extends GdUnitTestSuite
## Growth (P3b): a seed planted in tilled soil; a stage each morning it was watered the day
## before; withering after two dry mornings in a row; a ripe crop that waits; the harvest; and
## crops in a save. Farm is told how long each crop takes, so these use made-up crops.

const FARM_RULES: String = "res://data/rules/farm.json"
## How long the crops of these tests take (crop id -> mornings).
const DAYS: Dictionary = {"radish": 3, "leek": 4, "marrow": 8}
const A: Vector2i = Vector2i(1, 1)
const B: Vector2i = Vector2i(2, 1)

var _farm: Farm


func before_test() -> void:
	_farm = Farm.new(JSON.parse_string(FileAccess.get_file_as_string(FARM_RULES)))
	_farm.till(A)
	_farm.till(B)


func test_a_seed_is_planted_in_tilled_soil_with_nothing_in_it() -> void:
	assert_bool(_farm.has_crop(A)).is_false()
	assert_str(_farm.crop_at(A)).is_equal("")
	assert_that(_farm.phase_of(A, 3)).override_failure_message("nothing planted, no phase").is_equal(&"")
	assert_bool(_farm.plant(A, "radish")).is_true()
	assert_str(_farm.crop_at(A)).is_equal("radish")
	assert_int(_farm.stage_of(A)).is_equal(0)
	assert_that(_farm.phase_of(A, 3)).is_equal(Farm.SEEDED)
	assert_that(_farm.state_of(A)).override_failure_message("the soil is as it was").is_equal(Farm.TILLED)
	assert_bool(_farm.plant(A, "leek")).override_failure_message("something grows here already").is_false()
	assert_str(_farm.crop_at(A)).is_equal("radish")
	assert_bool(_farm.plant(Vector2i(4, 2), "radish")).override_failure_message("bare soil").is_false()
	assert_bool(_farm.plant(Vector2i(9, 9), "radish")).override_failure_message("off the plot").is_false()
	assert_bool(_farm.plant(B, "")).override_failure_message("no crop, nothing planted").is_false()
	assert_int(_farm.crop_count()).is_equal(1)
	# Watered soil takes a seed too, and a planted cell can be watered.
	_farm.water(B)
	assert_bool(_farm.plant(B, "leek")).is_true()
	assert_bool(_farm.water(A)).is_true()
	assert_bool(_farm.till(A)).override_failure_message("the hoe finds it tilled").is_false()


func test_a_crop_grows_a_stage_each_morning_it_was_watered_the_day_before() -> void:
	_farm.plant(A, "radish")
	for morning: int in [1, 2, 3]:
		assert_bool(_farm.is_ripe(A, 3)).override_failure_message("not ripe before its third morning").is_false()
		_farm.water(A)
		_farm.new_day(DAYS)
		assert_int(_farm.stage_of(A)).override_failure_message("morning %d" % morning).is_equal(morning)
		assert_bool(_farm.is_watered(A)).override_failure_message("the soil is dry again").is_false()
	assert_bool(_farm.is_ripe(A, 3)).override_failure_message("ripe on its third morning").is_true()
	assert_that(_farm.phase_of(A, 3)).is_equal(Farm.RIPE)
	# The phases of an eight-day crop: a sprout for the first half, growing for the second.
	_farm.plant(B, "marrow")
	var seen: Array = [_farm.phase_of(B, 8)]
	for morning: int in 8:
		_farm.water(B)
		_farm.new_day(DAYS)
		seen.append(_farm.phase_of(B, 8))
	assert_array(seen).is_equal([Farm.SEEDED, Farm.SPROUT, Farm.SPROUT, Farm.SPROUT, Farm.GROWING, Farm.GROWING, Farm.GROWING, Farm.GROWING, Farm.RIPE])
	# And of a three-day one: every phase shows once.
	_farm.till(Vector2i(0, 0))
	_farm.plant(Vector2i(0, 0), "radish")
	var quick: Array = []
	for morning: int in 3:
		_farm.water(Vector2i(0, 0))
		_farm.new_day(DAYS)
		quick.append(_farm.phase_of(Vector2i(0, 0), 3))
	assert_array(quick).is_equal([Farm.SPROUT, Farm.GROWING, Farm.RIPE])


