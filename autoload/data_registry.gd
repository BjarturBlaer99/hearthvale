extends Node
## Loads and validates every JSON file under res://data (docs/TECH_DESIGN.md §2, §10).
##
## The directory a file sits in decides what kind of content it holds, so adding content
## never means touching this script. Only a new *kind* of content, or a new condition or
## effect type, does.
##
## Validation runs in two passes: required fields and self-contained rules while loading,
## then cross-references once everything is registered. Problems are collected in
## `errors` instead of thrown, so tests can load bad fixtures; `_ready()` reports them
## and stops a debug build.
##
## Lookups return the stored dictionaries directly. Treat them as read-only.

const DATA_ROOT: String = "res://data"

const KIND_NETWORK: StringName = &"network"
const KIND_ITEMS: StringName = &"items"
const KIND_FACTIONS: StringName = &"factions"
const KIND_QUEST: StringName = &"quest"
const KIND_DIALOGUE: StringName = &"dialogue"

## Directory under DATA_ROOT -> the kind of file it holds.
const DIRECTORY_KINDS: Dictionary = {
	"water": KIND_NETWORK,
	"items": KIND_ITEMS,
	"factions": KIND_FACTIONS,
	"quests": KIND_QUEST,
	"dialogue": KIND_DIALOGUE,
}

const REQUIRED_FIELDS: Dictionary = {
	&"district": ["id", "name", "levels", "start_level", "water_volume_per_step", "outflows"],
	&"level": ["id", "water_height"],
	&"basin": ["id", "name", "capacity", "start_stored"],
	&"node": ["id", "type", "district", "target", "start_state"],
	&"interior": ["id", "district"],
	&"item": ["id", "name", "type"],
	&"faction": ["id", "name", "start_reputation"],
	&"companion": ["id", "name", "faction_leaning", "start_approval"],
	&"quest": ["id", "title", "start_stage", "stages"],
	&"stage": ["journal"],
	&"objective": ["id", "text", "complete_when"],
	&"transition": ["when", "to"],
	&"dialogue": ["id", "start", "nodes"],
	&"dialogue_node": ["speaker", "text", "options"],
}

## Condition type -> required fields (docs/data/CONDITIONS_AND_EFFECTS.md).
const CONDITION_FIELDS: Dictionary = {
	"flag": ["flag", "value"],
	"water_level": ["district", "level"],
	"has_item": ["item", "count"],
	"reputation_gte": ["faction", "value"],
	"attribute_gte": ["attribute", "value"],
	"quest_stage": ["quest", "stage"],
	"all": ["of"],
	"any": ["of"],
	"not": ["condition"],
}

## Effect type -> required fields (docs/data/CONDITIONS_AND_EFFECTS.md).
const EFFECT_FIELDS: Dictionary = {
	"set_flag": ["flag", "value"],
	"give_item": ["item", "count"],
	"take_item": ["item", "count"],
	"reputation": ["faction", "delta"],
	"approval": ["companion", "delta"],
	"set_quest_stage": ["quest", "stage"],
	"complete_quest": [],
	"water_lock": ["district", "locked"],
	"spawn_npc_group": ["group", "location"],
}

## A field with one of these names, inside a condition or effect, must name an id
## registered in the given collection.
const REFERENCE_FIELDS: Dictionary = {
	"item": &"items",
	"faction": &"factions",
	"companion": &"companions",
	"district": &"districts",
	"quest": &"quests",
}

const ATTRIBUTES: PackedStringArray = ["grit", "wits", "charm", "tech"]
const NODE_STATES: PackedStringArray = ["broken", "repaired"]

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

## The entry with `id` in `collection` (e.g. &"districts"), or an empty dictionary.
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


func get_district(id: StringName) -> Dictionary:
	return get_entry(&"districts", id)


func get_item(id: StringName) -> Dictionary:
	return get_entry(&"items", id)


func get_quest(id: StringName) -> Dictionary:
	return get_entry(&"quests", id)


