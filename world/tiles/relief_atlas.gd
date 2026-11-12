class_name ReliefAtlas
extends RefCounted
## Layout of the relief atlas (P1d): the pictures that give walls and buildings height. A wall
## has a front face (seen where the floor lies south of it) and a top; a pillar stands taller
## than its cell; a roof has a strip of ridge that rises above its top row. Painted by
## tools/art/make_relief.gd, read by WallRelief and Scenery.

const TEXTURE_PATH: String = "res://world/tiles/relief.png"
const SIZE: Vector2i = Vector2i(96, 96)
## The wall tiles (GreyboxTiles kinds) that get relief, and what each is built of.
const MATERIALS: Dictionary = {"dungeon_wall": "stone", "inner_wall": "timber", "stone": "ruin"}
const MATERIAL_ORDER: Array[String] = ["stone", "timber", "ruin"]
## A wall's front face is taller than a cell: its top FACE_RISE pixels are drawn over the foot
## of the wall cell behind it, so walls stand a third taller than the grid. Where there is no
## wall behind it to rise over (or that wall belongs to the next room), the short face is used,
## which fits its own cell.
const FACE_SIZE: Vector2i = Vector2i(16, 24)
const FACE_RISE: int = 8
const SHORT_FACE_SIZE: Vector2i = Vector2i(16, 16)
const TOP_SIZE: Vector2i = Vector2i(16, 16)
## A pillar: its picture, and where it meets the floor in it.
const PILLAR_SIZE: Vector2i = Vector2i(16, 28)
const PILLAR_FOOT: Vector2 = Vector2(8, 26)
## A roof's ridge strip: its size, the roof styles (the first part of a roof tile's kind) and
## the parts of a ridge.
const RIDGE_SIZE: Vector2i = Vector2i(16, 8)
const ROOF_STYLES: Array[String] = ["roof", "roof_blue", "roof_thatch"]
const RIDGE_PARTS: Array[String] = ["mid", "l", "r"]


## Where the front face of a wall of `material` is in the atlas.
static func face(material: String) -> Rect2:
	return Rect2(maxi(MATERIAL_ORDER.find(material), 0) * 32, 0, FACE_SIZE.x, FACE_SIZE.y)


## Where the short front face of a wall of `material` is: a cell high.
static func short_face(material: String) -> Rect2:
	return Rect2(maxi(MATERIAL_ORDER.find(material), 0) * 32 + 16, 16, SHORT_FACE_SIZE.x, SHORT_FACE_SIZE.y)


## Where the top of a wall of `material` is.
static func top(material: String) -> Rect2:
	return Rect2(maxi(MATERIAL_ORDER.find(material), 0) * 32 + 16, 0, TOP_SIZE.x, TOP_SIZE.y)


static func pillar() -> Rect2:
	return Rect2(0, 32, PILLAR_SIZE.x, PILLAR_SIZE.y)


## Where the ridge strip for a roof of `style` is: its middle, or its left or right end.
static func ridge(style: String, part: String) -> Rect2:
	return Rect2(32 + maxi(RIDGE_PARTS.find(part), 0) * 16, 32 + maxi(ROOF_STYLES.find(style), 0) * 16, RIDGE_SIZE.x, RIDGE_SIZE.y)


## The roof style and ridge part of a roof's top-row tile kind ("roof_blue_top_l" -> ["roof_blue",
## "l"]), or an empty array if `kind` isn't the top row of a roof.
static func ridge_of(kind: String) -> Array:
	for style: String in ["roof_thatch", "roof_blue", "roof"]:
		if kind == style + "_top":
			return [style, "mid"]
		if kind == style + "_top_l":
			return [style, "l"]
		if kind == style + "_top_r":
			return [style, "r"]
	return []
