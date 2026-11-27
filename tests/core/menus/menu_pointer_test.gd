extends GdUnitTestSuite
## Where the mouse points in a menu: which line of a list a point is on, and which of two
## names side by side.


func test_a_point_is_on_the_line_it_falls_in() -> void:
	# A list 200 wide of four lines, each 11 high.
	assert_int(MenuPointer.line_at(Vector2(4.0, 0.0), 200.0, 11.0, 4)).is_equal(0)
	assert_int(MenuPointer.line_at(Vector2(4.0, 10.9), 200.0, 11.0, 4)).is_equal(0)
	assert_int(MenuPointer.line_at(Vector2(4.0, 11.0), 200.0, 11.0, 4)).is_equal(1)
	assert_int(MenuPointer.line_at(Vector2(199.0, 43.9), 200.0, 11.0, 4)).is_equal(3)


func test_a_point_off_the_list_is_on_no_line() -> void:
	assert_int(MenuPointer.NONE).is_equal(-1)
	assert_int(MenuPointer.line_at(Vector2(4.0, -0.1), 200.0, 11.0, 4)).override_failure_message("above").is_equal(MenuPointer.NONE)
	assert_int(MenuPointer.line_at(Vector2(4.0, 44.0), 200.0, 11.0, 4)).override_failure_message("below the last line").is_equal(MenuPointer.NONE)
	assert_int(MenuPointer.line_at(Vector2(-1.0, 5.0), 200.0, 11.0, 4)).override_failure_message("to the left").is_equal(MenuPointer.NONE)
	assert_int(MenuPointer.line_at(Vector2(200.0, 5.0), 200.0, 11.0, 4)).override_failure_message("to the right").is_equal(MenuPointer.NONE)
	assert_int(MenuPointer.line_at(Vector2(4.0, 5.0), 200.0, 11.0, 0)).override_failure_message("an empty list").is_equal(MenuPointer.NONE)
	assert_int(MenuPointer.line_at(Vector2(4.0, 5.0), 200.0, 0.0, 4)).override_failure_message("lines of no height").is_equal(MenuPointer.NONE)


func test_a_point_is_on_one_of_the_names_side_by_side_or_between_them() -> void:
	# "[Buy]" 25 wide, a gap of 8, " Sell " 30 wide.
	var widths: PackedFloat32Array = [25.0, 30.0]
	assert_int(MenuPointer.part_at(0.0, widths, 8.0)).is_equal(0)
	assert_int(MenuPointer.part_at(24.9, widths, 8.0)).is_equal(0)
	assert_int(MenuPointer.part_at(28.0, widths, 8.0)).override_failure_message("on the gap").is_equal(MenuPointer.NONE)
	assert_int(MenuPointer.part_at(33.0, widths, 8.0)).is_equal(1)
	assert_int(MenuPointer.part_at(62.9, widths, 8.0)).is_equal(1)
	assert_int(MenuPointer.part_at(63.0, widths, 8.0)).override_failure_message("past the last").is_equal(MenuPointer.NONE)
	assert_int(MenuPointer.part_at(-1.0, widths, 8.0)).is_equal(MenuPointer.NONE)


func test_a_cursor_goes_where_it_is_pointed_unless_that_cant_be_chosen() -> void:
	var cursor: MenuCursor = MenuCursor.new([
		MenuCursor.option(&"continue", "Continue", false),
		MenuCursor.option(&"new", "New game"),
		MenuCursor.option(&"quit", "Quit"),
	])
	assert_that(cursor.selected_id()).is_equal(&"new")
	assert_bool(cursor.select(2)).is_true()
	assert_that(cursor.selected_id()).is_equal(&"quit")
	assert_bool(cursor.select(2)).override_failure_message("it is there already").is_false()
	assert_bool(cursor.select(0)).override_failure_message("a line that can't be chosen").is_false()
	assert_bool(cursor.select(MenuPointer.NONE)).is_false()
	assert_bool(cursor.select(3)).is_false()
	assert_that(cursor.selected_id()).is_equal(&"quit")


func test_a_click_chooses_the_line_it_is_on_or_the_highlighted_one() -> void:
	var cursor: MenuCursor = MenuCursor.new([
		MenuCursor.option(&"continue", "Continue", false),
		MenuCursor.option(&"new", "New game"),
		MenuCursor.option(&"quit", "Quit"),
	])
	assert_bool(cursor.take_click(MenuPointer.NONE)).override_failure_message("on no line: the highlighted one, as always").is_true()
	assert_that(cursor.selected_id()).is_equal(&"new")
	assert_bool(cursor.take_click(2)).is_true()
	assert_that(cursor.selected_id()).is_equal(&"quit")
	assert_bool(cursor.take_click(0)).override_failure_message("on a line that can't be chosen: nothing").is_false()
	assert_that(cursor.selected_id()).override_failure_message("and the cursor stays").is_equal(&"quit")
	assert_bool(cursor.take_click(7)).is_false()
	var empty: MenuCursor = MenuCursor.new()
	assert_bool(empty.take_click(MenuPointer.NONE)).override_failure_message("nothing to choose").is_false()


func test_a_point_is_on_the_cell_of_a_grid_it_falls_in() -> void:
	# Cells of 20 by 20, 4 apart, three to a row, five in all (the second row has two).
	var cell: Vector2 = Vector2(20, 20)
	assert_int(MenuPointer.cell_at(Vector2(0, 0), cell, 4.0, 3, 5)).is_equal(0)
	assert_int(MenuPointer.cell_at(Vector2(19.9, 19.9), cell, 4.0, 3, 5)).is_equal(0)
	assert_int(MenuPointer.cell_at(Vector2(24, 0), cell, 4.0, 3, 5)).is_equal(1)
	assert_int(MenuPointer.cell_at(Vector2(60, 10), cell, 4.0, 3, 5)).is_equal(2)
	assert_int(MenuPointer.cell_at(Vector2(5, 30), cell, 4.0, 3, 5)).override_failure_message("the second row").is_equal(3)
	assert_int(MenuPointer.cell_at(Vector2(30, 43.9), cell, 4.0, 3, 5)).is_equal(4)


func test_a_point_on_a_gap_or_off_the_grid_is_on_no_cell() -> void:
	var cell: Vector2 = Vector2(20, 20)
	assert_int(MenuPointer.cell_at(Vector2(21, 5), cell, 4.0, 3, 5)).override_failure_message("between two cells").is_equal(MenuPointer.NONE)
	assert_int(MenuPointer.cell_at(Vector2(5, 22), cell, 4.0, 3, 5)).override_failure_message("between two rows").is_equal(MenuPointer.NONE)
	assert_int(MenuPointer.cell_at(Vector2(53, 30), cell, 4.0, 3, 5)).override_failure_message("past the last cell").is_equal(MenuPointer.NONE)
	assert_int(MenuPointer.cell_at(Vector2(75, 5), cell, 4.0, 3, 5)).override_failure_message("right of the grid").is_equal(MenuPointer.NONE)
	assert_int(MenuPointer.cell_at(Vector2(5, 50), cell, 4.0, 3, 5)).override_failure_message("below it").is_equal(MenuPointer.NONE)
	assert_int(MenuPointer.cell_at(Vector2(-1, 5), cell, 4.0, 3, 5)).is_equal(MenuPointer.NONE)
	assert_int(MenuPointer.cell_at(Vector2(5, -1), cell, 4.0, 3, 5)).is_equal(MenuPointer.NONE)
	assert_int(MenuPointer.cell_at(Vector2(5, 5), cell, 4.0, 3, 0)).override_failure_message("no cells").is_equal(MenuPointer.NONE)
