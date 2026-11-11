extends GdUnitTestSuite
## Light, air and lettering (art pass 4). An area knows what kind of place it is from its
## tiles; lamps, hearths, candles, torches and crystals glow; houses and dungeons are dim away
## from their lights, but never around the hero; tall things shade the ground to their east;
## specks drift in the air. Every label uses Hearthvale's own pixel font at a whole multiple of
## its size, and every box wears the shared frame. All of it is for show: nothing here changes
## where the hero can go or what can be seen in the crypt's dark.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")
const FontTool: GDScript = preload("res://tools/art/make_font.gd")

const VILLAGE: String = "res://world/areas/village/village.tscn"
const ELDER_HOUSE: String = "res://world/areas/elder_house/elder_house.tscn"
const KEEP: String = "res://world/areas/keep/keep.tscn"
const CRYPT: String = "res://world/areas/crypt/crypt.tscn"
const UI_SCENES: Array[String] = [
	"res://ui/area_hud.tscn", "res://ui/dialogue_box.tscn", "res://ui/item_menu.tscn", "res://ui/pause_menu.tscn",
	"res://ui/quest_log.tscn", "res://ui/settings_menu.tscn", "res://ui/title_screen.tscn", "res://ui/ending_screen.tscn",
]

var _area: Node


func before_test() -> void:
	GameState.clear()
	GameState.new_game()


func after_test() -> void:
	if is_instance_valid(_area):
		_area.free()
	_area = null
	GameState.clear()


func test_an_area_knows_what_kind_of_place_it_is_from_its_tiles() -> void:
	assert_that(_load(VILLAGE).ambience).is_equal(Ambience.OUTDOOR)
	assert_that(_load(ELDER_HOUSE).ambience).is_equal(Ambience.INTERIOR)
	assert_that(_load(KEEP).ambience).is_equal(Ambience.DUNGEON)


func test_lamps_hearths_and_candles_glow_where_their_tiles_are() -> void:
	var village: AreaController = _load(VILLAGE)
	var lamps: Array[Vector2i] = (village.get_node(^"Decor") as TileMapLayer).get_used_cells_by_id(GreyboxTiles.SOURCE_ID, GreyboxTiles.coords("prop_lamp"))
	assert_int(lamps.size()).override_failure_message("the village has lamp posts").is_greater(0)
	assert_int(village.glows.fixed.size()).override_failure_message("one glow a lamp").is_equal(lamps.size())
	lamps.sort()
	var first: Dictionary = village.glows.fixed[0]
	assert_that(GridBody.cell_of(first["at"])).override_failure_message("at the lamp's cell").is_equal(lamps[0])
	assert_that(first["color"]).is_equal(Ambience.LAMP)
	assert_bool(first["flickers"]).override_failure_message("a lamp burns steadily").is_false()
	var house: AreaController = _load(ELDER_HOUSE)
	var fires: Array = house.glows.fixed.filter(func(one: Dictionary) -> bool: return one["color"] == Ambience.FIRE)
	assert_int(fires.size()).override_failure_message("the elder's hearth").is_equal(1)
	assert_bool(fires[0]["flickers"]).override_failure_message("a fire flickers").is_true()
	assert_int(house.glows.fixed.size()).override_failure_message("and his candle").is_greater(1)


func test_houses_and_dungeons_are_dim_away_from_their_lights_and_the_outdoors_is_not() -> void:
	var village: AreaController = _load(VILLAGE)
	assert_object(village.gloom).override_failure_message("the sun is out").is_null()
	var house: AreaController = _load(ELDER_HOUSE)
	assert_object(house.gloom).is_not_null()
	assert_object(house.darkness).override_failure_message("dim, not dark: nothing is hidden").is_null()
	assert_float(house.brightness_at(Vector2i.ZERO)).override_failure_message("the game's own light rule is untouched").is_equal(1.0)
	var lights: Array = house.gloom_lights()
	assert_that(lights[0]["at"]).override_failure_message("the hero always stands in light").is_equal(house.player.position + Vector2(0, -8))
	assert_float(lights[0]["radius"]).is_equal(Ambience.HERO_POOL)
	assert_int(lights.size()).override_failure_message("and every glow lights the room").is_equal(1 + house.glows.all().size())
	assert_float(Ambience.GLOOM[Ambience.DUNGEON]).override_failure_message("a dungeon is dimmer than a house").is_greater(Ambience.GLOOM[Ambience.INTERIOR])
	assert_float(Ambience.GLOOM[Ambience.DUNGEON]).override_failure_message("but enemies stay easy to see").is_less(0.5)


