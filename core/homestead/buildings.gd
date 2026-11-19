class_name Buildings
extends RefCounted
## The buildings of the hero's land (the Homestead, phase 3; docs/TECH_DESIGN.md §30), pure:
## what a building is, where its cells, its door and its doorstep are, whether it fits, how it
## looks, and what pulling it down gives back. A building is data (data/buildings/<id>.json):
##   { "id": "coop", "name": "Coop", "size": [4, 3], "door": [2, 2], "room": "coop",
##     "animals": 4,
##     "big": { "name": "Big Coop", "animals": 8, "look": [...] },
##     "look": [[0, 0, 4, 2, "roof_thatch"], [0, 2, 4, 1, "wall"], [2, 2, 1, 1, "door"]] }
## - `size`: its cells, width by height. One of each building stands on the land at most.
## - `door` (a building with a room): the cell of its door, counted from its top-left corner,
##   in its bottom row. The cell below it is its doorstep, which must be free and stays free.
##   Without one it has no room and no doorstep (the Well, the Silo).
## - `room`: the area that is its inside (an 11 by 9 room whose doormat leads out before the
##   door, wherever the building stands).
## - `fills_can`: the watering can fills at it (the Well). `holds`: { "item", "count" }, what it
##   keeps and how much (the Silo's hay). `keeps`: { "furnaces": [...], "chests": [...] }, the
##   furnaces and chests of its room, by the keys GameState keeps them under (the Shed's), so
##   pulling it down waits until they are empty. `animals`: how many it has room for (phase 4
##   reads it; nothing does yet). `big`: its upgrade, the same place and size: its own name,
##   its animals and its look.
## - `look`: how it is drawn, as the map baker lays a house: blocks [x, y, width, height, kind]
##   of the greybox tiles (a roof's top row gets its ridge and its bottom row its eaves; a wall
##   a window every third cell; "well" and "silo" are 2 by 2 pictures), later blocks over
##   earlier ones; a house decoration (a chimney) is laid over what is under it. `shadow`
##   (true unless said) is the shadow a tall thing casts east and south.
## The kit that sets it down is an item of type "kit" whose stats name it ({"building": "coop"}),
## made at the workbench's "Build" tab, as is its upgrade ({"makes": {"upgrade": "coop"}}).
## Homestead keeps where each stands; Placement says whether each of its cells fits; GameState
## goes through both. So a new building is data and pictures.

const KIT_TYPE: String = "kit"
## No door, or no cell.
const NO_CELL: Vector2i = Vector2i(-1, -1)
## What Placement is asked about a building's cells: something that stands and blocks.
const STANDING_THING: Dictionary = {"type": Placement.TYPE, "stats": {"layer": "standing"}}
## The 2 by 2 pictures of a look: their kind, and the tile kinds of their quarters.
const QUARTERS: Dictionary = {
	"well": ["well_nw", "well_ne", "well_sw", "well_se"],
	"silo": ["silo_nw", "silo_ne", "silo_sw", "silo_se"],
}
## A building site's look: dug ground in every cell, and a stack of timber in the middle one.
const SITE_TILE: String = "site"
const SITE_TIMBER: String = "site_timber"
## The words of a building (its name and the like).
const STANDS_WORDS: String = "The %s stands on your farm."
const BIGGER_WORDS: String = "The %s is finished."


static func is_kit(item: Dictionary) -> bool:
	return str(item.get("type", "")) == KIT_TYPE


## The building a kit sets down (its stats' "building"), or &"" for what is no kit.
static func building_of_kit(item: Dictionary) -> StringName:
	if not is_kit(item):
		return &""
	var stats: Variant = item.get("stats", {})
	return StringName(str((stats as Dictionary).get("building", ""))) if typeof(stats) == TYPE_DICTIONARY else &""


## The kit among `items` (data entries) that sets down `building_id`, or &"" if there is none.
static func kit_for(building_id: StringName, items: Array) -> StringName:
	for item: Variant in items:
		if typeof(item) == TYPE_DICTIONARY and building_of_kit(item) == building_id and building_id != &"":
			return StringName(str((item as Dictionary).get("id", "")))
	return &""


static func size_of(building: Dictionary) -> Vector2i:
	return _cell_of(building.get("size"), Vector2i.ONE)


## Its door's cell from its top-left corner, or NO_CELL for one with no door.
static func door_of(building: Dictionary) -> Vector2i:
	return _cell_of(building.get("door"), NO_CELL)


static func has_door(building: Dictionary) -> bool:
	return door_of(building) != NO_CELL


