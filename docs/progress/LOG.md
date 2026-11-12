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
- Played by hand on 2026-11-08: the sprint speed feels right.

## 2026-11-08 — H4 Items & weapons — done

**Built**
- **Items in data:** Bow (ranged: damage 2, cooldown 0.45 s, ammo `arrow`, speed 180), Arrows (up to 30), Bombs (up to 10: damage 4, fuse 2 s, radius 24). DataRegistry checks a ranged weapon's ammo is an item.
- **Inventory rules** (`core/inventory/Inventory`, pure): stack capacity, room left, which items go on the item button, ammo per item, and the equippable items held. `GameState.add_item` respects capacity and returns what it added.
- **Equipment:** `GameState.equipped` is saved, and the first item for the button is equipped automatically. `EventBus.equipped_changed`.
- **The item button** (Q / K / Y): the bow shoots hero-team arrows (they hurt enemies and the dummy, and stop at solid tiles); bombs go down, burn a blinking fuse, and blast enemies in range once. A message shows when out of ammo or with nothing equipped.
- **The item menu** (Tab / I / Back), and an "Item:" line on the HUD.
- **Tilda's shop:** a new door and interior in the village, with the shop as a conversation in data. The Bow and ten arrows lie in the South Field ruin.
- 132 tests in 20 suites (+14). New: `inventory_test` and `items_test`; additions to the GameState, save, registry, input-map and doors suites.

**Acceptance criteria**
- [x] Arrows and bombs hurt enemies and run out.
  - With two arrows, the first beats a slime in its path and the second leaves the quiver empty; a third shot does nothing.
  - One bomb: the goblin is untouched while the fuse burns, beaten by the blast, and the hero beside it is unhurt. Then there are no bombs left to set.
- [x] The shop sells them for coins. With 20 coins: ten arrows (→ 15 coins), three bombs (→ 7). With 7 coins the bombs only get an explanation, and nothing changes. A full quiver (capped at 30) can't buy arrows, and no coins are taken.
- [x] The equipped item survives a save. The menu lists "Bow (Arrows x5)" then "Bombs x2"; choosing Bombs equips them. It survives a save slot round trip and a fresh game being loaded over it, and the HUD shows "Item: Bombs x2" after. Also checked in the GameState JSON round trip and SaveSystem suites.
- Mutation checks: six deliberate bugs, each caught by the expected test, files restored byte for byte:
  - arrows never used up
  - no stack limits
  - the equipped item not saved
  - bombs that never blast
  - coins always "enough"
  - the hero's arrows on the enemy team
- One real fix found by the tests: the item menu listed items alphabetically by id ("Bombs" before "Bow"). It now uses pickup order.
- Visual check (`tools/capture.gd`, 18 shots): Tilda's shop with her offer, the item menu, an arrow in flight, and a lit bomb.

**Known issues / notes**
- An arrow shot upward starts behind the hero and is mostly hidden for its first few frames (y-sorting); sideways and downward shots read clearly.
- The hero's own bombs can't hurt them, and bombs don't break anything yet (cracked walls are H6).
- Shop options repeat their conditions in data (buy vs "can't"); a `can_carry` condition would tidy that.
- Played by hand on 2026-11-08: the bow, bombs, item menu and shop all feel right.

**Next:** H5, the dungeon framework.

## 2026-11-08 — H5 Dungeon framework — done

**Built**
- **Rooms** (`RoomGrid`, pure): a dungeon area is cut into equal rooms. The camera shows only the hero's room, centred, with a `RoomMask` shading the rest, and the screen dims briefly on a room change.
- **Dungeon state** (`DungeonState`, pure): per-dungeon flags for small keys, the big key, opened doors and opened chests, and the door rules (a small key for locked doors, spent; the big key for the boss door, kept).
- **`DungeonDoor`** (open, locked, boss, shutter): closed doors fill their cells, and shutters lift on a flag.
  - **`Chest`**: keys go to the dungeon's count, anything else to the inventory.
  - Enemies can share a `clear_flag` that's set when the last of them falls.
  - E now uses doors and chests in front, with HUD prompts. The HUD shows a dungeon's keys.
- **The Ruin Cellar:** a three-room test dungeon down a new stairway in the South Field ruin. New tiles: dungeon floor, stairway, dungeon wall, pillar.
- 142 tests in 22 suites (+10). New: `dungeon_rules_test` and `dungeon_test`; the doors suite covers the cellar's stairs.

**Acceptance criteria**
- [x] A three-room test dungeon needs a small key to progress. Facing the hall door with no key, it holds (and says so), and walking north stays in the entry hall. The entry hall's chest gives a key (HUD "Keys: 1"); the door then opens, the key is spent, and the hero walks through into the hall.
- [x] It remembers opened doors after leaving. After opening the chest and the door, the hero goes up the stairs, through a JSON save and load, and back down: the door is open and its cells walkable, and the chest is open with nothing more to give.
- [x] The boss door needs the big key. Three small keys don't open it. The big key from the alcove chest does, and neither key count goes down. The inner room's chest gives 20 coins.
- Also: the camera centres on one room at a time and the mask covers the rest. Beating one hall slime leaves the shutter shut; beating both lifts it.
- Mutation checks: six deliberate bugs, each caught, files restored byte for byte:
  - locked doors opening without a key
  - closed doors not blocking
  - flags not restored from a save
  - small keys opening the boss door
  - the shutter opening after the first slime
  - the camera ignoring rooms
- Visual check (`tools/capture.gd`, 21 shots): the stairway in the ruin, the entry hall, and the hall with its shutter and boss door. The first shots showed the neighbouring rooms above and below a room, so `RoomMask` was added. Doors were drawn with one lock across both halves, so each room saw half a keyhole; now each cell has its own.

**Known issues / notes**
- Room changes snap (with a short dim) rather than scroll.
- Doors don't lock behind you, and there's no map or compass.
- The cellar's slimes could notice the hero through a closed door when close, but can't pass it.
- Played by hand on 2026-11-08: the cellar, its keys, doors, shutter and room camera all feel right.

**Next:** H6, puzzles.

## 2026-11-08 — Art pass (user request)

At the user's request, the environment moves from flat greybox to pixel art. It's still all painted in code, and every map plays exactly as before.

**Built**
- **Repainted tiles** (`make_tile_texture.gd`): grass, paths, stairs, trees, rocks, timber walls, clay and slate roofs, water, fences, stone.
- **New atlas rows:**
  - decorations: flowers in three colours, tufts, pebbles, mushrooms, crops, lily pads
  - details: roof ridges and eaves, a wall with a flower-box window
  - solid ground by height
  - props: tree, rock, fence, the well's four quarters
- **Map baker** (`build_maps.gd`):
  - ridges, eaves and windows by itself
  - trees, rocks, fences and the well as props over solid ground
  - a Decor layer in every area, with placed decorations (flower beds along the house fronts, lily pads, a vegetable patch on the east meadow) and a seeded scatter over open grass
- **HeightShading:** earthy cliff faces with a lip and a shadow at the foot; soft shadows under houses.
- 146 tests in 23 suites (+4, `decor_test`). All earlier tests pass unchanged, so layouts, combat, enemies, items and dungeons behave as before.

**Checks**
- `decor_test`: every area has a Decor layer just above Height. Decorations sit only on open ground (lily pads only on water) and never on anything the hero uses or arrives at. Props stand only on solid ground, nothing on the Decor layer blocks, and the village and the field each have 60+ decorations. House roofs and walls show ridges, eaves and windows and stay solid at height 3; the well's quarters stand on solid ground.
- Mutation check: scatter allowed on busy cells, caught by `decor_test`. Restoring the tool and re-baking gave byte-identical scenes, so the baker is deterministic.
- Visual check: before/after screenshots of the village square, the field and pond, and the South Field. The first pass showed dark squares behind trees and rocks on raised ground, the well as a plain block, and cliffs as a thin band. Props over solid ground, a 2x2 well and cliff faces fixed all three.

**Known issues / notes**
- Interiors and the dungeon keep their earlier tiles (they were already detailed); their Decor layers are empty.
- No autotiled shorelines or path edges yet: water and paths meet grass with a straight edge.
- Trees in long rows still read as a line of round trees rather than a forest canopy.
- Seen in the game on 2026-11-08: the new look is approved ("looks good").

## 2026-11-08 — H6 Puzzles — done

