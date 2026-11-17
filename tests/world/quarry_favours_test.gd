extends GdUnitTestSuite
## The two favours of the balance pass (mining and crafting, phase 3): at three marks Wenna
## asks for five coal ("Black for the Loom") and Shepherd Edda for two iron bars ("New
## Shears"). Each still teaches her recipe at two marks, and that comes first. Both are data:
## a quest of the favours' shape, and an opening and four nodes in the villager's
## conversation. The rewards are given, so a full pack loses none of them.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const WEAVER: String = "res://world/areas/weaver_house/weaver_house.tscn"
const FIELDS: String = "res://world/areas/north_fields/north_fields.tscn"
const OLD_SAVE: String = "res://tests/fixtures/saves/v4_before_the_mine.json"
const TEST_SLOT: int = 957

## The plan's two favours: where the villager is, their node, their id, the quest and its
## title, the recipe they teach at two marks, what the favour wants and how many, the answer
## that takes it, the one that hands the thing over, the one that reminds, a word of the
## asking, and what finishing it gives.
const FAVOURS: Array = [
	[WEAVER, "Wenna", &"wenna", &"black_for_the_loom", "Black for the Loom", &"berry_jam", &"coal", 5,
		"I'll bring it.", "Five lumps of coal, Wenna.", "About that coal...", "five lumps", {&"coin": 30, &"blossom_tea": 2}],
	[FIELDS, "ShepherdEdda", &"shepherd_edda", &"new_shears", "New Shears", &"shepherds_pie", &"iron_bar", 2,
		"I'll bring them.", "Two iron bars, Edda.", "About those shears...", "two bars of iron", {&"coin": 50, &"shepherds_pie": 1}],
]

var _area: Node


func before_test() -> void:
	SaveSystem.erase_slot(TEST_SLOT)
	SaveSystem.current_slot = TEST_SLOT
	_fresh()


func after_test() -> void:
	if is_instance_valid(_area):
		_area.free()
	_area = null
	get_tree().paused = false
	SaveSystem.erase_slot(TEST_SLOT)
	SaveSystem.current_slot = SaveSystem.GAME_SLOT
	GameState.clear()


func test_at_three_marks_wenna_and_edda_ask_a_favour_that_can_be_put_off_taken_and_finished() -> void:
	for favour: Array in FAVOURS:
		_fresh()
		var who: StringName = favour[2]
		var quest: StringName = favour[3]
		var wanted: StringName = favour[6]
		var many: int = favour[7]
		var start_text: String = _start_text(who)
		# Her recipe is taught already, as it would be by three marks.
		GameState.learn_recipe(favour[5])
		# Two marks: nothing is asked. (Ten points, and the day's first talk makes eleven.) He
		# carries what she will ask for, and there is nothing to hand it over for yet.
		GameState.add_friendship(who, 10)
		GameState.add_item(wanted, many)
		var area: AreaController = _load(favour[0])
		var box: DialogueBox = area.hud.dialogue
		_talk(area, favour[1])
		assert_int(GameState.friend_marks(who)).is_equal(2)
		assert_str(box.shown_text()).override_failure_message("%s at two marks" % who).is_equal(start_text)
		assert_bool(Array(box.shown_options()).has(favour[8])).is_false()
		assert_bool(Array(box.shown_options()).has(favour[9]) or Array(box.shown_options()).has(favour[10])).override_failure_message("no favour was asked: nothing to hand over, nothing to be reminded of").is_false()
		_end(area)
		GameState.add_item(wanted, -many)
		# Three marks: the favour is asked, and can be put off.
		GameState.add_friendship(who, 1)
		assert_int(GameState.friend_marks(who)).is_equal(3)
		_talk(area, favour[1])
		assert_str(box.shown_text()).override_failure_message("%s says what she wants" % who).contains(favour[11])
		assert_array(Array(box.shown_options())).override_failure_message("%s asks at three marks" % who).is_equal([favour[8], "Not just now."])
		_say(area, "Not just now.")
		assert_str(box.shown_text()).override_failure_message("put off, she talks as she always does").is_equal(start_text)
		assert_that(Quests.runner.status(quest)).is_equal(QuestState.NOT_STARTED)
		_end(area)
		# Asked again at the next talk, and taken.
		_talk(area, favour[1])
		_say(area, favour[8])
		assert_that(Quests.runner.status(quest)).is_equal(QuestState.ACTIVE)
		assert_that(Quests.runner.stage(quest)).is_equal(&"bring")
		assert_str(Quests.runner.title(quest)).is_equal(favour[4])
		assert_array(Array(area.hud.notice_lines())).contains(["New quest: %s" % favour[4]])
		assert_array(Quests.runner.objectives(quest).map(func(objective: Dictionary) -> bool: return objective["done"])).is_equal([false, false])
		_end(area)
		# One short of what was asked for: only the reminder.
		GameState.add_item(wanted, many - 1)
		_talk(area, favour[1])
		assert_str(box.shown_text()).override_failure_message("no favour asked twice").is_equal(start_text)
		assert_bool(Array(box.shown_options()).has(favour[10])).is_true()
		assert_bool(Array(box.shown_options()).has(favour[9])).override_failure_message("%d %s are not %d" % [many - 1, wanted, many]).is_false()
		assert_array(Quests.runner.objectives(quest).map(func(objective: Dictionary) -> bool: return objective["done"])).is_equal([false, false])
		_say(area, favour[10])
		assert_str(box.shown_text()).override_failure_message("the reminder says where it comes from").contains("Old Quarry")
		_end(area)
		# With one more than was asked for, it is handed over: she takes what she asked for and
		# no more, and the reward is the plan's.
		GameState.add_item(wanted, 2)
		assert_array(Quests.runner.objectives(quest).map(func(objective: Dictionary) -> bool: return objective["done"])).is_equal([true, false])
		_talk(area, favour[1])
		assert_str(box.shown_options()[0]).override_failure_message("handing it over is the first answer").is_equal(favour[9])
		_say(area, favour[9])
		assert_int(GameState.item_count(wanted)).override_failure_message("%s took %d and left one" % [who, many]).is_equal(1)
		assert_that(Quests.runner.status(quest)).is_equal(QuestState.COMPLETE)
		assert_array(Array(area.hud.notice_lines())).contains(["Quest complete: %s" % favour[4]])
		var rewards: Dictionary = favour[12]
		for item: StringName in rewards:
			assert_int(GameState.item_count(item)).override_failure_message("%s gives %d %s" % [who, rewards[item], item]).is_equal(rewards[item])
		_end(area)
		# Done with: neither the favour nor its answers come again, though he carries enough to
		# hand over a second time.
		GameState.add_item(wanted, many)
		_talk(area, favour[1])
		assert_str(box.shown_text()).is_equal(start_text)
		assert_bool(Array(box.shown_options()).has(favour[8]) or Array(box.shown_options()).has(favour[9]) or Array(box.shown_options()).has(favour[10])).is_false()
		_end(area)


func test_the_recipe_at_two_marks_still_comes_first() -> void:
	for favour: Array in FAVOURS:
		_fresh()
		var who: StringName = favour[2]
		var recipe: StringName = favour[5]
		# Three marks at once, with nothing taught yet: the lesson, then the favour.
		GameState.add_friendship(who, 12)
		var area: AreaController = _load(favour[0])
		var box: DialogueBox = area.hud.dialogue
		_talk(area, favour[1])
		assert_bool(GameState.knows_recipe(recipe)).override_failure_message("%s teaches %s first" % [who, recipe]).is_true()
		assert_array(Array(box.shown_options())).is_equal(["Thank you."])
		assert_that(Quests.runner.status(favour[3])).is_equal(QuestState.NOT_STARTED)
		_end(area)
		_talk(area, favour[1])
		assert_array(Array(box.shown_options())).override_failure_message("then %s asks" % who).is_equal([favour[8], "Not just now."])
		_end(area)
		assert_that(Quests.runner.status(favour[3])).override_failure_message("put off by the last answer").is_equal(QuestState.NOT_STARTED)


func test_at_two_marks_the_recipe_is_taught_and_no_favour_is_asked() -> void:
	for favour: Array in FAVOURS:
		_fresh()
		var who: StringName = favour[2]
		GameState.add_friendship(who, 8)
		var area: AreaController = _load(favour[0])
		_talk(area, favour[1])
		assert_bool(GameState.knows_recipe(favour[5])).is_true()
		_end(area)
		# The next day, and the day after: eleven points are still two marks.
		for day: int in 2:
			GameState.start_next_day()
			GameState.set_time(float(GameState.day_clock().in_day("12:00")))
			_talk(area, favour[1])
			assert_str(area.hud.dialogue.shown_text()).override_failure_message("%s talks as she always does" % who).is_equal(_start_text(who))
			assert_bool(Array(area.hud.dialogue.shown_options()).has(favour[8])).is_false()
			_end(area)
		assert_int(GameState.friend_points(who)).is_equal(11)
		# The twelfth point is the third mark.
		GameState.start_next_day()
		GameState.set_time(float(GameState.day_clock().in_day("12:00")))
		_talk(area, favour[1])
		assert_array(Array(area.hud.dialogue.shown_options())).is_equal([favour[8], "Not just now."])
		_end(area)


