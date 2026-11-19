extends GdUnitTestSuite
## Work by hand (tool polish, step 3, D7 and D8): picking a crop or taking what an animal has
## ready, he reaches and then holds it up; petted with nothing to take, a heart rises over the
## animal; hay put in the silo, he reaches and chaff falls. All for show: he can move at once
## (moving ends the pose), and what he picks, takes or puts is as it always was.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const FARM: String = "res://world/areas/homestead/homestead.tscn"
const LAND: StringName = &"homestead"
const FRAME: float = 1.0 / 60.0
const PLOT: Vector2i = Vector2i(22, 17)
const COOP_AT: Vector2i = Vector2i(14, 10)
const SILO_CORNER: Vector2i = Vector2i(36, 11)
## The coop's pen, fenced, so its hens are out on the farm by day (as tests/world/animals_test.gd).
const PEN: Rect2i = Rect2i(13, 13, 6, 3)
const GATE: Vector2i = Vector2i(15, 16)

var _area: Node


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	Quests.refresh()
	_noon()


func after_test() -> void:
	if is_instance_valid(_area):
		_area.free()
	_area = null
	GameState.clear()


func test_a_ripe_crop_is_pulled_up_and_held_up_and_walking_ends_it() -> void:
	(GameState.farm() as Farm).load_saved({"cells": {"3,1": {"watered": true, "crop": "turnip", "stage": 3}}})
	var farm: AreaController = _load()
	_stand(farm, PLOT + Vector2i(2, 1), Vector2.RIGHT)
	var turnips: int = GameState.item_count(&"turnip")
	assert_bool(farm.interact()).is_true()
	assert_int(GameState.item_count(&"turnip")).override_failure_message("picked as ever").is_greater(turnips)
	assert_bool(farm.player.is_reaching()).is_true()
	assert_int(_column(farm)).override_failure_message("he reaches for it").is_equal(PlayerAnimator.REACH)
	assert_bool(farm.player.motor.is_attacking()).override_failure_message("nothing holds him").is_false()
	_wait(farm, PlayerController.REACH_TIME + FRAME)
	assert_bool(farm.player.is_holding_up()).is_true()
	assert_int(_column(farm)).override_failure_message("then holds it up").is_equal(PlayerAnimator.HOLD)
	# One step and it is over.
	farm.player.motor.step(Vector2.LEFT, FRAME)
	farm.player.sync_from_motor()
	assert_bool(farm.player.is_holding_up()).is_false()
	assert_bool(farm.player.is_reaching()).is_false()
	assert_int(_column(farm)).is_not_equal(PlayerAnimator.HOLD)


func test_walking_ends_the_reach_too() -> void:
	(GameState.farm() as Farm).load_saved({"cells": {"3,1": {"watered": true, "crop": "turnip", "stage": 3}}})
	var farm: AreaController = _load()
	_stand(farm, PLOT + Vector2i(2, 1), Vector2.RIGHT)
	farm.interact()
	var before: Vector2 = farm.player.motor.position
	farm.player.motor.step(Vector2.LEFT, FRAME)
	farm.player.sync_from_motor()
	assert_that(farm.player.motor.position).override_failure_message("he moves on the next frame").is_not_equal(before)
	assert_bool(farm.player.is_reaching()).is_false()
	assert_bool(farm.player.is_holding_up()).is_false()


func test_an_egg_taken_is_held_up_and_a_hen_petted_with_none_has_a_heart() -> void:
	GameState.add_item(GameState.COIN, 120)
	_build(&"coop", COOP_AT)
	assert_str(GameState.buy_animal(&"chicken", 60)).is_empty()
	assert_str(GameState.buy_animal(&"chicken", 60)).is_empty()
	(GameState.homestead().animal(0) as Dictionary)["ready"] = true
	_fence_pen()
	GameState.update_player(LAND, Vector2i(16, 15))
	var farm: AreaController = _load()
	var ready: Animal = farm.animals.animal(0)
	var plain: Animal = farm.animals.animal(1)
	_face(farm, ready, Vector2i(16, 14))
	assert_bool(farm.interact()).is_true()
	assert_int(GameState.item_count(&"egg")).override_failure_message("taken as ever").is_equal(1)
	_wait(farm, PlayerController.REACH_TIME + FRAME)
	assert_bool(farm.player.is_holding_up()).override_failure_message("the egg held up").is_true()
	assert_int(_hearts(ready)).override_failure_message("no heart when something is taken").is_equal(0)
	_put(ready, Vector2i(18, 15))
	_face(farm, plain, Vector2i(16, 14))
	assert_bool(farm.interact()).is_true()
	assert_bool(farm.player.is_reaching()).is_true()
	assert_bool(farm.player.is_holding_up()).override_failure_message("nothing to hold up").is_false()
	assert_int(_hearts(plain)).override_failure_message("a heart over the hen").is_equal(1)
	assert_int(GameState.item_count(&"egg")).is_equal(1)


