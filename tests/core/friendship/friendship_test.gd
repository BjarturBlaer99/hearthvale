extends GdUnitTestSuite
## Friendship (P4c), pure: the marks points make, what a talk and a gift are worth, what can
## be given, who likes what, the answer added to a conversation, and the checks on the rules
## and the villagers. The game's own data is the plan's.

const DataRegistryScript: GDScript = preload("res://autoload/data_registry.gd")

## The plan's table (docs/progress/P4-plan.md, section 5): villager id -> what they like.
const LIKES: Dictionary = {
	"elder_bram": ["vegetable_stew", "blossom_tea"],
	"wenna": ["cherry_blossom", "blossom_tea"],
	"tilda": ["pumpkin_pie", "wheat"],
	"farmer_oda": ["bread", "pumpkin"],
	"pip": ["wild_berries", "pumpkin_pie"],
	"guard_rolf": ["bread", "mushroom_soup"],
	"shepherd_edda": ["mushroom_soup", "carrot"],
}
const TALK: Dictionary = {
	"id": "pip", "start": "hello",
	"nodes": {
		"hello": {"speaker": "pip", "text": "Hello.", "options": [{"text": "Anything else?", "next": "more"}, {"text": "Goodbye.", "next": null}]},
		"more": {"speaker": "pip", "text": "No.", "options": [{"text": "Back.", "next": "hello"}]},
		"sign": {"speaker": "", "text": "A sign.", "options": []},
	},
}

var _rules: Friendship


func before_test() -> void:
	_rules = Friendship.new(DataRegistry.get_rules(DataRegistry.RULES_FRIENDSHIP))


func test_the_games_rules_are_the_plans() -> void:
	assert_int(_rules.marks).is_equal(5)
	assert_int(_rules.points_per_mark).is_equal(4)
	assert_int(_rules.max_points()).is_equal(20)
	assert_int(_rules.talk).is_equal(1)
	assert_int(_rules.liked_gift).is_equal(3)
	assert_int(_rules.other_gift).is_equal(1)
	assert_array(_rules.gift_types).is_equal(["food", "ingredient"])
	assert_int(_rules.gift_points(true)).is_equal(3)
	assert_int(_rules.gift_points(false)).is_equal(1)


func test_four_points_make_a_mark_up_to_five() -> void:
	for case: Array in [[-3, 0], [0, 0], [3, 0], [4, 1], [7, 1], [8, 2], [12, 3], [16, 4], [19, 4], [20, 5], [99, 5]]:
		assert_int(_rules.marks_at(case[0])).override_failure_message("%d points" % case[0]).is_equal(case[1])
	assert_int(_rules.after(0, 3)).is_equal(3)
	assert_int(_rules.after(19, 3)).override_failure_message("never over a full friendship").is_equal(20)
	assert_int(_rules.after(2, -5)).override_failure_message("never under nothing").is_equal(0)
	assert_str(_rules.mark_words("Pip", 2)).is_equal("Pip: friendship 2 of 5.")


func test_food_and_what_is_cooked_with_can_be_given_and_nothing_else() -> void:
	for id: StringName in [&"wild_berries", &"bread", &"vegetable_stew", &"turnip", &"wheat", &"cherry_blossom"]:
		assert_bool(_rules.is_giftable(DataRegistry.get_item(id))).override_failure_message(String(id)).is_true()
	for id: StringName in [&"hoe", &"watering_can", &"turnip_seeds", &"coin", &"wooden_sword", &"arrow", &"weavers_shuttle", &"water"]:
		assert_bool(_rules.is_giftable(DataRegistry.get_item(id))).override_failure_message(String(id)).is_false()
	assert_bool(_rules.is_giftable({})).is_false()


func test_what_can_be_given_is_listed_in_the_packs_own_order() -> void:
	var stacks: Array = [
		{"id": "hoe", "count": 1}, {"id": "bread", "count": 2}, {"id": "cherry_blossom", "count": 3},
		{"id": "coin", "count": 40}, {"id": "turnip", "count": 1}, {"id": "turnip_seeds", "count": 5}, {"id": "wheat", "count": 0},
	]
	var held: Array[Dictionary] = _rules.giftable_held(stacks, DataRegistry.entries(&"items"))
	assert_array(held.map(func(item: Dictionary) -> String: return str(item["id"]))).is_equal(["bread", "cherry_blossom", "turnip"])
	assert_array(_rules.giftable_held([], DataRegistry.entries(&"items"))).is_empty()
	assert_array(Friendship.new().giftable_held(stacks, DataRegistry.entries(&"items"))).override_failure_message("no rules: nothing can be given").is_empty()


