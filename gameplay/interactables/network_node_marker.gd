class_name NetworkNodeMarker
extends Node2D
## A flood-network node in the world: a pump, sluice or outlet. Repair it, then use the
## Network Key on it to raise or lower its district once you've seen every consequence.
## What it does is data (res://data/water: district, target, repair_requires); this only
## marks where it is. Position = the cell's top-left corner.

const BROKEN: Color = Color(0.86, 0.36, 0.30)
const WORKING: Color = Color(0.36, 0.86, 0.80)

@export var node_id: StringName


func cell() -> Vector2i:
	return PlayerMotor.cell_of(position + Vector2(0.5, 0.5))


func covers(at: Vector2i) -> bool:
	return at == cell()


func _draw() -> void:
	var color: Color = WORKING if GameState.is_network_node_repaired(node_id) else BROKEN
	draw_rect(Rect2(2, 2, 12, 12), Color(0.12, 0.14, 0.16))
	draw_rect(Rect2(2, 2, 12, 12), color, false, 1.0)
	# The valve wheel.
	draw_arc(Vector2(8, 8), 4.0, 0.0, TAU, 14, color, 1.5)
	draw_line(Vector2(8, 4), Vector2(8, 12), color, 1.0)
	draw_line(Vector2(4, 8), Vector2(12, 8), color, 1.0)
