# Plan: mining and crafting

The user's request, 2026-11-17: the Old Quarry (a mine of nine floors), a Pickaxe, a Mining skill, and
crafting at home (a furnace, a workbench, a chest, sprinklers, tool upgrades), in phases with a stop after
each. This is phase 0: the plan, and no code.

**Status: approved as written on 2026-11-17. Phase 1 is being built.**

## Sixteen things to decide

Each is a place where the request meets a rule or a system the game already has. Each has a choice already
made, the simplest that fits. Approving the plan approves these.

| # | Where the request meets the game | What the plan does |
|---|---|---|
| 1 | **The clock stands still in dungeons** (GDD §6). In the mine it would make mining free of time, and a mining day could not be weighed against a farming day. | A new kind of place, "underground": lit like a dungeon, but the clock runs. At 02:00 he wakes at home, and a collapse works as anywhere. The keep and the crypt are untouched. |
| 2 | **A Bogwisp lies low by day** and rises at 20:00 (its data says `"appears": "night"`). | Underground there is no day: a Bogwisp is always out there. Outdoors nothing changes. No new enemy file. |
| 3 | **The Lantern is in the crypt,** the last dungeon. Without it a Bogwisp can't be hit, and floors 7 to 9 are lit a cell or so round the hero. | As asked: "the Lantern matters". The deep floors can be mined before the crypt, but only by dodging. Wisp Embers can then be won by day in the mine, which makes Henrik's favour a little easier late in the game. |
| 4 | **A fall costs nothing.** Out of hearts, the hero wakes at the area's entrance with full hearts. On a floor that would be the ladder he came down. | In the mine he wakes in the quarry's entrance hall: he keeps what he carries and loses his depth. Same words, same full hearts. |
| 5 | **Ladders up.** Today's ladder down is under a random rock, so a ladder up to the floor above has nowhere certain to arrive. | A ladder up always climbs out to the entrance hall. Going down is floor by floor, or by the lift. |
| 6 | **Breakables come back on every visit** (grass, pots). Rocks and wood that did would be endless. | A breakable's data may say `"returns": "daily"`: broken, it stays broken until the next morning. Rocks, branches and stumps say so. Grass and pots stay as they are. |
| 7 | **Sword or axe for wood.** | The sword. Branches and stumps are breakables, and the sword already breaks breakables: data and pictures only, no new tool, no slot on the bar. |
| 8 | **Do bombs break rocks?** They are craftable from what the mine gives, and they cost no energy. | No: only the pickaxe breaks a rock. Otherwise bombs would mine for free. |
| 9 | **The pack has no slots.** It holds one stack of each thing, up to that thing's own limit. | The chest's 24 slots are 24 stacks, each up to the item's limit. Its use is keeping more ore, bars and crops than one stack. |
| 10 | **There is no placing of things.** "Placed at home" would need a new way to put furniture on a grid. | Each furnishing has its own fixed place in the cottage. Made at the workbench, it appears there. Only the sprinkler is carried: it is set on a plot cell from the item bar, as a seed is planted. |
| 11 | **The item bar is for what is held in the hand** (the rule of 2026-11-15: ask first). | The Pickaxe goes on the bar as the hoe does. I am asking for the sprinkler too. The bar already moves along when there are more than nine things. |
| 12 | **The cottage already has a rug and a candle,** baked into its map. | The crafted rug is a second, woven one beside the bed. The crafted lamp is a standing lamp, and a real light. |
| 13 | **"A skill changes energy only"** (P4b). The request gives Mining a chance of extra ore. | As asked: Mining is the one skill that does more than energy. The rule in the docs is amended to say so. |
| 14 | **A wider Lantern** lights more of the crypt too, and makes a Bogwisp solid from further off. | As asked: 56 to 80 pixels. It makes both a little easier, late in the game. |
| 15 | **Tilda buys only crops,** and "cooking" owns the folder `data/recipes`. | Her shop's data gets a `buys` list. Crafting recipes get their own folder, `data/crafting`, and their own schema. |
| 16 | **The North Fields change.** The quarry needs a way in. | Six cells of the east tree line, north of the stream, become a rock face with the mine's mouth in it (cells 38 to 39, rows 5 to 7). One re-bake of that map, as the village had for the marsh walk. |

**Worth knowing**
- **This is the largest addition since the pivot:** ten new scenes (the hall and nine floors), four new
  screens (the workbench, the chest, the furnace's and the lift's lists), nineteen items, sixteen recipes.
- **A sixth heart piece.** Four make a heart and five exist. With the quarry's there are six: one heart and
  two pieces left over.
