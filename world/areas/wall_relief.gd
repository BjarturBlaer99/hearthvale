class_name WallRelief
extends Node2D
## Walls with height (P1d, docs/TECH_DESIGN.md §3): drawn over the wall tiles of the Height
## layer, which stay exactly as they are (so nothing about where the hero can go changes).
## - A wall cell with open floor to its south shows its front FACE: bricks or boards, lit along
##   the top and dark at the floor. The face is taller than a cell: it rises FACE_RISE pixels
##   over the foot of the wall cell behind it. It doesn't rise into the room behind (in a
##   dungeon, the wall behind a room's north wall is the next room's south wall): there the
##   short face is used, a cell high.
## - Every other wall cell shows its TOP: one flat shade, edged with light where it ends to the
##   north or west and with shadow to the east.
## - A wall one cell thick, open to the north as well, shows a strip of top above a shorter
##   face, in its own cell.
## Which tiles are walls, and what they are built of, comes from ReliefAtlas.MATERIALS.
## The whole relief is put together once, as one picture the size of the map, and drawn in one
## go just above the Height layer: hundreds of wall cells cost no more than one. For show only.

const FACE: StringName = &"face"
const TOP: StringName = &"top"
## The strip of top a one-cell-thick wall shows above its face (px).
const THIN_TOP: int = 6
const T: int = GreyboxTiles.TILE_SIZE
const EDGE_LIGHT: Color = Color(1.0, 1.0, 1.0, 0.16)
const EDGE_DARK: Color = Color(0.0, 0.0, 0.0, 0.30)

## What each wall cell is built of ("stone", "timber", "ruin").
var materials: Dictionary[Vector2i, String] = {}
## The relief, put together: one picture the size of the map.
var picture: ImageTexture

var _size: Vector2i = Vector2i.ZERO
## A dungeon's room size in cells (zero: the area is one room).
var _room_size: Vector2i = Vector2i.ZERO


## Which part of a wall the cell `cell` shows, given the set of wall cells `walls` in a map of
## `size` cells: its FACE if the cell to its south is in the map and isn't wall, else its TOP.
## Empty if `cell` isn't a wall.
static func part_of(walls: Dictionary, size: Vector2i, cell: Vector2i) -> StringName:
	if not walls.has(cell):
		return &""
	var south: Vector2i = cell + Vector2i.DOWN
	if south.y < size.y and not walls.has(south):
		return FACE
	return TOP


## Whether the wall in `cell` ends on `side`: the cell there is in the map and isn't wall.
static func open_to(walls: Dictionary, size: Vector2i, cell: Vector2i, side: Vector2i) -> bool:
	var there: Vector2i = cell + side
	return Rect2i(Vector2i.ZERO, size).has_point(there) and not walls.has(there)


## Whether the face of the wall in `cell` may rise over the wall cell behind it: there is one,
## and it is in the same room (`room_size` in cells; zero for an area that is one room).
static func rises(walls: Dictionary, room_size: Vector2i, cell: Vector2i) -> bool:
	if not walls.has(cell + Vector2i.UP):
		return false
	return room_size.y <= 0 or cell.y % room_size.y != 0


## The wall cells of `layer` and what each is built of.
static func walls_of(layer: TileMapLayer) -> Dictionary[Vector2i, String]:
	var out: Dictionary[Vector2i, String] = {}
	for kind: String in ReliefAtlas.MATERIALS:
		for cell: Vector2i in layer.get_used_cells_by_id(GreyboxTiles.SOURCE_ID, GreyboxTiles.coords(kind)):
			out[cell] = ReliefAtlas.MATERIALS[kind]
	return out


## A relief for the walls of `layer`, a map of `size` cells in rooms of `room_size` cells (zero:
## one room); null if it has no such walls.
static func make(layer: TileMapLayer, size: Vector2i, room_size: Vector2i = Vector2i.ZERO) -> WallRelief:
	var walls: Dictionary[Vector2i, String] = walls_of(layer)
	if walls.is_empty():
		return null
	var relief: WallRelief = WallRelief.new()
	relief.name = "WallRelief"
	relief.materials = walls
	relief._size = size
	relief._room_size = room_size
	relief.picture = ImageTexture.create_from_image(relief._compose())
	return relief


