extends GdUnitTestSuite
## The cursor of the screen that arranges the item bar (step B2): rows of nine, two at least;
## the cursor steps along and round, and a row up and down in its column; a choice lifts, a
## choice elsewhere sets down (a move), a choice on its own slot or put_back() puts back.


func test_two_rows_at_least_and_more_as_the_bar_fills_them() -> void:
	assert_int(BarCursor.rows_for(0)).is_equal(2)
	assert_int(BarCursor.rows_for(5)).is_equal(2)
	assert_int(BarCursor.rows_for(18)).is_equal(2)
	assert_int(BarCursor.rows_for(19)).override_failure_message("a third row once more are in use").is_equal(3)
	var cursor: BarCursor = BarCursor.new()
	cursor.set_columns(20)
	assert_int(cursor.cells).is_equal(27)
	assert_int(cursor.rows()).is_equal(3)
	cursor.at = 25
	cursor.lifted = 24
	cursor.set_columns(4)
	assert_int(cursor.cells).is_equal(18)
	assert_int(cursor.at).override_failure_message("the cursor stays on a slot that shows").is_equal(17)
	assert_int(cursor.lifted).is_equal(BarCursor.NONE)


func test_the_cursor_steps_along_and_round_and_a_row_in_its_column() -> void:
	var cursor: BarCursor = BarCursor.new()
	cursor.set_columns(6)
	cursor.step(1)
	assert_int(cursor.at).is_equal(1)
	cursor.step(-2)
	assert_int(cursor.at).override_failure_message("back from the first, round to the last").is_equal(17)
	cursor.step(1)
	assert_int(cursor.at).is_equal(0)
	cursor.at = 8
	cursor.step(1)
	assert_int(cursor.at).override_failure_message("from the end of a row to the start of the next").is_equal(9)
	cursor.at = 3
	cursor.step_row(1)
	assert_int(cursor.at).is_equal(12)
	cursor.step_row(1)
	assert_int(cursor.at).override_failure_message("down from the last row, round to the first").is_equal(3)
	cursor.step_row(-1)
	assert_int(cursor.at).is_equal(12)


func test_pointing_moves_the_cursor_onto_a_slot_that_shows() -> void:
	var cursor: BarCursor = BarCursor.new()
	assert_bool(cursor.point(5)).is_true()
	assert_int(cursor.at).is_equal(5)
	assert_bool(cursor.point(5)).override_failure_message("there already").is_false()
	assert_bool(cursor.point(BarCursor.NONE)).is_false()
	assert_bool(cursor.point(18)).is_false()
	assert_int(cursor.at).is_equal(5)


func test_a_choice_lifts_and_another_sets_down_there() -> void:
	var cursor: BarCursor = BarCursor.new()
	assert_that(cursor.choose(4, false)).override_failure_message("nothing to lift in an empty slot").is_equal(BarCursor.NO_MOVE)
	assert_bool(cursor.is_lifting()).is_false()
	assert_int(cursor.at).is_equal(4)
	assert_that(cursor.choose(1, true)).is_equal(BarCursor.NO_MOVE)
	assert_int(cursor.lifted).is_equal(1)
	assert_that(cursor.choose(6, false)).override_failure_message("into an empty slot").is_equal(Vector2i(1, 6))
	assert_bool(cursor.is_lifting()).is_false()
	assert_int(cursor.at).is_equal(6)
	cursor.choose(6, true)
	assert_that(cursor.choose(0, true)).override_failure_message("onto another thing: a swap").is_equal(Vector2i(6, 0))


func test_a_choice_on_its_own_slot_or_put_back_puts_it_back() -> void:
	var cursor: BarCursor = BarCursor.new()
	cursor.choose(2, true)
	assert_that(cursor.choose(2, true)).is_equal(BarCursor.NO_MOVE)
	assert_bool(cursor.is_lifting()).is_false()
	cursor.choose(2, true)
	cursor.step(3)
	assert_bool(cursor.put_back()).is_true()
	assert_bool(cursor.is_lifting()).is_false()
	assert_int(cursor.at).override_failure_message("the cursor stays where it was").is_equal(5)
	assert_bool(cursor.put_back()).override_failure_message("nothing lifted").is_false()
	assert_that(cursor.choose(18, true)).override_failure_message("no such slot").is_equal(BarCursor.NO_MOVE)
