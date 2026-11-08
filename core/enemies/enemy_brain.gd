class_name EnemyBrain
extends RefCounted
## How an enemy acts (docs/TECH_DESIGN.md §5): a small state machine (idle, wander, chase,
## attack, hurt, dead) moving a GridBody, set up from the enemy's data (health, speed, sight).
## Pure: call step() every frame with the hero's position, and take_hit() when a blow lands.
## Randomness comes from the RandomNumberGenerator given, so tests can seed it. One subclass
## per behaviour id (EnemyBrains): HopperBrain, ArcherBrain, FlierBrain. Subclasses fill in
## _enter_state() and _think(); hurt and dead work the same for every enemy.

signal state_changed(state: StringName)
## An archer looses an arrow along `direction`.
signal shot(direction: Vector2)

const IDLE: StringName = &"idle"
const WANDER: StringName = &"wander"
const CHASE: StringName = &"chase"
const ATTACK: StringName = &"attack"
const HURT: StringName = &"hurt"
const DEAD: StringName = &"dead"

## How long a hit stuns it (it can't be hit again meanwhile), and how fast it's pushed.
const HURT_TIME: float = 0.3
const KNOCKBACK_SPEED: float = 160.0
## It follows the hero this many times its sight before giving up.
const LOSE_FACTOR: float = 1.6
## Wandering keeps it within this distance (px) of where it started.
const LEASH: float = 48.0
const CARDINALS: Array[Vector2] = [Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT, Vector2.UP]

var body: GridBody
var rng: RandomNumberGenerator
var health: int = 1
var max_health: int = 1
var speed: float = 30.0
var sight: float = 64.0
var facing: Vector2 = Vector2.DOWN
## Where it started: wandering stays near here.
var home: Vector2 = Vector2.ZERO
var state: StringName = &""

## Counts down in every state; subclasses use it for pauses and durations.
var _timer: float = 0.0
var _push: Vector2 = Vector2.ZERO
var _push_left: float = 0.0


func _init(grid_body: GridBody, data: Dictionary, random: RandomNumberGenerator) -> void:
	body = grid_body
	# Enemies keep to their level: no hopping down ledges after the hero.
	body.allow_drops = false
	rng = random
	max_health = maxi(int(data.get("health", 1)), 1)
	health = max_health
	speed = float(data.get("speed", 30.0))
	sight = float(data.get("sight", 64.0))
	home = body.position


## Begins thinking, idle. Call once after creating it.
func start() -> void:
	change_state(IDLE)


func is_dead() -> bool:
	return state == DEAD


func distance_to(point: Vector2) -> float:
	return body.position.distance_to(point)


func notices(hero: Vector2) -> bool:
	return distance_to(hero) <= sight


func has_lost(hero: Vector2) -> bool:
	return distance_to(hero) > sight * LOSE_FACTOR


func step(hero: Vector2, delta: float) -> void:
	_timer -= delta
	match state:
		DEAD:
			return
		HURT:
			_step_hurt(delta)
		_:
			_think(hero, delta)


## A blow lands: `damage` off its health, knocked back by `push` (direction times px).
## Ignored while already stunned or dead. Returns whether the blow landed.
func take_hit(damage: int, push: Vector2) -> bool:
	if state == HURT or state == DEAD:
		return false
	health = maxi(health - damage, 0)
	if health == 0:
		change_state(DEAD)
		return true
	_push = push.normalized()
	_push_left = push.length()
	change_state(HURT)
	_timer = HURT_TIME
	return true


func change_state(next: StringName) -> void:
	state = next
	_enter_state(next)
	state_changed.emit(next)


## Walks along `direction` at its speed for `delta` seconds, facing that way. Returns the
## distance covered (less than asked when something is in the way).
func move(direction: Vector2, delta: float, speed_factor: float = 1.0) -> float:
	if direction.is_zero_approx():
		return 0.0
	facing = direction.normalized()
	return body.walk(facing, speed * speed_factor * delta)


func toward(point: Vector2) -> Vector2:
	var offset: Vector2 = point - body.position
	return offset.normalized() if not offset.is_zero_approx() else Vector2.ZERO


## A random one of the four directions, or back toward home once it has strayed past LEASH.
func wander_direction() -> Vector2:
	if body.position.distance_to(home) > LEASH:
		return toward(home)
	return CARDINALS[rng.randi_range(0, CARDINALS.size() - 1)]


## The one of the four directions closest to `offset` (along its longer axis).
static func cardinal(offset: Vector2) -> Vector2:
	if offset.is_zero_approx():
		return Vector2.DOWN
	if absf(offset.x) >= absf(offset.y):
		return Vector2(signf(offset.x), 0.0)
	return Vector2(0.0, signf(offset.y))


## Set timers and the like for a state just entered (subclasses).
func _enter_state(_next: StringName) -> void:
	pass


## Idle, wander, chase and attack (subclasses).
func _think(_hero: Vector2, _delta: float) -> void:
	pass


func _step_hurt(delta: float) -> void:
	var distance: float = minf(_push_left, KNOCKBACK_SPEED * delta)
	if distance > 0.0:
		body.walk(_push, distance)
		_push_left -= distance
	if _timer <= 0.0 and _push_left <= 0.0:
		change_state(CHASE)
