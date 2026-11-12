class_name TitleBackdrop
extends Control
## The title screen's picture (P1f): an evening over Hearthvale, painted by
## tools/art/make_title.gd (TitlePicture has the layout), with what moves drawn over it: stars
## that twinkle, the light in the old keep's window, and cherry petals on the wind. The ending
## screen shows the same picture with the window dark.

const LIGHT: Color = Color(1.0, 0.82, 0.40)
const STAR: Color = Color(1.0, 1.0, 0.92)
## Petals in the air at once, and how long each drifts (seconds).
const PETALS: int = 18
const PETAL_LIFE: float = 9.0

## Whether the keep's window is lit. It's dark on the ending screen, and on the title once
## the save says the game was finished.
@export var keep_lit: bool = true

var _clock: float = 0.0
var _picture: Texture2D
var _petals: CPUParticles2D


func _ready() -> void:
	_picture = load(TitlePicture.TEXTURE_PATH)
	_petals = _make_petals()
	add_child(_petals)
	resized.connect(_place_petals)
	_place_petals()


func _process(delta: float) -> void:
	_clock += delta
	queue_redraw()


## Where the picture's top left corner is drawn: in the middle from side to side, its foot on
## the foot of the screen. On a screen taller than the picture there is more sky above it.
func origin() -> Vector2:
	return Vector2(floorf((size.x - TitlePicture.SIZE.x) / 2.0), size.y - TitlePicture.SIZE.y)


## The keep's window on the screen.
func window() -> Rect2:
	return Rect2(origin() + Vector2(TitlePicture.WINDOW.position), TitlePicture.WINDOW.size)


## How bright the star at `star` is now (0-1): each twinkles in its own time.
func twinkle(star: Vector2i) -> float:
	return 0.5 + 0.5 * sin(_clock * 2.0 + star.x * 0.7)


func _draw() -> void:
	var at: Vector2 = origin()
	draw_rect(Rect2(Vector2.ZERO, size), PixelGrade.warm(TitlePicture.SKY_TOP))
	draw_texture(_picture, at)
	for star: Vector2i in TitlePicture.STARS:
		draw_rect(Rect2(at + Vector2(star), Vector2.ONE), Color(STAR, 0.15 + 0.85 * twinkle(star)))
	if keep_lit:
		var glow: float = 0.75 + 0.25 * sin(_clock * 3.1)
		draw_rect(window().grow(3.0), Color(LIGHT, 0.10 * glow))
		draw_rect(window().grow(1.0), Color(LIGHT, 0.24 * glow))
		draw_rect(window(), Color(LIGHT, glow))


## Petals leave the village's cherry trees and drift east across the picture.
func _make_petals() -> CPUParticles2D:
	var drift: CPUParticles2D = CPUParticles2D.new()
	drift.name = "Petals"
	drift.amount = PETALS
	drift.lifetime = PETAL_LIFE
	drift.preprocess = PETAL_LIFE
	drift.randomness = 1.0
	drift.emission_shape = CPUParticles2D.EMISSION_SHAPE_POINTS
	drift.emission_points = PackedVector2Array(TitlePicture.crowns())
	drift.direction = Vector2(1.0, 0.25)
	drift.spread = 30.0
	drift.gravity = Vector2(2.0, 1.5)
	drift.initial_velocity_min = 6.0
	drift.initial_velocity_max = 16.0
	var pinks: Gradient = Gradient.new()
	pinks.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	pinks.colors = PackedColorArray([Petals.PINKS[0], Petals.PINKS[1], Petals.PINKS[2]])
	drift.color_initial_ramp = pinks
	var fade: Gradient = Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.1, 0.8, 1.0])
	fade.colors = PackedColorArray([Color(1, 1, 1, 0), Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	drift.color_ramp = fade
	return drift


func _place_petals() -> void:
	_petals.position = origin()
