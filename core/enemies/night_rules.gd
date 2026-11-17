class_name NightRules
extends RefCounted
## What the night does to a monster met out of doors (P2e, GDD §6), read from data
## (data/rules/night.json): more health, more speed, further sight, and coins more often among
## what it drops. Pure: strengthen() takes an enemy's data and returns a changed copy, which the
## enemy is then set up from. Bosses are left as they are, and so is an enemy that is only there
## by night (its "appears": the Bogwisp): its numbers are its night's already.

## What a missing rule falls back to (a test checks they are the game's own rules).
const DEFAULTS: Dictionary = {"health": 1.5, "speed": 1.15, "sight": 1.3, "coin_drops": 2.0}
const COIN: String = "coin"

## What each of an enemy's numbers is multiplied by (health is rounded up).
var health: float
var speed: float
var sight: float
## What the weight of each coin drop in its table is multiplied by.
var coin_drops: float


func _init(rules: Dictionary = {}) -> void:
	health = float(rules.get("health", DEFAULTS["health"]))
	speed = float(rules.get("speed", DEFAULTS["speed"]))
	sight = float(rules.get("sight", DEFAULTS["sight"]))
	coin_drops = float(rules.get("coin_drops", DEFAULTS["coin_drops"]))


## Whether `enemy` (an entry of data/enemies) is there only by night.
static func is_of_the_night(enemy: Dictionary) -> bool:
	return str(enemy.get("appears", "")) == "night"


## `enemy` (an entry of data/enemies) as it is at night: a copy, the original untouched.
func strengthen(enemy: Dictionary) -> Dictionary:
	var out: Dictionary = enemy.duplicate(true)
	if enemy.has("boss") or is_of_the_night(enemy):
		return out
	out["health"] = ceili(float(enemy.get("health", 1)) * health)
	out["speed"] = float(enemy.get("speed", 0.0)) * speed
	out["sight"] = float(enemy.get("sight", 64.0)) * sight
	for drop: Variant in out.get("drops", []):
		if typeof(drop) == TYPE_DICTIONARY and str((drop as Dictionary).get("type", "")) == "item" and str((drop as Dictionary).get("item", "")) == COIN:
			drop["weight"] = float(drop.get("weight", 0.0)) * coin_drops
	return out


## What is wrong with `rules` as the night's rules, in words: nothing, if they can be used.
static func problems(rules: Dictionary) -> PackedStringArray:
	var out: PackedStringArray = []
	for key: String in ["health", "speed", "sight", "coin_drops"]:
		var value: Variant = rules.get(key)
		if (typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT) or float(value) <= 0.0:
			out.append("'%s' must be a number above 0 (1 leaves things as by day)." % key)
	return out
