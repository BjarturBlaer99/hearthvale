extends GdUnitTestSuite
## Ground and nature (P1c). Trees stand up from the ground as tall pictures, each still blocking
## exactly its own cell, and a crown fades while the hero, an enemy or a pickup stands behind
## it, so nothing is hidden. Hearthvale has cherry trees: eight in new cells the user approved,
## and nothing else about where the hero can go has changed. Petals lie only on open ground and
## water; water has a moving surface and mirrors the hero and the trees on its bank; the Old
## Wood has mist. Nothing else in the scenery moves (the user's request, 2026-11-13): grass,
## flowers, washing, trees, petals, mist and chimney smoke are still.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const VILLAGE: String = "res://world/areas/village/village.tscn"
const NORTH_FIELDS: String = "res://world/areas/north_fields/north_fields.tscn"
const OLD_WOOD: String = "res://world/areas/old_wood/old_wood.tscn"
const SOUTH_FIELD: String = "res://world/areas/south_field/south_field.tscn"
const ELDER_HOUSE: String = "res://world/areas/elder_house/elder_house.tscn"
const KEEP: String = "res://world/areas/keep/keep.tscn"
const FRAME: float = 1.0 / 60.0
## The eight new cherry trees in Hearthvale (docs/progress/P1c-plan.md): the only cells that
## became solid in P1.
const NEW_CHERRY_CELLS: Array[Vector2i] = [
	Vector2i(16, 4), Vector2i(31, 4), Vector2i(34, 25), Vector2i(27, 31),
	Vector2i(21, 10), Vector2i(26, 10), Vector2i(26, 22), Vector2i(21, 27),
]
## How many cells could be walked to from the village square before P1c.
const REACHABLE_BEFORE: int = 1222
const SQUARE: Vector2i = Vector2i(23, 20)

var _area: Node


func before_test() -> void:
	GameState.clear()
	GameState.new_game()


func after_test() -> void:
	if is_instance_valid(_area):
		_area.free()
	_area = null
	GameState.clear()


func test_every_tree_stands_up_and_still_blocks_exactly_its_own_cell() -> void:
	for path: String in [VILLAGE, OLD_WOOD, SOUTH_FIELD]:
		var area: AreaController = _load(path)
		assert_int(area.scenery.by_cell.size()).override_failure_message("%s has trees" % path).is_greater(0)
		var decor: TileMapLayer = area.get_node(^"Decor")
		for cell: Vector2i in decor.get_used_cells():
			assert_str(Scenery.kind_of_tile(decor.get_cell_atlas_coords(cell))).override_failure_message("%s: no tree tile is left lying flat at %s" % [path, cell]).is_empty()
		for cell: Vector2i in area.scenery.by_cell:
			assert_bool(area.grid.is_solid(cell)).override_failure_message("%s: the tree at %s blocks its cell" % [path, cell]).is_true()
			var tree: Sprite2D = area.scenery.by_cell[cell]
			assert_that(tree.position).override_failure_message("it stands in its own cell").is_equal(Scenery.foot_of(cell))
			assert_that(GridBody.cell_of(tree.position)).is_equal(cell)
			assert_bool(SceneryAtlas.KINDS.has(str(tree.get_meta(&"kind")))).is_true()
		assert_bool(area.scenery.y_sort_enabled).override_failure_message("sorted by depth with the hero").is_true()
	assert_int(_load(ELDER_HOUSE).scenery.by_cell.size()).override_failure_message("no trees indoors").is_equal(0)


func test_the_tall_pictures_fit_their_atlas_with_room_to_spare() -> void:
	var atlas: Texture2D = load(SceneryAtlas.TEXTURE_PATH)
	assert_that(Vector2i(atlas.get_size())).is_equal(Vector2i(SceneryAtlas.CELL.x * SceneryAtlas.KINDS.size(), SceneryAtlas.CELL.y))
	var image: Image = atlas.get_image()
	for kind: String in SceneryAtlas.KINDS:
		var region: Rect2i = Rect2i(SceneryAtlas.region(kind))
		assert_that(region.size).is_equal(SceneryAtlas.SIZE)
		var painted: int = 0
		for y: int in region.size.y:
			for x: int in region.size.x:
				if image.get_pixel(region.position.x + x, region.position.y + y).a > 0.0:
					painted += 1
		assert_int(painted).override_failure_message("'%s' is painted" % kind).is_greater(300)
		# Clear pixels to either side: a crown never shows its neighbour.
		for y: int in SceneryAtlas.CELL.y:
			for dx: int in [-2, -1, region.size.x, region.size.x + 1]:
				assert_float(image.get_pixel(region.position.x + dx, y).a).override_failure_message("'%s' has clear padding" % kind).is_equal(0.0)
	for tile: String in SceneryAtlas.FROM_DECOR:
		assert_bool(GreyboxTiles.is_prop(tile)).override_failure_message("'%s' is a tree prop of the tileset" % tile).is_true()
		assert_bool(SceneryAtlas.KINDS.has(SceneryAtlas.FROM_DECOR[tile])).is_true()
	assert_str(SceneryAtlas.variant("cherry", Vector2i(3, 9))).override_failure_message("the same cell, the same picture").is_equal(SceneryAtlas.variant("cherry", Vector2i(3, 9)))
	assert_str(SceneryAtlas.variant("pine", Vector2i(3, 9))).is_equal("pine")


