class_name MineRules
extends RefCounted
## The Old Quarry's rules (2026-11-17, docs/TECH_DESIGN.md §27), pure. The rules are data
## (data/rules/mine.json):
##   { "hall": "quarry",
##     "floors": [ { "area": "quarry_1", "ores": { "copper_ore": 5 } }, ... ],
##     "lift": [4, 7],
##     "rocks": { "stone": { "blows": 2, "gives": "stone" },
##                "iron_ore": { "blows": 3, "gives": "iron_ore" }, ... } }
## The floors are numbered from 1 in the order they are listed, each an area; the last has no
## ladder down. A floor's `ores` say how many of its rocks hold each kind today (MineRolls
## decides which); the rest are plain stone. A rock of a kind takes `blows` of the pickaxe and
## gives one of its `gives` item. Arriving on a floor in `lift` opens the lift to it for good.
## It keeps nothing of the day: MineState does.

## The kind of a plain rock: every set of rules has it.
const STONE: StringName = &"stone"
## Not a floor of the mine (the hall, or anywhere else).
const NO_FLOOR: int = 0
## The entry point of every floor: where the ladder and the lift set him down.
const ARRIVAL: StringName = &"ladder"
## The flag that is set for good when the lift reaches a floor.
const LIFT_FLAG: String = "quarry/lift/%d"
## What the lift's conversation is.
const LIFT_ASK: String = "ask"
const LIFT_WORDS: String = "The old lift still runs. Where to?"
const LIFT_NOWHERE_WORDS: String = "The lift's rope is wound for floors you have reached on foot. It has nowhere to take you yet."
const LIFT_FLOOR_WORDS: String = "Floor %d"
const LIFT_STAY_WORDS: String = "Stay here."
## What is said when the pickaxe is swung at nothing.
const NOTHING_WORDS: String = "There is no rock here to break."

## The area the mine is entered through: where the lift stands, and where a fall ends.
var hall: StringName = &""

var _floors: Array[Dictionary] = []
var _rocks: Dictionary = {}
var _lift: Array[int] = []


func _init(rules: Dictionary = {}) -> void:
	hall = StringName(str(rules.get("hall", "")))
	var floors: Variant = rules.get("floors")
	if typeof(floors) == TYPE_ARRAY:
		for entry: Variant in floors:
			if typeof(entry) == TYPE_DICTIONARY:
				_floors.append(entry)
	var rocks: Variant = rules.get("rocks")
	if typeof(rocks) == TYPE_DICTIONARY:
		for kind: Variant in rocks:
			if typeof(rocks[kind]) == TYPE_DICTIONARY:
				_rocks[StringName(str(kind))] = rocks[kind]
	var lift: Variant = rules.get("lift")
	if typeof(lift) == TYPE_ARRAY:
		for stop: Variant in lift:
			_lift.append(int(stop))


func floor_count() -> int:
	return _floors.size()


## Which floor `area` is, from 1; NO_FLOOR if it isn't one.
func floor_of(area: StringName) -> int:
	for index: int in _floors.size():
		if str(_floors[index].get("area", "")) == String(area):
			return index + 1
	return NO_FLOOR


## The area of floor `floor`, or &"" if there is no such floor.
func area_of(floor: int) -> StringName:
	if floor < 1 or floor > _floors.size():
		return &""
	return StringName(str(_floors[floor - 1].get("area", "")))


## Whether `floor` is the deepest: it has no ladder down.
func is_last(floor: int) -> bool:
	return floor == _floors.size()


## The area a ladder down from `floor` leads to, or &"" from the last floor or from no floor.
func below(floor: int) -> StringName:
	return area_of(floor + 1) if floor >= 1 and not is_last(floor) else &""


## How many of `floor`'s rocks hold each kind of ore today (kind -> count), in the order the
## data lists them.
func ores_of(floor: int) -> Dictionary:
	if floor < 1 or floor > _floors.size():
		return {}
	var out: Dictionary = {}
	var ores: Variant = _floors[floor - 1].get("ores")
	if typeof(ores) == TYPE_DICTIONARY:
		for kind: Variant in ores:
			out[StringName(str(kind))] = maxi(int(ores[kind]), 0)
	return out


## Every kind of rock, plain stone among them.
func kinds() -> Array[StringName]:
	var out: Array[StringName] = []
	for kind: StringName in _rocks:
		out.append(kind)
	return out


## Whether a rock of `kind` holds ore: anything but plain stone.
func is_ore(kind: StringName) -> bool:
	return kind != STONE and _rocks.has(kind)


## How many blows a rock of `kind` takes from a pickaxe that needs `fewer` than the plain one
## (a better pickaxe: its stats' "fewer_blows"). Never less than one.
func blows(kind: StringName, fewer: int = 0) -> int:
	var rock: Dictionary = _rocks.get(kind, _rocks.get(STONE, {}))
	return maxi(int(rock.get("blows", 1)) - maxi(fewer, 0), 1)


