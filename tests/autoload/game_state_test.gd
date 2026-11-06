extends GdUnitTestSuite
## GameState: survives a JSON round trip, clamps reputation, keeps inventory counts sane,
## and announces changes on EventBus.

const GameStateScript: GDScript = preload("res://autoload/game_state.gd")

var _state: Node


func before_test() -> void:
	_state = auto_free(GameStateScript.new())


func test_state_survives_a_json_round_trip() -> void:
	_state.set_water_level(&"st_aud", &"waist")
	_state.basins[&"old_reservoir"] = 50
	_state.set_flag(&"talked_greenterrace_elder", true)
	_state.set_quest_stage(&"bitter_medicine", &"retrieve_medicine")
	_state.set_reputation(&"summit_holds", 35)
	_state.add_item(&"food_crate", 20)
	_state.player = {"district": "st_aud", "cell": [12, 8], "height": 2}

	var first_save: String = JSON.stringify(_state.to_dict(), "", true)
	var restored: Node = auto_free(GameStateScript.new())
	restored.from_dict(JSON.parse_string(first_save))
	var second_save: String = JSON.stringify(restored.to_dict(), "", true)

	assert_str(second_save).is_equal(first_save)
	assert_that(restored.get_water_level(&"st_aud")).is_equal(&"waist")
	assert_that(restored.get_quest_stage(&"bitter_medicine")).is_equal(&"retrieve_medicine")
	assert_int(restored.item_count(&"food_crate")).is_equal(20)
	assert_int(restored.player["height"]).is_equal(2)
	assert_bool(restored.get_flag(&"talked_greenterrace_elder")).is_true()


func test_missing_flag_reads_as_false() -> void:
	assert_bool(_state.get_flag(&"never_set")).is_false()


func test_reputation_is_clamped() -> void:
	_state.set_reputation(&"reclamation", 250)
	assert_int(_state.get_reputation(&"reclamation")).is_equal(100)
	_state.change_reputation(&"reclamation", -500)
	assert_int(_state.get_reputation(&"reclamation")).is_equal(-100)


func test_removing_more_than_held_empties_the_stack() -> void:
	_state.add_item(&"rivets", 10)
	_state.add_item(&"rivets", -25)
	assert_int(_state.item_count(&"rivets")).is_equal(0)
	assert_array(_state.inventory).is_empty()


func test_changes_are_announced_once_on_event_bus() -> void:
	var received: Array = []
	var on_flag: Callable = func(flag: StringName, value: Variant) -> void: received.append([flag, value])
	EventBus.flag_set.connect(on_flag)
	_state.set_flag(&"door_open", true)
	_state.set_flag(&"door_open", true) # unchanged, so no second signal
	EventBus.flag_set.disconnect(on_flag)
	assert_array(received).is_equal([[&"door_open", true]])
