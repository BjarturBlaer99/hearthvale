class_name PuzzleRules
extends RefCounted
## Pure rules for puzzle pieces (docs/TECH_DESIGN.md §6): pushing blocks, pressing plates, and
## shutters that wait on several flags.


## Whether a block in `from` can be pushed one cell along `direction`. The next cell must be
## open floor at the same level (no stairs, ledges or anything standing there) and, in a
## dungeon with rooms of `room_size`, not on its room's border, so a block can never jam a
## doorway.
static func can_push(terrain: TerrainQuery, from: Vector2i, direction: Vector2i, room_size: Vector2i = Vector2i.ZERO) -> bool:
	if direction == Vector2i.ZERO or absi(direction.x) + absi(direction.y) != 1:
		return false
	var to: Vector2i = from + direction
	var move: MoveResult = terrain.check_move(from, to)
	if move.kind != MoveResult.Kind.WALK or terrain.grid.is_ramp(to) or terrain.grid.height_at(to) != terrain.grid.height_at(from):
		return false
	return not on_room_border(to, room_size)


## Whether `cell` is in the wall ring of its room (the first or last row or column).
static func on_room_border(cell: Vector2i, room_size: Vector2i) -> bool:
	if room_size.x <= 0 or room_size.y <= 0:
		return false
	var local: Vector2i = Vector2i(posmod(cell.x, room_size.x), posmod(cell.y, room_size.y))
	return local.x == 0 or local.y == 0 or local.x == room_size.x - 1 or local.y == room_size.y - 1


## A plate is pressed while the hero or a block stands on it.
static func plate_pressed(plate: Vector2i, hero: Vector2i, blocks: Array) -> bool:
	return plate == hero or blocks.has(plate)


## Whether a shutter waiting on these flag values opens: any of them, or all with `needs_all`.
## With no flags at all it stays shut.
static func shutter_open(values: Array, needs_all: bool) -> bool:
	if values.is_empty():
		return false
	for value: Variant in values:
		if needs_all and value != true:
			return false
		if not needs_all and value == true:
			return true
	return needs_all
