extends GdUnitTestSuite
## The Iron Warden's brain (H7's boss): it wakes when the hero comes near, stomps after them
## with every blow clinking off, then opens its eye (the tell). Only an arrow in the eye stuns
## it, only a stunned warden can be hurt, and an unanswered gaze ends in a bolt. At half health
## it rages: faster, with three bolts. It keeps to its arena and starts over on reset().

const FRAME: float = 1.0 / 60.0
const WARDEN: Dictionary = {
	"behaviour": "warden", "health": 12, "speed": 22, "sight": 96,
	"boss": {"guard_time": 3.0, "gaze_time": 1.6, "stun_time": 2.5, "rage_at": 6, "rage_speed": 1.5, "weak_point": "arrow"},
}
const FAR_AWAY: Vector2 = Vector2(5000, 5000)


func test_it_sleeps_until_the_hero_comes_near_then_stomps_after_them() -> void:
	var brain: WardenBrain = _warden(Vector2i(10, 10))
	var start: Vector2 = brain.body.position
	_run(brain, FAR_AWAY, 2.0)
	assert_that(brain.state).is_equal(EnemyBrain.IDLE)
	assert_that(brain.body.position).is_equal(start)
	var hero: Vector2 = GridBody.cell_center(Vector2i(10, 15))
	_run(brain, hero, 1.0)
	assert_that(brain.state).is_equal(WardenBrain.GUARD)
	assert_float(brain.distance_to(hero)).override_failure_message("closing in").is_less(start.distance_to(hero) - 15.0)


func test_blows_clink_off_its_iron_unless_it_is_stunned() -> void:
	var brain: WardenBrain = _warden(Vector2i(10, 10))
	var clinks: Array[int] = [0]
	brain.clinked.connect(func() -> void: clinks[0] += 1)
	var hero: Vector2 = GridBody.cell_center(Vector2i(10, 14))
	_run(brain, hero, 0.5)
	for kind: StringName in [&"sword", &"arrow", &"bomb"]:
		assert_bool(brain.take_hit(2, Vector2.ZERO, kind)).override_failure_message("%s while guarding" % kind).is_false()
	assert_int(brain.health).is_equal(12)
	assert_int(clinks[0]).is_equal(3)


func test_its_eye_opens_for_a_visible_moment_and_an_arrow_stuns_it() -> void:
	var brain: WardenBrain = _warden(Vector2i(10, 10))
	var hero: Vector2 = GridBody.cell_center(Vector2i(10, 14))
	_run_until(brain, hero, WardenBrain.GAZE, 4.0)
	assert_that(brain.state).override_failure_message("guarding gives way to a gaze").is_equal(WardenBrain.GAZE)
	assert_float(brain.eye_open()).is_less(0.5)
	_run(brain, hero, WardenBrain.EYE_OPENING + FRAME)
	assert_float(brain.eye_open()).override_failure_message("the eye is open: the tell").is_equal(1.0)
	assert_bool(brain.take_hit(2, Vector2.ZERO, &"sword")).override_failure_message("the sword can't reach the eye").is_false()
	assert_that(brain.state).is_equal(WardenBrain.GAZE)
	assert_bool(brain.take_hit(2, Vector2.ZERO, &"arrow")).is_true()
	assert_bool(brain.is_stunned()).override_failure_message("an arrow in the eye").is_true()
	assert_int(brain.health).override_failure_message("stunning doesn't hurt it").is_equal(12)


func test_stunned_it_can_be_hurt_with_a_flinch_between_blows_then_it_rises() -> void:
	var brain: WardenBrain = _stunned_warden()
	assert_bool(brain.take_hit(2, Vector2.ZERO, &"sword")).is_true()
	assert_int(brain.health).is_equal(10)
	assert_bool(brain.take_hit(2, Vector2.ZERO, &"sword")).override_failure_message("flinching").is_false()
	var hero: Vector2 = GridBody.cell_center(Vector2i(10, 14))
	_run(brain, hero, WardenBrain.FLINCH_TIME + FRAME)
	assert_bool(brain.take_hit(2, Vector2.ZERO, &"arrow")).override_failure_message("arrows hurt too").is_true()
	assert_int(brain.health).is_equal(8)
	_run(brain, hero, 2.5)
	assert_that(brain.state).override_failure_message("back on its feet").is_equal(WardenBrain.GUARD)
	assert_bool(brain.take_hit(2, Vector2.ZERO, &"sword")).is_false()


