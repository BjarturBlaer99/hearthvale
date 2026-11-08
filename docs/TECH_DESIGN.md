# Hearthvale — Technical Design

Engine: **Godot 4.x (latest stable), typed GDScript, 2D top-down.** Tests: **gdUnit4**. Target: desktop
(Windows/Linux/macOS), keyboard+mouse and gamepad. Rendering: 16×16 tiles, base resolution 480×270 scaled up
(integer scaling, `canvas_items` stretch, nearest filtering), GL Compatibility renderer.

## 1. Project layout
```
res://
  autoload/          # singletons (EventBus, GameState, DataRegistry, SaveSystem)
  core/              # pure logic, RefCounted, unit-tested (no Node dependencies)
    terrain/         # HeightGrid, TerrainQuery, MoveResult, GridBody (grid-checked movement)
    player/          # PlayerMotor + one script per state (states/)
    enemies/         # EnemyBrain + one subclass per behaviour (WardenBrain: the keep's boss), EnemyBrains, DropTable
    dungeons/        # RoomGrid (rooms for the camera), DungeonState (dungeon flags, door rules)
    puzzles/         # PuzzleRules (pushing blocks, pressing plates, multi-flag shutters)
    quests/          # ConditionEvaluator, EffectApplier, later QuestRunner
    combat/          # CombatRules (hit geometry, knockback, weapon choice), Hit
    inventory/       # Inventory (stack limits, the item button, ammo)
    dialogue/        # DialogueRunner
    menus/           # MenuCursor (a menu's options and cursor)
    settings/        # SettingsData (the player's settings and their rules)
  gameplay/          # Node scripts: player, enemies, weapons, interactables, puzzle pieces
  world/
    areas/<id>/      # one scene per area: <id>.tscn (village, houses, countryside, dungeon rooms)
    tiles/           # greybox TileSet and atlas
  ui/                # HUD, text box, item and pause menus, settings menu, title screen
  data/              # JSON content (see docs/data for schemas + examples)
  tests/             # gdUnit4 tests, mirroring the code
  tools/             # dev-only scripts (greybox generation, captures, input map); not game code
  addons/gdUnit4/
```

## 2. Autoloads
| Name | Responsibility |
|---|---|
| `EventBus` | Global signals only, no state: `health_changed`, `item_added`, `flag_set`, `quest_updated`, … |
| `DataRegistry` | Loads and validates all JSON in `res://data` at startup (directory = kind of content); read-only lookups by id. Fails loudly on invalid data. |
| `GameState` | Owns all persistent state: hearts and health, flags, quests, inventory, where the hero is. `to_dict()` / `from_dict()`. Mutates only through methods that emit `EventBus` signals. |
| `SaveSystem` | Writes `GameState.to_dict()` as JSON to `user://saves/slot_<n>.json` with a `version`; loads and migrates. The menus use one slot (`current_slot`, `save_game()`, `load_game()`, `summary()`). |
| `Settings` | The player's settings (`SettingsData`), apart from any save: loaded from `user://settings.cfg` at start, applied to the window, saved on every change, announced by `EventBus.settings_changed`. |

## 3. Terrain & areas
- Each area scene has a `TileMapLayer` named **`Height`** whose tiles carry custom data **`height`** (0–7),
  **`ramp`** (stairs) and **`solid`**. `HeightGridBuilder` reads it into a pure `HeightGrid` at load.
- **Movement rules** (`TerrainQuery.check_move`, pure, tested): solid cells and the map edge are blocked; same
  height, or ±1 where either cell is stairs, is a **walk**; lower is a **drop** (a ledge hop, any height, one way,
  never hurts); higher without stairs is **blocked**. Everything that walks (hero, enemies) uses it.
- Movement is **grid-checked, not physics**: a `GridBody` (the hero's `PlayerMotor`, every enemy's body) asks
  `check_move` before the leading edge enters a new cell, stops short of blocked cells and slides along walls.
  - The hero may hop down ledges; enemies may not (`allow_drops`), so they keep to their level.
  - Flying bodies use `check_flight`: only solid cells and the map edge block them.
  - Cells occupied by villagers and the dummy block walkers.
  - Sealed cells (closed doors) block everything: walkers, fliers and arrows.
- `HeightShading` draws from the grid: earthy cliff faces with a dark lip below drops, soft shadows below
  solid things, and thin edges beside lower neighbours.
