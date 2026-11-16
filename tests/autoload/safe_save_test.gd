extends GdUnitTestSuite
## Safe saving (the fix round of 2026-11-16): a save is written beside the one before it, read
## back, and only then put in its place, and the one before it is kept as a backup. A write that
## fails or is cut short leaves the old save as it was. Uses a slot of its own.

const TEST_SLOT: int = 968


func before_test() -> void:
	SaveSystem.erase_slot(TEST_SLOT)
	SaveSystem.current_slot = TEST_SLOT
	GameState.clear()
	GameState.new_game()


func after_test() -> void:
	SaveSystem.write_file = SaveSystem._write_text
	SaveSystem.erase_slot(TEST_SLOT)
	SaveSystem.current_slot = SaveSystem.GAME_SLOT
	GameState.clear()


func test_the_first_save_has_no_backup_and_leaves_nothing_half_written() -> void:
	assert_int(SaveSystem.save_game()).is_equal(OK)
	assert_bool(SaveSystem.has_save()).is_true()
	assert_bool(SaveSystem.has_backup()).is_false()
	assert_bool(FileAccess.file_exists(_temp())).override_failure_message("the temporary file is gone").is_false()


func test_a_save_keeps_the_one_before_it_as_a_backup() -> void:
	GameState.add_item(&"coin", 7)
	assert_int(SaveSystem.save_game()).is_equal(OK)
	var first: String = _text(_save())
	GameState.add_item(&"coin", 5)
	assert_int(SaveSystem.save_game()).is_equal(OK)
	assert_str(_text(SaveSystem.backup_path(TEST_SLOT))).override_failure_message("the backup is the save before").is_equal(first)
	assert_str(_text(_save())).is_not_equal(first)
	# A third save: the backup is the second, never older.
	var second: String = _text(_save())
	GameState.add_item(&"coin", 1)
	assert_int(SaveSystem.save_game()).is_equal(OK)
	assert_str(_text(SaveSystem.backup_path(TEST_SLOT))).is_equal(second)
	assert_bool(FileAccess.file_exists(_temp())).is_false()
	# Each can be loaded.
	assert_int(SaveSystem.load_backup()).is_equal(OK)
	assert_int(GameState.item_count(&"coin")).is_equal(12)
	assert_int(SaveSystem.load_game()).is_equal(OK)
	assert_int(GameState.item_count(&"coin")).is_equal(13)


func test_a_save_cut_short_leaves_the_save_before_it_as_it_was() -> void:
	GameState.add_item(&"coin", 7)
	assert_int(SaveSystem.save_game()).is_equal(OK)
	var before: String = _text(_save())
	# The disk fills up halfway through the next one.
	SaveSystem.write_file = func(path: String, text: String) -> Error:
		return SaveSystem._write_text(path, text.substr(0, text.length() / 2))
	GameState.add_item(&"coin", 5)
	assert_int(SaveSystem.save_game()).override_failure_message("the save says it failed").is_equal(ERR_FILE_CORRUPT)
	assert_str(_text(_save())).override_failure_message("the old save is untouched").is_equal(before)
	assert_bool(FileAccess.file_exists(_temp())).override_failure_message("the half save is cleared away").is_false()
	GameState.new_game()
	assert_int(SaveSystem.load_game()).is_equal(OK)
	assert_int(GameState.item_count(&"coin")).is_equal(7)


func test_a_save_that_cannot_be_written_leaves_the_save_before_it_as_it_was() -> void:
	assert_int(SaveSystem.save_game()).is_equal(OK)
	var before: String = _text(_save())
	SaveSystem.write_file = func(_path: String, _text: String) -> Error: return ERR_FILE_CANT_WRITE
	GameState.add_item(&"coin", 5)
	assert_int(SaveSystem.save_game()).is_equal(ERR_FILE_CANT_WRITE)
	assert_str(_text(_save())).is_equal(before)
	assert_bool(SaveSystem.has_backup()).override_failure_message("nothing was moved for a save that never came").is_false()


func test_a_first_save_that_fails_leaves_no_save_at_all() -> void:
	SaveSystem.write_file = func(path: String, _text: String) -> Error: return SaveSystem._write_text(path, "{")
	assert_int(SaveSystem.save_game()).is_equal(ERR_FILE_CORRUPT)
	assert_bool(SaveSystem.has_save()).override_failure_message("half a save is never the save").is_false()


