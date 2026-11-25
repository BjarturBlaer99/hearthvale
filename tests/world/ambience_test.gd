extends GdUnitTestSuite
## Light, air and lettering (art pass 4; real lights in P1b). An area knows what kind of place
## it is from its tiles. Its lighting gives it an ambient colour and a real light for everything
## that shines: lamps, hearths, candles, torches, crystals, the lantern. Houses and dungeons are
## dim away from their lights but never around the hero. In the crypt the only pools of light
## are the rule's own (LightRules), at the rule's place and reach, so what is drawn lit is what
## the rule says is lit. Shadows are soft; tall things shade the ground to their east. Every
## label uses Hearthvale's own pixel font, and every box the shared frame. (Specks drifted in
## the air until 2026-11-13.)

const Steps: GDScript = preload("res://tests/support/area_steps.gd")
const FontTool: GDScript = preload("res://tools/art/make_font.gd")

const VILLAGE: String = "res://world/areas/village/village.tscn"
const ELDER_HOUSE: String = "res://world/areas/elder_house/elder_house.tscn"
const KEEP: String = "res://world/areas/keep/keep.tscn"
const CRYPT: String = "res://world/areas/crypt/crypt.tscn"
const FRAME: float = 1.0 / 60.0
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
	assert_int(village.tile_glows.size()).override_failure_message("one glow a lamp").is_equal(lamps.size())
	lamps.sort()
	var first: Dictionary = village.tile_glows[0]
	assert_that(GridBody.cell_of(first["at"])).override_failure_message("at the lamp's cell").is_equal(lamps[0])
	assert_that(first["color"]).is_equal(Ambience.LAMP)
	assert_bool(first["flickers"]).override_failure_message("a lamp burns steadily").is_false()
	var house: AreaController = _load(ELDER_HOUSE)
	var fires: Array = house.tile_glows.filter(func(one: Dictionary) -> bool: return one["color"] == Ambience.FIRE)
	assert_int(fires.size()).override_failure_message("the elder's hearth").is_equal(1)
	assert_bool(fires[0]["flickers"]).override_failure_message("a fire flickers").is_true()
	assert_int(house.tile_glows.size()).override_failure_message("and his candle").is_greater(1)


func test_each_kind_of_place_has_its_ambient_colour() -> void:
	# Outdoors the light follows the hour (P2a): this is the village at noon.
	GameState.set_time(float(GameState.day_clock().in_day("12:00")))
	assert_that(_load(VILLAGE).lighting.ambient).override_failure_message("the sun is out").is_equal(GameState.daylight())
	assert_bool(_area.lighting.is_dim()).is_false()
	var house: Color = _load(ELDER_HOUSE).lighting.ambient
	var keep: Color = _load(KEEP).lighting.ambient
	var crypt: Color = _load(CRYPT).lighting.ambient
	assert_that(house).is_equal(AreaLighting.AMBIENT[Ambience.INTERIOR])
	assert_that(keep).is_equal(AreaLighting.AMBIENT[Ambience.DUNGEON])
	assert_that(crypt).override_failure_message("a dark area is dark whatever its kind").is_equal(AreaLighting.DARK)
	assert_bool(_area.lighting.is_dim()).is_true()
	assert_float(keep.v).override_failure_message("a dungeon is dimmer than a house").is_less(house.v + 0.08)
	assert_float(minf(house.v, keep.v)).override_failure_message("dim, never dark: enemies stay easy to see").is_greater(0.5)
	assert_float(house.r).override_failure_message("a house is warm").is_greater(house.g)
	assert_float(keep.b).override_failure_message("a dungeon is cool").is_greater(keep.r)
	assert_float(crypt.v).override_failure_message("in the dark, a hint of the room stays and no more").is_between(0.02, 0.15)
	for kind: StringName in [Ambience.OUTDOOR, Ambience.INTERIOR, Ambience.DUNGEON]:
		assert_bool(AreaLighting.AMBIENT.has(kind)).override_failure_message("an ambient colour for '%s'" % kind).is_true()


