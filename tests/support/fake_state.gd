extends RefCounted
## A stand-in for GameState in pure tests: the methods EffectApplier calls, and to_dict() in
## GameState's shape for ConditionEvaluator.

var flags: Dictionary = {}
var items: Dictionary = {}
var quests: Dictionary = {}
## Every deed practised, in order: [skill, deed].
var practised: Array = []


func set_flag(flag: StringName, value: Variant) -> void:
	flags[String(flag)] = value


func add_item(item_id: StringName, count: int) -> void:
	items[String(item_id)] = maxi(int(items.get(String(item_id), 0)) + count, 0)


## A pack with no limits: everything given fits.
func give_item(item_id: StringName, count: int) -> void:
	add_item(item_id, count)


func set_quest_stage(quest_id: StringName, stage_id: StringName) -> void:
	quests[String(quest_id)] = String(stage_id)


func practise(skill: StringName, deed: StringName) -> void:
	practised.append([String(skill), String(deed)])


func to_dict() -> Dictionary:
	var inventory: Array = []
	for id: String in items:
		if int(items[id]) > 0:
			inventory.append({"id": id, "count": items[id]})
	return {"flags": flags.duplicate(), "quests": quests.duplicate(), "inventory": inventory}
