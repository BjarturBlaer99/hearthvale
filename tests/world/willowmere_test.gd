extends GdUnitTestSuite
## Willowmere by day (2026-11-17, step 1 of docs/progress/willowmere-plan.md): a marsh reached
## from Hearthvale's east meadow. Water and deep reeds block and the boardwalks are the paths;
## three things grow to be gathered, back each morning; a heart piece lies in a nook that only
## the cell of ground behind the willows leads to; Marsh Stew is cooked from two of the marsh's
## foods. A save from before the marsh loads with all of it untouched.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const VILLAGE: String = "res://world/areas/village/village.tscn"
const MARSH: String = "res://world/areas/willowmere/willowmere.tscn"
const HOME: String = "res://world/areas/home/home.tscn"
const OLD_SAVE: String = "res://tests/fixtures/saves/v3_in_the_keep.json"
const TEST_SLOT: int = 964
const FRAME: float = 1.0 / 60.0
const SIDES: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
## Where the hero comes in, and a cell of each patch of land.
const WAY_IN: Vector2i = Vector2i(1, 14)
const WEST_BANK: Vector2i = Vector2i(4, 14)
const HUT_ISLAND: Vector2i = Vector2i(21, 14)
const NORTH_ISLET: Vector2i = Vector2i(20, 4)
const SOUTH_ISLET: Vector2i = Vector2i(20, 24)
const EAST_BANK: Vector2i = Vector2i(34, 14)
const NOOK: Vector2i = Vector2i(34, 3)
## The one cell of ground wide that leads round the willows to the nook.
const WAY_ROUND: Array[Vector2i] = [Vector2i(37, 5), Vector2i(37, 6), Vector2i(37, 7), Vector2i(37, 8)]
## [node, what it gives, how many]
const FORAGE: Array = [
	["CattailsA", &"cattail_root", 2], ["CattailsB", &"cattail_root", 2],
	["MarshBerriesA", &"marsh_berries", 2], ["MarshBerriesB", &"marsh_berries", 2],
	["BogMushroomsA", &"bog_mushroom", 2], ["BogMushroomsB", &"bog_mushroom", 2],
]

var _area: Node


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	Quests.refresh()
	GameState.set_time(float(GameState.day_clock().in_day("12:00")))
	SaveSystem.erase_slot(TEST_SLOT)
	SaveSystem.current_slot = TEST_SLOT


func after_test() -> void:
	if is_instance_valid(_area):
		_area.free()
	_area = null
	SaveSystem.erase_slot(TEST_SLOT)
	SaveSystem.current_slot = SaveSystem.GAME_SLOT
	GameState.clear()


func test_the_marsh_is_reached_from_the_east_meadow_and_back() -> void:
	# From the village square: up the meadow's stairs, along it, and out by the planks.
	var village: AreaController = _load(VILLAGE)
	var before_walk: Vector2i = (village.interactables.get_node(^"MarshWalk") as AreaExit).cell() + Vector2i.LEFT
	var reachable: Dictionary = _reachable(village, village.player.motor.cell)
	assert_bool(reachable.has(before_walk)).override_failure_message("the way east can be walked to from the square").is_true()
	village.player.motor.place(before_walk)
	assert_str(Steps.walk_until_travel(village, Vector2.RIGHT)).is_equal(MARSH)
	var marsh: AreaController = _load(MARSH)
	assert_str(marsh.area_name).is_equal("Willowmere")
	assert_that(marsh.player.motor.cell).is_equal(WAY_IN)
	assert_that(marsh.player.facing_direction()).override_failure_message("he comes in facing the marsh").is_equal(Vector2i.RIGHT)
	# And back the way he came.
	assert_str(Steps.walk_until_travel(marsh, Vector2.LEFT)).is_equal(VILLAGE)
	village = _load(VILLAGE)
	assert_that(village.player.motor.cell).is_equal(before_walk)
	assert_that(village.player.facing_direction()).is_equal(Vector2i.LEFT)


