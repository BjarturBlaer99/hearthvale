extends GdUnitTestSuite
## The home's move (the Homestead, 2026-11-17, phase 1, step 1a): the hero lives in the
## farmhouse on his own land. Its door leads in and out; sleeping, staying up until 02:00 and
## collapsing each wake him in the farmhouse, and his door opens onto the farm; the old
## cottage in Hearthvale is locked at every hour and says so; and a save made inside the old
## cottage (written by the game as it stood before the Homestead) opens inside the farmhouse
## with all it had, its soil and crops in the field's clear corner.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const VILLAGE: String = "res://world/areas/village/village.tscn"
const FARM: String = "res://world/areas/homestead/homestead.tscn"
const HOME: String = "res://world/areas/home/home.tscn"
const V5: String = "res://tests/fixtures/saves/v5_in_the_old_cottage.json"
const TEST_SLOT: int = 951
const FRAME: float = 1.0 / 60.0
## The farmhouse's door on the homestead and the cell before it; the cell inside the door.
const DOOR: Vector2i = Vector2i(28, 11)
const DOORSTEP: Vector2i = Vector2i(28, 12)
const INSIDE: Vector2i = Vector2i(5, 7)
## The field's north-west corner on the homestead: the old plot's cells begin here.
const PLOT: Vector2i = Vector2i(22, 17)
## The old cottage's door in Hearthvale, and what it says.
const COTTAGE_DOOR: Vector2i = Vector2i(8, 14)
const LOCKED: String = "The cottage stands empty, and its door is locked."
## Where the plot lay in Hearthvale.
const OLD_PLOT: Vector2i = Vector2i(12, 18)

var _area: Node
var _heard: Array[StringName] = []


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	Quests.refresh()
	GameState.set_time(float(GameState.day_clock().in_day("12:00")))
	SaveSystem.erase_slot(TEST_SLOT)
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


func test_the_farmhouse_door_leads_in_and_out() -> void:
	assert_that(WorldPaths.HOME_AREA).override_failure_message("the home is still the area it was").is_equal(&"home")
	# In: from the doorstep, up through the door.
	GameState.update_player(&"homestead", DOORSTEP)
	var farm: AreaController = _load(FARM)
	var door: AreaExit = farm.interactables.get_node(^"FarmhouseDoor")
	assert_that(door.cell()).is_equal(DOOR)
	assert_bool(farm.is_shut(door)).override_failure_message("his own door is never shut").is_false()
	farm.player.face(Vector2.UP)
	assert_str(Steps.walk_until_travel(farm, Vector2.UP)).is_equal(HOME)
	assert_dict(GameState.player).is_equal({"area": "home", "entry": "door"})
	var home: AreaController = _load(HOME)
	assert_str(home.area_name).is_equal("Your farmhouse")
	assert_that(home.player.motor.cell).is_equal(INSIDE)
	assert_that(home.player.facing_direction()).is_equal(Vector2i.UP)
	# Out: down over the doormat, onto the farm, before his door and facing his land.
	assert_str(Steps.walk_until_travel(home, Vector2.DOWN)).override_failure_message("his door opens onto the farm, not the village").is_equal(FARM)
	assert_dict(GameState.player).is_equal({"area": "homestead", "entry": "farmhouse_door"})
	farm = _load(FARM)
	assert_that(farm.player.motor.cell).is_equal(DOORSTEP)
	assert_that(farm.player.facing_direction()).is_equal(Vector2i.DOWN)
	assert_that(PlayerMotor.cell_of(farm.entry_marker(&"farmhouse_door").position)).is_equal(DOORSTEP)
	# At night too: his own door keeps no hours.
	GameState.set_time(float(GameState.day_clock().in_day("23:30")))
	farm = _load(FARM)
	farm.player.motor.place(DOORSTEP)
	assert_str(Steps.walk_until_travel(farm, Vector2.UP)).is_equal(HOME)


