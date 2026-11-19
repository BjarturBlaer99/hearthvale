extends GdUnitTestSuite
## The buildings' plans (the Homestead, phase 3, step 3a): the workbench's "Build" tab lists
## them with their materials and coins; a plan bought is a kit in the pack (never in a chest,
## never on the item bar), and one of each; in build mode a kit's ghost covers every cell of
## its building and its doorstep, green or red with the first reason found; set down, it is a
## building site today (its cells filled) and the building the next morning, through a save.
## The Well fills the can; the meadow's tall grass gives hay, back each morning, and the Silo
## takes the hay he carries, as much as it holds. A tuft doesn't grow where something is set
## down.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const FARM: String = "res://world/areas/homestead/homestead.tscn"
const HOME: String = "res://world/areas/home/home.tscn"
const TEST_SLOT: int = 953
const FRAME: float = 1.0 / 60.0
const OLD_SAVES: String = "res://tests/fixtures/saves"
const V6: String = "v6_a_yard_on_the_farm.json"
## Open grass east of the farmhouse, where the hero stands.
const START: Vector2i = Vector2i(30, 13)
## The cell the ghost holds the Well by (the middle of its bottom row): its corner is (33, 11).
const WELL_AT: Vector2i = Vector2i(34, 12)
const WELL_CORNER: Vector2i = Vector2i(33, 11)
const SILO_CORNER: Vector2i = Vector2i(36, 11)
## The meadow's fourteen tufts of tall grass.
const TUFTS: Array[Vector2i] = [
	Vector2i(4, 3), Vector2i(6, 3), Vector2i(9, 3), Vector2i(11, 3), Vector2i(13, 3),
	Vector2i(5, 4), Vector2i(8, 4), Vector2i(10, 4), Vector2i(12, 4),
	Vector2i(4, 5), Vector2i(7, 5), Vector2i(9, 5), Vector2i(11, 5), Vector2i(13, 5),
]

var _area: Node
var _heard: Array[StringName] = []
var _finished: Array = []


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	Quests.refresh()
	GameState.set_time(float(GameState.day_clock().in_day("12:00")))
	SaveSystem.erase_slot(TEST_SLOT)
	SaveSystem.current_slot = TEST_SLOT
	_heard.clear()
	_finished.clear()
	EventBus.sound.connect(_on_sound)
	EventBus.building_finished.connect(_on_finished)


func after_test() -> void:
	EventBus.sound.disconnect(_on_sound)
	EventBus.building_finished.disconnect(_on_finished)
	if is_instance_valid(_area):
		_area.free()
	_area = null
	SaveSystem.erase_slot(TEST_SLOT)
	SaveSystem.current_slot = SaveSystem.GAME_SLOT
	GameState.clear()


