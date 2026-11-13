class_name EffectApplier
extends RefCounted
## Applies the shared effect vocabulary (docs/data/CONDITIONS_AND_EFFECTS.md) to a game state:
## GameState, or any object with the same methods (tests use a stand-in):
##   set_flag(flag, value), add_item(item_id, count), set_quest_stage(quest_id, stage_id),
##   sleep(), request_shop(shop_id, mode).
## Pure apart from those calls. DataRegistry has already validated the effects' shape and ids.

var _state: Object


func _init(state: Object) -> void:
	_state = state


## Applies one effect. Returns false for anything it can't apply here: unknown types, and
## complete_quest, which only means something inside a quest's stage (QuestRunner applies it).
func apply(effect: Dictionary) -> bool:
	match str(effect.get("type", "")):
		"set_flag":
			_state.call(&"set_flag", StringName(str(effect["flag"])), effect["value"])
		"give_item":
			_state.call(&"add_item", StringName(str(effect["item"])), int(effect["count"]))
		"take_item":
			_state.call(&"add_item", StringName(str(effect["item"])), -int(effect["count"]))
		"set_quest_stage":
			_state.call(&"set_quest_stage", StringName(str(effect["quest"])), StringName(str(effect["stage"])))
		"sleep":
			_state.call(&"sleep")
		"shop":
			_state.call(&"request_shop", StringName(str(effect["shop"])), StringName(str(effect["mode"])))
		_:
			return false
	return true


## Applies every effect in order. Returns how many were applied.
func apply_all(effects: Array) -> int:
	var applied: int = 0
	for effect: Variant in effects:
		if typeof(effect) == TYPE_DICTIONARY and apply(effect):
			applied += 1
	return applied