func test_a_save_left_half_written_by_a_crash_is_never_read_and_is_replaced() -> void:
	assert_int(SaveSystem.save_game()).is_equal(OK)
	SaveSystem._write_text(_temp(), "{ \"version\": 4, \"inv")
	assert_int(SaveSystem.load_game()).override_failure_message("the save loads, whatever lies beside it").is_equal(OK)
	GameState.add_item(&"coin", 3)
	assert_int(SaveSystem.save_game()).is_equal(OK)
	assert_bool(FileAccess.file_exists(_temp())).is_false()
	GameState.new_game()
	assert_int(SaveSystem.load_game()).is_equal(OK)
	assert_int(GameState.item_count(&"coin")).is_equal(3)


func test_a_save_from_before_backups_loads_as_it_did_and_becomes_the_first_backup() -> void:
	# As the game wrote them until now: one file, nothing beside it.
	GameState.add_item(&"coin", 9)
	GameState.update_player(&"village", Vector2i(18, 23))
	var old: String = JSON.stringify(GameState.to_dict(), "\t")
	DirAccess.make_dir_recursive_absolute(SaveSystem.SAVE_DIR)
	SaveSystem._write_text(_save(), old)
	GameState.new_game()
	assert_int(SaveSystem.load_game()).is_equal(OK)
	assert_int(GameState.item_count(&"coin")).is_equal(9)
	assert_str(JSON.stringify(GameState.to_dict(), "\t")).is_equal(old)
	GameState.add_item(&"coin", 1)
	assert_int(SaveSystem.save_game()).is_equal(OK)
	assert_str(_text(SaveSystem.backup_path(TEST_SLOT))).is_equal(old)


func test_saving_many_times_in_a_row_never_fails() -> void:
	# A file just written can be held for a moment by whatever watches the disk.
	for i: int in 25:
		GameState.add_play_time(1.0)
		assert_int(SaveSystem.save_game()).override_failure_message("save %d" % i).is_equal(OK)
	GameState.new_game()
	assert_int(SaveSystem.load_game()).is_equal(OK)
	assert_float(GameState.play_time).is_equal(25.0)
	assert_int(SaveSystem.load_backup()).is_equal(OK)
	assert_float(GameState.play_time).is_equal(24.0)


func test_the_backup_is_summed_up_like_the_save() -> void:
	assert_dict(SaveSystem.backup_summary()).override_failure_message("no backup, nothing to sum up").is_empty()
	GameState.update_player(&"old_wood", Vector2i(18, 10))
	GameState.add_play_time(60.0)
	assert_int(SaveSystem.save_game()).is_equal(OK)
	GameState.update_player(&"village", Vector2i(18, 23))
	GameState.add_play_time(60.0)
	assert_int(SaveSystem.save_game()).is_equal(OK)
	assert_str(str(SaveSystem.summary()["area"])).is_equal("village")
	assert_str(str(SaveSystem.backup_summary()["area"])).is_equal("old_wood")
	assert_float(float(SaveSystem.backup_summary()["play_time"])).is_equal(60.0)


func test_a_save_that_cant_be_read_has_nothing_to_sum_up() -> void:
	assert_int(SaveSystem.save_game()).is_equal(OK)
	SaveSystem._write_text(_save(), "{ \"version\": 4, \"inv")
	assert_dict(SaveSystem.summary()).is_empty()
	assert_int(SaveSystem.load_game()).is_equal(ERR_PARSE_ERROR)
	SaveSystem._write_text(_save(), "{ \"version\": 99 }")
	assert_dict(SaveSystem.summary()).override_failure_message("a newer game's save").is_empty()
	assert_int(SaveSystem.load_game()).is_equal(ERR_INVALID_DATA)


func test_erasing_a_slot_removes_its_three_files() -> void:
	assert_int(SaveSystem.save_game()).is_equal(OK)
	assert_int(SaveSystem.save_game()).is_equal(OK)
	SaveSystem._write_text(_temp(), "half")
	SaveSystem.erase_slot(TEST_SLOT)
	for path: String in [_save(), SaveSystem.backup_path(TEST_SLOT), _temp()]:
		assert_bool(FileAccess.file_exists(path)).override_failure_message(path).is_false()
	# And a slot with nothing in it is no trouble.
	SaveSystem.erase_slot(TEST_SLOT)


func _save() -> String:
	return SaveSystem.slot_path(TEST_SLOT)


func _temp() -> String:
	return SaveFiles.temp_path(_save())


func _text(path: String) -> String:
	return FileAccess.get_file_as_string(path)
