class_name PlayerAttackState
extends PlayerState
## Swinging the sword: the hero stands still, facing the swing, for the weapon's cooldown, then
## is back on their feet. Data: { "direction": Vector2i, "time": seconds }.

var direction: Vector2i = Vector2i.DOWN
var duration: float = 0.3

var _left: float = 0.0


func enter(_motor: PlayerMotor, data: Dictionary) -> void:
	direction = data.get("direction", Vector2i.DOWN)
	duration = maxf(float(data.get("time", 0.3)), 0.01)
	_left = duration


func step(motor: PlayerMotor, _direction: Vector2, delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		motor.change_state(PlayerMotor.GROUND)


## How far through the swing the hero is, 0 to 1.
func progress() -> float:
	return clampf(1.0 - _left / duration, 0.0, 1.0)
