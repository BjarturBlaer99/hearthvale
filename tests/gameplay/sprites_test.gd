extends GdUnitTestSuite
## Pixel art (H11): dungeon ledges are flagstones you can stand on (villagers were recoloured per
## look until the farm-look plan's phase D: tests/world/characters_test.gd has their figures); water is animated; items take their pictures. (Each sheet's size, frames and flash row are
## tests/art/art_sheets_test.gd's, since the art became PNG.)


func test_dungeon_ledges_are_flagstones_you_can_stand_on_and_water_is_animated() -> void:
	var tile_set: TileSet = load(GreyboxTiles.TILESET_PATH)
	var source: TileSetAtlasSource = tile_set.get_source(GreyboxTiles.SOURCE_ID) as TileSetAtlasSource
	for height: int in GreyboxTiles.COLUMNS:
		var ledge: TileData = source.get_tile_data(GreyboxTiles.coords("ledge", height), 0)
		assert_int(int(ledge.get_custom_data(GreyboxTiles.DATA_HEIGHT))).is_equal(height)
		assert_bool(bool(ledge.get_custom_data(GreyboxTiles.DATA_SOLID))).override_failure_message("a ledge can be stood on").is_false()
	var water: Vector2i = GreyboxTiles.coords("water")
	assert_int(source.get_tile_animation_frames_count(water)).is_equal(GreyboxTiles.WATER_FRAMES)
	assert_bool(bool(source.get_tile_data(water, 0).get_custom_data(GreyboxTiles.DATA_SOLID))).is_true()
	var keep: Node = auto_free((load("res://world/areas/keep/keep.tscn") as PackedScene).instantiate())
	var height_layer: TileMapLayer = keep.get_node(^"Height")
	assert_that(height_layer.get_cell_atlas_coords(Vector2i(4, 2))).override_failure_message("the gallery's walkway").is_equal(GreyboxTiles.coords("ledge", 1))


func test_items_take_the_picture_their_data_names() -> void:
	assert_that(ItemIcons.name_for(&"weavers_shuttle")).override_failure_message("the shuttle names its own picture").is_equal(&"shuttle")
	assert_that(ItemIcons.name_for(&"egg_basket")).override_failure_message("no picture named: by type, a gem").is_equal(&"gem")
	assert_that(ItemIcons.name_for(&"wooden_sword")).is_equal(&"sword")
	for item: Dictionary in DataRegistry.entries(&"items"):
		if item.has("icon"):
			# What is set down on the land wears its picture on the ground (PlacedArt); the rest,
			# one of the items' own.
			var sheet: Dictionary = PlacedArt.FRAMES if Placement.is_placeable(item) else ItemIcons.FRAMES
			assert_bool(sheet.has(StringName(str(item["icon"])))).override_failure_message("%s names a picture that exists" % item["id"]).is_true()
			assert_that(ItemIcons.name_for(StringName(str(item["id"])))).override_failure_message("%s shows it" % item["id"]).is_equal(StringName(str(item["icon"])))
