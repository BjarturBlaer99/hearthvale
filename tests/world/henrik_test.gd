extends GdUnitTestSuite
## Old Henrik (Willowmere, step 3): an eighth villager to befriend, by his ruined hut from
## 06:00 to 20:00. At two marks he asks a favour, three Wisp Embers; handed over, the marsh
## lanterns are lit (they burn from dusk to dawn, and their light gives a Bogwisp a body as
## the Lantern does) and he teaches Ember Tea. At four marks he gives a present. A save from
## before him loads with him a stranger and the lanterns dark.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const MARSH: String = "res://world/areas/willowmere/willowmere.tscn"
const HOME: String = "res://world/areas/home/home.tscn"
const OLD_SAVE: String = "res://tests/fixtures/saves/v3_in_the_keep.json"
const TEST_SLOT: int = 963
const QUEST: StringName = &"lights_on_the_marsh"
const LANTERNS: StringName = &"marsh_lanterns_lit"
const POSTS: int = 6

var _area: Node


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	Quests.refresh()
	SaveSystem.erase_slot(TEST_SLOT)
	SaveSystem.current_slot = TEST_SLOT


func after_test() -> void:
	get_tree().paused = false
	if is_instance_valid(_area):
		_area.free()
	_area = null
	SaveSystem.erase_slot(TEST_SLOT)
	SaveSystem.current_slot = SaveSystem.GAME_SLOT
	GameState.clear()


func test_henrik_is_an_eighth_villager_made_of_data() -> void:
	var villagers: Array = DataRegistry.entries(&"villagers")
	assert_int(villagers.size()).is_equal(8)
	var henrik: Dictionary = DataRegistry.get_villager(&"old_henrik")
	assert_str(str(henrik["name"])).is_equal("Old Henrik")
	assert_str(str(henrik["dialogue"])).is_equal("old_henrik")
	assert_array(henrik["likes"]).is_equal(["marsh_stew", "bread"])
	assert_dict(Friendship.villager_of(villagers, "old_henrik")).is_equal(henrik)
	var rules: Friendship = GameState.friendship()
	for liked: String in henrik["likes"]:
		assert_bool(rules.is_giftable(DataRegistry.get_item(StringName(liked)))).override_failure_message("%s can be given" % liked).is_true()
	# Three lines of thanks, each his own and each short enough for the message line.
	var lines: Array[String] = [Friendship.thanks(henrik, true), Friendship.thanks(henrik, false), Friendship.thanks(henrik, false, true)]
	for line: String in lines:
		assert_str(line).starts_with("Old Henrik: ")
		assert_int(line.length()).override_failure_message(line).is_less_equal(64)
		assert_str(line).is_not_equal("Old Henrik: Thank you.")
	assert_int(lines.size()).is_equal(3)
	assert_bool(lines[0] != lines[1] and lines[1] != lines[2] and lines[0] != lines[2]).is_true()
	assert_array(Array(DataRegistry.errors)).override_failure_message("the data loads clean").is_empty()


func test_the_friends_page_has_room_for_eight() -> void:
	# With an eighth name the list ran into the line under it: the line moved down.
	var marsh: AreaController = _marsh("12:00")
	assert_bool(marsh.open_pause_menu()).is_true()
	marsh.hud.pause_menu.choose(PauseMenu.FRIENDS)
	var page: FriendsPage = marsh.hud.pause_menu.friends_page
	assert_int(page.shown_lines().size()).is_equal(8)
	assert_bool(Array(page.shown_lines()).has("Old Henrik 0/5")).is_true()
	var rows: Control = page.get_node(^"Panel/Rows")
	var how: Label = page.get_node(^"Panel/How")
	var help: Label = page.get_node(^"Panel/Help")
	assert_float(rows.position.y + 8.0 * FriendsPage.ROW_HEIGHT).override_failure_message("the eighth row ends above the line that says how").is_less_equal(how.position.y)
	assert_float(how.position.y + 12.0).override_failure_message("and that line above the keys").is_less_equal(help.position.y)
	page.close()
	marsh.hud.pause_menu.resume()
	get_tree().paused = false