func test_an_unanswered_gaze_ends_in_a_bolt_at_the_hero() -> void:
	var brain: WardenBrain = _warden(Vector2i(10, 10))
	var shots: Array[Vector2] = []
	brain.shot.connect(func(direction: Vector2) -> void: shots.append(direction))
	var hero: Vector2 = GridBody.cell_center(Vector2i(10, 15))
	_run_until(brain, hero, WardenBrain.GAZE, 4.0)
	assert_int(shots.size()).is_equal(0)
	_run_until(brain, hero, WardenBrain.GUARD, 2.0)
	assert_int(shots.size()).is_equal(1)
	assert_float(shots[0].angle_to(brain.toward(hero))).is_equal_approx(0.0, 0.05)


func test_at_half_health_it_rages_faster_with_three_bolts() -> void:
	var brain: WardenBrain = _warden(Vector2i(4, 10))
	brain.health = 6
	assert_bool(brain.is_raging()).is_true()
	var calm: WardenBrain = _warden(Vector2i(4, 10))
	var hero: Vector2 = GridBody.cell_center(Vector2i(9, 10))
	_run(brain, hero, 1.0)
	_run(calm, hero, 1.0)
	assert_float(brain.body.position.x).override_failure_message("stomps faster").is_greater(calm.body.position.x + 8.0)
	var shots: Array[Vector2] = []
	brain.shot.connect(func(direction: Vector2) -> void: shots.append(direction))
	_run_until(brain, hero, WardenBrain.GAZE, 4.0)
	_run_until(brain, hero, WardenBrain.GUARD, 2.0)
	assert_int(shots.size()).is_equal(3)


func test_it_keeps_to_its_arena() -> void:
	var brain: WardenBrain = _warden(Vector2i(10, 10))
	brain.arena = Rect2(GridBody.cell_center(Vector2i(8, 8)), Vector2(64, 64))
	# Within sight, but beyond the arena's corner.
	var hero: Vector2 = GridBody.cell_center(Vector2i(14, 14))
	for i: int in roundi(12.0 / FRAME):
		brain.step(hero, FRAME)
		assert_bool(brain.arena.grow(0.01).has_point(brain.body.position)).override_failure_message("left its arena at %s" % brain.body.position).is_true()
	assert_float(brain.body.position.x).override_failure_message("it went as far as it may").is_equal_approx(brain.arena.end.x, 0.5)


func test_beaten_it_dies_and_reset_starts_the_fight_over() -> void:
	var brain: WardenBrain = _stunned_warden()
	brain.health = 2
	assert_bool(brain.take_hit(2, Vector2.ZERO, &"sword")).is_true()
	assert_bool(brain.is_dead()).is_true()
	assert_bool(brain.take_hit(2, Vector2.ZERO, &"arrow")).is_false()
	var fresh: WardenBrain = _stunned_warden()
	fresh.take_hit(2, Vector2.ZERO, &"sword")
	_run(fresh, GridBody.cell_center(Vector2i(10, 16)), 1.0)
	fresh.reset()
	assert_int(fresh.health).is_equal(12)
	assert_that(fresh.state).is_equal(EnemyBrain.IDLE)
	assert_that(fresh.body.position).is_equal(fresh.home)


func _warden(at: Vector2i) -> WardenBrain:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 3
	var body: GridBody = GridBody.new(TerrainQuery.new(HeightGrid.from_rows(PackedStringArray(_open(20)))))
	body.place(at)
	return EnemyBrains.create(WARDEN, body, rng) as WardenBrain


## A warden mid-fight, its eye just struck by an arrow.
func _stunned_warden() -> WardenBrain:
	var brain: WardenBrain = _warden(Vector2i(10, 10))
	_run_until(brain, GridBody.cell_center(Vector2i(10, 14)), WardenBrain.GAZE, 4.0)
	brain.take_hit(2, Vector2.ZERO, &"arrow")
	return brain


func _run(brain: EnemyBrain, hero: Vector2, seconds: float) -> void:
	for i: int in roundi(seconds / FRAME):
		brain.step(hero, FRAME)


## Steps until it enters `state` (or `seconds` pass).
func _run_until(brain: EnemyBrain, hero: Vector2, state: StringName, seconds: float) -> void:
	for i: int in roundi(seconds / FRAME):
		brain.step(hero, FRAME)
		if brain.state == state:
			return


func _open(size: int) -> Array:
	var rows: Array = []
	for i: int in size:
		rows.append(("0 ").repeat(size).strip_edges())
	return rows
