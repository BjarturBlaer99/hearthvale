extends GdUnitTestSuite
## Save version 5 (mining, phase 1): the number the mine's rolls come from and the rocks broken
## today go through a save; a version 4 save (made by the game as it stood before the mine)
## loads with everything it had, a whole mine and no Pickaxe; versions 1 to 3 still load,
## through every step.

const TEST_SLOT: int = 962
const OLD_SAVES: String = "res://tests/fixtures/saves"
const V4: String = "v4_before_the_mine.json"


func before_test() -> void:
	GameState.clear()


func after_test() -> void:
	GameState.clear()
	SaveSystem.current_slot = SaveSystem.GAME_SLOT
	SaveSystem.erase_slot(TEST_SLOT)


func test_every_new_game_s_mine_rolls_its_own_way() -> void:
	assert_int(GameState.SAVE_VERSION).is_equal(6)
	var numbers: Dictionary = {}
	for game: int in 6:
		GameState.clear()
		GameState.new_game()
		numbers[GameState.mine().number] = true
		assert_int(GameState.mine().day).override_failure_message("its list is today's").is_equal(1)
	assert_int(numbers.size()).override_failure_message("six games, and not one number between them").is_greater(1)


func test_a_rock_is_broken_for_the_day_and_whole_the_next_morning() -> void:
	GameState.new_game()
	assert_bool(GameState.is_rock_broken(&"quarry_1", Vector2i(3, 4))).is_false()
	GameState.break_rock(&"quarry_1", Vector2i(3, 4))
	assert_bool(GameState.is_rock_broken(&"quarry_1", Vector2i(3, 4))).is_true()
	assert_bool(GameState.is_rock_broken(&"quarry_2", Vector2i(3, 4))).is_false()
	var number: int = GameState.mine().number
	GameState.start_next_day()
	assert_bool(GameState.is_rock_broken(&"quarry_1", Vector2i(3, 4))).override_failure_message("a new day: whole again").is_false()
	assert_dict(GameState.to_dict()["mine"]).is_equal({"number": number, "day": 2, "broken": {}})
	# Sleeping is a new day too.
	GameState.break_rock(&"quarry_1", Vector2i(3, 4))
	GameState.sleep()
	assert_bool(GameState.is_rock_broken(&"quarry_1", Vector2i(3, 4))).is_false()
	assert_int(GameState.mine().number).override_failure_message("the number is the game's for good").is_equal(number)


func test_the_days_roll_is_the_floors_own_and_the_halls_is_plain() -> void:
	GameState.new_game()
	GameState.mine().number = 7
	var cells: Array[Vector2i] = [Vector2i(2, 2), Vector2i(3, 2), Vector2i(4, 2), Vector2i(5, 2), Vector2i(6, 2), Vector2i(7, 2), Vector2i(8, 2)]
	var roll: Dictionary = GameState.mine_roll(&"quarry_1", cells)
	assert_dict(roll).is_equal(MineRolls.roll(7, 1, 1, cells, {&"copper_ore": 5}, true))
	assert_dict(GameState.mine_roll(&"quarry_9", cells)).override_failure_message("the last floor has no ladder").is_equal(MineRolls.roll(7, 1, 9, cells, {&"gold_ore": 2, &"crystal": 2}, false))
	var hall: Dictionary = GameState.mine_roll(&"quarry", cells)
	assert_that(hall["ladder"]).is_equal(MineRolls.NO_CELL)
	for cell: Vector2i in cells:
		assert_that(hall["kinds"][cell]).is_equal(MineRules.STONE)
	GameState.start_next_day()
	assert_dict(GameState.mine_roll(&"quarry_1", cells)).override_failure_message("tomorrow's is tomorrow's").is_equal(MineRolls.roll(7, 2, 1, cells, {&"copper_ore": 5}, true))


func test_the_mine_goes_through_a_save() -> void:
	GameState.new_game()
	GameState.mine().number = 424242
	GameState.start_next_day()
	GameState.break_rock(&"quarry_1", Vector2i(7, 2))
	GameState.break_rock(&"quarry_1", Vector2i(3, 4))
	GameState.break_rock(&"quarry_4", Vector2i(9, 9))
	GameState.set_flag(MineRules.lift_flag(4), true)
	GameState.add_item(&"pickaxe")
	GameState.add_item(&"copper_ore", 9)
	GameState.update_player(&"quarry_4", Vector2i(8, 1))
	assert_int(SaveSystem.save_to_slot(TEST_SLOT)).is_equal(OK)
	var on_disk: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SaveSystem.slot_path(TEST_SLOT)))
	assert_int(int(on_disk["version"])).is_equal(6)
	assert_dict(on_disk["mine"]).is_equal({"number": 424242.0, "day": 2.0, "broken": {"quarry_1": ["3,4", "7,2"], "quarry_4": ["9,9"]}})
	var before: String = JSON.stringify(GameState.to_dict(), "", true)
	GameState.clear()
	assert_bool(GameState.is_rock_broken(&"quarry_1", Vector2i(3, 4))).override_failure_message("cleared").is_false()
	assert_int(SaveSystem.load_from_slot(TEST_SLOT)).is_equal(OK)
	assert_str(JSON.stringify(GameState.to_dict(), "", true)).is_equal(before)
	assert_int(GameState.mine().number).is_equal(424242)
	assert_bool(GameState.is_rock_broken(&"quarry_1", Vector2i(3, 4))).is_true()
	assert_bool(GameState.is_rock_broken(&"quarry_4", Vector2i(9, 9))).is_true()
	assert_bool(GameState.is_rock_broken(&"quarry_4", Vector2i(3, 4))).is_false()
	assert_bool(GameState.get_flag(MineRules.lift_flag(4)) == true).is_true()
	assert_int(GameState.item_count(&"copper_ore")).is_equal(9)
	assert_dict(GameState.player).is_equal({"area": "quarry_4", "cell": [8, 1]})
	# A save whose broken rocks are another day's loads with them whole.
	var stale: Dictionary = GameState.to_dict()
	stale["day"] = 3
	GameState.from_dict(stale)
	assert_bool(GameState.is_rock_broken(&"quarry_1", Vector2i(3, 4))).is_false()
	assert_int(GameState.mine().number).is_equal(424242)
	# And one with no mine in it at all still loads: a whole mine.
	stale.erase("mine")
	GameState.from_dict(stale)
	assert_dict(GameState.to_dict()["mine"]["broken"]).is_empty()


