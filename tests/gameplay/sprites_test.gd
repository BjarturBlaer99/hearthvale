extends GdUnitTestSuite
## Pixel art (H11): every sheet the game draws is painted by tools/art/make_sprites.gd; the
## frame names the scripts use match the order the tool paints them; each sheet carries its white
## flash row; villagers are recoloured per look; dungeon ledges are flagstones you can stand on;
## water is animated.

const TOOL: String = "res://tools/art/make_sprites.gd"


func test_frame_names_match_the_order_the_tool_paints_them() -> void:
	var sprites: Dictionary = _tool_sprites()
	var cases: Array = [
		["slime", Enemy.SLIME_FRAMES], ["bat", Enemy.BAT_FRAMES], ["goblin", Enemy.GOBLIN_FRAMES],
		["warden", Boss.FRAMES], ["villager", Villager.FRAMES], ["items", ItemIcons.FRAMES],
		["crystal", CrystalSwitch.FRAMES], ["breakables", Breakable.FRAMES], ["critters", Critter.FRAMES],
	]
	for case: Array in cases:
		var painted: Array = (sprites[case[0]]["frames"] as Dictionary).keys()
		var used: Dictionary = case[1]
		assert_int(used.size()).override_failure_message("%s: every frame named" % case[0]).is_equal(painted.size())
		for frame: StringName in used:
			assert_int(painted.find(String(frame))).override_failure_message("%s/%s" % [case[0], frame]).is_equal(int(used[frame]))


func test_every_sheet_is_painted_with_a_white_flash_row() -> void:
	var sprites: Dictionary = _tool_sprites()
	for sprite_name: String in sprites:
		var size: Vector2i = sprites[sprite_name]["size"]
		var frames: int = (sprites[sprite_name]["frames"] as Dictionary).size()
		var texture: Texture2D = load("res://gameplay/art/%s.png" % sprite_name)
		assert_object(texture).override_failure_message(sprite_name).is_not_null()
		assert_that(Vector2i(texture.get_size())).override_failure_message(sprite_name).is_equal(Vector2i(size.x * frames, size.y * 2))
		var image: Image = texture.get_image()
		var opaque: int = 0
		for y: int in size.y:
			for x: int in size.x * frames:
				var top: Color = image.get_pixel(x, y)
				var flash: Color = image.get_pixel(x, y + size.y)
				assert_float(flash.a).override_failure_message("%s (%d, %d): the flash has the same shape" % [sprite_name, x, y]).is_equal(top.a)
				if top.a > 0.0:
					opaque += 1
					assert_bool(flash.is_equal_approx(Color.WHITE)).override_failure_message("%s: the flash is white" % sprite_name).is_true()
		assert_int(opaque).override_failure_message("%s has something painted" % sprite_name).is_greater(20)


func test_villagers_wear_their_own_colours() -> void:
	var robe: Color = Color(0.20, 0.60, 0.30)
	var hair: Color = Color(0.90, 0.85, 0.10)
	var texture: Texture2D = SpriteSheet.recoloured(Villager.SHEET, {
		Villager.ROBE_MARK: robe, Villager.ROBE_SHADE_MARK: robe.darkened(0.3),
		Villager.HAIR_MARK: hair, Villager.HAIR_SHADE_MARK: hair.darkened(0.3),
	}, "test:villager")
	var image: Image = texture.get_image()
	var robed: int = 0
	for y: int in image.get_height():
		for x: int in image.get_width():
			var pixel: Color = image.get_pixel(x, y)
			if pixel.a == 0.0:
				continue
			for marker: Color in [Villager.ROBE_MARK, Villager.ROBE_SHADE_MARK, Villager.HAIR_MARK, Villager.HAIR_SHADE_MARK]:
				assert_bool(SpriteSheet._close(pixel, marker)).override_failure_message("a marker colour left at (%d, %d)" % [x, y]).is_false()
			if SpriteSheet._close(pixel, robe):
				robed += 1
	assert_int(robed).override_failure_message("the robe took its colour").is_greater(20)
	assert_object(SpriteSheet.recoloured(Villager.SHEET, {}, "test:villager")).override_failure_message("made once per look").is_same(texture)


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


func _tool_sprites() -> Dictionary:
	return (load(TOOL) as GDScript).get_script_constant_map()["SPRITES"]


func test_items_take_the_picture_their_data_names() -> void:
	assert_that(ItemIcons.name_for(&"weavers_shuttle")).override_failure_message("the shuttle names its own picture").is_equal(&"shuttle")
	assert_that(ItemIcons.name_for(&"egg_basket")).override_failure_message("no picture named: by type, a gem").is_equal(&"gem")
	assert_that(ItemIcons.name_for(&"wooden_sword")).is_equal(&"sword")
	for item: Dictionary in DataRegistry.entries(&"items"):
		if item.has("icon"):
			assert_bool(ItemIcons.FRAMES.has(StringName(str(item["icon"])))).override_failure_message("%s names a picture that exists" % item["id"]).is_true()
