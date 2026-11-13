extends GdUnitTestSuite
## Quests (H13), through the real game: each of the three quests is taken from its giver's
## conversation, advanced by doing the thing, and finished for its reward, with a notice on
## screen at each step. The quest log shows where each stands. Progress survives a save and a
## load without repeating a reward. A quest that exists only as a JSON file runs too.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")
const DataRegistryScript: GDScript = preload("res://autoload/data_registry.gd")

const VILLAGE: String = "res://world/areas/village/village.tscn"
const WEAVER: String = "res://world/areas/weaver_house/weaver_house.tscn"
const SHOP: String = "res://world/areas/shop/shop.tscn"
const FIELDS: String = "res://world/areas/north_fields/north_fields.tscn"
const SOUTH_FIELD: String = "res://world/areas/south_field/south_field.tscn"
const EXTRA_QUEST: String = "res://tests/fixtures/extra_quest"
const TEST_SLOT: int = 993
const SIDES: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

var _area: Node


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	SaveSystem.current_slot = TEST_SLOT


func after_test() -> void:
	if is_instance_valid(_area):
		_area.free()
	_area = null
	get_tree().paused = false
	if SaveSystem.has_slot(TEST_SLOT):
		DirAccess.remove_absolute(SaveSystem.slot_path(TEST_SLOT))
	SaveSystem.current_slot = SaveSystem.GAME_SLOT
	GameState.clear()


func test_every_quest_in_data_is_run_and_can_be_finished_from_its_data_alone() -> void:
	var runner: QuestRunner = Quests.runner
	var in_data: Array = Array(DataRegistry.ids(&"quests")).map(func(id: StringName) -> String: return String(id))
	var run: Array = Array(runner.quest_ids()).map(func(id: StringName) -> String: return String(id))
	in_data.sort()
	run.sort()
	assert_array(run).override_failure_message("every file in data/quests is run").is_equal(in_data)
	assert_array(run).is_equal(["a_place_of_your_own", "eggs_for_tilda", "lost_shuttle", "slime_bounty"])
	for quest_id: StringName in runner.quest_ids():
		# The main quest may have begun by itself already.
		assert_bool(runner.start(quest_id) or runner.starts_itself(quest_id)).override_failure_message("%s starts" % quest_id).is_true()
		var stages: Dictionary = DataRegistry.get_quest(quest_id)["stages"]
		for step: int in stages.size():
			if runner.status(quest_id) == QuestState.COMPLETE:
				break
			assert_str(runner.journal(quest_id)).override_failure_message("%s has a journal line at every stage" % quest_id).is_not_empty()
			assert_array(runner.objectives(quest_id)).override_failure_message("%s: something to do at '%s'" % [quest_id, runner.stage(quest_id)]).is_not_empty()
			# Do what the stage's first way on asks for.
			_satisfy(stages[String(runner.stage(quest_id))]["transitions"][0]["when"])
		assert_that(runner.status(quest_id)).override_failure_message("%s finishes" % quest_id).is_equal(QuestState.COMPLETE)
		assert_str(runner.journal(quest_id)).override_failure_message("%s says how it ended" % quest_id).is_not_empty()


