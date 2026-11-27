extends GdUnitTestSuite
## The screen that arranges the item bar (step B2 of the icons, axe and bar plan; the user's
## Q12): the pause menu's "Item bar" opens it; a click on a slot lifts what is in it, a click on
## another sets it down there (a swap, or into an empty slot); a click on no slot does nothing;
## the keys do the same; Esc, Tab or a right click puts a lifted thing back. Leaving keeps the
## arrangement, which the bar shows at once and the save keeps. Uses its own save slot.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const VILLAGE: String = "res://world/areas/village/village.tscn"
const TEST_SLOT: int = 941
## Open grass in Hearthvale, away from the plot and from water.
const GRASS: Vector2i = Vector2i(23, 20)
## Well away from every slot.
const NOWHERE: Vector2 = Vector2(3.0, 3.0)

var _area: Node
var _heard: Array[StringName] = []


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	GameState.set_time(float(GameState.day_clock().in_day("12:00")))
	SaveSystem.current_slot = TEST_SLOT
	GameState.set_flag(StoryGates.FIRST_CROP, true)
	Quests.refresh()
	for item: Array in [[&"wooden_sword", 1], [&"hoe", 1], [&"watering_can", 1], [&"bomb", 3]]:
		GameState.add_item(item[0], item[1])
	GameState.set_flag(&"took_wooden_sword", true)
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
	GameState.clear()


func test_the_pause_menu_has_seven_lines_and_item_bar_opens_the_screen() -> void:
	GameState.equip(&"watering_can")
	var village: AreaController = _load(VILLAGE)
	assert_bool(village.open_pause_menu()).is_true()
	var menu: PauseMenu = village.hud.pause_menu
	assert_array(Array(menu.shown_lines())).is_equal(["> Resume", "  Save", "  Quests", "  Friends", "  Item bar", "  Settings", "  Quit to title"])
	var minute: float = GameState.minute
	# A click on its line opens the screen in the pause panel's place.
	var list: Label = menu.get_node(^"Panel/List")
	menu._unhandled_input(_click_at(list.get_global_transform_with_canvas() * Vector2(4.0, MenuInput.line_height(list) * 4.5)))
	var screen: BarMenu = menu.bar_menu
	assert_bool(screen.is_open()).is_true()
	assert_bool(menu.get_node(^"Panel").visible).override_failure_message("the pause panel steps aside").is_false()
	assert_bool(get_tree().paused).override_failure_message("the game stays paused: the clock stands still").is_true()
	# Two rows of nine; the bar's things in its order; the cursor on the thing in hand.
	var ids: Array[StringName] = screen.shown_ids()
	assert_int(ids.size()).is_equal(18)
	assert_array(ids.slice(0, 5)).is_equal([&"wooden_sword", &"hoe", &"watering_can", &"bomb", &""])
	assert_int(screen.cursor.at).is_equal(2)
	assert_str(screen.shown_name()).is_equal("Watering Can")
	assert_str(screen.shown_help()).is_equal("Click: lift   Esc: back")
	# The box wears the frame, with its heading in the heading face, and fits the screen.
	var panel: PanelFrame = screen.get_node(^"Panel")
	assert_str((panel.get_node(^"Title") as Label).text).is_equal("Item bar")
	assert_that((panel.get_node(^"Title") as Label).theme_type_variation).is_equal(&"Heading")
	assert_bool(panel.size.y <= 360.0 - 8.0 and panel.size.x <= 640.0 - 8.0).is_true()
	# Esc goes back to the pause menu.
	screen._unhandled_input(_action(&"pause"))
	assert_bool(screen.is_open()).is_false()
	assert_bool(menu.is_open()).is_true()
	assert_bool(menu.get_node(^"Panel").visible).is_true()
	assert_float(GameState.minute).is_equal(minute)
	# Tab leaves too, and resuming from the pause menu closes it.
	menu.choose(PauseMenu.BAR)
	screen._unhandled_input(_action(&"item_menu"))
	assert_bool(screen.is_open()).is_false()
	menu.choose(PauseMenu.BAR)
	menu.resume()
	assert_bool(screen.is_open()).is_false()
	assert_bool(get_tree().paused).is_false()


