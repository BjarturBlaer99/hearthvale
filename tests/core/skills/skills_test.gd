extends GdUnitTestSuite
## Skills (P4b), pure: the levels points make, what each deed gives, what a level takes off the
## energy of a skill's work and adds to a dish, the pause menu's line, and the checks on the
## rules. The game's own rules are the ones the plan's tables give.

const DataRegistryScript: GDScript = preload("res://autoload/data_registry.gd")

var _skills: Skills
var _energy: EnergyRules


func before_test() -> void:
	_skills = Skills.new(DataRegistry.get_rules(DataRegistry.RULES_SKILLS))
	_energy = EnergyRules.new(DataRegistry.get_rules(DataRegistry.RULES_ENERGY))


func test_the_games_rules_are_the_plans() -> void:
	assert_array(_skills.thresholds).is_equal([0, 10, 25, 50, 90])
	assert_int(_skills.top_level()).is_equal(5)
	assert_float(_skills.step).is_equal(0.1)
	assert_array(_skills.ids()).is_equal([Skills.COMBAT, Skills.FARMING, Skills.COOKING])
	assert_int(_skills.gain(Skills.COMBAT, Skills.MONSTER)).is_equal(1)
	assert_int(_skills.gain(Skills.COMBAT, Skills.BOSS)).is_equal(10)
	assert_int(_skills.gain(Skills.FARMING, Skills.TILL)).is_equal(1)
	assert_int(_skills.gain(Skills.FARMING, Skills.HARVEST)).is_equal(2)
	assert_int(_skills.gain(Skills.COOKING, Skills.DISH)).is_equal(2)
	assert_array(Array(Skills.problems(DataRegistry.get_rules(DataRegistry.RULES_SKILLS), EnergyRules.COSTS))).is_empty()


func test_points_make_levels_at_the_thresholds() -> void:
	for case: Array in [[-5, 1], [0, 1], [9, 1], [10, 2], [24, 2], [25, 3], [49, 3], [50, 4], [89, 4], [90, 5], [100000, 5]]:
		assert_int(_skills.level_at(case[0])).override_failure_message("%d points" % case[0]).is_equal(case[1])
	assert_int(_skills.level_of(Skills.FARMING, {Skills.FARMING: 26, Skills.COMBAT: 3})).is_equal(3)
	assert_int(_skills.level_of(Skills.COOKING, {Skills.FARMING: 26})).override_failure_message("no points yet").is_equal(1)
	for case: Array in [[0, 10], [9, 10], [10, 25], [49, 50], [89, 90], [90, -1], [500, -1]]:
		assert_int(_skills.next_at(case[0])).override_failure_message("after %d points" % case[0]).is_equal(case[1])


func test_a_skill_gains_only_by_its_own_deeds() -> void:
	assert_bool(_skills.has_deed(Skills.COMBAT, Skills.MONSTER)).is_true()
	assert_int(_skills.gain(Skills.COMBAT, Skills.TILL)).override_failure_message("tilling is not combat").is_equal(0)
	assert_int(_skills.gain(Skills.FARMING, Skills.DISH)).is_equal(0)
	assert_int(_skills.gain(&"fishing", Skills.MONSTER)).override_failure_message("no such skill").is_equal(0)
	assert_bool(_skills.has_deed(Skills.COOKING, &"burn")).is_false()
	assert_bool(_skills.has_skill(Skills.COOKING)).is_true()
	assert_bool(_skills.has_skill(&"fishing")).is_false()


