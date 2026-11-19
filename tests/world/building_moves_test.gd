extends GdUnitTestSuite
## Moving and pulling down buildings (the Homestead, phase 3, step 3c; the plan's D24): the
## hand in build mode lifts a building from any of its cells and sets it down elsewhere, at once
## and for nothing, with what is in it and its door; it is refused where it doesn't fit. A right
## click on a site takes it up and gives back its kit. On a building it asks first, and only an
## empty one goes (no hay in the silo, nothing in the shed's chests or furnace): half of each
## material that went into it comes back, rounded down, no coins, and what the pack can't take
## is laid at his feet.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const FARM: String = "res://world/areas/homestead/homestead.tscn"
const HOME: String = "res://world/areas/home/home.tscn"
const TEST_SLOT: int = 961
const START: Vector2i = Vector2i(30, 13)
const SHED_AT: Vector2i = Vector2i(32, 10)
const SILO_AT: Vector2i = Vector2i(36, 11)
## A second place on the open land west of the farmhouse (its ground cleared for the test).
const WEST: Vector2i = Vector2i(15, 15)

var _area: Node
var _heard: Array[StringName] = []


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	Quests.refresh()
	GameState.set_time(float(GameState.day_clock().in_day("12:00")))
	SaveSystem.erase_slot(TEST_SLOT)
	SaveSystem.current_slot = TEST_SLOT
	_heard.clear()
	EventBus.sound.connect(_on_sound)


func after_test() -> void:
	EventBus.sound.disconnect(_on_sound)
	if is_instance_valid(_area):
		_area.free()
	_area = null
	SaveSystem.erase_slot(TEST_SLOT)
	SaveSystem.current_slot = SaveSystem.GAME_SLOT
	GameState.clear()


