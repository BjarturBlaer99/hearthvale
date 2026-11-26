extends GdUnitTestSuite
## Icons in the lists (icons, an axe and the item bar, step I1): every line of a shop's two
## lists (Tilda's, Farmer Oda's stall), the Tab menu and the chest has its picture beside it
## (ItemIconColumn), in the order of the lines shown, moving with the list as it scrolls. An
## animal's line has its own picture (Herd.icon_of: the hen, the sheep, the cow). The lines are
## 16 px apart, and the pointer finds the line under it, on its words or on its picture.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const VILLAGE: String = "res://world/areas/village/village.tscn"
const HOME: String = "res://world/areas/home/home.tscn"
## How far apart the lines of a list with pictures are.
const LINE: float = 16.0

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


func test_the_column_draws_the_icons_it_is_given_a_line_apart() -> void:
	assert_array(ItemIconColumn.icons_of(["bread", "pickaxe", "copper_ore"])).is_equal([&"bread", &"pickaxe", &"copper_ore"])
	assert_array(ItemIconColumn.icons_of(["bomb"])).override_failure_message("an icon by its type").is_equal([&"bomb_dim"])
	assert_array(ItemIconColumn.icons_of([])).is_empty()
	var column: ItemIconColumn = auto_free(ItemIconColumn.new())
	var shown: Array[StringName] = [&"bread", &"hen"]
	column.show_icons(shown, LINE)
	assert_array(column.icons).is_equal(shown)
	assert_float(column.line_height).is_equal(LINE)
	shown.append(&"cow")
	assert_int(column.icons.size()).override_failure_message("it keeps its own copy").is_equal(2)


func test_an_animal_names_its_picture_in_its_data() -> void:
	var named: Dictionary = {&"chicken": &"hen", &"sheep": &"sheep", &"cow": &"cow"}
	for kind: StringName in named:
		var icon: StringName = Herd.icon_of(DataRegistry.get_animal(kind))
		assert_that(icon).is_equal(named[kind])
		assert_bool(ItemIcons.FRAMES.has(icon)).override_failure_message("%s is a frame of items.png" % icon).is_true()
	assert_that(Herd.icon_of({"id": "goat"})).override_failure_message("a kind without one names none").is_equal(&"")
	assert_that(ShopMenu.icon_of({"animal": "cow", "price": 240})).is_equal(&"cow")
	assert_that(ShopMenu.icon_of({"item": "pickaxe", "count": 1, "price": 25})).is_equal(&"pickaxe")


func test_tildas_two_lists_show_each_lines_picture_and_scroll_with_it() -> void:
	GameState.add_item(GameState.COIN, 20)
	var village: AreaController = _load(VILLAGE)
	assert_bool(village.open_shop(&"tilda", Shop.BUY)).is_true()
	var counter: ShopMenu = village.hud.shop_menu
	assert_float(MenuInput.line_height(counter.get_node(^"Panel/List"))).override_failure_message("16 px lines").is_equal(LINE)
	assert_array(counter.shown_icons()).is_equal(_icons_of(counter, 0))
	assert_int(counter.shown_icons().size()).is_equal(ShopMenu.ROWS)
	# Down past the fifth line: the pictures move with the words.
	for step: int in ShopMenu.ROWS + 2:
		counter.move_cursor(1)
	assert_int(counter.top).is_greater(0)
	assert_array(counter.shown_icons()).is_equal(_icons_of(counter, counter.top))
	assert_bool(counter.shown_lines()[counter.selected - counter.top].begins_with(ShopMenu.CURSOR)).is_true()
	# Her other list: his harvest, ore and bars, each with its own picture.
	GameState.add_item(&"turnip", 3)
	GameState.add_item(&"copper_ore", 2)
	GameState.add_item(&"iron_bar", 1)
	counter.switch_mode()
	assert_int(counter.shown_lines().size()).is_equal(3)
	assert_array(counter.shown_icons()).is_equal([&"turnip", &"copper_ore", &"iron_bar"])
	# Nothing to sell: the line that says so has no picture.
	GameState.inventory.clear()
	counter.switch_mode()
	counter.switch_mode()
	assert_array(Array(counter.shown_lines())).is_equal([ShopMenu.NOTHING_TO_SELL])
	assert_array(counter.shown_icons()).is_empty()
	counter.close()
	assert_array(counter.shown_icons()).override_failure_message("closed, nothing shown").is_empty()


func test_odas_stall_shows_the_hen_the_sheep_and_the_cow() -> void:
	var village: AreaController = _load(VILLAGE)
	assert_bool(village.open_shop(&"oda", Shop.BUY)).is_true()
	var counter: ShopMenu = village.hud.shop_menu
	assert_array(Array(counter.shown_lines())).is_equal(["> Chicken: 60 coins", "  Sheep: 180 coins", "  Cow: 240 coins"])
	assert_array(counter.shown_icons()).is_equal([&"hen", &"sheep", &"cow"])


func test_the_tab_menu_shows_each_foods_picture() -> void:
	GameState.add_item(&"bread", 2)
	GameState.add_item(&"wild_berries", 3)
	GameState.add_item(&"egg", 1)
	var village: AreaController = _load(VILLAGE)
	assert_bool(village.open_item_menu()).is_true()
	var menu: ItemMenu = village.hud.item_menu
	assert_float(MenuInput.line_height(menu.get_node(^"Panel/List"))).is_equal(LINE)
	var ids: Array = []
	for item: Dictionary in menu.items:
		ids.append(str(item["id"]))
	assert_int(ids.size()).is_equal(3)
	assert_array(menu.shown_icons()).is_equal(ItemIconColumn.icons_of(ids))
	assert_array(menu.shown_icons()).contains([&"bread", &"berries", &"egg"])


func test_a_long_food_list_scrolls_its_pictures_with_it() -> void:
	for food: StringName in [&"bread", &"wild_berries", &"mushroom", &"turnip", &"carrot", &"egg", &"milk"]:
		GameState.add_item(food, 1)
	var village: AreaController = _load(VILLAGE)
	assert_bool(village.open_item_menu()).is_true()
	var menu: ItemMenu = village.hud.item_menu
	assert_int(menu.items.size()).is_equal(7)
	for step: int in 6:
		menu.move_cursor(1)
	assert_int(menu.top).is_equal(2)
	var ids: Array = []
	for i: int in range(2, 7):
		ids.append(str(menu.items[i]["id"]))
	assert_array(menu.shown_icons()).is_equal(ItemIconColumn.icons_of(ids))


func test_the_chests_two_lists_show_their_pictures() -> void:
	GameState.set_flag(Crafting.furnished_flag(&"chest"), true)
	GameState.add_item(&"stone", 9)
	GameState.add_item(&"coal", 3)
	GameState.store().put("turnip", 6, 30)
	GameState.store().put("iron_ore", 4, 30)
	var home: AreaController = _load(HOME)
	assert_bool(home.open_store()).is_true()
	var menu: StoreMenu = home.hud.store_menu
	for list: String in ["Panel/PackList", "Panel/ChestList"]:
		assert_float(MenuInput.line_height(menu.get_node(NodePath(list)))).is_equal(LINE)
	assert_array(menu.shown_icons(StoreMenu.PACK)).is_equal([&"stone", &"coal"])
	assert_array(menu.shown_icons(StoreMenu.CHEST)).is_equal([&"turnip", &"iron_ore"])
	# A stack put away: both columns follow.
	assert_bool(menu.confirm()).is_true()
	assert_array(menu.shown_icons(StoreMenu.PACK)).is_equal([&"coal"])
	assert_array(menu.shown_icons(StoreMenu.CHEST)).is_equal([&"turnip", &"iron_ore", &"stone"])


func test_a_long_chest_scrolls_its_pictures_with_it() -> void:
	GameState.set_flag(Crafting.furnished_flag(&"chest"), true)
	var kinds: Array[String] = ["stone", "coal", "copper_ore", "iron_ore", "gold_ore", "wood", "turnip", "carrot", "wheat", "potato"]
	for kind: String in kinds:
		GameState.store().put(kind, 3, 30)
	var home: AreaController = _load(HOME)
	home.open_store()
	var menu: StoreMenu = home.hud.store_menu
	assert_that(menu.side).is_equal(StoreMenu.CHEST)
	for step: int in 9:
		menu.move_cursor(1)
	var top: int = int(menu.tops[StoreMenu.CHEST])
	assert_int(top).is_equal(kinds.size() - StoreMenu.ROWS)
	assert_array(menu.shown_icons()).is_equal(ItemIconColumn.icons_of(kinds.slice(top, top + StoreMenu.ROWS)))


