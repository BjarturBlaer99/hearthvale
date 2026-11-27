extends GdUnitTestSuite
## The item bar's columns in GameState and in saves (step B1 of the icons, axe and bar plan):
## each thing keeps its column; the last seed leaves its slot empty and the seeds come back to
## it; a better tool takes its tool's column; an empty slot is never in hand. The save keeps
## `bar` in version 6, and a save from before has today's order.

const TEST_SLOT: int = 942
const OLD_SAVES: String = "res://tests/fixtures/saves"


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	SaveSystem.current_slot = TEST_SLOT


func after_test() -> void:
	GameState.clear()
	SaveSystem.erase_slot(TEST_SLOT)
	SaveSystem.current_slot = SaveSystem.GAME_SLOT


func test_the_last_seed_leaves_its_slot_empty_and_the_seeds_come_back_to_it() -> void:
	for item: Array in [[&"wooden_sword", 1], [&"turnip_seeds", 1], [&"hoe", 1], [&"watering_can", 1]]:
		GameState.add_item(item[0], item[1])
	assert_array(_ids()).is_equal(["wooden_sword", "turnip_seeds", "hoe", "watering_can"])
	GameState.equip(&"turnip_seeds")
	GameState.add_item(&"turnip_seeds", -1)
	assert_that(GameState.equipped).override_failure_message("the sword in hand: nothing he doesn't carry").is_equal(&"")
	assert_array(_ids()).override_failure_message("the slot stays, empty").is_equal(["wooden_sword", "", "hoe", "watering_can"])
	assert_array(GameState.bar).is_equal([HandBar.SWORD, "turnip_seeds", "hoe", "watering_can"])
	# Something new doesn't take the remembered slot.
	GameState.add_item(&"bomb", 2)
	assert_array(_ids()).is_equal(["wooden_sword", "", "hoe", "watering_can", "bomb"])
	# The seeds bought again: back in their own slot.
	GameState.add_item(&"turnip_seeds", 5)
	assert_array(_ids()).is_equal(["wooden_sword", "turnip_seeds", "hoe", "watering_can", "bomb"])


func test_an_empty_slot_is_never_in_hand_and_the_wheel_steps_over_it() -> void:
	for item: Array in [[&"wooden_sword", 1], [&"bomb", 1], [&"hoe", 1]]:
		GameState.add_item(item[0], item[1])
	GameState.add_item(&"bomb", -1)
	GameState.equip(&"")
	assert_array(_ids()).is_equal(["wooden_sword", "", "hoe"])
	assert_bool(GameState.take_in_hand(1)).override_failure_message("an empty slot: nothing").is_false()
	assert_that(GameState.equipped).is_equal(&"")
	assert_bool(GameState.step_hand(1)).is_true()
	assert_that(GameState.equipped).override_failure_message("over the empty slot").is_equal(&"hoe")
	assert_int(GameState.hand_index()).is_equal(2)
	assert_bool(GameState.step_hand(-1)).is_true()
	assert_that(GameState.equipped).is_equal(&"")
	assert_bool(GameState.step_hand(-1)).is_true()
	assert_that(GameState.equipped).override_failure_message("back from the sword, round to the hoe").is_equal(&"hoe")


func test_a_copper_hoe_made_from_the_hoe_takes_its_slot() -> void:
	for item: Array in [[&"wooden_sword", 1], [&"hoe", 1], [&"watering_can", 1], [&"turnip_seeds", 3], [&"copper_bar", 2]]:
		GameState.add_item(item[0], item[1])
	GameState.equip(&"turnip_seeds")
	assert_array(_ids()).is_equal(["wooden_sword", "hoe", "watering_can", "turnip_seeds"])
	assert_str(GameState.craft(&"copper_hoe")).is_empty()
	assert_array(_ids()).override_failure_message("in the hoe's slot, not at the end").is_equal(["wooden_sword", "copper_hoe", "watering_can", "turnip_seeds"])
	assert_that(GameState.equipped).override_failure_message("what was in hand stays").is_equal(&"turnip_seeds")
	# Made with the hoe in hand, it is in hand, in the same slot.
	GameState.add_item(&"copper_hoe", -1)
	GameState.add_item(&"hoe")
	assert_array(_ids()).override_failure_message("a hoe again takes the copper hoe's empty slot").is_equal(["wooden_sword", "hoe", "watering_can", "turnip_seeds"])
	GameState.add_item(&"copper_bar", 2)
	GameState.equip(&"hoe")
	assert_str(GameState.craft(&"copper_hoe")).is_empty()
	assert_that(GameState.equipped).is_equal(&"copper_hoe")
	assert_int(GameState.hand_index()).is_equal(1)


