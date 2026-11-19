extends GdUnitTestSuite
## The mouse points in menus (the user's request, 2026-11-15): in every menu and list the line
## under the pointer is highlighted as the mouse moves, and a click on a line chooses that
## line. A click that is on no line does what it always did (the highlighted line; reading on
## in a conversation), and the wheel moves the highlight. The keys are as they were. Uses its
## own save slot and settings file.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const TITLE: String = "res://ui/title_screen.tscn"
const ENDING: String = "res://ui/ending_screen.tscn"
const VILLAGE: String = "res://world/areas/village/village.tscn"
const HOME: String = "res://world/areas/home/home.tscn"
const SHOP: String = "res://world/areas/shop/shop.tscn"
const TEST_SLOT: int = 970
const TEST_SETTINGS: String = "user://test_pointer_settings.cfg"
## Well away from every list.
const NOWHERE: Vector2 = Vector2(3.0, 3.0)

var _area: Node
var _heard: Array[StringName] = []


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	GameState.set_time(float(GameState.day_clock().in_day("12:00")))
	SaveSystem.current_slot = TEST_SLOT
	Settings.path = TEST_SETTINGS
	Settings.load_settings()
	GameState.set_flag(StoryGates.FIRST_CROP, true)
	Quests.refresh()
	_heard.clear()
	EventBus.sound.connect(_on_sound)


func after_test() -> void:
	EventBus.sound.disconnect(_on_sound)
	if is_instance_valid(_area):
		_area.free()
	_area = null
	get_tree().paused = false
	SaveSystem.erase_slot(TEST_SLOT)
	SaveSystem.current_slot = SaveSystem.GAME_SLOT
	if FileAccess.file_exists(TEST_SETTINGS):
		DirAccess.remove_absolute(TEST_SETTINGS)
	Settings.path = Settings.PATH
	Settings.load_settings()
	GameState.clear()


func test_the_title_follows_the_pointer_and_a_click_chooses_its_line() -> void:
	var title: TitleScreen = _screen(TITLE)
	var list: Label = title.get_node(^"Menu/List")
	var travelled: Array[String] = []
	var quit: Array[bool] = []
	title.travel = func(path: String) -> void: travelled.append(path)
	title.quit = func() -> void: quit.append(true)
	assert_array(Array(title.shown_lines())).is_equal(["  (Continue)", "> New game", "  Settings", "  Quit"])
	title._unhandled_input(_move(list, 3))
	assert_array(Array(title.shown_lines())).is_equal(["  (Continue)", "  New game", "  Settings", "> Quit"])
	assert_array(_heard).override_failure_message("the cursor is heard to move").contains_exactly([&"menu_move"])
	# Moving along the same line says nothing more; a line that can't be chosen is passed over.
	title._unhandled_input(_move(list, 3))
	title._unhandled_input(_move(list, 0))
	assert_array(_heard).contains_exactly([&"menu_move"])
	assert_that(title.cursor.selected_id()).is_equal(TitleScreen.QUIT)
	# A click on a line that can't be chosen chooses nothing (not the highlighted Quit).
	title._unhandled_input(_click(list, 0))
	assert_array(quit).is_empty()
	assert_array(travelled).is_empty()
	# A click on a line chooses that line, wherever the cursor was.
	title._unhandled_input(_click(list, 1))
	assert_array(travelled).is_equal([VILLAGE])
	# A click on no line chooses the highlighted one, as a click always did.
	title._unhandled_input(_move(list, 3))
	title._unhandled_input(_click_at(NOWHERE))
	assert_array(quit).is_equal([true])
	# The right button chooses too, and the keys are as they were.
	title._unhandled_input(_click(list, 1, MOUSE_BUTTON_RIGHT))
	assert_int(travelled.size()).is_equal(2)
	title._unhandled_input(_action(&"move_down"))
	assert_that(title.cursor.selected_id()).is_equal(TitleScreen.SETTINGS)


