extends SceneTree
## Fills the Height layer of each greybox area with its layout below. Step 4 of 4 (see
## make_tile_texture.gd). Bakes every area, or just the ones named:
##   godot --headless --path . -s res://tools/greybox/build_maps.gd [-- village ...]
## It OVERWRITES each Height layer, including anything painted in the editor since. The rest
## of each scene is hand-written and kept as it is.
##
## Layout rules the tests check (tests/world/village_test.gd):
## - the north rise is reached by its stairs; the east meadow by the stairs at its south end,
##   and its long west edge is a one-way ledge down to the road;
## - houses, the chapel, the well, the pond and the woods are solid;
## - the south road leaves the map through a gap in the woods;
## - two houses have a door in their front wall (tests/world/doors_test.gd).
## House interiors are 11x9 rooms: log walls, the way out a doormat in the middle of the
## bottom wall at (5, 8).
## The South Field (H3's enemy ground, tests/world/south_field_test.gd): the road from the
## village comes in at the top; slimes in the western meadow; a goblin archer on the eastern
## plateau, reached by its stairs, with a one-way ledge all round; bats in the stone ruin,
## where a stairway leads down to the Ruin Cellar.
## The Ruin Cellar (H5's test dungeon, tests/world/dungeon_test.gd): three 15x11 rooms stacked
## north to south inside thick walls, joined by doorways at x = 7 that its doors close; a
## stairway in the inner room leads down to the Cistern.
## The Cistern (H6's puzzle rooms, tests/world/puzzle_test.gd): five 15x11 rooms on a 2x3 grid,
## (0,2) push block -> (0,1) pressure plate -> (1,1) switch -> (1,0) cracked wall -> (0,0)
## the combined room; the sixth room, (1,2), is a secret behind a cracked wall (H12).
## The Old Keep (H7's dungeon, tests/world/keep_test.gd): ten 15x11 rooms on a 3x4 grid; the
## gate is in the south wall, the way out behind the boss in the north wall of (1,1).
## The Chapel Crypt (H14's dungeon, tests/world/crypt_test.gd): ten 15x11 rooms on a 3x4 grid,
## the keep's shape mirrored; the stairs up to the chapel are in the south wall. Its pits are
## "pit" blocks (the top row of each shows the far wall).
## The countryside (H8, tests/world/countryside_test.gd): the village's north road leads to the
## North Fields (a stream and its bridge, a plateau, a farm plot, a hidden meadow behind a gap in
## the tree line), then the Old Wood (clearings off a winding road, the keep's front and gate,
## and a walled shrine with a cracked wall and a heart piece).

