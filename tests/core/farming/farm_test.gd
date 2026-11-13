extends GdUnitTestSuite
## Farm (P3a): the hero's plot of eighteen cells; tilling and watering one; the morning that
## dries the soil; and the farm as it is saved. The numbers are the game's own
## (data/rules/farm.json).

const FARM_RULES: String = "res://data/rules/farm.json"

var _data: Dictionary
var _farm: Farm


func before_test() -> void:
	_data = JSON.parse_string(FileAccess.get_file_as_string(FARM_RULES))
	_farm = Farm.new(_data)


func test_the_plot_is_eighteen_cells_of_bare_soil() -> void:
	assert_that(_farm.size).is_equal(Vector2i(6, 3))
	assert_int(_farm.size.x * _farm.size.y).is_equal(18)
	assert_int(_farm.count_of(Farm.BARE)).is_equal(18)
	assert_int(_farm.count_of(Farm.TILLED)).is_equal(0)
	for cell: Vector2i in [Vector2i(0, 0), Vector2i(5, 0), Vector2i(0, 2), Vector2i(5, 2), Vector2i(3, 1)]:
		assert_bool(_farm.has(cell)).override_failure_message("%s is a cell of the plot" % cell).is_true()
		assert_that(_farm.state_of(cell)).is_equal(Farm.BARE)
	for cell: Vector2i in [Vector2i(-1, 0), Vector2i(6, 0), Vector2i(0, 3), Vector2i(0, -1), Vector2i(12, 18)]:
		assert_bool(_farm.has(cell)).override_failure_message("%s is not" % cell).is_false()
	assert_int(_farm.wither_after).override_failure_message("two dry mornings wither a crop (3b)").is_equal(2)


func test_the_hoe_tills_a_bare_cell_once() -> void:
	assert_bool(_farm.till(Vector2i(2, 1))).is_true()
	assert_that(_farm.state_of(Vector2i(2, 1))).is_equal(Farm.TILLED)
	assert_bool(_farm.is_tilled(Vector2i(2, 1))).is_true()
	assert_bool(_farm.is_watered(Vector2i(2, 1))).is_false()
	assert_bool(_farm.till(Vector2i(2, 1))).override_failure_message("already tilled").is_false()
	assert_that(_farm.state_of(Vector2i(3, 1))).override_failure_message("its neighbour is as it was").is_equal(Farm.BARE)
	assert_int(_farm.count_of(Farm.TILLED)).is_equal(1)
	assert_bool(_farm.till(Vector2i(6, 1))).override_failure_message("no soil outside the plot").is_false()
	assert_bool(_farm.till(Vector2i(-1, -1))).is_false()
	assert_bool(_farm.is_tilled(Vector2i(6, 1))).is_false()


func test_the_can_waters_tilled_soil_once() -> void:
	assert_bool(_farm.water(Vector2i(1, 0))).override_failure_message("bare soil isn't watered").is_false()
	assert_that(_farm.state_of(Vector2i(1, 0))).is_equal(Farm.BARE)
	_farm.till(Vector2i(1, 0))
	assert_bool(_farm.water(Vector2i(1, 0))).is_true()
	assert_that(_farm.state_of(Vector2i(1, 0))).is_equal(Farm.WATERED)
	assert_bool(_farm.is_tilled(Vector2i(1, 0))).override_failure_message("watered soil is still tilled").is_true()
	assert_bool(_farm.water(Vector2i(1, 0))).override_failure_message("wet already").is_false()
	assert_bool(_farm.till(Vector2i(1, 0))).override_failure_message("and can't be tilled again").is_false()
	assert_bool(_farm.water(Vector2i(9, 9))).is_false()
	assert_int(_farm.count_of(Farm.WATERED)).is_equal(1)
	assert_int(_farm.count_of(Farm.TILLED)).override_failure_message("TILLED counts the dry ones").is_equal(0)


