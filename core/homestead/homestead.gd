class_name Homestead
extends RefCounted
## The hero's homestead (2026-11-17, docs/TECH_DESIGN.md §30), pure: what he has done to his
## land. Phase 1: the overgrowth he has cleared, a cell of the homestead's map whose weeds,
## bush, log, stump, rock or boulder is gone, and which no morning brings back. Phase 2: what
## he has set down, a cell to two things at most, one lying (a path, a floor, a flower bed) and
## one standing (a fence, a gate, a lamp post, a sapling), each an item's id, and for a sapling
## the mornings it has seen. Cells are the map's own (the area `homestead`). It knows nothing
## of what an item is: Placement says what fits where, and GameState goes through both.
## GameState keeps one and saves it (the save's section `homestead`); later phases keep more.

## The cells cleared for good: key ("x,y", as Farm keeps its cells) -> true.
var _cleared: Dictionary = {}
## What lies in a cell: key -> item id (String).
var _lying: Dictionary = {}
## What stands in a cell: key -> { "item": id (String), "age": mornings seen (a sapling's) }.
var _standing: Dictionary = {}


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


## The id of the item lying in `cell`, or &"" if nothing does.
func lying_at(cell: Vector2i) -> StringName:
	return StringName(str(_lying.get(Farm.key(cell), "")))


## The id of the item standing in `cell`, or &"" if nothing does.
func standing_at(cell: Vector2i) -> StringName:
	return StringName(str((_standing.get(Farm.key(cell), {}) as Dictionary).get("item", "")))


## The id of what is in `cell` on `layer` (Placement.LYING or STANDING), or &"".
func thing_at(cell: Vector2i, layer: StringName) -> StringName:
	return lying_at(cell) if layer == Placement.LYING else (standing_at(cell) if layer == Placement.STANDING else &"")


## How many mornings what stands in `cell` has seen there (0 for nothing).
func age_at(cell: Vector2i) -> int:
	return int((_standing.get(Farm.key(cell), {}) as Dictionary).get("age", 0))


## Sets `item_id` down in `cell` on `layer`, having seen `age` mornings. Returns whether it
## did: false where something of that layer is already, and for what is no cell, no layer or
## no item.
func set_down(cell: Vector2i, layer: StringName, item_id: StringName, age: int = 0) -> bool:
	if cell.x < 0 or cell.y < 0 or item_id == &"" or not Placement.LAYERS.has(layer) or thing_at(cell, layer) != &"":
		return false
	if layer == Placement.LYING:
		_lying[Farm.key(cell)] = String(item_id)
	else:
		_standing[Farm.key(cell)] = {"item": String(item_id), "age": maxi(age, 0)}
	return true


## Takes up what is in `cell` on `layer`. Returns its item id, or &"" if nothing was there.
func take_up(cell: Vector2i, layer: StringName) -> StringName:
	var item_id: StringName = thing_at(cell, layer)
	if item_id == &"":
		return &""
	if layer == Placement.LYING:
		_lying.erase(Farm.key(cell))
	else:
		_standing.erase(Farm.key(cell))
	return item_id


## Moves what is in `from` on `layer` to `to`, as it is (a sapling keeps its mornings). Returns
## whether it moved: false with nothing to move, or with something of that layer at `to`.
func move(from: Vector2i, to: Vector2i, layer: StringName) -> bool:
	var item_id: StringName = thing_at(from, layer)
	if item_id == &"" or from == to or to.x < 0 or to.y < 0 or thing_at(to, layer) != &"":
		return false
	var age: int = age_at(from) if layer == Placement.STANDING else 0
	take_up(from, layer)
	return set_down(to, layer, item_id, age)


## Everything set down on `layer`, row by row: [{ "cell": Vector2i, "item": StringName,
## "age": int }].
func placed(layer: StringName) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var source: Dictionary = _lying if layer == Placement.LYING else (_standing if layer == Placement.STANDING else {})
	for cell_key: String in source:
		var cell: Vector2i = Farm.cell_of(cell_key)
		out.append({"cell": cell, "item": thing_at(cell, layer), "age": age_at(cell) if layer == Placement.STANDING else 0})
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		var first: Vector2i = a["cell"]
		var second: Vector2i = b["cell"]
		return first.y < second.y or (first.y == second.y and first.x < second.x))
	return out