func test_he_stands_by_his_hut_by_day_and_is_away_at_night() -> void:
	var marsh: AreaController = _marsh("12:00")
	var henrik: Villager = marsh.interactables.get_node(^"OldHenrik")
	assert_str(henrik.display_name()).is_equal("Old Henrik")
	assert_bool(henrik.present).is_true()
	assert_bool(henrik.visible).is_true()
	var layer: TileMapLayer = marsh.get_node(^"Height")
	assert_that(layer.get_cell_atlas_coords(henrik.cell() + Vector2i.UP)).override_failure_message("in front of his hut's wall").is_equal(GreyboxTiles.coords("ruin_wall"))
	assert_bool(marsh.terrain.is_occupied(henrik.cell())).is_true()
	Steps.stand_before(marsh, "OldHenrik")
	assert_bool(marsh.interact()).is_true()
	assert_str(marsh.hud.dialogue.shown_name()).is_equal("Old Henrik")
	assert_str(marsh.hud.dialogue.shown_text()).contains("Keep to the boards after dark")
	assert_array(Array(marsh.hud.dialogue.shown_options())).override_failure_message("a stranger with nothing to give: the file's own answers").is_equal(["Anything else?", "Goodbye."])
	_say(marsh, "Anything else?")
	assert_str(marsh.hud.dialogue.shown_text()).override_failure_message("he says why the sword does nothing").contains("lantern light")
	# After dark he is in, like every villager out of doors.
	marsh = _marsh("21:00")
	henrik = marsh.interactables.get_node(^"OldHenrik")
	assert_bool(henrik.present).is_false()
	assert_bool(marsh.terrain.is_occupied(henrik.cell())).override_failure_message("and his place is empty").is_false()


func test_he_is_befriended_like_the_other_seven() -> void:
	GameState.add_item(&"marsh_stew", 1)
	GameState.add_item(&"wild_berries", 1)
	var marsh: AreaController = _marsh("12:00")
	_talk(marsh)
	assert_int(GameState.friend_points(&"old_henrik")).override_failure_message("a point for the day's first talk").is_equal(1)
	_say(marsh, Friendship.GIVE_WORDS)
	var list: GiftMenu = marsh.hud.gift_menu
	assert_str(list.title_text()).is_equal("A gift for Old Henrik")
	assert_bool(list.confirm()).is_true()
	assert_int(GameState.item_count(&"marsh_stew")).is_equal(0)
	assert_int(GameState.friend_points(&"old_henrik")).override_failure_message("three for the stew, which he likes").is_equal(4)
	assert_str(marsh.hud.message_text()).is_equal("Old Henrik: Now that warms old bones. Thank you.")
	assert_array(Array(marsh.hud.notice_lines())).contains(["Old Henrik: friendship 1 of 5."])
	# The next day: berries are nothing special to him.
	GameState.start_next_day()
	GameState.set_time(float(GameState.day_clock().in_day("12:00")))
	_talk(marsh)
	_say(marsh, Friendship.GIVE_WORDS)
	assert_bool(list.confirm()).is_true()
	assert_str(marsh.hud.message_text()).is_equal("Old Henrik: Kind of you to think of me.")
	assert_int(GameState.friend_points(&"old_henrik")).is_equal(4 + 1 + 1)


