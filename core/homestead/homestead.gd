class_name Homestead
extends RefCounted
## The hero's homestead (2026-11-17, docs/TECH_DESIGN.md §30), pure: what he has done to his
## land. Phase 1: the overgrowth he has cleared, a cell of the homestead's map whose weeds,
## bush, log, stump, rock or boulder is gone, and which no morning brings back. Phase 2: what
## he has set down, a cell to two things at most, one lying (a path, a floor, a flower bed) and
## one standing (a fence, a gate, a lamp post, a sapling), each an item's id, and for a sapling
## the mornings it has seen. Cells are the map's own (the area `homestead`). It knows nothing
## of what an item is: Placement says what fits where, and GameState goes through both.
## Phase 3: the buildings, one of each at most, each where its top-left corner stands, the day
## its kit was set down (it is a building site that day, and stands from the next morning) and
## the day its upgrade was bought (finished the next morning); and the hay the silo holds. It
## knows nothing of a building's size: Buildings does, and GameState asks both.
## GameState keeps one and saves it (the save's section `homestead`); later phases keep more.

## The cells cleared for good: key ("x,y", as Farm keeps its cells) -> true.
var _cleared: Dictionary = {}
## What lies in a cell: key -> item id (String).
var _lying: Dictionary = {}
## What stands in a cell: key -> { "item": id (String), "age": mornings seen (a sapling's) }.
var _standing: Dictionary = {}
## The buildings: id (String) -> { "at": Vector2i (its top-left corner), "day": the day it was
## set down, "big_day": the day its upgrade was bought, 0 for none }.
var _buildings: Dictionary = {}
## The hay in the silo.
var hay: int = 0


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


## Whether `id` stands on the land, or is a site there.
func has_building(id: StringName) -> bool:
	return _buildings.has(String(id))


## The ids of every building and site, by id.
func building_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for id: String in _buildings:
		out.append(StringName(id))
	out.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return out


## Where building `id`'s top-left corner is (Buildings.NO_CELL for none).
func building_at(id: StringName) -> Vector2i:
	return (_buildings.get(String(id), {}) as Dictionary).get("at", Buildings.NO_CELL)


## The day building `id`'s kit was set down (0 for none).
func building_day(id: StringName) -> int:
	return int((_buildings.get(String(id), {}) as Dictionary).get("day", 0))


## Whether building `id` stands on `today`: it was set down on an earlier day.
func is_standing(id: StringName, today: int) -> bool:
	return has_building(id) and today > building_day(id)


## Whether building `id` is a site on `today`: set down today, standing tomorrow.
func is_site(id: StringName, today: int) -> bool:
	return has_building(id) and not is_standing(id, today)


## Whether building `id` is its bigger self on `today`: its upgrade was bought on an earlier day.
func is_big(id: StringName, today: int) -> bool:
	var big_day: int = int((_buildings.get(String(id), {}) as Dictionary).get("big_day", 0))
	return big_day > 0 and today > big_day


## Whether building `id`'s upgrade is bought and not finished yet on `today`.
func is_upgrading(id: StringName, today: int) -> bool:
	var big_day: int = int((_buildings.get(String(id), {}) as Dictionary).get("big_day", 0))
	return big_day > 0 and today <= big_day


## Whether building `id` has its upgrade, finished or on its way.
func has_upgrade(id: StringName) -> bool:
	return int((_buildings.get(String(id), {}) as Dictionary).get("big_day", 0)) > 0


## A kit is set down: building `id` is a site with its top-left corner at `at`, from `today`.
## Returns whether it was: false for one that is there already (one of each), and for no cell.
func put_building(id: StringName, at: Vector2i, today: int) -> bool:
	if id == &"" or has_building(id) or at.x < 0 or at.y < 0:
		return false
	_buildings[String(id)] = {"at": at, "day": maxi(today, 0), "big_day": 0}
	return true


## Building `id`'s upgrade is bought on `today`: it is finished the next morning. Returns
## whether it was: not for a site, one that has it already, or none.
func upgrade(id: StringName, today: int) -> bool:
	if not is_standing(id, today) or has_upgrade(id):
		return false
	_buildings[String(id)]["big_day"] = maxi(today, 1)
	return true