func get_dialogue(id: StringName) -> Dictionary:
	return get_entry(&"dialogues", id)


## Level ids of a district, ordered from most water to least.
func level_ids(district_id: StringName) -> PackedStringArray:
	var out: PackedStringArray = []
	for level: Variant in get_district(district_id).get("levels", []):
		out.append(str((level as Dictionary).get("id", "")))
	return out


# --- Loading ---------------------------------------------------------------

## Clears everything and loads all JSON under `root`. Returns the problems found;
## an empty result means every file is valid and every reference resolves.
func load_all(root: String = DATA_ROOT) -> PackedStringArray:
	errors = []
	_collections = {
		&"districts": {}, &"basins": {}, &"nodes": {}, &"interiors": {},
		&"items": {}, &"factions": {}, &"companions": {},
		&"quests": {}, &"dialogues": {},
	}
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
		KIND_NETWORK:
			if not data.has("region"):
				errors.append("%s: a water network file needs a 'region'." % path)
			_load_list(path, data, "districts", &"district", &"districts", _check_district)
			_load_list(path, data, "basins", &"basin", &"basins", _check_basin)
			_load_list(path, data, "nodes", &"node", &"nodes")
			_load_list(path, data, "interiors", &"interior", &"interiors")
		KIND_ITEMS:
			_load_list(path, data, "items", &"item", &"items")
		KIND_FACTIONS:
			_load_list(path, data, "factions", &"faction", &"factions")
			_load_list(path, data, "companions", &"companion", &"companions")
		KIND_QUEST:
			_register(path, data, &"quest", &"quests")
		KIND_DIALOGUE:
			_register(path, data, &"dialogue", &"dialogues")


## Registers every object in the array `data[key]`. `extra_check` runs on each entry
## that passed the required-field check.
func _load_list(path: String, data: Dictionary, key: String, kind: StringName,
		collection: StringName, extra_check: Callable = Callable()) -> void:
	if not data.has(key):
		return
	if typeof(data[key]) != TYPE_ARRAY:
		errors.append("%s: '%s' must be an array." % [path, key])
		return
	for element: Variant in (data[key] as Array):
		if typeof(element) != TYPE_DICTIONARY:
			errors.append("%s: every entry in '%s' must be an object." % [path, key])
			continue
		var entry: Dictionary = element
		if _register(path, entry, kind, collection) and extra_check.is_valid():
			extra_check.call(path, entry)


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


## Self-contained district rules: levels exist, water heights strictly decrease,
## and the start level is one of them.
func _check_district(path: String, district: Dictionary) -> void:
	var label: String = "district '%s'" % district["id"]
	if typeof(district["levels"]) != TYPE_ARRAY or (district["levels"] as Array).is_empty():
		errors.append("%s: %s needs at least one level." % [path, label])
		return
	var previous_height: float = INF
	var seen: PackedStringArray = []
	for element: Variant in (district["levels"] as Array):
		if typeof(element) != TYPE_DICTIONARY:
			errors.append("%s: %s has a level that is not an object." % [path, label])
			continue
		var level: Dictionary = element
		if not _has_required(path, level, &"level", "%s/%s" % [district["id"], level.get("id", "?")]):
			continue
		if not _is_whole(level["water_height"]):
			errors.append("%s: %s level '%s' water_height must be a whole number." % [path, label, level["id"]])
			continue
		var height: float = level["water_height"]
		if height >= previous_height:
			errors.append("%s: %s levels must go from most water to least; water_height %s at '%s' does not decrease." % [path, label, height, level["id"]])
		previous_height = height
		seen.append(str(level["id"]))
	if not seen.has(str(district["start_level"])):
		errors.append("%s: %s start_level '%s' is not one of its levels %s." % [path, label, district["start_level"], seen])
	# Water is counted in whole units so the solver conserves it exactly.
	if not _is_whole(district["water_volume_per_step"]) or float(district["water_volume_per_step"]) <= 0.0:
		errors.append("%s: %s water_volume_per_step must be a positive whole number." % [path, label])
	if typeof(district["outflows"]) != TYPE_ARRAY:
		errors.append("%s: %s outflows must be an array (it may be empty)." % [path, label])
		district["outflows"] = []
	elif (district["outflows"] as Array).has(district["id"]):
		errors.append("%s: %s outflows into itself." % [path, label])


