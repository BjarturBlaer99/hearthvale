class_name ShadeBrain
extends EnemyBrain
## The Crypt Shade, the crypt's boss (behaviour "shade", docs/TECH_DESIGN.md §5): a thing of the
## dark that only light can hold.
## - Idle until the hero comes within sight (or strikes at it).
## - Haunting: drifts after the hero, over pits and all. Blows pass through it; its touch hurts.
## - Bound: when its hall is lit (set_lit(): every brazier burning) the light holds it for
##   `bound_time`. It can't move, and only now do blows hurt, each followed by a FLINCH_TIME
##   flinch, so one binding is worth a few blows, not a flurry.
## - Then it snuffs the lights (`snuffed`) and haunts again.
## - Raging, at `rage_at` health or less: faster, with a bolt at the hero every `bolt_every` s.
## It keeps inside `arena` (area pixels; empty: anywhere), and reset() starts the fight over.
## Timings come from the enemy data's "boss" object.

## A blow went through it.
signal passed
## The light caught it.
signal bound
## Its binding ended: it puts the lights out.
signal snuffed

const HAUNT: StringName = &"haunt"
const BOUND: StringName = &"bound"
## After a blow lands on it bound, further blows are ignored this long.
const FLINCH_TIME: float = 0.6

var bound_time: float = 3.0
var rage_at: int = 0
var rage_speed: float = 1.4
var bolt_every: float = 2.6
## Where it may go (area pixels): its room's floor, less its bulk. Empty: anywhere.
var arena: Rect2 = Rect2()
## Whether its hall is lit right now (the boss node says, every frame).
var lit: bool = false

var _flinch: float = 0.0
var _bolt_left: float = 0.0


func _init(grid_body: GridBody, data: Dictionary, random: RandomNumberGenerator) -> void:
	super(grid_body, data, random)
	body.flying = true
	var boss: Dictionary = data.get("boss", {})
	bound_time = float(boss.get("bound_time", bound_time))
	@warning_ignore("integer_division")
	rage_at = int(boss.get("rage_at", max_health / 2))
	rage_speed = float(boss.get("rage_speed", rage_speed))
	bolt_every = float(boss.get("bolt_every", bolt_every))


func set_lit(value: bool) -> void:
	lit = value


func is_raging() -> bool:
	return state != DEAD and health <= rage_at


func is_bound() -> bool:
	return state == BOUND


## Back to the start: full health, home, idle (the hero left its hall).
func reset() -> void:
	health = max_health
	_flinch = 0.0
	lit = false
	facing = Vector2.DOWN
	body.place(GridBody.cell_of(home))
	change_state(IDLE)


## A blow lands only while the light binds it; otherwise it passes through. Returns whether it
## counted.
func take_hit(damage: int, _push: Vector2, _kind: StringName = &"contact") -> bool:
	match state:
		DEAD:
			return false
		BOUND:
			if _flinch > 0.0:
				return false
			health = maxi(health - damage, 0)
			_flinch = FLINCH_TIME
			if health == 0:
				change_state(DEAD)
			return true
		IDLE:
			change_state(HAUNT)
	passed.emit()
	return false


## Drifts like any flier, but never out of its arena.
func move(direction: Vector2, delta: float, speed_factor: float = 1.0) -> float:
	return move_inside(arena, direction, delta, speed_factor)


func _enter_state(next: StringName) -> void:
	match next:
		IDLE:
			_timer = 0.0
		HAUNT:
			_bolt_left = bolt_every
		BOUND:
			_timer = bound_time
			_flinch = 0.0
			bound.emit()


func _think(hero: Vector2, delta: float) -> void:
	match state:
		IDLE:
			if notices(hero):
				change_state(HAUNT)
		HAUNT:
			if lit:
				change_state(BOUND)
				return
			move(toward(hero), delta, rage_speed if is_raging() else 1.0)
			if is_raging():
				_bolt_left -= delta
				if _bolt_left <= 0.0:
					_bolt_left = bolt_every
					var aim: Vector2 = toward(hero)
					shot.emit(aim if not aim.is_zero_approx() else facing)
		BOUND:
			_flinch = maxf(0.0, _flinch - delta)
			if _timer <= 0.0 or not lit:
				lit = false
				snuffed.emit()
				change_state(HAUNT)
