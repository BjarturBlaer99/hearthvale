extends GdUnitTestSuite
## ToolStroke (tool polish, 2026-11-19): which pose a stroke of work shows by how far through it
## is, the tool's pose to the hero's, when the sprinkler leaves his hands, and when the blow
## comes. Pictures only: how long a stroke lasts is the tool's.


func test_each_use_has_its_stroke() -> void:
	assert_that(ToolStroke.of_use(ToolUse.TILL)).is_equal(ToolStroke.HOE)
	assert_that(ToolStroke.of_use(ToolUse.WATER)).is_equal(ToolStroke.POUR)
	assert_that(ToolStroke.of_use(ToolUse.FILL)).is_equal(ToolStroke.FILL)
	assert_that(ToolStroke.of_use(ToolUse.PLANT)).is_equal(ToolStroke.SOW)
	assert_that(ToolStroke.of_use(ToolUse.PLACE)).is_equal(ToolStroke.PLACE)
	assert_that(ToolStroke.of_use(ToolUse.MINE)).is_equal(ToolStroke.PICK)
	assert_that(ToolStroke.of_use(ToolUse.NOTHING)).override_failure_message("a use that does nothing is no stroke").is_equal(&"")


func test_the_hoe_and_the_pickaxe_are_raised_until_the_blow_then_struck() -> void:
	for kind: StringName in [ToolStroke.HOE, ToolStroke.PICK]:
		assert_that(ToolStroke.pose(kind, 0.0)).override_failure_message("%s at the start" % kind).is_equal(ToolStroke.RAISE)
		assert_that(ToolStroke.pose(kind, ToolStroke.BLOW - 0.001)).is_equal(ToolStroke.RAISE)
		assert_that(ToolStroke.pose(kind, ToolStroke.BLOW)).override_failure_message("%s at the blow" % kind).is_equal(ToolStroke.STRIKE)
		assert_that(ToolStroke.pose(kind, 1.0)).override_failure_message("%s to the end" % kind).is_equal(ToolStroke.STRIKE)
	assert_float(ToolStroke.BLOW).override_failure_message("the blow comes after the raise and well before the end").is_between(0.2, 0.5)


func test_the_can_pours_or_dips_and_a_seed_or_sprinkler_is_reached_down() -> void:
	for progress: float in [0.0, 0.5, 1.0]:
		assert_that(ToolStroke.pose(ToolStroke.POUR, progress)).is_equal(ToolStroke.TIP)
		assert_that(ToolStroke.pose(ToolStroke.FILL, progress)).is_equal(ToolStroke.DIP)
		assert_that(ToolStroke.pose(ToolStroke.SOW, progress)).is_equal(ToolStroke.REACH)
		assert_that(ToolStroke.pose(ToolStroke.PLACE, progress)).is_equal(ToolStroke.REACH)
	assert_that(ToolStroke.pose(&"sword", 0.5)).override_failure_message("a swing is no stroke of work").is_equal(&"")


func test_the_hero_shows_one_of_his_four_work_poses() -> void:
	assert_that(ToolStroke.hero_pose(ToolStroke.RAISE)).is_equal(&"raise")
	assert_that(ToolStroke.hero_pose(ToolStroke.STRIKE)).is_equal(&"strike")
	assert_that(ToolStroke.hero_pose(ToolStroke.TIP)).is_equal(&"pour")
	assert_that(ToolStroke.hero_pose(ToolStroke.DIP)).override_failure_message("a can dipped is held in a reach").is_equal(&"reach")
	assert_that(ToolStroke.hero_pose(ToolStroke.REACH)).is_equal(&"reach")
	for kind: StringName in ToolStroke.KINDS:
		for progress: float in [0.0, 0.5, 1.0]:
			assert_bool(PlayerAnimator.WORK_COLUMNS.has(ToolStroke.hero_pose(ToolStroke.pose(kind, progress)))) \
				.override_failure_message("%s at %.1f has a column" % [kind, progress]).is_true()


func test_the_sprinkler_leaves_his_hands_at_the_blow_and_tools_stay() -> void:
	assert_bool(ToolStroke.holds(ToolStroke.PLACE, 0.0)).is_true()
	assert_bool(ToolStroke.holds(ToolStroke.PLACE, ToolStroke.BLOW)).override_failure_message("set down on the soil").is_false()
	for kind: StringName in [ToolStroke.HOE, ToolStroke.PICK, ToolStroke.POUR, ToolStroke.FILL, ToolStroke.SOW]:
		assert_bool(ToolStroke.holds(kind, 1.0)).override_failure_message(String(kind)).is_true()
	assert_bool(ToolStroke.holds(&"", 0.0)).is_false()


func test_the_blow_comes_once_in_a_stroke() -> void:
	var blows: int = 0
	var before: float = -1.0
	for step: int in 25:
		var after: float = step / 24.0
		if ToolStroke.blow_between(ToolStroke.HOE, before, after):
			blows += 1
		before = after
	assert_int(blows).is_equal(1)
	assert_bool(ToolStroke.blow_between(&"", -1.0, 1.0)).override_failure_message("no stroke, no blow").is_false()
