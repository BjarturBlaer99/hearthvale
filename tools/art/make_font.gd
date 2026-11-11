extends SceneTree
## Paints Hearthvale's own pixel font from ASCII art and bakes it, with the UI theme that uses
## it (art pass 4):
##   godot --headless --path . -s res://tools/art/make_font.gd -- <preview.png>
## Writes ui/font/hearth_font.tres (a bitmap FontFile, size 8, whole-number scaling only) and
## ui/theme.tres (that font, with a one-pixel shadow under every label), and points the project
## at the theme. Edit the letters here, never the baked files.
##
## Each glyph is rows of '#' and '.', top to bottom, split by '/'. Rows 1-7 are the capital
## height, with the baseline under row 7; rows 8-9 hold descenders. Missing rows are empty.

const FONT_PATH: String = "res://ui/font/hearth_font.tres"
const THEME_PATH: String = "res://ui/theme.tres"
## The size labels ask for, the line height and where the baseline sits in it (px).
const SIZE: int = 8
const LINE_HEIGHT: int = 11
const BASE: int = 8
const ROWS: int = 9
## The atlas: cells of 8x10 px, 16 across.
const CELL: Vector2i = Vector2i(8, 10)
const ACROSS: int = 16
const SPACE_ADVANCE: int = 3
const SHADOW: Color = Color(0.05, 0.03, 0.09, 0.85)

