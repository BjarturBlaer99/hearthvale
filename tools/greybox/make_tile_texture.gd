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
const PLASTER: Color = Color(0.92, 0.87, 0.74)
const TIMBER: Color = Color(0.30, 0.19, 0.11)
const THATCH: Color = Color(0.80, 0.66, 0.34)
## The coop's roof: wooden shingles gone silver-brown in the weather.
const SHINGLE: Color = Color(0.58, 0.48, 0.38)
## The big barn's roof: boards painted green, with standing seams.
const ROOF_GREEN: Color = Color(0.28, 0.50, 0.38)
## The shadow under eaves and under an upper floor that juts out.
const EAVE_SHADOW: Color = Color(0.16, 0.10, 0.09)
## Shadows on see-through props darken whatever grass they're drawn over (violet, not black).
const SHADOW: Color = Color(0.14, 0.06, 0.24, 0.30)

## The pixel art of the props and furniture added in H12: each a palette name and 16 rows.
const PROP_PALETTES: Dictionary = {
	"wood": {"L": Color(0.62, 0.42, 0.22), "w": Color(0.78, 0.58, 0.34), "W": Color(0.50, 0.32, 0.16), "s": Color(0.00, 0.00, 0.00, 0.25), "i": Color(0.42, 0.42, 0.48), "b": Color(0.40, 0.25, 0.12)},
	"hay": {"y": Color(0.92, 0.80, 0.42), "Y": Color(0.76, 0.62, 0.28), "b": Color(0.58, 0.40, 0.20), "s": Color(0.00, 0.00, 0.00, 0.25)},
	"log": {"r": Color(0.84, 0.68, 0.44), "R": Color(0.62, 0.46, 0.26), "b": Color(0.48, 0.32, 0.16), "B": Color(0.34, 0.22, 0.10), "s": Color(0.00, 0.00, 0.00, 0.25)},
	"lamp": {"y": Color(1.00, 0.88, 0.45), "Y": Color(1.00, 0.97, 0.75), "i": Color(0.30, 0.30, 0.36), "s": Color(0.00, 0.00, 0.00, 0.25)},
	"stone": {"g": Color(0.58, 0.58, 0.62), "G": Color(0.40, 0.40, 0.46), "l": Color(0.74, 0.74, 0.78), "m": Color(0.40, 0.56, 0.30), "s": Color(0.00, 0.00, 0.00, 0.25)},
	"stall": {"r": Color(0.80, 0.22, 0.22), "R": Color(0.60, 0.14, 0.14), "w": Color(0.96, 0.94, 0.88), "W": Color(0.80, 0.78, 0.72), "L": Color(0.62, 0.42, 0.22), "p": Color(0.78, 0.58, 0.34), "P": Color(0.50, 0.32, 0.16), "a": Color(0.88, 0.18, 0.20), "A": Color(0.98, 0.50, 0.40), "c": Color(0.42, 0.70, 0.30), "C": Color(0.26, 0.48, 0.18), "t": Color(0.86, 0.66, 0.36), "s": Color(0.00, 0.00, 0.00, 0.25)},
	"laundry": {"r": Color(0.80, 0.74, 0.58), "b": Color(0.40, 0.56, 0.86), "B": Color(0.28, 0.40, 0.68), "w": Color(0.96, 0.95, 0.90), "W": Color(0.80, 0.80, 0.78), "L": Color(0.62, 0.42, 0.22), "s": Color(0.00, 0.00, 0.00, 0.25)},
	"furniture": {"L": Color(0.58, 0.38, 0.20), "w": Color(0.74, 0.54, 0.32), "W": Color(0.46, 0.30, 0.14), "i": Color(0.42, 0.42, 0.48), "g": Color(0.36, 0.62, 0.26), "G": Color(0.22, 0.44, 0.16), "c": Color(0.80, 0.50, 0.30), "C": Color(0.58, 0.32, 0.18), "y": Color(1.00, 0.88, 0.45), "Y": Color(1.00, 0.97, 0.75), "e": Color(0.94, 0.90, 0.80), "r": Color(0.70, 0.20, 0.22), "u": Color(0.30, 0.42, 0.72), "t": Color(0.86, 0.66, 0.36), "v": Color(0.56, 0.30, 0.56), "s": Color(0.00, 0.00, 0.00, 0.22)},
}
const PROP_ART: Dictionary = {
	"prop_crate": ["wood", [
		"................",
		".oooooooooooooo.",
		".oLLLLLLLLLLLLo.",
		".oLWwwwwwwwwWLo.",
		".oLwWwwwwwwWwLo.",
		".oLwwWwwwwWwwLo.",
		".oLwwwWwwWwwwLo.",
		".oLwwwwWWwwwwLo.",
		".oLwwwwWWwwwwLo.",
		".oLwwwWwwWwwwLo.",
		".oLwwWwwwwWwwLo.",
		".oLwWwwwwwwWwLo.",
		".oLWwwwwwwwwWLo.",
		".oLLLLLLLLLLLLo.",
		".oooooooooooooo.",
		"..ssssssssssss..",
	]],
	"prop_keg": ["wood", [
		"................",
		"....oooooooo....",
		"...owwwwwwwwo...",
		"..owWwwwwwwWwo..",
		"..oiiiiiiiiiio..",
		"..owwwwwwwwwwo..",
		".owwwwwwwwwwwwo.",
		".owWwwwwwwwwWwo.",
		".oiiiiiiiiiiiio.",
		".owwwwwwwwwwwwo.",
		".owWwwwwwwwwWwo.",
		"..owwwwwwwwwwo..",
		"..oiiiiiiiiiio..",
		"...owwwwwwwwo...",
		"....oooooooo....",
		"...ssssssssss...",
	]],
	"prop_hay": ["hay", [
		"................",
		"................",
		"................",
		"................",
		".oooooooooooooo.",
		".oyyYyyyyYyyyyo.",
		".oyYyyyYyyyYyyo.",
		".obbbbbbbbbbbbo.",
		".oyyyYyyyyYyyyo.",
		".oYyyyyYyyyyYyo.",
		".oyyYyyyyYyyyyo.",
		".obbbbbbbbbbbbo.",
		".oYyyyyyYyyyYyo.",
		".oyyYyyyyyYyyyo.",
		".oooooooooooooo.",
		"..ssssssssssss..",
	]],
	"prop_logs": ["log", [
		"................",
		"................",
		"................",
		"................",
		"......oooo......",
		".....orrrro.....",
		".....orRRro.....",
		".....orrrro.....",
		"..ooooooooooo...",
		".orrrroorrrro...",
		".orRRroorRRro...",
		".orrrroorrrro...",
		".obbbbbbbbbbbo..",
		".obBbbBbbBbbbo..",
		".ooooooooooooo..",
		"..sssssssssss...",
	]],
	"prop_stump": ["log", [
		"................",
		"................",
		"................",
		"................",
		"................",
		"................",
		"................",
		"....oooooooo....",
		"...orrrrrrrro...",
		"...orRrRRrRro...",
		"...orrrRRrrro...",
		"...obrrrrrrbo...",
		"..obbbbbbbbbbo..",
		"..obBbbBbbBbbo..",
		"..oooooooooooo..",
		"...ssssssssss...",
	]],
	"prop_lamp": ["lamp", [
		"......oooo......",
		".....oyyyyo.....",
		".....oyYYyo.....",
		".....oyyyyo.....",
		"......oiio......",
		"......oiio......",
		"......oiio......",
		"......oiio......",
		"......oiio......",
		"......oiio......",
		"......oiio......",
		"......oiio......",
		"......oiio......",
		".....oiiiio.....",
		".....oooooo.....",
		"......ssss......",
	]],
	"prop_stone": ["stone", [
		"................",
		"......oooo......",
		".....ogggGo.....",
		".....olggGo.....",
		"....olgggGGo....",
		"....olggggGo....",
		"....olgmggGo....",
		"....olggmgGo....",
		"....olgggGGo....",
		"...olgggggGGo...",
		"...olggmmggGo...",
		"...olgggggGGo...",
		"...olgggggGGo...",
		"...oooooooooo...",
		"....ssssssss....",
		"................",
	]],
	"bucket": ["wood", [
		"................",
		"................",
		"................",
		"................",
		"................",
		"................",
		"......oo........",
		".....o..o.......",
		"....o....o......",
		"...oooooooo.....",
		"...owwwwwwo.....",
		"...oiiiiiio.....",
		"....owwwwo......",
		"....owwwwo......",
		".....oooo.......",
		"....ssssss......",
	]],
	"stall_nw": ["stall", [
		"................",
		".ooooooooooooooo",
		".orrwwwwrrrrwwww",
		".orrwwwwrrrrwwww",
		".orrwwwwrrrrwwww",
		".orrwwwwrrrrwwww",
		".orrwwwwrrrrwwww",
		".orrwwwwrrrrwwww",
		".orrwwwwrrrrwwww",
		".oRRWWWWRRRRWWWW",
		".orrowwworrrowww",
		".o...o...o...o..",
		"...oLo..........",
		"...oLo..........",
		"...oLo..........",
		"...oLo..........",
	]],
	"stall_n": ["stall", [
		"................",
		"oooooooooooooooo",
		"rrrrwwwwrrrrwwww",
		"rrrrwwwwrrrrwwww",
		"rrrrwwwwrrrrwwww",
		"rrrrwwwwrrrrwwww",
		"rrrrwwwwrrrrwwww",
		"rrrrwwwwrrrrwwww",
		"rrrrwwwwrrrrwwww",
		"RRRRWWWWRRRRWWWW",
		"orrrowwworrrowww",
		".o...o...o...o..",
		"................",
		"................",
		"................",
		"................",
	]],
	"stall_ne": ["stall", [
		"................",
		"ooooooooooooooo.",
		"rrrrwwwwrrrrwwo.",
		"rrrrwwwwrrrrwwo.",
		"rrrrwwwwrrrrwwo.",
		"rrrrwwwwrrrrwwo.",
		"rrrrwwwwrrrrwwo.",
		"rrrrwwwwrrrrwwo.",
		"rrrrwwwwrrrrwwo.",
		"RRRRWWWWRRRRWWo.",
		"orrrowwworrrowo.",
		".o...o...o...o..",
		"..........oLo...",
		"..........oLo...",
		"..........oLo...",
		"..........oLo...",
	]],
	"stall_sw": ["stall", [
		"...oLo..........",
		"...oLo..........",
		"...oLo..oaao..oc",
		"...oLo.oaAaao.oc",
		"...oLo.oaaaao.oc",
		"..oooooooooooooo",
		".oLLLLLLLLLLLLLL",
		".opppppppppppppp",
		".oPpppppPpppppPp",
		".oPpppppPpppppPp",
		".oPpppppPpppppPp",
		".oPpppppPpppppPp",
		".oPpppppPpppppPp",
		".oPpppppPpppppPp",
		".ooooooooooooooo",
		"..ssssssssssssss",
	]],
	"stall_s": ["stall", [
		"................",
		"................",
		"co..ottto...oaao",
		"Cco.otttto..oaAa",
		"cco.otttto..oaaa",
		"oooooooooooooooo",
		"LLLLLLLLLLLLLLLL",
		"pppppppppppppppp",
		"ppppPpppppPppppp",
		"ppppPpppppPppppp",
		"ppppPpppppPppppp",
		"ppppPpppppPppppp",
		"ppppPpppppPppppp",
		"ppppPpppppPppppp",
		"oooooooooooooooo",
		"ssssssssssssssss",
	]],
	"stall_se": ["stall", [
		"..........oLo...",
		"..........oLo...",
		"..occo...oAAo...",
		"o.ocCco..oaaao..",
		"o.occco..oaaao..",
		"oooooooooooooo..",
		"LLLLLLLLLLLLLLo.",
		"ppppppppppppppo.",
		"PpppppPpppppPpo.",
		"PpppppPpppppPpo.",
		"PpppppPpppppPpo.",
		"PpppppPpppppPpo.",
		"PpppppPpppppPpo.",
		"PpppppPpppppPpo.",
		"ooooooooooooooo.",
		"ssssssssssssss..",
	]],
	"laundry": ["laundry", [
		"................",
		"................",
		"................",
		"................",
		"rrrrrrrrrrrrrrrr",
		"..obbbbo.owwwwo.",
		".obbbbbbo.wwwww.",
		".obBbbBbo.wWwww.",
		"..obbbbo..wwwWw.",
		"..obbbbo..wwwww.",
		"..obbbbo..wWwww.",
		"..oooooo..wwwww.",
		"..........ooooo.",
		"................",
		"................",
		"................",
	]],
	"prop_post": ["laundry", [
		"................",
		"................",
		".......oo.......",
		"......oLLo......",
		"rrrrrroLLorrrrrr",
		"......oLLo......",
		"......oLLo......",
		"......oLLo......",
		"......oLLo......",
		"......oLLo......",
		"......oLLo......",
		"......oLLo......",
		"......oLLo......",
		".....oLLLLo.....",
		".....oooooo.....",
		"......ssss......",
	]],
	"chair": ["furniture", [
		"................",
		"................",
		"................",
		"....oooooooo....",
		"....owwwwwwo....",
		"....oWWWWWWo....",
		"....owwwwwwo....",
		"....oooooooo....",
		"...owwwwwwwwo...",
		"...oLLLLLLLLo...",
		"...oooooooooo...",
		"...ow......wo...",
		"...ow......wo...",
		"...oo......oo...",
		"....ssssssss....",
		"................",
	]],
	"cupboard": ["furniture", [
		".oooooooooooooo.",
		".oLLLLLLLLLLLLo.",
		".owwwwwwwwwwwwo.",
		".owWWWWWoWWWWWo.",
		".owWwwwWoWwwwWo.",
		".owWwwwWoWwwwWo.",
		".owWwwywoywwwWo.",
		".owWwwwWoWwwwWo.",
		".owWwwwWoWwwwWo.",
		".owWWWWWoWWWWWo.",
		".owwwwwwwwwwwwo.",
		".owWWWWWWWWWWWo.",
		".owwwwwwwwwwwwo.",
		".oooooooooooooo.",
		".ow..........wo.",
		"..ssssssssssss..",
	]],
	"loom": ["furniture", [
		"................",
		".oooooooooooooo.",
		".oLLLLLLLLLLLLo.",
		".owrurvrurvrurwo",
		".owrurvrurvruwo.",
		".owrurvrurvruwo.",
		".owrurvrurvruwo.",
		".owrrrrrrrrrrwo.",
		".owvvvvvvvvvvwo.",
		".owuuuuuuuuuuwo.",
		".owrurvrurvruwo.",
		".oLLLLLLLLLLLLo.",
		".oooooooooooooo.",
		".ow..........wo.",
		".oo..........oo.",
		"..ssssssssssss..",
	]],
	"plant": ["furniture", [
		"................",
		"......oo........",
		".....oggo.oo....",
		"..oo.oggooggo...",
		".oggooGggoGgo...",
		".ogGgoGgggggo...",
		"..ogggGggGgo....",
		"...oggggGgo.....",
		"....oooooo......",
		"....occcco......",
		"...occcccco.....",
		"...occcCcco.....",
		"....oCCCCo......",
		"....oooooo......",
		"...ssssssss.....",
		"................",
	]],
	"candle": ["furniture", [
		"................",
		"......oyo.......",
		".....oyYyo......",
		"......oyo.......",
		"......oeo.......",
		"......oeo.......",
		"......oeo.......",
		".....oiiio......",
		"......oio.......",
		"......oio.......",
		"......oio.......",
		"......oio.......",
		".....oiiio......",
		"....oiiiiio.....",
		"....ooooooo.....",
		".....sssss......",
	]],
	"counter": ["furniture", [
		"................",
		"................",
		"..oooo....oooo..",
		".ocCcco..ottto..",
		".occcco..ottto..",
		"oooooooooooooooo",
		"oLLLLLLLLLLLLLLo",
		"owwwwwwwwwwwwwwo",
		"owWwwwwwWwwwwwWo",
		"owWwwwwwWwwwwwWo",
		"owWwwwwwWwwwwwWo",
		"owWwwwwwWwwwwwWo",
		"owwwwwwwwwwwwwwo",
		"oooooooooooooooo",
		".ssssssssssssss.",
		"................",
	]],
	"stool": ["furniture", [
		"................",
		"................",
		"................",
		"................",
		"................",
		"................",
		".....oooooo.....",
		"....owwwwwwo....",
		"....oLLLLLLo....",
		"....oooooooo....",
		".....ow..wo.....",
		".....ow..wo.....",
		".....ow..wo.....",
		".....oo..oo.....",
		"....ssssssss....",
		"................",
	]],
	"bookcase": ["furniture", [
		".oooooooooooooo.",
		".oLLLLLLLLLLLLo.",
		".oruvruvtruvruo.",
		".oruvruvtruvruo.",
		".oruvruvtruvruo.",
		".oLLLLLLLLLLLLo.",
		".otruvrtuvrtruo.",
		".otruvrtuvrtruo.",
		".otruvrtuvrtruo.",
		".oLLLLLLLLLLLLo.",
		".ouvrtruvtruvro.",
		".ouvrtruvtruvro.",
		".oLLLLLLLLLLLLo.",
		".oooooooooooooo.",
		"..ssssssssssss..",
		"................",
	]],
}

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
	_pit(Vector2i(6, row), false)
	_pit(Vector2i(7, row), true)
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
	for height: int in GreyboxTiles.COLUMNS:
		_ledge(Vector2i(height, GreyboxTiles.ROW_LEDGE), height)
	for frame: int in GreyboxTiles.WATER_FRAMES:
		_water_frame(Vector2i(frame, GreyboxTiles.ROW_WATER), frame)
	for index: int in GreyboxTiles.MARKER_KINDS.size():
		_marker(Vector2i(index, GreyboxTiles.ROW_MARKERS), index)
	for index: int in GreyboxTiles.LAND_MARKER_KINDS.size():
		_marker(Vector2i(index, GreyboxTiles.ROW_LAND_MARKERS), index, true)
	for kind: String in GreyboxTiles.HOUSE_KINDS + GreyboxTiles.ROOF_B_KINDS:
		_house(GreyboxTiles.coords(kind), kind)
	_pine_art(GreyboxTiles.coords("prop_tree_b"))
	_oak_art(GreyboxTiles.coords("prop_tree_c"))
	_canopy(GreyboxTiles.coords("prop_canopy"))
	_cherry_art(GreyboxTiles.coords("prop_cherry"))
	_chimney(GreyboxTiles.coords("chimney"))
	_cross(GreyboxTiles.coords("cross_l"), true)
	_cross(GreyboxTiles.coords("cross_r"), false)
	_shop_sign(GreyboxTiles.coords("shop_sign"))
	for frame: int in GreyboxTiles.SMOKE_FRAMES:
		_smoke(Vector2i(frame, GreyboxTiles.ROW_SMOKE), frame)
	for index: int in GreyboxTiles.PROPS_B_KINDS.size():
		_ascii(Vector2i(index, GreyboxTiles.ROW_PROPS_B), GreyboxTiles.PROPS_B_KINDS[index])
	for index: int in GreyboxTiles.PROPS_C_KINDS.size():
		_ascii(Vector2i(index, GreyboxTiles.ROW_PROPS_C), GreyboxTiles.PROPS_C_KINDS[index])
	for index: int in GreyboxTiles.FURNITURE_B_KINDS.size():
		_floor(Vector2i(index, GreyboxTiles.ROW_FURNITURE_B))
		_ascii(Vector2i(index, GreyboxTiles.ROW_FURNITURE_B), GreyboxTiles.FURNITURE_B_KINDS[index])
	# The marsh (Willowmere): its ground, boardwalks, reeds and ruin, then its decorations and props.
	_marsh(GreyboxTiles.coords("marsh"))
	_marsh(GreyboxTiles.coords("marsh_solid"))
	_boardwalk(GreyboxTiles.coords("boardwalk"), true)
	_boardwalk(GreyboxTiles.coords("boardwalk_ns"), false)
	_reeds(GreyboxTiles.coords("reeds"), 0)
	_reeds(GreyboxTiles.coords("reeds_b"), 1)
	_ruin_wall(GreyboxTiles.coords("ruin_wall"))
	_ruin_top(GreyboxTiles.coords("ruin_top"))
	_cattail(GreyboxTiles.coords("cattail"))
	_moss(GreyboxTiles.coords("moss"))
	_planks(GreyboxTiles.coords("planks"))
	_ruin_hole(GreyboxTiles.coords("ruin_hole"))
	_art(GreyboxTiles.coords("prop_mossy_rock"), MARSH_ROCK_PALETTE, MARSH_ROCK_ART)
	_art(GreyboxTiles.coords("prop_marsh_lantern"), MARSH_LANTERN_PALETTE, MARSH_LANTERN_ART)
	_art(GreyboxTiles.coords("prop_marsh_lantern_lit"), MARSH_LANTERN_LIT_PALETTE, MARSH_LANTERN_ART)
	_willow_art(GreyboxTiles.coords("prop_willow"))
	# The Old Quarry: its earth and rock, the outcrop and the mouth, a ladder, then its looks.
	_cave_floor(GreyboxTiles.coords("cave_floor"))
	_cave_floor(GreyboxTiles.coords("cave_solid"))
	_cave_wall(GreyboxTiles.coords("cave_wall"))
	_cave_wall_face(GreyboxTiles.coords("cave_wall_face"))
	_quarry_rock(GreyboxTiles.coords("quarry_rock"))
	_mine_mouth(GreyboxTiles.coords("mine_mouth"))
	_ladder_up(GreyboxTiles.coords("ladder_up"))
	_rails(GreyboxTiles.coords("rails"))
	_rubble(GreyboxTiles.coords("rubble"))
	_crystal_vein(GreyboxTiles.coords("crystal_vein"))
	_art(GreyboxTiles.coords("prop_timber"), TIMBER_PALETTE, TIMBER_ART)
	# The Homestead's buildings (phase 3): a building site, the barn's plank walls and doors, and
	# the silo. The coop and the shed wear the village's own house tiles.
	_site(GreyboxTiles.coords("site"))
	_site(GreyboxTiles.coords("site_timber"))
	_site_timber(GreyboxTiles.coords("site_timber"))
	_barn_wall(GreyboxTiles.coords("barn_wall"))
	_barn_wall(GreyboxTiles.coords("barn_loft"))
	_barn_loft(GreyboxTiles.coords("barn_loft"))
	_barn_wall(GreyboxTiles.coords("barn_door"))
	_barn_door(GreyboxTiles.coords("barn_door"))
	var silo: Array[Vector2i] = []
	for kind: String in GreyboxTiles.SILO_KINDS:
		silo.append(GreyboxTiles.coords(kind))
	_silo(silo)
	# The shed's furniture: a rack of tools on the wall, and sacks on a crate.
	for index: int in GreyboxTiles.FURNITURE_C_KINDS.size():
		_floor(Vector2i(index, GreyboxTiles.ROW_FURNITURE_C))
	_tool_rack(GreyboxTiles.coords("tool_rack"))
	_sacks(GreyboxTiles.coords("sacks"))
	# Art pass 3: warm every colour and soften every outline, tile by tile.
	PixelGrade.apply(_image, OUTLINE, Rect2i(), Vector2i(T, T))
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


