class_name PanelFrame
extends ColorRect
## The look every box on screen shares (art pass 4): the dialogue box, the menus, the HUD's
## corner. On top of the box's own colour it draws a soft shadow under the box, a lighter band
## along the top, an inner line and a stud in each corner, all in whole pixels. The gold edge
## around it is the box's Border sibling, as before.

const GOLD: Color = Color(0.85, 0.74, 0.48)
const INNER_LINE: Color = Color(0.85, 0.74, 0.48, 0.28)
const SHEEN: Color = Color(1.0, 0.95, 0.85, 0.05)
const SHADOW: Color = Color(0.03, 0.02, 0.06, 0.45)
## How far in the inner line sits (px), and the size of a corner stud.
const INSET: float = 2.0
const STUD: float = 3.0


func _ready() -> void:
	resized.connect(queue_redraw)


func _draw() -> void:
	var box: Rect2 = Rect2(Vector2.ZERO, size)
	# The shadow falls below and to the right, outside the box and its border.
	draw_rect(Rect2(Vector2(2.0, size.y + 1.0), Vector2(size.x + 1.0, 2.0)), SHADOW)
	draw_rect(Rect2(Vector2(size.x + 1.0, 2.0), Vector2(2.0, size.y - 1.0)), SHADOW)
	if size.x < 4.0 * INSET or size.y < 4.0 * INSET:
		return
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, minf(10.0, size.y * 0.25))), SHEEN)
	draw_rect(box.grow(-INSET + 0.5), INNER_LINE, false, 1.0)
	for corner: Vector2 in [Vector2.ZERO, Vector2(size.x - STUD, 0.0), Vector2(0.0, size.y - STUD), size - Vector2(STUD, STUD)]:
		draw_rect(Rect2(corner, Vector2(STUD, STUD)), GOLD)
