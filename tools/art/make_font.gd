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
##
## It bakes a second face too, for headings (P1f): ui/font/hearth_heading.tres, twice the size
## (16), with thick stems, thin bars and small serifs. It has capitals, digits and a few marks;
## a small letter shows as its capital, so any heading can be set in it. The theme offers it as
## the "Heading" kind of label. Its glyphs are HEADING below, a list of rows each: rows 1-12
## are the capital height, rows 13-14 hold what hangs below the line.

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

## The heading face: where it is baked, the size labels ask for, its line height and where the
## baseline sits in it, and its atlas (cells of 14x16 px, 8 across).
const HEADING_PATH: String = "res://ui/font/hearth_heading.tres"
const HEADING_KIND: StringName = &"Heading"
const HEADING_SIZE: int = 16
const HEADING_LINE: int = 18
const HEADING_BASE: int = 13
const HEADING_ROWS: int = 14
const HEADING_CELL: Vector2i = Vector2i(14, 16)
const HEADING_ACROSS: int = 8
const HEADING_SPACE: int = 6
## Pairs of letters that stand too far apart as drawn (a slanted side against a slanted or
## overhanging one), and how many pixels closer the second sits.
const HEADING_KERNING: Dictionary = {
	"VA": 2, "AV": 2, "WA": 1, "AW": 1, "YA": 2, "AY": 2, "TA": 2, "AT": 2, "LT": 1, "LV": 1, "LY": 1,
	"PA": 1, "FA": 1, "TO": 1, "OT": 1,
}
## The gold every heading is set in, and the shadow under it.
const HEADING_COLOR: Color = Color(1.0, 0.84, 0.45)
const HEADING_SHADOW: Color = Color(0.16, 0.08, 0.06)

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


## The heading face's glyphs (see the top of the file).
const HEADING: Dictionary = {
	"A": [
		".....#.....",
		"....###....",
		"....###....",
		"...#.##....",
		"...#.###...",
		"..#...##...",
		"..#...###..",
		"..#######..",
		".#.....##..",
		".#.....###.",
		".#......##.",
		"###....####",
	],
	"B": [
		"#######..",
		".##...##.",
		".##....##",
		".##....##",
		".##...##.",
		".######..",
		".##...##.",
		".##....##",
		".##....##",
		".##....##",
		".##...##.",
		"#######..",
	],
	"C": [
		"..#####.#",
		".##....##",
		"##......#",
		"##......#",
		"##.......",
		"##.......",
		"##.......",
		"##.......",
		"##......#",
		"##......#",
		".##....#.",
		"..#####..",
	],
	"D": [
		"#######...",
		".##...##..",
		".##....##.",
		".##....##.",
		".##....##.",
		".##....##.",
		".##....##.",
		".##....##.",
		".##....##.",
		".##....##.",
		".##...##..",
		"#######...",
	],
	"E": [
		"#########",
		".##.....#",
		".##.....#",
		".##......",
		".##...#..",
		".######..",
		".##...#..",
		".##......",
		".##.....#",
		".##.....#",
		".##.....#",
		"#########",
	],
	"F": [
		"#########",
		".##.....#",
		".##.....#",
		".##......",
		".##...#..",
		".######..",
		".##...#..",
		".##......",
		".##......",
		".##......",
		".##......",
		"####.....",
	],
	"G": [
		"..#####.#.",
		".##....##.",
		"##......#.",
		"##......#.",
		"##........",
		"##........",
		"##...#####",
		"##.....##.",
		"##.....##.",
		"##.....##.",
		".##....##.",
		"..#####.#.",
	],
	"H": [
		"####..####",
		".##....##.",
		".##....##.",
		".##....##.",
		".##....##.",
		".########.",
		".##....##.",
		".##....##.",
		".##....##.",
		".##....##.",
		".##....##.",
		"####..####",
	],
	"I": [
		"####",
		".##.",
		".##.",
		".##.",
		".##.",
		".##.",
		".##.",
		".##.",
		".##.",
		".##.",
		".##.",
		"####",
	],
	"J": [
		"...####",
		"....##.",
		"....##.",
		"....##.",
		"....##.",
		"....##.",
		"....##.",
		"....##.",
		"....##.",
		"##..##.",
		"##..##.",
		".####..",
	],
	"K": [
		"####..####",
		".##....#..",
		".##...#...",
		".##..#....",
		".##.#.....",
		".####.....",
		".##.##....",
		".##..##...",
		".##..##...",
		".##...##..",
		".##...##..",
		"####..####",
	],
	"L": [
		"####.....",
		".##......",
		".##......",
		".##......",
		".##......",
		".##......",
		".##......",
		".##......",
		".##.....#",
		".##.....#",
		".##.....#",
		"#########",
	],
	"M": [
		"###......###",
		".###....###.",
		".###....###.",
		".##.#..#.##.",
		".##.#..#.##.",
		".##..##..##.",
		".##..##..##.",
		".##......##.",
		".##......##.",
		".##......##.",
		".##......##.",
		"####....####",
	],
	"N": [
		"###....####",
		".##.....#..",
		".###....#..",
		".###....#..",
		".####...#..",
		".##.##..#..",
		".##.##..#..",
		".##..##.#..",
		".##..##.#..",
		".##...###..",
		".##...###..",
		"####...##..",
	],
	"O": [
		"..######..",
		".##....##.",
		"##......##",
		"##......##",
		"##......##",
		"##......##",
		"##......##",
		"##......##",
		"##......##",
		"##......##",
		".##....##.",
		"..######..",
	],
	"P": [
		"#######..",
		".##...##.",
		".##....##",
		".##....##",
		".##....##",
		".##...##.",
		".######..",
		".##......",
		".##......",
		".##......",
		".##......",
		"####.....",
	],
	"Q": [
		"..######..",
		".##....##.",
		"##......##",
		"##......##",
		"##......##",
		"##......##",
		"##......##",
		"##......##",
		"##..##..##",
		"##...##.##",
		".##...###.",
		"..######..",
		".......##.",
		"........##",
	],
	"R": [
		"#######...",
		".##...##..",
		".##....##.",
		".##....##.",
		".##...##..",
		".######...",
		".##.##....",
		".##..##...",
		".##..##...",
		".##...##..",
		".##...##..",
		"####...###",
	],
	"S": [
		"..#####.#",
		".##....##",
		"##......#",
		"##.......",
		".###.....",
		"..#####..",
		".....###.",
		".......##",
		"#......##",
		"#......##",
		"##....##.",
		"#.#####..",
	],
	"T": [
		"##########",
		"#...##...#",
		"#...##...#",
		"....##....",
		"....##....",
		"....##....",
		"....##....",
		"....##....",
		"....##....",
		"....##....",
		"....##....",
		"..######..",
	],
	"U": [
		"####..####",
		".##....#..",
		".##....#..",
		".##....#..",
		".##....#..",
		".##....#..",
		".##....#..",
		".##....#..",
		".##....#..",
		".##....#..",
		"..##..##..",
		"...####...",
	],
	"V": [
		"####...####",
		".##.....#..",
		".##.....#..",
		"..##...#...",
		"..##...#...",
		"..##...#...",
		"...##.#....",
		"...##.#....",
		"...##.#....",
		"....###....",
		"....###....",
		".....#.....",
	],
	"W": [
		"####....####",
		".##......##.",
		".##......##.",
		".##......##.",
		".##......##.",
		".##..##..##.",
		".##..##..##.",
		".##.#..#.##.",
		".##.#..#.##.",
		".###....###.",
		".###....###.",
		".##......##.",
	],
	"X": [
		"####..####",
		".##....#..",
		"..##..#...",
		"..##..#...",
		"...###....",
		"....##....",
		"....##....",
		"...#.##...",
		"..#..##...",
		"..#...##..",
		".#....##..",
		"###..#####",
	],
	"Y": [
		"####..####",
		".##....#..",
		"..##..#...",
		"..##..#...",
		"...###....",
		"....##....",
		"....##....",
		"....##....",
		"....##....",
		"....##....",
		"....##....",
		"..######..",
	],
	"Z": [
		"#########",
		"#.....##.",
		"#....##..",
		".....##..",
		"....##...",
		"....##...",
		"...##....",
		"...##....",
		"..##.....",
		"..##....#",
		".##.....#",
		"#########",
	],
	"0": [
		"..####..",
		".##..##.",
		"##....##",
		"##....##",
		"##....##",
		"##....##",
		"##....##",
		"##....##",
		"##....##",
		"##....##",
		".##..##.",
		"..####..",
	],
	"1": [
		"..##..",
		".###..",
		"####..",
		"..##..",
		"..##..",
		"..##..",
		"..##..",
		"..##..",
		"..##..",
		"..##..",
		"..##..",
		"######",
	],
	"2": [
		".#####..",
		"##...##.",
		"#.....##",
		"......##",
		"......##",
		".....##.",
		"....##..",
		"...##...",
		"..##....",
		".##....#",
		"##.....#",
		"########",
	],
	"3": [
		".#####..",
		"##...##.",
		"#.....##",
		"......##",
		".....##.",
		"..####..",
		".....##.",
		"......##",
		"......##",
		"#.....##",
		"##...##.",
		".#####..",
	],
	"4": [
		".....###.",
		"....####.",
		"...#.##..",
		"..#..##..",
		".#...##..",
		"#....##..",
		"#########",
		".....##..",
		".....##..",
		".....##..",
		".....##..",
		"....####.",
	],
	"5": [
		"########",
		"##.....#",
		"##......",
		"##......",
		"######..",
		".....##.",
		"......##",
		"......##",
		"......##",
		"#.....##",
		"##...##.",
		".#####..",
	],
	"6": [
		"..#####.",
		".##...##",
		"##.....#",
		"##......",
		"##.###..",
		"###..##.",
		"##....##",
		"##....##",
		"##....##",
		"##....##",
		".##..##.",
		"..####..",
	],
	"7": [
		"########",
		"#.....##",
		"#.....##",
		".....##.",
		".....##.",
		"....##..",
		"....##..",
		"...##...",
		"...##...",
		"..##....",
		"..##....",
		"..##....",
	],
	"8": [
		"..####..",
		".##..##.",
		"##....##",
		"##....##",
		".##..##.",
		"..####..",
		".##..##.",
		"##....##",
		"##....##",
		"##....##",
		".##..##.",
		"..####..",
	],
	"9": [
		"..####..",
		".##..##.",
		"##....##",
		"##....##",
		"##....##",
		"##....##",
		".##..###",
		"..###.##",
		"......##",
		"#.....##",
		"##...##.",
		".#####..",
	],
	".": [
		"..",
		"..",
		"..",
		"..",
		"..",
		"..",
		"..",
		"..",
		"..",
		"..",
		"##",
		"##",
	],
	",": [
		"...",
		"...",
		"...",
		"...",
		"...",
		"...",
		"...",
		"...",
		"...",
		"...",
		".##",
		".##",
		".#.",
		"#..",
	],
	":": [
		"..",
		"..",
		"..",
		"..",
		"##",
		"##",
		"..",
		"..",
		"..",
		"..",
		"##",
		"##",
	],
	"'": [
		"##",
		"##",
		".#",
		"#.",
	],
	"-": [
		".....",
		".....",
		".....",
		".....",
		".....",
		".....",
		"#####",
		"#####",
	],
	"!": [
		"##",
		"##",
		"##",
		"##",
		"##",
		"##",
		"##",
		"##",
		"..",
		"..",
		"##",
		"##",
	],
	"?": [
		".#####..",
		"##...##.",
		"#.....##",
		"......##",
		".....##.",
		"....##..",
		"...##...",
		"...##...",
		"........",
		"........",
		"...##...",
		"...##...",
	],
}


