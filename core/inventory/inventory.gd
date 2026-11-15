class_name Inventory
extends RefCounted
## Inventory rules (docs/TECH_DESIGN.md §4), pure: how many of an item fit, which items go on
## the item button, what each one uses up, and how far a carried lantern lights the dark. Works on item entries from data and on stacks
## in GameState.inventory's shape ({ "id", "count" }). GameState applies them.

## Item types that can sit on the item button.
const EQUIPPABLE_TYPES: Array[String] = ["weapon_ranged", "bomb", "tool", "seed"]
## No data means no limit (tests and items not in data yet).
const UNLIMITED: int = 1 << 30


## How many of `item` can be carried: its max_stack when stackable, else one.
static func capacity(item: Dictionary) -> int:
	if item.is_empty():
		return UNLIMITED
	if bool(item.get("stackable", false)):
		return maxi(int(item.get("max_stack", 99)), 1)
	return 1


## How many more of `item` fit on top of `held`.
static func room_for(held: int, item: Dictionary) -> int:
	return maxi(capacity(item) - held, 0)


## Whether `count` more of `item` fit on top of `held`: all of them, or it doesn't fit. What
## can't be carried whole is left where it is (a chest, a bush, a crop), never taken in part.
static func fits(held: int, item: Dictionary, count: int) -> bool:
	return room_for(held, item) >= count


static func is_equippable(item: Dictionary) -> bool:
	return EQUIPPABLE_TYPES.has(str(item.get("type", "")))


## The item using up something when used: a ranged weapon's ammo, a bomb or a seed itself,
## what a tool holds (the watering can's water). Empty if none.
static func ammo_for(item: Dictionary) -> String:
	match str(item.get("type", "")):
		"weapon_ranged", "tool":
			var stats: Variant = item.get("stats", {})
			return str((stats as Dictionary).get("ammo", "")) if typeof(stats) == TYPE_DICTIONARY else ""
		"bomb", "seed":
			return str(item.get("id", ""))
	return ""


## The ids of what tools hold (the watering can's water), among `items` (data entries). It is
## in the tool, not in the pack: lists of what is carried leave it out.
static func held_in_tools(items: Array) -> Array[String]:
	var out: Array[String] = []
	for item: Variant in items:
		if typeof(item) == TYPE_DICTIONARY and str((item as Dictionary).get("type", "")) == "tool" and not ammo_for(item).is_empty():
			out.append(ammo_for(item))
	return out


## The items of `type` that `stacks` hold, looked up in `items` (data entries), in the order
## they were picked up.
static func held_of_type(stacks: Array, items: Array, type: String) -> Array[Dictionary]:
	var by_id: Dictionary = {}
	for item: Variant in items:
		if typeof(item) == TYPE_DICTIONARY:
			by_id[str((item as Dictionary).get("id", ""))] = item
	var out: Array[Dictionary] = []
	for stack: Variant in stacks:
		if typeof(stack) != TYPE_DICTIONARY or int((stack as Dictionary).get("count", 0)) <= 0:
			continue
		var item: Dictionary = by_id.get(str((stack as Dictionary).get("id", "")), {})
		if str(item.get("type", "")) == type:
			out.append(item)
	return out


## How far the hero's light reaches in the dark (px): the widest lantern among `stacks`, else
## `without` (their own dim glow).
static func light_radius(stacks: Array, items: Array, without: float) -> float:
	var best: float = without
	for lantern: Dictionary in held_of_type(stacks, items, "lantern"):
		var stats: Variant = lantern.get("stats", {})
		if typeof(stats) == TYPE_DICTIONARY:
			best = maxf(best, float((stats as Dictionary).get("radius", 0.0)))
	return best


## The equippable items that `stacks` hold, looked up in `items` (data entries), in the order
## they were picked up (the stacks' order).
static func equippable_held(stacks: Array, items: Array) -> Array[Dictionary]:
	var by_id: Dictionary = {}
	for item: Variant in items:
		if typeof(item) == TYPE_DICTIONARY:
			by_id[str((item as Dictionary).get("id", ""))] = item
	var out: Array[Dictionary] = []
	for stack: Variant in stacks:
		if typeof(stack) != TYPE_DICTIONARY or int((stack as Dictionary).get("count", 0)) <= 0:
			continue
		var item: Dictionary = by_id.get(str((stack as Dictionary).get("id", "")), {})
		if is_equippable(item):
			out.append(item)
	return out
