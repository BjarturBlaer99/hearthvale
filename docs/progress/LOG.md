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

## 2026-11-07 — Pivot to Hearthvale · H0 Land reset — done

At the user's request the game changes from a water-level RPG (Low Tide) to **Hearthvale**, a land-based
*A Link to the Past*-style action-adventure: a village start, dungeons, enemies, puzzles, multiple weapons and
hearts. The finished water version (M4 included) is committed on the **`water-version`** branch; this work is on
`hearthvale`, branched from it.

**Built / changed**
- **Removed:** the water network and solver, boat, sea map, Network Key, swimming/climbing/boat states, stamina and sprint, the three flooded districts, their data, tests and tools.
- **Terrain:** land-only rules. Stairs bridge one level, ledges are one-way hops down from any height, solid tiles block. `HeightGrid` has `solid`/`ramp` flags.
- **Hero:** `PlayerMotor` has just the ground state; the sprite and animator are kept (no swim/climb poses).
- **Hearts:** GameState `hearts_max` + `health` (half hearts), `damage`/`heal`/`add_heart_container`, `EventBus.health_changed`, and a `HeartsBar` on the new `AreaHud`.
- **Data:** items/quests/dialogue only; a trimmed condition vocabulary; starting items (Wooden Sword, Small Key, Coin).
- **Hearthvale village greybox** (48×36), now the main scene: north rise with chapel and stairs; east meadow with a one-way ledge; four houses; roads; a well; a fenced field; a pond; woods with the south road leading out.
- **Medieval greybox atlas;** `AreaController`; `tools/capture.gd`; the input map cleaned up (move + interact).
- **Docs** rewritten: GDD, ROADMAP (H0–H9), TECH_DESIGN, CLAUDE.md, README, data examples and schemas.
- 58 tests in 11 suites.

**Acceptance criteria**
- [x] Tests green: 58/58.
- [x] The game starts in the village with 3 hearts: scene test plus screenshot.
- [x] Stairs and ledges work, and buildings are solid: the village layout test (1,231 cells reachable from the square) and screenshots.

**Known issues / notes**
- Houses have no doors yet (H1). No combat yet, so hearts only change in tests (H2).
- Solid tiles have a meadow-green background, so trees on the rise sit on slightly darker grass.
- Not yet played by hand after the pivot.

**Next:** H1, village life (house interiors, villagers, dialogue).

## 2026-11-08 — H1 Village life — done

**Built**
- **Doors and interiors:** door tiles in two village houses and two interiors: Elder Bram's house and Wenna's house. These are 11×9 rooms with log walls, a hearth, shelves, a bed, a rug and barrels. `AreaExit` takes the hero to a named entry point, and `GameState.go_to` records the target area and entry. The arriving `AreaController` places the hero at the `Entries` marker, facing the way it points, and flashes the screen. Rooms are centred on screen.
- **Dialogue:**
  - `DialogueRunner` (`core/dialogue/`, pure) and `EffectApplier` (`core/quests/`).
  - `DialogueBox` in the HUD: speaker, text, a cursor over the answers, "[E]" when there are none.
  - `Talkable` → `Villager` / `Signpost`, which occupy their cell.
  - Interact picks up what's underfoot, else talks to whatever the hero faces. The HUD prompt says what E will do.
- **Content:** `data/dialogue/` has `elder_bram`, `wenna_weaver` and `sign_welcome`. An optional `speakers` map in dialogue files is validated by DataRegistry and covered by the schema.
- **Tiles:** two new atlas rows (walkable door/floor/rug/doormat; solid inner wall/table/bed/shelf/barrel/hearth). `build_maps.gd` bakes the houses, with an optional base kind per map.
- **Look:** areas are y-sorted; villagers and signs are drawn feet-mid-cell like the hero.
- 80 tests in 14 suites (+22). New: `dialogue_runner_test` (runner and effects), `doors_test`, `village_life_test`, plus additions to the terrain, GameState, DataRegistry and village suites.

