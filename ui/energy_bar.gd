class_name EnergyBar
extends Control
## The hero's energy as a bar (GDD §5), under the hearts in the HUD's corner: a small leaf, then
## a framed bar that empties from the right and turns from green to amber to red as it runs
## low. Drawn in whole pixels. It only shows what it is told; the energy rules come in P2, and
## until then the HUD keeps it hidden.

## The bar's inside, in pixels.
const WIDTH: int = 64
const HEIGHT: int = 5
## Where the bar starts, after the leaf.
const BAR_X: float = 9.0
## At or under this share of the whole, energy counts as low.
const LOW: float = 0.25
const FULL_COLOR: Color = Color(0.47, 0.80, 0.38)
const MID_COLOR: Color = Color(0.93, 0.78, 0.33)
const LOW_COLOR: Color = Color(0.90, 0.38, 0.26)
const SHINE: Color = Color(1.0, 1.0, 1.0, 0.28)
const BACK: Color = Color(0.13, 0.10, 0.15)
const FRAME: Color = Color(0.85, 0.74, 0.48)
const LEAF: Array[String] = [
	"...gg..",
	"..gGGg.",
	".gGGGg.",
	".gGGg..",
	"sgGg...",
	".s.....",
	"s......",
]
const LEAF_COLORS: Dictionary = {"g": Color(0.30, 0.58, 0.26), "G": Color(0.52, 0.82, 0.40), "s": Color(0.45, 0.32, 0.18)}

var _current: float = 0.0
var _maximum: float = 1.0


func _init() -> void:
	custom_minimum_size = Vector2(BAR_X + WIDTH + 2.0, HEIGHT + 2.0)
	mouse_filter = Control.MOUSE_FILTER_IGNORE


func set_energy(current: float, maximum: float) -> void:
	_current = clampf(current, 0.0, maxf(maximum, 0.0))
	_maximum = maxf(maximum, 0.001)
	queue_redraw()


## How full it is, 0 to 1.
func fraction() -> float:
	return clampf(_current / _maximum, 0.0, 1.0)


func is_low() -> bool:
	return fraction() <= LOW


## How many pixels of a bar `width` wide are filled at `share` (0 to 1): none only when empty,
## all only when full.
static func filled_pixels(share: float, width: int) -> int:
	if share <= 0.0:
		return 0
	if share >= 1.0:
		return width
	return clampi(roundi(share * float(width)), 1, width - 1)


## Green when there's plenty, amber under a half, red when low.
static func color_for(share: float) -> Color:
	if share <= LOW:
		return LOW_COLOR
	return MID_COLOR if share < 0.5 else FULL_COLOR


func _draw() -> void:
	for y: int in LEAF.size():
		for x: int in LEAF[y].length():
			var pixel: String = LEAF[y][x]
			if pixel != ".":
				draw_rect(Rect2(x, y, 1, 1), LEAF_COLORS[pixel])
	draw_rect(Rect2(BAR_X, 0.0, WIDTH + 2.0, HEIGHT + 2.0), FRAME)
	draw_rect(Rect2(BAR_X + 1.0, 1.0, WIDTH, HEIGHT), BACK)
	var filled: int = filled_pixels(fraction(), WIDTH)
	if filled > 0:
		draw_rect(Rect2(BAR_X + 1.0, 1.0, filled, HEIGHT), color_for(fraction()))
		draw_rect(Rect2(BAR_X + 1.0, 1.0, filled, 1.0), SHINE)
