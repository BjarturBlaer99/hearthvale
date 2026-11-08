class_name WardenBrain
extends EnemyBrain
## The Iron Warden, the keep's boss (behaviour "warden", docs/TECH_DESIGN.md §5): a suit of iron
## with one eye in its visor.
## - Idle until the hero comes within sight (or strikes it).
## - Guard: stomps toward the hero. Every blow clinks off its iron.
## - Gaze: stands and opens its eye (the tell). Only a `weak_point` hit (an arrow) counts: it
##   stuns the warden. A gaze nobody answers ends in a bolt at the hero.
## - Stunned: slumped. Only now do blows hurt (any kind), each followed by a FLINCH_TIME flinch,
##   so one stun is worth a few blows, not a flurry.
## - Raging, at `rage_at` health or less: stomps faster, guards for less long, fires three bolts.
## It keeps inside `arena` (area pixels; empty: anywhere), and reset() starts the fight over.
## Timings come from the enemy data's "boss" object.

## It was struck while it couldn't be hurt (the blow clinked off).
signal clinked
## An arrow found its eye.
signal stunned

const GUARD: StringName = &"guard"
const GAZE: StringName = &"gaze"
const STUNNED: StringName = &"stunned"
## How long its eye takes to open, at the start of a gaze.
const EYE_OPENING: float = 0.35
## A rage's side bolts fly this far (radians) either side of the middle one.
const SPREAD: float = 0.45
## Raging, it guards for this share of the usual time.
const RAGE_GUARD: float = 0.7
## After a blow lands on it stunned, further blows are ignored this long.
const FLINCH_TIME: float = 0.4

var guard_time: float = 3.0
var gaze_time: float = 1.6
var stun_time: float = 2.5
var rage_at: int = 0
var rage_speed: float = 1.5
var weak_point: StringName = &"arrow"
## Where it may go (area pixels): its room's floor, less its bulk. Empty: anywhere.
var arena: Rect2 = Rect2()

var _flinch: float = 0.0
var _gaze_length: float = 1.0


func _init(grid_body: GridBody, data: Dictionary, random: RandomNumberGenerator) -> void:
	super(grid_body, data, random)
	var boss: Dictionary = data.get("boss", {})
	guard_time = float(boss.get("guard_time", guard_time))
	gaze_time = float(boss.get("gaze_time", gaze_time))
	stun_time = float(boss.get("stun_time", stun_time))
	rage_at = int(boss.get("rage_at", max_health / 2))
	rage_speed = float(boss.get("rage_speed", rage_speed))
	weak_point = StringName(str(boss.get("weak_point", weak_point)))


func is_raging() -> bool:
	return state != DEAD and health <= rage_at


func is_stunned() -> bool:
	return state == STUNNED


## How open its eye is, 0 to 1: it opens at the start of a gaze and shuts after.
func eye_open() -> float:
	if state != GAZE:
		return 0.0
	return clampf((_gaze_length - _timer) / EYE_OPENING, 0.0, 1.0)


## Back to the start: full health, home, idle (the hero left its room).
func reset() -> void:
	health = max_health
	_flinch = 0.0
	facing = Vector2.DOWN
	body.place(GridBody.cell_of(home))
	change_state(IDLE)


## A blow lands only on the eye while it gazes (an arrow stuns it) or anywhere while stunned
## (it hurts); anything else clinks. Returns whether it counted.
func take_hit(damage: int, _push: Vector2, kind: StringName = &"contact") -> bool:
	match state:
		DEAD:
			return false
		GAZE:
			if kind == weak_point:
				change_state(STUNNED)
				return true
		STUNNED:
			if _flinch > 0.0:
				return false
			health = maxi(health - damage, 0)
			_flinch = FLINCH_TIME
			if health == 0:
				change_state(DEAD)
			return true
		IDLE:
			change_state(GUARD)
	clinked.emit()
	return false


## Walks like any enemy, but never out of its arena.
func move(direction: Vector2, delta: float, speed_factor: float = 1.0) -> float:
	if direction.is_zero_approx():
		return 0.0
	facing = direction.normalized()
	var distance: float = speed * speed_factor * delta
	if not arena.has_area():
		return body.walk(facing, distance)
	var goal: Vector2 = (body.position + facing * distance).clamp(arena.position, arena.end)
	var motion: Vector2 = goal - body.position
	if motion.length() < 0.001:
		return 0.0
	return body.walk(motion.normalized(), motion.length())


func _enter_state(next: StringName) -> void:
	match next:
		IDLE:
			_timer = 0.0
		GUARD:
			_timer = guard_time * (RAGE_GUARD if is_raging() else 1.0)
		GAZE:
			_gaze_length = gaze_time
			_timer = gaze_time
		STUNNED:
			_timer = stun_time
			_flinch = 0.0
			stunned.emit()


func _think(hero: Vector2, delta: float) -> void:
	match state:
		IDLE:
			if notices(hero):
				change_state(GUARD)
		GUARD:
			move(toward(hero), delta, rage_speed if is_raging() else 1.0)
			if _timer <= 0.0:
				change_state(GAZE)
		GAZE:
			var look: Vector2 = toward(hero)
			if not look.is_zero_approx():
				facing = look
			if _timer <= 0.0:
				_fire(hero)
				change_state(GUARD)
		STUNNED:
			_flinch = maxf(0.0, _flinch - delta)
			if _timer <= 0.0:
				change_state(GUARD)


## A bolt at the hero; raging, two more either side.
func _fire(hero: Vector2) -> void:
	var aim: Vector2 = toward(hero)
	if aim.is_zero_approx():
		aim = facing
	shot.emit(aim)
	if is_raging():
		shot.emit(aim.rotated(SPREAD))
		shot.emit(aim.rotated(-SPREAD))
