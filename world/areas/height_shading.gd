class_name HeightShading
extends Node2D
## Draws over the Height layer what its square tiles can't show (TECH_DESIGN §3). Static: drawn
## once.
## - Heights: below every drop to the south there's a cliff face (earth, or cut stone in a
##   dungeon; taller drops, taller faces) with a dark lip and a soft shadow at its foot; below
##   solid things (walls, houses) just a soft shadow. A thin dark edge marks a lower neighbour
##   to the west, east or north.
## - Soft edges (ground_edges()): grass laps over the edge of a path where the two meet on the
##   same level, and water gets a bank of earth and foam against everything else.
## The fringe, the bank and the cliff faces are pictures since the farm-look plan's phase A
## (world/tiles/ground_edges.png, cut from the art pack's own edge tiles; EdgeAtlas says which
## piece goes where); the shadows, the lip and the thin dark edges are still drawn in code.

const T: float = 16.0
const SHEET: Texture2D = preload("res://world/tiles/ground_edges.png")
const EDGE_COLOR: Color = Color(0.16, 0.07, 0.10, 0.35)

## Cut-stone cliff faces (dungeons) instead of earthy ones; the area sets it.
var stone_faces: bool = false
## The dark line along a drop's top: the art pack's outline.
const LIP_COLOR: Color = Color(0.08, 0.11, 0.11, 0.95)
## Shadows fade out in two steps (P1b): the whole shadow in the faint shade, and the half of
## it nearest the thing that casts it darkened again.
const SHADE_FAR: Color = Color(0.22, 0.09, 0.18, 0.15)
const SHADE_NEAR: Color = Color(0.22, 0.09, 0.18, 0.18)
## The sun stands in the north-west: tall solid things also shade the ground to their east.
## How far a shadow reaches (px); its darker half is nearest the thing.
const CAST: float = 6.0
const SIDES: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP]
const ALL_SIDES: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
## Kinds of soft edge: grass lapping over a path, and water against its bank.
const FRINGE: StringName = &"fringe"
const BANK: StringName = &"bank"

var _grid: HeightGrid
## Soft edges to draw: [cell, side, kind].
var _edges: Array = []
## The sides of each cell that have an edge, by kind (sides_of), and the corners where the
## other ground touches a cell only diagonally (find_corners): what is drawn from the sheet.
var _sides: Dictionary = {}
var _corners: Array = []


## Shows `grid`'s heights. With the Height `layer` too, the soft edges of its paths and water.
func show_grid(grid: HeightGrid, layer: TileMapLayer = null) -> void:
	_grid = grid
	_edges = find_ground_edges(grid, layer) if layer != null else []
	_sides = sides_of(_edges)
	_corners = find_corners(grid, layer, _sides) if layer != null else []
	queue_redraw()


## The soft edges drawn: [cell, the side of it the edge is on, FRINGE or BANK].
func ground_edges() -> Array:
	return _edges


## The corners drawn: [cell, the corner of it (an index into EdgeAtlas.CORNERS), FRINGE or BANK].
func ground_corners() -> Array:
	return _corners


## Every side of a path cell that meets grass on the same level (FRINGE: the grass frays over
## it), and every side of a water cell that meets anything else (BANK).
static func find_ground_edges(grid: HeightGrid, layer: TileMapLayer) -> Array:
	var out: Array = []
	var water: Vector2i = GreyboxTiles.coords("water")
	for y: int in grid.size.y:
		for x: int in grid.size.x:
			var cell: Vector2i = Vector2i(x, y)
			var tile: Vector2i = layer.get_cell_atlas_coords(cell)
			var is_water: bool = tile == water
			if not is_water and tile.y != GreyboxTiles.ROW_PATH:
				continue
			for side: Vector2i in ALL_SIDES:
				var neighbour: Vector2i = cell + side
				if not grid.in_bounds(neighbour):
					continue
				var other: Vector2i = layer.get_cell_atlas_coords(neighbour)
				if is_water:
					if other != water:
						out.append([cell, side, BANK])
				elif _is_grass(other) and grid.height_at(neighbour) == grid.height_at(cell):
					out.append([cell, side, FRINGE])
	return out