func test_a_new_morning_dries_the_soil_and_leaves_it_tilled() -> void:
	_farm.till(Vector2i(0, 0))
	_farm.till(Vector2i(1, 0))
	_farm.water(Vector2i(0, 0))
	_farm.new_day()
	assert_that(_farm.state_of(Vector2i(0, 0))).override_failure_message("yesterday's water is gone").is_equal(Farm.TILLED)
	assert_that(_farm.state_of(Vector2i(1, 0))).is_equal(Farm.TILLED)
	assert_that(_farm.state_of(Vector2i(2, 0))).is_equal(Farm.BARE)
	assert_bool(_farm.water(Vector2i(0, 0))).override_failure_message("and can be watered again").is_true()
	for i: int in 30:
		_farm.new_day()
	assert_bool(_farm.is_tilled(Vector2i(1, 0))).override_failure_message("tilled soil stays tilled").is_true()


func test_the_farm_is_saved_and_taken_up_again() -> void:
	_farm.till(Vector2i(0, 0))
	_farm.till(Vector2i(5, 2))
	_farm.water(Vector2i(5, 2))
	var saved: Dictionary = _farm.to_dict()
	assert_dict(saved).is_equal({"cells": {"0,0": {"watered": false}, "5,2": {"watered": true}}})
	# It goes through JSON as a save does.
	var other: Farm = Farm.new(_data)
	other.till(Vector2i(3, 1))
	other.load_saved(JSON.parse_string(JSON.stringify(saved)))
	assert_that(other.state_of(Vector2i(0, 0))).is_equal(Farm.TILLED)
	assert_that(other.state_of(Vector2i(5, 2))).is_equal(Farm.WATERED)
	assert_that(other.state_of(Vector2i(3, 1))).override_failure_message("what was there before is gone").is_equal(Farm.BARE)
	assert_dict(other.to_dict()).is_equal(saved)
	# Changing what was handed out changes nothing here.
	saved["cells"]["0,0"]["watered"] = true
	assert_bool(_farm.is_watered(Vector2i(0, 0))).is_false()


func test_a_save_cant_put_soil_where_there_is_none() -> void:
	_farm.load_saved({"cells": {"9,9": {"watered": true}, "-1,0": {}, "2,1": {"watered": true}, "soil": {}, "1,1": "wet", "4,2": {}}})
	assert_dict(_farm.to_dict()).is_equal({"cells": {"2,1": {"watered": true}, "4,2": {"watered": false}}})
	for junk: Variant in [null, 7, "farm", [], {}, {"cells": []}, {"cells": null}]:
		_farm.till(Vector2i(0, 0))
		_farm.load_saved(junk)
		assert_int(_farm.count_of(Farm.BARE)).override_failure_message("%s is an untouched plot" % [junk]).is_equal(18)


func test_cells_have_keys() -> void:
	assert_str(Farm.key(Vector2i(4, 2))).is_equal("4,2")
	assert_that(Farm.cell_of("4,2")).is_equal(Vector2i(4, 2))
	for cell: Vector2i in [Vector2i(0, 0), Vector2i(5, 2), Vector2i(17, 3)]:
		assert_that(Farm.cell_of(Farm.key(cell))).is_equal(cell)
	for bad: String in ["", "4", "4,2,1", "a,b", "4;2"]:
		assert_that(Farm.cell_of(bad)).override_failure_message("'%s' names no cell" % bad).is_equal(Vector2i(-1, -1))


func test_the_farms_rules_are_sound_and_bad_ones_are_named() -> void:
	assert_array(Array(Farm.problems(_data))).is_empty()
	assert_dict(Farm.DEFAULTS["plot"]).override_failure_message("what a missing rule falls back to is the game's own").is_equal({"columns": int(_data["plot"]["columns"]), "rows": int(_data["plot"]["rows"])})
	assert_int(int(Farm.DEFAULTS["wither_after"])).is_equal(int(_data["wither_after"]))
	assert_that(Farm.new().size).is_equal(Vector2i(6, 3))
	assert_that(Farm.new({"plot": {"columns": 2, "rows": 4}}).size).override_failure_message("the plot's size is the rules'").is_equal(Vector2i(2, 4))
	assert_array(Array(Farm.problems({"plot": {"columns": 0, "rows": 3}, "wither_after": 1.5}))).contains_exactly([
		"'plot' needs 'columns' and 'rows', each a whole number of 1 or more.",
		"'wither_after' must be a whole number of 1 or more: the dry mornings that wither a crop.",
	])
	assert_int(Farm.problems({}).size()).is_equal(2)
	assert_int(Farm.problems({"plot": "big", "wither_after": 2}).size()).is_equal(1)
