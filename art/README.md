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
| Trees | `world/tiles/scenery.png` | 280x48: 7 cells of 40x48 (broadleaf, oak, pine, cherry, cherry b, willow, willow b), each tree 32x40 at (4, 4) in its cell, clear padding round it | the trunk's foot at (16, 37) of the 32x40 |
| Wall faces, pillar, roof ridges | `world/tiles/relief.png` | 96x112, places in `world/tiles/relief_atlas.gd` | as there |
| Buildings | tiles of the atlas (houses rows 16 to 20, buildings 28 to 30) and `relief.png` | repaint the tiles in place | the cell |
| Crops, soil | `crops.png` 16x16 x13; `soil.png` 16x16 x4 | + flash row | the cell's top-left |
| Items | `items.png` 16x16 x74 | + flash row; one icon per item | the cell's top-left |
| Placed things, furnishings, rocks, breakables, forage | `placed`, `crafted`, `rocks`, `breakables`, `forage`, 16x16 | + flash row | the cell's top-left |
| Title | `ui/title/backdrop.png` 640x360 | the keep's window, the stars and the cherry trees must stay where `ui/title_picture.gd` says | the screen |
| UI | boxes, bars, the energy bar and the fonts are made in code | | |

**Villager markers** (`palettes/villager_markers.gpl`), recoloured for each villager by the game:
robe `#FF00FF`, robe shade `#800080`, hair `#00FFFF`, hair shade `#008080`. Use them exactly, and no
colour within two steps of them anywhere else on the sheet.

**Drawn in code, not in a PNG:** shadows and soft edges, sparks, bursts, the pour and the ring, the
sword's blade, lights and darkness, the water's movement and reflections, mist, fireflies, chests,
dungeon doors, pickups, signposts, plates and push blocks, the boxes' frames, the title's stars and
window, a building site's string and pegs, and lit windows. Their colours are in the code.

**Two colours in code match the art:** the grass's soft fringe (`HeightShading.fringe_color()`) and
the title's sky above the picture (`TitlePicture.SKY_TOP`). Repaint the grass or the sky and change
these too, or a seam shows.

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