## Whether the atlas tile `tile` is grass, or the same grass under a prop.
static func _is_grass(tile: Vector2i) -> bool:
	return tile.y == GreyboxTiles.ROW_GROUND or tile.y == GreyboxTiles.ROW_SOLID_GROUND


## `edges` gathered by cell: { FRINGE: { cell: sides }, BANK: { cell: sides } }, the sides as
## EdgeAtlas.SIDES adds them up. One picture then shows all of a cell's edges of a kind.
static func sides_of(edges: Array) -> Dictionary:
	var out: Dictionary = {FRINGE: {}, BANK: {}}
	for edge: Array in edges:
		var by_cell: Dictionary = out[edge[2]]
		by_cell[edge[0]] = int(by_cell.get(edge[0], 0)) | int(EdgeAtlas.SIDES[edge[1]])
	return out


## Every corner of a path cell that grass on the same level touches only diagonally, and every
## corner of a water cell that land touches only diagonally: [cell, corner, kind], the corner
## an index into EdgeAtlas.CORNERS. A corner between two sides, one of which has an edge
## already (`sides`, from sides_of), is that side's picture's to show.
static func find_corners(grid: HeightGrid, layer: TileMapLayer, sides: Dictionary) -> Array:
	var out: Array = []
	var water: Vector2i = GreyboxTiles.coords("water")
	for y: int in grid.size.y:
		for x: int in grid.size.x:
			var cell: Vector2i = Vector2i(x, y)
			var tile: Vector2i = layer.get_cell_atlas_coords(cell)
			var is_water: bool = tile == water
			if not is_water and tile.y != GreyboxTiles.ROW_PATH:
				continue
			var kind: StringName = BANK if is_water else FRINGE
			var edged: int = int((sides.get(kind, {}) as Dictionary).get(cell, 0))
			for corner: int in EdgeAtlas.CORNERS.size():
				var way: Vector2i = EdgeAtlas.CORNERS[corner]
				var between: int = int(EdgeAtlas.SIDES[Vector2i(way.x, 0)]) | int(EdgeAtlas.SIDES[Vector2i(0, way.y)])
				var neighbour: Vector2i = cell + way
				if edged & between or not grid.in_bounds(neighbour):
					continue
				var other: Vector2i = layer.get_cell_atlas_coords(neighbour)
				if is_water:
					if other != water:
						out.append([cell, corner, BANK])
				elif _is_grass(other) and grid.height_at(neighbour) == grid.height_at(cell):
					out.append([cell, corner, FRINGE])
	return out


func _draw() -> void:
	if _grid == null:
		return
	_draw_edges()
	for y: int in _grid.size.y:
		for x: int in _grid.size.x:
			var cell: Vector2i = Vector2i(x, y)
			var height: int = _grid.height_at(cell)
			var origin: Vector2 = Vector2(cell) * T
			_draw_cast(cell)
			var below: Vector2i = cell + Vector2i.DOWN
			if _grid.in_bounds(below) and _grid.height_at(below) < height:
				_draw_drop(cell, origin + Vector2(0.0, T), height - _grid.height_at(below))
			for side: Vector2i in SIDES:
				var neighbour: Vector2i = cell + side
				if not _grid.in_bounds(neighbour) or _grid.height_at(neighbour) >= height:
					continue
				match side:
					Vector2i.LEFT:
						draw_line(origin + Vector2(0.5, 0.0), origin + Vector2(0.5, T), EDGE_COLOR)
					Vector2i.RIGHT:
						draw_line(origin + Vector2(T - 0.5, 0.0), origin + Vector2(T - 0.5, T), EDGE_COLOR)
					Vector2i.UP:
						draw_line(origin + Vector2(0.0, 0.5), origin + Vector2(T, 0.5), EDGE_COLOR)


