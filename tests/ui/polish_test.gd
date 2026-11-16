extends GdUnitTestSuite
## UI polish (P1f): a second, larger letter face for headings; the frame's corner brackets and
## the rule under a heading; the title screen's painted evening; and a HUD corner as wide as
## its words, with no line for nothing.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")
const FontTool: GDScript = preload("res://tools/art/make_font.gd")
const TitleTool: GDScript = preload("res://tools/art/make_title.gd")

const VILLAGE: String = "res://world/areas/village/village.tscn"
const TITLE: String = "res://ui/title_screen.tscn"
const ENDING: String = "res://ui/ending_screen.tscn"
const SCREEN: Vector2 = Vector2(640, 360)

var _area: Node


func before_test() -> void:
	GameState.clear()
	GameState.new_game()


func after_test() -> void:
	if is_instance_valid(_area):
		_area.free()
	_area = null
	GameState.clear()


func test_the_heading_face_has_capitals_digits_and_marks_and_a_small_letter_shows_as_its_capital() -> void:
	var font: FontFile = load(FontTool.HEADING_PATH)
	var size: Vector2i = Vector2i(FontTool.HEADING_SIZE, 0)
	assert_int(font.fixed_size).is_equal(FontTool.HEADING_SIZE)
	assert_int(FontTool.HEADING_SIZE).override_failure_message("twice the small face, so both stay in whole pixels").is_equal(FontTool.SIZE * 2)
	assert_int(font.fixed_size_scale_mode).override_failure_message("scaled by whole numbers only").is_equal(TextServer.FIXED_SIZE_SCALE_INTEGER_ONLY)
	var baked: PackedInt32Array = font.get_glyph_list(0, size)
	for letter: String in "ABCDEFGHIJKLMNOPQRSTUVWXYZ":
		assert_bool(FontTool.HEADING.has(letter)).override_failure_message("the tool draws '%s'" % letter).is_true()
		assert_bool(baked.has(letter.unicode_at(0))).override_failure_message("a glyph for '%s'" % letter).is_true()
		var small: int = letter.to_lower().unicode_at(0)
		assert_bool(baked.has(small)).override_failure_message("and one for '%s'" % letter.to_lower()).is_true()
		assert_that(font.get_glyph_uv_rect(0, size, small)).override_failure_message("'%s' shows as its capital" % letter.to_lower()).is_equal(font.get_glyph_uv_rect(0, size, letter.unicode_at(0)))
		var rows: PackedStringArray = FontTool.heading_rows(letter)
		assert_int(rows.size()).override_failure_message("'%s' stands twelve rows tall (Q's tail hangs below)" % letter).is_equal(14 if letter == "Q" else 12)
		assert_bool("#" in rows[0] and "#" in rows[11]).override_failure_message("'%s' reaches from the capital height to the line" % letter).is_true()
	for digit: String in "0123456789":
		assert_bool(baked.has(digit.unicode_at(0))).override_failure_message("a glyph for '%s'" % digit).is_true()
	assert_bool(baked.has(" ".unicode_at(0))).is_true()
	for key: String in FontTool.HEADING:
		var rows: PackedStringArray = FontTool.heading_rows(key)
		assert_int(rows.size()).override_failure_message("'%s' fits its cell's height" % key).is_less_equal(FontTool.HEADING_ROWS)
		assert_int(rows[0].length()).override_failure_message("'%s' fits its cell's width" % key).is_between(1, FontTool.HEADING_CELL.x - 1)
	# Slanted letters are tucked together.
	var apart: float = font.get_string_size("VV", HORIZONTAL_ALIGNMENT_LEFT, -1, FontTool.HEADING_SIZE).x + font.get_string_size("AA", HORIZONTAL_ALIGNMENT_LEFT, -1, FontTool.HEADING_SIZE).x
	var together: float = font.get_string_size("VAVA", HORIZONTAL_ALIGNMENT_LEFT, -1, FontTool.HEADING_SIZE).x
	assert_float(together).override_failure_message("V and A stand closer than their widths").is_less(apart)