func test_the_crypt_keeps_its_own_dark_and_its_torches_glow_while_they_burn() -> void:
	GameState.add_item(&"lantern", 1)
	var crypt: AreaController = _load(CRYPT)
	assert_object(crypt.darkness).is_not_null()
	assert_object(crypt.gloom).override_failure_message("no second sheet of dark over the first").is_null()
	var torch: Torch = crypt.interactables.get_node(^"NarthexTorchA")
	var before: int = _fires(crypt)
	assert_bool(torch.light()).is_true()
	assert_int(_fires(crypt)).override_failure_message("a lit torch glows").is_equal(before + 1)
	var lantern: Array = crypt.moving_glows().filter(func(one: Dictionary) -> bool: return one["color"] == Ambience.LAMP)
	assert_int(lantern.size()).override_failure_message("and so does the hero's lantern").is_equal(1)


func test_crystals_glow_in_their_own_colour() -> void:
	var keep: AreaController = _load(KEEP)
	var crystals: Array = keep.interactables.get_children().filter(func(child: Node) -> bool: return child is CrystalSwitch)
	assert_int(crystals.size()).is_greater(0)
	var glows: Array = keep.moving_glows().filter(func(one: Dictionary) -> bool: return one["color"] == CrystalSwitch.RED or one["color"] == CrystalSwitch.BLUE)
	assert_int(glows.size()).is_equal(crystals.size())


func test_tall_things_shade_the_ground_to_their_east() -> void:
	var village: AreaController = _load(VILLAGE)
	var grid: HeightGrid = village.grid
	var kinds: Dictionary = {}
	for y: int in grid.size.y:
		for x: int in grid.size.x:
			var cell: Vector2i = Vector2i(x, y)
			var kind: StringName = HeightShading.cast_on(grid, cell)
			if kind == &"":
				continue
			kinds[kind] = int(kinds.get(kind, 0)) + 1
			assert_bool(grid.is_solid(cell)).override_failure_message("shade falls on open ground").is_false()
			var west: Vector2i = cell + Vector2i.LEFT
			var north_west: Vector2i = cell + Vector2i(-1, -1)
			if kind == HeightShading.CAST_CORNER:
				assert_bool(grid.is_solid(north_west) and grid.height_at(north_west) > grid.height_at(cell)).is_true()
				assert_bool(grid.is_solid(west) and grid.height_at(west) > grid.height_at(cell)).override_failure_message("a corner only where the side is open").is_false()
			else:
				assert_bool(grid.is_solid(west) and grid.height_at(west) > grid.height_at(cell)).override_failure_message("something taller stands to the west").is_true()
	for kind: StringName in [HeightShading.CAST_SIDE, HeightShading.CAST_SIDE_BELOW, HeightShading.CAST_CORNER]:
		assert_int(int(kinds.get(kind, 0))).override_failure_message("the village has '%s' shadows" % kind).is_greater(0)


