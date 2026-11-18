extends GdUnitTestSuite
## Friendship in the game's state (P4c): the first talk of a day is worth a point; a gift is
## worth three if it is liked and one if not, once a villager a day; a mark gained is said
## once; friendship goes through a save, and a game saved before it has no friends yet.

const TEST_SLOT: int = 975
const OLD_SAVE: String = "res://tests/fixtures/saves/v3_in_the_keep.json"

var _marks: Array = []


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	_marks.clear()
	EventBus.friend_mark_gained.connect(_on_mark_gained)


func after_test() -> void:
	EventBus.friend_mark_gained.disconnect(_on_mark_gained)
	GameState.clear()
	SaveSystem.current_slot = SaveSystem.GAME_SLOT
	SaveSystem.erase_slot(TEST_SLOT)


func test_a_new_game_has_no_friends_yet() -> void:
	assert_bool(GameState.friends.is_empty()).is_true()
	for villager: Dictionary in DataRegistry.entries(&"villagers"):
		var id: StringName = StringName(str(villager["id"]))
		assert_int(GameState.friend_points(id)).is_equal(0)
		assert_int(GameState.friend_marks(id)).is_equal(0)
		assert_bool(GameState.can_give(id)).override_failure_message("anyone can be given something today").is_true()
	assert_bool(GameState.friends.is_empty()).override_failure_message("asking makes no record").is_true()


func test_the_first_talk_of_a_day_is_worth_a_point() -> void:
	assert_int(GameState.greet(&"pip")).is_equal(1)
	assert_int(GameState.friend_points(&"pip")).is_equal(1)
	assert_int(GameState.greet(&"pip")).override_failure_message("a second talk the same day").is_equal(0)
	assert_int(GameState.greet(&"pip")).is_equal(0)
	assert_int(GameState.friend_points(&"pip")).is_equal(1)
	assert_int(GameState.greet(&"farmer_oda")).override_failure_message("each villager has their own day").is_equal(1)
	GameState.start_next_day()
	assert_int(GameState.greet(&"pip")).is_equal(1)
	assert_int(GameState.friend_points(&"pip")).is_equal(2)
	assert_dict(GameState.friends[&"pip"]).is_equal({"points": 2, "talked": 2, "gift": 0})


func test_only_a_villager_can_be_a_friend() -> void:
	assert_int(GameState.greet(&"sign_welcome")).is_equal(0)
	assert_int(GameState.add_friendship(&"the_bed", 5)).is_equal(0)
	assert_bool(GameState.can_give(&"hearth")).is_false()
	GameState.add_item(&"bread")
	assert_dict(GameState.give_gift(&"nobody", &"bread")).is_empty()
	assert_int(GameState.item_count(&"bread")).is_equal(1)
	assert_bool(GameState.friends.is_empty()).is_true()


func test_a_gift_they_like_is_worth_three_and_any_other_one() -> void:
	GameState.add_item(&"wild_berries", 2)
	GameState.add_item(&"turnip", 2)
	assert_dict(GameState.give_gift(&"pip", &"wild_berries")).is_equal({"liked": true, "points": 3, "full": false})
	assert_int(GameState.item_count(&"wild_berries")).override_failure_message("it has left his pack").is_equal(1)
	assert_int(GameState.friend_points(&"pip")).is_equal(3)
	assert_dict(GameState.give_gift(&"farmer_oda", &"turnip")).is_equal({"liked": false, "points": 1, "full": false})
	assert_int(GameState.item_count(&"turnip")).is_equal(1)
	assert_int(GameState.friend_points(&"farmer_oda")).is_equal(1)
	# The same thing is liked by one and not by another.
	GameState.start_next_day()
	assert_dict(GameState.give_gift(&"farmer_oda", &"wild_berries")).is_equal({"liked": false, "points": 1, "full": false})


