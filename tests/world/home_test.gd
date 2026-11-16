extends GdUnitTestSuite
## Home and sleep (P2b): the thatched cottage has a door and a room inside; sleeping in the bed
## starts the next day rested and saves; and staying up until the day runs out wakes the hero
## by his bed.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const VILLAGE: String = "res://world/areas/village/village.tscn"
const HOME: String = "res://world/areas/home/home.tscn"
const TEST_SLOT: int = 988
## The cottage's doorway, and the square of Hearthvale to count from.
const DOORWAY: Vector2i = Vector2i(8, 14)
const SQUARE: Vector2i = Vector2i(23, 20)
## The cells of Hearthvale the hero could walk to before the cottage had a door (P1c).
const REACHABLE_BEFORE: int = 1214

var _area: Node


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	SaveSystem.current_slot = TEST_SLOT


func after_test() -> void:
	if is_instance_valid(_area):
		_area.free()
	_area = null
	SaveSystem.erase_slot(TEST_SLOT)
	SaveSystem.current_slot = SaveSystem.GAME_SLOT
	GameState.clear()


func test_the_cottage_has_a_door_and_the_doorway_is_the_one_new_cell() -> void:
	var village: AreaController = _load(VILLAGE)
	var door: AreaExit = village.interactables.get_node(^"HomeDoor")
	assert_that(door.cell()).is_equal(DOORWAY)
	assert_that(door.target_area).is_equal(WorldPaths.HOME_AREA)
	assert_that((village.get_node(^"Height") as TileMapLayer).get_cell_atlas_coords(DOORWAY)).override_failure_message("a door in the front wall").is_equal(GreyboxTiles.coords("door"))
	assert_bool(village.grid.is_solid(DOORWAY)).is_false()
	for x: int in [6, 7, 9, 10, 11]:
		assert_bool(village.grid.is_solid(Vector2i(x, 14))).override_failure_message("the wall beside the door is still wall: %d" % x).is_true()
	for y: int in [11, 12, 13]:
		assert_bool(village.grid.is_solid(Vector2i(8, y))).override_failure_message("and the house behind it is still solid: row %d" % y).is_true()
	var out: Marker2D = village.entry_marker(&"home_door")
	assert_that(PlayerMotor.cell_of(out.position)).override_failure_message("he comes out in front of his door").is_equal(DOORWAY + Vector2i.DOWN)
	assert_that(AreaController.entry_facing(out)).is_equal(Vector2.DOWN)
	var reachable: Dictionary = _reachable(TerrainQuery.new(village.grid), SQUARE)
	assert_bool(reachable.has(DOORWAY)).is_true()
	assert_int(reachable.size()).override_failure_message("one more cell to walk to than before, the doorway").is_equal(REACHABLE_BEFORE + 1)


func test_home_is_one_room_with_a_bed_a_hearth_and_a_candle() -> void:
	var home: AreaController = _load(HOME)
	assert_that(home.ambience).is_equal(Ambience.INTERIOR)
	assert_int(home.player.camera_zoom()).is_equal(2)
	assert_str(WorldPaths.area_name(WorldPaths.HOME_AREA)).is_equal("Your cottage")
	assert_that(home.grid.size).override_failure_message("the size of the other houses").is_equal(Vector2i(11, 9))
	var layer: TileMapLayer = home.get_node(^"Height")
	var bed: Bed = home.interactables.get_node(^"Bed")
	assert_that(layer.get_cell_atlas_coords(bed.cell())).override_failure_message("the bed's node is on the bed").is_equal(GreyboxTiles.coords("bed"))
	assert_bool(home.grid.is_solid(bed.cell()) and home.terrain.is_occupied(bed.cell())).is_true()
	assert_int(bed.cell().x).override_failure_message("against the west wall, so the hero stands beside it and never hides it").is_equal(1)
	assert_that(layer.get_cell_atlas_coords(Vector2i(5, 1))).override_failure_message("a hearth to cook at (2d)").is_equal(GreyboxTiles.coords("hearth"))
	assert_int(home.tile_glows.size()).override_failure_message("the hearth and a candle give light").is_equal(2)
	var by_bed: Marker2D = home.entry_marker(WorldPaths.HOME_BED)
	assert_that(PlayerMotor.cell_of(by_bed.position)).override_failure_message("he wakes standing beside his bed").is_equal(bed.cell() + Vector2i.RIGHT)
	var door_cell: Vector2i = PlayerMotor.cell_of(home.entry_marker(&"door").position)
	var reachable: Dictionary = _reachable(TerrainQuery.new(home.grid), door_cell)
	for must: Vector2i in [bed.cell() + Vector2i.RIGHT, Vector2i(5, 2), Vector2i(5, 8), Vector2i(9, 3)]:
		assert_bool(reachable.has(must)).override_failure_message("%s can be walked to" % must).is_true()
	assert_that((home.interactables.get_node(^"Doormat") as AreaExit).target_entry).is_equal(&"home_door")


func test_the_bed_asks_and_not_yet_changes_nothing() -> void:
	var home: AreaController = _load(HOME)
	var bed: Bed = _stand_by_the_bed(home)
	assert_object(home.talkable_in_front()).is_same(bed)
	assert_str(bed.prompt()).is_equal("Go to bed")
	GameState.damage(3)
	GameState.set_time(float(GameState.day_clock().in_day("21:00")))
	var minute: float = GameState.minute
	assert_bool(home.interact()).is_true()
	assert_bool(home.is_talking()).is_true()
	assert_str(home.hud.dialogue.shown_text()).contains("Sleep until morning?")
	assert_int(home.hud.dialogue.shown_options().size()).is_equal(2)
	home.hud.dialogue.move_cursor(1)
	home.hud.dialogue.confirm()
	assert_bool(home.is_talking()).is_false()
	assert_int(GameState.day).is_equal(1)
	assert_float(GameState.minute).is_equal(minute)
	assert_int(GameState.health).override_failure_message("no rest, no hearts").is_equal(GameState.max_health() - 3)
	assert_bool(SaveSystem.has_slot(TEST_SLOT)).override_failure_message("and nothing saved").is_false()


