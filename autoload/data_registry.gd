extends Node
## Loads and validates every JSON file under res://data (docs/TECH_DESIGN.md §2, §10).
##
## The directory a file sits in decides what kind of content it holds, so adding content
## never means touching this script. Only a new *kind* of content, or a new condition or
## effect type, does.
##
## Validation runs in two passes: required fields while loading, then cross-references
## once everything is registered. Problems are collected in `errors` instead of thrown, so
## tests can load bad fixtures; `_ready()` reports them and stops a debug build.
##
## Lookups return the stored dictionaries directly. Treat them as read-only.

const DATA_ROOT: String = "res://data"

const KIND_ITEMS: StringName = &"items"
const KIND_QUEST: StringName = &"quest"
const KIND_DIALOGUE: StringName = &"dialogue"
const KIND_ENEMY: StringName = &"enemy"
const KIND_BREAKABLE: StringName = &"breakable"
const KIND_RULES: StringName = &"rules"

## Directory under DATA_ROOT -> the kind of file it holds.
const DIRECTORY_KINDS: Dictionary = {
	"items": KIND_ITEMS,
	"quests": KIND_QUEST,
	"dialogue": KIND_DIALOGUE,
	"enemies": KIND_ENEMY,
	"breakables": KIND_BREAKABLE,
	"rules": KIND_RULES,
}

const REQUIRED_FIELDS: Dictionary = {
	&"item": ["id", "name", "type"],
	&"quest": ["id", "title", "start_stage", "stages"],
	&"stage": ["journal"],
	&"objective": ["id", "text", "complete_when"],
	&"transition": ["when", "to"],
	&"dialogue": ["id", "start", "nodes"],
	&"dialogue_node": ["speaker", "text", "options"],
	&"enemy": ["id", "name", "behaviour", "health", "speed", "contact_damage"],
	&"breakable": ["id", "name", "breaks_on", "drops"],
	&"rules": ["id"],
}
## The sets of rules the game knows (data/rules/<id>.json), by id.
const RULES_TIME: StringName = &"time"
const RULE_SETS: Array[StringName] = [RULES_TIME]

## Enemy behaviour ids (EnemyBrains makes one brain per id) and drop-table entry types.
const ENEMY_BEHAVIOURS: Array[String] = ["hopper", "archer", "flier", "warden", "shade"]
const DROP_TYPES: Array[String] = ["heart", "item", "nothing"]
## What a boss's weak point can take (Hit kinds dealt by the hero's weapons). Also what can
## cut or break a breakable.
const WEAK_POINTS: Array[String] = ["sword", "arrow", "bomb"]
## The bursts a breakable can throw up (Burst kinds).
const BREAK_BURSTS: Array[String] = ["leaves", "shards", "dust", "spark", "sparkle"]

## Condition type -> required fields (docs/data/CONDITIONS_AND_EFFECTS.md).
const CONDITION_FIELDS: Dictionary = {
	"flag": ["flag", "value"],
	"has_item": ["item", "count"],
	"quest_stage": ["quest", "stage"],
	"quest_status": ["quest", "status"],
	"all": ["of"],
	"any": ["of"],
	"not": ["condition"],
}

## Effect type -> required fields (docs/data/CONDITIONS_AND_EFFECTS.md).
const EFFECT_FIELDS: Dictionary = {
	"set_flag": ["flag", "value"],
	"give_item": ["item", "count"],
	"take_item": ["item", "count"],
	"set_quest_stage": ["quest", "stage"],
	"complete_quest": [],
}

## A field with one of these names, inside a condition or effect, must name an id
## registered in the given collection.
const REFERENCE_FIELDS: Dictionary = {
	"item": &"items",
	"quest": &"quests",
}

## Problems found by the last load_all(), as "file: what is wrong" lines.
var errors: PackedStringArray = []

var _collections: Dictionary[StringName, Dictionary] = {}


func _ready() -> void:
	load_all()
	if errors.is_empty():
		return
	for message: String in errors:
		push_error("[DataRegistry] " + message)
	assert(false, "DataRegistry: %d problem(s) in %s; see the errors above." % [errors.size(), DATA_ROOT])


# --- Lookups ---------------------------------------------------------------

## The entry with `id` in `collection` (e.g. &"items"), or an empty dictionary.
func get_entry(collection: StringName, id: StringName) -> Dictionary:
	return _collections.get(collection, {}).get(id, {})


func has_entry(collection: StringName, id: StringName) -> bool:
	return _collections.get(collection, {}).has(id)


