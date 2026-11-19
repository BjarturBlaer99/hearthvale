class_name AnimalMotion
extends RefCounted
## How an animal of the hero's land moves (the Homestead, phase 4; docs/TECH_DESIGN.md §30), pure:
## it stands or grazes a while, then walks to a cell near it, and never leaves the cells it is
## given (its pasture by day, its room's floor by night). It walks straight; a step that would
## take it out of its cells ends the walk. It blocks nobody and is blocked by nobody (D28): the
## cells say where it may be, not the terrain. Random numbers come from the generator given.

const IDLE: StringName = &"idle"
const GRAZE: StringName = &"graze"
const WALK: StringName = &"walk"
## How far a walk goes, in cells either way.
const REACH: int = 3

var position: Vector2 = Vector2.ZERO
var speed: float = 14.0
var state: StringName = IDLE
## -1 facing left (as its pictures are drawn), 1 facing right.
var facing_x: float = -1.0

var _cells: Dictionary[Vector2i, bool] = {}
var _rng: RandomNumberGenerator
var _target: Vector2 = Vector2.ZERO
var _timer: float = 0.0


## An animal standing in the middle of `start`, which may walk among `cells` at `move_speed`
## px/s. A start that isn't one of the cells is taken as one (it is where it was put).
func _init(cells: Array[Vector2i], start: Vector2i, move_speed: float, rng: RandomNumberGenerator) -> void:
	_rng = rng
	speed = move_speed
	set_cells(cells)
	_cells[start] = true
	position = GridBody.cell_center(start)
	_target = position
	_timer = _rng.randf_range(0.3, 2.0)


## The cells it may be in from now on. If it stands outside them, it stays until it walks back in.
func set_cells(cells: Array[Vector2i]) -> void:
	_cells.clear()
	for cell: Vector2i in cells:
		_cells[cell] = true


## The cells it may walk among.
func cells() -> Array[Vector2i]:
	return _cells.keys()


func has_cell(cell: Vector2i) -> bool:
	return _cells.has(cell)


## The cell it stands in.
func cell() -> Vector2i:
	return PlayerMotor.cell_of(position)


func step(delta: float) -> void:
	_timer -= delta
	match state:
		IDLE, GRAZE:
			if _timer <= 0.0:
				_start_walk()
		WALK:
			var offset: Vector2 = _target - position
			if offset.length() < 1.0 or _timer <= 0.0:
				_rest()
				return
			var direction: Vector2 = offset.normalized()
			if absf(direction.x) > 0.1:
				facing_x = signf(direction.x)
			var next: Vector2 = position + direction * minf(speed * delta, offset.length())
			if not _cells.has(PlayerMotor.cell_of(next)):
				_rest()
				return
			position = next


func _start_walk() -> void:
	var here: Vector2i = cell()
	var near: Array[Vector2i] = []
	for at: Vector2i in _cells:
		if at != here and absi(at.x - here.x) <= REACH and absi(at.y - here.y) <= REACH:
			near.append(at)
	if near.is_empty():
		_rest()
		return
	near.sort()
	var to: Vector2i = near[_rng.randi_range(0, near.size() - 1)]
	# Somewhere in that cell, not always its middle.
	_target = GridBody.cell_center(to) + Vector2(_rng.randf_range(-4.0, 4.0), _rng.randf_range(-3.0, 3.0))
	state = WALK
	_timer = 4.0


func _rest() -> void:
	state = GRAZE if _rng.randf() < 0.5 else IDLE
	_timer = _rng.randf_range(1.0, 3.5)
