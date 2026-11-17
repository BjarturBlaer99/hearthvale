extends GdUnitTestSuite
## What the mine remembers (MineState, pure): the rocks broken today, floor by floor, whole
## again when another day begins; and the number its rolls come from. It goes through a save.

const FLOOR: StringName = &"quarry_2"
const OTHER: StringName = &"quarry_5"


func test_a_broken_rock_is_broken_for_the_day_on_its_own_floor() -> void:
	var mine: MineState = MineState.new(41)
	assert_int(mine.number).is_equal(41)
	assert_bool(mine.is_broken(FLOOR, Vector2i(3, 4), 1)).is_false()
	mine.mark_broken(FLOOR, Vector2i(3, 4), 1)
	mine.mark_broken(FLOOR, Vector2i(7, 2), 1)
	mine.mark_broken(FLOOR, Vector2i(7, 2), 1)
	assert_bool(mine.is_broken(FLOOR, Vector2i(3, 4), 1)).is_true()
	assert_bool(mine.is_broken(FLOOR, Vector2i(7, 2), 1)).is_true()
	assert_bool(mine.is_broken(FLOOR, Vector2i(4, 3), 1)).override_failure_message("not its neighbour").is_false()
	assert_bool(mine.is_broken(OTHER, Vector2i(3, 4), 1)).override_failure_message("not the same cell on another floor").is_false()
	assert_int(mine.broken_count(FLOOR, 1)).override_failure_message("a rock broken twice is one rock").is_equal(2)
	assert_int(mine.broken_count(OTHER, 1)).is_equal(0)


func test_the_next_morning_every_rock_is_whole_again() -> void:
	var mine: MineState = MineState.new()
	mine.mark_broken(FLOOR, Vector2i(3, 4), 1)
	assert_bool(mine.is_broken(FLOOR, Vector2i(3, 4), 2)).override_failure_message("asked about tomorrow").is_false()
	assert_int(mine.broken_count(FLOOR, 2)).is_equal(0)
	assert_bool(mine.is_broken(FLOOR, Vector2i(3, 4), 1)).override_failure_message("asking doesn't mend it").is_true()
	assert_bool(mine.start_day(1)).override_failure_message("the same day begins nothing").is_false()
	assert_bool(mine.is_broken(FLOOR, Vector2i(3, 4), 1)).is_true()
	assert_bool(mine.start_day(2)).is_true()
	assert_int(mine.day).is_equal(2)
	assert_bool(mine.is_broken(FLOOR, Vector2i(3, 4), 2)).is_false()
	assert_bool(mine.is_broken(FLOOR, Vector2i(3, 4), 1)).override_failure_message("yesterday's list is gone").is_false()
	# A rock broken on a later day begins that day by itself.
	mine.mark_broken(OTHER, Vector2i(1, 1), 5)
	assert_int(mine.day).is_equal(5)
	assert_bool(mine.is_broken(OTHER, Vector2i(1, 1), 5)).is_true()


func test_it_goes_through_a_save_as_it_is() -> void:
	var mine: MineState = MineState.new(987654321)
	mine.mark_broken(FLOOR, Vector2i(7, 2), 3)
	mine.mark_broken(FLOOR, Vector2i(3, 4), 3)
	mine.mark_broken(OTHER, Vector2i(10, 9), 3)
	var saved: Dictionary = mine.to_dict()
	assert_dict(saved).is_equal({"number": 987654321, "day": 3, "broken": {"quarry_2": ["3,4", "7,2"], "quarry_5": ["10,9"]}})
	# Through JSON, as a save file is (numbers come back as floats).
	var read: Variant = JSON.parse_string(JSON.stringify(saved))
	var again: MineState = MineState.new()
	again.load_saved(read)
	assert_int(again.number).is_equal(987654321)
	assert_int(again.day).is_equal(3)
	assert_bool(again.is_broken(FLOOR, Vector2i(7, 2), 3)).is_true()
	assert_bool(again.is_broken(OTHER, Vector2i(10, 9), 3)).is_true()
	assert_bool(again.is_broken(FLOOR, Vector2i(10, 9), 3)).is_false()
	assert_dict(again.to_dict()).is_equal(saved)
	# Loading replaces what was there.
	again.load_saved({"number": 5, "day": 4, "broken": {}})
	assert_int(again.number).is_equal(5)
	assert_int(again.broken_count(FLOOR, 3)).is_equal(0)


func test_odd_values_in_a_save_are_made_safe() -> void:
	var mine: MineState = MineState.new(12)
	mine.mark_broken(FLOOR, Vector2i(1, 1), 2)
	for odd: Variant in [null, "the mine", 7, []]:
		mine.load_saved(odd)
		assert_int(mine.number).override_failure_message("%s: the number it had is kept" % [odd]).is_equal(12)
		assert_int(mine.broken_count(FLOOR, 2)).override_failure_message("%s: nothing broken" % [odd]).is_equal(0)
	mine.load_saved({"number": "many", "day": -3, "broken": {"quarry_2": ["3,4", "somewhere", 9, "1,2,3"], "quarry_5": "all of it", "quarry_7": []}})
	assert_int(mine.number).is_equal(12)
	assert_int(mine.day).is_equal(0)
	assert_dict(mine.to_dict()["broken"]).override_failure_message("only what names a cell is kept").is_equal({"quarry_2": ["3,4"]})
