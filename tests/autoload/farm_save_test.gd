extends GdUnitTestSuite
## The farm in GameState and in saves (P3a): the plot is kept and saved (save version 3); a
## version 2 save loads with an untouched plot and everything else as it was; a version 1
## save still loads, through both steps.

const TEST_SLOT: int = 984
const OLD_SAVES: String = "res://tests/fixtures/saves"

var _changes: int = 0


func before_test() -> void:
	_changes = 0
	GameState.clear()
	EventBus.farm_changed.connect(_on_farm_changed)


func after_test() -> void:
	EventBus.farm_changed.disconnect(_on_farm_changed)
	GameState.clear()
	SaveSystem.current_slot = SaveSystem.GAME_SLOT
	if SaveSystem.has_slot(TEST_SLOT):
		DirAccess.remove_absolute(SaveSystem.slot_path(TEST_SLOT))


func test_a_new_game_has_an_untouched_plot() -> void:
	GameState.new_game()
	assert_that(GameState.farm().size).is_equal(Vector2i(6, 3))
	assert_int(GameState.farm().count_of(Farm.BARE)).is_equal(18)
	assert_int(GameState.farm().wither_after).is_equal(int(DataRegistry.get_rules(DataRegistry.RULES_FARM)["wither_after"]))
	assert_dict(GameState.to_dict()["farm"]).is_equal({"cells": {}})
	assert_int(int(GameState.to_dict()["version"])).is_equal(3)
	assert_int(GameState.SAVE_VERSION).is_equal(3)


func test_tilling_and_watering_say_so_and_only_when_they_did() -> void:
	GameState.new_game()
	assert_bool(GameState.till_soil(Vector2i(1, 1))).is_true()
	assert_int(_changes).is_equal(1)
	assert_bool(GameState.till_soil(Vector2i(1, 1))).override_failure_message("tilled already").is_false()
	assert_bool(GameState.till_soil(Vector2i(7, 7))).override_failure_message("off the plot").is_false()
	assert_bool(GameState.water_soil(Vector2i(2, 2))).override_failure_message("bare soil").is_false()
	assert_int(_changes).is_equal(1)
	assert_bool(GameState.water_soil(Vector2i(1, 1))).is_true()
	assert_int(_changes).is_equal(2)
	assert_bool(GameState.farm().is_watered(Vector2i(1, 1))).is_true()
	# The morning dries it, and whoever draws the plot is told.
	GameState.start_next_day()
	assert_int(_changes).is_equal(3)
	assert_that(GameState.farm().state_of(Vector2i(1, 1))).is_equal(Farm.TILLED)
	# Sleeping and collapsing are mornings too.
	GameState.water_soil(Vector2i(1, 1))
	GameState.sleep()
	assert_bool(GameState.farm().is_watered(Vector2i(1, 1))).override_failure_message("after a night's sleep").is_false()
	GameState.water_soil(Vector2i(1, 1))
	GameState.collapse()
	assert_bool(GameState.farm().is_watered(Vector2i(1, 1))).override_failure_message("after collapsing").is_false()
	assert_bool(GameState.farm().is_tilled(Vector2i(1, 1))).is_true()
	# A new game starts the plot afresh.
	GameState.new_game()
	assert_int(GameState.farm().count_of(Farm.BARE)).is_equal(18)


func test_the_farm_survives_a_save() -> void:
	GameState.new_game()
	GameState.add_item(&"watering_can")
	GameState.add_item(&"water", 6)
	GameState.till_soil(Vector2i(0, 0))
	GameState.till_soil(Vector2i(4, 2))
	GameState.water_soil(Vector2i(4, 2))
	GameState.update_player(&"village", Vector2i(14, 19))
	assert_int(SaveSystem.save_to_slot(TEST_SLOT)).is_equal(OK)
	var on_disk: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SaveSystem.slot_path(TEST_SLOT)))
	assert_int(int(on_disk["version"])).is_equal(3)
	assert_dict(on_disk["farm"]).is_equal({"cells": {"0,0": {"watered": false}, "4,2": {"watered": true}}})
	GameState.clear()
	assert_int(GameState.farm().count_of(Farm.BARE)).override_failure_message("cleared").is_equal(18)
	assert_int(SaveSystem.load_from_slot(TEST_SLOT)).is_equal(OK)
	assert_that(GameState.farm().state_of(Vector2i(0, 0))).is_equal(Farm.TILLED)
	assert_that(GameState.farm().state_of(Vector2i(4, 2))).is_equal(Farm.WATERED)
	assert_int(GameState.farm().count_of(Farm.BARE)).is_equal(16)
	assert_int(GameState.item_count(&"water")).override_failure_message("the can's water is kept with the pack").is_equal(6)
	assert_int(_changes).override_failure_message("loading says nothing: the world is reloaded").is_equal(3)


