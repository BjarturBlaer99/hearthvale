extends GdUnitTestSuite
## Friendship in the world (P4c): talking to a villager is worth a point once a day; with
## something to give, their conversation gains the answer that opens the list of what he
## carries; a gift is given from it, the villager says their words, and a mark gained is said
## at the top of the screen with a chime; one gift a villager a day; and the pause menu's
## Friends page shows every villager's marks. No conversation file is changed for any of it.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const VILLAGE: String = "res://world/areas/village/village.tscn"
const HOME: String = "res://world/areas/home/home.tscn"
const SHOP: String = "res://world/areas/shop/shop.tscn"
const ELDER_HOUSE: String = "res://world/areas/elder_house/elder_house.tscn"
const TEST_SLOT: int = 974

var _area: Node
var _heard: Array[StringName] = []


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	GameState.set_time(float(GameState.day_clock().in_day("12:00")))
	SaveSystem.current_slot = TEST_SLOT
	# The main quest begins with the game, with a chime: before these tests listen.
	Quests.refresh()
	_heard.clear()
	EventBus.sound.connect(_on_sound)


func after_test() -> void:
	EventBus.sound.disconnect(_on_sound)
	if is_instance_valid(_area):
		_area.free()
	_area = null
	get_tree().paused = false
	if SaveSystem.has_slot(TEST_SLOT):
		DirAccess.remove_absolute(SaveSystem.slot_path(TEST_SLOT))
	SaveSystem.current_slot = SaveSystem.GAME_SLOT
	GameState.clear()


func test_talking_to_a_villager_is_worth_a_point_once_a_day() -> void:
	var village: AreaController = _load(VILLAGE)
	_talk(village, "Pip")
	assert_int(GameState.friend_points(&"pip")).is_equal(1)
	_say(village, "Goodbye.")
	_talk(village, "Pip")
	_say(village, "Goodbye.")
	assert_int(GameState.friend_points(&"pip")).override_failure_message("a second talk the same day").is_equal(1)
	_talk(village, "FarmerOda")
	_say(village, "Goodbye.")
	assert_int(GameState.friend_points(&"farmer_oda")).is_equal(1)
	GameState.start_next_day()
	GameState.set_time(float(GameState.day_clock().in_day("12:00")))
	_talk(village, "Pip")
	_say(village, "Goodbye.")
	assert_int(GameState.friend_points(&"pip")).is_equal(2)
	# A sign is no friend, however often it is read.
	var sign: Talkable = village.interactables.get_node(^"WelcomeSign")
	assert_dict(village.villager_of(sign)).is_empty()
	assert_dict(village.villager_of(village.interactables.get_node(^"Pip"))).is_equal(DataRegistry.get_villager(&"pip"))
	assert_int(GameState.friends.size()).override_failure_message("only the two he talked to").is_equal(2)


func test_with_nothing_to_give_a_conversation_is_the_files_own() -> void:
	GameState.add_item(&"hoe")
	GameState.add_item(&"turnip_seeds", 5)
	GameState.add_item(&"coin", 30)
	var village: AreaController = _load(VILLAGE)
	_talk(village, "Pip")
	assert_array(Array(village.hud.dialogue.shown_options())).override_failure_message("tools, seeds and coins are not gifts").is_equal(["Anything else?", "Goodbye."])
	_say(village, "Goodbye.")


