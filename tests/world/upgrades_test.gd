extends GdUnitTestSuite
## Tool upgrades, the sprinkler and the Miner's Lantern in play (crafting, phase 2c): each is
## made at the workbench from the tool before it; a better hoe tills and a better can waters
## further in one stroke for the same energy; a better pickaxe breaks a rock in fewer blows;
## a sprinkler is set on the plot from the item bar, waters its four cells each morning, and
## is taken up again; the Miner's Lantern lights further.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const FARM: String = "res://world/areas/homestead/homestead.tscn"
const FRAME: float = 1.0 / 60.0
const SIDES: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
## The plot's north-west corner in Hearthvale.
## The field's north-west corner on the homestead: its clear corner is worked here.
const PLOT: Vector2i = Vector2i(22, 17)

var _area: Node
var _heard: Array[StringName] = []


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	Quests.refresh()
	GameState.mine().number = 20261117
	GameState.set_time(GameState.day_clock().in_day("12:00"))
	_heard.clear()
	EventBus.sound.connect(_on_sound)


func after_test() -> void:
	EventBus.sound.disconnect(_on_sound)
	if is_instance_valid(_area):
		_area.free()
	_area = null
	GameState.clear()


func test_every_upgrade_is_made_from_the_tool_before_it() -> void:
	# [recipe, what it takes besides bars, bars, how many, when it is known]
	var cases: Array = [
		[&"copper_hoe", "hoe", "copper_bar", 2, {"found": "copper_bar"}],
		[&"copper_watering_can", "watering_can", "copper_bar", 2, {"found": "copper_bar"}],
		[&"copper_pickaxe", "pickaxe", "copper_bar", 3, {"skill": "mining", "level": 2.0}],
		[&"iron_hoe", "copper_hoe", "iron_bar", 2, {"found": "iron_bar"}],
		[&"iron_watering_can", "copper_watering_can", "iron_bar", 2, {"found": "iron_bar"}],
		[&"iron_pickaxe", "copper_pickaxe", "iron_bar", 3, {"skill": "mining", "level": 3.0}],
	]
	for case: Array in cases:
		var recipe: Dictionary = DataRegistry.get_crafting(case[0])
		assert_array(Crafting.needs_of(recipe)).override_failure_message(String(case[0])).is_equal([{"item": case[1], "count": 1}, {"item": case[2], "count": case[3]}])
		assert_str(Crafting.item_made(recipe)).is_equal(String(case[0]))
		assert_dict(recipe["unlock"]).override_failure_message("%s: when it is known" % case[0]).is_equal(case[4])
	assert_array(Crafting.needs_of(DataRegistry.get_crafting(&"sprinkler"))).is_equal([{"item": "copper_bar", "count": 1}, {"item": "iron_bar", "count": 1}])
	assert_dict(DataRegistry.get_crafting(&"sprinkler")["unlock"]).is_equal({"skill": "farming", "level": 2.0})
	assert_array(Crafting.needs_of(DataRegistry.get_crafting(&"miners_lantern"))).is_equal([{"item": "lantern", "count": 1}, {"item": "gold_bar", "count": 1}, {"item": "crystal", "count": 1}])
	assert_dict(DataRegistry.get_crafting(&"miners_lantern")["unlock"]).is_equal({"found": "crystal"})
	# The whole list, in the workbench's order (cloth and the wool blanket since the Homestead's
	# phase 4: tests/world/animal_products_test.gd).
	var all: Array = Crafting.of_tab(Crafting.of_station(DataRegistry.entries(&"crafting"), Crafting.WORKBENCH), Crafting.TAB_MAKE).map(func(recipe: Dictionary) -> String: return str(recipe["id"]))
	assert_array(all).is_equal(["furnace", "chest", "bombs", "sprinkler", "copper_hoe", "copper_watering_can", "copper_pickaxe",
		"iron_hoe", "iron_watering_can", "iron_pickaxe", "miners_lantern", "rug", "lamp", "cloth", "wool_blanket"])
	assert_array(Array(DataRegistry.errors)).is_empty()


