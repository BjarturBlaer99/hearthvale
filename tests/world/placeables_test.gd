extends GdUnitTestSuite
## The rest of what is set down (the Homestead, phase 2, step 2b): the two floors, the hedge,
## the lamp post (lit from dusk to dawn), the bench, the three flower beds, and the oak and
## cherry saplings, which grow by the morning into trees the hero walks behind; the hand of the
## build bar, which lifts a thing and sets it down elsewhere; the workbench's two tabs, "Make"
## and "Place"; and Tilda's new wares. All fifteen are data.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const FARM: String = "res://world/areas/homestead/homestead.tscn"
const HOME: String = "res://world/areas/home/home.tscn"
const SHOP: String = "res://world/areas/shop/shop.tscn"
const TEST_SLOT: int = 952
const FRAME: float = 1.0 / 60.0
## Open grass east of the path to the farmhouse's door: rows 12 and 13, columns 29 to 37.
const START: Vector2i = Vector2i(30, 13)
const YARD: Vector2i = Vector2i(33, 12)
const ROAD: Vector2i = Vector2i(31, 14)
## The fifteen, as the plan's table has them: [id, name, lies or stands, blocks].
const PLACEABLES: Array = [
	[&"dirt_path", "Dirt Path", &"lying", false], [&"stone_path", "Stone Path", &"lying", false],
	[&"wood_path", "Wood Path", &"lying", false], [&"wooden_flooring", "Wooden Flooring", &"lying", false],
	[&"stone_flooring", "Stone Flooring", &"lying", false], [&"fence", "Fence", &"standing", true],
	[&"gate", "Gate", &"standing", false], [&"lamp_post", "Lamp Post", &"standing", true],
	[&"bench", "Bench", &"standing", true], [&"hedge", "Hedge", &"standing", true],
	[&"flower_bed_red", "Red Flower Bed", &"lying", false], [&"flower_bed_yellow", "Yellow Flower Bed", &"lying", false],
	[&"flower_bed_blue", "Blue Flower Bed", &"lying", false], [&"oak_sapling", "Oak Sapling", &"standing", true],
	[&"cherry_sapling", "Cherry Sapling", &"standing", true],
]
## What the workbench makes on its "Place" tab, in the list's order: [id, what it needs, how many it makes].
const MADE: Array = [
	[&"dirt_path", {"stone": 1}, 4], [&"stone_path", {"stone": 2}, 4], [&"wood_path", {"wood": 1}, 4],
	[&"wooden_flooring", {"wood": 2}, 4], [&"stone_flooring", {"stone": 3}, 4], [&"fence", {"wood": 1}, 2],
	[&"gate", {"wood": 3}, 1], [&"lamp_post", {"iron_bar": 1, "coal": 1, "wood": 2}, 1], [&"bench", {"wood": 4}, 1],
]
## What Tilda sells for the land: [id, how many a deal gives, coins].
const BOUGHT: Array = [
	[&"fibre", 5, 6], [&"hedge", 1, 5], [&"flower_bed_red", 1, 3], [&"flower_bed_yellow", 1, 3], [&"flower_bed_blue", 1, 3],
	[&"oak_sapling", 1, 10], [&"cherry_sapling", 1, 30],
]

var _area: Node
var _heard: Array[StringName] = []
var _changes: int = 0


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	Quests.refresh()
	GameState.set_time(float(GameState.day_clock().in_day("12:00")))
	SaveSystem.erase_slot(TEST_SLOT)
	SaveSystem.current_slot = TEST_SLOT
	_heard.clear()
	_changes = 0
	EventBus.sound.connect(_on_sound)
	EventBus.homestead_changed.connect(_on_homestead_changed)


func after_test() -> void:
	EventBus.sound.disconnect(_on_sound)
	EventBus.homestead_changed.disconnect(_on_homestead_changed)
	if is_instance_valid(_area):
		_area.free()
	_area = null
	SaveSystem.erase_slot(TEST_SLOT)
	SaveSystem.current_slot = SaveSystem.GAME_SLOT
	GameState.clear()


