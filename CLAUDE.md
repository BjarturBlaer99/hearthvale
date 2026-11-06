# CLAUDE.md — Low Tide

You are building **Low Tide**, a **2D top-down** open-world RPG in **Godot 4.x (latest stable) using typed GDScript**.
Read these before writing any code:

1. `docs/GDD.md` — what the game is (design source of truth)
2. `docs/TECH_DESIGN.md` — how it is built (architecture source of truth)
3. `docs/ROADMAP.md` — what to build next, milestone by milestone
4. `docs/data/` — example data files showing the schemas content must follow

## Current goal
Build the **vertical slice** described in `docs/ROADMAP.md` (region: *The Spillway*). Do not build
anything outside the current milestone. Scope creep is the main risk on this project.

## How to work
- Work one milestone at a time, in order. Each milestone has acceptance criteria — meet them, then stop and summarize.
- Before a milestone, write a short plan in `docs/progress/M<n>-plan.md`. After it, append results and known issues to `docs/progress/LOG.md`.
- If a design question isn't answered in the docs, pick the simplest option that keeps systems data-driven, note it in `docs/DECISIONS.md`, and continue.
- Use placeholder art: flat-colored 16×16 tiles generated in code or as tiny PNGs you create, `ColorRect`/`Polygon2D` for actors. No external art, audio or asset-store dependencies until the roadmap says so.

## Commands
```bash
# Run the game
godot --path .
# Run all tests headless (gdUnit4; exit code 0 = green; --continue reports every failure)
godot --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd --add res://tests --ignoreHeadlessMode --continue
# Import / validate project without opening the editor
godot --headless --path . --import
# Boot the game headless for a few frames (prints the smoke report, catches autoload errors)
godot --headless --path . --quit-after 30
```
If `godot` is not on PATH, ask the user for the binary path and record it here.

**This machine:** Godot 4.7.2 (winget, user scope). `godot` is a shim, `godot.cmd`, in the winget package folder,
which is on the user PATH (new shells only):
`C:\Users\bjarturbg\AppData\Local\Microsoft\WinGet\Packages\GodotEngine.GodotEngine_Microsoft.Winget.Source_8wekyb3d8bbwe\`
It runs `Godot_v4.7.2-stable_win64_console.exe` (use the `_console` binary for captured output). `winget upgrade`
removes the shim, so recreate it after upgrading.

**Testing gotchas:**
- `--ignoreHeadlessMode` is required headless. InputEvents aren't delivered headless, so tests that need input must run windowed.
- gdUnit4's CLI is **fail-fast by default**: it stops at the first failing test, and "Executed test cases (n/n)"
  only counts what ran. Always pass `--continue` (`-c`) to see every failure.
- `StringName` sorts by internal pointer, not text. Compare as `String` when order matters.

## Code conventions
- **Typed GDScript everywhere**: `var hp: int = 10`, typed function signatures, `class_name` on reusable scripts.
- snake_case files and functions, PascalCase classes/nodes, UPPER_SNAKE constants.
- Use `TileMapLayer` (not the deprecated `TileMap` node). Use 2D nodes only (`CharacterBody2D`, `Area2D`, `Camera2D`).
- One responsibility per script. Systems talk through **signals on `EventBus`**, not direct references across scenes.
- **Gameplay content is data, not code**: quests, dialogue, items, factions and water states live in `data/` as JSON validated against schemas in `docs/data/`. Adding a quest must never require a new script unless it needs a new *type* of step.
- All game state that must persist goes through `GameState` and is serializable to a Dictionary. No state hidden in scene nodes.
- Pure logic (water solver, height/terrain queries, quest evaluation, faction reputation, inventory) lives in plain `RefCounted` classes with **unit tests**. Scenes stay thin.

## Do not
- Do not hand-edit `.import` files or anything under `.godot/`.
- Do not simulate water as fluid physics. Water is a discrete per-district water height compared against per-cell terrain height (see TECH_DESIGN §3).
- Do not build a separate scene per water level. One district map; the water height decides what is land, shallows and deep water.
- Do not add a dependency/addon without noting why in `docs/DECISIONS.md`. Allowed now: gdUnit4.
- Do not write lore, dialogue or quest content beyond what the current milestone needs.
