extends GdUnitTestSuite
## The three animal icons at the end of items.png (icons, an axe and the item bar, step I1),
## for Farmer Oda's list: the hen and the cow are the art pack's own first frames as they stand;
## the sheep is today's sheep cut to 16 wide (a gap: the pack has none), standing on the frame's
## last row but one. Each has its white silhouette in the flash row beneath, as every icon does.

const ArtSheets: GDScript = preload("res://tests/support/art_sheets.gd")

const ANIMAL_DIR: String = "res://art/packs/ninja-adventure/Ninja Adventure - Asset Pack/Actor/Animal/"
const SIZE: int = 16


func test_the_three_are_the_last_frames_in_their_order() -> void:
	var frames: Array = ArtSheets.frames("items")
	assert_array(frames.slice(frames.size() - 3)).is_equal(["hen", "sheep", "cow"])
	assert_int(int(ItemIcons.FRAMES[&"hen"])).is_equal(frames.size() - 3)
	assert_int(int(ItemIcons.FRAMES[&"cow"])).is_equal(frames.size() - 1)


func test_the_hen_and_the_cow_are_the_packs_own_frames() -> void:
	var items: Image = _items()
	var sources: Dictionary = {&"hen": "Chicken/SpriteSheetWhite.png", &"cow": "Cow/SpriteSheetWhite.png"}
	for icon: StringName in sources:
		var pack: Image = Image.load_from_file(ProjectSettings.globalize_path(ANIMAL_DIR + str(sources[icon])))
		pack.convert(Image.FORMAT_RGBA8)
		var at: int = int(ItemIcons.FRAMES[icon]) * SIZE
		for y: int in SIZE:
			for x: int in SIZE:
				var want: Color = pack.get_pixel(x, y)
				var got: Color = items.get_pixel(at + x, y)
				assert_bool(got.a > 0.5).override_failure_message("%s (%d, %d) is where the pack's is" % [icon, x, y]).is_equal(want.a > 0.5)
				if want.a > 0.5:
					assert_bool(got.is_equal_approx(Color(want.r, want.g, want.b, 1.0))).override_failure_message("%s (%d, %d) is the pack's colour" % [icon, x, y]).is_true()


func test_each_is_whole_with_its_white_silhouette_beneath() -> void:
	var items: Image = _items()
	for icon: StringName in [&"hen", &"sheep", &"cow"]:
		var at: int = int(ItemIcons.FRAMES[icon]) * SIZE
		var frame: Image = items.get_region(Rect2i(at, 0, SIZE, SIZE))
		var used: Rect2i = frame.get_used_rect()
		assert_int(used.size.x).override_failure_message("%s has a picture" % icon).is_greater(10)
		for y: int in SIZE:
			for x: int in SIZE:
				var seen: bool = items.get_pixel(at + x, y).a > 0.5
				var flash: Color = items.get_pixel(at + x, SIZE + y)
				assert_bool(flash.a > 0.5).override_failure_message("%s's flash (%d, %d)" % [icon, x, y]).is_equal(seen)
				if seen:
					assert_bool(flash.is_equal_approx(Color.WHITE)).is_true()
	var sheep: Rect2i = items.get_region(Rect2i(int(ItemIcons.FRAMES[&"sheep"]) * SIZE, 0, SIZE, SIZE)).get_used_rect()
	assert_int(sheep.size.x).override_failure_message("the sheep fills the frame's width").is_equal(SIZE)
	assert_int(sheep.end.y).override_failure_message("the sheep stands on row 15").is_equal(SIZE)


func _items() -> Image:
	var items: Image = ArtSheets.image(ArtSheets.sheet("items"))
	items.convert(Image.FORMAT_RGBA8)
	return items
