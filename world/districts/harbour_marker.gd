class_name HarbourMarker
extends Node2D
## A district's landing: where you come ashore when the water is too low for the boat to
## sail in, and where you walk out to the boat while it waits at sea. It must be ground that
## is dry at every water level (the map tests check this). Position = the cell's top-left.

const COLOR: Color = Color(0.96, 0.90, 0.70)

## The boat is waiting at sea off this harbour. Set by the district; brightens the marker.
var boat_waiting: bool = false:
	set(value):
		boat_waiting = value
		queue_redraw()


func cell() -> Vector2i:
	return PlayerMotor.cell_of(position + Vector2(0.5, 0.5))


func _draw() -> void:
	var color: Color = Color(COLOR, 1.0 if boat_waiting else 0.45)
	draw_rect(Rect2(Vector2.ONE, Vector2(14, 14)), color, false, 1.0)
	# An anchor.
	draw_line(Vector2(8, 3), Vector2(8, 12), color, 1.0)
	draw_line(Vector2(5, 5), Vector2(11, 5), color, 1.0)
	draw_polyline(PackedVector2Array([Vector2(4, 9), Vector2(5, 12), Vector2(8, 13), Vector2(11, 12), Vector2(12, 9)]), color, 1.0)
