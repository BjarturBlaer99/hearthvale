class_name ToolUse
extends RefCounted
## What working the plot from the item button does (P3, GDD §7), pure: given what is on the
## button, what the hero faces and what he carries, it decides; the area then does it. A tool
## is an item of type "tool" whose stats name its `tool`: the hoe tills bare soil, the watering
## can waters tilled soil and fills at water. A seed (an item of type "seed") is planted in
## tilled soil that has nothing in it. The pickaxe (2026-11-17) is a tool too, of the kind "pick":
## it strikes the rock he faces (decide_pick), and its stats may say it needs `fewer_blows`.

const TYPE: String = "tool"
const HOE: String = "hoe"
const CAN: String = "water"
const SEED: String = "seed"
const PICK: String = "pick"
## A sprinkler (an item of type "sprinkler"): set on tilled soil of the plot like a seed.
const SPRINKLER: String = "sprinkler"
## The tools an item of type "tool" can be.
const KINDS: Array[String] = [HOE, CAN, PICK]
## What a use can do.
const TILL: StringName = &"till"
const WATER: StringName = &"water"
const FILL: StringName = &"fill"
const PLANT: StringName = &"plant"
const MINE: StringName = &"mine"
const PLACE: StringName = &"place"
const NOTHING: StringName = &""
## What is said when a use does nothing.
const HOE_NOT_HERE: String = "The hoe is for the soil of your plot."
const HOE_DONE: String = "This soil is tilled already."
const HOE_GROWING: String = "Something is growing here."
const CAN_NOT_HERE: String = "There is nothing to water here."
const CAN_BARE: String = "Till the soil with the hoe first."
const CAN_DONE: String = "This soil is wet already."
const CAN_EMPTY: String = "The watering can is empty. Fill it at the well or the pond."
const CAN_FULL: String = "The watering can is full."
const SEED_NOT_HERE: String = "Seeds are for the tilled soil of your plot."
const SEED_BARE: String = "Till the soil with the hoe first."
const SEED_TAKEN: String = "Something is growing here already."
const SEED_NONE: String = "You have no more of these seeds."
const SEED_SPRINKLER: String = "A sprinkler stands here."
const SPRINKLER_NOT_HERE: String = "A sprinkler is for the tilled soil of your plot."
const SPRINKLER_BARE: String = "Till the soil with the hoe first."
const SPRINKLER_GROWING: String = "Something is growing here."
const SPRINKLER_TAKEN: String = "A sprinkler stands here already."
const SPRINKLER_NONE: String = "You have no more sprinklers."


static func is_farm_tool(item: Dictionary) -> bool:
	return str(item.get("type", "")) == TYPE


## What `item` is to the plot: HOE or CAN for a tool, SEED for a seed, or "" if it is none.
static func kind_of(item: Dictionary) -> String:
	if Crops.is_seed(item):
		return SEED
	if str(item.get("type", "")) == SPRINKLER:
		return SPRINKLER
	var stats: Variant = item.get("stats", {})
	if not is_farm_tool(item) or typeof(stats) != TYPE_DICTIONARY:
		return ""
	return str((stats as Dictionary).get("tool", ""))


## How long the hero is busy with one use of `item` (s).
static func time_of(item: Dictionary) -> float:
	var stats: Variant = item.get("stats", {})
	return float((stats as Dictionary).get("cooldown", 0.4)) if typeof(stats) == TYPE_DICTIONARY else 0.4


## What using `kind` does: { "does": TILL, WATER, FILL, PLANT or NOTHING, "says": words }.
## `soil` is what the cell he faces is (a Farm state), or "" if it isn't a cell of the plot;
## `at_water` whether he faces the well or the pond; `held` how much he has of what the use
## takes (the can's pours, the seeds of this kind) and `holds` how much of it fits; `growing`
## whether something is planted in the cell, alive or withered.
## `sprinkler` is whether a sprinkler stands in the cell.
static func decide(kind: String, soil: StringName, at_water: bool, held: int, holds: int, growing: bool = false, sprinkler: bool = false) -> Dictionary:
	match kind:
		HOE:
			if soil == &"":
				return _no(HOE_NOT_HERE)
			if growing:
				return _no(HOE_GROWING)
			return _do(TILL) if soil == Farm.BARE else _no(HOE_DONE)
		CAN:
			if at_water:
				return _do(FILL) if held < holds else _no(CAN_FULL)
			match soil:
				&"":
					return _no(CAN_NOT_HERE)
				Farm.BARE:
					return _no(CAN_BARE)
				Farm.WATERED:
					return _no(CAN_DONE)
			return _do(WATER) if held > 0 else _no(CAN_EMPTY)
		SEED:
			if soil == &"":
				return _no(SEED_NOT_HERE)
			if soil == Farm.BARE:
				return _no(SEED_BARE)
			if growing:
				return _no(SEED_TAKEN)
			if sprinkler:
				return _no(SEED_SPRINKLER)
			return _do(PLANT) if held > 0 else _no(SEED_NONE)
		SPRINKLER:
			if soil == &"":
				return _no(SPRINKLER_NOT_HERE)
			if soil == Farm.BARE:
				return _no(SPRINKLER_BARE)
			if growing:
				return _no(SPRINKLER_GROWING)
			if sprinkler:
				return _no(SPRINKLER_TAKEN)
			return _do(PLACE) if held > 0 else _no(SPRINKLER_NONE)
	return _no("")


## How many cells in a line one use of `item` works: 1 unless a better tool's stats say more
## ("reach": the copper hoe and can 2, the iron ones 3).
static func reach(item: Dictionary) -> int:
	var stats: Variant = item.get("stats", {})
	if typeof(stats) != TYPE_DICTIONARY:
		return 1
	return maxi(int((stats as Dictionary).get("reach", 1)), 1)


## The cells one use works: the cell he faces (`front`) and those beyond it the way he faces
## (`facing`, a step of one cell), `cells` of them in all.
static func line(front: Vector2i, facing: Vector2i, cells: int) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for step: int in maxi(cells, 1):
		out.append(front + facing * step)
	return out


## What swinging the pickaxe does: { "does": MINE or NOTHING, "says": words }. `at_rock` is
## whether a whole rock stands in the cell he faces.
static func decide_pick(at_rock: bool) -> Dictionary:
	return _do(MINE) if at_rock else _no(MineRules.NOTHING_WORDS)


## How many blows fewer than the plain pickaxe `item` needs to break a rock (a better
## pickaxe's stats say so: "fewer_blows"). Nothing for anything else.
static func fewer_blows(item: Dictionary) -> int:
	var stats: Variant = item.get("stats", {})
	if kind_of(item) != PICK or typeof(stats) != TYPE_DICTIONARY:
		return 0
	return maxi(int((stats as Dictionary).get("fewer_blows", 0)), 0)


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
