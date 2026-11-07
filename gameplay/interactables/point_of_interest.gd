class_name PointOfInterest
extends Node2D
## A spot the player uses by standing on it and pressing interact: a door, a hatch, an
## entrance. The node's position is the top-left corner of its footprint, in district
## pixels. Using it sets `visited_flag` in GameState, so it is remembered through water
## changes. Interiors behind these arrive with M5.

@export var label: String = "Interact"
@export var used_message: String = "Done."
@export var visited_flag: StringName
## Usable only on foot on dry ground: not while it is underwater or awash.
@export var requires_dry: bool = true
@export var footprint: Vector2i = Vector2i.ONE
@export var color: Color = Color(1.0, 0.78, 0.30)

## Whether the current water lets the player use it. Set by the district.
var usable: bool = true:
	set(value):
		usable = value
		queue_redraw()


func origin_cell() -> Vector2i:
	return PlayerMotor.cell_of(position + Vector2(0.5, 0.5))


func cells() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for y: int in footprint.y:
		for x: int in footprint.x:
			out.append(origin_cell() + Vector2i(x, y))
	return out


func covers(cell: Vector2i) -> bool:
	return Rect2i(origin_cell(), footprint).has_point(cell)


func is_usable_at(terrain: TerrainQuery, water_height: int) -> bool:
	if not requires_dry:
		return true
	for cell: Vector2i in cells():
		if terrain.cell_kind(cell, water_height) != TerrainQuery.CellKind.DRY:
			return false
	return true


func visited() -> bool:
	return GameState.get_flag(visited_flag) == true


func _draw() -> void:
	var size: Vector2 = Vector2(footprint) * PlayerMotor.TILE
	var alpha: float = 1.0 if usable else 0.35
	var area: Rect2 = Rect2(Vector2.ZERO, size).grow(-1.0)
	draw_rect(area, Color(color.darkened(0.6), 0.8 * alpha))
	draw_rect(area, Color(color, alpha), false, 1.0)
	var c: Vector2 = size * 0.5
	var diamond: PackedVector2Array = [c + Vector2(0, -4), c + Vector2(4, 0), c + Vector2(0, 4), c + Vector2(-4, 0)]
	draw_colored_polygon(diamond, Color(color, alpha))
	if visited():
		draw_polyline(PackedVector2Array([c + Vector2(-3, 0), c + Vector2(-1, 2), c + Vector2(3, -2)]), Color(1, 1, 1, alpha), 1.5)
