extends GdUnitTestSuite
## HeightGrid: heights and flags per cell, safe outside the grid.


func test_rows_give_heights_and_flags() -> void:
	var grid: HeightGrid = HeightGrid.from_rows(PackedStringArray(["0 1r 2", "7s 3 0"]))
	assert_that(grid.size).is_equal(Vector2i(3, 2))
	assert_int(grid.height_at(Vector2i(1, 0))).is_equal(1)
	assert_int(grid.height_at(Vector2i(0, 1))).is_equal(7)
	assert_bool(grid.is_ramp(Vector2i(1, 0))).is_true()
	assert_bool(grid.is_solid(Vector2i(0, 1))).is_true()
	assert_bool(grid.is_solid(Vector2i(1, 0))).is_false()
	assert_bool(grid.is_ramp(Vector2i(0, 1))).is_false()


func test_outside_the_grid_has_no_height_or_flags() -> void:
	var grid: HeightGrid = HeightGrid.new(Vector2i(2, 2), 3)
	assert_int(grid.height_at(Vector2i(1, 1))).is_equal(3)
	assert_bool(grid.in_bounds(Vector2i(2, 0))).is_false()
	assert_int(grid.height_at(Vector2i(-1, 0))).is_equal(-1)
	assert_bool(grid.is_ramp(Vector2i(5, 5))).is_false()
	assert_bool(grid.is_solid(Vector2i(0, -1))).is_false()


func test_heights_are_clamped_to_zero_through_seven() -> void:
	var grid: HeightGrid = HeightGrid.new(Vector2i(2, 1))
	grid.set_height(Vector2i(0, 0), 12)
	grid.set_height(Vector2i(1, 0), -4)
	assert_int(grid.height_at(Vector2i(0, 0))).is_equal(HeightGrid.MAX_HEIGHT)
	assert_int(grid.height_at(Vector2i(1, 0))).is_equal(0)


func test_flags_can_be_cleared_independently() -> void:
	var grid: HeightGrid = HeightGrid.from_rows(PackedStringArray(["2sr"]))
	grid.set_solid(Vector2i.ZERO, false)
	assert_bool(grid.is_solid(Vector2i.ZERO)).is_false()
	assert_bool(grid.is_ramp(Vector2i.ZERO)).is_true()
