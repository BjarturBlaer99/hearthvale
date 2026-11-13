class_name FarmPlot
extends Node2D
## The hero's plot as it lies in an area (P3, GDD §7): a bed of soil, each cell drawn bare,
## tilled or watered as GameState's Farm says. Position = the top-left corner of its first
## cell; its size is the farm rules'. It is ground to walk on: it blocks nothing and nothing is
## picked up from it. The area works its cells with the tools (AreaController.use_item).

const SHEET: Texture2D = preload("res://gameplay/art/soil.png")
## Frames in the order the tool paints them (a test checks).
const FRAMES: Dictionary = {&"bare": 0, &"bare_b": 1, &"tilled": 2, &"watered": 3}
const CELL: Vector2i = Vector2i(16, 16)
## The bed's rim: a dark shade of the soil, a pixel wide, so it reads as dug and not as a path.
const RIM: Color = Color(0.30, 0.20, 0.13)


func _ready() -> void:
	EventBus.farm_changed.connect(queue_redraw)


## The map cell of its north-west corner.
func origin() -> Vector2i:
	return PlayerMotor.cell_of(position + Vector2(0.5, 0.5))


## Its size in cells (the farm rules').
func plot_size() -> Vector2i:
	return GameState.farm().size


## Whether the map cell `at` is one of the plot's.
func covers(at: Vector2i) -> bool:
	return Rect2i(origin(), plot_size()).has_point(at)


## The plot's own cell for the map cell `at` ((0, 0) is its north-west corner).
func plot_cell(at: Vector2i) -> Vector2i:
	return at - origin()


## The map cell of the plot's own cell `cell`.
func map_cell(cell: Vector2i) -> Vector2i:
	return origin() + cell


## Every map cell of the plot, row by row.
func cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y: int in plot_size().y:
		for x: int in plot_size().x:
			out.append(origin() + Vector2i(x, y))
	return out


## What the map cell `at` is: a Farm state, or "" if it isn't a cell of the plot.
func soil_at(at: Vector2i) -> StringName:
	return GameState.farm().state_of(plot_cell(at)) if covers(at) else &""


## Takes whatever grows on the plot's cells off `layer` (flowers and tufts on the Decor layer):
## it is a bed of soil. For show: those tiles block nothing.
func clear_ground(layer: TileMapLayer) -> void:
	if layer == null:
		return
	for cell: Vector2i in cells():
		layer.erase_cell(cell)


## The picture a cell shows: its state's, bare soil in two kinds so the bed isn't a pattern.
static func frame_for(state: StringName, cell: Vector2i) -> StringName:
	if state == Farm.BARE and (cell.x * 7 + cell.y * 13) % 3 == 0:
		return &"bare_b"
	return state


func _draw() -> void:
	var farm: Farm = GameState.farm()
	var size: Vector2i = plot_size()
	for y: int in size.y:
		for x: int in size.x:
			var cell: Vector2i = Vector2i(x, y)
			SpriteSheet.draw(self, SHEET, FRAMES[frame_for(farm.state_of(cell), cell)], CELL, Vector2(cell * CELL))
	var bed: Vector2 = Vector2(size * CELL)
	draw_rect(Rect2(0.0, 0.0, bed.x, 1.0), RIM)
	draw_rect(Rect2(0.0, bed.y - 1.0, bed.x, 1.0), RIM)
	draw_rect(Rect2(0.0, 0.0, 1.0, bed.y), RIM)
	draw_rect(Rect2(bed.x - 1.0, 0.0, 1.0, bed.y), RIM)
