extends GdUnitTestSuite
## BoatRules: where the boat floats, the nearest deep cell, landing and boarding.


func test_the_boat_floats_only_on_deep_water() -> void:
	var terrain: TerrainQuery = _terrain(["0 2 3 4"])
	assert_bool(BoatRules.floats(terrain, Vector2i(0, 0), 4)).is_true()
	assert_bool(BoatRules.floats(terrain, Vector2i(1, 0), 4)).is_true()
	assert_bool(BoatRules.floats(terrain, Vector2i(2, 0), 4)).override_failure_message("shallow").is_false()
	assert_bool(BoatRules.floats(terrain, Vector2i(3, 0), 4)).override_failure_message("dry").is_false()
	assert_bool(BoatRules.floats(terrain, Vector2i(9, 0), 4)).override_failure_message("off the map").is_false()


func test_the_nearest_deep_cell_is_the_fewest_steps_away() -> void:
	var terrain: TerrainQuery = _terrain(["4 4 4 4 4", "4 4 4 4 0", "0 4 4 4 4"])
	assert_that(BoatRules.nearest_deep_cell(terrain, Vector2i(0, 1), 4)).is_equal(Vector2i(0, 2))
	assert_that(BoatRules.nearest_deep_cell(terrain, Vector2i(3, 0), 4)).is_equal(Vector2i(4, 1))
	assert_that(BoatRules.nearest_deep_cell(terrain, Vector2i(4, 1), 4)).is_equal(Vector2i(4, 1))


func test_with_no_deep_water_there_is_no_nearest_cell() -> void:
	var terrain: TerrainQuery = _terrain(["0 0", "0 0"])
	assert_that(BoatRules.nearest_deep_cell(terrain, Vector2i(0, 0), 1)).is_equal(BoatRules.NO_CELL)


func test_a_rider_lands_ahead_of_the_boat_when_possible() -> void:
	var terrain: TerrainQuery = _terrain(["4 4 4", "4 0 4", "4 4 4"])
	assert_that(BoatRules.landing_cell(terrain, Vector2i(1, 1), 0.0, 4)).is_equal(Vector2i(2, 1))
	assert_that(BoatRules.landing_cell(terrain, Vector2i(1, 1), PI / 2.0, 4)).is_equal(Vector2i(1, 2))
	assert_that(BoatRules.landing_cell(terrain, Vector2i(1, 1), PI, 4)).is_equal(Vector2i(0, 1))


func test_landing_needs_ground_you_can_walk_onto() -> void:
	# Ahead (west) is a wall two levels above the surface; the shallows to the east will do.
	var terrain: TerrainQuery = _terrain(["6 6 6", "6 0 3", "6 6 6"])
	assert_that(BoatRules.landing_cell(terrain, Vector2i(1, 1), PI, 4)).is_equal(Vector2i(2, 1))
	var walled_in: TerrainQuery = _terrain(["6 6 6", "6 0 6", "6 6 6"])
	assert_that(BoatRules.landing_cell(walled_in, Vector2i(1, 1), 0.0, 4)).is_equal(BoatRules.NO_CELL)


func test_boarding_needs_the_boat_right_beside_you() -> void:
	assert_bool(BoatRules.can_board(Vector2i(1, 1), Vector2i(1, 1))).is_true()
	assert_bool(BoatRules.can_board(Vector2i(1, 2), Vector2i(1, 1))).is_true()
	assert_bool(BoatRules.can_board(Vector2i(2, 2), Vector2i(1, 1))).override_failure_message("diagonal").is_false()
	assert_bool(BoatRules.can_board(Vector2i(3, 1), Vector2i(1, 1))).is_false()


func _terrain(rows: Array) -> TerrainQuery:
	return TerrainQuery.new(HeightGrid.from_rows(PackedStringArray(rows)))
