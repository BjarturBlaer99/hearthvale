extends GdUnitTestSuite
## What the review of the whole codebase found (2026-11-23), each put right: what lies on the
## ground is kept when he leaves or saves; conditions read a light state, not a whole save; a
## damaged or odd save loads as far as it can; the quarry's seed is the game's own formula; the
## clock never goes back; push blocks go back past each other. (An animal cut off from its
## pasture: tests/world/animals_test.gd.)

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const HOMESTEAD: String = "res://world/areas/homestead/homestead.tscn"
const CISTERN: String = "res://world/areas/cistern/cistern.tscn"
const TEST_SLOT: int = 967

var _area: Node
var _went: Array[String] = []


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	_went = []
	SaveSystem.erase_slot(TEST_SLOT)
	SaveSystem.current_slot = TEST_SLOT


func after_test() -> void:
	if is_instance_valid(_area):
		_area.free()
	_area = null
	SaveSystem.erase_slot(TEST_SLOT)
	SaveSystem.current_slot = SaveSystem.GAME_SLOT
	GameState.clear()


# --- What lies on the ground --------------------------------------------------------

func test_what_lies_on_the_ground_is_kept_when_he_leaves() -> void:
	GameState.go_to(&"homestead", &"farmhouse_door")
	var farm: AreaController = _load(HOMESTEAD)
	farm.travel = func(path: String) -> void: _went.append(path)
	var stone: ItemDrop = _drop(farm, &"stone", 8, Vector2i(33, 12))
	assert_bool(stone.has_room()).is_true()
	var exit: AreaExit = farm.exit_at(Vector2i(39, 14))
	assert_object(exit).is_not_null()
	farm.take_exit(exit)
	assert_array(_went).has_size(1)
	assert_int(int(GameState.get_flag(LeftItems.lying_flag(&"homestead", Vector2i(33, 12), &"stone"), 0))).is_equal(8)
	# Back on the farm, it lies there to be picked up.
	GameState.go_to(&"homestead", &"farmhouse_door")
	farm = _load(HOMESTEAD)
	var lying: Array[Dictionary] = LeftItems.lying_in(GameState.flags, &"homestead")
	assert_int(lying.size()).is_equal(1)
	assert_that(lying[0]["item"]).is_equal(&"stone")
	var found: bool = false
	for child: Node in farm.interactables.get_children():
		if child is LeftItem and (child as LeftItem).item_id == &"stone" and (child as LeftItem).cell() == Vector2i(33, 12):
			found = true
			assert_int((child as LeftItem).count).is_equal(8)
	assert_bool(found).override_failure_message("the stone lies where it fell").is_true()


func test_what_lies_on_the_ground_is_kept_by_a_save() -> void:
	GameState.go_to(&"homestead", &"farmhouse_door")
	var farm: AreaController = _load(HOMESTEAD)
	_drop(farm, &"fibre", 3, Vector2i(34, 12))
	assert_int(farm.save_here()).is_equal(OK)
	assert_int(int(GameState.get_flag(LeftItems.lying_flag(&"homestead", Vector2i(34, 12), &"fibre"), 0))).is_equal(3)
	# Still here, it is a LeftItem now (not two of it: the drop is gone).
	await await_idle_frame()
	var drops: int = 0
	var left: int = 0
	for child: Node in farm.interactables.get_children():
		if child is ItemDrop and not child.is_queued_for_deletion():
			drops += 1
		if child is LeftItem and (child as LeftItem).item_id == &"fibre":
			left += 1
	assert_int(drops).is_equal(0)
	assert_int(left).is_equal(1)
	# And what a later visit finds is in the save.
	GameState.clear()
	assert_int(SaveSystem.load_game()).is_equal(OK)
	assert_int(int(GameState.get_flag(LeftItems.lying_flag(&"homestead", Vector2i(34, 12), &"fibre"), 0))).is_equal(3)


func test_a_drop_already_picked_up_is_not_kept() -> void:
	GameState.go_to(&"homestead", &"farmhouse_door")
	var farm: AreaController = _load(HOMESTEAD)
	var coins: ItemDrop = _drop(farm, &"coin", 2, Vector2i(33, 13))
	assert_bool(coins.collect()).is_true()
	assert_int(farm.keep_what_lies()).is_equal(0)
	assert_array(LeftItems.lying_in(GameState.flags, &"homestead")).is_empty()


# --- Conditions read a light state ---------------------------------------------------

func test_conditions_read_the_state_they_need_and_no_more() -> void:
	GameState.add_item(&"coin", 9)
	GameState.set_flag(&"some_flag", true)
	GameState.set_quest_stage(&"a_quest", &"middle")
	var state: Dictionary = GameState.condition_state()
	assert_array(state.keys()).contains_exactly_in_any_order(["day", "flags", "flag_days", "quests", "inventory", "friends"])
	var evaluator: ConditionEvaluator = ConditionEvaluator.for_state(GameState)
	assert_bool(evaluator.is_met({"type": "has_item", "item": "coin", "count": 9})).is_true()
	assert_bool(evaluator.is_met({"type": "flag", "flag": "some_flag", "value": true})).is_true()
	assert_bool(evaluator.is_met({"type": "quest_stage", "quest": "a_quest", "stage": "middle"})).is_true()
	assert_bool(evaluator.is_met({"type": "days_since", "flag": "some_flag", "days": 0})).is_true()