## Grass: flecks and blades in a yellower light and a bluer shade (warm light, cool shadow),
## some of the blades two wide. Seamless.
func _ground(tile: Vector2i, color: Color) -> void:
	_fill(tile, color)
	var sun: Color = Color(minf(color.r * 1.12 + 0.03, 1.0), minf(color.g * 1.07 + 0.02, 1.0), color.b * 0.90)
	var shade: Color = Color(color.r * 0.80, color.g * 0.88, minf(color.b * 1.04, 1.0))
	for y: int in T:
		for x: int in T:
			var n: int = _hash(x, y, 1) % 100
			if n < 9:
				_px(tile, x, y, color.lerp(shade, 0.45))
			elif n < 14:
				_px(tile, x, y, color.lerp(sun, 0.4))
	for i: int in 8:
		var bx: int = _hash(i, 3, 7) % T
		var by: int = 1 + _hash(i, 9, 5) % (T - 3)
		_px(tile, bx, by, sun)
		_px(tile, bx, by + 1, shade)
		if i % 3 == 0:
			_px(tile, bx + 1, by + 1, color.lerp(sun, 0.5))


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
	var dark: Color = Color(0.09, 0.30, 0.21)
	var mid: Color = Color(0.20, 0.47, 0.19)
	var light: Color = Color(0.47, 0.68, 0.24)
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


