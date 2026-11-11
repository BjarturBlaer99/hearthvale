# Art pass 3 — a warmer, softer look (plan)

Asked for by the user on 2026-11-10, after H15: graphics "very similar to Stardew Valley".

**What this is, and isn't.** Hearthvale's art stays its own: I won't copy another game's tiles, characters,
palette or interface. What the pass takes is the general craft of cosy farm-and-village pixel art, which is not
any one game's: warm, saturated colour; shadows that lean violet and lights that lean yellow; outlines in a dark
shade of the thing they surround, not one near-black ink; lush, sunlit greens. No new mechanics, areas or
content, and still no external assets: everything is painted in code.

## Step 1 (this pass): colour and line, everywhere at once
- **`PixelGrade`** (pure, tested), applied by all three art tools as they bake:
  - **Warm colour:** a little more saturation, highlights tinted towards yellow and shadows towards violet.
  - **Soft outlines:** each outline pixel takes a dark, rich shade of the colours beside it. With nothing coloured
    beside it, it falls back to a soft plum-brown ink.
  - It leaves alone what must stay exact: the white hit-flash copies of sprites and the villagers' marker colours.
- **Palette:** sunnier grass on the low ground, warmer earth on the paths, brighter water, tree crowns that run
  from blue-green shade to yellow-green light, violet-tinted shadows.
- **Grass:** blades and flecks in a yellower light and a bluer shade, in place of plain lighter and darker.
- **Things drawn in code at runtime** (chests, doors, blocks, signs, shadows, the grass fringe on paths) use the
  same ink and the same warmed greens, so they match the baked art.

## Done when
- [x] every baked picture goes through `PixelGrade`: the tiles, the hero, every other sprite
- [x] no near-black outline ink is left in the tiles or sprites; flashes stay white; villagers still recolour
- [x] the grass fringe drawn at runtime matches the baked grass
- [x] all tests pass, and before and after screenshots are compared side by side
- [x] (yours) it looks right in play (reported on 2026-11-11)

## Later steps, only if wanted
Each is a repaint of specific art, so each is its own piece of work:
- bigger, rounder trees (two tiles tall, drawn over the hero when the hero walks behind)
- richer ground: tilled soil, taller grass, more flower kinds
- a warmer look for the text box and menus, to match
- faces and clothes with more detail on the villagers

## Not in this pass
Anything that changes the maps, the tile layout, sprite sizes or frames. The pass changes pixels only.
