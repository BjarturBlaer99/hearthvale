extends GdUnitTestSuite
## The Bogwisp's brain (Willowmere, step 2), on tiny grids: it hangs still until it notices the
## hero, drifts slowly toward him, flares for half a second (the tell) and darts in a straight
## line along the aim it took as the flare began, then rests. Unlit, a blow passes through it;
## lit, two blows of a sword beat it. When the night ends it fades and leaves nothing. It
## drifts over water and walls, and never off the map.

const FRAME: float = 1.0 / 60.0
const WISP: Dictionary = {"behaviour": "wisp", "health": 4, "speed": 22, "sight": 96,
	"wisp": {"reach": 52, "flare": 0.5, "dart_speed": 150, "dart_time": 0.5, "rest": 1.3}}
const FAR_AWAY: Vector2 = Vector2(5000, 5000)
## What the two swords deal (data/items): two blows of either beat a wisp.
const WOODEN: int = 2
const IRON: int = 3


func test_the_wisp_behaviour_has_a_brain_that_drifts() -> void:
	var brain: WispBrain = _wisp(_open(12), Vector2i(6, 6))
	assert_object(brain).is_not_null()
	assert_bool(brain.body.drifting).override_failure_message("water and reeds don't stop it").is_true()
	assert_bool(brain.body.flying).is_true()
	assert_bool(brain.lit).override_failure_message("dark until light is said to reach it").is_false()
	assert_float(brain.flare_time).is_equal(0.5)


func test_the_numbers_fall_back_when_the_data_names_none() -> void:
	var brain: WispBrain = _wisp(_open(12), Vector2i(6, 6), {"behaviour": "wisp", "health": 4, "speed": 22})
	assert_float(brain.reach).is_equal(float(WispBrain.DEFAULTS["reach"]))
	assert_float(brain.flare_time).is_equal(float(WispBrain.DEFAULTS["flare"]))
	assert_float(brain.dart_speed).is_equal(float(WispBrain.DEFAULTS["dart_speed"]))
	assert_float(brain.dart_time).is_equal(float(WispBrain.DEFAULTS["dart_time"]))
	assert_float(brain.rest_time).is_equal(float(WispBrain.DEFAULTS["rest"]))


func test_it_hangs_still_until_it_notices_the_hero() -> void:
	var brain: WispBrain = _wisp(_open(30), Vector2i(15, 15))
	var home: Vector2 = brain.body.position
	_run(brain, FAR_AWAY, 5.0)
	assert_that(brain.state).is_equal(EnemyBrain.IDLE)
	assert_that(brain.body.position).override_failure_message("it doesn't wander").is_equal(home)
	# Just past its sight: still nothing. Inside it: it comes.
	_run(brain, home + Vector2(97, 0), 1.0)
	assert_that(brain.state).is_equal(EnemyBrain.IDLE)
	brain.step(home + Vector2(95, 0), FRAME)
	assert_that(brain.state).is_equal(EnemyBrain.CHASE)


func test_it_drifts_slowly_toward_him() -> void:
	var brain: WispBrain = _wisp(_open(30), Vector2i(5, 15))
	var hero: Vector2 = brain.body.position + Vector2(90, 0)
	var before: Vector2 = brain.body.position
	_run(brain, hero, 1.0)
	assert_that(brain.state).is_equal(EnemyBrain.CHASE)
	var moved: Vector2 = brain.body.position - before
	assert_float(moved.x).override_failure_message("a second at 22 px a second").is_equal_approx(22.0, 1.0)
	assert_float(moved.y).is_equal_approx(0.0, 0.01)
	assert_float(moved.x).override_failure_message("slower than a walk: the hero walks about 70").is_less(40.0)


