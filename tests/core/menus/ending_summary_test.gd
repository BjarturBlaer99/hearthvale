extends GdUnitTestSuite
## EndingSummary: what the ending screen says about the game just finished.


func test_the_summary_gives_time_hearts_and_quests() -> void:
	var lines: PackedStringArray = EndingSummary.lines("1:07:11", 5, 2, 3)
	assert_array(Array(lines)).is_equal(["Time played   1:07:11", "Hearts   5", "Quests finished   2 of 3"])


func test_a_game_without_quests_leaves_that_line_out() -> void:
	assert_array(Array(EndingSummary.lines("12:04", 3, 0, 0))).is_equal(["Time played   12:04", "Hearts   3"])


func test_odd_numbers_are_kept_in_bounds() -> void:
	var lines: PackedStringArray = EndingSummary.lines("0:10", -2, 9, 3)
	assert_str(lines[1]).is_equal("Hearts   0")
	assert_str(lines[2]).override_failure_message("never more done than there are").is_equal("Quests finished   3 of 3")


func test_a_finished_game_is_known_by_its_flag() -> void:
	assert_bool(EndingSummary.is_finished({})).is_false()
	assert_bool(EndingSummary.is_finished({"keep_warden_beaten": true, "crypt_shade_beaten": true})).is_false()
	assert_bool(EndingSummary.is_finished({"game_finished": false})).is_false()
	assert_bool(EndingSummary.is_finished({"game_finished": true})).override_failure_message("a save's flags, keyed by text").is_true()
	assert_bool(EndingSummary.is_finished({&"game_finished": true})).override_failure_message("the game's own flags").is_true()


func test_only_finished_quests_count() -> void:
	var quests: Dictionary = {"fetch": "return", "bounty": "report", "errand": "done"}
	var flags: Dictionary = {
		String(QuestState.complete_flag(&"fetch")): true,
		String(QuestState.complete_flag(&"errand")): true,
		String(QuestState.entered_flag(&"bounty")): "report",
	}
	assert_int(EndingSummary.quests_done(["fetch", "bounty", "errand", "never_started"], quests, flags)).is_equal(2)
	assert_int(EndingSummary.quests_done([], quests, flags)).is_equal(0)
	assert_int(EndingSummary.quests_done(["fetch"], {}, {})).is_equal(0)


func test_the_summary_adds_the_days_the_crops_and_the_friends() -> void:
	var lines: PackedStringArray = EndingSummary.lines("1:07:11", 5, 2, 8, {"days": 7, "crops": 31, "friends": 3, "villagers": 7})
	assert_array(Array(lines)).is_equal([
		"Time played   1:07:11", "Hearts   5", "Quests finished   2 of 8", "Days   7", "Crops grown   31", "Friends   3 of 7",
	])
	# What is left out is not shown, and a game with no villagers has no friends line.
	assert_array(Array(EndingSummary.lines("0:10", 3, 0, 0, {"days": 2}))).is_equal(["Time played   0:10", "Hearts   3", "Days   2"])
	assert_array(Array(EndingSummary.lines("0:10", 3, 0, 0, {"crops": 4, "friends": 2, "villagers": 0}))).is_equal(["Time played   0:10", "Hearts   3", "Crops grown   4"])
	# Odd numbers are kept in bounds.
	var odd: PackedStringArray = EndingSummary.lines("0:10", 3, 0, 0, {"days": 0, "crops": -5, "friends": 12, "villagers": 7})
	assert_array(Array(odd).slice(2)).is_equal(["Days   1", "Crops grown   0", "Friends   7 of 7"])