func test_the_pause_menu_and_its_pages_follow_the_pointer() -> void:
	var village: AreaController = _load(VILLAGE)
	assert_bool(village.open_pause_menu()).is_true()
	var menu: PauseMenu = village.hud.pause_menu
	var list: Label = menu.get_node(^"Panel/List")
	menu._unhandled_input(_move(list, 3))
	assert_that(menu.cursor.selected_id()).is_equal(PauseMenu.FRIENDS)
	assert_str(menu.shown_lines()[3]).is_equal("> Friends")
	# The wheel moves the highlight, a line a notch.
	menu._unhandled_input(_wheel(MOUSE_BUTTON_WHEEL_DOWN))
	assert_that(menu.cursor.selected_id()).is_equal(PauseMenu.SETTINGS)
	menu._unhandled_input(_wheel(MOUSE_BUTTON_WHEEL_UP))
	menu._unhandled_input(_wheel(MOUSE_BUTTON_WHEEL_UP))
	assert_that(menu.cursor.selected_id()).is_equal(PauseMenu.QUESTS)
	# A click on "Save" saves, though the cursor was on "Quests".
	menu._unhandled_input(_click(list, 1))
	assert_str(menu.note()).is_equal("Saved.")
	assert_bool(SaveSystem.has_save()).is_true()

	# The quest log: pointing at a quest reads it, a click on "Back" goes back.
	menu._unhandled_input(_click(list, 2))
	var log: QuestLog = menu.quest_log
	assert_bool(log.is_open()).is_true()
	var quests: Label = log.get_node(^"Panel/List")
	assert_array(Array(log.all_lines())).is_equal(["> A Place of Your Own", "  Back"])
	log._unhandled_input(_move(quests, 1))
	assert_that(log.cursor.selected_id()).is_equal(QuestLog.BACK)
	log._unhandled_input(_click(quests, 0))
	assert_bool(log.is_open()).override_failure_message("a click on a quest reads it").is_true()
	assert_str(log.shown_detail()).contains("[")
	log._unhandled_input(_click(quests, 1))
	assert_bool(log.is_open()).override_failure_message("a click on Back goes back").is_false()
	assert_bool(menu.get_node(^"Panel").visible).is_true()

	# Settings: pointing at "Back" and a click closes it; nothing was changed.
	var before: Array = Array(SettingsData.KEYS).map(func(key: StringName) -> String: return Settings.data.describe(key))
	menu._unhandled_input(_click(list, 4))
	var settings: SettingsMenu = menu.settings_menu
	assert_bool(settings.is_open()).is_true()
	var lines: Label = settings.get_node(^"Panel/List")
	settings._unhandled_input(_move(lines, settings.cursor.options.size() - 1))
	assert_that(settings.cursor.selected_id()).is_equal(SettingsMenu.BACK)
	settings._unhandled_input(_click(lines, settings.cursor.options.size() - 1))
	assert_bool(settings.is_open()).is_false()
	assert_array(Array(SettingsData.KEYS).map(func(key: StringName) -> String: return Settings.data.describe(key))).is_equal(before)

	# A click on "Resume" resumes.
	menu._unhandled_input(_click(list, 0))
	assert_bool(menu.is_open()).is_false()
	assert_bool(get_tree().paused).is_false()


func test_a_long_quest_log_is_scrolled_by_the_wheel_and_pointed_at_where_it_stands() -> void:
	for quest: StringName in [&"lost_shuttle", &"eggs_for_tilda", &"slime_bounty", &"pie_for_pip", &"seed_stock", &"elders_supper"]:
		Quests.runner.start(quest)
	var village: AreaController = _load(VILLAGE)
	village.open_pause_menu()
	village.hud.pause_menu.choose(PauseMenu.QUESTS)
	var log: QuestLog = village.hud.pause_menu.quest_log
	var quests: Label = log.get_node(^"Panel/List")
	var all: PackedStringArray = log.all_lines()
	assert_int(all.size()).override_failure_message("seven quests and Back").is_equal(8)
	for notch: int in 6:
		log._unhandled_input(_wheel(MOUSE_BUTTON_WHEEL_DOWN))
	assert_int(log.cursor.selected).is_equal(6)
	assert_int(log.top).override_failure_message("the list has moved on with the cursor").is_equal(2)
	# The first line showing is the third of the list: pointing at it puts the cursor there.
	log._unhandled_input(_move(quests, 0))
	assert_int(log.cursor.selected).is_equal(2)
	assert_str(log.shown_lines()[0]).is_equal("> " + all[2].substr(2))
	# Below the lines that show there is nothing to point at.
	log._unhandled_input(_move(quests, QuestLog.ROWS))
	assert_int(log.cursor.selected).is_equal(2)


