extends GdUnitTestSuite
## The story over days (P4a), in the areas: a new game has the main quest in its log and says
## so; the quest follows the hero through his first day and on to the end; Elder Bram welcomes
## a newcomer and speaks of the keep only once a first crop is in; the keep's gate is chained
## until Bram gives the word, and says why; the crypt's bars stay down on the day the Warden
## falls and are up the next morning; a game saved before the gates is past them; and the
## title's line is the new one.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const VILLAGE: String = "res://world/areas/village/village.tscn"
const HOME: String = "res://world/areas/home/home.tscn"
const ELDER_HOUSE: String = "res://world/areas/elder_house/elder_house.tscn"
const WOOD: String = "res://world/areas/old_wood/old_wood.tscn"
const TITLE: String = "res://ui/title_screen.tscn"
const OLD_SAVE: String = "res://tests/fixtures/saves/v3_in_the_keep.json"
const QUEST: StringName = &"a_place_of_your_own"
const TEST_SLOT: int = 978
## The cells of the keep's gate in the Old Wood, and the cell below its west half.
const GATE_CELLS: Array[Vector2i] = [Vector2i(18, 3), Vector2i(19, 3)]
const BEFORE_GATE: Vector2i = Vector2i(18, 4)

var _area: Node
var _announced: Array = []


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	GameState.set_time(float(GameState.day_clock().in_day("12:00")))
	SaveSystem.current_slot = TEST_SLOT
	_announced.clear()
	EventBus.quest_announced.connect(_on_quest_announced)


func after_test() -> void:
	EventBus.quest_announced.disconnect(_on_quest_announced)
	if is_instance_valid(_area):
		_area.free()
	_area = null
	get_tree().paused = false
	if SaveSystem.has_slot(TEST_SLOT):
		DirAccess.remove_absolute(SaveSystem.slot_path(TEST_SLOT))
	SaveSystem.current_slot = SaveSystem.GAME_SLOT
	GameState.clear()


func test_a_new_game_has_the_main_quest_in_its_log_and_says_so() -> void:
	assert_that(Quests.runner.status(QUEST)).override_failure_message("nothing has asked yet").is_equal(QuestState.NOT_STARTED)
	var village: AreaController = _load(VILLAGE)
	assert_that(Quests.runner.status(QUEST)).is_equal(QuestState.ACTIVE)
	assert_that(Quests.runner.stage(QUEST)).is_equal(&"settle")
	assert_array(_announced).is_equal([[QUEST, &"started"]])
	assert_str(village.hud.notice_text()).override_failure_message("the news shows at the top of the screen").is_equal("New quest: A Place of Your Own")
	assert_int(Quests.runner.active_count()).override_failure_message("and no other quest").is_equal(1)
	village.open_pause_menu()
	village.hud.pause_menu.choose(PauseMenu.QUESTS)
	var quest_log: QuestLog = village.hud.pause_menu.quest_log
	assert_array(Array(quest_log.shown_lines())).is_equal(["> A Place of Your Own", "  Back"])
	assert_str(quest_log.shown_detail()).contains("thatched house at the west end of the lane")
	assert_str(quest_log.shown_detail()).contains("[ ] Take the hoe").contains("[ ] Take the watering can").contains("[ ] Take the seeds")
	quest_log.close()
	village.hud.pause_menu.resume()
	# Loading another area doesn't begin it again.
	_load(HOME)
	assert_array(_announced).override_failure_message("announced once").has_size(1)


func test_no_game_no_quest() -> void:
	GameState.clear()
	Quests.refresh()
	assert_that(Quests.runner.status(QUEST)).override_failure_message("on the title screen there is no game to have a quest").is_equal(QuestState.NOT_STARTED)
	assert_bool(GameState.quests.is_empty() and GameState.flags.is_empty()).is_true()


