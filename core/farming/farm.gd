class_name Farm
extends RefCounted
## The hero's plot (P3, GDD §7), pure: which of its cells are tilled and which are watered, what
## grows in each and how far along it is; what the hoe, the can, a seed and a harvesting hand do
## to one; and what a new morning does. Cells are the plot's own ((0, 0) is its north-west
## corner), so the plot can stand anywhere on a map: it lay in Hearthvale, 6 by 3, until the
## Homestead (2026-11-17), and is the field there now, 12 by 6, with the old plot's cells its
## north-west corner, so a saved plot is where it was. The numbers are data
## (data/rules/farm.json); how long a crop takes is the crop's own (data/crops), handed in by
## whoever asks. GameState keeps one farm and saves it.

## What a missing rule falls back to (a test checks they are the game's own rules).
const DEFAULTS: Dictionary = {"plot": {"columns": 12, "rows": 6}, "wither_after": 2}
## What a cell's soil can be.
const BARE: StringName = &"bare"
const TILLED: StringName = &"tilled"
const WATERED: StringName = &"watered"
## How far along a crop is (phase_of): just planted, a sprout, growing, ready to pick, or dead.
const SEEDED: StringName = &"seeded"
const SPROUT: StringName = &"sprout"
const GROWING: StringName = &"growing"
const RIPE: StringName = &"ripe"
const WITHERED: StringName = &"withered"
## The cells a sprinkler waters, from its own: the four beside it.
const SPRINKLER_SIDES: Array[Vector2i] = [Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT, Vector2i.DOWN]

## The plot's size in cells.
var size: Vector2i
## How many dry mornings in a row wither a crop.
var wither_after: int
## The tilled cells: key ("x,y") -> { "watered": bool, "crop": String, "stage": int, "dry": int,
## "withered": bool }. A cell that isn't here is bare; a cell with no crop has "" for one.
var _cells: Dictionary = {}


func _init(rules: Dictionary = {}) -> void:
	var plot: Variant = rules.get("plot", DEFAULTS["plot"])
	if typeof(plot) != TYPE_DICTIONARY:
		plot = DEFAULTS["plot"]
	size = Vector2i(maxi(int((plot as Dictionary).get("columns", 0)), 0), maxi(int((plot as Dictionary).get("rows", 0)), 0))
	wither_after = maxi(int(rules.get("wither_after", DEFAULTS["wither_after"])), 1)


## "x,y" for a cell: the key it is kept and saved under.
static func key(cell: Vector2i) -> String:
	return "%d,%d" % [cell.x, cell.y]


## The cell a key names, or (-1, -1) if it names none.
static func cell_of(cell_key: String) -> Vector2i:
	var parts: PackedStringArray = cell_key.split(",")
	if parts.size() != 2 or not parts[0].is_valid_int() or not parts[1].is_valid_int():
		return Vector2i(-1, -1)
	return Vector2i(int(parts[0]), int(parts[1]))


## Whether `cell` is one of the plot's.
func has(cell: Vector2i) -> bool:
	return Rect2i(Vector2i.ZERO, size).has_point(cell)


## What `cell`'s soil is: bare, tilled or watered (watered soil is tilled too). Bare outside
## the plot.
func state_of(cell: Vector2i) -> StringName:
	if not _cells.has(key(cell)):
		return BARE
	return WATERED if bool(_cells[key(cell)]["watered"]) else TILLED


func is_tilled(cell: Vector2i) -> bool:
	return state_of(cell) != BARE


func is_watered(cell: Vector2i) -> bool:
	return state_of(cell) == WATERED


## Tills `cell` with the hoe. Returns whether it did: false outside the plot, or if the cell
## was tilled already.
func till(cell: Vector2i) -> bool:
	if not has(cell) or is_tilled(cell):
		return false
	_cells[key(cell)] = _tilled()
	return true


## Waters `cell` with the can. Returns whether it did: false unless the cell is tilled and dry.
func water(cell: Vector2i) -> bool:
	if state_of(cell) != TILLED:
		return false
	_cells[key(cell)]["watered"] = true
	return true


# --- Crops ---------------------------------------------------------------------

## The crop in `cell` (a crop id), or "" if nothing is planted there.
func crop_at(cell: Vector2i) -> String:
	return str(_cells[key(cell)]["crop"]) if _cells.has(key(cell)) else ""


func has_crop(cell: Vector2i) -> bool:
	return not crop_at(cell).is_empty()


