extends GdUnitTestSuite
## Save version 4 (P4a): the day each flag came true, the tally, and the places kept for
## skills and friendship go through a save; the first seed planted is remembered and crops
## picked are counted; a version 3 save loads past the story's gates with nothing lost, and
## versions 1 and 2 still load, through every step.

const TEST_SLOT: int = 979
const OLD_SAVES: String = "res://tests/fixtures/saves"


func before_test() -> void:
	GameState.clear()


func after_test() -> void:
	GameState.clear()
	SaveSystem.current_slot = SaveSystem.GAME_SLOT
	SaveSystem.erase_slot(TEST_SLOT)


func test_the_day_a_flag_came_true_is_kept() -> void:
	GameState.new_game()
	assert_int(GameState.SAVE_VERSION).is_equal(4)
	GameState.set_flag(&"met_bram", true)
	GameState.start_next_day()
	GameState.start_next_day()
	GameState.set_flag(&"warden_fell", true)
	GameState.set_flag(&"met_bram", true)
	assert_int(GameState.flag_days[&"met_bram"]).override_failure_message("set again, it keeps its first day").is_equal(1)
	assert_int(GameState.flag_days[&"warden_fell"]).is_equal(3)
	# Only a plain yes has a day: counts and words do not.
	GameState.set_flag(&"dungeon/keep/keys", 2)
	GameState.set_flag(&"quest/x/entered", "find")
	GameState.set_flag(&"door", false)
	assert_bool(GameState.flag_days.has(&"dungeon/keep/keys") or GameState.flag_days.has(&"quest/x/entered") or GameState.flag_days.has(&"door")).is_false()
	# Unset, its day is forgotten; set again, it is today's.
	GameState.set_flag(&"met_bram", false)
	assert_bool(GameState.flag_days.has(&"met_bram")).is_false()
	GameState.set_flag(&"met_bram", true)
	assert_int(GameState.flag_days[&"met_bram"]).is_equal(3)
	# The condition reads it from the state as it is saved.
	var check: ConditionEvaluator = ConditionEvaluator.new(GameState.to_dict())
	assert_bool(check.is_met({"type": "days_since", "flag": "warden_fell", "days": 1})).is_false()
	GameState.start_next_day()
	check = ConditionEvaluator.new(GameState.to_dict())
	assert_bool(check.is_met({"type": "days_since", "flag": "warden_fell", "days": 1})).is_true()
	GameState.clear()
	assert_bool(GameState.flag_days.is_empty()).override_failure_message("a new game keeps none").is_true()


func test_the_first_seed_planted_is_remembered() -> void:
	GameState.new_game()
	assert_bool(GameState.plant_crop(Vector2i(0, 0), &"turnip")).override_failure_message("untilled soil takes no seed").is_false()
	assert_bool(GameState.get_flag(StoryGates.FIRST_CROP) == true).is_false()
	GameState.till_soil(Vector2i(0, 0))
	assert_bool(GameState.get_flag(StoryGates.FIRST_CROP) == true).override_failure_message("tilling alone is not planting").is_false()
	GameState.start_next_day()
	assert_bool(GameState.plant_crop(Vector2i(0, 0), &"turnip")).is_true()
	assert_bool(GameState.get_flag(StoryGates.FIRST_CROP) == true).is_true()
	assert_int(GameState.flag_days[StoryGates.FIRST_CROP]).override_failure_message("on the day it was planted").is_equal(2)


func test_crops_picked_are_counted() -> void:
	GameState.new_game()
	assert_int(GameState.tally_of(GameState.CROPS_PICKED)).is_equal(0)
	for x: int in 2:
		GameState.till_soil(Vector2i(x, 0))
		GameState.plant_crop(Vector2i(x, 0), &"turnip")
	assert_dict(GameState.harvest(Vector2i(0, 0))).override_failure_message("nothing ripe yet").is_empty()
	assert_int(GameState.tally_of(GameState.CROPS_PICKED)).override_failure_message("a crop not picked is not counted").is_equal(0)
	for day: int in 3:
		for x: int in 2:
			GameState.water_soil(Vector2i(x, 0))
		GameState.start_next_day()
	assert_dict(GameState.harvest(Vector2i(0, 0))).is_not_empty()
	assert_dict(GameState.harvest(Vector2i(1, 0))).is_not_empty()
	assert_int(GameState.tally_of(GameState.CROPS_PICKED)).is_equal(2)
	GameState.add_tally(GameState.CROPS_PICKED, 0)
	GameState.add_tally(GameState.CROPS_PICKED, -3)
	assert_int(GameState.tally_of(GameState.CROPS_PICKED)).override_failure_message("a tally only grows").is_equal(2)
	assert_int(GameState.tally_of(&"never_counted")).is_equal(0)


