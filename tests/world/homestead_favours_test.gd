extends GdUnitTestSuite
## The Homestead's two favours (phase 5, step 5a), both at three marks: Tilda asks for six eggs
## ("Market Day"; 50 coins and 2 Carrot Cakes) and Farmer Oda for a coop standing on the farm
## ("A Roof for the Flock"; 60 coins and 5 hay). Tilda still teaches her carrot cake at two
## marks, and Oda still asks for his seed wheat at two: each of those comes first. Both favours
## are data (a quest and an opening and four nodes in the conversation); the coop's is asked of
## the flag `built/coop`, which GameState keeps true while the coop stands. The rewards are
## given, so a full pack loses none of them.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const SHOP: String = "res://world/areas/shop/shop.tscn"
const VILLAGE: String = "res://world/areas/village/village.tscn"
const OLD_SAVE: String = "res://tests/fixtures/saves/v6_a_yard_on_the_farm.json"
const TEST_SLOT: int = 953
## Open ground east of the farmhouse, where a coop fits (tests/world/rooms_test.gd).
const COOP_AT: Vector2i = Vector2i(32, 10)

const TILDA_ASKS: Array = ["I'll bring them.", "Not just now."]
const ODA_ASKS: Array = ["I'll build one.", "Not just now."]

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


# --- Tilda: "Market Day" ----------------------------------------------------------------

func test_at_three_marks_tilda_asks_for_six_eggs_and_the_favour_can_be_put_off_taken_and_finished() -> void:
	var start_text: String = _start_text(&"tilda")
	GameState.learn_recipe(&"carrot_cake")
	# Two marks (ten points, and the day's first talk makes eleven): nothing is asked, though he
	# carries the eggs.
	GameState.add_friendship(&"tilda", 10)
	GameState.add_item(&"egg", 6)
	var shop: AreaController = _load(SHOP)
	var box: DialogueBox = shop.hud.dialogue
	_talk(shop, "Tilda")
	assert_int(GameState.friend_marks(&"tilda")).is_equal(2)
	assert_str(box.shown_text()).override_failure_message("Tilda at two marks").is_equal(start_text)
	assert_bool(_offers(box, "Six eggs, Tilda.") or _offers(box, "About those eggs...")).override_failure_message("nothing asked yet").is_false()
	_end(shop)
	GameState.add_item(&"egg", -6)
	# Three marks: the favour is asked, and can be put off.
	GameState.add_friendship(&"tilda", 1)
	assert_int(GameState.friend_marks(&"tilda")).is_equal(3)
	_talk(shop, "Tilda")
	assert_str(box.shown_text()).contains("six")
	assert_array(Array(box.shown_options())).is_equal(TILDA_ASKS)
	_say(shop, "Not just now.")
	assert_str(box.shown_text()).override_failure_message("put off, she talks as she always does").is_equal(start_text)
	assert_that(Quests.runner.status(&"market_day")).is_equal(QuestState.NOT_STARTED)
	_end(shop)
	# Asked again, and taken.
	_talk(shop, "Tilda")
	_say(shop, "I'll bring them.")
	assert_that(Quests.runner.status(&"market_day")).is_equal(QuestState.ACTIVE)
	assert_that(Quests.runner.stage(&"market_day")).is_equal(&"bring")
	assert_str(Quests.runner.title(&"market_day")).is_equal("Market Day")
	assert_array(Array(shop.hud.notice_lines())).contains(["New quest: Market Day"])
	assert_array(_done(&"market_day")).is_equal([false, false])
	_end(shop)
	# Five eggs: only the reminder.
	GameState.add_item(&"egg", 5)
	_talk(shop, "Tilda")
	assert_str(box.shown_text()).override_failure_message("no favour asked twice").is_equal(start_text)
	assert_bool(_offers(box, "About those eggs...")).is_true()
	assert_bool(_offers(box, "Six eggs, Tilda.")).override_failure_message("five eggs are not six").is_false()
	_say(shop, "About those eggs...")
	assert_str(box.shown_text()).override_failure_message("the reminder says where eggs come from").contains("Oda")
	_end(shop)
	# Seven: handed over, six taken and one left, and the plan's reward.
	GameState.add_item(&"egg", 2)
	assert_array(_done(&"market_day")).is_equal([true, false])
	_talk(shop, "Tilda")
	assert_str(box.shown_options()[0]).override_failure_message("handing them over is the first answer").is_equal("Six eggs, Tilda.")
	_say(shop, "Six eggs, Tilda.")
	assert_int(GameState.item_count(&"egg")).is_equal(1)
	assert_that(Quests.runner.status(&"market_day")).is_equal(QuestState.COMPLETE)
	assert_array(Array(shop.hud.notice_lines())).contains(["Quest complete: Market Day"])
	assert_int(GameState.item_count(&"coin")).is_equal(50)
	assert_int(GameState.item_count(&"carrot_cake")).is_equal(2)
	_end(shop)
	# Done with: never asked again, though he carries six more.
	GameState.add_item(&"egg", 6)
	_talk(shop, "Tilda")
	assert_str(box.shown_text()).is_equal(start_text)
	assert_bool(_offers(box, "Six eggs, Tilda.") or _offers(box, "About those eggs...") or _offers(box, "I'll bring them.")).is_false()
	_end(shop)
	assert_int(GameState.item_count(&"egg")).is_equal(7)


