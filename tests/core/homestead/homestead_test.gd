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


# --- What is set down (phase 2) -----------------------------------------------

func test_a_new_homestead_has_nothing_set_down() -> void:
	assert_int(_homestead.placed_count()).is_equal(0)
	assert_array(_homestead.placed(Placement.LYING)).is_empty()
	assert_array(_homestead.placed(Placement.STANDING)).is_empty()
	for cell: Vector2i in [Vector2i(0, 0), Vector2i(20, 10)]:
		assert_that(_homestead.lying_at(cell)).is_equal(&"")
		assert_that(_homestead.standing_at(cell)).is_equal(&"")
		assert_int(_homestead.age_at(cell)).is_equal(0)
	assert_bool(_homestead.to_dict().has("lying") or _homestead.to_dict().has("standing")).override_failure_message("saved as phase 1 saved it").is_false()


func test_a_cell_holds_one_lying_thing_and_one_standing() -> void:
	var cell: Vector2i = Vector2i(20, 10)
	assert_bool(_homestead.set_down(cell, Placement.LYING, &"stone_path")).is_true()
	assert_that(_homestead.lying_at(cell)).is_equal(&"stone_path")
	assert_that(_homestead.standing_at(cell)).override_failure_message("nothing stands there yet").is_equal(&"")
	assert_bool(_homestead.set_down(cell, Placement.STANDING, &"fence")).override_failure_message("a fence on a paved cell").is_true()
	assert_that(_homestead.standing_at(cell)).is_equal(&"fence")
	assert_that(_homestead.thing_at(cell, Placement.LYING)).is_equal(&"stone_path")
	assert_that(_homestead.thing_at(cell, Placement.STANDING)).is_equal(&"fence")
	assert_that(_homestead.thing_at(cell, &"floating")).is_equal(&"")
	assert_int(_homestead.placed_count()).is_equal(2)
	# A second of either layer is refused, and what was there stays.
	assert_bool(_homestead.set_down(cell, Placement.LYING, &"dirt_path")).is_false()
	assert_bool(_homestead.set_down(cell, Placement.STANDING, &"gate")).is_false()
	assert_that(_homestead.lying_at(cell)).is_equal(&"stone_path")
	assert_that(_homestead.standing_at(cell)).is_equal(&"fence")
	assert_int(_homestead.placed_count()).is_equal(2)
	# Its neighbours are as they were, and so is its mirror.
	assert_that(_homestead.standing_at(Vector2i(21, 10))).is_equal(&"")
	assert_that(_homestead.lying_at(Vector2i(10, 20))).is_equal(&"")
	# What is no cell, no layer or no item is never set down.
	assert_bool(_homestead.set_down(Vector2i(-1, 3), Placement.LYING, &"dirt_path")).is_false()
	assert_bool(_homestead.set_down(Vector2i(3, -1), Placement.STANDING, &"fence")).is_false()
	assert_bool(_homestead.set_down(Vector2i(3, 3), &"floating", &"fence")).is_false()
	assert_bool(_homestead.set_down(Vector2i(3, 3), Placement.STANDING, &"")).is_false()
	assert_int(_homestead.placed_count()).is_equal(2)
	# Setting a thing down clears nothing, and clearing sets nothing down.
	assert_int(_homestead.cleared_count()).is_equal(0)
	_homestead.clear(Vector2i(3, 3))
	assert_int(_homestead.placed_count()).is_equal(2)


func test_a_thing_is_taken_up_and_its_cell_is_free_again() -> void:
	var cell: Vector2i = Vector2i(20, 10)
	_homestead.set_down(cell, Placement.LYING, &"stone_path")
	_homestead.set_down(cell, Placement.STANDING, &"fence")
	assert_that(_homestead.take_up(cell, Placement.STANDING)).is_equal(&"fence")
	assert_that(_homestead.standing_at(cell)).is_equal(&"")
	assert_that(_homestead.lying_at(cell)).override_failure_message("the path under it stays").is_equal(&"stone_path")
	assert_that(_homestead.take_up(cell, Placement.STANDING)).override_failure_message("nothing stands there now").is_equal(&"")
	assert_that(_homestead.take_up(cell, Placement.LYING)).is_equal(&"stone_path")
	assert_that(_homestead.take_up(cell, Placement.LYING)).is_equal(&"")
	assert_that(_homestead.take_up(cell, &"floating")).is_equal(&"")
	assert_int(_homestead.placed_count()).is_equal(0)
	assert_bool(_homestead.set_down(cell, Placement.STANDING, &"gate")).override_failure_message("and can be built on again").is_true()


