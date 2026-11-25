extends GdUnitTestSuite
## The ground tiles (the art pack's since the farm-look plan's phase A, each in its old place).
## They are calm and whole: each ground's heights share one pattern, a solid twin is its ground's
## picture, and the plain colour is still most of a tile, so pickups, crops and debris read on it.
## The pack's grass is one flat colour, as its artist drew it, and so is the marsh's ground: their
## texture is the ground details' (a flat tile has no grain of its own to check).

const SIZE: int = GreyboxTiles.TILE_SIZE
## Rows whose eight columns (heights 0 to 7) are one pattern in eight sets of colours.
const LAYERED_ROWS: Array[int] = [GreyboxTiles.ROW_GROUND, GreyboxTiles.ROW_PATH, GreyboxTiles.ROW_SOLID_GROUND, GreyboxTiles.ROW_LEDGE]
## Ground that walks and the same ground under a prop: one picture.
const TWINS: Array = [
	[Vector2i(0, GreyboxTiles.ROW_MARSH), Vector2i(1, GreyboxTiles.ROW_MARSH)],
	[Vector2i(0, GreyboxTiles.ROW_QUARRY), Vector2i(1, GreyboxTiles.ROW_QUARRY)],
]
## The grained tiles: the path, the dungeon floor, the ledge and the quarry's earth, and how
## many of a tile's 256 pixels the plain colour keeps at the least (the pack's cobbles are stone
## and mortar in near equal parts, so the floor's count is the ledge's).
const PLAIN_AT_LEAST: Dictionary = {
	Vector2i(0, 2): 151, Vector2i(4, 4): 100, Vector2i(0, 10): 100, Vector2i(0, 25): 151,
}
## The flat tiles: the grass a map uses (heights 0 to 2) and the marsh's ground.
const FLAT: Array[Vector2i] = [Vector2i(0, 0), Vector2i(1, 0), Vector2i(2, 0), Vector2i(0, 23)]


func test_each_grounds_heights_share_one_pattern() -> void:
	var image: Image = _atlas()
	for row: int in LAYERED_ROWS:
		var first: PackedInt32Array = _pattern(image, Vector2i(0, row))
		for column: int in range(1, GreyboxTiles.COLUMNS):
			assert_bool(_pattern(image, Vector2i(column, row)) == first).override_failure_message("row %d, height %d: the pattern of height 0" % [row, column]).is_true()


func test_the_solid_ground_is_the_grass_and_each_twin_is_its_ground() -> void:
	var image: Image = _atlas()
	for column: int in GreyboxTiles.COLUMNS:
		assert_bool(_same_picture(image, Vector2i(column, GreyboxTiles.ROW_GROUND), Vector2i(column, GreyboxTiles.ROW_SOLID_GROUND))).override_failure_message("height %d: solid ground looks like grass" % column).is_true()
	for pair: Array in TWINS:
		assert_bool(_same_picture(image, pair[0], pair[1])).override_failure_message("%s and %s are one picture" % pair).is_true()


func test_the_plain_colour_is_still_most_of_each_grained_tile() -> void:
	var image: Image = _atlas()
	for tile: Vector2i in PLAIN_AT_LEAST:
		var counts: Dictionary = _counts(image, tile)
		var top: int = 0
		var busy: int = 0
		for key: String in counts:
			top = maxi(top, int(counts[key]))
		for key: String in counts:
			if int(counts[key]) < top:
				busy += int(counts[key])
		assert_int(top).override_failure_message("%s: the plain colour keeps %d pixels" % [tile, top]).is_greater_equal(int(PLAIN_AT_LEAST[tile]))
		assert_int(busy).override_failure_message("%s: there is grain" % tile).is_greater(0)


func test_the_grass_and_the_marsh_are_one_flat_colour_each_its_own() -> void:
	var image: Image = _atlas()
	var seen: Dictionary = {}
	for tile: Vector2i in FLAT:
		var counts: Dictionary = _counts(image, tile)
		assert_int(counts.size()).override_failure_message("%s is one colour" % tile).is_equal(1)
		assert_bool(seen.has(counts.keys()[0])).override_failure_message("%s has a colour of its own" % tile).is_false()
		seen[counts.keys()[0]] = true


func _atlas() -> Image:
	return (load(GreyboxTiles.TEXTURE_PATH) as Texture2D).get_image()


## Each pixel as the index of its colour in the order the colours are met: two tiles with the
## same pattern in different colours give the same list.
func _pattern(image: Image, tile: Vector2i) -> PackedInt32Array:
	var seen: Dictionary = {}
	var out: PackedInt32Array = PackedInt32Array()
	for y: int in SIZE:
		for x: int in SIZE:
			var key: String = image.get_pixel(tile.x * SIZE + x, tile.y * SIZE + y).to_html(true)
			if not seen.has(key):
				seen[key] = seen.size()
			out.append(int(seen[key]))
	return out


func _same_picture(image: Image, a: Vector2i, b: Vector2i) -> bool:
	for y: int in SIZE:
		for x: int in SIZE:
			if image.get_pixel(a.x * SIZE + x, a.y * SIZE + y) != image.get_pixel(b.x * SIZE + x, b.y * SIZE + y):
				return false
	return true


func _counts(image: Image, tile: Vector2i) -> Dictionary:
	var counts: Dictionary = {}
	for y: int in SIZE:
		for x: int in SIZE:
			var key: String = image.get_pixel(tile.x * SIZE + x, tile.y * SIZE + y).to_html(true)
			counts[key] = int(counts.get(key, 0)) + 1
	return counts