func test_a_new_thing_takes_the_first_slot_that_remembers_nothing() -> void:
	GameState.add_item(&"wooden_sword")
	GameState.add_item(&"hoe")
	# A bar with a free column in it (as the screen of step B2 will leave one).
	GameState.bar = [HandBar.SWORD, "", "hoe"]
	GameState.add_item(&"axe")
	assert_array(_ids()).is_equal(["wooden_sword", "axe", "hoe"])
	GameState.add_item(&"pickaxe")
	assert_array(_ids()).override_failure_message("no free one: the end").is_equal(["wooden_sword", "axe", "hoe", "pickaxe"])
	# Food and placeables never go on the bar.
	GameState.add_item(&"bread", 2)
	GameState.add_item(&"fence", 3)
	assert_array(GameState.bar).is_equal([HandBar.SWORD, "axe", "hoe", "pickaxe"])


func test_a_save_keeps_the_bar_with_its_empty_slots() -> void:
	for item: Array in [[&"wooden_sword", 1], [&"bomb", 1], [&"hoe", 1], [&"carrot_seeds", 2]]:
		GameState.add_item(item[0], item[1])
	GameState.add_item(&"bomb", -1)
	var saved: Dictionary = GameState.to_dict()
	assert_array(saved["bar"]).is_equal([HandBar.SWORD, "bomb", "hoe", "carrot_seeds"])
	assert_int(int(saved["version"])).override_failure_message("the save stays version 6").is_equal(6)
	assert_int(SaveSystem.save_game()).is_equal(OK)
	GameState.clear()
	assert_array(GameState.bar).is_empty()
	assert_int(SaveSystem.load_game()).is_equal(OK)
	assert_array(GameState.bar).is_equal([HandBar.SWORD, "bomb", "hoe", "carrot_seeds"])
	assert_array(_ids()).is_equal(["wooden_sword", "", "hoe", "carrot_seeds"])
	GameState.add_item(&"bomb", 3)
	assert_array(_ids()).override_failure_message("the bombs come back to their slot after a load").is_equal(["wooden_sword", "bomb", "hoe", "carrot_seeds"])


func test_a_damaged_bar_in_a_save_is_made_sound() -> void:
	for item: Array in [[&"wooden_sword", 1], [&"hoe", 1], [&"watering_can", 1]]:
		GameState.add_item(item[0], item[1])
	var saved: Dictionary = GameState.to_dict()
	saved["bar"] = ["watering_can", "bread", "moon_hoe", "watering_can", 12]
	_write(TEST_SLOT, saved)
	assert_int(SaveSystem.load_game()).is_equal(OK)
	assert_array(GameState.bar).override_failure_message("the sword first, the can kept, the hoe after").is_equal([HandBar.SWORD, "watering_can", "hoe"])
	saved["bar"] = "not a list"
	_write(TEST_SLOT, saved)
	assert_int(SaveSystem.load_game()).is_equal(OK)
	assert_array(GameState.bar).is_equal([HandBar.SWORD, "hoe", "watering_can"])


func test_a_save_from_before_has_the_bar_as_it_was() -> void:
	for item: Array in [[&"hoe", 1], [&"bread", 2], [&"wooden_sword", 1], [&"bow", 1], [&"arrow", 4], [&"turnip_seeds", 3]]:
		GameState.add_item(item[0], item[1])
	var saved: Dictionary = GameState.to_dict()
	saved.erase("bar")
	_write(TEST_SLOT, saved)
	GameState.clear()
	assert_int(SaveSystem.load_game()).is_equal(OK)
	assert_array(GameState.bar).is_equal([HandBar.SWORD, "hoe", "bow", "turnip_seeds"])
	assert_array(_ids()).is_equal(["wooden_sword", "hoe", "bow", "turnip_seeds"])


