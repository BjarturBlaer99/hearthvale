class_name PlayerMotor
extends RefCounted
## Grid-checked top-down movement for the player (docs/TECH_DESIGN.md §3.4, §4). Pure: it
## owns position, level, stamina and the state machine (ground / swim / climb, one script
## each), and asks TerrainQuery before the player's leading edge enters a new cell.
## PlayerController feeds it input every physics frame and draws the result.
## Call place() before the first step().

signal state_changed(state_name: StringName)
signal cell_changed(cell: Vector2i)
## The player fell `levels` levels. `damaging` when onto ground from DAMAGING_DROP or more.
signal fell(levels: int, damaging: bool)

const TILE: float = 16.0
const WALK_SPEED: float = 72.0
const SPRINT_MULTIPLIER: float = 1.6
const SWIM_SPEED: float = 44.0
## Levels climbed per second while pushing into a climbable face.
const CLIMB_SPEED: float = 2.0
const STAMINA_MAX: float = 100.0
const SPRINT_DRAIN: float = 20.0
## Drained every second on a wall, moving or not.
const CLIMB_DRAIN: float = 18.0
const STAMINA_REGEN: float = 30.0
## After running dry, sprinting needs this much stamina back first.
const SPRINT_RECOVERY: float = 25.0
## How close (px) the player's centre may get to a cell it cannot enter.
const BODY_RADIUS: float = 4.0
## Longest single movement sub-step (px), so a long frame can never skip a cell.
const MAX_SUBSTEP: float = 4.0
## A climb starts only on a firm push; brushing a wall diagonally slides along it.
const CLIMB_PUSH: float = 0.9

const GROUND: StringName = &"ground"
const SWIM: StringName = &"swim"
const CLIMB: StringName = &"climb"

const DIRECTIONS: Array[Vector2] = [
	Vector2(1, 0), Vector2(0.70710678, 0.70710678), Vector2(0, 1), Vector2(-0.70710678, 0.70710678),
	Vector2(-1, 0), Vector2(-0.70710678, -0.70710678), Vector2(0, -1), Vector2(0.70710678, -0.70710678),
]

var terrain: TerrainQuery
var water_height: int = 0
## Feet position, in district pixels.
var position: Vector2 = Vector2.ZERO
var cell: Vector2i = Vector2i.ZERO
## The level the player stands or swims at (the climb's starting level while climbing).
var level: int = 0
var stamina: float = STAMINA_MAX
## True once stamina runs out, until it recovers to SPRINT_RECOVERY.
var exhausted: bool = false
var sprinting: bool = false
## Last non-zero movement direction.
var facing: Vector2 = Vector2.DOWN
var state: PlayerState
var state_name: StringName = &""

var _states: Dictionary[StringName, PlayerState] = {}


func _init(terrain_query: TerrainQuery = null, current_water_height: int = 0) -> void:
	terrain = terrain_query
	water_height = current_water_height
	_states = {GROUND: PlayerGroundState.new(), SWIM: PlayerSwimState.new(), CLIMB: PlayerClimbState.new()}


static func cell_of(point: Vector2) -> Vector2i:
	return Vector2i(floori(point.x / TILE), floori(point.y / TILE))


static func cell_center(at_cell: Vector2i) -> Vector2:
	return (Vector2(at_cell) + Vector2(0.5, 0.5)) * TILE


## Snaps stick or key input to one of 8 unit directions (equal speed diagonally).
static func snap_to_8(input: Vector2) -> Vector2:
	if input.length() < 0.2:
		return Vector2.ZERO
	return DIRECTIONS[wrapi(roundi(input.angle() / (PI / 4.0)), 0, 8)]


## Puts the player in the middle of `at_cell`, on foot or swimming as the water decides.
func place(at_cell: Vector2i) -> void:
	position = cell_center(at_cell)
	cell = at_cell
	state_name = &""
	settle()


func step(input: Vector2, sprint: bool, delta: float) -> void:
	var direction: Vector2 = snap_to_8(input)
	if direction != Vector2.ZERO:
		facing = direction
	state.step(self, direction, sprint, delta)


## The district's water moved. A climb is abandoned; ground vs swim follows the new water.
func set_water_height(height: int) -> void:
	water_height = height
	if state_name == CLIMB:
		change_state(GROUND)
	settle()


