extends SceneTree
## Builds the greybox TileSet from the imported atlas PNG (world/tiles/greybox_tiles.png, the
## source since 2026-11-19), before build_maps.gd.
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
	# Raised dungeon floor: walkable, its height by column.
	for height: int in GreyboxTiles.COLUMNS:
		_fixed(source, Vector2i(height, GreyboxTiles.ROW_LEDGE), height, false)
	# H12 props and decorations (Decor layer, never read for movement) and furniture.
	for index: int in GreyboxTiles.PROPS_B_KINDS.size():
		_fixed(source, Vector2i(index, GreyboxTiles.ROW_PROPS_B), 0, false)
	for index: int in GreyboxTiles.PROPS_C_KINDS.size():
		_fixed(source, Vector2i(index, GreyboxTiles.ROW_PROPS_C), 0, false)
	for index: int in GreyboxTiles.FURNITURE_B_KINDS.size():
		_fixed(source, Vector2i(index, GreyboxTiles.ROW_FURNITURE_B), GreyboxTiles.FURNITURE_B_HEIGHTS[index], true)
	# House fronts: solid, as tall as any roof or wall. Their overlays and the smoke are Decor.
	for kind: String in GreyboxTiles.HOUSE_KINDS:
		if GreyboxTiles.HOUSE_DOOR_KINDS.has(kind):
			_fixed(source, GreyboxTiles.coords(kind), GreyboxTiles.HOUSE_DOOR_HEIGHT, false)
		else:
			_fixed(source, GreyboxTiles.coords(kind), 3, true)
	for kind: String in GreyboxTiles.HOUSE_DECOR_KINDS:
		_fixed(source, GreyboxTiles.coords(kind), 0, false)
	# Chimney smoke stands still (the user's request, 2026-11-13): the first of its painted
	# frames, and the others unused.
	_fixed(source, GreyboxTiles.coords("smoke"), 0, false)
	for kind: String in GreyboxTiles.TREE_KINDS:
		_fixed(source, GreyboxTiles.coords(kind), 0, false)
	# The marsh (Willowmere): its ground and boardwalks are walked on, its reeds and the ruin
	# aren't; its decorations and props are for the Decor layer.
	for index: int in GreyboxTiles.MARSH_KINDS.size():
		_fixed(source, Vector2i(index, GreyboxTiles.ROW_MARSH), GreyboxTiles.MARSH_HEIGHTS[index], GreyboxTiles.MARSH_SOLID[index])
	for index: int in GreyboxTiles.MARSH_DECOR_KINDS.size():
		_fixed(source, Vector2i(index, GreyboxTiles.ROW_MARSH_DECOR), 0, false)
	# The Old Quarry: its earth, its mouth and its ladder are walked on, its rock isn't; its
	# decorations and its prop are for the Decor layer.
	for index: int in GreyboxTiles.QUARRY_KINDS.size():
		_fixed(source, Vector2i(index, GreyboxTiles.ROW_QUARRY), GreyboxTiles.QUARRY_HEIGHTS[index], GreyboxTiles.QUARRY_SOLID[index])
	for index: int in GreyboxTiles.QUARRY_DECOR_KINDS.size():
		_fixed(source, Vector2i(index, GreyboxTiles.ROW_QUARRY_DECOR), 0, false)
	# Spawn markers: never walked on (the area clears them), open ground in the editor.
	for index: int in GreyboxTiles.MARKER_KINDS.size():
		_fixed(source, Vector2i(index, GreyboxTiles.ROW_MARKERS), 0, false)
	for index: int in GreyboxTiles.LAND_MARKER_KINDS.size():
		_fixed(source, Vector2i(index, GreyboxTiles.ROW_LAND_MARKERS), 0, false)
	# The buildings the hero sets down (the Homestead, phase 3): drawn over the ground by
	# BuildingArt and never laid on a Height layer; in the editor they read as a house's tiles.
	for kind: String in GreyboxTiles.BUILDING_KINDS + GreyboxTiles.SILO_KINDS + GreyboxTiles.ROOF_B_KINDS:
		_fixed(source, GreyboxTiles.coords(kind), 3, true)
	for index: int in GreyboxTiles.FURNITURE_C_KINDS.size():
		_fixed(source, Vector2i(index, GreyboxTiles.ROW_FURNITURE_C), GreyboxTiles.FURNITURE_C_HEIGHTS[index], true)
	# Water: one tile that plays its frames (which lie to its right) in a loop.
	var water: Vector2i = Vector2i(0, GreyboxTiles.ROW_WATER)
	_fixed(source, water, 0, true)
	source.set_tile_animation_columns(water, GreyboxTiles.WATER_FRAMES)
	source.set_tile_animation_frames_count(water, GreyboxTiles.WATER_FRAMES)
	for frame: int in GreyboxTiles.WATER_FRAMES:
		source.set_tile_animation_frame_duration(water, frame, GreyboxTiles.WATER_FRAME_TIME)

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
