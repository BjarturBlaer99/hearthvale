extends GdUnitTestSuite
## The buildings with rooms (the Homestead, phase 3, step 3b): the Coop, the Barn and the Shed
## stand the morning after their kits are set down, each with a door that leads into its own
## small room, whose doormat leads out before its door wherever it stands; the doorstep stays
## free; the Shed's two chests and second furnace are made at the workbench once it stands, and
## keep what they hold through a save, apart from the farmhouse's; the Big Coop and the Big Barn
## are bought like a plan and finished the next morning, in the same place.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const FARM: String = "res://world/areas/homestead/homestead.tscn"
const HOME: String = "res://world/areas/home/home.tscn"
const TEST_SLOT: int = 955
const START: Vector2i = Vector2i(30, 13)
## Where each is set down (its top-left corner) in the yard east of the farmhouse, and a second
## place for each on the open land west of it.
const EAST: Dictionary = {&"coop": Vector2i(32, 10), &"barn": Vector2i(32, 9), &"shed": Vector2i(32, 10)}
const WEST: Dictionary = {&"coop": Vector2i(14, 10), &"barn": Vector2i(12, 9), &"shed": Vector2i(15, 15)}
const ROOMS: Dictionary = {&"coop": "Your coop", &"barn": "Your barn", &"shed": "Your shed"}

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


func test_each_room_is_entered_by_its_door_and_left_before_it_wherever_it_stands() -> void:
	for id: StringName in [&"coop", &"barn", &"shed"]:
		GameState.clear()
		GameState.new_game()
		Quests.refresh()
		GameState.set_time(float(GameState.day_clock().in_day("12:00")))
		_build(id, EAST[id])
		_walk_in_and_out(id)
		# Moved to the other side of the farm, its door goes with it.
		for cell: Vector2i in Buildings.cells_and_doorstep(DataRegistry.get_building(id), WEST[id]):
			GameState.clear_debris(&"homestead", cell)
		assert_bool(GameState.homestead().move_building(id, WEST[id])).is_true()
		_walk_in_and_out(id)


func test_a_site_has_no_door_yet_and_the_doorstep_stays_free() -> void:
	GameState.add_item(&"coop_kit")
	GameState.set_down_kit(&"homestead", EAST[&"coop"], &"coop_kit")
	var coop: Dictionary = DataRegistry.get_building(&"coop")
	var doorstep: Vector2i = Buildings.doorstep_of(coop, EAST[&"coop"])
	assert_that(doorstep).is_equal(Vector2i(34, 13))
	var farm: AreaController = _farm()
	assert_object(farm.buildings.door(&"coop")).override_failure_message("a site has no door").is_null()
	assert_object(farm.entry_marker(PlacedBuildings.door_entry(&"coop"))).is_null()
	assert_bool(farm.terrain.is_occupied(Buildings.door_cell(coop, EAST[&"coop"]))).override_failure_message("a site fills its door's cell too").is_true()
	# Nothing is set down on the doorstep, of a site or of a building.
	GameState.add_item(&"fence", 3)
	GameState.add_item(&"silo_kit")
	assert_bool(farm.open_build()).is_true()
	_choose(farm, &"fence")
	farm.build.point_at(doorstep)
	assert_str(farm.build.why_not()).is_equal(Placement.DOORSTEP_WORDS)
	_choose(farm, &"silo_kit")
	farm.build.point_at(doorstep + Vector2i(1, 1))
	assert_str(farm.build.why_not()).override_failure_message("a silo over the doorstep").is_equal(Placement.DOORSTEP_WORDS)
	farm.build.close()
	GameState.start_next_day()
	farm = _farm()
	assert_object(farm.buildings.door(&"coop")).is_not_null()
	assert_bool(farm.terrain.is_occupied(Buildings.door_cell(coop, EAST[&"coop"]))).override_failure_message("standing, its door is walked into").is_false()
	farm.open_build()
	_choose(farm, &"fence")
	farm.build.point_at(doorstep)
	assert_str(farm.build.why_not()).is_equal(Placement.DOORSTEP_WORDS)
	farm.build.point_at(doorstep + Vector2i(1, 0))
	assert_str(farm.build.why_not()).override_failure_message("beside it is open ground").is_empty()


