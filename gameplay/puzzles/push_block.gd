class_name PushBlock
extends Node2D
## A heavy stone block (docs/TECH_DESIGN.md §6). It stands in its cell; hold a direction
## against it for a moment and it slides one cell that way, if PuzzleRules.can_push allows
## (open floor at the same level, not a room's border). It also presses plates. It's back
## where it started when the hero leaves its room (reset()) and on the next visit. Position =
## its cell's top-left corner (the slide is drawn; the cell changes at once).
## Pushed into a pit (PuzzleRules.can_sink) it drops in and fills it: the pit is floor from then
## on, and the block is part of it (`sunk`: it stands in nobody's way and moves no more). With a
## `block_id` it stays sunk for good, a dungeon flag holding the cell; without, reset() lifts it
## out again. The area calls set_dungeon().

const SLIDE_TIME: float = 0.18
const OUTLINE: Color = PixelGrade.INK
## Warm carved sandstone, so a block never passes for one of the grey pillars around it.
const STONE: Color = Color(0.74, 0.60, 0.40)

## Names its flag (DungeonState.block_flag) so that, once sunk, it stays sunk. Optional.
@export var block_id: StringName

## Whether it lies in a pit it filled.
var sunk: bool = false
var dungeon_id: StringName

var _slide_left: float = 0.0
var _slide_from: Vector2 = Vector2.ZERO
var _home: Vector2 = Vector2.ZERO
## Where it started (its cell's top-left corner).
var _start: Vector2 = Vector2.ZERO


func _ready() -> void:
	_home = position
	_start = position
	set_process(false)


## Called by the area on load: a block that sank for good lies where it sank.
func set_dungeon(id: StringName) -> void:
	dungeon_id = id
	if block_id == &"":
		return
	var at: PackedStringArray = str(GameState.get_flag(DungeonState.block_flag(dungeon_id, block_id), "")).split(",")
	if at.size() == 2:
		_home = Vector2(int(at[0]), int(at[1])) * PlayerMotor.TILE
		position = _home
		sunk = true
		queue_redraw()


func cell() -> Vector2i:
	return PlayerMotor.cell_of(_home + Vector2(0.5, 0.5))


## Sunk, it's floor: nothing finds it there.
func covers(at: Vector2i) -> bool:
	return not sunk and at == cell()


## It stands in its cell (the area marks the cell occupied), unless it lies in a pit.
func occupies() -> bool:
	return not sunk


## Slides one cell along `direction` if it can, keeping `terrain`'s occupied cells up to date.
## Returns whether it moved.
func try_push(direction: Vector2i, terrain: TerrainQuery, room_size: Vector2i) -> bool:
	if sunk:
		return false
	var sinks: bool = PuzzleRules.can_sink(terrain, cell(), direction, room_size)
	if not sinks and not PuzzleRules.can_push(terrain, cell(), direction, room_size):
		return false
	terrain.set_occupied(cell(), false)
	_slide_from = position
	_home += Vector2(direction) * PlayerMotor.TILE
	_slide_left = SLIDE_TIME
	set_process(true)
	Burst.spawn(get_parent(), _slide_from + Vector2(8, 14), &"dust")
	if not sinks:
		terrain.set_occupied(cell(), true)
		EventBus.sound.emit(&"push")
		return true
	# Into the pit: it fills it, and the pit is floor from now on.
	sunk = true
	terrain.set_pit(cell(), false)
	if block_id != &"":
		GameState.set_flag(DungeonState.block_flag(dungeon_id, block_id), "%d,%d" % [cell().x, cell().y])
	EventBus.sound.emit(&"sink")
	EventBus.shake.emit(1.5, 0.12)
	queue_redraw()
	return true


## Puts it back where it started, if it has moved and that cell is free, keeping `terrain`'s
## occupied cells up to date. Returns whether it moved.
func reset(terrain: TerrainQuery) -> bool:
	if sunk and block_id != &"":
		return false
	var start_cell: Vector2i = PlayerMotor.cell_of(_start + Vector2(0.5, 0.5))
	if start_cell == cell() or terrain.is_occupied(start_cell):
		return false
	if sunk:
		# Lifted out again: the pit is open once more.
		sunk = false
		terrain.set_pit(cell(), true)
		queue_redraw()
	else:
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
	if sunk:
		# Flush with the floor: its top face, a little darker for the depth.
		draw_rect(Rect2(0, 0, 16, 16), OUTLINE)
		draw_rect(Rect2(1, 1, 14, 14), STONE.darkened(0.28))
		draw_rect(Rect2(1, 1, 14, 1), STONE.darkened(0.12))
		draw_rect(Rect2(3, 3, 10, 10), STONE.darkened(0.45))
		draw_rect(Rect2(4, 4, 8, 8), STONE.darkened(0.28))
		return
	SoftShadow.draw(self, Vector2(8, 14.5), Vector2(7.5, 2))
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