## Every id in `collection`, sorted alphabetically, for stable iteration.
func ids(collection: StringName) -> Array[StringName]:
	var out: Array[StringName] = []
	out.assign(_collections.get(collection, {}).keys())
	# StringName's own ordering is by internal pointer, not text, so compare as String.
	out.sort_custom(func(a: StringName, b: StringName) -> bool: return String(a) < String(b))
	return out


## Every entry in `collection`, ordered by id.
func entries(collection: StringName) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var source: Dictionary = _collections.get(collection, {})
	for id: StringName in ids(collection):
		out.append(source[id])
	return out


func get_item(id: StringName) -> Dictionary:
	return get_entry(&"items", id)


func get_quest(id: StringName) -> Dictionary:
	return get_entry(&"quests", id)


func get_dialogue(id: StringName) -> Dictionary:
	return get_entry(&"dialogues", id)


func get_enemy(id: StringName) -> Dictionary:
	return get_entry(&"enemies", id)


func get_breakable(id: StringName) -> Dictionary:
	return get_entry(&"breakables", id)


## The numbers a system runs on (data/rules/<id>.json), e.g. &"time" for the day's clock.
func get_rules(id: StringName) -> Dictionary:
	return get_entry(&"rules", id)


# --- Loading ---------------------------------------------------------------

## Clears everything and loads all JSON under `root`. Returns the problems found;
## an empty result means every file is valid and every reference resolves.
func load_all(root: String = DATA_ROOT) -> PackedStringArray:
	errors = []
	_collections = {&"items": {}, &"quests": {}, &"dialogues": {}, &"enemies": {}, &"breakables": {}, &"rules": {}}
	if not DirAccess.dir_exists_absolute(root):
		errors.append("%s: data directory does not exist." % root)
		return errors
	for stray: String in DirAccess.get_files_at(root):
		if stray.ends_with(".json"):
			errors.append("%s: JSON must live in a kind directory (%s)." % [root.path_join(stray), ", ".join(DIRECTORY_KINDS.keys())])
	for dir_name: String in DirAccess.get_directories_at(root):
		var dir_path: String = root.path_join(dir_name)
		if not DIRECTORY_KINDS.has(dir_name):
			errors.append("%s: unknown data directory. Known: %s." % [dir_path, ", ".join(DIRECTORY_KINDS.keys())])
			continue
		for file_name: String in DirAccess.get_files_at(dir_path):
			if file_name.ends_with(".json"):
				_load_file(dir_path.path_join(file_name), DIRECTORY_KINDS[dir_name])
	_validate_references()
	return errors


func _load_file(path: String, kind: StringName) -> void:
	var text: String = FileAccess.get_file_as_string(path)
	if text.is_empty():
		errors.append("%s: file is empty or unreadable." % path)
		return
	var json: JSON = JSON.new()
	if json.parse(text) != OK:
		errors.append("%s:%d: invalid JSON: %s" % [path, json.get_error_line(), json.get_error_message()])
		return
	if typeof(json.data) != TYPE_DICTIONARY:
		errors.append("%s: the top level must be a JSON object." % path)
		return
	var data: Dictionary = json.data
	match kind:
		KIND_ITEMS:
			_load_list(path, data, "items", &"item", &"items")
		KIND_QUEST:
			_register(path, data, &"quest", &"quests")
		KIND_DIALOGUE:
			_register(path, data, &"dialogue", &"dialogues")
		KIND_ENEMY:
			_register(path, data, &"enemy", &"enemies")
		KIND_BREAKABLE:
			_register(path, data, &"breakable", &"breakables")
		KIND_RULES:
			_register(path, data, &"rules", &"rules")


## Registers every object in the array `data[key]`.
func _load_list(path: String, data: Dictionary, key: String, kind: StringName, collection: StringName) -> void:
	if not data.has(key):
		return
	if typeof(data[key]) != TYPE_ARRAY:
		errors.append("%s: '%s' must be an array." % [path, key])
		return
	for element: Variant in (data[key] as Array):
		if typeof(element) != TYPE_DICTIONARY:
			errors.append("%s: every entry in '%s' must be an object." % [path, key])
			continue
		_register(path, element, kind, collection)


## Checks required fields and id uniqueness, then stores the entry. Returns success.
func _register(path: String, entry: Dictionary, kind: StringName, collection: StringName) -> bool:
	if not _has_required(path, entry, kind, str(entry.get("id", "?"))):
		return false
	var id: StringName = StringName(str(entry["id"]))
	if _collections[collection].has(id):
		errors.append("%s: duplicate %s id '%s' (also in %s)." % [path, kind, id, _collections[collection][id]["_source"]])
		return false
	entry["_source"] = path
	_collections[collection][id] = entry
	return true


func _has_required(path: String, entry: Dictionary, kind: StringName, label: String) -> bool:
	var ok: bool = true
	for field: String in REQUIRED_FIELDS[kind]:
		if not entry.has(field):
			errors.append("%s: %s '%s' is missing required field '%s'." % [path, kind, label, field])
			ok = false
	return ok


# --- Cross-references ------------------------------------------------------

func _validate_references() -> void:
	for quest: Dictionary in _collections[&"quests"].values():
		_check_quest(quest)
	for dialogue: Dictionary in _collections[&"dialogues"].values():
		_check_dialogue(dialogue)
	for enemy: Dictionary in _collections[&"enemies"].values():
		_check_enemy(enemy)
	for breakable: Dictionary in _collections[&"breakables"].values():
		_check_breakable(breakable)
	for rules: Dictionary in _collections[&"rules"].values():
		_check_rules(rules)
	for item: Dictionary in _collections[&"items"].values():
		var stats: Variant = item.get("stats", {})
		if typeof(stats) == TYPE_DICTIONARY and (stats as Dictionary).has("ammo"):
			_check_id(item["_source"], "item '%s' ammo" % item["id"], &"items", str(stats["ammo"]))


func _check_quest(quest: Dictionary) -> void:
	var path: String = quest["_source"]
	var label: String = "quest '%s'" % quest["id"]
	if typeof(quest["stages"]) != TYPE_DICTIONARY or (quest["stages"] as Dictionary).is_empty():
		errors.append("%s: %s needs a non-empty 'stages' object." % [path, label])
		return
	var stages: Dictionary = quest["stages"]
	var completes: bool = false
	if not stages.has(str(quest["start_stage"])):
		errors.append("%s: %s start_stage '%s' is not a stage." % [path, label, quest["start_stage"]])
	for stage_id: Variant in stages:
		var where: String = "%s stage '%s'" % [label, stage_id]
		if typeof(stages[stage_id]) != TYPE_DICTIONARY:
			errors.append("%s: %s must be an object." % [path, where])
			continue
		var stage: Dictionary = stages[stage_id]
		_has_required(path, stage, &"stage", "%s/%s" % [quest["id"], stage_id])
		for element: Variant in _array_field(path, where, stage, "objectives"):
			var objective: Dictionary = element if typeof(element) == TYPE_DICTIONARY else {}
			if _has_required(path, objective, &"objective", "%s/%s" % [stage_id, objective.get("id", "?")]):
				_check_condition(path, "%s objective '%s'" % [where, objective["id"]], objective["complete_when"])
		var transitions: Array = _array_field(path, where, stage, "transitions")
		for i: int in transitions.size():
			var transition: Dictionary = transitions[i] if typeof(transitions[i]) == TYPE_DICTIONARY else {}
			var t_where: String = "%s transition %d" % [where, i]
			if not _has_required(path, transition, &"transition", "%s/%d" % [stage_id, i]):
				continue
			_check_condition(path, t_where, transition["when"])
			if not stages.has(str(transition["to"])):
				errors.append("%s: %s goes to unknown stage '%s'." % [path, t_where, transition["to"]])
		_check_effect_list(path, where + " on_enter", stage.get("on_enter", []))
		var on_enter: Variant = stage.get("on_enter", [])
		if typeof(on_enter) == TYPE_ARRAY:
			for effect: Variant in on_enter:
				if typeof(effect) == TYPE_DICTIONARY and str((effect as Dictionary).get("type", "")) == "complete_quest":
					completes = true
	if not completes:
		errors.append("%s: %s can never finish: no stage's on_enter has a 'complete_quest' effect." % [path, label])