func test_every_heading_is_set_in_the_heading_face() -> void:
	var theme: Theme = ThemeDB.get_project_theme()
	assert_that(theme.get_type_variation_base(FontTool.HEADING_KIND)).override_failure_message("a heading is a kind of label").is_equal(&"Label")
	assert_object(theme.get_font(&"font", FontTool.HEADING_KIND)).is_same(load(FontTool.HEADING_PATH))
	var village: AreaController = _load(VILLAGE)
	var pause: PauseMenu = village.hud.pause_menu
	var boxes: Dictionary = {
		"Paused": pause.get_node(^"Panel"), "Food": village.hud.item_menu.get_node(^"Panel"),
		"Settings": pause.get_node(^"SettingsMenu/Panel"), "Quests": pause.get_node(^"QuestLog/Panel"),
	}
	for words: String in boxes:
		var box: PanelFrame = boxes[words]
		var heading: Label = box.get_node(^"Title")
		assert_str(heading.text).is_equal(words)
		_assert_heading(heading, FontTool.HEADING_SIZE)
		assert_float(box.rule_y).override_failure_message("%s: a rule under the heading" % words).is_greater(heading.position.y + FontTool.HEADING_BASE)
		for child: Node in box.get_children():
			if child != heading and child is Control:
				assert_float((child as Control).position.y).override_failure_message("%s: %s starts below the rule" % [words, child.name]).is_greater(box.rule_y + PanelFrame.DIAMOND)
		assert_bool(box.size.y <= SCREEN.y - 8.0).override_failure_message("%s still fits the screen" % words).is_true()
	village.free()
	_area = null
	for path: String in [TITLE, ENDING]:
		var screen: Control = (load(path) as PackedScene).instantiate()
		get_tree().root.add_child(screen)
		_area = screen
		_assert_heading(screen.get_node(^"Title"), FontTool.HEADING_SIZE * 2)
		screen.free()
		_area = null


func test_the_frame_has_a_bracket_in_each_corner_and_a_rule_under_a_heading() -> void:
	var box: Vector2 = Vector2(220.0, 204.0)
	var arms: Array[Rect2] = PanelFrame.bracket_arms(box)
	assert_int(arms.size()).override_failure_message("two arms to a corner").is_equal(8)
	var whole: Rect2 = Rect2(Vector2.ZERO, box)
	for corner: Vector2 in [Vector2.ZERO, Vector2(box.x - 1.0, 0.0), Vector2(0.0, box.y - 1.0), box - Vector2.ONE]:
		var touching: int = 0
		for arm: Rect2 in arms:
			assert_bool(whole.encloses(arm)).override_failure_message("an arm stays inside the box: %s" % arm).is_true()
			touching += 1 if arm.has_point(corner) else 0
		assert_int(touching).override_failure_message("both arms meet at the corner %s" % corner).is_equal(2)
	var parts: Array[Rect2] = PanelFrame.rule_parts(box, 25.0)
	assert_int(parts.size()).override_failure_message("the rule runs either side of its diamond").is_equal(2)
	assert_float(parts[0].position.x).is_equal(PanelFrame.RULE_MARGIN)
	assert_float(parts[1].end.x).override_failure_message("as far from the right side as from the left").is_equal(box.x - PanelFrame.RULE_MARGIN)
	assert_float(parts[0].size.x).override_failure_message("both halves the same length").is_equal_approx(parts[1].size.x, 1.0)
	var diamond: Array[Rect2] = PanelFrame.diamond_rows(box, 25.0)
	assert_int(diamond.size()).is_equal(PanelFrame.DIAMOND * 2 + 1)
	assert_float(diamond[PanelFrame.DIAMOND].get_center().x).override_failure_message("in the middle of the box").is_equal_approx(box.x / 2.0, 0.6)
	assert_float(diamond[0].size.x).override_failure_message("a point at the top").is_equal(1.0)
	assert_float(diamond[PanelFrame.DIAMOND].size.x).override_failure_message("widest on the rule").is_equal(PanelFrame.DIAMOND * 2.0 + 1.0)
	assert_bool(parts[0].end.x < diamond[PanelFrame.DIAMOND].position.x and parts[1].position.x > diamond[PanelFrame.DIAMOND].end.x).override_failure_message("a gap between the rule and its diamond").is_true()
	assert_array(PanelFrame.rule_parts(box, 0.0)).override_failure_message("no heading, no rule").is_empty()
	assert_array(PanelFrame.rule_parts(Vector2(16.0, 40.0), 25.0)).override_failure_message("too narrow for one").is_empty()
	var village: AreaController = _load(VILLAGE)
	assert_float((village.hud.get_node(^"Panel") as PanelFrame).rule_y).override_failure_message("the HUD's corner has no heading").is_equal(0.0)
	assert_float((village.hud.dialogue.get_node(^"Panel") as PanelFrame).rule_y).override_failure_message("nor the dialogue box").is_equal(0.0)


