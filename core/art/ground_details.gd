class_name GroundDetails
extends RefCounted
## Small still details on the ground (the warm-ground plan, step 3; docs/progress/
## warm-ground-plan.md §3): clover, flowers, pebbles and worn spots on grass and paths, cracks,
## moss and grit in the quarry and the dungeons. Pure: for a cell, its tile and what is around
## it, which detail goes there, or none. The rules are data (data/rules/ground_detail.json):
##   { "places": ["outdoor", "dungeon"],
##     "grounds": { "grass": { "chance": 0.2, "details": { "clover": 3, ... },
##                             "drifts": { "size": 4, "share": 0.3, "chance": 0.4,
##                                         "details": ["sunlit", "shaded"] } }, ... },
##     "unmirrored": ["pebbles", ...] }
## - Which cell gets which detail is a fixed hash of the cell: the same cell shows the same
##   detail at every load, in every game, and no map holds them.
## - A cell gets none unless it is open ground of a kind with details (GROUNDS), holds nothing,
##   its four neighbours look the same (the same tile, or its solid twin under a prop: look_of),
##   and the cell below it holds nothing (what stands there may rise over it): so the edges of
##   paths, banks, cliffs and walls, and whatever lies, stands or grows, stay clear.
## - On grass some details gather in drifts: squares of `size` cells, a `share` of them a drift
##   of one of its details, where a cell gets that detail at the drift's own chance.
## Details are for show only: nothing that moves, hits or collides knows of them.

const GRASS: StringName = &"grass"
const PATH: StringName = &"path"
const FLOOR: StringName = &"floor"
const LEDGE: StringName = &"ledge"
const CAVE: StringName = &"cave"
const MARSH: StringName = &"marsh"
## The kinds of ground that may have details, as the rules name them.
const GROUNDS: Array[StringName] = [GRASS, PATH, FLOOR, LEDGE, CAVE, MARSH]
## The heights of grass that may have details (the meadow and its two rises; above them it
## turns to rock).
const GRASS_HEIGHTS: int = 3
## The frames of world/tiles/ground_details.png in order (art/sheets.json names them too).
const FRAMES: Dictionary = {
	&"clover": 0, &"clover_b": 1, &"daisies": 2, &"buttercups": 3, &"blades": 4, &"blades_b": 5,
	&"sunlit": 6, &"shaded": 7, &"pebbles": 8, &"worn": 9,
	&"path_pebbles": 10, &"ruts": 11, &"path_sprig": 12, &"sandy": 13, &"flat_stone": 14, &"specks": 15,
	&"crack": 16, &"moss": 17, &"dust": 18, &"ledge_crack": 19,
	&"grit": 20, &"crumbs": 21, &"cave_crack": 22,
	&"marsh_moss": 23, &"damp": 24, &"marsh_sprig": 25,
}
const SIDES: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
## A roll is a whole number from 0 to ROLLS - 1.
const ROLLS: int = 10000
## Salts, so each question asked of a cell has its own answer.
const SALT_CHANCE: int = 1
const SALT_WHICH: int = 3
const SALT_MIRROR: int = 5
const SALT_DRIFT: int = 7
const SALT_DRIFT_WHICH: int = 11

var places: Array[StringName] = []
var unmirrored: Array[StringName] = []
## ground -> { "chance": float, "details": [[name, weight], ...], "total": int, "drifts": {...} }
var _grounds: Dictionary = {}


func _init(rules: Dictionary) -> void:
	for place: Variant in rules.get("places", []):
		places.append(StringName(str(place)))
	for name: Variant in rules.get("unmirrored", []):
		unmirrored.append(StringName(str(name)))
	var grounds: Variant = rules.get("grounds", {})
	if typeof(grounds) != TYPE_DICTIONARY:
		return
	for ground: Variant in grounds:
		var entry: Dictionary = grounds[ground]
		var weighted: Array = []
		var total: int = 0
		var details: Dictionary = entry.get("details", {})
		var names: Array = details.keys()
		names.sort()
		for name: Variant in names:
			var weight: int = int(details[name])
			if weight > 0:
				weighted.append([StringName(str(name)), weight])
				total += weight
		_grounds[StringName(str(ground))] = {
			"chance": float(entry.get("chance", 0.0)),
			"details": weighted,
			"total": total,
			"drifts": entry.get("drifts", {}),
		}


