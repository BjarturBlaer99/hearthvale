extends GdUnitTestSuite
## The Crypt Shade's brain (H14's boss): it wakes when the hero comes near and drifts after
## them, over pits; blows pass through it until its hall is lit. Then the light binds it for a
## while: it stands still and can be hurt, a few blows a binding. When the binding ends it puts
## the lights out and haunts again. At half health it rages: faster, with bolts. It keeps to its
## arena and starts over on reset().

const FRAME: float = 1.0 / 60.0
const SHADE: Dictionary = {
	"behaviour": "shade", "health": 16, "speed": 24, "sight": 96,
	"boss": {"bound_time": 3.0, "rage_at": 8, "rage_speed": 1.5, "bolt_every": 2.0},
}
const FAR_AWAY: Vector2 = Vector2(5000, 5000)


func test_it_sleeps_until_the_hero_comes_near_then_drifts_after_them() -> void:
	var brain: ShadeBrain = _shade(Vector2i(10, 10))
	var start: Vector2 = brain.body.position
	_run(brain, FAR_AWAY, 2.0)
	assert_that(brain.state).is_equal(EnemyBrain.IDLE)
	assert_that(brain.body.position).is_equal(start)
	var hero: Vector2 = GridBody.cell_center(Vector2i(10, 15))
	_run(brain, hero, 1.0)
	assert_that(brain.state).is_equal(ShadeBrain.HAUNT)
	assert_float(brain.distance_to(hero)).override_failure_message("closing in").is_less(start.distance_to(hero) - 15.0)


func test_it_drifts_over_pits() -> void:
	var terrain: TerrainQuery = TerrainQuery.new(HeightGrid.from_rows(PackedStringArray(_open(20))))
	for x: int in 20:
		terrain.set_pit(Vector2i(x, 12))
	var brain: ShadeBrain = _shade(Vector2i(10, 10), terrain)
	_run(brain, GridBody.cell_center(Vector2i(10, 16)), 5.0)
	assert_int(brain.body.cell.y).override_failure_message("past the pit at row 12").is_greater(12)


func test_blows_pass_through_it_in_the_dark() -> void:
	var brain: ShadeBrain = _shade(Vector2i(10, 10))
	var passes: Array[int] = [0]
	brain.passed.connect(func() -> void: passes[0] += 1)
	_run(brain, GridBody.cell_center(Vector2i(10, 14)), 0.5)
	for kind: StringName in [&"sword", &"arrow", &"bomb"]:
		assert_bool(brain.take_hit(2, Vector2.ZERO, kind)).override_failure_message("%s in the dark" % kind).is_false()
	assert_int(brain.health).is_equal(16)
	assert_int(passes[0]).is_equal(3)


func test_a_blow_wakes_it() -> void:
	var brain: ShadeBrain = _shade(Vector2i(10, 10))
	assert_bool(brain.take_hit(2, Vector2.ZERO, &"arrow")).is_false()
	assert_that(brain.state).is_equal(ShadeBrain.HAUNT)


func test_light_binds_it_and_only_then_can_it_be_hurt() -> void:
	var brain: ShadeBrain = _shade(Vector2i(10, 10))
	var bindings: Array[int] = [0]
	brain.bound.connect(func() -> void: bindings[0] += 1)
	var hero: Vector2 = GridBody.cell_center(Vector2i(10, 14))
	_run(brain, hero, 0.5)
	brain.set_lit(true)
	_run(brain, hero, FRAME)
	assert_bool(brain.is_bound()).is_true()
	assert_int(bindings[0]).is_equal(1)
	var held_at: Vector2 = brain.body.position
	_run(brain, hero, 0.5)
	assert_that(brain.body.position).override_failure_message("held still").is_equal(held_at)
	assert_bool(brain.take_hit(2, Vector2.ZERO, &"sword")).is_true()
	assert_int(brain.health).is_equal(14)
	assert_bool(brain.take_hit(2, Vector2.ZERO, &"sword")).override_failure_message("a flinch between blows").is_false()
	_run(brain, hero, ShadeBrain.FLINCH_TIME + FRAME)
	assert_bool(brain.take_hit(2, Vector2.ZERO, &"sword")).is_true()
	assert_int(brain.health).is_equal(12)


func test_one_binding_is_worth_a_few_blows_not_the_whole_fight() -> void:
	var brain: ShadeBrain = _bound_shade()
	var landed: int = 0
	for i: int in roundi(6.0 / FRAME):
		if brain.take_hit(2, Vector2.ZERO, &"sword"):
			landed += 1
		brain.step(GridBody.cell_center(Vector2i(10, 14)), FRAME)
	assert_int(landed).override_failure_message("several blows").is_greater(2)
	assert_bool(brain.is_dead()).override_failure_message("but it outlasts one binding").is_false()


func test_when_the_binding_ends_it_snuffs_the_lights_and_haunts_again() -> void:
	var brain: ShadeBrain = _bound_shade()
	var snuffs: Array[int] = [0]
	brain.snuffed.connect(func() -> void: snuffs[0] += 1)
	var hero: Vector2 = GridBody.cell_center(Vector2i(10, 14))
	_run(brain, hero, 2.9)
	assert_bool(brain.is_bound()).override_failure_message("bound for bound_time").is_true()
	_run(brain, hero, 0.2)
	assert_that(brain.state).is_equal(ShadeBrain.HAUNT)
	assert_int(snuffs[0]).is_equal(1)
	assert_bool(brain.lit).override_failure_message("it doesn't count its hall as lit any more").is_false()
	_run(brain, hero, 0.5)
	assert_that(brain.state).override_failure_message("not bound again until the lights are back").is_equal(ShadeBrain.HAUNT)
	assert_bool(brain.take_hit(2, Vector2.ZERO, &"sword")).is_false()


func test_a_light_going_out_frees_it_early() -> void:
	var brain: ShadeBrain = _bound_shade()
	brain.set_lit(false)
	_run(brain, GridBody.cell_center(Vector2i(10, 14)), FRAME)
	assert_that(brain.state).is_equal(ShadeBrain.HAUNT)


func test_at_half_health_it_rages_faster_and_throws_bolts() -> void:
	var calm: ShadeBrain = _shade(Vector2i(10, 4))
	var raging: ShadeBrain = _shade(Vector2i(10, 4))
	raging.health = 8
	assert_bool(raging.is_raging()).is_true()
	assert_bool(calm.is_raging()).is_false()
	var bolts: Array = []
	raging.shot.connect(func(direction: Vector2) -> void: bolts.append(direction))
	var calm_bolts: Array = []
	calm.shot.connect(func(direction: Vector2) -> void: calm_bolts.append(direction))
	# Near enough to wake them, then a long way off, so both chase the whole time.
	var near: Vector2 = GridBody.cell_center(Vector2i(10, 8))
	var hero: Vector2 = GridBody.cell_center(Vector2i(10, 19))
	for brain: ShadeBrain in [calm, raging]:
		_run(brain, near, FRAME)
		_run(brain, hero, 4.5)
	assert_float(raging.body.position.y).override_failure_message("faster").is_greater(calm.body.position.y + 10.0)
	assert_int(bolts.size()).override_failure_message("a bolt every bolt_every seconds").is_equal(2)
	assert_float((bolts[0] as Vector2).y).override_failure_message("aimed at the hero").is_greater(0.9)
	assert_int(calm_bolts.size()).is_equal(0)


func test_it_dies_only_bound_and_at_zero() -> void:
	var brain: ShadeBrain = _bound_shade()
	brain.health = 2
	assert_bool(brain.take_hit(3, Vector2.ZERO, &"sword")).is_true()
	assert_bool(brain.is_dead()).is_true()
	assert_bool(brain.take_hit(3, Vector2.ZERO, &"sword")).is_false()


func test_it_keeps_to_its_arena_and_reset_starts_it_over() -> void:
	var brain: ShadeBrain = _shade(Vector2i(10, 10))
	brain.arena = Rect2(Vector2(8, 8) * 16.0, Vector2(5, 5) * 16.0)
	_run(brain, GridBody.cell_center(Vector2i(10, 18)), 8.0)
	assert_float(brain.body.position.y).override_failure_message("stops at the arena's edge").is_less_equal(13.0 * 16.0)
	brain.set_lit(true)
	_run(brain, GridBody.cell_center(Vector2i(10, 12)), FRAME)
	brain.take_hit(2, Vector2.ZERO, &"sword")
	brain.reset()
	assert_that(brain.state).is_equal(EnemyBrain.IDLE)
	assert_int(brain.health).is_equal(16)
	assert_that(brain.body.cell).is_equal(Vector2i(10, 10))
	assert_bool(brain.lit).is_false()


func _shade(at: Vector2i, terrain: TerrainQuery = null) -> ShadeBrain:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 3
	if terrain == null:
		terrain = TerrainQuery.new(HeightGrid.from_rows(PackedStringArray(_open(20))))
	var body: GridBody = GridBody.new(terrain)
	body.place(at)
	return EnemyBrains.create(SHADE, body, rng) as ShadeBrain


## A shade mid-fight, the light just caught it.
func _bound_shade() -> ShadeBrain:
	var brain: ShadeBrain = _shade(Vector2i(10, 10))
	var hero: Vector2 = GridBody.cell_center(Vector2i(10, 14))
	_run(brain, hero, 0.5)
	brain.set_lit(true)
	_run(brain, hero, FRAME)
	return brain


func _run(brain: EnemyBrain, hero: Vector2, seconds: float) -> void:
	for i: int in roundi(seconds / FRAME):
		brain.step(hero, FRAME)


func _open(size: int) -> Array:
	var rows: Array = []
	for i: int in size:
		rows.append(("0 ").repeat(size).strip_edges())
	return rows