func test_the_seven_villagers_like_what_the_plan_says() -> void:
	var villagers: Array = DataRegistry.entries(&"villagers")
	assert_int(villagers.size()).is_equal(7)
	var theirs: Array = []
	for villager: Dictionary in villagers:
		var id: String = str(villager["id"])
		assert_bool(LIKES.has(id)).override_failure_message(id).is_true()
		assert_array(villager["likes"]).override_failure_message("%s likes" % id).is_equal(LIKES[id])
		for liked: String in LIKES[id]:
			assert_bool(Friendship.likes(villager, liked)).is_true()
		assert_bool(Friendship.likes(villager, "turnip")).override_failure_message("nobody is fond of a raw turnip").is_false()
		assert_bool(theirs.has(villager["dialogue"])).override_failure_message("%s has a conversation of their own" % id).is_false()
		theirs.append(villager["dialogue"])
		assert_dict(Friendship.villager_of(villagers, str(villager["dialogue"]))).is_equal(villager)
		for liked: bool in [true, false]:
			var words: String = Friendship.thanks(villager, liked)
			assert_str(words).override_failure_message("%s says something of their own" % id).starts_with(str(villager["name"]) + ": ")
			assert_int(words.length()).override_failure_message("'%s' fits the message line" % words).is_less_equal(64)
		assert_str(Friendship.thanks(villager, true)).is_not_equal(Friendship.thanks(villager, false))
		# A full friendship has a line of its own, the same whether they like the gift or not.
		var full: String = Friendship.thanks(villager, true, true)
		assert_str(full).override_failure_message("%s says something of their own to a full friendship" % id).starts_with(str(villager["name"]) + ": ")
		assert_str(full).is_equal(Friendship.thanks(villager, false, true))
		assert_str(full).is_not_equal(Friendship.thanks(villager, true)).is_not_equal(Friendship.thanks(villager, false))
		assert_str(full).override_failure_message("%s's own words, not the plain ones" % id).is_not_equal("%s: Thank you." % villager["name"])
		assert_int(full.length()).override_failure_message("'%s' fits the message line" % full).is_less_equal(64)
	assert_dict(Friendship.villager_of(villagers, "sign_welcome")).is_empty()
	assert_dict(Friendship.villager_of(villagers, "")).is_empty()
	assert_str(Friendship.thanks({"name": "Someone"}, true)).override_failure_message("words missing: plain thanks").is_equal("Someone: Thank you.")
	assert_str(Friendship.thanks({"name": "Someone", "thanks": {"liked": "Yes!", "other": "Thanks."}}, true, true)).override_failure_message("no line for a full friendship: plain thanks").is_equal("Someone: Thank you.")


func test_a_friendship_is_full_at_its_last_mark() -> void:
	assert_bool(_rules.is_full(_rules.max_points())).is_true()
	assert_bool(_rules.is_full(_rules.max_points() + 3)).is_true()
	assert_bool(_rules.is_full(_rules.max_points() - 1)).override_failure_message("five marks need every point").is_false()
	assert_bool(_rules.is_full(0)).is_false()
	assert_int(_rules.marks_at(_rules.max_points())).is_equal(_rules.marks)


func test_a_day_is_remembered_for_the_talk_and_for_the_gift() -> void:
	var friend: Dictionary = {"points": 5, "talked": 3, "gift": 2}
	assert_bool(Friendship.talked_on(friend, 3)).is_true()
	assert_bool(Friendship.talked_on(friend, 4)).is_false()
	assert_bool(Friendship.given_on(friend, 2)).is_true()
	assert_bool(Friendship.given_on(friend, 3)).is_false()
	assert_bool(Friendship.talked_on({}, 1) or Friendship.given_on({}, 1)).override_failure_message("a stranger").is_false()


