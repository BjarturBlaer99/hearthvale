class_name PanelFrame
extends ColorRect
## The look every box on screen shares (new art, step 4, from PixelLab's UI sheet): the dialogue
## box, the menus, the HUD's corner. Its inside is dark wood, and over it it draws, in whole pixels:
## - a soft shadow under the box
## - a lighter band along the top
## - a wooden frame with a gold cap in each corner (UiParts), laid over the box's outermost pixel
##   so it covers the gold edge of its Border sibling
## - under a heading (`rule_y`), a rule across the box with a small diamond in its middle

const GOLD: Color = Color(0.85, 0.66, 0.39)
const GOLD_LIGHT: Color = Color(0.95, 0.85, 0.59)
const RULE: Color = Color(0.85, 0.66, 0.39, 0.6)
const SHEEN: Color = Color(1.0, 0.95, 0.85, 0.05)
const SHADOW: Color = Color(0.03, 0.02, 0.06, 0.45)
## The box's inside: the dark wood of the sheet's slots (its own alpha is kept).
const WOOD: Color = Color(0.25, 0.16, 0.12)
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
	color = Color(WOOD, color.a)


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


## The frame of a box of `box_size`: pairs of [where in UiParts' picture, where on the box],
## the four corners first (top-left, top-right, bottom-left, bottom-right), then the edges in
## pieces of UiParts.EDGE_LONG or less between them. The frame starts a pixel outside the box,
## over its Border. Empty if the box is too small for a frame.
static func pieces(box_size: Vector2) -> Array[Array]:
	var out: Array[Array] = []
	var whole: Rect2 = Rect2(Vector2(-1.0, -1.0), box_size + Vector2(2.0, 2.0))
	var c: float = UiParts.CORNER
	var e: float = UiParts.EDGE
	if whole.size.x < c * 2.0 or whole.size.y < c * 2.0:
		return out
	var corners: Array[Vector2] = [whole.position, Vector2(whole.end.x - c, whole.position.y), Vector2(whole.position.x, whole.end.y - c), whole.end - Vector2(c, c)]
	for i: int in 4:
		out.append([UiParts.CORNERS[i], Rect2(corners[i], Vector2(c, c))])
	var x: float = whole.position.x + c
	while x < whole.end.x - c:
		var run: float = minf(UiParts.EDGE_LONG, whole.end.x - c - x)
		out.append([Rect2(UiParts.TOP.position, Vector2(run, e)), Rect2(Vector2(x, whole.position.y), Vector2(run, e))])
		out.append([Rect2(UiParts.BOTTOM.position, Vector2(run, e)), Rect2(Vector2(x, whole.end.y - e), Vector2(run, e))])
		x += run
	var y: float = whole.position.y + c
	while y < whole.end.y - c:
		var run: float = minf(UiParts.EDGE_LONG, whole.end.y - c - y)
		out.append([Rect2(UiParts.LEFT.position, Vector2(e, run)), Rect2(Vector2(whole.position.x, y), Vector2(e, run))])
		out.append([Rect2(UiParts.RIGHT.position, Vector2(e, run)), Rect2(Vector2(whole.end.x - e, y), Vector2(e, run))])
		y += run
	return out


func _draw() -> void:
	# The shadow falls below and to the right, outside the box and its frame.
	draw_rect(Rect2(Vector2(2.0, size.y + 1.0), Vector2(size.x + 1.0, 2.0)), SHADOW)
	draw_rect(Rect2(Vector2(size.x + 1.0, 2.0), Vector2(2.0, size.y - 1.0)), SHADOW)
	draw_rect(Rect2(Vector2.ZERO, Vector2(size.x, minf(10.0, size.y * 0.25))), SHEEN)
	var picture: Texture2D = UiParts.texture()
	# The edges first, then the corners over their ends.
	var all: Array[Array] = pieces(size)
	for i: int in range(all.size() - 1, -1, -1):
		draw_texture_rect_region(picture, all[i][1], all[i][0])
	for part: Rect2 in rule_parts(size, rule_y):
		draw_rect(part, RULE)
	if not rule_parts(size, rule_y).is_empty():
		for row: Rect2 in diamond_rows(size, rule_y):
			draw_rect(row, GOLD)
		draw_rect(Rect2(floorf(size.x / 2.0), rule_y, 1.0, 1.0), GOLD_LIGHT)
