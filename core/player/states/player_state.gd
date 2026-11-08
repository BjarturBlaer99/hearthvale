class_name PlayerState
extends RefCounted
## One state of the hero's state machine (docs/TECH_DESIGN.md §4). PlayerMotor owns them.


func enter(_motor: PlayerMotor, _data: Dictionary) -> void:
	pass


func exit(_motor: PlayerMotor) -> void:
	pass


## `direction` is already snapped to one of 8 unit vectors, or zero.
func step(_motor: PlayerMotor, _direction: Vector2, _delta: float) -> void:
	pass