func test_staying_up_until_two_on_the_farm_wakes_him_in_the_farmhouse() -> void:
	GameState.update_player(&"homestead", Vector2i(10, 20))
	var farm: AreaController = _load(FARM)
	var travelled: Array[String] = []
	farm.travel = func(path: String) -> void: travelled.append(path)
	var clock: DayClock = GameState.day_clock()
	GameState.set_time(float(clock.ends) - 1.0)
	farm._process(clock.seconds_per_hour / 60.0 * 0.5)
	assert_array(travelled).override_failure_message("not yet").is_empty()
	farm._process(clock.seconds_per_hour / 60.0)
	assert_array(travelled).override_failure_message("02:00: home").is_equal([HOME])
	assert_dict(GameState.player).is_equal({"area": "home", "entry": "bed"})
	assert_int(GameState.day).is_equal(2)
	assert_bool(SaveSystem.has_slot(TEST_SLOT)).override_failure_message("the new day is saved").is_true()
	_wakes_by_his_bed_and_his_door_opens_onto_the_farm(AreaController.WOKE_LATE_WORDS)


func test_collapsing_on_the_farm_wakes_him_in_the_farmhouse() -> void:
	GameState.add_item(&"wooden_sword")
	GameState.update_player(&"homestead", Vector2i(10, 20))
	var farm: AreaController = _load(FARM)
	var travelled: Array[String] = []
	farm.travel = func(path: String) -> void: travelled.append(path)
	GameState.set_energy(0.4)
	assert_bool(farm.player.swing()).override_failure_message("his last swing").is_true()
	farm._process(FRAME)
	assert_bool(farm.is_collapsing()).is_true()
	farm._process(AreaController.COLLAPSE_TIME + 0.1)
	assert_array(travelled).is_equal([HOME])
	assert_dict(GameState.player).is_equal({"area": "home", "entry": "bed"})
	assert_int(GameState.day).override_failure_message("the next morning").is_equal(2)
	assert_float(GameState.energy).override_failure_message("half his energy").is_equal(GameState.energy_rules().wake_energy())
	_wakes_by_his_bed_and_his_door_opens_onto_the_farm(AreaController.COLLAPSED_WORDS)


func test_collapsing_in_the_village_wakes_him_in_the_farmhouse_too() -> void:
	GameState.add_item(&"wooden_sword")
	var village: AreaController = _load(VILLAGE)
	var travelled: Array[String] = []
	village.travel = func(path: String) -> void: travelled.append(path)
	GameState.set_energy(0.4)
	assert_bool(village.player.swing()).is_true()
	village._process(FRAME)
	village._process(AreaController.COLLAPSE_TIME + 0.1)
	assert_array(travelled).is_equal([HOME])
	_wakes_by_his_bed_and_his_door_opens_onto_the_farm(AreaController.COLLAPSED_WORDS)


func test_sleeping_in_the_farmhouse_wakes_him_there_and_the_save_opens_there() -> void:
	var home: AreaController = _load(HOME)
	var bed: Bed = home.interactables.get_node(^"Bed")
	var by_bed: Vector2i = bed.cell() + Vector2i.RIGHT
	home.player.motor.place(by_bed)
	home.player.face(Vector2.LEFT)
	GameState.set_time(float(GameState.day_clock().in_day("21:00")))
	assert_bool(home.interact()).is_true()
	home.hud.dialogue.confirm()
	assert_int(GameState.day).is_equal(2)
	assert_str(home.hud.message_text()).is_equal(AreaController.SLEPT_WORDS)
	assert_that(home.player.motor.cell).override_failure_message("he is by his bed, in the farmhouse").is_equal(by_bed)
	assert_bool(SaveSystem.has_slot(TEST_SLOT)).is_true()
	assert_dict(SaveSystem.summary()).is_equal({"area": "home", "play_time": 0.0, "hearts_max": 3, "finished": false})
	assert_str(WorldPaths.area_name(&"home")).override_failure_message("the title names where the save was made").is_equal("Your farmhouse")
	# Carrying on from that save: in the farmhouse, and out of its door is the farm.
	GameState.clear()
	assert_int(SaveSystem.load_from_slot(TEST_SLOT)).is_equal(OK)
	assert_dict(GameState.player).is_equal({"area": "home", "cell": [by_bed.x, by_bed.y]})
	home = _load(HOME)
	assert_that(home.player.motor.cell).is_equal(by_bed)
	home.player.motor.place(INSIDE)
	assert_str(Steps.walk_until_travel(home, Vector2.DOWN)).is_equal(FARM)


