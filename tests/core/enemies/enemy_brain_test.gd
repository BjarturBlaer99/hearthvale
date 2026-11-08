extends GdUnitTestSuite
## Enemy brains on tiny grids with seeded random numbers: each behaviour patrols, notices the
## hero, attacks and can be beaten, and keeps to the terrain rules (walkers never climb a cliff,
## hop down a ledge or enter a solid tile; fliers cross heights but not solid tiles). Also the
## drop table.

const FRAME: float = 1.0 / 60.0
const SLIME: Dictionary = {"behaviour": "hopper", "health": 2, "speed": 44, "sight": 72}
const ARCHER: Dictionary = {"behaviour": "archer", "health": 4, "speed": 32, "sight": 112, "shot": {"cooldown": 1.6}}
const BAT: Dictionary = {"behaviour": "flier", "health": 1, "speed": 60, "sight": 64}
const FAR_AWAY: Vector2 = Vector2(5000, 5000)


func test_every_behaviour_in_data_has_a_brain() -> void:
	assert_array(Array(EnemyBrains.BEHAVIOURS)).is_equal(Array(DataRegistry.ENEMY_BEHAVIOURS))
	for enemy: Dictionary in DataRegistry.entries(&"enemies"):
		assert_bool(EnemyBrains.has(str(enemy["behaviour"]))).override_failure_message(str(enemy["id"])).is_true()
	assert_object(EnemyBrains.create({"behaviour": "teleporter"}, _body(_open(5), Vector2i(2, 2)), RandomNumberGenerator.new())).is_null()


func test_a_slime_patrols_near_home_until_it_notices_the_hero() -> void:
	var brain: EnemyBrain = _brain(_open(20), Vector2i(10, 10), SLIME)
	var states: Dictionary = _record_states(brain)
	var farthest: float = 0.0
	for i: int in roundi(10.0 / FRAME):
		brain.step(FAR_AWAY, FRAME)
		farthest = maxf(farthest, brain.body.position.distance_to(brain.home))
	assert_bool(states.has(EnemyBrain.WANDER)).override_failure_message("it hops about").is_true()
	assert_bool(states.has(EnemyBrain.CHASE)).override_failure_message("nobody to chase").is_false()
	assert_float(farthest).override_failure_message("stays near home").is_less_equal(EnemyBrain.LEASH + 32.0)


func test_a_slime_notices_the_hero_hops_after_them_and_gives_up_when_they_leave() -> void:
	var brain: EnemyBrain = _brain(_open(20), Vector2i(4, 10), SLIME)
	var states: Dictionary = _record_states(brain)
	var hero: Vector2 = GridBody.cell_center(Vector2i(8, 10))
	var start: float = brain.distance_to(hero)
	# A hop covers about 15 px, then a rest: four tiles take a few seconds.
	_run(brain, hero, 3.5)
	assert_bool(states.has(EnemyBrain.CHASE)).is_true()
	assert_float(brain.distance_to(hero)).override_failure_message("closer than %s" % start).is_less(24.0)
	assert_bool(states.has(EnemyBrain.ATTACK)).override_failure_message("lunges when close").is_true()
	_run(brain, FAR_AWAY, 2.0)
	assert_that(brain.state).override_failure_message("gave up").is_not_equal(EnemyBrain.CHASE)


func test_walkers_never_climb_cliffs_hop_down_ledges_or_enter_solid_tiles() -> void:
	# [rows, where the enemy starts, where the hero stands, the column it must never reach]
	var cases: Array = [
		[_rows("0 0 0 2 2 2", 5), Vector2i(1, 2), Vector2i(4, 2), 3],
		[_rows("2 2 2 0 0 0", 5), Vector2i(1, 2), Vector2i(4, 2), 3],
		[_rows("0 0 0s 0 0 0", 5), Vector2i(0, 2), Vector2i(4, 2), 2],
	]
	for data: Dictionary in [SLIME, ARCHER]:
		for case: Array in cases:
			var brain: EnemyBrain = _brain(case[0], case[1], data)
			var hero: Vector2 = GridBody.cell_center(case[2])
			var level: int = brain.body.level
			for i: int in roundi(6.0 / FRAME):
				brain.step(hero, FRAME)
				assert_int(brain.body.cell.x).override_failure_message("%s crossed %s" % [data["behaviour"], case[0][0]]).is_less(case[3])
				assert_int(brain.body.level).is_equal(level)
				if brain.body.cell.x >= case[3]:
					return


func test_an_archer_keeps_its_distance() -> void:
	var brain: EnemyBrain = _brain(_open(20), Vector2i(10, 10), ARCHER)
	var hero: Vector2 = GridBody.cell_center(Vector2i(11, 10))
	_run(brain, hero, 1.0)
	assert_float(brain.distance_to(hero)).override_failure_message("backed off").is_greater(ArcherBrain.NEAR - 4.0)


