extends SceneTree
## Paints the tile atlas in pixel art (see GreyboxTiles for the layout). Step 1 of 4:
##   godot --headless --path . -s res://tools/greybox/make_tile_texture.gd
##   godot --headless --path . --import
##   godot --headless --path . -s res://tools/greybox/build_tileset.gd
##   godot --headless --path . -s res://tools/greybox/build_maps.gd

const T: int = GreyboxTiles.TILE_SIZE
const OUTLINE: Color = Color(0.10, 0.08, 0.12)
const ROOF_RED: Color = Color(0.74, 0.30, 0.22)
const ROOF_BLUE: Color = Color(0.30, 0.40, 0.62)
## Shadows on see-through props darken whatever grass they're drawn over.
const SHADOW: Color = Color(0, 0, 0, 0.28)

var _image: Image


func _initialize() -> void:
	_image = Image.create(T * GreyboxTiles.COLUMNS, T * GreyboxTiles.ROWS, false, Image.FORMAT_RGBA8)
	_image.fill(Color(0, 0, 0, 0))
	for height: int in GreyboxTiles.COLUMNS:
		var grass: Color = GreyboxTiles.GROUND_COLORS[height]
		_ground(Vector2i(height, GreyboxTiles.ROW_GROUND), grass)
		_stairs(Vector2i(height, GreyboxTiles.ROW_STAIRS), GreyboxTiles.STAIRS_COLOR.lightened(height * 0.03))
		_path(Vector2i(height, GreyboxTiles.ROW_PATH), GreyboxTiles.PATH_COLOR.lightened(height * 0.03))
	var row: int = GreyboxTiles.ROW_SOLID
	var meadow: Color = GreyboxTiles.GROUND_COLORS[0]
	_tree(Vector2i(0, row), meadow)
	_rock(Vector2i(1, row), meadow)
	_wall(Vector2i(2, row))
	_roof(Vector2i(3, row), ROOF_RED)
	_slate(Vector2i(4, row), ROOF_BLUE)
	_water(Vector2i(5, row))
	_fence(Vector2i(6, row), meadow)
	_stone(Vector2i(7, row))
	row = GreyboxTiles.ROW_FLOOR
	_door(Vector2i(0, row))
	_floor(Vector2i(1, row))
	_rug(Vector2i(2, row))
	_doormat(Vector2i(3, row))
	_dungeon_floor(Vector2i(4, row))
	_stairs_down(Vector2i(5, row))
	row = GreyboxTiles.ROW_FURNITURE
	_inner_wall(Vector2i(0, row))
	_table(Vector2i(1, row))
	_bed(Vector2i(2, row))
	_shelf(Vector2i(3, row))
	_barrel(Vector2i(4, row))
	_hearth(Vector2i(5, row))
	_dungeon_wall(Vector2i(6, row))
	_pillar(Vector2i(7, row))
	row = GreyboxTiles.ROW_DECOR
	_flowers(Vector2i(0, row), Color(0.90, 0.24, 0.30), Color(1.0, 0.86, 0.35))
	_flowers(Vector2i(1, row), Color(0.98, 0.84, 0.25), Color(0.92, 0.52, 0.18))
	_flowers(Vector2i(2, row), Color(0.52, 0.62, 0.96), Color(1.0, 0.96, 0.85))
	_tuft(Vector2i(3, row))
	_pebbles(Vector2i(4, row))
	_mushroom(Vector2i(5, row))
	_crops(Vector2i(6, row))
	_lily(Vector2i(7, row))
	row = GreyboxTiles.ROW_DETAIL
	_roof_ridge(Vector2i(0, row), ROOF_RED, false)
	_roof_eave(Vector2i(1, row), ROOF_RED, false)
	_roof_ridge(Vector2i(2, row), ROOF_BLUE, true)
	_roof_eave(Vector2i(3, row), ROOF_BLUE, true)
	_wall_window(Vector2i(4, row))
	for height: int in GreyboxTiles.COLUMNS:
		_ground(Vector2i(height, GreyboxTiles.ROW_SOLID_GROUND), GreyboxTiles.GROUND_COLORS[height])
	row = GreyboxTiles.ROW_PROPS
	_tree_art(Vector2i(0, row))
	_rock_art(Vector2i(1, row))
	_fence_art(Vector2i(2, row))
	_well([Vector2i(3, row), Vector2i(4, row), Vector2i(5, row), Vector2i(6, row)])
	DirAccess.make_dir_recursive_absolute(GreyboxTiles.TEXTURE_PATH.get_base_dir())
	var error: Error = _image.save_png(GreyboxTiles.TEXTURE_PATH)
	print("tools/greybox: wrote %s (%s)" % [GreyboxTiles.TEXTURE_PATH, error_string(error)])
	quit(0 if error == OK else 1)


