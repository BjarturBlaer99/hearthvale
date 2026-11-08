extends SceneTree
## Builds the greybox TileSet from the imported atlas. Step 3 of 4 (see make_tile_texture.gd).
## Every tile carries the custom data HeightGridBuilder reads (TECH_DESIGN §3):
## height (int), ramp (bool: stairs), solid (bool: never entered).


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
		[GreyboxTiles.DATA_RAMP, TYPE_BOOL],
		[GreyboxTiles.DATA_SOLID, TYPE_BOOL],
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
	for row: int in [GreyboxTiles.ROW_GROUND, GreyboxTiles.ROW_STAIRS, GreyboxTiles.ROW_PATH]:
		for height: int in GreyboxTiles.COLUMNS:
			var data: TileData = _tile(source, Vector2i(height, row))
			data.set_custom_data(GreyboxTiles.DATA_HEIGHT, height)
			data.set_custom_data(GreyboxTiles.DATA_RAMP, row == GreyboxTiles.ROW_STAIRS)
			data.set_custom_data(GreyboxTiles.DATA_SOLID, false)
	for index: int in GreyboxTiles.SOLID_KINDS.size():
		_fixed(source, Vector2i(index, GreyboxTiles.ROW_SOLID), GreyboxTiles.SOLID_HEIGHTS[index], true)
	for index: int in GreyboxTiles.FLOOR_KINDS.size():
		_fixed(source, Vector2i(index, GreyboxTiles.ROW_FLOOR), 0, false)
	for index: int in GreyboxTiles.FURNITURE_KINDS.size():
		_fixed(source, Vector2i(index, GreyboxTiles.ROW_FURNITURE), GreyboxTiles.FURNITURE_HEIGHTS[index], true)
	# Decorations live on the Decor layer, which movement never reads; they're open ground anyway.
	for index: int in GreyboxTiles.DECOR_KINDS.size():
		_fixed(source, Vector2i(index, GreyboxTiles.ROW_DECOR), 0, false)
	for index: int in GreyboxTiles.DETAIL_KINDS.size():
		_fixed(source, Vector2i(index, GreyboxTiles.ROW_DETAIL), GreyboxTiles.DETAIL_HEIGHTS[index], true)
	# Solid ground: grass of each height that can't be entered (trees, rocks, fences stand on it).
	for height: int in GreyboxTiles.COLUMNS:
		_fixed(source, Vector2i(height, GreyboxTiles.ROW_SOLID_GROUND), height, true)
	for index: int in GreyboxTiles.PROP_KINDS.size():
		_fixed(source, Vector2i(index, GreyboxTiles.ROW_PROPS), 0, false)

	var error: Error = ResourceSaver.save(tile_set, GreyboxTiles.TILESET_PATH)
	print("tools/greybox: wrote %s (%s)" % [GreyboxTiles.TILESET_PATH, error_string(error)])
	quit(0 if error == OK else 1)


## A tile whose height doesn't depend on its column: solids, floors, furniture.
func _fixed(source: TileSetAtlasSource, coords: Vector2i, height: int, solid: bool) -> void:
	var data: TileData = _tile(source, coords)
	data.set_custom_data(GreyboxTiles.DATA_HEIGHT, height)
	data.set_custom_data(GreyboxTiles.DATA_RAMP, false)
	data.set_custom_data(GreyboxTiles.DATA_SOLID, solid)


func _tile(source: TileSetAtlasSource, coords: Vector2i) -> TileData:
	source.create_tile(coords)
	return source.get_tile_data(coords, 0)
