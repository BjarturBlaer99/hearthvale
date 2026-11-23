extends GdUnitTestSuite
## PlateSequence (dungeon-difficulty-plan.md, decision 14): plates pressed in an order.


func test_in_order_it_moves_on_and_the_last_solves_it() -> void:
	var order: PlateSequence = PlateSequence.new(3)
	assert_that(order.press(1)).is_equal(PlateSequence.RIGHT)
	assert_that(order.press(2)).is_equal(PlateSequence.RIGHT)
	assert_bool(order.is_done()).is_false()
	assert_that(order.press(3)).is_equal(PlateSequence.DONE)
	assert_bool(order.is_done()).is_true()
	assert_that(order.press(1)).override_failure_message("solved, nothing changes it").is_equal(PlateSequence.SAME)


func test_out_of_turn_it_starts_over() -> void:
	var order: PlateSequence = PlateSequence.new(4)
	order.press(1)
	order.press(2)
	assert_that(order.press(4)).is_equal(PlateSequence.WRONG)
	assert_int(order.progress).is_equal(0)
	assert_that(order.press(2)).override_failure_message("2 is not a start").is_equal(PlateSequence.WRONG)
	assert_int(order.progress).is_equal(0)


func test_a_wrong_step_onto_the_first_plate_is_a_new_start() -> void:
	var order: PlateSequence = PlateSequence.new(3)
	order.press(2)
	assert_int(order.progress).is_equal(0)
	assert_that(order.press(1)).is_equal(PlateSequence.RIGHT)
	order.press(2)
	# Off the second and back onto the first: it was counted, so nothing changes.
	assert_that(order.press(1)).is_equal(PlateSequence.SAME)
	assert_int(order.progress).is_equal(2)
	assert_bool(order.is_counted(2)).is_true()
	assert_bool(order.is_counted(3)).is_false()


func test_a_reset_starts_it_over_unless_it_is_solved() -> void:
	var order: PlateSequence = PlateSequence.new(2)
	order.press(1)
	order.reset()
	assert_int(order.progress).is_equal(0)
	order.press(1)
	order.press(2)
	order.reset()
	assert_bool(order.is_done()).override_failure_message("a solved set stays solved").is_true()


func test_a_sets_places_must_be_one_to_n() -> void:
	assert_array(Array(PlateSequence.problems([2, 1, 3]))).is_empty()
	assert_array(Array(PlateSequence.problems([1, 2, 2]))).has_size(1)
	assert_array(Array(PlateSequence.problems([1, 3]))).has_size(1)
	assert_array(Array(PlateSequence.problems([0, 1]))).has_size(1)
