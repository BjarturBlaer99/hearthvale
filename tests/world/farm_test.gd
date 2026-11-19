extends GdUnitTestSuite
## The farm in the world (P3a; moved by the Homestead, 2026-11-17): the field below the
## farmhouse, across the road, whose north-west corner is the old plot; the hoe and the
## watering can found at home and used from the item button; the can filled at the farm's
## pond (and still at the village's well and pond); the morning that dries the soil. Farm
## work costs energy and never a heart. The soil worked here is the field's clear corner:
## the rest of it starts overgrown (tests/world/debris_test.gd).

const Steps: GDScript = preload("res://tests/support/area_steps.gd")
const DataRegistryScript: GDScript = preload("res://autoload/data_registry.gd")

const FARM: String = "res://world/areas/homestead/homestead.tscn"
const VILLAGE: String = "res://world/areas/village/village.tscn"
const HOME: String = "res://world/areas/home/home.tscn"
const FIELD: String = "res://world/areas/south_field/south_field.tscn"
const FRAME: float = 1.0 / 60.0
## The field's north-west corner on the homestead, its clear corner (the old plot's cells, in
## the plot's own cells), and the pond in the corner of the land.
const PLOT: Vector2i = Vector2i(22, 17)
const CLEAR: Rect2i = Rect2i(0, 0, 6, 3)
const POND: Rect2i = Rect2i(4, 21, 6, 4)
## Where the plot lay in Hearthvale until the Homestead, and the village's well and pond.
const OLD_PLOT: Rect2i = Rect2i(12, 18, 6, 3)
const WELL: Array[Vector2i] = [Vector2i(18, 19), Vector2i(19, 19), Vector2i(18, 20), Vector2i(19, 20)]
const VILLAGE_POND: Rect2i = Rect2i(28, 26, 6, 4)

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


