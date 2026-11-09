# Art pass 2 — hero, houses and the land (plan)

Asked for by the user on 2026-11-09, between H13 and H14: better graphics, a better-looking hero with better
animation, and houses that look more medieval. No new mechanics, areas or content, and still no external assets:
everything is painted in code.

## The hero
- **Look:** the blue hood and tunic stay. Added: a red scarf (a small accent, and it shows movement), clearer arms
  and hands, and more shading.
- **Animation** (the sheet grows from 3 to 9 frames a row):
  - **Walk:** a four-frame cycle. Hands swing in front and back views; in side view the legs pass each other and
    the scarf's tail flutters.
  - **Idle:** the hero blinks.
  - **Attack:** a lunging pose behind the sword's swing, one for each facing.
  - **Item get:** arms up, with the item held overhead for a moment, when taking an item or opening a chest. It's
    for show only: the hero can move at once.
  - **Fallen:** a collapsed pose at zero hearts, in place of a grey tint.
- `PlayerAnimator` (pure, tested) chooses the frame from movement, a pose and a blink clock.

## Houses
- **Two-storey fronts:** a half-timbered upper floor (dark beams and braces over plaster, lattice windows with
  shutters) over a ground floor on a stone footing, with an arched plank door with iron bands.
- **Roofs** with gable boards at the ends: thatch for the cottages, red clay tiles for the shop (still "the red
  house"), blue slate for Elder Bram's (still "the blue-roofed house"). Stone chimneys with drifting smoke.
- **A hanging sign** over the shop door.
- **The chapel** in stone: lancet windows, an arched double door and a cross on the ridge.
- Footprints, doors and what's solid stay as they are: only the pictures and the split between roof and wall
  rows change.

## The land
- **Soft edges:** grass frays over the edges of paths, and water gets a bank and a foam line, drawn from the map
  at load.
- **Forests:** three kinds of tree mixed by position, and a closed canopy where the wood is thick, in place of a
  grid of identical trees.

## Done when
- [x] the hero has the new look and all five animations, and the animator's tests cover them
- [x] every village house and the chapel show the new fronts and roofs, with doors still working
- [x] paths, water and woods show the new edges and trees in every outdoor area
- [x] all tests pass, and before and after screenshots are reviewed

## Deliberately not in this pass
New animations for villagers or enemies, taller buildings or trees that overlap the hero, lighting, weather,
interiors, a HUD redesign.