func test_the_build_tab_lists_the_plans_with_their_materials_and_coins() -> void:
	var home: AreaController = _load(HOME)
	home.open_craft()
	var menu: CraftMenu = home.hud.craft_menu
	assert_bool(menu.show_tab(Crafting.TAB_BUILD)).is_true()
	assert_str(menu.tabs_text()).is_equal(" Make    Place   [Build]")
	assert_array(menu.entries()).override_failure_message("a new game knows no plan yet").is_empty()
	assert_array(Array(menu.shown_lines())).is_equal([CraftMenu.NOTHING_WORDS])
	menu.close()
	# A copper bar found, the Well and the Shed are known; Farming 2, the Silo.
	GameState.add_item(&"copper_bar", 1)
	GameState.skill_points[Skills.FARMING] = 10
	home.open_craft()
	menu.show_tab(Crafting.TAB_BUILD)
	assert_array(menu.entries().map(func(recipe: Dictionary) -> String: return str(recipe["id"]))).is_equal(["well", "silo", "shed"])
	assert_array(Array(menu.shown_lines())).is_equal(["> Well", "  Silo", "  Shed"])
	assert_array(menu.greyed_lines()).is_equal([true, true, true])
	assert_array(Array(menu.need_lines())).is_equal(["Stone 0 of 40", "Wood 0 of 10", "Copper Bar 1 of 1", "Coins 0 of 80"])
	# Refused, it says what he is short of.
	assert_bool(menu.confirm()).is_false()
	assert_str(menu.note_text()).is_equal("You are short of 40 Stone, 10 Wood and 80 Coins.")
	assert_int(GameState.item_count(&"copper_bar")).override_failure_message("nothing was taken").is_equal(1)
	menu.move_cursor(1)
	assert_array(Array(menu.need_lines())).is_equal(["Stone 0 of 30", "Wood 0 of 10", "Copper Bar 1 of 2", "Coins 0 of 100"])
	GameState.add_item(&"stone", 30)
	GameState.add_item(&"wood", 10)
	GameState.add_item(&"coin", 99)
	GameState.add_item(&"copper_bar", 1)
	assert_str(GameState.craft(&"silo")).is_equal("You are short of 1 Coin.")
	GameState.add_item(&"coin", 1)
	assert_bool(menu.confirm()).is_true()
	assert_str(menu.note_text()).is_equal("Bought: Silo Kit. Set it down in build mode.")
	assert_int(GameState.item_count(&"silo_kit")).is_equal(1)
	for spent: StringName in [&"stone", &"wood", &"copper_bar", &"coin"]:
		assert_int(GameState.item_count(spent)).override_failure_message("%s went" % spent).is_equal(0)


func test_a_plan_bought_is_a_kit_one_of_each_and_never_in_a_chest() -> void:
	_stock_for_the_well()
	assert_str(GameState.craft(&"well")).is_empty()
	assert_int(GameState.item_count(&"well_kit")).is_equal(1)
	assert_int(GameState.item_count(&"stone")).is_equal(10)
	assert_int(GameState.item_count(&"coin")).is_equal(120)
	# One of each: with the kit in the pack, as a site and as a building.
	assert_str(GameState.craft(&"well")).is_equal(Crafting.HAVE_ONE_WORDS)
	assert_bool(GameState.set_down_kit(&"homestead", WELL_CORNER, &"well_kit")).is_true()
	assert_str(GameState.craft(&"well")).override_failure_message("a site").is_equal(Crafting.HAVE_ONE_WORDS)
	GameState.start_next_day()
	assert_str(GameState.craft(&"well")).override_failure_message("a building").is_equal(Crafting.HAVE_ONE_WORDS)
	assert_int(GameState.item_count(&"coin")).override_failure_message("nothing more was taken").is_equal(120)
	# A kit stays with him: never in a chest, never on the item bar, always on the build bar.
	GameState.add_item(&"silo_kit")
	assert_str(GameState.store_put(&"silo_kit")).is_equal(Store.NOT_KEPT_WORDS)
	assert_bool(Store.can_hold({"id": "kit", "type": Buildings.KIT_TYPE, "stackable": true})).override_failure_message("a kit is kept out by its type, whether it stacks or not").is_false()
	assert_bool(GameState.storable_stacks().any(func(stack: Dictionary) -> bool: return str(stack["id"]) == "silo_kit")).is_false()
	assert_bool(GameState.hand_entries().any(func(entry: Dictionary) -> bool: return str(entry["id"]) == "silo_kit")).is_false()
	assert_that(GameState.equipped).is_equal(&"")
	var bar: Array = BuildBar.entries(GameState.inventory, DataRegistry.entries(&"items")).map(func(entry: Dictionary) -> String: return str(entry["id"]))
	assert_array(bar).is_equal(["hand", "silo_kit"])
	# A kit doesn't stack: one of each.
	assert_int(GameState.add_item(&"silo_kit")).is_equal(0)
	assert_bool(GameState.has_room_for(&"silo_kit")).is_false()