func test_a_full_friendship_still_takes_a_gift_and_says_it_was_full() -> void:
	# The fix round of 2026-11-16: at five marks a gift was taken and nothing said of it.
	var most: int = GameState.friendship().max_points()
	GameState.add_friendship(&"pip", most - 1)
	GameState.add_item(&"wild_berries", 3)
	# One short of full: the gift fills it, and it was not full when it was given.
	assert_dict(GameState.give_gift(&"pip", &"wild_berries")).is_equal({"liked": true, "points": 1, "full": false})
	assert_int(GameState.friend_points(&"pip")).is_equal(most)
	# Full: the next day's gift is taken all the same, adds nothing, and says so.
	GameState.start_next_day()
	assert_bool(GameState.can_give(&"pip")).override_failure_message("a full friendship can still be given to").is_true()
	assert_dict(GameState.give_gift(&"pip", &"wild_berries")).is_equal({"liked": true, "points": 0, "full": true})
	assert_int(GameState.item_count(&"wild_berries")).override_failure_message("it has left his pack").is_equal(1)
	assert_int(GameState.friend_points(&"pip")).is_equal(most)
	assert_bool(GameState.can_give(&"pip")).override_failure_message("and it was the day's gift").is_false()


func test_one_gift_a_villager_a_day() -> void:
	GameState.add_item(&"wild_berries", 3)
	assert_bool(GameState.can_give(&"pip")).is_true()
	assert_dict(GameState.give_gift(&"pip", &"wild_berries")).is_not_empty()
	assert_bool(GameState.can_give(&"pip")).is_false()
	assert_dict(GameState.give_gift(&"pip", &"wild_berries")).override_failure_message("a second gift the same day").is_empty()
	assert_int(GameState.item_count(&"wild_berries")).override_failure_message("and it stays in his pack").is_equal(2)
	assert_int(GameState.friend_points(&"pip")).is_equal(3)
	assert_bool(GameState.can_give(&"guard_rolf")).override_failure_message("someone else can still be given something").is_true()
	GameState.start_next_day()
	assert_bool(GameState.can_give(&"pip")).is_true()
	assert_dict(GameState.give_gift(&"pip", &"wild_berries")).is_not_empty()
	assert_int(GameState.friend_points(&"pip")).is_equal(6)
	assert_dict(GameState.friends[&"pip"]).is_equal({"points": 6, "talked": 0, "gift": 2})


func test_what_isnt_held_or_cant_be_given_isnt_given() -> void:
	GameState.add_item(&"hoe")
	GameState.add_item(&"turnip_seeds", 3)
	GameState.add_item(&"coin", 20)
	for thing: StringName in [&"hoe", &"turnip_seeds", &"coin", &"bread", &"no_such_item"]:
		assert_dict(GameState.give_gift(&"pip", thing)).override_failure_message(String(thing)).is_empty()
	assert_bool(GameState.can_give(&"pip")).override_failure_message("a gift not given doesn't use up the day's").is_true()
	assert_int(GameState.item_count(&"hoe") + GameState.item_count(&"turnip_seeds") + GameState.item_count(&"coin")).is_equal(24)
	assert_array(GameState.gifts_held()).override_failure_message("he carries nothing that can be given").is_empty()
	GameState.add_item(&"cherry_blossom", 2)
	GameState.add_item(&"bread")
	assert_array(GameState.gifts_held().map(func(item: Dictionary) -> String: return str(item["id"]))).is_equal(["cherry_blossom", "bread"])


func test_a_mark_gained_is_said_once_and_five_marks_are_a_full_friendship() -> void:
	GameState.add_friendship(&"wenna", 3)
	assert_array(_marks).is_empty()
	GameState.add_friendship(&"wenna", 1)
	assert_array(_marks).is_equal([[&"wenna", 1]])
	assert_int(GameState.friend_marks(&"wenna")).is_equal(1)
	GameState.add_friendship(&"wenna", 3)
	assert_array(_marks).override_failure_message("seven points are still one mark").has_size(1)
	# A liked gift that crosses a mark says the mark it reached.
	GameState.add_item(&"cherry_blossom")
	GameState.give_gift(&"wenna", &"cherry_blossom")
	assert_array(_marks).is_equal([[&"wenna", 1], [&"wenna", 2]])
	# Twenty points and no more.
	assert_int(GameState.add_friendship(&"wenna", 50)).override_failure_message("only what there was room for").is_equal(10)
	assert_int(GameState.friend_points(&"wenna")).is_equal(20)
	assert_int(GameState.friend_marks(&"wenna")).is_equal(5)
	assert_array(_marks.back()).is_equal([&"wenna", 5])
	var said: int = _marks.size()
	GameState.start_next_day()
	assert_int(GameState.greet(&"wenna")).override_failure_message("a full friendship gains nothing more").is_equal(0)
	GameState.add_item(&"blossom_tea")
	assert_dict(GameState.give_gift(&"wenna", &"blossom_tea")).override_failure_message("but a gift is still a gift").is_equal({"liked": true, "points": 0, "full": true})
	assert_int(GameState.item_count(&"blossom_tea")).is_equal(0)
	assert_array(_marks).has_size(said)


