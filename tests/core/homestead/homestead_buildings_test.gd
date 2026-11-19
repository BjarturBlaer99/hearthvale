extends GdUnitTestSuite
## What Homestead keeps of the buildings (the Homestead, phase 3), pure: one of each, where its
## top-left corner is, a site the day its kit is set down and a building from the next
## morning, an upgrade bought for one that stands and finished the morning after, a move as it
## is, the silo's hay, and all of it through a save.

var _homestead: Homestead


func before_test() -> void:
	_homestead = Homestead.new()


func test_a_kit_set_down_is_a_site_today_and_a_building_tomorrow() -> void:
	assert_bool(_homestead.has_building(&"well")).is_false()
	assert_bool(_homestead.put_building(&"well", Vector2i(33, 11), 4)).is_true()
	assert_bool(_homestead.has_building(&"well")).is_true()
	assert_that(_homestead.building_at(&"well")).is_equal(Vector2i(33, 11))
	assert_int(_homestead.building_day(&"well")).is_equal(4)
	assert_bool(_homestead.is_site(&"well", 4)).override_failure_message("today it is a site").is_true()
	assert_bool(_homestead.is_standing(&"well", 4)).is_false()
	assert_bool(_homestead.is_standing(&"well", 5)).override_failure_message("the next morning it stands").is_true()
	assert_bool(_homestead.is_site(&"well", 5)).is_false()
	assert_bool(_homestead.is_standing(&"well", 9)).is_true()
	# One of each: a second is refused, and so is no building and no cell.
	assert_bool(_homestead.put_building(&"well", Vector2i(3, 3), 5)).override_failure_message("one of each").is_false()
	assert_that(_homestead.building_at(&"well")).is_equal(Vector2i(33, 11))
	assert_bool(_homestead.put_building(&"", Vector2i(3, 3), 5)).is_false()
	assert_bool(_homestead.put_building(&"silo", Vector2i(-1, 3), 5)).is_false()
	assert_array(_homestead.building_ids()).is_equal([&"well"])
	assert_that(_homestead.building_at(&"silo")).is_equal(Buildings.NO_CELL)


func test_a_morning_says_what_it_finished() -> void:
	_homestead.put_building(&"well", Vector2i(33, 11), 4)
	_homestead.put_building(&"silo", Vector2i(3, 3), 5)
	assert_array(_homestead.finished_on(4)).is_empty()
	assert_array(_homestead.finished_on(5)).is_equal([{"id": &"well", "big": false}])
	assert_array(_homestead.finished_on(6)).is_equal([{"id": &"silo", "big": false}])
	assert_array(_homestead.finished_on(7)).override_failure_message("said once").is_empty()


func test_an_upgrade_is_bought_for_a_building_that_stands_and_finished_the_next_morning() -> void:
	_homestead.put_building(&"coop", Vector2i(5, 10), 3)
	assert_bool(_homestead.upgrade(&"coop", 3)).override_failure_message("not for a site").is_false()
	assert_bool(_homestead.upgrade(&"barn", 4)).override_failure_message("not for one that isn't there").is_false()
	assert_bool(_homestead.upgrade(&"coop", 6)).is_true()
	assert_bool(_homestead.has_upgrade(&"coop")).is_true()
	assert_bool(_homestead.is_upgrading(&"coop", 6)).is_true()
	assert_bool(_homestead.is_big(&"coop", 6)).override_failure_message("finished tomorrow").is_false()
	assert_bool(_homestead.is_big(&"coop", 7)).is_true()
	assert_bool(_homestead.is_upgrading(&"coop", 7)).is_false()
	assert_bool(_homestead.upgrade(&"coop", 8)).override_failure_message("one upgrade").is_false()
	assert_array(_homestead.finished_on(7)).is_equal([{"id": &"coop", "big": true}])
	assert_that(_homestead.building_at(&"coop")).override_failure_message("the same place").is_equal(Vector2i(5, 10))


