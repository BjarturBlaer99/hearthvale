# P1d — Buildings, interiors and dungeons (plan)

The fourth step of the pivot's visual overhaul (`docs/ROADMAP.md` P1). Walls, pillars and roofs get height,
in the same way the trees did in 1c: pictures drawn over the map at load, with the map itself untouched. No
collision, hit, speed or timing changes, and no map is re-baked.

## What changes
- **Walls with a face and a top** (`WallRelief`, `ReliefAtlas`, `tools/art/make_relief.gd`). Until now a wall was
  one flat tile whichever way it was seen. Now:
  - a wall cell with open floor to its south shows its **front face**: bricks in a dungeon, boards under a beam
    in a house, mossy blocks on a ruin, lit along the top edge and dark at the floor
  - every other wall cell shows its **top**: one flat shade, dark in a dungeon (the walls rise into the dark),
    light out of doors, edged where it ends
  - a face is **a third taller than a cell**: it rises eight pixels over the foot of the wall behind it. It
    doesn't rise into the next room of a dungeon, and a wall one cell thick shows a strip of top above a
    shorter face.
- **Pillars stand up** (`Scenery`): a picture 28 pixels tall over each pillar tile, sorted by depth, so the hero
  walks behind it. A pillar hides only the feet of whoever is behind it.
- **Roofs have a ridge** (`Scenery`): a strip eight pixels high above the top row of every roof, in the roof's
  own thatch, tile or slate, sloping away at the gable ends. It is sorted just inside the building's top edge,
  so someone walking behind a house has their feet hidden by the roof.
- **Light response is hand-shaded, not normal-mapped.** The pivot plan said I would try normal maps on dungeon
  walls. With walls now split into a lit face and a dark top, the shading that normal maps would give is
  painted in, and it stays in whole pixels. I did not build normal maps.

## What does not change
- The Height layer of every area: every wall, pillar and roof tile is where it was, so every cell blocks or
  doesn't exactly as before. No `.tscn` map file changes in this step.
- House fronts in the village (their walls were already drawn as fronts), furniture, doors.

## Done when
- [x] every wall of the three kinds shows a face or a top, by the rule above, in dungeons, houses and ruins
- [x] no face rises into the room behind it
- [x] every pillar tile has a standing pillar and every roof's top row a ridge
- [x] no map file changed, and all earlier tests pass
- [x] new tests cover the wall rule, the rise, the pillars, the ridges and the atlas
- [x] the frame cost is measured before and after
- [x] all 88 review shots retaken and compared
- [ ] (yours) it looks right in play

## Not in this step
- A repaint of the house fronts, furniture, floors or doors.
- Taller furniture (shelves and bookcases still fit their cells).
- The hero and the villagers (1e).