## A cherry tree in blossom, see-through around it. The game stands a tall picture in its place
## (Scenery, tools/art/make_scenery.gd); this tile marks the cell and shows in the editor.
func _cherry_art(tile: Vector2i) -> void:
	var deep: Color = Color(0.76, 0.35, 0.52)
	var mid: Color = Color(0.91, 0.53, 0.67)
	var pale: Color = Color(0.98, 0.76, 0.83)
	_ellipse(tile, Vector2(8.5, 13.8), Vector2(6.5, 2.4), SHADOW)
	_rect(tile, Rect2i(6, 10, 4, 5), OUTLINE)
	_rect(tile, Rect2i(7, 10, 2, 4), Color(0.28, 0.17, 0.16))
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
					shade = pale
				elif x - y > 4 or y > 9:
					shade = deep
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


## Plaster between two posts: what a house's timber framing is drawn on.
func _plaster(tile: Vector2i) -> void:
	_fill(tile, PLASTER)
	for y: int in T:
		for x: int in T:
			if _hash(x, y, 31) % 11 == 0:
				_px(tile, x, y, PLASTER.darkened(0.06))
	_rect(tile, Rect2i(0, 0, 1, T), TIMBER)
	_rect(tile, Rect2i(T - 1, 0, 1, T), TIMBER.darkened(0.2))


## A house's ground floor: plaster and posts on a stone footing, in the shadow of the upper
## floor that juts out above it.
func _wall(tile: Vector2i) -> void:
	_plaster(tile)
	_rect(tile, Rect2i(0, 0, T, 2), EAVE_SHADOW)
	_rect(tile, Rect2i(0, 2, T, 1), PLASTER.darkened(0.2))
	var footing: Color = Color(0.52, 0.50, 0.52)
	_rect(tile, Rect2i(0, 12, T, 4), footing.darkened(0.35))
	for x: int in range(0, T, 4):
		var offset: int = 0 if x % 8 == 0 else 1
		_rect(tile, Rect2i(x, 12 + offset, 3, 2), footing)
		_px(tile, x, 12 + offset, footing.lightened(0.2))


## A ground-floor window: small leaded panes in a dark frame, over a box of flowers.
func _wall_window(tile: Vector2i) -> void:
	_wall(tile)
	_rect(tile, Rect2i(4, 4, 8, 6), TIMBER)
	_leaded_glass(tile, Rect2i(5, 5, 6, 4))
	_rect(tile, Rect2i(3, 10, 10, 2), Color(0.48, 0.30, 0.16))
	_rect(tile, Rect2i(3, 11, 10, 1), Color(0.34, 0.20, 0.10))
	for p: Vector2i in [Vector2i(4, 9), Vector2i(6, 9), Vector2i(9, 9), Vector2i(11, 9)]:
		_px(tile, p.x, p.y, Color(0.90, 0.30, 0.38) if p.x % 3 != 0 else Color(0.98, 0.85, 0.35))
	for p: Vector2i in [Vector2i(5, 9), Vector2i(8, 9), Vector2i(10, 9)]:
		_px(tile, p.x, p.y, Color(0.30, 0.55, 0.25))


## Leaded glass over `area`: small panes in a diamond lattice of lead, with a glint.
func _leaded_glass(tile: Vector2i, area: Rect2i) -> void:
	var glass: Color = Color(0.52, 0.70, 0.86)
	var lead: Color = Color(0.24, 0.30, 0.40)
	for y: int in range(area.position.y, area.end.y):
		for x: int in range(area.position.x, area.end.x):
			var on_lead: bool = (x + y) % 4 == 0 or posmod(x - y, 4) == 0
			_px(tile, x, y, lead if on_lead else glass)
	_px(tile, area.position.x + 1, area.position.y, Color(0.92, 0.96, 1.0))


## A half-timbered upper floor: a rail along the top, posts at the sides, a diagonal brace
## ("a" rises to the right, "b" to the left, "" none) and, along the bottom, the beam it rests
## on, with the ends of its joists.
func _timber(tile: Vector2i, brace: String) -> void:
	_plaster(tile)
	_rect(tile, Rect2i(0, 0, T, 2), TIMBER)
	_rect(tile, Rect2i(0, 2, T, 1), PLASTER.darkened(0.14))
	if brace != "":
		for i: int in 10:
			var x: int = 2 + i if brace == "a" else 12 - i
			_px(tile, x, 12 - i, TIMBER)
			_px(tile, x + 1, 12 - i, TIMBER.lightened(0.1))
	_rect(tile, Rect2i(0, 13, T, 3), TIMBER)
	_rect(tile, Rect2i(0, 13, T, 1), TIMBER.lightened(0.2))
	for x: int in range(2, T, 4):
		_px(tile, x, 15, TIMBER.darkened(0.4))


## An upper-floor window: leaded panes between open shutters.
func _timber_window(tile: Vector2i) -> void:
	_timber(tile, "")
	var shutter: Color = Color(0.50, 0.31, 0.16)
	_rect(tile, Rect2i(2, 3, 12, 9), OUTLINE)
	for x: int in [3, 11]:
		_rect(tile, Rect2i(x, 4, 2, 7), shutter)
		_rect(tile, Rect2i(x, 4, 2, 1), shutter.lightened(0.2))
		_rect(tile, Rect2i(x, 7, 2, 1), shutter.darkened(0.3))
	_leaded_glass(tile, Rect2i(5, 4, 6, 7))
	_rect(tile, Rect2i(2, 11, 12, 1), TIMBER.lightened(0.25))


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
	var deep: Color = Color(0.17, 0.48, 0.72)
	_fill(tile, deep)
	for y: int in T:
		for x: int in T:
			if _hash(x, y, 51) % 7 == 0:
				_px(tile, x, y, deep.lightened(0.06))
	var ripple: Color = Color(0.62, 0.84, 0.95)
	for i: int in 3:
		var rx: int = _hash(i, 5, 53) % T
		var ry: int = 2 + _hash(i, 7, 57) % (T - 4)
		for dx: int in 3:
			_px(tile, rx + dx, ry, ripple)
		_px(tile, rx - 1, ry + 1, deep.lightened(0.15))
		_px(tile, rx + 3, ry + 1, deep.lightened(0.15))
	_px(tile, _hash(9, 9, 59) % T, _hash(4, 4, 61) % T, Color(0.95, 0.98, 1.0))


## One frame of animated water: the ripples drift right and bob, and the glint moves, frame by
## frame (frames wrap, so the loop is seamless).
func _water_frame(tile: Vector2i, frame: int) -> void:
	var deep: Color = Color(0.17, 0.48, 0.72)
	_fill(tile, deep)
	for y: int in T:
		for x: int in T:
			if _hash(x, y, 51) % 7 == 0:
				_px(tile, x, y, deep.lightened(0.06))
	var ripple: Color = Color(0.62, 0.84, 0.95)
	for i: int in 3:
		var rx: int = (_hash(i, 5, 53) + frame * 2) % T
		var ry: int = 2 + _hash(i, 7, 57) % (T - 4) + (1 if (frame + i) % 2 == 0 else 0)
		for dx: int in 3:
			_px(tile, (rx + dx) % T, ry, ripple)
		_px(tile, (rx + T - 1) % T, ry + 1, deep.lightened(0.15))
		_px(tile, (rx + 3) % T, ry + 1, deep.lightened(0.15))
	if frame % 2 == 0:
		_px(tile, (_hash(9, 9, 59) + frame * 3) % T, _hash(4, 4, 61) % T, Color(0.95, 0.98, 1.0))


## Paints PROP_ART[`art`] onto `tile` ("." clear, "o" outline, the rest from its palette),
## blending see-through colours (shadows) over what's there.
func _ascii(tile: Vector2i, art: String) -> void:
	var entry: Array = PROP_ART[art]
	var palette: Dictionary = PROP_PALETTES[entry[0]]
	var rows: Array = entry[1]
	for y: int in T:
		for x: int in T:
			var key: String = (rows[y] as String)[x]
			if key == ".":
				continue
			var color: Color = OUTLINE if key == "o" else palette[key]
			var at: Vector2i = Vector2i(tile.x * T + x, tile.y * T + y)
			_image.set_pixelv(at, _image.get_pixelv(at).blend(color) if color.a < 1.0 else color)


## A spawn marker (only ever seen in the editor): a bright square with a dot per index, so
## the kinds tell apart. One of the hero's land (`land`: the second row of markers) has its
## line along the bottom.
func _marker(tile: Vector2i, index: int, land: bool = false) -> void:
	var colors: Array = [Color(0.3, 0.9, 0.3), Color(0.85, 0.5, 0.25), Color(1, 1, 1), Color(1, 0.85, 0.2), Color(0.9, 1, 0.4), Color(0.6, 0.6, 0.65), Color(0.7, 0.5, 0.3), Color(0.5, 0.35, 0.2)]
	if land:
		colors = [Color(0.55, 0.8, 0.3), Color(0.2, 0.55, 0.25), Color(0.6, 0.45, 0.3), Color(0.45, 0.3, 0.2), Color(0.5, 0.5, 0.55), Color(0.35, 0.35, 0.4), Color(0.85, 0.75, 0.35)]
	var color: Color = colors[index]
	_rect(tile, Rect2i(2, 2, T - 4, T - 4), Color(color, 0.55))
	_rect(tile, Rect2i(2, T - 3 if land else 2, T - 4, 1), OUTLINE)
	for dot: int in index + 1:
		_px(tile, 4 + dot * 2, 8, OUTLINE)