## How many mornings the crop in `cell` has grown.
func stage_of(cell: Vector2i) -> int:
	return int(_cells[key(cell)]["stage"]) if has_crop(cell) else 0


## How many mornings in a row the crop in `cell` has gone unwatered.
func dry_of(cell: Vector2i) -> int:
	return int(_cells[key(cell)]["dry"]) if has_crop(cell) else 0


func is_withered(cell: Vector2i) -> bool:
	return has_crop(cell) and bool(_cells[key(cell)]["withered"])


## Whether the crop in `cell` is ready to pick, for a crop that takes `days` mornings.
func is_ripe(cell: Vector2i, days: int) -> bool:
	return has_crop(cell) and not is_withered(cell) and stage_of(cell) >= maxi(days, 1)


## How far along the crop in `cell` is, for a crop that takes `days` mornings: SEEDED the day
## it is planted, a SPROUT for the first half of its growing, GROWING for the second, then
## RIPE; WITHERED if it died. "" if nothing is planted there.
func phase_of(cell: Vector2i, days: int) -> StringName:
	if not has_crop(cell):
		return &""
	if is_withered(cell):
		return WITHERED
	if is_ripe(cell, days):
		return RIPE
	if stage_of(cell) == 0:
		return SEEDED
	return SPROUT if stage_of(cell) * 2 < maxi(days, 1) else GROWING


## Plants `crop` (a crop id) in `cell`. Returns whether it did: false unless the cell is tilled
## and nothing is planted there.
func plant(cell: Vector2i, crop: String) -> bool:
	if crop.is_empty() or not is_tilled(cell) or has_crop(cell) or has_sprinkler(cell):
		return false
	_cells[key(cell)]["crop"] = crop
	return true


## Picks the ripe crop in `cell` (one that takes `days` mornings). Returns its crop id and
## leaves tilled soil, or "" if nothing there is ripe.
func harvest(cell: Vector2i, days: int) -> String:
	if not is_ripe(cell, days):
		return ""
	var crop: String = crop_at(cell)
	_empty(cell)
	return crop


## Clears a withered crop out of `cell`, leaving tilled soil. Returns whether one was there.
func clear_withered(cell: Vector2i) -> bool:
	if not is_withered(cell):
		return false
	_empty(cell)
	return true


## A new morning. A crop that was watered yesterday grows a stage; one that wasn't has had a
## dry morning, and after `wither_after` of those in a row it withers. A ripe crop waits as it
## is. Then the soil is dry again; tilled soil stays tilled. `days_by_crop` is how many
## mornings each crop takes (crop id -> days).
func new_day(days_by_crop: Dictionary = {}) -> void:
	for cell_key: String in _cells:
		var soil: Dictionary = _cells[cell_key]
		var cell: Vector2i = cell_of(cell_key)
		if has_crop(cell) and not is_withered(cell) and not is_ripe(cell, int(days_by_crop.get(soil["crop"], 1))):
			if bool(soil["watered"]):
				soil["stage"] = int(soil["stage"]) + 1
				soil["dry"] = 0
			else:
				soil["dry"] = int(soil["dry"]) + 1
				soil["withered"] = int(soil["dry"]) >= wither_after
		soil["watered"] = false
	# Then the sprinklers run: the morning's water, for what grows today.
	for cell_key: String in _cells:
		if bool(_cells[cell_key].get("sprinkler", false)):
			for cell: Vector2i in watered_by(cell_of(cell_key)):
				_cells[key(cell)]["watered"] = true


# --- Sprinklers (crafting, 2026-11-17) ---------------------------------------------

## Whether a sprinkler stands in `cell`.
func has_sprinkler(cell: Vector2i) -> bool:
	return has(cell) and is_tilled(cell) and bool(_cells[key(cell)].get("sprinkler", false))


## Sets a sprinkler in `cell`. Returns whether it did: false unless the cell is tilled soil
## with nothing growing in it and no sprinkler. Nothing can be planted where one stands.
func place_sprinkler(cell: Vector2i) -> bool:
	if not has(cell) or not is_tilled(cell) or has_crop(cell) or has_sprinkler(cell):
		return false
	_cells[key(cell)]["sprinkler"] = true
	return true


## Takes up the sprinkler in `cell`. Returns whether there was one.
func take_sprinkler(cell: Vector2i) -> bool:
	if not has_sprinkler(cell):
		return false
	_cells[key(cell)]["sprinkler"] = false
	return true


