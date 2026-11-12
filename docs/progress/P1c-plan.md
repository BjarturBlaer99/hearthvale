# P1c — Ground and nature (plan)

The third step of the pivot's visual overhaul (`docs/ROADMAP.md` P1). Trees stand up from the ground, cherry
blossom comes to Hearthvale, and the wind, the water and the mist start to move. Movement, combat and timing
don't change. The only collision changes are the eight new cherry tree cells the user approved.

## The cherry tree cells (approved by the user on 2026-11-12, from a marked map of the village)
**New trees in Hearthvale: eight cells, each now solid.**

| Where | Cells (x, y) |
|---|---|
| Beside the chapel, on the rise | (16, 4) and (31, 4) |
| By the pond | (34, 25) north-east, (27, 31) south-west |
| Along the main path, at the foot of the chapel stairs | (21, 10) and (26, 10) |
| Along the main path, south of the square | (26, 22) and (21, 27) |

**Existing trees that become cherry trees (no cell changes):** in Hearthvale the clumps at (3–4, 9–10) and
(34–35, 31–32); in the North Fields the clumps at (30–31, 5–6) and (16–17, 22–23).

## What changes
- **Tall trees** (`Scenery`, `SceneryAtlas`, `tools/art/make_scenery.gd`): every tree but the closed canopy of
  thick woods becomes a picture 32 by 40 pixels, painted in five shades, standing in its cell and sorted by
  depth with the hero. A tree blocks exactly the cell it always did; its crown overlaps the cells behind it.
  - **Nothing is hidden:** a crown fades while the hero, an enemy or anything that can be picked up stands
    behind it.
- **Cherry blossom:** two tree pictures in five pinks over dark bark; petals drifting from each tree
  (particles) and settled on the grass and the water round it (`Petals`).
- **Wind:** crowns sway (a shader that moves whole pixels, more the higher up); tufts, flowers, crops and
  washing sway on a layer of their own (`SwayLayer`).
- **Water** (`WaterSurface`): glints, sparkles and a slow swell over the water tiles, and foam at the bank that
  widens and narrows. `HeightShading` no longer draws still foam.
- **Reflections** (`Reflections`): the hero and the trees by the bank, upside down in the water under them.
- **Mist** (`Mist`): two slow layers over the Old Wood.
- **Palette and outlines** (`PixelGrade`): a little less saturation, and selective outlines: a line on the edge
  of a shape stays dark, a line inside a shape is only a little darker than what it runs through. Every picture
  is re-baked.

## What does not change
- Collisions, apart from the eight cells above; hits, speed, timing and the save format.
- The maps of every area but Hearthvale and the North Fields.

## Done when
- [x] the eight new cells are solid and hold cherry trees, and nothing else about where the hero can go changed
- [x] the hero is never hidden behind a tree: standing behind one fades its crown
- [x] every tree tile has become a tall picture, and each still blocks its own cell
- [x] all earlier tests pass; new tests cover the trees, the fade, the cherry cells, petals, wind, water,
      reflections, mist and the outline rule
- [x] the frame cost is measured before and after
- [x] all 88 review shots retaken and compared
- [ ] (yours) it looks right in play

## Not in this step
- Normal maps on tree trunks (the pivot plan said I would try them): not done. Crowns are lit well enough by
  the lights from P1b, and trunks are a few pixels wide.
- A repaint of the ground tiles themselves (grass, paths): they change only through the palette and outline
  rule. The closed canopy inside thick woods is still a flat tile.
- Buildings, interiors and dungeons (1d); the hero and the villagers (1e).
