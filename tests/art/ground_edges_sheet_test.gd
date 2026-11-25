extends GdUnitTestSuite
## The ground's edge sheet (the farm-look plan, phase A): pictures cut from the art pack's edge
## tiles, in the places EdgeAtlas names. A sheet edited or brought anew must keep to this: every
## fringe piece is the grass of its height and lies along the sides it stands for, every bank
## piece is earth and foam along its sides, and a cliff's face is a whole strip.

const SHEET: String = "res://world/tiles/ground_edges.png"
const T: int = GreyboxTiles.TILE_SIZE
## How far into a cell a corner piece may reach, and how far a bank may lie over the water.
const CORNER_REACH: int = 8
const BANK_REACH: int = 6


func test_the_sheet_is_the_size_edge_atlas_lays_out() -> void:
	var sheet: Image = _sheet()
	assert_that(sheet.get_size()).is_equal(EdgeAtlas.SIZE)
	for sides: int in range(1, 16):
		assert_bool(Rect2(Vector2.ZERO, Vector2(EdgeAtlas.SIZE)).encloses(EdgeAtlas.fringe(sides, EdgeAtlas.HEIGHTS - 1))).is_true()
		assert_bool(Rect2(Vector2.ZERO, Vector2(EdgeAtlas.SIZE)).encloses(EdgeAtlas.bank(sides))).is_true()
	assert_that(EdgeAtlas.fringe(1, 0)).override_failure_message("north alone is the first piece").is_equal(Rect2(0, 0, T, T))
	assert_that(EdgeAtlas.fringe(15, 2)).is_equal(Rect2(14 * T, 2 * T, T, T))
	assert_that(EdgeAtlas.fringe_corner(0, 0)).override_failure_message("the corners follow the sides").is_equal(Rect2(15 * T, 0, T, T))
	assert_that(EdgeAtlas.bank_corner(3)).is_equal(Rect2(18 * T, EdgeAtlas.BANK_ROW * T, T, T))
	# A drop shows the foot of the face: its lowest rows.
	var low: Rect2 = EdgeAtlas.face(false, 4)
	assert_that(low.size).is_equal(Vector2(T, 4))
	assert_float(low.end.y).is_equal(float(EdgeAtlas.FACE_ROW * T + EdgeAtlas.FACE_ROWS))
	assert_that(EdgeAtlas.face(false, 99).size).override_failure_message("never more than the strip").is_equal(Vector2(T, EdgeAtlas.FACE_ROWS))
	assert_float(EdgeAtlas.face(true, 8).position.x).override_failure_message("cut stone stands beside earth").is_equal(float(T))


func test_every_fringe_piece_is_the_grass_of_its_height_along_its_sides() -> void:
	var sheet: Image = _sheet()
	for height: int in EdgeAtlas.HEIGHTS:
		var grass: Color = GreyboxTiles.GROUND_COLORS[height]
		for sides: int in range(1, 16):
			var at: Vector2i = Vector2i(EdgeAtlas.fringe(sides, height).position)
			var counts: Dictionary = _counts(sheet, at)
			assert_int(counts.size()).override_failure_message("height %d, sides %d: the grass and its marks, no more" % [height, sides]).is_between(1, 2)
			# (A lane's thin fringe is more mark than grass, so it need not be the commonest.)
			assert_bool(counts.has(grass.to_html(false))).override_failure_message("height %d, sides %d: the grass of its tile" % [height, sides]).is_true()
			for side: Vector2i in EdgeAtlas.SIDES:
				var named: bool = sides & int(EdgeAtlas.SIDES[side]) != 0
				assert_bool(_painted_at(sheet, at + _middle_of(side))).override_failure_message("height %d, sides %d: side %s" % [height, sides, side]).is_equal(named)
		for corner: int in EdgeAtlas.CORNERS.size():
			var at: Vector2i = Vector2i(EdgeAtlas.fringe_corner(corner, height).position)
			assert_int(_painted_outside_corner(sheet, at, corner)).override_failure_message("height %d: corner %d keeps to its corner" % [height, corner]).is_equal(0)
			assert_bool(_painted_at(sheet, at + _corner_pixel(corner))).override_failure_message("height %d: corner %d is painted" % [height, corner]).is_true()