## The cells a sprinkler in `cell` waters each morning: of the four beside it (not the
## corners), those that are tilled soil of the plot.
func watered_by(cell: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for side: Vector2i in SPRINKLER_SIDES:
		if has(cell + side) and is_tilled(cell + side):
			out.append(cell + side)
	return out


func sprinkler_count() -> int:
	var count: int = 0
	for cell_key: String in _cells:
		if bool(_cells[cell_key].get("sprinkler", false)):
			count += 1
	return count


## How many cells are in `state` (TILLED counts the dry ones only).
func count_of(state: StringName) -> int:
	var count: int = 0
	for x: int in size.x:
		for y: int in size.y:
			if state_of(Vector2i(x, y)) == state:
				count += 1
	return count


## How many cells have something planted in them, alive or withered.
func crop_count() -> int:
	var count: int = 0
	for cell_key: String in _cells:
		if not str(_cells[cell_key]["crop"]).is_empty():
			count += 1
	return count


## The farm as it is saved: { "cells": { "x,y": { "watered": bool } } }, and for a cell with a
## crop its "crop", "stage", "dry" and "withered" too.
func to_dict() -> Dictionary:
	var cells: Dictionary = {}
	for cell_key: String in _cells:
		var soil: Dictionary = _cells[cell_key]
		var saved: Dictionary = {"watered": bool(soil["watered"])}
		if not str(soil["crop"]).is_empty():
			saved["crop"] = str(soil["crop"])
			saved["stage"] = int(soil["stage"])
			saved["dry"] = int(soil["dry"])
			saved["withered"] = bool(soil["withered"])
		if bool(soil.get("sprinkler", false)):
			saved["sprinkler"] = true
		cells[cell_key] = saved
	return {"cells": cells}


## Takes up a saved farm in place of this one. Anything in it that isn't a cell of the plot is
## left out, so a save can't put soil where there is none; and with `known_crops` (crop ids)
## given, a crop that isn't one of them is left out too, leaving tilled soil.
func load_saved(saved: Variant, known_crops: Array = []) -> void:
	_cells.clear()
	if typeof(saved) != TYPE_DICTIONARY or typeof((saved as Dictionary).get("cells")) != TYPE_DICTIONARY:
		return
	var cells: Dictionary = saved["cells"]
	for cell_key: Variant in cells:
		if not has(cell_of(str(cell_key))) or typeof(cells[cell_key]) != TYPE_DICTIONARY:
			continue
		var from: Dictionary = cells[cell_key]
		var soil: Dictionary = _tilled()
		soil["watered"] = bool(from.get("watered", false))
		var crop: String = str(from.get("crop", "")) if typeof(from.get("crop", "")) == TYPE_STRING else ""
		if not crop.is_empty() and (known_crops.is_empty() or known_crops.has(crop) or known_crops.has(StringName(crop))):
			soil["crop"] = crop
			soil["stage"] = maxi(int(from.get("stage", 0)), 0)
			soil["dry"] = maxi(int(from.get("dry", 0)), 0)
			soil["withered"] = bool(from.get("withered", false))
		# A sprinkler stands only where nothing grows.
		soil["sprinkler"] = typeof(from.get("sprinkler")) == TYPE_BOOL and bool(from["sprinkler"]) and str(soil["crop"]).is_empty()
		_cells[key(cell_of(str(cell_key)))] = soil


## What is wrong with `rules` as the farm's rules, in words: nothing, if they can be used.
static func problems(rules: Dictionary) -> PackedStringArray:
	var out: PackedStringArray = []
	var plot: Variant = rules.get("plot")
	if typeof(plot) != TYPE_DICTIONARY or not _is_whole((plot as Dictionary).get("columns")) or not _is_whole((plot as Dictionary).get("rows")):
		out.append("'plot' needs 'columns' and 'rows', each a whole number of 1 or more.")
	if not _is_whole(rules.get("wither_after")):
		out.append("'wither_after' must be a whole number of 1 or more: the dry mornings that wither a crop.")
	return out


## Tilled, dry soil with nothing in it.
static func _tilled() -> Dictionary:
	return {"watered": false, "crop": "", "stage": 0, "dry": 0, "withered": false, "sprinkler": false}


## Takes whatever grows in `cell` out of it; the soil stays as it is.
func _empty(cell: Vector2i) -> void:
	var soil: Dictionary = _cells[key(cell)]
	soil["crop"] = ""
	soil["stage"] = 0
	soil["dry"] = 0
	soil["withered"] = false


static func _is_whole(value: Variant) -> bool:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return false
	return float(value) >= 1.0 and float(value) == roundf(float(value))