## A raised dungeon floor: big flagstones, lighter the higher they stand, each lit on its top
## edge, in dark mortar.
func _ledge(tile: Vector2i, height: int) -> void:
	var stone: Color = Color(0.44, 0.44, 0.50).lightened(height * 0.04)
	_fill(tile, stone.darkened(0.45))
	for flag: Rect2i in [Rect2i(0, 0, 9, 7), Rect2i(10, 0, 6, 7), Rect2i(0, 8, 5, 8), Rect2i(6, 8, 10, 8)]:
		var inner: Rect2i = Rect2i(flag.position, flag.size - Vector2i(1, 1))
		_rect(tile, inner, stone)
		_rect(tile, Rect2i(inner.position, Vector2i(inner.size.x, 1)), stone.lightened(0.15))
		_rect(tile, Rect2i(inner.position + Vector2i(0, inner.size.y - 1), Vector2i(inner.size.x, 1)), stone.darkened(0.12))
	for y: int in T:
		for x: int in T:
			if _hash(x, y, 67) % 23 == 0:
				_px(tile, x, y, stone.darkened(0.2))


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
		_px(tile, int(pad.x), int(pad.y), Color(0.17, 0.48, 0.72))
		_px(tile, int(pad.x) + 1, int(pad.y) - 1, Color(0.17, 0.48, 0.72))
	for p: Vector2i in [Vector2i(10, 10), Vector2i(12, 10), Vector2i(11, 9), Vector2i(11, 11)]:
		_px(tile, p.x, p.y, Color(0.96, 0.62, 0.78))
	_px(tile, 11, 10, Color(1.0, 0.90, 0.40))


func _rect(tile: Vector2i, rect: Rect2i, color: Color) -> void:
	for y: int in range(rect.position.y, rect.end.y):
		for x: int in range(rect.position.x, rect.end.x):
			_px(tile, x, y, color)


## An arched plank door in the ground floor's wall: iron bands, studs and a ring.
func _door(tile: Vector2i) -> void:
	_wall(tile)
	var wood: Color = Color(0.44, 0.27, 0.13)
	var iron: Color = Color(0.24, 0.25, 0.29)
	_rect(tile, Rect2i(2, 4, 12, 12), OUTLINE)
	_rect(tile, Rect2i(3, 3, 10, 1), OUTLINE)
	_rect(tile, Rect2i(5, 2, 6, 1), OUTLINE)
	_rect(tile, Rect2i(3, 5, 10, 11), wood)
	_rect(tile, Rect2i(4, 4, 8, 1), wood)
	_rect(tile, Rect2i(5, 3, 6, 1), wood.lightened(0.12))
	for x: int in [5, 8, 10]:
		_rect(tile, Rect2i(x, 4, 1, 12), wood.darkened(0.28))
	for y: int in [7, 13]:
		_rect(tile, Rect2i(3, y, 10, 1), iron)
		_px(tile, 4, y, iron.lightened(0.45))
		_px(tile, 11, y, iron.lightened(0.45))
	_px(tile, 10, 10, Color(0.92, 0.80, 0.36))
	_px(tile, 10, 11, Color(0.66, 0.52, 0.20))


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


# --- House fronts (art pass 2) ----------------------------------------------------------------

## Paints house tile `kind` (GreyboxTiles.HOUSE_KINDS): a roof named by its style, part and
## gable end, a timber-framed upper wall, or a piece of the chapel.
func _house(tile: Vector2i, kind: String) -> void:
	if kind.begins_with("roof"):
		var part: String = "top" if kind.contains("_top") else ("eave" if kind.contains("_eave") else "")
		var edge: String = "l" if kind.ends_with("_l") else ("r" if kind.ends_with("_r") else "")
		if kind.begins_with("roof_thatch"):
			_thatch(tile, part)
		elif kind.begins_with("roof_shingle"):
			_shingles(tile, part)
		elif kind.begins_with("roof_green"):
			_green_boards(tile, part)
		else:
			var slate: bool = kind.begins_with("roof_blue")
			var color: Color = ROOF_BLUE if slate else ROOF_RED
			if part == "top":
				_roof_ridge(tile, color, slate)
			elif part == "eave":
				_roof_eave(tile, color, slate)
			elif slate:
				_slate(tile, color)
			else:
				_roof(tile, color)
		if edge != "":
			_barge_board(tile, edge == "l", part)
		return
	match kind:
		"wall_upper":
			_timber(tile, "a")
		"wall_upper_b":
			_timber(tile, "b")
		"wall_upper_window":
			_timber_window(tile)
		"chapel_wall":
			_stone(tile)
		"chapel_window":
			_chapel_window(tile)
		"chapel_door_l":
			_chapel_door(tile, true)
		"chapel_door_r":
			_chapel_door(tile, false)


## Thatch: straw laid in layers, each ending in a ragged fringe. `part` "top" adds the ridge's
## stitched cap, "eave" the overhanging ends above their shadow.
func _thatch(tile: Vector2i, part: String) -> void:
	for y: int in T:
		for x: int in T:
			var shade: Color = THATCH
			var tone: int = _hash(x, 0, 71) % 6
			if tone == 0:
				shade = THATCH.lightened(0.14)
			elif tone == 1:
				shade = THATCH.darkened(0.12)
			if y % 5 == 4 and _hash(x, y, 73) % 3 != 0:
				shade = THATCH.darkened(0.34)
			elif y % 5 == 0 and _hash(x, y, 75) % 4 == 0:
				shade = THATCH.darkened(0.2)
			_px(tile, x, y, shade)
	if part == "top":
		var cap: Color = THATCH.lightened(0.22)
		_rect(tile, Rect2i(0, 0, T, 5), cap)
		_rect(tile, Rect2i(0, 0, T, 1), THATCH.darkened(0.5))
		_rect(tile, Rect2i(0, 5, T, 1), THATCH.darkened(0.42))
		for x: int in range(1, T, 5):
			for stitch: Vector2i in [Vector2i(0, 1), Vector2i(2, 1), Vector2i(1, 2), Vector2i(0, 3), Vector2i(2, 3)]:
				_px(tile, x + stitch.x, stitch.y, THATCH.darkened(0.45))
	elif part == "eave":
		for x: int in T:
			var ends: int = 11 + _hash(x, 3, 77) % 3
			_px(tile, x, ends - 1, THATCH.lightened(0.2))
			for y: int in range(ends, T):
				_px(tile, x, y, EAVE_SHADOW)


## Wooden shingles (the coop's roof): small boards in courses of four pixels, each shingle
## its own shade of weathered wood, the joints staggered from course to course and the butt
## of each course catching the light. `part` "top" adds a capping board nailed along the
## ridge, "eave" the ragged ends of the last course above their shadow.
func _shingles(tile: Vector2i, part: String) -> void:
	for y: int in T:
		@warning_ignore("integer_division")
		var course: int = y / 4
		var offset: int = 0 if course % 2 == 0 else 2
		for x: int in T:
			@warning_ignore("integer_division")
			var shingle: int = (x + offset) / 4
			var tone: int = _hash(shingle, course, 79) % 5
			var shade: Color = SHINGLE
			if tone == 0:
				shade = SHINGLE.lightened(0.16)
			elif tone == 1:
				shade = SHINGLE.darkened(0.12)
			elif tone == 2:
				shade = SHINGLE.lerp(Color(0.62, 0.40, 0.24), 0.35)
			if y % 4 == 3:
				shade = SHINGLE.darkened(0.45)
			elif posmod(x + offset, 4) == 0:
				shade = shade.darkened(0.28)
			elif y % 4 == 2:
				shade = shade.lightened(0.10)
			elif _hash(x, y, 81) % 11 == 0:
				shade = shade.darkened(0.10)
			_px(tile, x, y, shade)
	if part == "top":
		var cap: Color = SHINGLE.darkened(0.18)
		_rect(tile, Rect2i(0, 0, T, 4), cap)
		_rect(tile, Rect2i(0, 0, T, 1), SHINGLE.darkened(0.55))
		_rect(tile, Rect2i(0, 1, T, 1), cap.lightened(0.22))
		_rect(tile, Rect2i(0, 4, T, 1), SHINGLE.darkened(0.5))
		for x: int in range(3, T, 8):
			_px(tile, x, 2, Color(0.30, 0.30, 0.34))
	elif part == "eave":
		for x: int in T:
			var ends: int = 12 + (1 if posmod(x + 2, 4) < 2 else 0)
			_px(tile, x, ends - 1, SHINGLE.lightened(0.22))
			for y: int in range(ends, T):
				_px(tile, x, y, EAVE_SHADOW)


## Green boards (the big barn's roof): upright boards four pixels wide, each with a lit edge
## and a standing seam, crossed by the faint line of the battens under them. `part` "top" adds
## a ridge of flashing, "eave" a lit edge over the shadow the eaves cast.
func _green_boards(tile: Vector2i, part: String) -> void:
	for y: int in T:
		for x: int in T:
			var shade: Color = ROOF_GREEN
			if x % 4 == 3:
				shade = ROOF_GREEN.darkened(0.42)
			elif x % 4 == 0:
				shade = ROOF_GREEN.lightened(0.18)
			elif y % 8 == 6:
				shade = ROOF_GREEN.darkened(0.12)
			elif _hash(x, y, 87) % 13 == 0:
				shade = ROOF_GREEN.darkened(0.08)
			_px(tile, x, y, shade)
	if part == "top":
		var flashing: Color = ROOF_GREEN.darkened(0.25)
		_rect(tile, Rect2i(0, 0, T, 4), flashing)
		_rect(tile, Rect2i(0, 0, T, 1), ROOF_GREEN.darkened(0.6))
		_rect(tile, Rect2i(0, 1, T, 1), flashing.lightened(0.3))
		_rect(tile, Rect2i(0, 4, T, 1), ROOF_GREEN.darkened(0.55))
	elif part == "eave":
		_rect(tile, Rect2i(0, 12, T, 1), ROOF_GREEN.lightened(0.3))
		_rect(tile, Rect2i(0, 13, T, 3), EAVE_SHADOW)


## A rack of tools on the shed's wall: a plank on two brackets with a rake, a spade and a
## saw hung from its pegs, over the wooden floor.
func _tool_rack(tile: Vector2i) -> void:
	_art(tile, PROP_PALETTES["furniture"].merged({"m": Color(0.84, 0.86, 0.90), "M": Color(0.56, 0.58, 0.64)}), [
		"................",
		".oooooooooooooo.",
		".owwwwwwwwwwwwo.",
		".oLLLLLLLLLLLLo.",
		".oooooooooooooo.",
		"...ow....ow..o..",
		"...ow....ow.oLLo",
		"...ow....ow.omMo",
		"...ow....ow.omMo",
		"...ow...ommmomMo",
		"ooooooo.omMmomMo",
		"ommmmmo.omMmomMo",
		"om.m.mo..omo.oo.",
		".o.o.o....o.....",
		"................",
		"..ssssssssssss..",
	])


## Sacks of grain on a crate, against the shed's wall, over the wooden floor.
func _sacks(tile: Vector2i) -> void:
	_art(tile, PROP_PALETTES["furniture"].merged({"k": Color(0.86, 0.76, 0.56), "K": Color(0.68, 0.58, 0.40)}), [
		"....oo....oo....",
		"...okko..okko...",
		"..okkkkooKkkko..",
		"..okkkkkoKkkko..",
		".okkkkKkoKkkkko.",
		".okkkkKkoKkkKko.",
		".oKkkkKkoKkkKko.",
		".oKKKKKoooKKKKo.",
		".oooooooooooooo.",
		".owwwwwwwwwwwwo.",
		".oLLLWLLLLWLLLo.",
		".oLLLWLLLLWLLLo.",
		".oLLLWLLLLWLLLo.",
		".oWWWWWWWWWWWWo.",
		".oooooooooooooo.",
		"..ssssssssssss..",
	])