- **Enemies come back on every visit,** as everywhere. Rocks don't (decision 6).
- **Unlocking "by finding items"** needs the game to remember what he has ever held, or a recipe would
  vanish when he sells his last ore. A flag is set the first time an item is picked up (`found/<item>`).

## The Old Quarry

**Where.** In the north-east corner of the North Fields, past the stream: over the bridge, then east. About
twenty seconds from the cottage door. Open from day 1; the Pickaxe is what it takes to get anywhere.

**The entrance hall** (15 by 9, no monsters): the way out, the lift, the first ladder down, and two rocks
to try the pickaxe on.

```
###############
#.....T...T...#     T  timber prop      =  old rails (for show)
#..=======L...#     L  the lift: floors 4 and 7, once reached
>.............#     >  out to the North Fields
#.............#     v  the ladder down to floor 1
#.............#     o  a rock
#....o...o..v.#
#..T.........##
###############
```

**The nine floors.** Each is one screen (20 by 11 cells): the whole floor is seen at once, but for the dark
on floors 7 to 9. The sketches show the shape; the counts in the table are what gets built.

| Floor | Name | Rocks | Of them, each day | Monsters | |
|---|---|---|---|---|---|
| 1 | The Cut | 16 | 5 copper | 2 slimes | |
| 2 | The Galleries | 16 | 5 copper | 3 slimes | one rock plugs a gap |
| 3 | The Old Face | 16 | 5 copper | 4 slimes | three rocks plug a corridor |
| 4 | The Coal Seam | 16 | 3 iron, 4 coal | 3 bats | **lift** |
| 5 | The Crossing | 16 | 3 iron, 4 coal | 2 bats, 1 archer | |
| 6 | The Ledges | 16 | 3 iron, 4 coal | 2 bats, 2 archers | archers on raised ledges |
| 7 | The Dark Drift | 14 | 2 gold, 2 coal | 2 Bogwisps | **lift**, dark |
| 8 | The Flooded Gallery | 14 | 2 gold, 1 crystal, 2 coal | 3 Bogwisps | dark, pools |
| 9 | The Heart of the Quarry | 17 | 2 gold, 2 crystal | 4 Bogwisps | dark, no ladder down, the heart piece |

Legend: `#` rock wall, `.` floor, `o` a rock, `<` where he arrives (the ladder up), `s` slime, `b` bat,
`g` goblin archer, `w` Bogwisp, `~` water, `^` raised floor, `-` its edge, `S` stairs, `H` the heart piece.

```
 1 The Cut                 2 The Galleries           3 The Old Face
####################      ####################      ####################
#<.....o.....o....##      #<...o...###...o...#      #<.....o..o...s....#
#......o...........#      #........o....s..o.#      #..o..........o....#
#..oo........##..o.#      #.oo.....###.......#      #...###########.oo.#
#..o....s....##..o.#      #.o...s..###..oo...#      #...###########....#
#...........oo.....#      #........###..o....#      #ooo###########..s.#
#.o......o.......s.#      #....o...###.....o.#      #...###########o...#
#.oo.....o....o....#      #...oo...###.......#      #.o.###########o...#
#..................#      #.s...........o....#      #......s...o.......#
##................##      #........###..o....#      #...o......o....s.o#
####################      ####################      ####################

 4 The Coal Seam           5 The Crossing            6 The Ledges
####################      ####################      ####################
#<..oo.......##....#      #######....o.#######      #^^^^^g^^^####^^g^^#
#....oo......##..b.#      #######.b.o..#######      #^^^^^^^^^####^^^^^#
#.....oo...........#      #######.o....#######      #---S-----####--S--#
#......oo..........#      #<...o...oo....o..g#      #<....o........o...#
#..b....oo.....o...#      #....o...oo....o...#      #..oo......b.......#
#........oo........#      #........o.........#      #..o....oo.....oo..#
#.........oo....##.#      #######o.....#######      #.......o......o...#
#..........o....##.#      #######...b..#######      #.o...........b....#
#.......b..........#      #######.oo.o.#######      #.oo....o..o.......#
####################      ####################      ####################

 7 The Dark Drift          8 The Flooded Gallery     9 The Heart of the Quarry
####################      ####################      ####################
#<....o....#########      #<...~~~~~....o...##      #<.......o....#..H.#
#..........#########      #....~~~~~..o......#      #.............#....#
#######.o..#########      #..o...........~~~.#      #...oo........#ooo##
#######....o...oo..#      #..o..w..~~~...~~~o#      #...o.....w........#
#######..w....o....#      #.o......~~~..o~~~.#      #.........##....o..#
#######o...#####.o.#      #~~~..o..~~~.......#      #.w.......##....oo.#
#..o.......#####...#      #~~~..o.......w..o.#      #......o...........#
#.o..o.....#####.w.#      #~~~.....o.....o...#      #..o...o....w...o..#
#.o........#####o.o#      ##......oo...~~~.w.#      #..oo......o....w..#
####################      ####################      ####################
```

