extends GdUnitTestSuite
## Save version 6 (the Homestead, phase 1): the homestead goes through a save and back; a
## version 5 save (written by the game as it stood before the Homestead: the hero inside his
## cottage, the furnace burning, the chest filled, soil and crops at every stage, a sprinkler)
## loads with everything it had, and nothing in it needs moving; versions 1 to 4 still load,
## through every step. What the loaded save looks like in the world is
## tests/world/home_move_test.gd's.

const TEST_SLOT: int = 954
const OLD_SAVES: String = "res://tests/fixtures/saves"
const V5: String = "v5_in_the_old_cottage.json"
## Written at the end of the Homestead's phase 2 (57e7d3a): a yard on the farm, no buildings.
const V6_PHASE_2: String = "v6_a_yard_on_the_farm.json"
## The old plot's cells, in the plot's own cells: the field's clear corner.
const OLD_PLOT: Rect2i = Rect2i(0, 0, 6, 3)


func before_test() -> void:
	GameState.clear()


func after_test() -> void:
	GameState.clear()
	SaveSystem.current_slot = SaveSystem.GAME_SLOT
	SaveSystem.erase_slot(TEST_SLOT)


func test_a_new_game_has_a_homestead_with_nothing_cleared() -> void:
	assert_int(GameState.SAVE_VERSION).is_equal(6)
	GameState.new_game()
	assert_int(GameState.homestead().cleared_count()).is_equal(0)
	assert_dict(GameState.to_dict()["homestead"]).is_equal({"cleared": []})
	assert_int(int(GameState.to_dict()["version"])).is_equal(6)
	# The field is four times the old plot, and a new game starts in the village's square.
	assert_that(GameState.farm().size).is_equal(Vector2i(12, 6))
	assert_that(WorldPaths.START_AREA).is_equal(&"village")
	assert_that(WorldPaths.HOME_AREA).is_equal(&"home")


func test_the_homestead_goes_through_a_save_and_back() -> void:
	GameState.new_game()
	for cell: Vector2i in [Vector2i(28, 17), Vector2i(29, 17), Vector2i(23, 20), Vector2i(5, 9)]:
		assert_bool(GameState.homestead().clear(cell)).is_true()
	GameState.till_soil(Vector2i(6, 0))
	GameState.till_soil(Vector2i(11, 5))
	GameState.water_soil(Vector2i(11, 5))
	GameState.update_player(&"homestead", Vector2i(28, 16))
	assert_int(SaveSystem.save_to_slot(TEST_SLOT)).is_equal(OK)
	var on_disk: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SaveSystem.slot_path(TEST_SLOT)))
	assert_int(int(on_disk["version"])).is_equal(6)
	assert_dict(on_disk["homestead"]).is_equal({"cleared": ["5,9", "28,17", "29,17", "23,20"]})
	assert_dict(on_disk["farm"]).override_failure_message("soil beyond the old plot is kept: the field is the plot").is_equal({"cells": {"6,0": {"watered": false}, "11,5": {"watered": true}}})
	var before: String = JSON.stringify(GameState.to_dict(), "", true)
	GameState.clear()
	assert_int(GameState.homestead().cleared_count()).override_failure_message("cleared").is_equal(0)
	assert_int(SaveSystem.load_from_slot(TEST_SLOT)).is_equal(OK)
	assert_str(JSON.stringify(GameState.to_dict(), "", true)).is_equal(before)
	for cell: Vector2i in [Vector2i(28, 17), Vector2i(29, 17), Vector2i(23, 20), Vector2i(5, 9)]:
		assert_bool(GameState.homestead().is_cleared(cell)).override_failure_message("%s is still cleared" % cell).is_true()
	assert_bool(GameState.homestead().is_cleared(Vector2i(30, 17))).is_false()
	assert_dict(GameState.player).is_equal({"area": "homestead", "cell": [28, 16]})
	assert_dict(SaveSystem.summary(TEST_SLOT)).is_equal({"area": "homestead", "play_time": 0.0, "hearts_max": 3, "finished": false})
	# No morning brings anything back, and a new game starts overgrown again.
	GameState.start_next_day()
	GameState.sleep()
	GameState.collapse()
	assert_int(GameState.homestead().cleared_count()).override_failure_message("three mornings on").is_equal(4)
	GameState.new_game()
	assert_int(GameState.homestead().cleared_count()).is_equal(0)
	# A save with no homestead in it at all still loads: an overgrown one.
	var bare: Dictionary = JSON.parse_string(before)
	bare.erase("homestead")
	GameState.from_dict(bare)
	assert_dict(GameState.to_dict()["homestead"]).is_equal({"cleared": []})


