# H13 — Quests (plan)

Goal (ROADMAP H13): `QuestRunner`, two or three small villager quests with rewards, a quest log in the pause
menu, and quest progress that survives a save. A new quest must need only a JSON file.

## Design
- **`QuestRunner`** (`core/quests/`, pure) runs every quest in `data/quests/` against the game state:
  - A quest's stage lives in `GameState.quests`, as before.
  - When a quest reaches a stage, the runner applies that stage's `on_enter` effects once. A flag,
    `quest/<id>/entered`, records the stage whose effects were applied. Flags are saved, so a load never repeats a
    reward.
  - The `complete_quest` effect sets the flag `quest/<id>/complete`.
  - Each time flags, items or stages change, the runner checks every active quest's transitions top to bottom.
    The first whose condition is met moves the quest on. It repeats until nothing changes.
  - The runner keeps nothing of its own: everything is in GameState, in what's already saved.
- **`Quests` autoload** owns the runner. It listens for flag, item and stage changes on EventBus, and announces
  "New quest", "Quest updated" and "Quest complete" (`EventBus.quest_announced`) with a sound.
- **One new condition, `quest_status`** (`not_started`, `active`, `complete`), so a villager's dialogue can offer
  a quest only before it starts, without knowing the flag names.
- **Quests start from dialogue** with the existing `set_quest_stage` effect.
- **Three quests**, each a different shape, all data:
  1. **The Lost Shuttle** (fetch): Wenna the weaver lost her shuttle on the far bank of the stream in the North
     Fields. Find it, bring it back: 30 coins. Found before asking, it still counts.
  2. **Eggs for Tilda** (delivery): Farmer Oda's basket of eggs goes to Tilda's shop, then word back to Oda:
     5 bombs.
  3. **Slimes in the South Field** (bounty): Guard Rolf wants all three slimes beaten (the slimes share a
     `clear_flag`): 40 coins and 10 arrows.
- **Quest items** are items of type `quest` (the shuttle, the basket). An item can name its picture with `icon`.
- **Quest log:** a new "Quests" entry in the pause menu lists started quests, active first. The highlighted
  quest shows its journal line and objectives, ticked when done.
- **On screen:** a notice at the top of the screen when a quest starts, moves on or completes. It stays visible
  above the dialogue box.

## Acceptance criteria (from ROADMAP)
- [x] each quest starts, advances and finishes from data alone
- [x] the log shows where each stands
- [x] progress survives a save
- [x] a new quest can be added by writing only a JSON file

## Deliberately not in H13
A bigger quiver or heart pieces as rewards (they need carrying-capacity upgrades and shop changes), quest markers
on a map, failing or abandoning quests, timed quests, a main-story quest (H15).
