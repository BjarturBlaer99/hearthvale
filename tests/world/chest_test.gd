extends GdUnitTestSuite
## The storage chest, the woven rug and the standing lamp (crafting, phase 2b): each is made at
## the workbench and has its own place in the cottage. The chest opens two lists, the pack and
## its 24 stacks, and a line chosen moves that stack across. The rug is walked over; the lamp
## gives light. The chest's stacks go through a save.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const HOME: String = "res://world/areas/home/home.tscn"
const TEST_SLOT: int = 959
const CHEST_CELL: Vector2i = Vector2i(2, 2)
const LAMP_CELL: Vector2i = Vector2i(4, 2)
const RUG_CELLS: Array[Vector2i] = [Vector2i(2, 4), Vector2i(3, 4)]

var _area: Node
var _heard: Array[StringName] = []


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	Quests.refresh()
	_heard.clear()
	EventBus.sound.connect(_on_sound)


func after_test() -> void:
	EventBus.sound.disconnect(_on_sound)
	if is_instance_valid(_area):
		_area.free()
	_area = null
	GameState.clear()
	SaveSystem.current_slot = SaveSystem.GAME_SLOT
	SaveSystem.erase_slot(TEST_SLOT)


func test_the_three_are_made_at_the_workbench_from_what_the_plan_says() -> void:
	var cases: Array = [
		[&"chest", "Storage Chest", [["wood", 10], ["copper_bar", 1]], {"found": "wood"}],
		[&"rug", "Woven Rug", [["wheat", 8], ["cherry_blossom", 3]], null],
		[&"lamp", "Standing Lamp", [["copper_bar", 1], ["wood", 2], ["coal", 1]], {"found": "copper_bar"}],
	]
	for case: Array in cases:
		var recipe: Dictionary = DataRegistry.get_crafting(case[0])
		assert_str(str(recipe["name"])).is_equal(case[1])
		assert_str(Crafting.station_of(recipe)).is_equal(Crafting.WORKBENCH)
		assert_str(Crafting.furnishing_made(recipe)).is_equal(String(case[0]))
		var needs: Array = []
		for need: Dictionary in Crafting.needs_of(recipe):
			needs.append([need["item"], need["count"]])
		assert_array(needs).override_failure_message(String(case[0])).is_equal(case[2])
		assert_that(recipe.get("unlock")).override_failure_message("%s: when it is known" % case[0]).is_equal(case[3])
	# The rug is known from the first day; the chest once wood is found; the lamp once a bar is.
	assert_array(_ids(Crafting.of_tab(GameState.known_crafts(Crafting.WORKBENCH), Crafting.TAB_MAKE))).is_equal(["rug"])
	GameState.add_item(&"wood", 1)
	assert_array(_ids(Crafting.of_tab(GameState.known_crafts(Crafting.WORKBENCH), Crafting.TAB_MAKE))).is_equal(["chest", "rug"])
	GameState.add_item(&"copper_bar", 1)
	assert_array(_ids(Crafting.of_tab(GameState.known_crafts(Crafting.WORKBENCH), Crafting.TAB_MAKE))).override_failure_message("a copper bar opens the lamp, and the copper hoe, can and axe with it").is_equal(["chest", "copper_hoe", "copper_watering_can", "rug", "lamp", "copper_axe"])
	assert_array(Array(DataRegistry.errors)).is_empty()