## Each area: scene, size in cells, blocks, and optionally the base kind (default grass).
## Block = [x, y, width, height, terrain height, kind]; kind is "ground", "stairs", "path" (at
## that height) or a fixed-height kind from GreyboxTiles (solid, floor or furniture; the
## height is then ignored). Everything else is the base at height 0. Later blocks win.
## Details come by themselves: a roof block's top row gets a ridge and its bottom row eaves,
## and walls get a window every third cell (doors, laid later, replace them). Trees, rocks,
## fences and the 2x2 "well" become solid ground at the block's height (so they sit on grass of
## any height) with their picture on the Decor layer.
## Grass, pots and critters: "spawns" blocks [x, y, width, height, kind] paint markers on a hidden
## Spawns layer, and the area turns each into its node on load (GreyboxTiles.MARKER_KINDS).
## Optional looks, on the Decor layer (never read for movement):
## - "decor": blocks [x, y, width, height, kind] of GreyboxTiles.DECOR_KINDS;
## - "scatter": { "seed", "kinds": [[kind, percent], ...] } sprinkled over open ground,
##   never on paths, solids, doors, exits, people, items or arrival spots.
const MAPS: Dictionary = {
	"village": {
		"scene": "res://world/areas/village/village.tscn",
		"size": Vector2i(48, 36),
		"blocks": [
			# The north rise, wooded along the top, with the old chapel on it.
			[0, 0, 48, 8, 2, "ground"],
			[0, 0, 48, 2, 2, "tree"],
			# The chapel: slate over stone, with lancet windows and an arched double door.
			[18, 2, 12, 2, 3, "roof_blue"],
			[18, 4, 12, 1, 3, "chapel_window"],
			[18, 5, 12, 1, 3, "chapel_wall"],
			[23, 5, 2, 1, 3, "chapel_door_l"],
			[22, 8, 4, 1, 1, "stairs"],
			# The road north to the fields: along the chapel front, then up through a gap in the woods.
			[22, 6, 16, 2, 2, "path"],
			[36, 0, 2, 6, 2, "path"],
			# The east meadow: a long ledge down to the road, stairs at its south end.
			[38, 12, 9, 18, 1, "ground"],
			[40, 30, 3, 1, 1, "stairs"],
			[42, 15, 2, 2, 1, "tree"],
			[44, 22, 2, 2, 1, "tree"],
			[40, 25, 1, 1, 1, "rock"],
			# Houses: a roof over a half-timbered upper floor and a ground floor. Two thatched
			# cottages, Elder Bram's under blue slate, and the shop under red tiles.
			[6, 11, 6, 2, 3, "roof_thatch"],
			[6, 13, 6, 1, 3, "wall_upper"],
			[6, 14, 6, 1, 3, "wall"],
			[14, 11, 6, 2, 3, "roof_thatch"],
			[14, 13, 6, 1, 3, "wall_upper"],
			[14, 14, 6, 1, 3, "wall"],
			[28, 11, 6, 2, 3, "roof_blue"],
			[28, 13, 6, 1, 3, "wall_upper"],
			[28, 14, 6, 1, 3, "wall"],
			[6, 21, 6, 2, 3, "roof"],
			[6, 23, 6, 1, 3, "wall_upper"],
			[6, 24, 6, 1, 3, "wall"],
			# Doors: the weaver's, the elder's and the shop's.
			[16, 14, 1, 1, 0, "door"],
			[30, 14, 1, 1, 0, "door"],
			[8, 24, 1, 1, 0, "door"],
			# Roads: north-south from the stairs out through the woods; east-west across.
			[22, 9, 4, 27, 0, "path"],
			[3, 16, 35, 2, 0, "path"],
			# The well.
			[18, 19, 2, 2, 0, "well"],
			# A fenced field with a gate.
			[4, 27, 10, 1, 0, "fence"],
			[4, 33, 10, 1, 0, "fence"],
			[4, 27, 1, 7, 0, "fence"],
			[13, 27, 1, 7, 0, "fence"],
			[8, 27, 2, 1, 0, "ground"],
			# The pond.
			[28, 26, 6, 4, 0, "water"],
			# Rocks and trees about the village.
			[33, 20, 1, 1, 0, "rock"],
			[16, 26, 1, 1, 0, "rock"],
			[3, 9, 2, 2, 0, "tree"],
			[34, 31, 2, 2, 0, "tree"],
			# Woods round the edges; the south road leaves through a gap.
			[0, 8, 2, 26, 0, "tree"],
			[46, 8, 2, 4, 0, "tree"],
			[47, 12, 1, 18, 0, "tree"],
			[44, 30, 4, 4, 0, "tree"],
			[0, 34, 22, 2, 0, "tree"],
			[26, 34, 22, 2, 0, "tree"],
			# H12: a market stall in the square with a keg and a crate, lamp posts along the road.
			[29, 19, 3, 2, 0, "stall"],
			[32, 19, 1, 1, 0, "keg"],
			[32, 20, 1, 1, 0, "crate"],
			[21, 12, 1, 1, 0, "lamp"],
			[26, 12, 1, 1, 0, "lamp"],
			[21, 21, 1, 1, 0, "lamp"],
			# Crates by the shop, hay and logs by the field, a washing line west of the square.
			[12, 23, 1, 1, 0, "crate"],
			[12, 24, 1, 1, 0, "keg"],
			[15, 28, 1, 2, 0, "hay"],
			[16, 32, 1, 1, 0, "logs"],
			[2, 19, 1, 1, 0, "post"],
			[5, 19, 1, 1, 0, "post"],
			# A standing stone and a stump on the north rise.
			[12, 4, 1, 1, 2, "standing_stone"],
			[33, 3, 1, 1, 2, "stump"],
			# A nook in the woods by the field, behind tall grass, with a heart piece.
			[0, 30, 2, 1, 0, "ground"],
		],
		"spawns": [
			# Tall grass (one tuft hides the heart piece's nook), pots, chickens in and by the field, butterflies over flowers.
			[1, 30, 1, 1, "grass"],
			[2, 12, 2, 1, "grass"],
			[44, 13, 2, 1, "grass"],
			[34, 30, 2, 1, "grass"],
			[27, 30, 1, 1, "grass"],
			[13, 21, 1, 1, "pot"],
			[34, 14, 1, 2, "pot"],
			[6, 29, 1, 1, "chicken"],
			[10, 31, 1, 1, "chicken"],
			[14, 26, 1, 1, "chicken"],
			[11, 15, 1, 1, "butterfly"],
			[30, 15, 1, 1, "butterfly"],
			[44, 26, 1, 1, "butterfly"],
			[7, 15, 1, 1, "butterfly"],
		],
		"decor": [
			# Flower beds along the house fronts, leaving the doorsteps clear.
			[6, 15, 2, 1, "flowers_red"],
			[10, 15, 2, 1, "flowers_yellow"],
			[14, 15, 2, 1, "flowers_blue"],
			[18, 15, 2, 1, "flowers_red"],
			[28, 15, 2, 1, "flowers_yellow"],
			[32, 15, 2, 1, "flowers_blue"],
			[6, 25, 1, 1, "flowers_red"],
			[10, 25, 2, 1, "flowers_yellow"],
			# Lily pads on the pond.
			[29, 27, 1, 1, "lily"],
			[32, 28, 1, 1, "lily"],
			[30, 29, 1, 1, "lily"],
			# A vegetable patch on the east meadow.
			[43, 26, 3, 3, "crops"],
			# Chimneys with their smoke, the shop's sign and the chapel's cross.
			[10, 11, 1, 1, "chimney"], [10, 10, 1, 1, "smoke"],
			[18, 11, 1, 1, "chimney"], [18, 10, 1, 1, "smoke"],
			[32, 11, 1, 1, "chimney"], [32, 10, 1, 1, "smoke"],
			[10, 21, 1, 1, "chimney"], [10, 20, 1, 1, "smoke"],
			[9, 23, 1, 1, "shop_sign"],
			[23, 2, 1, 1, "cross_l"], [24, 2, 1, 1, "cross_r"],
			[20, 20, 1, 1, "bucket"],
			[3, 19, 2, 1, "laundry"],
		],
		"scatter": {"seed": 7, "kinds": [["tuft", 6], ["flowers_red", 1], ["flowers_yellow", 1], ["flowers_blue", 1], ["pebbles", 1]]},
	},
	"elder_house": {
		"scene": "res://world/areas/elder_house/elder_house.tscn",
		"size": Vector2i(11, 9),
		"base": "floor",
		"blocks": [
			[0, 0, 11, 2, 0, "inner_wall"],
			[0, 0, 1, 9, 0, "inner_wall"],
			[10, 0, 1, 9, 0, "inner_wall"],
			[0, 8, 11, 1, 0, "inner_wall"],
			[5, 8, 1, 1, 0, "doormat"],
			[5, 1, 1, 1, 0, "hearth"],
			[1, 2, 3, 1, 0, "shelf"],
			[8, 2, 1, 1, 0, "bed"],
			[4, 4, 3, 2, 0, "rug"],
			[1, 5, 2, 1, 0, "table"],
			[1, 7, 1, 1, 0, "barrel"],
			[9, 7, 1, 1, 0, "barrel"],
			# H12: a chair at the table, a cupboard, a candle stand, a bookcase.
			[3, 5, 1, 1, 0, "chair"],
			[6, 2, 1, 1, 0, "cupboard"],
			[7, 2, 1, 1, 0, "candle"],
			[9, 4, 1, 1, 0, "bookcase"],
		],
		"spawns": [
			[8, 7, 1, 1, "pot"],
		],
	},
	"weaver_house": {
		"scene": "res://world/areas/weaver_house/weaver_house.tscn",
		"size": Vector2i(11, 9),
		"base": "floor",
		"blocks": [
			[0, 0, 11, 2, 0, "inner_wall"],
			[0, 0, 1, 9, 0, "inner_wall"],
			[10, 0, 1, 9, 0, "inner_wall"],
			[0, 8, 11, 1, 0, "inner_wall"],
			[5, 8, 1, 1, 0, "doormat"],
			[1, 2, 2, 1, 0, "shelf"],
			[6, 2, 3, 1, 0, "table"],
			[9, 2, 1, 1, 0, "barrel"],
			[1, 5, 1, 1, 0, "bed"],
			[3, 4, 3, 2, 0, "rug"],
			[8, 5, 1, 2, 0, "barrel"],
			# H12: the weaver's loom, a cupboard, a stool and a plant.
			[3, 2, 1, 1, 0, "loom"],
			[5, 2, 1, 1, 0, "cupboard"],
			[2, 7, 1, 1, 0, "stool"],
			[9, 7, 1, 1, 0, "plant"],
		],
		"spawns": [
			[1, 7, 1, 1, "pot"],
		],
	},
	"shop": {
		"scene": "res://world/areas/shop/shop.tscn",
		"size": Vector2i(11, 9),
		"base": "floor",
		"blocks": [
			[0, 0, 11, 2, 0, "inner_wall"],
			[0, 0, 1, 9, 0, "inner_wall"],
			[10, 0, 1, 9, 0, "inner_wall"],
			[0, 8, 11, 1, 0, "inner_wall"],
			[5, 8, 1, 1, 0, "doormat"],
			# Shelves of wares along the back wall; the counter, open in the middle.
			[1, 2, 9, 1, 0, "shelf"],
			[2, 4, 3, 1, 0, "table"],
			[6, 4, 3, 1, 0, "table"],
			[1, 6, 1, 2, 0, "barrel"],
			[9, 6, 1, 2, 0, "barrel"],
			[4, 6, 3, 1, 0, "rug"],
			# H12: proper counters with wares, a plant and a stool.
			[2, 4, 3, 1, 0, "counter"],
			[6, 4, 3, 1, 0, "counter"],
			[2, 6, 1, 1, 0, "plant"],
			[8, 6, 1, 1, 0, "stool"],
		],
		"spawns": [
			[2, 7, 1, 1, "pot"],
			[8, 7, 1, 1, "pot"],
		],
	},
	"ruin_cellar": {
		"scene": "res://world/areas/ruin_cellar/ruin_cellar.tscn",
		"size": Vector2i(15, 33),
		"base": "dungeon_wall",
		"blocks": [
			# Floors: the inner room (north), the hall, the entry hall (south).
			[1, 1, 13, 9, 0, "dungeon_floor"],
			[1, 12, 13, 9, 0, "dungeon_floor"],
			[1, 23, 13, 9, 0, "dungeon_floor"],
			# Doorways through the walls between rooms: entry hall to hall, hall to inner room.
			[7, 21, 1, 2, 0, "dungeon_floor"],
			[7, 10, 1, 2, 0, "dungeon_floor"],
			# The hall's side alcove, behind a shutter.
			[4, 12, 1, 9, 0, "dungeon_wall"],
			[4, 16, 1, 1, 0, "dungeon_floor"],
			# Pillars.
			[3, 25, 1, 1, 0, "pillar"],
			[11, 25, 1, 1, 0, "pillar"],
			[3, 29, 1, 1, 0, "pillar"],
			[11, 29, 1, 1, 0, "pillar"],
			[10, 14, 1, 1, 0, "pillar"],
			[10, 18, 1, 1, 0, "pillar"],
			[4, 3, 1, 1, 0, "pillar"],
			[10, 3, 1, 1, 0, "pillar"],
			# The way back up, in the entry hall's south wall; the way down, in the inner room's north wall.
			[7, 32, 1, 1, 0, "stairway"],
			[12, 0, 1, 1, 0, "stairway"],
		],
		"spawns": [
			[1, 30, 1, 1, "pot"],
			[13, 30, 1, 1, "pot"],
		],
	},
	"cistern": {
		"scene": "res://world/areas/cistern/cistern.tscn",
		"size": Vector2i(30, 33),
		"base": "dungeon_wall",
		"blocks": [
			# Floors of the five rooms.
			[1, 1, 13, 9, 0, "dungeon_floor"],
			[16, 1, 13, 9, 0, "dungeon_floor"],
			[1, 12, 13, 9, 0, "dungeon_floor"],
			[16, 12, 13, 9, 0, "dungeon_floor"],
			[1, 23, 13, 9, 0, "dungeon_floor"],
			# Doorways: push room to plate room, plate room to switch room, switch room to the
			# cracked wall's room, and the cracked wall itself into the combined room.
			[7, 21, 1, 2, 0, "dungeon_floor"],
			[14, 16, 2, 1, 0, "dungeon_floor"],
			[22, 10, 1, 2, 0, "dungeon_floor"],
			[14, 5, 2, 1, 0, "dungeon_floor"],
			# Push room: a row of pillars across it; a block fills the only gap, away from the
			# doorway, so pushing it north can't park it in front of the way out.
			[1, 26, 3, 1, 0, "pillar"],
			[5, 26, 9, 1, 0, "pillar"],
			# Plate room and switch room: a few pillars; the switch sits in a nook open to the south.
			[4, 18, 1, 1, 0, "pillar"],
			[10, 14, 1, 1, 0, "pillar"],
			[21, 14, 3, 1, 0, "pillar"],
			[21, 15, 1, 1, 0, "pillar"],
			[23, 15, 1, 1, 0, "pillar"],
			# Combined room: the treasure alcove behind a shutter, and a raised platform (no
			# stairs) with a crystal out of sword reach.
			[4, 1, 1, 4, 0, "dungeon_wall"],
			[1, 4, 4, 1, 0, "dungeon_wall"],
			[2, 4, 1, 1, 0, "dungeon_floor"],
			[9, 1, 4, 4, 1, "ledge"],
			# The way back up.
			[7, 32, 1, 1, 0, "stairway"],
			# H12: the sixth room is no longer rock: a secret room behind a cracked wall in the push
			# room's east wall (its door is in the scene), with a heart piece and pots.
			[16, 23, 13, 9, 0, "dungeon_floor"],
			[14, 27, 2, 1, 0, "dungeon_floor"],
			[18, 25, 1, 1, 0, "pillar"],
			[26, 25, 1, 1, 0, "pillar"],
			[18, 29, 1, 1, 0, "pillar"],
			[26, 29, 1, 1, 0, "pillar"],
		],
		"spawns": [
			[17, 24, 1, 1, "pot"],
			[27, 24, 1, 1, "pot"],
			[17, 30, 1, 1, "pot"],
			[27, 30, 1, 1, "pot"],
		],
	},
	"keep": {
		"scene": "res://world/areas/keep/keep.tscn",
		"size": Vector2i(45, 44),
		"base": "dungeon_wall",
		"blocks": [
			# Floors of the ten rooms (the top middle and top right are solid rock).
			[16, 34, 13, 9, 0, "dungeon_floor"],
			[1, 34, 13, 9, 0, "dungeon_floor"],
			[31, 34, 13, 9, 0, "dungeon_floor"],
			[16, 23, 13, 9, 0, "dungeon_floor"],
			[1, 23, 13, 9, 0, "dungeon_floor"],
			[31, 23, 13, 9, 0, "dungeon_floor"],
			[1, 12, 13, 9, 0, "dungeon_floor"],
			[16, 12, 13, 9, 0, "dungeon_floor"],
			[31, 12, 13, 9, 0, "dungeon_floor"],
			[1, 1, 13, 9, 0, "dungeon_floor"],
			# Doorways through the walls between rooms (their doors are in the scene).
			[14, 38, 2, 1, 0, "dungeon_floor"],
			[29, 38, 2, 1, 0, "dungeon_floor"],
			[22, 32, 1, 2, 0, "dungeon_floor"],
			[14, 27, 2, 1, 0, "dungeon_floor"],
			[29, 27, 2, 1, 0, "dungeon_floor"],
			[22, 21, 1, 2, 0, "dungeon_floor"],
			[7, 21, 1, 2, 0, "dungeon_floor"],
			[7, 10, 1, 2, 0, "dungeon_floor"],
			[37, 21, 1, 2, 0, "dungeon_floor"],
			# Entrance and great hall: pillars.
			[18, 36, 1, 1, 0, "pillar"],
			[26, 36, 1, 1, 0, "pillar"],
			[18, 40, 1, 1, 0, "pillar"],
			[26, 40, 1, 1, 0, "pillar"],
			[18, 25, 1, 1, 0, "pillar"],
			[26, 25, 1, 1, 0, "pillar"],
			[18, 29, 1, 1, 0, "pillar"],
			[26, 29, 1, 1, 0, "pillar"],
			[33, 35, 1, 1, 0, "pillar"],
			[41, 35, 1, 1, 0, "pillar"],
			# Guard room: the small key's alcove, behind a shutter.
			[4, 34, 1, 4, 0, "dungeon_wall"],
			[1, 37, 4, 1, 0, "dungeon_wall"],
			[2, 37, 1, 1, 0, "dungeon_floor"],
			# Armoury: a ledge (no stairs) with a crystal on it, out of sword reach; two pillars.
			[9, 12, 4, 3, 1, "ledge"],
			[3, 18, 1, 1, 0, "pillar"],
			[11, 18, 1, 1, 0, "pillar"],
			# Gallery: a walkway along the north wall for the archers (no stairs), and the second
			# small key's alcove behind a shutter.
			[1, 1, 13, 3, 1, "ledge"],
			[10, 6, 1, 4, 0, "dungeon_wall"],
			[10, 6, 4, 1, 0, "dungeon_wall"],
			[10, 8, 1, 1, 0, "dungeon_floor"],
			# Twin crystals: a ledge in the north-east corner for the high one.
			[39, 23, 5, 3, 1, "ledge"],
			# Big key room: the big key's alcove, behind a shutter.
			[35, 12, 1, 3, 0, "dungeon_wall"],
			[39, 12, 1, 3, 0, "dungeon_wall"],
			[35, 15, 5, 1, 0, "dungeon_wall"],
			[37, 15, 1, 1, 0, "dungeon_floor"],
			# The gate (south) and the way out behind the Warden's hall (north).
			[22, 43, 1, 1, 0, "stairway"],
			[22, 11, 1, 1, 0, "stairway"],
		],
		"spawns": [
			[17, 35, 1, 1, "pot"],
			[27, 35, 1, 1, "pot"],
			[17, 23, 1, 1, "pot"],
			[27, 23, 1, 1, "pot"],
			[17, 13, 1, 1, "pot"],
			[27, 13, 1, 1, "pot"],
		],
	},
	"crypt": {
		"scene": "res://world/areas/crypt/crypt.tscn",
		"size": Vector2i(45, 44),
		"base": "dungeon_wall",
		"blocks": [
			# Floors of the ten rooms (the top left and top middle are solid rock).
			[16, 34, 13, 9, 0, "dungeon_floor"],
			[31, 34, 13, 9, 0, "dungeon_floor"],
			[1, 34, 13, 9, 0, "dungeon_floor"],
			[16, 23, 13, 9, 0, "dungeon_floor"],
			[31, 23, 13, 9, 0, "dungeon_floor"],
			[1, 23, 13, 9, 0, "dungeon_floor"],
			[31, 12, 13, 9, 0, "dungeon_floor"],
			[16, 12, 13, 9, 0, "dungeon_floor"],
			[1, 12, 13, 9, 0, "dungeon_floor"],
			[31, 1, 13, 9, 0, "dungeon_floor"],
			# Doorways through the walls between rooms (their doors are in the scene).
			[29, 38, 2, 1, 0, "dungeon_floor"],
			[14, 38, 2, 1, 0, "dungeon_floor"],
			[22, 32, 1, 2, 0, "dungeon_floor"],
			[29, 27, 2, 1, 0, "dungeon_floor"],
			[14, 27, 2, 1, 0, "dungeon_floor"],
			[22, 21, 1, 2, 0, "dungeon_floor"],
			[37, 21, 1, 2, 0, "dungeon_floor"],
			[37, 10, 1, 2, 0, "dungeon_floor"],
			[7, 21, 1, 2, 0, "dungeon_floor"],
			# The Trench: a pit right across the room.
			[37, 34, 1, 9, 0, "pit"],
			# The Dark Path: two walls of pit, each with a gap at one end.
			[34, 17, 10, 1, 0, "pit"],
			[31, 14, 10, 1, 0, "pit"],
			# The Knight's Tomb: the Iron Sword's alcove, behind bars.
			[39, 1, 1, 3, 0, "dungeon_wall"],
			[35, 1, 1, 3, 0, "dungeon_wall"],
			[35, 4, 5, 1, 0, "dungeon_wall"],
			[37, 4, 1, 1, 0, "dungeon_floor"],
			# The Ossuary: the small key's alcove, behind bars.
			[4, 34, 1, 4, 0, "dungeon_wall"],
			[1, 37, 4, 1, 0, "dungeon_wall"],
			[2, 37, 1, 1, 0, "dungeon_floor"],
			[8, 38, 1, 1, 0, "pillar"],
			# The Broken Floor: a trench between the way in and the way on.
			[1, 26, 13, 1, 0, "pit"],
			# The Reliquary: a pit between the hero and the far wall, and the big key's alcove.
			[1, 14, 13, 2, 0, "pit"],
			[1, 17, 4, 1, 0, "dungeon_wall"],
			[4, 17, 1, 4, 0, "dungeon_wall"],
			[4, 19, 1, 1, 0, "dungeon_floor"],
			# The stairs up to the chapel.
			[22, 43, 1, 1, 0, "stairway"],
		],
		"spawns": [
			[28, 34, 1, 1, "pot"],
			[16, 34, 1, 1, "pot"],
			[28, 42, 1, 1, "pot"],
			[16, 42, 1, 1, "pot"],
			[28, 23, 1, 1, "pot"],
			[16, 23, 1, 1, "pot"],
			[11, 31, 1, 1, "pot"],
			[9, 31, 1, 1, "pot"],
			[13, 20, 1, 1, "pot"],
			[11, 20, 1, 1, "pot"],
			[1, 42, 1, 1, "pot"],
		],
	},
	"north_fields": {
		"scene": "res://world/areas/north_fields/north_fields.tscn",
		"size": Vector2i(40, 30),
		"blocks": [
			# Woods round the edges; the road comes in at the bottom and leaves at the top.
			[0, 0, 40, 2, 0, "tree"],
			[0, 28, 40, 2, 0, "tree"],
			[0, 2, 2, 26, 0, "tree"],
			[38, 2, 2, 26, 0, "tree"],
			# A thicket in the north-west hiding a meadow, reached by a narrow path from a gap
			# in the tree line beside the road (the first secret).
			[2, 2, 11, 7, 0, "tree"],
			[3, 3, 5, 4, 0, "ground"],
			[8, 5, 5, 1, 0, "ground"],
			# The stream across the fields; the road crosses it (laid later, so a bridge).
			[2, 10, 36, 2, 0, "water"],
			# The road, winding north.
			[20, 16, 2, 14, 0, "path"],
			[14, 14, 8, 2, 0, "path"],
			[14, 4, 2, 12, 0, "path"],
			[14, 4, 6, 2, 0, "path"],
			[18, 0, 2, 6, 0, "path"],
			# The plateau in the east: stairs on its west side, a ledge all round, an archer.
			[27, 14, 10, 8, 1, "ground"],
			[26, 17, 1, 2, 1, "stairs"],
			[33, 15, 2, 2, 1, "tree"],
			[29, 19, 1, 1, 1, "rock"],
			# A fenced farm plot with a gate.
			[4, 18, 9, 1, 0, "fence"],
			[4, 25, 9, 1, 0, "fence"],
			[4, 18, 1, 8, 0, "fence"],
			[12, 18, 1, 8, 0, "fence"],
			[8, 18, 1, 1, 0, "ground"],
			# Trees and rocks about the fields.
			[24, 4, 2, 2, 0, "tree"],
			[30, 5, 2, 2, 0, "tree"],
			[8, 13, 1, 1, 0, "rock"],
			[25, 24, 2, 2, 0, "tree"],
			[32, 25, 1, 1, 0, "rock"],
			[16, 22, 2, 2, 0, "tree"],
			# H12: hay by the farm, logs, a standing stone by the stream, a stump below the plateau.
			[13, 19, 1, 2, 0, "hay"],
			[3, 26, 1, 1, 0, "logs"],
			[24, 9, 1, 1, 0, "standing_stone"],
			[30, 23, 1, 1, 0, "stump"],
		],
		"spawns": [
			# Tall grass round the plateau's far corner hides a heart piece.
			[35, 21, 1, 1, "grass"],
			[36, 20, 1, 1, "grass"],
			[3, 13, 2, 1, "grass"],
			[10, 9, 1, 1, "grass"],
			[22, 24, 1, 1, "grass"],
			[8, 21, 1, 1, "butterfly"],
			[30, 7, 1, 1, "butterfly"],
		],
		"decor": [
			[5, 19, 7, 6, "crops"],
			[6, 10, 1, 1, "lily"],
			[25, 11, 1, 1, "lily"],
			[33, 10, 1, 1, "lily"],
			[3, 3, 1, 1, "flowers_red"],
			[7, 3, 1, 1, "flowers_yellow"],
			[3, 6, 2, 1, "flowers_blue"],
			[6, 6, 2, 1, "flowers_red"],
		],
		"scatter": {"seed": 13, "kinds": [["tuft", 8], ["flowers_red", 1], ["flowers_yellow", 2], ["flowers_blue", 1], ["pebbles", 1]]},
	},
	"old_wood": {
		"scene": "res://world/areas/old_wood/old_wood.tscn",
		"size": Vector2i(40, 30),
		"blocks": [
			# Trees everywhere; clearings and the road are cut out of them below.
			[0, 0, 40, 30, 0, "tree"],
			# The keep's stone front along the top, its gate in the middle.
			[10, 0, 20, 4, 0, "stone"],
			[18, 3, 2, 1, 0, "stairway"],
			# The forecourt before the keep.
			[8, 4, 24, 6, 0, "ground"],
			[14, 6, 1, 1, 0, "rock"],
			[26, 7, 1, 1, 0, "rock"],
			# Corner towers standing out from the keep's front.
			[10, 0, 3, 5, 0, "stone"],
			[27, 0, 3, 5, 0, "stone"],
			# The road, winding south from the gate to the fields.
			[18, 4, 2, 10, 0, "path"],
			[10, 12, 10, 2, 0, "path"],
			[10, 14, 2, 10, 0, "path"],
			[10, 22, 10, 2, 0, "path"],
			[18, 24, 2, 6, 0, "path"],
			# Clearings off the road: bats in the west, slimes and an archer in the south-east.
			[2, 14, 8, 8, 0, "ground"],
			[20, 18, 12, 8, 0, "ground"],
			# The old shrine east of the forecourt (the second secret): stone walls round a
			# heart piece, one stretch cracked (its door is in the scene), and a nook before it.
			[24, 10, 6, 6, 0, "ground"],
			[30, 10, 8, 7, 0, "stone"],
			[31, 11, 6, 5, 0, "ground"],
			[30, 13, 1, 1, 0, "ground"],
			# H12: logs and stumps in the clearings, a standing stone by the shrine.
			[3, 15, 1, 1, 0, "logs"],
			[8, 20, 1, 1, 0, "stump"],
			[22, 24, 1, 1, 0, "stump"],
			[30, 24, 1, 1, 0, "logs"],
			[26, 11, 1, 1, 0, "standing_stone"],
		],
		"spawns": [
			[4, 16, 1, 1, "firefly"],
			[7, 19, 1, 1, "firefly"],
			[23, 21, 1, 1, "firefly"],
			[28, 20, 1, 1, "firefly"],
			[12, 8, 1, 1, "firefly"],
			[21, 19, 2, 1, "grass"],
			[9, 15, 1, 1, "grass"],
			[16, 4, 1, 1, "pot"],
			[21, 4, 1, 1, "pot"],
		],
		"decor": [
			[32, 11, 1, 1, "flowers_blue"],
			[35, 11, 1, 1, "flowers_red"],
			[32, 15, 1, 1, "flowers_yellow"],
			[35, 15, 1, 1, "flowers_blue"],
		],
		"scatter": {"seed": 17, "kinds": [["tuft", 10], ["mushroom", 4], ["pebbles", 2], ["flowers_blue", 1]]},
	},
	"south_field": {
		"scene": "res://world/areas/south_field/south_field.tscn",
		"size": Vector2i(40, 28),
		"blocks": [
			# The road down from the village, then east toward the ruin.
			[18, 0, 4, 16, 0, "path"],
			[18, 14, 14, 2, 0, "path"],
			# The plateau: a raised meadow with a ledge all round, stairs on its west side.
			[26, 3, 12, 9, 2, "ground"],
			[25, 6, 1, 2, 1, "stairs"],
			[33, 4, 2, 2, 2, "tree"],
			[28, 9, 1, 1, 2, "rock"],
			# The meadow in the west, with a pond.
			[5, 17, 6, 4, 0, "water"],
			[4, 6, 2, 2, 0, "tree"],
			[10, 11, 1, 1, 0, "rock"],
			[14, 21, 1, 1, 0, "rock"],
			[12, 24, 2, 2, 0, "tree"],
			# The old ruin, open to the south, with a stairway down to the cellar.
			[31, 19, 1, 1, 0, "stairway"],
			[27, 18, 9, 1, 0, "stone"],
			[27, 18, 1, 6, 0, "stone"],
			[35, 18, 1, 6, 0, "stone"],
			# Woods round the edges; the road comes in from the north.
			[0, 0, 18, 2, 0, "tree"],
			[22, 0, 18, 2, 0, "tree"],
			[0, 2, 2, 26, 0, "tree"],
			[38, 2, 2, 26, 0, "tree"],
			[0, 26, 40, 2, 0, "tree"],
			# H12: logs, a stump and a pair of standing stones.
			[4, 22, 1, 1, 0, "logs"],
			[36, 24, 1, 1, 0, "stump"],
			[16, 8, 1, 1, 0, "standing_stone"],
			[12, 13, 1, 1, 0, "standing_stone"],
		],
		"spawns": [
			[2, 10, 2, 1, "grass"],
			[3, 14, 1, 1, "grass"],
			[13, 23, 2, 1, "grass"],
			[24, 24, 2, 1, "grass"],
			[28, 22, 1, 1, "pot"],
			[34, 22, 1, 1, "pot"],
			[8, 13, 1, 1, "butterfly"],
			[14, 20, 1, 1, "butterfly"],
		],
		"decor": [
			[6, 18, 1, 1, "lily"],
			[9, 19, 1, 1, "lily"],
		],
		"scatter": {"seed": 11, "kinds": [["tuft", 9], ["flowers_red", 1], ["flowers_yellow", 1], ["flowers_blue", 1], ["mushroom", 1], ["pebbles", 2]]},
	},
}