func test_the_field_lies_below_the_farmhouse_across_the_road() -> void:
	var farm: AreaController = _load(FARM)
	var plot: FarmPlot = farm.plot
	assert_object(plot).is_not_null()
	assert_that(plot.origin()).is_equal(PLOT)
	assert_that(plot.plot_size()).override_failure_message("four times the old plot (6 by 3)").is_equal(Vector2i(12, 6))
	assert_int(plot.cells().size()).is_equal(72)
	assert_that(plot.cells()[0]).is_equal(PLOT)
	assert_that(plot.cells()[71]).is_equal(PLOT + Vector2i(11, 5))
	assert_that(plot.plot_cell(PLOT + Vector2i(4, 1))).is_equal(Vector2i(4, 1))
	assert_that(plot.map_cell(Vector2i(4, 1))).is_equal(PLOT + Vector2i(4, 1))
	for outside: Vector2i in [PLOT + Vector2i(-1, 0), PLOT + Vector2i(12, 0), PLOT + Vector2i(0, -1), PLOT + Vector2i(0, 6)]:
		assert_bool(plot.covers(outside)).override_failure_message("%s is not soil" % outside).is_false()
		assert_that(plot.soil_at(outside)).is_equal(&"")
	# It is ground like the grass it lies on: open, level, nothing growing on it.
	var decor: TileMapLayer = farm.get_node(^"Decor")
	for cell: Vector2i in plot.cells():
		assert_bool(plot.covers(cell)).is_true()
		assert_that(plot.soil_at(cell)).is_equal(Farm.BARE)
		assert_bool(farm.grid.is_solid(cell)).override_failure_message("%s is open ground" % cell).is_false()
		assert_int(farm.terrain.standing_level(cell)).is_equal(0)
		assert_int(decor.get_cell_source_id(cell)).override_failure_message("nothing grows at %s" % cell).is_equal(-1)
		assert_object(farm.exit_at(cell)).is_null()
	# Its corner by the house, the old plot's eighteen cells, is clear in every game: nothing
	# stands on it.
	var clear: int = 0
	for cell: Vector2i in plot.cells():
		if CLEAR.has_point(plot.plot_cell(cell)):
			clear += 1
			assert_bool(farm.terrain.is_occupied(cell)).override_failure_message("%s is clear" % cell).is_false()
	assert_int(clear).is_equal(18)
	# Drawn over the map and under whatever stands on it.
	for under: Node in [farm.height_layer, decor]:
		assert_int(plot.get_index()).override_failure_message("over %s" % under.name).is_greater(under.get_index())
	for over: Node in [farm.get_node(^"HeightShading"), farm.interactables, farm.player, farm.scenery]:
		assert_int(plot.get_index()).override_failure_message("under %s" % over.name).is_less(over.get_index())
	# The road runs above it, a row of grass between, and the farmhouse's door is beyond the road.
	var layer: TileMapLayer = farm.get_node(^"Height")
	for x: int in plot.plot_size().x:
		assert_that(layer.get_cell_atlas_coords(PLOT + Vector2i(x, -1))).override_failure_message("grass above the field").is_equal(GreyboxTiles.coords("ground"))
		assert_that(layer.get_cell_atlas_coords(PLOT + Vector2i(x, -2))).override_failure_message("and the road above that").is_equal(GreyboxTiles.coords("path"))
	var door: AreaExit = farm.interactables.get_node(^"FarmhouseDoor")
	assert_int(door.cell().x).override_failure_message("the path from the door meets the road at the clear corner's east end").is_equal(PLOT.x + CLEAR.size.x)
	assert_int(door.cell().y).is_less(PLOT.y - 2)
	# Nowhere else is there a plot: not in Hearthvale, where it lay until the Homestead.
	assert_object(_load(HOME).plot).is_null()
	assert_object(_load(FIELD).plot).is_null()
	var village: AreaController = _load(VILLAGE)
	assert_object(village.plot).override_failure_message("Hearthvale has no plot").is_null()
	for x: int in OLD_PLOT.size.x:
		for y: int in OLD_PLOT.size.y:
			var cell: Vector2i = OLD_PLOT.position + Vector2i(x, y)
			assert_that((village.get_node(^"Height") as TileMapLayer).get_cell_atlas_coords(cell)).override_failure_message("where it lay is grass again: %s" % cell).is_equal(GreyboxTiles.coords("ground"))
			assert_bool(village.grid.is_solid(cell) or village.terrain.is_occupied(cell)).is_false()


