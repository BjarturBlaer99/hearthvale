extends SceneTree
## Paints the hero's sprite sheet from the ASCII pixel art below, then:
##   godot --headless --path . -s res://tools/art/make_player_sprite.gd [-- <preview.png>]
##   godot --headless --path . --import
## The optional preview is the sheet at 6x on a green background, for reviewing the art.
##
## An original young adventurer (GDD §12): a blue hood and tunic with a gold-trimmed hem,
## a red scarf, a leather vest, a brown belt with a gold buckle, slate trousers and tall boots.
## Sheet: one row per facing (ROWS: down, up, side facing left; the game flips the side row for
## right) and one column per frame (COLUMNS; PlayerAnimator names the same columns, and a test
## checks they agree). Frames are 16x24 with the soles on the bottom row.
## - idle, blink: standing; the eyes close for a moment now and then
## - walk_a, pass_a, walk_b, pass_b: the walk cycle (hands swing, the scarf's tail flutters)
## - attack: lunging behind the sword's swing
## - hold: arms up, holding something overhead (the same front view in every row)
## - fallen: out of hearts (the same in every row)
## Made from those, so they never drift apart from them (derived()):
## - breathe: idle with the shoulders a pixel lower (breathing out; also a landing's crouch and
##   the end of a swing)
## - windup: the attack frame sunk a pixel: gathering before the lunge
## - hurt: the blink frame sunk a pixel: flinching, eyes shut
## - run_a, run_pass_a, run_b, run_pass_b: the walk cycle leaning into a sprint (side view: the
##   body above the belt a pixel forward; front and back: as walking)
## The outfit (hero pass, 2026-11-11): a leather vest over the tunic, wrist guards, a belt pouch,
## tall cuffed boots, the sword's hilt over his shoulder with its sheath across his back, and a
## small pack. The hilt is gone from the attack frames: the sword is in his hand.
## Edit the art here, never the PNG.

const OUT_PATH: String = "res://gameplay/player/player_sheet.png"
const W: int = 16
const H: int = 24
const ROWS: Array[String] = ["down", "up", "side"]
const COLUMNS: Array[String] = [
	"idle", "blink", "walk_a", "pass_a", "walk_b", "pass_b", "attack", "hold", "fallen",
	"breathe", "windup", "hurt", "run_a", "run_pass_a", "run_b", "run_pass_b",
]
## How many of COLUMNS are drawn by hand in FRAMES; the rest are made from those (derived()).
const DRAWN: int = 9
## The row a body gives up when it sinks a pixel: the top of the chest, under the scarf.
const SINK_ROW: int = 13
## The rows that lean when the hero runs: everything above the belt.
const LEAN_ROWS: int = 16

