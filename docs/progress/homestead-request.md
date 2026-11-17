# Hearthvale Homestead

Add HEARTHVALE HOMESTEAD: a new farm area outside the village, where the hero now
lives, builds structures, shapes the land and keeps animals. Follow CLAUDE.md:
content as data (JSON with schemas), state in GameState, systems on EventBus, pure
logic in RefCounted classes with unit tests, all art and sound made in code.

Work in phases. After each one: all tests pass, commit, and STOP with screenshots
and a short summary. Before starting any phase, read docs/HOMESTEAD-NOTES.md for
decisions already approved.

## Phase 0: Plan (no code)
Propose:
- where the homestead connects to the world, its map size and layout
- how the hero's home moves out of the village, and what happens to the old house
- which story and quest lines need updating
- the full list of buildings, placeables and animals with costs
- the placement rules
- the save migration
- the economy numbers
Flag conflicts with existing systems. Wait for approval.

## Phase 1: The homestead area
- A NEW AREA, separate from the village: an old, overgrown farmstead on the road
  west of Hearthvale, reached by a short path from the village edge (keep the walk
  under 20 seconds, so the 14-minute day still works).
- The hero's house moves here: bed, hearth, workbench, furnace, chests and the farm
  plot all live on the homestead. Sleeping, waking and fainting from no energy
  now happen here.
- The hero's old house in the village becomes an empty, locked cottage (or propose
  a better use in the plan).
- Story: the hero arrives in Hearthvale having inherited this run-down farmstead.
  Update the opening, the "settle in" quest steps and Elder Bram's lines to fit.
  Keep the rest of the story unchanged.
- The farm map is large (propose about 4x the old plot) and starts overgrown with
  stumps, rocks, logs, weeds and bushes that clear with the existing tools and give
  wood, stone and fibre. Some need upgraded tools.
- Its own music for day and a quieter track for night, synthesised like the rest.

## Phase 2: Placement and land shaping
- A build mode: pick an item, see a ghost preview snapped to the 16x16 grid,
  tinted green where it fits and red where it doesn't. Click to place.
- Placeables (craft at the workbench or buy from Tilda): dirt, stone and wood
  paths; wooden and stone flooring; fences and gates; hedges; lamp posts; benches;
  flower beds; and saplings that grow into trees over a few days.
- Move and pick-up mode for everything placed. Picking up returns the item.
- Placed objects update collisions and y-sorting, and are saved in GameState.
- Nothing can be placed over the house, the area's exits, or the paths to them.
- Placement only works on the homestead, not in the village or other areas.

## Phase 3: Buildings
- A Building Plans menu at the workbench. Each building costs materials and coins,
  is placed with the same ghost preview, and is finished the next morning.
- Buildings: Coop (chickens), Barn (sheep and cows), Shed (an enterable room for
  chests and crafting stations), Well (refills the watering can), Silo (stores hay).
- Each animal building has one upgrade that holds more animals.
- Enterable buildings get their own simple interior scene.
- Buildings can be moved or demolished; demolishing refunds part of the materials.

## Phase 4: Animals
- Chickens, sheep and cows, bought from a new stall at Farmer Oda's.
- Each day: animals need feeding (hay from cut grass stored in the silo, or put out
  to graze on grass inside fences) and like being petted. Fed, happy animals
  produce eggs, wool or milk each day or every few days; unhappy ones produce less.
- Animals wander inside their building or fenced pasture, go in at night, and come
  out in the morning. Simple, readable behaviour; no complex pathfinding.
- Products feed existing systems: new cooking recipes, Tilda buys them, and one or
  two crafting recipes use wool.
- Animal care counts toward the Farming skill.
- Animal sounds synthesised like the rest.

## Phase 5: Balance and integration
- Two new favours from villagers that ask for animal products or a built structure.
- Check the economy alongside mining and crops: building should feel like a goal,
  not something you can afford on day 2 or never.
- Play through days 1-10 and report coins, materials, buildings and animals per day.

## Rules
- Old saves load: the hero's home, placed stations, chests, tilled soil and crops
  move to the homestead in the migration, and a save made inside the old house
  wakes the hero in the new one.
- No new villagers. Story changes only as described in Phase 1.
- No terrain height editing (cliffs stay as they are).
- Art must not change existing hit detection, collisions or timing.
- Unit tests for placement rules, collision updates, building construction,
  move/demolish refunds, animal needs and production, the home move, and
  save/load of placed objects.