func test_the_hand_moves_a_building_at_once_with_what_is_in_it() -> void:
	_build(&"shed", SHED_AT)
	_build(&"silo", SILO_AT)
	GameState.homestead().add_hay(20, 60)
	GameState.set_flag(&"shed/chest_a", true)
	GameState.set_flag(&"shed/furnace", true)
	GameState.store(&"shed_a").put("stone", 25, 50)
	GameState.light_furnace(&"copper_bar", 2, &"shed")
	GameState.add_item(&"coin", 50)
	var shed: Dictionary = DataRegistry.get_building(&"shed")
	for cell: Vector2i in Buildings.cells_and_doorstep(shed, WEST):
		GameState.clear_debris(&"homestead", cell)
	var farm: AreaController = _farm()
	await await_idle_frame()
	farm.open_build()
	assert_bool(farm.build.is_hand()).is_true()
	# The hand over any of its cells lifts the whole of it: the ghost holds it where it stands.
	farm.build.point_at(SHED_AT + Vector2i(0, 1))
	assert_str(farm.build.words()).is_equal("Lift the Shed")
	assert_that(farm.build.ghost_colour()).is_equal(BuildMode.FITS)
	assert_bool(farm.build.set_down()).is_true()
	assert_that(farm.build.lifted["building"]).is_equal(&"shed")
	assert_that(farm.build.cell).is_equal(SHED_AT + Buildings.anchor_of(shed))
	assert_str(farm.build.words()).is_equal("Put the Shed back")
	# Refused where it doesn't fit: on the road, over the farmhouse, on the silo's cells.
	for case: Array in [[Vector2i(34, 15), Placement.ROAD_WORDS], [Vector2i(30, 11), Placement.NO_GROUND_WORDS], [Vector2i(37, 12), Placement.NO_GROUND_WORDS]]:
		farm.build.point_at(case[0])
		assert_str(farm.build.why_not()).override_failure_message("%s" % case[0]).is_equal(case[1])
		assert_bool(farm.build.set_down()).is_false()
		assert_that(GameState.homestead().building_at(&"shed")).is_equal(SHED_AT)
	# Where it fits it is moved at once, and for nothing.
	farm.build.point_at(WEST + Buildings.anchor_of(shed))
	assert_str(farm.build.words()).is_equal("Set the Shed down here")
	assert_bool(farm.build.set_down()).is_true()
	assert_dict(farm.build.lifted).is_empty()
	assert_that(GameState.homestead().building_at(&"shed")).is_equal(WEST)
	assert_int(GameState.item_count(&"coin")).override_failure_message("moving is free").is_equal(50)
	assert_bool(GameState.is_built(&"shed")).override_failure_message("still standing").is_true()
	for cell: Vector2i in Buildings.filled_cells(shed, SHED_AT, true):
		assert_bool(farm.terrain.is_occupied(cell)).override_failure_message("%s is free again" % cell).is_false()
	for cell: Vector2i in Buildings.filled_cells(shed, WEST, true):
		assert_bool(farm.terrain.is_occupied(cell)).override_failure_message("%s is filled" % cell).is_true()
	# Its door and its doorstep went with it, and what is in it.
	assert_that(farm.buildings.door(&"shed").cell()).is_equal(Buildings.door_cell(shed, WEST))
	assert_that(PlayerMotor.cell_of(farm.entry_marker(PlacedBuildings.door_entry(&"shed")).position)).is_equal(Buildings.doorstep_of(shed, WEST))
	assert_int(GameState.store(&"shed_a").count_of("stone")).is_equal(25)
	assert_bool(GameState.furnace(&"shed").is_burning(GameState.day)).is_true()
	# Moved a cell, over its own cells: its own ground is no hindrance. The silo keeps its hay.
	var silo: Dictionary = DataRegistry.get_building(&"silo")
	farm.build.point_at(SILO_AT + Buildings.anchor_of(silo))
	farm.build.set_down()
	farm.build.point_at(SILO_AT + Buildings.anchor_of(silo) + Vector2i.LEFT)
	assert_str(farm.build.why_not()).is_empty()
	assert_bool(farm.build.set_down()).is_true()
	assert_that(GameState.homestead().building_at(&"silo")).is_equal(SILO_AT + Vector2i.LEFT)
	assert_int(GameState.homestead().hay).is_equal(20)
	# Through a save, it is where it was moved to.
	farm.build.close()
	GameState.update_player(&"homestead", START)
	SaveSystem.save_game()
	GameState.clear()
	SaveSystem.load_game()
	assert_that(GameState.homestead().building_at(&"shed")).is_equal(WEST)
	assert_that(GameState.homestead().building_at(&"silo")).is_equal(SILO_AT + Vector2i.LEFT)
	# Off his land nothing is moved.
	assert_bool(GameState.move_building(&"village", &"silo", Vector2i(3, 3))).is_false()


func test_a_site_is_moved_as_a_site_and_taken_up_gives_its_kit_back() -> void:
	GameState.add_item(&"coop_kit")
	GameState.set_down_kit(&"homestead", SHED_AT, &"coop_kit")
	var coop: Dictionary = DataRegistry.get_building(&"coop")
	var farm: AreaController = _farm()
	await await_idle_frame()
	farm.open_build()
	farm.build.point_at(SHED_AT)
	farm.build.set_down()
	farm.build.point_at(SHED_AT + Buildings.anchor_of(coop) + Vector2i.RIGHT)
	assert_bool(farm.build.set_down()).is_true()
	assert_that(GameState.homestead().building_at(&"coop")).is_equal(SHED_AT + Vector2i.RIGHT)
	assert_bool(GameState.homestead().is_site(&"coop", GameState.day)).override_failure_message("still a site").is_true()
	# A right click takes it up: nothing was built, and the kit comes back whole.
	_heard.clear()
	assert_bool(farm.build.take_up()).is_true()
	assert_array(_heard).contains([&"take_up"])
	assert_bool(GameState.homestead().has_building(&"coop")).is_false()
	assert_int(GameState.item_count(&"coop_kit")).is_equal(1)
	assert_str(farm.hud.message_text()).is_equal("Taken up: Coop Kit.")
	for cell: Vector2i in Buildings.cells_of(coop, SHED_AT + Vector2i.RIGHT):
		assert_bool(farm.terrain.is_occupied(cell)).override_failure_message("%s" % cell).is_false()
	assert_object(farm.buildings.spot(&"coop")).is_null()


