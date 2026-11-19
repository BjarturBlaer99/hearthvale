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
volume, fullscreen, window size, the controls hint), or quit to the title. Quitting to the title saves first,
and so does closing the window. The save before the last is kept as a backup: if a save can't be read,
Continue says so and offers it. The game has sound effects and music
(made in code). The pause menu also shows your play time.

| Action | Keyboard | Gamepad |
|---|---|---|
| Move (8 directions) | WASD / arrow keys | Left stick / d-pad |
| Sprint (hold) | Shift | B |
| Use what is in hand: the lit slot of the bar at the bottom | Left mouse button (a click anywhere) | X (sword), Y (item) |
| Choose what is in hand: sword, bow, bombs, hoe, can, pickaxe, seeds, sprinklers | Mouse wheel, or 1 to 9 | Shoulder buttons |
| Talk / read / pick up / harvest | Right mouse button | A |
| Choose an answer, or read on | Point and left click; or W / S, the wheel or arrows, then a left click or Enter | d-pad, then A |
| Choose in a menu | Point and click; or W / S, the wheel or arrows, then a click or Enter | d-pad, then A |
| Swing the sword whatever is in hand | Space / J | X |
| Use the item on the item button (bow, bombs, hoe, can, seeds) | Q / K | Y |
| Food menu (eat something) | Tab / I | Back |
| Build mode, on your own farm: set things down, move them, take them up | B; then point and left click to set down, right click to take up, the wheel or 1 to 9 to choose (or WASD, Space and Q); B, Tab or Esc to leave | Left stick click; then d-pad, X to set down, A or Y to take up, shoulders to choose |
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
- **What friendship opens** (the pivot, step 4d): at two marks a villager asks a favour or teaches a recipe.
  Pip wants a pumpkin pie and trades a secret for it; Guard Rolf wants three loaves for the watch; Farmer Oda
  wants five sheaves of wheat; Elder Bram wants a stew and tells more of Sir Aldric. Wenna teaches berry jam,
  Tilda carrot cake and Shepherd Edda shepherd's pie. At three marks Wenna and Shepherd Edda each ask a
  favour that wants something from the quarry: five coal for dye, two iron bars for new shears. At four marks
  each gives a present, once. The quest log scrolls now, and the ending counts the days it took, the crops
  grown and the friends made.
- **Friendship and gifts** (the pivot, step 4c): talk to a villager and the first talk of the day is worth a
  little friendship. Carry food and their conversation offers "I brought you something.", which opens a list
  of what you carry: one gift a villager a day, and one they like is worth three times another. Four points
  make a mark and five marks a full friendship; a mark gained is said at the top of the screen. The pause
  menu's **Friends** page shows everyone's marks.
- **Skills** (the pivot, step 4b): combat, farming and cooking rise with use, five levels each. Monsters
  beaten raise combat, cells tilled and crops picked raise farming, dishes cooked raise cooking. Each level
  takes a tenth off the energy of that skill's work (a swing and a shot; the hoe and the can), and each level
  of cooking adds a tenth to the energy a dish gives. A level rising is said at the top of the screen, and
  the pause menu shows all three. Skills never change hearts, damage or speed.
- **The story over days** (the pivot, step 4a): a new game begins with a quest, "A Place of Your Own", in the
  quest log (Esc, Quests). It says where your farm is, how to till and plant, and what comes next. Elder
  Bram welcomes a newcomer and speaks of the old keep only once a first seed is in the ground. Until he gives
  his word the keep's gate in the Old Wood is chained. The bars under the chapel lift at dawn on the day after
  the Warden falls, so there is a night at home between the two dungeons.
- **The mouse in menus, and an item bar** (asked for on 2026-11-15): in every menu the mouse points, and a
  click chooses the line it is on. A bar along the bottom of the screen has a slot for each thing that can be
  in hand; the wheel steps through it and the keys 1 to 9 choose a slot. The Tab menu is for food.
