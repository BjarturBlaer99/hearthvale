extends GdUnitTestSuite
## DayClock (P2a): a day runs from 06:00 to 02:00 in 14 real minutes; the light, the lamps and
## the night follow the hour; and a clock's rules are checked before they are used.

const TIME_RULES: String = "res://data/rules/time.json"

var _rules: Dictionary
var _clock: DayClock


func before_test() -> void:
	_rules = JSON.parse_string(FileAccess.get_file_as_string(TIME_RULES))
	_clock = DayClock.new(_rules)


func test_times_of_day_are_read_and_written() -> void:
	assert_int(DayClock.parse("06:00")).is_equal(360)
	assert_int(DayClock.parse("18:30")).is_equal(1110)
	assert_int(DayClock.parse("0:05")).is_equal(5)
	for wrong: String in ["", "six", "24:00", "12:60", "12", "12:5", "-1:00", "12:00:00"]:
		assert_int(DayClock.parse(wrong)).override_failure_message("'%s' is not a time of day" % wrong).is_equal(-1)
	assert_str(DayClock.format(360.0)).is_equal("06:00")
	assert_str(DayClock.format(1110.9)).is_equal("18:30")
	assert_str(DayClock.format(1560.0)).override_failure_message("the small hours read as a clock does").is_equal("02:00")
	assert_str(DayClock.shown(367.0)).override_failure_message("the HUD's clock moves in steps of ten minutes").is_equal("06:00")
	assert_str(DayClock.shown(370.0)).is_equal("06:10")
	assert_str(DayClock.shown(1499.9)).is_equal("00:50")


func test_a_day_runs_from_six_to_two_in_fourteen_minutes() -> void:
	assert_int(_clock.starts).is_equal(360)
	assert_int(_clock.ends).override_failure_message("02:00 the next morning, counted on from midnight").is_equal(1560)
	assert_float(_clock.length_seconds()).override_failure_message("fourteen real minutes (decision 6)").is_equal_approx(14.0 * 60.0, 0.01)
	assert_int(_clock.in_day("23:00")).is_equal(1380)
	assert_int(_clock.in_day("01:00")).override_failure_message("after midnight counts on").is_equal(1500)
	assert_int(_clock.in_day("06:00")).is_equal(360)


func test_the_clock_moves_with_real_time_and_stops_at_the_days_end() -> void:
	var minute: float = float(_clock.starts)
	minute = _clock.advance(minute, _clock.seconds_per_hour)
	assert_float(minute).override_failure_message("an hour of the day in seconds_per_hour").is_equal_approx(420.0, 0.001)
	assert_float(_clock.advance(minute, -5.0)).override_failure_message("time never runs back").is_equal(minute)
	assert_bool(_clock.is_over(minute)).is_false()
	minute = _clock.advance(minute, _clock.length_seconds())
	assert_float(minute).override_failure_message("it stops at 02:00").is_equal(float(_clock.ends))
	assert_bool(_clock.is_over(minute)).is_true()
	assert_float(_clock.advance(minute, 100.0)).is_equal(float(_clock.ends))
	# A frame at a time comes to the same.
	var by_frames: float = float(_clock.starts)
	for i: int in 600:
		by_frames = _clock.advance(by_frames, 1.0 / 60.0)
	assert_float(by_frames).is_equal_approx(_clock.advance(float(_clock.starts), 10.0), 0.01)


