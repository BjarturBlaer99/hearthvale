class_name ConditionEvaluator
extends RefCounted
## Evaluates the shared condition vocabulary (docs/data/CONDITIONS_AND_EFFECTS.md) against a
## game-state snapshot in GameState.to_dict() shape. Pure: build one per check from a fresh
## snapshot. DataRegistry has already validated the conditions' shape and ids, so anything
## unrecognised here simply counts as not met.

var _state: Dictionary


func _init(state: Dictionary) -> void:
	_state = state


func is_met(condition: Dictionary) -> bool:
	match str(condition.get("type", "")):
		"flag":
			return _same(_section("flags").get(str(condition["flag"]), false), condition["value"])
		"has_item":
			return item_count(str(condition["item"])) >= int(condition["count"])
		"quest_stage":
			return str(_section("quests").get(str(condition["quest"]), "")) == str(condition["stage"])
		"all":
			return all_met(condition["of"])
		"any":
			for inner: Variant in condition["of"]:
				if is_met(inner):
					return true
			return false
		"not":
			return not is_met(condition["condition"])
	return false


func all_met(conditions: Array) -> bool:
	return unmet(conditions).is_empty()


## The conditions in `conditions` that aren't met, in order.
func unmet(conditions: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for condition: Variant in conditions:
		if not is_met(condition):
			out.append(condition)
	return out


func item_count(item_id: String) -> int:
	for stack: Variant in _state.get("inventory", []):
		if str((stack as Dictionary).get("id", "")) == item_id:
			return int((stack as Dictionary).get("count", 0))
	return 0


func _section(key: String) -> Dictionary:
	var value: Variant = _state.get(key, {})
	return value if typeof(value) == TYPE_DICTIONARY else {}


## Equality that never errors across types: numbers compare by value, anything else must
## also share a type.
static func _same(a: Variant, b: Variant) -> bool:
	var a_number: bool = typeof(a) == TYPE_INT or typeof(a) == TYPE_FLOAT
	var b_number: bool = typeof(b) == TYPE_INT or typeof(b) == TYPE_FLOAT
	if a_number and b_number:
		return is_equal_approx(float(a), float(b))
	return typeof(a) == typeof(b) and a == b