func _px(tile: Vector2i, x: int, y: int, color: Color) -> void:
	if x >= 0 and y >= 0 and x < T and y < T:
		_image.set_pixel(tile.x * T + x, tile.y * T + y, color)


func _fill(tile: Vector2i, color: Color) -> void:
	_image.fill_rect(Rect2i(tile * T, Vector2i(T, T)), color)


## A small integer hash for scattered detail. Coordinates wrap at the tile size, so patterns
## made with it tile seamlessly.
func _hash(x: int, y: int, salt: int) -> int:
	var h: int = (posmod(x, T) * 73856093) ^ (posmod(y, T) * 19349663) ^ (salt * 83492791)
	h = (h ^ (h >> 13)) * 1274126177
	return absi(h ^ (h >> 16))


func _ellipse(tile: Vector2i, center: Vector2, radius: Vector2, color: Color) -> void:
	for y: int in T:
		for x: int in T:
			var d: Vector2 = (Vector2(x + 0.5, y + 0.5) - center) / radius
			if d.length_squared() <= 1.0:
				_px(tile, x, y, color)


## Grass: speckles of lighter and darker green and a few blades with light tips. Seamless.
func _ground(tile: Vector2i, color: Color) -> void:
	_fill(tile, color)
	for y: int in T:
		for x: int in T:
			var n: int = _hash(x, y, 1) % 100
			if n < 9:
				_px(tile, x, y, color.darkened(0.09))
			elif n < 13:
				_px(tile, x, y, color.lightened(0.08))
	for i: int in 6:
		var bx: int = _hash(i, 3, 7) % T
		var by: int = 1 + _hash(i, 9, 5) % (T - 3)
		_px(tile, bx, by, color.lightened(0.20))
		_px(tile, bx, by + 1, color.darkened(0.14))


## Stone steps: lit treads over shadowed risers, dark side edges.
func _stairs(tile: Vector2i, color: Color) -> void:
	_fill(tile, color.darkened(0.38))
	for step: int in 4:
		var y: int = step * 4
		_rect(tile, Rect2i(1, y, T - 2, 3), color)
		_rect(tile, Rect2i(1, y, T - 2, 1), color.lightened(0.22))
		for x: int in range(1, T - 1):
			if _hash(x, y + 1, 4) % 6 == 0:
				_px(tile, x, y + 1, color.darkened(0.12))
	_rect(tile, Rect2i(0, 0, 1, T), color.darkened(0.5))
	_rect(tile, Rect2i(T - 1, 0, 1, T), color.darkened(0.5))


## Packed earth: light and dark grains and a few pebbles. Seamless.
func _path(tile: Vector2i, color: Color) -> void:
	_fill(tile, color)
	for y: int in T:
		for x: int in T:
			var n: int = _hash(x, y, 2) % 100
			if n < 12:
				_px(tile, x, y, color.darkened(0.12))
			elif n < 18:
				_px(tile, x, y, color.lightened(0.10))
	for i: int in 3:
		var px: int = 1 + _hash(i, 1, 13) % (T - 3)
		var py: int = 1 + _hash(i, 2, 17) % (T - 3)
		_px(tile, px, py, Color(0.78, 0.74, 0.66))
		_px(tile, px + 1, py, Color(0.70, 0.66, 0.58))
		_px(tile, px, py + 1, color.darkened(0.32))
		_px(tile, px + 1, py + 1, color.darkened(0.32))


func _tree(tile: Vector2i, grass: Color) -> void:
	_ground(tile, grass)
	_tree_art(tile)