func test_the_lost_shuttle_from_wenna_to_the_stream_and_back() -> void:
	var weaver: AreaController = _load(WEAVER)
	_talk(weaver, "Wenna")
	_say(weaver, "You look troubled.")
	_say(weaver, "I'll look for it.")
	assert_that(Quests.runner.stage(&"lost_shuttle")).is_equal(&"find")
	assert_str(weaver.hud.notice_text()).is_equal("New quest: The Lost Shuttle")
	_say(weaver, "Goodbye.")
	_talk(weaver, "Wenna")
	assert_array(Array(weaver.hud.dialogue.shown_options())).override_failure_message("offered once").is_equal(["About your shuttle...", "Goodbye."])

	GameState.go_to(&"north_fields", &"south_road")
	var fields: AreaController = _load(FIELDS)
	var shuttle: ItemPickup = fields.interactables.get_node(^"Shuttle")
	assert_bool(_reachable(fields, fields.player.motor.cell).has(shuttle.cell())).override_failure_message("the far bank can be reached over the bridge").is_true()
	assert_int(shuttle.cell().y).override_failure_message("north of the stream").is_less(10)
	fields.player.motor.place(shuttle.cell())
	assert_bool(fields.interact()).is_true()
	assert_that(Quests.runner.stage(&"lost_shuttle")).is_equal(&"return")
	assert_str(fields.hud.notice_text()).is_equal("Quest updated: The Lost Shuttle")

	weaver = _load(WEAVER)
	_talk(weaver, "Wenna")
	_say(weaver, "I found your shuttle.")
	assert_that(Quests.runner.status(&"lost_shuttle")).is_equal(QuestState.COMPLETE)
	assert_str(weaver.hud.notice_text()).is_equal("Quest complete: The Lost Shuttle")
	assert_int(GameState.item_count(&"weavers_shuttle")).override_failure_message("handed over").is_equal(0)
	assert_int(GameState.item_count(&"coin")).override_failure_message("the reward").is_equal(30)
	_say(weaver, "Goodbye.")
	_talk(weaver, "Wenna")
	assert_array(Array(weaver.hud.dialogue.shown_options())).override_failure_message("nothing more to ask").is_equal(["Goodbye."])


func test_a_shuttle_found_before_asking_can_be_handed_straight_over() -> void:
	GameState.add_item(&"weavers_shuttle")
	var weaver: AreaController = _load(WEAVER)
	_talk(weaver, "Wenna")
	_say(weaver, "You look troubled.")
	_say(weaver, "I'll look for it.")
	assert_that(Quests.runner.stage(&"lost_shuttle")).is_equal(&"return")
	_say(weaver, "Is this it?")
	assert_that(Quests.runner.status(&"lost_shuttle")).is_equal(QuestState.COMPLETE)
	assert_int(GameState.item_count(&"coin")).is_equal(30)


func test_eggs_for_tilda_from_oda_to_the_shop_and_back() -> void:
	var village: AreaController = _load(VILLAGE)
	_talk(village, "FarmerOda")
	_say(village, "Need a hand with anything?")
	_say(village, "I'll take it.")
	assert_int(GameState.item_count(&"egg_basket")).override_failure_message("Oda hands over the basket").is_equal(1)
	assert_str(village.hud.notice_text()).is_equal("New quest: Eggs for Tilda")

	var shop: AreaController = _load(SHOP)
	_talk(shop, "Tilda")
	assert_str(shop.hud.dialogue.shown_options()[0]).is_equal("Eggs from Farmer Oda.")
	_say(shop, "Eggs from Farmer Oda.")
	assert_int(GameState.item_count(&"egg_basket")).is_equal(0)
	assert_that(Quests.runner.stage(&"eggs_for_tilda")).is_equal(&"tell_oda")
	_say(shop, "Something else.")
	assert_bool(Array(shop.hud.dialogue.shown_options()).has("Eggs from Farmer Oda.")).override_failure_message("delivered once").is_false()

	village = _load(VILLAGE)
	_talk(village, "FarmerOda")
	_say(village, "Tilda has her eggs.")
	assert_that(Quests.runner.status(&"eggs_for_tilda")).is_equal(QuestState.COMPLETE)
	assert_int(GameState.item_count(&"bomb")).override_failure_message("the reward").is_equal(5)
	assert_str(village.hud.notice_text()).is_equal("Quest complete: Eggs for Tilda")


