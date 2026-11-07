extends GdUnitTestSuite
## HeightGridBuilder: reads height, climbable and ramp from a Height layer's tile data.


func test_reads_heights_and_flags_from_tile_data() -> void:
	var layer: TileMapLayer = _layer()
	layer.set_cell(Vector2i(0, 0), GreyboxTiles.SOURCE_ID, GreyboxTiles.terrain_coords(3, false, false))
	layer.set_cell(Vector2i(2, 1), GreyboxTiles.SOURCE_ID, GreyboxTiles.terrain_coords(5, true, false))
	layer.set_cell(Vector2i(1, 1), GreyboxTiles.SOURCE_ID, GreyboxTiles.terrain_coords(2, false, true))
	var grid: HeightGrid = HeightGridBuilder.from_layer(layer)
	assert_that(grid.size).is_equal(Vector2i(3, 2))
	assert_int(grid.height_at(Vector2i(0, 0))).is_equal(3)
	assert_int(grid.height_at(Vector2i(2, 1))).is_equal(5)
	assert_bool(grid.is_climbable(Vector2i(2, 1))).is_true()
	assert_bool(grid.is_ramp(Vector2i(1, 1))).is_true()
	assert_bool(grid.is_ramp(Vector2i(2, 1))).is_false()
	# Unpainted cells inside the grid are street level.
	assert_int(grid.height_at(Vector2i(1, 0))).is_equal(0)


func test_cells_at_negative_coordinates_are_ignored() -> void:
	var layer: TileMapLayer = _layer()
	layer.set_cell(Vector2i(-2, -1), GreyboxTiles.SOURCE_ID, GreyboxTiles.terrain_coords(7, false, false))
	layer.set_cell(Vector2i(1, 0), GreyboxTiles.SOURCE_ID, GreyboxTiles.terrain_coords(1, false, false))
	var grid: HeightGrid = HeightGridBuilder.from_layer(layer)
	assert_that(grid.size).is_equal(Vector2i(2, 1))
	assert_int(grid.height_at(Vector2i(1, 0))).is_equal(1)


func _layer() -> TileMapLayer:
	var layer: TileMapLayer = auto_free(TileMapLayer.new())
	layer.tile_set = load(GreyboxTiles.TILESET_PATH)
	return layer
