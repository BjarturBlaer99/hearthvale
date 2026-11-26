# Hearthvale's art

Since 2026-11-19 every picture the game shows is a PNG, and the PNG is the source: edit it in
Aseprite, or replace it with art you make or bring (AI-made art included). This folder holds what the
game does not load: your `.aseprite` files, the palettes, the list of sheets the tests check, and this
how-to. Godot ignores it (`.gdignore`).

```
art/
  README.md           this how-to
  sheets.json         every art PNG: size, frames in order, rows, flash row, pivot (tests read it)
  palettes/
    hearthvale.gpl    the master palette: the 256 colours the art uses most
    <sheet>.gpl       each sheet's own colours, exactly
    villager_markers.gpl   the four colours villagers are painted in
  aseprite/           your .aseprite files, named after their PNG (player_sheet.aseprite)
  packs/<pack>/       an art pack, untouched, with its licence (docs/ASSETS.md says which, and on
                      what terms); never edit or run anything in it: cut from it with a script
```

## The workflow

1. Open (or make) the `.aseprite` file in `art/aseprite/`, with `palettes/hearthvale.gpl` loaded.
2. Export the PNG over the one the game loads (the paths are in `sheets.json`).
3. Check it: `godot --headless --path . --import`, then the art tests
   (`godot --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd --add res://tests/art --ignoreHeadlessMode --continue`).
   A wrong size, a missing frame or a missing flash row fails a test.
4. Record where it came from in `docs/ASSETS.md`.

## Every picture

- **PNG, RGBA, transparent background, drawn at 1x** (one pixel is one game pixel).
- **No anti-aliasing and no half-clear pixels in sprites.** (The tiles and trees have a few soft
  edges; keep to what is there.)
- **Exact sizes, frames in the order `sheets.json` lists them.** Never move a frame or a tile; add new
  ones at the end, and tell the code (a frame name in the script that draws it).
- **Hearthvale's look:** colours from `hearthvale.gpl`; dark outlines in a deep shade of what they
  surround (not black); light from the top left (the north-west), shadows to the south-east. Never
  another game's art.
- **The flash row:** every sheet in `gameplay/art/` is two frames tall: the frames, and under them the
  same frames as white silhouettes (the hit flash). In Aseprite: duplicate the frames' layer, lock its
  alpha, fill it white, and place it one frame height lower. The hero's sheet has no flash row.
- **The pivot** is the point of a frame the game puts on its node (a character's feet, a cell's
  top-left). A picture drawn a pixel lower stands a pixel lower (it still collides where it always
  did).

## Each kind of asset

| Kind | File | Export | Pivot |
|---|---|---|---|
| Hero | `gameplay/player/player_sheet.png` | 400x96: 25 frames of 16x32 a row, rows facing down, up, left (right is the left row mirrored). Columns: idle, blink, walk 1 to 6, windup, slash, follow, hold (seen from the front in every row), fallen, breathe, hurt, run 1 to 6, raise, strike, pour, reach. No flash row. | his feet, (8, 32): soles on the last row, centred |
| Tools in his hands | `gameplay/art/held_tools.png` | 2280x112: 57 frames of 40x56 + flash row, order in `sheets.json` | his feet at (20, 40); the fists where his work pose's hands are |
| Villagers | `gameplay/art/villager.png` | 96x64: 6 frames of 16x32 (plain, bearded, their breathe, their blink) + flash row; robe and hair in the marker colours (below) | feet on the last row |
| Slime, wisp, bat | `slime.png`, `wisp.png`, `bat.png` | 16x16, 3 frames each + flash row | slime (8, 15); wisp (8, 18); bat (8, 8) |
| Goblin | `goblin.png` | 16x24, 5 frames + flash row; side frames face left | (8, 23) |
| The Warden, the Shade | `warden.png`, `shade.png` | 32x40, 4 and 3 frames + flash row | Warden (16, 39); Shade (16, 42) |
| Animals, critters | `animals.png` 24x20 x8; `critters.png` 16x16 x8 | + flash row; face left | animals (12, 18); the hen (8, 14) |
| Tiles | `world/tiles/greybox_tiles.png` | 128x544: 8 x 34 tiles of 16x16. Rows are listed in `world/tiles/greybox_tiles.gd`. Repaint a tile in its place; add new tiles at the end. Rows 12 and 27 are markers (never seen). Row 11 is the water's frames. | the cell |
| Trees | `world/tiles/scenery.png` | 392x56: 7 cells of 56x56 (broadleaf, oak, pine, cherry, cherry b, willow, willow b), each picture 48x48 at (4, 4) in its cell, clear padding round it; a smaller tree stands at the picture's foot | the trunk's foot at (24, 45) of the 48x48 |
| Wall faces, pillar, roof ridges | `world/tiles/relief.png` | 96x112, places in `world/tiles/relief_atlas.gd` | as there |
| Ground details | `world/tiles/ground_details.png` | 416x16: 26 frames of 16x16 in the order `sheets.json` lists them, clear background, no flash row (below) | the cell's top-left |
| The ground's edges | `world/tiles/ground_edges.png` | 304x160, places in `world/tiles/edge_atlas.gd`: rows 0 to 7 are grass lapping over a path at heights 0 to 7 (columns 0 to 14: the sides it is on, north 1 + east 2 + south 4 + west 8, less one; columns 15 to 18: a corner alone, north-east, south-east, south-west, north-west); row 8 the water's bank, the same nineteen; row 9 a cliff's face, 16x12, in earth and then in cut stone. Clear where the ground under a piece shows | the cell's top-left |
| Buildings | tiles of the atlas (houses rows 16 to 20, buildings 28 to 30) and `relief.png` | repaint the tiles in place | the cell |
| Crops, soil | `crops.png` 16x16 x13; `soil.png` 16x16 x4 | + flash row | the cell's top-left |
| Items | `items.png` 16x16 x74 | + flash row; one icon per item | the cell's top-left |
| Placed things, furnishings, rocks, breakables, forage | `placed`, `crafted`, `rocks`, `breakables`, `forage`, 16x16 | + flash row | the cell's top-left |
| Title | `ui/title/backdrop.png` 640x360 | the keep's window, the stars and the cherry trees must stay where `ui/title_picture.gd` says | the screen |
| UI: frames, dial | `ui/art/ui_parts.png` 104x32: four gold corners of 7, the top, bottom, left and right edges (6 deep, 16 long, outline outermost), the dial 32x32; places in `ui/ui_parts.gd` | each piece's top-left |
| UI: the rest | the hearts, bars, slots and the dial's hand are drawn in code, in the UI sheet's colours; the fonts are made in code | | |