**Acceptance criteria**
- [x] You can enter two houses and come out the same door. `doors_test` walks the hero up into each door, checks the interior's arrival cell and facing, walks out over the doormat, and checks they stand outside that same door facing away. It also checks every exit leads to a real entry point on open ground.
- [x] A villager's dialogue, with a choice that sets a flag, plays from data. `village_life_test` checks Bram's name, text and answers against `elder_bram.json`; "I'll keep watch." sets `promised_elder_keep`, and talking again shows the new answer.
- [x] The flag survives leaving the area. The same suite walks out to the village, through a JSON save and load, into Wenna's house (her extra answer appears), and back to Bram, who remembers.
- Mutation checks: five deliberate bugs, each caught by the expected test, files restored byte for byte:
  - arrival ignores the entry
  - a doormat pointing at the wrong door
  - `set_flag` doing nothing
  - option conditions ignored
  - occupied cells ignored
- Visual check (`tools/capture.gd`, 9 shots): doors in the village, reading the sign, both interiors, and talking to Bram.

**Known issues / notes**
- The other two village houses and the chapel have no doors yet.
- Villagers always face down and don't turn to the hero.
- Text appears all at once; long text isn't paged (the box fits about three lines plus four answers).
- The dialogue box covers the bottom of a room. That's fine for these rooms, but worth watching as rooms grow.
- Played by hand on 2026-11-08: walking through doors, talking, the answer cursor and the flag all feel right.

**Next:** H2, sword and hearts.

## 2026-11-08 — H2 Sword & hearts — done

**Built**
- **Combat rules** (`core/combat/`, pure): `CombatRules` covers sword-arc and circle contact, knockback away from the blow, choosing the strongest held sword from data, and weapon stats with defaults. `Hit` holds damage, push and source.
- **Hero states:** `attack` (stands still for the swing), `hurt` (knockback through the terrain rules) and `dead`, plus 1 s of invincibility (the sprite blinks; tinted when hurt or down).
- **HitBox / HurtBox** (`gameplay/combat/`) on `hero` and `enemy` teams. The area resolves contacts in code every physics frame. `Sword` is an arc HitBox drawn as a blade sweeping 120°, behind the hero when they face up.
- **Attack action:** Space / J / gamepad X, via `tools/setup_input_map.gd`. Wooden Sword stats in `data/items/items.json` (damage 2, knockback 40, cooldown 0.3).
- **Death and respawn:** at zero hearts the hero lies still for 1 s, then returns to the area entrance (where they arrived) with full hearts.
- **Training yard** in the village's fenced field: the Wooden Sword pickup, a training dummy (wobbles and flashes, blocks its cell), three brambles, and a recovery heart (+1, back each visit).
- 97 tests in 16 suites (+17). New: `combat_rules_test` and `combat_test` (village); additions to the motor and input-map suites.

**Acceptance criteria**
- [x] The sword hits the dummy only in front of the hero. `combat_test` swings from seven spots: ahead, beside and behind, facing toward and away, and out of reach. Each swing lands exactly once or not at all.
- [x] Touching a hazard costs half a heart with knockback and invincibility frames. The hero walks into the brambles: 6 → 5 half hearts, pushed back about 32 px. Walking straight back in costs nothing while invincible, and the thorns bite again (→ 4) once it wears off.
- [x] At zero hearts the hero respawns at the area entrance with full hearts. With one half heart left, the brambles knock the hero down: they lie still, can't swing, and after the delay are back at the spawn with 3 hearts. A second test enters the village through the elder's door and respawns at that door.
- Mutation checks: six deliberate bugs, each caught by the expected test, files restored byte for byte:
  - the arc check ignored
  - the sword hitting every frame
  - no invincibility
  - no knockback
  - respawning at the spawn instead of the entrance
  - no refill on respawn
- Visual check (`tools/capture.gd`, 11 shots): the training yard, and a swing from the side landing on the dummy as it flashes.