func test_hearthvale_has_cherry_trees_in_the_eight_approved_cells_and_no_other_cell_changed() -> void:
	var village: AreaController = _load(VILLAGE)
	for cell: Vector2i in NEW_CHERRY_CELLS:
		assert_bool(village.grid.is_solid(cell)).override_failure_message("%s is blocked by its tree" % cell).is_true()
		assert_bool(village.scenery.by_cell.has(cell)).override_failure_message("a tree stands at %s" % cell).is_true()
		assert_bool(SceneryAtlas.is_cherry(str(village.scenery.by_cell[cell].get_meta(&"kind")))).override_failure_message("and it is a cherry").is_true()
	assert_int(village.scenery.cherry_feet().size()).override_failure_message("eight new, and two old clumps of four").is_equal(NEW_CHERRY_CELLS.size() + 8)
	# Each new tree stood on open ground that could be walked to: the hero can reach exactly that
	# many fewer cells, and everywhere else as before.
	var reachable: Dictionary = _reachable(TerrainQuery.new(village.grid), SQUARE)
	# (And one more since P2b: the doorway of the hero's cottage, tests/world/home_test.gd; two
	# since Willowmere: the way out through the east tree line, tests/world/willowmere_test.gd;
	# four since the Homestead: the lane's west end, tests/world/homestead_test.gd; and six fewer
	# since its phase 4: Farmer Oda's stall, tests/world/oda_stall_test.gd.)
	assert_int(reachable.size()).is_equal(REACHABLE_BEFORE - NEW_CHERRY_CELLS.size() + 1 + 2 + 4 - 6)
	for must: Vector2i in [Vector2i(10, 4), Vector2i(42, 20), Vector2i(23, 35), Vector2i(36, 1), Vector2i(16, 15), Vector2i(30, 15), Vector2i(8, 25), Vector2i(23, 6), Vector2i(0, 30)]:
		assert_bool(reachable.has(must)).override_failure_message("%s can still be walked to" % must).is_true()
	var fields: AreaController = _load(NORTH_FIELDS)
	assert_int(fields.scenery.cherry_feet().size()).override_failure_message("two clumps of four in the North Fields").is_equal(8)
	assert_int(_load(OLD_WOOD).scenery.cherry_feet().size()).override_failure_message("none in the Old Wood").is_equal(0)


func test_a_crown_hides_only_what_stands_behind_it() -> void:
	var foot: Vector2 = Scenery.foot_of(Vector2i(10, 10))
	assert_bool(Scenery.hides(foot, foot + Vector2(0, -18))).override_failure_message("the hero in the cell behind").is_true()
	assert_bool(Scenery.hides(foot, Vector2(10 * 16, 9 * 16))).override_failure_message("a pickup lying in the cell behind").is_true()
	assert_bool(Scenery.hides(foot, foot + Vector2(-16, -18))).override_failure_message("behind and one cell to the side").is_true()
	assert_bool(Scenery.hides(foot, foot + Vector2(0, 6))).override_failure_message("in front of the tree").is_false()
	assert_bool(Scenery.hides(foot, foot + Vector2(0, -60))).override_failure_message("well clear behind").is_false()
	assert_bool(Scenery.hides(foot, foot + Vector2(40, -18))).override_failure_message("well clear to the side").is_false()


