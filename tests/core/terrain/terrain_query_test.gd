extends GdUnitTestSuite
## TerrainQuery: classic top-down movement rules. Each test steps from the first cell of a
## one-row grid to the second.


func test_walking_on_level_ground() -> void:
	var step: MoveResult = _step("2 2")
	assert_that(step.kind).is_equal(MoveResult.Kind.WALK)
	assert_int(step.to_level).is_equal(2)


func test_stairs_go_up_or_down_one_level() -> void:
	assert_that(_step("1 2r").kind).is_equal(MoveResult.Kind.WALK)
	assert_that(_step("1r 2").kind).is_equal(MoveResult.Kind.WALK)
	assert_that(_step("2r 1").kind).is_equal(MoveResult.Kind.WALK)
	assert_int(_step("2r 1").drop).is_equal(0)


func test_higher_ground_without_stairs_is_blocked() -> void:
	var step: MoveResult = _step("1 2")
	assert_that(step.kind).is_equal(MoveResult.Kind.BLOCKED)
	assert_str(step.reason).contains("no stairs")
	assert_that(_step("0 3r").kind).override_failure_message("stairs only bridge one level").is_equal(MoveResult.Kind.BLOCKED)


func test_ledges_can_be_hopped_down_from_any_height() -> void:
	var small: MoveResult = _step("1 0")
	assert_that(small.kind).is_equal(MoveResult.Kind.DROP)
	assert_int(small.drop).is_equal(1)
	var cliff: MoveResult = _step("5 0")
	assert_that(cliff.kind).is_equal(MoveResult.Kind.DROP)
	assert_int(cliff.drop).is_equal(5)
	assert_int(cliff.to_level).is_equal(0)


func test_solid_cells_are_never_entered() -> void:
	assert_that(_step("0 0s").kind).is_equal(MoveResult.Kind.BLOCKED)
	assert_that(_step("2 0s").kind).override_failure_message("not even by hopping down").is_equal(MoveResult.Kind.BLOCKED)
	assert_str(_step("0 0s").reason).is_equal("solid")


func test_stepping_off_the_map_is_blocked() -> void:
	var query: TerrainQuery = TerrainQuery.new(HeightGrid.from_rows(PackedStringArray(["0 0"])))
	var step: MoveResult = query.check_move(Vector2i(0, 0), Vector2i(-1, 0))
	assert_that(step.kind).is_equal(MoveResult.Kind.BLOCKED)
	assert_str(step.reason).is_equal("out of bounds")


func test_occupied_cells_are_blocked_until_freed() -> void:
	var query: TerrainQuery = TerrainQuery.new(HeightGrid.from_rows(PackedStringArray(["0 0"])))
	query.set_occupied(Vector2i(1, 0))
	var step: MoveResult = query.check_move(Vector2i(0, 0), Vector2i(1, 0))
	assert_that(step.kind).is_equal(MoveResult.Kind.BLOCKED)
	assert_str(step.reason).is_equal("occupied")
	query.set_occupied(Vector2i(1, 0), false)
	assert_that(query.check_move(Vector2i(0, 0), Vector2i(1, 0)).kind).is_equal(MoveResult.Kind.WALK)


func _step(row: String) -> MoveResult:
	var query: TerrainQuery = TerrainQuery.new(HeightGrid.from_rows(PackedStringArray([row])))
	return query.check_move(Vector2i(0, 0), Vector2i(1, 0))