func test_a_version_5_save_loads_with_all_it_had_and_nothing_moved() -> void:
	# Written by the game as it stood before the Homestead: the fifth day, inside the cottage.
	var old: Dictionary = _old_save(V5)
	assert_int(int(old["version"])).is_equal(5)
	assert_bool(old.has("homestead")).override_failure_message("version 5 knew no homestead").is_false()
	assert_dict(old["player"]).override_failure_message("it was saved inside the old cottage").is_equal({"area": "home", "cell": [4.0, 5.0]})

	# The step by itself: it adds the homestead, overgrown, and touches nothing else.
	var migrated: Dictionary = SaveSystem.migrate(old, 5)
	assert_int(int(migrated["version"])).is_equal(6)
	assert_dict(migrated["homestead"]).is_equal({"cleared": []})
	for part: String in old:
		if part != "version":
			assert_that(migrated[part]).override_failure_message("%s is left alone" % part).is_equal(old[part])
	assert_int(migrated.size()).override_failure_message("one new section, and no other").is_equal(old.size() + 1)
	assert_bool(old.has("homestead")).override_failure_message("the old data is left alone").is_false()

	# Loaded, as it would lie on disk.
	assert_int(_load_old(V5)).is_equal(OK)
	# The hero is where he stood: the same room, which is now inside the farmhouse.
	assert_dict(GameState.player).is_equal({"area": "home", "cell": [4, 5]})
	assert_int(GameState.day).is_equal(5)
	assert_float(GameState.minute).is_equal_approx(860.39, 0.01)
	assert_float(GameState.energy).is_equal(62.0)
	assert_int(GameState.health).is_equal(6)
	assert_that(GameState.equipped).is_equal(&"hoe")
	# The furnishings made, by the same flags.
	assert_bool(GameState.is_furnished(&"furnace") and GameState.is_furnished(&"chest")).is_true()
	assert_bool(GameState.is_furnished(&"lamp") or GameState.is_furnished(&"rug")).override_failure_message("and none he hadn't made").is_false()
	# The chest's stacks, two of them stone.
	assert_array(GameState.store().to_list()).is_equal([
		{"id": "stone", "count": 50}, {"id": "stone", "count": 12}, {"id": "iron_ore", "count": 4},
		{"id": "turnip", "count": 1}, {"id": "wood", "count": 4},
	])
	# The furnace's load: lit that day, burning, and ready the next morning.
	assert_dict(GameState.furnace().to_dict()).is_equal({"item": "copper_bar", "count": 3, "day": 5})
	assert_bool(GameState.furnace().is_burning(GameState.day)).is_true()
	# Tilled soil, crops and the sprinkler: the same cells of the plot, which are the field's
	# clear corner now.
	assert_dict(JSON.parse_string(JSON.stringify(GameState.farm().to_dict()))).override_failure_message("the farm, as it would be written again").is_equal(old["farm"])
	assert_int((old["farm"]["cells"] as Dictionary).size()).is_equal(12)
	for cell_key: String in old["farm"]["cells"]:
		assert_bool(OLD_PLOT.has_point(Farm.cell_of(cell_key))).override_failure_message("%s is in the clear corner" % cell_key).is_true()
	var phases: Dictionary = {}
	for cell_key: String in old["farm"]["cells"]:
		phases[cell_key] = GameState.crop_phase(Farm.cell_of(cell_key))
	assert_dict(phases).override_failure_message("crops at every stage, as they were").is_equal({
		"0,0": Farm.RIPE, "1,0": Farm.SEEDED, "2,0": Farm.RIPE, "3,0": Farm.GROWING, "4,0": Farm.SPROUT, "5,0": Farm.WITHERED,
		"0,1": Farm.GROWING, "1,1": Farm.SPROUT, "2,1": &"", "3,1": &"", "4,1": &"", "5,1": &"",
	})
	assert_int(GameState.farm().dry_of(Vector2i(4, 0))).override_failure_message("a morning dry").is_equal(1)
	assert_int(GameState.farm().count_of(Farm.WATERED)).is_equal(6)
	assert_bool(GameState.farm().has_sprinkler(Vector2i(4, 1))).is_true()
	assert_int(GameState.farm().sprinkler_count()).is_equal(1)
	# What he carries, what he has found, and every flag: the tools taken and the seeds not,
	# what lies at his feet at home and in the village, the wood cut today and yesterday.
	assert_int(GameState.inventory.size()).is_equal((old["inventory"] as Array).size())
	for stack: Dictionary in old["inventory"]:
		assert_int(GameState.item_count(StringName(str(stack["id"])))).override_failure_message(str(stack["id"])).is_equal(int(stack["count"]))
	assert_int(GameState.flags.size()).is_equal((old["flags"] as Dictionary).size())
	for flag: String in old["flags"]:
		assert_that(GameState.get_flag(StringName(flag), null)).override_failure_message(flag).is_equal(old["flags"][flag])
	assert_bool(GameState.get_flag(&"took_hoe") == true and GameState.get_flag(&"took_watering_can") == true).is_true()
	assert_bool(GameState.get_flag(&"took_first_seeds") == true).override_failure_message("the first seeds still lie on the floor").is_false()
	assert_array(LeftItems.lying_in(GameState.flags, &"home")).is_equal([{"cell": Vector2i(6, 5), "item": &"arrow", "count": 5, "flag": &"left/home/6,5/arrow"}])
	assert_array(LeftItems.lying_in(GameState.flags, &"village")).is_equal([{"cell": Vector2i(14, 17), "item": &"arrow", "count": 10, "flag": &"left/village/14,17/arrow"}])
	assert_int(int(GameState.get_flag(&"cut/old_wood/7,12", 0))).is_equal(5)
	assert_int(int(GameState.get_flag(&"cut/north_fields/5,9", 0))).is_equal(4)
	for item: String in old["found"]:
		assert_bool(GameState.has_found(StringName(item))).override_failure_message("found: %s" % item).is_true()
	# The story, friends, skills and quests: untouched.
	assert_that(GameState.get_quest_stage(&"a_place_of_your_own")).is_equal(&"bram")
	assert_int(GameState.friend_points(&"tilda")).is_equal(2)
	assert_int(GameState.friend_points(&"elder_bram")).is_equal(1)
	assert_int(GameState.skill_points[&"farming"]).is_equal(14)
	assert_int(GameState.skill_points[&"mining"]).is_equal(12)
	assert_int(GameState.tally_of(GameState.CROPS_PICKED)).is_equal(1)
	assert_int(GameState.mine().number).is_equal(20261117)
	assert_bool(GameState.get_flag(MineRules.lift_flag(4)) == true).is_true()
	# The homestead is as a new game's.
	assert_int(GameState.homestead().cleared_count()).is_equal(0)

	# The next morning the furnace has burned down and gives its bars, the sprinkler has run,
	# and the crops have grown as they would have in the village.
	GameState.start_next_day()
	assert_bool(GameState.furnace().is_ready(GameState.day)).override_failure_message("lit the night before, it is ready").is_true()
	assert_dict(GameState.empty_furnace()).is_equal({"item": &"copper_bar", "count": 3})
	assert_int(GameState.item_count(&"copper_bar")).is_equal(4)
	assert_that(GameState.crop_phase(Vector2i(1, 0))).override_failure_message("watered yesterday, the seed has sprouted").is_equal(Farm.SPROUT)
	for cell: Vector2i in [Vector2i(4, 0), Vector2i(3, 1), Vector2i(5, 1)]:
		assert_bool(GameState.farm().is_watered(cell)).override_failure_message("the sprinkler waters %s" % cell).is_true()

	# Saved again, it is a save of today's version, and loads back the same.
	assert_int(SaveSystem.save_to_slot(TEST_SLOT)).is_equal(OK)
	var again: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SaveSystem.slot_path(TEST_SLOT)))
	assert_int(int(again["version"])).is_equal(6)
	assert_dict(again["homestead"]).is_equal({"cleared": []})
	var before: String = JSON.stringify(GameState.to_dict(), "", true)
	assert_int(SaveSystem.load_from_slot(TEST_SLOT)).is_equal(OK)
	assert_str(JSON.stringify(GameState.to_dict(), "", true)).is_equal(before)


