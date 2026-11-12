# The pivot — phase 0: audit and plan

Asked for by the user on 2026-11-12. Hearthvale becomes a story-driven RPG with survival and farming, with a
modern pixel-art look. This document is the plan only: nothing in the game has changed. Phases 1 to 4 wait for
approval, and each starts with its own short plan.

Hearthvale stays its own game. It takes the farming-and-village genre's mechanics, not any one game's art,
interface or characters.

## 1. Where things stand
- **The hero pass is committed** as `ffa36a7` on `hearthvale` (345 tests pass). It is not pushed, and it has not
  been tried in play.
- **Still open from the playtests:** no whole-game run has reached the ending screen since the fixes; the
  new-player playtest was never run; one playtest run stopped with exit code 4 and no error, unexplained.
- The roadmap's last criterion (a new player finishes unaided in about two hours) is still unmet. The pivot
  replaces it; see section 8.

## 2. Decisions I need from you
Each has my recommendation. Everything else in this plan follows from these.

| # | Decision | Options | I recommend |
|---|---|---|---|
| 1 | Resolution and grid | See section 4. Three real choices | **Option 1:** 640x360 on the same 16-pixel grid, with taller sprites |
| 2 | Camera indoors (only with option 1) | Rooms shown at twice the size, or small in the middle of the screen | **Twice the size** |
| 3 | The hero's look | Keep the pointed blue hood, or wear it down so his hair shows | **Hood down**, keeping the blue tunic and red scarf |
| 4 | The hero's home | The game has none today. Use the doorless thatched cottage in Hearthvale, with a new one-room interior | **Yes** (it is a new area scene, so it needs your word) |
| 5 | New cherry trees block cells | About eight new one-cell trees in Hearthvale; North Fields by swapping existing trees | **Yes**, with the exact cells listed before baking |
| 6 | Day length | 12, 14 or 16 real minutes | **14 minutes** |
| 7 | The clock in dungeons | Runs, or stands still underground | **Stands still** |
| 8 | Saving | Sleep only, or sleep and the pause menu | **Both** |
| 9 | Phase 1 in six steps, each with a review stop | One stop at the end, or six | **Six** |

## 3. What conflicts with today's rules
I would change these documents first, on approval, before any code.

- **`CLAUDE.md` and the GDD say no stamina, and that sprint never runs out** (your request of 2026-11-08). Energy
  replaces both.
- **`CLAUDE.md` and the GDD call the game "A Link to the Past style"** and the hero "Zelda-style". Both get
  rewritten for the new direction, with new design pillars.
- **"Do not build anything outside the current milestone"** points at H10 to H15. The roadmap gets a new phase 3
  (P1 to P4, these phases).
- **"No new areas beyond the farm plot"** against sleeping, cooking and waking at home: the hero has no home.
  Decision 4.
- **Phase 1's "no collision changes"** against cherry trees that block like other trees. Decision 5. The home's
  door (one wall cell becoming a doorway) is the other map change, in phase 2.
- **"Art must never change gameplay timing"** stays true, with one planned exception: low energy slows movement
  and the sword (phase 2).
- **The hero exception** ("keep the blue suit") against a hero who no longer reads as a homage. Decision 3.

## 4. Resolution: the one big choice
**640x360 alone does not add detail.** On a 16-pixel grid it only shows more of the world: 40 by 22 cells in
place of 30 by 17. Detail comes from how many pixels each thing is drawn with. So the choice is the grid.

| | Option 1 | Option 2 | Option 3 |
|---|---|---|---|
| Screen | 640x360 | 640x360 | 640x360 |
| Grid cell | 16 px (as now) | 24 px | 32 px |
| Cells in view | 40 x 22 (more than now) | 27 x 15 (about as now) | 20 x 11 (much closer) |
| Pixels per thing | Same per cell; sprites drawn taller (hero 16x32, trees 32x48) | 2.25 times | 4 times |
| A dungeon room on screen | Small, so the camera doubles indoors | Just over half the screen | Fills the screen |
| Code changes | Camera and UI only | Every pixel number and scene position times 1.5 | Every pixel number and position times 2 |
| Art to repaint (my estimate) | About as much as the last three art passes together | Roughly double option 1 | Roughly four times option 1 |
| Play | Unchanged | Unchanged | Archers can shoot from off screen above and below |

- **Why option 1.** The cosy modern pixel look comes from tall characters, multi-cell trees and buildings, soft
  light, wind and water, not from smaller pixels. Option 1 puts the work there, and no gameplay number moves.
- **Its cost.** Rooms and house interiors are small (a dungeon room is 15 by 11 cells), so indoors the camera
  shows them at twice the size. Pixels are then twice as big indoors as outdoors.
- **If you want finer pixels,** option 2 is the one to take. It keeps today's framing, and I can do it in safe
  steps (scale the world first with the old art stretched, then repaint family by family).
- **This machine:** the monitors are 2560x1440, which is exactly 640x360 four times. Window sizes become 2x, 3x
  and 4x.

