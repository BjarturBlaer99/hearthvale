extends GdUnitTestSuite
## The look of the world (the art pass): every area has a Decor layer above its Height layer,
## and it never changes the way. Decorations sit only on open ground (lily pads only on water)
## and never on anything the hero uses or arrives at; props (trees, rocks, fences, the well)
## stand only on solid ground; nothing on the Decor layer blocks. Houses are two storeys under a
## roof with gable ends (thatch, clay tiles or slate), carry chimneys that smoke, and stay exactly
## as solid as before. Woods mix three kinds of tree and close into a canopy where they are thick.
## In the marsh (Willowmere) the open ground is its own mossy ground and the solid ground under a
## prop its own too; planks laid on the ground are a way to walk, so they may lie under an exit.

const AREAS: Array[StringName] = [&"village", &"elder_house", &"weaver_house", &"south_field", &"shop", &"ruin_cellar", &"cistern", &"keep", &"north_fields", &"old_wood", &"crypt", &"willowmere"]


func test_every_area_has_a_decor_layer_just_above_its_height_layer() -> void:
	for area_id: StringName in AREAS:
		var scene: Node = _scene(area_id)
		var decor: TileMapLayer = scene.get_node_or_null(^"Decor")
		assert_object(decor).override_failure_message("%s has a Decor layer" % area_id).is_not_null()
		assert_int(decor.get_index()).is_equal(scene.get_node(^"Height").get_index() + 1)


func test_decorations_never_hide_the_way() -> void:
	var lily: Vector2i = GreyboxTiles.coords("lily")
	var water: Vector2i = GreyboxTiles.coords("water")
	var marsh: Vector2i = GreyboxTiles.coords("marsh")
	var marsh_solid: Vector2i = GreyboxTiles.coords("marsh_solid")
	var decorations: Dictionary = {}
	for area_id: StringName in AREAS:
		var scene: Node = _scene(area_id)
		var height: TileMapLayer = scene.get_node(^"Height")
		var decor: TileMapLayer = scene.get_node(^"Decor")
		var grid: HeightGrid = HeightGridBuilder.from_layer(height)
		var busy: Dictionary = _busy_cells(scene)
		for cell: Vector2i in decor.get_used_cells():
			var tile: Vector2i = decor.get_cell_atlas_coords(cell)
			var under: Vector2i = height.get_cell_atlas_coords(cell)
			var where: String = "%s %s" % [area_id, cell]
			var kind: String = ""
			if tile.y == GreyboxTiles.ROW_PROPS_B:
				kind = GreyboxTiles.PROPS_B_KINDS[tile.x]
			elif tile.y == GreyboxTiles.ROW_PROPS_C:
				kind = GreyboxTiles.PROPS_C_KINDS[tile.x]
			if GreyboxTiles.PROP_DECOR_KINDS.has(kind):
				# A bucket or the washing line: decoration on open ground, walked under or past.
				assert_int(under.y).override_failure_message(where + ": %s sits on open ground" % kind).is_equal(GreyboxTiles.ROW_GROUND)
				assert_bool(busy.has(cell)).override_failure_message(where + ": nothing on what the hero uses or arrives at").is_false()
			elif kind != "":
				assert_int(under.y).override_failure_message(where + ": %s stands on solid ground" % kind).is_equal(GreyboxTiles.ROW_SOLID_GROUND)
			match tile.y:
				GreyboxTiles.ROW_PROPS_B, GreyboxTiles.ROW_PROPS_C:
					pass
				GreyboxTiles.ROW_PROPS, GreyboxTiles.ROW_TREES:
					assert_bool(under.y == GreyboxTiles.ROW_SOLID_GROUND or under == marsh_solid).override_failure_message(where + ": props stand on solid ground").is_true()
				GreyboxTiles.ROW_MARSH_DECOR:
					var marsh_kind: String = GreyboxTiles.MARSH_DECOR_KINDS[tile.x]
					if GreyboxTiles.MARSH_PROP_KINDS.has(marsh_kind):
						assert_that(under).override_failure_message(where + ": the marsh's props stand on its solid ground").is_equal(marsh_solid)
					elif marsh_kind == "ruin_hole":
						assert_that(under).override_failure_message(where + ": a hole is in the hut's roof").is_equal(GreyboxTiles.coords("ruin_top"))
					elif marsh_kind == "planks":
						# A way to walk: on open ground, and it may lead under an exit.
						assert_int(under.y).override_failure_message(where + ": planks lie on open ground").is_equal(GreyboxTiles.ROW_GROUND)
					else:
						decorations[area_id] = int(decorations.get(area_id, 0)) + 1
						assert_that(under).override_failure_message(where + ": %s sits on the marsh's open ground" % marsh_kind).is_equal(marsh)
						assert_bool(busy.has(cell)).override_failure_message(where + ": nothing on what the hero uses or arrives at").is_false()
				GreyboxTiles.ROW_HOUSE_DECOR:
					# A chimney, the chapel's cross or the shop's sign.
					assert_bool(grid.is_solid(cell) and grid.height_at(cell) == 3).override_failure_message(where + ": a house's overlay sits on the house").is_true()
				GreyboxTiles.ROW_SMOKE:
					assert_that(decor.get_cell_atlas_coords(cell + Vector2i.DOWN)).override_failure_message(where + ": smoke rises from a chimney").is_equal(GreyboxTiles.coords("chimney"))
					assert_bool(busy.has(cell)).override_failure_message(where + ": nothing on what the hero uses or arrives at").is_false()
				GreyboxTiles.ROW_DECOR:
					decorations[area_id] = int(decorations.get(area_id, 0)) + 1
					if tile == lily:
						assert_that(under).override_failure_message(where + ": lily pads float on water").is_equal(water)
					else:
						assert_bool(under.y == GreyboxTiles.ROW_GROUND or under == marsh).override_failure_message(where + ": decorations sit on open ground").is_true()
					assert_bool(busy.has(cell)).override_failure_message(where + ": nothing on what the hero uses or arrives at").is_false()
				_:
					fail(where + ": the Decor layer holds only decorations and props")
			var data: TileData = decor.get_cell_tile_data(cell)
			assert_bool(bool(data.get_custom_data(GreyboxTiles.DATA_SOLID))).override_failure_message(where + ": decor never blocks").is_false()
	assert_int(int(decorations.get(&"village", 0))).override_failure_message("the village is decorated").is_greater(60)
	assert_int(int(decorations.get(&"south_field", 0))).override_failure_message("the field is decorated").is_greater(60)
	assert_int(int(decorations.get(&"willowmere", 0))).override_failure_message("the marsh is decorated").is_greater(30)