func test_versions_1_to_4_still_load_and_come_out_with_a_homestead() -> void:
	for file: String in ["v1_playtest.json", "v1_finished.json", "v2_third_day.json", "v3_in_the_keep.json", "v4_before_the_mine.json"]:
		var old: Dictionary = _old_save(file)
		var migrated: Dictionary = SaveSystem.migrate(old, int(old["version"]))
		assert_int(int(migrated["version"])).override_failure_message(file).is_equal(6)
		assert_dict(migrated["homestead"]).override_failure_message(file).is_equal({"cleared": []})
		assert_bool(migrated.has("mine") and migrated.has("home") and migrated.has("farm") and migrated.has("flag_days")).override_failure_message("%s went through every step" % file).is_true()
		assert_bool(old.has("homestead")).override_failure_message("the old data is left alone").is_false()
		assert_int(_load_old(file)).override_failure_message(file).is_equal(OK)
		assert_int(GameState.homestead().cleared_count()).override_failure_message(file).is_equal(0)
		assert_int(GameState.hearts_max).override_failure_message(file).is_equal(int(old["hearts_max"]))
		assert_that(GameState.farm().size).is_equal(Vector2i(12, 6))
	# The version 4 save had a withered turnip in the plot's first cell: it is the field's
	# first cell now.
	assert_int(_load_old("v4_before_the_mine.json")).is_equal(OK)
	assert_str(GameState.farm().crop_at(Vector2i(0, 0))).is_equal("turnip")
	assert_bool(GameState.farm().is_withered(Vector2i(0, 0))).is_true()
	assert_dict(GameState.player).override_failure_message("saved at home: at home, in the farmhouse").is_equal({"area": "home", "cell": [5, 5]})


