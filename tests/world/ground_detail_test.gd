extends GdUnitTestSuite
## Ground details in the areas (the warm-ground plan, step 3): outdoors, in the quarry and in
## the dungeons, none in a house or a farm building's room; drawn just above the Height layer;
## never on or just above a cell that holds something, nor beside other ground. On the hero's land they follow the homestead:
## a detail goes from a cell a fence is set on and comes back when it is taken up, comes where
## debris is cleared, and isn't drawn under something lying to be picked up or under the
## build ghost.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const AREAS: String = "res://world/areas/%s/%s.tscn"
const TEST_SLOT: int = 952
const START: Vector2i = Vector2i(30, 13)

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


func test_outdoors_the_quarry_and_dungeons_have_details_and_houses_and_rooms_none() -> void:
	for id: String in ["village", "old_wood", "willowmere", "homestead", "quarry", "quarry_1", "ruin_cellar", "keep"]:
		var area: AreaController = _load(id)
		assert_object(area.ground_detail).override_failure_message("%s has details" % id).is_not_null()
		assert_int(area.ground_detail.shown_count()).override_failure_message("%s shows some" % id).is_greater(10)
		# Just above the Height layer: under the relief, the water, the shading and everyone.
		assert_int(area.ground_detail.get_index()).override_failure_message(id).is_equal(area.height_layer.get_index() + 1)
	for id: String in ["home", "weaver_house", "elder_house", "shop", "coop", "barn", "shed"]:
		var area: AreaController = _load(id)
		assert_object(area.ground_detail).override_failure_message("%s has none" % id).is_null()


func test_no_detail_is_on_or_above_anything_that_holds_a_cell_or_beside_other_ground() -> void:
	for id: String in ["village", "homestead", "willowmere", "quarry_1", "ruin_cellar"]:
		var area: AreaController = _load(id)
		var decor: TileMapLayer = area.get_node_or_null(^"Decor") as TileMapLayer
		var things: Dictionary = {}
		for child: Node in area.interactables.get_children():
			if child is Node2D and not (child is Enemy or child is Critter or child is Animal):
				things[GroundDetail.cell_of(child as Node2D)] = child.name
		for cell: Vector2i in area.ground_detail.picks:
			var tile: Vector2i = area.height_layer.get_cell_atlas_coords(cell)
			assert_str(String(GroundDetails.ground_of(tile))).override_failure_message("%s %s: open ground" % [id, cell]).is_not_empty()
			# Nothing in it or just below it (what stands there may rise over it).
			for at: Vector2i in [cell, cell + Vector2i.DOWN]:
				assert_bool(decor != null and decor.get_cell_source_id(at) != -1).override_failure_message("%s %s: decor at %s" % [id, cell, at]).is_false()
				assert_bool(things.has(at)).override_failure_message("%s %s: %s at %s" % [id, cell, things.get(at, ""), at]).is_false()
				assert_bool(area.plot != null and area.plot.covers(at)).override_failure_message("%s %s: the plot" % [id, cell]).is_false()
			# The same ground all round (or its solid twin under a prop).
			for side: Vector2i in GroundDetails.SIDES:
				var next: Vector2i = area.height_layer.get_cell_atlas_coords(cell + side)
				assert_that(GroundDetails.look_of(next)).override_failure_message("%s %s: the same ground at %s" % [id, cell, cell + side]).is_equal(tile)


func test_about_one_open_grass_cell_in_four_in_the_village() -> void:
	var village: AreaController = _load("village")
	var tiles: Dictionary = _tiles(village)
	var held: Dictionary = GroundDetail.held_cells(village)
	var open: int = 0
	var detailed: int = 0
	for cell: Vector2i in tiles:
		if GroundDetails.ground_of(tiles[cell]) == GroundDetails.GRASS and GroundDetails.is_clear(cell, tiles, held):
			open += 1
			detailed += 1 if village.ground_detail.picks.has(cell) else 0
	assert_int(open).is_greater(200)
	assert_float(detailed / float(open)).override_failure_message("%d of %d" % [detailed, open]).is_between(0.18, 0.34)


func test_a_fence_set_down_takes_the_detail_away_and_taken_up_brings_it_back() -> void:
	var farm: AreaController = _farm()
	var cell: Vector2i = _detail_in(farm, Rect2i(20, 2, 18, 22))
	var neighbour: Vector2i = _detailed_neighbour_of(farm, cell)
	var was: StringName = farm.ground_detail.shown_at(cell)
	GameState.add_item(&"fence", 1)
	assert_bool(GameState.set_down(&"homestead", cell, &"fence")).is_true()
	await await_idle_frame()
	assert_str(String(farm.ground_detail.shown_at(cell))).override_failure_message("under the fence").is_empty()
	assert_bool(farm.ground_detail.picks.has(cell)).is_false()
	if neighbour != Vector2i(-1, -1):
		assert_str(String(farm.ground_detail.shown_at(neighbour))).override_failure_message("beside the fence").is_empty()
	assert_str(String(GameState.take_up(&"homestead", cell, Placement.STANDING))).is_equal("fence")
	await await_idle_frame()
	assert_str(String(farm.ground_detail.shown_at(cell))).override_failure_message("back when it is taken up").is_equal(String(was))