func test_the_answer_that_gives_is_added_before_the_goodbye() -> void:
	var before: String = JSON.stringify(TALK)
	var with: Dictionary = Friendship.with_gift_answer(TALK, "hello", "pip")
	var answers: Array = with["nodes"]["hello"]["options"]
	assert_array(answers.map(func(answer: Dictionary) -> String: return str(answer["text"]))).is_equal(["Anything else?", Friendship.GIVE_WORDS, "Goodbye."])
	assert_dict(answers[1]).is_equal({"text": "I brought you something.", "effects": [{"type": "gift", "villager": "pip"}], "next": null})
	assert_str(JSON.stringify(TALK)).override_failure_message("the conversation it was given is left as it was").is_equal(before)
	assert_int((with["nodes"]["more"]["options"] as Array).size()).override_failure_message("only where it begins").is_equal(1)
	# A node whose last answer goes on somewhere: after it.
	var on: Array = Friendship.with_gift_answer(TALK, "more", "pip")["nodes"]["more"]["options"]
	assert_array(on.map(func(answer: Dictionary) -> String: return str(answer["text"]))).is_equal(["Back.", Friendship.GIVE_WORDS])
	# A node with nothing to answer gets it as its only answer; a node there isn't changes nothing.
	assert_int((Friendship.with_gift_answer(TALK, "sign", "pip")["nodes"]["sign"]["options"] as Array).size()).is_equal(1)
	assert_str(JSON.stringify(Friendship.with_gift_answer(TALK, "nowhere", "pip"))).is_equal(before)
	assert_str(JSON.stringify(Friendship.with_gift_answer({}, "hello", "pip"))).is_equal("{}")


func test_rules_that_cant_be_used_say_why() -> void:
	var good: Dictionary = {"marks": 5, "points_per_mark": 4, "talk": 1, "liked_gift": 3, "other_gift": 1, "gift_types": ["food"]}
	var types: Array = ["food", "tool"]
	assert_array(Array(Friendship.problems(good, types))).is_empty()
	var cases: Array = [
		[{"marks": 0}, "'marks' must be a whole number of 1 or more."],
		[{"points_per_mark": 2.5}, "'points_per_mark' must be a whole number of 1 or more."],
		[{"talk": -1}, "'talk' must be a whole number of 0 or more."],
		[{"liked_gift": "lots"}, "'liked_gift' must be a whole number of 0 or more."],
		[{"liked_gift": 1, "other_gift": 2}, "'liked_gift' must be at least 'other_gift': a gift they like is worth no less."],
		[{"gift_types": []}, "'gift_types' must list the item types that can be given."],
		[{"gift_types": ["food", "treasure"]}, "'gift_types' names an item type no item has: 'treasure'."],
	]
	for case: Array in cases:
		var rules: Dictionary = good.duplicate(true)
		rules.merge(case[0], true)
		assert_array(Array(Friendship.problems(rules, types))).override_failure_message("%s" % [case[0]]).contains([case[1]])
	# No rules at all still make something that can be asked: no marks to speak of, nothing to give.
	var none: Friendship = Friendship.new()
	assert_int(none.marks_at(100)).is_equal(1)
	assert_int(none.gift_points(true)).is_equal(0)


func test_a_villager_that_cant_be_used_says_why() -> void:
	var item_of: Callable = func(id: String) -> Dictionary: return DataRegistry.get_item(StringName(id))
	var has_dialogue: Callable = func(id: String) -> bool: return id == "pip"
	var good: Dictionary = {"id": "pip", "name": "Pip", "dialogue": "pip", "likes": ["wild_berries"], "thanks": {"liked": "Yes!", "other": "Thanks.", "full": "Again?"}}
	assert_array(Array(_rules.villager_problems(good, item_of, has_dialogue))).is_empty()
	var cases: Array = [
		[{"name": ""}, "'name' must be the villager's name."],
		[{"dialogue": "nobody"}, "'dialogue' names an unknown conversation 'nobody'."],
		[{"likes": "berries"}, "'likes' must list the items they like (it may be empty)."],
		[{"likes": ["moonbeams"]}, "'likes' names an unknown item id 'moonbeams'."],
		[{"likes": ["hoe"]}, "'likes' names 'hoe', which can't be given (its type is 'tool')."],
		[{"thanks": "Thanks."}, "'thanks' must be an object: what they say to a gift they 'liked', to any 'other', and once the friendship is 'full'."],
		[{"thanks": {"liked": "Yes!", "full": "Again?"}}, "'thanks' needs 'other': what they say to such a gift."],
		[{"thanks": {"liked": "Yes!", "other": "Thanks."}}, "'thanks' needs 'full': what they say to such a gift."],
		[{"thanks": {"liked": "Yes!", "other": "Thanks.", "full": ""}}, "'thanks' needs 'full': what they say to such a gift."],
	]
	for case: Array in cases:
		var villager: Dictionary = good.duplicate(true)
		villager.merge(case[0], true)
		assert_array(Array(_rules.villager_problems(villager, item_of, has_dialogue))).override_failure_message("%s" % [case[0]]).contains([case[1]])
	var likes_nothing: Dictionary = good.duplicate(true)
	likes_nothing["likes"] = []
	assert_array(Array(_rules.villager_problems(likes_nothing, item_of, has_dialogue))).override_failure_message("a villager may like nothing in particular").is_empty()