func test_pulling_a_building_down_asks_first_and_gives_back_half_its_materials() -> void:
	_build(&"coop", SHED_AT)
	GameState.add_item(&"coin", 7)
	var coop: Dictionary = DataRegistry.get_building(&"coop")
	var farm: AreaController = _farm()
	await await_idle_frame()
	farm.open_build()
	farm.build.point_at(SHED_AT + Vector2i(1, 1))
	_heard.clear()
	assert_bool(farm.build.take_up()).override_failure_message("the first click only asks").is_false()
	assert_that(farm.build.asked).is_equal(&"coop")
	assert_str(farm.build.words()).is_equal("Pull down the Coop? Right click again. Back: 15 Wood, 10 Stone and 7 Fibre.")
	assert_that(farm.build.ghost_colour()).is_equal(BuildMode.REFUSED)
	assert_bool(GameState.homestead().has_building(&"coop")).is_true()
	# Moving the ghost off it lets the question go; back on it, a click asks again.
	farm.build.point_at(Vector2i(30, 12))
	assert_that(farm.build.asked).is_equal(&"")
	farm.build.point_at(SHED_AT)
	assert_bool(farm.build.take_up()).is_false()
	assert_bool(farm.build.take_up()).override_failure_message("the second click pulls it down").is_true()
	assert_bool(GameState.homestead().has_building(&"coop")).is_false()
	assert_int(GameState.item_count(&"wood")).is_equal(15)
	assert_int(GameState.item_count(&"stone")).is_equal(10)
	assert_int(GameState.item_count(&"fibre")).is_equal(7)
	assert_int(GameState.item_count(&"coin")).override_failure_message("no coins come back").is_equal(7)
	assert_str(farm.hud.message_text()).is_equal("The Coop is pulled down. Back: 15 Wood, 10 Stone and 7 Fibre.")
	for cell: Vector2i in Buildings.cells_of(coop, SHED_AT):
		assert_bool(farm.terrain.is_occupied(cell)).override_failure_message("%s" % cell).is_false()
	assert_object(farm.buildings.door(&"coop")).is_null()
	assert_object(farm.entry_marker(PlacedBuildings.door_entry(&"coop"))).is_null()
	# Gone, its plan can be bought again: one of each is one standing.
	for stack: Array in [[&"wood", 15], [&"stone", 10], [&"fibre", 8], [&"coin", 243]]:
		GameState.add_item(stack[0], stack[1])
	assert_str(GameState.craft(&"coop")).is_empty()


