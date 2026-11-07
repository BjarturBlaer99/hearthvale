class_name SeaPort
extends Node2D
## A district's approach on the sea map: sail into its footprint to go there. Leaving that
## district by sea brings the boat back out at `exit_cell`, facing away from the island.
## Position = the footprint's top-left corner.

@export var district_id: StringName
@export var footprint: Vector2i = Vector2i(2, 2)
## A deep cell outside the footprint, so the boat doesn't sail straight back in.
@export var exit_cell: Vector2i
@export var exit_heading_degrees: float = 0.0

const COLOR: Color = Color(1.0, 0.86, 0.45)


func origin_cell() -> Vector2i:
	return PlayerMotor.cell_of(position + Vector2(0.5, 0.5))


func covers(cell: Vector2i) -> bool:
	return Rect2i(origin_cell(), footprint).has_point(cell)


func exit_heading() -> float:
	return deg_to_rad(exit_heading_degrees)


func _draw() -> void:
	var area: Rect2 = Rect2(Vector2.ZERO, Vector2(footprint) * PlayerMotor.TILE)
	draw_rect(area, Color(COLOR, 0.16))
	draw_rect(area, Color(COLOR, 0.8), false, 1.0)
	var title: String = str(DataRegistry.get_district(district_id).get("name", district_id))
	draw_string(ThemeDB.fallback_font, Vector2(0.0, -3.0), title, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 8, Color(1, 1, 1, 0.9))
