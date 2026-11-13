extends GdUnitTestSuite
## The input map in project.godot: every action works from the keyboard (physical keys,
## so any layout) and from a gamepad, but interact, which is the left mouse button (the user's
## request, 2026-11-13); and actions from the old design are gone.

const ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"move_up", &"move_down", &"interact", &"attack", &"sprint", &"use_item", &"item_menu", &"pause"]
const RETIRED: Array[StringName] = [&"debug_cycle_water"]


## The one action that isn't on a key.
const ON_THE_MOUSE: StringName = &"interact"


func test_every_action_has_a_physical_key_and_a_gamepad_binding() -> void:
	for action: StringName in ACTIONS:
		assert_bool(InputMap.has_action(action)).override_failure_message("missing action %s" % action).is_true()
		var has_key: bool = false
		var has_pad: bool = false
		for event: InputEvent in InputMap.action_get_events(action):
			if event is InputEventKey and (event as InputEventKey).physical_keycode != KEY_NONE:
				has_key = true
			if event is InputEventJoypadButton or event is InputEventJoypadMotion:
				has_pad = true
		assert_bool(has_key != (action == ON_THE_MOUSE) and has_pad).override_failure_message("%s: key=%s pad=%s" % [action, has_key, has_pad]).is_true()


func test_the_left_mouse_button_interacts_and_no_key_does() -> void:
	var buttons: Array = []
	for event: InputEvent in InputMap.action_get_events(&"interact"):
		assert_bool(event is InputEventKey).override_failure_message("no key interacts").is_false()
		if event is InputEventMouseButton:
			buttons.append((event as InputEventMouseButton).button_index)
	assert_array(buttons).contains_exactly([MOUSE_BUTTON_LEFT])
	assert_array(_physical_keys(&"interact")).is_empty()
	# A click is interact; the other mouse buttons and the old key are not.
	assert_bool(_mouse(MOUSE_BUTTON_LEFT, true).is_action_pressed(&"interact")).is_true()
	assert_bool(_mouse(MOUSE_BUTTON_LEFT, false).is_action_pressed(&"interact")).override_failure_message("letting go isn't a second press").is_false()
	assert_bool(_mouse(MOUSE_BUTTON_RIGHT, true).is_action_pressed(&"interact")).is_false()
	assert_bool(_mouse(MOUSE_BUTTON_WHEEL_UP, true).is_action_pressed(&"interact")).is_false()
	var key: InputEventKey = InputEventKey.new()
	key.physical_keycode = KEY_E
	key.pressed = true
	assert_bool(key.is_action_pressed(&"interact")).override_failure_message("E no longer interacts").is_false()
	# No other action is on the mouse: moving, the sword and the item stay on the keys.
	for action: StringName in ACTIONS:
		if action == ON_THE_MOUSE:
			continue
		for event: InputEvent in InputMap.action_get_events(action):
			assert_bool(event is InputEventMouseButton).override_failure_message("%s is not on the mouse" % action).is_false()


func test_retired_actions_are_gone() -> void:
	for action: StringName in RETIRED:
		assert_bool(InputMap.has_action(action)).override_failure_message("%s should be gone" % action).is_false()


func test_wasd_and_the_left_stick_move() -> void:
	assert_array(_physical_keys(&"move_up")).contains(KEY_W, KEY_UP)
	assert_array(_physical_keys(&"move_left")).contains(KEY_A, KEY_LEFT)
	assert_array(_physical_keys(&"move_down")).contains(KEY_S, KEY_DOWN)
	assert_array(_physical_keys(&"move_right")).contains(KEY_D, KEY_RIGHT)
	var stick: InputEventJoypadMotion = null
	for event: InputEvent in InputMap.action_get_events(&"move_right"):
		if event is InputEventJoypadMotion:
			stick = event
	assert_object(stick).is_not_null()
	assert_int(stick.axis).is_equal(JOY_AXIS_LEFT_X)
	assert_float(stick.axis_value).is_equal(1.0)


func test_shift_sprints() -> void:
	assert_array(_physical_keys(&"sprint")).contains(KEY_SHIFT)


func test_space_or_j_swings_the_sword() -> void:
	assert_array(_physical_keys(&"attack")).contains(KEY_SPACE, KEY_J)


func _mouse(button: MouseButton, pressed: bool) -> InputEventMouseButton:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = button
	event.pressed = pressed
	return event


func _physical_keys(action: StringName) -> Array:
	var keys: Array = []
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey:
			keys.append((event as InputEventKey).physical_keycode)
	return keys