func test_every_bank_piece_is_earth_and_foam_along_its_sides() -> void:
	var sheet: Image = _sheet()
	for sides: int in range(1, 16):
		var at: Vector2i = Vector2i(EdgeAtlas.bank(sides).position)
		assert_int(_counts(sheet, at).size()).override_failure_message("sides %d: earth and foam" % sides).is_equal(2)
		for y: int in T:
			for x: int in T:
				var depth: int = T
				for side: Vector2i in EdgeAtlas.SIDES:
					if sides & int(EdgeAtlas.SIDES[side]):
						depth = mini(depth, _depth_from(side, Vector2i(x, y)))
				var painted: bool = sheet.get_pixel(at.x + x, at.y + y).a > 0.0
				if depth == 0:
					assert_bool(painted).override_failure_message("sides %d: (%d, %d) is on the bank" % [sides, x, y]).is_true()
				elif depth >= BANK_REACH:
					assert_bool(painted).override_failure_message("sides %d: (%d, %d) is open water" % [sides, x, y]).is_false()
	for corner: int in EdgeAtlas.CORNERS.size():
		var at: Vector2i = Vector2i(EdgeAtlas.bank_corner(corner).position)
		assert_int(_painted_outside_corner(sheet, at, corner)).is_equal(0)
		assert_bool(_painted_at(sheet, at + _corner_pixel(corner))).is_true()
	# The water's foam laps on from where the bank's picture ends.
	assert_float(WaterSurface.BANK).is_between(3.0, float(BANK_REACH))


func test_a_cliffs_face_is_a_whole_strip_in_earth_and_in_stone() -> void:
	var sheet: Image = _sheet()
	var differ: int = 0
	for y: int in EdgeAtlas.FACE_ROWS:
		for x: int in T:
			var earth: Color = sheet.get_pixelv(Vector2i(EdgeAtlas.face(false, EdgeAtlas.FACE_ROWS).position) + Vector2i(x, y))
			var stone: Color = sheet.get_pixelv(Vector2i(EdgeAtlas.face(true, EdgeAtlas.FACE_ROWS).position) + Vector2i(x, y))
			assert_float(earth.a).override_failure_message("earth (%d, %d)" % [x, y]).is_equal(1.0)
			assert_float(stone.a).override_failure_message("stone (%d, %d)" % [x, y]).is_equal(1.0)
			differ += 0 if earth == stone else 1
	assert_int(differ).override_failure_message("cut stone is not earth").is_greater(T * EdgeAtlas.FACE_ROWS / 2)


func _sheet() -> Image:
	return Image.load_from_file(ProjectSettings.globalize_path(SHEET))


func _counts(image: Image, at: Vector2i) -> Dictionary:
	var counts: Dictionary = {}
	for y: int in T:
		for x: int in T:
			var pixel: Color = image.get_pixel(at.x + x, at.y + y)
			if pixel.a > 0.0:
				counts[pixel.to_html(false)] = int(counts.get(pixel.to_html(false), 0)) + 1
	return counts


func _painted_at(image: Image, at: Vector2i) -> bool:
	return image.get_pixelv(at).a > 0.0


## The middle of a cell's outer row on `side`.
func _middle_of(side: Vector2i) -> Vector2i:
	return Vector2i(8, 8) + side * 8 - Vector2i(maxi(side.x, 0), maxi(side.y, 0))


func _corner_pixel(corner: int) -> Vector2i:
	var way: Vector2i = EdgeAtlas.CORNERS[corner]
	return Vector2i(T - 1 if way.x > 0 else 0, T - 1 if way.y > 0 else 0)


## How many pixels of the piece at `at` are painted further than CORNER_REACH from `corner`.
func _painted_outside_corner(image: Image, at: Vector2i, corner: int) -> int:
	var from: Vector2i = _corner_pixel(corner)
	var count: int = 0
	for y: int in T:
		for x: int in T:
			if image.get_pixel(at.x + x, at.y + y).a > 0.0 and maxi(absi(x - from.x), absi(y - from.y)) >= CORNER_REACH:
				count += 1
	return count


## How far the pixel `at` of a cell lies in from its `side`.
func _depth_from(side: Vector2i, at: Vector2i) -> int:
	match side:
		Vector2i.UP:
			return at.y
		Vector2i.DOWN:
			return T - 1 - at.y
		Vector2i.LEFT:
			return at.x
	return T - 1 - at.x