## A gable's barge board down a roof tile's outer edge (`left`: its left edge). Over the
## eaves it stops where the roof does.
func _barge_board(tile: Vector2i, left: bool, part: String) -> void:
	var rows: int = 13 if part == "eave" else T
	var shades: Array[Color] = [OUTLINE, TIMBER.lightened(0.3), TIMBER]
	for i: int in shades.size():
		_rect(tile, Rect2i(i if left else T - 1 - i, 0, 1, rows), shades[i])
	if part == "top":
		_rect(tile, Rect2i(0 if left else T - 3, 0, 3, 1), OUTLINE)


## A lancet window of stained glass in the chapel's stone.
func _chapel_window(tile: Vector2i) -> void:
	_stone(tile)
	for y: int in range(1, 15):
		# A pointed arch: narrow at the top, three pixels either side of the middle below.
		var half: int = clampi(y - 1, 0, 3)
		for x: int in range(8 - half - 1, 8 + half + 1):
			var frame: bool = y == 1 or y == 14 or x == 8 - half - 1 or x == 8 + half
			if frame:
				_px(tile, x, y, OUTLINE)
			elif y % 4 == 1:
				_px(tile, x, y, Color(0.20, 0.22, 0.30))
			elif y < 5:
				_px(tile, x, y, Color(0.95, 0.80, 0.35))
			else:
				@warning_ignore("integer_division")
				var red: bool = ((x - 5) / 3 + y / 4) % 2 == 0
				_px(tile, x, y, Color(0.80, 0.24, 0.26) if red else Color(0.28, 0.46, 0.82))
	_px(tile, 7, 6, Color(1.0, 0.86, 0.86))


## One leaf of the chapel's arched double door (`left`: the left leaf): planks, long iron
## hinges and a ring, set into the stone.
func _chapel_door(tile: Vector2i, left: bool) -> void:
	_stone(tile)
	var wood: Color = Color(0.40, 0.24, 0.12)
	var iron: Color = Color(0.24, 0.25, 0.29)
	# How far in from the leaf's outer edge the door starts on each row: the arch.
	var arch: Array[int] = [16, 8, 6, 4, 3, 2, 2]
	for y: int in T:
		var starts: int = arch[y] if y < arch.size() else 2
		for from_outer: int in T:
			var x: int = from_outer if left else T - 1 - from_outer
			if from_outer < starts:
				var above_door: bool = y + 1 < T and from_outer >= (arch[y + 1] if y + 1 < arch.size() else 2)
				if from_outer == starts - 1 or above_door:
					_px(tile, x, y, OUTLINE)
				continue
			var shade: Color = wood
			if from_outer == T - 1:
				shade = wood.darkened(0.5)
			elif from_outer % 4 == 1:
				shade = wood.darkened(0.28)
			elif (y == 8 or y == 13) and from_outer < 11:
				shade = iron
			_px(tile, x, y, shade)
	var ring: int = T - 3 if left else 2
	_px(tile, ring, 10, Color(0.92, 0.80, 0.36))
	_px(tile, ring, 11, Color(0.66, 0.52, 0.20))


## A stone chimney, see-through around it, to stand on a roof (the Decor layer).
func _chimney(tile: Vector2i) -> void:
	var stone: Color = Color(0.60, 0.58, 0.57)
	_rect(tile, Rect2i(13, 6, 2, 9), SHADOW)
	_rect(tile, Rect2i(4, 4, 9, 11), OUTLINE)
	_rect(tile, Rect2i(5, 5, 7, 9), stone)
	_rect(tile, Rect2i(10, 5, 2, 9), stone.darkened(0.2))
	for y: int in [7, 10]:
		_rect(tile, Rect2i(5, y, 7, 1), stone.darkened(0.32))
	for joint: Vector2i in [Vector2i(8, 5), Vector2i(8, 6), Vector2i(6, 8), Vector2i(6, 9), Vector2i(9, 11), Vector2i(9, 12)]:
		_px(tile, joint.x, joint.y, stone.darkened(0.32))
	_rect(tile, Rect2i(3, 1, 11, 4), OUTLINE)
	_rect(tile, Rect2i(4, 2, 9, 2), stone.lightened(0.18))
	_rect(tile, Rect2i(6, 2, 5, 1), Color(0.08, 0.06, 0.06))


## Half of the stone cross on the chapel's ridge (`left`: the half left of the seam between
## the two tiles it stands across), for the Decor layer.
func _cross(tile: Vector2i, left: bool) -> void:
	var stone: Color = Color(0.84, 0.82, 0.78)
	for y: int in T:
		for from_seam: int in 6:
			var x: int = T - 1 - from_seam if left else from_seam
			if _in_cross(from_seam, y):
				_px(tile, x, y, stone if left else stone.darkened(0.14))
			elif _in_cross(from_seam - 1, y) or _in_cross(from_seam, y - 1) or _in_cross(from_seam, y + 1) or _in_cross(from_seam + 1, y):
				_px(tile, x, y, OUTLINE)


## Whether the cross covers the pixel `from_seam` in from the middle seam, on row `y`.
func _in_cross(from_seam: int, y: int) -> bool:
	# One pixel past the seam is the other half's first pixel: the cross is the same both sides.
	var d: int = maxi(from_seam, 0)
	return (d == 0 and y >= 2 and y <= 13) or (d <= 3 and y >= 5 and y <= 6) or (d <= 1 and y >= 12 and y <= 13)


## A shop's hanging sign for the Decor layer: an iron bracket, two chains and a board with a
## bomb painted on it.
func _shop_sign(tile: Vector2i) -> void:
	var iron: Color = Color(0.20, 0.20, 0.24)
	var wood: Color = Color(0.66, 0.46, 0.24)
	_rect(tile, Rect2i(2, 1, 12, 1), iron)
	_px(tile, 2, 2, iron)
	_rect(tile, Rect2i(4, 2, 1, 2), iron)
	_rect(tile, Rect2i(11, 2, 1, 2), iron)
	_rect(tile, Rect2i(2, 4, 12, 9), OUTLINE)
	_rect(tile, Rect2i(3, 5, 10, 7), wood)
	_rect(tile, Rect2i(3, 5, 10, 1), wood.lightened(0.22))
	_ellipse(tile, Vector2(7.5, 9.0), Vector2(2.6, 2.4), Color(0.12, 0.12, 0.16))
	_px(tile, 6, 8, Color(0.55, 0.56, 0.66))
	_px(tile, 9, 6, Color(0.86, 0.76, 0.52))
	_px(tile, 10, 5, Color(1.0, 0.86, 0.30))


## One frame of chimney smoke for the Decor layer: puffs four pixels apart that each rise a
## pixel a frame, growing and thinning as they go, so SMOKE_FRAMES frames loop without a jump.
func _smoke(tile: Vector2i, frame: int) -> void:
	for puff: int in 4:
		var y: float = 14.0 - 4.0 * puff - frame
		var rise: float = (14.0 - y) / 15.0
		var alpha: float = 0.55 * (1.0 - rise)
		if alpha <= 0.03:
			continue
		var center: Vector2 = Vector2(7.5 + rise * 3.0 + sin(y * 0.9) * rise * 1.5, y + 0.5)
		var radius: float = 1.4 + rise * 2.2
		for py: int in T:
			for px: int in T:
				if Vector2(px + 0.5, py + 0.5).distance_to(center) <= radius:
					_px(tile, px, py, Color(0.93, 0.93, 0.96, alpha))


# --- More trees (art pass 2) --------------------------------------------------------------------

## A pine, see-through around it: three tiers of dark needles, lit from the left, on a short
## trunk.
func _pine_art(tile: Vector2i) -> void:
	var dark: Color = Color(0.06, 0.24, 0.22)
	var mid: Color = Color(0.13, 0.39, 0.24)
	var light: Color = Color(0.32, 0.58, 0.28)
	_ellipse(tile, Vector2(8.5, 14.2), Vector2(5.5, 1.8), SHADOW)
	_rect(tile, Rect2i(6, 11, 4, 4), OUTLINE)
	_rect(tile, Rect2i(7, 11, 2, 3), Color(0.40, 0.25, 0.14))
	# Each tier: its top row, its bottom row and its half width at the bottom.
	for tier: Vector3 in [Vector3(8, 13, 6.5), Vector3(4, 10, 5.2), Vector3(0, 6, 3.8)]:
		var top: int = int(tier.x)
		var bottom: int = int(tier.y)
		for y: int in range(top, bottom + 2):
			for x: int in T:
				var half: float = tier.z * (y - top + 1) / (bottom - top + 1)
				var off: float = absf(x + 0.5 - 8.0)
				if y <= bottom and off <= half:
					var shade: Color = mid
					if y == bottom:
						shade = dark
					elif x + 0.5 < 8.0 - half * 0.25:
						shade = light
					elif x + 0.5 > 8.0 + half * 0.4:
						shade = dark
					_px(tile, x, y, shade)
				elif off <= half + 1.0 and y <= bottom + 1 and (y > bottom or off > half):
					_px(tile, x, y, OUTLINE)


## A broad oak, see-through around it: a wide, warm green crown that nearly fills its tile.
func _oak_art(tile: Vector2i) -> void:
	var dark: Color = Color(0.14, 0.34, 0.16)
	var mid: Color = Color(0.30, 0.53, 0.16)
	var light: Color = Color(0.58, 0.74, 0.24)
	_ellipse(tile, Vector2(8.5, 14.2), Vector2(7.0, 2.0), SHADOW)
	_rect(tile, Rect2i(6, 11, 4, 4), OUTLINE)
	_rect(tile, Rect2i(7, 11, 2, 3), Color(0.44, 0.28, 0.15))
	var lobes: Array[Vector3] = [
		Vector3(4.2, 6.6, 3.8), Vector3(11.8, 6.6, 3.8), Vector3(8.0, 3.8, 4.4), Vector3(8.0, 8.8, 4.8),
		Vector3(4.6, 9.8, 3.0), Vector3(11.4, 9.8, 3.0),
	]
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
				if x + y < 12:
					shade = light
				elif x - y > 5 or y > 10:
					shade = dark
				var n: int = _hash(x, y, 81) % 8
				if n == 0:
					shade = shade.darkened(0.22)
				elif n == 1:
					shade = shade.lightened(0.16)
				_px(tile, x, y, shade)
			elif edge:
				_px(tile, x, y, OUTLINE)


