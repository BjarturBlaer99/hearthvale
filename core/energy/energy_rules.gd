class_name EnergyRules
extends RefCounted
## The rules of the hero's energy (P2c, GDD §5), read from data (data/rules/energy.json): how
## big the bar is, what things cost, when he is tired and what that does, and what collapsing
## costs. Pure: it keeps no energy itself. GameState holds the hero's energy and asks this.
##
## Energy is apart from hearts: nothing here ever touches a heart.

## What a missing rule falls back to (a test checks they are the game's own rules).
const DEFAULTS: Dictionary = {
	"maximum": 100.0,
	"costs": {"sprint_per_second": 0.25, "swing": 0.5, "shot": 0.5},
	"low": {"below": 25.0, "move": 0.85, "cooldown": 1.3},
	"no_sprint_below": 10.0,
	"collapse": {"wake_share": 0.5, "coins_lost_share": 0.1, "coins_lost_most": 30},
}
## The costs the game asks for: running a second, a swing of the sword, a shot of the bow.
const SPRINT: String = "sprint_per_second"
const SWING: String = "swing"
const SHOT: String = "shot"

## A full bar.
var maximum: float
## Under this he is tired: he moves at `low_move` of his speed, and the sword's cooldown is
## `low_cooldown` times as long.
var low_below: float
var low_move: float
var low_cooldown: float
## Under this he can't sprint.
var no_sprint_below: float
## Collapsing: the share of a full bar he wakes with, the share of his coins he loses, and the
## most coins that can be.
var wake_share: float
var coins_lost_share: float
var coins_lost_most: int

var _costs: Dictionary = {}


func _init(rules: Dictionary = {}) -> void:
	maximum = maxf(float(rules.get("maximum", DEFAULTS["maximum"])), 1.0)
	_costs = _part(rules, "costs")
	var low: Dictionary = _part(rules, "low")
	low_below = float(low["below"])
	low_move = float(low["move"])
	low_cooldown = float(low["cooldown"])
	no_sprint_below = float(rules.get("no_sprint_below", DEFAULTS["no_sprint_below"]))
	var collapse: Dictionary = _part(rules, "collapse")
	wake_share = float(collapse["wake_share"])
	coins_lost_share = float(collapse["coins_lost_share"])
	coins_lost_most = int(collapse["coins_lost_most"])


## What `action` costs (SPRINT is by the second). Something the rules don't name is free.
func cost(action: String) -> float:
	return maxf(float(_costs.get(action, 0.0)), 0.0)


## `energy` after spending `amount`: never under nothing, never over a full bar.
func after(energy: float, amount: float) -> float:
	return clampf(energy - amount, 0.0, maximum)


## Whether he is tired at `energy`.
func is_low(energy: float) -> bool:
	return energy < low_below


## Whether he has the energy to sprint.
func can_sprint(energy: float) -> bool:
	return energy >= no_sprint_below


## Whether he has none left: he collapses.
func is_spent(energy: float) -> bool:
	return energy <= 0.0


## The share of his speed he moves at.
func move_factor(energy: float) -> float:
	return low_move if is_low(energy) else 1.0


## What the sword's cooldown is multiplied by.
func cooldown_factor(energy: float) -> float:
	return low_cooldown if is_low(energy) else 1.0


## The energy he wakes with after collapsing.
func wake_energy() -> float:
	return maximum * wake_share


## How many of `coins` he loses by collapsing: a share of them, rounded down, and no more than
## the most the rules allow.
func coins_lost(coins: int) -> int:
	return clampi(floori(maxi(coins, 0) * coins_lost_share), 0, coins_lost_most)


## What is wrong with `rules` as energy rules, in words: nothing, if they can be used.
static func problems(rules: Dictionary) -> PackedStringArray:
	var out: PackedStringArray = []
	if not _is_number(rules.get("maximum")) or float(rules["maximum"]) <= 0.0:
		out.append("'maximum' must be a number above 0.")
	var costs: Variant = rules.get("costs")
	if typeof(costs) != TYPE_DICTIONARY:
		out.append("'costs' must be an object of what things cost.")
	else:
		for action: String in [SPRINT, SWING, SHOT]:
			if not _is_number((costs as Dictionary).get(action)) or float(costs[action]) < 0.0:
				out.append("'costs' needs '%s', a number of 0 or more." % action)
	var low: Variant = rules.get("low")
	if typeof(low) != TYPE_DICTIONARY or not _is_number((low as Dictionary).get("below")):
		out.append("'low' needs 'below', the energy under which the hero is tired.")
	else:
		if not _is_number((low as Dictionary).get("move")) or float(low["move"]) <= 0.0 or float(low["move"]) > 1.0:
			out.append("'low' needs 'move', the share of his speed he keeps (above 0, at most 1).")
		if not _is_number((low as Dictionary).get("cooldown")) or float(low["cooldown"]) < 1.0:
			out.append("'low' needs 'cooldown', what the sword's cooldown is multiplied by (1 or more).")
	if not _is_number(rules.get("no_sprint_below")) or float(rules["no_sprint_below"]) < 0.0:
		out.append("'no_sprint_below' must be a number of 0 or more.")
	elif _is_number(rules.get("maximum")) and float(rules["no_sprint_below"]) >= float(rules["maximum"]):
		out.append("'no_sprint_below' must be under 'maximum', or the hero could never sprint.")
	var collapse: Variant = rules.get("collapse")
	if typeof(collapse) != TYPE_DICTIONARY:
		out.append("'collapse' must be an object: 'wake_share', 'coins_lost_share', 'coins_lost_most'.")
	else:
		for share: String in ["wake_share", "coins_lost_share"]:
			if not _is_number((collapse as Dictionary).get(share)) or float(collapse[share]) < 0.0 or float(collapse[share]) > 1.0:
				out.append("'collapse' needs '%s', a share from 0 to 1." % share)
		if _is_number((collapse as Dictionary).get("wake_share")) and float(collapse["wake_share"]) <= 0.0:
			out.append("'collapse' 'wake_share' must be above 0, or he would wake only to collapse again.")
		if not _is_number((collapse as Dictionary).get("coins_lost_most")) or float(collapse["coins_lost_most"]) < 0.0:
			out.append("'collapse' needs 'coins_lost_most', a number of 0 or more.")
	return out


## The part of `rules` called `key`, with the fallback for anything it leaves out.
static func _part(rules: Dictionary, key: String) -> Dictionary:
	var out: Dictionary = (DEFAULTS[key] as Dictionary).duplicate()
	var given: Variant = rules.get(key)
	if typeof(given) == TYPE_DICTIONARY:
		out.merge(given, true)
	return out


static func _is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT
