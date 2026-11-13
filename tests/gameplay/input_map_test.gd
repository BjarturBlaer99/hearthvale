extends GdUnitTestSuite
## The input map in project.godot: every action works from the keyboard (physical keys,
## so any layout) and from a gamepad, but the two on the mouse (the user's requests,
## 2026-11-13): the left button uses what is in hand, the right button interacts. Actions from
## the old design are gone.

const ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"move_up", &"move_down", &"interact", &"use_hand", &"attack", &"sprint", &"use_item", &"item_menu", &"pause"]
const RETIRED: Array[StringName] = [&"debug_cycle_water"]


## The actions that are on the mouse and on no key, each with its button.
const ON_THE_MOUSE: Dictionary = {&"interact": MOUSE_BUTTON_RIGHT, &"use_hand": MOUSE_BUTTON_LEFT}
## The one that a gamepad has no button of its own for: its X and Y do the sword and the item.
const MOUSE_ONLY: StringName = &"use_hand"


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
		assert_bool(has_key != ON_THE_MOUSE.has(action)).override_failure_message("%s: key=%s" % [action, has_key]).is_true()
		assert_bool(has_pad != (action == MOUSE_ONLY)).override_failure_message("%s: pad=%s" % [action, has_pad]).is_true()


func test_the_left_button_uses_the_hand_and_the_right_button_interacts() -> void:
	for action: StringName in ON_THE_MOUSE:
		var buttons: Array = []
		for event: InputEvent in InputMap.action_get_events(action):
			assert_bool(event is InputEventKey).override_failure_message("no key does %s" % action).is_false()
			if event is InputEventMouseButton:
				buttons.append((event as InputEventMouseButton).button_index)
		assert_array(buttons).override_failure_message(String(action)).contains_exactly([ON_THE_MOUSE[action]])
		assert_array(_physical_keys(action)).is_empty()
	# Each click is its own action and not the other's.
	assert_bool(_mouse(MOUSE_BUTTON_LEFT, true).is_action_pressed(&"use_hand")).is_true()
	assert_bool(_mouse(MOUSE_BUTTON_LEFT, true).is_action_pressed(&"interact")).is_false()
	assert_bool(_mouse(MOUSE_BUTTON_RIGHT, true).is_action_pressed(&"interact")).is_true()
	assert_bool(_mouse(MOUSE_BUTTON_RIGHT, true).is_action_pressed(&"use_hand")).is_false()
	assert_bool(_mouse(MOUSE_BUTTON_LEFT, false).is_action_pressed(&"use_hand")).override_failure_message("letting go isn't a second press").is_false()
	for button: MouseButton in [MOUSE_BUTTON_MIDDLE, MOUSE_BUTTON_WHEEL_UP, MOUSE_BUTTON_WHEEL_DOWN]:
		assert_bool(_mouse(button, true).is_action_pressed(&"interact") or _mouse(button, true).is_action_pressed(&"use_hand")).is_false()
	var key: InputEventKey = InputEventKey.new()
	key.physical_keycode = KEY_E
	key.pressed = true
	assert_bool(key.is_action_pressed(&"interact") or key.is_action_pressed(&"use_hand")).override_failure_message("E does nothing").is_false()
	# No other action is on the mouse: moving stays on the keys, and the sword and the item
	# keep their own keys beside the left click.
	for action: StringName in ACTIONS:
		if ON_THE_MOUSE.has(action):
			continue
		for event: InputEvent in InputMap.action_get_events(action):
			assert_bool(event is InputEventMouseButton).override_failure_message("%s is not on the mouse" % action).is_false()
	assert_array(_physical_keys(&"use_item")).contains(KEY_Q)


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