func test_he_walks_over_the_plot_as_over_grass() -> void:
	var farm: AreaController = _load(FARM)
	GameState.till_soil(Vector2i(2, 1))
	GameState.water_soil(Vector2i(2, 1))
	farm.player.motor.place(PLOT + Vector2i(-1, 1))
	farm.player.face(Vector2.RIGHT)
	for i: int in 200:
		farm.player.motor.step(Vector2.RIGHT, FRAME)
	assert_that(farm.player.motor.cell).override_failure_message("across all six cells of the clear corner, to the weeds beyond it").is_equal(PLOT + Vector2i(5, 1))
	farm.player.motor.place(PLOT + Vector2i(3, -2))
	for i: int in 200:
		farm.player.motor.step(Vector2.DOWN, FRAME)
	assert_int(farm.player.motor.cell.y).override_failure_message("and down through all three of its rows, to the weeds below them").is_equal(PLOT.y + 2)
	assert_float(farm.player.motor.speed_scale).is_equal(1.0)


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
	var farm: AreaController = _load(FARM)
	_stand(farm, PLOT + Vector2i(1, 1), Vector2.RIGHT)
	assert_bool(farm.use_item()).is_true()
	assert_that(GameState.farm().state_of(Vector2i(2, 1))).is_equal(Farm.TILLED)
	assert_that(farm.plot.soil_at(PLOT + Vector2i(2, 1))).is_equal(Farm.TILLED)
	assert_int(GameState.farm().count_of(Farm.TILLED)).override_failure_message("that cell and no other").is_equal(1)
	assert_float(GameState.energy).is_equal(98.0)
	assert_int(GameState.health).override_failure_message("farm work never costs a heart").is_equal(hearts)
	# The sound comes when the tool lands (tool polish).
	Steps.to_the_blow(farm)
	assert_array(_heard).contains([&"hoe"])
	assert_bool(farm.player.motor.is_attacking()).override_failure_message("he stands still for the stroke").is_true()
	assert_that(farm.player.work_stroke()).override_failure_message("a stroke of the hoe").is_equal(ToolStroke.HOE)
	assert_bool(farm.player.held_tool().visible).override_failure_message("the hoe is in his hands").is_true()
	assert_int(farm.player.held_tool().frame_index).override_failure_message("come down at the blow").is_equal(HeldTools.frame_of(&"hoe", "side", ToolStroke.STRIKE))
	assert_array(_flashes(farm)).override_failure_message("no hoe floats over the cell").is_empty()
	# Mid-stroke he can't start another.
	farm.player.face(Vector2.UP)
	assert_bool(farm.use_item()).override_failure_message("not again until the stroke is done").is_false()
	assert_that(GameState.farm().state_of(Vector2i(1, 0))).is_equal(Farm.BARE)
	assert_float(GameState.energy).is_equal(98.0)
	farm.player.face(Vector2.RIGHT)
	# The same cell again: it is tilled already, and that costs nothing.
	_rest(farm)
	_heard.clear()
	assert_bool(farm.use_item()).is_false()
	assert_str(farm.hud.message_text()).is_equal(ToolUse.HOE_DONE)
	assert_array(_heard).contains_exactly([&"nope"])
	assert_float(GameState.energy).is_equal(98.0)
	assert_bool(farm.player.motor.is_attacking()).is_false()
	# Off the plot the hoe has nothing to do.
	_stand(farm, PLOT + Vector2i(1, 0), Vector2.UP)
	assert_bool(farm.use_item()).is_false()
	assert_str(farm.hud.message_text()).is_equal(ToolUse.HOE_NOT_HERE)
	assert_float(GameState.energy).is_equal(98.0)
	assert_int(GameState.farm().count_of(Farm.BARE)).is_equal(71)
	# From the grass beside the plot he can reach its edge.
	_stand(farm, PLOT + Vector2i(-1, 2), Vector2.RIGHT)
	assert_bool(farm.use_item()).is_true()
	assert_bool(GameState.farm().is_tilled(Vector2i(0, 2))).is_true()
	assert_float(GameState.energy).is_equal(96.0)