## A leafy tree, see-through around it: a soft shadow, a trunk, and a crown of four lobes lit
## from the top left, with leaf speckles.
func _tree_art(tile: Vector2i) -> void:
	var dark: Color = Color(0.11, 0.27, 0.14)
	var mid: Color = Color(0.18, 0.40, 0.19)
	var light: Color = Color(0.34, 0.58, 0.27)
	_ellipse(tile, Vector2(8.5, 13.8), Vector2(6.5, 2.4), SHADOW)
	_rect(tile, Rect2i(6, 10, 4, 5), OUTLINE)
	_rect(tile, Rect2i(7, 10, 2, 4), Color(0.42, 0.26, 0.14))
	var lobes: Array[Vector3] = [Vector3(5.2, 7.2, 4.3), Vector3(10.8, 7.2, 4.3), Vector3(8.0, 4.4, 4.7), Vector3(8.0, 8.6, 4.4)]
	for y: int in T:
		for x: int in T:
			var at: Vector2 = Vector2(x + 0.5, y + 0.5)
			var inside: bool = false
			var edge: bool = false
			for lobe: Vector3 in lobes:
				var d: float = at.distance_to(Vector2(lobe.x, lobe.y))
				inside = inside or d <= lobe.z
				edge = edge or d <= lobe.z + 1.0
			if inside:
				var shade: Color = mid
				if x + y < 11:
					shade = light
				elif x - y > 4 or y > 9:
					shade = dark
				var n: int = _hash(x, y, 21) % 9
				if n == 0:
					shade = shade.darkened(0.25)
				elif n == 1:
					shade = shade.lightened(0.18)
				_px(tile, x, y, shade)
			elif edge:
				_px(tile, x, y, OUTLINE)


func _rock(tile: Vector2i, grass: Color) -> void:
	_ground(tile, grass)
	_rock_art(tile)


## A boulder, see-through around it: a shadow, an outline, light from the top left, a crack
## and a patch of moss.
func _rock_art(tile: Vector2i) -> void:
	var stone: Color = Color(0.58, 0.58, 0.62)
	_ellipse(tile, Vector2(8.5, 12.8), Vector2(6.5, 2.2), SHADOW)
	_ellipse(tile, Vector2(8.0, 8.5), Vector2(6.8, 5.8), OUTLINE)
	_ellipse(tile, Vector2(8.0, 8.5), Vector2(5.8, 4.8), stone)
	_ellipse(tile, Vector2(6.5, 7.0), Vector2(3.2, 2.2), stone.lightened(0.18))
	_ellipse(tile, Vector2(10.0, 10.5), Vector2(3.0, 1.8), stone.darkened(0.2))
	for p: Vector2i in [Vector2i(9, 6), Vector2i(10, 7), Vector2i(10, 8)]:
		_px(tile, p.x, p.y, stone.darkened(0.4))
	for p: Vector2i in [Vector2i(5, 5), Vector2i(6, 5), Vector2i(7, 4), Vector2i(4, 6)]:
		_px(tile, p.x, p.y, Color(0.36, 0.55, 0.28))


## A timber-framed wall: plaster between beams, on a stone footing.
func _wall(tile: Vector2i) -> void:
	var plaster: Color = Color(0.91, 0.85, 0.71)
	var timber: Color = Color(0.40, 0.25, 0.13)
	_fill(tile, plaster)
	for y: int in T:
		for x: int in T:
			if _hash(x, y, 31) % 11 == 0:
				_px(tile, x, y, plaster.darkened(0.06))
	_rect(tile, Rect2i(0, 0, T, 2), timber)
	_rect(tile, Rect2i(0, 1, T, 1), timber.darkened(0.25))
	_rect(tile, Rect2i(0, 0, 1, 13), timber)
	_rect(tile, Rect2i(T - 1, 0, 1, 13), timber.darkened(0.2))
	var footing: Color = Color(0.52, 0.50, 0.52)
	_rect(tile, Rect2i(0, 12, T, 4), footing.darkened(0.35))
	for x: int in range(0, T, 4):
		var offset: int = 0 if x % 8 == 0 else 1
		_rect(tile, Rect2i(x, 12 + offset, 3, 2), footing)
		_px(tile, x, 12 + offset, footing.lightened(0.2))