func test_clicks_lift_and_set_down_swapping_or_into_an_empty_slot() -> void:
	var screen: BarMenu = _open_screen(_load(VILLAGE))
	# The pointer lights the slot under it.
	screen._unhandled_input(_move_to(screen.slot_point(1)))
	assert_int(screen.cursor.at).is_equal(1)
	assert_str(screen.shown_name()).is_equal("Hoe")
	# A click lifts the hoe.
	screen._unhandled_input(_click_at(screen.slot_point(1)))
	assert_that(screen.lifted_id()).is_equal(&"hoe")
	assert_str(screen.shown_help()).is_equal("Click: set down   %s" % MenuInput.prompt("Put back"))
	assert_bool(_heard.has(&"take_up")).is_true()
	screen._unhandled_input(_move_to(screen.slot_point(3)))
	assert_str(screen.shown_name()).is_equal("Hoe: swap with the Bombs")
	# A click on no slot does nothing: the hoe is still lifted.
	screen._unhandled_input(_click_at(NOWHERE))
	assert_that(screen.lifted_id()).is_equal(&"hoe")
	# A click on the bombs: the two swap, at once.
	screen._unhandled_input(_click_at(screen.slot_point(3)))
	assert_that(screen.lifted_id()).is_equal(&"")
	assert_array(screen.shown_ids().slice(0, 4)).is_equal([&"wooden_sword", &"bomb", &"watering_can", &"hoe"])
	assert_array(GameState.bar).is_equal([HandBar.SWORD, "bomb", "watering_can", "hoe"])
	assert_bool(_heard.has(&"set_down")).is_true()
	# The sword into an empty slot of the second row.
	screen._unhandled_input(_click_at(screen.slot_point(0)))
	screen._unhandled_input(_move_to(screen.slot_point(11)))
	assert_str(screen.shown_name()).is_equal("Wooden Sword: set it down here")
	screen._unhandled_input(_click_at(screen.slot_point(11)))
	assert_array(GameState.bar).is_equal(["", "bomb", "watering_can", "hoe", "", "", "", "", "", "", "", HandBar.SWORD])
	assert_that(screen.shown_ids()[11]).is_equal(&"wooden_sword")
	assert_that(screen.shown_ids()[0]).is_equal(&"")
	# A click on an empty slot with nothing lifted lifts nothing.
	screen._unhandled_input(_click_at(screen.slot_point(0)))
	assert_that(screen.lifted_id()).is_equal(&"")
	assert_str(screen.shown_name()).is_equal(BarMenu.EMPTY_WORDS)
	# A click on its own slot puts it back.
	screen._unhandled_input(_click_at(screen.slot_point(2)))
	screen._unhandled_input(_click_at(screen.slot_point(2)))
	assert_that(screen.lifted_id()).is_equal(&"")
	assert_array(GameState.bar).is_equal(["", "bomb", "watering_can", "hoe", "", "", "", "", "", "", "", HandBar.SWORD])


func test_the_keys_step_lift_and_set_down_and_esc_or_a_right_click_puts_back() -> void:
	GameState.equip(&"")
	var village: AreaController = _load(VILLAGE)
	var screen: BarMenu = _open_screen(village)
	assert_int(screen.cursor.at).override_failure_message("the sword in hand").is_equal(0)
	screen._unhandled_input(_action(&"move_right"))
	screen._unhandled_input(_action(&"move_right"))
	assert_int(screen.cursor.at).is_equal(2)
	screen._unhandled_input(_wheel(MOUSE_BUTTON_WHEEL_UP))
	assert_int(screen.cursor.at).override_failure_message("the wheel steps a slot").is_equal(1)
	screen._unhandled_input(_wheel(MOUSE_BUTTON_WHEEL_DOWN))
	assert_int(screen.cursor.at).is_equal(2)
	# Enter lifts the can; down a row and Enter sets it down there.
	screen._unhandled_input(_key(KEY_ENTER))
	assert_that(screen.lifted_id()).is_equal(&"watering_can")
	screen._unhandled_input(_action(&"move_down"))
	assert_int(screen.cursor.at).is_equal(11)
	screen._unhandled_input(_key(KEY_ENTER))
	assert_array(GameState.bar).is_equal([HandBar.SWORD, "hoe", "", "bomb", "", "", "", "", "", "", "", "watering_can"])
	# Lifted and carried off, Esc puts it back: nothing moved, and the screen stays.
	screen._unhandled_input(_action(&"move_up"))
	screen._unhandled_input(_action(&"move_left"))
	assert_int(screen.cursor.at).is_equal(1)
	screen._unhandled_input(_key(KEY_ENTER))
	assert_that(screen.lifted_id()).is_equal(&"hoe")
	screen._unhandled_input(_action(&"move_right"))
	screen._unhandled_input(_action(&"pause"))
	assert_that(screen.lifted_id()).is_equal(&"")
	assert_bool(screen.is_open()).override_failure_message("Esc only put it back").is_true()
	assert_array(GameState.bar).is_equal([HandBar.SWORD, "hoe", "", "bomb", "", "", "", "", "", "", "", "watering_can"])
	# A right click puts back too.
	screen._unhandled_input(_click_at(screen.slot_point(3)))
	assert_that(screen.lifted_id()).is_equal(&"bomb")
	screen._unhandled_input(_click_at(screen.slot_point(4), MOUSE_BUTTON_RIGHT))
	assert_that(screen.lifted_id()).is_equal(&"")
	assert_bool(screen.is_open()).is_true()
	# With nothing lifted, Esc leaves.
	screen._unhandled_input(_action(&"pause"))
	assert_bool(screen.is_open()).is_false()