func test_the_can_waters_a_tilled_cell_for_one_energy_and_a_pour() -> void:
	GameState.add_item(&"hoe")
	GameState.add_item(&"watering_can")
	GameState.equip(&"watering_can")
	GameState.till_soil(Vector2i(2, 1))
	var hearts: int = GameState.health
	var farm: AreaController = _load(FARM)
	_stand(farm, PLOT + Vector2i(1, 1), Vector2.RIGHT)
	# Empty, it says where to fill it.
	assert_bool(farm.use_item()).is_false()
	assert_str(farm.hud.message_text()).is_equal(ToolUse.CAN_EMPTY)
	assert_array(_heard).contains_exactly([&"nope"])
	GameState.add_item(&"water", 3)
	_heard.clear()
	assert_bool(farm.use_item()).is_true()
	assert_that(GameState.farm().state_of(Vector2i(2, 1))).is_equal(Farm.WATERED)
	assert_int(GameState.item_count(&"water")).override_failure_message("one pour").is_equal(2)
	assert_float(GameState.energy).is_equal(99.0)
	assert_int(GameState.health).is_equal(hearts)
	# The sound comes when the tool lands (tool polish).
	Steps.to_the_blow(farm)
	assert_array(_heard).contains([&"pour"])
	assert_that(farm.player.work_stroke()).is_equal(ToolStroke.POUR)
	assert_int(farm.player.held_tool().frame_index).override_failure_message("the can tipped in his hands").is_equal(HeldTools.frame_of(&"watering_can", "side", ToolStroke.TIP))
	assert_array(_flashes(farm)).is_empty()
	# Wet soil needs no more, and bare soil must be tilled first: neither costs a pour.
	_rest(farm)
	assert_bool(farm.use_item()).is_false()
	assert_str(farm.hud.message_text()).is_equal(ToolUse.CAN_DONE)
	_stand(farm, PLOT + Vector2i(1, 1), Vector2.DOWN)
	assert_bool(farm.use_item()).is_false()
	assert_str(farm.hud.message_text()).is_equal(ToolUse.CAN_BARE)
	_stand(farm, PLOT + Vector2i(1, 0), Vector2.UP)
	assert_bool(farm.use_item()).is_false()
	assert_str(farm.hud.message_text()).is_equal(ToolUse.CAN_NOT_HERE)
	assert_int(GameState.item_count(&"water")).is_equal(2)
	assert_float(GameState.energy).is_equal(99.0)
	# The can says what it holds wherever it is named; the pack doesn't list the water.
	assert_str(AreaController.equipped_text()).is_equal("Item: Watering Can (Water x2)")
	assert_str(AreaController.carrying_text()).is_equal("Carrying: Hoe, Watering Can")
	farm._update_hud()
	assert_array(farm.hud.item_bar.shown_ids()).is_equal([&"hoe", &"watering_can"])
	assert_array(Array(farm.hud.item_bar.shown_counts())).override_failure_message("the can's slot says its pours").is_equal(["", "2"])
	assert_int(farm.hud.item_bar.lit_slot()).is_equal(1)


func test_the_can_fills_at_the_farms_pond() -> void:
	GameState.add_item(&"watering_can")
	GameState.add_item(&"water", 4)
	var farm: AreaController = _load(FARM)
	var layer: TileMapLayer = farm.get_node(^"Height")
	for x: int in POND.size.x:
		for y: int in POND.size.y:
			var cell: Vector2i = POND.position + Vector2i(x, y)
			assert_that(layer.get_cell_atlas_coords(cell)).override_failure_message("the pond at %s" % cell).is_equal(GreyboxTiles.coords("water"))
			assert_bool(farm.is_water_source(cell)).override_failure_message("the pond at %s" % cell).is_true()
			assert_bool(farm.grid.is_solid(cell)).override_failure_message("and nobody walks on it").is_true()
	# It is the only water on the land: there is no well until one is built.
	var water: int = 0
	for y: int in farm.grid.size.y:
		for x: int in farm.grid.size.x:
			if farm.is_water_source(Vector2i(x, y)):
				water += 1
	assert_int(water).is_equal(POND.size.x * POND.size.y)
	for dry: Vector2i in [PLOT, PLOT + Vector2i(5, 1), Vector2i(28, 12), Vector2i(28, 11), Vector2i(30, 14), Vector2i(-3, 5), POND.position + Vector2i(-1, 1), POND.end]:
		assert_bool(farm.is_water_source(dry)).override_failure_message("no water at %s" % dry).is_false()
	# From its bank he faces the water.
	_stand(farm, POND.position + Vector2i(-1, 1), Vector2.RIGHT)
	var energy: float = GameState.energy
	assert_bool(farm.use_item()).is_true()
	assert_int(GameState.item_count(&"water")).override_failure_message("ten pours").is_equal(10)
	assert_float(GameState.energy).override_failure_message("filling is free").is_equal(energy)
	# The sound comes when the tool lands (tool polish).
	Steps.to_the_blow(farm)
	assert_array(_heard).contains([&"fill"])
	assert_str(farm.hud.message_text()).is_equal(AreaController.CAN_FILLED_WORDS)
	_rest(farm)
	_heard.clear()
	assert_bool(farm.use_item()).override_failure_message("full already").is_false()
	assert_str(farm.hud.message_text()).is_equal(ToolUse.CAN_FULL)
	assert_array(_heard).contains_exactly([&"nope"])
	# And from its other banks.
	GameState.add_item(&"water", -7)
	_stand(farm, POND.position + Vector2i(2, -1), Vector2.DOWN)
	assert_bool(farm.use_item()).is_true()
	assert_int(GameState.item_count(&"water")).is_equal(10)
	# A hoe at the pond does nothing.
	GameState.add_item(&"hoe")
	GameState.equip(&"hoe")
	_rest(farm)
	assert_bool(farm.use_item()).is_false()
	assert_str(farm.hud.message_text()).is_equal(ToolUse.HOE_NOT_HERE)


