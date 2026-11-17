extends GdUnitTestSuite
## The whole story in one test (P4d): a new game carried through every gate of the pivot's
## story to the ending's lines, with what P4 added on the way. Six days:
##   1  the cottage, the tools, five turnips planted; Elder Bram's welcome, then his promise;
##      the keep's gate chained, then open; berries for Pip
##   2  watering; berries for Pip: two marks
##   3  Pip asks his favour; blossoms for Wenna
##   4  the harvest (farming rises); the Warden falls: the chapel's bars hold
##   5  the bars are up; Wenna teaches jam; the pie for Pip; a day at home
##   6  the Shade falls; the ending: the days, the crops, the friends
## The two boss fights are stood in for by their flags (tests/world/keep_test.gd and
## crypt_test.gd fight them); everything else is done as a player does it.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const VILLAGE: String = "res://world/areas/village/village.tscn"
const HOME: String = "res://world/areas/home/home.tscn"
const ELDER_HOUSE: String = "res://world/areas/elder_house/elder_house.tscn"
const WEAVER: String = "res://world/areas/weaver_house/weaver_house.tscn"
const WOOD: String = "res://world/areas/old_wood/old_wood.tscn"
const FRAME: float = 1.0 / 60.0
const PLOT: Vector2i = Vector2i(12, 18)
const QUEST: StringName = &"a_place_of_your_own"
const TEST_SLOT: int = 972

var _area: Node
var _notices: Array[String] = []


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	GameState.set_time(float(GameState.day_clock().in_day("09:00")))
	SaveSystem.current_slot = TEST_SLOT
	_notices.clear()
	EventBus.skill_rose.connect(_on_skill_rose)
	EventBus.friend_mark_gained.connect(_on_mark_gained)
	EventBus.recipe_learned.connect(_on_recipe_learned)


func after_test() -> void:
	EventBus.skill_rose.disconnect(_on_skill_rose)
	EventBus.friend_mark_gained.disconnect(_on_mark_gained)
	EventBus.recipe_learned.disconnect(_on_recipe_learned)
	if is_instance_valid(_area):
		_area.free()
	_area = null
	get_tree().paused = false
	SaveSystem.erase_slot(TEST_SLOT)
	SaveSystem.current_slot = SaveSystem.GAME_SLOT
	GameState.clear()


