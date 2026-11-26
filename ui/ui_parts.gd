class_name UiParts
extends RefCounted
## Layout of ui/art/ui_parts.png: a box's wooden frame in nine pieces, cut from the Ninja Adventure
## pack's wood panel (the farm look's phase C), and the clock's dial (new art, step 4, from
## PixelLab's UI sheet: the pack has no dial). Read by PanelFrame and ClockDial.

const TEXTURE_PATH: String = "res://ui/art/ui_parts.png"
## A corner's side, and how deep an edge is (px). An edge piece is EDGE_LONG along.
const CORNER: int = 5
const EDGE: int = 5
const EDGE_LONG: int = 6
## The four corners in order: top-left, top-right, bottom-left, bottom-right.
const CORNERS: Array[Rect2] = [Rect2(0, 0, 5, 5), Rect2(5, 0, 5, 5), Rect2(10, 0, 5, 5), Rect2(15, 0, 5, 5)]
## The edges, each with its outline on the outside of the box.
const TOP: Rect2 = Rect2(20, 0, 6, 5)
const BOTTOM: Rect2 = Rect2(26, 0, 6, 5)
const LEFT: Rect2 = Rect2(32, 0, 5, 6)
const RIGHT: Rect2 = Rect2(37, 0, 5, 6)
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