func test_an_upgrade_takes_the_old_tool_and_the_new_one_takes_its_place_in_his_hand() -> void:
	GameState.add_item(&"wooden_sword")
	GameState.add_item(&"hoe")
	GameState.add_item(&"watering_can")
	GameState.add_item(&"water", 7)
	GameState.add_item(&"copper_bar", 4)
	GameState.equip(&"watering_can")
	assert_str(GameState.craft(&"copper_watering_can")).is_equal("")
	assert_int(GameState.item_count(&"watering_can")).override_failure_message("the old can is gone").is_equal(0)
	assert_int(GameState.item_count(&"copper_watering_can")).is_equal(1)
	assert_int(GameState.item_count(&"copper_bar")).is_equal(2)
	assert_int(GameState.item_count(&"water")).override_failure_message("the water he carried is in the new can").is_equal(7)
	assert_that(GameState.equipped).override_failure_message("the new can is in his hand").is_equal(&"copper_watering_can")
	# One not in his hand stays out of it.
	assert_str(GameState.craft(&"copper_hoe")).is_equal("")
	assert_int(GameState.item_count(&"hoe")).is_equal(0)
	assert_int(GameState.item_count(&"copper_hoe")).is_equal(1)
	assert_that(GameState.equipped).is_equal(&"copper_watering_can")
	# Without the tool before it, it can't be made; and iron wants the copper one.
	GameState.add_item(&"copper_bar", 2)
	assert_str(GameState.craft(&"copper_hoe")).override_failure_message("no plain hoe left").is_equal(Crafting.LACKING_WORDS)
	GameState.add_item(&"iron_bar", 4)
	assert_str(GameState.craft(&"iron_hoe")).is_equal("")
	assert_int(GameState.item_count(&"copper_hoe")).is_equal(0)
	assert_int(GameState.item_count(&"iron_hoe")).is_equal(1)
	# The pickaxes wait on his Mining.
	GameState.add_item(&"pickaxe")
	GameState.add_item(&"copper_bar", 3)
	assert_str(GameState.craft(&"copper_pickaxe")).is_equal(Crafting.UNKNOWN_WORDS)
	GameState.skill_points[Skills.MINING] = 10
	assert_str(GameState.craft(&"copper_pickaxe")).is_equal("")
	assert_str(GameState.craft(&"iron_pickaxe")).override_failure_message("iron wants the third level").is_equal(Crafting.UNKNOWN_WORDS)


func test_a_thing_made_stays_out_of_a_hand_that_holds_the_sword_by_choice() -> void:
	GameState.add_item(&"wooden_sword")
	GameState.add_item(&"hoe")
	GameState.add_item(&"watering_can")
	GameState.add_item(&"copper_bar", 2)
	GameState.add_item(&"coal", 1)
	GameState.add_item(&"stone", 3)
	assert_that(GameState.equipped).override_failure_message("his first tool went on the item button").is_equal(&"hoe")
	GameState.equip(&"")
	assert_str(GameState.craft(&"copper_hoe")).is_equal("")
	assert_int(GameState.item_count(&"copper_hoe")).is_equal(1)
	assert_that(GameState.equipped).override_failure_message("the hoe was not in his hand: the copper one isn't either").is_equal(&"")
	assert_str(GameState.craft(&"bombs")).is_equal("")
	assert_that(GameState.equipped).override_failure_message("bombs made go on the bar, not into his hand").is_equal(&"")


func test_a_better_hoe_tills_further_in_one_stroke_for_the_same_energy() -> void:
	GameState.add_item(&"copper_hoe")
	GameState.equip(&"copper_hoe")
	var farm: AreaController = _load(FARM)
	_stand(farm, PLOT + Vector2i(0, 1), Vector2.RIGHT)
	assert_bool(farm.use_item()).is_true()
	assert_that(GameState.farm().state_of(Vector2i(1, 1))).is_equal(Farm.TILLED)
	assert_that(GameState.farm().state_of(Vector2i(2, 1))).override_failure_message("and the cell beyond").is_equal(Farm.TILLED)
	assert_that(GameState.farm().state_of(Vector2i(3, 1))).is_equal(Farm.BARE)
	assert_int(GameState.farm().count_of(Farm.TILLED)).is_equal(2)
	assert_float(GameState.energy).override_failure_message("one stroke's energy for both").is_equal(98.0)
	assert_int(int(GameState.skill_points.get(Skills.FARMING, 0))).override_failure_message("each cell tilled is practice").is_equal(2)
	_finish(farm)
	# The iron hoe tills three; a cell already tilled in the line is passed over, not paid for.
	GameState.add_item(&"iron_hoe")
	GameState.equip(&"iron_hoe")
	_stand(farm, PLOT + Vector2i(2, 1), Vector2.RIGHT)
	assert_bool(farm.use_item()).is_true()
	for x: int in [3, 4, 5]:
		assert_that(GameState.farm().state_of(Vector2i(x, 1))).is_equal(Farm.TILLED)
	assert_float(GameState.energy).is_equal(96.0)
	_finish(farm)
	# At the plot's edge the stroke stops with the plot.
	_stand(farm, PLOT + Vector2i(1, 0), Vector2.LEFT)
	assert_bool(farm.use_item()).is_true()
	assert_that(GameState.farm().state_of(Vector2i(0, 0))).is_equal(Farm.TILLED)
	assert_int(GameState.farm().count_of(Farm.TILLED)).override_failure_message("one more cell, and nothing outside the plot").is_equal(6)
	_finish(farm)
	# The cell he faces decides: tilled already, the stroke isn't made, though bare soil lies beyond.
	_stand(farm, PLOT + Vector2i(1, 2), Vector2.UP)
	assert_bool(farm.use_item()).is_false()
	assert_str(farm.hud.message_text()).is_equal(ToolUse.HOE_DONE)
	assert_float(GameState.energy).is_equal(94.0)


