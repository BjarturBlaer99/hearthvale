extends GdUnitTestSuite
## What friendship opens (P4d): at two marks four villagers ask a favour (a quest that can be
## taken, put off and finished for its reward) and three teach a recipe (which the hearth then
## lists and cooks); at four marks each of the seven gives a present, once. All of it is data:
## openings on the `friendship` condition in each villager's conversation, quests in the
## quest format, recipes marked `taught`. The quest log scrolls, and the ending counts the
## days, the crops and the friends.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")
const DataRegistryScript: GDScript = preload("res://autoload/data_registry.gd")
const FakeState: GDScript = preload("res://tests/support/fake_state.gd")

const VILLAGE: String = "res://world/areas/village/village.tscn"
const HOME: String = "res://world/areas/home/home.tscn"
const SHOP: String = "res://world/areas/shop/shop.tscn"
const ELDER_HOUSE: String = "res://world/areas/elder_house/elder_house.tscn"
const WEAVER: String = "res://world/areas/weaver_house/weaver_house.tscn"
const FIELDS: String = "res://world/areas/north_fields/north_fields.tscn"
const ENDING: String = "res://ui/ending_screen.tscn"
const TEST_SLOT: int = 973

## The plan's table of favours: where the villager is, their node, their id, the quest and its
## first stage, what it wants and how many, the three answers, and what finishing it gives.
const FAVOURS: Array = [
	[VILLAGE, "Pip", &"pip", &"pie_for_pip", &"bake", &"pumpkin_pie", 1, "I'll bake you one.", "Here's your pie.", "About that pie...", {&"coin": 15}],
	[VILLAGE, "GuardRolf", &"guard_rolf", &"rations_for_the_watch", &"bring", &"bread", 3, "I'll bring them.", "Three loaves, as promised.", "About those rations...", {&"arrow": 10, &"coin": 20}],
	[VILLAGE, "FarmerOda", &"farmer_oda", &"seed_stock", &"bring", &"wheat", 5, "I'll bring five.", "Five sheaves of wheat.", "About that wheat...", {&"pumpkin_seeds": 3}],
	[ELDER_HOUSE, "Bram", &"elder_bram", &"elders_supper", &"cook", &"vegetable_stew", 1, "I'll cook you one.", "Your supper, Elder.", "About that stew...", {&"coin": 30}],
]
## The plan's table of recipes: where the teacher is, their node, their id, the recipe, the
## dish's name, its makings and what it gives (energy, half hearts).
const LESSONS: Array = [
	[WEAVER, "Wenna", &"wenna", &"berry_jam", "Berry Jam", [[&"wild_berries", 3]], 30.0, 0],
	[SHOP, "Tilda", &"tilda", &"carrot_cake", "Carrot Cake", [[&"carrot", 2], [&"wheat", 1]], 50.0, 1],
	[FIELDS, "ShepherdEdda", &"shepherd_edda", &"shepherds_pie", "Shepherd's Pie", [[&"potato", 1], [&"turnip", 1], [&"mushroom", 1]], 70.0, 2],
]
## Each villager's present at four marks: where they are, their node, their id, what and how many.
const PRESENTS: Array = [
	[ELDER_HOUSE, "Bram", &"elder_bram", &"coin", 40],
	[WEAVER, "Wenna", &"wenna", &"coin", 25],
	[SHOP, "Tilda", &"tilda", &"potato_seeds", 3],
	[VILLAGE, "FarmerOda", &"farmer_oda", &"carrot_seeds", 3],
	[VILLAGE, "Pip", &"pip", &"coin", 10],
	[VILLAGE, "GuardRolf", &"guard_rolf", &"coin", 30],
	[FIELDS, "ShepherdEdda", &"shepherd_edda", &"wheat_seeds", 4],
]

var _area: Node


func before_test() -> void:
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


