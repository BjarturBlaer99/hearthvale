extends GdUnitTestSuite
## The Tab menu's two lists (icons, an axe and the item bar, step I2): "Food", as before (a
## click eats), and "Pack", everything he carries in the pack's order with its picture and
## count, to look at only. Turned with left and right or a click on a name; it opens on Food,
## or on Pack when he has no food, so Tab always opens.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const VILLAGE: String = "res://world/areas/village/village.tscn"
## What a full pack carries, in the order picked up (the can's water is in the can).
const FULL: Array = [[&"wooden_sword", 1], [&"coin", 412], [&"bow", 1], [&"arrow", 20], [&"bomb", 5],
	[&"small_key", 1], [&"hoe", 1], [&"watering_can", 1], [&"water", 10], [&"pickaxe", 1],
	[&"turnip_seeds", 8], [&"bread", 3], [&"egg", 4], [&"stone", 40], [&"wood", 25], [&"copper_ore", 7],
	[&"copper_bar", 2], [&"coal", 5], [&"fibre", 12], [&"hay", 8], [&"weavers_shuttle", 1]]

var _area: Node


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	Quests.refresh()
	GameState.set_time(float(GameState.day_clock().in_day("12:00")))


func after_test() -> void:
	if is_instance_valid(_area):
		_area.free()
	_area = null
	GameState.clear()


func test_pack_lists_every_stack_in_the_packs_order_with_its_picture() -> void:
	for item: Array in FULL:
		GameState.add_item(item[0], item[1])
	var village: AreaController = _load(VILLAGE)
	assert_bool(village.open_item_menu()).is_true()
	var menu: ItemMenu = village.hud.item_menu
	assert_that(menu.list).override_failure_message("with food it opens on Food").is_equal(ItemMenu.FOOD)
	menu.switch_list()
	assert_that(menu.list).is_equal(ItemMenu.PACK)
	assert_str(menu.title_text()).is_equal("Pack")
	# Coins, a key, a quest thing, materials, tools, food, seeds: every stack, the water in its can.
	var expected: Array = []
	for item: Array in FULL:
		if item[0] != &"water":
			expected.append(String(item[0]))
	assert_array(_ids(menu.items)).is_equal(expected)
	var lines: Array = []
	var icons: Array[StringName] = []
	for i: int in menu.items.size():
		if i > 0:
			menu.move_cursor(1)
		var shown: PackedStringArray = menu.shown_lines()
		lines.append(shown[menu.selected - menu.top].substr(ItemMenu.CURSOR.length()))
		icons.append(menu.shown_icons()[menu.selected - menu.top])
		assert_int(shown.size()).override_failure_message("five lines, never more").is_less_equal(ItemMenu.ROWS)
	assert_array(lines.slice(0, 8)).is_equal(["Wooden Sword", "412 coins", "Bow", "Arrows x20", "Bombs x5", "Small Key x1", "Hoe", "Watering Can (Water x10)"])
	assert_array(lines.slice(17)).is_equal(["Fibre x12", "Hay x8", "Weaver's Shuttle"])
	assert_array(icons).is_equal(ItemIconColumn.icons_of(expected))
	assert_that(icons[1]).is_equal(&"coin")
	assert_that(icons[5]).is_equal(&"key")


func test_a_long_pack_scrolls_its_pictures_with_it() -> void:
	for item: Array in FULL:
		GameState.add_item(item[0], item[1])
	var village: AreaController = _load(VILLAGE)
	village.open_item_menu()
	var menu: ItemMenu = village.hud.item_menu
	menu.switch_list()
	for step: int in 9:
		menu.move_cursor(1)
	assert_int(menu.top).is_equal(5)
	assert_array(menu.shown_icons()).is_equal(ItemIconColumn.icons_of(_ids(menu.items).slice(5, 10)))
	assert_str(menu.shown_lines()[4]).is_equal("> Turnip Seeds x8")


func test_nothing_on_pack_is_used_dropped_or_put_in_hand() -> void:
	# Five stacks: every line shows at once.
	for item: Array in [[&"wooden_sword", 1], [&"bow", 1], [&"arrow", 5], [&"bread", 2], [&"stone", 6]]:
		GameState.add_item(item[0], item[1])
	GameState.equip(&"bow")
	GameState.set_energy(40.0)
	var village: AreaController = _load(VILLAGE)
	village.open_item_menu()
	var menu: ItemMenu = village.hud.item_menu
	menu.switch_list()
	var pack: Array = GameState.inventory.duplicate(true)
	await await_idle_frame()
	var list: Label = menu.get_node(^"Panel/List")
	for line: int in menu.items.size():
		# A click on each line, by mouse or by key: the cursor goes there, and that is all.
		menu._unhandled_input(_click(list, line, 4.0))
		assert_int(menu.selected).is_equal(line)
		for action: StringName in [&"use_item", &"interact", &"ui_accept"]:
			menu._unhandled_input(_action(action))
		assert_bool(menu.is_open()).override_failure_message("it stays open").is_true()
		assert_that(menu.confirm()).is_equal(&"")
	assert_that(GameState.equipped).override_failure_message("what is in hand is chosen on the bar").is_equal(&"bow")
	assert_array(GameState.inventory).override_failure_message("nothing taken from the pack").is_equal(pack)
	assert_float(GameState.energy).override_failure_message("nothing eaten").is_equal(40.0)
	assert_str(menu.help_text()).override_failure_message("no click is offered").is_equal("A / D: turn   Tab: close")
	assert_bool(village.player.controls_enabled).override_failure_message("he stands still while it is open").is_false()