func test_version_4_keeps_its_new_parts_through_a_save() -> void:
	GameState.new_game()
	GameState.set_flag(&"met_bram", true)
	GameState.start_next_day()
	GameState.set_flag(StoryGates.WARDEN_BEATEN, true)
	GameState.add_tally(GameState.CROPS_PICKED, 7)
	# Nothing in the game changes these two yet (P4b, P4c): their places in a save are kept.
	GameState.skill_points[&"farming"] = 12
	GameState.friends[&"pip"] = {"points": 5, "talked": 2, "gift": 1}
	GameState.update_player(&"village", Vector2i(23, 8))
	assert_int(SaveSystem.save_to_slot(TEST_SLOT)).is_equal(OK)
	var on_disk: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SaveSystem.slot_path(TEST_SLOT)))
	assert_int(int(on_disk["version"])).is_equal(4)
	assert_dict(on_disk["flag_days"]).is_equal({"met_bram": 1.0, "keep_warden_beaten": 2.0})
	assert_dict(on_disk["skills"]).is_equal({"farming": 12.0})
	assert_dict(on_disk["friends"]).is_equal({"pip": {"points": 5.0, "talked": 2.0, "gift": 1.0}})
	assert_dict(on_disk["tally"]).is_equal({"crops_picked": 7.0})
	var before: String = JSON.stringify(GameState.to_dict(), "", true)
	GameState.clear()
	assert_bool(GameState.skill_points.is_empty() and GameState.friends.is_empty() and GameState.tally.is_empty()).override_failure_message("cleared").is_true()
	assert_int(SaveSystem.load_from_slot(TEST_SLOT)).is_equal(OK)
	assert_str(JSON.stringify(GameState.to_dict(), "", true)).is_equal(before)
	assert_int(GameState.flag_days[StoryGates.WARDEN_BEATEN]).is_equal(2)
	assert_int(GameState.skill_points[&"farming"]).is_equal(12)
	assert_dict(GameState.friends[&"pip"]).is_equal({"points": 5, "talked": 2, "gift": 1})
	assert_int(GameState.tally_of(GameState.CROPS_PICKED)).is_equal(7)


func test_odd_values_in_a_save_are_made_safe() -> void:
	GameState.new_game()
	var odd: Dictionary = GameState.to_dict()
	odd["flag_days"] = "never"
	odd["skills"] = {"farming": -4}
	odd["friends"] = {"pip": "a friend", "oda": {"points": -2}}
	odd["tally"] = {"crops_picked": -1}
	GameState.from_dict(odd)
	assert_bool(GameState.flag_days.is_empty()).is_true()
	assert_int(GameState.skill_points[&"farming"]).is_equal(0)
	assert_dict(GameState.friends[&"pip"]).is_equal({"points": 0, "talked": 0, "gift": 0})
	assert_dict(GameState.friends[&"oda"]).is_equal({"points": 0, "talked": 0, "gift": 0})
	assert_int(GameState.tally_of(GameState.CROPS_PICKED)).is_equal(0)
	# A save with none of the new parts at all still loads (they are simply empty).
	for part: String in ["flag_days", "skills", "friends", "tally"]:
		odd.erase(part)
	GameState.from_dict(odd)
	assert_bool(GameState.flag_days.is_empty() and GameState.skill_points.is_empty() and GameState.friends.is_empty() and GameState.tally.is_empty()).is_true()


