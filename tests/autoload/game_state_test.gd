extends GdUnitTestSuite
## GameState: hearts, flags, inventory, the player's position, and a JSON round trip.

const GameStateScript: GDScript = preload("res://autoload/game_state.gd")

var _state: Node


func before_test() -> void:
	_state = auto_free(GameStateScript.new())


# --- Hearts ----------------------------------------------------------------

func test_a_new_game_starts_with_three_full_hearts() -> void:
	assert_bool(_state.is_started()).is_false()
	_state.new_game()
	assert_bool(_state.is_started()).is_true()
	assert_int(_state.hearts_max).is_equal(3)
	assert_int(_state.health).is_equal(6)
	assert_int(_state.max_health()).is_equal(6)


func test_damage_and_healing_stay_within_the_hearts() -> void:
	_state.new_game()
	_state.damage(1)
	assert_int(_state.health).is_equal(5)
	_state.heal(10)
	assert_int(_state.health).is_equal(6)
	_state.damage(99)
	assert_int(_state.health).is_equal(0)
	assert_bool(_state.is_dead()).is_true()


func test_a_heart_container_adds_a_heart_and_refills() -> void:
	_state.new_game()
	_state.damage(3)
	_state.add_heart_container()
	assert_int(_state.hearts_max).is_equal(4)
	assert_int(_state.health).is_equal(8)


func test_health_changes_are_announced_once() -> void:
	_state.new_game()
	var announced: Array = []
	var on_health: Callable = func(current: int, maximum: int) -> void: announced.append([current, maximum])
	EventBus.health_changed.connect(on_health)
	_state.damage(1)
	_state.heal(0)
	_state.heal(5)
	_state.heal(5)
	EventBus.health_changed.disconnect(on_health)
	assert_array(announced).is_equal([[5, 6], [6, 6]])


# --- Everything else -------------------------------------------------------

func test_missing_flag_reads_as_false() -> void:
	assert_bool(_state.get_flag(&"never_set")).is_false()


func test_flag_changes_are_announced_once() -> void:
	var received: Array = []
	var on_flag: Callable = func(flag: StringName, value: Variant) -> void: received.append([flag, value])
	EventBus.flag_set.connect(on_flag)
	_state.set_flag(&"door_open", true)
	_state.set_flag(&"door_open", true)
	EventBus.flag_set.disconnect(on_flag)
	assert_array(received).is_equal([[&"door_open", true]])


func test_removing_more_than_held_empties_the_stack() -> void:
	_state.add_item(&"coin", 10)
	_state.add_item(&"coin", -25)
	assert_int(_state.item_count(&"coin")).is_equal(0)
	assert_array(_state.inventory).is_empty()


func test_the_heros_position_is_recorded_for_saving() -> void:
	_state.update_player(&"village", Vector2i(8, 9))
	assert_dict(_state.to_dict()["player"]).is_equal({"area": "village", "cell": [8, 9]})


func test_going_through_a_door_records_the_entry_until_the_area_places_the_hero() -> void:
	_state.update_player(&"village", Vector2i(30, 15))
	_state.go_to(&"elder_house", &"door")
	assert_dict(_state.to_dict()["player"]).is_equal({"area": "elder_house", "entry": "door"})
	var restored: Node = auto_free(GameStateScript.new())
	restored.from_dict(JSON.parse_string(JSON.stringify(_state.to_dict())))
	assert_dict(restored.player).override_failure_message("a save taken mid-door keeps the entry").is_equal({"area": "elder_house", "entry": "door"})
	_state.update_player(&"elder_house", Vector2i(5, 7))
	assert_dict(_state.to_dict()["player"]).is_equal({"area": "elder_house", "cell": [5, 7]})


func test_state_survives_a_json_round_trip() -> void:
	_state.new_game()
	_state.damage(3)
	_state.set_flag(&"talked_to_elder", true)
	_state.set_quest_stage(&"lost_key", &"find_key")
	_state.add_item(&"coin", 20)
	_state.update_player(&"village", Vector2i(12, 8))

	var first_save: String = JSON.stringify(_state.to_dict(), "", true)
	var restored: Node = auto_free(GameStateScript.new())
	restored.from_dict(JSON.parse_string(first_save))
	var second_save: String = JSON.stringify(restored.to_dict(), "", true)

	assert_str(second_save).is_equal(first_save)
	assert_int(restored.health).is_equal(3)
	assert_int(restored.hearts_max).is_equal(3)
	assert_that(restored.get_quest_stage(&"lost_key")).is_equal(&"find_key")
	assert_int(restored.item_count(&"coin")).is_equal(20)
	assert_array(restored.player["cell"]).is_equal([12, 8])
