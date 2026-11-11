class_name Glows
extends Node2D
## The warm light around things that burn or shine (art pass 4): soft rounds of colour added
## over the tiles and actors, under the dark. The area gives it the glows of its tiles once
## (Ambience.tile_glows) and asks `moving` every frame for the ones that come and go (torches,
## crystals). Fires flicker. Made in code: one small round texture, drawn at each light.

const SIZE: int = 64
## How much a flickering glow breathes, and how fast.
const FLICKER: float = 0.07
const FLICKER_SPEED: float = 7.0

## Glows that never change (Ambience.glow dictionaries).
var fixed: Array = []
## Returns the glows that come and go; unset: none.
var moving: Callable
## The glows last drawn (for tests).
var shown: Array = []

var _round: GradientTexture2D
var _clock: float = 0.0


func _init() -> void:
	z_index = 30
	var blend: CanvasItemMaterial = CanvasItemMaterial.new()
	blend.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = blend
	var fade: Gradient = Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.35, 1.0])
	fade.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 0.45), Color(1, 1, 1, 0)])
	_round = GradientTexture2D.new()
	_round.gradient = fade
	_round.width = SIZE
	_round.height = SIZE
	_round.fill = GradientTexture2D.FILL_RADIAL
	_round.fill_from = Vector2(0.5, 0.5)
	_round.fill_to = Vector2(1.0, 0.5)


## A frame for `glows` that draws nothing outside `rect` (the map, in area pixels), so light
## doesn't spill into the black around a room. Add the frame to the area, not the glows.
static func framed(glows: Glows, rect: Rect2) -> Control:
	var frame: Control = Control.new()
	frame.name = "GlowFrame"
	frame.position = rect.position
	frame.size = rect.size
	frame.clip_contents = true
	frame.mouse_filter = Control.MOUSE_FILTER_IGNORE
	frame.z_index = glows.z_index
	glows.z_index = 0
	glows.position = -rect.position
	frame.add_child(glows)
	return frame


## Every glow there is right now.
func all() -> Array:
	var out: Array = fixed.duplicate()
	if moving.is_valid():
		out.append_array(moving.call())
	return out


func _process(delta: float) -> void:
	_clock += delta
	queue_redraw()


func _draw() -> void:
	shown = all()
	for i: int in shown.size():
		var one: Dictionary = shown[i]
		var radius: float = float(one["radius"])
		var strength: float = float(one["strength"])
		if one["flickers"]:
			var breath: float = sin(_clock * FLICKER_SPEED + float(i) * 1.7) * 0.6 + sin(_clock * FLICKER_SPEED * 2.3 + float(i)) * 0.4
			radius *= 1.0 + FLICKER * breath
			strength *= 1.0 + FLICKER * breath
		var at: Vector2 = one["at"]
		draw_texture_rect(_round, Rect2(at - Vector2(radius, radius), Vector2(radius, radius) * 2.0), false, Color(one["color"], strength))