func test_the_heart_rises_a_little_and_is_gone_within_half_a_second() -> void:
	var heart: HeartPop = auto_free(HeartPop.new())
	assert_float(HeartPop.LIFE).is_less_equal(0.5)
	var highest: float = 0.0
	var age: float = 0.0
	while age + FRAME < HeartPop.LIFE:
		heart._process(FRAME)
		age += FRAME
		highest = maxf(highest, heart.height())
	assert_float(highest).override_failure_message("it rises").is_greater(0.0)
	assert_float(highest).override_failure_message("six pixels at the most").is_less_equal(HeartPop.RISE)
	heart._process(FRAME * 2.0)
	assert_bool(heart.is_queued_for_deletion()).is_true()


func test_hay_put_in_the_silo_is_a_reach_and_a_little_chaff() -> void:
	GameState.add_item(&"silo_kit")
	GameState.set_down_kit(LAND, SILO_CORNER, &"silo_kit")
	GameState.start_next_day()
	_noon()
	GameState.add_item(&"hay", 5)
	var farm: AreaController = _load()
	_stand(farm, SILO_CORNER + Vector2i(0, 2), Vector2.UP)
	assert_bool(farm.interact()).is_true()
	assert_int(GameState.homestead().hay).override_failure_message("put in as ever").is_equal(5)
	assert_bool(farm.player.is_reaching()).is_true()
	assert_int(_bursts(farm, &"chaff")).is_equal(1)
	# With no hay to put, no reach and no chaff.
	_wait(farm, PlayerController.REACH_TIME + FRAME)
	assert_bool(farm.interact()).is_true()
	assert_bool(farm.player.is_reaching()).is_false()


func _noon() -> void:
	GameState.set_time(float(GameState.day_clock().in_day("12:00")))


func _build(id: StringName, at: Vector2i) -> void:
	for cell: Vector2i in Buildings.cells_and_doorstep(DataRegistry.get_building(id), at):
		GameState.clear_debris(LAND, cell)
	var kit: StringName = Buildings.kit_for(id, DataRegistry.entries(&"items"))
	GameState.add_item(kit)
	assert_bool(GameState.set_down_kit(LAND, at, kit)).is_true()
	GameState.start_next_day()
	_noon()


## Clears the pen round the coop's door and fences it, with a gate in its south side.
func _fence_pen() -> void:
	var ring: Rect2i = PEN.grow(1)
	for y: int in range(ring.position.y - 1, ring.end.y):
		for x: int in range(ring.position.x, ring.end.x):
			GameState.clear_debris(LAND, Vector2i(x, y))
	for x: int in range(ring.position.x, ring.end.x):
		for y: int in range(ring.position.y, ring.end.y):
			var cell: Vector2i = Vector2i(x, y)
			if PEN.has_point(cell) or GameState.building_covering(LAND, cell) != &"":
				continue
			GameState.homestead().set_down(cell, Placement.STANDING, &"gate" if cell == GATE else &"fence")


func _load() -> AreaController:
	_area = Steps.load_area(FARM, _area)
	return _area


func _stand(area: AreaController, cell: Vector2i, way: Vector2) -> void:
	area.player.motor.place(cell)
	area.player.face(way)


func _face(area: AreaController, animal: Animal, cell: Vector2i) -> void:
	_put(animal, cell)
	area.player.motor.place(cell + Vector2i.DOWN)
	area.player.face(Vector2.UP)


func _put(animal: Animal, cell: Vector2i) -> void:
	animal.motion.position = GridBody.cell_center(cell)
	animal.position = animal.motion.position


## Lets `seconds` pass for the hero, standing still.
func _wait(area: AreaController, seconds: float) -> void:
	var left: float = seconds
	while left > 0.0:
		area.player._physics_process(FRAME)
		left -= FRAME


func _column(area: AreaController) -> int:
	return int(area.player.shown_region().position.x) / PlayerAnimator.FRAME_SIZE.x


func _hearts(animal: Animal) -> int:
	var count: int = 0
	for child: Node in animal.get_children():
		if child is HeartPop and not child.is_queued_for_deletion():
			count += 1
	return count


func _bursts(area: AreaController, kind: StringName) -> int:
	var count: int = 0
	for child: Node in area.interactables.get_children():
		if child is Burst and (child as Burst).kind == kind and not child.is_queued_for_deletion():
			count += 1
	return count