func test_a_version_4_save_loads_with_all_it_had_and_a_whole_mine() -> void:
	# Written by the game as it stood before the mine: the sixth day, at home.
	var old: Dictionary = _old_save(V4)
	assert_int(int(old["version"])).is_equal(4)
	assert_bool(old.has("mine")).override_failure_message("version 4 knew no mine").is_false()

	# The step by itself: it adds the mine and touches nothing else.
	var migrated: Dictionary = SaveSystem.migrate(old, 4)
	assert_int(int(migrated["version"])).is_equal(6)
	assert_dict(migrated["mine"]["broken"]).is_empty()
	assert_int(int(migrated["mine"]["day"])).is_equal(0)
	assert_int(typeof(migrated["mine"]["number"])).is_equal(TYPE_INT)
	assert_that(SaveSystem.migrate(old, 4)["mine"]["number"]).override_failure_message("the same save rolls the same way every time it is loaded").is_equal(migrated["mine"]["number"])
	for part: String in old:
		if part != "version":
			assert_that(migrated[part]).override_failure_message("%s is left alone" % part).is_equal(old[part])
	assert_bool(old.has("mine")).override_failure_message("the old data is left alone").is_false()

	# Loaded, as it would lie on disk.
	assert_int(_load_old(V4)).is_equal(OK)
	assert_int(GameState.day).is_equal(6)
	assert_float(GameState.minute).is_equal(615.0)
	assert_float(GameState.energy).is_equal(100.0)
	assert_int(GameState.health).is_equal(6)
	assert_that(GameState.equipped).is_equal(&"hoe")
	assert_dict(GameState.player).is_equal({"area": "home", "cell": [5, 5]})
	assert_int(GameState.inventory.size()).is_equal((old["inventory"] as Array).size())
	for stack: Dictionary in old["inventory"]:
		assert_int(GameState.item_count(StringName(str(stack["id"])))).override_failure_message(str(stack["id"])).is_equal(int(stack["count"]))
	for flag: String in old["flags"]:
		assert_that(GameState.get_flag(StringName(flag), null)).override_failure_message(flag).is_equal(old["flags"][flag])
	assert_int(GameState.friend_points(&"pip")).is_equal(6)
	assert_int(GameState.skill_points[&"farming"]).is_equal(3)
	assert_str(GameState.farm().crop_at(Vector2i(0, 0))).is_equal("turnip")
	assert_bool(GameState.farm().is_withered(Vector2i(0, 0))).is_true()
	# The new things start as they start for anyone: no Pickaxe, nothing broken, no lift.
	assert_int(GameState.item_count(&"pickaxe")).override_failure_message("he buys one at Tilda's like anyone").is_equal(0)
	assert_int(GameState.mine().number).is_equal(int(migrated["mine"]["number"]))
	assert_bool(GameState.is_rock_broken(&"quarry_1", Vector2i(3, 4))).is_false()
	for floor: int in GameState.mine_rules().lift_floors():
		assert_bool(GameState.get_flag(MineRules.lift_flag(floor)) == true).override_failure_message("the lift has been nowhere").is_false()
	assert_bool(GameState.get_flag(&"took_quarry_heart_piece") == true).is_false()

	# Saved again, it is a save of today's version, and loads back the same.
	assert_int(SaveSystem.save_to_slot(TEST_SLOT)).is_equal(OK)
	var again: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SaveSystem.slot_path(TEST_SLOT)))
	assert_int(int(again["version"])).is_equal(6)
	assert_dict(again["farm"]).is_equal(old["farm"])
	var before: String = JSON.stringify(GameState.to_dict(), "", true)
	assert_int(SaveSystem.load_from_slot(TEST_SLOT)).is_equal(OK)
	assert_str(JSON.stringify(GameState.to_dict(), "", true)).is_equal(before)


func test_versions_1_to_3_still_load_and_come_out_with_a_mine() -> void:
	for file: String in ["v1_playtest.json", "v1_finished.json", "v2_third_day.json", "v3_in_the_keep.json"]:
		var old: Dictionary = _old_save(file)
		var migrated: Dictionary = SaveSystem.migrate(old, int(old["version"]))
		assert_int(int(migrated["version"])).override_failure_message(file).is_equal(6)
		assert_dict(migrated["mine"]["broken"]).override_failure_message(file).is_empty()
		assert_int(_load_old(file)).override_failure_message(file).is_equal(OK)
		assert_bool(GameState.is_started()).is_true()
		assert_bool(GameState.is_rock_broken(&"quarry_1", Vector2i(3, 4))).is_false()
		assert_int(GameState.item_count(&"pickaxe")).is_equal(0)


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
