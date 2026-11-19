extends GdUnitTestSuite
## The art is PNG (2026-11-19, docs/progress/png-art-plan.md): every picture the game shows is
## checked against art/sheets.json, so a wrong export fails here and not in the game. Its size and
## frames; the names the game's scripts give the frames; the white flash rows; the hero's and the
## villagers' feet; the villagers' marker colours; the trees in their cells; no half-clear pixels in
## the sprites; and lossless import with no mipmaps.

const ArtSheets: GDScript = preload("res://tests/support/art_sheets.gd")


func test_the_list_names_every_art_png_in_the_game() -> void:
	var listed: Array = []
	for entry: Dictionary in ArtSheets.all():
		listed.append(str(entry["path"]))
	assert_int(listed.size()).override_failure_message("art/sheets.json is read").is_equal(27)
	for dir: String in ["res://gameplay/art", "res://gameplay/player", "res://world/tiles", "res://ui/title"]:
		for file: String in DirAccess.get_files_at(dir):
			if file.ends_with(".png"):
				assert_array(listed).override_failure_message("%s is listed" % dir.path_join(file)).contains([dir.path_join(file)])


func test_every_png_is_the_size_its_frames_make() -> void:
	for entry: Dictionary in ArtSheets.all():
		var image: Image = ArtSheets.image(entry)
		assert_object(image).override_failure_message("%s exists" % entry["path"]).is_not_null()
		var expected: Vector2i
		match str(entry["kind"]):
			"strip":
				var frame: Array = entry["frame"]
				expected = Vector2i(int(frame[0]) * (entry["frames"] as Array).size(), int(frame[1]) * (2 if entry["flash_row"] else 1))
			"grid":
				var frame: Array = entry["frame"]
				expected = Vector2i(int(frame[0]) * (entry["frames"] as Array).size(), int(frame[1]) * (entry["rows"] as Array).size())
			_:
				expected = Vector2i(int(entry["size"][0]), int(entry["size"][1]))
		assert_that(image.get_size()).override_failure_message("%s: its size" % entry["path"]).is_equal(expected)


func test_the_game_names_the_frames_in_the_order_they_stand() -> void:
	var named: Dictionary = {
		"slime": Enemy.SLIME_FRAMES, "wisp": Enemy.WISP_FRAMES, "bat": Enemy.BAT_FRAMES, "goblin": Enemy.GOBLIN_FRAMES,
		"warden": Boss.FRAMES, "villager": Villager.FRAMES, "items": ItemIcons.FRAMES, "soil": FarmPlot.FRAMES,
		"crops": FarmPlot.CROP_FRAMES, "forage": ForageSpot.FRAMES, "crystal": CrystalSwitch.FRAMES, "rocks": Rock.FRAMES,
		"crafted": Furnishing.FRAMES, "breakables": Breakable.FRAMES, "critters": Critter.FRAMES, "animals": Animal.FRAMES,
		"torch": Torch.FRAMES, "shade": ShadeBoss.FRAMES, "placed": PlacedArt.FRAMES,
	}
	for file: String in named:
		var frames: Array = ArtSheets.frames(file)
		var used: Dictionary = named[file]
		assert_int(used.size()).override_failure_message("%s: every frame named" % file).is_equal(frames.size())
		for frame: StringName in used:
			assert_int(frames.find(String(frame))).override_failure_message("%s/%s" % [file, frame]).is_equal(int(used[frame]))
	assert_array(ArtSheets.frames("held_tools")).is_equal(Array(HeldTools.frame_names()))
	assert_array(ArtSheets.frames("scenery")).is_equal(Array(SceneryAtlas.KINDS))
	var hero: Dictionary = ArtSheets.sheet("player_sheet")
	assert_int((hero["frames"] as Array).size()).is_equal(PlayerAnimator.COLUMNS)
	assert_array(hero["rows"]).override_failure_message("rows in Facing order").is_equal(["down", "up", "side"])
	var columns: Dictionary = {
		"idle": PlayerAnimator.IDLE, "blink": PlayerAnimator.BLINK, "walk_1": PlayerAnimator.WALK_1, "walk_6": PlayerAnimator.WALK_6,
		"windup": PlayerAnimator.WINDUP, "slash": PlayerAnimator.ATTACK, "follow": PlayerAnimator.FOLLOW, "hold": PlayerAnimator.HOLD,
		"fallen": PlayerAnimator.FALLEN, "breathe": PlayerAnimator.BREATHE, "hurt": PlayerAnimator.HURT, "run_1": PlayerAnimator.RUN_1,
		"run_6": PlayerAnimator.RUN_6, "raise": PlayerAnimator.RAISE, "strike": PlayerAnimator.STRIKE, "pour": PlayerAnimator.POUR,
		"reach": PlayerAnimator.REACH,
	}
	for column: String in columns:
		assert_int((hero["frames"] as Array).find(column)).override_failure_message("the hero's %s" % column).is_equal(int(columns[column]))
	var tiles: Dictionary = ArtSheets.sheet("greybox_tiles")
	assert_that(Vector2i(tiles["size"][0], tiles["size"][1])).is_equal(Vector2i(GreyboxTiles.COLUMNS, GreyboxTiles.ROWS) * GreyboxTiles.TILE_SIZE)
	assert_that(Vector2i(ArtSheets.sheet("relief")["size"][0], ArtSheets.sheet("relief")["size"][1])).is_equal(ReliefAtlas.SIZE)
	assert_that(Vector2i(ArtSheets.sheet("backdrop")["size"][0], ArtSheets.sheet("backdrop")["size"][1])).is_equal(TitlePicture.SIZE)