func test_an_unwatered_crop_doesnt_grow_and_withers_after_two_dry_mornings_in_a_row() -> void:
	_farm.plant(A, "radish")
	_farm.water(A)
	_farm.new_day(DAYS)
	assert_int(_farm.stage_of(A)).is_equal(1)
	_farm.new_day(DAYS)
	assert_int(_farm.stage_of(A)).override_failure_message("a dry morning: no growth").is_equal(1)
	assert_int(_farm.dry_of(A)).is_equal(1)
	assert_bool(_farm.is_withered(A)).override_failure_message("one dry morning is forgiven").is_false()
	_farm.new_day(DAYS)
	assert_bool(_farm.is_withered(A)).override_failure_message("two in a row are not").is_true()
	assert_that(_farm.phase_of(A, 3)).is_equal(Farm.WITHERED)
	assert_bool(_farm.is_ripe(A, 3)).is_false()
	# Withered, it is dead: water and mornings change nothing.
	_farm.water(A)
	_farm.new_day(DAYS)
	_farm.new_day(DAYS)
	assert_int(_farm.stage_of(A)).is_equal(1)
	assert_bool(_farm.is_withered(A)).is_true()
	# A seed never watered withers the same way.
	_farm.plant(B, "leek")
	_farm.new_day(DAYS)
	assert_bool(_farm.is_withered(B)).is_false()
	_farm.new_day(DAYS)
	assert_bool(_farm.is_withered(B)).is_true()


func test_watering_starts_the_dry_count_again() -> void:
	_farm.plant(A, "leek")
	for round: int in 3:
		_farm.new_day(DAYS)
		assert_int(_farm.dry_of(A)).override_failure_message("a dry morning").is_equal(1)
		_farm.water(A)
		_farm.new_day(DAYS)
		assert_int(_farm.dry_of(A)).override_failure_message("watered: the count starts again").is_equal(0)
		assert_bool(_farm.is_withered(A)).is_false()
	assert_int(_farm.stage_of(A)).override_failure_message("three watered mornings in six").is_equal(3)
	# How many dry mornings wither a crop is the rules'.
	var hardy: Farm = Farm.new({"plot": {"columns": 2, "rows": 1}, "wither_after": 4})
	hardy.till(Vector2i(0, 0))
	hardy.plant(Vector2i(0, 0), "leek")
	for morning: int in 3:
		hardy.new_day(DAYS)
	assert_bool(hardy.is_withered(Vector2i(0, 0))).is_false()
	hardy.new_day(DAYS)
	assert_bool(hardy.is_withered(Vector2i(0, 0))).is_true()


func test_a_ripe_crop_waits_to_be_picked() -> void:
	_farm.plant(A, "radish")
	for morning: int in 3:
		_farm.water(A)
		_farm.new_day(DAYS)
	for morning: int in 10:
		_farm.new_day(DAYS)
	assert_bool(_farm.is_ripe(A, 3)).override_failure_message("ten dry mornings later it is still ripe").is_true()
	assert_bool(_farm.is_withered(A)).is_false()
	assert_int(_farm.stage_of(A)).override_failure_message("and no riper").is_equal(3)
	assert_int(_farm.dry_of(A)).is_equal(0)
	_farm.water(A)
	_farm.new_day(DAYS)
	assert_int(_farm.stage_of(A)).is_equal(3)


func test_a_ripe_crop_is_harvested_and_leaves_tilled_soil() -> void:
	_farm.plant(A, "radish")
	assert_str(_farm.harvest(A, 3)).override_failure_message("nothing to pick yet").is_equal("")
	for morning: int in 3:
		_farm.water(A)
		_farm.new_day(DAYS)
	_farm.water(A)
	assert_str(_farm.harvest(A, 3)).is_equal("radish")
	assert_bool(_farm.has_crop(A)).is_false()
	assert_that(_farm.state_of(A)).override_failure_message("the soil stays as it was, wet or dry").is_equal(Farm.WATERED)
	assert_str(_farm.harvest(A, 3)).override_failure_message("only once").is_equal("")
	assert_bool(_farm.plant(A, "leek")).override_failure_message("and can be planted again").is_true()
	assert_int(_farm.stage_of(A)).override_failure_message("from the start").is_equal(0)
	assert_str(_farm.harvest(B, 3)).override_failure_message("an empty cell").is_equal("")
	assert_str(_farm.harvest(Vector2i(9, 9), 3)).is_equal("")


