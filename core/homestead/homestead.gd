class_name Homestead
extends RefCounted
## The hero's homestead (2026-11-17, docs/TECH_DESIGN.md §30), pure: what he has done to his
## land that is for good. In phase 1 that is the overgrowth he has cleared: a cell of the
## homestead's map whose weeds, bush, log, stump, rock or boulder is gone, and which no morning
## brings back. Cells are the map's own (the area `homestead`). GameState keeps one and saves
## it (the save's section `homestead`); later phases keep more in it.

## The cells cleared for good: key ("x,y", as Farm keeps its cells) -> true.
var _cleared: Dictionary = {}


## Whether what stood in `cell` has been cleared.
func is_cleared(cell: Vector2i) -> bool:
	return _cleared.has(Farm.key(cell))


## What stood in `cell` is cleared, for good. Returns whether that is news: false for a cell
## cleared already, or one that is no cell at all.
func clear(cell: Vector2i) -> bool:
	if cell.x < 0 or cell.y < 0 or is_cleared(cell):
		return false
	_cleared[Farm.key(cell)] = true
	return true


## How many cells have been cleared.
func cleared_count() -> int:
	return _cleared.size()


## The cells cleared, row by row.
func cleared_cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for cell_key: String in _cleared:
		out.append(Farm.cell_of(cell_key))
	out.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	return out


## The homestead as it is saved: { "cleared": ["x,y", ...] }, row by row.
func to_dict() -> Dictionary:
	var cleared: Array = []
	for cell: Vector2i in cleared_cells():
		cleared.append(Farm.key(cell))
	return {"cleared": cleared}


## Takes up a saved homestead in place of this one. Anything in it that doesn't read as a cell
## is left out; a save with no homestead in it (or one that isn't what it should be) is a
## homestead with nothing cleared.
func load_saved(saved: Variant) -> void:
	_cleared.clear()
	if typeof(saved) != TYPE_DICTIONARY or typeof((saved as Dictionary).get("cleared")) != TYPE_ARRAY:
		return
	for cell_key: Variant in ((saved as Dictionary)["cleared"] as Array):
		if typeof(cell_key) == TYPE_STRING:
			clear(Farm.cell_of(str(cell_key)))
