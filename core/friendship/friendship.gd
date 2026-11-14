class_name Friendship
extends RefCounted
## Friendship with the villagers (P4c, GDD §10), pure: what a talk and a gift are worth, how
## many marks points make, what can be given, and who likes what. The numbers are data
## (data/rules/friendship.json):
##   { "marks": 5, "points_per_mark": 4, "talk": 1, "liked_gift": 3, "other_gift": 1,
##     "gift_types": ["food", "ingredient"], "friend_marks": 3 }
## and so are the villagers (data/villagers/<id>.json):
##   { "id": "pip", "name": "Pip", "dialogue": "pip", "likes": ["wild_berries", "pumpkin_pie"],
##     "thanks": { "liked": "...", "other": "..." } }
## A villager is known by their conversation: no scene names them. It keeps no points itself:
## GameState holds each friend's points and the days he last talked to them and gave them
## something ({ "points", "talked", "gift" }), and asks this.

## The answer the game adds to a villager's conversation when there is something to give.
const GIVE_WORDS: String = "I brought you something."
## What a mark gained is announced with: the villager's name, their marks, the most there are.
const MARK_WORDS: String = "%s: friendship %d of %d."
## A villager's words on a gift, after their name.
const THANKS_WORDS: String = "%s: %s"
## The effect the added answer has: the area opens the list of what he carries.
const GIFT_EFFECT: String = "gift"

## How many marks a full friendship is, and the points that make one mark.
var marks: int = 1
var points_per_mark: int = 1
## The points for the first talk of a day, a gift they like, and any other gift.
var talk: int = 0
var liked_gift: int = 0
var other_gift: int = 0
## The item types that can be given.
var gift_types: Array[String] = []
## The marks at which a villager counts as a friend (the ending's count).
var friend_marks: int = 1


func _init(rules: Dictionary = {}) -> void:
	marks = maxi(_whole(rules.get("marks"), 1), 1)
	points_per_mark = maxi(_whole(rules.get("points_per_mark"), 1), 1)
	talk = maxi(_whole(rules.get("talk"), 0), 0)
	liked_gift = maxi(_whole(rules.get("liked_gift"), 0), 0)
	other_gift = maxi(_whole(rules.get("other_gift"), 0), 0)
	var types: Variant = rules.get("gift_types")
	if typeof(types) == TYPE_ARRAY:
		for type: Variant in types:
			gift_types.append(str(type))
	friend_marks = clampi(_whole(rules.get("friend_marks"), marks), 1, marks)


## The most points a friendship holds.
func max_points() -> int:
	return marks * points_per_mark


## The marks `points` make: 0 at the least, `marks` at the most.
func marks_at(points: int) -> int:
	@warning_ignore("integer_division")
	return clampi(points / points_per_mark, 0, marks)


## `points` after gaining `gain`: never under nothing, never over a full friendship.
func after(points: int, gain: int) -> int:
	return clampi(points + gain, 0, max_points())


## What a gift is worth: more if they like it.
func gift_points(liked: bool) -> int:
	return liked_gift if liked else other_gift


## Whether `item` (a data entry) is a thing that can be given.
func is_giftable(item: Dictionary) -> bool:
	return gift_types.has(str(item.get("type", "")))


## What `stacks` hold that can be given, looked up in `items` (data entries), in the order it
## was picked up.
func giftable_held(stacks: Array, items: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for type: String in gift_types:
		out.append_array(Inventory.held_of_type(stacks, items, type))
	if gift_types.size() < 2:
		return out
	# Back into the pack's own order: the types were gathered one after another.
	var order: Dictionary = {}
	for i: int in stacks.size():
		if typeof(stacks[i]) == TYPE_DICTIONARY:
			order[str((stacks[i] as Dictionary).get("id", ""))] = i
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		return int(order.get(str(a.get("id", "")), 0)) < int(order.get(str(b.get("id", "")), 0)))
	return out


## How many of `villager_ids` are friends: at `friend_marks` or more, by `friends` (villager id
## -> { "points", ... }, as GameState keeps them).
func friends_among(friends: Dictionary, villager_ids: Array) -> int:
	var count: int = 0
	for id: Variant in villager_ids:
		var friend: Variant = friends.get(id, friends.get(StringName(str(id)), friends.get(str(id))))
		if typeof(friend) == TYPE_DICTIONARY and marks_at(int((friend as Dictionary).get("points", 0))) >= friend_marks:
			count += 1
	return count


## "Pip: friendship 2 of 5."
func mark_words(villager_name: String, marks_now: int) -> String:
	return MARK_WORDS % [villager_name, marks_now, marks]


## Whether `villager` (a data entry) likes the item `item_id`.
static func likes(villager: Dictionary, item_id: String) -> bool:
	var liked: Variant = villager.get("likes")
	return typeof(liked) == TYPE_ARRAY and (liked as Array).has(item_id)


## The villager among `villagers` (data entries) whose conversation is `dialogue_id`, or {}.
static func villager_of(villagers: Array, dialogue_id: String) -> Dictionary:
	if dialogue_id.is_empty():
		return {}
	for villager: Variant in villagers:
		if typeof(villager) == TYPE_DICTIONARY and str((villager as Dictionary).get("dialogue", "")) == dialogue_id:
			return villager
	return {}


