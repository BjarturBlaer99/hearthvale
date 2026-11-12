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
- 2026-11-11 — **Animation never changes play.** The wind-up and the settle are pictures chosen by how far
  through the swing the motor is. The blade is live from the first frame and the swing is as long as it was.