func test_a_save_newer_than_the_game_is_not_loaded() -> void:
	var data: Dictionary = _old_save(V5)
	data["version"] = GameState.SAVE_VERSION + 1
	_write(TEST_SLOT, data)
	GameState.new_game()
	assert_int(SaveSystem.load_from_slot(TEST_SLOT)).is_not_equal(OK)
	assert_bool(GameState.is_furnished(&"furnace")).override_failure_message("and nothing of it is taken up").is_false()


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


# --- What is set down (phase 2): still version 6, new fields read with defaults ---

func test_what_is_set_down_goes_through_a_save_and_back() -> void:
	GameState.new_game()
	for item: Array in [[&"fence", 5], [&"gate", 1], [&"stone_path", 4]]:
		GameState.add_item(item[0], item[1])
	GameState.homestead().clear(Vector2i(5, 9))
	assert_bool(GameState.set_down(&"homestead", Vector2i(32, 12), &"fence")).is_true()
	assert_bool(GameState.set_down(&"homestead", Vector2i(33, 12), &"gate")).is_true()
	assert_bool(GameState.set_down(&"homestead", Vector2i(33, 12), &"stone_path")).override_failure_message("a path under the gate").is_true()
	assert_bool(GameState.set_down(&"homestead", Vector2i(33, 12), &"fence")).override_failure_message("a second standing thing").is_false()
	assert_int(GameState.item_count(&"fence")).override_failure_message("one fence set down, one refused and kept").is_equal(4)
	assert_int(GameState.item_count(&"gate")).override_failure_message("the last gate: none left").is_equal(0)
	GameState.update_player(&"homestead", Vector2i(30, 13))
	assert_int(SaveSystem.save_to_slot(TEST_SLOT)).is_equal(OK)
	var on_disk: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SaveSystem.slot_path(TEST_SLOT)))
	assert_int(int(on_disk["version"])).override_failure_message("no new version: the new fields are read with defaults").is_equal(6)
	assert_dict(on_disk["homestead"]).is_equal({
		"cleared": ["5,9"],
		"lying": {"33,12": "stone_path"},
		"standing": {"32,12": {"item": "fence"}, "33,12": {"item": "gate"}},
	})
	var before: String = JSON.stringify(GameState.to_dict(), "", true)
	GameState.clear()
	assert_int(GameState.homestead().placed_count()).override_failure_message("cleared").is_equal(0)
	assert_int(SaveSystem.load_from_slot(TEST_SLOT)).is_equal(OK)
	assert_str(JSON.stringify(GameState.to_dict(), "", true)).is_equal(before)
	assert_that(GameState.homestead().standing_at(Vector2i(32, 12))).is_equal(&"fence")
	assert_that(GameState.homestead().standing_at(Vector2i(33, 12))).is_equal(&"gate")
	assert_that(GameState.homestead().lying_at(Vector2i(33, 12))).is_equal(&"stone_path")
	assert_bool(GameState.homestead().is_cleared(Vector2i(5, 9))).is_true()
	# Taken up after the load, each comes back to the pack; a new game has none of it.
	assert_that(GameState.take_up(&"homestead", Vector2i(33, 12), Placement.STANDING)).is_equal(&"gate")
	assert_int(GameState.item_count(&"gate")).is_equal(1)
	GameState.new_game()
	assert_int(GameState.homestead().placed_count()).is_equal(0)
	assert_dict(GameState.to_dict()["homestead"]).is_equal({"cleared": []})


