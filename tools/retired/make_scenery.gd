extends SceneTree
## Paints the tall scenery (P1c): trees that stand up from the ground, in more shades than a
## 16-pixel tile can hold. Then re-import:
##   godot --headless --path . -s res://tools/art/make_scenery.gd [-- <preview.png>]
##   godot --headless --path . --import
## The optional preview is the atlas at 4x on grass green. Layout: SceneryAtlas.
##
## Each crown is built from round clumps of leaves, lit from the top left: every clump runs
## through its tree's ramp of shades from light to dark, lower clumps sit in the shade of the
## ones above, and only the shaded side of the crown gets a dark rim (outlines are selective).
## Edit the art here, never the PNG.

const OUT_PATH: String = SceneryAtlas.TEXTURE_PATH
const SIZE: Vector2i = SceneryAtlas.SIZE
## Shades from darkest to lightest.
const LEAF: Array[Color] = [Color(0.09, 0.27, 0.22), Color(0.14, 0.39, 0.24), Color(0.23, 0.52, 0.24), Color(0.38, 0.65, 0.26), Color(0.57, 0.78, 0.33)]
const OAK: Array[Color] = [Color(0.13, 0.28, 0.17), Color(0.21, 0.40, 0.18), Color(0.33, 0.53, 0.20), Color(0.49, 0.65, 0.24), Color(0.68, 0.77, 0.34)]
const PINE: Array[Color] = [Color(0.05, 0.20, 0.22), Color(0.08, 0.30, 0.26), Color(0.13, 0.40, 0.28), Color(0.22, 0.51, 0.31), Color(0.36, 0.62, 0.36)]
const BLOSSOM: Array[Color] = [Color(0.56, 0.22, 0.38), Color(0.76, 0.35, 0.52), Color(0.91, 0.53, 0.67), Color(0.98, 0.72, 0.80), Color(1.0, 0.88, 0.91)]
const WILLOW: Array[Color] = [Color(0.13, 0.27, 0.20), Color(0.22, 0.39, 0.24), Color(0.36, 0.52, 0.28), Color(0.53, 0.65, 0.34), Color(0.70, 0.77, 0.44)]
const BARK: Array[Color] = [Color(0.25, 0.15, 0.10), Color(0.40, 0.25, 0.14), Color(0.55, 0.36, 0.20)]
const DARK_BARK: Array[Color] = [Color(0.17, 0.10, 0.11), Color(0.28, 0.17, 0.16), Color(0.41, 0.27, 0.23)]
const SPARKLE: Color = Color(1.0, 0.97, 0.97)
const SHADOW: Color = Color(0.14, 0.06, 0.24, 0.26)
## A colour no picture uses: PixelGrade is asked to warm the colours, not to hunt outlines.
const NO_OUTLINE: Color = Color(1.0, 0.0, 1.0)


