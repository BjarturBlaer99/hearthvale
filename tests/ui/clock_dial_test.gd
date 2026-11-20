extends GdUnitTestSuite
## The clock's dial (new art, step 4, N6): day on its left, night on its right, and a hand that
## goes round once a day in the clock's steps of ten minutes. It stands beside the HUD's corner
## box, never over it, and tells the time GameState keeps.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const VILLAGE: String = "res://world/areas/village/village.tscn"

var _area: Node


func before_test() -> void:
	GameState.clear()
	GameState.new_game()


func after_test() -> void:
	if is_instance_valid(_area):
		_area.free()
	_area = null
	GameState.clear()


func test_the_hand_points_down_at_dawn_into_the_sun_at_noon_up_at_dusk_and_into_the_night_at_midnight() -> void:
	var cases: Dictionary = {"06:00": Vector2.DOWN, "12:00": Vector2.LEFT, "18:00": Vector2.UP, "00:00": Vector2.RIGHT}
	for time: String in cases:
		var way: Vector2 = ClockDial.hand_direction(float(GameState.day_clock().in_day(time)))
		assert_bool(way.is_equal_approx(cases[time])).override_failure_message("%s: the hand points %s, not %s" % [time, way, cases[time]]).is_true()
	# The sun is on the left half of the dial, the moon on the right: noon's hand lies in the day.
	var noon: Array[Vector2i] = ClockDial.hand_cells(12.0 * 60.0)
	for cell: Vector2i in noon:
		assert_int(cell.x).override_failure_message("noon's hand lies on the day's half").is_less(int(UiParts.DIAL_CENTRE.x))


func test_the_hand_moves_in_steps_of_ten_minutes_and_goes_round_once_a_day() -> void:
	assert_float(ClockDial.hand_angle(12.0 * 60.0 + 9.0)).override_failure_message("12:09 shows as 12:00").is_equal(ClockDial.hand_angle(12.0 * 60.0))
	assert_float(ClockDial.hand_angle(12.0 * 60.0 + 10.0)).override_failure_message("12:10 has moved on").is_greater(ClockDial.hand_angle(12.0 * 60.0))
	# 02:00, the day's end, runs on past midnight: the same place as 02:00 on a clock.
	assert_float(ClockDial.hand_angle(26.0 * 60.0)).is_equal_approx(ClockDial.hand_angle(2.0 * 60.0), 0.0001)
	for minute: float in [360.0, 700.0, 1080.0, 1500.0]:
		for cell: Vector2i in ClockDial.hand_cells(minute):
			assert_bool(Rect2i(Vector2i.ZERO, Vector2i(UiParts.DIAL.size)).has_point(cell)).override_failure_message("the hand stays on the dial: %s" % cell).is_true()
			assert_float((Vector2(cell) + Vector2(0.5, 0.5)).distance_to(UiParts.DIAL_CENTRE)).override_failure_message("inside the ring").is_less(12.0)


func test_the_hud_shows_the_dial_beside_its_corner_and_the_hour_on_it() -> void:
	GameState.set_time(float(GameState.day_clock().in_day("13:24")))
	_area = Steps.load_area(VILLAGE, _area)
	var village: AreaController = _area
	village._update_hud()
	var hud: AreaHud = village.hud
	assert_object(hud.dial).is_not_null()
	assert_float(hud.dial.minute()).override_failure_message("the dial shows the hour, in the clock's steps").is_equal(13.0 * 60.0 + 20.0)
	var corner: Rect2 = Rect2((hud.get_node(^"Panel") as Control).position, hud.panel_size())
	var dial: Rect2 = Rect2(hud.dial.position, hud.dial.size)
	assert_bool(corner.intersects(dial)).override_failure_message("the dial stands beside the box, not over it").is_false()
	assert_float(dial.position.y).override_failure_message("level with the box's top").is_equal(corner.position.y)
	# A longer line widens the box, and the dial moves along with it.
	hud.set_items("A very long line of things carried, to widen the box")
	assert_bool(Rect2(hud.dial.position, hud.dial.size).intersects(Rect2(corner.position, hud.panel_size()))).override_failure_message("still beside it").is_false()
