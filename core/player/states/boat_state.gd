class_name PlayerBoatState
extends PlayerState
## Aboard the boat. The player doesn't walk: movement input steers the boat instead
## (BoatController), and PlayerMotor.ride() keeps the player on it. Resting aboard
## recovers stamina.


func step(motor: PlayerMotor, _direction: Vector2, _sprint: bool, delta: float) -> void:
	motor.regen_stamina(delta)
