extends GdUnitTestSuite
## Homestead (2026-11-17, phase 1), pure: the cells of the hero's land that he has cleared for
## good, and the homestead as it is saved.

var _homestead: Homestead


func before_test() -> void:
	_homestead = Homestead.new()


func test_a_new_homestead_has_nothing_cleared() -> void:
	assert_int(_homestead.cleared_count()).is_equal(0)
	assert_array(_homestead.cleared_cells()).is_empty()
	for cell: Vector2i in [Vector2i(0, 0), Vector2i(28, 17), Vector2i(39, 29)]:
		assert_bool(_homestead.is_cleared(cell)).override_failure_message("%s" % cell).is_false()
	assert_dict(_homestead.to_dict()).is_equal({"cleared": []})


func test_a_cell_is_cleared_once_and_for_good() -> void:
	assert_bool(_homestead.clear(Vector2i(28, 17))).is_true()
	assert_bool(_homestead.is_cleared(Vector2i(28, 17))).is_true()
	assert_bool(_homestead.is_cleared(Vector2i(29, 17))).override_failure_message("its neighbour is as it was").is_false()
	assert_bool(_homestead.is_cleared(Vector2i(17, 28))).override_failure_message("a cell is not its mirror").is_false()
	assert_bool(_homestead.clear(Vector2i(28, 17))).override_failure_message("cleared already: no news").is_false()
	assert_int(_homestead.cleared_count()).is_equal(1)
	# Nothing here undoes it: there is no way to put a thing back.
	assert_bool(_homestead.has_method(&"restore") or _homestead.has_method(&"unclear") or _homestead.has_method(&"new_day")).is_false()
	# What is no cell is never cleared.
	for bad: Vector2i in [Vector2i(-1, 0), Vector2i(3, -2), Vector2i(-1, -1)]:
		assert_bool(_homestead.clear(bad)).override_failure_message("%s is no cell" % bad).is_false()
	assert_int(_homestead.cleared_count()).is_equal(1)


func test_the_cleared_cells_are_listed_row_by_row() -> void:
	for cell: Vector2i in [Vector2i(30, 20), Vector2i(2, 8), Vector2i(10, 2), Vector2i(29, 20), Vector2i(11, 2)]:
		_homestead.clear(cell)
	assert_array(_homestead.cleared_cells()).is_equal([Vector2i(10, 2), Vector2i(11, 2), Vector2i(2, 8), Vector2i(29, 20), Vector2i(30, 20)])
	assert_dict(_homestead.to_dict()).is_equal({"cleared": ["10,2", "11,2", "2,8", "29,20", "30,20"]})


func test_the_homestead_is_saved_and_taken_up_again() -> void:
	for cell: Vector2i in [Vector2i(28, 17), Vector2i(5, 9), Vector2i(11, 21)]:
		_homestead.clear(cell)
	var saved: Dictionary = _homestead.to_dict()
	# It goes through JSON as a save does.
	var other: Homestead = Homestead.new()
	other.clear(Vector2i(3, 3))
	other.load_saved(JSON.parse_string(JSON.stringify(saved)))
	assert_bool(other.is_cleared(Vector2i(3, 3))).override_failure_message("what was there before is gone").is_false()
	for cell: Vector2i in [Vector2i(28, 17), Vector2i(5, 9), Vector2i(11, 21)]:
		assert_bool(other.is_cleared(cell)).override_failure_message("%s" % cell).is_true()
	assert_dict(other.to_dict()).is_equal(saved)
	# Changing what was handed out changes nothing here.
	(saved["cleared"] as Array).append("1,1")
	assert_bool(_homestead.is_cleared(Vector2i(1, 1))).is_false()


func test_a_save_that_is_no_homestead_is_an_overgrown_one() -> void:
	for junk: Variant in [null, 7, "farm", [], {}, {"cleared": null}, {"cleared": {}}, {"cleared": "all"}]:
		_homestead.clear(Vector2i(4, 4))
		_homestead.load_saved(junk)
		assert_int(_homestead.cleared_count()).override_failure_message("%s is a homestead with nothing cleared" % [junk]).is_equal(0)
	# What doesn't read as a cell is left out, and a cell named twice is one cell.
	_homestead.load_saved({"cleared": ["6,7", "x", 12, "-1,4", "6,7", "4;2", "9,9,9", {"x": 1}, "30,22"]})
	assert_array(_homestead.cleared_cells()).is_equal([Vector2i(6, 7), Vector2i(30, 22)])