## Moves building `id` (or its site) so that its top-left corner is at `to`, as it is: what is
## in it goes with it. Returns whether it moved.
func move_building(id: StringName, to: Vector2i) -> bool:
	if not has_building(id) or to.x < 0 or to.y < 0 or to == building_at(id):
		return false
	_buildings[String(id)]["at"] = to
	return true


## Takes building `id` off the land (it is pulled down, or its site taken up). Returns whether
## it was there.
func remove_building(id: StringName) -> bool:
	return _buildings.erase(String(id))


## The buildings that a morning of `today` finished: sites set down the day before, and
## upgrades bought the day before. [{ "id", "big": whether it was the upgrade }]
func finished_on(today: int) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id: StringName in building_ids():
		var entry: Dictionary = _buildings[String(id)]
		if int(entry["day"]) == today - 1:
			out.append({"id": id, "big": false})
		elif int(entry["big_day"]) == today - 1 and int(entry["big_day"]) > 0:
			out.append({"id": id, "big": true})
	return out


## Puts `count` hay in the silo, up to `most` in all. Returns how many went in.
func add_hay(count: int, most: int) -> int:
	var room: int = maxi(most - hay, 0)
	var added: int = clampi(count, 0, room)
	hay += added
	return added


## The homestead as it is saved, each part row by row:
##   { "cleared": ["x,y", ...], "lying": { "x,y": item id },
##     "standing": { "x,y": { "item": id, "age": mornings } },
##     "buildings": { id: { "at": "x,y", "day": n, "big_day": n } }, "hay": n }
## "lying" and "standing" are there only when something lies or stands (a homestead with
## nothing set down is saved as phase 1 saved it), and "age" only for what has seen a morning;
## "buildings" only when one is set down, "big_day" only for one with its upgrade, and "hay"
## only when the silo holds some.
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
	var buildings: Dictionary = {}
	for id: StringName in building_ids():
		var entry: Dictionary = _buildings[String(id)]
		var saved: Dictionary = {"at": Farm.key(entry["at"]), "day": int(entry["day"])}
		if int(entry["big_day"]) > 0:
			saved["big_day"] = int(entry["big_day"])
		buildings[String(id)] = saved
	if not buildings.is_empty():
		out["buildings"] = buildings
	if hay > 0:
		out["hay"] = hay
	return out


## Takes up a saved homestead in place of this one. Anything in it that doesn't read as what
## it should be is left out; a save with no homestead in it (or one that isn't what it should
## be) is a homestead with nothing cleared and nothing set down, and one from before things
## could be set down (phase 1's) has nothing set down. `layer_of` gives the layer an item id
## (String) belongs on (Placement.LYING, STANDING, or &"" for what is no placeable): a thing
## saved on another layer than its own, or that the game no longer has, is left out. Without
## it, every item is taken at its word.
func load_saved(saved: Variant, layer_of: Callable = Callable(), is_building: Callable = Callable()) -> void:
	_cleared.clear()
	_lying.clear()
	_standing.clear()
	_buildings.clear()
	hay = 0
	if typeof(saved) != TYPE_DICTIONARY:
		return
	# Phase 3's buildings and hay: a save from before them has none (each is read with a
	# default), and a building the game no longer has is left out (`is_building`).
	var buildings: Variant = (saved as Dictionary).get("buildings")
	if typeof(buildings) == TYPE_DICTIONARY:
		for id: Variant in (buildings as Dictionary):
			var entry: Variant = buildings[id]
			if typeof(entry) != TYPE_DICTIONARY or typeof((entry as Dictionary).get("at")) != TYPE_STRING:
				continue
			if is_building.is_valid() and not bool(is_building.call(str(id))):
				continue
			if put_building(StringName(str(id)), Farm.cell_of(str(entry["at"])), int((entry as Dictionary).get("day", 0))):
				_buildings[str(id)]["big_day"] = maxi(int((entry as Dictionary).get("big_day", 0)), 0)
	hay = maxi(int((saved as Dictionary).get("hay", 0)), 0) if typeof((saved as Dictionary).get("hay")) in [TYPE_INT, TYPE_FLOAT] else 0
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
