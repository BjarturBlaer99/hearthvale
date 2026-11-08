class_name PlayerHurtState
extends PlayerState
## Knocked back by a hit: pushed along it at KNOCKBACK_SPEED, with no control, until the push
## is used up. The push follows the terrain rules: it can carry the hero off a ledge but never
## through a wall. Data: { "push": Vector2 } (direction times distance in px).

var _direction: Vector2 = Vector2.ZERO
var _left: float = 0.0


func enter(_motor: PlayerMotor, data: Dictionary) -> void:
	var push: Vector2 = data.get("push", Vector2.ZERO)
	_direction = push.normalized()
	_left = push.length()


func step(motor: PlayerMotor, _direction_input: Vector2, delta: float) -> void:
	var distance: float = minf(_left, PlayerMotor.KNOCKBACK_SPEED * delta)
	if distance > 0.0 and _direction != Vector2.ZERO:
		motor.walk(_direction, distance)
	_left -= distance
	if _left <= 0.0:
		motor.change_state(PlayerMotor.GROUND)