func test_at_two_marks_four_villagers_ask_a_favour_that_can_be_put_off_taken_and_finished() -> void:
	for favour: Array in FAVOURS:
		_fresh()
		var who: StringName = favour[2]
		var quest: StringName = favour[3]
		var start_text: String = str(DataRegistry.get_dialogue(StringName(str(DataRegistry.get_villager(who)["dialogue"])))["nodes"][str(DataRegistry.get_dialogue(StringName(str(DataRegistry.get_villager(who)["dialogue"])))["start"])]["text"])
		# One mark: nothing is asked. (Six points, and the day's first talk makes seven.)
		GameState.add_friendship(who, 6)
		var area: AreaController = _load(favour[0])
		var box: DialogueBox = area.hud.dialogue
		_talk(area, favour[1])
		assert_str(box.shown_text()).override_failure_message("%s at one mark" % who).is_equal(start_text)
		assert_bool(Array(box.shown_options()).has(favour[7])).is_false()
		_end(area)
		# Two marks: the favour is asked, and can be put off.
		GameState.add_friendship(who, 1)
		_talk(area, favour[1])
		assert_array(Array(box.shown_options())).override_failure_message("%s asks at two marks" % who).is_equal([favour[7], "Not just now."])
		_say(area, "Not just now.")
		assert_str(box.shown_text()).override_failure_message("put off, they talk as they always do").is_equal(start_text)
		assert_that(Quests.runner.status(quest)).is_equal(QuestState.NOT_STARTED)
		_end(area)
		# Asked again at the next talk, and taken.
		_talk(area, favour[1])
		_say(area, favour[7])
		assert_that(Quests.runner.status(quest)).is_equal(QuestState.ACTIVE)
		assert_that(Quests.runner.stage(quest)).is_equal(favour[4])
		assert_array(Quests.runner.objectives(quest).map(func(objective: Dictionary) -> bool: return objective["done"])).is_equal([false, false])
		_end(area)
		# Without what was asked for there is only the reminder.
		_talk(area, favour[1])
		assert_str(box.shown_text()).override_failure_message("no favour asked twice").is_equal(start_text)
		assert_bool(Array(box.shown_options()).has(favour[9])).is_true()
		assert_bool(Array(box.shown_options()).has(favour[8])).override_failure_message("nothing to hand over yet").is_false()
		_say(area, favour[9])
		_end(area)
		# With it, it is handed over, and the reward is the plan's.
		GameState.add_item(favour[5], favour[6])
		assert_array(Quests.runner.objectives(quest).map(func(objective: Dictionary) -> bool: return objective["done"])).is_equal([true, false])
		_talk(area, favour[1])
		_say(area, favour[8])
		assert_int(GameState.item_count(favour[5])).override_failure_message("%s took what was asked for" % who).is_equal(0)
		assert_that(Quests.runner.status(quest)).is_equal(QuestState.COMPLETE)
		var rewards: Dictionary = favour[10]
		for item: StringName in rewards:
			assert_int(GameState.item_count(item)).override_failure_message("%s gives %d %s" % [who, rewards[item], item]).is_equal(rewards[item])
		_end(area)
		# Done with: neither the favour nor its answers come again.
		_talk(area, favour[1])
		assert_str(box.shown_text()).is_equal(start_text)
		assert_bool(Array(box.shown_options()).has(favour[8]) or Array(box.shown_options()).has(favour[9]) or Array(box.shown_options()).has(favour[7])).is_false()
		_end(area)


func test_pip_tells_his_secret_and_bram_more_of_aldrics_tale() -> void:
	GameState.add_friendship(&"pip", 8)
	GameState.set_quest_stage(&"pie_for_pip", &"bake")
	GameState.add_item(&"pumpkin_pie")
	var village: AreaController = _load(VILLAGE)
	_talk(village, "Pip")
	_say(village, "Here's your pie.")
	assert_str(village.hud.dialogue.shown_text()).contains("shrine").contains("Old Wood").contains("west wall").contains("bang")
	assert_str(Quests.runner.journal(&"pie_for_pip")).override_failure_message("the journal keeps the secret").contains("west wall").contains("bomb")
	_end(village)
	GameState.add_friendship(&"elder_bram", 8)
	GameState.set_quest_stage(&"elders_supper", &"cook")
	GameState.add_item(&"vegetable_stew")
	var house: AreaController = _load(ELDER_HOUSE)
	_talk(house, "Bram")
	_say(house, "Your supper, Elder.")
	assert_str(house.hud.dialogue.shown_text()).contains("Aldric").contains("farmed")
	_say(house, "Go on.")
	assert_str(house.hud.dialogue.shown_text()).contains("cottage").contains("keeper")
	_end(house)
	assert_int(GameState.item_count(&"coin")).override_failure_message("fifteen from Pip and thirty from Bram").is_equal(45)


