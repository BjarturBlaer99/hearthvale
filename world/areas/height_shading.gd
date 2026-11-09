class_name HeightShading
extends Node2D
## Draws over the Height layer what its square tiles can't show (TECH_DESIGN §3). Static: drawn
## once.
## - Heights: below every drop to the south there's a cliff face (earth, or cut stone in a
##   dungeon; taller drops, taller faces) with a dark lip and a soft shadow at its foot; below
##   solid things (walls, houses) just a soft shadow. A thin dark edge marks a lower neighbour
##   to the west, east or north.
## - Soft edges (ground_edges()): grass frays over the edge of a path where the two meet on the
##   same level, and water gets a dark line under its bank and foam lapping at it.

const T: float = 16.0
const EDGE_COLOR: Color = Color(0.0, 0.0, 0.0, 0.35)
const FACE_COLOR: Color = Color(0.36, 0.28, 0.20, 0.90)
const FACE_LINE: Color = Color(0.18, 0.13, 0.10, 0.55)
## In dungeons the faces are cut stone instead of earth.
const STONE_FACE_COLOR: Color = Color(0.24, 0.24, 0.29, 0.95)
const STONE_FACE_LINE: Color = Color(0.12, 0.12, 0.15, 0.7)

## Cut-stone cliff faces (dungeons) instead of earthy ones; the area sets it.
var stone_faces: bool = false
const LIP_COLOR: Color = Color(0.14, 0.10, 0.08, 0.95)
const FOOT_SHADOW: Color = Color(0.0, 0.0, 0.0, 0.22)
const SOLID_SHADOW: Color = Color(0.0, 0.0, 0.0, 0.30)
const SIDES: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP]
const ALL_SIDES: Array[Vector2i] = [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]
## Kinds of soft edge: grass fraying over a path, and water against its bank.
const FRINGE: StringName = &"fringe"
const BANK: StringName = &"bank"
const BANK_SHADE: Color = Color(0.08, 0.20, 0.38, 0.85)
const FOAM: Color = Color(0.82, 0.92, 1.0, 0.8)

var _grid: HeightGrid
## Soft edges to draw: [cell, side, kind].
var _edges: Array = []


## Shows `grid`'s heights. With the Height `layer` too, the soft edges of its paths and water.
func show_grid(grid: HeightGrid, layer: TileMapLayer = null) -> void:
	_grid = grid
	_edges = find_ground_edges(grid, layer) if layer != null else []
	queue_redraw()


## The soft edges drawn: [cell, the side of it the edge is on, FRINGE or BANK].
func ground_edges() -> Array:
	return _edges


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
				elif (other.y == GreyboxTiles.ROW_GROUND or other.y == GreyboxTiles.ROW_SOLID_GROUND) \
						and grid.height_at(neighbour) == grid.height_at(cell):
					out.append([cell, side, FRINGE])
	return out


func _draw() -> void:
	if _grid == null:
		return
	for edge: Array in _edges:
		if edge[2] == FRINGE:
			_draw_fringe(edge[0], edge[1])
		else:
			_draw_bank(edge[0], edge[1])
	for y: int in _grid.size.y:
		for x: int in _grid.size.x:
			var cell: Vector2i = Vector2i(x, y)
			var height: int = _grid.height_at(cell)
			var origin: Vector2 = Vector2(cell) * T
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


## What shows below a cell that's `levels` higher than the one south of it, from `top` down.
func _draw_drop(cell: Vector2i, top: Vector2, levels: int) -> void:
	if _grid.is_solid(cell):
		draw_rect(Rect2(top, Vector2(T, 4.0)), SOLID_SHADOW)
		return
	var face: float = minf(float(levels) * 4.0, 12.0)
	var line: Color = STONE_FACE_LINE if stone_faces else FACE_LINE
	draw_rect(Rect2(top, Vector2(T, face)), STONE_FACE_COLOR if stone_faces else FACE_COLOR)
	var stripe: float = 3.0
	while stripe < face:
		draw_line(top + Vector2(0.0, stripe + 0.5), top + Vector2(T, stripe + 0.5), line)
		stripe += 3.0
	var crack: float = float(posmod(cell.x * 7 + cell.y * 3, 11)) + 2.0
	draw_line(top + Vector2(crack + 0.5, 1.0), top + Vector2(crack + 0.5, face), line)
	draw_rect(Rect2(top, Vector2(T, 1.0)), LIP_COLOR)
	draw_rect(Rect2(top + Vector2(0.0, face), Vector2(T, 2.0)), FOOT_SHADOW)


## Grass fraying over a path's edge: blades of different lengths growing in from `side`, with
## gaps, in the greens of the grass at that height.
func _draw_fringe(cell: Vector2i, side: Vector2i) -> void:
	var grass: Color = GreyboxTiles.GROUND_COLORS[clampi(_grid.height_at(cell), 0, GreyboxTiles.GROUND_COLORS.size() - 1)]
	var origin: Vector2 = Vector2(cell) * T
	for along: int in int(T):
		var roll: int = _mix(cell, side, along)
		if roll % 5 < 2:
			continue
		@warning_ignore("integer_division")
		var depth: float = 1.0 + float((roll / 5) % 3)
		@warning_ignore("integer_division")
		var tone: int = (roll / 16) % 3
		var shade: Color = grass.darkened(0.14) if tone == 0 else (grass.lightened(0.1) if tone == 1 else grass)
		draw_rect(_strip(origin, side, along, depth), shade)


## Water meeting the land on `side`: a dark line under the bank, and dashes of foam beside it.
func _draw_bank(cell: Vector2i, side: Vector2i) -> void:
	var origin: Vector2 = Vector2(cell) * T
	for along: int in int(T):
		draw_rect(_strip(origin, side, along, 1.0), BANK_SHADE)
		@warning_ignore("integer_division")
		if _mix(cell, side, along / 3) % 3 != 0:
			draw_rect(_strip(origin, side, along, 1.0, 1.0), FOAM)


## A strip one pixel wide and `depth` deep, `along` pixels down the `side` of the cell at
## `origin`, starting `inset` pixels in from that side.
static func _strip(origin: Vector2, side: Vector2i, along: int, depth: float, inset: float = 0.0) -> Rect2:
	match side:
		Vector2i.UP:
			return Rect2(origin + Vector2(along, inset), Vector2(1.0, depth))
		Vector2i.DOWN:
			return Rect2(origin + Vector2(along, T - inset - depth), Vector2(1.0, depth))
		Vector2i.LEFT:
			return Rect2(origin + Vector2(inset, along), Vector2(depth, 1.0))
	return Rect2(origin + Vector2(T - inset - depth, along), Vector2(depth, 1.0))


## The same number for the same cell, side and step, every time.
static func _mix(cell: Vector2i, side: Vector2i, step: int) -> int:
	var h: int = (cell.x * 73856093) ^ (cell.y * 19349663) ^ ((side.x + 2) * 83492791) ^ ((side.y + 2) * 2654435) ^ (step * 40503)
	h = (h ^ (h >> 13)) * 1274126177
	return absi(h ^ (h >> 16))
