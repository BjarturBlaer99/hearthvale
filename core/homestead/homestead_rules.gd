class_name HomesteadRules
extends RefCounted
## The homestead's rules (2026-11-18, docs/TECH_DESIGN.md §30), pure. The rules are data
## (data/rules/homestead.json):
##   { "area": "homestead",
##     "rocks": { "rock": { "blows": 2, "gives": "stone", "count": 1 },
##                "boulder": { "blows": 4, "wants": "copper_pickaxe", "gives": "stone", "count": 4 },
##                ... } }
## `area` is the map that is the hero's land: what is cleared there is cleared for good
## (Homestead keeps the cells). `rocks` are the kinds of rock that stand on it. One takes
## `blows` of the plain pickaxe (a better pickaxe needs fewer, as in the quarry: its stats'
## "fewer_blows") and leaves `count` of its `gives` item lying. A kind that `wants` a pickaxe
## can't be broken by a lesser one: a pickaxe is good enough when it needs at least as few
## blows as the one named. What the sword clears (weeds, bushes, logs, stumps) is not here:
## those are breakables whose data says "returns": "never" (data/breakables).

## The kind of a plain rock of the land: every set of rules has it.
const ROCK: StringName = &"rock"

## The map that is the hero's land.
var area: StringName = &""

var _rocks: Dictionary = {}


func _init(rules: Dictionary = {}) -> void:
	area = StringName(str(rules.get("area", "")))
	var rocks: Variant = rules.get("rocks")
	if typeof(rocks) == TYPE_DICTIONARY:
		for kind: Variant in rocks:
			if typeof(rocks[kind]) == TYPE_DICTIONARY:
				_rocks[StringName(str(kind))] = rocks[kind]


## Whether `area_id` is the hero's land: the one place where what is cleared stays cleared.
func is_land(area_id: StringName) -> bool:
	return area != &"" and area_id == area


## Every kind of rock on the land, in the order the data lists them.
func rock_kinds() -> Array[StringName]:
	var out: Array[StringName] = []
	for kind: StringName in _rocks:
		out.append(kind)
	return out


func has_rock(kind: StringName) -> bool:
	return _rocks.has(kind)


## The kind a rock of the land is: `kind` if the rules know it, else a plain rock.
func rock_kind(kind: StringName) -> StringName:
	return kind if has_rock(kind) else ROCK


## How many blows of the plain pickaxe a rock of `kind` is counted at (Rock.hold): a better
## pickaxe takes its "fewer_blows" off that, never to less than one.
func blows(kind: StringName) -> int:
	return maxi(int((_rocks.get(kind, {}) as Dictionary).get("blows", 1)), 1)


## How many blows it takes with a pickaxe that needs `fewer` than the plain one.
func blows_with(kind: StringName, fewer: int) -> int:
	return maxi(blows(kind) - maxi(fewer, 0), 1)


## The item a broken rock of `kind` leaves, or &"" if it leaves nothing.
func gives(kind: StringName) -> StringName:
	return StringName(str((_rocks.get(kind, {}) as Dictionary).get("gives", "")))


## How many of it.
func count(kind: StringName) -> int:
	return maxi(int((_rocks.get(kind, {}) as Dictionary).get("count", 1)), 1)


## The least pickaxe that breaks a rock of `kind` (an item id), or &"" if any pickaxe does.
func wants(kind: StringName) -> StringName:
	return StringName(str((_rocks.get(kind, {}) as Dictionary).get("wants", "")))


## Whether the pickaxe `pick` (an item) is too weak for a rock of `kind`: the kind wants a
## pickaxe (`wanted`, that item's data) that needs fewer blows than this one does.
func is_too_hard(kind: StringName, pick: Dictionary, wanted: Dictionary) -> bool:
	if wants(kind) == &"":
		return false
	return ToolUse.fewer_blows(pick) < ToolUse.fewer_blows(wanted)


## What is wrong with `rules` as the homestead's, in words: nothing, if they can be used.
## `item_of` gives an item's data by its id ({} if there is none).
static func problems(rules: Dictionary, item_of: Callable) -> PackedStringArray:
	var out: PackedStringArray = []
	if str(rules.get("area", "")).is_empty():
		out.append("'area' must name the map that is the hero's land.")
	var rocks: Variant = rules.get("rocks")
	if typeof(rocks) != TYPE_DICTIONARY:
		out.append("'rocks' must be an object: a kind of rock, then its blows and what it gives.")
		return out
	if not (rocks as Dictionary).has(String(ROCK)):
		out.append("'rocks' needs '%s', the plain rock of the land." % ROCK)
	for kind: Variant in rocks:
		var rock: Variant = rocks[kind]
		if typeof(rock) != TYPE_DICTIONARY:
			out.append("rock '%s' must be an object." % kind)
			continue
		if not _is_whole(rock.get("blows")) or int(rock["blows"]) < 1:
			out.append("rock '%s' needs 'blows', a whole number of 1 or more." % kind)
		if rock.has("count") and (not _is_whole(rock["count"]) or int(rock["count"]) < 1):
			out.append("rock '%s': 'count' must be a whole number of 1 or more." % kind)
		if (item_of.call(str(rock.get("gives", ""))) as Dictionary).is_empty():
			out.append("rock '%s' gives '%s', which is no item." % [kind, rock.get("gives", "")])
		if rock.has("wants"):
			var wanted: Dictionary = item_of.call(str(rock["wants"]))
			if ToolUse.kind_of(wanted) != ToolUse.PICK:
				out.append("rock '%s' wants '%s', which is no pickaxe." % [kind, rock["wants"]])
			elif _is_whole(rock.get("blows")) and int(rock["blows"]) - ToolUse.fewer_blows(wanted) < 1:
				out.append("rock '%s' needs more 'blows' than the pickaxe it wants takes off." % kind)
	return out


static func _is_whole(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or (typeof(value) == TYPE_FLOAT and float(value) == floorf(float(value)))
