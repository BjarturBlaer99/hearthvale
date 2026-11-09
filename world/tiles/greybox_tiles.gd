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
##   4 walkable floors at height 0: door (in a house wall), wooden floor, rug, doormat, dungeon
##     floor, stairway (down into a dungeon, or up out of it)
##   5 solid things indoors: inner wall, table, bed, shelf, barrel, hearth, dungeon wall, pillar
##   6 decorations (the Decor layer only, see-through, no effect on movement): flowers (red,
##     yellow, blue), a grass tuft, pebbles, mushrooms, a vegetable patch, lily pads
##   7 details of solid things, chosen by build_maps.gd: roof ridge and eaves (red and blue),
##     a wall with a window
##   8 solid ground by height 0-7: looks like grass, can't be entered; trees, rocks, fences and
##     the well stand on it
##   9 props for the Decor layer (see-through): tree, rock, fence, and the well's four quarters
##  10 raised dungeon floor ("ledge") by height 0-7: flagstones for platforms and walkways
##  11 water, animated: WATER_FRAMES frames side by side, the first being the tile maps use
##  12 spawn markers for the hidden Spawns layer: grass, pot, chicken, butterfly, firefly (the
##     area turns each into its node on load; never seen in the game)
##  13 more props for the Decor layer: crate, keg, hay, logs, stump, lamp post, standing stone,
##     and a well bucket (decoration, walkable)
##  14 the market stall's six quarters, a washing line (decoration) and its post
##  15 more furniture, on a wooden floor: chair, cupboard, loom, plant, candle stand, shop counter,
##     stool, bookcase

const TEXTURE_PATH: String = "res://world/tiles/greybox_tiles.png"
const TILESET_PATH: String = "res://world/tiles/greybox_tiles.tres"
const SOURCE_ID: int = 0
const TILE_SIZE: int = 16
const COLUMNS: int = 8
const ROWS: int = 16

const ROW_GROUND: int = 0
const ROW_STAIRS: int = 1
const ROW_PATH: int = 2
const ROW_SOLID: int = 3
const ROW_FLOOR: int = 4
const ROW_FURNITURE: int = 5
const ROW_DECOR: int = 6
const ROW_DETAIL: int = 7
const ROW_SOLID_GROUND: int = 8
const ROW_PROPS: int = 9
const ROW_LEDGE: int = 10
const ROW_WATER: int = 11
const ROW_MARKERS: int = 12
const ROW_PROPS_B: int = 13
const ROW_PROPS_C: int = 14
const ROW_FURNITURE_B: int = 15
const PROPS_B_KINDS: Array[String] = ["prop_crate", "prop_keg", "prop_hay", "prop_logs", "prop_stump", "prop_lamp", "prop_stone", "bucket"]
const PROPS_C_KINDS: Array[String] = ["stall_nw", "stall_n", "stall_ne", "stall_sw", "stall_s", "stall_se", "laundry", "prop_post"]
## More solid indoor furniture, with shading heights like FURNITURE_HEIGHTS.
const FURNITURE_B_KINDS: Array[String] = ["chair", "cupboard", "loom", "plant", "candle", "counter", "stool", "bookcase"]
const FURNITURE_B_HEIGHTS: Array[int] = [1, 2, 2, 1, 1, 1, 1, 2]
## Decorations among the H12 props: see-through and walkable, like DECOR_KINDS.
const PROP_DECOR_KINDS: Array[String] = ["bucket", "laundry"]
## What the Spawns layer's markers stand for, in atlas order.
const MARKER_KINDS: Array[String] = ["grass", "pot", "chicken", "butterfly", "firefly"]
## Markers that become breakables (the rest become critters).
const BREAKABLE_MARKERS: Array[String] = ["grass", "pot"]
## Water's animation: frames, and how long each shows (seconds).
const WATER_FRAMES: int = 4
const WATER_FRAME_TIME: float = 0.4

## Kinds painted at any height 0-7 (their column is the height).
const LAYERED_KINDS: Dictionary = {"ground": ROW_GROUND, "stairs": ROW_STAIRS, "path": ROW_PATH, "solid_ground": ROW_SOLID_GROUND, "ledge": ROW_LEDGE}

## Solid kinds in atlas order, and the height each one counts as for edge shading
## (a tree on the grass gets a shadow like a two-level block). Solids are never entered.
const SOLID_KINDS: Array[String] = ["tree", "rock", "wall", "roof", "roof_blue", "water", "fence", "stone"]
const SOLID_HEIGHTS: Array[int] = [2, 1, 3, 3, 3, 0, 1, 2]

## Walkable kinds at height 0, in atlas order. A door sits in a house's front wall.
const FLOOR_KINDS: Array[String] = ["door", "floor", "rug", "doormat", "dungeon_floor", "stairway"]

