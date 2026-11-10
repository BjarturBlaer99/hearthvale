extends GdUnitTestSuite
## A more detailed world (H12):
## - spawn markers become grass, pots and critters
## - grass and pots break on what their data says, drop from their tables, free their cell, and
##   are back on the next visit
## - critters never block the way
## - the four heart pieces (village nook, plateau corner, Cistern secret room, Old Wood shrine)
##   can each be reached and together make a heart, counted on the HUD
## - the new villagers talk from data
## - no area grew

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const VILLAGE: String = "res://world/areas/village/village.tscn"
const FIELDS: String = "res://world/areas/north_fields/north_fields.tscn"
const CISTERN: String = "res://world/areas/cistern/cistern.tscn"
const WOOD: String = "res://world/areas/old_wood/old_wood.tscn"
const FRAME: float = 1.0 / 60.0
const SIDES: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
## Every area and its size in cells before H12: the map must not grow.
const SIZES: Dictionary = {
	&"village": Vector2i(48, 36), &"elder_house": Vector2i(11, 9), &"weaver_house": Vector2i(11, 9),
	&"shop": Vector2i(11, 9), &"south_field": Vector2i(40, 28), &"ruin_cellar": Vector2i(15, 33),
	&"cistern": Vector2i(30, 33), &"keep": Vector2i(45, 44), &"north_fields": Vector2i(40, 30),
	&"old_wood": Vector2i(40, 30),
	# H14's dungeon, the one area added since: under the chapel, so the map above is no bigger.
	&"crypt": Vector2i(45, 44),
}

var _area: Node
var _heard: Array[StringName] = []


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	_heard.clear()
	EventBus.sound.connect(_on_sound)


func after_test() -> void:
	EventBus.sound.disconnect(_on_sound)
	if is_instance_valid(_area):
		_area.free()
	_area = null
	Engine.time_scale = 1.0
	GameState.clear()


func test_spawn_markers_become_grass_pots_and_critters() -> void:
	var village: AreaController = _load(VILLAGE)
	var spawns: TileMapLayer = village.get_node(^"Spawns")
	assert_bool(spawns.visible).override_failure_message("the markers are never seen").is_false()
	assert_int(spawns.get_used_cells().size()).override_failure_message("all turned into nodes").is_equal(0)
	var counts: Dictionary = {}
	for child: Node in village.interactables.get_children():
		if child is Breakable:
			counts[(child as Breakable).breakable_id] = int(counts.get((child as Breakable).breakable_id, 0)) + 1
		elif child is Critter:
			counts[(child as Critter).kind] = int(counts.get((child as Critter).kind, 0)) + 1
	assert_int(int(counts.get(&"grass", 0))).is_greater_equal(6)
	assert_int(int(counts.get(&"pot", 0))).is_greater_equal(2)
	assert_int(int(counts.get(&"chicken", 0))).is_greater_equal(2)
	assert_int(int(counts.get(&"butterfly", 0))).is_greater_equal(2)


func test_grass_and_pots_break_on_what_their_data_says_and_drop_from_their_tables() -> void:
	var village: AreaController = _load(VILLAGE)
	var grass: Breakable = village.interactables.get_node(^"Grass_2_12")
	assert_bool(village.terrain.is_occupied(grass.cell())).override_failure_message("grass stands in its cell").is_true()
	grass.roll_drop = func() -> float: return 0.95
	grass.hurt_box.receive(Hit.new(2, Vector2.ZERO, Vector2.ZERO, &"arrow"))
	assert_bool(grass.broken).override_failure_message("an arrow doesn't cut grass").is_false()
	grass.hurt_box.receive(Hit.new(2, Vector2.ZERO, Vector2.ZERO, &"sword"))
	assert_bool(grass.broken).override_failure_message("a sword does").is_true()
	assert_bool(village.terrain.is_occupied(grass.cell())).override_failure_message("its cell comes free").is_false()
	assert_array(_heard).contains([&"cut"])
	_assert_drop(grass, 0.95)
	var pot: Breakable = village.interactables.get_node(^"Pot_13_21")
	pot.roll_drop = func() -> float: return 0.5
	pot.hurt_box.receive(Hit.new(4, Vector2.ZERO, Vector2.ZERO, &"bomb"))
	assert_bool(pot.broken).override_failure_message("a bomb breaks a pot").is_true()
	assert_array(_heard).contains([&"pot"])
	_assert_drop(pot, 0.5)
	village = _load(VILLAGE)
	assert_bool((village.interactables.get_node(^"Grass_2_12") as Breakable).broken).override_failure_message("back on the next visit").is_false()


