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


func test_sprinting_walks_faster_in_every_direction() -> void:
	for direction: Vector2 in PlayerMotor.DIRECTIONS:
		var motor: PlayerMotor = _motor(_open_rows(30), Vector2i(15, 15))
		motor.sprinting = true
		var start: Vector2 = motor.position
		_hold(motor, direction, 0.5)
		assert_float(motor.position.distance_to(start)).override_failure_message("sprinting %s" % direction).is_equal_approx(PlayerMotor.SPRINT_SPEED * 0.5, 0.5)
	var walker: PlayerMotor = _motor(_open_rows(30), Vector2i(15, 15))
	var from: Vector2 = walker.position
	_hold(walker, Vector2.RIGHT, 0.5)
	assert_float(walker.position.distance_to(from)).override_failure_message("walking").is_equal_approx(PlayerMotor.WALK_SPEED * 0.5, 0.5)


func test_sprint_doesnt_move_a_hero_mid_swing() -> void:
	var motor: PlayerMotor = _motor([_row("0", 8)], Vector2i(3, 0))
	motor.sprinting = true
	var start: Vector2 = motor.position
	motor.attack(Vector2i.DOWN, 0.3)
	_hold(motor, Vector2.RIGHT, 0.2)
	assert_that(motor.position).is_equal(start)


func test_a_swing_roots_the_hero_and_keeps_their_facing_until_it_ends() -> void:
	var motor: PlayerMotor = _motor([_row("0", 8)], Vector2i(3, 0))
	var start: Vector2 = motor.position
	assert_bool(motor.attack(Vector2i.DOWN, 0.3)).is_true()
	assert_bool(motor.attack(Vector2i.DOWN, 0.3)).override_failure_message("one swing at a time").is_false()
	_hold(motor, Vector2.RIGHT, 0.2)
	assert_that(motor.position).override_failure_message("no walking mid-swing").is_equal(start)
	assert_that(motor.facing).is_equal(Vector2.DOWN)
	assert_that(motor.state_name).is_equal(PlayerMotor.ATTACK)
	_hold(motor, Vector2.RIGHT, 0.15)
	assert_that(motor.state_name).is_equal(PlayerMotor.GROUND)
	assert_float(motor.position.x).is_greater(start.x)


func test_a_hit_knocks_the_hero_back_and_makes_them_invincible_for_a_while() -> void:
	var motor: PlayerMotor = _motor([_row("0", 10)], Vector2i(2, 0))
	var start: Vector2 = motor.position
	assert_bool(motor.take_hit(Vector2(32, 0))).is_true()
	assert_that(motor.state_name).is_equal(PlayerMotor.HURT)
	# The push lasts 32 / KNOCKBACK_SPEED = 0.2 s; input does nothing meanwhile.
	_hold(motor, Vector2.LEFT, 0.15)
	assert_float(motor.position.x).override_failure_message("pushed, input ignored").is_equal_approx(start.x + 24.0, 0.01)
	_hold(motor, Vector2.ZERO, 0.1)
	assert_float(motor.position.x).override_failure_message("pushed 32 px in all").is_equal_approx(start.x + 32.0, 0.01)
	assert_that(motor.state_name).is_equal(PlayerMotor.GROUND)
	assert_bool(motor.take_hit(Vector2(32, 0))).override_failure_message("still invincible").is_false()
	_hold(motor, Vector2.ZERO, PlayerMotor.INVINCIBLE_TIME)
	assert_bool(motor.is_invincible()).is_false()
	assert_bool(motor.take_hit(Vector2(-16, 0))).is_true()


func test_knockback_stops_at_a_wall() -> void:
	var motor: PlayerMotor = _motor(["0 0 0s"], Vector2i(1, 0))
	motor.take_hit(Vector2(40, 0))
	_hold(motor, Vector2.ZERO, 0.4)
	assert_that(motor.cell).is_equal(Vector2i(1, 0))
	assert_float(motor.position.x).is_equal_approx(2.0 * PlayerMotor.TILE - PlayerMotor.BODY_RADIUS, 0.01)


func test_a_fallen_hero_lies_still_until_placed() -> void:
	var motor: PlayerMotor = _motor([_row("0", 6)], Vector2i(2, 0))
	motor.die()
	var at: Vector2 = motor.position
	_hold(motor, Vector2.RIGHT, 0.3)
	assert_that(motor.position).is_equal(at)
	assert_bool(motor.take_hit(Vector2(16, 0))).is_false()
	assert_bool(motor.attack(Vector2i.DOWN, 0.3)).is_false()
	motor.place(Vector2i(4, 0))
	assert_that(motor.state_name).is_equal(PlayerMotor.GROUND)


func _motor(rows: Array, start: Vector2i) -> PlayerMotor:
	var motor: PlayerMotor = PlayerMotor.new(TerrainQuery.new(HeightGrid.from_rows(PackedStringArray(rows))))
	motor.place(start)
	return motor


func _hold(motor: PlayerMotor, input: Vector2, seconds: float) -> void:
	for i: int in roundi(seconds / FRAME):
		motor.step(input, FRAME)


func _open_rows(count: int) -> Array:
	var rows: Array = []
	for i: int in count:
		rows.append(_row("0", 30))
	return rows


func _row(token: String, width: int) -> String:
	return (token + " ").repeat(width).strip_edges()