func test_a_version_3_save_loads_past_the_gates_with_nothing_lost() -> void:
	# A save written by version 3 of the format: the fourth day, inside the Old Keep, by a hero
	# who never spoke to Elder Bram. (Made by the game itself, the step before the gates.)
	var old: Dictionary = _old_save("v3_in_the_keep.json")
	assert_int(int(old["version"])).is_equal(3)
	for part: String in ["flag_days", "skills", "friends", "tally"]:
		assert_bool(old.has(part)).override_failure_message("version 3 knew no %s" % part).is_false()
	assert_bool((old["flags"] as Dictionary).has("keep_gate_open") or (old["flags"] as Dictionary).has("promised_elder_keep")).is_false()

	# The step by itself.
	var migrated: Dictionary = SaveSystem.migrate(old, 3)
	assert_int(int(migrated["version"])).is_equal(4)
	for part: String in ["flag_days", "skills", "friends", "tally"]:
		assert_dict(migrated[part]).override_failure_message("the step from 3 to 4 adds an empty %s" % part).is_empty()
	assert_dict(migrated["flags"]).override_failure_message("its flags, and the two that put it past the gates").is_equal(StoryGates.past_the_gates(old["flags"]))
	assert_bool(migrated["flags"]["keep_gate_open"] == true and migrated["flags"]["planted_first_crop"] == true).is_true()
	assert_bool((migrated["flags"] as Dictionary).has("crypt_open")).override_failure_message("the Warden stands: the bars stay down").is_false()
	assert_dict(migrated["farm"]).override_failure_message("and leaves the rest alone").is_equal(old["farm"])
	assert_bool((old["flags"] as Dictionary).has("keep_gate_open")).override_failure_message("the old data is left alone").is_false()

	# Loaded, as it would lie on disk.
	assert_int(_load_old("v3_in_the_keep.json")).is_equal(OK)
	assert_bool(GameState.get_flag(StoryGates.KEEP_GATE) == true).override_failure_message("he is not locked out of the keep he stands in").is_true()
	assert_bool(GameState.get_flag(StoryGates.FIRST_CROP) == true).is_true()
	assert_bool(GameState.get_flag(StoryGates.CRYPT_OPEN) == true).is_false()
	assert_bool(GameState.get_flag(&"promised_elder_keep") == true).override_failure_message("no promise is put in his mouth").is_false()
	assert_int(GameState.day).is_equal(4)
	assert_float(GameState.minute).is_equal(float(old["minute"]))
	assert_float(GameState.energy).is_equal(float(old["energy"]))
	assert_int(GameState.health).is_equal(int(old["health"]))
	assert_int(GameState.hearts_max).is_equal(int(old["hearts_max"]))
	assert_float(GameState.play_time).is_equal_approx(float(old["play_time"]), 0.01)
	assert_that(GameState.equipped).is_equal(&"bow")
	assert_dict(GameState.player).is_equal({"area": "keep", "cell": [22, 30]})
	assert_int(GameState.inventory.size()).is_equal((old["inventory"] as Array).size())
	for stack: Dictionary in old["inventory"]:
		assert_int(GameState.item_count(StringName(str(stack["id"])))).override_failure_message(str(stack["id"])).is_equal(int(stack["count"]))
	for flag: String in old["flags"]:
		assert_that(GameState.get_flag(StringName(flag), null)).override_failure_message(flag).is_equal(old["flags"][flag])
	assert_that(GameState.get_quest_stage(&"lost_shuttle")).is_equal(&"find")
	assert_str(GameState.farm().crop_at(Vector2i(0, 0))).override_failure_message("the plot is as he left it").is_equal("turnip")
	assert_int(GameState.farm().stage_of(Vector2i(0, 0))).is_equal(2)
	assert_bool(GameState.farm().is_withered(Vector2i(1, 0))).is_true()
	assert_int(GameState.tally_of(GameState.CROPS_PICKED)).override_failure_message("nothing was counted before").is_equal(0)
	assert_bool(GameState.skill_points.is_empty() and GameState.friends.is_empty() and GameState.flag_days.is_empty()).is_true()

	# Saved again, it is a version 4 save.
	assert_int(SaveSystem.save_to_slot(TEST_SLOT)).is_equal(OK)
	var again: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SaveSystem.slot_path(TEST_SLOT)))
	assert_int(int(again["version"])).is_equal(4)
	assert_dict(again["farm"]).is_equal(old["farm"])


func test_a_version_3_save_with_the_warden_fallen_has_the_bars_up() -> void:
	var old: Dictionary = _old_save("v3_in_the_keep.json")
	old["flags"]["keep_warden_beaten"] = true
	_write(TEST_SLOT, old)
	assert_int(SaveSystem.load_from_slot(TEST_SLOT)).is_equal(OK)
	assert_bool(GameState.get_flag(StoryGates.CRYPT_OPEN) == true).is_true()
	# The Warden fell before days were kept: for anything that waits a day on it, long ago.
	var check: ConditionEvaluator = ConditionEvaluator.new(GameState.to_dict())
	assert_bool(check.is_met({"type": "days_since", "flag": "keep_warden_beaten", "days": 1})).is_true()


func test_versions_1_and_2_still_load_and_are_past_the_gates() -> void:
	assert_int(_load_old("v1_playtest.json")).is_equal(OK)
	assert_bool(GameState.get_flag(StoryGates.KEEP_GATE) == true).is_true()
	assert_bool(GameState.get_flag(StoryGates.CRYPT_OPEN) == true).override_failure_message("its Warden had fallen").is_true()
	assert_int(GameState.day).override_failure_message("through the first step too").is_equal(1)
	assert_int(GameState.farm().count_of(Farm.BARE)).override_failure_message("and the second").is_equal(18)
	assert_int(_load_old("v2_third_day.json")).is_equal(OK)
	assert_bool(GameState.get_flag(StoryGates.KEEP_GATE) == true).is_true()
	assert_bool(GameState.get_flag(StoryGates.FIRST_CROP) == true).is_true()
	assert_bool(GameState.get_flag(StoryGates.CRYPT_OPEN) == true).is_false()
	assert_int(GameState.day).is_equal(3)
	assert_int(_load_old("v1_finished.json")).is_equal(OK)
	assert_bool(GameState.get_flag(EndingSummary.FINISHED_FLAG) == true).override_failure_message("a finished game is still finished").is_true()


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