# --- Loading a damaged or odd save --------------------------------------------------

func test_a_save_with_sections_of_the_wrong_shape_loads_as_far_as_it_can() -> void:
	var data: Dictionary = GameState.to_dict()
	data["flags"] = []
	data["quests"] = "nonsense"
	data["inventory"] = [{"id": "coin", "count": 4}, "a string", {"id": 7}, {"count": 2}]
	data["player"] = [1, 2]
	GameState.from_dict(data)
	assert_bool(GameState.is_started()).override_failure_message("the rest of it loaded").is_true()
	assert_int(GameState.item_count(&"coin")).is_equal(4)
	assert_int(GameState.inventory.size()).is_equal(1)
	assert_dict(GameState.flags).is_empty()
	assert_dict(GameState.player).is_empty()


func test_a_loaded_pack_is_checked_against_the_items() -> void:
	var data: Dictionary = GameState.to_dict()
	data["inventory"] = [
		{"id": "wood", "count": 500},
		{"id": "no_such_thing", "count": 3},
		{"id": "stone", "count": 0},
		{"id": "coin", "count": 5}, {"id": "coin", "count": 6},
	]
	GameState.from_dict(data)
	assert_int(GameState.item_count(&"wood")).override_failure_message("a stack of wood holds 50").is_equal(Inventory.capacity(DataRegistry.get_item(&"wood")))
	assert_int(GameState.item_count(&"no_such_thing")).is_equal(0)
	assert_int(GameState.item_count(&"stone")).is_equal(0)
	assert_int(GameState.item_count(&"coin")).override_failure_message("two stacks of one thing, put together").is_equal(11)
	assert_int(GameState.inventory.size()).is_equal(2)


func test_a_loaded_silo_holds_no_more_than_it_can() -> void:
	var data: Dictionary = GameState.to_dict()
	data["homestead"] = {"cleared": [], "hay": 500}
	GameState.from_dict(data)
	assert_int(GameState.homestead().hay).is_equal(60)


# --- The quarry's seed ----------------------------------------------------------------

func test_the_quarrys_seed_is_the_games_own_formula() -> void:
	# Worked out by hand (FNV-1a's step, 64-bit): the same in every version of Godot.
	assert_int(MineRolls.seed_for(20261117, 3, 2)).is_equal(-6246715348648147128)
	assert_int(MineRolls.seed_for(20261117, 3, 3)).is_equal(-6246714249136518917)
	assert_int(MineRolls.seed_for(0, 1, 1)).is_equal(955475604726134)


# --- The clock ----------------------------------------------------------------------

func test_the_clock_never_goes_back() -> void:
	var clock: DayClock = GameState.day_clock()
	assert_float(clock.advance(float(clock.ends) + 30.0, 1.0)).is_equal(float(clock.ends) + 30.0)
	assert_float(clock.advance(float(clock.ends) - 1.0, 1000.0)).is_equal(float(clock.ends))


# --- Push blocks ----------------------------------------------------------------------

func test_two_blocks_on_each_others_start_both_go_back() -> void:
	var cistern: AreaController = _load(CISTERN)
	var a: PushBlock = PushBlock.new()
	a.position = Vector2(Vector2i(4, 39) * 16)
	var b: PushBlock = PushBlock.new()
	b.position = Vector2(Vector2i(8, 39) * 16)
	cistern.interactables.add_child(a)
	cistern.interactables.add_child(b)
	cistern.terrain.set_occupied(a.cell())
	cistern.terrain.set_occupied(b.cell())
	# Swapped: each stands on the other's start.
	_move_block(cistern, a, Vector2i(8, 39), b, Vector2i(4, 39))
	cistern.player.motor.place(Vector2i(22, 27))
	cistern.update_room()
	cistern.reset_blocks()
	assert_that(a.cell()).is_equal(Vector2i(4, 39))
	assert_that(b.cell()).is_equal(Vector2i(8, 39))
	assert_bool(cistern.terrain.is_occupied(Vector2i(4, 39)) and cistern.terrain.is_occupied(Vector2i(8, 39))).is_true()


func _drop(area: AreaController, item_id: StringName, count: int, cell: Vector2i) -> ItemDrop:
	var drop: ItemDrop = ItemDrop.new()
	drop.item_id = item_id
	drop.count = count
	drop.position = Vector2(cell * GreyboxTiles.TILE_SIZE)
	area.interactables.add_child(drop)
	return drop


func _move_block(area: AreaController, first: PushBlock, first_to: Vector2i, second: PushBlock, second_to: Vector2i) -> void:
	for pair: Array in [[first, first_to], [second, second_to]]:
		var block: PushBlock = pair[0]
		area.terrain.set_occupied(block.cell(), false)
	for pair: Array in [[first, first_to], [second, second_to]]:
		var block: PushBlock = pair[0]
		block._home = Vector2(pair[1] as Vector2i) * 16.0
		block.position = block._home
		area.terrain.set_occupied(block.cell(), true)


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area