- **Tiles** are pixel art painted in code by `tools/greybox/make_tile_texture.gd`; `GreyboxTiles` has the atlas
  layout. `build_maps.gd` lays out each area's `Height` layer and adds some details by itself:
  - roof ridges and eaves, and windows in walls
  - trees, rocks, fences and the well become solid ground at the right height, with their picture on top

  A **`Decor` layer** above `Height` holds those props, plus decorations: placed flower beds, lily pads and
  crops, and a deterministic scatter of tufts, flowers, pebbles and mushrooms over open ground (never on what
  the hero uses or arrives at). Movement never reads the Decor layer.
- **Areas** live at `world/areas/<id>/<id>.tscn` (`WorldPaths`): the village, house interiors, the shop, the
  South Field and its Ruin Cellar and Cistern, and on the road north the North Fields, the Old Wood and the Old Keep. An
  `AreaController` builds the grid, places the hero, drives the HUD, and handles interact: pick up the
  `ItemPickup` underfoot, else talk to the `Talkable` in the cell the hero faces. `Interactables` children expose
  `covers(cell)`; Talkables also occupy their cell (`TerrainQuery.set_occupied`), and the area is y-sorted so
  whoever is lower on screen draws in front.
- **Area transitions:** an `AreaExit` (a door tile in a house wall, a doormat) names a target area and entry
  point. Stepping onto it calls `GameState.go_to(area, entry)` and changes scene through the area's `travel`
  callable (tests replace it). Each area's `Entries` holds a `Marker2D` per entry point, named by id, at a cell
  centre and rotated to the arrival facing; the arriving area places the hero there (else at the saved cell, else
  `PlayerSpawn`) and flashes the screen. A house's doormat leads to the entry just outside its own door.
- An area smaller than the screen (a house) is centred on it, on the dark clear colour.

## 4. Hero, items & combat
- `PlayerController` (CharacterBody2D) reads input, steps `PlayerMotor` and draws the sprite (`PlayerAnimator`:
  4-way facing, walk cycle by distance). The motor's state machine has one script per state:
  - `ground`: walks at `WALK_SPEED`, or `SPRINT_SPEED` while sprint is held (no stamina)
  - `attack`: stands still for the weapon's cooldown
  - `hurt`: pushed along the hit at `KNOCKBACK_SPEED` through the terrain rules
  - `dead`: lies still

  After a hit the hero is invincible for `INVINCIBLE_TIME` (1 s) and the sprite blinks.
- **Health:** hearts in `GameState` as **half-heart units** (`health`, `hearts_max`); `damage()`, `heal()`,
  `add_heart_container()` emit `health_changed`. The HUD's `HeartsBar` draws full, half and empty hearts.
- **Combat:**
  - `HurtBox` and `HitBox` (`gameplay/combat/`) are circles around a node, each on a team (`hero` or `enemy`).
    A HitBox can be an arc instead (the sword).
  - Every physics frame, `AreaController.resolve_combat()` lets each active HitBox hit the other team's HurtBoxes
    it touches. A `Hit` carries damage, a push and the source. Contacts are checked in code with `CombatRules`
    (pure), not with physics Area2Ds, so they match the grid-checked movement and stay deterministic in tests.
  - The sword (`Sword`, a HitBox child of the hero) is a 120° arc with 20 px reach, and hits each target once per
    swing. Its damage, knockback and cooldown come from the strongest `weapon_melee` item held
    (`CombatRules.best_melee_weapon`). Hazards (brambles) are HitBoxes on the enemy team.
  - The hero's HurtBox takes hits through the motor (knockback and invincibility), then `GameState.damage()`.
  - At zero hearts the area waits `RESPAWN_DELAY`, then puts the hero back at its **entrance** (where they
    arrived) with full hearts.
  - Recovery hearts (`HeartPickup`) heal on touch and come back on the next visit.
  - A `HeartContainer` appears once its flag is set (its boss beaten). Touching it adds a heart and fills them
    all, once and for good (`taken_flag`).
  - **Heart pieces:** `GameState.heart_pieces` (0–3, saved) and `add_heart_piece()`. Every fourth piece becomes a
    heart container. A `HeartPiece` lies in the world, is taken by touch, and is gone for good.
