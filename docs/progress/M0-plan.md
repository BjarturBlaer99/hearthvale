# M0 — Project skeleton (plan)

Goal (ROADMAP M0): a Godot project that opens, a data loader that validates content, and a green
headless test run. No gameplay.

## Steps
1. **Toolchain** — Godot 4.7.2 (winget, user-scope). Record the binary path in `CLAUDE.md`.
2. **`project.godot`** — 480×270 base viewport, `canvas_items` stretch, integer scaling, nearest
   texture filter, GL Compatibility renderer (performance budget: 60 fps on integrated graphics),
   four autoloads, gdUnit4 enabled.
3. **Folder layout** — exactly TECH_DESIGN §1: `autoload/ core/{water,terrain,quests,factions,inventory,dialogue}/
   gameplay/ world/{districts,interiors,sea}/ ui/ data/ tests/ addons/gdUnit4/`.
4. **Seed data** — the four files in `docs/data/*.example.json` become real content under `res://data/`,
   split by kind: `data/water/spillway.json`, `data/items/items.json`, `data/factions/factions.json`,
   `data/quests/bitter_medicine.json`, `data/dialogue/greenterrace_elder.json`. No new content written.
5. **Autoload stubs** — `EventBus` (the five signals in TECH_DESIGN §2, no state), `GameState`
   (the §9 save shape, `to_dict`/`from_dict`, mutators that emit on `EventBus`), `SaveSystem`
   (`user://saves/slot_<n>.json` with a `version` field and a migration hook).
6. **`DataRegistry`** — scans `res://data`, directory name decides the kind of file, validates
   required fields, then resolves every cross-reference (district, basin, node, interior, item,
   faction, companion, quest, dialogue, and the ids inside conditions/effects). Checks that each
   district's `water_height` values strictly decrease. Collects errors rather than throwing, so it
   is testable; `_ready()` pushes them and asserts.
7. **JSON Schemas** — `docs/data/*.schema.json` for the condition/effect vocabulary and the four
   file kinds, as `CONDITIONS_AND_EFFECTS.md` requires.
8. **Test scene** — `world/dev/m0_smoke.tscn` as the main scene: prints what loaded.
9. **Tests** — `tests/` mirrors `core/`: DataRegistry happy path, known ids, strictly decreasing
   levels, and two bad-data fixtures (missing required field, unresolved reference); GameState
   round trip, reputation clamp, signal emission.

## Acceptance criteria (from ROADMAP)
- [x] headless test command runs green
- [x] `godot --path .` opens a test scene
- [x] `docs/progress/LOG.md` exists

## Deliberately not in M0
Water solver, height grid, player, any district map, UI beyond the smoke label.
