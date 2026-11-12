extends GdUnitTestSuite
## The frame (P1a): the picture is 640x360 on the same 16-pixel grid. Outdoors the camera shows
## the world at life size; in houses and dungeons, whose rooms are small, at twice the size, with
## the room in the middle. Every box on screen is anchored, so nothing sits where the old
## 480x270 screen had it. The HUD's corner holds the hearts and an energy bar (hidden until P2)
## and fits what it holds.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const VILLAGE: String = "res://world/areas/village/village.tscn"
const ELDER_HOUSE: String = "res://world/areas/elder_house/elder_house.tscn"
const KEEP: String = "res://world/areas/keep/keep.tscn"
const CRYPT: String = "res://world/areas/crypt/crypt.tscn"
const SCREEN: Vector2i = Vector2i(640, 360)
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


func test_the_picture_is_640_by_360_and_the_window_a_whole_multiple_of_it() -> void:
	assert_int(int(ProjectSettings.get_setting("display/window/size/viewport_width"))).is_equal(SCREEN.x)
	assert_int(int(ProjectSettings.get_setting("display/window/size/viewport_height"))).is_equal(SCREEN.y)
	assert_that(Settings.BASE_SIZE).override_failure_message("the settings scale the same picture").is_equal(SCREEN)
	var wide: int = int(ProjectSettings.get_setting("display/window/size/window_width_override"))
	var high: int = int(ProjectSettings.get_setting("display/window/size/window_height_override"))
	assert_int(wide % SCREEN.x).override_failure_message("a whole number of times wider").is_equal(0)
	@warning_ignore("integer_division")
	assert_int(high).override_failure_message("and as many times higher").is_equal(SCREEN.y * (wide / SCREEN.x))
	assert_int(GreyboxTiles.TILE_SIZE).override_failure_message("the grid is what it was").is_equal(16)


func test_outdoors_is_life_size_and_houses_and_dungeons_twice_that() -> void:
	var village: AreaController = _load(VILLAGE)
	assert_int(village.player.camera_zoom()).is_equal(1)
	assert_that(village.player.camera_view()).override_failure_message("40 by 22 cells of the village").is_equal(SCREEN)
	var house: AreaController = _load(ELDER_HOUSE)
	assert_int(house.player.camera_zoom()).is_equal(2)
	@warning_ignore("integer_division")
	assert_that(house.player.camera_view()).is_equal(SCREEN / 2)
	assert_int(_load(KEEP).player.camera_zoom()).is_equal(2)
	assert_int(_load(CRYPT).player.camera_zoom()).override_failure_message("the dark crypt too").is_equal(2)
	for kind: StringName in Ambience.ZOOM:
		assert_bool(Ambience.ZOOM[kind] is int and int(Ambience.ZOOM[kind]) >= 1).override_failure_message("whole numbers keep pixels square").is_true()


func test_a_room_fits_the_screen_at_twice_its_size_and_sits_in_the_middle() -> void:
	var keep: AreaController = _load(KEEP)
	var room: Rect2i = RoomGrid.camera_rect(keep.player.motor.cell, keep.room_size, keep.grid.size, GreyboxTiles.TILE_SIZE)
	var view: Vector2i = keep.player.camera_view()
	assert_bool(room.size.x <= view.x and room.size.y <= view.y).override_failure_message("a room of %s fits a view of %s" % [room.size, view]).is_true()
	var limits: Rect2i = keep.player.camera_limits()
	assert_that(limits.size).override_failure_message("the camera can't move within a room").is_equal(view)
	assert_that(limits.get_center()).override_failure_message("the room's middle is the screen's").is_equal(room.get_center())
	var house: AreaController = _load(ELDER_HOUSE)
	var floor_plan: Rect2i = Rect2i(Vector2i.ZERO, house.grid.size * GreyboxTiles.TILE_SIZE)
	assert_bool(floor_plan.size.x <= house.player.camera_view().x and floor_plan.size.y <= house.player.camera_view().y).override_failure_message("a house fits too").is_true()
	assert_that(house.player.camera_limits().get_center()).is_equal(floor_plan.get_center())


func test_outdoors_the_camera_stays_inside_the_map() -> void:
	var village: AreaController = _load(VILLAGE)
	assert_that(village.player.camera_limits()).is_equal(Rect2i(Vector2i.ZERO, village.grid.size * GreyboxTiles.TILE_SIZE))
	assert_bool(village.grid.size.x * GreyboxTiles.TILE_SIZE >= SCREEN.x).override_failure_message("the village is wider than the screen").is_true()
	for path: String in ["res://world/areas/north_fields/north_fields.tscn", "res://world/areas/old_wood/old_wood.tscn", "res://world/areas/south_field/south_field.tscn"]:
		var area: AreaController = _load(path)
		var size: Vector2i = area.grid.size * GreyboxTiles.TILE_SIZE
		assert_bool(size.x >= SCREEN.x and size.y >= SCREEN.y).override_failure_message("%s fills the screen: %s" % [path, size]).is_true()