func test_a_building_is_moved_as_it_is_and_taken_away() -> void:
	_homestead.put_building(&"coop", Vector2i(5, 10), 3)
	_homestead.upgrade(&"coop", 4)
	assert_bool(_homestead.move_building(&"coop", Vector2i(12, 3))).is_true()
	assert_that(_homestead.building_at(&"coop")).is_equal(Vector2i(12, 3))
	assert_int(_homestead.building_day(&"coop")).override_failure_message("moving builds nothing again").is_equal(3)
	assert_bool(_homestead.is_big(&"coop", 5)).override_failure_message("its upgrade goes with it").is_true()
	assert_bool(_homestead.move_building(&"coop", Vector2i(12, 3))).override_failure_message("nowhere new").is_false()
	assert_bool(_homestead.move_building(&"barn", Vector2i(1, 1))).is_false()
	assert_bool(_homestead.move_building(&"coop", Vector2i(-2, 1))).is_false()
	assert_bool(_homestead.remove_building(&"coop")).is_true()
	assert_bool(_homestead.has_building(&"coop")).is_false()
	assert_bool(_homestead.remove_building(&"coop")).is_false()
	# Gone, it can be set down again.
	assert_bool(_homestead.put_building(&"coop", Vector2i(5, 10), 9)).is_true()
	assert_bool(_homestead.has_upgrade(&"coop")).override_failure_message("a new coop is a plain one").is_false()


func test_the_silo_holds_so_much_hay_and_no_more() -> void:
	assert_int(_homestead.hay).is_equal(0)
	assert_int(_homestead.add_hay(14, 60)).is_equal(14)
	assert_int(_homestead.add_hay(50, 60)).override_failure_message("only what there is room for").is_equal(46)
	assert_int(_homestead.hay).is_equal(60)
	assert_int(_homestead.add_hay(3, 60)).is_equal(0)
	assert_int(_homestead.add_hay(-4, 60)).is_equal(0)
	assert_int(_homestead.hay).is_equal(60)


func test_buildings_and_hay_go_through_a_save() -> void:
	_homestead.clear(Vector2i(2, 2))
	_homestead.put_building(&"coop", Vector2i(5, 10), 3)
	_homestead.upgrade(&"coop", 4)
	_homestead.put_building(&"well", Vector2i(33, 11), 6)
	_homestead.add_hay(12, 60)
	var saved: Dictionary = _homestead.to_dict()
	assert_dict(saved).is_equal({"cleared": ["2,2"], "buildings": {"coop": {"at": "5,10", "day": 3, "big_day": 4}, "well": {"at": "33,11", "day": 6}}, "hay": 12})
	var other: Homestead = Homestead.new()
	other.put_building(&"barn", Vector2i(1, 1), 1)
	other.load_saved(JSON.parse_string(JSON.stringify(saved)))
	assert_bool(other.has_building(&"barn")).override_failure_message("what was there before is gone").is_false()
	assert_dict(other.to_dict()).is_equal(saved)
	assert_bool(other.is_big(&"coop", 5)).is_true()
	assert_bool(other.is_site(&"well", 6)).is_true()
	assert_int(other.hay).is_equal(12)
	# A building the game doesn't know is left out; a phase 2 save has none and no hay.
	var known: Callable = func(id: String) -> bool: return id != "coop"
	other.load_saved(JSON.parse_string(JSON.stringify(saved)), Callable(), known)
	assert_array(other.building_ids()).is_equal([&"well"])
	other.load_saved({"cleared": ["2,2"], "standing": {"3,3": {"item": "fence"}}})
	assert_array(other.building_ids()).is_empty()
	assert_int(other.hay).is_equal(0)
	assert_dict(other.to_dict()).override_failure_message("written as phase 2 wrote it").is_equal({"cleared": ["2,2"], "standing": {"3,3": {"item": "fence"}}})
	# Junk in the save is left out.
	for junk: Variant in [{"buildings": 3}, {"buildings": {"well": "here"}}, {"buildings": {"well": {"day": 2}}}, {"hay": "lots"}]:
		other.load_saved(junk)
		assert_array(other.building_ids()).override_failure_message("%s" % [junk]).is_empty()
		assert_int(other.hay).is_equal(0)
