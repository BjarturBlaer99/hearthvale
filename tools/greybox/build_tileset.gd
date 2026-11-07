extends SceneTree
## Builds the greybox TileSet from the imported atlas. Step 3 of 4 (see make_tile_texture.gd).
## Terrain tiles carry the custom data DistrictController reads (TECH_DESIGN §3.2):
## height (int), climbable (bool), ramp (bool), dive_point (String; set per cell later).


func _initialize() -> void:
	var texture: Texture2D = load(GreyboxTiles.TEXTURE_PATH)
	if texture == null:
		push_error("tools/greybox: %s is missing or not imported; run steps 1-2 first." % GreyboxTiles.TEXTURE_PATH)
		quit(1)
		return
	var tile_set: TileSet = TileSet.new()
	tile_set.tile_size = Vector2i(GreyboxTiles.TILE_SIZE, GreyboxTiles.TILE_SIZE)
	var layers: Array = [
		[GreyboxTiles.DATA_HEIGHT, TYPE_INT],
		[GreyboxTiles.DATA_CLIMBABLE, TYPE_BOOL],
		[GreyboxTiles.DATA_RAMP, TYPE_BOOL],
		[GreyboxTiles.DATA_DIVE_POINT, TYPE_STRING],
	]
	for layer: Array in layers:
		var index: int = tile_set.get_custom_data_layers_count()
		tile_set.add_custom_data_layer()
		tile_set.set_custom_data_layer_name(index, layer[0])
		tile_set.set_custom_data_layer_type(index, layer[1])

	var source: TileSetAtlasSource = TileSetAtlasSource.new()
	source.texture = texture
	source.texture_region_size = Vector2i(GreyboxTiles.TILE_SIZE, GreyboxTiles.TILE_SIZE)
	tile_set.add_source(source, GreyboxTiles.SOURCE_ID)
	for row: int in [GreyboxTiles.ROW_PLAIN, GreyboxTiles.ROW_CLIMBABLE, GreyboxTiles.ROW_RAMP]:
		for height: int in GreyboxTiles.COLUMNS:
			var coords: Vector2i = Vector2i(height, row)
			source.create_tile(coords)
			var data: TileData = source.get_tile_data(coords, 0)
			data.set_custom_data(GreyboxTiles.DATA_HEIGHT, height)
			data.set_custom_data(GreyboxTiles.DATA_CLIMBABLE, row == GreyboxTiles.ROW_CLIMBABLE)
			data.set_custom_data(GreyboxTiles.DATA_RAMP, row == GreyboxTiles.ROW_RAMP)
	source.create_tile(GreyboxTiles.WATER_SHALLOW)
	source.create_tile(GreyboxTiles.WATER_DEEP)

	var error: Error = ResourceSaver.save(tile_set, GreyboxTiles.TILESET_PATH)
	print("tools/greybox: wrote %s (%s)" % [GreyboxTiles.TILESET_PATH, error_string(error)])
	quit(0 if error == OK else 1)