func test_no_box_is_left_where_the_old_screen_had_it() -> void:
	for path: String in UI_SCENES:
		var text: String = FileAccess.get_file_as_string(path)
		assert_bool("offset_right = 480.0" in text).override_failure_message("%s: nothing spans exactly the old width" % path).is_false()
	var village: AreaController = _load(VILLAGE)
	var boxes: Array[Control] = [
		village.hud.pause_menu.get_node(^"Panel"), village.hud.item_menu.get_node(^"Panel"),
		village.hud.pause_menu.get_node(^"Border"), village.hud.item_menu.get_node(^"Border"),
	]
	for box: Control in boxes:
		assert_float(box.anchor_left).override_failure_message("%s is anchored to the middle" % box.get_path()).is_equal(0.5)
		assert_float(box.anchor_top).is_equal(0.5)
		assert_float(box.offset_left + box.offset_right).override_failure_message("and centred on it").is_equal(0.0)
	var words: Control = village.hud.dialogue.get_node(^"Panel")
	assert_float(words.anchor_top).override_failure_message("the dialogue box hangs from the bottom edge").is_equal(1.0)
	assert_float(words.offset_left + words.offset_right).is_equal(0.0)
	assert_float(words.offset_bottom).is_less(0.0)
	var hint: Control = village.hud.get_node(^"HintPanel")
	assert_float(hint.anchor_left).override_failure_message("the controls hint hangs from the right edge").is_equal(1.0)
	assert_float(hint.offset_right).is_less(0.0)


func test_the_energy_bar_shows_what_it_is_told() -> void:
	var bar: EnergyBar = auto_free(EnergyBar.new())
	bar.set_energy(100.0, 100.0)
	assert_float(bar.fraction()).is_equal(1.0)
	assert_bool(bar.is_low()).is_false()
	bar.set_energy(25.0, 100.0)
	assert_bool(bar.is_low()).override_failure_message("a quarter is low").is_true()
	bar.set_energy(150.0, 100.0)
	assert_float(bar.fraction()).override_failure_message("never more than full").is_equal(1.0)
	bar.set_energy(-5.0, 100.0)
	assert_float(bar.fraction()).override_failure_message("never less than empty").is_equal(0.0)
	assert_int(EnergyBar.filled_pixels(0.0, 64)).is_equal(0)
	assert_int(EnergyBar.filled_pixels(1.0, 64)).is_equal(64)
	assert_int(EnergyBar.filled_pixels(0.5, 64)).is_equal(32)
	assert_int(EnergyBar.filled_pixels(0.001, 64)).override_failure_message("a sliver shows while any is left").is_equal(1)
	assert_int(EnergyBar.filled_pixels(0.999, 64)).override_failure_message("and a gap until it is full").is_equal(63)
	assert_that(EnergyBar.color_for(0.9)).is_equal(EnergyBar.FULL_COLOR)
	assert_that(EnergyBar.color_for(0.4)).is_equal(EnergyBar.MID_COLOR)
	assert_that(EnergyBar.color_for(0.2)).is_equal(EnergyBar.LOW_COLOR)
	assert_float(bar.custom_minimum_size.x).override_failure_message("it asks for its own room").is_greater(float(EnergyBar.WIDTH))


func test_the_huds_corner_fits_what_it_holds() -> void:
	var village: AreaController = _load(VILLAGE)
	var hud: AreaHud = village.hud
	assert_bool(hud.energy.visible).override_failure_message("no energy bar before the energy rules (P2)").is_false()
	var plain: Vector2 = hud.panel_size()
	assert_float(plain.y).override_failure_message("hearts and where you are").is_greater(24.0)
	hud.show_energy(true)
	hud.set_energy(60.0, 100.0)
	assert_float(hud.energy.fraction()).is_equal_approx(0.6, 0.001)
	var with_bar: Vector2 = hud.panel_size()
	assert_float(with_bar.y).override_failure_message("taller with the bar").is_greater(plain.y)
	assert_float(with_bar.x).override_failure_message("and no wider").is_equal(plain.x)
	hud.show_energy(false)
	assert_that(hud.panel_size()).override_failure_message("and back").is_equal(plain)
	assert_int(hud.hearts.rows()).is_equal(1)
	hud.set_health(24, 24)
	assert_int(hud.hearts.rows()).override_failure_message("twelve hearts take two rows").is_equal(2)
	hud._fit_panel()
	assert_float(hud.panel_size().y).override_failure_message("taller with a second row of hearts").is_greater(plain.y)
	hud.set_health(20, 20)
	hud.set_pieces(2)
	assert_int(hud.hearts.rows()).override_failure_message("ten hearts and a piece heart: the piece starts a row").is_equal(2)
	var corner: Control = hud.get_node(^"Panel")
	assert_bool(corner.position.x + hud.panel_size().x < SCREEN.x / 2.0).override_failure_message("it keeps to its corner").is_true()


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area
