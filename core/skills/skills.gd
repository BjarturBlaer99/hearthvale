class_name Skills
extends RefCounted
## The hero's skills (P4b, GDD §5), pure: what raises each, the points a level begins at, and
## what a level does. The rules are data (data/rules/skills.json):
##   { "levels": [0, 10, 25, 50, 90], "step": 0.1,
##     "skills": { "farming": { "name": "Farming", "gains": { "till": 1, "harvest": 2 },
##                              "eases": ["hoe", "water"] }, ... } }
## A skill's points only grow, by its `gains` (the points a deed gives). Its level is how many
## of `levels` its points have reached. Each level above the first takes `step` off the energy
## of the work the skill `eases` (EnergyRules' costs), and for a skill that `enriches_dishes`
## adds `step` to the energy a cooked dish gives. It keeps no points itself: GameState holds
## them (skill id -> points) and asks this.
##
## A skill changes energy and nothing else: never hearts, damage, speed or timing.

const COMBAT: StringName = &"combat"
const FARMING: StringName = &"farming"
const COOKING: StringName = &"cooking"
## The deeds the game reports (GameState.practise): a skill's `gains` are named by them.
const MONSTER: StringName = &"monster"
const BOSS: StringName = &"boss"
const TILL: StringName = &"till"
const HARVEST: StringName = &"harvest"
const DISH: StringName = &"dish"
## What is said when a skill rises.
const RISEN_WORDS: String = "%s rose to level %d."
## What stands between two skills on the pause menu's line.
const LINE_GAP: String = "   "

## The points each level begins at, from the first (0) up.
var thresholds: Array[int] = [0]
## The share each level above the first takes off a cost, or adds to a dish.
var step: float = 0.0

## skill id -> its rules, in the order the data lists them.
var _skills: Dictionary = {}


func _init(rules: Dictionary = {}) -> void:
	var levels: Variant = rules.get("levels")
	if typeof(levels) == TYPE_ARRAY and not (levels as Array).is_empty():
		thresholds.clear()
		for at: Variant in levels:
			thresholds.append(int(at))
	step = maxf(float(rules.get("step", 0.0)), 0.0) if _is_number(rules.get("step")) else 0.0
	var listed: Variant = rules.get("skills")
	if typeof(listed) == TYPE_DICTIONARY:
		for id: Variant in listed:
			if typeof(listed[id]) == TYPE_DICTIONARY:
				_skills[StringName(str(id))] = listed[id]


## The skills, in the order the data lists them.
func ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for id: StringName in _skills:
		out.append(id)
	return out


func has_skill(skill: StringName) -> bool:
	return _skills.has(skill)


func name_of(skill: StringName) -> String:
	return str(_rules_of(skill).get("name", String(skill).capitalize()))


## The highest level there is.
func top_level() -> int:
	return thresholds.size()


## The level `points` make: 1 at the least, top_level() at the most.
func level_at(points: int) -> int:
	var level: int = 0
	for at: int in thresholds:
		if points >= at:
			level += 1
	return maxi(level, 1)


## The level of `skill`, given everyone's points (skill id -> points).
func level_of(skill: StringName, points: Dictionary) -> int:
	return level_at(int(points.get(skill, 0)))


## The points the level after `points`' begins at, or -1 at the top level.
func next_at(points: int) -> int:
	var level: int = level_at(points)
	return thresholds[level] if level < thresholds.size() else -1


## The points `skill` gains by `deed` (0: no such skill, or it doesn't grow by that).
func gain(skill: StringName, deed: StringName) -> int:
	var gains: Variant = _rules_of(skill).get("gains")
	if typeof(gains) != TYPE_DICTIONARY:
		return 0
	var points: Variant = (gains as Dictionary).get(String(deed), 0)
	return maxi(int(points), 0) if _is_number(points) else 0


func has_deed(skill: StringName, deed: StringName) -> bool:
	return gain(skill, deed) > 0


## Whether `skill` makes `action` (one of EnergyRules' costs) cheaper.
func eases(skill: StringName, action: String) -> bool:
	var listed: Variant = _rules_of(skill).get("eases")
	return typeof(listed) == TYPE_ARRAY and (listed as Array).has(action)


## Whether `skill` makes cooked dishes give more.
func enriches_dishes(skill: StringName) -> bool:
	var marked: Variant = _rules_of(skill).get("enriches_dishes", false)
	return typeof(marked) == TYPE_BOOL and marked