func test_the_hero_is_never_hidden_behind_a_tree() -> void:
	var village: AreaController = _load(VILLAGE)
	var tree: Vector2i = Vector2i(26, 22)
	var behind: Vector2i = tree + Vector2i.UP
	assert_bool(village.grid.is_solid(behind)).override_failure_message("the cell behind the tree is open").is_false()
	assert_float(village.scenery.opacity_of(tree)).is_equal(1.0)
	village.player.motor.place(behind)
	village.player.sync_from_motor()
	for i: int in 30:
		village._process(FRAME)
	assert_float(village.scenery.opacity_of(tree)).override_failure_message("the crown fades to show the hero").is_equal_approx(Scenery.FADED, 0.01)
	assert_float(Scenery.FADED).override_failure_message("see-through enough to see him, not gone").is_between(0.25, 0.6)
	assert_bool(village.grid.is_solid(tree)).override_failure_message("and the tree still blocks").is_true()
	village.player.motor.place(tree + Vector2i.DOWN)
	village.player.sync_from_motor()
	for i: int in 30:
		village._process(FRAME)
	assert_float(village.scenery.opacity_of(tree)).override_failure_message("in front of it, the tree is solid again").is_equal(1.0)
	# Every open cell just behind a tree fades that tree: there is nowhere to stand unseen.
	for cell: Vector2i in village.scenery.by_cell:
		var spot: Vector2i = cell + Vector2i.UP
		if village.grid.in_bounds(spot) and not village.grid.is_solid(spot):
			var hiding: Array[Vector2i] = village.scenery.hiding(GridBody.cell_center(spot))
			assert_bool(hiding.has(cell)).override_failure_message("standing at %s fades the tree at %s" % [spot, cell]).is_true()


func test_crowns_fade_for_enemies_and_pickups_but_not_for_grass() -> void:
	var fields: AreaController = _load(SOUTH_FIELD)
	var points: Array[Vector2] = fields.standing_points()
	assert_that(points[0]).override_failure_message("the hero first").is_equal(fields.player.position)
	var enemies: int = 0
	var grass: int = 0
	for child: Node in fields.interactables.get_children():
		if child is Enemy:
			enemies += 1
			assert_bool(points.has((child as Node2D).position)).override_failure_message("an enemy is watched").is_true()
		elif child is Breakable:
			grass += 1
			assert_bool(points.has((child as Node2D).position)).override_failure_message("grass and pots are not: a tree behind them would never come back").is_false()
	assert_int(enemies).is_greater(0)
	assert_int(grass).is_greater(0)


func test_petals_lie_only_on_open_ground_and_water_and_always_in_the_same_places() -> void:
	var foot: Vector2 = Scenery.foot_of(Vector2i(20, 20))
	var once: Array[Vector2] = Petals.scatter(foot)
	assert_int(once.size()).is_equal(Petals.SETTLED)
	assert_array(Petals.scatter(foot)).override_failure_message("the same every time").is_equal(once)
	assert_array(Petals.scatter(Scenery.foot_of(Vector2i(21, 20)))).override_failure_message("each tree its own").is_not_equal(once)
	for spot: Vector2 in once:
		assert_bool(absf(spot.x - foot.x) <= Petals.SPREAD.x + 1.0 and absf(spot.y - foot.y) <= Petals.SPREAD.y + 1.0).override_failure_message("within reach of the tree").is_true()
	var village: AreaController = _load(VILLAGE)
	assert_int(village.petals.settled.size()).is_greater(40)
	var afloat: int = 0
	for petal: Array in village.petals.settled:
		var ground: String = village.ground_at(GridBody.cell_of(petal[0]))
		assert_bool(ground == "open" or ground == "water").override_failure_message("a petal at %s lies on '%s'" % [petal[0], ground]).is_true()
		if ground == "water":
			afloat += 1
	assert_int(afloat).override_failure_message("some float on the pond").is_greater(0)
	assert_int(village.scenery.cherry_feet().size()).is_greater(8)
	assert_int(village.petals.get_child_count()).override_failure_message("none are in the air").is_equal(0)
	assert_int(_load(OLD_WOOD).petals.settled.size()).override_failure_message("no cherry trees, no petals").is_equal(0)


