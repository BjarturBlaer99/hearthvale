class_name Motes
extends Node2D
## Specks in the air (art pass 4): pollen drifting over the fields, dust hanging in a house or
## a dungeon. A few single pixels that drift, sway and fade in and out, wrapped around the
## screen so there are always some in view. For show only.

## The patch of air the specks live in (px): a little more than the 640x360 screen.
const FIELD: Vector2 = Vector2(672, 392)

## By Ambience kind: [how many, colour, drift (px/s), sway (px)].
const LOOKS: Dictionary = {
	&"outdoor": [24, Color(1.0, 0.97, 0.72, 0.55), Vector2(5.0, 2.0), 5.0],
	&"interior": [9, Color(1.0, 0.92, 0.75, 0.30), Vector2(1.0, 1.5), 2.0],
	&"dungeon": [12, Color(0.80, 0.82, 0.95, 0.28), Vector2(-1.5, 1.0), 3.0],
}

var kind: StringName = &"outdoor"
var _clock: float = 0.0


func _init() -> void:
	z_index = 35


func count() -> int:
	return int((LOOKS.get(kind, LOOKS[&"outdoor"]) as Array)[0])


## Where speck `index` is `seconds` in, inside FIELD (the same for the same inputs).
static func speck_at(index: int, seconds: float, drift: Vector2, sway: float) -> Vector2:
	var seed_x: float = fposmod(float(index) * 197.3 + 31.0, FIELD.x)
	var seed_y: float = fposmod(float(index) * 113.7 + 57.0, FIELD.y)
	var pace: float = 0.6 + fposmod(float(index) * 0.37, 0.8)
	var x: float = seed_x + drift.x * pace * seconds + sin(seconds * 0.7 + float(index)) * sway
	var y: float = seed_y + drift.y * pace * seconds + cos(seconds * 0.5 + float(index) * 2.0) * sway * 0.6
	return Vector2(fposmod(x, FIELD.x), fposmod(y, FIELD.y))


func _process(delta: float) -> void:
	_clock += delta
	queue_redraw()


func _draw() -> void:
	var look: Array = LOOKS.get(kind, LOOKS[&"outdoor"])
	var camera: Camera2D = get_viewport().get_camera_2d()
	var middle: Vector2 = camera.get_screen_center_position() if camera != null else FIELD * 0.5
	var corner: Vector2 = (middle - FIELD * 0.5).floor()
	# The field is pinned to the world, so specks stay put as the camera moves past them.
	var shift: Vector2 = Vector2(fposmod(corner.x, FIELD.x), fposmod(corner.y, FIELD.y))
	for i: int in int(look[0]):
		var at: Vector2 = speck_at(i, _clock, look[2], look[3])
		at = Vector2(fposmod(at.x - shift.x, FIELD.x), fposmod(at.y - shift.y, FIELD.y)) + corner
		var twinkle: float = 0.55 + 0.45 * sin(_clock * 1.3 + float(i) * 2.1)
		draw_rect(Rect2(at.floor(), Vector2.ONE), Color(look[1], (look[1] as Color).a * twinkle))
