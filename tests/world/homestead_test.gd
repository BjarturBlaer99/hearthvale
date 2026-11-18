extends GdUnitTestSuite
## The Homestead's map (2026-11-17, phase 1, step 1a of docs/progress/homestead-plan.md): the
## hero's farm west of Hearthvale, reached by the lane's west end. The way from the edge to
## the farmhouse door is road and twelve cells; the farmhouse, the pond and the old trees are
## where the plan drew them; no walk on the land is anywhere near twenty seconds; nobody lives
## there and nothing grows to be gathered; and in the village four cells changed and no others.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const VILLAGE: String = "res://world/areas/village/village.tscn"
const FARM: String = "res://world/areas/homestead/homestead.tscn"
const TEST_SLOT: int = 952
const SIDES: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
## Hearthvale's square, where a new game begins, and the lane's rows.
const SQUARE: Vector2i = Vector2i(23, 20)
const LANE_ROWS: Array[int] = [16, 17]
## Where he comes in on the farm, the farmhouse's door and the cell before it.
const WAY_IN: Vector2i = Vector2i(38, 14)
const DOOR: Vector2i = Vector2i(28, 11)
const DOORSTEP: Vector2i = Vector2i(28, 12)
## The farmhouse (thatch over two floors), the pond, and the field.
const HOUSE: Rect2i = Rect2i(26, 8, 6, 4)
const POND: Rect2i = Rect2i(4, 21, 6, 4)
const FIELD: Rect2i = Rect2i(22, 17, 12, 6)
## The old trees left standing about the land.
const OLD_TREES: Array[Vector2i] = [
	Vector2i(35, 3), Vector2i(16, 4), Vector2i(34, 4), Vector2i(36, 4), Vector2i(34, 8), Vector2i(3, 9),
	Vector2i(23, 9), Vector2i(3, 18), Vector2i(36, 24), Vector2i(35, 25), Vector2i(12, 26),
]

var _area: Node


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	Quests.refresh()
	GameState.set_time(float(GameState.day_clock().in_day("12:00")))
	SaveSystem.erase_slot(TEST_SLOT)
	SaveSystem.current_slot = TEST_SLOT


func after_test() -> void:
	if is_instance_valid(_area):
		_area.free()
	_area = null
	SaveSystem.erase_slot(TEST_SLOT)
	SaveSystem.current_slot = SaveSystem.GAME_SLOT
	GameState.clear()


func test_the_farm_is_reached_by_the_lanes_west_end_and_back() -> void:
	# From the village square: along the lane, out through the west woods.
	var village: AreaController = _load(VILLAGE)
	assert_that(village.player.motor.cell).override_failure_message("a new game still begins in the square").is_equal(SQUARE)
	var road: AreaExit = village.interactables.get_node(^"WestRoad")
	assert_that(road.cell()).is_equal(Vector2i(0, 16))
	assert_that(road.size).override_failure_message("two cells tall, as the lane is").is_equal(Vector2i(1, 2))
	var before_road: Vector2i = road.cell() + Vector2i.RIGHT
	assert_bool(_reachable(village, village.player.motor.cell).has(before_road)).override_failure_message("the way west can be walked to from the square").is_true()
	village.player.motor.place(before_road)
	assert_str(Steps.walk_until_travel(village, Vector2.LEFT)).is_equal(FARM)
	assert_dict(GameState.player).is_equal({"area": "homestead", "entry": "east_road"})
	var farm: AreaController = _load(FARM)
	assert_that(farm.area_id).is_equal(&"homestead")
	assert_str(farm.area_name).is_equal("Your farm")
	assert_that(farm.player.motor.cell).is_equal(WAY_IN)
	assert_that(farm.player.facing_direction()).override_failure_message("he comes in facing his land").is_equal(Vector2i.LEFT)
	assert_that(farm.ambience).is_equal(Ambience.OUTDOOR)
	# And back the way he came, by either row of the road.
	assert_str(Steps.walk_until_travel(farm, Vector2.RIGHT)).is_equal(VILLAGE)
	assert_dict(GameState.player).is_equal({"area": "village", "entry": "west_road"})
	village = _load(VILLAGE)
	assert_that(village.player.motor.cell).is_equal(before_road)
	assert_that(village.player.facing_direction()).is_equal(Vector2i.RIGHT)
	farm = _load(FARM)
	farm.player.motor.place(WAY_IN + Vector2i.DOWN)
	assert_str(Steps.walk_until_travel(farm, Vector2.RIGHT)).override_failure_message("the lower row leads out too").is_equal(VILLAGE)


