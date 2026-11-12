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
##     floor, stairway (down into a dungeon, or up out of it), and a pit (plain, and with the
##     far wall showing along its top edge); the area makes pits something to fall into
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
##  16-19 house fronts (HOUSE_KINDS): roofs with a gable's barge board on their left or right edge,
##     thatch, the half-timbered upper floor, and the stone chapel
##  20 overlays for the Decor layer on houses: chimney, the chapel's cross (two halves), shop sign
##  21 chimney smoke, animated: SMOKE_FRAMES frames side by side
##  22 more trees for the Decor layer: a pine, a broad oak, a closed canopy for thick woods, and
##     a cherry in blossom. Scenery stands every tree but the canopy up as a tall picture (P1c),
##     so these tiles only mark where they grow

const TEXTURE_PATH: String = "res://world/tiles/greybox_tiles.png"
const TILESET_PATH: String = "res://world/tiles/greybox_tiles.tres"
const SOURCE_ID: int = 0
const TILE_SIZE: int = 16
const COLUMNS: int = 8
const ROWS: int = 23

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
const ROW_HOUSE: int = 16
const ROW_HOUSE_DECOR: int = 20
const ROW_SMOKE: int = 21
const ROW_TREES: int = 22
## More trees, all props like "prop_tree". The baker mixes the first three kinds by cell and
## uses the canopy where trees stand on all four sides; a "cherry" block is always a cherry.
const TREE_KINDS: Array[String] = ["prop_tree_b", "prop_tree_c", "prop_canopy", "prop_cherry"]
## House fronts, in atlas order from ROW_HOUSE (eight to a row), all solid at height 3 but for
## HOUSE_DOOR_KINDS.
## A roof kind is its style ("roof" clay tiles, "roof_blue" slate, "roof_thatch"), then "_top"
## (ridge) or "_eave" for its first and last rows, then "_l" or "_r" for a gable end; the baker
## builds the name for each cell of a roof block.
const HOUSE_KINDS: Array[String] = [
	"roof_l", "roof_r", "roof_top_l", "roof_top_r", "roof_eave_l", "roof_eave_r",
	"roof_blue_l", "roof_blue_r", "roof_blue_top_l", "roof_blue_top_r", "roof_blue_eave_l", "roof_blue_eave_r",
	"roof_thatch", "roof_thatch_l", "roof_thatch_r", "roof_thatch_top", "roof_thatch_top_l", "roof_thatch_top_r",
	"roof_thatch_eave", "roof_thatch_eave_l", "roof_thatch_eave_r",
	"wall_upper", "wall_upper_b", "wall_upper_window",
	"chapel_wall", "chapel_window", "chapel_door_l", "chapel_door_r",
]
## House fronts that are a way in: the chapel's doors (down to the crypt). Not solid, and level
## with the rise the chapel stands on.
const HOUSE_DOOR_KINDS: Array[String] = ["chapel_door_l", "chapel_door_r"]
const HOUSE_DOOR_HEIGHT: int = 2
## Overlays that sit on house tiles, on the Decor layer.
const HOUSE_DECOR_KINDS: Array[String] = ["chimney", "cross_l", "cross_r", "shop_sign"]
## Chimney smoke's animation: frames, and how long each shows (seconds).
const SMOKE_FRAMES: int = 4
const SMOKE_FRAME_TIME: float = 0.35
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
const FLOOR_KINDS: Array[String] = ["door", "floor", "rug", "doormat", "dungeon_floor", "stairway", "pit", "pit_top"]
## Pits: walkable as far as the tiles go; TerrainQuery makes them a drop (maps say "pit", and
## the baker shows the far wall in the top row of each).
const PIT_KINDS: Array[String] = ["pit", "pit_top"]

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
	"tree": "prop_tree", "cherry": "prop_cherry", "rock": "prop_rock", "fence": "prop_fence", "well": "well",
	"crate": "prop_crate", "keg": "prop_keg", "hay": "prop_hay", "logs": "prop_logs", "stump": "prop_stump",
	"lamp": "prop_lamp", "standing_stone": "prop_stone", "post": "prop_post", "stall": "stall",
}

## Custom data layers on the TileSet (TECH_DESIGN §3).
const DATA_HEIGHT: String = "height"
const DATA_RAMP: String = "ramp"
const DATA_SOLID: String = "solid"

## Meadow grass at the bottom, lighter grass on raised ground, rock on the heights.
const GROUND_COLORS: Array[Color] = [
	Color(0.40, 0.64, 0.24),
	Color(0.45, 0.69, 0.27),
	Color(0.50, 0.73, 0.30),
	Color(0.52, 0.56, 0.36),
	Color(0.56, 0.52, 0.40),
	Color(0.60, 0.56, 0.47),
	Color(0.66, 0.63, 0.56),
	Color(0.74, 0.72, 0.68),
]
const STAIRS_COLOR: Color = Color(0.63, 0.60, 0.54)
const PATH_COLOR: Color = Color(0.78, 0.61, 0.38)


## Atlas coordinates for a kind of tile: "ground", "stairs" or "path" at `height`, or a
## fixed-height kind (SOLID_KINDS, FLOOR_KINDS, FURNITURE_KINDS; height is then ignored).
## Unknown kinds give the meadow grass.
## Whether the tile at atlas `at` is a pit.
static func is_pit(at: Vector2i) -> bool:
	return at.y == ROW_FLOOR and at.x >= FLOOR_KINDS.find("pit") and at.x < FLOOR_KINDS.size()


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
	if HOUSE_KINDS.has(kind):
		var index: int = HOUSE_KINDS.find(kind)
		@warning_ignore("integer_division")
		return Vector2i(index % COLUMNS, ROW_HOUSE + index / COLUMNS)
	if HOUSE_DECOR_KINDS.has(kind):
		return Vector2i(HOUSE_DECOR_KINDS.find(kind), ROW_HOUSE_DECOR)
	if kind == "smoke":
		return Vector2i(0, ROW_SMOKE)
	if TREE_KINDS.has(kind):
		return Vector2i(TREE_KINDS.find(kind), ROW_TREES)
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
		or PROPS_B_KINDS.has(kind) or PROPS_C_KINDS.has(kind) or FURNITURE_B_KINDS.has(kind) \
		or HOUSE_KINDS.has(kind) or HOUSE_DECOR_KINDS.has(kind) or kind == "smoke" or TREE_KINDS.has(kind)


static func is_decor(kind: String) -> bool:
	return DECOR_KINDS.has(kind) or PROP_DECOR_KINDS.has(kind) or HOUSE_DECOR_KINDS.has(kind) or kind == "smoke"


static func is_prop(kind: String) -> bool:
	return PROP_KINDS.has(kind) or TREE_KINDS.has(kind) \
		or (PROPS_B_KINDS.has(kind) or PROPS_C_KINDS.has(kind)) and not PROP_DECOR_KINDS.has(kind)
