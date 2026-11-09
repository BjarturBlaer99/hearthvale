extends GdUnitTestSuite
## CritterMotion: a walking critter (a chicken) wanders near home, rests and pecks, and never
## enters a solid or occupied cell; a flying one (a butterfly, a firefly) drifts about its home over
## anything. Both stay close to home and are the same for the same seed.

const FRAME: float = 1.0 / 30.0


func test_a_walker_wanders_and_rests_but_never_enters_walls_or_occupied_cells() -> void:
	# A 12x12 yard with a wall down the middle (a gap at the top) and a villager standing in it.
	var rows: Array = []
	for y: int in 12:
		var row: PackedStringArray = []
		for x: int in 12:
			row.append("0s" if x == 6 and y > 1 else "0")
		rows.append(" ".join(row))
	var terrain: TerrainQuery = TerrainQuery.new(HeightGrid.from_rows(PackedStringArray(rows)))
	terrain.set_occupied(Vector2i(4, 5))
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 5
	var home: Vector2 = GridBody.cell_center(Vector2i(3, 5))
	var motion: CritterMotion = CritterMotion.new(CritterMotion.WALKER, home, 40.0, 18.0, rng, terrain)
	var states: Dictionary = {}
	var farthest: float = 0.0
	for i: int in roundi(60.0 / FRAME):
		motion.step(FRAME)
		states[motion.state] = true
		var cell: Vector2i = GridBody.cell_of(motion.position)
		assert_bool(terrain.grid.is_solid(cell)).override_failure_message("in a wall at %s" % cell).is_false()
		assert_bool(cell == Vector2i(4, 5)).override_failure_message("walked into the villager").is_false()
		farthest = maxf(farthest, motion.position.distance_to(home))
	assert_bool(states.has(CritterMotion.WALK) and states.has(CritterMotion.PECK)).override_failure_message("walks and pecks").is_true()
	assert_float(farthest).override_failure_message("stays near home").is_less(40.0 + 16.0)
	assert_float(farthest).override_failure_message("but does get about").is_greater(8.0)


func test_a_flier_drifts_about_home_over_anything() -> void:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 9
	var home: Vector2 = Vector2(100, 100)
	var motion: CritterMotion = CritterMotion.new(CritterMotion.FLIER, home, 28.0, 22.0, rng)
	var farthest: float = 0.0
	var moved: float = 0.0
	var last: Vector2 = motion.position
	for i: int in roundi(30.0 / FRAME):
		motion.step(FRAME)
		farthest = maxf(farthest, motion.position.distance_to(home))
		moved += motion.position.distance_to(last)
		last = motion.position
	assert_float(farthest).override_failure_message("stays near home").is_less(28.0 * 1.6)
	assert_float(moved).override_failure_message("keeps moving").is_greater(100.0)


func test_the_same_seed_moves_the_same_way() -> void:
	var paths: Array = []
	for run: int in 2:
		var rng: RandomNumberGenerator = RandomNumberGenerator.new()
		rng.seed = 3
		var motion: CritterMotion = CritterMotion.new(CritterMotion.FLIER, Vector2.ZERO, 20.0, 15.0, rng)
		for i: int in 90:
			motion.step(FRAME)
		paths.append(motion.position)
	assert_that(paths[0]).is_equal(paths[1])
