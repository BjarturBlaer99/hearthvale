class_name PlayerGroundState
extends PlayerState
## On foot: walk in 8 directions, slide along walls, hop down ledges, take stairs.


func step(motor: PlayerMotor, direction: Vector2, delta: float) -> void:
	if direction != Vector2.ZERO:
		motor.walk(direction, PlayerMotor.WALK_SPEED * delta)