## The item a broken rock of `kind` gives (one of it), or &"" if it gives nothing.
func gives(kind: StringName) -> StringName:
	var rock: Dictionary = _rocks.get(kind, {})
	return StringName(str(rock.get("gives", "")))


## The floors the lift stops at, shallowest first.
func lift_floors() -> Array[int]:
	var out: Array[int] = _lift.duplicate()
	out.sort()
	return out


func is_lift_stop(floor: int) -> bool:
	return _lift.has(floor)


static func lift_flag(floor: int) -> StringName:
	return StringName(LIFT_FLAG % floor)


## The lift's stops that `flags` (GameState.flags' shape) say have been reached.
func reached(flags: Dictionary) -> Array[int]:
	var out: Array[int] = []
	for floor: int in lift_floors():
		if flags.get(lift_flag(floor), false) == true:
			out.append(floor)
	return out


## The lift's conversation, in the shape of the ones in data/dialogue: an answer for every
## floor in `stops` (the `travel` effect takes him there, to `entry`), and one to stay.
func lift_dialogue(stops: Array[int], entry: StringName) -> Dictionary:
	var answers: Array = []
	for floor: int in stops:
		answers.append({"text": LIFT_FLOOR_WORDS % floor, "next": null,
			"effects": [{"type": "travel", "area": String(area_of(floor)), "entry": String(entry)}]})
	answers.append({"text": LIFT_STAY_WORDS, "next": null})
	var words: String = LIFT_WORDS if not stops.is_empty() else LIFT_NOWHERE_WORDS
	return {"id": "lift", "start": LIFT_ASK, "nodes": {LIFT_ASK: {"speaker": "", "text": words, "options": answers}}}


## What is wrong with `rules` as the mine's rules, in words: nothing, if they can be used.
## `item_of` gives the item entry for an id (empty if there is none).
static func problems(rules: Dictionary, item_of: Callable) -> PackedStringArray:
	var out: PackedStringArray = []
	if str(rules.get("hall", "")).is_empty():
		out.append("'hall' must name the area the mine is entered through.")
	var rocks: Variant = rules.get("rocks")
	if typeof(rocks) != TYPE_DICTIONARY or not (rocks as Dictionary).has(String(STONE)):
		out.append("'rocks' must be an object of kinds of rock, 'stone' among them.")
		return out
	for kind: Variant in rocks:
		var rock: Variant = rocks[kind]
		if typeof(rock) != TYPE_DICTIONARY or not _is_whole((rock as Dictionary).get("blows")) or int(rock["blows"]) < 1:
			out.append("rock '%s' needs 'blows', a whole number of 1 or more." % kind)
			continue
		if (item_of.call(str((rock as Dictionary).get("gives", ""))) as Dictionary).is_empty():
			out.append("rock '%s' gives an unknown item id '%s'." % [kind, (rock as Dictionary).get("gives", "")])
	var floors: Variant = rules.get("floors")
	if typeof(floors) != TYPE_ARRAY or (floors as Array).is_empty():
		out.append("'floors' must list one floor or more.")
		return out
	var areas: Array = []
	for index: int in (floors as Array).size():
		var entry: Variant = floors[index]
		if typeof(entry) != TYPE_DICTIONARY or str((entry as Dictionary).get("area", "")).is_empty():
			out.append("floor %d must name its 'area'." % (index + 1))
			continue
		if areas.has(str(entry["area"])):
			out.append("floor %d: area '%s' is a floor already." % [index + 1, entry["area"]])
		areas.append(str(entry["area"]))
		var ores: Variant = (entry as Dictionary).get("ores", {})
		if typeof(ores) != TYPE_DICTIONARY:
			out.append("floor %d: 'ores' must be an object of kind -> how many rocks." % (index + 1))
			continue
		for kind: Variant in ores:
			if str(kind) == String(STONE) or not (rocks as Dictionary).has(str(kind)):
				out.append("floor %d: '%s' is not a kind of ore in 'rocks'." % [index + 1, kind])
			elif not _is_whole(ores[kind]) or int(ores[kind]) < 0:
				out.append("floor %d: '%s' needs a whole number of rocks, 0 or more." % [index + 1, kind])
	var lift: Variant = rules.get("lift", [])
	if typeof(lift) != TYPE_ARRAY:
		out.append("'lift' must be a list of floor numbers.")
	else:
		for stop: Variant in lift:
			if not _is_whole(stop) or int(stop) < 1 or int(stop) > (floors as Array).size():
				out.append("'lift' names floor '%s', which there isn't." % stop)
	return out


static func _is_whole(value: Variant) -> bool:
	return (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and float(value) == floorf(float(value))