func test_four_cells_of_the_village_changed_and_no_others() -> void:
	var village: AreaController = _load(VILLAGE)
	var layer: TileMapLayer = village.get_node(^"Height")
	# The west tree line is solid from top to bottom but for the lane's two rows, and the nook
	# by the field that was always there.
	var open: Array[Vector2i] = []
	for y: int in range(8, 34):
		for x: int in 2:
			if not village.grid.is_solid(Vector2i(x, y)):
				open.append(Vector2i(x, y))
	assert_array(open).is_equal([Vector2i(0, 16), Vector2i(1, 16), Vector2i(0, 17), Vector2i(1, 17), Vector2i(0, 30), Vector2i(1, 30)])
	# The four new cells are lane, level with the lane, and the lane runs unbroken from the
	# edge to where it always began.
	var road: AreaExit = village.interactables.get_node(^"WestRoad")
	for y: int in LANE_ROWS:
		assert_bool(road.covers(Vector2i(0, y))).override_failure_message("(0, %d) is the way out" % y).is_true()
		assert_bool(road.covers(Vector2i(1, y))).override_failure_message("and (1, %d) is not: he arrives there" % y).is_false()
		for x: int in range(0, 38):
			assert_that(layer.get_cell_atlas_coords(Vector2i(x, y))).override_failure_message("the lane at (%d, %d)" % [x, y]).is_equal(GreyboxTiles.coords("path"))
			assert_int(village.grid.height_at(Vector2i(x, y))).is_equal(0)
	assert_that(PlayerMotor.cell_of(village.entry_marker(&"west_road").position)).is_equal(Vector2i(1, 16))
	# Nothing else: every other cell is as solid or as open as it was (the count of cells that
	# can be walked to from the square is the old count and four; tests/world/home_test.gd and
	# nature_test.gd hold the number), and the houses, the well and the pond stand where they did.
	for solid: Vector2i in [Vector2i(8, 12), Vector2i(17, 14), Vector2i(24, 3), Vector2i(18, 19), Vector2i(30, 27), Vector2i(0, 15), Vector2i(1, 18), Vector2i(0, 20), Vector2i(2, 19)]:
		assert_bool(village.grid.is_solid(solid)).override_failure_message("%s is solid" % solid).is_true()
	for cottage_cell: Vector2i in [Vector2i(6, 11), Vector2i(11, 13), Vector2i(7, 14), Vector2i(9, 14)]:
		assert_bool(village.grid.is_solid(cottage_cell)).override_failure_message("the old cottage still stands: %s" % cottage_cell).is_true()
	# No monsters or new people came with the road.
	assert_int(village.enemies().size()).is_equal(0)
	var villagers: Array = village.talkables().filter(func(talker: Talkable) -> bool: return talker is Villager)
	assert_int(villagers.size()).override_failure_message("Farmer Oda, Pip and Guard Rolf, as before").is_equal(3)


