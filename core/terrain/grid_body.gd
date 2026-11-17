class_name GridBody
extends RefCounted
## Something that moves on an area's grid by the terrain rules (docs/TECH_DESIGN.md §3): the
## hero (PlayerMotor) and enemies. Pure: it owns a position and cell, asks TerrainQuery before
## its leading edge enters a new cell, stops short of cells it can't enter and slides along
## walls. Walkers follow the land rules, hopping down ledges only with `allow_drops` (the hero;
## enemies keep to their level). Bodies with `flying` cross heights and ledges, but not solid
## tiles or the map edge. Bodies that are `drifting` (a Bogwisp, a light with nothing to it)
## cross solid tiles too, and stop only at the map edge. Call place() before moving.

signal cell_changed(cell: Vector2i)
## Hopped down a ledge `levels` levels.
signal dropped(levels: int)

const TILE: float = 16.0
## How close (px) the centre may get to a cell it can't enter.
const BODY_RADIUS: float = 4.0
## Longest single movement sub-step (px), so a long frame can never skip a cell.
const MAX_SUBSTEP: float = 4.0

const DIRECTIONS: Array[Vector2] = [
	Vector2(1, 0), Vector2(0.70710678, 0.70710678), Vector2(0, 1), Vector2(-0.70710678, 0.70710678),
	Vector2(-1, 0), Vector2(-0.70710678, -0.70710678), Vector2(0, -1), Vector2(0.70710678, -0.70710678),
]

var terrain: TerrainQuery
## Feet position, in area pixels.
var position: Vector2 = Vector2.ZERO
var cell: Vector2i = Vector2i.ZERO
## The terrain level it stands at.
var level: int = 0
var allow_drops: bool = true
var flying: bool = false
## Nothing in the map stops it: water, reeds, walls. Only the map's edge does.
var drifting: bool = false


func _init(terrain_query: TerrainQuery = null) -> void:
	terrain = terrain_query


static func cell_of(point: Vector2) -> Vector2i:
	return Vector2i(floori(point.x / TILE), floori(point.y / TILE))


static func cell_center(at_cell: Vector2i) -> Vector2:
	return (Vector2(at_cell) + Vector2(0.5, 0.5)) * TILE


## Snaps stick or key input (or any direction) to one of 8 unit directions.
static func snap_to_8(input: Vector2) -> Vector2:
	if input.length() < 0.2:
		return Vector2.ZERO
	return DIRECTIONS[wrapi(roundi(input.angle() / (PI / 4.0)), 0, 8)]


## Puts it in the middle of `at_cell`.
func place(at_cell: Vector2i) -> void:
	position = cell_center(at_cell)
	cell = at_cell
	level = terrain.standing_level(at_cell)


## Whether it may move from its cell into the neighbouring `to_cell`.
func can_enter(to_cell: Vector2i) -> bool:
	if drifting:
		return terrain.grid.in_bounds(to_cell)
	if flying:
		return terrain.check_flight(cell, to_cell).is_allowed()
	var move: MoveResult = terrain.check_move(cell, to_cell)
	return move.kind == MoveResult.Kind.WALK or (move.kind == MoveResult.Kind.DROP and allow_drops)


## Moves up to `distance` px along unit `direction`, one axis at a time so walls slide.
## Returns how far it actually got.
func walk(direction: Vector2, distance: float) -> float:
	var start: Vector2 = position
	var remaining: float = distance
	while remaining > 0.0:
		var chunk: float = minf(remaining, MAX_SUBSTEP)
		remaining -= chunk
		if direction.x != 0.0:
			_walk_axis(Vector2(direction.x * chunk, 0.0))
		if direction.y != 0.0:
			_walk_axis(Vector2(0.0, direction.y * chunk))
	return position.distance_to(start)


func _walk_axis(motion: Vector2) -> void:
	var axis: Vector2 = motion.sign()
	var ahead: Vector2i = cell_of(position + motion + axis * BODY_RADIUS)
	if ahead != cell and not can_enter(ahead):
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
	if not flying and move.kind == MoveResult.Kind.DROP:
		dropped.emit(move.drop)