func test_the_quest_follows_the_hero_through_his_first_day() -> void:
	# The cottage: what lies inside the door.
	var home: AreaController = _load(HOME)
	for found: String in ["Hoe", "WateringCan"]:
		home.player.motor.place((home.interactables.get_node(NodePath(found)) as ItemPickup).cell())
		assert_bool(home.interact()).override_failure_message("picking up the %s" % found).is_true()
	assert_that(Quests.runner.stage(QUEST)).override_failure_message("two of three taken").is_equal(&"settle")
	assert_array(Quests.runner.objectives(QUEST).map(func(o: Dictionary) -> bool: return o["done"])).is_equal([true, true, false])
	home.player.motor.place((home.interactables.get_node(^"TurnipSeeds") as ItemPickup).cell())
	assert_bool(home.interact()).is_true()
	assert_that(Quests.runner.stage(QUEST)).is_equal(&"plant")
	assert_str(Quests.runner.journal(QUEST)).contains("by the well").contains("hoe").contains("Tab")

	# The plot: tilling is not yet planting.
	GameState.till_soil(Vector2i(0, 0))
	assert_that(Quests.runner.stage(QUEST)).is_equal(&"plant")
	assert_bool(GameState.plant_crop(Vector2i(0, 0), &"turnip")).is_true()
	assert_that(Quests.runner.stage(QUEST)).is_equal(&"bram")
	assert_str(Quests.runner.journal(QUEST)).contains("Elder Bram").contains("blue-roofed").contains("Water it each morning")

	# Elder Bram: refusing leaves the quest where it is; the promise moves it on.
	var house: AreaController = _load(ELDER_HOUSE)
	var box: DialogueBox = house.hud.dialogue
	Steps.stand_before(house, "Bram")
	house.interact()
	_say(house, "What lights?")
	_say(house, "Not me.")
	_say(house, "Goodbye.")
	assert_that(Quests.runner.stage(QUEST)).is_equal(&"bram")
	house.interact()
	_say(house, "What lights?")
	_say(house, "I'll keep watch.")
	assert_str(box.shown_text()).contains("chain taken off the keep's gate").contains("wooden sword")
	_say(house, "Goodbye.")
	assert_that(Quests.runner.stage(QUEST)).is_equal(&"keep")
	assert_str(Quests.runner.journal(QUEST)).contains("training yard").contains("Old Wood")
	assert_array(_announced.map(func(news: Array) -> StringName: return news[1])).is_equal([&"started", &"updated", &"updated", &"updated"])


func test_a_seed_planted_before_the_tools_are_all_taken_still_moves_the_quest_on() -> void:
	_load(VILLAGE)
	GameState.till_soil(Vector2i(2, 1))
	GameState.plant_crop(Vector2i(2, 1), &"carrot")
	assert_that(Quests.runner.stage(QUEST)).override_failure_message("the can can wait: he has settled in").is_equal(&"bram")


func test_elder_bram_welcomes_a_newcomer_and_speaks_of_the_keep_only_after_the_first_crop() -> void:
	var house: AreaController = _load(ELDER_HOUSE)
	var box: DialogueBox = house.hud.dialogue
	var nodes: Dictionary = DataRegistry.get_dialogue(&"elder_bram")["nodes"]
	Steps.stand_before(house, "Bram")
	assert_bool(house.interact()).is_true()
	assert_str(box.shown_name()).is_equal("Elder Bram")
	assert_str(box.shown_text()).is_equal(str(nodes["welcome"]["text"]))
	assert_str(box.shown_text()).contains("Welcome to Hearthvale").contains("thatched house").contains("plot by the well")
	assert_array(Array(box.shown_options())).is_equal(["What should I do first?", "Goodbye."])
	_say(house, "What should I do first?")
	assert_str(box.shown_text()).contains("tools by your door").contains("seed").contains("Tilda").contains("first crop")
	for words: String in [str(nodes["welcome"]["text"]), str(nodes["settle"]["text"])]:
		assert_bool(words.contains("keep") or words.contains("lights")).override_failure_message("not a word of the keep yet: %s" % words).is_false()
	_say(house, "Goodbye.")
	assert_bool(box.is_open()).is_false()
	assert_bool(GameState.get_flag(StoryGates.KEEP_GATE) == true or GameState.get_flag(&"promised_elder_keep") == true).is_false()

	# The first seed is in the ground.
	GameState.till_soil(Vector2i(0, 0))
	GameState.plant_crop(Vector2i(0, 0), &"turnip")
	house.interact()
	assert_str(box.shown_text()).is_equal(str(nodes["greet"]["text"]))
	assert_array(Array(box.shown_options())).is_equal(["What lights?", "Goodbye."])
	_say(house, "What lights?")
	_say(house, "I'll keep watch.")
	assert_bool(GameState.get_flag(&"promised_elder_keep") == true).is_true()
	assert_bool(GameState.get_flag(StoryGates.KEEP_GATE) == true).override_failure_message("his word unchains the gate").is_true()
	_say(house, "Goodbye.")
	house.interact()
	assert_array(Array(box.shown_options())).is_equal(["I'm keeping watch, as I promised.", "Goodbye."])
	_say(house, "I'm keeping watch, as I promised.")
	assert_str(box.shown_text()).contains("unchained")


func test_the_keeps_gate_is_chained_until_elder_bram_gives_the_word() -> void:
	GameState.go_to(&"old_wood", &"keep_gate")
	var wood: AreaController = _load(WOOD)
	assert_that(wood.player.motor.cell).is_equal(BEFORE_GATE)
	var chain: DungeonDoor = wood.interactables.get_node(^"KeepChain")
	var gate: AreaExit = wood.interactables.get_node(^"KeepGate")
	assert_that(chain.kind).is_equal(DungeonState.CHAINED)
	assert_that(chain.open_flag).is_equal(StoryGates.KEEP_GATE)
	assert_array(chain.cells()).override_failure_message("it fills the way in, and nothing else").is_equal(GATE_CELLS)
	for cell: Vector2i in GATE_CELLS:
		assert_bool(gate.covers(cell)).is_true()
		assert_bool(wood.terrain.is_occupied(cell)).override_failure_message("%s is shut" % cell).is_true()
	assert_bool(chain.is_open()).is_false()

	# He can't walk in, from either half of the gate.
	assert_str(Steps.walk_until_travel(wood, Vector2.UP, 90)).override_failure_message("the chain holds").is_equal("")
	assert_that(wood.player.motor.cell).is_equal(BEFORE_GATE)
	wood.player.motor.place(BEFORE_GATE + Vector2i.RIGHT)
	assert_str(Steps.walk_until_travel(wood, Vector2.UP, 90)).is_equal("")

	# Walking up to it says why, naming who to see.
	wood.hud.show_message("-")
	wood.player.motor.place(BEFORE_GATE + Vector2i.DOWN)
	wood.player.face(Vector2.UP)
	assert_str(Steps.walk_until_travel(wood, Vector2.UP, 60)).is_equal("")
	assert_that(wood.player.motor.cell).is_equal(BEFORE_GATE)
	assert_str(wood.hud.message_text()).is_equal(chain.shut_words)
	assert_str(wood.hud.message_text()).contains("chained").contains("Elder Bram").contains("Hearthvale")
	# So does trying it.
	wood.hud.show_message("-")
	assert_str(chain.prompt()).is_equal("Try the gate")
	assert_bool(wood.interact()).is_true()
	assert_str(wood.hud.message_text()).is_equal(chain.shut_words)
	# Walking past it, facing along the wall, says nothing.
	wood.hud.show_message("-")
	wood.player.motor.place(BEFORE_GATE + Vector2i(2, 1))
	wood.player.face(Vector2.LEFT)
	for i: int in 40:
		wood.player.motor.step(Vector2.LEFT, 1.0 / 60.0)
	assert_str(wood.hud.message_text()).override_failure_message("only when he faces it").is_equal("-")

	# Elder Bram's word: the chain is off, and the way is as it was.
	GameState.set_flag(StoryGates.KEEP_GATE, true)
	assert_bool(chain.is_open()).is_true()
	assert_str(chain.words()).is_empty()
	assert_str(chain.prompt()).is_empty()
	for cell: Vector2i in GATE_CELLS:
		assert_bool(wood.terrain.is_occupied(cell)).is_false()
	wood.player.motor.place(BEFORE_GATE)
	var keep: AreaController = _load(Steps.walk_until_travel(wood, Vector2.UP))
	assert_str(keep.area_name).is_equal("The Old Keep")


func test_a_chained_gate_with_no_words_of_its_own_still_says_it_is_chained() -> void:
	var chain: DungeonDoor = auto_free(DungeonDoor.new())
	chain.kind = DungeonState.CHAINED
	chain.open_flag = &"some_word_given"
	assert_str(chain.words()).is_equal(DungeonDoor.CHAINED_WORDS)
	assert_str(chain.use()).is_equal(DungeonDoor.CHAINED_WORDS)
	GameState.set_flag(&"some_word_given", true)
	assert_str(chain.use()).override_failure_message("open, it has nothing to say").is_empty()
	# Other doors have no such words.
	var bars: DungeonDoor = auto_free(DungeonDoor.new())
	bars.kind = DungeonState.SHUTTER
	assert_str(bars.words()).is_empty()


