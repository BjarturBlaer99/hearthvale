class_name LeftItems
extends RefCounted
## What a full pack couldn't take of something the hero was given (pure): a quest's reward, a
## present, anything a `give_item` effect hands over. Nothing given is lost: what doesn't fit is
## laid at his feet and lies there until he picks it up, through leaving the area and through a
## save. It is all kept in GameState's flags, so the save's shape is as it was:
##   owed/<item>                  how many are given and not yet laid down (no area to lay them in)
##   left/<area>/<x>,<y>/<item>   how many lie in that cell of that area
## GameState writes the flags (give_item, lay_down_owed, erase_flag); the area draws what lies
## in it as LeftItem pickups. This says what the flags are called and reads them back.

const OWED: String = "owed/"
const LYING: String = "left/"
## What he is told as something is laid at his feet: "Arrows x10", or "Bow" for one.
const WORDS: String = "Pack full. At your feet: %s."


static func owed_flag(item_id: StringName) -> StringName:
	return StringName(OWED + String(item_id))


static func lying_flag(area: StringName, cell: Vector2i, item_id: StringName) -> StringName:
	return StringName("%s%s/%d,%d/%s" % [LYING, area, cell.x, cell.y, item_id])


## How many a flag's `value` counts: a whole number above nothing, else none (a save gives
## numbers back as floats; a flag that isn't there is `false`).
static func count_of(value: Variant) -> int:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return 0
	return maxi(int(value), 0)


## What is owed by `flags` (GameState's): [{ "item": StringName, "count": int, "flag":
## StringName }], in the order of the item ids.
static func owed(flags: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for key: Variant in flags:
		var flag: String = str(key)
		var count: int = count_of(flags[key])
		if flag.begins_with(OWED) and flag.length() > OWED.length() and count > 0:
			out.append({"item": StringName(flag.trim_prefix(OWED)), "count": count, "flag": StringName(flag)})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a["item"]) < String(b["item"]))
	return out


## What lies in `area` by `flags`: [{ "cell": Vector2i, "item": StringName, "count": int,
## "flag": StringName }], in the order of the flags' names. A flag that doesn't read as a place
## and an item is passed over.
static func lying_in(flags: Dictionary, area: StringName) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var prefix: String = "%s%s/" % [LYING, area]
	for key: Variant in flags:
		var flag: String = str(key)
		var count: int = count_of(flags[key])
		if not flag.begins_with(prefix) or count <= 0:
			continue
		var parts: PackedStringArray = flag.trim_prefix(prefix).split("/")
		var at: PackedStringArray = parts[0].split(",")
		if parts.size() != 2 or parts[1].is_empty() or at.size() != 2 or not at[0].is_valid_int() or not at[1].is_valid_int():
			continue
		out.append({"cell": Vector2i(int(at[0]), int(at[1])), "item": StringName(parts[1]), "count": count, "flag": StringName(flag)})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return String(a["flag"]) < String(b["flag"]))
	return out


## "Pack full. At your feet: Arrows x10."
static func words(item_name: String, count: int) -> String:
	return WORDS % (item_name if count == 1 else "%s x%d" % [item_name, count])
