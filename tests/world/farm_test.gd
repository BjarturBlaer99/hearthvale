extends GdUnitTestSuite
## The farm in the world (P3a): the plot between the shop and the well; the hoe and the
## watering can found at home and used from the item button; the can filled at the well and
## the pond; the morning that dries the soil. Farm work costs energy and never a heart.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")
const DataRegistryScript: GDScript = preload("res://autoload/data_registry.gd")

const VILLAGE: String = "res://world/areas/village/village.tscn"
const HOME: String = "res://world/areas/home/home.tscn"
const FIELD: String = "res://world/areas/south_field/south_field.tscn"
const FRAME: float = 1.0 / 60.0
## The plot's north-west corner in Hearthvale, and the well beside it.
const PLOT: Vector2i = Vector2i(12, 18)
const WELL: Array[Vector2i] = [Vector2i(18, 19), Vector2i(19, 19), Vector2i(18, 20), Vector2i(19, 20)]
const POND: Rect2i = Rect2i(28, 26, 6, 4)

var _area: Node
var _heard: Array[StringName] = []


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	# The main quest begins with the game, with a chime: before these tests listen.
	Quests.refresh()
	_heard.clear()
	EventBus.sound.connect(_on_sound)


func after_test() -> void:
	EventBus.sound.disconnect(_on_sound)
	if is_instance_valid(_area):
		_area.free()
	_area = null
	GameState.clear()


func test_the_plot_lies_between_the_shop_and_the_well() -> void:
	var village: AreaController = _load(VILLAGE)
	var plot: FarmPlot = village.plot
	assert_object(plot).is_not_null()
	assert_that(plot.origin()).is_equal(PLOT)
	assert_that(plot.plot_size()).is_equal(Vector2i(6, 3))
	assert_int(plot.cells().size()).is_equal(18)
	assert_that(plot.cells()[0]).is_equal(PLOT)
	assert_that(plot.cells()[17]).is_equal(PLOT + Vector2i(5, 2))
	assert_that(plot.plot_cell(PLOT + Vector2i(4, 1))).is_equal(Vector2i(4, 1))
	assert_that(plot.map_cell(Vector2i(4, 1))).is_equal(PLOT + Vector2i(4, 1))
	for outside: Vector2i in [PLOT + Vector2i(-1, 0), PLOT + Vector2i(6, 0), PLOT + Vector2i(0, -1), PLOT + Vector2i(0, 3)]:
		assert_bool(plot.covers(outside)).override_failure_message("%s is not soil" % outside).is_false()
		assert_that(plot.soil_at(outside)).is_equal(&"")
	# It is ground like the grass it lies on: open, level, nothing growing on it.
	var decor: TileMapLayer = village.get_node(^"Decor")
	for cell: Vector2i in plot.cells():
		assert_bool(plot.covers(cell)).is_true()
		assert_that(plot.soil_at(cell)).is_equal(Farm.BARE)
		assert_bool(village.grid.is_solid(cell) or village.terrain.is_occupied(cell)).override_failure_message("%s is open" % cell).is_false()
		assert_int(village.terrain.standing_level(cell)).is_equal(0)
		assert_int(decor.get_cell_source_id(cell)).override_failure_message("nothing grows at %s" % cell).is_equal(-1)
		assert_object(village.exit_at(cell)).is_null()
	# Drawn over the map and under whatever stands on it.
	for under: Node in [village.height_layer, decor]:
		assert_int(plot.get_index()).override_failure_message("over %s" % under.name).is_greater(under.get_index())
	for over: Node in [village.get_node(^"HeightShading"), village.interactables, village.player, village.scenery]:
		assert_int(plot.get_index()).override_failure_message("under %s" % over.name).is_less(over.get_index())
	# The well is at its east edge.
	assert_that(WELL[0]).is_equal(PLOT + Vector2i(6, 1))
	# Nowhere else is there a plot.
	assert_object(_load(HOME).plot).is_null()
	assert_object(_load(FIELD).plot).is_null()


func test_he_walks_over_the_plot_as_over_grass() -> void:
	var village: AreaController = _load(VILLAGE)
	GameState.till_soil(Vector2i(2, 1))
	GameState.water_soil(Vector2i(2, 1))
	village.player.motor.place(PLOT + Vector2i(-1, 1))
	village.player.face(Vector2.RIGHT)
	for i: int in 200:
		village.player.motor.step(Vector2.RIGHT, FRAME)
	assert_that(village.player.motor.cell).override_failure_message("across all six cells, to the well").is_equal(PLOT + Vector2i(5, 1))
	village.player.motor.place(PLOT + Vector2i(3, -2))
	for i: int in 200:
		village.player.motor.step(Vector2.DOWN, FRAME)
	assert_int(village.player.motor.cell.y).override_failure_message("and down through all three rows").is_greater(PLOT.y + 2)
	assert_float(village.player.motor.speed_scale).is_equal(1.0)