func test_the_can_still_fills_at_the_villages_well_and_pond() -> void:
	GameState.add_item(&"watering_can")
	GameState.add_item(&"water", 4)
	var village: AreaController = _load(VILLAGE)
	for cell: Vector2i in WELL:
		assert_bool(village.is_water_source(cell)).override_failure_message("the well at %s" % cell).is_true()
	for x: int in VILLAGE_POND.size.x:
		for y: int in VILLAGE_POND.size.y:
			assert_bool(village.is_water_source(VILLAGE_POND.position + Vector2i(x, y))).override_failure_message("the pond").is_true()
	for dry: Vector2i in [OLD_PLOT.position, OLD_PLOT.position + Vector2i(5, 1), Vector2i(23, 20), Vector2i(8, 14), Vector2i(21, 21), Vector2i(-3, 5), Vector2i(13, 21)]:
		assert_bool(village.is_water_source(dry)).override_failure_message("no water at %s" % dry).is_false()
	# From the grass west of the well (the old plot's last cell) he faces it.
	_stand(village, OLD_PLOT.position + Vector2i(5, 1), Vector2.RIGHT)
	var energy: float = GameState.energy
	assert_bool(village.use_item()).is_true()
	assert_int(GameState.item_count(&"water")).override_failure_message("ten pours").is_equal(10)
	assert_float(GameState.energy).override_failure_message("filling is free").is_equal(energy)
	# The sound comes when the tool lands (tool polish).
	Steps.to_the_blow(village)
	assert_array(_heard).contains([&"fill"])
	assert_str(village.hud.message_text()).is_equal(AreaController.CAN_FILLED_WORDS)
	_rest(village)
	_heard.clear()
	assert_bool(village.use_item()).override_failure_message("full already").is_false()
	assert_str(village.hud.message_text()).is_equal(ToolUse.CAN_FULL)
	assert_array(_heard).contains_exactly([&"nope"])
	# And at the pond.
	GameState.add_item(&"water", -7)
	_stand(village, VILLAGE_POND.position + Vector2i(-1, 1), Vector2.RIGHT)
	assert_bool(village.use_item()).is_true()
	assert_int(GameState.item_count(&"water")).is_equal(10)
	# A hoe at the well does nothing, and neither does it where the plot was: the soil is the farm's.
	GameState.add_item(&"hoe")
	GameState.equip(&"hoe")
	_rest(village)
	assert_bool(village.use_item()).is_false()
	assert_str(village.hud.message_text()).is_equal(ToolUse.HOE_NOT_HERE)
	_stand(village, OLD_PLOT.position + Vector2i(1, 1), Vector2.RIGHT)
	assert_bool(village.use_item()).override_failure_message("no tilling in Hearthvale any more").is_false()
	assert_str(village.hud.message_text()).is_equal(ToolUse.HOE_NOT_HERE)
	assert_int(GameState.farm().count_of(Farm.TILLED)).is_equal(0)


