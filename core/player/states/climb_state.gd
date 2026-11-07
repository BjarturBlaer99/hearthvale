class_name PlayerClimbState
extends PlayerState
## On a climbable face. Push toward it to climb, away from it to climb down; letting go at
## the bottom puts you back on your feet. Stamina drains every second on the wall, moving
## or not, and running dry drops you back where you started (damaging from 3 levels).

const PUSH_THRESHOLD: float = 0.3

var target: Vector2i
## Unit axis vector from the start cell toward the wall.
var axis: Vector2
var rise: int = 1
## Levels climbed so far.
var progress: float = 0.0


func enter(motor: PlayerMotor, data: Dictionary) -> void:
	target = data["target"]
	axis = data["direction"]
	rise = maxi(1, motor.terrain.standing_level(target, motor.water_height) - motor.level)
	progress = 0.0


func fraction() -> float:
	return clampf(progress / float(rise), 0.0, 1.0)


func step(motor: PlayerMotor, direction: Vector2, _sprint: bool, delta: float) -> void:
	motor.drain_stamina(PlayerMotor.CLIMB_DRAIN * delta)
	var push: float = direction.dot(axis)
	if push > PUSH_THRESHOLD:
		progress += PlayerMotor.CLIMB_SPEED * delta
	elif push < -PUSH_THRESHOLD:
		progress -= PlayerMotor.CLIMB_SPEED * delta

	if progress >= rise:
		motor.finish_climb(target, axis)
	elif progress <= 0.0:
		motor.change_state(PlayerMotor.GROUND)
		motor.settle()
	elif motor.stamina <= 0.0:
		var drop: int = floori(progress)
		var into_water: bool = motor.terrain.cell_kind(motor.cell, motor.water_height) == TerrainQuery.CellKind.DEEP
		motor.change_state(PlayerMotor.GROUND)
		motor.settle()
		if drop > 0:
			motor.fell.emit(drop, drop >= TerrainQuery.DAMAGING_DROP and not into_water)
