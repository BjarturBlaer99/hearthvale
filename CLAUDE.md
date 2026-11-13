# CLAUDE.md — Hearthvale

You are building **Hearthvale**, a **cosy 2D story RPG with farming and survival**, seen from above, in
**Godot 4.x (latest stable) using typed GDScript**. It began as a top-down action-adventure and **pivoted on
2026-11-12**: the dungeons, the story and the combat stay, and energy, food, time, farming and a modern
pixel-art look are added in phases. Read these before writing any code:

1. `docs/GDD.md` — what the game is (design source of truth; parts marked *(P1)*–*(P4)* are not built yet)
2. `docs/TECH_DESIGN.md` — how it is built (architecture source of truth)
3. `docs/ROADMAP.md` — what to build next (the slice H0–H9, phase 2 H10–H15, the pivot P1–P4)
4. `docs/progress/pivot-plan.md` — the pivot's audit, the nine decisions the user approved, and the risks
5. `docs/data/` — example data files showing the schemas content must follow

## Current goal
**The pivot** in `docs/ROADMAP.md` (P1–P4), in order: **P1** the visual overhaul (six steps, 1a–1f), **P2**
energy, food and time, **P3** farming, **P4** RPG and story. Do not build anything outside the current step, and
ask the user before adding anything the roadmap doesn't list. Scope creep is the main risk on this project.

It is Hearthvale's own game: take the genre's mechanics, never another game's art, interface or characters.

History: the project began as "Low Tide", a water-level game (milestones M0–M4 in `docs/progress/LOG.md`). It
pivoted to Hearthvale on 2026-11-07; the last water version is on the `water-version` branch. Water-era entries
in `docs/DECISIONS.md` are superseded.

