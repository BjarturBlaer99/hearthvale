# Ten days played: the farm

The report of the Homestead's step 5b (`docs/progress/homestead-plan.md`, phase 5). **Nothing in data was
changed:** every number below was measured at the numbers the user approved. The last section says
which I would change, each a question for the user (step 5c is the tuning, on the user's word).

## How it was played

- **A script played ten days of a new game in a real window, at life's own speed,** on 2026-11-19:
  `tools/play_days.gd`, taught the farm for this step. It pressed keys and mouse buttons while the
  game ran as it does for a player: 2325 seconds of play, 39 minutes. It started at the title screen
  and took "New game"; its save was slot 956, emptied before and after.
- **What it was taught:** the walk to the farm and back; the field cleared with the sword and the
  pickaxe (a boulder with the Copper Pickaxe); wood, stone and fibre gathered off the field for the
  next building; the workbench's tabs turned with D ("Make", "Place", "Build"); a kit set down in build
  mode (B, the wheel on the build bar, the ghost moved a cell at a time with the movement keys, Space);
  six fences and a gate laid as a pen before the Coop's door; hens bought at Oda's stall; every animal
  petted and its egg taken with a right click. The choices it makes are in `docs/DECISIONS.md`
  (2026-11-19, step 5b): the Well, the Coop and the Silo in that order, at fixed sites; seed first.
- **It changed the game's state once:** the Lantern was put in its pack on the morning of day 9 (in
  the story it comes from the crypt), as the old script did on day 7.
- **The ten days never reached the Coop** (below). So **the animals were measured by a second run**
  at life's speed, `play_days.gd -- farm`: five days from a new game, with the makings of the Well, the
  Coop and the pen **handed to him (SETUP: 700 coins, 30 wood, 50 stone, 20 fibre, 2 copper bars, a
  sword, the Copper Pickaxe, a hoe and a can)**. Everything after the handing over was played.
- **Another run at life's speed** (the same days, with one fault of the script's last day since
  mended: it sold the bars before making the Well) and **four at four times speed** were trials of the
  script. They are quoted only where it says so, to show how much a run can differ: **the quarry's
  rocks are rolled from the save's own number, which a new game draws at random,** so each run finds
  different ore, and above all different coal.

## The short of it

- **The first building came on day 8, not day 4, and the Coop not at all in ten days.** The purse
  never held more than 165 coins (the other life run: day 8, after the first big harvest). The plan
  guessed the Well on day 4, the Coop and a hen on day 7 or 8, the Silo on day 9.
- **Clearing the field is not the brake the plan thought.** All 54 things on the field went in an
  hour of the game for 30 energy, on day 4 (the plan: about 160 energy to clear and till). A swing
  cuts everything in its arc: he went at 35 of them, and all 54 were gone.
- **Coins are the brake, and seed is where they go.** Of 500 coins spent in the ten days, 365 were
  turnip seed, 80 the Well, 30 bread, 25 the Pickaxe. The field held 5 crops on day 1, 16 on day 4, 33
  on day 8 and 54 on day 10: each harvest is sown again with all it pays, three days a round.
- **The Well waits on coal, not on coins.** Its copper bar needs the furnace, and coal lies from the
  fourth floor down. In the reported run the first copper bars came on day 6 (two of them went to the
  Copper Pickaxe that morning); in the other life run, not until day 10. In a trial at four times
  speed that found coal on day 3, the Well stood on day 4, as the plan guessed.
- **The materials are never short; the pack is.** By day 4 he carried a full stack of fibre (50) and
  26 wood from the field and its edges, and by day 6 wood to the stack's 30; stone filled its stack
  (50) by day 8. **The Coop and the Barn each take a
  full stack of wood (30),** so the pen's six wood is gathered after the Coop's kit is made.
- **Four hens pay what the plan said:** four eggs every morning from the second morning, fed on the
  pen's grass, 32 coins a day at Tilda's (the plan: 8 hens, 64 a day). Bought at 60, a hen pays for
  herself in under eight days. The pen is six fences and a gate (six wood) where the overgrowth closes
  the rest; tending four hens took a minute of play and no energy.
- **Seed first leaves nothing for bread.** He went to bed with fewer than ten coins every day, and the
  Lantern's day (9) ended on floor 5 for want of a loaf.
- **The farm and the quarry still don't compete for the day.** The longest farm day (day 10: harvest,
  24 cells sown, 54 watered) was over at 10:40 with 38 energy left; quarry days ended by 12:50.

## The ten days

