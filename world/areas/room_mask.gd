class_name RoomMask
extends Node2D
## Hides every dungeon room but the hero's (docs/TECH_DESIGN.md §6): a room smaller than the
## screen sits in the middle of it, and this paints everything outside the room in the clear
## colour, over the tiles and actors (below the HUD). The area creates it for dungeons.

const SHADE: Color = Color(0.05, 0.04, 0.06, 1.0)
## How far past the room the shade reaches (px): beyond anything the camera can show.
const REACH: float = 4096.0

## The room being shown, in area pixels.
var room_rect: Rect2 = Rect2()


func _init() -> void:
	z_index = 50


func show_room(rect: Rect2) -> void:
	room_rect = rect
	queue_redraw()


func _draw() -> void:
	var r: Rect2 = room_rect
	draw_rect(Rect2(r.position.x - REACH, r.position.y - REACH, REACH * 2.0 + r.size.x, REACH), SHADE)
	draw_rect(Rect2(r.position.x - REACH, r.end.y, REACH * 2.0 + r.size.x, REACH), SHADE)
	draw_rect(Rect2(r.position.x - REACH, r.position.y, REACH, r.size.y), SHADE)
	draw_rect(Rect2(r.end.x, r.position.y, REACH, r.size.y), SHADE)