## Solid indoor kinds in atlas order, with their shading heights like SOLID_HEIGHTS.
const FURNITURE_KINDS: Array[String] = ["inner_wall", "table", "bed", "shelf", "barrel", "hearth", "dungeon_wall", "pillar"]
const FURNITURE_HEIGHTS: Array[int] = [3, 1, 1, 2, 1, 3, 3, 2]

## Decorations for the Decor layer, in atlas order: pure looks, never read for movement.
## Lily pads go on water; everything else on open ground.
const DECOR_KINDS: Array[String] = ["flowers_red", "flowers_yellow", "flowers_blue", "tuft", "pebbles", "mushroom", "crops", "lily"]

## Solid details in atlas order (same height and solidity as the thing they decorate):
## build_maps.gd puts ridges on a roof's top row, eaves on its bottom row, and windows in walls.
const DETAIL_KINDS: Array[String] = ["roof_top", "roof_eave", "roof_blue_top", "roof_blue_eave", "wall_window"]
const DETAIL_HEIGHTS: Array[int] = [3, 3, 3, 3, 3]

## Props drawn on the Decor layer over solid ground (so they sit on grass of any height).
const PROP_KINDS: Array[String] = ["prop_tree", "prop_rock", "prop_fence", "well_nw", "well_ne", "well_sw", "well_se"]
## Map kinds that become solid ground plus a prop: block kind -> prop (or the "well" 2x2).
const PROP_BLOCKS: Dictionary = {
	"tree": "prop_tree", "rock": "prop_rock", "fence": "prop_fence", "well": "well",
	"crate": "prop_crate", "keg": "prop_keg", "hay": "prop_hay", "logs": "prop_logs", "stump": "prop_stump",
	"lamp": "prop_lamp", "standing_stone": "prop_stone", "post": "prop_post", "stall": "stall",
}

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
	if kind == "water":
		return Vector2i(0, ROW_WATER)
	if SOLID_KINDS.has(kind):
		return Vector2i(SOLID_KINDS.find(kind), ROW_SOLID)
	if FLOOR_KINDS.has(kind):
		return Vector2i(FLOOR_KINDS.find(kind), ROW_FLOOR)
	if FURNITURE_KINDS.has(kind):
		return Vector2i(FURNITURE_KINDS.find(kind), ROW_FURNITURE)
	if DECOR_KINDS.has(kind):
		return Vector2i(DECOR_KINDS.find(kind), ROW_DECOR)
	if DETAIL_KINDS.has(kind):
		return Vector2i(DETAIL_KINDS.find(kind), ROW_DETAIL)
	if PROP_KINDS.has(kind):
		return Vector2i(PROP_KINDS.find(kind), ROW_PROPS)
	if PROPS_B_KINDS.has(kind):
		return Vector2i(PROPS_B_KINDS.find(kind), ROW_PROPS_B)
	if PROPS_C_KINDS.has(kind):
		return Vector2i(PROPS_C_KINDS.find(kind), ROW_PROPS_C)
	if FURNITURE_B_KINDS.has(kind):
		return Vector2i(FURNITURE_B_KINDS.find(kind), ROW_FURNITURE_B)
	return Vector2i(0, ROW_GROUND)


## Atlas coordinates for spawn marker `kind` (MARKER_KINDS).
static func marker_coords(kind: String) -> Vector2i:
	return Vector2i(MARKER_KINDS.find(kind), ROW_MARKERS)


## What the marker at atlas `coords` stands for, or empty if it isn't one.
static func marker_kind(coords: Vector2i) -> String:
	if coords.y != ROW_MARKERS or coords.x < 0 or coords.x >= MARKER_KINDS.size():
		return ""
	return MARKER_KINDS[coords.x]


static func is_known_kind(kind: String) -> bool:
	return LAYERED_KINDS.has(kind) or SOLID_KINDS.has(kind) or FLOOR_KINDS.has(kind) or FURNITURE_KINDS.has(kind) \
		or DECOR_KINDS.has(kind) or DETAIL_KINDS.has(kind) or PROP_KINDS.has(kind) or PROP_BLOCKS.has(kind) \
		or PROPS_B_KINDS.has(kind) or PROPS_C_KINDS.has(kind) or FURNITURE_B_KINDS.has(kind)


static func is_decor(kind: String) -> bool:
	return DECOR_KINDS.has(kind) or PROP_DECOR_KINDS.has(kind)


static func is_prop(kind: String) -> bool:
	return PROP_KINDS.has(kind) or (PROPS_B_KINDS.has(kind) or PROPS_C_KINDS.has(kind)) and not PROP_DECOR_KINDS.has(kind)
