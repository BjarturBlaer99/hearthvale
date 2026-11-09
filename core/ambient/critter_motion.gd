class_name CritterMotion
extends RefCounted
## How a critter moves (docs/TECH_DESIGN.md §15), pure.
## - A WALKER (a chicken) stands or pecks a while, then walks to a spot near home. It walks by the
##   terrain rules (a GridBody that never drops off ledges), so it never enters a solid or occupied
##   cell, and gives up on a walk that gets stuck.
## - A FLIER (a butterfly, a firefly) drifts toward a wandering point near home, over anything.
## Neither ever strays far from home. Random numbers come from the RandomNumberGenerator given.

const WALKER: StringName = &"walker"
const FLIER: StringName = &"flier"
const IDLE: StringName = &"idle"
const PECK: StringName = &"peck"
const WALK: StringName = &"walk"
## A walk that covers less than this (px/s) is stuck, and ends.
const STUCK_SPEED: float = 2.0

var style: StringName = WALKER
var position: Vector2 = Vector2.ZERO
var home: Vector2 = Vector2.ZERO
var radius: float = 32.0
var speed: float = 16.0
var state: StringName = IDLE
## -1 facing left, 1 facing right.
var facing_x: float = -1.0

var _rng: RandomNumberGenerator
var _body: GridBody
var _target: Vector2 = Vector2.ZERO
var _timer: float = 0.0
var _velocity: Vector2 = Vector2.ZERO


## A critter at `start` (its home), wandering within `radius` px at `speed` px/s. Walkers need
## `terrain`; fliers ignore it.
func _init(motion_style: StringName, start: Vector2, wander_radius: float, move_speed: float,
		rng: RandomNumberGenerator, terrain: TerrainQuery = null) -> void:
	style = motion_style
	home = start
	position = start
	radius = wander_radius
	speed = move_speed
	_rng = rng
	_target = start
	_timer = _rng.randf_range(0.2, 1.5)
	if style == WALKER and terrain != null:
		_body = GridBody.new(terrain)
		_body.allow_drops = false
		_body.place(GridBody.cell_of(start))
		_body.position = start
		position = start


func step(delta: float) -> void:
	_timer -= delta
	if style == FLIER:
		_drift(delta)
	else:
		_wander(delta)


func _wander(delta: float) -> void:
	match state:
		IDLE, PECK:
			if _timer <= 0.0:
				_target = home + Vector2(_rng.randf_range(-radius, radius), _rng.randf_range(-radius, radius)) * 0.8
				state = WALK
				_timer = 3.0
		WALK:
			var offset: Vector2 = _target - position
			if offset.length() < 2.0 or _timer <= 0.0:
				_rest()
				return
			var direction: Vector2 = offset.normalized()
			facing_x = signf(direction.x) if absf(direction.x) > 0.1 else facing_x
			var moved: float = speed * delta
			if _body != null:
				moved = _body.walk(direction, speed * delta)
				position = _body.position
			else:
				position += direction * moved
			if moved < STUCK_SPEED * delta:
				_rest()


func _rest() -> void:
	state = PECK if _rng.randf() < 0.4 else IDLE
	_timer = _rng.randf_range(0.8, 2.6)


func _drift(delta: float) -> void:
	if _timer <= 0.0 or position.distance_to(_target) < 3.0:
		_target = home + Vector2.from_angle(_rng.randf() * TAU) * _rng.randf_range(0.0, radius)
		_timer = _rng.randf_range(0.8, 1.8)
	var wanted: Vector2 = (_target - position).normalized() * speed
	_velocity = _velocity.lerp(wanted, minf(1.0, delta * 3.0))
	position += _velocity * delta
	if absf(_velocity.x) > 1.0:
		facing_x = signf(_velocity.x)
	state = WALK