func _initialize() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var font: FontFile = build_font()
	DirAccess.make_dir_recursive_absolute(FONT_PATH.get_base_dir())
	var error: Error = ResourceSaver.save(font, FONT_PATH)
	print("tools/art/make_font: %s (%s), %d glyphs" % [FONT_PATH, error_string(error), GLYPHS.size() + 1])
	error = ResourceSaver.save(build_heading(), HEADING_PATH)
	print("tools/art/make_font: %s (%s), %d glyphs" % [HEADING_PATH, error_string(error), HEADING.size() + 1])
	var theme: Theme = Theme.new()
	theme.default_font = load(FONT_PATH)
	theme.default_font_size = SIZE
	theme.set_color(&"font_shadow_color", &"Label", SHADOW)
	theme.set_constant(&"shadow_offset_x", &"Label", 1)
	theme.set_constant(&"shadow_offset_y", &"Label", 1)
	theme.set_constant(&"line_spacing", &"Label", 0)
	# Headings: a kind of label in the larger face, gold over a dark shadow.
	theme.set_type_variation(HEADING_KIND, &"Label")
	theme.set_font(&"font", HEADING_KIND, load(HEADING_PATH))
	theme.set_font_size(&"font_size", HEADING_KIND, HEADING_SIZE)
	theme.set_color(&"font_color", HEADING_KIND, HEADING_COLOR)
	theme.set_color(&"font_shadow_color", HEADING_KIND, HEADING_SHADOW)
	error = ResourceSaver.save(theme, THEME_PATH)
	print("tools/art/make_font: %s (%s)" % [THEME_PATH, error_string(error)])
	ProjectSettings.set_setting("gui/theme/custom", THEME_PATH)
	error = ProjectSettings.save()
	print("tools/art/make_font: project.godot points at the theme (%s)" % error_string(error))
	if args.size() > 0:
		atlas().save_png(args[0])
		heading_atlas().save_png(args[0].get_basename() + "_heading.png")
	quit(0 if error == OK else 1)