func test_only_two_cells_of_the_village_changed() -> void:
	# The east tree line is solid from top to bottom but for the two cells of the way out.
	var village: AreaController = _load(VILLAGE)
	var open: Array[Vector2i] = []
	for y: int in range(8, 34):
		if not village.grid.is_solid(Vector2i(47, y)):
			open.append(Vector2i(47, y))
	assert_array(open).is_equal([Vector2i(47, 17), Vector2i(47, 18)])
	var walk: AreaExit = village.interactables.get_node(^"MarshWalk")
	for cell: Vector2i in open:
		assert_bool(walk.covers(cell)).override_failure_message("%s is the way out, nothing else" % cell).is_true()
		assert_int(village.grid.height_at(cell)).override_failure_message("level with the meadow").is_equal(1)


func test_water_and_reeds_stop_him_and_the_boards_do_not() -> void:
	var marsh: AreaController = _load(MARSH)
	var layer: TileMapLayer = marsh.get_node(^"Height")
	var water: int = 0
	var reeds: int = 0
	var boards: int = 0
	for y: int in marsh.grid.size.y:
		for x: int in marsh.grid.size.x:
			var cell: Vector2i = Vector2i(x, y)
			var tile: Vector2i = layer.get_cell_atlas_coords(cell)
			if tile == GreyboxTiles.coords("water"):
				water += 1
				assert_bool(marsh.grid.is_solid(cell)).override_failure_message("water at %s" % cell).is_true()
			elif tile == GreyboxTiles.coords("reeds") or tile == GreyboxTiles.coords("reeds_b"):
				reeds += 1
				assert_bool(marsh.grid.is_solid(cell)).override_failure_message("reeds at %s" % cell).is_true()
			elif tile == GreyboxTiles.coords("boardwalk") or tile == GreyboxTiles.coords("boardwalk_ns"):
				boards += 1
				assert_bool(marsh.grid.is_solid(cell)).override_failure_message("boards at %s" % cell).is_false()
	assert_int(water).override_failure_message("a marsh is mostly water").is_greater(250)
	assert_int(reeds).is_greater(150)
	assert_int(boards).override_failure_message("four walks, two boards wide").is_equal(48)
	# Walking: along the west walk he reaches the island; into the reeds beside it he doesn't move.
	marsh.player.motor.place(Vector2i(6, 14))
	for i: int in 600:
		marsh.player.motor.step(Vector2.RIGHT, FRAME)
	assert_int(marsh.player.motor.cell.x).override_failure_message("across the boards to the island").is_greater_equal(16)
	marsh.player.motor.place(Vector2i(6, 12))
	for i: int in 120:
		marsh.player.motor.step(Vector2.RIGHT, FRAME)
	assert_that(marsh.player.motor.cell).override_failure_message("the reeds are too thick").is_equal(Vector2i(6, 12))


func test_the_boardwalks_join_every_patch_of_land() -> void:
	var marsh: AreaController = _load(MARSH)
	var reachable: Dictionary = _reachable(marsh, WAY_IN)
	for place: Vector2i in [WEST_BANK, HUT_ISLAND, NORTH_ISLET, SOUTH_ISLET, EAST_BANK, NOOK]:
		assert_bool(reachable.has(place)).override_failure_message("%s can be walked to" % place).is_true()
	for forage: Array in FORAGE:
		var spot: ForageSpot = marsh.interactables.get_node(NodePath(str(forage[0])))
		assert_bool(reachable.has(spot.cell())).override_failure_message("%s can be walked to" % forage[0]).is_true()
	# Without the boards there is only the west bank.
	var layer: TileMapLayer = marsh.get_node(^"Height")
	assert_that(layer.get_cell_atlas_coords(Vector2i(10, 14))).is_equal(GreyboxTiles.coords("boardwalk"))
	assert_that(layer.get_cell_atlas_coords(Vector2i(20, 8))).override_failure_message("planks lie across the way a walk runs").is_equal(GreyboxTiles.coords("boardwalk_ns"))


