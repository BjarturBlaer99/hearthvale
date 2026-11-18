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
## - the houses have a door in their front wall (tests/world/doors_test.gd): the weaver's, the
##   elder's, the shop's and (P2b) the hero's own cottage, west of the weaver's.
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
## Willowmere (2026-11-17, tests/world/willowmere_test.gd): a marsh reached from the village's
## east meadow; water and reeds block, boardwalks are the paths, a nook behind the willows.
## The Homestead (2026-11-17, tests/world/homestead_test.gd): the hero's farm west of the village,
## at the end of the lane: the road in, the farmhouse and the path to its door, a pond, old trees,
## and the land's overgrowth as markers.

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
## A map may name its "prop_ground": the solid ground its props stand on (default the grass's
## "solid_ground"; the marsh's is "marsh_solid").
## A map may be drawn as a "sketch" (the Old Quarry's are): rows of characters, a cell each,
## laid before its blocks. "#" is the map's base (cave wall), "~" water, "^" raised floor (a
## ledge at height 1), "S" stairs up to it, "T" a timber prop, "o" floor with a rock marker on
## it, "=" floor with rails on it, and anything else floor: the letters only mark where the
## scene's own nodes stand (the way in, monsters, the lift). A cave wall with floor to its
## south shows its face.
## A sketch may have a "legend" of its own (the Homestead's has): each character it names lays
## [kind, height] in its cell, and every other character leaves the map's base showing. Its
## "marks" then say which characters are spawn markers (character -> marker kind).
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
			# Doors: the hero's own (P2b), the weaver's, the elder's and the shop's.
			[8, 14, 1, 1, 0, "door"],
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
			[3, 9, 2, 2, 0, "cherry"],
			[34, 31, 2, 2, 0, "cherry"],
			# P1c: cherry trees by the chapel, round the pond and along the main path. These eight
			# are new solid cells, approved by the user on 2026-11-12 (tests/world/nature_test.gd).
			[16, 4, 1, 1, 2, "cherry"],
			[31, 4, 1, 1, 2, "cherry"],
			[34, 25, 1, 1, 0, "cherry"],
			[27, 31, 1, 1, 0, "cherry"],
			[21, 10, 1, 1, 0, "cherry"],
			[26, 10, 1, 1, 0, "cherry"],
			[26, 22, 1, 1, 0, "cherry"],
			[21, 27, 1, 1, 0, "cherry"],
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
			# The way east to Willowmere (2026-11-17): two cells of the east tree line opened,
			# level with the east meadow, approved by the user (tests/world/willowmere_test.gd).
			[47, 17, 1, 2, 1, "ground"],
			# The way west to the Homestead (2026-11-17): two cells of the west tree line opened
			# on the lane's rows, and the lane run on to the edge, approved by the user (the
			# Homestead's plan, D1; tests/world/homestead_test.gd).
			[0, 16, 3, 2, 0, "path"],
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
			# Planks across the east meadow to the gap in the trees: the walk to the marsh.
			[44, 17, 4, 2, "planks"],
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
	# The hero's home (P2b): one room, with his bed, a hearth to cook at, and a candle. The bed
	# is against the west wall, so he stands beside it and it is never hidden behind him.
	"home": {
		"scene": "res://world/areas/home/home.tscn",
		"size": Vector2i(11, 9),
		"base": "floor",
		"blocks": [
			[0, 0, 11, 2, 0, "inner_wall"],
			[0, 0, 1, 9, 0, "inner_wall"],
			[10, 0, 1, 9, 0, "inner_wall"],
			[0, 8, 11, 1, 0, "inner_wall"],
			[5, 8, 1, 1, 0, "doormat"],
			[5, 1, 1, 1, 0, "hearth"],
			[1, 2, 1, 1, 0, "cupboard"],
			[3, 2, 1, 1, 0, "candle"],
			[1, 3, 1, 1, 0, "bed"],
			[7, 2, 2, 1, 0, "shelf"],
			[9, 2, 1, 1, 0, "barrel"],
			[4, 4, 3, 2, 0, "rug"],
			[8, 5, 1, 1, 0, "table"],
			[7, 5, 1, 1, 0, "chair"],
			[1, 7, 1, 1, 0, "plant"],
			[9, 7, 1, 1, 0, "stool"],
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
			[30, 5, 2, 2, 0, "cherry"],
			[8, 13, 1, 1, 0, "rock"],
			[25, 24, 2, 2, 0, "tree"],
			[32, 25, 1, 1, 0, "rock"],
			[16, 22, 2, 2, 0, "cherry"],
			# H12: hay by the farm, logs, a standing stone by the stream, a stump below the plateau.
			[13, 19, 1, 2, 0, "hay"],
			[3, 26, 1, 1, 0, "logs"],
			[24, 9, 1, 1, 0, "standing_stone"],
			[30, 23, 1, 1, 0, "stump"],
			# The Old Quarry (2026-11-17): six cells of the east tree line are an outcrop of rock,
			# with the mine's mouth cut through it.
			[38, 5, 2, 3, 0, "quarry_rock"],
			[38, 6, 2, 1, 0, "mine_mouth"],
		],
		"spawns": [
			# Wood (2026-11-17): four fallen branches and two old stumps, off the road and clear of
			# the crowns. They are back each morning.
			[23, 15, 1, 1, "branch"],
			[36, 3, 1, 1, "branch"],
			[14, 25, 1, 1, "branch"],
			[17, 7, 1, 1, "branch"],
			[3, 17, 1, 1, "stump"],
			[31, 24, 1, 1, "stump"],
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
			[37, 5, 1, 1, "rubble"],
			[36, 7, 1, 1, "rubble"],
			[34, 6, 4, 1, "rails"],
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
			# Wood (2026-11-17): three fallen branches and an old stump in the clearings.
			[22, 7, 1, 1, "branch"],
			[15, 7, 1, 1, "branch"],
			[26, 9, 1, 1, "branch"],
			[30, 5, 1, 1, "stump"],
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
	# Willowmere (2026-11-17, tests/world/willowmere_test.gd): a marsh east of Hearthvale, the
	# size of the North Fields. Water is the base and blocks, and so do the deep reeds; the
	# boardwalks are the paths between four patches of land: the west bank where the walk from
	# Hearthvale comes in, the island with the ruined fisher's hut, an islet to its north
	# (cattails) and one to its south (bog mushrooms), and the east bank (marsh berries). Behind
	# two rows of willows in the north-east, one cell of ground between them and the woods
	# leads to a nook with a heart piece. Props stand on the marsh's own ground.
	"willowmere": {
		"scene": "res://world/areas/willowmere/willowmere.tscn",
		"size": Vector2i(40, 30),
		"base": "water",
		"prop_ground": "marsh_solid",
		"blocks": [
			# Reed beds, laid first: land and boards go over them and leave a ring of reeds.
			[15, 2, 11, 5, 0, "reeds"],
			[14, 9, 13, 11, 0, "reeds"],
			[13, 22, 15, 6, 0, "reeds"],
			[29, 7, 9, 15, 0, "reeds"],
			[2, 9, 6, 12, 0, "reeds"],
			[2, 3, 5, 3, 0, "reeds"],
			[8, 23, 4, 3, 0, "reeds"],
			[30, 23, 6, 3, 0, "reeds"],
			# Land: the west bank, the hut's island, the north islet, the south islet, the east bank.
			[2, 10, 5, 10, 0, "marsh"],
			[16, 10, 9, 8, 0, "marsh"],
			[17, 3, 7, 3, 0, "marsh"],
			[15, 23, 11, 4, 0, "marsh"],
			[31, 9, 7, 12, 0, "marsh"],
			# The nook behind the willows, and the one cell of ground that leads round them.
			[31, 2, 7, 3, 0, "marsh"],
			[30, 5, 7, 2, 0, "willow"],
			[31, 7, 6, 2, 0, "willow"],
			[37, 5, 1, 4, 0, "marsh"],
			# Boardwalks: west bank to the island, island to the east bank, and north and south.
			[7, 14, 9, 2, 0, "boardwalk"],
			[25, 14, 6, 2, 0, "boardwalk"],
			[20, 6, 2, 4, 0, "boardwalk"],
			[20, 18, 2, 5, 0, "boardwalk"],
			# Woods round the edges; the walk from Hearthvale comes in through a gap in the west.
			[0, 0, 40, 2, 0, "tree"],
			[0, 28, 40, 2, 0, "tree"],
			[0, 2, 2, 26, 0, "tree"],
			[38, 2, 2, 26, 0, "tree"],
			[0, 14, 2, 2, 0, "marsh"],
			# The ruined fisher's hut, in the island's north-west corner (clear of where the north
			# walk lands): a fallen roof over its front wall.
			[16, 10, 4, 3, 0, "ruin"],
			# Marsh lantern posts where the boards meet land (dark until Henrik's favour).
			[6, 13, 1, 1, 0, "marsh_lantern"],
			[16, 13, 1, 1, 0, "marsh_lantern"],
			[24, 13, 1, 1, 0, "marsh_lantern"],
			[31, 13, 1, 1, 0, "marsh_lantern"],
			[22, 10, 1, 1, 0, "marsh_lantern"],
			[19, 17, 1, 1, 0, "marsh_lantern"],
			# Willows and mossy stones about the land.
			[3, 11, 1, 1, 0, "willow"],
			[4, 18, 1, 1, 0, "willow"],
			[23, 16, 1, 1, 0, "willow"],
			[33, 19, 1, 1, 0, "willow"],
			[36, 12, 1, 1, 0, "willow"],
			[16, 25, 1, 1, 0, "willow"],
			[24, 24, 1, 1, 0, "willow"],
			[5, 16, 1, 1, 0, "mossy_rock"],
			[17, 16, 1, 1, 0, "mossy_rock"],
			[35, 17, 1, 1, 0, "mossy_rock"],
			[20, 26, 1, 1, 0, "mossy_rock"],
			[36, 3, 1, 1, 0, "mossy_rock"],
		],
		"spawns": [
			# Fireflies over the land and the water (out from dusk).
			[4, 13, 1, 1, "firefly"],
			[18, 15, 1, 1, "firefly"],
			[23, 12, 1, 1, "firefly"],
			[33, 12, 1, 1, "firefly"],
			[20, 24, 1, 1, "firefly"],
			[34, 4, 1, 1, "firefly"],
			[11, 13, 1, 1, "firefly"],
			[27, 16, 1, 1, "firefly"],
		],
		"decor": [
			# Cattails at the water's edge, lily pads on the open pools.
			[2, 10, 1, 1, "cattail"],
			[6, 19, 1, 1, "cattail"],
			[16, 17, 1, 1, "cattail"],
			[24, 10, 1, 1, "cattail"],
			[31, 20, 1, 1, "cattail"],
			[17, 5, 1, 1, "cattail"],
			[23, 3, 1, 1, "cattail"],
			[15, 26, 1, 1, "cattail"],
			[25, 23, 1, 1, "cattail"],
			[37, 20, 1, 1, "cattail"],
			[10, 7, 1, 1, "lily"],
			[12, 19, 1, 1, "lily"],
			[27, 5, 1, 1, "lily"],
			[9, 22, 1, 1, "lily"],
			[34, 26, 1, 1, "lily"],
			[5, 7, 1, 1, "lily"],
			[28, 18, 1, 1, "lily"],
			# Two holes through the hut's fallen roof.
			[17, 10, 1, 1, "ruin_hole"],
			[19, 11, 1, 1, "ruin_hole"],
		],
		"scatter": {"seed": 23, "kinds": [["moss", 9], ["tuft", 4], ["pebbles", 2], ["mushroom", 1], ["flowers_blue", 1]]},
	},
	# The Homestead (2026-11-17, tests/world/homestead_test.gd): the old farmstead west of
	# Hearthvale, the size of the North Fields, drawn as the plan drew it
	# (docs/progress/homestead-plan.md). The lane from the village comes in through the east
	# woods (">", rows 14 and 15) and runs west as the road ("="), with a path up to the
	# farmhouse's door. The farmhouse (H, its door D) is laid by the blocks below, with the
	# village's own house tiles. "F" is the field's clear corner; the whole field is the
	# FarmPlot node in the scene, (22..33, 17..22). "~" is the pond. "T" is the woods round the
	# edge and "t" an old tree left standing. The other letters are the land's overgrowth,
	# spawn markers named by "marks": "w" weeds, "b" a bush, "l" a fallen log, "s" an old
	# stump, "o" a rock, "O" a boulder, "@" a great boulder. The quote marks are the meadow's tall grass, which
	# is phase 3's: until then they are grass like any other.
	"homestead": {
		"scene": "res://world/areas/homestead/homestead.tscn",
		"size": Vector2i(40, 30),
		"sketch": [
			"TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT",
			"TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT",
			"TT.........ww...........s.............TT",
			"TT..\".\"..\".\".\"..................o..t..TT",
			"TT.o.\".l\".\".\".b.t.............o...t.t.TT",
			"TT..\"..\".\".\".\"..s.............o...l.w.TT",
			"TT...............oww.......l..........TT",
			"TT............O.w..............ww...w.TT",
			"TT...w....w........w......HHHHHH..t.l.TT",
			"TT.t.O..oOs..........w.t..HHHHHH...ow.TT",
			"TT.s...b....O...O......wsbHHHHHH......TT",
			"TT.w............o.b....o..HHDHHH......TT",
			"TT........w...l..o.s........=.........TT",
			"TT.O.....w.....w............=.........TT",
			"TT.s...O..w.l.......==================>>",
			"TT...............w..==================>>",
			"TT....................................TT",
			"TT.....b......o....b..FFFFFFwwwwww....TT",
			"TT.t..................FFFFFFwwwsww....TT",
			"TT.ow.......o.O.b.....FFFFFFwbwbww..o.TT",
			"TT.b.w....wl....o...s.wowwblowwbww....TT",
			"TT..~~~~~~w@.@........wwwwwlwwooww..b.TT",
			"TT..~~~~~~.....b...l..wsbwwwwwwwwo....TT",
			"TT..~~~~~~..wo........................TT",
			"TT..~~~~~~....s........b............t.TT",
			"TT.s..@.s.w...wo....o..sw.......ow.t..TT",
			"TT..........t.........................TT",
			"TT....................................TT",
			"TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT",
			"TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT",
		],
		"legend": {
			"T": ["tree", 0], "t": ["tree", 0], "~": ["water", 0], "=": ["path", 0], ">": ["path", 0],
		},
		"marks": {
			"w": "weeds", "b": "bush", "l": "log", "s": "farm_stump",
			"o": "rock", "O": "boulder", "@": "great_boulder",
		},
		"blocks": [
			# The farmhouse: thatch over a half-timbered upper floor and a ground floor, as the
			# village's cottages are, with its door where theirs is.
			[26, 8, 6, 2, 3, "roof_thatch"],
			[26, 10, 6, 1, 3, "wall_upper"],
			[26, 11, 6, 1, 3, "wall"],
			[28, 11, 1, 1, 0, "door"],
		],
		"decor": [
			# Its chimney (as the cottages': on the roof, with its smoke), flowers gone wild
			# along its front, and lily pads on the pond.
			[30, 8, 1, 1, "chimney"], [30, 7, 1, 1, "smoke"],
			[26, 12, 2, 1, "flowers_yellow"],
			[30, 12, 2, 1, "flowers_red"],
			[5, 22, 1, 1, "lily"],
			[8, 23, 1, 1, "lily"],
			[6, 24, 1, 1, "lily"],
		],
		"scatter": {"seed": 31, "kinds": [["tuft", 12], ["flowers_yellow", 2], ["flowers_red", 1], ["flowers_blue", 1], ["pebbles", 2], ["mushroom", 1]]},
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
			# Wood (2026-11-17): three fallen branches and two old stumps about the field.
			[24, 10, 1, 1, "branch"],
			[7, 3, 1, 1, "branch"],
			[17, 19, 1, 1, "branch"],
			[3, 21, 1, 1, "stump"],
			[36, 17, 1, 1, "stump"],
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
	# The Old Quarry's entrance hall: the way out, the lift, the first ladder down, two rocks to try a pickaxe on.
	"quarry": {
		"scene": "res://world/areas/quarry/quarry.tscn",
		"size": Vector2i(15, 9),
		"base": "cave_wall",
		"prop_ground": "cave_solid",
		"sketch": [
			"###############",
			"#.....T...T...#",
			"#..=======L...#",
			">.............#",
			"#.............#",
			"#.............#",
			"#....o...o..v.#",
			"#..T.........##",
			"###############",
		],
		"blocks": [
			[0, 3, 1, 1, 0, "mine_mouth"],
		],
	},
	# Floor 1, The Cut.
	"quarry_1": {
		"scene": "res://world/areas/quarry_1/quarry_1.tscn",
		"size": Vector2i(20, 11),
		"base": "cave_wall",
		"prop_ground": "cave_solid",
		"sketch": [
			"####################",
			"#......o.<...o....##",
			"#......o...........#",
			"#..oo........##..o.#",
			"#..o....s....##..o.#",
			"#...........oo.....#",
			"#.o......o.......s.#",
			"#.oo.....o....o....#",
			"#..................#",
			"##................##",
			"####################",
		],
		"blocks": [
			[9, 0, 1, 1, 0, "ladder_up"],
		],
	},
	# Floor 2, The Galleries.
	"quarry_2": {
		"scene": "res://world/areas/quarry_2/quarry_2.tscn",
		"size": Vector2i(20, 11),
		"base": "cave_wall",
		"prop_ground": "cave_solid",
		"sketch": [
			"####################",
			"#......<.###...o...#",
			"#.....o..o....s..o.#",
			"#.oo.....###.......#",
			"#.o...s..###..oo...#",
			"#........###..o....#",
			"#....o...###.....o.#",
			"#...oo...###.......#",
			"#.s...........o....#",
			"#........###..o....#",
			"####################",
		],
		"blocks": [
			[7, 0, 1, 1, 0, "ladder_up"],
		],
	},
	# Floor 3, The Old Face.
	"quarry_3": {
		"scene": "res://world/areas/quarry_3/quarry_3.tscn",
		"size": Vector2i(20, 11),
		"base": "cave_wall",
		"prop_ground": "cave_solid",
		"sketch": [
			"####################",
			"#......o<.o...s....#",
			"#.............o....#",
			"#...###########.oo.#",
			"#.o.###########....#",
			"#ooo###########..s.#",
			"#...###########o...#",
			"#.o.###########o...#",
			"#......s...o.......#",
			"#...o......o....s.o#",
			"####################",
		],
		"blocks": [
			[8, 0, 1, 1, 0, "ladder_up"],
		],
	},
	# Floor 4, The Coal Seam.
	"quarry_4": {
		"scene": "res://world/areas/quarry_4/quarry_4.tscn",
		"size": Vector2i(20, 11),
		"base": "cave_wall",
		"prop_ground": "cave_solid",
		"sketch": [
			"####################",
			"#....oo.<....##....#",
			"#....oo......##..b.#",
			"#.....oo...........#",
			"#......oo..........#",
			"#..b....oo.....o...#",
			"#........oo........#",
			"#.........oo....##.#",
			"#..........o....##.#",
			"#.......b..........#",
			"####################",
		],
		"blocks": [
			[8, 0, 1, 1, 0, "ladder_up"],
		],
	},
	# Floor 5, The Crossing.
	"quarry_5": {
		"scene": "res://world/areas/quarry_5/quarry_5.tscn",
		"size": Vector2i(20, 11),
		"base": "cave_wall",
		"prop_ground": "cave_solid",
		"sketch": [
			"####################",
			"#######....o.#######",
			"#######.b.o..#######",
			"#######.o....#######",
			"#<...o...oo....o..g#",
			"#....o...oo....o...#",
			"#........o.........#",
			"#######o.....#######",
			"#######...b..#######",
			"#######.oo.o.#######",
			"####################",
		],
		"blocks": [
			[1, 3, 1, 1, 0, "ladder_up"],
		],
	},
	# Floor 6, The Ledges.
	"quarry_6": {
		"scene": "res://world/areas/quarry_6/quarry_6.tscn",
		"size": Vector2i(20, 11),
		"base": "cave_wall",
		"prop_ground": "cave_solid",
		"sketch": [
			"####################",
			"#^^^^^g^^^####^^g^^#",
			"#^^^^^^^^^####^^^^^#",
			"##--S-----####--S--#",
			"#<....o........o...#",
			"#..oo......b.......#",
			"#..o....oo.....oo..#",
			"#.......o......o...#",
			"#.o...........b....#",
			"#.oo....o..o.......#",
			"####################",
		],
		"blocks": [
			[1, 3, 1, 1, 0, "ladder_up"],
		],
	},
	# Floor 7, The Dark Drift.
	"quarry_7": {
		"scene": "res://world/areas/quarry_7/quarry_7.tscn",
		"size": Vector2i(20, 11),
		"base": "cave_wall",
		"prop_ground": "cave_solid",
		"sketch": [
			"####################",
			"#.....o.<..#########",
			"#..........#########",
			"#######.o..#########",
			"#######....o...oo..#",
			"#######..w....o....#",
			"#######o...#####.o.#",
			"#..o.......#####...#",
			"#.o..o.....#####.w.#",
			"#.o........#####o.o#",
			"####################",
		],
		"blocks": [
			[8, 0, 1, 1, 0, "ladder_up"],
		],
	},
	# Floor 8, The Flooded Gallery.
	"quarry_8": {
		"scene": "res://world/areas/quarry_8/quarry_8.tscn",
		"size": Vector2i(20, 11),
		"base": "cave_wall",
		"prop_ground": "cave_solid",
		"sketch": [
			"####################",
			"#....~~~~~.<..o...##",
			"#....~~~~~..o......#",
			"#..o...........~~~.#",
			"#..o..w..~~~...~~~o#",
			"#.o......~~~..o~~~.#",
			"#~~~..o..~~~.......#",
			"#~~~..o.......w..o.#",
			"#~~~.....o.....o...#",
			"##......oo...~~~.w.#",
			"####################",
		],
		"blocks": [
			[11, 0, 1, 1, 0, "ladder_up"],
		],
		"decor": [
			[13, 0, 1, 1, "crystal_vein"],
			[16, 0, 1, 1, "crystal_vein"],
		],
	},
	# Floor 9, The Heart of the Quarry.
	"quarry_9": {
		"scene": "res://world/areas/quarry_9/quarry_9.tscn",
		"size": Vector2i(20, 11),
		"base": "cave_wall",
		"prop_ground": "cave_solid",
		"sketch": [
			"####################",
			"#......<.o....#..H.#",
			"#.............#....#",
			"#...oo........#ooo##",
			"#...o.....w........#",
			"#.........##....o..#",
			"#.w.......##....oo.#",
			"#......o...........#",
			"#..o...o....w...o..#",
			"#..oo......o....w..#",
			"####################",
		],
		"blocks": [
			[7, 0, 1, 1, 0, "ladder_up"],
		],
		"decor": [
			[4, 0, 1, 1, "crystal_vein"],
			[12, 0, 1, 1, "crystal_vein"],
			[17, 0, 1, 1, "crystal_vein"],
		],
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
	var blocks: Array = _sketch_blocks(map) + (map.get("blocks", []) as Array)
	for block: Array in blocks:
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
					layer.set_cell(cell, GreyboxTiles.SOURCE_ID, GreyboxTiles.coords(str(map.get("prop_ground", "solid_ground")), block[4]))
					props[cell] = _prop(kind, x - int(block[0]), y - int(block[1]))
					continue
				var detail: String = _detail(kind, x - int(block[0]), y - int(block[1]), block[2], block[3])
				layer.set_cell(cell, GreyboxTiles.SOURCE_ID, GreyboxTiles.coords(detail, block[4]))
	_cave_faces(layer, size)
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
	print("tools/greybox: baked %d blocks into %s (%s)" % [blocks.size(), path, error_string(error)])
	return error


## What a sketch's characters lay on the Height layer: [kind, height]. Anything else is floor.
const SKETCH_KINDS: Dictionary = {"~": ["water", 0], "^": ["ledge", 1], "S": ["stairs", 1], "T": ["timber", 0]}
const SKETCH_BASE: String = "#"
const SKETCH_FLOOR: String = "cave_floor"
const SKETCH_ROCK: String = "o"
const SKETCH_RAILS: String = "="


## The blocks a map's "sketch" stands for, a cell each: nothing where the base shows. A map
## with a "legend" of its own lays only what the legend names; without one, the Old Quarry's
## characters are read.
func _sketch_blocks(map: Dictionary) -> Array:
	var out: Array = []
	var rows: Array = map.get("sketch", [])
	var legend: Dictionary = map.get("legend", {})
	for y: int in rows.size():
		var row: String = rows[y]
		for x: int in row.length():
			if map.has("legend"):
				if legend.has(row[x]):
					var named: Array = legend[row[x]]
					out.append([x, y, 1, 1, named[1], named[0]])
				continue
			if row[x] == SKETCH_BASE:
				continue
			var laid: Array = SKETCH_KINDS.get(row[x], [SKETCH_FLOOR, 0])
			out.append([x, y, 1, 1, laid[1], laid[0]])
	return out


## The cells of a map's "sketch" that hold `mark`, as blocks of `kind` for the Spawns or the
## Decor layer.
func _sketch_marks(map: Dictionary, mark: String, kind: String) -> Array:
	var out: Array = []
	var rows: Array = map.get("sketch", [])
	for y: int in rows.size():
		var row: String = rows[y]
		for x: int in row.length():
			if row[x] == mark:
				out.append([x, y, 1, 1, kind])
	return out


## The spawn markers a map's sketch stands for: what its "marks" name (character -> marker
## kind), or, for a sketch with no legend of its own, a rock of the quarry at every "o".
func _sketch_spawns(map: Dictionary) -> Array:
	if not map.has("legend"):
		return _sketch_marks(map, SKETCH_ROCK, GreyboxTiles.ROCK_MARKER)
	var out: Array = []
	var marks: Dictionary = map.get("marks", {})
	for mark: String in marks:
		out.append_array(_sketch_marks(map, mark, str(marks[mark])))
	return out


## A cave wall with anything but wall to its south shows its face.
func _cave_faces(layer: TileMapLayer, size: Vector2i) -> void:
	var wall: Vector2i = GreyboxTiles.coords(GreyboxTiles.CAVE_WALL)
	var face: Vector2i = GreyboxTiles.coords(GreyboxTiles.CAVE_WALL_FACE)
	for y: int in size.y - 1:
		for x: int in size.x:
			var cell: Vector2i = Vector2i(x, y)
			var south: Vector2i = layer.get_cell_atlas_coords(cell + Vector2i.DOWN)
			if layer.get_cell_atlas_coords(cell) == wall and south != wall and south != face:
				layer.set_cell(cell, GreyboxTiles.SOURCE_ID, face)


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
## - a "boardwalk" lays its planks across the way it runs; "reeds" mix their two pictures; a
##   "ruin" is fallen roof with the front wall along its bottom row (Willowmere)
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
		"boardwalk":
			# Planks lie across the way it runs.
			return "boardwalk" if width >= height else "boardwalk_ns"
		"reeds":
			return "reeds" if _cell_hash(Vector2i(dx, dy), 31) % 3 != 0 else "reeds_b"
		"ruin":
			return "ruin_wall" if dy == height - 1 else "ruin_top"
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
	# The Old Quarry's sketches draw their rails; a sketch with a legend of its own has none.
	var rails: Array = [] if map.has("legend") else _sketch_marks(map, SKETCH_RAILS, "rails")
	for block: Array in rails + (map.get("decor", []) as Array):
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
		var under: Vector2i = height_layer.get_cell_atlas_coords(cell)
		if (under.y != GreyboxTiles.ROW_GROUND and under != GreyboxTiles.coords("marsh")) or avoid.has(cell):
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
	var blocks: Array = _sketch_spawns(map) + (map.get("spawns", []) as Array)
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
		if not GreyboxTiles.is_marker(kind):
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
