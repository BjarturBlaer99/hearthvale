class_name Placement
extends RefCounted
## Setting things down on the hero's land (the Homestead, phase 2; docs/TECH_DESIGN.md §30),
## pure: what a placeable is, whether one fits a cell, and why not, in words.
##
## A placeable is an item of type "placeable" (data/items) whose stats say what it is on the
## ground:
##   { "id": "fence", "name": "Fence", "type": "placeable", "icon": "fence",
##     "stackable": true, "max_stack": 99, "stats": { "layer": "standing", "joins": true } }
## - `layer`: "lying" (a path, a floor, a flower bed: flat, walked over, never in the way) or
##   "standing" (a fence, a gate, a hedge, a lamp post, a bench, a sapling). A cell holds one of
##   each at most.
## - `fills` (lying things): its picture covers its cell edge to edge (a path, a floor), so it
##   is drawn with a rim where nothing of the kind lies beside it. A flower bed has its own edge.
## - `blocks` (standing things; true unless said): whether it fills its cell. A gate says false:
##   the hero walks through it, and it still counts as fence to whatever a fence keeps in.
## - `joins`: it runs on to its neighbours that join too (a fence's rails, a gate's posts).
## - `light`: { "at": [x, y], "radius", "strength" }: it shines from dusk to dawn, steadily.
## - `grows`: { "mornings", "tree" }: a sapling, a tree of that kind (a SceneryAtlas picture)
##   after so many mornings. Until then it shows STAGES pictures: its icon's frame, then
##   "<icon>_1" and "<icon>_2".
## So a new placeable is data and a picture, unless it is a new kind of thing.
##
## Whether one fits is asked of a `site`: what the area knows of a cell (site()). The refusals
## and their words are the plan's table, in its order: the first that holds is the one said.

const TYPE: String = "placeable"
const LYING: StringName = &"lying"
const STANDING: StringName = &"standing"
const LAYERS: Array[StringName] = [LYING, STANDING]
## How many pictures a sapling shows before it is a tree.
const STAGES: int = 3

## Why a thing can't be set down (the plan's table).
const NOT_LAND_WORDS: String = "You can only build on your own land."
const NO_GROUND_WORDS: String = "Nothing can stand there."
const ROAD_WORDS: String = "That is the road."
const DOORSTEP_WORDS: String = "That is a doorstep."
const FIELD_WORDS: String = "That is your field."
const CLEAR_FIRST_WORDS: String = ToolUse.CLEAR_FIRST
const TAKEN_WORDS: String = "Something is there already."
const SOMEONE_WORDS: String = "Someone is standing there."
## ...and what is said of a thing that is no placeable at all (nothing in play offers one).
const NOT_PLACEABLE_WORDS: String = "That can't be set down."
## Why a thing can't be taken up: there is none, or (its name) the pack has no room for it.
const NOTHING_WORDS: String = "There is nothing here to take up."
const NO_ROOM_WORDS: String = "You have no room for the %s."


static func is_placeable(item: Dictionary) -> bool:
	return str(item.get("type", "")) == TYPE


static func _stats(item: Dictionary) -> Dictionary:
	var stats: Variant = item.get("stats", {})
	return stats if typeof(stats) == TYPE_DICTIONARY else {}


## Whether `item` lies or stands (LYING, STANDING), or &"" for what is no placeable.
static func layer_of(item: Dictionary) -> StringName:
	if not is_placeable(item):
		return &""
	var layer: StringName = StringName(str(_stats(item).get("layer", "")))
	return layer if LAYERS.has(layer) else &""


## Whether `item`, set down, fills its cell: a standing thing does unless it says otherwise (a
## gate); a lying thing never does.
static func blocks(item: Dictionary) -> bool:
	return layer_of(item) == STANDING and bool(_stats(item).get("blocks", true))


## Whether `item`, lying, covers its cell edge to edge (a path, a floor; not a flower bed).
static func fills(item: Dictionary) -> bool:
	return layer_of(item) == LYING and bool(_stats(item).get("fills", false))