func test_each_has_its_place_in_the_cottage_and_nothing_that_was_there_moved() -> void:
	var home: AreaController = _load(HOME)
	var places: Dictionary = {"Chest": CHEST_CELL, "Lamp": LAMP_CELL, "Rug": RUG_CELLS[0], "Furnace": Vector2i(6, 2), "Workbench": Vector2i(9, 3)}
	for node_name: String in places:
		var furnishing: Furnishing = home.interactables.get_node(NodePath(node_name))
		assert_that(furnishing.cell()).override_failure_message(node_name).is_equal(places[node_name])
		assert_bool(home.grid.is_solid(furnishing.cell())).override_failure_message("%s stands on the room's open floor" % node_name).is_false()
		if node_name != "Workbench":
			assert_bool(furnishing.is_there()).override_failure_message("%s is not there until it is made" % node_name).is_false()
			assert_bool(home.terrain.is_occupied(furnishing.cell())).is_false()
	# Where he wakes, the hearth's front and the way to the door are clear of every place.
	for cell: Vector2i in [Vector2i(2, 3), Vector2i(5, 2), Vector2i(5, 7), Vector2i(5, 6)]:
		assert_bool(places.values().has(cell) or RUG_CELLS.has(cell)).override_failure_message("%s is kept clear" % cell).is_false()
	# Unmade, the lamp gives no light.
	var lights_before: int = home.glows_now().size()
	assert_bool((home.interactables.get_node(^"Lamp") as Furnishing).glow_now().is_empty()).override_failure_message("no lamp, no light").is_true()
	# Made, each is there at once.
	GameState.add_item(&"wood", 12)
	GameState.add_item(&"copper_bar", 2)
	GameState.add_item(&"coal", 1)
	GameState.add_item(&"wheat", 8)
	GameState.add_item(&"cherry_blossom", 3)
	for recipe: StringName in [&"chest", &"rug", &"lamp"]:
		assert_str(GameState.craft(recipe)).override_failure_message(String(recipe)).is_equal("")
	assert_int(GameState.item_count(&"wood")).is_equal(0)
	assert_int(GameState.item_count(&"copper_bar")).is_equal(0)
	assert_int(GameState.item_count(&"wheat")).is_equal(0)
	var chest: Furnishing = home.interactables.get_node(^"Chest")
	var lamp: Furnishing = home.interactables.get_node(^"Lamp")
	var rug: Furnishing = home.interactables.get_node(^"Rug")
	assert_bool(chest.is_there() and lamp.is_there() and rug.is_there()).is_true()
	assert_bool(home.terrain.is_occupied(CHEST_CELL)).is_true()
	assert_bool(home.terrain.is_occupied(LAMP_CELL)).is_true()
	# The rug lies flat: two cells wide, walked over, never faced.
	assert_that(rug.frames()).is_equal([&"rug_l", &"rug_r"] as Array[StringName])
	for cell: Vector2i in RUG_CELLS:
		assert_bool(home.terrain.is_occupied(cell)).override_failure_message("the rug at %s is walked over" % cell).is_false()
		assert_bool(rug.covers(cell)).is_false()
	# The lamp is in the way, gives light, and has nothing to say.
	assert_bool(lamp.covers(LAMP_CELL)).override_failure_message("nothing to face").is_false()
	assert_bool(lamp.glow_now().is_empty()).is_false()
	assert_array(home.glows_now()).contains([lamp.glow_now()])
	assert_int(home.glows_now().size()).override_failure_message("one light more than before: the lamp's").is_equal(lights_before + 1)
	assert_str(chest.prompt()).is_equal("Open the chest")
	# A second of any can't be made.
	GameState.add_item(&"wheat", 8)
	GameState.add_item(&"cherry_blossom", 3)
	assert_str(GameState.craft(&"rug")).is_equal(Crafting.HAVE_ONE_WORDS)


