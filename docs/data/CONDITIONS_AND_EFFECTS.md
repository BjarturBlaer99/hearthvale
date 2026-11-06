# Condition & effect vocabulary

Shared by quests, dialogue, network nodes and world objects. Adding a new `type` is the only reason
to write new evaluator code. Formal JSON Schemas go next to this file (`*.schema.json`) — write them in M0.

## Conditions
| type | fields | true when |
|---|---|---|
| `flag` | `flag`, `value` | GameState flag equals value (missing flag = false) |
| `water_level` | `district`, `level` | district is at that level |
| `has_item` | `item`, `count` | inventory has ≥ count |
| `reputation_gte` | `faction`, `value` | reputation ≥ value |
| `attribute_gte` | `attribute`, `value` | player attribute ≥ value |
| `quest_stage` | `quest`, `stage` | quest is in that stage |
| `all` / `any` | `of: [conditions]` | logical and / or |
| `not` | `condition` | negation |

## Effects
| type | fields |
|---|---|
| `set_flag` | `flag`, `value` |
| `give_item` / `take_item` | `item`, `count` |
| `reputation` | `faction`, `delta` |
| `approval` | `companion`, `delta` |
| `set_quest_stage` | `quest`, `stage` |
| `complete_quest` | — (current quest) |
| `water_lock` | `district`, `locked` |
| `spawn_npc_group` | `group`, `location` |