func test_the_heart_piece_is_reached_only_by_the_way_behind_the_willows() -> void:
	var marsh: AreaController = _load(MARSH)
	var piece: HeartPiece = marsh.interactables.get_node(^"MarshHeartPiece")
	assert_bool(_reachable(marsh, WAY_IN).has(piece.cell())).is_true()
	# Every way to it passes through the one cell of ground between the willows and the woods.
	for cell: Vector2i in WAY_ROUND:
		assert_bool(marsh.grid.is_solid(cell)).is_false()
		assert_bool(marsh.grid.is_solid(cell + Vector2i.LEFT)).override_failure_message("a willow to its west").is_true()
		assert_bool(marsh.grid.is_solid(cell + Vector2i.RIGHT)).override_failure_message("the woods to its east").is_true()
		assert_bool(_reachable(marsh, WAY_IN, [cell]).has(piece.cell())).override_failure_message("no way round %s" % cell).is_false()
	# The willows hide it: they stand as tall pictures the hero walks behind.
	assert_str(str(marsh.scenery.by_cell[Vector2i(36, 6)].get_meta(&"kind"))).is_equal("willow")
	assert_bool(Scenery.hides(Scenery.foot_of(Vector2i(36, 6)), Vector2(37 * 16 + 4, 5 * 16 + 8))).override_failure_message("a crown hangs over the way").is_true()
	# Taken once, and it is a piece like any other.
	marsh.player.motor.place(piece.cell())
	marsh.player.sync_from_motor()
	assert_int(marsh.collect_pickups()).is_equal(1)
	assert_int(GameState.heart_pieces).is_equal(1)
	assert_bool(GameState.get_flag(&"took_marsh_heart_piece") == true).is_true()
	assert_int(marsh.collect_pickups()).override_failure_message("not twice").is_equal(0)
	GameState.update_player(&"willowmere", piece.cell())
	marsh = _load(MARSH)
	assert_bool((marsh.interactables.get_node(^"MarshHeartPiece") as HeartPiece).is_there()).is_false()


func test_each_forage_spot_gives_its_food_and_is_back_the_next_morning() -> void:
	var marsh: AreaController = _load(MARSH)
	for forage: Array in FORAGE:
		var spot: ForageSpot = marsh.interactables.get_node(NodePath(str(forage[0])))
		var item: StringName = forage[1]
		var before: int = GameState.item_count(item)
		assert_str(str(DataRegistry.get_item(item).get("type", ""))).override_failure_message("%s is food" % item).is_equal("food")
		assert_bool(ForageSpot.FRAMES.has(spot.kind)).is_true()
		assert_bool(ForageSpot.FRAMES.has(StringName(String(spot.kind) + "_picked"))).is_true()
		assert_that(spot.item_id).is_equal(item)
		assert_bool(marsh.grid.is_solid(spot.cell())).override_failure_message("%s lies on open ground" % forage[0]).is_false()
		marsh.player.motor.place(spot.cell())
		assert_bool(marsh.interact()).is_true()
		assert_int(GameState.item_count(item)).override_failure_message(str(forage[0])).is_equal(before + int(forage[2]))
		assert_bool(spot.taken()).is_true()
		assert_bool(spot.take()).override_failure_message("gone for the day").is_false()
	GameState.start_next_day()
	for forage: Array in FORAGE:
		assert_bool((marsh.interactables.get_node(NodePath(str(forage[0]))) as ForageSpot).taken()).override_failure_message("%s is back" % forage[0]).is_false()


func test_the_marsh_foods_can_be_eaten_and_no_forage_spot_is_under_a_crown() -> void:
	for item: Array in [[&"cattail_root", 6.0], [&"marsh_berries", 9.0], [&"bog_mushroom", 7.0]]:
		GameState.add_item(item[0], 1)
		GameState.set_energy(50.0)
		assert_bool(GameState.eat(item[0])).override_failure_message(String(item[0])).is_true()
		assert_float(GameState.energy).is_equal(50.0 + float(item[1]))
		assert_bool(ItemIcons.FRAMES.has(ItemIcons.name_for(item[0]))).is_true()
		assert_that(ItemIcons.name_for(item[0])).override_failure_message("a picture of its own").is_not_equal(&"gem")
	var marsh: AreaController = _load(MARSH)
	for forage: Array in FORAGE:
		var spot: ForageSpot = marsh.interactables.get_node(NodePath(str(forage[0])))
		var at: Vector2 = Vector2(spot.cell() * 16) + Vector2(8, 8)
		assert_array(marsh.scenery.hiding(at)).override_failure_message("%s is clear of the trees" % forage[0]).is_empty()


