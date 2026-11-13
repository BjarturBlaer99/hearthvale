extends GdUnitTestSuite
## Crops in GameState and in saves (P3b): planting, the morning's growth and the harvest go
## through GameState; the farm's crops are saved in the same version 3, and a save from step
## 3a (soil with nothing in it) loads as it is.

const TEST_SLOT: int = 982

var _changes: int = 0


func before_test() -> void:
	_changes = 0
	GameState.clear()
	GameState.new_game()
	EventBus.farm_changed.connect(_on_farm_changed)


func after_test() -> void:
	EventBus.farm_changed.disconnect(_on_farm_changed)
	GameState.clear()
	SaveSystem.current_slot = SaveSystem.GAME_SLOT
	if SaveSystem.has_slot(TEST_SLOT):
		DirAccess.remove_absolute(SaveSystem.slot_path(TEST_SLOT))


func test_planting_goes_through_the_game_and_only_real_crops_are_planted() -> void:
	GameState.till_soil(Vector2i(0, 0))
	_changes = 0
	assert_bool(GameState.plant_crop(Vector2i(0, 0), &"moonflower")).override_failure_message("no such crop").is_false()
	assert_bool(GameState.plant_crop(Vector2i(1, 0), &"turnip")).override_failure_message("bare soil").is_false()
	assert_int(_changes).is_equal(0)
	assert_bool(GameState.plant_crop(Vector2i(0, 0), &"turnip")).is_true()
	assert_int(_changes).is_equal(1)
	assert_bool(GameState.plant_crop(Vector2i(0, 0), &"carrot")).override_failure_message("taken").is_false()
	assert_that(GameState.crop_phase(Vector2i(0, 0))).is_equal(Farm.SEEDED)
	assert_that(GameState.crop_phase(Vector2i(1, 0))).override_failure_message("nothing grows there").is_equal(&"")
	assert_bool(GameState.is_crop_ripe(Vector2i(0, 0))).is_false()
	assert_bool(GameState.is_crop_ripe(Vector2i(1, 0))).is_false()


func test_mornings_grow_what_was_watered_at_each_crops_own_pace() -> void:
	for x: int in 2:
		GameState.till_soil(Vector2i(x, 0))
	GameState.plant_crop(Vector2i(0, 0), &"turnip")
	GameState.plant_crop(Vector2i(1, 0), &"pumpkin")
	for morning: int in 3:
		GameState.water_soil(Vector2i(0, 0))
		GameState.water_soil(Vector2i(1, 0))
		# Sleeping, staying up and collapsing are all mornings.
		match morning:
			0:
				GameState.sleep()
			1:
				GameState.start_next_day()
			2:
				GameState.collapse()
	assert_bool(GameState.is_crop_ripe(Vector2i(0, 0))).override_failure_message("a turnip takes three").is_true()
	assert_that(GameState.crop_phase(Vector2i(1, 0))).override_failure_message("a pumpkin takes eight").is_equal(Farm.SPROUT)
	assert_int(GameState.farm().stage_of(Vector2i(1, 0))).is_equal(3)
	assert_int(GameState.day).is_equal(4)


func test_the_harvest_goes_into_the_pack() -> void:
	GameState.farm().load_saved({"cells": {"0,0": {"crop": "turnip", "stage": 3}, "1,0": {"crop": "turnip", "stage": 2}, "2,0": {"crop": "wheat", "stage": 1, "dry": 2, "withered": true}}})
	assert_dict(GameState.harvest(Vector2i(1, 0))).override_failure_message("not ripe").is_empty()
	assert_dict(GameState.harvest(Vector2i(2, 0))).override_failure_message("withered").is_empty()
	assert_dict(GameState.harvest(Vector2i(4, 2))).override_failure_message("bare soil").is_empty()
	assert_int(_changes).is_equal(0)
	assert_dict(GameState.harvest(Vector2i(0, 0))).is_equal({"item": "turnip", "count": 1})
	assert_int(GameState.item_count(&"turnip")).is_equal(1)
	assert_int(_changes).is_equal(1)
	assert_bool(GameState.farm().has_crop(Vector2i(0, 0))).is_false()
	assert_dict(GameState.harvest(Vector2i(0, 0))).override_failure_message("only once").is_empty()
	assert_bool(GameState.clear_crop(Vector2i(1, 0))).override_failure_message("a living crop isn't cleared").is_false()
	assert_bool(GameState.clear_crop(Vector2i(2, 0))).is_true()
	assert_int(_changes).is_equal(2)
	assert_int(GameState.item_count(&"wheat")).is_equal(0)
	# With no room for it, the crop stays where it is.
	GameState.farm().load_saved({"cells": {"0,0": {"crop": "potato", "stage": 5}}})
	GameState.add_item(&"potato", Inventory.capacity(DataRegistry.get_item(&"potato")))
	assert_dict(GameState.harvest(Vector2i(0, 0))).is_empty()
	assert_bool(GameState.is_crop_ripe(Vector2i(0, 0))).is_true()


