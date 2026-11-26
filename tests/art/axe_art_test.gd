extends GdUnitTestSuite
## The axe's pictures (icons, an axe and the item bar, step A1): three icons at the end of
## items.png and eighteen frames at the end of held_tools.png. The plain axe is the art pack's
## own, its icon (`Items/Tool/Axe.png`) and its axe layer cut in the windows the pickaxe was cut
## from (two of them moved a pixel along the flat handle, so the blade's tip stays in the frame);
## the copper and iron axes are the plain one in the bars' colours, as the pickaxes are. Every
## colour is the palette's or one the pickaxe of the same metal already wears (the pack's tools
## wear two its Palette.png lacks), and each frame holds the whole of the pack's axe.

const ArtSheets: GDScript = preload("res://tests/support/art_sheets.gd")

const PACK: String = "res://art/packs/ninja-adventure/Ninja Adventure - Asset Pack/"
const ICON: int = 16
const AXES: Array[StringName] = [&"axe", &"copper_axe", &"iron_axe"]
const POSES: Array[String] = ["down_raise", "down_strike", "up_raise", "up_strike", "side_raise", "side_strike"]
## Where each pose's frame lies in the pack's axe layer (the pickaxe's windows, two moved).
const WINDOWS: Dictionary = {
	"down_raise": Vector2i(12, 0), "down_strike": Vector2i(12, 128), "up_raise": Vector2i(77, 0),
	"up_strike": Vector2i(76, 128), "side_raise": Vector2i(140, 0), "side_strike": Vector2i(139, 128),
}
## The plain tool's colours in each metal (phase C's, with the blade's bright edge).
const METAL_COLOURS: Dictionary = {
	&"copper_axe": {"abc2bc": "ffad5d", "8d977f": "f38c4c", "5f7160": "965340", "ffad5d": "a3754e", "e66a3a": "965340", "f2eaf1": "ffcb8d", "141b1b": "141b1b"},
	&"iron_axe": {"abc2bc": "f2eaf1", "8d977f": "b8dce5", "5f7160": "79b8ce", "f2eaf1": "ffffff", "ffad5d": "ffad5d", "e66a3a": "e66a3a", "141b1b": "141b1b"},
}


func test_the_icons_are_the_last_three_in_their_order() -> void:
	var frames: Array = ArtSheets.frames("items")
	assert_array(frames.slice(frames.size() - 3)).is_equal(["axe", "copper_axe", "iron_axe"])
	for index: int in AXES.size():
		assert_int(int(ItemIcons.FRAMES[AXES[index]])).is_equal(frames.size() - 3 + index)


func test_the_held_frames_are_the_last_eighteen_in_their_order() -> void:
	var names: Array[String] = HeldTools.frame_names()
	var expected: Array = []
	for axe: StringName in AXES:
		for pose: String in POSES:
			expected.append("%s_%s" % [axe, pose])
	assert_array(names.slice(names.size() - 18)).is_equal(expected)
	for axe: StringName in AXES:
		assert_bool(HeldTools.has_item(axe)).is_true()
		for facing: String in HeldTools.FACINGS:
			for pose: StringName in [ToolStroke.RAISE, ToolStroke.STRIKE]:
				assert_int(HeldTools.frame_of(axe, facing, pose)).is_equal(names.find("%s_%s_%s" % [axe, facing, pose]))


func test_the_plain_axe_is_the_packs_own() -> void:
	var icon: Image = _pack("Items/Tool/Axe.png")
	var items: Image = _sheet("items")
	var at: int = int(ItemIcons.FRAMES[&"axe"]) * ICON
	for y: int in ICON:
		for x: int in ICON:
			_assert_same(items.get_pixel(at + x, y), icon.get_pixel(x, y), "the icon (%d, %d)" % [x, y])
	var layer: Image = _pack("Actor/CharacterAnimated/Weapon/Axe.png")
	var held: Image = _sheet("held_tools")
	for pose: String in POSES:
		var frame: int = HeldTools.frame_names().find("axe_%s" % pose)
		var window: Vector2i = WINDOWS[pose]
		var cell: Rect2i = Rect2i(window / 64 * 64, Vector2i(64, 64))
		var in_frame: int = _painted(held, Rect2i(frame * HeldTools.SIZE.x, 0, HeldTools.SIZE.x, HeldTools.SIZE.y))
		assert_int(in_frame).override_failure_message("%s holds the whole axe of the pack's cell" % pose).is_equal(_painted(layer, cell))
		for y: int in HeldTools.SIZE.y:
			for x: int in HeldTools.SIZE.x:
				_assert_same(held.get_pixel(frame * HeldTools.SIZE.x + x, y), layer.get_pixel(window.x + x, window.y + y), "%s (%d, %d)" % [pose, x, y])