func test_every_breakable_drop_follows_its_table() -> void:
	for id: StringName in [&"grass", &"pot"]:
		var data: Dictionary = DataRegistry.get_breakable(id)
		for roll: float in [0.0, 0.3, 0.55, 0.7, 0.85, 0.99]:
			var village: AreaController = _load(VILLAGE)
			var breakable: Breakable = Breakable.new()
			breakable.breakable_id = id
			breakable.position = Vector2(30, 24) * GridBody.TILE
			village.interactables.add_child(breakable)
			breakable.roll_drop = func() -> float: return roll
			breakable.smash()
			assert_bool(breakable.broken).is_true()
			_assert_drop(breakable, roll)
			assert_dict(data).is_not_empty()


func test_critters_never_block_the_way() -> void:
	var village: AreaController = _load(VILLAGE)
	var critters: Array[Critter] = []
	for child: Node in village.interactables.get_children():
		if child is Critter:
			critters.append(child as Critter)
			assert_bool(child.has_method(&"occupies")).override_failure_message("%s stands in nobody's way" % child.name).is_false()
	assert_int(critters.size()).is_greater(0)
	for i: int in roundi(5.0 / FRAME):
		for critter: Critter in critters:
			critter._process(FRAME)
	for critter: Critter in critters:
		if critter.kind == &"chicken":
			assert_bool(village.grid.is_solid(GridBody.cell_of(critter.position))).override_failure_message("%s on open ground" % critter.name).is_false()


func test_four_heart_pieces_can_be_found_and_make_a_heart() -> void:
	GameState.add_item(&"wooden_sword")
	GameState.add_item(&"bomb", 2)
	# 1. The village: a nook in the woods by the field, behind tall grass.
	GameState.go_to(&"village", &"south_road")
	var village: AreaController = _load(VILLAGE)
	var piece: HeartPiece = village.interactables.get_node(^"VillageHeartPiece")
	assert_bool(_reachable(village, village.player.motor.cell).has(piece.cell())).override_failure_message("behind grass").is_false()
	(village.interactables.get_node(^"Grass_1_30") as Breakable).smash()
	assert_bool(_reachable(village, village.player.motor.cell).has(piece.cell())).override_failure_message("cut, the nook opens").is_true()
	_take(village, piece)
	assert_int(GameState.heart_pieces).is_equal(1)
	assert_int(village.hud.hearts.pieces_shown()).override_failure_message("the HUD counts it").is_equal(1)
	# 2. The North Fields: the plateau's far corner, behind tall grass.
	GameState.go_to(&"north_fields", &"south_road")
	var fields: AreaController = _load(FIELDS)
	piece = fields.interactables.get_node(^"FieldsHeartPiece")
	assert_bool(_reachable(fields, fields.player.motor.cell).has(piece.cell())).is_false()
	(fields.interactables.get_node(^"Grass_36_20") as Breakable).smash()
	assert_bool(_reachable(fields, fields.player.motor.cell).has(piece.cell())).override_failure_message("up the plateau's stairs, then through the cut grass").is_true()
	_take(fields, piece)
	# 3. The Cistern: the secret room behind a cracked wall in the push room.
	GameState.go_to(&"cistern", &"entrance")
	var cistern: AreaController = _load(CISTERN)
	piece = cistern.interactables.get_node(^"CisternHeartPiece")
	var wall: DungeonDoor = cistern.interactables.get_node(^"SecretWall")
	assert_bool(_reachable(cistern, cistern.player.motor.cell).has(piece.cell())).override_failure_message("walled up").is_false()
	_bomb(cistern, Vector2i(13, 27))
	assert_bool(wall.is_open()).is_true()
	assert_bool(_reachable(cistern, cistern.player.motor.cell).has(piece.cell())).override_failure_message("a bomb opens the secret room").is_true()
	_take(cistern, piece)
	assert_int(GameState.heart_pieces).is_equal(3)
	assert_int(GameState.hearts_max).is_equal(3)
	# 4. The Old Wood's shrine.
	GameState.go_to(&"old_wood", &"south_road")
	var wood: AreaController = _load(WOOD)
	_bomb(wood, Vector2i(29, 13))
	_take(wood, wood.interactables.get_node(^"HeartPiece"))
	assert_int(GameState.hearts_max).override_failure_message("four pieces make a heart").is_equal(4)
	assert_int(GameState.heart_pieces).is_equal(0)
	assert_int(wood.hud.hearts.pieces_shown()).is_equal(0)