func test_tab_with_no_food_opens_on_pack() -> void:
	GameState.add_item(&"wooden_sword")
	GameState.add_item(&"cherry_blossom", 2)
	var village: AreaController = _load(VILLAGE)
	assert_bool(village.open_item_menu()).is_true()
	var menu: ItemMenu = village.hud.item_menu
	assert_that(menu.list).is_equal(ItemMenu.PACK)
	assert_array(Array(menu.shown_lines())).is_equal(["> Wooden Sword", "  Cherry Blossoms x2"])
	# Food is still there to turn to, and says there is none.
	menu.switch_list()
	assert_that(menu.list).is_equal(ItemMenu.FOOD)
	assert_array(Array(menu.shown_lines())).is_equal([ItemMenu.NOTHING_TO_EAT])
	assert_array(menu.shown_icons()).is_empty()
	assert_that(menu.confirm()).override_failure_message("nothing to eat").is_equal(&"")
	# With nothing at all it still opens, and says so.
	GameState.clear()
	GameState.new_game()
	village.player.controls_enabled = true
	assert_bool(village.open_item_menu()).is_true()
	assert_array(Array(menu.shown_lines())).is_equal([ItemMenu.NOTHING_CARRIED])


func test_left_and_right_or_a_click_on_a_name_turn_the_lists() -> void:
	GameState.add_item(&"bread", 2)
	GameState.add_item(&"stone", 6)
	GameState.set_energy(40.0)
	var village: AreaController = _load(VILLAGE)
	village.open_item_menu()
	var menu: ItemMenu = village.hud.item_menu
	assert_str(menu.tabs_text()).is_equal("[Food]   Pack ")
	menu._unhandled_input(_action(&"move_right"))
	assert_that(menu.list).is_equal(ItemMenu.PACK)
	assert_str(menu.tabs_text()).is_equal(" Food   [Pack]")
	menu._unhandled_input(_action(&"move_left"))
	assert_that(menu.list).is_equal(ItemMenu.FOOD)
	# Up and down move the cursor; they don't turn.
	menu._unhandled_input(_action(&"move_down"))
	assert_that(menu.list).is_equal(ItemMenu.FOOD)
	await await_idle_frame()
	var tabs: Label = menu.get_node(^"Panel/Tabs")
	var pack_x: float = MenuInput.width_of(tabs, menu.tab_parts()[0] + ItemMenu.TAB_GAP) + 4.0
	menu._unhandled_input(_click(tabs, 0, pack_x))
	assert_that(menu.list).override_failure_message("a click on 'Pack'").is_equal(ItemMenu.PACK)
	assert_bool(menu.is_open()).is_true()
	assert_array(Array(menu.shown_lines())).is_equal(["> Bread x2", "  Stone x6"])
	menu._unhandled_input(_click(tabs, 0, 4.0))
	assert_that(menu.list).override_failure_message("a click on 'Food'").is_equal(ItemMenu.FOOD)
	assert_float(GameState.energy).override_failure_message("turning eats nothing").is_equal(40.0)
	# Food is as it was: a click eats and closes.
	menu._unhandled_input(_click(menu.get_node(^"Panel/List"), 0, 4.0))
	assert_bool(menu.is_open()).is_false()
	assert_float(GameState.energy).is_equal(70.0)
	assert_int(GameState.item_count(&"bread")).is_equal(1)


func test_each_lists_words_fit_their_labels() -> void:
	var village: AreaController = _load(VILLAGE)
	var menu: ItemMenu = village.hud.item_menu
	var help: Label = menu.get_node(^"Panel/Help")
	var tabs: Label = menu.get_node(^"Panel/Tabs")
	for list: StringName in ItemMenu.LISTS:
		assert_float(MenuInput.width_of(help, ItemMenu.HELP[list])).override_failure_message("%s's help fits" % list).is_less_equal(help.size.x)
	assert_float(MenuInput.width_of(tabs, " Food   [Pack]")).is_less_equal(tabs.size.x)
	assert_float(help.position.x + help.size.x).override_failure_message("the help ends where the count begins").is_less_equal(menu.get_node(^"Panel/Count").position.x)
	var list: Label = menu.get_node(^"Panel/List")
	assert_float(MenuInput.width_of(list, "> Watering Can (Water x10)")).is_less_equal(list.size.x)


func _ids(entries: Array[Dictionary]) -> Array:
	var out: Array = []
	for entry: Dictionary in entries:
		out.append(str(entry["id"]))
	return out


func _action(action: StringName) -> InputEventAction:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = true
	return event


func _click(label: Label, line: int, x: float) -> InputEventMouseButton:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = label.get_global_transform_with_canvas() * Vector2(x, MenuInput.line_height(label) * (float(line) + 0.5))
	event.global_position = event.position
	return event


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area