- **Items:** the inventory lives in GameState. `Inventory` (pure) sets the rules:
  - stack capacity (`max_stack`, or 1), so `GameState.add_item` adds only what fits
  - which items go on the item button (`weapon_ranged`, `bomb`)
  - what each item uses up (a bow's `ammo`; bombs themselves)

  `GameState.equipped` is the item on the button. It's saved, and the first equippable item picked up is
  equipped. The area's `use_item()` (Q / K / Y):
  - The bow stands the hero still for its cooldown and shoots a hero-team `Arrow`.
  - Bombs set down a `Bomb`: a fuse, then a blast HitBox that hits each enemy once and spares the hero.

  `ItemMenu` (Tab / I / Back) lists the equippable items held, in pickup order, and equips the chosen one.

## 5. Enemies
- **Data:** `data/enemies/<id>.json`, one per file (`docs/data/enemy.schema.json`), validated by DataRegistry:
  - health, speed, sight, contact damage and knockback
  - a behaviour id; archers also have a `shot`
  - a weighted `drops` table of `heart`, `item` and `nothing`
- **Brains** (`core/enemies/`, pure):
  - `EnemyBrain` is a state machine (idle, wander, chase, attack, hurt, dead) moving a `GridBody`, with one
    subclass per behaviour id. `EnemyBrains.create()` picks it:
    - `hopper` (slime): hops, lunges when close
    - `archer` (goblin): keeps its distance, lines up, draws (the tell), shoots
    - `flier` (bat): rests, zigzags at the hero, swoops; flies over heights
    - `warden` (the Iron Warden, the keep's boss):
      - It guards: stomps after the hero, and every blow clinks off.
      - Then it gazes: stands still and opens its eye (the tell). Only a `weak_point` hit (arrows) during the gaze
        stuns it.
      - Only a stunned warden takes damage, with a flinch between blows. An unanswered gaze ends in a bolt.
      - At `rage_at` health it stomps faster and fires three bolts. Its timings are the data's `boss` object.
  - Wandering stays within `LEASH` of home; it notices the hero within `sight` and gives up beyond
    `sight × LOSE_FACTOR`.
  - A hit costs health, knocks it back and stuns it briefly (no further hits). At zero it dies. A brain is told
    the hit's kind, which only the warden cares about.
  - Random numbers come from the area's seeded `RandomNumberGenerator`.
- **Nodes:**
  - `Enemy` (`gameplay/enemies/`) follows its brain and draws a placeholder. It has a HurtBox (the sword hits it)
    and a contact HitBox (touching it hurts the hero).
  - Beaten, it rolls `DropTable` and leaves a `HeartPickup` or an `ItemDrop` (coins, collected by touch).
  - `Arrow` is a flying HitBox that stops at solid tiles. A boss's `bolt` is one drawn as a glowing orb.
  - A drop from an enemy on raised ground falls to the foot of the ledge, where the hero can reach it.
    Goblin archers can drop arrows.
  - `Boss` (an Enemy with a WardenBrain, drawn big):
    - It keeps to its `arena` (its room's floor) and starts over (full health, back home) when the hero leaves.
    - If the hero has no arrows when its eye opens, five arrows fall into a far corner of the room.
    - With `stays_beaten`, it never comes back once its `clear_flag` is set. The heart container and the way out
      wait on that flag.
  - The area sets enemies up on load. They're back on every visit, and nothing about them is saved (except
    that a boss stays beaten).

## 6. Dungeons & puzzles
- **Rooms:** a dungeon is one area (`dungeon_id` set on its AreaController) cut into equal rooms of `room_size`
  cells (`RoomGrid`, pure).
  - The camera shows the hero's room, centred when smaller than the screen.
  - A `RoomMask` shades everything outside it, so neighbouring rooms stay hidden.
  - Crossing into another room dims the screen briefly (`update_room`).
- **Dungeon state** is flags in GameState, named per dungeon by `DungeonState`, so leaving, coming back and
  saving never reset progress:
  - `dungeon/<id>/keys` (small keys held: keys belong to their dungeon) and `dungeon/<id>/big_key`
  - `dungeon/<id>/door/<door>` and `dungeon/<id>/chest/<chest>`
  - Outside dungeons the area's id stands in (`AreaController.flag_scope()`), so a cracked wall or a chest works
    in the countryside too. A cracked wall's `stone` colour can match a ruin.
- **Doors** (`DungeonDoor`): `open`, `locked`, `boss`, `shutter`.
  - E opens a locked door with a small key (spent), or the boss door with the big key (kept).
  - A shutter lifts when its `open_flag` is set. Enemies sharing a `clear_flag` set it when the last one falls.
    With `stays_open` it records itself open for good once lifted (`latch()`), so a solved puzzle stays solved.
  - A closed door fills its cells; the area re-checks doors whenever a flag changes. A door through a two-cell
    wall shows half in each room, so each half draws its own lock.
- **Chests** (`Chest`) stand in their cell. E opens one: keys go to the dungeon's count, anything else to the
  inventory.
- **Interaction:** E uses whatever in front of the hero has `use()` and `prompt()`, after pickups and people.
- **Puzzles** (`gameplay/puzzles/` nodes over `PuzzleRules`, pure):
  - **Push block:** stands in its cell. Holding straight against it for `PUSH_TIME` slides it one cell onto open
    floor at its level, never onto a room's border (doorways), and the slide is drawn. It goes back to where it
    started when the hero leaves its room (`reset_blocks`), and on the next visit.
  - **Pressure plate:** the hero or a block on it sets its flag, and stepping off clears it unless it `latches`.
  - **Crystal switch:** a sword, arrow or bomb hit sets (or toggles) its flag, with a short lockout; red when
    off, blue when on.
  - **Cracked wall:** a `DungeonDoor` kind opened for good only by a bomb's blast.
  - A `Hit` carries its kind (sword, arrow, bomb, contact) so pieces can tell them apart.
  - Shutters can wait on several flags (`open_flags`, any of them, or all with `needs_all`), so a room can have
    two solutions.

## 7. Quests & dialogue
- Quests are JSON (`docs/data/quest.example.json`): stages with objectives and transitions. Conditions and
  effects use the shared vocabulary (`docs/data/CONDITIONS_AND_EFFECTS.md`); `ConditionEvaluator` evaluates
  conditions against a GameState snapshot. New condition or effect *types* are the only reason to add code.
- Dialogue is a JSON node graph (`docs/data/dialogue.example.json`): nodes with speaker, text and options;
  options have conditions, effects and `next` (null ends); an optional `speakers` map gives display names.
- `DialogueRunner` (`core/dialogue/`, pure) plays one conversation against a game state (GameState, or a
  stand-in in tests): the current node's speaker and text, the options whose conditions are met, `choose(i)`
  (apply the option's effects, go to `next`) and `advance()` for a node with no options (a sign).
  `EffectApplier` (`core/quests/`) applies effects through GameState's methods.
- `Talkable` (`Villager`, `Signpost`) names a dialogue id. `DialogueBox` (in the HUD) shows the runner: name,
  text, and a cursor over the options (up/down, interact). The hero stands still while it's open.

## 8. Data
| Folder | Kind |
|---|---|
| `data/items/` | items (weapons, keys, currency, consumables) |
| `data/quests/` | one quest per file |
| `data/dialogue/` | one conversation per file |
| `data/enemies/` | one enemy type per file |

DataRegistry validates required fields and resolves every cross-reference at load.

## 9. Save format
```json
{ "version": 1, "hearts_max": 3, "health": 5, "heart_pieces": 0, "play_time": 754.25,
  "flags": {}, "quests": {}, "inventory": [{"id": "small_key", "count": 1}],
  "equipped": "bow", "player": {"area": "village", "cell": [23, 20]} }
```
While the hero is on the way into an area, `player` is `{"area": "elder_house", "entry": "door"}` instead of
a cell, until the area places them. Bump `version` on breaking changes and add a migration step in
`SaveSystem`.

## 10. Testing
Every class in `core/` has gdUnit4 tests. Areas get layout tests (reachability from the spawn with the real
movement rules) and scene tests through gdUnit4's scene runner. Data validation tests load every JSON file. Tests
run headless; see CLAUDE.md for the command and gotchas.

## 11. Performance budget (slice)
60 fps on integrated graphics. Area loads under 200 ms. No world streaming in the slice.

## 12. Menus, saving & settings
- **The title screen** (`ui/title_screen.tscn`) is the main scene. It offers:
  - **Continue**, which can be chosen only when there's a save, and names where and how long (`SaveSystem.summary()`)
  - **New game**, **Settings** and **Quit**

  Continue loads the save and opens the area it names, with the hero on the saved cell.
- **Menus** share a pure `MenuCursor`: options with ids, labels and whether they can be chosen. Moving wraps and
  skips the ones that can't. `MenuInput` names the keys:
  - the movement keys move the cursor
  - E, Enter or A picks
  - Esc, Start or Tab backs out
- **Pause:** the `pause` action (Esc / P / Start) makes the area open the HUD's `PauseMenu`, unless the hero is
  busy (talking, in the item menu, travelling, down).
  - The menu pauses the scene tree and runs anyway (`PROCESS_MODE_ALWAYS`), so enemies, arrows and the play clock
    stop.
  - It shows hearts, heart pieces, keys in a dungeon and the play time.
  - It offers Resume, Save (the menus' slot), Settings, and Quit to title. Anything not saved is lost on quitting,
    and the menu says so.
- **Play time:** `GameState.play_time` counts in the area's `_process`, which a paused tree skips. It's saved.
- **Settings** (`SettingsMenu` over the `Settings` autoload):
  - fullscreen
  - window size (2x, 3x or 4x the 480x270 picture)
  - whether the HUD shows the controls hint

  Changes apply and are saved at once. There's no audio yet, so no volume.
- **The end of the slice:** the Warden's `HeartContainer` names a conversation (`dialogue_id`). The area opens it
  once the heart is taken, in place of the pickup message.
