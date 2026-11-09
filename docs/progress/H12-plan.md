# H12 — A more detailed world (plan)

Goal (ROADMAP H12): more to see and do in the areas we have, instead of new ones. The places get denser and
livelier, grass and pots can be cut and broken, more villagers talk, and three more heart pieces are hidden (four
make a heart). The map stays the same size.

## Design
- **Grass and pots** (`Breakable`):
  - Tall grass and clay pots stand in their cell. A sword or a bomb cuts or breaks them, with a sound and a burst
    of leaves or shards. Grass leaves stubble; a pot is gone.
  - They drop what their data says: `data/breakables/<id>.json`, a new kind of content validated like enemies.
    It holds what can break it, its sound, its burst, and a weighted drop table of hearts, coins, arrows and
    bombs.
  - They're back on the next visit (not saved).
- **Spawn markers:**
  - The map baker paints grass, pots and critters onto a hidden `Spawns` tile layer, as it paints the rest of the
    map.
  - On load, the area turns each marker into its node.
  - Placement stays in `build_maps.gd`'s layouts, and no tool has to attach scripts to scenes.
- **Ambient life** (`Critter`, a pure `CritterMotion` for the moves):
  - chickens peck and wander in the village, never into solid or occupied cells
  - butterflies flutter over flowers
  - fireflies drift and blink in the Old Wood

  None of them blocks the hero, fights, or is saved.
- **More detail:**
  - New pixel-art props, painted in the tile tool:
    - outdoors: crates, barrels, hay, log piles, stumps, lamp posts, a market stall, a washing line, a well bucket,
      standing stones
    - indoors: chairs, a cupboard, a loom, plants, candles, a counter
  - Hearthvale, both outdoor areas beyond it, and all three interiors are dressed with them.
- **Heart pieces**, four in all:
  1. the Old Wood's shrine (H8)
  2. a nook in the village woods behind tall grass
  3. a corner of the North Fields plateau behind tall grass
  4. a secret room in the Cistern behind a new cracked wall (that room was solid rock)

  The HUD shows a small heart filling up as pieces are found.
- **More villagers:** a farmer, a child and a guard in Hearthvale, and a shepherd in the North Fields, each with a
  few lines from data. Some hint at the secrets.

## Acceptance criteria (from ROADMAP)
- [x] every outdoor area and interior has new detail in its screenshots
- [x] grass and pots drop what their data says
- [x] all four heart pieces can be found
- [x] the map is no bigger than before

## Deliberately not in H12
Lifting and throwing pots, burning grass, critters that react to the hero, day and night, new areas, new quests
(H13).