func test_a_kits_ghost_covers_its_cells_and_says_the_first_reason_found() -> void:
	GameState.add_item(&"well_kit")
	GameState.add_item(&"fence", 1)
	GameState.set_down(&"homestead", Vector2i(35, 13), &"fence")
	var farm: AreaController = _farm()
	await await_idle_frame()
	assert_bool(farm.open_build()).is_true()
	_choose(farm, &"well_kit")
	farm.build.point_at(WELL_AT)
	assert_that(farm.build.building_origin()).is_equal(WELL_CORNER)
	assert_dict(farm.build.building_in_hand()).is_equal(DataRegistry.get_building(&"well"))
	assert_str(farm.build.why_not()).is_empty()
	assert_bool(farm.build.fits()).is_true()
	assert_that(farm.build.ghost_colour()).is_equal(BuildMode.FITS)
	assert_str(farm.build.words()).is_equal("Well Kit x1")
	# Red, with the first reason found over any of its cells.
	for case: Array in [
			[Vector2i(32, 11), Placement.NO_GROUND_WORDS, "over the farmhouse's wall"],
			[Vector2i(33, 15), Placement.ROAD_WORDS, "on the road"],
			[Vector2i(31, 14), Placement.SOMEONE_WORDS, "where the hero stands"],
			[Vector2i(36, 14), Placement.TAKEN_WORDS, "on the fence"],
			[Vector2i(5, 4), Placement.CLEAR_FIRST_WORDS, "on the meadow's tall grass"],
			[Vector2i(37, 10), Placement.CLEAR_FIRST_WORDS, "on the weeds at (36, 9)"],
			[Vector2i(24, 19), Placement.FIELD_WORDS, "on the field"]]:
		farm.build.point_at(case[0])
		assert_str(farm.build.why_not()).override_failure_message(case[2]).is_equal(case[1])
		assert_that(farm.build.ghost_colour()).override_failure_message(case[2]).is_equal(BuildMode.REFUSED)
		assert_str(farm.hud.build_words()).override_failure_message(case[2]).is_equal(case[1])
		assert_bool(farm.build.set_down()).override_failure_message(case[2]).is_false()
	assert_int(GameState.item_count(&"well_kit")).override_failure_message("refused, it is still in the pack").is_equal(1)
	assert_bool(GameState.homestead().has_building(&"well")).is_false()
	# Set down where it fits: a site, its cells filled, the kit gone and the hand chosen.
	farm.build.point_at(WELL_AT)
	_heard.clear()
	assert_bool(farm.build.set_down()).is_true()
	assert_array(_heard).contains([&"set_down"])
	assert_int(GameState.item_count(&"well_kit")).is_equal(0)
	assert_that(farm.build.chosen).is_equal(BuildBar.HAND)
	assert_that(GameState.homestead().building_at(&"well")).is_equal(WELL_CORNER)
	assert_int(GameState.homestead().building_day(&"well")).is_equal(GameState.day)
	assert_bool(GameState.is_built(&"well")).override_failure_message("a site today").is_false()
	assert_object(farm.buildings.spot(&"well")).is_not_null()
	for cell: Vector2i in Buildings.cells_of(DataRegistry.get_building(&"well"), WELL_CORNER):
		assert_bool(farm.terrain.is_occupied(cell)).override_failure_message("%s is filled" % cell).is_true()
		assert_that(GameState.building_covering(&"homestead", cell)).is_equal(&"well")
	assert_bool(farm.terrain.is_occupied(WELL_CORNER + Vector2i(2, 0))).is_false()
	# A site's cells are no ground for anything else.
	_choose(farm, &"fence")
	assert_bool(farm.build.is_hand()).override_failure_message("the last fence was set down earlier").is_true()
	GameState.add_item(&"fence", 1)
	_choose(farm, &"fence")
	farm.build.point_at(WELL_CORNER)
	assert_str(farm.build.why_not()).is_equal(Placement.NO_GROUND_WORDS)
	# Nowhere but the land: the village knows nothing of kits.
	assert_bool(GameState.set_down_kit(&"village", Vector2i(10, 10), &"silo_kit")).is_false()
	GameState.add_item(&"silo_kit")
	assert_bool(GameState.set_down_kit(&"village", Vector2i(10, 10), &"silo_kit")).is_false()
	assert_bool(GameState.set_down_kit(&"homestead", SILO_CORNER, &"fence")).override_failure_message("a fence is no kit").is_false()