## Whether `friend` ({ "points", "talked", "gift" }) was talked to on `day`.
static func talked_on(friend: Dictionary, day: int) -> bool:
	return int(friend.get("talked", 0)) == day


## Whether `friend` was given something on `day`.
static func given_on(friend: Dictionary, day: int) -> bool:
	return int(friend.get("gift", 0)) == day


## "Pip: For me? This is the best thing ever!": what `villager` says to a gift.
static func thanks(villager: Dictionary, liked: bool) -> String:
	var words: Variant = villager.get("thanks")
	var said: String = str((words as Dictionary).get("liked" if liked else "other", "")) if typeof(words) == TYPE_DICTIONARY else ""
	return THANKS_WORDS % [str(villager.get("name", "")), said if not said.is_empty() else "Thank you."]


## `dialogue` (in the shape of data/dialogue) with the answer that gives `villager_id` a gift
## added to its node `node_id`: before the node's last answer if that one ends the conversation
## (its goodbye), else after it. Returns a copy; `dialogue` is left as it was. A node the
## dialogue hasn't got changes nothing.
static func with_gift_answer(dialogue: Dictionary, node_id: String, villager_id: String) -> Dictionary:
	var out: Dictionary = dialogue.duplicate(true)
	var nodes: Variant = out.get("nodes")
	if typeof(nodes) != TYPE_DICTIONARY or typeof((nodes as Dictionary).get(node_id)) != TYPE_DICTIONARY:
		return out
	var node: Dictionary = nodes[node_id]
	var options: Array = node["options"] if typeof(node.get("options")) == TYPE_ARRAY else []
	var answer: Dictionary = {"text": GIVE_WORDS, "effects": [{"type": GIFT_EFFECT, "villager": villager_id}], "next": null}
	var last: Variant = options.back() if not options.is_empty() else null
	if typeof(last) == TYPE_DICTIONARY and (last as Dictionary).get("next") == null:
		options.insert(options.size() - 1, answer)
	else:
		options.append(answer)
	node["options"] = options
	return out


## What is wrong with `rules` as the rules of friendship, in words: nothing, if they can be
## used. `item_types` are the item types the game's items have.
static func problems(rules: Dictionary, item_types: Array) -> PackedStringArray:
	var out: PackedStringArray = []
	for key: String in ["marks", "points_per_mark"]:
		if not _is_whole(rules.get(key)) or float(rules[key]) < 1.0:
			out.append("'%s' must be a whole number of 1 or more." % key)
	for key: String in ["talk", "liked_gift", "other_gift"]:
		if not _is_whole(rules.get(key)) or float(rules[key]) < 0.0:
			out.append("'%s' must be a whole number of 0 or more." % key)
	if out.is_empty() and float(rules["liked_gift"]) < float(rules["other_gift"]):
		out.append("'liked_gift' must be at least 'other_gift': a gift they like is worth no less.")
	if rules.has("friend_marks") and (not _is_whole(rules["friend_marks"]) or float(rules["friend_marks"]) < 1.0
			or (_is_whole(rules.get("marks")) and float(rules["friend_marks"]) > float(rules["marks"]))):
		out.append("'friend_marks' must be a whole number from 1 to 'marks': the marks that make a friend.")
	var types: Variant = rules.get("gift_types")
	if typeof(types) != TYPE_ARRAY or (types as Array).is_empty():
		out.append("'gift_types' must list the item types that can be given.")
	else:
		for type: Variant in types:
			if not item_types.has(str(type)):
				out.append("'gift_types' names an item type no item has: '%s'." % type)
	return out


## What is wrong with `villager` (a data entry), in words: nothing, if it can be used.
## `item_of` gives an item's data entry by id ({} if there is none); `has_dialogue` says
## whether a conversation id is one the game has.
func villager_problems(villager: Dictionary, item_of: Callable, has_dialogue: Callable) -> PackedStringArray:
	var out: PackedStringArray = []
	if typeof(villager.get("name")) != TYPE_STRING or str(villager["name"]).is_empty():
		out.append("'name' must be the villager's name.")
	if not has_dialogue.call(str(villager.get("dialogue", ""))):
		out.append("'dialogue' names an unknown conversation '%s'." % villager.get("dialogue", ""))
	var liked: Variant = villager.get("likes")
	if typeof(liked) != TYPE_ARRAY:
		out.append("'likes' must list the items they like (it may be empty).")
	else:
		for id: Variant in liked:
			var item: Dictionary = item_of.call(str(id))
			if item.is_empty():
				out.append("'likes' names an unknown item id '%s'." % id)
			elif not is_giftable(item):
				out.append("'likes' names '%s', which can't be given (its type is '%s')." % [id, item.get("type", "")])
	var words: Variant = villager.get("thanks")
	if typeof(words) != TYPE_DICTIONARY:
		out.append("'thanks' must be an object: what they say to a gift they 'liked' and to any 'other'.")
	else:
		for key: String in ["liked", "other"]:
			if typeof((words as Dictionary).get(key)) != TYPE_STRING or str(words[key]).is_empty():
				out.append("'thanks' needs '%s': what they say to such a gift." % key)
	return out


static func _is_whole(value: Variant) -> bool:
	return (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and float(value) == roundf(float(value))


static func _whole(value: Variant, fallback: int) -> int:
	return int(value) if _is_whole(value) else fallback
