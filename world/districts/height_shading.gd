class_name HeightShading
extends Node2D
## Draws cliff edges over the Height layer so heights read at a glance (TECH_DESIGN §3.2):
## a dark wall face below every drop to the south (taller drops, taller faces), and a thin
## dark edge wherever a neighbour to the west, east or north is lower. Static: drawn once.

const T: float = 16.0
const EDGE_COLOR: Color = Color(0.0, 0.0, 0.0, 0.35)
const WALL_COLOR: Color = Color(0.07, 0.06, 0.05, 0.55)
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
				var face: float = minf(float(height - _grid.height_at(below)) * 2.0, 8.0)
				draw_rect(Rect2(origin + Vector2(0.0, T), Vector2(T, face)), WALL_COLOR)
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
