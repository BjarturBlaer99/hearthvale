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
story over days, 4b skills, 4c friendship and gifts, 4d side quests, recipes and the ending. **What is left is
P4's "done when", which is the user's: a whole game played from the title to the ending.** Nothing further is
planned: ask before building anything more.

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
# Start partway through to try one part by hand (scenarios in the script: late, gifts, bram, gate, rest, farm, market, kitchen, home, village,
# warden, crypt, shade, ending). An hour after the name starts at that time of day, energy=<n> with that much energy,
# and skills=<level> with every skill at that level.
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
- **The mouse: left click is `use_hand`, right click is `interact`.** A test hands a click (an
  `InputEventMouseButton`, pressed) straight to a node's `_unhandled_input()`, or calls
  `AreaController.use_hand()` / `interact()`. Every screen calls `MenuInput.let_clicks_through(self)` as it
  starts, or a Control would swallow the click; write a prompt with `MenuInput.prompt()`, never with a key's
  name.

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
- Do not add motion to the scenery (wind, drifting petals or mist, smoke, specks): only the water moves, at
  the user's request of 2026-11-13.
- Do not make the mouse a pointer, and keep its two buttons as the user set them on 2026-11-13, as in
  farming games: **left click uses what is in hand** (`AreaController.use_hand()`: the sword, or the tool or
  item on the item button) and answers in a conversation; **right click interacts** with people and things.
  Moving stays on the keys; Space and Q still do the sword and the item.
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
- **Hours and night (P2e):** who is where when is in `data/rules/hours.json`, read by `Hours` (`core/time/`,
  pure). A door keeps hours by naming its place (`AreaExit.hours`; the shop's is `&"shop"`): shut, its cell is
  solid and the area says the place's words. Villagers who stand outdoors are away from 20:00 to 06:00
  (`Villager.present`), so **a test that talks to one sets the hour itself.** Monsters met outdoors at night
  are set up from `NightRules.strengthen()` (`data/rules/night.json`), decided once as the area loads; never
  in dungeons, never bosses. Windows are lit with the lamps (`WindowGlow`), and outdoors at night the tune is
  `night`. All for show except the door, the villagers and the monsters' numbers.
- **Farming (P3a; `docs/progress/P3-plan.md` has P3's three steps):** the plot is `GameState.farm()`, a pure
  `Farm` (`core/farming/`) in the plot's own cells; the rules are `data/rules/farm.json`. Change it only
  through `GameState.till_soil()` and `water_soil()`, which tell whoever draws it (`EventBus.farm_changed`).
  It lies in Hearthvale as a `FarmPlot` node (cells 12..17, 18..20): ground to walk on, drawn over the map,
  **no map re-baked.** The hoe and the can are items of type `tool`; `ToolUse.decide()` (pure) says what a use
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
- **Friendship (P4c):** the numbers are in `data/rules/friendship.json`, read by `Friendship`
  (`core/friendship/`, pure); a villager is a file in `data/villagers/` naming their conversation, what they
  like and their words of thanks, so **a new villager to befriend is data only** (and a `Villager` node with
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

