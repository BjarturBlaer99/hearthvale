# PixelLab prompts: the mobs

Prompts for the six monsters, for the user to make in PixelLab and bring in, as the new art was
(`art/incoming/`). Each prompt says what the game needs: the size, the frames in their order, which way
it faces, and where its feet are. Written 2026-11-23.

**How to use them**
- Paste the **style line** first and then the mob's own prompt. If PixelLab has a field for the
  colour palette, give it `art/palettes/hearthvale.gpl`.
- **Make each picture at the game's size if PixelLab lets you pick it** (16x16, 16x24 or 32x40). The
  hero's sheet showed that a big picture shrunk to 16 pixels loses its face. If it only offers larger
  sizes, take the smallest and keep the shape simple and bold.
- One frame at a time is fine. Make the first frame, then ask for the others "the same character, now
  …", so they match.
- **You don't need to make the white flash row:** I add it, fit the frames to the sheet, check
  them against `art/sheets.json` and record them in `docs/ASSETS.md`.
- Don't name another game or its characters in a prompt: Hearthvale's art is its own.

## Style line (for every mob)

> Pixel art game sprite, top-down three-quarter view, transparent background, no anti-aliasing, crisp
> single pixels. Cosy storybook fantasy look with soft saturation and many shades per material. Light from the top left,
> shadows lean violet. Outline only where the shape needs one, in a dark shade of the colour inside it,
> never black. Centred in the frame, nothing touching the edges.

## Slime — `slime.png`, 16x16, 3 frames

Hops toward the hero in fields, the quarry's first floors and the dungeons. The weakest monster: it
should look harmless, almost cute.

> A small round green slime blob, 16x16 pixels, glossy jelly with a bright highlight on its top left,
> two small dark eyes, a darker green underside and a soft shadow edge at its base. Sits on the ground
> with its bottom on the frame's last row, centred.

Frames, in order:
1. **rest**: sitting, round.
2. **wide**: squashed flat and wide, about to jump (lower and wider, same base).
3. **hop**: stretched tall and narrow, in the air (its bottom lifted 2–3 px off the last row).

## Bat — `bat.png`, 16x16, 3 frames

Flutters erratically in the ruin, the dungeons and the quarry's middle floors.

> A small cave bat seen from above at a three-quarter angle, 16x16 pixels, dusky purple-brown fur, leathery
> wings with lighter membrane between dark finger bones, tiny pointed ears, two small bright eyes. Its
> body centred in the frame.

Frames, in order:
1. **rest**: wings half open, level.
2. **up**: wings raised high.
3. **down**: wings swept low.

## Goblin archer — `goblin.png`, 16x24, 5 frames

Keeps its distance and shoots arrows. Fields, dungeons, and the quarry's floors 4 to 6.

> A small goblin archer, 16 pixels wide and 24 tall, green skin, long pointed ears, a hooded brown
> leather tunic, a short wooden bow, a quiver on its back. Mischievous rather than frightening. Feet on
> the frame's last row, centred.

Frames, in order:
1. **front**: facing down (toward the viewer), bow held low.
2. **front_draw**: facing down, bow raised and string drawn.
3. **back**: facing up (away), the quiver showing.
4. **side**: facing **left**, bow held low. (The game mirrors it for facing right.)
5. **side_draw**: facing left, bow raised and string drawn.

## Bogwisp — `wisp.png`, 16x16, 3 frames

A marsh light that rises over Willowmere's pools at night and down on the quarry's dark floors. It
drifts slowly, flares, then darts. Its touch tires the hero. The game draws its glow and its light,
so the sprite is only the little body of light.

> A small will-o'-the-wisp, 16x16 pixels, a pale blue-green flame-like spirit with a brighter white-green
> core, a soft wispy tail trailing below, two faint dark eyes. Floating in the middle of the frame, nothing on the
> last two rows.

Frames, in order:
1. **a**: its flame leaning a little left.
2. **b**: leaning a little right (the two take turns as it drifts).
3. **flare**: bigger and brighter, the core almost white, about to dart.

## Iron Warden — `warden.png`, 32x40, 4 frames (the keep's boss)

An old iron guardian set in the keep by a knight long ago. Slow, heavy, stomping. Blows clink off
it. It opens a single eye in its helm, which is where an arrow stuns it.

> A hulking ancient iron golem knight, 32 pixels wide and 40 tall, blue-grey riveted plate armour with
> worn edges and a little rust, broad shoulders, heavy gauntlets, a great helm with a narrow visor slit.
> Old and solemn rather than evil. Feet on the frame's last row, centred.

Frames, in order:
1. **stand**: standing, the visor dark.
2. **step**: mid-stride, one foot lifted, leaning forward.
3. **gaze**: standing, a **single bright amber eye** glowing in the visor slit (the tell: this frame must
   read at a glance).
4. **stunned**: slumped, head down, arms hanging, the eye out.

## Crypt Shade — `shade.png`, 32x40, 3 frames (the crypt's boss and the story's last foe)

A shadow bound in the crypt under the chapel. It drifts and blows pass through it, until the
braziers' light binds it.

> A tall hooded shade, 32 pixels wide and about 36 tall, a ragged cloak of deep violet and near-black
> shadow, no visible body, two pale glowing eyes under the hood, its hem fading into wisps with no
> feet. Floating: the bottom of its hem 2–3 px above the frame's last row, centred.

Frames, in order:
1. **drift_a**: its hem trailing left.
2. **drift_b**: its hem trailing right (the two take turns as it drifts).
3. **bound**: held by light: drawn in, the cloak pulled tight and paler at the edges, the eyes wide.