func test_leaving_keeps_the_arrangement_the_bar_shows_it_and_the_save_keeps_it() -> void:
	GameState.equip(&"hoe")
	var village: AreaController = _load(VILLAGE)
	village.player.motor.place(GRASS)
	village._update_hud()
	var bar: ItemBar = village.hud.item_bar
	assert_array(bar.shown_ids()).is_equal([&"wooden_sword", &"hoe", &"watering_can", &"bomb"])
	var screen: BarMenu = _open_screen(village)
	# The hoe to the end, past an empty slot; the bombs to the front.
	screen.choose(1)
	screen.choose(5)
	screen.choose(3)
	screen.choose(0)
	assert_array(GameState.bar).is_equal(["bomb", "", "watering_can", HandBar.SWORD, "", "hoe"])
	screen._unhandled_input(_action(&"pause"))
	village.hud.pause_menu.resume()
	village._update_hud()
	assert_array(bar.shown_ids()).override_failure_message("the bar shows it at once").is_equal([&"bomb", &"", &"watering_can", &"wooden_sword", &"", &"hoe"])
	assert_that(GameState.equipped).override_failure_message("what was in hand stays in hand").is_equal(&"hoe")
	assert_int(bar.lit_slot()).is_equal(5)
	assert_array(Array(bar.shown_counts())).is_equal(["3", "", "0", "", "", ""])
	# The wheel steps the bar in its new order, over the empty slots.
	assert_bool(GameState.step_hand(1)).is_true()
	assert_that(GameState.equipped).override_failure_message("round from the end to the bombs").is_equal(&"bomb")
	# Saved and loaded, still version 6.
	assert_int(SaveSystem.save_game()).is_equal(OK)
	assert_int(int(GameState.to_dict()["version"])).is_equal(6)
	GameState.clear()
	assert_int(SaveSystem.load_game()).is_equal(OK)
	assert_array(GameState.bar).is_equal(["bomb", "", "watering_can", HandBar.SWORD, "", "hoe"])


func test_a_bar_of_more_than_eighteen_columns_shows_a_third_row() -> void:
	# Things for the hand far along the bar: the columns past eighteen get a row of their own.
	GameState.bar.assign([HandBar.SWORD, "hoe", "watering_can", "bomb"])
	assert_bool(GameState.move_on_bar(1, 20)).is_true()
	var screen: BarMenu = _open_screen(_load(VILLAGE))
	assert_int(screen.shown_ids().size()).is_equal(27)
	assert_that(screen.shown_ids()[20]).is_equal(&"hoe")
	screen._unhandled_input(_click_at(screen.slot_point(20)))
	screen._unhandled_input(_click_at(screen.slot_point(1)))
	assert_int(screen.shown_ids().size()).override_failure_message("back to two rows").is_equal(18)
	assert_array(GameState.bar).is_equal([HandBar.SWORD, "hoe", "watering_can", "bomb"])


## Opens the pause menu and, from it, the screen.
func _open_screen(village: AreaController) -> BarMenu:
	assert_bool(village.open_pause_menu()).is_true()
	village.hud.pause_menu.choose(PauseMenu.BAR)
	var screen: BarMenu = village.hud.pause_menu.bar_menu
	assert_bool(screen.is_open()).is_true()
	return screen


func _move_to(at: Vector2) -> InputEventMouseMotion:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.position = at
	event.global_position = at
	return event


func _click_at(at: Vector2, button: MouseButton = MOUSE_BUTTON_LEFT) -> InputEventMouseButton:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = button
	event.pressed = true
	event.position = at
	event.global_position = at
	return event


func _wheel(button: MouseButton) -> InputEventMouseButton:
	return _click_at(NOWHERE, button)


func _action(action: StringName) -> InputEventAction:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = true
	return event


func _key(code: Key) -> InputEventKey:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	return event


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area


func _on_sound(id: StringName) -> void:
	_heard.append(id)