func test_a_withered_crop_is_cleared_away_and_nothing_else_is() -> void:
	_farm.plant(A, "radish")
	assert_bool(_farm.clear_withered(A)).override_failure_message("a living crop stays").is_false()
	_farm.new_day(DAYS)
	_farm.new_day(DAYS)
	assert_str(_farm.harvest(A, 3)).override_failure_message("a withered crop gives nothing").is_equal("")
	assert_bool(_farm.clear_withered(A)).is_true()
	assert_bool(_farm.has_crop(A)).is_false()
	assert_bool(_farm.is_tilled(A)).is_true()
	assert_bool(_farm.clear_withered(A)).is_false()
	assert_bool(_farm.clear_withered(B)).override_failure_message("empty soil").is_false()
	assert_bool(_farm.plant(A, "radish")).is_true()
	assert_int(_farm.dry_of(A)).override_failure_message("the new seed starts afresh").is_equal(0)


func test_each_crop_grows_at_its_own_pace() -> void:
	_farm.plant(A, "radish")
	_farm.plant(B, "leek")
	for morning: int in 3:
		_farm.water(A)
		_farm.water(B)
		_farm.new_day(DAYS)
	assert_bool(_farm.is_ripe(A, DAYS["radish"])).is_true()
	assert_bool(_farm.is_ripe(B, DAYS["leek"])).override_failure_message("the leek needs a fourth morning").is_false()
	_farm.water(B)
	_farm.new_day(DAYS)
	assert_bool(_farm.is_ripe(B, DAYS["leek"])).is_true()
	# A crop the list doesn't name is taken to need one morning.
	_farm.till(Vector2i(0, 0))
	_farm.plant(Vector2i(0, 0), "weed")
	_farm.water(Vector2i(0, 0))
	_farm.new_day(DAYS)
	_farm.new_day(DAYS)
	_farm.new_day(DAYS)
	assert_int(_farm.stage_of(Vector2i(0, 0))).is_equal(1)
	assert_bool(_farm.is_withered(Vector2i(0, 0))).override_failure_message("ripe after its one morning, it waits").is_false()


func test_crops_are_saved_with_the_soil() -> void:
	_farm.plant(A, "radish")
	_farm.water(A)
	_farm.new_day(DAYS)
	_farm.plant(B, "leek")
	_farm.new_day(DAYS)
	_farm.new_day(DAYS)
	_farm.till(Vector2i(0, 0))
	_farm.water(B)
	var saved: Dictionary = _farm.to_dict()
	assert_dict(saved).is_equal({"cells": {
		"1,1": {"watered": false, "crop": "radish", "stage": 1, "dry": 2, "withered": true},
		"2,1": {"watered": true, "crop": "leek", "stage": 0, "dry": 2, "withered": true},
		"0,0": {"watered": false},
	}})
	var other: Farm = Farm.new()
	other.load_saved(JSON.parse_string(JSON.stringify(saved)))
	assert_dict(other.to_dict()).override_failure_message("through JSON and back").is_equal(saved)
	assert_bool(other.is_withered(A)).is_true()
	assert_int(other.stage_of(A)).is_equal(1)
	# A crop the game doesn't know is left out, and its soil kept; junk numbers are mended.
	other.load_saved({"cells": {"1,1": {"watered": true, "crop": "moonflower", "stage": 2}, "2,1": {"crop": "leek", "stage": -3, "dry": -1}, "3,1": {"crop": 7}}}, ["radish", "leek"])
	assert_dict(other.to_dict()).is_equal({"cells": {
		"1,1": {"watered": true},
		"2,1": {"watered": false, "crop": "leek", "stage": 0, "dry": 0, "withered": false},
		"3,1": {"watered": false},
	}})
	# A save from step 3a (soil only) loads as it is.
	other.load_saved({"cells": {"0,0": {"watered": false}, "4,2": {"watered": true}}}, ["radish"])
	assert_dict(other.to_dict()).is_equal({"cells": {"0,0": {"watered": false}, "4,2": {"watered": true}}})
	assert_int(other.crop_count()).is_equal(0)
