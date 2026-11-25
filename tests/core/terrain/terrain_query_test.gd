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


func test_sealed_cells_stop_flying_things_too() -> void:
	var query: TerrainQuery = TerrainQuery.new(HeightGrid.from_rows(PackedStringArray(["0 0 0"])))
	assert_bool(query.check_flight(Vector2i(0, 0), Vector2i(1, 0)).is_allowed()).is_true()
	query.set_sealed(Vector2i(1, 0))
	assert_bool(query.is_sealed(Vector2i(1, 0))).is_true()
	assert_bool(query.check_flight(Vector2i(0, 0), Vector2i(1, 0)).is_allowed()).override_failure_message("a closed door stops a bat").is_false()
	query.set_sealed(Vector2i(1, 0), false)
	assert_bool(query.check_flight(Vector2i(0, 0), Vector2i(1, 0)).is_allowed()).is_true()


func test_a_pit_is_a_drop_for_walkers_and_nothing_to_fliers() -> void:
	var terrain: TerrainQuery = TerrainQuery.new(HeightGrid.from_rows(PackedStringArray(["0 0 0"])))
	terrain.set_pit(Vector2i(1, 0))
	assert_bool(terrain.is_pit(Vector2i(1, 0))).is_true()
	var into: MoveResult = terrain.check_move(Vector2i(0, 0), Vector2i(1, 0))
	assert_that(into.kind).override_failure_message("level floor, but a pit: a drop").is_equal(MoveResult.Kind.DROP)
	assert_int(into.drop).is_equal(1)
	assert_that(terrain.check_flight(Vector2i(0, 0), Vector2i(1, 0)).kind).override_failure_message("bats cross").is_equal(MoveResult.Kind.WALK)
	assert_that(terrain.check_move(Vector2i(1, 0), Vector2i(2, 0)).kind).override_failure_message("out of a pit is level ground").is_equal(MoveResult.Kind.WALK)
	var walker: GridBody = GridBody.new(terrain)
	walker.allow_drops = false
	walker.place(Vector2i(0, 0))
	assert_bool(walker.can_enter(Vector2i(1, 0))).override_failure_message("enemies keep out").is_false()
	var hero: GridBody = GridBody.new(terrain)
	hero.place(Vector2i(0, 0))
	assert_bool(hero.can_enter(Vector2i(1, 0))).override_failure_message("the hero can fall in").is_true()


func test_a_filled_pit_is_floor_again() -> void:
	var terrain: TerrainQuery = TerrainQuery.new(HeightGrid.from_rows(PackedStringArray(["0 0 0"])))
	terrain.set_pit(Vector2i(1, 0))
	terrain.set_pit(Vector2i(1, 0), false)
	assert_bool(terrain.is_pit(Vector2i(1, 0))).is_false()
	assert_that(terrain.check_move(Vector2i(0, 0), Vector2i(1, 0)).kind).is_equal(MoveResult.Kind.WALK)


func test_a_pit_on_higher_ground_is_still_out_of_reach() -> void:
	var terrain: TerrainQuery = TerrainQuery.new(HeightGrid.from_rows(PackedStringArray(["0 1"])))
	terrain.set_pit(Vector2i(1, 0))
	assert_that(terrain.check_move(Vector2i(0, 0), Vector2i(1, 0)).kind).is_equal(MoveResult.Kind.BLOCKED)


func test_a_blow_is_stopped_by_walls_doors_and_higher_ground() -> void:
	var terrain: TerrainQuery = TerrainQuery.new(HeightGrid.from_rows(PackedStringArray(["0 0s 0 1 1r 0"])))
	assert_bool(terrain.stops_blow(Vector2i(0, 0), 0)).override_failure_message("open floor").is_false()
	assert_bool(terrain.stops_blow(Vector2i(1, 0), 0)).override_failure_message("a wall").is_true()
	terrain.set_sealed(Vector2i(2, 0))
	assert_bool(terrain.stops_blow(Vector2i(2, 0), 0)).override_failure_message("a closed door").is_true()
	assert_bool(terrain.stops_blow(Vector2i(3, 0), 0)).override_failure_message("a ledge's face, struck from below").is_true()
	assert_bool(terrain.stops_blow(Vector2i(3, 0), 1)).override_failure_message("level with him").is_false()
	assert_bool(terrain.stops_blow(Vector2i(5, 0), 1)).override_failure_message("lower ground").is_false()
	assert_bool(terrain.stops_blow(Vector2i(4, 0), 0)).override_failure_message("stairs").is_false()
	assert_bool(terrain.stops_blow(Vector2i(9, 0), 0)).override_failure_message("off the map").is_true()
	terrain.set_pit(Vector2i(0, 0))
	terrain.set_occupied(Vector2i(5, 0))
	assert_bool(terrain.stops_blow(Vector2i(0, 0), 0)).override_failure_message("a pit").is_false()
	assert_bool(terrain.stops_blow(Vector2i(5, 0), 0)).override_failure_message("someone standing").is_false()
