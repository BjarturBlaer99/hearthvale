class_name PanelFrame
extends ColorRect
## The look every box on screen shares (art pass 4, P1f): the dialogue box, the menus, the HUD's
## corner. On top of the box's own colour it draws, all in whole pixels:
## - a soft shadow under the box
## - a lighter band along the top
## - an inner line, lit along the top and left and in shade along the bottom and right
## - a bracket in each corner, with a rivet where the inner line turns
## - under a heading (`rule_y`), a rule across the box with a small diamond in its middle
## The gold edge around a box is its Border sibling, as before.

const GOLD: Color = Color(0.85, 0.74, 0.48)
const GOLD_LIGHT: Color = Color(1.0, 0.93, 0.70)
const INNER_LIT: Color = Color(1.0, 0.90, 0.62, 0.34)
const INNER_SHADE: Color = Color(0.85, 0.74, 0.48, 0.14)
const RULE: Color = Color(0.85, 0.74, 0.48, 0.55)
const SHEEN: Color = Color(1.0, 0.95, 0.85, 0.05)
const SHADOW: Color = Color(0.03, 0.02, 0.06, 0.45)
## How far in the inner line sits (px).
const INSET: float = 2.0
## How long each arm of a corner's bracket is, and the size of its rivet (px).
const BRACKET: float = 6.0
const RIVET: float = 2.0
## How far the heading's rule stops short of the box's sides, how far its diamond reaches from
## its middle, and the gap left between the two (px).
const RULE_MARGIN: float = 8.0
const DIAMOND: int = 2
const RULE_GAP: float = 2.0

## Where the rule under the box's heading is drawn, down from the top (px). Zero: no heading,
## no rule.
@export var rule_y: float = 0.0


func _ready() -> void:
	resized.connect(queue_redraw)


## The two halves of the heading's rule in a box of `box_size`, left and right of its diamond.
## Empty if the box has no heading or is too narrow for one.
static func rule_parts(box_size: Vector2, y: float) -> Array[Rect2]:
	var middle: float = floorf(box_size.x / 2.0)
	var reach: float = DIAMOND + RULE_GAP
	if y <= 0.0 or middle - reach - RULE_MARGIN < 1.0:
		return []
	return [
		Rect2(RULE_MARGIN, y, middle - reach - RULE_MARGIN, 1.0),
		Rect2(middle + reach + 1.0, y, box_size.x - RULE_MARGIN - (middle + reach + 1.0), 1.0),
	]


## The rows of the rule's diamond, top to bottom: one pixel, three, five, three, one.
static func diamond_rows(box_size: Vector2, y: float) -> Array[Rect2]:
	var middle: float = floorf(box_size.x / 2.0)
	var rows: Array[Rect2] = []
	for dy: int in range(-DIAMOND, DIAMOND + 1):
		var half: int = DIAMOND - absi(dy)
		rows.append(Rect2(middle - half, y + dy, half * 2 + 1, 1.0))
	return rows


## The two arms of the bracket in each corner of a box of `box_size`: eight strips along its
## very edge.
static func bracket_arms(box_size: Vector2) -> Array[Rect2]:
	var arms: Array[Rect2] = []
	for x: float in [0.0, box_size.x - BRACKET]:
		for y: float in [0.0, box_size.y - 1.0]:
			arms.append(Rect2(x, y, BRACKET, 1.0))
	for x: float in [0.0, box_size.x - 1.0]:
		for y: float in [0.0, box_size.y - BRACKET]:
			arms.append(Rect2(x, y, 1.0, BRACKET))
	return arms


func _draw() -> void:
	# The shadow falls below and to the right, outside the box and its border.
	draw_rect(Rect2(Vector2(2.0, size.y + 1.0), Vector2(size.x + 1.0, 2.0)), SHADOW)
	draw_rect(Rect2(Vector2(size.x + 1.0, 2.0), Vector2(2.0, size.y - 1.0)), SHADOW)
	if size.x < 2.0 * BRACKET or size.y < 2.0 * BRACKET:
		return
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, minf(10.0, size.y * 0.25))), SHEEN)
	# The inner line: light falls from the top left.
	var inner: Rect2 = Rect2(Vector2(INSET, INSET), size - Vector2(INSET, INSET) * 2.0)
	draw_rect(Rect2(inner.position, Vector2(inner.size.x, 1.0)), INNER_LIT)
	draw_rect(Rect2(inner.position + Vector2(0.0, 1.0), Vector2(1.0, inner.size.y - 1.0)), INNER_LIT)
	draw_rect(Rect2(Vector2(inner.position.x + 1.0, inner.end.y - 1.0), Vector2(inner.size.x - 1.0, 1.0)), INNER_SHADE)
	draw_rect(Rect2(Vector2(inner.end.x - 1.0, inner.position.y + 1.0), Vector2(1.0, inner.size.y - 2.0)), INNER_SHADE)
	for arm: Rect2 in bracket_arms(size):
		draw_rect(arm, GOLD)
	for corner: Vector2 in [inner.position, Vector2(inner.end.x - RIVET, inner.position.y), Vector2(inner.position.x, inner.end.y - RIVET), inner.end - Vector2(RIVET, RIVET)]:
		draw_rect(Rect2(corner, Vector2(RIVET, RIVET)), GOLD_LIGHT)
	for part: Rect2 in rule_parts(size, rule_y):
		draw_rect(part, RULE)
	if not rule_parts(size, rule_y).is_empty():
		for row: Rect2 in diamond_rows(size, rule_y):
			draw_rect(row, GOLD)
		draw_rect(Rect2(floorf(size.x / 2.0), rule_y, 1.0, 1.0), GOLD_LIGHT)