func test_the_hoe_and_the_can_lie_at_home() -> void:
	var home: AreaController = _load(HOME)
	var hoe: ItemPickup = home.interactables.get_node(^"Hoe")
	var can: ItemPickup = home.interactables.get_node(^"WateringCan")
	assert_that(hoe.item_id).is_equal(&"hoe")
	assert_that(can.item_id).is_equal(&"watering_can")
	for pickup: ItemPickup in [hoe, can]:
		assert_bool(home.grid.is_solid(pickup.cell()) or home.terrain.is_occupied(pickup.cell())).override_failure_message("%s lies on open floor" % pickup.name).is_false()
		home.player.motor.place(pickup.cell())
		assert_bool(home.interact()).is_true()
		assert_int(GameState.item_count(pickup.item_id)).is_equal(1)
		assert_bool(pickup.taken()).is_true()
	assert_that(GameState.equipped).override_failure_message("the first of them goes on the item button").is_equal(&"hoe")
	assert_int(GameState.item_count(&"water")).override_failure_message("the can is empty").is_equal(0)
	assert_str(AreaController.equipped_text()).is_equal("Item: Hoe")
	# They are gone the next time he comes home.
	home = _load(HOME)
	home.player.motor.place((home.interactables.get_node(^"Hoe") as ItemPickup).cell())
	assert_object(home.pickup_under_player()).is_null()


func test_the_hoe_tills_the_cell_he_faces_for_two_energy() -> void:
	GameState.add_item(&"hoe")
	GameState.damage(1)
	var hearts: int = GameState.health
	var village: AreaController = _load(VILLAGE)
	_stand(village, PLOT + Vector2i(1, 1), Vector2.RIGHT)
	assert_bool(village.use_item()).is_true()
	assert_that(GameState.farm().state_of(Vector2i(2, 1))).is_equal(Farm.TILLED)
	assert_that(village.plot.soil_at(PLOT + Vector2i(2, 1))).is_equal(Farm.TILLED)
	assert_int(GameState.farm().count_of(Farm.TILLED)).override_failure_message("that cell and no other").is_equal(1)
	assert_float(GameState.energy).is_equal(98.0)
	assert_int(GameState.health).override_failure_message("farm work never costs a heart").is_equal(hearts)
	assert_array(_heard).contains([&"hoe"])
	assert_bool(village.player.motor.is_attacking()).override_failure_message("he stands still for the stroke").is_true()
	assert_int(_flashes(village).size()).override_failure_message("the hoe shows on the cell").is_equal(1)
	assert_that(_flashes(village)[0].icon).is_equal(&"hoe")
	assert_that(GridBody.cell_of(_flashes(village)[0].position + Vector2(8, 8))).is_equal(PLOT + Vector2i(2, 1))
	# Mid-stroke he can't start another.
	village.player.face(Vector2.UP)
	assert_bool(village.use_item()).override_failure_message("not again until the stroke is done").is_false()
	assert_that(GameState.farm().state_of(Vector2i(1, 0))).is_equal(Farm.BARE)
	assert_float(GameState.energy).is_equal(98.0)
	village.player.face(Vector2.RIGHT)
	# The same cell again: it is tilled already, and that costs nothing.
	_rest(village)
	_heard.clear()
	assert_bool(village.use_item()).is_false()
	assert_str(village.hud.message_text()).is_equal(ToolUse.HOE_DONE)
	assert_array(_heard).contains_exactly([&"nope"])
	assert_float(GameState.energy).is_equal(98.0)
	assert_bool(village.player.motor.is_attacking()).is_false()
	# Off the plot the hoe has nothing to do.
	_stand(village, PLOT + Vector2i(1, 0), Vector2.UP)
	assert_bool(village.use_item()).is_false()
	assert_str(village.hud.message_text()).is_equal(ToolUse.HOE_NOT_HERE)
	assert_float(GameState.energy).is_equal(98.0)
	assert_int(GameState.farm().count_of(Farm.BARE)).is_equal(17)
	# From the grass beside the plot he can reach its edge.
	_stand(village, PLOT + Vector2i(-1, 2), Vector2.RIGHT)
	assert_bool(village.use_item()).is_true()
	assert_bool(GameState.farm().is_tilled(Vector2i(0, 2))).is_true()
	assert_float(GameState.energy).is_equal(96.0)


func test_the_can_waters_a_tilled_cell_for_one_energy_and_a_pour() -> void:
	GameState.add_item(&"hoe")
	GameState.add_item(&"watering_can")
	GameState.equip(&"watering_can")
	GameState.till_soil(Vector2i(2, 1))
	var hearts: int = GameState.health
	var village: AreaController = _load(VILLAGE)
	_stand(village, PLOT + Vector2i(1, 1), Vector2.RIGHT)
	# Empty, it says where to fill it.
	assert_bool(village.use_item()).is_false()
	assert_str(village.hud.message_text()).is_equal(ToolUse.CAN_EMPTY)
	assert_array(_heard).contains_exactly([&"nope"])
	GameState.add_item(&"water", 3)
	_heard.clear()
	assert_bool(village.use_item()).is_true()
	assert_that(GameState.farm().state_of(Vector2i(2, 1))).is_equal(Farm.WATERED)
	assert_int(GameState.item_count(&"water")).override_failure_message("one pour").is_equal(2)
	assert_float(GameState.energy).is_equal(99.0)
	assert_int(GameState.health).is_equal(hearts)
	assert_array(_heard).contains([&"pour"])
	assert_that(_flashes(village)[0].icon).is_equal(&"watering_can")
	# Wet soil needs no more, and bare soil must be tilled first: neither costs a pour.
	_rest(village)
	assert_bool(village.use_item()).is_false()
	assert_str(village.hud.message_text()).is_equal(ToolUse.CAN_DONE)
	_stand(village, PLOT + Vector2i(1, 1), Vector2.DOWN)
	assert_bool(village.use_item()).is_false()
	assert_str(village.hud.message_text()).is_equal(ToolUse.CAN_BARE)
	_stand(village, PLOT + Vector2i(1, 0), Vector2.UP)
	assert_bool(village.use_item()).is_false()
	assert_str(village.hud.message_text()).is_equal(ToolUse.CAN_NOT_HERE)
	assert_int(GameState.item_count(&"water")).is_equal(2)
	assert_float(GameState.energy).is_equal(99.0)
	# The can says what it holds wherever it is named; the pack doesn't list the water.
	assert_str(AreaController.equipped_text()).is_equal("Item: Watering Can (Water x2)")
	assert_str(AreaController.carrying_text()).is_equal("Carrying: Hoe, Watering Can")
	village._update_hud()
	assert_array(village.hud.item_bar.shown_ids()).is_equal([&"hoe", &"watering_can"])
	assert_array(Array(village.hud.item_bar.shown_counts())).override_failure_message("the can's slot says its pours").is_equal(["", "2"])
	assert_int(village.hud.item_bar.lit_slot()).is_equal(1)


func test_the_can_fills_at_the_well_and_at_the_pond() -> void:
	GameState.add_item(&"watering_can")
	GameState.add_item(&"water", 4)
	var village: AreaController = _load(VILLAGE)
	for cell: Vector2i in WELL:
		assert_bool(village.is_water_source(cell)).override_failure_message("the well at %s" % cell).is_true()
	for x: int in POND.size.x:
		for y: int in POND.size.y:
			assert_bool(village.is_water_source(POND.position + Vector2i(x, y))).override_failure_message("the pond").is_true()
	for dry: Vector2i in [PLOT, PLOT + Vector2i(5, 1), Vector2i(23, 20), Vector2i(8, 14), Vector2i(21, 21), Vector2i(-3, 5), Vector2i(13, 21)]:
		assert_bool(village.is_water_source(dry)).override_failure_message("no water at %s" % dry).is_false()
	# From the plot's last cell he faces the well.
	_stand(village, PLOT + Vector2i(5, 1), Vector2.RIGHT)
	var energy: float = GameState.energy
	assert_bool(village.use_item()).is_true()
	assert_int(GameState.item_count(&"water")).override_failure_message("ten pours").is_equal(10)
	assert_float(GameState.energy).override_failure_message("filling is free").is_equal(energy)
	assert_array(_heard).contains([&"fill"])
	assert_str(village.hud.message_text()).is_equal(AreaController.CAN_FILLED_WORDS)
	_rest(village)
	_heard.clear()
	assert_bool(village.use_item()).override_failure_message("full already").is_false()
	assert_str(village.hud.message_text()).is_equal(ToolUse.CAN_FULL)
	assert_array(_heard).contains_exactly([&"nope"])
	# And at the pond.
	GameState.add_item(&"water", -7)
	_stand(village, POND.position + Vector2i(-1, 1), Vector2.RIGHT)
	assert_bool(village.use_item()).is_true()
	assert_int(GameState.item_count(&"water")).is_equal(10)
	# A hoe at the well does nothing.
	GameState.add_item(&"hoe")
	GameState.equip(&"hoe")
	_rest(village)
	assert_bool(village.use_item()).is_false()
	assert_str(village.hud.message_text()).is_equal(ToolUse.HOE_NOT_HERE)


