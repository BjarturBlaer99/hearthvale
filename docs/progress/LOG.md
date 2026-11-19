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

## 2026-11-12 — P1f: UI polish (built; not yet tried in play)

Plan: `docs/progress/P1f-plan.md`. The last step of the pivot's visual overhaul (P1).

**Built**
- **A heading face** (`tools/art/make_font.gd`, `ui/font/hearth_heading.tres`): a second pixel font of size 16, capitals twelve pixels tall, with thick stems, thin bars and small serifs. Forty-three glyphs drawn by hand: capitals, digits and a few marks; a small letter shows as its capital. Pairs that stood too far apart (V and A) are tucked together. The theme offers it as the `Heading` kind of label.
- **Headings set in it:** the game's name and "The End" at twice its size (the small face was stretched four times before), and Paused, Settings, Items and Quests in their boxes, which are twelve pixels taller for it.
- **Frames** (`PanelFrame`): a bracket in each corner with a rivet where the inner line turns, in place of the square stud; an inner line lit along the top and left and in shade along the bottom and right; and under a box's heading a rule with a diamond in its middle.
- **The title screen:** a painted evening over Hearthvale, baked by a new tool (`tools/art/make_title.gd`, `ui/title/backdrop.png`): a dusk sky in dithered bands, a crescent moon, clouds lit from below, far hills, the old keep on its hill, the Old Wood's pines, mist, and the village's roofs among cherry trees (the game's own trees, in evening light) with lamps along the road north. The screen draws what moves: stars that twinkle, the keep's lit window, petals on the wind. The ending screen shares it, with the window dark.
- **A slimmer HUD corner:** as wide as its words in place of a fixed 202 pixels, and no line for "Carrying: nothing" or "Item: none".

**Checked**
- 387 tests in 54 suites pass (+5, `tests/ui/polish_test.gd`; one earlier test of the corner's height was updated). Import and boot clean.
- **Play is as it was:** the menus' options, keys and words are unchanged; the only game script touched is the two lines that tell the HUD what to show.
- **Mutation checks:** five deliberate bugs in runtime code, each caught, files restored: the rule's middle off to one side, an empty line still showing, the corner's box always at its widest, the title's picture pinned to the left, the corner saying it carries nothing.
- **Frame cost:** draw calls are four fewer than at the last commit in every area measured (the village 320, Elder Bram's house 46, the keep 382, the cistern 231): the two hidden lines. The title's picture is one draw where the old backdrop drew some forty shapes a frame.
- Screenshots: all 88 retaken. Looked at closely: the title, the ending, the pause menu, the item menu, the quest log, the keep's guard room (the corner), a conversation.

**Known issues and limits**
- Not tried in play.
- **The heading face has no small letters:** headings are all capitals. Adding them is another fifty glyphs.
- **The title's line of story is the old one** ("Something has stirred in the old keep north of the village."). It is story, so it was left for P4.
- **The mist on the title reads as a flat band** more than as mist. It was softened once; it could go.
- **The houses on the title are painted for it,** seen from the front. They are not the game's house tiles, which are seen from above.
- **The controls hint (top right) is as wide as it was.** It is a setting, and can be switched off.
- **On a screen taller than 16:9** the picture sits at the foot and plain night sky fills the space above it.
- The petals on the title are single pixels; easy to miss.
- Still open from 1e: Elder Bram's fire shows above his head, and the hero's head hides most of whoever he talks to from the south.

## 2026-11-12 — P2a: the clock and the day (built; not yet tried in play)

Plan: `docs/progress/P2-plan.md` (P2 in five steps; this is the first).

**Built**
- **The clock's rules are data** (`data/rules/time.json`, a new kind of data with a schema): the day's start and end, the seconds an hour takes, when lamps are lit, when it is night, and the colour of the light at seven times of the day. The registry checks them on load.
- **`DayClock`** (`core/time/`, pure) reads them: a day runs from 06:00 to 02:00 in fourteen real minutes.
- **`GameState`** keeps the day, the time of day and the hero's energy (full, and unused until 2c). **Save version 2**, with a migration from version 1: the first day, 06:00, a full bar, everything else as it was.
- **The clock runs** in the village, the countryside and houses. It stands still in dungeons, in conversations, in the item menu, while the hero is down, and behind the pause menu.
- **The light outdoors follows the hour:** peach at dawn, clear from 07:30, orange at 18:30, violet at 19:45, blue from 21:00. Houses and dungeons keep their own light.
- **Lamps are lit from 18:30 to 06:30** and dark by day. Once the night dims the picture each lamp has a warm pool. The hero has no pool of his own outdoors.
- **The HUD's corner** shows the day and the hour under the hearts, in steps of ten minutes.
- **At 02:00 a new day begins** where the hero stands, with a short dark screen and a line of words. No penalty.
- **Tools:** the screenshot tool takes every shot at noon unless it names an hour, and has seven new shots round the clock (95 in all); the playtest tool takes an hour (`-- village 19:30`) and has a scenario that starts in the village.

**Checked**
- 406 tests in 57 suites pass (+19: `tests/core/time/day_clock_test.gd`, `tests/autoload/day_test.gd`, `tests/world/day_test.gd`). Three older tests that looked at the village's light now say what hour they mean. Import and boot clean.
- **Old saves:** a real version 1 save from the whole-game playtest loads with every flag, item, quest and heart as it was; a finished version 1 save is still finished; a save from a later version is refused.
- **Mutation checks:** five deliberate bugs in runtime code, each caught, files restored: the clock running on past the day's end, a span over midnight never true, the clock running in dungeons, an old save waking with no energy, the hero carrying a pool of light outdoors at night.
- **Frame cost** in the village, noon and night turn about in one run: 2.94 ms and 306 draw calls at noon, 3.54 ms and 321 at night (the lamps' pools and glows). The four areas measured at each step are unchanged in draw calls.
- Screenshots: all 95 taken. Looked at closely: the village at dawn, noon, dusk, nightfall and night; the North Fields at 01:00; a house at night.

**Known issues and limits**
- Not tried in play. **Whether fourteen minutes is the right length of day is for a playtest to say.**
- **The day ends where the hero stands.** The home, the bed and waking there are 2b; what collapsing costs is 2c.
- **Nothing else knows the hour yet:** the shop, the villagers and the monsters are the same day and night (2e).
- **A lamp's picture is the same lit or unlit:** its glass is yellow at noon. Only its light goes out.
- **Windows don't glow at night** (2e), so a house at night is a dark shape beside a lamp.
- **A house's light doesn't change with the hour:** indoors it looks the same at noon and at midnight.
- **A new game starts in peach light,** for the first hour and a half of the day (about a minute).
- The pause menu's "Time played" is still real time played, not the day.

## 2026-11-12 — P2b: home and sleep (built; not yet tried in play)

Plan: `docs/progress/P2-plan.md` (the second of P2's five steps).

**Built**
- **The hero has a home:** the thatched cottage west of the weaver's has a door in its front wall, and a one-room inside (a new area, `home`, baked like the other houses): a bed against the west wall, a hearth, a candle, a cupboard, shelves, a table and chair, a plant and a stool.
- **Sleeping:** face the bed and press E. "Sleep until morning" starts the next day at 06:00 with full hearts and full energy, and saves the game; "Not yet" changes nothing. He can sleep at any hour. The bed's words are a conversation in data, and sleeping is a new effect a conversation can have (`sleep`).
- **At 02:00 he wakes by his bed** on the next day, in place of where he stood. The game is saved, and a line says he stayed up too late. His hearts are as they were and nothing is lost.
- **Tools:** a playtest scenario that starts at home (`-- home 21:00`), and four new screenshots (99 in all): the cottage's door, its inside, the bed's question, a morning.

**Checked**
- 413 tests in 58 suites pass (+7: `tests/world/home_test.gd`, and two in `tests/autoload/day_test.gd`). Import and boot clean.
- **Hearthvale has exactly one more cell to walk to:** the doorway. The walls beside it and the house behind it are solid, as they were.
- **A bug found by the new tests and fixed:** after the day ended, the rest of that frame wrote the hero's old place over where he was headed, so he would have arrived in the village instead of by his bed.
- **Older tests updated:** the list of houses with doors, the tile shown at the cottage's doorway, the count of reachable cells (one more), the count of areas (one more), the count of exits (two more), and 2a's test of the day's end.
- **Mutation checks:** five deliberate bugs in runtime code, each caught, files restored: sleeping not mending his hearts, a night in bed not saved, the frame going on after the day ends, waking at the door and not by the bed, the bed's answer doing nothing.
- **Frame cost:** draw calls within a few of the last step (the village 325, Elder Bram's house 46, the keep 382, the cistern 231).
- Screenshots: all 99 taken. Looked at closely: the cottage's front before and after, its inside, the bed's question, the morning after.

**Known issues and limits**
- Not tried in play.
- **A new game still starts in the village square,** not in bed.
- **Nothing is lost by staying up until 02:00 yet.** The cost (half energy, a tenth of his coins) comes with energy, in 2c.
- **The hearth at home does nothing yet.** Cooking is 2d.
- **No sound for sleeping or waking.** The new sounds are 2e.
- **The bed's question has no name above it,** like a sign's words.
- **Staying up until 02:00 saves the game,** as sleeping does: the save never holds a day that has ended.
- The cottage looks like the weaver's from outside but for where it stands.

## 2026-11-12 — P2c: energy (built; not yet tried in play)

Plan: `docs/progress/P2-plan.md` (the third of P2's five steps).

**Built**
- **The energy rules are data** (`data/rules/energy.json`, read by `EnergyRules` in `core/energy/`, pure): a bar of 100; sprinting 0.25 a second, a swing or a shot 0.5; tired under 25; no sprinting under 10; collapsing leaves half a bar and takes a tenth of his coins, 30 at most.
- **The bar is on the HUD,** under the hearts: green, then amber, then red where he tires.
- **Sprint costs energy** for each frame in which he actually runs. Holding the key while standing costs nothing.
- **A swing and a shot each cost 0.5.** A bomb is free. Walking and talking are free.
- **Tired (under 25):** he walks and runs at 85% of his speed, and the sword's cooldown is 1.3 times as long. **Worn out (under 10):** he can't sprint. A line of words says so as each happens.
- **At zero he collapses:** he lies where he fell for a moment (nothing can hurt him), then wakes by his bed the next morning with half his energy and a tenth of his coins gone. It can happen in a dungeon; what he did there stays done.
- **Staying up until 02:00 costs the same.**
- **Tools:** the playtest tool takes a starting energy (`-- village energy=12`); two new screenshots (101 in all): the bar when tired, and a collapse.

**Checked**
- 427 tests in 60 suites pass (+14: `tests/core/energy/energy_rules_test.gd`, `tests/world/energy_test.gd`, two in `tests/autoload/day_test.gd`). They passed on the first run. Import and boot clean.
- **Hearts are never touched:** every energy test ends by checking them, and a planted bug that made collapsing cost a heart was caught three times over.
- **Rested, nothing changed:** at 25 energy or more the walk is 72 pixels a second, the run 120, and the sword's cooldown what the weapon's data says.
- **Older tests updated:** 2b's test of staying up (it now costs a coin of twelve), and the HUD's test that said the bar was hidden.
- **Mutation checks:** five deliberate bugs in runtime code, each caught, files restored: tired already at a quarter, no limit to the coins lost, sprint draining while standing still, being hurt while lying collapsed, collapsing costing a heart.
- **Frame cost:** draw calls within a few of the last step (the village 327, Elder Bram's house 46, the keep 382, the cistern 231).
- **The player's own save was not touched** by the tools: the collapse shot stops the way home before anything is saved.
- Screenshots: all 101 taken. Looked at closely: the bar full, tired and empty; the collapse in the square.

**Known issues and limits**
- Not tried in play. **The numbers are starting values:** whether sprint still feels free enough, and whether a long fight drains him unfairly, are for a playtest to say. They are one file to change.
- **Nothing gives energy back but sleep** until food arrives in 2d. For this one step the bar only goes down during a day.
- **No sound** for tiring or collapsing (2e).
- **The pause menu doesn't show energy** as a number; the bar is the only place it shows.
- **A collapse in the middle of a boss fight sends him home:** the fight starts again next time, as after a fall.
- **Under 10 energy the only way to zero is swinging or shooting** (twenty swings), since he can no longer run.
- Hoeing and watering costs are in the plan but not in the data yet: they come with the tools, in P3.

## 2026-11-13 — P2d: food and cooking (built; not yet tried in play)

Plan: `docs/progress/P2-plan.md` (the fourth of P2's five steps).

**Built**
- **Food is a kind of item** (`food`, with the energy and hearts it gives in its data; `Food` in `core/inventory/`, pure). Five items: wild berries (8 energy), mushrooms (6), bread (30), cherry blossom tea (15), and cherry blossoms, an ingredient.
- **Eating from the item menu:** food is listed under the bow and the bombs with what it gives. Choosing it eats one. A hero with a full bar and nothing to mend isn't hungry, and nothing is used.
- **Ten things to gather,** each back the next morning (`ForageSpot`, a pickup that grows back): berries in the North Fields (two) and the South Field, mushrooms in the Old Wood (four), fallen blossom in front of three of Hearthvale's cherry trees. They block nothing.
- **Bread at Tilda's,** 6 coins a loaf.
- **Recipes are data** (`data/recipes/`, a new kind, with a schema). One so far: cherry blossom tea from three blossoms.
- **Cooking at the hearth at home:** it lists every recipe with what it needs, as a conversation built from the recipes (`Cooking`, `core/cooking/`, pure). No new screen.
- **Art:** five item pictures and six forage pictures, painted in the sprite tool.
- **Tools:** a playtest scenario at the hearth (`-- kitchen`); five new screenshots (106 in all).

**Checked**
- 439 tests in 62 suites pass (+12: `tests/core/cooking/cooking_test.gd`, `tests/world/food_test.gd`). Import and boot clean.
- **Where the hero can walk is unchanged:** no Height layer changed (the four areas were re-baked and their tile data came out identical), and no forage spot occupies a cell.
- **Found and fixed on the way:** a spot beside a tree's trunk lay under its crown, and the crown stayed faded for it. Five spots moved; a test now checks that none lies under a crown.
- **Older tests updated:** the list of item ids, the shop's answers (bread is the third), who may have words that aren't a file (the hearth), and the sprite sheets with named frames.
- **Mutation checks:** five deliberate bugs in runtime code, each caught, files restored: a full hero still eating, eating not using up the food, what is gathered never growing back, cooking not using the makings, the item menu not listing food.
- **Frame cost:** draw calls within a few of the last step (the village 330 with its three blossom patches, Elder Bram's house 46, the keep 382, the cistern 231).
- Screenshots: all 106 taken. Looked at closely: the item menu with food, the hearth's list, berries in the North Fields, mushrooms in the Old Wood, the new pictures enlarged.

**Known issues and limits**
- Not tried in play. **How much there is to eat is a guess:** about a hundred energy a day lies about for someone who walks to all ten spots, and bread is 6 coins. Both are data.
- **Only one recipe can be cooked,** since the other meals need crops (P3). The hearth's list is short until then.
- **None of this step's food mends hearts.** The rule is built and tested with made-up meals; the first real one is mushroom soup, in P3.
- **The "Carrying" line on the HUD gets long** with food in the pack, and is cut off at the box's width.
- **No sound of its own for eating or cooking:** eating uses the heart's chime (2e).
- **Standing at the hearth, the hero hides the fire,** as he hides whoever he talks to from the south.
- A berry bush is small and dark on dark grass; it may be easy to miss.
- Eating is from the menu only: there is no button to eat what is in hand.

## 2026-11-13 — P2e: hours and night (built; not yet tried in play). P2 is complete.

Plan: `docs/progress/P2-plan.md` (the last of P2's five steps).

**Built**
- **Hours are data** (`data/rules/hours.json`, read by `Hours` in `core/time/`, pure): when a place's door is open, what is said at it when it is shut, and when villagers who stand outdoors are out.
- **Tilda's shop is open from 08:00 to 18:00.** Outside those hours the door from the village is shut and solid. Walking up to it, or trying it, says "Tilda's shop is shut. She opens at 08:00 and closes at 18:00." Once inside he can always buy and leave.
- **Villagers who stand outdoors go home at 20:00 and are back at 06:00:** Farmer Oda, Pip, Guard Rolf and the shepherd Edda. Gone, they can't be seen or talked to and their cell is free. Nobody leaves in the middle of a conversation, and nobody comes back onto the hero. Bram, Wenna and Tilda are indoors and stay.
- **Monsters met outdoors at night** (20:00 to 06:00) have half as much health again (rounded up), are 15% faster, see 30% further and drop coins twice as often. The numbers are data (`data/rules/night.json`, read by `NightRules` in `core/enemies/`, pure). It is decided as the area loads. Not in dungeons, and never bosses. They hit no harder.
- **Night monsters show pale in the dark:** they are drawn unshaded in a pale violet.
- **House windows are lit** from dusk to dawn, with the lamps: sixteen panes in the village (`WindowGlow`). For show.
- **A night tune** (`night`, the fifth song) plays out of doors at night in place of the area's own. Houses and dungeons keep theirs.
- **Three new sounds:** eating, collapsing, and a cock-crow when a new day begins (after sleeping, and when he wakes at home after a day that ran out).
- **Tools:** three new screenshots (109 in all): the shut shop, monsters at night, lit windows.

**Checked**
- 461 tests in 65 suites pass (+22: `tests/core/time/hours_test.gd`, `tests/core/enemies/night_rules_test.gd`, `tests/world/night_test.gd`). No older test needed changing. Import and boot clean.
- **Where the hero can walk by day is unchanged:** no map was re-baked. The only cells that change are the shop's doorway (solid while shut) and the villagers' own cells (free while they are away).
- **Combat is unchanged by day and in dungeons:** a test loads the South Field by day and a cellar at 23:00 and finds every monster as its data says. At night, damage, knockback and timings are still the data's own.
- **Found on the way:** with a tint alone, night monsters were harder to see than by day; and a shut door that could be stepped into left him standing in the doorway. Both changed before the tests were written (see `docs/DECISIONS.md`).
- **Mutation checks:** five deliberate bugs in runtime code, each caught, files restored: a place the rules don't name being shut, night health rounded down, villagers coming back onto the hero, night monsters in dungeons, the tune asked for again every minute (which would cut off a boss's).
- **Frame cost:** draw calls within one of the last step (the village 331, Elder Bram's house 46, the keep 382, the cistern 231). The village at night is 326 against 316 at noon, lamps and windows together.
- **The player's own save was not touched** by the tools or the tests (the night tests use slot 985).
- Screenshots: all 109 taken. Looked at closely: the shut shop at 19:00, the village at 21:30 and 23:30 (windows lit, nobody out), the South Field at 22:00 and the North Fields at 01:00 (pale monsters, no shepherd).

**Known issues and limits**
- Not tried in play. **A whole day from waking to sleeping has not been played by anyone yet**: that is the one line of P2 still open.
- **Villagers vanish at 20:00 and appear at 06:00** where they stand. Nobody walks home.
- **A quest that needs Oda, Pip, Rolf or Edda waits for morning.** Nothing says where they have gone.
- **Nightfall changes nobody already there.** Staying in a field from 19:00 to 21:00 keeps its day monsters; leaving and coming back brings the night's. The same the other way at dawn.
- **The night's numbers are starting values** (one file): whether three hits on a slime and faster bats are fair on a tired hero is for a playtest to say.
- **Night monsters look pale rather than fearsome,** and by daylight (one met at 05:00 and still there at 07:00) they look washed out.
- **Windows are lit from 18:30,** an hour and a half before the light goes: they show as bright panes in daylight.
- **The shop says its hours only at the door.** No sign shows them, and Tilda doesn't mention them.
- **At 18:00 a hero inside the shop is not asked to leave,** and can buy all night.
- The night tune is short (27 seconds) and loops.
- Still open from earlier steps: Elder Bram's fire shows above his head; the hero's head hides whoever he talks to from the south; the heading face has no small letters.

## 2026-11-13 — P3a: the plot and the tools (built; tried in play by the user: "feels right")

Plan: `docs/progress/P3-plan.md` (the first of P3's three steps: 3a the plot and the tools, 3b seeds and crops, 3c the shop's list and the meals).

**Built**
- **The plot:** eighteen cells of soil (6 by 3) in Hearthvale, between Tilda's shop and the well. It is drawn over the grass (`FarmPlot`); the hero walks over it as before.
- **The farm's rules are data** (`data/rules/farm.json`, read by `Farm` in `core/farming/`, pure): the plot's size, and how many dry mornings wither a crop (for 3b). Hoeing (2) and watering (1) joined the energy rules.
- **Two tools,** lying in the hero's cottage by the door: the hoe and the watering can. They go on the item button from the item menu.
- **The hoe** tills the bare cell he faces: 2 energy.
- **The watering can** waters the tilled cell he faces: 1 energy and one pour of ten. Facing the well or the pond it fills, for nothing. It starts empty.
- **A tool with nothing to do says why and costs nothing** (`ToolUse`, pure): off the plot, soil already tilled, soil already wet, bare soil under the can, an empty can, a full can at the well.
- **Each morning the watered soil is dry again.** Tilled soil stays tilled.
- **Save version 3,** with a migration from version 2 (an untouched plot).
- **Art:** soil (bare in two kinds, tilled, watered) and three item pictures (hoe, can, a drop of water), painted in the sprite tool. The tool's picture dips over the cell it works; the hero uses his swing pose.
- **Sound:** the hoe, a pour, the can filling.
- **Tools:** a playtest scenario at the plot (`-- farm`); six new screenshots (115 in all).

**Checked**
- 492 tests in 69 suites pass (+31: `tests/core/farming/farm_test.gd`, `tests/core/farming/tool_use_test.gd`, `tests/world/farm_test.gd`, `tests/autoload/farm_save_test.gd`). Import and boot clean.
- **Where the hero can walk is unchanged:** no map was re-baked (the village scene gained one node; its Height layer is the same data). A test walks him across all six cells and down through all three rows.
- **Old saves:** a real version 2 save (written before the format changed) loads with an untouched plot and everything else as it was; the two version 1 saves still load, a finished one still finished.
- **Hearts are never touched:** tilling the whole plot costs 36 energy and no heart.
- **Older tests updated:** the list of item ids (three more), and two lines that named save version 2.
- **Found on the way:** straight across the road from the hero's door the shop's roof hid half of the third row, so the plot is one house further east (see `docs/DECISIONS.md`). And a function named `is_tool` clashed with one every script has; it is `is_farm_tool`.
- **Mutation checks:** five deliberate bugs in runtime code, each caught, files restored: soil that never dries, an empty can that still waters, watering that uses no pour, hoeing that costs no energy, a version 2 save loaded without its migration.
- **Frame cost:** draw calls within two of the last step (the village 333 with the plot, Elder Bram's house 46, the keep 382, the cistern 231).
- **The player's own save was not touched** by the tools or the tests (the save tests use slot 984).
- Screenshots: all 115 taken. Looked at closely: the bare plot; rows tilled and watered; the hoe at work; the tools on the cottage floor; the item menu; the can filling at the well.

**Known issues and limits**
- **Tried by the user on 2026-11-13** (the `farm` scenario): hoeing and watering "feel right", so the numbers stand. Tilling all eighteen cells is 18 strokes and 36 energy; watering them all is 18 pours, so two trips to the well, and 18 energy. Finding the tools at home and a whole day with the farm in it were not part of that try.
- **Nothing grows yet.** For this one step the plot can only be dug and wetted (3b brings seeds).
- **The plot is not straight across from the hero's door** but one house east, in front of the weaver's (the reason is above).
- **The bed of soil has a hard, square edge.** It reads as dug, but it is plainer than the paths' soft edges.
- **The hero swings an empty hand:** the tool shows over the cell, not in his grip.
- **No hint on the HUD** says which button works a tool, beyond the controls line ("Q: item").
- **Nothing says the tools are at home.** A new player finds them by walking in; an old save's hero has to go and look.
- **The hoe can't undo its work,** and nothing else can: a tilled cell stays tilled.
- **He can fill the can at any open water,** the stream in the North Fields too, though the plot is only in Hearthvale.
- The "Carrying" line is longer still with two tools in it.

## 2026-11-13 — P3b: seeds and crops (built; tried in play by the user: "feels right")

Plan: `docs/progress/P3-plan.md` (the second of P3's three steps).

**Built**
- **Crops are data** (`data/crops/`, a new kind, with a schema; read by `Crops` in `core/farming/`, pure): turnip (3 days), carrot (4), wheat (5), potato (5), pumpkin (8), each with its seed, what it gives and its two prices (for 3c).
- **Seeds** are items of a new type, `seed`. On the item button, one is planted in the tilled, empty cell the hero faces. Planting costs no energy.
- **A first pouch of five turnip seeds** lies in the cottage with the tools.
- **Growth** (`Farm`, pure): each morning a crop that was watered the day before grows a stage; an unwatered one has a dry morning, and two of those in a row wither it. Watering starts the count again. A ripe crop waits.
- **Picking:** facing a ripe crop, E puts it in the pack ("[E] Pick the Turnip") and leaves tilled soil. Facing a withered one, E clears it away. Neither costs energy. A full pack leaves the crop in the soil.
- **Crops never block:** he walks through the plot whatever grows there. The hoe leaves a planted cell alone.
- **The harvest is food:** turnip 7 energy raw, carrot 7, wheat 5, potato 8, pumpkin 22.
- **Saved** in the same version 3: a planted cell also keeps its crop, its stage and its dry mornings.
- **The item menu scrolls:** it shows five lines and says where the cursor is ("3/7 v").
- **Art:** thirteen crop pictures (three every crop shares, two of its own for each) and ten item pictures (five crops, five seed pouches), painted in the sprite tool.
- **Sound:** planting and harvesting.
- **Tools:** the `farm` playtest scenario has seeds of every crop; four new screenshots (119 in all).

**Checked**
- 520 tests in 73 suites pass (+28: `tests/core/farming/growth_test.gd`, `tests/core/farming/crops_test.gd`, `tests/world/crops_test.gd`, `tests/autoload/crop_save_test.gd`). The new ones passed on their first run. Import and boot clean.
- **Every crop was raised as a player raises it:** a test tills, plants and waters a cell for each crop from the item button, waters it each day, and finds each ripe on the morning its data says (3, 4, 5, 5, 8); then picks and eats each.
- **Where the hero can walk is unchanged:** a test walks him across a plot full of ripe pumpkins, and finds the farm as it was.
- **Saves:** a save made by step 3a (soil with nothing in it) loads as it is; the version 2 and version 1 saves still load; a crop the game doesn't know is left out and its soil kept.
- **Hearts are never touched:** the season in the test ends with full hearts.
- **Older tests updated:** the list of item ids (ten more). The heading test caught the menu's new count sitting above the box's rule; it moved to the bottom line.
- **Found on the way:** the item menu ran out of its box at seven lines (tools, seeds, two crops), so it scrolls now.
- **Mutation checks:** five deliberate bugs in runtime code, each caught, files restored: a crop growing unwatered, one dry morning withering a crop, a ripe crop withering, planting that uses no seed, a harvest lost when the pack is full.
- **Frame cost:** draw calls as the last step (the village 332, Elder Bram's house 46, the keep 382, the cistern 231).
- **The player's own save was not touched** by the tools or the tests (the tests use slots 982 and 983).
- Screenshots: all 119 taken. Looked at closely: the plot in the middle of a season (every crop growing and ripe, a seed, a sprout, a withered one); the prompt at a ripe turnip; the pouch on the cottage floor; the item menu with seven lines; all 23 new pictures enlarged.

**Known issues and limits**
- **Tried by the user on 2026-11-13** (the `farm` scenario, with tools and seeds in hand and the steps listed for him): raising a crop "feels right". **Whether a new player works it out untold,** starting from the pouch at home, is still unknown: nothing in the game says to till, plant and water, or that a crop needs water every day.
- **Seeds can't be bought until 3c.** In the real game the five turnip seeds at home are all there are for one more step.
- **Nothing shows which crops were watered today** but the colour of their soil, and nothing warns that a crop has had a dry morning.
- **Standing below a crop, the hero's head hides it** (he is two cells tall). The prompt says what is there.
- **Crops are small:** a cell each, drawn flat. Wheat and pumpkins fill their cells; a seed is a few pixels.
- **A ripe crop never spoils,** so a plot can be left ripe for as long as he likes.
- **The numbers are starting values:** the raw energies are mine (a third of the cooked ones in the plan, roughly), and all are data.
- **The wheat's picture as an item** looks more like a trident than a sheaf.
- The "Carrying" line is longer again with seeds and crops in the pack.

## 2026-11-13 — A still world, and interact on the mouse (the user's request; not yet tried in play)

Asked for between steps 3b and 3c: "get rid of the animations on the environment except the water animation", and "change the controls so move is the same but interact is mouse". No plan file; the decisions are in `docs/DECISIONS.md`.

**Built**
- **The scenery is still.** Gone: the wind in tufts, flowers, crops and washing (`SwayLayer`, deleted) and in tree crowns (their shader), petals in the air, specks in the air (`Motes`, deleted).
- **Kept as still pictures:** the mist over the Old Wood (it no longer drifts), chimney smoke (one frame of its four), the fallen petals round the cherry trees.
- **The water moves as before:** its tile's frames, its surface, and its reflections.
- **Interact is the left mouse button** (a gamepad's A is unchanged). E no longer does anything. The mouse is a button: where the click lands doesn't matter, and the hero still faces what he acts on.
- **A click is every menu's yes:** it answers a conversation and chooses in the item menu, the pause menu, the title and the ending. Enter still works where it did.
- **Every screen names the click:** the HUD's keys ("Click: talk / use"), its prompts ("[Click] Pick the Turnip"), the answer mark, and the help lines of the item menu, the pause menu, the title and the ending.
- **No screen takes the mouse for itself** (`MenuInput.let_clicks_through`), so a click anywhere reaches the game.

**Checked**
- 525 tests in 74 suites pass (+5 on balance: `tests/ui/mouse_test.gd`, one in the input map's test, one for the still scenery; the tests of the sway layer and the specks went with them). Import and boot clean.
- **Real clicks through a window** (a scratch script, since headless tests can't send them): a click over the HUD's corner starts a conversation, clicks answer it to its end, a click eats the bread under the item menu's cursor, a click resumes from the pause menu, a click on the title starts a game. All seven steps passed.
- **Nothing about play changed:** no map was re-baked. The tileset lost five lines (the smoke's animation) and no tile moved.
- **Mutation checks:** five deliberate bugs in runtime code, files restored. Four were caught: prompts naming E again, the mist drifting again, a shader on the trees again, petals in the air again. **One was not:** taking the HUD's call to `let_clicks_through` away changes nothing, because the HUD's own scenes already ignore the mouse. Taking it from the title or the ending is caught (their root would swallow the click). The HUD's call is a second guard, not the only one.
- **Frame cost:** the village is 19 draw calls down (313 from 332); Elder Bram's house 45, the keep 382, the cistern 231.
- **The player's own save was not touched** (the click check ran on slot 995 and removed it).
- Screenshots: all 119 taken. Looked at closely: the HUD's keys, the pause menu, the title, the Old Wood under its still mist.

**Known issues and limits**
- Not tried in play. Stillness can't be seen in a screenshot: that nothing moves but the water is checked by tests, not by eye.
- **What I left moving, as not "the environment":** the flicker of fires, lamps and torches; creatures (chickens, butterflies, fireflies); people breathing and blinking; pickups that bob; the title screen's stars and petals. Each is one line to still.
- **Still smoke over a chimney and a frozen lean in nothing** may look odd where motion used to explain the picture.
- **Every click interacts,** including the click that brings the window to the front.
- **The mouse can't point:** it can't choose a line in a menu or a cell in the plot. Menus still move with W and S.
- **The hint in a conversation is "[Click]"**, wider than "[E]" was.
- **E does nothing now.** If both were wanted, it is one entry in `tools/setup_input_map.gd`.
- The sway layer's room in the tree atlas (clear pixels to each side of a crown) is still there, unused.

## 2026-11-13 — The mouse, as the user wants it: left click uses, right click interacts (not yet tried in play)

The user tried the first version (interact on the left button) and asked for this instead: "attacking should be left click and using hoe and other items should be left click and similar to the controls in stardew valley and right click should be to interact with other characters and items". The still world needed no change. The decisions are in `docs/DECISIONS.md`.

**Built**
- **Right click interacts:** talks, reads, picks up, opens, harvests. (A gamepad's A is unchanged.)
- **Left click uses what is in hand** (a new action, `use_hand`; `AreaController.use_hand()`):
  - nothing on the item button: the sword;
  - the bow or bombs on it: those;
  - the hoe, the can or seeds on it: the tool when he faces his plot (or water, for the can), where it works or says why not; anywhere else, the sword.
- **The sword is a line in the item menu** when something else could be in hand. Choosing it empties the item button, so the left click swings again.
- **Space and Q still do the sword and the item,** whatever is in hand. Moving is unchanged.
- **Menus take either click as yes.** A conversation is answered with the right click or Enter, never the left: it swings the sword.
- **The screens say so:** "Left click: sword / item   Right click: talk / take" on the HUD (its box is a little wider), "[Right click] Pick the Turnip" in prompts, "[Right click]" in a conversation.

**Checked**
- 531 tests in 74 suites pass (+6: `tests/ui/mouse_test.gd` rewritten, the input map's test). Import and boot clean.
- **Real clicks through a window** (a scratch script): a left click facing a villager starts no conversation and a right click does; a left click doesn't answer and right clicks do; on open grass a left click swings the sword though the hoe is on the item button; facing the plot it tills; a left click chooses in the item menu, resumes from the pause menu and starts a game from the title. All nine steps passed.
- **A tool in hand doesn't leave him unarmed:** a test stands him in the South Field with the hoe on the item button, and a left click swings.
- **Mutation checks:** five deliberate bugs in runtime code, each caught, files restored: a tool that never gives way to the sword, water that is no work for the can, a left click that answers a conversation, choosing the sword putting it on the item button, the left click interacting.
- **The player's own save was not touched** (the click check ran on slot 995 and removed it).
- Screenshots looked at: the HUD's keys (the box fits both lines now), the answer mark, the prompt at a ripe turnip.

**Known issues and limits**
- Not tried in play.
- **No row of tools to pick from.** Farming games switch tools with number keys or the wheel; here it is still the item menu (Tab), so hoe, seeds and can are three trips to the menu. That was not asked for and is not built.
- **The pointer still doesn't matter:** he works the cell he faces, not the one under the pointer.
- **Facing the plot with a tool that has nothing to do, a left click says why and doesn't swing.** A monster standing on the plot could only be hit with Space; there are none in Hearthvale.
- **With the bow or bombs in hand a left click never swings the sword:** choose the sword in the menu, or press Space.
- **A left click facing a villager swings the sword at them** (it does them no harm).
- **The HUD shows no line for the sword in hand:** "Item:" is simply gone when the item button is empty.
- **Every left click costs a swing's energy** where there is nothing else to do with it, including the click that brings the window to the front.
- The hint box in the top right is wider and covers a little more of the screen.

## 2026-11-13 — A left click answers in a conversation (the user's correction; not yet tried in play)

The user tried the second version and said: "when speaking to another character selecting the text should be left click not right click".

**Built**
- **In a conversation the left click answers and reads on.** The right click, which starts a conversation, no longer answers one. Enter and a gamepad's A answer as before; Space never did.
- **The first 0.3 seconds of a conversation take no left click.** The left click is also the sword's button, and this keeps a swing made as words open by themselves (a boss's last) from skipping the first line.
- The mark in a conversation says "[Left click]".

**Checked**
- 532 tests in 74 suites pass (+1). Import and boot clean.
- **Real clicks through a window:** a right click starts a conversation; a left click at once answers nothing; a right click doesn't answer; left clicks then carry it to its end, and no sword is swung meanwhile.
- **Mutation checks:** five deliberate bugs in runtime code, each caught, files restored: a right click answering, a left click not answering, no wait for a swing as the words open, a wait that never ends, a wait not started again for a new conversation.

**Known issues and limits**
- Not tried in play.
- **Right click talks, left click answers:** two buttons for one conversation. It is what was asked for, and what farming games do.
- **A very fast left click after the right click is ignored** (under a third of a second).

## 2026-11-13 — P3c: the shop's list and meals (built; not yet tried in play). P3 is complete.

Plan: `docs/progress/P3-plan.md` (the last of P3's three steps).

**Built**
- **Tilda's shop is data** (`data/shops/tilda.json`, a new kind, with a schema; `Shop` in `core/shop/`, pure): her own wares and prices, that she sells seeds, that she buys crops. Seed prices and crop prices are the crops' own.
- **A buy-and-sell list** on the HUD (`ShopMenu`), in place of her one-line-per-ware conversation:
  - **Buy:** ten arrows 5 coins, three bombs 8, bread 6 (as before), and a seed of each crop: turnip 5, wheat 6, carrot 8, potato 10, pumpkin 20.
  - **Sell:** the harvest, one at a time: turnip 12, wheat 10, carrot 18, potato 24, pumpkin 60. She buys nothing else.
  - It shows the purse, stays open for as many deals as he likes, and says what the last deal was or why it couldn't be made (not enough coins, no room, a full purse).
- **Her conversation opens it:** "Let me see what you sell." and "I have crops to sell." (a new effect for conversations, `shop`). The eggs she is owed are still asked for there.
- **Five meals from crops, as recipes** (data only): roast turnip (22 energy), mushroom soup (35, half a heart), vegetable stew (60, one heart), pumpkin pie (80, two hearts), and bread from two wheat (30). Four new dishes, with pictures.
- **A conversation with many answers scrolls:** four show at a time, and the corner says where he is ("^ 5/7 v"). The hearth lists six dishes now.
- **Tools:** a playtest scenario at her counter (`-- market`); the kitchen scenario has crops to cook; the farm scenario has 30 coins; three new screenshots (122 in all).

**Checked**
- 550 tests in 78 suites pass (+18: `tests/core/shop/shop_test.gd`, `tests/world/shop_test.gd`, `tests/world/meals_test.gd`, `tests/world/farm_round_test.gd`). The new ones passed on their first run. Import and boot clean.
- **The roadmap's "done when" for P3:** one test takes the tools and the first seeds from the cottage, tills and plants five cells with the left click, waters them for three days, picks five turnips with the right click, eats one raw, roasts one at the hearth and eats it, sells two to Tilda through her conversation, and buys four seeds with the coins.
- **The prices are the GDD's:** a test reads every line of both lists.
- **A deal that can't be made changes nothing:** the game's whole state is compared before and after.
- **The meals give what the GDD's table says,** and each is worth more than its makings eaten raw.
- **Older tests updated:** the list of item ids (four more); buying bread, arrows and bombs (through the list now); the hearth's answers (six dishes).
- **Mutation checks:** five deliberate bugs in runtime code, each caught, files restored: a ware sold to an empty purse, a ware sold with no room to carry it, a crop sold for nothing, the clock running while the list is open, a long list of answers not scrolling.
- **Frame cost:** draw calls as before (the village 312, Elder Bram's house 45, the keep 382, the cistern 231).
- **The save format is unchanged:** coins and items were already saved.
- Screenshots: all 122 taken. Looked at closely: her conversation, the list to buy from with a deal made, the list to sell on, the hearth's dishes scrolled, the four dish pictures enlarged.

**Known issues and limits**
- Not tried in play. **Whether the farm pays for itself at a pace that feels right** is for a playtest: a turnip seed is 5 coins and sells for 12 after three days of watering; a pumpkin is 20 and 60 after eight. All are data.
- **Selling is one crop a click.** A plot of eighteen turnips is eighteen clicks; there is no "sell all".
- **She buys only crops:** not berries, mushrooms, meals or anything found.
- **Seeds are the only thing that isn't listed in her file:** they come from the crops, so a crop can't be kept off her list.
- **The list is worked with the keys and a click,** not by pointing: W and S move, A and D turn to the other list.
- **A conversation shows four answers** even where five would fit under a one-line question.
- **Bread can be bought for 6 coins or baked from two wheat that sell for 20:** baking it is a loss in coins. The numbers are the plan's.
- **The hearth's dish names are long:** "Vegetable Stew (1 Potato, 1 Carrot, 1 Turnip)" nearly reaches the corner's count.
- **P4 is not started,** and is to be proposed first.

## 2026-11-13 — P4 approved; P4a: the story over days (built; not yet tried in play)

Plan: `docs/progress/P4-plan.md`. The user approved the proposal as written ("Approve as written"): all ten
decisions stand as recommended. Section 10 of the plan is this step's own list.

**Built**
- **A main quest, "A Place of Your Own",** in the quest log from the first morning (`data/quests/a_place_of_your_own.json`). It begins by itself and says so at the top of the screen. Six stages, each with words that say where to go:
  1. the cottage, and the hoe, the can and the seeds inside its door
  2. the plot, and how to till and plant ("Choose the hoe with Tab and left click to till a patch")
  3. Elder Bram, in the blue-roofed house (and: water it each morning, the can fills at the well)
  4. the Old Keep, by way of the sword in the training yard
  5. home, to sleep: the chapel's bars lift at dawn
  6. the crypt
- **Elder Bram welcomes a newcomer.** Before a first seed is planted he says which cottage and plot are the hero's and sends him to settle in, and says nothing of the keep. After it he speaks as before, and his promise now also has the chain taken off the keep's gate.
- **The keep's gate in the Old Wood is chained** until he gives that word: a gate of planks under a chain and a padlock. Walking up to it, or trying it, says "The keep's gate is chained shut. Elder Bram in Hearthvale has the say over it."
- **The crypt's bars lift at dawn on the day after the Warden falls,** not at once. Sleeping, staying up until 02:00 and collapsing all bring that dawn.
- **Words changed to match:** Bram's promise ("I will have the chain taken off the keep's gate"), his tale ("the bars will not hold past dawn"), Guard Rolf's two answers about the chapel door, the keep's closing words ("By dawn they will be up"), and the title's line: "A cottage, a plot of soil, and lights over the old keep."
- **Three new things data may say,** each checked on load and in the schemas: a quest's `auto_start`, a conversation's `openings` (other nodes to begin at, with conditions), and the condition `days_since` (so many dawns since a flag came true).
- **A new kind of door,** `chained`: opens on a flag like a shutter, with words of its own.
- **Save version 4,** the one change of format for all of P4: the day each flag came true, a tally (crops picked, counted from now on), and places for skill points and friendship that stay empty until 4b and 4c. A version 3 save loads with those empty and past the story's gates: its first crop counts as planted, the keep's gate is open, and the crypt's bars are up if its Warden had fallen. No promise to Bram is added to it.
- **The quests chime once** when a quest runs through several stages at once (an old save catching up, a playtest scenario).
- **Tools:** playtest scenarios `bram` (in his house, the first crop in), `gate` (below the chained gate) and `rest` (by the chapel on the day the Warden fell); the older scenarios start past the gates; six new screenshots (128 in all); the older ones of Bram, the keep's gate and the chapel's door now show the new story.

**Checked**
- 582 tests in 81 suites pass (+32: `tests/core/story/story_gates_test.gd`, `tests/autoload/story_save_test.gd`, `tests/world/story_days_test.gd`, and more in the condition, quest and conversation suites). Import and boot clean.
- **The plan's "done when":** a new game has the quest and it moves on through the first day and to the end; Bram's welcome and his words after the first crop; the gate holds, says why, and opens on his word; the bars are down on the day the Warden falls (even at 01:30) and up after a night; the three new things in data are refused when wrong; a real version 3 save, made inside the keep before the format changed, loads past the gates with its day, plot, pack, flags and quest as they were; versions 1 and 2 still load.
- **Nineteen older tests failed first,** all for the reason the step exists: they walked into the keep, or had Bram speak of it, on a new game. Each now says what it stands on (Bram's word, a first crop), or expects the main quest in the log.
- **Mutation checks:** five deliberate bugs in runtime code, each caught, files restored: the bars lifting on the day the Warden falls, a chained gate that is never shut, an old save not put past the gates, the quests not hearing the dawn, Bram never welcoming a newcomer.
- **Frame cost:** draw calls as before: Elder Bram's house 45, the keep 382, the cistern 231, the village 313 (312 before, which is within what the village's creatures vary it by; it reads 314 for the three and a half seconds the quest's notice shows).
- Screenshots: all 128 taken. Looked at closely: the gate chained and unchained (enlarged), Bram's welcome, his tale, the quest log on a new game and at each of the seven stages (the words fit the box), the log with four quests, the title.

**Known issues and limits**
- Not tried in play. **Whether the first day reads clearly to someone new, and whether the story runs to six to eight days,** is for a playtest. The plan proposes a whole-game playtest now, before 4b.
- **The notice of the quest shows for a few seconds at the top of the screen** when a game begins. A player who misses it has the quest log (Esc, Quests); nothing else on screen points there.
- **The journal names keys in its words** ("Tab", "left click"). They are data, not read from the input map.
- **The quest log's list holds five lines,** and four quests and "Back" now fill it. 4d adds four side quests: the list will need to scroll, as the item menu and the shop do.
- **Refusing Bram ("Not me.") leaves the gate chained** until the player goes back and promises. The journal's line is "Hear Elder Bram out".
- **The gate says its words each time he steps up to it,** as the shut shop does.
- **An old save says "Quest updated: A Place of Your Own"** the first time it loads, as the quest catches up.
- **The main quest counts on the ending screen** among the quests finished. The ending's lines are redone in 4d.
- **A day is kept for every flag that comes true,** so a save is a little longer (a number a flag).
- **Skills and friendship have places in a save and nothing else:** nothing reads or changes them yet.
- **The chain is drawn in code,** like the game's other doors, not painted by an art tool.

## 2026-11-13 — P4b: skills (built; not yet tried in play)

Plan: `docs/progress/P4-plan.md`, section 11 (the second of P4's four steps).

**Built**
- **Three skills, five levels each,** with the numbers in data (`data/rules/skills.json`, a new set of rules with a schema; `Skills` in `core/skills/`, pure). Levels begin at 0, 10, 25, 50 and 90 points.
- **What raises them:**
  - combat: 1 for a monster beaten, 10 for a boss
  - farming: 1 for a cell tilled, 2 for a crop picked
  - cooking: 2 for a dish cooked
- **What a level does:** each level above the first takes a tenth off the energy of the skill's work, or adds a tenth to a dish.

| Skill | Level 1 | Level 2 | Level 5 |
|---|---|---|---|
| Combat: a swing, a shot | 0.5 | 0.45 | 0.3 |
| Farming: the hoe | 2 | 1.8 | 1.2 |
| Farming: the can | 1 | 0.9 | 0.6 |
| Cooking: a vegetable stew | 60 | 66 | 84 |

- **A level rising is said once,** at the top of the screen ("Farming rose to level 2."), with a chime of its own (a new sound, `skill`, made by the audio tool).
- **The pause menu has a line for them:** "Combat 3   Farming 4   Cooking 2".
- **The item menu and the words on eating say what a dish gives him now:** at the top level a stew reads "+84 energy, +1 heart".
- **A new effect for conversations and quests, `practise`** (a skill and a deed): it is how the hearth counts a dish.
- **Two small layout changes that came with it:** the pause menu's list sits six pixels lower, since its status is four lines now; the item menu is 24 pixels wider, so a dish's line with its hearts stays inside the frame (the stew's already poked out of it).
- **Tools:** `skills=<level>` after a playtest scenario's name; three new screenshots (131 in all).

**Checked**
- 611 tests in 84 suites pass (+29: `tests/core/skills/skills_test.gd`, `tests/autoload/skills_state_test.gd`, `tests/world/skills_test.gd`). Import and boot clean.
- **The plan's table, number by number:** a swing, a shot, the hoe and the can at each of the five levels, through the game itself (the left click, the item button), and a stew at each level.
- **Each deed gives its points once:** a slime beaten (and not a slime only hurt, nor one beaten twice), the Warden, a cell tilled (and not a stroke that tills nothing), a crop picked (and not one that isn't ripe), a dish cooked at the hearth (and not one he hasn't the makings of).
- **The stroke that raises farming costs the old price,** and the next one the new.
- **A rise is said once:** one notice and one chime, and nothing more at later points or past the top level.
- **Hearts are untouched:** a stew mends one heart at any level; the sword's numbers are the item's own.
- **Sprinting costs what it did** at every level.
- **Saves:** skill points go through a save (still version 4); a real version 3 save starts every skill at level 1.
- **Two older tests failed first,** both in the farm's suite: they till twelve and eighteen cells, which now reaches level 2 on the way. They say so now (ten pours cost 9; the whole plot costs 34.4, not 36).
- **Mutation checks:** five deliberate bugs in runtime code, each caught, files restored: a level coming a point late, work costing the same at every level, a level said to rise at every point, a boss worth no more than a slime, a good cook getting more out of raw food too.
- **Frame cost:** draw calls as before (the village 313, Elder Bram's house 45, the keep 382, the cistern 231).
- Screenshots: all 131 taken. Looked at closely: the notice as a level rises, the pause menu with its new line (and the gap under it), the item menu of a cook at the top level, before and after it was widened.

**Known issues and limits**
- Not tried in play. **Whether a tenth a level is felt** is the plan's own doubt: it shows over a day's work, not in one swing. If it reads as nothing, the plan's next thing to try is a named perk a skill.
- **Tilda's bread is richer for a good cook too.** It is the same item as the bread the hearth bakes, and an item does not remember who made it. So is tea, and any dish a quest might give.
- **Combat can be raised by going back to the same monsters:** they come back when an area is entered again. Ten slimes are level 2; ninety are level 5. The numbers are data.
- **The pause menu shows levels only:** not the points, nor how far the next level is.
- **A level is said in the same place as a quest's news,** so if both happen at once the later one shows.
- **The notice is hard to read over a thatched roof** (pale yellow on straw), as a quest's is.
- **Points keep counting past the top level** and do nothing there.
- **Watering and planting give no points:** the plan names tilling and picking only.
- **A dish's energy is shown rounded** ("+24 energy" for 24.2); the bar takes the exact number.

## 2026-11-13 — P4c: friendship and gifts (built; not yet tried in play)

Plan: `docs/progress/P4-plan.md`, section 12 (the third of P4's four steps).

**Built**
- **The seven villagers are data** (`data/villagers/<id>.json`, a new kind with a schema): a name, the conversation that is theirs, what they like, and what they say to a gift they like and to any other. No scene changed: the game knows who is spoken to by the conversation.
- **Friendship is twenty points a villager, a mark for every four,** with the numbers in data (`data/rules/friendship.json`; `Friendship` in `core/friendship/`, pure):
  - the first talk of a day: 1 point
  - a gift they like: 3 points; any other: 1
  - one gift a villager a day
- **What can be given:** food and what is cooked with (cherry blossoms). Not tools, seeds, coins, keys or anything else.
- **Giving:** where a villager's conversation begins it gains the answer "I brought you something.", when a gift can still be given that day and he carries one. It opens a list of what he carries ("A gift for Pip"); he picks one thing, it is given, the villager says their words, and the list closes. No conversation file was changed.
- **What each villager likes** is the plan's table: Elder Bram stew and tea, Wenna blossoms and tea, Tilda pumpkin pie and wheat, Farmer Oda bread and pumpkin, Pip berries and pumpkin pie, Guard Rolf bread and mushroom soup, Shepherd Edda mushroom soup and carrots.
- **A mark gained is said once,** at the top of the screen ("Pip: friendship 1 of 5."), with a chime of its own (a new sound, `friend`).
- **A "Friends" page in the pause menu,** beside "Quests": every villager by name with five small blossoms, in bloom for each mark, and the line "Talk to them each day, and bring a gift they like."
- **A new effect, `gift`** (a villager): it opens the list when the conversation is over, as `shop` does.
- **Tools:** a playtest scenario beside Pip with a pack of food (`-- gifts`); four new screenshots (135 in all).

**Checked**
- 638 tests in 87 suites pass (+27: `tests/core/friendship/friendship_test.gd`, `tests/autoload/friends_state_test.gd`, `tests/world/friends_test.gd`). Import and boot clean.
- **The plan's numbers:** a talk 1 point, once a day for each villager; a liked gift 3 and another 1; a second gift the same day is not given and stays in the pack; four points a mark, five marks, twenty points and no more.
- **The answer is there only when it would do something:** not with only tools, seeds and coins in the pack, not after that day's gift, not at the hearth or a sign; and only where the conversation begins.
- **No conversation file is changed:** Pip's data in the registry is compared before and after.
- **It works where conversations differ:** Elder Bram's welcome to a newcomer (another opening), Tilda's four answers (it scrolls, and her own list still opens).
- **A mark is said once:** one notice and one chime; a full friendship gains nothing more, though a gift is still taken.
- **The clock and the hero wait** while the list is open; leaving it gives nothing and keeps the day's gift.
- **Saves:** friendship goes through a save (still version 4), with the days of the last talk and gift; a real version 3 save has no friends.
- **Three older tests failed first:** two counted the pause menu's lines (six now), and one listed Elder Bram's answers for a hero who carries turnips and bread.
- **Mutation checks:** five deliberate bugs in runtime code, each caught, files restored: every talk worth a point, any number of gifts a day, any gift worth as much as a liked one, the answer that gives always there, a hoe that can be given.
- **Frame cost:** draw calls as before (the village 313, Elder Bram's house 45, the keep 382, the cistern 231).
- Screenshots: all 135 taken. Looked at closely: the answer in Pip's conversation, the list, a gift he likes with the mark's notice, the Friends page.

**Known issues and limits**
- Not tried in play. **Whether the marks come at a pace that feels right** is for a playtest: with a liked gift and a talk every day a mark takes a day; by talk alone four days. Both numbers are data.
- **Friendship opens nothing yet.** The side quests, the recipes and the presents are step 4d, and so are the condition and the effect that would let data ask for marks or give friendship.
- **Nothing in the game says what a villager likes** before the first gift: their words on receiving one are the only sign. The Friends page lists marks, not likes.
- **The Friends page shows all seven from the start,** including those not yet met.
- **A gift at a full friendship is still taken,** for no gain.
- **Villagers who stand outdoors are away from 20:00 to 06:00,** as before: Oda, Pip, Rolf and Edda can't be talked to or given anything then. Bram and Wenna are indoors at all hours; Tilda's door is shut after 18:00.
- **The gift list is its own script,** in the shape of Tilda's, not her list reused: hers is two tabs, a purse and many deals.
- **The pause menu's list is full** at six lines. Its note sits five pixels lower to leave a gap under them.
- **A mark and a quest's news share the line at the top,** so the later of two at once is the one shown.

## 2026-11-14 — P4d: side quests, recipes and the ending (built; not yet tried in play). P4's four steps are built.

Plan: `docs/progress/P4-plan.md`, section 13 (the last of P4's four steps).

**Built**
- **At two marks four villagers ask a favour,** each a quest in the quest format, offered in their conversation:

| Quest | From | Wants | Gives |
|---|---|---|---|
| A Pie for Pip | Pip | 1 pumpkin pie | 15 coins, and where a bomb opens the Old Wood's shrine |
| Rations for the Watch | Guard Rolf | 3 bread | 10 arrows and 20 coins |
| Seed Stock | Farmer Oda | 5 wheat | 3 pumpkin seeds |
| The Elder's Supper | Elder Bram | 1 vegetable stew | 30 coins, and more of Sir Aldric's tale |

  A favour can be put off ("Not just now.") and is asked again at the next talk. Each has an answer that reminds him what was asked, and one that hands it over.
- **At two marks three villagers teach a recipe:** Wenna berry jam (3 wild berries: 30 energy), Tilda carrot cake (2 carrots, 1 wheat: 50, half a heart), Shepherd Edda shepherd's pie (potato, turnip, mushroom: 70, one heart). The hearth lists them once they are taught; the six from before are known from the start. Three new dishes, with pictures.
- **At four marks each villager gives a present, once:** Elder Bram 40 coins, Wenna 25 coins, Tilda 3 potato seeds, Farmer Oda 3 carrot seeds, Pip 10 coins, Guard Rolf 30 coins, Shepherd Edda 4 wheat seeds.
- **Two new things data may say,** checked on load and in the schemas: the condition `friendship` (a villager, so many marks) and the effect `teach_recipe`; and a recipe may be marked `"taught": true`.
- **The quest log scrolls:** five quests at a time, with the corner saying where he is ("^ 6/9 v"). There can be eight quests now.
- **The ending has three more lines:** "Days 7", "Crops grown 31", "Friends 3 of 7". A friend is a villager at three marks or more (a number in the friendship rules).
- **Tools:** a playtest scenario on a late day (`-- late`: the sixth morning, the crypt open, every villager a gift short of two marks); five new screenshots (140 in all).

**Checked**
- 655 tests in 89 suites pass (+17: `tests/world/friends_open_test.gd`, `tests/world/whole_story_test.gd`, and more in the condition, cooking, friendship and ending suites). Import and boot clean.
- **Each favour, as a player meets it:** not asked at one mark; asked at two; put off, and the villager talks as ever; asked again; taken; the reminder; handed over; the plan's reward; and never asked again. All four.
- **Each recipe:** not known and not on the hearth's list before; taught once at two marks, with its notice; then listed, cooked from the plan's makings, and worth what the table says.
- **Each present:** nothing at three marks, the present at four, and nothing more at the next two talks. All seven.
- **The whole story in one test:** a new game through the chained gate, Bram's welcome and promise, the first crop, the harvest, the Warden's fall, the night the bars wait, Wenna's jam, Pip's pie and present, the Shade's fall, to the ending's lines ("Days 6", "Crops grown 5", "Friends 1 of 7", "Quests finished 2 of 8"). The two boss fights are stood in for by their flags; the rest is done as a player does it. What is said on the way (four marks for Pip, two for Wenna, farming's second level, the recipe) is said once each, in order.
- **Five older tests needed updating,** all lists by count: the game's items (three more), its recipes, its quests, and Elder Bram's openings.
- **Mutation checks:** five deliberate bugs in runtime code, each caught, files restored: a favour asked a mark late, the hearth listing what he was never taught, a recipe taught and not remembered, anyone with a mark counting as a friend, the quest log not scrolling.
- **Frame cost:** draw calls as before (the village 312, Elder Bram's house 45, the keep 382, the cistern 231).
- **The save format is unchanged:** a recipe known and a present given are flags.
- Screenshots: all 140 taken. Looked at closely: Pip's favour, Wenna's lesson with its notice, Tilda's present, the quest log with eight quests scrolled, the ending's six lines, the three new dish pictures enlarged.

**Known issues and limits**
- Not tried in play. **P4's "done when" is still open, and only a player can close it:** a whole game from the title to the ending, in six to eight days, with no help. The test above runs the story in six days, but a test knows where everything is.
- **Berry jam gives 30 energy where the plan's table says 20:** at 20 it was worth less than its three berries raw (24), against the rule since 3c that a dish beats its makings.
- **More of Sir Aldric's tale is new lore that the plan did not spell out:** he was a farmer of the valley, and the hero's cottage was his. Two lines of Elder Bram's, easily changed.
- **The effect that adds friendship was not built:** the plan lists it, and nothing in the plan's content gives friendship as a reward.
- **What friendship opens is in the conversations, not the villagers' data files,** where the plan's sketch had it.
- **A favour that is put off is the first thing the villager says at every talk** until it is taken. "Not just now." leads to their usual words.
- **At four marks the present comes before a favour not yet asked,** so a player who reaches four marks in one go meets the present first and the favour at the next talk.
- **Nothing on the Friends page says a villager has something to ask or to teach:** he finds out by talking to them.
- **The favours' makings are named in the words** ("a pumpkin and some wheat"), not read from the recipes: a recipe changed in data would need the words changed too.
- **The quest log's finished quests stay in the list,** so late in a game it holds eight lines and scrolls.
- **The main quest counts among "Quests finished"** on the ending screen, as before.

## 2026-11-14 — Playtest: the new first day (the user: "Feels right")

The user ran the whole-game playtest (`tools/playtest.gd -- full`) and, asked how the new first day felt, said it feels right. The run's log is `user://playtests/playtest_2026-11-14T00-28-26.log`; about four minutes of game time.

**What the run covered**
- **Continue, on the playtest slot's old save** (from before the pivot): it loaded as a version 4 save, standing in the crypt, and the main quest ran straight through its stages to the crypt. That is the migration on a real save.
- **Then a new game:** the cottage in 7 seconds, the hoe, the can and the seeds by 17, the first seed planted at 56. The main quest moved on at each.
- **After that:** the can filled, Farmer Oda's eggs carried to Tilda, the wooden sword, a piece of heart, Wenna's shuttle quest begun.
- No errors in the game's output.

**What it did not cover**
- Elder Bram after the first crop (where the quest pointed), the chained gate, the keep, a night's sleep, a gift, a skill rising, the ending.
- About nine minutes of real time passed while the game's clock moved 19 seconds, between planting and filling the can: paused, or a menu open.

**Ticked, on the user's word:** step 4a's line (the first day reads clearly), with a note of what was and was not reached.

**Still open, and the user's:** step 4b's line (a level is felt), 4c's (giving feels worth the food), 4d's (a whole game in six to eight days with no help), and step 3c's (a week of farming pays for itself).

## 2026-11-15 — Bug hunt (the user: "fix bugs you can find")

No roadmap step: a search for bugs across the finished game, and a fix with a test for each one found.

**How it was searched**
- **The tests as they stood:** 655 passed before anything was touched.
- **By reading:** the game's state, saving, the area's logic, conversations, quests, the shop, the farm, the menus, the pickups and the villagers' conversations, each looked at for what is lost, what can't be undone and what leaves the player with nothing to do.
- **By a monkey:** a scratch script that plays all twelve areas with random moves, clicks, menus, conversations, sleeps, saves and jumps to random places, in a late game with a full pack and in a new one. Three sessions of 144,000 frames each (about two hours of play in all), headless, at sixty frames a second of game time. It watched for script errors, a hero who can't move with nothing to explain it, empty stacks, and energy or hearts out of range. **It found nothing:** no errors, no stuck states.
- **The player's own save** (version 1, from 2026-11-09, in the Old Wood): a copy, loaded in a scratch slot. It loads, the main quest catches up to "keep", the gate is unchained, and he can walk in all four directions. The save itself was only read.

**Fixed**
- **A full pack swallowed things.** Gathering berries with twenty in the pack, picking up something lying in the world, or opening a chest whose arrows or bombs didn't fit: the thing was used up (the bush bare until morning, the chest open for good), nothing came of it, and the game said "You pick up the Wild Berries." Now each is left where it is until he can carry all of it, and he is told: "You have no room for the Wild Berries.", "You have no room for the Arrows in this chest." It is the rule a ripe crop, a dish at the hearth and Tilda's wares already had.
- **Running out of bombs or arrows left the left click dead.** With the last bomb set down, every left click said "Out of bombs." and the item menu would not open to put the sword back in hand ("No items yet."), so the left click could not attack again: only Space could. The player's own save has bombs on the item button and two bombs. Now a bow or bombs with nothing left give the click back to the sword, and the item menu offers the sword whenever something is on the item button, so it can be cleared. Q still says "Out of bombs."; with no sword at all the left click says so too, as before.
- **A save could put the hero inside a wall.** Loading put him on the cell he was saved on even if that cell had since become solid (the maps have been re-baked many times: trees planted, his cottage built). Now a saved cell that can't be stood on is passed over for the area's own start.
- **Esc did nothing in the item menu.** It leaves the shop's list, the gifts and every other menu; in the item menu only Tab did. Now Esc leaves it too.

**Checked**
- 666 tests in 90 suites pass. Eleven are new: four in `tests/world/full_pack_test.gd`, and others in the mouse, item, village, inventory and game-state suites. Each of the four world tests was seen failing before its fix. Import and boot clean.
- **Deliberate bugs:** five planted in runtime code, one at a time, each caught, files restored: the area taking a pickup that doesn't fit, a bush giving to a full pack, a chest opening into one, a spent weapon keeping the left click, a save putting the hero in a wall.
- **Not re-captured:** nothing drawn changed, so no screenshots were taken.

**Found and left, for the user to decide** (none is new; each is in an earlier entry's known issues)
- **News at the top of the screen replaces news:** a skill rising as a quest moves on, or a mark gained as a recipe is taught, shows only the later line. Beating the Warden is likely to do it. Showing both needs about ten tests changed.
- **A reward that doesn't fit is cut to what fits:** Guard Rolf's ten arrows to a hero with more than twenty, a present of seeds to one with twenty-seven. Conversations and quests give without asking for room.
- **A gift to a villager at five marks is taken for no gain.**
- **A save is written straight over the old one,** not to a second file first: a crash in the instant of writing could spoil it.
- **Continue does nothing, and says nothing, if the save can't be read** (a newer version, a damaged file).

**Known issues and limits**
- Not tried in play.
- **"No room" means no room for all of it:** a chest of fifteen arrows stays shut to a hero with twenty of thirty. He must use five and come back; nothing is ever lost in part.
- **A single thing he already has can't be taken again** (a second hoe): it stays where it lies. Nothing in the game gives one twice.
- **An empty bow still shows on the HUD** ("Item: Bow (Arrows x0)") while the left click swings the sword.
- **The monkey is a scratch script,** not part of the project: it lives outside the repository and was not kept.

## 2026-11-15 — Bug hunt, continued: news no longer replaces news (the user: "Yes, fix it")

The first of the things the bug hunt found and left: at the top of the screen the later of two pieces of news took the earlier one's place.

**Fixed**
- **News joins news.** A notice that comes while another is still up is shown on a line of its own under it. The Warden's fall now reads "Combat rose to level 2." and, under it, "Quest updated: A Place of Your Own"; a talk that gains a mark and a lesson reads "Wenna: friendship 2 of 5." and "New recipe: Berry Jam."
- **The same news isn't said twice,** so an old save's quest catching up through several stages is still one line.
- **Three lines at most:** a fourth pushes the oldest off.
- **Each new line gives all of it its full time again** (three and a half seconds), and then all of it fades together.
- The rule is `NoticeLines` (`core/menus/`, pure); the HUD keeps the lines and their time.

**Checked**
- 673 tests in 92 suites pass. Seven are new: four of the rule alone, and three on the HUD (news joining and going, the Warden's fall, a mark with a lesson), each of those three seen failing first. Import and boot clean.
- **Two older tests needed updating,** both in the quests suite: they start a new game and take a quest at once, so the game's own "New quest: A Place of Your Own" is still up and the quest's news is the line under it. They now say so.
- **Deliberate bugs:** four planted in runtime code, one at a time, each caught, files restored: news taking the place of news, the same news said twice, the oldest line never giving way, news whose time is up coming back with the next.
- **Two screenshots,** looked at closely: two lines in the keep's hall, three in Hearthvale at dusk. They sit under one another in the middle of the top of the screen, clear of the corner's box and the keys.

**Known issues and limits**
- Not tried in play.
- **Old news stays up longer when more comes:** a line three seconds old shows for three and a half more once a second line joins it.
- **The lines fade together,** not one by one.
- **Still hard to read over a thatched roof** (pale yellow on straw), as before: three lines cover more of one.
- **Still found and left,** from the entry above: a reward cut to what fits, a gift to a villager at five marks, a save written straight over the old one, and Continue saying nothing when a save can't be read.

## 2026-11-16 — The mouse in menus, and an item bar (the user's request of 2026-11-15; built, not yet tried in play)

Plan: `docs/progress/mouse-and-bar-plan.md`. The user's words, after playing: "the mouse should be the select on the pause menu and main menu and bombs and lets add a items menu at the bottom of the screen where the player scrolls or uses 123456789 buttons to select the item they want to use". Three things were asked back and answered: bombs are only picked in the bar; the pointer works in every menu; the bar holds what goes in hand, and food stays in the Tab menu.

**Built: the mouse points in menus**
- In every menu and list the line under the pointer is highlighted as the mouse moves, and a click chooses the line it is on: the title, the pause menu and its pages, settings, the food menu, Tilda's lists, the gifts, the answers in a conversation, the ending.
- **A click on no line does what it always did:** the highlighted line, or reading on in a conversation. A click on a line that can't be chosen (Continue with no save) does nothing.
- **The wheel is up and down in every menu,** which scrolls a list longer than its box.
- **At Tilda's a click on "Buy" or "Sell" turns to that list.** A click between the two names does nothing.
- In play nothing changed: the mouse is two buttons and the hero works the cell he faces.

**Built: the item bar**
- **A bar along the bottom of the screen** with a slot for each thing that can be in hand: his best sword, then the bow, bombs, hoe, watering can and seeds in the order he picked them up. The slot in hand is lit. A slot shows how many it has left: arrows for the bow, bombs, seeds, pours in the can.
- **The wheel steps through the slots,** round and round, **and the keys 1 to 9 choose one.** A gamepad's shoulder buttons step.
- **With more than nine things** (there can be ten) the bar shows nine and moves with the choice, with a small arrow at an end where it goes on. The number keys are for the slots showing.
- **The Tab menu is the food menu:** it lists only food. Its heading says so.
- **The last bomb or seed leaves the sword in hand:** the slot goes, and the item button is empty. An old save with bombs on the button and none left loads the same way (the player's own save was one).
- **Only his first thing for the item button goes into his hand as it is picked up.** With the sword in hand by choice, a thing bought or found waits in the bar.
- The prompt and the message line moved up to clear the bar; the keys in the corner have a third line ("Wheel or 1-9: choose what is in hand") and say "Tab: food"; the news at the top sits six pixels lower to clear them; the first quest's journal says to choose the hoe "with the wheel or a number key".

**Checked**
- 702 tests in 96 suites pass. Twenty-nine are new: the pointer in each menu (`tests/ui/pointer_test.gd`), the bar (`tests/ui/item_bar_test.gd`), the two pure rules (`MenuPointer`, `HandBar`) and the input map. Import and boot clean.
- **Twelve older tests needed updating:** they chose a tool or the sword in the Tab menu, expected "Items" as its heading, or quoted the journal's "Tab".
- **Deliberate bugs:** ten planted in runtime code, one at a time, each caught, files restored: the pointer a line off, a click choosing a line that can't be chosen, a click on an answer giving the highlighted one, the wheel stopping at the ends of the bar, the last bomb staying on the item button, the number keys ignoring where the bar stands, an old save keeping bombs he hasn't got, a thing picked up taking the sword out of his hand, a click on "Sell" not turning the list, the wheel changing hands while he talks. **Real mouse events through a real window** (window pixels, at three times the size): the wheel, two number keys, the pointer on four lines of the pause menu, clicks on Quests, Back, Resume and a food, all as expected.
- **Six screenshots,** looked at closely: the bar by the plot with the hoe in hand, the bombs in hand, ten things with the bar moved along, the pause menu with the pointer on "Friends", the food menu, the title with the pointer on "Settings".
- **The save format is unchanged.**

**Known issues and limits**
- Not tried in play. **Whether pointing feels natural, and whether the wheel and the numbers feel right in a fight and on the plot,** are the plan's two lines for the user.
- **The bar's slots can't be clicked:** the pointer is for menus, and a left click in play always uses what is in hand, wherever it lands.
- **The slots have no numbers on them.** They count from the left; with ten things the first showing is not always the sword.
- **The corner still says "Item: Hoe" and lists everything carried,** though the bar now shows what is in hand. The "Carrying" line is cut short with a full pack.
- **The keys box in the top right is a line taller.**
- **Tab no longer chooses a tool,** and nothing in the game says so but the keys box and the first quest's journal.
- **The wheel in a conversation moves the highlight;** it does not scroll a long line of words.
- **Hovering makes the cursor's tick** each time the pointer crosses onto another line.
- **A click on the tab row at Tilda's that misses both names does nothing,** by design; a click anywhere else off the list still makes the highlighted deal.
- **A bow with no arrows stays in hand** (it is still his), and the left click swings the sword; only bombs and seeds leave the bar when they run out.


**Played (2026-11-16):** the user played the whole-game playtest from the title (a new game, about five
minutes: the sword, the tools, Tilda's eggs, the first crop watered, Bram's promise) with no errors, and said
"everything feels good". The plan's two lines for the user are ticked. The run's log shows no fight, so the bar
in a fight was judged on the user's word.

## 2026-11-16 — The whole game played: P4's "done when"

The user played the whole game in the playtest mode (`-- full`, slot 901) in two sittings, from a new game to
the ending. From the run's log and its save:

- **The ending was reached on day 5,** in 63 minutes of play: the first crop and Bram's promise on day 2, the
  keep's bow on day 3 and its Warden on day 4, the crypt open at the next dawn and the Shade beaten on day 5.
  That is a day sooner than the six to eight the roadmap aimed at.
- **Beside the story:** three favours done (the eggs, the shuttle, the slimes), the ruin cellar and the
  cistern, four heart pieces, five crops picked, one dish cooked, gifts given to three villagers (Pip at
  five marks, Oda at four).
- **He fell seven times:** three in the keep (once to the Warden) and four in the crypt (twice to the Shade).
- **No script errors.** Three audio driver messages came from Windows changing the sound output.

**Limits of this as a test**
- The player was the user, who knows the game: "a new player, with no help" is still untried.
- The log has no record of how it felt; the user has been asked.

**Seen in the log, not looked into**
- After the Warden, the keep's door was passed six times in half a minute, several times within one second.
  It may be the player looking about, or the door sending him back.
- The second sitting began about a minute and a half before the first ended (the crop was planted and Bram
  spoken to twice): quitting does not save.

## 2026-11-16 — The keep's way out walked him back in

Looked into from the playthrough's log, at the user's word ("Yes, check it").

**The bug.** The way out behind the Warden's hall is taken going north, and sets the hero down in the Old
Wood one step south of the keep's gate, facing south. The W key, still held, walked him north through the
gate and back to the keep's entrance, within a tenth of a second. A simulation with the key held showed it
(the Old Wood at frame 20, the keep again at frame 27); the playthrough's log shows it six times.

**The fix.** A key held against the way he comes out of a door is not obeyed until it is let go
(`ArrivalHold`, pure, in `core/player/`; `PlayerController.held_back`, set by the area as he arrives through
an entry point). Every other way moves him at once, a slanting push keeps its sideways part, a new press of
the same key is obeyed, and a loaded game or a fall holds nothing back.

**Checked**
- 710 tests in 97 suites pass. Eight are new: five for the rule, three in `tests/world/keep_test.gd` (the
  held key does not take him back in and a new press does; a key held the way he comes out keeps him
  walking; a loaded game holds nothing back).
- **A deliberate bug:** with the area's line taken out, two of the new tests fail; restored.
- The simulation again, with the fix: holding W through the way out leaves him standing under the gate.

**Known issues and limits**
- Not tried in play.
- It changes how one moment feels at every door that turns the hero round: only the keep's way out does
  today. Walking on through an ordinary door with the key held is as it was.
- Quitting still does not save (seen in the same log; not looked into).

## 2026-11-16 — A fix round: saves, quitting, rewards, gifts

The user's request (`docs/progress/fix-round-plan.md`): five fixes in order, each with tests, no new content.
One commit a fix. The save format is unchanged (version 4).

**1. Safe saving**
- A save is written to `slot_1.json.tmp`, read back, and only a whole one is moved into the save's place; the
  save that was there is kept as `slot_1.backup.json`. A write that fails or is cut short leaves the old save
  as it was (`SaveFiles`, pure; `SaveSystem.save_to_slot()`).
- `SaveSystem.erase_slot()` removes a slot's three files. The tests' cleanup (26 files) and the two tools
  that empty slots use it.

**2. Save on quit**
- "Quit to title" saves first, and so does closing the window in an area or on the ending screen.
  "Saving..." is up for half a second, then the game leaves. The pause menu's note says so.
- A save that can't be written keeps the game open once and says why; asked again, it leaves unsaved.
- A hero lying fallen is saved awake at the entrance; one down a pit, on the ground he fell from.

**3. A save that can't be read**
- Continue says so in a box under the title's menu and offers the backup, with where and how long it was.
  If the backup can't be read either, or there is none, it says that and the title stays. A save that is
  gone while its backup is there, and one from a version this game doesn't know, are treated the same way.

**4. A reward too big for the pack**
- The `give_item` effect goes through `GameState.give_item()`: what fits goes in, and the rest is laid at
  his feet (a `LeftItem`) with a line at the top of the screen. It lies there through leaving the area and
  through a save, and is picked up whole when there is room.
- A right click passes over what he has no room for when someone or something is before him.

**5. A gift to a full friendship**
- Still taken, as it was. The villager now answers with a line of their own (`thanks.full`), and the seven
  villagers each have one.

**Checked**
- **766 tests in 103 suites pass.** Fifty-six are new: `safe_save_test` (11), `save_files_test` (4),
  `quit_save_test` (12), `unreadable_save_test` (11), `reward_overflow_test` (9), `left_items_test` (6), and
  three for the gift. Seven older tests were changed to fit: two that quit to the title, three that named
  what a gift returns, and two about a villager's file.
- **Nineteen deliberate bugs,** planted one at a time in runtime code and each caught by the new tests,
  files restored: a half-written save passing for a save, the old save not kept, the save written straight
  over the old one, a fallen hero saved fallen, a failed save leaving at once, a closing window never
  saving, quitting without saving, leaving before the notice, Continue greyed out for a broken save, the
  offer loading the broken save, nothing said with no backup, a second thing owed replacing the first, a
  picked-up thing lying there still, a full pack standing between him and a villager, the effect losing the
  rest as before, another area's things showing here, the ordinary thanks at five marks, a gift never saying
  the friendship was full, a villager's file without the line let through.
- **A real window, closed as the X button closes it** (a close message from the system, not a call): in the
  village scenario the save was written at the moment of closing and the game was gone 0.8 seconds later;
  at the title the game was gone in 0.2 seconds and no save was touched.
- **Renaming over a file** replaces it on this machine (checked by itself); the code also covers a system
  where it doesn't.
- **Five screenshots,** looked at: the title offering the earlier save, the title with neither readable, the
  arrows at his feet with the line at the top, "Saving...", and Pip's line.
- **The player's own save was read-only throughout:** the same checksum before and after every run.
- **Old saves:** the suite's saves from versions 1 to 3 load as before, and a version 4 save with nothing
  beside it loads and becomes the first backup.

**Known issues and limits**
- Not tried in play.
- **The window's close button now takes half a second** in an area: the price of the notice.
- **A crash or a power cut still loses what was done since the last save.** Only leaving by the pause menu
  or the window saves; there is no autosave on a timer or on entering an area.
- **The backup is the save before the last, and is offered only when the save can't be read.** A save that
  reads but holds a game he didn't want (a new game saved over an old one) is not undone by it.
- **A save that fails on quit is told at the top of the screen,** where it can be missed over a pale wall;
  the second quit then leaves unsaved.
- **What lies at his feet is taken whole or not at all,** like every pickup: six arrows wait until there is
  room for six.
- **A thing given while he is on his way through a door** is laid where he arrives.
- **The gift at five marks still costs the food** and still uses the day's gift; only the words changed.
- **The ending's "Save and go to the title"** shows no "Saving..." and, if it can't save, stays on the
  ending for good, as before.
- **News at the top of the screen is hard to read over a pale house wall** (as it always was).

## 2026-11-17 — Willowmere, step 1: the marsh by day

The user's request: one new area and one new enemy (`docs/progress/willowmere-plan.md`, approved as written:
ten decisions, three steps). This is step 1, and the one stop asked for before the end.

**Built**
- **Willowmere,** a marsh 40 by 30 cells east of Hearthvale, baked by `build_maps.gd`. Water and deep reeds
  block; four boardwalks join the west bank, the island with the ruined fisher's hut, an islet north and one
  south, and the east bank. Six marsh lantern posts stand dark where the boards meet land.
- **The way there:** two cells of Hearthvale's east tree line are open (rows 17 and 18), with planks laid
  across the east meadow to them. Nothing else in the village moved.
- **A heart piece** in a nook in the north-east, reached only by one cell of ground between two rows of
  willows and the east woods. The willows' crowns hang over that way.
- **Three things to gather,** two spots of each, back each morning: cattail root (north islet), marsh
  berries (east bank), bog mushrooms (south islet). All three can be eaten raw.
- **Marsh Stew:** two bog mushrooms and a cattail root at the hearth, known from the start. 45 energy and
  half a heart.
- **The look:** two new rows of tiles (mossy ground, boardwalk planks two ways, reeds, the hut's fallen roof
  and front wall, cattails, moss, a mossy stone, a lantern post) and a weeping willow that stands tall like
  the other trees. Mist lies still over it, as over the Old Wood. Eight fireflies come out when the lamps
  are lit (18:30); the Old Wood's are out at every hour, as before.
- **A tune of its own,** `marsh`: slow, D minor, 29 seconds. After nightfall the night's tune plays, as
  everywhere out of doors.
- **A scenario to try it:** `tools/playtest.gd -- marsh` (add an hour for dusk: `-- marsh 18:30`).

**Checked**
- **777 tests in 104 suites pass.** Eleven are new (`tests/world/willowmere_test.gd`): the walk there and
  back, only two village cells changed, water and reeds block and boards don't, every patch of land is
  joined, the heart piece's one way in, each forage spot and its morning, the foods, Marsh Stew at the
  hearth, the tune and mist and fireflies, the tiles, and a save from version 3 loaded into the marsh.
- **Ten older tests changed** to the new facts: the list of items, the hearth's seven dishes (four tests),
  the village's count of cells that can be walked to (two tests), the list of areas and their sizes, the
  count of exits, and the Decor layer's rules (the marsh's own ground counts as open ground).
- **The tests found a fault in the plan's sketch:** the hut stood on the cells where the north boardwalk
  lands, so the north islet could not be reached. It was moved two cells west.
- **No older tile moved:** the new tiles are two rows at the end of the atlas, and the old rows are the same
  pixel for pixel (compared with the atlas in git).
- **Eleven deliberate bugs,** planted one at a time in the code and the data and each caught by the new
  tests, files restored: fireflies out at noon, none waiting for dusk, the Old Wood losing its mist, no mist
  over the marsh, no tune of its own, a cattail spot with no picture once picked, a stew of mushrooms only,
  a stew that must be taught, a willow that is no tall tree, the way in arriving on the exit, and marsh
  berries that are not food.
- **Screenshots,** looked at: the marsh from five places by day and at dusk, and the village's east meadow.
- **The player's own save was read-only throughout** (the same checksum before and after).

**Known issues and limits**
- Not tried in play.
- **Steps 2 and 3 are not built:** there are no Bogwisps, the marsh is as calm at night as by day, Old
  Henrik is not there, and the lantern posts never light.
- **The way out of Hearthvale runs under the crown of the tree south of it,** as the plan could not avoid:
  the whole east edge is trees. The crown fades when the hero is behind it.
- **The numbers are first guesses:** 6, 9 and 7 energy for the three raw foods, 45 and half a heart for
  the stew.
- **The water is the game's one water tile,** bright and clear: a marsh pool is no murkier than the
  village pond.
- **The fifth heart piece is always left over** once four have made a heart (decision 4 of the plan).
- **The hut is a block of roof and wall,** four cells by three, with no way in (decision 6).

## 2026-11-17 — Willowmere, step 2: the marsh by night

The user looked at step 1 and said to go on ("Looks right, go on").

**Built**
- **The Bogwisp,** a pale blue-green light that is only there in Willowmere at night. Five of them, over the
  pools beside the boardwalks. Data: `data/enemies/bogwisp.json`.
- **Its brain** (`WispBrain`, pure): it hangs where it rose until the hero comes within six cells, drifts
  toward him at 22 px a second, and within 52 px stops and flares for half a second, aiming where he stands
  as the flare begins. Then it darts 75 px along that aim and rests 1.3 seconds. A step aside during the
  flare takes him out of the dart's way. It floats over water, reeds and walls (`GridBody.drifting`).
- **Its touch** takes half a heart and 15 energy (a hit can now carry energy: `Hit.energy`, from an enemy's
  `energy_drain`). At no energy he collapses and wakes at home, by the rule that was there.
- **No body without light.** Unlit, a blow passes through it with the Shade's thin-air sound. Inside the
  light of the Lantern the hero carries (its own radius, 56 px, as in the crypt) it has a body: health 4,
  which is two blows of either sword. His dim glow without a Lantern doesn't count.
- **A Wisp Ember** every time one is beaten: an ingredient, not food. One beaten over water leaves its ember
  on the nearest open cell, or where the hero stands.
- **Only by night** (`"appears": "night"` in an enemy's data): by day they lie low, out of sight and
  touching nothing. If the hero is there at 20:00 they rise, fading in. When the night ends they fade and
  leave nothing. The night's rules, which make other monsters tougher, leave them as they are.
- **Thicker mist at night** over the marsh: it thickens slowly where it lies, and does not drift.
- **Two sounds:** a rising note for the flare, a falling rush for the dart.

**Checked**
- **801 tests in 106 suites pass.** Twenty-four are new: twelve for the brain
  (`tests/core/enemies/wisp_brain_test.gd`) and twelve in the marsh (`tests/world/bogwisp_test.gd`).
- **Three older tests changed:** the lists of items and of enemies, and one lily pad moved off a cell
  where a wisp rises.
- **Twenty-six deliberate bugs,** planted one at a time in the code and the data, each caught, files
  restored. Among them: a blow landing on a wisp with no body, no half second of warning, a dart that homes
  in, fading counted as a death, drifting off the map, water stopping it, no energy taken, wisps out by day,
  never rising, never fading, the dim glow counted as light, the ember falling in the water, one blow
  enough, an ember that can be eaten.
- **Screenshots,** looked at: the marsh at 22:00 with and without the Lantern, two wisps flaring at the
  hero on the boards and three hanging over the pools.

**Known issues and limits**
- Not tried in play by a person. The fight is played through in a real window at the end of step 3.
- **The night ending can't be seen:** a day ends at 02:00 and the hero wakes at home, so the fading is a
  rule with tests and nothing more (decision 2 of the plan).
- **Without the Lantern there is no fighting them,** and the Lantern is in the crypt (decision 3).
- **The west boardwalk is the only way home, and two wisps hang beside it.** A hero who keeps moving is
  missed by their darts; one who stands is not.
- **They are back on every visit,** like every enemy: walking out of the marsh and in again brings back
  those beaten.
- **The numbers are first guesses:** 15 energy, 22 and 150 px a second, 1.3 seconds of rest.
- **An ember is an ingredient, so it can be given as a gift,** like cherry blossom. Nobody likes it.

## 2026-11-17 — Willowmere, step 3: Old Henrik, and the whole of it played

**Built**
- **Old Henrik,** the eighth villager, by his ruined hut from 06:00 to 20:00. A file in `data/villagers`
  and a conversation: he likes Marsh Stew and bread, warns of the lights, and says why a sword does nothing
  to them.
- **His favour,** "Lights on the Marsh", asked at two marks: bring three Wisp Embers. A quest of the same
  shape as the other four favours.
- **The reward:** the flag `marsh_lanterns_lit` and the Ember Tea recipe.
  - The six posts take their burning picture at once. From dusk to dawn they glow like the village's lamps,
    and their light gives a Bogwisp a body, 44 px round each, as the hero's Lantern does.
  - **Ember Tea:** one Wisp Ember and two marsh berries, 90 energy and no hearts. It is not at the hearth
    until he teaches it.
- **His present** at four marks: three bog mushrooms, once.
- **The Friends page has room for eight:** the line under the list moved down a row.
- **Two shots in the screenshot tool:** `141_willowmere_by_day`, `142_willowmere_by_night`.

**Checked**
- **811 tests in 107 suites pass.** Ten are new (`tests/world/henrik_test.gd`), and Henrik is in the two
  tables the older friendship tests run through: his favour is put off, taken, reminded of and finished by
  the same test as the other four, and his present by the same test as the other seven.
- **Eight older tests changed** to the new counts: eight villagers, nine quests, the list of items, the
  quest log's lines, the Friends page, and the ending's "of 9" and "of 8".
- **Twenty-two deliberate bugs,** planted one at a time in the code and the data, files restored. Twenty-one
  were caught at once. **One was not:** a lantern whose light reached two pixels passed every test, because
  the test stood the wisp right under the post. A test of the reach was added (lit six pixels inside it, dark
  six pixels outside), and then that bug and its opposite were both caught. The others: lanterns that hold
  nothing, burn by day, are lit before the favour or stay dark after it; a lit post with no glow; the marsh
  naming no flag; a favour that teaches nothing or lights nothing; Ember Tea known from the start or worth
  little; Henrik not liking the stew, or with no line for a full friendship; two embers being enough; the
  embers kept; a present of one; the favour or the present given to a stranger; the eighth name running
  into the line below.
- **Played in a real window** by a script that presses the keys and the mouse buttons while the game runs
  as it does for a player (`Input.parse_input_event`; the script looks at where the wisps are to decide
  what to press, and changes the game's state only where noted). One run, 66 seconds:
  - **The favour is asked.** He walks to Henrik and right-clicks. Henrik asks for three embers; Enter takes
    the first answer; the quest is active and the friendship stands at two marks.
  - **Night falls.** *(The clock was set to 19:57.)* At 20:00 five Bogwisps rise over the pools.
  - **Without the Lantern,** on the west boardwalk for thirty seconds: two swings at wisps in reach, both
    heard as thin air, none landed, none beaten. He stepped out of the way of every dart.
  - **Standing still,** he let one dart through him: hearts 8 to 7 and energy 99 to 84. Half a heart and
    fifteen energy.
  - **With the Lantern** *(put in his pack; in the story it comes from the crypt)*: two wisps beaten on the
    west boardwalk in four seconds, and a third on the east boardwalk in sixteen, with one more touch taken.
    Each left an ember, and he walked onto all three.
  - **The embers are handed over.** *(The clock was set to the next morning: the walk home and the night's
    sleep were not played.)* The wisps that were left had faded. He walks to Henrik, right-clicks, and Enter
    takes "Three embers, Henrik.": the quest is complete, the flag is set, Ember Tea is known, no embers are
    left, six posts on the map burn, and the news reads "New recipe: Ember Tea." and "Quest complete: Lights
    on the Marsh".
  - **Dusk.** *(The clock was set to 19:20.)* The lanterns burn, and seven lights give a wisp a body: six
    lanterns and his own.
- **Screenshots,** looked at: the marsh by day and by night, Henrik by his hut, the lanterns lit, the
  Friends page with eight names, and seven from the played run.
- **The player's own save was read-only throughout** (the same checksum before and after every run).

**Known issues and limits**
- **Not played by a person.** The scripted play shows that the fight and the favour work from the keys;
  it says nothing of how they feel, or whether the wisps are too hard or too easy to dodge.
- **What the script skipped is not shown to work in play:** the walk from the marsh to the bed, sleeping,
  and coming back the next day. Each is covered by tests of its own from before Willowmere.
- **The script's hero dodged nearly every dart** by stepping across the line a wisp was aimed along. A
  player has half a second to do the same.
- **Henrik's present is food, so it can be given straight back to him** while his favour is still unasked:
  "I brought you something." is then the last answer he offers.
- **The lanterns burn only from 18:30,** with the village's lamps; lit, the posts show their burning
  picture by day as well.
- **Ember Tea's 90 energy is a first guess,** and is the most any dish gives.
- **The quest's journal says nothing of where the Lantern is.** Henrik's own words say to carry one.

## 2026-11-17 — Playtest: Willowmere by day (the user: "Feels right")

The user started the `marsh` scenario at 16:00 (`tools/playtest.gd -- marsh 16:00`), played for about a hundred seconds, closed the window and, asked how Willowmere felt, said it feels right.

**What the run covered** (read from the scenario's own save, slot 900, written as the window closed)
- **Old Henrik was given the Marsh Stew** and stands at nine points, two marks, and **he asked his favour** (the quest is at its `bring` stage).
- **Three forage spots were gathered:** four cattail roots and two bog mushrooms are in the pack.
- **The hidden heart piece was taken,** by the side path behind the willows.
- **The window was closed at 18:01** and the game saved as it left: the fix round's saving on quit, in a person's hands, to the scenario's slot.
- No errors in the game's output. The player's own save has the same checksum as before.

**What it did not cover**
- **The night.** The run ended two hours before the Bogwisps rise: no wisp was met, no ember was won, the favour was not finished, and the lanterns and Ember Tea were not seen. So the plan's last line was split in two: the day is ticked, the night is still open.
- Cooking Marsh Stew, and the walk to the marsh from the village.

**Changed for the run**
- **The `marsh` scenario starts with Old Henrik at five points,** one liked gift short of two marks, as the `late` scenario does for the other villagers, so his favour can be asked on the first day. A tool only; committed on its own.

## 2026-11-17 — Playtest: Willowmere by night (the user: "Feels right")

The user started the `marsh` scenario at 19:00 (`tools/playtest.gd -- marsh 19:00`), played for seventy seconds, about twenty-seven of them after the Bogwisps rise, closed the window and, asked how the marsh felt by night, said it feels right. Both of the plan's last lines are ticked.

**What the run covered** (worked out from the scenario's own save, slot 900, written as the window closed at 20:38; not watched)
- **Two Bogwisps were beaten:** two points of Combat.
- **He ran out of hearts once.** The save has him at the marsh's entrance with full hearts and 5 energy of 100. That is six touches (three hearts and 90 energy) and about ten swings, and then waking at the entrance whole. A fall gives the hearts back and none of the energy.
- No errors in the game's output. The player's own save has the same checksum as before.

**What it did not cover**
- **No ember was carried at the end:** the two that were dropped were not walked onto.
- **Old Henrik was not spoken to.** His favour has still been finished only by the script, and the lit lanterns and Ember Tea have not been seen by a person.
- A collapse in the marsh, the walk home and the night's sleep.

**Worth knowing**
- **A person is touched far more often than the script was:** six touches in under half a minute of night, against the script's two in a minute. The user judged it right as it is. Five wisps, 15 energy a touch and half a second of warning are all data, should that change.
- **After the fall he stood at the entrance with 5 energy and three wisps still out:** one more touch would have been a collapse (waking at home with half a bar, a tenth of his coins gone).

## 2026-11-17 — Mining, phase 1: the Old Quarry

The first of three phases of mining and crafting (`docs/progress/mining-crafting-plan.md`, approved as written).

**Built**
- **The mouth:** six cells of the North Fields' east tree line, north of the stream, are an outcrop of rock with a cut through it, and old rails lead up to it over the grass.
- **The entrance hall:** the way out, the lift, a ladder down, timber, rails, and two rocks to try a pickaxe on. No monsters.
- **Nine floors,** each one screen, drawn as sketches that the map baker reads:
  - 1 to 3 (The Cut, The Galleries, The Old Face): 16 rocks each, 5 of them copper; 2, 3 and 4 slimes.
  - 4 to 6 (The Coal Seam, The Crossing, The Ledges): 16 rocks each, 3 iron and 4 coal; bats, and goblin archers from floor 5, two of them on raised ledges on floor 6.
  - 7 to 9 (The Dark Drift, The Flooded Gallery, The Heart of the Quarry): 14, 14 and 17 rocks; gold on all three, crystal from floor 8; dark; 2, 3 and 4 Bogwisps.
- **The Pickaxe,** 25 coins at Tilda's. A blow costs 2 energy. Stone, copper and coal take two blows; iron, gold and crystal three.
- **The day's roll:** each morning every rock is back in its place, and which hold ore and which plain rock hides the ladder is shuffled anew, from a number kept in the save, the day and the floor.
- **The lift:** coming to floor 4 or 7 opens it to that floor for good. Every ladder up leads to the hall.
- **A fall** on a floor ends in the hall, whole, with what he carries.
- **The clock runs** in the quarry, and Bogwisps are out there at every hour.
- **A heart piece** on floor 9, in a pocket walled off by three rocks.
- **Mining,** a fourth skill: a point for a plain rock, two for ore; each level takes a tenth off a blow and adds a twentieth to the chance of one more ore.
- **Seven items** (the Pickaxe, stone, copper ore, coal, iron ore, gold ore, crystal), a sheet of rocks, a tune and three sounds.
- **Save version 5,** with a step from version 4.
- **Two playtest scenarios** (`quarry`, `deep`) and seven capture shots (143 to 149).

**What differs from the plan**
- **He arrives a few cells east of the top-left corner** on seven floors, and two rocks moved with him: the HUD covers that corner at a dungeon's size. Counts are as approved; the plan's sketches are now the built ones.
- **What a rock held lies in its cell** until he walks onto it; it is not put in his pack.
- **What he has no room for stays lying,** and he is told once. This changed what monsters drop too: before, a drop over a full stack was taken and lost.
- **The rock over the ladder gives no stone.**
- **The pause menu is a line taller** and shows two skills to a line.
- **One commit,** not the three steps the plan listed: they shared the same files.

**Verified**
- **860 tests in 113 suites, all passing** (49 of them new: the mine's rules, rolls and state; the quarry in play; the Mining skill; the save).
- **A version 4 save loads** with everything it had, a whole mine, no lift and no Pickaxe. The fixture was written by the game as it stood at the commit before (a second checkout, run once), not made by hand. Versions 1 to 3 still load.
- **63 of 63 bugs planted on purpose were caught** by the tests (62 at once; the other, a floor that is no lift stop announcing the lift, slipped through until a check for it was added).
- **A bug found by the tests while building:** a fall that ended in the hall wrote where he had lain over where he was going, in the same frame. Fixed; a planted copy of it is caught.
- **Screenshots,** looked at: the mouth, the hall, floors 1, 5, 6 and 9, and floor 8 with and without the Lantern.
- **The player's own save was read-only throughout** (the same checksum before and after).

**Known issues and limits**
- **Not played by a person, or by a script pressing keys.** The tests drive the game's own functions; nobody has walked a floor. Whether a floor reads at a glance, and whether a blow feels right, is for the user.
- **The numbers are the plan's first guesses:** 2 energy a blow, the blows a rock takes, how many rocks hold ore. Phase 3 measures them.
- **Ore can't be sold or used yet:** Tilda buys it in phase 3, and the furnace and workbench are phase 2. Until then it only stacks up (stone to 50, ores and coal to 30, crystals to 10).
- **A tree's crown covers the lower half of the outcrop** in the North Fields. The mouth itself and the rails are clear.
- **Without the Lantern the deep floors can be mined but not fought in:** a Bogwisp has no body there, as in the marsh. The Lantern is in the crypt.
- **Enemies are back on every visit,** as everywhere: taking the ladder up and coming down again brings them back.
- **Headless, a villager's colours depend on which suite ran first** (the sheet is painted on in place). The whole suite's order passes. Not new, and not touched.

## 2026-11-17 — Playtest: the quarry's hall and first floor (the user: "Feels right")

The user started the `quarry` scenario (`tools/playtest.gd -- quarry`), played for seventy-five seconds, closed the window and, asked how the quarry felt, said it feels right.

**What the run covered** (worked out from the scenario's own save, slot 900, written as the window closed at 07:37; not watched)
- **Both of the hall's rocks were broken,** and the two stones picked up.
- **Four rocks of copper were broken on floor 1,** and all four ores picked up. With the two plain rocks that is ten points of Mining: the second level, reached in the first minute.
- **Two slimes were beaten,** and two touches taken (two hearts of three left).
- **About a third of his energy was spent** (65 of 100 left): twelve blows, a few swings and some running.
- **He climbed out and walked back into the North Fields** before closing the window, which saved as it left.
- No errors in the game's output. The player's own save has the same checksum as before.

**What it did not cover**
- **The ladder on floor 1 was not found:** it was under one of the plain rocks left standing. So nobody has yet been below floor 1: floors 2 to 9, the lift, iron and coal, the dark floors and their Bogwisps, a fall, and the heart piece are all still played only by the tests.
- A second day, with the rocks back and rolled anew.
- A full stack, and the Pickaxe bought at Tilda's (the scenario hands him one).

The plan's last lines say so: the first floor is ticked, the floors below and the comparison with farming are open.

## 2026-11-17 — Crafting, phase 2: the workbench, the furnace and what they make

The second of three phases of mining and crafting (`docs/progress/mining-crafting-plan.md`, approved as written). Built in three commits, a step each (2a, 2b, 2c), and a fourth for the checking and this write-up.

**Built**
- **The workbench** stands by the cottage's east wall from the first day. Facing it, a right click opens its list:
  - the recipes he knows, six at a time, in a fixed order;
  - under it, what the one under the cursor needs and what he has of it ("Stone 12 of 20"), a need to a line;
  - what he can't make now is greyed out, and choosing it says why (he lacks something, has no room, or has one already);
  - it stays open for as many things as he likes; the mouse points, the wheel steps, Tab and Esc leave.
- **Thirteen recipes at the workbench and three in the furnace,** all data (`data/crafting/`). A recipe is known once the thing it waits on has been found, or a skill has risen; the Woven Rug is known from the start.
- **What he has ever held is remembered,** so a recipe stays on the list when the last of its ore is sold or used.
- **The furnace** (20 stone, 5 copper ore) smelts overnight: three ore and a coal for a bar, one load of one metal, five bars at the most. Lit today, ready the next morning. Burning, it shows its fire and lights the room.
- **The storage chest** (10 wood, 1 copper bar): 24 stacks, several of one thing if need be. Two lists, the pack and the chest; a line chosen moves that stack across, as much of it as there is room for.
- **The Standing Lamp** (1 copper bar, 2 wood, 1 coal), a real light, and **the Woven Rug** (8 wheat, 3 cherry blossoms), beside the bed.
- **Wood:** ten fallen branches (one blow of the sword, 1 wood) and five old stumps (three blows, 2 wood) in the North Fields, the Old Wood and the South Field, back each morning.
- **Bombs:** 1 coal and 3 stone for three.
- **Copper and iron tools,** each made from the tool before it, at the same energy a use:
  - the hoe tills two cells in a line, then three;
  - the watering can waters two cells with one pour, then three;
  - the pickaxe breaks a rock in one blow fewer, then two fewer (every rock in one).
- **The sprinkler** (1 copper bar, 1 iron bar; Farming 2): set on a tilled, empty cell of the plot from the item bar, taken up with a right click. Each morning it waters the four cells beside it.
- **The Miner's Lantern** (the Lantern, 1 gold bar, 1 crystal): light for 80 pixels round the hero, where the Lantern gives 56.
- **Twelve items,** a sheet of furnishings, a branch and a stump, twelve icons and two sounds.
- **A playtest scenario** (`craft`) and six capture shots (150 to 155).

**What differs from the plan**
- **What he has found is a list in the save,** not a flag for each item.
- **The workbench shows the needs of the recipe under the cursor,** not of every recipe at once.
- **A tool made from the one in his hand takes its place there.**
- **The cell he faces decides whether a better hoe's or can's stroke is made;** the cells beyond it get it if they can.
- **A rock's blows are counted by the pickaxe that strikes it:** a rock begun with the plain pickaxe is finished sooner by a better one.
- **The chest keeps what stacks,** and leaves coins, keys and quest things with the hero. A line moves the whole stack; there is no choosing how many.
- **A sprinkler set down today runs from tomorrow,** and is taken up only if he has room for it.
- **What the furnace made is given:** what a full pack can't take is laid at his feet.
- **Three maps were re-baked** for the wood's markers (the plan named one re-bake, for the quarry's mouth).
- **Two sounds, not three:** the ladder uses a chime that was there.
- **No new save version:** crafting's three fields are read with defaults, inside version 5.
- **Step 2b's commit was amended once,** before anything was pushed.

**Changed while checking**
- **`CraftMenu.bright_lines()`** was added, so a test can see that a greyed line is not on the bright list as well.
- **The chest's menu chose which list to open on in two places.** One was removed; it opens as it did.
- **A comment line that stood twice** in `GameState` stands once.

**Verified**
- **925 tests in 122 suites, all passing.** 65 are new with crafting (57 from the three steps, 8 from this check): the rules of recipes, the furnace and the chest; the workbench, the furnace, the chest, wood, the tools and the sprinkler in play; and the save.
- **The plan's "done when", in one test each** (`tests/world/crafting_chain_test.gd`):
  - **Everything on the workbench's list is made from what the mine and the fields give.** Starting with only raw things (stone, ore, coal, a crystal, wood, wheat, blossom) and the four plain tools, a hero with Farming 2 and Mining 3 makes all thirteen recipes at the workbench, through its own list, over six days. Five nights of the furnace turn 30 copper ore, 24 iron ore and 3 gold ore into 10, 8 and 1 bars (five more copper ore built the furnace itself). At the end nothing is left over. It takes 21 coal: the plan's sum for the whole list was one coal short (it left out the bombs' one), and the plan now says so.
  - **Every need of every recipe comes from somewhere:** a rock, cut wood, a crop, Tilda's shelf, something lying in the world, or another recipe. No recipe needs more of a thing than a stack holds.
  - **A save in the middle of it** keeps the furnace burning, the chest's stacks in their order and a sprinkler on the plot; the next morning the bars are ready, and for four mornings the sprinkler waters its four cells and leaves the corner dry. The turnip beside it ripens without the can; the one in the corner withers.
- **A version 4 save loads** with a cold furnace, an empty chest, nothing furnished, and what it carries counted as found, which stays found when the last of it is gone.
- **152 bugs planted on purpose,** one at a time, in the fourteen code files and the data, each file put back. **132 were caught at once** (one of them by tests that failed and then hung, in a loop the bug made endless). **Twenty were not.** A test was added for nineteen, and each was planted again and caught:
  - **In the chest:** a quest's thing that stacks could be put away; so could the watering can's water; a stack that a save made bigger than its item's limit loaded as it was.
  - **In the workbench's list:** a line he couldn't make was on the bright list too, so nothing looked greyed; the list never scrolled; pointing with the mouse in a scrolled list picked the wrong line; it opened where the cursor had been left, with the last note still up.
  - **In the chest's lists:** turning to the other list kept the old line; pointing in a scrolled list picked the wrong line.
  - **On the plot:** setting a sprinkler, or taking one up, told nobody, so the plot would not have been redrawn.
  - **In his hand:** a thing made jumped into a hand that held the sword by choice.
  - **Elsewhere:** the lamp gave light before it was made; a stump's first two blows were silent; an old save forgot what it had carried once the last of it was gone; the last lantern picked up counted, not the widest; three watering cans named their water three times (an older farming test outside the crafting suites did catch this one); a stack of gold bars held thirty.
  - **One planted change turned out to be no bug:** the chest's menu chooses which list to open on in two places that do the same thing, so removing one changed nothing.
- **Screenshots,** looked at (shots 150 to 155): the workbench's list, with the chest greyed and what it is short of; the cottage with the chest, the lamp, the rug and the furnace burning; the chest's two lists after a stack was put away; the plot the morning after two sprinklers were set, the four cells beside each one wet and the corners dry; the cold furnace's list; fallen branches and a stump in the Old Wood.
- **The `craft` scenario starts** (`tools/playtest.gd -- craft`) without an error. It was run for a few seconds and closed; nobody played it.
- **The player's own save was read-only throughout** (the same checksum before and after).

**Known issues and limits**
- **Not played by a person, or by a script pressing keys.** The tests drive the game's own functions and hand events to the menus; nobody has stood at the workbench. Whether its list is easy to read, and whether it is clear what to make next, is for the user.
- **The numbers are the plan's first guesses:** what each recipe costs, five bars a load, 24 stacks, two and three cells of reach. Phase 3 measures them.
- **Ore and bars can't be sold yet:** Tilda buys them in phase 3.
- **A load can't be taken back.** Once the furnace is lit, the ore and the coal are in it until morning.
- **The chest moves whole stacks,** as much as fits; there is no choosing how many.
- **The workbench's list shows six recipes at a time.** With all thirteen known it scrolls; a line under the box says where he is in it.
- **A better hoe or can works only if the cell he faces can be worked.** Facing tilled soil with bare soil beyond it, the hoe does nothing.
- **A sprinkler waters tilled soil only,** and from the morning after it is set. It has one picture: nothing moves, as the scenery's rule asks.
- **The HUD's "Carrying" line is cut off** once the pack holds more than three or four kinds of thing, as it always was. With ore, bars and wood in the pack that is now most of the time.
- **Wood is the tight material early:** fifteen spots give up to 20 a day, and the chest and the lamp take 12.
- **Making the Miner's Lantern uses up the Lantern.** It lights the crypt's torches and gives a Bogwisp a body as the Lantern did, from further off.
- **Two older warts, not new and not touched:** entering a boss's room prints "signal already connected" (since the Bogwisp), and headless a villager's colours depend on which suite ran first.

## 2026-11-17 — Playtest: the workbench (the user: "Feels right")

The user started the `craft` scenario (`tools/playtest.gd -- craft`), played for about eighty-six seconds, closed the window and, asked how the workbench and its list felt, said it feels right.

**What the run covered** (worked out from the scenario's own save, slot 900, written as the window closed at 07:35; not watched)
- **Six things were made at the workbench:** the furnace, the storage chest, bombs, the copper hoe, the copper watering can and a sprinkler. Every copper bar he began with went into them.
- **The furnace was loaded and lit** with what makes three copper bars: nine ore and three coal.
- **The copper hoe was in his hand** when the window closed.
- No errors in the game's output. The player's own save has the same checksum as before.

**What it did not cover**
- **A night:** he did not sleep, so the furnace was still burning and no bar was taken out.
- **The chest in use:** it was made, and holds nothing.
- **The plot:** he never left the cottage. The reach of the copper hoe and can, and a sprinkler on the soil, are still played only by the tests.
- **The rest of the list:** the lamp (no copper bar was left for it), the rug, the copper pickaxe, the iron tools and the Miner's Lantern. No wood was cut.

The plan's last lines say so: the workbench is ticked; the lower floors and the comparison with farming are open.

## 2026-11-17 — Balance, phase 3: Tilda buys, two favours, and eight days played

The third of three phases of mining and crafting (`docs/progress/mining-crafting-plan.md`, approved as written). Built in two commits, a step each (3a, 3b), and a third for this write-up. **No price or count was changed:** the report proposes numbers, and the tuning waits for the user's word.

**Built**
- **Tilda buys what the quarry gives:** copper ore for 3 coins, iron ore 5, gold ore 10, a crystal 15, a copper bar 12, an iron bar 20, a gold bar 36. Stone, wood and coal are not bought.
  - A shop's data may list what it buys besides crops (`buys`). Her list shows the harvest first, then these. A new thing to buy is a line of data.
  - Her answer reads "I have things to sell.", and her greeting says she buys what he digs out of the quarry.
- **Two favours, asked at three marks** by the two villagers who teach a recipe at two:
  - **Wenna, "Black for the Loom":** five coal, for dye. 30 coins and two Cherry Blossom Tea.
  - **Shepherd Edda, "New Shears":** two iron bars. 50 coins and a Shepherd's Pie.
  - Both are data: a quest of the favours' shape, and an opening and four nodes in the villager's conversation. The rewards are given, so a full pack finds them at his feet.
- **A script that plays the game** (`tools/play_days.gd`): eight days of a new game in a real window, by pressing real keys and mouse buttons. The plot, Tilda's counter, the quarry, the furnace and the workbench.
- **The report** (`docs/progress/mining-balance-report.md`): each day's energy, coins, ore, crops, bars and things made; every floor; what the script set up or left out; a day in the quarry beside a day on the plot against the plan's first guesses; and the numbers it would change.
- **Three capture shots** (156 to 158): Tilda's list with ore and bars on it, and each favour being asked.

**What differs from the plan**
- **Tilda says "things", not "crops".** With only ore in his pack a player would not have looked under "I have crops to sell."
- **Each favour is asked after the lesson.** A hero who reaches three marks untaught is taught first and asked at the next talk.
- **The script is a tool in the repository,** not a scratch file as Willowmere's was: tuning will want it run again.
- **One thing was handed to it:** the Lantern, on day 7. Everything else was come by in play, from the title's "New game".
- **It did not play the two favours:** three marks take about a week of gifts.
- **The tuning is not done.** The plan's step 3b ends with it; it waits for the user.

**Verified**
- **935 tests in 123 suites, all passing.** Ten are new: the shop's `buys` list in the pure class and at the counter (four), and the two favours (six). Three older tests carried counts that changed (eleven quests, the quest log's twelve lines, the ending's "of 11"), and three carried Tilda's old words.
- **80 bugs planted on purpose** in the new code and data, one at a time, each file put back. **78 were caught at once.** One was not: a favour's hand-over answer shown to a hero who carried the coal but had never been asked. A test was added, and that bug and its twin for Edda were both caught.
- **The eight days, played at life's own speed** (1813 seconds, thirty minutes; `Input.parse_input_event`; slot 956, emptied before and after):
  - **Day 1:** the tools by the door, five turnips sown and watered, the wooden sword, Wenna's shuttle for 30 coins, the Pickaxe for 25, and floors 1 and 2 until he was spent. In bed at 10:40.
  - **Day 2:** three loaves, floors 1 to 5 with the plain Pickaxe (182 energy), the furnace built and lit. Mining at its top level by 11:20.
  - **Day 3:** five copper bars, the Copper Pickaxe, floors 4 to 6 by the lift. On floor 7, without a light, a Bogwisp threw him back up the ladder; he went down again and left after one more touch.
  - **Day 4:** five iron bars, the Iron Pickaxe, five turnips picked and sold, two sprinklers made and one set, seventeen turnips sown.
  - **Day 5:** floors 1 to 6 with the Iron Pickaxe: 109 coins of ore for 85 energy.
  - **Day 6:** the Copper Watering Can and the Copper Hoe; the plot watered.
  - **Day 7** *(the Lantern put in his pack)*: all nine floors: 261 coins of ore for 115 energy, nine Bogwisps beaten, no touch in the dark.
  - **Day 8:** seventeen turnips picked, everything sold for 571 coins, the second sprinkler set, sixteen turnips sown. 494 coins in the purse.
- **Three full trial runs at four times speed** came before it, to try the script out. They found its faults, not the game's.
- **Screenshots,** looked at: Tilda's list with ore and bars, each favour asked, and fifty-odd from the played days (the plot sown, the furnace and the workbench, a floor of each band, a Bogwisp struck in the Lantern's light).
- **The player's own save was read-only throughout** (the same checksum before and after every run).

**What the days showed** (the report has the tables)
- **The plan's first guesses fit a new miner, and he is a seasoned one by day 4:** Mining at its top on the second morning, the Iron Pickaxe on the fourth.
- **From then floors 1 to 6 cost less than a bar of energy and pay about 110 coins a day.** A plot of turnips pays 40.
- **With the Lantern all nine floors pay 261 coins for 115 energy.** Without it the dark floors can't be worked.
- **The two don't compete for the day:** the plot takes a few minutes and a tenth of the bar.
- **Coal and stone pile up,** and the furnace's five bars a night is the narrow place.
- **Proposed, not done:** a third off what Tilda pays for ore, bars and crystals; a rock of ore 1 point of Mining and a plain rock none; two coal rocks a floor on floors 4 to 6, not four.

**Known issues and limits**
- **Not played by a person.** The script shows what the numbers do, not how a day in the quarry feels.
- **The script is quicker than a hand at a Bogwisp's flare,** and it sees rocks in the dark. A person will do worse on floors 7 to 9.
- **A Bogwisp's touch at the foot of floor 7's ladder throws the hero back up it.** He arrives one cell below the way up. Seen on day 3 and in three trial runs; not touched.
- **One run is one run.** In the trials the safe floors were steady (96 to 129 coins) and the dark floors were not (55 coins and a fall in one).
- **The script's first run at life's speed was thrown away:** a change to day 4 had him count the plot's empty cells from his cottage, and he bought no seed. Found in the log, fixed, and played again from the start.
- **`tools/play_days.gd` is long** (two thousand lines), and has no tests of its own: its test is that it plays.
- **Two warts met on the way, not touched:** the HUD's "Carrying" line is cut off all week, and the engine's time scale is set back to 1 after every hit's freeze, which a tool that runs the game faster has to undo each step.

## 2026-11-17 — Balance: the numbers settled (the user: "All three")

Shown the report and its three proposals, the user took all three. Each is a change to data and to the tests that carry it; no code changed.

**Changed**
- **What Tilda pays, a third off:** copper ore 3 to 2, iron ore 5 to 3, gold ore 10 to 7, a crystal 15 to 10, a copper bar 12 to 8, an iron bar 20 to 12, a gold bar 36 to 25. A bar is still worth more than its three ore.
- **Mining's points:** a rock of ore or coal 2 to 1, a plain rock 1 to none.
- **Coal on floors 4, 5 and 6:** 4 rocks a floor to 2.

**Verified**
- **935 tests in 123 suites pass.** Six tests carried the old numbers and were brought up to date: Tilda's prices in the pure class and at her counter, the floors' ore, a point for ore and none for stone, the blow that raises his Mining (now a rock of ore), and the crafting chain (twenty-five rocks of ore for Mining 3, where thirteen did).
- **The player's own save was not touched.**

**Known issues and limits**
- **The eight days were not played again with the new numbers.** By the report's own ore the days would have paid 53, 69 and 173 coins where they paid 83, 109 and 261. What the slower skill and the scarcer coal do to a week is worked out, not played.
- **With 2 coal a floor a day on floors 4 to 6 gives 6 or 7,** against 5 a night in the furnace: enough, with little to spare for Wenna's five.
- **Not asked for and unchanged:** the Iron Pickaxe's gate (Mining 3) and the furnace's five bars a night.

## 2026-11-17 — The Homestead, phase 0: the plan (no code)

The user asked for a farm of the hero's own outside the village: a new area where he lives, clears and shapes the land, raises buildings and keeps animals, in five phases with a stop after each (`docs/progress/homestead-request.md`). Phase 0 is a written plan only: `docs/progress/homestead-plan.md`. **It is a proposal and waits for the user's approval. Nothing is built.**

**What it proposes**
- **Where:** the lane through Hearthvale runs on west, through two cells of the tree line, to a new map of 40 by 30 cells. From the village's edge to the farmhouse door is 12 cells: 2.7 seconds at a walk, where the request allows 20.
- **The home:** the area `home` stays the same room and becomes the farmhouse's inside; only its door moves. Sleeping, 02:00 and a collapse wake him there, as they do now. The old cottage stands empty and locked.
- **The field:** 12 by 6, four times the old plot, which is its north-west corner. That corner is clear. The rest of it and the land around carry 145 weeds, bushes, logs, stumps, rocks and boulders, which the sword and the pickaxe clear for good. A small pond fills the can.
- **The story:** seven lines of the main quest, of Elder Bram and of his supper's journal change, and the title's line. The farm was Sir Aldric's, where the tale said his cottage.
- **Phase 2:** build mode, a screen in which the mouse points at a cell, and fifteen things to set down.
- **Phase 3:** a Well, a Silo, a Coop, a Barn and a Shed, bought as plans at the workbench and standing the next morning; a bigger Coop and Barn.
- **Phase 4:** chickens, sheep and cows from Farmer Oda, fed by pasture or by hay.
- **Phase 5:** two favours, ten days played by the script, and the numbers settled.
- **The save:** version 6, once. Nothing in an older save needs moving: the home, the furnishings, the chest, the furnace, the soil and the crops are where the farmhouse and the field now are.
- **Thirty decisions** are numbered for the user to approve or change one by one, and each phase is broken into steps with its tests and its screenshots.

**Where it meets the rules**
- **Eighteen places in CLAUDE.md are listed, each quoted:** where the home is, where the plot lies, no new areas, a furnishing's fixed place, one furnace and one chest, the mouse in play, what comes back each morning, the night's tune, the count of quests, and the tests and tools that take the old home for granted.
- **The words CLAUDE.md would carry instead are written out,** nineteen passages, each with the phase after which it takes effect. CLAUDE.md itself is not changed.
- **The request tells each phase to read `docs/HOMESTEAD-NOTES.md`, which doesn't exist.** The plan proposes that its own decision list, with `docs/DECISIONS.md`, takes its place.

**Checked**
- **The plan's facts against the code:** the village's map and scene, the home's scene, the plot and its rules, sleeping and waking, doors that keep hours, the hero's speeds, the save and its migrations, furnishings, the chest and the furnace, breakables and rocks, the shop, the input map, and the tools and tests that use the old home. The plan ends with the list.
- **Six before-pictures,** taken with `tools/capture.gd` (shots 54, 96, 97, 110, 116 and 151; five seconds) and looked at: the cottage's door with the lane's west end and the plot; the plot bare and with crops; the west side of the village with Farmer Oda by her field; the home's inside, bare and with every furnishing. They are in `reports/homestead/before/`, which git ignores.
- **935 tests in 123 suites pass,** as before: nothing in the game changed.
- **The player's own save has the same checksum as before.**

**Known issues and limits**
- **Nothing is approved.** No decision is in `docs/DECISIONS.md`, and CLAUDE.md, the GDD, TECH_DESIGN and the roadmap are as they were.
- **Every number is a first guess:** the costs, the day on which each building comes within reach, what an animal pays. Phase 5 measures them.
- **A field four times the size could pay four times the crops** (168 coins a day in turnips, where the old plot paid 42). The plan says what holds it back and that phase 5 must watch it.
- **Not tried:** how build mode would read the mouse against the camera, whether a tall picture set down at run time sorts as the baked trees do, how the baker lays a house front outside the village, and what three more rooms and 145 things on the land cost a frame.
- **The map's sketch is a first drawing.** Its counts are what is proposed; a cell may shift when it is baked.
- **`docs/HOMESTEAD.md`,** an untracked copy of the request, was left as it is.

**Approved.** Shown the plan, the user approved it as written the same day ("Approve as written"). The thirty decisions are recorded in `docs/DECISIONS.md` and at the head of the plan, and CLAUDE.md has the Homestead's paragraph under "Current goal". No phase is built yet; phase 1 is next.

## 2026-11-18 — The Homestead, phase 1, step 1a: the move

The first of phase 1's three steps (`docs/progress/homestead-plan.md`, approved as written). **The phase was stopped once and picked up again.** A first subagent wrote the version 5 fixture (committed, `569ddf0`) and most of this step, and was stopped as it began the step's new tests, with nothing run. A second read every change it left against the plan, kept it, finished the tests and ran everything. What was found is under "Picked up" below.

**Built**
- **The way west.** Two cells of Hearthvale's west tree line are open on the lane's rows and the lane runs on to the edge (one re-bake of the village; four cells changed and no others). `WestRoad` there and `EastRoad` on the farm lead to each other.
- **The farm's map** (`homestead`, "Your farm"): 40 by 30, baked from the plan's own drawing. Woods all round, the road in along rows 14 and 15, a path up to the farmhouse door, the farmhouse (the village's house tiles, thatched), a pond in the south-west corner, eleven old trees. Twelve cells from where he comes in to his doorstep.
- **The home's move.** The area `home` is the same room, now "Your farmhouse"; its doormat leads onto the farm. Sleeping, 02:00 and a collapse wake him there, with no rule changed.
- **The old cottage is locked:** its door names a place that is never open (`old_cottage` in `data/rules/hours.json`) and says "The cottage stands empty, and its door is locked."
- **The field:** the plot is 12 by 6 and lies on the farm at (22, 17); the village has none. The old plot's cells are its north-west corner.
- **Save version 6:** a section `homestead` (what is cleared for good; nothing clears anything until step 1b). `_v5_to_v6()` adds it and moves nothing.
- **The story's words,** exactly the plan's table: the title's line, four stages of the main quest, Elder Bram's welcome and his tale, and his supper's journal.
- **Nine test suites moved to the farm** with their checks: `farm_test`, `crops_test`, `farm_round_test`, `skills_test`, `upgrades_test`, `whole_story_test`, `mouse_test`, `farm_save_test`, `crop_save_test`.

**Picked up**
- **Kept as found:** all of the first subagent's code, data, map and moved tests. Every changed test was read line by line for a check weakened in the moving.
- **Three checks were looser than before the move, each for a reason that ends with step 1b:** two "he walks across the plot and stops at its far end" checks (`farm_test`, `crops_test`) said "at least as far", because on the farm nothing yet stands beyond the clear corner to stop him; and "every cell of the plot is open" says "open ground" for the whole field and "nothing stands on it" for the clear corner only, since the rest is to be overgrown. Step 1b puts the first two back at full strength.
- **Finished:** `tests/world/home_move_test.gd` was named by four other suites and did not exist. It was written: in and out of the farmhouse door; staying up, collapsing (on the farm and in the village) and sleeping each wake him in the farmhouse; the cottage shut at nine hours of the day and night with its words; the version 5 save opened in the world.
- **Fixed, three tests that had never been run:** the order of the saved cells (row by row, which the test had wrong); a comparison of whole numbers with the fractions a JSON file gives; and the whole story's walk out of the farmhouse, which began beside the door instead of at it.
- **The map and the village were baked already,** and baking them again gives the same two scenes, byte for byte.

**What differs from the plan**
- **Nothing in the map shifted:** it is the drawing, cell for cell.
- **The main quest's words are measured against the quest log's box,** where a test counted letters (150 at most). The approved words for two stages are longer, and fit.

**Verified**
- **959 tests in 127 suites, all passing** (935 in 123 before the Homestead). Twenty-four are new: the homestead as it is kept (5), the save (5), the map and the walk (6), the home's move (7), and the can at the farm's pond (1, where one test of the well and the pond became two).
- **The suites that moved were read against what they were before the move,** change by change (above).
- **The game boots headless** with no script error.
- **Baking `village` and `homestead` again changes nothing.**
- **The player's own save has the same checksum as before** (it is version 5 and was not opened).

**Known issues and limits**
- **Nothing is overgrown yet** (step 1b), and the farm plays the village's tune (step 1c).
- **`tools/playtest.gd -- farm`, `tools/play_days.gd` and twelve capture shots still take the plot to be in the village** (step 1c).
- **Not played by a person.**

## 2026-11-18 — The Homestead, phase 1, step 1b: the overgrowth

The second of phase 1's three steps (`docs/progress/homestead-plan.md`).

**Built**
- **145 things stand on the land in a new game,** where the plan's drawing put them: 70 weeds, 16 bushes, 10 fallen logs, 14 old stumps, 24 rocks, 8 boulders and 3 great boulders. 54 are on the field (40 weeds, 5 bushes, 5 rocks, 2 stumps, 2 logs), and none on its clear corner, the road, the path or the row before the farmhouse.
- **The sword clears** weeds in one blow (1 fibre), a bush in two (2 fibre), a log in three (3 wood) and a stump in three (2 wood). A bomb's blast is one blow of the same.
- **The pickaxe clears** a rock in two blows (1 stone). A boulder takes three blows of the Copper Pickaxe or two of the Iron (4 stone); a great boulder three of the Iron (8 stone).
- **A lesser pickaxe at a boulder** is told "It wants a better pickaxe.": no swing, no energy.
- **What one leaves lies in its cell,** and stays lying if the pack has no room for all of it.
- **Cleared is cleared.** The cell is kept in `GameState.homestead()` and the save's `homestead` section. No visit, morning or save brings it back; a new game starts overgrown.
- **Nothing is tilled under it:** the hoe, and the can, a seed and a sprinkler, say "Clear this first." and spend nothing.
- **Fibre,** a new material with its own picture. It stacks to 50. Nothing uses it yet.
- **All of it is data:** four breakables that never return, three kinds of rock in a new set of rules (`data/rules/homestead.json`), and one item.
- **Pictures, painted by the tools:** weeds, a bush, a log; a field stone, a boulder, a great boulder; fibre. Six new spawn markers are a row at the end of the tile atlas. Every older tile and frame is where it was, pixel for pixel (checked).

**What differs from the plan**
- **The numbers are the plan's table,** each one: counts, blows, drops, and the totals (102 fibre, 58 wood, 80 stone).
- **Twenty things moved a cell or two when the map was baked.** In the plan's drawing they stood behind a tree's crown: against the woods' edge on the west, east and south, or behind an old tree. A first screenshot showed stumps and weeds peeking from under the trees, and the hero stopped by things he couldn't see. Each was moved onto open grass nearby (three of them further, to keep the pond's banks and a great boulder's foot open). Nothing on the field moved, and every count is the plan's.
- **"Clear this first." is said to every tool of the plot,** not the hoe alone.
- **The land's stump is a breakable of its own** (`farm_stump`), with the countryside's picture: the countryside's comes back each morning.
- **Not in the plan, chosen and written down** (`docs/DECISIONS.md`): fibre's stack of 50; a left click with the hoe at weeds on the field says "Clear this first." (off the field it swings the sword, as before); a better hoe's stroke passes over a cell with something on it; stone from the land is no practice at mining, as plain stone in the quarry is none.

**Verified**
- **974 tests in 129 suites, all passing.** Fifteen are new in this step: the homestead's rules (4), the overgrowth in the world (9), a game saved where the plot lay in Hearthvale (1), and a new game's first day on the farm from the square to bed (1), which is the plan's "done when" in one test.
- **The two walks that step 1a had loosened are exact again:** across the clear corner he stops at its last cell, against the weeds beyond, and down through it at its last row.
- **Sixty bugs planted on purpose,** one at a time, each file put back, in the new code, data and scenes of steps 1a and 1b: **all sixty were caught.** Among them: nothing recorded as cleared; every map taken for his land; the homestead not saved, not loaded, or kept by a new game; no step from version 5; the old plot's size; a blocked cell tilled; a weak pickaxe swinging anyway; cleared weeds back on the next visit; a boulder that is a plain rock, leaves one stone, or puts its stone straight in the pack; a land rock broken only for today; each kind's blows, drop and pickaxe changed in its data; the cottage open for half an hour at midnight; the farmhouse door opening onto the village; the field a row too high; a quest stage too long for the log. A run of each suite with no bug planted reports nothing caught, so the catching is the tests' own.
- **One check was found empty by reading it, and fixed:** "nothing stands on the road" compared a cell against a word the area never gives. It now reads the tile under each thing. (By the way the map is drawn a cell is road or carries a thing, never both, and the road's 42 cells are counted elsewhere.)
- **Every older picture is unchanged:** the four repainted sheets were compared with the ones before, pixel by pixel, over the part that was there.
- **The game boots headless** with no script error.

**Known issues and limits**
- **Not played by a person.** How long the land takes to clear, and whether a swing that catches two weeds at once feels right, is for a playtest.
- **A swing of the sword cuts everything in its arc,** so weeds that stand side by side fall two or three to a blow. The plan's "about 250 energy for the whole land" is by the blow, and will be an overestimate.
- **Fibre has no use until phase 3,** and Tilda does not buy it (as planned).
- **The farm still plays the village's tune,** and the tools still take the plot to be in the village (step 1c).

## 2026-11-19 — The Homestead, phase 1, step 1c: the rest, and the phase as a whole

The last of phase 1's three steps (`docs/progress/homestead-plan.md`). **The phase was stopped a second time and picked up again.** The subagent that built step 1b went on to this step and was stopped partway, with nothing committed and no report. A third read what it left, file by file, against the plan, kept it, checked steps 1a and 1b again (nobody had reported on them), and finished. What was found is under "Picked up" below.

**Built**
- **Two tunes,** made in code by `tools/audio/make_audio.gd` and baked: `homestead` by day (D major, 92 beats a minute, a plain tune over a walking bass and a broken chord, no drums) and `homestead_night` after dark (the same tune in long notes at 66, every voice quieter than the game's own night tune).
- **The farm plays them:** its own tune by day, and from 20:00 its own night tune in place of the game's (`AreaController.night_music`, which only the homestead names). The farmhouse plays the day's at every hour. Every other place is as it was.
- **`tools/playtest.gd`:** a new scenario `homestead` (arriving by the lane with a sword, all three pickaxes, the hoe, the can and seeds; `-- homestead 20:30` for its night), and `farm` starts on the farm's road above the field's clear corner.
- **`tools/capture.gd`:** the ten shots that stood at the village's plot (110 to 112, 114, 116 to 119, 129, 153) stand at the field's clear corner under their old numbers and names. Nine new shots, 159 to 167: arriving on the farm, the farmhouse and its yard, the old cottage's words, the can at the pond, a boulder refusing the plain Pickaxe, the overgrown land, the farm at night, weeds cut on the field, and the field with its clear corner.
- **`tools/play_days.gd`** knows that his home is the farmhouse (out of its door is the farm, and the lane leads on to the village) and that the plot is on the homestead. It works the cells with nothing standing on them and fills the can at the pond. It does not clear land.

**Picked up**
- **Found in the tree, uncommitted:** the two songs in the audio tool with their baked files; the two scenes naming them; the game's list of tunes; a test of the tunes; the playtest scenarios; the capture shots; `tools/play_days.gd`'s changes; and this step's words in the README, the GDD, TECH_DESIGN, the roadmap, DECISIONS and the plan. Nothing was cut off mid-file, and the whole suite passed on the tree as found (977 tests in 130 suites). No log entry had been written.
- **Kept as found:** all of it. Baking the two tunes again gives the same two files, byte for byte, so the files are the tool's own.
- **Fixed:** capture shot 163 stood the hero below the boulder, where he is two cells tall and hid it: he stands beside it now. A comment in `tools/playtest.gd` still put his cottage at the west end of the lane (the plan lists it), and three comments in `tools/capture.gd` spoke of the cottage.
- **Nothing of phase 2 or later was found** in the tree: no build mode, placeables, buildings, hay, animals, wares or favours.
- **A mistake of this session's, undone:** it started, by its name, a bug-planting script the earlier session had left in the shared scratch folder. It was stopped within a minute. It had left one planted bug in `core/homestead/homestead.gd` (the homestead saved with nothing cleared), which was put back from the commit; the tree's whole diff was compared before and after and is the same.

**Steps 1a and 1b, checked again**
- **Every test the plan lists for phase 1 exists and is a real one:** the home's move (`tests/world/home_move_test.gd`), the save (`tests/autoload/homestead_save_test.gd`), the map (`tests/world/homestead_test.gd`, `farm_test.gd`) and the overgrowth (`tests/world/debris_test.gd`). Each was read.
- **The tests that step 1a moved to the farm were read against what they were,** change by change (`git show defc6c2 -- tests/`): twenty-three older suites. **No check was deleted or skipped.** The two walks that 1a loosened were made exact again by 1b. One check is different in kind and stays so: the main quest's words were held to 150 letters and are now laid out in the quest log's own label and held to its room, and to 200 letters (the approved words are longer than 150). A stage a page long fails it (planted, below).
- **The village's map, cell by cell, against the map before the Homestead:** six cells of the Height layer differ, (0..2, 16..17), the lane's west end, and seven of the Decor layer beside them. No spawn marker moved. The scene lost its `FarmPlot` and gained `WestRoad`, its entry, and the cottage door's hours.
- **Thirteen bugs planted,** one at a time, each file put back and compared: the farmhouse's door opening onto the village; waking outside the old cottage; the step from version 5 adding no homestead; that step emptying the plot; what the sword clears only cut for today; a cleared rock standing again on the next visit; a boulder's refusal spending a blow's energy; the plain pickaxe breaking a boulder; a quest stage a page long; and, for this step, the farm naming no night tune, the farmhouse playing the village's, an area's own night tune never asked for, and the game not knowing the farm's tunes. **All thirteen were caught.** No gap was found, so no test was added.

**What differs from the plan**
- **Shot 96 stays in the village,** with 115 (the well): the plan moves it to the farm with the plot's shots, but it is the picture the plan asks for as the "after" of the lane's west end, and it shows the locked cottage.
- **The moved shots keep their names as well as their numbers:** 97 is still "home" and 151 "the cottage furnished", to pair with the before-pictures.
- **Nothing else.** Every approved decision the phase touches (D1 to D11, D30) held as written, in all three steps.

**Verified**
- **977 tests in 130 suites, all passing** (974 in 129 after step 1b). Three are new: the farm's two tunes by day and by night, the farmhouse's tune and every other place as it was, and the night tune the quieter of the two.
- **The game boots headless** with no script error.
- **In a window, each for a few seconds:** `tools/playtest.gd -- homestead`, `-- homestead 20:30` and `-- farm` start with no error (about four seconds each).
- **Two days played by `tools/play_days.gd` at four times speed** (`days=2 speed=4`; 134 seconds). It left nothing out and wrote no fault: from the title's "New game" it walked to the farmhouse, took the tools, tilled, sowed and watered five turnips in the clear corner with the can filled at the pond, went on to the village for the sword, the weaver's shuttle and Tilda's Pickaxe, mined the quarry's first floors, and slept in the farmhouse both nights; on day 2 it watered, waited for Tilda to open, mined to floor 4, made the furnace and lit it. Its log and pictures are in `reports/homestead/phase1/play_days/`.
- **Seventeen pictures,** taken with `tools/capture.gd` from the finished tree and each looked at, in `reports/homestead/phase1/` (which git ignores): the title; the lane's west end and the cottage's door (96); the locked cottage's words (161); arriving on the farm (159); the farmhouse and its yard (160); inside it (97, 113); the field (110, 167) and its clear corner sown (116); the pond (162); a boulder (163); the overgrown land (164); the farm at night (165); weeds cut (166); the quest log (123); Elder Bram's welcome (124). No debris stands on the road, the path, the clear corner or behind a crown, and no crown covers the door.
- **The player's own save has the same checksum as before.**

**Known issues and limits, for the phase**
- **Nobody has played any of phase 1 by hand:** not the walk from the square, the farmhouse, the field, the pond, clearing the land, a night on the farm, or an old save opened in the farmhouse. The tests, the script's two days and the pictures are all there is.
- **Nobody has listened to the two tunes.** That the night tune is quieter is a sum of volumes in the tool, not an ear's judgement.
- **A swing of the sword cuts everything in its arc** (shot 166 shows three weeds falling to one blow), so the plan's "about 250 energy for the whole land" is an overestimate.
- **The script's days were played at four times speed and stop at day 2.** It never clears land, so the 54 overgrown cells of the field are not farmed by it: its days 4, 6 and 8, which sow "the whole plot", will sow the clear corner's 18 cells as before. Eight days at life's speed have not been played since the home moved; the walk to the farm costs each of them a few seconds.
- **Fibre has no use until phase 3.**
- **`docs/HOMESTEAD.md`,** an untracked copy of the request, was left as it is.
- **CLAUDE.md is as it was:** its words for phase 1 (the plan's R2 to R8, R18, R19) are the coordinator's to write, and the phase's report proposes them as built.

**Approved (phase 1).** The coordinator ran the full suite again (977 tests in 130 suites pass), confirmed the four commits and looked at the pictures; shown the summary and the pictures, the user approved phase 1 on 2026-11-19 ("Approve Phase 1"). Nobody has played it by hand. CLAUDE.md's rules now describe the game with phase 1 built. Phase 2 is next.

## 2026-11-19 — The Homestead, phase 2, step 2a: the rules and the mode

The first of phase 2's two steps (`docs/progress/homestead-plan.md`). Phase 1 was approved by the user the same day.

**Built**
- **Build mode.** B (or a click of a pad's left stick) opens it on the homestead, and only when the hero is free to act. Anywhere else it says "You can only build on your own land." While it is open he stands still and the clock with him, as at the workbench. B, Tab or Esc leave.
- **The ghost.** It shows the thing chosen on the cell the mouse points at, snapped to the grid; the movement keys move it a cell at a time. It is green where the thing fits and red where it doesn't, and a line of words over the bar says why, or what the thing is and how many he carries ("Fence x12").
- **Only what is on screen can be built on.** The ghost stops at the edge of the view, by the keys and by the mouse alike. To build further off he leaves, walks, and opens it again.
- **A left click sets the thing down** and takes one from the pack. **A right click takes up** what is under the ghost and puts it back in the pack: what stands there before what lies there. A full pack refuses ("You have no room for the Fence.") and the thing stays.
- **The build bar** takes the item bar's place: a slot for each thing he carries that can be set down, with how many. The wheel steps along it and the keys 1 to 9 choose a slot. Nothing of it is ever on the item bar.
- **The rules** are the plan's table, with its words: never on trees, water, the house or the map's edge ("Nothing can stand there."); the road, the path to the door or the way out ("That is the road."); a doorstep; the field ("That is your field."); where something stands to be cleared ("Clear this first."); where a thing of its kind is already ("Something is there already."); and, for a standing thing, the cell he is in ("Someone is standing there.").
- **Two things to a cell at most:** one lying and one standing. A fence stands on a paved cell.
- **Five things to set down:** the Dirt Path, the Stone Path and the Wood Path (lying), the Fence (standing, blocks) and the Gate (standing; the hero walks through it).
- **Collisions.** A fence fills its cell the moment it is set down and frees it the moment it is taken up. A path never blocks. Nothing else on the land changes for any of it.
- **Sorting.** Standing things are drawn with the hero by where they stand: he walks before a fence and behind it. Lying things are drawn flat under everyone, with a thin rim where nothing lies beside them.
- **A fence joins its neighbours:** a post, and a rail toward every fence or gate beside it. A gate is two capped posts with the way open; in a fence that runs north and south it is the two ends of the gap.
- **Kept and saved.** What is set down is in `GameState.homestead()` and in the save's `homestead` section. The save is still version 6: the two new parts are written only when something is set down, so a homestead with nothing on it is saved exactly as phase 1 saved it.
- **Two sounds,** made in code: a thing set down, and a thing taken up.
- **Pictures, painted by the tool:** a new sheet, `placed.png`, with the three paths, a fence's post and rails, and the gate's two pictures. A placeable's icon is its picture on the ground.
- **Tools:** `tools/playtest.gd -- build` (on the homestead east of the farmhouse's door, the ground cleared, with a stock of all five); four capture shots, 168 to 171.

**What differs from the plan**
- **Nothing in the approved decisions (D12 to D19).** D12 is built as written.
- **The farmhouse's doorstep says "That is the road."** It is the end of the path to the door, and the table lists the road first. No cell of today's land says "That is a doorstep.": the rule is there and tested by itself, for phase 3's buildings.
- **In this step the five things can only be had from the playtest scenario and the tests.** The workbench's "Place" tab is step 2b's, as the plan orders it.
- **Not in the plan, chosen and written down** (`docs/DECISIONS.md`): a placeable is an item of type `placeable`; the keys that do what the two mouse buttons do; a standing thing is not set down over something that lies to be picked up; which thing a right click takes first; the words the plan didn't give; what is chosen when the last of a thing is set down.

**Verified**
- **1021 tests in 133 suites, all passing** (977 in 130 before). Forty-four are new: Placement's rules (9), the build bar (5), what the homestead keeps (8), its save (3), and build mode in the world (19).
- **The plan's tests for this step each have one:** every refusal with its words, and the table's order; two things to a cell; only on the homestead; a fence that blocks at once and frees its cell at once; a path that never blocks; a gate walked through; save and load, with an older version 6 save and the version 5 one; the item back, and a full pack's refusal; the mode's keys and mouse; the clock standing; nothing set down outside the mode.
- **The two things the plan had not checked:** the ghost reads the mouse against the camera through the canvas's own transform (`make_input_local`), and it is right headless (a test points at a cell's last pixel and at the next cell's first) and in a window (below). A tall picture set down at run time is step 2b's (the grown tree).
- **In a window, with real keys and a real mouse** (a scratch script sending them through `Input`, about a second, the camera scrolled as far south as it goes): B opened the mode, the ghost went to each of four cells the mouse was put on, a left click set a fence down and a right click took it up.
- **In a window, about four seconds:** four capture shots, each looked at. A first look found the west rail of every fence drawn a cell too far east: fixed (below), and taken again.
- **The game boots headless** with no script error.
- **Planted bugs are the phase's last job,** after step 2b: see that entry.

**Found on the way, and left alone**
- **`SpriteSheet.draw()` puts a mirrored frame one frame's width to the right** in this engine (Godot 4.7.2): asked to draw at columns 40 to 55, a mirrored frame covers 56 to 71 (measured in a window with a scratch script). The engine keeps a negative-width rectangle's corner and mirrors the picture in it; `SpriteSheet` moves the corner right first. It is what draws a chicken, a goblin seen from the side, the Warden and the Shade when they face the other way. **It is older than this phase and not this phase's to change:** `PlacedArt` mirrors a fence's west rail itself, in place. It needs the user's word, and a look at each creature before and after.

**Known issues and limits**
- **Nobody has played it by hand.** Whether the ghost is easy to see, and whether laying a long fence a click a cell is a pleasure or a chore, is for the user.
- **A click sets down one thing.** There is no dragging a line of fence.
- **On a pad** the ghost moves a cell a press: slow over forty cells, as the plan warned.
- **The ghost starts on the cell the hero faces,** and jumps to the mouse as soon as it moves.
- **The dirt path is close in colour to the farm's own road.** It reads as laid by its rim.

## 2026-11-19 — The Homestead, phase 2, step 2b: the rest of the list, and the phase as a whole

The second of phase 2's two steps (`docs/progress/homestead-plan.md`).

**Built**
- **Ten more things to set down,** fifteen in all, as the plan's table has them:
  - **lying:** Wooden Flooring, Stone Flooring, and a Red, a Yellow and a Blue Flower Bed;
  - **standing, and in the way:** the Hedge, the Bench, the Lamp Post, the Oak Sapling and the Cherry Sapling.
- **The lamp post** is lit when the day's lamps are (18:30 to 06:30), with its burning picture and a steady light of the village lamps' own reach and colour. By day it stands dark.
- **Saplings** need no water. Each shows three pictures as it grows, changing with the morning, and is a tree after 4 mornings (oak) or 6 (cherry): one of the area's tall trees, which the hero walks behind and whose crown fades while he is there. It blocks its cell at every age.
- **Taking up a grown tree gives back its sapling** (D16), if there is room for it; the tree is felled. Set down again, the sapling starts over.
- **The hand** is the build bar's first slot. With it a left click lifts the thing under the ghost (what stands there before what lies there) and the next sets it down elsewhere, green or red as for anything else. The words say what a click would do: "Lift the Fence", "Set the Fence down here", "Put the Fence back". A right click, another choice, or leaving lets it go where it stood.
- **The workbench has two tabs,** as Tilda's counter has: "Make", the list as it was, and "Place", the nine things made there to be set down, at the plan's costs (a stone makes 4 dirt paths; a wood makes 2 fences; a lamp post is an iron bar, a coal and 2 wood). A and D turn the tab, and so does a click on its name.
- **Tilda sells** hedges (5 coins), the three flower beds (3 each), the oak sapling (10), the cherry sapling (30), and fibre five at a time (6), after her old wares and before the seeds. Nothing she sold before costs anything else.
- **Pictures, painted by the tool:** sixteen more frames at the end of `placed.png` (the nine frames of step 2a are where they were, pixel for pixel: compared). A lamp post is drawn lit and made dark, the yellow and blue flower beds are the red one in other colours, and a cherry sapling is an oak's in blossom: the tool can make a frame from another by swapping colours.
- **Tools:** `tools/playtest.gd -- build` carries all fifteen, with wood, stone and coins; five more capture shots (172 to 176).

**What differs from the plan**
- **Nothing in the approved decisions.** D12 to D19 are built as written, and D30 holds: the save is still version 6.
- **One reading of D16 to confirm** (`docs/DECISIONS.md`): the hand moves a thing as it is. A sapling keeps its mornings and a grown tree is a tree in its new place; it is a right click that takes a tree up and gives back a sapling. D16's "moving is taking up and setting down in one go", read to the letter, would turn a moved tree back into a sapling.
- **With the hand on the bar, the last of a thing set down leaves the hand chosen** (in step 2a, with no hand, the next thing was chosen).
- **Not in the plan, chosen and written down:** the nine recipes are known from the start; the workbench opens on "Make" each time; a lamp post has the village lamp's numbers; how a sapling's three pictures are spread over its mornings; no petals lie round a planted cherry tree; the stacks; the flower beds' names.

**Verified**
- **1038 tests in 134 suites, all passing** (1021 in 133 after step 2a; 977 in 130 before the phase). The phase's new tests: Placement's rules and what a placeable's data says (13), the build bar (5), what the homestead keeps (8), its save (3), build mode in the world (20), and the rest of the list in the world (12).
- **Every test the plan lists for the phase has one:** every refusal with its words; two things to a cell; only on the homestead; a fence that blocks the moment it is set and frees its cell the moment it is taken up; a path that never blocks; a gate walked through; save and load of what is set down, a sapling's age among it; a version 5 save and an early version 6 save still load; the item comes back; a full pack refuses; a grown tree gives a sapling; saplings by the morning; a lamp post lit at dusk; the mode's keys and mouse; the clock stands in it; nothing is set down outside it. The plan's "done when" is one test: a yard made at the bench, fenced, gated, floored and lit, saved, loaded, and taken up again piece by piece.
- **Older tests that changed, and why:** six suites counted Tilda's wares or the workbench's list (`tests/core/shop/shop_test.gd`, `tests/world/shop_test.gd`, `farm_round_test.gd`, `chest_test.gd`, `crafting_chain_test.gd`, `upgrades_test.gd`), one lists every item (`data_registry_test.gd`), and one checks that every item's picture exists (`sprites_test.gd`, which now looks in the new sheet for what is set down). Each keeps its checks: the shop's now carry sixteen wares and their sum (153 coins for one of everything), and the workbench's ask for the "Make" tab, whose thirteen recipes are as they were.
- **88 bugs planted on purpose,** one at a time, in the phase's runtime code and data, each file put back and compared: **84 were caught at the first try, and the 4 that were not each showed a gap that has a test now and is caught.** The four: a fence that ran a rail to a hedge beside it; a held key that didn't repeat (the test pressed the key twice where a keyboard echoes it); the shut mode setting a thing down when a thing had been chosen in it before; and a lifted thing still lifted after leaving (the mode let go twice, once as it closed and once as it opened: it lets go in one place now). Among the 84: a thing set down off his land, on a tree, the road, the field, debris or the hero; two of a kind in a cell; setting down that costs no item; taking up that gives nothing back, or that a full pack doesn't stop; a fence that doesn't fill its cell, a gate that does, a cell still filled after its fence is taken up; the land not following what changes; the ghost leaving the screen; the mouse read without the camera; a click that sets down where the ghost was and not where the mouse is; the clock running in build mode; build mode in the village; B, Tab or Esc not leaving; no morning for a sapling, a tree a morning late, a tree that goes on ageing, a moved sapling losing its mornings; a sapling's age not saved; what stands not loaded; a thing on the wrong layer loaded; a lamp post that burns all day, flickers, shows its dark picture, or gives the area no light; a tree still standing after it is taken up; the hand setting a thing down where it doesn't fit; both tabs listed at once; a click on a tab's name making a thing; the workbench opening on the tab it was left on; the hand missing from the bar; and seven numbers changed in the data (a gate that blocks, an oak of five mornings, a hedge that lies, one fence to a wood, a lamp post without coal, a hedge for six coins, fibre one at a time). A run of the same suites with no bug planted reports nothing.
- **The two things the plan had not checked:** the mouse against the camera (step 2a's entry), and a tall picture set down at run time: a grown sapling is stood by the same code that stands the map's trees (`Scenery.stand()`), sorted by its foot like them, and a picture shows the hero behind one with its crown faded (173).
- **In a window:** nine capture shots (168 to 176), taken several times over as things were fixed, about half a minute of window in all, and each final picture looked at; seven scratch probes of a second or two each (real keys and mouse in build mode, twice; where a mirrored frame is drawn; a fence's rails, before and after the fix; and the ghost at 23:00 under the HUD's corner box, twice: it is drawn under the box and keeps its green in the dark). The real mouse matters in a window: where the pointer is over it, the ghost goes, in a probe and in a capture alike. `tools/playtest.gd -- build 18:20` was started and closed itself after five seconds, with no error. `tools/play_days.gd` was not run. No Godot process was left running, and the player's own save is as it was (its file's date is unchanged).
- **The game boots headless** with no script error.

**Found by looking at the pictures, and fixed**
- **A fence's west rail was drawn a cell too far east** (step 2a's entry): `PlacedArt` mirrors in place now.
- **A capture's flower bed lay on the farmhouse's wall:** the capture tool sets things down through `GameState.set_down()`, which trusts whoever calls it to have asked `Placement` first, as build mode does. The shot's cell was wrong, not the game: nothing in play can do it.
- **The "Place" tab's shot showed no "Made:" line:** moving the cursor clears it. The shot makes the thing last.
- **Two shots had the hero standing over a flower bed,** hiding it: he stands beside the yard in them now.

**Known issues and limits, for the phase**
- **Nobody has played any of it by hand.** The tests, the pictures and a second of real keys and mouse sent by a script are all there is. What that can't tell: whether the ghost is easy to see against grass and at night; whether a click a cell is a pleasant way to lay thirty fences; whether the words are read at all; how the mode feels on a pad.
- **A click sets down one thing.** There is no dragging a line.
- **With more than eight kinds of thing in the pack the build bar moves along,** as the item bar does, and the key 1 is then the leftmost slot showing, not always the hand. The wheel always reaches it.
- **The engine lights one drawn thing with 16 lights at the most,** and the area keeps to 14: each lamp post is two (a pool and a glow), so with more than seven in view the narrowest are dropped, as the plan's risks say.
- **A planted cherry tree has no petals lying round it** (the map's petals are laid once, as the area loads).
- **A vertical run of fence** is thin posts and a beam between them: it reads, but less well than a run from east to west.
- **`SpriteSheet.draw()` puts a mirrored frame a frame's width to the right** (step 2a's entry). Left alone: it needs the user's word.
- **Placeables can be put in the storage chest,** like anything that stacks, and can't be sold: Tilda buys none of them.
- **CLAUDE.md is as it was:** its words for phase 2 (the plan's R10 to R14) are the coordinator's to write, and the phase's report proposes them as built.

**Approved (phase 2).** The coordinator ran the full suite again (1038 tests in 134 suites pass), confirmed the two commits and looked at the pictures; shown the summary and the pictures, the user approved phase 2 on 2026-11-19 ("Approve Phase 2"), as built. Nobody has played it by hand. CLAUDE.md's rules now describe build mode and the placeables. Phase 3 is next, stopping at its end.

## 2026-11-19 — The Homestead, phase 3, step 3a: plans, kits, sites, the Well, the Silo and hay

The first of phase 3's three steps (`docs/progress/homestead-plan.md`).

**Built**
- **The workbench's third tab, "Build",** lists the plans with their materials and coins ("Coins 0 of 80"). A plan refused says what is short, by name ("You are short of 40 Stone, 10 Wood and 80 Coins."). Bought, it is a kit in the pack.
- **A kit** (an item of type `kit`) never stacks, never goes in a chest and is never on the item bar; the build bar shows it. One of each building: a plan is refused while its kit is in the pack, its site is set down or its building stands.
- **In build mode a kit's ghost** covers every cell of its building and the doorstep before its door, green or red over all of them with the first reason found (D15). Set down, it is a building site today: dug ground pegged out with twine, a stack of timber, its cells filled. **The next morning the building stands** (any morning), and the hero is told with a short sound (`built`), where he is or where he next arrives.
- **The Well** (2 by 2; 40 stone, 10 wood, a copper bar, 80 coins; known once a copper bar is found): the can fills facing any of its cells once it stands. It wears the village well's own picture.
- **The Silo** (2 by 2; 30 stone, 10 wood, 2 copper bars, 100 coins; known at Farming 2): a right click puts in the hay he carries, up to 60; what doesn't fit stays in the pack.
- **The meadow's fourteen tufts of tall grass** (D29): cut, each leaves a hay lying and is back the next morning. Nothing can be set down on a tuft that stands.
- **A building is drawn as the farmhouse is:** flat tiles on the ground (the village's own house tiles and five new ones at the end of the atlas, with a silo), a house's shadow east and south, and a ridge strip over its roof that the hero walks behind.
- **Data:** a building is a file in `data/buildings/` (`docs/data/building.schema.json`); the plans are files in `data/crafting/` with `"tab": "build"`. **The save stays version 6:** the section `homestead` gains `buildings` and `hay`, written only when there is something in them.

**What differs from the plan**
- **Nothing in the approved decisions.** D20, D21 and D29's hay hold as written.
- **The open point the brief named:** phase 2 left the tufts plain grass, so a save may have something set down on one. **A tuft doesn't grow where something lies or stands, or a building covers it;** taken up again, the tuft is back on the next visit. Nothing is lost.
- Chosen where the plan was silent (`docs/DECISIONS.md`): the ghost holds a building by its door; the doorstep is asked the plan's table as every cell is; a path may lie under a building; a building's cells say "Nothing can stand there."; the Well casts no shadow; nothing takes hay out of the silo.

**Verified**
- **1069 tests in 138 suites pass** (1038 in 134 before). New: the buildings' rules (`tests/core/homestead/building_rules_test.gd`), what the homestead keeps of them (`homestead_buildings_test.gd`), the Build tab's rules (`tests/core/crafting/crafting_build_test.gd`), the plans in the world (`tests/world/plans_test.gd`: the tab, the kit, the ghost's refusals, a site through a save and the morning, the well, hay and the silo, a tuft under a phase 2 yard), and a save from phase 2 (`tests/fixtures/saves/v6_a_yard_on_the_farm.json`, written by the game at `57e7d3a`).
- Older tests brought up to date: the workbench's tabs (three now) and the registry's list of items and breakables.
- The game boots headless with no script error.

**Known issues**
- Nobody has played it by hand. The rooms, upgrades, moving and demolishing are steps 3b and 3c.

## 2026-11-19 — The Homestead, phase 3, step 3b: rooms, the shed's chests and furnace, the upgrades

**Built**
- **The Coop** (4 by 3; 30 wood, 20 stone, 15 fibre, 250 coins; known once wood is found), **the Barn** (6 by 4; 30 wood, 40 stone, 25 fibre, 4 iron bars, 600 coins; Farming 3) and **the Shed** (4 by 3; 30 wood, 20 stone, 15 fibre, 2 copper bars, 200 coins; a copper bar found), each with its own small room (`coop`, `barn`, `shed`, 11 by 9) entered by its door, whose doormat leads out before the door wherever the building stands. The rooms stand empty of animals.
- **The Shed's two chests and second furnace,** made at the workbench once it stands, for what their like costs in the farmhouse, each in its own place in the shed; each furnace one load a night. `GameState.furnace()` and `store()` are still the farmhouse's; the shed's are `furnace(&"shed")`, `store(&"shed_a")`, `store(&"shed_b")`.
- **The Big Coop** (20 wood, 10 fibre, 2 iron bars, 350 coins) **and the Big Barn** (30 wood, 30 stone, 2 gold bars, 800 coins), bought like a plan once the building stands and finished the next morning, the same place and size, room for 8 animals (data that phase 4 will read). Each wears a different roof.
- **The save is still version 6:** the shed's furnace and chests are kept in `homestead` by key, written only when they hold something.

**What differs from the plan:** nothing in D20 to D23. Chosen where the plan was silent: the doors' cells and the rooms' furniture, the shed's three recipes on "Build", the big forms' roofs (`docs/DECISIONS.md`).

**Verified:** 1075 tests in 139 suites pass, with the new `tests/world/rooms_test.gd` (in and out of each room in two places, a site without a door, the doorstep kept free, the shed's chests and furnace through a save, the two upgrades, the seven plans' costs and unlocks against the plan's table and its sums, the rooms' size and names). Nobody has played it by hand.

## 2026-11-19 — The Homestead, phase 3, step 3c: moving and pulling down

**Built**
- **Moving** (D24): in build mode the hand lifts a building (or a site) from any of its cells and sets it down elsewhere, at once and for nothing, as it is: the silo's hay, the shed's chests and furnace, its upgrade, its door and the entry before it go with it. It is refused where it doesn't fit, with the first reason found; its own cells are no hindrance to it.
- **Pulling down:** a right click on a building asks first ("Pull down the Coop? Right click again. Back: 15 Wood, 10 Stone and 7 Fibre."), and a second pulls it down. Only an empty building goes: no hay in the silo, nothing in the shed's chests or furnace, each refusal saying why. Half of each material that went into it comes back, rounded down, its upgrade's too; no coins; what the pack can't take is laid at his feet.
- **A site taken up** (a right click) gives its kit back whole.
- **Tools:** `tools/playtest.gd -- buildings` and `-- built`; capture shots 177 to 191.

**What differs from the plan:** nothing in D24. Chosen where the plan was silent: the second right click as the asking, a site taken up for its kit, the shed's furnishings staying with its room, and (to put to the user) that nothing takes hay out of the silo, so a silo with hay can't be pulled down until phase 4 (`docs/DECISIONS.md`).

**Verified:** 1080 tests in 140 suites pass, with the new `tests/world/building_moves_test.gd` (a building moved with what is in it and refused where it doesn't fit, a site moved and taken up, the question and the pulling down, only an empty building, an upgrade's refund and what doesn't fit at his feet). The two scenarios were started in a window for four seconds each, with no error.

## 2026-11-19 — The Homestead, phase 3 as a whole: buildings

The three steps of phase 3 (`docs/progress/homestead-plan.md`), committed one by one: 3a plans, kits, sites, the Well, the Silo and hay; 3b the rooms, the shed's chests and furnace, the upgrades; 3c moving and pulling down.

**1080 tests in 140 suites pass** (1038 in 134 before the phase), and the game boots headless with no script error.

**The plan's "done when"** is tested end to end: each of the five can be bought (`plans_test`, `rooms_test`), set down (`plans_test`), found standing the next morning (`plans_test`), entered where it has a room (`rooms_test`, in two places), moved (`building_moves_test`), upgraded (`rooms_test`) and pulled down (`building_moves_test`).

**Every test the plan lists has one:** a kit set down is a site today and a building at dawn, through a save; one of each; the doorstep stays free; a plan refused without its coins or materials says what is short; the well fills the can; hay is cut, carried and stored, and a full silo leaves it in the pack; in and out of each room wherever its building stands; the shed's chests and furnace through a save; moving with what is in it, refused where it doesn't fit; pulling down refused unless empty, half of each material given, what doesn't fit laid at his feet; a phase 2 save loads.

**Planted bugs:** 54, one at a time, in the phase's runtime code and data, each file put back byte for byte and compared. **50 were caught at the first try; the 4 that were not each showed a gap that has a test now, and each is caught** (planted again after the test was added). The four: the ghost holding a building by the middle of its row instead of its door (the same cell for all five as they are drawn: a test with a door off the middle now); the Silo's `put_hay()` taking hay for a site (build mode's spot asked first, so play was right: `GameState` is asked itself now); a kit kept out of a chest only because it doesn't stack (a test of the kit's type now); and the Shed's door moved in its data (the tests read the door from the data: the doors are checked against the decisions now). Among those caught: the doorstep above the door, a door filled, the doorstep not asked, a whole refund or coins given back, a site standing the same day, two of a building, hay not saved, an upgrade for a site, a move that moves nothing, a silo without a limit, one of each forgotten, a kit set down that stays in the pack, no morning's news, demolition with full chests or hay, a refund added and not given (lost to a full pack), the upgrade not refunded, the shed's chests not saved, the shed's chests or furnace the farmhouse's, a plan that doesn't say what is short, a site taken up for nothing, a building's cells left open, a site that is a well, the room's entry on the door instead of the doorstep, a door that doesn't follow a move, a site with a door, a building's cells or doorstep built on, tall grass no hindrance, pulling down without asking, a moved building in its own way, the question outliving the ghost's move, tufts under things, the well no water, no news where he arrives, the doors not marked before he arrives, a built unlock always known, the shed's chest or furnace opening the farmhouse's, the furnace's key left out, kits off the build bar, and six numbers in the data (the silo's 60, the well's 80 coins, the coop's size, the tall grass back every visit, the barn at Farming 3, the big coop's 8).

**In a window:** capture shots 177 to 191, taken twice (about twelve seconds of window each time; the second time with the coop moved off the farmhouse's side and the window's mouse warped to the ghost's cell, which the first time had dragged the ghost away), and each picture looked at; `tools/playtest.gd -- buildings` and `-- built`, four seconds each. `tools/play_days.gd` was not run. No Godot process was left running; the player's own save was not touched (the tests use their own slots, the tools 900 and 994).

**Found by looking at the pictures, and fixed:** the Coop set down against the farmhouse's east wall read as part of it (the shots put it on the land west of the house now); the ghost followed the window's real mouse, not the cell the shot named.

**Known issues and limits**
- **Nobody has played any of it by hand:** only the tests, the pictures and two four-second starts.
- **Nothing takes hay out of the silo,** so a silo with hay can't be pulled down until phase 4's animals eat it (put to the user).
- **A building is drawn flat, as the farmhouse is:** its windows don't light at night (nobody lives in it), and only a roof's ridge rises above its cells.
- **The Big Barn wears the Shed's slate:** the two look alike but for the barn's red planks.
- **The site's twine** is drawn on each cell's top and left edges, so a site reads as a pegged-out grid, open on its right and bottom edges.
- **CLAUDE.md is as it was:** its words for phase 3 (the plan's R4, R7's hay sentence, R8's shed sentence, R9, R10's `build` tab) are the coordinator's to write; the phase's report proposes them as built.

## 2026-11-19 — The Homestead, phase 3: three looks the user asked for

The user approved phase 3 and asked for three changes of look, nothing else, before phase 4.

- **The Coop's roof** is wooden shingles gone silver-brown in the weather (`roof_shingle`), no longer the farmhouse's thatch. The Big Coop keeps its red tiles.
- **The Big Barn's roof** is green boards with standing seams (`roof_green`), no longer the Shed's blue slate (the small Barn keeps its red tiles).
- **The Shed's room** has a rack of tools (a rake, a spade and a saw) at (3, 2) and sacks on a crate at (7, 2) where its two bookshelves stood. Both are solid furniture as tall as the shelves were, so the same cells block and the same cells are free; re-baking the shed (`build_maps.gd -- shed`) changed those two cells of its Height layer and nothing else (checked cell by cell). The chests, the furnace, the rug and the doormat are where they were.

**The atlas:** four new rows at the end (34 rows now; no older tile moved). Rows 30 to 32 hold the two roofs' eighteen tiles (`GreyboxTiles.ROOF_B_KINDS`, laid as `HOUSE_KINDS` are, eight to a row: the shingles at (0..7, 30) and (0, 31), the green boards at (1..7, 31) and (0..1, 32)); row 33 holds `tool_rack` (0, 33) and `sacks` (1, 33) (`FURNITURE_C_KINDS`). All painted by `make_tile_texture.gd`. **The relief atlas is 96 by 112** (it was 96 by 96): the two roofs' ridge strips are rows of their own (`ReliefAtlas.ROOF_STYLES` has five styles), painted by `make_relief.gd`. `Buildings.detail()`, its check of a look, `Scenery.ROOF_TILES` and `build_tileset.gd` know the two styles.

**Verified:** 1080 tests in 140 suites; one fails, `tests/gameplay/sprites_test.gd` `test_villagers_wear_their_own_colours`, for the run's order on this machine only (`tests/gameplay` alone passes, 29 of 29). No test needed changing. The game boots headless with no script error. Capture shots 181 and 185 to 190 were taken before and after and looked at: only the two roofs and the shed's two cells changed (185 and 186 are the same to the pixel).

**Seen, not changed:** the Coop's room has the same bookshelves along its back wall (two runs of three `shelf` tiles, meant as perches and nesting boxes); the Barn's room has tables and barrels, which read well enough.

**Approved (phase 3).** Moved to a cloud session, the coordinator installed Godot 4.7.2 there (Linux), ran the full suite (1080 tests; one fails, the known villager-colour test, for the run's order: on Linux `tests/world` runs before `tests/gameplay`; `tests/gameplay` alone passes 29 of 29), and took shots 177 to 191 again under a virtual display. Shown the summary and seven pictures, the user approved phase 3 on 2026-11-19 ("Approve, fix looks first"): the Coop's roof, the Big Barn's roof and the shed's bookshelves changed first (above), and a silo with hay stays one that can't be pulled down ("Keep as built"). CLAUDE.md's rules now describe the buildings. Nobody has played it by hand. Phase 4 is next, stopping at its end.

## 2026-11-19 — The Homestead, phase 4, step 4a: the rules (animals as data, herd and pasture, Oda's stall, the save)

The first of phase 4's three steps (`docs/progress/homestead-plan.md`).

**Built**
- **Three kinds of animal as data** (`data/animals/`, `docs/data/animal.schema.json`): the Chicken (lives in the Coop, an egg every morning, 4 cells of grass), the Sheep (the Barn, wool every third morning, 6 cells) and the Cow (the Barn, milk every second morning, 8 cells), each with its sound. The egg, the wool and the milk are items, with icons; the egg and the milk can be eaten raw (6 and 18 energy).
- **The herd's rules** (`Herd`, `core/homestead/`, pure): each morning, in the order they were bought, each animal eats its grass from its building's pasture while there is enough, else a hay from the silo, else goes hungry (D25); fed and petted the day before it comes a whole morning nearer its product, fed only half a morning, unfed none, and a product waiting stops the next (D27). Bought only for a building that stands, with room (4, or 8 for the big one).
- **Pastures** (`Pasture`, pure): the ground reached from a building's doorstep without crossing anything standing (a gate counts as fence), a building, debris or anything solid; ground that reaches the road or a way out is no pasture; a path, floor or flower bed, and the field, are crossed and not grazed. The land as it was is read from its scene once a run (`LandSurvey`, `LandMap`), so a morning knows each pasture while the hero sleeps in the farmhouse.
- **`GameState`**: `pasture_of(id)`, `has_pasture(id)`, `pastures()`, `animals_in(id)`, `why_not_buy_animal()`, `buy_animal()` (and `buy()` of an animal ware), `pet_animal(index)`; the morning in `start_next_day()`; a building with animals can't be pulled down.
- **Farmer Oda's stall:** the village re-baked once more, the market stall's six tiles at (16..18, 30..31) beside her. Her conversation gains "Have you any animals to sell?", which opens her list (`data/shops/oda.json`: the Chicken 60, the Sheep 180, the Cow 240). Refused without a building or with it full; bought, it is in its building ("Bought: a chicken. It is in your Coop.").
- **The save is still version 6:** `homestead` gains `animals`, written only when there is one.

**What differs from the plan:** nothing in D25 to D28 or D30. Chosen where the plan was silent (`docs/DECISIONS.md`): steps of half a morning; "unhappy" as the morning's hungry; the herd fed in the order bought; what stops a pasture; the land read from its scene; the price in the shop's data; Oda's stall the village's stall tiles again.

**Verified:** 1102 tests in 144 suites pass but the one known on this machine (`sprites_test.gd`'s villagers' colours, which fails only when Linux runs `tests/world` first). New: `tests/core/homestead/herd_test.gd` (every row of the morning's table, a waiting product, pasture before hay before hunger, a shared pasture, a full building and a big one of eight, the herd through a save), `pasture_test.gd` (a pen, a gap, the road, a floor), `tests/autoload/animals_state_test.gd` (Oda's list, buying refused and bought, a pen on the land with a gate, a gap and a floor, a morning's feeding, petting and a full pack, pulling down, a save, the phase 3 fixture `v6_buildings_before_animals.json`, the land read from its scene), `tests/world/oda_stall_test.gd` (the stall's cells, her list opened from her conversation). The village's reachable cells are six fewer (`home_test`, `nature_test`).

## 2026-11-19 — The Homestead, phase 4, step 4b: in the world (out by day, in by night, petting, sounds)

**Built**
- **The three animals as creatures** (`Animal`, `gameplay/interactables/`): the hen is the village's chicken, the sheep and the cow a new sheet (`animals.png`, 24 by 20: standing, walking, grazing, blinking), all from `tools/art/make_sprites.gd`. Each wanders among its own cells (`AnimalMotion`, pure), blocks nobody and is never in the way.
- **Out by day, in by night** (D28, R5): `PlacedAnimals` (on the homestead and in the coop's and the barn's rooms) shows, on the land by day, the animals of each building with a pasture, wandering in it; in a room, those living there that are not out (all of them from 20:00 to 06:00). Nobody walks them: at the hour they are where they belong.
- **One right click pets and takes** (D26): "Pet the Chicken", or "Take the Egg" when one waits over her head; her cluck; a full pack leaves the egg waiting. An animal that went hungry this morning shows it.
- **Build mode** sets nothing standing on an animal's cell ("Someone is standing there.") and holds the animals still while it is open.
- **Sounds:** `cluck`, `bleat`, `low`, made in code.
- **`tools/playtest.gd -- animals`:** a coop and a barn with fenced pastures, a silo with hay, four hens, two sheep, two cows, one of each kind with its product ready.

**What differs from the plan:** nothing in D26 or D28. Chosen where the plan was silent: an animal's cells (its pasture, or its room's floor) rather than the terrain; build mode holding them still; what is ready shown in a bubble (`docs/DECISIONS.md`).

**Verified:** 1111 tests in 146 suites pass but the known one. New: `tests/world/animals_test.gd` (out by day with a pasture and in without; in at 20:00, out at 06:00; each within its pasture for twenty seconds and blocking nobody; build mode holds them still; nothing set down on one; a right click pets and takes, a full pack leaves the egg; a sheep and a cow in the barn at night, with their sounds; a hungry one shows it) and `tests/core/homestead/animal_motion_test.gd`. The scenario was started in a window with no error.

## 2026-11-19 — The Homestead, phase 4, step 4c: into the rest (products, three dishes, Tilda's prices, cloth and the blanket, Farming)

**Built**
- **The three dishes** (`data/recipes/`), known from the start and cooked at the hearth: a Fried Egg (an egg: 20 energy), an Omelette (two eggs and a mushroom: 50 energy and half a heart) and a Custard (an egg and milk: 65 energy and a heart). An egg and milk are eaten raw (6 and 18) and given as gifts like any food.
- **Tilda buys** the egg (8), the milk (30), the wool (40) and cloth (100): four lines of her data.
- **Woven at the workbench** ("Make"): Cloth (2 wool; known once wool is found), which is worth more than its wool, and a Wool Blanket (2 cloth), a furnishing that lies over the bed in the farmhouse, for show.
- **Farming rises by tending:** the deed `tend`, a point for each product taken (ten raise a level).
- **Pictures:** seven icons (the egg, wool, milk, cloth, the three dishes), the blanket; **shots** 192 to 203 in `tools/capture.gd`.

**What differs from the plan:** nothing in the table or D30. Chosen where the plan was silent: the blanket a furnishing of the farmhouse over the bed's cell; cloth and the blanket known once their makings are found; the deed's name (`docs/DECISIONS.md`).

**Verified:** 1117 tests in 147 suites pass but the known one. New: `tests/world/animal_products_test.gd` (the egg and the milk raw and as a gift; the three dishes known and cooked at the hearth; Tilda's four prices and cloth worth more than its wool, at her counter; cloth and the blanket woven, the blanket on the bed and the bed still the bed; ten eggs taken raise Farming; and the plan's "done when": a hen, a sheep and a cow bought from Oda's list, fed by hay and by pasture, petted, each ready on its morning, the products cooked, sold and given). Older tests brought up to date: the hearth's list (ten dishes), Tilda's list of what she buys, the workbench's "Make" tab (fifteen), the furnishings (five), the registry's items.

## 2026-11-19 — The Homestead, phase 4 as a whole: animals

The three steps of phase 4 (`docs/progress/homestead-plan.md`), committed one by one: 4a the rules (animals as data, the herd and pastures, Oda's stall, the save); 4b in the world (out by day, in by night, petting and taking, the sounds); 4c into the rest (the products sold, cooked, given and woven, Farming).

**1118 tests in 147 suites pass** (1080 in 140 before the phase) but the one known on this machine: `sprites_test.gd`'s villagers' colours, which fails only because Linux runs `tests/world` before `tests/gameplay`, and passes with `--add res://tests/gameplay` alone (29 of 29). The game boots headless with no script error.

**The plan's "done when"** is tested end to end (`tests/world/animal_products_test.gd`): a hen, a sheep and a cow bought from Oda's list, fed by the silo's hay and by a pasture, petted, each with its product on its morning, and the products cooked, sold and given; the stall's list and its refusals in the village (`oda_stall_test`); out by day, in by night, a right click (`animals_test`).

**Every test the plan lists has one:** each row of the morning's table, a product that waits and stops the next, pasture before hay before hunger, a full building and a big one of eight (`herd_test`, `animals_state_test`); a gap in the fence, a gate as fence, a floor not grass (`pasture_test`, `animals_state_test`); buying refused without a building or room, and an animal bought in its building (`animals_state_test`, `oda_stall_test`); in at 20:00 and out at 06:00, one click pets and takes, a full pack leaves the egg (`animals_test`); the dishes cook, Tilda buys, cloth is worth more than its wool, Farming rises (`animal_products_test`). And a save from the end of phase 3 loads with its buildings and no animals (`v6_buildings_before_animals.json`).

**Planted bugs:** 67, one at a time, in the phase's runtime code and data (the herd's rules, pastures, the land's survey, `GameState`'s herd, the save, Oda's wares, the animals in the world, the right click, build mode, the motion, the blanket, and every number of the three kinds, the prices, the dishes, cloth and Farming's deed), each file put back byte for byte and compared, against the phase's eight suites. **62 were caught at the first try; the 5 that were not each showed a gap that has a test now, and each is caught** (planted again after the test was added): a site counted as having a pasture; two doors on one pasture not sharing its grass; a room's animals allowed on the doormat; an animal reached from two cells off; the farmhouse's door not read as a way out (the map's path tiles hid it).

**In a window:** capture shots 192 to 203, taken three times, each picture looked at; `tools/playtest.gd -- animals` started for twenty seconds with no error. `tools/play_days.gd` was not run. No Godot process was left running; the player's own save was not touched (the tests use their own slots, the tools 900 and 994; the fixture was written in a checkout of `21199f6` on slot 940, emptied after).

**Found by looking at the pictures, and fixed:** what an animal had ready was first drawn in a square box, too big indoors and floating two cells high; it is a small round badge just over the head now (the bare icon, tried between, read as an egg lying on the grass and the wool as a second sheep). The sheep shot had the hero hiding the sheep (he is two cells tall), the silo shot hid the silo, and the barn pasture shot stood him on a bush: each was moved.

**Known issues and limits**
- **Nobody has played any of it by hand:** only the tests, the pictures and a twenty-second start.
- **The coop's room still has its shelves of books** (the user named only the shed's), so the hens sleep under bookshelves.
- **An animal starts on a random cell of its ground each time an area loads,** so the animals are somewhere else after every door; they never remember where they stood.
- **The village's chickens are drawn a frame's width to the right when they face right** (`SpriteSheet.draw`, older than the Homestead and left alone); the farm's hens, sheep and cows are mirrored in place.
- **The hearth's list reads "Omelette (2 Egg, 1 Mushrooms)"**: it uses each item's own name, as "Carrot Cake (2 Carrot, 1 Wheat)" did before.
- **CLAUDE.md is as it was:** its words for phase 4 (the plan's R5's second sentence, R13's animals, R15, R16, R18's `animals`) are the coordinator's to write; the phase's report proposes them as built.

**Approved (phase 4), 2026-11-19.** Checked in the cloud container before the review: the full suite,
1118 tests in 147 suites, with only `sprites_test.gd`'s run-order failure (it passes with `tests/gameplay`
alone); the twelve capture shots looked at. The user answered "Approve, fix looks first": a pasture stays as
built (anything standing closes one; the meadow's tall grass is grass), and the badges over the animals are
smaller. The badge is now a 10-pixel bubble with the product drawn at half size and a tail pointing down at
the animal (`Animal._draw_ready()`), where it was a round badge of 19 pixels with the full icon; shots 193,
196 and 197 were taken again and looked at, and the suite is as it was. Known: when animals crowd together,
a bubble can still be hard to tie to its animal; nobody has played phase 4 by hand. CLAUDE.md has phase 4's
words.

## 2026-11-19 — The Homestead, phase 5, step 5a: two favours

Tilda's "Market Day" (six eggs; 50 coins and 2 Carrot Cakes) and Farmer Oda's "A Roof for the Flock" (a coop standing on the farm; 60 coins and 5 hay), both at three marks, both data: a quest each in `data/quests/`, and an opening on `friendship` 3 and four nodes in each conversation, of the shape of Wenna's and Edda's. Tilda's comes after her carrot cake (taught at two marks since P4d); Oda's after his seed wheat of two marks. The rewards are `give_item`, so a full pack loses none of them.

**One piece of code:** the flag `built/<id>` (`GameState.built_flag()`), true while a building stands: set by `start_next_day()` the morning a site stands, erased by `demolish()`, and put right by `from_dict()`. Oda's quest and his answer "My coop is built." ask `built/coop`. No new condition type, no save version.

**The quest count is thirteen:** `quests_test` (the list), `friends_open_test` (the quest log: fourteen lines with Back, walked again), `whole_story_test` (the ending's "2 of 13"). Recipes are fourteen, as phase 4 left them.

**Verified:** 1129 tests in 148 suites pass but the known `sprites_test.gd` run-order failure. New: `tests/world/homestead_favours_test.gd` (11 tests: each favour asked at three marks, put off, taken, reminded, handed over and never again; the lesson, the wheat and the present first; a site is no coop, a coop pulled down undoes it, a coop built before the asking counts; the flag through moves, a demolition beside a site and a save; older saves; a full pack; the quests' shape and the count).

**Planted bugs:** 19, one at a time, in `game_state.gd`'s flag code and the four data files, each put back byte for byte (compared), against the new suite. 17 caught at the first try; 2 were not (a site counted as built by the flag's sync; the day a loaded flag came true), each closed by a test, and caught when planted again.

**Pictures:** shots 204 to 207 (`f:ask:` and `f:done:`), each looked at. In Oda's two the hero is under the conversation's box, as in shot 192.

## 2026-11-19 — The Homestead, phase 5, step 5b: ten days played

`tools/play_days.gd` plays ten days now (`days=` up to 10), and is taught the farm: the field cleared with the sword and the pickaxe, wood, stone and fibre gathered off the field, the workbench's three tabs (D turns them), kits set down in build mode by the keys (B, the wheel, the movement keys for the ghost, Space), a pen of six fences and a gate before the Coop, hens bought at Oda's stall, and every animal petted with a right click. Days 4, 6, 8 and 10 are farm days; 5, 7 and 9 the quarry (the Lantern on day 9). `farm` is a five-day trial of the farm alone, its makings handed over. The day's record (`days.json`) carries the farm at dawn and dusk: buildings, animals, materials, the field's clear cells, the pen.

**The report** is `docs/progress/homestead-balance-report.md`. Played at life's speed from the title, 2325 seconds; the animals in a second life-speed run of five days (`-- farm`). In short: the field was cleared on day 4 for 30 energy; the Well stood on day 8 (its copper bar waits on coal); the Coop was not reached in ten days (the purse never passed 165, as every harvest is sown again); four hens give four eggs a morning on a pen of sixteen cells. Three numbers are proposed for 5c, none changed: the Coop's coins (250 to about 150), the Well without its copper bar, wood to stack to 50.

**Verified:** 1129 tests in 148 suites pass but the known `sprites_test.gd` run-order failure (the tool has no tests, as before). Runs: two at life's speed (the second is the report's; the first had a fault of the last day since mended: the bars were sold before the Well was made), four ten-day trials and two `farm` trials at four times speed, each a slot of its own (956), emptied. Pictures looked at: the pen, the Well set down, the workbench's "Build" tab, the field on day 10.

**Known issues and limits**
- **One life run is one roll of the quarry:** coal came on day 3 in the report's run and on day 9 in the other, and the Well's day follows it.
- **The sites of the buildings and the pen are fixed cells** chosen from this map's overgrowth; a change to the farm's map would want them chosen again (the script says "!!" when a ghost doesn't fit).
- **Nobody has played the Homestead by hand;** the script never reached a favour (three marks), a sheep, a cow, the Silo or hay.

**The Homestead's phase 5, step 5c (2026-11-19).** Checked before asking: the suite after 5a and 5b, 1129
tests in 148 suites, only `sprites_test.gd`'s run-order failure; the favours' shots (204, 206) and the
tenth day's picture looked at. The user settled the numbers: the Coop 150 coins (was 250), wood stacks to
50 (was 30), the Well as it was. Tests that carried the old numbers were changed (`rooms_test`, the plans'
sum 2280; `wood_test`; `crafting_chain_test`; `building_moves_test`'s full stack). The suite is as it
was. Known: the ten days were not played again with the new numbers; nobody has played phase 5 by hand,
and no run has reached the favours or the Silo, sheep and cows.

## 2026-11-19 — Tool polish, phase 0: the plan

The user's words: "now polish the graphics and all animations when using tools". The plan is
`docs/progress/tool-polish-plan.md`: what each tool looks like in use today, what is proposed (four work
poses for the hero, the tool drawn in his hands in its three metals, the blow's effects and sound at the
moment the tool lands, rocks, logs and stumps that show each blow, work by hand shown, and three
unfinished things: mirrored frames drawn a frame's width to the right, a building site's twine that reads
as a grid, and the buildings' dark windows at night), thirteen decisions for the user, and four steps.
**Nothing is built until it is approved.**

**Seen in the before-pictures** (films of each stroke, twelve pictures 0.04 s apart, from a scratch
script; and 26 shots of `tools/capture.gd`): every tool, seed and the sprinkler plays the sword's three
swing frames with nothing in his hands, while the tool's icon bobs over the cell (`ToolFlash`); facing
up, the icon is drawn on his back; the can neither tips nor splashes; a rock breaks into the pot's
terracotta shards; a log or a stump shows nothing until its last blow; picking a crop and taking from an
animal don't move him at all.

**Where it bends a rule:** the new bursts (clods, drops, a ring on the water, seeds, chips, splinters,
chaff, a heart) are small things that fly, against "A still world"; each is tied to a stroke or a touch,
half a second or less, falling or fading where it is, and is put to the user (D5, D8). No timing, hit or
collision changes: the frames read the motor's progress, and only when pictures and sounds show moves
(D3, D4).

**In a window:** the capture shots, about half a minute; the scratch film script and a probe, a few
seconds a run, about twenty runs. No Godot process was left running; no save slot but the capture's own
(994) was touched. No tests were run (no code changed).
