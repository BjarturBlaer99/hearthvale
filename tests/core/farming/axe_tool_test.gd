extends GdUnitTestSuite
## The axe as a tool (icons-axe-bar plan, step A2), pure: what a stroke does, how much a blow
## of each axe counts for, its stroke's poses, and what it costs. Tried on the game's own items.

const AXES: Array[StringName] = [&"axe", &"copper_axe", &"iron_axe"]


func test_the_axe_cuts_wood_and_says_so_when_there_is_none() -> void:
	assert_dict(ToolUse.decide_chop(true)).is_equal({"does": ToolUse.CUT, "says": ""})
	assert_dict(ToolUse.decide_chop(false)).is_equal({"does": ToolUse.NOTHING, "says": ToolUse.CHOP_NOTHING})
	assert_str(ToolUse.CHOP_NOTHING).is_not_empty()
	# The plot's own decisions know nothing of it: the area asks decide_chop().
	assert_dict(ToolUse.decide(ToolUse.CHOP, Farm.BARE, false, 0, 0)).is_equal({"does": ToolUse.NOTHING, "says": ""})


func test_the_three_axes_are_tools_and_the_better_ones_count_for_more() -> void:
	# [item, blows fewer, hits a blow counts for, blows a stump of three takes]
	var cases: Array = [[&"axe", 0, 1, 3], [&"copper_axe", 1, 2, 2], [&"iron_axe", 2, 3, 1]]
	for case: Array in cases:
		var item: Dictionary = DataRegistry.get_item(case[0])
		var what: String = String(case[0])
		assert_bool(item.is_empty()).override_failure_message(what + " is an item").is_false()
		assert_str(str(item["type"])).is_equal(ToolUse.TYPE)
		assert_str(ToolUse.kind_of(item)).override_failure_message(what).is_equal(ToolUse.CHOP)
		assert_array(Array(ToolUse.problems(item))).override_failure_message(what).is_empty()
		assert_int(ToolUse.fewer_blows(item)).override_failure_message(what + ": blows fewer").is_equal(case[1])
		assert_int(ToolUse.hits_of_blow(item)).override_failure_message(what + ": hits a blow").is_equal(case[2])
		assert_int(ceili(3.0 / ToolUse.hits_of_blow(item))).override_failure_message(what + ": a stump").is_equal(case[3])
		assert_int(ToolUse.reach(item)).override_failure_message(what + " works one cell").is_equal(1)
		assert_float(ToolUse.time_of(item)).override_failure_message(what + ": the pickaxe's stroke").is_equal(0.4)
		assert_bool(Inventory.is_equippable(item)).override_failure_message(what + " goes on the bar").is_true()
		assert_that(ItemIcons.name_for(case[0])).override_failure_message(what + " has its own icon").is_equal(case[0])
		assert_bool(HeldTools.has_item(case[0])).override_failure_message(what + " is drawn in his hands").is_true()
		assert_bool(item.get("stackable", false)).override_failure_message(what + " doesn't stack").is_false()


func test_fewer_blows_is_any_tools_and_nothing_elses() -> void:
	# The pickaxes read as they always did.
	assert_int(ToolUse.fewer_blows(DataRegistry.get_item(&"pickaxe"))).is_equal(0)
	assert_int(ToolUse.fewer_blows(DataRegistry.get_item(&"copper_pickaxe"))).is_equal(1)
	assert_int(ToolUse.fewer_blows(DataRegistry.get_item(&"iron_pickaxe"))).is_equal(2)
	# A tool of any kind is read by its stat, not by being a pickaxe.
	assert_int(ToolUse.fewer_blows({"type": "tool", "stats": {"tool": "chop", "fewer_blows": 4}})).is_equal(4)
	assert_int(ToolUse.fewer_blows({"type": "tool", "stats": {"tool": "hoe"}})).is_equal(0)
	# What isn't a tool saves nothing, whatever it says; a bad number is none.
	assert_int(ToolUse.fewer_blows({"type": "food", "stats": {"fewer_blows": 3}})).is_equal(0)
	assert_int(ToolUse.fewer_blows({"type": "tool", "stats": {"tool": "chop", "fewer_blows": -2}})).is_equal(0)
	assert_int(ToolUse.fewer_blows({"type": "tool", "stats": "chop"})).is_equal(0)
	assert_int(ToolUse.hits_of_blow({})).override_failure_message("nothing in hand is one blow").is_equal(1)


func test_the_axes_stroke_is_raised_then_struck() -> void:
	assert_that(ToolStroke.of_use(ToolUse.CUT)).is_equal(ToolStroke.CHOP)
	assert_bool(ToolStroke.KINDS.has(ToolStroke.CHOP)).is_true()
	assert_that(ToolStroke.pose(ToolStroke.CHOP, 0.0)).is_equal(ToolStroke.RAISE)
	assert_that(ToolStroke.pose(ToolStroke.CHOP, ToolStroke.BLOW)).is_equal(ToolStroke.STRIKE)
	assert_bool(ToolStroke.holds(ToolStroke.CHOP, 0.9)).override_failure_message("held to the end").is_true()
	assert_bool(ToolStroke.blow_between(ToolStroke.CHOP, 0.2, 0.4)).is_true()
	for axe: StringName in AXES:
		for facing: String in ["down", "up", "side"]:
			for pose: StringName in [ToolStroke.RAISE, ToolStroke.STRIKE]:
				assert_int(HeldTools.frame_of(axe, facing, pose)).override_failure_message("%s %s %s" % [axe, facing, pose]).is_greater_equal(0)


func test_a_blow_of_the_axe_costs_half_a_point_and_no_skill_eases_it() -> void:
	var rules: EnergyRules = EnergyRules.new(DataRegistry.get_rules(DataRegistry.RULES_ENERGY))
	assert_float(rules.cost(EnergyRules.CHOP)).is_equal(0.5)
	assert_float(rules.cost(EnergyRules.CHOP)).override_failure_message("what a swing of the sword cost on wood").is_equal(rules.cost(EnergyRules.SWING))
	assert_float(float(EnergyRules.DEFAULTS["costs"]["chop"])).is_equal(0.5)
	var skills: Skills = Skills.new(DataRegistry.get_rules(DataRegistry.RULES_SKILLS))
	var masters: Dictionary = {}
	for skill: StringName in [Skills.COMBAT, Skills.FARMING, Skills.COOKING, Skills.MINING]:
		masters[skill] = 1000
	assert_float(skills.cost_factor(EnergyRules.CHOP, masters)).override_failure_message("no skill eases chopping (Q8)").is_equal(1.0)
