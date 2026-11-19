# Plan: the Homestead

The user's request, 2026-11-17 (`docs/progress/homestead-request.md`): a farm of the hero's own on the road
west of Hearthvale, where he now lives, clears and shapes the land, raises buildings and keeps animals, in
five phases with a stop after each. This is phase 0: the plan, and no code.

**Status: approved as written by the user on 2026-11-17 ("Approve as written"). All thirty decisions
below (D1 to D30) stand as proposed, and each is recorded in `docs/DECISIONS.md`. Phase 1 is built and
approved (2026-11-19); phase 2 is built and approved (2026-11-19); phase 3 is built and approved (2026-11-19);
phase 4 is built and approved (2026-11-19); phase 5 is not built.** Every number is a first guess, kept in data, to be measured in phase 5. The tables below are as
approved; where a phase builds something differently, it says so under "What the user has decided" and
in the log.

## What the user has decided

Each phase reads this section first. It stands in for the `docs/HOMESTEAD-NOTES.md` the request names,
which does not exist. The coordinator adds to it after each review.

- **2026-11-17, phase 0: the plan is approved as written.** D1 to D30 stand as proposed. The two that
  bend a standing rule were approved with the rest: build mode is a screen in which the mouse points
  (D12), and the Shed has fixed places for two more chests and a second furnace (D23). The two existing
  numbers the plan changes have the user's word: the plot is 12 by 6, and Farming gains a point for a
  product taken (D30).
- **The open questions, as the approval leaves them:**
  1. This plan's decisions, with `docs/DECISIONS.md`, take the place of `docs/HOMESTEAD-NOTES.md`.
  2. `docs/HOMESTEAD.md` (an untracked copy of the request) was not spoken of: it is left as it is.
  3. The clock stops in build mode (D12, as written).
  4. No hay for sale (as written: it is under "Not in this plan").
  5. The welcome sign in the square is left alone (as written).
- **The stops are after each phase,** as the user's instructions say. The plan's suggestion of a look
  after step 3a was put to the user with phase 2's summary and not answered; phase 3 stops at its end,
  by the user's own rule, and commits after each step so it can be stopped between them.
- **CLAUDE.md:** the paragraph R1 was added under "Current goal" on approval. R2 to R19 are added by the
  coordinator as each phase is built and reviewed, in the words below unless the phase built otherwise.
  **R2 to R8, R18 and R19 went in on 2026-11-19, after phase 1's approval, in the words of what was
  built** (baked cells and real names; the phase's report gave them and the coordinator checked the
  names against the code). R10 to R14 went in the same way after phase 2's approval (R10 without
  its `build` tab, which is phase 3's). R9 and R15 to R17 wait for phases 3 to 5.
- **2026-11-19, phase 1 is built** (steps 1a and 1b on 2026-11-18, step 1c finished on 2026-11-19;
  each is ticked below with what was built differently) **and the user approved it on 2026-11-19** ("Approve Phase 1", shown the summary and the pictures; nobody has played it by hand). *(Written
  by the phase's subagent; the coordinator ran the full suite again, 977 tests in 130 suites, and
  confirmed the commits and the pictures. The phase was stopped by the user twice and picked up again
  each time.)* Every approved decision it touches
  (D1 to D11, D30) held as written. What the plan left open and the phase chose is in `docs/DECISIONS.md` under the three
  steps; the ones a later phase will meet:
  - the land's cells cleared for good are `GameState.homestead()`, through `clear_debris(area, cell)`;
  - "Clear this first." (`ToolUse.CLEAR_FIRST`) is what every tool of the plot says at a cell with
    something on it, and `AreaController.debris_at(cell)` is how the area asks;
  - spawn markers for the land are a second row at the end of the atlas (`LAND_MARKER_KINDS`);
  - an area may name its own night tune (`night_music`).
- **2026-11-19, phase 2 is built** (steps 2a and 2b, each ticked below with what was built
  differently) **and the user approved it on 2026-11-19** ("Approve Phase 2", shown the summary and the
  pictures; nobody has played it by hand). *(Written by the phase's subagent; the coordinator ran the
  full suite again, 1038 tests in 134 suites, and confirmed the commits and the pictures. The
  approval was of the phase as built, so the hand's reading of D16 below stands: the user did not
  speak to it apart.)* Every approved decision it touches (D12 to D19, D30) held as written.
  One reading wants the user's word: **D16 says moving "is taking up and setting down in one go";
  the hand as built moves a thing as it is,** so a moved sapling keeps its mornings, a moved tree
  stays a tree, and a full pack is no hindrance. Taking a tree up (a right click) gives back its
  sapling, as D16 says. What else the plan left open is in `docs/DECISIONS.md` under the two steps;
  what a later phase will meet:
  - a placeable is an item of type `placeable`, set down through `GameState.set_down()`, moved
    through `move_placed()` and taken up through `take_up()`; `Placement.why_not(item, site)` says
    whether it fits, and `BuildMode.site_at(cell)` describes a cell (a building's cells will ask the
    same, and add their own doorsteps);
  - what stands is `GameState.homestead().standing_at(cell)`, and `Placement.blocks()` and `joins()`
    say what an animal or a pasture needs to know of it (a gate doesn't block the hero and still
    joins a fence);
  - a crafting recipe has a `tab` (`make` or `place`): "Build" is one more name in `Crafting.TABS`;
  - `SpriteSheet.draw()` draws a mirrored frame a frame's width to the right in this engine: found,
    measured, and left alone (it is older than the Homestead).
