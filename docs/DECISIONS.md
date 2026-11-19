# Decisions

Record design/technical decisions not covered by the docs. Newest at the bottom.
Format: `YYYY-MM-DD — Decision — Why — Alternatives considered`

- 2026-11-06 — Godot 4 + typed GDScript — free, good 2D tooling (TileMapLayer, AStarGrid2D), text-based scenes Claude Code can edit — Unity (licensing, heavier), GameMaker (weaker for data-driven systems and testing).
- 2026-11-06 — Discrete per-district water levels (no fluid simulation) — keeps the consequence math testable and designable — real-time fluid sim (expensive, unpredictable).
- 2026-11-06 — gdUnit4 for tests — most complete Godot 4 test framework with headless CLI — GUT.
- 2026-11-06 — Vertical slice before open world — proves the core mechanic is fun before scaling content.
- 2026-11-06 — Switched from 3D to **2D top-down** — much cheaper art, simpler for one developer and for Claude Code; Zelda-style top-down suits sailing and open-world exploration — side-view (great water visuals but awkward open-world sailing), isometric (art and sorting cost).
- 2026-11-06 — Per-tile terrain height + per-district water height, one scene per district — the map reacts to water automatically and new water levels don't need new scenes — one hand-authored scene per water level (more control, much more work).
- 2026-11-06 — Godot **4.7.2** via winget (user scope), with a `godot.cmd` shim in the package folder — winget cannot create its `godot` alias without admin — admin install; full path only.
- 2026-11-06 — **GL Compatibility** renderer — the game is 2D-only and the budget is 60 fps on integrated graphics (the dev machine is Intel integrated) — Forward+ (heavier, no 2D benefit).
- 2026-11-06 — gdUnit4 **6.2.3** from its GitHub tag (repo is now `godot-gdunit-labs/gdUnit4`), committed in `addons/` — tests must run headless from a clean checkout — Asset Library install (needs the editor UI). Headless runs need `--ignoreHeadlessMode` because InputEvents aren't delivered; no test uses input yet.
- 2026-11-06 — `res://data/<kind>/`: the directory decides the kind (`water`, `items`, `factions`, `quests`, `dialogue`); quests and dialogue are one object per file — adding content never touches DataRegistry — top-level keys decide the kind (ambiguous when a file mixes kinds).
- 2026-11-06 — DataRegistry resolves **every cross-reference at load**, including ids inside conditions/effects and quest/dialogue graph targets — broken content fails at startup, not mid-quest — validate lazily when content is used.
- 2026-11-06 — `docs/data/*.schema.json` are documentation/editor aids; **DataRegistry is the authoritative validator** — Godot has no JSON Schema validator and adding one is a dependency — a GDScript JSON Schema implementation.
- 2026-11-06 — Dev-only scenes live in `world/dev/` (an addition to TECH_DESIGN §1) — M0 needs a runnable scene that is not a district — `tests/` (gdUnit4 scans it).
- 2026-11-06 — Save format v1 has no companion `approval` yet; it arrives with companions in M8 — adding a key is not breaking while no saves exist — an empty `approval` now.
- 2026-11-06 — GameState restores whole-number floats in `player`/`boat` as ints on load — JSON can hand back 12 as 12.0 and cells/heights are ints — store numbers as strings.
- 2026-11-06 — **Water conservation: districts accumulate `pending` water** and rise a level only when a full step of their own volume has arrived — TECH_DESIGN §3.1's `ceil(volume / target step)` created water (50 units in, 100 units of rise) and contradicted the worked example (2 × 50 into Greenterrace = exactly one level); TECH_DESIGN §3.1 updated — keep `ceil` (breaks conservation and the example), reject partial steps (can't drain St. Aud one level via the pump at all).
- 2026-11-06 — Cascades visit each district at most once per change and **never flow back into the district being changed** — prevents loops and pumping water uphill into itself — allow backflow (infinite loops, nonsense results).
- 2026-11-06 — **Raising** pulls one step from the node's direct target only (no pulling through its outflows), and is rejected if the target lacks the water — simplest inverse of lowering that conserves water — pull along the network (much harder to preview and explain).
- 2026-11-06 — Pumps, sluices and outlets behave identically in the solver for now; they differ only in data and presentation — nothing in the docs gives them different rules yet.
- 2026-11-06 — **GameState is the single truth for water state**; `GameState.water_network()` builds a fresh WaterNetwork from data plus state on demand, and `apply_water_change()` records a previewed change — a cached network could drift from what gets saved — keep a long-lived network in sync by hand.
- 2026-11-06 — `water_level_changed` fires only when a district's *level* changes; water building up toward a level (`pending`) emits nothing — pending water changes no tile, so nothing needs to redraw — a separate pending signal (add when UI needs it).
- 2026-11-06 — `WaterSolver.apply()` returns bool and refuses a rejected or stale change (state moved on, or node broken since the preview) — the preview the player confirmed must be exactly what happens — apply whatever was passed.
- 2026-11-06 — Save format v1 gains `water_pending` and `network_nodes` — needed to restore the network exactly; adding keys is not breaking while no saves exist — nest pending inside `water` (changes the documented shape).
- 2026-11-06 — Water volumes, capacities and stored amounts must be **whole numbers** (DataRegistry + schema) — exact integer conservation — floats (rounding drift).
- 2026-11-06 — Movement rules: a swimmer's level is the water surface; a ±1 move is a walk if *either* cell is a ramp; any rise onto a climbable cell is a climb; stepping from deep water into shallows is a walk; drops into deep water never damage — TECH_DESIGN §3.4 doesn't pin these down; these are the simplest consistent readings.
- 2026-11-06 — `world/dev/m0_smoke` renamed `dev_smoke` — it now grows with each milestone.
- 2026-11-07 — **Player movement is grid-checked by a pure `PlayerMotor`** (`core/player/`, one script per state: ground, swim, climb); `PlayerController` only feeds input and draws, and CharacterBody2D physics stays unused until M7 — TECH_DESIGN §3.4 asks for grid checks, and generated physics shapes would duplicate the same rules — `move_and_slide` against per-height collision.
- 2026-11-07 — Ground vs swim **follows the cell underfoot** (deep = swim), so a water change can never leave the player in an invalid state; climbing is the only modal state and a water change ends it — explicit transitions on every water change.
- 2026-11-07 — Climbing starts only on a firm (cardinal) push into a climbable higher cell, so brushing a wall diagonally slides along it. Push to climb up, away to climb down. Stamina drains even while hanging, and running dry drops you (damaging from 3 levels) — GDD/TECH_DESIGN don't specify the controls.
- 2026-11-07 — Movement tunables as `PlayerMotor` constants, not data yet: walk 72 px/s, sprint ×1.6, swim 44 px/s, climb 2 levels/s, stamina 100 (sprint −20/s, climb −18/s, regen +30/s, sprint locked out until 25) — tune by playtest; move to data if designers need them.
- 2026-11-07 — **Fall damage is reported, not applied** (signal + HUD message) — health arrives in M7.
- 2026-11-07 — Greybox tiles are generated (`tools/greybox/`): a PNG atlas and one TileSet with custom data layers `height`/`climbable`/`ramp`/`dive_point`, shared by the Height and Water layers — CLAUDE.md allows no external art yet.
- 2026-11-07 — **St. Aud's layout is authored as rectangles in `tools/greybox/build_st_aud.gd` and baked into the Height TileMapLayer**; after that the TileMapLayer is the source of truth (re-baking overwrites editor painting) — TECH_DESIGN §3.2 makes the layer the source, and 4,096 hand-placed cells isn't practical — generate the layer at runtime from text (loses editor painting).
- 2026-11-07 — Level-gated places are `PointOfInterest` nodes that set visited flags: rooftop door (flooded only), clinic balcony hatch (waist only, added so every level opens something), subway entrance (drained only) — ROADMAP M2 names the first and last.
- 2026-11-07 — Debug water cycling uses `GameState.set_water_level()` (bypasses conservation, now clears pending water), debug builds only, F2 / gamepad Back.
- 2026-11-07 — Input uses **physical keys** (WASD stays put on any layout, including Icelandic), written to project.godot by `tools/setup_input_map.gd`. Sprint = Shift / LB / L3, interact = E / A.
- 2026-11-07 — The water redraw is synchronous and the fade plays after it — state changes stay instant and testable — fade out, redraw, fade in (adds latency and async).
- 2026-11-07 — Layout additions to TECH_DESIGN §1: `core/player/` (pure player logic), `world/tiles/` (tile set and atlas), `tools/` (dev-only scripts, not game code).
- 2026-11-07 — St. Aud is the main scene; `world/dev/dev_smoke.tscn` stays runnable directly. Collision generation and pathfinding from TECH_DESIGN §3.3 step 3 and `WaterVisibility` are deferred to when something needs them (M7/M5).
- 2026-11-07 — **The player gets a Zelda-style pixel-art sprite before the slice is done**, at the user's request — an exception to "placeholder art until the roadmap says so"; still made in code (ASCII art → PNG by `tools/art/make_player_sprite.gd`), no external assets. It's an **original character** in the *A Link to the Past* style (16×24, 4-direction walk): a green hooded salvager's coat, tan trousers, boots, and the Network Key glowing on the belt, not a copy of Link (Nintendo's character) — a Link lookalike.
- 2026-11-07 — Sprite animation is a pure `PlayerAnimator` (`gameplay/player/`, unit-tested): 4-way facing where diagonals keep a matching facing, a walk cycle (idle, step, idle, step) that advances by distance travelled, a back view while climbing, and head-and-shoulders when swimming. Right-facing frames are the left ones flipped — fewer frames to draw.
- 2026-11-07 — **Every district has a Harbour (dry at every level) and a Mooring.** If a water change grounds the boat it moves to the nearest deep cell (rider and all); with no deep water left it **waits at sea off the harbour**, a rider steps ashore where it was, and you walk out from the Harbour to board it. Arriving from the sea works the same way — ROADMAP M3's "moved to the nearest deep tile" has no answer when a district has no deep tiles (drained St. Aud, dry Greenterrace), and a naive rule could strand the player for good — teleport the boat to the map edge; refuse the water change.
- 2026-11-07 — Boat steering is **steer-toward-input**: the boat turns toward the stick or keys at a fixed rate, thrusts along its heading (scaled by how well it's aligned), and sideways speed decays faster than forward speed, which gives the drift — works the same on keyboard and gamepad — tank controls (awkward with 8-way keys and sticks).
- 2026-11-07 — Boat tunables are `BoatMotor` constants for now: max 110 px/s, acceleration 150, turn 3.5 rad/s, forward drag 0.9/s, sideways drag 5/s, radius 6 px.
- 2026-11-07 — You can **board while swimming beside the boat** as well as from an adjacent dry or shallow cell; going ashore needs a neighbouring dry or shallow cell you could *walk* onto from the water (no climbing out), preferring the cell ahead — TECH_DESIGN §4 names only dry/shallow; refusing swimmers felt like a trap.
- 2026-11-07 — **Spire Nine is a single-level district** in `data/water/spillway.json` ("sea", water height 4, no network nodes) — the district code needs a water height, and Spire Nine's water never changes — special-case districts outside the network.
- 2026-11-07 — The **sea map is its own scene** (`world/sea/`) at a fixed water height (4), with a `SeaPort` per district: sail into its footprint to enter; leaving that district puts the boat back at the port's exit cell, heading away. Leaving a district by **any** map edge returns to its port.
- 2026-11-07 — **Travel state lives in GameState** (`boat`: where, cell, heading, moored_at; `player`: on_boat, arriving, came_from) and each map rebuilds itself from it on load. Scenes change with `change_scene_to_file`, through a `travel` callable that tests replace — a scene-manager autoload (a fifth autoload, not needed yet).
- 2026-11-07 — `tools/greybox/build_st_aud.gd` became `build_maps.gd`, which bakes all four maps (or the ones named).
- 2026-11-07 — **`ConditionEvaluator` implements the whole condition vocabulary now** (pure, `core/quests/`, evaluated against a `GameState.to_dict()` snapshot) — `repair_requires` is already data and DataRegistry already validates every type; half an evaluator would be a trap for M8/M9 — only `has_item`.
- 2026-11-07 — **Repairing a node uses up the items its `repair_requires` asks for** (the valve is fitted) and emits `EventBus.network_node_repaired` — the docs don't say; keeping the part felt wrong — add explicit `on_repair` effects to node data (do it if a node ever needs something else).
- 2026-11-07 — The Pump Valve lies on **Spire Nine's platform** (an `ItemPickup` with a taken-flag), so the M4 loop uses the boat — M4 needs the item to come from somewhere; Spire Nine is the settlement — next to the pump (no reason to travel).
- 2026-11-07 — The pump is on **St. Aud's lookout tower**, reachable at every water level — it must stay usable after draining (to drain again or raise back) — a pump house that drained water would cut off.
- 2026-11-07 — The **Network Key is always available**, not an inventory item — GDD: an inherited device; nothing yet takes it away.
- 2026-11-07 — **Mini-map positions are data**: optional `"map": [x, y]` on districts and basins (DataRegistry + schema). The preview draws a box per entry with a before/after water gauge, pipes as lines, and the node in use as a flow arrow; amber = changes, red = floods — positions hand-placed in the UI (not reusable for other regions).
- 2026-11-07 — The Network Key preview **pauses the game** (panel `process_mode = ALWAYS`) and defaults to **Lower**. Up = Raise, Down = Lower, E confirms, Esc cancels; a rejected change shows its reason and can't be confirmed.

## 2026-11-07 — Pivot to Hearthvale (supersedes the water-era entries above)
- 2026-11-07 — **The game becomes Hearthvale: a land-based, A Link to the Past-style action-adventure** that starts in a small medieval village, with dungeons, enemies, puzzles, multiple weapons and hearts — the user's decision. The water-level design (Low Tide, M0–M4) is archived on the **`water-version`** branch; every water, boat, sea, Network Key, swimming, climbing, stamina, St. Aud, Spire Nine and Greenterrace decision above is superseded.
- 2026-11-07 — **Kept from Low Tide:** project skeleton, DataRegistry, GameState/SaveSystem, height-based terrain (now land rules), PlayerMotor (ground state only), the hero sprite and PlayerAnimator, the physical-key input map, the greybox tools, ConditionEvaluator, ItemPickup and the HUD. Removed: water network and solver, boat and sea, Network Key, swim/climb/boat states, flooded districts and their data.
- 2026-11-07 — **Life is Zelda-style hearts**: start with 3, health counted in half hearts, a heart container adds a heart and refills; `EventBus.health_changed` drives the HUD's `HeartsBar` — the user's choice over a health number.
- 2026-11-07 — **No climbing, sprint or stamina**; classic movement: stairs bridge one level, ledges can be hopped down from any height (one way, never hurt), solid tiles block — the user's choice for a classic Zelda feel.
- 2026-11-07 — Tiles gain a **`solid`** flag (replacing `climbable`); the greybox atlas is redrawn with material rows (grass by height, stone stairs, dirt path, and solid trees, rocks, walls, red/blue roofs, water, fences, stone). Solids have a fixed shading height so they cast edges.
- 2026-11-07 — Areas live at `world/areas/<id>/<id>.tscn` run by an **`AreaController`** (generalised from DistrictController); interactables sit under `Interactables` and expose `covers(cell)`.
- 2026-11-07 — Milestones are renamed **H0–H9** so they don't clash with the water-era M1–M4 in the log.
- 2026-11-07 — The condition vocabulary shrinks to `flag`, `has_item`, `quest_stage`, `all`/`any`/`not`; effects to `set_flag`, `give_item`/`take_item`, `set_quest_stage`, `complete_quest`. Factions, companions, attributes and dialogue skill checks are gone (not in the new design); combat and dungeons add types when needed.
- 2026-11-07 — Save format v1 is redefined (hearts, flags, quests, inventory, area and cell); no saves exist, so no migration.
- 2026-11-07 — The working **name is Hearthvale** — the user's choice; it is also the starting village.

## H1 — Village life
- 2026-11-08 — **Doors are walk-in, not interact**: stepping onto a door tile (or a house's doormat) changes area, as in classic Zeldas. `AreaExit` nodes name a target area and entry point; each area's `Entries` holds named `Marker2D`s whose rotation is the arrival facing. A doormat leads to the entry just outside its own door, so you come out where you went in.
- 2026-11-08 — **`GameState.player` holds an `entry` instead of a cell while the hero is going through a door** (`go_to`); the arriving area places them and the next `update_player` replaces it with a cell. Save v1 stays: the change is additive, and a save taken mid-door still loads at the right place.
- 2026-11-08 — Scene changes still go through a replaceable `travel` callable on the area (as on the water branch), not a scene-manager autoload.
- 2026-11-08 — **Interact order:** pick up what's underfoot first, else talk to whatever is in the cell the hero faces (the facing the sprite shows, so diagonals follow the animator).
- 2026-11-08 — **Villagers and signs occupy their cell**: `TerrainQuery` gained dynamic occupied cells (BLOCKED, reason "occupied"), which enemies will use too.
- 2026-11-08 — **The hero stands still while the dialogue box is open** (`PlayerController.controls_enabled`), instead of pausing the tree: nothing else moves yet, and it keeps scene tests simple. Revisit when enemies arrive (H3).
- 2026-11-08 — **Dialogue files may have a `speakers` map** (speaker id → display name). A missing speaker shows its id capitalised; an empty speaker (signs) shows no name. A node with no options shows "[E]" and interact ends it. A villager's name (for the prompt) is the start node's speaker.
- 2026-11-08 — `EffectApplier` applies effects through GameState's own methods (so signals fire) and works on any object with those methods (a stand-in in tests). `complete_quest` isn't applied yet: it needs a running quest (QuestRunner).
- 2026-11-08 — **Interiors are their own small areas** (11×9 rooms: log walls, wooden floor, the way out a doormat in the bottom wall). A room smaller than the screen is centred, on a dark clear colour (`default_clear_color`). Two new atlas rows: walkable door/floor/rug/doormat at height 0, and solid inner wall/table/bed/shelf/barrel/hearth.
- 2026-11-08 — **Areas are y-sorted** (root and `Interactables`), and villagers/signs are drawn with their feet mid-cell like the hero, so the hero passes in front of or behind them correctly.
- 2026-11-08 — Content kept to what H1 needs: Elder Bram (blue-roofed house; "I'll keep watch." sets `promised_elder_keep`, after which he answers differently), Wenna the weaver (an extra answer once the flag is set) and a welcome sign. The other two village houses stay closed.

## H2 — Sword & hearts
- 2026-11-08 — **Hit detection is code, not physics.** `HitBox`/`HurtBox` are plain Node2D circles (the sword an arc), and `AreaController.resolve_combat()` checks contacts every physics frame with the pure `CombatRules`. TECH_DESIGN §4 said Area2D components, but movement is grid-checked rather than physics, and code checks are deterministic in headless tests (no waiting frames for overlaps). Teams are `hero` and `enemy`; a hit only crosses teams.
- 2026-11-08 — **Sword:** a 120° arc in front of the hero (the way the sprite faces), 20 px reach from the feet, hitting each target once per swing. The swing lasts the weapon's `cooldown`, and the hero stands still for it. Damage, knockback and cooldown are item `stats` in data (Wooden Sword: 2, 40 px, 0.3 s); the strongest held `weapon_melee` is used, so an Iron Sword later is data only.
- 2026-11-08 — **Attack action:** Space or J, gamepad X. It swings on the press, detected by the controller from the held state, so `Input.action_press` drives it in headless tests. It does nothing without a sword.
- 2026-11-08 — **Getting hit:** knockback at 160 px/s for the hit's push distance, through the terrain rules (off a ledge yes, through a wall never), with no control meanwhile. Then 1 s of invincibility with a blinking sprite. Input doesn't turn the hero during a swing or a knockback.
- 2026-11-08 — **Hazard: brambles.** A HitBox on the enemy team costing half a heart with 32 px knockback. They don't fill their cell, so an invincible hero can push into them; they bite again when invincibility ends.
- 2026-11-08 — **Death:** at zero hearts the hero lies still (tinted) for 1 s, then is placed at the **area entrance** with full hearts and a screen flash. The entrance is the cell they arrived at: the entry point they came through, or the spawn or saved cell for a new or loaded game. It's re-placed in the same scene, not reloaded (nothing else in an area resets yet). No game-over screen.
- 2026-11-08 — **Recovery hearts** (`HeartPickup`, +1 heart) are collected by touch, not E, and come back on every visit (not saved), as dropped hearts will in H3. The Wooden Sword stays an E pickup with a taken-flag, like other items.
- 2026-11-08 — The training dummy is on the enemy team, so brambles never hit it. It stands in its cell through a general `occupies()` check (Talkables use it too). It counts hits, and wobbles and flashes when struck.
- 2026-11-08 — The village's fenced field becomes the **training yard**: the Wooden Sword, the dummy, three brambles and a heart. Item pickups now draw by item type (a sword picture for `weapon_melee`; a brass token otherwise).

## H3 — Enemies
- 2026-11-08 — **A small greybox South Field is H3's enemy ground**, through the gap at the end of the village's south road (a four-cell `AreaExit`, which gained a `size`). The countryside proper is H8, but enemies need somewhere in the game to patrol. H8 grows this area rather than starting over.
- 2026-11-08 — **The hero's grid movement became `GridBody`**, shared with enemies (PlayerMotor extends it), so everything walks by one set of rules. **Enemies never hop down ledges** (`allow_drops = false`), so a goblin on a plateau stays up there, though anything may take stairs. **Bats fly** (`TerrainQuery.check_flight`): heights and ledges don't stop them; solid tiles and the map edge do. That's how ROADMAP's "respect cliffs, ledges and solid tiles" applies to a flier.
- 2026-11-08 — **One enemy per file** in `data/enemies/` (like quests), with a behaviour id per AI. A new behaviour is an `EnemyBrain` subclass, listed in `EnemyBrains` and `DataRegistry.ENEMY_BEHAVIOURS` (a test checks the two match). A class-reference dictionary can't be a GDScript constant, so `EnemyBrains` uses a `match`.
- 2026-11-08 — **Enemy health is in weapon damage points** (Wooden Sword 2): slime 2 (one hit), goblin archer 4 (two), bat 1. Contact damage is half hearts like everything else.
- 2026-11-08 — **Drops are a weighted table** of `heart`, `item` (coins, with a count) and `nothing`; one entry is rolled on death (`DropTable`, pure). Hearts reuse `HeartPickup`; coins are a new `ItemDrop`. Both are collected by touch and gone for the visit. The area now picks up anything with `touches()` and `collect()` (`collect_pickups`, formerly `collect_hearts`).
- 2026-11-08 — **Behaviours:**
  - Slimes move in hops (about 15 px, then a rest) and lunge when close.
  - Goblin archers back off inside 40 px, close in beyond 88 px, and sidestep to line up on a row or column. They shoot only from a distance, after a 0.5 s draw (the tell: bow pulled back, arrow nocked, a "!" overhead), then wait 1.6 s.
  - Bats rest, flit, zigzag at the hero with a new jittered heading every 0.2–0.45 s, and swoop when close.
  - Every enemy wanders within 48 px of home, notices the hero within its `sight`, and gives up beyond 1.6 × sight.
- 2026-11-08 — **A hit stuns an enemy for 0.3 s** and pushes it back by the weapon's knockback (terrain rules apply). It can't be hit again while stunned, and afterwards it chases the hero. Arrows fly straight in one of four directions, over heights, and stop at solid tiles, the map edge, or on hitting.
- 2026-11-08 — **Enemies come back on every visit** and nothing about them is saved; drops vanish when you leave. Random numbers come from the area's `RandomNumberGenerator` (randomised on load), so tests seed it, and an enemy's `roll_drop` can be swapped to choose a drop.

## Sprint
- 2026-11-08 — **The hero can sprint** (hold Shift / gamepad B): 120 px/s instead of 72, at the user's request. This reverses the pivot's "no sprint" for sprint only; there's still **no stamina**, so it never runs out, and still no climbing or swimming. GDD §5 and CLAUDE.md were updated first. Sprint speeds up walking only: a swing still roots the hero, and knockback keeps its own speed. The `sprint` action left `setup_input_map.gd`'s retired list.

## H4 — Items & weapons
- 2026-11-08 — **The Bow lies in the South Field ruin for now**, with a bundle of ten arrows. GDD §5 makes it the first dungeon's item, but the keep is H7 and H4 needs arrows in the game. When H7 builds the keep, it moves the pickup there; the bow itself is all data and code that stays.
- 2026-11-08 — **Stack limits are enforced in `GameState.add_item`** through `Inventory.capacity` (the item's `max_stack`, or 1 for single items; no limit for ids with no data). It returns how many were added. Gifts and pickups beyond the limit are simply not taken.
- 2026-11-08 — **One item on the item button: `GameState.equipped`**, saved with the game as an additive key, so the save version stays 1. The first equippable item picked up (bow or bombs) goes on the button by itself. Equipping announces `EventBus.equipped_changed`.
- 2026-11-08 — **The item button** (Q or K, gamepad Y; next to E and Space on the keyboard) is handled by the area, which has the terrain and can place arrows and bombs.
  - The bow roots the hero for its cooldown (the sword's attack state) and fires the H3 `Arrow`, now on either team, the way the hero faces.
  - Bombs go down at the hero's feet. They burn a 2 s fuse whose spark blinks faster as it runs down, then blast a 24 px radius once.
  - With nothing equipped, or no ammo, a message says so.
- 2026-11-08 — **The hero's own bombs don't hurt them** (the blast is on the hero team), for now. One HitBox damage number can't be half hearts for the hero and health points for enemies at once. If self-damage is wanted, the blast needs a second, hero-scaled hit.
- 2026-11-08 — **The item menu** (Tab or I, gamepad Back) lists the equippable items held in pickup order, with their ammo (`Bow (Arrows x10)`, `Bombs x3`). E equips and closes; Tab just closes; the hero stands still meanwhile. The HUD gained an "Item:" line, and its hint is two lines.
- 2026-11-08 — **The shop is a conversation in data** (`data/dialogue/shop_tilda.json`), built from existing effects (`take_item`, `give_item`) and conditions (`has_item`, `not`, `all`).
  - Each buy option shows only when you can afford it and have room for the whole lot. Otherwise a same-named option leads to Tilda's "come back when…".
  - A `can_carry` condition type would make the room check read better; add it if more shops appear.
  - Prices: ten arrows for 5 coins, three bombs for 8.
- 2026-11-08 — **Tilda's shop** is the red house beside the training yard (door at (8, 24)), the same 11×9 room as the other houses, with shelves and an open counter.

## H5 — Dungeon framework
- 2026-11-08 — **A dungeon is one area cut into equal rooms** (`room_size` on its AreaController; `RoomGrid`), rather than one scene per room. Doors are then just nodes in walls; enemies, arrows and bombs need no hand-off between scenes; and the whole dungeon's state is in one place.
  - The camera shows only the hero's room, centred when smaller than the screen.
  - A `RoomMask` shades everything else. Without it, a 15x11 room centred on a 30x17-cell screen showed the rooms above and below.
  - A room change dims the screen for 0.2 s; there's no scroll animation yet.
- 2026-11-08 — **Dungeon state is flags, named by `DungeonState`:** `dungeon/<id>/keys` (an int), `dungeon/<id>/big_key`, `dungeon/<id>/door/<door>`, `dungeon/<id>/chest/<chest>`. Keys belong to their dungeon, as TECH_DESIGN §6 says, so they're counts in flags rather than inventory items. Chests turn `small_key` and `big_key` contents into those flags. The items stay in data (with a new `big_key`) for their names.
- 2026-11-08 — **Doors open with E while facing them** (as chests and people do), not by walking into them. A locked door spends a small key; the boss door needs the big key and keeps it. A closed door fills its cells (TerrainQuery occupied cells), refreshed whenever any flag changes.
- 2026-11-08 — **Shutters open on a flag**, and a room is "cleared" when every enemy sharing an Enemy's `clear_flag` is beaten (the area sets the flag). Enemies come back on the next visit, but the flag, and so the open shutter, stays.
- 2026-11-08 — Doors between rooms go through a two-cell wall (each room owns its walls), so a door shows half in each room. Each cell of a locked or boss door draws its own lock, so both halves read as a door.
- 2026-11-08 — **E uses anything with `use()` and `prompt()`** in front of the hero, after pickups underfoot and people: doors and chests now, puzzle pieces later. `use()` returns the message for the HUD.
- 2026-11-08 — **The H5 test dungeon is the Ruin Cellar**, down a stairway in the South Field ruin. It has three 15x11 rooms stacked north to south: an entry hall (small key chest, locked door), a hall (two slimes, a shuttered alcove with the big key, the boss door), and an inner room (20 coins, where a boss room would go). H7's keep is the real dungeon; the cellar can stay as a side dungeon or go then. The ruin's roosting bat moved one cell aside, off the stairway.
- 2026-11-08 — New tiles: `dungeon_floor` and `stairway` (walkable; a stairway leads down into a dungeon or back up), and `dungeon_wall` and `pillar` (solid).

## Art pass
- 2026-11-08 — **The environment gets proper pixel art now**, at the user's request ("make the village more pretty and the environment and graphics better"). This is a second exception to "placeholder art until the roadmap says so", after the hero sprite. Everything is still painted in code by `tools/greybox/make_tile_texture.gd`, with no external assets; CLAUDE.md records the exception.
  - Tiles: grass with blades and speckles, pebbled paths, stone steps, leafy trees with trunks and shadows, mossy boulders, timber-framed walls on stone footings, clay and slate roofs, rippled water, capped fences, cut stone.
  - Seamless patterns come from a small coordinate hash.
- 2026-11-08 — **Details come from the map baker**, not hand-placed tiles: a roof block's top row gets a ridge and its bottom row eaves, and walls get a window (with a flower box) every third cell, which doors replace. The map data didn't change, apart from fences and the well now giving their ground height.
- 2026-11-08 — **Trees, rocks, fences and the well are props over solid ground.** The Height layer gets a new "solid ground" tile at the block's height (grass that can't be entered), and the picture goes on the Decor layer. Before, those tiles carried lowland grass, which showed as dark squares on raised ground. Their shading height is now their ground height: the art draws its own shadow. The well is one 2x2 picture cut into quarters.
- 2026-11-08 — **A Decor layer** (TileMapLayer "Decor", just above Height, added by the baker) holds props and decorations: flowers in three colours, grass tufts, pebbles, mushrooms, a vegetable patch, lily pads.
  - Each map can place decor blocks and scatter decorations over open ground with a seed. The scatter is deterministic: re-baking gives identical scenes.
  - The scatter never touches paths, solids, doors, exits, people, items, entry points or the spawn.
  - Movement only reads the Height layer, so the Decor layer can't change the way; a test checks the rules.
- 2026-11-08 — **Cliffs read as cliffs:** below a drop, HeightShading draws an earthy face (4 px per level, up to 12) with a dark lip, strata lines, a crack and a soft shadow at its foot. Below solid things (houses, walls) it draws just a soft shadow.

## H6 — Puzzles
- 2026-11-08 — **Puzzle pieces are Interactables children over pure `PuzzleRules`.** The area pushes blocks and presses plates every physics frame; switches and cracked walls take hits through HurtBoxes like enemies do.
- 2026-11-08 — **Pushing: hold straight against a block for 0.35 s** and it slides one cell; a tap doesn't move it. It moves only onto open floor at its own level (no stairs, ledges, solids or anything standing there).
  - **Never onto its room's border:** the wall ring, where doorways are. A block can't jam a doorway, and the Cistern's push room keeps its gap away from the doorway so pushing straight on can't park the block in front of the way out.
  - Blocks go back to their start on the next visit (not saved), the classic reset if a player gets stuck. What a puzzle opened stays open, because plates, switches and walls are flags.
- 2026-11-08 — **Plates set a flag while the hero or a block stands on them.** A latching plate stays pressed for good. A non-latching plate also counts the hero, which is why a block is needed when the plate and the door are far apart.
- 2026-11-08 — **A `Hit` now carries its kind** (sword, arrow, bomb, contact; HitBox `kind`).
  - Crystal switches react to sword, arrow and bomb hits, set or toggle their flag, and ignore further hits for 0.4 s (one swing, one change). They show red when off and blue when on.
  - Cracked walls are a `DungeonDoor` kind, `cracked`, opened only by a bomb, through a HurtBox the door makes for itself.
- 2026-11-08 — **Shutters can wait on several flags** (`open_flags`, any of them; `needs_all` for all), so the Cistern's treasure room has two solutions: a block held on its plate, or an arrow into a crystal on a raised platform. The platform has no stairs, and the crystal is three cells in, beyond the sword's 20 px reach; arrows fly over heights.
- 2026-11-08 — **The H6 puzzle rooms are the Cistern**, down a stairway in the Ruin Cellar's inner room. It has five 15x11 rooms on a 2x3 grid: push block, then latching plate, then crystal switch, then cracked wall, then the combined room (30 coins in a chest); the sixth room is solid rock. Gating it behind the cellar keeps a natural order (keys, then puzzles), and H7's keep is still the real dungeon.
- 2026-11-08 — Push blocks are carved sandstone with a diamond mark, so they never pass for the grey pillars around them. The first screenshot made that confusion plain.

## H7 — The first dungeon & boss
- 2026-11-08 — **The Old Keep is ten 15x11 rooms on a 3x4 grid** (the top middle and top right are solid rock), in the H5/H6 style. The order is forced:
  1. guard room (small key 1, from a cleared room)
  2. the hall door
  3. the two-plate room
  4. the armoury (the Bow, and a crystal on a ledge to try it on)
  5. the gallery (archers on a walkway, small key 2)
  6. the east door and the twin crystals
  7. the big key room
  8. the Warden

  The old store behind the entrance's cracked wall (50 coins) is optional.
- 2026-11-08 — **Until H8, the road to the keep is a gap in the woods at the top of the village's north rise.** H8 puts the countryside in between by retargeting the village's `KeepRoad` exit and the keep's two exits.
- 2026-11-08 — **The boss is the Iron Warden**, an enemy with a new behaviour, `warden` (data in `data/enemies/iron_warden.json`, timings in a `boss` object):
  - It guards, then gazes. Only an arrow during the gaze stuns it (its `weak_point`), and only stunned does it take damage. That makes the bow necessary and the sword still useful.
  - It has 12 health and stays stunned for 3 s, with a 0.4 s flinch between blows, so one stun is worth about five sword hits: two or three stuns in all (eased after the first playtest, below).
  - At half health it stomps faster, guards for less long, and fires three bolts.
  - Brains now get the hit's kind (`take_hit(..., kind)`); other enemies ignore it.
- 2026-11-08 — **Bosses don't trap or strand the hero.** The boss door doesn't shut behind them.
  - The Warden keeps to its room and starts over whenever the hero leaves it, the classic reset.
  - If the hero has no arrows when its eye opens, five fall into the room's far corner, so the fight can't strand anyone.
  - Beaten, it stays beaten: the Enemy's new `stays_beaten` with its saved `clear_flag`.
- 2026-11-08 — **A heart container is a `HeartContainer` node**, not an item. It appears when its flag is set, is taken by touch, and calls `GameState.add_heart_container()`. Its taken flag keeps it gone. The way out is a shutter on a stairway behind the boss, on the same flag.
- 2026-11-08 — **Shutters can `stays_open`:** once their flags are met, they latch open for good (a door flag set by `latch()`, which the area calls whenever flags change).
  - This lets puzzles use plates that don't latch. In the two-plate room the hero stands on one plate and a block holds the other, and once solved it stays solved.
  - Crystal shutters latch too, for consistency.
- 2026-11-08 — **Blocks go back to their start when the hero leaves their room** (H6's known issue): one jammed in a corner is back in place on the return. Safe now that solved shutters stay open.
- 2026-11-08 — **What an enemy drops falls off a ledge** to the first lower open cell below it (up to four cells), so archers shot off the gallery leave their drops where the hero can walk. Goblin archers can now drop three arrows (weight 2 of 6), which keeps the bow fed in the keep.
- 2026-11-08 — **The Bow moved from the South Field ruin into the keep's armoury**, with a chest of 15 arrows beside it, as H4 planned. The shop still sells arrows. The Cistern's arrow solution now needs the keep first; its block solution doesn't.
- 2026-11-08 — **The Warden was too hard in the first playtest, so it was eased on every front:**

  | | Before | After |
  |---|---|---|
  | Touch | a heart | half a heart |
  | Bolts | a heart, at 110 px/s | half a heart, at 90 px/s |
  | Speed | 22 | 18 |
  | Rage | half health, x1.5 | half health, x1.3 |
  | Eye open | 1.6 s | 2.2 s |
  | Stun | 2.2 s | 3 s |
  | Guard (before each gaze) | 3 s | 2.5 s (more chances) |
  | Health | 16 | 12 |
  | Flinch | 0.5 s | 0.4 s |

  `tools/playtest.gd -- warden` starts at its door with the sword, the bow and 20 arrows, for retrying it.
- 2026-11-08 — Raised ledges in dungeons reuse the dirt-path tile at height 1, as the Cistern did. A proper raised-flagstone tile can come with the art later.

## H8 — The countryside
- 2026-11-08 — **The road north is two areas**, each 40x30, both outdoor greybox like the South Field:
  - **The North Fields:** a stream with a bridge, a farm plot, a plateau with an archer.
  - **The Old Wood:** dense trees cut by a winding road and clearings, ending at the keep's stone front with its gate.

  They replace H7's stand-in road from the village straight into the keep: the village's `NorthRoad` now leads to the fields, and the keep's gate and its way out both lead to the wood.
- 2026-11-08 — **Two secrets, both optional and both seen before they're reached** (curiosity pays, no blind searching):
  - **Hidden meadow:** a one-tree-wide gap in the fields' thicket beside the road leads to a meadow with a chest of five bombs. That's enough for the second secret even without visiting the shop.
  - **Old shrine:** the wood's shrine shows its heart piece through the open-air ruin. One stretch of its wall is cracked: bomb it.
- 2026-11-08 — **Heart pieces are GameState state, not items:**
  - `heart_pieces` (0–3), saved as an additive key, so the save version stays 1.
  - `add_heart_piece()` turns every fourth piece into a heart container, and `EventBus.heart_piece_found` announces each one.
  - The slice has one piece; finding it says "1 of 4". There's no HUD counter yet, only the message.
- 2026-11-08 — **Doors and chests outside dungeons keep their flags under the area's id** (`flag_scope()`): `dungeon/old_wood/door/shrine_wall`. The flag prefix is a little off for a field, but it reuses DungeonState unchanged.
  - A cracked wall gains a `stone` colour so it matches the light ruin stone outdoors.
- 2026-11-08 — **Every dungeon door must stand on walkable ground** (`doors_test`). The shrine's first bake left solid stone under its cracked wall, so it opened onto nothing. The secret's test found it, and the new check keeps it from happening again.
- 2026-11-08 — The welcome sign now points north to the road to the keep and south to the South Field. A new sign in the fields points the way.

## H9 — Save, menus & playtest
- 2026-11-08 — **One save slot for the slice.** Save from the pause menu; Continue on the title loads it and puts you on the saved cell, even mid-dungeon. Classic Zelda restarts at a dungeon's entrance, but resuming where you stood is simpler and kinder to a playtest.
  - `SaveSystem.current_slot` lets tests save elsewhere.
  - Quitting to the title loses unsaved progress, and the pause menu says so. There's no autosave.
- 2026-11-08 — **Pause really pauses:** the pause menu sets `get_tree().paused`, and the menus run with `PROCESS_MODE_ALWAYS`. Earlier menus (dialogue, items) only stop the hero, and still do. Pausing can't happen while the hero is busy (talking, item menu, travelling, down).
- 2026-11-08 — **Play time is GameState state** (`play_time`, saved as an additive key; the version stays 1). It counts in the area's `_process`, so it stops behind the pause menu, and announces nothing because it changes every frame. It's what we'll read to check the 30–60 minute goal.
- 2026-11-08 — **Settings are a new `Settings` autoload over a pure `SettingsData`, kept in `user://settings.cfg`.** They belong to the machine, not the save, so GameState doesn't own them.
  - The settings: fullscreen, window size (2x, 3x or 4x), and showing the controls hint.
  - No volume until there's audio, and no key rebinding in the slice.
  - Applying is skipped headless.
- 2026-11-08 — **Menus share a pure `MenuCursor` and `MenuInput`.** Movement keys move the cursor, E / Enter / A picks, and Esc / Start / Tab backs out. Options that can't be chosen show in brackets and are skipped. The test for the settings menu found that a multi-step move went only one step; fixed.
- 2026-11-08 — **The slice ends with a closing conversation from data** (`ending_keep`), opened when the Warden's heart container is taken (`HeartContainer.dialogue_id`). It replaces the pickup message, points to the play time, and hints at secrets. The game goes on afterwards.
- 2026-11-08 — **Fixes for new players:**
  - Closed doors seal their cells (`TerrainQuery.set_sealed`), so arrows and bats stop at them (H7's known issue).
  - Elder Bram now points to the training yard's sword and the road north.
  - The welcome sign names the road to the keep.
  - The controls hint mentions Esc.
- 2026-11-08 — **H9's last criterion needs a person:** a new player finishing in 30–60 minutes without help. The build, the clock and the ending are ready for it. The ROADMAP marked H9 built but not done until that playtest. It went well (2026-11-08), so H9 is done.

## Phase 2
- 2026-11-08 — **Phase 2 approved: from slice to small game** (ROADMAP H10–H16), aiming at about two hours of play. The order is feel and sound, then grass, pots and heart pieces, quests, a new region with pits, the second dungeon around a new item, pixel art for everyone, and story with an ending.
  - Sound first, because the game is silent and sound improves everything after it.
  - Art last, because it's costly and easiest to get right once content stops changing.
  - Still no external assets: sound, music and art are made in code.

## H10 — Feel & sound
- 2026-11-08 — **Sound is made in code and baked to WAVs**, like the tile art: a pure `Synth` plus `tools/audio/make_audio.gd`, written to `audio/sfx` and `audio/music`.
  - Baking keeps start-up instant; synthesising seconds of music in GDScript at load would take seconds.
  - The four songs come to about 3 MB of WAV in the repository. Fine for now; compress or shorten later if it grows.
- 2026-11-08 — **The songs are short original loops** (13–23 s):
  - village: warm, F major
  - countryside: brisk, G major, with drums
  - dungeon: sparse, A minor
  - boss: driving, E minor

  The jingles (item, solved, secret) are plain arpeggios of their own, kept clear of any famous tune.
- 2026-11-08 — **Sounds are asked for with `EventBus.sound(id)`** at the node where the action happens, and an `Audio` autoload plays them. That keeps systems talking through signals, and lets tests listen for every sound without audio. Music is asked for the same way (`music_requested`). Each area names its tune, and a boss swaps in its own while awake.
- 2026-11-08 — **Headless, `Audio` plays nothing but still records** what it would play. A tune still playing at quit raced the dummy mixer and leaked at exit; nobody hears headless audio anyway.
- 2026-11-08 — **Hit-stop uses `Engine.time_scale`**, ended on real time by the area, and always reset when an area leaves the tree, so tests and scene changes can't be left in slow motion. Shake is the camera's offset. Particles are small drawn `Burst` nodes, keeping to placeholder art.
- 2026-11-08 — **Volumes are settings, not save data:** music and sound, 0–10, default 7. Zero mutes the bus. The settings menu lists them first.
- 2026-11-08 — **Phase 2 re-planned at the user's request:** more detail in the world we have instead of a bigger map, a new hero sprite with a blue suit, and better graphics, sooner. The new order:
  - H11 hero and graphics (was H15)
  - H12 a more detailed world (replaces the new region, and takes in grass, pots and heart pieces)
  - H13 quests
  - H14 the second dungeon, entered from the existing world, with pits
  - H15 story

  The new region moves to "later".

## H11 — Hero & graphics
- 2026-11-08 — **The hero wears blue** (user's request): a blue hood and tunic with a gold-trimmed hem, a brown belt with a gold buckle, cream trousers and brown boots.
  - More shading, two eyes, a hair fringe, and an arm that swings in side view.
  - The leftover "Network Key" glow from the water design is gone.
  - Same 3x3 sheet of 16x24 frames, so nothing else changed.
- 2026-11-08 — **One art tool for every other actor:** `tools/art/make_sprites.gd` holds ASCII art with a small palette per sprite (sharing `.` and `o`) and paints a strip per sprite into `gameplay/art/`. The art is written and width-checked in a generator first, but lives in the tool afterwards.
  - Each strip carries a white silhouette row, so hit flashes stay a simple frame swap (no shader).
  - Nodes draw frames with `SpriteSheet`. A test pins the frame names to the tool's order.
- 2026-11-08 — **Villagers are one sprite in marker colours**, recoloured per villager at run time (cached). New villagers stay a matter of picking colours in the scene.
- 2026-11-08 — **What "no placeholder shapes" means here:** every body, item and piece is a sprite. Shadows, glows, sparks, poofs, the sword's swing arc, flying arrows and bolts stay drawn in code as effects. Rectangle-built pieces already sit on the pixel grid (chests, doors, plates, blocks, signs) and look the part, so they stay.
- 2026-11-08 — **Tiles:**
  - A raised flagstone `ledge` kind replaces the dirt-path ledges in dungeons, with cut-stone cliff faces under it (`HeightShading.stone_faces`, set for dungeons).
  - Water is one animated tile of four frames in its own atlas row. The old still water tile stays in the atlas, unused.
  - Dungeon walls and floors were already detailed and stay as they are.
- 2026-11-08 — **The screenshot tool waits by the clock for the Warden's gaze.** A fast screen draws far more than 60 frames a second, so frame counts lie.

## H12 — A more detailed world
- 2026-11-09 — **Grass, pots and critters are placed by spawn markers.** The map baker paints a hidden `Spawns` tile layer, and the area turns markers into nodes on load. Placement stays in `build_maps.gd` with the rest of each layout, and no tool attaches scripts to scenes (a `-s` tool compiles before the autoloads exist, so it can't load scripts that use them).
- 2026-11-09 — **Breakables are a new kind of data** (`data/breakables/`), validated like enemies. The enemy drop-table check is now shared (`_check_drops`).
  - Grass and pots break on the sword and bombs, not arrows (an arrow just stops).
  - Grass drops a heart or a coin now and then. Pots drop more often: hearts, coins, arrows or bombs.
  - Pots in the keep give arrows and bombs before the Warden.
- 2026-11-09 — **No lifting or throwing pots**: the sword breaks them. It's the simplest version, and it keeps the hero's moves unchanged (GDD §5).
- 2026-11-09 — **Critters are pure decoration with honest movement.** Chickens use a GridBody by the terrain rules, so they never walk through a fence. Butterflies and fireflies fly over anything. None blocks the hero, fights or is saved. Fireflies glow all day: there's no night yet.
- 2026-11-09 — **The heart pieces:**
  1. the village: a nook carved into the woods by the field, behind a tuft of grass
  2. the North Fields: the plateau's far corner, ringed by grass
  3. the Cistern: a secret room behind a new cracked wall in the push room (the sixth room was solid rock)
  4. the Old Wood's shrine

  Each is visible before it's reachable. Farmer Oda, Pip, Guard Rolf and Shepherd Edda each hint at one, or at how pieces add up.
- 2026-11-09 — **New props and furniture are drawn as ASCII art in the tile tool** (`PROP_ART`, painted by `_ascii`), the way the sprites are. The market stall is a 3x2 prop like the 2x2 well. The washing line and the bucket are decorations you can walk past or under.
- 2026-11-09 — The HUD shows heart pieces as a gold heart after the hearts, filling a quarter at a time. It's hidden at zero.

## H13 — Quests
- 2026-11-09 — **Quest progress is all in GameState, in what was already saved.** The stage is in `quests`; two flags per quest (`quest/<id>/entered`, `quest/<id>/complete`) record whether a stage's `on_enter` effects were applied and whether the quest is finished.
  - `QuestRunner` keeps nothing of its own, so it needs no sync after a load, and a reward can't be paid twice.
  - No save-format change: the version stays 1.
- 2026-11-09 — **Quests advance on change, not on a timer.** A new `Quests` autoload runs the runner whenever EventBus reports a flag, an item or a stage change, and when an area loads. Changes the runner makes come straight back as signals; the update already running picks them up.
- 2026-11-09 — **One new condition type, `quest_status`** (`not_started`, `active`, `complete`), so a giver's conversation can offer a quest once without knowing flag names. No new effect types: quests start with the existing `set_quest_stage`, and `complete_quest` is now applied (by the runner, in a stage's `on_enter`).
- 2026-11-09 — **DataRegistry rejects a quest that can never finish** (no stage's `on_enter` has `complete_quest`). With quests written as data only, the check has to catch what a script's author would have noticed.
- 2026-11-09 — **Three small quests, three shapes**, to prove the format: a fetch (The Lost Shuttle), a delivery with a report back (Eggs for Tilda), and a bounty (Slimes in the South Field, on the slimes' shared `clear_flag`).
  - Rewards are things the game already has: 30 coins; 5 bombs; 40 coins and 10 arrows.
  - The roadmap's "bigger quiver or heart piece" rewards wait. A quiver needs carrying-capacity upgrades, and the shop's stock rules are written against today's limits. A fifth heart piece would leave a heart that can never be completed.
  - An item or deed done before asking still counts: the quest moves straight on when taken, and the giver's reply offers to settle it on the spot.
- 2026-11-09 — **Items can name their picture** (`icon` in item data). The shuttle has its own; without one an item's type decides, so new quest items need no code.
- 2026-11-09 — **Quest news is a notice at the top of the screen**, not the message line, which the dialogue box covers: quests mostly start and finish mid-conversation.
- 2026-11-09 — **The quest log lists started quests only**, active first and then finished, each group by title. Unstarted quests stay hidden. With three quests it needs no scrolling; a longer list will.

## Art pass 2 — hero, houses and the land
- 2026-11-09 — **An art pass between H13 and H14, at the user's request**: better graphics, a better-looking hero
  with better animation, more medieval houses. It adds no mechanics, areas or content, and everything is still
  painted in code.
- 2026-11-09 — **The hero keeps the blue hood and tunic and gains a red scarf.** The scarf is my choice, not the
  user's: a warm accent on a blue figure, and its tail shows movement in the side view. It's two palette entries
  in `make_player_sprite.gd`, easy to recolour or remove.
- 2026-11-09 — **Holding up an item is for show only.** The hero raises it for about a second but can move or
  swing at once, which ends the pose. Freezing the hero would need a new motor state and would get in the way
  when picking things up mid-fight.
- 2026-11-09 — **A fallen pose replaces the red tint at zero hearts.** The hurt tint stays.
- 2026-11-09 — **Houses keep their footprints, doors and solidity.** What was three roof rows over one wall row is
  now two roof rows, a half-timbered upper floor and the ground floor. Roofs tell the houses apart: thatch on the
  cottages, clay tiles on the shop (still "the red house"), slate on Elder Bram's (still "the blue-roofed house").
- 2026-11-09 — **Soft edges are drawn, not tiled.** `HeightShading` reads the Height layer at load and draws grass
  over path edges and a bank round water. The alternative, a transition tile for every combination of
  neighbours, would mean dozens of new tiles and a baker that picks among them; this way hand-painted maps get
  the edges too.
- 2026-11-09 — **The baker picks each tree.** Maps still say only "tree". A tree hemmed in by trees (or the map's
  edge) on all four sides becomes closed canopy; the rest are a round tree, a pine or an oak by a hash of the
  cell, so the same map always bakes the same wood.
- 2026-11-09 — **Smoke is an animated tile on the Decor layer**, like water on the Height layer: no node, no
  script.

## H14 — The second dungeon & boss
- 2026-11-09 — **The dungeon's item is the Lantern, not the boomerang** (the roadmap left the choice to this
  milestone). The bow already hits things at range, so a boomerang's puzzles would mostly repeat the keep's, and
  its stun would have touched every enemy brain. Darkness and torches are new and self-contained.
- 2026-11-09 — **The Lantern is carried, not put on the item button.** E lights a torch while it's in the pack.
  The first plan put it on the button, but that meant swapping between it and the bow in the item menu, most of
  all in the boss fight. Nothing about it needs a button: no fuel, no aiming.
- 2026-11-09 — **The second dungeon is the Chapel Crypt**, under the chapel already on Hearthvale's north rise, so
  the world above grows by nothing. Its door is barred (a shutter on the `keep_warden_beaten` flag) until the
  keep is done, which keeps the dungeons in order without a new key item. Guard Rolf explains, before and after.
- 2026-11-09 — **A pit is a drop, not a new kind of move.** `TerrainQuery` reports stepping into an open pit as a
  DROP: the hero already may drop and enemies already may not, so enemies keep out with no new rule, and fliers
  and arrows were never bound by drops. The area does the falling: half a heart, back on the last safe cell.
- 2026-11-09 — **A block that fills a pit can stay for good.** Given a `block_id`, the pit cell goes into a
  dungeon flag, so a bridge built once is there on every later visit and nobody is stranded on the far side.
  Both of the crypt's trenches cut their room in two right across, so any cell a block sinks into bridges it:
  there's no wrong place to push it.
- 2026-11-09 — **Keys can't be spent in the wrong order.** Before the Lantern there is one small key and one
  locked door in reach. The second key is behind a torch door, and so is the second locked door.
- 2026-11-09 — **Light stays in its room.** Only torches in the room on screen count, so a lit room never glows
  through the wall into a dark one. Lights don't add up either: the brightest counts, which keeps the rule simple
  enough to test and to draw in a shader.
- 2026-11-09 — **The dark is drawn by a small shader written in code**, the first in the project: a sheet of
  black with stepped holes. Drawing it in rectangles would have cost thousands of draw calls a frame. The rule
  it draws lives in `LightRules`, pure and tested; the shader only repeats it.
- 2026-11-09 — **The Crypt Shade is beaten with light, then the sword.** All four braziers burning bind it for
  three seconds; then it puts them out. Its touch does no harm while bound. 16 health against the Iron Sword's 3
  and a flinch of 0.6 s means two bindings at best, three or four more likely.
- 2026-11-09 — **Bosses share `ArenaBoss`** (the arena, starting over when the hero leaves, the fight's tune,
  bolts). `Boss` stays the Iron Warden's class so the keep's scene and tests are untouched.
- 2026-11-09 — **The Iron Sword is in the crypt, before its boss**, not a reward for beating it: a sword won from
  the last boss would never be swung. It's behind the three brief torches, the crypt's one optional room.
- 2026-11-09 — **The game's closing words moved to the crypt.** The keep's now point on to the chapel door. The
  real ending is H15's.
- 2026-11-09 — **No lantern fuel, fire arrows or burning things**: one new item, used two ways (seeing and
  lighting), is enough for one dungeon.

## H15 — Story, ending & playtest
- 2026-11-10 — **The story is one idea: the Warden was a lock.** Sir Aldric bound a Shade under the chapel and set
  the Iron Warden to bar the crypt when it stirred. Beating the Warden opens the way to what it guarded. It ties
  the two dungeons together with what the game already had (the lights over the keep, the bars on the chapel door,
  the Iron Sword in a knight's tomb), and adds no new place, character on screen or mechanic.
- 2026-11-10 — **It's told in about a dozen lines**: Elder Bram before and after the keep, Guard Rolf, five
  inscriptions and the two dungeons' closing words. Three of the inscriptions double as hints (the block and the
  pit, the three brief torches, how the Shade is beaten), so the story is where a stuck player will look.
- 2026-11-10 — **No new effect type for the ending.** The last conversation sets the flag `game_finished`; the
  area leaves for the ending screen when that conversation closes. Because it's a saved flag, the ending plays
  once, and a save remembers the game was finished.
- 2026-11-10 — **The ending screen lets you keep exploring**, back on the cell you stood on, or save and go to the
  title. It doesn't save by itself: the game never saves unasked anywhere else.
- 2026-11-10 — **The ending sums up time, hearts and quests**, the three things the game already counts. It doesn't
  count heart pieces found: pieces merge into hearts, so the number isn't kept.
- 2026-11-10 — **The playtest isn't mine to run.** It needs people who haven't seen the game. This milestone
  ships a guide for it and stops there; nothing is "fixed" ahead of anyone hitting it, beyond the three hints.
- 2026-11-10 — **The title's picture follows the save.** The keep's window is dark once the save in the menu's
  slot says the game was finished. It reads the save, not the running game: the title is what you see before
  anything is loaded.
- 2026-11-10 — **An inscription is a look of `Signpost`** (`stone`), not a new kind of thing: the same behaviour
  with a different drawing and prompt. It's drawn in code, as the signpost is.
- 2026-11-10 — **Playtest scenarios save into a slot of their own** (900), emptied at each start. Before, saving
  in a scenario (the pause menu, or "Save and go to the title" at the ending) replaced the player's own game.
  The title shown after a scenario reads that slot too, so nothing of the player's is loaded or written.
- 2026-11-11 — **The new-player playtest runs through the playtest tool** (`-- full`): the whole game from the
  title, on a slot of its own that is kept between runs, with a log of areas, first items, flags, quests and
  falls. It listens to `EventBus` and reads `GameState` from outside, so the game itself has no playtest code.
  Nothing announces a conversation, so who was talked to isn't logged.
- 2026-11-11 — **A hint goes where the player is stuck.** Playtest run 1 stopped at the Reliquary's locked door
  with no idea where its key was. The fix is a stone beside that door saying where the key is and how to reach
  it, in plain words ("the first hall", not "the Narthex", a name the game never shows). The crypt's layout and
  key order stay as they are: the way was there, only nothing pointed to it.
- 2026-11-11 — **Enter answers a conversation, Space doesn't.** Playtest run 3 ended at the game's last words:
  the player pressed Enter, which picks in every menu, and only E answered a conversation. Now Enter does too
  (`MenuInput.is_answer`). Space also picks in menus but is the attack key, so it is left out: swinging as words
  open would skip them.

## Art pass 3 — a warmer, softer look
- 2026-11-10 — **Hearthvale's look stays its own.** The user asked for graphics "very similar to Stardew Valley".
  The pass doesn't copy that game's tiles, characters, palette or interface. It takes the general craft of cosy
  village pixel art: saturated colour, warm lights and cool shadows, outlines in the colour of the thing.
- 2026-11-10 — **One colour pass in the tools, not a repaint.** `PixelGrade` runs on every picture as it's baked.
  That changes the whole game at once, keeps the ASCII art and the palettes as they are, and puts the look in one
  place to tune. A repaint of specific art (bigger trees, the menus) is a later step, each its own piece of work.
- 2026-11-10 — **Outlines are found by colour.** Every tool paints outlines in one near-black, so the pass treats
  any solid pixel of that colour as outline. Eyes were painted in the same colour and came out soft, so they now
  have a dark violet of their own.
- 2026-11-10 — **An outline is never darker than a floor**, and the inside of a dark mass stays dark. Without the
  floor, the outline of a dark thing (a bomb, a pit's rim) came out as black as before.
- 2026-11-10 — **The pass changes pixels only**: no map, tile layout, sprite size or frame changed, so no area was
  re-baked.
- 2026-11-11 — **Art pass 4 is light and lettering, not a repaint.** The review screenshots showed the tiles and
  sprites in good shape and three things letting them down: flat light, the engine's smooth font over pixel art,
  and still air. Those change the whole game at once and touch no map, tile or sprite.
- 2026-11-11 — **The gloom is for show.** Houses and dungeons are dimmed by a second, soft `Darkness`, and the
  hero always stands in light. The rules that play depends on (`lights()`, `brightness_at()`, the crypt's dark)
  are untouched, and a dungeon is never dimmed by more than half, so enemies stay easy to see.
- 2026-11-11 — **What kind of place an area is comes from its tiles**, not a new property on eleven scenes: a
  `dungeon_id` means a dungeon, inner walls mean a house, anything else is outdoors.
- 2026-11-11 — **The font is painted in code**, like the rest of the art: 95 glyphs as ASCII in
  `tools/art/make_font.gd`, baked into a `FontFile` resource. It is set through a project theme, so no label names
  it. Whole-number scaling only, so a pixel is always a square; label sizes of 10 became 8, and 36 became 32.
- 2026-11-11 — **The keep and the cistern get no wall torches in this pass.** They would need new decor tiles
  and a re-bake of their maps. Their rooms are lit around the hero only.
- 2026-11-11 — **The hero pass reads a 3D brief as a sprite's.** The request spoke of a model, a rig, skin weights
  and IK; the hero is a 16x24 sprite. Clothing became a repaint of the ASCII art, and animation became new frames.
  Jumping, dodging and climbing were left out: the hero has none of them and the pass adds no mechanics.
- 2026-11-11 — **The hero keeps his blue hood and red scarf** (the user's earlier requests), and gains the rest
  over them: vest, wrist guards, pouch, tall boots, sword on his back, pack. His trousers went from cream to
  pale slate, a working colour that stands apart from the gold hem and the brown boots.
- 2026-11-11 — **New frames are made from the drawn ones, in the tool.** Breathing, the wind-up and the flinch
  are a drawn frame with the upper body a pixel lower; the run frames are the walk frames leaning a pixel. They
  can't drift from the drawn art, and a change of clothes reaches them for free. Frames that need new drawing
  (a drawn-back sword arm, running from the front) are listed in the plan as not done.
- 2026-11-12 — **The pivot.** The user changed the game's direction: a story-driven RPG with survival and
  farming, a modern pixel-art look, cherry blossom trees. Water-era rules aside, this supersedes "no stamina",
  free sprint and "A Link to the Past style". The plan and its reasons are in `docs/progress/pivot-plan.md`; the
  user approved all nine recommendations as written:
  1. **640x360 on the same 16-pixel grid**, with taller sprites. The resolution alone adds view, not detail; the
     look comes from tall art, light, wind and water. No gameplay number moves.
  2. **Indoors and in dungeons the camera shows the room at twice the size**, since rooms are small.
  3. **The hero wears his hood down**, keeping the blue tunic and red scarf.
  4. **The hero's home** is the doorless thatched cottage in Hearthvale, with a new one-room interior.
  5. **About eight new cherry trees block cells** in Hearthvale, listed before baking; North Fields swaps
     existing trees.
  6. **A day is 14 real minutes.**
  7. **The clock stands still in dungeons.**
  8. **Saving** is by sleeping and from the pause menu.
  9. **Phase 1 is six steps**, each with a review stop.
- 2026-11-12 — **P1a: the kind of place sets the camera's size.** `Ambience` already reads outdoors, house or
  dungeon from the tiles, so the 2x indoor camera needed no property on any scene.
- 2026-11-12 — **P1a: screens are anchored, not moved.** Shifting every box by the difference between the two
  screen sizes would have fixed today and broken at the next size. Each box is now tied to the middle or an edge.
- 2026-11-12 — **P1a: the energy bar exists but is hidden.** The HUD's corner is laid out for hearts and energy
  now, as the step asks; the bar shows nothing true until P2's rules feed it, so it stays hidden until then.
- 2026-11-12 — **P1a: the HUD's contents are unchanged.** At twice the size the HUD's corner and the controls
  hint cover the top corners of a dungeon room (they are see-through). Slimming the HUD is left to 1f and P2,
  when it gains the energy bar, the clock and the day.
- 2026-11-12 — **P1b: pools mix, glows add.** A test in a window showed what the engine's two blends do under
  a dark ambient colour: "mix" at full strength gives a thing's own colour back exactly, and two that overlap
  stay at that; "add" piles up and glares. So light that shows things is a mix, and only the bloom is an add.
- 2026-11-12 — **P1b: the crypt's dark is drawn by the rule's lights and nothing else.** A crystal or a far
  torch with a light of its own would give itself away in the dark, which the old sheet of dark prevented by
  lying over everything. So a dark area gets one pool per rule light, and a glow only when it lies wholly
  inside a light's fully lit core.
- 2026-11-12 — **P1b: a light's first step starts at its edge.** The old sheet rounded brightness to the nearest
  of four steps, so the outer twentieth of each light was drawn dark although the rule calls it lit. The new
  picture rounds up, so drawn and rule agree on where light ends; lights look a shade wider than before.
- 2026-11-12 — **P1b: no normal maps and no hard shadows yet.** The plan was to try normal maps on dungeon walls
  and tree trunks, and that belongs with their repaint (1c, 1d), since the pictures change there. Real-time
  shadows from walls were not tried.
- 2026-11-12 — **P1c: the user approved all eight new cherry tree cells** from a marked map of Hearthvale:
  (16,4), (31,4), (34,25), (27,31), (21,10), (26,10), (26,22), (21,27). They are the only collision changes in
  P1 so far; the village's reachable cells went from 1222 to 1214.
- 2026-11-12 — **P1c: trees are stood up at load, not re-baked.** `Scenery` takes the tree tiles off the Decor
  layer and puts tall pictures in their cells. No map but Hearthvale and the North Fields was re-baked, and a
  tree's cell is solid from the Height layer exactly as before.
- 2026-11-12 — **P1c: a crown fades for what matters, not for everything.** The first version faded for
  anything standing behind a tree, and tall grass behind a tree left it see-through for good. Now only the hero,
  enemies and things that can be picked up count.
- 2026-11-12 — **P1c: reflections are mirror pictures, not a copy of the screen.** A water shader that reads the
  screen would have to be drawn after everything it mirrors, and would then also draw over the heads of people
  standing in front of the water. Mirror sprites masked to the water cells have no such problem; they mirror
  the hero and the trees, not villagers or enemies.
- 2026-11-12 — **P1c: the ground tiles were not repainted.** They change through the softer palette and the
  outline rule only. The closed canopy inside thick woods is still a flat tile. No normal maps: tried none.
- 2026-11-14 — **P4d: what friendship opens is in the villager's conversation, not their data file.** The
  plan had the villager's file say it. But quests have always been offered in conversations, step 4a's
  `openings` already let one begin elsewhere on a condition, and this way a favour is words and answers like
  any other. The villager's file stays who they are and what they like.
- 2026-11-14 — **P4d: the present comes before the favour.** At four marks the present's opening is tried
  first, since it is given once and done; a favour that is put off is asked at every talk, and would stand in
  the present's way for good.
- 2026-11-14 — **P4d: a favour put off leads to the villager's usual talk** ("Not just now."), so the story's
  own answers (Elder Bram's) are never out of reach behind it.
- 2026-11-14 — **P4d: berry jam gives 30 energy, not the plan's 20.** Three wild berries eaten raw give 24,
  and since 3c a dish is worth more than its makings (a test holds every recipe to it). The number is data.
- 2026-11-14 — **P4d: the condition takes the rules of friendship.** Points are saved; how many make a mark
  is a rule. An evaluator built from a bare snapshot meets no friendship condition, so a mistake shows as an
  answer missing, never as one that should not be there. — Alternative: the condition in points, which would
  put a rule's number into every conversation.
- 2026-11-14 — **P4d: a recipe known is a flag** (`recipe/<id>`), so teaching needed no change to a save.
  The effect `teach_recipe` is its own type, so the load check can refuse a recipe that isn't there or one
  that needs no teaching.
- 2026-11-14 — **P4d: the effect that adds friendship was not built.** The plan lists it among P4's new
  effects, but none of the plan's quests or presents gives friendship. `GameState.add_friendship()` is there
  when content wants it.
- 2026-11-14 — **P4d: more of Sir Aldric's tale is two lines:** he was a farmer of the valley, and the hero's
  cottage was his. The plan asked for "more of the tale" and no more; this ties the story's two halves, the
  keep and the plot. It is new lore, and the user may want other words.
- 2026-11-14 — **P4d: Pip's secret is where a bomb opens the Old Wood's shrine,** which holds a piece of heart.
  The wall was there to find since H13; this is a second way to learn of it.
- 2026-11-14 — **P4d: the ending's three lines follow the old three.** Six lines in one column fit above the
  menu. A friend is three marks or more: the number is in the friendship rules.
- 2026-11-14 — **P4d: the whole-story test stands in for the bosses with their flags.** The fights are tested
  where they are (the keep's and the crypt's suites); played again here they would make one test of two
  minutes that fails for reasons not its own.
- 2026-11-13 — **P4c: a villager is known by their conversation.** Their data names it, and the area looks a
  `Villager` up by the conversation it has. No scene was touched and no node got a new property. Two villagers
  may not share one, which the load check refuses.
- 2026-11-13 — **P4c: the answer that gives is added to a copy of the conversation** as it opens, at the node
  it begins at, before its last answer. The plan asked for no conversation file to change, and the data in the
  registry is never changed either. It is not offered where the conversation goes on to.
- 2026-11-13 — **P4c: the answer shows only when it would do something:** a gift can still be given that day
  and he carries one. An answer that led to "you have nothing to give" would be a line of noise in every
  conversation of the game.
- 2026-11-13 — **P4c: food and ingredients can be given.** The plan says "food and crops"; crops are food
  already, and Wenna likes cherry blossoms, which are an ingredient. The types are data.
- 2026-11-13 — **P4c: the gift list is a list of its own, in the shape of Tilda's.** Her list is two tabs, a
  purse and a deal that stays open; a gift is one choice and done. They share the frame, the cursor and the
  scrolling, not the script.
- 2026-11-13 — **P4c: a gift at a full friendship is still taken.** The villager thanks him and nothing more
  is gained. Refusing it would need words of its own for a case few will meet.
- 2026-11-13 — **P4c: what a villager says to a gift is in their data,** two lines each: one for a gift they
  like and one for any other. The words tell the player which it was; the Friends page does not list likes.
- 2026-11-13 — **P4c: the Friends page shows all seven from the start,** unmet ones with no marks. It tells a
  new player who there is to meet. — Alternative: only those he has spoken to.
- 2026-11-13 — **P4c: marks are blossoms drawn in code,** as the hearts are, pink in bloom and dark in bud.
  Hearts are life in this game, so friendship has a picture of its own.
- 2026-11-13 — **P4c: the condition "so many marks" and the effect "add friendship" wait for 4d.** The plan
  lists them among P4's new conditions and effects; only the side quests and recipes would use them, and their
  shape is better chosen with that content in hand.
- 2026-11-13 — **P4b: a dish is anything a recipe makes, and the cook's level counts when it is eaten.** A
  dish does not remember who made it, so Tilda's bread, which is the bread the hearth bakes, is richer for a
  good cook too. — Alternative: marking each dish as his own, which would need items that differ one from
  another; the inventory has only counts.
- 2026-11-13 — **P4b: cooking is counted by an effect, `practise`.** Cooking is the hearth's conversation
  giving and taking items, so the points come the same way. Any conversation or quest can use it.
- 2026-11-13 — **P4b: which costs a skill eases is data** (`eases`), like the points and the levels. `Skills`
  knows nothing of swords or hoes.
- 2026-11-13 — **P4b: the hoe is paid before the cell is tilled.** The stroke that raises farming costs the
  old price, and the next one the new. Otherwise the very stroke that earns the level would be cheaper for it.
- 2026-11-13 — **P4b: a rise is a notice at the top of the screen,** where a quest's news goes, with a chime
  of its own. The line at the bottom is taken by "Picked: Turnip." and the like, and by the hearth's words.
- 2026-11-13 — **P4b: points are given where the deed is done in the game's state** (`till_soil`, `harvest`),
  so nothing that tills or picks can forget them. A monster's are given by the area that hears it fall.
- 2026-11-13 — **P4b: every monster beaten counts,** by the sword, an arrow or a bomb, by day or at night, and
  monsters come back when an area is entered again. Combat can be raised by going back to the slimes. That is
  "improves with use"; whether it is too easy is for a playtest, and the numbers are data.
- 2026-11-13 — **P4b: the pause menu's line is levels only.** No points and no bar toward the next level: the
  plan keeps a skills screen out of P4.
- 2026-11-13 — **P4: the proposal was approved as written** (the user: "Approve as written"). All ten
  decisions in `docs/progress/P4-plan.md` §3 stand as recommended: three skills of five levels that only make
  work cheaper and meals better; the keep's gate chained until Bram's word; his word as soon as a first seed is
  planted; the crypt's bars up at dawn the day after the Warden; friendship in five marks of four points;
  gifts from a list; side quests and recipes at two marks and a present at four; old saves past the gates;
  four steps.
- 2026-11-13 — **P4a: the keep's gate is a door, not a rule about the exit.** The chapel's bars were already
  a `DungeonDoor` standing in front of an exit, so the gate is one too, of a new kind (`chained`) with its own
  words. Nothing about exits changed. — Alternative: a flag on `AreaExit`, as the shop's hours are; it would
  have needed its own drawing and its own words.
- 2026-11-13 — **P4a: the gate's chain is drawn in code, like every door.** Locks, bars and cracked walls are
  drawn by `DungeonDoor`; a baked picture for one gate would have been the odd one out.
- 2026-11-13 — **P4a: a flag's day is kept for every flag that comes true,** not only the Warden's. It is one
  rule with no list to keep up, and the condition `days_since` can then wait on anything. A save grows by a
  number a flag. Flags that hold counts or words have no day.
- 2026-11-13 — **P4a: the crypt opens through the quest.** The main quest's `rest` stage waits a dawn and its
  next stage sets `crypt_open`, which the bars and Guard Rolf read. The quest always exists (it starts by
  itself), so the story's timing is in one data file. — Alternative: bars that count days themselves.
- 2026-11-13 — **P4a: the main quest starts by itself** (`auto_start`), at the first update of a game, and
  announces itself like any quest. `Quests` does nothing with no game started, so it does not begin on the
  title screen.
- 2026-11-13 — **P4a: the main quest catches up.** Each stage moves on by a flag that later progress also
  sets, so a hero who is further along (an old save, a playtest scenario) runs through the earlier stages at
  once. A seed planted before all three things are taken from the cottage also moves it on.
- 2026-11-13 — **P4a: Bram's welcome is an opening, not a new conversation.** A dialogue may list `openings`:
  nodes to begin at when their conditions are met. His welcome is for a hero with no first crop and no Warden
  beaten, so nothing later in the story can fall back into it.
- 2026-11-13 — **P4a: the journal tells a new player how to farm.** "Choose the hoe with Tab and left click to
  till a patch" is in the second stage's words. There is no tutorial and no pop-up: the plan says the quest
  log is the help.
- 2026-11-13 — **P4a: an old save is given no promise.** The migration opens the gate and counts a first crop
  as planted, but does not set `promised_elder_keep`: Bram and Wenna would speak of a promise the player never
  made.
- 2026-11-13 — **P4a: version 4 holds places for skills and friendship now,** empty, so the format changes once
  for the phase as the plan says. `friends` is `points`, `talked` (the day) and `gift` (the day) a villager;
  `skills` is points a skill. If 4b or 4c need another shape, that is a version 5.
- 2026-11-13 — **P4a: the main quest counts among the quests on the ending screen** ("Quests finished 4 of
  4"). It is a quest like the others; the ending's lines are redone in 4d.
- 2026-11-13 — **P3c: the shop is a list on the HUD, opened by her conversation.** The pivot plan said her
  one-line-per-ware conversation "won't stretch to seeds and crops". Her conversation keeps what is hers to
  say (the eggs she is owed) and two answers open the list, on buying or on selling. A new effect, `shop`,
  does it, so any conversation can open any shop.
- 2026-11-13 — **P3c: seeds and crop prices are the crops' own, not the shop's.** The shop's file says only
  that it sells seeds and buys crops. A sixth crop is then on both lists with no change to the shop.
- 2026-11-13 — **P3c: she buys only what crops give.** Not what is foraged, not meals, not anything else. The
  GDD says "it buys crops". It keeps the farm the one way to earn at her counter.
- 2026-11-13 — **P3c: her old wares keep their prices and sizes:** ten arrows 5 coins, three bombs 8, bread 6.
  A deal is all or nothing: all ten arrows must fit.
- 2026-11-13 — **P3c: crops are sold one at a time,** and the list stays open. A line for "sell all" was not
  asked for; eighteen turnips are eighteen clicks.
- 2026-11-13 — **P3c: a full purse refuses a sale** (999 coins) and keeps the crop, as a full pack keeps a
  crop in the soil.
- 2026-11-13 — **P3c: the meals are data only.** Four dishes and five recipes; bread can now be baked from
  two wheat as well as bought. The numbers are the pivot plan's table.
- 2026-11-13 — **P3c: a conversation shows four answers and scrolls.** The hearth's six dishes ran out of its
  box, as the item menu's lines did in 3b. The scrolling is shared now (`MenuCursor.window_top()`), and the
  hearth stays a conversation: it needed no screen of its own.
- 2026-11-13 — **The scenery is still but for the water** (the user's request: "get rid of the animations on
  the environment except the water animation"). Gone: the wind in tufts, flowers, crops and washing
  (`SwayLayer`) and in tree crowns, petals in the air, specks in the air (`Motes`). Kept as still pictures:
  the mist (it no longer drifts), chimney smoke (the first of its four frames), fallen petals. Still moving:
  the water's tile, its surface and its reflections.
  - **Left as they were, as my reading of "environment":** the flicker of fires, lamps and torches (light),
    creatures (chickens, butterflies, fireflies), people breathing and blinking, pickups that bob, and the
    title screen's stars and petals. Each is one line to still if the user wants it.
- 2026-11-13 — **Left click uses what is in hand, right click interacts** (the user, after trying the first
  version: "attacking should be left click and using hoe and other items should be left click and similar to
  the controls in stardew valley and right click should be to interact with other characters and items").
  This replaces the entry below, which had interact on the left button.
  - **One button, two things to use.** Hearthvale has a sword button and an item button; farming games have
    one "use" button for whatever is held. The left click is a new action (`use_hand`) that picks between the
    two: the item if it is a weapon, or a tool with work in front of it; otherwise the sword.
  - **A tool gives way to the sword where it has no work.** With the hoe in hand off the plot, a left click
    swings the sword. The other reading (the hoe says "not here") would leave him unarmed in a field until he
    opened a menu. On the plot a tool with nothing to do still says why, and he doesn't hack at his crops.
  - **The sword is a line in the item menu** when something else could be in hand, so the bow can be put
    away with the mouse alone. Choosing it empties the item button.
  - **A left click answers a conversation, and a right click doesn't** (the user, after trying it: "when
    speaking to another character selecting the text should be left click not right click"). My first version
    had it the other way round, to keep a swing from skipping words that open in the middle of a fight (a
    boss's last). That is kept another way: the box takes no left click as an answer for its first 0.3
    seconds. Enter and a pad's A answer as before.
  - **Space and Q are kept.** The sword and the item are still one press away whatever is in hand, which the
    dungeons were built round. The gamepad is unchanged.
  - **Not done, and not asked:** a row of tools along the bottom of the screen with number keys or the wheel
    to pick from, which is how those games switch tools. Tools are still chosen in the item menu (Tab).
  - **The pointer still doesn't matter:** he works the cell he faces, not the one under the pointer.
- 2026-11-13 — *(Replaced the same day, above.)* **Interact is the left mouse button** (the user's request:
  "move is the same but interact is mouse"). The simplest reading: the interact action moved from E to the
  mouse, as a button. E no longer interacts.
- 2026-11-13 — **No screen takes the mouse for itself.** Input is read in `_unhandled_input`, which a Control
  under the pointer cuts off, so every screen sets all its Controls to ignore the mouse as it starts. The
  game has no clickable parts, so nothing is lost.
- 2026-11-13 — **P3b: a ripe crop waits.** It needs no more water and never withers, however long it stands.
  The docs say when a crop withers but not whether a finished one can; losing a ripe pumpkin to a missed day
  would punish the wrong thing.
- 2026-11-13 — **P3b: what a crop gives is a `food` item, not an item type of its own.** It is eaten and
  cooked with by what already exists. The pivot plan listed "crop" among the new types; the crop's file says
  everything else about it (days, seed, prices), so the item needed no type.
- 2026-11-13 — **P3b: what each crop gives raw** (the plan says "about a third of their cooked value"):
  turnip 7 (roast turnip is 22), carrot 7 and potato 8 (a third of the stew's 60 between three), wheat 5
  (bread is 30 from two), pumpkin 22 (most of a pie's 80). They are in the items' data.
- 2026-11-13 — **P3b: a first pouch of five turnip seeds lies at home** with the tools (the user's yes,
  2026-11-13), so the first crop needs no coins and no shop.
- 2026-11-13 — **P3b: picking is E, facing the crop,** as tools work the cell he faces. E on a growing crop
  does nothing; on a withered one it clears it. The hoe leaves a planted cell alone, so a crop can't be dug
  up by a slip.
- 2026-11-13 — **P3b: crops are drawn flat, a cell high, and never block.** A crop he could walk behind would
  need sorting against him and would hide what he does at the plot's edge; one that blocked would make the
  middle row of a full plot unreachable.
- 2026-11-13 — **P3b: planting costs no energy.** The plan's table gives costs for hoeing and watering and
  says harvesting is free; it doesn't mention planting.
- 2026-11-13 — **P3b: the phases every crop shares.** Just planted, a sprout and withered look the same for
  every crop; each has two pictures of its own (growing, ripe). A crop is a sprout for the first half of its
  days and growing for the second.
- 2026-11-13 — **P3b: the item menu scrolls.** With tools, five seeds and a harvest the list ran out of its
  box. It shows five lines and says where the cursor is in the list. Nothing else about the menu changed.
- 2026-11-13 — **P3a: the plot is one house east of where the plan put it.** Straight across the road from
  the hero's door (cells 6..11) the shop's roof stands over the third row and hides half of it, and a crop
  there would be half hidden too. At cells 12..17 all eighteen cells show, and the well is at its edge.
- 2026-11-13 — **P3a: the plot is drawn over the map, not baked into it.** A `FarmPlot` node draws the soil
  and takes the three flowers off its cells as the area loads. The Height layer is untouched, so where the
  hero can walk is the same by construction, and the plot can be moved by moving one node.
- 2026-11-13 — **P3a: the farm is kept in the plot's own cells,** not the map's: a save made today still
  fits if the plot is moved.
- 2026-11-13 — **P3a: the can's water is an item, carried like arrows.** The item menu, the HUD's item line
  and "out of..." already speak of ammo, so the can needed no display of its own and no new field in the save.
  The "Carrying" line leaves it out: it is in the can.
- 2026-11-13 — **P3a: the tools lie in the hero's home, by the door,** as pickups (GDD §4 says "Home"). An old
  save finds them there. The can starts empty, which sends him to the well once.
- 2026-11-13 — **P3a: tilled soil stays tilled for good.** Nothing grows over it and no day undoes it. Only
  the water is gone by morning.
- 2026-11-13 — **P3a: no new hero frames for the tools.** He uses his swing pose, and the tool's picture
  dips over the cell it works. Tools in his hands would be twelve more frames a tool.
- 2026-11-13 — **P3a: a tool with nothing to do costs nothing** and says why. The words about the soil come
  before the words about the can: "till it first" is more use than "the can is empty".
- 2026-11-13 — **P3a: the save stays version 3 through P3.** A cell's crop joins it in 3b as a field with a
  default.
- 2026-11-13 — **P2e: a monster is a night monster if the area loads at night.** Changing one in the middle
  of a fight (its health, its speed) would be felt as a cheat, so nightfall changes nobody already there; it
  takes leaving and coming back. The other way too: one met at 05:00 is still tough at 07:00.
- 2026-11-13 — **P2e: the night's numbers where the pivot plan gave none:** sight 1.3 times, coin drops twice
  as likely (the plan said "see further" and "more often"). Both are in `data/rules/night.json`.
- 2026-11-13 — **P2e: night monsters are drawn unshaded, in a pale violet.** A tint alone was lost in the
  dark: they were harder to see than by day, as well as tougher. Unshaded they stand out of the night, which
  also tells him which kind they are.
- 2026-11-13 — **P2e: a shut door is solid.** The first version let him step into the doorway and told him
  there. Now the cell is blocked, and he is told as he walks up to it facing it, or tries it. The shop can
  always be left: only the door from the village keeps hours, and Tilda serves whoever is inside.
- 2026-11-13 — **P2e: villagers who go home are simply gone.** Nobody walks home and nobody can be found
  there: the houses that have insides have their own people. A quest that needs one of them waits for morning.
- 2026-11-13 — **P2e: the window light is a pane drawn over the glass, not a real light.** Sixteen real lights
  would cost draw calls for a glow nobody stands in. The lamps light the ground; the windows only shine.
- 2026-11-13 — **P2e: indoors keeps its own tune at night,** as it keeps its own light.
- 2026-11-12 — **P2d: only the recipes whose makings exist are in the game yet.** Cherry blossom tea is the one
  recipe. Soup, stew, pie, roast turnip and bread from wheat need crops; they are files to add in P3, with no
  code. Adding them now would list dishes nobody can cook.
- 2026-11-12 — **P2d: the hearth's list is a conversation built from the recipes.** The dialogue box and the
  shared `take_item` and `give_item` effects already do everything a cooking list needs, the way Tilda's shop
  does. No new screen.
- 2026-11-12 — **P2d: things to gather are pickups that grow back, not solid bushes.** The hero stands on one
  and presses E, as for any item. Nothing about where he can walk changes, and no map is re-laid.
- 2026-11-12 — **P2d: a full hero isn't hungry.** Food that would do nothing isn't used up.
- 2026-11-12 — **P2d: bread costs 6 coins.** The pivot plan gives bread's energy (30) but no price. It is a
  starting value, in Tilda's conversation.
- 2026-11-12 — **P2d: how much there is to gather is a starting value too:** ten spots, giving six berries,
  four mushrooms and six blossoms a day (about a hundred energy in all, for someone who walks to every one).
- 2026-11-12 — **P2d: blossom lies in front of its tree, never beside the trunk.** A crown fades for anything
  that can be picked up behind it; a spot beside a trunk kept its tree faded for good. A test now checks.
- 2026-11-12 — **P2c: sprint costs energy only for frames in which he ran.** Holding the key against a wall or
  standing still costs nothing: the cost is for the running, not for the key.
- 2026-11-12 — **P2c: collapse is checked every frame, not only when energy changes.** A hero who reaches zero
  while down, in a pit or mid-conversation would otherwise never collapse, and be stuck slow for good.
- 2026-11-12 — **P2c: he lies where he fell for a moment before waking at home,** and can't be hurt while he
  does. Going straight to black felt like a crash.
- 2026-11-12 — **P2c: staying up until 02:00 costs what collapsing costs,** as the pivot plan says ("as at zero
  energy"): half a bar and a tenth of his coins. Sleeping in bed is how you avoid it.
- 2026-11-12 — **P2c: "30% slower" is the sword's cooldown, 1.3 times as long.** The swing itself is as long
  as it was and hits when it did; he is slower to be ready for the next.
- 2026-11-12 — **P2c: a full bar comes from the rules, not from a constant.** `GameState.ENERGY_MAX` of 2a is
  gone; `max_energy()` reads `data/rules/energy.json`.
- 2026-11-12 — **P2c: nothing gives energy back but sleep, until there is food (2d).** For one step the bar
  only goes down during a day.
- 2026-11-12 — **P2b: sleeping is an effect a conversation can have.** The bed asks in words from data, and its
  first answer carries `sleep`, as a shop's answer carries `give_item`. No new menu and no new kind of
  interactable beyond a bed that says "Go to bed".
- 2026-11-12 — **P2b: every morning at home is saved, however he got there.** Sleeping saves (decision 8), and
  so does waking after the day ran out, so the save never holds a day that has already ended.
- 2026-11-12 — **P2b: he can sleep at any hour.** The pivot plan sets no bedtime, and a player who wants the
  next morning shouldn't have to wait for it.
- 2026-11-12 — **P2b: the bed is against the west wall.** A two-cell hero standing south of a bed hides it. From
  beside it, both show.
- 2026-11-12 — **P2b: a new game still starts in the village square.** Waking in bed on the first morning would
  be a new opening; nobody asked for one.
- 2026-11-12 — **P2b: words to say on arrival are kept in `GameState` but not saved.** "You stayed up too
  late" has to cross a change of scene and be said once. It is not game state: a save loaded later has no
  reason to say it.
- 2026-11-12 — **P2 is built in five steps, each with a review stop:** the clock and the day, home and sleep,
  energy, food and cooking, hours and night. P1 was six for the same reason: the phase is too big to judge in
  one piece. (My reading of the user's rule to stop for review after each step; they can ask for bigger steps.)
- 2026-11-12 — **P2a: save version 2 holds the day, the minute and the energy at once.** Energy isn't spent
  until 2c, but it is in the save now so P2 changes the format once, as the pivot plan says.
- 2026-11-12 — **P2a: time is counted from the midnight the day began on.** 02:00 at a day's end is 1560, not
  120, so a day's times only go up and "is it later than" is one comparison.
- 2026-11-12 — **P2a: until he has a home, the hero ends the day where he stands.** At 02:00 a new day begins on
  the spot, with no penalty. Step 2b moves the waking to his bed; 2c adds what collapsing costs.
- 2026-11-12 — **P2a: the night is dim, not dark, and the hero carries no light outdoors.** The crypt is the
  place where the dark is a rule. Outdoors at night every enemy stays easy to see, and only lamps make pools.
- 2026-11-12 — **P2a: a lamp's pool at night is warm and weaker than indoors.** At full strength it showed the
  grass under it in noon colours, like a floodlight.
- 2026-11-12 — **P2a: the HUD's clock moves in steps of ten minutes.** A minute of the day is 0.7 seconds, too
  fast to read as a ticking number.
- 2026-11-12 — **P2a: screenshots are taken at noon** unless a shot names an hour, so the 88 older shots can
  still be compared with earlier steps. A new game starts at dawn, in peach light.
- 2026-11-12 — **P1f: the heading face has capitals only.** Forty-three glyphs drawn by hand; a small letter is
  given its capital's picture, so any words can be set in it and no heading can come out with a missing letter.
  Small letters of its own would be another fifty glyphs for six headings.
- 2026-11-12 — **P1f: the heading face is drawn, not made from the small one.** Doubling the small face gives
  the same letters with thicker strokes. A face with thick stems, thin bars and serifs reads as a heading.
- 2026-11-12 — **P1f: the title's picture is baked; only what moves is drawn.** One 640x360 PNG painted by a
  tool, with the stars, the keep's window and the petals drawn over it. The old backdrop drew hills as polygons
  every frame. Its trees are the game's own, from the scenery atlas, so the title can't drift from the game.
- 2026-11-12 — **P1f: the HUD's corner says only what there is to say.** No "Carrying: nothing", no "Item:
  none", and the box is as wide as its words. In a dungeon room at twice the size it now covers far less of the
  room's corner. P2 adds an energy bar and a clock there, which is why it was slimmed first.
- 2026-11-12 — **P1e: the hero is put together from parts.** A head, a body pose and a pair of legs per facing,
  joined by the tool. Thirty-nine frames drawn whole would drift apart; this way one head serves every frame and
  the second half of the walk is the first on the other foot.
- 2026-11-12 — **P1e: a walk cycle still covers 28 pixels.** Six frames at 28/6 pixels a step, in place of four
  at 7, so the legs turn over as fast as they did and only look smoother. The run likewise (36 pixels).
- 2026-11-12 — **P1e: the sword is drawn from his belt, and hits from his feet as before.** `Sword.HAND` moved up
  five pixels with the taller body. It is used only in drawing; the arc that hits is the HitBox's, unchanged.
- 2026-11-12 — **P1e: villagers were redrawn, not stretched.** Stretching the old 16x24 robe left a small head on
  a long body beside the hero. They have his proportions now (a ten-pixel head), in their marker colours.
- 2026-11-12 — **P1e: idle frames are made by the tool, not drawn.** A breath is the drawn frame sunk a pixel
  above the chest, a blink the same frame with the eyes closed, so they can't drift from the picture they come
  from. `Idling` (pure) keeps each villager's time. A blink never falls mid-breath, since it is drawn with the
  shoulders up.
- 2026-11-12 — **P1e: animals got the cheapest idle.** Chickens already walk and peck and butterflies flap; a
  chicken standing still now blinks (a made frame). No new animal drawings. Enemies and bosses were not redrawn:
  they took the palette and outline rule in 1c.
- 2026-11-12 — **P1d: buildings get height the way trees did, over the map and not in it.** Wall faces, tall
  pillars and roof ridges are drawn at load over a Height layer that doesn't change, so no cell's blocking can
  change and no map file is touched.
- 2026-11-12 — **P1d: a face never rises into the next room.** A dungeon's north wall has the next room's south
  wall behind it, and that room is on screen alone. The first version let the face rise eight pixels into it,
  and it showed as a strip of brick at the foot of the room above.
- 2026-11-12 — **P1d: the walls are one picture.** Drawn cell by cell the relief took the keep from 383 draw
  calls to 1020. Put together once into a picture the size of the map it is one draw, and switching it on and
  off in one run shows no cost in the keep and 0.4 ms in a house.
- 2026-11-12 — **P1d: light on walls is painted, not normal-mapped.** A wall is now a lit face and a dark top,
  which is the shading normal maps would have given, and it stays in whole pixels. No normal maps were built;
  the pivot plan's promise to try them is dropped.
- 2026-11-12 — **Frame times on this machine can't be compared across runs.** The same build read 1.75 ms and
  3.77 ms in the same house in two runs minutes apart. Draw calls are steady, and an effect can be timed by
  switching it on and off in turn within one run.
- 2026-11-11 — **Animation never changes play.** The wind-up and the settle are pictures chosen by how far
  through the swing the motor is. The blade is live from the first frame and the swing is as long as it was.
- 2026-11-15 — **Bug hunt: a full pack refuses, it never takes part.** A pickup, a forage spot and a chest stay
  as they are unless all of what they hold fits (`GameState.has_room_for()`), as a ripe crop, a dish and a
  shop's ware already did. Taking what fits and losing the rest would lose things for good; taking part and
  keeping the rest would need a count saved for every pickup.
- 2026-11-15 — **Bug hunt: a weapon with nothing left gives the left click back to the sword.** The user asked
  for attacking on the left click; with the last bomb gone it only said "Out of bombs." and the menu would not
  put the sword back. Emptying the item button when a stack runs out was the other way: it would have changed
  what Q says and hidden that the bow is still his.
- 2026-11-15 — **Bug hunt: a saved cell that is solid now is passed over for the area's start.** Maps are
  re-baked often, and a save names a cell. Only solid cells are refused: a cell that someone stands on by day
  can still be walked out of.
- 2026-11-15 — **Bug hunt: what was found and not fixed is listed, not changed.** Notices that replace each
  other, rewards cut to what fits and a gift to a full friendship are how the plans left them; changing them is
  the user's call, not a bug fix.
- 2026-11-15 — **Bug hunt: news is stacked, not queued.** Two pieces of news at once show together, a line
  each. A queue would show them one after the other and keep the second back for three and a half seconds,
  by when the moment it belongs to is over; and tests, in which no time passes, would never see it.
- 2026-11-15 — **The mouse: a pointer in menus, two buttons in play.** The user asked for the mouse to select
  in menus, which changes their rule of 2026-11-13 for menus only. In play the hero still works the cell he
  faces: pointing at the world would be a different game, and was not asked for.
- 2026-11-15 — **A click on no line still chooses the highlighted one.** The keys and a click anywhere worked
  together before the pointer, and a conversation is read on with a click anywhere. Only a click on a line
  that can't be chosen, or between Tilda's two tabs, does nothing: it was aimed.
- 2026-11-15 — **The bar is a view of the item button, not a second inventory.** The lit slot is
  `GameState.equipped` (empty for the sword), so the save format, the left click's rules and Q are as they
  were. Slots are in pickup order and can't be rearranged: the user asked for a bar to choose from, not one to
  arrange.
- 2026-11-15 — **The last bomb or seed empties the item button.** A bar can't light a slot that isn't there.
  This replaces the bug hunt's choice to leave "Bombs x0" on the button: Q now says nothing is on it. A bow
  with no arrows stays, since the bow is still carried.
- 2026-11-15 — **Only the first thing for the item button jumps into his hand.** With a bar the sword is
  often in hand by choice, and buying bombs must not swap it out. With nothing else for the button (a new
  game's hoe, bombs after the last ran out) it still does.
- 2026-11-15 — **No numbers are drawn on the slots.** The font's smallest size is eight pixels, a third of a
  slot. The keys box says "1-9", and the slots count from the left.

- 2026-11-16 — **A key held against the way he comes out of a door is not obeyed until it is let go**
  (`ArrivalHold`). The keep's way out is taken going north and sets him down a step south of the keep's
  gate, so the held key walked him straight back in. Chosen over moving the entry point (a map change, and
  any later door that turns him round would have the same fault) and over ignoring every held key on
  arrival (walking on through a door with the key down is how every other door feels, and stays).
- 2026-11-16 — **A save is written beside the old one, read back, and moved into place; the old one is
  copied to a backup first.** Copying keeps the save in its place the whole time: moving it aside instead
  would leave a moment with no save at all. Reading the new file back is what catches a disk that filled up.
- 2026-11-16 — **One backup, the save before the last.** The user asked for the previous save to be kept, not
  a history, and one file is enough to survive a save that goes wrong. Whatever was in the save's place
  becomes the backup, readable or not: the game does not judge it.
- 2026-11-16 — **If the backup can't be made, the save still goes ahead.** The new save has been read back
  whole by then, and a player who can't save at all loses more than one who saves without a backup. The old
  save is then only ever replaced by a move, never removed first.
- 2026-11-16 — **Leaving saves, and a save that fails keeps the game open once.** Thrown out unsaved, the
  player loses the session without being asked; held for ever, he can't leave a game on a full disk. So he is
  told, and the second time it leaves.
- 2026-11-16 — **"Saving..." stays up for half a second.** The save takes no time to speak of; words that are
  gone in a frame are not a notice. It counts real time, so it works behind the pause menu.
- 2026-11-16 — **`SaveSystem` takes the window's close request and asks only the scene the game is showing.**
  One place decides, and an area that a test or the screenshot tool has put in the tree beside its own scene
  can never be saved over the player's game by a window closed by hand. The title has nothing to save.
- 2026-11-16 — **The ending screen saves on a closing window too.** The Shade's fall is not saved until then:
  closing the window on "The End" would have cost the last fight. Its own "Save and go to the title" is as it
  was.
- 2026-11-16 — **A hero lying fallen is saved awake at the entrance.** A save with no hearts loads a hero who
  walks about dead. He was a second from waking there anyway.
- 2026-11-16 — **A save that can't be read is found out when Continue is chosen, and the backup is offered,
  never loaded unasked.** It is his game: he is told what happened and what the earlier save holds (where,
  and how long played) before anything is loaded. Continue is no longer greyed out for a broken save, which
  looked like no save at all.
- 2026-11-16 — **What doesn't fit is laid down by the `give_item` effect, not by quests alone.** A quest's
  reward is that effect, and so are a present and a thing handed over in a conversation (Oda's basket of
  eggs): the loss was the same, and one place fixes all of it. Cooking already checks for room.
- 2026-11-16 — **What lies at his feet is kept in the flags.** `owed/<item>` and `left/<area>/<x>,<y>/<item>`
  hold counts, as the forage spots and the pushed blocks already keep theirs. No new field, so no new save
  version, and an older build loads such a save.
- 2026-11-16 — **It is picked up whole, like everything else on the ground,** and what he has no room for is
  passed over by the right click when someone or something is before him. Without that, a reward laid at his
  feet stood between him and the villager who gave it.
- 2026-11-16 — **A gift to a full friendship has a third line of thanks, `thanks.full`, and every villager
  must have one.** "From dialogue data" was read as the villager's own file, where their words of thanks
  already are. The gift was always taken at five marks (a test said "a gift is still a gift"); what was
  missing was any sign that it changed nothing. Seven short lines are the only new words.
- 2026-11-17 — **Willowmere and the Bogwisp: the plan's ten decisions,** approved by the user as written
  (`docs/progress/willowmere-plan.md`): still mist and the game's own fireflies; dawn can't be seen, so the
  rule is built and the rising at dusk is what shows; the Lantern gates the fight and the favour; a fifth
  heart piece; lit lanterns count as light; no inside for the hut; two cells of Hearthvale opened; Marsh Stew
  known and Ember Tea taught; a present at four marks; one stop after step 1.
- 2026-11-17 — **The marsh has its own ground, and its props stand on it.** A map may name its
  `prop_ground`; without that every willow, stone and lantern post would stand on a square of meadow grass.
  The scatter of decorations covers the marsh's ground as it does grass.
- 2026-11-17 — **The planks across Hearthvale's east meadow are a decoration, not a tile of the Height
  layer.** The meadow is a level above the road, and a boardwalk tile is at ground level: laid as a picture
  over the meadow's own ground, the planks need no tile for every height.
- 2026-11-17 — **The way east is at rows 17 and 18,** not half-way down as the plan said: the meadow's own
  trees stand at rows 22 and 23, and their crowns would have hidden planks laid at 20 and 21.
- 2026-11-17 — **Only the marsh's fireflies wait for dusk.** The request was fireflies at dusk in
  Willowmere; the Old Wood's are out at every hour and stay so (`Ambience.DUSK_FIREFLIES`).
- 2026-11-17 — **The hut moved two cells west of the plan's sketch.** A test that walks to every patch of
  land found the north boardwalk landing on the hut.
- 2026-11-17 — **After nightfall the marsh plays the night's tune,** like every place out of doors. Its
  own tune is for the day and the dusk; no rule was bent for it.
- 2026-11-17 — **A Bogwisp has health 4, not a count of blows.** The wooden sword deals 2 and the iron
  sword 3, so both take two blows, as asked, without a rule of its own. Bombs and arrows count as they do
  anywhere, where light reaches.
- 2026-11-17 — **Its dart is aimed as the flare begins, not as it ends.** The half second is then a real
  warning: a step aside is enough. Aimed at the end it would follow him.
- 2026-11-17 — **"Only by night" is a word in an enemy's data** (`"appears": "night"`), not a rule about
  Bogwisps. Such an enemy is not made tougher by the night's rules: its numbers are its night's.
- 2026-11-17 — **The light that gives a Bogwisp a body is the Lantern's own,** at the radius its item
  names, through `LightRules`. The dim glow the hero has without one (so he is never lost in the crypt) is
  left out, or the Lantern would not matter.
- 2026-11-17 — **Its touch hurts whether it has a body or not.** Otherwise the dark would be the safe
  place to stand.
- 2026-11-17 — **Its ember never falls in the water.** It is beaten over a pool as often as not; the drop
  lands on the nearest open cell, or where the hero stands.
- 2026-11-17 — **The mist thickens, it doesn't move.** More of it at night is a change like the light's;
  the rule against scenery moving stands.
- 2026-11-17 — **The flag that lights an area's lantern posts is named by the area** (`lanterns_flag` on
  its scene), not written into the code. Willowmere's is `marsh_lanterns_lit`; an area that names none has
  none to light.
- 2026-11-17 — **A lit post shows its burning picture by day,** as the village's lamp posts do, and gives
  light only from dusk. One picture, swapped once, and nothing to keep in step with the clock.
- 2026-11-17 — **A marsh lantern holds a wisp within 44 px, a little less than the Lantern's 56.** Six of
  them cover where the boards meet land and leave the middle of each walk dark: the favour makes the marsh
  safer, not safe.
- 2026-11-17 — **Henrik's favour is the fifth row in the favours' own test,** not a test of its own. The
  plan asked that he be befriended like the others; the same test running him is the proof.
- 2026-11-17 — **The "play" asked for was done by a script pressing real keys in a real window,** since
  there is nobody at the keyboard. It is written up as that, with what it skipped.
- 2026-11-17 — **Mining and crafting: sixteen decisions were approved with the plan**
  (`docs/progress/mining-crafting-plan.md`): the clock runs underground; Bogwisps are always out there;
  a fall in the mine ends in its hall; ladders up lead to the hall; rocks, branches and stumps come back
  daily, not on every visit; the sword cuts wood; bombs don't break rocks; a chest's slots are stacks;
  furnishings have fixed places; the Pickaxe and the sprinkler go on the bar; a second rug and a standing
  lamp; Mining gives a chance of extra ore; a wider Lantern; a `buys` list and a folder for crafting
  recipes; six cells of the North Fields change.
- 2026-11-17 — **He arrives on a floor clear of the HUD's corner.** The plan's sketches put the way in at
  the top-left cell, which the HUD covers at a dungeon's size. It moved a few cells east on seven floors,
  and two rocks that were under the corner moved with it. The counts are as planned.
- 2026-11-17 — **A broken rock leaves what it held lying in its cell,** as a breakable leaves its drop,
  and it is picked up by walking onto it. Straight into the pack would have needed a rule for a full pack
  that the game didn't have; a drop already had a place to lie.
- 2026-11-17 — **A drop he has no room for stays lying, and he is told once.** Before, what a monster
  dropped over a full stack was taken and lost. A full stack of stone would otherwise have stopped him
  breaking plain rocks, and so stopped him finding the ladder.
- 2026-11-17 — **The rock over the ladder gives no stone:** the ladder is what it gives.
- 2026-11-17 — **The lift is a conversation with a new effect, `travel`,** not a menu of its own: the
  dialogue box already lists answers, points with the mouse and closes on Tab.
- 2026-11-17 — **The pause menu is a line taller,** and shows two skills to a line. Four skills on one
  line are 43 letters, and its box holds 33.
- 2026-11-17 — **Cave walls show their face by the baker picking a second tile,** not by `WallRelief`:
  rough rock has no courses to line up, and one tile does it.
- 2026-11-17 — **A map can be a sketch.** Nine floors as lists of blocks would have been nine chances to
  miscount; the sketch in the plan is the sketch the baker reads.
- 2026-11-17 — **The version 4 save in the tests' fixtures was written by the game as it stood before
  the mine** (a checkout of the commit before, run once), not made up by hand.
- 2026-11-17 — **Phase 1 is one commit, not the three the plan listed.** The steps shared the same
  files (the area's script above all), and could not be told apart after the fact.
- 2026-11-17 — **Crafting recipes have a folder and a shape of their own** (`data/crafting/`; cooking
  keeps `data/recipes/`). Each names its `station` (the workbench or the furnace), its `order` on the
  list, what it `needs`, what it `makes` (an item, or a furnishing of the home) and, if it waits on
  anything, an `unlock`: an item `found`, or a `skill` at a `level`.
- 2026-11-17 — **What he has found is a list in the save, not a flag for each item.** The plan said
  flags (`found/<item>`); a set of ids says the same with one field, and keeps a hundred entries out of
  the flags. What he carries counts as found when a save loads, so an older save loses nothing.
- 2026-11-17 — **A furnishing is a flag and a node with a fixed place.** `home/<id>` says it has been
  made; a `Furnishing` in the cottage's scene says where it stands: the workbench (there from the start)
  at cell (9, 3), the furnace (6, 2), the chest (2, 2), the lamp (4, 2), the rug (2..3, 4). Nothing that
  stood in the cottage moved, and its map was not re-baked.
- 2026-11-17 — **The furnace's list is a conversation, built as the hearth's is,** with two new effects,
  `light_furnace` and `empty_furnace`. One load of up to five bars, three ore and a coal each, lit today
  and ready the next morning. The bars are given, not added: what a full pack can't take is laid at his
  feet.
- 2026-11-17 — **The workbench greys out what can't be made by showing two labels in the same place,**
  a bright one and a dim one; a line is on one and blank on the other. The pixel font has one colour to
  a label, and this needed no new kind of text. What the recipe under the cursor needs is shown beside
  what he has, a need to a line.
- 2026-11-17 — **The chest may hold several stacks of one thing,** which is its use: more ore, bars and
  crops than one stack. It holds 24 stacks, keeps what stacks, and leaves coins, keys and quest things
  with the hero. A line chosen moves that stack, as much of it as fits; there is no choosing how many.
- 2026-11-17 — **Wood lies at chosen cells, and comes back in the morning.** A fallen branch (one blow,
  1 wood) and an old stump (three blows, 2 wood) are breakables; a breakable's data may now say `hits`
  and `"returns": "daily"`, and a flag (`cut/<area>/<x>,<y>`) keeps the day. Ten branches and five
  stumps lie off the paths in the North Fields, the Old Wood and the South Field; those three maps were
  re-baked for their markers and nothing else in them changed.
- 2026-11-17 — **A better tool is an item of its own** (`copper_hoe`, `iron_hoe`, and so on), not a
  level kept beside the plain one: its stats say `reach` or `fewer_blows`, and the workbench takes the
  old tool to make it. The cell he faces decides whether a stroke is made; the cells beyond it in the
  line get it if they can; energy and the pour are paid once.
- 2026-11-17 — **A rock's blows are counted by the pickaxe that strikes it,** at each blow. Counting
  them once as the floor loads would have gone by whichever pickaxe was in hand at the ladder.
- 2026-11-17 — **The sprinkler is an item of type `sprinkler`, on the item bar** (approved with the
  plan). It is set on tilled, empty soil, lies flat, and is taken up with interact. Each morning, after
  the plot wakes, it waters the tilled cells among the four beside it: set down today, it runs from
  tomorrow.
- 2026-11-17 — **The Miner's Lantern is a second item of type `lantern`,** with radius 80, and making
  it uses up the Lantern. The hero's light is the widest lantern he carries, so nothing else changed.
- 2026-11-17 — **Crafting did not change the save's version.** `home` (the furnace's load, the chest's
  stacks), `found`, and a sprinkler in a cell of the plot are each read with a default, so a version 5
  save from before crafting loads as it is. A version 4 save starts with none of them.
- 2026-11-17 — **What tools hold is named once** (`Inventory.held_in_tools`): three watering cans hold
  the same water, and it is in the can, not in the pack, so the chest's list leaves it out.
- 2026-11-17 — **Two sounds were made for crafting, `craft` and `furnace`.** The plan's list of six had
  a "ladder" sound; the ladder uses the `secret` chime that was there already.
- 2026-11-17 — **Step 2b's commit was amended once,** before anything was pushed, to bring one test up
  to date with it. Nothing else in the history was rewritten.
- 2026-11-17 — **What a shop buys besides crops is a list of its own in the shop's data** (`buys`: an
  item and what is paid for one), not a price on the item. The price is the shop's to set, as a crop's
  is the crop's; a second shop could pay otherwise. Her list shows the harvest first, then `buys` in its
  own order. A thing is offered once: if a crop's harvest were also named in `buys`, the crop's price
  stands.
- 2026-11-17 — **Tilda's answer reads "I have things to sell."** It read "I have crops to sell.", which
  would have hidden the ore from a player who had only ore. Her greeting says she buys what he digs out
  of the quarry. Three older tests carried the old words.
- 2026-11-17 — **A favour at three marks stands after the lesson in a villager's `openings`.** Wenna and
  Shepherd Edda teach at two marks and ask at three. A hero who comes to three marks untaught (gifts on
  one day) is taught first and asked at the next talk; the present at four marks still comes before
  both.
- 2026-11-17 — **The eight days are played by a tool in the repository** (`tools/play_days.gd`), not a
  scratch script as Willowmere's was: phase 3's tuning will want it run again. It presses keys and mouse
  buttons through `Input.parse_input_event`, finds its way with the game's own rule for a step
  (`TerrainQuery.check_move`), reads what a player can see (rocks and what shows in them, monsters, a
  list's lines) and never what he can't (where the ladder is hidden). Where it changes the game's state
  it logs SETUP. Its save is slot 956.
- 2026-11-17 — **A trial run of that tool may go faster than life by taking more steps a second, each as
  long as ever** (`Engine.physics_ticks_per_second` with `Engine.time_scale`), so what happens in a step
  is what happens at life's speed. The game sets the time scale back to 1 after every hit's freeze, so
  the tool says its speed again each step. The report's run is at life's own speed.
- 2026-11-17 — **No price and no count was changed in phase 3.** The report proposes numbers; they are
  changed only on the user's word, in data, with the tests that carry them.
- 2026-11-17 — **Phase 3's numbers were settled by the user: all three of the report's proposals.**
  Tilda pays a third less for what the quarry gives (2, 3, 7 for the ores, 10 for a crystal, 8, 12, 25
  for the bars). A rock of ore or coal is 1 point of Mining and a plain rock none: `rock` was taken out
  of the skill's `gains`, since a deed there must be worth a whole point or more. Floors 4, 5 and 6 have
  2 coal rocks each. The Iron Pickaxe's gate and the furnace's five bars were raised in the report as
  the user's to call, were not asked for, and are unchanged.
- 2026-11-17 — **The Homestead: thirty decisions were approved with the plan, as written**
  (`docs/progress/homestead-plan.md`; the user: "Approve as written"). The plan's own list, with this
  entry, stands in for the `docs/HOMESTEAD-NOTES.md` the request names, which does not exist. By number:
  - **D1.** The way there is the lane's west end: two cells of Hearthvale's west tree line open (rows 16
    and 17) and the lane runs on to the edge. One re-bake of the village.
  - **D2.** The map is 40 by 30 cells.
  - **D3.** "About 4x the old plot" is the field: 12 by 6, 72 cells in one bed, with the old plot as its
    north-west corner. No tilling outside it.
  - **D4.** The field's 18 cells nearest the house are clear; the other 54 and about 90 places round the
    land carry debris, 145 in all. What is cleared is gone for good.
  - **D5.** The sword clears weeds, bushes, logs and stumps; the Pickaxe clears rocks; eight boulders
    want the Copper Pickaxe and three great boulders the Iron. Nothing on the field needs a better tool.
  - **D6.** A small pond in the south-west corner fills the can; there is no well until one is built.
  - **D7.** No monsters, villagers or forage on the homestead.
  - **D8.** The area `home` keeps its room and becomes the farmhouse's inside, cell for cell; only its
    doormat changes.
  - **D9.** The old cottage stands empty and locked: "The cottage stands empty, and its door is locked."
  - **D10.** A new game still begins in Hearthvale's square.
  - **D11.** The farm was Sir Aldric's. Seven lines of the quests and of Elder Bram change, and the
    title's line; nothing else in the story.
  - **D12 (bends the mouse rule).** Build mode is a screen, like a menu: B opens it, on the homestead
    only; the hero stands still and the clock stops; the mouse points at a cell; a left click sets down
    and a right click takes up; the wheel and 1 to 9 choose; Tab, Esc or B leave. In play the mouse is
    still no pointer.
  - **D13.** Only what is on screen can be built on.
  - **D14.** Two things to a cell at most: one lying and one standing.
  - **D15.** Never on trees, water or the house; the road and the path to the door; the way out; a
    doorstep; the field; debris or tall grass; the cell the hero or an animal is in.
  - **D16.** Taking up gives the item back if there is room; a grown tree gives back its sapling. Moving
    is taking up and setting down in one go.
  - **D17.** Fifteen placeables: nine made at the workbench, six bought from Tilda, who also sells fibre.
  - **D18.** A gate lets the hero through and keeps animals in; it is never opened or shut.
  - **D19.** The sprinkler stays on the item bar and on the field.
  - **D20.** One of each building.
  - **D21.** A plan is bought on a "Build" tab at the workbench, becomes a kit in the pack, is set down
    in build mode as a building site, and stands the next morning.
  - **D22.** The costs and footprints in the plan's table; an upgrade keeps the building's place and
    size.
  - **D23 (bends one furnace and one chest).** The Shed is a room with fixed places for two more chests
    and a second furnace, each made at the workbench. Each furnace still takes one load a night.
  - **D24.** Moving a building is free and at once. Demolishing gives back half of each material and no
    coins, and only an empty building can go.
  - **D25.** An animal is fed each morning by fenced pasture first, else by one hay from the silo, else
    it goes hungry.
  - **D26.** One right click pets an animal and takes what it has ready. No shears, no pail.
  - **D27.** Fed and petted, an animal gives at full pace; fed only, at half; unfed, nothing that
    morning. Nothing dies or runs off.
  - **D28.** Animals are indoors from 20:00 to 06:00 and simply are where they belong; they never use a
    door.
  - **D29.** Hay is tall grass from a meadow on the farm, back each morning. Farmer Oda sells animals
    from her conversation; an animal bought is in its building.
  - **D30.** Save version 6, once, for all five phases. The plot's size (6 by 3 to 12 by 6) and
    Farming's points (a point for a product taken) are the two existing numbers changed, with the
    user's word.
- 2026-11-17 — **What the Homestead's approval left as written:** the clock stops in build mode; no hay
  is for sale; the welcome sign in the square is not changed. `docs/HOMESTEAD.md`, an untracked copy of
  the request, was not spoken of and is left as it is. Whether to stop for a look after step 3a is not
  decided: the stops are after each phase, and the coordinator asks before phase 3.
- 2026-11-17 — **The Homestead is built by a coordinator and one subagent a phase** (the user's
  instruction). Each phase runs in a fresh context, commits and writes the log; the coordinator runs the
  full tests again, confirms the commit, and records what the user approves here, in the plan and, where
  a phase changes how something works, in CLAUDE.md. CLAUDE.md is the coordinator's to edit, not a
  phase's.
- 2026-11-18 — **The Homestead, step 1a: what the plan left open.**
  - **A sketch may have a legend of its own** (`tools/greybox/build_maps.gd`): the farm's map is the
    plan's drawing, read character by character, and its legend says which characters lay a tile. The Old
    Quarry's sketches are read as before. Why: the plan's drawing is the map, and its letters for debris
    are not the quarry's.
  - **The old cottage keeps its door, its entry point (`home_door`) and its scene's node name
    (`HomeDoor`).** Nothing leads to the entry now. Why: D9 says "no scene removed", and the tests of the
    doorway still hold.
  - **The main quest's words are measured, not counted.** A test held each stage's journal to 150
    letters; the approved words for `settle` and `bram` are longer. The test now lays each stage out in
    the quest log's own label and checks that it ends above the line of help, and that no stage is over
    200 letters.
  - **The farm is named "Your farm" and the room "Your farmhouse"** (the HUD's corner and the title's
    line for a save).
  - **For looks only, on the farm's Decor layer:** a chimney with its smoke, flowers gone wild along the
    farmhouse's front, three lily pads on the pond, and a scatter of tufts, flowers, pebbles and
    mushrooms as the other outdoor maps have.
  - **Until step 1c the farm plays the village's tune.**
- 2026-11-18 — **The Homestead, step 1b: what the plan left open.**
  - **The seven kinds are two sorts of data.** What the sword clears are breakables with `"returns":
    "never"` (the plan's R7); the three rocks are kinds in a new set of rules, `data/rules/homestead.json`
    (the plan lists the file), which also names the map that is his land. Why: a breakable already has
    its blows and its drop as data, and a rock's blows were already a rule.
  - **The land's stump is `farm_stump`,** a breakable of its own with the countryside's picture and
    numbers. Why: `stump` returns daily, and one id can't do both.
  - **A boulder's "blows" are counted for the plain pickaxe** (4, and 5 for a great boulder), and a
    better pickaxe takes off what it takes off in the quarry. That gives the plan's numbers exactly: 3
    with the Copper and 2 with the Iron; 3 with the Iron. The plain pickaxe never gets to try.
  - **A rock on the land breaks in one blow of a better pickaxe,** as a plain rock of the quarry does.
  - **Stone from the land is no practice at mining,** as plain stone in the quarry is none (no number of
    the skill was changed).
  - **Only the land keeps what is cleared.** `clear_debris()` and `is_debris_cleared()` take the area
    and answer "no" anywhere else, so a breakable that "never" returns means that only on the homestead.
  - **"Clear this first." is said by every tool of the plot,** not the hoe alone: the can, a seed and a
    sprinkler at such a cell would otherwise say "Till the soil with the hoe first.", which he can't.
  - **With a hoe in hand a left click at weeds on the field says "Clear this first."** and does not
    swing the sword: the field is the hoe's work, as it was. Space still swings, and the wheel changes
    what is in hand. (Off the field the click is the sword's, as before.)
  - **A better hoe's stroke passes over a cell with something on it,** as it passes over a cell tilled
    already.
  - **Fibre stacks to 50,** as stone does. The plan gives no number; no building's plan asks for more
    than 25.
  - **Six new spawn markers are a row of their own at the end of the atlas** (row 27): the markers' row
    had no room, and an older tile never changes place.
  - **A bomb's blast is one blow,** so it clears weeds and only starts on a log: what a bomb already
    does to a stump in the countryside.
  - **Twenty things of the plan's drawing were moved a cell or two** (three were moved further, to
    keep the pond's banks and a great boulder's foot open): they stood behind a tree's crown, against
    the woods' edge or behind an old tree, by the rule the wood in the countryside is held to
    (`Scenery.hiding()`). Why: what blocks his way should be in plain sight, and the plan allows a cell
    to shift when baked. Nothing on the field moved; the counts and the field's 54 are as approved.
- 2026-11-18 — **The Homestead, step 1c: what the plan left open.**
  - **An area may name its own night tune** (`AreaController.night_music`); only the homestead does.
    Why: the request asks for "a quieter track for night" of the farm's own, and every other outdoor
    place keeps the game's.
  - **The farmhouse plays the farm's day tune,** at every hour. Why: the village's houses play the
    village's; a tune that changed at his own door each time would grate.
  - **Capture shot 96 stays in the village** (the plan moves it to the farm with the plot's shots). Why:
    it is the picture the plan itself asks for as the "after" of the lane's west end, and it shows the
    locked cottage; the farmhouse's door has shots of its own (160, 165).
  - **`tools/play_days.gd` works the clear corner only** and does not clear land: the smallest change
    that keeps it playing. Teaching it the farm is phase 5's.
  - **The moved shots keep their names as well as their numbers** (2026-11-19, as the step was
    finished): 97 is still "home" and 151 "the cottage furnished", though the room is the farmhouse's.
    Why: the before-pictures in `reports/homestead/before/` pair with them by name.
  - **"Quieter" is tested as the sum of a tune's track volumes** in the audio tool's `SONGS`: the
    farm's night tune is under its day tune and under the game's own night tune, and slower than the
    day's. Nobody has listened to either tune: that is the user's to judge.
- 2026-11-19 — **The Homestead's phase 1 was approved by the user** ("Approve Phase 1"), shown the
  summary and seventeen pictures; nobody has played it by hand. Nothing was changed at the review. The
  choices the phase made where the plan was silent are above, under its three steps, and stand.
- 2026-11-19 — **CLAUDE.md's rules were brought up to date for phase 1 after that approval** (the plan's
  R2 to R8, R18 and R19), in the words of what was built: the home in the farmhouse, the plot on the
  homestead, the areas that may be added, the area's own night tune, land cleared for good, and a block
  for the homestead itself. The passages for phases 2 to 5 (R9 to R17) wait for their phases.
- 2026-11-19 — **Phase 1 was stopped by the user twice and picked up each time by a fresh subagent**
  from what was committed and what lay in the working tree; nothing was discarded. The last subagent
  re-read every test suite the first had moved and planted thirteen bugs, all caught.
- 2026-11-19 — **The Homestead, step 2a: what the plan left open.**
  - **A placeable is an item of type `placeable`** whose stats say what it is on the ground (`layer`, and
    for a standing thing `blocks` and `joins`). There is no `data/placeables/`: the plan's list of new
    data has none, a seed and a sprinkler are items in the same way, and the shop, the workbench and the
    chest already deal in items. Why: a new placeable is then a line of data and a picture.
  - **Its icon is its picture on the ground.** One sheet, `gameplay/art/placed.png`, holds both;
    `ItemIcons` draws from it for an icon it doesn't have itself.
  - **What is set down is two layers of `Homestead`,** saved as `lying` and `standing` in the save's
    `homestead` section, **and written only when something is set down:** a homestead with nothing on
    it is saved exactly as phase 1 saved it. Why: D30's "fields read with defaults", and every phase 1
    test of the save holds unchanged.
  - **A thing saved that the game no longer has, or on the wrong layer, is left out** as the save loads.
  - **The table's order is the order the refusals are tried in.** So the farmhouse's doorstep, which is
    the end of the path to its door, says "That is the road.", and the door's own cell (a way out) says
    the same. No cell of today's land says "That is a doorstep."; phase 3's buildings will have some.
  - **The road is read from the map:** a path tile of the Height layer, or a cell an exit covers. A
    doorstep is the cell below a door tile that an exit covers.
  - **A standing thing is not set down where something lies to be picked up** (what a rock left, what a
    full pack couldn't take): "Something is there already." Why: it would be shut in. A path may be laid
    under it.
  - **A lying thing may be laid under the hero's feet:** the table's "someone is standing there" is for
    standing things.
  - **"On screen" is the cells whose middle the camera shows.** The ghost stops at the view's edge, by
    the keys and by the mouse.
  - **The keys do what the two mouse buttons do,** where the ghost is: the sword's key (Space, J, a
    pad's X) sets down, and the item's key (Q, K, a pad's Y) takes up. A pad's A is the right click's
    twin, as in play, so it takes up. A movement key held repeats. Why: the plan gives the mouse its two
    buttons and the keys the ghost; without these a pad could move the ghost and do nothing with it.
  - **The ghost starts on the cell the hero faces** and goes to the mouse as soon as it moves.
  - **A right click takes up what stands in a cell before what lies in it.**
  - **The words the plan didn't give:** "Fence x12" over the bar where the thing fits; "You carry nothing
    to set down."; "Taken up: Fence."; "There is nothing here to take up."; and, for a full pack, the
    game's own "You have no room for the Fence."
  - **When the last of a thing is set down the first thing on the bar is chosen,** and with nothing left
    the ghost is a plain pointer that can still take things up. What was chosen is remembered while he
    stays on the farm.
  - **The build bar is the item bar drawn again** (`BuildBarView` extends `ItemBar`): the same slots in
    the same place, each with its count.
  - **The controls hint,** where the player has it showing, says build mode's keys while the mode is open.
  - **A fence shows a post, and a rail toward every neighbour that is a fence or a gate.** A gate is two
    capped posts with the way between them open (D18: no opening and shutting); in a fence that runs
    north and south it is the two ends of the gap. A lying thing has a thin dark rim on each side where
    nothing lies beside it.
  - **The ghost is drawn on a layer of its own that follows the camera,** so the night's tint doesn't
    dim it. It is tinted, not solid: what it would hide still shows.
  - **Setting a thing down raises a little dust and has a sound** (`set_down`; `take_up` for taking one
    up), both made in code.
  - **A stack of paths or fences is 99, of gates 20.** They go in the storage chest like anything that
    stacks, and are never eaten, given or on the item bar.
  - **`SpriteSheet.draw()` is left as it is,** though in this engine it draws a mirrored frame one
    frame's width to the right (measured). It is older than the Homestead and draws four creatures; a
    fence's west rail is mirrored by `PlacedArt` itself. Needs the user's word.
- 2026-11-19 — **The Homestead, step 2b: what the plan left open.**
  - **The hand moves a thing as it is** (`GameState.move_placed()`): nothing goes through the pack, a
    sapling keeps its mornings, and a grown tree is a tree in its new place. It is a right click that
    takes a tree up and gives back its sapling (D16). **A reading of D16 for the coordinator to confirm
    with the user:** "moving is taking up and setting down in one go", read to the letter, would make a
    moved tree a sapling again and would refuse a move with a full pack. Why this way: tidying a yard
    should cost nothing, and a full pack "loses nothing" either way.
  - **A lifted thing stays where it was until it is set down.** The ghost shows it and its old cell is
    outlined. A click on its old cell puts it back; a right click, another choice on the bar, or leaving
    the mode lets it go. Why: nothing is ever in limbo, so nothing can be lost or saved half moved.
  - **The hand lifts what stands in a cell before what lies in it,** as a right click takes up.
  - **With the hand on the bar, the last of a thing set down leaves the hand chosen** (step 2a chose the
    next thing). Why: the next click then sets nothing else down by mistake. The mode opens on what was
    chosen last time while it is still carried, else on the first thing he carries, else on the hand.
  - **A build bar longer than nine slots moves along with the choice,** as the item bar does, so the key
    1 is the leftmost slot showing: the hand, until he carries more than eight kinds of thing.
  - **A path or a floor says `"fills": true`,** and is drawn with a thin rim where none lies beside it.
    A flower bed has its own edge and gets none.
  - **A lamp post has the village lamps' own numbers** (a reach of 22, a strength of 0.3, their colour,
    no flicker) and their hours: it is lit when the day's lamps are, 18:30 to 06:30. It is one cell tall,
    as the village's are, with a dark picture and a burning one.
  - **A sapling's three pictures are spread evenly over its mornings:** the oak's over two, one and one,
    the cherry's over two each. Any morning counts (a night slept, stayed up through, or collapsed in),
    and no water is needed.
  - **A grown sapling is one of `Scenery`'s trees** (`Scenery.stand()`, the code that stands the map's):
    the "oak" picture, or one of the two cherry pictures by its cell, as the map's cherries vary. It
    blocks its own cell, as the sapling did. No petals lie round a planted cherry: the map's are laid
    once as the area loads, and nothing drifts.
  - **A sapling's mornings are saved beside it** (`"age"`, left out at 0), and a tree stands again as the
    land loads.
  - **The nine recipes of the "Place" tab are known from the first day:** the plan's table gives them a
    cost and no condition. Each is named for the item it makes, with how many ("Fence x2").
  - **A recipe's `tab` is `make` or `place`** (`make` if it names none); `build` is phase 3's to add.
    `GameState.known_crafts()` still gives every workbench recipe he knows: the list splits them by tab.
  - **The workbench opens on "Make" every time.** A and D (or the arrows) turn the tab, round and round.
  - **Tilda's list:** her four old wares, then fibre, the hedge, the red, yellow and blue flower beds and
    the two saplings, then the seeds: sixteen lines. She buys none of them back: the plan's "no selling
    of fibre" is kept, and no selling of what is set down was asked for.
  - **Stacks:** floors 99, hedges 50, flower beds 30; lamp posts, benches and saplings 10.
  - **The sprite tool can make a frame from another by swapping colours** (`"swap"`), beside breathing
    and blinking: the dark lamp, two flower beds and the cherry sapling are made so.
  - **Older tests that counted Tilda's wares or the workbench's list were brought up to date,** each
    keeping its checks: the shop's carry sixteen wares, and the workbench's ask for the "Make" tab.
- 2026-11-19 — **The Homestead's phase 2 was approved by the user** ("Approve Phase 2"), shown the
  summary and nine pictures; nobody has played it by hand. It was approved as built, so the choices the
  phase made where the plan was silent (above, under steps 2a and 2b) stand, among them **the hand's
  reading of D16:** a moved sapling keeps its mornings and a moved tree stays a tree, and only taking a
  tree up gives back its sapling. The user did not speak to that reading apart; the coordinator had
  recommended it.
- 2026-11-19 — **CLAUDE.md's rules were brought up to date for phase 2 after that approval** (the plan's
  R10 to R14 and a block for phase 2), in the words of what was built, with the names checked against
  the code. R10's `build` tab, R9 and R15 to R17 wait for their phases.
- 2026-11-19 — **No look after step 3a.** The plan suggested one; put to the user with phase 2's summary,
  it was not answered, so phase 3 stops at its end by the user's own rule, committing after each step.
- 2026-11-19 — **Left for the user, not changed:** a mirrored sprite frame is drawn one frame's width to
  the right in this engine (phase 2's subagent measured it; the chickens, a side-on goblin, the Warden and
  the Shade facing the other way). It is older than the Homestead and outside it.
- 2026-11-19 — **The Homestead, step 3a (plans, kits, sites, the Well, the Silo, hay): what the plan
  left open.** D20, D21 and D29's hay are built as written; these are the phase's own choices.
  - **A kit is an item of type `kit`** whose stats name its building (`{"building": "well"}`); one kit to
    a building. It doesn't stack (one of each), is kept out of every chest (`Store.KEPT_OUT`), is no
    `Inventory.EQUIPPABLE_TYPES`, and is on the build bar after the hand, among the placeables in the
    pack's order. All five kits wear one picture (`kit`: planks bound, a plan rolled on top).
  - **A building is a file in `data/buildings/`** (size, door, room, what it does, its look as blocks of
    the atlas's tiles, laid by the baker's own rules). `Buildings` (`core/homestead/`, pure) reads it.
  - **One of each** is asked of the plan: refused ("You have one already.") with its kit in the pack, its
    site set down, or the building standing.
  - **A plan refused for want of something says what is short, by name** ("You are short of 40 Stone,
    10 Wood and 80 Coins."), on the "Build" tab only: the other tabs keep "You haven't all it needs."
    (13 tests read those words). On the workbench coins read "Coins" ("Coins 50 of 80"); one coin short
    is "1 Coin". A plan bought says "Bought: Well Kit. Set it down in build mode."
  - **The ghost holds a building by its door,** and one without a door by the middle of its bottom row:
    the cell under the mouse is that cell.
  - **The doorstep is asked the plan's table as every cell of the building is** ("if any cell under it or
    its doorstep fails the above"), read to the letter: a doorstep on the road, the field, another
    doorstep or tall grass is refused. A path lying under a building is allowed (D14: one lying, one
    standing): it stays under it, covered.
  - **A building's cells, and a site's, say "Nothing can stand there."** to anything set down on them, as
    the farmhouse's do.
  - **Any morning finishes a site** (a night slept, stayed up through, or collapsed in), as any morning
    grows a sapling. The hero is told at the top of the screen ("The Well stands on your farm.") with
    the sound `built`, where he is or, if the morning came on his way somewhere, where he arrives.
  - **The Well is low:** it casts no house's shadow, and it wears the village well's own picture. The can
    fills facing any of its four cells once it stands; a site is no well.
  - **The Silo takes all the hay he carries** with one right click, up to its 60; what doesn't fit stays
    in the pack, and the words say how much it holds. Nothing takes hay out of it in this phase (phase 4
    feeds from it).
  - **Hay** is a material, stacks to 50, and may go in a chest like any material; nobody buys it (the
    plan's "no selling of hay").
  - **The meadow's tall grass** is a breakable of its own, `meadow_grass`, on a seventh land marker: the
    village's tall-grass picture, cut by the sword or a bomb, one hay lying in its cell, back the next
    morning (`"returns": "daily"`, the flag `cut/homestead/x,y`). It is no debris to the farm's tools
    (it is not on the field), but nothing can be set down on a tuft that stands ("Clear this first.").
  - **The tall grass and a save from phase 2 (the brief's open point):** phase 2 left the fourteen tufts
    plain grass, so a save may have a path, a fence or a sapling on one. **A tuft doesn't grow where
    something lies or stands, or a building covers its cell:** such a tuft is taken away as the land
    loads, its cell left to what stands there; taken up again, the tuft is back on the next visit.
    Nothing is lost, and nothing set down moves.
  - **A building is drawn as the farmhouse is:** its tiles flat on the ground under everyone (the
    village's own house tiles, and five new ones and a silo at the end of the atlas, rows 28 and 29), the
    shadow `HeightShading` gives a house east and south, and a ridge strip over its roof among the
    area's scenery, as `Scenery` stands the farmhouse's. A site is dug ground pegged out with twine
    over its cells and a stack of timber in the middle of its bottom row.
  - **The save stays version 6** (D30): the section `homestead` gains `"buildings"` (`{ id: { "at":
    "x,y", "day": n, "big_day": n } }`, `big_day` only for an upgrade) and `"hay"`, each written only
    when there is something in it and read with a default. A building the game doesn't know is left out.
- 2026-11-19 — **The Homestead, step 3b (the rooms, the shed's furnishings, the upgrades): what the plan
  left open.** D20, D22 and D23 are built as written; these are the phase's own choices.
  - **The Coop and the Shed are 4 by 3 with their door in the middle of the bottom row (column 2); the
    Barn is 6 by 4 with its door at column 3.** Their looks: the Coop thatched like the farmhouse, the
    Shed slate-roofed with a chimney (it has a furnace), the Barn a red-tiled roof over two rows of red
    planks with a loft door above its door. **The Big Coop** wears clay tiles in place of thatch and
    **the Big Barn** slate in place of tiles: the same size and place, so the bigger form shows.
  - **Each room is an 11 by 9 area** (`coop`, `barn`, `shed`) baked like every house's inside, named
    "Your coop", "Your barn", "Your shed", playing the farm's tune. Its doormat leads to the homestead's
    entry `<id>_door`, which the area puts on the building's doorstep (facing south) each time it loads
    and whenever the building changes, so the door leads the right way wherever the building stands.
    The rooms stand empty of animals: perches and nest boxes, troughs and barrels, shelves.
  - **A building's door is an `AreaExit` on its door's cell,** made by the area: the building fills all
    its cells but that one, which the hero walks into from the doorstep. A site has no door.
  - **The shed's furnishings are three recipes on the "Build" tab (after the seven plans), known once
    the shed stands,** so the farmhouse's "Make" list is as it was: Shed
    Furnace (20 stone, 5 copper ore), Shed Chest and Second Shed Chest (10 wood and a copper bar each),
    the farmhouse's own costs. Their flags are `shed/furnace`, `shed/chest_a`, `shed/chest_b`; their
    places in the shed are (5, 2), (2, 2) and (8, 2). The crafting rules name the shed's room and its
    three furnishings (`"rooms"`).
  - **The furnaces and chests are kept by key:** `GameState.furnace()` and `store()` are the
    farmhouse's, as before; `furnace(&"shed")`, `store(&"shed_a")` and `store(&"shed_b")` the shed's,
    each with one load or 24 stacks of its own. The furnace's conversation carries its key in its
    effects (`"furnace": "shed"`), and the farmhouse's carries none, as before. They are saved in the
    section `homestead` (`"furnaces"`, `"chests"`), written only when one holds something; the
    farmhouse's stay in `home`.
  - **An upgrade is a recipe of the "Build" tab that makes `{"upgrade": id}`,** known once that building
    stands (`"unlock": {"built": id}`), bought with its materials and coins, and finished the next
    morning ("The Big Coop is finished."). One upgrade a building. Its room is the room it had.
- 2026-11-19 — **The Homestead, step 3c (moving and pulling down): what the plan left open.** D24 is
  built as written; these are the phase's own choices.
  - **The hand lifts a building from any of its cells,** and the ghost then holds it where it stands (by
    its door, or the middle of its bottom row); a click where it fits moves it at once, for nothing, as
    it is. Its own cells and its own doorstep are no hindrance to itself, so it can be moved a cell.
    What is in it goes with it because nothing of it is kept by place: the silo's hay, the shed's
    chests and furnace (by key), its upgrade, its door and the entry before it.
  - **A site can be moved like a building** (it stays a site, with the day it was set down), **and a
    right click on a site takes it up and gives its kit back whole,** if there is room for it: nothing
    was built, so nothing is lost. A right click on a standing building is what pulls one down.
  - **"Asks first" is a second right click:** the first says "Pull down the Coop? Right click again.
    Back: 15 Wood, 10 Stone and 7 Fibre." and washes the building red; moving the ghost off it, choosing
    on the bar or leaving lets the question go. No dialogue box is opened over build mode.
  - **"Only an empty building can go" is asked before the question,** with the reason: "The Silo still
    holds hay.", "There are things in the Shed's chests.", "The Shed's furnace holds a load." (each
    followed by "Only an empty building can be pulled down."). Animals are phase 4's to add.
  - **Nothing takes hay out of the silo in this phase,** so a silo with hay in it can't be pulled down
    until phase 4's animals eat it. Left so on purpose (the plan has no way out for hay); the user may
    want one. *(For the coordinator to put to the user.)*
  - **Half of each material is counted over the plan and, for a big building, its upgrade together,**
    then halved and rounded down (the Big Coop: 50 wood gives 25). Coins never come back. It is given:
    what the pack can't take lies at his feet as a `LeftItem`, as a reward's does.
  - **A pulled-down shed's furnishings stay with the room** (their flags are kept): a shed built again
    has its chests and furnace, empty. Nothing is lost, and no refund is given for them.
  - **A building pulled down can be bought again:** one of each is one that stands, or is a site or kit.

## 2026-11-19 — Two roofs and the shed's furniture (the user's review of the Homestead's phase 3)
- **The Coop wears wooden shingles, silver-brown with the weather, and the Big Barn green boards
  with standing seams:** two new roof styles (`roof_shingle`, `roof_green`) beside the clay, slate
  and thatch, each with its tiles at the end of the atlas and its own ridge strip. Chosen to be told
  apart by colour and by pattern from the farmhouse's thatch, the Shed's slate and the red tiles of
  the small Barn and the Big Coop. For show only.
- **The Shed's two bookshelves became a rack of tools and sacks on a crate,** two new furniture
  tiles as solid and as tall as the shelves (height 2), so nothing changed but the pictures.

## 2026-11-19 — The user's review of the Homestead's phase 3
- **A silo with hay in it can't be pulled down** (the user: "Keep as built"). Nothing takes hay out of
  the silo until phase 4's animals eat it; pulling it down does not give the hay back.
- **The Coop's room keeps its shelves** (as perches and nesting boxes) for now: the user named only
  the shed's bookshelves.

## 2026-11-19 — The Homestead, phase 4: animals
- 2026-11-19 — **The Homestead, step 4a (the rules): what the plan left open.** D25 to D28 and D30 are
  built as written; the table's prices, products, paces and grass are in data. These are the step's
  own choices.
  - **A kind of animal is a file in `data/animals/`** (`docs/data/animal.schema.json`): `lives_in`,
    `gives`, `every`, `grazes`, `sound`. `Herd` (`core/homestead/`, pure) reads it and does a morning
    and a petting. Its price is not in it: a price is the shop's, as every price is, so Oda's stall is
    `data/shops/oda.json` with wares `{ "animal": "chicken", "price": 60 }` (R15).
  - **A morning goes in steps of half a morning:** fed and petted the day before, two halves nearer;
    fed only, one; unfed, none. A product is ready when the halves reach twice its `every`, so a hen
    fed and never petted lays every second morning, a cow every fourth, a sheep every sixth. A product
    waiting stops the next: nothing is gained while one waits, and nothing is stored up.
  - **"Unhappy" is the morning's `hungry`:** an animal that went unfed this morning is hungry for the
    day and is shown so; the next morning that feeds it ends it. Nothing else follows from it (D27).
  - **The herd is fed in the order it was bought.** Each animal, in turn, eats its `grazes` cells from
    its building's pasture if that much grass is left, else one hay from the silo, else nothing. Two
    buildings whose doors open on one fenced ground share its grass.
  - **A pasture is the ground reached from the building's doorstep, cell to cell, through what can be
    crossed** (`Pasture`, pure). Anything standing stops it (a fence, a gate, a hedge, a lamp post, a
    bench, a sapling), as do buildings and sites, debris not cleared, and what was solid on the map (the
    woods, the trees, the pond, the farmhouse). The meadow's tall grass is grass: it is cut and comes
    back, and grazing it doesn't stop it growing. Reaching the road, the path to the farmhouse, a way
    out or the map's edge, it is not fenced. A cell of the field, or one with a path, floor or flower
    bed lying on it, is crossed and not grazed.
  - **The land as it was is read from its scene once a run** (`LandSurvey`, a `LandMap`), so a morning
    knows each pasture while the hero is asleep in the farmhouse, far from the homestead's area: what
    he has cleared, set down and built is laid over it from `GameState.homestead()`.
  - **An animal is bought only for a building that stands** (a site is no coop yet), with room: four,
    or eight once the upgrade is finished; sheep and cows count together in the barn. The words: "A
    chicken needs a Coop on your farm.", "Your Coop has no room for another.", and the shop's "You
    haven't the coins for that." Bought, it is in its building at once ("Bought: a chicken. It is in
    your Coop.").
  - **No animal is ever taken away:** nothing dies, runs off or is sold, so an animal's place in the herd
    is its name in the code.
  - **A building with animals can't be pulled down** ("The Coop still has animals in it. Only an empty
    building can be pulled down."). Moved, its animals go with it: an animal lives in its kind's
    building, wherever that stands.
  - **Oda's stall is the village's market stall again,** the same six tiles, at (16..18, 30..31) beside
    her: no new pictures. Her list has no "Sell" of its own: the second tab says "You carry nothing she
    buys."
  - **The products are items from this step** (the egg and the milk food, 6 and 18 energy; wool a
    material; each stacks to 30), since the kinds name them; their prices, the dishes and the cloth are
    step 4c's.
  - **The save is still version 6:** `homestead` gains `"animals"`, written only when there is one, each
    `{ "kind", "petted", "progress", "ready", "hungry" }`. A kind the game no longer has is left out.
    The fixture `tests/fixtures/saves/v6_buildings_before_animals.json` was written by the game at the
    end of phase 3 (`21199f6`).
