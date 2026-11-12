extends SceneTree
## Paints the hero's sprite sheet from the ASCII pixel art below, then:
##   godot --headless --path . -s res://tools/art/make_player_sprite.gd [-- <preview.png>]
##   godot --headless --path . --import
## The optional preview is the sheet at 6x on a green background, for reviewing the art.
##
## An original young adventurer (GDD §12, redrawn in P1e): brown hair, his blue hood down behind
## his neck, a red scarf, a blue tunic with a gold-trimmed hem under a leather vest, wrist
## guards, a belt with a pouch, slate trousers and tall boots, his sword on his back and a small
## pack.
## Sheet: one row per facing (ROWS: down, up, side facing left; the game flips the side row for
## right) and one column per frame (COLUMNS; PlayerAnimator names the same columns, and a test
## checks they agree). Frames are 16x32 with the soles on the bottom row.
##
## He is drawn from parts, so every frame of a facing has the same head and the same clothes:
## a HEAD (rows 0-11), a BODY pose (rows 12-22) and a pair of LEGS (rows 23-31), put together
## by frame(). The sword's hilt is laid over the sheathed frames (HILTS).
## - idle, blink: standing; the eyes close for a moment now and then
## - walk_1 to walk_6: a step, the weight coming down, the legs passing, then the other side;
##   the arms swing against the legs
## - windup, slash, follow: a swing of the sword (the hilt is gone from his back: it is in his
##   hand)
## - hold: arms up, holding something overhead (the same front view in every row)
## - fallen: out of hearts (the same in every row)
## Made from those, so they never drift apart from them (derived()):
## - breathe: idle with the shoulders a pixel lower (breathing out; also a landing's crouch)
## - hurt: the blink frame sunk a pixel: flinching, eyes shut
## - run_1 to run_6: the walk cycle leaning into a sprint (side view: the body above the belt a
##   pixel forward; front and back: as walking)
## Edit the art here, never the PNG.

const OUT_PATH: String = "res://gameplay/player/player_sheet.png"
const W: int = 16
const H: int = 32
const ROWS: Array[String] = ["down", "up", "side"]
const COLUMNS: Array[String] = [
	"idle", "blink", "walk_1", "walk_2", "walk_3", "walk_4", "walk_5", "walk_6",
	"windup", "slash", "follow", "hold", "fallen",
	"breathe", "hurt", "run_1", "run_2", "run_3", "run_4", "run_5", "run_6",
]
## How many of COLUMNS are put together from the parts (drawn()); the rest are made from those
## (derived()).
const DRAWN: int = 13
## Where the parts meet: the head's rows, then the body's, then the legs'.
const HEAD_ROWS: int = 12
const BODY_ROWS: int = 11
const LEG_ROWS: int = 9
## The row a body gives up when it sinks a pixel: the top of the chest, under the scarf.
const SINK_ROW: int = 13
## The rows that lean when the hero runs: everything above the belt.
const LEAN_ROWS: int = 19