func test_a_better_can_waters_further_with_one_pour() -> void:
	GameState.add_item(&"copper_watering_can")
	GameState.add_item(&"water", 10)
	GameState.equip(&"copper_watering_can")
	for x: int in 6:
		GameState.till_soil(Vector2i(x, 1))
	GameState.plant_crop(Vector2i(1, 1), &"turnip")
	var farm: AreaController = _load(FARM)
	_stand(farm, PLOT + Vector2i(0, 1), Vector2.RIGHT)
	assert_bool(farm.use_item()).is_true()
	assert_bool(GameState.farm().is_watered(Vector2i(1, 1))).is_true()
	assert_bool(GameState.farm().is_watered(Vector2i(2, 1))).override_failure_message("and the cell beyond").is_true()
	assert_bool(GameState.farm().is_watered(Vector2i(3, 1))).is_false()
	assert_int(GameState.item_count(&"water")).override_failure_message("one pour for both").is_equal(9)
	assert_float(GameState.energy).is_equal(99.0)
	_finish(farm)
	GameState.add_item(&"iron_watering_can")
	GameState.equip(&"iron_watering_can")
	_stand(farm, PLOT + Vector2i(2, 1), Vector2.RIGHT)
	assert_bool(farm.use_item()).is_true()
	for x: int in [3, 4, 5]:
		assert_bool(GameState.farm().is_watered(Vector2i(x, 1))).is_true()
	assert_int(GameState.item_count(&"water")).is_equal(8)
	assert_float(GameState.energy).is_equal(98.0)
	_finish(farm)
	# Wet already, the cell he faces takes no pour.
	_stand(farm, PLOT + Vector2i(0, 1), Vector2.RIGHT)
	assert_bool(farm.use_item()).is_false()
	assert_str(farm.hud.message_text()).is_equal(ToolUse.CAN_DONE)
	assert_int(GameState.item_count(&"water")).is_equal(8)


func test_a_better_pickaxe_breaks_a_rock_in_fewer_blows() -> void:
	GameState.add_item(&"wooden_sword")
	GameState.add_item(&"copper_pickaxe")
	GameState.add_item(&"iron_pickaxe")
	GameState.equip(&"copper_pickaxe")
	var floor: AreaController = _floor(4)
	# Copper: stone in one, iron in two.
	var stone: Rock = _rock_of(floor, MineRules.STONE)
	_face(floor, stone)
	assert_bool(floor.use_item()).is_true()
	assert_bool(stone.broken).override_failure_message("stone in one blow").is_true()
	_finish(floor)
	var iron: Rock = _rock_of(floor, &"iron_ore")
	_face(floor, iron)
	assert_bool(floor.use_item()).is_true()
	assert_bool(iron.broken).is_false()
	_finish(floor)
	assert_bool(floor.use_item()).is_true()
	assert_bool(iron.broken).override_failure_message("iron in two").is_true()
	_finish(floor)
	assert_float(GameState.energy).override_failure_message("three blows, each the same price").is_equal(94.0)
	# Iron: every rock in one. It is the pickaxe that strikes that counts, not the one he came in with.
	GameState.equip(&"iron_pickaxe")
	var more: Rock = _rock_of(floor, &"iron_ore")
	_face(floor, more)
	assert_bool(floor.use_item()).is_true()
	assert_bool(more.broken).override_failure_message("iron in one").is_true()
	_finish(floor)
	# A rock begun with the plain pickaxe is finished sooner by a better one.
	GameState.add_item(&"pickaxe")
	GameState.equip(&"pickaxe")
	var begun: Rock = _rock_of(floor, &"iron_ore")
	_face(floor, begun)
	assert_bool(floor.use_item()).is_true()
	assert_bool(begun.broken).is_false()
	_finish(floor)
	GameState.equip(&"copper_pickaxe")
	assert_bool(floor.use_item()).is_true()
	assert_bool(begun.broken).override_failure_message("one plain blow and one copper: two of copper's two").is_true()


