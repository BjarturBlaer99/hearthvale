class_name Food
extends RefCounted
## Food (P2d, GDD §6), pure: which items can be eaten, what one gives (energy, and for some
## meals hearts), and whether eating it now would do the hero any good. Works on item entries
## from data; GameState applies it (eat()).

## The item type that can be eaten. An "ingredient" is only cooked with.
const TYPE: String = "food"
const HALVES_PER_HEART: int = 2


static func is_food(item: Dictionary) -> bool:
	return str(item.get("type", "")) == TYPE


## The energy `item` gives when eaten.
static func energy_of(item: Dictionary) -> float:
	return maxf(float(_stats(item).get("energy", 0.0)), 0.0)


## The hearts `item` mends when eaten, in half hearts (its data says hearts: 0.5, 1, 2).
static func halves_of(item: Dictionary) -> int:
	return maxi(roundi(float(_stats(item).get("hearts", 0.0)) * HALVES_PER_HEART), 0)


## Whether eating `item` would do any good: it gives energy and the bar isn't full, or it mends
## hearts and some are missing.
static func would_help(item: Dictionary, energy: float, max_energy: float, health: int, max_health: int) -> bool:
	if not is_food(item):
		return false
	return (energy_of(item) > 0.0 and energy < max_energy) or (halves_of(item) > 0 and health < max_health)


## "+30 energy", "+35 energy, +half a heart", "+1 heart": what `item` gives, for a menu.
## `energy` is what it gives the hero now, if that isn't what its data says (a good cook's dish).
static func gives_text(item: Dictionary, energy: float = -1.0) -> String:
	var parts: PackedStringArray = []
	var gives: float = energy if energy >= 0.0 else energy_of(item)
	if gives > 0.0:
		parts.append("+%d energy" % roundi(gives))
	var halves: int = halves_of(item)
	if halves == 1:
		parts.append("+half a heart")
	elif halves > 0:
		@warning_ignore("integer_division")
		var whole: int = halves / HALVES_PER_HEART
		parts.append("+%d%s heart%s" % [whole, " and a half" if halves % HALVES_PER_HEART == 1 else "", "" if halves == HALVES_PER_HEART else "s"])
	return ", ".join(parts)


## The food that `stacks` hold, looked up in `items` (data entries), in the order it was picked
## up.
static func edible_held(stacks: Array, items: Array) -> Array[Dictionary]:
	return Inventory.held_of_type(stacks, items, TYPE)


## What is wrong with `item` as food, in words: nothing, if it can be eaten.
static func problems(item: Dictionary) -> PackedStringArray:
	var out: PackedStringArray = []
	var stats: Variant = item.get("stats")
	if typeof(stats) != TYPE_DICTIONARY:
		out.append("food needs 'stats' with the 'energy' or the 'hearts' it gives.")
		return out
	for key: String in ["energy", "hearts"]:
		var value: Variant = (stats as Dictionary).get(key, 0)
		if (typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT) or float(value) < 0.0:
			out.append("'%s' must be a number of 0 or more." % key)
	if out.is_empty() and energy_of(item) <= 0.0 and halves_of(item) <= 0:
		out.append("food must give some 'energy' or some 'hearts'.")
	return out


static func _stats(item: Dictionary) -> Dictionary:
	var stats: Variant = item.get("stats", {})
	return stats if typeof(stats) == TYPE_DICTIONARY else {}