func test_tilda_teaches_her_carrot_cake_first_then_asks() -> void:
	# Three marks at once, nothing taught yet: the lesson, then the favour.
	GameState.add_friendship(&"tilda", 12)
	var shop: AreaController = _load(SHOP)
	_talk(shop, "Tilda")
	assert_bool(GameState.knows_recipe(&"carrot_cake")).override_failure_message("the carrot cake first").is_true()
	assert_array(Array(shop.hud.dialogue.shown_options())).is_equal(["Thank you."])
	assert_that(Quests.runner.status(&"market_day")).is_equal(QuestState.NOT_STARTED)
	_end(shop)
	_talk(shop, "Tilda")
	assert_array(Array(shop.hud.dialogue.shown_options())).override_failure_message("then she asks").is_equal(TILDA_ASKS)
	_end(shop)
	assert_that(Quests.runner.status(&"market_day")).is_equal(QuestState.NOT_STARTED)


func test_at_four_marks_tildas_present_comes_before_her_favour() -> void:
	GameState.learn_recipe(&"carrot_cake")
	GameState.add_friendship(&"tilda", 16)
	var shop: AreaController = _load(SHOP)
	_talk(shop, "Tilda")
	assert_bool(GameState.get_flag(&"present/tilda")).is_true()
	_end(shop)
	_talk(shop, "Tilda")
	assert_array(Array(shop.hud.dialogue.shown_options())).is_equal(TILDA_ASKS)
	_end(shop)


# --- Oda: "A Roof for the Flock" --------------------------------------------------------

func test_at_three_marks_oda_asks_for_a_coop_that_is_finished_the_morning_it_stands() -> void:
	var start_text: String = _start_text(&"farmer_oda")
	# His wheat favour of two marks is taken already.
	GameState.set_quest_stage(&"seed_stock", &"bring")
	GameState.add_friendship(&"farmer_oda", 10)
	var village: AreaController = _load(VILLAGE)
	var box: DialogueBox = village.hud.dialogue
	_talk(village, "FarmerOda")
	assert_int(GameState.friend_marks(&"farmer_oda")).is_equal(2)
	assert_str(box.shown_text()).is_equal(start_text)
	assert_bool(_offers(box, "About that coop...") or _offers(box, "My coop is built.")).is_false()
	_end(village)
	GameState.add_friendship(&"farmer_oda", 1)
	_talk(village, "FarmerOda")
	assert_str(box.shown_text()).contains("coop")
	assert_array(Array(box.shown_options())).is_equal(ODA_ASKS)
	_say(village, "Not just now.")
	assert_str(box.shown_text()).is_equal(start_text)
	assert_that(Quests.runner.status(&"a_roof_for_the_flock")).is_equal(QuestState.NOT_STARTED)
	_end(village)
	_talk(village, "FarmerOda")
	_say(village, "I'll build one.")
	assert_that(Quests.runner.stage(&"a_roof_for_the_flock")).is_equal(&"build")
	assert_str(Quests.runner.title(&"a_roof_for_the_flock")).is_equal("A Roof for the Flock")
	assert_array(Array(village.hud.notice_lines())).contains(["New quest: A Roof for the Flock"])
	assert_array(_done(&"a_roof_for_the_flock")).is_equal([false, false])
	assert_str(Quests.runner.journal(&"a_roof_for_the_flock")).contains("Build tab")
	_end(village)
	# The kit set down is a site today: only the reminder.
	GameState.add_item(&"coop_kit")
	assert_bool(GameState.set_down_kit(&"homestead", COOP_AT, &"coop_kit")).is_true()
	assert_bool(GameState.get_flag(&"built/coop")).override_failure_message("a site is not a coop").is_false()
	_talk(village, "FarmerOda")
	assert_bool(_offers(box, "My coop is built.")).is_false()
	_say(village, "About that coop...")
	assert_str(box.shown_text()).contains("Build tab")
	_end(village)
	assert_array(_done(&"a_roof_for_the_flock")).is_equal([false, false])
	# The next morning it stands: the first objective is done, and he may say so.
	GameState.start_next_day()
	GameState.set_time(float(GameState.day_clock().in_day("12:00")))
	assert_bool(GameState.is_built(&"coop")).is_true()
	assert_bool(GameState.get_flag(&"built/coop")).is_true()
	assert_array(_done(&"a_roof_for_the_flock")).is_equal([true, false])
	assert_that(Quests.runner.status(&"a_roof_for_the_flock")).override_failure_message("not until Oda is told").is_equal(QuestState.ACTIVE)
	_talk(village, "FarmerOda")
	assert_str(box.shown_options()[0]).is_equal("My coop is built.")
	assert_bool(_offers(box, "About that coop...")).is_true()
	_say(village, "My coop is built.")
	assert_that(Quests.runner.status(&"a_roof_for_the_flock")).is_equal(QuestState.COMPLETE)
	assert_array(Array(village.hud.notice_lines())).contains(["Quest complete: A Roof for the Flock"])
	assert_int(GameState.item_count(&"coin")).is_equal(60)
	assert_int(GameState.item_count(&"hay")).is_equal(5)
	_end(village)
	_talk(village, "FarmerOda")
	assert_str(box.shown_text()).is_equal(start_text)
	assert_bool(_offers(box, "My coop is built.") or _offers(box, "About that coop...") or _offers(box, "I'll build one.")).is_false()
	_end(village)
	assert_bool(GameState.is_built(&"coop")).override_failure_message("Oda takes nothing").is_true()