func test_a_sprinkler_is_set_on_the_plot_waters_each_morning_and_is_taken_up_again() -> void:
	GameState.add_item(&"wooden_sword")
	GameState.add_item(&"sprinkler", 2)
	GameState.equip(&"sprinkler")
	for cell: Vector2i in [Vector2i(1, 1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(2, 1), Vector2i(1, 2), Vector2i(3, 1)]:
		GameState.till_soil(cell)
	GameState.plant_crop(Vector2i(2, 1), &"turnip")
	var farm: AreaController = _load(FARM)
	# Not on bare soil, and not where something grows.
	_stand(farm, PLOT + Vector2i(4, 2), Vector2.RIGHT)
	assert_bool(farm.use_item()).is_false()
	assert_str(farm.hud.message_text()).is_equal(ToolUse.SPRINKLER_BARE)
	_stand(farm, PLOT + Vector2i(2, 2), Vector2.UP)
	assert_bool(farm.use_item()).is_false()
	assert_str(farm.hud.message_text()).is_equal(ToolUse.SPRINKLER_GROWING)
	assert_int(GameState.item_count(&"sprinkler")).is_equal(2)
	# On tilled, empty soil it is set down, and one is gone from his pack.
	_stand(farm, PLOT + Vector2i(1, 2), Vector2.UP)
	assert_bool(farm.use_hand()).override_failure_message("a left click sets it down too").is_true()
	assert_bool(GameState.farm().has_sprinkler(Vector2i(1, 1))).is_true()
	assert_int(GameState.item_count(&"sprinkler")).is_equal(1)
	assert_array(_heard).contains([&"plant"])
	_finish(farm)
	assert_bool(farm.use_item()).override_failure_message("not a second in the same cell").is_false()
	assert_str(farm.hud.message_text()).is_equal(ToolUse.SPRINKLER_TAKEN)
	assert_bool(farm.terrain.is_occupied(PLOT + Vector2i(1, 1))).override_failure_message("it lies flat: he walks over it").is_false()
	# The next morning the four cells beside it are wet, and the turnip has begun to grow the day after.
	GameState.start_next_day()
	for cell: Vector2i in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(2, 1), Vector2i(1, 2)]:
		assert_bool(GameState.farm().is_watered(cell)).override_failure_message("%s is watered" % cell).is_true()
	assert_bool(GameState.farm().is_watered(Vector2i(3, 1))).is_false()
	GameState.start_next_day()
	assert_int(GameState.farm().stage_of(Vector2i(2, 1))).is_equal(1)
	# A seed isn't planted where it stands.
	GameState.add_item(&"turnip_seeds", 2)
	GameState.equip(&"turnip_seeds")
	assert_bool(farm.use_item()).is_false()
	assert_str(farm.hud.message_text()).is_equal(ToolUse.SEED_SPRINKLER)
	# Facing it, a right click takes it up again.
	farm._process(FRAME)
	assert_str(farm.hud.prompt_text()).contains(AreaController.SPRINKLER_PROMPT)
	assert_that(farm.sprinkler_in_front()).is_equal(Vector2i(1, 1))
	assert_bool(farm.interact()).is_true()
	assert_bool(GameState.farm().has_sprinkler(Vector2i(1, 1))).is_false()
	assert_int(GameState.item_count(&"sprinkler")).is_equal(2)
	assert_array(_heard).contains([&"item_get"])
	assert_that(farm.sprinkler_in_front()).is_equal(Vector2i(-1, -1))
	# With ten already, it stays where it is and he is told.
	GameState.place_sprinkler(Vector2i(1, 1))
	GameState.add_item(&"sprinkler", 8)
	assert_bool(farm.interact()).is_true()
	assert_bool(GameState.farm().has_sprinkler(Vector2i(1, 1))).is_true()
	assert_int(GameState.item_count(&"sprinkler")).is_equal(10)
	assert_str(farm.hud.message_text()).is_equal(AreaController.NO_ROOM_WORDS % "sprinklers")