func _initialize() -> void:
	var image: Image = Image.create(SceneryAtlas.CELL.x * SceneryAtlas.KINDS.size(), SceneryAtlas.CELL.y, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for kind: String in SceneryAtlas.KINDS:
		var origin: Vector2i = Vector2i(SceneryAtlas.region(kind).position)
		match kind:
			"broadleaf":
				_broadleaf(image, origin)
			"oak":
				_oak(image, origin)
			"pine":
				_pine(image, origin)
			"cherry":
				_cherry(image, origin, false)
			"cherry_b":
				_cherry(image, origin, true)
			"willow":
				_willow(image, origin, false)
			"willow_b":
				_willow(image, origin, true)
	PixelGrade.apply(image, NO_OUTLINE)
	DirAccess.make_dir_recursive_absolute(OUT_PATH.get_base_dir())
	var error: Error = image.save_png(OUT_PATH)
	print("tools/art: wrote %s (%s)" % [OUT_PATH, error_string(error)])
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if error == OK and args.size() > 0:
		var scale: int = 4
		var preview: Image = Image.create(image.get_width() * scale, image.get_height() * scale, false, Image.FORMAT_RGBA8)
		preview.fill(Color(0.42, 0.62, 0.30))
		var big: Image = image.duplicate()
		big.resize(image.get_width() * scale, image.get_height() * scale, Image.INTERPOLATE_NEAREST)
		preview.blend_rect(big, Rect2i(Vector2i.ZERO, big.get_size()), Vector2i.ZERO)
		print("tools/art: preview %s (%s)" % [args[0], error_string(preview.save_png(args[0]))])
	quit(0 if error == OK else 1)


func _broadleaf(image: Image, origin: Vector2i) -> void:
	_foot_shadow(image, origin, 9.0)
	_trunk(image, origin, 14, 4, 23, BARK)
	_crown(image, origin, [
		Vector3(6, 19, 5), Vector3(26, 19, 5), Vector3(12, 23, 5), Vector3(20, 23, 5),
		Vector3(10, 18, 7), Vector3(22, 18, 7), Vector3(16, 20, 8),
		Vector3(8, 12, 7), Vector3(24, 12, 7), Vector3(16, 13, 8),
		Vector3(12, 7, 6), Vector3(20, 7, 6), Vector3(16, 5, 5),
	], LEAF, 11)


func _oak(image: Image, origin: Vector2i) -> void:
	_foot_shadow(image, origin, 10.0)
	_trunk(image, origin, 13, 6, 24, BARK)
	_crown(image, origin, [
		Vector3(7, 20, 6), Vector3(25, 20, 6), Vector3(16, 22, 8),
		Vector3(8, 14, 8), Vector3(24, 14, 8), Vector3(16, 14, 10),
		Vector3(11, 8, 7), Vector3(21, 8, 7), Vector3(16, 6, 6),
	], OAK, 23)


## A pine: tiers of boughs, each a triangle lit on its left, the one above shading the next.
func _pine(image: Image, origin: Vector2i) -> void:
	_foot_shadow(image, origin, 7.0)
	_trunk(image, origin, 15, 3, 30, BARK)
	for tier: int in range(3, -1, -1):
		var apex: float = 1.0 + tier * 6.5
		var base: float = apex + 12.0
		var half: float = 6.0 + tier * 2.6
		for y: int in range(int(apex), int(base) + 1):
			var reach: float = half * (float(y) - apex + 1.0) / (base - apex + 1.0)
			for x: int in SIZE.x:
				var off: float = float(x) + 0.5 - 16.0
				if absf(off) > reach:
					continue
				var light: float = 0.55 - off / half * 0.38 - (float(y) - apex) / 12.0 * 0.22
				light += (float(_hash(x, y, 31) % 100) / 100.0 - 0.5) * 0.24
				# The top rows of a tier lie under the tier above: in its shade.
				if tier > 0 and float(y) < apex + 5.0:
					light -= 0.22
				var shade: int = clampi(int(light * PINE.size()), 0, PINE.size() - 1)
				# The ragged lower edge of each tier is its darkest line.
				if y == int(base) and (x + tier) % 3 != 0:
					shade = 0
				_dot(image, origin, x, y, PINE[shade])


func _cherry(image: Image, origin: Vector2i, mirrored: bool) -> void:
	_foot_shadow(image, origin, 10.0)
	_trunk(image, origin, 14, 4, 22, DARK_BARK)
	# Two boughs fork under the crown.
	for step: int in 6:
		_dot(image, origin, 13 - step, 24 - step, DARK_BARK[1])
		_dot(image, origin, 14 - step, 24 - step, DARK_BARK[0])
		_dot(image, origin, 18 + step, 24 - step, DARK_BARK[0])
		_dot(image, origin, 19 + step, 24 - step, DARK_BARK[1])
	var clumps: Array = [
		Vector3(5, 19, 4.5), Vector3(27, 18, 4.5), Vector3(11, 20, 5.5), Vector3(21, 21, 5.5),
		Vector3(8, 14, 7), Vector3(24, 14, 7), Vector3(16, 15, 8),
		Vector3(11, 9, 7), Vector3(21, 8, 7), Vector3(16, 6, 6), Vector3(26, 10, 4),
	]
	if mirrored:
		for i: int in clumps.size():
			clumps[i] = Vector3(32.0 - (clumps[i] as Vector3).x, (clumps[i] as Vector3).y + (1.0 if i % 3 == 0 else 0.0), (clumps[i] as Vector3).z)
	var crown: Dictionary = _crown(image, origin, clumps, BLOSSOM, 47 if mirrored else 5)
	# Blossom catching the light, and a few gaps where the dark boughs show through.
	for cell: Vector2i in crown:
		var roll: int = _hash(cell.x, cell.y, 71 if mirrored else 53) % 100
		if roll < 7 and int(crown[cell]) >= 2:
			_dot(image, origin, cell.x, cell.y, SPARKLE)
		elif roll > 96 and cell.y > 14 and int(crown[cell]) <= 2:
			_dot(image, origin, cell.x, cell.y, DARK_BARK[1])


## A weeping willow (Willowmere, 2026-11-17): a low dome of crown on a dark trunk, and from it
## long strands hanging nearly to the ground, longest at the sides, each its own length and
## shade, with gaps between where the trunk and the dark under the tree show through.
func _willow(image: Image, origin: Vector2i, mirrored: bool) -> void:
	_foot_shadow(image, origin, 12.0)
	_trunk(image, origin, 14, 4, 15, DARK_BARK)
	# A bough leaning out each way under the crown.
	for step: int in 5:
		_dot(image, origin, 13 - step, 19 - step, DARK_BARK[1])
		_dot(image, origin, 18 + step, 19 - step, DARK_BARK[0])
	var clumps: Array = [
		Vector3(7, 14, 5.5), Vector3(25, 14, 5.5), Vector3(16, 13, 8),
		Vector3(11, 9, 6.5), Vector3(21, 9, 6.5), Vector3(16, 6, 6),
	]
	if mirrored:
		for i: int in clumps.size():
			clumps[i] = Vector3(32.0 - (clumps[i] as Vector3).x, (clumps[i] as Vector3).y + (1.0 if i % 2 == 0 else 0.0), (clumps[i] as Vector3).z)
	var crown: Dictionary = _crown(image, origin, clumps, WILLOW, 97 if mirrored else 91)
	# The hanging strands, one or two pixels wide, from the crown's underside down.
	var seed_value: int = 113 if mirrored else 101
	for x: int in range(1, SIZE.x - 1):
		var roll: int = _hash(x, 7, seed_value)
		if roll % 7 == 0:
			continue
		var from: int = 12
		for y: int in range(SIZE.y - 1, 0, -1):
			if crown.has(Vector2i(x, y)):
				from = y
				break
		var out: float = absf(float(x) - 15.5)
		# Long at the sides, short over the trunk so it shows.
		var reach: int = 30 + (roll >> 3) % 5 if out > 5.0 else 21 + (roll >> 3) % 5
		if out > 12.0:
			reach -= 3
		var shade: int = 1 + (roll >> 7) % 3
		for y: int in range(from, reach + 1):
			var leaf: int = shade
			if y > reach - 2:
				leaf = 0
			elif y > from + 8:
				leaf = maxi(shade - 1, 1)
			_dot(image, origin, x, y, WILLOW[leaf])


## A crown of round `clumps` (x, y, radius; drawn in order, so list the lowest first), shaded
## through `ramp` from the top left. Returns each crown pixel's shade (an index into `ramp`).
func _crown(image: Image, origin: Vector2i, clumps: Array, ramp: Array[Color], seed_value: int) -> Dictionary:
	var shades: Dictionary = {}
	var top: float = 999.0
	var bottom: float = 0.0
	for clump: Vector3 in clumps:
		top = minf(top, clump.y - clump.z)
		bottom = maxf(bottom, clump.y + clump.z)
	for clump: Vector3 in clumps:
		for y: int in SIZE.y:
			for x: int in SIZE.x:
				var off: Vector2 = Vector2(x + 0.5 - clump.x, y + 0.5 - clump.y)
				if off.length() > clump.z:
					continue
				var across: Vector2 = off / clump.z
				var light: float = 0.52 - 0.5 * (across.x * 0.55 + across.y * 0.85)
				light += (float(_hash(x, y, seed_value) % 100) / 100.0 - 0.5) * 0.26
				# Clumps low in the crown sit in the shade of those above.
				light -= ((clump.y - top) / maxf(bottom - top, 1.0) - 0.45) * 0.42
				shades[Vector2i(x, y)] = clampi(int(light * ramp.size()), 0, ramp.size() - 1)
	for cell: Vector2i in shades:
		var shade: int = shades[cell]
		# The rim: only on the shaded side, below and to the right.
		if not shades.has(cell + Vector2i(0, 1)) or (not shades.has(cell + Vector2i(1, 0)) and cell.y > int((top + bottom) / 2.0)):
			shade = 0
			shades[cell] = 0
		_dot(image, origin, cell.x, cell.y, ramp[shade])
	return shades


## A trunk `wide` pixels across from `left`, from `top` down to the foot, lit on its left, with
## roots spreading at the ground.
func _trunk(image: Image, origin: Vector2i, left: int, wide: int, top: int, bark: Array[Color]) -> void:
	var foot: int = int(SceneryAtlas.FOOT.y)
	for y: int in range(top, foot + 1):
		for x: int in range(left, left + wide):
			var shade: Color = bark[1]
			if x == left:
				shade = bark[2]
			elif x == left + wide - 1:
				shade = bark[0]
			if _hash(x, y, 9) % 7 == 0:
				shade = bark[0]
			_dot(image, origin, x, y, shade)
	for x: int in [left - 1, left + wide]:
		_dot(image, origin, x, foot, bark[0])
		_dot(image, origin, x, foot - 1, bark[1] if x < left else bark[0])
	_dot(image, origin, left - 2, foot, bark[0])
	_dot(image, origin, left + wide + 1, foot, bark[0])


## The patch of shade the tree stands on.
func _foot_shadow(image: Image, origin: Vector2i, half_width: float) -> void:
	var middle: Vector2 = SceneryAtlas.FOOT + Vector2(0.5, 0.5)
	for y: int in SIZE.y:
		for x: int in SIZE.x:
			var off: Vector2 = Vector2(x + 0.5, y + 0.5) - middle
			if (off.x * off.x) / (half_width * half_width) + (off.y * off.y) / 6.5 <= 1.0:
				_dot(image, origin, x, y, SHADOW)


func _dot(image: Image, origin: Vector2i, x: int, y: int, color: Color) -> void:
	if x >= 0 and y >= 0 and x < SIZE.x and y < SIZE.y:
		image.set_pixel(origin.x + x, origin.y + y, color)


## The same number for the same pixel and seed, every time.
func _hash(x: int, y: int, seed_value: int) -> int:
	var h: int = (x * 73856093) ^ (y * 19349663) ^ (seed_value * 83492791)
	h = (h ^ (h >> 13)) * 1274126177
	return absi(h ^ (h >> 16))
