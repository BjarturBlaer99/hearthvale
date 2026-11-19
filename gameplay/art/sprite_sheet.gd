class_name SpriteSheet
extends RefCounted
## Draws frames from the sprite strips of gameplay/art/ (docs/TECH_DESIGN.md §14). A strip holds
## its frames side by side, in the order art/sheets.json lists them, painted on the
## top row and as white silhouettes on the bottom row (for hit flashes). It can also swap a
## sheet's marker colours (a villager's robe and hair), caching each look.

## How close a pixel must be to a marker colour to be swapped (PNG stores 8 bits a channel).
const MARKER_TOLERANCE: float = 0.01

static var _recoloured: Dictionary = {}


## Draws frame `index` of `texture` (frames of `size` px) on `canvas`, its top-left at `origin`:
## mirrored left to right with `flip_h`, as a white silhouette with `white`, tinted by `tint`.
static func draw(canvas: CanvasItem, texture: Texture2D, index: int, size: Vector2i, origin: Vector2,
		flip_h: bool = false, white: bool = false, tint: Color = Color.WHITE) -> void:
	var source: Rect2 = Rect2(Vector2(index * size.x, size.y if white else 0), Vector2(size))
	var target: Rect2 = Rect2(origin.round(), Vector2(size))
	if flip_h:
		# A negative width draws the frame mirrored.
		target = Rect2(origin.round() + Vector2(size.x, 0), Vector2(-size.x, size.y))
	canvas.draw_texture_rect_region(texture, target, source, tint)


## `texture` with each marker colour in `swaps` (marker -> colour) replaced, made once per `key`.
static func recoloured(texture: Texture2D, swaps: Dictionary, key: String) -> Texture2D:
	if _recoloured.has(key):
		return _recoloured[key]
	var image: Image = texture.get_image()
	if image.is_compressed():
		image.decompress()
	for y: int in image.get_height():
		for x: int in image.get_width():
			var pixel: Color = image.get_pixel(x, y)
			if pixel.a == 0.0:
				continue
			for marker: Color in swaps:
				if _close(pixel, marker):
					image.set_pixel(x, y, swaps[marker])
					break
	var out: ImageTexture = ImageTexture.create_from_image(image)
	_recoloured[key] = out
	return out


static func _close(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) < MARKER_TOLERANCE and absf(a.g - b.g) < MARKER_TOLERANCE \
		and absf(a.b - b.b) < MARKER_TOLERANCE