func test_the_old_cottage_is_locked_at_every_hour_and_says_so() -> void:
	# The rule: a place that is never open, whatever the minute.
	var hours: Hours = Hours.new(DataRegistry.get_rules(DataRegistry.RULES_HOURS))
	assert_str(hours.shut_words(&"old_cottage")).is_equal(LOCKED)
	for minute: int in range(0, DayClock.DAY + 180, 7):
		assert_bool(hours.is_open(&"old_cottage", float(minute))).override_failure_message("locked at minute %d" % minute).is_false()
	assert_bool(hours.is_open(&"shop", float(GameState.day_clock().in_day("12:00")))).override_failure_message("the shop keeps its own hours still").is_true()
	# In the world, hour by hour through the day and the night.
	for hour: String in ["06:00", "08:00", "12:00", "17:59", "18:00", "20:00", "23:59", "00:00", "01:59"]:
		GameState.set_time(float(GameState.day_clock().in_day(hour)))
		var village: AreaController = _load(VILLAGE)
		var door: AreaExit = village.interactables.get_node(^"HomeDoor")
		assert_that(door.cell()).is_equal(COTTAGE_DOOR)
		assert_that(door.hours).is_equal(&"old_cottage")
		assert_bool(village.is_shut(door)).override_failure_message("shut at %s" % hour).is_true()
		assert_bool(village.terrain.is_occupied(COTTAGE_DOOR)).override_failure_message("a shut door is solid at %s" % hour).is_true()
		# He walks up to it: he is told, and stands before it.
		_heard.clear()
		village.player.motor.place(COTTAGE_DOOR + Vector2i(0, 2))
		village.player.face(Vector2.UP)
		assert_str(Steps.walk_until_travel(village, Vector2.UP, 90)).override_failure_message("he doesn't get in at %s" % hour).is_equal("")
		assert_that(village.player.motor.cell).override_failure_message("before the door, not in it").is_equal(COTTAGE_DOOR + Vector2i.DOWN)
		assert_str(village.hud.message_text()).override_failure_message("its words at %s" % hour).is_equal(LOCKED)
		assert_array(_heard).contains([&"nope"])
		# Trying it says so again, and nothing takes him through it.
		village.hud.show_message("-")
		assert_bool(village.interact()).is_true()
		assert_str(village.hud.message_text()).is_equal(LOCKED)
		var travelled: Array[String] = []
		village.travel = func(path: String) -> void: travelled.append(path)
		village.take_exit(door)
		assert_array(travelled).is_empty()
		assert_bool(village.player.controls_enabled).is_true()
	# The hour turning opens nothing: he stands before it as the shop opens.
	GameState.set_time(float(GameState.day_clock().in_day("07:59")))
	var village_at_dawn: AreaController = _load(VILLAGE)
	var cottage: AreaExit = village_at_dawn.interactables.get_node(^"HomeDoor")
	GameState.set_time(float(GameState.day_clock().in_day("08:00")))
	village_at_dawn._process(FRAME)
	assert_bool(village_at_dawn.is_shut(village_at_dawn.interactables.get_node(^"ShopDoor"))).override_failure_message("the shop has opened").is_false()
	assert_bool(village_at_dawn.is_shut(cottage)).is_true()
	assert_bool(village_at_dawn.terrain.is_occupied(COTTAGE_DOOR)).is_true()
	# The cottage still stands, and the way out of it is still there for nobody to use.
	assert_object(village_at_dawn.entry_marker(&"home_door")).is_not_null()
	assert_bool(village_at_dawn.grid.is_solid(COTTAGE_DOOR + Vector2i.LEFT)).is_true()