func test_nothing_in_the_scenery_moves_but_the_water() -> void:
	var village: AreaController = _load(VILLAGE)
	var decor: TileMapLayer = village.get_node(^"Decor")
	# Grass, flowers and washing are plain tiles on the Decor layer: no layer of their own, no wind.
	var small: int = 0
	for kind: String in ["tuft", "flowers_red", "flowers_yellow", "flowers_blue", "laundry"]:
		assert_bool(GreyboxTiles.is_decor(kind)).override_failure_message("'%s' is a decoration: it never blocks" % kind).is_true()
		small += decor.get_used_cells_by_id(GreyboxTiles.SOURCE_ID, GreyboxTiles.coords(kind)).size()
	assert_int(small).override_failure_message("tufts, flowers and washing lie on Decor").is_greater(20)
	assert_object(decor.material).override_failure_message("no shader moves them").is_null()
	var layers: Array = []
	for child: Node in village.get_children():
		if child is TileMapLayer:
			layers.append(String(child.name))
	assert_array(layers).override_failure_message("no layer for the wind").contains_exactly(["Height", "Decor", "Spawns"])
	assert_bool(&"sway" in village or &"motes" in village).override_failure_message("no wind and no specks in the air").is_false()
	# Trees stand still, and no petal is in the air.
	assert_int(village.scenery.by_cell.size()).is_greater(50)
	for tree: Sprite2D in village.scenery.by_cell.values():
		assert_object(tree.material).override_failure_message("%s doesn't sway" % tree.name).is_null()
	assert_int(village.petals.get_child_count()).is_equal(0)
	assert_object(village.petals.material).is_null()
	# Chimney smoke is one still picture.
	var source: TileSetAtlasSource = decor.tile_set.get_source(GreyboxTiles.SOURCE_ID)
	assert_int(decor.get_used_cells_by_id(GreyboxTiles.SOURCE_ID, GreyboxTiles.coords("smoke")).size()).override_failure_message("the chimneys still smoke").is_equal(4)
	assert_int(source.get_tile_animation_frames_count(GreyboxTiles.coords("smoke"))).override_failure_message("the smoke stands still").is_equal(1)
	# The water is the one thing that moves: its tile plays its frames, and its surface keeps time.
	assert_int(source.get_tile_animation_frames_count(Vector2i(0, GreyboxTiles.ROW_WATER))).is_equal(GreyboxTiles.WATER_FRAMES)
	assert_str((village.water.material as ShaderMaterial).shader.code).override_failure_message("the water's surface moves").contains("TIME")
	# Mist lies still over the Old Wood, and its trees stand as still.
	var wood: AreaController = _load(OLD_WOOD)
	assert_str((wood.mist.material as ShaderMaterial).shader.code).override_failure_message("the mist doesn't drift").not_contains("TIME")
	for tree: Sprite2D in wood.scenery.by_cell.values():
		assert_object(tree.material).is_null()


func test_water_has_a_moving_surface_and_mirrors_the_hero_and_the_trees_on_its_bank() -> void:
	var village: AreaController = _load(VILLAGE)
	var pond: Array[Vector2i] = village.height_layer.get_used_cells_by_id(GreyboxTiles.SOURCE_ID, GreyboxTiles.coords("water"))
	assert_int(pond.size()).is_equal(24)
	assert_int(village.water.cells.size()).is_equal(pond.size())
	for cell: Vector2i in pond:
		assert_bool(village.water.bounds.has_point(GridBody.cell_center(cell))).override_failure_message("the surface covers %s" % cell).is_true()
		assert_str(village.ground_at(cell)).is_equal("water")
	# Over the water tiles and the ground's details (warm-ground plan, step 3), under the lily pads.
	assert_int(village.ground_detail.get_index()).is_equal(village.height_layer.get_index() + 1)
	assert_int(village.water.get_index()).override_failure_message("over the water tiles, under the lily pads").is_equal(village.height_layer.get_index() + 2)
	assert_int(village.reflections.get_index()).is_equal(village.water.get_index() + 1)
	village._process(FRAME)
	var mirror: Sprite2D = village.reflections.hero
	assert_bool(mirror.flip_v).override_failure_message("upside down").is_true()
	assert_that(mirror.region_rect).override_failure_message("the frame the hero shows").is_equal(village.player.shown_region())
	assert_that(mirror.position).override_failure_message("under their feet").is_equal(village.player.position.round())
	assert_bool(village.reflections.trees.has(Vector2i(34, 25))).override_failure_message("the cherry by the pond's corner is mirrored").is_true()
	assert_bool(village.reflections.trees.has(Vector2i(16, 4))).override_failure_message("the one by the chapel is nowhere near water").is_false()
	var wet: Dictionary = {Vector2i(5, 7): true}
	assert_bool(Reflections.near_water(Vector2i(5, 5), wet)).override_failure_message("water two cells south").is_true()
	assert_bool(Reflections.near_water(Vector2i(5, 8), wet)).override_failure_message("water to the north doesn't mirror").is_false()
	assert_bool(Reflections.near_water(Vector2i(5, 2), wet)).override_failure_message("too far").is_false()
	var house: AreaController = _load(ELDER_HOUSE)
	assert_object(house.water).override_failure_message("no water indoors").is_null()
	assert_object(house.reflections).is_null()


func test_the_old_wood_has_mist_and_nowhere_else() -> void:
	assert_object(_load(OLD_WOOD).mist).is_not_null()
	assert_float(Mist.THICKEST).override_failure_message("thin: enemies stay easy to see").is_less(0.3)
	assert_object(_load(VILLAGE).mist).is_null()
	assert_object(_load(KEEP).mist).is_null()
	assert_bool(Ambience.has_mist(&"old_wood")).is_true()
	assert_bool(Ambience.has_mist(&"crypt")).is_false()
	assert_str(Mist.CODE).override_failure_message("it lies still").not_contains("TIME")


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
