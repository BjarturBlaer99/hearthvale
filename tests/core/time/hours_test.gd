extends GdUnitTestSuite
## Hours (P2e): when the shop's door is open and when villagers who stand outdoors are out. The
## numbers are the game's own (data/rules/hours.json).

const HOURS_RULES: String = "res://data/rules/hours.json"
const TIME_RULES: String = "res://data/rules/time.json"

var _data: Dictionary
var _hours: Hours
var _clock: DayClock


func before_test() -> void:
	_data = JSON.parse_string(FileAccess.get_file_as_string(HOURS_RULES))
	_hours = Hours.new(_data)
	_clock = DayClock.new(JSON.parse_string(FileAccess.get_file_as_string(TIME_RULES)))


func test_the_shop_is_open_from_eight_to_six() -> void:
	var open: Dictionary = {"06:00": false, "07:59": false, "08:00": true, "12:00": true, "17:59": true, "18:00": false, "23:00": false, "01:30": false}
	for time: String in open:
		assert_bool(_hours.is_open(&"shop", _clock.in_day(time))).override_failure_message("the shop at %s" % time).is_equal(open[time])
	assert_str(_hours.shut_words(&"shop")).is_equal("Tilda's shop is shut. She opens at 08:00 and closes at 18:00.")


func test_a_place_the_rules_dont_name_keeps_no_hours() -> void:
	for time: String in ["06:00", "12:00", "23:00", "01:59"]:
		assert_bool(_hours.is_open(&"chapel", _clock.in_day(time))).override_failure_message("at %s" % time).is_true()
	assert_bool(_hours.is_open(&"", _clock.in_day("23:00"))).is_true()
	assert_str(_hours.shut_words(&"chapel")).is_equal(Hours.SHUT_WORDS)


func test_villagers_are_out_from_six_until_eight_in_the_evening() -> void:
	var out: Dictionary = {"06:00": true, "12:00": true, "19:59": true, "20:00": false, "23:30": false, "01:59": false}
	for time: String in out:
		assert_bool(_hours.villagers_out(_clock.in_day(time))).override_failure_message("out at %s" % time).is_equal(out[time])
	assert_bool(_hours.villagers_out(float(_clock.ends))).override_failure_message("02:00, as the day runs out").is_false()


func test_hours_may_run_over_midnight_and_a_door_may_have_no_words() -> void:
	var late: Hours = Hours.new({"places": {"inn": {"from": "17:00", "to": "01:00"}}, "outdoors": {"from": "22:00", "to": "04:00"}})
	var open: Dictionary = {"16:59": false, "17:00": true, "23:59": true, "00:30": true, "01:00": false, "06:00": false}
	for time: String in open:
		assert_bool(late.is_open(&"inn", _clock.in_day(time))).override_failure_message("the inn at %s" % time).is_equal(open[time])
	assert_str(late.shut_words(&"inn")).is_equal(Hours.SHUT_WORDS)
	assert_bool(late.villagers_out(_clock.in_day("23:00"))).is_true()
	assert_bool(late.villagers_out(_clock.in_day("12:00"))).is_false()


func test_the_games_hours_are_sound_and_bad_ones_are_named() -> void:
	assert_array(Array(Hours.problems(_data))).is_empty()
	assert_dict(Hours.DEFAULTS["outdoors"]).override_failure_message("what a missing rule falls back to is the game's own").is_equal(_data["outdoors"])
	assert_bool(Hours.new().villagers_out(_clock.in_day("19:59"))).is_true()
	assert_bool(Hours.new().villagers_out(_clock.in_day("20:00"))).is_false()
	assert_bool(Hours.new().is_open(&"shop", _clock.in_day("23:00"))).override_failure_message("with no rules nothing is shut").is_true()
	var bad: Array = Array(Hours.problems({"places": {"shop": {"from": "08:00"}, "inn": {"from": "10:00", "to": "23:00", "shut": 5}}, "outdoors": {"from": "dawn", "to": "20:00"}}))
	assert_array(bad).contains_exactly([
		"'outdoors' must have a 'from' and a 'to', each a time of day.",
		"place 'shop' must have a 'from' and a 'to', each a time of day.",
		"place 'inn': 'shut' must be the words said at its door.",
	])
	assert_array(Array(Hours.problems({"outdoors": {"from": "06:00", "to": "20:00"}}))).contains_exactly(["'places' must be an object: a place's id, then its hours."])
