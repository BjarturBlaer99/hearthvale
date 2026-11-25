extends GdUnitTestSuite
## PixelGrade (art pass 3): what the game draws in code is warmed to match the baked art, and the
## ground's colours in code are the tiles' own. (The grading of pictures as they were baked retired
## with the art tools when the art became PNG, 2026-11-19; the grass's fringe became a picture with
## the farm-look plan's phase A, tests/art/ground_edges_sheet_test.gd.)

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


func test_the_ground_colours_in_code_are_the_colours_of_the_tiles() -> void:
	var image: Image = (load(GreyboxTiles.TEXTURE_PATH) as Texture2D).get_image()
	var size: int = GreyboxTiles.TILE_SIZE
	for height: int in GreyboxTiles.COLUMNS:
		var want: Color = GreyboxTiles.GROUND_COLORS[height]
		for row: int in [GreyboxTiles.ROW_GROUND, GreyboxTiles.ROW_SOLID_GROUND]:
			var matching: int = 0
			for y: int in size:
				for x: int in size:
					if PixelGrade.same(image.get_pixel(height * size + x, row * size + y), want):
						matching += 1
			assert_int(matching).override_failure_message("height %d, row %d: the colour in code is the colour of most of the tile" % [height, row]).is_greater(150)