func test_a_thing_is_moved_as_it_is() -> void:
	var from: Vector2i = Vector2i(5, 5)
	var to: Vector2i = Vector2i(9, 7)
	_homestead.set_down(from, Placement.STANDING, &"oak_sapling", 2)
	_homestead.set_down(from, Placement.LYING, &"dirt_path")
	assert_bool(_homestead.move(from, to, Placement.STANDING)).is_true()
	assert_that(_homestead.standing_at(from)).is_equal(&"")
	assert_that(_homestead.standing_at(to)).is_equal(&"oak_sapling")
	assert_int(_homestead.age_at(to)).override_failure_message("a sapling keeps its mornings").is_equal(2)
	assert_that(_homestead.lying_at(from)).override_failure_message("the path stays where it lay").is_equal(&"dirt_path")
	assert_that(_homestead.lying_at(to)).is_equal(&"")
	# Nothing to move, nowhere to move it, or something there already: nothing changes.
	assert_bool(_homestead.move(from, to, Placement.STANDING)).override_failure_message("nothing stands at the old place").is_false()
	assert_bool(_homestead.move(to, to, Placement.STANDING)).is_false()
	assert_bool(_homestead.move(to, Vector2i(-1, 0), Placement.STANDING)).is_false()
	_homestead.set_down(from, Placement.STANDING, &"fence")
	assert_bool(_homestead.move(to, from, Placement.STANDING)).override_failure_message("a fence stands there").is_false()
	assert_that(_homestead.standing_at(to)).is_equal(&"oak_sapling")
	assert_int(_homestead.age_at(to)).is_equal(2)
	assert_int(_homestead.placed_count()).is_equal(3)
	# A lying thing moves the same way.
	assert_bool(_homestead.move(from, Vector2i(6, 5), Placement.LYING)).is_true()
	assert_that(_homestead.lying_at(Vector2i(6, 5))).is_equal(&"dirt_path")
	assert_that(_homestead.lying_at(from)).is_equal(&"")


func test_what_is_set_down_is_listed_row_by_row() -> void:
	for at: Array in [[Vector2i(30, 20), &"fence"], [Vector2i(2, 8), &"gate"], [Vector2i(10, 2), &"fence"], [Vector2i(9, 2), &"oak_sapling"]]:
		_homestead.set_down(at[0], Placement.STANDING, at[1], 3 if at[1] == &"oak_sapling" else 0)
	_homestead.set_down(Vector2i(2, 8), Placement.LYING, &"dirt_path")
	assert_array(_homestead.placed(Placement.STANDING)).is_equal([
		{"cell": Vector2i(9, 2), "item": &"oak_sapling", "age": 3}, {"cell": Vector2i(10, 2), "item": &"fence", "age": 0},
		{"cell": Vector2i(2, 8), "item": &"gate", "age": 0}, {"cell": Vector2i(30, 20), "item": &"fence", "age": 0},
	])
	assert_array(_homestead.placed(Placement.LYING)).is_equal([{"cell": Vector2i(2, 8), "item": &"dirt_path", "age": 0}])
	assert_array(_homestead.placed(&"floating")).is_empty()
	assert_dict(_homestead.to_dict()).is_equal({
		"cleared": [],
		"lying": {"2,8": "dirt_path"},
		"standing": {"9,2": {"item": "oak_sapling", "age": 3}, "10,2": {"item": "fence"}, "2,8": {"item": "gate"}, "30,20": {"item": "fence"}},
	})


func test_a_morning_comes_to_what_grows_and_to_nothing_else() -> void:
	var mornings: Dictionary = {"oak_sapling": 4, "cherry_sapling": 6}
	_homestead.set_down(Vector2i(4, 4), Placement.STANDING, &"oak_sapling")
	_homestead.set_down(Vector2i(5, 4), Placement.STANDING, &"cherry_sapling", 5)
	_homestead.set_down(Vector2i(6, 4), Placement.STANDING, &"fence")
	_homestead.set_down(Vector2i(4, 4), Placement.LYING, &"dirt_path")
	_homestead.clear(Vector2i(8, 8))
	assert_bool(_homestead.grow(mornings)).is_true()
	assert_int(_homestead.age_at(Vector2i(4, 4))).is_equal(1)
	assert_int(_homestead.age_at(Vector2i(5, 4))).is_equal(6)
	assert_int(_homestead.age_at(Vector2i(6, 4))).override_failure_message("a fence doesn't grow").is_equal(0)
	for morning: int in 3:
		assert_bool(_homestead.grow(mornings)).override_failure_message("the oak is still growing").is_true()
	assert_int(_homestead.age_at(Vector2i(4, 4))).is_equal(4)
	# Grown, they are no older for another morning, and nothing is news.
	assert_bool(_homestead.grow(mornings)).override_failure_message("both are trees: nothing grew").is_false()
	assert_int(_homestead.age_at(Vector2i(4, 4))).is_equal(4)
	assert_int(_homestead.age_at(Vector2i(5, 4))).is_equal(6)
	# Everything is where it was, and what was cleared is cleared.
	assert_int(_homestead.placed_count()).is_equal(4)
	assert_that(_homestead.lying_at(Vector2i(4, 4))).is_equal(&"dirt_path")
	assert_bool(_homestead.is_cleared(Vector2i(8, 8))).is_true()
	assert_int(_homestead.cleared_count()).is_equal(1)
	assert_bool(Homestead.new().grow(mornings)).override_failure_message("an empty homestead").is_false()