**Built**
- **`PuzzleRules`** (`core/puzzles/`, pure): pushable cells (open floor at the same level, never a room's border), plates pressed by the hero or a block, shutters on any or all of several flags.
- **Pieces** (`gameplay/puzzles/`):
  - `PushBlock`: slides a cell after 0.35 s of pushing, drawn sliding; back at its start each visit.
  - `PressurePlate`: sets its flag while pressed, or for good with `latches`.
  - `CrystalSwitch`: hit by sword, arrow or bomb, it sets or toggles its flag; red or blue.
- **Doors and hits:** a `cracked` `DungeonDoor` kind that only a bomb opens; shutters with `open_flags` / `needs_all`; `Hit.kind` and `HitBox.kind` on the sword, arrows and bombs.
- **The hero** remembers the held direction (`PlayerMotor.held`), and the area pushes blocks the hero leans on (`update_pushing`) and updates plates (`update_plates`).
- **The Cistern:** five puzzle rooms, down a new stairway in the Ruin Cellar's inner room.
- 157 tests in 25 suites (+11). New: `puzzle_rules_test` and `puzzle_test`; the doors and decor suites cover the Cistern.

**Acceptance criteria**
- [x] One room per mechanic works.
  - **Push block:** a tap doesn't move it. Holding north slides it cell by cell until the room's edge stops it, and the way north opens (a flood fill reaches the next room).
  - **Pressure plate:** standing on it lifts the east shutter, and it stays lifted after stepping off (latching).
  - **Crystal switch:** the sword turns it blue and lifts the north shutter. With the flag reset (the shutter drops again), an arrow does the same.
  - **Cracked wall:** a sword hit does nothing; a bomb blows it open, its cells come free, the hero is unhurt, and it's still open after reloading.
- [x] One room combines two mechanics with more than one solution. In the treasure room:
  - Pushing the block west onto the plate lifts the shutter. Pushing it off (and stepping away) drops it again.
  - Separately, the platform can't be climbed and the sword can't reach its crystal from below, but an arrow can. That lifts the shutter too, and the chest behind it holds 30 coins.
- Also: the Cistern's stairs lead from the cellar's inner room and back.
- Mutation checks: six deliberate bugs, each caught, files restored byte for byte:
  - no room borders for blocks
  - pushing without holding
  - anything breaking cracked walls
  - shutters needing all flags
  - plates always latching
  - crystals ignoring arrows
- Two test mistakes found and fixed along the way:
  - A crystal's 0.4 s lockout runs on real frames, so a test must let it pass before a second hit.
  - The hero following a pushed block steps onto the plate and keeps it down; the game is right.
- Two layout fixes found while building:
  - The push room's gap sat in line with the doorway, so pushing straight on would park the block in front of the way out. The gap moved to column 4.
  - Blocks looked like pillars; they're sandstone now.
- Visual check (`tools/capture.gd`, 26 shots): the five Cistern rooms.

**Known issues / notes**
- There are no pits for blocks to fall into, and no ice, torches or timed switches (not in the slice).
- Blocks reset only when the area reloads, not when you leave a room within it.
- Played by hand on 2026-11-09: the new look feels right.

**Next:** H7, the first dungeon and its boss.

## 2026-11-08 — H7 The first dungeon & boss — done

**Built**
- **The Old Keep** (`world/areas/keep/`): ten rooms using the H5 and H6 pieces, up a new road through the woods at the top of the village's north rise.
  - Small keys from a cleared guard room and from the archer gallery; a two-plate room; the armoury with **the Bow**.
  - Crystals on ledges out of sword reach, the big key room, and the boss.
  - An optional store behind a cracked wall.
- **The Iron Warden:** a `WardenBrain` (pure; behaviour `warden`, data in `iron_warden.json`) and a `Boss` node.
  - It guards (blows clink off), then gazes. An arrow in its eye stuns it, and only then does the sword hurt it.
  - Unanswered gazes end in bolts. It rages at half health.
  - It keeps to its room and starts over when the hero leaves, and drops arrows for an empty quiver.
- **Heart container** (`HeartContainer`): appears when the boss falls, and adds a heart and fills them all. The way out opens on the same flag.
- **Engine pieces:**
  - shutters that `stays_open`
  - blocks that reset when the hero leaves their room
  - bosses that stay beaten
  - drops that fall off ledges
  - arrow drops (goblin archers, and the boss's help) drawn as a bundle; glowing boss bolts
  - pickup messages
- The Bow and its arrows left the South Field ruin.
- 170 tests in 27 suites (+13). New: `warden_brain_test` and `keep_test`; the doors, decor, items and data suites cover the keep and the boss data.

**Acceptance criteria**
- [x] The dungeon can be finished start to end. `keep_test` walks it gate by gate and checks each one shuts the way until it's solved:
  - the locked hall door, then small key 1 from the guard room's alcove (opened by beating its guards)
  - the two-plate shutter: one plate does nothing; the block on one plate and the hero on the other open it, and it stays open, even after the block goes back
  - the Bow and 15 arrows
  - the armoury crystal: the sword can't reach it, an arrow can
  - the gallery archers: no way up the walkway; they're shot down, and their drops land on the floor; small key 2
  - the east door, then the twin crystals (sword and arrow, both needed)
  - the big key, then the boss door
- [x] Beating the boss adds a heart.
  - Sword blows clink off until an arrow finds its eye. It took two stuns to beat.
  - The heart container appeared; touching it took the hero from 3 to 4 hearts and filled them.
  - The way out led back to the village.
  - Reloaded, the Warden is gone and the heart is taken for good.
- Also:
  - The road from the village leads to the keep and back.
  - All ten rooms are joined once every door is open.
  - The Warden starts over when the hero leaves its room.
  - An empty quiver gets five arrows.
  - An unanswered gaze fires a glowing bolt.
- Mutation checks: eight deliberate bugs, each caught, files restored byte for byte:
  - the eye taking any blow
  - the boss never starting over
  - bosses coming back
  - shutters never latching
  - blocks never resetting
  - drops staying on the ledge
  - no arrows for an empty quiver
  - no flinch
- One test mistake: the pickup tests moved the hero's grid position without moving its node, so nothing was touched. The game was right.
- Visual check (`tools/capture.gd`, 39 shots): the north road, every keep room, the Warden waking and opening its eye (with arrows fallen for an empty quiver), and the heart container after it falls.

**Known issues / notes**
- Arrows fly through closed doors and shutters (they only stop at solid tiles). It's harmless so far.
- Ledges in dungeons use the dirt-path tile.
- The Warden has no health bar or music.
- Played by hand on 2026-11-08: the boss was too hard. It was eased on every front:
  - its touch and bolts cost half a heart
  - it moves slower, its eye stays open longer, and stuns last longer
  - it has less health

  A dev shortcut, `tools/playtest.gd -- warden`, starts at its door for retrying (details in DECISIONS).
- Played again on 2026-11-08: the eased Warden feels right.

**Next:** H8, the countryside between the village and the keep.

## 2026-11-08 — H8 The countryside — done

**Built**
- **The North Fields** (`world/areas/north_fields/`): a winding road and a bridge over a stream, a fenced farm plot, a plateau with a goblin archer, five slimes, and a signpost. A gap in the tree line hides a meadow with a chest of five bombs (secret 1).
- **The Old Wood** (`world/areas/old_wood/`): dense trees, the road winding between clearings with bats, slimes and an archer, and the keep's stone front with corner towers and its gate. A walled shrine with a cracked wall holds a heart piece (secret 2).
- **The roads are rewired:** village → fields → wood → keep, and back. The keep's way out behind the boss leads to the wood.
- **Heart pieces:**
  - `GameState.heart_pieces` (saved) and `add_heart_piece()`, where four make a heart
  - `EventBus.heart_piece_found`
  - the `HeartPiece` node, a quarter heart taken by touch
- **Outdoor doors and chests:** their flags are named by the area (`flag_scope()`), and cracked walls get a `stone` colour.
- 176 tests in 28 suites (+6). New: `countryside_test`; GameState covers heart pieces and saves them; `doors_test` checks every door stands on walkable ground; the doors, decor and keep suites cover the new roads.

**Acceptance criteria**
- [x] You can walk from the village to the keep and back. `countryside_test` takes every exit in turn and checks each can be reached on foot: village to fields to wood to keep, then back the same way, arriving where the north road comes in.
- [x] At least one optional secret. There are two, and neither is on the way to the keep:
  - The hidden meadow: a path one tree wide off the road leads to a chest of five bombs, opened for good.
  - The shrine: the heart piece is walled in. A sword doesn't break the crack, but a bomb does (sparing the hero). The piece counts "1 of 4", doesn't add a heart on its own, and stays taken after a reload.
- Also: both areas have five or more enemies of more than one kind, all set up and on open ground.
- Mutation checks: five deliberate bugs, each caught, files restored byte for byte:
  - pieces never making a heart
  - pieces not saved
  - a piece never taken for good
  - outdoor flags left unnamed
  - the village road skipping the countryside
- One real bug, found by the shrine's test: the cracked wall stood on solid stone, so opening it led nowhere. The map now has floor under it, and a new check in `doors_test` makes sure every door in every area stands on walkable ground.
- Visual check (`tools/capture.gd`, 47 shots): the fields' road, bridge, plateau and hidden meadow, and the wood's road, the keep's gate, and the shrine closed and opened.

**Known issues / notes**
- No HUD counter for heart pieces; only the message when one is found.
- The keep's front is a plain stone wall with two towers.
- Played by hand on 2026-11-08: the road north, the secrets and the enemies feel right.

**Next:** H9, save, menus and playtest.

## 2026-11-08 — H9 Save, menus & playtest — done

**Built**
- **Title screen** (`ui/title_screen.tscn`, now the main scene): a painted dusk with the keep on the skyline, and Continue (with where and how long), New game, Settings and Quit.
- **Pause menu** (Esc / P / Start; new `pause` action):
  - It pauses the game tree.
  - It shows hearts, heart pieces, keys and the play time.
  - It offers Resume, Save, Settings, and Quit to title (warning that unsaved progress is lost).
- **Saving:** one slot (`SaveSystem.current_slot`, `save_game`, `load_game`, `summary`). Continue resumes on the saved cell.
- **Settings:** a `Settings` autoload over a pure `SettingsData` (fullscreen, window size 2x/3x/4x, controls hint), kept in `user://settings.cfg`.
- **Menus:** a shared `MenuCursor` (pure) and `MenuInput`.
- **Play time:** `GameState.play_time` (saved) and `format_play_time`.
- **The end:** taking the Warden's heart opens a closing conversation (`ending_keep`).
- **Fixes:**
  - Closed doors seal their cells, so arrows and bats stop at them.
  - Elder Bram points to the sword and the road north.
  - The welcome sign names the road to the keep.
  - The controls hint mentions Esc.
- 197 tests in 31 suites (+21). New: `menu_cursor_test`, `settings_data_test`, and `menus_test` (the title, pause, saving and continuing, settings, the clock, the ending, arrows at doors, Bram's hint). GameState, SaveSystem, TerrainQuery and the input map suites grew; the keep walkthrough now ends in the closing conversation.

**Acceptance criteria**
- [x] A new player finishes the slice in 30–60 minutes with no developer help. The new-player playtest went well, as reported on 2026-11-08 (no play time was given). Everything it relies on is built and tested:
  - The title starts a fresh game, or continues a save to the exact cell.
  - The pause menu stops the game (the area can't process, the menu can) and saves.
  - Settings apply at once and survive a reload.
  - The clock stops while paused.
  - The Warden's heart ends the slice.
- Mutation checks: eight deliberate bugs, each caught, files restored byte for byte:
  - the cursor landing on options that can't be chosen
  - the pause menu not pausing
  - Continue without a save
  - play time not saved
  - the clock never running
  - arrows ignoring closed doors
  - settings not kept
  - no closing conversation
- One real bug, found by the settings test: `MenuCursor.move(2)` moved only one step.
- Visual check (`tools/capture.gd`, 51 shots): the title screen, the pause menu, the settings menu, and the closing conversation. Two layout fixes came out of it: "Quit" spilled out of the title's menu panel, and the pause note crowded the last option (the pause panel now steps aside for the settings).

**Known issues / notes**
- One save slot, no autosave.
- No audio, so no volume setting.
- The window settings are applied but can't be checked headless.
- **First run by hand (2026-11-08):** saving and a settings change worked (both files written). The log showed a script error each time a menu choice changed the scene (New game, Continue, Quit to title): the menu asked for its viewport after the scene change had taken it out of the tree.
  - Fixed: the menus take the viewport first.
  - A test now leaves the tree mid-choice the same way. Putting the bug back in either menu fails it.
- Played again by hand on 2026-11-08: the title, the pause menu and the settings feel right.

**Next:** the vertical slice (H0–H9) is done. What comes after it is in ROADMAP's "After the slice".

## 2026-11-08 — H10 Feel & sound — done

**Built**
- **`Synth`** (`core/audio/`, pure): oscillators, noise, envelopes, pitch sweeps, mixing, a note sequencer with drums, PCM16.
- **`tools/audio/make_audio.gd`:** 26 sound effects and 4 original songs, baked in about 5 s to `audio/sfx` (0.5 MB) and `audio/music` (3 MB).
  - The effects cover swings, hits, hurt, pickups, fanfares, doors, jingles, arrows, bombs, crystals, pushes, plates, the Warden, and menus.
- **`Audio` autoload:** sound and music buses, eight effect voices, looping music, volumes.
- **Hooked into the game:** every action asks for its sound through `EventBus.sound`.
  - Each area plays its tune; the Warden plays the boss tune while awake.
  - Hit-stop on landed blows, hurts, stuns and the Warden's fall.
  - Screen shake for bombs, the Warden's stomps and fall, and the hero being hurt.
  - Sparks, dust and sparkle bursts.
- **Settings:** music and sound volume.
- 214 tests in 33 suites (+17). New: `synth_test` and `sound_test`; the settings and menu suites cover volume.

**Acceptance criteria**
- [x] Every action makes its sound. `sound_test` listens while doing each one:
  - fighting: swing, hit, beat, hurt
  - items: arrow, out of arrows, bomb set and blast
  - pickups and treasure: an item, a heart, a coin, a chest, the heart container
  - doors and puzzles: locked, unlocked, a plate (one click, not one a frame), a pushed block, a crystal and the shutter it lifts, a cracked wall
  - the Warden: stomp, gaze, clink, stun, fall
  - the pause menu
- [x] Each area plays its tune and the boss fight its own. All ten areas and the title are checked. The Warden switches to the boss tune when it wakes, and back to the dungeon's when the hero leaves or it falls.
- [x] Volume settings work and persist: each sets its bus, 0 mutes, and they survive a reload.
- [x] A playtest says the game feels better, not noisier: played by hand on 2026-11-08, and the sound feels right.
- Also checked:
  - Every sound and tune the game uses is baked by the tool, and the tool bakes nothing unused.
  - A landed blow freezes the game a moment and sends sparks.
  - Getting hurt and blasts shake the view.
  - Leaving an area always ends a freeze.
- Mutation checks: eight deliberate bugs, each caught, files restored byte for byte:
  - silent blows
  - no hit-stop
  - no boss tune
  - silent solved puzzles
  - zero volume still playing
  - music volume forgotten
  - areas playing no tune
  - a baked sound left unlisted
- Found along the way:
  - The boot leaked the village tune at exit (fixed: headless plays nothing).
  - A dialogue-box hook landed under the wrong function's comment (fixed).
- Visual check: the settings menu fits its six lines.

**Known issues / notes**
- Mono only; no footsteps or text blips.
- The tunes loop with a hard cut.
- Heard and approved by hand on 2026-11-08.

**Next:** the playtest, then H11 (grass, pots and heart pieces).

## 2026-11-08 — H11 Hero & graphics — done

Re-planned first at the user's request: phase 2 now puts detail and graphics ahead of a bigger map (ROADMAP H11–H15; the new region moved to "later").

**Built**
- **The hero repainted in blue:** hood and tunic with a gold hem, belt and buckle, more shading, a face with two eyes, and an arm that swings in side view. The old Network Key glow is gone.
- **`tools/art/make_sprites.gd`:** 9 sprites, 33 frames, painted into `gameplay/art/` with white flash rows:
  - slime (rest, wobble, hop)
  - bat (roosting, wings up, wings down)
  - goblin archer (front, back and side, drawing its bow in front and side views)
  - the Iron Warden (stand, step, gaze, stunned)
  - villagers (plain and bearded)
  - 11 item icons (sword, bow, arrows, bomb lit and dim, key, coin, heart, heart container, heart piece, gem)
  - the crystal switch (red, blue, white)
  - the training dummy and brambles
- **`SpriteSheet`** (frames, mirroring, flashes, tint, villager recolouring) and **`ItemIcons`**. Every enemy, the Warden, villagers, pickups, items, bombs, the crystal, the dummy and the brambles now draw sprites.
- **Tiles:** a raised flagstone `ledge` kind for dungeon platforms and walkways, stone cliff faces in dungeons, and animated water (four frames).
- 218 tests in 34 suites (+4). New: `sprites_test`.

**Acceptance criteria**
- [x] The hero wears blue.
- [x] No placeholder shapes are left. Every body, item and puzzle piece is a sprite; only effects stay drawn (shadows, glows, sparks, poofs, the swing arc, arrows in flight).
- [x] Screenshots of every area read clearly: all 51 shots reviewed, with close-ups of the training yard, the goblin, Bram, the Warden, the keep's walkway and the Cistern's platform.
- [x] Tests stay green. `sprites_test` checks:
  - the frame names match the tool
  - every sheet has its white flash row
  - villagers are recoloured with no marker colour left
  - ledges are walkable at every height
  - water animates
  - the keep's walkway is a ledge
- Mutation checks: four deliberate bugs, each caught, files restored byte for byte:
  - goblin frames out of order
  - villagers keeping marker colours
  - water not animated
  - beards on the wrong villagers
- Found along the way:
  - The Warden's first step frame lifted half its body. The generator shifted the wrong rows; fixed.
  - The bomb and hearts borrowed the wrong palette keys (a blue cap, a red fuse, grey highlights); fixed.
  - The signpost relied on the villager's old `LIFT` constant; kept.
  - The screenshot tool counted frames, not seconds, for the Warden's gaze; fixed.

**Known issues / notes**
- Sprites are a first pass: one idle frame for villagers, no walk cycle for goblins (they glide), no attack poses.
- Flying arrows and the sword arc are still thin drawn lines.
- Played by hand on 2026-11-08: the new art feels right.

**Next:** H12, a more detailed world.

## 2026-11-09 — H12 A more detailed world — done

**Built**
- **Grass and pots** (`Breakable`, data in `data/breakables/` with a schema):
  - Cut or smashed by the sword or a bomb, each with its own sound (`cut`, `pot`) and a burst (leaves, shards).
  - Drops come from data tables; the cell is freed; grass leaves stubble.
  - DataRegistry validates the new kind, sharing the enemies' drop-table check.
- **Spawn markers:** a hidden `Spawns` layer painted by the baker becomes grass, pots, chickens, butterflies and fireflies on load.
- **Ambient life** (`Critter` over a pure `CritterMotion`): chickens wander and peck by the terrain rules, butterflies flutter over the flowers, fireflies blink in the Old Wood. New sprites: tall grass, stubble, a pot, a chicken (three frames), butterflies in two colours.
- **24 new props and furniture tiles**, painted from ASCII in the tile tool:
  - outdoors: crate, keg, hay, logs, stump, lamp post, standing stone, the washing line and its posts, a well bucket, a 3x2 market stall with wares
  - indoors: chair, cupboard, loom, plant, candle stand, counter, stool, bookcase
- **Dressing:**
  - Hearthvale: market stall, lamp posts, crates, a washing line, hay and logs, a standing stone on the rise, chickens, butterflies, grass and pots.
  - All three interiors are furnished.
  - The South Field, the North Fields and the Old Wood get props, grass, pots and critters.
  - The dungeons get pots.
- **Heart pieces:** three more (village nook, fields plateau, Cistern secret room) join the Old Wood's, plus a HUD counter.
- **Villagers:** Farmer Oda, Pip and Guard Rolf in Hearthvale, Shepherd Edda in the North Fields, each with a short conversation from data.
- 230 tests in 36 suites (+12). New: `critter_motion_test` and `detail_test`; the data, sprite and decor suites grew.

**Acceptance criteria**
- [x] Every outdoor area and interior has new detail in its screenshots: 57 shots, including new views of the market, the field and chickens, the washing line and nook, the shepherd and plateau, the Cistern's secret room, and the Old Wood's fireflies.
- [x] Grass and pots drop what their data says. Rolls across each table produce exactly the drop `DropTable` picks. Arrows don't cut grass, the sword does, and bombs break pots. Cells come free, and everything's back next visit.
- [x] All four heart pieces can be found. One test walks to each:
  - the village nook (cut the grass)
  - the plateau corner (stairs, then cut the grass)
  - the Cistern's secret room (bomb the wall)
  - the shrine (bomb)

  Each is unreachable first. Four pieces make the fourth heart, and the HUD counts 1, then back to 0.
- [x] The map is no bigger: every area's size is unchanged, and there are no new areas.
- Mutation checks: six deliberate bugs, each caught, files restored byte for byte:
  - anything cutting grass
  - broken things still blocking
  - markers left behind
  - the HUD not counting pieces
  - chickens walking through walls
  - any breaks_on accepted
- Found along the way:
  - The standing stone first stood where a village test expects open ground on the rise; moved.
  - The layout script's map lookup dropped a newline and stopped before writing; fixed and rerun.
  - The decor test only knew the old prop rows; it now checks the new props stand on solid ground and the bucket and washing line sit on open ground.

**Known issues / notes**
- The washing line's rope runs a little past its outer posts.
- No lifting or throwing pots; critters don't react to the hero.
- Fireflies glow in daylight.
- Played by hand on 2026-11-09: the new look feels right.

**Next:** H13, quests.

## 2026-11-09 — H13 Quests — done

**Built**
- **`QuestRunner`** and **`QuestState`** (`core/quests/`, pure):
  - Quests run from data: `on_enter` effects once per stage, the first met transition wins, and `complete_quest` finishes a quest.
  - All progress is in GameState's quests and flags.
- **`Quests` autoload:** runs the runner on every flag, item and stage change and on area load, and announces quest news with a sound (`quest`, or the item fanfare on completion).
- **`quest_status` condition**, validated by DataRegistry, which now also rejects quests that can never finish.
- **Three quests as data** (`data/quests/`), with quest options added to four conversations:
  - The Lost Shuttle: Wenna, to the far bank of the stream in the North Fields, and back.
  - Eggs for Tilda: Oda, to the shop, and back.
  - Slimes in the South Field: Rolf, the three slimes, and back.
- **Quest items:** the Weaver's Shuttle (with its own picture, lying by the stream) and the Basket of Eggs. Items can name their picture in data.
- **Quest log:** a "Quests" entry in the pause menu.
- **Notice:** quest news at the top of the screen.
- 249 tests in 38 suites (+19). New: `quest_runner_test` and `quests_test`; the condition, data, sprite, menu and village suites grew.

**Acceptance criteria**
- [x] Each quest starts, advances and finishes from data alone.
  - A generic test starts every quest in `data/quests` and walks it to the end by satisfying each stage's first transition.
  - Three scene tests play each quest through its real conversations: accept, do the thing, report back, get the reward. Each checks the notice at every step.
- [x] The log shows where each stands: empty at first, then active quests before finished ones, with the journal line and unticked objectives for the highlighted quest.
- [x] Progress survives a save. Saved mid-quest and loaded: the same quests at the same stages, Oda's basket not handed over twice, and the shuttle's 30 coins paid once, also after a second save and load.
- [x] A new quest can be added by writing only a JSON file. A fixture quest that exists only as JSON loads without errors and runs start to finish. The game runs exactly the files in `data/quests`.
- Mutation checks: nine deliberate bugs, each caught, files restored byte for byte:
  - stage effects not recorded as applied
  - `complete_quest` ignored
  - quests deaf to item changes
  - started quests reading as not started
  - quests that can't finish accepted
  - every objective ticked
  - no notice
  - the Quests entry opening nothing
  - item pictures ignoring data
- Four existing tests listed exact menu entries, dialogue options and item ids; they were updated for the new entries.
- Visual check (`tools/capture.gd`, 61 shots): Wenna's offer, the "New quest" notice over the conversation, the shuttle by the stream, the quest log, and the pause menu with its fifth entry.

**Known issues / notes**
- The quest log has no scrolling: fine for three quests, not for many.
- Rewards are coins, bombs and arrows only (see DECISIONS).
- The HUD's "Carrying" line grows with every item, quest items included.
- Played by hand on 2026-11-09: the quests feel right.

**Next:** H14, the second dungeon and its boss.

## 2026-11-09 — Art pass 2: hero, houses and the land — done

Asked for by the user between H13 and H14: better graphics, a better-looking hero with better animation, and
houses that look more medieval. Plan: `docs/progress/art-pass-2-plan.md`. No new mechanics, areas or content.

**Built**
- **The hero:** a red scarf, clearer arms and hands, more shading. The sheet grew from 3 to 9 frames a row.
  - a four-frame walk cycle, with hands swinging and the scarf's tail fluttering in side view
  - a blink while standing
  - a lunge behind the sword, one for each facing
  - an item held overhead when picking one up, opening a chest or taking a heart container (for show: moving ends it)
  - a fallen pose at zero hearts, in place of the red tint
- **Houses:** two-storey fronts, with a half-timbered upper floor over a ground floor on a stone footing.
  - roofs with gable boards: thatch on the cottages, clay tiles on the shop, slate on Elder Bram's
  - stone chimneys with drifting smoke, and a hanging sign on the shop
  - the chapel in stone, with arched stained-glass windows, a double door and a cross on its ridge
  - footprints, doors and what's solid are unchanged
- **The land:**
  - grass frays over the edges of paths, and water has a bank and foam (`HeightShading.find_ground_edges`)
  - three kinds of tree mixed by position (round, pine, oak), and a closed canopy where a wood is thick
- 264 tests in 40 suites (+15). New: `hero_test` and `ground_edges_test`; the animator suite was rewritten for the new sheet, and the decor and keep suites grew.

**Done when**
- [x] The hero has the new look and all five animations, and the animator's tests cover them: facing, the four-frame cycle, the blink, each pose, and that its columns are the ones the tool paints.
- [x] Every village house and the chapel show the new fronts and roofs, with doors still working. A test pins the tile at 21 cells (ridge, eaves, gable ends, both floors, the chapel) and that all but the door stay solid at height 3; the village's door tests still pass unchanged.
- [x] Paths, water and woods show the new edges and trees in every outdoor area: a test checks that canopy sits exactly where trees stand on every side, in all four outdoor areas, and that each has every kind of tree.
- [x] All tests pass, and before and after screenshots were reviewed (`tools/capture.gd`, now 64 shots: three new ones for the held item, a stride and the fallen pose).
- Mutation checks: 22 deliberate bugs, each caught, files restored byte for byte:
  - the hero: a walk that starts on a full step, no blink, no bob, an item held up sideways or mirrored, no lunge, never fallen, arms down while holding, a hold that moving doesn't end or that never ends, and no hold for a picked-up item, a chest's treasure or a heart container
  - the land: grass fraying down a cliff, no fringe beside trees, fringes on grass instead of paths, no banks, banks at the map's edge, areas not asking for edges, edges never stored, and every tree kind sharing one tile

**Known issues / notes**
- The baker's choices (which tree, which roof tile) are tested through the baked scenes, so a baker bug shows only after a re-bake.
- The fallen pose is one picture for every facing, and small: it has to fit the 16-pixel-wide frame.
- Villagers and enemies kept their H11 sprites and animations (deliberately not in this pass).
- The red scarf was my choice (DECISIONS). It's two palette entries in the tool if it should change.
- Played by hand on 2026-11-09: the new look feels right.

**Next:** H14, the second dungeon and its boss.

## 2026-11-10 — H14 The second dungeon & boss — done

Plan: `docs/progress/H14-plan.md`. The roadmap left the dungeon's item open; the plan chose the Lantern.

**Built**
- **The Chapel Crypt:** ten dark rooms under Hearthvale's chapel, on a 3x4 grid (the keep's shape mirrored).
  - The chapel's doors are a way in now, behind bars that lift once the Iron Warden is beaten. Guard Rolf says so.
  - The stairs back up come out at the chapel door.
- **Pits:** a pit is a drop in `TerrainQuery`, so the hero can step in, enemies keep out, and bats and arrows cross.
  - Falling costs half a heart; the hero drops out of sight and comes back on the last safe cell, briefly invincible.
  - A push block pushed in fills the pit. With a `block_id` it stays there for good.
  - Drops from anything beaten over a pit land beside it.
- **The dark:** `LightRules` (pure) and a `Darkness` overlay drawn by a small shader, the project's first.
  - The hero has a dim glow, or the Lantern's wide one. Burning torches light their own room only.
- **Torches:** E lights one while the Lantern is carried. Lit, a torch sets a flag that shutters can wait on.
  - Braziers that always burn light the first rooms; three in the Knight's Tomb burn for 6.5 seconds only.
- **The Lantern** (a new item type, carried rather than equipped) and **the Iron Sword** (damage 3 to the wooden sword's 2, with a steel blade when swung).
- **The Crypt Shade:** `ShadeBrain` and `ShadeBoss`. Blows pass through it until all four braziers in its hall burn; the light binds it for three seconds, then it puts them out. At half health it's faster and throws bolts.
  - `ArenaBoss` now holds what both bosses share. The Iron Warden's class and scene are unchanged.
- **Art and sound, all in code:** the torch and the Shade as sprites, Lantern and Iron Sword icons, pit tiles, and five sounds (torch, snuff, fall, sink, whiff).
- **The closing words** moved from the keep to the crypt; the keep's now point at the chapel door.
- **Playtest scenarios:** `crypt` (the top of the stairs, equipped as after the keep) and `shade` (outside its hall).
- 300 tests in 43 suites (+36). New: `light_rules_test`, `shade_brain_test` and `crypt_test`; the terrain, puzzle, inventory, sprite, decor, door and detail suites grew.

**Acceptance criteria**
- [x] The dungeon can be finished start to end. A scene test plays it through: the Trench's block and key, the locked door, the Lantern, the torch door, the Dark Path, the three brief torches and the Iron Sword, the Ossuary's fight and key, the Broken Floor's block and locked door, an arrow into the Reliquary's crystal for the big key, the boss door, the Shade, the heart container and the closing words.
- [x] Its puzzles need the new item. Without the Lantern a torch stays cold (E says why) and its door stays barred; five of the crypt's doors wait on torches.
- [x] The boss can only be beaten with it. Sword and arrow pass through the Shade until all four braziers burn (checked with none, one, two and three lit), and it takes more than one binding.
- [x] Pits work. Half a heart and back at the edge; on the last half heart, back at the entrance with full hearts. A block bridges the trench and is still there after leaving and coming back. A walker can't enter a pit; a flier can.
- [x] The Iron Sword does more than the wooden one: it becomes the sword swung, and a swing does 3.
- Mutation checks: 29 deliberate bugs, files restored byte for byte. 28 were caught at once. One was not: with the hero's hurt box left on during a fall, every test still passed. The fall test now checks it, and the bug is caught.
  - pits: plain floor, a free fall, a fall that sends the hero to the entrance, walking over pits, drops landing in pits
  - blocks: sinking on a room's border, leaving the pit open, a named block lifted out on reset, a sunk block forgotten, its pit open after a load
  - torches and light: lighting without a lantern, brief torches that never go out, a stale flag surviving a load, light through walls, a lantern that gives no light, lights adding up, every torch burning for good
  - the Shade: no flinch, never bound, never snuffing, bound with braziers unlit, braziers left lit on starting over, its touch hurting while bound, bosses never starting over
  - the rest: the dark drawing no lights, a dark area with no darkness, every blade wood, the Iron Sword no stronger
- Six existing tests listed exact items, enemies, areas, exits or the keep's closing words; they were updated.
- Visual check (`tools/capture.gd`, now 80 shots, 16 new): the chapel door barred and open, every room of the crypt, the trench bridged, the hero falling, the Dark Path with and without the Lantern, and the Shade haunting and bound. Three things were changed after looking: braziers moved so room centres and the trench are lit, light kept from leaking between rooms, and the Shade's hall lit fully when all four braziers burn.

**Known issues / notes**
- Played by hand on 2026-11-10: the crypt and the Shade feel right. The Shade's difficulty, the brief torches' 6.5 seconds and how dark the dark is were guesses, and stay as they are; all three are single numbers (in `data/enemies/crypt_shade.json`, the crypt's scene and `Darkness`).
- What the Reliquary's archers drop stays on the far side of the pit.
- The crypt uses the keep's tiles and the dungeon tune. It has no look or music of its own beyond the dark.
- The hero's safe cell is tracked as they walk, so a test that places the hero beside a pit has to walk them a step first.
- A heart container is the Shade's only reward; the story and the real ending are H15's.

**Next:** H15, the story, the ending and a full playtest.

## 2026-11-10 — H15 Story, ending & playtest — built; the playtest is still to run

Plan: `docs/progress/H15-plan.md`. Playtest guide: `docs/progress/H15-playtest.md`.

**Built**
- **The story**, all in data: long ago Sir Aldric bound a Shade under the chapel and set the Iron Warden to bar the crypt when it stirred. Beating the Warden lifts the bars, so the hero has to finish what Aldric began.
  - Elder Bram tells the tale once the keep is quiet, and gives thanks at the end. His earlier lines go away when they're stale.
  - Guard Rolf gets a last line.
  - Five inscriptions: a plaque in the keep's entrance, one by the chapel door, and three in the crypt (the Narthex, the Trench, Aldric's epitaph). The crypt's three are also hints.
  - The keep's closing words now send the hero to Elder Bram. The crypt's end the game.
- **The ending:** the crypt's closing conversation sets the flag `game_finished`, and when it closes the area leaves for a new ending screen: "The End", time played, hearts and quests finished, then Keep exploring or Save and go to the title. `EndingSummary` (pure) builds the lines.
- **For the playtest:** the guide, and an `ending` scenario for `tools/playtest.gd`.
- 313 tests in 46 suites (+13). New: `ending_summary_test`, `ending_test` and `story_test`.

**Done when**
- [x] The story is told in each place, from data, at its point in the game. Tests check Elder Bram's options before the keep, after it and at the end, his tale's words, Rolf's lines, and that each inscription stands on open floor with its cell to itself, can be read, and says what it should.
- [x] The ending screen follows the crypt's closing words, once: not before the last line is read, and not again on a later visit. It shows the right time, hearts and quests.
- [x] Keep exploring returns the hero to the cell they stood on and saves nothing. Save and go to the title saves, and the save remembers the game was finished.
- [x] All tests pass. Screenshots checked (`tools/capture.gd`, now 86 shots, 6 new): Bram's tale, four inscriptions being read, and the ending screen with the keep's window dark.
- [ ] **A new player finishes the game without help, in about two hours.** Not run: it needs people who haven't seen the game.
- Mutation checks: eight deliberate bugs, each caught, files restored byte for byte: the ending flag ignored, the ending screen never coming, the closing words setting the wrong flag, the hero's place not kept, keep exploring going to the village, save and quit not saving, every quest counting as finished, and the quests line left out.

**Known issues / notes**
- Played by hand on 2026-11-10: the crypt, the story and the ending feel right. The new-player playtest is still to run.
- Length: my guess is that a first run takes 45 to 75 minutes, well under the roadmap's two hours. The ending screen will give the real number. If it matters, the fix is more game, which is the "Later" list, not this milestone.
- The ending screen shows the keep's window dark, but the title screen still shows it lit after the game is finished. Fixed the same day (next entry).
- The inscriptions are drawn as the village's wooden signpost, in the dungeons too. Fixed the same day (next entry).
- The ending counts hearts and quests, not heart pieces found (see DECISIONS).

**Next:** the playtest. Then fixes for what it finds.

## 2026-11-10 — After H15: three small fixes

The first two were known issues in the H15 entry above; the third turned up while checking them. No plan file:
each is a few lines.

- **The title follows the save.** `SaveSystem.summary()` now says whether the saved game was finished (`EndingSummary.is_finished`, from the flag `game_finished`), and the title shows the keep's window dark when it was. With no save, or an unfinished one, the window is lit as before.
- **Inscriptions are stone.** `Signpost` has a `stone` option: a standing stone with carved lines, and the prompt "Read the inscription". The five story inscriptions use it (by the chapel door, in the keep's entrance, three in the crypt). The village's welcome sign and the road sign stay wooden.
- **Playtest scenarios have their own save slot** (900, emptied at each start). Before, saving in a scenario replaced the player's own game, and seeing the finished title by hand meant doing just that. Checked by running the `ending` scenario with a stale scenario save planted (it was removed), then a copy of the tool that saves right after starting (the save landed in slot 900, and the player's save stayed byte for byte the same).
- 317 tests in 46 suites (+4). Screenshots checked (`tools/capture.gd`, now 87 shots, 1 new: the title after the ending), and close-ups of the stone in the village, the keep and the crypt.
- Mutation checks: five deliberate bugs, each caught, files restored: finished games read as unfinished, the summary never saying finished, the title's window always lit, stones prompting like wooden signs, and one inscription turned wooden again.

**Known issues / notes**
- Not played by hand yet.
- The title's line "Something has stirred in the old keep north of the village." stays the same after the game is finished.
- The new-player playtest is still to run.

## 2026-11-10 — Art pass 3, step 1: a warmer, softer look — done

Plan: `docs/progress/art-pass-3-plan.md`. Asked for as "very similar to Stardew Valley"; built as Hearthvale's own look in the manner of cosy village pixel art, without copying that game's art (see DECISIONS).

**Built**
- **`PixelGrade`** (`core/art/`, pure): all three art tools pass each picture through it as they bake.
  - Colours are warmed: a little more saturation, lights towards yellow, shadows towards violet.
  - Outlines take a dark shade of what they surround, never darker than a floor. A lone line is a plum-brown ink, and the inside of a dark mass stays dark.
  - The white flash rows and the villagers' marker colours are left exactly as painted.
- **Palette:** sunnier grass on the low ground, warmer paths, brighter water, tree crowns from blue-green shade to yellow-green light, violet-tinted shadows.
- **Grass:** flecks and blades in a yellower light and a bluer shade.
- **Drawn at runtime:** code-drawn outlines use the same ink, and the grass fringe on paths is warmed as the tiles are (`HeightShading.fringe_color`).
- Repainted: the tile atlas, the hero's sheet and 13 sprite sheets. No map, tile layout, sprite size or frame changed.
- 326 tests in 47 suites (+9, all in `pixel_grade_test`).

**Done when**
- [x] Every baked picture goes through `PixelGrade`.
- [x] No old outline ink is left in the tiles, the hero or any sprite (a test reads every picture); flashes are white and villagers still recolour (existing tests).
- [x] The fringe drawn at runtime is the colour of most of the grass tile (a test, for the three green heights).
- [x] All tests pass. All 87 screenshots retaken and compared with the ones from before, six of them side by side (the village square, the pond, the Old Wood, a shop, the keep, the crypt's dark path), with close-ups of the hero, the well and a barrel.
- [x] It looks right in play: played by hand, and on 2026-11-11 the new look was reported to feel right.
- Mutation checks: six deliberate bugs, each caught, files restored: lights leaning violet, marker colours graded, outlines seeing the tile next door, outlines near black again, the fringe not warmed, and the flashes graded too.

**Found along the way**
- The first tuning was too strong (an orange cast on skin and paths), so saturation and the light tint were eased.
- Eyes painted in the outline's own colour were softened with the outlines; they now have a colour of their own.
- Dark things (a bomb, the pit's rim) got outlines as black as before, which is what the floor fixes.

**Known issues / notes**
- This is step 1: colour and line. The shapes are the same art as before. Bigger trees, richer ground, the menus' look and the villagers are later steps in the plan, only if wanted.
- The title screen's picture and the text box are drawn in code and aren't part of the pass.
- One screenshot run printed "1 resources still in use at exit" as the tool quit; the game itself boots and runs clean.

## 2026-11-11 — A whole-game playtest run, for H15's playtest

- `tools/playtest.gd -- full [fresh]` opens the title screen on a save slot of its own (901, kept between runs), so the player's game is untouched and the title offers only New game until the playtest has saved.
- It logs what happens to the console and to `user://playtests/playtest_<date and time>.log`, each line with the time since the run began and the game's own clock: areas entered, items first held, flags, quests and falls.
- Checked by running it (a clean title, a log with its start and end), then a copy that plays a little by itself (a first item, a flag, a fall and an area all logged; the save landed in slot 901; the player's save stayed byte for byte the same). The tool has no unit tests.
- The playtest guide, the README and CLAUDE.md say how to run it.

## 2026-11-11 — Playtest run 1 (`-- full`): stopped partway through the crypt

From the tool's log (`playtest_2026-11-11T10-44-45.log`) and the run's save. Played by the user, who knows the game, so this is not the new-player test. What happened at the two spots under "My reading" isn't recorded yet, so everything under "Read from the log" is fact and everything under "My reading" is a guess to check.

**Read from the log** (times are the game's own clock; the run took 18:47 by the wall clock)
| # | Checkpoint | Time | Notes |
|---|---|---|---|
| 2 | Has the Wooden Sword | 0:07 | before talking to anyone |
| 1 | Talks to Elder Bram | 0:40 | |
| - | Ruin cellar and cistern (side dungeon) | 2:16 to 4:32 | every chest, the heart piece |
| 3 | Leaves the village by the north road | 5:40 | |
| 4 | Enters the Old Keep | 7:07 | |
| 5 | Has the Bow | 8:24 | |
| 6 | Beats the Iron Warden | 10:08 | 23 seconds after opening its door |
| 7 | Back at Elder Bram's | 10:43 | 15 seconds inside |
| 8 | Enters the crypt | 11:01 | left again after 58 seconds with nothing done; back at 14:43 |
| 9 | Bridges the Trench | 15:17 | 34 seconds after coming back |
| 10 | Has the Lantern | 15:49 | |
| 11 | Has the Iron Sword | 16:39 | the three brief torches: one failed try, then lit in 4 seconds |
| - | Bridges the Broken Floor | 17:17 | |
| 12 | Has the crypt's big key | not reached | |
| 13 | Beats the Crypt Shade | not reached | |
| 14 | Sees the ending screen | not reached | |

- The run ended at 18:12, saved, with the hero in the Dark Path room (the crypt's east side), holding no key.
- All three quests finished, four heart pieces found, five hearts, 204 coins. The hero never ran out of hearts.
- Between the two crypt visits (11:59 to 14:43) the player went to Elder Bram, finished two quests, and visited the shop, the south field and the North Fields.
- Never done: lighting the Narthex's two torches. They open the Ossuary, which holds the key to the Reliquary door on the far side of the Broken Floor.
- No errors or warnings in the game's output.

**My reading** (to check with whoever played)
- This is the pace of someone who knows the game (it was the user): a sword in seven seconds, the keep in three minutes. It says nothing about whether a new player finishes without help.
- At this pace a whole run is about 25 minutes. That fits the earlier guess of 45 to 75 minutes for a first run, well under the roadmap's two hours.
- The first crypt visit ended after a minute with nothing done. Either the player chose to finish the quests first, or the dark and the Trench sent them looking for something outside. Elder Bram's tale says to find a light before going deep, and the only light is inside the crypt.
- The run stopped 55 seconds after the Broken Floor, with the hero back on the east side and no key. That looks like a search for the Reliquary door's key. The way to it (the Narthex torches, passed before the Lantern can light them) may be easy to miss.
- The three brief torches took two tries, which is about what was hoped for.

**What the player said** (the user, 2026-11-11)
- The run stopped because they were stuck at the Reliquary's locked door: they couldn't find its key. The reading above was right.
- The first crypt visit hasn't been explained yet, so Elder Bram's line stays as it is.

**Fixed**
- **A stone by the Reliquary door** (`ReliquaryInscription`, the crypt's fourth inscription): "THE RELIQUARY IS LOCKED. Its key lies with the bones, west of the first hall. Light the two torches by its west wall." It stands beside the door, on the far side of the trench, where the player is standing when they find the door locked.
- Why a hint and not a new layout: the key order can't strand anyone, and the way to the key was there. What was missing was anything, at the moment of being stuck, that pointed back to two torches passed before the Lantern could light them. The door itself only says a small key would open it.
- Tests: the stone is in the inscriptions test (on open floor, readable, its words), and a new test checks it stands within two cells of the locked door and on the door's side of the trench. 327 tests in 47 suites (+1). Screenshot checked (shot 88, the stone being read by lantern light).
- Mutation checks: three deliberate bugs, each caught, files restored: the hint leaving out the torches, the stone on the wrong side of the trench, and the stone saying the wrong thing.

**Next:** carry on the run from its save with `-- full` to play the Reliquary, the big key and the Shade, which nobody has reached in a whole-game run yet. Then the new-player playtest.

## 2026-11-11 — Playtest runs 2 and 3 (`-- full`, carried on): the Shade beaten, no ending recorded

Played by the user, from run 1's save (the Dark Path room, 18:12 on the game's clock). From the tool's logs; what the player saw isn't recorded yet.

**Run 2** (`playtest_2026-11-11T21-22-23.log`): stopped without a normal end
- Lit the first hall's two torches at 21:12, cleared the Ossuary in 14 seconds, took its key at 21:31. The stone's hint seems to have worked.
- Before that, the three brief torches were lit and burnt out four times over (18:55 to 19:19), though they had already given the Iron Sword.
- The log ends at the key with no "run ended" line; the process exited with code 4 and the engine printed no error. Not known whether the game crashed or was closed from outside. Nothing was saved.

**Run 3** (`playtest_2026-11-11T22-02-04.log`): from the same save again
| # | Checkpoint | Time | Notes |
|---|---|---|---|
| - | Ran out of hearts in the crypt | 19:29 | the first fall in any run |
| - | (nothing logged) | 19:29 to 28:41 | nine minutes; not known what happened |
| - | Ossuary key | 32:42 | torches at 31:47, room cleared in 38 seconds |
| - | Opens the Reliquary door | 33:18 | |
| 12 | Has the crypt's big key | 33:39 | crystal shot 19 seconds after the door opened |
| - | Opens the Shade's door | 36:58 | 3:19 after the big key |
| 13 | Beats the Crypt Shade | 39:39 | 2:41 in its room, without falling |
| - | Takes the heart container | 39:40 | this opens the closing words |
| 14 | Sees the ending screen | not recorded | `game_finished` was never set; the run ended at 41:37 |

- The player asked where the big key was (a hint from outside the game) before run 3.
- The game was closed without saving, so the playtest's save is still run 1's.

**Open**
- Why the ending wasn't reached in the two minutes after the heart container: the closing words set `game_finished` on their last choice ("The end."). Either they weren't finished or something stopped them. Ask the player what they saw.
- What ended run 2.
- The nine quiet minutes after the fall in run 3.

**What the player said** (the user, 2026-11-11): no ending appeared; "the game got stuck on the last message".

**Looked for the cause, not found yet**
- Read the path from the heart container to the ending screen (the pickup, the closing words, the flag, the area leaving): nothing wrong found.
- Reproduced it in a window with real key presses (a scratch script): the Shade beaten by a sword swing with the move, sprint and attack keys held, the heart taken, then the interact key twice. Both times the words advanced, `game_finished` was set and the ending screen came up. So the stuck box needs something from the real run that isn't known yet: which words were showing, and which keys were pressed.
- Found on the way and fixed: the key press that ends the closing words raised a script error (`DialogueBox._unhandled_input` asked for its viewport after the area had already left the tree). It did no harm, and it is not the cause above, since the run's output shows no error. 327 tests pass.
- The player said the stuck words were the second and last ("What Sir Aldric could only bind..."), so the first answer ("Go on.") worked and the last ("The end.") didn't.
- Reproduced twice more: with ten seconds between the two key presses, and from a copy of the run's own save (five hearts, every quest done). The ending came up both times. The game was still running while stuck (its clock ran on for two minutes and it closed cleanly), so the box was open and waiting, and the interact key either wasn't reaching it or wasn't what was pressed. Still open.
- The player tried the ending once more from the `ending` scenario, with every key press printed: Enter did nothing on the first words (only the interact key answers), then E took both answers and the ending screen came up. So the closing words work without the fight before them.
- One more reproduction, with the item menu open as the Shade fell: the menu took the first press, then the words went through. Five reproductions, none stuck. Still open.
- **Found** (the player, asked which keys they tried on the stuck box: "Only Enter"). The game wasn't stuck. It was waiting for E, and Enter, which picks in every menu, did nothing in a conversation.
- **Fixed:** Enter (and the keypad's Enter) now answers a conversation. Space does not, because it is the attack key and would skip words that open mid-swing. One new test (`test_enter_answers_a_conversation_and_the_attack_key_doesnt`), which also covers the last answer taking the box out of the tree. 328 tests in 47 suites (+1). Three deliberate bugs, each caught, files restored: Space answering, Enter not answering, and the old viewport error.
- So that the next time is not a mystery: the playtest tool takes a `keys` word that prints every key pressed and the words on screen, and a whole-game run (`-- full`) now always logs the keys pressed while words are showing.

## 2026-11-11 — Art pass 4: light and lettering

Asked for by the user: improve the graphics substantially, keeping gameplay, controls and identity. Plan: `docs/progress/art-pass-4-plan.md`.

**What was weakest** (from the 88 review screenshots): flat light, the engine's smooth font and plain boxes over pixel art, and still air. The tiles, sprites and colour were left alone.

**Built**
- **Cast shadows:** tall solid things shade the ground to their east as well as their south (`HeightShading.cast_on`).
- **Glows:** lamp posts, hearths, candles, burning torches, crystals and the hero's lantern give a soft round of light (`Glows`, `Ambience`); fires flicker; light is clipped to the map.
- **Gloom:** houses and dungeons that aren't `dark` are a little dim away from their lights, never around the hero (a second, soft `Darkness`). For show only.
- **Vignette** on the HUD, and **motes** in the air (pollen outdoors, dust inside).
- **A pixel font** painted in code (`tools/art/make_font.gd`, 95 glyphs), baked with a UI theme and set for the whole project. Label sizes are whole multiples of 8 (10 became 8, the titles' 36 became 32); outlines became the theme's one-pixel shadow.
- **Framed boxes** (`PanelFrame`) for the dialogue box, every menu and the HUD; the controls hint has a box of its own; the HUD's corner is wider and cuts long lines with an ellipsis.
- `tools/capture.gd` takes only the shots named after the folder (`-- <dir> 1 30 71`).

**Checked**
- 337 tests in 48 suites pass (+9, `tests/world/ambience_test.gd`). Import and boot clean.
- Mutation checks: five deliberate bugs in runtime code, each caught, files restored: a dungeon taken for the outdoors, a second sheet of dark over the crypt, shade falling from lower things, an unlit torch glowing, a lamp flickering like a fire.
- Screenshots: all 88 retaken; before and after compared from the same spots for the village square, the elder's house, the keep's great hall, the crypt's hall, the wood road, the title, the pause menu, the item menu, the quest log, a long conversation and the keep's closing words.
- Frame cost, windowed with vsync off on this machine (Intel graphics): about 2.1 to 2.5 ms a frame with or without the pass, a difference of 0.1 to 0.3 ms and 2 to 4 draw calls, in the village, the wood, the keep and the crypt.

**Known issues and limits**
- The motes and the flicker only show in motion, so the screenshots couldn't judge them; the play below did.
- The keep and the cistern have no light sources, so their rooms are lit around the hero only. Wall torches would need map changes.
- The titles are the 5x7 font at four times its size, which is blocky. A title drawn at its own size would look better.
- The font is wider than the old one, so text wraps a little sooner. The longest conversations checked fit their box; not every line in the game was looked at.
- Tiles, sprites and animation are as they were.

**Played** (the user, 2026-11-11): "Feels right". The game ran and closed with no errors or warnings.

## 2026-11-11 — Hero pass: outfit and movement (built; not yet tried in play)

Asked for by the user: a better-looking, better-moving hero, keeping controls and gameplay. The request was written for a 3D character; the hero is a 16x24 sprite, so the plan (`docs/progress/hero-pass-plan.md`) says what each part became and what has no meaning here.

**Built**
- **Outfit**, on every drawn frame of every facing (189 rows of the ASCII art rewritten in `tools/art/make_player_sprite.gd`): a leather vest over the blue tunic, wrist guards, a belt pouch, pale slate trousers, tall cuffed boots, the sword's hilt over his shoulder with its sheath across his back, a small olive pack, a swept fringe and a mouth. The blue hood and the red scarf stay.
- **Seven new frames a row** (sixteen in all), made by the tool from the drawn ones: breathe, windup, hurt, and four run frames.
- **Animation** (`PlayerAnimator`, `PlayerController`): a slow breath while standing; the run frames and a longer stride when sprinting; a swing in three pictures (wind-up, lunge, settle); a flinch when hit; bent knees after a ledge hop. The hilt leaves his back while he swings.
- Swing timing, the sword's HitBox, speed and collisions are untouched.

**Checked**
- 345 tests in 48 suites pass (+8: the breath, the run cycle and stride, the swing's three pictures, the hurt and landing poses, the made frames against the drawn ones, and in the village a sprint, a hit, a swing and a landing). Import and boot clean.
- Mutation checks: five deliberate bugs in runtime code, each caught, files restored: the wind-up after the lunge, walking leaning in place of sprinting, a sprint with a walk's stride, a hit with no flinch, a hero who never breathes.
- Pictures: the sheet before and after; the idle from the front, the back and the side, and the breathe, wind-up, attack, hurt and run frames at eight times size; the hero in the village square before and after from the same spot.

**Known issues and limits**
- Not tried in play. Stills can't show how the breath, the lean or the wind-up feel in motion, or whether the wind-up (about a fifth of a swing) is long enough to see.
- From the front and from behind, the run frames are the walk frames: only the side view leans.
- The wind-up and the flinch are a drawn frame with the body a pixel lower, not new drawings: no drawn-back sword arm, no follow-through of its own.
- From the side the hilt doesn't show (the hood and the scarf's tail are in the way); the pack does.
- The fallen frame is too small to show the new clothes and is unchanged but for its colours.
- No jump, dodge or climb: the hero has none, and the pass adds no mechanics.

## 2026-11-12 — The pivot, phase 0: audit and plan (no code)

The user asked for a change of direction: a story-driven RPG with survival and farming, a modern pixel-art look, cherry blossom trees. Phase 0 is a written plan only: `docs/progress/pivot-plan.md`.

- The hero pass was committed first (`ffa36a7`, 345 tests pass); it has still not been tried in play.
- Audited: `GameState`, `SaveSystem`, the motor, items and the registry, the HUD and screens, the area controller, light, enemies, quests, audio, the art tools, the maps, settings, the tools and the tests.
- Checked on this machine: the monitors are 2560x1440 (exactly 640x360 four times); real 2D lights work in the project's renderer, and 24 of them over a full screen cost about 0.9 ms a frame.
- Nine decisions are waiting on the user (resolution and grid, the indoor camera, the hero's hood, a home for the hero, new cherry tree cells, the day's length, the clock in dungeons, saving, six review stops in phase 1).
- Nothing in the game changed. `CLAUDE.md`, the GDD and the roadmap are rewritten on approval, before any code.

## 2026-11-12 — The pivot is approved; P1a: the frame (built; not yet tried in play)

**Approved.** The user approved the pivot plan as written, all nine recommendations (`docs/progress/pivot-plan.md`, `docs/DECISIONS.md`). Before any code, `CLAUDE.md`, the GDD and the roadmap were rewritten for the new direction: energy replaces "no stamina", the game is no longer described as a Zelda-like, and the roadmap has the pivot's steps (P1a to 1f, P2, P3, P4). In the GDD, parts not built yet are marked with their phase.

**P1a built** (plan: `docs/progress/P1a-plan.md`)
- **The picture is 640x360** on the same 16-pixel grid; the window is 1920x1080 at the default 3x, with 2x and 4x in the settings.
- **The camera's size comes from the kind of place** (`Ambience.ZOOM`): life size outdoors (40 by 22 cells in view), twice that in houses and dungeons, with the room in the middle.
- **Every screen is anchored:** menus to the middle, the dialogue box to the bottom edge, the controls hint to the top right, the title's and ending's lines across the top and bottom. The title's stars and houses spread across the wider screen.
- **The HUD's corner** is a column: hearts, the new `EnergyBar` (hidden until P2), three lines of text. Its framed box fits what it holds.
- The specks in the air cover the wider view.
- No tile, sprite, map, collision, speed or timing changed, and the save format is the same.

**Checked**
- 352 tests in 49 suites pass (+7, `tests/ui/frame_test.gd`). Import and boot clean.
- Mutation checks: five deliberate bugs in runtime code, each caught, files restored: dungeons at life size, a camera that thinks it sees more when it sees less, an empty energy bar showing a sliver, a corner box that never changes size, a piece heart not counted in the hearts' rows.
- Screenshots: all 88 taken before (from the commit before this step) and after. Looked at closely: the village square, the North Fields, Elder Bram's house, the keep's great hall, the crypt's Dark Path, the title, the pause menu and the ending.

**Known issues and limits**
- Not tried in play.
- **The HUD covers the top corners of a dungeon room.** At twice the size a room fills the screen's height, so the HUD's corner and the controls hint sit over the room's top corners. Both are see-through, and the hint can be turned off. Slimming the HUD is left to 1f and P2.
- **Pixels are twice as big indoors as outdoors.** That is decision 2, and it shows.
- **More is in view outdoors.** The North Fields, the Old Wood and the South Field are exactly as wide as the screen, so the camera there only moves up and down, and the heart piece on the North Fields' plateau is in view from the road.
- During the first run of the after shots, 31 of 88 came out at 640x360: the window had shrunk part-way through. Retaking them gave 1920x1080. Not explained; nothing in the game sets that size.
- The art is unchanged, by design: this step is the frame only.

## 2026-11-12 — P1b: light (built; not yet tried in play)

Plan: `docs/progress/P1b-plan.md`.

**Built**
- **`AreaLighting`**, one per area: an ambient colour (clear outdoors, warm and dim in a house, cool and dim in a dungeon, near black in the crypt) and a pool of real lights (`PointLight2D`), filled every frame.
- **Two kinds of light:** a pool, which shows what it reaches in its own colours and never glares where two overlap, and a glow, which adds its colour on top.
- **Which lights:** a glow at every lamp post, hearth, candle, burning torch, crystal and the lantern; where it is dim, also a pool round the hero and round each glow.
- **The crypt's dark is drawn by the rule's own lights:** one pool per `LightRules` light, at its place and radius, with a picture made from the rule's falloff. Nothing else lights a dark area: a glow is drawn there only when it lies wholly inside a light's fully lit core, so the Reliquary's crystal still gives nothing away.
- **Soft shadows:** one helper (`SoftShadow`) draws the shadow under the hero, villagers, enemies, bosses, critters, pickups, chests, blocks, torches, signs and pots (22 places); cast shadows from trees, walls and buildings are six pixels in two steps.
- **Removed:** `Glows` and `Darkness`.

**Checked**
- 356 tests in 49 suites pass (+4). The tests about the removed nodes were rewritten for the new ones. Import and boot clean.
- **Drawn light against the rule, in a window:** the crypt's hall, the Dark Path (one light) and the Narthex, about 640 floor points each, comparing pixels with the lighting on and off. Every point the rule calls fully lit was drawn at full colour, no half-lit point was drawn dark or darker than the rule, and the brightest truly dark point was 3% or less. In the hall, one or two points in some runs were drawn faintly lit though the rule calls them dark; each was within half a pixel of a light's edge (lights sit on whole pixels).
- **Mutation checks:** five deliberate bugs in runtime code. Four were caught at once: pools adding and glows mixing, a light drawn shorter than the rule, the crypt's lights drawn wider than the rule, a crypt that is only dim. **One survived:** a glow shining out in the crypt's dark. No test had a glow standing outside a lit core. Added one (the Reliquary's crystal while the hero is elsewhere); the bug is now caught. Files restored.
- **Frame cost** (windowed, vsync off, 1920x1080, Intel graphics), before to after: village 3.10 to 3.37 ms, Elder Bram's house 2.90 to 3.59 ms, the keep 3.22 to 3.96 ms, the crypt's hall 3.43 to 5.46 ms. The crypt is the dearest: five pools and their glows over a full screen. All are well inside the 16.7 ms a frame that 60 a second needs.
- Screenshots: all 88 retaken. Looked at closely: the village square, Elder Bram's house (and a close crop of its floor), the keep's great hall, the crypt's hall and the Dark Path.

**Known issues and limits**
- Not tried in play: the flicker of fires and the hero's pool moving with him only show in motion.
- **Lights look a shade wider in the crypt than before.** The old sheet drew the outer twentieth of each light dark although the rule calls it lit; now drawn and rule agree.
- **Where two half-lit edges cross, it is a little brighter than the rule's "brightest light counts".** Never darker, and never lit where the rule says dark.
- **Cast shadows are wide indoors:** six pixels at twice the size is a broad band under shelves and tables.
- **No normal maps and no real-time shadows from walls.** The pivot plan said I would try normal maps on dungeon walls and tree trunks; that is moved to 1c and 1d, where those pictures are repainted.
- Outdoors by day nothing changes but the lamps' glow and the shadows: the hour's colour comes in P2.

## 2026-11-12 — P1c: ground and nature (built; not yet tried in play)

Plan: `docs/progress/P1c-plan.md`. The user approved all eight new cherry tree cells from a marked map of Hearthvale before they were baked.

**Built**
- **Tall trees:** every tree but the closed canopy of thick woods is now a picture 32 by 40 pixels in five shades (broadleaf, oak, pine, two cherries), stood up in its cell at load (`Scenery`) and sorted by depth with the hero. Each still blocks exactly its own cell. A crown fades while the hero, an enemy or a pickup stands behind it.
- **Cherry trees in Hearthvale:** eight new one-cell trees ((16,4), (31,4), (34,25), (27,31), (21,10), (26,10), (26,22), (21,27)) and two existing clumps changed to cherry; in the North Fields two existing clumps changed. Petals drift from each tree and lie settled on the grass and the pond.
- **Wind:** crowns sway; tufts, flowers, crops and washing sway on a layer of their own.
- **Water:** a moving surface (a swell, glints, sparkles, foam at the bank that widens and narrows), and reflections of the hero and of trees by the bank.
- **Mist** over the Old Wood.
- **Palette and outlines:** a little less saturation; outlines dark only on the edge of a shape, soft inside it. All art re-baked (tiles, hero, other sprites, trees).

**Checked**
- 367 tests in 50 suites pass (+11, `tests/world/nature_test.gd`). Import and boot clean.
- **Where the hero can go:** the eight cells are solid and hold cherry trees; the cells reachable from the village square went from 1222 to exactly 1214; doors, roads, the stairs, the crypt door and the heart piece's nook are all still reachable. No other map was re-baked.
- **Never hidden:** for every tree in Hearthvale, standing in the open cell behind it fades that tree.
- **Mutation checks:** five deliberate bugs in runtime code, each caught, files restored: a crown hiding what stands in front of it, trees fading for grass and pots, petals lying on walls, trees mirrored in water to their north, lines inside a shape as dark as its edge.
- **Frame cost** (windowed, vsync off, 1920x1080, Intel graphics), before to after in the same session: village 3.05 to 3.75 ms, North Fields 1.94 to 2.57 ms, the Old Wood 1.88 to 2.26 ms, the keep 2.12 to 2.49 ms. Timings on this machine drift between sessions (the keep read 3.96 ms in P1b's run), so only compare within a pair.
- Screenshots: all 88 retaken. Looked at closely: the village square, the north rise, the pond, the hero behind a cherry tree (close crop), the hero's reflection (close crop), the Old Wood road, the North Fields' bridge, the South Field, the keep's great hall.

**Two mistakes found from the screenshots and fixed**
- The trees came out dark and crimson: my wind shader multiplied the picture by itself (in a canvas shader `COLOR` already holds the texture's colour). Fixed, and the gotcha is in `CLAUDE.md`.
- Some crowns stayed see-through: tall grass behind a tree counted as "something standing there". Now only the hero, enemies and pickups count.

**Known issues and limits**
- Not tried in play: the sway, the drifting petals, the water's movement, the mist's drift and the fade as you walk behind a tree only show in motion.
- **A faded cherry crown over grass looks greyish**, not pink.
- **Reflections mirror the hero and trees only**, not villagers, enemies or buildings.
- **The ground tiles themselves were not repainted** (grass, paths): they changed only through the palette and the outline rule. The closed canopy inside thick woods is still a flat tile.
- **No normal maps.** The pivot plan said I would try them on tree trunks; I did not.
- The outline change is subtle on tiles: most of their lines were already light.

## 2026-11-12 — P1d: buildings, interiors and dungeons (built; not yet tried in play)

Plan: `docs/progress/P1d-plan.md`.

**Built**
- **Walls with a face and a top** (`WallRelief`): a wall cell with open floor to its south shows a front face, lit along the top and dark at the floor (bricks in dungeons, boards under a beam in houses, mossy blocks on ruins); every other wall cell shows a flat top. A face is eight pixels taller than its cell and rises over the foot of the wall behind it, except into the next room of a dungeon.
- **Pillars stand up:** 28 pixels tall, sorted by depth, so the hero walks behind them.
- **Roofs have a ridge:** a strip over each roof's top row in its own thatch, tile or slate, sloping at the gable ends, sorted so that whoever walks behind a house has their feet hidden by it.
- All of it is drawn over the map at load. **No map file changed.**

**Checked**
- 374 tests in 51 suites pass (+7, `tests/world/buildings_test.gd`). Import and boot clean. `git status` shows no `.tscn` changed.
- **Blocking is as it was:** in the keep, every wall cell with relief still holds its wall tile and is still solid; every pillar's cell and every ridge's cell too.
- **Mutation checks:** five deliberate bugs in runtime code, each caught, files restored: a face where more wall lies to the south, a face rising into the next room, a ridge sorted behind the hero, pillars counted as trees, the ridge on the eaves.
- **Frame cost.** Draw calls, which are steady: the keep 383 before and 386 after, the cistern 231 and 235, Elder Bram's house 49 and 50, the village 322 and 325. Time, switching the walls on and off in turn in one run (six rounds each): the keep 6.19 ms on and 6.26 ms off (no measurable cost), Elder Bram's house 2.06 on and 1.69 off. All the standing scenery in the village (trees, ridges): 2.90 on and 2.69 off.
- Screenshots: all 88 retaken. Looked at closely: the keep's great hall, Elder Bram's house, the cistern's push room, the crypt's hall, the chapel rise, the Old Wood's shrine.

**Two mistakes found and fixed on the way**
- **A strip of brick at the foot of each dungeon room:** the next room's north wall rose eight pixels into this room's south wall. A face no longer rises out of its own room.
- **The keep's draw calls went from 383 to 1020:** each wall cell was its own draw. The relief is now put together once into one picture the size of the map.
- Also toned down: a speckled grain on the wall tops.

**Known issues and limits**
- Not tried in play.
- **A block of brick stands in a side wall above each east or west door.** By the rule it is a face (the door is open floor to its south), and it reads as the wall's end over the doorway, but it is the least convincing part.
- **Dungeon wall tops are nearly as dark as the black around the room.** Meant (the walls rise into the dark), but the room's outline is softer than it was.
- **A roof's ridge hides the feet of anyone behind the house, a pillar the feet of anyone behind it.** Never more than the feet, so neither fades.
- **Frame times on this machine drift a lot between runs** (the same build read 1.75 ms and 3.77 ms in the same house minutes apart), so only the in-run comparisons above mean anything.
- **No normal maps.** The pivot plan's promise to try them is dropped: a wall is now a painted lit face and a dark top.
- House fronts, furniture, floors and doors were not repainted.

## 2026-11-12 — P1e: characters (built; not yet tried in play)

Plan: `docs/progress/P1e-plan.md`.

**Built**
- **A taller hero, hood down:** 16 by 32 pixels in place of 16 by 24, standing on the same spot. Brown hair, the blue hood hanging behind his neck, and everything he wore before.
- **Put together from parts** (`tools/art/make_player_sprite.gd`): a head, a body pose and a pair of legs per facing, joined by the tool, so every frame of a facing has the same head and clothes. Twenty-one frames a row (thirteen built, eight made from those).
- **Six-frame walk and run:** legs passing, a step, the weight coming down, then the same on the other foot, with the arms swinging against the legs. A cycle covers the ground it did with four frames (28 pixels walking, 36 running).
- **A three-frame swing, drawn for each facing:** wind-up (the hand goes up to the hilt), slash, follow-through, chosen by how far through the swing the motor is.
- **Villagers two cells tall,** redrawn in the hero's proportions, each breathing out and blinking in their own time (`Idling`, pure). The idle frames are made by the tool from the drawn ones.
- **A chicken standing still blinks** (a made frame too).

**Checked**
- 382 tests in 53 suites pass (+8: `tests/core/ambient/idling_test.gd`, `tests/world/characters_test.gd`, and one each in the animator, hero and sprite suites). The tests naming the old frames were rewritten. Import and boot clean.
- **Play is as it was.** No motor, combat, terrain or map file changed. The one scene touched is `player.tscn` (where the sprite is drawn from, and its size). The feet's collision shape is the same size; a villager still fills exactly its own cell; `Sword.HAND` is used only to draw the blade.
- **Mutation checks:** five deliberate bugs in runtime code, each caught, files restored: the walk's first two steps swapped, slash and follow-through swapped, the taller hero drawn from where the short one was, villagers never breathing or blinking, a blink cutting into a breath out.
- **Frame cost:** draw calls are what they were at the last commit: the village 324 (325), Elder Bram's house 50 (50), the keep 386 (387), the cistern 235 (235). Times can't be compared on this machine: the same build read 15.6 ms and 2.6 ms in the cistern in two runs.
- Screenshots: all 88 retaken. Looked at closely: the village square, Elder Bram's house, Tilda's shop, the swing at the dummy, the sword held up, the fall in the South Field.

**Changed from the plan**
- Villagers were redrawn, not stretched: the old robe lengthened left a small head on a long body.
- The chicken's blink was added, since the roadmap names animals.

**Known issues and limits**
- Not tried in play.
- **The hero's head hides most of whoever he talks to from the south.** Two-cell people on neighbouring cells overlap by half. Elder Bram and Tilda are both talked to this way.
- **Elder Bram's fire shows above his head like a crown.** He stands in front of his hearth, and his head now reaches the flame. Moving him a cell would change where things stand, so it is left for the user to decide.
- **The blade is drawn from the middle of his belt,** not from the fist the slash frames hold out. Facing up, it is hidden behind him mid-swing, as it was.
- **From the front and back, running looks like walking.** Only the side view leans.
- **The fallen hero is small:** the frame is one cell wide, so he lies curled in it.
- **The training dummy, the scarecrow and the goblins are still 24 pixels tall,** shorter than the hero. Enemies and bosses were not redrawn.
- The arms holding an item up are a pixel wide.
- The HUD still covers the top corners of dungeon rooms (1f).