func test_the_food_menu_follows_the_pointer_and_a_click_eats_that_food() -> void:
	GameState.add_item(&"bread", 2)
	GameState.add_item(&"wild_berries", 3)
	GameState.add_item(&"mushroom", 1)
	GameState.set_energy(40.0)
	var village: AreaController = _load(VILLAGE)
	assert_bool(village.open_item_menu()).is_true()
	var menu: ItemMenu = village.hud.item_menu
	var list: Label = menu.get_node(^"Panel/List")
	menu._unhandled_input(_move(list, 2))
	assert_that(menu.selected_id()).is_equal(&"mushroom")
	menu._unhandled_input(_click(list, 1))
	assert_bool(menu.is_open()).is_false()
	assert_int(GameState.item_count(&"wild_berries")).override_failure_message("the berries he clicked on, not the mushroom under the cursor").is_equal(2)
	assert_int(GameState.item_count(&"mushroom")).is_equal(1)
	assert_float(GameState.energy).is_equal(48.0)
	# A click on no line eats what the cursor is on.
	assert_bool(village.open_item_menu()).is_true()
	menu._unhandled_input(_click_at(NOWHERE))
	assert_int(GameState.item_count(&"bread")).is_equal(1)


func test_tildas_lists_follow_the_pointer_and_a_click_on_a_name_turns_to_that_list() -> void:
	GameState.add_item(&"coin", 50)
	GameState.add_item(&"turnip", 4)
	var shop: AreaController = _load(SHOP)
	assert_bool(shop.open_shop(&"tilda", Shop.BUY)).is_true()
	var counter: ShopMenu = shop.hud.shop_menu
	var list: Label = counter.get_node(^"Panel/List")
	var tabs: Label = counter.get_node(^"Panel/Tabs")
	counter._unhandled_input(_move(list, 2))
	assert_int(counter.selected).is_equal(2)
	assert_str(counter.shown_lines()[2]).is_equal("> Bread: 6 coins")
	# A click on a line buys that ware.
	counter._unhandled_input(_click(list, 0))
	assert_int(GameState.item_count(&"arrow")).is_equal(10)
	assert_int(counter.selected).is_equal(0)
	assert_bool(counter.is_open()).override_failure_message("the list stays for more deals").is_true()
	# A click on "Sell" turns to what she buys, and buys nothing.
	var coins: int = GameState.item_count(&"coin")
	counter._unhandled_input(_click_at(_tab_point(counter, tabs, 1)))
	assert_that(counter.mode).is_equal(Shop.SELL)
	assert_int(GameState.item_count(&"coin")).is_equal(coins)
	counter._unhandled_input(_click_at(_tab_point(counter, tabs, 1)))
	assert_that(counter.mode).override_failure_message("a click on the list he is on changes nothing").is_equal(Shop.SELL)
	assert_int(GameState.item_count(&"turnip")).is_equal(4)
	counter._unhandled_input(_click(list, 0))
	assert_int(GameState.item_count(&"turnip")).override_failure_message("a click on the turnips sells one").is_equal(3)
	# A click between the two names was aimed at them: it makes no deal.
	var gap: Vector2 = _tab_point(counter, tabs, 1) - Vector2(3.0, 0.0)
	counter._unhandled_input(_click_at(gap))
	assert_int(GameState.item_count(&"turnip")).is_equal(3)
	assert_that(counter.mode).is_equal(Shop.SELL)
	counter._unhandled_input(_click_at(_tab_point(counter, tabs, 0)))
	assert_that(counter.mode).is_equal(Shop.BUY)
	# The wheel moves the cursor down a long list, and the list with it.
	for notch: int in 6:
		counter._unhandled_input(_wheel(MOUSE_BUTTON_WHEEL_DOWN))
	assert_int(counter.selected).is_equal(6)
	assert_int(counter.top).is_equal(2)
	counter._unhandled_input(_move(list, 0))
	assert_int(counter.selected).override_failure_message("the first line showing is the third ware").is_equal(2)


