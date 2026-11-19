extends GdUnitTestSuite
## The blow (tool polish, step 2, D3 to D6): the work is done at the press, as always, but its
## sound, its effects and the new look of what was worked come when the tool lands; a stroke cut
## short still shows them; a rock is drawn whole until its last blow lands, and what it leaves
## shows then; a log shudders and flashes on a blow; nothing costs or gives otherwise.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const FARM: String = "res://world/areas/homestead/homestead.tscn"
const FRAME: float = 1.0 / 60.0
const PLOT: Vector2i = Vector2i(22, 17)
## A rock alone east of the farmhouse, a log alone in the north-west, and the pond's bank.
const ROCK: Vector2i = Vector2i(35, 9)
const LOG: Vector2i = Vector2i(7, 4)
const BANK: Vector2i = Vector2i(3, 22)

var _area: Node
var _heard: Array[StringName] = []


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	Quests.refresh()
	GameState.set_time(float(GameState.day_clock().in_day("12:00")))
	_heard.clear()
	EventBus.sound.connect(_on_sound)


func after_test() -> void:
	EventBus.sound.disconnect(_on_sound)
	if is_instance_valid(_area):
		_area.free()
	_area = null
	GameState.clear()


func test_the_soil_is_tilled_at_once_and_shows_it_when_the_hoe_lands() -> void:
	GameState.add_item(&"hoe")
	var farm: AreaController = _load()
	var cell: Vector2i = PLOT + Vector2i(2, 1)
	_stand(farm, PLOT + Vector2i(1, 1), Vector2.RIGHT)
	assert_bool(farm.use_item()).is_true()
	assert_that(GameState.farm().state_of(Vector2i(2, 1))).override_failure_message("done at the press").is_equal(Farm.TILLED)
	assert_float(GameState.energy).is_equal(98.0)
	assert_that(farm.plot.shown_at(cell)["soil"]).override_failure_message("still bare while the hoe is up").is_equal(Farm.BARE)
	assert_array(_heard).not_contains([&"hoe"])
	assert_int(_bursts(farm, &"clods")).is_equal(0)
	_to_the_blow(farm)
	assert_that(farm.plot.shown_at(cell)["soil"]).is_equal(Farm.TILLED)
	assert_array(_heard).contains([&"hoe"])
	assert_int(_bursts(farm, &"clods")).override_failure_message("clods where it landed").is_equal(1)
	assert_int(_bursts(farm, &"dust")).override_failure_message("no rising dust").is_equal(0)


func test_a_stroke_cut_short_by_a_hit_still_shows_the_cell() -> void:
	GameState.add_item(&"hoe")
	var farm: AreaController = _load()
	_stand(farm, PLOT + Vector2i(1, 1), Vector2.RIGHT)
	assert_bool(farm.use_item()).is_true()
	assert_bool(farm.player.motor.take_hit(Vector2(-40, 0))).is_true()
	assert_that(farm.plot.shown_at(PLOT + Vector2i(2, 1))["soil"]).is_equal(Farm.TILLED)
	assert_array(_heard).contains([&"hoe"])


func test_the_can_pours_onto_the_soil_and_rings_the_pond() -> void:
	GameState.add_item(&"watering_can")
	GameState.equip(&"watering_can")
	GameState.add_item(&"water", 3)
	GameState.till_soil(Vector2i(2, 1))
	var farm: AreaController = _load()
	_stand(farm, PLOT + Vector2i(1, 1), Vector2.RIGHT)
	assert_bool(farm.use_item()).is_true()
	assert_int(GameState.item_count(&"water")).is_equal(2)
	assert_that(farm.plot.shown_at(PLOT + Vector2i(2, 1))["soil"]).is_equal(Farm.TILLED)
	_to_the_blow(farm)
	assert_that(farm.plot.shown_at(PLOT + Vector2i(2, 1))["soil"]).is_equal(Farm.WATERED)
	assert_int(_count(farm, Pour)).override_failure_message("water from the spout").is_equal(1)
	assert_int(_bursts(farm, &"splash")).is_equal(1)
	assert_array(_heard).contains([&"pour"])
	_rest(farm)
	_stand(farm, BANK, Vector2.RIGHT)
	_heard.clear()
	assert_bool(farm.use_item()).is_true()
	assert_int(GameState.item_count(&"water")).override_failure_message("filled at the press").is_greater(2)
	assert_int(_count(farm, Ripple)).is_equal(0)
	_to_the_blow(farm)
	assert_int(_count(farm, Ripple)).override_failure_message("a ring on the pond").is_equal(1)
	assert_array(_heard).contains([&"fill"])


