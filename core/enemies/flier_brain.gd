class_name FlierBrain
extends EnemyBrain
## Bat (behaviour "flier"): rests on its roost, now and then flits about near it. Once it
## notices the hero it flies at them in an erratic zigzag (a new heading every TURN seconds,
## pulled toward the hero but jittered), swoops straight in when close, and after FLIGHT_TIME
## gives up and flits home. Its GridBody flies: heights and ledges don't stop it, solid tiles do.

const TURN: Vector2 = Vector2(0.2, 0.45)
const JITTER: float = 1.1
const SWOOP_RANGE: float = 26.0
const SWOOP_TIME: float = 0.35
const SWOOP_SPEED: float = 1.7
const FLIGHT_TIME: float = 4.5
const REST_TIME: Vector2 = Vector2(1.5, 3.0)
const FLIT_TIME: Vector2 = Vector2(1.0, 2.0)

var _heading: Vector2 = Vector2.ZERO
var _turn_left: float = 0.0
var _flight_left: float = 0.0


func _init(grid_body: GridBody, data: Dictionary, random: RandomNumberGenerator) -> void:
	super(grid_body, data, random)
	body.flying = true


## Resting on its roost (wings folded).
func is_resting() -> bool:
	return state == IDLE


func _enter_state(next: StringName) -> void:
	_turn_left = 0.0
	match next:
		IDLE:
			_timer = rng.randf_range(REST_TIME.x, REST_TIME.y)
		WANDER:
			_timer = rng.randf_range(FLIT_TIME.x, FLIT_TIME.y)
		CHASE:
			if _flight_left <= 0.0:
				_flight_left = FLIGHT_TIME
		ATTACK:
			_timer = SWOOP_TIME


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
				return
			_zigzag(home if body.position.distance_to(home) > LEASH else body.position + wander_direction() * GridBody.TILE, delta)
			if _timer <= 0.0:
				change_state(IDLE)
		CHASE:
			_flight_left -= delta
			if has_lost(hero) or _flight_left <= 0.0:
				_flight_left = 0.0
				change_state(WANDER)
			elif distance_to(hero) <= SWOOP_RANGE:
				_heading = toward(hero)
				change_state(ATTACK)
			else:
				_zigzag(hero, delta)
		ATTACK:
			_flight_left -= delta
			move(_heading, delta, SWOOP_SPEED)
			if _timer <= 0.0:
				change_state(CHASE)


## Flies toward `target`, picking a new jittered heading every TURN seconds.
func _zigzag(target: Vector2, delta: float) -> void:
	_turn_left -= delta
	if _turn_left <= 0.0:
		_turn_left = rng.randf_range(TURN.x, TURN.y)
		var jitter: Vector2 = Vector2.RIGHT.rotated(rng.randf_range(0.0, TAU)) * JITTER
		_heading = (toward(target) + jitter).normalized()
	move(_heading, delta)