func test_with_something_to_give_the_answer_is_there_and_opens_the_list() -> void:
	var file_before: String = JSON.stringify(DataRegistry.get_dialogue(&"pip"))
	for item: Array in [[&"hoe", 1], [&"bread", 2], [&"cherry_blossom", 3], [&"coin", 12], [&"wild_berries", 4], [&"turnip_seeds", 2]]:
		GameState.add_item(item[0], item[1])
	var village: AreaController = _load(VILLAGE)
	_talk(village, "Pip")
	var box: DialogueBox = village.hud.dialogue
	assert_array(Array(box.shown_options())).is_equal(["Anything else?", Friendship.GIVE_WORDS, "Goodbye."])
	assert_str(JSON.stringify(DataRegistry.get_dialogue(&"pip"))).override_failure_message("the conversation's data is as its file has it").is_equal(file_before)
	# The answer is only where the conversation begins.
	_say(village, "Anything else?")
	assert_bool(Array(box.shown_options()).has(Friendship.GIVE_WORDS)).is_false()
	_say(village, "Goodbye.")

	_talk(village, "Pip")
	_say(village, Friendship.GIVE_WORDS)
	assert_bool(village.is_talking()).override_failure_message("the words are done").is_false()
	var list: GiftMenu = village.hud.gift_menu
	assert_bool(list.is_open()).is_true()
	assert_bool(village.is_in_menu()).is_true()
	assert_bool(village.clock_runs()).override_failure_message("the clock waits while he chooses").is_false()
	assert_bool(village.player.controls_enabled).override_failure_message("and he stands still").is_false()
	assert_str(list.title_text()).is_equal("A gift for Pip")
	assert_array(Array(list.shown_lines())).override_failure_message("food and what is cooked with, in his pack's order").is_equal([
		"> Bread x2", "  Cherry Blossoms x3", "  Wild Berries x4",
	])
	# Leaving the list gives nothing, and the day's gift is still to give.
	list.close()
	assert_bool(village.player.controls_enabled).is_true()
	assert_bool(GameState.can_give(&"pip")).is_true()
	assert_int(GameState.item_count(&"bread") + GameState.item_count(&"cherry_blossom") + GameState.item_count(&"wild_berries")).is_equal(9)


func test_a_gift_is_given_and_a_mark_gained_is_said_once() -> void:
	GameState.add_item(&"bread", 2)
	GameState.add_item(&"wild_berries", 4)
	var village: AreaController = _load(VILLAGE)
	_talk(village, "Pip")
	_say(village, Friendship.GIVE_WORDS)
	var list: GiftMenu = village.hud.gift_menu
	list.move_cursor(1)
	_heard.clear()
	assert_bool(list.confirm()).is_true()
	assert_bool(list.is_open()).override_failure_message("one gift, and the list closes").is_false()
	assert_bool(village.player.controls_enabled).is_true()
	assert_int(GameState.item_count(&"wild_berries")).is_equal(3)
	assert_int(GameState.item_count(&"bread")).is_equal(2)
	# A point for the day's first talk and three for berries, which he likes: a first mark.
	assert_int(GameState.friend_points(&"pip")).is_equal(4)
	assert_str(village.hud.message_text()).is_equal("Pip: For me? This is the best thing ever!")
	assert_str(village.hud.notice_text()).is_equal("Pip: friendship 1 of 5.")
	assert_array(_heard.filter(func(id: StringName) -> bool: return id == &"friend")).override_failure_message("one chime").has_size(1)

	# He has had his gift for today: the answer is gone.
	_talk(village, "Pip")
	assert_array(Array(village.hud.dialogue.shown_options())).is_equal(["Anything else?", "Goodbye."])
	_say(village, "Goodbye.")
	# Someone else can still be given something; bread is nothing special to Pip but Oda likes it.
	_heard.clear()
	_talk(village, "FarmerOda")
	_say(village, Friendship.GIVE_WORDS)
	assert_array(Array(list.shown_lines())).is_equal(["> Bread x2", "  Wild Berries x3"])
	assert_bool(list.confirm()).is_true()
	assert_str(village.hud.message_text()).is_equal("Farmer Oda: That's the stuff. You know a farmer's heart.")
	assert_int(GameState.friend_points(&"farmer_oda")).override_failure_message("one for the talk and three for the bread").is_equal(4)
	# Tomorrow Pip can be given something again, and berries he doesn't much care for... he does.
	GameState.start_next_day()
	GameState.set_time(float(GameState.day_clock().in_day("12:00")))
	_talk(village, "Pip")
	_say(village, Friendship.GIVE_WORDS)
	assert_bool(list.confirm()).is_true()
	assert_str(village.hud.message_text()).override_failure_message("bread is the first line now, and nothing special to him").is_equal("Pip: Thanks! Mum says to say thanks.")
	assert_int(GameState.friend_points(&"pip")).is_equal(4 + 1 + 1)


