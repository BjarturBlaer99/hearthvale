class_name Cooking
extends RefCounted
## Cooking (P2d, GDD §6), pure: recipes are data (data/recipes/<id>.json), each saying what a
## dish needs and what it makes:
##   { "id": "blossom_tea", "makes": { "item": "blossom_tea", "count": 1 },
##     "needs": [ { "item": "cherry_blossom", "count": 3 } ] }
## The hearth's list is a conversation built from the recipes (dialogue()), in the shape of the
## ones in data/dialogue, so the dialogue box and the shared conditions and effects do the rest:
## an answer for each dish, which cooks it if the hero has the makings and room for it, and
## says so if he hasn't. Cooking a dish is practice at cooking (P4b: the `practise` effect).
## A recipe marked `"taught": true` is not known from the start: someone teaches it (P4d: the
## `teach_recipe` effect), which sets its flag, and the hearth lists only what he knows.

const ASK: String = "ask"
const LACKING: String = "lacking"
const ASK_WORDS: String = "The hearth is warm. What will you cook?"
const NOTHING_WORDS: String = "There is nothing you know how to cook."
const LACKING_WORDS: String = "You haven't the makings of that, or the room to carry it."
const COOKED_WORDS: String = "You make %s."
const MORE_WORDS: String = "Cook something else."
const DONE_WORDS: String = "That will do."
const LEAVE_WORDS: String = "Nothing now."
## What learning a recipe is announced with: the dish's name.
const LEARNED_WORDS: String = "New recipe: %s."


## Whether `recipe` can be cooked with what `held` says the hero has (item id -> count).
static func can_cook(recipe: Dictionary, held: Dictionary) -> bool:
	for need: Dictionary in recipe.get("needs", []):
		if int(held.get(str(need["item"]), 0)) < int(need["count"]):
			return false
	return not (recipe.get("needs", []) as Array).is_empty()


## Whether `recipe` has to be taught before the hearth lists it.
static func is_taught(recipe: Dictionary) -> bool:
	var marked: Variant = recipe.get("taught", false)
	return typeof(marked) == TYPE_BOOL and marked


## The flag that says the hero knows the recipe `recipe_id`.
static func known_flag(recipe_id: StringName) -> StringName:
	return StringName("recipe/%s" % recipe_id)


## Those of `recipes` the hero knows, in the order given: the ones known from the start, and
## the taught ones whose flag `flags` (name -> value) has set.
static func known(recipes: Array, flags: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for recipe: Variant in recipes:
		if typeof(recipe) != TYPE_DICTIONARY:
			continue
		var flag: StringName = known_flag(StringName(str((recipe as Dictionary).get("id", ""))))
		var learned: Variant = flags.get(flag, flags.get(String(flag), false))
		if not is_taught(recipe) or (typeof(learned) == TYPE_BOOL and learned):
			out.append(recipe)
	return out


## Whether `item_id` is a dish: something one of `recipes` makes.
static func is_dish(recipes: Array, item_id: String) -> bool:
	for recipe: Variant in recipes:
		var makes: Variant = (recipe as Dictionary).get("makes") if typeof(recipe) == TYPE_DICTIONARY else null
		if typeof(makes) == TYPE_DICTIONARY and str((makes as Dictionary).get("item", "")) == item_id:
			return true
	return false


## "3 Cherry Blossoms" or "2 Mushrooms, 1 Potato": what `recipe` needs, in words. `names` maps
## item ids to the names they show.
static func needs_text(recipe: Dictionary, names: Dictionary) -> String:
	var parts: PackedStringArray = []
	for need: Dictionary in recipe.get("needs", []):
		parts.append("%d %s" % [int(need["count"]), str(names.get(str(need["item"]), need["item"]))])
	return ", ".join(parts)


## The hearth's conversation for `recipes` (data entries, in the order given). `items` maps
## item ids to their data entries (for names and how many can be carried).
static func dialogue(recipes: Array, items: Dictionary) -> Dictionary:
	var names: Dictionary = {}
	for id: Variant in items:
		names[str(id)] = str((items[id] as Dictionary).get("name", id))
	var nodes: Dictionary = {}
	var answers: Array = []
	for recipe: Dictionary in recipes:
		var dish: String = str(recipe["makes"]["item"])
		var made: int = int(recipe["makes"].get("count", 1))
		var words: String = "%s (%s)" % [str(names.get(dish, dish)), needs_text(recipe, names)]
		var able: Array = []
		var effects: Array = []
		for need: Dictionary in recipe["needs"]:
			able.append({"type": "has_item", "item": str(need["item"]), "count": int(need["count"])})
			effects.append({"type": "take_item", "item": str(need["item"]), "count": int(need["count"])})
		# Room to carry what is made: not so many already that some would be lost.
		var most: int = Inventory.capacity(items.get(dish, {}))
		if most < Inventory.UNLIMITED:
			able.append({"type": "not", "condition": {"type": "has_item", "item": dish, "count": most - made + 1}})
		effects.append({"type": "give_item", "item": dish, "count": made})
		effects.append({"type": "practise", "skill": String(Skills.COOKING), "deed": String(Skills.DISH)})
		var cooked: String = "cooked_%s" % str(recipe["id"])
		answers.append({"text": words, "conditions": able, "effects": effects, "next": cooked})
		answers.append({"text": words, "conditions": [{"type": "not", "condition": {"type": "all", "of": able}}], "next": LACKING})
		nodes[cooked] = {"speaker": "", "text": COOKED_WORDS % str(names.get(dish, dish)).to_lower(), "options": _after()}
	answers.append({"text": LEAVE_WORDS, "next": null})
	nodes[ASK] = {"speaker": "", "text": ASK_WORDS if not recipes.is_empty() else NOTHING_WORDS, "options": answers}
	nodes[LACKING] = {"speaker": "", "text": LACKING_WORDS, "options": _after()}
	return {"id": "hearth", "start": ASK, "nodes": nodes}


## What is wrong with `recipe`, in words: nothing, if it can be used. `known` says whether an
## item id is one the game has.
static func problems(recipe: Dictionary, known: Callable) -> PackedStringArray:
	var out: PackedStringArray = []
	var makes: Variant = recipe.get("makes")
	if typeof(makes) != TYPE_DICTIONARY or not (makes as Dictionary).has("item"):
		out.append("'makes' must name the 'item' the recipe makes.")
	else:
		if not known.call(str(makes["item"])):
			out.append("'makes' names an unknown item id '%s'." % makes["item"])
		if int((makes as Dictionary).get("count", 1)) < 1:
			out.append("'makes' 'count' must be 1 or more.")
	if recipe.has("taught") and typeof(recipe["taught"]) != TYPE_BOOL:
		out.append("'taught' must be true or false.")
	var needs: Variant = recipe.get("needs")
	if typeof(needs) != TYPE_ARRAY or (needs as Array).is_empty():
		out.append("'needs' must list one thing or more that the recipe uses.")
		return out
	for need: Variant in needs:
		if typeof(need) != TYPE_DICTIONARY or not (need as Dictionary).has("item") or not (need as Dictionary).has("count"):
			out.append("every entry in 'needs' has an 'item' and a 'count'.")
			continue
		if not known.call(str(need["item"])):
			out.append("'needs' names an unknown item id '%s'." % need["item"])
		if int(need["count"]) < 1:
			out.append("'needs' wants 1 or more of '%s'." % need["item"])
	return out


static func _after() -> Array:
	return [{"text": MORE_WORDS, "next": ASK}, {"text": DONE_WORDS, "next": null}]
