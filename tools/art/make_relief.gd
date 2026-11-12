extends SceneTree
## Paints the relief atlas (P1d): wall faces and tops, the pillar, and the roofs' ridge strips.
## Then re-import:
##   godot --headless --path . -s res://tools/art/make_relief.gd [-- <preview.png>]
##   godot --headless --path . --import
## The optional preview is the atlas at 6x on a dark background. Layout: ReliefAtlas.
##
## Everything is lit from above and a little from the left. A wall's face is brightest along
## its top edge and darkens towards the floor; its top is one flat shade, darker than the face
## in a dungeon (the walls rise into the dark) and lighter out of doors (the sun is on it).
## Edit the art here, never the PNG.

const OUT_PATH: String = ReliefAtlas.TEXTURE_PATH
const ROOF_RED: Color = Color(0.74, 0.30, 0.22)
const ROOF_BLUE: Color = Color(0.30, 0.40, 0.62)
const THATCH: Color = Color(0.80, 0.66, 0.34)
## A colour no picture uses: PixelGrade is asked to warm the colours, not to hunt outlines.
const NO_OUTLINE: Color = Color(1.0, 0.0, 1.0)

var _image: Image


func _initialize() -> void:
	_image = Image.create(ReliefAtlas.SIZE.x, ReliefAtlas.SIZE.y, false, Image.FORMAT_RGBA8)
	_image.fill(Color(0, 0, 0, 0))
	for face: Rect2 in [ReliefAtlas.face("stone"), ReliefAtlas.short_face("stone")]:
		_bricks(face, Color(0.37, 0.37, 0.48), Color(0.17, 0.17, 0.24), 8, 0)
	_flat_top(ReliefAtlas.top("stone"), Color(0.16, 0.16, 0.22), 13)
	for face: Rect2 in [ReliefAtlas.face("timber"), ReliefAtlas.short_face("timber")]:
		_planks(face)
	_flat_top(ReliefAtlas.top("timber"), Color(0.21, 0.14, 0.10), 29)
	for face: Rect2 in [ReliefAtlas.face("ruin"), ReliefAtlas.short_face("ruin")]:
		_bricks(face, Color(0.58, 0.58, 0.61), Color(0.34, 0.34, 0.38), 8, 41)
		_moss(face)
	_flat_top(ReliefAtlas.top("ruin"), Color(0.64, 0.64, 0.67), 43)
	_pillar(ReliefAtlas.pillar())
	for style: String in ReliefAtlas.ROOF_STYLES:
		for part: String in ReliefAtlas.RIDGE_PARTS:
			_ridge(ReliefAtlas.ridge(style, part), style, part)
	PixelGrade.apply(_image, NO_OUTLINE)
	DirAccess.make_dir_recursive_absolute(OUT_PATH.get_base_dir())
	var error: Error = _image.save_png(OUT_PATH)
	print("tools/art: wrote %s (%s)" % [OUT_PATH, error_string(error)])
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if error == OK and args.size() > 0:
		var scale: int = 6
		var preview: Image = Image.create(_image.get_width() * scale, _image.get_height() * scale, false, Image.FORMAT_RGBA8)
		preview.fill(Color(0.10, 0.09, 0.14))
		var big: Image = _image.duplicate()
		big.resize(_image.get_width() * scale, _image.get_height() * scale, Image.INTERPOLATE_NEAREST)
		preview.blend_rect(big, Rect2i(Vector2i.ZERO, big.get_size()), Vector2i.ZERO)
		print("tools/art: preview %s (%s)" % [args[0], error_string(preview.save_png(args[0]))])
	quit(0 if error == OK else 1)


## A wall face of stone blocks in courses four pixels high, joints staggered: lightest along
## its top edge, darkening to the floor.
func _bricks(region: Rect2, stone: Color, mortar: Color, block: int, seed_value: int) -> void:
	var origin: Vector2i = Vector2i(region.position)
	var size: Vector2i = Vector2i(region.size)
	for y: int in size.y:
		@warning_ignore("integer_division")
		var course: int = y / 4
		# From a little lighter at the top to a good deal darker at the foot.
		var depth: float = float(y) / float(size.y - 1)
		var shade: Color = stone.lightened(0.12 * (1.0 - depth)).darkened(0.34 * depth * depth)
		for x: int in size.x:
			var joint: int = (x + (block / 2 if course % 2 == 1 else 0)) % block
			var color: Color = shade
			var tint: int = _hash((x + (4 if course % 2 == 1 else 0)) / block, course, seed_value) % 5
			color = color.lightened(0.03 * float(tint)) if tint < 3 else color.darkened(0.04 * float(tint - 2))
			if y % 4 == 3 or joint == 0:
				color = mortar.lerp(shade, 0.25)
			elif y % 4 == 0:
				color = color.lightened(0.10)
			_dot(origin, x, y, color)
	# The top edge catches the light; the foot is the darkest line.
	for x: int in size.x:
		_dot(origin, x, 0, stone.lightened(0.42))
		_dot(origin, x, 1, stone.lightened(0.20))
		_dot(origin, x, size.y - 1, mortar.darkened(0.25))


