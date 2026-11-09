extends SceneTree
## Paints the player's sprite sheet from the ASCII pixel art below, then:
##   godot --headless --path . -s res://tools/art/make_player_sprite.gd [-- <preview.png>]
##   godot --headless --path . --import
## The optional preview is the sheet at 8x on a grey background, for reviewing the art.
##
## An original Zelda-style adventurer (GDD §10): a blue hood and tunic with a gold-trimmed hem,
## a brown belt with a gold buckle, cream trousers and brown boots. In side view an arm swings
## with the walk.
## Sheet: 3 columns (idle, step A, step B) x 3 rows (down, up, side facing left; the game
## flips the side row for right). Frames are 16x24 with the soles on the bottom row.
## Edit the art here, never the PNG.

const OUT_PATH: String = "res://gameplay/player/player_sheet.png"
const W: int = 16
const H: int = 24

const PALETTE: Dictionary = {
	".": Color(0, 0, 0, 0),
	"o": Color(0.10, 0.08, 0.14),  # outline
	"D": Color(0.13, 0.22, 0.50),  # tunic, shade
	"m": Color(0.22, 0.42, 0.84),  # tunic
	"L": Color(0.50, 0.70, 1.00),  # tunic, highlight
	"t": Color(0.96, 0.78, 0.30),  # gold trim on the hem
	"y": Color(1.00, 0.88, 0.40),  # belt buckle
	"h": Color(0.45, 0.27, 0.13),  # hair
	"H": Color(0.30, 0.17, 0.08),  # hair, shade
	"s": Color(0.97, 0.80, 0.64),  # skin
	"S": Color(0.83, 0.61, 0.47),  # skin, shade
	"e": Color(0.10, 0.10, 0.20),  # eyes
	"b": Color(0.42, 0.25, 0.12),  # belt
	"p": Color(0.92, 0.88, 0.76),  # trousers
	"P": Color(0.74, 0.70, 0.60),  # trousers, shade
	"B": Color(0.33, 0.20, 0.10),  # boots
	"c": Color(0.52, 0.33, 0.17),  # boots, highlight
}

# Front and back views are symmetric: only the left half (8 px) is drawn, then mirrored.
const DOWN_UPPER_HALF: Array[String] = [
	"........",
	".....ooo",
	"....oLmm",
	"...oLmmm",
	"...oLmmm",
	"..oLmmhh",
	"..oDmhhh",
	"..oDhsss",
	"..oDsess",
	"..oDsess",
	"..oDSsss",
	"...oDSSs",
	"..oDDmmm",
	".oDmmLmm",
	".oDmmmmm",
	".osDmmmm",
	".oSbbbby",
	"..oDmmmm",
	"..oDtttt",
]

const UP_UPPER_HALF: Array[String] = [
	"........",
	".....ooo",
	"....oLmm",
	"...oLmmm",
	"...oLmmm",
	"..oLmmmm",
	"..oDmmmm",
	"..oDmmmm",
	"..oDmmmD",
	"..oDDmmD",
	"...oDDDD",
	"...oHhhh",
	"..oDDmmm",
	".oDmmmmm",
	".oDmmmmm",
	".osDmmmm",
	".oSbbbbb",
	"..oDmmmm",
	"..oDtttt",
]

const LEGS_IDLE_HALF: Array[String] = [
	"...oPppo",
	"...oPppo",
	"...oBcBo",
	"...oBBBo",
	"...ooooo",
]

## Front/back step A (left foot down, right foot lifted). Step B is its mirror image.
const LEGS_STEP: Array[String] = [
	"...oPppooPppo...",
	"...oPppooBcBo...",
	"...oBcBooBBBo...",
	"...oBBBo.oooo...",
	"...ooooo........",
]

## Side view (facing left), head to chest. Each walk frame adds its arm, the hem and its legs.
const SIDE_HEAD: Array[String] = [
	"................",
	"......ooooo.....",
	".....oLLmmmo....",
	"....oLmmmmmmo...",
	"....oLmmmmmmmo..",
	"...ohhhhmmmmmmo.",
	"...ohhhhhmmmmmDo",
	"..osshhhhmmmmDo.",
	"..oseshhhmmmDo..",
	".osssshhhmmmDo..",
	"..osssssmmmDo...",
	"...oSSSSDDo.....",
	"....oDmmmmDo....",
	"...oDmmLmmmDo...",
]

const SIDE_ARMS_IDLE: Array[String] = [
	"...oDmDmmmmDo...",
	"...oDmDmmmmDo...",
	"...obsbbbbbbo...",
]

const SIDE_ARMS_FORWARD: Array[String] = [
	"..oDDmmmmmmDo...",
	"..osDmmmmmmDo...",
	"...obbbbbbbbo...",
]

const SIDE_ARMS_BACK: Array[String] = [
	"...oDmmmmmDDo...",
	"...oDmmmmmmDso..",
	"...obbbbbbbbo...",
]

const SIDE_HEM: Array[String] = [
	"....oDmmmmDo....",
	"....otttttto....",
]

const SIDE_LEGS_IDLE: Array[String] = [
	".....oPpppo.....",
	".....oPpppo.....",
	".....oBBcBo.....",
	"....oBBBBBo.....",
	"....ooooooo.....",
]

const SIDE_LEGS_A: Array[String] = [
	"....oPpooPppo...",
	"...oPpo..oPpo...",
	"...oBco..oBco...",
	"..oBBBo..oBBBo..",
	"..ooooo..ooooo..",
]

const SIDE_LEGS_B: Array[String] = [
	".....oPpppo.....",
	".....oPppBo.....",
	"....oBcBoBo.....",
	"....oBBBBoo.....",
	"....ooooo.......",
]


func _initialize() -> void:
	var down: Array[String] = _mirror_halves(DOWN_UPPER_HALF)
	var up: Array[String] = _mirror_halves(UP_UPPER_HALF)
	var legs_idle: Array[String] = _mirror_halves(LEGS_IDLE_HALF)
	var legs_b: Array[String] = _flip_rows(LEGS_STEP)
	var side_idle: Array[String] = SIDE_HEAD + SIDE_ARMS_IDLE + SIDE_HEM + SIDE_LEGS_IDLE
	var side_a: Array[String] = SIDE_HEAD + SIDE_ARMS_FORWARD + SIDE_HEM + SIDE_LEGS_A
	var side_b: Array[String] = SIDE_HEAD + SIDE_ARMS_BACK + SIDE_HEM + SIDE_LEGS_B
	var sheet: Array = [
		[down + legs_idle, down + LEGS_STEP, down + legs_b],
		[up + legs_idle, up + LEGS_STEP, up + legs_b],
		[side_idle, side_a, side_b],
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
