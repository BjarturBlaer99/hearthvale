extends GdUnitTestSuite
## ArrivalHold: a key held against the way the hero comes out of a door is not obeyed until
## it is let go, so it can't walk him back through the door (found in the playtest of
## 2026-11-16: the keep's way out, taken going north, sets him down under the keep's gate).


func test_nothing_is_held_back_by_default() -> void:
	assert_bool(ArrivalHold.is_against(Vector2.UP, Vector2.ZERO)).is_false()
	assert_that(ArrivalHold.allowed(Vector2.UP, Vector2.ZERO)).is_equal(Vector2.UP)


func test_a_key_the_way_held_back_does_not_move_him() -> void:
	assert_bool(ArrivalHold.is_against(Vector2.UP, Vector2.UP)).is_true()
	assert_that(ArrivalHold.allowed(Vector2.UP, Vector2.UP)).is_equal(Vector2.ZERO)


func test_every_other_way_moves_him_at_once() -> void:
	for way: Vector2 in [Vector2.DOWN, Vector2.LEFT, Vector2.RIGHT]:
		assert_bool(ArrivalHold.is_against(way, Vector2.UP)).is_false()
		assert_that(ArrivalHold.allowed(way, Vector2.UP)).is_equal(way)


func test_a_slanting_push_keeps_its_sideways_part() -> void:
	var slant: Vector2 = Vector2(1.0, -1.0).normalized()
	var allowed: Vector2 = ArrivalHold.allowed(slant, Vector2.UP)
	assert_float(allowed.y).is_equal_approx(0.0, 0.0001)
	assert_float(allowed.x).is_equal_approx(slant.x, 0.0001)


func test_it_is_held_back_only_while_the_key_stays_down() -> void:
	assert_that(ArrivalHold.after(Vector2.UP, Vector2.UP)).is_equal(Vector2.UP)
	assert_that(ArrivalHold.after(Vector2.ZERO, Vector2.UP)).is_equal(Vector2.ZERO)
	assert_that(ArrivalHold.after(Vector2.LEFT, Vector2.UP)).is_equal(Vector2.ZERO)