func test_a_path_laid_and_a_building_set_down_take_details_away_too() -> void:
	var farm: AreaController = _farm()
	var cell: Vector2i = _detail_in(farm, Rect2i(20, 2, 18, 22))
	GameState.add_item(&"dirt_path", 1)
	assert_bool(GameState.set_down(&"homestead", cell, &"dirt_path")).is_true()
	await await_idle_frame()
	assert_str(String(farm.ground_detail.shown_at(cell))).override_failure_message("under a path").is_empty()
	GameState.take_up(&"homestead", cell, Placement.LYING)
	await await_idle_frame()
	assert_str(String(farm.ground_detail.shown_at(cell))).is_not_empty()
	# A building's cells are held (GameState.building_covering): none under it.
	for id: StringName in GameState.homestead().building_ids():
		for at: Vector2i in Buildings.cells_of(DataRegistry.get_building(id), GameState.homestead().building_at(id)):
			assert_bool(farm.ground_detail.picks.has(at)).is_false()


func test_a_detail_comes_where_debris_is_cleared_for_good() -> void:
	var farm: AreaController = _farm()
	var tiles: Dictionary = _tiles(farm)
	var held: Dictionary = GroundDetail.held_cells(farm)
	var found: Vector2i = Vector2i(-1, -1)
	var expected: StringName = &""
	var decor: TileMapLayer = farm.get_node(^"Decor") as TileMapLayer
	for thing: Node2D in farm.debris():
		var cell: Vector2i = thing.call(&"cell")
		# Some stand on a tuft of the map's decor, which stays when they are gone, and some on
		# the plot, which never has details.
		if decor.get_cell_source_id(cell) != -1 or farm.plot.covers(cell):
			continue
		var without: Dictionary = held.duplicate()
		without.erase(cell)
		var detail: StringName = farm.ground_detail.rules.detail_at(cell, tiles, without)
		if detail != &"":
			found = cell
			expected = detail
			break
	assert_that(found).override_failure_message("some debris stands alone on grass").is_not_equal(Vector2i(-1, -1))
	assert_str(String(farm.ground_detail.shown_at(found))).override_failure_message("none while it stands").is_empty()
	assert_bool(GameState.clear_debris(&"homestead", found)).is_true()
	await await_idle_frame()
	assert_str(String(farm.ground_detail.shown_at(found))).is_equal(String(expected))


func test_nothing_lying_to_be_picked_up_or_the_build_ghost_shows_a_detail_under_it() -> void:
	var farm: AreaController = _farm()
	await await_idle_frame()
	var cell: Vector2i = _detail_in(farm, farm.build.view_cells())
	var drop: ItemDrop = ItemDrop.new()
	drop.item_id = &"stone"
	drop.position = Vector2(cell * GreyboxTiles.TILE_SIZE)
	farm.interactables.add_child(drop)
	await await_idle_frame()
	assert_str(String(farm.ground_detail.shown_at(cell))).override_failure_message("under a drop").is_empty()
	assert_bool(farm.ground_detail.picks.has(cell)).override_failure_message("it is there still").is_true()
	drop.queue_free()
	await await_idle_frame()
	await await_idle_frame()
	assert_str(String(farm.ground_detail.shown_at(cell))).override_failure_message("back once it is gone").is_not_empty()
	# The ghost: hidden where it points, back where it leaves and once the mode is closed.
	assert_bool(farm.open_build()).is_true()
	farm.build.point_at(cell)
	assert_that(farm.build.cell).is_equal(cell)
	assert_str(String(farm.ground_detail.shown_at(cell))).override_failure_message("under the ghost").is_empty()
	farm.build.point_at(cell + Vector2i(3, 0))
	assert_str(String(farm.ground_detail.shown_at(cell))).is_not_empty()
	farm.build.point_at(cell)
	farm.build.close()
	assert_str(String(farm.ground_detail.shown_at(cell))).override_failure_message("back once the mode is closed").is_not_empty()


func test_the_plot_never_has_details_and_tilling_it_changes_nothing_else() -> void:
	var farm: AreaController = _farm()
	var before: Dictionary = farm.ground_detail.picks.duplicate()
	for cell: Vector2i in farm.plot.cells():
		assert_bool(before.has(cell)).is_false()
	GameState.till_soil(Vector2i(0, 0))
	await await_idle_frame()
	assert_dict(farm.ground_detail.picks).is_equal(before)


## The homestead with the hero in the yard.
func _farm() -> AreaController:
	GameState.update_player(&"homestead", START)
	return _load("homestead")


func _load(id: String) -> AreaController:
	_area = Steps.load_area(AREAS % [id, id], _area)
	return _area as AreaController


func _tiles(area: AreaController) -> Dictionary:
	var out: Dictionary = {}
	for cell: Vector2i in area.height_layer.get_used_cells():
		out[cell] = area.height_layer.get_cell_atlas_coords(cell)
	return out


## A cell of `rect` on the farm that shows a detail (the first, row by row).
func _detail_in(farm: AreaController, rect: Rect2i) -> Vector2i:
	for y: int in range(rect.position.y, rect.end.y):
		for x: int in range(rect.position.x, rect.end.x):
			if farm.ground_detail.shown_at(Vector2i(x, y)) != &"":
				return Vector2i(x, y)
	assert_bool(false).override_failure_message("a detail in %s" % rect).is_true()
	return Vector2i(-1, -1)


func _detailed_neighbour_of(farm: AreaController, cell: Vector2i) -> Vector2i:
	for side: Vector2i in GroundDetails.SIDES:
		if farm.ground_detail.shown_at(cell + side) != &"":
			return cell + side
	return Vector2i(-1, -1)