func test_at_two_marks_three_villagers_teach_a_recipe_the_hearth_then_cooks() -> void:
	for lesson: Array in LESSONS:
		_fresh()
		var who: StringName = lesson[2]
		var recipe: StringName = lesson[3]
		assert_bool(GameState.knows_recipe(recipe)).override_failure_message("%s is not known from the start" % recipe).is_false()
		assert_bool(GameState.known_recipes().any(func(known: Dictionary) -> bool: return known["id"] == String(recipe))).is_false()
		GameState.add_friendship(who, 8)
		var area: AreaController = _load(lesson[0])
		_talk(area, lesson[1])
		assert_bool(GameState.knows_recipe(recipe)).override_failure_message("%s teaches it at two marks" % who).is_true()
		assert_str(area.hud.notice_text()).is_equal("New recipe: %s." % lesson[4])
		assert_array(Array(area.hud.dialogue.shown_options())).is_equal(["Thank you."])
		_end(area)
		# Taught once: the next talk is their own.
		_talk(area, lesson[1])
		assert_bool(Array(area.hud.dialogue.shown_options()).has("Thank you.")).is_false()
		_end(area)
		# The hearth lists it now, and cooks it from its makings.
		var names: PackedStringArray = []
		for need: Array in lesson[5]:
			GameState.add_item(need[0], need[1])
			names.append("%d %s" % [need[1], DataRegistry.get_item(need[0])["name"]])
		var home: AreaController = _load(HOME)
		var hearth: Hearth = home.interactables.get_node(^"Hearth")
		home.player.motor.place(hearth.cell() + Vector2i.DOWN)
		home.player.face(Vector2.UP)
		assert_bool(home.interact()).is_true()
		var dish: String = "%s (%s)" % [lesson[4], ", ".join(names)]
		assert_bool(Array(home.hud.dialogue.shown_options()).has(dish)).override_failure_message("the hearth lists '%s' among %s" % [dish, home.hud.dialogue.shown_options()]).is_true()
		_say(home, dish)
		assert_int(GameState.item_count(recipe)).override_failure_message("cooked").is_equal(1)
		for need: Array in lesson[5]:
			assert_int(GameState.item_count(need[0])).is_equal(0)
		_end(home)
		var cooked: Dictionary = DataRegistry.get_item(recipe)
		assert_float(Food.energy_of(cooked)).is_equal(lesson[6])
		assert_int(Food.halves_of(cooked)).is_equal(lesson[7])
		assert_bool(ItemIcons.FRAMES.has(ItemIcons.name_for(recipe)) and ItemIcons.name_for(recipe) != &"gem").override_failure_message("%s has a picture of its own" % recipe).is_true()


func test_before_he_is_taught_the_hearth_lists_only_what_he_knew() -> void:
	var home: AreaController = _load(HOME)
	var hearth: Hearth = home.interactables.get_node(^"Hearth")
	home.player.motor.place(hearth.cell() + Vector2i.DOWN)
	home.player.face(Vector2.UP)
	home.interact()
	assert_int(home.hud.dialogue.shown_options().size()).override_failure_message("seven dishes and the way out").is_equal(8)
	for taught: String in ["Berry Jam", "Carrot Cake", "Shepherd's Pie"]:
		assert_bool(Array(home.hud.dialogue.shown_options()).any(func(answer: String) -> bool: return answer.begins_with(taught))).override_failure_message(taught).is_false()
	_end(home)
	# Learning is a flag, so it goes through a save, and learning twice is nothing.
	assert_bool(GameState.learn_recipe(&"berry_jam")).is_true()
	assert_bool(GameState.learn_recipe(&"berry_jam")).override_failure_message("known already").is_false()
	assert_bool(GameState.learn_recipe(&"bread")).override_failure_message("known from the start").is_false()
	assert_bool(GameState.learn_recipe(&"no_such_dish")).is_false()
	var saved: Variant = JSON.parse_string(JSON.stringify(GameState.to_dict()))
	GameState.clear()
	GameState.from_dict(saved)
	assert_bool(GameState.knows_recipe(&"berry_jam")).is_true()
	assert_bool(GameState.knows_recipe(&"carrot_cake")).is_false()
	assert_int(GameState.known_recipes().size()).override_failure_message("the seven he knew and the one he learned").is_equal(8)


