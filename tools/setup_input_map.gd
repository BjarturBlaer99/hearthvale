extends SceneTree
## Writes Low Tide's input actions (and pixel snapping) into project.godot.
## Re-run after changing an action:
##   godot --headless --path . -s res://tools/setup_input_map.gd
## Keys are physical, so WASD sits in the same place on any keyboard layout.
## Gamepad events apply to every connected device.

const DEADZONE: float = 0.25


func _initialize() -> void:
	_action("move_left", [_key(KEY_A), _key(KEY_LEFT), _axis(JOY_AXIS_LEFT_X, -1.0), _button(JOY_BUTTON_DPAD_LEFT)])
	_action("move_right", [_key(KEY_D), _key(KEY_RIGHT), _axis(JOY_AXIS_LEFT_X, 1.0), _button(JOY_BUTTON_DPAD_RIGHT)])
	_action("move_up", [_key(KEY_W), _key(KEY_UP), _axis(JOY_AXIS_LEFT_Y, -1.0), _button(JOY_BUTTON_DPAD_UP)])
	_action("move_down", [_key(KEY_S), _key(KEY_DOWN), _axis(JOY_AXIS_LEFT_Y, 1.0), _button(JOY_BUTTON_DPAD_DOWN)])
	_action("sprint", [_key(KEY_SHIFT), _button(JOY_BUTTON_LEFT_SHOULDER), _button(JOY_BUTTON_LEFT_STICK)])
	_action("interact", [_key(KEY_E), _button(JOY_BUTTON_A)])
	_action("debug_cycle_water", [_key(KEY_F2), _button(JOY_BUTTON_BACK)])
	# Crisp pixel art: no sub-pixel jitter when the camera follows the player.
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