func test_the_answer_is_added_where_each_conversation_begins() -> void:
	GameState.add_item(&"blossom_tea", 2)
	# Elder Bram greets a newcomer with other words: the answer is there too.
	var house: AreaController = _load(ELDER_HOUSE)
	_talk(house, "Bram")
	assert_array(Array(house.hud.dialogue.shown_options())).is_equal(["What should I do first?", Friendship.GIVE_WORDS, "Goodbye."])
	_say(house, Friendship.GIVE_WORDS)
	assert_str(house.hud.gift_menu.title_text()).is_equal("A gift for Elder Bram")
	assert_bool(house.hud.gift_menu.confirm()).is_true()
	assert_str(house.hud.message_text()).is_equal("Elder Bram: Ah, my favourite. You spoil an old man.")
	# Tilda's has four answers of its own and scrolls; her list still opens from it.
	var shop: AreaController = _load(SHOP)
	_talk(shop, "Tilda")
	assert_array(Array(shop.hud.dialogue.shown_options())).is_equal(["Let me see what you sell.", "I have crops to sell.", Friendship.GIVE_WORDS, "Just looking."])
	_say(shop, "Let me see what you sell.")
	assert_bool(shop.hud.shop_menu.is_open()).is_true()
	assert_bool(shop.hud.gift_menu.is_open()).is_false()
	shop.hud.shop_menu.close()
	# The hearth and the bed are nobody: nothing to give them.
	var home: AreaController = _load(HOME)
	var hearth: Hearth = home.interactables.get_node(^"Hearth")
	home.player.motor.place(hearth.cell() + Vector2i.DOWN)
	home.player.face(Vector2.UP)
	assert_bool(home.interact()).is_true()
	assert_bool(Array(home.hud.dialogue.shown_options()).has(Friendship.GIVE_WORDS)).is_false()
	assert_dict(home.villager_of(hearth)).is_empty()


func test_the_pause_menu_has_a_friends_page_with_every_villagers_marks() -> void:
	GameState.add_friendship(&"pip", 9)
	GameState.add_friendship(&"wenna", 20)
	GameState.add_friendship(&"guard_rolf", 3)
	var village: AreaController = _load(VILLAGE)
	assert_bool(village.open_pause_menu()).is_true()
	var menu: PauseMenu = village.hud.pause_menu
	assert_bool(Array(menu.shown_lines()).has("  Friends")).is_true()
	menu.choose(PauseMenu.FRIENDS)
	var page: FriendsPage = menu.friends_page
	assert_bool(page.is_open()).is_true()
	assert_array(Array(page.shown_lines())).override_failure_message("everyone, by name").is_equal([
		"Elder Bram 0/5", "Farmer Oda 0/5", "Guard Rolf 0/5", "Pip 2/5", "Shepherd Edda 0/5", "Tilda 0/5", "Wenna 5/5",
	])
	var blossoms: Array[FriendMarks] = page.shown_marks()
	assert_int(blossoms.size()).is_equal(7)
	assert_array(blossoms.map(func(marks: FriendMarks) -> int: return marks.earned)).is_equal([0, 0, 0, 2, 0, 0, 5])
	for marks: FriendMarks in blossoms:
		assert_int(marks.out_of).is_equal(5)
	assert_bool(get_tree().paused).override_failure_message("the game waits behind it").is_true()
	# Back to the pause menu, and opened again it has not doubled its rows.
	page.close()
	assert_bool(menu.is_open()).is_true()
	menu.choose(PauseMenu.FRIENDS)
	assert_int(page.shown_marks().size()).is_equal(7)
	menu.resume()
	assert_bool(page.is_open()).override_failure_message("resuming closes it").is_false()
	assert_bool(get_tree().paused).is_false()


func test_the_chime_is_a_sound_the_game_has() -> void:
	assert_bool(Audio.SFX.has(&"friend")).is_true()
	assert_bool(ResourceLoader.exists("res://audio/sfx/friend.wav")).is_true()
	var tool: Dictionary = (load("res://tools/audio/make_audio.gd") as GDScript).get_script_constant_map()
	assert_bool((tool["SFX"] as Array).has("friend")).override_failure_message("made by the audio tool").is_true()


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


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area


func _on_sound(id: StringName) -> void:
	_heard.append(id)
