class_name DungeonRules
extends RefCounted
## What a dungeon does to the monsters in it (docs/progress/dungeon-difficulty-plan.md,
## decision 1), read from data (data/rules/dungeon.json): each place it names (a dungeon's id,
## or a quarry floor's area id) has its own numbers, so the first dungeon can be gentler than
## the last. Pure: strengthen() takes an enemy's data and the place, and returns a changed copy,
## which the enemy is then set up from. A place it doesn't name is left as it is, and so are
## bosses (they have numbers of their own) and an enemy that is only there by night (the
## Bogwisp: its numbers are its night's already).

## The numbers a place may give, and what a missing one falls back to (1: as in the fields).
const NUMBERS: Array[String] = ["health", "damage", "speed", "sight", "hearts", "shot_cooldown"]
const HEART: String = "heart"

## The places it names, each a Dictionary of NUMBERS.
var places: Dictionary = {}


func _init(rules: Dictionary = {}) -> void:
	var named: Variant = rules.get("places", {})
	if typeof(named) == TYPE_DICTIONARY:
		for place: Variant in named:
			places[StringName(str(place))] = named[place]


## Whether `place` (a dungeon's id or an area's) has numbers of its own.
func names(place: StringName) -> bool:
	return places.has(place)


## One of a place's NUMBERS (1 for a place it doesn't name, or a number it leaves out).
func number(place: StringName, key: String) -> float:
	var numbers: Variant = places.get(place, {})
	if typeof(numbers) != TYPE_DICTIONARY:
		return 1.0
	return float((numbers as Dictionary).get(key, 1.0))


## `enemy` (an entry of data/enemies) as it is in `place`: a copy, the original untouched.
## Health and damage are whole, rounded up; the weight of each heart drop in its table is
## multiplied by "hearts", and an archer's wait between shots by "shot_cooldown".
func strengthen(enemy: Dictionary, place: StringName) -> Dictionary:
	var out: Dictionary = enemy.duplicate(true)
	if not names(place) or enemy.has("boss") or NightRules.is_of_the_night(enemy):
		return out
	out["health"] = ceili(float(enemy.get("health", 1)) * number(place, "health"))
	out["contact_damage"] = ceili(float(enemy.get("contact_damage", 1)) * number(place, "damage"))
	out["speed"] = float(enemy.get("speed", 0.0)) * number(place, "speed")
	out["sight"] = float(enemy.get("sight", 64.0)) * number(place, "sight")
	if typeof(out.get("shot")) == TYPE_DICTIONARY:
		var shot: Dictionary = out["shot"]
		shot["damage"] = ceili(float(shot.get("damage", 1)) * number(place, "damage"))
		if shot.has("cooldown"):
			shot["cooldown"] = float(shot["cooldown"]) * number(place, "shot_cooldown")
	for drop: Variant in out.get("drops", []):
		if typeof(drop) == TYPE_DICTIONARY and str((drop as Dictionary).get("type", "")) == HEART:
			drop["weight"] = float(drop.get("weight", 0.0)) * number(place, "hearts")
	return out


## What is wrong with `rules` as the dungeons' rules, in words: nothing, if they can be used.
static func problems(rules: Dictionary) -> PackedStringArray:
	var out: PackedStringArray = []
	var named: Variant = rules.get("places")
	if typeof(named) != TYPE_DICTIONARY or (named as Dictionary).is_empty():
		out.append("'places' must name at least one place (a dungeon's id or an area's) and its numbers.")
		return out
	for place: Variant in named:
		var numbers: Variant = named[place]
		if typeof(numbers) != TYPE_DICTIONARY:
			out.append("place '%s' must be a dictionary of numbers." % place)
			continue
		for key: Variant in numbers:
			if not NUMBERS.has(str(key)):
				out.append("place '%s': unknown number '%s'. Known: %s." % [place, key, ", ".join(NUMBERS)])
				continue
			var value: Variant = numbers[key]
			if (typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT) or float(value) <= 0.0:
				out.append("place '%s': '%s' must be a number above 0 (1 leaves things as in the fields)." % [place, key])
	return out