const GLYPHS: Dictionary = {
	"A": ".###./#...#/#...#/#####/#...#/#...#/#...#",
	"B": "####./#...#/#...#/####./#...#/#...#/####.",
	"C": ".###./#...#/#..../#..../#..../#...#/.###.",
	"D": "####./#...#/#...#/#...#/#...#/#...#/####.",
	"E": "#####/#..../#..../####./#..../#..../#####",
	"F": "#####/#..../#..../####./#..../#..../#....",
	"G": ".###./#...#/#..../#.###/#...#/#...#/.###.",
	"H": "#...#/#...#/#...#/#####/#...#/#...#/#...#",
	"I": "###/.#./.#./.#./.#./.#./###",
	"J": "..###/...#./...#./...#./...#./#..#./.##..",
	"K": "#...#/#..#./#.#../##.../#.#../#..#./#...#",
	"L": "#..../#..../#..../#..../#..../#..../#####",
	"M": "#...#/##.##/#.#.#/#.#.#/#...#/#...#/#...#",
	"N": "#...#/##..#/#.#.#/#..##/#...#/#...#/#...#",
	"O": ".###./#...#/#...#/#...#/#...#/#...#/.###.",
	"P": "####./#...#/#...#/####./#..../#..../#....",
	"Q": ".###./#...#/#...#/#...#/#.#.#/#..#./.##.#",
	"R": "####./#...#/#...#/####./#.#../#..#./#...#",
	"S": ".####/#..../#..../.###./....#/....#/####.",
	"T": "#####/..#../..#../..#../..#../..#../..#..",
	"U": "#...#/#...#/#...#/#...#/#...#/#...#/.###.",
	"V": "#...#/#...#/#...#/#...#/.#.#./.#.#./..#..",
	"W": "#...#/#...#/#...#/#.#.#/#.#.#/##.##/#...#",
	"X": "#...#/#...#/.#.#./..#../.#.#./#...#/#...#",
	"Y": "#...#/#...#/.#.#./..#../..#../..#../..#..",
	"Z": "#####/....#/...#./..#../.#.../#..../#####",
	"a": "..../..../.##./...#/.###/#..#/.###",
	"b": "#.../#.../###./#..#/#..#/#..#/###.",
	"c": "..../..../.###/#.../#.../#.../.###",
	"d": "...#/...#/.###/#..#/#..#/#..#/.###",
	"e": "..../..../.##./#..#/####/#.../.###",
	"f": "..##/.#../###./.#../.#../.#../.#..",
	"g": "..../..../.###/#..#/#..#/#..#/.###/...#/.##.",
	"h": "#.../#.../###./#..#/#..#/#..#/#..#",
	"i": "#/./#/#/#/#/#",
	"j": "..#/.../..#/..#/..#/..#/..#/..#/##.",
	"k": "#.../#.../#..#/#.#./##../#.#./#..#",
	"l": "#/#/#/#/#/#/#",
	"m": "...../...../##.#./#.#.#/#.#.#/#.#.#/#.#.#",
	"n": "..../..../###./#..#/#..#/#..#/#..#",
	"o": "..../..../.##./#..#/#..#/#..#/.##.",
	"p": "..../..../###./#..#/#..#/#..#/###./#.../#...",
	"q": "..../..../.###/#..#/#..#/#..#/.###/...#/...#",
	"r": "..../..../#.##/##../#.../#.../#...",
	"s": "..../..../.###/#.../.##./...#/###.",
	"t": ".#../.#../###./.#../.#../.#../..##",
	"u": "..../..../#..#/#..#/#..#/#..#/.###",
	"v": ".../.../#.#/#.#/#.#/#.#/.#.",
	"w": "...../...../#...#/#...#/#.#.#/#.#.#/.#.#.",
	"x": "..../..../#..#/#..#/.##./#..#/#..#",
	"y": "..../..../#..#/#..#/#..#/#..#/.###/...#/.##.",
	"z": "..../..../####/...#/.##./#.../####",
	"0": ".###./#...#/#..##/#.#.#/##..#/#...#/.###.",
	"1": "..#../.##../..#../..#../..#../..#../.###.",
	"2": ".###./#...#/....#/...#./..#../.#.../#####",
	"3": "####./....#/....#/.###./....#/....#/####.",
	"4": "...#./..##./.#.#./#..#./#####/...#./...#.",
	"5": "#####/#..../####./....#/....#/#...#/.###.",
	"6": ".###./#..../#..../####./#...#/#...#/.###.",
	"7": "#####/....#/...#./..#../..#../..#../..#..",
	"8": ".###./#...#/#...#/.###./#...#/#...#/.###.",
	"9": ".###./#...#/#...#/.####/....#/....#/.###.",
	"!": "#/#/#/#/#/./#",
	"\"": "#.#/#.#",
	"#": ".#.#./.#.#./#####/.#.#./#####/.#.#./.#.#.",
	"$": "..#../.####/#.#../.###./..#.#/####./..#..",
	"%": "##..#/##.#./...#./..#../.#.../.#.##/#..##",
	"&": ".##../#..#./#.#../.#.../#.#.#/#..#./.##.#",
	"'": "#/#",
	"(": ".#/#./#./#./#./#./.#",
	")": "#./.#/.#/.#/.#/.#/#.",
	"*": ".../#.#/.#./#.#",
	"+": "...../..#../..#../#####/..#../..#..",
	",": "../../../../../../.#/#.",
	"-": ".../.../.../###",
	".": "././././././#",
	"/": "....#/...#./...#./..#../.#.../.#.../#....",
	":": "./././#/././#",
	";": "../../../.#/../../.#/#.",
	"<": "...#/..#./.#../#.../.#../..#./...#",
	"=": "..../..../####/..../####",
	">": "#.../.#../..#./...#/..#./.#../#...",
	"?": ".###./#...#/....#/...#./..#../...../..#..",
	"@": ".###./#...#/#.###/#.#.#/#.###/#..../.###.",
	"[": "##/#./#./#./#./#./##",
	"\\": "#..../.#.../.#.../..#../...#./...#./....#",
	"]": "##/.#/.#/.#/.#/.#/##",
	"^": ".#./#.#",
	"_": "...../...../...../...../...../...../...../#####",
	"`": "#./.#",
	"{": "..#/.#./.#./#../.#./.#./..#",
	"|": "#/#/#/#/#/#/#",
	"}": "#../.#./.#./..#/.#./.#./#..",
	"~": "...../...../.##.#/#.##.",
}


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var font: FontFile = build_font()
	DirAccess.make_dir_recursive_absolute(FONT_PATH.get_base_dir())
	var error: Error = ResourceSaver.save(font, FONT_PATH)
	print("tools/art/make_font: %s (%s), %d glyphs" % [FONT_PATH, error_string(error), GLYPHS.size() + 1])
	var theme: Theme = Theme.new()
	theme.default_font = load(FONT_PATH)
	theme.default_font_size = SIZE
	theme.set_color(&"font_shadow_color", &"Label", SHADOW)
	theme.set_constant(&"shadow_offset_x", &"Label", 1)
	theme.set_constant(&"shadow_offset_y", &"Label", 1)
	theme.set_constant(&"line_spacing", &"Label", 0)
	error = ResourceSaver.save(theme, THEME_PATH)
	print("tools/art/make_font: %s (%s)" % [THEME_PATH, error_string(error)])
	ProjectSettings.set_setting("gui/theme/custom", THEME_PATH)
	error = ProjectSettings.save()
	print("tools/art/make_font: project.godot points at the theme (%s)" % error_string(error))
	if args.size() > 0:
		atlas().save_png(args[0])
	quit(0 if error == OK else 1)


