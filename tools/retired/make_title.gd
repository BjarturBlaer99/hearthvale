extends SceneTree
## Paints the title screen's picture (P1f): an evening over Hearthvale. Then re-import:
##   godot --headless --path . -s res://tools/art/make_title.gd
##   godot --headless --path . --import
## It writes ui/title/backdrop.png, the size of the screen (TitlePicture has the layout).
##
## Back to front: a dusk sky in dithered bands, dim stars and a crescent moon, streaks of
## cloud lit from below, two ranges of far hills, the old keep on its own hill (its window
## dark: the screen lights it), the Old Wood's pines, a band of mist, and Hearthvale: thatch,
## tile and slate roofs with lit windows, cherry trees in blossom (the game's own trees, from
## the scenery atlas, in evening light), lamps along the road north.
## Stars that twinkle, the lit window and the petals are drawn by TitleBackdrop.
## Edit the art here, never the PNG.

const OUT_PATH: String = TitlePicture.TEXTURE_PATH
const W: int = TitlePicture.SIZE.x
const H: int = TitlePicture.SIZE.y
## A colour no picture uses: PixelGrade is asked to warm the colours, not to hunt outlines.
const NO_OUTLINE: Color = Color(1.0, 0.0, 1.0)
## The order pixels are filled in when two colours are mixed by dithering (a 4x4 Bayer grid).
const BAYER: Array[int] = [0, 8, 2, 10, 12, 4, 14, 6, 3, 11, 1, 9, 15, 7, 13, 5]

## The sky from the top down to the horizon.
const SKY: Array[Color] = [
	TitlePicture.SKY_TOP, Color(0.11, 0.11, 0.28), Color(0.18, 0.13, 0.35), Color(0.30, 0.18, 0.41),
	Color(0.47, 0.25, 0.45), Color(0.67, 0.34, 0.45), Color(0.86, 0.47, 0.41), Color(0.97, 0.63, 0.42),
	Color(1.00, 0.79, 0.52),
]
const STAR: Color = Color(0.86, 0.86, 1.0)
const MOON: Color = Color(0.99, 0.95, 0.80)
const MOON_AT: Vector2i = Vector2i(112, 58)
const CLOUD_DARK: Color = Color(0.46, 0.27, 0.45)
const CLOUD_MID: Color = Color(0.74, 0.40, 0.46)
const CLOUD_LIT: Color = Color(1.0, 0.68, 0.46)
const RANGE_FAR: Color = Color(0.42, 0.29, 0.47)
const RANGE_FAR_LIT: Color = Color(0.66, 0.40, 0.48)
const RANGE_NEAR: Color = Color(0.28, 0.23, 0.41)
const RANGE_NEAR_LIT: Color = Color(0.43, 0.30, 0.45)
const KEEP_HILL: Color = Color(0.20, 0.19, 0.34)
const KEEP: Color = Color(0.11, 0.10, 0.18)
const KEEP_RIM: Color = Color(0.36, 0.23, 0.37)
const KEEP_DARK: Color = Color(0.05, 0.05, 0.09)
const WOOD: Color = Color(0.09, 0.17, 0.23)
const PINE: Color = Color(0.06, 0.12, 0.18)
const MIST: Color = Color(0.50, 0.44, 0.58)
const GRASS: Color = Color(0.15, 0.30, 0.21)
const GRASS_LIT: Color = Color(0.25, 0.42, 0.27)
const GRASS_DEEP: Color = Color(0.09, 0.19, 0.16)
const ROAD: Color = Color(0.53, 0.42, 0.37)
const ROAD_SHADE: Color = Color(0.40, 0.31, 0.31)
const PLASTER: Color = Color(0.80, 0.71, 0.62)
const PLASTER_SHADE: Color = Color(0.60, 0.52, 0.52)
const TIMBER: Color = Color(0.27, 0.17, 0.14)
const STONE: Color = Color(0.40, 0.38, 0.44)
const DOOR: Color = Color(0.22, 0.13, 0.10)
const LIGHT: Color = Color(1.0, 0.84, 0.46)
const GLOW: Color = Color(1.0, 0.74, 0.38)
const SMOKE: Color = Color(0.72, 0.66, 0.76, 0.5)
const IRON: Color = Color(0.12, 0.11, 0.16)
## Each roof: its two alternating rows, its ridge, and the same in shade.
const ROOFS: Dictionary = {
	"thatch": [Color(0.70, 0.54, 0.27), Color(0.58, 0.43, 0.22), Color(0.86, 0.70, 0.38), Color(0.44, 0.32, 0.20)],
	"tile": [Color(0.66, 0.27, 0.22), Color(0.52, 0.19, 0.18), Color(0.82, 0.40, 0.30), Color(0.38, 0.14, 0.17)],
	"slate": [Color(0.32, 0.38, 0.60), Color(0.25, 0.30, 0.50), Color(0.46, 0.52, 0.74), Color(0.18, 0.21, 0.38)],
}
## The game's trees are painted for noon: this is what evening does to them.
const DUSK: Color = Color(0.84, 0.76, 0.90)
## The village, back row then front: houses as [left, foot, width, roof], trees as [kind, foot].
const HOUSES: Array = [
	[40, 304, 44, "thatch"], [126, 304, 40, "tile"], [478, 304, 40, "slate"], [560, 305, 44, "thatch"],
	[70, 342, 42, "slate"], [536, 344, 44, "tile"],
]
const TREES: Array = [
	["pine", Vector2i(186, 306)], ["oak", Vector2i(538, 307)], ["broadleaf", Vector2i(216, 310)],
	["pine", Vector2i(424, 309)], ["oak", Vector2i(132, 348)], ["broadleaf", Vector2i(462, 350)],
]
const LAMPS: Array[Vector2i] = [Vector2i(276, 334), Vector2i(392, 318)]

var _image: Image
var _atlas: Image
var _rng: RandomNumberGenerator = RandomNumberGenerator.new()


func _initialize() -> void:
	_rng.seed = 20261112
	_image = Image.create(W, H, false, Image.FORMAT_RGBA8)
	_atlas = (load(SceneryAtlas.TEXTURE_PATH) as Texture2D).get_image()
	_atlas.convert(Image.FORMAT_RGBA8)
	_sky()
	_stars()
	_moon()
	_clouds()
	_range(212.0, 30.0, 0.009, 0.8, 0.031, RANGE_FAR, RANGE_FAR_LIT)
	_range(226.0, 20.0, 0.013, 3.4, 0.043, RANGE_NEAR, RANGE_NEAR_LIT)
	_keep()
	_wood()
	_mist()
	_ground()
	_road()
	_village()
	_tufts()
	PixelGrade.apply(_image, NO_OUTLINE)
	DirAccess.make_dir_recursive_absolute(OUT_PATH.get_base_dir())
	var error: Error = _image.save_png(OUT_PATH)
	print("tools/art: wrote %s (%s)" % [OUT_PATH, error_string(error)])
	quit(0 if error == OK else 1)


## Whether the pixel at (x, y) takes the second of two colours mixed `share` to one (0-1).
static func dithered(x: int, y: int, share: float) -> bool:
	return BAYER[posmod(y, 4) * 4 + posmod(x, 4)] < int(round(share * 16.0))


## How high the village's ground is at `x` (the y of its crest).
static func ground_top(x: int) -> int:
	return int(284.0 - 9.0 * (0.5 + 0.5 * sin(x * 0.013 + 0.6)))


## How high the Old Wood's hill is at `x`.
static func wood_top(x: int) -> int:
	return int(252.0 - 14.0 * (0.5 + 0.5 * sin(x * 0.017 + 2.3)) - 5.0 * (0.5 + 0.5 * sin(x * 0.05)))


## Paints one pixel, blending a see-through colour over what is there. Off the picture: nothing.
func _put(x: int, y: int, color: Color) -> void:
	if x < 0 or y < 0 or x >= W or y >= H:
		return
	if color.a >= 1.0:
		_image.set_pixel(x, y, color)
	elif color.a > 0.0:
		var under: Color = _image.get_pixel(x, y)
		_image.set_pixel(x, y, Color(under.lerp(Color(color.r, color.g, color.b), color.a), 1.0))


func _rect(x: int, y: int, wide: int, high: int, color: Color) -> void:
	for dy: int in high:
		for dx: int in wide:
			_put(x + dx, y + dy, color)


## Light spilling round (cx, cy): `color` dithered in, thinning out to nothing at `radius`.
func _halo(cx: int, cy: int, radius: int, color: Color, strength: float) -> void:
	for y: int in range(cy - radius, cy + radius + 1):
		for x: int in range(cx - radius, cx + radius + 1):
			var far: float = Vector2(x - cx, y - cy).length() / radius
			if far < 1.0 and dithered(x, y, strength * (1.0 - far)):
				_put(x, y, Color(color, 0.45))


func _sky() -> void:
	for y: int in H:
		var down: float = pow(clampf(float(y) / TitlePicture.HORIZON, 0.0, 1.0), 1.2) * (SKY.size() - 1)
		var band: int = mini(int(down), SKY.size() - 2)
		for x: int in W:
			_image.set_pixel(x, y, SKY[band + 1] if dithered(x, y, down - band) else SKY[band])


func _stars() -> void:
	for i: int in 70:
		var at: Vector2i = Vector2i(_rng.randi_range(0, W - 1), _rng.randi_range(0, 128))
		_put(at.x, at.y, Color(STAR, _rng.randf_range(0.2, 0.55) * (1.0 - at.y / 150.0)))
	for star: Vector2i in TitlePicture.STARS:
		_put(star.x, star.y, Color(STAR, 0.5))


## A crescent: a disc with a bite out of it, and a faint ring of light.
func _moon() -> void:
	_halo(MOON_AT.x, MOON_AT.y, 22, Color(0.62, 0.52, 0.70), 0.32)
	for y: int in range(-13, 14):
		for x: int in range(-13, 14):
			var here: Vector2 = Vector2(x, y)
			if here.length() <= 12.5 and (here - Vector2(6.0, -4.0)).length() > 11.5:
				_put(MOON_AT.x + x, MOON_AT.y + y, MOON if here.length() < 11.5 else Color(MOON, 0.6))


## Streaks of cloud low in the sky: dark above, lit from below by the sun that has set.
func _clouds() -> void:
	for cloud: Array in [[150, 150, 46], [262, 172, 60], [78, 184, 34], [388, 142, 38], [560, 166, 52], [330, 196, 44], [610, 190, 26]]:
		var cx: int = cloud[0]
		var cy: int = cloud[1]
		var half: int = cloud[2]
		_rect(cx - half * 6 / 10, cy - 2, half * 11 / 10, 1, CLOUD_DARK)
		_rect(cx - half * 8 / 10, cy - 1, half * 17 / 10, 1, CLOUD_DARK)
		_rect(cx - half, cy, half * 2, 1, CLOUD_MID)
		_rect(cx - half * 9 / 10, cy + 1, half * 19 / 10, 1, CLOUD_MID)
		_rect(cx - half * 7 / 10, cy + 2, half * 15 / 10, 1, CLOUD_LIT)
		_rect(cx - half * 4 / 10, cy + 3, half * 9 / 10, 1, CLOUD_LIT)


## A range of far hills: two waves added, filled down to the foot of the picture, with the
## last light along their crest.
func _range(foot: float, height: float, wave: float, phase: float, ripple: float, color: Color, lit: Color) -> void:
	for x: int in W:
		var top: int = int(foot - height * (0.5 + 0.5 * sin(x * wave + phase)) - height * 0.3 * (0.5 + 0.5 * sin(x * ripple + phase * 2.0)))
		_put(x, top, lit)
		for y: int in range(top + 1, H):
			_image.set_pixel(x, y, color)


## The old keep on a hill of its own: two towers, a wall between them, a gate, a pennant.
func _keep() -> void:
	for x: int in range(360, 620):
		var rise: float = maxf(0.0, cos((x - 490) / 130.0 * PI / 2.0))
		var top: int = int(228.0 - 46.0 * pow(rise, 1.4))
		for y: int in range(top, H):
			_image.set_pixel(x, y, KEEP_HILL)
	var foot: int = 184
	_rect(462, 150, 56, foot - 150, KEEP)
	for notch: int in 8:
		_rect(463 + notch * 7, 146, 4, 4, KEEP)
	for tower: Array in [[454, 134, 15], [510, 126, 16]]:
		_rect(tower[0], tower[1], tower[2], foot - int(tower[1]), KEEP)
		_rect(int(tower[0]) - 1, int(tower[1]) - 1, int(tower[2]) + 2, 2, KEEP)
		for notch: int in 4:
			_rect(int(tower[0]) - 1 + notch * 5, int(tower[1]) - 5, 3, 4, KEEP)
		# The last of the light catches the western edge.
		_rect(tower[0], int(tower[1]) + 2, 1, foot - int(tower[1]) - 2, KEEP_RIM)
		_rect(int(tower[0]) + 6, int(tower[1]) + 12, 2, 4, KEEP_DARK)
	_rect(470, 152, 1, foot - 152, KEEP_RIM)
	# The gate, and the pennant on the taller tower.
	_rect(485, 172, 10, foot - 172, KEEP_DARK)
	_rect(486, 170, 8, 2, KEEP_DARK)
	_rect(518, 110, 1, 12, KEEP)
	_rect(519, 111, 6, 2, Color(0.45, 0.16, 0.22))
	_rect(519, 113, 4, 1, Color(0.45, 0.16, 0.22))
	var window: Rect2i = TitlePicture.WINDOW
	_rect(window.position.x, window.position.y, window.size.x, window.size.y, KEEP_DARK)


## The Old Wood: a dark hill with pines standing along its crest.
func _wood() -> void:
	for x: int in W:
		for y: int in range(wood_top(x), H):
			_image.set_pixel(x, y, WOOD)
	var x: int = 3
	while x < W:
		var high: int = _rng.randi_range(12, 24)
		var foot: int = wood_top(x) + 3
		for row: int in high:
			var half: int = int(1.0 + (row % 6) * 0.7 + row * 0.18)
			_rect(x - half, foot - high + row, half * 2 + 1, 1, PINE)
		x += _rng.randi_range(7, 13)


## Mist lying where the wood meets the village's fields.
func _mist() -> void:
	for y: int in range(248, 270):
		var thick: float = 0.30 * (1.0 - absf(y - 259.0) / 11.0)
		for x: int in W:
			if dithered(x, y, thick):
				_put(x, y, Color(MIST, 0.55))


func _ground() -> void:
	for x: int in W:
		var top: int = ground_top(x)
		for y: int in range(top, H):
			var deep: float = float(y - top) / float(H - top)
			var color: Color = GRASS_DEEP if dithered(x, y, deep * 0.85) else GRASS
			_image.set_pixel(x, y, GRASS_LIT if y - top < 2 else color)
	for i: int in 900:
		var at: Vector2i = Vector2i(_rng.randi_range(0, W - 1), _rng.randi_range(280, H - 1))
		if at.y > ground_top(at.x) + 3:
			_put(at.x, at.y, Color(GRASS_LIT, 0.5) if i % 3 != 0 else Color(GRASS_DEEP, 0.6))


## The road north: wide at the foot of the picture, narrowing as it climbs towards the keep.
func _road() -> void:
	for y: int in range(H - 1, 262, -1):
		var along: float = float(H - 1 - y) / 96.0
		var middle: float = 318.0 + 104.0 * pow(along, 1.15) + 9.0 * sin(along * 5.0)
		var half: float = lerpf(27.0, 2.0, pow(along, 0.7))
		for x: int in range(int(middle - half), int(middle + half) + 1):
			if y < ground_top(x) + 1:
				continue
			var edge: bool = x <= int(middle - half) + 1 or x >= int(middle + half) - 1
			var shade: bool = x > middle + half * 0.35 and dithered(x, y, 0.6)
			_put(x, y, ROAD_SHADE if edge or shade else ROAD)


## Hearthvale: houses, trees and lamps, the back row first so the front row stands before it.
func _village() -> void:
	var things: Array = []
	for house: Array in HOUSES:
		things.append([int(house[1]), "house", house])
	for tree: Array in TREES:
		things.append([(tree[1] as Vector2i).y, "tree", tree])
	for foot: Vector2i in TitlePicture.CHERRY_FEET:
		things.append([foot.y, "tree", ["cherry" if foot.x % 2 == 0 else "cherry_b", foot]])
	for lamp: Vector2i in LAMPS:
		things.append([lamp.y, "lamp", lamp])
	things.sort_custom(func(a: Array, b: Array) -> bool: return int(a[0]) < int(b[0]))
	for thing: Array in things:
		match str(thing[1]):
			"house":
				_house(thing[2][0], thing[2][1], thing[2][2], thing[2][3])
			"tree":
				_tree(thing[2][0], thing[2][1])
			"lamp":
				_lamp(thing[2])


