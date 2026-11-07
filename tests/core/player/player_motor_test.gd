extends GdUnitTestSuite
## PlayerMotor on tiny grids: 8-direction speed, walls, wading, swimming, climbing with
## stamina, drops, sprint, and how rising or falling water changes the player's state.
## Grids use HeightGrid.from_rows(): a height digit, then `c` climbable or `r` ramp.

const FRAME: float = 1.0 / 60.0


# --- Walking ---------------------------------------------------------------

func test_walks_at_the_same_speed_in_all_eight_directions() -> void:
	var rows: Array = []
	for y: int in 12:
		rows.append(_open_row(12))
	for direction: Vector2 in PlayerMotor.DIRECTIONS:
		var motor: PlayerMotor = _motor(rows, 0, Vector2i(6, 6))
		var start: Vector2 = motor.position
		_hold(motor, direction, 0.5, false)
		var message: String = "direction %s" % direction
		assert_float(motor.position.distance_to(start)).override_failure_message(message).is_equal_approx(PlayerMotor.WALK_SPEED * 0.5, 0.6)


func test_analog_input_snaps_to_eight_directions() -> void:
	assert_that(PlayerMotor.snap_to_8(Vector2(0.9, 0.3))).is_equal(Vector2(1, 0))
	assert_that(PlayerMotor.snap_to_8(Vector2(0.6, 0.55))).is_equal(Vector2(0.70710678, 0.70710678))
	assert_that(PlayerMotor.snap_to_8(Vector2(-0.2, -0.95))).is_equal(Vector2(0, -1))
	assert_that(PlayerMotor.snap_to_8(Vector2(0.1, 0.1))).is_equal(Vector2.ZERO)


func test_walls_stop_the_player_short_of_the_edge() -> void:
	var motor: PlayerMotor = _motor(["0 0 3 0"], 0, Vector2i(0, 0))
	_hold(motor, Vector2.RIGHT, 1.0, false)
	assert_float(motor.position.x).is_equal_approx(2.0 * PlayerMotor.TILE - PlayerMotor.BODY_RADIUS, 0.01)
	assert_that(motor.cell).is_equal(Vector2i(1, 0))
	assert_that(motor.state_name).is_equal(PlayerMotor.GROUND)


func test_walking_diagonally_into_a_wall_slides_along_it() -> void:
	var motor: PlayerMotor = _motor(["0 0 3", "0 0 3", "0 0 3", "0 0 3"], 0, Vector2i(1, 0))
	var start: Vector2 = motor.position
	_hold(motor, Vector2(1, 1), 0.5, false)
	assert_float(motor.position.x).is_equal_approx(2.0 * PlayerMotor.TILE - PlayerMotor.BODY_RADIUS, 0.01)
	assert_float(motor.position.y - start.y).is_greater(20.0)


func test_the_district_edge_is_a_wall() -> void:
	var motor: PlayerMotor = _motor(["0 0"], 0, Vector2i(0, 0))
	_hold(motor, Vector2.LEFT, 1.0, false)
	assert_float(motor.position.x).is_equal_approx(PlayerMotor.BODY_RADIUS, 0.01)


func test_shallows_halve_walking_speed() -> void:
	var dry: PlayerMotor = _motor([_row("1", 8)], 0, Vector2i(0, 0))
	var wading: PlayerMotor = _motor([_row("1", 8)], 2, Vector2i(0, 0))
	var start: float = dry.position.x
	_hold(dry, Vector2.RIGHT, 0.5, false)
	_hold(wading, Vector2.RIGHT, 0.5, false)
	assert_float(dry.position.x - start).is_equal_approx(PlayerMotor.WALK_SPEED * 0.5, 0.6)
	assert_float(wading.position.x - start).is_equal_approx(PlayerMotor.WALK_SPEED * 0.5 * TerrainQuery.SHALLOW_SPEED, 0.6)


func test_dropping_down_reports_the_fall() -> void:
	var small: PlayerMotor = _motor(["4 3"], 0, Vector2i(0, 0))
	var small_falls: Array = _record_falls(small)
	_hold(small, Vector2.RIGHT, 0.5, false)
	assert_array(small_falls).is_equal([[1, false]])
	assert_int(small.level).is_equal(3)

	var big: PlayerMotor = _motor(["4 1"], 0, Vector2i(0, 0))
	var big_falls: Array = _record_falls(big)
	_hold(big, Vector2.RIGHT, 0.5, false)
	assert_array(big_falls).is_equal([[3, true]])
	assert_int(big.level).is_equal(1)


# --- Sprint and stamina ----------------------------------------------------

func test_sprinting_is_faster_and_tires_you() -> void:
	var motor: PlayerMotor = _motor([_open_row(20)], 0, Vector2i(0, 0))
	var start: float = motor.position.x
	_hold(motor, Vector2.RIGHT, 0.5, true)
	assert_float(motor.position.x - start).is_equal_approx(PlayerMotor.WALK_SPEED * PlayerMotor.SPRINT_MULTIPLIER * 0.5, 0.6)
	assert_float(motor.stamina).is_equal_approx(PlayerMotor.STAMINA_MAX - PlayerMotor.SPRINT_DRAIN * 0.5, 0.5)


func test_an_exhausted_player_walks_until_stamina_recovers() -> void:
	var motor: PlayerMotor = _motor([_open_row(20)], 0, Vector2i(0, 0))
	motor.stamina = 1.0
	_hold(motor, Vector2.RIGHT, 0.1, true)
	assert_bool(motor.exhausted).is_true()
	var before: float = motor.position.x
	_hold(motor, Vector2.RIGHT, 0.25, true)
	assert_float(motor.position.x - before).is_equal_approx(PlayerMotor.WALK_SPEED * 0.25, 0.6)
	_hold(motor, Vector2.ZERO, 1.0, false)
	assert_bool(motor.can_sprint()).is_true()


# --- Water -----------------------------------------------------------------

func test_walking_into_deep_water_starts_swimming_at_the_surface() -> void:
	var motor: PlayerMotor = _motor(["4 4 0 0 0 0"], 4, Vector2i(0, 0))
	_hold(motor, Vector2.RIGHT, 1.0, false)
	assert_that(motor.state_name).is_equal(PlayerMotor.SWIM)
	assert_int(motor.level).is_equal(4)


func test_swimming_is_slower_than_walking() -> void:
	var motor: PlayerMotor = _motor([_open_row(8)], 4, Vector2i(0, 0))
	var start: float = motor.position.x
	_hold(motor, Vector2.RIGHT, 0.5, true)
	assert_float(motor.position.x - start).is_equal_approx(PlayerMotor.SWIM_SPEED * 0.5, 0.6)


func test_rising_water_lifts_a_walker_into_swimming() -> void:
	var motor: PlayerMotor = _motor(["0 0"], 0, Vector2i(0, 0))
	assert_that(motor.state_name).is_equal(PlayerMotor.GROUND)
	motor.set_water_height(4)
	assert_that(motor.state_name).is_equal(PlayerMotor.SWIM)
	assert_int(motor.level).is_equal(4)


func test_falling_water_strands_a_swimmer_on_a_roof() -> void:
	var motor: PlayerMotor = _motor(["2 0"], 4, Vector2i(0, 0))
	assert_that(motor.state_name).is_equal(PlayerMotor.SWIM)
	motor.set_water_height(2)
	assert_that(motor.state_name).is_equal(PlayerMotor.GROUND)
	assert_int(motor.level).is_equal(2)


# --- Climbing --------------------------------------------------------------

func test_climbing_a_climbable_face_costs_stamina() -> void:
	var motor: PlayerMotor = _motor(["0 0 3c 3"], 0, Vector2i(0, 0))
	var climbed: bool = _hold_until_climb_ends(motor, Vector2.RIGHT, 5.0)
	assert_bool(climbed).is_true()
	assert_that(motor.state_name).is_equal(PlayerMotor.GROUND)
	assert_that(motor.cell).is_equal(Vector2i(2, 0))
	assert_int(motor.level).is_equal(3)
	var climb_cost: float = 3.0 / PlayerMotor.CLIMB_SPEED * PlayerMotor.CLIMB_DRAIN
	assert_float(motor.stamina).is_equal_approx(PlayerMotor.STAMINA_MAX - climb_cost, 1.5)


