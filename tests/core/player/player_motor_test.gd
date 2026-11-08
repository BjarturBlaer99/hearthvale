extends GdUnitTestSuite
## PlayerMotor on tiny grids: 8-direction speed, walls, sliding, ledges and stairs.
## Grids use HeightGrid.from_rows(): a height digit, then `s` solid or `r` stairs.

const FRAME: float = 1.0 / 60.0


func test_walks_at_the_same_speed_in_all_eight_directions() -> void:
	var rows: Array = []
	for y: int in 12:
		rows.append(_row("0", 12))
	for direction: Vector2 in PlayerMotor.DIRECTIONS:
		var motor: PlayerMotor = _motor(rows, Vector2i(6, 6))
		var start: Vector2 = motor.position
		_hold(motor, direction, 0.5)
		var message: String = "direction %s" % direction
		assert_float(motor.position.distance_to(start)).override_failure_message(message).is_equal_approx(PlayerMotor.WALK_SPEED * 0.5, 0.6)


func test_analog_input_snaps_to_eight_directions() -> void:
	assert_that(PlayerMotor.snap_to_8(Vector2(0.9, 0.3))).is_equal(Vector2(1, 0))
	assert_that(PlayerMotor.snap_to_8(Vector2(0.6, 0.55))).is_equal(Vector2(0.70710678, 0.70710678))
	assert_that(PlayerMotor.snap_to_8(Vector2(-0.2, -0.95))).is_equal(Vector2(0, -1))
	assert_that(PlayerMotor.snap_to_8(Vector2(0.1, 0.1))).is_equal(Vector2.ZERO)


func test_solid_cells_stop_the_hero_short_of_the_edge() -> void:
	var motor: PlayerMotor = _motor(["0 0 0s 0"], Vector2i(0, 0))
	_hold(motor, Vector2.RIGHT, 1.0)
	assert_float(motor.position.x).is_equal_approx(2.0 * PlayerMotor.TILE - PlayerMotor.BODY_RADIUS, 0.01)
	assert_that(motor.cell).is_equal(Vector2i(1, 0))


func test_cliffs_without_stairs_stop_the_hero_too() -> void:
	var motor: PlayerMotor = _motor(["0 0 2"], Vector2i(0, 0))
	_hold(motor, Vector2.RIGHT, 1.0)
	assert_that(motor.cell).is_equal(Vector2i(1, 0))


func test_walking_diagonally_into_a_wall_slides_along_it() -> void:
	var motor: PlayerMotor = _motor(["0 0 0s", "0 0 0s", "0 0 0s", "0 0 0s"], Vector2i(1, 0))
	var start: Vector2 = motor.position
	_hold(motor, Vector2(1, 1), 0.5)
	assert_float(motor.position.x).is_equal_approx(2.0 * PlayerMotor.TILE - PlayerMotor.BODY_RADIUS, 0.01)
	assert_float(motor.position.y - start.y).is_greater(20.0)


func test_the_map_edge_is_a_wall() -> void:
	var motor: PlayerMotor = _motor(["0 0"], Vector2i(0, 0))
	_hold(motor, Vector2.LEFT, 1.0)
	assert_float(motor.position.x).is_equal_approx(PlayerMotor.BODY_RADIUS, 0.01)


func test_stairs_take_the_hero_up_and_ledges_back_down() -> void:
	var motor: PlayerMotor = _motor(["0 1r 2 2"], Vector2i(0, 0))
	var drops: Array = []
	motor.dropped.connect(func(levels: int) -> void: drops.append(levels))
	_hold(motor, Vector2.RIGHT, 1.0)
	assert_that(motor.cell).is_equal(Vector2i(3, 0))
	assert_int(motor.level).is_equal(2)
	assert_array(drops).override_failure_message("stairs aren't a drop").is_empty()


func test_hopping_down_a_ledge_is_reported() -> void:
	var motor: PlayerMotor = _motor(["3 0 0"], Vector2i(0, 0))
	var drops: Array = []
	motor.dropped.connect(func(levels: int) -> void: drops.append(levels))
	_hold(motor, Vector2.RIGHT, 0.5)
	assert_array(drops).is_equal([3])
	assert_int(motor.level).is_equal(0)
	# One way: the ledge can't be climbed back up.
	_hold(motor, Vector2.LEFT, 1.0)
	assert_that(motor.cell).is_equal(Vector2i(1, 0))


func test_input_sets_facing_and_standing_still_keeps_it() -> void:
	var motor: PlayerMotor = _motor([_row("0", 6)], Vector2i(2, 0))
	_hold(motor, Vector2.LEFT, 0.1)
	_hold(motor, Vector2.ZERO, 0.1)
	assert_that(motor.facing).is_equal(Vector2.LEFT)


func _motor(rows: Array, start: Vector2i) -> PlayerMotor:
	var motor: PlayerMotor = PlayerMotor.new(TerrainQuery.new(HeightGrid.from_rows(PackedStringArray(rows))))
	motor.place(start)
	return motor


func _hold(motor: PlayerMotor, input: Vector2, seconds: float) -> void:
	for i: int in roundi(seconds / FRAME):
		motor.step(input, FRAME)


func _row(token: String, width: int) -> String:
	return (token + " ").repeat(width).strip_edges()