## A wall with a window: a dark frame, panes of sky with a glint, and a box of flowers.
func _wall_window(tile: Vector2i) -> void:
	_wall(tile)
	var timber: Color = Color(0.36, 0.22, 0.12)
	_rect(tile, Rect2i(4, 3, 8, 7), timber)
	_rect(tile, Rect2i(5, 4, 6, 5), Color(0.46, 0.64, 0.82))
	_rect(tile, Rect2i(5, 4, 6, 1), Color(0.62, 0.78, 0.92))
	_rect(tile, Rect2i(7, 4, 1, 5), timber)
	_rect(tile, Rect2i(5, 6, 6, 1), timber)
	_px(tile, 5, 5, Color(0.95, 0.97, 1.0))
	_rect(tile, Rect2i(3, 10, 10, 2), Color(0.48, 0.30, 0.16))
	_rect(tile, Rect2i(3, 11, 10, 1), Color(0.34, 0.20, 0.10))
	for p: Vector2i in [Vector2i(4, 9), Vector2i(6, 9), Vector2i(9, 9), Vector2i(11, 9)]:
		_px(tile, p.x, p.y, Color(0.90, 0.30, 0.38) if p.x % 3 != 0 else Color(0.98, 0.85, 0.35))
	for p: Vector2i in [Vector2i(5, 9), Vector2i(8, 9), Vector2i(10, 9)]:
		_px(tile, p.x, p.y, Color(0.30, 0.55, 0.25))


## Clay roof tiles in staggered rows, each row lit along its top and shadowed below.
func _roof(tile: Vector2i, color: Color) -> void:
	_fill(tile, color.darkened(0.32))
	for row: int in 4:
		var y: int = row * 4
		var offset: int = 0 if row % 2 == 0 else 4
		for x: int in T:
			var seam: bool = posmod(x - offset, 8) == 0
			for dy: int in 3:
				var shade: Color = color
				if dy == 0:
					shade = color.lightened(0.14)
				elif seam:
					shade = color.darkened(0.22)
				elif _hash(x, y + dy, 41) % 10 == 0:
					shade = color.darkened(0.08)
				_px(tile, x, y + dy, shade)


## Slate roof: neat staggered shingles, cooler and flatter than clay.
func _slate(tile: Vector2i, color: Color) -> void:
	_fill(tile, color.darkened(0.35))
	for row: int in 4:
		var y: int = row * 4
		var offset: int = 0 if row % 2 == 0 else 3
		for x: int in T:
			if posmod(x - offset, 6) == 5:
				continue
			_px(tile, x, y, color.lightened(0.12))
			_px(tile, x, y + 1, color)
			_px(tile, x, y + 2, color.darkened(0.08) if _hash(x, y, 43) % 4 == 0 else color)


## A roof's top row: a ridge of capping along the top.
func _roof_ridge(tile: Vector2i, color: Color, slate: bool) -> void:
	if slate:
		_slate(tile, color)
	else:
		_roof(tile, color)
	var cap: Color = color.darkened(0.2)
	_rect(tile, Rect2i(0, 0, T, 4), cap)
	_rect(tile, Rect2i(0, 0, T, 1), cap.lightened(0.3))
	_rect(tile, Rect2i(0, 3, T, 1), cap.darkened(0.35))
	for x: int in range(2, T, 5):
		_px(tile, x, 1, cap.lightened(0.15))


## A roof's bottom row: the eaves, a lit edge over the shadow they cast.
func _roof_eave(tile: Vector2i, color: Color, slate: bool) -> void:
	if slate:
		_slate(tile, color)
	else:
		_roof(tile, color)
	_rect(tile, Rect2i(0, 12, T, 1), color.lightened(0.25))
	_rect(tile, Rect2i(0, 13, T, 3), Color(0.16, 0.10, 0.09))


## Deep water: a slightly lighter surface pattern, short ripples and a sparkle. Seamless.
func _water(tile: Vector2i) -> void:
	var deep: Color = Color(0.20, 0.42, 0.68)
	_fill(tile, deep)
	for y: int in T:
		for x: int in T:
			if _hash(x, y, 51) % 7 == 0:
				_px(tile, x, y, deep.lightened(0.06))
	var ripple: Color = Color(0.55, 0.74, 0.92)
	for i: int in 3:
		var rx: int = _hash(i, 5, 53) % T
		var ry: int = 2 + _hash(i, 7, 57) % (T - 4)
		for dx: int in 3:
			_px(tile, rx + dx, ry, ripple)
		_px(tile, rx - 1, ry + 1, deep.lightened(0.15))
		_px(tile, rx + 3, ry + 1, deep.lightened(0.15))
	_px(tile, _hash(9, 9, 59) % T, _hash(4, 4, 61) % T, Color(0.95, 0.98, 1.0))


