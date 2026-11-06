extends GdUnitTestSuite
## TerrainQuery: what each St. Aud water level means per cell, and the movement rules.
## Movement tests use one-row grids and step from the first cell to the second.


# --- Classification --------------------------------------------------------

func test_depth_decides_dry_shallow_or_deep() -> void:
	assert_that(TerrainQuery.kind_for(3, 1)).is_equal(TerrainQuery.CellKind.DRY)
	assert_that(TerrainQuery.kind_for(3, 3)).is_equal(TerrainQuery.CellKind.DRY)
	assert_that(TerrainQuery.kind_for(3, 4)).is_equal(TerrainQuery.CellKind.SHALLOW)
	assert_that(TerrainQuery.kind_for(3, 5)).is_equal(TerrainQuery.CellKind.DEEP)
	assert_that(TerrainQuery.kind_for(0, 7)).is_equal(TerrainQuery.CellKind.DEEP)


func test_cells_are_dry_shallow_or_deep_at_each_st_aud_level() -> void:
	var query: TerrainQuery = TerrainQuery.new(HeightGrid.from_rows(PackedStringArray(["0 1 2 3 4 5"])))
	# Terrain heights 0..5; "~" deep, "s" shallow, "." dry.
	var expected: Dictionary = {"flooded": "~~~s..", "waist": "~s....", "drained": "......"}
	var levels: Array = DataRegistry.get_district(&"st_aud")["levels"]
	assert_int(levels.size()).is_equal(3)
	for level: Dictionary in levels:
		var water: int = int(level["water_height"])
		var message: String = "level %s (water height %d)" % [level["id"], water]
		assert_str(_kinds(query, water)).override_failure_message(message).is_equal(expected[level["id"]])


# --- Movement --------------------------------------------------------------

func test_walking_on_level_ground() -> void:
	var step: MoveResult = _step("2 2", 0)
	assert_that(step.kind).is_equal(MoveResult.Kind.WALK)
	assert_float(step.speed_scale).is_equal(1.0)


func test_one_level_up_needs_a_ramp_or_a_climbable_face() -> void:
	assert_that(_step("1 2", 0).kind).is_equal(MoveResult.Kind.BLOCKED)
	assert_that(_step("1 2r", 0).kind).is_equal(MoveResult.Kind.WALK)
	assert_that(_step("1r 2", 0).kind).is_equal(MoveResult.Kind.WALK)
	assert_that(_step("1 2c", 0).kind).is_equal(MoveResult.Kind.CLIMB)


func test_climbing_several_levels_needs_a_climbable_face() -> void:
	var climb: MoveResult = _step("0 4c", 0)
	assert_that(climb.kind).is_equal(MoveResult.Kind.CLIMB)
	assert_int(climb.to_level).is_equal(4)
	var wall: MoveResult = _step("0 4", 0)
	assert_that(wall.kind).is_equal(MoveResult.Kind.BLOCKED)
	assert_str(wall.reason).contains("not climbable")


func test_drops_hurt_from_three_levels() -> void:
	var small: MoveResult = _step("4 3", 0)
	assert_that(small.kind).is_equal(MoveResult.Kind.DROP)
	assert_int(small.drop).is_equal(1)
	assert_bool(small.damaging).is_false()
	assert_bool(_step("4 2", 0).damaging).is_false()
	var hurts: MoveResult = _step("4 1", 0)
	assert_int(hurts.drop).is_equal(3)
	assert_bool(hurts.damaging).is_true()
	assert_bool(_step("5 0", 0).damaging).is_true()


func test_a_ramp_turns_a_one_level_drop_into_a_walk() -> void:
	var step: MoveResult = _step("4 3r", 0)
	assert_that(step.kind).is_equal(MoveResult.Kind.WALK)
	assert_int(step.drop).is_equal(0)


func test_wading_through_shallows_halves_speed() -> void:
	assert_float(_step("1 1", 2).speed_scale).is_equal(TerrainQuery.SHALLOW_SPEED)
	var into_shallows: MoveResult = _step("2 1", 2)
	assert_that(into_shallows.kind).is_equal(MoveResult.Kind.DROP)
	assert_float(into_shallows.speed_scale).is_equal(TerrainQuery.SHALLOW_SPEED)
	assert_float(_step("1 1", 0).speed_scale).is_equal(1.0)


func test_deep_water_means_swimming_at_the_surface() -> void:
	var dive_in: MoveResult = _step("4 0", 4)
	assert_that(dive_in.kind).is_equal(MoveResult.Kind.SWIM)
	assert_int(dive_in.to_level).is_equal(4)
	var high_jump: MoveResult = _step("6 0", 4)
	assert_that(high_jump.kind).is_equal(MoveResult.Kind.SWIM)
	assert_int(high_jump.drop).is_equal(2)
	assert_bool(high_jump.damaging).is_false()
	assert_that(_step("3 0", 4).kind).is_equal(MoveResult.Kind.SWIM)
	assert_that(_step("0 0", 4).kind).is_equal(MoveResult.Kind.SWIM)


func test_leaving_deep_water() -> void:
	assert_that(_step("0 4", 4).kind).is_equal(MoveResult.Kind.WALK)
	var wade_out: MoveResult = _step("0 3", 4)
	assert_that(wade_out.kind).is_equal(MoveResult.Kind.WALK)
	assert_float(wade_out.speed_scale).is_equal(TerrainQuery.SHALLOW_SPEED)
	assert_that(_step("0 5", 4).kind).is_equal(MoveResult.Kind.BLOCKED)
	assert_that(_step("0 5r", 4).kind).is_equal(MoveResult.Kind.WALK)
	assert_that(_step("0 6c", 4).kind).is_equal(MoveResult.Kind.CLIMB)


func test_the_same_street_changes_with_the_water() -> void:
	# A street (0) next to a rooftop (3): swim at St. Aud "flooded", climb-blocked when drained.
	assert_that(_step("3 0", 4).kind).is_equal(MoveResult.Kind.SWIM)
	assert_that(_step("0 3", 4).kind).is_equal(MoveResult.Kind.WALK)
	assert_that(_step("0 3", 0).kind).is_equal(MoveResult.Kind.BLOCKED)
	assert_bool(_step("3 0", 0).damaging).is_true()


func test_stepping_off_the_grid_is_blocked() -> void:
	var query: TerrainQuery = TerrainQuery.new(HeightGrid.from_rows(PackedStringArray(["0 0"])))
	var step: MoveResult = query.check_move(Vector2i(0, 0), Vector2i(-1, 0), 0)
	assert_that(step.kind).is_equal(MoveResult.Kind.BLOCKED)
	assert_str(step.reason).is_equal("out of bounds")


# --- Helpers ---------------------------------------------------------------

func _step(row: String, water_height: int) -> MoveResult:
	var query: TerrainQuery = TerrainQuery.new(HeightGrid.from_rows(PackedStringArray([row])))
	return query.check_move(Vector2i(0, 0), Vector2i(1, 0), water_height)


func _kinds(query: TerrainQuery, water_height: int) -> String:
	var symbols: String = ""
	for x: int in query.grid.size.x:
		match query.cell_kind(Vector2i(x, 0), water_height):
			TerrainQuery.CellKind.DRY:
				symbols += "."
			TerrainQuery.CellKind.SHALLOW:
				symbols += "s"
			TerrainQuery.CellKind.DEEP:
				symbols += "~"
	return symbols