## The closed canopy of a thick wood, seen from above: crowns crowding together, each lit from
## the top left, with dark gaps between. It fills its tile and tiles seamlessly.
func _canopy(tile: Vector2i) -> void:
	var gap: Color = Color(0.05, 0.15, 0.13)
	var dark: Color = Color(0.09, 0.29, 0.20)
	var mid: Color = Color(0.18, 0.43, 0.18)
	var light: Color = Color(0.42, 0.63, 0.23)
	var crowns: Array[Vector3] = [Vector3(3, 3, 4.4), Vector3(11, 4, 4.6), Vector3(7, 10, 4.8), Vector3(14.5, 11.5, 4.2), Vector3(1.5, 12.5, 3.6)]
	for y: int in T:
		for x: int in T:
			var shade: Color = gap
			var best: float = 2.0
			for crown: Vector3 in crowns:
				# Distances wrap round the tile, so crowns run on into the next tile.
				var dx: float = fposmod(x + 0.5 - crown.x + 8.0, 16.0) - 8.0
				var dy: float = fposmod(y + 0.5 - crown.y + 8.0, 16.0) - 8.0
				var d: float = Vector2(dx, dy).length() / crown.z
				if d < best and d <= 1.0:
					best = d
					shade = mid
					if dx + dy < -crown.z * 0.5:
						shade = light
					elif dx + dy > crown.z * 0.7 or d > 0.86:
						shade = dark
			if best <= 1.0:
				var n: int = _hash(x, y, 83) % 9
				if n == 0:
					shade = shade.darkened(0.2)
				elif n == 1:
					shade = shade.lightened(0.14)
			_px(tile, x, y, shade)


# --- Pits (H14) -----------------------------------------------------------------------------------

## A pit: blackness. With `top`, its far wall shows along the top edge, running down into the
## dark (the baker uses that one for the top row of a pit).
func _pit(tile: Vector2i, top: bool) -> void:
	var dark: Color = Color(0.03, 0.02, 0.05)
	_fill(tile, dark)
	for y: int in T:
		for x: int in T:
			if _hash(x, y, 91) % 29 == 0:
				_px(tile, x, y, dark.lightened(0.05))
	if not top:
		return
	var stone: Color = Color(0.30, 0.31, 0.36)
	for y: int in 8:
		for x: int in T:
			var joint: bool = y == 3 or (x + (4 if y > 3 else 0)) % 8 == 7
			_px(tile, x, y, stone.darkened(minf(0.30 + y * 0.085 + (0.14 if joint else 0.0), 0.97)))
	_rect(tile, Rect2i(0, 0, T, 1), OUTLINE)


# --- The marsh (Willowmere, 2026-11-17) --------------------------------------------------

const MARSH_GROUND: Color = Color(0.31, 0.45, 0.29)
const MARSH_MOSS: Color = Color(0.50, 0.63, 0.28)
const MARSH_DAMP: Color = Color(0.21, 0.33, 0.27)
const PLANK: Color = Color(0.57, 0.47, 0.36)
const REED: Array[Color] = [Color(0.15, 0.29, 0.20), Color(0.23, 0.41, 0.24), Color(0.35, 0.53, 0.27), Color(0.53, 0.65, 0.33)]
const REED_HEAD: Color = Color(0.42, 0.27, 0.16)
const WATER_DEEP: Color = Color(0.17, 0.48, 0.72)


## The marsh's ground: damp earth under moss, darker and cooler than the meadow, with brighter
## cushions of moss and a wet glint here and there. Seamless.
func _marsh(tile: Vector2i) -> void:
	_fill(tile, MARSH_GROUND)
	for y: int in T:
		for x: int in T:
			var n: int = _hash(x, y, 201) % 100
			if n < 12:
				_px(tile, x, y, MARSH_GROUND.lerp(MARSH_DAMP, 0.6))
			elif n < 19:
				_px(tile, x, y, MARSH_GROUND.lerp(MARSH_MOSS, 0.45))
	# Cushions of moss: a few soft blobs, lit from the top left.
	for i: int in 3:
		var cx: int = 2 + _hash(i, 3, 203) % (T - 5)
		var cy: int = 2 + _hash(i, 5, 207) % (T - 5)
		_px(tile, cx, cy, MARSH_MOSS)
		_px(tile, cx + 1, cy, MARSH_MOSS.darkened(0.12))
		_px(tile, cx, cy + 1, MARSH_MOSS.darkened(0.12))
		_px(tile, cx + 1, cy + 1, MARSH_DAMP)
	# A wet glint.
	var gx: int = 1 + _hash(2, 9, 211) % (T - 3)
	var gy: int = 1 + _hash(7, 4, 213) % (T - 3)
	_px(tile, gx, gy, Color(0.45, 0.62, 0.66))
	_px(tile, gx + 1, gy, MARSH_DAMP)


## A boardwalk over the water: weathered planks side by side, each its own shade, lit along
## one edge and dark along the other where the next plank begins, with a nail at each end and a
## little moss. `across` planks lie north to south (a walk running east to west); otherwise
## they lie east to west.
func _boardwalk(tile: Vector2i, across: bool) -> void:
	for plank: int in 4:
		var tone: float = float(_hash(plank, 1, 221 if across else 227) % 5) * 0.035 - 0.07
		var wood: Color = PLANK.lightened(tone) if tone > 0.0 else PLANK.darkened(-tone)
		for along: int in T:
			for step: int in 4:
				var across_at: int = plank * 4 + step
				var x: int = across_at if across else along
				var y: int = along if across else across_at
				var shade: Color = wood
				if step == 0:
					shade = wood.lightened(0.10)
				elif step == 3:
					shade = wood.darkened(0.42)
				elif _hash(x, y, 229) % 11 == 0:
					shade = shade.darkened(0.10)
				_px(tile, x, y, shade)
		# Nails near each end of the plank, and a tuft of moss on some.
		for end: int in [1, T - 2]:
			var nx: int = plank * 4 + 1 if across else end
			var ny: int = end if across else plank * 4 + 1
			_px(tile, nx, ny, Color(0.26, 0.22, 0.22))
		if _hash(plank, 4, 233) % 3 == 0:
			var along_at: int = 4 + _hash(plank, 6, 239) % 8
			var mx: int = plank * 4 + 1 if across else along_at
			var my: int = along_at if across else plank * 4 + 1
			_px(tile, mx, my, MARSH_MOSS.darkened(0.1))


## Planks laid on the ground (a decoration, for the Decor layer: it covers the grass under it
## and nothing reads it for movement): the boardwalk's planks, on land.
func _planks(tile: Vector2i) -> void:
	_boardwalk(tile, true)


## Deep reeds standing in the water, too thick to push through: a dark stand behind and a
## brighter one in front, every blade its own height, with brown heads on a few. `variant`
## picks another stand.
func _reeds(tile: Vector2i, variant: int) -> void:
	_fill(tile, WATER_DEEP.darkened(0.55))
	for x: int in T:
		var roll: int = _hash(x, 3, 251 + variant * 7)
		# The stand behind: nearly every column, from the top of the cell.
		var back_top: int = 0 if roll % 3 != 0 else 1 + (roll >> 2) % 3
		for y: int in range(back_top, T):
			_px(tile, x, y, REED[0] if (x + y + variant) % 5 != 0 else REED[1])
		# The stand in front: most columns, shorter, brighter, darker at the foot.
		if (roll >> 5) % 4 == 0:
			continue
		var top: int = 4 + (roll >> 7) % 7
		var shade: int = 1 + (roll >> 10) % 2
		for y: int in range(top, T):
			var blade: Color = REED[shade]
			if y == top:
				blade = REED[3]
			elif y >= T - 2:
				blade = REED[shade - 1]
			_px(tile, x, y, blade)
		# A cattail's brown head on a few.
		if (roll >> 12) % 5 == 0:
			for y: int in range(top - 3, top):
				_px(tile, x, maxi(y, 0), REED_HEAD if y > top - 3 else REED_HEAD.lightened(0.15))


## The ruined hut's front wall: grey planks standing on end, weathered, the tops broken off at
## different heights with the dark of the inside behind them, and moss creeping up from the ground.
func _ruin_wall(tile: Vector2i) -> void:
	var dark: Color = Color(0.13, 0.11, 0.13)
	var board: Color = Color(0.46, 0.42, 0.38)
	_fill(tile, dark)
	for plank: int in 4:
		var top: int = _hash(plank, 2, 261) % 6
		var tone: float = float(_hash(plank, 3, 263) % 4) * 0.04
		for y: int in range(top, T):
			for step: int in 4:
				var x: int = plank * 4 + step
				var shade: Color = board.darkened(tone)
				if step == 0:
					shade = shade.lightened(0.12)
				elif step == 3:
					shade = dark.lerp(board, 0.25)
				if y == top:
					shade = shade.lightened(0.18)
				if _hash(x, y, 267) % 9 == 0:
					shade = shade.darkened(0.14)
				_px(tile, x, y, shade)
	# A gap where a board has gone, and moss along the foot.
	_rect(tile, Rect2i(8, 6, 3, 7), dark)
	for x: int in T:
		var up: int = _hash(x, 1, 269) % 3
		for y: int in range(T - 1 - up, T):
			_px(tile, x, y, MARSH_MOSS.darkened(0.15 if y == T - 1 else 0.0))


## The ruined hut from above: what is left of a thatched roof, fallen in. Grey old thatch, a
## rafter lying across, and moss. Seamless enough to stand in a block; the holes through it are
## a decoration laid over a cell or two (_ruin_hole), so a roof isn't the same hole repeated.
func _ruin_top(tile: Vector2i) -> void:
	var thatch: Color = Color(0.52, 0.47, 0.34)
	_fill(tile, thatch)
	for y: int in T:
		for x: int in T:
			var n: int = _hash(x, y, 271) % 100
			if n < 16:
				_px(tile, x, y, thatch.darkened(0.20))
			elif n < 24:
				_px(tile, x, y, thatch.lightened(0.12))
			elif n < 30:
				_px(tile, x, y, MARSH_MOSS.darkened(0.2))
	# Straw lies in short strokes down the slope.
	for i: int in 9:
		var sx: int = _hash(i, 1, 273) % T
		var sy: int = _hash(i, 2, 277) % (T - 3)
		for d: int in 3:
			_px(tile, sx, sy + d, thatch.darkened(0.30))
	# A rafter lying across.
	for x: int in T:
		var ry: int = 13 + (1 if x > 9 else 0)
		_px(tile, x, ry, Color(0.34, 0.25, 0.18))
		_px(tile, x, ry + 1, Color(0.22, 0.16, 0.13))


## A hole through the hut's fallen roof (a decoration over "ruin_top"): the dark of the inside,
## a lit lip of thatch below it, and the broken end of a rafter poking out.
func _ruin_hole(tile: Vector2i) -> void:
	var dark: Color = Color(0.13, 0.11, 0.13)
	var thatch: Color = Color(0.52, 0.47, 0.34)
	_ellipse(tile, Vector2(8, 7.5), Vector2(5.6, 4.2), dark)
	_ellipse(tile, Vector2(4, 5), Vector2(2.2, 1.8), dark)
	for x: int in range(4, 13):
		_px(tile, x, 12 if x > 5 and x < 11 else 11, thatch.lightened(0.22))
	for step: int in 5:
		_px(tile, 9 + step, 4 + step, Color(0.34, 0.25, 0.18))
		_px(tile, 9 + step, 5 + step, Color(0.22, 0.16, 0.13))


## Cattails at the water's edge (a decoration): three stalks, two with their brown heads, and a
## blade leaning out.
func _cattail(tile: Vector2i) -> void:
	for stalk: Vector3i in [Vector3i(4, 3, 1), Vector3i(8, 1, 1), Vector3i(12, 5, 0)]:
		for y: int in range(stalk.y, T - 1):
			_px(tile, stalk.x, y, REED[1] if y % 3 != 0 else REED[2])
		_px(tile, stalk.x, T - 1, REED[0])
		if stalk.z == 1:
			for y: int in range(stalk.y + 1, stalk.y + 5):
				_px(tile, stalk.x, y, REED_HEAD)
				_px(tile, stalk.x + 1, y, REED_HEAD.darkened(0.2))
			_px(tile, stalk.x, stalk.y, REED[3])
	# A blade leaning to the right.
	for step: int in 6:
		_px(tile, 9 + step, 13 - step, REED[2] if step < 4 else REED[3])
	for step: int in 4:
		_px(tile, 3 - mini(step, 2), 12 - step, REED[1])