func test_the_sheds_chests_and_furnace_are_made_once_it_stands_and_keep_through_a_save() -> void:
	for stack: Array in [[&"stone", 40], [&"copper_ore", 5], [&"wood", 25], [&"copper_bar", 2]]:
		GameState.add_item(stack[0], stack[1])
	var make: Callable = func() -> Array: return Crafting.of_tab(GameState.known_crafts(Crafting.WORKBENCH), Crafting.TAB_BUILD).map(func(recipe: Dictionary) -> String: return str(recipe["id"]))
	assert_bool((make.call() as Array).has("shed_furnace")).override_failure_message("no shed yet").is_false()
	assert_str(GameState.craft(&"shed_chest")).is_equal(Crafting.UNKNOWN_WORDS)
	_build(&"shed", EAST[&"shed"])
	assert_array((make.call() as Array).slice(-3)).is_equal(["shed_furnace", "shed_chest", "shed_chest_2"])
	for recipe: StringName in [&"shed_furnace", &"shed_chest", &"shed_chest_2"]:
		assert_str(GameState.craft(recipe)).override_failure_message(recipe).is_empty()
	assert_str(GameState.craft(&"shed_chest")).is_equal(Crafting.HAVE_ONE_WORDS)
	for flag: StringName in [&"shed/furnace", &"shed/chest_a", &"shed/chest_b"]:
		assert_bool(GameState.get_flag(flag) == true).override_failure_message(flag).is_true()
	assert_bool(GameState.is_furnished(&"furnace")).override_failure_message("the farmhouse has no furnace of its own yet").is_false()
	assert_bool(GameState.is_furnished(&"chest")).is_false()
	# In the shed: each in its own place, in the way.
	GameState.go_to(&"shed", &"door")
	var shed: AreaController = _load("res://world/areas/shed/shed.tscn")
	for spot: Array in [["Furnace", Vector2i(5, 2)], ["ChestA", Vector2i(2, 2)], ["ChestB", Vector2i(8, 2)]]:
		var furnishing: Furnishing = shed.interactables.get_node(NodePath(spot[0]))
		assert_that(furnishing.cell()).is_equal(spot[1])
		assert_bool(furnishing.is_there()).override_failure_message(spot[0]).is_true()
		assert_bool(shed.terrain.is_occupied(spot[1])).override_failure_message(spot[0]).is_true()
	# The first chest takes the stone (twenty left from the plans, and thirty more); the second
	# the wood (five and twelve); the farmhouse's has nothing.
	GameState.add_item(&"stone", 30)
	GameState.add_item(&"wood", 12)
	Steps.stand_before(shed, "ChestA")
	assert_bool(shed.interact()).is_true()
	assert_that(shed.hud.store_menu.key).is_equal(&"shed_a")
	_put(shed, &"stone")
	shed.hud.store_menu.close()
	Steps.stand_before(shed, "ChestB")
	shed.interact()
	assert_that(shed.hud.store_menu.key).is_equal(&"shed_b")
	_put(shed, &"wood")
	shed.hud.store_menu.close()
	assert_int(GameState.store(&"shed_a").count_of("stone")).is_equal(50)
	assert_int(GameState.store(&"shed_b").count_of("wood")).is_equal(17)
	assert_int(GameState.store(&"shed_a").count_of("wood")).is_equal(0)
	assert_int(GameState.store().used_slots()).is_equal(0)
	# The shed's furnace: one load of its own, lit through its conversation.
	GameState.add_item(&"copper_ore", 9)
	GameState.add_item(&"coal", 3)
	Steps.stand_before(shed, "Furnace")
	assert_bool(shed.interact()).is_true()
	shed.hud.dialogue.confirm()
	assert_bool(GameState.furnace(&"shed").is_burning(GameState.day)).is_true()
	assert_dict(GameState.furnace(&"shed").to_dict()).is_equal({"item": "copper_bar", "count": 3, "day": GameState.day})
	assert_bool(GameState.furnace().is_empty()).override_failure_message("the farmhouse's is another").is_true()
	_close_talk(shed)
	# Through a save and back.
	GameState.update_player(&"shed", Vector2i(5, 6))
	assert_int(SaveSystem.save_game()).is_equal(OK)
	var on_disk: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SaveSystem.slot_path(TEST_SLOT)))
	assert_bool((on_disk["homestead"] as Dictionary).has("chests")).is_true()
	assert_bool((on_disk["homestead"] as Dictionary).has("furnaces")).is_true()
	assert_array(on_disk["home"]["chest"]).override_failure_message("the farmhouse's chest is as it was").is_empty()
	GameState.clear()
	assert_int(SaveSystem.load_game()).is_equal(OK)
	assert_int(GameState.store(&"shed_a").count_of("stone")).is_equal(50)
	assert_int(GameState.store(&"shed_b").count_of("wood")).is_equal(17)
	assert_bool(GameState.furnace(&"shed").is_burning(GameState.day)).is_true()
	# The next morning its bars are taken out through its conversation; what doesn't fit is laid
	# at his feet.
	GameState.start_next_day()
	shed = _load("res://world/areas/shed/shed.tscn")
	Steps.stand_before(shed, "Furnace")
	shed.interact()
	shed.hud.dialogue.confirm()
	assert_int(GameState.item_count(&"copper_bar")).is_equal(3)
	assert_bool(GameState.furnace(&"shed").is_empty()).is_true()


