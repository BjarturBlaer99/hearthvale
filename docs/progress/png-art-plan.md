# Art as PNG — the plan

The user's request, 2026-11-19: move Hearthvale's art to PNG as the source of truth, so art can be
edited in Aseprite or replaced with AI-made pixel art (for example PixelLab). Bake every art asset one
last time, keep those PNGs as the editable source, retire the art tools, and keep the game looking
exactly the same. Sound and fonts stay made in code. Two steps: this plan (no code or art changes),
then the switch, each stopping for the user's approval. **The plan was approved as written on
2026-11-19** (all eight decisions as recommended: the tool polish's steps 3 and 4 come first).

## 0. In short

- **The 27 PNGs the game shows stay where they are** and become the source. Nothing in the game's
  code or scenes changes path. A new top folder, `art/`, holds what isn't loaded by the game: your
  `.aseprite` files, the palettes, the sheet list and the how-to.
- **Six painting tools retire:** `make_player_sprite.gd`, `make_sprites.gd`, `make_scenery.gd`,
  `make_relief.gd`, `make_title.gd` and `tools/greybox/make_tile_texture.gd`. They move to
  `tools/retired/`, which Godot ignores, so nothing can run them. The font tool and the sound tool stay.
- **Map work keeps working:** `build_tileset.gd` and `build_maps.gd` paint nothing. They read the tile
  atlas PNG and the layout in `GreyboxTiles`, and stay as they are.
- **A sheet list, `art/sheets.json`,** says each PNG's size, frame size, frame names in order, rows
  and pivot. Tests check every PNG against it, so a wrong export fails a test instead of the game.
- **Proof it looks the same:** the baked PNGs are byte for byte the ones in the repo today, and every
  capture shot and film is compared pixel by pixel before and after.

## 1. Inventory

### The tools that paint, and what they paint

| Tool | Paints | Size | Frames |
|---|---|---|---|
| `tools/art/make_player_sprite.gd` | `gameplay/player/player_sheet.png` | 400x96 | 25 columns x 3 rows of 16x32 (rows: down, up, side facing left) |
| `tools/art/make_sprites.gd` (`SPRITES`) | 21 sheets in `gameplay/art/` | see below | frames side by side, then the same frames as white silhouettes (the flash row) |
| `tools/art/make_sprites.gd` (`HELD`) | `gameplay/art/held_tools.png` | 2280x112 | 57 frames of 40x56, flash row |
| `tools/art/make_scenery.gd` | `world/tiles/scenery.png` | 280x48 | 7 cells of 40x48, a 32x40 tree in each at (4, 4) |
| `tools/art/make_relief.gd` | `world/tiles/relief.png` | 96x112 | wall faces 16x24 and 16x16, tops 16x16, a pillar 16x28, roof ridges (`ReliefAtlas`) |
| `tools/art/make_title.gd` | `ui/title/backdrop.png` | 640x360 | one picture |
| `tools/greybox/make_tile_texture.gd` | `world/tiles/greybox_tiles.png` | 128x544 | 8 columns x 34 rows of 16x16 tiles (`GreyboxTiles`) |
| *stays:* `tools/art/make_font.gd` | `ui/font/hearth_font.tres`, `hearth_heading.tres`, `ui/theme.tres` | | fonts stay made in code |
| *stays:* `tools/audio/make_audio.gd` | `audio/` | | sound stays made in code |

**The sheets of `make_sprites.gd`** (frame size, frames; the PNG is frames x width wide and two
frames tall, the second row the white flash):

| Sheet | Frame | Frames | Notes |
|---|---|---|---|
| `slime.png` | 16x16 | 3 | rest, wide, hop |
| `wisp.png` | 16x16 | 3 | a, b, flare |
| `bat.png` | 16x16 | 3 | rest, up, down |
| `goblin.png` | 16x24 | 5 | front, front_draw, back, side, side_draw |
| `warden.png` | 32x40 | 4 | stand, step, gaze, stunned |
| `villager.png` | 16x32 | 6 | 2 drawn + breathe and blink of each; **marker colours** |
| `items.png` | 16x16 | 74 | every item's icon |
| `soil.png` | 16x16 | 4 | bare, bare_b, tilled, watered |
| `crops.png` | 16x16 | 13 | seeded, sprout, withered, then each crop growing and ripe |
| `forage.png` | 16x16 | 12 | each forage spot full and picked |
| `crystal.png` | 16x16 | 3 | red, blue, white |
| `dummy.png` | 16x24 | 1 | |
| `brambles.png` | 16x16 | 1 | |
| `rocks.png` | 16x16 | 11 | the mine's rocks, ladder, lift, the land's rock, boulder, great boulder |
| `crafted.png` | 16x16 | 9 | the furnishings |
| `breakables.png` | 16x16 | 8 | grass, cut grass, pot, branch, stump, weeds, bush, log |
| `critters.png` | 16x16 | 8 | the hen (4), butterflies (4) |
| `animals.png` | 24x20 | 8 | sheep and cow, standing, walking, grazing, blinking |
| `torch.png` | 16x24 | 3 | unlit, two flames |
| `shade.png` | 32x40 | 3 | drift_a, drift_b, bound |
| `placed.png` | 16x16 | 25 | the fifteen placeables and their joins, ages and lit lamp |
| `held_tools.png` | 40x56 | 57 | hoe, pickaxe, can (plain, copper, iron) and sprinkler, by facing and pose |

"Made" frames (a villager's breath and blink, a hen's blink, the copper and iron tools, a sapling's
ages) are ordinary frames in the PNG: after the switch they are drawn like any other.

### What depends on the pictures (and stays in code)

- **Frame names and order:** each script names its sheet's frames in a dictionary (`Enemy.SLIME_FRAMES`,
  `Boss.FRAMES`, `Villager.FRAMES`, `ItemIcons.FRAMES`, `Breakable.FRAMES`, `Rock.FRAMES`,
  `Furnishing.FRAMES`, `PlacedArt.FRAMES`, `Animal.FRAMES`, `Critter.FRAMES`, `FarmPlot.FRAMES` and
  `CROP_FRAMES`, `ForageSpot.FRAMES`, `CrystalSwitch.FRAMES`, `Torch.FRAMES`, `ShadeBoss.FRAMES`,
  `HeldTools`, `PlayerAnimator`'s columns). Today a test checks each against the tool; after the
  switch, against `art/sheets.json`.
- **Pivots:** where a frame is drawn from is in each script (below, in the how-to). A frame drawn
  with its feet elsewhere stands in the wrong place but still collides where it always did.
- **The flash:** `SpriteSheet.draw(..., white)` reads the sheet's second row. Every sheet of
  `gameplay/art/` needs its white row; the hero's sheet has none (he is tinted instead).
- **Villager recolouring:** `SpriteSheet.recoloured()` swaps four marker colours for each villager's
  robe and hair (§5).
- **The tile atlas** (`GreyboxTiles`): every tile's place is data. `build_tileset.gd` gives each place
  its height, ramp and solidity; the maps name tiles by place; `building_art.gd` and the buildings'
  data (`look`) name blocks of places; rows 12 and 27 are spawn markers (never seen, but their places
  are data). Row 11 is the water's frames, read with the water's shader.
- **`Scenery`** stands each tree up from its cell in `scenery.png` by `SceneryAtlas.FOOT` (16, 37).
- **`WallRelief`, `Scenery.build_stone()`** read `relief.png` by `ReliefAtlas`'s places.
- **`HeightShading`** draws the soft edges and cast shadows in code; its grass fringe is a colour
  in code, warmed by `PixelGrade.warm()` to match the baked grass. **Repaint the grass and the fringe
  may no longer match** (flagged below).
- **The title** (`TitlePicture`): the stars, the keep's window and the cherry trees' feet are pixel
  places in code; `TitleBackdrop` draws what moves over the picture there. Repaint the picture and
  those places must still be stars, a window and trees. The sky above the picture is
  `PixelGrade.warm(TitlePicture.SKY_TOP)`.
- **`PixelGrade`** (§4).

**Drawn in code, and staying in code:** soft shadows (`SoftShadow`), cast shadows and soft edges
(`HeightShading`), bursts, sparks, the pour and the ring (`Burst`, `Pour`, `Ripple`), the sword's
blade and trail (`Sword`), lights and darkness (`AreaLighting`, `Ambience`), the water's movement,
foam and reflections (`WaterSurface`, `Reflections`, shaders), mist (`Mist`), fireflies, the
vignette, the boxes' frames (`PanelFrame`), the energy bar, villager recolouring, the title's stars,
window and petals, the hit flash (it reads the white row), the hero's hurt tint, the walking bob and
the crowns' fading. Chests, dungeon doors, pickups, signposts, plates and push blocks are drawn in
code with `PixelGrade.INK` outlines: they have no PNG.

## 2. Where the art lives

**Recommended: the PNGs stay where the game loads them** (`gameplay/art/`, `gameplay/player/`,
`world/tiles/`, `ui/title/`). They are the source: edit or replace them there, and Godot re-imports
them. Moving them would change dozens of paths in code, scenes and `.import` files and gain nothing.

A new folder `art/` (with a `.gdignore`, so Godot neither imports nor exports anything in it):

```
art/
  README.md            the how-to (section 12), for you
  sheets.json          every PNG's size, frames, rows and pivot (the tests read it)
  palettes/
    hearthvale.gpl     the master palette (section 7)
    <sheet>.gpl        each sheet's own exact colours
  aseprite/            your .aseprite files, named as their PNG (hero.aseprite -> player_sheet.png)
```

You keep the `.aseprite` file in `art/aseprite/` and export its PNG over the one the game loads.

## 3. The tools

- **Retire, moved to `tools/retired/`** (with a `.gdignore`, so Godot never compiles them and
  `-s res://tools/retired/...` cannot run; git history keeps them and the folder keeps them readable
  as a record of how each picture was drawn): `make_player_sprite.gd`, `make_sprites.gd`,
  `make_scenery.gd`, `make_relief.gd`, `make_title.gd`, `tools/greybox/make_tile_texture.gd`, and
  their `.uid` files. A `README.md` there says they are retired and out of date the moment a PNG is
  edited.
- **Stay, unchanged:** `build_tileset.gd` (builds the TileSet from the atlas PNG and `GreyboxTiles`)
  and `build_maps.gd` (bakes the maps' Height and Decor layers): neither paints. Map work becomes
  "edit the atlas PNG if a tile's look changes, then `build_tileset.gd`, then `build_maps.gd`", with
  no tile-painting step. `make_font.gd`, `make_audio.gd`, `capture.gd`, `playtest.gd`,
  `play_days.gd`, `setup_input_map.gd` stay.
- **What leaves with the tools:** nothing the game reads at runtime. `TitlePicture`, `SceneryAtlas`,
  `ReliefAtlas`, `GreyboxTiles` and the frame dictionaries are runtime code and stay. Some comments
  ("painted by tools/art/...") change to "in <the PNG>".

## 4. PixelGrade

Its warm grade and soft outlines are already in every baked PNG, and nothing re-applies them.
- **Stays:** `PixelGrade.INK` (outlines of the things drawn in code) and `PixelGrade.warm()` (the
  grass fringe of `HeightShading` and the title's sky), so what is drawn in code keeps matching.
- **Retires with the tools:** `PixelGrade.apply()` and its outline helpers, and the parts of
  `tests/core/art/pixel_grade_test.gd` that test them (they only ever ran inside the tools).
- **New art gets the look from the palette** (§7): paint or reduce it to the master palette, with
  dark outlines in a deep shade of what they surround (as the baked art has), lit from the north-west.

## 5. Villager recolouring

`SpriteSheet.recoloured()` swaps any pixel within 0.01 of a marker colour (per channel, about 2 of
255) for the villager's own. It keeps working as long as `villager.png` is painted in exactly:

| Marker | Hex | Becomes |
|---|---|---|
| robe | `#FF00FF` | the villager's `robe_color` |
| robe, shade | `#800080` (or `#7F007F`) | the robe colour, darkened 30% |
| hair | `#00FFFF` | `hair_color` |
| hair, shade | `#008080` (or `#007F7F`) | the hair colour, darkened 30% |

Nothing else in the sheet may come within two steps of those colours. They are a palette of their
own (`art/palettes/villager_markers.gpl`), and a test checks that each is present and that every
pixel either is one of them exactly or is far from all four.

## 6. Import settings

The art's `.import` files are already right: lossless (`compress/mode=0`), no mipmaps, and the
project draws every texture with the nearest filter (`default_texture_filter=0`). The switch adds
`importer_defaults` for textures to `project.godot` (lossless, no mipmaps, no 3D detection), so a
new PNG imports the same way, and a test that every art PNG's `.import` says lossless and no
mipmaps. **The `.import` files are not edited by hand** (a standing rule); the defaults cover new
files, and the existing ones already match.

## 7. A master palette

The baked art has 3,771 distinct colours, because the tiles carry dithered texture (1,703 colours
in the tile atlas alone) and outlines are shaded from what they surround. So:
- **`art/palettes/hearthvale.gpl`, the master:** the 256 most-used colours across all the art
  (near-twins merged, within two steps a channel), grouped and named by where they come from (skin,
  hair, cloth, leather, wood, stone, metal, grass, soil, water, outline...). Load it in Aseprite and
  in an AI tool that takes a palette.
- **`art/palettes/<sheet>.gpl`, one per sheet:** that sheet's exact colours (from 5 in the wisp to
  413 in the items), for touching up a picture without a stray colour.
- **`art/palettes/villager_markers.gpl`:** the four markers (§5).

Made once in step 2, from the baked PNGs, by a scratch script (not kept as a tool).

## 8. Checks (tests)

A new suite, `tests/art/`, reads `art/sheets.json`:
- **Each PNG exists and is its size:** frames x frame width by rows x frame height.
- **Each sheet has its frames in its order:** each script's frame dictionary names the same frames
  in the same columns as the sheet list (this replaces today's checks against the tools).
- **Flash rows:** every sheet of `gameplay/art/` has a second row the same shape as the first, in
  white.
- **The hero:** 25 columns x 3 rows of 16x32; every frame painted, its soles on the last row.
- **Villagers:** the markers (§5); every frame's feet on its last row.
- **Atlases:** the tile atlas is 128x544 (8x34 tiles); the scenery atlas keeps each tree inside its
  cell's padding, its foot on the ground; the relief atlas is 96x112.
- **The title:** 640x360; the keep's window and the stars are where `TitlePicture` says (a dark
  window, dim stars).
- **No new half-clear pixels** in the sprite sheets (they have none today; the tiles and trees have
  some, and keep them).
- **Import settings:** lossless and no mipmaps, for every art PNG.

Today's tests that call the tools change: `sprites_test`, `held_tools_test`, `player_animator_test`,
`crops_test`, `farm_test` check against the sheet list instead. **Some tests check how a tool
painted, not what the game needs, and retire with it:** the hero's frames being put together from
the same parts (a breath is the idle frame a pixel lower), the title tool's dithering and ground
line, `PixelGrade.apply()`'s outlines. `make_font.gd`'s tests stay.

## 9. Proof it looks the same

1. **The PNGs:** each tool is run one last time; every PNG it writes must be byte for byte the one
   in the repo (a hash of each, before and after). If one differs, it is explained before going on
   (it should not: each was baked by its tool at its last change).
2. **The screens:** `tools/capture.gd`, every shot (1 to 207) and the 16 films, taken twice before
   the switch (to find what moves by itself: water, fires, critters, the clock's light) and once
   after. A script compares them pixel by pixel; a difference is allowed only where the two "before"
   runs already differ from each other, and every other one is explained or fixed. **This opens a
   game window for about five minutes, three times** (I will say so before each run; it writes no
   save but the capture's own slot).
3. **The suite:** all tests pass.

## 10. Licences: `docs/ASSETS.md`

A table of every art asset: its file, what it is, where it came from, when, and its terms. Every
asset today reads: *made in code by Hearthvale's own tool `<tool>` (retired 2026-11-xx; in git
history), Hearthvale's own work*. For AI-made art you add: the tool (e.g. PixelLab), your plan or
tier, the date, the prompt or source (optional), and the licence terms as the tool states them at
that date (a link and a line quoting what matters: commercial use, attribution). Fonts and sound:
made in code, Hearthvale's own. A release is checked by reading that table.

## 11. CLAUDE.md and DECISIONS.md

**Replaces lines 98 to 153** (the art bullet and its passes), keeping what is still true about the
game, dropping every "painted by" and "edit the tool, never the PNG":

> - **Art is PNG (the user's switch, 2026-11-xx; `docs/progress/png-art-plan.md`):** every picture
>   the game shows is a PNG where the game loads it (`gameplay/art/`, `gameplay/player/`,
>   `world/tiles/`, `ui/title/`), edited by hand (Aseprite, files in `art/aseprite/`) or replaced
>   with art the user brings, AI-made art included; each is listed in `docs/ASSETS.md` with where it
>   came from. **New art fits as the old does:** the size, frames, order, rows and pivot in
>   `art/sheets.json` (tests check them), a white flash row under every sheet of `gameplay/art/`,
>   villagers in the marker colours (`art/palettes/villager_markers.gpl`), colours from
>   `art/palettes/hearthvale.gpl`, and tiles in their atlas places (an older tile never changes
>   place; new tiles go at the end). How-to: `art/README.md`. Art never changes timing, hits or
>   collisions. Hearthvale's own look: never another game's art.
> - **Drawn in code, and kept in code:** shadows, cast shadows and soft edges (`HeightShading`),
>   bursts and sparks, the sword's blade, lights and darkness (`AreaLighting`), the water's movement
>   and reflections, mist, the boxes' frames (`PanelFrame`), villager recolouring, the title's
>   stars, window and petals, and the things outlined in `PixelGrade.INK` (chests, doors, pickups).
> - **Sound and fonts are made in code:** `tools/audio/make_audio.gd` bakes `audio/` (edit the
>   tool, never the WAVs); `tools/art/make_font.gd` bakes the two pixel faces and the theme. No
>   external audio or fonts.
> - **What the passes left, still true:** the hero is two cells tall (16x32), 25 frames a row, his
>   feet, collisions and the sword's reach where they always were (`Sword.HAND` only says where the
>   blade is drawn); villagers are as tall, and breathe and blink (`Idling`); trees stand up from
>   their cell (`Scenery`) and block only it; walls have faces (`WallRelief`); labels are whole
>   multiples of 8 and boxes wear `PanelFrame`; headings use the `Heading` face. The plans of each
>   pass are in `docs/progress/`.
> - **A still world (user's request, 2026-11-13):** *(this line stays word for word, with the tool
>   polish's bend added: bursts of a stroke, half a second at the most, falling to the ground.)*

**The commands:** the six "Repaint ..." and "Re-bake ... tiles" commands go. What stays and what
is new:

> ```bash
> # After adding or editing a PNG (Aseprite export), let Godot import it, then check the art
> godot --headless --path . --import
> godot --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd --add res://tests/art --ignoreHeadlessMode --continue
> # Re-bake both pixel fonts and the UI theme after editing tools/art/make_font.gd
> godot --headless --path . -s res://tools/art/make_font.gd -- <preview.png>
> # Re-bake sound effects and music after editing tools/audio/make_audio.gd, then re-import
> godot --headless --path . -s res://tools/audio/make_audio.gd
> godot --headless --path . --import
> # Maps: rebuild the TileSet from the atlas PNG, then re-bake the areas' Height layers
> # (OVERWRITES editor painting of those layers); build_maps.gd bakes every area, or only those named
> godot --headless --path . -s res://tools/greybox/build_tileset.gd
> godot --headless --path . -s res://tools/greybox/build_maps.gd
> ```

**The other lines that name a painting tool** change to name the PNG: the marsh's tiles (lines
144 to 147: "two rows at the end of the atlas" stays, "painted by `make_tile_texture.gd`" goes), the
Homestead's buildings (line 726: "atlas rows 28 and 29 (`GreyboxTiles.BUILDING_KINDS`,
`SILO_KINDS`)"), and any "edit the art in the tool". No line will say art may only be made in code
or that a PNG must not be edited.

**`docs/DECISIONS.md`** gains:

> - 2026-11-xx — **Art is PNG (the user's request).** Every art asset was baked one last time by its
>   tool and the PNGs became the source, edited in Aseprite or replaced with art the user brings
>   (AI-made art allowed, each recorded in `docs/ASSETS.md`). The six painting tools are retired to
>   `tools/retired/` (ignored by Godot; kept as a record). The PNGs stay where the game loads them;
>   `art/` holds the sheet list, the palettes, the how-to and `.aseprite` files. Sound and fonts are
>   still made in code. Supersedes "art is made in code" and every "edit the tool, never the PNG".

## 12. How-to: what to export, and what to ask for

All pictures: PNG, RGBA, **no anti-aliasing, no semi-clear pixels in sprites**, transparent
background, exact sizes. Draw at 1x (one pixel is one game pixel). Lit from the north-west; dark
outlines that take a deep shade of what they surround. Colours from `hearthvale.gpl`. A pivot is
where the game puts the node (a character's feet, a cell's corner) in the frame.

| Kind | File | Export | Pivot |
|---|---|---|---|
| **Hero** | `gameplay/player/player_sheet.png` | 400x96: 25 frames of 16x32 a row; rows facing down, up, left (right is mirrored). Columns: idle, blink, walk 1-6, windup, slash, follow, hold (seen from the front in every row), fallen, breathe, hurt, run 1-6, raise, strike, pour, reach. No flash row. | feet at (8, 32): soles on the last row, centred |
| **Tools in his hands** | `gameplay/art/held_tools.png` | 2280x112: 57 frames of 40x56 + flash row, order in `sheets.json` | his feet at (20, 40); the fists over the handle where his pose's hands are |
| **Villagers** | `gameplay/art/villager.png` | 96x64: 6 frames of 16x32 (plain, bearded, then their breathe, then their blink) + flash row; robe and hair in the marker colours | feet on the last row |
| **Monsters** | `slime`, `wisp`, `bat` 16x16 x3; `goblin` 16x24 x5; `warden` 32x40 x4; `shade` 32x40 x3 | frames + flash row | slime: feet at (8, 15); goblin (8, 23); wisp (8, 18); bat: the middle, (8, 8); warden (16, 39); shade (16, 42), below its frame: it floats |
| **Animals, critters** | `animals.png` 24x20 x8; `critters.png` 16x16 x8 | frames + flash row; face left (right is mirrored) | animals (12, 18); hen (8, 14) |
| **Tiles** | `world/tiles/greybox_tiles.png` | 128x544: 8 x 34 tiles of 16x16. Repaint a tile in its place; never move one; new tiles at the end. Rows by `GreyboxTiles` (ground by height, stairs, paths, solid things, floors, furniture, decor, details, water frames, markers, houses, marsh, quarry, buildings, silo, roofs) | the cell |
| **Trees** | `world/tiles/scenery.png` | 280x48: 7 cells of 40x48 (broadleaf, oak, pine, cherry, cherry b, willow, willow b), each tree 32x40 at (4, 4), clear padding round it | trunk foot at (16, 37) of the 32x40 |
| **Wall faces, pillar, ridges** | `world/tiles/relief.png` | 96x112, places by `ReliefAtlas` | as `ReliefAtlas` says |
| **Buildings** | tiles of the atlas (houses rows 16-20, buildings 28-30) and `relief.png` | repaint tiles in place | the cell |
| **Crops, soil** | `crops.png` 16x16 x13; `soil.png` 16x16 x4 | + flash row | the cell's top-left |
| **Items** | `items.png` 16x16 x74 | + flash row; one icon per item, order in `sheets.json` | the cell's top-left |
| **Things set down, furnishings, rocks, breakables, forage** | `placed`, `crafted`, `rocks`, `breakables`, `forage` 16x16 | + flash row | the cell's top-left |
| **UI** | the title picture `ui/title/backdrop.png` 640x360; boxes, bars and the font are code | keep the keep's window and the stars where `TitlePicture` says | |

**Asking an AI tool:** give it the size, the frame count and order, the view and the palette. For
example: *"16x32 pixel-art character sprite sheet, top-down three-quarter view, 25 frames per row in
this order: ..., three rows facing down, up and left; transparent background; no anti-aliasing; 1px
dark outline; limited palette (attached .gpl); warm light from the top left; feet on the bottom row,
centred."* For tiles: *"16x16 seamless top-down pixel-art tile, ..., same palette, no outline on the
edges that meet the next tile."* Check the result against `sheets.json` with the art tests before
using it, and record it in `docs/ASSETS.md`.

## 13. Risky or hard to switch

1. **The tile atlas is dithered texture** (1,703 colours): an AI tile will not match it exactly;
   the master palette helps but repainted ground will look different beside old ground. Repaint a
   whole family of tiles (all the grass heights) at once.
2. **The grass fringe and the title's sky are colours in code** (`HeightShading.fringe_color()`,
   `TitlePicture.SKY_TOP`). Repaint the grass or the sky and these need changing too, or a seam shows.
3. **Every sheet of `gameplay/art/` needs its white flash row,** which art tools don't make. In
   Aseprite: duplicate the frames' layer, fill the shapes white, export below. (An alternative, not
   proposed: make the flash in code at load and drop the row from the PNGs; it changes every sheet's
   size.)
4. **Villager markers must be exact** (§5); an AI tool will not keep them on its own. Recolour by
   hand after.
5. **Pivots are not in the PNG:** a picture drawn a pixel lower stands a pixel lower. The tests
   check feet on the last row where that is the rule (hero, villagers); the rest is the how-to's
   table.
6. **The hero's frames were made from shared parts;** after the switch nothing keeps them in step
   (a new head must be drawn in all 75 frames).
7. **The title picture's stars, window and trees are places in code;** repaint the picture and they
   must stay where they are.
8. **Tool polish is half done:** steps 3 (work by hand) and 4 (mirrored frames, the site's twine,
   lit windows) are approved and not built. Step 4's twine is a change to the tile atlas, made today
   in `make_tile_texture.gd`. **Recommended: finish tool polish first, then switch,** so its art is in
   the PNGs that become the source. Switching first means the twine is drawn by editing the atlas
   PNG.
9. **Tool polish step 2 is committed** (`f83b520`); the switch starts from there.

## 14. Decisions for the user

1. **A1.** The PNGs stay where the game loads them; `art/` holds the sheet list, palettes, how-to and
   `.aseprite` files. *Recommended.*
2. **A2.** The six painting tools move to `tools/retired/` under `.gdignore` (kept, never run). The
   other choice: delete them (git history keeps them). *Recommended: move.*
3. **A3.** `PixelGrade` keeps `INK` and `warm()`; `apply()` retires with the tools. *Recommended.*
4. **A4.** The white flash row stays in the PNGs. *Recommended.*
5. **A5.** The palettes: a 256-colour master, one per sheet, and the villager markers. *Recommended.*
6. **A6.** `art/sheets.json` drives the art tests; the tests that check how a tool painted retire.
   *Recommended.*
7. **A7.** The proof: byte-equal PNGs, and every shot and film compared against two "before" runs.
   *Recommended.*
8. **A8.** Order: finish tool polish (steps 3 and 4) first, then the switch; or switch now.
   *Recommended: tool polish first.*

## 15. Step 2, the switch (after approval)

1. Check that the tools' last bake equals the repo's PNGs (hashes). Take the "before" shots and films
   twice.
2. Write `art/sheets.json` from the tools (once), the palettes, `art/README.md`, `art/.gdignore`.
3. Move the six tools to `tools/retired/` with its `.gdignore` and `README.md`; move `PixelGrade.apply()`
   there too; change comments that name a retired tool.
4. Tests: `tests/art/`, the five suites that read the tools changed, the tool-only tests retired.
   `importer_defaults` in `project.godot`.
5. Take the "after" shots and films; compare; explain or fix every difference.
6. `CLAUDE.md` (the approved wording), `docs/DECISIONS.md`, `docs/ASSETS.md`, `LOG.md`.
7. All tests pass, commit, stop: the `CLAUDE.md` diff and the screenshot comparison for you.

## Step 2 — built (2026-11-19)

As planned, with what building it decided (in `docs/DECISIONS.md`): 13 tests of how a tool painted
retired with the tools; pivots are listed and only the feet and trunks tested; new PNGs import by
`importer_defaults`; the master palette is the 256 most-used colours. **The proof:** all 27 PNGs
byte-equal after the last bake; every shot and film compared against two "before" runs, and the only
differences are things that move by themselves (creatures, flicker, a screen shake, timing). Results
and the pictures looked at: `docs/progress/LOG.md`.