func _fence(tile: Vector2i, grass: Color) -> void:
	_ground(tile, grass)
	_fence_art(tile)


## A wooden fence, see-through around it: capped posts, two rails, and their shadow.
func _fence_art(tile: Vector2i) -> void:
	var wood: Color = Color(0.62, 0.42, 0.22)
	_rect(tile, Rect2i(0, 13, T, 1), SHADOW)
	for y: int in [5, 9]:
		_rect(tile, Rect2i(0, y, T, 3), OUTLINE)
		_rect(tile, Rect2i(0, y + 1, T, 1), wood)
		_rect(tile, Rect2i(0, y + 1, T, 1), wood)
		_rect(tile, Rect2i(0, y, T, 1), wood.lightened(0.15))
	for post: int in [2, 12]:
		_rect(tile, Rect2i(post - 1, 2, 4, 12), OUTLINE)
		_rect(tile, Rect2i(post, 3, 2, 10), wood.darkened(0.12))
		_rect(tile, Rect2i(post, 3, 2, 1), wood.lightened(0.25))


## Cut stone blocks in mortar, each lit on top and shaded below, with a little colour variety.
func _stone(tile: Vector2i) -> void:
	var mortar: Color = Color(0.36, 0.36, 0.40)
	_fill(tile, mortar)
	for row: int in 3:
		var y: int = row * 5 + 1
		var offset: int = 0 if row % 2 == 0 else 4
		for block: int in range(-1, 3):
			var x: int = offset + block * 8
			var tint: float = float(_hash(block, row, 63) % 5) * 0.02
			var stone: Color = Color(0.60, 0.60, 0.63).lightened(tint)
			for dx: int in 7:
				for dy: int in 4:
					var c: Color = stone
					if dy == 0:
						c = stone.lightened(0.15)
					elif dy == 3:
						c = stone.darkened(0.18)
					_px(tile, x + dx, y + dy, c)


# --- Decorations (the Decor layer; see-through backgrounds) -------------------

## A few flowers with stems and leaves, petals round a contrasting centre.
func _flowers(tile: Vector2i, petal: Color, centre: Color) -> void:
	var spots: Array[Vector2i] = [Vector2i(4, 5), Vector2i(11, 4), Vector2i(7, 11), Vector2i(13, 12)]
	var stem: Color = Color(0.22, 0.48, 0.20)
	for spot: Vector2i in spots:
		_px(tile, spot.x, spot.y + 2, stem)
		_px(tile, spot.x, spot.y + 3, stem)
		_px(tile, spot.x - 1, spot.y + 3, stem.lightened(0.2))
		for d: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			_px(tile, spot.x + d.x, spot.y + d.y, petal)
		_px(tile, spot.x, spot.y, centre)


## A tuft of tall grass.
func _tuft(tile: Vector2i) -> void:
	for base: Vector2i in [Vector2i(4, 12), Vector2i(11, 8)]:
		for i: int in 5:
			var x: int = base.x - 2 + i
			var tall: int = 3 + (i % 3)
			for dy: int in tall:
				_px(tile, x, base.y - dy, Color(0.18, 0.42, 0.17) if dy < tall - 1 else Color(0.45, 0.70, 0.32))


func _pebbles(tile: Vector2i) -> void:
	for p: Vector3i in [Vector3i(4, 10, 2), Vector3i(10, 6, 1), Vector3i(12, 12, 2)]:
		var stone: Color = Color(0.66, 0.64, 0.62)
		_rect(tile, Rect2i(p.x, p.y, p.z + 1, 2), stone)
		_px(tile, p.x, p.y, stone.lightened(0.2))
		_rect(tile, Rect2i(p.x, p.y + 2, p.z + 1, 1), Color(0.18, 0.28, 0.14, 0.7))


func _mushroom(tile: Vector2i) -> void:
	for m: Vector2i in [Vector2i(5, 10), Vector2i(11, 7)]:
		_rect(tile, Rect2i(m.x, m.y, 2, 3), Color(0.94, 0.90, 0.80))
		_rect(tile, Rect2i(m.x - 2, m.y - 3, 6, 3), OUTLINE)
		_rect(tile, Rect2i(m.x - 1, m.y - 3, 4, 2), Color(0.82, 0.18, 0.16))
		_px(tile, m.x, m.y - 3, Color(1, 1, 1))
		_px(tile, m.x + 2, m.y - 2, Color(1, 1, 1))