## The rows of the heading glyph `key`, each as wide as its widest.
static func heading_rows(key: String) -> PackedStringArray:
	var rows: PackedStringArray = PackedStringArray(HEADING[key])
	var width: int = 0
	for row: String in rows:
		width = maxi(width, row.length())
	for i: int in rows.size():
		rows[i] = rows[i].rpad(width, ".")
	return rows


## Every heading glyph in white on clear, one to a cell, in HEADING order.
static func heading_atlas() -> Image:
	@warning_ignore("integer_division")
	var down: int = (HEADING.size() + HEADING_ACROSS - 1) / HEADING_ACROSS
	var image: Image = Image.create(HEADING_CELL.x * HEADING_ACROSS, HEADING_CELL.y * down, false, Image.FORMAT_RGBA8)
	var index: int = 0
	for key: String in HEADING:
		@warning_ignore("integer_division")
		var corner: Vector2i = Vector2i(index % HEADING_ACROSS, index / HEADING_ACROSS) * HEADING_CELL
		var rows: PackedStringArray = heading_rows(key)
		for y: int in rows.size():
			for x: int in rows[y].length():
				if rows[y][x] == "#":
					image.set_pixel(corner.x + x, corner.y + y, Color.WHITE)
		index += 1
	return image


## The heading face: a bitmap FontFile of one size, scaled by whole numbers only. A small
## letter is given its capital's picture.
static func build_heading() -> FontFile:
	var font: FontFile = FontFile.new()
	font.font_name = "Hearth Heading"
	font.antialiasing = TextServer.FONT_ANTIALIASING_NONE
	font.fixed_size = HEADING_SIZE
	font.fixed_size_scale_mode = TextServer.FIXED_SIZE_SCALE_INTEGER_ONLY
	var size: Vector2i = Vector2i(HEADING_SIZE, 0)
	font.set_cache_ascent(0, HEADING_SIZE, float(HEADING_BASE))
	font.set_cache_descent(0, HEADING_SIZE, float(HEADING_LINE - HEADING_BASE))
	font.set_texture_image(0, size, 0, heading_atlas())
	var index: int = 0
	for key: String in HEADING:
		@warning_ignore("integer_division")
		var corner: Vector2i = Vector2i(index % HEADING_ACROSS, index / HEADING_ACROSS) * HEADING_CELL
		var width: int = heading_rows(key)[0].length()
		var codes: Array[int] = [key.unicode_at(0)]
		if key.to_lower() != key:
			codes.append(key.to_lower().unicode_at(0))
		for code: int in codes:
			font.set_glyph_advance(0, HEADING_SIZE, code, Vector2(width + 1, 0))
			font.set_glyph_offset(0, size, code, Vector2(0, -HEADING_BASE + 1))
			font.set_glyph_size(0, size, code, Vector2(width, HEADING_ROWS))
			font.set_glyph_uv_rect(0, size, code, Rect2(corner, Vector2(width, HEADING_ROWS)))
			font.set_glyph_texture_idx(0, size, code, 0)
		index += 1
	# Kerning, for capitals and for the small letters that show as them.
	for pair: String in HEADING_KERNING:
		for first: String in [pair[0], pair[0].to_lower()]:
			for second: String in [pair[1], pair[1].to_lower()]:
				font.set_kerning(0, HEADING_SIZE, Vector2i(first.unicode_at(0), second.unicode_at(0)), Vector2(-int(HEADING_KERNING[pair]), 0))
	var space: int = " ".unicode_at(0)
	font.set_glyph_advance(0, HEADING_SIZE, space, Vector2(HEADING_SPACE, 0))
	font.set_glyph_size(0, size, space, Vector2.ZERO)
	font.set_glyph_uv_rect(0, size, space, Rect2())
	font.set_glyph_texture_idx(0, size, space, 0)
	return font


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
