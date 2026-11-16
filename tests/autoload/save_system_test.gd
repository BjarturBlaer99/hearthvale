extends GdUnitTestSuite
## SaveSystem: a slot written from GameState loads back into identical state.
## Uses the real autoloads and a slot number no player will use; cleans up after itself.

const TEST_SLOT: int = 990


func after_test() -> void:
	GameState.clear()
	SaveSystem.current_slot = SaveSystem.GAME_SLOT
	SaveSystem.erase_slot(TEST_SLOT)


func test_slot_round_trip_keeps_hearts_items_and_place() -> void:
	GameState.new_game()
	GameState.damage(2)
	GameState.add_item(&"small_key", 1)
	GameState.update_player(&"village", Vector2i(20, 18))
	var before: String = JSON.stringify(GameState.to_dict(), "", true)

	assert_int(SaveSystem.save_to_slot(TEST_SLOT)).is_equal(OK)
	GameState.new_game()
	assert_int(SaveSystem.load_from_slot(TEST_SLOT)).is_equal(OK)

	assert_str(JSON.stringify(GameState.to_dict(), "", true)).is_equal(before)
	assert_int(GameState.health).is_equal(4)


func test_the_equipped_item_survives_a_save_slot() -> void:
	GameState.new_game()
	GameState.add_item(&"bow")
	GameState.add_item(&"bomb", 2)
	GameState.equip(&"bomb")
	assert_int(SaveSystem.save_to_slot(TEST_SLOT)).is_equal(OK)
	GameState.new_game()
	assert_int(SaveSystem.load_from_slot(TEST_SLOT)).is_equal(OK)
	assert_that(GameState.equipped).is_equal(&"bomb")
	assert_int(GameState.item_count(&"bomb")).is_equal(2)


func test_missing_slot_is_not_found() -> void:
	assert_int(SaveSystem.load_from_slot(TEST_SLOT)).is_equal(ERR_FILE_NOT_FOUND)


func test_saves_carry_a_version() -> void:
	assert_int(SaveSystem.save_to_slot(TEST_SLOT)).is_equal(OK)
	var data: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SaveSystem.slot_path(TEST_SLOT)))
	assert_int(int(data["version"])).is_equal(GameState.SAVE_VERSION)


func test_the_menus_slot_saves_loads_and_sums_up_without_loading() -> void:
	SaveSystem.current_slot = TEST_SLOT
	assert_bool(SaveSystem.has_save()).is_false()
	assert_dict(SaveSystem.summary()).override_failure_message("no save, nothing to sum up").is_empty()
	GameState.new_game()
	GameState.add_heart_container()
	GameState.add_play_time(754.0)
	GameState.update_player(&"old_wood", Vector2i(18, 10))
	assert_int(SaveSystem.save_game()).is_equal(OK)
	assert_bool(SaveSystem.has_slot(TEST_SLOT)).is_true()
	GameState.new_game()
	assert_dict(SaveSystem.summary()).is_equal({"area": "old_wood", "play_time": 754.0, "hearts_max": 4, "finished": false})
	assert_int(GameState.hearts_max).override_failure_message("summing up doesn't load").is_equal(3)
	assert_int(SaveSystem.load_game()).is_equal(OK)
	assert_int(GameState.hearts_max).is_equal(4)
	assert_float(GameState.play_time).is_equal(754.0)


func test_the_summary_says_whether_the_game_was_finished() -> void:
	SaveSystem.current_slot = TEST_SLOT
	GameState.new_game()
	assert_int(SaveSystem.save_game()).is_equal(OK)
	assert_bool(SaveSystem.summary()["finished"]).is_false()
	GameState.set_flag(EndingSummary.FINISHED_FLAG, true)
	assert_bool(SaveSystem.summary()["finished"]).override_failure_message("it's the save that counts, and it isn't saved yet").is_false()
	assert_int(SaveSystem.save_game()).is_equal(OK)
	assert_bool(SaveSystem.summary()["finished"]).is_true()
