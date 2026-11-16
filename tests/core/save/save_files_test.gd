extends GdUnitTestSuite
## SaveFiles: where a slot's three files are, and whether a file's text is a save this game
## can load.

const GOOD: String = "{\"version\": 4, \"day\": 2}"


func test_the_temporary_file_and_the_backup_sit_beside_the_save() -> void:
	assert_str(SaveFiles.temp_path("user://saves/slot_1.json")).is_equal("user://saves/slot_1.json.tmp")
	assert_str(SaveFiles.backup_path("user://saves/slot_1.json")).is_equal("user://saves/slot_1.backup.json")
	assert_str(SaveFiles.backup_path("user://saves/slot_990.json")).is_equal("user://saves/slot_990.backup.json")


func test_a_whole_save_of_a_known_version_can_be_read() -> void:
	assert_int(SaveFiles.problem(GOOD, 4)).is_equal(OK)
	assert_int(int(SaveFiles.read(GOOD, 4)["day"])).is_equal(2)
	assert_int(SaveFiles.problem("{\"version\": 1}", 4)).override_failure_message("an old save").is_equal(OK)


func test_a_save_cut_short_is_not_a_save() -> void:
	for text: String in ["", "   ", GOOD.substr(0, 12), "[1, 2]", "nonsense", "12"]:
		assert_int(SaveFiles.problem(text, 4)).override_failure_message("'%s'" % text).is_equal(ERR_PARSE_ERROR)
		assert_dict(SaveFiles.read(text, 4)).is_empty()


func test_a_save_from_a_version_this_game_doesnt_know_is_refused() -> void:
	assert_int(SaveFiles.problem("{\"version\": 5}", 4)).override_failure_message("a newer game's").is_equal(ERR_INVALID_DATA)
	assert_int(SaveFiles.problem("{\"version\": 0}", 4)).is_equal(ERR_INVALID_DATA)
	assert_int(SaveFiles.problem("{\"day\": 2}", 4)).override_failure_message("no version at all").is_equal(ERR_INVALID_DATA)
	assert_dict(SaveFiles.read("{\"version\": 5}", 4)).is_empty()
