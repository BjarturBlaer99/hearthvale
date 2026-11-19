# Tool polish — the plan

The user's words, 2026-11-19: "now polish the graphics and all animations when using tools".

This is phase 0: what is there today, what I propose, the decisions for the user, and the steps.
**Approved as written by the user on 2026-11-19** (all thirteen decisions as recommended). Each step then ends with all tests passing, new logic tested,
the work committed, and before-and-after pictures for the user to review.

**The before-pictures** are outside the repo, in the session group's notes folder
(`C:\Users\bjarturbg\AppData\Roaming\Claude\side-session-notes\local_fe741240-bb50-4dc5-9761-c88cbb6d3b6e\tool-polish-before\`): `films/` holds each stroke filmed frame by
frame (twelve pictures, 0.04 s apart, round the hero, at four times the game's size; a stroke of three
blows has three rows of six), and `shots/` holds 26 shots of `tools/capture.gd` (11, 112, 114, 115, 117,
118, 145, 151, 153, 154, 162, 163, 166, 168, 172, 174, 180, 181, 183, 184, 188, 193, 194, 195, 197, 198).

## 1. What each tool looks like in use today

Every tool, the seeds and the sprinkler stand the hero still for the tool's time (0.4 s) through the
motor's attack state, so **the hero plays the sword's three swing frames for all of them** (a fist up,
the slash, the follow-through), with the sword's hilt gone from his back as though it were in his hand.
Nothing is in his hands. The tool itself is its item icon floating over the cell he works
(`ToolFlash`): it dips six pixels to the ground and lifts again over the 0.4 s, then is gone. The work
is done the moment the button is pressed, and the sound plays then.

| Use | The hero | The tool | Effects | Sound |
|---|---|---|---|---|
| Hoe, tilling | sword swing frames | hoe icon over the cell | the soil is tilled at the press; a pale puff of dust that rises | `hoe` |
| Can, watering | sword swing frames | can icon over the cell, not tipped | seven 1-pixel pale blue drops, hard to see; wet soil at the press | `pour` |
| Can, filling at the pond or a well | sword swing frames | can icon over the water | none | `fill` |
| A seed | sword swing frames | the seed bag's icon over the cell | a small puff of dust; the seed at the press | `plant` |
| The sprinkler | sword swing frames | the sprinkler's icon over the cell | a small puff of dust | `plant` |
| Pickaxe on a rock, ore or a boulder | sword swing frames | pickaxe icon over the rock | a blow nudges the rock a pixel and raises pale dust; the last blow throws "shards", the broken pot's terracotta, then the stone lies there | `pick`, `rock_break` |
| Plain pickaxe at a boulder | nothing | nothing | none (no stroke, no time spent) | `nope` and words |
| Sword on weeds, a bush | the swing, with its drawn blade and trail | the sword | leaves; the weeds or bush gone at once, fibre lying | `sword`, `cut` |
| Sword on a log, a stump | the swing | the sword | pale dust; the log or stump doesn't move on a blow that doesn't break it, and has no hit flash; wood lying at the last | `sword`, `cut` |
| Picking a ripe crop (right click) | doesn't move | — | the crop is gone; green leaves burst | `harvest`, words |
| Petting, taking an egg, wool or milk | doesn't move | — | the badge over the animal goes | the animal's own, words |
| Hay into the Silo | doesn't move | — | none | `item_get`, words |
| The furnace | a conversation | — | the burning furnace flickers (as fires do) | — |
| Build mode, setting down | stands still (it is a screen) | — | a puff of dust | `set_down`, `take_up` |

What looks worst, seen in the films:
- **The sword's frames for every tool** (`hoe_side`, `can_pour_side`, `seed_plant`, `pick_rock`): he
  makes a sword cut at the air while a picture of the tool bobs in the cell beside him.
- **Facing up, the floating tool is drawn on his back** (`hoe_up`): he is two cells tall, and the cell
  he works is where his head is.
- **The can** (`can_pour_side`, `can_fill_pond`) neither tips nor splashes; the drops can hardly be
  seen.
- **A rock breaks into terracotta** (`pick_rock`, `pick_boulder_copper`): the pot's shards.
- **A log or a stump takes three blows without a sign** (`sword_log`, `sword_stump`) until it is gone.
- **Picking a crop** (`harvest`) and taking from an animal: the hero doesn't move at all.

Other things in the graphics that look unfinished beside these:
- **Mirrored frames are drawn one frame's width to the right** (`SpriteSheet.draw()` with `flip_h`,
  measured by the Homestead's phase 2): the village's chickens, a goblin seen from the side, the Warden
  and the Shade jump 16 pixels when they turn to face the other way. The farm's fences, hens, sheep and
  cows mirror in place themselves, so they are right.
- **A building site's twine** is drawn on each cell's top and left edges, so a site reads as a grid
  (shot 180), open on its right and bottom.
- **The Coop's, the Barn's and the Shed's windows stay dark at night** (they are drawn flat, "nobody
  lives in it"), beside the farmhouse's lit ones.
- (The Big Barn's roof, also noted by phase 3, was changed before phase 4: it is green boards now.)

## 2. What I propose

**The rule kept throughout:** the motor keeps its times (0.4 s for a tool, the sword's own cooldown),
and every new frame is chosen from the motor's own progress through the stroke, never the other way.
The work is still done at the press (the soil, energy, skill, words). Hits, collisions and what blocks
are untouched. Nothing new stands the hero still: the poses for work done by hand end the moment he
moves, as holding up a found item does today.

### A. The hero at work (new frames)
Four new poses, put together from parts in `tools/art/make_player_sprite.gd` like the others, for each
facing:
- **raise**: both hands up over the shoulder, the tool high (the hoe and the pickaxe before the blow);
- **strike**: bent forward, arms down, knees bent (the blow and after it);
- **pour**: both arms forward at the waist, a can's handle in the hands (the can, tipping);
- **reach**: one arm down and forward, a little crouch (a seed, the sprinkler, a crop, an animal, the
  Silo, the can dipped in water).

The sheet grows from 21 columns to 25; no old column moves, so the walk, the swing and the rest are as
they were. The sword's hilt stays on his back in all four (it is the sword that is put away). For a
0.4-s tool: the hoe and the pickaxe are raised until 0.35 of the stroke (the first 0.14 s) and strike
from there; the can pours for the whole stroke; a seed and the sprinkler reach for it.

### B. The tool in his hands
A new sheet, `gameplay/art/held_tools.png`, painted by `tools/art/make_sprites.gd` through `PixelGrade`:
the hoe, the watering can and the pickaxe, each in its three metals (plain, copper, iron: one drawing,
the head's colours swapped by the tool as it bakes), for each facing and each pose that holds it (the
hoe and the pickaxe raised and struck; the can held, tipped and dipped), and the sprinkler held in both
hands. It is drawn from his feet by a small node on the hero, as the sword's blade is: behind him when
he faces up, mirrored with him when he faces right. The pictures are named per item
(`HeldTools.FRAMES`, checked against the tool's order by a test), so a new tool is a picture and a
line. The floating icon (`ToolFlash`) is kept only for a tool that has no held picture, which after
this is none.

### C. The blow
New kinds of `Burst`, drawn in code as the old ones are, each coloured from what is struck:
- **hoe:** *clods*, four to six bits of soil thrown up a few pixels that fall back onto the cell within
  a third of a second (in place of the rising dust);
- **can, watering:** a short *stream* of drops from the spout into the cell while it is tipped, a
  little *splash* on the soil, and drops two pixels wide in a brighter blue;
- **can, filling:** a *splash* on the water and a *ring* that widens and fades on the water cell in
  0.4 s;
- **a seed:** three *seeds* falling from his hand into the soil;
- **pickaxe:** *chips* in the rock's own colours (an ore rock flecks its ore's colour) that jump and fall,
  a one-pixel spark where the head lands, and the rock shows its white flash picture for a moment and
  shakes as it does now; the last blow throws more chips, of the rock's colours, in place of the pot's
  terracotta;
- **sword on a log or a stump:** *splinters* of pale wood in place of dust; a blow that doesn't break it
  shakes it a pixel and flashes it white, as a rock;
- weeds, bushes and a picked crop keep their leaves (they look right).

The effects and the tool's sound come **at the blow** (0.35 of the stroke, 0.14 s after the press), and,
if the user agrees (D4), so does the cell's new look: the soil shows tilled when the hoe lands, wet when
the water reaches it, the seed when it falls. A pure `ToolStroke` (in `core/player/`) says, for a kind of
tool and a progress, which pose and whether the blow has come, and the tests hold it to the motor.

### D. Work done by hand
- **Picking a crop:** he reaches for it, then holds it up over his head for 0.6 s (the found-item pose,
  with the crop's picture); walking ends it at once.
- **Taking an egg, wool or milk:** the same, with the product.
- **Petting with nothing ready:** he reaches, and a small heart rises six pixels over the animal and
  fades within half a second.
- **Hay into the Silo:** he reaches toward its door, and a puff of chaff.

### E. The unfinished things
- **Mirrored frames in their own place:** `SpriteSheet.draw()` mirrors a frame where it stands, with a
  test in a window that measures where a mirrored frame lands, and a picture of each creature that
  turns (the village's chickens, a goblin, the Warden, the Shade) before and after. `PlacedArt` and the
  farm's animals, which mirror in place themselves, are looked at again but should not change.
- **The site's twine** round the outside of the site, with a peg at each corner (new tiles at the end
  of the atlas if it needs them).
- **The windows of the Coop, the Barn and the Shed lit at night**, with the lamps, as every window is,
  by a line in each building's data. The Well and the Silo have no windows.

### F. The film tool
`tools/capture.gd` learns film shots: a dozen pictures through a stroke, cropped round the hero and
enlarged, put in a grid (what made the before-pictures, written in a scratch folder). Every step's
before and after are films of the same strokes.

### Not proposed (say if you want any of them)
The bow (it too plays the sword's frames when shot), the furnace (it already flickers; it is lit
through a conversation), build mode (the hero stands still in it, and setting down already puffs and
sounds), the plain pickaxe at a boulder (it makes no stroke today, and a stroke would hold him still:
a timing change), new sounds.

## 3. Where this bends a standing rule

- **"A still world" (2026-11-13) forbids specks in the air and drifting things.** The new bursts are small
  things that fly: clods, the stream and splash drops, the ring on the water, seeds, rock chips,
  splinters, chaff and the petting heart. **Each comes from a stroke or a touch, lasts half a second or
  less, and falls to the ground or fades where it is:** none hangs in the air, drifts, loops or comes by
  itself. Bursts of this kind are in the game already (dust, leaves, drops, shards, sparkle) and were
  kept when the world was made still, but these are new, so they need the user's word (D5). **The heart
  is the one thing that rises** (six pixels) before it fades, and is a decision of its own (D8).
- **"Art must never change timing, hit detection or collisions":** not bent. Every frame reads the
  motor's progress; the motor's times, the sword's arc and reach, the cells that block and the moment
  the work is done are all as they are. The hand poses never hold him: moving ends them. **What moves in
  time is only when pictures and sounds show** (the blow's effects and sound 0.14 s after the press,
  D3; and with D4 the cell's new look). That is for show, but it is a change in what the player sees
  and hears and when, so it is put to the user.
- **The hero's sheet gains four columns** (the rule is to edit his art in its tool, which this does).

## 4. Decisions for the user

Each can be approved, changed or said no to on its own. My recommendation is given.

1. **D1. The hero's four work poses** (raise, strike, pour, reach) for every facing, in place of the
   sword's frames for tools. *Recommended: yes.*
2. **D2. The tool drawn in his hands**: hoe, can and pickaxe in three metals each, and the sprinkler; the
   floating icon retired. *Recommended: yes.*
3. **D3. The effects and the sound at the blow** (0.14 s after the press), not at the press.
   *Recommended: yes.*
4. **D4. The cell's new look at the blow too** (tilled, wet, sown). No: the cell changes at the press as
   now, and the hoe lands on soil already tilled. *Recommended: yes.*
5. **D5. The stroke bursts** (clods, stream and splash, the ring on the water, seeds, chips, splinters,
   chaff): a bend of "A still world", each short and falling or fading where it is. *Recommended: yes.*
6. **D6. Rocks, logs and stumps show each blow** (a white flash, a shake; chips in the rock's colours in
   place of terracotta; splinters from wood). *Recommended: yes.*
7. **D7. Work by hand shown:** a crop or a product held up, a reach for the Silo. *Recommended: yes.*
8. **D8. A heart over a petted animal** (the one effect that rises). *Recommended: yes.*
9. **D9. Mirrored frames drawn in their own place** (the chickens, goblins, the Warden and the Shade stop
   jumping when they turn). *Recommended: yes.*
10. **D10. The site's twine round its outside.** *Recommended: yes.*
11. **D11. The Coop's, the Barn's and the Shed's windows lit at night.** No: they stay dark, as built.
    *Recommended: yes.*
12. **D12. Film shots in `tools/capture.gd`**, for the before-and-after of every step. *Recommended: yes.*
13. **D13. Leave out** the bow, the furnace, build mode, the plain pickaxe at a boulder and new sounds.
    *Recommended: leave them out.*

## 5. The steps

Each step: all tests pass (headless suite with `--continue`, exit 0), new logic has tests, the work is
committed, `LOG.md` and `DECISIONS.md` are written, and I stop with a short summary and before-and-after
pictures. A step whose decision is said no to is dropped or shrinks.

**Step 1 — The hero at work, with the tool in his hands (D1, D2, D12).** The four poses in
`make_player_sprite.gd`; `PlayerAnimator` gains a work pose chosen by `ToolStroke` from the motor's
progress; the held tools' sheet and the node that draws them; the film shots.
Tests: `ToolStroke` (each kind's poses and its blow, at the stroke's edges); the animator's columns
against the tool's (the existing test, with four more); every tool, seed and the sprinkler has a held
picture or a hand pose; a stroke stands him still exactly as long as before, frame for frame, and he
moves again on the same frame; the sword's swing shows the swing frames as before; facing up, the held
tool is drawn behind him. Pictures: films of the hoe, the can (pouring and filling), the pickaxe, a
seed and the sprinkler, in each facing, before and after.

**Step 2 — The blow (D3, D4, D5, D6).** The new bursts; the effects, the sound and (D4) the cell's look
at the blow; rocks, logs and stumps flash and shake; chips in the rock's colours.
Tests: each burst kind exists, lasts no more than half a second and ends at or below where it began
(nothing left in the air); before the blow there is no effect and after it there is; the soil is tilled
in `GameState` at the press and drawn tilled from the blow; a stroke cut short by a hit still shows the
cell; breaking and cutting cost, give and take as many blows as before; the rock's chips take its
colours. Pictures: films of the hoe, the can, the pickaxe on a rock, ore and a boulder, the sword on a
log and a stump.

**Step 3 — Work by hand (D7, D8).** Picking a crop and taking a product held up; the reach for the Silo;
the petting heart.
Tests: the pose shows and walking ends it at once; he can move on the next frame; nothing about the
harvest, the product or the hay changes. Pictures: films of picking a turnip, taking wool, petting a
hen, hay into the Silo.

**Step 4 — The unfinished things (D9, D10, D11).** Mirrored frames in place; the site's twine; the
buildings' windows at night.
Tests: a mirrored frame covers the same columns as the unmirrored one (in a window); the site's twine
cells; each building's windows lit from dusk to dawn and dark by day. Pictures: each creature facing
both ways, before and after; a site; the farm at night with its buildings.

After the last step: the coordinator is told what `CLAUDE.md` should say (the poses, the held tools,
the blow, the bend of "A still world" as approved), since `CLAUDE.md` is the coordinator's to edit.

## Step 1 — built (2026-11-19)

The hero's four work poses (`make_player_sprite.gd`, columns 21 to 24, from his own parts), the
tools in his hands (`held_tools.png`, 57 frames: the hoe, the pickaxe and the can in three metals and
the sprinkler), `ToolStroke`, `HeldTools`, `HeldTool`, the animator's `WORK` pose, and film shots in
`tools/capture.gd` (`-- <dir> film [names]`). What was decided in building it:
- **The poses are made from his existing parts:** raise is the swing's wind-up body, strike and
  pour the slash's, reach the follow-through's a pixel lower, so his hands are where the swing's
  are and the held tools take hold there (the fists are painted in the tool's picture).
- **From behind, the blow and the can are hidden by him** (he is two cells tall and the cell he
  works is behind his back): the hoe and the pickaxe show raised over his head, then nothing; the
  can and the sprinkler show nothing.
- **The sprinkler leaves his hands at the blow**, so it is never shown twice (in his hands and on
  the plot); until step 2 it is on the plot from the press.
- **A seed is sown by hand:** the reach, with nothing in it (the seeds that fall are step 2's).

## Step 2 — built (2026-11-19)

The blow (D3 to D6). The motor says when a stroke's blow comes (`struck`, at 0.35 of the stroke, or
as it ends early); the area keeps each stroke's sound, bursts and new look for it. What building it
decided:
- **The blow is the motor's signal, not the animator's:** tests that step the motor see it, and a
  hit before the blow still shows the cell and plays the sound.
- **A rock is struck at the press and shown at the blow,** as the soil is: its cell is free and its
  stone is there at once, but the rock is drawn whole and the stone hidden until the pickaxe lands
  (the hero cannot move before then). The ladder a rock hid shows at the blow too.
- **What the sword cuts was always cut at its blow** (the sword's arc touches it mid-swing), so the
  sword is as it was; a log and a stump now shudder and flash on each blow and throw splinters
  (their data's burst), as a rock does.
- **The flash is the white picture laid over at a little over half strength**, for 0.06 s: drawn
  whole it read as a white blob.
- **The new bursts fall:** each is thrown up and lies where it lands (its `floor`) before it fades;
  none is in the air when it ends. The older bursts are drawn as they were.
- **From behind, the water is hidden:** facing up, only the splash shows on the cell.
- **Filling the can says so at the press** ("The watering can is full."), with the ring and the sound at the
  blow.

## Step 3 — built (2026-11-19)

Work by hand (D7, D8): `PlayerController.reach()` and `hand_up(icon)`, `HeartPop`, the `chaff` burst,
and three films (`take_wool`, `pet_hen`, `silo_hay`). What building it decided:
- **The reach is the work pose's reach column** (step 1's), for 0.15 s; the hold-up is the found-item
  pose for 0.6 s after it (a found item's is 1.1 s, as before).
- **A product the pack has no room for** is neither taken nor held up: he reaches, and no heart shows
  (the words say why).
- **The heart is a child of the animal,** so it rises over the animal even as it walks; it is drawn in
  code, five pixels wide, outlined in `PixelGrade.INK`.
- **Hay put in the silo** reaches and throws chaff only when hay went in; a full silo or an empty
  pack is words only.

**Step 4 waits for the art switch** (the user, 2026-11-19: "Keep, switch next"): step 3 stays as
built, the switch to PNG art comes next, and step 4's site twine is then drawn by editing the tile
atlas PNG, not a tool.

## Step 4 — built (2026-11-19)

After the switch to PNG art (`9231a9e`), as approved:
- **D9:** `SpriteSheet.draw()` mirrors a frame in its own place (`target_of()`): a window probe measured
  a 16-pixel frame painted at x 41 to 52 landing at 59 to 70 mirrored, and at 43 to 54 after the fix.
  The village's hens, side-on goblins, the Warden and the Shade stand on their node facing either way.
- **D10:** the two site tiles of the atlas PNG (row 28) lost their string and peg (a one-off pixel
  edit, the dug soil of the same tile put in their place); `BuildingArt.twine()` draws one string round
  the site's outside, a pixel in from its edge, with a peg of nine pixels at each corner (the old peg's
  colours).
- **D11:** a building's data may say `"lit_at_night": true` (the Coop, the Barn, the Shed); once it
  stands, `PlacedBuildings.glow` (a `WindowGlow`) lights the glass of its windows (a house's, and the
  barn's loft) with the lamps, from dusk to dawn, as the farmhouse's are. The Well and the Silo have none.
- Capture shot 208: the farm at night with every building standing.