func test_the_light_follows_the_hour() -> void:
	var dawn: Color = _clock.light_at(_clock.in_day("06:00"))
	var noon: Color = _clock.light_at(_clock.in_day("12:00"))
	var dusk: Color = _clock.light_at(_clock.in_day("18:30"))
	var late_dusk: Color = _clock.light_at(_clock.in_day("19:45"))
	var night: Color = _clock.light_at(_clock.in_day("23:00"))
	var small_hours: Color = _clock.light_at(_clock.in_day("02:00"))
	assert_that(noon).override_failure_message("clear by day").is_equal(Color.WHITE)
	assert_bool(dawn.r > dawn.g and dawn.g > dawn.b).override_failure_message("peach at dawn: %s" % dawn).is_true()
	assert_bool(dusk.r > dusk.g and dusk.g > dusk.b and dusk.b < dawn.b).override_failure_message("orange at dusk, deeper than dawn: %s" % dusk).is_true()
	assert_bool(late_dusk.b > late_dusk.g and late_dusk.r > late_dusk.g).override_failure_message("then violet: %s" % late_dusk).is_true()
	assert_bool(night.b > night.r and night.b > night.g).override_failure_message("blue at night: %s" % night).is_true()
	assert_float(small_hours.get_luminance()).override_failure_message("the night is dim, not dark: the hero has no light of his own outdoors").is_greater(0.4)
	# Between two of the rules' times the light is between their colours, and it never jumps.
	var half: Color = _clock.light_at((_clock.in_day("06:00") + _clock.in_day("07:30")) / 2.0)
	assert_bool(half.is_equal_approx(dawn.lerp(Color.WHITE, 0.5))).is_true()
	var last: Color = dawn
	for minute: int in range(_clock.starts, _clock.ends + 1):
		var now: Color = _clock.light_at(float(minute))
		assert_float(absf(now.r - last.r) + absf(now.g - last.g) + absf(now.b - last.b)).override_failure_message("no jump at %s" % DayClock.format(minute)).is_less(0.02)
		last = now
	assert_that(_clock.light_at(0.0)).override_failure_message("before the first time: the first colour").is_equal(dawn)
	assert_that(_clock.light_at(5000.0)).override_failure_message("after the last: the last").is_equal(small_hours)


func test_lamps_are_lit_from_dusk_to_dawn_and_night_falls_at_eight() -> void:
	var lit: Dictionary = {"06:00": true, "06:29": true, "06:30": false, "12:00": false, "18:29": false, "18:30": true, "23:59": true, "00:00": true, "02:00": true}
	for time: String in lit:
		assert_bool(_clock.lamps_lit(_clock.in_day(time))).override_failure_message("lamps at %s" % time).is_equal(lit[time])
	var night: Dictionary = {"06:00": false, "19:59": false, "20:00": true, "01:30": true, "02:00": true}
	for time: String in night:
		assert_bool(_clock.is_night(_clock.in_day(time))).override_failure_message("night at %s" % time).is_equal(night[time])


func test_the_games_rules_are_sound_and_bad_ones_are_named() -> void:
	assert_array(Array(DayClock.problems(_rules))).override_failure_message("the game's own rules").is_empty()
	for key: String in ["day_starts", "day_ends", "seconds_per_hour", "lamps_lit", "night"]:
		assert_that(DayClock.DEFAULTS[key]).override_failure_message("the fallback for '%s' is the game's rule" % key).is_equal(_rules[key] if key != "seconds_per_hour" else float(_rules[key]))
		var without: Dictionary = _rules.duplicate(true)
		without.erase(key)
		assert_array(Array(DayClock.problems(without))).override_failure_message("a missing '%s' is a problem" % key).is_not_empty()
	var bad: Dictionary = _rules.duplicate(true)
	bad["seconds_per_hour"] = 0
	assert_str("\n".join(DayClock.problems(bad))).contains("above 0")
	bad = _rules.duplicate(true)
	bad["day_ends"] = "two o'clock"
	assert_str("\n".join(DayClock.problems(bad))).contains("'day_ends'")
	bad = _rules.duplicate(true)
	bad["light"] = []
	assert_str("\n".join(DayClock.problems(bad))).contains("'light'")
	bad = _rules.duplicate(true)
	bad["light"] = [{"at": "12:00", "color": [1, 1, 1]}, {"at": "08:00", "color": [1, 1, 1]}]
	assert_str("\n".join(DayClock.problems(bad))).override_failure_message("the light must be listed in the day's order").contains("out of order")
	bad["light"] = [{"at": "23:00", "color": [1, 1, 1]}, {"at": "01:00", "color": [1, 1, 1]}]
	assert_array(Array(DayClock.problems(bad))).override_failure_message("01:00 comes after 23:00 in a day that began at 06:00").is_empty()
	bad["light"] = [{"at": "12:00", "color": [1, 2, 1]}]
	assert_str("\n".join(DayClock.problems(bad))).contains("0 to 1")
	bad["light"] = [{"at": "12:00"}]
	assert_str("\n".join(DayClock.problems(bad))).contains("three numbers")
	# A clock with no rules at all still runs, on the fallbacks.
	var bare: DayClock = DayClock.new()
	assert_int(bare.starts).is_equal(_clock.starts)
	assert_int(bare.ends).is_equal(_clock.ends)
	assert_float(bare.length_seconds()).is_equal(_clock.length_seconds())