func test_each_level_takes_a_tenth_off_the_work_a_skill_eases() -> void:
	# [points, a swing, a shot] for combat and [points, the hoe, the can] for farming.
	for case: Array in [[0, 0.5, 0.5], [10, 0.45, 0.45], [25, 0.4, 0.4], [50, 0.35, 0.35], [90, 0.3, 0.3]]:
		var points: Dictionary = {Skills.COMBAT: case[0]}
		assert_float(_energy.cost(EnergyRules.SWING) * _skills.cost_factor(EnergyRules.SWING, points)).override_failure_message("a swing at %d points" % case[0]).is_equal_approx(case[1], 0.0001)
		assert_float(_energy.cost(EnergyRules.SHOT) * _skills.cost_factor(EnergyRules.SHOT, points)).is_equal_approx(case[2], 0.0001)
	for case: Array in [[0, 2.0, 1.0], [10, 1.8, 0.9], [25, 1.6, 0.8], [50, 1.4, 0.7], [90, 1.2, 0.6]]:
		var points: Dictionary = {Skills.FARMING: case[0]}
		assert_float(_energy.cost(EnergyRules.HOE) * _skills.cost_factor(EnergyRules.HOE, points)).override_failure_message("the hoe at %d points" % case[0]).is_equal_approx(case[1], 0.0001)
		assert_float(_energy.cost(EnergyRules.WATER) * _skills.cost_factor(EnergyRules.WATER, points)).is_equal_approx(case[2], 0.0001)


func test_a_skill_eases_only_its_own_work_and_nothing_eases_sprinting() -> void:
	var master: Dictionary = {Skills.COMBAT: 90, Skills.FARMING: 90, Skills.COOKING: 90}
	assert_float(_skills.cost_factor(EnergyRules.SPRINT, master)).override_failure_message("sprinting costs what it did").is_equal(1.0)
	assert_float(_skills.cost_factor("something_else", master)).is_equal(1.0)
	assert_float(_skills.cost_factor(EnergyRules.HOE, {Skills.COMBAT: 90, Skills.COOKING: 90})).override_failure_message("a fighter is no farmer").is_equal(1.0)
	assert_float(_skills.cost_factor(EnergyRules.SWING, {Skills.FARMING: 90})).is_equal(1.0)
	assert_bool(_skills.eases(Skills.COMBAT, EnergyRules.SWING)).is_true()
	assert_bool(_skills.eases(Skills.COOKING, EnergyRules.SWING)).is_false()
	assert_float(_skills.share_at(1)).is_equal(0.0)
	assert_float(_skills.share_at(0)).override_failure_message("never less than nothing").is_equal(0.0)


func test_each_level_of_cooking_adds_a_tenth_to_a_dish() -> void:
	for case: Array in [[0, 60.0], [10, 66.0], [25, 72.0], [50, 78.0], [90, 84.0]]:
		assert_float(60.0 * _skills.dish_factor({Skills.COOKING: case[0]})).override_failure_message("a stew at %d points" % case[0]).is_equal_approx(case[1], 0.0001)
	assert_float(_skills.dish_factor({Skills.COMBAT: 90, Skills.FARMING: 90})).override_failure_message("only cooking").is_equal(1.0)
	assert_bool(_skills.enriches_dishes(Skills.COOKING)).is_true()
	assert_bool(_skills.enriches_dishes(Skills.FARMING)).is_false()


func test_the_line_names_every_skill_and_its_level() -> void:
	assert_str(_skills.line({})).is_equal("Combat 1   Farming 1   Cooking 1")
	assert_str(_skills.line({Skills.COMBAT: 30, Skills.FARMING: 55, Skills.COOKING: 12})).is_equal("Combat 3   Farming 4   Cooking 2")
	assert_int(_skills.line({Skills.COMBAT: 90, Skills.FARMING: 90, Skills.COOKING: 90}).length()).override_failure_message("it fits the pause menu's 200 pixels at 6 a letter").is_less_equal(33)
	assert_str(_skills.risen_words(Skills.FARMING, 2)).is_equal("Farming rose to level 2.")
	assert_str(_skills.name_of(&"fishing")).override_failure_message("a skill the rules don't name").is_equal("Fishing")


func test_no_rules_make_no_skills_and_change_nothing() -> void:
	var none: Skills = Skills.new()
	assert_array(none.ids()).is_empty()
	assert_int(none.top_level()).is_equal(1)
	assert_int(none.level_at(1000)).is_equal(1)
	assert_int(none.gain(Skills.COMBAT, Skills.MONSTER)).is_equal(0)
	assert_float(none.cost_factor(EnergyRules.SWING, {Skills.COMBAT: 90})).is_equal(1.0)
	assert_float(none.dish_factor({Skills.COOKING: 90})).is_equal(1.0)
	assert_str(none.line({})).is_empty()
	# Garbled parts are passed over, not crashed on.
	var odd: Skills = Skills.new({"levels": "many", "step": "big", "skills": {"combat": "strong", "farming": {"gains": {"till": "lots"}, "eases": "hoe"}}})
	assert_array(odd.ids()).is_equal([Skills.FARMING])
	assert_int(odd.gain(Skills.FARMING, Skills.TILL)).is_equal(0)
	assert_float(odd.cost_factor(EnergyRules.HOE, {Skills.FARMING: 90})).is_equal(1.0)