func _initialize() -> void:
	var names: PackedStringArray = OS.get_cmdline_user_args()
	if names.is_empty():
		names = PackedStringArray(MAPS.keys())
	for map_name: String in names:
		if not MAPS.has(map_name):
			push_error("tools/greybox: no area '%s'. Areas: %s" % [map_name, ", ".join(MAPS.keys())])
			quit(1)
			return
		if _bake(MAPS[map_name]) != OK:
			quit(1)
			return
	quit(0)


func _bake(map: Dictionary) -> Error:
	var path: String = map["scene"]
	var packed: PackedScene = load(path)
	if packed == null:
		push_error("tools/greybox: cannot load %s" % path)
		return ERR_CANT_OPEN
	# Edit state MAIN (as the editor opens scenes) keeps instanced children (Player, HUD) as
	# clean instances; without it pack() pins every inherited property.
	var root: Node = packed.instantiate(PackedScene.GEN_EDIT_STATE_MAIN)
	var layer: TileMapLayer = root.get_node("Height")
	var size: Vector2i = map["size"]
	var base: Vector2i = GreyboxTiles.coords(str(map.get("base", "ground")), 0)
	var props: Dictionary = {}
	layer.clear()
	for y: int in size.y:
		for x: int in size.x:
			layer.set_cell(Vector2i(x, y), GreyboxTiles.SOURCE_ID, base)
	for block: Array in map["blocks"]:
		var kind: String = block[5]
		if not GreyboxTiles.is_known_kind(kind):
			push_error("tools/greybox: unknown tile kind '%s' in %s" % [kind, block])
			root.free()
			return ERR_INVALID_DATA
		for y: int in range(block[1], block[1] + block[3]):
			for x: int in range(block[0], block[0] + block[2]):
				var cell: Vector2i = Vector2i(x, y)
				props.erase(cell)
				if GreyboxTiles.PROP_BLOCKS.has(kind):
					layer.set_cell(cell, GreyboxTiles.SOURCE_ID, GreyboxTiles.coords("solid_ground", block[4]))
					props[cell] = _prop(kind, x - int(block[0]), y - int(block[1]))
					continue
				var detail: String = _detail(kind, x - int(block[0]), y - int(block[1]), block[2], block[3])
				layer.set_cell(cell, GreyboxTiles.SOURCE_ID, GreyboxTiles.coords(detail, block[4]))
	var decor_error: Error = _decorate(root, layer, map, props)
	if decor_error == OK:
		decor_error = _spawns(root, map)
	if decor_error != OK:
		root.free()
		return decor_error
	var out: PackedScene = PackedScene.new()
	var error: Error = out.pack(root)
	if error == OK:
		error = ResourceSaver.save(out, path)
	root.free()
	print("tools/greybox: baked %d blocks into %s (%s)" % [(map["blocks"] as Array).size(), path, error_string(error)])
	return error