func test_the_big_coop_and_the_big_barn_are_bought_like_a_plan_and_finished_the_next_morning() -> void:
	for pair: Array in [[&"coop", &"big_coop", [[&"wood", 20], [&"fibre", 10], [&"iron_bar", 2], [&"coin", 350]], "Big Coop"],
			[&"barn", &"big_barn", [[&"wood", 30], [&"stone", 30], [&"gold_bar", 2], [&"coin", 800]], "Big Barn"]]:
		var id: StringName = pair[0]
		var upgrade: StringName = pair[1]
		assert_str(GameState.craft(upgrade)).override_failure_message("unknown without the %s" % id).is_equal(Crafting.UNKNOWN_WORDS)
		_build(id, EAST[id] if id == &"coop" else WEST[id])
		var at: Vector2i = GameState.homestead().building_at(id)
		for stack: Array in pair[2]:
			GameState.add_item(stack[0], stack[1])
		var home: AreaController = _load(HOME)
		home.open_craft()
		var menu: CraftMenu = home.hud.craft_menu
		menu.show_tab(Crafting.TAB_BUILD)
		var ids: Array = menu.entries().map(func(recipe: Dictionary) -> String: return str(recipe["id"]))
		menu.move_cursor(ids.find(String(upgrade)))
		assert_bool(menu.confirm()).is_true()
		assert_str(menu.note_text()).is_equal("Bought: %s. It is finished tomorrow." % pair[3])
		menu.close()
		for stack: Array in pair[2]:
			assert_int(GameState.item_count(stack[0])).override_failure_message("%s spent" % stack[0]).is_equal(0)
		assert_bool(GameState.homestead().is_upgrading(id, GameState.day)).is_true()
		assert_bool(GameState.is_big(id)).is_false()
		assert_str(GameState.craft(upgrade)).override_failure_message("one upgrade").is_equal(Crafting.HAVE_ONE_WORDS)
		GameState.start_next_day()
		assert_bool(GameState.is_big(id)).is_true()
		assert_that(GameState.homestead().building_at(id)).override_failure_message("the same place").is_equal(at)
		assert_array(Array(home.hud.notice_lines())).contains(["The %s is finished." % pair[3]])
		var building: Dictionary = DataRegistry.get_building(id)
		assert_int(Buildings.animals_of(building, GameState.is_big(id))).is_equal(8)
		assert_str(Buildings.name_of(building, true)).is_equal(pair[3])
		# Its look is its bigger self's, the same size, and its room is the one it had.
		var farm: AreaController = _farm()
		assert_array(farm.buildings.ridges_of(id)).has_size(Buildings.size_of(building).x)
		assert_object(farm.buildings.door(id)).is_not_null()
		assert_that(farm.buildings.door(id).target_area).is_equal(Buildings.room_of(building))
	# Their price is the plan's table.
	assert_array(Crafting.needs_of(DataRegistry.get_crafting(&"big_coop"))).is_equal([
		{"item": "wood", "count": 20}, {"item": "fibre", "count": 10}, {"item": "iron_bar", "count": 2}, {"item": "coin", "count": 350}])


