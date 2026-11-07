class_name PlayerGroundState
extends PlayerState
## On foot, dry or wading: walk, sprint (drains stamina), drop down, start climbing.
## Shallow water halves the speed; walking into deep water hands over to swimming.


func step(motor: PlayerMotor, direction: Vector2, sprint: bool, delta: float) -> void:
	var moving: bool = direction != Vector2.ZERO
	motor.sprinting = sprint and moving and motor.can_sprint()
	if motor.sprinting:
		motor.drain_stamina(PlayerMotor.SPRINT_DRAIN * delta)
	else:
		motor.regen_stamina(delta)
	if moving:
		var speed: float = PlayerMotor.WALK_SPEED * motor.speed_scale_here()
		if motor.sprinting:
			speed *= PlayerMotor.SPRINT_MULTIPLIER
		motor.walk(direction, speed * delta)


func exit(motor: PlayerMotor) -> void:
	motor.sprinting = false