## Kinds of cast shadow on an open cell: down its west side, the same but starting below the
## shadow from the north, or only its north-west corner.
const CAST_SIDE: StringName = &"side"
const CAST_SIDE_BELOW: StringName = &"side_below"
const CAST_CORNER: StringName = &"corner"


## The shadow a taller solid neighbour to the west (or north-west) casts on open `cell`, or
## empty for none. The shadow from the north is _draw_drop's.
static func cast_on(grid: HeightGrid, cell: Vector2i) -> StringName:
	if grid.is_solid(cell):
		return &""
	var north: bool = _casts(grid, cell + Vector2i.UP, cell)
	if _casts(grid, cell + Vector2i.LEFT, cell):
		return CAST_SIDE_BELOW if north else CAST_SIDE
	if not north and _casts(grid, cell + Vector2i(-1, -1), cell):
		return CAST_CORNER
	return &""


func _draw_cast(cell: Vector2i) -> void:
	var origin: Vector2 = Vector2(cell) * T
	var near: float = CAST / 2.0
	match cast_on(_grid, cell):
		CAST_SIDE:
			draw_rect(Rect2(origin, Vector2(CAST, T)), SHADE_FAR)
			draw_rect(Rect2(origin, Vector2(near, T)), SHADE_NEAR)
		CAST_SIDE_BELOW:
			draw_rect(Rect2(origin + Vector2(0.0, CAST), Vector2(CAST, T - CAST)), SHADE_FAR)
			draw_rect(Rect2(origin + Vector2(0.0, near), Vector2(near, T - near)), SHADE_NEAR)
		CAST_CORNER:
			draw_rect(Rect2(origin, Vector2(CAST, CAST)), SHADE_FAR)
			draw_rect(Rect2(origin, Vector2(near, near)), SHADE_NEAR)


## Whether `from` is a solid thing standing taller than `onto`.
static func _casts(grid: HeightGrid, from: Vector2i, onto: Vector2i) -> bool:
	return grid.in_bounds(from) and grid.is_solid(from) and grid.height_at(from) > grid.height_at(onto)


## What shows below a cell that's `levels` higher than the one south of it, from `top` down.
func _draw_drop(cell: Vector2i, top: Vector2, levels: int) -> void:
	if _grid.is_solid(cell):
		draw_rect(Rect2(top, Vector2(T, CAST)), SHADE_FAR)
		draw_rect(Rect2(top, Vector2(T, CAST / 2.0)), SHADE_NEAR)
		return
	var face: float = minf(float(levels) * 4.0, float(EdgeAtlas.FACE_ROWS))
	draw_texture_rect_region(SHEET, Rect2(top, Vector2(T, face)), EdgeAtlas.face(stone_faces, int(face)))
	draw_rect(Rect2(top, Vector2(T, 1.0)), LIP_COLOR)
	draw_rect(Rect2(top + Vector2(0.0, face), Vector2(T, 4.0)), SHADE_FAR)
	draw_rect(Rect2(top + Vector2(0.0, face), Vector2(T, 2.0)), SHADE_NEAR)


## The fringe and the bank, from the edge sheet: for each cell one picture for all its sides,
## and one for each corner the other ground touches only diagonally.
func _draw_edges() -> void:
	for kind: StringName in _sides:
		var by_cell: Dictionary = _sides[kind]
		for cell: Vector2i in by_cell:
			var sides: int = by_cell[cell]
			var piece: Rect2 = EdgeAtlas.fringe(sides, _grid.height_at(cell)) if kind == FRINGE else EdgeAtlas.bank(sides)
			draw_texture_rect_region(SHEET, Rect2(Vector2(cell) * T, Vector2(T, T)), piece)
	for corner: Array in _corners:
		var cell: Vector2i = corner[0]
		var piece: Rect2 = EdgeAtlas.fringe_corner(corner[1], _grid.height_at(cell)) if corner[2] == FRINGE else EdgeAtlas.bank_corner(corner[1])
		draw_texture_rect_region(SHEET, Rect2(Vector2(cell) * T, Vector2(T, T)), piece)
