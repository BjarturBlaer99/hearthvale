class_name LightRules
extends RefCounted
## How much light reaches a point in a dark area (docs/TECH_DESIGN.md §6), pure. A light is
## { "at": Vector2 (area pixels), "radius": float (px) }: full strength out to CORE of its
## radius, then fading to nothing at its edge. Lights don't add up: the brightest one counts.
## The Darkness overlay draws what this works out; tests and the area ask it directly.

## The share of a light's radius that is fully lit.
const CORE: float = 0.55


static func light(at: Vector2, radius: float) -> Dictionary:
	return {"at": at, "radius": radius}


## 0 (dark) to 1 (fully lit) at `point`.
static func brightness(point: Vector2, lights: Array) -> float:
	var best: float = 0.0
	for entry: Variant in lights:
		var radius: float = float((entry as Dictionary).get("radius", 0.0))
		if radius <= 0.0:
			continue
		var reach: float = point.distance_to((entry as Dictionary).get("at", Vector2.ZERO)) / radius
		best = maxf(best, clampf((1.0 - reach) / (1.0 - CORE), 0.0, 1.0))
	return best


static func is_lit(point: Vector2, lights: Array) -> bool:
	return brightness(point, lights) > 0.0


## The lights that reach into `rect` (the room on screen), widest first, at most `limit`: the
## overlay can only draw so many.
static func reaching(rect: Rect2, lights: Array, limit: int) -> Array:
	var out: Array = []
	for entry: Variant in lights:
		var at: Vector2 = (entry as Dictionary).get("at", Vector2.ZERO)
		var radius: float = float((entry as Dictionary).get("radius", 0.0))
		if radius > 0.0 and rect.grow(radius).has_point(at):
			out.append(entry)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool: return float(a["radius"]) > float(b["radius"]))
	return out.slice(0, maxi(limit, 0))