func test_the_way_from_the_edge_to_the_door_is_road_and_twelve_cells() -> void:
	var farm: AreaController = _load(FARM)
	var layer: TileMapLayer = farm.get_node(^"Height")
	# Along the road and up the path, never leaving it.
	var on_road: Callable = func(cell: Vector2i) -> bool: return layer.get_cell_atlas_coords(cell) == GreyboxTiles.coords("path")
	var steps: Dictionary = _steps_from(farm, WAY_IN, on_road)
	assert_bool(steps.has(DOORSTEP)).override_failure_message("the road leads to the doorstep").is_true()
	assert_int(int(steps.get(DOORSTEP, -1))).override_failure_message("twelve cells from where he comes in to his doorstep").is_equal(12)
	# By any way at all it is no shorter: the road is the straight way.
	assert_int(int(_steps_from(farm, WAY_IN, func(_cell: Vector2i) -> bool: return true)[DOORSTEP])).is_equal(12)
	# The door is in the front wall above the doorstep, and leads home.
	assert_that(layer.get_cell_atlas_coords(DOOR)).is_equal(GreyboxTiles.coords("door"))
	var door: AreaExit = farm.interactables.get_node(^"FarmhouseDoor")
	assert_that(door.cell()).is_equal(DOOR)
	assert_that(door.target_area).is_equal(WorldPaths.HOME_AREA)
	assert_that(door.target_entry).is_equal(&"door")
	assert_that(door.hours).override_failure_message("his own door is never shut").is_equal(&"")
	# The road: two rows from the path to the edge, and the path two cells up to the door.
	var road: int = 0
	for y: int in farm.grid.size.y:
		for x: int in farm.grid.size.x:
			if on_road.call(Vector2i(x, y)):
				road += 1
				assert_bool(farm.grid.is_solid(Vector2i(x, y))).is_false()
				assert_int(farm.grid.height_at(Vector2i(x, y))).override_failure_message("the land is level: no heights were made").is_equal(0)
	assert_int(road).override_failure_message("eighteen cells by two of road, two of path, and four through the woods").is_equal(42)
	# Walked at his own speed it is under three seconds, as the plan reckoned (2.7 s).
	assert_float(12.0 * GridBody.TILE / PlayerMotor.WALK_SPEED).is_equal_approx(2.67, 0.01)


func test_no_walk_on_the_farm_is_near_twenty_seconds() -> void:
	var farm: AreaController = _load(FARM)
	var steps: Dictionary = _steps_from(farm, WAY_IN, func(_cell: Vector2i) -> bool: return true)
	var farthest: int = 0
	for cell: Vector2i in steps:
		farthest = maxi(farthest, int(steps[cell]))
	print("  homestead: %d cells can be walked to; the farthest is %d cells from the way in" % [steps.size(), farthest])
	assert_float(float(farthest) * GridBody.TILE / PlayerMotor.WALK_SPEED).override_failure_message("the far corner of the land, walking").is_less(14.0)
	# From the village's square to his door, a new game's first walk: under ten seconds.
	var village: AreaController = _load(VILLAGE)
	var lane: Dictionary = _steps_from(village, SQUARE, func(_cell: Vector2i) -> bool: return true)
	var to_door: int = int(lane[Vector2i(1, 16)]) + 1 + 12
	assert_float(float(to_door) * GridBody.TILE / PlayerMotor.WALK_SPEED).override_failure_message("the square to the farmhouse door: %d cells" % to_door).is_less(10.0)