func test_the_gifts_follow_the_pointer_and_a_click_gives_that_thing() -> void:
	for item: Array in [[&"bread", 2], [&"wild_berries", 4], [&"cherry_blossom", 3]]:
		GameState.add_item(item[0], item[1])
	var village: AreaController = _load(VILLAGE)
	assert_bool(village.open_gifts(&"pip")).is_true()
	var gifts: GiftMenu = village.hud.gift_menu
	var list: Label = gifts.get_node(^"Panel/List")
	gifts._unhandled_input(_move(list, 2))
	assert_int(gifts.selected).is_equal(2)
	gifts._unhandled_input(_click(list, 1))
	assert_bool(gifts.is_open()).is_false()
	assert_int(GameState.item_count(&"wild_berries")).override_failure_message("the berries he clicked on").is_equal(3)
	assert_int(GameState.item_count(&"cherry_blossom")).is_equal(3)
	assert_int(GameState.friend_points(&"pip")).is_equal(GameState.friendship().liked_gift)


func test_a_conversations_answers_follow_the_pointer_and_a_click_elsewhere_reads_on() -> void:
	var village: AreaController = _load(VILLAGE)
	Steps.stand_before(village, "Pip")
	assert_bool(village.interact()).is_true()
	var box: DialogueBox = village.hud.dialogue
	await await_idle_frame()
	var answers: Label = box.get_node(^"Panel/Lines/Options")
	assert_array(Array(box.shown_options())).is_equal(["Anything else?", "Goodbye."])
	box.open_for = 1.0
	box._unhandled_input(_move(answers, 1))
	assert_int(box.selected).is_equal(1)
	assert_array(Array(box.shown_option_lines())).is_equal(["  Anything else?", "> Goodbye."])
	# A left click on an answer gives that answer, though the cursor was on the other.
	box._unhandled_input(_click(answers, 0))
	assert_bool(box.is_open()).is_true()
	assert_str(box.shown_text()).contains("My brother")
	# A right click doesn't answer, wherever it is.
	box._unhandled_input(_click(answers, 0, MOUSE_BUTTON_RIGHT))
	assert_bool(box.is_open()).is_true()
	# A left click anywhere else gives the highlighted answer: here, the only one.
	box._unhandled_input(_click_at(NOWHERE))
	assert_bool(box.is_open()).is_false()

	# A sign has no answers: a left click anywhere reads on, and the pointer changes nothing.
	Steps.stand_before(village, "WelcomeSign")
	assert_bool(village.interact()).is_true()
	box.open_for = 1.0
	box._unhandled_input(_move(answers, 0))
	assert_bool(box.is_open()).is_true()
	box._unhandled_input(_click_at(NOWHERE))
	assert_bool(box.is_open()).is_false()


func test_a_long_list_of_answers_is_scrolled_by_the_wheel() -> void:
	var home: AreaController = _load(HOME)
	Steps.stand_before(home, "Hearth")
	assert_bool(home.interact()).is_true()
	var box: DialogueBox = home.hud.dialogue
	await await_idle_frame()
	var answers: Label = box.get_node(^"Panel/Lines/Options")
	var count: int = box.shown_options().size()
	assert_int(count).override_failure_message("ten dishes known from the start (Marsh Stew since Willowmere, the three of eggs and milk since the Homestead's phase 4), and leaving").is_equal(11)
	for notch: int in 5:
		box._unhandled_input(_wheel(MOUSE_BUTTON_WHEEL_DOWN))
	assert_int(box.selected).is_equal(5)
	assert_int(box.top).is_equal(2)
	box._unhandled_input(_move(answers, 0))
	assert_int(box.selected).override_failure_message("the first answer showing is the third dish").is_equal(2)
	box._unhandled_input(_wheel(MOUSE_BUTTON_WHEEL_UP))
	assert_int(box.selected).is_equal(1)