## The rows of `glyph`, each as wide as its widest.
static func rows_of(glyph: String) -> PackedStringArray:
	var rows: PackedStringArray = glyph.split("/")
	var width: int = 0
	for row: String in rows:
		width = maxi(width, row.length())
	for i: int in rows.size():
		rows[i] = rows[i].rpad(width, ".")
	return rows


static func width_of(glyph: String) -> int:
	return rows_of(glyph)[0].length()


## Every glyph in white on clear, one to a cell, in GLYPHS order.
static func atlas() -> Image:
	@warning_ignore("integer_division")
	var down: int = (GLYPHS.size() + ACROSS - 1) / ACROSS
	var image: Image = Image.create(CELL.x * ACROSS, CELL.y * down, false, Image.FORMAT_RGBA8)
	var index: int = 0
	for key: String in GLYPHS:
		@warning_ignore("integer_division")
		var corner: Vector2i = Vector2i(index % ACROSS, index / ACROSS) * CELL
		var rows: PackedStringArray = rows_of(GLYPHS[key])
		for y: int in rows.size():
			for x: int in rows[y].length():
				if rows[y][x] == "#":
					image.set_pixel(corner.x + x, corner.y + y, Color.WHITE)
		index += 1
	return image


## The font: a bitmap FontFile of one size, scaled by whole numbers only.
static func build_font() -> FontFile:
	var font: FontFile = FontFile.new()
	font.font_name = "Hearth"
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	font.fixed_size = SIZE
	font.fixed_size_scale_mode = TextServer.FIXED_SIZE_SCALE_INTEGER_ONLY
	var size: Vector2i = Vector2i(SIZE, 0)
	font.set_cache_ascent(0, SIZE, float(BASE))
	font.set_cache_descent(0, SIZE, float(LINE_HEIGHT - BASE))
	font.set_texture_image(0, size, 0, atlas())
	var index: int = 0
	for key: String in GLYPHS:
		var code: int = key.unicode_at(0)
		@warning_ignore("integer_division")
		var corner: Vector2i = Vector2i(index % ACROSS, index / ACROSS) * CELL
		var width: int = width_of(GLYPHS[key])
		font.set_glyph_advance(0, SIZE, code, Vector2(width + 1, 0))
		font.set_glyph_offset(0, size, code, Vector2(0, -BASE + 1))
		font.set_glyph_size(0, size, code, Vector2(width, ROWS))
		font.set_glyph_uv_rect(0, size, code, Rect2(corner, Vector2(width, ROWS)))
		font.set_glyph_texture_idx(0, size, code, 0)
		index += 1
	var space: int = " ".unicode_at(0)
	font.set_glyph_advance(0, SIZE, space, Vector2(SPACE_ADVANCE, 0))
	font.set_glyph_size(0, size, space, Vector2.ZERO)
	font.set_glyph_uv_rect(0, size, space, Rect2())
	font.set_glyph_texture_idx(0, size, space, 0)
	return font
