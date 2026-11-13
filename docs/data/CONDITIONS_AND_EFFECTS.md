# Condition & effect vocabulary

Shared by quests, dialogue, doors and world objects. Adding a new `type` is the only reason to write new
evaluator code. Formal JSON Schemas sit next to this file (`*.schema.json`); DataRegistry is the authoritative
check and also resolves ids. `ConditionEvaluator` (`core/quests/`) evaluates conditions; `EffectApplier` applies
effects (`complete_quest` only means something in a quest stage's `on_enter`, where `QuestRunner` applies it).

## Conditions
| type | fields | true when |
|---|---|---|
| `flag` | `flag`, `value` | GameState flag equals value (missing flag = false) |
| `has_item` | `item`, `count` | inventory has ≥ count |
| `quest_stage` | `quest`, `stage` | quest is in that stage |
| `quest_status` | `quest`, `status` | quest is `not_started`, `active` or `complete` |
| `all` / `any` | `of: [conditions]` | logical and / or |
| `not` | `condition` | negation |

## Effects
| type | fields |
|---|---|
| `set_flag` | `flag`, `value` |
| `give_item` / `take_item` | `item`, `count` |
| `set_quest_stage` | `quest`, `stage` |
| `complete_quest` | — (the quest whose stage it's in; finishes it) |
| `sleep` | — (the hero sleeps until morning: the next day begins, hearts and energy are full; the area saves the game) |
| `shop` | `shop` (a shop id from `data/shops`), `mode` (`buy` or `sell`: the list it opens on). The shop's buy-and-sell list opens when the conversation is over |

Combat and dungeon milestones will add types (e.g. `heal`, `open_door`) when they need them.