func test_the_plot_is_told_when_a_sprinkler_is_set_or_taken_up() -> void:
	var told: Array[int] = [0]
	var count: Callable = func() -> void: told[0] += 1
	GameState.till_soil(Vector2i(1, 1))
	EventBus.farm_changed.connect(count)
	assert_bool(GameState.place_sprinkler(Vector2i(1, 1))).is_true()
	assert_int(told[0]).override_failure_message("whoever draws the plot is told").is_equal(1)
	assert_bool(GameState.place_sprinkler(Vector2i(1, 1))).is_false()
	assert_int(told[0]).override_failure_message("nothing changed: nothing is told").is_equal(1)
	assert_bool(GameState.take_sprinkler(Vector2i(1, 1))).is_true()
	assert_int(told[0]).is_equal(2)
	assert_bool(GameState.take_sprinkler(Vector2i(1, 1))).is_false()
	assert_int(told[0]).is_equal(2)
	EventBus.farm_changed.disconnect(count)


func test_the_miners_lantern_lights_further_than_the_lantern() -> void:
	var lantern: Dictionary = DataRegistry.get_item(&"lantern")
	var miners: Dictionary = DataRegistry.get_item(&"miners_lantern")
	assert_str(str(miners["type"])).is_equal("lantern")
	assert_float(float(lantern["stats"]["radius"])).is_equal(56.0)
	assert_float(float(miners["stats"]["radius"])).is_equal(80.0)
	GameState.add_item(&"wooden_sword")
	GameState.add_item(&"lantern")
	var floor: AreaController = _floor(7)
	assert_float(floor.hero_light_radius()).is_equal(56.0)
	var far: Vector2 = floor.player.position + Vector2(70, -8)
	assert_bool(floor.holds_at(far)).override_failure_message("70 pixels off is beyond the Lantern").is_false()
	# Made from the Lantern, a gold bar and a crystal: the Lantern goes, and the light widens.
	GameState.add_item(&"gold_bar")
	GameState.add_item(&"crystal")
	assert_str(GameState.craft(&"miners_lantern")).is_equal("")
	assert_int(GameState.item_count(&"lantern")).is_equal(0)
	assert_int(GameState.item_count(&"miners_lantern")).is_equal(1)
	assert_float(floor.hero_light_radius()).is_equal(80.0)
	assert_bool(floor.holds_at(far)).override_failure_message("and inside the Miner's Lantern").is_true()
	assert_bool(Torch.has_lantern()).override_failure_message("it lights the crypt's torches as the Lantern did").is_true()
	assert_str(GameState.craft(&"miners_lantern")).override_failure_message("no Lantern left to make another from").is_equal(Crafting.LACKING_WORDS)


# --- Helpers -------------------------------------------------------------------------------

func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area


func _floor(number: int) -> AreaController:
	var area_id: StringName = GameState.mine_rules().area_of(number)
	GameState.go_to(area_id, MineRules.ARRIVAL)
	return _load(WorldPaths.scene_for(area_id))


func _stand(area: AreaController, cell: Vector2i, way: Vector2) -> void:
	area.player.motor.place(cell)
	area.player.face(way)


func _finish(area: AreaController) -> void:
	for i: int in 40:
		area.player.motor.step(Vector2.ZERO, FRAME)


func _open_beside(area: AreaController, cell: Vector2i) -> Array:
	for side: Vector2i in SIDES:
		var at: Vector2i = cell + side
		if area.grid.in_bounds(at) and not area.grid.is_solid(at) and not area.terrain.is_occupied(at) \
				and area.grid.height_at(at) == area.grid.height_at(cell):
			return [at, Vector2(-side)]
	return []


func _face(area: AreaController, rock: Rock) -> void:
	var where: Array = _open_beside(area, rock.cell())
	area.player.motor.place(where[0])
	area.player.face(where[1])


func _rock_of(area: AreaController, kind: StringName) -> Rock:
	for rock: Rock in area.rocks():
		if rock.kind == kind and not rock.broken and rock.blows_left == GameState.mine_rules().blows(kind) \
				and rock.cell() != area.ladder_cell() and not _open_beside(area, rock.cell()).is_empty():
			return rock
	fail("no %s rock to get at" % kind)
	return null


func _on_sound(id: StringName) -> void:
	_heard.append(id)