## A house seen from the front: a half-timbered wall on a stone foot, a hipped roof with a
## chimney, a door, and a window with the lamp lit inside.
func _house(left: int, foot: int, wide: int, style: String) -> void:
	var roof: Array = ROOFS[style]
	var eaves: int = foot - 15
	for y: int in range(eaves, foot):
		for x: int in range(left, left + wide):
			_image.set_pixel(x, y, PLASTER_SHADE if x > left + wide * 0.62 else PLASTER)
	_rect(left, foot - 2, wide, 2, STONE)
	# Timber: the corner posts, one in the middle, a rail, and a brace at each end.
	for post: int in [left, left + wide / 2, left + wide - 1]:
		_rect(post, eaves, 1, 13, TIMBER)
	_rect(left, eaves + 6, wide, 1, TIMBER)
	for step: int in 5:
		_put(left + 1 + step, eaves + 5 - step, TIMBER)
		_put(left + wide - 2 - step, eaves + 5 - step, TIMBER)
	# The door, left of the middle; the window, right of it.
	var door: int = left + wide / 2 - 9
	_rect(door - 1, foot - 12, 8, 10, TIMBER)
	_rect(door, foot - 11, 6, 9, DOOR)
	_put(door + 4, foot - 6, LIGHT)
	var window: Vector2i = Vector2i(left + wide / 2 + 5, eaves + 3)
	_halo(window.x + 3, window.y + 3, 9, GLOW, 0.75)
	_rect(window.x - 1, window.y - 1, 8, 8, TIMBER)
	_rect(window.x, window.y, 6, 6, LIGHT)
	_rect(window.x + 2, window.y, 1, 6, TIMBER)
	_rect(window.x, window.y + 2, 6, 1, TIMBER)
	# The roof: rows that step in as they rise, its eastern side in shade.
	var rows: int = 17
	for row: int in rows:
		var inset: int = int(row * 0.9)
		var from: int = left - 3 + inset
		var to: int = left + wide + 3 - inset
		for x: int in range(from, to):
			var color: Color = roof[1] if row % 3 == 0 else roof[0]
			if row == rows - 1:
				color = roof[2]
			elif x > left + wide * 0.66 + inset * 0.3 or row == 0:
				color = roof[3]
			_image.set_pixel(x, eaves - 1 - row, color)
	# The chimney and its smoke.
	var stack: int = left + wide * 2 / 3
	_rect(stack, eaves - rows - 4, 4, 8, STONE)
	_rect(stack - 1, eaves - rows - 5, 6, 1, TIMBER)
	for puff: int in 9:
		_put(stack + 1 + int(2.5 * sin(puff * 0.9)) + puff / 3, eaves - rows - 7 - puff * 2, SMOKE)
		_put(stack + 2 + int(2.5 * sin(puff * 0.9)) + puff / 3, eaves - rows - 8 - puff * 2, Color(SMOKE, 0.3))


## One of the game's own trees, from the scenery atlas, in evening light.
func _tree(kind: String, foot: Vector2i) -> void:
	var region: Rect2i = Rect2i(SceneryAtlas.region(kind))
	var corner: Vector2i = foot - Vector2i(SceneryAtlas.FOOT)
	for y: int in region.size.y:
		for x: int in region.size.x:
			var pixel: Color = _atlas.get_pixel(region.position.x + x, region.position.y + y)
			_put(corner.x + x, corner.y + y, Color(pixel.r * DUSK.r, pixel.g * DUSK.g, pixel.b * DUSK.b, pixel.a))


## A lamp on a post, lit, with its pool of light.
func _lamp(foot: Vector2i) -> void:
	_halo(foot.x, foot.y - 15, 15, GLOW, 0.7)
	_rect(foot.x - 1, foot.y - 12, 2, 12, IRON)
	_rect(foot.x - 2, foot.y - 1, 4, 1, IRON)
	_rect(foot.x - 3, foot.y - 18, 6, 7, IRON)
	_rect(foot.x - 2, foot.y - 17, 4, 5, LIGHT)
	_rect(foot.x - 2, foot.y - 19, 4, 1, IRON)


## Tufts of grass along the foot of the picture, nearest of all.
func _tufts() -> void:
	var x: int = 2
	while x < W:
		var high: int = _rng.randi_range(2, 5)
		for blade: int in 3:
			_rect(x + blade * 2, H - high + absi(blade - 1), 1, high, GRASS_DEEP if blade != 1 else Color(0.20, 0.36, 0.24))
		x += _rng.randi_range(5, 11)
