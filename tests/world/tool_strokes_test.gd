extends GdUnitTestSuite
## The hero at work (tool polish, step 1): a stroke of a tool shows his work poses and the tool
## in his hands, by the motor's own progress, for exactly as long as the stroke always lasted;
## facing up the tool is behind him; a swing is still the sword's; a seed is sown by hand; the
## sprinkler leaves his hands at the blow; a hit puts the tool away.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const FARM: String = "res://world/areas/homestead/homestead.tscn"
const FRAME: float = 1.0 / 60.0
## The field's clear corner (its plot's own cells 0..5, 0..2), a rock that stands alone east of
## the farmhouse, and the pond's west bank.
const PLOT: Vector2i = Vector2i(22, 17)
const ROCK: Vector2i = Vector2i(35, 9)
const BANK: Vector2i = Vector2i(3, 22)

var _area: Node


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	Quests.refresh()
	GameState.set_time(float(GameState.day_clock().in_day("12:00")))


func after_test() -> void:
	if is_instance_valid(_area):
		_area.free()
	_area = null
	GameState.clear()


func test_the_hoe_is_raised_then_struck_in_his_hands_for_as_long_as_a_stroke_lasts() -> void:
	GameState.add_item(&"hoe")
	var farm: AreaController = _load()
	_stand(farm, PLOT + Vector2i(1, 1), Vector2.RIGHT)
	assert_bool(farm.use_item()).is_true()
	assert_that(farm.player.work_stroke()).is_equal(ToolStroke.HOE)
	assert_int(_column(farm)).override_failure_message("raised").is_equal(PlayerAnimator.RAISE)
	var held: HeldTool = farm.player.held_tool()
	assert_bool(held.visible).is_true()
	assert_int(held.frame_index).is_equal(HeldTools.frame_of(&"hoe", "side", ToolStroke.RAISE))
	assert_bool(held.flip_h).override_failure_message("facing right, the tool is mirrored with him").is_true()
	assert_int(held.get_index()).override_failure_message("in front of him").is_greater(_sprite(farm).get_index())
	# The bare motor, with the same stroke, is the clock: the pictures never lengthen it.
	var bare: PlayerMotor = PlayerMotor.new(farm.terrain)
	bare.place(PLOT + Vector2i(1, 1))
	bare.attack(Vector2i.RIGHT, ToolUse.time_of(DataRegistry.get_item(&"hoe")))
	var struck: bool = false
	var steps: int = 0
	while farm.player.motor.is_attacking():
		assert_bool(bare.is_attacking()).override_failure_message("step %d: he stands still no longer than before" % steps).is_true()
		var progress: float = (farm.player.motor.state as PlayerAttackState).progress()
		assert_int(_column(farm)).override_failure_message("at %.2f" % progress) \
			.is_equal(PlayerAnimator.RAISE if progress < ToolStroke.BLOW else PlayerAnimator.STRIKE)
		if progress >= ToolStroke.BLOW:
			struck = true
			assert_int(held.frame_index).is_equal(HeldTools.frame_of(&"hoe", "side", ToolStroke.STRIKE))
		farm.player.motor.step(Vector2.ZERO, FRAME)
		bare.step(Vector2.ZERO, FRAME)
		farm.player.sync_from_motor()
		steps += 1
	assert_bool(bare.is_attacking()).override_failure_message("and no shorter").is_false()
	assert_bool(struck).override_failure_message("the blow was shown").is_true()
	assert_bool(held.visible).override_failure_message("put away when the stroke is done").is_false()
	assert_that(farm.player.work_stroke()).is_equal(&"")
	assert_int(_column(farm)).is_less(PlayerAnimator.RAISE)


func test_facing_up_the_tool_is_behind_him() -> void:
	GameState.add_item(&"hoe")
	var farm: AreaController = _load()
	_stand(farm, PLOT + Vector2i(1, 2), Vector2.UP)
	assert_bool(farm.use_item()).is_true()
	var held: HeldTool = farm.player.held_tool()
	assert_int(held.frame_index).is_equal(HeldTools.frame_of(&"hoe", "up", ToolStroke.RAISE))
	assert_int(held.get_index()).override_failure_message("drawn before him, so behind").is_less(_sprite(farm).get_index())
	assert_bool(held.flip_h).is_false()


func test_a_copper_pickaxe_on_a_rock_is_copper_in_his_hands() -> void:
	GameState.add_item(&"copper_pickaxe")
	GameState.equip(&"copper_pickaxe")
	var farm: AreaController = _load()
	_stand(farm, ROCK + Vector2i.LEFT, Vector2.RIGHT)
	assert_bool(farm.use_item()).is_true()
	assert_that(farm.player.work_stroke()).is_equal(ToolStroke.PICK)
	assert_int(farm.player.held_tool().frame_index).is_equal(HeldTools.frame_of(&"copper_pickaxe", "side", ToolStroke.RAISE))
	assert_int(farm.player.held_tool().frame_index).is_not_equal(HeldTools.frame_of(&"pickaxe", "side", ToolStroke.RAISE))


func test_a_swing_after_a_stroke_is_the_swords_with_nothing_in_his_hands() -> void:
	GameState.add_item(&"wooden_sword")
	GameState.add_item(&"hoe")
	GameState.equip(&"hoe")
	var farm: AreaController = _load()
	_stand(farm, PLOT + Vector2i(1, 1), Vector2.RIGHT)
	assert_bool(farm.use_item()).is_true()
	_rest(farm)
	assert_bool(farm.player.swing()).is_true()
	assert_that(farm.player.work_stroke()).is_equal(&"")
	assert_bool(farm.player.held_tool().visible).is_false()
	assert_int(_column(farm)).is_between(PlayerAnimator.WINDUP, PlayerAnimator.FOLLOW)


func test_a_seed_is_sown_by_hand() -> void:
	GameState.add_item(&"turnip_seeds", 2)
	GameState.till_soil(Vector2i(2, 1))
	var farm: AreaController = _load()
	_stand(farm, PLOT + Vector2i(1, 1), Vector2.RIGHT)
	assert_bool(farm.use_item()).is_true()
	assert_that(farm.player.work_stroke()).is_equal(ToolStroke.SOW)
	assert_int(_column(farm)).is_equal(PlayerAnimator.REACH)
	assert_bool(farm.player.held_tool().visible).override_failure_message("nothing in his hand but the seed").is_false()


func test_the_sprinkler_leaves_his_hands_at_the_blow() -> void:
	GameState.add_item(&"sprinkler")
	GameState.equip(&"sprinkler")
	GameState.till_soil(Vector2i(2, 1))
	var farm: AreaController = _load()
	_stand(farm, PLOT + Vector2i(1, 1), Vector2.RIGHT)
	assert_bool(farm.use_item()).is_true()
	assert_int(farm.player.held_tool().frame_index).is_equal(HeldTools.frame_of(&"sprinkler", "side", ToolStroke.REACH))
	while (farm.player.motor.state as PlayerAttackState).progress() < ToolStroke.BLOW:
		farm.player.motor.step(Vector2.ZERO, FRAME)
	farm.player.sync_from_motor()
	assert_bool(farm.player.motor.is_attacking()).is_true()
	assert_int(_column(farm)).override_failure_message("still reaching").is_equal(PlayerAnimator.REACH)
	assert_bool(farm.player.held_tool().visible).override_failure_message("set down").is_false()


func test_the_can_is_dipped_at_the_pond_and_tipped_over_the_soil() -> void:
	GameState.add_item(&"watering_can")
	GameState.equip(&"watering_can")
	var farm: AreaController = _load()
	_stand(farm, BANK, Vector2.RIGHT)
	assert_bool(farm.use_item()).is_true()
	assert_that(farm.player.work_stroke()).is_equal(ToolStroke.FILL)
	assert_int(_column(farm)).is_equal(PlayerAnimator.REACH)
	assert_int(farm.player.held_tool().frame_index).is_equal(HeldTools.frame_of(&"watering_can", "side", ToolStroke.DIP))
	_rest(farm)
	GameState.till_soil(Vector2i(2, 1))
	_stand(farm, PLOT + Vector2i(1, 1), Vector2.RIGHT)
	assert_bool(farm.use_item()).is_true()
	assert_int(_column(farm)).is_equal(PlayerAnimator.POUR)
	assert_int(farm.player.held_tool().frame_index).is_equal(HeldTools.frame_of(&"watering_can", "side", ToolStroke.TIP))


func test_a_hit_puts_the_tool_away() -> void:
	GameState.add_item(&"hoe")
	var farm: AreaController = _load()
	_stand(farm, PLOT + Vector2i(1, 1), Vector2.RIGHT)
	assert_bool(farm.use_item()).is_true()
	assert_bool(farm.player.motor.take_hit(Vector2(40, 0))).is_true()
	farm.player.sync_from_motor()
	assert_bool(farm.player.held_tool().visible).is_false()
	assert_that(farm.player.work_stroke()).is_equal(&"")


func _load() -> AreaController:
	_area = Steps.load_area(FARM, _area)
	return _area


func _stand(area: AreaController, cell: Vector2i, way: Vector2) -> void:
	area.player.motor.place(cell)
	area.player.face(way)


func _rest(area: AreaController) -> void:
	for i: int in 40:
		area.player.motor.step(Vector2.ZERO, FRAME)
	area.player.sync_from_motor()


func _column(area: AreaController) -> int:
	return int(area.player.shown_region().position.x) / PlayerAnimator.FRAME_SIZE.x


func _sprite(area: AreaController) -> Sprite2D:
	return area.player.get_node("Sprite") as Sprite2D
