extends GdUnitTestSuite
## MenuCursor: up and down wrap round and skip options that can't be chosen; the cursor starts
## on the first that can (or stays on a kept one); labels mark the cursor and bracket the rest.


func test_it_starts_on_the_first_option_that_can_be_chosen_and_skips_the_rest() -> void:
	var cursor: MenuCursor = MenuCursor.new([
		MenuCursor.option(&"continue", "Continue", false),
		MenuCursor.option(&"new_game", "New game"),
		MenuCursor.option(&"quit", "Quit"),
	])
	assert_that(cursor.selected_id()).is_equal(&"new_game")
	cursor.move(1)
	assert_that(cursor.selected_id()).is_equal(&"quit")
	cursor.move(1)
	assert_that(cursor.selected_id()).override_failure_message("wraps, skipping Continue").is_equal(&"new_game")
	cursor.move(-1)
	assert_that(cursor.selected_id()).is_equal(&"quit")
	cursor.move(-2)
	assert_that(cursor.selected_id()).override_failure_message("two steps up, two options that can be chosen").is_equal(&"quit")
	cursor.move(3)
	assert_that(cursor.selected_id()).is_equal(&"new_game")


func test_lines_mark_the_cursor_and_bracket_what_cant_be_chosen() -> void:
	var cursor: MenuCursor = MenuCursor.new([MenuCursor.option(&"a", "Continue", false), MenuCursor.option(&"b", "New game")])
	assert_array(Array(cursor.lines())).is_equal(["  (Continue)", "> New game"])


func test_new_options_keep_the_cursor_where_it_was() -> void:
	var cursor: MenuCursor = MenuCursor.new([MenuCursor.option(&"a", "A"), MenuCursor.option(&"b", "B"), MenuCursor.option(&"c", "C")])
	cursor.set_options([MenuCursor.option(&"a", "A2"), MenuCursor.option(&"b", "B2"), MenuCursor.option(&"c", "C2")], &"c")
	assert_that(cursor.selected_id()).is_equal(&"c")
	cursor.set_options([MenuCursor.option(&"a", "A"), MenuCursor.option(&"c", "C", false)], &"c")
	assert_that(cursor.selected_id()).override_failure_message("a kept option that can't be chosen gives way").is_equal(&"a")


func test_nothing_to_choose_means_no_selection() -> void:
	var cursor: MenuCursor = MenuCursor.new([MenuCursor.option(&"a", "A", false)])
	assert_that(cursor.selected_id()).is_equal(&"")
	cursor.move(1)
	assert_that(cursor.selected_id()).is_equal(&"")
	assert_that(MenuCursor.new().selected_id()).is_equal(&"")