## Matches state and level to the cell underfoot: swim in deep water, ground otherwise.
func settle() -> void:
	if state_name == CLIMB:
		return
	level = terrain.standing_level(cell, water_height)
	var deep: bool = terrain.cell_kind(cell, water_height) == TerrainQuery.CellKind.DEEP
	change_state(SWIM if deep else GROUND)


func change_state(next: StringName, data: Dictionary = {}) -> void:
	if next == state_name and data.is_empty():
		return
	if state != null:
		state.exit(self)
	state_name = next
	state = _states[next]
	state.enter(self, data)
	state_changed.emit(next)


## 0..1 of the way up the current climb, or 0 when not climbing.
func climb_progress() -> float:
	return (state as PlayerClimbState).fraction() if state_name == CLIMB else 0.0


func speed_scale_here() -> float:
	if terrain.cell_kind(cell, water_height) == TerrainQuery.CellKind.SHALLOW:
		return TerrainQuery.SHALLOW_SPEED
	return 1.0


func can_sprint() -> bool:
	return not exhausted and stamina > 0.0


func drain_stamina(amount: float) -> void:
	stamina = maxf(0.0, stamina - amount)
	if stamina == 0.0:
		exhausted = true


func regen_stamina(delta: float) -> void:
	stamina = minf(STAMINA_MAX, stamina + STAMINA_REGEN * delta)
	if stamina >= SPRINT_RECOVERY:
		exhausted = false


## Moves up to `distance` px along unit `direction`, one axis at a time so walls slide.
func walk(direction: Vector2, distance: float) -> void:
	var remaining: float = distance
	while remaining > 0.0 and state_name != CLIMB:
		var chunk: float = minf(remaining, MAX_SUBSTEP)
		remaining -= chunk
		if direction.x != 0.0:
			_walk_axis(Vector2(direction.x * chunk, 0.0), direction)
		if direction.y != 0.0 and state_name != CLIMB:
			_walk_axis(Vector2(0.0, direction.y * chunk), direction)


## The climb reached the top: stand just inside the target cell.
func finish_climb(target: Vector2i, axis: Vector2) -> void:
	var boundary: Vector2 = cell_center(cell) + axis * (TILE * 0.5)
	var inside: Vector2 = boundary + axis * (BODY_RADIUS + 0.5)
	position = Vector2(position.x if axis.x == 0.0 else inside.x, position.y if axis.y == 0.0 else inside.y)
	cell = target
	cell_changed.emit(target)
	change_state(GROUND)
	settle()


func _walk_axis(motion: Vector2, direction: Vector2) -> void:
	var axis: Vector2 = motion.sign()
	var ahead: Vector2i = cell_of(position + motion + axis * BODY_RADIUS)
	if ahead != cell:
		var move: MoveResult = terrain.check_move(cell, ahead, water_height)
		if move.kind == MoveResult.Kind.CLIMB and absf(direction.dot(axis)) >= CLIMB_PUSH and stamina > 0.0:
			change_state(CLIMB, {"target": ahead, "direction": axis})
			return
		if move.kind == MoveResult.Kind.BLOCKED or move.kind == MoveResult.Kind.CLIMB:
			_stop_short(motion, axis)
			return
	position += motion
	var now: Vector2i = cell_of(position)
	if now != cell:
		_enter(now)


## Moves as far as allowed toward a cell that can't be entered: BODY_RADIUS short of its edge.
func _stop_short(motion: Vector2, axis: Vector2) -> void:
	var origin: Vector2 = Vector2(cell) * TILE
	if axis.x > 0.0:
		position.x = minf(position.x + motion.x, origin.x + TILE - BODY_RADIUS)
	elif axis.x < 0.0:
		position.x = maxf(position.x + motion.x, origin.x + BODY_RADIUS)
	elif axis.y > 0.0:
		position.y = minf(position.y + motion.y, origin.y + TILE - BODY_RADIUS)
	else:
		position.y = maxf(position.y + motion.y, origin.y + BODY_RADIUS)


func _enter(now: Vector2i) -> void:
	var move: MoveResult = terrain.check_move(cell, now, water_height)
	cell = now
	cell_changed.emit(now)
	settle()
	if move.drop > 0:
		fell.emit(move.drop, move.damaging)