## 5. Phase 1 proposals (the look)
**Direction:** a soft storybook countryside. More shades per material, less flat saturation, violet shadows and
warm lights kept. Outlines only where a shape meets a busy background.

**Proposed steps, each ending with tests, a commit, screenshots and a stop:**

| Step | What | Notes |
|---|---|---|
| 1a | The frame: 640x360, indoor camera, every screen laid out again, HUD with room for hearts and an energy bar | The bar stays hidden until phase 2 |
| 1b | Light: real lights and ambient colour, soft shadows | Replaces the glow sprites and the show-only gloom |
| 1c | Ground and nature: new palette, terrain, tall trees you walk behind, cherry blossoms and petals, wind, water, fog in the Old Wood | The cherry tree cells are listed here first |
| 1d | Buildings, interiors and dungeons in taller three-quarter view | |
| 1e | Characters: a taller hero with more frames; idle animations for villagers and animals; enemies in the new palette | |
| 1f | UI polish: frames, a second larger letter face for headings, the title screen | |

- **Light.** One ambient colour per area (`CanvasModulate`) and a `PointLight2D` at each lamp, hearth, candle,
  torch, crystal and the lantern.
  - I tested it on this machine: real lights work in the project's renderer, and 24 lights over a full screen
    cost about 0.9 ms a frame.
  - The crypt's dark stays a rule (`LightRules`), drawn with the same lights at the same sizes.
  - **Normal maps:** not everywhere. I would try them on dungeon walls and tree trunks, and keep them only if
    they look right in review.
  - **Shadows:** soft and baked for trees and buildings; no hard real-time shadows by default, because they
    crawl on pixel art.
- **Walking behind things.** Tall art goes on a y-sorted layer. A tree still blocks exactly one cell; its crown
  only overlaps the cell behind it. A crown fades when the hero stands behind it, so nothing hides him.
- **Wind, water, fog.** One sway shader for grass, flowers, crowns and cloth. Water gets moving ripples, foam at
  the bank and a mirrored reflection. The Old Wood gets two slow layers of mist.
- **Cherry blossoms.** Crowns in four pinks over dark bark, swaying; petals as particles on the wind; settled
  petals on the grass and floating on the pond.
  - **Hearthvale:** by the chapel, round the pond and along the main path. Two existing tree clumps become
    cherry trees; about eight are new.
  - **North Fields:** existing trees swapped, so no cell changes.
- **Animation.** Hero walk and run from four frames to six, and a three-frame attack drawn for each facing.
  Villagers breathe and blink; chickens peck.
- **Tests.** Collision and hitbox tests stay as they are. All 88 review shots are taken before and after.

## 6. Phase 2 proposals (energy, food, time)
All numbers live in one data file, so tuning needs no code. These are starting values.

**Energy** (a bar of 100, separate from hearts):

| Action | Cost |
|---|---|
| Sprinting | 0.25 a second (about 6.5 minutes from full) |
| A sword swing or a bow shot | 0.5 |
| Hoeing a cell | 2 |
| Watering a cell | 1 |
| Walking, talking, harvesting | nothing |

- **Low energy** (under 25): movement at 85%, the sword 30% slower. Under 10, no sprinting.
- **At zero:** the hero collapses, wakes at home the next morning with half energy, and loses a tenth of his
  coins (30 at most). Dungeon progress is kept. Hearts are untouched.
- **Sleeping** refills energy and hearts, ends the day and saves.

**Time**
- A day runs from 06:00 to 02:00 in 14 real minutes (42 seconds an hour). At 02:00 the hero passes out, as at
  zero energy.
- The clock stops in conversations, menus and (decision 7) dungeons.
- **Light by the hour:** peach at dawn, clear by day, orange then violet at dusk, blue at night. Lamps and
  windows light at dusk.
- **Hours:** Tilda's shop 08:00 to 18:00. Villagers who stand outdoors go home at 20:00. Hours are data.
- **Night monsters** (outdoors, 20:00 to 06:00): half as much health again, 15% faster, and they see further.
  They drop coins more often.

**Food** (eaten from the item menu; cooked at the hearth at home from JSON recipes):

| Food | From | Energy | Hearts |
|---|---|---|---|
| Wild berries | foraged | 8 | |
| Mushroom | foraged in the Old Wood | 6 | |
| Bread | Tilda's shop, or 2 wheat | 30 | |
| Cherry blossom tea | 3 blossoms | 15 | |
| Roast turnip | 1 turnip | 22 | |
| Mushroom soup | 2 mushrooms, 1 potato | 35 | half |
| Vegetable stew | potato, carrot, turnip | 60 | one |
| Pumpkin pie | 1 pumpkin, 1 wheat | 80 | two |

Raw crops can be eaten for about a third of their cooked value.

## 7. Phase 3 and 4 proposals
**Farming** (phase 3)
- **The plot:** 18 cells of soil (6 by 3) across the road from the hero's cottage, where the grass is open today.
- **Tools:** a hoe and a watering can (ten pours, refilled at the well or the pond), used from the item button
  like the bow. Seeds are planted the same way.