func test_the_fifteen_placeables_are_data_from_the_bench_and_from_tilda() -> void:
	assert_int(PLACEABLES.size()).is_equal(15)
	var known: Array = []
	for item: Dictionary in DataRegistry.entries(&"items"):
		if Placement.is_placeable(item):
			known.append(StringName(str(item["id"])))
	assert_array(known).override_failure_message("the plan's fifteen, and no others").contains_exactly_in_any_order(PLACEABLES.map(func(row: Array) -> StringName: return row[0]))
	for row: Array in PLACEABLES:
		var item: Dictionary = DataRegistry.get_item(row[0])
		assert_str(str(item["name"])).is_equal(row[1])
		assert_that(Placement.layer_of(item)).override_failure_message(String(row[0])).is_equal(row[2])
		assert_bool(Placement.blocks(item)).override_failure_message("%s blocks" % row[0]).is_equal(row[3])
		assert_bool(PlacedArt.has(Placement.frame_of(item))).override_failure_message("%s has its picture" % row[0]).is_true()
		assert_that(ItemIcons.name_for(row[0])).is_equal(Placement.frame_of(item))
		assert_bool(Inventory.is_equippable(item)).override_failure_message("%s is never on the item bar" % row[0]).is_false()
		assert_bool(bool(item.get("stackable", false))).is_true()
		# Each takes one cell: nothing in its data says otherwise.
		assert_bool((item["stats"] as Dictionary).has("size") or (item["stats"] as Dictionary).has("cells")).is_false()
	# Only the fence and the gate join; only the lamp post gives light; only the saplings grow;
	# the paths and floors cover their cell and the flower beds don't.
	for row: Array in PLACEABLES:
		var item: Dictionary = DataRegistry.get_item(row[0])
		assert_bool(Placement.joins(item)).override_failure_message("%s joins" % row[0]).is_equal(row[0] in [&"fence", &"gate"])
		assert_bool(not Placement.light_of(item).is_empty()).override_failure_message("%s gives light" % row[0]).is_equal(row[0] == &"lamp_post")
		assert_bool(Placement.is_sapling(item)).override_failure_message("%s grows" % row[0]).is_equal(row[0] in [&"oak_sapling", &"cherry_sapling"])
		assert_bool(Placement.fills(item)).override_failure_message("%s covers its cell" % row[0]).is_equal(
			row[0] in [&"dirt_path", &"stone_path", &"wood_path", &"wooden_flooring", &"stone_flooring"])
	assert_int(Placement.mornings_of(DataRegistry.get_item(&"oak_sapling"))).override_failure_message("an oak after 4 mornings").is_equal(4)
	assert_int(Placement.mornings_of(DataRegistry.get_item(&"cherry_sapling"))).override_failure_message("a cherry tree after 6").is_equal(6)
	assert_str(Placement.tree_of(DataRegistry.get_item(&"oak_sapling"))).is_equal("oak")
	assert_str(Placement.tree_of(DataRegistry.get_item(&"cherry_sapling"))).is_equal("cherry")
	assert_dict(GameState.growing_things()).is_equal({"oak_sapling": 4, "cherry_sapling": 6})
	# Nine are made at the workbench, for the plan's costs, on its "Place" tab and in its order.
	var place: Array[Dictionary] = Crafting.of_tab(Crafting.of_station(DataRegistry.entries(&"crafting"), Crafting.WORKBENCH), Crafting.TAB_PLACE)
	assert_array(place.map(func(recipe: Dictionary) -> StringName: return StringName(str(recipe["id"])))).is_equal(MADE.map(func(row: Array) -> StringName: return row[0]))
	for index: int in MADE.size():
		var recipe: Dictionary = place[index]
		var needs: Dictionary = {}
		for need: Dictionary in Crafting.needs_of(recipe):
			needs[need["item"]] = need["count"]
		assert_dict(needs).override_failure_message("%s needs" % MADE[index][0]).is_equal(MADE[index][1])
		assert_str(Crafting.item_made(recipe)).is_equal(String(MADE[index][0]))
		assert_int(Crafting.count_made(recipe)).override_failure_message("%s makes" % MADE[index][0]).is_equal(MADE[index][2])
		assert_bool(recipe.has("unlock")).override_failure_message("known from the start").is_false()
	# Six are bought from Tilda, with fibre five at a time, at the plan's prices; and nothing
	# she sold before costs anything else.
	var wares: Array[Dictionary] = Shop.wares(DataRegistry.get_shop(&"tilda"), [])
	assert_array(wares).is_equal([
		{"item": "arrow", "count": 10, "price": 5}, {"item": "bomb", "count": 3, "price": 8}, {"item": "bread", "count": 1, "price": 6},
		{"item": "pickaxe", "count": 1, "price": 25},
		{"item": "fibre", "count": 5, "price": 6}, {"item": "hedge", "count": 1, "price": 5},
		{"item": "flower_bed_red", "count": 1, "price": 3}, {"item": "flower_bed_yellow", "count": 1, "price": 3}, {"item": "flower_bed_blue", "count": 1, "price": 3},
		{"item": "oak_sapling", "count": 1, "price": 10}, {"item": "cherry_sapling", "count": 1, "price": 30},
	])
	assert_int(BOUGHT.size()).is_equal(7)
	# Every one of the fifteen comes from one of the two, and from one only.
	for row: Array in PLACEABLES:
		var made: bool = MADE.any(func(made_row: Array) -> bool: return made_row[0] == row[0])
		var bought: bool = BOUGHT.any(func(bought_row: Array) -> bool: return bought_row[0] == row[0])
		assert_bool(made != bought).override_failure_message("%s: the bench or the shop" % row[0]).is_true()
	# She buys none of it back (no selling of what is set down was asked for).
	for bought_thing: Dictionary in Shop.bought_things(DataRegistry.get_shop(&"tilda")):
		assert_bool(Placement.is_placeable(DataRegistry.get_item(StringName(str(bought_thing["item"]))))).is_false()
	assert_array(Array(DataRegistry.errors)).is_empty()


func test_the_hedge_the_bench_and_the_lamp_post_block_and_floors_and_flower_beds_lie() -> void:
	_stock()
	var farm: AreaController = _farm()
	farm.open_build()
	var x: int = 31
	for id: StringName in [&"hedge", &"bench", &"lamp_post", &"oak_sapling", &"cherry_sapling"]:
		var at: Vector2i = Vector2i(x, 12)
		assert_bool(_put(farm, id, at)).override_failure_message(String(id)).is_true()
		assert_bool(farm.terrain.is_occupied(at)).override_failure_message("%s fills its cell at once" % id).is_true()
		assert_that(farm.placed.standing_node(at).item_id).is_equal(id)
		assert_that(farm.terrain.check_move(at + Vector2i.DOWN, at).kind).is_equal(MoveResult.Kind.BLOCKED)
		x += 1
	x = 31
	for id: StringName in [&"wooden_flooring", &"stone_flooring", &"flower_bed_red", &"flower_bed_yellow", &"flower_bed_blue"]:
		var at: Vector2i = Vector2i(x, 13)
		assert_bool(_put(farm, id, at)).override_failure_message(String(id)).is_true()
		assert_bool(farm.terrain.is_occupied(at)).override_failure_message("%s is walked over" % id).is_false()
		assert_object(farm.placed.standing_node(at)).is_null()
		assert_that(GameState.homestead().lying_at(at)).is_equal(id)
		x += 1
	# Only a fence and a gate run on to each other: a fence beside a hedge is a post alone.
	assert_bool(_put(farm, &"fence", Vector2i(30, 12))).is_true()
	assert_that(farm.placed.standing_node(Vector2i(31, 12)).item_id).is_equal(&"hedge")
	assert_int(farm.placed.standing_node(Vector2i(30, 12)).joined()).override_failure_message("no rail toward a hedge").is_equal(0)
	assert_int(farm.placed.standing_node(Vector2i(31, 12)).joined()).override_failure_message("and a hedge joins nothing").is_equal(0)
	assert_bool(_put(farm, &"gate", Vector2i(29, 12))).is_true()
	assert_int(farm.placed.standing_node(Vector2i(30, 12)).joined()).override_failure_message("a rail toward the gate west of it").is_equal(PlacedArt.WEST)
	farm.build.close()
	# He walks the row of floors and flower beds from end to end.
	_walk(farm, Vector2.RIGHT, 80)
	assert_int(farm.player.motor.cell.x).override_failure_message("across both floors and all three beds").is_greater(35)
	# A floor under a bench: two things to a cell, as with the paths.
	farm.open_build()
	assert_bool(_put(farm, &"stone_flooring", Vector2i(32, 12))).override_failure_message("a floor under the bench").is_true()
	assert_bool(_put(farm, &"flower_bed_red", Vector2i(32, 12))).override_failure_message("but not a flower bed on the floor").is_false()
	assert_str(farm.hud.build_words()).is_equal(Placement.TAKEN_WORDS)
	# Each comes back to the pack when it is taken up.
	farm.build.point_at(Vector2i(31, 12))
	assert_bool(farm.build.take_up()).is_true()
	assert_int(GameState.item_count(&"hedge")).is_equal(4)
	assert_bool(farm.terrain.is_occupied(Vector2i(31, 12))).is_false()


