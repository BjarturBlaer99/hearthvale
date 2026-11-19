# Retired with the art tools (2026-11-19): the whole PixelGrade as it was when the art was baked.
# class_name PixelGrade
extends RefCounted
## The look of art pass 3 (docs/TECH_DESIGN.md §14), softened in P1c, pure: what the art tools
## do to every picture as they bake it. Colours are warmed (a touch more saturated, lights
## tinted towards yellow, shadows towards violet), and outlines take a shade of what they
## surround in place of one near-black ink. Outlines are selective (P1c): a line on the edge of
## a shape, against clear pixels, is dark; a line inside a shape is only a little darker than
## what it runs through. Things drawn at runtime use `INK` and `warm()` to match.

## What an outline is with nothing coloured beside it, and the ink of things drawn in code.
const INK: Color = Color(0.23, 0.16, 0.21)
## The inside of a mass of outline colour (a dark doorway, a stairwell): it stays dark.
const DEEP: Color = Color(0.13, 0.09, 0.13)
## How much richer colours get (P1c: less than it was, for a softer picture).
const SATURATION: float = 1.05
## What dark colours are multiplied by, and what light ones are; between, a blend of the two.
const SHADOW_TINT: Color = Color(0.95, 0.95, 1.06)
const LIGHT_TINT: Color = Color(1.03, 1.005, 0.95)
## An outline's brightness and richness, against the colours beside it.
const OUTLINE_VALUE: float = 0.46
## No outline is darker than this, however dark the thing it surrounds: the line stays soft.
const OUTLINE_FLOOR: float = 0.13
const OUTLINE_SATURATION: float = 1.25
## How much of the ink is mixed into every outline, so they hold together.
const OUTLINE_INK: float = 0.2
## A line inside a shape (P1c): its brightness against the colours beside it, and its share
## of ink. Much lighter than an edge, so the shape reads as one thing.
const INNER_VALUE: float = 0.70
const INNER_INK: float = 0.06
## How close two colours must be to count as the same (a PNG stores 8 bits a channel).
const TOLERANCE: float = 0.012


## `color`, warmed. See-through colours keep their alpha; fully clear ones are left alone.
static func warm(color: Color) -> Color:
	if color.a == 0.0:
		return color
	var rich: Color = Color.from_hsv(color.h, minf(color.s * SATURATION, 1.0), color.v, color.a)
	var tint: Color = SHADOW_TINT.lerp(LIGHT_TINT, color.v)
	return Color(minf(rich.r * tint.r, 1.0), minf(rich.g * tint.g, 1.0), minf(rich.b * tint.b, 1.0), color.a)


## The colour of an outline pixel with `beside` around it (already warmed): a rich shade of
## their average, or the ink when there's nothing coloured beside it. On the `edge` of a shape
## it is dark; inside one it is only a little darker than what it runs through.
static func outline_for(beside: Array[Color], edge: bool = true) -> Color:
	if beside.is_empty():
		return INK
	var sum: Vector3 = Vector3.ZERO
	for color: Color in beside:
		sum += Vector3(color.r, color.g, color.b)
	var mean: Color = Color(sum.x / beside.size(), sum.y / beside.size(), sum.z / beside.size())
	var value: float = OUTLINE_VALUE if edge else INNER_VALUE
	var shade: Color = Color.from_hsv(mean.h, minf(mean.s * OUTLINE_SATURATION, 1.0), maxf(mean.v * value, OUTLINE_FLOOR))
	return shade.lerp(INK, OUTLINE_INK if edge else INNER_INK)