func test_the_copper_and_iron_axes_are_the_plain_one_in_the_bars_colours() -> void:
	var items: Image = _sheet("items")
	var held: Image = _sheet("held_tools")
	var names: Array[String] = HeldTools.frame_names()
	for metal: StringName in METAL_COLOURS:
		var colours: Dictionary = METAL_COLOURS[metal]
		_assert_recoloured(items, Rect2i(int(ItemIcons.FRAMES[&"axe"]) * ICON, 0, ICON, ICON),
			Vector2i(int(ItemIcons.FRAMES[metal]) * ICON, 0), colours, "%s's icon" % metal)
		for pose: String in POSES:
			var plain: int = names.find("axe_%s" % pose)
			var tier: int = names.find("%s_%s" % [metal, pose])
			_assert_recoloured(held, Rect2i(plain * HeldTools.SIZE.x, 0, HeldTools.SIZE.x, HeldTools.SIZE.y),
				Vector2i(tier * HeldTools.SIZE.x, 0), colours, "%s %s" % [metal, pose])


func test_every_colour_is_the_palettes_or_its_pickaxes() -> void:
	var items: Image = _sheet("items")
	var held: Image = _sheet("held_tools")
	var names: Array[String] = HeldTools.frame_names()
	for axe: StringName in AXES:
		var pickaxe: StringName = StringName(str(axe).replace("axe", "pickaxe"))
		var allowed: Dictionary = _palette()
		_add_colours(items, Rect2i(int(ItemIcons.FRAMES[pickaxe]) * ICON, 0, ICON, ICON), allowed)
		for pose: String in POSES:
			var tool_frame: int = names.find("%s_%s" % [pickaxe, pose])
			_add_colours(held, Rect2i(tool_frame * HeldTools.SIZE.x, 0, HeldTools.SIZE.x, HeldTools.SIZE.y), allowed)
		_assert_in(items, Rect2i(int(ItemIcons.FRAMES[axe]) * ICON, 0, ICON, ICON), allowed, "%s's icon" % axe)
		for pose: String in POSES:
			var frame: int = names.find("%s_%s" % [axe, pose])
			_assert_in(held, Rect2i(frame * HeldTools.SIZE.x, 0, HeldTools.SIZE.x, HeldTools.SIZE.y), allowed, "%s %s" % [axe, pose])


func _assert_recoloured(image: Image, plain: Rect2i, at: Vector2i, colours: Dictionary, what: String) -> void:
	for y: int in plain.size.y:
		for x: int in plain.size.x:
			var was: Color = image.get_pixel(plain.position.x + x, plain.position.y + y)
			var now: Color = image.get_pixel(at.x + x, at.y + y)
			assert_bool(now.a > 0.5).override_failure_message("%s (%d, %d) has the plain one's shape" % [what, x, y]).is_equal(was.a > 0.5)
			if was.a > 0.5:
				var key: String = was.to_html(false)
				assert_bool(colours.has(key)).override_failure_message("%s: %s has a metal colour" % [what, key]).is_true()
				assert_str(now.to_html(false)).override_failure_message("%s (%d, %d)" % [what, x, y]).is_equal(str(colours.get(key, "")))


func _assert_in(image: Image, rect: Rect2i, allowed: Dictionary, what: String) -> void:
	for y: int in rect.size.y:
		for x: int in rect.size.x:
			var colour: Color = image.get_pixel(rect.position.x + x, rect.position.y + y)
			if colour.a <= 0.0:
				continue
			assert_float(colour.a).override_failure_message("%s (%d, %d) is opaque" % [what, x, y]).is_equal(1.0)
			assert_bool(allowed.has(colour.to_html(false))).override_failure_message("%s: %s is the palette's or its pickaxe's" % [what, colour.to_html(false)]).is_true()
	assert_int(_painted(image, rect)).override_failure_message("%s shows" % what).is_greater(40)


func _add_colours(image: Image, rect: Rect2i, into: Dictionary) -> void:
	for y: int in rect.size.y:
		for x: int in rect.size.x:
			var colour: Color = image.get_pixel(rect.position.x + x, rect.position.y + y)
			if colour.a > 0.0:
				into[colour.to_html(false)] = true


func _painted(image: Image, rect: Rect2i) -> int:
	var count: int = 0
	for y: int in rect.size.y:
		for x: int in rect.size.x:
			if image.get_pixel(rect.position.x + x, rect.position.y + y).a > 0.0:
				count += 1
	return count


func _assert_same(got: Color, want: Color, what: String) -> void:
	assert_bool(got.a > 0.5).override_failure_message("%s is where the pack's is" % what).is_equal(want.a > 0.5)
	if want.a > 0.5:
		assert_str(got.to_html(false)).override_failure_message("%s is the pack's colour" % what).is_equal(want.to_html(false))


func _palette() -> Dictionary:
	var out: Dictionary = {}
	var text: String = FileAccess.get_file_as_string("res://art/palettes/hearthvale.gpl")
	for line: String in text.split("\n"):
		var parts: PackedStringArray = line.strip_edges().replace("\t", " ").split(" ", false)
		if parts.size() < 3 or not parts[0].is_valid_int():
			continue
		out[Color8(int(parts[0]), int(parts[1]), int(parts[2])).to_html(false)] = true
	return out


func _sheet(file: String) -> Image:
	var image: Image = ArtSheets.image(ArtSheets.sheet(file))
	image.convert(Image.FORMAT_RGBA8)
	return image


func _pack(path: String) -> Image:
	var image: Image = Image.load_from_file(ProjectSettings.globalize_path(PACK + path))
	image.convert(Image.FORMAT_RGBA8)
	return image
