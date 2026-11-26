class_name EnergyBar
extends Control
## The hero's energy as a bar (GDD §5), under the hearts in the HUD's corner: a gold bolt, then
## a framed bar (new art, step 4: PixelLab's UI sheet's bolt, wood and green, cut in segments) that empties from the right and turns from green to amber to red as it runs
## low. Drawn in whole pixels. It only shows what it is told; the energy rules come in P2, and
## until then the HUD keeps it hidden.

## The bar's inside, in pixels.
const WIDTH: int = 64
const HEIGHT: int = 5
## Where the bar starts, after the leaf.
const BAR_X: float = 9.0
## At or under this share of the whole, energy counts as low.
const LOW: float = 0.25
## The Ninja Adventure pack's colours (the farm look's phase C): its grass green, its gold and
## its heart red, in a slot of its dark slate framed in its wood's orange.
const FULL_COLOR: Color = Color("74a334")
const MID_COLOR: Color = Color("f1c471")
const LOW_COLOR: Color = Color("e0394c")
const SHINE: Color = Color(1.0, 1.0, 1.0, 0.28)
const BACK: Color = Color("3b3643")
const FRAME: Color = Color("f06733")
## The line between two segments of the bar, darker than what fills it.
const SEGMENT: int = 8
const SEGMENT_LINE: Color = Color(0.0, 0.0, 0.0, 0.22)
const BOLT: Array[String] = [
	"....oo.",
	"...oYo.",
	"..oYo..",
	".oYYYo.",
	"..oYo..",
	".oYo...",
	".oo....",
]
const BOLT_COLORS: Dictionary = {"o": Color("141b1b"), "Y": Color("ffe18d")}

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
	for y: int in BOLT.size():
		for x: int in BOLT[y].length():
			var pixel: String = BOLT[y][x]
			if pixel != ".":
				draw_rect(Rect2(x, y, 1, 1), BOLT_COLORS[pixel])
	draw_rect(Rect2(BAR_X, 0.0, WIDTH + 2.0, HEIGHT + 2.0), FRAME)
	draw_rect(Rect2(BAR_X + 1.0, 1.0, WIDTH, HEIGHT), BACK)
	var filled: int = filled_pixels(fraction(), WIDTH)
	if filled > 0:
		draw_rect(Rect2(BAR_X + 1.0, 1.0, filled, HEIGHT), color_for(fraction()))
		draw_rect(Rect2(BAR_X + 1.0, 1.0, filled, 1.0), SHINE)
		for at: int in range(SEGMENT, filled, SEGMENT):
			draw_rect(Rect2(BAR_X + 1.0 + at, 1.0, 1.0, HEIGHT), SEGMENT_LINE)
