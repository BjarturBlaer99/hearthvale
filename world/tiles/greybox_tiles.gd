class_name GreyboxTiles
extends RefCounted
## Layout of the generated greybox tile atlas (made by tools/greybox/). Shared by the build
## tools and the district scripts so atlas coordinates live in one place.
##
## Atlas rows (16 px tiles, 8 columns = heights 0-7):
##   0 plain, 1 climbable (ivy), 2 ramp (steps), 3 water: (0,3) shallow, (1,3) deep.

const TEXTURE_PATH: String = "res://world/tiles/greybox_tiles.png"
const TILESET_PATH: String = "res://world/tiles/greybox_tiles.tres"
const SOURCE_ID: int = 0
const TILE_SIZE: int = 16
const COLUMNS: int = 8
const ROWS: int = 4

const ROW_PLAIN: int = 0
const ROW_CLIMBABLE: int = 1
const ROW_RAMP: int = 2
const WATER_SHALLOW: Vector2i = Vector2i(0, 3)
const WATER_DEEP: Vector2i = Vector2i(1, 3)

## Custom data layers on the TileSet (TECH_DESIGN §3.2).
const DATA_HEIGHT: String = "height"
const DATA_CLIMBABLE: String = "climbable"
const DATA_RAMP: String = "ramp"
const DATA_DIVE_POINT: String = "dive_point"

## Street level is dark asphalt; each level up is lighter, sunlit concrete.
const HEIGHT_COLORS: Array[Color] = [
	Color(0.204, 0.220, 0.243),
	Color(0.306, 0.298, 0.275),
	Color(0.400, 0.376, 0.322),
	Color(0.494, 0.459, 0.376),
	Color(0.588, 0.541, 0.431),
	Color(0.675, 0.620, 0.486),
	Color(0.761, 0.702, 0.549),
	Color(0.839, 0.784, 0.627),
]
const IVY_COLOR: Color = Color(0.310, 0.478, 0.227)
## Translucent, so the terrain stays faintly visible underneath (TECH_DESIGN §3.3).
const SHALLOW_COLOR: Color = Color(0.286, 0.659, 0.627, 0.45)
const DEEP_COLOR: Color = Color(0.110, 0.361, 0.420, 0.72)


static func terrain_coords(height: int, climbable: bool, ramp: bool) -> Vector2i:
	var row: int = ROW_PLAIN
	if ramp:
		row = ROW_RAMP
	elif climbable:
		row = ROW_CLIMBABLE
	return Vector2i(clampi(height, 0, COLUMNS - 1), row)
