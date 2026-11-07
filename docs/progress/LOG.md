# Progress log

Append one entry per milestone: date, milestone, what was built, acceptance criteria status, known issues, next step.

## 2026-11-06 — M0 Project skeleton — done

**Built**
- Godot 4.7.2 project: 480×270 base viewport, `canvas_items` stretch, integer scaling, nearest filter, GL Compatibility. The window opens at 1440×810 (3×).
- Folder layout from TECH_DESIGN §1, plus `world/dev/` for dev scenes. gdUnit4 6.2.3 in `addons/`.
- Autoloads: `EventBus` (the five §2 signals), `GameState` (§9 save shape; mutators emit on EventBus; reputation clamped), `SaveSystem` (versioned `user://saves/slot_<n>.json`, migration hook), `DataRegistry`.
- `DataRegistry` loads `res://data/<kind>/`, checks required fields, strictly decreasing water heights, valid start levels, and resolves every cross-reference: outflows, node targets, interior levels, companion factions, ids inside conditions/effects, and quest/dialogue graph targets. Errors are collected (testable) and assert in debug.
- Seed content is the `docs/data` examples split by kind. No new content written.
- JSON Schemas for the condition/effect vocabulary and the five file kinds in `docs/data/`.
- `world/dev/m0_smoke.tscn` (main scene) lists everything that loaded.
- 16 tests in 3 suites (`tests/autoload/`), including bad-data fixtures in `tests/fixtures/`.

**Acceptance criteria**
- [x] Headless test command runs green: 16/16, exit code 0.
- [x] `godot --path .` opens a test scene: verified windowed (frame captured) and headless.
- [x] `docs/progress/LOG.md` exists.

**Known issues / notes**
- Headless tests need `--ignoreHeadlessMode` (CLAUDE.md updated). Future tests that use InputEvents must run windowed.
- ~~Line continuations break test discovery~~ Wrong: corrected in M1. The first run stopped after 2 of 8 tests because gdUnit4's CLI is fail-fast by default.
- The JSON Schemas are syntax-checked but not machine-validated against the data (no `jsonschema` installed). DataRegistry is authoritative.
- The `godot` shim lives in the winget package folder, so `winget upgrade` will remove it.
- Not built, by design: water solver, height grid, any map, input map.

**Next:** M1, water and terrain logic (WaterNetwork / WaterSolver / HeightGrid / TerrainQuery + tests).

## 2026-11-06 — M1 Water & terrain logic — done

