class_name CombatRules
extends RefCounted
## Pure combat geometry and rules (docs/TECH_DESIGN.md §4). Hitboxes and hurtboxes are circles;
## the sword's hitbox is a slice of a circle pointing the way the hero faces.

## How far the sword reaches from the hero's feet (px), and the swing's width. The reach was 20
## until the user asked for a longer one (2026-11-25): at 28 a swing reaches the cell two before
## him straight ahead (a target's own radius counts too), where it reached only the next.
const SWORD_REACH: float = 28.0
const SWORD_ARC_DEGREES: float = 120.0
## How finely clear_between() walks its line (px): well under a cell, so no cell is stepped over.
const LINE_STEP: float = 2.0
## How far into a blocking cell a line may pass and still be let by as a graze (px).
const GRAZE: float = 3.0
## Used when a weapon's data leaves a stat out.
const DEFAULT_WEAPON_STATS: Dictionary = {"damage": 1, "knockback": 0.0, "cooldown": 0.3}


static func circles_touch(a: Vector2, a_radius: float, b: Vector2, b_radius: float) -> bool:
	return a.distance_to(b) < a_radius + b_radius


## Whether a target circle is touched by the slice of a circle around `origin` (radius `reach`)
## that points along `facing` and spans `arc` radians. A target at the origin always counts.
static func in_arc(origin: Vector2, facing: Vector2, arc: float, reach: float, target: Vector2, target_radius: float) -> bool:
	var offset: Vector2 = target - origin
	if offset.length() - target_radius > reach:
		return false
	if offset.is_zero_approx() or facing.is_zero_approx():
		return true
	return absf(facing.angle_to(offset)) <= arc / 2.0


## Whether a blow from `from` reaches `to` with nothing in the way: no cell on the straight line
## between them, leaving out the cells at either end, is one `blocks` (a Callable(cell) -> bool)
## says stops it. A line that only grazes a blocking cell, within GRAZE px of an edge with open
## ground (or either end's cell) across it, is let by: a blow at something diagonally beside him
## isn't stopped by a wall's corner, but the seam between two walls lets nothing through. A sword
## stops at a wall as an arrow does (2026-11-25).
static func clear_between(from: Vector2, to: Vector2, blocks: Callable) -> bool:
	var first: Vector2i = GridBody.cell_of(from)
	var last: Vector2i = GridBody.cell_of(to)
	var stops: Callable = func(cell: Vector2i) -> bool:
		return cell != first and cell != last and bool(blocks.call(cell))
	var steps: int = ceili(from.distance_to(to) / LINE_STEP)
	for i: int in range(1, steps):
		var point: Vector2 = from.lerp(to, float(i) / float(steps))
		var cell: Vector2i = GridBody.cell_of(point)
		if not stops.call(cell):
			continue
		var inside: Vector2 = point - Vector2(cell) * GridBody.TILE
		var grazed: bool = (inside.x < GRAZE and not stops.call(cell + Vector2i.LEFT)) \
				or (GridBody.TILE - inside.x < GRAZE and not stops.call(cell + Vector2i.RIGHT)) \
				or (inside.y < GRAZE and not stops.call(cell + Vector2i.UP)) \
				or (GridBody.TILE - inside.y < GRAZE and not stops.call(cell + Vector2i.DOWN))
		if not grazed:
			return false
	return true


## Knockback for something at `target` hit from `source`: `distance` px straight away from the
## source, or along `fallback` when they're in the same spot.
static func push(source: Vector2, target: Vector2, distance: float, fallback: Vector2 = Vector2.DOWN) -> Vector2:
	var away: Vector2 = target - source
	if away.is_zero_approx():
		away = fallback
	return away.normalized() * distance if not away.is_zero_approx() else Vector2.ZERO


## The strongest melee weapon among held `stacks` ({ "id", "count" }, as in GameState.inventory),
## looked up in `items` (item entries from data). Ties go to the first in `items`. Empty if none.
static func best_melee_weapon(stacks: Array, items: Array) -> Dictionary:
	var held: Dictionary = {}
	for stack: Variant in stacks:
		if typeof(stack) == TYPE_DICTIONARY and int((stack as Dictionary).get("count", 0)) > 0:
			held[str((stack as Dictionary).get("id", ""))] = true
	var best: Dictionary = {}
	for item: Variant in items:
		if typeof(item) != TYPE_DICTIONARY:
			continue
		var entry: Dictionary = item
		if str(entry.get("type", "")) != "weapon_melee" or not held.has(str(entry.get("id", ""))):
			continue
		if best.is_empty() or float(weapon_stats(entry)["damage"]) > float(weapon_stats(best)["damage"]):
			best = entry
	return best


## A weapon item's damage, knockback and cooldown, with defaults for anything missing.
static func weapon_stats(item: Dictionary) -> Dictionary:
	var stats: Dictionary = DEFAULT_WEAPON_STATS.duplicate()
	var given: Variant = item.get("stats", {})
	if typeof(given) == TYPE_DICTIONARY:
		for key: String in DEFAULT_WEAPON_STATS:
			if (given as Dictionary).has(key):
				stats[key] = given[key]
	stats["damage"] = int(stats["damage"])
	stats["knockback"] = float(stats["knockback"])
	stats["cooldown"] = float(stats["cooldown"])
	return stats