func test_the_crypts_bars_stay_down_the_day_the_warden_falls_and_lift_at_dawn() -> void:
	for flag: StringName in [StoryGates.FIRST_CROP, StoryGates.KEEP_GATE]:
		GameState.set_flag(flag, true)
	GameState.go_to(&"village", &"crypt_door")
	var village: AreaController = _load(VILLAGE)
	village.travel = func(_path: String) -> void: pass
	var bars: DungeonDoor = village.interactables.get_node(^"CryptBars")
	assert_that(bars.open_flag).is_equal(StoryGates.CRYPT_OPEN)
	assert_that(Quests.runner.stage(QUEST)).is_equal(&"keep")
	GameState.set_flag(StoryGates.WARDEN_BEATEN, true)
	assert_that(Quests.runner.stage(QUEST)).is_equal(&"rest")
	assert_str(Quests.runner.journal(QUEST)).contains("lift at dawn").contains("sleep")
	assert_array(Quests.runner.objectives(QUEST)).is_equal([{"text": "Sleep until morning", "done": false, "optional": false}])
	assert_bool(bars.is_open()).override_failure_message("not on the day the Warden falls").is_false()
	assert_bool(GameState.get_flag(StoryGates.CRYPT_OPEN) == true).is_false()
	# However late it gets that day.
	GameState.set_time(float(GameState.day_clock().in_day("01:30")))
	Quests.refresh()
	assert_bool(bars.is_open()).is_false()
	village.player.face(Vector2.UP)
	assert_bool(village.interact()).override_failure_message("the bars say they block the way").is_true()

	# He sleeps (the bed's effect; the game is saved, in a slot of this test's own).
	GameState.sleep()
	assert_int(GameState.day).is_equal(2)
	assert_bool(GameState.get_flag(StoryGates.CRYPT_OPEN) == true).is_true()
	assert_that(Quests.runner.stage(QUEST)).is_equal(&"crypt")
	assert_str(Quests.runner.journal(QUEST)).contains("bars under the chapel are up").contains("light")
	assert_bool(bars.is_open()).override_failure_message("at dawn the day after").is_true()
	for cell: Vector2i in bars.cells():
		assert_bool(village.terrain.is_occupied(cell)).is_false()
	# The morning is in the save he woke to.
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SaveSystem.slot_path(TEST_SLOT)))
	assert_bool(saved["flags"]["crypt_open"] == true).is_true()
	assert_str(str(saved["quests"][String(QUEST)])).is_equal("crypt")


func test_collapsing_brings_the_dawn_too() -> void:
	for flag: StringName in [StoryGates.FIRST_CROP, StoryGates.KEEP_GATE, StoryGates.WARDEN_BEATEN]:
		GameState.set_flag(flag, true)
	_load(VILLAGE)
	assert_that(Quests.runner.stage(QUEST)).is_equal(&"rest")
	GameState.collapse()
	assert_that(Quests.runner.stage(QUEST)).override_failure_message("a night is a night, however it was spent").is_equal(&"crypt")
	assert_bool(GameState.get_flag(StoryGates.CRYPT_OPEN) == true).is_true()


func test_the_quest_runs_to_the_end_of_the_story() -> void:
	_load(VILLAGE)
	var stages: Array[StringName] = [Quests.runner.stage(QUEST)]
	for flag: StringName in [&"took_hoe", &"took_watering_can", &"took_first_seeds"]:
		GameState.set_flag(flag, true)
	stages.append(Quests.runner.stage(QUEST))
	GameState.till_soil(Vector2i(0, 0))
	GameState.plant_crop(Vector2i(0, 0), &"turnip")
	stages.append(Quests.runner.stage(QUEST))
	GameState.set_flag(StoryGates.KEEP_GATE, true)
	stages.append(Quests.runner.stage(QUEST))
	GameState.start_next_day()
	GameState.start_next_day()
	GameState.set_flag(StoryGates.WARDEN_BEATEN, true)
	stages.append(Quests.runner.stage(QUEST))
	GameState.start_next_day()
	stages.append(Quests.runner.stage(QUEST))
	assert_that(Quests.runner.status(QUEST)).is_equal(QuestState.ACTIVE)
	GameState.set_flag(&"crypt_shade_beaten", true)
	stages.append(Quests.runner.stage(QUEST))
	assert_array(stages).is_equal([&"settle", &"plant", &"bram", &"keep", &"rest", &"crypt", &"done"])
	assert_that(Quests.runner.status(QUEST)).is_equal(QuestState.COMPLETE)
	assert_str(Quests.runner.journal(QUEST)).contains("The Shade is gone")
	assert_that((_announced.back() as Array)[1]).is_equal(&"completed")
	# Every stage has words that fit the quest log's box: a few lines, and something to do.
	var quest: Dictionary = DataRegistry.get_quest(QUEST)
	for stage_id: String in quest["stages"]:
		var stage: Dictionary = quest["stages"][stage_id]
		assert_int(str(stage["journal"]).length()).override_failure_message("'%s' is short enough for the log" % stage_id).is_less_equal(150)
		if stage_id != "done":
			assert_int((stage["objectives"] as Array).size()).override_failure_message("'%s' has one to three things to do" % stage_id).is_between(1, 3)


