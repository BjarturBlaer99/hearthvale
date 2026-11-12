# P1b — Light (plan)

The second step of the pivot's visual overhaul (`docs/ROADMAP.md` P1). Real 2D lights and an ambient colour for
each area take the place of the glow sprites and the two sheets of dark; shadows get soft edges. Nothing about
movement, combat or timing changes.

## What changes
- **`AreaLighting`** (new, `world/areas/`): one per area. It sets the area's ambient colour with a
  `CanvasModulate` and keeps a pool of `PointLight2D` nodes, which the area fills every frame.
  - **Ambient colour by kind of place:** clear outdoors (the hour will colour it in P2), a warm dimness in
    houses, a cool dimness in dungeons, and near black in a `dark` area.
  - **Two kinds of light.** A **pool** shows what it reaches in its true colours (the engine's "mix" blend), so
    two pools that overlap never glare. A **glow** adds its colour on top (the "add" blend), for the warm bloom
    round a flame, and for lamps in daylight.
- **Which lights:** a pool round the hero wherever it is dim; a pool and a glow at every hearth, candle, lamp,
  burning torch and crystal (in its colour); the lantern's glow.
- **The crypt's dark is drawn by the rule's own lights.** `LightRules` still says how lit a point is. In a
  `dark` area the only pools are the rule's lights, each at exactly the rule's place and radius, with a
  light picture made from the rule's own falloff. Glows there stay inside a light's fully lit core, so no
  light shows anything the rule says is dark.
  - One honest difference: the rule takes the brightest light; overlapping pools add up a little where two
    half-lit edges cross. It is never darker than the rule says, and never lit where the rule says dark.
- **Soft shadows.** Cast shadows from trees, walls and buildings fade out in two steps over six pixels. Every
  shadow under an actor, a pickup or a prop is drawn by one helper (`SoftShadow`): a dark heart and a fainter
  rim, tinted violet.
- **Removed:** `Glows` and `Darkness` (the glow sprites, the show-only gloom, the crypt's shader sheet).

## What does not change
- `LightRules`, `AreaController.lights()` and `brightness_at()`: the rule is the same.
- What the crypt hides. Where no light reaches, things are as dark as before (about a twentieth).
- Collisions, hits, speed, timing, maps and the save format.

## Done when
- [x] in the crypt, every rule light has a pool at the same place and radius, and there are no others
- [x] a check in a window compares drawn pixels with the rule at points lit, half lit and dark
- [x] houses and dungeons are dim away from their lights and clear around the hero
- [x] the frame cost is measured before and after, in the village, a house, the keep and the crypt
- [x] all earlier tests pass (those about the removed nodes are rewritten for the new ones); new tests cover
      the ambient colours, the kinds of light, the falloff against the rule, and the shadows
- [x] all 88 review shots retaken and compared
- [ ] (yours) it looks right in play