func test_the_title_shows_a_painted_evening_with_the_keeps_window_lit() -> void:
	var picture: Texture2D = load(TitlePicture.TEXTURE_PATH)
	assert_that(Vector2i(picture.get_size())).override_failure_message("the size of the screen").is_equal(TitlePicture.SIZE)
	assert_that(Vector2(TitlePicture.SIZE)).is_equal(SCREEN)
	var image: Image = picture.get_image()
	var top: Color = image.get_pixel(320, 0)
	# Above the far hills (the highest of them tops out below this), clear of the clouds.
	var low_sky: Color = image.get_pixel(40, 168)
	var foot: Color = image.get_pixel(300, 300)
	var same_sky: int = 0
	for x: int in TitlePicture.SIZE.x:
		same_sky += 1 if PixelGrade.same(image.get_pixel(x, 0), PixelGrade.warm(TitlePicture.SKY_TOP)) else 0
	assert_int(same_sky).override_failure_message("the sky above the picture is the sky at its top (but for a star or two)").is_greater(TitlePicture.SIZE.x - 12)
	assert_bool(top.b > top.r and top.get_luminance() < 0.2).override_failure_message("night at the top").is_true()
	assert_bool(low_sky.r > low_sky.b and low_sky.get_luminance() > 0.4).override_failure_message("the last light low in the sky: %s" % low_sky).is_true()
	assert_bool(foot.g > foot.r and foot.g > foot.b).override_failure_message("grass at the foot").is_true()
	for corner: Vector2i in [Vector2i.ZERO, TitlePicture.SIZE - Vector2i.ONE, Vector2i(0, TitlePicture.SIZE.y - 1)]:
		assert_float(image.get_pixelv(corner).a).override_failure_message("painted to its edges").is_equal(1.0)
	var window: Rect2i = TitlePicture.WINDOW
	assert_float(image.get_pixelv(window.get_center()).get_luminance()).override_failure_message("the window is dark in the picture: the screen lights it").is_less(0.1)
	for star: Vector2i in TitlePicture.STARS:
		assert_bool(star.y < TitlePicture.HORIZON - 60 and star.x >= 0 and star.x < TitlePicture.SIZE.x).override_failure_message("a star in the sky: %s" % star).is_true()
	assert_int(TitlePicture.crowns().size()).is_equal(TitlePicture.CHERRY_FEET.size())
	for foot_at: Vector2i in TitlePicture.CHERRY_FEET:
		assert_bool(foot_at.y > TitleTool.ground_top(foot_at.x)).override_failure_message("a cherry tree stands on the village's ground: %s" % foot_at).is_true()
		var blossom: Color = image.get_pixelv(foot_at - Vector2i(0, TitlePicture.CROWN_RISE))
		assert_bool(blossom.r > blossom.g).override_failure_message("in blossom: %s" % foot_at).is_true()
	# Dithering mixes two colours a share at a time.
	var mixed: int = 0
	for y: int in 4:
		for x: int in 4:
			assert_bool(TitleTool.dithered(x, y, 0.0)).is_false()
			assert_bool(TitleTool.dithered(x, y, 1.0)).is_true()
			mixed += 1 if TitleTool.dithered(x, y, 0.5) else 0
	assert_int(mixed).override_failure_message("half and half").is_equal(8)
	# On the screen.
	var title: TitleScreen = (load(TITLE) as PackedScene).instantiate()
	get_tree().root.add_child(title)
	_area = title
	assert_bool(title.backdrop.keep_lit).is_true()
	assert_object(title.backdrop.get_node(^"Petals")).override_failure_message("petals on the wind").is_not_null()
	# A backdrop of its own, free to be any size (the title's fills the screen).
	var backdrop: TitleBackdrop = auto_free(TitleBackdrop.new())
	add_child(backdrop)
	backdrop.size = SCREEN
	assert_that(backdrop.origin()).is_equal(Vector2.ZERO)
	assert_that(backdrop.window()).is_equal(Rect2(window))
	backdrop.size = Vector2(700.0, 400.0)
	assert_that(backdrop.origin()).override_failure_message("in the middle, its foot on the screen's foot").is_equal(Vector2(30.0, 40.0))
	assert_that(backdrop.window().position).is_equal(Vector2(window.position) + Vector2(30.0, 40.0))
	assert_that(backdrop.get_node(^"Petals").position).override_failure_message("the petals move with the picture").is_equal(Vector2(30.0, 40.0))
	var seen: Dictionary = {}
	for i: int in 120:
		backdrop._process(1.0 / 30.0)
		for star: Vector2i in TitlePicture.STARS:
			assert_float(backdrop.twinkle(star)).is_between(0.0, 1.0)
		seen[snappedf(backdrop.twinkle(TitlePicture.STARS[0]) - backdrop.twinkle(TitlePicture.STARS[1]), 0.05)] = true
	assert_int(seen.size()).override_failure_message("the stars don't twinkle as one").is_greater(3)


