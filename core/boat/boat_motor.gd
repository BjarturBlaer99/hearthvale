class_name BoatMotor
extends RefCounted
## Arcade sailing for the player's boat (docs/TECH_DESIGN.md §4). Pure. The boat turns
## toward the stick or keys at TURN_RATE, thrusts along its heading (less while still
## turning), and its sideways speed dies quickly: that lag is the drift. It floats only on
## deep cells: shores and shallows stop it, grid-checked like PlayerMotor. Pushing off the
## edge of the map emits `edge_reached` (a district then hands over to the sea map).

signal cell_changed(cell: Vector2i)
## The boat tried to sail off the map; `direction` is the unit axis it was moving along.
signal edge_reached(direction: Vector2)

const TILE: float = 16.0
const MAX_SPEED: float = 110.0
const ACCELERATION: float = 150.0
## Radians per second.
const TURN_RATE: float = 3.5
## Exponential drag per second along the heading (coasting) and across it (drift).
const FORWARD_DRAG: float = 0.9
const SIDE_DRAG: float = 5.0
## How close (px) the boat's centre may get to a cell it can't float in.
const RADIUS: float = 6.0
const MAX_SUBSTEP: float = 4.0

var terrain: TerrainQuery
var water_height: int = 0
var position: Vector2 = Vector2.ZERO
var cell: Vector2i = Vector2i.ZERO
var velocity: Vector2 = Vector2.ZERO
## Radians; 0 points east, PI/2 south.
var heading: float = 0.0


func _init(terrain_query: TerrainQuery = null, current_water_height: int = 0) -> void:
	terrain = terrain_query
	water_height = current_water_height


## Puts the boat at rest in the middle of `at_cell`.
func place(at_cell: Vector2i, at_heading: float) -> void:
	position = PlayerMotor.cell_center(at_cell)
	cell = at_cell
	velocity = Vector2.ZERO
	heading = at_heading


func speed() -> float:
	return velocity.length()


## `input` is a direction (length up to 1); zero lets the boat coast to a stop.
func step(input: Vector2, delta: float) -> void:
	if input.length() > 0.2:
		var target: float = input.angle()
		heading = rotate_toward(heading, target, TURN_RATE * delta)
		var alignment: float = maxf(0.0, cos(angle_difference(heading, target)))
		velocity += Vector2.from_angle(heading) * ACCELERATION * alignment * minf(input.length(), 1.0) * delta
	var forward: Vector2 = Vector2.from_angle(heading)
	var along: float = velocity.dot(forward)
	var side: Vector2 = velocity - forward * along
	velocity = forward * along * exp(-FORWARD_DRAG * delta) + side * exp(-SIDE_DRAG * delta)
	velocity = velocity.limit_length(MAX_SPEED)
	_move(velocity * delta)


func _move(motion: Vector2) -> void:
	var steps: int = ceili(motion.length() / MAX_SUBSTEP)
	if steps == 0:
		return
	var chunk: Vector2 = motion / float(steps)
	for i: int in steps:
		if chunk.x != 0.0:
			_move_axis(Vector2(chunk.x, 0.0))
		if chunk.y != 0.0:
			_move_axis(Vector2(0.0, chunk.y))


func _move_axis(motion: Vector2) -> void:
	var axis: Vector2 = motion.sign()
	var ahead: Vector2i = PlayerMotor.cell_of(position + motion + axis * RADIUS)
	if ahead != cell:
		if not terrain.grid.in_bounds(ahead):
			_bump(motion, axis)
			edge_reached.emit(axis)
			return
		if not BoatRules.floats(terrain, ahead, water_height):
			_bump(motion, axis)
			return
	position += motion
	var now: Vector2i = PlayerMotor.cell_of(position)
	if now != cell:
		cell = now
		cell_changed.emit(now)


## Stops RADIUS short of the cell it can't enter and kills speed along that axis.
func _bump(motion: Vector2, axis: Vector2) -> void:
	var origin: Vector2 = Vector2(cell) * TILE
	if axis.x > 0.0:
		position.x = minf(position.x + motion.x, origin.x + TILE - RADIUS)
		velocity.x = minf(velocity.x, 0.0)
	elif axis.x < 0.0:
		position.x = maxf(position.x + motion.x, origin.x + RADIUS)
		velocity.x = maxf(velocity.x, 0.0)
	elif axis.y > 0.0:
		position.y = minf(position.y + motion.y, origin.y + TILE - RADIUS)
		velocity.y = minf(velocity.y, 0.0)
	else:
		position.y = maxf(position.y + motion.y, origin.y + RADIUS)
		velocity.y = maxf(velocity.y, 0.0)