## A vegetable patch: tilled furrows with rows of cabbages.
func _crops(tile: Vector2i) -> void:
	var soil: Color = Color(0.46, 0.31, 0.18)
	_fill(tile, soil)
	for y: int in [3, 7, 11, 15]:
		_rect(tile, Rect2i(0, y, T, 1), soil.darkened(0.3))
	for row: int in 2:
		for col: int in 2:
			var c: Vector2 = Vector2(4.5 + col * 8, 4.5 + row * 8)
			_ellipse(tile, c + Vector2(0, 1), Vector2(3.4, 2.6), Color(0.15, 0.32, 0.14))
			_ellipse(tile, c, Vector2(3.0, 2.4), Color(0.36, 0.62, 0.28))
			_ellipse(tile, c + Vector2(-0.5, -0.5), Vector2(1.4, 1.1), Color(0.58, 0.80, 0.42))


## Lily pads with a pink flower, for ponds.
func _lily(tile: Vector2i) -> void:
	for pad: Vector3 in [Vector3(5, 6, 3.2), Vector3(11, 11, 3.6)]:
		_ellipse(tile, Vector2(pad.x, pad.y + 0.6), Vector2(pad.z, pad.z * 0.8), Color(0.12, 0.32, 0.20))
		_ellipse(tile, Vector2(pad.x, pad.y), Vector2(pad.z, pad.z * 0.8), Color(0.30, 0.60, 0.30))
		_px(tile, int(pad.x), int(pad.y), Color(0.20, 0.42, 0.68))
		_px(tile, int(pad.x) + 1, int(pad.y) - 1, Color(0.20, 0.42, 0.68))
	for p: Vector2i in [Vector2i(10, 10), Vector2i(12, 10), Vector2i(11, 9), Vector2i(11, 11)]:
		_px(tile, p.x, p.y, Color(0.96, 0.62, 0.78))
	_px(tile, 11, 10, Color(1.0, 0.90, 0.40))


func _rect(tile: Vector2i, rect: Rect2i, color: Color) -> void:
	for y: int in range(rect.position.y, rect.end.y):
		for x: int in range(rect.position.x, rect.end.x):
			_px(tile, x, y, color)


## A plank door in the timber wall, under a dark lintel.
func _door(tile: Vector2i) -> void:
	_wall(tile)
	var wood: Color = Color(0.40, 0.24, 0.12)
	_rect(tile, Rect2i(3, 2, 10, 14), OUTLINE)
	_rect(tile, Rect2i(4, 3, 8, 13), wood)
	for x: int in [6, 9]:
		_rect(tile, Rect2i(x, 3, 1, 13), wood.darkened(0.3))
	_rect(tile, Rect2i(4, 3, 8, 1), wood.lightened(0.15))
	_px(tile, 10, 9, Color(0.85, 0.75, 0.35))


## Wooden planks running east-west, with staggered seams.
func _floor(tile: Vector2i) -> void:
	var wood: Color = Color(0.58, 0.40, 0.24)
	_fill(tile, wood)
	for y: int in T:
		if y % 4 == 3:
			_rect(tile, Rect2i(0, y, T, 1), wood.darkened(0.28))
		else:
			@warning_ignore("integer_division")
			var seam: int = 3 if (y / 4) % 2 == 0 else 11
			_px(tile, seam, y, wood.darkened(0.22))


func _rug(tile: Vector2i) -> void:
	var red: Color = Color(0.62, 0.20, 0.18)
	_fill(tile, red)
	for y: int in T:
		for x: int in T:
			if (x + y) % 6 == 0:
				_px(tile, x, y, red.lightened(0.18))
	_rect(tile, Rect2i(0, 1, T, 1), Color(0.86, 0.70, 0.36))
	_rect(tile, Rect2i(0, 14, T, 1), Color(0.86, 0.70, 0.36))


## A woven mat on the floor by the way out.
func _doormat(tile: Vector2i) -> void:
	_floor(tile)
	var straw: Color = Color(0.78, 0.66, 0.38)
	_rect(tile, Rect2i(1, 3, 14, 11), straw.darkened(0.35))
	_rect(tile, Rect2i(2, 4, 12, 9), straw)
	for y: int in range(4, 13, 2):
		_rect(tile, Rect2i(2, y, 12, 1), straw.darkened(0.15))


