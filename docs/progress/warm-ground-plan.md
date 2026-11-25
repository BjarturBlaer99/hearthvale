# Warmer colours and busier ground — the plan

The user's words, 2026-11-25: the graphics "1 to 1 to Stardew Valley". That was declined: copying
another game's art, tiles, palette or interface is not allowed (`CLAUDE.md`, "Hearthvale's own
look"). Of the qualities offered in its place, the user chose two: **warmer colours** and **busier
ground**. This pass takes only that general feel, which belongs to the whole genre of cosy farm
games. Every colour and tile below is Hearthvale's own, worked out from its own palette.

## What the user has decided

**Approved as written on 2026-11-25** ("Approve as recommended"), with the recommended answer to each
of the eight questions in section 7:

1. **Q1:** as warm as in the samples.
2. **Q2:** a faint gold daylight (1.0 0.98 0.93 from 07:30 to 17:00) in place of white.
3. **Q3:** the water a little towards teal.
4. **Q4:** the dungeons and the quarry warmer (plum-grey stone, warmer dim light), and still dim.
5. **Q5:** details outdoors, in the quarry and in the dungeons; none in houses.
6. **Q6:** about one grass cell in four, tuned in the user's playtest (step 4).
7. **Q7:** the details drawn by script in the game's palette; the user may replace them with a
   PixelLab sheet later.
8. **Q8:** the order colours, tiles, details, playtest, with a stop after each.

**How far it has come:**

- **Step 1, the colours:** built (`78ed546`) and **approved on 2026-11-25** (shown the summary and
  five before-and-after pairs: "Approve, go to step 2").
- **Step 2, the busier tiles:** built on 2026-11-25; waits for the user's review.

**The plan as it was written follows. When it was written nothing in the game had changed yet.** The pictures in
`docs/progress/warm-ground-samples/` were made in a scratch copy of the project. Each one shows the
game as it is on the left and the proposed look on the right, at the same spot and the same hour.
The detail art in them is a rough first draft, painted by a script in about an hour, to show the
direction.

## 0. In short

- **Warmer:** the grass moves from a cool, saturated green towards a sunny yellow-green. The water
  moves a little towards teal, and the dungeons' blue-grey stone towards a plum-grey. Shadows lean
  plum, not violet. Daylight gets a faint gold tint, and houses and dungeons get warmer ambient light.
  The path, the soil and the wood are already warm, so they barely change.
- **Busier:** today 203 of the 256 pixels in a grass tile are one flat colour. The pass gives the
  ground tiles more texture, painted in place. It also adds **ground details**: clover, tiny
  flowers, grass blades, sunlit and shaded patches, pebbles, worn spots, ruts, cracks, moss and grit.
  They come from a new sheet, chosen for each cell by a fixed hash, and are drawn once under
  everything else. They never sit on a cell that holds anything.
- Four steps, a stop after each. Eight questions for you (section 7).

## 1. What the game looks like now

Taken with `tools/capture.gd` (shots 1, 4, 5, 21, 30, 44, 46, 52, 90, 92, 141, 142, 144, 145, 160,
164 and 167). The left half of each sample picture.

- **The grass is one flat, cool green** (`#63a037`, hue 94°, saturation 65%). It is bright and clean,
  but it reads as a lawn: a big field is a single colour with a few tufts on it.
- **The paths are already warm** (`#c89758`) and have a few pebbles drawn in. **The soil, the wood
  and the roofs are warm** too. The cool colours are the grass, the water and the dungeons' stone.
- **The water is a strong, saturated blue** (`#2475b3`). Next to warm ground it is the coldest thing
  on screen.
- **The dungeons and the quarry look blue-violet.** The cellar's and the keep's stone is blue-grey
  (`#494c5c`). The quarry's earth is a warm brown (`#5c4d47`), but the dungeon light
  (`AreaLighting.AMBIENT["dungeon"]`, 0.54 0.54 0.72) tints it violet.
- **Noon is pure white light.** Dawn and dusk are already warm.

## 2. Warmer colours

### 2.1 The palette, by role

The pass recolours by role. **Every pixel of an exact old colour becomes its new colour**, wherever it
is in the atlas: the grass under a fence or a prop changes with the grass tile, and no seam can open.
The colours below are the ones in the samples.