## Whether `item` runs on to its neighbours (a fence, a gate).
static func joins(item: Dictionary) -> bool:
	return layer_of(item) == STANDING and bool(_stats(item).get("joins", false))


## The light `item` gives from dusk to dawn: { "at": Vector2 (px in its cell), "radius",
## "strength" }, or {} if it gives none.
static func light_of(item: Dictionary) -> Dictionary:
	var light: Variant = _stats(item).get("light")
	if typeof(light) != TYPE_DICTIONARY:
		return {}
	var at: Variant = (light as Dictionary).get("at", [8, 8])
	var point: Vector2 = Vector2(float(at[0]), float(at[1])) if typeof(at) == TYPE_ARRAY and (at as Array).size() == 2 else Vector2(8, 8)
	return {"at": point, "radius": float((light as Dictionary).get("radius", 0.0)), "strength": float((light as Dictionary).get("strength", 0.3))}


## How many mornings `item` takes to become a tree, or 0 for what doesn't grow.
static func mornings_of(item: Dictionary) -> int:
	var grows: Variant = _stats(item).get("grows")
	return maxi(int((grows as Dictionary).get("mornings", 0)), 0) if typeof(grows) == TYPE_DICTIONARY else 0


## The tree `item` grows into (a SceneryAtlas kind), or "" for what doesn't grow.
static func tree_of(item: Dictionary) -> String:
	var grows: Variant = _stats(item).get("grows")
	return str((grows as Dictionary).get("tree", "")) if typeof(grows) == TYPE_DICTIONARY else ""


static func is_sapling(item: Dictionary) -> bool:
	return mornings_of(item) > 0


## Whether a sapling `item` that has seen `age` mornings is a tree. Never, for what doesn't grow.
static func is_grown(item: Dictionary, age: int) -> bool:
	return is_sapling(item) and age >= mornings_of(item)


## Which of its STAGES pictures a sapling `item` shows after `age` mornings: 0 when just set
## down, the last on the morning before it is a tree. (0 for what doesn't grow.)
static func stage_of(item: Dictionary, age: int) -> int:
	var mornings: int = mornings_of(item)
	if mornings <= 0:
		return 0
	@warning_ignore("integer_division")
	return clampi(maxi(age, 0) * STAGES / mornings, 0, STAGES - 1)


## The picture `item` shows on the ground after `age` mornings: its icon's, or for a sapling
## that has grown a stage or two, "<icon>_1", "<icon>_2".
static func frame_of(item: Dictionary, age: int = 0) -> StringName:
	var icon: String = str(item.get("icon", item.get("id", "")))
	var stage: int = stage_of(item, age)
	return StringName(icon if stage == 0 else "%s_%d" % [icon, stage])


## The items among `items` (data entries) that grow, as Homestead.grow() wants them: item id
## (String) -> the mornings it takes.
static func growing(items: Array) -> Dictionary:
	var out: Dictionary = {}
	for item: Variant in items:
		if typeof(item) == TYPE_DICTIONARY and is_sapling(item):
			out[str((item as Dictionary).get("id", ""))] = mornings_of(item)
	return out


## What the area knows of a cell, for why_not(). Every part has the answer that lets a thing
## be set down, so a caller (and a test) says only what is in the way:
## - `land`: the map is the hero's land;
## - `ground`: the cell is on the map and can be walked: no tree, water, wall or edge;
## - `road`: it is the road, the path to the door, or the way out;
## - `doorstep`: it is the cell before a door;
## - `field`: it is a cell of the field;
## - `debris`: something stands there to be cleared;
## - `lying`, `standing`: the item id of what lies and stands there already (&"" for nothing);
## - `someone`: the hero (or an animal) is in the cell;
## - `left`: something lies there to be picked up.
static func site(land: bool = true, ground: bool = true, road: bool = false, doorstep: bool = false, field: bool = false,
		debris: bool = false, lying: StringName = &"", standing: StringName = &"", someone: bool = false, left: bool = false) -> Dictionary:
	return {"land": land, "ground": ground, "road": road, "doorstep": doorstep, "field": field, "debris": debris,
		"lying": lying, "standing": standing, "someone": someone, "left": left}


