class_name CombatRules
extends RefCounted
## Pure combat geometry and rules (docs/TECH_DESIGN.md §4). Hitboxes and hurtboxes are circles;
## the sword's hitbox is a slice of a circle pointing the way the hero faces.

## How far the sword reaches from the hero's feet (px), and the swing's width.
const SWORD_REACH: float = 20.0
const SWORD_ARC_DEGREES: float = 120.0
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