func test_sleeping_starts_the_next_day_rested_and_saves() -> void:
	var home: AreaController = _load(HOME)
	var bed: Bed = _stand_by_the_bed(home)
	GameState.damage(3)
	GameState.energy = 20.0
	GameState.add_item(&"coin", 7)
	GameState.set_time(float(GameState.day_clock().in_day("21:00")))
	assert_bool(home.interact()).is_true()
	home.hud.dialogue.confirm()
	assert_bool(home.is_talking()).override_failure_message("the bed has no more to say").is_false()
	assert_int(GameState.day).is_equal(2)
	assert_float(GameState.minute).override_failure_message("06:00").is_equal(float(GameState.day_clock().starts))
	assert_int(GameState.health).override_failure_message("full hearts").is_equal(GameState.max_health())
	assert_float(GameState.energy).override_failure_message("full energy").is_equal(GameState.max_energy())
	assert_str(home.hud.message_text()).is_equal(AreaController.SLEPT_WORDS)
	assert_bool(home.player.controls_enabled).is_true()
	home._update_hud()
	assert_str(home.hud.shown_lines()[0]).is_equal("Day 2  06:00")
	# The morning is saved: loading it puts him by his bed on the second day.
	assert_bool(SaveSystem.has_slot(TEST_SLOT)).is_true()
	GameState.clear()
	assert_int(SaveSystem.load_from_slot(TEST_SLOT)).is_equal(OK)
	assert_int(GameState.day).is_equal(2)
	assert_int(GameState.item_count(&"coin")).is_equal(7)
	assert_dict(GameState.player).is_equal({"area": "home", "cell": [bed.cell().x + 1, bed.cell().y]})
	# He can sleep at any hour.
	GameState.set_time(float(GameState.day_clock().in_day("07:00")))
	assert_bool(home.interact()).is_true()
	home.hud.dialogue.confirm()
	assert_int(GameState.day).is_equal(3)


func test_staying_up_until_two_wakes_him_by_his_bed_the_next_day() -> void:
	var village: AreaController = _load(VILLAGE)
	var travelled: Array[String] = []
	village.travel = func(path: String) -> void: travelled.append(path)
	var clock: DayClock = GameState.day_clock()
	GameState.damage(2)
	var hearts: int = GameState.health
	GameState.add_item(&"coin", 12)
	GameState.set_time(float(clock.ends) - 1.0)
	village._process(clock.seconds_per_hour / 60.0 * 0.5)
	assert_array(travelled).override_failure_message("not yet").is_empty()
	village._process(clock.seconds_per_hour / 60.0)
	assert_array(travelled).override_failure_message("02:00: home").is_equal([WorldPaths.scene_for(WorldPaths.HOME_AREA)])
	assert_dict(GameState.player).is_equal({"area": "home", "entry": "bed"})
	assert_int(GameState.day).is_equal(2)
	assert_float(GameState.minute).is_equal(float(clock.starts))
	assert_int(GameState.health).override_failure_message("his hearts are as they were").is_equal(hearts)
	assert_int(GameState.item_count(&"coin")).override_failure_message("a tenth of his twelve coins is gone (P2c; tests/world/energy_test.gd)").is_equal(11)
	assert_bool(SaveSystem.has_slot(TEST_SLOT)).override_failure_message("the new day is saved").is_true()
	assert_str(GameState.arrival_notice).is_equal(AreaController.WOKE_LATE_WORDS + AreaController.COINS_LOST_WORDS % 1)
	village._process(1.0)
	assert_int(travelled.size()).override_failure_message("once").is_equal(1)
	# He arrives by his bed, and is told why, once.
	var home: AreaController = _load(HOME)
	var bed: Bed = home.interactables.get_node(^"Bed")
	assert_that(home.player.motor.cell).is_equal(bed.cell() + Vector2i.RIGHT)
	assert_that(home.player.facing_direction()).is_equal(Vector2i.DOWN)
	assert_str(home.hud.message_text()).contains(AreaController.WOKE_LATE_WORDS)
	assert_str(GameState.arrival_notice).override_failure_message("said, and gone").is_equal("")
	# Carrying on from that save puts him there too.
	GameState.clear()
	assert_int(SaveSystem.load_from_slot(TEST_SLOT)).is_equal(OK)
	assert_dict(GameState.player).is_equal({"area": "home", "entry": "bed"})
	assert_int(GameState.day).is_equal(2)
	assert_str(GameState.arrival_notice).override_failure_message("the words are not part of a save").is_equal("")


## Puts the hero beside the bed, facing it.
func _stand_by_the_bed(home: AreaController) -> Bed:
	var bed: Bed = home.interactables.get_node(^"Bed")
	home.player.motor.place(bed.cell() + Vector2i.RIGHT)
	home.player.face(Vector2.LEFT)
	return bed


func _reachable(query: TerrainQuery, start: Vector2i) -> Dictionary:
	var seen: Dictionary = {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + step
			if not seen.has(next) and query.check_move(cell, next).is_allowed():
				seen[next] = true
				queue.append(next)
	return seen


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area
