extends GdUnitTestSuite
## The hero's poses in the game (art pass 2): an item just taken is held overhead until the
## hero moves, or for a moment; a chest's treasure too; a swing shows the lunge; out of hearts,
## the hero lies fallen.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const VILLAGE: String = "res://world/areas/village/village.tscn"
const FIELDS: String = "res://world/areas/north_fields/north_fields.tscn"

var _area: Node


func before_test() -> void:
	GameState.clear()
	GameState.new_game()


func after_test() -> void:
	if is_instance_valid(_area):
		_area.free()
	_area = null
	Engine.time_scale = 1.0
	GameState.clear()


func test_an_item_just_taken_is_held_up_until_the_hero_moves() -> void:
	var village: AreaController = _load(VILLAGE)
	var sword: ItemPickup = village.interactables.get_node(^"WoodenSword")
	village.player.motor.place(sword.cell())
	village.player.face(Vector2.RIGHT)
	assert_bool(village.player.is_holding_up()).is_false()
	assert_bool(village.interact()).is_true()
	assert_bool(village.player.is_holding_up()).is_true()
	assert_that(village.player.shown_region()).override_failure_message("arms up, seen from the front").is_equal(_frame(PlayerAnimator.HOLD, PlayerAnimator.Facing.DOWN))
	assert_bool((village.player.get_node(^"Sprite") as Sprite2D).flip_h).override_failure_message("and not mirrored, though the hero faced right").is_false()
	village.player.motor.step(Vector2.RIGHT, 0.1)
	village.player.sync_from_motor()
	assert_bool(village.player.is_holding_up()).override_failure_message("moving ends it").is_false()
	assert_int(int(village.player.shown_region().position.y)).override_failure_message("facing the way they walk again").is_equal(int(PlayerAnimator.Facing.SIDE) * 24)


func test_a_held_item_is_put_away_after_a_moment() -> void:
	var village: AreaController = _load(VILLAGE)
	village.player.hold_up(ItemIcons.name_for(&"wooden_sword"))
	village.player._physics_process(PlayerController.HOLD_TIME * 0.5)
	assert_bool(village.player.is_holding_up()).override_failure_message("still held halfway").is_true()
	village.player._physics_process(PlayerController.HOLD_TIME * 0.6)
	assert_bool(village.player.is_holding_up()).is_false()
	assert_that(village.player.shown_region()).override_failure_message("standing again").is_equal(_frame(PlayerAnimator.IDLE, PlayerAnimator.Facing.DOWN))


func test_a_chests_treasure_is_held_up_too() -> void:
	var fields: AreaController = _load(FIELDS)
	var chest: Chest = fields.interactables.get_node(^"MeadowChest")
	fields.player.motor.place(chest.cell() + Vector2i.DOWN)
	fields.player.face(Vector2.UP)
	assert_bool(fields.interact()).is_true()
	assert_bool(fields.player.is_holding_up()).is_true()
	assert_bool(fields.interact()).override_failure_message("an open chest gives nothing more").is_false()


func test_a_swing_shows_the_lunge_and_ends_with_it() -> void:
	GameState.add_item(&"wooden_sword")
	var village: AreaController = _load(VILLAGE)
	village.player.face(Vector2.LEFT)
	assert_bool(village.player.swing()).is_true()
	assert_that(village.player.shown_region()).is_equal(_frame(PlayerAnimator.ATTACK, PlayerAnimator.Facing.SIDE))
	village.player.motor.step(Vector2.ZERO, 0.5)
	village.player.sync_from_motor()
	assert_that(village.player.shown_region()).override_failure_message("standing again").is_equal(_frame(PlayerAnimator.IDLE, PlayerAnimator.Facing.SIDE))


func test_out_of_hearts_the_hero_lies_fallen() -> void:
	var village: AreaController = _load(VILLAGE)
	GameState.damage(99)
	assert_bool(village.is_dying()).is_true()
	assert_int(int(village.player.shown_region().position.x)).is_equal(PlayerAnimator.FALLEN * 16)
	village.respawn()
	assert_int(int(village.player.shown_region().position.x)).override_failure_message("up again").is_equal(PlayerAnimator.IDLE * 16)


func _frame(column: int, facing: PlayerAnimator.Facing) -> Rect2:
	return Rect2(column * 16, int(facing) * 24, 16, 24)


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area