func test_a_version_6_save_from_before_things_could_be_set_down_still_loads() -> void:
	# Phase 1's save: the homestead is its cleared cells and nothing else.
	GameState.new_game()
	GameState.homestead().clear(Vector2i(28, 17))
	GameState.update_player(&"homestead", Vector2i(28, 16))
	var early: Dictionary = GameState.to_dict()
	assert_dict(early["homestead"]).override_failure_message("with nothing set down, the homestead is saved as phase 1 saved it").is_equal({"cleared": ["28,17"]})
	_write(TEST_SLOT, early)
	GameState.clear()
	assert_int(SaveSystem.load_from_slot(TEST_SLOT)).is_equal(OK)
	assert_int(GameState.homestead().placed_count()).is_equal(0)
	assert_bool(GameState.homestead().is_cleared(Vector2i(28, 17))).is_true()
	assert_dict(GameState.player).is_equal({"area": "homestead", "cell": [28, 16]})
	# And a version 5 save, which knew no homestead, has nothing set down either.
	assert_int(_load_old(V5)).is_equal(OK)
	assert_int(GameState.homestead().placed_count()).is_equal(0)
	assert_array(GameState.homestead().placed(Placement.STANDING)).is_empty()
	assert_array(GameState.homestead().placed(Placement.LYING)).is_empty()


func test_a_saved_thing_the_game_does_not_know_is_left_out() -> void:
	GameState.new_game()
	var data: Dictionary = GameState.to_dict()
	data["homestead"] = {
		"cleared": [],
		"lying": {"30,12": "stone_path", "31,12": "fence", "32,12": "magic_carpet", "33,12": "stone"},
		"standing": {"30,12": {"item": "fence"}, "31,12": {"item": "stone_path"}, "32,12": {"item": "statue"}, "33,12": {"item": "wooden_sword"}},
	}
	GameState.from_dict(JSON.parse_string(JSON.stringify(data)))
	assert_array(GameState.homestead().placed(Placement.LYING)).is_equal([{"cell": Vector2i(30, 12), "item": &"stone_path", "age": 0}])
	assert_array(GameState.homestead().placed(Placement.STANDING)).is_equal([{"cell": Vector2i(30, 12), "item": &"fence", "age": 0}])


func test_a_save_from_phase_2_loads_with_its_yard_and_no_buildings() -> void:
	# Written by the game as it stood at the end of phase 2 (the Homestead's), with the hero on
	# his farm: a yard set down (three things on the meadow's tall grass, which was plain grass
	# then), the furnace burning, the chest filled.
	var old: Dictionary = _old_save(V6_PHASE_2)
	assert_int(int(old["version"])).is_equal(6)
	assert_bool((old["homestead"] as Dictionary).has("buildings")).override_failure_message("phase 2 knew no buildings").is_false()
	assert_int(_load_old(V6_PHASE_2)).is_equal(OK)
	assert_int(GameState.day).is_equal(6)
	assert_array(GameState.homestead().building_ids()).is_empty()
	assert_int(GameState.homestead().hay).is_equal(0)
	assert_int(GameState.homestead().placed_count()).is_equal(8)
	assert_that(GameState.homestead().standing_at(Vector2i(6, 3))).is_equal(&"fence")
	assert_that(GameState.homestead().lying_at(Vector2i(4, 3))).is_equal(&"dirt_path")
	assert_int(GameState.homestead().age_at(Vector2i(9, 3))).is_equal(2)
	assert_int(GameState.homestead().cleared_count()).is_equal(3)
	assert_bool(GameState.furnace().is_burning(6)).is_true()
	assert_int(GameState.store().count_of("stone")).is_equal(20)
	assert_dict(GameState.player).is_equal({"area": "homestead", "cell": [30, 13]})
	# Saved again, the homestead is as it was, and nothing of phase 3 is written that isn't there.
	var again: Dictionary = GameState.to_dict()
	assert_bool((again["homestead"] as Dictionary).has("buildings")).is_false()
	assert_bool((again["homestead"] as Dictionary).has("hay")).is_false()
	assert_dict(JSON.parse_string(JSON.stringify(again["homestead"]))).is_equal(old["homestead"])