const PALETTE: Dictionary = {
	".": Color(0, 0, 0, 0),
	"o": Color(0.10, 0.08, 0.14),  # outline
	"D": Color(0.13, 0.22, 0.50),  # tunic and hood, shade
	"m": Color(0.22, 0.42, 0.84),  # tunic and hood
	"L": Color(0.50, 0.70, 1.00),  # tunic, highlight
	"t": Color(0.96, 0.78, 0.30),  # gold trim on the hem
	"y": Color(1.00, 0.88, 0.40),  # belt buckle
	"h": Color(0.45, 0.27, 0.13),  # hair
	"H": Color(0.30, 0.17, 0.08),  # hair, shade (and closed eyes)
	"n": Color(0.62, 0.40, 0.21),  # hair, where the light catches it
	"s": Color(0.97, 0.80, 0.64),  # skin
	"S": Color(0.83, 0.61, 0.47),  # skin, shade
	"e": Color(0.10, 0.10, 0.20),  # eyes
	"b": Color(0.42, 0.25, 0.12),  # belt
	"p": Color(0.64, 0.68, 0.78),  # trousers: hard-wearing pale slate
	"P": Color(0.47, 0.50, 0.62),  # trousers, shade
	"v": Color(0.60, 0.39, 0.20),  # leather vest and wrist guards
	"V": Color(0.42, 0.26, 0.13),  # leather, shade
	"q": Color(0.72, 0.54, 0.30),  # belt pouch
	"Q": Color(0.52, 0.37, 0.19),  # pouch, shade
	"G": Color(0.80, 0.84, 0.90),  # steel: the sword's pommel
	"g": Color(0.52, 0.57, 0.66),  # steel, shade: its grip
	"k": Color(0.55, 0.60, 0.36),  # travel pack, olive canvas
	"K": Color(0.38, 0.44, 0.26),  # pack, shade
	"B": Color(0.33, 0.20, 0.10),  # boots
	"c": Color(0.52, 0.33, 0.17),  # boots, highlight
	"r": Color(0.86, 0.20, 0.20),  # scarf
	"R": Color(0.60, 0.11, 0.14),  # scarf, shade
}

## Each facing's head: rows 0 to 11.
const HEADS: Dictionary = {
	"down": [
		"................",
		"................",
		".....oooooo.....",
		"....ohnnhhho....",
		"...ohhnnhhhho...",
		"...ohhhhhhhho...",
		"...ohhHhhhhHo...",
		"...oHhhssshho...",
		"...ohsessesho...",
		"..oshsessesHso..",
		"...oSssSsssSo...",
		"....oSssssSo....",
	],
	"up": [
		"................",
		"................",
		".....oooooo.....",
		"....ohnnhhho....",
		"...ohhnnhhhho...",
		"...ohhhhhhhho...",
		"...ohhhhhhhHo...",
		"...ohhhhhhhHo...",
		"...ohhhhhhhHo...",
		"..oshHhhhHhHso..",
		"...oHHhhHhHHo...",
		"....oHHHHHHo....",
	],
	"side": [
		"................",
		"................",
		"....oooooo......",
		"...ohnnhhho.....",
		"..ohhnnhhhho....",
		"..ohhhhhhhhho...",
		"..ohhhhhhhhHo...",
		"..oshhhhhhhHo...",
		"..osesshshhHo...",
		".ossesshhhHHo...",
		"..osssssshHo....",
		"...oSSSssHo.....",
	],
}
## The rows of each head that change when the eyes close: row -> its picture.
const BLINKS: Dictionary = {
	"down": {8: "...ohssssssho...", 9: "..oshsHssHsHso.."},
	"up": {},
	"side": {8: "..osssshshhHo...", 9: ".ossHsshhhHHo..."},
}
## The sword's hilt over his shoulder, laid over every frame in which it is sheathed: [row,
## column, colour]. From the side the scarf's tail and the hood are in the way.
const HILTS: Dictionary = {
	"down": [[10, 13, "G"], [10, 14, "o"], [11, 12, "g"], [11, 13, "o"]],
	"up": [[10, 2, "G"], [10, 1, "o"], [11, 3, "g"], [11, 2, "o"]],
	"side": [],
}

