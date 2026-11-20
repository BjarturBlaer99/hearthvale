class_name ClockDial
extends Control
## The clock's dial in the HUD (new art, step 4, N6), beside the corner's box: a watch face with
## day (a sun) on its left half and night (a moon) on its right, and one hand that goes round
## once a day. The hand points down at dawn (06:00), into the sun at noon, up at dusk (18:00) and
## into the night at midnight; it moves in the clock's own steps of ten minutes. For show only:
## the time is GameState's, and the HUD's line still says it in words.

## The hand's colour, and its pivot's.
const HAND: Color = Color("4e2e1f")
const PIVOT: Color = Color("e7c072")
## Minutes in a day, and the time the hand points straight up.
const DAY: float = 1440.0
const UP_AT: float = 18.0 * 60.0
## The clock shows the time in steps of this many minutes (as DayClock.shown does).
const STEP: float = 10.0

var _minute: float = -1.0


func _init() -> void:
	custom_minimum_size = UiParts.DIAL.size
	size = UiParts.DIAL.size
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Shows the time `minute` (GameState.minute: minutes from midnight; after midnight it runs past
## 1440).
func set_minute(minute: float) -> void:
	var stepped: float = floorf(minute / STEP) * STEP
	if stepped == _minute:
		return
	_minute = stepped
	queue_redraw()


func minute() -> float:
	return _minute


## The hand's angle at `minute`, clockwise from straight up (radians, 0 to TAU).
static func hand_angle(minute: float) -> float:
	var stepped: float = floorf(minute / STEP) * STEP
	return fposmod((stepped - UP_AT) / DAY, 1.0) * TAU


## The way the hand points at `minute`, on the screen (y grows downward).
static func hand_direction(minute: float) -> Vector2:
	var angle: float = hand_angle(minute)
	return Vector2(sin(angle), -cos(angle))


## The pixels of the hand at `minute`, in the dial's own picture: a line from its middle.
static func hand_cells(minute: float) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var way: Vector2 = hand_direction(minute)
	for i: int in range(1, int(UiParts.HAND_LENGTH) + 1):
		var cell: Vector2i = Vector2i((UiParts.DIAL_CENTRE + way * float(i) - Vector2(0.5, 0.5)).round())
		if not out.has(cell):
			out.append(cell)
	return out


func _draw() -> void:
	draw_texture_rect_region(UiParts.texture(), Rect2(Vector2.ZERO, UiParts.DIAL.size), UiParts.DIAL)
	if _minute < 0.0:
		return
	for cell: Vector2i in hand_cells(_minute):
		draw_rect(Rect2(Vector2(cell), Vector2.ONE), HAND)
	draw_rect(Rect2(UiParts.DIAL_CENTRE - Vector2(1.0, 1.0), Vector2(2.0, 2.0)), PIVOT)
