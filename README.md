# Hearthvale

A 2D top-down action-adventure in the style of *A Link to the Past*: start in a small medieval village, explore
the countryside, and delve into dungeons full of enemies and puzzles. Find new weapons, and grow from three hearts
into a hero.

## Getting started with Claude Code
1. Install Godot 4.x (latest stable) and make sure `godot` is on your PATH.
2. Run `claude` here and say: **"Read CLAUDE.md and the docs, then start the next milestone."**
3. After each milestone, review `docs/progress/LOG.md`, play the build, commit, then ask for the next one.

## Playing the current build
Run `godot --path .` to reach the title screen. Choose **New game** to start in Hearthvale, or **Continue** to pick
up a save. Press **Esc** (gamepad Start) to pause: from there you can save, change the settings (music and sound
volume, fullscreen, window size, the controls hint), or quit to the title. The game has sound effects and music
(made in code). The pause menu also shows your play time.

| Action | Keyboard | Gamepad |
|---|---|---|
| Move (8 directions) | WASD / arrow keys | Left stick / d-pad |
| Sprint (hold) | Shift | B |
| Talk / read / pick up / harvest | Left mouse button (a click anywhere) | A |
| Choose an answer | W / S or arrows, then a click | d-pad, then A |
| Swing the sword (once you have it) | Space / J | X |
| Use the equipped item (bow, bombs) | Q / K | Y |
| Item menu (choose what's equipped) | Tab / I | Back |
| Pause menu (save, settings, quit) | Esc / P | Start |

Read the sign in the square, then walk into a door: Elder Bram lives in the blue-roofed house, Wenna the weaver
in the house west of the road. The Wooden Sword lies in the fenced training yard south-west of the square, next
to a straw dummy to practise on. Mind the brambles (half a heart each touch); the red heart heals. At zero hearts
you wake up back where you entered the area. Take the stairs up to the chapel on the north rise, or to the meadow
in the east; hop down a ledge to come back.

Follow the road south out of the village to the **South Field**:
- slimes hop about the meadow
- a goblin archer guards the plateau (take its stairs, and watch for it drawing its bow)
- bats roost in the old ruin

Beaten enemies sometimes drop hearts or coins.
- **Bow:** for now it lies in the South Field's ruin, with ten arrows. It moves into the first dungeon later.
- **Tilda's shop:** the red house beside the training yard. She sells ten arrows for 5 coins and three bombs for 8.
- **Bombs:** set one down, step back, and it blows up enemies nearby.
- **The Ruin Cellar:** a three-room test dungeon down the stairway in the ruin.
  - A chest in the entry hall holds the small key for the locked door.
  - Beat the hall's slimes to lift the bars on the big key's alcove.
  - The big key opens the boss door. Doors and chests you open stay open.
- **The Cistern:** five puzzle rooms down a stairway in the cellar's inner room.
  - Push the sandstone block (walk into it and keep pushing), stand on the plate, and hit the crystal.
  - Bomb the cracked wall.
  - The treasure room has two ways in: a block on the plate, or an arrow into the crystal up on the platform.
- **A livelier Hearthvale:**
  - a market stall in the square, crates, kegs and lamp posts
  - a washing line, chickens in the field, butterflies over the flowers
  - furnished houses
  - more folk to talk to: Farmer Oda, Pip and Guard Rolf (and Shepherd Edda in the North Fields)
- **Tall grass and pots** everywhere: cut and smash them with the sword (or a bomb) for hearts, coins, arrows and
  bombs.
- **Four heart pieces** are hidden around the world; four make a new heart. The villagers drop a hint or two.
- **Quests:** three villagers have work for you. Ask Wenna the weaver, Farmer Oda and Guard Rolf. A notice tells
  you when a quest starts, moves on or is done, and the pause menu's **Quests** entry shows where each stands.
- **A new look** (art pass 2):
  - the hero walks with a four-frame stride, blinks, lunges with the sword and holds up what they find
  - Hearthvale's houses are half-timbered, under thatch, clay tiles or slate, with smoking chimneys
  - grass frays over the paths, the pond has a bank, and the woods mix three kinds of tree under a closed canopy
- **A warmer look** (art pass 3): sunnier grass, warmer paths, brighter water, and soft coloured outlines in
  place of black ones, on everything.
- **Light and lettering** (art pass 4): lamps, hearths, torches and crystals glow; houses, trees and walls cast
  shadows; houses and dungeons are dim away from their lights; and all text is the
  game's own pixel font in framed boxes.
- **The hero** (hero pass): a leather vest, wrist guards, a belt pouch and tall boots over the blue tunic, the
  sword on his back until he swings it, and a small pack. He breathes when he stands, leans into a sprint,
  winds up before a swing, flinches when hit and bends his knees landing from a ledge.
- **A still world, and a click to interact** (asked for on 2026-11-13): nothing in the scenery moves but the
  water, and talking, picking up and choosing are on the left mouse button. Moving, the sword and the item
  are on the keys as before.
- **Seeds and crops** (the pivot, step 3b): turnips, carrots, wheat, potatoes and pumpkins. A seed is planted
  from the item button in tilled soil; a crop grows a stage each morning if it was watered the day before,
  withers after two dry mornings in a row, and waits when ripe; a click picks it. The harvest can be eaten raw. A
  first pouch of turnip seeds lies in the cottage (seeds are sold from step 3c).
- **A plot to farm** (the pivot, step 3a): eighteen cells of soil between Tilda's shop and the well. The hoe
  and the watering can lie in the hero's cottage and go on the item button: the hoe tills a cell, the can
  waters it and fills at the well or the pond. Watered soil is dry again by morning.
- **Hours and night** (the pivot, step 2e): Tilda's shop is open from 08:00 to 18:00; villagers who stand
  outdoors go home at 20:00 and are back at 06:00; house windows are lit from dusk to dawn; monsters met in the
  fields and the wood at night are tougher and drop coins more often; and the night has a tune of its own.
- **Food and cooking** (the pivot, step 2d): berries, mushrooms and fallen cherry blossom to gather, back each
  morning; bread at Tilda's; food is eaten from the item menu for energy; and the hearth at home cooks from
  recipes (cherry blossom tea, for a start).
- **Energy** (the pivot, step 2c): a bar under the hearts. Sprinting, swinging the sword and shooting the bow
  spend it. Low on energy the hero slows; out of it he collapses and wakes at home, a little poorer. Sleep
  refills it. It never costs a heart.
- **A home and a bed** (the pivot, step 2b): the thatched cottage west of the weaver's is the hero's own, with
  a door and a room inside. Sleeping in the bed starts the next day with full hearts and saves the game; stay
  up until 02:00 and he wakes there anyway.
- **A day that passes** (the pivot, step 2a): a day runs from 06:00 to 02:00 in fourteen minutes; dawn is
  peach, dusk orange, night blue; lamps light at dusk; the day and the hour show under the hearts.
- **A finished look to the screens** (the pivot, step 1f): a painted evening on the title screen, a larger
  letter face for headings, corner brackets and a ruled heading on every box, and a smaller corner for the
  hearts.
- **Taller people** (the pivot, step 1e): the hero stands two cells tall with his hood down, walks and runs in
  six frames and swings in three; villagers are as tall as he is and breathe and blink; a chicken standing still
  blinks.
- **A wider picture** (the pivot, step 1a): the game draws 640x360, so more of the world is in view outdoors;
  houses and dungeon rooms are shown at twice the size. The window is 1920x1080 at the default 3x.
- **Real light** (the pivot, step 1b): every lamp, hearth, candle, torch and crystal is a light, houses are warm
  and dim, dungeons cool and dim, and shadows have soft edges.
- **Living nature** (the pivot, step 1c): trees stand tall and you walk behind them; Hearthvale has cherry trees
  in blossom, with fallen petals on the grass and the pond; water ripples, foams at the bank and mirrors
  you; the Old Wood has mist. Only the water moves.
- **Walls with height** (the pivot, step 1d): dungeon and house walls show a lit front and a dark top, pillars
  stand tall, and roofs have a ridge you walk behind.
- **The road north:** from the top of the north rise, through the woods.
  - **The North Fields:** a stream with a bridge, a farm plot, slimes, and a goblin archer on a plateau. Keep an eye
    on the tree line beside the road.
  - **The Old Wood:** a road winding between clearings, up to the keep's gate. There's an old walled shrine with
    something inside, and one stretch of its wall looks cracked.
- **The Old Keep:** the first real dungeon, at the top of the Old Wood.
  - Ten rooms: small keys, a room with two plates (stand on one, push the block onto the other), and crystals.
  - **The Bow** is in its armoury; goblin archers on a walkway have to be shot down.
  - The big key opens the Iron Warden's hall. Blows clink off its iron: wait for its eye to open, put an arrow in
    it, then use your sword while it's stunned.
  - Beat it for a heart container, and the way out opens behind it.

- **The Chapel Crypt:** the second dungeon, under the chapel on Hearthvale's north rise. Bars hold its door
  until the Iron Warden is beaten (ask Guard Rolf).
  - It's dark. The first rooms are lit by braziers; further in you see only what your own light reaches.
  - **Pits:** stepping into one costs half a heart and puts you back at its edge. Push a block in to bridge one.
  - **The Lantern** is in a tomb behind the first locked door. Carry it and you see further, and a click lights torches.
    Lit torches open barred doors; in the Knight's Tomb three of them burn only for a few seconds.
  - **The Iron Sword** is in the Knight's Tomb, and hits harder than the wooden one.
  - **The Crypt Shade** waits behind the boss door. Blows pass through it: light all four braziers in its hall
    and strike while the light holds it. It puts them out again, so be ready to relight them.

- **The story:** talk to Elder Bram again once the keep is quiet, and read the inscriptions in the keep, by the
  chapel door and in the crypt. They say what the Warden was for, and how the Shade is beaten.

Beating the Crypt Shade ends the game: after the closing words comes an ending screen with your time, hearts and
quests finished. From there you can keep exploring or save and go back to the title.

To try one part without playing up to it: `godot --path . -s res://tools/playtest.gd -- crypt` (the top of the
crypt's stairs, equipped as after the keep), `-- shade` (outside the Shade's hall), `-- ending` (one step from
the ending) or `-- warden`. Saving in a scenario goes to a slot of its own, so it never replaces your own game.

Running a playtest with someone new? `docs/progress/H15-playtest.md` says how, and what to write down.
`godot --path . -s res://tools/playtest.gd -- full` runs the whole game for it, on a save slot of its own, and
logs when things happen.

## Docs
- `CLAUDE.md` — rules for Claude Code
- `docs/GDD.md` — game design
- `docs/TECH_DESIGN.md` — architecture
- `docs/ROADMAP.md` — milestones H0–H9 (the vertical slice) and H10–H15 (phase 2)
- `docs/data/` — example content files and the condition/effect vocabulary
- `docs/DECISIONS.md`, `docs/progress/` — running records

The project started as a water-level game called *Low Tide*; that version is kept on the `water-version` branch.
