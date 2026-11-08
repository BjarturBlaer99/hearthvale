extends GdUnitTestSuite
## HeightGridBuilder: reads height, stairs and solids from a Height layer's tile data.


func test_reads_height_stairs_and_solids_from_tile_data() -> void:
	var layer: TileMapLayer = _layer()
	layer.set_cell(Vector2i(0, 0), GreyboxTiles.SOURCE_ID, GreyboxTiles.coords("ground", 3))
	layer.set_cell(Vector2i(1, 1), GreyboxTiles.SOURCE_ID, GreyboxTiles.coords("stairs", 2))
	layer.set_cell(Vector2i(2, 1), GreyboxTiles.SOURCE_ID, GreyboxTiles.coords("tree"))
	var grid: HeightGrid = HeightGridBuilder.from_layer(layer)
	assert_that(grid.size).is_equal(Vector2i(3, 2))
	assert_int(grid.height_at(Vector2i(0, 0))).is_equal(3)
	assert_bool(grid.is_ramp(Vector2i(1, 1))).is_true()
	assert_int(grid.height_at(Vector2i(1, 1))).is_equal(2)
	assert_bool(grid.is_solid(Vector2i(2, 1))).is_true()
	assert_int(grid.height_at(Vector2i(2, 1))).override_failure_message("a tree shades like a 2-level block").is_equal(2)
	assert_bool(grid.is_solid(Vector2i(0, 0))).is_false()
	# Unpainted cells inside the grid are open ground.
	assert_int(grid.height_at(Vector2i(1, 0))).is_equal(0)


func test_cells_at_negative_coordinates_are_ignored() -> void:
	var layer: TileMapLayer = _layer()
	layer.set_cell(Vector2i(-2, -1), GreyboxTiles.SOURCE_ID, GreyboxTiles.coords("ground", 7))
	layer.set_cell(Vector2i(1, 0), GreyboxTiles.SOURCE_ID, GreyboxTiles.coords("ground", 1))
	var grid: HeightGrid = HeightGridBuilder.from_layer(layer)
	assert_that(grid.size).is_equal(Vector2i(2, 1))
	assert_int(grid.height_at(Vector2i(1, 0))).is_equal(1)


func _layer() -> TileMapLayer:
	var layer: TileMapLayer = auto_free(TileMapLayer.new())
	layer.tile_set = load(GreyboxTiles.TILESET_PATH)
	return layer