## Each facing's body poses: rows 12 to 22.
const BODIES: Dictionary = {
	"down": {
		"stand": [
			"..oDrrrrrrrrDo..",
			".oDmVRrmmvvVmDo.",
			".oDmVvRmmvvVmDo.",
			".oDmVvvmmvvVmDo.",
			".oDmVvvmmvvVmDo.",
			".oDDVvvmmvvVDDo.",
			".ovDVvvmmvvVDvo.",
			".osbbbbyybqqbso.",
			"..oDmmmmmmQQDo..",
			"..oDmmmmmmmmDo..",
			"..oDttttttttDo..",
		],
		"swing_a": [
			"..oDrrrrrrrrDo..",
			".oDmVRrmmvvVmDo.",
			".oDmVvRmmvvVmDo.",
			".oDmVvvmmvvVmDo.",
			".oDmVvvmmvvVDDo.",
			".oDDVvvmmvvVDvo.",
			".ovDVvvmmvvVDso.",
			".ovbbbbyybqqbo..",
			".osDmmmmmmQQDo..",
			"..oDmmmmmmmmDo..",
			"..oDttttttttDo..",
		],
		"swing_b": [
			"..oDrrrrrrrrDo..",
			".oDmVRrmmvvVmDo.",
			".oDmVvRmmvvVmDo.",
			".oDmVvvmmvvVmDo.",
			".oDDVvvmmvvVmDo.",
			".ovDVvvmmvvVDDo.",
			".osDVvvmmvvVDvo.",
			"..obbbbyybqqbvo.",
			"..oDmmmmmmQQDso.",
			"..oDmmmmmmmmDo..",
			"..oDttttttttDo..",
		],
		"windup": [
			"..oDrrrrrrrrDmmo",
			".oDmVRrmmvvVDDo.",
			".oDmVvRmmvvVDo..",
			".oDmVvvmmvvVDo..",
			".oDmVvvmmvvVDo..",
			".oDDVvvmmvvVDo..",
			".ovDVvvmmvvVDo..",
			".osbbbbyybqqbo..",
			"..oDmmmmmmQQDo..",
			"..oDmmmmmmmmDo..",
			"..oDttttttttDo..",
		],
		"slash": [
			"..oDrrrrrrrrDo..",
			".oDmVRrmmvvVmDo.",
			".oDmVvRmmvvVmDo.",
			".oDmVvvmmvvmDo..",
			".oDmVvvmmvmDVo..",
			".oDDVvvmmmDvVo..",
			".ovDVvvmVVvvVo..",
			".osbbbbssbqqbo..",
			"..oDmmmmmmQQDo..",
			"..oDmmmmmmmmDo..",
			"..oDttttttttDo..",
		],
		"follow": [
			"..oDrrrrrrrrDo..",
			".oDmVRrmmvvVmDo.",
			".oDmVvRmmvvVmDo.",
			".oDmVvvmmvvmDo..",
			".oDmVvvmmmDvVo..",
			".oDDVvmmDvvvVo..",
			".ovDVVVvvvvvVo..",
			".ossbbbyybqqbo..",
			"..oDmmmmmmQQDo..",
			"..oDmmmmmmmmDo..",
			"..oDttttttttDo..",
		],
	},
	"up": {
		"stand": [
			"..oDrDmmmmDrDo..",
			".oDmBDmmmmDVmDo.",
			".oDmVBDmmDvVmDo.",
			".oDmVvBDDvvVmDo.",
			".oDmkkvBvvvVmDo.",
			".oDDkKvvBvvVDDo.",
			".ovDKKvvvBvVDvo.",
			".osbbbbbbbbbbso.",
			"..oDmmmmmmBmDo..",
			"..oDmmmmmmmmDo..",
			"..oDttttttttDo..",
		],
		"swing_a": [
			"..oDrDmmmmDrDo..",
			".oDmBDmmmmDVmDo.",
			".oDmVBDmmDvVmDo.",
			".oDmVvBDDvvVmDo.",
			".oDmkkvBvvvVDDo.",
			".oDDkKvvBvvVDvo.",
			".ovDKKvvvBvVDso.",
			".ovbbbbbbbbbbo..",
			".osDmmmmmmBmDo..",
			"..oDmmmmmmmmDo..",
			"..oDttttttttDo..",
		],
		"swing_b": [
			"..oDrDmmmmDrDo..",
			".oDmBDmmmmDVmDo.",
			".oDmVBDmmDvVmDo.",
			".oDmVvBDDvvVmDo.",
			".oDDkkvBvvvVmDo.",
			".ovDkKvvBvvVDDo.",
			".osDKKvvvBvVDvo.",
			"..obbbbbbbbbbvo.",
			"..oDmmmmmmBmDso.",
			"..oDmmmmmmmmDo..",
			"..oDttttttttDo..",
		],
		"windup": [
			"ommDrDmmmmDrDo..",
			".oDDBDmmmmDVmDo.",
			"..oDVBDmmDvVmDo.",
			"..oDVvBDDvvVmDo.",
			"..oDkkvBvvvVmDo.",
			"..oDkKvvBvvVDDo.",
			"..oDKKvvvBvVDvo.",
			"..obbbbbbbbbbso.",
			"..oDmmmmmmBmDo..",
			"..oDmmmmmmmmDo..",
			"..oDttttttttDo..",
		],
		"slash": [
			"..oDrDmmmmDrDo..",
			".oDmBDmmmmDVmDo.",
			".oDDVBDmmDvVDDo.",
			"..oDVvBDDvvVDo..",
			"..oDkkvBvvvVDo..",
			"..oDkKvvBvvVDo..",
			"..oDKKvvvBvVDo..",
			"..obbbbbbbbbbo..",
			"..oDmmmmmmBmDo..",
			"..oDmmmmmmmmDo..",
			"..oDttttttttDo..",
		],
		"follow": [
			"..oDrDmmmmDrDo..",
			".oDmBDmmmmDVmDo.",
			".oDDVBDmmDvVmDo.",
			"..oDVvBDDvvVmDo.",
			"..oDkkvBvvvVmDo.",
			"..oDkKvvBvvVDmDo",
			"..oDKKvvvBvVoDvo",
			"..obbbbbbbbbboso",
			"..oDmmmmmmBmDo..",
			"..oDmmmmmmmmDo..",
			"..oDttttttttDo..",
		],
	},
	"side": {
		"stand": [
			"....orrrrrDDo...",
			"...omVvmmmvVDo..",
			"...omVvDmmvVro..",
			"...omVvDmmvVRo..",
			"...omVvDmmvVo...",
			"...omVvDmmvVko..",
			"...omVvVVVvVkKo.",
			"...obbbssqbbKo..",
			"....oDmmmQmDo...",
			"....oDmmmmmDo...",
			"....ottttttto...",
		],
		"swing_a": [
			"....orrrrrDDo...",
			"...omVvmmmvVDo..",
			"...omVDmmvvVro..",
			"...omDmmvvvVRo..",
			"...oDmmvvvvVo...",
			"..oVVmvvvvvVko..",
			"..ossVvvvvvVkKo.",
			"...obbbbbqbbKo..",
			"....oDmmmQmDo...",
			"....oDmmmmmDo...",
			"....ottttttto...",
		],
		"swing_b": [
			"....orrrrrDDo...",
			"...omVvmmmvVDo..",
			"...omVvvDmmVro..",
			"...omVvvvDmmRo..",
			"...omVvvvvDmmo..",
			"...omVvvvvvVVVo.",
			"...omVvvvvvVsso.",
			"...obbbbbqbbKo..",
			"....oDmmmQmDo...",
			"....oDmmmmmDo...",
			"....ottttttto...",
		],
		"windup": [
			"....orrrrrDDoso.",
			"...omVvvmmmmvvo.",
			"...omVvvvDDVo...",
			"...omVvvvvvVo...",
			"...omVvvvvvVo...",
			"...omVvvvvvVko..",
			"...omVvvvvvVkKo.",
			"...obbbbbqbbKo..",
			"....oDmmmQmDo...",
			"....oDmmmmmDo...",
			"....ottttttto...",
		],
		"slash": [
			"....orrrrrDDo...",
			"...omVvmmmvVDo..",
			".ooomVvmmmvVro..",
			".osvVmmmmmvVRo..",
			".oooDDDDDDvVo...",
			"...omVvvvvvVko..",
			"...omVvvvvvVkKo.",
			"...obbbbbqbbKo..",
			"....oDmmmQmDo...",
			"....oDmmmmmDo...",
			"....ottttttto...",
		],
		"follow": [
			"....orrrrrDDo...",
			"...omVvmmmvVDo..",
			"...omVDmmvvVro..",
			"...omDmmvvvVRo..",
			"..oDDmmvvvvVo...",
			".oVVDmvvvvvVko..",
			".ossmVvvvvvVkKo.",
			".ooobbbbbqbbKo..",
			"....oDmmmQmDo...",
			"....oDmmmmmDo...",
			"....ottttttto...",
		],
	},
}