- **Growth:** a crop grows one stage each morning if it was watered the day before. Two dry mornings in a row
  and it withers. No seasons and no weather (not asked for).

| Crop | Days | Seed price | Sells for |
|---|---|---|---|
| Turnip | 3 | 5 | 12 |
| Carrot | 4 | 8 | 18 |
| Wheat | 5 | 6 | 10 |
| Potato | 5 | 10 | 24 |
| Pumpkin | 8 | 20 | 60 |

- **The shop** needs a buy-and-sell list. Today buying is a conversation with one line per ware, which won't
  stretch to seeds and crops.

**RPG and story** (phase 4): proposed in full before that phase, as you asked. In outline:
- three skills (combat, farming, cooking) that rise with use and lower what each action costs
- friendship with each villager, from talking once a day and from gifts they like
- Elder Bram's quest opens after the first crop is planted; saves from before the pivot count as past that point
- the ending screen gains days, crops grown and friendships

## 8. Every system the pivot touches

| System | Today | What changes | Phase |
|---|---|---|---|
| `GameState` | Hearts, flags, quests, inventory, play time, place. Save version 1 | Energy, day and minute, farm cells, friendships, skills. Version 2 | 2, 3, 4 |
| `SaveSystem` | Loads version 1; a migration hook exists but is empty | A version 1 to 2 migration (full energy, day 1, 06:00, no farm), with tests on a real old save | 2 |
| `PlayerMotor` | Walk 72, sprint 120 px a second; sprint is free | Speed and sprint read the energy rules | 2 |
| Combat | Sword cooldown 0.3 s from item data | Cooldown stretched at low energy; swings cost energy | 2 |
| Inventory and items | Eight item types; the item menu equips one item | New types: food, seed, crop, tool, ingredient. The menu also eats | 2, 3 |
| `DataRegistry` and schemas | Items, quests, dialogue, enemies, breakables | New kinds: foods, recipes, crops, rules, schedules, gifts. New conditions (time of day, day number, friendship) and effects (energy, friendship) | 2, 3, 4 |
| HUD | Hearts, area name, two lines of text, a controls hint, laid out for 480x270 | Laid out again; an energy bar, a clock and the day | 1, 2 |
| Other screens | Eight scenes with fixed 480x270 positions | Laid out again; a shop list; a cooking list; the ending's new lines | 1, 2, 3, 4 |
| `AreaController` | Runs an area; adds glows, gloom, motes | Lights, time of day, a clock that runs, villagers' hours, soil and crops, the bed and hearth | 1, 2, 3 |
| Light (`Glows`, `Darkness`, `Ambience`) | Glow sprites and a shader sheet | Real lights; `Ambience` keeps deciding the kind of place | 1 |
| `HeightShading` | Cliff faces, edges, short shadows | Softer, longer shadows; the foam moves to the water shader | 1 |
| Enemies | Five kinds from data | A night rule on health, speed and sight | 2 |
| `Quests` and dialogue | Three side quests; Bram's story | Bram's quest gated; more quests and lines; gifts | 4 |
| `Audio` | Synthesised effects and tunes | New effects (eating, hoe, water, harvest, cock-crow, collapse); a night tune | 2, 3 |
| Art tools | Tiles, hero, other sprites, font, all at 16 px | A new palette and outline rule in `PixelGrade`; tall art; new tiles, sprites and icons | 1, 2, 3 |
| Maps (`build_maps.gd`) | Eleven areas | Cherry trees; the cottage door and its interior; the farm plot | 1, 2, 3 |
| Settings | Window sizes as multiples of 480x270 | Multiples of 640x360 | 1 |
| Tools (`capture`, `playtest`) | 88 shots; scenario starts | New shots; starts on a given day and hour | 1, 2 |
| Tests | 345, mostly in cells, so most survive | New suites for energy, food, recipes, the clock, growth, migration | all |

## 9. Risks
- **Phase 1 is the largest piece of work in the project so far.** I paint every picture in code and judge it
  from screenshots, and I can't see motion. Six review stops keep it from drifting.
- **Energy against dungeons.** A long fight costs energy, and collapsing in the crypt means the walk back. The
  swing cost is low for that reason, and it needs a playtest.
- **Sprint becomes a cost.** You asked for free sprint on 2026-11-08 and the game is paced for it. At 0.25 a
  second it should still feel free for short runs; this is the number most likely to need changing.
- **The game gets longer by design.** A story spread over days no longer fits "about two hours". I propose the
  new aim is the main story in six to eight in-game days.
- **Wider view** (option 1) shows more of each map at once, so a few hidden things are easier to spot.
- **Old saves.** A finished version 1 save must still load, finished.
- **The unverified hero pass** will be repainted in step 1e; its frame logic carries over.

## 10. Not included unless you ask
Seasons, weather, livestock you own, crafting beyond cooking, fishing, an inventory limit, new areas beyond the
home and the plot, swimming, climbing.
