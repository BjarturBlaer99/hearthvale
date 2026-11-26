class_name HeldTools
extends RefCounted
## The tools in the hero's hands (tool polish, 2026-11-19): gameplay/art/held_tools.png
## (art/sheets.json lists its frames). Each frame is SIZE, with the hero's feet at FEET,
## and is "<item>_<facing>_<pose>": the plain hoe, pickaxe and can, then the sprinkler, then
## the copper and iron ones, then the axes added after them (icons-axe-bar plan, step A1), plain,
## copper and iron. A test checks the order against art/sheets.json.

const SHEET: Texture2D = preload("res://gameplay/art/held_tools.png")
const SIZE: Vector2i = Vector2i(40, 56)
## Where the hero's feet are in a frame: in the middle, so a frame mirrors about them.
const FEET: Vector2i = Vector2i(20, 40)
const FACINGS: Array[String] = ["down", "up", "side"]
## The drawn tools, in the tool's order, and the poses each is drawn in.
const BASES: Array = [
	["hoe", [ToolStroke.RAISE, ToolStroke.STRIKE]],
	["pickaxe", [ToolStroke.RAISE, ToolStroke.STRIKE]],
	["watering_can", [ToolStroke.TIP, ToolStroke.DIP]],
	["sprinkler", [ToolStroke.REACH]],
]
## The tools made again in each metal, in the tool's order.
const METALLED: Array[String] = ["hoe", "pickaxe", "watering_can"]
const METALS: Array[String] = ["copper", "iron"]
## The tools drawn after the first ones, each plain and then in each metal, at the sheet's end
## (an older frame never moves).
const ADDED: Array = [
	["axe", [ToolStroke.RAISE, ToolStroke.STRIKE]],
]
## Each item that is held: [the drawn tool, its metal ("" for plain)].
const ITEMS: Dictionary = {
	&"hoe": ["hoe", ""], &"copper_hoe": ["hoe", "copper"], &"iron_hoe": ["hoe", "iron"],
	&"pickaxe": ["pickaxe", ""], &"copper_pickaxe": ["pickaxe", "copper"], &"iron_pickaxe": ["pickaxe", "iron"],
	&"watering_can": ["watering_can", ""], &"copper_watering_can": ["watering_can", "copper"],
	&"iron_watering_can": ["watering_can", "iron"],
	&"sprinkler": ["sprinkler", ""],
	&"axe": ["axe", ""], &"copper_axe": ["axe", "copper"], &"iron_axe": ["axe", "iron"],
}

static var _frames: Dictionary = {}


## Every frame's name, in the order the tool paints them.
static func frame_names() -> Array[String]:
	var out: Array[String] = []
	for base: Array in BASES:
		out.append_array(_names_of(str(base[0]), base[1]))
	for metal: String in METALS:
		for base: Array in BASES:
			if METALLED.has(str(base[0])):
				for frame_name: String in _names_of(str(base[0]), base[1]):
					out.append("%s_%s" % [metal, frame_name])
	for base: Array in ADDED:
		out.append_array(_names_of(str(base[0]), base[1]))
		for metal: String in METALS:
			for frame_name: String in _names_of(str(base[0]), base[1]):
				out.append("%s_%s" % [metal, frame_name])
	return out


## Whether `item_id` has pictures in his hands.
static func has_item(item_id: StringName) -> bool:
	return ITEMS.has(item_id)


## The frame of `item_id` seen from `facing` ("down", "up", "side") in `pose` (a ToolStroke
## pose), or -1 if there is none.
static func frame_of(item_id: StringName, facing: String, pose: StringName) -> int:
	if not ITEMS.has(item_id):
		return -1
	if _frames.is_empty():
		var names: Array[String] = frame_names()
		for index: int in names.size():
			_frames[names[index]] = index
	var held: Array = ITEMS[item_id]
	var prefix: String = "" if str(held[1]).is_empty() else "%s_" % held[1]
	return int(_frames.get("%s%s_%s_%s" % [prefix, held[0], facing, pose], -1))


## The frame's place in the sheet.
static func region_of(frame: int) -> Rect2:
	return Rect2(frame * SIZE.x, 0, SIZE.x, SIZE.y)


static func _names_of(base: String, poses: Array) -> Array[String]:
	var out: Array[String] = []
	for facing: String in FACINGS:
		for pose: StringName in poses:
			out.append("%s_%s_%s" % [base, facing, pose])
	return out
