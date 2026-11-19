extends GdUnitTestSuite
## The blow of a stroke (tool polish, step 2): a stroke given a blow has the motor say `struck`
## once, when it is that far through, or as it ends early; a stroke without one never does; and
## the blow changes nothing of how long the stroke lasts.

const FRAME: float = 1.0 / 60.0

## What each blow said (a lambda cannot change a number of the suite's, but can add to this).
var _blows: Array[float] = []


func before_test() -> void:
	_blows.clear()


func test_the_blow_comes_once_at_its_point() -> void:
	var motor: PlayerMotor = _motor()
	motor.struck.connect(func() -> void: _blows.append((motor.state as PlayerAttackState).progress()))
	assert_bool(motor.attack(Vector2i.RIGHT, 0.4, 0.35)).is_true()
	assert_int(_blows.size()).override_failure_message("not as the stroke begins").is_equal(0)
	while motor.is_attacking():
		motor.step(Vector2.ZERO, FRAME)
	assert_int(_blows.size()).is_equal(1)
	assert_float(_blows[0]).is_between(0.35, 0.35 + FRAME / 0.4 + 0.001)


func test_a_stroke_cut_short_still_comes_to_its_blow() -> void:
	var motor: PlayerMotor = _motor()
	motor.struck.connect(func() -> void: _blows.append(0.0))
	motor.attack(Vector2i.RIGHT, 0.4, 0.35)
	motor.step(Vector2.ZERO, FRAME)
	assert_bool(motor.take_hit(Vector2(40, 0))).is_true()
	assert_int(_blows.size()).override_failure_message("a hit before the blow").is_equal(1)
	for i: int in 60:
		motor.step(Vector2.ZERO, FRAME)
	assert_int(_blows.size()).override_failure_message("and never again").is_equal(1)


func test_a_swing_has_no_blow_and_the_blow_lengthens_nothing() -> void:
	var with_blow: PlayerMotor = _motor()
	var without: PlayerMotor = _motor()
	without.struck.connect(func() -> void: _blows.append(0.0))
	with_blow.attack(Vector2i.RIGHT, 0.4, 0.35)
	without.attack(Vector2i.RIGHT, 0.4)
	var steps: int = 0
	while with_blow.is_attacking() or without.is_attacking():
		assert_bool(with_blow.is_attacking()).is_equal(without.is_attacking())
		with_blow.step(Vector2.ZERO, FRAME)
		without.step(Vector2.ZERO, FRAME)
		steps += 1
	assert_int(_blows.size()).override_failure_message("a stroke with no blow never says one").is_equal(0)
	assert_int(steps).override_failure_message("the stroke lasts its 0.4 s").is_between(roundi(0.4 / FRAME), roundi(0.4 / FRAME) + 1)


func _motor() -> PlayerMotor:
	var rows: Array = []
	for i: int in 6:
		rows.append(("0 ").repeat(6).strip_edges())
	var motor: PlayerMotor = PlayerMotor.new(TerrainQuery.new(HeightGrid.from_rows(PackedStringArray(rows))))
	motor.place(Vector2i(2, 2))
	return motor