## Dark log wall of a room.
func _inner_wall(tile: Vector2i) -> void:
	var log_color: Color = Color(0.33, 0.24, 0.18)
	_fill(tile, log_color)
	for y: int in T:
		if y % 5 == 4:
			_rect(tile, Rect2i(0, y, T, 1), log_color.darkened(0.45))
		elif y % 5 == 0:
			_rect(tile, Rect2i(0, y, T, 1), log_color.lightened(0.12))


func _table(tile: Vector2i) -> void:
	_floor(tile)
	var top: Color = Color(0.70, 0.50, 0.30)
	_rect(tile, Rect2i(1, 2, 14, 12), OUTLINE)
	_rect(tile, Rect2i(2, 3, 12, 9), top)
	_rect(tile, Rect2i(2, 12, 12, 1), top.darkened(0.35))
	_rect(tile, Rect2i(5, 6, 4, 3), Color(0.90, 0.88, 0.80))


func _bed(tile: Vector2i) -> void:
	_floor(tile)
	_rect(tile, Rect2i(1, 0, 14, 16), OUTLINE)
	_rect(tile, Rect2i(2, 1, 12, 14), Color(0.48, 0.30, 0.16))
	_rect(tile, Rect2i(3, 2, 10, 4), Color(0.92, 0.90, 0.84))
	_rect(tile, Rect2i(3, 6, 10, 8), Color(0.30, 0.42, 0.66))
	_rect(tile, Rect2i(3, 6, 10, 1), Color(0.30, 0.42, 0.66).lightened(0.25))


## Shelves of jars and books against the wall.
func _shelf(tile: Vector2i) -> void:
	var wood: Color = Color(0.46, 0.30, 0.17)
	_fill(tile, wood.darkened(0.3))
	for y: int in [6, 13]:
		_rect(tile, Rect2i(0, y, T, 2), wood)
	var colors: Array[Color] = [Color(0.70, 0.22, 0.20), Color(0.25, 0.45, 0.65), Color(0.80, 0.70, 0.30), Color(0.35, 0.55, 0.30)]
	for i: int in 5:
		_rect(tile, Rect2i(1 + i * 3, 1 + (i % 2), 2, 5 - (i % 2)), colors[i % colors.size()])
		_rect(tile, Rect2i(1 + i * 3, 9 + ((i + 1) % 2), 2, 4 - ((i + 1) % 2)), colors[(i + 2) % colors.size()])


func _barrel(tile: Vector2i) -> void:
	_floor(tile)
	var wood: Color = Color(0.55, 0.36, 0.20)
	for y: int in T:
		for x: int in T:
			var d: float = Vector2(x - 7.5, y - 7.5).length()
			if d <= 7.0:
				_px(tile, x, y, OUTLINE)
			if d <= 6.0:
				_px(tile, x, y, wood.lightened(0.12) if d < 3.5 else wood)
			if d > 4.5 and d <= 5.2:
				_px(tile, x, y, Color(0.30, 0.30, 0.32))


## A stone fireplace with a fire in it.
func _hearth(tile: Vector2i) -> void:
	_stone(tile)
	_rect(tile, Rect2i(3, 5, 10, 11), OUTLINE)
	_rect(tile, Rect2i(4, 6, 8, 10), Color(0.12, 0.08, 0.06))
	_rect(tile, Rect2i(5, 11, 6, 5), Color(0.92, 0.46, 0.14))
	_rect(tile, Rect2i(6, 9, 4, 4), Color(0.98, 0.70, 0.22))
	_rect(tile, Rect2i(7, 8, 2, 3), Color(1.0, 0.92, 0.55))


## Cold flagstones.
func _dungeon_floor(tile: Vector2i) -> void:
	var stone: Color = Color(0.30, 0.31, 0.36)
	_fill(tile, stone)
	for y: int in T:
		for x: int in T:
			if x % 8 == 7 or y % 8 == 7:
				_px(tile, x, y, stone.darkened(0.35))
			elif (x * 3 + y * 7) % 17 == 0:
				_px(tile, x, y, stone.lightened(0.10))