## What is wrong with `rules`, in words.
static func problems(rules: Dictionary) -> PackedStringArray:
	var out: PackedStringArray = []
	var frames: Array = []
	for name: StringName in FRAMES:
		frames.append(String(name))
	var places_given: Variant = rules.get("places")
	if typeof(places_given) != TYPE_ARRAY:
		out.append("'places' must list the kinds of area that have details (outdoor, interior, dungeon).")
	else:
		for place: Variant in places_given:
			if not str(place) in ["outdoor", "interior", "dungeon"]:
				out.append("'places' has '%s', which is no kind of area (outdoor, interior, dungeon)." % place)
	var grounds: Variant = rules.get("grounds")
	if typeof(grounds) != TYPE_DICTIONARY:
		out.append("'grounds' must be an object: a kind of ground, then its chance and details.")
		return out
	for ground: Variant in grounds:
		if not GROUNDS.has(StringName(str(ground))):
			out.append("'grounds' has '%s', which is no ground with details (%s)." % [ground, ", ".join(GROUNDS)])
		var entry: Variant = grounds[ground]
		if typeof(entry) != TYPE_DICTIONARY:
			out.append("ground '%s' must be an object." % ground)
			continue
		if not _is_share(entry.get("chance")):
			out.append("ground '%s' needs 'chance', a number from 0 to 1." % ground)
		var details: Variant = entry.get("details")
		if typeof(details) != TYPE_DICTIONARY or (details as Dictionary).is_empty():
			out.append("ground '%s' needs 'details': a frame's name, then its weight." % ground)
		else:
			for name: Variant in details:
				if not frames.has(str(name)):
					out.append("ground '%s' has the detail '%s', which is no frame of the sheet." % [ground, name])
				var weight: Variant = details[name]
				if (typeof(weight) != TYPE_INT and typeof(weight) != TYPE_FLOAT) or float(weight) != floorf(float(weight)) or int(weight) < 1:
					out.append("ground '%s': the weight of '%s' must be a whole number of 1 or more." % [ground, name])
		if entry.has("drifts"):
			var drifts: Variant = entry["drifts"]
			if typeof(drifts) != TYPE_DICTIONARY:
				out.append("ground '%s': 'drifts' must be an object." % ground)
				continue
			var size: Variant = drifts.get("size")
			if (typeof(size) != TYPE_INT and typeof(size) != TYPE_FLOAT) or float(size) != floorf(float(size)) or int(size) < 1:
				out.append("ground '%s': the drifts' 'size' must be a whole number of 1 or more." % ground)
			if not _is_share(drifts.get("share")) or not _is_share(drifts.get("chance")):
				out.append("ground '%s': the drifts' 'share' and 'chance' must be numbers from 0 to 1." % ground)
			var drift_details: Variant = drifts.get("details")
			if typeof(drift_details) != TYPE_ARRAY or (drift_details as Array).is_empty():
				out.append("ground '%s': the drifts need 'details', a list of frames." % ground)
			else:
				for name: Variant in drift_details:
					if not frames.has(str(name)):
						out.append("ground '%s': the drift '%s' is no frame of the sheet." % [ground, name])
	for name: Variant in rules.get("unmirrored", []):
		if not frames.has(str(name)):
			out.append("'unmirrored' has '%s', which is no frame of the sheet." % name)
	return out


static func _is_share(value: Variant) -> bool:
	return (typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT) and float(value) >= 0.0 and float(value) <= 1.0


## Whether an area of this kind (Ambience: outdoor, interior, dungeon) has details.
func shows_in(place: StringName) -> bool:
	return places.has(place)


## The kind of ground the atlas tile `tile` of a Height layer is, or &"" for one that never
## has details (water, walls, doors, stairs, floors of houses, solid ground under props).
static func ground_of(tile: Vector2i) -> StringName:
	if tile.y == GreyboxTiles.ROW_GROUND and tile.x >= 0 and tile.x < GRASS_HEIGHTS:
		return GRASS
	if tile.y == GreyboxTiles.ROW_PATH and tile.x >= 0 and tile.x < GreyboxTiles.COLUMNS:
		return PATH
	if tile == GreyboxTiles.coords("dungeon_floor"):
		return FLOOR
	if tile.y == GreyboxTiles.ROW_LEDGE and tile.x >= 0 and tile.x < GreyboxTiles.COLUMNS:
		return LEDGE
	if tile == GreyboxTiles.coords("cave_floor"):
		return CAVE
	if tile == GreyboxTiles.coords("marsh"):
		return MARSH
	return &""


