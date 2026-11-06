# Low Tide — Technical Design

Engine: **Godot 4.x (latest stable), typed GDScript, 2D top-down.** Tests: **gdUnit4**. Target: desktop (Windows/Linux/macOS), keyboard+mouse and gamepad.
Rendering: 16×16 tiles, base resolution 480×270 scaled up (integer scaling, `canvas_items` stretch mode, nearest filtering).

## 1. Project layout
```
res://
  autoload/          # singletons (EventBus, GameState, DataRegistry, SaveSystem)
  core/              # pure logic, RefCounted, unit-tested (no Node dependencies)
    water/           # WaterNetwork, WaterSolver, WaterChangeResult
    terrain/         # HeightGrid, TerrainQuery (dry / shallow / deep per cell)
    quests/          # QuestRunner, condition/effect evaluators
    factions/        # Reputation
    inventory/       # Inventory, ItemStack
    dialogue/        # DialogueRunner, check evaluation
  gameplay/          # Node scripts: player, boat, winch, enemies, interactables
  world/
    districts/<id>/  # one scene per district: <id>.tscn
    interiors/       # dive / building interiors
    sea/             # overworld sea map joining districts
  ui/
  data/              # JSON content (see docs/data for schemas + examples)
  tests/             # gdUnit4 tests mirror core/ structure
  addons/gdUnit4/
```

## 2. Autoloads
| Name | Responsibility |
|---|---|
| `EventBus` | Global signals only. No state. e.g. `water_level_changed(district_id, level)`, `quest_updated(quest_id)`, `reputation_changed(faction_id, value)`, `item_added(item_id, count)`, `flag_set(flag, value)` |
| `DataRegistry` | Loads and validates all JSON in `res://data` at startup; read-only lookups by id. Fails loudly (push_error + assert in debug) on invalid data. |
| `GameState` | Owns all persistent state: water levels, flags, quest progress, reputation, inventory, player stats, boat upgrades, companions. `to_dict()` / `from_dict()`. Mutates only through methods that emit `EventBus` signals. |
| `SaveSystem` | Writes `GameState.to_dict()` as JSON to `user://saves/slot_<n>.json` with a `version` field; loads and migrates. |

## 3. Water system (the core mechanic)
**Not fluid simulation.** Two separate parts: the *network* decides each district's water level; the *terrain* decides what that level means for each tile.

### 3.1 Network model (pure)
- **District**: `id`, ordered list of `levels` (most water → least), each with a `water_height` (int), `current_level`, `water_volume_per_step`, `outflows`.
- **Basin**: a sink/source with `capacity` and `stored` (e.g. an empty reservoir, the sea).
- **Node** (pump/sluice/outlet): connects a district to a target (district or basin). Has `state`: `broken | repaired`, and `repair_requires` (conditions).
- **Conservation rule**: lowering a district by one step moves `water_volume_per_step` into the node's target. If the target is a district, its level rises by `ceil(volume / target.water_volume_per_step)` steps, clamped; overflow cascades along that district's outflows. If no valid target has capacity, the change is rejected.

```gdscript
class_name WaterSolver extends RefCounted
func preview(network: WaterNetwork, node_id: StringName, direction: int) -> WaterChangeResult
func apply(network: WaterNetwork, change: WaterChangeResult) -> void
```
`WaterChangeResult` lists every district/basin whose level changes, plus `rejected_reason`. **Preview is mandatory**: the UI shows every consequence before the player confirms (pillar 2).

### 3.2 Terrain model (pure)
- Each district scene has a `TileMapLayer` named `Height` whose tiles carry an integer **custom data layer `height`** (0–7). Visual layers (`Ground`, `Walls`, `Decor`) sit on top. `HeightGrid` is built from `Height` at load and is plain data, so it is testable without scenes.
- `TerrainQuery.cell_kind(cell, water_height) -> DRY | SHALLOW | DEEP` where depth = `water_height - height`: depth ≤ 0 dry, depth = 1 shallow, depth ≥ 2 deep.
- Tiles may carry extra custom data: `climbable` (bool), `ramp` (bool: walk up/down one height freely), `dive_point` (interior scene id).

### 3.3 Presentation (one scene per district, no per-level scenes)
- A `Water` node draws the water: a full-district `TileMapLayer` (or shader on a ColorRect) filled from `TerrainQuery` — shallow tiles light teal, deep tiles dark teal, dry tiles empty. Submerged terrain stays faintly visible underneath (modulate/alpha).
- On `water_level_changed`, `DistrictController`:
  1. recomputes cell kinds,
  2. redraws the `Water` layer (slice: instant with a screen fade; later: tween the water edge),
  3. rebuilds collision (see 3.4) and pathfinding (`AStarGrid2D` solid cells),
  4. shows/hides entities with a `WaterVisibility` component (`visible_when`: list of levels or a condition) — e.g. a sunken shop counter, lurkers trapped in drained pits.