## A patch of moss on the ground (a decoration): two bright cushions with a dark underside.
func _moss(tile: Vector2i) -> void:
	for pad: Vector3 in [Vector3(5, 9, 3.4), Vector3(11, 6, 2.6)]:
		_ellipse(tile, Vector2(pad.x, pad.y + 0.8), Vector2(pad.z, pad.z * 0.7), MARSH_DAMP)
		_ellipse(tile, Vector2(pad.x, pad.y), Vector2(pad.z, pad.z * 0.7), MARSH_MOSS.darkened(0.08))
		_ellipse(tile, Vector2(pad.x - 0.8, pad.y - 0.6), Vector2(pad.z * 0.55, pad.z * 0.4), MARSH_MOSS.lightened(0.14))


## A weeping willow, small, for the Decor layer's tile (Scenery stands the tall one up in its
## place when the area loads).
func _willow_art(tile: Vector2i) -> void:
	var leaf: Array[Color] = [Color(0.17, 0.33, 0.22), Color(0.30, 0.48, 0.26), Color(0.48, 0.62, 0.30), Color(0.66, 0.74, 0.40)]
	_ellipse(tile, Vector2(8, 15), Vector2(6, 1.6), SHADOW)
	_rect(tile, Rect2i(7, 9, 2, 6), Color(0.30, 0.22, 0.17))
	_ellipse(tile, Vector2(8, 5), Vector2(7, 4.5), leaf[1])
	_ellipse(tile, Vector2(7, 4), Vector2(5, 3), leaf[2])
	for x: int in range(1, T - 1):
		var drop: int = 7 + _hash(x, 1, 281) % 6
		for y: int in range(5, drop):
			_px(tile, x, y, leaf[(x + y) % 3])
		_px(tile, x, drop, leaf[0])
	_px(tile, 6, 3, leaf[3])
	_px(tile, 5, 4, leaf[3])


## The marsh's two props, as PROP_ART is written: "." clear, "o" outline, the rest from the
## palette beside it.
const MARSH_ROCK_PALETTE: Dictionary = {"g": Color(0.50, 0.53, 0.52), "G": Color(0.34, 0.37, 0.40), "l": Color(0.68, 0.71, 0.68), "m": Color(0.42, 0.58, 0.28), "M": Color(0.58, 0.70, 0.32), "s": Color(0.00, 0.00, 0.00, 0.25)}
const MARSH_ROCK_ART: Array[String] = [
	"................",
	"................",
	"................",
	"................",
	".....ooooo......",
	"....oMMmmmo.....",
	"...oMmmlggGo....",
	"..oMmlggggGGo...",
	"..omlgggggmGo...",
	".olggggmgggGGo..",
	".olgggggggmGGo..",
	".olGgggmggGGGo..",
	".oGGGGmmGGGGGo..",
	"..ooooooooooo...",
	"...sssssssss....",
	"................",
]
## A lantern on a crooked post, its glass dark: Henrik's favour lights them (step 3).
const MARSH_LANTERN_PALETTE: Dictionary = {"w": Color(0.48, 0.38, 0.28), "W": Color(0.32, 0.24, 0.18), "i": Color(0.30, 0.30, 0.36), "d": Color(0.16, 0.20, 0.28), "D": Color(0.34, 0.42, 0.52), "s": Color(0.00, 0.00, 0.00, 0.25)}
## The same post with its lantern burning: only the glass differs.
const MARSH_LANTERN_LIT_PALETTE: Dictionary = {"w": Color(0.48, 0.38, 0.28), "W": Color(0.32, 0.24, 0.18), "i": Color(0.30, 0.30, 0.36), "d": Color(1.00, 0.88, 0.45), "D": Color(1.00, 0.97, 0.75), "s": Color(0.00, 0.00, 0.00, 0.25)}
const MARSH_LANTERN_ART: Array[String] = [
	"................",
	"....ooooooo.....",
	"...owwwwwwWo....",
	"...owWoooiio....",
	"...owo..oiio....",
	"...owo.oiiiio...",
	"...owo.oiDdio...",
	"...owo.oiddio...",
	"...owo.oiiiio...",
	"...owo..oooo....",
	"...owo..........",
	"...owo..........",
	"...owo..........",
	"..owWwo.........",
	"..oooooo........",
	"...ssss.........",
]


## Paints `rows` onto `tile` from `palette`, as _ascii() does for PROP_ART.
# --- The Old Quarry (2026-11-17) -----------------------------------------------------------

const CAVE_EARTH: Color = Color(0.37, 0.32, 0.28)
const CAVE_ROCK: Color = Color(0.21, 0.19, 0.20)
const CAVE_FACE: Color = Color(0.34, 0.30, 0.29)
const QUARRY_STONE: Color = Color(0.57, 0.53, 0.48)
const TIMBER_WOOD: Color = Color(0.50, 0.37, 0.24)
const RAIL_IRON: Color = Color(0.46, 0.46, 0.50)


## Packed earth underfoot: warm and dull, with grit and the odd small stone, so that rocks
## and ore stand out on it.
func _cave_floor(tile: Vector2i) -> void:
	_fill(tile, CAVE_EARTH)
	for y: int in T:
		for x: int in T:
			var roll: int = _hash(x, y, 71) % 23
			if roll == 0:
				_px(tile, x, y, CAVE_EARTH.darkened(0.22))
			elif roll == 1:
				_px(tile, x, y, CAVE_EARTH.lightened(0.10))
			elif roll == 2 and _hash(x + 1, y, 71) % 23 != 2:
				_px(tile, x, y, CAVE_EARTH.darkened(0.12))
	for stone: Vector2i in [Vector2i(3, 4), Vector2i(11, 10)]:
		_px(tile, stone.x, stone.y, CAVE_EARTH.lightened(0.22))
		_px(tile, stone.x + 1, stone.y, CAVE_EARTH.lightened(0.12))
		_px(tile, stone.x, stone.y + 1, CAVE_EARTH.darkened(0.25))
		_px(tile, stone.x + 1, stone.y + 1, CAVE_EARTH.darkened(0.25))


## Living rock seen from above: dark, in rough slabs with paler broken edges.
func _cave_wall(tile: Vector2i) -> void:
	_fill(tile, CAVE_ROCK)
	for y: int in T:
		for x: int in T:
			var slab: int = _hash(x >> 2, y >> 2, 43) % 5
			var color: Color = CAVE_ROCK.lightened(0.05 * slab)
			if _hash(x, y, 47) % 19 == 0:
				color = color.darkened(0.35)
			_px(tile, x, y, color)
	for crack: Vector2i in [Vector2i(2, 3), Vector2i(3, 4), Vector2i(4, 4), Vector2i(10, 11), Vector2i(11, 12), Vector2i(12, 12), Vector2i(13, 13)]:
		_px(tile, crack.x, crack.y, CAVE_ROCK.darkened(0.5))
		_px(tile, crack.x, crack.y - 1, CAVE_ROCK.lightened(0.16))


## The same rock where it stands over the floor: a lit lip along the top, a face of broken
## strata under it, and the dark where it meets the ground.
func _cave_wall_face(tile: Vector2i) -> void:
	_fill(tile, CAVE_FACE)
	for y: int in T:
		for x: int in T:
			var color: Color = CAVE_FACE.darkened(0.05 * (y >> 2))
			var strata: int = _hash(x >> 1, y >> 2, 53) % 7
			if strata == 0:
				color = color.lightened(0.10)
			elif strata == 1:
				color = color.darkened(0.16)
			if _hash(x, y, 59) % 29 == 0:
				color = color.darkened(0.3)
			_px(tile, x, y, color)
	_rect(tile, Rect2i(0, 0, T, 2), CAVE_ROCK.lightened(0.10))
	_rect(tile, Rect2i(0, 2, T, 1), CAVE_FACE.lightened(0.24))
	_rect(tile, Rect2i(0, T - 2, T, 2), CAVE_FACE.darkened(0.42))
	for x: int in [4, 5, 11]:
		_rect(tile, Rect2i(x, 5, 1, 7), CAVE_FACE.darkened(0.36))


## The outcrop in the North Fields: weathered stone in the light, paler than the cave's, with
## a little grass in its cracks.
func _quarry_rock(tile: Vector2i) -> void:
	_fill(tile, QUARRY_STONE)
	for y: int in T:
		for x: int in T:
			var slab: int = _hash(x >> 2, y >> 2, 61) % 4
			var color: Color = QUARRY_STONE.darkened(0.06 * slab)
			if _hash(x, y, 67) % 17 == 0:
				color = color.lightened(0.14)
			_px(tile, x, y, color)
	for crack: Vector2i in [Vector2i(3, 5), Vector2i(4, 6), Vector2i(5, 6), Vector2i(9, 2), Vector2i(10, 3), Vector2i(11, 12), Vector2i(12, 13), Vector2i(6, 12)]:
		_px(tile, crack.x, crack.y, QUARRY_STONE.darkened(0.45))
	for tuft: Vector2i in [Vector2i(4, 7), Vector2i(12, 14)]:
		_px(tile, tuft.x, tuft.y, GreyboxTiles.GROUND_COLORS[1])
		_px(tile, tuft.x + 1, tuft.y - 1, GreyboxTiles.GROUND_COLORS[0])
	_rect(tile, Rect2i(0, T - 1, T, 1), QUARRY_STONE.darkened(0.30))


## The cut into the hillside: trodden earth going dark, old rails running in, and a timber
## beam along each side.
func _mine_mouth(tile: Vector2i) -> void:
	_fill(tile, CAVE_EARTH.darkened(0.62))
	for y: int in T:
		for x: int in T:
			if _hash(x, y, 73) % 13 == 0:
				_px(tile, x, y, CAVE_EARTH.darkened(0.74))
	_rails_on(tile)
	for beam: int in [0, T - 3]:
		_rect(tile, Rect2i(0, beam, T, 3), TIMBER_WOOD.darkened(0.25))
		_rect(tile, Rect2i(0, beam, T, 1), TIMBER_WOOD.lightened(0.12))
		_px(tile, 5, beam + 1, TIMBER_WOOD.darkened(0.5))
		_px(tile, 12, beam + 1, TIMBER_WOOD.darkened(0.5))


## A ladder up the rock: a dark shaft in the wall's face and the rungs climbing into it.
func _ladder_up(tile: Vector2i) -> void:
	_cave_wall_face(tile)
	_rect(tile, Rect2i(3, 1, 10, T - 1), OUTLINE)
	_rect(tile, Rect2i(4, 2, 8, T - 2), Color(0.13, 0.11, 0.13))
	for rail: int in [5, 10]:
		_rect(tile, Rect2i(rail, 1, 1, T - 1), TIMBER_WOOD)
	for rung: int in [3, 6, 9, 12]:
		_rect(tile, Rect2i(6, rung, 4, 1), TIMBER_WOOD.lightened(0.14))
	_rect(tile, Rect2i(5, T - 1, 6, 1), TIMBER_WOOD.darkened(0.2))