func test_a_save_made_in_the_old_cottage_opens_in_the_farmhouse_with_all_it_had() -> void:
	# The save as it would lie on disk, written by the game before the Homestead.
	DirAccess.make_dir_recursive_absolute(SaveSystem.SAVE_DIR)
	var file: FileAccess = FileAccess.open(SaveSystem.slot_path(TEST_SLOT), FileAccess.WRITE)
	file.store_string(FileAccess.get_file_as_string(V5))
	file.close()
	# The title offers it by the room's new name.
	assert_str(WorldPaths.area_name(StringName(str(SaveSystem.summary()["area"])))).is_equal("Your farmhouse")
	GameState.clear()
	assert_int(SaveSystem.load_from_slot(TEST_SLOT)).is_equal(OK)
	assert_str(WorldPaths.scene_for(StringName(str(GameState.player["area"])))).override_failure_message("carrying on opens the farmhouse").is_equal(HOME)

	# Inside the farmhouse, on the cell he stood on: it is the same room.
	var home: AreaController = _load(HOME)
	assert_str(home.area_name).is_equal("Your farmhouse")
	assert_that(home.player.motor.cell).is_equal(Vector2i(4, 5))
	# The furnishings he had made stand in their places, and those he hadn't are not there.
	for made: Array in [["Furnace", Vector2i(6, 2)], ["Chest", Vector2i(2, 2)], ["Workbench", Vector2i(9, 3)]]:
		var furnishing: Furnishing = home.interactables.get_node(NodePath(str(made[0])))
		assert_bool(furnishing.is_there()).override_failure_message("%s stands" % made[0]).is_true()
		assert_that(furnishing.cell()).override_failure_message("%s in its place" % made[0]).is_equal(made[1])
		assert_bool(home.terrain.is_occupied(made[1])).is_true()
	for unmade: String in ["Lamp", "Rug"]:
		assert_bool((home.interactables.get_node(NodePath(unmade)) as Furnishing).is_there()).override_failure_message("no %s" % unmade).is_false()
	assert_bool((home.interactables.get_node(^"Furnace") as Furnishing).is_burning()).override_failure_message("the furnace is burning, as he left it").is_true()
	assert_int(GameState.store().to_list().size()).override_failure_message("the chest's five stacks").is_equal(5)
	# The tools he took are gone from the floor; the first seeds still lie inside the door.
	assert_bool((home.interactables.get_node(^"Hoe") as ItemPickup).taken() and (home.interactables.get_node(^"WateringCan") as ItemPickup).taken()).is_true()
	var seeds: ItemPickup = home.interactables.get_node(^"TurnipSeeds")
	assert_bool(seeds.taken()).override_failure_message("the first seeds lie on the farmhouse's floor").is_false()
	assert_that(seeds.cell()).is_equal(Vector2i(6, 7))
	# What was laid at his feet at home lies where it lay.
	var lying: Array = home.interactables.get_children().filter(func(child: Node) -> bool: return child is LeftItem)
	assert_int(lying.size()).is_equal(1)
	assert_that((lying[0] as LeftItem).cell()).is_equal(Vector2i(6, 5))
	assert_that((lying[0] as LeftItem).item_id).is_equal(&"arrow")

	# Out of his door he is on the farm.
	home.player.motor.place(INSIDE)
	assert_str(Steps.walk_until_travel(home, Vector2.DOWN)).is_equal(FARM)
	var farm: AreaController = _load(FARM)
	assert_that(farm.player.motor.cell).is_equal(DOORSTEP)
	# His soil, crops and sprinkler are in the field's clear corner: the same cells of the plot.
	assert_that(farm.plot.origin()).is_equal(PLOT)
	assert_that(farm.plot.soil_at(PLOT)).is_equal(Farm.TILLED)
	assert_that(farm.plot.soil_at(PLOT + Vector2i(1, 0))).is_equal(Farm.WATERED)
	assert_that(GameState.crop_phase(farm.plot.plot_cell(PLOT))).is_equal(Farm.RIPE)
	assert_that(GameState.crop_phase(farm.plot.plot_cell(PLOT + Vector2i(5, 0)))).is_equal(Farm.WITHERED)
	assert_bool(GameState.farm().has_sprinkler(farm.plot.plot_cell(PLOT + Vector2i(4, 1)))).is_true()
	assert_that(farm.plot.soil_at(PLOT + Vector2i(0, 2))).override_failure_message("the row he never tilled").is_equal(Farm.BARE)
	for cell_key: String in (GameState.farm().to_dict()["cells"] as Dictionary):
		var cell: Vector2i = farm.plot.map_cell(Farm.cell_of(cell_key))
		assert_bool(Rect2i(PLOT, Vector2i(6, 3)).has_point(cell)).override_failure_message("%s is in the clear corner" % cell).is_true()
		assert_bool(farm.grid.is_solid(cell) or farm.terrain.is_occupied(cell)).override_failure_message("nothing stands on %s" % cell).is_false()
	# He picks the ripe turnip he left, from the grass above the field.
	farm.player.motor.place(PLOT + Vector2i.UP)
	farm.player.face(Vector2.DOWN)
	var turnips: int = GameState.item_count(&"turnip")
	assert_str(farm.crop_prompt()).is_equal("Pick the Turnip")
	assert_bool(farm.interact()).is_true()
	assert_int(GameState.item_count(&"turnip")).is_greater(turnips)
	# The homestead is as a new game's: nothing cleared.
	assert_int(GameState.homestead().cleared_count()).is_equal(0)

	# In Hearthvale, what was laid at his feet lies where it lay; where the plot was is grass,
	# and the cottage he saved in is locked.
	var village: AreaController = _load(VILLAGE)
	var left: Array = village.interactables.get_children().filter(func(child: Node) -> bool: return child is LeftItem)
	assert_int(left.size()).is_equal(1)
	assert_that((left[0] as LeftItem).cell()).is_equal(Vector2i(14, 17))
	assert_object(village.plot).override_failure_message("Hearthvale has no plot").is_null()
	assert_that((village.get_node(^"Height") as TileMapLayer).get_cell_atlas_coords(OLD_PLOT)).is_equal(GreyboxTiles.coords("ground"))
	assert_bool(village.is_shut(village.interactables.get_node(^"HomeDoor"))).is_true()


## After a day ended somewhere else: he arrives by his bed in the farmhouse and is told why,
## and walking out of his door he is on the farm.
func _wakes_by_his_bed_and_his_door_opens_onto_the_farm(words: String) -> void:
	var home: AreaController = _load(HOME)
	var bed: Bed = home.interactables.get_node(^"Bed")
	assert_str(home.area_name).is_equal("Your farmhouse")
	assert_that(home.player.motor.cell).is_equal(bed.cell() + Vector2i.RIGHT)
	assert_str(home.hud.message_text()).contains(words)
	home.player.motor.place(INSIDE)
	assert_str(Steps.walk_until_travel(home, Vector2.DOWN)).is_equal(FARM)
	assert_dict(GameState.player).is_equal({"area": "homestead", "entry": "farmhouse_door"})
	var farm: AreaController = _load(FARM)
	assert_that(farm.player.motor.cell).is_equal(DOORSTEP)


func _on_sound(id: StringName) -> void:
	_heard.append(id)


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area