## Legs seen from the front or the back (the same either way): rows 23 to 31. "step" has the
## left leg forward; the tool mirrors it for the other side.
const LEGS_FRONT: Dictionary = {
	"stand": [
		"...oPppooppPo...",
		"...oPppooppPo...",
		"...oPppooppPo...",
		"...occcooccco...",
		"...oBcBooBcBo...",
		"...oBcBooBcBo...",
		"...oBBBooBBBo...",
		"...oBBBooBBBo...",
		"...oooooooooo...",
	],
	"step": [
		"...oPppooppPo...",
		"...oPppooppPo...",
		"...oPppooPppo...",
		"...occcooBcBo...",
		"...oBcBooBBBo...",
		"...oBcBo.oooo...",
		"...oBBBo........",
		"...oBBBo........",
		"...ooooo........",
	],
	"low": [
		"...oPppooppPo...",
		"...oPppooppPo...",
		"...oPppooppPo...",
		"...occcooPppo...",
		"...oBcBooBcBo...",
		"...oBcBooBBBo...",
		"...oBBBo.oooo...",
		"...oBBBo........",
		"...ooooo........",
	],
	"pass": [
		"...oPppooppPo...",
		"...oPppooppPo...",
		"...oPppooppPo...",
		"...occcooccco...",
		"...oBcBooBcBo...",
		"...oBcBooBcBo...",
		"...oBBBooBBBo...",
		"...oBBBooooo....",
		"...ooooo........",
	],
	"apart": [
		"..oPppo..oppPo..",
		"..oPppo..oppPo..",
		"..oPppo..oppPo..",
		"..occco..occco..",
		"..oBcBo..oBcBo..",
		"..oBcBo..oBcBo..",
		"..oBBBo..oBBBo..",
		"..oBBBo..oBBBo..",
		"..ooooo..ooooo..",
	],
}
## Legs seen from the side. For the other half of the cycle the tool swaps the near leg's
## shade with the far one's.
const LEGS_SIDE: Dictionary = {
	"stand": [
		".....oPpppo.....",
		".....oPpppo.....",
		".....oPpppo.....",
		".....occcco.....",
		".....oBBcBo.....",
		".....oBBcBo.....",
		".....oBBBBo.....",
		"....oBBBBBo.....",
		"....ooooooo.....",
	],
	"step": [
		".....oPpppo.....",
		"....oppPPPPo....",
		"....oppooPPPo...",
		"...oppo..oPPo...",
		"...occo..occo...",
		"...oBco..oBBo...",
		"..oBBco..oBBBo..",
		"..oBBBo..oBBBo..",
		"..ooooo..ooooo..",
	],
	"low": [
		".....oPpppo.....",
		"....oppPPPPo....",
		"....oppooPPPo...",
		"...oppo..oPPo...",
		"...occo..occo...",
		"...oBco..oBBBo..",
		"..oBBco..ooooo..",
		"..oBBBo.........",
		"..ooooo.........",
	],
	"pass": [
		".....oPpppo.....",
		".....oPpppo.....",
		".....oPpppo.....",
		".....occcco.....",
		".....oBBcBBo....",
		".....oBBcoBo....",
		".....oBBBBoo....",
		"....oBBBBBo.....",
		"....ooooooo.....",
	],
}

