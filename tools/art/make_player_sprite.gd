extends SceneTree
## Paints the player's sprite sheet from the ASCII pixel art below, then:
##   godot --headless --path . -s res://tools/art/make_player_sprite.gd [-- <preview.png>]
##   godot --headless --path . --import
## The optional preview is the sheet at 8x on a grey background, for reviewing the art.
##
## An original Zelda-style adventurer: green hooded salvager's coat, tan trousers, boots,
## and the glowing Network Key on the belt (GDD §5).
## Sheet: 3 columns (idle, step A, step B) x 3 rows (down, up, side facing left; the game
## flips the side row for right). Frames are 16x24 with the soles on the bottom row.
## Edit the art here, never the PNG.

const OUT_PATH: String = "res://gameplay/player/player_sheet.png"
const W: int = 16
const H: int = 24

const PALETTE: Dictionary = {
	".": Color(0, 0, 0, 0),
	"o": Color(0.10, 0.08, 0.12),  # outline
	"d": Color(0.20, 0.45, 0.13),  # coat, shade
	"g": Color(0.38, 0.70, 0.18),  # coat
	"l": Color(0.62, 0.86, 0.33),  # coat, highlight
	"h": Color(0.40, 0.24, 0.13),  # hair
	"s": Color(0.97, 0.80, 0.64),  # skin
	"S": Color(0.82, 0.60, 0.46),  # skin, shade
	"e": Color(0.12, 0.12, 0.20),  # eyes
	"b": Color(0.52, 0.32, 0.16),  # belt
	"B": Color(0.32, 0.19, 0.10),  # boots
	"p": Color(0.86, 0.80, 0.62),  # trousers
	"k": Color(0.40, 0.96, 0.86),  # Network Key glow
}

# Front and back views are symmetric: only the left half (8 px) is drawn, then mirrored.
const DOWN_UPPER_HALF: Array[String] = [
	"........",
	".....ooo",
	"....oddg",
	"...odggl",
	"...oggll",
	"..odghhh",
	"..oghhhh",
	"..oghsss",
	"..ogsess",
	"..odssss",
	"...odsss",
	"...oddSS",
	"..oddggg",
	".odglggg",
	".odggdgg",
	".osgdggg",
	".osdbbbk",
	"..odgggg",
	"..odgggd",
]

const UP_UPPER_HALF: Array[String] = [
	"........",
	".....ooo",
	"....oddg",
	"...odggg",
	"...ogggg",
	"..odgggg",
	"..oggggg",
	"..ogdggg",
	"..ogdggg",
	"..odgggg",
	"...odhhh",
	"...odddd",
	"..oddggg",
	".odggggg",
	".odggdgg",
	".osgdggg",
	".osdbbbb",
	"..odgggg",
	"..odgggd",
]

const LEGS_IDLE_HALF: Array[String] = [
	"...opppo",
	"...opppo",
	"...oBBbo",
	"...oBBBo",
	"...ooooo",
]

## Front/back step A (left foot down, right foot lifted). Step B is its mirror image.
const LEGS_STEP: Array[String] = [
	"...opppoopppo...",
	"...opppooBBbo...",
	"...oBBbooBBBo...",
	"...oBBBo.oooo...",
	"...ooooo........",
]

const SIDE_UPPER: Array[String] = [
	"................",
	"......ooooo.....",
	".....oddgggo....",
	"....odgglgggo...",
	"....oggllggggo..",
	"...ohhhhggggggo.",
	"...ohhhhhgggggdo",
	"..ossshhhggggdo.",
	"..osesshhgggdo..",
	".ossssshggggdo..",
	"..osssssgggdo...",
	"...oSSSSddo.....",
	"....oddggggdo...",
	"...odggggggdo...",
	"...ogggggdggo...",
	"...ogggggdggo...",
	"...obbbbbsbbo...",
	"....odggggdo....",
	"....odgggddo....",
]

const SIDE_LEGS_IDLE: Array[String] = [
	".....oppppo.....",
	".....oppppo.....",
	".....oBBBbo.....",
	"....oBBBBBo.....",
	"....ooooooo.....",
]

const SIDE_LEGS_A: Array[String] = [
	"....oppoopppo...",
	"...oppo..oppo...",
	"...oBbo..oBBo...",
	"..oBBBo..oBBBo..",
	"..ooooo..ooooo..",
]

const SIDE_LEGS_B: Array[String] = [
	".....oppppo.....",
	".....opppBo.....",
	"....oBBBoBo.....",
	"....oBBBBoo.....",
	"....ooooo.......",
]


func _initialize() -> void:
	var down: Array[String] = _mirror_halves(DOWN_UPPER_HALF)
	var up: Array[String] = _mirror_halves(UP_UPPER_HALF)
	var legs_idle: Array[String] = _mirror_halves(LEGS_IDLE_HALF)
	var legs_b: Array[String] = _flip_rows(LEGS_STEP)
	var sheet: Array = [
		[down + legs_idle, down + LEGS_STEP, down + legs_b],
		[up + legs_idle, up + LEGS_STEP, up + legs_b],
		[SIDE_UPPER + SIDE_LEGS_IDLE, SIDE_UPPER + SIDE_LEGS_A, SIDE_UPPER + SIDE_LEGS_B],
	]
	var image: Image = Image.create(W * 3, H * 3, false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for row: int in sheet.size():
		for column: int in (sheet[row] as Array).size():
			var frame: Array = sheet[row][column]
			if not _paint(image, frame, Vector2i(column * W, row * H), "row %d column %d" % [row, column]):
				quit(1)
				return
	DirAccess.make_dir_recursive_absolute(OUT_PATH.get_base_dir())
	var error: Error = image.save_png(OUT_PATH)
	print("tools/art: wrote %s (%s)" % [OUT_PATH, error_string(error)])
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if error == OK and args.size() > 0:
		_save_preview(image, args[0])
	quit(0 if error == OK else 1)


func _paint(image: Image, rows: Array, origin: Vector2i, label: String) -> bool:
	if rows.size() != H:
		push_error("tools/art: %s has %d rows, expected %d" % [label, rows.size(), H])
		return false
	for y: int in H:
		var line: String = rows[y]
		if line.length() != W:
			push_error("tools/art: %s row %d is %d px wide, expected %d: '%s'" % [label, y, line.length(), W, line])
			return false
		for x: int in W:
			var key: String = line[x]
			if not PALETTE.has(key):
				push_error("tools/art: %s row %d has unknown colour '%s'" % [label, y, key])
				return false
			image.set_pixel(origin.x + x, origin.y + y, PALETTE[key])
	return true


func _mirror_halves(halves: Array[String]) -> Array[String]:
	var out: Array[String] = []
	for half: String in halves:
		out.append(half + half.reverse())
	return out


func _flip_rows(rows: Array[String]) -> Array[String]:
	var out: Array[String] = []
	for line: String in rows:
		out.append(line.reverse())
	return out


func _save_preview(sheet: Image, path: String) -> void:
	var scale: int = 8
	var preview: Image = Image.create(sheet.get_width() * scale, sheet.get_height() * scale, false, Image.FORMAT_RGBA8)
	preview.fill(Color(0.45, 0.47, 0.5))
	var big: Image = sheet.duplicate()
	big.resize(sheet.get_width() * scale, sheet.get_height() * scale, Image.INTERPOLATE_NEAREST)
	preview.blend_rect(big, Rect2i(Vector2i.ZERO, big.get_size()), Vector2i.ZERO)
	print("tools/art: preview %s (%s)" % [path, error_string(preview.save_png(path))])