**Ground details** (`world/tiles/ground_details.png`, the warm-ground plan, step 3) are small
still touches drawn on the ground under everything else: clover and flowers on grass, pebbles on
the path, cracks and moss in the dungeons, grit in the quarry. Which cell gets one is a fixed rule
of the game (`GroundDetails`), and how many and which kinds each ground gets are numbers in
`data/rules/ground_detail.json`, so the sheet only says what each looks like. **To swap in your
own sheet** (PixelLab or any other): keep it 416x16, 26 frames of 16x16 on a clear background, in
the order of `sheets.json` (frame 0 clover, 1 clover_b, ... 25 marsh_sprig; the first ten are
grass, then six for the path, four for stone, three for the quarry, three for the marsh). Keep
each detail small and quiet (48 pixels at most), off the cell's outer row of pixels, in the colours
of the ground it lies on (the atlas's own: `art/palettes/greybox_tiles.gpl`), with nothing red, no
mushroom, berry, coin or stone the size of a rock, and no tuft as tall as the grass the sword cuts:
nothing may look like something to pick up, break or cut. Lit from the north-west, as the rest; a
detail named in `"unmirrored"` is never drawn mirrored, the others are, half the time. Export over
the PNG, then import and run the art tests (`tests/art/ground_details_sheet_test.gd` checks size,
colours, quietness and edges). To have fewer or more, change `"chance"` in the rules, not the sheet.

**Villager markers** (`palettes/villager_markers.gpl`), recoloured for each villager by the game:
robe `#FF00FF`, robe shade `#800080`, hair `#00FFFF`, hair shade `#008080`. Use them exactly, and no
colour within two steps of them anywhere else on the sheet.

**Drawn in code, not in a PNG:** shadows and soft edges, sparks, bursts, the pour and the ring, the
sword's blade, lights and darkness, the water's movement and reflections, mist, fireflies, chests,
dungeon doors, pickups, signposts, plates and push blocks, the hearts, the energy bar, the item bar's slots, the dial's hand, the title's stars and
window, a building site's string and pegs, and lit windows. Their colours are in the code.

**Colours in code that match the art:** the ground's colour at each height
(`GreyboxTiles.GROUND_COLORS`: the grass tiles' own colours, which a test checks, and which tint
the details on raised grass), the water's glints, foam and swell (`WaterSurface`) and the title's
sky above the picture (`TitlePicture.SKY_TOP`). Repaint the grass, the water or the sky and change
these too, or a seam shows. The grass's fringe over a path, the water's bank and the cliff faces
are pictures since 2026-11-25 (`ground_edges.png`): repaint the grass and repaint its fringe
pieces in the same colours (`tests/art/ground_edges_sheet_test.gd` checks them).

**Art from a pack** (`docs/progress/farm-look-plan.md`): the ground, the trees, the ground details
and the ground's edges (phase A), and the buildings, interiors and props (phase B: the atlas's
house, furniture and prop rows, `relief.png`, `placed`, `crafted`, `rocks`, `breakables`, `forage`
and `torch`, but the sprinkler and the hand) are Ninja Adventure's (CC0), fitted by cutting, moving, mirroring and
recolouring. Their colours are the pack's own, not `hearthvale.gpl`'s older ones (the master palette
lists both while the switch is under way), their outlines are the pack's near black, and the grass
and the marsh are flat colour. Keep a new piece to one style: the pack's, where the pack has it.

## Asking an AI tool

Give it the size, the frame count and order, the view, and the palette. For example:

> 16x32 pixel-art character sprite sheet, top-down three-quarter view, 25 frames per row in this
> order: idle, blink, walk 1-6, ..., three rows facing down, up and left; transparent background; no
> anti-aliasing; 1px dark outline in a deep shade of the colour inside it; limited palette (attached);
> warm light from the top left; feet on the bottom row, centred.

> 16x16 seamless top-down pixel-art tile of short grass, the same palette, no outline on the edges that
> meet the next tile, soft dithering.

Then fit it to the sheet (size, order, the flash row), run the art tests, and record it in
`docs/ASSETS.md` with the tool, your plan, the date and the tool's licence terms on that date.
