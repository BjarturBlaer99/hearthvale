class_name PlayerMotor
extends RefCounted
## Grid-checked top-down movement for the hero (docs/TECH_DESIGN.md §3, §4). Pure: it owns
## position, level and a small state machine (one script per state; `ground` for now, with
## attack and hurt states to come), and asks TerrainQuery before the hero's leading edge
## enters a new cell. PlayerController feeds it input every physics frame and draws it.
## Call place() before the first step().

signal state_changed(state_name: StringName)
signal cell_changed(cell: Vector2i)
## The hero hopped down a ledge `levels` levels (for the hop animation).
signal dropped(levels: int)

const TILE: float = 16.0
const WALK_SPEED: float = 72.0
## How close (px) the hero's centre may get to a cell they can't enter.
const BODY_RADIUS: float = 4.0
## Longest single movement sub-step (px), so a long frame can never skip a cell.
const MAX_SUBSTEP: float = 4.0

const GROUND: StringName = &"ground"

const DIRECTIONS: Array[Vector2] = [
	Vector2(1, 0), Vector2(0.70710678, 0.70710678), Vector2(0, 1), Vector2(-0.70710678, 0.70710678),
	Vector2(-1, 0), Vector2(-0.70710678, -0.70710678), Vector2(0, -1), Vector2(0.70710678, -0.70710678),
]

var terrain: TerrainQuery
## Feet position, in area pixels.
var position: Vector2 = Vector2.ZERO
var cell: Vector2i = Vector2i.ZERO
## The terrain level the hero stands at.
var level: int = 0
## Last non-zero movement direction.
var facing: Vector2 = Vector2.DOWN
var state: PlayerState
var state_name: StringName = &""

var _states: Dictionary[StringName, PlayerState] = {}


func _init(terrain_query: TerrainQuery = null) -> void:
	terrain = terrain_query
	_states = {GROUND: PlayerGroundState.new()}


static func cell_of(point: Vector2) -> Vector2i:
	return Vector2i(floori(point.x / TILE), floori(point.y / TILE))


static func cell_center(at_cell: Vector2i) -> Vector2:
	return (Vector2(at_cell) + Vector2(0.5, 0.5)) * TILE


## Snaps stick or key input to one of 8 unit directions (equal speed diagonally).
static func snap_to_8(input: Vector2) -> Vector2:
	if input.length() < 0.2:
		return Vector2.ZERO
	return DIRECTIONS[wrapi(roundi(input.angle() / (PI / 4.0)), 0, 8)]


## Puts the hero in the middle of `at_cell`, standing.
func place(at_cell: Vector2i) -> void:
	position = cell_center(at_cell)
	cell = at_cell
	level = terrain.standing_level(at_cell)
	state_name = &""
	change_state(GROUND)


func step(input: Vector2, delta: float) -> void:
	var direction: Vector2 = snap_to_8(input)
	if direction != Vector2.ZERO:
		facing = direction
	state.step(self, direction, delta)


func change_state(next: StringName, data: Dictionary = {}) -> void:
	if next == state_name and data.is_empty():
		return
	if state != null:
		state.exit(self)
	state_name = next
	state = _states[next]
	state.enter(self, data)
	state_changed.emit(next)


## Moves up to `distance` px along unit `direction`, one axis at a time so walls slide.
func walk(direction: Vector2, distance: float) -> void:
	var remaining: float = distance
	while remaining > 0.0:
		var chunk: float = minf(remaining, MAX_SUBSTEP)
		remaining -= chunk
		if direction.x != 0.0:
			_walk_axis(Vector2(direction.x * chunk, 0.0))
		if direction.y != 0.0:
			_walk_axis(Vector2(0.0, direction.y * chunk))


func _walk_axis(motion: Vector2) -> void:
	var axis: Vector2 = motion.sign()
	var ahead: Vector2i = cell_of(position + motion + axis * BODY_RADIUS)
	if ahead != cell and not terrain.check_move(cell, ahead).is_allowed():
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
	var move: MoveResult = terrain.check_move(cell, now)
	cell = now
	level = terrain.standing_level(now)
	cell_changed.emit(now)
	if move.kind == MoveResult.Kind.DROP:
		dropped.emit(move.drop)