func test_bad_friendship_data_is_refused_on_load() -> void:
	var registry: Node = auto_free(DataRegistryScript.new())
	var errors: String = "\n".join(registry.load_all("res://tests/fixtures/bad_friends"))
	assert_str(errors).contains("rules 'friendship': 'points_per_mark' must be a whole number of 1 or more.")
	assert_str(errors).contains("villager 'stranger' is missing required field 'thanks'.")
	assert_str(errors).contains("villager 'miller': 'dialogue' names an unknown conversation 'nobody'.")
	assert_str(errors).contains("villager 'miller': 'likes' names an unknown item id 'moonbeams'.")
	assert_str(errors).contains("villager 'twin' has the conversation 'baker', which villager 'baker' has already.")
	assert_str(errors).contains("villager 'forgetful': 'thanks' needs 'full': what they say to such a gift.")
	assert_str(errors).contains("effect 'gift' is missing 'villager'.")
	assert_str(errors).contains("refers to unknown villager id 'nobody'.")
	assert_bool(errors.contains("villager 'baker':")).override_failure_message("a good villager is let through").is_false()
	# The game's own data loads clean.
	assert_bool(DataRegistry.RULE_SETS.has(DataRegistry.RULES_FRIENDSHIP)).is_true()
	assert_dict(DataRegistry.get_villager(&"pip")).is_not_empty()
	assert_array(Array(DataRegistry.errors)).is_empty()


func test_three_marks_make_a_friend() -> void:
	assert_int(_rules.friend_marks).is_equal(3)
	var friends: Dictionary = {
		&"pip": {"points": 12, "talked": 1, "gift": 1}, &"wenna": {"points": 20}, &"tilda": {"points": 11},
		&"guard_rolf": {"points": 0}, &"someone_else": {"points": 20},
	}
	var villagers: Array = [&"pip", &"wenna", &"tilda", &"guard_rolf", &"elder_bram"]
	assert_int(_rules.friends_among(friends, villagers)).override_failure_message("twelve points and twenty; eleven is one short").is_equal(2)
	assert_int(_rules.friends_among({}, villagers)).is_equal(0)
	assert_int(_rules.friends_among(friends, [])).is_equal(0)
	# A save's friends are keyed by text, the game's by name: both are counted.
	assert_int(_rules.friends_among({"pip": {"points": 12.0}}, ["pip"])).is_equal(1)
	assert_int(_rules.friends_among({"pip": {"points": 12}}, [&"pip"])).is_equal(1)
	# The rule is data, and must be a number of marks there can be.
	assert_int(Friendship.new({"marks": 5, "points_per_mark": 4, "friend_marks": 5}).friends_among(friends, villagers)).is_equal(1)
	assert_int(Friendship.new({"marks": 5, "points_per_mark": 4}).friend_marks).override_failure_message("left out: only a full friendship counts").is_equal(5)
	var good: Dictionary = {"marks": 5, "points_per_mark": 4, "talk": 1, "liked_gift": 3, "other_gift": 1, "gift_types": ["food"], "friend_marks": 3}
	assert_array(Array(Friendship.problems(good, ["food"]))).is_empty()
	for bad: Variant in [0, 6, 2.5, "three"]:
		var rules: Dictionary = good.duplicate(true)
		rules["friend_marks"] = bad
		assert_array(Array(Friendship.problems(rules, ["food"]))).override_failure_message(str(bad)).contains(["'friend_marks' must be a whole number from 1 to 'marks': the marks that make a friend."])
