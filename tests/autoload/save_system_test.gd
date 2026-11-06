extends GdUnitTestSuite
## SaveSystem: a slot written from GameState loads back into identical state.
## Uses the real autoloads and a slot number no player will use; cleans up after itself.

const TEST_SLOT: int = 990


func after_test() -> void:
	GameState.clear()
	if SaveSystem.has_slot(TEST_SLOT):
		DirAccess.remove_absolute(SaveSystem.slot_path(TEST_SLOT))


func test_slot_round_trip() -> void:
	GameState.clear()
	GameState.set_water_level(&"st_aud", &"drained")
	GameState.set_reputation(&"summit_holds", -20)
	GameState.add_item(&"pump_valve", 1)
	var before: Dictionary = GameState.to_dict()

	assert_int(SaveSystem.save_to_slot(TEST_SLOT)).is_equal(OK)
	GameState.clear()
	assert_int(SaveSystem.load_from_slot(TEST_SLOT)).is_equal(OK)

	assert_str(JSON.stringify(GameState.to_dict(), "", true)).is_equal(JSON.stringify(before, "", true))


func test_water_state_survives_a_save_and_load() -> void:
	GameState.new_game()
	GameState.network_nodes[&"third_outlet"] = WaterNetwork.STATE_REPAIRED
	var solver: WaterSolver = WaterSolver.new()
	var drained_once: bool = GameState.apply_water_change(solver.preview(GameState.water_network(), &"third_outlet", WaterSolver.LOWER))
	assert_bool(drained_once).is_true()
	var saved: String = JSON.stringify(GameState.water_network().get_state(), "", true)

	assert_int(SaveSystem.save_to_slot(TEST_SLOT)).is_equal(OK)
	GameState.new_game()
	assert_that(GameState.get_water_level(&"st_aud")).is_equal(&"flooded")
	assert_int(SaveSystem.load_from_slot(TEST_SLOT)).is_equal(OK)

	assert_str(JSON.stringify(GameState.water_network().get_state(), "", true)).is_equal(saved)
	assert_that(GameState.get_water_level(&"st_aud")).is_equal(&"waist")
	assert_int(GameState.basins[&"old_reservoir"]).is_equal(50)
	# The loaded state is live: the outlet is still repaired and can drain the last step.
	var next: WaterChangeResult = solver.preview(GameState.water_network(), &"third_outlet", WaterSolver.LOWER)
	assert_str(next.rejected_reason).is_empty()


func test_missing_slot_is_not_found() -> void:
	assert_int(SaveSystem.load_from_slot(TEST_SLOT)).is_equal(ERR_FILE_NOT_FOUND)


func test_saves_carry_a_version() -> void:
	assert_int(SaveSystem.save_to_slot(TEST_SLOT)).is_equal(OK)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SaveSystem.slot_path(TEST_SLOT)))
	assert_int(int(data["version"])).is_equal(GameState.SAVE_VERSION)
