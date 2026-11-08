# H1 — Village life (plan)

Goal (ROADMAP H1): doors into house interiors and back, villagers with data-driven dialogue, signs to read.

## Design
- **Doors and areas.** A house door is a walkable `door` tile set into the house's wall. An `AreaExit` on it
  names a target area and an entry point; walking onto it calls `GameState.go_to(area, entry)` and changes
  scene. Each area has `Entries` (markers named by id, rotated to face the way the hero should face on
  arrival). The arriving `AreaController` places the hero at the named entry and the screen flashes. A
  house's exit is a doormat in its bottom wall, leading back to the entry just outside its own door, so you
  come out where you went in.
- **Interiors** are small areas (12×9): wooden floor, walls, furniture, a doormat. The camera centres a room
  smaller than the screen on a dark background.
- **Talking.** `Talkable` (base class) → `Villager` and `Sign`. Each names a dialogue in `data/dialogue`, blocks
  its cell, and is used by facing it and pressing E. `TerrainQuery` gains dynamic **blocked cells** (for
  villagers now, enemies later).
- **Dialogue** (TECH_DESIGN §7):
  - `DialogueRunner` (`core/dialogue/`, pure) plays a conversation: the current node's speaker and text, the
    options whose conditions are met (`ConditionEvaluator`), and choosing one (apply its effects, go to `next`,
    `null` ends).
  - `EffectApplier` (`core/quests/`) applies effects to GameState (or a stand-in in tests).
  - An optional `speakers` map in each dialogue file gives display names.
  - `DialogueBox` (`ui/`) shows the speaker, text and a cursor over the options; the hero stands still while
    it's open (no tree pause: nothing else moves yet).
- **Content** (just enough for the milestone):
  - **Elder Bram** in the elder's house, with a choice that sets `promised_elder_keep`. On a later visit a
    different option appears.
  - **A weaver** in the second house.
  - **A welcome sign** in the square.
- **Tiles:** two new atlas rows: walkable door, floor, rug and doormat; solid table, bed, shelf, barrel and
  inner wall.

## Acceptance criteria (from ROADMAP)
- [x] you can enter two houses and come out the same door
- [x] a villager's dialogue (with a choice that sets a flag) plays from data
- [x] the flag survives leaving the area

## Deliberately not in H1
The sword and combat (H2), quests running (QuestRunner), shops, a typewriter text effect, NPCs that walk around,
locked doors.
