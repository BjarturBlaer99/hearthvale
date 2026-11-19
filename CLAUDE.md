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
**P1, P2 and P3 are built** (P3 finished on 2026-11-13). **P4's four steps are built** (2026-11-14; the user approved its
proposal as written, `docs/progress/P4-plan.md`: ten decisions, four steps, each with its own list): 4a the
story over days, 4b skills, 4c friendship and gifts, 4d side quests, recipes and the ending. **P4's "done when" was met
on 2026-11-16: the user played a whole game from the title to the ending. The roadmap is finished.** Nothing
further is planned: ask before building anything more.
**Since P4 (the user's requests, 2026-11-15):** a bug hunt (five fixes), the mouse pointing in menus and the
item bar (`docs/progress/mouse-and-bar-plan.md`). **P4's "done when" was met on 2026-11-16** (the user played
the game to its ending), and a **fix round** followed the same day (`docs/progress/fix-round-plan.md`): safe
saving with a backup, saving on quit, a title that says when a save can't be read, rewards laid at his feet
when the pack is full, and a villager's own thanks for a gift to a full friendship. None of it is a roadmap
step.
**Willowmere (the user's request, 2026-11-17; `docs/progress/willowmere-plan.md`, approved as written):** one
new area, a marsh east of the village, and one new enemy, the Bogwisp, in three steps. **All three steps are
built (2026-11-17):** W1 the marsh by day, W2 the Bogwisp and the night, W3 Old Henrik, his favour and the
lanterns. The user played it by day and by night on 2026-11-17 ("feels right" both times); handing over the
embers and the lit lanterns have been played only by a script. Nothing further is planned: ask before building more. Build nothing beyond the plan's list.
**Mining and crafting (the user's request, 2026-11-17; `docs/progress/mining-crafting-plan.md`, approved as
written):** three phases, with a stop after each for the user to review. **Phase 1, mining, is built
(2026-11-17):** the Old Quarry (an entrance hall and nine floors), the Pickaxe, rocks and ore rolled anew
each day, the lift, the Mining skill. The user tried the hall and floor 1 the same day ("feels right"); no
person has been below floor 1. **Phase 2, crafting, is built (2026-11-17):** the workbench and its
thirteen recipes, the furnace, the storage chest, the lamp and the rug, wood, copper and iron tools, the
sprinkler, the Miner's Lantern. The user tried the workbench the same day ("feels right": six things
made, the furnace lit); the chest in use, a night of the furnace, and the better tools and the
sprinkler on the plot have been played only by the tests (`tools/playtest.gd -- craft`).
**Phase 3, balance, is built (2026-11-17):** Tilda buys ore, bars and crystals; Wenna and Shepherd
Edda each ask a favour at three marks; and a script played eight days by pressing real keys
(`tools/play_days.gd`), with a report of what each day cost and paid
(`docs/progress/mining-balance-report.md`). **The numbers were settled the same day** (the user:
"All three"): a third off what Tilda pays for ore, bars and crystals; a rock of ore is 1 point of
Mining and a plain rock none; two coal rocks a floor on floors 4 to 6. The eight days have not been
played again with them. The plan is finished.
**The Homestead (the user's request, 2026-11-17; `docs/progress/homestead-request.md`; the plan,
`docs/progress/homestead-plan.md`, approved as written on 2026-11-17):** a farm of the hero's own west
of the village, in five phases with a stop after each for the user to review: 1 the homestead and the
home's move, 2 placing things, 3 buildings, 4 animals, 5 balance. **Phase 1 is built (2026-11-19) and
the user approved it the same day** (shown the summary and the pictures: "Approve Phase 1"): the lane's
west end, the farm's map, the farmhouse as the hero's home, the old cottage locked, the field 12 by 6,
a pond, save version 6, the story's words, the overgrowth (145 things cleared for good, fibre) and the
farm's two tunes. Nobody has played it by hand: only the tests, and two days by `tools/play_days.gd`
at four times speed. **Phase 2 is built (2026-11-19) and the user approved it the same day** ("Approve
Phase 2", shown the summary and the pictures): build mode (B, on the homestead only), fifteen
placeables on a build bar of their own, the hand, the workbench's "Make" and "Place" tabs, and Tilda's
seven wares for the land. Nobody has played it by hand. **Phase 3 is built (2026-11-19) and the user
approved it the same day** ("Approve, fix looks first", shown the summary and the pictures): the
workbench's "Build" tab, kits and sites, the Well, the Silo and hay from the meadow, the Coop, the Barn
and the Shed with their rooms, the shed's chests and furnace, the two upgrades, and moving and pulling
down. The user asked for three looks to change before phase 4 (the Coop's roof, the Big Barn's roof,
the shed's bookshelves), and kept a silo with hay as one that can't be pulled down. Nobody has played
it by hand. **Phase 4 is built (2026-11-19) and the user approved it the same day** ("Approve, fix
looks first", shown the summary and the pictures): animals as data, the herd's mornings, fenced
pastures, Farmer Oda's stall, hens, sheep and cows in the world, and eggs, milk, wool, cloth, the
blanket and three dishes. The user kept a pasture as built (anything standing closes it, the meadow's
tall grass is grass) and asked for smaller badges over the animals, which were made the same day.
Nobody has played it by hand. Phase 5 is not built. The plan's
thirty numbered decisions are the approved ones: they are at the head of the plan ("What the user has
decided", which stands in for the `docs/HOMESTEAD-NOTES.md` the request names) and in
`docs/DECISIONS.md`. Each phase is built by a subagent with a fresh context; **CLAUDE.md is the
coordinator's to edit, not a phase's** (a phase says in its report what should change here). The rules
below describe the game as it stands, with phases 1 to 4 built: where the plan changes one for a later
phase (the count of quests), **the plan's approved decision is the rule for the phase that builds it,** and the words here
follow once that phase is reviewed (the plan's R17). Build nothing beyond the
plan's list, and nothing of a later phase early. Nothing beyond it is planned: ask before building more.

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
  in Hearthvale were approved by the user. Water and its reflections move; the rest of the scenery is still
  (below). For show only. See `docs/progress/P1c-plan.md`.
  **A still world (user's request, 2026-11-13):** the scenery doesn't move, except the water (its tile, its
  surface, its reflections). Grass, flowers, washing and trees stand still, fallen petals lie where they are,
  the mist doesn't drift, chimney smoke is one picture, and there are no specks in the air (`SwayLayer` and
  `Motes` are gone). Creatures, people, pickups and the flicker of fires were left as they were.
  **The marsh (Willowmere, 2026-11-17):** its tiles are two rows at the end of the atlas, painted by
  `make_tile_texture.gd` (ground, boardwalk, reeds, the ruined hut, cattails, a lantern post), and its
  willows are tall pictures from `make_scenery.gd`. A map names the ground its props stand on
  (`"prop_ground"`). New tiles go at the end of the atlas: an older tile never changes place.
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
# Start partway through to try one part by hand (scenarios in the script: late, gifts, bram, gate, rest, kitchen, farm, homestead, build, buildings, built, animals, market,
# home, village, marsh, quarry, deep, craft, warden, crypt, shade, ending; `build` is the farm with a stock of every placeable,
# `buildings` the coins, materials and skill for every plan, `built` every building standing, `animals` the farm with a coop
# and a barn west of the farmhouse, their pastures fenced, the silo with hay, four hens, two sheep and two cows). An hour after the name starts at that time of day, energy=<n> with that
# much energy, and skills=<level> with every skill at that level. `farm` starts on the homestead's road above the field; `homestead` arrives
# by the lane with all three pickaxes (`-- homestead 20:30` for its night tune).
# Saving in a scenario goes to its own slot (900), emptied at each start, never the player's game.
godot --path . -s res://tools/playtest.gd -- warden
godot --path . -s res://tools/playtest.gd -- village 19:30 energy=12
# The whole game for a playtest: from the title, on its own save slot (901, kept between runs; "fresh" empties
# it), with a log of what happens in user://playtests
godot --path . -s res://tools/playtest.gd -- full
# Eight days played by a script that presses real keys and mouse buttons, from the title's "New game"
# (about 35 minutes; needs a window). Its save is slot 956, emptied before and after. It writes days.json,
# play_log.txt and pictures to the folder. speed=4 is a quick trial of the script (days=2 speed=4 is the
# quickest); "deep" tries the dark floors alone. Since the Homestead it works the field's clear corner
# and does not clear land; the eight days have not been played at life's speed since the move.
godot --path . -s res://tools/play_days.gd -- <output_dir>
godot --path . -s res://tools/play_days.gd -- <output_dir> speed=4
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
- Headless, a texture's `get_image()` hands back the same picture every time, and
  `SpriteSheet.recoloured()` paints on it: the first villager made in a run colours the sheet for the rest.
  The whole suite runs `tests/gameplay` before `tests/world`, so it passes; a hand-picked run that loads a
  villager's area before `sprites_test.gd` fails its colour test. It is the run's order, not the code.
- gdUnit4's CLI is **fail-fast by default**: it stops at the first failing test, and "Executed test cases (n/n)"
  only counts what ran. Always pass `--continue` (`-c`) to see every failure.
- `StringName` sorts by internal pointer, not text. Compare as `String` when order matters.
- Headless, drive input with `Input.action_press()` / `action_release()` (sets action state directly);
  gdUnit4's `simulate_action_*` sends InputEvents, which headless mode drops.
- Area scene tests: load areas one at a time with `tests/support/area_steps.gd` (a loaded area writes
  `GameState.player` every frame) and let it replace `AreaController.travel`, so taking an exit stays in the test.
- **The mouse: left click is `use_hand`, right click is `interact`.** A test hands a click (an
  `InputEventMouseButton`, pressed) straight to a node's `_unhandled_input()`, or calls
  `AreaController.use_hand()` / `interact()`. Every screen calls `MenuInput.let_clicks_through(self)` as it
  starts, or a Control would swallow the click; write a prompt with `MenuInput.prompt()`, never with a key's
  name.
- **The pointer and the bar in tests:** point with an `InputEventMouseMotion` whose `position` is on a line of
  the menu's list (`label.get_global_transform_with_canvas() * Vector2(4, line_height * (line + 0.5))`), and
  click with an `InputEventMouseButton` at such a point; a list inside a container needs a frame first
  (`await await_idle_frame()`). Put a thing in hand with `AreaController.choose_slot()` / `step_hand()` or
  `GameState.equip()`, never through the Tab menu, which lists food. After the last bomb or seed
  `GameState.equipped` is empty.
- **News at the top of the screen joins, it doesn't replace** (`AreaHud.show_notice()`, `NoticeLines`): a
  quest's, a skill's, a friendship's and a recipe's news each take a line while earlier news is still up.
  In a test no time passes, so earlier news is still up: check `hud.notice_lines()` (the latest is the last
  line), not that `notice_text()` equals one line. A new game's first area says "New quest: A Place of Your
  Own" unless the test calls `Quests.refresh()` before loading it.

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
  **What the player sets down is not art:** a fence, a hedge, a bench, a lamp post or a sapling fills its
  cell because `GameState.homestead()` says it stands there (`PlacedThings` tells the terrain), and nothing
  else in the game changes for it. A gate, and everything that lies, never blocks.
- Do not add motion to the scenery (wind, drifting petals or mist, smoke, specks): only the water moves, at
  the user's request of 2026-11-13. **On the homestead the same holds:** a sapling changes its picture at
  dawn and never sways, a lamp post's light is steady, and no petals lie or drift round a planted cherry.
  The animals are creatures, like the village's chickens, and move.
- Do not make the mouse a pointer **in play**, and keep its two buttons as the user set them on 2026-11-13,
  as in farming games: **left click uses what is in hand** (`AreaController.use_hand()`: the lit slot of the
  item bar) and answers in a conversation; **right click interacts** with people and things. Moving stays on
  the keys; Space and Q still do the sword and the item. A bow with no arrows gives the left click back to
  the sword (`GameState.is_out_of_ammo()`), so running out is no dead end.
- **In build mode the mouse points at a cell** (approved with the Homestead's plan, D12). Build mode is a
  screen, as a menu is: B opens it (the action `build`; a pad's left stick), on the homestead only and only
  when he is free to act; anywhere else he is told "You can only build on your own land." The hero stands
  still and the clock with him (`is_in_menu()`, `is_building()`). The thing chosen shows as a ghost on the
  cell under the mouse (the movement keys move it a cell at a time, no further than the screen shows),
  green where it fits and red where it doesn't, with the reason in words. A left click sets it down (and
  the sword's key); a right click takes up what is there (and the item's key); the wheel and the keys 1 to
  9 choose on the build bar; Tab, Esc or B leave. **Nothing is ever set down with the mouse in play,** and
  where a click lands in play still doesn't matter.
- **In menus the mouse points** (the user's request, 2026-11-15): the line under it is highlighted and a
  click chooses that line; a click on no line chooses the highlighted one, as before. Every new menu or list
  does the same (`MenuInput.line_under()`, `MenuPointer`, and `MenuCursor.select()` / `take_click()`), takes
  the wheel as up and down (`MenuInput.is_up()` / `is_down()`), and leaves on Tab or Esc (`is_back()`).
- **What is in hand is chosen on the item bar** (the user's request, 2026-11-15), not in a menu: the wheel
  steps through it, the keys 1 to 9 choose a slot (`HandBar`, pure; `GameState.take_in_hand()`,
  `step_hand()`; `ItemBar` draws it). The Tab menu lists food only. `GameState.equipped` is always something
  he carries: the last bomb or seed empties the item button. Do not put food, or anything that isn't held in
  the hand, in the bar without asking. **What is set down in build mode is chosen on the build bar, never
  the item bar:** an item of type `placeable` is not in `Inventory.EQUIPPABLE_TYPES`. The build bar's first
  slot is the hand, which lifts a thing and sets it down elsewhere. The sprinkler is as it was: on the item
  bar, set on the plot.
- Do not let a full pack lose things: what can't be carried whole stays where it is and the hero is told
  (`GameState.has_room_for()`; a pickup, a forage spot and a chest each have `has_room()`). **A test that
  fills a stack and then takes more of it sees a refusal,** not a silent loss. What is *given* (the
  `give_item` effect: a reward, a present) goes through `GameState.give_item()`, never `add_item()`: what
  doesn't fit is laid at his feet as a `LeftItem` and kept in the flags (`LeftItems`).
- Do not write a save any way but `SaveSystem.save_game()` / `save_to_slot()`: it writes beside the old save,
  reads it back, and keeps the old one as a backup (`SaveFiles`). **Empty a slot with
  `SaveSystem.erase_slot()`,** which removes its three files; removing only `slot_path()` leaves a backup
  that the title would offer.
- Do not let the game leave without saving: "Quit to title" and a closing window go through
  `save_and_leave()` (an area, the ending screen). **A test that quits to the title has saved to
  `SaveSystem.current_slot`,** so it points that at a slot of its own, and sets `SaveSystem.leave_delay` to
  0 or the area leaves half a second later. A closing window saves only `get_tree().current_scene`: call
  `SaveSystem.close_requested()` with the area made the current scene to test it.
- Do not add areas beyond the homestead (`homestead`) and the insides of its buildings (`coop`, `barn`,
  `shed`) unless the user asks.
- Do not add a dependency/addon without noting why in `docs/DECISIONS.md`. Allowed now: gdUnit4.
- Do not write story, dialogue or quest content beyond what the current milestone needs.

## The pivot's rules in code (P2 on)
- **Time (P2a):** a day is 06:00 to 02:00 in 14 real minutes; the numbers are in `data/rules/time.json`, read by
  `DayClock` (`core/time/`, pure). `GameState` keeps `day` and `minute`. The clock runs in areas but not in
  dungeons, conversations or menus. Outdoors the ambient light is the hour's; lamps are lit from dusk to dawn.
  A test that needs daylight sets the hour itself (a new game starts at dawn). `P2` is built in five steps:
  see `docs/progress/P2-plan.md`.
- **Home and sleep (P2b; moved by the Homestead):** the hero's home is the area `home` ("Your farmhouse"),
  the inside of **the farmhouse on the homestead**. Until the Homestead it was the thatched cottage west of
  the weaver's; the room and every place in it are the same. Its `Doormat` leads to `homestead` /
  `farmhouse_door` (cell (28, 12), facing south); on the farm the door is `FarmhouseDoor` at (28, 11). The
  cottage in Hearthvale is empty: its door (`HomeDoor`, at (8, 14)) keeps the hours of a place that is
  never open (`old_cottage` in `data/rules/hours.json`), so its cell is solid and the area says "The
  cottage stands empty, and its door is locked." Its entry `home_door` is still in the village's scene and
  nothing leads to it. Sleeping is the `sleep` effect of the bed's conversation (`data/dialogue/bed.json`):
  `GameState.sleep()` starts the next day rested, and the area saves. At 02:00, and after a collapse, the
  hero wakes by his bed in the farmhouse. **Anything that ends a day saves the game and changes scene:** a
  test that does it points `SaveSystem.current_slot` at a slot of its own and replaces the area's `travel`.
  **A test that walks out of his door arrives on the homestead, not in the village:** it puts him on the
  door's cell first (`PlayerMotor.cell_of(home.entry_marker(&"door").position)`, which is (5, 7)) and walks
  down. **A test that lists the village's doors with hours finds two,** the shop's and the cottage's.
- **Energy (P2c):** the numbers are in `data/rules/energy.json`, read by `EnergyRules` (`core/energy/`, pure).
  `GameState.energy` is spent by sprinting (while he runs), a swing and a shot; under 25 he is slower, under 10
  he can't sprint, and at zero he collapses and wakes at home with half a bar and a tenth of his coins gone.
  Staying up until 02:00 costs the same. A hero left at zero energy in an area collapses on its next frame.
- **Food and cooking (P2d):** food is an item of type `food` (its `stats` give `energy` and `hearts`); eating is
  `GameState.eat()`, from the item menu. A recipe is a file in `data/recipes/`; the hearth at home lists them
  all (`Cooking.dialogue()` builds its conversation), so **a new dish is data only**. Things to gather are
  `ForageSpot` nodes in an area's `Interactables`, back each morning; keep them clear of tree crowns.
- **Hours and night (P2e):** who is where when is in `data/rules/hours.json`, read by `Hours` (`core/time/`,
  pure). A door keeps hours by naming its place (`AreaExit.hours`; the shop's is `&"shop"`): shut, its cell is
  solid and the area says the place's words. Villagers who stand outdoors are away from 20:00 to 06:00
  (`Villager.present`), so **a test that talks to one sets the hour itself.** Animals keep the villagers'
  hours (`Hours.villagers_out`): in their building from 20:00 to 06:00, and nobody walks them there. Monsters met outdoors at night
  are set up from `NightRules.strengthen()` (`data/rules/night.json`), decided once as the area loads; never
  in dungeons, never bosses. Windows are lit with the lamps (`WindowGlow`), and outdoors at night the tune is
  `night`, or the area's own `night_music` where it names one (only the homestead does: `homestead_night`;
  its day tune is `homestead`, which the farmhouse plays at every hour). All for show except the door, the
  villagers and the monsters' numbers.
- **Farming (P3a; `docs/progress/P3-plan.md` has P3's three steps):** the plot is `GameState.farm()`, a pure
  `Farm` (`core/farming/`) in the plot's own cells; the rules are `data/rules/farm.json`. Change it only
  through `GameState.till_soil()` and `water_soil()`, which tell whoever draws it (`EventBus.farm_changed`).
  It lies **on the homestead** as a `FarmPlot` node (cells 22..33, 17..22; the rules' plot is 12 by 6):
  ground to walk on, drawn over the map. **Hearthvale has no plot** (`village.plot` is null). The plot's
  own cells (0..5, 0..2), its north-west corner, are clear in every game and are where an older save's soil
  and crops are; the rest starts overgrown, and **a cell with something on it can't be tilled, watered or
  sown until it is cleared** ("Clear this first.", `ToolUse.CLEAR_FIRST`; `ToolUse.decide()` takes
  `blocked`). **A test that tills, plants or waters loads `homestead`, with the plot at `Vector2i(22, 17)`,
  works cells of the clear corner,** and fills the can at the pond (4..9, 21..24; from (3, 22) facing
  right). The first row is worked from the grass above it (`PLOT + Vector2i(x, -1)`, facing down). **A hero
  who walks across the clear corner stops at its edge:** weeds stand at (28, 17..19) and in row 20. The hoe
  and the can are items of type `tool`; `ToolUse.decide()` (pure) says what a use
  does and the area does it. The can's water is the item `water` (its `ammo`). **Save version 3.**
- **Crops (P3b):** a crop is a file in `data/crops/` (days, seed, what it gives, prices), read by `Crops`
  (pure); its seed is an item of type `seed` and its harvest an ordinary `food` item, so **a new crop is data
  and pictures, no logic.** `Farm` does the growing (a stage each watered morning, withered after two dry
  ones in a row, a ripe crop waits); go through `GameState.plant_crop()`, `harvest()` and `clear_crop()`.
  Seeds are planted from the item button, ripe crops picked with interact (the right click). Crop pictures
  are 16x16 and flat (`FarmPlot.CROP_FRAMES`): crops never block. The item menu scrolls past five lines.
- **The shop and meals (P3c):** a shop is a file in `data/shops/` (`Shop`, `core/shop/`, pure, says what is on
  its lists and why a deal can't be made); `GameState.buy()` and `sell()` make the deals; `ShopMenu` on the HUD
  is the counter. A conversation opens it with the effect `shop`, when its words are done. Seeds and crop
  prices come from `data/crops`, so **a new crop needs no change to the shop.** The meals are recipes and food
  items only. Long lists scroll through `MenuCursor.window_top()`: use it, don't grow a box.
  **There are two shops:** `tilda`, and `oda` (Farmer Oda's stall, opened from her conversation's "Have
  you any animals to sell?"). A ware may be an `animal` in place of an item (`{ "animal": "chicken",
  "price": 60 }`, `Shop.is_animal()`): it is refused without a building for it or with the building
  full, and bought, it is in its building.
- **The story over days (P4a; `docs/progress/P4-plan.md` has P4's four steps):** the main quest
  (`data/quests/a_place_of_your_own.json`) begins by itself (a quest's `auto_start`) and its journal is the
  new player's guide. Four flags gate the story (`StoryGates`, `core/story/`): `planted_first_crop` (set by
  `GameState.plant_crop()`), `keep_gate_open` (Elder Bram's promise), `keep_warden_beaten`, and `crypt_open`
  (set by the quest at the dawn after the Warden falls: the condition `days_since`, from
  `GameState.flag_days`). The keep's gate is `KeepChain` in the Old Wood, a `chained` `DungeonDoor`; the
  chapel's `CryptBars` open on `crypt_open`. A conversation's `openings` give it other places to begin (Bram
  welcomes a newcomer). **A test that walks into the keep, or wants Bram to speak of it, sets the flag
  itself** (`StoryGates.KEEP_GATE`, `StoryGates.FIRST_CROP`); one that listens for every sound or flag calls
  `Quests.refresh()` first, since the main quest begins with a chime. **Save version 4** (one change for all
  of P4: `flag_days`, `tally`, and `skills` and `friends`, which nothing changes until 4b and 4c); an older
  save loads past the gates.
- **Skills (P4b):** the numbers are in `data/rules/skills.json`, read by `Skills` (`core/skills/`, pure).
  `GameState.skill_points` holds the points; **go through `GameState.practise(skill, deed)`** (it says when a
  level rises: `EventBus.skill_rose`). **What work costs is `GameState.energy_cost(action)`, never
  `energy_rules().cost()`** (but for sprinting), and what food gives is `GameState.food_energy(item_id)`: a
  dish (anything a recipe makes) gives a better cook more. A skill changes energy only: never hearts, damage,
  speed or timing. Cooking is counted by the effect `practise`, which the hearth's conversation gives each
  dish. **A test that tills ten cells, or beats ten monsters, has raised a level:** work is cheaper after it.
  **Farming also rises by tending animals** (the deed `tend`: an egg, a fleece or a pail taken, through
  `GameState.pet_animal()`): a test that takes ten has raised a level.
- **Friendship (P4c):** the numbers are in `data/rules/friendship.json`, read by `Friendship`
  (`core/friendship/`, pure); a villager is a file in `data/villagers/` naming their conversation, what they
  like and their words of thanks (three lines: `liked`, `other`, and `full` for a gift to a friendship
  that is full already), so **a new villager to befriend is data only** (and a `Villager` node with
  that conversation). `GameState.friends` holds the points and the days of the last talk and gift: go through
  `greet()`, `give_gift()` and `add_friendship()`. The answer "I brought you something." is added by
  `AreaController.talk_to()` to a copy of the conversation: **never write it into a dialogue file.** It shows
  only when a gift can be given today and he carries food or an ingredient, so **a test that lists a
  villager's answers with food in the pack sees it.** The pause menu has six lines now (Friends).
- **What friendship opens (P4d):** it is in each villager's conversation, as `openings` on the condition
  `friendship` (a villager, so many marks): a present at four marks (the flag `present/<villager>`), and at
  two a favour (a quest) or a recipe. **A new favour, recipe or present is data only.** A recipe marked
  `"taught": true` is not known until the effect `teach_recipe` sets its flag (`recipe/<id>`); the hearth
  lists `GameState.known_recipes()`. Build a `ConditionEvaluator` with `ConditionEvaluator.for_state(state)`,
  or friendship conditions are never met. The quest log shows five quests at a time (`shown_lines()`; all of
  them are `all_lines()`). **A test that talks to a villager at two or four marks gets their favour, lesson
  or present first:** end it, or set the quest, the recipe's flag or the present's flag beforehand.
- **Willowmere (2026-11-17; `docs/progress/willowmere-plan.md`, TECH_DESIGN §26):** the area `willowmere`,
  east of the village by the planks on its east meadow. Water and reeds are solid; boardwalks are the
  paths. Its forage, foods, recipes, villager, favour and enemy are all data.
  - **An enemy's data may say three new things:** `"energy_drain"` (its touch takes energy as well as
    hearts: `Hit.energy`), `"appears": "night"` (it lies low by day, rises at 20:00 if the hero is there,
    fades when the night ends, and the night's rules don't strengthen it), and `"behaviour": "wisp"`.
  - **A Bogwisp has no body unless light reaches it** (`WispBrain.lit`, set each frame from
    `AreaController.holds_at()`): the Lantern the hero carries, at its own radius, and the marsh lanterns
    once they burn. **A test that hits a wisp gives the hero a lantern or sets the lanterns' flag, and
    calls `wisp.step()` once so the brain has been told**; its touch hurts either way.
  - **By day a test finds no wisps** (they are `lying_low`, with no brain): set the hour to night before
    loading the marsh, or set it and call `area._process()`.
  - **The marsh lanterns** light when the area's `lanterns_flag` is set (`marsh_lanterns_lit`, the reward
    of Henrik's favour) and burn from dusk to dawn.
  - **Old Henrik** is away after 20:00 like every villager out of doors, and wisps are there only after
    20:00: the embers are won by night and handed over by day.
  - **Do not make the mist drift or add specks to the marsh's air:** its mist thickens at night and stays
    where it lies; its fireflies are creatures, and wait for dusk (`Ambience.DUSK_FIREFLIES`).

- **The Old Quarry (2026-11-17; `docs/progress/mining-crafting-plan.md`, TECH_DESIGN §27):** the areas
  `quarry` (the entrance hall) and `quarry_1` to `quarry_9`, entered from the north-east corner of the
  North Fields. The numbers are in `data/rules/mine.json`, read by `MineRules` (`core/mining/`, pure).
  - **Underground** (`AreaController.underground`): shown and lit like a dungeon, but **the clock runs**,
    and a Bogwisp is out at every hour. The keep and the crypt are as they were.
  - **Rocks** are `Rock` nodes made from the map's `rock` markers. Which hold ore and which hides the
    ladder is `GameState.mine_roll()`: a shuffle from the save's own number, the day and the floor
    (`MineRolls`). **A test that wants a known roll sets `GameState.mine().number`** (a new game's is
    random). A broken rock stays broken until morning: go through `GameState.break_rock()`.
    **On the homestead a rock is broken for good:** it goes through `GameState.clear_debris(area, cell)`,
    which keeps its cell in `GameState.homestead()`, and no morning brings it back. Its kind is not
    rolled: it is `rock`, `boulder` or `great_boulder` of `data/rules/homestead.json` (read by
    `HomesteadRules`), by the marker it was baked from, so `GameState.mine().number` changes nothing
    there. A boulder wants the Copper Pickaxe (three blows, or two of the Iron) and a great boulder the
    Iron (three); a lesser pickaxe is told "It wants a better pickaxe." (`ToolUse.PICK_WEAK`) and spends
    nothing. A plain rock takes two blows of the plain pickaxe. Each leaves stone (1, 4, 8) lying as an
    `ItemDrop`, and is no practice at mining.
  - **Only the pickaxe breaks a rock,** from the item button or a left click facing it. **A test that
    breaks one equips the pickaxe, faces the rock, calls `use_item()`, and lets the blow finish** (forty
    frames of `player.motor.step(Vector2.ZERO, FRAME)`) before the next: two blows for stone, copper and
    coal, three for iron, gold and crystal.
  - **What a rock held lies in its cell** as an `ItemDrop`: he walks onto it. **A test that picks it up
    puts the hero there with `motor.place()` and then `sync_from_motor()`**, since what touches a pickup
    is his body, not the motor. A drop he has no room for stays lying, and he is told once.
  - **A test arrives on a floor with `GameState.go_to(area, MineRules.ARRIVAL)`** before loading it, and
    replaces the area's `travel`: the ladder, the lift and a fall all change scene.
  - **A fall on a floor ends in the hall** (`fall_area`), whole. Every ladder up leads to the hall. The
    lift is a conversation whose answers use the `travel` effect; its stops are the flags
    `quarry/lift/4` and `quarry/lift/7`, set on arriving.
  - **Mining** is the fourth skill. A rock of ore may leave one more: the roll is the area's
    `roll_extra_ore`, which **a test replaces** to choose it. The pause menu shows two skills to a line.
  - **A map can be a sketch** (`"sketch"` in `build_maps.gd`): the floors are. Their nodes (the ladder
    up, monsters, the heart piece) are in the scenes. Re-bake one floor with `build_maps.gd -- quarry_3`.
  - **Do not** let the sword or a bomb break a rock, put what a rock gives straight into the pack, make a
    ladder up lead one floor up, or stop the clock in the mine: each was decided with the plan.
  - **Save version 5** (the mine's number and today's broken rocks). The fixture
    `tests/fixtures/saves/v4_before_the_mine.json` was written by the game as it stood before the mine.

- **Crafting (2026-11-17; `docs/progress/mining-crafting-plan.md`, TECH_DESIGN §28):** made at home, in
  the farmhouse (and, once the shed stands, its furnishings in the shed).
  - **A crafting recipe is a file in `data/crafting/`** (cooking keeps `data/recipes/`): its `station`
    (`workbench` or `furnace`), its `tab` at the workbench (`make`, `place` or `build`; `make` if it names
    none), `order`, `needs` (coins are a need like any other: the item `coin`), `makes` (an item, which
    may be a placeable or a building's kit, `{"upgrade": building}`, or a `furnishing`) and an optional
    `unlock` (an item `found`, a `skill` and `level`, or a building `built`). `Crafting` (`core/crafting/`, pure) says what
    is known and why a thing can't be made; **go through `GameState.craft(recipe_id)`**, which returns
    "" or the reason. **A new recipe is data only.**
  - **What he has ever held is `GameState.found`:** `add_item()` marks it whenever a count goes up, so
    **a test that wants a recipe unknown must never have added the item it waits on,** even to take it
    away again. A skill recipe wants the level: `GameState.skill_points[Skills.MINING] = 10` is level 2.
  - **A furnishing is a flag and a `Furnishing` node with a fixed place** in a room's scene. In the
    farmhouse (`home.tscn`, flags `home/<id>`): the workbench (always there) at cell (9, 3), the
    furnace (6, 2), the chest (2, 2), the lamp (4, 2), the rug (2..3, 4), the wool blanket over the bed (1, 3; flag `home/blanket`, not solid). **A test that wants one sets
    `Crafting.furnished_flag(&"furnace")` or crafts it,** and stands at it with
    `Steps.stand_before(home, "Furnace")`. Do not move one, or anything that stood in that room: it is
    the old cottage's room, cell for cell. **A furnishing is never set down by hand:** what is set down
    by hand is a placeable, out of doors on the homestead. In the shed (`shed.tscn`, flags
    `shed/<piece>`): two chests (`chest_a`, `chest_b`) and a furnace, each at its own cell, made on the
    "Build" tab once the shed stands (`{"built": "shed"}`).
  - **The workbench's list** is `hud.craft_menu` (`AreaController.open_craft()`): `entries()`,
    `shown_lines()`, `greyed_lines()`, `need_lines()`, `confirm()`. Greyed lines are on a second label
    in the same place (`bright_lines()` is what the bright one shows). **It has three tabs:** "Make"
    (thirteen, and cloth and the wool blanket once wool and cloth are found), "Place" (nine, known from the first day) and "Build" (ten: five plans, two
    upgrades, the shed's two chests and furnace). `hud.craft_menu.tab` is the one
    showing (`Crafting.TAB_MAKE` each time it opens); `switch_tab()` and `show_tab(Crafting.TAB_PLACE)`
    turn it, and `entries()`, `shown_lines()` and `confirm()` are the showing tab's.
    **`GameState.known_crafts(Crafting.WORKBENCH)` gives every tab's recipes:** a test that counts the
    workbench's list asks for one tab (`Crafting.of_tab(..., Crafting.TAB_MAKE)`).
  - **The furnace** (`GameState.furnace()`, a pure `Furnace`) is lit today and ready from the next
    morning: **a test lights it, calls `GameState.start_next_day()`, and takes the bars out through its
    conversation** (`home.interact()`, then `hud.dialogue.confirm()`). One load, five bars at the most
    (`data/rules/crafting.json`). The bars are given: what doesn't fit is a `LeftItem` at his feet.
    **There are two once the shed has its own:** `GameState.furnace()` is the farmhouse's and
    `GameState.furnace(&"shed")` the shed's, each with one load.
  - **The chest** (`GameState.store()`, a pure `Store`) holds 24 stacks and several of one thing.
    **There are three once the shed has its two:** `GameState.store()`, `store(&"shed_a")` and
    `store(&"shed_b")`; `store_put()`, `store_take()` and `StoreMenu.open()` take the key. Move
    stacks with `GameState.store_put(item_id)` and `store_take(index)`; its lists are
    `hud.store_menu` (`AreaController.open_store()`). It never holds coins, keys, quest things, or what
    a tool holds.
  - **Wood:** branches and stumps are breakables with `"returns": "daily"`; a stump has `"hits": 3`.
    Cut, a flag `cut/<area>/<x>,<y>` keeps the day: **a test that wants it back sets the next day
    (`GameState.start_next_day()`) and loads the area again.** Grass and pots are back on every visit,
    as before. **The meadow's tall grass on the homestead** (`meadow_grass`, fourteen tufts) is
    `"returns": "daily"` and leaves a hay lying. **On the homestead what the sword clears is gone for good** (the breakables `weeds`,
    `bush`, `log` and `farm_stump`, whose data says `"returns": "never"`; their cells are kept in
    `GameState.homestead()`, not in flags). **A test that wants one back starts a new game.** A swing
    cuts everything in its arc, so **a test that counts blows uses one that stands alone:** weeds
    (36, 5), a bush (7, 17), a log (7, 4), a stump (24, 2), a rock (3, 4). Boulders: (14, 7), (5, 9),
    (7, 14). Great boulders: (11, 21), (13, 21).
  - **Tool tiers** are items of their own whose stats say `reach` (hoe, can) or `fewer_blows`
    (pickaxe). The cell he faces decides whether the stroke is made; energy and the pour are paid
    once. **A test that uses a tool twice lets the first use finish** (forty frames of
    `player.motor.step(Vector2.ZERO, FRAME)`).
  - **The sprinkler** is an item of type `sprinkler`, on the item bar (the user approved it with the
    plan). Go through `GameState.place_sprinkler()` and `take_sprinkler()` (the plot's own cell). It
    waters the tilled cells among the four beside it in `Farm.new_day()`, after the soil has dried:
    **set down today, a test sees wet soil only after `start_next_day()`.**
  - **Do not** bump the save's version for crafting's fields (`home`, `found`, a cell's `sprinkler`:
    each is read with a default), let a furnace hold two loads, let a chest take coins, keys,
    quest things or a kit, or put a furnishing anywhere but its own place: each was decided with the
    plan (the shed's furnace and chests with the Homestead's).

- **The balance pass (2026-11-17; `docs/progress/mining-crafting-plan.md` phase 3, TECH_DESIGN §21, §25, §29):**
  - **A shop's data may list what it buys besides crops** (`buys`: an item and what is paid for one).
    `Shop.offers()` lists the harvest first, then `buys` in its own order; `Shop.bought_things()` is the
    list as read. Tilda pays 2, 3 and 7 for copper, iron and gold ore, 10 for a crystal, and 8, 12 and
    25 for the bars (a bar is worth more than its three ore: a test holds that), and 8, 30, 40 and 100 for
    the egg, the milk, the wool and cloth; stone, wood and coal are not bought. **A new thing to buy is a line of data.**
  - **Tilda's answer reads "I have things to sell."** (not "crops"), and a test that sells ore opens
    her list with `open_shop(&"tilda", Shop.SELL)`: the lines are "Copper Ore x2: 3 coins each".
  - **There are eleven quests.** A test that lists them, counts the quest log's lines, or reads the
    ending's "of 11" carries that number.
  - **Wenna and Shepherd Edda ask a favour at three marks** ("Black for the Loom": 5 coal; "New
    Shears": 2 iron bars), after the recipe each teaches at two. **A test that talks to either at three
    marks gets her lesson first if the recipe isn't known, then her favour at the next talk:** set
    `recipe/berry_jam` or `recipe/shepherds_pie` (or call `GameState.learn_recipe()`), or the quest's
    stage, beforehand. Their rewards are `give_item`: a full pack finds them at his feet.
  - **`tools/play_days.gd` presses real keys** (`Input.parse_input_event`, then
    `Input.flush_buffered_events()`: an event is otherwise handed on only at the next picture). The area
    sets `Engine.time_scale` back to 1 after every hit's freeze, so a tool that runs the game faster
    says its speed again each step, and takes more steps a second (`Engine.physics_ticks_per_second`)
    rather than longer ones.
  - **Mining's points:** a rock of ore (coal too) is 1, a plain rock none: `rock` is not in the
    skill's `gains`. **A test that wants Mining to rise breaks rocks of ore,** or sets
    `GameState.skill_points[Skills.MINING]`. Twenty-five rocks of ore are level 3.
  - **Floors 4, 5 and 6 have 3 iron and 2 coal rocks each** (they had 4 coal until the tuning).
  - **Do not** change a price, a count or a skill's numbers for balance without the user's word.

- **The Homestead, phase 1 (2026-11-19; `docs/progress/homestead-plan.md`, TECH_DESIGN §30):** the area
  `homestead` ("Your farm", 40 by 30), west of the village by the lane's west end (`WestRoad` in the
  village at (0, 16..17), `EastRoad` on the farm at (39, 14..15); he arrives at (38, 14) on the farm and
  (1, 16) in the village). The farmhouse is (26..31, 8..11) with its door at (28, 11); the field is
  (22..33, 17..22); the pond is (4..9, 21..24). No villagers, monsters, critters or forage.
  - **`GameState.homestead()`** is a pure `Homestead` (`core/homestead/`): the cells cleared for good. Go
    through `GameState.clear_debris(area, cell)` and ask with `is_debris_cleared(area, cell)`: both
    answer "no" for any area but the land (`GameState.homestead_rules().is_land()`).
    `EventBus.homestead_changed` tells whoever draws it.
  - **Debris** is weeds, bushes, logs and stumps (breakables that never return) and rocks, boulders and
    great boulders (`Rock` nodes). 145 stand in a new game, 54 of them on the field.
    `AreaController.debris()` is what still stands and `debris_at(cell)` what stands in a cell; each
    fills its cell until cleared. **A test that clears one equips the sword or the right pickaxe, faces
    it, and lets each blow finish** (forty frames; for the sword call `player.sync_from_motor()` and
    `resolve_combat()` each frame, as `tests/world/debris_test.gd` does).
  - **Where each stands is a spawn marker baked from the map's sketch** (`"marks"` in `build_maps.gd`; a
    sketch may have a `"legend"` of its own). The land's markers are a row of their own at the end of
    the atlas (`GreyboxTiles.LAND_MARKER_KINDS`).
  - **Fibre** is the item `fibre`, a material that stacks to 50; nothing uses it until phase 3. A test
    that lists every item or every breakable carries it and the four new breakables.
  - **Save version 6** (the section `homestead`: `{"cleared": ["x,y", ...]}`). The fixture
    `tests/fixtures/saves/v5_in_the_old_cottage.json` was written by the game as it stood before the
    Homestead. A test that reads a save's version carries 6.
  - **Two more tunes:** `Audio.MUSIC` and the audio tool's `SONGS` both list `homestead` and
    `homestead_night`.
  - **The main quest's words are measured against the quest log's box**
    (`tests/world/story_days_test.gd`), not counted to 150 letters: a stage must end above the line of
    help and be no longer than 200.
  - **In a capture shot the hero hides anything in the cell north of him:** he is two cells tall.
    `tools/capture.gd`'s shots end at 191 (168 to 176 are phase 2's, 177 to 191 phase 3's); its title shot reads (only reads) the player's slot 1 for its
    "Continue" line.
  - **A subagent's scratch folder may hold an earlier subagent's files:** work in a subfolder of your
    own, and never run a script there you did not just write.
  - **Do not** let anything cleared come back, put debris on the field's clear corner, the road, the
    path or the row before the farmhouse, change a count, a blow or a drop of the overgrowth without the
    user's word, or add monsters, villagers or forage to the homestead: each was decided with the plan.

- **The Homestead, phase 2 (2026-11-19; `docs/progress/homestead-plan.md`, TECH_DESIGN §30): placing things.**
  - **A placeable is an item of type `placeable`** (fifteen). Its stats: `layer` (`lying`/`standing`),
    `fills` (paths and floors), `blocks` (a gate says false), `joins` (fence, gate), `light` (lamp post),
    `grows` (`mornings`, `tree`). `Placement` (`core/homestead/`, pure) reads them (`layer_of`, `blocks`,
    `joins`, `fills`, `light_of`, `mornings_of`, `is_grown`, `stage_of`, `frame_of`) and says whether one
    fits: `Placement.why_not(item, Placement.site(...))`, the plan's table in its order. **A new placeable
    is data and a frame of `placed.png`** (`PlacedArt.FRAMES`; its `icon` is its picture on the ground too).
  - **`GameState.homestead()` keeps two layers,** a cell to one of each: `lying_at(cell)`,
    `standing_at(cell)`, `age_at(cell)`, `placed(layer)`, `placed_count()`. **Go through
    `GameState.set_down(area, cell, item_id)`, `take_up(area, cell, layer)` and
    `move_placed(area, from, to, layer)`.** They refuse off his land and emit `EventBus.homestead_changed`,
    but **they don't ask whether the ground fits** (build mode asks `Placement` first): a test or tool that
    calls `set_down()` itself picks a cell that is open ground, and play never calls it but through build
    mode.
  - **In the area** (both null off the land): `farm.placed` (`PlacedThings`: `standing_node(cell)`,
    `standing_nodes()`, `has_tree(cell)`) and `farm.build` (`BuildMode`, `world/areas/build_mode.gd`). A
    standing thing is a `PlacedThing` in `Interactables` (`item_id`, `age`, `blocks()`, `joined()`,
    `is_lit()`, `glow_now()`, `is_grown()`); what blocks is `farm.terrain.is_occupied(cell)` at once. A
    grown sapling is `farm.scenery.by_cell[cell]`, stood by `Scenery.stand()` like the map's trees.
  - **A test builds like this:** `farm.open_build()`; choose with `farm.build.step(1)` until
    `farm.build.chosen` is the id (`BuildBar.HAND` for the hand; `choose_slot(0)` is the hand only while he
    carries eight kinds or fewer); `farm.build.point_at(cell)`, which is clamped to `view_cells()`;
    `farm.build.set_down()`; `farm.build.take_up()`. Ask `why_not()`, `fits()`, `words()`; on the HUD
    `hud.build_bar.shown_ids()`, `shown_counts()`, `lit_slot()`, `hud.build_words()`,
    `hud.build_refused()`. **After loading the farm or moving the hero, `await await_idle_frame()` before
    trusting the view.** A mouse event's `position` is
    `farm.build.get_global_transform_with_canvas() * GridBody.cell_center(cell)`, handed to
    `farm.build._unhandled_input()`.
  - **Open ground for tests:** east of the farmhouse, columns 32 to 37, rows 10 to 13, and (29..37,
    12..13). (35, 9) is a rock, (36, 9) and (36, 7) weeds, (36, 5) weeds that stand alone, (34, 8) an old
    tree; (31, 11) is the house's wall. With the hero at (30, 13) the view is rows 2 to 24.
  - **The mode opens on the first thing he carries** (else the hand), and remembers the choice; **the last
    of a thing set down leaves the hand chosen.** With the hand, `set_down()` lifts (`farm.build.lifted`)
    and the next `set_down()` moves it as it is (a sapling keeps its mornings, a tree stays a tree: the
    user approved this reading of D16 with the phase); `take_up()`, another choice or `close()` lets go. A
    right click on a grown tree gives back its sapling.
  - **The farmhouse's doorstep says "That is the road."** (it is the path's end); no cell of the land says
    "That is a doorstep." until a building stands.
  - **The meadow's fourteen tufts of tall grass** can't be built on while they stand; a tuft doesn't
    grow where something lies or stands or a building covers it (phase 3).
  - **A lamp post is lit from 18:30 to 06:30** (`DayClock.lamps_lit`): a new morning at 06:00 still finds
    it lit; set 07:00 for dark. Each lit lamp post is two of the area's engine lights.
  - **Saplings grow by `GameState.start_next_day()`** (and `sleep()`): oak 4 mornings, cherry 6.
  - **The save is still version 6:** `homestead` has `lying` and `standing` only when something is set
    down, so **a save with nothing set down still reads `{"cleared": [...]}`.**
  - **Tilda sells sixteen wares** (her four, seven for the land, five seeds): turnip seeds are her twelfth
    line (`move_cursor(11)`), and one of everything costs 153 coins. A test that lists every item carries
    the fifteen; `Audio.SFX` and the audio tool list `set_down` and `take_up`.
  - **`SpriteSheet.draw()` with `flip_h` draws a frame's width to the right in this engine** (measured by
    phase 2's subagent, not fixed: it is older than the Homestead and wants the user's word). `PlacedArt`
    mirrors in place itself; the creatures are as they were.
  - **Do not** put a placeable on the item bar, call `GameState.set_down()` from play, make a lamp post
    flicker or a sapling sway, bump the save's version for what is set down, or change a cost or price of
    the fifteen without the user's word.

- **The Homestead, phase 3 (2026-11-19; `docs/progress/homestead-plan.md`, TECH_DESIGN §30): buildings.**
  - **A building is a file in `data/buildings/`** (`docs/data/building.schema.json`): `size`, `door` (a
    cell of its bottom row), `room`, what it does (`fills_can`, `holds`, `keeps`), `animals` (phase 4's
    to read), its upgrade (`big`) and its `look` (blocks of the atlas's tiles). `Buildings`
    (`core/homestead/`, pure) reads it: cells, door, doorstep (the cell below the door, which must be
    free and stays free), `anchor_of` (the cell the ghost holds it by: its door), `why_not_at`, `refund`.
    **A new building is data and pictures.** The five: Well, Silo, Coop, Barn, Shed; the Big Coop and
    the Big Barn are upgrades.
  - **A plan is a "Build" recipe whose `makes` is a kit** (an item of type `kit`: never stacks, never in
    a chest, never on the item bar; the build bar shows it). One of each: a plan is refused while its kit
    is in the pack, its site is set down or its building stands ("You have one already."), and one short
    of something names what ("You are short of 40 Stone, 10 Wood and 80 Coins.").
  - **Go through `GameState.set_down_kit(area, origin, kit_id)`** (a site today; play calls it only
    through build mode), `move_building()`, `take_up_site()`, `why_not_demolish()` and `demolish()`;
    ask `building_covering(area, cell)`, `doorstep_of()`, `is_built(id)`. **A site stands as its building
    at the next `GameState.start_next_day()`** (any morning; an upgrade too), which says so in
    `GameState.morning_news` and the area says it with the sound `built`. **A test that wants a building
    standing sets its kit down and calls `start_next_day()`.**
  - **In the area** `PlacedBuildings` draws each building flat, as the farmhouse is, with a roof's ridge
    the hero walks behind, fills its cells (all but its door; a site all of them) and makes a
    `BuildingSpot` for what he faces. A standing Well fills the can; the Silo takes the hay he carries
    with a right click (`GameState.put_hay()`, 60 at most; what doesn't fit stays in the pack), and
    each morning an animal its pasture can't feed eats one.
  - **Rooms:** the Coop, the Barn and the Shed have rooms (`coop`, `barn`, `shed`, 11 by 9). The door's
    cell is an `AreaExit` into the room; its doormat leads to the homestead's entry `<id>_door`, on the
    doorstep wherever the building stands, moved with it. A site has neither. **A test that walks into
    a room** stands the building first, then loads the homestead (as `tests/world/rooms_test.gd` does).
  - **Moving** (build mode's hand): lifted from any of its cells, set down where it fits, at once and for
    nothing, with what it holds (hay, the shed's chests and furnace, its upgrade); its own cells are no
    hindrance to it. **Pulling down:** a right click asks, a second pulls it down, only if empty (no hay,
    nothing in the shed's chests or furnace, no animals); half of each material of the plan
    and its upgrade comes back, rounded down, through `give_item()`, and no coins. A site taken up gives
    its kit back whole.
  - **The save is still version 6:** `homestead` gains `buildings`, `hay`, `furnaces` and `chests`, each
    written only when there is something in it. The fixture `tests/fixtures/saves/v6_a_yard_on_the_farm.json`
    was written by the game at the end of phase 2.
  - **Pictures:** atlas rows 28 and 29 (`GreyboxTiles.BUILDING_KINDS`, `SILO_KINDS`), painted by
    `make_tile_texture.gd`; `tools/playtest.gd -- buildings` and `-- built`; capture shots 177 to 191.
  - **Do not** let a building stand the day its kit is set down, sell two of one building, build on a
    doorstep, give coins back for a building pulled down, pull down one that holds anything, or change a
    building's cost, size or unlock without the user's word: each was decided with the plan.

- **The Homestead, phase 4 (2026-11-19; `docs/progress/homestead-plan.md`, TECH_DESIGN §30): animals.**
  - **A kind of animal is a file in `data/animals/`** (`docs/data/animal.schema.json`): `lives_in`
    (`coop`; sheep and cows share the `barn`), `gives` (`egg`, `wool`, `milk`), `every` (1, 3, 2 mornings
    fed and petted), `grazes` (4, 6, 8 cells) and `sound` (`cluck`, `bleat`, `low`). `Herd`
    (`core/homestead/`, pure) reads it. **A new animal is data and pictures.**
  - **The herd** is `GameState.homestead().animals()`, in the order bought; `animal(index)` is
    `{ "kind", "petted", "progress", "ready", "hungry" }`, and an animal's place in the herd is its name
    (none is ever taken away). It lives in its kind's building wherever that stands (4, or 8 upgraded).
    Go through `GameState.buy()` of Oda's ware or `buy_animal(kind, price)`, `pet_animal(index)`,
    `animals_in(id)`. **A test that buys one stands its building first** (a site is no home).
  - **A morning** (`start_next_day()`): each animal in turn eats its grass from its building's pasture
    while there is enough, else one hay from `homestead().hay`, else is hungry today; fed, it is two
    halves of a morning nearer its product if petted the day before, one if not; a product waiting
    stops the next. **A test that wants a product sets the hay or fences a pasture, pets, and calls
    `start_next_day()`.**
  - **A pasture** is `GameState.pasture_of(id)` (`Pasture.reach` from the doorstep): anything standing
    stops it (a gate, a bench or a sapling as a fence does: the user kept this at the review), as do
    buildings, sites, debris and the map's solid cells; ground that reaches the road or a way out is no
    pasture; what lies on the grass and the field are crossed and not grazed; the meadow's tall grass is
    grass. `has_pasture(id)`; `pastures()` shares one pasture between doors that open on it. The land as
    it was is `GameState.land_map()`, read from the scene once a run.
  - **In the world:** `AreaController.animals` (`PlacedAnimals`, on the homestead and in the coop's and
    barn's rooms; null elsewhere) shows each `Animal` out in its pasture from 06:00 to 20:00 if its
    building has one, else in its room, on a random cell of its ground each time an area loads. An
    animal fills no cell and walks only among its own cells; build mode holds them still and refuses a
    cell one stands in ("Someone is standing there."). **A right click on the animal he faces
    (`animal_in_front()`) pets it and takes what it has ready**; a full pack leaves it waiting. What is
    ready shows over its head as a small bubble with the thing at half size, pointing down at it (the
    user asked for smaller badges); a hungry one shows three dots. **A test that pets one puts it with
    `animal.motion.position` in the cell he faces**, as `tests/world/animals_test.gd` does.
  - **The products:** the egg and the milk are food (6, 18), wool and cloth materials; the hearth's
    Fried Egg, Omelette and Custard are known from the start (ten dishes from the start, fourteen with
    the four taught); Tilda buys the four; cloth (2 wool) and the Wool Blanket (2 cloth, the furnishing
    `blanket`) are made at the workbench's "Make" tab.
  - **The save is still version 6:** `homestead` gains `"animals"`, written only when there is one. The
    fixture `tests/fixtures/saves/v6_buildings_before_animals.json` was written by the game at the end
    of phase 3.
  - **Pictures and tools:** `animals.png` (the sheep and the cow; the hen is `critters.png`'s chicken),
    seven icons, the blanket in `crafted.png`; Oda's stall is the market stall's tiles, re-baked in the
    village at (16..18, 30..31); `tools/playtest.gd -- animals`; capture shots 192 to 203.
  - **Do not** let an animal die, run off, block anyone or use a door, sell one back, give a product the
    pack has no room for, or change a price, a pace or a pasture's grass without the user's word: each
    was decided with the plan.
