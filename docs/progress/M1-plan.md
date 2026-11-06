# M1 — Water & terrain logic (plan)

Goal (ROADMAP M1): the pure logic behind "changing the water level changes the map", fully
unit-tested, with no visuals.

## A conflict in the docs, and how M1 resolves it
TECH_DESIGN §3.1 says a target district "rises by `ceil(volume / target.water_volume_per_step)` steps".
The worked example in `water_network.example.json` says draining St. Aud fully (2 × 50 units) via the
pump raises Greenterrace (100 per step) by **exactly one** step. With `ceil`, the *first* 50 units
already raise it a full step (50 units in, 100 units of rise), which creates water, breaks the
"conservation" acceptance test, and leaves the second step with nowhere to go.

**Resolution:** a district that receives water keeps it as `pending` and rises one level each time a
full `water_volume_per_step` of its own has arrived. Total water is conserved exactly. This matches
the worked example step for step, and the preview can show the build-up ("50 of 100 toward
flooding"), which serves pillar 2. TECH_DESIGN §3.1 is updated and the decision is recorded.

## Steps
1. **`core/water/WaterNetwork`**: districts (levels, water heights, volume per step, outflows,
   current level, pending), basins (capacity, stored), nodes (district, target, broken/repaired).
   Built from DataRegistry entries in the start state; `get_state()` / `set_state()` in GameState's
   shape; `copy()`; `total_water()`.
2. **`core/water/WaterChangeResult`**: affected districts and basins in flow order with from/to
   values, `rejected_reason`, `level_changes()`, `describe()` (text for the M4 preview).
3. **`core/water/WaterSolver`**: `preview(network, node_id, direction)` simulates on a copy (never
   mutates). LOWER sends one step into the node's target, which absorbs it and then cascades along
   outflows, in order. Each district is visited at most once and the water never flows back into the
   source. RAISE pulls one step back from the node's direct target. Reject with a reason when: the
   node is unknown or broken, the district is already at its lowest/highest level, nothing downstream
   has room, or the target lacks the water. `apply()` writes the preview's end state, and refuses
   rejected or stale changes.
4. **`core/terrain/HeightGrid`**: heights 0–7 plus `climbable`, `ramp` and `dive_point` per cell.
   Pure. M1 builds it from text rows; the TileMapLayer builder comes with the first district (M2).
5. **`core/terrain/TerrainQuery` + `MoveResult`**: `cell_kind(cell, water_height)` gives DRY /
   SHALLOW / DEEP. `check_move(from, to, water_height)` gives BLOCKED / WALK / CLIMB / DROP / SWIM, with
   the drop height, a damaging flag (drop ≥ 3 onto ground) and a speed scale (0.5 in shallows). A
   swimmer's level is the water surface.
6. **DataRegistry**: volumes and capacities must be whole numbers (exact conservation),
   `start_stored ≤ capacity`, no district/basin id collisions, no outflow into itself, no node targeting
   its own district. Adds `entries(collection)`.
7. **GameState**: adds `water_pending` and `network_nodes`, plus `new_game()` (seeds water from data),
   `water_network()` (fresh view built from data and state, so it can't drift), and
   `apply_water_change(change)`, which writes the state and emits `water_level_changed` per district
   whose level changed. Save v1 gains two keys (non-breaking, no saves exist).
8. **Tests**: everything in "Done when", plus a seeded random walk asserting conservation and
   invariants after every operation.
9. **Smoke scene**: shows the start water state and what each node would do if repaired.

## Acceptance criteria (from ROADMAP)
Tests cover:
- [x] conservation
- [x] cascade into Greenterrace
- [x] basin capacity
- [x] rejection with reason
- [x] preview equals apply
- [x] dry/shallow/deep classification per level
- [x] climb/drop/ramp rules
- [x] save/load round trip of water state

## Deliberately not in M1
Water visuals, collision, pathfinding, node repair flow (M4), `water_lock` effect (M9), boat rules (M3).