func _check_basin(path: String, basin: Dictionary) -> void:
	var label: String = "basin '%s'" % basin["id"]
	if not _is_whole(basin["capacity"]) or float(basin["capacity"]) < 0.0:
		errors.append("%s: %s capacity must be a whole number, 0 or more." % [path, label])
		return
	if not _is_whole(basin["start_stored"]) or float(basin["start_stored"]) < 0.0:
		errors.append("%s: %s start_stored must be a whole number, 0 or more." % [path, label])
	elif float(basin["start_stored"]) > float(basin["capacity"]):
		errors.append("%s: %s start_stored %d is more than its capacity %d." % [path, label, int(basin["start_stored"]), int(basin["capacity"])])


# --- Cross-references ------------------------------------------------------

func _validate_references() -> void:
	for district: Dictionary in _collections[&"districts"].values():
		var where: String = "district '%s'" % district["id"]
		for target: Variant in district["outflows"]:
			_check_water_target(district["_source"], where + " outflow", str(target))
	# Water targets are looked up by id in districts *or* basins, so ids must not collide.
	for id: StringName in _collections[&"basins"]:
		if _collections[&"districts"].has(id):
			errors.append("%s: '%s' is both a district and a basin; water targets need unique ids." % [_collections[&"basins"][id]["_source"], id])
	for node: Dictionary in _collections[&"nodes"].values():
		var where: String = "node '%s'" % node["id"]
		_check_id(node["_source"], where, &"districts", str(node["district"]))
		_check_water_target(node["_source"], where + " target", str(node["target"]))
		if str(node["target"]) == str(node["district"]):
			errors.append("%s: %s targets its own district." % [node["_source"], where])
		if not NODE_STATES.has(str(node["start_state"])):
			errors.append("%s: %s start_state must be one of %s." % [node["_source"], where, NODE_STATES])
		_check_condition_list(node["_source"], where + " repair_requires", node.get("repair_requires", []))
	for interior: Dictionary in _collections[&"interiors"].values():
		var where: String = "interior '%s'" % interior["id"]
		var district_id: String = str(interior["district"])
		if _check_id(interior["_source"], where, &"districts", district_id):
			for key: String in ["dive_when", "dry_when"]:
				for level_id: Variant in interior.get(key, []):
					_check_level(interior["_source"], "%s %s" % [where, key], district_id, str(level_id))
	for companion: Dictionary in _collections[&"companions"].values():
		_check_id(companion["_source"], "companion '%s'" % companion["id"], &"factions", str(companion["faction_leaning"]))
	for quest: Dictionary in _collections[&"quests"].values():
		_check_quest(quest)
	for dialogue: Dictionary in _collections[&"dialogues"].values():
		_check_dialogue(dialogue)


func _check_quest(quest: Dictionary) -> void:
	var path: String = quest["_source"]
	var label: String = "quest '%s'" % quest["id"]
	if typeof(quest["stages"]) != TYPE_DICTIONARY or (quest["stages"] as Dictionary).is_empty():
		errors.append("%s: %s needs a non-empty 'stages' object." % [path, label])
		return
	var stages: Dictionary = quest["stages"]
	if not stages.has(str(quest["start_stage"])):
		errors.append("%s: %s start_stage '%s' is not a stage." % [path, label, quest["start_stage"]])
	for stage_id: Variant in stages:
		var where: String = "%s stage '%s'" % [label, stage_id]
		if typeof(stages[stage_id]) != TYPE_DICTIONARY:
			errors.append("%s: %s must be an object." % [path, where])
			continue
		var stage: Dictionary = stages[stage_id]
		_has_required(path, stage, &"stage", "%s/%s" % [quest["id"], stage_id])
		var objectives: Array = _array_field(path, where, stage, "objectives")
		for element: Variant in objectives:
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