## How to work
- Work one step at a time, in order. Each has acceptance criteria — meet them, then stop and summarize.
- **During the pivot (the user's rule, 2026-11-12):** at the end of each step all tests pass, new logic has
  tests, the work is **committed**, and you **stop** with a short summary and screenshots of what changed, so
  the user can review before the next step. Push only when asked.
- Before a step, write a short plan in `docs/progress/P<n>-plan.md` (`H<n>-plan.md` for the old milestones). After it, append results and known issues to `docs/progress/LOG.md`.
- A change to the save format needs a new version number and a migration from old saves, with a test.
- If a design question isn't answered in the docs, pick the simplest option that keeps systems data-driven, note it in `docs/DECISIONS.md`, and continue.
- Art and sound are made in code (no external art, audio or asset-store dependencies until the roadmap says so).
  The slice started with placeholder shapes; phase 2 replaced them with pixel art, as below.
  **Exception (user's request, 2026-11-07; blue suit 2026-11-08):** the hero is a Zelda-style pixel-art sprite in a blue suit, painted from ASCII art by
  `tools/art/make_player_sprite.gd`. Keep it; edit the art in that tool, never the PNG.
  **Art pass 2 (user's request, 2026-11-09, between H13 and H14):** the hero has a red scarf and nine frames a row
  (walk cycle, blink, attack, item held up, fallen); houses are half-timbered with thatch, tile and slate roofs;
  paths and water have soft edges drawn by `HeightShading`. See `docs/progress/art-pass-2-plan.md`.
  **Exception (user's request, 2026-11-08):** the environment tiles are proper pixel art (grass, trees, roofs with
  ridges and eaves, windows, water...) plus a Decor layer of flowers, tufts and the like, all still painted in code by
  `tools/greybox/make_tile_texture.gd` and placed by `build_maps.gd`. No external assets; edit the art in the tool.
  **Every other actor (H11)** is pixel art painted from ASCII by `tools/art/make_sprites.gd` into `gameplay/art/`
  (no placeholder shapes left; effects like shadows and sparks stay drawn in code). Edit the art in the tool.
  **Art pass 3 (user's request, 2026-11-10, after H15):** a warmer, softer look. Every art tool passes its
  picture through `PixelGrade` (`core/art/`) as it bakes: warmer colour, and outlines in a dark shade of what they
  surround. Tune the look there, not picture by picture. It is Hearthvale's own look: do not copy another game's
  art. See `docs/progress/art-pass-3-plan.md`.
  **Art pass 4 (user's request, 2026-11-11):** light and lettering. Lamps, hearths, torches and crystals glow
  (real lights since P1b: `AreaLighting`, `Ambience`), tall things cast shadows east as well as south
  (`HeightShading`), houses and dungeons are dim away from their lights (for show only; the crypt's dark is the
  only light that matters to play, and it is drawn by the rule's own lights), and all
  text is Hearthvale's own pixel font, painted from ASCII by `tools/art/make_font.gd` with the UI theme. Label
  sizes are whole multiples of 8; boxes wear `PanelFrame`. See `docs/progress/art-pass-4-plan.md`.
  **Hero pass (user's request, 2026-11-11):** over the blue tunic the hero wears a leather vest, wrist guards, a
  belt pouch, slate trousers and tall boots, with his sword on his back and a small pack. (Its sixteen 16x24
  frames were replaced in P1e, below.)
  The animator only picks pictures; swing timing and hits belong to the motor. See `docs/progress/hero-pass-plan.md`.
  **Characters (P1e, 2026-11-12):** the hero is two cells tall (16x32) with his hood down, and is put together
  from parts by the tool (a head, a body pose, a pair of legs per facing), so edit a part and every frame that
  uses it follows. Twenty-one frames a row: six-frame walk and run, a three-frame swing. Villagers are as tall,
  and breathe and blink (`Idling`). Feet, collisions and the sword's reach are where they were: `Sword.HAND`
  only says where the blade is drawn from. See `docs/progress/P1e-plan.md`.
  **UI polish (P1f, 2026-11-12):** headings are set in a second, larger face (`ui/font/hearth_heading.tres`,
  size 16, capitals only: a small letter shows as its capital), baked by `tools/art/make_font.gd` and offered by
  the theme as the `Heading` kind of label. `PanelFrame` draws corner brackets and, with `rule_y`, a rule under
  a box's heading. The title screen's evening is painted by `tools/art/make_title.gd` (`TitlePicture` has the
  layout; `TitleBackdrop` draws what moves). The HUD's corner is as wide as its words and hides empty lines.
  See `docs/progress/P1f-plan.md`.
  **Nature (P1c, 2026-11-12):** trees are tall pictures painted by `tools/art/make_scenery.gd` and stood up at
  load by `Scenery` (the hero walks behind them; a crown fades when anything that matters is behind it). A tree
  still blocks exactly its own cell. Cherry trees are `"cherry"` blocks in `build_maps.gd`; the eight new cells
  in Hearthvale were approved by the user. Wind, water, reflections, petals and mist are shaders and particles,
  for show only. See `docs/progress/P1c-plan.md`.
  **Buildings (P1d, 2026-11-12):** walls show a lit front face where the floor lies south of them and a flat top
  elsewhere (`WallRelief`), pillars stand taller than their cells and roofs have a ridge (`Scenery`), all painted
  by `tools/art/make_relief.gd` and drawn over the map at load. The Height layer is untouched: no map is re-baked
  for looks. See `docs/progress/P1d-plan.md`.
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
# ...or only some shots, by number
godot --path . -s res://tools/capture.gd -- <output_dir> 1 30 71
# Start partway through to try one part by hand (scenarios in the script: kitchen, home, village, warden, crypt, shade,
# ending). An hour after the name starts at that time of day, and energy=<n> with that much energy.
# Saving in a scenario goes to its own slot (900), emptied at each start, never the player's game.
godot --path . -s res://tools/playtest.gd -- warden
godot --path . -s res://tools/playtest.gd -- village 19:30 energy=12
# The whole game for a playtest: from the title, on its own save slot (901, kept between runs; "fresh" empties
# it), with a log of what happens in user://playtests
godot --path . -s res://tools/playtest.gd -- full
# Repaint the hero's sprite sheet after editing its ASCII art (optional 8x preview), then re-import
godot --headless --path . -s res://tools/art/make_player_sprite.gd -- <preview.png>
godot --headless --path . --import
# Repaint the other actors' sprites after editing tools/art/make_sprites.gd, then re-import
godot --headless --path . -s res://tools/art/make_sprites.gd
godot --headless --path . --import
# Repaint the tall trees after editing tools/art/make_scenery.gd (optional 4x preview), then re-import
godot --headless --path . -s res://tools/art/make_scenery.gd -- <preview.png>
godot --headless --path . --import
# Repaint the wall faces, the pillar and the roof ridges after editing tools/art/make_relief.gd, then re-import
godot --headless --path . -s res://tools/art/make_relief.gd -- <preview.png>
godot --headless --path . --import
# Re-bake both pixel fonts (the small face and the heading face) and the UI theme after editing
# tools/art/make_font.gd (optional previews of the glyphs: <preview>.png and <preview>_heading.png)
godot --headless --path . -s res://tools/art/make_font.gd -- <preview.png>
# Repaint the title screen's picture after editing tools/art/make_title.gd, then re-import
godot --headless --path . -s res://tools/art/make_title.gd
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

**Shader gotcha:** in a canvas shader `COLOR` already holds the texture's colour when `fragment()` starts. To
sample the texture again, pass the tint from `vertex()` in a varying; multiplying by `COLOR` squares the picture.

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
- Do not add swimming or climbing: the hero moves on foot (stairs, ledge hops, solid tiles), with a
  hold-to-sprint. Since P2c sprint costs **energy**, which the user asked for on 2026-11-12 in place of the
  old "no stamina" rule. Hearts are life in combat only: energy never costs hearts.
- Do not let art or animation change gameplay timing, hit detection or collisions, unless a step says so.
- Do not add areas beyond the hero's home and plot unless the user asks.
- Do not add a dependency/addon without noting why in `docs/DECISIONS.md`. Allowed now: gdUnit4.
- Do not write story, dialogue or quest content beyond what the current milestone needs.

## The pivot's rules in code (P2 on)
- **Time (P2a):** a day is 06:00 to 02:00 in 14 real minutes; the numbers are in `data/rules/time.json`, read by
  `DayClock` (`core/time/`, pure). `GameState` keeps `day` and `minute`. The clock runs in areas but not in
  dungeons, conversations or menus. Outdoors the ambient light is the hour's; lamps are lit from dusk to dawn.
  A test that needs daylight sets the hour itself (a new game starts at dawn). `P2` is built in five steps:
  see `docs/progress/P2-plan.md`.
- **Home and sleep (P2b):** the hero's home is the area `home` (the thatched cottage west of the weaver's; its
  inside is baked by `build_maps.gd` like the other houses). Sleeping is the `sleep` effect of the bed's
  conversation (`data/dialogue/bed.json`): `GameState.sleep()` starts the next day rested, and the area saves.
  At 02:00 the hero wakes by his bed. **Anything that ends a day saves the game and changes scene:** a test
  that does it points `SaveSystem.current_slot` at a slot of its own and replaces the area's `travel`.
- **Energy (P2c):** the numbers are in `data/rules/energy.json`, read by `EnergyRules` (`core/energy/`, pure).
  `GameState.energy` is spent by sprinting (while he runs), a swing and a shot; under 25 he is slower, under 10
  he can't sprint, and at zero he collapses and wakes at home with half a bar and a tenth of his coins gone.
  Staying up until 02:00 costs the same. A hero left at zero energy in an area collapses on its next frame.
- **Food and cooking (P2d):** food is an item of type `food` (its `stats` give `energy` and `hearts`); eating is
  `GameState.eat()`, from the item menu. A recipe is a file in `data/recipes/`; the hearth at home lists them
  all (`Cooking.dialogue()` builds its conversation), so **a new dish is data only**. Things to gather are
  `ForageSpot` nodes in an area's `Interactables`, back each morning; keep them clear of tree crowns.
