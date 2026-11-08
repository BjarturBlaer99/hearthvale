class_name Inventory
extends RefCounted
## Inventory rules (docs/TECH_DESIGN.md §4), pure: how many of an item fit, which items go on
## the item button, and what each one uses up. Works on item entries from data and on stacks
## in GameState.inventory's shape ({ "id", "count" }). GameState applies them.

## Item types that can sit on the item button.
const EQUIPPABLE_TYPES: Array[String] = ["weapon_ranged", "bomb"]
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


static func is_equippable(item: Dictionary) -> bool:
	return EQUIPPABLE_TYPES.has(str(item.get("type", "")))


## The item using up something when used: a ranged weapon's ammo, a bomb itself. Empty if none.
static func ammo_for(item: Dictionary) -> String:
	match str(item.get("type", "")):
		"weapon_ranged":
			var stats: Variant = item.get("stats", {})
			return str((stats as Dictionary).get("ammo", "")) if typeof(stats) == TYPE_DICTIONARY else ""
		"bomb":
			return str(item.get("id", ""))
	return ""


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