func test_the_pointer_finds_the_line_on_its_words_or_on_its_picture() -> void:
	GameState.add_item(GameState.COIN, 20)
	var village: AreaController = _load(VILLAGE)
	village.open_shop(&"tilda", Shop.BUY)
	var counter: ShopMenu = village.hud.shop_menu
	var list: Label = counter.get_node(^"Panel/List")
	var icons: ItemIconColumn = counter.get_node(^"Panel/Icons")
	await await_idle_frame()
	# The pictures stand in the room beside the words.
	assert_float(list.position.x - icons.position.x).is_equal(float(ItemIconColumn.WIDTH))
	# On the words of the fourth line, 16 px lines apart.
	counter._unhandled_input(_move(list, 3, 4.0))
	assert_int(counter.selected).is_equal(3)
	# On the picture of the second line.
	counter._unhandled_input(_move(list, 1, -float(ItemIconColumn.SIZE) / 2.0))
	assert_int(counter.selected).is_equal(1)
	# Left of the pictures is no line: the cursor stays.
	counter._unhandled_input(_move(list, 4, -float(ItemIconColumn.WIDTH) - 4.0))
	assert_int(counter.selected).is_equal(1)
	# A click on the fifth line's picture buys that ware.
	var fifth: String = counter.shown_lines()[4].substr(ShopMenu.CURSOR.length())
	counter._unhandled_input(_click(list, 4, -float(ItemIconColumn.SIZE) / 2.0))
	assert_int(counter.selected).is_equal(4)
	assert_str(counter.note_text()).override_failure_message("the fifth line's deal: %s" % fifth).contains("Bought: ")
	# The Tab menu and the chest are pointed at on a picture too.
	counter.close()
	GameState.add_item(&"bread", 1)
	GameState.add_item(&"wild_berries", 1)
	village.player.controls_enabled = true
	assert_bool(village.open_item_menu()).is_true()
	var menu: ItemMenu = village.hud.item_menu
	await await_idle_frame()
	menu._unhandled_input(_move(menu.get_node(^"Panel/List"), 1, -8.0))
	assert_int(menu.selected).is_equal(1)


func test_the_chest_is_pointed_at_on_a_picture() -> void:
	GameState.set_flag(Crafting.furnished_flag(&"chest"), true)
	GameState.add_item(&"stone", 9)
	GameState.add_item(&"coal", 3)
	GameState.store().put("turnip", 6, 30)
	GameState.store().put("iron_ore", 4, 30)
	var home: AreaController = _load(HOME)
	home.open_store()
	var menu: StoreMenu = home.hud.store_menu
	await await_idle_frame()
	menu._unhandled_input(_move(menu.get_node(^"Panel/ChestList"), 1, -8.0))
	assert_that(menu.side).is_equal(StoreMenu.CHEST)
	assert_int(menu.selected).is_equal(1)
	menu._unhandled_input(_move(menu.get_node(^"Panel/PackList"), 1, -8.0))
	assert_that(menu.side).is_equal(StoreMenu.PACK)
	assert_int(menu.selected).is_equal(1)


func test_every_box_still_holds_its_lines_help_and_count() -> void:
	var village: AreaController = _load(VILLAGE)
	for scene: Control in [village.hud.shop_menu, village.hud.item_menu, village.hud.store_menu]:
		var panel: Control = scene.get_node(^"Panel")
		for child: Node in panel.get_children():
			if child is Control:
				var rect: Rect2 = Rect2((child as Control).position, (child as Control).size)
				assert_bool(Rect2(Vector2.ZERO, panel.size).encloses(rect)).override_failure_message("%s/%s is inside its box" % [scene.name, child.name]).is_true()
		assert_bool(panel.size.y <= 360.0 - 16.0).override_failure_message("%s fits the screen" % scene.name).is_true()
	# Five lines (seven in the chest), 16 px each, above the note and the help line.
	var lists: Dictionary = {
		village.hud.shop_menu: ["Panel/List", ShopMenu.ROWS, "Panel/Note"],
		village.hud.item_menu: ["Panel/List", ItemMenu.ROWS, "Panel/Help"],
		village.hud.store_menu: ["Panel/PackList", StoreMenu.ROWS, "Panel/Note"],
	}
	for scene: Control in lists:
		var list: Label = scene.get_node(NodePath(lists[scene][0]))
		var below: Control = scene.get_node(NodePath(lists[scene][2]))
		assert_float(list.size.y).override_failure_message("%s holds its lines" % scene.name).is_greater_equal(LINE * int(lists[scene][1]))
		assert_float(below.position.y).override_failure_message("%s: nothing over the lines" % scene.name).is_greater_equal(list.position.y + LINE * int(lists[scene][1]))


func _icons_of(counter: ShopMenu, top: int) -> Array[StringName]:
	var shown: Array[StringName] = []
	var list: Array[Dictionary] = counter.entries()
	for i: int in range(top, mini(top + ShopMenu.ROWS, list.size())):
		shown.append(ShopMenu.icon_of(list[i]))
	return shown


## The mouse moved to the middle of line `line` of `label`, `x` in from its left (less than 0:
## left of the words, on the pictures).
func _move(label: Label, line: int, x: float) -> InputEventMouseMotion:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.position = _point(label, line, x)
	event.global_position = event.position
	return event


func _click(label: Label, line: int, x: float) -> InputEventMouseButton:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = _point(label, line, x)
	event.global_position = event.position
	return event


func _point(label: Label, line: int, x: float) -> Vector2:
	return label.get_global_transform_with_canvas() * Vector2(x, MenuInput.line_height(label) * (float(line) + 0.5))


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area
