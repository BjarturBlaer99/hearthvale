class_name PlayerAttackState
extends PlayerState
## Swinging the sword: the hero stands still, facing the swing, for the weapon's cooldown, then
## is back on their feet. Data: { "direction": Vector2i, "time": seconds, "blow": 0 to 1 or -1 }.
## A stroke with a blow has the motor emit `struck` once: when it is that far through, or when
## it ends before (a hit, a fall), so whatever waits on the blow is never left waiting.

var direction: Vector2i = Vector2i.DOWN
var duration: float = 0.3

var blow: float = -1.0

var _left: float = 0.0
var _struck: bool = false


func enter(_motor: PlayerMotor, data: Dictionary) -> void:
	direction = data.get("direction", Vector2i.DOWN)
	duration = maxf(float(data.get("time", 0.3)), 0.01)
	blow = float(data.get("blow", -1.0))
	_left = duration
	_struck = false


func exit(motor: PlayerMotor) -> void:
	_strike(motor)


func step(motor: PlayerMotor, _direction: Vector2, delta: float) -> void:
	_left -= delta
	if blow >= 0.0 and progress() >= blow:
		_strike(motor)
	if _left <= 0.0:
		motor.change_state(PlayerMotor.GROUND)


func _strike(motor: PlayerMotor) -> void:
	if blow < 0.0 or _struck:
		return
	_struck = true
	motor.struck.emit()


## How far through the swing the hero is, 0 to 1.
func progress() -> float:
	return clampf(1.0 - _left / duration, 0.0, 1.0)