## A timber wall: boards under a dark beam, with a skirting board along the floor.
func _planks(region: Rect2) -> void:
	var origin: Vector2i = Vector2i(region.position)
	var size: Vector2i = Vector2i(region.size)
	var board: Color = Color(0.56, 0.40, 0.26)
	var gap: Color = Color(0.30, 0.20, 0.13)
	var beam: Color = Color(0.36, 0.24, 0.15)
	for y: int in size.y:
		var depth: float = float(y) / float(size.y - 1)
		for x: int in size.x:
			var color: Color = board.lightened(0.10 * (1.0 - depth)).darkened(0.22 * depth)
			if _hash(x, y / 5, 17) % 9 == 0:
				color = color.darkened(0.10)
			if y % 5 == 4:
				color = gap
			elif y % 5 == 0:
				color = color.lightened(0.08)
			# A board's end every so often, staggered from course to course.
			if (x + (y / 5) * 7) % 16 == 0 and y % 5 != 4:
				color = gap.lightened(0.15)
			_dot(origin, x, y, color)
	for x: int in size.x:
		_dot(origin, x, 0, beam.lightened(0.45))
		for y: int in range(1, 4):
			_dot(origin, x, y, beam.lightened(0.10) if y == 1 else beam)
		_dot(origin, x, 4, beam.darkened(0.35))
		for y: int in range(size.y - 4, size.y):
			_dot(origin, x, y, beam.lightened(0.12) if y == size.y - 4 else beam.darkened(0.10))
		_dot(origin, x, size.y - 1, beam.darkened(0.45))


## The top of a wall: one flat shade with a little grain.
func _flat_top(region: Rect2, color: Color, seed_value: int) -> void:
	var origin: Vector2i = Vector2i(region.position)
	for y: int in int(region.size.y):
		for x: int in int(region.size.x):
			var roll: int = _hash(x, y, seed_value) % 29
			var shade: Color = color
			if roll == 0:
				shade = color.lightened(0.03)
			elif roll == 1:
				shade = color.darkened(0.05)
			_dot(origin, x, y, shade)


## Moss creeping up from the foot of an outdoor wall.
func _moss(region: Rect2) -> void:
	var origin: Vector2i = Vector2i(region.position)
	var size: Vector2i = Vector2i(region.size)
	for x: int in size.x:
		var height: int = _hash(x, 0, 59) % 5
		for up: int in height:
			var y: int = size.y - 2 - up
			if _hash(x, y, 61) % 3 != 0:
				_dot(origin, x, y, Color(0.36, 0.52, 0.26) if up < 2 else Color(0.46, 0.60, 0.30))


## A stone pillar: a base, a shaft lit on its left, a capital wider than the shaft.
func _pillar(region: Rect2) -> void:
	var origin: Vector2i = Vector2i(region.position)
	var stone: Color = Color(0.56, 0.56, 0.62)
	var foot: int = int(ReliefAtlas.PILLAR_FOOT.y)
	# The capital (rows 1-6), the shaft (rows 7-21) and the base (rows 22 to the foot).
	for y: int in range(1, foot + 1):
		var left: int = 4
		var right: int = 11
		if y <= 6 or y >= 22:
			left = 2
			right = 13
		if y == 1 or y == foot:
			left = 3
			right = 12
		for x: int in range(left, right + 1):
			var across: float = float(x - left) / float(right - left)
			var color: Color = stone.lightened(0.22 * (1.0 - across) - 0.02).darkened(0.30 * across)
			if y == 1 or y == 22:
				color = color.lightened(0.20)
			elif y == 6 or y == foot:
				color = color.darkened(0.30)
			elif y == 7:
				color = color.darkened(0.22)
			_dot(origin, x, y, color)
	# A crack and a chip, so it has stood a while.
	_dot(origin, 6, 12, stone.darkened(0.35))
	_dot(origin, 7, 13, stone.darkened(0.35))
	_dot(origin, 7, 14, stone.darkened(0.30))
	_dot(origin, 10, 18, stone.darkened(0.28))


## A roof's ridge strip: the back slope seen from the front, under a dark line of sky edge. Its
## ends slope away at the gable.
func _ridge(region: Rect2, style: String, part: String) -> void:
	var origin: Vector2i = Vector2i(region.position)
	var size: Vector2i = Vector2i(region.size)
	var base: Color = THATCH if style == "roof_thatch" else (ROOF_BLUE if style == "roof_blue" else ROOF_RED)
	for y: int in size.y:
		for x: int in size.x:
			# The gable: the strip narrows towards its top at the roof's end.
			var from_end: int = x if part == "l" else (size.x - 1 - x if part == "r" else 99)
			if from_end < (size.y - 1 - y) / 2:
				continue
			var color: Color = base.darkened(0.16 - 0.03 * float(y))
			if style == "roof_thatch":
				if _hash(x, 0, 83) % 4 == 0:
					color = color.darkened(0.14)
				elif _hash(x, y, 85) % 7 == 0:
					color = color.lightened(0.12)
			elif (y % 4 == 3) or ((x + (4 if y >= 4 else 0)) % 8 == 0):
				color = color.darkened(0.22)
			if y == 0:
				color = base.darkened(0.48)
			elif y == 1:
				color = base.lightened(0.20)
			if from_end == (size.y - 1 - y) / 2 and part != "mid":
				color = base.darkened(0.45)
			_dot(origin, x, y, color)


func _dot(origin: Vector2i, x: int, y: int, color: Color) -> void:
	_image.set_pixel(origin.x + x, origin.y + y, color)


## The same number for the same pixel and seed, every time.
func _hash(x: int, y: int, seed_value: int) -> int:
	var h: int = (x * 73856093) ^ (y * 19349663) ^ (seed_value * 83492791)
	h = (h ^ (h >> 13)) * 1274126177
	return absi(h ^ (h >> 16))
