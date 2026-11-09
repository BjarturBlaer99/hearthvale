class_name HeightShading
extends Node2D
## Draws cliff edges over the Height layer so heights read at a glance (TECH_DESIGN §3.2).
## Below every drop to the south there's an earthy cliff face (taller drops, taller faces) with
## a dark lip and a soft shadow at its foot; below solid things (walls, houses) just a soft
## shadow. A thin dark edge marks a lower neighbour to the west, east or north. Static: drawn
## once.

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

var _grid: HeightGrid


func show_grid(grid: HeightGrid) -> void:
	_grid = grid
	queue_redraw()


func _draw() -> void:
	if _grid == null:
		return
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