func test_the_chest_opens_two_lists_and_a_line_chosen_moves_that_stack_across() -> void:
	GameState.set_flag(Crafting.furnished_flag(&"chest"), true)
	GameState.add_item(&"wooden_sword")
	GameState.add_item(&"coin", 40)
	GameState.add_item(&"copper_ore", 30)
	GameState.add_item(&"turnip", 6)
	GameState.add_item(&"watering_can")
	GameState.add_item(&"water", 5)
	var home: AreaController = _load(HOME)
	Steps.stand_before(home, "Chest")
	assert_bool(home.interact()).is_true()
	var menu: StoreMenu = home.hud.store_menu
	assert_bool(menu.is_open()).is_true()
	assert_bool(home.is_in_menu()).is_true()
	assert_bool(home.player.controls_enabled).is_false()
	assert_bool(home.clock_runs()).is_false()
	# The pack's list has what a chest keeps: not the sword, the coins, the can or its water.
	assert_that(menu.side).is_equal(StoreMenu.PACK)
	assert_array(Array(menu.shown_lines(StoreMenu.PACK))).is_equal(["> Copper Ore x30", "  Turnip x6"])
	assert_array(Array(menu.shown_lines(StoreMenu.CHEST))).is_equal([StoreMenu.EMPTY_CHEST])
	assert_str(menu.chest_title()).is_equal("Chest  0 of 24")
	# Choosing the ore puts the whole stack away.
	assert_bool(menu.confirm()).is_true()
	assert_int(GameState.item_count(&"copper_ore")).is_equal(0)
	assert_array(GameState.store().to_list()).is_equal([{"id": "copper_ore", "count": 30}])
	assert_str(menu.note_text()).is_equal("Put away: Copper Ore x30.")
	assert_str(menu.chest_title()).is_equal("Chest  1 of 24")
	assert_array(Array(menu.shown_lines(StoreMenu.PACK))).is_equal(["> Turnip x6"])
	assert_array(Array(menu.shown_lines(StoreMenu.CHEST))).is_equal(["  Copper Ore x30"])
	assert_array(_heard).contains([&"menu_select"])
	# Turning to the chest and choosing it takes it out again.
	menu.switch_side()
	assert_that(menu.side).is_equal(StoreMenu.CHEST)
	assert_array(Array(menu.shown_lines(StoreMenu.CHEST))).is_equal(["> Copper Ore x30"])
	assert_bool(menu.confirm()).is_true()
	assert_int(GameState.item_count(&"copper_ore")).is_equal(30)
	assert_bool(GameState.store().to_list().is_empty()).is_true()
	assert_str(menu.note_text()).is_equal("Took out: Copper Ore x30.")
	assert_str(GameState.store_put(&"water")).override_failure_message("the water is in the can, not in the pack").is_equal(Store.NOT_KEPT_WORDS)
	assert_int(GameState.item_count(&"water")).is_equal(5)
	assert_bool(GameState.store().to_list().is_empty()).is_true()
	assert_that(menu.side).override_failure_message("the chest is empty: the cursor goes back to the pack").is_equal(StoreMenu.PACK)
	menu.close()
	assert_bool(home.player.controls_enabled).is_true()


func test_taking_out_gives_only_what_he_has_room_for() -> void:
	GameState.set_flag(Crafting.furnished_flag(&"chest"), true)
	GameState.store().put("copper_ore", 30, 30)
	GameState.store().put("copper_ore", 12, 30)
	GameState.add_item(&"copper_ore", 25)
	var home: AreaController = _load(HOME)
	assert_bool(home.open_store()).is_true()
	var menu: StoreMenu = home.hud.store_menu
	menu.switch_side()
	assert_array(Array(menu.shown_lines())).is_equal(["> Copper Ore x30", "  Copper Ore x12"])
	# Room for five more: five come out, and twenty-five stay in that stack.
	assert_bool(menu.confirm()).is_true()
	assert_int(GameState.item_count(&"copper_ore")).is_equal(30)
	assert_array(GameState.store().to_list()).is_equal([{"id": "copper_ore", "count": 25}, {"id": "copper_ore", "count": 12}])
	assert_str(menu.note_text()).is_equal("Took out: Copper Ore x5.")
	# A full stack in the pack: nothing comes out, and he is told why.
	_heard.clear()
	assert_bool(menu.confirm()).is_false()
	assert_str(menu.note_text()).is_equal(Store.NO_ROOM_WORDS)
	assert_array(_heard).contains([&"nope"])
	assert_int(GameState.store().count_of("copper_ore")).is_equal(37)
	# Putting away tops up the chest's own stacks before beginning another.
	menu.switch_side()
	assert_bool(menu.confirm()).is_true()
	assert_array(GameState.store().to_list()).is_equal([{"id": "copper_ore", "count": 30}, {"id": "copper_ore", "count": 30}, {"id": "copper_ore", "count": 7}])
	assert_int(GameState.item_count(&"copper_ore")).is_equal(0)


