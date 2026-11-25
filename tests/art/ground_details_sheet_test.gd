extends GdUnitTestSuite
## The ground details' sheet (the warm-ground plan, step 3): small, quiet pictures in the
## ground's own colours, so nothing on it looks like something to pick up, break or cut. A
## sheet painted anew (or brought from a tool) must keep to this.

const SHEET: String = "res://world/tiles/ground_details.png"
const ATLAS: String = "res://world/tiles/greybox_tiles.png"
const SIZE: int = GreyboxTiles.TILE_SIZE
## The most of a frame's 256 pixels a detail may paint: it is a touch on the ground, not a thing.
const MOST_PAINTED: int = 48


func test_every_detail_is_painted_in_colours_of_the_ground_atlas() -> void:
	var atlas: Dictionary = {}
	var tiles: Image = Image.load_from_file(ProjectSettings.globalize_path(ATLAS))
	for y: int in tiles.get_height():
		for x: int in tiles.get_width():
			var pixel: Color = tiles.get_pixel(x, y)
			if pixel.a == 1.0:
				atlas[pixel.to_html(false)] = true
	var sheet: Image = _sheet()
	for y: int in sheet.get_height():
		for x: int in sheet.get_width():
			var pixel: Color = sheet.get_pixel(x, y)
			if pixel.a > 0.0:
				assert_bool(atlas.has(pixel.to_html(false))).override_failure_message("%s at (%d, %d) is a colour of the atlas" % [pixel.to_html(false), x, y]).is_true()


func test_each_detail_is_small_quiet_and_clear_of_its_cells_edge() -> void:
	var sheet: Image = _sheet()
	for name: StringName in GroundDetails.FRAMES:
		var frame: int = GroundDetails.FRAMES[name]
		var painted: int = 0
		for y: int in SIZE:
			for x: int in SIZE:
				var pixel: Color = sheet.get_pixel(frame * SIZE + x, y)
				if pixel.a == 0.0:
					continue
				painted += 1
				assert_bool(x == 0 or y == 0 or x == SIZE - 1 or y == SIZE - 1).override_failure_message("%s: (%d, %d) is on the cell's edge" % [name, x, y]).is_false()
				# Nothing red: red is for berries, mushrooms and the flowers of the decor.
				var red: bool = (pixel.h < 20.0 / 360.0 or pixel.h > 330.0 / 360.0) and pixel.s > 0.35
				assert_bool(red).override_failure_message("%s: (%d, %d) is red" % [name, x, y]).is_false()
		assert_int(painted).override_failure_message("%s is painted" % name).is_greater(2)
		assert_int(painted).override_failure_message("%s is quiet: %d pixels" % [name, painted]).is_less_equal(MOST_PAINTED)


func _sheet() -> Image:
	return Image.load_from_file(ProjectSettings.globalize_path(SHEET))
