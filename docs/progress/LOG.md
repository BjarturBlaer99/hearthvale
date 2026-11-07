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

## 2026-11-07 — M3 Boat & sea map — done

**Built**
- `core/boat/`: `BoatMotor` (pure arcade sailing: steer toward the input, thrust along the heading, sideways drift; floats only on deep cells; reports the map edge) and `BoatRules` (where it floats, nearest deep cell, where a rider can land, who can board).
- Player `on_boat` state (`PlayerBoatState`, `PlayerMotor.board/ride/disembark`); the rider is drawn head-and-shoulders in the hull, facing the boat's heading.
- `gameplay/boat/`: `BoatController` and a greybox hull with a wake.
- **Sea map** `world/sea/sea.tscn` (48×30, fixed water height 4): three islands ringed by shallows, a `SeaPort` approach for each, and the boat always under you.
- **Districts:** Spire Nine (32×32 settlement platform and spire, one water level, added to the data) and Greenterrace (32×32 terraced roofs and quay, dry/flooded). St. Aud gained a pier. Every district has a **Harbour** (dry at every level) and a **Mooring**.
- `DistrictController`: boarding, going ashore, sailing off any edge to the sea, arriving from the sea (sail in if the mooring is deep, otherwise come ashore at the harbour), stranding on water changes (nearest deep cell, or the boat waits at sea off the harbour), and HUD prompts. `SeaController` for the sea.
- GameState travel state (`boat`, `player.on_boat/arriving/came_from`, `set_boat`, `begin_voyage`); maps rebuild from it on load.
- `tools/greybox/build_maps.gd` bakes all four maps; `tools/capture_world.gd` screenshots travel situations.
- 132 tests in 17 suites (35 new). README covers the boat.

**Acceptance criteria**
- [x] You can sail between all three: on the real sea map every port is reachable from every other port's exit, and travel tests go district → sea (sailing off the edge) → district (sailing into a port) through the real controllers, for all three districts.
- [x] After a water change the boat can reach different places, or gets moved:
  - St. Aud: 3,358 sailable cells flooded vs 3,092 at waist (rubble and low roofs drop out), none drained.
  - Greenterrace: 744 flooded, none dry.
  - At waist, a boat on the rubble moves to the nearest deep cell with its rider. At drained, with no deep water left, it waits at sea off the harbour and you board it from there.

Mutation check: letting the boat float on shallow water fails 8 tests (16 assertions) across the boat motor, rules, maps and travel suites.

Visual check (`tools/capture_world.gd`): open sea with labelled approaches; the boat at St. Aud's pier; Greenterrace dry (ashore at the quay, "Walk out to the boat") vs flooded (sailing in).

**Known issues / notes**
- Scene changes go through `change_scene_to_file` with no transition effect yet.
- Leaving a district by any edge returns you to its sea port, even the edge away from the sea.
- The boat has no collision with the player or NPCs (no NPCs yet); physics shapes wait for M7.
- No boat upgrades, deck map or storage yet (M10). Spire Nine and Greenterrace are geometry only: no settlement content.
- Sailing hasn't been tried by hand with a real keyboard or gamepad; the tunables are first guesses.

**Next:** M4, the Network Key and the consequence preview.

## 2026-11-07 — M4 Network Key & consequence preview — done

**Built**
- **Pump in the world:** a `NetworkNodeMarker` for `st_aud_pump` on St. Aud's lookout tower (red wheel when broken, teal when working). Its behaviour comes from `data/water/spillway.json`.
- **Repair:** `ConditionEvaluator` (pure, the whole condition vocabulary) and `GameState.repair_network_node()` / `unmet_repair_requirements()`. Requirements are checked, items used up, and `EventBus.network_node_repaired` emitted. The message names what's missing ("It needs: Pump Valve").
- **The valve:** an `ItemPickup` on Spire Nine's platform, remembered by a flag. The HUD shows "Carrying: ...".
- **Preview:** `ui/network_panel` plus `RegionMap`. Up/Down chooses Raise or Lower; the text and the mini-map show every consequence (before/after gauges, pipes, a flow arrow, amber for changes, red for floods). Rejections show their reason and can't be confirmed. E applies through `GameState.apply_water_change()`, Esc cancels, and the game pauses while it's open.
- **Data:** optional `"map": [x, y]` on districts and basins, validated and added to the schema.
- 143 tests in 19 suites (11 new). The README explains the pump.

**Acceptance criteria**
- [x] Draining St. Aud from the pump visibly floods Greenterrace, and the preview warned about it first. Tested end to end through the real scenes:
  1. Broken without the valve.
  2. Repaired with it (the valve is used up).
  3. The first preview lists *St. Aud Hospital: flooded -> waist* and *Greenterrace: water rising, 50 of 100*.
  4. The second preview warns *Greenterrace: dry -> flooded*, with Greenterrace outlined red on the mini-map, while Greenterrace is still dry. After confirming, Greenterrace is flooded.
  5. The Greenterrace scene goes from 0 to 744 deep-water cells.

Mutation check: with no red outline for flooding districts, the acceptance test fails.

Visual check (`tools/capture_world.gd`, shots 7–8): both pump previews with the mini-map, gauges, arrow and legend.

**Known issues / notes**
- Only the pump is in the world; the third outlet and its tunnel come in M9.
- The preview is a pause menu: no animation of the water changing yet (TECH_DESIGN §3.3 allows instant + fade for the slice).
- The Network Key isn't an item and has no upgrades.
- I haven't played it by hand with a real keyboard or gamepad (Up/Down/E/Esc in the panel).

**Next:** M5, diving and interiors.