func test_every_old_save_loads_with_the_bar_it_had() -> void:
	var dir: DirAccess = DirAccess.open(OLD_SAVES)
	var files: PackedStringArray = dir.get_files()
	var loaded: int = 0
	for file: String in files:
		if not file.ends_with(".json"):
			continue
		var data: Variant = JSON.parse_string(FileAccess.get_file_as_string(OLD_SAVES.path_join(file)))
		assert_bool((data as Dictionary).has("bar")).override_failure_message(file + " was written before the bar's columns").is_false()
		GameState.new_game()
		_write(TEST_SLOT, data)
		assert_int(SaveSystem.load_from_slot(TEST_SLOT)).override_failure_message(file).is_equal(OK)
		var items: Array = DataRegistry.entries(&"items")
		assert_array(GameState.bar).override_failure_message(file + ": the sword, then the pack's order").is_equal(HandBar.default_bar(GameState.inventory, items))
		assert_array(_ids()).override_failure_message(file).is_equal(_entry_ids(HandBar.entries(GameState.inventory, items)))
		loaded += 1
	assert_int(loaded).override_failure_message("v1 to v6").is_equal(8)
	# The cottage's save (v5): his tools as he picked them up, the hoe in hand.
	GameState.new_game()
	_write(TEST_SLOT, JSON.parse_string(FileAccess.get_file_as_string(OLD_SAVES.path_join("v5_in_the_old_cottage.json"))))
	assert_int(SaveSystem.load_from_slot(TEST_SLOT)).is_equal(OK)
	assert_array(GameState.bar).is_equal([HandBar.SWORD, "hoe", "watering_can", "carrot_seeds", "pickaxe"])
	assert_that(GameState.equipped).is_equal(&"hoe")
	assert_int(GameState.hand_index()).is_equal(1)
	# Its last carrot seed sown, the slot stays.
	GameState.add_item(&"carrot_seeds", -1)
	assert_array(_ids()).is_equal(["wooden_sword", "hoe", "watering_can", "", "pickaxe"])


func test_a_thing_moved_on_the_bar_keeps_its_new_slot_and_stays_in_hand() -> void:
	for item: Array in [[&"wooden_sword", 1], [&"hoe", 1], [&"watering_can", 1], [&"bomb", 2]]:
		GameState.add_item(item[0], item[1])
	GameState.equip(&"hoe")
	assert_bool(GameState.move_on_bar(1, 3)).override_failure_message("the hoe swaps with the bombs").is_true()
	assert_array(_ids()).is_equal(["wooden_sword", "bomb", "watering_can", "hoe"])
	assert_that(GameState.equipped).override_failure_message("still in hand, in its new slot").is_equal(&"hoe")
	assert_int(GameState.hand_index()).is_equal(3)
	assert_bool(GameState.move_on_bar(0, 6)).override_failure_message("the sword into an empty slot past the end").is_true()
	assert_array(_ids()).is_equal(["", "bomb", "watering_can", "hoe", "", "", "wooden_sword"])
	assert_bool(GameState.move_on_bar(2, 2)).override_failure_message("set down where it was lifted").is_false()
	assert_bool(GameState.move_on_bar(9, 0)).override_failure_message("nothing there").is_false()
	# The last bomb: its slot stays where it was put, and they come back to it.
	GameState.add_item(&"bomb", -2)
	GameState.add_item(&"carrot_seeds", 3)
	assert_array(_ids()).override_failure_message("something new takes the first free slot").is_equal(["carrot_seeds", "", "watering_can", "hoe", "", "", "wooden_sword"])
	GameState.add_item(&"bomb", 1)
	assert_array(_ids()).is_equal(["carrot_seeds", "bomb", "watering_can", "hoe", "", "", "wooden_sword"])
	# The save keeps it, version 6.
	assert_int(SaveSystem.save_game()).is_equal(OK)
	GameState.clear()
	assert_int(SaveSystem.load_game()).is_equal(OK)
	assert_array(GameState.bar).is_equal(["carrot_seeds", "bomb", "watering_can", "hoe", "", "", HandBar.SWORD])
	assert_array(_ids()).is_equal(["carrot_seeds", "bomb", "watering_can", "hoe", "", "", "wooden_sword"])


func test_a_move_counts_the_columns_as_the_bar_shows_them() -> void:
	# A thing put in the pack without add_item (as a test may) has no column yet: the move counts
	# the columns hand_entries() shows, where it has one.
	GameState.add_item(&"wooden_sword", 1)
	GameState.inventory.append({"id": &"hoe", "count": 1})
	assert_array(GameState.bar).is_equal([HandBar.SWORD])
	assert_array(_ids()).is_equal(["wooden_sword", "hoe"])
	assert_bool(GameState.move_on_bar(1, 0)).is_true()
	assert_array(GameState.bar).is_equal(["hoe", HandBar.SWORD])
	assert_array(_ids()).is_equal(["hoe", "wooden_sword"])


func _ids() -> Array:
	return _entry_ids(GameState.hand_entries())


func _entry_ids(entries: Array) -> Array:
	return entries.map(func(item: Dictionary) -> String: return str(item.get("id", "")))


func _write(slot: int, data: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(SaveSystem.SAVE_DIR)
	var file: FileAccess = FileAccess.open(SaveSystem.slot_path(slot), FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