func _check_dialogue(dialogue: Dictionary) -> void:
	var path: String = dialogue["_source"]
	var label: String = "dialogue '%s'" % dialogue["id"]
	if typeof(dialogue["nodes"]) != TYPE_DICTIONARY or (dialogue["nodes"] as Dictionary).is_empty():
		errors.append("%s: %s needs a non-empty 'nodes' object." % [path, label])
		return
	var nodes: Dictionary = dialogue["nodes"]
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
			if option.has("check"):
				var check: Dictionary = option["check"] if typeof(option["check"]) == TYPE_DICTIONARY else {}
				if not ATTRIBUTES.has(str(check.get("attribute", ""))):
					errors.append("%s: %s check attribute must be one of %s." % [path, o_where, ATTRIBUTES])
				if not _is_number(check.get("difficulty")):
					errors.append("%s: %s check needs a numeric difficulty." % [path, o_where])
				for key: String in ["success", "failure"]:
					_check_dialogue_target(path, o_where, nodes, option, key, false)
			else:
				_check_dialogue_target(path, o_where, nodes, option, "next", true)


## `option[key]` must name a node in `nodes`; null ends the conversation when allowed.
func _check_dialogue_target(path: String, where: String, nodes: Dictionary, option: Dictionary,
		key: String, null_ends: bool) -> void:
	if not option.has(key):
		errors.append("%s: %s needs '%s'." % [path, where, key])
	elif option[key] == null:
		if not null_ends:
			errors.append("%s: %s '%s' cannot be null." % [path, where, key])
	elif not nodes.has(str(option[key])):
		errors.append("%s: %s '%s' points to unknown node '%s'." % [path, where, key, option[key]])


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
		"water_level":
			_check_level(path, where, str(condition["district"]), str(condition["level"]))
		"quest_stage":
			_check_stage(path, where, str(condition["quest"]), str(condition["stage"]))
		"attribute_gte":
			if not ATTRIBUTES.has(str(condition["attribute"])):
				errors.append("%s: %s: attribute must be one of %s." % [path, where, ATTRIBUTES])


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


## A water target is a district or a basin.
func _check_water_target(path: String, where: String, id: String) -> void:
	var key: StringName = StringName(id)
	if not _collections[&"districts"].has(key) and not _collections[&"basins"].has(key):
		errors.append("%s: %s refers to '%s', which is neither a district nor a basin." % [path, where, id])


## Missing districts are reported by _check_reference_fields; this only checks the level.
func _check_level(path: String, where: String, district_id: String, level_id: String) -> void:
	if not _collections[&"districts"].has(StringName(district_id)):
		return
	var levels: PackedStringArray = level_ids(StringName(district_id))
	if not levels.has(level_id):
		errors.append("%s: %s: district '%s' has no level '%s' (levels: %s)." % [path, where, district_id, level_id, levels])


## Missing quests are reported by _check_reference_fields; this only checks the stage.
func _check_stage(path: String, where: String, quest_id: String, stage_id: String) -> void:
	var quest: Dictionary = get_quest(StringName(quest_id))
	if quest.is_empty() or typeof(quest.get("stages")) != TYPE_DICTIONARY:
		return
	if not (quest["stages"] as Dictionary).has(stage_id):
		errors.append("%s: %s: quest '%s' has no stage '%s'." % [path, where, quest_id, stage_id])


static func _is_number(value: Variant) -> bool:
	return typeof(value) == TYPE_INT or typeof(value) == TYPE_FLOAT


## JSON may parse 50 as 50.0, so "whole" means numeric with no fractional part.
static func _is_whole(value: Variant) -> bool:
	return _is_number(value) and float(value) == floorf(float(value))
