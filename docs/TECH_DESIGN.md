# Hearthvale — Technical Design

Engine: **Godot 4.x (latest stable), typed GDScript, 2D top-down.** Tests: **gdUnit4**. Target: desktop
(Windows/Linux/macOS), keyboard+mouse and gamepad. Rendering: 16×16 tiles, base resolution 640×360 (P1a; it was 480×270) scaled up
(integer scaling, `canvas_items` stretch, nearest filtering), GL Compatibility renderer.

## 1. Project layout
```
res://
  autoload/          # singletons (EventBus, GameState, DataRegistry, SaveSystem)
  core/              # pure logic, RefCounted, unit-tested (no Node dependencies)
    terrain/         # HeightGrid, TerrainQuery, MoveResult, GridBody (grid-checked movement)
    player/          # PlayerMotor + one script per state (states/)
    enemies/         # EnemyBrain + one subclass per behaviour (the bosses: WardenBrain, ShadeBrain), EnemyBrains, DropTable
    dungeons/        # RoomGrid (rooms for the camera), DungeonState (dungeon flags, door rules)
    puzzles/         # PuzzleRules (pushing blocks, sinking them in pits, plates, torches, multi-flag shutters)
    light/           # LightRules (how much light reaches a point in a dark area)
    art/             # PixelGrade (the art tools' colour pass: warm colour, soft outlines)
    quests/          # ConditionEvaluator, EffectApplier, QuestRunner, QuestState
    combat/          # CombatRules (hit geometry, knockback, weapon choice), Hit
    inventory/       # Inventory (stack limits, the item button, ammo, a lantern's reach)
    dialogue/        # DialogueRunner
    menus/           # MenuCursor (a menu's options and cursor), EndingSummary (the ending screen's lines)
    audio/           # Synth (oscillators, noise, envelopes, a note sequencer, PCM16)
    ambient/         # CritterMotion (how chickens, butterflies and fireflies wander)
    settings/        # SettingsData (the player's settings and their rules)
  gameplay/          # Node scripts: player, enemies, weapons, interactables, puzzle pieces
    art/             # sprite strips painted by tools/art/ (PNG), SpriteSheet, ItemIcons
    ambient/         # Critter (chickens, butterflies, fireflies)
  world/
    areas/<id>/      # one scene per area: <id>.tscn (village, houses, countryside, dungeon rooms)
    tiles/           # greybox TileSet and atlas
  ui/                # HUD, text box, item and pause menus, settings menu, title screen, ending screen
  data/              # JSON content (see docs/data for schemas + examples)
  tests/             # gdUnit4 tests, mirroring the code
  audio/             # baked sound effects (sfx/) and music (music/): WAVs made by tools/audio/make_audio.gd
  tools/             # dev-only scripts (greybox generation, audio baking, captures, input map); not game code
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
| `Quests` | Runs every quest in `data/quests` (a `QuestRunner` over GameState) whenever a flag, an item or a quest's stage changes, and announces quest news (`EventBus.quest_announced`). Holds no state. |
| `Audio` | Plays sound effects (`EventBus.sound`) on a pool of players on the `SFX` bus, and loops music (`EventBus.music_requested`) on the `Music` bus; volumes from Settings. |

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
  - **Pits** (`TerrainQuery.set_pit`) are a drop for walkers, whatever the heights: the hero can step in, enemies
    (who never drop) keep out, and fliers and arrows cross. The area takes it from there (§6).
- `HeightShading` draws what square tiles can't show, once, at load:
  - from the grid: cliff faces with a dark lip below drops (earthy outdoors, cut stone in dungeons), soft shadows
    below solid things, and thin edges beside lower neighbours
  - from the Height layer (`find_ground_edges`, tested), **soft edges**: grass frays over the edge of a path
    where the two meet on the same level, and water gets a dark line under its bank and foam beside it. No
    transition tiles: any map gets them.
- **Tiles** are pixel art painted in code by `tools/greybox/make_tile_texture.gd`; `GreyboxTiles` has the atlas
  layout. `build_maps.gd` lays out each area's `Height` layer and adds some details by itself:
  - **house fronts** (`GreyboxTiles.HOUSE_KINDS`, all solid at height 3). A map gives a house as three blocks: a
    roof two rows deep (`roof` clay tiles, `roof_blue` slate or `roof_thatch`), a `wall_upper` row and a `wall`
    row. The baker picks each cell's tile:
    - a ridge on the roof's first row, eaves on its last, and a barge board at each gable end
    - beams and braces alternating along the half-timbered upper floor, with a window every third cell
    - windows in the ground floor, beside the door

    The chapel is built the same way from `chapel_window`, `chapel_wall` and a two-leaf `chapel_door_l`.
  - trees, rocks, fences and the well become solid ground at the right height, with their picture on top. A tree
    is one of three kinds picked by its cell (round, pine, oak), or a closed canopy where trees stand on all four
    sides of it (`GreyboxTiles.TREE_KINDS`).

  Chimneys, the chapel's cross and the shop's sign are overlays (`HOUSE_DECOR_KINDS`) that a map's `decor` blocks
  put on house tiles; `smoke` above a chimney is an animated tile (`SMOKE_FRAMES`).

  The chapel's two doors (`HOUSE_DOOR_KINDS`) are the exception among house fronts: open, and level with the rise,
  because they lead down to the crypt. A `pit` is a floor tile (walkable as far as the tiles go) that the area
  hands to `TerrainQuery`; the baker shows the far wall in the top row of each pit block.

  Raised dungeon floor is its own layered kind, `ledge` (flagstones at any height). Water is one animated tile
  (`WATER_FRAMES` frames). H12 added a second set of props:
  - outdoors: crate, keg, hay, logs, stump, lamp post, standing stone, washing-line post, and a 3x2 market stall
    (all on solid ground)
  - decorations: a well bucket and the washing line
  - furniture: chair, cupboard, loom, plant, candle stand, counter, stool, bookcase
- **Spawn markers:**
  - The baker paints a hidden **`Spawns` layer** from each map's `spawns` blocks: grass, pot, chicken, butterfly,
    firefly (`GreyboxTiles.MARKER_KINDS`).
  - On load, `AreaController.spawn_markers()` turns each marker into its node (`Breakable` or `Critter`) and clears
    the layer.
  - Interactables children with `set_terrain(terrain, rng)` get the area's terrain and random numbers.
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
- `PlayerController` (CharacterBody2D) reads input, steps `PlayerMotor` and draws the sprite. `PlayerAnimator`
  (pure, tested) picks the frame:
  - 4-way facing, and a four-frame walk cycle that advances by distance travelled (so it keeps pace with
    sprinting), with a one-pixel bob on each step
  - a blink every few seconds while standing, and a slow breath (the `BREATHE` frame for `BREATH_OUT` of every
    `BREATH_EVERY` seconds)
  - sprinting (`sprinting`): the leaning run frames, and a longer stride (`RUN_STRIDE`) so the feet keep pace
  - a swing by `attack_progress` (the motor's): wind-up until `WINDUP_UNTIL`, the lunge, settling from
    `SETTLE_FROM`. Pictures only: the sword's HitBox is live for the whole swing, as before
  - poses for a hit (`HURT`, a flinch) and for landing from a ledge hop (`LAND`, for `LAND_TIME`)
  - a pose that overrides both: lunging behind the sword, lying fallen at zero hearts, or holding an item
    overhead (always seen from the front)

  `hold_up(icon)` shows that last pose, with the item's picture above the hands, for `HOLD_TIME`. The area calls
  it when the hero picks up an item, opens a chest or takes a heart container. It's for show only: moving or
  swinging ends it at once.

  The motor's state machine has one script per state:
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
    heart container. A `HeartPiece` lies in the world, is taken by touch, and is gone for good. The HUD's
    `HeartsBar` shows the pieces as a gold heart filling a quarter at a time.
- **Items:** the inventory lives in GameState. `Inventory` (pure) sets the rules:
  - stack capacity (`max_stack`, or 1), so `GameState.add_item` adds only what fits
  - which items go on the item button (`weapon_ranged`, `bomb`)
  - what each item uses up (a bow's `ammo`; bombs themselves)

  `GameState.equipped` is the item on the button. It's saved, and the first equippable item picked up is
  equipped. The area's `use_item()` (Q / K / Y):
  - The bow stands the hero still for its cooldown and shoots a hero-team `Arrow`.
  - Bombs set down a `Bomb`: a fuse, then a blast HitBox that hits each enemy once and spares the hero.

  `ItemMenu` (Tab / I / Back) lists the equippable items held, in pickup order, and equips the chosen one.
- **The Lantern** (type `lantern`) is carried, not put on the item button. Its `radius` is how far the hero's
  light reaches in a dark area (`Inventory.light_radius`), and carrying one lets E light torches.
- **The sword's blade** takes the colour of the weapon's picture: wood for the Wooden Sword, steel for the Iron
  Sword (damage 3 to the wooden one's 2). The strongest sword held is the one swung.

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
    - `shade` (the Crypt Shade, the crypt's boss):
      - It haunts: drifts after the hero over pits and all, and every blow passes through it.
      - While its hall is lit (`set_lit`, which its node calls every frame) the light binds it for `bound_time`:
        it stands still, and only now do blows hurt, with a flinch between them.
      - When the binding ends it emits `snuffed` (its node puts the braziers out) and haunts again.
      - At `rage_at` health it drifts faster and throws a bolt every `bolt_every` seconds.
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
  - `ArenaBoss` (an Enemy; what the bosses share):
    - It keeps to its `arena` (its room's floor) and starts over (full health, back home) when the hero leaves.
    - Its fight has its own tune, and its shots are bolts.
    - With `stays_beaten`, it never comes back once its `clear_flag` is set. The heart container and the way on
      wait on that flag.
  - `Boss` (the Iron Warden: an ArenaBoss with a WardenBrain, drawn big). If the hero has no arrows when its eye
    opens, five arrows fall into a far corner of the room.
  - `ShadeBoss` (the Crypt Shade: an ArenaBoss with a ShadeBrain, drawn half there while it haunts):
    - Its braziers are the `Torch` nodes standing in its arena. All of them burning is what binds it.
    - It puts them out when its binding ends and when the fight starts over.
    - Bound, its touch does no harm, so the hero can close in.
  - The area sets enemies up on load. They're back on every visit, and nothing about them is saved (except
    that a boss stays beaten).

## 6. Dungeons & puzzles
- **Rooms:** a dungeon is one area (`dungeon_id` set on its AreaController) cut into equal rooms of `room_size`
  cells (`RoomGrid`, pure).
  - The camera shows the hero's room, centred when smaller than what the camera shows.
  - **The frame (P1a):** the picture is 640x360. `Ambience.ZOOM` gives the camera's size by kind of place: 1
    outdoors (40 by 22 cells in view), 2 in houses and dungeons, whose rooms are small (a 15 by 11 room then
    fills three quarters of the screen's width). Whole numbers only, so pixels stay square.
    `PlayerController.set_camera_zoom()` is set before the bounds; `camera_view()` is what the camera shows in
    area pixels, and the bounds are centred against that.
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
- **Grass and pots** (`Breakable`, data in `data/breakables/`, schema `docs/data/breakable.schema.json`):
  - They stand in their cell until a blow their data lets through (`breaks_on`: sword, arrow, bomb) cuts or breaks
    them.
  - Breaking plays the data's sound and throws up its burst (leaves, shards). It also frees the cell and rolls the
    data's weighted drop table (`DropTable`, as for enemies), leaving the drop in the cell.
  - Grass leaves stubble (its `broken` frame); a pot is gone.
  - They're back on every visit, not saved.
- **Puzzles** (`gameplay/puzzles/` nodes over `PuzzleRules`, pure):
  - **Push block:** stands in its cell. Holding straight against it for `PUSH_TIME` slides it one cell onto open
    floor at its level, never onto a room's border (doorways), and the slide is drawn. It goes back to where it
    started when the hero leaves its room (`reset_blocks`), and on the next visit.
  - **Pressure plate:** the hero or a block on it sets its flag, and stepping off clears it unless it `latches`.
  - **Crystal switch:** a sword, arrow or bomb hit sets (or toggles) its flag, with a short lockout; red when
    off, blue when on.
  - **Cracked wall:** a `DungeonDoor` kind opened for good only by a bomb's blast.
  - A `Hit` carries its kind (sword, arrow, bomb, contact) so pieces can tell them apart.
  - **Pits:**
    - A hero who steps into one (`AreaController.fall_into_pit`) loses half a heart, drops out of sight for
      `PIT_TIME`, and is put back on the last safe cell they stood on, with a moment's invincibility. On their
      last half heart they come back at the entrance like any other fall.
    - A push block pushed into a pit (`PuzzleRules.can_sink`) fills it: the pit is floor from then on and the
      block is part of it. With a `block_id` it stays sunk for good (`DungeonState.block_flag` holds the cell);
      without one it's lifted out when its room resets.
    - A drop from something beaten over a pit (a bat) lands on the floor beside it.
  - **Torch** (a standing brazier): E lights it if the hero carries a lantern. Burning, it sets its flag, so
    shutters wait on torches as they do on plates and crystals.
    - `always_lit`: burns from the start (the light of the crypt's first rooms).
    - `burn_time`: goes out by itself after that long, guttering first, and starts every visit unlit.
    - Otherwise it burns until snuffed, and its flag keeps it lit across visits.
- **The dark:** an area marked `dark` shows only what its lights reach.
  - `LightRules` (pure) works it out: each light is full to `CORE` of its radius and fades to nothing at its
    edge, and the brightest one counts.
  - The lights are the hero's own (a dim glow, or a lantern's `radius`) and every torch burning in the room on
    screen (`AreaController.lights()`): light doesn't pass a dungeon's walls.
  - `AreaLighting` draws it (P1b): the area's ambient colour is near black, and each of the rule's lights is a
    real light at the rule's place and radius, with a picture made from the rule's own falloff in four steps.
    Nothing else lights a dark area, so what is drawn lit is what the rule says is lit. `brightness_at(cell)`
    asks the same rule, for tests.
    - One difference from the rule: it takes the brightest light, while two overlapping pools add up a little
      where their half-lit edges cross. Never darker than the rule, and never lit where the rule says dark.
  - Shutters can wait on several flags (`open_flags`, any of them, or all with `needs_all`), so a room can have
    two solutions.

## 7. Quests & dialogue
- Quests are JSON (`docs/data/quest.example.json`): stages with objectives and transitions. Conditions and
  effects use the shared vocabulary (`docs/data/CONDITIONS_AND_EFFECTS.md`); `ConditionEvaluator` evaluates
  conditions against a GameState snapshot. New condition or effect *types* are the only reason to add code.
- **`QuestRunner`** (`core/quests/`, pure) runs the quests. A new quest is a new file in `data/quests/`, and
  nothing else.
  - A quest's stage is in `GameState.quests`. Two flags per quest (`QuestState`) record the rest:
    `quest/<id>/entered` is the stage whose `on_enter` effects were applied, and `quest/<id>/complete` is set by
    the `complete_quest` effect. The runner keeps nothing itself, so quests save with the game, and a load never
    repeats a reward.
  - `update()` applies the `on_enter` effects of any stage just reached, then moves each active quest on by the
    first of its stage's transitions whose condition is met. It repeats until nothing changes, with a cap in
    case quest data goes round in a loop.
  - Quests start when anything sets their stage: a dialogue option's `set_quest_stage` effect, or `start()`.
  - The `quest_status` condition (`not_started`, `active`, `complete`) lets a giver's conversation offer a quest
    only once.
  - The `Quests` autoload calls `update()` when EventBus reports a flag, item or stage change, and when an area
    loads. It announces "New quest", "Quest updated" and "Quest complete" with a sound. The area shows the
    announcement as a notice at the top of the screen, clear of the dialogue box.
  - DataRegistry rejects a quest no stage of which completes it.
- **The quests so far** (each a different shape):
  - The Lost Shuttle: fetch an item lying in the world.
  - Eggs for Tilda: carry an item from one villager to another, then report back.
  - Slimes in the South Field: a bounty. The slimes share a `clear_flag` that the quest waits on.
- **Quest items** are items of type `quest`. An item's `icon` names its picture (`ItemIcons`); without one, its
  type decides.
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
| `data/breakables/` | one breakable (grass, pot) per file |

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

  The title's picture follows the save: `summary()` also says whether the saved game was finished
  (`EndingSummary.is_finished`), and then the keep's window is dark.
- **Menus** share a pure `MenuCursor`: options with ids, labels and whether they can be chosen. Moving wraps and
  skips the ones that can't. `MenuInput` names the keys:
  - the movement keys move the cursor
  - E, Enter or A picks
  - Esc, Start or Tab backs out
  - a conversation is answered with E, Enter or A, but not Space: Space is also the attack key, and a swing as
    words open would skip them (`MenuInput.is_answer`)
- **Pause:** the `pause` action (Esc / P / Start) makes the area open the HUD's `PauseMenu`, unless the hero is
  busy (talking, in the item menu, travelling, down).
  - The menu pauses the scene tree and runs anyway (`PROCESS_MODE_ALWAYS`), so enemies, arrows and the play clock
    stop.
  - It shows hearts, heart pieces, keys in a dungeon and the play time.
  - It offers Resume, Save (the menus' slot), Quests, Settings, and Quit to title. Quests opens the
    `QuestLog`: started quests, active first, each with its journal line and objectives ticked when done. Anything not saved is lost on quitting,
    and the menu says so.
- **Play time:** `GameState.play_time` counts in the area's `_process`, which a paused tree skips. It's saved.
- **Settings** (`SettingsMenu` over the `Settings` autoload):
  - fullscreen
  - window size (2x, 3x or 4x the 640x360 picture)
  - whether the HUD shows the controls hint

  Changes apply and are saved at once. There's no audio yet, so no volume.
- **Closing words:** a `HeartContainer` can name a conversation (`dialogue_id`). The area opens it once the heart
  is taken, in place of the pickup message. The Warden's sends the hero to Elder Bram; the Shade's ends the game.
- **The ending** (`ui/ending_screen.tscn`):
  - The game's last conversation sets the flag `game_finished` (`EndingSummary.FINISHED_FLAG`) with an ordinary
    `set_flag` effect. When that conversation closes, the area leaves for the ending screen. The flag is saved,
    so the ending plays once.
  - The screen shows "The End" over the title's picture (the keep's window dark), then `EndingSummary`'s lines
    (pure): time played, hearts, and quests finished out of those in `data/quests`.
  - **Keep exploring** goes back to the area and cell the hero stood on. **Save and go to the title** saves first.
- **The story** is data only: conversations whose options are gated on the flags `keep_warden_beaten` and
  `crypt_shade_beaten`, and `Signpost` inscriptions in the keep, by the chapel and in the crypt. They are
  `stone`: drawn as a standing stone with carved lines, where a wayside sign is a wooden post.

## 13. Audio & feel
- **Made in code, baked to files** (no external assets):
  - `Synth` (`core/audio/`, pure) makes samples: square (with duty), triangle, sine, saw and noise; pitch sweeps;
    attack and release; mixing; a note sequencer; and PCM16.
  - Notes are written `C4:2` (a note and its length in eighth notes); `R` is a rest, and drum tracks use `K`, `S`
    and `H`.
  - `tools/audio/make_audio.gd` holds every effect's recipe and the four original songs, and bakes them to
    `audio/sfx/<id>.wav` and `audio/music/<id>.wav` (22050 Hz, mono, 16-bit). Edit sounds in the tool, never the
    WAVs, then re-import.
- **Playing:** the `Audio` autoload.
  - Effects: `EventBus.sound(id)` plays on one of eight voices on the `SFX` bus.
  - Music: `EventBus.music_requested(id)` loops on the `Music` bus (the same tune again carries on; empty stops).
    Each area names its `music`: village tunes for the village and its houses, countryside outdoors, dungeon
    underground. The title plays the village tune.
  - A `Boss` asks for its `fight_music` when it wakes, and gives the area's tune back when it resets or falls.
  - Headless it keeps track but plays nothing (no one hears it, and a sound playing at quit races the dummy mixer).
- **Who sounds:** the node where the action happens emits the sound.
  - The hero: sword, hurt.
  - Enemies: hit, enemy_die or boss_die, and their arrows.
  - Pickups: heart, coin, item_get, heart_get.
  - Doors: door, or nope when locked; secret when a cracked wall breaks; solved when a shutter lifts (the area
    hears doors change).
  - Puzzles: crystal, push, plate (once per press).
  - Bombs: bomb_set, bomb.
  - The Warden: stomp, gaze, clink, stun.
  - Menus: menu_move, menu_select, pause; nope when an item can't be used.
- **Feel:**
  - **Hit-stop:** `EventBus.hit_stop(seconds)` makes the area run `Engine.time_scale` at `HIT_STOP_SCALE` until that
    much real time passes. Leaving an area always ends it. It's 0.05 s for a landed blow, 0.08 s when the hero is
    hurt, 0.12 s for a stun, and 0.3 s for the Warden's fall.
  - **Screen shake:** `EventBus.shake(strength, seconds)` jitters the hero's camera offset, fading out. Used for
    bombs, the Warden's stomp and fall, and the hero being hurt.
  - **Bursts:** `Burst` (`gameplay/effects/`), small drawn particles that free themselves:
    - sparks where blows land
    - dust from blasts, pushed blocks and sprinting feet
    - sparkle from pickups and crystals
- **Volume:** `SettingsData` adds music and sound volume (0–10, default 7). `Audio` sets each bus (0 mutes).

## 14. Sprites
- **Every actor is pixel art painted in code**, like the hero. The art lives as ASCII in `tools/art/`:
  - `make_player_sprite.gd`: the hero, a blue hood and tunic with a gold hem and a red scarf. Three rows (down,
    up, side; right is the side row mirrored) of sixteen 16x24 frames. Nine are drawn: idle, blink, four walk
    frames, attack, item held up, fallen. Seven are made from those by `derived()`: breathe, windup and hurt
    (`sink()`: the body above the chest a pixel lower) and four run frames (`lean()`: the side view's upper body a
    pixel forward). A test checks `PlayerAnimator`'s columns against the tool's.
    Over the tunic he wears a leather vest, wrist guards, a belt pouch, slate trousers and tall boots; the sword's
    hilt shows over his shoulder (not in the attack frames, when it is in his hand), with a small pack behind.
  - `make_sprites.gd`: everything else, namely slime, bat, goblin archer, the Iron Warden, the Crypt Shade,
    villagers, items and pickups, the crystal switch, the torch, the training dummy and brambles

  Each sprite becomes `gameplay/art/<name>.png`. Its frames sit side by side in the order the tool lists them, and
  below them the same frames as white silhouettes for hit flashes. Edit the art in the tool, never the PNGs.
- **The colour pass** (art pass 3): all three art tools (the tiles, the hero, the other sprites) hand each picture
  to `PixelGrade.apply()` (`core/art/`, pure) just before saving it.
  - **Warm colour:** a touch more saturation (`SATURATION`, lowered in P1c for a softer picture), lights tinted
    towards yellow and shadows towards violet.
  - **Selective outlines** (P1c): an outline pixel that touches a clear pixel is on the edge of its shape and
    stays dark (`OUTLINE_VALUE`); one inside a shape is only a little darker than what it runs through
    (`INNER_VALUE`). A picture with no clear pixels, like a wall tile, has no edges: all its lines are soft.
  - **Soft outlines:** each pixel of the tools' outline colour takes a dark, rich shade of the colours beside it
    (never darker than a floor). With nothing coloured beside it, it's a plum-brown `INK`; inside a mass of
    outline colour (a doorway, a stairwell) it stays `DEEP` dark. In the tile atlas an outline looks no further
    than its own tile.
  - **Left alone:** the white flash rows, and the villagers' marker colours.
  - A colour painted exactly in the outline colour is treated as outline, so eyes have a colour of their own.
  - Things drawn at runtime match it: code-drawn outlines use `PixelGrade.INK`, and the grass fringe on paths
    uses `HeightShading.fringe_color()`, which warms the ground colour as the tiles are warmed.
- **Light and air** (art pass 4), all for show: none of it changes movement, combat or what can be seen.
  - `Ambience` (`world/areas/`) reads what kind of place an area is from its tiles: a dungeon (it has a
    `dungeon_id`), a house's inside (it has inner walls), else outdoors. It also finds the tiles that give light
    (lamp posts, hearths, candles).
  - **`AreaLighting`** (P1b, `world/areas/`), one per area, in place of the glow sprites and the sheets of dark:
    - **Ambient colour** by kind of place, through a `CanvasModulate`: clear outdoors, a warm dimness in a
      house, a cool one in a dungeon (`AMBIENT`), near black in a `dark` area (`DARK`). The HUD is on its own
      layer and isn't tinted.
    - **A pool of `PointLight2D` nodes**, filled every frame by `AreaController.scene_lights()`: the lights that
      reach the room on screen, widest first, at most `MAX_LIGHTS` (the engine lights one drawn thing with at
      most 16).
    - **Two kinds of light.** A `POOL` uses the engine's "mix" blend: it shows what it reaches in its own
      colours, so a white pool undoes the dimness exactly and two pools never glare. A `GLOW` uses "add": the
      warm bloom round a flame, and a lamp in daylight.
    - **Which lights** (`scene_lights()`): a glow for every tile that gives light, every burning torch, every
      crystal (in its colour) and the hero's lantern (`glows_now()`). Where the ambient colour is dim, also a
      pool round the hero (`Ambience.HERO_POOL`) and round each glow (`Ambience.REACH` times as wide).
    - Light pictures are made in code (`picture(core, steps)`) from `falloff()`, and kept.
    - `brightness_at()` and `lights()`, the rules play depends on, are untouched.
  - **Soft shadows** (P1b): `SoftShadow.draw(canvas, center, radii, strength)` (`gameplay/effects/`) draws the
    shadow under every actor, pickup and prop: a dark heart and a fainter rim, in violet. `SoftShadowNode` is the
    same as a node, for the hero's scene. `HeightShading` casts its shadows `CAST` pixels (six) in two steps:
    the whole shadow in `SHADE_FAR`, the nearer half again in `SHADE_NEAR`.
  - **Cast shadows:** `HeightShading.cast_on(grid, cell)` says whether a taller solid cell to the west (or
    north-west) shades an open cell; the sun stands in the north-west.
  - `Motes` (`gameplay/ambient/`): a few single-pixel specks pinned to the world, by kind of place.
- **Nature** (P1c), all for show; an area builds it in `_add_ambience()`:
  - **Tall trees** (`Scenery`, `world/areas/`): at load, every tree tile on the Decor layer but the closed
    canopy is taken off it and a `Sprite2D` stands in its cell, 32 by 40 pixels from `SceneryAtlas`
    (`world/tiles/scenery.png`, painted by `tools/art/make_scenery.gd`). `Scenery` is y-sorted, so trees sort by
    depth with the hero and everything in `Interactables`. A tree's foot is `Scenery.foot_of(cell)`.
    - The tree's cell is solid as it always was (the Height layer). The crown only overlaps the cells behind.
    - **Nothing is hidden:** `fade_for(points, delta)` fades the crowns that `hides()` any of
      `AreaController.standing_points()` (the hero, enemies, anything with `collect()`, item pickups). Grass,
      pots and signs don't count, or a tree behind them would stay faded.
    - Crowns sway: one shared shader shifts whole pixels, more the higher above the foot.
  - **Cherry trees:** a `"cherry"` block in `build_maps.gd` makes a solid cell with a `prop_cherry` tile, which
    `Scenery` stands up as `cherry` or `cherry_b` by cell. `Petals` (`gameplay/ambient/`) scatters settled petals
    round each (`scatter(foot)`, the same every time; only on cells `ground_at()` calls "open" or "water") and
    drifts a few from each crown (`CPUParticles2D`).
  - **Wind in small things** (`SwayLayer`): tufts, flowers, crops and washing move from Decor to a layer just
    above it whose shader leans each tile's top rows, each cell in its own time, never past the tile's edge.
  - **Water** (`WaterSurface`): one rectangle over the water's bounds, just above the Height layer, with a shader
    that reads a one-pixel-a-cell map of the water: a slow swell, glints, sparkles, and foam at the bank one to
    three pixels wide. `HeightShading` keeps only the dark line under the bank.
  - **Reflections** (`Reflections`): a mirror `Sprite2D` (flipped, hanging below the feet) for the hero and for
    each tree within three cells north of water, shown only on water cells by a shader with the same map.
  - **Mist** (`Mist`, `gameplay/ambient/`): two layers of noise in four flat steps, pinned to the world, for the
    areas in `Ambience.MISTY` (the Old Wood).
  - **A shader gotcha:** in a canvas shader `COLOR` already holds the texture's colour times the node's tint
    when `fragment()` starts. To sample the texture again, carry the tint from `vertex()` in a varying; don't
    multiply the new sample by `COLOR`, or the picture is squared and goes dark.
  - **Vignette:** `AreaHud` shades the screen's corners (a radial gradient, under the rest of the HUD).
- **Screen layout (P1a):** every box is anchored, never placed for one screen size: menus to the middle, the
  dialogue box to the bottom edge, the controls hint to the top right, lines of text across the top or bottom.
  - The HUD's corner is a `VBoxContainer` (`Panel/Box`): the hearts, the `EnergyBar`, then three lines.
    `AreaHud._fit_panel()` sizes the framed box to it, so it grows with a second row of hearts or with the bar.
  - `EnergyBar` (`ui/`) draws a leaf and a framed bar from `set_energy(current, maximum)`: green, amber under a
    half, red at a quarter (`LOW`). It is hidden until the energy rules exist (P2): `AreaHud.show_energy()`.
- **Lettering** (art pass 4): `tools/art/make_font.gd` paints a 95-glyph pixel font from ASCII art and bakes
  `ui/font/hearth_font.tres` (a bitmap `FontFile`, size 8, line height 11, scaled by whole numbers only) and
  `ui/theme.tres` (that font, and a one-pixel shadow under every label), and sets the project's theme.
  - Labels ask for size 8, or a whole multiple (the titles are 32). A bitmap font has no outline, so none is set.
  - `PanelFrame` (`ui/`) is the script on every box's `Panel`: a shadow under the box, an inner line and corner
    studs over the box's own colour.
- **Drawing:** `SpriteSheet.draw(canvas, texture, frame, size, origin, flip_h, white, tint)` draws one frame.
  - Origins are rounded so sprites stay on the pixel grid.
  - A negative width mirrors it (side views face left).
  - Scripts name frames in dictionaries (`Enemy.SLIME_FRAMES`, `Boss.FRAMES`, `ItemIcons.FRAMES`...), and a test
    checks they match the tool's order.
  - Shadows, glows, sparks, poofs, arrows and the sword's swing stay drawn in code: they're effects, not shapes.
- **Villagers** are painted in marker colours (magenta robe, cyan hair). `SpriteSheet.recoloured()` swaps them for
  each villager's `robe_color` and `hair_color`, once per look.
- **The Warden:**
  - frames for standing, stepping (mirrored for the other foot), gazing (the eye open) and stunned (slumped)
  - a red tint while raging
  - a glow over its eye while gazing

## 15. Ambient life
- `Critter` (`gameplay/ambient/`), spawned from markers. It never occupies a cell, never fights and is never saved.
  - **Chickens** walk: `CritterMotion.WALKER` over a `GridBody` by the terrain rules, so never into solid or
    occupied cells or off ledges. They rest, peck, and walk to a spot near home; a stuck walk ends.
  - **Butterflies** and **fireflies** fly: `CritterMotion.FLIER` drifts toward wandering points near home, over
    anything.
  - Chickens and butterflies are sprites (`gameplay/art/critters.png`); fireflies are glowing dots drawn in code.
- `CritterMotion` (`core/ambient/`) is pure and seeded by the area's random numbers.