func test_the_ending_follows_the_pointer() -> void:
	GameState.update_player(&"crypt", Vector2i(22, 13))
	var screen: EndingScreen = _screen(ENDING)
	var list: Label = screen.get_node(^"Menu/List")
	var travelled: Array[String] = []
	screen.travel = func(path: String) -> void: travelled.append(path)
	screen._unhandled_input(_move(list, 1))
	assert_array(Array(screen.shown_lines())).is_equal(["  Keep exploring", "> Save and go to the title"])
	screen._unhandled_input(_click(list, 1))
	assert_array(travelled).is_equal([EndingScreen.TITLE_SCENE])
	assert_bool(SaveSystem.has_save()).override_failure_message("saved first").is_true()


func test_in_play_the_pointer_is_nothing_and_a_click_is_a_button() -> void:
	GameState.add_item(&"wooden_sword")
	var village: AreaController = _load(VILLAGE)
	village.player.motor.place(Vector2i(23, 20))
	var before: Vector2i = village.player.motor.cell
	var moved: InputEventMouseMotion = InputEventMouseMotion.new()
	moved.position = Vector2(300.0, 40.0)
	village._unhandled_input(moved)
	assert_that(village.player.motor.cell).is_equal(before)
	assert_bool(village.is_talking() or village.is_in_menu() or village.is_paused()).is_false()
	# A left click anywhere swings the sword, as before.
	village._unhandled_input(_click_at(Vector2(600.0, 300.0)))
	assert_bool(village.player.motor.is_attacking()).is_true()


## The mouse moving onto line `line` of `label`.
func _move(label: Label, line: int) -> InputEventMouseMotion:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.position = _point(label, line)
	event.global_position = event.position
	return event


## A click on line `line` of `label`.
func _click(label: Label, line: int, button: MouseButton = MOUSE_BUTTON_LEFT) -> InputEventMouseButton:
	return _click_at(_point(label, line), button)


func _click_at(at: Vector2, button: MouseButton = MOUSE_BUTTON_LEFT) -> InputEventMouseButton:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = button
	event.pressed = true
	event.position = at
	event.global_position = at
	return event


## The wheel rolled a notch.
func _wheel(button: MouseButton) -> InputEventMouseButton:
	return _click_at(NOWHERE, button)


## A point on the screen in the middle of line `line` of `label`, a little in from its left.
func _point(label: Label, line: int) -> Vector2:
	return label.get_global_transform_with_canvas() * Vector2(4.0, MenuInput.line_height(label) * (float(line) + 0.5))


## A point on the name of Tilda's list number `part` (0: Buy, 1: Sell).
func _tab_point(counter: ShopMenu, tabs: Label, part: int) -> Vector2:
	var x: float = 2.0
	var names: PackedStringArray = counter.tab_parts()
	for i: int in part:
		x += MenuInput.width_of(tabs, names[i]) + MenuInput.width_of(tabs, ShopMenu.TAB_GAP)
	return tabs.get_global_transform_with_canvas() * Vector2(x, MenuInput.line_height(tabs) * 0.5)


func _action(action: StringName) -> InputEventAction:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = true
	return event


func _screen(path: String) -> Control:
	if is_instance_valid(_area):
		_area.free()
	var screen: Control = (load(path) as PackedScene).instantiate()
	get_tree().root.add_child(screen)
	_area = screen
	return screen


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area


func _on_sound(id: StringName) -> void:
	_heard.append(id)
