extends GdUnitTestSuite
## The tool polish's step 4 (D9 to D11): a mirrored frame is drawn over the same columns as the
## frame itself (until then it stood a frame's width to the right); a building site has one string
## round its outside, not one on every cell; and the Coop's, the Barn's and the Shed's windows glow
## with the lamps once they stand.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const FARM: String = "res://world/areas/homestead/homestead.tscn"
const LAND: StringName = &"homestead"
const COOP_AT: Vector2i = Vector2i(14, 10)

var _area: Node


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	Quests.refresh()


func after_test() -> void:
	if is_instance_valid(_area):
		_area.free()
	_area = null
	GameState.clear()


func test_a_mirrored_frame_covers_the_same_columns_as_the_frame() -> void:
	for size: Vector2i in [Vector2i(16, 16), Vector2i(16, 24), Vector2i(32, 40)]:
		var origin: Vector2 = Vector2(40.4, 12.0)
		var plain: Rect2 = SpriteSheet.target_of(origin, size, false)
		var mirrored: Rect2 = SpriteSheet.target_of(origin, size, true)
		assert_that(plain).is_equal(Rect2(Vector2(40, 12), Vector2(size)))
		assert_float(mirrored.size.x).override_failure_message("a negative width mirrors it").is_equal(-float(size.x))
		# This engine mirrors a negative-width rectangle in place, over its corner's own columns
		# (measured in a window, 2026-11-19): so the corner must not move.
		assert_that(mirrored.position).override_failure_message("%s: in its own place" % size).is_equal(plain.position)
		assert_float(mirrored.size.y).is_equal(plain.size.y)


func test_a_site_is_strung_round_its_outside_with_a_peg_at_each_corner() -> void:
	var size: Vector2 = Vector2(4, 3) * GreyboxTiles.TILE_SIZE
	var pieces: Array[Array] = BuildingArt.twine(size)
	var lines: int = 0
	var pegs: int = 0
	for piece: Array in pieces:
		var rect: Rect2 = piece[0]
		assert_bool(Rect2(Vector2.ZERO, size).encloses(rect)).override_failure_message("%s inside the site" % rect).is_true()
		# Nothing crosses the middle: every piece lies within three pixels of an edge.
		var near_edge: bool = rect.position.x < 3.0 or rect.position.y < 3.0 or rect.end.x > size.x - 3.0 or rect.end.y > size.y - 3.0
		assert_bool(near_edge).override_failure_message("%s lies along the edge" % rect).is_true()
		if piece[1] == BuildingArt.TWINE:
			lines += 1
		else:
			pegs += 1
	assert_int(lines).override_failure_message("four sides").is_equal(4)
	assert_int(pegs).override_failure_message("four pegs of nine pixels").is_equal(36)
	# The site's own tiles carry no string of their own any more.
	var atlas: Image = Image.load_from_file(ProjectSettings.globalize_path(GreyboxTiles.TEXTURE_PATH))
	for kind: String in [Buildings.SITE_TILE, Buildings.SITE_TIMBER]:
		var at: Vector2i = GreyboxTiles.coords(kind) * GreyboxTiles.TILE_SIZE
		for y: int in GreyboxTiles.TILE_SIZE:
			for x: int in GreyboxTiles.TILE_SIZE:
				assert_bool(atlas.get_pixel(at.x + x, at.y + y).is_equal_approx(BuildingArt.TWINE)).override_failure_message("%s (%d, %d): no string in the tile" % [kind, x, y]).is_false()


func test_the_coop_barn_and_shed_light_their_windows_and_the_well_and_silo_have_none() -> void:
	for id: StringName in [&"coop", &"barn", &"shed"]:
		assert_bool(Buildings.lit_at_night(DataRegistry.get_building(id))).override_failure_message(String(id)).is_true()
	for id: StringName in [&"well", &"silo"]:
		assert_bool(Buildings.lit_at_night(DataRegistry.get_building(id))).override_failure_message(String(id)).is_false()


func test_a_standing_coops_window_glows_from_dusk_to_dawn_and_a_site_has_none() -> void:
	for cell: Vector2i in Buildings.cells_and_doorstep(DataRegistry.get_building(&"coop"), COOP_AT):
		GameState.clear_debris(LAND, cell)
	GameState.add_item(&"coop_kit")
	assert_bool(GameState.set_down_kit(LAND, COOP_AT, &"coop_kit")).is_true()
	GameState.set_time(float(GameState.day_clock().in_day("22:00")))
	var farm: AreaController = _load()
	assert_array(farm.buildings.window_glass()).override_failure_message("a site has no windows yet").is_empty()
	GameState.start_next_day()
	GameState.set_time(float(GameState.day_clock().in_day("22:00")))
	farm = _load()
	farm._update_light()
	var glass: Array[Rect2] = farm.buildings.window_glass()
	# The Coop's wall is four cells wide: its window is the second cell of its bottom row.
	var window: Rect2i = WindowGlow.BUILDING_GLASS["wall_window"]
	assert_array(glass).is_equal([Rect2(Vector2((COOP_AT + Vector2i(1, 2)) * GreyboxTiles.TILE_SIZE + window.position), Vector2(window.size))])
	assert_array(farm.buildings.glow.windows).is_equal(glass)
	assert_bool(farm.buildings.glow.lit).override_failure_message("lit at 22:00").is_true()
	GameState.set_time(float(GameState.day_clock().in_day("12:00")))
	farm._update_light()
	assert_bool(farm.buildings.glow.lit).override_failure_message("dark at noon").is_false()


func _load() -> AreaController:
	_area = Steps.load_area(FARM, _area)
	return _area