## Holding something overhead: one whole frame, the same front view in every row.
const HOLD: Array[String] = [
	"................",
	".o............o.",
	"oso..oooooo..oso",
	"oso.ohnnhhho.oso",
	"ovoohhnnhhhhoovo",
	"omoohhhhhhhhoomo",
	"omoohhHhhhhHoomo",
	"omooHhhssshhoomo",
	"omoohsesseshoomo",
	"omoshsessesHsomo",
	"omooSssSsssSoomo",
	"omoooSssssSooomo",
	"ommDrrrrrrrrDmmo",
	"..oVvRrmmvvvVo..",
	"..oVvvRmmvvvVo..",
	"..oVvvvmmvvvVo..",
	"..oVvvvmmvvvVo..",
	"..oVvvvmmvvvVo..",
	"..oVvvvmmvvvVo..",
	"..obbbbyybqqbo..",
	"..oDmmmmmmQQDo..",
	"..oDmmmmmmmmDo..",
	"..oDttttttttDo..",
	"...oPppooppPo...",
	"...oPppooppPo...",
	"...oPppooppPo...",
	"...occcooccco...",
	"...oBcBooBcBo...",
	"...oBcBooBcBo...",
	"...oBBBooBBBo...",
	"...oBBBooBBBo...",
	"...oooooooooo...",
]
## Out of hearts, lying down: the last rows of a frame that is otherwise empty.
const FALLEN: Array[String] = [
	"..ooooo.........",
	".ohnnhhooooooo..",
	"ohhnhhhsoDmmtooo",
	"ohhhhhsHrmvvtpBo",
	"oHhhhhssrmvvtpBo",
	"oHhhhhsSoDbbtpBo",
	".oHHhhhooDmmtooo",
	"..ooooo.oooooo..",
]
## Pixels laid over one frame of one facing, where a pose reaches outside its part: [row,
## column, colours]. A wind-up's hand goes up beside the head, to the hilt.
const EXTRAS: Dictionary = {
	"windup": {
		"down": [[8, 13, "ooo"], [9, 14, "so"], [10, 13, "ovo"], [11, 13, "omo"]],
		"up": [[8, 0, "ooo"], [9, 0, "os"], [10, 0, "ovo"], [11, 0, "omo"]],
		"side": [[11, 12, "ooo"]],
	},
}
## What each drawn frame is put together from: [body pose, legs, whether the legs are the other
## side's (mirrored from the front and back, the near and far leg swapped from the side),
## whether the eyes are shut, whether the sword is on his back].
const RECIPES: Dictionary = {
	"idle": ["stand", "stand", false, false, true],
	"blink": ["stand", "stand", false, true, true],
	"walk_1": ["swing_a", "step", false, false, true],
	"walk_2": ["swing_a", "low", false, false, true],
	"walk_3": ["stand", "pass", false, false, true],
	"walk_4": ["swing_b", "step", true, false, true],
	"walk_5": ["swing_b", "low", true, false, true],
	"walk_6": ["stand", "pass", true, false, true],
	"windup": ["windup", "lunge", false, false, false],
	"slash": ["slash", "lunge", false, false, false],
	"follow": ["follow", "lunge", false, false, false],
}