| Day | What he did | In bed | Energy spent (clear / farm / mine / other) | Coins at dawn → dusk | Coins in (sold / found) | Coins out (on what) | Wood, stone, fibre, copper bars at dusk | Field clear | Crops in the ground | Buildings | Animals |
|---|---|---|---|---|---|---|---|---|---|---|---|
| 1 | the plot and a first look at the quarry | 11:10 | 91 (0 / 15 / 72 / 4) | 0 → 6 | 0 / 31 | 25 (the Pickaxe) | 0, 7, 0, 0 | 18 of 72 | 5 | none | none |
| 2 | the quarry: the top floors | 12:20 | 152 (0 / 5 / 142 / 6) | 6 → 9 | 10 / 5 | 12 (2 bread) | 0, 3, 0, 0 | 18 of 72 | 5 | none | none |
| 3 | the quarry: the middle floors, and a look at the dark below | 11:40 | 120 (0 / 5 / 109 / 6) | 9 → 1 | 10 / 0 | 18 (3 bread) | 0, 10, 0, 0 | 18 of 72 | 5 | none | none |
| 4 | the farm: harvest, clear the field, sell, sow, the Well | 09:40 | 95 (66 / 29 / 0 / 0) | 1 → 1 | 80 / 0 | 80 (16 seed) | 26, 24, 50, 0 | 72 of 72 | 16 | none | none |
| 5 | the quarry: floors 1 to 6 with a better pickaxe | 11:20 | 91 (0 / 13 / 75 / 4) | 1 → 4 | 0 / 3 | 0 | 26, 31, 50, 0 | 72 of 72 | 16 | none | none |
| 6 | the farm: wood and fibre, the Coop and its pen, the plot | 09:10 | 36 (16 / 20 / 0 / 0) | 4 → 2 | 13 / 0 | 15 (3 seed) | 30, 40, 50, 1 | 72 of 72 | 19 | none | none |
| 7 | hens from Oda, then the quarry: floors 1 to 6 | 12:40 | 92 (0 / 6 / 82 / 4) | 2 → 9 | 0 / 7 | 0 | 30, 50, 50, 1 | 72 of 72 | 19 | none | none |
| 8 | the farm: animals, harvest, clear, sell, build, sow | 11:10 | 44 (0 / 44 / 0 / 0) | 9 → 1 | 222 / 0 | 230 (30 seed, the Well) | 20, 10, 50, 1 | 72 of 72 | 33 | the Well | none |
| 9 | the quarry, late: all nine floors with the Lantern | 12:50 | 92 (0 / 18 / 70 / 4) | 1 → 6 | 0 / 5 | 0 | 20, 33, 50, 1 | 72 of 72 | 33 | the Well | none |
| 10 | the farm, late: animals, harvest, build, sell everything, sow again | 10:40 | 62 (5 / 57 / 0 / 0) | 6 → 3 | 117 / 0 | 120 (24 seed) | 30, 33, 50, 0 | 72 of 72 | 54 | the Well | none |

The table is the reported run. "Energy spent": a bar is 100; "farm" is tilling, sowing, watering and
filling the can; "other" is the sword on the way and walking. "Coins in, found" is Wenna's 30 for her
shuttle on day 1 and what slimes and pots dropped. "Field clear" counts the plot's cells with nothing on
them (the clear corner is 18). Days 1 to 3 are the old script's, as in the mining report.

**What happened on each farm day**
- **Day 4:** five turnips picked; the field cleared (he went at 35 things and all 54 were gone, in 60 minutes
  and 30 energy); 19 more off the field for wood and stone
  until he was down to 34 energy; the turnips and 10 copper ore sold for 80 coins, all of it turnip
  seed (16); 16 sown, 12 watered before he was spent. No Well: no copper bar.
- **Day 6:** the furnace's first copper bars (4): the Copper and the Iron Pickaxe took three. Twelve
  things cleared for the Well's stone. 13 coins, 3 seeds. Still no Well: 80 coins short.
- **Day 8:** 16 turnips (192 coins) and ore; 30 seed (a full stack, 150 coins); **the Well made and set
  down** (80 coins, 40 stone, 10 wood, a copper bar) by the field, where it fills the can; a sprinkler.
  33 crops in the ground. One coin left.
- **Day 10 (the last):** everything sold (the copper bars too: the Well stood); 24 seed; 54 crops in
  the ground, all watered; the Coop's wood and stone gathered. 3 coins: the Coop wants 250.

**The quarry days** (5, 7, 9) were the old script's floors: 10 to 21 copper ore a day, iron and coal
from floor 4. **On day 9, the Lantern's day, he had one coin and no bread:** he was spent on floor 5
at 11:50, a heart from falling, and never saw the dark floors (in the other life run, with bread, the
same day gave 7 gold ore and 3 crystals). He went to bed with fewer than ten coins on every day of
the ten, as in the mining report: the quarry pays in tools, the crops pay in seed, and nothing is
left for bread.

**The animals** (the `farm` run, from a new game with the makings handed over)

