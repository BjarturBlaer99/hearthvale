class_name PlayerSwimState
extends PlayerState
## In deep water, at the surface: slower than walking, no sprint. Walking out happens when
## the next cell is ground at or just below the surface; higher ledges need a ramp or a
## climbable face.


func step(motor: PlayerMotor, direction: Vector2, _sprint: bool, delta: float) -> void:
	motor.regen_stamina(delta)
	if direction != Vector2.ZERO:
		motor.walk(direction, PlayerMotor.SWIM_SPEED * delta)
