class_name PlayerGroundState
extends PlayerState
## On foot: walk (or sprint) in 8 directions, slide along walls, hop down ledges, take stairs.


func step(motor: PlayerMotor, direction: Vector2, delta: float) -> void:
	if direction != Vector2.ZERO:
		motor.walk(direction, motor.walk_speed() * delta)