| Day | What he did | Coins at dawn → dusk | Hens | Eggs taken |
|---|---|---|---|---|
| 1 | cleared the field (30 energy); made the Well, the Coop, 6 fences and a gate; set them down; gathered 3 wood for the pen | 700 (handed) → 370 | 0 | 0 |
| 2 | the Coop stands: 4 hens bought at Oda's (240), petted | 370 → 130 | 4 | 0 |
| 3 | 4 hens petted, fed on the pen | 130 | 4 | 4 |
| 4 | the same | 130 | 4 | 4 |
| 5 | the same | 130 | 4 | 4 |

- **The pen** (sixteen cells of grass before the Coop's door, closed by the overgrowth and six fences
  and a gate) fed all four hens every morning: none went hungry, and none needed hay.
- **The eggs were not sold in this run** (it only tends): at Tilda's 8 each they are 32 coins a day.

## Beside the plan's guesses

| The plan's guess ("The economy") | Measured |
|---|---|
| The Well on day 4 | **Day 8** (the copper bar came on day 6, the 80 coins on day 8). Day 4 in a fast trial that found coal on day 3; day 10 or later in the other life run |
| The Coop and a first hen on day 7 or 8 (310 coins) | **Not in ten days.** The purse's best was 165 (the other run, day 8) |
| The Silo on day 9 (waits on Farming 2) | Not in ten days. **Farming 2 came on day 4** with the first harvest: the Silo waits on 100 coins and 2 copper bars, not the skill |
| The Shed on day 10 or 11 | Not in ten days |
| 54 cells to clear and till: about 160 energy | **Clearing the 54: 30 energy and an hour** (day 4). Tilling is the hoe's 2 a cell, as before |
| 72 pours a morning, eight trips with the plain can | 54 crops watered on day 10 for 57 energy with tilling 24 cells; the Well beside the field shortens the trips |
| A field of turnips: 168 coins a day | Not reached: the field was three-quarters sown on day 10 (54 of 72), for want of seed coins |
| Wood: 58 once from the farm | 40 gathered by day 10 (about half the logs and stumps), never more than 30 at once |
| 8 hens, 64 coins a day; a hen pays for itself in 8 days | **4 hens, 4 eggs a morning (32 coins a day);** 7.5 days |

## The numbers I would change

Each is a question for the user; none is changed.

1. **The Coop's 250 coins, to about 150** (`data/crafting/coop.json`). *Why:* the purse never passed
   165 in ten days, because every harvest is sown again; at 250 the Coop is a second-week goal, where
   the plan put it at day 7 or 8. At 150 it comes about when the field is first full. *Or keep it,* and
   change the plan's guess: the animals are then the reward of the second week.
2. **The Well without its copper bar** (80 coins, 40 stone, 10 wood). *Why:* the first building should
   follow the first harvest, as the plan meant (day 4); with the bar it waits on finding coal, which is
   down to the quarry's roll (day 3 in one run, day 9 in another). Its unlock (`found: copper_bar`)
   would want changing with it, to `found: stone`.
3. **Wood to stack to 50**, as stone and fibre do (`data/items/items.json`). *Why:* the Coop and the
   Barn each take a full stack of 30, so the pen's wood is a second trip, and wood cut beyond 30 lies on
   the ground. The plan names wood as "the material to gather".
4. **Nothing else.** Not the crop prices: farming does not run away in ten days. Not the clearing,
   though it is far cheaper than the plan thought: the field's brake is the seed and the water, as the
   plan said it should be, and a quick clearing makes the first farm day a good one. Not the hens:
   they pay what the plan said.

## Known limits of the run

- **One run at life's speed is one roll of the quarry.** The other life run found almost no coal
  until day 9; the reported one found it on day 3. The Well's day follows the coal.
- **The script is one way of playing:** seed first, the Well, the Coop and the Silo in that order, the
  old quarry days. A player who sold all his ore every day, or sowed less, would build sooner and farm
  less.
- **Oda's and Tilda's favours (step 5a) were not reached:** they want three marks of friendship, and
  the script talks to Tilda most days (two marks by day 8: she taught her carrot cake) and to Oda only
  at his stall.
- **The animals' run was handed its makings**, so its coins are not a game's.
- **The eggs were not sold, cooked or given** by the script, and no sheep, cow, Silo or hay was tried.

## Settled with the user (step 5c, 2026-11-19)

Asked the three questions above, the user chose: **the Coop costs 150 coins** (was 250), **wood stacks
to 50** (was 30), and **the Well keeps its copper bar**. Crop prices, clearing and the hens stay as they
were. Both changes are in data (`data/crafting/coop.json`, `data/items/items.json`). The ten days have
not been played again with the new numbers. Note that the script spends every coin on seed, so its
"no Coop in ten days" says as much about its own habit as about the price.