## Why `item` can't be set down at `at` (a site()), in words; "" if it can. The plan's table,
## top to bottom: the first refusal that holds.
static func why_not(item: Dictionary, at: Dictionary) -> String:
	if not bool(at.get("land", false)):
		return NOT_LAND_WORDS
	var layer: StringName = layer_of(item)
	if layer == &"":
		return NOT_PLACEABLE_WORDS
	if not bool(at.get("ground", false)):
		return NO_GROUND_WORDS
	if bool(at.get("road", false)):
		return ROAD_WORDS
	if bool(at.get("doorstep", false)):
		return DOORSTEP_WORDS
	if bool(at.get("field", false)):
		return FIELD_WORDS
	if bool(at.get("debris", false)):
		return CLEAR_FIRST_WORDS
	if StringName(str(at.get(String(layer), ""))) != &"":
		return TAKEN_WORDS
	if layer == STANDING:
		# What lies there to be picked up would be shut in under it.
		if bool(at.get("left", false)):
			return TAKEN_WORDS
		if bool(at.get("someone", false)):
			return SOMEONE_WORDS
	return ""


## What is wrong with `item` as a placeable, in words: nothing, if it can be used. `trees` are
## the kinds of tree a sapling may grow into.
static func problems(item: Dictionary, trees: Array) -> PackedStringArray:
	var out: PackedStringArray = []
	var stats: Dictionary = _stats(item)
	var layer: String = str(stats.get("layer", ""))
	if not LAYERS.has(StringName(layer)):
		out.append("a placeable's stats need 'layer': 'lying' or 'standing'.")
		return out
	if not bool(item.get("stackable", false)):
		out.append("a placeable must stack (it is counted on the build bar).")
	if str(item.get("icon", "")).is_empty():
		out.append("a placeable needs an 'icon': it is its picture on the ground too.")
	if StringName(layer) == LYING:
		for standing_only: String in ["blocks", "joins", "light", "grows"]:
			if stats.has(standing_only):
				out.append("'%s' is for a standing thing: a lying one never blocks, joins, shines or grows." % standing_only)
		if stats.has("fills") and typeof(stats["fills"]) != TYPE_BOOL:
			out.append("'fills' must be true or false.")
		return out
	if stats.has("fills"):
		out.append("'fills' is for a lying thing: a path or a floor that covers its cell.")
	for flag: String in ["blocks", "joins"]:
		if stats.has(flag) and typeof(stats[flag]) != TYPE_BOOL:
			out.append("'%s' must be true or false." % flag)
	if stats.has("light"):
		var light: Variant = stats["light"]
		if typeof(light) != TYPE_DICTIONARY or not _is_number((light as Dictionary).get("radius")) or float(light["radius"]) <= 0.0:
			out.append("'light' needs a 'radius' above 0.")
		elif (light as Dictionary).has("at") and (typeof(light["at"]) != TYPE_ARRAY or (light["at"] as Array).size() != 2):
			out.append("'light' 'at' must be [x, y], a point in its cell.")
	if stats.has("grows"):
		var grows: Variant = stats["grows"]
		if typeof(grows) != TYPE_DICTIONARY:
			out.append("'grows' must be an object: 'mornings' and 'tree'.")
		else:
			var mornings: Variant = (grows as Dictionary).get("mornings")
			if not _is_number(mornings) or float(mornings) != floorf(float(mornings)) or int(mornings) < STAGES:
				out.append("'grows' needs 'mornings', a whole number of %d or more (a picture a stage)." % STAGES)
			if not trees.has(str((grows as Dictionary).get("tree", ""))):
				out.append("'grows' names an unknown tree '%s'." % (grows as Dictionary).get("tree", ""))
	return out


static func _is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT
