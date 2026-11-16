extends GdUnitTestSuite
## Seeds and crops in the world (P3b): the first pouch of seeds at home; a seed planted from
## the item button; crops that grow by the morning, wither unwatered and wait when ripe; the
## harvest picked with E; every crop raised from seed to pack in its days, and eaten raw. The
## plot stays ground to walk on, whatever grows there.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const VILLAGE: String = "res://world/areas/village/village.tscn"
const HOME: String = "res://world/areas/home/home.tscn"
const FRAME: float = 1.0 / 60.0
const PLOT: Vector2i = Vector2i(12, 18)
const TEST_SLOT: int = 983
## The plot's cell the tests work, and the map cell the hero stands in to face it (from below).
const CELL: Vector2i = Vector2i(2, 1)

var _area: Node
var _heard: Array[StringName] = []


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	SaveSystem.current_slot = TEST_SLOT
	_heard.clear()
	EventBus.sound.connect(_on_sound)


func after_test() -> void:
	EventBus.sound.disconnect(_on_sound)
	if is_instance_valid(_area):
		_area.free()
	_area = null
	SaveSystem.erase_slot(TEST_SLOT)
	SaveSystem.current_slot = SaveSystem.GAME_SLOT
	GameState.clear()


func test_the_first_pouch_of_turnip_seeds_lies_at_home() -> void:
	var home: AreaController = _load(HOME)
	var pouch: ItemPickup = home.interactables.get_node(^"TurnipSeeds")
	assert_that(pouch.item_id).is_equal(&"turnip_seeds")
	assert_int(pouch.count).is_equal(5)
	assert_bool(home.grid.is_solid(pouch.cell()) or home.terrain.is_occupied(pouch.cell())).override_failure_message("on open floor").is_false()
	var cells: Dictionary = {}
	for node_name: String in ["Hoe", "WateringCan", "TurnipSeeds"]:
		cells[(home.interactables.get_node(NodePath(node_name)) as ItemPickup).cell()] = true
	assert_int(cells.size()).override_failure_message("each in a cell of its own").is_equal(3)
	home.player.motor.place(pouch.cell())
	home._update_hud()
	assert_str(home.hud.prompt_text()).is_equal("[Right click] Pick up the Turnip Seeds")
	assert_bool(home.interact()).is_true()
	assert_int(GameState.item_count(&"turnip_seeds")).is_equal(5)
	assert_that(GameState.equipped).override_failure_message("with nothing else on the button, the seeds go there").is_equal(&"turnip_seeds")
	assert_str(AreaController.equipped_text()).is_equal("Item: Turnip Seeds x5")
	assert_object(home.pickup_under_player()).is_null()


func test_a_seed_is_planted_from_the_item_button_in_tilled_soil() -> void:
	GameState.add_item(&"turnip_seeds", 2)
	GameState.damage(1)
	var hearts: int = GameState.health
	GameState.till_soil(CELL)
	var village: AreaController = _load(VILLAGE)
	_face(village, CELL)
	assert_bool(village.use_item()).is_true()
	assert_str(GameState.farm().crop_at(CELL)).is_equal("turnip")
	assert_that(GameState.crop_phase(CELL)).is_equal(Farm.SEEDED)
	assert_int(GameState.item_count(&"turnip_seeds")).override_failure_message("one seed").is_equal(1)
	assert_float(GameState.energy).override_failure_message("planting costs no energy").is_equal(100.0)
	assert_int(GameState.health).is_equal(hearts)
	assert_array(_heard).contains([&"plant"])
	assert_bool(village.player.motor.is_attacking()).override_failure_message("it takes a moment").is_true()
	assert_that(_flashes(village)[0].icon).is_equal(&"turnip_seeds")
	# Not twice in one cell, not in bare soil, not off the plot: none of it costs a seed.
	_rest(village)
	_heard.clear()
	assert_bool(village.use_item()).is_false()
	assert_str(village.hud.message_text()).is_equal(ToolUse.SEED_TAKEN)
	assert_array(_heard).contains_exactly([&"nope"])
	_face(village, CELL + Vector2i(1, 0))
	assert_bool(village.use_item()).is_false()
	assert_str(village.hud.message_text()).is_equal(ToolUse.SEED_BARE)
	village.player.motor.place(PLOT + Vector2i(1, 0))
	village.player.face(Vector2.UP)
	assert_bool(village.use_item()).is_false()
	assert_str(village.hud.message_text()).is_equal(ToolUse.SEED_NOT_HERE)
	assert_int(GameState.item_count(&"turnip_seeds")).is_equal(1)
	assert_int(GameState.farm().crop_count()).is_equal(1)
	# The last seed goes in; then there are none: their slot is gone and the item button is empty.
	GameState.till_soil(CELL + Vector2i(1, 0))
	_face(village, CELL + Vector2i(1, 0))
	assert_bool(village.use_item()).is_true()
	assert_int(GameState.item_count(&"turnip_seeds")).is_equal(0)
	GameState.till_soil(CELL + Vector2i(2, 0))
	_face(village, CELL + Vector2i(2, 0))
	_rest(village)
	assert_that(GameState.equipped).override_failure_message("nothing he no longer has is on the button").is_equal(&"")
	assert_bool(village.use_item()).is_false()
	assert_str(village.hud.message_text()).is_equal("Nothing on the item button yet.")
	assert_int(GameState.farm().crop_count()).is_equal(2)


func test_the_tools_on_a_planted_cell() -> void:
	for item: Array in [[&"hoe", 1], [&"watering_can", 1], [&"water", 4]]:
		GameState.add_item(item[0], item[1])
	GameState.till_soil(CELL)
	GameState.plant_crop(CELL, &"carrot")
	var village: AreaController = _load(VILLAGE)
	_face(village, CELL)
	assert_bool(village.use_item()).override_failure_message("the hoe leaves a crop alone").is_false()
	assert_str(village.hud.message_text()).is_equal(ToolUse.HOE_GROWING)
	assert_float(GameState.energy).is_equal(100.0)
	assert_str(GameState.farm().crop_at(CELL)).is_equal("carrot")
	GameState.equip(&"watering_can")
	assert_bool(village.use_item()).override_failure_message("the can waters it").is_true()
	assert_bool(GameState.farm().is_watered(CELL)).is_true()
	assert_float(GameState.energy).is_equal(99.0)


func test_a_watered_turnip_ripens_in_three_mornings_and_is_picked_with_e() -> void:
	GameState.till_soil(CELL)
	GameState.plant_crop(CELL, &"turnip")
	var village: AreaController = _load(VILLAGE)
	_face(village, CELL)
	var seen: Array = [GameState.crop_phase(CELL)]
	for morning: int in 3:
		village._update_hud()
		assert_str(village.hud.prompt_text()).override_failure_message("nothing to pick yet").is_equal("")
		assert_bool(village.interact()).override_failure_message("E does nothing to a growing crop").is_false()
		GameState.water_soil(CELL)
		GameState.start_next_day()
		seen.append(GameState.crop_phase(CELL))
	assert_array(seen).is_equal([Farm.SEEDED, Farm.SPROUT, Farm.GROWING, Farm.RIPE])
	assert_bool(GameState.is_crop_ripe(CELL)).is_true()
	village._update_hud()
	assert_str(village.hud.prompt_text()).is_equal("[Right click] Pick the Turnip")
	assert_dict(village.crop_in_front()).is_equal({"cell": CELL, "name": "Turnip", "phase": Farm.RIPE})
	var energy: float = GameState.energy
	_heard.clear()
	assert_bool(village.interact()).is_true()
	assert_int(GameState.item_count(&"turnip")).is_equal(1)
	assert_bool(GameState.farm().has_crop(CELL)).is_false()
	assert_bool(GameState.farm().is_tilled(CELL)).override_failure_message("the soil is still tilled").is_true()
	assert_float(GameState.energy).override_failure_message("picking costs no energy").is_equal(energy)
	assert_str(village.hud.message_text()).is_equal("Picked: Turnip.")
	assert_array(_heard).contains([&"harvest"])
	assert_bool(village.player.controls_enabled).is_true()
	village._update_hud()
	assert_str(village.hud.prompt_text()).is_equal("")
	assert_bool(village.interact()).override_failure_message("nothing left to pick").is_false()
	assert_int(GameState.item_count(&"turnip")).is_equal(1)


func test_two_dry_mornings_wither_a_crop_and_e_clears_it_away() -> void:
	GameState.till_soil(CELL)
	GameState.plant_crop(CELL, &"wheat")
	GameState.water_soil(CELL)
	var village: AreaController = _load(VILLAGE)
	_face(village, CELL)
	GameState.start_next_day()
	GameState.start_next_day()
	assert_that(GameState.crop_phase(CELL)).override_failure_message("one dry morning").is_equal(Farm.SPROUT)
	GameState.start_next_day()
	assert_that(GameState.crop_phase(CELL)).is_equal(Farm.WITHERED)
	village._update_hud()
	assert_str(village.hud.prompt_text()).is_equal("[Right click] Clear the withered Wheat")
	assert_bool(village.interact()).is_true()
	assert_bool(GameState.farm().has_crop(CELL)).is_false()
	assert_bool(GameState.farm().is_tilled(CELL)).is_true()
	assert_int(GameState.item_count(&"wheat")).override_failure_message("a withered crop gives nothing").is_equal(0)
	assert_str(village.hud.message_text()).is_equal("You clear away the withered wheat.")
	assert_float(GameState.energy).is_equal(100.0)
	# And the cell can be planted again.
	GameState.add_item(&"wheat_seeds", 1)
	GameState.equip(&"wheat_seeds")
	assert_bool(village.use_item()).is_true()
	assert_that(GameState.crop_phase(CELL)).is_equal(Farm.SEEDED)


func test_every_crop_is_raised_from_seed_to_pack_in_its_days_and_eaten_raw() -> void:
	GameState.add_item(&"hoe")
	GameState.add_item(&"watering_can")
	var village: AreaController = _load(VILLAGE)
	var crops: Array = DataRegistry.entries(&"crops")
	assert_int(crops.size()).is_equal(5)
	# A column a crop: till it, plant it and water it, as the player does.
	for x: int in crops.size():
		var cell: Vector2i = Vector2i(x, 0)
		_face(village, cell)
		GameState.equip(&"hoe")
		assert_bool(village.use_item()).is_true()
		_rest(village)
		GameState.add_item(StringName(str(crops[x]["seed"])), 1)
		GameState.equip(StringName(str(crops[x]["seed"])))
		assert_bool(village.use_item()).override_failure_message("planting %s" % crops[x]["id"]).is_true()
		_rest(village)
	var mornings: Dictionary = {}
	for morning: int in range(1, 9):
		GameState.add_item(&"water", 10)
		GameState.equip(&"watering_can")
		for x: int in crops.size():
			_face(village, Vector2i(x, 0))
			if not GameState.is_crop_ripe(Vector2i(x, 0)):
				assert_bool(village.use_item()).is_true()
				_rest(village)
		GameState.set_energy(GameState.max_energy())
		GameState.start_next_day()
		for x: int in crops.size():
			if GameState.is_crop_ripe(Vector2i(x, 0)) and not mornings.has(crops[x]["id"]):
				mornings[crops[x]["id"]] = morning
	assert_dict(mornings).override_failure_message("each ripens on the morning its data says").is_equal({"turnip": 3, "carrot": 4, "wheat": 5, "potato": 5, "pumpkin": 8})
	# The harvest goes into the pack, and each crop can be eaten raw.
	GameState.set_energy(20.0)
	for x: int in crops.size():
		_face(village, Vector2i(x, 0))
		assert_bool(village.interact()).override_failure_message("picking %s" % crops[x]["id"]).is_true()
		var item_id: StringName = StringName(str(crops[x]["gives"]["item"]))
		assert_int(GameState.item_count(item_id)).is_equal(1)
		var before: float = GameState.energy
		assert_bool(GameState.eat(item_id)).override_failure_message("eating %s" % item_id).is_true()
		assert_float(GameState.energy - before).is_equal(Food.energy_of(DataRegistry.get_item(item_id)))
		assert_int(GameState.item_count(item_id)).is_equal(0)
	assert_int(GameState.farm().crop_count()).is_equal(0)
	assert_int(GameState.farm().count_of(Farm.TILLED) + GameState.farm().count_of(Farm.WATERED)).override_failure_message("five tilled cells left").is_equal(5)
	assert_int(GameState.health).override_failure_message("a season's work never cost a heart").is_equal(GameState.max_health())


func test_a_full_pack_leaves_the_crop_in_the_soil() -> void:
	GameState.farm().load_saved({"cells": {"2,1": {"watered": false, "crop": "pumpkin", "stage": 8}}})
	GameState.add_item(&"pumpkin", 30)
	var village: AreaController = _load(VILLAGE)
	_face(village, CELL)
	assert_bool(GameState.is_crop_ripe(CELL)).is_true()
	assert_bool(village.interact()).override_failure_message("he tried, and was told").is_true()
	assert_str(village.hud.message_text()).is_equal("Your pack holds no more pumpkin.")
	assert_array(_heard).contains([&"nope"])
	assert_str(GameState.farm().crop_at(CELL)).override_failure_message("it waits in the soil").is_equal("pumpkin")
	assert_int(GameState.item_count(&"pumpkin")).is_equal(30)
	GameState.add_item(&"pumpkin", -1)
	assert_bool(village.interact()).is_true()
	assert_int(GameState.item_count(&"pumpkin")).is_equal(30)
	assert_bool(GameState.farm().has_crop(CELL)).is_false()


func test_he_walks_through_his_crops_and_harms_nothing() -> void:
	var cells: Dictionary = {}
	for x: int in 6:
		for y: int in 3:
			cells["%d,%d" % [x, y]] = {"watered": false, "crop": "pumpkin", "stage": 8 if y == 1 else 3}
	GameState.farm().load_saved({"cells": cells})
	var before: Dictionary = GameState.farm().to_dict()
	var village: AreaController = _load(VILLAGE)
	village.player.motor.place(PLOT + Vector2i(-1, 1))
	village.player.face(Vector2.RIGHT)
	for i: int in 200:
		village.player.motor.step(Vector2.RIGHT, FRAME)
	assert_that(village.player.motor.cell).override_failure_message("across the whole plot, ripe pumpkins and all").is_equal(PLOT + Vector2i(5, 1))
	for cell: Vector2i in village.plot.cells():
		assert_bool(village.grid.is_solid(cell) or village.terrain.is_occupied(cell)).override_failure_message("%s is open" % cell).is_false()
	assert_dict(GameState.farm().to_dict()).override_failure_message("nothing was trampled").is_equal(before)


func test_crops_have_their_pictures() -> void:
	var tool: Dictionary = (load("res://tools/art/make_sprites.gd") as GDScript).get_script_constant_map()
	var painted: Array = (tool["SPRITES"]["crops"]["frames"] as Dictionary).keys()
	assert_int(painted.size()).is_equal(FarmPlot.CROP_FRAMES.size())
	for i: int in painted.size():
		assert_int(int(FarmPlot.CROP_FRAMES[StringName(str(painted[i]))])).override_failure_message("%s is frame %d" % [painted[i], i]).is_equal(i)
	assert_that(Vector2i(FarmPlot.CROPS.get_size())).is_equal(Vector2i(FarmPlot.CELL.x * FarmPlot.CROP_FRAMES.size(), FarmPlot.CELL.y * 2))
	# Each picture is something, and leaves soil showing round it.
	var image: Image = FarmPlot.CROPS.get_image()
	for frame: StringName in FarmPlot.CROP_FRAMES:
		var painted_pixels: int = 0
		for y: int in FarmPlot.CELL.y:
			for x: int in FarmPlot.CELL.x:
				if image.get_pixel(int(FarmPlot.CROP_FRAMES[frame]) * FarmPlot.CELL.x + x, y).a > 0.0:
					painted_pixels += 1
		assert_int(painted_pixels).override_failure_message("%s is %d pixels" % [frame, painted_pixels]).is_between(16, 200)
	# What every crop shares, and what a crop with no pictures of its own falls back to.
	for phase: StringName in [Farm.SEEDED, Farm.SPROUT, Farm.WITHERED]:
		assert_that(FarmPlot.crop_frame("turnip", phase)).is_equal(phase)
		assert_that(FarmPlot.crop_frame("pumpkin", phase)).is_equal(phase)
	assert_that(FarmPlot.crop_frame("moonflower", Farm.GROWING)).is_equal(&"sprout")
	assert_that(FarmPlot.crop_frame("moonflower", Farm.RIPE)).is_equal(&"sprout")
	assert_that(FarmPlot.crop_frame("moonflower", Farm.WITHERED)).is_equal(&"withered")
	for id: StringName in [&"plant", &"harvest"]:
		assert_bool(Audio.SFX.has(id)).override_failure_message("%s is a sound the game has" % id).is_true()


func test_a_long_item_list_scrolls_to_keep_the_cursor_in_view() -> void:
	assert_int(MenuCursor.window_top(0, 0, 3, 5)).override_failure_message("a list that fits doesn't scroll").is_equal(0)
	assert_int(MenuCursor.window_top(0, 4, 9, 5)).is_equal(0)
	assert_int(MenuCursor.window_top(0, 5, 9, 5)).override_failure_message("down a line at a time").is_equal(1)
	assert_int(MenuCursor.window_top(1, 8, 9, 5)).is_equal(4)
	assert_int(MenuCursor.window_top(4, 6, 9, 5)).override_failure_message("it stays while the cursor is in view").is_equal(4)
	assert_int(MenuCursor.window_top(4, 3, 9, 5)).override_failure_message("and up a line at a time").is_equal(3)
	assert_int(MenuCursor.window_top(4, 0, 9, 5)).override_failure_message("wrapping to the top").is_equal(0)
	assert_int(MenuCursor.window_top(7, 8, 9, 5)).override_failure_message("never past the end").is_equal(4)
	assert_str(MenuCursor.count_text(0, 0, 3, 5)).is_equal("")
	assert_str(MenuCursor.count_text(0, 2, 9, 5)).is_equal("  3/9 v")
	assert_str(MenuCursor.count_text(2, 4, 9, 5)).is_equal("^ 5/9 v")
	assert_str(MenuCursor.count_text(4, 8, 9, 5)).is_equal("^ 9/9  ")
	# In the game: a harvest and what was gathered are eight lines of food in a box of five.
	# (The tools and the seeds are on the bar at the bottom, seven slots of it.)
	for item: Array in [[&"hoe", 1], [&"watering_can", 1], [&"turnip_seeds", 5], [&"carrot_seeds", 3], [&"wheat_seeds", 3], [&"potato_seeds", 3], [&"pumpkin_seeds", 2],
			[&"turnip", 4], [&"carrot", 2], [&"wheat", 6], [&"potato", 1], [&"pumpkin", 1], [&"bread", 2], [&"wild_berries", 3], [&"mushroom", 1]]:
		GameState.add_item(item[0], item[1])
	assert_int(GameState.hand_entries().size()).is_equal(7)
	var village: AreaController = _load(VILLAGE)
	assert_bool(village.open_item_menu()).is_true()
	var menu: ItemMenu = village.hud.item_menu
	assert_int(menu.items.size()).is_equal(8)
	assert_int(menu.shown_lines().size()).override_failure_message("five lines, never more").is_equal(ItemMenu.ROWS)
	assert_array(Array(menu.shown_lines())).is_equal(["> Turnip x4 (+7 energy)", "  Carrot x2 (+7 energy)", "  Wheat x6 (+5 energy)", "  Potato x1 (+8 energy)", "  Pumpkin x1 (+22 energy)"])
	for i: int in 5:
		menu.move_cursor(1)
	assert_str(menu.shown_lines()[4]).is_equal("> Bread x2 (+30 energy)")
	for i: int in 2:
		menu.move_cursor(1)
	assert_str(menu.shown_lines()[4]).is_equal("> Mushrooms x1 (+6 energy)")
	menu.move_cursor(1)
	assert_array(Array(menu.shown_lines())).override_failure_message("past the end it wraps to the top").is_equal(["> Turnip x4 (+7 energy)", "  Carrot x2 (+7 energy)", "  Wheat x6 (+5 energy)", "  Potato x1 (+8 energy)", "  Pumpkin x1 (+22 energy)"])
	menu.move_cursor(-1)
	assert_str(menu.shown_lines()[4]).is_equal("> Mushrooms x1 (+6 energy)")


## Puts the hero in the cell below the plot's own cell `cell`, facing up at it.
func _face(area: AreaController, cell: Vector2i) -> void:
	area.player.motor.place(PLOT + cell + Vector2i.DOWN)
	area.player.face(Vector2.UP)


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


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area


func _on_sound(id: StringName) -> void:
	_heard.append(id)