## The share `level` takes off a cost or adds to a dish: nothing at level 1.
func share_at(level: int) -> float:
	return step * float(maxi(level, 1) - 1)


## What `action`'s energy cost is multiplied by, given everyone's points: 1 for work no skill
## eases (sprinting), less for work one does.
func cost_factor(action: String, points: Dictionary) -> float:
	var factor: float = 1.0
	for skill: StringName in _skills:
		if eases(skill, action):
			factor *= maxf(1.0 - share_at(level_of(skill, points)), 0.0)
	return factor


## What a cooked dish's energy is multiplied by, given everyone's points: 1 or more.
func dish_factor(points: Dictionary) -> float:
	var factor: float = 1.0
	for skill: StringName in _skills:
		if enriches_dishes(skill):
			factor *= 1.0 + share_at(level_of(skill, points))
	return factor


## "Combat 2   Farming 3   Cooking 1": every skill's level, for the pause menu.
func line(points: Dictionary) -> String:
	var parts: PackedStringArray = []
	for skill: StringName in _skills:
		parts.append("%s %d" % [name_of(skill), level_of(skill, points)])
	return LINE_GAP.join(parts)


## "Farming rose to level 2."
func risen_words(skill: StringName, level: int) -> String:
	return RISEN_WORDS % [name_of(skill), level]


## What is wrong with `rules` as the skills' rules, in words: nothing, if they can be used.
## `cost_names` are the energy costs a skill may ease (EnergyRules.COSTS).
static func problems(rules: Dictionary, cost_names: Array) -> PackedStringArray:
	var out: PackedStringArray = []
	var levels: Variant = rules.get("levels")
	var count: int = 0
	if typeof(levels) != TYPE_ARRAY or (levels as Array).is_empty():
		out.append("'levels' must list the points each level begins at, from 0 up.")
	else:
		count = (levels as Array).size()
		var last: float = -1.0
		for i: int in count:
			var at: Variant = levels[i]
			if not _is_whole(at) or float(at) <= last or (i == 0 and float(at) != 0.0):
				out.append("'levels' must be whole numbers that rise, the first of them 0.")
				break
			last = float(at)
	var step_value: Variant = rules.get("step")
	if not _is_number(step_value) or float(step_value) < 0.0:
		out.append("'step' must be a number of 0 or more: the share a level takes off a cost.")
	elif count > 1 and float(step_value) * float(count - 1) >= 1.0:
		out.append("'step' is too big: at the top level the work would cost nothing.")
	var listed: Variant = rules.get("skills")
	if typeof(listed) != TYPE_DICTIONARY or (listed as Dictionary).is_empty():
		out.append("'skills' must be an object of the hero's skills.")
		return out
	for id: Variant in listed:
		if typeof(listed[id]) != TYPE_DICTIONARY:
			out.append("skill '%s' must be an object." % id)
			continue
		var skill: Dictionary = listed[id]
		if typeof(skill.get("name")) != TYPE_STRING or str(skill["name"]).is_empty():
			out.append("skill '%s' needs a 'name'." % id)
		var gains: Variant = skill.get("gains")
		if typeof(gains) != TYPE_DICTIONARY or (gains as Dictionary).is_empty():
			out.append("skill '%s' needs 'gains': the points each deed gives." % id)
		else:
			for deed: Variant in gains:
				if not _is_whole(gains[deed]) or float(gains[deed]) < 1.0:
					out.append("skill '%s' gains by '%s' must be a whole number of 1 or more." % [id, deed])
		var eased: Variant = skill.get("eases", [])
		if typeof(eased) != TYPE_ARRAY:
			out.append("skill '%s' 'eases' must list the costs it makes cheaper." % id)
		else:
			for action: Variant in eased:
				if not cost_names.has(str(action)):
					out.append("skill '%s' eases an unknown cost '%s'. Known: %s." % [id, action, ", ".join(PackedStringArray(cost_names))])
		if skill.has("enriches_dishes") and typeof(skill["enriches_dishes"]) != TYPE_BOOL:
			out.append("skill '%s' 'enriches_dishes' must be true or false." % id)
	return out


func _rules_of(skill: StringName) -> Dictionary:
	var found: Variant = _skills.get(skill, {})
	return found if typeof(found) == TYPE_DICTIONARY else {}


static func _is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT


static func _is_whole(value: Variant) -> bool:
	return _is_number(value) and float(value) == roundf(float(value))
