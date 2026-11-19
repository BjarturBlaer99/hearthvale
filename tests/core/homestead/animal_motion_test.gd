extends GdUnitTestSuite
## How an animal moves (the Homestead, phase 4), pure: it rests, then walks to a cell near it,
## and never leaves the cells it is given, however they lie; given new cells, it keeps to them;
## with one cell it stays put.

const FRAME: float = 1.0 / 60.0


func _rng(seed_value: int) -> RandomNumberGenerator:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = seed_value
	return rng


func test_it_never_leaves_its_cells_and_does_wander() -> void:
	# An L of cells: a straight walk across its corner would leave it.
	var cells: Array[Vector2i] = []
	for x: int in range(2, 9):
		cells.append(Vector2i(x, 2))
	for y: int in range(3, 9):
		cells.append(Vector2i(2, y))
	for seed_value: int in [1, 7, 42]:
		var motion: AnimalMotion = AnimalMotion.new(cells, Vector2i(2, 2), 14.0, _rng(seed_value))
		var visited: Dictionary = {}
		for i: int in 3600:
			motion.step(FRAME)
			assert_bool(cells.has(motion.cell())).override_failure_message("seed %d left its cells at %s" % [seed_value, motion.cell()]).is_true()
			visited[motion.cell()] = true
		assert_int(visited.size()).override_failure_message("seed %d stood still for a minute" % seed_value).is_greater(2)


func test_one_cell_and_new_cells() -> void:
	var motion: AnimalMotion = AnimalMotion.new([Vector2i(5, 5)] as Array[Vector2i], Vector2i(5, 5), 14.0, _rng(3))
	for i: int in 600:
		motion.step(FRAME)
	assert_that(motion.cell()).is_equal(Vector2i(5, 5))
	assert_that(motion.position).override_failure_message("nowhere to go").is_equal(GridBody.cell_center(Vector2i(5, 5)))
	# Given a row of cells, it walks along them and nowhere else.
	var row: Array[Vector2i] = [Vector2i(5, 5), Vector2i(6, 5), Vector2i(7, 5), Vector2i(8, 5)]
	motion.set_cells(row)
	var went: bool = false
	for i: int in 1800:
		motion.step(FRAME)
		assert_bool(row.has(motion.cell())).is_true()
		went = went or motion.cell() != Vector2i(5, 5)
	assert_bool(went).is_true()
	# It faces the way it walks: left as drawn, right mirrored.
	assert_float(absf(motion.facing_x)).is_equal(1.0)
	assert_bool(motion.has_cell(Vector2i(8, 5))).is_true()
	assert_int(motion.cells().size()).is_equal(4)