func test_the_seven_plans_cost_what_the_plan_says_and_are_known_when_it_says() -> void:
	var table: Array = [
		[&"well", [["stone", 40], ["wood", 10], ["copper_bar", 1], ["coin", 80]], {"found": "copper_bar"}, Vector2i(2, 2)],
		[&"silo", [["stone", 30], ["wood", 10], ["copper_bar", 2], ["coin", 100]], {"skill": "farming", "level": 2.0}, Vector2i(2, 2)],
		[&"coop", [["wood", 30], ["stone", 20], ["fibre", 15], ["coin", 150]], {"found": "wood"}, Vector2i(4, 3)],
		[&"big_coop", [["wood", 20], ["fibre", 10], ["iron_bar", 2], ["coin", 350]], {"built": "coop"}, Vector2i.ZERO],
		[&"barn", [["wood", 30], ["stone", 40], ["fibre", 25], ["iron_bar", 4], ["coin", 600]], {"skill": "farming", "level": 3.0}, Vector2i(6, 4)],
		[&"big_barn", [["wood", 30], ["stone", 30], ["gold_bar", 2], ["coin", 800]], {"built": "barn"}, Vector2i.ZERO],
		[&"shed", [["wood", 30], ["stone", 20], ["fibre", 15], ["copper_bar", 2], ["coin", 200]], {"found": "copper_bar"}, Vector2i(4, 3)],
	]
	var totals: Dictionary = {}
	var order: Array = []
	for row: Array in table:
		var recipe: Dictionary = DataRegistry.get_crafting(row[0])
		assert_str(Crafting.tab_of(recipe)).is_equal(Crafting.TAB_BUILD)
		var needs: Array = Crafting.needs_of(recipe).map(func(need: Dictionary) -> Array: return [need["item"], need["count"]])
		assert_array(needs).override_failure_message(String(row[0])).is_equal(row[1])
		assert_dict(recipe["unlock"]).override_failure_message(String(row[0])).is_equal(row[2])
		order.append(int(recipe["order"]))
		for need: Array in row[1]:
			totals[need[0]] = int(totals.get(need[0], 0)) + int(need[1])
		if row[3] != Vector2i.ZERO:
			assert_that(Buildings.size_of(DataRegistry.get_building(row[0]))).is_equal(row[3])
	assert_array(order).override_failure_message("listed in the table's order").is_equal([1, 2, 3, 4, 5, 6, 7])
	# The plan's sum of all seven.
	assert_dict(totals).is_equal({"wood": 160, "stone": 180, "fibre": 65, "copper_bar": 5, "iron_bar": 6, "gold_bar": 2, "coin": 2280})
	assert_int(Buildings.animals_of(DataRegistry.get_building(&"coop"))).is_equal(4)
	# The doors: in the middle of the Coop's and the Shed's bottom row, the Barn's a cell right of it.
	for door: Array in [[&"coop", Vector2i(2, 2)], [&"shed", Vector2i(2, 2)], [&"barn", Vector2i(3, 3)]]:
		assert_that(Buildings.door_of(DataRegistry.get_building(door[0]))).override_failure_message(String(door[0])).is_equal(door[1])
	assert_bool(Buildings.has_door(DataRegistry.get_building(&"well")) or Buildings.has_door(DataRegistry.get_building(&"silo"))).is_false()
	assert_int(Buildings.animals_of(DataRegistry.get_building(&"barn"))).is_equal(4)