func _check_dialogue(dialogue: Dictionary) -> void:
	var path: String = dialogue["_source"]
	var label: String = "dialogue '%s'" % dialogue["id"]
	if typeof(dialogue["nodes"]) != TYPE_DICTIONARY or (dialogue["nodes"] as Dictionary).is_empty():
		errors.append("%s: %s needs a non-empty 'nodes' object." % [path, label])
		return
	var nodes: Dictionary = dialogue["nodes"]
	if dialogue.has("speakers") and typeof(dialogue["speakers"]) != TYPE_DICTIONARY:
		errors.append("%s: %s 'speakers' must be an object (speaker id -> display name)." % [path, label])
	if not nodes.has(str(dialogue["start"])):
		errors.append("%s: %s start '%s' is not a node." % [path, label, dialogue["start"]])
	for node_id: Variant in nodes:
		var where: String = "%s node '%s'" % [label, node_id]
		var node: Dictionary = nodes[node_id] if typeof(nodes[node_id]) == TYPE_DICTIONARY else {}
		if not _has_required(path, node, &"dialogue_node", "%s/%s" % [dialogue["id"], node_id]):
			continue
		_check_effect_list(path, where + " on_enter", node.get("on_enter", []))
		var options: Array = node["options"] if typeof(node["options"]) == TYPE_ARRAY else []
		for i: int in options.size():
			var o_where: String = "%s option %d" % [where, i]
			var option: Dictionary = options[i] if typeof(options[i]) == TYPE_DICTIONARY else {}
			if not option.has("text"):
				errors.append("%s: %s needs 'text'." % [path, o_where])
			_check_condition_list(path, o_where + " conditions", option.get("conditions", []))
			_check_effect_list(path, o_where + " effects", option.get("effects", []))
			if not option.has("next"):
				errors.append("%s: %s needs 'next' (a node id, or null to end)." % [path, o_where])
			elif option["next"] != null and not nodes.has(str(option["next"])):
				errors.append("%s: %s 'next' points to unknown node '%s'." % [path, o_where, option["next"]])


func _check_enemy(enemy: Dictionary) -> void:
	var path: String = enemy["_source"]
	var label: String = "enemy '%s'" % enemy["id"]
	if not ENEMY_BEHAVIOURS.has(str(enemy["behaviour"])):
		errors.append("%s: %s has unknown behaviour '%s'. Known: %s." % [path, label, enemy["behaviour"], ", ".join(ENEMY_BEHAVIOURS)])
	for field: String in ["health", "speed", "contact_damage"]:
		var value: Variant = enemy[field]
		if (typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT) or float(value) < 0.0:
			errors.append("%s: %s '%s' must be a number of 0 or more." % [path, label, field])
	if enemy.has("boss"):
		var boss: Variant = enemy["boss"]
		if typeof(boss) != TYPE_DICTIONARY:
			errors.append("%s: %s 'boss' must be an object." % [path, label])
		elif not WEAK_POINTS.has(str((boss as Dictionary).get("weak_point", "arrow"))):
			errors.append("%s: %s has unknown weak_point '%s'. Known: %s." % [path, label, boss["weak_point"], ", ".join(WEAK_POINTS)])
	_check_drops(path, label, enemy)


## A set of rules must be one the game knows, and usable by the class that reads it.
func _check_rules(rules: Dictionary) -> void:
	var path: String = rules["_source"]
	var id: StringName = StringName(str(rules["id"]))
	if not RULE_SETS.has(id):
		errors.append("%s: unknown rules '%s'. Known: %s." % [path, id, ", ".join(RULE_SETS)])
		return
	if id == RULES_TIME:
		for problem: String in DayClock.problems(rules):
			errors.append("%s: rules 'time': %s" % [path, problem])


func _check_breakable(breakable: Dictionary) -> void:
	var path: String = breakable["_source"]
	var label: String = "breakable '%s'" % breakable["id"]
	var breaks_on: Array = _array_field(path, label, breakable, "breaks_on")
	if breaks_on.is_empty():
		errors.append("%s: %s needs something in 'breaks_on' that can break it." % [path, label])
	for kind: Variant in breaks_on:
		if not WEAK_POINTS.has(str(kind)):
			errors.append("%s: %s 'breaks_on' has unknown '%s'. Known: %s." % [path, label, kind, ", ".join(WEAK_POINTS)])
	if breakable.has("burst") and not BREAK_BURSTS.has(str(breakable["burst"])):
		errors.append("%s: %s has unknown burst '%s'. Known: %s." % [path, label, breakable["burst"], ", ".join(BREAK_BURSTS)])
	_check_drops(path, label, breakable)


## A weighted drop table (enemies, breakables): known types, weights above 0, real items.
func _check_drops(path: String, label: String, entry: Dictionary) -> void:
	var drops: Array = _array_field(path, label, entry, "drops")
	for i: int in drops.size():
		var where: String = "%s drop %d" % [label, i]
		if typeof(drops[i]) != TYPE_DICTIONARY:
			errors.append("%s: %s must be an object." % [path, where])
			continue
		var drop: Dictionary = drops[i]
		if not DROP_TYPES.has(str(drop.get("type", ""))):
			errors.append("%s: %s has unknown type '%s'. Known: %s." % [path, where, drop.get("type", ""), ", ".join(DROP_TYPES)])
		var weight: Variant = drop.get("weight")
		if (typeof(weight) != TYPE_INT and typeof(weight) != TYPE_FLOAT) or float(weight) <= 0.0:
			errors.append("%s: %s needs a 'weight' above 0." % [path, where])
		if str(drop.get("type", "")) == "item":
			if not drop.has("item"):
				errors.append("%s: %s of type 'item' needs 'item'." % [path, where])
			else:
				_check_id(path, where + " item", &"items", str(drop["item"]))