func test_an_archer_lines_up_draws_its_bow_then_shoots() -> void:
	var brain: EnemyBrain = _brain(_open(20), Vector2i(10, 6), ARCHER)
	var hero: Vector2 = GridBody.cell_center(Vector2i(12, 10))
	var shots: Array = []
	var drew_at: Array[float] = []
	var clock: Array[float] = [0.0]
	brain.shot.connect(func(direction: Vector2) -> void: shots.append([clock[0], direction]))
	brain.state_changed.connect(func(state: StringName) -> void:
		if state == EnemyBrain.ATTACK:
			drew_at.append(clock[0]))
	for i: int in roundi(4.0 / FRAME):
		brain.step(hero, FRAME)
		clock[0] += FRAME
	assert_int(shots.size()).override_failure_message("it shot").is_greater_equal(1)
	# The tell must last long enough to see and react to, whatever DRAW_TIME is set to.
	assert_float(shots[0][0] - drew_at[0]).override_failure_message("draws its bow for a visible moment first (the tell)").is_greater_equal(0.4)
	var offset: Vector2 = hero - brain.body.position
	assert_bool(absf(offset.x) <= ArcherBrain.ALIGN + 2.0 or absf(offset.y) <= ArcherBrain.ALIGN + 2.0).override_failure_message("lined up").is_true()
	assert_that(shots[0][1]).is_equal(EnemyBrain.cardinal(offset))
	if shots.size() > 1:
		assert_float(shots[1][0] - shots[0][0]).override_failure_message("waits out its cooldown").is_greater_equal(1.6)


func test_a_bat_rests_until_the_hero_comes_near_then_flies_at_them() -> void:
	var brain: EnemyBrain = _brain(_open(20), Vector2i(10, 10), BAT)
	var start: Vector2 = brain.body.position
	_run(brain, FAR_AWAY, 1.0)
	assert_that(brain.state).is_equal(EnemyBrain.IDLE)
	assert_that(brain.body.position).override_failure_message("resting on its roost").is_equal(start)
	var states: Dictionary = _record_states(brain)
	var hero: Vector2 = GridBody.cell_center(Vector2i(13, 10))
	var nearest: float = brain.distance_to(hero)
	for i: int in roundi(3.0 / FRAME):
		brain.step(hero, FRAME)
		nearest = minf(nearest, brain.distance_to(hero))
	assert_bool(states.has(EnemyBrain.CHASE)).is_true()
	assert_bool(states.has(EnemyBrain.ATTACK)).override_failure_message("swoops").is_true()
	assert_float(nearest).is_less(12.0)


func test_a_bat_flies_over_heights_but_not_through_solid_tiles() -> void:
	var data: Dictionary = BAT.duplicate()
	data["sight"] = 400
	var brain: EnemyBrain = _brain(_rows("0 0 3 3 0 0 0s 0 0", 7), Vector2i(0, 3), data)
	var hero: Vector2 = GridBody.cell_center(Vector2i(8, 3))
	var farthest: int = 0
	for i: int in roundi(8.0 / FRAME):
		brain.step(hero, FRAME)
		farthest = maxi(farthest, brain.body.cell.x)
	assert_int(farthest).override_failure_message("over the height-3 ridge").is_greater_equal(4)
	assert_int(farthest).override_failure_message("not through the solid wall").is_less(6)


func test_hits_cost_health_knock_it_back_and_beat_it() -> void:
	var brain: EnemyBrain = _brain(_open(10), Vector2i(3, 3), SLIME)
	var start: Vector2 = brain.body.position
	assert_bool(brain.take_hit(1, Vector2(32, 0))).is_true()
	assert_int(brain.health).is_equal(1)
	assert_that(brain.state).is_equal(EnemyBrain.HURT)
	assert_bool(brain.take_hit(1, Vector2(32, 0))).override_failure_message("stunned: can't be hit again yet").is_false()
	# The hero waits in sight, straight below where the push ends.
	_run(brain, start + Vector2(32, 40), EnemyBrain.HURT_TIME + FRAME)
	assert_float(brain.body.position.x).is_equal_approx(start.x + 32.0, 0.01)
	assert_that(brain.state).override_failure_message("after a hit it's after the hero").is_equal(EnemyBrain.CHASE)
	assert_bool(brain.take_hit(5, Vector2.ZERO)).is_true()
	assert_bool(brain.is_dead()).is_true()
	var at: Vector2 = brain.body.position
	_run(brain, at + Vector2(16, 0), 1.0)
	assert_that(brain.body.position).override_failure_message("the dead stay put").is_equal(at)


func test_the_drop_table_picks_by_weight() -> void:
	var drops: Array = [{"type": "heart", "weight": 1}, {"type": "item", "item": "coin", "weight": 2}, {"type": "nothing", "weight": 2}]
	for case: Array in [[0.0, "heart"], [0.19, "heart"], [0.21, "item"], [0.59, "item"], [0.61, "nothing"], [0.999, "nothing"], [1.0, "nothing"]]:
		assert_str(str(DropTable.roll(drops, case[0]).get("type", ""))).override_failure_message("roll %s" % case[0]).is_equal(case[1])
	assert_dict(DropTable.roll([], 0.5)).is_empty()


func _brain(rows: Array, at: Vector2i, data: Dictionary, rng_seed: int = 7) -> EnemyBrain:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = rng_seed
	return EnemyBrains.create(data, _body(rows, at), rng)


func _body(rows: Array, at: Vector2i) -> GridBody:
	var body: GridBody = GridBody.new(TerrainQuery.new(HeightGrid.from_rows(PackedStringArray(rows))))
	body.place(at)
	return body


func _run(brain: EnemyBrain, hero: Vector2, seconds: float) -> void:
	for i: int in roundi(seconds / FRAME):
		brain.step(hero, FRAME)


func _record_states(brain: EnemyBrain) -> Dictionary:
	var seen: Dictionary = {}
	brain.state_changed.connect(func(state: StringName) -> void: seen[state] = true)
	return seen


func _open(size: int) -> Array:
	return _rows(("0 ").repeat(size).strip_edges(), size)


func _rows(row: String, count: int) -> Array:
	var rows: Array = []
	for i: int in count:
		rows.append(row)
	return rows