func test_houses_have_two_storeys_under_a_gabled_roof_and_stay_solid() -> void:
	var scene: Node = _scene(&"village")
	var height: TileMapLayer = scene.get_node(^"Height")
	var grid: HeightGrid = HeightGridBuilder.from_layer(height)
	# [cell, the tile it shows]
	var cases: Array = [
		# A thatched cottage: ridge and eaves, with a barge board at each gable end.
		[Vector2i(6, 11), "roof_thatch_top_l"], [Vector2i(7, 11), "roof_thatch_top"], [Vector2i(11, 11), "roof_thatch_top_r"],
		[Vector2i(6, 12), "roof_thatch_eave_l"], [Vector2i(8, 12), "roof_thatch_eave"], [Vector2i(11, 12), "roof_thatch_eave_r"],
		# Slate on the third house, clay tiles on the shop.
		[Vector2i(28, 11), "roof_blue_top_l"], [Vector2i(29, 12), "roof_blue_eave"], [Vector2i(6, 21), "roof_top_l"],
		# The half-timbered upper floor, then the ground floor with its windows and door.
		[Vector2i(7, 13), "wall_upper_window"], [Vector2i(8, 13), "wall_upper"], [Vector2i(9, 13), "wall_upper_b"],
		[Vector2i(7, 14), "wall_window"], [Vector2i(9, 14), "wall"], [Vector2i(10, 14), "wall_window"],
		[Vector2i(8, 14), "door"], [Vector2i(16, 14), "door"],
		# The chapel: stone, arched windows and a double door.
		[Vector2i(18, 4), "chapel_wall"], [Vector2i(19, 4), "chapel_window"], [Vector2i(18, 5), "chapel_wall"],
		[Vector2i(23, 5), "chapel_door_l"], [Vector2i(24, 5), "chapel_door_r"],
	]
	for case: Array in cases:
		var cell: Vector2i = case[0]
		assert_that(height.get_cell_atlas_coords(cell)).override_failure_message("%s shows %s" % [cell, case[1]]).is_equal(GreyboxTiles.coords(case[1]))
		if GreyboxTiles.HOUSE_DOOR_KINDS.has(case[1]):
			# The chapel's doors lead down to the crypt: a way in, level with the rise.
			assert_bool(grid.is_solid(cell)).override_failure_message("%s is a way in" % cell).is_false()
			assert_int(grid.height_at(cell)).is_equal(GreyboxTiles.HOUSE_DOOR_HEIGHT)
		elif case[1] != "door":
			assert_bool(grid.is_solid(cell)).override_failure_message("%s is solid" % cell).is_true()
			assert_int(grid.height_at(cell)).is_equal(3)