func test_specks_drift_inside_their_field_the_same_way_every_time() -> void:
	for kind: StringName in [Ambience.OUTDOOR, Ambience.INTERIOR, Ambience.DUNGEON]:
		assert_bool(Motes.LOOKS.has(kind)).override_failure_message("a look for '%s'" % kind).is_true()
		assert_int(int(Motes.LOOKS[kind][0])).override_failure_message("a few, not a snowstorm").is_between(4, 24)
	for index: int in 20:
		for seconds: float in [0.0, 7.5, 600.0]:
			var at: Vector2 = Motes.speck_at(index, seconds, Vector2(5.0, 2.0), 5.0)
			assert_bool(Rect2(Vector2.ZERO, Motes.FIELD).has_point(at)).override_failure_message("speck %d at %s" % [index, at]).is_true()
			assert_that(Motes.speck_at(index, seconds, Vector2(5.0, 2.0), 5.0)).is_equal(at)
	assert_that(Motes.speck_at(3, 1.0, Vector2(5.0, 2.0), 5.0)).override_failure_message("they move").is_not_equal(Motes.speck_at(3, 2.0, Vector2(5.0, 2.0), 5.0))
	assert_that(_load(KEEP).motes.kind).is_equal(Ambience.DUNGEON)


func test_the_font_has_every_letter_the_game_can_print() -> void:
	var font: FontFile = ThemeDB.get_project_theme().default_font as FontFile
	assert_object(font).override_failure_message("the project's theme uses the baked font").is_not_null()
	assert_int(font.fixed_size).is_equal(FontTool.SIZE)
	assert_int(ThemeDB.get_project_theme().default_font_size).is_equal(FontTool.SIZE)
	assert_int(font.fixed_size_scale_mode).override_failure_message("scaled by whole numbers only").is_equal(TextServer.FIXED_SIZE_SCALE_INTEGER_ONLY)
	var baked: PackedInt32Array = font.get_glyph_list(0, Vector2i(FontTool.SIZE, 0))
	for code: int in range(32, 127):
		assert_bool(baked.has(code)).override_failure_message("a glyph for '%s'" % String.chr(code)).is_true()
	for key: String in FontTool.GLYPHS:
		var rows: PackedStringArray = FontTool.rows_of(FontTool.GLYPHS[key])
		assert_int(rows.size()).override_failure_message("'%s' fits its cell's height" % key).is_less_equal(FontTool.ROWS)
		assert_int(FontTool.width_of(FontTool.GLYPHS[key])).override_failure_message("'%s' fits its cell's width" % key).is_between(1, FontTool.CELL.x - 1)
		assert_bool("#" in FontTool.GLYPHS[key]).override_failure_message("'%s' has ink" % key).is_true()
	assert_float(font.get_string_size("Hearthvale", HORIZONTAL_ALIGNMENT_LEFT, -1, FontTool.SIZE).x).override_failure_message("narrow letters are narrower").is_less(font.get_string_size("HEARTHVALE", HORIZONTAL_ALIGNMENT_LEFT, -1, FontTool.SIZE).x)


func test_every_label_uses_a_whole_multiple_of_the_fonts_size_and_every_box_its_frame() -> void:
	var size_line: RegEx = RegEx.create_from_string("font_size = (\\d+)")
	for path: String in UI_SCENES:
		var text: String = FileAccess.get_file_as_string(path)
		for found: RegExMatch in size_line.search_all(text):
			assert_int(int(found.get_string(1)) % FontTool.SIZE).override_failure_message("%s: size %s" % [path, found.get_string(1)]).is_equal(0)
		assert_bool("outline_size" in text).override_failure_message("%s: a bitmap font has no outline" % path).is_false()
		assert_bool("panel_frame.gd" in text).override_failure_message("%s: its box wears the frame" % path).is_true()
	var village: AreaController = _load(VILLAGE)
	assert_bool(village.hud.get_node(^"Panel") is PanelFrame).is_true()
	assert_bool(village.hud.dialogue.get_node(^"Panel") is PanelFrame).is_true()
	assert_object(village.hud.vignette).override_failure_message("the screen's corners are shaded").is_not_null()
	assert_int(village.hud.vignette.get_index()).override_failure_message("under everything else on the HUD").is_equal(0)
	assert_float(AreaHud.VIGNETTE_COLOR.a).override_failure_message("lightly").is_less(0.5)


func _fires(area: AreaController) -> int:
	return area.moving_glows().filter(func(one: Dictionary) -> bool: return one["color"] == Ambience.FIRE).size()


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area