## The prop for cell (dx, dy) of a prop block: the tree, rock, fence, crate and so on, a well
## quarter (2x2), or a part of the market stall (3x2: awning above, counter below).
func _prop(kind: String, dx: int, dy: int) -> String:
	if kind == "well":
		return "well_%s%s" % ["n" if dy % 2 == 0 else "s", "w" if dx % 2 == 0 else "e"]
	if kind == "stall":
		return "stall_%s%s" % ["n" if dy % 2 == 0 else "s", ["w", "", "e"][dx % 3]]
	return GreyboxTiles.PROP_BLOCKS[kind]


## The tile for cell (dx, dy) of a block of `kind`, `width` x `height`:
## - a roof ("roof", "roof_blue", "roof_thatch"): its top row gets the ridge, its bottom row the
##   eaves, and its first and last columns a gable's barge board
## - walls get a window every third cell; an upper floor's other cells alternate their braces
## - "chapel_window" alternates stone and lancet windows; "chapel_door_l" is a pair of leaves
## - a "pit" shows its far wall along its top row
func _detail(kind: String, dx: int, dy: int, width: int, height: int) -> String:
	match kind:
		"roof", "roof_blue", "roof_thatch":
			var part: String = ""
			if height >= 2 and dy == 0:
				part = "_top"
			elif height >= 2 and dy == height - 1:
				part = "_eave"
			var edge: String = ""
			if width >= 2 and dx == 0:
				edge = "_l"
			elif width >= 2 and dx == width - 1:
				edge = "_r"
			return kind + part + edge
		"wall":
			if width >= 4 and dx % 3 == 1 and dx < width - 1:
				return "wall_window"
		"wall_upper":
			if width >= 4 and dx % 3 == 1 and dx < width - 1:
				return "wall_upper_window"
			return "wall_upper" if dx % 2 == 0 else "wall_upper_b"
		"chapel_window":
			return "chapel_window" if dx % 2 == 1 else "chapel_wall"
		"chapel_door_l":
			return "chapel_door_l" if dx % 2 == 0 else "chapel_door_r"
		"pit":
			return "pit_top" if dy == 0 else "pit"
	return kind