- *(Written by phase 3's subagent, for the coordinator to confirm with the user.)* **2026-11-19, phase 3
  is built** (steps 3a, 3b and 3c, each ticked below with what was built differently). Every approved
  decision it touches (D20 to D24, D29's hay, D30) held as written. What the plan left open and the phase
  chose is in `docs/DECISIONS.md` under the three steps. Two readings want the user's word:
  - **the tall grass and a phase 2 save** (the brief's open point): a tuft doesn't grow where something
    is set down or a building stands; taken up, it is back on the next visit;
  - **nothing takes hay out of the silo,** so a silo with hay can't be pulled down until phase 4's
    animals eat it.
  What a later phase will meet: a building is a file in `data/buildings/` (its `animals`, and `big`'s,
  are phase 4's to read); `GameState.is_built(id)`, `is_big(id)`, `homestead().hay`; a building with a
  room has a door and the homestead's entry `<id>_door`; `GameState.why_not_demolish()` is where "no
  animals" goes.
- **2026-11-19, the user approved phase 3** ("Approve, fix looks first", shown the summary and seven
  pictures in a cloud session; nobody has played it by hand). First, three looks changed at the user's
  word: the Coop wears wooden shingles, the Big Barn green boards, and the shed's bookshelves became a
  tool rack and sacks (commit `3d99550`). Of the two readings: **a silo with hay stays one that can't be
  pulled down** ("Keep as built"); the tall grass reading was approved with the phase as built. R4, R7's
  hay, R8's shed, R9 and R10's `build` tab are in CLAUDE.md, with a block of phase 3's rules. R15 to R17
  wait for phases 4 and 5.

- **2026-11-19, phase 4 approved:** shown the summary and the pictures, the user answered "Approve, fix
  looks first". They kept a pasture as built (anything standing closes one, a bench or a sapling as a
  fence does, and the meadow's tall grass is grass), and asked for smaller badges over the animals: done
  the same day, a small bubble with the thing at half size that points down at its animal. The coop's
  shelves, Oda's borrowed stall, the animals' random start and the hearth's singular names stay as they
  are (the user did not choose to change them). R5's sentence, R13's animals, R15, R16 and R18's
  `animals` are in CLAUDE.md, with a block of phase 4's rules. R17 waits for phase 5.
- *(Written by phase 4's subagent, for the coordinator to confirm with the user.)* **2026-11-19, phase 4
  is built** (steps 4a, 4b and 4c, each ticked below with what was built differently). Every approved
  decision it touches (D25 to D28, D29's stall, D30's point for a product) held as written, with the
  table's prices, products, paces and grass. What the plan left open and the phase chose is in
  `docs/DECISIONS.md` under the three steps; the readings worth the user's eye:
  - **a pasture is the ground the doorstep reaches through what can be crossed,** and anything
    standing closes it (a bench or a sapling as well as a fence, a gate or a hedge); the meadow's tall
    grass is grazed like any grass;
  - **the herd is fed in the order it was bought,** and two buildings whose doors open on one fenced
    ground share its grass;
  - **"unhappy" is a day's hunger,** shown over its head, and nothing more;
  - **the Wool Blanket is a farmhouse furnishing that lies over the bed,** and cloth and the blanket
    are on the "Make" tab once their makings are found;
  - **Oda's stall is the village's market stall again,** at (16..18, 30..31) beside her.
  What phase 5 will meet: an animal is `GameState.homestead().animal(index)`, bought through
  `GameState.buy()` of Oda's ware or `buy_animal()`, petted through `pet_animal()`; `has_pasture(id)`
  and `pastures()`; the products are the items `egg`, `wool`, `milk` and `cloth`.

## The short of it

- **The lane through Hearthvale runs on west,** through two cells of the tree line, onto a new map: an old
  farmstead, 40 by 30 cells, overgrown.
- **The hero's home is the farmhouse there.** It is the same room as today, with the bed, the hearth, the
  workbench and everything made for it in the same places: only its door opens onto the farm. He sleeps,
  wakes and comes round there. The cottage in the village stands empty and locked.
- **The field is four times the old plot:** 12 by 6 cells below the farmhouse. Its corner by the house is
  clear; the rest of it, and the land around, is under weeds, bushes, logs, stumps, rocks and boulders that
  the sword and the pickaxe clear for good.
- **Phase 2: build mode.** A key opens it, the mouse points at a cell, and paths, floors, fences, gates,
  hedges, lamp posts, benches, flower beds and saplings are set down, moved and taken up.
- **Phase 3: five buildings,** bought as plans at the workbench and standing the next morning: a Well, a
  Silo, a Coop, a Barn and a Shed, with a bigger Coop and Barn to follow.
- **Phase 4: chickens, sheep and cows** from Farmer Oda: fed by pasture or hay, petted, and giving eggs,
  wool and milk that are cooked, sold and woven.
- **Phase 5: two favours, ten days played by the script, and the numbers settled.**
- **An old save loads with nothing lost:** the home, the furnishings, the chest, the furnace, the soil and
  the crops are all where the farmhouse and the field now are.
- **It is the largest addition yet,** and it breaks or bends about a dozen of the project's standing rules.
  They are listed under "Where the request meets the rules", with the words CLAUDE.md would carry instead.

## Thirty things to decide

Each is a concrete proposal, the simplest I found that fits the game as it is. Approving the plan approves
these; any one can be changed by its number. **All thirty were approved as written on 2026-11-17.** The two marked **(rule)** are where the choice itself decides
how a standing rule bends; every rule the request touches is under "Where the request meets the rules".

**Where it is, and how big**

| # | The plan proposes | Why | Otherwise |
|---|---|---|---|
| D1 | **The way there is the lane's west end.** Two cells of Hearthvale's west tree line open (rows 16 and 17) and the lane runs three cells further to the edge. The homestead's east edge is the other side. | The lane already ends three cells short of those trees: it is the road west. One re-bake of the village, as the marsh walk had; nothing else in it moves. | |
| D2 | **The map is 40 by 30 cells,** the size of the North Fields and Willowmere. | It holds everything asked with room over, and it is exactly one screen wide, so build mode sees the whole width. | 48 by 36, the village's size: more to clear, and wider than the screen. |
| D3 | **"About 4x the old plot" is the field:** 12 by 6, 72 cells of soil in one bed (the old plot is 6 by 3, 18). The old plot is its north-west corner. | The plot is a rectangle of its own cells in the code. A bigger rectangle needs no new farming rules and leaves a saved plot as it is. | Tilling anywhere on the land: soil would meet paths, buildings and pasture, and it is a good deal more to build. |
| D4 | **Overgrown, but not on day 1's patch.** The field's 18 cells nearest the house are clear. The other 54, and about 90 places round the land, carry something: 145 in all. What is cleared is gone for good. | A new game must be able to plant on the first morning (the main quest asks it). The farm then opens up over days. | |
| D5 | **The sword and the pickaxe clear it.** Weeds, bushes, logs and stumps fall to the sword; rocks to the Pickaxe; eight boulders want the Copper Pickaxe and three great boulders the Iron. Nothing on the field needs a better tool. | "Existing tools." The pickaxe is the tool whose better kinds come early; the Iron Sword is the last dungeon's. | |
| D6 | **A small pond in the south-west corner,** and no well until one is built. | The very first can should not need a walk to the village. The Well then saves about 6 seconds a refill. | No water on the farm at all: the village well is 7 seconds from the farmhouse, each way. |
| D7 | **No monsters, villagers or forage on the homestead.** | None is asked for. | |

**The home's move, and the story**

| # | The plan proposes | Why | Otherwise |
|---|---|---|---|
| D8 | **The home keeps its room.** The area `home` becomes the inside of the farmhouse, cell for cell. Only its doormat changes: it leads onto the homestead. | Sleeping, 02:00 and a collapse all send him to `home` already. A save made inside the cottage opens inside the farmhouse with nothing to move, and no furnishing's place is decided again. | A new, larger room: every place in it chosen again, and every crafting test moved. |
| D9 | **The old cottage is empty and locked.** Its door stays, and trying it says "The cottage stands empty, and its door is locked." | One line of data (a place that is never open), no scene removed. | Under "The home's move" below: Farmer Oda's house, or the house taken away. |
| D10 | **A new game still begins in Hearthvale's square.** The quest's first line sends him west: 8 seconds' walk. | "Arrives in Hearthvale." | Begin at the farm's gate. |
| D11 | **The farm was Sir Aldric's.** Bram's tale already says Aldric farmed in this valley and left his place "for whoever would look after the valley"; it says farm now where it said cottage. Seven lines of the quests and of Bram change, and the title's. | The inheritance is the story's own, with one word changed. Nobody new is named. | |

**Placing things (phase 2)**

| # | The plan proposes | Why | Otherwise |
|---|---|---|---|
| D12 | **(rule) Build mode is a screen, like a menu.** B opens it, on the homestead only. The hero stands still and the clock with him. The mouse points at a cell; the ghost is green or red; a left click sets down, a right click takes up; the wheel and 1 to 9 choose; Tab, Esc or B leave. | In menus the mouse already points. Play itself keeps the rule of 2026-11-13: no pointer. | No mode: placeables on the item bar, set on the cell he faces, as the sprinkler is. It keeps the mouse rule and breaks the bar's, and a fence can't be laid sideways. |
| D13 | **What is on screen can be built on.** To build further off, leave, walk and open it again. | No free camera to build. The map is one screen wide. | |
| D14 | **Two things to a cell at most:** one lying (a path, a floor, a flower bed) and one standing (a fence, a gate, a hedge, a lamp post, a bench, a sapling, a building). | A lamp post on a paved yard. | |
| D15 | **Never on:** trees, water or the house; the road and the path to the door; the way out; a doorstep; the field; debris or tall grass; the cell the hero or an animal is in. | The request's three (house, exits, paths to them), and what would trap or bury something. | |
| D16 | **Taking up gives the item back,** if he has room; a grown tree gives back its sapling. Moving is taking up and setting down in one go. | "A full pack loses nothing." | |
| D17 | **Fifteen placeables** (the table below): nine made at the workbench, six bought from Tilda. Tilda also sells fibre. | Built things from the bench, living things from the shop. Fibre for sale so it can never run out. | |
| D18 | **A gate lets the hero through and keeps animals in.** No opening and shutting. | One rule, nothing to forget. | |
| D19 | **The sprinkler stays as it is:** on the item bar, set on the field. | It was approved that way. | |

**Buildings (phase 3)**

| # | The plan proposes | Why | Otherwise |
|---|---|---|---|
| D20 | **One of each building.** | One room to draw for each, and the costs stay a ladder. | Several coops and barns. |
| D21 | **A plan is bought at the workbench and set down outside.** A third tab, "Build", lists the plans with their materials and coins. Bought, it is a kit in the pack; in build mode it is set down as a building site, and the building stands the next morning. | The workbench is indoors and the land is outdoors. | |
| D22 | **The costs and sizes in the table below;** an upgrade keeps the building where it is and the size it was. | | |
| D23 | **(rule) The Shed is a room with fixed places** for two more chests and a second furnace, each made at the workbench. | It keeps "a furnishing has its own place", and a second furnace eases the one narrow place the balance report found. | Chests and stations set down by hand indoors: a second build mode. |
| D24 | **Moving is free and at once. Demolishing gives half the materials back, no coins,** and only an empty building can go. | "Refunds part of the materials." | |

**Animals (phase 4)**

| # | The plan proposes | Why | Otherwise |
|---|---|---|---|
| D25 | **Pasture first, then hay, then hungry.** An animal is fed each morning by fenced grass beside its building (4, 6 or 8 cells an animal), else by one hay from the silo. | Both ways asked for; land or work is the choice. | |
| D26 | **One right click pets an animal and takes what it has ready.** No shears, no pail. | No new tools, nothing more on the item bar. | |
| D27 | **Fed and petted, it gives at full pace; fed only, at half; unfed, nothing that morning.** Nothing dies or runs off. A hen lays each morning, a cow milks every second, a sheep is shorn every third. | "Unhappy ones produce less", and readable. | A mood that builds over days. |
| D28 | **Animals are in from 20:00 to 06:00 and simply are where they belong,** as villagers are. They wander, block nobody, and never use a door. | "No complex pathfinding", and it is how the village already keeps hours. | |
| D29 | **Hay is tall grass from a meadow on the farm,** back each morning, carried to the silo. Farmer Oda sells animals from her conversation; an animal bought is in its building. What each costs and gives is in the table below. | | |

**The save, and two numbers**

| # | The plan proposes | Why | Otherwise |
|---|---|---|---|
| D30 | **Save version 6, once, for all five phases.** Phase 1 brings it; later phases add fields read with defaults. The plot's size (6 by 3 to 12 by 6) and Farming's points (a point for a product taken) are the two existing numbers this plan changes. | P4 did the same with version 4. | A version a phase. |

**Worth knowing**

- **The size of it.** Four new areas (the homestead and three rooms), a new mode, 29 items, 21 crafting
  recipes, three new kinds of data file (buildings, animals, the homestead's rules), two tunes and six
  sounds. Phases 3 and 4 are each about as large as all of crafting was.
- **The request's phases each say "read `docs/HOMESTEAD-NOTES.md`", and there is no such file.** I propose
  that this plan's decision list takes its place: the coordinator records each approved decision here and
  in `docs/DECISIONS.md`, and each phase reads those.
- **Farming could pay four times what it does.** A full field of turnips is 168 coins a day where the old
  plot paid 42. Water, seed money and clearing hold it back for a week or two. See "The economy".
- **Fibre is a new material** (weeds and bushes give it). The buildings' thatch takes 65 of the 102 the
  land gives, which is why Tilda sells it too.

## Where it is, and the walk

**The village side.** The lane ("path") runs along rows 16 and 17 from column 3; the west woods are columns
0 and 1 (`tools/greybox/build_maps.gd`). Cells (0..1, 16..17) become open ground and the lane is laid over
(0..2, 16..17). A way out two cells tall stands on the edge, as `MarshWalk` does in the east.

**The map.** 40 by 30. This is a first drawing: the counts are what is proposed, and a cell may shift when
it is baked, as Willowmere's hut did.

```
     0         1         2         3
     0123456789012345678901234567890123456789
  0  TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
  1  TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
  2  TT.........ww...........s.............TT
  3  TT..".".."."."...................o.t..TT
  4  TT.o.".l".".".b.t.............o...t.twTT
  5  TT..".."."."."..s.............o.......TT
  6  TT...............oww.......l......l...TT
  7  TT............O.w..............w..ww..TT
  8  TTs..w....w........w......HHHHHH..to.lTT
  9  TT.t.O..oOs..........w.t..HHHHHH....w.TT
 10  TT.....b....O...O......wsbHHHHHH......TT
 11  TTw.............o.b....o..HHDHHH......TT
 12  TT........w...l..o.s........=.........TT
 13  TT.O.....w.....w............=.........TT
 14  TTs....O..w.l.......==================>>
 15  TT...............w..==================>>
 16  TT....................................TT
 17  TT.....b......o....b..FFFFFFwwwwww....TT
 18  TT.t..................FFFFFFwwwsww....TT
 19  TT.ow.......o.O.b.....FFFFFFwbwbww..o.TT
 20  TTb..w....wl....o...s.wowwblowwbww....TT
 21  TT..~~~~~~w@.@........wwwwwlwwooww....TT
 22  TT..~~~~~~.....b...l..wsbwwwwwwwwo....TT
 23  TT..~~~~~~...o......................b.TT
 24  TT..~~~~~~....s........b............t.TT
 25  TT....@.s......o....o..............t..TT
 26  TT....s.....t..........sw...........w.TT
 27  TT.......w.w..w.................o.....TT
 28  TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
 29  TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
```

| Letter | What |
|---|---|
| `T` | the woods round the edge (solid) |
| `>` | the way out to Hearthvale (columns 38 and 39, rows 14 and 15) |
| `=` | the road in, and the path up to the door: never built on |
| `H`, `D` | the farmhouse (6 by 4, thatched, the village's own house tiles) and its door at (28, 11) |
| `F` | the field's clear corner: 18 cells (22..27, 17..19). The whole field is (22..33, 17..22) |
| `~` | the pond (4..9, 21..24): the can fills here |
| `"` | the meadow's tall grass, 14 tufts, back each morning (hay, from phase 3) |
| `t` | old trees left standing (solid, tall pictures the hero walks behind) |
| `w`, `b` | weeds, a bush |
| `l`, `s` | a fallen log, an old stump |
| `o` | a rock |
| `O` | a boulder: the Copper Pickaxe or better |
| `@` | a great boulder: the Iron Pickaxe |
| `.` | grass |

- **Room for what is to come:** the open land west of the house (columns 3 to 19, rows 8 to 19) takes a
  barn, a coop and their pasture; the boulders stand in the best of it. The south-east and the north are
  free for a shed, a silo and whatever the player likes.
- **The ground itself is never changed:** no cliffs, no heights, as the request rules.

**How I read "large (propose about 4x the old plot)".** A map four times the old plot would be 72 cells,
smaller than the farmhouse's yard, so the four times must be the soil: the field is 72 cells where the
plot was 18 (D3). "Large" I take as the map, and propose 1200 cells, 936 of them inside the woods: the
field, the house, the road, the pond and every building asked for take about 220.

**The walk.** The hero walks at 72 pixels a second and sprints at 120
(`core/player/player_motor.gd`: `WALK_SPEED`, `SPRINT_SPEED`): 4.5 and 7.5 cells a second. Tired (under 25
energy) he walks at 85%. Cells are counted along the shortest way. **The sum for the walk asked about:**
from the edge he came in by, 9 cells west along the road and 3 north to the door are 12 cells, 192
pixels, and 192 / 72 = 2.7 seconds.

| From, to | Cells | Walking | Sprinting | Tired |
|---|---|---|---|---|
| **The village's edge to the farmhouse door** | 12 | **2.7 s** | 1.6 s | 3.1 s |
| The village's edge to the far corner of the land | 48 | 10.7 s | 6.4 s | 12.5 s |
| Hearthvale's square (a new game) to the farmhouse door | 38 | 8.4 s | 5.1 s | 9.9 s |
| The farmhouse door to Tilda's door | 28 | 6.2 s | 3.7 s | 7.3 s |
| The farmhouse door to the village well | 31 | 6.9 s | 4.1 s | 8.1 s |
| The field to the pond and back | 30 | 6.7 s | 4.0 s | 7.8 s |

- **Every walk on the farm is under the 20 seconds asked,** the longest by half.
- **What it costs against today:** the cottage door was 2 seconds from Tilda's and from the plot. Tilda is
  now 6 seconds from the door, and the quarry about 4 seconds further than it was (about 24).
- **A day is 14 minutes:** 20 seconds are half an hour on the game's clock, and the walk to the square 12
  minutes of it.

## The home's move

- **The farmhouse's inside is the area `home`,** the same scene: bed at (1, 3), hearth, workbench at (9, 3),
  the places for the furnace, the chest, the lamp and the rug. It is named "Your farmhouse". Its doormat
  leads to the homestead, in front of the farmhouse door.
- **He wakes there:** after sleeping, at 02:00, and after a collapse. All three already go to `home` by his
  bed (`WorldPaths.HOME_AREA`, `HOME_BED`; `AreaController._wake_at_home()`). No rule of energy or sleep
  changes.
- **The plot's node leaves the village** and lies on the homestead. Where it lay (12..17, 18..20) is grass
  again; the village's own well and pond still fill a can.
- **The tools and the first seeds** lie inside the farmhouse door, where they lay inside the cottage's.
- **Hours:** nothing changes for the home. The old cottage's door is "shut" at every hour.

**The old cottage.** Three ways, and the one I would take:

| | What | For | Against |
|---|---|---|---|
| **Locked (proposed)** | The house stands, its door says it is locked. | Nothing removed; one line of data; old saves and new games both make sense of it. | A dead door in a small village. |
| Farmer Oda's | The same locked door, but the words are hers ("Oda's door. She is out with her hens."). | The house has an owner, and Oda has no house. | She stands by her field, some twenty cells away; "at Farmer Oda's" then means two places. |
| Taken away | The house is baked out and the lane's end is trees and grass. | Nothing dead. | A second change to the village's layout, and the tests of the cottage's doorway (`home_test`, `doors_test`) go with it. |

## The story's words

The game has no opening scene: a new game starts in the square with the notice of the main quest, and the
quest's journal is the guide. So "the opening" is the title's line, the quest's first three lines, and
Bram's welcome. Stages, objectives, flags and conditions are untouched.

| File | Now | Proposed |
|---|---|---|
| `ui/title_screen.tscn`, the line under the name | "A cottage, a plot of soil, and lights over the old keep." | "An old farm, a field gone wild, and lights over the old keep." |
| `data/quests/a_place_of_your_own.json`, `settle` | "Your cottage is the thatched house at the west end of the lane in Hearthvale. Take what lies inside its door." | "The old farmstead is yours now. Follow the lane west out of Hearthvale, past the last cottage, to its farmhouse. Take what lies inside the door." |
| the same, `plant` | "Your plot is across the lane, by the well. Choose the hoe..." | "Your field lies below the farmhouse, across the road: one corner of it is clear. Choose the hoe..." (the rest as it is) |
| the same, `bram` | "...Water it each morning: the can fills at the well. Elder Bram, in the blue-roofed house, wants a word." | "...Water it each morning: the can fills at the pond in the corner of your land. Elder Bram, in the blue-roofed house in Hearthvale, wants a word." |
| the same, `done` | "...and the cottage is yours." | "...and the farm is yours." |
| `data/dialogue/elder_bram.json`, `welcome` | "So you are the one who has taken the old cottage. Welcome to Hearthvale. It is the thatched house at the west end of the lane, and the plot by the well is yours." | "So you are the one the old farmstead was left to. Welcome to Hearthvale. It lies out the west lane, past the last cottage: run down and overgrown, but the house stands and the soil is good." |
| the same, `favour_tale` | "They say the cottage you sleep in was his..." | "They say the farm you keep was his..." (the rest as it is) |
| `data/quests/elders_supper.json`, `done` | "...and that your cottage was his." | "...and that your farm was his." |
| `data/rules/hours.json` | | a place `old_cottage` that is never open: "The cottage stands empty, and its door is locked." |

**Left as they are,** though they touch the subject:
- Bram's `settle` ("Take the tools by your door, till a patch and put a seed in it...") is still true.
- The quest's `rest` ("Go home and sleep.") and its title.
- Farmer Oda's "that plot of yours", and the tools' words ("The hoe is for the soil of your plot.", "Fill
  it at the well or the pond."): a field is still a plot, and tests carry those words.
- The welcome sign in the square (north and south only; it did not gain the marsh either).
- Every other conversation, quest, inscription and item: none mentions the cottage or the plot (searched
  in `data/`, `ui/`, `core/` and `gameplay/`).

**To be brought up to date as documents, not story:** `README.md` (its lines about the cottage and the
plot), `docs/GDD.md` (§4, §7, §11, §13) and a comment in `tools/playtest.gd`.

## Clearing the land (phase 1)

| What | Cleared by | Blows | Leaves | On the land |
|---|---|---|---|---|
| Weeds | the sword | 1 | 1 fibre | 70 |
| A bush | the sword | 2 | 2 fibre | 16 |
| A fallen log | the sword | 3 | 3 wood | 10 |
| An old stump | the sword | 3 | 2 wood | 14 |
| A rock | the Pickaxe | 2 | 1 stone | 24 |
| A boulder | the Copper Pickaxe (3 blows) or the Iron (2) | | 4 stone | 8 |
| A great boulder | the Iron Pickaxe (3 blows) | | 8 stone | 3 |

- **In all:** 145 things, giving 102 fibre, 58 wood and 80 stone, for about 250 energy: two and a half
  bars, over the first week or two.
- **On the field:** 54 of them (40 weeds, 5 bushes, 5 rocks, 2 stumps, 2 logs): 51 energy to clear, and
  108 more to till.
- **What it leaves lies in its cell,** as ore and wood do, and stays lying if the pack is full.
- **Cleared is cleared:** no morning brings it back. This is new: a branch in the countryside is back
  the next day, and a rock in the quarry too.
- **A cell with something on it can't be tilled:** "Clear this first."
- **The plain pickaxe at a boulder** is told: "It wants a better pickaxe." No energy is spent.
- **Bombs** cut what the sword cuts, as they cut branches, and never a rock.

## Placing things (phase 2)

**What can be set down**

| Thing | Lies or stands | From | Cost |
|---|---|---|---|
| Dirt Path | lies | the workbench | 1 stone makes 4 |
| Stone Path | lies | the workbench | 2 stone make 4 |
| Wood Path | lies | the workbench | 1 wood makes 4 |
| Wooden Flooring | lies | the workbench | 2 wood make 4 |
| Stone Flooring | lies | the workbench | 3 stone make 4 |
| Fence | stands, blocks | the workbench | 1 wood makes 2 |
| Gate | stands; the hero walks through | the workbench | 3 wood |
| Lamp Post | stands, blocks; lit from dusk to dawn | the workbench | 1 iron bar, 1 coal, 2 wood |
| Bench | stands, blocks | the workbench | 4 wood |
| Hedge | stands, blocks | Tilda | 5 coins |
| Flower Bed: red, yellow, blue | lies | Tilda | 3 coins each |
| Oak Sapling | stands, blocks; a tree after 4 mornings | Tilda | 10 coins |
| Cherry Sapling | stands, blocks; a cherry tree after 6 mornings | Tilda | 30 coins |
| *(Fibre, five at a time)* | | Tilda | 6 coins |

- **Each takes one cell.**
- **The workbench gets tabs,** as Tilda's counter has: "Make" (today's list), "Place" (these nine) and, in
  phase 3, "Build". Thirteen lines are already more than its six rows.
- **A path and a floor differ only in looks.** Grass with something lying on it is no longer grass to a
  grazing animal.
- **A sapling needs no water.** It shows three pictures as it grows, and the grown tree is a tall picture
  the hero walks behind, like every tree.

**Build mode**

- **B opens it** (a pad: the left stick's click), only on the homestead and only when he is free to act.
  Anywhere else: "You can only build on your own land."
- **The build bar** takes the item bar's place: first a hand (move and take up), then each placeable he
  carries with how many. The wheel steps along it and the keys 1 to 9 choose.
- **The ghost** lies on the cell under the mouse, snapped to the grid; the movement keys move it a cell at
  a time. Green where the thing fits; red where it doesn't, with the reason in a line of words.
- **Left click** sets it down and takes one from the pack. **Right click** takes up what is under the
  ghost. With the hand chosen, a left click lifts a thing and the next sets it down elsewhere.
- **Tab, Esc or B** leave.
- **The hero stands still and the clock stops,** as at the workbench. Setting a thing down costs no energy.

**The rules**

| A thing is refused | It says |
|---|---|
| anywhere but the homestead | "You can only build on your own land." |
| on trees, water, the house, or the edge of the map | "Nothing can stand there." |
| on the road, the path to the door, or the way out | "That is the road." |
| on the cell before a door (the house's, a building's) | "That is a doorstep." |
| on the field | "That is your field." |
| where debris or tall grass stands | "Clear this first." |
| where a thing of its kind already lies or stands | "Something is there already." |
| a standing thing, on the cell the hero or an animal is in | "Someone is standing there." |
| a building, if any cell under it or its doorstep fails the above | the first reason found |

- **Collisions:** a standing thing fills its cell the moment it is set down and frees it the moment it is
  taken up (`TerrainQuery.set_occupied`, as a villager or a furnishing does). A lying thing never blocks.
- **Sorting:** standing things are drawn with the hero and everyone else, by their feet; lying things are
  drawn flat under everyone, as the field's soil is; a grown tree is one of `Scenery`'s, and its crown
  fades when he is behind it.
- **Taking up** puts the item back in the pack, or is refused if there is no room. A building is never
  taken up: it is moved or demolished.
- **Kept:** all of it is in `GameState` and in the save.
- **Nothing existing changes:** no hit box, no collision and no timing of anything already in the game.

## Buildings (phase 3)

| Building | Cells | Has a room | Materials | Coins | Known once | What it does |
|---|---|---|---|---|---|---|
| Well | 2 by 2 | | 40 stone, 10 wood, 1 copper bar | 80 | a copper bar is found | the can fills at it |
| Silo | 2 by 2 | | 30 stone, 10 wood, 2 copper bars | 100 | Farming 2 | holds 60 hay |
| Coop | 4 by 3 | yes | 30 wood, 20 stone, 15 fibre | 250 | wood is found | 4 chickens |
| Big Coop | the same | | 20 wood, 10 fibre, 2 iron bars | 350 | a Coop stands | 8 chickens |
| Barn | 6 by 4 | yes | 30 wood, 40 stone, 25 fibre, 4 iron bars | 600 | Farming 3 | 4 sheep and cows |
| Big Barn | the same | | 30 wood, 30 stone, 2 gold bars | 800 | a Barn stands | 8 sheep and cows |
| Shed | 4 by 3 | yes | 30 wood, 20 stone, 15 fibre, 2 copper bars | 200 | a copper bar is found | room for two chests and a furnace |

- **All seven:** 160 wood, 180 stone, 65 fibre, 5 copper bars, 6 iron bars, 2 gold bars and 2380 coins.
  No one plan needs more of a thing than a stack holds (wood 30, stone 50).
- **Buying a plan** takes the materials and the coins and gives a kit. A kit can't be put in a chest.
- **Setting it down** makes a building site that fills its cells. **The next morning** the building stands.
- **A doorstep,** the cell below the door, must be free and stays free.
- **The rooms** are three small areas, each 11 by 9 like every house's inside, each with a doormat that
  leads out before its building's door wherever the building stands.
- **The Shed's furnishings** are made at the workbench once the shed stands, each for what its like costs
  in the farmhouse: two chests (10 wood and a copper bar each) and a furnace (20 stone, 5 copper ore).
  Each furnace still takes one load a night.
- **An upgrade** is bought like a plan, needs the building standing, and is done the next morning.
- **Moving:** in build mode, with the hand: lift it, set it down. Its animals and whatever its room holds
  go with it.
- **Demolishing:** a right click on it in build mode asks first. Only an empty building can go (no
  animals, nothing in its chests or furnace, no hay). Half of each material that went into it comes back,
  rounded down, and what the pack can't take is laid at his feet. No coins come back.

## Animals (phase 4)

| Animal | Lives in | At Oda's | Gives | When fed and petted | Tilda pays | Grass to graze |
|---|---|---|---|---|---|---|
| Chicken | the Coop | 60 coins | an egg | every morning | 8 | 4 cells |
| Sheep | the Barn | 180 coins | wool | every third morning | 40 | 6 cells |
| Cow | the Barn | 240 coins | milk | every second morning | 30 | 8 cells |

- **Each morning,** for each animal in turn:

| It was | This morning |
|---|---|
| fed, and petted yesterday | a full day nearer its next egg, fleece or pail |
| fed, not petted | half a day nearer |
| not fed | no nearer, and it looks unhappy until it is fed |

- **Fed means:** its building has a pasture with grass enough for it, or the silo has a hay to give.
  Pasture is used first.
- **A pasture** is the grass an animal can reach from its building's door without crossing a fence, a
  gate, a hedge or anything that blocks. If that ground runs on to the road or the edge of the map it is
  not fenced, and is no pasture.
- **By day** (06:00 to 20:00) animals with a pasture are out in it; the rest are in their room. **By
  night** all are in. They wander near where they stand and get in nobody's way.
- **A right click on an animal** pets it, with its sound, and takes what it has ready. With a full pack
  the egg waits. A waiting egg stops the next one.
- **Hay:** 14 tufts of tall grass in the meadow, a hay each, back every morning. A right click on the silo
  puts in the hay he carries. A full herd of sixteen eats 16 a day, so some pasture is needed.
- **Farmer Oda** stands by her field as now, with a stall beside her (one more small re-bake of the
  village). Her conversation gains "Have you any animals to sell?", which opens a list like Tilda's. An
  animal is refused without a building for it or with the building full; bought, it is there when he gets
  home.
- **What the products are for:**
  - **Sold:** Tilda's list of what she buys gains the egg, the milk, the wool and cloth.
  - **Cooked,** all known from the start: a Fried Egg (1 egg: 20 energy), an Omelette (2 eggs, 1 mushroom:
    50 energy and half a heart), a Custard (1 egg, 1 milk: 65 energy and a heart). An egg and milk can be
    had raw (6 and 18 energy), and given as gifts like any food.
  - **Woven,** at the workbench: Cloth (2 wool), which Tilda buys for 100 where the wool is 80; and a Wool
    Blanket (2 cloth) for the bed, a furnishing for show.
- **Farming** gains a point for each product taken.
- **Sounds:** a cluck, a bleat and a low, made in code like the rest.

## The economy

**What a day earns today** (`docs/progress/mining-balance-report.md`, at the prices settled since):

| | Coins a day |
|---|---|
| The old plot, 18 cells of turnips (measured: 204 every three days, less seed) | 40 |
| The old plot in pumpkins (the plan's sum; not played) | 90 |
| The quarry, floors 1 to 5, plain Pickaxe (day 2's ore at today's prices) | 53 |
| The quarry, floors 1 to 6, Iron Pickaxe (day 5's ore) | 69 |
| The quarry, all nine floors with the Lantern (day 7's ore) | 173 |

- **The script's eight days at today's prices:** 589 coins in (264 from crops, 281 from the quarry, 44
  found or given) and 244 out (the Pickaxe, bread, seed): **about 345 in the purse on day 8,** with two
  better pickaxes, a copper can and hoe, two sprinklers and the furnace made on the way.
- **After that,** about 110 a day from the safe floors and the old plot together.

**The field at four times the size**

| A full field of | Coins a day | Seed to sow it |
|---|---|---|
| Turnips | 168 | 360 |
| Carrots | 180 | 576 |
| Potatoes | 202 | 720 |
| Pumpkins | 360 | 1440 |

- **What holds it back:** 54 cells to clear and till (about 160 energy); 72 pours a morning, which is 72
  energy and eight trips to the water with the plain can; and the seed.
- **What lets it go:** sprinklers (a copper and an iron bar each; about fifteen for the field) and the
  iron can. So the field fills as the quarry's bars come, over a week or two.
- **This is the number to watch in phase 5.** If farming runs away, crop prices are the lever, and they
  are not touched without the user's word.

**What the Homestead costs, and when**

| Goal | Coins | Waits on | A first guess at the day |
|---|---|---|---|
| The Well | 80 | a copper bar: the furnace's first night | 4 |
| The Coop and a first hen | 310 | 30 wood | 7 or 8 |
| The Silo | 100 | Farming 2 | 9 |
| The Shed | 200 | | 10 or 11 |
| The Barn and a first sheep | 780 | 4 iron bars, Farming 3 | 14 to 16 |
| The Big Coop and four more hens | 590 | 2 iron bars | 18 to 20 |
| The Big Barn, and the barn filled | 800 and about 1500 | 2 gold bars | after day 25 |

- **Everything:** 2380 coins of buildings and 2160 of animals (8 hens, 4 sheep, 4 cows).
- **What a full herd pays,** fed and petted: 8 hens 64 a day, 4 sheep 53, 4 cows 60: 177 a day, or about
  190 with the wool woven. That is the quarry with the Lantern, for sixteen clicks and no energy.
- **An animal pays for itself** in 8 days (a hen), 14 (a sheep) or 16 (a cow).
- **Wood** is the material to gather: the farm gives 58 once, and the countryside 20 a day.
- **Placeables are cheap on purpose:** a fence is half a wood. The yard is for pleasure; the buildings and
  animals are the goal.

## The save

**Version 6,** brought by phase 1. New in the file is one section, `homestead`:
- phase 1: the cells cleared for good;
- phase 2: what lies and stands where, and each sapling's age;
- phase 3: the buildings (which, where, the day it is finished, whether it is the big one), the shed's
  chests and furnace, and the silo's hay;
- phase 4: the animals (its kind, whether it was petted, how near its next product is, whether one waits).

**What an older save keeps, and where it is afterwards**

| In the old save | After it loads |
|---|---|
| The hero inside his cottage | inside the farmhouse, on the cell he stood on: it is the same room |
| The furnishings made (the flags `home/furnace`, `home/chest`, `home/lamp`, `home/rug`) | the same flags, the same places |
| The chest's stacks and the furnace's load | as they were; a furnace lit the night before is ready |
| Tilled soil, crops and sprinklers | the same cells of the plot, which are now the field's clear corner |
| Tools not yet taken from the cottage's floor | on the farmhouse's floor |
| Things laid at his feet at home or in the village | where they lay |
| Wood cut today (the flags `cut/<area>/...`) | as they were: those three areas don't change, and none is in the village |
| The hero standing in the village | where he stood; the old plot is grass under him |
| The story, friends, skills, quests | untouched |
| The homestead | as a new game's: overgrown, nothing set down, built or kept |

- **No file needs anything moved:** `SaveSystem._v5_to_v6()` adds an empty `homestead`. The move is in
  where the door leads and where the plot is drawn.
- **The fixture is made first,** before phase 1 changes anything: `v5_in_the_old_cottage.json`, written by
  the game as it stands today, with the hero inside, the furnace burning, the chest filled, soil tilled
  and watered, crops at each stage and a sprinkler. The version 4 fixture was made the same way.
- **Tests:** that save loads with all of the above and he walks out of the door onto the farm; versions 1
  to 4 still load; a homestead goes through a save and back.

## What is reused, and what is new

**Reused as it is:** areas, exits and entries; the map baker and its sketches; the village's house tiles;
breakables and their drops; rocks and the pickaxes' tiers; `Farm` and `FarmPlot`; the home, the bed and
waking there; furnishings, the chest and the furnace; crafting recipes and the workbench's list; the shop's
menu and its tabs; conversations built from data; doors that keep hours; `Scenery`'s tall trees; lamps that
light at dusk; the village's chickens (`Critter`, `CritterMotion`); giving what doesn't fit at his feet;
the save's safe writing; quests and favours.

**New, pure and unit-tested:**
- `Homestead`: what is cleared, set down, built and kept, and what a morning does to it;
- `Placement`: whether a thing fits a cell, and why not;
- the buildings' rules: footprints, doorsteps, sites, upgrades, refunds;
- `Pasture`: the grass an animal can reach, and how many it feeds;
- the herd's rules: needs, feeding and production.

**New, in the world:** the area `homestead` and three rooms; build mode and its bar; debris; placed things;
buildings; animals; the workbench's tabs; Oda's list.

**New data:** `data/buildings/`, `data/animals/`, `data/rules/homestead.json`, a second shop, 29 items, 21
crafting recipes, 3 cooking recipes, 2 quests; each with its schema in `docs/data/`.

**Pictures and sound,** all made in code: seven kinds of debris, fifteen placeables and a sapling's ages,
five buildings (two of them in a bigger form) and a building site, a sheep and a cow, about thirty icons;
the tunes `homestead` and a quieter `homestead_night`; sounds for setting down, taking up, a building
finished, and the three animals.

## The phases

Each phase ends with every test passing, a commit, and a stop with screenshots and a short summary, and
the user reviews before the next. Inside a phase the work is committed in the steps listed. Bugs are
planted on purpose in each step's code to see that the tests catch them. Each phase brings the GDD,
TECH_DESIGN, the roadmap, the README and DECISIONS up to date; CLAUDE.md is the coordinator's.

**Phase 1: the homestead** *(three commits)*
- [x] 1a. **The move.** First the version 5 fixture. Then the village's west gap, the map, the farmhouse
  and its door, the cottage locked, the field on the homestead, save version 6, the story's words, and
  the nine test suites that used the village's plot moved to the farm.
  *Built 2026-11-18. The map was baked as drawn: no cell shifted. He arrives on the farm at (38, 14) and
  in the village at (1, 16). The main quest's words are measured against the quest log's box where a
  test counted them in letters (150 at the most): the approved words are longer than that, and fit.*
- [x] 1b. **The overgrowth.** The seven kinds of debris as data, cleared for good, fibre, boulders that
  want a better pickaxe, and no tilling under debris.
  *Built 2026-11-18, with the table's counts, blows and drops. The land's stump is a breakable of its
  own (`farm_stump`: the countryside's `stump` comes back each morning). "Clear this first." is said to
  the can, a seed and a sprinkler as well as the hoe. Fibre stacks to 50. **Twenty things shifted when
  baked:** in the drawing above they stood behind a crown (against the woods' edge on the west, east and
  south, or behind an old tree), where the hero could not see what blocked him. Each moved a cell or
  two onto open grass; none on the field moved, and every count is the same. The map as baked is the
  sketch in `tools/greybox/build_maps.gd`.*
- [x] 1c. **The rest.** The two tunes, playtest scenarios (`homestead`; `farm` moved), capture shots, and
  `tools/play_days.gd` kept running (the smallest change, tried for two days at four times speed).
  *Begun 2026-11-18 and finished 2026-11-19 (the step was stopped partway and picked up again). The
  farmhouse plays the farm's day tune. Of the twelve shots the plan names, ten moved to the farm; 96
  stays in the village with 115: it is the "after" of the lane's west end and shows the locked cottage.
  Nine shots were added (159 to 167). `tools/play_days.gd` played its two days at four times speed with
  nothing left out (134 seconds): it works the field's clear corner and does not clear land.*
- **Tests:**
  - *the home move:* in and out of the farmhouse door; sleeping, staying up and collapsing each wake him
    in the farmhouse; the cottage's door is shut at every hour and says its words;
  - *the save:* the version 5 fixture loads with everything in the table above; versions 1 to 4 load;
  - *the map:* the way from the edge to the door is road and 12 cells; every field cell is open ground;
    the pond fills the can; the village has four new cells and no others;
  - *debris:* each kind takes its blows and leaves its drop lying; cleared stays cleared through a save
    and a morning; a boulder refuses the plain pickaxe; a full pack leaves the drop; the hoe refuses a
    cell under debris; the counts on the map.
- **Done when** a new game walks from the square to the farmhouse, takes the tools, plants in the clear
  corner, fills the can at the pond, clears weeds and a rock, sleeps and wakes there; a save made in the
  old cottage opens in the farmhouse with all it had; and all tests pass.
- **Screenshots:** the lane's west end before and after; the locked cottage and its words; arriving on the
  farm; the farmhouse and its yard; inside; the clear corner sown; the pond; a boulder; the land at night;
  the quest log; Bram's welcome; the title.

**Phase 2: placing** *(two commits)*
- [x] 2a. **The rules and the mode.** `Placement`, what is kept, build mode with its ghost and bar, the
  three paths, the fence and the gate, collisions and sorting, the save.
  *Built 2026-11-19, with D12 to D15 and D18 as written. A placeable is an item of type `placeable`.
  The farmhouse's doorstep is the path's end, so it is refused as road ("That is the road."): no cell
  of today's land says "That is a doorstep.", and the rule waits for phase 3's buildings. The keys do
  what the mouse's two buttons do (the sword's key sets down, the item's key takes up). In this step
  the five things come only from `tools/playtest.gd -- build`: the "Place" tab is step 2b's.*
- [x] 2b. **The rest of the list.** Two floors, the hedge, the lamp post, the bench, the flower beds, the
  saplings; the hand; the workbench's "Place" tab and Tilda's new wares.
  *Built 2026-11-19, with the table's fifteen, costs and prices, and D16, D17 and D19 as written. The
  hand moves a thing as it is: a sapling keeps its mornings and a grown tree stays a tree (a right
  click takes it up and gives back the sapling). The nine recipes are known from the first day. A lamp
  post keeps the village lamps' hours, 18:30 to 06:30. Nobody has played the phase by hand.*
- **Tests:**
  - *placement rules:* every refusal in the table with its words; two things to a cell; only on the
    homestead;
  - *collision updates:* a fence blocks the moment it is set and frees its cell the moment it is taken up;
    a path never blocks; the hero walks through a gate;
  - *save and load of placed objects,* a sapling's age among them;
  - *moving and taking up:* the item comes back; a full pack refuses; a grown tree gives a sapling;
  - saplings by the morning; a lamp post lit at dusk; the mode's keys and mouse; the clock stands in it;
    nothing is set down outside it.
- **Done when** a yard can be fenced, gated, paved and lit, taken up again, and is there after a save.
- **Screenshots:** a green ghost; a red one on the road with its words; a fenced yard with paths; a lamp
  post at night; a sapling at each age and the hero behind a grown tree; the "Place" tab; Tilda's list.

**Phase 3: buildings** *(three commits; the largest phase)*
- [x] 3a. **Plans.** The "Build" tab, kits, building sites and the morning that finishes them; the Well;
  the Silo, with the meadow's tall grass and hay.
  *Built 2026-11-19, with D20, D21 and D29's hay as written, and the table's costs and unlocks. A kit is
  an item of type `kit`; a building is a file in `data/buildings/`. A plan refused says what is short by
  name. The ghost holds a building by its door (or the middle of its bottom row), and the doorstep is
  asked the table as every cell is. A tuft of tall grass doesn't grow where something is set down (a
  save from phase 2 may have one there).*
- [x] 3b. **Rooms.** The Coop, the Barn and the Shed with their insides, doors that follow the building,
  the shed's chests and furnace, the two upgrades.
  *Built 2026-11-19, with D22 and D23 as written and the table's costs, sizes and unlocks. The doormat
  of each room leads to an entry the homestead puts on the building's doorstep as it loads. The shed's
  chests and furnace are three "Build" recipes known once it stands, with flags `shed/...`; they are
  kept by key (`GameState.furnace(&"shed")`, `store(&"shed_a")`). The big forms wear another roof.*
- [x] 3c. **Moving and demolishing,** with refunds.
  *Built 2026-11-19, with D24 as written. The hand lifts a building and sets it down elsewhere, at once,
  with what is in it; a right click asks, and a second pulls an empty building down for half of each
  material (its upgrade's too), what doesn't fit laid at his feet. A right click on a site gives its
  kit back. Nothing takes hay out of the silo yet, so a silo with hay stays.*
- **Tests:**
  - *construction:* a kit set down is a site today and a building at dawn, through a save; one of each;
    the doorstep stays free; a plan is refused without its coins or materials and says what is short;
  - the well fills the can; hay is cut, carried and stored, and a full silo leaves it in the pack;
  - in and out of each room wherever its building stands;
  - the shed's chests and furnace through a save;
  - *moving:* what is in it goes with it; refused where it doesn't fit;
  - *demolishing and refunds:* refused unless empty; half of each material given; what doesn't fit laid
    at his feet.
- **Done when** each of the five can be bought, set down, found standing the next morning, entered where
  it has a room, moved, upgraded and demolished.
- **Screenshots:** the "Build" tab; a kit's ghost; a site; each building standing; each room; the shed
  furnished; the well filling the can; a demolition's refund.

**Phase 4: animals** *(three commits)*
- [x] 4a. **The rules.** Animals as data, the herd's and the pasture's rules, Oda's stall and list, the
  save.
  *Built 2026-11-19, with D25 to D28 and the table's prices, paces and grass as written. A kind is a file
  in `data/animals/`; its price is Oda's shop's (`data/shops/oda.json`, a ware `{"animal": ...}`). A
  morning goes in halves of a morning; the herd is fed in the order bought; a pasture is what the
  doorstep reaches through what can be crossed, and the land as it was is read from its scene once a
  run, so a morning knows each pasture while he sleeps. Oda's stall is the village's market stall
  again, beside her at (16..18, 30..31). The egg, the wool and the milk came with this step.*
- [x] 4b. **In the world.** The three animals as creatures, out by day and in by night, petting and
  taking, their sounds.
  *Built 2026-11-19, with D26 and D28 as written. An animal walks among its own cells (its pasture by
  day, its room's floor by night), so it blocks nobody and never passes a gate; build mode holds the
  animals still. What one has ready shows over its head; a hungry one shows it too. The hen is the
  village's chicken; the sheep and the cow are a new sheet.*
- [x] 4c. **Into the rest.** The products, the three dishes, Tilda's prices, cloth and the blanket,
  Farming's points.
  *Built 2026-11-19, with the table's dishes, prices and cloth, and D30's point a product. The dishes
  are known from the start; cloth and the blanket are on the workbench's "Make" tab, known once their
  makings are found; the blanket is a furnishing of the farmhouse that lies over the bed. Capture shots
  192 to 203.*
- **Tests:**
  - *needs and production:* each row of the morning's table; a product waits and stops the next; pasture
    before hay before hunger; a full building; a bigger one holds eight;
  - *pasture:* a gap in the fence is no pasture; a gate counts as fence; a floor is not grass;
  - buying is refused without a building or room; an animal bought is in its building;
  - in at 20:00 and out at 06:00; one click pets and takes; a full pack leaves the egg waiting;
  - the dishes cook; Tilda buys; cloth is worth more than its wool; Farming rises.
- **Done when** a hen can be bought, fed either way, petted, and its eggs cooked, sold and given, and the
  same for a sheep and a cow.
- **Screenshots:** Oda's list; hens in their pasture; the coop's inside at night; a sheep with wool to
  give; the silo; the three dishes; Tilda's list.

**Phase 5: balance** *(two commits, and a third for the tuning)*
- [ ] 5a. **Two favours,** both at three marks:
  - **Tilda, "Market Day":** 6 eggs. 50 coins and 2 Carrot Cakes. (She teaches at two marks, as Wenna and
    Edda do.)
  - **Farmer Oda, "A Roof for the Flock":** a Coop standing on the farm. 60 coins and 5 hay.
- [ ] 5b. **Ten days played** by `tools/play_days.gd`, taught the farm: the walk, the field, clearing,
  the workbench's new tabs, setting a building down, buying and tending animals. A report,
  `docs/progress/homestead-balance-report.md`, with coins, materials, buildings and animals for each day,
  set beside this plan's guesses, and the numbers it would change.
- [ ] 5c. **The tuning,** in data, on the user's word.
- **Done when** the report is in hand, the numbers are settled with the user, and all tests pass.

**The last word is the user's,** after each phase:
- [ ] *(yours)* the farm feels like home, and the walk to the village is short enough
- [ ] *(yours)* build mode is easy to use, and a yard is a pleasure to lay out
- [ ] *(yours)* a building feels like a goal reached
- [ ] *(yours)* the animals are worth their keep and not a chore

## Where the request meets the rules

The user asked for two things by name: how the home's move breaks CLAUDE.md's rules, and how CLAUDE.md
should read afterwards. I went through it from top to bottom. "Broken" means the words become false;
"bent" means they stay true only with something added.

| | CLAUDE.md says | What the request does | |
|---|---|---|---|
| C1 | "the hero's home is the area `home` (the thatched cottage west of the weaver's...)" | The home is the farmhouse on the homestead. By D8 it is still the area `home`; the cottage is locked. | **Broken** (the place) |
| C2 | "It lies in Hearthvale as a `FarmPlot` node (cells 12..17, 18..20)... **no map re-baked.**" | The plot lies on the homestead, 12 by 6. The village has none, and is re-baked for the lane's end. | **Broken** |
| C3 | "Do not add areas beyond the hero's home and plot unless the user asks." | The user asks: the homestead, and three rooms. | **Broken**, by request |
| C4 | "A furnishing is the flag `home/<id>` and a `Furnishing` node with a fixed place in the cottage's scene... Do not move one, or anything that stood in the cottage." | By D8 nothing moves: the cottage's room is the farmhouse's room. The word "cottage" is wrong, and the shed adds furnishings with flags `shed/<id>`. | **Bent** |
| C5 | "**Do not**... let the furnace hold two loads... or put a furnishing anywhere but its own place" | A second furnace and two more chests, in the shed (D23). Each still holds one load, and each has its own place. The mining plan also said "no second chest" and "no placing furniture by hand". | **Bent**; the plan's two lines broken |
| C6 | "Do not make the mouse a pointer **in play**..." | "A ghost preview... Click to place." By D12 the pointer is in build mode, a screen, and play is untouched. Read as placing during play, it would break the rule outright. | **Bent** |
| C7 | "Do not put food, or anything that isn't held in the hand, in the bar without asking." | Placeables have a bar of their own (D12), so nothing new goes on the item bar. The other way round (the alternative to D12) would put fifteen things on it. | Kept, by D12 |
| C8 | "Do not add motion to the scenery... only the water moves" and "A still world" | Animals move, but creatures were left moving by that rule. Saplings change picture at dawn and never sway. The ghost and a building site are not scenery. | Kept; worth saying |
| C9 | "branches and stumps are breakables with `"returns": "daily"`"; "A broken rock stays broken until morning: go through `GameState.break_rock()`" | On the homestead what is cleared never returns, and is kept in the homestead's own record. | **Bent** |
| C10 | "outdoors at night the tune is `night`" | The homestead has its own quieter night tune. | **Bent** |
| C11 | "Do not let art or animation change gameplay timing, hit detection or collisions, unless a step says so." | Placed things change collisions, on purpose. Nothing existing changes, as the request also rules. | Kept; worth saying |
| C12 | "A crafting recipe is a file in `data/crafting/`...: its `station`..., `needs`, `makes` (an item, or a `furnishing`) and an optional `unlock`" | Recipes gain a tab, may make a placeable or a kit, and may wait on a building. Coins are already an item, so a plan's price is an ordinary need. | **Bent** |
| C13 | "The clock runs in areas but not in dungeons, conversations or menus." | Build mode stops it, as a menu. | **Bent** |
| C14 | "a shop is a file in `data/shops/`" (and TECH_DESIGN: "There is one shop, `tilda`") | A second shop, whose wares are animals. | **Bent** |
| C15 | "Do not change a price, a count or a skill's numbers for balance without the user's word." | Two existing numbers change: the plot's size, and a new deed for Farming. Both are in D30 for that word. | Needs the word |
| C16 | "There are eleven quests." | Thirteen after phase 5. Recipes go from eleven to fourteen. | **Broken** (a count) |
| C17 | The scenarios, shots and tests that take the old home for granted | See "Tests and tools that will change". | |
| C18 | "Nothing further is planned: ask before building more." | This is the asking. | |

**Kept as they are, and they bind the new work:** art and sound made in code; new tiles at the end of the
atlas; the Height layer never changed for looks; a full pack loses nothing; saves only through
`SaveSystem`; the game never leaves without saving; menus that point, take the wheel and leave on Tab or
Esc; the left click uses what is in hand and the right click interacts; no story beyond what is listed;
"take the genre's mechanics, never another game's art, interface or characters".

### How CLAUDE.md should read afterwards

The words below are proposed. The coordinator makes the changes, each once its phase is built and
approved. Cells are the sketch's; the phase's write-up carries the baked ones.

**R1. Under "Current goal", a new paragraph** *(on approval of this plan; one sentence changed after each
phase)*:

> **The Homestead (the user's request, 2026-11-17; `docs/progress/homestead-plan.md`, approved on ...):** a
> farm of the hero's own west of the village, in five phases with a stop after each for the user to
> review: 1 the homestead and the home's move, 2 placing things, 3 buildings, 4 animals, 5 balance. **No
> phase is built yet.** The plan's numbered decisions are the approved ones (they stand in for the
> `docs/HOMESTEAD-NOTES.md` the request names, and each is in `docs/DECISIONS.md`). Build nothing beyond
> the plan's list, and nothing of a later phase early.

**R2. "Home and sleep (P2b)", the whole of it** *(after phase 1; C1)*:

> - **Home and sleep (P2b; moved by the Homestead):** the hero's home is the area `home`, the inside of
>   **the farmhouse on the homestead**. Until the Homestead it was the thatched cottage west of the
>   weaver's; the room and every place in it are the same. Its doormat leads to `homestead` /
>   `farmhouse_door`. The cottage in Hearthvale is empty: its door (`HomeDoor`) keeps the hours of a place
>   that is never open (`old_cottage` in `data/rules/hours.json`), so its cell is solid and the area says
>   the place's words. Sleeping is the `sleep` effect of the bed's conversation (`data/dialogue/bed.json`):
>   `GameState.sleep()` starts the next day rested, and the area saves. At 02:00, and after a collapse, the
>   hero wakes by his bed in the farmhouse. **Anything that ends a day saves the game and changes scene:**
>   a test that does it points `SaveSystem.current_slot` at a slot of its own and replaces the area's
>   `travel`. **A test that walks out of his door arrives on the homestead, not in the village.**

**R3. "Farming (P3a)", in place of its third sentence** *(after phase 1; C2)*:

> It lies **on the homestead** as a `FarmPlot` node (cells 22..33, 17..22; the rules' plot is 12 by 6):
> ground to walk on, drawn over the map. **Hearthvale has no plot.** The plot's own cells (0..5, 0..2),
> its north-west corner, are clear in every game and are where an older save's soil and crops are; the
> rest starts overgrown, and **a cell with something on it can't be tilled until it is cleared.** **A
> test that tills, plants or waters loads `homestead`, with the plot at `Vector2i(22, 17)`,** and fills
> the can at the pond (4..9, 21..24).

**R4. In "Do not"** *(after phase 1; C3)*:

> - Do not add areas beyond the homestead (`homestead`) and the insides of its buildings (`coop`, `barn`,
>   `shed`, from phase 3) unless the user asks.

**R5. "Hours and night (P2e)", in place of "and outdoors at night the tune is `night`"** *(after phase 1;
C10)*:

> and outdoors at night the tune is `night`, or the area's own `night_music` where it names one (the
> homestead's is `homestead_night`)

and one sentence more *(after phase 4)*:

> Animals keep the villagers' hours: in their building from 20:00 to 06:00, and nobody walks them there.

**R6. Under the Old Quarry's "Rocks", after "go through `GameState.break_rock()`."** *(after phase 1;
C9)*:

> **On the homestead a rock is broken for good:** it goes through `GameState.clear_debris()`, which keeps
> its cell in `GameState.homestead()`, and no morning brings it back. A boulder there wants the Copper
> Pickaxe and a great boulder the Iron one; a lesser pickaxe is told so and spends nothing.

**R7. Under Crafting's "Wood", one sentence more** *(after phase 1; C9)*:

> **On the homestead what the sword clears is gone for good** (weeds, bushes, logs, stumps: breakables
> with `"returns": "never"`, their cells kept in `GameState.homestead()`, not in flags). **A test that
> wants one back starts a new game.**

and *(after phase 3)*: "The meadow's tall grass there is `"returns": "daily"` and leaves a hay."

**R8. Crafting's first line and its "furnishing" rule** *(after phase 1, the shed's sentence after phase
3; C4)*:

> - **Crafting (...):** made at home, in the farmhouse.
>   - **A furnishing is a flag and a `Furnishing` node with a fixed place** in a room's scene. In the
>     farmhouse (`home.tscn`, flags `home/<id>`): the workbench (always there) at cell (9, 3), the
>     furnace (6, 2), the chest (2, 2), the lamp (4, 2), the rug (2..3, 4). **A test that wants one sets
>     `Crafting.furnished_flag(&"furnace")` or crafts it,** and stands at it with
>     `Steps.stand_before(home, "Furnace")`. Do not move one, or anything that stood in that room. **A
>     furnishing is never set down by hand:** what is set down by hand is a placeable, out of doors on
>     the homestead.

> In the shed (`shed.tscn`, flags `shed/<id>`): two chests and a furnace, each at its own cell.

**R9. Crafting's "furnace", "chest" and "Do not"** *(after phase 3; C5)*:

> - **The furnace**... One load, five bars at the most (`data/rules/crafting.json`). **There are two once
>   the shed has its own:** `GameState.furnace()` is the farmhouse's and `GameState.furnace(&"shed")` the
>   shed's, each with one load.
> - **The chest**... holds 24 stacks and several of one thing. **There are three once the shed has its
>   two:** `GameState.store()`, `GameState.store(&"shed_a")` and `GameState.store(&"shed_b")`.
> - **Do not** bump the save's version for crafting's fields (...), let a furnace hold two loads, let a
>   chest take coins, keys or quest things, or put a furnishing anywhere but its own place: each was
>   decided with the plan. (The shed's furnace and chests were decided with the Homestead's.)

**R10. Crafting's "recipe" rule** *(after phase 2; "build" and `built` after phase 3; C12)*:

> - **A crafting recipe is a file in `data/crafting/`** (cooking keeps `data/recipes/`): its `station`
>   (`workbench` or `furnace`), its `tab` at the workbench (`make`, `place` or `build`; `make` if it names
>   none), `order`, `needs` (coins are a need like any other: the item `coin`), `makes` (an item, which
>   may be a placeable or a building's kit, or a `furnishing`) and an optional `unlock` (an item `found`,
>   a `skill` and `level`, or a building `built`).

**R11. In "Do not", a new line after the one about the mouse in play, which stays** *(after phase 2; C6,
C13)*:

> - **In build mode the mouse points at a cell** (approved with the Homestead's plan). Build mode is a
>   screen, as a menu is: B opens it, on the homestead only; the hero stands still and the clock with him
>   (`is_in_menu()`). The thing chosen shows as a ghost on the cell under the mouse (the movement keys
>   move it a cell at a time), green where it fits and red where it doesn't, with the reason in words. A
>   left click sets it down; a right click takes up what is there; the wheel and the keys 1 to 9 choose on
>   the build bar; Tab, Esc or B leave. **Nothing is ever set down with the mouse in play,** and where a
>   click lands in play still doesn't matter.

**R12. In the item bar's rule, two sentences more** *(after phase 2; C7)*:

> **What is set down in build mode is chosen on the build bar, never the item bar:** paths, fences,
> saplings and kits take no slot of it. The sprinkler is as it was: on the item bar, set on the plot.

**R13. In "Do not", the line about the scenery, with two sentences more** *(after phase 2; the animals'
after phase 4; C8)*:

> **On the homestead the same holds:** a sapling changes its picture at dawn and never sways, a lamp
> post's light is steady, a building site is one picture. The animals are creatures, like the village's
> chickens, and move.

**R14. In "Do not", the line about art and collisions, with one sentence more** *(after phase 2; C11)*:

> **What the player sets down is not art:** a fence, a hedge or a building blocks its cells because
> `GameState.homestead()` says it stands there, and nothing else in the game changes for it.

**R15. "The shop and meals (P3c)", one sentence more** *(after phase 4; C14)*:

> **There are two shops:** `tilda`, and `oda` (Farmer Oda's stall, opened from her conversation). A ware
> may be an `animal` in place of an item: it is refused without a building for it or with the building
> full, and bought, it is in its building.

**R16. "Skills (P4b)", one sentence more** *(after phase 4; C15)*:

> **Farming also rises by tending animals** (the deed `tend`: an egg, a fleece or a pail taken): a test
> that takes ten has raised a level.

**R17. The balance pass's "eleven quests"** *(after phase 5; C16)*:

> - **There are thirteen quests.** A test that lists them, counts the quest log's lines, or reads the
>   ending's "of 13" carries that number.
> - **Tilda and Farmer Oda ask a favour at three marks too** ("Market Day": 6 eggs; "A Roof for the
>   Flock": a coop standing, the flag `built/coop`). **A test that talks to Tilda at three marks gets her
>   lesson first if `recipe/carrot_cake` isn't set.**

**R18. Under "Commands"** *(after phase 1; `build` after phase 2, `animals` after phase 4)*:

> scenarios in the script: late, gifts, bram, gate, rest, farm, market, kitchen, home, village,
> homestead, marsh, quarry, deep, craft, warden, crypt, shade, ending

and *(after phase 5)* "Ten days played by a script...", in place of "Eight days".

**R19. A new block at the end of "The pivot's rules in code"** *(after phase 1; each later phase adds its
own lines as built)*:

> - **The Homestead (2026-11-...; `docs/progress/homestead-plan.md`, TECH_DESIGN §30):** the area
>   `homestead`, west of the village by the lane's west end (`WestRoad` in the village, `EastRoad` on the
>   farm). The hero's home, his field and a pond are there.
>   - **`GameState.homestead()`** is a pure `Homestead` (`core/homestead/`): what has been cleared for
>     good. Go through `GameState.clear_debris()`; `EventBus.homestead_changed` tells whoever draws it.
>   - **Debris** is weeds, bushes, logs and stumps (breakables with `"returns": "never"`) and rocks,
>     boulders and great boulders (`Rock` nodes whose kind names the pickaxe it wants). **A test that
>     clears one equips the sword or the right pickaxe, faces it, and lets each blow finish.**
>   - **Save version 6** (the section `homestead`). The fixture
>     `tests/fixtures/saves/v5_in_the_old_cottage.json` was written by the game as it stood before the
>     Homestead.
>   - **Do not** let anything cleared come back, put debris on the field's clear corner, the road or the
>     yard, or add monsters, villagers or forage to the homestead: each was decided with the plan.

**Not CLAUDE.md, but the same change:** `docs/GDD.md` §13 lists "livestock of your own", "placing
furniture by hand" and "new areas beyond the hero's home and plot" as out of scope. Each comes off that
list with its phase.

## Tests and tools that will change

- **Nine test suites use the village's plot** (`PLOT = Vector2i(12, 18)`, or a cell on it):
  `farm_test`, `crops_test`, `farm_round_test`, `skills_test`, `upgrades_test`, `whole_story_test`,
  `mouse_test`, `farm_save_test` and `crop_save_test`. They move to the homestead in step 1a. Their
  checks stay; their area and cells change.
- **`home_test`, `doors_test`, `village_test`:** the cottage's door (now shut), the houses' doors (the
  home's is on the farm), the village's reachable cells (four more).
- **`farm_test`:** "the plot lies between the shop and the well" and "the can fills at the well and at
  the pond" are rewritten for the farm; the village's well and pond are still tested as water.
- **Tests that count:** the plot's 18 cells; the workbench's thirteen lines; Tilda's wares; eleven
  recipes; eleven quests and the ending's "of 11"; the furnishings' list.
- **`tools/capture.gd`:** twelve shots stand at the cottage's door, the village's plot or the well beside
  it (96, 110 to 112, 114 to 119, 129, 153). They keep their numbers; all but the well's move to the
  farm. New shots follow 158.
- **`tools/playtest.gd`:** `farm` starts on the homestead; a new `homestead` (and later `build`,
  `animals`).
- **`tools/play_days.gd`** takes the plot to be in the village and the home to open onto it. It has no
  tests: its test is that it plays.

## Open questions

1. **`docs/HOMESTEAD-NOTES.md` doesn't exist.** Is it right that this plan's decisions, once approved and
   recorded in `docs/DECISIONS.md`, take its place?
2. **`docs/HOMESTEAD.md`** is an untracked copy of the request, word for word the same as
   `docs/progress/homestead-request.md`. Delete it, or keep it?
3. **Build mode and the clock (D12).** I propose the clock stops, as at the workbench: a fence costs no
   time and no energy. If laying out the farm should cost the day something, say so: the clock can run.
4. **Hay for sale.** The request gives two ways to feed (pasture, and hay cut on the farm). Should Farmer
   Oda also sell hay, for a player with neither? It is not in the request, so it is not in the plan.
5. **The welcome sign in the square** names the ways north and south. Should it name the farm to the
   west? The request lists only the opening, the quest's first steps and Bram, so it is left alone.

## Risks

- **Scope creep, first and most.** This is larger than mining and crafting together. The request's list
  is long, and every item invites a second (names for animals, a scarecrow, seasons of grass, a second
  coop). The plan builds the list and nothing else.
- **Two phases are too big to be one piece of work:** phase 3 (five buildings, three rooms, two
  upgrades, moving, demolishing) and phase 4 (three animals, two ways to feed, pasture, hours, a stall,
  four products into four systems). Each is three commits, and I would show the user step 3a (plans, the
  Well and the Silo) before building the rooms.
- **What I would leave out or put last if a phase runs long:**
  - phase 1: the three great boulders; the second tune (the night could keep the game's own);
  - phase 2: the bench, the flower beds and the hedge (looks only); lifting with the hand (taking up and
    setting down does it);
  - phase 3: moving a building (demolish and build again does it, at a cost); the Shed last;
  - phase 4: the cow (the barn works with sheep); the Wool Blanket; pasture, if it must be, leaving hay
    as the only feed for a first look;
  - phase 5: the favours before the played days.
- **The tests' move.** Nine suites change area in step 1a. A check weakened in the moving would not be
  seen. Each moved suite is run before and after, and bugs are planted in the farm's code afterwards.
- **The economy.** A field four times the size is four times the crops (above). Animals add 177 coins a
  day at the far end. Ten played days will not reach the far end; the report says how far it got.
- **`tools/play_days.gd`** is two thousand lines with no tests, and phase 5 asks it to clear land, lay
  out a building and tend animals. It may take as long as a phase's own code.
- **The area's script is two thousand lines already** (`world/areas/area_controller.gd`). Build mode,
  the buildings and the animals should each be a node and a pure class of their own, or it becomes the
  place every bug hides.
- **Build mode on a pad** is the least certain part of phase 2: a ghost moved a cell at a time is slow
  over forty cells.
- **A cell the player can no longer reach.** He can fence himself in, and take the fence up again. The
  road, the door path and every doorstep can't be built on, so the house, the way out and every building
  can always be left.
- **Two ways of drawing a building.** The farmhouse is baked tiles, like the village's houses, with their
  wall faces, ridges and cast shadows. A coop set down by hand is one picture with a soft shadow. They
  must be painted to look of a piece.
- **Lights.** The engine lights one drawn thing with at most 16 lights, and the area already drops the
  narrowest beyond that. Twenty lamp posts in view would not all light.
- **Two re-bakes of the village** (the lane's end in phase 1, Oda's stall in phase 4). The baker rewrites
  only its three layers, and the layout tests guard the rest.
- **Fibre** comes from the land once (102). Tilda sells it so that a player who demolishes and rebuilds
  is never stuck.

## Not in this plan

No new villagers; no story beyond the lines listed. No monsters on the farm. No tilling outside the
field. No second coop, barn, shed, well or silo. No setting down of things indoors or off the farm. No
changing of the ground's height. No seasons, weather, breeding, ageing or death of animals; no names for
them. No shears, pail or axe. No hay for sale. No selling of stone, wood, coal, fibre or hay. No fishing
in the pond. Ask before adding any of them.

## Checked in the code

What the plan rests on, and where I read it. Nothing was run but the tests and six screenshots.

| Fact | Where |
|---|---|
| The lane is rows 16 and 17 from column 3; the west woods are columns 0 and 1; the cottage is (6..11, 11..14) with its door at (8, 14) | `tools/greybox/build_maps.gd`, the `village` map |
| The plot's node is at (192, 288): cell (12, 18); the cottage's door leads to `home` / `door`; a new game starts at cell (23, 20); Farmer Oda stands at (15, 31) | `world/areas/village/village.tscn` |
| The home's bed, hearth, tools and five furnishings, and its doormat to `village` / `home_door` | `world/areas/home/home.tscn` |
| Waking at 02:00 and after a collapse goes to `WorldPaths.HOME_AREA`, `HOME_BED` | `world/areas/area_controller.gd` (`_wake_at_home`), `world/world_paths.gd` |
| The plot is a rectangle of its own cells, sized by the rules; a save keeps cells by "x,y" and drops any outside it | `core/farming/farm.gd`, `data/rules/farm.json` |
| A door is shut outside its place's hours, and a place whose hours begin and end together is never open | `core/time/hours.gd`, `core/time/day_clock.gd` (`within`), `gameplay/interactables/area_exit.gd` |
| Walking 72, sprinting 120 pixels a second; tired, 85% | `core/player/player_motor.gd`, `data/rules/energy.json` |
| The save is version 5; `home` holds the furnace and the chest; migrations run one step at a time | `autoload/game_state.gd`, `autoload/save_system.gd` |
| Furnishings are flags `home/<id>` and nodes with fixed cells; one `Store`, one `Furnace` | `gameplay/interactables/furnishing.gd`, `core/crafting/`, `autoload/game_state.gd` |
| Coins are the item `coin`, and a recipe's needs are items | `autoload/game_state.gd` (`craft`), `data/items/items.json` |
| A breakable may return daily, by a flag `cut/<area>/<x>,<y>`; a rock is broken for the day through the mine's record | `gameplay/interactables/breakable.gd`, `rock.gd` |
| Wood stacks to 30, stone to 50; the tools' kinds and tiers | `data/items/items.json` |
| The keys in use (B is free on the keyboard) | `tools/setup_input_map.gd` |
| What Tilda sells and buys; Oda's conversation | `data/shops/tilda.json`, `data/dialogue/farmer_oda.json` |
| The words that mention the cottage or the plot | a search of `data/`, `ui/`, `core/`, `gameplay/`, `README.md` |
| The scenarios, shots and tests that use the old home and plot | `tools/playtest.gd`, `tools/capture.gd`, `tools/play_days.gd`, `tests/` |
| What a day earns | `docs/progress/mining-balance-report.md`, with today's prices from `data/shops/tilda.json` |

**Not checked:** how build mode's ghost would read the mouse against the camera; whether a tall picture
set down at run time sorts as the baked trees do; how the baker would lay a second house front outside
the village; what three more rooms and 145 debris nodes cost a frame. Each is the first thing its phase
should try.

**Before-pictures** (taken with `tools/capture.gd`, shots 54, 96, 97, 110, 116 and 151, with the game as
it stood at `dfb573d`) are in `reports/homestead/before/`, which git ignores: the cottage's door with the
lane's west end and the plot; the plot bare and with crops; the west side of the village with Farmer Oda
by her field; the home's inside, bare and with every furnishing.