func test_marsh_stew_is_known_from_the_start_and_cooked_from_two_of_the_marshs_foods() -> void:
	var recipe: Dictionary = DataRegistry.get_recipe(&"marsh_stew")
	assert_bool(bool(recipe.get("taught", false))).override_failure_message("nobody has to teach it").is_false()
	assert_array(recipe["needs"]).is_equal([{"item": "bog_mushroom", "count": 2.0}, {"item": "cattail_root", "count": 1.0}])
	assert_array(GameState.known_recipes().map(func(known: Dictionary) -> String: return str(known["id"]))).contains(["marsh_stew"])
	GameState.add_item(&"bog_mushroom", 2)
	GameState.add_item(&"cattail_root", 1)
	var home: AreaController = _load(HOME)
	var hearth: Hearth = home.interactables.get_node(^"Hearth")
	home.player.motor.place(hearth.cell() + Vector2i.DOWN)
	home.player.face(Vector2.UP)
	assert_bool(home.interact()).is_true()
	var line: String = "Marsh Stew (2 Bog Mushrooms, 1 Cattail Root)"
	assert_array(Array(home.hud.dialogue.shown_options())).contains([line])
	_say(home, line)
	assert_int(GameState.item_count(&"marsh_stew")).is_equal(1)
	assert_int(GameState.item_count(&"bog_mushroom")).is_equal(0)
	assert_int(GameState.item_count(&"cattail_root")).is_equal(0)
	# A dish: more than the three eaten raw would give, and half a heart.
	GameState.set_energy(10.0)
	GameState.damage(2)
	var hearts: int = GameState.health
	assert_bool(GameState.eat(&"marsh_stew")).is_true()
	assert_float(GameState.energy).is_equal(10.0 + GameState.food_energy(&"marsh_stew"))
	assert_float(GameState.food_energy(&"marsh_stew")).is_greater(7.0 + 7.0 + 6.0)
	assert_int(GameState.health).is_equal(hearts + 1)


func test_the_marsh_has_its_own_tune_its_mist_and_fireflies_that_wait_for_dusk() -> void:
	var marsh: AreaController = _load(MARSH)
	assert_that(marsh.music).is_equal(&"marsh")
	assert_bool(Audio.MUSIC.has(&"marsh")).is_true()
	assert_bool(ResourceLoader.exists("res://audio/music/marsh.wav")).is_true()
	assert_that(marsh.tune_now()).override_failure_message("by day, its own tune").is_equal(&"marsh")
	assert_object(marsh.mist).override_failure_message("mist lies over it").is_not_null()
	assert_that(marsh.ambience).is_equal(Ambience.OUTDOOR)
	assert_bool(marsh.clock_runs()).override_failure_message("the day passes here").is_true()
	var fireflies: Array[Critter] = []
	for child: Node in marsh.interactables.get_children():
		if child is Critter and (child as Critter).kind == &"firefly":
			fireflies.append(child as Critter)
	assert_int(fireflies.size()).is_equal(8)
	for firefly: Critter in fireflies:
		assert_bool(firefly.from_dusk).is_true()
		assert_bool(firefly.is_out()).override_failure_message("none at noon").is_false()
	GameState.set_time(float(GameState.day_clock().in_day("19:00")))
	assert_bool(fireflies[0].is_out()).override_failure_message("out once the lamps are lit").is_true()
	assert_that(marsh.tune_now()).override_failure_message("still its own tune at dusk").is_equal(&"marsh")
	GameState.set_time(float(GameState.day_clock().in_day("21:00")))
	assert_that(marsh.tune_now()).override_failure_message("the night's tune after nightfall, as everywhere out of doors").is_equal(AreaController.NIGHT_TUNE)
	# The Old Wood's fireflies are as they were: out at every hour.
	assert_bool(Ambience.fireflies_wait_for_dusk(&"old_wood")).is_false()
	assert_bool(Ambience.has_mist(&"old_wood")).is_true()