**The day's roll.** A floor's rocks are always in the same cells. Which of them hold ore, and which plain
rock hides the ladder, is a shuffle from three numbers: a number kept in the save, the day, and the floor.
So the roll is the same all day and across a save and a load, and different tomorrow. Ore shows in the
rock (copper flecks, a black seam, a glint), so he can choose what to break. The ladder never shows.

**Broken rocks** stay broken until morning: the game keeps today's broken cells per floor, and empties the
list when the day changes.

**The lift.** Arriving on floor 4 or floor 7 sets a flag for good. The lift in the hall is a conversation
that offers the floors reached.

**The heart piece** is in a pocket in floor 9's north-east corner, walled off by three rocks, and out of
sight in the dark until a light reaches it.

**Light.** Floors 7 to 9 are dark by the crypt's rule: the Lantern lights 56 pixels round the hero (the
Miner's Lantern 80), and without one he sees a cell or so. Crystals glimmer, for show.

**Looks and sound.** Cave floor and wall, the mouth, ladders, the lift, rails and timber are new tiles at
the end of the atlas; rocks and ores are pictures from the sprite tool. One tune, `mine`, slow and hollow,
and six sounds (a pick's strike, a rock breaking, the ladder, the lift, the workbench, the furnace). All
made in code.

## The Pickaxe, energy and the Mining skill

- **The Pickaxe** is an item of type `tool`, 25 coins at Tilda's. It strikes the rock he faces from the
  item button, like the hoe.
- **A blow costs 2 energy** (the hoe's cost; `"mine": 2` in the energy rules).
- **Blows to break a rock:** stone, copper and coal 2; iron, gold and crystal 3. A broken rock gives 1 of
  what it holds; a plain rock gives 1 stone.
- **Mining** is a fourth skill, with the same levels as the others (10, 25, 50, 90 points). A plain rock
  is 1 point, an ore rock 2. Each level above the first takes a tenth off the energy of a blow, as Farming
  does for the hoe, and adds 5% to the chance that an ore rock gives one more (20% at the top).

## Items

Nineteen. Materials are a new type, `material`: they can't be eaten or given as gifts.

| Item | Stack | Tilda pays | From |
|---|---|---|---|
| Stone | 50 | not bought | every plain rock |
| Wood | 30 | not bought | branches (1) and stumps (2) |
| Copper Ore | 30 | 3 | floors 1 to 3 |
| Coal | 30 | not bought | floors 4 to 8 |
| Iron Ore | 30 | 5 | floors 4 to 6 |
| Gold Ore | 30 | 10 | floors 7 to 9 |
| Crystal | 10 | 15 | floors 8 and 9 |
| Copper Bar | 20 | 12 | the furnace |
| Iron Bar | 20 | 20 | the furnace |
| Gold Bar | 20 | 36 | the furnace |
| Pickaxe | 1 | | Tilda, 25 coins |
| Copper and Iron Pickaxe | 1 | | the workbench |
| Copper and Iron Hoe | 1 | | the workbench |
| Copper and Iron Watering Can | 1 | | the workbench |
| Sprinkler | 10 | | the workbench |
| Miner's Lantern | 1 | | the workbench |

## Crafting

**The workbench** stands in the cottage from the start. Its menu lists the recipes he knows, shows what
each needs beside what he has ("Copper Bar 1 of 2"), and greys out what he can't make. It follows the
menu rules: the mouse points, the wheel steps, Tab and Esc leave.

| # | Makes | Needs | Known once |
|---|---|---|---|
| 1 | Furnace (furnishing) | 20 stone, 5 copper ore | copper ore is found |
| 2 | Storage Chest (furnishing) | 10 wood, 1 copper bar | wood is found |
| 3 | Bombs x3 | 1 coal, 3 stone | coal is found |
| 4 | Sprinkler | 1 copper bar, 1 iron bar | Farming 2 |
| 5 | Copper Hoe | the Hoe, 2 copper bars | a copper bar is found |
| 6 | Copper Watering Can | the Watering Can, 2 copper bars | a copper bar is found |
| 7 | Copper Pickaxe | the Pickaxe, 3 copper bars | Mining 2 |
| 8 | Iron Hoe | the Copper Hoe, 2 iron bars | an iron bar is found |
| 9 | Iron Watering Can | the Copper Watering Can, 2 iron bars | an iron bar is found |
| 10 | Iron Pickaxe | the Copper Pickaxe, 3 iron bars | Mining 3 |
| 11 | Miner's Lantern | the Lantern, 1 gold bar, 1 crystal | a crystal is found |
| 12 | Woven Rug (furnishing) | 8 wheat, 3 cherry blossoms | from the start |
| 13 | Standing Lamp (furnishing) | 1 copper bar, 2 wood, 1 coal | a copper bar is found |

Everything on the list, with three sprinklers, comes to 12 copper bars, 10 iron bars and 1 gold bar: 41
copper ore (5 of them for the furnace itself), 30 iron ore, 3 gold ore and 24 coal. That is about three
days in the top floors and four in the middle ones.

**The furnace** smelts overnight. One load a night, of one metal, up to 5 bars; loaded today, the bars are
there from the next morning. Its list is a conversation, built as the hearth's is.

| Makes | Needs |
|---|---|
| Copper Bar | 3 copper ore, 1 coal |
| Iron Bar | 3 iron ore, 1 coal |
| Gold Bar | 3 gold ore, 1 coal |

Coal comes from floor 4 down, so nothing can be smelted before the lift's first stop.

**Tool tiers.** An upgrade takes the old tool and gives the new one. A use costs the same energy at every
tier.

| Tool | Plain | Copper | Iron |
|---|---|---|---|
| Hoe | tills 1 cell | 2 cells in a line | 3 cells in a line |
| Watering Can | waters 1 cell a pour | 2 cells a pour | 3 cells a pour |
| Pickaxe | 2 or 3 blows a rock | one blow fewer | two fewer (every rock in one) |

**The sprinkler** is set on a tilled, empty cell of the plot from the item bar, and taken up again with a
right click. Each morning, after the plot wakes, it waters the four cells beside it (not the corners).
Its own cell can't be planted.

**The chest** holds 24 stacks. Its menu is two lists, the pack and the chest; choosing a line moves that
stack across.

**The cottage,** with the new things in brackets. Nothing that is there now moves.

```
###########
#####h#####     New:  C the chest    L the lamp    F the furnace    W the workbench
#cC*L.Fssb#           RR the woven rug, beside the bed
#B.......W#
#.RRrrr...#     There now:  h hearth   c cupboard   * candle   s shelf   b barrel   B bed
#...rrrkt.#                 rrr the rug   k chair   t table   p plant   o stool   d the door
#.........#
#p.......o#
#####d#####
```

**Wood.** Fallen branches (one blow, 1 wood) and old stumps (three blows, 2 wood) are breakables the sword
cuts: ten branches and five stumps across the North Fields, the Old Wood and the South Field, off the
paths, back each morning. Up to 20 wood a day. They look unlike the stumps that are scenery.

## The economy

**Farming today,** a full plot of 18 cells, once it is turning over:

| Crop | Coins a day | Energy a day | Up front |
|---|---|---|---|
| Turnips | 42 | about 20 | 90 coins of seed |
| Carrots | 45 | about 20 | 144 |
| Potatoes | 50 | about 20 | 180 |
| Pumpkins | 90 | about 20 | 360, and eight days |

**Mining,** with the plain Pickaxe at Mining 1, breaking the ore rocks and about half the plain ones (the
ladder is under one of them):

| A day in | Ore | Coins sold raw | As bars | Energy |
|---|---|---|---|---|
| Floors 1 to 3 | 15 copper | 45 | 60 (5 bars, needs 5 coal) | about 130 |
| Floors 4 to 6 | 9 iron, 12 coal | 45 | 60 (3 bars) | about 160 |
| Floors 7 to 9 | 6 gold, 3 crystal, 4 coal | 105 | 117 (2 bars) | about 115, and 15 a wisp's touch |
| All nine | | 195 | about 210 (the furnace takes one load a night) | about 405 |

- **One band a day is about one plot:** the top floors match turnips and carrots, the middle floors
  potatoes, the deep floors pumpkins.
- **Mining is far hungrier.** A coin from the plot costs about a third of a point of energy; a coin from
  the upper and middle floors about three, from the deep floors about one. A band is more than a bar of
  energy, so a mining day eats: bread at 6 coins for 30 energy, or what the plot grows. The two feed each
  other.
- **Mining pays the same day,** with no seed to buy and no wait. Farming pays more for less work, later.
- **Late in the game mining pulls ahead:** with the Iron Pickaxe and a high skill the whole mine costs
  little more than one bar of energy and pays 200 coins or more, twice a plot of pumpkins. Whether that is
  "clearly dominant" is what phase 3 measures. The lever is the ore prices: a third off levels it.
- **Time is not the limit.** The mine is twenty seconds from home and a floor is about forty seconds: all
  nine fit in a day. Energy, food and hearts are the limits.

## Phase 3

- **Tilda buys** copper, iron and gold ore, the three bars and crystals, at the prices above.
- **Two favours,** at three marks, from two villagers who have none (each teaches a recipe at two):
  - **Wenna, "Black for the Loom":** 5 coal, for dye. 30 coins and 2 Cherry Blossom Tea.
  - **Shepherd Edda, "New Shears":** 2 iron bars. 50 coins and a Shepherd's Pie.
- **Eight days played** by a script that presses real keys in a real window, as Willowmere was, with a
  report of energy spent, coins earned and items crafted each day, and a plain list of what the script set
  up or skipped. Prices and counts are then tuned in data.

## The save

**Version 5.** Three things are new in the file:
- `mine`: the number its rolls come from, the day its broken rocks belong to, and today's broken cells by
  floor.
- `home`: what the furnace holds (the metal, how many, the day it was lit) and the chest's stacks.
- a sprinkler, in a cell of the plot's own section.

Everything else is flags and counts that the file already carries: the lift's two stops, the furnishings
made, the heart piece, what has been found, and Mining's points.

**An older save** (versions 1 to 4) loads through the steps it already takes, then one more: the mine gets
a number of its own, with nothing broken; the furnace and the chest are empty; nothing is furnished; and
what he carries is marked as found. He has no Pickaxe until he buys one. A test loads a version 4 save and
finds exactly that.

## What is reused, and what is new

**Reused as it is:** areas and their exits, the map baker, breakables and their drops, the item bar, tools
on the item button, the energy rules, skills and their levels, slimes, bats, goblin archers and Bogwisps
from their data, the dark and the Lantern's light, heart pieces, the shop's menu, conversations built from
data (the hearth's way), quests and favours, giving what doesn't fit at his feet, the save's safe writing.

**New, pure and unit-tested:**
- the mine's rolls (ore and ladder from the day, never the same cell twice) and its day (what is broken,
  the morning's reset, the lift's stops);
- mining rules (blows by rock and by tier, what a rock gives, the extra ore);
- the furnace (a load, the night, what comes out);
- crafting (what a recipe needs, what is missing, what is known and why);
- tool tiers (the cells a tool works);
- sprinklers on the plot;
- the chest's stacks;
- the shop's `buys` list, and the Mining skill.

**Schemas:** new ones for crafting recipes and the mine's rules; the item, breakable, shop and skills
schemas each gain a field.

## The phases

Each phase ends with every test passing, a commit, and a stop with screenshots and a short summary. Inside
a phase the work is committed in the steps listed. Bugs are planted on purpose in each step's code to see
that the tests catch them.

**Phase 1: mining**
- 1a. The mouth in the North Fields, the hall, cave tiles, the Pickaxe at Tilda's, rocks that stay broken
  until morning, the cost of a blow, save version 5.
- 1b. The nine floors, the day's roll, ladders, the lift, falling, the monsters of each band, the dark
  floors, the heart piece.
- 1c. The Mining skill, the tune and the sounds, playtest scenarios.
- **Done when** a new game can buy the Pickaxe, go down from floor 1 to floor 9 over as many days as it
  takes, ride the lift to 4 and 7, and find rocks and ore back the next morning in other places; a version
  4 save loads; all tests pass.

**Phase 2: crafting**
- 2a. Materials, the workbench and its menu, recipes as data, the furnace, bombs.
- 2b. The chest, the rug, the lamp, wood.
- 2c. Tool tiers, the sprinkler, the Miner's Lantern.
- **Done when** every recipe on the list can be made from what the mine and the fields give, the furnace
  turns ore to bars overnight, the chest keeps its stacks through a save, and a sprinkler waters its four
  cells each morning; all tests pass.

**Phase 3: balance**
- 3a. Tilda buys; the two favours.
- 3b. The eight days played, the report, and the tuning.
- **Done when** the report is in hand, the numbers are settled with the user, and all tests pass.

**The last word is the user's:**
- [ ] *(yours)* a day in the mine feels worth it beside a day on the plot
- [ ] *(yours)* the workbench is easy to read, and what to make next is clear

## Not in this plan

No new villagers, story, or areas beyond the quarry. No axe, no fishing, no placing furniture by hand, no
selling of stone, wood or coal, no second chest, no new monsters. Ask before adding any of them.