func test_a_lamp_post_is_lit_from_dusk_to_dawn() -> void:
	_stock()
	var farm: AreaController = _farm()
	farm.open_build()
	assert_bool(_put(farm, &"lamp_post", YARD)).is_true()
	farm.build.close()
	var post: PlacedThing = farm.placed.standing_node(YARD)
	var item: Dictionary = DataRegistry.get_item(&"lamp_post")
	# By day it stands dark.
	assert_bool(post.is_lit()).override_failure_message("dark at noon").is_false()
	assert_dict(post.glow_now()).is_empty()
	assert_bool(_glows_at(farm, YARD)).is_false()
	assert_array(PlacedArt.pieces(item, 0, 0, post.is_lit())).is_equal([[&"lamp_post", false]])
	# The lamps of the day's clock light it: from dusk to dawn.
	var clock: DayClock = GameState.day_clock()
	for hour: Array in [["06:00", true], ["06:30", false], ["12:00", false], ["18:00", false], ["18:30", true], ["21:00", true], ["01:30", true]]:
		GameState.set_time(float(clock.in_day(hour[0])))
		assert_bool(clock.lamps_lit(GameState.minute)).override_failure_message("the test knows when lamps are lit: %s" % hour[0]).is_equal(hour[1])
		assert_bool(post.is_lit()).override_failure_message("lit at %s" % hour[0]).is_equal(hour[1])
		assert_bool(_glows_at(farm, YARD)).override_failure_message("the area shows its light at %s" % hour[0]).is_equal(hour[1])
	# Lit, it shows its burning picture and gives a steady light where its lamp is.
	GameState.set_time(float(clock.in_day("21:00")))
	assert_array(PlacedArt.pieces(item, 0, 0, post.is_lit())).is_equal([[&"lamp_post_lit", false]])
	var glow: Dictionary = post.glow_now()
	assert_that(glow["at"]).is_equal(Vector2(YARD) * 16.0 + Vector2(8, 3))
	assert_float(float(glow["radius"])).is_equal(22.0)
	assert_bool(glow["flickers"]).override_failure_message("a lamp post's light is steady").is_false()
	assert_that(glow["color"]).is_equal(Ambience.LAMP)
	# At night the area draws a pool of light round it, and its glow.
	farm._process(FRAME)
	var kinds: Array = []
	for light: Dictionary in farm.scene_lights():
		if (light["at"] as Vector2).is_equal_approx(glow["at"]):
			kinds.append(light["kind"])
			assert_bool(light["flickers"]).is_false()
	assert_array(kinds).override_failure_message("a pool and a glow at the lamp").contains_exactly_in_any_order([AreaLighting.POOL, AreaLighting.GLOW])
	# The morning puts it out (the lamps burn on through the first half hour of the day);
	# taken up, its light goes with it.
	GameState.start_next_day()
	assert_bool(post.is_lit()).override_failure_message("06:00: the lamps still burn").is_true()
	GameState.set_time(float(clock.in_day("07:00")))
	assert_bool(post.is_lit()).override_failure_message("morning").is_false()
	assert_bool(_glows_at(farm, YARD)).is_false()
	GameState.set_time(float(clock.in_day("22:00")))
	assert_bool(_glows_at(farm, YARD)).is_true()
	farm.open_build()
	farm.build.point_at(YARD)
	assert_bool(farm.build.take_up()).is_true()
	assert_bool(_glows_at(farm, YARD)).override_failure_message("no lamp, no light").is_false()
	# A fence gives none at any hour.
	assert_bool(_put(farm, &"fence", YARD)).is_true()
	assert_dict(farm.placed.standing_node(YARD).glow_now()).is_empty()


func test_a_sapling_grows_by_the_morning_into_a_tree() -> void:
	_stock()
	var farm: AreaController = _farm()
	var oak: Vector2i = Vector2i(33, 12)
	var cherry: Vector2i = Vector2i(35, 12)
	farm.open_build()
	assert_bool(_put(farm, &"oak_sapling", oak)).is_true()
	assert_bool(_put(farm, &"cherry_sapling", cherry)).is_true()
	farm.build.close()
	var trees_before: int = farm.scenery.by_cell.size()
	# Three pictures as it grows: the oak's over four mornings, the cherry's over six.
	var oak_frames: Array = [&"oak_sapling", &"oak_sapling", &"oak_sapling_1", &"oak_sapling_2"]
	var cherry_frames: Array = [&"cherry_sapling", &"cherry_sapling", &"cherry_sapling_1", &"cherry_sapling_1", &"cherry_sapling_2", &"cherry_sapling_2"]
	for morning: int in 6:
		if morning < 4:
			var young: PlacedThing = farm.placed.standing_node(oak)
			assert_int(young.age).override_failure_message("the oak after %d mornings" % morning).is_equal(morning)
			assert_bool(young.is_grown()).is_false()
			assert_that(Placement.frame_of(young.item, young.age)).override_failure_message("the oak after %d mornings" % morning).is_equal(oak_frames[morning])
			assert_bool(farm.scenery.by_cell.has(oak)).override_failure_message("no tree yet").is_false()
		else:
			assert_bool(farm.placed.standing_node(oak).is_grown()).override_failure_message("an oak from the fourth morning").is_true()
			assert_bool(farm.scenery.by_cell.has(oak)).is_true()
		var bloom: PlacedThing = farm.placed.standing_node(cherry)
		assert_int(bloom.age).is_equal(morning)
		assert_that(Placement.frame_of(bloom.item, bloom.age)).override_failure_message("the cherry after %d mornings" % morning).is_equal(cherry_frames[morning])
		assert_bool(farm.scenery.by_cell.has(cherry)).override_failure_message("the cherry is no tree after %d mornings" % morning).is_false()
		# It blocks at every age, and needs no water: nothing was poured.
		assert_bool(farm.terrain.is_occupied(oak) and farm.terrain.is_occupied(cherry)).is_true()
		_changes = 0
		GameState.start_next_day()
		assert_int(_changes).override_failure_message("the land is told that it grew").is_equal(1)
	assert_bool(farm.scenery.by_cell.has(cherry)).override_failure_message("a cherry tree after six mornings").is_true()
	assert_int(farm.scenery.by_cell.size()).override_failure_message("two more trees on the land").is_equal(trees_before + 2)
	# Each is a tall picture among the area's own trees: its kind's, standing in its cell.
	var oak_tree: Sprite2D = farm.scenery.by_cell[oak]
	assert_object(oak_tree.get_parent()).is_same(farm.scenery)
	assert_str(str(oak_tree.get_meta(&"kind"))).is_equal("oak")
	assert_that(oak_tree.position).override_failure_message("sorted by its foot, as every tree").is_equal(Scenery.foot_of(oak))
	assert_that(oak_tree.region_rect).is_equal(SceneryAtlas.region("oak"))
	assert_bool(SceneryAtlas.is_cherry(str(farm.scenery.by_cell[cherry].get_meta(&"kind")))).is_true()
	assert_bool(farm.placed.has_tree(oak) and farm.placed.has_tree(cherry)).is_true()
	# The hero walks behind it, and its crown fades while he is there.
	assert_bool(farm.terrain.is_occupied(oak)).override_failure_message("a tree blocks its own cell").is_true()
	assert_bool(farm.terrain.is_occupied(oak + Vector2i.UP)).override_failure_message("and only its own").is_false()
	farm.player.motor.place(oak + Vector2i.UP)
	farm.player.sync_from_motor()
	assert_array(farm.scenery.hiding(farm.player.position)).override_failure_message("behind the oak he is under its crown").contains([oak])
	assert_float(farm.player.position.y).override_failure_message("and drawn before it").is_less(oak_tree.position.y)
	for frame: int in 30:
		farm._process(FRAME)
	assert_float(farm.scenery.opacity_of(oak)).override_failure_message("the crown fades").is_less(0.6)
	farm.player.motor.place(START)
	farm.player.sync_from_motor()
	for frame: int in 30:
		farm._process(FRAME)
	assert_float(farm.scenery.opacity_of(oak)).is_equal(1.0)
	# More mornings change nothing more.
	GameState.start_next_day()
	GameState.start_next_day()
	assert_int(GameState.homestead().age_at(oak)).is_equal(4)
	assert_int(GameState.homestead().age_at(cherry)).is_equal(6)
	assert_int(farm.scenery.by_cell.size()).is_equal(trees_before + 2)