## Fills the Decor layer (adding it after Height if the scene has none): the map's decor
## blocks, then its scatter over open ground away from anything the hero uses or arrives at.
func _decorate(root: Node, height_layer: TileMapLayer, map: Dictionary, props: Dictionary) -> Error:
	var decor: TileMapLayer = root.get_node_or_null(^"Decor")
	if decor == null:
		decor = TileMapLayer.new()
		decor.name = "Decor"
		root.add_child(decor)
		root.move_child(decor, height_layer.get_index() + 1)
		decor.owner = root
	decor.tile_set = height_layer.tile_set
	decor.clear()
	for cell: Vector2i in props:
		var prop: String = str(props[cell])
		if prop == "prop_tree":
			prop = _tree_kind(cell, props, map["size"])
		decor.set_cell(cell, GreyboxTiles.SOURCE_ID, GreyboxTiles.coords(prop))
	for block: Array in map.get("decor", []):
		var kind: String = block[4]
		if not GreyboxTiles.is_decor(kind):
			push_error("tools/greybox: '%s' is not a decoration (%s)" % [kind, block])
			return ERR_INVALID_DATA
		for y: int in range(block[1], block[1] + block[3]):
			for x: int in range(block[0], block[0] + block[2]):
				decor.set_cell(Vector2i(x, y), GreyboxTiles.SOURCE_ID, GreyboxTiles.coords(kind))
	var scatter: Dictionary = map.get("scatter", {})
	if scatter.is_empty():
		return OK
	var avoid: Dictionary = _busy_cells(root)
	var seed_value: int = int(scatter.get("seed", 1))
	for cell: Vector2i in height_layer.get_used_cells():
		if height_layer.get_cell_atlas_coords(cell).y != GreyboxTiles.ROW_GROUND or avoid.has(cell):
			continue
		if decor.get_cell_source_id(cell) != -1:
			continue
		var roll: int = _cell_hash(cell, seed_value) % 100
		for entry: Array in scatter["kinds"]:
			if roll < int(entry[1]):
				decor.set_cell(cell, GreyboxTiles.SOURCE_ID, GreyboxTiles.coords(str(entry[0])))
				break
			roll -= int(entry[1])
	return OK