func test_what_is_set_down_is_saved_and_taken_up_again() -> void:
	_homestead.clear(Vector2i(5, 9))
	_homestead.set_down(Vector2i(20, 10), Placement.LYING, &"stone_path")
	_homestead.set_down(Vector2i(20, 10), Placement.STANDING, &"fence")
	_homestead.set_down(Vector2i(21, 10), Placement.STANDING, &"oak_sapling", 3)
	var saved: Dictionary = _homestead.to_dict()
	var other: Homestead = Homestead.new()
	other.set_down(Vector2i(1, 1), Placement.STANDING, &"gate")
	other.load_saved(JSON.parse_string(JSON.stringify(saved)))
	assert_that(other.standing_at(Vector2i(1, 1))).override_failure_message("what was there before is gone").is_equal(&"")
	assert_dict(other.to_dict()).is_equal(saved)
	assert_that(other.lying_at(Vector2i(20, 10))).is_equal(&"stone_path")
	assert_that(other.standing_at(Vector2i(20, 10))).is_equal(&"fence")
	assert_int(other.age_at(Vector2i(21, 10))).override_failure_message("a sapling's mornings are kept").is_equal(3)
	assert_bool(other.is_cleared(Vector2i(5, 9))).is_true()
	# A homestead saved before anything could be set down (phase 1's) has nothing set down.
	other.load_saved({"cleared": ["5,9"]})
	assert_int(other.placed_count()).is_equal(0)
	assert_bool(other.is_cleared(Vector2i(5, 9))).is_true()
	# What doesn't read as it should is left out, the rest kept.
	other.load_saved({"cleared": "all", "lying": {"3,3": "dirt_path", "x": "dirt_path", "4,4": 7, "-1,2": "dirt_path", "5,5": ""},
		"standing": {"3,3": {"item": "fence"}, "6,6": "fence", "7,7": {"age": 2}, "8,8": {"item": "oak_sapling", "age": 2.0}, "9;9": {"item": "fence"}}})
	assert_int(other.cleared_count()).is_equal(0)
	assert_array(other.placed(Placement.LYING)).is_equal([{"cell": Vector2i(3, 3), "item": &"dirt_path", "age": 0}])
	assert_array(other.placed(Placement.STANDING)).is_equal([
		{"cell": Vector2i(3, 3), "item": &"fence", "age": 0}, {"cell": Vector2i(8, 8), "item": &"oak_sapling", "age": 2},
	])
	for junk: Variant in [{"lying": [], "standing": "none"}, {"lying": null}, []]:
		other.load_saved(junk)
		assert_int(other.placed_count()).override_failure_message("%s" % [junk]).is_equal(0)


func test_a_thing_saved_on_the_wrong_layer_or_unknown_is_left_out() -> void:
	var layers: Dictionary = {"dirt_path": Placement.LYING, "fence": Placement.STANDING}
	var layer_of: Callable = func(item_id: String) -> StringName: return layers.get(item_id, &"")
	_homestead.load_saved({
		"lying": {"1,1": "dirt_path", "2,2": "fence", "3,3": "carpet"},
		"standing": {"1,1": {"item": "fence"}, "4,4": {"item": "dirt_path"}, "5,5": {"item": "statue"}},
	}, layer_of)
	assert_array(_homestead.placed(Placement.LYING)).is_equal([{"cell": Vector2i(1, 1), "item": &"dirt_path", "age": 0}])
	assert_array(_homestead.placed(Placement.STANDING)).is_equal([{"cell": Vector2i(1, 1), "item": &"fence", "age": 0}])
