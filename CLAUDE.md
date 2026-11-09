# CLAUDE.md — Hearthvale

You are building **Hearthvale**, a **2D top-down action-adventure** (A Link to the Past style) in
**Godot 4.x (latest stable) using typed GDScript**. Read these before writing any code:

1. `docs/GDD.md` — what the game is (design source of truth)
2. `docs/TECH_DESIGN.md` — how it is built (architecture source of truth)
3. `docs/ROADMAP.md` — what to build next, milestone by milestone (the slice H0–H9, phase 2 H10–H15)
4. `docs/data/` — example data files showing the schemas content must follow

## Current goal
**Phase 2** in `docs/ROADMAP.md` (H10–H15): grow the finished vertical slice (H0–H9) into a small game of about
two hours: feel and sound, a blue-suited hero and pixel art everywhere, a more detailed world (not a bigger one),
quests, a second dungeon, a light story. Do not
build anything outside the current milestone. Scope creep is the main risk on this project.

History: the project began as "Low Tide", a water-level game (milestones M0–M4 in `docs/progress/LOG.md`). It
pivoted to Hearthvale on 2026-11-07; the last water version is on the `water-version` branch. Water-era entries
in `docs/DECISIONS.md` are superseded.

## How to work
- Work one milestone at a time, in order. Each milestone has acceptance criteria — meet them, then stop and summarize.
- Before a milestone, write a short plan in `docs/progress/H<n>-plan.md`. After it, append results and known issues to `docs/progress/LOG.md`.
- If a design question isn't answered in the docs, pick the simplest option that keeps systems data-driven, note it in `docs/DECISIONS.md`, and continue.
- Art and sound are made in code (no external art, audio or asset-store dependencies until the roadmap says so).
  The slice started with placeholder shapes; phase 2 replaced them with pixel art, as below.
  **Exception (user's request, 2026-11-07; blue suit 2026-11-08):** the hero is a Zelda-style pixel-art sprite in a blue suit, painted from ASCII art by
  `tools/art/make_player_sprite.gd`. Keep it; edit the art in that tool, never the PNG.
  **Exception (user's request, 2026-11-08):** the environment tiles are proper pixel art (grass, trees, roofs with
  ridges and eaves, windows, water...) plus a Decor layer of flowers, tufts and the like, all still painted in code by
  `tools/greybox/make_tile_texture.gd` and placed by `build_maps.gd`. No external assets; edit the art in the tool.
  **Every other actor (H11)** is pixel art painted from ASCII by `tools/art/make_sprites.gd` into `gameplay/art/`
  (no placeholder shapes left; effects like shadows and sparks stay drawn in code). Edit the art in the tool.
  **Sound (H10):** all sound effects and music are made in code by `tools/audio/make_audio.gd` (Synth) and baked to
  `audio/`. No external audio; edit the sounds in the tool, never the WAVs.

## Commands
```bash
# Run the game (the title screen; Esc pauses)
godot --path .
# Run all tests headless (gdUnit4; exit code 0 = green; --continue reports every failure)
godot --headless --path . -s addons/gdUnit4/bin/GdUnitCmdTool.gd --add res://tests --ignoreHeadlessMode --continue
# Import / validate project without opening the editor
godot --headless --path . --import
# Boot the game headless for a few frames (catches script and autoload errors)
godot --headless --path . --quit-after 30
# Screenshots for review (needs a window, not --headless)
godot --path . -s res://tools/capture.gd -- <output_dir>
# Start partway through to try one part by hand (scenarios in the script, e.g. warden)
godot --path . -s res://tools/playtest.gd -- warden
# Repaint the hero's sprite sheet after editing its ASCII art (optional 8x preview), then re-import
godot --headless --path . -s res://tools/art/make_player_sprite.gd -- <preview.png>
godot --headless --path . --import
# Repaint the other actors' sprites after editing tools/art/make_sprites.gd, then re-import
godot --headless --path . -s res://tools/art/make_sprites.gd
godot --headless --path . --import
# Re-bake sound effects and music after editing tools/audio/make_audio.gd (or just some: -- sword boss), then re-import
godot --headless --path . -s res://tools/audio/make_audio.gd
godot --headless --path . --import
# Rewrite the input map after editing tools/setup_input_map.gd
godot --headless --path . -s res://tools/setup_input_map.gd
# Greybox: regenerate the tiles and re-bake the areas' Height layers (OVERWRITES editor painting of those layers).
# build_maps.gd bakes every area, or only those named: -- village
godot --headless --path . -s res://tools/greybox/make_tile_texture.gd
godot --headless --path . --import
godot --headless --path . -s res://tools/greybox/build_tileset.gd
godot --headless --path . -s res://tools/greybox/build_maps.gd
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
- Headless, drive input with `Input.action_press()` / `action_release()` (sets action state directly);
  gdUnit4's `simulate_action_*` sends InputEvents, which headless mode drops.
- Area scene tests: load areas one at a time with `tests/support/area_steps.gd` (a loaded area writes
  `GameState.player` every frame) and let it replace `AreaController.travel`, so taking an exit stays in the test.

**Tool-script gotchas (`-s res://tools/...`):**
- A `-s` script compiles before the autoloads exist. Never name a class that uses an autoload (e.g.
  `AreaController`) or the autoload itself in a tool script; look things up at runtime
  (`root.get_node("GameState")`, untyped `Node`).
- When a tool re-saves a scene, instantiate it with `PackedScene.GEN_EDIT_STATE_MAIN`, or `pack()` pins every
  inherited property of instanced children (Player, HUD) as an override.
- Windows PowerShell 5.1's `Set-Content -Encoding utf8` writes a byte-order mark. Edit text files with the Edit
  tool or `sed`, not PowerShell.
- On this machine a file just written can be locked for a moment (`OSError: [Errno 22] Invalid argument` on the
  next write). Scripts that write the same file twice in a row should retry briefly.

## Code conventions
- **Typed GDScript everywhere**: `var hp: int = 10`, typed function signatures, `class_name` on reusable scripts.
- snake_case files and functions, PascalCase classes/nodes, UPPER_SNAKE constants.
- Use `TileMapLayer` (not the deprecated `TileMap` node). Use 2D nodes only (`CharacterBody2D`, `Area2D`, `Camera2D`).
- One responsibility per script. Systems talk through **signals on `EventBus`**, not direct references across scenes.
- **Gameplay content is data, not code**: items, quests, dialogue and enemies live in `data/` as JSON validated against schemas in `docs/data/`. Adding a quest must never require a new script unless it needs a new *type* of step.
- All game state that must persist goes through `GameState` and is serializable to a Dictionary. No state hidden in scene nodes.
- Pure logic (terrain rules, player motor, combat rules, quest evaluation, inventory, puzzles) lives in plain `RefCounted` classes with **unit tests**. Scenes stay thin.

## Do not
- Do not hand-edit `.import` files or anything under `.godot/`.
- Do not add swimming, climbing or stamina: the hero moves like classic Zelda (stairs, ledge hops, solid tiles),
  plus a hold-to-sprint the user asked for on 2026-11-08 (no stamina). Change the GDD first if that should change.
- Do not add a dependency/addon without noting why in `docs/DECISIONS.md`. Allowed now: gdUnit4.
- Do not write story, dialogue or quest content beyond what the current milestone needs.