## The area that is its inside, or &"" for one with no room.
static func room_of(building: Dictionary) -> StringName:
	return StringName(str(building.get("room", "")))


## The cell of it that the ghost holds in build mode (the mouse's cell): its door, or for one
## without, the middle of its bottom row.
static func anchor_of(building: Dictionary) -> Vector2i:
	if has_door(building):
		return door_of(building)
	var size: Vector2i = size_of(building)
	@warning_ignore("integer_division")
	return Vector2i(size.x / 2, size.y - 1)


## Where its top-left corner is when the ghost holds it at `cell`.
static func origin_at(building: Dictionary, cell: Vector2i) -> Vector2i:
	return cell - anchor_of(building)


## Its cells, standing with its top-left corner at `origin`, row by row.
static func cells_of(building: Dictionary, origin: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var size: Vector2i = size_of(building)
	for y: int in size.y:
		for x: int in size.x:
			out.append(origin + Vector2i(x, y))
	return out


## Whether it covers `cell`, standing at `origin`.
static func covers(building: Dictionary, origin: Vector2i, cell: Vector2i) -> bool:
	return Rect2i(origin, size_of(building)).has_point(cell)


## Its door's cell on the map, standing at `origin` (NO_CELL for one with no door).
static func door_cell(building: Dictionary, origin: Vector2i) -> Vector2i:
	return origin + door_of(building) if has_door(building) else NO_CELL


## The cell below its door, which must be free and stays free (NO_CELL for one with no door).
static func doorstep_of(building: Dictionary, origin: Vector2i) -> Vector2i:
	return door_cell(building, origin) + Vector2i.DOWN if has_door(building) else NO_CELL


## The cells it fills, standing at `origin`: all of them as a site; once it stands, all but
## its door, which the hero walks into to go in.
static func filled_cells(building: Dictionary, origin: Vector2i, standing: bool) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var door: Vector2i = door_cell(building, origin)
	for cell: Vector2i in cells_of(building, origin):
		if not (standing and cell == door):
			out.append(cell)
	return out


## Why it can't be set down with its top-left corner at `origin`, in Placement's words; "" if
## it can. Each of its cells, row by row, and then its doorstep is asked as a standing thing
## would be (`site_of` gives Placement.site() for a cell), and the first refusal found is the
## one said (the plan's D15).
static func why_not_at(building: Dictionary, origin: Vector2i, site_of: Callable) -> String:
	for cell: Vector2i in cells_and_doorstep(building, origin):
		var why: String = Placement.why_not(STANDING_THING, site_of.call(cell))
		if not why.is_empty():
			return why
	return ""


## Its cells, row by row, and then its doorstep (if it has a door).
static func cells_and_doorstep(building: Dictionary, origin: Vector2i) -> Array[Vector2i]:
	var out: Array[Vector2i] = cells_of(building, origin)
	if has_door(building):
		out.append(doorstep_of(building, origin))
	return out


## Whether the can fills at it (the Well).
static func fills_can(building: Dictionary) -> bool:
	return bool(building.get("fills_can", false))


## What it keeps and how much: { "item": id, "count": most }, or {} (the Silo's hay).
static func holds(building: Dictionary) -> Dictionary:
	var held: Variant = building.get("holds")
	if typeof(held) != TYPE_DICTIONARY or str((held as Dictionary).get("item", "")).is_empty():
		return {}
	return {"item": StringName(str(held["item"])), "count": maxi(int((held as Dictionary).get("count", 0)), 0)}


## The keys of the furnaces (or, with `chests`, the chests) of its room, as GameState keeps
## them.
static func kept_in(building: Dictionary, chests: bool) -> Array[StringName]:
	var out: Array[StringName] = []
	var keeps: Variant = building.get("keeps")
	if typeof(keeps) != TYPE_DICTIONARY:
		return out
	var keys: Variant = (keeps as Dictionary).get("chests" if chests else "furnaces", [])
	if typeof(keys) == TYPE_ARRAY:
		for key: Variant in keys:
			out.append(StringName(str(key)))
	return out


## Whether it has an upgrade.
static func has_big(building: Dictionary) -> bool:
	return typeof(building.get("big")) == TYPE_DICTIONARY


## Its name: its own, or with `big` its upgrade's.
static func name_of(building: Dictionary, big: bool = false) -> String:
	if big and has_big(building):
		return str((building["big"] as Dictionary).get("name", building.get("name", building.get("id", ""))))
	return str(building.get("name", building.get("id", "")))


## How many animals it has room for (phase 4 reads it), big or not.
static func animals_of(building: Dictionary, big: bool = false) -> int:
	if big and has_big(building):
		return maxi(int((building["big"] as Dictionary).get("animals", building.get("animals", 0))), 0)
	return maxi(int(building.get("animals", 0)), 0)


## Whether it casts a tall thing's shadow east and south.
static func casts_shadow(building: Dictionary) -> bool:
	return bool(building.get("shadow", true))


## Whether `building`'s windows glow with the lamps once it stands (its data's "lit_at_night").
static func lit_at_night(building: Dictionary) -> bool:
	return bool(building.get("lit_at_night", false))


## Its look's blocks: its own, or with `big` its upgrade's (its own if that names none).
static func look_of(building: Dictionary, big: bool = false) -> Array:
	if big and has_big(building) and typeof((building["big"] as Dictionary).get("look")) == TYPE_ARRAY:
		return building["big"]["look"]
	var look: Variant = building.get("look", [])
	return look if typeof(look) == TYPE_ARRAY else []


## The tile kind of each of its cells, from its top-left (cell -> GreyboxTiles kind), as the
## map baker would lay `blocks` (look_of): roofs with their ridge, eaves and gable ends, walls
## with a window every third cell, the 2 by 2 pictures in quarters. Decorations are left out
## (decor_of).
static func tiles_of(blocks: Array) -> Dictionary:
	var out: Dictionary = {}
	for block: Variant in blocks:
		if not _is_block(block):
			continue
		var kind: String = str(block[4])
		if GreyboxTiles.HOUSE_DECOR_KINDS.has(kind):
			continue
		for y: int in int(block[3]):
			for x: int in int(block[2]):
				out[Vector2i(int(block[0]) + x, int(block[1]) + y)] = detail(kind, x, y, int(block[2]), int(block[3]))
	return out


## The decorations laid over its tiles (a chimney): cell -> kind.
static func decor_of(blocks: Array) -> Dictionary:
	var out: Dictionary = {}
	for block: Variant in blocks:
		if _is_block(block) and GreyboxTiles.HOUSE_DECOR_KINDS.has(str(block[4])):
			for y: int in int(block[3]):
				for x: int in int(block[2]):
					out[Vector2i(int(block[0]) + x, int(block[1]) + y)] = str(block[4])
	return out


## A building site's look over `size`: dug ground, and timber in the middle cell.
static func site_tiles(size: Vector2i) -> Dictionary:
	var out: Dictionary = {}
	@warning_ignore("integer_division")
	var middle: Vector2i = Vector2i((size.x - 1) / 2, size.y - 1)
	for y: int in size.y:
		for x: int in size.x:
			out[Vector2i(x, y)] = SITE_TIMBER if Vector2i(x, y) == middle else SITE_TILE
	return out


## The tile for cell (dx, dy) of a look block of `kind`, `width` by `height`: what the map
## baker lays for a house (tools/greybox/build_maps.gd, _detail), and a quarter of a 2 by 2
## picture.
static func detail(kind: String, dx: int, dy: int, width: int, height: int) -> String:
	if QUARTERS.has(kind):
		return QUARTERS[kind][(dy % 2) * 2 + (dx % 2)]
	match kind:
		"roof", "roof_blue", "roof_thatch", "roof_shingle", "roof_green":
			var part: String = ""
			if height >= 2 and dy == 0:
				part = "_top"
			elif height >= 2 and dy == height - 1:
				part = "_eave"
			var edge: String = ""
			if width >= 2 and dx == 0:
				edge = "_l"
			elif width >= 2 and dx == width - 1:
				edge = "_r"
			return kind + part + edge
		"wall":
			if width >= 4 and dx % 3 == 1 and dx < width - 1:
				return "wall_window"
		"wall_upper":
			if width >= 4 and dx % 3 == 1 and dx < width - 1:
				return "wall_upper_window"
			return "wall_upper" if dx % 2 == 0 else "wall_upper_b"
	return kind


## Half of each thing in `needs` ([{ "item", "count" }], what went into it), rounded down, and
## none of the coins: what pulling it down gives back. Things of which half is nothing are
## left out.
static func refund(needs: Array, coin: String = "coin") -> Array[Dictionary]:
	var totals: Dictionary = {}
	var order: Array[String] = []
	for need: Variant in needs:
		if typeof(need) != TYPE_DICTIONARY:
			continue
		var item: String = str((need as Dictionary).get("item", ""))
		if item.is_empty() or item == coin:
			continue
		if not totals.has(item):
			order.append(item)
		totals[item] = int(totals.get(item, 0)) + maxi(int((need as Dictionary).get("count", 0)), 0)
	var out: Array[Dictionary] = []
	for item: String in order:
		@warning_ignore("integer_division")
		var back: int = int(totals[item]) / 2
		if back > 0:
			out.append({"item": item, "count": back})
	return out


## What is wrong with `building` (a data entry), in words: nothing, if it can be used.
## `is_tile` says whether a look's kind is a tile the game has; `is_room` whether an area id
## is one that may be a building's inside (its scene is there).
static func problems(building: Dictionary, is_tile: Callable, is_room: Callable) -> PackedStringArray:
	var out: PackedStringArray = []
	var size: Variant = building.get("size")
	if not _is_pair(size) or int(size[0]) < 1 or int(size[1]) < 1:
		out.append("'size' must be [width, height], each 1 or more.")
		return out
	var cells: Vector2i = size_of(building)
	if building.has("door"):
		var door: Variant = building["door"]
		if not _is_pair(door):
			out.append("'door' must be [x, y], a cell of the building.")
		elif not Rect2i(Vector2i.ZERO, cells).has_point(door_of(building)) or door_of(building).y != cells.y - 1:
			out.append("'door' must be a cell of the building's bottom row.")
		if room_of(building) == &"":
			out.append("a building with a door has a 'room' to go into.")
	if building.has("room"):
		if not building.has("door"):
			out.append("a building with a 'room' needs a 'door' to it.")
		if not bool(is_room.call(String(room_of(building)))):
			out.append("'room' names no room the game has: '%s'." % building["room"])
	if building.has("holds"):
		var held: Variant = building["holds"]
		if typeof(held) != TYPE_DICTIONARY or str((held as Dictionary).get("item", "")).is_empty() or not _is_whole((held as Dictionary).get("count")) or int(held["count"]) < 1:
			out.append("'holds' must name an 'item' and a 'count' of 1 or more.")
	for number: String in ["animals"]:
		if building.has(number) and (not _is_whole(building[number]) or int(building[number]) < 0):
			out.append("'%s' must be a whole number of 0 or more." % number)
	out.append_array(_look_problems(look_of(building), cells, is_tile, "look"))
	if building.has("big"):
		var big: Variant = building["big"]
		if typeof(big) != TYPE_DICTIONARY or str((big as Dictionary).get("name", "")).is_empty():
			out.append("'big' must be an object with a 'name' (the upgrade's).")
		else:
			if (big as Dictionary).has("animals") and (not _is_whole(big["animals"]) or int(big["animals"]) < 0):
				out.append("'big' 'animals' must be a whole number of 0 or more.")
			if (big as Dictionary).has("look"):
				out.append_array(_look_problems(big["look"] if typeof(big["look"]) == TYPE_ARRAY else [null], cells, is_tile, "big look"))
	return out


static func _look_problems(blocks: Array, size: Vector2i, is_tile: Callable, what: String) -> PackedStringArray:
	var out: PackedStringArray = []
	if blocks.is_empty():
		out.append("'%s' must list one block or more." % what)
	for block: Variant in blocks:
		if not _is_block(block):
			out.append("every block of '%s' is [x, y, width, height, kind]." % what)
			continue
		var rect: Rect2i = Rect2i(int(block[0]), int(block[1]), int(block[2]), int(block[3]))
		if rect.size.x < 1 or rect.size.y < 1 or not Rect2i(Vector2i.ZERO, size).encloses(rect):
			out.append("a block of '%s' lies outside the building: %s." % [what, block])
		var kind: String = str(block[4])
		if QUARTERS.has(kind):
			if rect.size.x % 2 != 0 or rect.size.y % 2 != 0:
				out.append("'%s' is a 2 by 2 picture: its block must be whole pictures." % kind)
		elif not ["roof", "roof_blue", "roof_thatch", "roof_shingle", "roof_green", "wall", "wall_upper"].has(kind) and not bool(is_tile.call(kind)):
			out.append("'%s' names an unknown tile '%s'." % [what, kind])
	return out


static func _is_block(block: Variant) -> bool:
	if typeof(block) != TYPE_ARRAY or (block as Array).size() != 5 or typeof(block[4]) != TYPE_STRING:
		return false
	for index: int in 4:
		if not _is_whole(block[index]):
			return false
	return true


static func _is_pair(value: Variant) -> bool:
	return typeof(value) == TYPE_ARRAY and (value as Array).size() == 2 and _is_whole(value[0]) and _is_whole(value[1])


static func _cell_of(value: Variant, otherwise: Vector2i) -> Vector2i:
	return Vector2i(int(value[0]), int(value[1])) if _is_pair(value) else otherwise


static func _is_whole(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or (typeof(value) == TYPE_FLOAT and float(value) == floorf(float(value)))