func test_the_rooms_are_small_and_empty() -> void:
	for id: StringName in ROOMS:
		GameState.go_to(id, &"door")
		var room: AreaController = _load(WorldPaths.scene_for(id))
		assert_str(room.area_name).is_equal(ROOMS[id])
		assert_that(room.grid.size).is_equal(Vector2i(11, 9))
		assert_that(room.player.motor.cell).is_equal(Vector2i(5, 7))
		assert_object(room.exit_at(Vector2i(5, 8))).is_not_null()
		assert_that(room.exit_at(Vector2i(5, 8)).target_entry).is_equal(PlacedBuildings.door_entry(id))
		assert_array(room.enemies()).is_empty()
		assert_object(room.build).override_failure_message("nothing is set down indoors").is_null()


# --- Helpers -------------------------------------------------------------------------------

## Clears the ground, sets `id`'s kit down with its corner at `at`, and lets a morning come.
func _build(id: StringName, at: Vector2i) -> void:
	var building: Dictionary = DataRegistry.get_building(id)
	for cell: Vector2i in Buildings.cells_and_doorstep(building, at):
		GameState.clear_debris(&"homestead", cell)
	var kit: StringName = Buildings.kit_for(id, DataRegistry.entries(&"items"))
	GameState.add_item(kit)
	assert_bool(GameState.set_down_kit(&"homestead", at, kit)).override_failure_message("%s at %s" % [id, at]).is_true()
	GameState.start_next_day()
	GameState.set_time(float(GameState.day_clock().in_day("12:00")))


## Walks up from `id`'s doorstep into its door and its room, and down its doormat out again,
## arriving on the doorstep facing south.
func _walk_in_and_out(id: StringName) -> void:
	var building: Dictionary = DataRegistry.get_building(id)
	var at: Vector2i = GameState.homestead().building_at(id)
	var doorstep: Vector2i = Buildings.doorstep_of(building, at)
	GameState.update_player(&"homestead", doorstep)
	var farm: AreaController = _load(FARM)
	var door: AreaExit = farm.buildings.door(id)
	assert_object(door).override_failure_message("%s has a door" % id).is_not_null()
	assert_that(door.cell()).is_equal(Buildings.door_cell(building, at))
	assert_object(farm.entry_marker(PlacedBuildings.door_entry(id))).is_not_null()
	farm.player.motor.place(doorstep)
	assert_str(Steps.walk_until_travel(farm, Vector2.UP)).override_failure_message("%s's door" % id).is_equal(WorldPaths.scene_for(Buildings.room_of(building)))
	var room: AreaController = _load(WorldPaths.scene_for(Buildings.room_of(building)))
	assert_that(room.player.motor.cell).override_failure_message("in by the doormat").is_equal(Vector2i(5, 7))
	assert_str(Steps.walk_until_travel(room, Vector2.DOWN)).is_equal(FARM)
	farm = _load(FARM)
	assert_that(farm.player.motor.cell).override_failure_message("%s: out before its door" % id).is_equal(doorstep)
	assert_that(Vector2(farm.player.facing_direction())).is_equal(Vector2.DOWN)


func _put(area: AreaController, item_id: StringName) -> void:
	var menu: StoreMenu = area.hud.store_menu
	var index: int = menu.entries(StoreMenu.PACK).map(func(stack: Dictionary) -> String: return str(stack["id"])).find(String(item_id))
	menu.side = StoreMenu.PACK
	menu.selected = index
	assert_bool(menu.confirm()).override_failure_message("%s put away" % item_id).is_true()


func _close_talk(area: AreaController) -> void:
	for i: int in 4:
		if area.is_talking():
			area.hud.dialogue.confirm()


func _farm() -> AreaController:
	GameState.update_player(&"homestead", START)
	var farm: AreaController = _load(FARM)
	farm.player.face(Vector2.RIGHT)
	return farm


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area


func _choose(farm: AreaController, id: StringName) -> void:
	for step: int in farm.build.entries().size():
		if farm.build.chosen == id:
			return
		farm.build.step(1)


func _on_sound(id: StringName) -> void:
	_heard.append(id)
