class_name EdgeAtlas
extends RefCounted
## Layout of the ground's edge sheet (world/tiles/ground_edges.png; the farm-look plan, phase A):
## the pictures HeightShading draws where two kinds of ground meet, cut from the art pack's own
## edge tiles. Pure: which piece goes where is worked out here, and HeightShading only draws.
## - Fringe: grass lapping over a path. Eight rows, one for each height (the grass's colours at
##   that height); nineteen pieces to a row: one for each set of sides the grass is on (SIDES:
##   north 1, east 2, south 4, west 8; the piece for a set stands in column set - 1), then four
##   corner pieces (CORNERS: north-east, south-east, south-west, north-west) for grass that
##   touches a path cell only at its corner.
## - Bank: earth and foam where water meets anything else. One row of the same nineteen.
## - Faces: the foot of a cliff, earth and cut stone, each 16 wide and FACE_ROWS tall; a drop
##   shows as many of its lowest rows as it is tall.
## Each piece is a cell's size, clear where the ground under it shows.

const TEXTURE_PATH: String = "res://world/tiles/ground_edges.png"
const T: int = GreyboxTiles.TILE_SIZE
const SIZE: Vector2i = Vector2i(19 * T, 10 * T)
## The sides of a cell and the bit each has in a set of sides.
const SIDES: Dictionary = {Vector2i.UP: 1, Vector2i.RIGHT: 2, Vector2i.DOWN: 4, Vector2i.LEFT: 8}
## The corners of a cell, in the order their pieces stand, and the two sides each lies between.
const CORNERS: Array[Vector2i] = [Vector2i(1, -1), Vector2i(1, 1), Vector2i(-1, 1), Vector2i(-1, -1)]
const HEIGHTS: int = GreyboxTiles.COLUMNS
const BANK_ROW: int = 8
const FACE_ROW: int = 9
const FACE_ROWS: int = 12


## The fringe piece for grass on the sides in `sides` (1 to 15) of a path cell at `height`.
static func fringe(sides: int, height: int) -> Rect2:
	return _piece(clampi(sides, 1, 15) - 1, clampi(height, 0, HEIGHTS - 1))


## The fringe piece for grass touching corner `corner` (an index into CORNERS) at `height`.
static func fringe_corner(corner: int, height: int) -> Rect2:
	return _piece(15 + clampi(corner, 0, 3), clampi(height, 0, HEIGHTS - 1))


## The bank piece for land on the sides in `sides` (1 to 15) of a water cell.
static func bank(sides: int) -> Rect2:
	return _piece(clampi(sides, 1, 15) - 1, BANK_ROW)


## The bank piece for land touching corner `corner` (an index into CORNERS) of a water cell.
static func bank_corner(corner: int) -> Rect2:
	return _piece(15 + clampi(corner, 0, 3), BANK_ROW)


## The lowest `rows` pixel rows of a cliff's face: earth, or cut stone.
static func face(stone: bool, rows: int) -> Rect2:
	var shown: int = clampi(rows, 1, FACE_ROWS)
	return Rect2((T if stone else 0), FACE_ROW * T + FACE_ROWS - shown, T, shown)


static func _piece(column: int, row: int) -> Rect2:
	return Rect2(column * T, row * T, T, T)
