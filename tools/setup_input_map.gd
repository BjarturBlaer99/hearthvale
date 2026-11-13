extends SceneTree
## Writes Hearthvale's input actions (and pixel snapping) into project.godot, and removes
## actions the game no longer has. Re-run after changing an action:
##   godot --headless --path . -s res://tools/setup_input_map.gd
## Keys are physical, so WASD sits in the same place on any keyboard layout.
## Gamepad events apply to every connected device.
## Interact is the left mouse button (the user's request, 2026-11-13): the hero is moved with the
## keys and talks, picks up and chooses with a click. It is a button, not a pointer: where the
## click lands doesn't matter.

const DEADZONE: float = 0.25
## Actions from earlier designs, cleared if present.
const RETIRED: Array[String] = ["debug_cycle_water"]


func _initialize() -> void:
	_action("move_left", [_key(KEY_A), _key(KEY_LEFT), _axis(JOY_AXIS_LEFT_X, -1.0), _button(JOY_BUTTON_DPAD_LEFT)])
	_action("move_right", [_key(KEY_D), _key(KEY_RIGHT), _axis(JOY_AXIS_LEFT_X, 1.0), _button(JOY_BUTTON_DPAD_RIGHT)])
	_action("move_up", [_key(KEY_W), _key(KEY_UP), _axis(JOY_AXIS_LEFT_Y, -1.0), _button(JOY_BUTTON_DPAD_UP)])
	_action("move_down", [_key(KEY_S), _key(KEY_DOWN), _axis(JOY_AXIS_LEFT_Y, 1.0), _button(JOY_BUTTON_DPAD_DOWN)])
	_action("interact", [_mouse(MOUSE_BUTTON_LEFT), _button(JOY_BUTTON_A)])
	_action("attack", [_key(KEY_SPACE), _key(KEY_J), _button(JOY_BUTTON_X)])
	_action("sprint", [_key(KEY_SHIFT), _button(JOY_BUTTON_B)])
	_action("use_item", [_key(KEY_Q), _key(KEY_K), _button(JOY_BUTTON_Y)])
	_action("item_menu", [_key(KEY_TAB), _key(KEY_I), _button(JOY_BUTTON_BACK)])
	_action("pause", [_key(KEY_ESCAPE), _key(KEY_P), _button(JOY_BUTTON_START)])
	for action_name: String in RETIRED:
		if ProjectSettings.has_setting("input/" + action_name):
			ProjectSettings.clear("input/" + action_name)
	# Crisp pixel art: no sub-pixel jitter when the camera follows the hero.
	ProjectSettings.set_setting("rendering/2d/snap/snap_2d_transforms_to_pixel", true)
	var error: Error = ProjectSettings.save()
	print("tools/setup_input_map: project.godot saved (%s)" % error_string(error))
	quit(0 if error == OK else 1)


func _action(action_name: String, events: Array) -> void:
	ProjectSettings.set_setting("input/" + action_name, {"deadzone": DEADZONE, "events": events})


func _key(physical: Key) -> InputEventKey:
	var event: InputEventKey = InputEventKey.new()
	event.device = -1
	event.physical_keycode = physical
	return event


func _mouse(button: MouseButton) -> InputEventMouseButton:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.device = -1
	event.button_index = button
	return event


func _axis(axis: JoyAxis, value: float) -> InputEventJoypadMotion:
	var event: InputEventJoypadMotion = InputEventJoypadMotion.new()
	event.device = -1
	event.axis = axis
	event.axis_value = value
	return event


func _button(button: JoyButton) -> InputEventJoypadButton:
	var event: InputEventJoypadButton = InputEventJoypadButton.new()
	event.device = -1
	event.button_index = button
	return event