## A fixed roll for `cell`, from 0 to ROLLS - 1, its own for each `salt`.
static func roll(cell: Vector2i, salt: int) -> int:
	var h: int = (cell.x * 73856093) ^ (cell.y * 19349663) ^ (salt * 83492791)
	h = (h ^ (h >> 13)) * 1274126177
	h = h ^ (h >> 16)
	h = (h ^ (h >> 7)) * 2246822519
	h = h ^ (h >> 15)
	return posmod(h, ROLLS)


static func _below(chance: float, at: int) -> bool:
	return at < int(roundf(chance * ROLLS))


## The detail the hash gives `cell` on `ground`, as if nothing were around it; &"" for none.
func choose(cell: Vector2i, ground: StringName) -> StringName:
	if not _grounds.has(ground):
		return &""
	var entry: Dictionary = _grounds[ground]
	var drifts: Dictionary = entry["drifts"]
	if not drifts.is_empty():
		var size: int = maxi(int(drifts.get("size", 1)), 1)
		var square: Vector2i = Vector2i(floori(cell.x / float(size)), floori(cell.y / float(size)))
		if _below(float(drifts.get("share", 0.0)), roll(square, SALT_DRIFT)):
			var kinds: Array = drifts.get("details", [])
			if kinds.is_empty() or not _below(float(drifts.get("chance", 0.0)), roll(cell, SALT_CHANCE)):
				return &""
			return StringName(str(kinds[roll(square, SALT_DRIFT_WHICH) % kinds.size()]))
	if int(entry["total"]) <= 0 or not _below(float(entry["chance"]), roll(cell, SALT_CHANCE)):
		return &""
	var pick: int = roll(cell, SALT_WHICH) % int(entry["total"])
	for weighted: Array in entry["details"]:
		pick -= int(weighted[1])
		if pick < 0:
			return weighted[0]
	return &""


## What the tile `tile` looks like: a solid twin under a prop (the grass, the marsh and the
## quarry's earth have one) looks like its ground; any other tile like itself.
static func look_of(tile: Vector2i) -> Vector2i:
	if tile.y == GreyboxTiles.ROW_SOLID_GROUND:
		return Vector2i(tile.x, GreyboxTiles.ROW_GROUND)
	if tile == GreyboxTiles.coords("marsh_solid"):
		return GreyboxTiles.coords("marsh")
	if tile == GreyboxTiles.coords("cave_solid"):
		return GreyboxTiles.coords("cave_floor")
	return tile


## Whether `cell` is clear for a detail: its four neighbours in `tiles` (cell -> atlas coords
## of the Height layer) look as it does (look_of), and neither it nor the cell below it is in
## `held` (cells where something lies, stands or grows; what stands below may rise over it).
static func is_clear(cell: Vector2i, tiles: Dictionary, held: Dictionary) -> bool:
	if not tiles.has(cell) or held.has(cell) or held.has(cell + Vector2i.DOWN):
		return false
	var look: Vector2i = look_of(tiles[cell])
	for side: Vector2i in SIDES:
		var next: Variant = tiles.get(cell + side)
		if next == null or look_of(next) != look:
			return false
	return true


## The detail for `cell`, given the Height layer's `tiles` and the `held` cells; &"" for none.
func detail_at(cell: Vector2i, tiles: Dictionary, held: Dictionary) -> StringName:
	if not tiles.has(cell):
		return &""
	var ground: StringName = ground_of(tiles[cell])
	if ground == &"" or not is_clear(cell, tiles, held):
		return &""
	return choose(cell, ground)


## Every cell of `tiles` that gets a detail, and which: cell -> detail.
func place(tiles: Dictionary, held: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for cell: Vector2i in tiles:
		var detail: StringName = detail_at(cell, tiles, held)
		if detail != &"":
			out[cell] = detail
	return out


## Whether the detail in `cell` is drawn mirrored (half of them are, by the hash; never those
## lit from one side).
func is_mirrored(cell: Vector2i, detail: StringName) -> bool:
	return not unmirrored.has(detail) and roll(cell, SALT_MIRROR) % 2 == 1


## The details a ground may get, by name (its own and its drifts').
func details_of(ground: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	if not _grounds.has(ground):
		return out
	for weighted: Array in _grounds[ground]["details"]:
		out.append(weighted[0])
	for name: Variant in (_grounds[ground]["drifts"] as Dictionary).get("details", []):
		out.append(StringName(str(name)))
	return out
