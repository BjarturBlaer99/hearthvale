extends SceneTree
## Paints the greybox tile atlas (see GreyboxTiles for the layout). Step 1 of 4:
##   godot --headless --path . -s res://tools/greybox/make_tile_texture.gd
##   godot --headless --path . --import
##   godot --headless --path . -s res://tools/greybox/build_tileset.gd
##   godot --headless --path . -s res://tools/greybox/build_st_aud.gd

const T: int = GreyboxTiles.TILE_SIZE


func _initialize() -> void:
	var image: Image = Image.create(T * GreyboxTiles.COLUMNS, T * GreyboxTiles.ROWS, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for height: int in GreyboxTiles.COLUMNS:
		var base: Color = GreyboxTiles.HEIGHT_COLORS[height]
		_fill(image, Vector2i(height, GreyboxTiles.ROW_PLAIN), base)
		_fill(image, Vector2i(height, GreyboxTiles.ROW_CLIMBABLE), base)
		_ivy(image, Vector2i(height, GreyboxTiles.ROW_CLIMBABLE))
		_fill(image, Vector2i(height, GreyboxTiles.ROW_RAMP), base)
		_steps(image, Vector2i(height, GreyboxTiles.ROW_RAMP), base)
	_fill(image, GreyboxTiles.WATER_SHALLOW, GreyboxTiles.SHALLOW_COLOR)
	_ripples(image, GreyboxTiles.WATER_SHALLOW, GreyboxTiles.SHALLOW_COLOR.lightened(0.25))
	_fill(image, GreyboxTiles.WATER_DEEP, GreyboxTiles.DEEP_COLOR)
	_ripples(image, GreyboxTiles.WATER_DEEP, GreyboxTiles.DEEP_COLOR.lightened(0.15))
	DirAccess.make_dir_recursive_absolute(GreyboxTiles.TEXTURE_PATH.get_base_dir())
	var error: Error = image.save_png(GreyboxTiles.TEXTURE_PATH)
	print("tools/greybox: wrote %s (%s)" % [GreyboxTiles.TEXTURE_PATH, error_string(error)])
	quit(0 if error == OK else 1)


func _fill(image: Image, tile: Vector2i, color: Color) -> void:
	image.fill_rect(Rect2i(tile * T, Vector2i(T, T)), color)


## Vertical ivy strands with gaps, so climbable faces read at a glance.
func _ivy(image: Image, tile: Vector2i) -> void:
	for x: int in T:
		if x % 4 == 0 or x % 4 == 3:
			continue
		for y: int in T:
			if (y + x * 3) % 5 != 0:
				var leaf: Color = GreyboxTiles.IVY_COLOR.lightened(0.12 if (x + y) % 3 == 0 else 0.0)
				image.set_pixel(tile.x * T + x, tile.y * T + y, leaf)


## Horizontal step edges, so ramps read as stairs.
func _steps(image: Image, tile: Vector2i, base: Color) -> void:
	for y: int in T:
		var shade: Color
		if y % 4 == 0:
			shade = base.lightened(0.18)
		elif y % 4 == 3:
			shade = base.darkened(0.22)
		else:
			continue
		for x: int in T:
			image.set_pixel(tile.x * T + x, tile.y * T + y, shade)


func _ripples(image: Image, tile: Vector2i, color: Color) -> void:
	for point: Vector2i in [Vector2i(3, 4), Vector2i(4, 4), Vector2i(10, 9), Vector2i(11, 9), Vector2i(12, 9), Vector2i(6, 13), Vector2i(7, 13)]:
		image.set_pixel(tile.x * T + point.x, tile.y * T + point.y, color)
