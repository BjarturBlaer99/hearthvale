extends GdUnitTestSuite
## ConditionEvaluator: every condition type in docs/data/CONDITIONS_AND_EFFECTS.md.

var _check: ConditionEvaluator


func before_test() -> void:
	_check = ConditionEvaluator.new({
		"flags": {"door_open": true, "visits": 3},
		"water": {"st_aud": "waist"},
		"inventory": [{"id": "pump_valve", "count": 1}, {"id": "rivets", "count": 12}],
		"reputation": {"summit_holds": 25},
		"player": {"attributes": {"charm": 4}},
		"quests": {"bitter_medicine": "retrieve_medicine"},
	})


func test_flags_compare_values_and_missing_flags_are_false() -> void:
	assert_bool(_check.is_met({"type": "flag", "flag": "door_open", "value": true})).is_true()
	assert_bool(_check.is_met({"type": "flag", "flag": "door_open", "value": false})).is_false()
	assert_bool(_check.is_met({"type": "flag", "flag": "never_set", "value": false})).is_true()
	assert_bool(_check.is_met({"type": "flag", "flag": "never_set", "value": true})).is_false()
	assert_bool(_check.is_met({"type": "flag", "flag": "visits", "value": 3.0})).override_failure_message("JSON numbers").is_true()


func test_water_levels() -> void:
	assert_bool(_check.is_met({"type": "water_level", "district": "st_aud", "level": "waist"})).is_true()
	assert_bool(_check.is_met({"type": "water_level", "district": "st_aud", "level": "drained"})).is_false()


func test_items_need_enough_of_them() -> void:
	assert_bool(_check.is_met({"type": "has_item", "item": "pump_valve", "count": 1})).is_true()
	assert_bool(_check.is_met({"type": "has_item", "item": "rivets", "count": 20})).is_false()
	assert_bool(_check.is_met({"type": "has_item", "item": "food_crate", "count": 1})).is_false()


func test_reputation_attributes_and_quest_stages() -> void:
	assert_bool(_check.is_met({"type": "reputation_gte", "faction": "summit_holds", "value": 25})).is_true()
	assert_bool(_check.is_met({"type": "reputation_gte", "faction": "reclamation", "value": 1})).is_false()
	assert_bool(_check.is_met({"type": "attribute_gte", "attribute": "charm", "value": 4})).is_true()
	assert_bool(_check.is_met({"type": "attribute_gte", "attribute": "grit", "value": 1})).is_false()
	assert_bool(_check.is_met({"type": "quest_stage", "quest": "bitter_medicine", "stage": "retrieve_medicine"})).is_true()


func test_all_any_and_not() -> void:
	var valve: Dictionary = {"type": "has_item", "item": "pump_valve", "count": 1}
	var drained: Dictionary = {"type": "water_level", "district": "st_aud", "level": "drained"}
	assert_bool(_check.is_met({"type": "all", "of": [valve, drained]})).is_false()
	assert_bool(_check.is_met({"type": "any", "of": [valve, drained]})).is_true()
	assert_bool(_check.is_met({"type": "not", "condition": drained})).is_true()


func test_unmet_lists_what_is_missing_in_order() -> void:
	var valve: Dictionary = {"type": "has_item", "item": "pump_valve", "count": 1}
	var food: Dictionary = {"type": "has_item", "item": "food_crate", "count": 20}
	var flag: Dictionary = {"type": "flag", "flag": "tunnel_reached_outlet", "value": true}
	assert_array(_check.unmet([valve, food, flag])).is_equal([food, flag])
	assert_bool(_check.all_met([valve])).is_true()
	assert_bool(_check.all_met([])).is_true()