| Role | Where | Old | New | Why |
|---|---|---|---|---|
| grass, plain (height 0) | atlas row 0 and row 8, column 0 | `#63a037` | `#7aa540` | 9° towards yellow, a touch less saturated: sunny, not lawn |
| grass, shade blade | same | `#589739` | `#6b9c41` | shades keep more green, so the turf keeps depth |
| grass, light blade | same | `#6aa633` | `#84ab3d` | |
| grass, highlight | same | `#76b02f` | `#95b53a` | highlights lean gold |
| grass, dark | same | `#4d8c3a` | `#5c9042` | |
| grass, plain (height 1, 2) | columns 1, 2 | `#6fac3d`, `#7db845` | `#8ab147`, `#9cbe4f` | the rises stay lighter, as now |
| path | row 2 | `#c89758`, `#af844f`, `#cea268`, `#85653d` | `#cc9357`, `#b3814f`, `#d29f68`, `#88633d` | already warm: a hair more honey |
| water | row 11 and the water tile | `#2475b3`, `#317db7`, `#458abd`, `#9dd5e7` | `#3690b7`, `#4297bb`, `#55a1c1`, `#a4dde7` | 8° towards teal, less saturated: still clearly water |
| dungeon stone | floor (4, 4), walls (6..7, 5), ledges (row 10), pits | `#494c5c`, `#2e303d`, `#5b5c6d`, `#6e6c7f`, `#353549`, `#1a1a24` | `#565060`, `#38333f`, `#6a6271`, `#7f7484`, `#453b4c`, `#221d25` | blue-grey to plum-grey: still stone, no longer cold |
| marsh ground | row 23 | `#4c6f47` and its shades | a few degrees warmer, in step 1 | Willowmere stays a damp, darker green, as it should |
| soil, wood, roofs, cave earth | | | unchanged | already warm |

The grass's new colours are worked out from the old ones by one rule (hue down 9°, a little more for
the lights and a little less for the shades, saturation × 0.93, value × 1.03). Step 1 writes them all
into `art/palettes/hearthvale.gpl` and each sheet's palette.

### 2.2 Which PNGs change

- `world/tiles/greybox_tiles.png`: every pixel of the colours above, **in place**. No tile moves.
- `world/tiles/relief.png`: the dungeon walls' faces and tops follow the dungeon stone. In the samples
  they are still the old blue, which shows the seam this avoids.
- Nothing else changes in step 1. The sprites, the trees, the houses, the crops and the UI keep their
  colours. The trees, flowers and tufts were made from PixelLab's sheet (`docs/ASSETS.md`), and they
  sit well on the warmer grass in the samples.

### 2.3 The colours kept in code, and what each must do

