class_name WispBrain
extends EnemyBrain
## Bogwisp (behaviour "wisp", Willowmere at night): a floating light. It hangs where it rose
## until it notices the hero, then drifts slowly toward him. Within reach it stops and flares
## brighter for half a second (the tell), aiming where he stands as the flare begins; then it
## darts in a straight line along that aim, fast, and rests a moment before drifting again. A
## step aside while it flares takes him out of the dart's way.
##
## It has no body until light reaches it: unlit, a blow passes through it (take_hit refuses,
## as the Warden's armour does). The enemy that owns the brain says each frame whether it is
## `lit` (LightRules, the light the crypt uses). Its touch still hurts in the dark.
##
## When the night ends it fades (fade()) and is gone, leaving nothing: not beaten, so no drop.
## Its GridBody drifts: water, reeds and walls don't stop it, only the map's edge.
##
## The numbers are data (the enemy's "wisp": { "reach", "flare", "dart_speed", "dart_time",
## "rest" }), with these to fall back on.

const FLARE: StringName = &"flare"
const DART: StringName = &"dart"
const REST: StringName = &"rest"
const GONE: StringName = &"gone"

const DEFAULTS: Dictionary = {"reach": 52.0, "flare": 0.5, "dart_speed": 150.0, "dart_time": 0.5, "rest": 1.3}

## How near the hero must be (px) for it to stop and flare.
var reach: float
## How long the flare lasts (s): the tell.
var flare_time: float
## How fast it darts (px/s) and for how long (s).
var dart_speed: float
var dart_time: float
## How long it hangs still after a dart (s).
var rest_time: float
## The way it darts: fixed as the flare begins.
var aim: Vector2 = Vector2.ZERO
## Whether light reaches it right now (LightRules; the enemy that owns the brain says so each
## frame, as the Shade's boss does for its hall). Dark until told: a light with nothing to it.
var lit: bool = false


func _init(grid_body: GridBody, data: Dictionary, random: RandomNumberGenerator) -> void:
	super(grid_body, data, random)
	body.flying = true
	body.drifting = true
	var numbers: Dictionary = data.get("wisp", {}) if typeof(data.get("wisp")) == TYPE_DICTIONARY else {}
	reach = float(numbers.get("reach", DEFAULTS["reach"]))
	flare_time = float(numbers.get("flare", DEFAULTS["flare"]))
	dart_speed = float(numbers.get("dart_speed", DEFAULTS["dart_speed"]))
	dart_time = float(numbers.get("dart_time", DEFAULTS["dart_time"]))
	rest_time = float(numbers.get("rest", DEFAULTS["rest"]))


## Flaring: the half second before a dart, brighter and still.
func is_flaring() -> bool:
	return state == FLARE


func is_darting() -> bool:
	return state == DART


## Faded with the night: gone for good, with nothing left behind.
func is_gone() -> bool:
	return state == GONE


## Whether a blow would land on it now: only where light reaches it.
func is_solid() -> bool:
	return lit and state != DEAD and state != GONE


## The night is over: it fades where it hangs. Not a death: nothing drops.
func fade() -> void:
	if state != DEAD and state != GONE:
		change_state(GONE)


## Unlit, a blow passes through it. Lit, it takes blows like anything else.
func take_hit(damage: int, push: Vector2, kind: StringName = &"contact") -> bool:
	if not is_solid():
		return false
	return super(damage, push, kind)


func step(hero: Vector2, delta: float) -> void:
	if state == GONE:
		return
	super(hero, delta)


func _enter_state(next: StringName) -> void:
	match next:
		FLARE:
			_timer = flare_time
		DART:
			_timer = dart_time
		REST:
			_timer = rest_time


func _think(hero: Vector2, delta: float) -> void:
	match state:
		IDLE:
			if notices(hero):
				change_state(CHASE)
		CHASE:
			if has_lost(hero):
				change_state(WANDER)
			elif distance_to(hero) <= reach:
				aim = toward(hero)
				if aim == Vector2.ZERO:
					aim = Vector2.DOWN
				change_state(FLARE)
			else:
				move(toward(hero), delta)
		WANDER:
			# Back to where it rose, unless he comes near again.
			if notices(hero):
				change_state(CHASE)
			elif body.position.distance_to(home) <= 2.0:
				change_state(IDLE)
			else:
				move(toward(home), delta)
		FLARE:
			facing = aim
			if _timer <= 0.0:
				change_state(DART)
		DART:
			facing = aim
			body.walk(aim, dart_speed * delta)
			if _timer <= 0.0:
				change_state(REST)
		REST:
			if _timer <= 0.0:
				change_state(CHASE)