func test_the_farms_crops_survive_a_save() -> void:
	for x: int in 3:
		GameState.till_soil(Vector2i(x, 1))
	GameState.plant_crop(Vector2i(0, 1), &"carrot")
	GameState.plant_crop(Vector2i(1, 1), &"potato")
	GameState.water_soil(Vector2i(0, 1))
	GameState.start_next_day()
	GameState.start_next_day()
	GameState.water_soil(Vector2i(1, 1))
	GameState.add_item(&"carrot_seeds", 4)
	GameState.update_player(&"village", Vector2i(14, 19))
	assert_int(SaveSystem.save_to_slot(TEST_SLOT)).is_equal(OK)
	var on_disk: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SaveSystem.slot_path(TEST_SLOT)))
	assert_int(int(on_disk["version"])).override_failure_message("still version 3").is_equal(3)
	assert_dict(on_disk["farm"]).is_equal({"cells": {
		"0,1": {"watered": false, "crop": "carrot", "stage": 1.0, "dry": 1.0, "withered": false},
		"1,1": {"watered": true, "crop": "potato", "stage": 0.0, "dry": 2.0, "withered": true},
		"2,1": {"watered": false},
	}})
	GameState.clear()
	assert_int(SaveSystem.load_from_slot(TEST_SLOT)).is_equal(OK)
	assert_str(GameState.farm().crop_at(Vector2i(0, 1))).is_equal("carrot")
	assert_int(GameState.farm().stage_of(Vector2i(0, 1))).is_equal(1)
	assert_int(GameState.farm().dry_of(Vector2i(0, 1))).is_equal(1)
	assert_that(GameState.crop_phase(Vector2i(0, 1))).is_equal(Farm.SPROUT)
	assert_that(GameState.crop_phase(Vector2i(1, 1))).is_equal(Farm.WITHERED)
	assert_bool(GameState.farm().is_watered(Vector2i(1, 1))).is_true()
	assert_bool(GameState.farm().has_crop(Vector2i(2, 1))).is_false()
	assert_int(GameState.item_count(&"carrot_seeds")).is_equal(4)
	# Growth carries on from where it was saved.
	GameState.water_soil(Vector2i(0, 1))
	GameState.start_next_day()
	assert_int(GameState.farm().stage_of(Vector2i(0, 1))).is_equal(2)


func test_a_save_from_step_3a_loads_as_it_is_and_an_unknown_crop_is_left_out() -> void:
	var data: Dictionary = GameState.to_dict()
	data["farm"] = {"cells": {"0,0": {"watered": false}, "4,2": {"watered": true}}}
	_write(TEST_SLOT, data)
	GameState.clear()
	assert_int(SaveSystem.load_from_slot(TEST_SLOT)).is_equal(OK)
	assert_dict(GameState.farm().to_dict()).override_failure_message("soil only, as step 3a saved it").is_equal({"cells": {"0,0": {"watered": false}, "4,2": {"watered": true}}})
	assert_int(GameState.farm().crop_count()).is_equal(0)
	data["farm"] = {"cells": {"0,0": {"watered": true, "crop": "moonflower", "stage": 2}, "1,0": {"watered": false, "crop": "wheat", "stage": 9}}}
	_write(TEST_SLOT, data)
	assert_int(SaveSystem.load_from_slot(TEST_SLOT)).is_equal(OK)
	assert_bool(GameState.farm().has_crop(Vector2i(0, 0))).override_failure_message("a crop the game doesn't know").is_false()
	assert_bool(GameState.farm().is_watered(Vector2i(0, 0))).override_failure_message("its soil is kept").is_true()
	assert_bool(GameState.is_crop_ripe(Vector2i(1, 0))).override_failure_message("a stage past ripe is ripe").is_true()
	# The version 2 save still loads, with nothing growing.
	_write(TEST_SLOT, JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/saves/v2_third_day.json")))
	assert_int(SaveSystem.load_from_slot(TEST_SLOT)).is_equal(OK)
	assert_int(GameState.farm().crop_count()).is_equal(0)
	assert_int(GameState.farm().count_of(Farm.BARE)).is_equal(18)


func _on_farm_changed() -> void:
	_changes += 1


func _write(slot: int, data: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(SaveSystem.SAVE_DIR)
	var file: FileAccess = FileAccess.open(SaveSystem.slot_path(slot), FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