func test_the_slime_bounty_from_rolf_to_the_south_field_and_back() -> void:
	var village: AreaController = _load(VILLAGE)
	_talk(village, "GuardRolf")
	_say(village, "Any work for a sword?")
	_say(village, "I'll do it.")
	assert_that(Quests.runner.stage(&"slime_bounty")).is_equal(&"hunt")

	var field: AreaController = _load(SOUTH_FIELD)
	var slimes: Array[Enemy] = []
	for enemy: Enemy in field.enemies():
		if enemy.enemy_id == &"slime":
			slimes.append(enemy)
	assert_int(slimes.size()).is_equal(3)
	for i: int in slimes.size():
		assert_that(Quests.runner.stage(&"slime_bounty")).override_failure_message("not until all three are beaten").is_equal(&"hunt")
		slimes[i].hurt_box.receive(Hit.new(99, Vector2.ZERO, Vector2.ZERO, &"sword"))
	assert_that(Quests.runner.stage(&"slime_bounty")).is_equal(&"report")
	assert_str(field.hud.notice_text()).is_equal("Quest updated: Slimes in the South Field")

	village = _load(VILLAGE)
	_talk(village, "GuardRolf")
	_say(village, "The slimes are dealt with.")
	assert_that(Quests.runner.status(&"slime_bounty")).is_equal(QuestState.COMPLETE)
	assert_int(GameState.item_count(&"coin")).is_equal(40)
	assert_int(GameState.item_count(&"arrow")).is_equal(10)


func test_the_quest_log_shows_where_each_quest_stands() -> void:
	var village: AreaController = _load(VILLAGE)
	village.open_pause_menu()
	var menu: PauseMenu = village.hud.pause_menu
	menu.choose(PauseMenu.QUESTS)
	var quest_log: QuestLog = menu.quest_log
	# A game just begun has the main quest, and nothing else (P4a).
	assert_array(Array(quest_log.shown_lines())).is_equal(["> A Place of Your Own", "  Back"])
	assert_str(quest_log.shown_detail()).contains("Your cottage").contains("[ ] Take the hoe")
	quest_log.close()
	menu.resume()

	Quests.runner.start(&"lost_shuttle")
	Quests.runner.start(&"slime_bounty")
	Quests.runner.start(&"eggs_for_tilda")
	GameState.set_flag(&"eggs_delivered", true)
	GameState.set_flag(&"told_oda_eggs", true)
	GameState.add_item(&"weavers_shuttle")
	village.open_pause_menu()
	menu.choose(PauseMenu.QUESTS)
	assert_bool(quest_log.is_open()).is_true()
	assert_array(Array(quest_log.shown_lines())).override_failure_message("active first, then finished").is_equal([
		"> A Place of Your Own", "  Slimes in the South Field", "  The Lost Shuttle", "  Eggs for Tilda (done)", "  Back",
	])
	quest_log.move_cursor(1)
	assert_str(quest_log.shown_detail()).contains("[ ] Beat all three slimes in the South Field")
	quest_log.move_cursor(1)
	assert_str(quest_log.shown_detail()).contains("You have the shuttle").contains("[ ] Bring the shuttle to Wenna")
	quest_log.move_cursor(1)
	assert_str(quest_log.shown_detail()).contains("five of the bombs")
	quest_log.close()
	assert_bool(menu.is_open()).override_failure_message("back to the pause menu").is_true()
	assert_bool(get_tree().paused).is_true()
	menu.resume()