func test_houses_and_dungeons_are_lit_around_the_hero_and_their_lights() -> void:
	# Outdoors the light and the lamps follow the hour (P2a; tests/world/day_test.gd): at dusk
	# the lamps are lit and the light is still clear.
	GameState.set_time(float(GameState.day_clock().in_day("18:30")))
	var village: AreaController = _load(VILLAGE)
	village._process(FRAME)
	assert_int(_of_kind(village, AreaLighting.POOL).size()).override_failure_message("while the light is clear nothing needs a pool").is_equal(0)
	assert_int(_of_kind(village, AreaLighting.GLOW).size()).override_failure_message("lit lamps in view glow").is_greater(0)
	var house: AreaController = _load(ELDER_HOUSE)
	house._process(FRAME)
	assert_object(house.get(&"darkness")).override_failure_message("the old sheet of dark is gone").is_null()
	assert_float(house.brightness_at(Vector2i.ZERO)).override_failure_message("the game's own light rule is untouched").is_equal(1.0)
	var pools: Array = _of_kind(house, AreaLighting.POOL)
	var glows: Array = _of_kind(house, AreaLighting.GLOW)
	assert_int(glows.size()).override_failure_message("a glow for the hearth and one for the candle").is_equal(house.glows_now().size())
	assert_int(pools.size()).override_failure_message("a pool round the hero and round each glow").is_equal(1 + glows.size())
	var around_hero: Array = pools.filter(func(one: Dictionary) -> bool: return (one["at"] as Vector2).is_equal_approx(house.player.position + Vector2(0, -8)))
	assert_int(around_hero.size()).override_failure_message("the hero always stands in light").is_equal(1)
	assert_float(around_hero[0]["radius"]).is_equal(Ambience.HERO_POOL)
	assert_that(around_hero[0]["color"]).override_failure_message("white: the hero's surroundings show in their own colours").is_equal(Color.WHITE)
	for pool: Dictionary in pools:
		assert_float((pool["color"] as Color).v).override_failure_message("a pool is nearly white, only tinted by its fire").is_greater(0.9)


func test_pools_show_true_colours_and_glows_add_their_own() -> void:
	var house: AreaController = _load(ELDER_HOUSE)
	house._process(FRAME)
	var nodes: Array[PointLight2D] = house.lighting.lit_nodes()
	assert_int(nodes.size()).is_equal(house.lighting.shown.size())
	for i: int in nodes.size():
		var one: Dictionary = house.lighting.shown[i]
		var wanted: int = Light2D.BLEND_MODE_MIX if one["kind"] == AreaLighting.POOL else Light2D.BLEND_MODE_ADD
		assert_int(nodes[i].blend_mode).override_failure_message("a pool mixes, a glow adds").is_equal(wanted)
		assert_that(nodes[i].position).is_equal((one["at"] as Vector2).round())
		assert_object(nodes[i].texture).is_not_null()
	var lights: Array = []
	for i: int in 40:
		lights.append(AreaLighting.light(Vector2(i * 4, 0), 30.0 + i, Color.WHITE, AreaLighting.GLOW))
	house.lighting.show_lights(lights, Rect2(0, -50, 400, 100))
	assert_int(house.lighting.lit_nodes().size()).override_failure_message("never more than the engine can draw on one thing").is_equal(AreaLighting.MAX_LIGHTS)
	house.lighting.show_lights([], Rect2(0, 0, 10, 10))
	assert_int(house.lighting.lit_nodes().size()).override_failure_message("lights go out when nothing shines").is_equal(0)


