class_name Signpost
extends Talkable
## A wooden sign to read. Its text is a conversation in data/dialogue (usually one node with
## no options and no speaker). Placeholder art drawn in code.

const OUTLINE: Color = Color(0.10, 0.08, 0.12)
const WOOD: Color = Color(0.62, 0.43, 0.24)


func prompt() -> String:
	return "Read the sign"


func _draw() -> void:
	draw_set_transform(Vector2(0.0, -Villager.LIFT))
	draw_rect(Rect2(4, 13, 8, 2), Color(0, 0, 0, 0.3))
	draw_rect(Rect2(6, 5, 4, 10), OUTLINE)
	draw_rect(Rect2(7, 5, 2, 9), WOOD.darkened(0.3))
	draw_rect(Rect2(1, -1, 14, 9), OUTLINE)
	draw_rect(Rect2(2, 0, 12, 7), WOOD)
	draw_rect(Rect2(2, 0, 12, 1), WOOD.lightened(0.2))
	for row: int in [2, 4]:
		draw_rect(Rect2(4, row, 8, 1), WOOD.darkened(0.45))
