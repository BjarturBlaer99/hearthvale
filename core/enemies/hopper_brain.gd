class_name HopperBrain
extends EnemyBrain
## Slime (behaviour "hopper"): moves in hops with a rest between them. It sits, hops about
## near home, and once it notices the hero hops after them, lunging with a long fast hop when
## close (touching is its attack). It gives up when they get far enough away.

const HOP_TIME: float = 0.35
const WANDER_REST: Vector2 = Vector2(0.6, 1.3)
const CHASE_REST: float = 0.35
const LUNGE_RANGE: float = 30.0
const LUNGE_SPEED: float = 2.2

var _hop: Vector2 = Vector2.ZERO
var _hop_left: float = 0.0


## How far through the current hop, 0 to 1; -1 when resting (for the squash-and-stretch).
func hop_phase() -> float:
	return 1.0 - _hop_left / HOP_TIME if _hop_left > 0.0 else -1.0


func _enter_state(next: StringName) -> void:
	_hop_left = 0.0
	match next:
		IDLE:
			_timer = rng.randf_range(WANDER_REST.x, WANDER_REST.y)
		WANDER:
			_start_hop(wander_direction())
		CHASE:
			_timer = CHASE_REST


func _think(hero: Vector2, delta: float) -> void:
	match state:
		IDLE:
			if notices(hero):
				change_state(CHASE)
			elif _timer <= 0.0:
				change_state(WANDER)
		WANDER:
			if notices(hero):
				change_state(CHASE)
			elif _continue_hop(delta, 1.0):
				change_state(IDLE)
		CHASE:
			if _hop_left > 0.0:
				if _continue_hop(delta, 1.0):
					_timer = CHASE_REST
			elif has_lost(hero):
				change_state(IDLE)
			elif _timer <= 0.0:
				if distance_to(hero) <= LUNGE_RANGE:
					change_state(ATTACK)
					_start_hop(toward(hero))
				else:
					_start_hop(snap_to_8_toward(hero))
		ATTACK:
			if _continue_hop(delta, LUNGE_SPEED):
				change_state(CHASE)


func snap_to_8_toward(point: Vector2) -> Vector2:
	return GridBody.snap_to_8(toward(point))


func _start_hop(direction: Vector2) -> void:
	_hop = direction
	_hop_left = HOP_TIME
	if not direction.is_zero_approx():
		facing = direction


## Moves through the hop; returns true when it has landed.
func _continue_hop(delta: float, speed_factor: float) -> bool:
	var spent: float = minf(delta, _hop_left)
	move(_hop, spent, speed_factor)
	_hop_left -= spent
	return _hop_left <= 0.0