func test_houses_carry_chimneys_that_smoke_a_cross_and_a_sign() -> void:
	var decor: TileMapLayer = _scene(&"village").get_node(^"Decor")
	var smoke: Vector2i = GreyboxTiles.coords("smoke")
	for chimney: Vector2i in [Vector2i(10, 11), Vector2i(18, 11), Vector2i(32, 11), Vector2i(10, 21)]:
		assert_that(decor.get_cell_atlas_coords(chimney)).override_failure_message("a chimney at %s" % chimney).is_equal(GreyboxTiles.coords("chimney"))
		assert_that(decor.get_cell_atlas_coords(chimney + Vector2i.UP)).override_failure_message("smoke above %s" % chimney).is_equal(smoke)
	assert_that(decor.get_cell_atlas_coords(Vector2i(23, 2))).is_equal(GreyboxTiles.coords("cross_l"))
	assert_that(decor.get_cell_atlas_coords(Vector2i(24, 2))).is_equal(GreyboxTiles.coords("cross_r"))
	assert_that(decor.get_cell_atlas_coords(Vector2i(9, 23))).override_failure_message("the shop's sign").is_equal(GreyboxTiles.coords("shop_sign"))
	var source: TileSetAtlasSource = decor.tile_set.get_source(GreyboxTiles.SOURCE_ID)
	assert_int(source.get_tile_animation_frames_count(smoke)).override_failure_message("the smoke stands still (2026-11-13)").is_equal(1)


func test_woods_mix_three_kinds_of_tree_and_close_into_a_canopy() -> void:
	var trees: Array[Vector2i] = [GreyboxTiles.coords("prop_tree"), GreyboxTiles.coords("prop_tree_b"), GreyboxTiles.coords("prop_tree_c")]
	var canopy: Vector2i = GreyboxTiles.coords("prop_canopy")
	for area_id: StringName in [&"old_wood", &"village", &"south_field", &"north_fields"]:
		var scene: Node = _scene(area_id)
		var decor: TileMapLayer = scene.get_node(^"Decor")
		var bounds: Rect2i = (scene.get_node(^"Height") as TileMapLayer).get_used_rect()
		var counts: Dictionary = {}
		for cell: Vector2i in decor.get_used_cells():
			var tile: Vector2i = decor.get_cell_atlas_coords(cell)
			if tile != canopy and not trees.has(tile):
				continue
			counts[tile] = int(counts.get(tile, 0)) + 1
			var hemmed_in: bool = true
			for side: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
				var beside: Vector2i = decor.get_cell_atlas_coords(cell + side)
				if bounds.has_point(cell + side) and beside != canopy and not trees.has(beside):
					hemmed_in = false
			assert_bool(tile == canopy).override_failure_message("%s %s: a canopy exactly where trees stand on every side" % [area_id, cell]).is_equal(hemmed_in)
		for tree: Vector2i in trees:
			assert_int(int(counts.get(tree, 0))).override_failure_message("%s has every kind of tree" % area_id).is_greater(2)
		if area_id == &"old_wood":
			assert_int(int(counts.get(canopy, 0))).override_failure_message("the Old Wood is thick").is_greater(40)


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
