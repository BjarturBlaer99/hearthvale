extends GdUnitTestSuite
## PixelGrade (art pass 3): colours are warmed, outlines take a dark shade of what they
## surround, and what must stay exact (flashes, marker colours) is left alone. The last tests
## check the baked art itself: no old ink left, and the grass the game draws at runtime
## matches the grass in the tiles.

const OLD_INK: Color = Color(0.10, 0.08, 0.12)
const HERO_OLD_INK: Color = Color(0.10, 0.08, 0.14)
const MAGENTA: Color = Color(1.0, 0.0, 1.0)


func test_warming_makes_colours_richer_and_keeps_alpha() -> void:
	var grass: Color = Color(0.40, 0.64, 0.24)
	var warm: Color = PixelGrade.warm(grass)
	assert_float(warm.s).override_failure_message("richer").is_greater(grass.s)
	assert_float(warm.a).is_equal(1.0)
	assert_float(PixelGrade.warm(Color(0.5, 0.3, 0.2, 0.4)).a).is_equal_approx(0.4, 0.001)
	assert_that(PixelGrade.warm(Color(0.9, 0.1, 0.1, 0.0))).override_failure_message("clear pixels are left alone").is_equal(Color(0.9, 0.1, 0.1, 0.0))
	for color: Color in [Color.WHITE, Color.BLACK, Color(1, 1, 0), Color(0, 0, 1), Color(0.99, 0.5, 0.99)]:
		var out: Color = PixelGrade.warm(color)
		for channel: float in [out.r, out.g, out.b]:
			assert_float(channel).is_between(0.0, 1.0)


func test_lights_lean_yellow_and_shadows_lean_violet() -> void:
	var light: Color = PixelGrade.warm(Color(0.9, 0.9, 0.9))
	assert_float(light.r).override_failure_message("a light grey: more red than blue").is_greater(light.b)
	var dark: Color = PixelGrade.warm(Color(0.15, 0.15, 0.15))
	assert_float(dark.b).override_failure_message("a dark grey: more blue than red").is_greater(dark.r)
	assert_float(dark.b).is_greater(dark.g)


func test_an_outline_takes_a_dark_shade_of_what_it_surrounds() -> void:
	var none: Array[Color] = []
	assert_that(PixelGrade.outline_for(none)).override_failure_message("nothing beside it: the ink").is_equal(PixelGrade.INK)
	var blue: Array[Color] = [Color(0.2, 0.4, 0.9), Color(0.3, 0.5, 1.0)]
	var edge: Color = PixelGrade.outline_for(blue)
	assert_float(edge.b).override_failure_message("still blue").is_greater(edge.r)
	assert_float(edge.b).is_greater(edge.g)
	assert_float(edge.v).override_failure_message("darker than what it surrounds").is_less(0.6)
	assert_float(edge.v).override_failure_message("but not the old near-black").is_greater(OLD_INK.v + 0.1)


func test_grading_a_picture_colours_its_outlines_and_warms_the_rest() -> void:
	var red: Color = Color(0.8, 0.2, 0.2)
	var image: Image = _picture(5, 5)
	_rect(image, Rect2i(1, 1, 3, 3), OLD_INK)
	image.set_pixel(2, 2, red)
	PixelGrade.apply(image, OLD_INK)
	assert_bool(PixelGrade.same(image.get_pixel(2, 2), PixelGrade.warm(red))).override_failure_message("the middle is warmed").is_true()
	var edge: Color = image.get_pixel(1, 2)
	assert_bool(PixelGrade.same(edge, OLD_INK)).override_failure_message("the old ink is gone").is_false()
	assert_float(edge.r).override_failure_message("the outline is a dark red").is_greater(edge.g + 0.1)
	assert_float(edge.v).is_less(PixelGrade.warm(red).v)
	assert_float(image.get_pixel(0, 0).a).override_failure_message("clear stays clear").is_equal(0.0)


func test_a_line_with_nothing_beside_it_is_ink_and_the_inside_of_a_dark_mass_stays_dark() -> void:
	var line: Image = _picture(5, 3)
	_rect(line, Rect2i(0, 1, 5, 1), OLD_INK)
	PixelGrade.apply(line, OLD_INK)
	assert_bool(PixelGrade.same(line.get_pixel(2, 1), PixelGrade.INK)).override_failure_message("a lone line: the ink").is_true()
	var mass: Image = _picture(5, 5)
	_rect(mass, Rect2i(0, 0, 5, 5), OLD_INK)
	PixelGrade.apply(mass, OLD_INK)
	assert_bool(PixelGrade.same(mass.get_pixel(2, 2), PixelGrade.DEEP)).override_failure_message("a doorway's dark stays dark").is_true()
	assert_float(PixelGrade.DEEP.v).is_less(PixelGrade.INK.v)