func test_taking_up_a_grown_tree_gives_back_its_sapling() -> void:
	_stock()
	var farm: AreaController = _farm()
	farm.open_build()
	assert_bool(_put(farm, &"oak_sapling", YARD)).is_true()
	farm.build.close()
	for morning: int in 4:
		GameState.sleep()
	assert_bool(farm.scenery.by_cell.has(YARD)).override_failure_message("a night in bed is a morning too").is_true()
	assert_int(GameState.item_count(&"oak_sapling")).is_equal(2)
	# A full stack of saplings: the tree can't be carried, and stands.
	GameState.add_item(&"oak_sapling", 50)
	assert_int(GameState.item_count(&"oak_sapling")).is_equal(10)
	farm.open_build()
	farm.build.point_at(YARD)
	assert_bool(farm.build.take_up()).is_false()
	assert_str(farm.hud.message_text()).is_equal("You have no room for the Oak Sapling.")
	assert_bool(farm.scenery.by_cell.has(YARD)).is_true()
	# With room, the tree is gone, a sapling is in the pack, and the cell is free.
	GameState.add_item(&"oak_sapling", -1)
	assert_bool(farm.build.take_up()).is_true()
	assert_int(GameState.item_count(&"oak_sapling")).override_failure_message("a grown tree gives back its sapling").is_equal(10)
	assert_bool(farm.scenery.by_cell.has(YARD)).override_failure_message("the tree is felled").is_false()
	assert_bool(farm.placed.has_tree(YARD)).is_false()
	assert_object(farm.placed.standing_node(YARD)).is_null()
	assert_bool(farm.terrain.is_occupied(YARD)).is_false()
	assert_str(farm.hud.message_text()).is_equal("Taken up: Oak Sapling.")
	# Set down again it starts from the beginning.
	assert_bool(_put(farm, &"oak_sapling", YARD)).is_true()
	assert_int(GameState.homestead().age_at(YARD)).is_equal(0)
	assert_bool(farm.scenery.by_cell.has(YARD)).is_false()
	# The map's own trees are none of this: one can't be taken up.
	var old_tree: Vector2i = Vector2i(34, 8)
	assert_bool(farm.scenery.by_cell.has(old_tree)).is_true()
	farm.build.point_at(old_tree)
	assert_bool(farm.build.take_up()).is_false()
	assert_bool(farm.scenery.by_cell.has(old_tree)).is_true()
	assert_bool(farm.grid.is_solid(old_tree)).is_true()


func test_a_saplings_age_is_saved_and_a_tree_stands_after_loading() -> void:
	_stock()
	var farm: AreaController = _farm()
	farm.open_build()
	assert_bool(_put(farm, &"oak_sapling", Vector2i(33, 12))).is_true()
	farm.build.close()
	GameState.start_next_day()
	GameState.start_next_day()
	farm.open_build()
	assert_bool(_put(farm, &"cherry_sapling", Vector2i(35, 12))).is_true()
	assert_bool(_put(farm, &"lamp_post", Vector2i(34, 13))).is_true()
	assert_bool(_put(farm, &"wooden_flooring", Vector2i(34, 13))).is_true()
	farm.build.close()
	GameState.start_next_day()
	GameState.start_next_day()
	# The oak has seen four mornings and is a tree; the cherry two.
	assert_int(farm.save_here()).is_equal(OK)
	var on_disk: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SaveSystem.slot_path(TEST_SLOT)))
	assert_int(int(on_disk["version"])).is_equal(6)
	assert_dict(on_disk["homestead"]["standing"]).is_equal({
		"33,12": {"item": "oak_sapling", "age": 4.0}, "35,12": {"item": "cherry_sapling", "age": 2.0}, "34,13": {"item": "lamp_post"},
	})
	assert_dict(on_disk["homestead"]["lying"]).is_equal({"34,13": "wooden_flooring"})
	var before: String = JSON.stringify(GameState.to_dict(), "", true)
	GameState.clear()
	assert_int(SaveSystem.load_from_slot(TEST_SLOT)).is_equal(OK)
	assert_str(JSON.stringify(GameState.to_dict(), "", true)).is_equal(before)
	farm = _load(FARM)
	assert_bool(farm.scenery.by_cell.has(Vector2i(33, 12))).override_failure_message("the oak stands as a tree as the land loads").is_true()
	assert_bool(farm.terrain.is_occupied(Vector2i(33, 12))).is_true()
	var cherry: PlacedThing = farm.placed.standing_node(Vector2i(35, 12))
	assert_int(cherry.age).override_failure_message("the cherry's two mornings are kept").is_equal(2)
	assert_that(Placement.frame_of(cherry.item, cherry.age)).is_equal(&"cherry_sapling_1")
	assert_bool(farm.scenery.by_cell.has(Vector2i(35, 12))).is_false()
	assert_that(farm.placed.standing_node(Vector2i(34, 13)).item_id).is_equal(&"lamp_post")
	assert_that(GameState.homestead().lying_at(Vector2i(34, 13))).is_equal(&"wooden_flooring")
	# And it goes on growing from where it was.
	for morning: int in 4:
		GameState.start_next_day()
	assert_bool(farm.scenery.by_cell.has(Vector2i(35, 12))).is_true()


