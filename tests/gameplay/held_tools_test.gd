extends GdUnitTestSuite
## The tools in the hero's hands (tool polish, 2026-11-19): HeldTools names the frames
## tools/art/make_sprites.gd paints (HELD), in its order; every tool, and the sprinkler, has a
## picture for every facing and pose its strokes use; the sheet is painted with its flash row; and
## a frame's feet are in its middle, so it mirrors in place.

const TOOL: String = "res://tools/art/make_sprites.gd"


func test_the_frames_are_the_ones_the_tool_paints_in_its_order() -> void:
	var tool: GDScript = load(TOOL)
	var painted: Array = (tool.call(&"frames_of", tool.call(&"held_sprite")) as Dictionary).keys()
	assert_array(painted).is_equal(Array(HeldTools.frame_names()))
	var held: Dictionary = tool.get_script_constant_map()["HELD"]
	assert_that(held["size"]).is_equal(HeldTools.SIZE)
	assert_array(held["metalled"]).is_equal(Array(HeldTools.METALLED))
	assert_array((held["metals"] as Dictionary).keys()).is_equal(Array(HeldTools.METALS))


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
	assert_int(held).override_failure_message("three hoes, three cans, three pickaxes, the sprinkler").is_equal(10)


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


func test_the_metals_differ_only_in_the_head() -> void:
	var image: Image = HeldTools.SHEET.get_image()
	var plain: int = HeldTools.frame_of(&"hoe", "side", ToolStroke.RAISE)
	var copper: int = HeldTools.frame_of(&"copper_hoe", "side", ToolStroke.RAISE)
	var differ: int = 0
	for x: int in HeldTools.SIZE.x:
		for y: int in HeldTools.SIZE.y:
			var a: Color = image.get_pixel(plain * HeldTools.SIZE.x + x, y)
			var b: Color = image.get_pixel(copper * HeldTools.SIZE.x + x, y)
			assert_float(a.a).is_equal(b.a)
			# (A clear pixel's colour is the importer's: only what is painted counts.)
			if a.a > 0.0 and not a.is_equal_approx(b):
				differ += 1
	# The head, and the outline round it (which takes a shade of what it surrounds).
	assert_int(differ).override_failure_message("the head is copper: %d pixels" % differ).is_between(4, 40)


func _painted(image: Image, frame: int) -> int:
	var count: int = 0
	for x: int in HeldTools.SIZE.x:
		for y: int in HeldTools.SIZE.y:
			if image.get_pixel(frame * HeldTools.SIZE.x + x, y).a > 0.0:
				count += 1
	return count