func test_the_gift_effect_asks_for_the_list() -> void:
	var asked: Array = []
	var on_asked: Callable = func(villager: StringName) -> void: asked.append(villager)
	EventBus.gift_requested.connect(on_asked)
	assert_bool(EffectApplier.new(GameState).apply({"type": "gift", "villager": "pip"})).is_true()
	EventBus.gift_requested.disconnect(on_asked)
	assert_array(asked).is_equal([&"pip"])
	assert_bool(GameState.friends.is_empty()).override_failure_message("asking for the list gives nothing").is_true()


func test_friendship_goes_through_a_save() -> void:
	GameState.add_item(&"wild_berries")
	GameState.greet(&"pip")
	GameState.give_gift(&"pip", &"wild_berries")
	GameState.start_next_day()
	GameState.greet(&"elder_bram")
	GameState.update_player(&"village", Vector2i(23, 20))
	assert_int(SaveSystem.save_to_slot(TEST_SLOT)).is_equal(OK)
	var on_disk: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SaveSystem.slot_path(TEST_SLOT)))
	assert_dict(on_disk["friends"]).is_equal({
		"pip": {"points": 4.0, "talked": 1.0, "gift": 1.0}, "elder_bram": {"points": 1.0, "talked": 2.0, "gift": 0.0},
	})
	assert_int(int(on_disk["version"])).override_failure_message("friends have had their place since version 4; 5 came with the mine, 6 with the Homestead").is_equal(6)
	GameState.clear()
	assert_int(GameState.friend_points(&"pip")).override_failure_message("cleared").is_equal(0)
	assert_int(SaveSystem.load_from_slot(TEST_SLOT)).is_equal(OK)
	assert_int(GameState.friend_points(&"pip")).is_equal(4)
	assert_int(GameState.friend_marks(&"pip")).is_equal(1)
	assert_int(GameState.greet(&"elder_bram")).override_failure_message("he was talked to today, and the save remembers").is_equal(0)
	assert_int(GameState.greet(&"pip")).override_failure_message("Pip was talked to yesterday").is_equal(1)
	assert_bool(GameState.can_give(&"pip")).is_true()
	assert_array(_marks).override_failure_message("loading says nothing of the mark it already had").is_equal([[&"pip", 1]])


func test_a_game_saved_before_friendship_has_no_friends_yet() -> void:
	DirAccess.make_dir_recursive_absolute(SaveSystem.SAVE_DIR)
	var file: FileAccess = FileAccess.open(SaveSystem.slot_path(TEST_SLOT), FileAccess.WRITE)
	file.store_string(FileAccess.get_file_as_string(OLD_SAVE))
	file.close()
	assert_int(SaveSystem.load_from_slot(TEST_SLOT)).is_equal(OK)
	assert_bool(GameState.friends.is_empty()).is_true()
	assert_int(GameState.friend_marks(&"elder_bram")).is_equal(0)
	assert_bool(GameState.can_give(&"elder_bram")).is_true()
	assert_array(GameState.gifts_held().map(func(item: Dictionary) -> String: return str(item["id"]))).override_failure_message("what that hero carried").is_equal(["turnip", "bread"])


func _on_mark_gained(villager: StringName, marks: int) -> void:
	_marks.append([villager, marks])