func test_a_light_reaches_exactly_as_far_as_the_rule_says() -> void:
	var rule: Array = [LightRules.light(Vector2.ZERO, 100.0)]
	for distance: float in [0.0, 20.0, 55.0, 56.0, 70.0, 85.0, 99.0, 99.9, 100.0, 101.0, 140.0]:
		var said: float = LightRules.brightness(Vector2(distance, 0.0), rule)
		var drawn: float = AreaLighting.falloff(distance / 100.0, LightRules.CORE, AreaLighting.RULE_STEPS)
		assert_bool(drawn > 0.0).override_failure_message("at %.1f: drawn lit exactly where the rule says lit" % distance).is_equal(said > 0.0)
		assert_float(drawn).override_failure_message("at %.1f: never darker than the rule (%.2f)" % [distance, said]).is_greater_equal(said - 0.001)
		assert_float(drawn).override_failure_message("at %.1f: within one step of the rule" % distance).is_less_equal(said + 1.0 / AreaLighting.RULE_STEPS + 0.001)
		if said >= 1.0:
			assert_float(drawn).override_failure_message("at %.1f: the fully lit core is fully lit" % distance).is_equal(1.0)
	var picture: Image = AreaLighting.picture(LightRules.CORE, AreaLighting.RULE_STEPS).get_image()
	@warning_ignore("integer_division")
	var middle: int = AreaLighting.SIZE / 2
	assert_float(picture.get_pixel(middle, middle).a).override_failure_message("the picture is full at its middle").is_equal_approx(1.0, 0.01)
	assert_float(picture.get_pixel(AreaLighting.SIZE - 1, middle).a).override_failure_message("and still a step of light at its rim").is_equal_approx(1.0 / AreaLighting.RULE_STEPS, 0.01)
	assert_float(picture.get_pixel(0, 0).a).override_failure_message("and nothing in its corners").is_equal(0.0)
	assert_float(picture.get_pixel(middle + int(middle * LightRules.CORE) - 2, middle).a).override_failure_message("full out to the rule's core").is_equal_approx(1.0, 0.01)


func test_the_crypts_dark_is_drawn_by_the_rules_own_lights() -> void:
	GameState.add_item(&"lantern", 1)
	var crypt: AreaController = _load(CRYPT)
	var torch: Torch = crypt.interactables.get_node(^"NarthexTorchA")
	var fires_before: int = _fires(crypt)
	assert_bool(torch.light()).is_true()
	assert_int(_fires(crypt)).override_failure_message("a lit torch glows").is_equal(fires_before + 1)
	crypt._process(FRAME)
	var rule: Array = crypt.lights()
	var pools: Array = _of_kind(crypt, AreaLighting.POOL)
	assert_int(rule.size()).override_failure_message("the hero's lantern and the Narthex's burning torches").is_greater(1)
	assert_int(pools.size()).override_failure_message("a pool for each of the rule's lights, and no others").is_equal(rule.size())
	var nodes: Array[PointLight2D] = crypt.lighting.lit_nodes()
	for said: Dictionary in rule:
		var matching: Array = pools.filter(func(one: Dictionary) -> bool: return (one["at"] as Vector2).is_equal_approx(said["at"]) and is_equal_approx(float(one["radius"]), float(said["radius"])))
		assert_int(matching.size()).override_failure_message("a pool at %s reaching %.1f" % [said["at"], said["radius"]]).is_equal(1)
		assert_bool(matching[0]["exact"]).override_failure_message("drawn with the rule's own falloff").is_true()
		var node: PointLight2D = nodes[crypt.lighting.shown.find(matching[0])]
		assert_float(AreaLighting.reach_of(node)).override_failure_message("the engine's light reaches as far as the rule's").is_equal_approx(float(said["radius"]), 0.01)
		assert_float(node.energy).is_equal(1.0)
		assert_bool(node.position.distance_to(said["at"]) < 0.71).override_failure_message("at the rule's place, to the pixel").is_true()
	# Glows add colour only inside a light's fully lit core: they show nothing the rule hides.
	for glow: Dictionary in _of_kind(crypt, AreaLighting.GLOW):
		var inside: bool = false
		for said: Dictionary in rule:
			inside = inside or (glow["at"] as Vector2).distance_to(said["at"]) + float(glow["radius"]) <= float(said["radius"]) * LightRules.CORE + 0.01
		assert_bool(inside).override_failure_message("the glow at %s stays inside a lit core" % glow["at"]).is_true()
	var lantern: Array = crypt.glows_now().filter(func(one: Dictionary) -> bool: return one["color"] == Ambience.LAMP)
	assert_int(lantern.size()).override_failure_message("the hero's lantern glows").is_equal(1)
	# The Reliquary's crystal is found by lantern light. It glows like any crystal, but out in the
	# dark that glow is not drawn, or it would give itself away from across the room.
	var crystal: CrystalSwitch = crypt.interactables.get_node(^"ReliquaryCrystal")
	var its_place: Vector2 = crystal.position + Vector2(8, 6)
	var its_glow: Array = crypt.glows_now().filter(func(one: Dictionary) -> bool: return (one["at"] as Vector2).is_equal_approx(its_place))
	assert_int(its_glow.size()).override_failure_message("the crystal is among the things that glow").is_equal(1)
	var drawn_there: Array = crypt.scene_lights().filter(func(one: Dictionary) -> bool: return (one["at"] as Vector2).is_equal_approx(its_place))
	assert_int(drawn_there.size()).override_failure_message("but no light is drawn at it while it stands in the dark").is_equal(0)
	var far_glow: Dictionary = Ambience.glow(Vector2(-500, -500), 18.0, CrystalSwitch.RED, 0.3, false)
	assert_bool(AreaController._inside_a_core(far_glow, rule)).override_failure_message("a glow out in the dark is not drawn").is_false()