func test_a_game_saved_before_the_gates_is_past_them() -> void:
	# A real version 3 save: the fourth day, inside the keep, by a hero who never met Bram.
	DirAccess.make_dir_recursive_absolute(SaveSystem.SAVE_DIR)
	var file: FileAccess = FileAccess.open(SaveSystem.slot_path(TEST_SLOT), FileAccess.WRITE)
	file.store_string(FileAccess.get_file_as_string(OLD_SAVE))
	file.close()
	assert_int(SaveSystem.load_game()).is_equal(OK)
	GameState.go_to(&"old_wood", &"keep_gate")
	var chimes: Array = []
	var on_sound: Callable = func(id: StringName) -> void:
		if id == &"quest":
			chimes.append(id)
	EventBus.sound.connect(on_sound)
	var wood: AreaController = _load(WOOD)
	EventBus.sound.disconnect(on_sound)
	assert_int(_announced.size()).override_failure_message("every stage it ran through is announced").is_equal(4)
	assert_int(chimes.size()).override_failure_message("but it chimes once, not four times at once").is_equal(1)
	assert_bool((wood.interactables.get_node(^"KeepChain") as DungeonDoor).is_open()).override_failure_message("the gate he came through is not chained behind him").is_true()
	assert_that(Quests.runner.stage(QUEST)).override_failure_message("the main quest catches up to where he is").is_equal(&"keep")
	assert_that(Quests.runner.stage(&"lost_shuttle")).override_failure_message("his other quest is as it was").is_equal(&"find")
	assert_str(Steps.walk_until_travel(wood, Vector2.UP)).is_equal("res://world/areas/keep/keep.tscn")
	# Elder Bram does not treat him as a newcomer.
	var house: AreaController = _load(ELDER_HOUSE)
	Steps.stand_before(house, "Bram")
	house.interact()
	# (He carries turnips and bread, so there is something to give: P4c.)
	assert_array(Array(house.hud.dialogue.shown_options())).is_equal(["What lights?", Friendship.GIVE_WORDS, "Goodbye."])
	_say(house, "Goodbye.")
	# Had the Warden fallen in that save, the bars would be up and the quest in the crypt.
	var fallen: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(OLD_SAVE))
	fallen["flags"]["keep_warden_beaten"] = true
	file = FileAccess.open(SaveSystem.slot_path(TEST_SLOT), FileAccess.WRITE)
	file.store_string(JSON.stringify(fallen))
	file.close()
	assert_int(SaveSystem.load_game()).is_equal(OK)
	GameState.go_to(&"village", &"crypt_door")
	var village: AreaController = _load(VILLAGE)
	assert_bool((village.interactables.get_node(^"CryptBars") as DungeonDoor).is_open()).is_true()
	assert_that(Quests.runner.stage(QUEST)).is_equal(&"crypt")


func test_the_title_speaks_of_the_cottage_the_plot_and_the_keep() -> void:
	var title: TitleScreen = (load(TITLE) as PackedScene).instantiate()
	get_tree().root.add_child(title)
	_area = title
	assert_str((title.get_node(^"Subtitle") as Label).text).is_equal("A cottage, a plot of soil, and lights over the old keep.")


## Picks the answer that reads `text` in the open conversation.
func _say(area: AreaController, text: String) -> void:
	var box: DialogueBox = area.hud.dialogue
	var index: int = box.shown_options().find(text)
	assert_int(index).override_failure_message("no answer '%s' among %s" % [text, box.shown_options()]).is_greater_equal(0)
	box.move_cursor(index - box.selected)
	box.confirm()


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area


func _on_quest_announced(quest_id: StringName, what: StringName) -> void:
	_announced.append([quest_id, what])
