class_name MineState
extends RefCounted
## What the mine remembers (2026-11-17, docs/TECH_DESIGN.md §27), pure: the number its daily
## rolls come from, and which rocks have been broken today. A broken rock stays broken until
## the next morning: the list belongs to one day, and is emptied when another begins. It keeps
## no rules (MineRules) and makes no rolls (MineRolls). GameState holds one and saves it.

## The number the rolls come from: set once for a game, kept in its save.
var number: int = 0
## The day the broken rocks belong to.
var day: int = 0

## area id (String) -> { "x,y": true }, the cells of the rocks broken today.
var _broken: Dictionary = {}


func _init(roll_number: int = 0) -> void:
	number = roll_number


static func key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]


## It is `today`: if that is another day than the broken rocks belong to, they are whole
## again. Returns whether a new day began.
func start_day(today: int) -> bool:
	if today == day:
		return false
	day = today
	_broken.clear()
	return true


## Whether the rock at `cell` of `area` has been broken on `today`.
func is_broken(area: StringName, cell: Vector2i, today: int) -> bool:
	return today == day and (_broken.get(String(area), {}) as Dictionary).has(key(cell))


## The rock at `cell` of `area` is broken, on `today`.
func mark_broken(area: StringName, cell: Vector2i, today: int) -> void:
	start_day(today)
	if not _broken.has(String(area)):
		_broken[String(area)] = {}
	(_broken[String(area)] as Dictionary)[key(cell)] = true


## How many of `area`'s rocks have been broken on `today`.
func broken_count(area: StringName, today: int) -> int:
	return (_broken.get(String(area), {}) as Dictionary).size() if today == day else 0


## JSON-safe: { "number", "day", "broken": { area: ["x,y", ...] } }.
func to_dict() -> Dictionary:
	var broken: Dictionary = {}
	for area: String in _broken:
		var cells: Array = (_broken[area] as Dictionary).keys()
		cells.sort()
		broken[area] = cells
	return {"number": number, "day": day, "broken": broken}


## Takes what a save holds. Anything that isn't in the right shape is left out; a save with no
## number keeps the one this state has.
func load_saved(saved: Variant) -> void:
	_broken.clear()
	day = 0
	if typeof(saved) != TYPE_DICTIONARY:
		return
	var data: Dictionary = saved
	if _is_whole(data.get("number")):
		number = int(data["number"])
	if _is_whole(data.get("day")):
		day = maxi(int(data["day"]), 0)
	var broken: Variant = data.get("broken")
	if typeof(broken) != TYPE_DICTIONARY:
		return
	for area: Variant in broken:
		if typeof(broken[area]) != TYPE_ARRAY:
			continue
		var cells: Dictionary = {}
		for cell: Variant in broken[area]:
			if typeof(cell) == TYPE_STRING and (cell as String).split(",").size() == 2:
				cells[cell] = true
		if not cells.is_empty():
			_broken[str(area)] = cells


static func _is_whole(value: Variant) -> bool:
	return (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and float(value) == floorf(float(value))