## Paints the hidden Spawns layer (adding it after Decor if the scene has none): grass, pots and
## critters, from the map's "spawns" blocks [x, y, width, height, kind]. The area turns each
## marker into its node on load.
func _spawns(root: Node, map: Dictionary) -> Error:
	var layer: TileMapLayer = root.get_node_or_null(^"Spawns")
	var blocks: Array = map.get("spawns", [])
	if layer == null and blocks.is_empty():
		return OK
	if layer == null:
		layer = TileMapLayer.new()
		layer.name = "Spawns"
		root.add_child(layer)
		root.move_child(layer, root.get_node(^"Decor").get_index() + 1)
		layer.owner = root
	layer.tile_set = (root.get_node(^"Height") as TileMapLayer).tile_set
	layer.clear()
	for block: Array in blocks:
		var kind: String = block[4]
		if not GreyboxTiles.MARKER_KINDS.has(kind):
			push_error("tools/greybox: '%s' is not a spawn marker (%s)" % [kind, block])
			return ERR_INVALID_DATA
		for y: int in range(block[1], block[1] + block[3]):
			for x: int in range(block[0], block[0] + block[2]):
				layer.set_cell(Vector2i(x, y), GreyboxTiles.SOURCE_ID, GreyboxTiles.marker_coords(kind))
	return OK