- **A still world, and the mouse** (asked for on 2026-11-13): nothing in the scenery moves but the water.
  The left mouse button uses what is in hand: the sword, or a tool where there is work for it (the hoe, the
  can and seeds on the plot; the sword everywhere else), and answers in a conversation. The right button
  talks, picks up and harvests.
  Moving is on the keys as before, and Space and Q still do the sword and the item.
- **Tilda's list, and meals from the harvest** (the pivot, step 3c): talk to Tilda for a list to buy from
  (seeds of every crop, bread, arrows, bombs) and one to sell your harvest on. At home the hearth cooks five
  meals from crops: roast turnip, mushroom soup, vegetable stew, pumpkin pie, and bread from wheat. The
  stronger ones mend hearts as well as giving energy. With this the farm pays for itself: plant, water,
  harvest, then eat, cook or sell.
- **Seeds and crops** (the pivot, step 3b): turnips, carrots, wheat, potatoes and pumpkins. A seed is planted
  from the item button in tilled soil; a crop grows a stage each morning if it was watered the day before,
  withers after two dry mornings in a row, and waits when ripe; a right click picks it. The harvest can be eaten raw. A
  first pouch of turnip seeds lies in the farmhouse; Tilda sells the rest.
- **A plot to farm** (the pivot, step 3a; on the homestead since 2026-11-17): the field below the
  farmhouse. The hoe and the watering can lie in the farmhouse and go on the item button: the hoe tills a
  cell, the can waters it and fills at the farm's pond (or the village's well or pond). Watered soil is
  dry again by morning.
- **Hours and night** (the pivot, step 2e): Tilda's shop is open from 08:00 to 18:00; villagers who stand
  outdoors go home at 20:00 and are back at 06:00; house windows are lit from dusk to dawn; monsters met in the
  fields and the wood at night are tougher and drop coins more often; and the night has a tune of its own.
- **Food and cooking** (the pivot, step 2d): berries, mushrooms and fallen cherry blossom to gather, back each
  morning; bread at Tilda's; food is eaten from the food menu (Tab) for energy; and the hearth at home cooks from
  recipes (cherry blossom tea, for a start).
- **Energy** (the pivot, step 2c): a bar under the hearts. Sprinting, swinging the sword and shooting the bow
  spend it. Low on energy the hero slows; out of it he collapses and wakes at home, a little poorer. Sleep
  refills it. It never costs a heart.