func test_rules_that_cant_be_used_say_why() -> void:
	var good: Dictionary = {"levels": [0, 5], "step": 0.2, "skills": {"combat": {"name": "Combat", "gains": {"monster": 1}, "eases": ["swing"]}}}
	assert_array(Array(Skills.problems(good, EnergyRules.COSTS))).is_empty()
	var cases: Array = [
		[{"levels": []}, "'levels' must list the points each level begins at, from 0 up."],
		[{"levels": [5, 10]}, "'levels' must be whole numbers that rise, the first of them 0."],
		[{"levels": [0, 10, 10]}, "'levels' must be whole numbers that rise, the first of them 0."],
		[{"levels": [0, 2.5]}, "'levels' must be whole numbers that rise, the first of them 0."],
		[{"step": -0.1}, "'step' must be a number of 0 or more: the share a level takes off a cost."],
		[{"step": "a tenth"}, "'step' must be a number of 0 or more: the share a level takes off a cost."],
		[{"levels": [0, 10, 20], "step": 0.5}, "'step' is too big: at the top level the work would cost nothing."],
		[{"skills": {}}, "'skills' must be an object of the hero's skills."],
		[{"skills": {"combat": "strong"}}, "skill 'combat' must be an object."],
		[{"skills": {"combat": {"gains": {"monster": 1}}}}, "skill 'combat' needs a 'name'."],
		[{"skills": {"combat": {"name": "Combat"}}}, "skill 'combat' needs 'gains': the points each deed gives."],
		[{"skills": {"combat": {"name": "Combat", "gains": {"monster": 0}}}}, "skill 'combat' gains by 'monster' must be a whole number of 1 or more."],
		[{"skills": {"combat": {"name": "Combat", "gains": {"monster": 1}, "eases": "swing"}}}, "skill 'combat' 'eases' must list the costs it makes cheaper."],
		[{"skills": {"combat": {"name": "Combat", "gains": {"monster": 1}, "eases": ["dodge"]}}}, "skill 'combat' eases an unknown cost 'dodge'. Known: sprint_per_second, swing, shot, hoe, water."],
		[{"skills": {"cooking": {"name": "Cooking", "gains": {"dish": 2}, "enriches_dishes": "yes"}}}, "skill 'cooking' 'enriches_dishes' must be true or false."],
	]
	for case: Array in cases:
		var rules: Dictionary = good.duplicate(true)
		rules.merge(case[0], true)
		assert_array(Array(Skills.problems(rules, EnergyRules.COSTS))).override_failure_message("%s" % [case[0]]).contains([case[1]])


func test_bad_skills_data_is_refused_on_load() -> void:
	var registry: Node = auto_free(DataRegistryScript.new())
	var errors: String = "\n".join(registry.load_all("res://tests/fixtures/bad_skills"))
	assert_str(errors).contains("rules 'skills': 'levels' must be whole numbers that rise, the first of them 0.")
	assert_str(errors).contains("rules 'skills': skill 'farming' eases an unknown cost 'plough'.")
	assert_str(errors).contains("effect 'practise' is missing 'deed'.")
	assert_str(errors).contains("no skill 'farming' grows by a deed 'weed' (data/rules/skills.json).")
	assert_str(errors).contains("no skill 'fishing' grows by a deed 'till' (data/rules/skills.json).")
	assert_bool(errors.contains("no skill 'farming' grows by a deed 'till'")).override_failure_message("a deed the rules do name is let through").is_false()
	# The game's own data loads clean, and its rule sets include the skills.
	assert_bool(DataRegistry.RULE_SETS.has(DataRegistry.RULES_SKILLS)).is_true()
	assert_array(Array(DataRegistry.errors)).is_empty()