func test_crystals_glow_in_their_own_colour() -> void:
	var keep: AreaController = _load(KEEP)
	var crystals: Array = keep.interactables.get_children().filter(func(child: Node) -> bool: return child is CrystalSwitch)
	assert_int(crystals.size()).is_greater(0)
	var glows: Array = keep.glows_now().filter(func(one: Dictionary) -> bool: return one["color"] == CrystalSwitch.RED or one["color"] == CrystalSwitch.BLUE)
	assert_int(glows.size()).is_equal(crystals.size())


func test_shadows_are_soft() -> void:
	var rings: Array = SoftShadow.rings(Vector2(6, 2))
	assert_int(rings.size()).override_failure_message("a rim and a heart").is_equal(2)
	assert_float((rings[0][0] as Vector2).x).override_failure_message("the rim is wider than the thing").is_greater(6.0)
	assert_float((rings[1][0] as Vector2).x).override_failure_message("the heart is narrower").is_less(6.0)
	assert_float(rings[0][1]).override_failure_message("and the rim is fainter than the heart").is_less(rings[1][1])
	assert_float(SoftShadow.rings(Vector2(6, 2), 0.5)[1][1]).override_failure_message("strength scales it").is_equal_approx(float(rings[1][1]) * 0.5, 0.001)
	assert_float(SoftShadow.COLOR.b).override_failure_message("violet, like every shadow").is_greater(SoftShadow.COLOR.g)
	assert_float(HeightShading.SHADE_FAR.a).override_failure_message("a cast shadow fades out, not stops").is_less(0.2)
	assert_float(HeightShading.CAST).is_greater(4.0)
	var village: AreaController = _load(VILLAGE)
	assert_bool(village.player.get_node(^"Shadow") is SoftShadowNode).override_failure_message("the hero stands on a soft shadow").is_true()


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
	return area.glows_now().filter(func(one: Dictionary) -> bool: return one["color"] == Ambience.FIRE).size()


## The lights the area's lighting last showed, of one kind (AreaLighting.POOL or GLOW).
func _of_kind(area: AreaController, kind: StringName) -> Array:
	return area.lighting.shown.filter(func(one: Dictionary) -> bool: return one["kind"] == kind)


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area