- **A home and a bed** (the pivot, step 2b; moved by the Homestead): the farmhouse on your own land is the
  hero's home, with a door and a room inside. Sleeping in the bed starts the next day with full hearts and
  saves the game; stay up until 02:00 and he wakes there anyway. (Until the Homestead it was the thatched
  cottage west of the weaver's, which is now locked.)
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
- **The Homestead** (asked for on 2026-11-17; phases 1 and 2 of five are built): an old farmstead of your own.
  Follow the lane west out of Hearthvale, past the last cottage and through the trees: it is a few
  seconds' walk. The farmhouse there is your home (the bed, the hearth and the workbench are inside), your
  field lies below it across the road, and a pond in the south-west corner fills the watering can.
  - **One corner of the field is clear** and can be tilled on the first morning. The rest of it, and
    the land around, is overgrown: cut weeds, bushes, fallen logs and old stumps with the sword, and
    break rocks with the Pickaxe. They leave fibre, wood and stone, and never come back. A boulder wants
    the Copper Pickaxe and a great boulder the Iron one. Soil can't be tilled until it is cleared.
  - **Build mode** (phase 2): on the farm, **B** opens it. The mouse points at a cell (or move the
    ghost with the movement keys): it is green where the thing fits and red where it doesn't, with
    the reason in words. **Left click** sets the thing down, **right click** takes one up; the
    **wheel** or **1 to 9** choose what to set down; **B**, **Tab** or **Esc** leave. Time stands
    still while you build. Without a mouse, Space sets down and Q takes up.
  - **Fifteen things to set down:** three paths and two floors, three flower beds, a fence that
    blocks and a gate you walk through, a hedge, a bench, a lamp post that lights at dusk, and oak and
    cherry saplings that grow into trees over a few mornings. Nine are made at the workbench (its
    new "Place" tab: press A or D to turn to it), and Tilda sells the hedge, the flower beds and the
    saplings.
  - **The hand,** the build bar's first slot, moves things: click a thing to lift it, click again to
    set it down. Not on trees, water, the house, the road, the field, or anything still to be cleared.
  - **An older save loads as it was:** a game saved in the old cottage opens in the farmhouse, and its
    soil and crops are in the field's clear corner.
  - **The farm has its own tune,** and a quieter one after dark.
- **Willowmere:** a marsh east of the village. Climb the stairs at the south end of the east meadow and
  follow the planks through the gap in the trees. Boardwalks cross the water between its banks and islets;
  cattail root, marsh berries and bog mushrooms grow there, and two of them make Marsh Stew at your hearth.
  Look behind the willows in the north-east. After dark, Bogwisps rise over the pools: their touch takes
  energy as well as hearts, and a sword only bites inside the light of the Lantern. Old Henrik stands by
  the hut by day: befriend him, bring him three Wisp Embers, and he lights the marsh lanterns and teaches
  Ember Tea.
- **The Old Quarry:** a disused mine in the north-east corner of the North Fields: over the bridge, then
  east along the old rails. Buy a Pickaxe at Tilda's (25 coins), put it in hand on the item bar, and strike
  the rocks. Ore shows in the rock: copper on the first three floors, iron and coal on the next three,
  gold and crystals on the last three, which are dark. A ladder down is under one of each floor's plain
  rocks; reaching floors 4 and 7 opens the lift in the entrance hall. The rocks are back each morning, in
  the same places with other things in them. Mining takes energy, so bring food. Tilda buys the ore, the
  bars a furnace makes of it, and crystals; she has no use for stone, coal or wood.
- **Crafting at home:** the workbench stands by the east wall of your farmhouse. Face it and right-click for
  its list: what you know how to make, what the thing under the cursor needs beside what you have, and
  greyed out what you can't make yet. New things appear on the list as you find what they are made of.
  - **The furnace** (20 stone, 5 copper ore) smelts overnight: load it with three ore and a coal for each
    bar, up to five bars, and take them out the next morning.
  - **The storage chest** (10 wood, 1 copper bar) holds 24 stacks. Left and right turn between your pack
    and the chest; a click moves the stack under the cursor across.
  - **Wood:** cut fallen branches and old stumps with the sword in the North Fields, the Old Wood and the
    South Field. They are back each morning.
  - **Better tools:** copper and iron hoes and watering cans work two and three cells in a line; copper and
    iron pickaxes break a rock in fewer blows. Each is made from the tool before it.
  - **Sprinklers** go on the item bar: set one on a tilled, empty cell of the plot and it waters the four
    cells beside it every morning. Right-click it to take it up again.
  - Also: bombs from coal and stone, a standing lamp, a woven rug, and the Miner's Lantern, which lights
    further than the Lantern.
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
  - **The Lantern** is in a tomb behind the first locked door. Carry it and you see further, and a right click lights torches.
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
the ending), `-- warden`, `-- quarry` (the mine's entrance hall with a Pickaxe), `-- craft` (at home by the
workbench, with ore, bars and wood for most of its list), `-- homestead` (arriving on your farm with a sword
and all three pickaxes; add `20:30` for its night), `-- farm` (on the farm's road above the field, with the
hoe, the can and seeds) or `-- build` (on the farm by the farmhouse, the ground cleared, with a stock of
all fifteen things to set down, and wood, stone and coins: press B). Saving in a scenario goes to a slot of its own, so it never replaces your own game.

To have a script play eight days by pressing real keys (the balance pass's run: the field's clear corner,
Tilda's counter, the quarry, the furnace and the workbench): `godot --path . -s res://tools/play_days.gd -- <folder>`. It
takes about 35 minutes, uses a save slot of its own, and writes what each day cost and paid to the folder.

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