| In code | Today | Change |
|---|---|---|
| `GreyboxTiles.GROUND_COLORS[0..2]` (read by `HeightShading.fringe_color()`) | 0.40 0.64 0.24 / 0.45 0.69 0.27 / 0.50 0.73 0.30 | **0.48 0.65 0.27 / 0.55 0.70 0.30 / 0.61 0.75 0.34**. The fringe passes these through `PixelGrade.warm()`, so they sit a step before the tile's own colour, and the grass fringing a path matches the tile. `pixel_grade_test` checks it, and passes with these in the scratch copy |
| `HeightShading.SHADE_FAR`, `SHADE_NEAR` (soft shadows) | violet 0.14 0.06 0.24 | **plum 0.22 0.09 0.18** (same alpha) |
| `HeightShading.EDGE_COLOR` (the lower-edge line) | black at 0.35 | **dark plum 0.16 0.07 0.10** at 0.35 |
| `HeightShading.STONE_FACE_COLOR` | 0.24 0.24 0.29 | **0.28 0.24 0.28**, as the dungeon stone |
| `HeightShading.BANK_SHADE` (under a bank) | 0.08 0.20 0.38 | **0.06 0.18 0.32**, as the water |
| `WaterSurface` `glint`, `deep` | 0.80 0.93 1.0 / 0.05 0.14 0.34 | **0.86 0.96 0.92 / 0.05 0.17 0.32** |
| `data/rules/time.json` 07:30 and 17:00 (read by `DayClock`) | white | **1.0 0.98 0.93**, a faint gold (question Q2) |
| `time.json` 21:00 and 02:00 | 0.48 0.54 0.82 / 0.42 0.48 0.78 | **0.54 0.56 0.80 / 0.48 0.50 0.76**. Under the old blue, warm grass turns grey-olive (sample 08); this keeps the night blue but lets the grass stay green. Still "blue at night" and bright enough by the tests |
| `AreaLighting.AMBIENT` interior / dungeon | 0.62 0.55 0.66 / 0.54 0.54 0.72 | **0.68 0.58 0.62 / 0.62 0.56 0.68**: the quarry's brown earth reads brown, dungeons read plum-dark, not blue (Q4) |
| `AreaLighting.DARK` (the crypt's dark) | 0.06 0.05 0.11 | **unchanged**: the one light that matters to play |
| `Ambience` FIRE, CANDLE, LAMP | already warm | unchanged |
| `TitlePicture.SKY_TOP` | 0.08 0.09 0.22 | **unchanged**: the title's picture (`backdrop.png`) is not repainted in this pass, and the two must change together |
| `PixelGrade` | | unchanged |

## 3. Busier ground

### 3.1 Two parts

1. **The ground tiles themselves get more texture, painted in place.** In the samples each grass tile
   has ten more blades: 185 of 256 pixels are the plain colour, down from 203. In step 2 the
   path, the dungeon floor, the ledge, the cave earth and the marsh get the same, so that a field of
   one tile shows no grid. Every cell still shows the same tile at a given height, so this alone
   can't break the repeat.
2. **Ground details** break the repeat. A detail is a 16x16 picture with a clear background, drawn over
   the ground on some cells and under everything else.

   | Ground | Details (sample sheet: `16_detail_sheet_x6.png`) | In the samples |
   |---|---|---|
   | grass | clover, daisies, buttercups, a clump of dark blades, a sunlit patch, a shaded patch, two pebbles, a worn spot | about 1 cell in 4, with the sunlit and shaded patches gathered in drifts four cells across |
   | path | pebbles, ruts, a sprig of grass, a light sandy patch, a flat stone, specks | about 1 in 3 |
   | dungeon floor, ledge | a crack, moss, dust | about 1 in 5 |
   | cave earth (the quarry) | grit, rubble, a crack | about 1 in 3 |
   | marsh | moss, a damp patch, a sprig | about 1 in 3 |
   | wooden floors (houses) | none (question Q5) | |

   **What a detail may never look like:** anything to pick up, break or cut. That rules out
   mushrooms, berries, coins, gems, anything red, a stone as big as a rock, and a tuft as tall as the
   grass that is cut. Details stay in the ground's own colours, plus flowers of at most three pixels.
   Details are mirrored at random for variety. They never move: the still world holds.

### 3.2 Where details go: three ways compared

| Way | How | For | Against |
|---|---|---|---|
| **A. A fixed hash at draw time** (recommended) | A still `GroundDetail` node draws from its own sheet (`world/tiles/ground_details.png`). For each cell of the Height layer, a hash of the cell picks whether a detail goes there, and which one. It is drawn once, the way `HeightShading` draws its fringe, and redrawn only when the homestead changes | No map changes; the same cell shows the same detail at every load; the sheet is a PNG you can edit like any other; it can't be painted into a map by mistake; costs nothing per frame | A rule decides placement, not a hand (you can't put a daisy exactly *there*) |
| B. Detail tiles at the atlas's end, on a TileMapLayer filled at load by the same hash | As A, but the pictures are three new atlas rows and the layer is a `TileMapLayer` | Could later be painted by hand into a map | Rebuilds the TileSet; puts tiles in the atlas that must never go on a Height layer; a mirrored detail needs alternative tiles. Gains nothing over A today |
| C. A detail layer painted into each map | A `Detail` layer in each area's scene | Full control | Rejected: "no map is re-baked for looks", and it is hours of hand work in 27 areas |
| (D. Swap the Height layer's tiles for variants) | | | Rejected: the Height layer's atlas coordinates are read in several places (paths in build mode, water, doors, pits, edges, the land survey); a variant would break them |

**Recommended: A.** It is what the samples use (`GroundDetail`, about 100 lines in the scratch copy, not committed).
How often a ground gets a detail, and the weights of each kind, go in `data/rules/ground_detail.json`,
data like the other rules. An area can be left bare: the crypt, say, or a room.

### 3.3 The rules it keeps

- **An older tile never changes place; new tiles go at the end.** Step 1 and step 2 repaint tiles in
  place. The details are a sheet of their own, so the atlas grows by nothing. `art/sheets.json` gains
  one entry (`ground_details.png`, 16x16 frames, named in order); the art tests check it. It is a
  tile sheet in `world/tiles/`, so it has no flash row.
- **No map is re-baked for looks.** No `.tscn` changes, and neither `build_maps.gd` nor
  `build_tileset.gd` is run.
- **The scenery stays still.** Details are drawn once and never move.
- **Art never changes collisions, timing or hits.** `GroundDetail` is drawn, never read. Nothing in
  `TerrainQuery`, `HeightGrid` or any motor knows it exists.
- **The ground never hides what matters.** A cell gets no detail if:
  - it has a Decor tile, a Spawns marker, or a node in Interactables (forage, debris, rocks, chests,
    signposts, a dropped item when the area loads);
  - it is on the farm plot (crops and soil are drawn over a bare bed);
  - on the homestead, something lies or stands there, or a building or a site covers it (redrawn on
    `EventBus.homestead_changed`);
  - it is not plain ground (water, a wall, a door, stairs, a pit);
  - **any of its four neighbours is other ground or holds something.** This keeps the path's fringe,
    the banks, the cliff faces clean, and so the walls' bottom rows: the prototype first drew on the
    grass cell where a house's lowest wall row is painted, and this rule fixed it.

  A drop that falls during play lands on whatever is there. Details are small, dull and drawn under
  it, and dropped items wear the `PixelGrade.INK` outline. **The build ghost** is drawn over
  everything, so its green and red and the cell it points at are unchanged.
- **Performance:** one node an area, a few hundred cached rectangles, drawn once. It never sorts or
  walks anything each frame (the dungeon lag fixed in `4e7d107` came from per-frame work).

## 4. The steps

Each step ends with all tests passing, before-and-after pictures from the same spots (the capture
shots above), a commit, and a stop for your review.

1. **Warm colours.** Recolour the atlas and `relief.png` by role (section 2.1), the colours in code
   (2.3), the palettes, and `docs/ASSETS.md` (recoloured by a script, Hearthvale's own colours). The
   script runs once and is not kept as a tool: the PNGs stay the source.
   *Done when:* the village by day, at dusk and at night, the homestead, the Old Wood, Willowmere by
   day and night, the cellar, the keep and the quarry are shown before and after; the fringe matches
   the grass (the existing test); the night stays readable; all tests pass.
2. **Busier tiles.** Grass, path, dungeon floor, ledge, cave earth and marsh repainted in place with
   more texture, each still seamless.
   *Done when:* a wide field shows no grid at the capture's scale; the fringe test still finds the
   grass's plain colour as the commonest (its threshold of 150 pixels is kept, or changed to "the
   commonest colour", with your word); all tests pass.
3. **Ground details.** The sheet (drawn with care in the game's palette; or yours, Q7), `GroundDetail`,
   its rules in `data/rules/ground_detail.json` read by a pure `GroundDetails` (`core/art/`) that
   says, for a cell, its ground and what lies around it, which detail goes there or none.
   *Done when:* unit tests show that the same cell always gets the same detail, and that no detail
   lands on a cell with a decor, a marker, an interactable, the plot, a placed thing, a building or
   water, or beside other ground; a homestead test shows a detail going when a fence is set down and
   coming back when it is taken up; `ground_details.png` is in `sheets.json`; the pictures cover the
   places in step 1, a pickup lying on detailed grass, and a build ghost over it; all tests pass.
4. **Your playtest and tuning.** You play a day; densities and colours are adjusted on your word (data
   and colours only). *Done when:* you say it feels right.

## 5. Risks

1. **Readability.** Warmer grass is closer to the yellow-green weeds, crops and tufts on the
   homestead (sample 04): a weed stands out less. The bushes, stones and stumps keep their outlines
   and still read. If weeds get lost, their dark outline can go one shade darker (a recolour of
   `breakables.png`'s weeds, with your word). Details must stay quieter than anything you can
   interact with.
2. **The night and dark dungeons.** Warm grass under the old blue night goes grey-olive (sample 08,
   right). The new night light (2.3) fixes most of it, and the night stays blue. The crypt's darkness
   (`AreaLighting.DARK`, the Lantern's radius) is untouched. Details on a dark floor are invisible,
   which is right.
3. **The colour tests.** `day_clock_test` says noon is "clear by day" (pure white). A golden noon
   (Q2) changes that test to "warm white: red ≥ green ≥ blue, near white". `pixel_grade_test` wants
   the fringe's colour to cover more than 150 pixels of the grass tile; the samples keep 185, and the
   test passes in the scratch copy.
   `tests/art/` gains the new sheet. `ambience_test` reads `AMBIENT` by name and is unaffected.
4. **An uneven look.** The trees, flowers and houses from PixelLab, and the code-drawn shadows, must
   still sit right on the new ground. In the samples they do. The dungeons' wall relief must follow,
   or blue walls sit on plum floors (samples 13 and 14 show this seam).
5. **Too busy.** A detail on every other cell turns to noise, which is the opposite of cosy. The
   samples use about one in four, with drifts; step 4 tunes it.
6. **Copying.** Every colour here comes from Hearthvale's own, moved by a rule, and every detail is
   drawn for this game. Nothing is taken from another game's palette or tiles.

## 6. The samples (`docs/progress/warm-ground-samples/`, before | after)

| File | What |
|---|---|
| `01_village_square.png`, `02_village_green_close.png`, `03_crossroads_path_close.png` | the village green and its crossroads, noon |
| `04_homestead_overgrown.png`, `05_homestead_field_edge_close.png`, `06_homestead_farmhouse.png` | the farm, the field's edge and the road |
| `07_village_at_dusk.png`, `08_village_at_night.png` | the light through the day |
| `09_old_wood.png`, `10_willowmere.png`, `11_willowmere_at_night.png` | the wood and the marsh (its ground not yet warmed) |
| `12_quarry_floor_1.png`, `13_ruin_cellar.png`, `14_keep_great_hall.png` | the quarry and two dungeons (their walls not yet warmed) |
| `15_ground_tiles_x8.png` | the atlas's top-left corner eight times (grass at heights 0 to 3, the stairs, the path): today's, and with the new colours and more blades on the grass |
| `16_detail_sheet_x6.png` | the draft detail sheet, six times |

## 7. Decisions for you

1. **Q1. How warm.** As in the samples; or gentler (half as far); or warmer still. *Recommended: as in
   the samples.*
2. **Q2. A faint gold daylight** (1.0 0.98 0.93 from 07:30 to 17:00, in place of white). It makes the
   whole picture sunnier, sprites too, and changes the "clear by day" test. *Recommended: yes.*
3. **Q3. Water a little towards teal,** as in the samples; or keep today's blue. *Recommended: teal.*
4. **Q4. Dungeons and the quarry warmer** (plum-grey stone, warmer dim light), as in the samples; or
   keep them cool, to set them apart from the warm world outside. *Recommended: warmer, as in the
   samples; they stay dim.*
5. **Q5. Where details go:** outdoors, the quarry and the dungeons; or outdoors only; and houses'
   wooden floors: none, or a few knots and rugs' wear. *Recommended: outdoors, the quarry and the
   dungeons; none in houses.*
6. **Q6. How many:** about one cell in four on grass, as in the samples; or fewer; or more.
   *Recommended: as in the samples, tuned in step 4.*
7. **Q7. Who draws the details:** I draw them by script in the game's palette, with more care than the
   draft (as the hero was redrawn); or you bring a sheet (PixelLab, 16x16 details on a clear
   background) and I fit it, as with the slime and the bat. *Recommended: I draw them; your sheet can
   replace mine at any time.*
8. **Q8. The order:** colours, tiles, details, playtest, a stop after each. *Recommended.*
