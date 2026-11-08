extends GdUnitTestSuite
## The input map in project.godot: every action works from the keyboard (physical keys,
## so any layout) and from a gamepad, and actions from the old design are gone.

const ACTIONS: Array[StringName] = [&"move_left", &"move_right", &"move_up", &"move_down", &"interact", &"attack", &"sprint", &"use_item", &"item_menu"]
const RETIRED: Array[StringName] = [&"debug_cycle_water"]


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
		assert_bool(has_key and has_pad).override_failure_message("%s: key=%s pad=%s" % [action, has_key, has_pad]).is_true()


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


func _physical_keys(action: StringName) -> Array:
	var keys: Array = []
	for event: InputEvent in InputMap.action_get_events(action):
		if event is InputEventKey:
			keys.append((event as InputEventKey).physical_keycode)
	return keys