- Objects whose state matters (opened chests, killed bosses) record flags in `GameState`, so changing water never resets progress.

### 3.4 Height & movement rules
- The player and NPCs have a current `height`. Moving onto a neighbour tile:
  - same height or a `ramp` ±1 → walk
  - lower → drop down (short hop animation; small damage if drop ≥ 3)
  - higher → blocked unless `climbable`, then enter `climb` state (stamina drain)
  - shallow → walk at half speed; deep → `swim` state (land enemies cannot follow), or `on_boat`.
- Implement as a movement-validation function in `core/terrain` (pure, tested) used by `PlayerController`; physics collision is generated per district from the same rules for the current height band. Keep it grid-checked rather than relying only on physics shapes.
- Draw order: Y-sort, with higher tiles drawn later for the same row. Use a drop shadow under the player to show height.

## 4. Player, traversal and tools
- `PlayerController` (CharacterBody2D, 8-directional, free movement on a tile grid) with a small explicit state machine: `ground, climb, swim, dive, glide, on_boat, winch_reel`. One script per state.
- Stamina for climb/glide/sprint/dodge; oxygen for dive. Values live in GameState-backed stats.
- **Diving**: interacting at a `dive_point` while swimming loads an interior scene in `dive` mode (oxygen timer, slow movement). The same interior can load in dry mode if the district is drained far enough (declared in data).
- `Boat` (CharacterBody2D, arcade turning and drift): only on deep tiles; board/disembark at adjacent dry or shallow tiles. Sailing off the district edge goes to the sea map. Upgrades read from GameState.
- **Winch**: `ShapeCast2D`/raycast in the aim direction to targets in group `winch_target` with a `WinchTarget` component declaring `mode`: `pull_to_player` (enemies stagger, light objects), `pull_player_to` (anchors — crosses water and gaps), `drag` (heavy machinery along an authored path), `bridge` (debris that snaps into an authored gap socket and becomes walkable). The target decides the behaviour; that keeps puzzles systemic.

## 5. Quests (data-driven)
Quests are JSON (`docs/data/quest.example.json`). A quest is a set of **stages**; each stage has **objectives** and **transitions**.
- **Conditions** (shared by quests, dialogue, nodes and world objects) and **effects**: see `docs/data/CONDITIONS_AND_EFFECTS.md`.
- `QuestRunner` (pure) re-evaluates active quests on any EventBus state signal. New *types* of conditions/effects are the only reason to add code.

## 6. Dialogue
JSON node graph (`docs/data/dialogue.example.json`): nodes with speaker, text, options; options have `conditions`, an optional `check` (`attribute`, `difficulty`), and `effects`. Checks are deterministic (attribute ≥ difficulty), shown as `[Charm 4]`. `DialogueRunner` is pure; UI is a thin view (bottom-of-screen text box, portrait placeholder).

## 7. Factions & companions
- Reputation per faction in GameState, clamped −100..100, thresholds `hostile < -50 <= neutral < 50 <= allied`.
- Companion approval: same mechanism keyed by companion id (`approval` effect). Companions follow the player using `AStarGrid2D` and respect the same height/water rules.

## 8. Combat (slice level)
- `HitBox`/`HurtBox` (Area2D) components, `Health` component, stagger meter, i-frames on dodge.
- Enemy AI: state machine (idle, patrol, chase, attack, staggered) pathing with the district `AStarGrid2D`. Each enemy declares where it can move (`land`, `water`, `both`).
- Weapons and mutations are data items with stats. The slice needs one firearm (projectiles), one melee weapon (arc swing), the winch.

## 9. Save format
```json
{ "version": 1, "water": {"st_aud": "flooded"}, "basins": {"old_reservoir": 0},
  "flags": {}, "quests": {"bitter_medicine": "stage_id"}, "reputation": {},
  "inventory": [{"id": "fever_medicine", "count": 1}], "player": {"district": "st_aud", "cell": [12, 8], "height": 2},
  "boat": {} }
```
Bump `version` on breaking changes and add a migration function in `SaveSystem`.

## 10. Testing
- Every class in `core/` has gdUnit4 tests. Required for the slice: water solver (conservation, cascades, rejection, preview == apply), terrain queries (dry/shallow/deep at each level, movement rules for climb/drop/ramp), quest runner (each resolution path of Bitter Medicine reachable), dialogue checks, reputation clamps, save/load round trip.
- Data validation test: every JSON in `data/` loads through `DataRegistry` and all cross-references (item, faction, district, interior ids) resolve. Each district's level `water_height` values must be strictly decreasing.

## 11. Performance budget (slice)
60 fps on integrated graphics. Water level change (redraw + collision + pathfinding rebuild) < 200 ms for a 128×128 district. No world streaming until after the slice; districts load as separate scenes.
