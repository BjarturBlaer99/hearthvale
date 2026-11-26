extends GdUnitTestSuite
## The boxes' frame and the plot's soil as the farm-look plan's phase C left them (cut from the
## Ninja Adventure pack). A sheet edited or brought anew must keep to this: every piece of the
## frame where UiParts says, its edges whole and outlined on the box's outside, the dial in its
## place; and the soil darker as it is worked: bare, then tilled, then watered.

const UI_SHEET: String = "res://ui/art/ui_parts.png"
const SOIL_SHEET: String = "res://gameplay/art/soil.png"


func test_the_frames_pieces_lie_where_ui_parts_says_and_its_edges_are_whole() -> void:
	var sheet: Image = _load(UI_SHEET)
	var whole: Rect2 = Rect2(Vector2.ZERO, Vector2(sheet.get_size()))
	var pieces: Array[Rect2] = UiParts.CORNERS.duplicate()
	pieces.append_array([UiParts.TOP, UiParts.BOTTOM, UiParts.LEFT, UiParts.RIGHT])
	for piece: Rect2 in pieces:
		assert_bool(whole.encloses(piece)).override_failure_message("%s is on the sheet" % piece).is_true()
		assert_bool(piece.intersects(UiParts.DIAL)).override_failure_message("%s is clear of the dial" % piece).is_false()
	for corner: Rect2 in UiParts.CORNERS:
		assert_that(corner.size).is_equal(Vector2(UiParts.CORNER, UiParts.CORNER))
	assert_that(UiParts.TOP.size).is_equal(Vector2(UiParts.EDGE_LONG, UiParts.EDGE))
	assert_that(UiParts.LEFT.size).is_equal(Vector2(UiParts.EDGE, UiParts.EDGE_LONG))
	# An edge repeats along the box: every pixel of it is painted, or a gap would show.
	for edge: Rect2 in [UiParts.TOP, UiParts.BOTTOM, UiParts.LEFT, UiParts.RIGHT]:
		for y: int in range(int(edge.position.y), int(edge.end.y)):
			for x: int in range(int(edge.position.x), int(edge.end.x)):
				assert_float(sheet.get_pixel(x, y).a).override_failure_message("%s is whole at (%d, %d)" % [edge, x, y]).is_equal(1.0)
	# The outline is outermost: the darkest row of the top edge is its first, of the bottom its last.
	assert_float(_row_value(sheet, UiParts.TOP, 0)).is_less(_row_value(sheet, UiParts.TOP, 2))
	assert_float(_row_value(sheet, UiParts.BOTTOM, int(UiParts.BOTTOM.size.y) - 1)).is_less(_row_value(sheet, UiParts.BOTTOM, 2))
	# The dial is still a picture where ClockDial reads it.
	assert_float(sheet.get_pixelv(Vector2i(UiParts.DIAL.position + UiParts.DIAL_CENTRE)).a).override_failure_message("the dial's middle is painted").is_equal(1.0)


func test_soil_is_darker_as_it_is_worked() -> void:
	var sheet: Image = _load(SOIL_SHEET)
	var bare: float = _mean_value(sheet, int(FarmPlot.FRAMES[&"bare"]))
	var bare_b: float = _mean_value(sheet, int(FarmPlot.FRAMES[&"bare_b"]))
	var tilled: float = _mean_value(sheet, int(FarmPlot.FRAMES[&"tilled"]))
	var watered: float = _mean_value(sheet, int(FarmPlot.FRAMES[&"watered"]))
	assert_float(absf(bare - bare_b)).override_failure_message("the two bare soils are one ground").is_less(0.05)
	assert_float(tilled).override_failure_message("tilled soil is darker than bare").is_less(bare - 0.02)
	assert_float(watered).override_failure_message("watered soil is darker than tilled").is_less(tilled - 0.02)
	for frame: int in 4:
		for y: int in FarmPlot.CELL.y:
			for x: int in FarmPlot.CELL.x:
				assert_float(sheet.get_pixel(frame * FarmPlot.CELL.x + x, y).a).override_failure_message("soil %d is whole" % frame).is_equal(1.0)


func _load(path: String) -> Image:
	var image: Image = Image.load_from_file(ProjectSettings.globalize_path(path))
	image.convert(Image.FORMAT_RGBA8)
	return image


func _row_value(sheet: Image, piece: Rect2, row: int) -> float:
	var total: float = 0.0
	for x: int in range(int(piece.position.x), int(piece.end.x)):
		total += sheet.get_pixel(x, int(piece.position.y) + row).v
	return total / piece.size.x


func _mean_value(sheet: Image, frame: int) -> float:
	var total: float = 0.0
	for y: int in FarmPlot.CELL.y:
		for x: int in FarmPlot.CELL.x:
			total += sheet.get_pixel(frame * FarmPlot.CELL.x + x, y).v
	return total / float(FarmPlot.CELL.x * FarmPlot.CELL.y)