func test_new_villagers_talk_from_data() -> void:
	var cases: Array = [[VILLAGE, "FarmerOda", "Farmer Oda"], [VILLAGE, "Pip", "Pip"], [VILLAGE, "GuardRolf", "Guard Rolf"], [FIELDS, "ShepherdEdda", "Shepherd Edda"]]
	for case: Array in cases:
		var area: AreaController = _load(case[0])
		var villager: Villager = area.interactables.get_node(NodePath(case[1]))
		assert_str(villager.display_name()).is_equal(case[2])
		assert_bool(area.terrain.is_occupied(villager.cell())).is_true()
		assert_bool(area.talk_to(villager)).is_true()
		assert_str(area.hud.dialogue.shown_name()).is_equal(case[2])


func test_no_area_grew() -> void:
	for area_id: StringName in SIZES:
		var scene: Node = auto_free((load(WorldPaths.scene_for(area_id)) as PackedScene).instantiate())
		var used: Rect2i = (scene.get_node(^"Height") as TileMapLayer).get_used_rect()
		assert_that(used.size).override_failure_message(String(area_id)).is_equal(SIZES[area_id])
	var folders: PackedStringArray = DirAccess.get_directories_at("res://world/areas")
	assert_int(folders.size()).override_failure_message("no new areas").is_equal(SIZES.size())


func _assert_drop(breakable: Breakable, roll: float) -> void:
	var expected: Dictionary = DropTable.roll(breakable.data["drops"], roll)
	match str(expected.get("type", "")):
		"heart":
			assert_object(breakable.dropped).override_failure_message("%s @%s: a heart" % [breakable.breakable_id, roll]).is_instanceof(HeartPickup)
		"item":
			assert_object(breakable.dropped).is_instanceof(ItemDrop)
			assert_str(String((breakable.dropped as ItemDrop).item_id)).is_equal(str(expected["item"]))
			assert_int((breakable.dropped as ItemDrop).count).is_equal(int(expected.get("count", 1)))
		_:
			assert_object(breakable.dropped).override_failure_message("%s @%s: nothing" % [breakable.breakable_id, roll]).is_null()


func _take(area: AreaController, piece: HeartPiece) -> void:
	area.player.motor.place(piece.cell())
	area.player.sync_from_motor()
	assert_int(area.collect_pickups()).override_failure_message("take %s" % piece.name).is_equal(1)


## Sets a bomb down at `cell` and lets it burn out.
func _bomb(area: AreaController, cell: Vector2i) -> void:
	GameState.equip(&"bomb")
	area.player.motor.place(cell)
	area.player.sync_from_motor()
	assert_bool(area.use_item()).is_true()
	var bomb: Bomb = area.last_projectile
	for i: int in roundi(2.6 / FRAME):
		bomb.tick(FRAME)
		area.resolve_combat()
		if not is_instance_valid(bomb) or bomb.is_queued_for_deletion():
			break


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area


func _on_sound(id: StringName) -> void:
	_heard.append(id)


func _reachable(area: AreaController, start: Vector2i) -> Dictionary:
	var seen: Dictionary = {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_back()
		for side: Vector2i in SIDES:
			var next: Vector2i = cell + side
			if not seen.has(next) and area.terrain.check_move(cell, next).is_allowed():
				seen[next] = true
				queue.append(next)
	return seen