func test_a_wall_without_ivy_cannot_be_climbed() -> void:
	var motor: PlayerMotor = _motor(["0 0 3"], 0, Vector2i(0, 0))
	_hold(motor, Vector2.RIGHT, 2.0, false)
	assert_that(motor.state_name).is_equal(PlayerMotor.GROUND)
	assert_that(motor.cell).is_equal(Vector2i(1, 0))


func test_brushing_a_climbable_wall_diagonally_does_not_start_a_climb() -> void:
	var motor: PlayerMotor = _motor(["0 0 3c", "0 0 3c", "0 0 3c"], 0, Vector2i(1, 0))
	var states: Array = []
	motor.state_changed.connect(func(state_name: StringName) -> void: states.append(state_name))
	_hold(motor, Vector2(1, 1), 0.5, false)
	assert_bool(states.has(PlayerMotor.CLIMB)).is_false()


func test_pushing_away_climbs_back_down() -> void:
	var motor: PlayerMotor = _motor(["0 0 3c"], 0, Vector2i(0, 0))
	var falls: Array = _record_falls(motor)
	_hold_until_state(motor, Vector2.RIGHT, PlayerMotor.CLIMB, 2.0)
	_hold(motor, Vector2.RIGHT, 0.25, false)
	assert_float(motor.climb_progress()).is_greater(0.1)
	_hold_until_state(motor, Vector2.LEFT, PlayerMotor.GROUND, 1.0)
	assert_that(motor.state_name).is_equal(PlayerMotor.GROUND)
	assert_that(motor.cell).is_equal(Vector2i(1, 0))
	assert_array(falls).is_empty()


func test_running_out_of_stamina_mid_climb_drops_you() -> void:
	var motor: PlayerMotor = _motor(["0 7c"], 0, Vector2i(0, 0))
	motor.stamina = 30.0
	var falls: Array = _record_falls(motor)
	var ended: bool = _hold_until_climb_ends(motor, Vector2.RIGHT, 6.0)
	assert_bool(ended).is_true()
	assert_that(motor.cell).is_equal(Vector2i(0, 0))
	assert_int(motor.level).is_equal(0)
	assert_array(falls).is_equal([[3, true]])


func test_rising_water_ends_a_climb() -> void:
	var motor: PlayerMotor = _motor(["0 0 3c"], 0, Vector2i(0, 0))
	_hold_until_state(motor, Vector2.RIGHT, PlayerMotor.CLIMB, 2.0)
	motor.set_water_height(4)
	assert_that(motor.state_name).is_equal(PlayerMotor.SWIM)
	assert_int(motor.level).is_equal(4)


# --- Helpers ---------------------------------------------------------------

func _motor(rows: Array, water_height: int, start: Vector2i) -> PlayerMotor:
	var grid: HeightGrid = HeightGrid.from_rows(PackedStringArray(rows))
	var motor: PlayerMotor = PlayerMotor.new(TerrainQuery.new(grid), water_height)
	motor.place(start)
	return motor


func _hold(motor: PlayerMotor, input: Vector2, seconds: float, sprint: bool) -> void:
	for i: int in roundi(seconds / FRAME):
		motor.step(input, sprint, FRAME)


func _hold_until_state(motor: PlayerMotor, input: Vector2, state_name: StringName, max_seconds: float) -> void:
	for i: int in roundi(max_seconds / FRAME):
		if motor.state_name == state_name:
			return
		motor.step(input, false, FRAME)


## Holds `input` until a climb has started and ended. Returns false if it never finished.
func _hold_until_climb_ends(motor: PlayerMotor, input: Vector2, max_seconds: float) -> bool:
	var climbing: bool = false
	for i: int in roundi(max_seconds / FRAME):
		motor.step(input, false, FRAME)
		if motor.state_name == PlayerMotor.CLIMB:
			climbing = true
		elif climbing:
			return true
	return false


func _record_falls(motor: PlayerMotor) -> Array:
	var falls: Array = []
	motor.fell.connect(func(levels: int, damaging: bool) -> void: falls.append([levels, damaging]))
	return falls


func _open_row(width: int) -> String:
	return _row("0", width)


func _row(token: String, width: int) -> String:
	return (token + " ").repeat(width).strip_edges()
