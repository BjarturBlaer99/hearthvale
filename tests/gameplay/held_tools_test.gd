extends GdUnitTestSuite
## The tools in the hero's hands (tool polish, 2026-11-19): HeldTools names the frames of
## held_tools.png as art/sheets.json lists them; every tool, and the sprinkler, has a picture for
## every facing and pose its strokes use; the sheet has its flash row; and a frame's feet are in its
## middle, so it mirrors in place.

const ArtSheets: GDScript = preload("res://tests/support/art_sheets.gd")


func test_the_frames_are_the_ones_the_sheet_list_names_in_its_order() -> void:
	var sheet: Dictionary = ArtSheets.sheet("held_tools")
	assert_array(sheet["frames"]).is_equal(Array(HeldTools.frame_names()))
	assert_that(Vector2i(sheet["frame"][0], sheet["frame"][1])).is_equal(HeldTools.SIZE)
	assert_that(Vector2i(sheet["pivot"][0], sheet["pivot"][1])).is_equal(HeldTools.FEET)


func test_the_sheet_is_painted_with_a_flash_row() -> void:
	var count: int = HeldTools.frame_names().size()
	assert_that(Vector2i(HeldTools.SHEET.get_size())).is_equal(Vector2i(HeldTools.SIZE.x * count, HeldTools.SIZE.y * 2))
	var image: Image = HeldTools.SHEET.get_image()
	for x: int in HeldTools.SIZE.x * count:
		for y: int in HeldTools.SIZE.y:
			assert_float(image.get_pixel(x, y + HeldTools.SIZE.y).a).override_failure_message("(%d, %d)" % [x, y]).is_equal(image.get_pixel(x, y).a)


func test_a_frame_mirrors_about_his_feet() -> void:
	assert_int(HeldTools.FEET.x * 2).override_failure_message("the feet are in the middle").is_equal(HeldTools.SIZE.x)
	assert_that((auto_free(HeldTool.new()) as HeldTool).position).is_equal(-Vector2(HeldTools.FEET))


func test_every_tool_and_the_sprinkler_is_held() -> void:
	var held: int = 0
	for item: Dictionary in DataRegistry.entries(&"items"):
		var kind: String = ToolUse.kind_of(item)
		if kind.is_empty() or kind == ToolUse.SEED:
			continue
		held += 1
		var id: StringName = StringName(str(item["id"]))
		assert_bool(HeldTools.has_item(id)).override_failure_message("%s is held" % id).is_true()
	assert_int(held).override_failure_message("three hoes, three cans, three pickaxes, three axes, the sprinkler").is_equal(13)


func test_each_stroke_has_its_pictures_and_shows_something_but_from_behind() -> void:
	var image: Image = HeldTools.SHEET.get_image()
	var strokes: Dictionary = {
		ToolStroke.HOE: [&"hoe", &"copper_hoe", &"iron_hoe"], ToolStroke.PICK: [&"pickaxe", &"copper_pickaxe", &"iron_pickaxe"],
		ToolStroke.POUR: [&"watering_can", &"copper_watering_can", &"iron_watering_can"],
		ToolStroke.FILL: [&"watering_can", &"iron_watering_can"], ToolStroke.PLACE: [&"sprinkler"],
	}
	for kind: StringName in strokes:
		for item_id: StringName in strokes[kind]:
			for facing: String in HeldTools.FACINGS:
				for progress: float in [0.0, 0.9]:
					if not ToolStroke.holds(kind, progress):
						continue
					var pose: StringName = ToolStroke.pose(kind, progress)
					var frame: int = HeldTools.frame_of(item_id, facing, pose)
					assert_int(frame).override_failure_message("%s %s %s" % [item_id, facing, pose]).is_greater_equal(0)
					var painted: int = _painted(image, frame)
					if facing != "up":
						assert_int(painted).override_failure_message("%s %s %s shows" % [item_id, facing, pose]).is_greater(20)
	assert_int(HeldTools.frame_of(&"wooden_sword", "side", ToolStroke.STRIKE)).override_failure_message("the sword is drawn by Sword").is_equal(-1)


func _painted(image: Image, frame: int) -> int:
	var count: int = 0
	for x: int in HeldTools.SIZE.x:
		for y: int in HeldTools.SIZE.y:
			if image.get_pixel(frame * HeldTools.SIZE.x + x, y).a > 0.0:
				count += 1
	return count