func test_ten_pours_water_ten_cells_and_the_morning_dries_them() -> void:
	GameState.add_item(&"watering_can")
	GameState.add_item(&"water", 10)
	for x: int in 6:
		for y: int in 2:
			GameState.till_soil(Vector2i(x, y))
	var village: AreaController = _load(VILLAGE)
	var watered: int = 0
	for y: int in 2:
		for x: int in 6:
			_stand(village, PLOT + Vector2i(x, y + 1), Vector2.UP)
			if village.use_item():
				watered += 1
			_rest(village)
	assert_int(watered).override_failure_message("a can waters ten cells").is_equal(10)
	assert_int(GameState.farm().count_of(Farm.WATERED)).is_equal(10)
	assert_int(GameState.item_count(&"water")).is_equal(0)
	assert_str(village.hud.message_text()).is_equal(ToolUse.CAN_EMPTY)
	# Twelve cells tilled made him level 2 at farming (P4b): a pour costs nine tenths of one energy.
	assert_float(GameState.energy).override_failure_message("nine energy for ten cells, at level 2").is_equal_approx(91.0, 0.001)
	assert_str(AreaController.equipped_text()).is_equal("Item: Watering Can (Water x0)")
	GameState.start_next_day()
	assert_int(GameState.farm().count_of(Farm.WATERED)).override_failure_message("dry by morning").is_equal(0)
	assert_int(GameState.farm().count_of(Farm.TILLED)).override_failure_message("and still tilled").is_equal(12)
	assert_that(village.plot.soil_at(PLOT)).is_equal(Farm.TILLED)
	assert_int(GameState.item_count(&"water")).override_failure_message("the can doesn't fill itself").is_equal(0)


func test_tilling_the_whole_plot_costs_less_as_his_farming_rises_and_a_tool_that_does_nothing_costs_nothing() -> void:
	var rules: EnergyRules = GameState.energy_rules()
	assert_float(rules.cost(EnergyRules.HOE)).is_equal(2.0)
	assert_float(rules.cost(EnergyRules.WATER)).is_equal(1.0)
	GameState.add_item(&"hoe")
	var hearts: int = GameState.health
	var village: AreaController = _load(VILLAGE)
	village.travel = func(_path: String) -> void: pass
	for cell: Vector2i in village.plot.cells():
		_stand(village, cell + Vector2i.DOWN, Vector2.UP)
		assert_bool(village.use_item()).override_failure_message("tilling %s" % cell).is_true()
		_rest(village)
	assert_int(GameState.farm().count_of(Farm.TILLED)).is_equal(18)
	# Ten cells at two energy each; the tenth raises his farming (P4b), and the last eight cost 1.8.
	assert_float(GameState.energy).is_equal_approx(100.0 - 20.0 - 8.0 * 1.8, 0.001)
	assert_int(GameState.skill_level(Skills.FARMING)).is_equal(2)
	assert_int(GameState.health).is_equal(hearts)
	# A tool that does nothing costs nothing, however tired he is.
	GameState.set_energy(1.5)
	_stand(village, PLOT + Vector2i(0, 1), Vector2.UP)
	assert_bool(village.use_item()).is_false()
	assert_float(GameState.energy).is_equal(1.5)
	assert_int(GameState.health).is_equal(hearts)