const PALETTE: Dictionary = {
	".": Color(0, 0, 0, 0),
	"o": Color(0.10, 0.08, 0.14),  # outline
	"D": Color(0.13, 0.22, 0.50),  # tunic, shade
	"m": Color(0.22, 0.42, 0.84),  # tunic
	"L": Color(0.50, 0.70, 1.00),  # tunic, highlight
	"t": Color(0.96, 0.78, 0.30),  # gold trim on the hem
	"y": Color(1.00, 0.88, 0.40),  # belt buckle
	"h": Color(0.45, 0.27, 0.13),  # hair
	"H": Color(0.30, 0.17, 0.08),  # hair, shade (and closed eyes)
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

## FRAMES[row] is that facing's frames, in COLUMNS order.
const FRAMES: Dictionary = {
	"down": [
		# idle
		[
			"................",
			".....oooooo.....",
			"....oLmmmmLo....",
			"...oLmmmmmmLo...",
			"...oLmmmmmmLo...",
			"..oLmmhhhhmmLo..",
			"..oDmhhhhhhmDo..",
			"..oDhhhsssshDo..",
			"..oDsessssesDo..",
			"..oDsessssesDoo.",
			"..oDSsssSssSDoGo",
			"...oDSSssSSDogo.",
			"..oDrrrrrrrrDo..",
			".oDmVRrmmvvVmDo.",
			".oDmVvRmmvvVmDo.",
			".ovDVvvmmvvVDvo.",
			".osbbbbyybqqbso.",
			"..oDmmmmmmQQDo..",
			"..oDttttttttDo..",
			"...oPppooppPo...",
			"...occcooccco...",
			"...oBcBooBcBo...",
			"...oBBBooBBBo...",
			"...oooooooooo...",
		],
		# blink
		[
			"................",
			".....oooooo.....",
			"....oLmmmmLo....",
			"...oLmmmmmmLo...",
			"...oLmmmmmmLo...",
			"..oLmmhhhhmmLo..",
			"..oDmhhhhhhmDo..",
			"..oDhhhsssshDo..",
			"..oDssssssssDo..",
			"..oDsHssssHsDoo.",
			"..oDSsssSssSDoGo",
			"...oDSSssSSDogo.",
			"..oDrrrrrrrrDo..",
			".oDmVRrmmvvVmDo.",
			".oDmVvRmmvvVmDo.",
			".ovDVvvmmvvVDvo.",
			".osbbbbyybqqbso.",
			"..oDmmmmmmQQDo..",
			"..oDttttttttDo..",
			"...oPppooppPo...",
			"...occcooccco...",
			"...oBcBooBcBo...",
			"...oBBBooBBBo...",
			"...oooooooooo...",
		],
		# walk_a
		[
			"................",
			".....oooooo.....",
			"....oLmmmmLo....",
			"...oLmmmmmmLo...",
			"...oLmmmmmmLo...",
			"..oLmmhhhhmmLo..",
			"..oDmhhhhhhmDo..",
			"..oDhhhsssshDo..",
			"..oDsessssesDo..",
			"..oDsessssesDoo.",
			"..oDSsssSssSDoGo",
			"...oDSSssSSDogo.",
			"..oDrrrrrrrrDo..",
			".oDmVRrmmvvVmDo.",
			".oDmVvRmmvvVmDo.",
			".ovDVvvmmvvVDso.",
			".ovbbbbyybqqbo..",
			".osDmmmmmmQQDo..",
			"..oDttttttttDo..",
			"...oPppooPppo...",
			"...occcooBcBo...",
			"...oBcBooBBBo...",
			"...oBBBo.oooo...",
			"...ooooo........",
		],
		# pass_a
		[
			"................",
			".....oooooo.....",
			"....oLmmmmLo....",
			"...oLmmmmmmLo...",
			"...oLmmmmmmLo...",
			"..oLmmhhhhmmLo..",
			"..oDmhhhhhhmDo..",
			"..oDhhhsssshDo..",
			"..oDsessssesDo..",
			"..oDsessssesDoo.",
			"..oDSsssSssSDoGo",
			"...oDSSssSSDogo.",
			"..oDrrrrrrrrDo..",
			".oDmVRrmmvvVmDo.",
			".oDmVvRmmvvVmDo.",
			".ovDVvvmmvvVDvo.",
			".osbbbbyybqqbso.",
			"..oDmmmmmmQQDo..",
			"..oDttttttttDo..",
			"...oPppooppPo...",
			"...occcooccco...",
			"...oBcBooBcBo...",
			"...oBBBooBBBo...",
			"...oooooooooo...",
		],
		# walk_b
		[
			"................",
			".....oooooo.....",
			"....oLmmmmLo....",
			"...oLmmmmmmLo...",
			"...oLmmmmmmLo...",
			"..oLmmhhhhmmLo..",
			"..oDmhhhhhhmDo..",
			"..oDhhhsssshDo..",
			"..oDsessssesDo..",
			"..oDsessssesDoo.",
			"..oDSsssSssSDoGo",
			"...oDSSssSSDogo.",
			"..oDrrrrrrrrDo..",
			".oDmVRrmmvvVmDo.",
			".oDmVvRmmvvVmDo.",
			".osDVvvmmvvVDvo.",
			"..obbbbyybqqbvo.",
			"..oDmmmmmmQQDso.",
			"..oDttttttttDo..",
			"...oppPooppPo...",
			"...oBcBooccco...",
			"...oBBBooBcBo...",
			"...oooo.oBBBo...",
			"........ooooo...",
		],
		# pass_b
		[
			"................",
			".....oooooo.....",
			"....oLmmmmLo....",
			"...oLmmmmmmLo...",
			"...oLmmmmmmLo...",
			"..oLmmhhhhmmLo..",
			"..oDmhhhhhhmDo..",
			"..oDhhhsssshDo..",
			"..oDsessssesDo..",
			"..oDsessssesDoo.",
			"..oDSsssSssSDoGo",
			"...oDSSssSSDogo.",
			"..oDrrrrrrrrDo..",
			".oDmVRrmmvvVmDo.",
			".oDmVvRmmvvVmDo.",
			".ovDVvvmmvvVDvo.",
			".osbbbbyybqqbso.",
			"..oDmmmmmmQQDo..",
			"..oDttttttttDo..",
			"...oPppooppPo...",
			"...occcooccco...",
			"...oBcBooBcBo...",
			"...oBBBooBBBo...",
			"...oooooooooo...",
		],
		# attack
		[
			"................",
			".....oooooo.....",
			"....oLmmmmLo....",
			"...oLmmmmmmLo...",
			"...oLmmmmmmLo...",
			"..oLmmhhhhmmLo..",
			"..oDmhhhhhhmDo..",
			"..oDhhhsssshDo..",
			"..oDsessssesDo..",
			"..oDsessssesDo..",
			"..oDSsssSssSDo..",
			"...oDSSssSSDo...",
			"..oDrrrrrrrrDo..",
			".oDmVRrmmvvVmDo.",
			".oDmVvRmmvvVmDo.",
			".ovDVvvmmvvVDvo.",
			"..oDbbbyybqbDo..",
			"..oDmmDssDmmDo..",
			"..oDttttttttDo..",
			"..oPppo..oppPo..",
			"..occco..occco..",
			"..oBcBo..oBcBo..",
			"..oBBBo..oBBBo..",
			"..ooooo..ooooo..",
		],
		# hold
		[
			"................",
			".o...oooooo...o.",
			"oso.oLmmmmLo.oso",
			"osooLmmmmmmLooso",
			"ovooLmmmmmmLoovo",
			"omoLmmhhhhmmLomo",
			"omoDmhhhhhhmDomo",
			"omoDhhhsssshDomo",
			"omoDsessssesDomo",
			"omoDsessssesDomo",
			"omoDSsssSssSDomo",
			"omooDSSssSSDoomo",
			"ommDrrrrrrrrDmmo",
			"..oVvRrmmvvvVo..",
			"..oVvvRmmvvvVo..",
			"..oVvvvmmvvvVo..",
			"..obbbbyybqqbo..",
			"..oDmmmmmmQQDo..",
			"..oDttttttttDo..",
			"...oPppooppPo...",
			"...occcooccco...",
			"...oBcBooBcBo...",
			"...oBBBooBBBo...",
			"...oooooooooo...",
		],
		# fallen
		[
			"................",
			"................",
			"................",
			"................",
			"................",
			"................",
			"................",
			"................",
			"................",
			"................",
			"................",
			"................",
			"................",
			"................",
			"................",
			"................",
			"................",
			"...oooo.........",
			"..oLmmmoooooo...",
			".oLmhhsoDmmmtooo",
			".oDmhHsrmmmmtpBo",
			".oDmmhsrDmmmtpBo",
			"..oDDmmoDbbmtooo",
			"...oooo.ooooo...",
		],
	],
	"up": [
		# idle
		[
			"................",
			".....oooooo.....",
			"....oLmmmmLo....",
			"...oLmmmmmmLo...",
			"...oLmmmmmmLo...",
			"..oLmmmmmmmmLo..",
			"..oDmmmmmmmmDo..",
			"..oDmmmmmmmmDo..",
			"..oDmmmDDmmmDo..",
			".ooDDmmDDmmDDo..",
			"oGooDDDDDDDDo...",
			".ogoHhhhhhhHo...",
			"..oDrrrrrrrrDo..",
			".oDmVBvRrvvVmDo.",
			".oDmVBvrrkkKmDo.",
			".ovDVvBRrkKKDvo.",
			".osbbbbbbbbbbso.",
			"..oDmmmBmmmmDo..",
			"..oDttttttttDo..",
			"...oPppooppPo...",
			"...occcooccco...",
			"...oBcBooBcBo...",
			"...oBBBooBBBo...",
			"...oooooooooo...",
		],
		# blink
		[
			"................",
			".....oooooo.....",
			"....oLmmmmLo....",
			"...oLmmmmmmLo...",
			"...oLmmmmmmLo...",
			"..oLmmmmmmmmLo..",
			"..oDmmmmmmmmDo..",
			"..oDmmmmmmmmDo..",
			"..oDmmmDDmmmDo..",
			".ooDDmmDDmmDDo..",
			"oGooDDDDDDDDo...",
			".ogoHhhhhhhHo...",
			"..oDrrrrrrrrDo..",
			".oDmVBvRrvvVmDo.",
			".oDmVBvrrkkKmDo.",
			".ovDVvBRrkKKDvo.",
			".osbbbbbbbbbbso.",
			"..oDmmmBmmmmDo..",
			"..oDttttttttDo..",
			"...oPppooppPo...",
			"...occcooccco...",
			"...oBcBooBcBo...",
			"...oBBBooBBBo...",
			"...oooooooooo...",
		],
		# walk_a
		[
			"................",
			".....oooooo.....",
			"....oLmmmmLo....",
			"...oLmmmmmmLo...",
			"...oLmmmmmmLo...",
			"..oLmmmmmmmmLo..",
			"..oDmmmmmmmmDo..",
			"..oDmmmmmmmmDo..",
			"..oDmmmDDmmmDo..",
			".ooDDmmDDmmDDo..",
			"oGooDDDDDDDDo...",
			".ogoHhhhhhhHo...",
			"..oDrrrrrrrrDo..",
			".oDmVBvRrvvVmDo.",
			".oDmVBrrvkkKmDo.",
			".ovDVrRvvkKKDso.",
			".oDbbbbbbbbbbo..",
			".osDmmmBmmmmDo..",
			"..oDttttttttDo..",
			"...oPppooPppo...",
			"...occcooBcBo...",
			"...oBcBooBBBo...",
			"...oBBBo.oooo...",
			"...ooooo........",
		],
		# pass_a
		[
			"................",
			".....oooooo.....",
			"....oLmmmmLo....",
			"...oLmmmmmmLo...",
			"...oLmmmmmmLo...",
			"..oLmmmmmmmmLo..",
			"..oDmmmmmmmmDo..",
			"..oDmmmmmmmmDo..",
			"..oDmmmDDmmmDo..",
			".ooDDmmDDmmDDo..",
			"oGooDDDDDDDDo...",
			".ogoHhhhhhhHo...",
			"..oDrrrrrrrrDo..",
			".oDmVBvRrvvVmDo.",
			".oDmVBvrrkkKmDo.",
			".ovDVvBRrkKKDvo.",
			".osbbbbbbbbbbso.",
			"..oDmmmBmmmmDo..",
			"..oDttttttttDo..",
			"...oPppooppPo...",
			"...occcooccco...",
			"...oBcBooBcBo...",
			"...oBBBooBBBo...",
			"...oooooooooo...",
		],
		# walk_b
		[
			"................",
			".....oooooo.....",
			"....oLmmmmLo....",
			"...oLmmmmmmLo...",
			"...oLmmmmmmLo...",
			"..oLmmmmmmmmLo..",
			"..oDmmmmmmmmDo..",
			"..oDmmmmmmmmDo..",
			"..oDmmmDDmmmDo..",
			".ooDDmmDDmmDDo..",
			"oGooDDDDDDDDo...",
			".ogoHhhhhhhHo...",
			"..oDrrrrrrrrDo..",
			".oDmVBvRrvvVmDo.",
			".oDmVBvvrrkKmDo.",
			".osDVvBvvRrKDvo.",
			"..obbbbbbbbbbDo.",
			"..oDmmmBmmmmDso.",
			"..oDttttttttDo..",
			"...oppPooppPo...",
			"...oBcBooccco...",
			"...oBBBooBcBo...",
			"...oooo.oBBBo...",
			"........ooooo...",
		],
		# pass_b
		[
			"................",
			".....oooooo.....",
			"....oLmmmmLo....",
			"...oLmmmmmmLo...",
			"...oLmmmmmmLo...",
			"..oLmmmmmmmmLo..",
			"..oDmmmmmmmmDo..",
			"..oDmmmmmmmmDo..",
			"..oDmmmDDmmmDo..",
			".ooDDmmDDmmDDo..",
			"oGooDDDDDDDDo...",
			".ogoHhhhhhhHo...",
			"..oDrrrrrrrrDo..",
			".oDmVBvRrvvVmDo.",
			".oDmVBvrrkkKmDo.",
			".ovDVvBRrkKKDvo.",
			".osbbbbbbbbbbso.",
			"..oDmmmBmmmmDo..",
			"..oDttttttttDo..",
			"...oPppooppPo...",
			"...occcooccco...",
			"...oBcBooBcBo...",
			"...oBBBooBBBo...",
			"...oooooooooo...",
		],
		# attack
		[
			"................",
			".....oooooo.....",
			"....oLmmmmLo....",
			"...oLmmmmmmLo...",
			"...oLmmmmmmLo...",
			"..oLmmmmmmmmLo..",
			"..oDmmmmmmmmDo..",
			"..oDmmmmmmmmDo..",
			"..oDmmmDDmmmDo..",
			"..oDDmmDDmmDDo..",
			"...oDDDDDDDDo...",
			"...oHhhhhhhHo...",
			".ooDrrrrrrrrDoo.",
			".osmVBvRrvvVmso.",
			".oDmVBvrrkkKmDo.",
			".ovDVvBRrkKKDvo.",
			"..oDbbbbbbbbDo..",
			"..oDmmmBmmmmDo..",
			"..oDttttttttDo..",
			"..oPppo..oppPo..",
			"..occco..occco..",
			"..oBcBo..oBcBo..",
			"..oBBBo..oBBBo..",
			"..ooooo..ooooo..",
		],
		# hold
		[
			"................",
			".o...oooooo...o.",
			"oso.oLmmmmLo.oso",
			"osooLmmmmmmLooso",
			"ovooLmmmmmmLoovo",
			"omoLmmhhhhmmLomo",
			"omoDmhhhhhhmDomo",
			"omoDhhhsssshDomo",
			"omoDsessssesDomo",
			"omoDsessssesDomo",
			"omoDSsssSssSDomo",
			"omooDSSssSSDoomo",
			"ommDrrrrrrrrDmmo",
			"..oVvRrmmvvvVo..",
			"..oVvvRmmvvvVo..",
			"..oVvvvmmvvvVo..",
			"..obbbbyybqqbo..",
			"..oDmmmmmmQQDo..",
			"..oDttttttttDo..",
			"...oPppooppPo...",
			"...occcooccco...",
			"...oBcBooBcBo...",
			"...oBBBooBBBo...",
			"...oooooooooo...",
		],
		# fallen
		[
			"................",
			"................",
			"................",
			"................",
			"................",
			"................",
			"................",
			"................",
			"................",
			"................",
			"................",
			"................",
			"................",
			"................",
			"................",
			"................",
			"................",
			"...oooo.........",
			"..oLmmmoooooo...",
			".oLmhhsoDmmmtooo",
			".oDmhHsrmmmmtpBo",
			".oDmmhsrDmmmtpBo",
			"..oDDmmoDbbmtooo",
			"...oooo.ooooo...",
		],
	],
	"side": [
		# idle
		[
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
			"....orrrrrRR....",
			"...oDmmLvvvVr...",
			"...oDmDmvvvVR...",
			"...oDvVmvvvVko..",
			"...obsbbqqbbKo..",
			"....oDmmQQDoo...",
			"....otttttto....",
			".....oPpppo.....",
			".....occcco.....",
			".....oBBcBo.....",
			"....oBBBBBo.....",
			"....ooooooo.....",
		],
		# blink
		[
			"................",
			"......ooooo.....",
			".....oLLmmmo....",
			"....oLmmmmmmo...",
			"....oLmmmmmmmo..",
			"...ohhhhmmmmmmo.",
			"...ohhhhhmmmmmDo",
			"..osshhhhmmmmDo.",
			"..osHshhhmmmDo..",
			".osssshhhmmmDo..",
			"..osssssmmmDo...",
			"...oSSSSDDo.....",
			"....orrrrrRR....",
			"...oDmmLvvvVr...",
			"...oDmDmvvvVR...",
			"...oDvVmvvvVko..",
			"...obsbbqqbbKo..",
			"....oDmmQQDoo...",
			"....otttttto....",
			".....oPpppo.....",
			".....occcco.....",
			".....oBBcBo.....",
			"....oBBBBBo.....",
			"....ooooooo.....",
		],
		# walk_a
		[
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
			"..osssssmmmDo.R.",
			"...oSSSSDDo.rr..",
			"....orrrrrRR....",
			"...oDmmLvvvVo...",
			"..oDDmmmvvvVo...",
			"..osDmmmvvvVko..",
			"...obbbbqqbbKo..",
			"....oDmmQQDoo...",
			"....otttttto....",
			"....oppooPPPo...",
			"...occo..occo...",
			"...oBco..oBBo...",
			"..oBBBo..oBBBo..",
			"..ooooo..ooooo..",
		],
		# pass_a
		[
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
			"....orrrrrRRrr..",
			"...oDmmLvvvVo.R.",
			"...oDmDmvvvVo...",
			"...oDvVmvvvVko..",
			"...obsbbqqbbKo..",
			"....oDmmQQDoo...",
			"....otttttto....",
			".....oPpppo.....",
			".....occcBo.....",
			"....oBcBoBo.....",
			"....oBBBBoo.....",
			"....ooooo.......",
		],
		# walk_b
		[
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
			"....orrrrrRR....",
			"...oDmmLvvvVrr..",
			"...oDmmvvvDDoR..",
			"...oDmmmvvvVso..",
			"...obbbbqqbbKo..",
			"....oDmmQQDoo...",
			"....otttttto....",
			"....oPPoopppo...",
			"...occo..occo...",
			"...oBBo..oBco...",
			"..oBBBo..oBBBo..",
			"..ooooo..ooooo..",
		],
		# pass_b
		[
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
			"....orrrrrRRrr..",
			"...oDmmLvvvVo.R.",
			"...oDmDmvvvVo...",
			"...oDvVmvvvVko..",
			"...obsbbqqbbKo..",
			"....oDmmQQDoo...",
			"....otttttto....",
			".....opppPo.....",
			".....occcBo.....",
			"....oBBBoBo.....",
			"....oBBBBoo.....",
			"....ooooo.......",
		],
		# attack
		[
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
			"..osssssmmmDo.R.",
			"...oSSSSDDo.rr..",
			"....orrrrrRR....",
			".oooDmmLvvvVo...",
			".osDDmmmvvvVo...",
			".oooDmmmvvvVko..",
			"...obbbbqqbbKo..",
			"....oDmmQQDoo...",
			"....otttttto....",
			"....oppooPPPo...",
			"...occo..occo...",
			"...oBco..oBBo...",
			"..oBBBo..oBBBo..",
			"..ooooo..ooooo..",
		],
		# hold
		[
			"................",
			".o...oooooo...o.",
			"oso.oLmmmmLo.oso",
			"osooLmmmmmmLooso",
			"ovooLmmmmmmLoovo",
			"omoLmmhhhhmmLomo",
			"omoDmhhhhhhmDomo",
			"omoDhhhsssshDomo",
			"omoDsessssesDomo",
			"omoDsessssesDomo",
			"omoDSsssSssSDomo",
			"omooDSSssSSDoomo",
			"ommDrrrrrrrrDmmo",
			"..oVvRrmmvvvVo..",
			"..oVvvRmmvvvVo..",
			"..oVvvvmmvvvVo..",
			"..obbbbyybqqbo..",
			"..oDmmmmmmQQDo..",
			"..oDttttttttDo..",
			"...oPppooppPo...",
			"...occcooccco...",
			"...oBcBooBcBo...",
			"...oBBBooBBBo...",
			"...oooooooooo...",
		],
		# fallen
		[
			"................",
			"................",
			"................",
			"................",
			"................",
			"................",
			"................",
			"................",
			"................",
			"................",
			"................",
			"................",
			"................",
			"................",
			"................",
			"................",
			"................",
			"...oooo.........",
			"..oLmmmoooooo...",
			".oLmhhsoDmmmtooo",
			".oDmhHsrmmmmtpBo",
			".oDmmhsrDmmmtpBo",
			"..oDDmmoDbbmtooo",
			"...oooo.ooooo...",
		],
	],
}


func _initialize() -> void:
	var image: Image = Image.create(W * COLUMNS.size(), H * ROWS.size(), false, Image.FORMAT_RGBA8)
	image.fill(Color(0, 0, 0, 0))
	for row: int in ROWS.size():
		var frames: Array = FRAMES[ROWS[row]].duplicate()
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


## The frames of `facing` that are made from its drawn ones, in COLUMNS order after DRAWN.
static func derived(facing: String) -> Array:
	var drawn: Array = FRAMES[facing]
	var out: Array = [sink(drawn[COLUMNS.find("idle")]), sink(drawn[COLUMNS.find("attack")]), sink(drawn[COLUMNS.find("blink")])]
	for step: String in ["walk_a", "pass_a", "walk_b", "pass_b"]:
		var frame: Array = drawn[COLUMNS.find(step)]
		out.append(lean(frame) if facing == "side" else frame)
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