## Which tree stands at `cell`: a closed canopy where trees (or the map's edge) stand on all
## four sides of it, else one of three kinds, picked by the cell so a wood is never a grid of
## one tree.
func _tree_kind(cell: Vector2i, props: Dictionary, size: Vector2i) -> String:
	var hemmed_in: bool = true
	for side: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		var neighbour: Vector2i = cell + side
		if Rect2i(Vector2i.ZERO, size).has_point(neighbour) and str(props.get(neighbour, "")) != "prop_tree":
			hemmed_in = false
	if hemmed_in:
		return "prop_canopy"
	var roll: int = _cell_hash(cell, 29) % 6
	return "prop_tree" if roll < 3 else ("prop_tree_b" if roll < 5 else "prop_tree_c")


## Cells the hero uses or arrives at: every Interactables child (with its size, if it has
## one), every entry point and the spawn. Scatter keeps off them.
func _busy_cells(root: Node) -> Dictionary:
	var cells: Dictionary = {}
	var interactables: Node = root.get_node_or_null(^"Interactables")
	if interactables != null:
		for child: Node in interactables.get_children():
			var at: Vector2i = _cell_at((child as Node2D).position)
			var size: Variant = child.get(&"size")
			var span: Vector2i = size if typeof(size) == TYPE_VECTOR2I else Vector2i.ONE
			for y: int in span.y:
				for x: int in span.x:
					cells[at + Vector2i(x, y)] = true
	var entries: Node = root.get_node_or_null(^"Entries")
	if entries != null:
		for marker: Node in entries.get_children():
			cells[_cell_at((marker as Node2D).position)] = true
	var spawn: Node2D = root.get_node_or_null(^"PlayerSpawn")
	if spawn != null:
		cells[_cell_at(spawn.position)] = true
	return cells


func _cell_at(point: Vector2) -> Vector2i:
	return Vector2i(floori(point.x / GreyboxTiles.TILE_SIZE), floori(point.y / GreyboxTiles.TILE_SIZE))


## The same number for the same cell and seed, every bake.
func _cell_hash(cell: Vector2i, seed_value: int) -> int:
	var h: int = (cell.x * 73856093) ^ (cell.y * 19349663) ^ (seed_value * 83492791)
	h = (h ^ (h >> 13)) * 1274126177
	return absi(h ^ (h >> 16))
