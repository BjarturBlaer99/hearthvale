# Art pass 4 — light and lettering (plan)

Asked for by the user on 2026-11-11: improve the graphics substantially, keeping the gameplay, the controls and
the game's identity; consistency before effects; one scene first, then the whole game.

## What was weakest (from the 88 review screenshots)
1. **Flat light.** Nothing cast a shadow sideways, and nothing that burns gave light: a hearth, a lamp post and a
   brazier were pictures of light on an evenly lit screen. Houses and dungeons had no depth.
2. **Lettering that didn't belong.** All text was the engine's smooth default font over pixel art, and every box
   was a plain rectangle. The controls hint sat unbacked on top of the scene.
3. **Still air.** Apart from chimney smoke, critters and water, nothing moved.

The tiles, sprites and colour were already in good shape after art passes 1 to 3, so they are left alone.

## Direction
**Warm storybook light, in whole pixels.** Light comes from the north-west outdoors and from fire indoors; dim
places are a deep violet, never grey or black; light is warm. Text and boxes are pixel art like everything else.
No bloom, no blur, nothing that hides an enemy. Still no external assets: every part is made in code.

## The standard, set in the village square, then applied everywhere
- **Cast shadows** (`HeightShading`): a tall solid thing shades the ground to its east as well as its south, with
  the corner joined, so houses, trees, walls and pillars stand on the ground.
- **Glows** (`Glows`, `Ambience`): a soft round of warm light added around lamp posts, hearths, candles, burning
  torches, crystals (in their colour) and the hero's lantern. Fires flicker.
- **Gloom** (`Darkness`, reused): houses and dungeons that aren't `dark` are a little dim away from their lights.
  The hero always stands in a pool of light. It is for show: the game's own light rule (the crypt) is untouched.
- **Vignette** (`AreaHud`): the screen's corners are shaded lightly.
- **Motes** (`Motes`): a few specks in the air: pollen outdoors, dust in houses and dungeons.
- **A pixel font** (`tools/art/make_font.gd`): Hearthvale's own, painted from ASCII art like the sprites, baked
  with a UI theme that gives every label a one-pixel shadow. Sizes are whole multiples of the font's size.
- **Framed boxes** (`PanelFrame`): the dialogue box, the menus and the HUD's corners share one frame. The controls
  hint gets a box of its own.

## Done when
- [x] the village square, a house, a dungeon room and the crypt show the standard in screenshots
- [x] every area gets it without a scene saying so (the kind of place is read from its tiles)
- [x] nothing about movement, combat or what the crypt's dark hides has changed; all earlier tests pass
- [x] new tests cover the kinds of place, the glows, the gloom, the cast shadows, the motes, the font, the frames
- [x] before and after screenshots from the same spots are compared
- [x] (yours) it looks right in play (reported on 2026-11-11)

## Not in this pass
- Repainting tiles or sprites, new animation frames, new props or map changes.
- The title screen's backdrop, beyond its lettering and menu box.
- Wall torches in the keep and the cistern: they have no light sources of their own, so their rooms are lit only
  around the hero. Sconces would need map changes and a re-bake.