func test_ten_pours_water_ten_cells_and_the_morning_dries_them() -> void:
	GameState.add_item(&"watering_can")
	GameState.add_item(&"water", 10)
	for x: int in 6:
		for y: int in 2:
			GameState.till_soil(Vector2i(x, y))
	var farm: AreaController = _load(FARM)
	var watered: int = 0
	for y: int in 2:
		for x: int in 6:
			_stand(farm, PLOT + Vector2i(x, y + 1), Vector2.UP)
			if farm.use_item():
				watered += 1
			_rest(farm)
	assert_int(watered).override_failure_message("a can waters ten cells").is_equal(10)
	assert_int(GameState.farm().count_of(Farm.WATERED)).is_equal(10)
	assert_int(GameState.item_count(&"water")).is_equal(0)
	assert_str(farm.hud.message_text()).is_equal(ToolUse.CAN_EMPTY)
	# Twelve cells tilled made him level 2 at farming (P4b): a pour costs nine tenths of one energy.
	assert_float(GameState.energy).override_failure_message("nine energy for ten cells, at level 2").is_equal_approx(91.0, 0.001)
	assert_str(AreaController.equipped_text()).is_equal("Item: Watering Can (Water x0)")
	GameState.start_next_day()
	assert_int(GameState.farm().count_of(Farm.WATERED)).override_failure_message("dry by morning").is_equal(0)
	assert_int(GameState.farm().count_of(Farm.TILLED)).override_failure_message("and still tilled").is_equal(12)
	assert_that(farm.plot.soil_at(PLOT)).is_equal(Farm.TILLED)
	assert_int(GameState.item_count(&"water")).override_failure_message("the can doesn't fill itself").is_equal(0)


func test_tilling_the_whole_clear_corner_costs_less_as_his_farming_rises_and_a_tool_that_does_nothing_costs_nothing() -> void:
	var rules: EnergyRules = GameState.energy_rules()
	assert_float(rules.cost(EnergyRules.HOE)).is_equal(2.0)
	assert_float(rules.cost(EnergyRules.WATER)).is_equal(1.0)
	GameState.add_item(&"hoe")
	var hearts: int = GameState.health
	var farm: AreaController = _load(FARM)
	farm.travel = func(_path: String) -> void: pass
	# The old plot's eighteen cells, each worked from the cell above it (the grass above the
	# field for the first row).
	var worked: int = 0
	for cell: Vector2i in farm.plot.cells():
		if not CLEAR.has_point(farm.plot.plot_cell(cell)):
			continue
		_stand(farm, cell + Vector2i.UP, Vector2.DOWN)
		assert_bool(farm.use_item()).override_failure_message("tilling %s" % cell).is_true()
		_rest(farm)
		worked += 1
	assert_int(worked).is_equal(18)
	assert_int(GameState.farm().count_of(Farm.TILLED)).is_equal(18)
	# Ten cells at two energy each; the tenth raises his farming (P4b), and the last eight cost 1.8.
	assert_float(GameState.energy).is_equal_approx(100.0 - 20.0 - 8.0 * 1.8, 0.001)
	assert_int(GameState.skill_level(Skills.FARMING)).is_equal(2)
	assert_int(GameState.health).is_equal(hearts)
	# A tool that does nothing costs nothing, however tired he is.
	GameState.set_energy(1.5)
	_stand(farm, PLOT + Vector2i(0, 1), Vector2.UP)
	assert_bool(farm.use_item()).is_false()
	assert_float(GameState.energy).is_equal(1.5)
	assert_int(GameState.health).is_equal(hearts)


func test_the_soil_has_its_pictures() -> void:
	var painted: Array = (preload("res://tests/support/art_sheets.gd") as GDScript).call(&"frames", "soil")
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
	for x: int in 12:
		for y: int in 6:
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
	assert_str(errors).contains("item 'spade': a tool's stats must name its 'tool': hoe or water or pick.")
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
