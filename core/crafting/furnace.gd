class_name Furnace
extends RefCounted
## The furnace in the hero's home (2026-11-17, docs/TECH_DESIGN.md §28), pure: it smelts
## overnight. One load at a time, of one thing: lit today, what it makes is there from the next
## morning, and waits until it is taken out. Its recipes are the crafting recipes whose station
## is "furnace" (Crafting): so much ore and coal for a bar. It keeps what it holds and the day
## it was lit; GameState holds one and saves it.

const ASK: String = "ask"
const LIT: String = "lit"
const LACKING: String = "lacking"
const COLD_WORDS: String = "The furnace is cold. What will you smelt?"
const NOTHING_WORDS: String = "The furnace is cold, and you know nothing to smelt in it."
const BURNING_WORDS: String = "The furnace is burning. The %s will be ready in the morning."
const READY_WORDS: String = "The furnace has burned down. In it: %s."
const LIT_WORDS: String = "You load the furnace and light it. The %s will be ready in the morning."
const LACKING_WORDS: String = "You haven't the ore and the coal for that."
const TAKE_WORDS: String = "Take it out."
const LEAVE_WORDS: String = "Leave it."
const NOT_NOW_WORDS: String = "Nothing now."
const OTHER_WORDS: String = "Something else."

## What it will give (an item id), how many, and the day it was lit. Empty: count 0.
var item: StringName = &""
var count: int = 0
var day: int = 0


func is_empty() -> bool:
	return count <= 0


## Lit today (or, in a save from the future, later): still burning.
func is_burning(today: int) -> bool:
	return not is_empty() and today <= day


## Lit on an earlier day: what it made can be taken out.
func is_ready(today: int) -> bool:
	return not is_empty() and today > day


## Loads it with what makes `how_many` of `what`, and lights it, on `today`. Returns false, and
## changes nothing, if it holds something already or there is nothing to make.
func light(what: StringName, how_many: int, today: int) -> bool:
	if not is_empty() or how_many < 1 or what == &"":
		return false
	item = what
	count = how_many
	day = today
	return true


## Takes out what it holds: { "item", "count" }, or {} if it is empty. It is empty afterwards.
func take() -> Dictionary:
	if is_empty():
		return {}
	var out: Dictionary = {"item": item, "count": count}
	item = &""
	count = 0
	day = 0
	return out


## JSON-safe: { "item", "count", "day" }, or {} when it is empty.
func to_dict() -> Dictionary:
	return {} if is_empty() else {"item": String(item), "count": count, "day": day}


## Takes what a save holds. Anything that isn't a load leaves it empty.
func load_saved(saved: Variant) -> void:
	item = &""
	count = 0
	day = 0
	if typeof(saved) != TYPE_DICTIONARY:
		return
	var data: Dictionary = saved
	var how_many: Variant = data.get("count")
	if typeof(data.get("item")) != TYPE_STRING or str(data["item"]).is_empty() or not _is_number(how_many) or int(how_many) < 1:
		return
	item = StringName(str(data["item"]))
	count = int(how_many)
	day = maxi(int(data.get("day", 0)), 0) if _is_number(data.get("day")) else 0


## How many of `recipe` one load can make: as many as what he holds of each need allows
## (`held` gives how many of an item id he carries), `most` at the most.
static func load_size(recipe: Dictionary, held: Callable, most: int) -> int:
	var size: int = maxi(most, 0)
	for need: Dictionary in Crafting.needs_of(recipe):
		@warning_ignore("integer_division")
		size = mini(size, int(held.call(str(need["item"]))) / int(need["count"]))
	return maxi(size, 0)


## The furnace's conversation on `today`, in the shape of the ones in data/dialogue.
## Burning, it says so. Burned down, it offers what it holds (the `empty_furnace` effect).
## Cold and empty, it lists `recipes` (the furnace's, known to him): an answer for each, which
## loads as many as he can make (`most` at the most) with the shared `take_item` effects and
## `light_furnace`, or says he hasn't the makings. `names` maps item ids to their names.
func dialogue(today: int, recipes: Array, held: Callable, most: int, names: Dictionary) -> Dictionary:
	var nodes: Dictionary = {}
	if is_burning(today):
		nodes[ASK] = {"speaker": "", "text": BURNING_WORDS % _load_words(item, count, names).to_lower(), "options": [{"text": LEAVE_WORDS, "next": null}]}
		return {"id": "furnace", "start": ASK, "nodes": nodes}
	if is_ready(today):
		nodes[ASK] = {"speaker": "", "text": READY_WORDS % _load_words(item, count, names).to_lower(), "options": [
			{"text": TAKE_WORDS, "effects": [{"type": "empty_furnace"}], "next": null},
			{"text": LEAVE_WORDS, "next": null},
		]}
		return {"id": "furnace", "start": ASK, "nodes": nodes}
	var answers: Array = []
	for recipe: Dictionary in recipes:
		var made: String = Crafting.item_made(recipe)
		var size: int = load_size(recipe, held, most)
		var parts: PackedStringArray = []
		for need: Dictionary in Crafting.needs_of(recipe):
			parts.append("%d %s" % [int(need["count"]) * maxi(size, 1), str(names.get(need["item"], need["item"]))])
		var words: String = "%s (%s)" % [_load_words(StringName(made), maxi(size, 1), names), ", ".join(parts)]
		if size < 1:
			answers.append({"text": words, "next": LACKING})
			continue
		var effects: Array = []
		for need: Dictionary in Crafting.needs_of(recipe):
			effects.append({"type": "take_item", "item": str(need["item"]), "count": int(need["count"]) * size})
		effects.append({"type": "light_furnace", "item": made, "count": size})
		var lit: String = "%s_%s" % [LIT, str(recipe.get("id", made))]
		answers.append({"text": words, "effects": effects, "next": lit})
		nodes[lit] = {"speaker": "", "text": LIT_WORDS % _load_words(StringName(made), size, names).to_lower(), "options": [{"text": LEAVE_WORDS, "next": null}]}
	answers.append({"text": NOT_NOW_WORDS, "next": null})
	nodes[ASK] = {"speaker": "", "text": COLD_WORDS if not recipes.is_empty() else NOTHING_WORDS, "options": answers}
	nodes[LACKING] = {"speaker": "", "text": LACKING_WORDS, "options": [{"text": OTHER_WORDS, "next": ASK}, {"text": LEAVE_WORDS, "next": null}]}
	return {"id": "furnace", "start": ASK, "nodes": nodes}


## "Copper Bar x3", or "Copper Bar" for one.
static func _load_words(what: StringName, how_many: int, names: Dictionary) -> String:
	var words: String = str(names.get(String(what), what))
	return Crafting.COUNT_WORDS % [words, how_many] if how_many > 1 else words


static func _is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT
