# Hero pass — outfit and movement (plan)

Asked for by the user on 2026-11-11: improve the hero's look, clothing and animation, keeping the controls and
the gameplay. The request was written for a 3D character (model, rig, skin weights, IK). Hearthvale's hero is a
16x24 pixel sprite painted from ASCII art, so this pass does what those words mean for a sprite, and says below
what has no meaning here.

## Who he is
A young man, a trained and travelled adventurer, in Hearthvale's own style. He keeps what the user asked for
earlier: the blue hood and tunic and the red scarf.

## Outfit (painted in `tools/art/make_player_sprite.gd`)
- a **leather vest** over the tunic, open at the front, and **wrist guards**
- a **belt pouch** on his right hip
- **pale slate trousers** (they stand apart from the gold hem above and the brown boots below) and **tall boots with cuffs**
- his **sword on his back**: the pommel and grip show over his shoulder from the front and from behind, with the
  sheath across the vest's back and its tip under the belt. In the attack frames the hilt is gone: the sword is
  in his hand. That is this game's drawing and sheathing.
- a **small pack** at the back of his belt, in olive canvas
- a **swept fringe** and a mouth, for a face with more in it
- cloth, leather, steel and canvas each have their own colours; `PixelGrade` warms them like the rest

## Movement (`PlayerAnimator`, `PlayerController`)
Seven new frames a row, all made by the tool from the drawn ones, so they can't drift apart from them:
- **Idle:** he breathes out for 0.9 s of every 2.6 (shoulders and head a pixel lower), and still blinks.
- **Sprint:** the walk cycle leaning forward (side view), with a longer stride so the feet keep pace.
- **Attack:** a short wind-up (sunk a pixel, gathering), the lunge as before, then settling. Only the picture
  changes: the blade is live from the first frame and the swing takes as long as it did.
- **Hit:** he flinches, eyes shut, as well as flashing red.
- **Landing:** after hopping down a ledge his knees bend for a moment.

## What a sprite has no use for
- A rig, skin weights, joint deformation, blending and foot IK: there is no skeleton. Foot sliding is handled the
  sprite way: the cycle advances by distance travelled.
- Jumping, dodging and climbing: the hero has none of them (CLAUDE.md: no climbing; the GDD has no jump or dodge),
  and this pass adds no mechanics. The ledge hop is the nearest thing, and it gets the landing.
- Turning: four facings change at once, as in the games this one follows.

## Done when
- [x] the new outfit is on every frame of every facing, with no frame left in the old clothes
- [x] the new frames show in play: breathing, the sprint's lean, wind-up and settle, the flinch, the landing
- [x] swing timing, hit detection, speed and collisions are untouched; all earlier tests pass
- [x] before and after pictures of the sheet and of the hero in the village are compared
- [ ] (yours) it looks right in play

## Would need hand-drawn art
- Run frames from the front and from behind (they are the walk frames for now).
- A wind-up with the sword arm drawn back, and a real follow-through frame.
- An idle fidget (a glance, a shift of weight), and the scarf's tail moving while he stands.
- The fallen frame in the new clothes: it is too small to show them, so it is unchanged but for the palette.