func test_the_favour_is_asked_at_two_marks_and_three_embers_light_the_lanterns() -> void:
	GameState.add_friendship(&"old_henrik", 7)
	var marsh: AreaController = _marsh("12:00")
	var decor: TileMapLayer = marsh.get_node(^"Decor")
	assert_int(_posts(decor, GreyboxTiles.LANTERN_DARK)).override_failure_message("six posts, dark").is_equal(POSTS)
	assert_int(_posts(decor, GreyboxTiles.LANTERN_LIT)).is_equal(0)
	assert_bool(marsh.lanterns_are_lit()).is_false()
	# Two marks with the day's talk: he asks.
	_talk(marsh)
	assert_int(GameState.friend_marks(&"old_henrik")).is_equal(2)
	assert_str(marsh.hud.dialogue.shown_text()).contains("three of their embers")
	_say(marsh, "I'll bring them.")
	assert_that(Quests.runner.status(QUEST)).is_equal(QuestState.ACTIVE)
	assert_str(Quests.runner.title(QUEST)).is_equal("Lights on the Marsh")
	_say(marsh, "Goodbye.")
	# Two embers are not three.
	GameState.add_item(&"wisp_ember", 2)
	_talk(marsh)
	assert_bool(Array(marsh.hud.dialogue.shown_options()).has("Three embers, Henrik.")).is_false()
	_say(marsh, "About those embers...")
	assert_str(marsh.hud.dialogue.shown_text()).contains("lantern's light")
	_say(marsh, "Goodbye.")
	# Three: handed over, the favour is done.
	GameState.add_item(&"wisp_ember", 1)
	_talk(marsh)
	_say(marsh, "Three embers, Henrik.")
	assert_int(GameState.item_count(&"wisp_ember")).is_equal(0)
	assert_that(Quests.runner.status(QUEST)).is_equal(QuestState.COMPLETE)
	assert_bool(GameState.get_flag(LANTERNS) == true).is_true()
	assert_bool(GameState.knows_recipe(&"ember_tea")).override_failure_message("and he teaches ember tea").is_true()
	assert_array(Array(marsh.hud.notice_lines())).contains(["Quest complete: Lights on the Marsh"])
	_say(marsh, "Goodbye.")
	# Every post has its burning picture at once, though by day they give no light yet.
	assert_int(_posts(decor, GreyboxTiles.LANTERN_LIT)).override_failure_message("six posts, burning").is_equal(POSTS)
	assert_int(_posts(decor, GreyboxTiles.LANTERN_DARK)).is_equal(0)
	assert_bool(marsh.lanterns_are_lit()).is_true()
	assert_bool(marsh.lanterns_burn()).override_failure_message("not at noon").is_false()
	assert_array(marsh.holding_lights()).is_empty()
	# The posts still block, lit or dark.
	assert_bool(marsh.grid.is_solid(Vector2i(6, 13))).is_true()
	# Neither the favour nor its answers come again.
	_talk(marsh)
	assert_bool(Array(marsh.hud.dialogue.shown_options()).has("About those embers...") or Array(marsh.hud.dialogue.shown_options()).has("I'll bring them.")).is_false()


func test_lit_the_lanterns_burn_from_dusk_and_give_a_wisp_a_body() -> void:
	# Before the favour the posts are dark at night, and without the Lantern nothing holds a wisp.
	var marsh: AreaController = _marsh("22:00")
	assert_bool(marsh.lanterns_burn()).is_false()
	assert_array(marsh.holding_lights()).is_empty()
	assert_int(_lantern_glows(marsh)).is_equal(0)
	# After it: six lights along the boards, from dusk.
	GameState.set_flag(LANTERNS, true)
	marsh = _marsh("22:00")
	assert_int(_posts(marsh.get_node(^"Decor"), GreyboxTiles.LANTERN_LIT)).override_failure_message("burning as he arrives").is_equal(POSTS)
	assert_bool(marsh.lanterns_burn()).is_true()
	assert_int(marsh.holding_lights().size()).override_failure_message("six lanterns, and he carries none").is_equal(POSTS)
	assert_float(float(marsh.holding_lights()[0]["radius"])).is_equal(Ambience.LANTERN_HOLD)
	assert_int(_lantern_glows(marsh)).override_failure_message("and each is seen to glow").is_equal(POSTS)
	# A wisp that drifts into a lantern's light can be struck, with no Lantern in his pack.
	GameState.add_item(&"wooden_sword")
	var wisp: Enemy = marsh.interactables.get_node(^"BogwispA")
	var post: Vector2i = Vector2i(6, 13)
	var under_it: Vector2 = Vector2(post * 16) + Ambience.LANTERN_AT - Enemy.WISP_AT
	_put(wisp, under_it)
	wisp.step(0.0)
	assert_bool((wisp.brain as WispBrain).lit).override_failure_message("in the lantern's light").is_true()
	assert_bool((wisp.brain as WispBrain).take_hit(2, Vector2.ZERO, &"sword")).is_true()
	_put(wisp, under_it + Vector2(Ambience.LANTERN_HOLD + 30.0, -40.0))
	wisp.step(0.0)
	assert_bool((wisp.brain as WispBrain).lit).override_failure_message("out over the pool it is a light again").is_false()
	# A lantern's light reaches as far as it is said to, and no further.
	for case: Array in [[Ambience.LANTERN_HOLD - 6.0, true], [Ambience.LANTERN_HOLD * 0.5, true], [Ambience.LANTERN_HOLD + 6.0, false]]:
		_put(wisp, under_it + Vector2(-float(case[0]), 0))
		wisp.step(0.0)
		assert_bool((wisp.brain as WispBrain).lit).override_failure_message("%s px west of the post" % case[0]).is_equal(case[1])
	assert_float(Ambience.LANTERN_HOLD).override_failure_message("a little less than the Lantern he carries").is_less(marsh.hero_light_radius() if GameState.item_count(&"lantern") > 0 else 56.0)
	assert_float(Ambience.LANTERN_HOLD).is_greater(24.0)
	# By day they don't burn, and at dusk they do.
	marsh = _marsh("12:00")
	assert_bool(marsh.lanterns_burn()).is_false()
	assert_int(_lantern_glows(marsh)).is_equal(0)
	GameState.set_time(float(GameState.day_clock().in_day("18:45")))
	assert_bool(marsh.lanterns_burn()).override_failure_message("with the village's lamps").is_true()
	assert_int(_lantern_glows(marsh)).is_equal(POSTS)
	# The village has no such posts: its flag is its own.
	assert_bool(FileAccess.get_file_as_string("res://world/areas/village/village.tscn").contains("lanterns_flag")).is_false()


