class_name Farm
extends RefCounted
## The hero's plot (P3, GDD §7), pure: which of its cells are tilled and which are watered, what
## the hoe and the can do to one, and what a new morning does. Cells are the plot's own ((0, 0)
## is its north-west corner), so the plot can stand anywhere on a map. The numbers are data
## (data/rules/farm.json). GameState keeps one and saves it.

## What a missing rule falls back to (a test checks they are the game's own rules).
const DEFAULTS: Dictionary = {"plot": {"columns": 6, "rows": 3}, "wither_after": 2}
## What a cell can be.
const BARE: StringName = &"bare"
const TILLED: StringName = &"tilled"
const WATERED: StringName = &"watered"

## The plot's size in cells.
var size: Vector2i
## How many dry mornings in a row wither a crop (3b).
var wither_after: int
## The tilled cells: key ("x,y") -> { "watered": bool }. A cell that isn't here is bare.
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


## What `cell` is: bare, tilled or watered (watered soil is tilled too). Bare outside the plot.
func state_of(cell: Vector2i) -> StringName:
	if not _cells.has(key(cell)):
		return BARE
	return WATERED if bool((_cells[key(cell)] as Dictionary).get("watered", false)) else TILLED


func is_tilled(cell: Vector2i) -> bool:
	return state_of(cell) != BARE


func is_watered(cell: Vector2i) -> bool:
	return state_of(cell) == WATERED


## Tills `cell` with the hoe. Returns whether it did: false outside the plot, or if the cell
## was tilled already.
func till(cell: Vector2i) -> bool:
	if not has(cell) or is_tilled(cell):
		return false
	_cells[key(cell)] = {"watered": false}
	return true


## Waters `cell` with the can. Returns whether it did: false unless the cell is tilled and dry.
func water(cell: Vector2i) -> bool:
	if state_of(cell) != TILLED:
		return false
	_cells[key(cell)]["watered"] = true
	return true


## A new morning: watered soil is dry again. Tilled soil stays tilled.
func new_day() -> void:
	for cell_key: String in _cells:
		_cells[cell_key]["watered"] = false


## How many cells are in `state` (TILLED counts the dry ones only).
func count_of(state: StringName) -> int:
	var count: int = 0
	for x: int in size.x:
		for y: int in size.y:
			if state_of(Vector2i(x, y)) == state:
				count += 1
	return count


## The farm as it is saved: { "cells": { "x,y": { "watered": bool } } }.
func to_dict() -> Dictionary:
	var cells: Dictionary = {}
	for cell_key: String in _cells:
		cells[cell_key] = {"watered": bool(_cells[cell_key].get("watered", false))}
	return {"cells": cells}


## Takes up a saved farm in place of this one. Anything in it that isn't a cell of the plot
## is left out, so a save can't put soil where there is none.
func load_saved(saved: Variant) -> void:
	_cells.clear()
	if typeof(saved) != TYPE_DICTIONARY or typeof((saved as Dictionary).get("cells")) != TYPE_DICTIONARY:
		return
	var cells: Dictionary = saved["cells"]
	for cell_key: Variant in cells:
		if not has(cell_of(str(cell_key))) or typeof(cells[cell_key]) != TYPE_DICTIONARY:
			continue
		_cells[key(cell_of(str(cell_key)))] = {"watered": bool((cells[cell_key] as Dictionary).get("watered", false))}


## What is wrong with `rules` as the farm's rules, in words: nothing, if they can be used.
static func problems(rules: Dictionary) -> PackedStringArray:
	var out: PackedStringArray = []
	var plot: Variant = rules.get("plot")
	if typeof(plot) != TYPE_DICTIONARY or not _is_whole((plot as Dictionary).get("columns")) or not _is_whole((plot as Dictionary).get("rows")):
		out.append("'plot' needs 'columns' and 'rows', each a whole number of 1 or more.")
	if not _is_whole(rules.get("wither_after")):
		out.append("'wither_after' must be a whole number of 1 or more: the dry mornings that wither a crop.")
	return out


static func _is_whole(value: Variant) -> bool:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return false
	return float(value) >= 1.0 and float(value) == roundf(float(value))