func test_the_huds_corner_is_as_wide_as_its_words_and_says_nothing_about_nothing() -> void:
	var village: AreaController = _load(VILLAGE)
	var hud: AreaHud = village.hud
	village._update_hud()
	assert_array(Array(hud.shown_lines())).override_failure_message("nothing carried, nothing in hand: only when and where you are").is_equal([GameState.time_text(), "Hearthvale"])
	var bare: Vector2 = hud.panel_size()
	assert_float(bare.x).override_failure_message("no wider than ten hearts need").is_less(120.0)
	GameState.add_item(&"wooden_sword")
	village._update_hud()
	assert_array(Array(hud.shown_lines())).is_equal([GameState.time_text(), "Hearthvale", "Carrying: Wooden Sword"])
	var carrying: Vector2 = hud.panel_size()
	assert_float(carrying.y).override_failure_message("a line taller").is_greater(bare.y)
	assert_float(carrying.x).override_failure_message("and as wide as the new line").is_greater(bare.x)
	var words: Label = hud.get_node(^"Panel/Box/Items")
	assert_float(carrying.x).override_failure_message("the words and the box's padding, no more").is_equal(AreaHud.line_width(words) + hud.get_node(^"Panel/Box").position.x * 2.0)
	GameState.add_item(&"bow")
	GameState.add_item(&"arrow", 10)
	GameState.equipped = &"bow"
	village._update_hud()
	assert_int(hud.shown_lines().size()).override_failure_message("and the item in hand").is_equal(4)
	assert_str(hud.shown_lines()[3]).is_equal(AreaController.equipped_text())
	hud.set_items("Carrying: " + "a very long list of things, ".repeat(8))
	assert_float(hud.panel_size().x).override_failure_message("never wider than its limit: the line ends in an ellipsis").is_equal(AreaHud.BOX_MAX + hud.get_node(^"Panel/Box").position.x * 2.0)
	hud.set_items("")
	hud.set_equipped("")
	assert_that(hud.panel_size()).override_failure_message("and back to where it began").is_equal(bare)


func _assert_heading(heading: Label, size: int) -> void:
	assert_that(heading.theme_type_variation).override_failure_message("%s is a heading" % heading.get_path()).is_equal(FontTool.HEADING_KIND)
	assert_object(heading.get_theme_font(&"font")).is_same(load(FontTool.HEADING_PATH))
	assert_int(heading.get_theme_font_size(&"font_size")).is_equal(size)
	var baked: PackedInt32Array = (load(FontTool.HEADING_PATH) as FontFile).get_glyph_list(0, Vector2i(FontTool.HEADING_SIZE, 0))
	for letter: String in heading.text:
		assert_bool(baked.has(letter.unicode_at(0))).override_failure_message("'%s' in \"%s\" can be set in the heading face" % [letter, heading.text]).is_true()


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area