func test_ember_tea_is_at_the_hearth_only_once_he_has_taught_it() -> void:
	var recipe: Dictionary = DataRegistry.get_recipe(&"ember_tea")
	assert_bool(bool(recipe["taught"])).is_true()
	assert_array(recipe["needs"]).is_equal([{"item": "wisp_ember", "count": 1.0}, {"item": "marsh_berries", "count": 2.0}])
	GameState.add_item(&"wisp_ember", 1)
	GameState.add_item(&"marsh_berries", 2)
	var home: AreaController = _load(HOME)
	_cook(home)
	assert_bool(Array(home.hud.dialogue.shown_options()).any(func(answer: String) -> bool: return answer.begins_with("Ember Tea"))).override_failure_message("not before the favour").is_false()
	_say(home, Cooking.LEAVE_WORDS)
	# The favour's last stage teaches it.
	GameState.set_quest_stage(QUEST, &"bring")
	GameState.set_flag(&"embers_given", true)
	assert_bool(GameState.knows_recipe(&"ember_tea")).is_true()
	_cook(home)
	_say(home, "Ember Tea (1 Wisp Ember, 2 Marsh Berries)")
	assert_int(GameState.item_count(&"ember_tea")).is_equal(1)
	assert_int(GameState.item_count(&"wisp_ember")).is_equal(0)
	assert_int(GameState.item_count(&"marsh_berries")).is_equal(0)
	# It puts the strength back: a great deal of energy, and no hearts.
	GameState.set_energy(5.0)
	GameState.damage(2)
	var hearts: int = GameState.health
	assert_bool(GameState.eat(&"ember_tea")).is_true()
	assert_float(GameState.energy).is_equal(5.0 + GameState.food_energy(&"ember_tea"))
	assert_float(GameState.food_energy(&"ember_tea")).override_failure_message("more than any other dish").is_greater_equal(90.0)
	assert_int(GameState.health).override_failure_message("energy only").is_equal(hearts)
	assert_that(ItemIcons.name_for(&"ember_tea")).is_equal(&"ember_tea")


func test_at_four_marks_he_gives_three_bog_mushrooms_once() -> void:
	GameState.add_friendship(&"old_henrik", 15)
	GameState.set_quest_stage(QUEST, &"bring")
	var marsh: AreaController = _marsh("12:00")
	_talk(marsh)
	assert_int(GameState.friend_marks(&"old_henrik")).is_equal(4)
	assert_int(GameState.item_count(&"bog_mushroom")).is_equal(3)
	assert_bool(GameState.get_flag(&"present/old_henrik") == true).is_true()
	_say(marsh, "Thank you.")
	GameState.start_next_day()
	GameState.set_time(float(GameState.day_clock().in_day("12:00")))
	_talk(marsh)
	assert_int(GameState.item_count(&"bog_mushroom")).override_failure_message("once").is_equal(3)