func test_only_an_empty_building_can_go() -> void:
	_build(&"silo", SILO_AT)
	_build(&"shed", SHED_AT)
	GameState.homestead().add_hay(5, 60)
	GameState.set_flag(&"shed/chest_b", true)
	GameState.set_flag(&"shed/furnace", true)
	GameState.store(&"shed_b").put("wood", 3, 30)
	assert_str(GameState.why_not_demolish(&"silo")).is_equal("The Silo still holds hay. Only an empty building can be pulled down.")
	assert_str(GameState.why_not_demolish(&"shed")).is_equal("There are things in the Shed's chests. Only an empty building can be pulled down.")
	assert_array(GameState.demolish(&"homestead", &"silo")).is_empty()
	assert_bool(GameState.homestead().has_building(&"silo")).is_true()
	var farm: AreaController = _farm()
	await await_idle_frame()
	farm.open_build()
	farm.build.point_at(SILO_AT)
	_heard.clear()
	assert_bool(farm.build.take_up()).is_false()
	assert_array(_heard).contains([&"nope"])
	assert_that(farm.build.asked).override_failure_message("refused, it doesn't ask").is_equal(&"")
	assert_str(farm.hud.message_text()).is_equal(GameState.why_not_demolish(&"silo"))
	assert_bool(farm.build.take_up()).is_false()
	assert_bool(GameState.homestead().has_building(&"silo")).is_true()
	# Emptied, the shed's furnace still holds a load; then nothing is in the way.
	GameState.store_take(0, &"shed_b")
	GameState.light_furnace(&"iron_bar", 1, &"shed")
	assert_str(GameState.why_not_demolish(&"shed")).is_equal("The Shed's furnace holds a load. Only an empty building can be pulled down.")
	GameState.start_next_day()
	GameState.empty_furnace(&"shed")
	assert_str(GameState.why_not_demolish(&"shed")).is_empty()
	# Pulled down, its room's furnishings wait for a shed built again.
	assert_array(GameState.demolish(&"homestead", &"shed")).is_equal([
		{"item": "wood", "count": 15}, {"item": "stone", "count": 10}, {"item": "fibre", "count": 7}, {"item": "copper_bar", "count": 1}])
	assert_bool(GameState.is_furnished(&"shed/chest_b")).is_true()
	# A site is not pulled down: it is taken up.
	assert_str(GameState.why_not_demolish(&"barn")).is_equal(GameState.NOT_STANDING_WORDS)


func test_an_upgrade_comes_back_by_half_too_and_what_doesnt_fit_is_laid_at_his_feet() -> void:
	_build(&"coop", SHED_AT)
	GameState.homestead().upgrade(&"coop", GameState.day)
	GameState.start_next_day()
	GameState.set_time(float(GameState.day_clock().in_day("12:00")))
	assert_array(GameState.demolish_refund(&"coop")).is_equal([
		{"item": "wood", "count": 25}, {"item": "stone", "count": 10}, {"item": "fibre", "count": 12}, {"item": "iron_bar", "count": 1}])
	# A full stack of wood: what the pack can't take lies at his feet.
	GameState.add_item(&"wood", 30)
	var farm: AreaController = _farm()
	await await_idle_frame()
	farm.open_build()
	farm.build.point_at(SHED_AT)
	farm.build.take_up()
	assert_bool(farm.build.take_up()).is_true()
	assert_int(GameState.item_count(&"wood")).is_equal(30)
	var left: Array = farm.interactables.get_children().filter(func(child: Node) -> bool: return child is LeftItem)
	assert_int(left.size()).is_equal(1)
	assert_that((left[0] as LeftItem).item_id).is_equal(&"wood")
	assert_int((left[0] as LeftItem).count).is_equal(25)
	assert_that(PlayerMotor.cell_of((left[0] as Node2D).position + Vector2(0.5, 0.5))).override_failure_message("at his feet").is_equal(START)
	assert_int(GameState.item_count(&"iron_bar")).is_equal(1)


# --- Helpers -------------------------------------------------------------------------------

## Clears the ground, sets `id`'s kit down with its corner at `at`, and lets a morning come.
func _build(id: StringName, at: Vector2i) -> void:
	for cell: Vector2i in Buildings.cells_and_doorstep(DataRegistry.get_building(id), at):
		GameState.clear_debris(&"homestead", cell)
	var kit: StringName = Buildings.kit_for(id, DataRegistry.entries(&"items"))
	GameState.add_item(kit)
	assert_bool(GameState.set_down_kit(&"homestead", at, kit)).override_failure_message("%s at %s" % [id, at]).is_true()
	GameState.start_next_day()
	GameState.set_time(float(GameState.day_clock().in_day("12:00")))


func _farm() -> AreaController:
	GameState.update_player(&"homestead", START)
	var farm: AreaController = _load(FARM)
	farm.player.face(Vector2.RIGHT)
	return farm


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area


func _on_sound(id: StringName) -> void:
	_heard.append(id)