func test_kept_colours_are_untouched_and_dont_colour_outlines() -> void:
	var image: Image = _picture(3, 1)
	image.set_pixel(0, 0, OLD_INK)
	image.set_pixel(1, 0, MAGENTA)
	var keep: Array[Color] = [MAGENTA]
	PixelGrade.apply(image, OLD_INK, Rect2i(), Vector2i.ZERO, keep)
	assert_that(image.get_pixel(1, 0)).override_failure_message("the marker is exactly as painted").is_equal(MAGENTA)
	assert_bool(PixelGrade.same(image.get_pixel(0, 0), PixelGrade.INK)).override_failure_message("an outline beside a marker is plain ink").is_true()


func test_only_the_region_is_graded_and_an_outline_looks_no_further_than_its_cell() -> void:
	var image: Image = _picture(4, 4)
	_rect(image, Rect2i(0, 0, 4, 4), Color.WHITE)
	PixelGrade.apply(image, OLD_INK, Rect2i(0, 0, 4, 2))
	assert_that(image.get_pixel(1, 3)).override_failure_message("outside the region: the flash stays white").is_equal(Color.WHITE)
	assert_bool(image.get_pixel(1, 0) == Color.WHITE).override_failure_message("inside it: warmed").is_false()
	# Two 2x2 cells side by side: ink in the left one, red in the right. The ink doesn't see it.
	var atlas: Image = _picture(4, 2)
	_rect(atlas, Rect2i(0, 0, 2, 2), OLD_INK)
	_rect(atlas, Rect2i(2, 0, 2, 2), Color(0.8, 0.2, 0.2))
	PixelGrade.apply(atlas, OLD_INK, Rect2i(), Vector2i(2, 2))
	var edge: Color = atlas.get_pixel(1, 0)
	assert_float(absf(edge.r - edge.g)).override_failure_message("no red from the tile next door").is_less(0.1)


func test_no_old_ink_is_left_in_the_baked_art() -> void:
	var pictures: Dictionary = {GreyboxTiles.TEXTURE_PATH: OLD_INK, "res://gameplay/player/player_sheet.png": HERO_OLD_INK}
	var dir: DirAccess = DirAccess.open("res://gameplay/art")
	for file: String in dir.get_files():
		if file.ends_with(".png"):
			pictures["res://gameplay/art".path_join(file)] = OLD_INK
	assert_int(pictures.size()).override_failure_message("the tiles, the hero and the other sprites").is_greater(10)
	for path: String in pictures:
		var image: Image = (load(path) as Texture2D).get_image()
		var left: int = 0
		for y: int in image.get_height():
			for x: int in image.get_width():
				var pixel: Color = image.get_pixel(x, y)
				if pixel.a == 1.0 and PixelGrade.same(pixel, pictures[path]):
					left += 1
		assert_int(left).override_failure_message("%s: %d pixels of the old ink" % [path, left]).is_equal(0)


func test_the_grass_drawn_at_runtime_matches_the_grass_in_the_tiles() -> void:
	var image: Image = (load(GreyboxTiles.TEXTURE_PATH) as Texture2D).get_image()
	var size: int = GreyboxTiles.TILE_SIZE
	for height: int in 3:
		var want: Color = HeightShading.fringe_color(GreyboxTiles.GROUND_COLORS[height], 2)
		assert_float(HeightShading.fringe_color(GreyboxTiles.GROUND_COLORS[height], 0).v).override_failure_message("tone 0 is the darker blade").is_less(want.v)
		var matching: int = 0
		for y: int in size:
			for x: int in size:
				if PixelGrade.same(image.get_pixel(height * size + x, GreyboxTiles.ROW_GROUND * size + y), want):
					matching += 1
		assert_int(matching).override_failure_message("height %d: the fringe's plain blade is the colour of most of the tile" % height).is_greater(150)


func _picture(width: int, height: int) -> Image:
	var image: Image = Image.create(width, height, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	return image


func _rect(image: Image, rect: Rect2i, color: Color) -> void:
	image.fill_rect(rect, color)