func test_the_marshs_tiles_are_the_marshs_own_and_nothing_else_moved() -> void:
	# New kinds sit in rows of their own at the end of the atlas: no older tile changed place.
	assert_that(GreyboxTiles.coords("water")).is_equal(Vector2i(0, GreyboxTiles.ROW_WATER))
	assert_that(GreyboxTiles.coords("prop_cherry")).is_equal(Vector2i(3, GreyboxTiles.ROW_TREES))
	assert_that(GreyboxTiles.coords("prop_willow")).is_equal(Vector2i(4, GreyboxTiles.ROW_TREES))
	var seen: Dictionary = {}
	for kind: String in GreyboxTiles.MARSH_KINDS + GreyboxTiles.MARSH_DECOR_KINDS:
		var at: Vector2i = GreyboxTiles.coords(kind)
		assert_bool(GreyboxTiles.is_known_kind(kind)).is_true()
		assert_bool(at.y == GreyboxTiles.ROW_MARSH or at.y == GreyboxTiles.ROW_MARSH_DECOR).override_failure_message(kind).is_true()
		assert_bool(seen.has(at)).override_failure_message("%s has a tile of its own" % kind).is_false()
		seen[at] = true
	assert_bool(GreyboxTiles.is_decor("cattail") and GreyboxTiles.is_decor("planks") and GreyboxTiles.is_decor("ruin_hole")).is_true()
	assert_bool(GreyboxTiles.is_decor("prop_marsh_lantern")).override_failure_message("a post is a prop: it blocks").is_false()
	assert_bool(GreyboxTiles.is_prop("prop_marsh_lantern") and GreyboxTiles.is_prop("prop_mossy_rock") and GreyboxTiles.is_prop("prop_willow")).is_true()
	# The hut, the lantern posts and the stones block; the ground and the decorations don't.
	var marsh: AreaController = _load(MARSH)
	for cell: Vector2i in [Vector2i(16, 10), Vector2i(19, 12), Vector2i(6, 13), Vector2i(24, 13), Vector2i(5, 16), Vector2i(3, 11)]:
		assert_bool(marsh.grid.is_solid(cell)).override_failure_message("%s blocks" % cell).is_true()
	for cell: Vector2i in [Vector2i(2, 10), Vector2i(16, 17), HUT_ISLAND, Vector2i(22, 13), Vector2i(20, 10), Vector2i(21, 10)]:
		assert_bool(marsh.grid.is_solid(cell)).override_failure_message("%s is open" % cell).is_false()
	assert_int(marsh.grid.size.x * marsh.grid.size.y).override_failure_message("the size of the North Fields").is_equal(40 * 30)


func test_a_save_from_before_the_marsh_loads_with_the_marsh_untouched() -> void:
	DirAccess.make_dir_recursive_absolute(SaveSystem.SAVE_DIR)
	SaveSystem._write_text(SaveSystem.slot_path(TEST_SLOT), FileAccess.get_file_as_string(OLD_SAVE))
	assert_int(SaveSystem.load_game()).is_equal(OK)
	GameState.set_time(float(GameState.day_clock().in_day("12:00")))
	GameState.go_to(&"willowmere", &"west_walk")
	var marsh: AreaController = _load(MARSH)
	assert_that(marsh.player.motor.cell).is_equal(WAY_IN)
	assert_bool((marsh.interactables.get_node(^"MarshHeartPiece") as HeartPiece).is_there()).is_true()
	for forage: Array in FORAGE:
		assert_bool((marsh.interactables.get_node(NodePath(str(forage[0]))) as ForageSpot).taken()).is_false()
	assert_int(GameState.item_count(&"marsh_stew")).is_equal(0)
	# And the game saved in the marsh loads back into it.
	assert_int(SaveSystem.save_game()).is_equal(OK)
	GameState.new_game()
	assert_int(SaveSystem.load_game()).is_equal(OK)
	assert_str(str(SaveSystem.summary()["area"])).is_equal("willowmere")
	assert_str(WorldPaths.area_name(&"willowmere")).is_equal("Willowmere")


## Every cell the hero could walk to from `start` right now, never stepping on `blocked`.
func _reachable(area: AreaController, start: Vector2i, blocked: Array = []) -> Dictionary:
	var seen: Dictionary = {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_back()
		for side: Vector2i in SIDES:
			var next: Vector2i = cell + side
			if not seen.has(next) and not blocked.has(next) and area.terrain.check_move(cell, next).is_allowed():
				seen[next] = true
				queue.append(next)
	return seen


## Picks the answer that reads `text` in the open conversation.
func _say(area: AreaController, text: String) -> void:
	var box: DialogueBox = area.hud.dialogue
	var index: int = box.shown_options().find(text)
	assert_int(index).override_failure_message("no answer '%s' among %s" % [text, box.shown_options()]).is_greater_equal(0)
	box.move_cursor(index - box.selected)
	box.confirm()


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area
