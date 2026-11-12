class_name TitleBackdrop
extends Control
## The title screen's picture, painted in code (placeholder art): an evening sky, the old keep
## on a far hill with one window lit, rolling hills, and the roofs of Hearthvale below.

const SKY_TOP: Color = Color(0.10, 0.12, 0.26)
const SKY_LOW: Color = Color(0.86, 0.52, 0.36)
const HILL_FAR: Color = Color(0.22, 0.26, 0.34)
const HILL_MID: Color = Color(0.18, 0.34, 0.24)
const HILL_NEAR: Color = Color(0.14, 0.27, 0.17)
const KEEP: Color = Color(0.12, 0.12, 0.17)
const LIGHT: Color = Color(1.0, 0.82, 0.40)

## Whether the keep's window is lit. It's dark on the ending screen, and on the title once
## the save says the game was finished.
@export var keep_lit: bool = true

var _clock: float = 0.0


func _process(delta: float) -> void:
	_clock += delta
	queue_redraw()


func _draw() -> void:
	var size_now: Vector2 = size
	# Stars and houses were placed for a screen 480 wide: they spread out over a wider one.
	var wide: float = size_now.x / 480.0
	# The sky, in bands from night above to sunset at the horizon.
	for i: int in 18:
		var t: float = i / 17.0
		draw_rect(Rect2(0, size_now.y * 0.62 * t, size_now.x, size_now.y * 0.62 / 17.0 + 1.0), SKY_TOP.lerp(SKY_LOW, t * t))
	for star: Vector2 in [Vector2(40, 18), Vector2(96, 30), Vector2(150, 12), Vector2(300, 22), Vector2(372, 14), Vector2(430, 34), Vector2(210, 40)]:
		var twinkle: float = 0.5 + 0.5 * sin(_clock * 2.0 + star.x)
		draw_rect(Rect2(Vector2(roundf(star.x * wide), star.y), Vector2(1, 1)), Color(1, 1, 0.9, 0.4 + 0.5 * twinkle))
	# The far hill and the keep on it.
	_hill(size_now.y * 0.60, 26.0, 0.012, 1.0, HILL_FAR)
	var base: Vector2 = Vector2(size_now.x * 0.72, size_now.y * 0.50)
	draw_rect(Rect2(base + Vector2(-26, -30), Vector2(52, 32)), KEEP)
	for tower: float in [-30.0, 22.0]:
		draw_rect(Rect2(base + Vector2(tower, -44), Vector2(10, 46)), KEEP)
		for notch: int in 3:
			draw_rect(Rect2(base + Vector2(tower + notch * 4.0 - 1.0, -48), Vector2(2, 4)), KEEP)
	for notch: int in 7:
		draw_rect(Rect2(base + Vector2(-24 + notch * 7.0, -34), Vector2(4, 4)), KEEP)
	if keep_lit:
		var glow: float = 0.75 + 0.25 * sin(_clock * 3.1)
		draw_rect(Rect2(base + Vector2(-3, -20), Vector2(4, 6)), Color(LIGHT, glow))
		draw_circle(base + Vector2(-1, -17), 6.0, Color(LIGHT, 0.12 * glow))
	# Nearer hills, with trees along the middle one.
	_hill(size_now.y * 0.70, 18.0, 0.020, 2.3, HILL_MID)
	for x: int in range(6, int(size_now.x), 23):
		var y: float = size_now.y * 0.70 - 18.0 * (0.5 + 0.5 * sin(x * 0.020 + 2.3)) + 4.0
		draw_circle(Vector2(x, y - 5.0), 5.0, HILL_MID.darkened(0.25))
		draw_rect(Rect2(x - 1.0, y - 2.0, 2.0, 4.0), Color(0.25, 0.17, 0.10))
	_hill(size_now.y * 0.84, 14.0, 0.028, 0.6, HILL_NEAR)
	# Hearthvale's roofs in the foreground.
	for house: Vector3 in [Vector3(48, 0, 0), Vector3(92, 6, 1), Vector3(140, 2, 0), Vector3(372, 4, 1), Vector3(420, 0, 0)]:
		_house(Vector2(roundf(house.x * wide), size_now.y * 0.86 + house.y), house.z > 0.0)


func _hill(top: float, height: float, frequency: float, phase: float, color: Color) -> void:
	var points: PackedVector2Array = [Vector2(0, size.y)]
	for x: int in range(0, int(size.x) + 8, 8):
		points.append(Vector2(x, top - height * (0.5 + 0.5 * sin(x * frequency + phase))))
	points.append(Vector2(size.x, size.y))
	draw_colored_polygon(points, color)


func _house(at: Vector2, blue: bool) -> void:
	var roof: Color = Color(0.32, 0.38, 0.62) if blue else Color(0.66, 0.26, 0.20)
	draw_rect(Rect2(at + Vector2(-12, -8), Vector2(24, 12)), Color(0.84, 0.78, 0.64))
	draw_colored_polygon(PackedVector2Array([at + Vector2(-15, -8), at + Vector2(0, -20), at + Vector2(15, -8)]), roof)
	draw_rect(Rect2(at + Vector2(-3, -3), Vector2(6, 7)), Color(0.36, 0.22, 0.12))
	draw_rect(Rect2(at + Vector2(6, -5), Vector2(3, 3)), Color(LIGHT, 0.9))
