class_name PlayerMotor
extends GridBody
## The hero's movement and states (docs/TECH_DESIGN.md §3, §4). Pure: on top of GridBody's
## grid-checked walking (the hero may hop down ledges), it owns the facing and a small state
## machine, one script per state: ground, attack, hurt, dead. After a hit the hero is
## invincible for INVINCIBLE_TIME. PlayerController feeds it input every physics frame and
## draws it. Call place() before the first step().

signal state_changed(state_name: StringName)
## A stroke given a blow (attack()'s `blow`) has come to it, or ended before it: once a stroke.
## For show only (tool polish): what the stroke does was done when it began.
signal struck

const WALK_SPEED: float = 72.0
## Holding sprint. (Whether he may, and what it costs, are the energy rules': the controller
## sets `sprinting` and `speed_scale`.)
const SPRINT_SPEED: float = 120.0
## How fast a hit pushes the hero back (px/s), and how long they can't be hurt again after.
const KNOCKBACK_SPEED: float = 160.0
const INVINCIBLE_TIME: float = 1.0

const GROUND: StringName = &"ground"
const ATTACK: StringName = &"attack"
const HURT: StringName = &"hurt"
const DEAD: StringName = &"dead"

## Last non-zero movement direction.
var facing: Vector2 = Vector2.DOWN
## Whether the hero is sprinting (the controller sets it every frame: sprint held, and the
## energy for it). Only walking goes faster.
var sprinting: bool = false
## The share of his speed he walks and runs at: 1, or less when he is tired (EnergyRules).
var speed_scale: float = 1.0
## The direction input held on the last step (snapped to 8 ways; zero when none).
var held: Vector2 = Vector2.ZERO
var state: PlayerState
var state_name: StringName = &""
## Seconds of invincibility left after a hit.
var invincible_left: float = 0.0

var _states: Dictionary[StringName, PlayerState] = {}


func _init(terrain_query: TerrainQuery = null) -> void:
	super(terrain_query)
	allow_drops = true
	_states = {
		GROUND: PlayerGroundState.new(),
		ATTACK: PlayerAttackState.new(),
		HURT: PlayerHurtState.new(),
		DEAD: PlayerDeadState.new(),
	}


## How fast the hero walks right now (px/s).
func walk_speed() -> float:
	return (SPRINT_SPEED if sprinting else WALK_SPEED) * speed_scale


## Puts the hero in the middle of `at_cell`, standing.
func place(at_cell: Vector2i) -> void:
	super(at_cell)
	invincible_left = 0.0
	state_name = &""
	change_state(GROUND)


func step(input: Vector2, delta: float) -> void:
	invincible_left = maxf(0.0, invincible_left - delta)
	var direction: Vector2 = snap_to_8(input)
	held = direction
	# Only on foot does input turn the hero; a swing or a knockback keeps their facing.
	if direction != Vector2.ZERO and state_name == GROUND:
		facing = direction
	state.step(self, direction, delta)


## Starts a sword swing toward `direction` lasting `duration` s. Only on foot; returns whether
## the swing started.
## `blow` (0 to 1, or -1 for none) is how far through the stroke `struck` is emitted; it doesn't
## change how long the stroke lasts.
func attack(direction: Vector2i, duration: float, blow: float = -1.0) -> bool:
	if state_name != GROUND:
		return false
	change_state(ATTACK, {"direction": direction, "time": duration, "blow": blow})
	return true


func is_attacking() -> bool:
	return state_name == ATTACK


func is_invincible() -> bool:
	return invincible_left > 0.0


## A hit lands: knocked back by `push` (direction times px) and invincible for a while.
## Ignored while invincible or down. Returns whether the hit landed.
func take_hit(push: Vector2) -> bool:
	if is_invincible() or state_name == DEAD:
		return false
	invincible_left = INVINCIBLE_TIME
	change_state(HURT, {"push": push})
	return true


## Out of hearts: lies still until place() brings the hero back.
func die() -> void:
	change_state(DEAD)


func change_state(next: StringName, data: Dictionary = {}) -> void:
	if next == state_name and data.is_empty():
		return
	if state != null:
		state.exit(self)
	state_name = next
	state = _states[next]
	state.enter(self, data)
	state_changed.emit(next)
