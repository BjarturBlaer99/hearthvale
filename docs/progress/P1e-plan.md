# P1e — Characters (plan)

The fifth step of the pivot's visual overhaul (`docs/ROADMAP.md` P1). The hero is redrawn taller with his hood
down, walks and runs in six frames and swings in three; villagers stand as tall as he does and breathe and
blink. Swing timing, hits, speed and collisions are untouched.

## What changes
- **A taller hero, hood down** (decision 3 of the pivot): 16 by 32 pixels in place of 16 by 24. His head is a
  third of his height, not nearly half. His brown hair shows; the blue hood hangs behind his neck. He keeps the
  blue tunic, the red scarf and everything from the hero pass (vest, wrist guards, pouch, sword on his back,
  pack).
- **Drawn from parts** (`tools/art/make_player_sprite.gd`): each frame is a head, a body pose and a pair of legs
  for its facing, put together by the tool. One head serves every frame of a facing, so nothing drifts.
- **Six-frame walk and run:** step, weight down, legs passing, then the other side. Arms swing against the legs.
  The run is the walk leaning forward (side view), as before.
- **A three-frame swing, drawn for each facing:** wind-up, slash, follow-through. Which one shows is chosen by
  how far through the swing the motor is; the blade is live from the first frame, as before.
- **Villagers** (`tools/art/make_sprites.gd`): as tall as the hero, and each breathes and blinks in their own
  time. *(Changed while building: they were redrawn in the hero's proportions. Stretching the old robe left a
  small head on a long body.)*
- **Animals:** chickens already walk and peck and butterflies flap. A chicken standing still now blinks. *(Added
  while building: the roadmap names animals, and the frame is made by the tool, not drawn.)*
- **Enemies:** no new drawing. They took the new palette and outline rule when all art was re-baked in 1c.

## What does not change
- `PlayerMotor`, the sword's hit box, hurt boxes, speeds, the swing's length and when it hits.
- Where the hero's feet are: the taller sprite stands on the same spot.
- Which cell a villager fills: its own, and only that.

## Done when
- [x] the hero is 16 by 32, hood down, in every frame of every facing
- [x] walk and run cycle through six frames, advancing by distance travelled
- [x] a swing shows wind-up, slash and follow-through, and its timing and hit box are what they were
- [x] villagers are as tall as the hero and have idle frames
- [x] all earlier tests pass (those naming the old frames are rewritten); new tests cover the parts, the
      cycles, the swing and the villagers' idle
- [x] the sheet and the game are compared before and after
- [ ] (yours) it looks right in play

## Not in this step
- New drawings for enemies, animals or bosses.
- Run frames of their own from the front and back (they are the walk frames; only the side view leans).
- Jumping, dodging or climbing: the hero has none.
- Moving anyone: Elder Bram still stands at his hearth (see the log's known issues).
