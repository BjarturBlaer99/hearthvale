class_name SoftShadow
extends RefCounted
## The shadow under anything that stands on the ground (P1b): a dark heart and a fainter rim,
## tinted violet like every shadow in the game. One helper, so heroes, monsters, pickups and
## props all sit on the ground the same way. Pure but for the drawing.

const COLOR: Color = Color(0.10, 0.05, 0.18)
## Each ring: how much of the full size it covers, and how dark it is. Drawn widest first.
const RINGS: Array = [[1.25, 0.11], [0.85, 0.17]]
const POINTS: int = 14


## The rings of a shadow `radii` wide and high at `strength`: [radii, alpha] each, widest first.
static func rings(radii: Vector2, strength: float = 1.0) -> Array:
	var out: Array = []
	for ring: Array in RINGS:
		out.append([radii * float(ring[0]), float(ring[1]) * strength])
	return out


## Draws the shadow on `canvas`, centred at `center` (the canvas's own coordinates).
static func draw(canvas: CanvasItem, center: Vector2, radii: Vector2, strength: float = 1.0) -> void:
	for ring: Array in rings(radii, strength):
		var size: Vector2 = ring[0]
		var outline: PackedVector2Array = PackedVector2Array()
		for i: int in POINTS:
			var angle: float = TAU * float(i) / float(POINTS)
			outline.append(center + Vector2(cos(angle) * size.x, sin(angle) * size.y))
		canvas.draw_colored_polygon(outline, Color(COLOR, float(ring[1])))