## How many things are set down, lying and standing together.
func placed_count() -> int:
	return _lying.size() + _standing.size()


## A morning comes to what grows: everything standing whose item is in `mornings` (item id
## (String) -> the mornings it takes to be a tree) has seen one more, up to that many. Nothing
## else changes: what is cleared stays cleared, and what is set down stays where it is. Returns
## whether anything grew.
func grow(mornings: Dictionary) -> bool:
	var grew: bool = false
	for cell_key: String in _standing:
		var thing: Dictionary = _standing[cell_key]
		var full: int = int(mornings.get(str(thing.get("item", "")), 0))
		if int(thing.get("age", 0)) < full:
			thing["age"] = int(thing.get("age", 0)) + 1
			grew = true
	return grew


## The homestead as it is saved, each part row by row:
##   { "cleared": ["x,y", ...], "lying": { "x,y": item id },
##     "standing": { "x,y": { "item": id, "age": mornings } } }
## "lying" and "standing" are there only when something lies or stands (a homestead with
## nothing set down is saved as phase 1 saved it), and "age" only for what has seen a morning.
func to_dict() -> Dictionary:
	var cleared: Array = []
	for cell: Vector2i in cleared_cells():
		cleared.append(Farm.key(cell))
	var out: Dictionary = {"cleared": cleared}
	var lying: Dictionary = {}
	for thing: Dictionary in placed(Placement.LYING):
		lying[Farm.key(thing["cell"])] = String(thing["item"])
	if not lying.is_empty():
		out["lying"] = lying
	var standing: Dictionary = {}
	for thing: Dictionary in placed(Placement.STANDING):
		var entry: Dictionary = {"item": String(thing["item"])}
		if int(thing["age"]) > 0:
			entry["age"] = int(thing["age"])
		standing[Farm.key(thing["cell"])] = entry
	if not standing.is_empty():
		out["standing"] = standing
	return out


## Takes up a saved homestead in place of this one. Anything in it that doesn't read as what
## it should be is left out; a save with no homestead in it (or one that isn't what it should
## be) is a homestead with nothing cleared and nothing set down, and one from before things
## could be set down (phase 1's) has nothing set down. `layer_of` gives the layer an item id
## (String) belongs on (Placement.LYING, STANDING, or &"" for what is no placeable): a thing
## saved on another layer than its own, or that the game no longer has, is left out. Without
## it, every item is taken at its word.
func load_saved(saved: Variant, layer_of: Callable = Callable()) -> void:
	_cleared.clear()
	_lying.clear()
	_standing.clear()
	if typeof(saved) != TYPE_DICTIONARY:
		return
	var cleared: Variant = (saved as Dictionary).get("cleared")
	if typeof(cleared) == TYPE_ARRAY:
		for cell_key: Variant in (cleared as Array):
			if typeof(cell_key) == TYPE_STRING:
				clear(Farm.cell_of(str(cell_key)))
	var lying: Variant = (saved as Dictionary).get("lying")
	if typeof(lying) == TYPE_DICTIONARY:
		for cell_key: Variant in (lying as Dictionary):
			var item_id: Variant = lying[cell_key]
			if typeof(item_id) == TYPE_STRING and _belongs(str(item_id), Placement.LYING, layer_of):
				set_down(Farm.cell_of(str(cell_key)), Placement.LYING, StringName(str(item_id)))
	var standing: Variant = (saved as Dictionary).get("standing")
	if typeof(standing) == TYPE_DICTIONARY:
		for cell_key: Variant in (standing as Dictionary):
			var thing: Variant = standing[cell_key]
			if typeof(thing) != TYPE_DICTIONARY or typeof((thing as Dictionary).get("item")) != TYPE_STRING:
				continue
			if _belongs(str(thing["item"]), Placement.STANDING, layer_of):
				set_down(Farm.cell_of(str(cell_key)), Placement.STANDING, StringName(str(thing["item"])), int((thing as Dictionary).get("age", 0)))


## Whether `item_id` belongs on `layer`, by `layer_of` (anything does, if there is none to ask).
static func _belongs(item_id: String, layer: StringName, layer_of: Callable) -> bool:
	return not item_id.is_empty() and (not layer_of.is_valid() or StringName(str(layer_of.call(item_id))) == layer)
