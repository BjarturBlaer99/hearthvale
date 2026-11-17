class_name Crafting
extends RefCounted
## Crafting (2026-11-17, docs/TECH_DESIGN.md §28), pure: recipes are data
## (data/crafting/<id>.json), each made at a station and saying what it needs and makes:
##   { "id": "furnace", "name": "Furnace", "station": "workbench", "order": 1,
##     "needs": [ { "item": "stone", "count": 20 }, { "item": "copper_ore", "count": 5 } ],
##     "makes": { "furnishing": "furnace" },
##     "unlock": { "found": "copper_ore" } }
## `makes` is an item (`{ "item", "count" }`) or a furnishing of the hero's home, which has its
## own place there and is made once. `unlock` says when the recipe is known: once an item has
## been `found` (ever held), or once a `skill` has reached a `level`; without it, from the
## start. The workbench lists what is known, in `order`; the furnace's recipes (station
## "furnace") are what it smelts. This says what is known, what is missing and why a thing
## can't be made; GameState makes it. It keeps nothing itself.

const WORKBENCH: String = "workbench"
const FURNACE: String = "furnace"
const STATIONS: Array[String] = [WORKBENCH, FURNACE]
## The flag that says a furnishing has been made: "home/furnace".
const FURNISHED_FLAG: String = "home/%s"
## Why a thing can't be made.
const LACKING_WORDS: String = "You haven't all it needs."
const NO_ROOM_WORDS: String = "You have no room to carry that."
const HAVE_ONE_WORDS: String = "You have one already."
const UNKNOWN_WORDS: String = "You don't know how to make that."
## What making a thing is announced with.
const MADE_WORDS: String = "Made: %s."
## A need as the workbench shows it: "Stone 12 of 20".
const NEED_LINE: String = "%s %d of %d"
## What a recipe's line ends with when it makes more than one, or a thing he has: "x3".
const COUNT_WORDS: String = "%s x%d"


static func furnished_flag(furnishing: StringName) -> StringName:
	return StringName(FURNISHED_FLAG % furnishing)


static func station_of(recipe: Dictionary) -> String:
	return str(recipe.get("station", WORKBENCH))


## The recipes of `station` among `recipes` (data entries), in their `order`, then by id.
static func of_station(recipes: Array, station: String) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for recipe: Variant in recipes:
		if typeof(recipe) == TYPE_DICTIONARY and station_of(recipe) == station:
			out.append(recipe)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var first: int = int(a.get("order", 0))
		var second: int = int(b.get("order", 0))
		return first < second or (first == second and str(a.get("id", "")) < str(b.get("id", ""))))
	return out


## Whether `recipe` is known. `has_found` says whether an item id has ever been held, and
## `level_of` gives a skill id's level.
static func is_known(recipe: Dictionary, has_found: Callable, level_of: Callable) -> bool:
	var unlock: Variant = recipe.get("unlock")
	if typeof(unlock) != TYPE_DICTIONARY:
		return true
	if (unlock as Dictionary).has("found"):
		return bool(has_found.call(str(unlock["found"])))
	if (unlock as Dictionary).has("skill"):
		return int(level_of.call(str(unlock["skill"]))) >= int((unlock as Dictionary).get("level", 1))
	return true


## The recipes of `station` that are known, in their order.
static func known(recipes: Array, station: String, has_found: Callable, level_of: Callable) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for recipe: Dictionary in of_station(recipes, station):
		if is_known(recipe, has_found, level_of):
			out.append(recipe)
	return out


## The item `recipe` makes, or "" if it makes a furnishing.
static func item_made(recipe: Dictionary) -> String:
	var makes: Variant = recipe.get("makes", {})
	return str((makes as Dictionary).get("item", "")) if typeof(makes) == TYPE_DICTIONARY else ""


## How many of its item `recipe` makes at once (1 for a furnishing).
static func count_made(recipe: Dictionary) -> int:
	var makes: Variant = recipe.get("makes", {})
	return maxi(int((makes as Dictionary).get("count", 1)), 1) if typeof(makes) == TYPE_DICTIONARY else 1


## The furnishing `recipe` makes, or "" if it makes an item.
static func furnishing_made(recipe: Dictionary) -> String:
	var makes: Variant = recipe.get("makes", {})
	return str((makes as Dictionary).get("furnishing", "")) if typeof(makes) == TYPE_DICTIONARY else ""


## What `recipe` is called on the list: its own name, else its item's (`names`: item id ->
## name), with how many it makes if that is more than one ("Bombs x3").
static func name_of(recipe: Dictionary, names: Dictionary) -> String:
	var made: String = item_made(recipe)
	var words: String = str(recipe.get("name", names.get(made, made if not made.is_empty() else str(recipe.get("id", "")))))
	return COUNT_WORDS % [words, count_made(recipe)] if count_made(recipe) > 1 else words


