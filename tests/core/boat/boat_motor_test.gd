extends GdUnitTestSuite
## BoatMotor: steer-toward-input sailing with drift, deep water only, and the map edge.

const FRAME: float = 1.0 / 60.0


func test_sails_toward_the_input_and_speeds_up() -> void:
	var boat: BoatMotor = _boat(_sea(20, 5), 4, Vector2i(2, 2), 0.0)
	var start: float = boat.position.x
	_sail(boat, Vector2.RIGHT, 1.0)
	assert_float(boat.position.x - start).is_greater(40.0)
	assert_float(boat.speed()).is_greater(80.0)
	assert_float(boat.speed()).is_less_equal(BoatMotor.MAX_SPEED)


func test_turning_takes_time() -> void:
	var boat: BoatMotor = _boat(_sea(20, 20), 4, Vector2i(5, 5), 0.0)
	_sail(boat, Vector2.DOWN, 0.1)
	assert_float(boat.heading).is_equal_approx(BoatMotor.TURN_RATE * 0.1, 0.02)
	_sail(boat, Vector2.DOWN, 1.0)
	assert_float(boat.heading).is_equal_approx(PI / 2.0, 0.001)


func test_the_boat_drifts_through_a_turn() -> void:
	var boat: BoatMotor = _boat(_sea(20, 20), 4, Vector2i(2, 2), 0.0)
	_sail(boat, Vector2.RIGHT, 1.0)
	_sail(boat, Vector2.DOWN, 0.15)
	# Still sliding east while it swings south...
	assert_float(boat.velocity.x).is_greater(30.0)
	_sail(boat, Vector2.DOWN, 1.5)
	# ...until the keel bites and it runs straight south.
	assert_float(absf(boat.velocity.x)).is_less(2.0)
	assert_float(boat.velocity.y).is_greater(50.0)


func test_coasts_to_a_stop_without_input() -> void:
	var boat: BoatMotor = _boat(_sea(40, 5), 4, Vector2i(2, 2), 0.0)
	_sail(boat, Vector2.RIGHT, 1.0)
	_sail(boat, Vector2.ZERO, 5.0)
	assert_float(boat.speed()).is_less(5.0)


func test_the_shore_stops_the_boat() -> void:
	var boat: BoatMotor = _boat(["0 0 0 0 4 0"], 4, Vector2i(0, 0), 0.0)
	_sail(boat, Vector2.RIGHT, 3.0)
	assert_float(boat.position.x).is_equal_approx(4.0 * BoatMotor.TILE - BoatMotor.RADIUS, 0.01)
	assert_float(boat.velocity.x).is_equal(0.0)
	assert_that(boat.cell).is_equal(Vector2i(3, 0))


func test_shallows_stop_the_boat_too() -> void:
	var boat: BoatMotor = _boat(["0 0 0 3 0"], 4, Vector2i(0, 0), 0.0)
	_sail(boat, Vector2.RIGHT, 3.0)
	assert_float(boat.position.x).is_equal_approx(3.0 * BoatMotor.TILE - BoatMotor.RADIUS, 0.01)


func test_sailing_off_the_map_reports_the_edge() -> void:
	var boat: BoatMotor = _boat(_sea(3, 3), 4, Vector2i(1, 1), 0.0)
	var edges: Array = []
	boat.edge_reached.connect(func(direction: Vector2) -> void: edges.append(direction))
	_sail(boat, Vector2.RIGHT, 1.0)
	assert_bool(edges.is_empty()).is_false()
	assert_that(edges[0]).is_equal(Vector2.RIGHT)


func test_each_new_cell_is_reported() -> void:
	var boat: BoatMotor = _boat(_sea(8, 1), 4, Vector2i(0, 0), 0.0)
	var cells: Array = []
	boat.cell_changed.connect(func(cell: Vector2i) -> void: cells.append(cell))
	_sail(boat, Vector2.RIGHT, 1.0)
	assert_array(cells).contains(Vector2i(1, 0), Vector2i(2, 0))


func _boat(rows: Array, water_height: int, cell: Vector2i, heading: float) -> BoatMotor:
	var boat: BoatMotor = BoatMotor.new(TerrainQuery.new(HeightGrid.from_rows(PackedStringArray(rows))), water_height)
	boat.place(cell, heading)
	return boat


func _sail(boat: BoatMotor, input: Vector2, seconds: float) -> void:
	for i: int in roundi(seconds / FRAME):
		boat.step(input, FRAME)


func _sea(width: int, height: int) -> Array:
	var rows: Array = []
	for y: int in height:
		rows.append("0 ".repeat(width).strip_edges())
	return rows
