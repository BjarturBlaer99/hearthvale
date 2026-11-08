extends GdUnitTestSuite
## ConditionEvaluator: every condition type in docs/data/CONDITIONS_AND_EFFECTS.md.

var _check: ConditionEvaluator


func before_test() -> void:
	_check = ConditionEvaluator.new({
		"flags": {"door_open": true, "visits": 3},
		"inventory": [{"id": "small_key", "count": 1}, {"id": "coin", "count": 12}],
		"quests": {"lost_key": "find_key"},
	})


func test_flags_compare_values_and_missing_flags_are_false() -> void:
	assert_bool(_check.is_met({"type": "flag", "flag": "door_open", "value": true})).is_true()
	assert_bool(_check.is_met({"type": "flag", "flag": "door_open", "value": false})).is_false()
	assert_bool(_check.is_met({"type": "flag", "flag": "never_set", "value": false})).is_true()
	assert_bool(_check.is_met({"type": "flag", "flag": "never_set", "value": true})).is_false()
	assert_bool(_check.is_met({"type": "flag", "flag": "visits", "value": 3.0})).override_failure_message("JSON numbers").is_true()


func test_items_need_enough_of_them() -> void:
	assert_bool(_check.is_met({"type": "has_item", "item": "small_key", "count": 1})).is_true()
	assert_bool(_check.is_met({"type": "has_item", "item": "coin", "count": 20})).is_false()
	assert_bool(_check.is_met({"type": "has_item", "item": "wooden_sword", "count": 1})).is_false()


func test_quest_stages() -> void:
	assert_bool(_check.is_met({"type": "quest_stage", "quest": "lost_key", "stage": "find_key"})).is_true()
	assert_bool(_check.is_met({"type": "quest_stage", "quest": "lost_key", "stage": "done"})).is_false()


func test_all_any_and_not() -> void:
	var key: Dictionary = {"type": "has_item", "item": "small_key", "count": 1}
	var rich: Dictionary = {"type": "has_item", "item": "coin", "count": 100}
	assert_bool(_check.is_met({"type": "all", "of": [key, rich]})).is_false()
	assert_bool(_check.is_met({"type": "any", "of": [key, rich]})).is_true()
	assert_bool(_check.is_met({"type": "not", "condition": rich})).is_true()


func test_unmet_lists_what_is_missing_in_order() -> void:
	var key: Dictionary = {"type": "has_item", "item": "small_key", "count": 1}
	var rich: Dictionary = {"type": "has_item", "item": "coin", "count": 100}
	var flag: Dictionary = {"type": "flag", "flag": "boss_beaten", "value": true}
	assert_array(_check.unmet([key, rich, flag])).is_equal([rich, flag])
	assert_bool(_check.all_met([key])).is_true()
	assert_bool(_check.all_met([])).is_true()
