class_name ArcherBrain
extends EnemyBrain
## Goblin archer (behaviour "archer"): strolls about near home. Once it notices the hero it
## keeps its distance (backs off inside NEAR, closes in beyond FAR), sidesteps to line up with
## them along a row or column, then stops and draws its bow for DRAW_TIME (its tell) before
## shooting along that line. Then it waits out its cooldown. The arrow's damage and speed are
## the node's business (the "shot" data).

const NEAR: float = 40.0
const FAR: float = 88.0
## How close (px) to the hero's row or column counts as lined up.
const ALIGN: float = 6.0
const DRAW_TIME: float = 0.5
const IDLE_TIME: Vector2 = Vector2(0.6, 1.5)
const STROLL_TIME: Vector2 = Vector2(0.5, 1.2)

var cooldown: float = 1.6

var _cooldown_left: float = 0.0
var _stroll: Vector2 = Vector2.ZERO


func _init(grid_body: GridBody, data: Dictionary, random: RandomNumberGenerator) -> void:
	super(grid_body, data, random)
	var shot_data: Variant = data.get("shot", {})
	if typeof(shot_data) == TYPE_DICTIONARY:
		cooldown = float((shot_data as Dictionary).get("cooldown", cooldown))


## True while it stands drawing its bow, about to shoot.
func is_drawing() -> bool:
	return state == ATTACK


func step(hero: Vector2, delta: float) -> void:
	_cooldown_left -= delta
	super(hero, delta)


func _enter_state(next: StringName) -> void:
	match next:
		IDLE:
			_timer = rng.randf_range(IDLE_TIME.x, IDLE_TIME.y)
		WANDER:
			_stroll = wander_direction()
			_timer = rng.randf_range(STROLL_TIME.x, STROLL_TIME.y)
		ATTACK:
			_timer = DRAW_TIME


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
			else:
				move(_stroll, delta)
				if _timer <= 0.0:
					change_state(IDLE)
		CHASE:
			if has_lost(hero):
				change_state(IDLE)
				return
			var offset: Vector2 = hero - body.position
			var lined_up: bool = absf(offset.x) <= ALIGN or absf(offset.y) <= ALIGN
			var way: Vector2 = Vector2.ZERO
			if offset.length() < NEAR:
				way = -offset.normalized()
			elif offset.length() > FAR:
				way = offset.normalized()
			if not lined_up:
				# Sidestep along the shorter axis to get in line.
				if absf(offset.x) < absf(offset.y):
					way.x += signf(offset.x)
				else:
					way.y += signf(offset.y)
			if not way.is_zero_approx():
				move(way.normalized(), delta)
			facing = cardinal(offset)
			# Shoots only from a distance: too close, it backs off first.
			var in_range: bool = offset.length() >= NEAR and offset.length() <= FAR + GridBody.TILE
			if lined_up and in_range and _cooldown_left <= 0.0:
				change_state(ATTACK)
		ATTACK:
			facing = cardinal(hero - body.position) if _timer > DRAW_TIME / 2.0 else facing
			if _timer <= 0.0:
				shot.emit(facing)
				_cooldown_left = cooldown
				change_state(CHASE)
