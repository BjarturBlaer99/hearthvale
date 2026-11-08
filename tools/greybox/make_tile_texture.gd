extends SceneTree
## Paints the greybox tile atlas (see GreyboxTiles for the layout). Step 1 of 4:
##   godot --headless --path . -s res://tools/greybox/make_tile_texture.gd
##   godot --headless --path . --import
##   godot --headless --path . -s res://tools/greybox/build_tileset.gd
##   godot --headless --path . -s res://tools/greybox/build_maps.gd

const T: int = GreyboxTiles.TILE_SIZE
const OUTLINE: Color = Color(0.10, 0.08, 0.12)

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
	_roof(Vector2i(3, row), Color(0.70, 0.27, 0.20))
	_roof(Vector2i(4, row), Color(0.27, 0.38, 0.62))
	_water(Vector2i(5, row))
	_fence(Vector2i(6, row), meadow)
	_stone(Vector2i(7, row))
	row = GreyboxTiles.ROW_FLOOR
	_door(Vector2i(0, row))
	_floor(Vector2i(1, row))
	_rug(Vector2i(2, row))
	_doormat(Vector2i(3, row))
	row = GreyboxTiles.ROW_FURNITURE
	_inner_wall(Vector2i(0, row))
	_table(Vector2i(1, row))
	_bed(Vector2i(2, row))
	_shelf(Vector2i(3, row))
	_barrel(Vector2i(4, row))
	_hearth(Vector2i(5, row))
	DirAccess.make_dir_recursive_absolute(GreyboxTiles.TEXTURE_PATH.get_base_dir())
	var error: Error = _image.save_png(GreyboxTiles.TEXTURE_PATH)
	print("tools/greybox: wrote %s (%s)" % [GreyboxTiles.TEXTURE_PATH, error_string(error)])
	quit(0 if error == OK else 1)


func _px(tile: Vector2i, x: int, y: int, color: Color) -> void:
	if x >= 0 and y >= 0 and x < T and y < T:
		_image.set_pixel(tile.x * T + x, tile.y * T + y, color)


func _fill(tile: Vector2i, color: Color) -> void:
	_image.fill_rect(Rect2i(tile * T, Vector2i(T, T)), color)


## Grass with a scatter of lighter and darker blades.
func _ground(tile: Vector2i, color: Color) -> void:
	_fill(tile, color)
	for y: int in T:
		for x: int in T:
			var n: int = (x * 7 + y * 13) % 23
			if n == 0:
				_px(tile, x, y, color.lightened(0.14))
			elif n == 11:
				_px(tile, x, y, color.darkened(0.12))


func _stairs(tile: Vector2i, color: Color) -> void:
	_fill(tile, color)
	for y: int in T:
		if y % 4 == 0:
			for x: int in T:
				_px(tile, x, y, color.lightened(0.18))
		elif y % 4 == 3:
			for x: int in T:
				_px(tile, x, y, color.darkened(0.25))


func _path(tile: Vector2i, color: Color) -> void:
	_fill(tile, color)
	for y: int in T:
		for x: int in T:
			var n: int = (x * 5 + y * 11) % 19
			if n == 0:
				_px(tile, x, y, color.darkened(0.18))
			elif n == 7:
				_px(tile, x, y, color.lightened(0.12))


func _tree(tile: Vector2i, grass: Color) -> void:
	_ground(tile, grass)
	var leaves: Color = Color(0.17, 0.38, 0.17)
	for y: int in T:
		for x: int in T:
			var d: float = Vector2(x - 7.5, y - 7.0).length()
			if d <= 7.2:
				_px(tile, x, y, OUTLINE)
			if d <= 6.2:
				var lit: bool = x + y < 12 and d < 4.5
				_px(tile, x, y, leaves.lightened(0.18) if lit else leaves)


func _rock(tile: Vector2i, grass: Color) -> void:
	_ground(tile, grass)
	var stone: Color = Color(0.55, 0.55, 0.58)
	for y: int in T:
		for x: int in T:
			var d: float = Vector2((x - 7.5) / 1.1, y - 8.5).length()
			if d <= 6.4:
				_px(tile, x, y, OUTLINE)
			if d <= 5.4:
				_px(tile, x, y, stone.lightened(0.2) if (x < 7 and y < 8) else stone)


## Plaster between timber beams.
func _wall(tile: Vector2i) -> void:
	var plaster: Color = Color(0.86, 0.79, 0.63)
	var timber: Color = Color(0.42, 0.27, 0.15)
	_fill(tile, plaster)
	for x: int in T:
		_px(tile, x, 0, timber)
		_px(tile, x, 15, timber)
	for y: int in T:
		_px(tile, 0, y, timber)
		_px(tile, 15, y, timber)
		_px(tile, 7, y, timber)


func _roof(tile: Vector2i, color: Color) -> void:
	_fill(tile, color)
	for y: int in T:
		if y % 4 == 3:
			for x: int in T:
				_px(tile, x, y, color.darkened(0.3))
		else:
			@warning_ignore("integer_division")
			var offset: int = 0 if (y / 4) % 2 == 0 else 4
			for x: int in range(offset, T, 8):
				_px(tile, x, y, color.darkened(0.2))


func _water(tile: Vector2i) -> void:
	var blue: Color = Color(0.24, 0.47, 0.72)
	_fill(tile, blue)
	for point: Vector2i in [Vector2i(2, 3), Vector2i(3, 3), Vector2i(4, 3), Vector2i(9, 8), Vector2i(10, 8), Vector2i(11, 8), Vector2i(5, 12), Vector2i(6, 12)]:
		_px(tile, point.x, point.y, blue.lightened(0.3))


func _fence(tile: Vector2i, grass: Color) -> void:
	_ground(tile, grass)
	var wood: Color = Color(0.52, 0.34, 0.18)
	for x: int in T:
		for y: int in [6, 10]:
			_px(tile, x, y, wood)
			_px(tile, x, y + 1, wood.darkened(0.3))
	for post: int in [2, 13]:
		for y: int in range(3, 14):
			_px(tile, post, y, wood.darkened(0.15))


func _stone(tile: Vector2i) -> void:
	var stone: Color = Color(0.60, 0.60, 0.62)
	_fill(tile, stone)
	for y: int in T:
		if y % 5 == 4:
			for x: int in T:
				_px(tile, x, y, stone.darkened(0.3))
		else:
			@warning_ignore("integer_division")
			var offset: int = 2 if (y / 5) % 2 == 0 else 7
			_px(tile, offset, y, stone.darkened(0.3))
			_px(tile, (offset + 8) % T, y, stone.darkened(0.3))


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
