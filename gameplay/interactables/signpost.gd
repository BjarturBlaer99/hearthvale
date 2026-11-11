class_name Signpost
extends Talkable
## Something to read: a wooden signpost by the road, or (`stone`) a standing stone with an
## inscription, as in the dungeons and by the chapel door. Its text is a conversation in
## data/dialogue (usually one node with no options and no speaker). Drawn in code.

const OUTLINE: Color = PixelGrade.INK
const WOOD: Color = Color(0.62, 0.43, 0.24)
const STONE: Color = Color(0.58, 0.60, 0.66)

## A standing stone with carved lines, in place of the wooden signpost.
@export var stone: bool = false:
	set(value):
		stone = value
		queue_redraw()


func prompt() -> String:
	return "Read the inscription" if stone else "Read the sign"


func _draw() -> void:
	draw_set_transform(Vector2(0.0, -Villager.LIFT))
	if stone:
		_draw_stone()
	else:
		_draw_wood()


func _draw_wood() -> void:
	draw_rect(Rect2(4, 13, 8, 2), Color(0, 0, 0, 0.3))
	draw_rect(Rect2(6, 5, 4, 10), OUTLINE)
	draw_rect(Rect2(7, 5, 2, 9), WOOD.darkened(0.3))
	draw_rect(Rect2(1, -1, 14, 9), OUTLINE)
	draw_rect(Rect2(2, 0, 12, 7), WOOD)
	draw_rect(Rect2(2, 0, 12, 1), WOOD.lightened(0.2))
	for row: int in [2, 4]:
		draw_rect(Rect2(4, row, 8, 1), WOOD.darkened(0.45))


## A slab with a rounded top on a wider foot, lit from the left, with four carved lines.
func _draw_stone() -> void:
	draw_rect(Rect2(2, 14, 12, 2), Color(0, 0, 0, 0.3))
	draw_rect(Rect2(5, -1, 6, 1), OUTLINE)
	draw_rect(Rect2(4, 0, 8, 1), OUTLINE)
	draw_rect(Rect2(3, 1, 10, 12), OUTLINE)
	draw_rect(Rect2(2, 12, 12, 3), OUTLINE)
	draw_rect(Rect2(5, 0, 6, 1), STONE.lightened(0.25))
	draw_rect(Rect2(4, 1, 8, 11), STONE)
	draw_rect(Rect2(4, 1, 1, 11), STONE.lightened(0.25))
	draw_rect(Rect2(11, 1, 1, 11), STONE.darkened(0.25))
	draw_rect(Rect2(3, 13, 10, 1), STONE.darkened(0.35))
	for row: int in [3, 5, 7, 9]:
		draw_rect(Rect2(6, row, 3 if row == 9 else 4, 1), STONE.darkened(0.5))