func test_at_four_marks_each_villager_gives_a_present_once() -> void:
	for present: Array in PRESENTS:
		_fresh()
		var who: StringName = present[2]
		GameState.add_friendship(who, 12)
		var area: AreaController = _load(present[0])
		_talk(area, present[1])
		assert_int(GameState.item_count(present[3])).override_failure_message("%s at three marks gives nothing yet" % who).is_equal(0)
		_end(area)
		GameState.add_friendship(who, 3)
		assert_int(GameState.friend_marks(who)).is_equal(4)
		_talk(area, present[1])
		assert_int(GameState.item_count(present[3])).override_failure_message("%s's present" % who).is_equal(present[4])
		assert_bool(GameState.get_flag(StringName("present/%s" % who)) == true).is_true()
		assert_int(area.hud.dialogue.shown_options().size()).override_failure_message("thanks, and nothing else to say to it").is_equal(1)
		_end(area)
		# Once: the next talk gives nothing more.
		_talk(area, present[1])
		_end(area)
		_talk(area, present[1])
		_end(area)
		assert_int(GameState.item_count(present[3])).override_failure_message("%s's present is given once" % who).is_equal(present[4])


func test_the_answer_that_gives_is_still_there_when_a_favour_is_asked() -> void:
	GameState.add_friendship(&"pip", 8)
	GameState.add_item(&"bread")
	var village: AreaController = _load(VILLAGE)
	_talk(village, "Pip")
	assert_array(Array(village.hud.dialogue.shown_options())).is_equal(["I'll bake you one.", "Not just now.", Friendship.GIVE_WORDS])
	_say(village, Friendship.GIVE_WORDS)
	assert_bool(village.hud.gift_menu.is_open()).is_true()
	village.hud.gift_menu.close()
	assert_that(Quests.runner.status(&"pie_for_pip")).override_failure_message("giving is not taking the favour").is_equal(QuestState.NOT_STARTED)


func test_elder_brams_welcome_still_comes_first() -> void:
	GameState.set_flag(StoryGates.FIRST_CROP, false)
	GameState.add_friendship(&"elder_bram", 16)
	var house: AreaController = _load(ELDER_HOUSE)
	_talk(house, "Bram")
	assert_str(house.hud.dialogue.shown_text()).override_failure_message("a newcomer is welcomed before anything else").contains("Welcome to Hearthvale")
	assert_int(GameState.item_count(&"coin")).is_equal(0)
	_end(house)
	GameState.set_flag(StoryGates.FIRST_CROP, true)
	_talk(house, "Bram")
	assert_int(GameState.item_count(&"coin")).override_failure_message("then his present").is_equal(40)
	_end(house)
	_talk(house, "Bram")
	assert_array(Array(house.hud.dialogue.shown_options())).override_failure_message("then his favour").is_equal(["I'll cook you one.", "Not just now."])
	_say(house, "Not just now.")
	assert_bool(Array(house.hud.dialogue.shown_options()).has("What lights?")).override_failure_message("and the story is still to hand").is_true()
	_end(house)


func test_the_condition_reads_the_games_own_friendships() -> void:
	var two_marks: Dictionary = {"type": "friendship", "villager": "pip", "marks": 2}
	assert_bool(ConditionEvaluator.for_state(GameState).is_met(two_marks)).is_false()
	GameState.add_friendship(&"pip", 7)
	assert_bool(ConditionEvaluator.for_state(GameState).is_met(two_marks)).override_failure_message("seven points are one mark").is_false()
	GameState.add_friendship(&"pip", 1)
	assert_bool(ConditionEvaluator.for_state(GameState).is_met(two_marks)).is_true()
	# A stand-in state with no rules of friendship meets no such condition.
	var stand_in: RefCounted = FakeState.new()
	assert_bool(ConditionEvaluator.for_state(stand_in).is_met(two_marks)).is_false()
	assert_bool(ConditionEvaluator.for_state(stand_in).is_met({"type": "flag", "flag": "never", "value": false})).override_failure_message("the rest works as ever").is_true()


