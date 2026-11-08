class_name RoomGrid
extends RefCounted
## Cuts a dungeon area into equal rooms (docs/TECH_DESIGN.md §6): the camera shows one room at
## a time. Pure. A zero room size means no rooms: the whole area is one.


## Which room `cell` is in (room coordinates: (0, 0) is the top-left room).
static func room_of(cell: Vector2i, room_size: Vector2i) -> Vector2i:
	if room_size.x <= 0 or room_size.y <= 0:
		return Vector2i.ZERO
	return Vector2i(floori(float(cell.x) / room_size.x), floori(float(cell.y) / room_size.y))


## The cells `room` covers.
static func cells_of(room: Vector2i, room_size: Vector2i) -> Rect2i:
	return Rect2i(room * room_size, room_size)


## The pixels the camera shows for the room around `cell`, or all of `area_size` (cells)
## without rooms.
static func camera_rect(cell: Vector2i, room_size: Vector2i, area_size: Vector2i, tile: int) -> Rect2i:
	if room_size.x <= 0 or room_size.y <= 0:
		return Rect2i(Vector2i.ZERO, area_size * tile)
	var cells: Rect2i = cells_of(room_of(cell, room_size), room_size)
	return Rect2i(cells.position * tile, cells.size * tile)
