extends GdUnitTestSuite
## EnergyRules (P2c): what things cost, when the hero is tired and what that does, and what
## collapsing costs. The numbers are the game's own (data/rules/energy.json).

const ENERGY_RULES: String = "res://data/rules/energy.json"

var _data: Dictionary
var _rules: EnergyRules


func before_test() -> void:
	_data = JSON.parse_string(FileAccess.get_file_as_string(ENERGY_RULES))
	_rules = EnergyRules.new(_data)


func test_a_bar_of_a_hundred_and_what_things_cost() -> void:
	assert_float(_rules.maximum).is_equal(100.0)
	assert_float(_rules.cost(EnergyRules.SPRINT)).override_failure_message("a second of running").is_equal(0.25)
	assert_float(_rules.cost(EnergyRules.SWING)).is_equal(0.5)
	assert_float(_rules.cost(EnergyRules.SHOT)).is_equal(0.5)
	assert_float(_rules.cost("walking")).override_failure_message("what the rules don't name is free").is_equal(0.0)
	assert_float(_rules.maximum / _rules.cost(EnergyRules.SPRINT)).override_failure_message("a full bar is more than six minutes of running").is_greater(360.0)
	assert_float(_rules.after(10.0, 0.5)).is_equal(9.5)
	assert_float(_rules.after(0.3, 0.5)).override_failure_message("never under nothing").is_equal(0.0)
	assert_float(_rules.after(99.0, -50.0)).override_failure_message("never over a full bar").is_equal(100.0)


func test_tired_under_a_quarter_and_no_running_under_a_tenth() -> void:
	assert_bool(_rules.is_low(25.0)).override_failure_message("25 is not yet tired").is_false()
	assert_bool(_rules.is_low(24.9)).is_true()
	assert_float(_rules.move_factor(60.0)).is_equal(1.0)
	assert_float(_rules.move_factor(20.0)).override_failure_message("tired, he moves at 85%").is_equal(0.85)
	assert_float(_rules.cooldown_factor(60.0)).is_equal(1.0)
	assert_float(_rules.cooldown_factor(20.0)).override_failure_message("and the sword is 30% slower to be ready").is_equal(1.3)
	assert_bool(_rules.can_sprint(10.0)).is_true()
	assert_bool(_rules.can_sprint(9.9)).override_failure_message("under 10, no sprinting").is_false()
	assert_bool(_rules.is_spent(0.0)).is_true()
	assert_bool(_rules.is_spent(0.1)).is_false()
	assert_float(_rules.no_sprint_below).override_failure_message("he tires before he can't run").is_less(_rules.low_below)


func test_collapsing_costs_half_his_energy_and_a_tenth_of_his_coins() -> void:
	assert_float(_rules.wake_energy()).is_equal(50.0)
	var lost: Dictionary = {0: 0, 9: 0, 10: 1, 55: 5, 299: 29, 300: 30, 301: 30, 999: 30, -4: 0}
	for coins: int in lost:
		assert_int(_rules.coins_lost(coins)).override_failure_message("of %d coins" % coins).is_equal(lost[coins])
	assert_float(_rules.wake_energy()).override_failure_message("he wakes able to run").is_greater(_rules.no_sprint_below)


func test_the_games_rules_are_sound_and_bad_ones_are_named() -> void:
	assert_array(Array(EnergyRules.problems(_data))).override_failure_message("the game's own rules").is_empty()
	var bare: EnergyRules = EnergyRules.new()
	assert_float(bare.maximum).override_failure_message("the fallbacks are the game's rules").is_equal(_rules.maximum)
	for action: String in [EnergyRules.SPRINT, EnergyRules.SWING, EnergyRules.SHOT]:
		assert_float(bare.cost(action)).override_failure_message(action).is_equal(_rules.cost(action))
	assert_float(bare.low_below).is_equal(_rules.low_below)
	assert_float(bare.low_move).is_equal(_rules.low_move)
	assert_float(bare.low_cooldown).is_equal(_rules.low_cooldown)
	assert_float(bare.no_sprint_below).is_equal(_rules.no_sprint_below)
	assert_float(bare.wake_energy()).is_equal(_rules.wake_energy())
	assert_int(bare.coins_lost(999)).is_equal(_rules.coins_lost(999))
	for key: String in ["maximum", "costs", "low", "no_sprint_below", "collapse"]:
		var without: Dictionary = _data.duplicate(true)
		without.erase(key)
		assert_array(Array(EnergyRules.problems(without))).override_failure_message("a missing '%s' is a problem" % key).is_not_empty()
	var cases: Array = [
		["maximum", 0, "above 0"],
		["no_sprint_below", 100, "could never sprint"],
		["no_sprint_below", -1, "0 or more"],
	]
	for case: Array in cases:
		var bad: Dictionary = _data.duplicate(true)
		bad[case[0]] = case[1]
		assert_str("\n".join(EnergyRules.problems(bad))).override_failure_message("%s = %s" % [case[0], case[1]]).contains(case[2])
	var parts: Array = [
		["costs", "swing", -1, "'swing'"], ["costs", "shot", "lots", "'shot'"],
		["low", "move", 0, "'move'"], ["low", "move", 1.5, "'move'"], ["low", "cooldown", 0.5, "'cooldown'"],
		["collapse", "wake_share", 0, "collapse again"], ["collapse", "coins_lost_share", 2, "'coins_lost_share'"],
		["collapse", "coins_lost_most", -3, "'coins_lost_most'"],
	]
	for case: Array in parts:
		var bad: Dictionary = _data.duplicate(true)
		bad[case[0]][case[1]] = case[2]
		assert_str("\n".join(EnergyRules.problems(bad))).override_failure_message("%s.%s = %s" % [case[0], case[1], case[2]]).contains(case[3])
	# A part that leaves something out takes the fallback for it.
	var thin: EnergyRules = EnergyRules.new({"costs": {"swing": 2.0}})
	assert_float(thin.cost(EnergyRules.SWING)).is_equal(2.0)
	assert_float(thin.cost(EnergyRules.SHOT)).is_equal(_rules.cost(EnergyRules.SHOT))