## A stairway going down into the dark.
func _stairs_down(tile: Vector2i) -> void:
	var stone: Color = Color(0.48, 0.47, 0.50)
	_fill(tile, OUTLINE)
	for step: int in 4:
		var y: int = 2 + step * 3
		var inset: int = 1 + step
		_rect(tile, Rect2i(inset, y, T - inset * 2, 2), stone.darkened(step * 0.18))
	_rect(tile, Rect2i(0, 0, T, 1), stone.lightened(0.15))


## Dark stone blocks of a dungeon wall.
func _dungeon_wall(tile: Vector2i) -> void:
	var stone: Color = Color(0.22, 0.22, 0.28)
	_fill(tile, stone)
	for y: int in T:
		if y % 4 == 3:
			_rect(tile, Rect2i(0, y, T, 1), stone.darkened(0.5))
		else:
			@warning_ignore("integer_division")
			var seam: int = 3 if (y / 4) % 2 == 0 else 11
			_px(tile, seam, y, stone.darkened(0.5))
			if y % 4 == 0:
				_rect(tile, Rect2i(0, y, T, 1), stone.lightened(0.08))


## A squat stone pillar on the flagstones.
func _pillar(tile: Vector2i) -> void:
	_dungeon_floor(tile)
	var stone: Color = Color(0.55, 0.55, 0.60)
	_rect(tile, Rect2i(2, 1, 12, 14), OUTLINE)
	_rect(tile, Rect2i(3, 2, 10, 12), stone)
	_rect(tile, Rect2i(3, 2, 10, 2), stone.lightened(0.2))
	_rect(tile, Rect2i(3, 11, 10, 3), stone.darkened(0.25))


## The village well, 2x2 tiles drawn as one picture and cut into quarters (nw, ne, sw, se):
## a ring of stones round dark water, a wooden frame with a crossbar, a rope and a bucket.
func _well(quarters: Array[Vector2i]) -> void:
	var size: int = T * 2
	var art: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	art.fill(Color(0, 0, 0, 0))
	var centre: Vector2 = Vector2(16.0, 15.0)
	var stone: Color = Color(0.62, 0.62, 0.66)
	for y: int in size:
		for x: int in size:
			var at: Vector2 = Vector2(x + 0.5, y + 0.5)
			var shadow: Vector2 = (at - Vector2(16.5, 27.0)) / Vector2(13.0, 4.0)
			if shadow.length_squared() <= 1.0:
				art.set_pixel(x, y, SHADOW)
			var d: float = at.distance_to(centre)
			if d <= 13.0:
				art.set_pixel(x, y, OUTLINE)
			if d <= 12.0:
				var angle: float = atan2(at.y - centre.y, at.x - centre.x)
				var brick: int = int(floor((angle + PI) / (TAU / 14.0)))
				var c: Color = stone.lightened(0.08) if brick % 2 == 0 else stone.darkened(0.06)
				if y < centre.y - 4:
					c = c.lightened(0.10)
				art.set_pixel(x, y, c)
			if d <= 8.0:
				art.set_pixel(x, y, OUTLINE)
			if d <= 7.0:
				var water: Color = Color(0.10, 0.20, 0.34)
				if Vector2(x - 13, y - 12).length() < 2.5:
					water = Color(0.30, 0.48, 0.66)
				art.set_pixel(x, y, water)
	var wood: Color = Color(0.48, 0.30, 0.16)
	for post_x: int in [3, 27]:
		for y: int in range(4, 20):
			art.set_pixel(post_x, y, OUTLINE)
			art.set_pixel(post_x + 1, y, wood)
			art.set_pixel(post_x + 2, y, OUTLINE)
	for x: int in range(3, 30):
		art.set_pixel(x, 3, OUTLINE)
		art.set_pixel(x, 4, wood.lightened(0.15))
		art.set_pixel(x, 5, wood.darkened(0.2))
	for y: int in range(6, 12):
		art.set_pixel(16, y, Color(0.85, 0.78, 0.60))
	for y: int in range(12, 16):
		for x: int in range(14, 19):
			art.set_pixel(x, y, OUTLINE if x == 14 or x == 18 or y == 15 else Color(0.55, 0.36, 0.18))
	var origins: Array[Vector2i] = [Vector2i(0, 0), Vector2i(T, 0), Vector2i(0, T), Vector2i(T, T)]
	for i: int in 4:
		_image.blit_rect(art, Rect2i(origins[i], Vector2i(T, T)), quarters[i] * T)
