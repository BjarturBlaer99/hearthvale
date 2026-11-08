class_name PushBlock
extends Node2D
## A heavy stone block (docs/TECH_DESIGN.md §6). It stands in its cell; hold a direction
## against it for a moment and it slides one cell that way, if PuzzleRules.can_push allows
## (open floor at the same level, not a room's border). It also presses plates. It's back
## where it started when the hero leaves its room (reset()) and on the next visit. Position =
## its cell's top-left corner (the slide is drawn; the cell changes at once).

const SLIDE_TIME: float = 0.18
const OUTLINE: Color = Color(0.10, 0.08, 0.12)
## Warm carved sandstone, so a block never passes for one of the grey pillars around it.
const STONE: Color = Color(0.74, 0.60, 0.40)

var _slide_left: float = 0.0
var _slide_from: Vector2 = Vector2.ZERO
var _home: Vector2 = Vector2.ZERO
## Where it started (its cell's top-left corner).
var _start: Vector2 = Vector2.ZERO


func _ready() -> void:
	_home = position
	_start = position
	set_process(false)


func cell() -> Vector2i:
	return PlayerMotor.cell_of(_home + Vector2(0.5, 0.5))


func covers(at: Vector2i) -> bool:
	return at == cell()


## It stands in its cell: the area marks the cell occupied.
func occupies() -> bool:
	return true


## Slides one cell along `direction` if it can, keeping `terrain`'s occupied cells up to date.
## Returns whether it moved.
func try_push(direction: Vector2i, terrain: TerrainQuery, room_size: Vector2i) -> bool:
	if not PuzzleRules.can_push(terrain, cell(), direction, room_size):
		return false
	terrain.set_occupied(cell(), false)
	_slide_from = position
	_home += Vector2(direction) * PlayerMotor.TILE
	terrain.set_occupied(cell(), true)
	_slide_left = SLIDE_TIME
	set_process(true)
	return true


## Puts it back where it started, if it has moved and that cell is free, keeping `terrain`'s
## occupied cells up to date. Returns whether it moved.
func reset(terrain: TerrainQuery) -> bool:
	var start_cell: Vector2i = PlayerMotor.cell_of(_start + Vector2(0.5, 0.5))
	if start_cell == cell() or terrain.is_occupied(start_cell):
		return false
	terrain.set_occupied(cell(), false)
	_home = _start
	position = _start
	_slide_left = 0.0
	set_process(false)
	terrain.set_occupied(cell(), true)
	return true


func _process(delta: float) -> void:
	_slide_left = maxf(0.0, _slide_left - delta)
	position = _home.lerp(_slide_from, _slide_left / SLIDE_TIME)
	if _slide_left <= 0.0:
		set_process(false)


func _draw() -> void:
	draw_rect(Rect2(1, 13, 14, 3), Color(0, 0, 0, 0.3))
	draw_rect(Rect2(0, 0, 16, 15), OUTLINE)
	draw_rect(Rect2(1, 1, 14, 13), STONE)
	draw_rect(Rect2(1, 1, 14, 3), STONE.lightened(0.22))
	draw_rect(Rect2(1, 11, 14, 3), STONE.darkened(0.25))
	# A carved ring and a diamond: the mark of a block that moves.
	draw_rect(Rect2(3, 3, 10, 1), STONE.darkened(0.35))
	draw_rect(Rect2(3, 10, 10, 1), STONE.darkened(0.35))
	draw_rect(Rect2(3, 3, 1, 8), STONE.darkened(0.35))
	draw_rect(Rect2(12, 3, 1, 8), STONE.darkened(0.35))
	draw_colored_polygon(PackedVector2Array([Vector2(8, 4.5), Vector2(10.5, 7), Vector2(8, 9.5), Vector2(5.5, 7)]), STONE.darkened(0.3))
	draw_colored_polygon(PackedVector2Array([Vector2(8, 5.5), Vector2(9.5, 7), Vector2(8, 8.5), Vector2(6.5, 7)]), STONE.lightened(0.15))