func test_a_site_stands_the_next_morning_through_a_save() -> void:
	GameState.add_item(&"well_kit")
	assert_bool(GameState.set_down_kit(&"homestead", WELL_CORNER, &"well_kit")).is_true()
	GameState.update_player(&"homestead", START)
	assert_int(SaveSystem.save_game()).is_equal(OK)
	var on_disk: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SaveSystem.slot_path(TEST_SLOT)))
	assert_int(int(on_disk["version"])).override_failure_message("still version 6 (D30)").is_equal(6)
	assert_dict(on_disk["homestead"]["buildings"]).override_failure_message("JSON's numbers are floats").is_equal({"well": {"at": "33,11", "day": 1.0}})
	GameState.clear()
	assert_int(SaveSystem.load_game()).is_equal(OK)
	assert_bool(GameState.homestead().is_site(&"well", GameState.day)).is_true()
	var farm: AreaController = _load(FARM)
	assert_bool(farm.buildings.spot(&"well").stands()).is_false()
	# The morning: it stands, he is told, and the building's sound is heard.
	_heard.clear()
	GameState.start_next_day()
	assert_array(_finished).is_equal([[&"well", false]])
	assert_bool(GameState.is_built(&"well")).is_true()
	assert_array(_heard).contains([&"built"])
	assert_array(Array(farm.hud.notice_lines())).contains(["The Well stands on your farm."])
	assert_array(Array(GameState.morning_news)).override_failure_message("said once").is_empty()
	# A morning that comes while he is away is said where he next arrives.
	GameState.add_item(&"silo_kit")
	GameState.set_down_kit(&"homestead", SILO_CORNER, &"silo_kit")
	farm.free()
	_area = null
	GameState.start_next_day()
	assert_array(Array(GameState.morning_news)).is_equal(["The Silo stands on your farm."])
	_heard.clear()
	farm = _load(HOME)
	assert_array(Array(farm.hud.notice_lines())).contains(["The Silo stands on your farm."])
	assert_array(_heard).contains([&"built"])
	assert_array(Array(GameState.morning_news)).is_empty()
	# Through a save and back, both stand.
	GameState.update_player(&"homestead", START)
	SaveSystem.save_game()
	GameState.clear()
	SaveSystem.load_game()
	assert_bool(GameState.is_built(&"well")).is_true()
	assert_bool(GameState.is_built(&"silo")).is_true()
	assert_that(GameState.homestead().building_at(&"silo")).is_equal(SILO_CORNER)


func test_the_well_fills_the_can_once_it_stands() -> void:
	GameState.add_item(&"watering_can")
	GameState.add_item(&"water", 2)
	GameState.equip(&"watering_can")
	GameState.add_item(&"well_kit")
	GameState.set_down_kit(&"homestead", WELL_CORNER, &"well_kit")
	var farm: AreaController = _farm()
	# A site is no well yet.
	_stand(farm, WELL_CORNER + Vector2i(0, 2), Vector2.UP)
	assert_bool(farm.is_water_source(WELL_CORNER)).is_false()
	assert_bool(farm.use_item()).is_false()
	assert_int(GameState.item_count(&"water")).is_equal(2)
	GameState.start_next_day()
	farm = _farm()
	for cell: Vector2i in Buildings.cells_of(DataRegistry.get_building(&"well"), WELL_CORNER):
		assert_bool(farm.is_water_source(cell)).override_failure_message("%s" % cell).is_true()
	assert_bool(farm.is_water_source(WELL_CORNER + Vector2i(2, 0))).is_false()
	# From below it, and from its side.
	_stand(farm, WELL_CORNER + Vector2i(1, 2), Vector2.UP)
	_heard.clear()
	assert_bool(farm.use_item()).is_true()
	assert_int(GameState.item_count(&"water")).is_equal(10)
	# The sound comes when the tool lands (tool polish).
	Steps.to_the_blow(farm)
	assert_array(_heard).contains([&"fill"])
	assert_str(farm.hud.message_text()).is_equal(AreaController.CAN_FILLED_WORDS)
	_rest(farm)
	GameState.add_item(&"water", -6)
	_stand(farm, WELL_CORNER + Vector2i(-1, 1), Vector2.RIGHT)
	assert_bool(farm.use_hand()).override_failure_message("the left click fills it too").is_true()
	assert_int(GameState.item_count(&"water")).is_equal(10)