func test_within_reach_it_flares_for_half_a_second_then_darts_straight_then_rests() -> void:
	var brain: WispBrain = _wisp(_open(40), Vector2i(10, 20))
	var states: Array[StringName] = []
	brain.state_changed.connect(func(state: StringName) -> void: states.append(state))
	var start: Vector2 = brain.body.position
	var hero: Vector2 = start + Vector2(40, 0)
	brain.step(hero, FRAME)
	brain.step(hero, FRAME)
	assert_that(brain.state).override_failure_message("he is within reach: it flares").is_equal(WispBrain.FLARE)
	assert_bool(brain.is_flaring()).is_true()
	assert_that(brain.aim).is_equal(Vector2.RIGHT)
	# The tell: it stays where it is for the half second, wherever he goes.
	var flared_at: Vector2 = brain.body.position
	var frames: int = 0
	while brain.is_flaring() and frames < 200:
		brain.step(hero + Vector2(0, 60), FRAME)
		frames += 1
	assert_float(frames * FRAME).override_failure_message("half a second of warning").is_equal_approx(0.5, 0.03)
	assert_that(brain.body.position).override_failure_message("still while it flares").is_equal(flared_at)
	assert_bool(brain.is_darting()).is_true()
	# The dart: along the aim it took, though he has stepped aside.
	var dart_frames: int = 0
	while brain.is_darting() and dart_frames < 200:
		brain.step(hero + Vector2(0, 60), FRAME)
		dart_frames += 1
		assert_float(brain.body.position.y).override_failure_message("a straight line").is_equal_approx(flared_at.y, 0.01)
	var darted: float = brain.body.position.x - flared_at.x
	assert_float(dart_frames * FRAME).is_equal_approx(0.5, 0.03)
	assert_float(darted).override_failure_message("half a second at 150 px a second").is_equal_approx(75.0, 4.0)
	assert_float(darted).override_failure_message("past where he stood").is_greater(40.0)
	assert_that(brain.state).is_equal(WispBrain.REST)
	# It rests where it stopped, then drifts after him again.
	var rested_at: Vector2 = brain.body.position
	_run(brain, FAR_AWAY, 1.0)
	assert_that(brain.state).is_equal(WispBrain.REST)
	assert_that(brain.body.position).is_equal(rested_at)
	_run(brain, rested_at + Vector2(0, 70), 0.5)
	assert_that(brain.state).is_equal(EnemyBrain.CHASE)
	assert_array(states.slice(0, 5)).is_equal([EnemyBrain.CHASE, WispBrain.FLARE, WispBrain.DART, WispBrain.REST, EnemyBrain.CHASE])


func test_a_step_aside_during_the_flare_takes_him_out_of_the_darts_way() -> void:
	var brain: WispBrain = _wisp(_open(40), Vector2i(10, 20))
	var hero: Vector2 = brain.body.position + Vector2(40, 0)
	_run(brain, hero, 2.0 * FRAME)
	assert_bool(brain.is_flaring()).is_true()
	# He walks two cells to the side while it flares; the dart passes where he was.
	var aside: Vector2 = hero + Vector2(0, 32)
	var nearest: float = 9999.0
	for i: int in 120:
		brain.step(aside, FRAME)
		nearest = minf(nearest, brain.body.position.distance_to(aside))
	assert_float(nearest).override_failure_message("it never came within a touch of him").is_greater(20.0)


func test_unlit_a_blow_passes_through_it() -> void:
	var brain: WispBrain = _wisp(_open(12), Vector2i(6, 6))
	brain.lit = false
	assert_bool(brain.is_solid()).is_false()
	for i: int in 5:
		assert_bool(brain.take_hit(IRON, Vector2(30, 0), &"sword")).override_failure_message("the sword passes through").is_false()
	assert_int(brain.health).override_failure_message("untouched").is_equal(4)
	assert_that(brain.body.position).override_failure_message("not even pushed").is_equal(GridBody.cell_center(Vector2i(6, 6)))
	assert_that(brain.state).is_not_equal(EnemyBrain.HURT)
	# An arrow or a bomb fares no better in the dark.
	assert_bool(brain.take_hit(4, Vector2.ZERO, &"bomb")).is_false()
	assert_bool(brain.take_hit(2, Vector2.ZERO, &"arrow")).is_false()


func test_lit_two_blows_of_either_sword_beat_it() -> void:
	for damage: int in [WOODEN, IRON]:
		var brain: WispBrain = _wisp(_open(12), Vector2i(6, 6))
		brain.lit = true
		assert_bool(brain.is_solid()).is_true()
		assert_bool(brain.take_hit(damage, Vector2(20, 0), &"sword")).override_failure_message("the first blow lands").is_true()
		assert_bool(brain.is_dead()).override_failure_message("one blow of %d is not enough" % damage).is_false()
		assert_that(brain.state).is_equal(EnemyBrain.HURT)
		assert_bool(brain.take_hit(damage, Vector2(20, 0), &"sword")).override_failure_message("not again while it reels").is_false()
		_run(brain, FAR_AWAY, EnemyBrain.HURT_TIME + 0.2)
		assert_bool(brain.take_hit(damage, Vector2(20, 0), &"sword")).override_failure_message("the second blow lands").is_true()
		assert_bool(brain.is_dead()).override_failure_message("two blows of %d beat it" % damage).is_true()


