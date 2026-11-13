class_name ToolUse
extends RefCounted
## What using a farm tool does (P3, GDD §7), pure: given the tool, what the hero faces and
## what he carries, it decides; the area then does it. A tool is an item of type "tool" whose
## stats name its `tool`: the hoe tills bare soil, the watering can waters tilled soil and
## fills at water.

const TYPE: String = "tool"
const HOE: String = "hoe"
const CAN: String = "water"
const KINDS: Array[String] = [HOE, CAN]
## What a use can do.
const TILL: StringName = &"till"
const WATER: StringName = &"water"
const FILL: StringName = &"fill"
const NOTHING: StringName = &""
## What is said when a use does nothing.
const HOE_NOT_HERE: String = "The hoe is for the soil of your plot."
const HOE_DONE: String = "This soil is tilled already."
const CAN_NOT_HERE: String = "There is nothing to water here."
const CAN_BARE: String = "Till the soil with the hoe first."
const CAN_DONE: String = "This soil is wet already."
const CAN_EMPTY: String = "The watering can is empty. Fill it at the well or the pond."
const CAN_FULL: String = "The watering can is full."


static func is_farm_tool(item: Dictionary) -> bool:
	return str(item.get("type", "")) == TYPE


## Which tool `item` is: HOE or CAN, or "" if it is none.
static func kind_of(item: Dictionary) -> String:
	var stats: Variant = item.get("stats", {})
	if not is_farm_tool(item) or typeof(stats) != TYPE_DICTIONARY:
		return ""
	return str((stats as Dictionary).get("tool", ""))


## How long the hero is busy with one use of `item` (s).
static func time_of(item: Dictionary) -> float:
	var stats: Variant = item.get("stats", {})
	return float((stats as Dictionary).get("cooldown", 0.4)) if typeof(stats) == TYPE_DICTIONARY else 0.4


## What using the tool `kind` does: { "does": TILL, WATER, FILL or NOTHING, "says": words }.
## `soil` is what the cell he faces is (a Farm state), or "" if it isn't a cell of the plot;
## `at_water` whether he faces the well or the pond; `pours` what the can holds of `holds`.
static func decide(kind: String, soil: StringName, at_water: bool, pours: int, holds: int) -> Dictionary:
	match kind:
		HOE:
			if soil == &"":
				return _no(HOE_NOT_HERE)
			return _do(TILL) if soil == Farm.BARE else _no(HOE_DONE)
		CAN:
			if at_water:
				return _do(FILL) if pours < holds else _no(CAN_FULL)
			match soil:
				&"":
					return _no(CAN_NOT_HERE)
				Farm.BARE:
					return _no(CAN_BARE)
				Farm.WATERED:
					return _no(CAN_DONE)
			return _do(WATER) if pours > 0 else _no(CAN_EMPTY)
	return _no("")


## What is wrong with `item` as a tool, in words: nothing, if it can be used.
static func problems(item: Dictionary) -> PackedStringArray:
	var out: PackedStringArray = []
	var stats: Variant = item.get("stats")
	if typeof(stats) != TYPE_DICTIONARY or not KINDS.has(str((stats as Dictionary).get("tool", ""))):
		out.append("a tool's stats must name its 'tool': %s." % " or ".join(KINDS))
		return out
	if kind_of(item) == CAN and str((stats as Dictionary).get("ammo", "")).is_empty():
		out.append("the watering can's stats must name what it holds ('ammo').")
	return out


static func _do(what: StringName) -> Dictionary:
	return {"does": what, "says": ""}


static func _no(words: String) -> Dictionary:
	return {"does": NOTHING, "says": words}
