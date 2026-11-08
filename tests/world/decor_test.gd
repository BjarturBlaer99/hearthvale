extends GdUnitTestSuite
## The look of the world (the art pass): every area has a Decor layer above its Height layer,
## and it never changes the way. Decorations sit only on open ground (lily pads only on water)
## and never on anything the hero uses or arrives at; props (trees, rocks, fences, the well)
## stand only on solid ground; nothing on the Decor layer blocks. Houses get windows, ridges and
## eaves, and stay exactly as solid as before.

const AREAS: Array[StringName] = [&"village", &"elder_house", &"weaver_house", &"south_field", &"shop", &"ruin_cellar", &"cistern", &"keep", &"north_fields", &"old_wood"]


func test_every_area_has_a_decor_layer_just_above_its_height_layer() -> void:
	for area_id: StringName in AREAS:
		var scene: Node = _scene(area_id)
		var decor: TileMapLayer = scene.get_node_or_null(^"Decor")
		assert_object(decor).override_failure_message("%s has a Decor layer" % area_id).is_not_null()
		assert_int(decor.get_index()).is_equal(scene.get_node(^"Height").get_index() + 1)


func test_decorations_never_hide_the_way() -> void:
	var lily: Vector2i = GreyboxTiles.coords("lily")
	var water: Vector2i = GreyboxTiles.coords("water")
	var decorations: Dictionary = {}
	for area_id: StringName in AREAS:
		var scene: Node = _scene(area_id)
		var height: TileMapLayer = scene.get_node(^"Height")
		var decor: TileMapLayer = scene.get_node(^"Decor")
		var busy: Dictionary = _busy_cells(scene)
		for cell: Vector2i in decor.get_used_cells():
			var tile: Vector2i = decor.get_cell_atlas_coords(cell)
			var under: Vector2i = height.get_cell_atlas_coords(cell)
			var where: String = "%s %s" % [area_id, cell]
			match tile.y:
				GreyboxTiles.ROW_PROPS:
					assert_int(under.y).override_failure_message(where + ": props stand on solid ground").is_equal(GreyboxTiles.ROW_SOLID_GROUND)
				GreyboxTiles.ROW_DECOR:
					decorations[area_id] = int(decorations.get(area_id, 0)) + 1
					if tile == lily:
						assert_that(under).override_failure_message(where + ": lily pads float on water").is_equal(water)
					else:
						assert_int(under.y).override_failure_message(where + ": decorations sit on open ground").is_equal(GreyboxTiles.ROW_GROUND)
					assert_bool(busy.has(cell)).override_failure_message(where + ": nothing on what the hero uses or arrives at").is_false()
				_:
					fail(where + ": the Decor layer holds only decorations and props")
			var data: TileData = decor.get_cell_tile_data(cell)
			assert_bool(bool(data.get_custom_data(GreyboxTiles.DATA_SOLID))).override_failure_message(where + ": decor never blocks").is_false()
	assert_int(int(decorations.get(&"village", 0))).override_failure_message("the village is decorated").is_greater(60)
	assert_int(int(decorations.get(&"south_field", 0))).override_failure_message("the field is decorated").is_greater(60)


func test_houses_have_windows_ridges_and_eaves_and_stay_solid() -> void:
	var scene: Node = _scene(&"village")
	var height: TileMapLayer = scene.get_node(^"Height")
	var grid: HeightGrid = HeightGridBuilder.from_layer(height)
	# [cell, the tile it shows]
	var cases: Array = [
		[Vector2i(6, 11), "roof_top"], [Vector2i(6, 12), "roof"], [Vector2i(6, 13), "roof_eave"],
		[Vector2i(28, 11), "roof_blue_top"], [Vector2i(28, 13), "roof_blue_eave"],
		[Vector2i(7, 14), "wall_window"], [Vector2i(8, 14), "wall"], [Vector2i(10, 14), "wall_window"],
		[Vector2i(19, 5), "wall_window"], [Vector2i(16, 14), "door"],
	]
	for case: Array in cases:
		var cell: Vector2i = case[0]
		assert_that(height.get_cell_atlas_coords(cell)).override_failure_message("%s shows %s" % [cell, case[1]]).is_equal(GreyboxTiles.coords(case[1]))
		if case[1] != "door":
			assert_bool(grid.is_solid(cell)).override_failure_message("%s is solid" % cell).is_true()
			assert_int(grid.height_at(cell)).is_equal(3)


func test_the_well_is_four_quarters_on_solid_ground() -> void:
	var scene: Node = _scene(&"village")
	var height: TileMapLayer = scene.get_node(^"Height")
	var decor: TileMapLayer = scene.get_node(^"Decor")
	var grid: HeightGrid = HeightGridBuilder.from_layer(height)
	var quarters: Dictionary = {Vector2i(18, 19): "well_nw", Vector2i(19, 19): "well_ne", Vector2i(18, 20): "well_sw", Vector2i(19, 20): "well_se"}
	for cell: Vector2i in quarters:
		assert_that(decor.get_cell_atlas_coords(cell)).is_equal(GreyboxTiles.coords(quarters[cell]))
		assert_bool(grid.is_solid(cell)).override_failure_message("the well is solid").is_true()


func _scene(area_id: StringName) -> Node:
	return auto_free((load(WorldPaths.scene_for(area_id)) as PackedScene).instantiate())


## Cells the hero uses or arrives at: Interactables children (with their size), entry points
## and the spawn.
func _busy_cells(scene: Node) -> Dictionary:
	var cells: Dictionary = {}
	for child: Node in scene.get_node(^"Interactables").get_children():
		var at: Vector2i = PlayerMotor.cell_of((child as Node2D).position + Vector2(0.5, 0.5))
		var size: Variant = child.get(&"size")
		var span: Vector2i = size if typeof(size) == TYPE_VECTOR2I else Vector2i.ONE
		for y: int in span.y:
			for x: int in span.x:
				cells[at + Vector2i(x, y)] = true
	var entries: Node = scene.get_node_or_null(^"Entries")
	if entries != null:
		for marker: Node in entries.get_children():
			cells[PlayerMotor.cell_of((marker as Node2D).position)] = true
	cells[PlayerMotor.cell_of((scene.get_node(^"PlayerSpawn") as Node2D).position)] = true
	return cells
