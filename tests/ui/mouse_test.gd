extends GdUnitTestSuite
## Interact on the mouse (the user's request, 2026-11-13): the hero is moved with the keys and
## talks, picks up and chooses with a click of the left button. The mouse is a button, not a
## pointer: nothing on any screen takes a click for itself, so a click anywhere reaches the
## game; and every screen names the click where it used to name E.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const VILLAGE: String = "res://world/areas/village/village.tscn"
const TITLE: String = "res://ui/title_screen.tscn"
const ENDING: String = "res://ui/ending_screen.tscn"
const TEST_SLOT: int = 981

var _area: Node


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	GameState.set_time(float(GameState.day_clock().in_day("12:00")))
	SaveSystem.current_slot = TEST_SLOT


func after_test() -> void:
	if is_instance_valid(_area):
		_area.free()
	_area = null
	if SaveSystem.has_slot(TEST_SLOT):
		DirAccess.remove_absolute(SaveSystem.slot_path(TEST_SLOT))
	SaveSystem.current_slot = SaveSystem.GAME_SLOT
	Audio.play_music(&"")
	GameState.clear()


func test_the_prompt_names_the_click() -> void:
	assert_str(MenuInput.INTERACT_KEY).is_equal("Click")
	assert_str(MenuInput.prompt("Open the door")).is_equal("[Click] Open the door")
	var village: AreaController = _load(VILLAGE)
	var oda: Talkable = Steps.stand_before(village, "FarmerOda")
	village._update_hud()
	assert_str(village.hud.prompt_text()).is_equal("[Click] %s" % oda.prompt())
	village.player.motor.place(Vector2i(23, 20))
	village._update_hud()
	assert_str(village.hud.prompt_text()).override_failure_message("nothing to do here, nothing said").is_equal("")


func test_a_click_is_a_menus_yes_and_an_answer() -> void:
	assert_bool(MenuInput.is_confirm(_click())).is_true()
	assert_bool(MenuInput.is_answer(_click())).is_true()
	assert_bool(MenuInput.is_confirm(_click(MOUSE_BUTTON_RIGHT))).override_failure_message("the right button is nothing").is_false()
	assert_bool(MenuInput.is_back(_click())).is_false()
	assert_bool(MenuInput.is_up(_click()) or MenuInput.is_down(_click())).is_false()
	var released: InputEventMouseButton = _click()
	released.pressed = false
	assert_bool(MenuInput.is_confirm(released)).override_failure_message("letting go isn't a second yes").is_false()


func test_a_click_talks_answers_and_chooses() -> void:
	GameState.add_item(&"bow")
	GameState.add_item(&"bread", 2)
	GameState.set_energy(40.0)
	var village: AreaController = _load(VILLAGE)
	Steps.stand_before(village, "FarmerOda")
	village._unhandled_input(_click())
	assert_bool(village.is_talking()).override_failure_message("a click starts the conversation").is_true()
	for i: int in 30:
		if not village.is_talking():
			break
		village.hud.dialogue._unhandled_input(_click())
	assert_bool(village.is_talking()).override_failure_message("clicks carry it to its end").is_false()
	# The item menu: a click chooses the line under the cursor.
	village.player.motor.place(Vector2i(23, 20))
	assert_bool(village.open_item_menu()).is_true()
	village.hud.item_menu.move_cursor(1)
	village.hud.item_menu._unhandled_input(_click())
	assert_bool(village.hud.item_menu.is_open()).is_false()
	assert_int(GameState.item_count(&"bread")).override_failure_message("he ate the bread he clicked on").is_equal(1)
	# With nothing before him a click does nothing.
	village._unhandled_input(_click())
	assert_bool(village.is_talking() or village.is_in_menu()).is_false()


func test_nothing_on_any_screen_takes_the_click_for_itself() -> void:
	var village: AreaController = _load(VILLAGE)
	var counted: int = _assert_ignores_mouse(village.hud, "the HUD")
	assert_int(counted).override_failure_message("the HUD, its menus and its boxes").is_greater(30)
	village.free()
	_area = null
	for path: String in [TITLE, ENDING]:
		var screen: Control = (load(path) as PackedScene).instantiate()
		get_tree().root.add_child(screen)
		_area = screen
		assert_int(_assert_ignores_mouse(screen, path)).is_greater(3)
		screen.free()
		_area = null
	# The helper itself: everything under a node, and the node.
	var box: Control = auto_free(Control.new())
	var inner: ColorRect = ColorRect.new()
	var label: Label = Label.new()
	box.add_child(inner)
	inner.add_child(label)
	assert_int(inner.mouse_filter).override_failure_message("a box takes clicks unless told not to").is_equal(Control.MOUSE_FILTER_STOP)
	MenuInput.let_clicks_through(box)
	for control: Control in [box, inner, label]:
		assert_int(control.mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)


func test_every_screen_names_the_click_and_none_names_e() -> void:
	var village: AreaController = _load(VILLAGE)
	var said: PackedStringArray = _words(village.hud)
	village.free()
	_area = null
	for path: String in [TITLE, ENDING]:
		var screen: Control = (load(path) as PackedScene).instantiate()
		get_tree().root.add_child(screen)
		said.append_array(_words(screen))
		screen.free()
	var named: int = 0
	for words: String in said:
		for old: String in ["[E]", "E: ", "E or Enter", " E "]:
			assert_bool(words.contains(old)).override_failure_message("'%s' still names E" % words).is_false()
		if words.contains("Click"):
			named += 1
	assert_int(named).override_failure_message("the HUD's keys, the answer mark, the item menu, the pause menu, the title, the ending").is_greater_equal(6)
	assert_bool("\n".join(said).contains("WASD: move")).override_failure_message("moving is as it was").is_true()
	assert_bool("\n".join(said).contains("Space: sword") and "\n".join(said).contains("Q: item")).override_failure_message("so are the sword and the item").is_true()


## Checks that no Control under `root` (or `root` itself) takes mouse input. Returns how many
## there were.
func _assert_ignores_mouse(root: Node, where: String) -> int:
	var count: int = 0
	if root is Control:
		count += 1
		assert_int((root as Control).mouse_filter).override_failure_message("%s: %s lets clicks through" % [where, root.name]).is_equal(Control.MOUSE_FILTER_IGNORE)
	for child: Node in root.get_children():
		count += _assert_ignores_mouse(child, where)
	return count


## The text of every label under `root`.
func _words(root: Node) -> PackedStringArray:
	var out: PackedStringArray = []
	if root is Label and not (root as Label).text.is_empty():
		out.append((root as Label).text)
	for child: Node in root.get_children():
		out.append_array(_words(child))
	return out


func _click(button: MouseButton = MOUSE_BUTTON_LEFT) -> InputEventMouseButton:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = button
	event.pressed = true
	return event


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area
