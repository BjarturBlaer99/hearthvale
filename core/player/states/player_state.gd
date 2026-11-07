class_name PlayerState
extends RefCounted
## One state of the player's movement state machine (docs/TECH_DESIGN.md §4).
## States are stateless between uses except for what enter() sets up; PlayerMotor owns them.


func enter(_motor: PlayerMotor, _data: Dictionary) -> void:
	pass


func exit(_motor: PlayerMotor) -> void:
	pass


## `direction` is already snapped to one of 8 unit vectors, or zero.
func step(_motor: PlayerMotor, _direction: Vector2, _sprint: bool, _delta: float) -> void:
	pass
