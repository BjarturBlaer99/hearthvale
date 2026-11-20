class_name UiParts
extends RefCounted
## Layout of ui/art/ui_parts.png (new art, step 4, from PixelLab's UI sheet): a box's wooden frame
## in nine pieces, and the clock's dial. Read by PanelFrame and ClockDial.

const TEXTURE_PATH: String = "res://ui/art/ui_parts.png"
## A gold corner cap's side, and how deep an edge is (px). An edge piece is EDGE_LONG along.
const CORNER: int = 7
const EDGE: int = 6
const EDGE_LONG: int = 16
## The four corners in order: top-left, top-right, bottom-left, bottom-right.
const CORNERS: Array[Rect2] = [Rect2(0, 0, 7, 7), Rect2(7, 0, 7, 7), Rect2(14, 0, 7, 7), Rect2(21, 0, 7, 7)]
## The edges, each with its outline on the outside of the box.
const TOP: Rect2 = Rect2(28, 0, 16, 6)
const BOTTOM: Rect2 = Rect2(44, 0, 16, 6)
const LEFT: Rect2 = Rect2(60, 0, 6, 16)
const RIGHT: Rect2 = Rect2(66, 0, 6, 16)
## The clock's dial: day (a sun) on its left half, night (a moon) on its right.
const DIAL: Rect2 = Rect2(72, 0, 32, 32)
## The dial's middle, in the dial's own picture, and how long its hand is (px).
const DIAL_CENTRE: Vector2 = Vector2(16, 16)
const HAND_LENGTH: float = 9.0

static var _texture: Texture2D


static func texture() -> Texture2D:
	if _texture == null:
		_texture = load(TEXTURE_PATH)
	return _texture