func test_a_version_2_save_loads_with_an_untouched_plot_and_all_else_as_it_was() -> void:
	# A save written by version 2 of the format (tools: the step before the farm).
	var old: Dictionary = _old_save("v2_third_day.json")
	assert_int(int(old["version"])).is_equal(2)
	assert_bool(old.has("farm")).override_failure_message("version 2 knew no farm").is_false()
	var migrated: Dictionary = SaveSystem.migrate(old, 2)
	assert_int(int(migrated["version"])).is_equal(3)
	assert_dict(migrated["farm"]).override_failure_message("the step from 2 to 3 adds an untouched plot").is_equal({"cells": {}})
	assert_float(float(migrated["energy"])).override_failure_message("and leaves the rest alone").is_equal(float(old["energy"]))
	assert_int(_load_old("v2_third_day.json")).is_equal(OK)
	assert_int(GameState.farm().count_of(Farm.BARE)).is_equal(18)
	assert_int(GameState.day).is_equal(3)
	assert_float(GameState.minute).is_equal(float(old["minute"]))
	assert_float(GameState.energy).is_equal(float(old["energy"]))
	assert_int(GameState.health).is_equal(int(old["health"]))
	assert_int(GameState.hearts_max).is_equal(int(old["hearts_max"]))
	assert_float(GameState.play_time).is_equal_approx(float(old["play_time"]), 0.01)
	assert_that(GameState.equipped).is_equal(&"bow")
	assert_bool(GameState.get_flag(&"met_elder_bram") == true).is_true()
	assert_int(GameState.inventory.size()).is_equal((old["inventory"] as Array).size())
	for stack: Dictionary in old["inventory"]:
		assert_int(GameState.item_count(StringName(str(stack["id"])))).override_failure_message(str(stack["id"])).is_equal(int(stack["count"]))
	assert_dict(GameState.player).is_equal({"area": "village", "cell": [9, 19]})
	assert_int(GameState.item_count(&"hoe") + GameState.item_count(&"watering_can")).override_failure_message("the tools still lie at home for him").is_equal(0)
	assert_bool(GameState.get_flag(&"took_hoe") == true).is_false()
	# Saved again, it is a version 3 save.
	assert_int(SaveSystem.save_to_slot(TEST_SLOT)).is_equal(OK)
	var again: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SaveSystem.slot_path(TEST_SLOT)))
	assert_int(int(again["version"])).is_equal(3)
	assert_dict(again["farm"]).is_equal({"cells": {}})


func test_a_version_1_save_still_loads() -> void:
	var old: Dictionary = _old_save("v1_playtest.json")
	assert_int(int(old["version"])).is_equal(1)
	assert_int(_load_old("v1_playtest.json")).is_equal(OK)
	assert_int(GameState.farm().count_of(Farm.BARE)).is_equal(18)
	assert_int(GameState.day).override_failure_message("through the first step too").is_equal(1)
	assert_float(GameState.energy).is_equal(GameState.max_energy())
	assert_int(GameState.hearts_max).is_equal(int(old["hearts_max"]))
	assert_int(GameState.flags.size()).is_equal((old["flags"] as Dictionary).size())
	assert_int(_load_old("v1_finished.json")).is_equal(OK)
	assert_bool(GameState.get_flag(EndingSummary.FINISHED_FLAG) == true).override_failure_message("a finished game is still finished").is_true()
	# The migration by itself: each step adds what its version brought.
	var migrated: Dictionary = SaveSystem.migrate(old, 1)
	assert_int(int(migrated["version"])).is_equal(3)
	assert_dict(migrated["farm"]).is_equal({"cells": {}})
	assert_bool(migrated.has("day") and migrated.has("energy")).is_true()
	assert_bool(old.has("farm")).override_failure_message("the old data is left alone").is_false()


func test_a_save_cant_put_soil_where_there_is_none() -> void:
	GameState.new_game()
	var data: Dictionary = GameState.to_dict()
	data["farm"] = {"cells": {"3,1": {"watered": true}, "40,40": {"watered": true}, "x": 4}}
	_write(TEST_SLOT, data)
	GameState.clear()
	assert_int(SaveSystem.load_from_slot(TEST_SLOT)).is_equal(OK)
	assert_dict(GameState.farm().to_dict()).is_equal({"cells": {"3,1": {"watered": true}}})
	data["farm"] = "none"
	_write(TEST_SLOT, data)
	assert_int(SaveSystem.load_from_slot(TEST_SLOT)).override_failure_message("a farm that is no farm is an untouched plot").is_equal(OK)
	assert_int(GameState.farm().count_of(Farm.BARE)).is_equal(18)


func _on_farm_changed() -> void:
	_changes += 1


func _old_save(file: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(OLD_SAVES.path_join(file)))


## Puts an old save in the test slot, as it would lie on disk, and loads it.
func _load_old(file: String) -> Error:
	_write(TEST_SLOT, _old_save(file))
	return SaveSystem.load_from_slot(TEST_SLOT)


func _write(slot: int, data: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(SaveSystem.SAVE_DIR)
	var file: FileAccess = FileAccess.open(SaveSystem.slot_path(slot), FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
