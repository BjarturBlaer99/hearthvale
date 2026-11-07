extends GdUnitTestSuite
## GameState: survives a JSON round trip, clamps reputation, keeps inventory counts sane,
## and announces changes on EventBus.

const GameStateScript: GDScript = preload("res://autoload/game_state.gd")

var _state: Node


func before_test() -> void:
	_state = auto_free(GameStateScript.new())


func test_state_survives_a_json_round_trip() -> void:
	_state.set_water_level(&"st_aud", &"waist")
	_state.water_pending[&"greenterrace"] = 50
	_state.basins[&"old_reservoir"] = 50
	_state.network_nodes[&"third_outlet"] = WaterNetwork.STATE_REPAIRED
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
	assert_int(restored.water_pending[&"greenterrace"]).is_equal(50)
	assert_that(restored.network_nodes[&"third_outlet"]).is_equal(WaterNetwork.STATE_REPAIRED)


func test_new_game_starts_the_flood_network_from_data() -> void:
	_state.new_game()
	assert_that(_state.get_water_level(&"st_aud")).is_equal(&"flooded")
	assert_that(_state.get_water_level(&"greenterrace")).is_equal(&"dry")
	assert_int(_state.basins[&"old_reservoir"]).is_equal(0)
	assert_that(_state.network_nodes[&"st_aud_pump"]).is_equal(WaterNetwork.STATE_BROKEN)
	assert_int(_state.water_network().total_water()).is_equal(100)


func test_applied_water_changes_are_recorded_and_announced() -> void:
	_state.new_game()
	_state.network_nodes[&"st_aud_pump"] = WaterNetwork.STATE_REPAIRED
	var solver: WaterSolver = WaterSolver.new()
	var announced: Array = []
	var on_level: Callable = func(district_id: StringName, level: StringName) -> void: announced.append([district_id, level])
	EventBus.water_level_changed.connect(on_level)
	var first: WaterChangeResult = solver.preview(_state.water_network(), &"st_aud_pump", WaterSolver.LOWER)
	var first_applied: bool = _state.apply_water_change(first)
	var pending_after_first: int = _state.water_pending[&"greenterrace"]
	var second: WaterChangeResult = solver.preview(_state.water_network(), &"st_aud_pump", WaterSolver.LOWER)
	var second_applied: bool = _state.apply_water_change(second)
	var stale_applied: bool = _state.apply_water_change(first)
	EventBus.water_level_changed.disconnect(on_level)

	assert_bool(first_applied).is_true()
	assert_bool(second_applied).is_true()
	assert_bool(stale_applied).is_false()
	assert_int(pending_after_first).is_equal(50)
	# Water building up in Greenterrace changes no map, so only level changes are announced.
	assert_array(announced).is_equal([[&"st_aud", &"waist"], [&"st_aud", &"drained"], [&"greenterrace", &"flooded"]])
	assert_that(_state.get_water_level(&"greenterrace")).is_equal(&"flooded")
	assert_int(_state.water_pending[&"greenterrace"]).is_equal(0)


func test_setting_a_level_directly_clears_pending_water() -> void:
	_state.new_game()
	_state.water_pending[&"greenterrace"] = 50
	_state.set_water_level(&"greenterrace", &"flooded")
	assert_int(_state.water_pending[&"greenterrace"]).is_equal(0)
	assert_int(_state.water_network().get_district(&"greenterrace").pending).is_equal(0)


func test_the_players_position_is_recorded_for_saving() -> void:
	_state.update_player(&"st_aud", Vector2i(8, 9), 5, 72.5)
	assert_dict(_state.to_dict()["player"]).is_equal({"district": "st_aud", "cell": [8, 9], "height": 5, "stamina": 72.5, "on_boat": false})


func test_the_boat_is_recorded_with_or_without_a_cell() -> void:
	_state.set_boat(&"st_aud", Vector2i(1, 10), 0.5)
	assert_that(_state.boat_cell()).is_equal(Vector2i(1, 10))
	assert_dict(_state.to_dict()["boat"]).is_equal({"where": "st_aud", "cell": [1, 10], "heading": 0.5, "moored_at": ""})
	_state.set_boat(&"sea", GameState.NO_CELL, 0.0, &"greenterrace")
	assert_that(_state.boat_cell()).is_equal(GameState.NO_CELL)
	assert_that(str(_state.boat["moored_at"])).is_equal("greenterrace")


func test_setting_sail_marks_the_player_as_arriving_aboard() -> void:
	_state.update_player(&"st_aud", Vector2i(1, 9), 4, 100.0)
	_state.begin_voyage(&"sea", &"st_aud")
	assert_that(str(_state.player["district"])).is_equal("sea")
	assert_that(str(_state.player["came_from"])).is_equal("st_aud")
	assert_bool(_state.player["arriving"]).is_true()
	assert_bool(_state.player["on_boat"]).is_true()
	assert_bool(_state.player.has("cell")).is_false()


func test_rejected_water_changes_are_not_recorded() -> void:
	_state.new_game()
	var change: WaterChangeResult = WaterSolver.new().preview(_state.water_network(), &"st_aud_pump", WaterSolver.LOWER)
	assert_bool(change.is_rejected()).is_true()
	assert_bool(_state.apply_water_change(change)).is_false()
	assert_that(_state.get_water_level(&"st_aud")).is_equal(&"flooded")


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
