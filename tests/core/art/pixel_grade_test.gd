extends GdUnitTestSuite
## PixelGrade (art pass 3): what the game draws in code is warmed to match the baked art, and the
## grass it draws at runtime matches the grass in the tiles. (The grading of pictures as they were
## baked retired with the art tools when the art became PNG, 2026-11-19.)

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