**Built**
- `core/water/`: `WaterNetwork` (districts, basins and nodes; start state from data; get/set state; copy; `total_water()`), `WaterChangeResult` (affected districts and basins in flow order with from/to values, `rejected_reason`, `level_changes()`, `describe()` for the M4 preview), and `WaterSolver` (`preview()` never mutates; `apply()` writes exactly the preview and refuses rejected or stale changes).
- Conservation model: a receiving district accumulates `pending` water and rises a level per full step *of its own* volume. Overflow cascades along outflows in order, each district at most once, never back into the source. Raising pulls one step back from the node's target. TECH_DESIGN §3.1 updated, because its old `ceil` rule created water and contradicted the worked example.
- `core/terrain/`: `HeightGrid` (heights 0–7 plus climbable/ramp/dive-point flags; built from text rows for now) and `TerrainQuery` (DRY/SHALLOW/DEEP; `check_move()` returns a `MoveResult`: BLOCKED/WALK/CLIMB/DROP/SWIM, drop height, damaging at 3+, half speed in shallows).
- `GameState`: `water_pending`, `network_nodes`, `new_game()`, `water_network()` (a fresh view, so it can't drift) and `apply_water_change()` (emits `water_level_changed` per level change, in flow order). New save keys.
- `DataRegistry`: whole-number volumes and capacities, `start_stored` ≤ capacity, no district/basin id collisions, no self-outflow, no node targeting its own district; adds `entries()`.
- The dev smoke scene (renamed `world/dev/dev_smoke.tscn`) shows the start water state and what each node would do if repaired.
- 57 tests in 7 suites (41 new).

**Acceptance criteria**: tests cover
- [x] Conservation: every solver operation checks total water, plus a 300-step seeded random walk (3 districts, 1 basin, 3 nodes) that checks totals and invariants after each step.
- [x] Cascade into Greenterrace: via the pump, step 1 leaves 50 pending and step 2 floods it. Also an ordered cascade along outflows (basin first, then the next district).
- [x] Basin capacity: Old Reservoir fills to exactly 100; an 80-unit basin refuses the second 50.
- [x] Rejection with reason: broken node, unknown node, bad direction, lowest/highest level, nowhere for the water to go, target lacks water, no backflow.
- [x] Preview equals apply: for every operation, preview leaves the network untouched and apply lands on exactly the previewed state. Stale previews are refused.
- [x] Dry/shallow/deep per level: St. Aud's three levels against terrain heights 0–5.
- [x] Climb/drop/ramp rules: 10 movement tests.
- [x] Save/load round trip of water state: through a real save slot, and the loaded network is live.

Mutation check: doubling absorbed water in the solver fails 7 of 13 solver tests (1,201 assertion failures).

**Known issues / notes**
- **Correction to M0:** gdUnit4's CLI is fail-fast by default and stops at the first failing test. That, not `\` line continuations, is why M0's first run showed only 2 of 8 DataRegistry tests (a probe suite with continuations discovers fine). The documented test command now passes `--continue`, and CLAUDE.md is fixed.
- `HeightGrid` is built from text rows only; the TileMapLayer builder comes with the first district (M2).
- Node repair (conditions → repaired) is M4; tests set node states directly.
- The `water_lock` effect is not implemented (M9).
- Pending water emits no signal; add one if the UI needs to show build-up live.

**Next:** M2, player and district greybox.

## 2026-11-07 — M2 Player & district greybox — done

**Built**
- `core/player/`: `PlayerMotor` plus `PlayerGroundState`, `PlayerSwimState` and `PlayerClimbState` (one script per state). Pure, grid-checked movement: 8-direction input with equal diagonal speed, sprint and climb on stamina, drops, half speed in shallows, swimming at the surface, and wall sliding. Rising or falling water switches walking/swimming by itself.
- `gameplay/player/`: a thin `PlayerController` (CharacterBody2D) and greybox body (shadow, ripple when swimming, facing marker, hop on drops), with the camera clamped to the district.
- `world/districts/st_aud/st_aud.tscn` (now the main scene): a 64×64 greybox St. Aud. It has a `Height` TileMapLayer with `height`/`climbable`/`ramp`/`dive_point` tile data, cliff-edge shading, and a translucent `Water` layer redrawn from the water height (about 4 ms per redraw). Three points of interest, the player and a HUD (water, activity, level, cell, stamina, prompts, messages, redraw fade).
- `DistrictController`, `HeightGridBuilder`, `HeightShading`, `PointOfInterest`, `DistrictHud`.
- Tools: `tools/setup_input_map.gd` (physical-key + gamepad input map), `tools/greybox/` (tile atlas → TileSet → layout bake) and `tools/capture_st_aud.gd` (review screenshots at each water level).
- GameState: `update_player()`; `set_water_level()` clears pending water so debug cycling keeps the network valid.
- 90 tests in 12 suites (33 new). README has the controls.

**Acceptance criteria**
- [x] Each water level changes where you can walk: a search of the real Height layer from the spawn, using the player's movement rules, gives a different walkable area at each level. The scene test redraws the water at every level and checks every tile against the terrain (3,364 deep cells flooded, 3,098 at waist, 0 drained).
- [x] Something is reachable only at specific levels: rooftop door **flooded only** (swim to the wing roof), clinic balcony hatch **waist only**, subway entrance **drained only**. A mutation check (a staircase baked up to the wing roof) fails this test with "RooftopDoor at waist/drained: usable=true".
- [x] State survives level changes: cycling through all three levels keeps the player's position, stamina and flags, and leaves a door marked as opened. The water lifts a street-level player into swimming and strands a swimmer on the street when drained.

Visual check: screenshots at each level (`tools/capture_st_aud.gd`) show the gated places, prompts, translucent water over submerged terrain, and the HUD.

**Known issues / notes**
- Fall damage is reported, not applied (health is M7). Physics collision, pathfinding and `WaterVisibility` are deferred until something needs them.
- Movement numbers are first guesses; tune by playing.
- Points of interest only mark progress for now: the interiors behind them are M5.
- Not yet tested by hand with a real keyboard or gamepad: input wiring is verified by the input-map test and by driving the move actions in the scene test.
- `tools/` scripts can't reference autoload-using classes at compile time; see CLAUDE.md.

**Next:** M3, the boat and the sea map.

## 2026-11-07 — Player sprite (between M2 and M3, at the user's request)
- The placeholder polygon is replaced by an original Zelda-style 16×24 pixel-art hero: green hooded salvager's coat, tan trousers, boots, and the Network Key glowing on the belt. 9 frames: down/up/side × idle and two walk steps, with the side row flipped for right.
- Art lives as ASCII in `tools/art/make_player_sprite.gd`, which writes `gameplay/player/player_sheet.png` (and an optional 8× preview).
- `PlayerAnimator` (pure, 7 tests) handles facing, the walk cycle by distance, the back view while climbing, and head-and-shoulders above a ripple while swimming. Sprinting and wading animate at the right pace automatically.
- 97 tests green. Checked in-game: standing, swimming and side view.
- Known: the sprite is 16 px wide but movement still keeps the player's centre 4 px from walls, so the hood can overlap a wall by about 3 px sideways. There's no Y-sorting yet, so the player draws over everything.
