extends GdUnitTestSuite
## The bursts of a stroke (tool polish, step 2, D5: a bend of "A still world" the user allowed):
## each is gone within half a second, and its bits end at or below where they began, lying on
## the ground: nothing is left in the air, nothing rises. The pour falls to where it lands and
## the ring on the water stays flat where it is.

const STROKE_KINDS: Array[StringName] = [&"clods", &"splash", &"seeds", &"chips", &"rubble", &"splinters", &"chaff"]
const FRAME: float = 1.0 / 60.0


func test_each_stroke_burst_falls_to_the_ground_within_half_a_second() -> void:
	for kind: StringName in STROKE_KINDS:
		assert_bool(Burst.KINDS.has(kind)).override_failure_message(String(kind)).is_true()
		var burst: Burst = auto_free(Burst.new())
		burst.setup(kind)
		assert_float(burst.life).override_failure_message("%s lasts half a second at most" % kind).is_less_equal(0.5)
		var floor_y: float = float(Burst.KINDS[kind]["floor"])
		assert_float(floor_y).override_failure_message("%s comes to rest at or below its start" % kind).is_greater_equal(0.0)
		var last: Array[Vector2] = []
		var age: float = 0.0
		while age + FRAME < burst.life:
			burst._process(FRAME)
			age += FRAME
			last = burst.bits().duplicate()
		assert_bool(burst.is_queued_for_deletion()).is_false()
		for bit: Vector2 in last:
			assert_float(bit.y).override_failure_message("%s: a bit lies on the ground at the end" % kind).is_equal_approx(floor_y, 0.01)
		burst._process(FRAME * 2.0)
		assert_bool(burst.is_queued_for_deletion()).override_failure_message("%s is gone" % kind).is_true()


func test_a_burst_takes_the_colours_it_is_given() -> void:
	var burst: Burst = auto_free(Burst.new())
	burst.setup(&"chips", 1.0, [Color.RED, Color.BLUE])
	assert_array(burst._colors).contains([Color.RED, Color.BLUE])
	assert_array(burst._colors).not_contains([Color(0.62, 0.60, 0.58)])


func test_the_pour_falls_to_where_it_lands_and_the_ring_stays_flat() -> void:
	var pour: Pour = auto_free(Pour.new())
	pour.from = Vector2(-1, -12)
	assert_float(Pour.LIFE).is_less_equal(0.5)
	var lowest: float = -100.0
	var age: float = 0.0
	while age < Pour.LIFE - FRAME:
		pour._process(FRAME)
		age += FRAME
		for drop: Vector2 in pour.drops():
			assert_float(drop.y).override_failure_message("between the spout and the soil").is_between(-12.0, 0.0)
			lowest = maxf(lowest, drop.y)
	assert_float(lowest).override_failure_message("the drops reach the soil").is_greater(-2.0)
	var ripple: Ripple = auto_free(Ripple.new())
	assert_float(Ripple.LIFE).is_less_equal(0.5)
	var before: float = ripple.radius()
	ripple._process(0.2)
	assert_float(ripple.radius()).override_failure_message("it widens").is_greater(before)
	assert_float(ripple.position.y).override_failure_message("where it is").is_equal(0.0)


func test_a_rocks_chips_take_its_own_colours() -> void:
	var stone: Array = Rock.chip_colours(MineRules.STONE)
	var copper: Array = Rock.chip_colours(&"copper_ore")
	assert_int(stone.size()).is_between(2, Rock.CHIP_COLOURS)
	var orange: bool = false
	for colour: Color in copper:
		orange = orange or (colour.r > colour.b + 0.2)
	assert_bool(orange).override_failure_message("copper ore's chips fleck orange").is_true()
	for colour: Color in stone:
		assert_float(colour.get_luminance()).override_failure_message("no outline among them").is_greater_equal(0.2)