func test_bad_data_for_what_friendship_opens_is_refused_on_load() -> void:
	var registry: Node = auto_free(DataRegistryScript.new())
	var errors: String = "\n".join(registry.load_all("res://tests/fixtures/bad_opens"))
	assert_str(errors).contains("rules 'friendship': 'friend_marks' must be a whole number from 1 to 'marks': the marks that make a friend.")
	assert_str(errors).contains("recipe 'bun': 'taught' must be true or false.")
	assert_str(errors).contains("refers to unknown villager id 'miller'.")
	assert_str(errors).contains("'marks' must be a whole number from 1 to 5, not '6")
	assert_str(errors).contains("'marks' must be a whole number from 1 to 5, not 'many'.")
	assert_str(errors).contains("condition 'friendship' is missing 'marks'.")
	assert_str(errors).contains("the recipe 'loaf' is known from the start: there is nothing to teach")
	assert_str(errors).contains("refers to unknown recipe id 'cake'.")
	assert_str(errors).contains("effect 'teach_recipe' is missing 'recipe'.")
	assert_bool(errors.contains("the recipe 'roll'")).override_failure_message("a recipe that is taught can be taught").is_false()
	assert_array(Array(DataRegistry.errors)).override_failure_message("the game's own data loads clean").is_empty()


func test_the_quest_log_shows_five_quests_at_a_time_and_scrolls() -> void:
	for quest: StringName in Quests.runner.quest_ids():
		Quests.runner.start(quest)
	var village: AreaController = _load(VILLAGE)
	village.open_pause_menu()
	village.hud.pause_menu.choose(PauseMenu.QUESTS)
	var quest_log: QuestLog = village.hud.pause_menu.quest_log
	assert_int(quest_log.all_lines().size()).override_failure_message("eight quests and Back").is_equal(9)
	assert_array(Array(quest_log.shown_lines())).is_equal([
		"> A Pie for Pip", "  A Place of Your Own", "  Eggs for Tilda", "  Rations for the Watch", "  Seed Stock",
	])
	assert_str(quest_log.corner_text()).is_equal("  1/9 v")
	quest_log.move_cursor(4)
	assert_str(quest_log.shown_lines()[4]).override_failure_message("still in view").is_equal("> Seed Stock")
	quest_log.move_cursor(1)
	assert_array(Array(quest_log.shown_lines())).override_failure_message("the list moves up a line").is_equal([
		"  A Place of Your Own", "  Eggs for Tilda", "  Rations for the Watch", "  Seed Stock", "> Slimes in the South Field",
	])
	assert_str(quest_log.corner_text()).is_equal("^ 6/9 v")
	assert_str(quest_log.shown_detail()).contains("slimes")
	quest_log.move_cursor(3)
	assert_str(quest_log.shown_lines()[4]).is_equal("> Back")
	assert_str(quest_log.corner_text()).is_equal("^ 9/9  ")
	quest_log.move_cursor(1)
	assert_str(quest_log.shown_lines()[0]).override_failure_message("round to the top").is_equal("> A Pie for Pip")
	quest_log.close()
	village.hud.pause_menu.resume()


func test_the_ending_counts_the_days_the_crops_and_the_friends() -> void:
	for day: int in 6:
		GameState.start_next_day()
	GameState.add_tally(GameState.CROPS_PICKED, 31)
	for friend: Array in [[&"pip", 12], [&"wenna", 20], [&"elder_bram", 13], [&"tilda", 11], [&"guard_rolf", 4]]:
		GameState.add_friendship(friend[0], friend[1])
	assert_array(Array(EndingScreen.summary_lines()).slice(3)).is_equal(["Days   7", "Crops grown   31", "Friends   3 of 7"])
	var screen: EndingScreen = (load(ENDING) as PackedScene).instantiate()
	get_tree().root.add_child(screen)
	_area = screen
	screen.travel = func(_path: String) -> void: pass
	assert_int(screen.shown_stats().split("\n").size()).override_failure_message("six lines").is_equal(6)
	assert_str(screen.shown_stats()).contains("Days   7").contains("Crops grown   31").contains("Friends   3 of 7")
	var stats: Label = screen.get_node(^"Stats")
	var menu: Control = screen.get_node(^"Menu")
	assert_float(stats.position.y + stats.size.y).override_failure_message("the six lines end above the menu's box").is_less_equal(menu.position.y)


## A game begun, at noon, with the first crop in (Elder Bram speaks of more than his welcome).
func _fresh() -> void:
	if is_instance_valid(_area):
		_area.free()
	_area = null
	GameState.clear()
	GameState.new_game()
	GameState.set_time(float(GameState.day_clock().in_day("12:00")))
	GameState.set_flag(StoryGates.FIRST_CROP, true)
	Quests.refresh()


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
			return
		var count: int = box.shown_options().size()
		if count > 0:
			box.move_cursor(count - 1 - box.selected)
		box.confirm()
	assert_bool(area.is_talking()).override_failure_message("the conversation ends").is_false()


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area