func test_the_favour_is_a_quest_of_the_same_shape_as_the_other_four() -> void:
	var quest: Dictionary = DataRegistry.get_quest(QUEST)
	assert_str(str(quest["giver"])).is_equal("old_henrik")
	assert_str(str(quest["start_stage"])).is_equal("bring")
	for stage_id: String in quest["stages"]:
		assert_int(str(quest["stages"][stage_id]["journal"]).length()).override_failure_message("'%s' is short enough for the log" % stage_id).is_less_equal(150)
	Quests.runner.start(QUEST)
	assert_array(Quests.runner.objectives(QUEST).map(func(objective: Dictionary) -> bool: return objective["done"])).is_equal([false, false])
	GameState.add_item(&"wisp_ember", 3)
	assert_array(Quests.runner.objectives(QUEST).map(func(objective: Dictionary) -> bool: return objective["done"])).is_equal([true, false])
	assert_bool(GameState.get_flag(LANTERNS) == true).override_failure_message("not until they are handed over").is_false()


func test_a_save_from_before_henrik_loads_with_him_a_stranger_and_the_lanterns_dark() -> void:
	DirAccess.make_dir_recursive_absolute(SaveSystem.SAVE_DIR)
	SaveSystem._write_text(SaveSystem.slot_path(TEST_SLOT), FileAccess.get_file_as_string(OLD_SAVE))
	assert_int(SaveSystem.load_game()).is_equal(OK)
	assert_int(GameState.friend_points(&"old_henrik")).is_equal(0)
	assert_int(GameState.friend_marks(&"old_henrik")).is_equal(0)
	assert_that(Quests.runner.status(QUEST)).is_equal(QuestState.NOT_STARTED)
	assert_bool(GameState.knows_recipe(&"ember_tea")).is_false()
	assert_bool(GameState.knows_recipe(&"marsh_stew")).override_failure_message("the stew is known to everyone").is_true()
	var marsh: AreaController = _marsh("22:00")
	assert_bool(marsh.lanterns_are_lit()).is_false()
	assert_int(_posts(marsh.get_node(^"Decor"), GreyboxTiles.LANTERN_DARK)).is_equal(POSTS)
	# Friendship with him goes through a save like anyone's.
	GameState.add_friendship(&"old_henrik", 9)
	GameState.set_flag(LANTERNS, true)
	assert_int(SaveSystem.save_game()).is_equal(OK)
	GameState.new_game()
	assert_int(SaveSystem.load_game()).is_equal(OK)
	assert_int(GameState.friend_points(&"old_henrik")).is_equal(9)
	assert_bool(GameState.get_flag(LANTERNS) == true).is_true()


## Willowmere at `hour`, the hero on the hut's island.
func _marsh(hour: String) -> AreaController:
	GameState.set_time(float(GameState.day_clock().in_day(hour)))
	GameState.update_player(&"willowmere", Vector2i(21, 14))
	return _load(MARSH)


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area as AreaController


## Stands the hero before Henrik and starts talking.
func _talk(area: AreaController) -> void:
	Steps.stand_before(area, "OldHenrik")
	assert_bool(area.interact()).override_failure_message("talk to Henrik").is_true()


## Stands the hero at his hearth and opens it.
func _cook(home: AreaController) -> void:
	var hearth: Hearth = home.interactables.get_node(^"Hearth")
	home.player.motor.place(hearth.cell() + Vector2i.DOWN)
	home.player.face(Vector2.UP)
	assert_bool(home.interact()).is_true()


## Picks the answer that reads `text` in the open conversation.
func _say(area: AreaController, text: String) -> void:
	var box: DialogueBox = area.hud.dialogue
	var index: int = box.shown_options().find(text)
	assert_int(index).override_failure_message("no answer '%s' among %s" % [text, box.shown_options()]).is_greater_equal(0)
	box.move_cursor(index - box.selected)
	box.confirm()


## How many posts on `decor` wear the picture `kind`.
func _posts(decor: TileMapLayer, kind: String) -> int:
	return decor.get_used_cells_by_id(GreyboxTiles.SOURCE_ID, GreyboxTiles.coords(kind)).size()


## How many of the area's glows right now are a marsh lantern's.
func _lantern_glows(area: AreaController) -> int:
	var points: Array[Vector2] = Ambience.lantern_points(area.get_node(^"Decor"))
	var count: int = 0
	for glow: Dictionary in area.glows_now():
		if points.has(glow["at"]):
			count += 1
	return count


## Puts `wisp` at `point` (area px), resting.
func _put(wisp: Enemy, point: Vector2) -> void:
	wisp.body.position = point
	wisp.body.cell = GridBody.cell_of(point)
	wisp.position = point
	wisp.brain.change_state(WispBrain.REST)