func test_the_hand_lifts_a_thing_and_sets_it_down_elsewhere() -> void:
	_stock()
	var farm: AreaController = _farm()
	var from: Vector2i = Vector2i(33, 12)
	var to: Vector2i = Vector2i(35, 13)
	farm.open_build()
	assert_bool(_put(farm, &"fence", from)).is_true()
	assert_bool(_put(farm, &"stone_flooring", from)).is_true()
	# A full stack of fences: moving goes through no pack, so it is no hindrance.
	GameState.add_item(&"fence", 200)
	_choose(farm, BuildBar.HAND)
	assert_bool(farm.build.is_hand()).is_true()
	farm.build.point_at(Vector2i(34, 12))
	assert_str(farm.hud.build_words()).is_equal("The hand lifts a thing to move it.")
	assert_that(farm.build.ghost_colour()).is_equal(BuildMode.POINTER)
	farm.build.point_at(from)
	assert_str(farm.hud.build_words()).override_failure_message("what stands there before what lies there").is_equal("Lift the Fence")
	assert_that(farm.build.ghost_colour()).is_equal(BuildMode.FITS)
	# A left click lifts it. It is still where it was until it is set down.
	_heard.clear()
	_changes = 0
	assert_bool(farm.build.set_down()).is_true()
	assert_dict(farm.build.lifted).is_equal({"cell": from, "layer": Placement.STANDING, "item": &"fence"})
	assert_that(GameState.homestead().standing_at(from)).is_equal(&"fence")
	assert_bool(farm.terrain.is_occupied(from)).is_true()
	assert_int(_changes).is_equal(0)
	assert_array(_heard).contains_exactly([&"take_up"])
	assert_str(farm.hud.build_words()).is_equal("Put the Fence back")
	# Where it doesn't fit, the ghost is red with the reason, and a click leaves it lifted.
	farm.build.point_at(ROAD)
	assert_str(farm.hud.build_words()).is_equal(Placement.ROAD_WORDS)
	assert_bool(farm.hud.build_refused()).is_true()
	assert_that(farm.build.ghost_colour()).is_equal(BuildMode.REFUSED)
	_heard.clear()
	assert_bool(farm.build.set_down()).is_false()
	assert_array(_heard).contains_exactly([&"nope"])
	assert_bool(farm.build.lifted.is_empty()).is_false()
	farm.build.point_at(START)
	assert_str(farm.hud.build_words()).override_failure_message("not onto the hero").is_equal(Placement.SOMEONE_WORDS)
	# The next click, where it fits, sets it down there: one move, the pack untouched.
	farm.build.point_at(to)
	assert_str(farm.hud.build_words()).is_equal("Set the Fence down here")
	assert_that(farm.build.ghost_colour()).is_equal(BuildMode.FITS)
	_heard.clear()
	assert_bool(farm.build.set_down()).is_true()
	assert_that(GameState.homestead().standing_at(from)).is_equal(&"")
	assert_that(GameState.homestead().standing_at(to)).is_equal(&"fence")
	assert_that(GameState.homestead().lying_at(from)).override_failure_message("the floor it stood on stays").is_equal(&"stone_flooring")
	assert_bool(farm.terrain.is_occupied(from)).override_failure_message("its old cell is free at once").is_false()
	assert_bool(farm.terrain.is_occupied(to)).override_failure_message("and its new one filled").is_true()
	assert_object(farm.placed.standing_node(from)).is_null()
	assert_object(farm.placed.standing_node(to)).is_not_null()
	assert_int(GameState.item_count(&"fence")).override_failure_message("nothing went through the pack").is_equal(99)
	assert_int(_changes).is_equal(1)
	assert_array(_heard).contains_exactly([&"set_down"])
	assert_bool(farm.build.lifted.is_empty()).is_true()
	# With nothing standing there, the hand lifts what lies: the floor.
	farm.build.point_at(from)
	assert_str(farm.hud.build_words()).is_equal("Lift the Stone Flooring")
	assert_bool(farm.build.set_down()).is_true()
	farm.build.point_at(to)
	assert_bool(farm.build.set_down()).override_failure_message("a floor under the fence").is_true()
	assert_that(GameState.homestead().lying_at(to)).is_equal(&"stone_flooring")
	assert_that(GameState.homestead().lying_at(from)).is_equal(&"")
	# A click on its own place puts a lifted thing back; a right click, another choice, or
	# leaving lets it go where it stood.
	farm.build.point_at(to)
	assert_bool(farm.build.set_down()).is_true()
	assert_bool(farm.build.set_down()).override_failure_message("back where it was").is_true()
	assert_bool(farm.build.lifted.is_empty()).is_true()
	assert_that(GameState.homestead().standing_at(to)).is_equal(&"fence")
	for let_go: String in ["right click", "another choice", "leaving"]:
		farm.build.point_at(to)
		assert_bool(farm.build.set_down()).is_true()
		assert_bool(farm.build.lifted.is_empty()).is_false()
		match let_go:
			"right click":
				assert_bool(farm.build.take_up()).override_failure_message("a right click lets go: nothing is taken up").is_false()
			"another choice":
				_choose(farm, &"gate")
				_choose(farm, BuildBar.HAND)
			"leaving":
				farm.build.close()
				assert_bool(farm.build.lifted.is_empty()).override_failure_message("let go as he leaves, not as he comes back").is_true()
				farm.open_build()
		assert_bool(farm.build.lifted.is_empty()).override_failure_message(let_go).is_true()
		assert_that(GameState.homestead().standing_at(to)).override_failure_message("%s: it is where it was" % let_go).is_equal(&"fence")
		assert_int(GameState.item_count(&"fence")).is_equal(99)
	# The hand can't lift what isn't his: bare ground, a tree, weeds.
	for bare: Vector2i in [Vector2i(36, 12), Vector2i(34, 8), Vector2i(36, 7)]:
		farm.build.point_at(bare)
		assert_bool(farm.build.set_down()).override_failure_message("%s" % bare).is_false()
		assert_bool(farm.build.lifted.is_empty()).is_true()