func test_it_turns_solid_and_back_as_the_light_comes_and_goes() -> void:
	var brain: WispBrain = _wisp(_open(12), Vector2i(6, 6))
	brain.lit = false
	assert_bool(brain.take_hit(WOODEN, Vector2.ZERO, &"sword")).is_false()
	brain.lit = true
	assert_bool(brain.take_hit(WOODEN, Vector2.ZERO, &"sword")).is_true()
	_run(brain, FAR_AWAY, EnemyBrain.HURT_TIME + 0.2)
	brain.lit = false
	assert_bool(brain.take_hit(WOODEN, Vector2.ZERO, &"sword")).override_failure_message("out of the light it is a light again").is_false()
	assert_int(brain.health).is_equal(2)


func test_when_the_night_ends_it_fades_and_is_gone_without_being_beaten() -> void:
	var brain: WispBrain = _wisp(_open(40), Vector2i(10, 20))
	var hero: Vector2 = brain.body.position + Vector2(90, 0)
	_run(brain, hero, 0.5)
	assert_that(brain.state).is_equal(EnemyBrain.CHASE)
	brain.fade()
	assert_bool(brain.is_gone()).is_true()
	assert_bool(brain.is_dead()).override_failure_message("faded, not beaten: nothing drops").is_false()
	assert_bool(brain.is_solid()).is_false()
	var faded_at: Vector2 = brain.body.position
	_run(brain, hero, 3.0)
	assert_that(brain.body.position).override_failure_message("it does nothing more").is_equal(faded_at)
	assert_that(brain.state).is_equal(WispBrain.GONE)
	assert_bool(brain.take_hit(IRON, Vector2.ZERO, &"sword")).is_false()
	# A beaten one is beaten: fading doesn't undo it.
	var beaten: WispBrain = _wisp(_open(12), Vector2i(6, 6))
	beaten.lit = true
	beaten.take_hit(9, Vector2.ZERO, &"sword")
	beaten.fade()
	assert_bool(beaten.is_dead()).is_true()
	assert_bool(beaten.is_gone()).is_false()


func test_it_gives_up_when_he_is_far_and_drifts_back_to_where_it_rose() -> void:
	var brain: WispBrain = _wisp(_open(40), Vector2i(10, 20))
	var home: Vector2 = brain.home
	_run(brain, home + Vector2(80, 0), 1.0)
	assert_that(brain.state).is_equal(EnemyBrain.CHASE)
	assert_float(brain.body.position.x).is_greater(home.x)
	_run(brain, FAR_AWAY, 0.1)
	assert_that(brain.state).override_failure_message("lost him").is_equal(EnemyBrain.WANDER)
	_run(brain, FAR_AWAY, 3.0)
	assert_that(brain.state).override_failure_message("home, and still again").is_equal(EnemyBrain.IDLE)
	assert_float(brain.body.position.distance_to(home)).is_less(3.0)


func test_it_drifts_over_water_and_walls_but_never_off_the_map() -> void:
	# A wall of solid cells between it and the hero ("s"): a bat would stop, a wisp doesn't.
	var rows: Array = _rows("0 0 0 0s 0s 0s 0 0 0 0", 9)
	var brain: WispBrain = _wisp(rows, Vector2i(1, 4))
	var hero: Vector2 = GridBody.cell_center(Vector2i(7, 4))
	var crossed: bool = false
	for i: int in roundi(8.0 / FRAME):
		brain.step(hero, FRAME)
		crossed = crossed or brain.body.cell.x >= 6
	assert_bool(crossed).override_failure_message("through the solid cells to him").is_true()
	# Darting at the map's edge it stops there.
	var edge: WispBrain = _wisp(_open(10), Vector2i(8, 5))
	var beyond: Vector2 = edge.body.position + Vector2(40, 0)
	for i: int in roundi(6.0 / FRAME):
		edge.step(beyond, FRAME)
		assert_bool(edge.body.cell.x >= 0 and edge.body.cell.x < 10 and edge.body.cell.y >= 0 and edge.body.cell.y < 10).override_failure_message("inside the map").is_true()
		assert_float(edge.body.position.x).is_less(160.0)


func _wisp(rows: Array, at: Vector2i, data: Dictionary = WISP) -> WispBrain:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 7
	var body: GridBody = GridBody.new(TerrainQuery.new(HeightGrid.from_rows(PackedStringArray(rows))))
	body.place(at)
	return EnemyBrains.create(data, body, rng) as WispBrain


func _run(brain: EnemyBrain, hero: Vector2, seconds: float) -> void:
	for i: int in roundi(seconds / FRAME):
		brain.step(hero, FRAME)


func _open(size: int) -> Array:
	return _rows(("0 ").repeat(size).strip_edges(), size)


func _rows(row: String, count: int) -> Array:
	var rows: Array = []
	for i: int in count:
		rows.append(row)
	return rows
