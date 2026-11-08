class_name GreyboxTiles
extends RefCounted
## Layout of the generated greybox tile atlas (made by tools/greybox/). Shared by the build
## tools and the area scripts so atlas coordinates live in one place.
##
## Atlas rows (16 px tiles, 8 columns):
##   0 ground by height 0-7: grass that turns to rock as it rises
##   1 stairs by height 0-7: stone steps (a ramp: walk up or down one level)
##   2 dirt path by height 0-7
##   3 solid things outdoors: tree, rock, wall, red roof, blue roof, water, fence, stone
##   4 walkable floors at height 0: door (in a house wall), wooden floor, rug, doormat
##   5 solid things indoors: inner wall, table, bed, shelf, barrel, hearth

const TEXTURE_PATH: String = "res://world/tiles/greybox_tiles.png"
const TILESET_PATH: String = "res://world/tiles/greybox_tiles.tres"
const SOURCE_ID: int = 0
const TILE_SIZE: int = 16
const COLUMNS: int = 8
const ROWS: int = 6

const ROW_GROUND: int = 0
const ROW_STAIRS: int = 1
const ROW_PATH: int = 2
const ROW_SOLID: int = 3
const ROW_FLOOR: int = 4
const ROW_FURNITURE: int = 5

## Kinds painted at any height 0-7 (their column is the height).
const LAYERED_KINDS: Dictionary = {"ground": ROW_GROUND, "stairs": ROW_STAIRS, "path": ROW_PATH}

## Solid kinds in atlas order, and the height each one counts as for edge shading
## (a tree on the grass gets a shadow like a two-level block). Solids are never entered.
const SOLID_KINDS: Array[String] = ["tree", "rock", "wall", "roof", "roof_blue", "water", "fence", "stone"]
const SOLID_HEIGHTS: Array[int] = [2, 1, 3, 3, 3, 0, 1, 2]

## Walkable kinds at height 0, in atlas order. A door sits in a house's front wall.
const FLOOR_KINDS: Array[String] = ["door", "floor", "rug", "doormat"]

## Solid indoor kinds in atlas order, with their shading heights like SOLID_HEIGHTS.
const FURNITURE_KINDS: Array[String] = ["inner_wall", "table", "bed", "shelf", "barrel", "hearth"]
const FURNITURE_HEIGHTS: Array[int] = [3, 1, 1, 2, 1, 3]

## Custom data layers on the TileSet (TECH_DESIGN §3).
const DATA_HEIGHT: String = "height"
const DATA_RAMP: String = "ramp"
const DATA_SOLID: String = "solid"

## Meadow grass at the bottom, lighter grass on raised ground, rock on the heights.
const GROUND_COLORS: Array[Color] = [
	Color(0.34, 0.56, 0.26),
	Color(0.39, 0.61, 0.29),
	Color(0.44, 0.65, 0.32),
	Color(0.52, 0.56, 0.36),
	Color(0.56, 0.52, 0.40),
	Color(0.60, 0.56, 0.47),
	Color(0.66, 0.63, 0.56),
	Color(0.74, 0.72, 0.68),
]
const STAIRS_COLOR: Color = Color(0.63, 0.60, 0.54)
const PATH_COLOR: Color = Color(0.70, 0.57, 0.38)


## Atlas coordinates for a kind of tile: "ground", "stairs" or "path" at `height`, or a
## fixed-height kind (SOLID_KINDS, FLOOR_KINDS, FURNITURE_KINDS; height is then ignored).
## Unknown kinds give the meadow grass.
static func coords(kind: String, height: int = 0) -> Vector2i:
	if LAYERED_KINDS.has(kind):
		return Vector2i(clampi(height, 0, COLUMNS - 1), LAYERED_KINDS[kind])
	if SOLID_KINDS.has(kind):
		return Vector2i(SOLID_KINDS.find(kind), ROW_SOLID)
	if FLOOR_KINDS.has(kind):
		return Vector2i(FLOOR_KINDS.find(kind), ROW_FLOOR)
	if FURNITURE_KINDS.has(kind):
		return Vector2i(FURNITURE_KINDS.find(kind), ROW_FURNITURE)
	return Vector2i(0, ROW_GROUND)


static func is_known_kind(kind: String) -> bool:
	return LAYERED_KINDS.has(kind) or SOLID_KINDS.has(kind) or FLOOR_KINDS.has(kind) or FURNITURE_KINDS.has(kind)
