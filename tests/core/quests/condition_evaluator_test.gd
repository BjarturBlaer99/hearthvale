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


func test_quest_status_is_not_started_active_or_complete() -> void:
	var check: ConditionEvaluator = ConditionEvaluator.new({
		"flags": {"quest/done_one/complete": true, "quest/lost_key/entered": "find_key"},
		"quests": {"lost_key": "find_key", "done_one": "end"},
	})
	for case: Array in [["never_heard_of", "not_started"], ["lost_key", "active"], ["done_one", "complete"]]:
		for status: String in ["not_started", "active", "complete"]:
			assert_bool(check.is_met({"type": "quest_status", "quest": case[0], "status": status})) 				.override_failure_message("%s is %s, asked %s" % [case[0], case[1], status]).is_equal(status == case[1])


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


func test_days_since_counts_the_dawns_since_a_flag_came_true() -> void:
	# The Warden fell on day 4. `on` is the evaluator as it would be on a given day.
	var on: Callable = func(today: int) -> ConditionEvaluator:
		return ConditionEvaluator.new({
			"day": today,
			"flags": {"warden_fell": true, "old_news": true, "gate": false, "visits": 3},
			"flag_days": {"warden_fell": 4, "gate": 2},
		})
	var a_day: Dictionary = {"type": "days_since", "flag": "warden_fell", "days": 1}
	var two_days: Dictionary = {"type": "days_since", "flag": "warden_fell", "days": 2}
	assert_bool((on.call(4) as ConditionEvaluator).is_met(a_day)).override_failure_message("not on the day itself").is_false()
	assert_bool((on.call(5) as ConditionEvaluator).is_met(a_day)).override_failure_message("the next dawn").is_true()
	assert_bool((on.call(5) as ConditionEvaluator).is_met(two_days)).is_false()
	assert_bool((on.call(6) as ConditionEvaluator).is_met(two_days)).is_true()
	assert_bool((on.call(9) as ConditionEvaluator).is_met(a_day)).override_failure_message("and ever after").is_true()
	var today: ConditionEvaluator = on.call(5)
	assert_int(today.days_since("warden_fell")).is_equal(1)
	assert_int((on.call(4) as ConditionEvaluator).days_since("warden_fell")).is_equal(0)
	assert_int((on.call(3) as ConditionEvaluator).days_since("warden_fell")).override_failure_message("never before its day").is_equal(0)


func test_days_since_needs_the_flag_to_be_true_and_takes_an_undated_one_as_long_ago() -> void:
	var check: ConditionEvaluator = ConditionEvaluator.new({
		"day": 5,
		"flags": {"old_news": true, "gate": false, "visits": 3},
		"flag_days": {"gate": 2},
	})
	assert_bool(check.is_met({"type": "days_since", "flag": "never_set", "days": 1})).is_false()
	assert_int(check.days_since("never_set")).is_equal(-1)
	assert_bool(check.is_met({"type": "days_since", "flag": "gate", "days": 1})).override_failure_message("a flag that is false, whatever its day").is_false()
	assert_bool(check.is_met({"type": "days_since", "flag": "visits", "days": 1})).override_failure_message("a number is not a yes").is_false()
	# True, with no day kept: it came true before days were kept (an older save).
	assert_int(check.days_since("old_news")).is_equal(ConditionEvaluator.LONG_AGO)
	assert_bool(check.is_met({"type": "days_since", "flag": "old_news", "days": 400})).is_true()
	# A state that keeps no days at all (a stand-in) is on day 1.
	var bare: ConditionEvaluator = ConditionEvaluator.new({"flags": {"done": true}})
	assert_bool(bare.is_met({"type": "days_since", "flag": "done", "days": 1})).is_true()
