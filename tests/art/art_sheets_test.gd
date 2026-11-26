extends GdUnitTestSuite
## The art is PNG (2026-11-19, docs/progress/png-art-plan.md): every picture the game shows is
## checked against art/sheets.json, so a wrong export fails here and not in the game. Its size and
## frames; the names the game's scripts give the frames; the white flash rows; the hero's and the
## villagers' feet; the villagers' eight figures; the trees in their cells; no half-clear pixels in
## the sprites; and lossless import with no mipmaps.

const ArtSheets: GDScript = preload("res://tests/support/art_sheets.gd")


func test_the_list_names_every_art_png_in_the_game() -> void:
	var listed: Array = []
	for entry: Dictionary in ArtSheets.all():
		listed.append(str(entry["path"]))
	assert_int(listed.size()).override_failure_message("art/sheets.json is read").is_equal(30)
	for dir: String in ["res://gameplay/art", "res://gameplay/player", "res://world/tiles", "res://ui/title", "res://ui/art"]:
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
		"ground_details": GroundDetails.FRAMES,
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
	assert_that(Vector2i(ArtSheets.sheet("ground_edges")["size"][0], ArtSheets.sheet("ground_edges")["size"][1])).is_equal(EdgeAtlas.SIZE)
	var trees: Dictionary = ArtSheets.sheet("scenery")
	assert_that(Vector2i(trees["cell"][0], trees["cell"][1])).is_equal(SceneryAtlas.CELL)
	assert_that(Vector2i(trees["frame"][0], trees["frame"][1])).is_equal(SceneryAtlas.SIZE)
	assert_that(Vector2(trees["pivot"][0], trees["pivot"][1])).is_equal(SceneryAtlas.FOOT)
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


func test_the_hero_and_the_villagers_stand_on_their_feet() -> void:
	# A villager's soles are on the frame's last row. The hero's are on the row above his pivot
	# (farm-look plan, phase E: the art pack's frame, with room below his feet for a lunge or a
	# fall), and his standing and walking frames are on it exactly.
	for file: String in ["player_sheet", "villager"]:
		var entry: Dictionary = ArtSheets.sheet(file)
		var image: Image = ArtSheets.image(entry)
		var frame: Vector2i = Vector2i(entry["frame"][0], entry["frame"][1])
		var soles_row: int = frame.y - 1 if file == "villager" else int(entry["pivot"][1]) - 1
		var rows: int = (entry["rows"] as Array).size() if entry.has("rows") else 1
		for row: int in rows:
			for column: int in (entry["frames"] as Array).size():
				var painted: int = 0
				var lowest: int = -1
				for y: int in frame.y:
					for x: int in frame.x:
						if image.get_pixel(column * frame.x + x, row * frame.y + y).a > 0.0:
							painted += 1
							lowest = y
				var frame_name: String = str(entry["frames"][column])
				var name: String = "%s row %d %s" % [file, row, frame_name]
				assert_int(painted).override_failure_message("%s is painted" % name).is_greater(40)
				if file == "villager" or frame_name == "idle" or frame_name.begins_with("walk_"):
					assert_int(lowest).override_failure_message("%s stands on its soles' row" % name).is_equal(soles_row)
				else:
					assert_int(lowest).override_failure_message("%s stands on its feet" % name).is_between(soles_row, soles_row + 4)


func test_villagers_are_eight_short_figures_each_their_own() -> void:
	# The farm-look plan, phase D (F3 and F5): the art pack's short people, one figure for each
	# villager (resting, breathing, blinking), painted in the frame's lower half only.
	var entry: Dictionary = ArtSheets.sheet("villager")
	var image: Image = ArtSheets.image(entry)
	var frame: Vector2i = Vector2i(entry["frame"][0], entry["frame"][1])
	assert_int((entry["frames"] as Array).size()).is_equal(Villager.FIGURES.size() * 3)
	var faces: Dictionary = {}
	for index: int in (entry["frames"] as Array).size():
		var picture: Image = image.get_region(Rect2i(index * frame.x, 0, frame.x, frame.y))
		var used: Rect2i = picture.get_used_rect()
		var name: String = entry["frames"][index]
		assert_int(used.position.y).override_failure_message("%s is short: nothing above the frame's middle" % name).is_greater_equal(frame.y / 2)
		if index % 3 == 0:
			faces[picture.get_data()] = name
		else:
			var rest: Image = image.get_region(Rect2i((index - index % 3) * frame.x, 0, frame.x, frame.y))
			assert_bool(picture.get_data() == rest.get_data()).override_failure_message("%s differs from its resting frame" % name).is_false()
	assert_int(faces.size()).override_failure_message("eight faces, no two alike").is_equal(Villager.FIGURES.size())


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