func test_the_hand_moves_a_sapling_with_its_mornings_and_a_tree_as_a_tree() -> void:
	_stock()
	var farm: AreaController = _farm()
	farm.open_build()
	assert_bool(_put(farm, &"oak_sapling", Vector2i(33, 12))).is_true()
	farm.build.close()
	GameState.start_next_day()
	GameState.start_next_day()
	farm.open_build()
	_choose(farm, BuildBar.HAND)
	farm.build.point_at(Vector2i(33, 12))
	assert_bool(farm.build.set_down()).is_true()
	assert_dict(farm.build.lifted).is_equal({"cell": Vector2i(33, 12), "layer": Placement.STANDING, "item": &"oak_sapling"})
	farm.build.point_at(Vector2i(36, 13))
	assert_bool(farm.build.set_down()).is_true()
	assert_int(GameState.homestead().age_at(Vector2i(36, 13))).override_failure_message("its two mornings go with it").is_equal(2)
	assert_int(farm.placed.standing_node(Vector2i(36, 13)).age).is_equal(2)
	farm.build.close()
	GameState.start_next_day()
	GameState.start_next_day()
	assert_bool(farm.scenery.by_cell.has(Vector2i(36, 13))).override_failure_message("grown where it was moved to").is_true()
	# A grown tree lifted and set down is a tree in its new place, and gone from its old.
	farm.open_build()
	assert_bool(farm.build.is_hand()).override_failure_message("the hand is still chosen").is_true()
	farm.build.point_at(Vector2i(36, 13))
	assert_str(farm.hud.build_words()).is_equal("Lift the Oak Sapling")
	assert_bool(farm.build.set_down()).is_true()
	farm.build.point_at(Vector2i(34, 12))
	assert_bool(farm.build.set_down()).is_true()
	assert_bool(farm.scenery.by_cell.has(Vector2i(34, 12))).is_true()
	assert_bool(farm.scenery.by_cell.has(Vector2i(36, 13))).is_false()
	assert_bool(farm.terrain.is_occupied(Vector2i(34, 12))).is_true()
	assert_bool(farm.terrain.is_occupied(Vector2i(36, 13))).is_false()
	assert_int(GameState.item_count(&"oak_sapling")).override_failure_message("no sapling came back: it was moved, not taken up").is_equal(2)
	# Off his land nothing is moved, whatever asks.
	assert_bool(GameState.move_placed(&"village", Vector2i(34, 12), Vector2i(35, 12), Placement.STANDING)).is_false()
	assert_bool(GameState.move_placed(&"homestead", Vector2i(1, 1), Vector2i(35, 12), Placement.STANDING)).override_failure_message("nothing there to move").is_false()


func test_the_workbench_has_three_tabs_and_place_lists_the_nine() -> void:
	GameState.add_item(&"wood", 5)
	GameState.add_item(&"stone", 2)
	var home: AreaController = _load(HOME)
	assert_bool(home.open_craft()).is_true()
	var menu: CraftMenu = home.hud.craft_menu
	assert_str(menu.tab).override_failure_message("it opens on what it always listed").is_equal(Crafting.TAB_MAKE)
	assert_str(menu.tabs_text()).is_equal("[Make]   Place    Build ")
	var make: Array = menu.entries().map(func(recipe: Dictionary) -> String: return str(recipe["id"]))
	assert_bool(make.has("fence") or make.has("dirt_path") or make.has("bench")).override_failure_message("nothing to set down is on Make").is_false()
	# Right turns to "Place": the nine, in the plan's order, six lines at a time.
	_heard.clear()
	menu._unhandled_input(_key(&"move_right"))
	assert_str(menu.tab).is_equal(Crafting.TAB_PLACE)
	assert_str(menu.tabs_text()).is_equal(" Make   [Place]   Build ")
	assert_array(_heard).contains_exactly([&"menu_move"])
	assert_array(menu.entries().map(func(recipe: Dictionary) -> StringName: return StringName(str(recipe["id"])))).is_equal(MADE.map(func(row: Array) -> StringName: return row[0]))
	assert_array(Array(menu.shown_lines())).is_equal([
		"> Dirt Path x4", "  Stone Path x4", "  Wood Path x4", "  Wooden Flooring x4", "  Stone Flooring x4", "  Fence x2",
	])
	# What he hasn't the makings for is greyed: three stone for the flooring, and he has two.
	assert_array(menu.greyed_lines()).is_equal([false, false, false, false, true, false])
	assert_array(Array(menu.need_lines())).is_equal(["Stone 1 of 1"])
	# The list scrolls to the lamp post, which needs three things.
	menu.move_cursor(7)
	assert_array(Array(menu.shown_lines())).is_equal([
		"  Wood Path x4", "  Wooden Flooring x4", "  Stone Flooring x4", "  Fence x2", "  Gate", "> Lamp Post",
	])
	assert_array(Array(menu.need_lines())).is_equal(["Iron Bar 0 of 1", "Coal 0 of 1", "Wood 2 of 2"])
	assert_bool(menu.confirm()).is_false()
	assert_str(menu.note_text()).is_equal(Crafting.LACKING_WORDS)
	# Making a thing: a wood makes two fences, as the plan has it.
	menu.move_cursor(-2)
	assert_bool(menu.confirm()).is_true()
	assert_str(menu.note_text()).is_equal("Made: Fence x2.")
	assert_int(GameState.item_count(&"fence")).is_equal(2)
	assert_int(GameState.item_count(&"wood")).is_equal(4)
	assert_that(GameState.equipped).override_failure_message("nothing made here goes in his hand").is_equal(&"")
	# Left turns back, and round; a click on a tab's name turns to it, and beside the names does nothing.
	menu._unhandled_input(_key(&"move_left"))
	assert_str(menu.tab).is_equal(Crafting.TAB_MAKE)
	assert_int(menu.selected).override_failure_message("a tab starts at its top").is_equal(0)
	menu._unhandled_input(_key(&"move_left"))
	assert_str(menu.tab).override_failure_message("round, to the buildings' tab (phase 3)").is_equal(Crafting.TAB_BUILD)
	var tabs: Label = menu.get_node(^"Panel/Tabs")
	await await_idle_frame()
	menu._unhandled_input(_click_at(tabs.get_global_transform_with_canvas() * Vector2(6.0, 5.0)))
	assert_str(menu.tab).override_failure_message("a click on Make").is_equal(Crafting.TAB_MAKE)
	var past_make: float = MenuInput.width_of(tabs, menu.tab_parts()[0]) + MenuInput.width_of(tabs, CraftMenu.TAB_GAP) + 5.0
	menu._unhandled_input(_click_at(tabs.get_global_transform_with_canvas() * Vector2(past_make, 5.0)))
	assert_str(menu.tab).override_failure_message("a click on Place").is_equal(Crafting.TAB_PLACE)
	var fences: int = GameState.item_count(&"fence")
	menu._unhandled_input(_click_at(tabs.get_global_transform_with_canvas() * Vector2(tabs.size.x - 2.0, 5.0)))
	assert_str(menu.tab).is_equal(Crafting.TAB_PLACE)
	assert_int(GameState.item_count(&"dirt_path") + GameState.item_count(&"fence")).override_failure_message("a click beside the names makes nothing").is_equal(fences)
	# Opened again it is on "Make" again.
	menu.close()
	home.open_craft()
	assert_str(menu.tab).is_equal(Crafting.TAB_MAKE)


