extends GdUnitTestSuite
## Sword & hearts (H2), in the village training yard: the Wooden Sword is picked up there, it
## hits the dummy only in front of the hero, brambles cost half a heart with knockback and
## invincibility, a recovery heart heals, and at zero hearts the hero comes back at the area's
## entrance with full hearts.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const VILLAGE: String = "res://world/areas/village/village.tscn"
const FRAME: float = 1.0 / 60.0
const SPAWN: Vector2i = Vector2i(23, 20)
## A yard cell just west of the first brambles (11, 32).
const BY_THE_BRAMBLES: Vector2i = Vector2i(9, 32)

var _area: Node


func before_test() -> void:
	GameState.clear()
	GameState.new_game()


func after_test() -> void:
	Input.action_release(&"attack")
	if is_instance_valid(_area):
		_area.free()
	_area = null
	GameState.clear()


func test_the_wooden_sword_is_picked_up_in_the_training_yard() -> void:
	var village: AreaController = _village()
	var pickup: ItemPickup = village.interactables.get_node(^"WoodenSword")
	village.player.motor.place(pickup.cell())
	assert_bool(village.player.swing()).override_failure_message("no sword yet").is_false()
	assert_bool(village.interact()).is_true()
	assert_int(GameState.item_count(&"wooden_sword")).is_equal(1)
	assert_bool(village.player.swing()).is_true()


func test_the_attack_button_swings_the_sword() -> void:
	GameState.add_item(&"wooden_sword")
	var village: AreaController = _village()
	await get_tree().physics_frame
	Input.action_press(&"attack")
	await get_tree().physics_frame
	await get_tree().physics_frame
	assert_bool(village.player.motor.is_attacking()).is_true()
	assert_bool(village.player.sword.active).is_true()


func test_the_sword_hits_the_dummy_only_in_front_of_the_hero() -> void:
	GameState.add_item(&"wooden_sword")
	var village: AreaController = _village()
	var dummy: TrainingDummy = village.interactables.get_node(^"TrainingDummy")
	var at: Vector2i = dummy.cell()
	# [where the hero stands, which way they face, whether the swing hits]
	var cases: Array = [
		[at + Vector2i.DOWN, Vector2.UP, true],
		[at + Vector2i.LEFT, Vector2.RIGHT, true],
		[at + Vector2i.UP, Vector2.DOWN, true],
		[at + Vector2i.DOWN, Vector2.DOWN, false],
		[at + Vector2i.LEFT, Vector2.UP, false],
		[at + Vector2i.LEFT, Vector2.LEFT, false],
		[at + Vector2i.DOWN * 2, Vector2.UP, false],
	]
	for case: Array in cases:
		village.player.motor.place(case[0])
		village.player.face(case[1])
		var before: int = dummy.hits
		assert_bool(village.player.swing()).is_true()
		_play(village, Vector2.ZERO, 0.4)
		var expected: int = 1 if case[2] else 0
		assert_int(dummy.hits - before).override_failure_message("standing at %s facing %s" % [case[0], case[1]]).is_equal(expected)
	assert_str(village.terrain.check_move(at + Vector2i.DOWN, at).reason).override_failure_message("the dummy stands in its cell").is_equal("occupied")


func test_touching_brambles_costs_half_a_heart_with_knockback_and_invincibility() -> void:
	var village: AreaController = _village()
	var motor: PlayerMotor = village.player.motor
	motor.place(BY_THE_BRAMBLES)
	var hit_at: float = _walk_until_hurt(village, Vector2.RIGHT)
	assert_int(GameState.health).override_failure_message("half a heart").is_equal(5)
	assert_that(motor.state_name).is_equal(PlayerMotor.HURT)
	assert_bool(motor.is_invincible()).is_true()
	_play(village, Vector2.ZERO, 0.3)
	assert_float(motor.position.x).override_failure_message("knocked back away from the brambles").is_less_equal(hit_at - 30.0)

	# Invincible: walking straight back into the thorns costs nothing for a while...
	_play(village, Vector2.RIGHT, 0.5)
	assert_int(GameState.health).override_failure_message("invincibility frames").is_equal(5)
	# ...then it wears off, and the thorns still being touched bite again.
	_play(village, Vector2.RIGHT, 0.6)
	assert_int(GameState.health).is_equal(4)


func test_at_zero_hearts_the_hero_respawns_at_the_entrance_with_full_hearts() -> void:
	var village: AreaController = _village()
	GameState.set_health(1)
	village.player.motor.place(BY_THE_BRAMBLES)
	_walk_until_hurt(village, Vector2.RIGHT)
	assert_int(GameState.health).is_equal(0)
	assert_bool(village.is_dying()).is_true()
	assert_that(village.player.motor.state_name).is_equal(PlayerMotor.DEAD)
	assert_bool(village.player.swing()).override_failure_message("no swinging while down").is_false()
	village._process(AreaController.RESPAWN_DELAY / 2.0)
	assert_bool(village.is_dying()).override_failure_message("lies still for a moment first").is_true()
	village._process(AreaController.RESPAWN_DELAY / 2.0 + 0.01)
	assert_bool(village.is_dying()).is_false()
	assert_that(village.player.motor.cell).override_failure_message("back at the entrance").is_equal(SPAWN)
	assert_int(GameState.health).is_equal(GameState.max_health())
	assert_that(village.player.motor.state_name).is_equal(PlayerMotor.GROUND)
	assert_bool(village.player.controls_enabled).is_true()


func test_the_entrance_is_where_the_hero_came_in() -> void:
	GameState.go_to(&"village", &"elder_door")
	var village: AreaController = _village()
	var door: Vector2i = village.player.motor.cell
	assert_that(door).is_equal(Vector2i(30, 15))
	village.player.motor.place(BY_THE_BRAMBLES)
	GameState.damage(GameState.max_health())
	village._process(AreaController.RESPAWN_DELAY + 0.01)
	assert_that(village.player.motor.cell).is_equal(door)
	assert_that(village.player.facing_direction()).is_equal(Vector2i.DOWN)


func test_a_heart_pickup_heals_a_heart_and_is_gone_for_the_visit() -> void:
	var village: AreaController = _village()
	var heart: HeartPickup = village.interactables.get_node(^"Heart")
	GameState.damage(3)
	village.player.motor.place(heart.cell() + Vector2i.RIGHT)
	_play(village, Vector2.LEFT, 0.4)
	assert_int(GameState.health).is_equal(5)
	assert_bool(heart.taken).is_true()
	_play(village, Vector2.RIGHT, 0.3)
	_play(village, Vector2.LEFT, 0.3)
	assert_int(GameState.health).override_failure_message("only once").is_equal(5)
	village = _village()
	assert_bool((village.interactables.get_node(^"Heart") as HeartPickup).taken).override_failure_message("back next visit").is_false()


func _village() -> AreaController:
	_area = Steps.load_area(VILLAGE, _area)
	return _area


## Plays `seconds` of the area frame by frame without the engine loop: the hero steps, the
## area resolves hits and hearts.
func _play(area: AreaController, input: Vector2, seconds: float) -> void:
	for i: int in roundi(seconds / FRAME):
		area.player.motor.step(input, FRAME)
		area.player.sync_from_motor()
		area.resolve_combat()
		area.collect_pickups()


## Walks one way until something hurts the hero; returns their x where it happened.
func _walk_until_hurt(area: AreaController, direction: Vector2) -> float:
	var health: int = GameState.health
	for i: int in 120:
		_play(area, direction, FRAME)
		if GameState.health != health:
			return area.player.motor.position.x
	fail("the hero was never hurt")
	return 0.0