## Grades `image` in place: every pixel in `region` (the whole picture when empty) is warmed,
## and every pixel of the `outline` colour takes the shade of what's beside it. Pixels in
## `keep` colours are left exactly as they are and don't colour outlines (marker colours the
## game swaps later). With a `cell` size, an outline only looks at pixels in its own cell (a
## tile's neighbours in an atlas are other tiles).
static func apply(image: Image, outline: Color, region: Rect2i = Rect2i(), cell: Vector2i = Vector2i.ZERO,
		keep: Array[Color] = []) -> void:
	var area: Rect2i = region if region.size != Vector2i.ZERO else Rect2i(Vector2i.ZERO, image.get_size())
	var source: Image = image.duplicate()
	for y: int in range(area.position.y, area.end.y):
		for x: int in range(area.position.x, area.end.x):
			var pixel: Color = source.get_pixel(x, y)
			if pixel.a == 0.0 or _among(pixel, keep):
				continue
			if pixel.a == 1.0 and same(pixel, outline):
				var at: Vector2i = Vector2i(x, y)
				var beside: Array[Color] = _beside(source, at, area, cell, outline, keep)
				if beside.is_empty() and _buried(source, at, area, cell, outline):
					image.set_pixel(x, y, DEEP)
				else:
					image.set_pixel(x, y, outline_for(beside, _on_edge(source, at, area, cell)))
			else:
				image.set_pixel(x, y, warm(pixel))


## Whether two colours are the same but for rounding (alpha aside).
static func same(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) < TOLERANCE and absf(a.g - b.g) < TOLERANCE and absf(a.b - b.b) < TOLERANCE


## The solid, coloured pixels around `at`, warmed: not clear or see-through, not outline, not
## kept, inside `area` and, with a `cell` size, in the same cell as `at`.
static func _beside(source: Image, at: Vector2i, area: Rect2i, cell: Vector2i, outline: Color,
		keep: Array[Color]) -> Array[Color]:
	var out: Array[Color] = []
	for dy: int in [-1, 0, 1]:
		for dx: int in [-1, 0, 1]:
			var there: Vector2i = at + Vector2i(dx, dy)
			if there == at or not area.has_point(there):
				continue
			@warning_ignore("integer_division")
			if cell != Vector2i.ZERO and Vector2i(there.x / cell.x, there.y / cell.y) != Vector2i(at.x / cell.x, at.y / cell.y):
				continue
			var pixel: Color = source.get_pixel(there.x, there.y)
			if pixel.a < 1.0 or same(pixel, outline) or _among(pixel, keep):
				continue
			out.append(warm(pixel))
	return out


## Whether the pixel at `at` is on the edge of its shape: one of the pixels round it (in `area`,
## and in its cell) is clear or see-through. A picture with no clear pixels has no edges.
static func _on_edge(source: Image, at: Vector2i, area: Rect2i, cell: Vector2i) -> bool:
	for dy: int in [-1, 0, 1]:
		for dx: int in [-1, 0, 1]:
			var there: Vector2i = at + Vector2i(dx, dy)
			if there == at or not area.has_point(there):
				continue
			@warning_ignore("integer_division")
			if cell != Vector2i.ZERO and Vector2i(there.x / cell.x, there.y / cell.y) != Vector2i(at.x / cell.x, at.y / cell.y):
				continue
			if source.get_pixel(there.x, there.y).a < 1.0:
				return true
	return false


## Whether every pixel around `at` (in `area`, and in its cell) is solid outline colour too.
static func _buried(source: Image, at: Vector2i, area: Rect2i, cell: Vector2i, outline: Color) -> bool:
	for dy: int in [-1, 0, 1]:
		for dx: int in [-1, 0, 1]:
			var there: Vector2i = at + Vector2i(dx, dy)
			if there == at or not area.has_point(there):
				continue
			@warning_ignore("integer_division")
			if cell != Vector2i.ZERO and Vector2i(there.x / cell.x, there.y / cell.y) != Vector2i(at.x / cell.x, at.y / cell.y):
				continue
			var pixel: Color = source.get_pixel(there.x, there.y)
			if pixel.a < 1.0 or not same(pixel, outline):
				return false
	return true


static func _among(pixel: Color, colors: Array[Color]) -> bool:
	for color: Color in colors:
		if same(pixel, color):
			return true
	return false