func test_the_land_is_as_the_plan_drew_it() -> void:
	var farm: AreaController = _load(FARM)
	var layer: TileMapLayer = farm.get_node(^"Height")
	assert_that(farm.grid.size).override_failure_message("the size of the North Fields and Willowmere: one screen wide").is_equal(Vector2i(40, 30))
	# Woods all round, two deep, but for the way out.
	var way_out: AreaExit = farm.interactables.get_node(^"EastRoad")
	assert_that(way_out.cell()).is_equal(Vector2i(39, 14))
	assert_that(way_out.size).is_equal(Vector2i(1, 2))
	for y: int in farm.grid.size.y:
		for x: int in farm.grid.size.x:
			var cell: Vector2i = Vector2i(x, y)
			if Rect2i(2, 2, 36, 26).has_point(cell):
				continue
			var is_way: bool = Rect2i(38, 14, 2, 2).has_point(cell)
			assert_bool(farm.grid.is_solid(cell)).override_failure_message("the edge at %s" % cell).is_equal(not is_way)
	# The farmhouse: thatch, a half-timbered floor, a ground floor, solid but for its door.
	for x: int in HOUSE.size.x:
		for y: int in HOUSE.size.y:
			var cell: Vector2i = HOUSE.position + Vector2i(x, y)
			assert_bool(farm.grid.is_solid(cell)).override_failure_message("the farmhouse at %s" % cell).is_equal(cell != DOOR)
	assert_that(layer.get_cell_atlas_coords(HOUSE.position)).override_failure_message("thatched, with a gable end").is_equal(GreyboxTiles.coords("roof_thatch_top_l"))
	assert_that(layer.get_cell_atlas_coords(HOUSE.position + Vector2i(1, 3))).override_failure_message("a window in its front wall").is_equal(GreyboxTiles.coords("wall_window"))
	assert_object(farm.windows).override_failure_message("its windows are lit with the lamps").is_not_null()
	assert_bool(farm.scenery.ridges.has(HOUSE.position + Vector2i(2, 0))).override_failure_message("its roof has a ridge").is_true()
	# The pond in the south-west corner.
	for x: int in POND.size.x:
		for y: int in POND.size.y:
			assert_that(layer.get_cell_atlas_coords(POND.position + Vector2i(x, y))).is_equal(GreyboxTiles.coords("water"))
	assert_object(farm.water).override_failure_message("its water moves, as all water does").is_not_null()
	# The old trees: each blocks its own cell and stands tall, and none hides the door.
	for cell: Vector2i in OLD_TREES:
		assert_bool(farm.grid.is_solid(cell)).override_failure_message("a tree at %s" % cell).is_true()
		assert_bool(farm.scenery.by_cell.has(cell)).override_failure_message("standing tall at %s" % cell).is_true()
		assert_bool(Scenery.hides(Scenery.foot_of(cell), GridBody.cell_center(DOORSTEP))).override_failure_message("%s doesn't hide the doorstep" % cell).is_false()
	var inner_trees: int = 0
	for cell: Vector2i in farm.scenery.by_cell:
		if Rect2i(2, 2, 36, 26).has_point(cell):
			inner_trees += 1
	assert_int(inner_trees).is_equal(OLD_TREES.size())
	# The field lies below the road, clear of the house, the pond and the trees.
	assert_that(Rect2i(farm.plot.origin(), farm.plot.plot_size())).is_equal(FIELD)
	assert_bool(FIELD.intersects(HOUSE) or FIELD.intersects(POND)).is_false()
	# Nobody lives here, nothing hunts here and nothing grows to be gathered (the plan's D7).
	assert_int(farm.enemies().size()).is_equal(0)
	for child: Node in farm.interactables.get_children():
		assert_bool(child is Villager or child is ForageSpot or child is Enemy or child is Critter).override_failure_message("%s has no place on the farm" % child.name).is_false()
	# He can stand everywhere the plan left open: the land is one piece.
	var reachable: Dictionary = _reachable(farm, WAY_IN)
	for must: Vector2i in [DOORSTEP, Vector2i(22, 16), Vector2i(3, 22), Vector2i(2, 2), Vector2i(37, 27), Vector2i(2, 27), Vector2i(37, 2), Vector2i(24, 18)]:
		assert_bool(reachable.has(must)).override_failure_message("%s can be walked to" % must).is_true()


func test_the_farm_keeps_its_place_through_a_save() -> void:
	GameState.update_player(&"homestead", Vector2i(24, 16))
	var farm: AreaController = _load(FARM)
	assert_that(farm.player.motor.cell).is_equal(Vector2i(24, 16))
	assert_int(farm.save_here()).is_equal(OK)
	assert_dict(SaveSystem.summary()).is_equal({"area": "homestead", "play_time": 0.0, "hearts_max": 3, "finished": false})
	assert_str(WorldPaths.area_name(&"homestead")).override_failure_message("the title names where a save was made").is_equal("Your farm")
	GameState.clear()
	assert_int(SaveSystem.load_game()).is_equal(OK)
	farm = _load(FARM)
	assert_that(farm.player.motor.cell).override_failure_message("where he stood").is_equal(Vector2i(24, 16))


## How many steps it is from `start` to every cell of the map that can be walked to, stepping
## only onto cells `allowed` says yes to. It is the map's own shape that is walked: what stands
## on it (people, and since step 1b the overgrowth) is left out.
func _steps_from(area: AreaController, start: Vector2i, allowed: Callable) -> Dictionary:
	var ground: TerrainQuery = TerrainQuery.new(area.grid)
	var steps: Dictionary = {start: 0}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		for side: Vector2i in SIDES:
			var next: Vector2i = cell + side
			if not steps.has(next) and allowed.call(next) and ground.check_move(cell, next).is_allowed():
				steps[next] = int(steps[cell]) + 1
				queue.append(next)
	return steps


func _reachable(area: AreaController, start: Vector2i) -> Dictionary:
	return _steps_from(area, start, func(_cell: Vector2i) -> bool: return true)


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area