func test_a_seed_falls_from_his_hand_and_shows_planted_then() -> void:
	GameState.add_item(&"turnip_seeds", 2)
	GameState.till_soil(Vector2i(2, 1))
	var farm: AreaController = _load()
	_stand(farm, PLOT + Vector2i(1, 1), Vector2.RIGHT)
	assert_bool(farm.use_item()).is_true()
	assert_str(GameState.farm().crop_at(Vector2i(2, 1))).is_equal("turnip")
	assert_str(str(farm.plot.shown_at(PLOT + Vector2i(2, 1))["crop"])).is_empty()
	_to_the_blow(farm)
	assert_str(str(farm.plot.shown_at(PLOT + Vector2i(2, 1))["crop"])).is_equal("turnip")
	assert_int(_bursts(farm, &"seeds")).is_equal(1)
	assert_array(_heard).contains([&"plant"])


func test_a_rock_is_struck_at_once_and_shows_each_blow_when_the_pickaxe_lands() -> void:
	GameState.add_item(&"pickaxe")
	GameState.equip(&"pickaxe")
	var farm: AreaController = _load()
	var rock: Rock = farm.debris_at(ROCK) as Rock
	_stand(farm, ROCK + Vector2i.LEFT, Vector2.RIGHT)
	var energy: float = GameState.energy
	assert_bool(farm.use_item()).is_true()
	assert_float(GameState.energy).override_failure_message("paid at the press").is_less(energy)
	assert_bool(rock.is_flashing()).is_false()
	assert_int(_bursts(farm, &"chips")).is_equal(0)
	_to_the_blow(farm)
	assert_bool(rock.is_flashing()).override_failure_message("the blow flashes it").is_true()
	assert_int(_bursts(farm, &"chips")).is_equal(1)
	assert_array(_heard).contains([&"pick"])
	_rest(farm)
	# The second blow breaks it: its cell is free and the stone it leaves is there at once, but
	# the rock is drawn whole, and the stone hidden, until the pickaxe lands.
	_heard.clear()
	assert_bool(farm.use_item()).is_true()
	assert_bool(rock.broken).is_true()
	assert_bool(farm.terrain.is_occupied(ROCK)).is_false()
	var stone: ItemDrop = _drop_at(farm, ROCK)
	assert_object(stone).is_not_null()
	assert_bool(rock.visible).override_failure_message("whole while the pickaxe is up").is_true()
	assert_bool(stone.visible).is_false()
	assert_array(_heard).not_contains([&"rock_break"])
	_to_the_blow(farm)
	assert_bool(rock.visible).is_false()
	assert_bool(stone.visible).is_true()
	assert_int(_bursts(farm, &"rubble")).is_equal(1)
	assert_int(_bursts(farm, &"shards")).override_failure_message("no pot's shards").is_equal(0)
	assert_array(_heard).contains([&"rock_break"])


func test_a_log_shudders_and_flashes_on_a_blow_and_throws_splinters() -> void:
	GameState.add_item(&"wooden_sword")
	var farm: AreaController = _load()
	var wood: Breakable = farm.debris_at(LOG) as Breakable
	_stand(farm, LOG + Vector2i.LEFT, Vector2.RIGHT)
	assert_bool(farm.player.swing()).is_true()
	for i: int in 4:
		farm.player.motor.step(Vector2.ZERO, FRAME)
		farm.player.sync_from_motor()
		farm.resolve_combat()
	assert_int(wood.hits_left).override_failure_message("one blow of three").is_equal(2)
	assert_bool(wood.is_flashing()).is_true()
	assert_int(_bursts(farm, &"splinters")).is_equal(1)


func _load() -> AreaController:
	_area = Steps.load_area(FARM, _area)
	return _area


func _stand(area: AreaController, cell: Vector2i, way: Vector2) -> void:
	area.player.motor.place(cell)
	area.player.face(way)


## Steps the stroke until its blow has come.
func _to_the_blow(area: AreaController) -> void:
	while area.player.motor.is_attacking() and (area.player.motor.state as PlayerAttackState).progress() < ToolStroke.BLOW:
		area.player.motor.step(Vector2.ZERO, FRAME)
	area.player.sync_from_motor()


func _rest(area: AreaController) -> void:
	for i: int in 40:
		area.player.motor.step(Vector2.ZERO, FRAME)
	area.player.sync_from_motor()


func _bursts(area: AreaController, kind: StringName) -> int:
	var count: int = 0
	for child: Node in area.interactables.get_children():
		if child is Burst and (child as Burst).kind == kind and not child.is_queued_for_deletion():
			count += 1
	return count


func _count(area: AreaController, type: Variant) -> int:
	var count: int = 0
	for child: Node in area.interactables.get_children():
		if is_instance_of(child, type) and not child.is_queued_for_deletion():
			count += 1
	return count


func _drop_at(area: AreaController, cell: Vector2i) -> ItemDrop:
	for child: Node in area.interactables.get_children():
		if child is ItemDrop and PlayerMotor.cell_of((child as ItemDrop).position + Vector2(8, 8)) == cell:
			return child as ItemDrop
	return null


func _on_sound(id: StringName) -> void:
	_heard.append(id)