func test_a_recipes_tab_is_checked_as_the_data_loads() -> void:
	var item_of: Callable = func(id: String) -> Dictionary: return DataRegistry.get_item(StringName(id))
	var good: Dictionary = {"id": "fence", "tab": "place", "needs": [{"item": "wood", "count": 1}], "makes": {"item": "fence", "count": 2}}
	assert_array(Array(Crafting.problems(good, item_of, [], []))).is_empty()
	assert_str(Crafting.tab_of(good)).is_equal("place")
	assert_str(Crafting.tab_of({"id": "bombs"})).override_failure_message("a recipe that names no tab is on Make").is_equal("make")
	assert_array(Crafting.TABS).override_failure_message("phase 3 added its own").is_equal(["make", "place", "build"])
	var odd: Dictionary = good.duplicate(true)
	odd["tab"] = "attic"
	assert_array(Array(Crafting.problems(odd, item_of, [], []))).contains_exactly(["'tab' must be one of: make, place, build."])
	var smelted: Dictionary = {"id": "bar", "station": "furnace", "tab": "place", "needs": [{"item": "coal", "count": 1}], "makes": {"item": "copper_bar"}}
	assert_array(Array(Crafting.problems(smelted, item_of, [], []))).contains_exactly(["only the workbench's list has tabs."])
	assert_array(Crafting.of_tab([good, {"id": "bombs"}, odd, 7], "place")).is_equal([good])
	assert_array(Crafting.of_tab([good, {"id": "bombs"}], "make")).is_equal([{"id": "bombs"}])


func test_tilda_sells_hedges_flower_beds_saplings_and_fibre() -> void:
	GameState.add_item(&"coin", 30)
	var shop: AreaController = _load(SHOP)
	assert_bool(shop.open_shop(&"tilda", Shop.BUY)).is_true()
	var counter: ShopMenu = shop.hud.shop_menu
	var wares: Array = counter.entries().map(func(ware: Dictionary) -> String: return str(ware["item"]))
	# Her old wares, then what is for the land, then the seeds.
	assert_array(wares.slice(0, 11)).is_equal(["arrow", "bomb", "bread", "pickaxe", "fibre", "hedge", "flower_bed_red", "flower_bed_yellow", "flower_bed_blue", "oak_sapling", "cherry_sapling"])
	assert_int(wares.size()).override_failure_message("eleven wares and five seeds").is_equal(16)
	counter.move_cursor(4)
	assert_array(Array(counter.shown_lines())).is_equal(["  Arrows x10: 5 coins", "  Bombs x3: 8 coins", "  Bread: 6 coins", "  Pickaxe: 25 coins", "> Fibre x5: 6 coins"])
	assert_bool(counter.confirm()).is_true()
	assert_int(GameState.item_count(&"fibre")).override_failure_message("five at a time").is_equal(5)
	assert_int(GameState.item_count(&"coin")).is_equal(24)
	counter.move_cursor(1)
	assert_bool(counter.confirm()).is_true()
	assert_int(GameState.item_count(&"hedge")).is_equal(1)
	counter.move_cursor(1)
	assert_bool(counter.confirm()).is_true()
	assert_int(GameState.item_count(&"flower_bed_red")).is_equal(1)
	counter.move_cursor(3)
	assert_bool(counter.confirm()).override_failure_message("an oak sapling for ten").is_true()
	assert_int(GameState.item_count(&"oak_sapling")).is_equal(1)
	assert_int(GameState.item_count(&"coin")).is_equal(6)
	# A cherry sapling is thirty: more than he has left.
	counter.move_cursor(1)
	assert_array(Array(counter.shown_lines())).contains(["> Cherry Sapling: 30 coins"])
	assert_bool(counter.confirm()).is_false()
	assert_str(counter.note_text()).is_equal(Shop.NO_COINS)
	assert_int(GameState.item_count(&"cherry_sapling")).is_equal(0)
	# What he bought he can't sell back: she buys crops, ore and bars.
	counter.switch_mode()
	assert_array(counter.entries()).is_empty()