func test_a_new_game_runs_through_every_gate_to_the_endings_lines() -> void:
	# --- Day 1: the first morning -------------------------------------------------------
	var village: AreaController = _load(VILLAGE)
	assert_that(Quests.runner.stage(QUEST)).is_equal(&"settle")
	# The keep is shut to him, and Elder Bram has only a welcome.
	GameState.go_to(&"old_wood", &"keep_gate")
	var wood: AreaController = _load(WOOD)
	assert_str(Steps.walk_until_travel(wood, Vector2.UP, 90)).override_failure_message("the keep's gate is chained").is_equal("")
	var house: AreaController = _load(ELDER_HOUSE)
	_talk(house, "Bram")
	assert_str(house.hud.dialogue.shown_text()).contains("Welcome to Hearthvale")
	_end(house)
	# The cottage: what lies inside the door.
	var home: AreaController = _load(HOME)
	for found: String in ["Hoe", "WateringCan", "TurnipSeeds"]:
		home.player.motor.place((home.interactables.get_node(NodePath(found)) as ItemPickup).cell())
		assert_bool(home.interact()).is_true()
	assert_that(Quests.runner.stage(QUEST)).is_equal(&"plant")
	# The plot: five cells tilled and planted with the left click, and watered.
	village = _load(VILLAGE)
	for x: int in 5:
		_face(village, Vector2i(x, 0))
		GameState.equip(&"hoe")
		assert_bool(village.use_hand()).is_true()
		_rest(village)
		GameState.equip(&"turnip_seeds")
		assert_bool(village.use_hand()).is_true()
		_rest(village)
	assert_that(Quests.runner.stage(QUEST)).override_failure_message("the first seed is in").is_equal(&"bram")
	_water_the_plot()
	# Elder Bram speaks of the keep now, and his promise unchains its gate.
	house = _load(ELDER_HOUSE)
	_talk(house, "Bram")
	_say(house, "What lights?")
	_say(house, "I'll keep watch.")
	_end(house)
	assert_that(Quests.runner.stage(QUEST)).is_equal(&"keep")
	GameState.go_to(&"old_wood", &"keep_gate")
	wood = _load(WOOD)
	assert_str(Steps.walk_until_travel(wood, Vector2.UP)).override_failure_message("the gate is open").is_equal("res://world/areas/keep/keep.tscn")
	# Berries picked on the way home (foraging is tests/world/food_test.gd's), and some for Pip.
	GameState.add_item(&"wild_berries", 6)
	village = _load(VILLAGE)
	_give(village, "Pip", "Wild Berries")
	assert_int(GameState.friend_points(&"pip")).override_failure_message("a talk and a gift he likes").is_equal(4)
	_sleep(village)

	# --- Day 2 --------------------------------------------------------------------------
	assert_int(GameState.day).is_equal(2)
	_water_the_plot()
	village = _load(VILLAGE)
	_give(village, "Pip", "Wild Berries")
	assert_int(GameState.friend_marks(&"pip")).is_equal(2)
	_sleep(village)

	# --- Day 3: Pip asks his favour -----------------------------------------------------
	_water_the_plot()
	village = _load(VILLAGE)
	_talk(village, "Pip")
	_say(village, "I'll bake you one.")
	_end(village)
	assert_that(Quests.runner.status(&"pie_for_pip")).is_equal(QuestState.ACTIVE)
	_give(village, "Pip", "Wild Berries")
	GameState.add_item(&"cherry_blossom", 4)
	var weaver: AreaController = _load(WEAVER)
	_give(weaver, "Wenna", "Cherry Blossoms")
	_sleep(weaver)

	# --- Day 4: the harvest, and the keep -----------------------------------------------
	village = _load(VILLAGE)
	for x: int in 5:
		_face(village, Vector2i(x, 0))
		assert_bool(village.interact()).override_failure_message("picking turnip %d" % x).is_true()
	assert_int(GameState.item_count(&"turnip")).is_equal(5)
	assert_int(GameState.skill_level(Skills.FARMING)).override_failure_message("five cells tilled and five crops picked").is_equal(2)
	_give(village, "Pip", "Wild Berries")
	weaver = _load(WEAVER)
	_give(weaver, "Wenna", "Cherry Blossoms")
	assert_int(GameState.friend_marks(&"wenna")).is_equal(2)
	# The Iron Warden falls. The chapel's bars hold until he has slept.
	GameState.set_flag(StoryGates.WARDEN_BEATEN, true)
	assert_that(Quests.runner.stage(QUEST)).is_equal(&"rest")
	GameState.go_to(&"village", &"crypt_door")
	village = _load(VILLAGE)
	var bars: DungeonDoor = village.interactables.get_node(^"CryptBars")
	assert_bool(bars.is_open()).override_failure_message("not on the day the Warden falls").is_false()
	_sleep(village)

	# --- Day 5: a day at home -----------------------------------------------------------
	assert_that(Quests.runner.stage(QUEST)).is_equal(&"crypt")
	GameState.go_to(&"village", &"crypt_door")
	village = _load(VILLAGE)
	assert_bool((village.interactables.get_node(^"CryptBars") as DungeonDoor).is_open()).override_failure_message("at dawn the day after").is_true()
	# Wenna teaches her jam, and the hearth makes it.
	weaver = _load(WEAVER)
	_talk(weaver, "Wenna")
	assert_bool(GameState.knows_recipe(&"berry_jam")).is_true()
	_end(weaver)
	# A pumpkin and wheat (bought and grown: tests/world/farm_round_test.gd's round), baked for Pip.
	GameState.add_item(&"pumpkin")
	GameState.add_item(&"wheat")
	GameState.add_item(&"wild_berries", 2)
	home = _load(HOME)
	var hearth: Hearth = home.interactables.get_node(^"Hearth")
	home.player.motor.place(hearth.cell() + Vector2i.DOWN)
	home.player.face(Vector2.UP)
	assert_bool(home.interact()).is_true()
	_say(home, "Pumpkin Pie (1 Pumpkin, 1 Wheat)")
	_say(home, Cooking.MORE_WORDS)
	_say(home, "Berry Jam (3 Wild Berries)")
	_end(home)
	assert_int(GameState.item_count(&"pumpkin_pie")).is_equal(1)
	assert_int(GameState.item_count(&"berry_jam")).is_equal(1)
	village = _load(VILLAGE)
	# Pip is at four marks now: his present comes first, then the pie is handed over.
	_talk(village, "Pip")
	assert_bool(GameState.get_flag(&"present/pip") == true).is_true()
	_end(village)
	_talk(village, "Pip")
	_say(village, "Here's your pie.")
	_end(village)
	assert_that(Quests.runner.status(&"pie_for_pip")).is_equal(QuestState.COMPLETE)
	assert_int(GameState.item_count(&"coin")).override_failure_message("ten for his present and fifteen for the pie").is_equal(25)
	_sleep(village)

	# --- Day 6: the crypt, and the end --------------------------------------------------
	assert_int(GameState.day).is_equal(6)
	GameState.set_flag(&"crypt_shade_beaten", true)
	assert_that(Quests.runner.status(QUEST)).is_equal(QuestState.COMPLETE)
	GameState.set_flag(EndingSummary.FINISHED_FLAG, true)
	assert_array(Array(EndingScreen.summary_lines()).slice(1)).is_equal([
		"Hearts   3", "Quests finished   2 of 11", "Days   6", "Crops grown   5", "Friends   1 of 8",
	])
	# What was said on the way, each once.
	assert_array(_notices).is_equal([
		"pip 1", "pip 2", "pip 3", "wenna 1", "farming 2", "pip 4", "wenna 2", "berry_jam",
	])
	# And the save he last woke to holds it all, in today's format.
	var saved: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SaveSystem.slot_path(TEST_SLOT)))
	assert_int(int(saved["version"])).is_equal(GameState.SAVE_VERSION)
	assert_int(int(saved["day"])).is_equal(6)
	assert_int(int(saved["tally"]["crops_picked"])).is_equal(5)
	assert_bool(saved["flags"]["recipe/berry_jam"] == true and saved["flags"]["crypt_open"] == true).is_true()


