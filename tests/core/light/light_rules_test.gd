extends GdUnitTestSuite
## LightRules: how much light reaches a point in the dark. Full strength near a light, fading
## to nothing at its edge; the brightest light counts; and only the lights that reach a room
## are handed on to be drawn.


func test_a_light_is_full_near_its_middle_and_gone_at_its_edge() -> void:
	var lights: Array = [LightRules.light(Vector2(100, 100), 40.0)]
	assert_float(LightRules.brightness(Vector2(100, 100), lights)).is_equal(1.0)
	assert_float(LightRules.brightness(Vector2(100 + 40.0 * LightRules.CORE, 100), lights)).override_failure_message("full out to the core").is_equal_approx(1.0, 0.001)
	var fading: float = LightRules.brightness(Vector2(130, 100), lights)
	assert_float(fading).override_failure_message("fading between core and edge").is_between(0.05, 0.95)
	assert_float(LightRules.brightness(Vector2(140, 100), lights)).override_failure_message("nothing at the edge").is_equal_approx(0.0, 0.001)
	assert_float(LightRules.brightness(Vector2(200, 100), lights)).is_equal(0.0)
	assert_bool(LightRules.is_lit(Vector2(120, 100), lights)).is_true()
	assert_bool(LightRules.is_lit(Vector2(141, 100), lights)).is_false()


func test_with_no_light_all_is_dark() -> void:
	assert_float(LightRules.brightness(Vector2(5, 5), [])).is_equal(0.0)
	assert_float(LightRules.brightness(Vector2(5, 5), [LightRules.light(Vector2(5, 5), 0.0)])).override_failure_message("a light with no reach").is_equal(0.0)


func test_lights_do_not_add_up_the_brightest_counts() -> void:
	var one: Array = [LightRules.light(Vector2(0, 0), 40.0)]
	var two: Array = [LightRules.light(Vector2(0, 0), 40.0), LightRules.light(Vector2(60, 0), 40.0)]
	var between: Vector2 = Vector2(30, 0)
	assert_float(LightRules.brightness(between, two)).is_equal(LightRules.brightness(between, one))
	assert_float(LightRules.brightness(Vector2(58, 0), two)).override_failure_message("the nearer light wins").is_equal(1.0)


func test_only_the_lights_that_reach_a_room_are_drawn_widest_first() -> void:
	var room: Rect2 = Rect2(0, 0, 240, 176)
	var inside: Dictionary = LightRules.light(Vector2(100, 80), 30.0)
	var wide: Dictionary = LightRules.light(Vector2(40, 40), 70.0)
	var just_outside: Dictionary = LightRules.light(Vector2(-20, 80), 30.0)
	var far_away: Dictionary = LightRules.light(Vector2(-200, 80), 60.0)
	var unlit: Dictionary = LightRules.light(Vector2(50, 50), 0.0)
	var reaching: Array = LightRules.reaching(room, [inside, far_away, wide, unlit, just_outside], 12)
	assert_array(reaching).is_equal([wide, inside, just_outside])
	assert_array(LightRules.reaching(room, [inside, far_away, wide, unlit, just_outside], 2)).override_failure_message("no more than the overlay can draw").is_equal([wide, inside])
