class_name PixelGrade
extends RefCounted
## The look of art pass 3 (docs/TECH_DESIGN.md §14), softened in P1c, pure: the warm grade every
## picture was baked with, for what the game draws in code to match it. Colours are warmed (a touch
## more saturated, lights tinted towards yellow, shadows towards violet), and code-drawn outlines use
## `INK`. Since the art became PNG (2026-11-19) the grade is in the PNGs themselves; the part that
## graded a picture as it was baked (outlines taking a shade of what they surround) retired with the
## art tools, to `tools/retired/pixel_grade_bake.gd`.

## The ink of outlines drawn in code (chests, doors, pickups, signposts, a petted animal's heart).
const INK: Color = Color(0.23, 0.16, 0.21)
## How much richer colours get (P1c: less than it was, for a softer picture).
const SATURATION: float = 1.05
## What dark colours are multiplied by, and what light ones are; between, a blend of the two.
const SHADOW_TINT: Color = Color(0.95, 0.95, 1.06)
const LIGHT_TINT: Color = Color(1.03, 1.005, 0.95)
## How close two colours must be to count as the same (a PNG stores 8 bits a channel).
const TOLERANCE: float = 0.012


## `color`, warmed. See-through colours keep their alpha; fully clear ones are left alone.
static func warm(color: Color) -> Color:
	if color.a == 0.0:
		return color
	var rich: Color = Color.from_hsv(color.h, minf(color.s * SATURATION, 1.0), color.v, color.a)
	var tint: Color = SHADOW_TINT.lerp(LIGHT_TINT, color.v)
	return Color(minf(rich.r * tint.r, 1.0), minf(rich.g * tint.g, 1.0), minf(rich.b * tint.b, 1.0), color.a)


## Whether two colours are the same but for rounding (alpha aside).
static func same(a: Color, b: Color) -> bool:
	return absf(a.r - b.r) < TOLERANCE and absf(a.g - b.g) < TOLERANCE and absf(a.b - b.b) < TOLERANCE