func test_a_yard_is_made_fenced_gated_paved_and_lit_taken_up_and_there_after_a_save() -> void:
	# The plan's "done when", from the makings: wood, stone, an iron bar and coal at the bench.
	for item: Array in [[&"wood", 20], [&"stone", 12], [&"iron_bar", 1], [&"coal", 1], [&"coin", 20]]:
		GameState.add_item(item[0], item[1])
	for made: Array in [[&"fence", 6], [&"gate", 1], [&"stone_flooring", 2], [&"lamp_post", 1]]:
		for time: int in made[1]:
			assert_str(GameState.craft(made[0])).override_failure_message(String(made[0])).is_equal("")
	assert_int(GameState.item_count(&"fence")).is_equal(12)
	assert_int(GameState.item_count(&"stone_flooring")).is_equal(8)
	assert_int(GameState.item_count(&"wood")).override_failure_message("six for the fences, three for the gate, two for the lamp").is_equal(9)
	assert_str(GameState.buy({"item": "hedge", "count": 1, "price": 5})).is_equal("")
	var farm: AreaController = _farm()
	farm._unhandled_input(_key(&"build"))
	# A yard of 3 by 2 inside a fence, with a gate in its south side.
	var fence: Array[Vector2i] = []
	for x: int in range(32, 37):
		fence.append(Vector2i(x, 10))
	for y: int in [11, 12]:
		fence.append(Vector2i(32, y))
		fence.append(Vector2i(36, y))
	for x: int in [32, 33, 35, 36]:
		fence.append(Vector2i(x, 13))
	assert_int(fence.size()).is_equal(13)
	# Thirteen cells and twelve fences: the hedge fills the gap.
	for cell: Vector2i in fence.slice(0, 12):
		assert_bool(_put(farm, &"fence", cell)).override_failure_message("a fence at %s" % cell).is_true()
	assert_bool(_put(farm, &"hedge", fence[12])).is_true()
	assert_bool(_put(farm, &"gate", Vector2i(34, 13))).is_true()
	for cell: Vector2i in [Vector2i(33, 11), Vector2i(34, 11), Vector2i(35, 11), Vector2i(33, 12), Vector2i(34, 12), Vector2i(35, 12), Vector2i(34, 13)]:
		assert_bool(_put(farm, &"stone_flooring", cell)).override_failure_message("paving at %s" % cell).is_true()
	assert_bool(_put(farm, &"lamp_post", Vector2i(35, 11))).is_true()
	farm.build._unhandled_input(_key(&"build"))
	assert_bool(farm.is_building()).is_false()
	assert_int(GameState.homestead().placed_count()).is_equal(22)
	# He walks in through the gate and no other way.
	farm.player.motor.place(Vector2i(34, 14))
	_walk(farm, Vector2.UP, 60)
	assert_that(farm.player.motor.cell).override_failure_message("through the gate, up to the fence at the back").is_equal(Vector2i(34, 11))
	farm.player.motor.place(Vector2i(31, 12))
	_walk(farm, Vector2.RIGHT, 40)
	assert_that(farm.player.motor.cell).override_failure_message("the fence keeps him out").is_equal(Vector2i(31, 12))
	# After dark the lamp lights it.
	GameState.set_time(float(GameState.day_clock().in_day("21:00")))
	assert_bool(_glows_at(farm, Vector2i(35, 11))).is_true()
	# Saved, loaded, and there.
	assert_int(farm.save_here()).is_equal(OK)
	GameState.clear()
	assert_int(SaveSystem.load_from_slot(TEST_SLOT)).is_equal(OK)
	farm = _load(FARM)
	assert_int(GameState.homestead().placed_count()).is_equal(22)
	assert_int(farm.placed.standing_nodes().size()).is_equal(15)
	assert_bool(_glows_at(farm, Vector2i(35, 11))).override_failure_message("still lit after the load: it is night").is_true()
	# Taken up again, every piece is back in the pack and the land is as it was.
	farm.open_build()
	var view: Rect2i = farm.build.view_cells()
	for x: int in range(32, 37):
		for y: int in range(10, 14):
			assert_bool(view.has_point(Vector2i(x, y))).is_true()
			farm.build.point_at(Vector2i(x, y))
			while GameState.homestead().standing_at(Vector2i(x, y)) != &"" or GameState.homestead().lying_at(Vector2i(x, y)) != &"":
				assert_bool(farm.build.take_up()).is_true()
	assert_int(GameState.homestead().placed_count()).is_equal(0)
	assert_int(farm.placed.standing_nodes().size()).is_equal(0)
	for item: Array in [[&"fence", 12], [&"gate", 1], [&"stone_flooring", 8], [&"lamp_post", 1], [&"hedge", 1]]:
		assert_int(GameState.item_count(item[0])).override_failure_message(String(item[0])).is_equal(item[1])
	for x: int in range(32, 37):
		for y: int in range(10, 14):
			assert_bool(farm.terrain.is_occupied(Vector2i(x, y))).override_failure_message("%d,%d is free" % [x, y]).is_false()


# --- helpers ---------------------------------------------------------------

## A stock of everything that can be set down.
func _stock() -> void:
	for item: Array in [[&"fence", 12], [&"gate", 2], [&"stone_flooring", 8], [&"wooden_flooring", 8], [&"hedge", 4], [&"lamp_post", 3],
			[&"bench", 2], [&"flower_bed_red", 3], [&"flower_bed_yellow", 3], [&"flower_bed_blue", 3], [&"oak_sapling", 3], [&"cherry_sapling", 3]]:
		GameState.add_item(item[0], item[1])


## Chooses `item_id` on the build bar, points the ghost at `at`, and sets it down. Returns
## whether it was set down.
func _put(farm: AreaController, item_id: StringName, at: Vector2i) -> bool:
	_choose(farm, item_id)
	farm.build.point_at(at)
	assert_that(farm.build.cell).override_failure_message("%s is on screen" % at).is_equal(at)
	return farm.build.set_down()


## Chooses `id` on the build bar (BuildBar.HAND, or a thing he carries), whichever slot it is in.
func _choose(farm: AreaController, id: StringName) -> void:
	for step: int in farm.build.entries().size():
		if farm.build.chosen == id:
			break
		farm.build.step(1)
	assert_that(farm.build.chosen).override_failure_message("%s is on the bar" % id).is_equal(id)


## Whether the area shows a light in `cell` now.
func _glows_at(farm: AreaController, cell: Vector2i) -> bool:
	var around: Rect2 = Rect2(Vector2(cell) * 16.0, Vector2(16, 16))
	for glow: Dictionary in farm.glows_now():
		if around.has_point(glow["at"]):
			return true
	return false


## The homestead with the hero in the yard, facing east.
func _farm() -> AreaController:
	GameState.update_player(&"homestead", START)
	var farm: AreaController = _load(FARM)
	farm.player.face(Vector2.RIGHT)
	return farm


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area


## Walks the hero `direction` for `frames` frames.
func _walk(area: AreaController, direction: Vector2, frames: int) -> void:
	for frame: int in frames:
		area.player.motor.step(direction, FRAME)
	area.player.sync_from_motor()


## A key (or pad button) of `action`, pressed.
func _key(action: StringName) -> InputEventAction:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = true
	return event


## A left click at the screen's point `at`.
func _click_at(at: Vector2) -> InputEventMouseButton:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = at
	event.global_position = at
	return event


func _on_sound(id: StringName) -> void:
	_heard.append(id)


func _on_homestead_changed() -> void:
	_changes += 1