# --- Conditions & effects --------------------------------------------------

func _check_condition_list(path: String, where: String, list: Variant) -> void:
	if typeof(list) != TYPE_ARRAY:
		errors.append("%s: %s must be an array of conditions." % [path, where])
		return
	for i: int in (list as Array).size():
		_check_condition(path, "%s[%d]" % [where, i], list[i])


func _check_condition(path: String, where: String, raw: Variant) -> void:
	if typeof(raw) != TYPE_DICTIONARY:
		errors.append("%s: %s: a condition must be an object." % [path, where])
		return
	var condition: Dictionary = raw
	var type_name: String = str(condition.get("type", ""))
	if not CONDITION_FIELDS.has(type_name):
		errors.append("%s: %s: unknown condition type '%s'. Known: %s." % [path, where, type_name, ", ".join(CONDITION_FIELDS.keys())])
		return
	if not _has_fields(path, where, "condition", type_name, condition, CONDITION_FIELDS[type_name]):
		return
	_check_reference_fields(path, where, condition)
	match type_name:
		"all", "any":
			_check_condition_list(path, "%s %s" % [where, type_name], condition["of"])
		"not":
			_check_condition(path, where + " not", condition["condition"])
		"quest_stage":
			_check_stage(path, where, str(condition["quest"]), str(condition["stage"]))
		"quest_status":
			if not QuestState.STATUSES.has(StringName(str(condition["status"]))):
				errors.append("%s: %s: unknown quest status '%s'. Known: %s." % [path, where, condition["status"], ", ".join(QuestState.STATUSES)])


func _check_effect_list(path: String, where: String, list: Variant) -> void:
	if typeof(list) != TYPE_ARRAY:
		errors.append("%s: %s must be an array of effects." % [path, where])
		return
	for i: int in (list as Array).size():
		var w: String = "%s[%d]" % [where, i]
		if typeof(list[i]) != TYPE_DICTIONARY:
			errors.append("%s: %s: an effect must be an object." % [path, w])
			continue
		var effect: Dictionary = list[i]
		var type_name: String = str(effect.get("type", ""))
		if not EFFECT_FIELDS.has(type_name):
			errors.append("%s: %s: unknown effect type '%s'. Known: %s." % [path, w, type_name, ", ".join(EFFECT_FIELDS.keys())])
			continue
		if not _has_fields(path, w, "effect", type_name, effect, EFFECT_FIELDS[type_name]):
			continue
		_check_reference_fields(path, w, effect)
		if type_name == "set_quest_stage":
			_check_stage(path, w, str(effect["quest"]), str(effect["stage"]))


func _has_fields(path: String, where: String, what: String, type_name: String,
		entry: Dictionary, fields: Array) -> bool:
	var ok: bool = true
	for field: String in fields:
		if not entry.has(field):
			errors.append("%s: %s: %s '%s' is missing '%s'." % [path, where, what, type_name, field])
			ok = false
	return ok


## Every field named in REFERENCE_FIELDS must point at a registered id.
func _check_reference_fields(path: String, where: String, entry: Dictionary) -> void:
	for field: String in REFERENCE_FIELDS:
		if entry.has(field):
			_check_id(path, "%s %s" % [where, field], REFERENCE_FIELDS[field], str(entry[field]))


func _check_id(path: String, where: String, collection: StringName, id: String) -> bool:
	if _collections[collection].has(StringName(id)):
		return true
	errors.append("%s: %s refers to unknown %s id '%s'." % [path, where, String(collection).trim_suffix("s"), id])
	return false


## `entry[key]` as an array; missing means empty, anything else is reported.
func _array_field(path: String, where: String, entry: Dictionary, key: String) -> Array:
	var value: Variant = entry.get(key, [])
	if typeof(value) == TYPE_ARRAY:
		return value
	errors.append("%s: %s '%s' must be an array." % [path, where, key])
	return []


## Missing quests are reported by _check_reference_fields; this only checks the stage.
func _check_stage(path: String, where: String, quest_id: String, stage_id: String) -> void:
	var quest: Dictionary = get_quest(StringName(quest_id))
	if quest.is_empty() or typeof(quest.get("stages")) != TYPE_DICTIONARY:
		return
	if not (quest["stages"] as Dictionary).has(stage_id):
		errors.append("%s: %s: quest '%s' has no stage '%s'." % [path, where, quest_id, stage_id])