func test_a_coop_built_before_the_favour_is_asked_can_be_told_of_at_once() -> void:
	GameState.set_quest_stage(&"seed_stock", &"bring")
	_stand_coop()
	GameState.add_friendship(&"farmer_oda", 12)
	var village: AreaController = _load(VILLAGE)
	_talk(village, "FarmerOda")
	_say(village, "I'll build one.")
	assert_array(_done(&"a_roof_for_the_flock")).is_equal([true, false])
	_end(village)
	_talk(village, "FarmerOda")
	_say(village, "My coop is built.")
	assert_that(Quests.runner.status(&"a_roof_for_the_flock")).is_equal(QuestState.COMPLETE)
	_end(village)


func test_odas_wheat_of_two_marks_comes_before_his_coop() -> void:
	GameState.add_friendship(&"farmer_oda", 12)
	var village: AreaController = _load(VILLAGE)
	_talk(village, "FarmerOda")
	assert_array(Array(village.hud.dialogue.shown_options())).override_failure_message("the wheat first").is_equal(["I'll bring five.", "Not just now."])
	_say(village, "I'll bring five.")
	_end(village)
	_talk(village, "FarmerOda")
	assert_array(Array(village.hud.dialogue.shown_options())).override_failure_message("then the coop").is_equal(ODA_ASKS)
	_end(village)


func test_a_coop_pulled_down_is_no_coop_to_tell_of() -> void:
	GameState.set_quest_stage(&"a_roof_for_the_flock", &"build")
	_stand_coop()
	assert_array(_done(&"a_roof_for_the_flock")).is_equal([true, false])
	assert_str(GameState.why_not_demolish(&"coop")).is_empty()
	assert_array(GameState.demolish(&"homestead", &"coop")).is_not_empty()
	assert_bool(GameState.is_built(&"coop")).is_false()
	assert_bool(GameState.flags.has(&"built/coop")).override_failure_message("the flag goes with the coop").is_false()
	assert_array(_done(&"a_roof_for_the_flock")).is_equal([false, false])
	GameState.add_friendship(&"farmer_oda", 12)
	GameState.set_quest_stage(&"seed_stock", &"bring")
	var village: AreaController = _load(VILLAGE)
	_talk(village, "FarmerOda")
	assert_bool(_offers(village.hud.dialogue, "My coop is built.")).is_false()
	_end(village)


# --- The flag built/<id> ----------------------------------------------------------------

func test_the_built_flag_follows_each_building_and_a_save() -> void:
	for id: StringName in DataRegistry.ids(&"buildings"):
		assert_bool(GameState.flags.has(GameState.built_flag(id))).override_failure_message("a new game has no %s" % id).is_false()
	assert_str(String(GameState.built_flag(&"coop"))).is_equal("built/coop")
	GameState.add_item(&"well_kit")
	assert_bool(GameState.set_down_kit(&"homestead", COOP_AT, &"well_kit")).is_true()
	assert_bool(GameState.get_flag(&"built/well")).is_false()
	GameState.start_next_day()
	assert_bool(GameState.get_flag(&"built/well")).is_true()
	assert_bool(GameState.get_flag(&"built/coop")).is_false()
	# Moved, it still stands.
	assert_bool(GameState.move_building(&"homestead", &"well", COOP_AT + Vector2i(1, 0))).is_true()
	assert_bool(GameState.get_flag(&"built/well")).is_true()
	# A site is never built, whatever else changes: a coop's kit set down today, and a silo
	# that stood pulled down beside it.
	GameState.add_item(&"silo_kit")
	assert_bool(GameState.set_down_kit(&"homestead", Vector2i(35, 11), &"silo_kit")).is_true()
	GameState.start_next_day()
	assert_bool(GameState.get_flag(&"built/silo")).is_true()
	GameState.add_item(&"coop_kit")
	assert_bool(GameState.set_down_kit(&"homestead", Vector2i(29, 14), &"coop_kit")).is_true()
	assert_array(GameState.demolish(&"homestead", &"silo")).is_not_empty()
	assert_bool(GameState.flags.has(&"built/silo")).is_false()
	assert_bool(GameState.flags.has(&"built/coop")).override_failure_message("the coop is a site today").is_false()
	assert_bool(GameState.get_flag(&"built/well")).is_true()
	# A save keeps it; a save whose flag was lost (from before phase 5) gets it back; a flag with
	# no building behind it is dropped.
	var saved: Dictionary = GameState.to_dict()
	assert_bool(saved["flags"].get("built/well", false)).is_true()
	(saved["flags"] as Dictionary).erase("built/well")
	(saved["flag_days"] as Dictionary).erase("built/well")
	saved["flags"]["built/barn"] = true
	GameState.from_dict(saved)
	assert_bool(GameState.get_flag(&"built/well")).is_true()
	assert_bool(GameState.flags.has(&"built/barn")).is_false()
	# The day it came true is the morning the well stood: day 2, its kit set down on day 1.
	assert_int(GameState.day).is_equal(3)
	assert_int(int(GameState.flag_days[&"built/well"])).is_equal(2)


func test_saves_from_before_phase_5_load_with_neither_favour_begun() -> void:
	DirAccess.make_dir_recursive_absolute(SaveSystem.SAVE_DIR)
	SaveSystem._write_text(SaveSystem.slot_path(TEST_SLOT), FileAccess.get_file_as_string(OLD_SAVE))
	assert_int(SaveSystem.load_game()).is_equal(OK)
	for quest: StringName in [&"market_day", &"a_roof_for_the_flock"]:
		assert_that(Quests.runner.status(quest)).is_equal(QuestState.NOT_STARTED)
	GameState.set_quest_stage(&"market_day", &"bring")
	GameState.set_quest_stage(&"a_roof_for_the_flock", &"build")
	GameState.set_flag(&"coop_shown_oda", true)
	var coins: int = GameState.item_count(&"coin")
	assert_int(SaveSystem.save_game()).is_equal(OK)
	GameState.new_game()
	assert_int(SaveSystem.load_game()).is_equal(OK)
	assert_that(Quests.runner.status(&"market_day")).is_equal(QuestState.ACTIVE)
	assert_that(Quests.runner.status(&"a_roof_for_the_flock")).is_equal(QuestState.COMPLETE)
	assert_int(GameState.item_count(&"coin")).override_failure_message("not given again on loading").is_equal(coins)


# --- Both ------------------------------------------------------------------------------

func test_a_full_pack_loses_nothing_of_either_reward() -> void:
	# Tilda's cakes: ten are a full stack, so both are laid at his feet.
	GameState.add_item(&"carrot_cake", 10)
	GameState.set_quest_stage(&"market_day", &"bring")
	GameState.add_item(&"egg", 6)
	var shop: AreaController = _load(SHOP)
	_talk(shop, "Tilda")
	_say(shop, "Six eggs, Tilda.")
	_end(shop)
	assert_that(Quests.runner.status(&"market_day")).is_equal(QuestState.COMPLETE)
	assert_int(GameState.item_count(&"coin")).is_equal(50)
	assert_dict(_lying(shop)).is_equal({&"carrot_cake": 2})
	assert_array(LeftItems.owed(GameState.flags)).is_empty()
	# Oda's hay: a stack of 48 takes two, and three are laid down.
	_fresh()
	GameState.add_item(&"hay", 48)
	GameState.set_quest_stage(&"a_roof_for_the_flock", &"build")
	_stand_coop()
	var village: AreaController = _load(VILLAGE)
	_talk(village, "FarmerOda")
	_say(village, "My coop is built.")
	_end(village)
	assert_int(GameState.item_count(&"hay")).is_equal(50)
	assert_int(GameState.item_count(&"coin")).is_equal(60)
	assert_dict(_lying(village)).is_equal({&"hay": 3})


func test_both_are_quests_of_the_favours_shape_and_the_game_has_thirteen() -> void:
	assert_int(DataRegistry.ids(&"quests").size()).is_equal(13)
	var plan: Dictionary = {
		&"market_day": ["Market Day", "tilda", "bring", {&"coin": 50, &"carrot_cake": 2}],
		&"a_roof_for_the_flock": ["A Roof for the Flock", "farmer_oda", "build", {&"coin": 60, &"hay": 5}],
	}
	for quest_id: StringName in plan:
		var quest: Dictionary = DataRegistry.get_quest(quest_id)
		assert_str(str(quest["title"])).is_equal(plan[quest_id][0])
		assert_str(str(quest["giver"])).is_equal(plan[quest_id][1])
		assert_str(str(quest["start_stage"])).is_equal(plan[quest_id][2])
		assert_array((quest["stages"] as Dictionary).keys()).is_equal([plan[quest_id][2], "done"])
		for stage_id: String in quest["stages"]:
			assert_int(str(quest["stages"][stage_id]["journal"]).length()).override_failure_message("'%s' fits the log" % stage_id).is_less_equal(150)
		var given: Dictionary = {}
		for effect: Dictionary in quest["stages"]["done"]["on_enter"]:
			assert_bool(str(effect["type"]) in ["give_item", "complete_quest"]).override_failure_message("'%s' in %s's reward" % [effect["type"], quest_id]).is_true()
			if str(effect["type"]) == "give_item":
				given[StringName(str(effect["item"]))] = int(effect["count"])
		assert_dict(given).is_equal(plan[quest_id][3])
	# Six eggs fit a stack; each giver is a villager to befriend.
	assert_int(int(DataRegistry.get_item(&"egg")["max_stack"])).is_greater_equal(6)
	for who: StringName in [&"tilda", &"farmer_oda"]:
		assert_bool(DataRegistry.has_entry(&"villagers", who)).is_true()
	# Eggs alone finish only the first objective of Tilda's.
	Quests.runner.start(&"market_day")
	GameState.add_item(&"egg", 5)
	assert_array(_done(&"market_day")).is_equal([false, false])
	GameState.add_item(&"egg", 1)
	assert_array(_done(&"market_day")).is_equal([true, false])
	assert_that(Quests.runner.status(&"market_day")).is_equal(QuestState.ACTIVE)
	assert_array(Array(DataRegistry.errors)).is_empty()


# --- Helpers ---------------------------------------------------------------------------

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


## A coop standing on the farm: its kit set down, and the next morning, at noon.
func _stand_coop() -> void:
	GameState.add_item(&"coop_kit")
	assert_bool(GameState.set_down_kit(&"homestead", COOP_AT, &"coop_kit")).is_true()
	GameState.start_next_day()
	GameState.set_time(float(GameState.day_clock().in_day("12:00")))
	assert_bool(GameState.is_built(&"coop")).is_true()


func _done(quest: StringName) -> Array:
	return Quests.runner.objectives(quest).map(func(objective: Dictionary) -> bool: return objective["done"])


func _offers(box: DialogueBox, text: String) -> bool:
	return Array(box.shown_options()).has(text)


func _start_text(who: StringName) -> String:
	var dialogue: Dictionary = DataRegistry.get_dialogue(StringName(str(DataRegistry.get_villager(who)["dialogue"])))
	return str(dialogue["nodes"][str(dialogue["start"])]["text"])


func _talk(area: AreaController, node_name: String) -> void:
	Steps.stand_before(area, node_name)
	assert_bool(area.interact()).override_failure_message("talk to %s" % node_name).is_true()


func _say(area: AreaController, text: String) -> void:
	var box: DialogueBox = area.hud.dialogue
	var index: int = box.shown_options().find(text)
	assert_int(index).override_failure_message("no answer '%s' among %s" % [text, box.shown_options()]).is_greater_equal(0)
	box.move_cursor(index - box.selected)
	box.confirm()


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


func _lying(area: AreaController) -> Dictionary:
	var out: Dictionary = {}
	for child: Node in area.interactables.get_children():
		if child is LeftItem and not (child as LeftItem).taken():
			out[(child as LeftItem).item_id] = (child as LeftItem).count
	return out


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area