func test_a_full_chest_takes_what_fits_and_says_when_nothing_does() -> void:
	GameState.set_flag(Crafting.furnished_flag(&"chest"), true)
	for slot: int in 23:
		GameState.store().put("stone", 50, 50)
	GameState.store().put("coal", 22, 30)
	assert_int(GameState.store().free_slots()).is_equal(0)
	GameState.add_item(&"coal", 20)
	GameState.add_item(&"wood", 4)
	assert_str(GameState.store_put(&"coal")).override_failure_message("eight go in").is_equal("")
	assert_int(GameState.item_count(&"coal")).is_equal(12)
	assert_int(GameState.store().count_of("coal")).is_equal(30)
	assert_str(GameState.store_put(&"coal")).is_equal(Store.FULL_WORDS)
	assert_str(GameState.store_put(&"wood")).override_failure_message("no slot for a new kind").is_equal(Store.FULL_WORDS)
	assert_int(GameState.item_count(&"wood")).is_equal(4)
	# What a chest doesn't keep, and what he hasn't got.
	GameState.add_item(&"coin", 9)
	GameState.add_item(&"wooden_sword")
	assert_str(GameState.store_put(&"coin")).is_equal(Store.NOT_KEPT_WORDS)
	assert_str(GameState.store_put(&"wooden_sword")).is_equal(Store.NOT_KEPT_WORDS)
	assert_str(GameState.store_put(&"turnip")).is_equal(Store.NOTHING_WORDS)
	assert_str(GameState.store_take(99)).is_equal(Store.NOTHING_WORDS)
	assert_int(GameState.item_count(&"coin")).is_equal(9)


func test_what_is_in_his_hand_leaves_it_when_the_last_is_put_away() -> void:
	GameState.set_flag(Crafting.furnished_flag(&"chest"), true)
	GameState.add_item(&"bomb", 4)
	GameState.equip(&"bomb")
	assert_str(GameState.store_put(&"bomb")).is_equal("")
	assert_int(GameState.item_count(&"bomb")).is_equal(0)
	assert_that(GameState.equipped).override_failure_message("the item button never holds what he no longer has").is_equal(&"")
	assert_str(GameState.store_take(0)).is_equal("")
	assert_int(GameState.item_count(&"bomb")).is_equal(4)


func test_the_mouse_points_at_either_list_and_the_wheel_steps() -> void:
	GameState.set_flag(Crafting.furnished_flag(&"chest"), true)
	GameState.add_item(&"stone", 9)
	GameState.add_item(&"coal", 3)
	GameState.add_item(&"wood", 2)
	GameState.store().put("turnip", 6, 30)
	GameState.store().put("iron_ore", 4, 30)
	var home: AreaController = _load(HOME)
	home.open_store()
	var menu: StoreMenu = home.hud.store_menu
	var pack: Label = menu.get_node(^"Panel/PackList")
	var chest: Label = menu.get_node(^"Panel/ChestList")
	await await_idle_frame()
	menu._unhandled_input(_move(pack, 2))
	assert_that(menu.side).is_equal(StoreMenu.PACK)
	assert_int(menu.selected).is_equal(2)
	# Pointing at the other list turns to it.
	menu._unhandled_input(_move(chest, 1))
	assert_that(menu.side).is_equal(StoreMenu.CHEST)
	assert_int(menu.selected).is_equal(1)
	assert_array(Array(menu.shown_lines(StoreMenu.CHEST))).is_equal(["  Turnip x6", "> Iron Ore x4"])
	assert_array(Array(menu.shown_lines(StoreMenu.PACK))).override_failure_message("one cursor, on the list he is on").is_equal(["  Stone x9", "  Coal x3", "  Wood x2"])
	menu._unhandled_input(_wheel(MOUSE_BUTTON_WHEEL_UP))
	assert_int(menu.selected).is_equal(0)
	# A click on a line moves that stack.
	menu._unhandled_input(_click_at(_point(pack, 1)))
	assert_int(GameState.item_count(&"coal")).is_equal(0)
	assert_int(GameState.store().count_of("coal")).is_equal(3)
	menu._unhandled_input(_click_at(_point(chest, 0)))
	assert_int(GameState.item_count(&"turnip")).is_equal(6)
	# Tab leaves.
	var back: InputEventAction = InputEventAction.new()
	back.action = &"item_menu"
	back.pressed = true
	menu._unhandled_input(back)
	assert_bool(menu.is_open()).is_false()