func part(cell: Vector2i) -> StringName:
	return part_of(materials, _size, cell)


func _draw() -> void:
	draw_texture(picture, Vector2.ZERO)


## Puts the relief together from the atlas: tops first, then faces, since a face rises over the
## foot of the top behind it.
func _compose() -> Image:
	var atlas: Image = (load(ReliefAtlas.TEXTURE_PATH) as Texture2D).get_image()
	atlas.convert(Image.FORMAT_RGBA8)
	var out: Image = Image.create(_size.x * T, _size.y * T, false, Image.FORMAT_RGBA8)
	out.fill(Color(0, 0, 0, 0))
	for cell: Vector2i in materials:
		if part(cell) == TOP:
			_put_top(out, atlas, cell, Rect2i(cell * T, Vector2i(T, T)))
	for cell: Vector2i in materials:
		if part(cell) == FACE:
			_put_face(out, atlas, cell)
	return out


func _put_top(out: Image, atlas: Image, cell: Vector2i, rect: Rect2i) -> void:
	var source: Rect2i = Rect2i(ReliefAtlas.top(materials[cell]))
	out.blit_rect(atlas, Rect2i(source.position, rect.size), rect.position)
	if open_to(materials, _size, cell, Vector2i.UP):
		_shade(out, Rect2i(rect.position, Vector2i(rect.size.x, 1)), EDGE_LIGHT)
	if open_to(materials, _size, cell, Vector2i.LEFT):
		_shade(out, Rect2i(rect.position, Vector2i(1, rect.size.y)), EDGE_LIGHT)
	if open_to(materials, _size, cell, Vector2i.RIGHT):
		_shade(out, Rect2i(rect.position + Vector2i(rect.size.x - 1, 0), Vector2i(1, rect.size.y)), EDGE_DARK)


func _put_face(out: Image, atlas: Image, cell: Vector2i) -> void:
	var corner: Vector2i = cell * T
	var short: Rect2i = Rect2i(ReliefAtlas.short_face(materials[cell]))
	if rises(materials, _room_size, cell):
		# Wall behind it in the same room: the tall face, risen over that wall's foot.
		out.blit_rect(atlas, Rect2i(ReliefAtlas.face(materials[cell])), corner - Vector2i(0, ReliefAtlas.FACE_RISE))
	elif materials.has(cell + Vector2i.UP):
		# Wall behind it, but in the next room: the short face, in its own cell.
		out.blit_rect(atlas, short, corner)
	else:
		# One cell thick: a strip of its top, then as much face as fits below, ending in the
		# face's last row so the dark line meets the floor.
		_put_top(out, atlas, cell, Rect2i(corner, Vector2i(T, THIN_TOP)))
		var shown: int = T - THIN_TOP - 1
		out.blit_rect(atlas, Rect2i(short.position, Vector2i(T, shown)), corner + Vector2i(0, THIN_TOP))
		out.blit_rect(atlas, Rect2i(short.position + Vector2i(0, short.size.y - 1), Vector2i(T, 1)), corner + Vector2i(0, T - 1))
	# Where the wall ends beside this face, the end is in shadow.
	if open_to(materials, _size, cell, Vector2i.RIGHT):
		_shade(out, Rect2i(corner + Vector2i(T - 1, 0), Vector2i(1, T)), EDGE_DARK)


## Blends `color` over the pixels of `rect` (only where something is already painted).
static func _shade(out: Image, rect: Rect2i, color: Color) -> void:
	var tint: Color = Color(color.r, color.g, color.b)
	for y: int in range(rect.position.y, rect.end.y):
		for x: int in range(rect.position.x, rect.end.x):
			var under: Color = out.get_pixel(x, y)
			if under.a > 0.0:
				out.set_pixel(x, y, Color(under.lerp(tint, color.a), under.a))