func _initialize() -> void:
	var image: Image = Image.create(W * COLUMNS.size(), H * ROWS.size(), false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for row: int in ROWS.size():
		var frames: Array = drawn(ROWS[row])
		frames.append_array(derived(ROWS[row]))
		if frames.size() != COLUMNS.size():
			push_error("tools/art: row '%s' has %d frames, expected %d" % [ROWS[row], frames.size(), COLUMNS.size()])
			quit(1)
			return
		for column: int in frames.size():
			if not _paint(image, frames[column], Vector2i(column * W, row * H), "%s/%s" % [ROWS[row], COLUMNS[column]]):
				quit(1)
				return
	# Art pass 3: warm the colours and soften the outlines.
	PixelGrade.apply(image, PALETTE["o"])
	DirAccess.make_dir_recursive_absolute(OUT_PATH.get_base_dir())
	var error: Error = image.save_png(OUT_PATH)
	print("tools/art: wrote %s (%s)" % [OUT_PATH, error_string(error)])
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if error == OK and args.size() > 0:
		_save_preview(image, args[0])
	quit(0 if error == OK else 1)


## The frames of `facing` that are put together from the parts, in COLUMNS order.
static func drawn(facing: String) -> Array:
	var out: Array = []
	for column: int in DRAWN:
		out.append(frame(facing, COLUMNS[column]))
	return out


## One drawn frame of `facing`: its rows, top to bottom.
static func frame(facing: String, column: String) -> Array:
	if column == "hold":
		return Array(HOLD)
	if column == "fallen":
		var rows: Array = []
		for y: int in H - FALLEN.size():
			rows.append(".".repeat(W))
		rows.append_array(FALLEN)
		return rows
	var recipe: Array = RECIPES[column]
	var out: Array = (HEADS[facing] as Array).duplicate()
	if recipe[3]:
		for row: int in BLINKS[facing]:
			out[row] = BLINKS[facing][row]
	out.append_array(BODIES[facing][recipe[0]])
	out.append_array(legs(facing, recipe[1], recipe[2]))
	if recipe[4]:
		for mark: Array in HILTS[facing]:
			_lay(out, mark[0], mark[1], mark[2])
	for mark: Array in (EXTRAS.get(column, {}) as Dictionary).get(facing, []):
		_lay(out, mark[0], mark[1], mark[2])
	return out


## Writes `text` over `rows[row]` from `column` on.
static func _lay(rows: Array, row: int, column: int, text: String) -> void:
	var line: String = rows[row]
	rows[row] = line.substr(0, column) + text + line.substr(column + text.length())


## The legs of `facing` in `pose`; `other_side` gives the same step on the other foot. A
## "lunge" is feet apart from the front and back, a long step from the side.
static func legs(facing: String, pose: String, other_side: bool) -> Array:
	var side: bool = facing == "side"
	var name: String = pose
	if pose == "lunge":
		name = "step" if side else "apart"
	var rows: Array = ((LEGS_SIDE if side else LEGS_FRONT)[name] as Array).duplicate()
	if not other_side:
		return rows
	for i: int in rows.size():
		var line: String = rows[i]
		if side:
			# The near leg and the far one change places: swap their shades.
			line = line.replace("p", "#").replace("P", "p").replace("#", "P")
		else:
			line = line.reverse()
		rows[i] = line
	return rows


## The frames of `facing` that are made from its drawn ones, in COLUMNS order after DRAWN.
static func derived(facing: String) -> Array:
	var out: Array = [sink(frame(facing, "idle")), sink(frame(facing, "blink"))]
	for step: int in range(1, 7):
		var walk: Array = frame(facing, "walk_%d" % step)
		out.append(lean(walk) if facing == "side" else walk)
	return out


## `rows` with everything above SINK_ROW a pixel lower, and that row gone: the body settles.
static func sink(rows: Array) -> Array:
	var out: Array = [".".repeat(W)]
	for y: int in rows.size():
		if y != SINK_ROW:
			out.append(rows[y])
	return out


## `rows` (a side view, facing left) with everything above the belt a pixel forward. A row with
## paint in its first column stays where it is.
static func lean(rows: Array) -> Array:
	var out: Array = []
	for y: int in rows.size():
		var line: String = rows[y]
		out.append(line.substr(1) + "." if y < LEAN_ROWS and line[0] == "." else line)
	return out


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


func _save_preview(sheet: Image, path: String) -> void:
	var scale: int = 6
	var preview: Image = Image.create(sheet.get_width() * scale, sheet.get_height() * scale, false, Image.FORMAT_RGBA8)
	preview.fill(Color(0.42, 0.58, 0.36))
	var big: Image = sheet.duplicate()
	big.resize(sheet.get_width() * scale, sheet.get_height() * scale, Image.INTERPOLATE_NEAREST)
	preview.blend_rect(big, Rect2i(Vector2i.ZERO, big.get_size()), Vector2i.ZERO)
	print("tools/art: preview %s (%s)" % [path, error_string(preview.save_png(path))])