func test_the_soil_has_its_pictures() -> void:
	var tool: Dictionary = (load("res://tools/art/make_sprites.gd") as GDScript).get_script_constant_map()
	var painted: Array = (tool["SPRITES"]["soil"]["frames"] as Dictionary).keys()
	assert_int(painted.size()).is_equal(FarmPlot.FRAMES.size())
	for i: int in painted.size():
		assert_int(int(FarmPlot.FRAMES[StringName(str(painted[i]))])).override_failure_message("%s is frame %d" % [painted[i], i]).is_equal(i)
	assert_that(Vector2i(FarmPlot.SHEET.get_size())).is_equal(Vector2i(FarmPlot.CELL.x * FarmPlot.FRAMES.size(), FarmPlot.CELL.y * 2))
	# Whole tiles: no grass shows through the soil.
	var image: Image = FarmPlot.SHEET.get_image()
	for frame: StringName in FarmPlot.FRAMES:
		for y: int in FarmPlot.CELL.y:
			for x: int in FarmPlot.CELL.x:
				assert_float(image.get_pixel(int(FarmPlot.FRAMES[frame]) * FarmPlot.CELL.x + x, y).a).override_failure_message("%s at %d,%d" % [frame, x, y]).is_equal(1.0)
	# Wet soil is darker than dry, and tilled soil isn't flat.
	assert_float(_brightness(image, &"watered")).is_less(_brightness(image, &"tilled") - 0.05)
	assert_that(FarmPlot.frame_for(Farm.TILLED, Vector2i(1, 1))).is_equal(&"tilled")
	assert_that(FarmPlot.frame_for(Farm.WATERED, Vector2i(0, 0))).is_equal(&"watered")
	var bare: Dictionary = {}
	for x: int in 6:
		for y: int in 3:
			bare[FarmPlot.frame_for(Farm.BARE, Vector2i(x, y))] = true
	assert_array(bare.keys()).override_failure_message("bare soil comes in two kinds").contains_exactly_in_any_order([&"bare", &"bare_b"])
	for id: StringName in [&"hoe", &"pour", &"fill"]:
		assert_bool(Audio.SFX.has(id)).override_failure_message("%s is a sound the game has" % id).is_true()


func test_a_tool_at_work_dips_and_is_gone() -> void:
	var flash: ToolFlash = ToolFlash.spawn(self, Vector2(32, 48), &"hoe", 0.4)
	assert_that(flash.position).is_equal(Vector2(32, 48))
	assert_float(flash.height()).override_failure_message("it starts lifted").is_equal(ToolFlash.LIFT)
	flash._process(0.2)
	assert_float(flash.height()).override_failure_message("down on the soil by the middle").is_equal_approx(0.0, 0.01)
	flash._process(0.19)
	assert_float(flash.height()).is_greater(ToolFlash.LIFT * 0.8)
	assert_bool(flash.is_queued_for_deletion()).is_false()
	flash._process(0.02)
	assert_bool(flash.is_queued_for_deletion()).override_failure_message("gone when the stroke is done").is_true()


func test_bad_tools_and_bad_farm_rules_are_reported() -> void:
	assert_bool(DataRegistry.has_entry(&"rules", DataRegistry.RULES_FARM)).override_failure_message("data/rules/farm.json is loaded").is_true()
	assert_array(Array(Farm.problems(DataRegistry.get_rules(DataRegistry.RULES_FARM)))).is_empty()
	var registry: Node = auto_free(DataRegistryScript.new())
	var errors: String = "\n".join(registry.load_all("res://tests/fixtures/bad_rules"))
	assert_str(errors).contains("rules 'farm': 'plot' needs 'columns' and 'rows', each a whole number of 1 or more.")
	assert_str(errors).contains("rules 'farm': 'wither_after' must be a whole number of 1 or more")
	assert_str(errors).contains("rules 'energy': 'costs' needs 'hoe', a number of 0 or more.")
	assert_str(errors).contains("rules 'energy': 'costs' needs 'water', a number of 0 or more.")
	var other: Node = auto_free(DataRegistryScript.new())
	errors = "\n".join(other.load_all("res://tests/fixtures/bad_tools"))
	assert_str(errors).contains("item 'spade': a tool's stats must name its 'tool': hoe or water.")
	assert_str(errors).contains("item 'jug': the watering can's stats must name what it holds ('ammo').")
	assert_str(errors).contains("item 'bucket' ammo")


## Puts the hero in `cell`, facing `way`.
func _stand(area: AreaController, cell: Vector2i, way: Vector2) -> void:
	area.player.motor.place(cell)
	area.player.face(way)


## Lets a tool's stroke finish.
func _rest(area: AreaController) -> void:
	for i: int in 40:
		area.player.motor.step(Vector2.ZERO, FRAME)


func _flashes(area: AreaController) -> Array[ToolFlash]:
	var out: Array[ToolFlash] = []
	for child: Node in area.interactables.get_children():
		if child is ToolFlash and not child.is_queued_for_deletion():
			out.append(child as ToolFlash)
	return out


## How bright a soil frame is on the whole.
func _brightness(image: Image, frame: StringName) -> float:
	var total: float = 0.0
	for y: int in FarmPlot.CELL.y:
		for x: int in FarmPlot.CELL.x:
			total += image.get_pixel(int(FarmPlot.FRAMES[frame]) * FarmPlot.CELL.x + x, y).get_luminance()
	return total / float(FarmPlot.CELL.x * FarmPlot.CELL.y)


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area


func _on_sound(id: StringName) -> void:
	_heard.append(id)