func test_the_meadows_tall_grass_gives_hay_and_is_back_the_next_morning() -> void:
	var farm: AreaController = _farm()
	var tufts: Array = _tufts(farm)
	assert_array(tufts.map(func(tuft: Breakable) -> Vector2i: return tuft.cell())).contains_exactly_in_any_order(TUFTS)
	for tuft: Breakable in tufts:
		assert_bool(tuft.is_daily()).is_true()
		assert_bool(farm.terrain.is_occupied(tuft.cell())).override_failure_message("tall grass is in the way until cut").is_true()
	assert_object(farm.debris_at(TUFTS[0])).override_failure_message("it is no debris: it comes back").is_null()
	# Cut, it leaves a hay lying, which he walks onto.
	var tuft: Breakable = tufts[0]
	var hay: Node2D = tuft.smash()
	assert_object(hay).is_instanceof(ItemDrop)
	assert_that((hay as ItemDrop).item_id).is_equal(&"hay")
	farm.player.motor.place(tuft.cell())
	farm.player.sync_from_motor()
	assert_int(farm.collect_pickups()).is_equal(1)
	assert_int(GameState.item_count(&"hay")).is_equal(1)
	# The same day it stays cut; the next morning it is back.
	var cut: Vector2i = tuft.cell()
	farm = _farm()
	assert_bool(_tuft_at(farm, cut).broken).override_failure_message("cut today").is_true()
	assert_bool(farm.terrain.is_occupied(cut)).is_false()
	GameState.start_next_day()
	farm = _farm()
	assert_bool(_tuft_at(farm, cut).broken).override_failure_message("back the next morning").is_false()
	assert_bool(farm.terrain.is_occupied(cut)).is_true()


func test_the_silo_takes_the_hay_he_carries_and_a_full_one_leaves_it_in_the_pack() -> void:
	GameState.add_item(&"silo_kit")
	GameState.set_down_kit(&"homestead", SILO_CORNER, &"silo_kit")
	GameState.add_item(&"hay", 14)
	var farm: AreaController = _farm()
	_stand(farm, SILO_CORNER + Vector2i(0, 2), Vector2.UP)
	assert_str(farm.buildings.spot(&"silo").prompt()).override_failure_message("a site takes nothing").is_empty()
	assert_bool(farm.interact()).is_false()
	assert_int(GameState.item_count(&"hay")).is_equal(14)
	# Asked of GameState itself, a site takes nothing either.
	assert_str(GameState.put_hay(&"silo")).is_empty()
	assert_int(GameState.homestead().hay).is_equal(0)
	GameState.start_next_day()
	farm = _farm()
	_stand(farm, SILO_CORNER + Vector2i(0, 2), Vector2.UP)
	farm._update_hud()
	assert_str(farm.hud.prompt_text()).contains("Put hay in the Silo")
	assert_bool(farm.interact()).is_true()
	assert_str(farm.hud.message_text()).is_equal("You put 14 hay in the silo. It holds 14 of 60.")
	assert_int(GameState.item_count(&"hay")).is_equal(0)
	assert_int(GameState.homestead().hay).is_equal(14)
	assert_bool(farm.interact()).is_true()
	assert_str(farm.hud.message_text()).is_equal("You carry no hay. The silo holds 14 of 60.")
	# Fuller than it holds: what doesn't fit stays in the pack.
	GameState.add_item(&"hay", 50)
	farm.interact()
	assert_str(farm.hud.message_text()).is_equal("You put 46 hay in the silo. It holds 60 of 60.")
	assert_int(GameState.item_count(&"hay")).is_equal(4)
	farm.interact()
	assert_str(farm.hud.message_text()).is_equal("The silo is full: it holds 60 hay.")
	assert_int(GameState.item_count(&"hay")).override_failure_message("a full silo leaves it in the pack").is_equal(4)
	# Through a save.
	GameState.update_player(&"homestead", START)
	SaveSystem.save_game()
	GameState.clear()
	SaveSystem.load_game()
	assert_int(GameState.homestead().hay).is_equal(60)
	assert_int(GameState.item_count(&"hay")).is_equal(4)


