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
| `days_since` | `flag`, `days` | the flag is `true` and at least `days` dawns (a whole number, 1 or more) have passed since it came true. Not met on the day itself. A flag that came true before days were kept (a save older than version 4) counts as long ago |
| `friendship` | `villager`, `marks` | the hero has at least `marks` marks of friendship with the villager (a villager id from `data/villagers`; `marks` from 1 to the most there are) |
| `all` / `any` | `of: [conditions]` | logical and / or |
| `not` | `condition` | negation |

## Effects
| type | fields |
|---|---|
| `set_flag` | `flag`, `value` |
| `give_item` / `take_item` | `item`, `count` (what a full pack can't take of a `give_item` is laid at the hero's feet, never lost) |
| `set_quest_stage` | `quest`, `stage` |
| `complete_quest` | — (the quest whose stage it's in; finishes it) |
| `sleep` | — (the hero sleeps until morning: the next day begins, hearts and energy are full; the area saves the game) |
| `gift` | `villager` (a villager id from `data/villagers`). The list of what the hero can give them opens when the conversation is over. The game adds an answer with this effect to a villager's conversation by itself; a file needs it only for something out of the ordinary |
| `teach_recipe` | `recipe` (a recipe id from `data/recipes` that is marked `"taught": true`). The hero knows it from then on, and the hearth lists it |
| `practise` | `skill`, `deed` (a skill and one of its deeds in `data/rules/skills.json`, e.g. `cooking` and `dish`). The skill gains that deed's points |
| `travel` | `area`, `entry` (an area id and the name of one of its entry points). The hero is taken there when the conversation is over: the mine's lift. No file in `data/dialogue` uses it yet; the lift's conversation is built by the game |
| `light_furnace` | `item`, `count` (an item id and how many of it the load will make). The furnace in the hero's home is lit today and holds that from the next morning. It takes nothing itself: the ore and the coal go by `take_item` effects beside it. No file in `data/dialogue` uses it; the furnace's conversation is built by the game |
| `empty_furnace` | — (what the furnace made is given to the hero, as `give_item` gives: what a full pack can't take is laid at his feet). Built into the furnace's conversation by the game |
| `shop` | `shop` (a shop id from `data/shops`), `mode` (`buy` or `sell`: the list it opens on). The shop's buy-and-sell list opens when the conversation is over |

Combat and dungeon milestones will add types (e.g. `heal`, `open_door`) when they need them.
