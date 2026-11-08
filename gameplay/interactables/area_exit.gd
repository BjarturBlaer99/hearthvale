class_name AreaExit
extends Node2D
## A way out of an area: a house door, a doormat, later a road off the edge of the map.
## Stepping onto its cell takes the hero to the entry point `target_entry` of `target_area`
## (docs/TECH_DESIGN.md §3). Position = the top-left corner of its first cell; `size` cells
## wide and tall (a road off the map edge is several cells). Draws nothing: the tiles show the
## way out.

@export var target_area: StringName
@export var target_entry: StringName
@export var size: Vector2i = Vector2i.ONE


func cell() -> Vector2i:
	return PlayerMotor.cell_of(position + Vector2(0.5, 0.5))


func covers(at: Vector2i) -> bool:
	return Rect2i(cell(), size).has_point(at)