func test_a_full_pack_loses_nothing_of_either_reward() -> void:
	# Wenna's tea: ten cups are a full stack, so both of hers are laid at his feet.
	GameState.add_item(&"blossom_tea", 10)
	GameState.set_quest_stage(&"black_for_the_loom", &"bring")
	GameState.add_item(&"coal", 5)
	var house: AreaController = _load(WEAVER)
	_talk(house, "Wenna")
	_say(house, "Five lumps of coal, Wenna.")
	_end(house)
	assert_that(Quests.runner.status(&"black_for_the_loom")).is_equal(QuestState.COMPLETE)
	assert_int(GameState.item_count(&"coin")).is_equal(30)
	assert_int(GameState.item_count(&"blossom_tea")).is_equal(10)
	assert_dict(_lying(house)).override_failure_message("two cups at his feet").is_equal({&"blossom_tea": 2})
	assert_array(LeftItems.owed(GameState.flags)).override_failure_message("laid down, no longer owed").is_empty()
	assert_array(Array(house.hud.notice_lines())).contains([LeftItems.words("Cherry Blossom Tea", 2)])
	# Edda's coins and pie: a purse nineteen short of full takes nineteen, and the pie has no room.
	_fresh()
	GameState.add_item(&"coin", 980)
	GameState.add_item(&"shepherds_pie", 10)
	GameState.set_quest_stage(&"new_shears", &"bring")
	GameState.add_item(&"iron_bar", 2)
	var fields: AreaController = _load(FIELDS)
	_talk(fields, "ShepherdEdda")
	_say(fields, "Two iron bars, Edda.")
	_end(fields)
	assert_that(Quests.runner.status(&"new_shears")).is_equal(QuestState.COMPLETE)
	assert_int(GameState.item_count(&"coin")).is_equal(999)
	assert_int(GameState.item_count(&"shepherds_pie")).is_equal(10)
	assert_dict(_lying(fields)).override_failure_message("thirty-one coins and the pie at his feet").is_equal({&"coin": 31, &"shepherds_pie": 1})


func test_both_are_quests_of_the_same_shape_as_the_other_favours() -> void:
	var givers: Dictionary = {&"black_for_the_loom": "wenna_weaver", &"new_shears": "shepherd_edda"}
	for favour: Array in FAVOURS:
		var quest_id: StringName = favour[3]
		var quest: Dictionary = DataRegistry.get_quest(quest_id)
		assert_str(str(quest["title"])).is_equal(favour[4])
		assert_str(str(quest["giver"])).is_equal(givers[quest_id])
		assert_str(str(quest["start_stage"])).is_equal("bring")
		assert_array((quest["stages"] as Dictionary).keys()).is_equal(["bring", "done"])
		for stage_id: String in quest["stages"]:
			assert_int(str(quest["stages"][stage_id]["journal"]).length()).override_failure_message("'%s' is short enough for the log" % stage_id).is_less_equal(150)
		# The reward is given, never added: what a full pack can't take is laid at his feet.
		var rewards: Dictionary = favour[12]
		var given: Dictionary = {}
		for effect: Dictionary in quest["stages"]["done"]["on_enter"]:
			assert_bool(str(effect["type"]) in ["give_item", "complete_quest"]).override_failure_message("'%s' in %s's reward" % [effect["type"], quest_id]).is_true()
			if str(effect["type"]) == "give_item":
				given[StringName(str(effect["item"]))] = int(effect["count"])
		assert_dict(given).is_equal(rewards)
		# What it wants fits in the pack, and having it is the first objective.
		assert_int(int(DataRegistry.get_item(favour[6])["max_stack"])).is_greater_equal(int(favour[7]))
		_fresh()
		Quests.runner.start(quest_id)
		assert_str(Quests.runner.journal(quest_id)).contains("Old Quarry" if quest_id == &"black_for_the_loom" else "furnace")
		GameState.add_item(favour[6], int(favour[7]) - 1)
		assert_array(Quests.runner.objectives(quest_id).map(func(objective: Dictionary) -> bool: return objective["done"])).is_equal([false, false])
		GameState.add_item(favour[6], 1)
		assert_array(Quests.runner.objectives(quest_id).map(func(objective: Dictionary) -> bool: return objective["done"])).is_equal([true, false])
		assert_that(Quests.runner.status(quest_id)).override_failure_message("not until it is handed over").is_equal(QuestState.ACTIVE)
		assert_int(GameState.item_count(&"coin")).is_equal(0)
	# Coal is in the quarry's rocks and iron bars come out of the furnace: both can be had.
	var floors_with_coal: int = 0
	var mine: MineRules = GameState.mine_rules()
	for level: int in range(1, mine.floor_count() + 1):
		floors_with_coal += 1 if int(mine.ores_of(level).get(&"coal", 0)) > 0 else 0
	assert_int(floors_with_coal).override_failure_message("floors 4 to 8").is_equal(5)
	var smelted: Array = DataRegistry.entries(&"crafting").filter(func(recipe: Dictionary) -> bool: return str(recipe["station"]) == "furnace" and str(recipe["makes"]["item"]) == "iron_bar")
	assert_int(smelted.size()).is_equal(1)
	assert_array(Array(DataRegistry.errors)).override_failure_message("the game's own data loads clean").is_empty()


