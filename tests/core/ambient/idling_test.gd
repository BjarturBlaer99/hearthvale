extends GdUnitTestSuite
## Idling (P1e): someone standing still breathes out for part of every breath and blinks
## briefly now and then, never both at once, and starts at a moment of their own.

const STEP: float = 1.0 / 60.0


func test_they_breathe_out_for_part_of_every_breath() -> void:
	var idling: Idling = Idling.new()
	var out: float = 0.0
	var breaths: int = 0
	var was_out: bool = false
	for i: int in roundi(Idling.BREATH_EVERY * 3.0 / STEP):
		idling.tick(STEP)
		var now: bool = idling.look() == Idling.Look.BREATHE
		out += STEP if now else 0.0
		breaths += 1 if now and not was_out else 0
		was_out = now
	assert_int(breaths).is_equal(3)
	assert_float(out).override_failure_message("out for BREATH_OUT of each breath").is_equal_approx(Idling.BREATH_OUT * 3.0, 0.1)
	assert_float(Idling.BREATH_OUT).override_failure_message("in for longer than out").is_less(Idling.BREATH_EVERY / 2.0)


func test_they_blink_briefly_and_never_mid_breath() -> void:
	var idling: Idling = Idling.new()
	var blinks: int = 0
	var longest: float = 0.0
	var run: float = 0.0
	var last: Idling.Look = Idling.Look.REST
	# What they did, in order, without repeats.
	var story: Array[Idling.Look] = [Idling.Look.REST]
	for i: int in roundi(60.0 / STEP):
		idling.tick(STEP)
		var now: Idling.Look = idling.look()
		if now == Idling.Look.BLINK:
			run += STEP
			blinks += 1 if last != Idling.Look.BLINK else 0
		else:
			run = 0.0
		if now != last:
			story.append(now)
		longest = maxf(longest, run)
		last = now
	assert_int(blinks).override_failure_message("several blinks a minute").is_between(5, 14)
	assert_float(longest).override_failure_message("a blink is brief").is_less(0.25)
	# A blink is drawn with the shoulders up, so one in the middle of a breath out would jump.
	for i: int in range(2, story.size()):
		var mid_breath: bool = story[i - 2] == Idling.Look.BREATHE and story[i - 1] == Idling.Look.BLINK and story[i] == Idling.Look.BREATHE
		assert_bool(mid_breath).override_failure_message("a blink never cuts into a breath out").is_false()
	assert_bool(story.has(Idling.Look.BREATHE) and story.has(Idling.Look.REST)).is_true()


func test_each_has_a_moment_of_their_own() -> void:
	var here: float = Idling.phase_of(Vector2i(12, 9))
	assert_float(Idling.phase_of(Vector2i(12, 9))).override_failure_message("the same every time").is_equal(here)
	var seen: Dictionary = {}
	for x: int in 6:
		for y: int in 6:
			var phase: float = Idling.phase_of(Vector2i(10 + x, 20 + y))
			assert_float(phase).is_between(0.0, Idling.BREATH_EVERY * Idling.BLINK_EVERY)
			seen[snappedf(phase, 0.001)] = true
	assert_int(seen.size()).override_failure_message("neighbours start at different moments").is_equal(36)
	# Two who started apart are not doing the same thing all the time.
	var one: Idling = Idling.new(Idling.phase_of(Vector2i(4, 4)))
	var other: Idling = Idling.new(Idling.phase_of(Vector2i(5, 4)))
	var apart: int = 0
	for i: int in roundi(10.0 / STEP):
		one.tick(STEP)
		other.tick(STEP)
		apart += 1 if one.look() != other.look() else 0
	assert_int(apart).override_failure_message("they don't breathe as one").is_greater(30)