## Old rails for the Decor layer: sleepers under two runs of iron, east to west.
func _rails(tile: Vector2i) -> void:
	_rails_on(tile)


func _rails_on(tile: Vector2i) -> void:
	for sleeper: int in [1, 5, 9, 13]:
		_rect(tile, Rect2i(sleeper, 4, 2, 8), TIMBER_WOOD.darkened(0.38))
		_rect(tile, Rect2i(sleeper, 4, 2, 1), TIMBER_WOOD.darkened(0.2))
	for run: int in [5, 10]:
		_rect(tile, Rect2i(0, run, T, 1), RAIL_IRON)
		_rect(tile, Rect2i(0, run + 1, T, 1), RAIL_IRON.darkened(0.45))


## Broken stone lying about, for the Decor layer.
func _rubble(tile: Vector2i) -> void:
	for stone: Vector3 in [Vector3(4, 5, 2.2), Vector3(10.5, 9, 2.6), Vector3(6, 12, 1.6), Vector3(12.5, 4, 1.4)]:
		_ellipse(tile, Vector2(stone.x, stone.y + 0.8), Vector2(stone.z, stone.z * 0.7), OUTLINE)
		_ellipse(tile, Vector2(stone.x, stone.y), Vector2(stone.z, stone.z * 0.7), Color(0.47, 0.44, 0.43))
		_px(tile, int(stone.x) - 1, int(stone.y) - 1, Color(0.66, 0.63, 0.60))


## A vein of crystal in the rock, for the Decor layer: three pale shards.
func _crystal_vein(tile: Vector2i) -> void:
	var shards: Array = [[Vector2i(4, 9), 5, Color(0.62, 0.86, 0.95)], [Vector2i(8, 7), 7, Color(0.80, 0.74, 0.98)], [Vector2i(12, 10), 4, Color(0.66, 0.92, 0.88)]]
	for shard: Array in shards:
		var foot: Vector2i = shard[0]
		var tall: int = shard[1]
		var color: Color = shard[2]
		for step: int in tall:
			_px(tile, foot.x, foot.y - step, color.darkened(0.25))
			_px(tile, foot.x + 1, foot.y - step, color)
		_px(tile, foot.x + 1, foot.y - tall, color.lightened(0.5))
		_px(tile, foot.x - 1, foot.y, OUTLINE)
		_px(tile, foot.x + 2, foot.y, OUTLINE)


## The quarry's prop, as PROP_ART is written: pit props stacked against the wall.
const TIMBER_PALETTE: Dictionary = {"w": Color(0.52, 0.39, 0.25), "W": Color(0.36, 0.26, 0.17), "l": Color(0.68, 0.54, 0.36), "e": Color(0.74, 0.62, 0.44), "s": Color(0.0, 0.0, 0.0, 0.28)}
const TIMBER_ART: Array[String] = [
	"................",
	"................",
	"....oooooooo....",
	"...oellllllwo...",
	"...oewwwwwwWo...",
	"...oeWWWWWWWo...",
	"..oooooooooooo..",
	".oellllllllllwo.",
	".oewwwwwwwwwwWo.",
	".oeWWWWWWWWWWWo.",
	"oooooooooooooooo",
	"oellllllllllllwo",
	"oewwwwwwwwwwwwWo",
	"oeWWWWWWWWWWWWWo",
	"oooooooooooooooo",
	".ssssssssssssss.",
]


# --- The Homestead's buildings (phase 3) -------------------------------------------------------

## The barn's red: its planks, and the white of its trim.
const BARN_RED: Color = Color(0.64, 0.22, 0.17)
const BARN_TRIM: Color = Color(0.93, 0.90, 0.82)


## A building site: dug, trodden earth with clods, marked out with twine along its top and
## left edges (so a site of many cells reads as a plot pegged out), a peg where they meet.
func _site(tile: Vector2i) -> void:
	var earth: Color = Color(0.58, 0.43, 0.28)
	_fill(tile, earth)
	for y: int in T:
		for x: int in T:
			var n: int = _hash(x, y, 91) % 100
			if n < 10:
				_px(tile, x, y, earth.darkened(0.18))
			elif n < 16:
				_px(tile, x, y, earth.lightened(0.12))
	for clod: Vector2i in [Vector2i(4, 6), Vector2i(10, 11), Vector2i(12, 4), Vector2i(6, 12)]:
		_rect(tile, Rect2i(clod, Vector2i(2, 1)), earth.lightened(0.2))
		_rect(tile, Rect2i(clod + Vector2i(0, 1), Vector2i(2, 1)), earth.darkened(0.3))
	var twine: Color = Color(0.92, 0.86, 0.64)
	_rect(tile, Rect2i(0, 1, T, 1), twine)
	_rect(tile, Rect2i(1, 0, 1, T), twine)
	_rect(tile, Rect2i(0, 0, 3, 3), OUTLINE)
	_px(tile, 1, 1, Color(0.70, 0.50, 0.28))


## A site's stack of timber: three planks laid one on another, their ends showing, with a
## shadow under them, over the dug earth.
func _site_timber(tile: Vector2i) -> void:
	var wood: Color = Color(0.74, 0.54, 0.32)
	_rect(tile, Rect2i(2, 13, 13, 2), SHADOW)
	for plank: int in 3:
		var y: int = 5 + plank * 3
		var x: int = 2 + (plank % 2)
		_rect(tile, Rect2i(x, y, 12, 3), OUTLINE)
		_rect(tile, Rect2i(x + 1, y + 1, 10, 1), wood.lightened(0.1 - plank * 0.05))
		_px(tile, x + 10, y + 1, wood.darkened(0.3))
		_px(tile, x + 4, y + 1, wood.darkened(0.15))


## The barn's wall: upright red planks with dark seams, the shadow of the eaves along the top
## and a stone footing along the bottom, as a house's ground floor has.
func _barn_wall(tile: Vector2i) -> void:
	_fill(tile, BARN_RED)
	for x: int in T:
		var seam: bool = x % 4 == 3
		for y: int in T:
			var shade: Color = BARN_RED.darkened(0.32) if seam else BARN_RED
			if not seam and _hash(x, y, 93) % 9 == 0:
				shade = BARN_RED.darkened(0.1)
			if not seam and x % 4 == 0:
				shade = shade.lightened(0.1)
			_px(tile, x, y, shade)
	_rect(tile, Rect2i(0, 0, T, 2), EAVE_SHADOW)
	var footing: Color = Color(0.52, 0.50, 0.52)
	_rect(tile, Rect2i(0, 13, T, 3), footing.darkened(0.35))
	for x: int in range(0, T, 4):
		_rect(tile, Rect2i(x, 13 + (0 if x % 8 == 0 else 1), 3, 2), footing)


## The barn's loft door: a square hatch framed in white with its cross brace, over the wall.
func _barn_loft(tile: Vector2i) -> void:
	_rect(tile, Rect2i(3, 3, 10, 9), OUTLINE)
	_rect(tile, Rect2i(4, 4, 8, 7), BARN_TRIM)
	_rect(tile, Rect2i(5, 5, 6, 5), BARN_RED.darkened(0.2))
	for i: int in 5:
		_px(tile, 5 + i + (1 if i > 2 else 0), 5 + i, BARN_TRIM)
		_px(tile, 10 - i - (1 if i > 2 else 0), 5 + i, BARN_TRIM)


## The barn's door: tall plank leaves framed in white, a white cross brace over them.
func _barn_door(tile: Vector2i) -> void:
	_rect(tile, Rect2i(1, 2, 14, 14), OUTLINE)
	_rect(tile, Rect2i(2, 3, 12, 13), BARN_TRIM)
	_rect(tile, Rect2i(3, 4, 10, 12), BARN_RED.darkened(0.12))
	_rect(tile, Rect2i(8, 4, 1, 12), BARN_RED.darkened(0.4))
	for i: int in 10:
		_px(tile, 3 + i, 4 + i + (1 if i > 4 else 0), BARN_TRIM)
		_px(tile, 12 - i, 4 + i + (1 if i > 4 else 0), BARN_TRIM)
	_px(tile, 7, 10, Color(0.92, 0.80, 0.36))
	_px(tile, 9, 10, Color(0.92, 0.80, 0.36))


## The silo: a round tower of stone courses under a domed copper cap, with a hatch and two
## iron hoops, two cells by two, painted whole and cut into its quarters.
func _silo(quarters: Array[Vector2i]) -> void:
	var size: int = T * 2
	var art: Image = Image.create(size, size, false, Image.FORMAT_RGBA8)
	art.fill(Color(0, 0, 0, 0))
	var stone: Color = Color(0.66, 0.64, 0.62)
	var cap: Color = Color(0.36, 0.56, 0.52)
	var iron: Color = Color(0.28, 0.28, 0.33)
	for y: int in size:
		for x: int in size:
			var across: float = (float(x) + 0.5 - 16.0) / 13.0
			# The body: x 3..28, from under the cap to the ground, lit from the west.
			if absf(across) <= 1.0 and y >= 9:
				var edge: bool = absf(across) > 0.92 or y == size - 1
				var shade: Color = stone.lightened(0.12 - across * 0.22)
				var course: int = floori(float(y - 9) / 4.0)
				var joint: bool = (y - 9) % 4 == 3 or posmod(x + (course % 2) * 3, 6) == 0
				var c: Color = OUTLINE if edge else (shade.darkened(0.25) if joint else shade)
				if not edge and (y == 15 or y == 26):
					c = iron.lightened(0.25 if across < 0.0 else 0.0)
				art.set_pixel(x, y, c)
			# The cap: a dome over the body, a little wider, with its lit side and seams.
			var dome: Vector2 = Vector2((float(x) + 0.5 - 16.0) / 14.0, (float(y) + 0.5 - 11.0) / 10.0)
			if y <= 11 and dome.length_squared() <= 1.0:
				var rim: bool = dome.length_squared() > 0.82 or y == 11
				var lit: Color = cap.lightened(0.18 - dome.x * 0.3)
				var c2: Color = OUTLINE if rim else (lit.darkened(0.2) if posmod(x, 5) == 0 else lit)
				art.set_pixel(x, y, c2)
	# The finial on top, and the hatch high on its face.
	for p: Vector2i in [Vector2i(15, 0), Vector2i(16, 0), Vector2i(15, 1), Vector2i(16, 1)]:
		art.set_pixel(p.x, p.y, iron)
	for y: int in range(17, 23):
		for x: int in range(13, 19):
			var frame: bool = y == 17 or y == 22 or x == 13 or x == 18
			art.set_pixel(x, y, OUTLINE if frame else Color(0.48, 0.30, 0.16))
	art.set_pixel(17, 20, Color(0.92, 0.80, 0.36))
	var origins: Array[Vector2i] = [Vector2i(0, 0), Vector2i(T, 0), Vector2i(0, T), Vector2i(T, T)]
	for i: int in 4:
		_image.blit_rect(art, Rect2i(origins[i], Vector2i(T, T)), quarters[i] * T)


func _art(tile: Vector2i, palette: Dictionary, rows: Array[String]) -> void:
	for y: int in T:
		for x: int in T:
			var key: String = rows[y][x]
			if key == ".":
				continue
			var color: Color = OUTLINE if key == "o" else palette[key]
			var at: Vector2i = Vector2i(tile.x * T + x, tile.y * T + y)
			_image.set_pixelv(at, _image.get_pixelv(at).blend(color) if color.a < 1.0 else color)