func test_a_save_from_before_the_mine_loads_with_neither_favour_begun_and_one_begun_is_kept() -> void:
	DirAccess.make_dir_recursive_absolute(SaveSystem.SAVE_DIR)
	SaveSystem._write_text(SaveSystem.slot_path(TEST_SLOT), FileAccess.get_file_as_string(OLD_SAVE))
	assert_int(SaveSystem.load_game()).is_equal(OK)
	for favour: Array in FAVOURS:
		assert_that(Quests.runner.status(favour[3])).override_failure_message("%s in an older save" % favour[3]).is_equal(QuestState.NOT_STARTED)
	# Taken, and one of them finished, they go through a save like any quest.
	GameState.set_quest_stage(&"black_for_the_loom", &"bring")
	GameState.set_quest_stage(&"new_shears", &"bring")
	GameState.set_flag(&"shears_iron_given", true)
	var coins: int = GameState.item_count(&"coin")
	assert_int(SaveSystem.save_game()).is_equal(OK)
	GameState.new_game()
	assert_int(SaveSystem.load_game()).is_equal(OK)
	assert_that(Quests.runner.status(&"black_for_the_loom")).is_equal(QuestState.ACTIVE)
	assert_that(Quests.runner.status(&"new_shears")).is_equal(QuestState.COMPLETE)
	assert_int(GameState.item_count(&"coin")).override_failure_message("the reward is not given again on loading").is_equal(coins)


## A game begun, at noon, with the first crop in.
func _fresh() -> void:
	if is_instance_valid(_area):
		_area.free()
	_area = null
	GameState.clear()
	GameState.new_game()
	GameState.set_time(float(GameState.day_clock().in_day("12:00")))
	GameState.set_flag(StoryGates.FIRST_CROP, true)
	Quests.refresh()


## What `who` says when nothing is opened: the start node of their conversation.
func _start_text(who: StringName) -> String:
	var dialogue: Dictionary = DataRegistry.get_dialogue(StringName(str(DataRegistry.get_villager(who)["dialogue"])))
	return str(dialogue["nodes"][str(dialogue["start"])]["text"])


## Stands the hero before the named villager and starts talking.
func _talk(area: AreaController, node_name: String) -> void:
	Steps.stand_before(area, node_name)
	assert_bool(area.interact()).override_failure_message("talk to %s" % node_name).is_true()


## Picks the answer that reads `text` in the open conversation.
func _say(area: AreaController, text: String) -> void:
	var box: DialogueBox = area.hud.dialogue
	var index: int = box.shown_options().find(text)
	assert_int(index).override_failure_message("no answer '%s' among %s" % [text, box.shown_options()]).is_greater_equal(0)
	box.move_cursor(index - box.selected)
	box.confirm()


## Ends the open conversation by its last answer, as often as it takes.
func _end(area: AreaController) -> void:
	var box: DialogueBox = area.hud.dialogue
	for step: int in 6:
		if not area.is_talking():
			break
		var count: int = box.shown_options().size()
		if count > 0:
			box.move_cursor(count - 1 - box.selected)
		box.confirm()
	assert_bool(area.is_talking()).override_failure_message("the conversation ends").is_false()
	if area.hud.gift_menu.is_open():
		area.hud.gift_menu.close()


## What lies at the hero's feet in `area`: each item and how many.
func _lying(area: AreaController) -> Dictionary:
	var out: Dictionary = {}
	for child: Node in area.interactables.get_children():
		if child is LeftItem and not (child as LeftItem).taken():
			out[(child as LeftItem).item_id] = (child as LeftItem).count
	return out


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area
