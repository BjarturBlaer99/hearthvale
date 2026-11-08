class_name AreaExit
extends Node2D
## A way out of an area: a house door, a doormat, later a road off the edge of the map.
## Stepping onto its cell takes the hero to the entry point `target_entry` of `target_area`
## (docs/TECH_DESIGN.md §3). Position = the cell's top-left corner. Draws nothing: the tiles
## show the door.

@export var target_area: StringName
@export var target_entry: StringName


func cell() -> Vector2i:
	return PlayerMotor.cell_of(position + Vector2(0.5, 0.5))


func covers(at: Vector2i) -> bool:
	return at == cell()