**Known issues / notes**
- The hero sprite has no attack frames; the blade is drawn in code. Facing up, it's mostly hidden behind the hero.
- Respawning re-places the hero in the same scene; nothing else resets (there's nothing to reset until enemies, H3).
- No sound, no game-over screen, no damage numbers (by design: damage is shown in hearts).
- Recovery hearts can be farmed by walking out and back in. That's fine for now, as hearts will drop from enemies.
- Played by hand on 2026-11-08: the swing, knockback, invincibility blinking and respawn all feel right.

**Next:** H3, enemies.

## 2026-11-08 — H3 Enemies — done

**Built**
- **Enemy data:** `data/enemies/` has `slime`, `goblin_archer` and `bat`, with `docs/data/enemy.schema.json` and an example. DataRegistry validates the behaviour id, the numbers, drop types and weights, and item references; a bad fixture checks the errors.
- **Shared movement:** `GridBody` (the hero's grid movement, now shared). Enemies keep to their level; bats fly over heights but not solid tiles (`TerrainQuery.check_flight`).
- **Brains** (`core/enemies/`, pure, seeded): `EnemyBrain` with `HopperBrain`, `ArcherBrain` and `FlierBrain`, made by `EnemyBrains` from the behaviour id. `DropTable` rolls weighted drops.
- **Nodes:**
  - `Enemy`: placeholder art per behaviour, flashing when hit and a poof on death; a HurtBox, and a contact HitBox that hurts on touch.
  - `Arrow`, and `ItemDrop` (coins by touch).
  - The area sets enemies up and collects touch pickups.
- **South Field:** a 40×28 greybox reached by the village's south road. It has slimes in the meadow (with a pond), a goblin archer on a plateau with stairs and a ledge all round, and bats in a stone ruin.
- 115 tests in 18 suites (+18). New: `enemy_brain_test` (behaviours, terrain rules, hits, drop table) and `south_field_test`; additions to the DataRegistry and doors suites.

**Acceptance criteria**
- [x] Each enemy patrols, notices, attacks and can be beaten.
  - Brain tests: a slime wanders near home and never chases with nobody around, then notices, hops after the hero and lunges, and gives up when they leave. An archer backs off when crowded, lines up, draws its bow for at least 0.4 s, shoots along the line, and waits out its cooldown. A bat rests until the hero comes near, then zigzags in and swoops.
  - In the field, the goblin shoots by itself and its arrow costs half a heart; touching a slime costs half a heart; the sword beats a slime and a bat in one hit and the goblin in two.
- [x] Drops follow data. Each kind is beaten with a chosen roll, and what it leaves matches its data's table: the slime's coin, the goblin's three coins, nothing from the bat. The coins land in the inventory when walked over. Drop-table tests check the weights at the boundaries.
- [x] Enemies respect cliffs, ledges and solid tiles. For slime and archer, on small grids: they never climb a cliff, hop down a ledge or pass a solid tile, even while chasing the hero just beyond. A bat crosses a height-3 ridge but not a solid wall. In the field over 12 s of play, no enemy enters a solid tile, walkers never change level, and the goblin is still on its plateau with the hero waiting below. Arrows stop in solid tiles.
- Mutation checks: six deliberate bugs, each caught, files restored byte for byte:
  - enemies hopping down ledges
  - bats flying through walls
  - drops ignoring the table
  - health not from data
  - no draw before shooting
  - enemies never noticing

  "No draw" first slipped through: the test compared against the constant it was testing. It now requires a visible tell of at least 0.4 s.
- Two test mistakes found and fixed along the way:
  - A slime needs over 2 s to cover four tiles.
  - The slime's and the goblin's coins land on the same spot when both are beaten there.

  One real fix: the archer used to shoot point-blank; it now backs off to its range first.
- Visual check (`tools/capture.gd`, 14 shots): slimes in the meadow, the goblin on its plateau with an arrow in flight, and a bat resting in the ruin while another flies.

**Known issues / notes**
- No pathfinding: enemies head straight for the hero and can get stuck behind rocks or ponds (fine for this greybox; revisit if dungeon rooms need it).
- Arrows fly only in four directions, and the sword doesn't deflect them.
- Enemies have no sprites or sounds yet. Drops don't time out.
- Bats ignore occupied cells (villagers, the dummy); there are none in the field.
- Played by hand on 2026-11-08: the slimes, goblin archer, bats and drops all feel right.

**Next:** H4, items and weapons.

## 2026-11-08 — Sprint (user request)
- Hold **Shift** (gamepad **B**) to sprint at 120 px/s (walking is 72); no stamina. GDD §5 and CLAUDE.md now allow it. The HUD hint lists it.
- Tests: sprinting covers 120 px/s in all eight directions while walking stays at 72, a swing still roots a sprinting hero, and Shift is bound. 118 tests, all green. A deliberate bug (sprint not faster) was caught.
- Not played by hand yet.