func test_a_long_list_scrolls_and_the_chest_goes_through_a_save() -> void:
	GameState.set_flag(Crafting.furnished_flag(&"chest"), true)
	var kinds: Array[String] = ["stone", "coal", "copper_ore", "iron_ore", "gold_ore", "wood", "turnip", "carrot", "wheat", "potato"]
	for kind: String in kinds:
		GameState.store().put(kind, 3, 30)
	GameState.store().put("copper_ore", 40, 30)
	var home: AreaController = _load(HOME)
	home.open_store()
	var menu: StoreMenu = home.hud.store_menu
	assert_that(menu.side).override_failure_message("nothing to put away: it opens on the chest").is_equal(StoreMenu.CHEST)
	assert_int(menu.shown_lines().size()).is_equal(StoreMenu.ROWS)
	assert_str(menu.chest_title()).is_equal("Chest  11 of 24")
	for step: int in 10:
		menu.move_cursor(1)
	assert_int(menu.selected).is_equal(10)
	assert_int(menu.shown_lines().size()).is_equal(StoreMenu.ROWS)
	assert_str(menu.shown_lines()[StoreMenu.ROWS - 1]).override_failure_message("the cursor's line is in view").is_equal("> Copper Ore x13")
	# Pointing at the first line shown puts the cursor on the fifth stack, not the first.
	await await_idle_frame()
	menu._unhandled_input(_move(menu.get_node(^"Panel/ChestList"), 0))
	assert_int(menu.selected).is_equal(4)
	assert_str(menu.shown_lines()[0]).is_equal("> Gold Ore x3")
	# Turning to the pack and back begins at the top of the list turned to.
	for carried: Array in [[&"bread", 2], [&"stone", 5], [&"coal", 2]]:
		GameState.add_item(carried[0], carried[1])
	menu.switch_side()
	assert_that(menu.side).is_equal(StoreMenu.PACK)
	assert_int(menu.selected).is_equal(0)
	menu.move_cursor(2)
	menu.switch_side()
	assert_that(menu.side).is_equal(StoreMenu.CHEST)
	assert_int(menu.selected).override_failure_message("not where the cursor was left").is_equal(0)
	assert_str(menu.shown_lines()[0]).is_equal("> Stone x3")
	menu.close()
	GameState.update_player(&"home", Vector2i(5, 5))
	assert_int(SaveSystem.save_to_slot(TEST_SLOT)).is_equal(OK)
	var on_disk: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SaveSystem.slot_path(TEST_SLOT)))
	assert_int((on_disk["home"]["chest"] as Array).size()).is_equal(11)
	assert_dict(on_disk["home"]["chest"][2]).is_equal({"id": "copper_ore", "count": 30.0})
	var before: String = JSON.stringify(GameState.to_dict(), "", true)
	GameState.clear()
	assert_int(GameState.store().used_slots()).override_failure_message("cleared").is_equal(0)
	assert_int(SaveSystem.load_from_slot(TEST_SLOT)).is_equal(OK)
	assert_str(JSON.stringify(GameState.to_dict(), "", true)).is_equal(before)
	assert_int(GameState.store().count_of("copper_ore")).is_equal(43)
	assert_bool(GameState.is_furnished(&"chest")).is_true()
	# A stack a save makes bigger than its item's limit is cut down to it as the game loads.
	var odd: Dictionary = GameState.to_dict()
	odd["home"]["chest"] = [{"id": "copper_ore", "count": 99}, {"id": "coal", "count": 4}]
	GameState.from_dict(odd)
	assert_array(GameState.store().to_list()).is_equal([{"id": "copper_ore", "count": 30}, {"id": "coal", "count": 4}])


# --- Helpers -------------------------------------------------------------------------------

func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area


func _ids(recipes: Array) -> Array:
	return recipes.map(func(recipe: Dictionary) -> String: return str(recipe["id"]))


func _point(label: Label, line: int) -> Vector2:
	return label.get_global_transform_with_canvas() * Vector2(4.0, MenuInput.line_height(label) * (float(line) + 0.5))


func _move(label: Label, line: int) -> InputEventMouseMotion:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.position = _point(label, line)
	event.global_position = event.position
	return event


func _click_at(at: Vector2, button: MouseButton = MOUSE_BUTTON_LEFT) -> InputEventMouseButton:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = button
	event.pressed = true
	event.position = at
	event.global_position = at
	return event


func _wheel(button: MouseButton) -> InputEventMouseButton:
	return _click_at(Vector2(3.0, 3.0), button)


func _on_sound(id: StringName) -> void:
	_heard.append(id)
