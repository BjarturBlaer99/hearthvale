# New art from PixelLab — the plan

The user's words, 2026-11-20: "here is the new artwork for the game", four sheets made with PixelLab
(kept in `art/incoming/`: `nature.png`, `houses.png`, `hero.png`, `ui.png`). The user chose: **fit it to
the game's sizes** (the game, its maps and collisions stay as they are; the look changes), **cut the
houses into the game's tiles**, and record it as PixelLab's. This is the plan; nothing is built until it
is approved. Each step then ends with all tests passing, committed, and before-and-after pictures.

## 1. What came

| Sheet | What is on it | Its size | The game's size for it |
|---|---|---|---|
| `nature.png` | a cherry, a round broadleaf, a willow, two pines; two stumps (one with roots); two mossy rocks; a berry bush; grass tufts, sprigs and flower clumps | trees 58 to 97 px; stumps, rocks, bush about 45 px; grass 13 to 30 px | trees 32x40 (`scenery.png`); stumps, rocks, bush, grass 16x16 |
| `houses.png` | four cottages seen from an angle: thatch, red tile, blue slate, mossy shingle; half-timbered walls, shuttered lit windows, doors, chimneys | about 120 px each | 16x16 tiles: roofs, walls, windows, doors, chimneys; ridges in `relief.png` |
| `hero.png` | the hero standing, from the front, the back and the side (the same look as today's: brown hair, red scarf, blue tunic, leather vest, pack, boots) | 212 px tall | 16x32, 25 frames in each of 3 rows (`player_sheet.png`) |
| `ui.png` | a clock with a day-and-night dial, "DAY 04" and the time; a status box with hearts and an energy bar; a menu with tabs and a grid of icons; a dialogue box with the speaker's portrait; an item bar of nine slots | about the size the game's own boxes are on its 640x360 screen | drawn in code today (`PanelFrame`, `HeartsBar`, `EnergyBar`, `ItemBar`) |

**A quick automatic fit** (shrunk to size, edges made hard, colours snapped to the piece's own) is in
the pictures sent with this plan: the trees, stumps and rocks come through well and richer than
today's; **the hero does not** (at 16x32 his face is lost and he comes out thin and dark), so he is
drawn by hand at the game's size from the new look, not shrunk.

## 2. Where each piece goes

**Nature (into `scenery.png`, `breakables.png`, `rocks.png` and the tile atlas):**
- trees: broadleaf and oak from the round broadleaf (the oak a little darker), pine from the taller
  pine, cherry and willow from theirs; the second cherry and willow (`cherry_b`, `willow_b`) the same
  tree mirrored. Each fitted into its 32x40 picture, its trunk's foot at (16, 37).
- stumps: `stump` (the village's and the farm's old stumps) from the plain stump.
- rocks: `boulder` from the smaller mossy rock and `great_boulder` from the larger; the field stone
  `rock` and the quarry's rocks stay as they are (nothing on the sheet is a plain stone or ore).
- the berry bush: `bush`; grass: the `grass` breakable and the atlas's grass tufts; flower clumps: the
  atlas's red, yellow and blue flowers.

**Houses (into the tile atlas and `relief.png`):** the game's houses stay front-on, as its maps build
them; from the sheet I take what each house is made of and draw it into the tiles: thatch, red tile,
blue slate and mossy shingle roofs (the farmhouse's, the village's red and blue, the Coop's), the
half-timbered wall, the shuttered window, the door, the chimneys, the eaves and the ridges.

**The hero (into `player_sheet.png`):** his three standing frames drawn at 16x32 from the new look;
then the new look carried through all 75 frames (walk, run, swing, work poses, hurt, fallen...), which
today share parts (a head, a body, legs). The held tools are fitted to his new hands where they move.

**The UI:** restyled in the new look: the boxes' wooden frames with gold corners, the hearts, the energy
bar with its bolt, the item bar's slots, as PNG pictures the code draws instead of drawing them itself.
The text stays the game's own pixel font. **Two things on the sheet are new to the game** and are
decisions of their own: the clock with its day-and-night dial, and a portrait of the speaker in the
dialogue box (the sheet has the Elder's; every villager would need one).

## 3. What it touches

- **Sizes, frames, pivots and atlas places stay as `art/sheets.json` says;** the art tests hold them.
  Flash rows are made again from each new frame's shape.
- **Palettes:** the master palette and each sheet's are made again from the new art.
- **Gameplay, timing and collisions:** none. A tree still blocks its cell, the hero still collides
  where he did.
- **`docs/ASSETS.md`:** each changed PNG says PixelLab, with your plan, the date and PixelLab's terms on
  that date. **I need your PixelLab plan (free or paid, which tier) and the date you made them.**

## 4. Risky or hard

1. **The forest's closed canopy and the map's own tree tiles** (the edges of every area) are tiles, not
   the standing trees; with new trees beside them they will look old. I would make them from the new
   trees' leaves, in their places.
2. **The hero is the most work:** 75 frames by hand from three standing poses. The other way is to ask
   PixelLab for his whole animation at 16x32 (walk, run, swing and so on) using this sheet as the
   reference, and I fit and tidy what comes.
3. **The houses are drawn from an angle;** the tiles are front-on. Roofs and walls take their
   materials and colours; their shapes stay the game's.
4. **Two new UI features** (the clock dial, portraits) are new code, not only new pictures.
5. **The new art is richer and darker in places than the old;** mixed with old art (the quarry's rocks,
   the village's people, the monsters) it may look uneven until those are made new too.

## 5. Decisions for you

1. **N1. Nature as in section 2** (trees, stumps, mossy rocks as boulders, the bush, grass and flowers).
   *Recommended: yes.*
2. **N2. The forest's canopy and map tree tiles** made from the new trees' leaves. *Recommended: yes.*
3. **N3. The houses' materials into the tiles,** front-on as now. *Recommended: yes.*
4. **N4. The hero: I draw all 75 frames from the new look** (or you ask PixelLab for his animation and
   I fit it). *Recommended: I draw them.*
5. **N5. The UI restyled** (boxes, hearts, energy bar, item slots). *Recommended: yes.*
6. **N6. The clock with its dial** (new). *Recommended: yes, in the UI step.*
7. **N7. Portraits in the dialogue box** (new; a portrait for every villager). *Recommended: later,
   when you have the portraits.*
8. **N8. The order:** nature, houses, hero, UI, a step each, stopping after each. *Recommended.*

## 6. The steps

1. **Nature:** the trees, stumps, boulders, bush, grass, flowers (and N2's canopy). Pictures: the
   village square, the Old Wood, the farm, before and after.
2. **Houses:** roofs, walls, windows, doors, chimneys, ridges. Pictures: the village, the farmhouse,
   the farm's buildings, a house at night.
3. **The hero:** 75 frames, the held tools fitted. Pictures: the films of every stroke, walking,
   running, a swing, before and after.
4. **The UI:** the boxes, hearts, energy bar, slots (and N6's clock). Pictures: the HUD, a dialogue,
   the pause menu, the item bar.

Each step: the art tests and the whole suite pass, `docs/ASSETS.md` and the palettes are updated, and I
stop with before-and-after pictures.

## Approved, and step 1 built (2026-11-20)

The user approved the plan as written ("Approve as written"). **Step 1, nature:**
- **Trees** (`scenery.png`): each tree shrunk to fit 32x40, its outline kept (a pixel on the edge
  takes the darkest colour under it), its colours snapped to the piece's own, its foot centred on
  (16, 37); the old soft shadow kept under it. Broadleaf from the round broadleaf, the oak the same
  mirrored, a little darker and warmer; the pine from the taller pine; the cherry and the willow, and
  their second pictures the same mirrored. The cherry is 32x32 now (its sheet picture is as wide as
  it is tall), the others fill the 40.
- **Stump and bush** (`breakables.png`, `stump` and `bush`), **boulder and great boulder**
  (`rocks.png`): shrunk the same way into 16x16. The farm's stumps are the same picture.
- **Grass, flowers, tuft:** the sheet draws these at the game's own scale, so they are taken whole
  (1:1), not shrunk: the grass to cut (`grass`, and `grass_cut` its bottom four rows), the red,
  yellow and blue flowers of the atlas (row 6). The decoration tuft is the smallest tuft shrunk to
  8x6, so the grass that can be cut stays the larger one.
- **The closed canopy** (N2, row 22): a 16x16 piece of the new broadleaf's crown, made to repeat (near
  the tile's edges it is the same piece moved half a tile, mixed in by a dither).
- The tile atlas's other trees (rows 3, 9, 22) are never seen: Scenery stands each as a tall
  picture. The field stone `rock` and the quarry's rocks are as they were.
- Palettes made again (the master palette, `scenery`, `breakables`, `rocks`, `greybox_tiles`).