func test_every_sheet_with_a_flash_row_has_its_frames_in_white_beneath() -> void:
	for entry: Dictionary in ArtSheets.all():
		if not entry.get("flash_row", false):
			continue
		var image: Image = ArtSheets.image(entry)
		var half: int = image.get_height() / 2
		var painted: int = 0
		for y: int in half:
			for x: int in image.get_width():
				var top: Color = image.get_pixel(x, y)
				var flash: Color = image.get_pixel(x, y + half)
				if top.a != flash.a:
					assert_float(flash.a).override_failure_message("%s (%d, %d): the flash has the same shape" % [entry["path"], x, y]).is_equal(top.a)
					return
				if top.a > 0.0:
					painted += 1
					if not flash.is_equal_approx(Color.WHITE):
						assert_bool(false).override_failure_message("%s (%d, %d): the flash is white" % [entry["path"], x, y + half]).is_true()
						return
		assert_int(painted).override_failure_message("%s has something painted" % entry["path"]).is_greater(20)


func test_no_sprite_has_half_clear_pixels() -> void:
	for entry: Dictionary in ArtSheets.all():
		if not str(entry["kind"]) in ["strip", "grid", "picture"]:
			continue
		var image: Image = ArtSheets.image(entry)
		for y: int in image.get_height():
			for x: int in image.get_width():
				var alpha: float = image.get_pixel(x, y).a
				if alpha > 0.0 and alpha < 1.0:
					assert_bool(false).override_failure_message("%s (%d, %d) is half clear" % [entry["path"], x, y]).is_true()
					return


func test_the_hero_and_the_villagers_stand_on_their_frames_last_row() -> void:
	for file: String in ["player_sheet", "villager"]:
		var entry: Dictionary = ArtSheets.sheet(file)
		var image: Image = ArtSheets.image(entry)
		var frame: Vector2i = Vector2i(entry["frame"][0], entry["frame"][1])
		var rows: int = (entry["rows"] as Array).size() if entry.has("rows") else 1
		for row: int in rows:
			for column: int in (entry["frames"] as Array).size():
				var painted: int = 0
				var soles: int = 0
				for y: int in frame.y:
					for x: int in frame.x:
						if image.get_pixel(column * frame.x + x, row * frame.y + y).a > 0.0:
							painted += 1
							soles += 1 if y == frame.y - 1 else 0
				var name: String = "%s row %d %s" % [file, row, entry["frames"][column]]
				assert_int(painted).override_failure_message("%s is painted" % name).is_greater(40)
				assert_int(soles).override_failure_message("%s stands on the frame's last row" % name).is_greater(0)


func test_villagers_are_painted_in_the_marker_colours_and_nothing_near_them() -> void:
	var entry: Dictionary = ArtSheets.sheet("villager")
	var image: Image = ArtSheets.image(entry)
	var markers: Array[Color] = [Villager.ROBE_MARK, Villager.ROBE_SHADE_MARK, Villager.HAIR_MARK, Villager.HAIR_SHADE_MARK]
	for hex: String in (entry["markers"] as Dictionary).values():
		assert_bool(markers.any(func(m: Color) -> bool: return SpriteSheet._close(Color(hex), m))).override_failure_message("%s is one of Villager's marks" % hex).is_true()
	var found: Array[int] = [0, 0, 0, 0]
	for y: int in image.get_height() / 2:
		for x: int in image.get_width():
			var pixel: Color = image.get_pixel(x, y)
			if pixel.a == 0.0:
				continue
			for i: int in markers.size():
				if SpriteSheet._close(pixel, markers[i]):
					found[i] += 1
				else:
					var near: bool = absf(pixel.r - markers[i].r) < 0.05 and absf(pixel.g - markers[i].g) < 0.05 and absf(pixel.b - markers[i].b) < 0.05
					assert_bool(near).override_failure_message("(%d, %d) is near a marker but not it" % [x, y]).is_false()
	for i: int in found.size():
		assert_int(found[i]).override_failure_message("marker %d is used" % i).is_greater(0)


func test_each_tree_stands_in_its_cell_with_clear_padding_round_it() -> void:
	var entry: Dictionary = ArtSheets.sheet("scenery")
	var image: Image = ArtSheets.image(entry)
	var cell: Vector2i = Vector2i(entry["cell"][0], entry["cell"][1])
	var pad: Vector2i = Vector2i(entry["pad"][0], entry["pad"][1])
	var picture: Rect2i = Rect2i(pad, Vector2i(entry["frame"][0], entry["frame"][1]))
	var foot: Vector2i = Vector2i(entry["pivot"][0], entry["pivot"][1])
	for index: int in (entry["frames"] as Array).size():
		var trunk: bool = false
		for y: int in cell.y:
			for x: int in cell.x:
				var alpha: float = image.get_pixel(index * cell.x + x, y).a
				if not picture.has_point(Vector2i(x, y)):
					assert_float(alpha).override_failure_message("%s: the padding is clear at (%d, %d)" % [entry["frames"][index], x, y]).is_equal(0.0)
				elif y - pad.y == foot.y and absi(x - pad.x - foot.x) <= 3 and alpha > 0.0:
					trunk = true
		assert_bool(trunk).override_failure_message("%s: its trunk reaches its foot" % entry["frames"][index]).is_true()


func test_every_art_png_imports_lossless_without_mipmaps() -> void:
	for entry: Dictionary in ArtSheets.all():
		var settings: String = FileAccess.get_file_as_string(str(entry["path"]) + ".import")
		assert_str(settings).override_failure_message("%s: lossless" % entry["path"]).contains("compress/mode=0")
		assert_str(settings).override_failure_message("%s: no mipmaps" % entry["path"]).contains("mipmaps/generate=false")
