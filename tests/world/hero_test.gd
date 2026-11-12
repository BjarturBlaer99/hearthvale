extends GdUnitTestSuite
## The hero's poses in the game (art pass 2): an item just taken is held overhead until the
## hero moves, or for a moment; a chest's treasure too; a swing shows the lunge; out of hearts,
## the hero lies fallen. And the hero pass (2026-11-11): a swing winds up, slashes and follows
## through without changing when it hits; a sprint leans; a hit makes the hero flinch. Since
## P1e he is two cells tall, standing on the same spot.

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
	assert_int(int(village.player.shown_region().position.y)).override_failure_message("facing the way they walk again").is_equal(int(PlayerAnimator.Facing.SIDE) * PlayerAnimator.FRAME_SIZE.y)


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


func test_a_swing_winds_up_slashes_follows_through_and_ends() -> void:
	GameState.add_item(&"wooden_sword")
	var village: AreaController = _load(VILLAGE)
	village.player.face(Vector2.LEFT)
	assert_bool(village.player.swing()).is_true()
	assert_that(village.player.shown_region()).override_failure_message("gathering first").is_equal(_frame(PlayerAnimator.WINDUP, PlayerAnimator.Facing.SIDE))
	assert_bool(village.player.sword.active).override_failure_message("the blade is live from the first frame, as before").is_true()
	var shown: Array[int] = [PlayerAnimator.WINDUP]
	for i: int in 240:
		village.player.motor.step(Vector2.ZERO, 1.0 / 240.0)
		village.player.sync_from_motor()
		@warning_ignore("integer_division")
		var column: int = int(village.player.shown_region().position.x) / 16
		if shown[-1] != column:
			shown.append(column)
		if not village.player.motor.is_attacking():
			break
	assert_array(shown).override_failure_message("wind-up, slash, follow-through, standing: %s" % [shown]).is_equal([PlayerAnimator.WINDUP, PlayerAnimator.ATTACK, PlayerAnimator.FOLLOW, PlayerAnimator.IDLE])
	assert_int(int(village.player.shown_region().position.y)).override_failure_message("still facing the same way").is_equal(int(PlayerAnimator.Facing.SIDE) * PlayerAnimator.FRAME_SIZE.y)


func test_the_taller_hero_stands_on_the_same_spot() -> void:
	var village: AreaController = _load(VILLAGE)
	var sprite: Sprite2D = village.player.get_node(^"Sprite")
	village.player.sync_from_motor()
	assert_that(sprite.region_rect.size).override_failure_message("a cell wide, two cells tall").is_equal(Vector2(16, 32))
	assert_float(sprite.position.y + sprite.region_rect.size.y).override_failure_message("his soles are at his feet").is_equal(0.0)
	assert_float(sprite.position.x + sprite.region_rect.size.x / 2.0).override_failure_message("and he is centred on them").is_equal(0.0)
	assert_float((village.player.get_node(^"Collision") as CollisionShape2D).shape.get_rect().size.y).override_failure_message("the feet he collides with are no bigger").is_equal(8.0)
	# What he holds up sits on his raised hands: the top painted row of the hold frame.
	var sheet: Image = village.player.sheet().get_image()
	var top: int = -1
	for y: int in PlayerAnimator.FRAME_SIZE.y:
		for x: int in PlayerAnimator.FRAME_SIZE.x:
			if top < 0 and sheet.get_pixel(PlayerAnimator.HOLD * PlayerAnimator.FRAME_SIZE.x + x, y).a > 0.0:
				top = y
	var hands: float = top - PlayerAnimator.FRAME_SIZE.y
	assert_float(PlayerController.HOLD_OFFSET.y + ItemIcons.SIZE.y).override_failure_message("the item rests on his hands, neither floating nor sunk into them").is_equal(hands)
	assert_float(Sword.HAND.y).override_failure_message("the sword is drawn from his belt, not his boots or his head").is_between(-16.0, -8.0)


func test_a_sprint_leans_and_a_walk_does_not() -> void:
	var village: AreaController = _load(VILLAGE)
	village.player.motor.sprinting = false
	for i: int in 12:
		village.player.motor.step(Vector2.DOWN, 1.0 / 60.0)
		village.player.sync_from_motor()
		assert_bool(PlayerAnimator.CYCLE.has(_column(village))).override_failure_message("walking shows the walk cycle").is_true()
	village.player.motor.sprinting = true
	for i: int in 12:
		village.player.motor.step(Vector2.DOWN, 1.0 / 60.0)
		village.player.sync_from_motor()
		assert_bool(PlayerAnimator.RUN_CYCLE.has(_column(village))).override_failure_message("sprinting shows the run cycle").is_true()
	village.player.motor.sprinting = false


func test_a_hit_makes_the_hero_flinch() -> void:
	var village: AreaController = _load(VILLAGE)
	assert_bool(village.player.motor.take_hit(Vector2.RIGHT * 40.0)).is_true()
	village.player.sync_from_motor()
	assert_int(_column(village)).is_equal(PlayerAnimator.HURT)
	for i: int in 120:
		village.player.motor.step(Vector2.ZERO, 1.0 / 60.0)
		village.player.sync_from_motor()
	assert_int(_column(village)).override_failure_message("then stands as before").is_equal(PlayerAnimator.IDLE)


func test_landing_from_a_ledge_hop_bends_the_knees_for_a_moment() -> void:
	var village: AreaController = _load(VILLAGE)
	var step: float = 1.0 / 60.0
	village.player._on_dropped(1)
	var shown: Array[int] = []
	for i: int in roundi((PlayerController.HOP_TIME + PlayerController.LAND_TIME) / step) + 6:
		village.player._physics_process(step)
		if shown.is_empty() or shown[-1] != _column(village):
			shown.append(_column(village))
	assert_array(shown).override_failure_message("in the air, knees bent, standing: %s" % [shown]).is_equal([PlayerAnimator.IDLE, PlayerAnimator.BREATHE, PlayerAnimator.IDLE])
	assert_float(PlayerController.LAND_TIME).override_failure_message("brief: it never holds the hero up").is_less(0.2)
	assert_bool(village.player.controls_enabled).is_true()


func test_out_of_hearts_the_hero_lies_fallen() -> void:
	var village: AreaController = _load(VILLAGE)
	GameState.damage(99)
	assert_bool(village.is_dying()).is_true()
	assert_int(int(village.player.shown_region().position.x)).is_equal(PlayerAnimator.FALLEN * 16)
	village.respawn()
	assert_int(int(village.player.shown_region().position.x)).override_failure_message("up again").is_equal(PlayerAnimator.IDLE * 16)


## The sheet column the hero shows.
func _column(area: AreaController) -> int:
	@warning_ignore("integer_division")
	return int(area.player.shown_region().position.x) / 16


func _frame(column: int, facing: PlayerAnimator.Facing) -> Rect2:
	var size: Vector2i = PlayerAnimator.FRAME_SIZE
	return Rect2(column * size.x, int(facing) * size.y, size.x, size.y)


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area
