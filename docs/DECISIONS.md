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