## What `recipe` needs: [{ "item": id, "count": n }], as the data lists them.
static func needs_of(recipe: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var needs: Variant = recipe.get("needs")
	if typeof(needs) == TYPE_ARRAY:
		for need: Variant in needs:
			if typeof(need) == TYPE_DICTIONARY:
				out.append({"item": str((need as Dictionary).get("item", "")), "count": maxi(int((need as Dictionary).get("count", 1)), 1)})
	return out


## What he is short of for `recipe`: [{ "item": id, "count": how many more }]. `held` gives how
## many of an item id he carries.
static func missing(recipe: Dictionary, held: Callable) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for need: Dictionary in needs_of(recipe):
		var short: int = int(need["count"]) - int(held.call(str(need["item"])))
		if short > 0:
			out.append({"item": need["item"], "count": short})
	return out


## Why `recipe` can't be made now, in words; "" if it can. `held` gives how many of an item he
## carries, `has_room` whether so many more of an item fit, and `is_furnished` whether his
## home has a furnishing already. A thing it uses up makes room for a thing of the same kind.
static func why_not(recipe: Dictionary, held: Callable, has_room: Callable, is_furnished: Callable) -> String:
	var furnishing: String = furnishing_made(recipe)
	if not furnishing.is_empty() and bool(is_furnished.call(furnishing)):
		return HAVE_ONE_WORDS
	if not missing(recipe, held).is_empty():
		return LACKING_WORDS
	var made: String = item_made(recipe)
	if not made.is_empty():
		var used: int = 0
		for need: Dictionary in needs_of(recipe):
			if str(need["item"]) == made:
				used += int(need["count"])
		if not bool(has_room.call(made, count_made(recipe) - used)):
			return NO_ROOM_WORDS
	return ""


## `recipe`'s needs as the workbench shows them, beside what he has: "Stone 12 of 20". What
## he has more of than is needed shows as what is needed ("Stone 20 of 20").
static func need_lines(recipe: Dictionary, held: Callable, names: Dictionary) -> PackedStringArray:
	var out: PackedStringArray = []
	for need: Dictionary in needs_of(recipe):
		var wanted: int = int(need["count"])
		out.append(NEED_LINE % [str(names.get(need["item"], need["item"])), mini(int(held.call(str(need["item"]))), wanted), wanted])
	return out


## What is wrong with `recipe`, in words: nothing, if it can be used. `item_of` gives the item
## entry for an id (empty if there is none); `furnishings` are the home's, and `skills` the
## hero's skill ids.
static func problems(recipe: Dictionary, item_of: Callable, furnishings: Array, skills: Array) -> PackedStringArray:
	var out: PackedStringArray = []
	if recipe.has("station") and not STATIONS.has(str(recipe["station"])):
		out.append("'station' must be one of: %s." % ", ".join(PackedStringArray(STATIONS)))
	var makes: Variant = recipe.get("makes")
	if typeof(makes) != TYPE_DICTIONARY or ((makes as Dictionary).has("item") == (makes as Dictionary).has("furnishing")):
		out.append("'makes' must name an 'item' or a 'furnishing', one of the two.")
	elif (makes as Dictionary).has("item"):
		if (item_of.call(str(makes["item"])) as Dictionary).is_empty():
			out.append("'makes' names an unknown item id '%s'." % makes["item"])
		if int((makes as Dictionary).get("count", 1)) < 1:
			out.append("'makes' 'count' must be 1 or more.")
	else:
		if not furnishings.has(str(makes["furnishing"])):
			out.append("'makes' names an unknown furnishing '%s'." % makes["furnishing"])
		if station_of(recipe) == FURNACE:
			out.append("the furnace makes items, not furnishings.")
	var needs: Variant = recipe.get("needs")
	if typeof(needs) != TYPE_ARRAY or (needs as Array).is_empty():
		out.append("'needs' must list one thing or more that the recipe uses.")
	else:
		for need: Variant in needs:
			if typeof(need) != TYPE_DICTIONARY or not (need as Dictionary).has("item") or not (need as Dictionary).has("count"):
				out.append("every entry in 'needs' has an 'item' and a 'count'.")
				continue
			if (item_of.call(str(need["item"])) as Dictionary).is_empty():
				out.append("'needs' names an unknown item id '%s'." % need["item"])
			if int(need["count"]) < 1:
				out.append("'needs' wants 1 or more of '%s'." % need["item"])
	if recipe.has("unlock"):
		var unlock: Variant = recipe["unlock"]
		if typeof(unlock) != TYPE_DICTIONARY or ((unlock as Dictionary).has("found") == (unlock as Dictionary).has("skill")):
			out.append("'unlock' must name an item 'found' or a 'skill' and its 'level', one of the two.")
		elif (unlock as Dictionary).has("found"):
			if (item_of.call(str(unlock["found"])) as Dictionary).is_empty():
				out.append("'unlock' names an unknown item id '%s'." % unlock["found"])
		else:
			if not skills.has(str(unlock["skill"])):
				out.append("'unlock' names an unknown skill '%s'." % unlock["skill"])
			if int((unlock as Dictionary).get("level", 0)) < 2:
				out.append("'unlock' needs a 'level' of 2 or more: every skill begins at 1.")
	return out


## What is wrong with `rules` as the crafting rules (data/rules/crafting.json), in words:
## nothing, if they can be used.
static func rules_problems(rules: Dictionary) -> PackedStringArray:
	var out: PackedStringArray = []
	for number: String in ["furnace_most", "chest_slots"]:
		var value: Variant = rules.get(number)
		if (typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT) or float(value) != floorf(float(value)) or int(value) < 1:
			out.append("'%s' must be a whole number of 1 or more." % number)
	var furnishings: Variant = rules.get("furnishings")
	if typeof(furnishings) != TYPE_ARRAY:
		out.append("'furnishings' must list what the hero's home can be furnished with.")
	else:
		for furnishing: Variant in furnishings:
			if typeof(furnishing) != TYPE_STRING or str(furnishing).is_empty():
				out.append("every entry in 'furnishings' is a name.")
	return out