func test_quest_progress_survives_a_save_and_never_pays_twice() -> void:
	var weaver: AreaController = _load(WEAVER)
	_talk(weaver, "Wenna")
	_say(weaver, "You look troubled.")
	_say(weaver, "I'll look for it.")
	_say(weaver, "Goodbye.")
	Quests.runner.start(&"eggs_for_tilda")
	GameState.add_item(&"weavers_shuttle")
	var before: Array[Dictionary] = Quests.runner.started_quests()
	assert_int(SaveSystem.save_game()).is_equal(OK)

	GameState.clear()
	GameState.new_game()
	assert_array(Quests.runner.started_quests()).override_failure_message("a new game has no quests").is_empty()
	assert_int(SaveSystem.load_game()).is_equal(OK)
	weaver = _load(WEAVER)
	assert_array(Quests.runner.started_quests()).override_failure_message("the same quests at the same stages").is_equal(before)
	assert_that(Quests.runner.stage(&"lost_shuttle")).is_equal(&"return")
	assert_int(GameState.item_count(&"egg_basket")).override_failure_message("Oda's basket isn't handed over a second time").is_equal(1)
	_talk(weaver, "Wenna")
	_say(weaver, "I found your shuttle.")
	assert_int(GameState.item_count(&"coin")).is_equal(30)
	_say(weaver, "Goodbye.")

	# Saved again after finishing: a load doesn't pay again.
	assert_int(SaveSystem.save_game()).is_equal(OK)
	GameState.clear()
	assert_int(SaveSystem.load_game()).is_equal(OK)
	weaver = _load(WEAVER)
	assert_that(Quests.runner.status(&"lost_shuttle")).is_equal(QuestState.COMPLETE)
	assert_int(GameState.item_count(&"coin")).override_failure_message("paid once").is_equal(30)


func test_a_quest_that_is_only_a_json_file_runs() -> void:
	var registry: Node = auto_free(DataRegistryScript.new())
	var errors: PackedStringArray = registry.load_all(EXTRA_QUEST)
	assert_array(Array(errors)).override_failure_message("\n".join(errors)).is_empty()
	var quests: Dictionary = {}
	for quest: Dictionary in registry.entries(&"quests"):
		quests[quest["id"]] = quest
	var runner: QuestRunner = QuestRunner.new(quests, GameState)
	assert_bool(runner.start(&"herb_run")).is_true()
	assert_str(runner.journal(&"herb_run")).contains("three healing herbs")
	GameState.add_item(&"healing_herb", 2)
	runner.update()
	assert_that(runner.status(&"herb_run")).override_failure_message("two herbs aren't three").is_equal(QuestState.ACTIVE)
	GameState.add_item(&"healing_herb", 1)
	runner.update()
	assert_that(runner.status(&"herb_run")).is_equal(QuestState.COMPLETE)
	assert_int(GameState.item_count(&"healing_herb")).is_equal(0)
	assert_int(GameState.item_count(&"coin")).is_equal(12)


## Makes `condition` true the way a player would: sets the flag, or picks up the item.
func _satisfy(condition: Dictionary) -> void:
	match str(condition.get("type", "")):
		"flag":
			GameState.set_flag(StringName(str(condition["flag"])), condition["value"])
		"has_item":
			GameState.add_item(StringName(str(condition["item"])), int(condition["count"]))
		"all":
			for inner: Dictionary in condition["of"]:
				_satisfy(inner)
		"any":
			_satisfy(condition["of"][0])
		"days_since":
			GameState.set_flag(StringName(str(condition["flag"])), true)
			for day: int in int(condition["days"]):
				GameState.start_next_day()
		_:
			fail("the test can't satisfy a '%s' condition yet" % condition.get("type", ""))


## Stands the hero before the named villager and starts talking.
func _talk(area: AreaController, node_name: String) -> void:
	Steps.stand_before(area, node_name)
	assert_bool(area.interact()).override_failure_message("talk to %s" % node_name).is_true()


## Picks the answer that reads `text`.
func _say(area: AreaController, text: String) -> void:
	var box: DialogueBox = area.hud.dialogue
	var options: PackedStringArray = box.shown_options()
	var index: int = options.find(text)
	assert_int(index).override_failure_message("'%s' isn't among %s" % [text, options]).is_greater_equal(0)
	if index < 0:
		return
	box.move_cursor(index - box.selected)
	box.confirm()


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area


func _reachable(area: AreaController, start: Vector2i) -> Dictionary:
	var seen: Dictionary = {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_back()
		for side: Vector2i in SIDES:
			var next: Vector2i = cell + side
			if not seen.has(next) and area.terrain.check_move(cell, next).is_allowed():
				seen[next] = true
				queue.append(next)
	return seen