func test_a_tuft_does_not_grow_where_something_is_set_down() -> void:
	# A save from phase 2, when the meadow's tufts were plain grass: a path, a fence and a
	# sapling stand on three of them.
	var old: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OLD_SAVES.path_join(V6)))
	GameState.from_dict(SaveSystem.migrate(old, int(old["version"])))
	var farm: AreaController = _load(FARM)
	var cells: Array = _tufts(farm).map(func(tuft: Breakable) -> Vector2i: return tuft.cell())
	assert_int(cells.size()).is_equal(11)
	for under: Vector2i in [Vector2i(4, 3), Vector2i(6, 3), Vector2i(9, 3)]:
		assert_bool(cells.has(under)).override_failure_message("no tuft under what stands at %s" % under).is_false()
	assert_bool(farm.terrain.is_occupied(Vector2i(4, 3))).override_failure_message("the path is walked on").is_false()
	assert_bool(farm.terrain.is_occupied(Vector2i(6, 3))).override_failure_message("the fence fills its cell").is_true()
	assert_bool(farm.terrain.is_occupied(Vector2i(9, 3))).override_failure_message("so does the sapling").is_true()
	assert_object(farm.placed.standing_node(Vector2i(6, 3))).is_not_null()
	# Taken up again, the tuft is back on the next visit.
	GameState.take_up(&"homestead", Vector2i(6, 3), Placement.STANDING)
	farm = _load(FARM)
	assert_object(_tuft_at(farm, Vector2i(6, 3))).is_not_null()
	assert_bool(farm.terrain.is_occupied(Vector2i(6, 3))).is_true()


# --- Helpers -------------------------------------------------------------------------------

func _stock_for_the_well() -> void:
	for stack: Array in [[&"stone", 50], [&"wood", 30], [&"copper_bar", 3], [&"coin", 200]]:
		GameState.add_item(stack[0], stack[1])


## The homestead with the hero in the yard, facing east.
func _farm() -> AreaController:
	GameState.update_player(&"homestead", START)
	var farm: AreaController = _load(FARM)
	farm.player.face(Vector2.RIGHT)
	return farm


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area


## Steps along the build bar until `id` is chosen (or round once).
func _choose(farm: AreaController, id: StringName) -> void:
	for step: int in farm.build.entries().size():
		if farm.build.chosen == id:
			return
		farm.build.step(1)


func _stand(area: AreaController, cell: Vector2i, way: Vector2) -> void:
	area.player.motor.place(cell)
	area.player.face(way)


func _rest(area: AreaController) -> void:
	for i: int in 40:
		area.player.motor.step(Vector2.ZERO, FRAME)


## The meadow's tufts in the area (the daily breakables of the land).
func _tufts(area: AreaController) -> Array:
	return area.interactables.get_children().filter(func(child: Node) -> bool: return child is Breakable and (child as Breakable).breakable_id == &"meadow_grass")


func _tuft_at(area: AreaController, cell: Vector2i) -> Breakable:
	for tuft: Breakable in _tufts(area):
		if tuft.cell() == cell:
			return tuft
	return null


func _on_sound(id: StringName) -> void:
	_heard.append(id)


func _on_finished(id: StringName, big: bool) -> void:
	_finished.append([id, big])