## The five turnips watered (the can's own work is tests/world/farm_round_test.gd's).
func _water_the_plot() -> void:
	for x: int in 5:
		GameState.water_soil(Vector2i(x, 0))


## Talks to the villager and gives them the thing named, through the answer and the list.
func _give(area: AreaController, node_name: String, item_name: String) -> void:
	_talk(area, node_name)
	if not Array(area.hud.dialogue.shown_options()).has(Friendship.GIVE_WORDS):
		# A favour or a present came first: the answer is where they talk as they always do.
		_end(area)
		_talk(area, node_name)
	_say(area, Friendship.GIVE_WORDS)
	var list: GiftMenu = area.hud.gift_menu
	assert_bool(list.is_open()).override_failure_message("the list for %s" % node_name).is_true()
	var names: Array = list.entries().map(func(item: Dictionary) -> String: return str(item["name"]))
	assert_bool(names.has(item_name)).override_failure_message("%s among %s" % [item_name, names]).is_true()
	list.move_cursor(names.find(item_name) - list.selected)
	assert_bool(list.confirm()).is_true()


## A night in bed: the next morning, saved (in this test's own slot), at nine o'clock.
func _sleep(area: AreaController) -> void:
	area.travel = func(_path: String) -> void: pass
	GameState.sleep()
	GameState.set_time(float(GameState.day_clock().in_day("09:00")))


func _face(area: AreaController, cell: Vector2i) -> void:
	area.player.motor.place(PLOT + cell + Vector2i.DOWN)
	area.player.face(Vector2.UP)


func _rest(area: AreaController) -> void:
	for i: int in 40:
		area.player.motor.step(Vector2.ZERO, FRAME)


func _talk(area: AreaController, node_name: String) -> void:
	Steps.stand_before(area, node_name)
	assert_bool(area.interact()).override_failure_message("talk to %s" % node_name).is_true()


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


func _on_skill_rose(skill: StringName, level: int) -> void:
	_notices.append("%s %d" % [skill, level])


func _on_mark_gained(villager: StringName, marks: int) -> void:
	_notices.append("%s %d" % [villager, marks])


func _on_recipe_learned(recipe_id: StringName) -> void:
	_notices.append(String(recipe_id))
