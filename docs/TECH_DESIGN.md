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
    time/            # DayClock (the day's rules: its length, the light by the hour, lamps, night)
    energy/          # EnergyRules (what things cost, tiredness, what collapsing costs)
    cooking/         # Cooking (recipes, and the hearth's list as a conversation)
    art/             # PixelGrade (the art tools' colour pass: warm colour, soft outlines)
    quests/          # ConditionEvaluator, EffectApplier, QuestRunner, QuestState
    combat/          # CombatRules (hit geometry, knockback, weapon choice), Hit
    inventory/       # Inventory (stack limits, the item button, ammo, a lantern's reach), Food (what food gives)
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
| `GameState` | Owns all persistent state: hearts and health, flags, quests, inventory, where the hero is, the day and the time of day, the hero's energy. `to_dict()` / `from_dict()`. Mutates only through methods that emit `EventBus` signals. |
| `SaveSystem` | Writes `GameState.to_dict()` as JSON to `user://saves/slot_<n>.json` with a `version`; loads and migrates. The menus use one slot (`current_slot`, `save_game()`, `load_game()`, `summary()`). A save is written beside the old one and the old one kept as a backup (§9); a closing window is routed here, so a game in play is saved first (§12). |
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
- **Tiles** are pixel art in `world/tiles/greybox_tiles.png` (painted in code until the art became PNG,
  2026-11-19; §14); `GreyboxTiles` has the atlas layout. `build_maps.gd` lays out each area's `Height` layer and adds some details by itself:
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
  put on house tiles; `smoke` above a chimney is a still tile: the first of the `SMOKE_FRAMES` painted (it was animated until
  2026-11-13).

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
  `PlayerSpawn`) and flashes the screen. A saved cell that is solid now (the map changed after the save) is
  nowhere to stand: he starts at `PlayerSpawn`. A house's doormat leads to the entry just outside its own door.
- An area smaller than the screen (a house) is centred on it, on the dark clear colour.

## 4. Hero, items & combat
- `PlayerController` (CharacterBody2D) reads input, steps `PlayerMotor` and draws the sprite. `PlayerAnimator`
  (pure, tested) picks the frame:
  - 4-way facing, and a six-frame walk cycle (legs passing, a step, the weight coming down, then the same on
    the other foot) that advances by distance travelled (so it keeps pace with sprinting), with a one-pixel dip
    as the weight comes onto each foot. A cycle covers 28 pixels, as it did with four frames
  - a blink every few seconds while standing, and a slow breath (the `BREATHE` frame for `BREATH_OUT` of every
    `BREATH_EVERY` seconds)
  - sprinting (`sprinting`): the leaning run frames, and a longer stride (`RUN_STRIDE`) so the feet keep pace
  - a swing by `attack_progress` (the motor's): wind-up until `WINDUP_UNTIL`, the slash, the follow-through
    from `FOLLOW_FROM`, each drawn for every facing. Pictures only: the sword's HitBox is live for the whole
    swing, as before, and is measured from his feet. `Sword.HAND` (his belt) is only where the blade is drawn from
  - poses for a hit (`HURT`, a flinch) and for landing from a ledge hop (`LAND`, for `LAND_TIME`)
  - a pose that overrides both: swinging the sword, lying fallen at zero hearts, or holding an item
    overhead (always seen from the front)
  - **He is two cells tall** (P1e): frames are 16x32 with the soles on the last row, drawn up from his feet,
    so he stands on the same spot and collides as he did

  `hold_up(icon)` shows that last pose, with the item's picture above the hands, for `HOLD_TIME`. The area calls
  it when the hero picks up an item, opens a chest or takes a heart container. It's for show only: moving or
  swinging ends it at once.
  **Work by hand** (tool polish, step 3): `reach()` shows the reach pose for `REACH_TIME` (a withered crop
  cleared, an animal petted with nothing to take, hay put in the silo); `hand_up(icon)` reaches, then holds
  `icon` up for `HAND_UP_TIME` (a crop picked, an egg, wool or milk taken). Both are for show only: they
  never stand him still, and moving or swinging ends them at once. A petted animal with nothing to give
  shows a `HeartPop` (a small heart that rises six pixels and fades in half a second, the one effect
  allowed to rise); hay put in the silo throws a little `chaff`.

  **Work** (tool polish, 2026-11-19): a stroke of a tool, a seed or the sprinkler is the motor's attack
  state as before (it stands him still for the tool's time), but the area tells the hero what it is
  (`PlayerController.work(item_id, kind)`), and he shows it in place of the sword's swing:
  - `ToolStroke` (`core/player/`, pure) says, by the motor's progress, which pose (the hoe and the
    pickaxe raised until `BLOW`, 0.35 of the stroke, then struck; the can tipped, or dipped to fill; a
    seed and the sprinkler reached down), and whether the tool is still in his hands (the sprinkler
    leaves them at the blow).
  - The animator's `WORK` pose shows one of four columns: raise, strike, pour, reach.
  - The tool is a `HeldTool` (a `Sprite2D` child of the hero, made in `_ready()`): a frame of
    `HeldTools.SHEET` (`gameplay/art/held_tools.png`), laid from his feet, mirrored with him in place,
    behind him when he faces up. Facing up, the blow and the can are hidden by him.
  - For show only: the work is done when the stroke begins, as it always was, and its length is the
    tool's. A swing, a shot or a hit ends the work pose. `ToolFlash` is left for a tool with no
    picture in his hands (none now).
  - **The blow** (step 2): the area starts a stroke with `motor.attack(..., ToolStroke.BLOW)`, and the
    motor emits `struck` once when the stroke is that far through, or as it ends early (a hit), so
    nothing waits for ever. What the stroke shows waits for it (`AreaController.at_the_blow()`):
    its sound, its bursts, the cell's new look (`FarmPlot.hold()` keeps a cell drawn as it was until
    `let_go()`), a rock's blow (`Rock.strike(fewer, false)`, then `show_blow()`), and what a rock
    leaves, hidden until then. The motor's time is untouched.

  The motor's state machine has one script per state:
  - `ground`: walks at `WALK_SPEED`, or `SPRINT_SPEED` while sprinting, times `speed_scale` (the controller
    sets both from the energy rules, §17)
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
  - The sword (`Sword`, a HitBox child of the hero) is a 120° arc with 28 px reach from his feet
    (`CombatRules.SWORD_REACH`; it was 20 until the user asked for a longer one on 2026-11-25), and hits each
    target once per swing. With a target's own radius (6 for a monster, a weed, a pot or a crystal) a swing takes
    in the next cell all round the front and the cell two straight ahead. **A blow never passes through a wall:**
    `Sword.touches()` also asks `CombatRules.clear_between()` (pure) whether any cell on the line from his feet
    to the target, leaving out the two ends, stops a blow (`TerrainQuery.stops_blow(cell, level)`: a solid cell,
    a closed door, off the map, or ground higher than his own; stairs, pits, lower ground and whatever merely
    stands in a cell don't). A line that only grazes a blocking cell's corner (within `GRAZE`, 3 px, of an edge
    with open ground across it) is let by, so a blow at something diagonally beside him is as it was; the seam
    between two walls lets nothing by. Higher ground stops it so the crystals on raised platforms in the keep and
    the cistern, placed for the bow, stay the bow's. The drawn blade is `SWORD_REACH * 0.65` long (13 px at 20,
    18 at 28) and a faint sweep at the reach round his feet shows the ground the swing covers. Its damage, knockback and cooldown come from the strongest `weapon_melee` item held
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
  - **nothing is lost to a full pack** (`Inventory.fits()`, `GameState.has_room_for()`): what can't be carried
    whole is left where it is and the hero is told. An `ItemPickup`, a `ForageSpot` and a `Chest` each have
    `has_room()` and refuse (the chest stays shut); a ripe crop, a dish and a shop's ware were so already. Only
    what is given in a conversation or by a quest, and what monsters drop, is still cut to what fits
  - which items go on the item button (`weapon_ranged`, `bomb`)
  - what each item uses up (a bow's `ammo`; bombs themselves)

  `GameState.equipped` is the item on the button. It's saved, and the first equippable item picked up is
  equipped. The area's `use_item()` (Q / K / Y):
  - The bow stands the hero still for its cooldown and shoots a hero-team `Arrow`.
  - Bombs set down a `Bomb`: a fuse, then a blast HitBox that hits each enemy once and spares the hero.

  What is on the button is chosen on **the item bar** (below, with the mouse). `GameState.equipped` is always
  something he carries: when the last bomb or seed goes, `add_item()` empties the button, and `from_dict()`
  does the same for an older save. Only his first thing for the button is put on it as it is picked up; with
  the sword in hand by choice, later ones wait in the bar.
  `ItemMenu` (Tab / I / Back) is the food menu: it lists the food he carries and eats the chosen one.
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
  - **A drop still lying when he leaves or the game saves** (2026-11-23) is kept:
    `AreaController.keep_what_lies()` turns every ItemDrop into the LeftItems flag of its cell, on
    every way out (an exit, the lift, a fall, the day's end, the ending) and before every save
    (`save_here()`, sleeping, the pause menu's Save through its `saving` signal).
- **Dungeon rules** (harder dungeons, 2026-11-23): `DungeonRules` (`core/enemies/`, pure) reads
  `data/rules/dungeon.json`, whose `places` name a dungeon's id (or an area's, for the quarry's floors)
  and what a monster there is multiplied by: `health` and `damage` (its touch and its arrows, both
  rounded up), `speed`, `sight`, `hearts` (the weight of its heart drops) and `shot_cooldown`. The area
  sets each enemy's `place` to its `flag_scope()` before setup, and `Enemy.setup()` takes the data
  through `strengthen(data, place)`. A place not named, a boss, and a monster only there by night are
  left as they are. Night is outdoors only, so the two rules never meet.

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
- **Doors** (`DungeonDoor`): `open`, `locked`, `boss`, `shutter`. Two more came later: `cracked` (a bomb opens
  it) and `chained` (P4a: a gate that opens on its `open_flag` like a shutter, says its `shut_words` when the
  hero tries it or walks up to it, and is drawn as planks under a chain and a padlock).
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
  - **A crystal that turns back** (harder dungeons, 2026-11-23): with a `hold_time` a hit makes it blue
    for that long (`PuzzleRules.crystal_holding`), blinking white in its last `WARNING_TIME`
    (`is_warning()`), then red with the snuff's sound; another hit gives it its whole time again. It
    starts every visit red. Shutters waiting on several need them blue at the same time.
  - **Plates in an order** (2026-11-23): a `PressurePlate` with an `order` (1 up) is one of the set
    sharing its `flag`. `PlateSequence` (`core/puzzles/`, pure) counts the steps: the next in turn moves
    it on (the plate stays down), one out of turn starts it over ("nope"; plate 1 counts as a new
    start), the last sets the flag for good. `PlateOrders` (`AreaController.plate_orders`) feeds it the
    plates stepped onto each frame, from `update_plates()`, and `update_room()` starts unsolved sets
    over. A set already solved shows every plate down. Nothing of the progress is saved.
  - **A shutter that opens when off** (2026-11-23): `opens_when_off` weighs its flags turned over
    (`PuzzleRules.weighed`): a flag anything but true counts as met. It never latches, whatever
    `stays_open` says. With a toggling crystal, one hit opens one way and shuts another.
  - **A shutter whose puzzle changed after games were saved** (2026-11-23) names `open_if_past`, a
    flag: with `stays_open`, a game in which it is set had it open and keeps it open (the cistern's
    plate room: its old plate's flag, `cistern_b_plate`, which the new plates never set).
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
    - **A block added after games were saved** (2026-11-23) names `sunk_if_past`, a flag, and
      `sinks_at`, a cell: a game with that flag set got past its pit before it stood there, and finds
      it sunk there (the crypt's `FloorBlockB`, past the Reliquary's door).
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
    A quest marked `"auto_start": true` starts by itself at the first `update()` of a game (P4a: the main
    quest; nobody gives it).
  - The `quest_status` condition (`not_started`, `active`, `complete`) lets a giver's conversation offer a quest
    only once.
  - The `Quests` autoload calls `update()` when EventBus reports a flag, item or stage change, when a day
    starts (a stage may wait for a dawn: the `days_since` condition) and when an area loads. With no game
    started it does nothing. It announces "New quest", "Quest updated" and "Quest complete" with a sound. The area shows the
    announcement as a notice at the top of the screen, clear of the dialogue box.
  - **News joins news** (`AreaHud.show_notice()`, `NoticeLines` in `core/menus/`, pure): a notice that comes
    while another is still up is shown on a line of its own under it, so a skill rising as a quest moves on
    are both read. News already showing isn't said twice, three lines show at most (the oldest gives way), and
    each new line gives all of it its full time again. `notice_lines()` has them a line each; `notice_text()`
    is the whole of it. The same holds for a skill's rise, a mark of friendship and a recipe learned.
  - DataRegistry rejects a quest no stage of which completes it.
- **The quests so far** (each a different shape):
  - A Place of Your Own: the main story, in six stages (section 22). It starts by itself.
  - The Lost Shuttle: fetch an item lying in the world.
  - Eggs for Tilda: carry an item from one villager to another, then report back.
  - Slimes in the South Field: a bounty. The slimes share a `clear_flag` that the quest waits on.
  - A Pie for Pip, Rations for the Watch, Seed Stock, The Elder's Supper (P4d): bring a thing to a villager
    who asked for it as a friend (section 25).
- **The quest log** shows five quests at a time (`QuestLog.ROWS`): a longer list scrolls with the cursor
  (`MenuCursor.window_top()`), and the corner says where in it he is.
- **Quest items** are items of type `quest`. An item's `icon` names its picture (`ItemIcons`); without one, its
  type decides.
- Dialogue is a JSON node graph (`docs/data/dialogue.example.json`): nodes with speaker, text and options;
  options have conditions, effects and `next` (null ends); an optional `speakers` map gives display names.
  An optional `openings` list gives other nodes to begin at, each with conditions: the first whose conditions
  are all met is used in place of `start` (P4a: Elder Bram greets a newcomer differently).
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
| `data/breakables/` | one breakable (grass, pot, fallen branch, old stump) per file |
| `data/recipes/` | one recipe per file: what a dish needs and what it makes |
| `data/crafting/` | one crafting recipe per file: where it is made (the workbench or the furnace), what it needs, what it makes, and when it is known (§28) |
| `data/crops/` | one crop per file: how long it takes, its seed, what it gives, its prices |
| `data/shops/` | one shop per file: its wares and prices, whether it sells seeds and buys crops |
| `data/rules/` | one set of rules per file: the numbers a system runs on (`time.json`: the day's clock; `energy.json`: the hero's energy; `hours.json`: who is where when; `night.json`: what the night does to monsters; `farm.json`: the hero's plot; `skills.json`, `friendship.json`, `mine.json`; `crafting.json`: the furnace's load, the chest's slots and the home's furnishings) |

DataRegistry validates required fields and resolves every cross-reference at load. A set of rules must be one
the game knows (`RULE_SETS`), and is checked by the class that reads it (`DayClock.problems()`,
`EnergyRules.problems()`, `Hours.problems()`, `NightRules.problems()`, `Farm.problems()`,
`Crafting.rules_problems()`). A tool item is checked by `ToolUse.problems()`, and a crafting recipe by
`Crafting.problems()`.

## 9. Save format
```json
{ "version": 4, "hearts_max": 3, "health": 5, "heart_pieces": 0, "play_time": 754.25,
  "day": 3, "minute": 870.5, "energy": 100.0,
  "flags": {"keep_warden_beaten": true}, "flag_days": {"keep_warden_beaten": 3},
  "quests": {}, "inventory": [{"id": "small_key", "count": 1}],
  "equipped": "bow", "player": {"area": "village", "cell": [23, 20]},
  "farm": {"cells": {"0,0": {"watered": false}, "4,2": {"watered": true}}},
  "skills": {}, "friends": {}, "tally": {"crops_picked": 7} }
```
While the hero is on the way into an area, `player` is `{"area": "elder_house", "entry": "door"}` instead of
a cell, until the area places them. Bump `version` on breaking changes and add a migration step in
`SaveSystem`.
- **A save is never written over the one before it** (the fix round of 2026-11-16; `SaveFiles`, pure, in
  `core/save/`, names the files and says whether a file's text is a save this game can load):
  - `slot_1.json.tmp` is written first and read back. Only a whole one is moved into the save's place
    (`slot_1.json`); the save that was there is copied to `slot_1.backup.json` beforehand.
  - A write that fails, or comes back different from what was written (`ERR_FILE_CORRUPT`), leaves the old
    save as it was and removes the temporary file. A file the system holds for a moment is tried five times.
  - If the backup can't be made the save still goes ahead, since the new save has been read back whole; the
    old save is then replaced only by a move that takes its place, never removed first.
  - `load_backup()` and `backup_summary()` read the backup; `erase_slot()` removes all three files (tests and
    the playtest tool use it, so a slot is truly empty).
  - A save made before this is one file with nothing beside it: it loads as it did, and becomes the first
    backup at the next save. The format is unchanged.
- **What a full pack couldn't take of something given** is kept in the flags (`LeftItems`, pure, in
  `core/inventory/`), so it needs no new field: `owed/<item>` counts what is given and not yet laid down, and
  `left/<area>/<x>,<y>/<item>` what lies in a cell. `GameState.give_item()` (the `give_item` effect) adds what
  fits and records the rest as owed; the area lays it where the hero stands (`EventBus.items_owed`, or as it
  loads) and stands a `LeftItem` there (an `ItemPickup` whose flag is a count). Picked up, the flag is erased
  (`GameState.erase_flag()`). An older build would load such a save and simply not show what lies there.
- **Version 2** (P2a) added `day` (1 is the first), `minute` (the time of day, in minutes since the midnight
  the day began on: 360 is 06:00) and `energy`. `SaveSystem._v1_to_v2()` gives a version 1 save the first day,
  the hour days start and a full bar; a finished game stays finished. Tests load two real version 1 saves
  (`tests/fixtures/saves/`).
- **Version 3** (P3a) added `farm`: the tilled cells of the plot, by the plot's own cell ("column,row" from
  its north-west corner), each with whether it is watered. A cell that isn't listed is bare. Loading leaves out
  anything that isn't a cell of the plot. `SaveSystem._v2_to_v3()` gives a version 2 save an untouched plot; a
  test loads a real version 2 save. The can's water is an item in the inventory, so nothing more is saved for
  it.
  - A cell with something planted in it also has `crop` (a crop id), `stage` (the mornings it has grown),
    `dry` (the dry mornings in a row) and `withered` (P3b). They are fields with defaults, so the format is
    still version 3 and a save from step 3a loads as it is. A crop the game doesn't know is left out as the
    save loads, and its soil kept.
- **Version 4** (P4a) is the one change of format for the whole of P4. It added:
  - `flag_days`: the day each flag came true (`GameState.set_flag` keeps it for a plain `true`, and forgets it
    when the flag is unset). A flag with no day counts as long ago.
  - `tally`: what the game has counted (`crops_picked`, by `GameState.harvest`).
  - `skills` (skill id to points) and `friends` (villager id to `points`, `talked`, `gift`): kept, saved and
    loaded, but nothing changes them until steps 4b and 4c.
  - `SaveSystem._v3_to_v4()` gives an older save all four empty, and puts it past the story's gates
    (`StoryGates.past_the_gates()`): the first crop counts as planted, the keep's gate is open, and the crypt's
    bars are up if the Warden had fallen. A test loads a real version 3 save made inside the keep.
- **Version 5** (mining and crafting, 2026-11-17) added `mine` (§27), and with crafting `home` (the
  furnace's load and the chest's stacks), `found` (what he has ever held) and a `sprinkler` in a cell of
  `farm` (§28). The three that came with crafting are read with defaults, so the version did not change
  again. `SaveSystem._v4_to_v5()` gives an older save a mine of its own, a cold furnace, an empty chest and
  nothing found; a test loads a real version 4 save.
- **Version 6** (the Homestead, 2026-11-18) added `homestead` (§30): `{ "cleared": ["x,y", ...] }`, the
  cells of the farm cleared for good. Later phases add fields to it, read with defaults.
  `SaveSystem._v5_to_v6()` gives an older save an overgrown homestead and moves nothing: the home is the
  same area and the plot's cells are the field's clear corner. A test loads a real version 5 save made
  inside the old cottage (`tests/fixtures/saves/v5_in_the_old_cottage.json`).

## 10. Testing
Every class in `core/` has gdUnit4 tests. Areas get layout tests (reachability from the spawn with the real
movement rules) and scene tests through gdUnit4's scene runner. Data validation tests load every JSON file. Tests
run headless; see CLAUDE.md for the command and gotchas.

## 11. Performance budget (slice)
60 fps on integrated graphics. Area loads under 200 ms. No world streaming in the slice.

## 12. Menus, saving & settings
- **The title screen** (`ui/title_screen.tscn`) is the main scene. It offers:
  - **Continue**, which can be chosen when there's a save or the backup of one, and names where and how long
    if the save can be read (`SaveSystem.summary()`)
  - **New game**, **Settings** and **Quit**

  Continue loads the save and opens the area it names, with the hero on the saved cell.

  **A save that can't be read is never passed over in silence.** Continue says so in a box under the menu and
  offers the backup in the menu's place, with where and how long it was ("Load the earlier save", "Back"; Esc
  goes back). If the backup can't be read either, or there is none, it says that and the menu stays. A save
  that is missing while its backup is there (the game closed between the two moves) is treated the same way.

  The title's picture follows the save: `summary()` also says whether the saved game was finished
  (`EndingSummary.is_finished`), and then the keep's window is dark.

  **The picture** (P1f) is a painted evening over Hearthvale, the size of the screen:
  - `tools/art/make_title.gd` paints it and bakes `ui/title/backdrop.png`: a dusk sky in dithered bands
    (`dithered()`, a 4x4 Bayer grid), a moon, clouds, far hills, the old keep, the Old Wood's pines, mist, and the
    village: houses painted for the picture, and the game's own trees from the scenery atlas in evening light.
  - `TitlePicture` (`ui/`) has the layout both sides need: the keep's window, the stars that twinkle, where the
    cherry trees stand.
  - `TitleBackdrop` draws the picture (in the middle, its foot on the screen's foot: `origin()`) and what moves
    over it: the stars, the window's light (`keep_lit`), and petals leaving the cherry trees. The ending screen
    uses the same backdrop with the window dark.
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
    `QuestLog`: started quests, active first, each with its journal line and objectives ticked when done. **Quitting to the title saves first,**
    and the menu says so.
- **Leaving saves** (the fix round of 2026-11-16). `SaveSystem` turns `auto_accept_quit` off and takes the
  window's close request itself: the scene the game is showing is asked to `save_and_leave(then)` if it has
  that method (an area, the ending screen), and anything else (the title) quits at once.
  - `AreaController.save_and_leave()` saves where the hero stands (`save_here()`), says "Saving..." at the top
    of the screen and in the pause menu if it is open, and calls `then` after `SaveSystem.leave_delay` (half a
    second of real time): the title for "Quit to title", the end of the game for a closing window.
  - A hero lying fallen is saved as he would wake (at the entrance, whole); one down a pit, on the ground he
    fell from.
  - If the save can't be written he is told and the game goes on. Asked a second time, it leaves unsaved.
  - Only `get_tree().current_scene` is asked, so an area that a test or the screenshot tool has put in the
    tree beside its own scene is never saved by a closing window.
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
    (pure): time played, hearts, and quests finished out of those in `data/quests`; and since P4d the days it
    took, the crops grown (`GameState.tally`) and the friends made out of the villagers in `data/villagers`
    (`Friendship.friends_among()`: a friend has `friend_marks` marks or more, three in the rules).
  - **Keep exploring** goes back to the area and cell the hero stood on. **Save and go to the title** saves first.
- **The story** is data only: conversations whose options are gated on the flags `keep_warden_beaten` and
  `crypt_shade_beaten`, and `Signpost` inscriptions in the keep, by the chapel and in the crypt. They are
  `stone`: drawn as a standing stone with carved lines, where a wayside sign is a wooden post. Since P4a it
  is spread over days, with a main quest (section 22).

- **The mouse** (the user's requests, 2026-11-13; `tools/setup_input_map.gd`), as in farming games: the left
  button uses what the hero has in hand (the action `use_hand`), the right button interacts (`interact`).
  Moving is on the keys as it was; the sword (Space) and the item (Q) keep their own keys too; a gamepad is
  unchanged; E no longer does anything. In play the buttons are buttons, not a pointer: where a click lands
  doesn't matter, and the hero acts on what he faces. In menus the mouse points (2026-11-15, below).
  - **What is in hand** is `AreaController.use_hand()`'s to say. With nothing on the item button: the sword.
    A weapon there (the bow, bombs): that weapon. A bow with no arrows gives the click to the sword
    (`GameState.is_out_of_ammo()`; Q still says "Out of arrows."), and the last bomb empties the button, so
    running out is no dead end. A farm tool or a seed: the tool when he faces what it is for
    (`faces_farm_work()`: a cell of his plot, or water), where it works or says why not; anywhere else the
    sword, so a hoe in hand doesn't leave him unarmed. With no sword at all the tool says what it is for.
  - **The item bar** (the user's request, 2026-11-15; `docs/progress/mouse-and-bar-plan.md`): `HandBar`
    (`core/inventory/`, pure) says what can be in hand and in what order (the best sword, then
    `Inventory.equippable_held()`), which entry is in hand for a given `equipped` (the sword's when the
    button is empty), the entry a step on (round and round), the first slot showing when there are more than
    `SLOTS` (9), and the number a slot has (`Inventory.ammo_for()`). `GameState.hand_entries()`,
    `hand_index()`, `take_in_hand(index)` and `step_hand(step)` apply it by setting `equipped`. The area
    reads the actions `slot_next` / `slot_previous` (the wheel, a pad's shoulders) and `slot_1`..`slot_9`
    (`step_hand()`, `choose_slot()`; nothing while he is busy), and `ItemBar` (`ui/item_bar.gd`, on the HUD)
    draws it in code: slots of 20 px in the middle of the bottom of the screen, the one in hand lit, a mark
    at an end where the bar goes on. It is hidden during a conversation and behind the lists, and takes no
    clicks. The prompt and the message line sit above it.
  - **The mouse points in menus** (the user's request, 2026-11-15). `MenuPointer` (`core/menus/`, pure) says
    which line of a list a point is on; `MenuInput.line_under(label, event, lines)` asks it about a menu's
    own list (the event made local to the label, lines `MenuInput.line_height()` high). Each menu, on the
    mouse moving, puts its cursor on the line under it (`point_at()`), and on a click chooses the line the
    click is on. A click on no line does what it always did: the highlighted line, or reading on in a
    conversation. A `MenuCursor` list uses `select()` and `take_click()`, so a click on a line that can't be
    chosen does nothing. The wheel is up and down in every menu (`MenuInput.is_up()` / `is_down()`), which
    scrolls a list longer than its box. At Tilda's a click on "Buy" or "Sell" turns to that list
    (`ShopMenu.tab_under()`), and a click between them does nothing.
  - Every menu takes either click as its yes (`MenuInput.is_confirm()`: interact, use_hand or Enter). Tab or
    Esc leaves any list (`MenuInput.is_back()`).
  - **A conversation is answered with the left click** (`MenuInput.is_answer()`: use_hand, Enter, or A on a
    pad; the user's request). The right click starts a conversation and doesn't answer one; Space never did.
    The left click is also the sword's button, so `DialogueBox` takes no left click as an answer for its
    first `SWING_GRACE` (0.3 s): a swing made as a conversation opens by itself (a boss's last words) doesn't
    skip its first line. Enter answers at once.
  - Everything reads input in `_unhandled_input`, and a `Control` under the pointer would take the click
    first. `MenuInput.let_clicks_through(root)` sets every Control under a screen to ignore the mouse; the
    HUD, the title and the ending call it as they start. **A new screen must call it too.**
  - `MenuInput.INTERACT_KEY` ("Right click") is what the interact button is called on screen, and
    `MenuInput.prompt()` makes the HUD's prompt ("[Right click] Pick the Turnip"). `ANSWER_KEY` ("Left
    click") is the mark in a conversation. The help lines in the scenes say "Click" where either button does.
  - Headless tests hand a click straight to a node's `_unhandled_input()`; a scratch script that pushed real
    clicks through a window found them working in the world, a conversation, each menu and the title.
- **A long list scrolls** (P3b, P3c): `MenuCursor.window_top()` (pure) moves the first line shown only as far
  as it must to keep the cursor in view, and `count_text()` says where he is ("3/7 v": the marks show which
  way there is more). The item menu and the shop's list show five lines (`ROWS`); a conversation shows four
  answers (`DialogueBox.OPTION_ROWS`), with the count in the corner where "[Left click]" stands when there is
  nothing to choose.

## 13. Audio & feel
- **Made in code, baked to files** (no external assets):
  - `Synth` (`core/audio/`, pure) makes samples: square (with duty), triangle, sine, saw and noise; pitch sweeps;
    attack and release; mixing; a note sequencer; and PCM16.
  - Notes are written `C4:2` (a note and its length in eighth notes); `R` is a rest, and drum tracks use `K`, `S`
    and `H`.
  - `tools/audio/make_audio.gd` holds every effect's recipe and the five original songs, and bakes them to
    `audio/sfx/<id>.wav` and `audio/music/<id>.wav` (22050 Hz, mono, 16-bit). Edit sounds in the tool, never the
    WAVs, then re-import.
- **Playing:** the `Audio` autoload.
  - Effects: `EventBus.sound(id)` plays on one of eight voices on the `SFX` bus.
  - Music: `EventBus.music_requested(id)` loops on the `Music` bus (the same tune again carries on; empty stops).
    Each area names its `music`: village tunes for the village and its houses, countryside outdoors, dungeon
    underground. The title plays the village tune. Out of doors at night the area asks for the night's tune
    in place of its own (§19).
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
  - The farm (the area, as a tool is used): hoe, pour, fill; nope when a tool has nothing to do.
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
    - **the strokes' (tool polish, D5, a bend of "A still world" the user allowed):** clods from the
      hoe, a splash of water, seeds from the hand, chips and rubble of a rock in its own colours
      (`Rock.chip_colours()`, read from its picture), splinters of wood. Each is thrown up and comes
      to rest on the ground (its `floor`) within half a second; none rises or hangs. `Pour` is the
      water from the can's spout and `Ripple` a ring on the water where the can is dipped.
    - a blow that doesn't break a rock, a log or a stump shudders it a pixel and lays its white
      picture over it, half seen, for a moment.
- **Volume:** `SettingsData` adds music and sound volume (0–10, default 7). `Audio` sets each bus (0 mutes).

## 14. Sprites
- **The art is PNG (since 2026-11-19, `docs/progress/png-art-plan.md`).** Every picture the game shows
  is a PNG where the game loads it, and is its own source: edited in Aseprite or replaced (`art/README.md`).
  `art/sheets.json` lists each PNG's size, frames in order, rows, flash row and pivot, and
  `tests/art/art_sheets_test.gd` checks every PNG and every script's frame names against it; the
  palettes are in `art/palettes/`; `docs/ASSETS.md` says where each picture came from. **The tools named
  below and in later sections painted the art until then;** they are retired to `tools/retired/`
  (ignored by Godot) with the part of `PixelGrade` that graded a picture as it was baked. What follows
  is how the art was made and what it is; the frames and their order are the same in the PNGs.
- **Every actor is pixel art**, painted in code until the switch, like the hero. The art lived as ASCII in `tools/art/`:
  - `make_player_sprite.gd`: the hero, brown-haired with his blue hood down, a blue tunic with a gold hem and a
    red scarf. Three rows (down, up, side; right is the side row mirrored) of twenty-five 16x32 frames (twenty-one until the tool polish added four work poses).
    - **He is put together from parts** (P1e), so every frame of a facing has the same head and clothes:
      `HEADS` (rows 0-11), `BODIES` (a pose, rows 12-22) and legs (`LEGS_FRONT`, `LEGS_SIDE`, rows 23-31), joined
      by `frame()` as `RECIPES` says. The second half of the walk is the first on the other foot: the legs
      mirrored from the front and back, the near and far leg's shades swapped from the side.
    - Thirteen frames are built that way (`drawn()`): idle, blink, six walk frames, wind-up, slash,
      follow-through, item held up, fallen (the last two are whole pictures).
    - Eight are made from those by `derived()`: breathe and hurt (`sink()`: everything above the chest a pixel
      lower) and six run frames (`lean()`: the side view's upper body a pixel forward).
    - `HILTS` lays the sword's hilt over his shoulder in every frame but a swing's; `EXTRAS` lays a wind-up's
      raised hand beside his head.
    - A test checks `PlayerAnimator`'s columns against the tool's.
    Over the tunic he wears a leather vest, wrist guards, a belt pouch, slate trousers and tall boots, with a
    small pack behind.
  - `make_sprites.gd`: everything else, namely slime, bat, goblin archer, the Iron Warden, the Crypt Shade,
    villagers, items and pickups, the crystal switch, the torch, the training dummy and brambles
    - and the tools in his hands (`HELD`, painted by `held_sprite()` to `held_tools.png`): 40x56
      frames with his feet at (20, 40), each a block laid at a corner and named
      `<item>_<facing>_<pose>`, the fists painted over the handle where his work poses' hands are.
      The copper and iron tools are made from the plain ones by swapping the head's colours.
      `HeldTools` names them in the same order (a test checks).
  - The hero's work poses (`worked()` in `make_player_sprite.gd`) are columns 21 to 24, put together
    from his parts like the rest: raise (the swing's wind-up body), strike and pour (the slash's), and
    reach (the follow-through's, a pixel lower), all with the sword on his back.

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
- **Nature** (P1c), all for show; an area builds it in `_add_ambience()`:
  - **Only the water moves** (the user's request, 2026-11-13). Until then crowns swayed (a shader on each
    tree), tufts, flowers and washing leaned in the wind on a layer of their own (`SwayLayer`), petals drifted
    from the cherry trees, specks hung in the air (`Motes`), the mist drifted and chimney smoke played four
    frames. `SwayLayer` and `Motes` are gone; the rest stands still. Do not add motion to the scenery.
  - **Tall trees** (`Scenery`, `world/areas/`): at load, every tree tile on the Decor layer but the closed
    canopy is taken off it and a `Sprite2D` stands in its cell, 32 by 40 pixels from `SceneryAtlas`
    (`world/tiles/scenery.png`, painted by `tools/art/make_scenery.gd`). `Scenery` is y-sorted, so trees sort by
    depth with the hero and everything in `Interactables`. A tree's foot is `Scenery.foot_of(cell)`.
    - The tree's cell is solid as it always was (the Height layer). The crown only overlaps the cells behind.
    - **Nothing is hidden:** `fade_for(points, delta)` fades the crowns that `hides()` any of
      `AreaController.standing_points()` (the hero, enemies, anything with `collect()`, item pickups). Grass,
      pots and signs don't count, or a tree behind them would stay faded.
    - A tree has no material: it stands still.
  - **Cherry trees:** a `"cherry"` block in `build_maps.gd` makes a solid cell with a `prop_cherry` tile, which
    `Scenery` stands up as `cherry` or `cherry_b` by cell. `Petals` (`gameplay/ambient/`) scatters settled petals
    round each (`scatter(foot)`, the same every time; only on cells `ground_at()` calls "open" or "water").
    None are in the air.
  - **Water** (`WaterSurface`): one rectangle over the water's bounds, just above the Height layer, with a shader
    that reads a one-pixel-a-cell map of the water: a slow swell, glints, sparkles, and foam at the bank one to
    three pixels wide. `HeightShading` keeps only the dark line under the bank.
  - **Reflections** (`Reflections`): a mirror `Sprite2D` (flipped, hanging below the feet) for the hero and for
    each tree within three cells north of water, shown only on water cells by a shader with the same map.
  - **Mist** (`Mist`, `gameplay/ambient/`): two layers of noise in four flat steps, pinned to the world, for the
    areas in `Ambience.MISTY` (the Old Wood). It lies still: its shader reads no time.
- **Buildings** (P1d), for show, built in `_add_ambience()` like the trees: pictures over the map, the Height
  layer untouched.
  - **Walls with a face and a top** (`WallRelief`, `world/areas/`): for the wall tiles in
    `ReliefAtlas.MATERIALS` (dungeon walls of stone, house walls of timber, outdoor ruins), `part_of()` says
    which part a cell shows: its FACE if the cell to its south is in the map and isn't wall, else its TOP.
    - A face is 24 pixels tall and rises eight over the foot of the wall behind it (`rises()`), unless that wall
      is in the next room of a dungeon (the first row of a room) or isn't there at all. Then the short face is
      used; a wall one cell thick shows a strip of top above it.
    - Tops are edged with light where the wall ends to the north or west and with shadow to the east.
    - The whole relief is put together once into one picture the size of the map (`_compose()`), so it costs
      one draw. Drawn per cell it tripled the keep's draw calls.
  - **Pillars and ridges** (`Scenery.build_stone()`): a 28-pixel pillar over each pillar tile, and an 8-pixel
    strip of ridge over each cell of a roof's top row (`ReliefAtlas.ridge_of(kind)` gives the roof's style and
    whether it is a gable end). Both are sorted by depth: a ridge sits just inside the building's top edge, so
    whoever walks behind the house is drawn first. Neither fades.
  - `ReliefAtlas` (`world/tiles/relief.png`) is painted by `tools/art/make_relief.gd`.
  - **A shader gotcha:** in a canvas shader `COLOR` already holds the texture's colour times the node's tint
    when `fragment()` starts. To sample the texture again, carry the tint from `vertex()` in a varying; don't
    multiply the new sample by `COLOR`, or the picture is squared and goes dark.
  - **Vignette:** `AreaHud` shades the screen's corners (a radial gradient, under the rest of the HUD).
- **Screen layout (P1a):** every box is anchored, never placed for one screen size: menus to the middle, the
  dialogue box to the bottom edge, the controls hint to the top right, lines of text across the top or bottom.
  - The HUD's corner is a `VBoxContainer` (`Panel/Box`): the hearts, the `EnergyBar`, then up to three lines.
    `AreaHud._fit_panel()` sizes the framed box to it, so it grows with a second row of hearts or with the bar.
    Since P1f it is as wide as its longest line (`line_width()`, up to `BOX_MAX`, then an ellipsis), and a line
    with nothing to say is hidden: `AreaController` hands it "" when nothing is carried or no item is in hand.
  - `EnergyBar` (`ui/`) draws a leaf and a framed bar from `set_energy(current, maximum)`: green, amber under a
    half, red at a quarter (`LOW`). It is hidden until the energy rules exist (P2): `AreaHud.show_energy()`.
- **Lettering** (art pass 4): `tools/art/make_font.gd` paints a 95-glyph pixel font from ASCII art and bakes
  `ui/font/hearth_font.tres` (a bitmap `FontFile`, size 8, line height 11, scaled by whole numbers only) and
  `ui/theme.tres` (that font, and a one-pixel shadow under every label), and sets the project's theme.
  - Labels ask for size 8, or a whole multiple. A bitmap font has no outline, so none is set.
  - **The heading face** (P1f): the same tool bakes `ui/font/hearth_heading.tres`, a second face of size 16
    (capitals twelve pixels tall, line height 18) with thick stems, thin bars and small serifs. It has capitals,
    digits and a few marks (`HEADING`, a list of rows a glyph); a small letter is given its capital's picture, so
    any words can be set in it. `HEADING_KERNING` tucks together pairs that stand too far apart (V and A).
    The theme offers it as a kind of label, `Heading` (gold over a dark shadow): a label takes it with
    `theme_type_variation`. The game's name and "The End" are set in it at 32, each box's heading at 16.
  - `PanelFrame` (`ui/`) is the script on every box's `Panel`: over the box's own colour it draws a shadow under
    the box, an inner line (lit along the top and left, in shade along the bottom and right), a bracket in each
    corner with a rivet where the inner line turns, and, when the box has a heading (`rule_y`), a rule under it
    with a diamond in the middle. `bracket_arms()`, `rule_parts()` and `diamond_rows()` say where, and are tested.
- **Drawing:** `SpriteSheet.draw(canvas, texture, frame, size, origin, flip_h, white, tint)` draws one frame.
  - Origins are rounded so sprites stay on the pixel grid.
  - A negative width mirrors it (side views face left). This engine mirrors a negative-width rectangle
    in its own place, so the corner stays where it is (`target_of()`; until the tool polish's step 4 it was
    moved a frame's width right first, and every creature facing right stood off its node).
  - Scripts name frames in dictionaries (`Enemy.SLIME_FRAMES`, `Boss.FRAMES`, `ItemIcons.FRAMES`...), and a test
    checks they match the tool's order.
  - Shadows, glows, sparks, poofs, arrows and the sword's swing stay drawn in code: they're effects, not shapes.
- **Villagers** are painted in marker colours (magenta robe, cyan hair). `SpriteSheet.recoloured()` swaps them for
  each villager's `robe_color` and `hair_color`, once per look.
  - **As tall as the hero** (P1e): 16x32, feet mid-cell where they were. A villager still fills only its own cell.
  - **They breathe and blink** (`Idling`, `core/ambient/`, pure): out for `BREATH_OUT` of every `BREATH_EVERY`
    seconds, eyes shut for `BLINK_TIME` every `BLINK_EVERY`, never mid-breath. Each starts at a moment of their
    own (`phase_of(cell)`), so they don't move as one. A villager redraws only when its look changes.
  - **Made frames:** a sprite in `make_sprites.gd` may list frames `"made"` from its drawn ones (`frames_of()`):
    `"breathe"` lowers everything above its `"sink_row"` a pixel, `"blink"` closes the eyes. The villagers'
    four idle frames and the chicken's blink (shown when it stands still) are made that way.
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

## 16. Time
- **The day's rules are data** (`data/rules/time.json`, schema `docs/data/rules.schema.json`): when a day starts
  (06:00) and ends (02:00), how many real seconds an hour takes (42, so a day is 14 minutes), when lamps are lit,
  when it is night, and the colour of the light at times of the day.
- **`DayClock`** (`core/time/`, pure) reads them. A time is a number of minutes since the midnight the day began
  on, so the small hours carry on past 1440 and a day's times only go up. It moves a time on (`advance()`, which
  stops at the day's end), and answers `is_over()`, `light_at()` (between two of the rules' times the light is
  between their colours), `lamps_lit()` and `is_night()` (spans that may run over midnight). `problems()` says
  what is wrong with a set of rules; the registry calls it at load.
- **`GameState`** keeps `day` and `minute`. `advance_time(seconds)` moves the clock and emits
  `EventBus.time_changed(day, minute)` once for each minute of the day; `start_next_day()` emits `day_started`.
  `time_text()` is the HUD's line ("Day 3  14:20", in steps of ten minutes); `daylight()` is the light now.
- **The clock runs in an area's `_process`** (`AreaController.clock_runs()`): not in a dungeon, a conversation
  or the item menu, nor while the hero is down or in a pit; behind the pause menu nothing runs at all.
- **Light:** outdoors (`has_daylight()`) the area hands the hour's colour to `AreaLighting.set_ambient()` every
  frame. Houses and dungeons keep their own ambient colour.
  - Tile lights in `Ambience.LIT_AT_DUSK` (street lamps) carry `at_dusk`, and `Ambience.shining()` leaves them
    out unless lamps are lit. A fire or a candle burns at any hour.
  - Once the night dims the picture each lamp gets a pool, warmer and weaker than indoors (`NIGHT_POOL_TINT`,
    `NIGHT_POOL`). The hero has no pool of his own outdoors.
- **The day's end:** at 02:00 `AreaController.end_the_day()` starts the next day, sends the hero to the entry
  by his bed (`WorldPaths.HOME_AREA`, `HOME_BED`), saves, and leaves `GameState.arrival_notice` for the home
  area to say once as it loads (words that are not part of a save). `_process` stops there for the frame: the
  rest of it would write where he stood over where he is going.
- **Home and sleep (P2b):** `home` is an area like the other houses (the farmhouse's inside since the
  Homestead, §30, and the thatched cottage's before it; its door is an `AreaExit` on the homestead). The bed is a `Bed` (`gameplay/interactables/`), a `Talkable` on the bed's
  tile whose conversation is data (`data/dialogue/bed.json`). Its first answer has the effect `sleep`:
  `EffectApplier` calls `GameState.sleep()`, which starts the next day, fills hearts and energy and emits
  `EventBus.slept`; the area running then saves the game and says so.
- **Tools:** `tools/capture.gd` takes every shot at noon unless its action is `time:<HH:MM>`;
  `tools/playtest.gd` takes an hour after a scenario's name.

## 17. Energy
- **The rules are data** (`data/rules/energy.json`, in `docs/data/rules.schema.json`): a full bar (100), what
  things cost (`sprint_per_second`, `swing`, `shot`), when the hero is tired (`low`: under 25 he moves at 85%
  and the sword's cooldown is 1.3 times as long), when he can't sprint (`no_sprint_below`: 10), and what
  collapsing costs (`collapse`: he wakes with half a bar, and loses a tenth of his coins, 30 at most).
- **`EnergyRules`** (`core/energy/`, pure) reads them and answers `cost()`, `is_low()`, `can_sprint()`,
  `is_spent()`, `move_factor()`, `cooldown_factor()`, `wake_energy()` and `coins_lost()`. `problems()` checks a
  set of rules at load.
- **What work costs the hero** is `GameState.energy_cost(action)`: the rules' cost, less what his skill at
  that work takes off it (P4b, section 23). A swing, a shot, the hoe and the can ask it; sprinting asks the
  rules, since no skill eases it.
- **`GameState`** holds `energy` (saved since version 2). `spend_energy()` and `set_energy()` keep it between
  nothing and a full bar and emit `EventBus.energy_changed`. `is_exhausted()` is true at zero. `collapse()`
  is the state's part of collapsing: the next day, half a bar, the coins gone; it returns how many.
  **Nothing here touches hearts.**
- **Spending:** `PlayerController` sets `motor.sprinting` (sprint held, and the energy for it) and
  `motor.speed_scale` every physics frame, and spends the sprint's cost only for frames in which the hero
  actually moved on foot while sprinting. A swing spends its cost when it starts, with the cooldown stretched
  if he is tired; the area does the same for a bow's shot. A bomb is free.
- **Collapsing** (`AreaController`): each frame, an exhausted hero who isn't down, in a pit or talking
  collapses: `collapse()` lays him down (`PlayerController.lie_down()`, the fallen picture), switches off his
  hurt box and his controls, and after `COLLAPSE_TIME` `_wake_at_home()` runs: `GameState.collapse()`, the
  words for the home area to say, the way to his bed, a save, and the change of scene. The day running out
  (`end_the_day()`) goes the same way, so it costs the same.
- **The HUD:** the area shows the `EnergyBar` and keeps it to `energy_changed`; a line of words says when he
  crosses into being tired or too tired to run.

## 18. Food and cooking
- **Food is an item type** (`food`), whose `stats` say the `energy` it gives and the `hearts` it mends (0.5 is
  half a heart). An `ingredient` is only cooked with. `Food` (`core/inventory/`, pure) reads them:
  `energy_of()`, `halves_of()`, `would_help()` (it gives energy and the bar isn't full, or mends hearts and some
  are missing), `gives_text()` for the menu, and `problems()`, which the registry runs on every food item.
- **Eating:** `GameState.eat(item_id)` uses one and applies it, or returns false and uses nothing when it
  wouldn't help. The item menu lists what goes on the item button, then the food (`Food.edible_held()`);
  `AreaController._on_item_chosen()` equips the one and eats the other.
- **Foraging:** `ForageSpot` (`gameplay/interactables/`) is an `ItemPickup` that grows back: its flag holds the
  day it was last gathered, and it is `taken()` only on that day. It lies on the ground, blocks nothing, and is
  picked up like any item. Its two pictures (grown, gathered) are in `gameplay/art/forage.png`.
  - A spot must not lie under a tree's crown: a crown fades for anything that can be picked up behind it, and
    would stay faded. A test checks every spot.
- **Recipes are data** (`data/recipes/<id>.json`, schema `docs/data/recipe.schema.json`): `makes` (an item and
  how many) and `needs` (items and how many). The registry checks every item id (`Cooking.problems()`).
- **Cooking:** `Hearth` (`gameplay/interactables/`) is a `Talkable` on the hearth's tile at home. Its
  `dialogue()` isn't a file: `Cooking.dialogue()` (`core/cooking/`, pure) builds a conversation from the
  recipes, in the shape of the ones in `data/dialogue`. Each recipe is an answer that takes the makings and
  gives the dish (the shared `take_item` and `give_item` effects) when the hero has them and room to carry the
  dish, and says so when he hasn't. `AreaController.talk_to()` opens whatever a `Talkable.dialogue()` returns,
  so the hearth needs no screen of its own.
- **The shop:** bread is a line of Tilda's list, like arrows and bombs (§21; until P3c each was a line of her
  conversation).
- **Meals from crops** (P3c) are five more recipes and four more food items: no code. The hearth's
  conversation lists six dishes, so a conversation's answers scroll (§12).

## 19. Hours and night
- **Hours are data** (`data/rules/hours.json`): `places` (a place's id, when its door is open, and the words
  said at it when it is shut) and `outdoors` (when villagers who stand outdoors are out). `Hours`
  (`core/time/`, pure) reads them: `is_open(place, minute)`, `shut_words(place)`, `villagers_out(minute)`. A
  place the rules don't name keeps no hours. Spans may run over midnight (`DayClock.span_of()`, `within()`).
- **A door keeps hours** by naming its place: `AreaExit.hours` (the village's `ShopDoor` has `&"shop"`).
  `AreaController._keep_hours()` runs as the area loads and on every `EventBus.time_changed`: a shut door's
  cell is occupied, so the hero can't stand in the doorway. Walking up to it (`_on_cell_changed`, facing it)
  or trying it (`interact()`) says the place's words; `take_exit()` refuses a shut door whoever asks. Doors
  the other way (the shop's doormat) keep no hours: he can always leave.
- **Villagers go home:** outdoors (`has_daylight()`), `_keep_hours()` sets every `Villager` present or away
  (`set_present()`): away, it is hidden, `covers()` nothing (so there is nobody to talk to) and its cell is
  free. Nobody leaves during a conversation, and nobody comes back onto the cell the hero stands in; both are
  put right at the next minute. Villagers indoors are never touched. Nobody walks anywhere.
- **Night monsters:** the night's numbers are data (`data/rules/night.json`). `NightRules` (`core/enemies/`,
  pure) has `strengthen(enemy_data)`, which returns a copy with more health (rounded up), speed and sight and
  heavier coin drops; bosses come back unchanged. As an area loads, `AreaController` sets `Enemy.night` from
  `is_night_outdoors()` before `setup()`, and the enemy is set up from the strengthened copy. It is decided
  once: a monster met by day stays a day monster at nightfall, and the other way round. Dungeons have no
  night. Damage, knockback, hit boxes and timings are the data's own.
  - A night monster is drawn unshaded in `Enemy.NIGHT_TINT`, so it shows in the dark. For show only.
- **Lit windows:** `WindowGlow` (`world/areas/`) is made at load from the window tiles of the Height layer
  (`GLASS`: each window tile and where its glass is). It draws a warm pane over each, unshaded so the night
  doesn't dim it, over the walls and under everything that stands in front of them. `_update_light()` lights
  it with the lamps (`DayClock.lamps_lit()`). Only the village has windows to light.
- **The tune:** `AreaController.tune_now()` is the area's `music`, or when `is_night_outdoors()` the area's own `night_music` if it names one (only the homestead does, §30) and `NIGHT_TUNE` if not.
  `_play_tune()` asks for it at load and on `time_changed`, but only when it is another than the one it last
  asked for, so a boss's tune is left alone.
- **Sounds:** `eat` (eating), `collapse` (as he falls), `morning` (a cock-crow: after sleeping, and when he
  wakes at home after a day that ran out).
- **Tools:** `tools/capture.gd` has the action `shut` (the hero tries the shop's door at 19:00).

## 20. Farming
- **The farm's rules are data** (`data/rules/farm.json`): the plot's size in cells (12 by 6 since the
  Homestead, §30; 6 by 3 before it) and how many dry
  mornings wither a crop (3b). What hoeing and watering cost is in the energy rules (`hoe`, `water`).
- **`Farm`** (`core/farming/`, pure) is the plot: which cells are tilled and which watered. Cells are the
  plot's own ((0, 0) is its north-west corner), so the plot can lie anywhere. `till()` and `water()` return
  whether they did anything; `new_day()` dries the soil and leaves it tilled; `to_dict()` and `load_saved()`
  are its save.
- **`GameState.farm()`** keeps the one farm (made from the rules when first asked for, thrown away by
  `clear()`). `till_soil()` and `water_soil()` change it and emit `EventBus.farm_changed`;
  `start_next_day()` calls `new_day()`, so sleeping, collapsing and staying up all dry the soil.
- **`FarmPlot`** (`world/areas/`) is the plot as it lies in an area: a node at the plot's north-west corner
  (the homestead's is at cell (22, 17), below the farmhouse; until the Homestead it lay in Hearthvale at
  (12, 18), between the shop and the well). It draws each cell from
  `gameplay/art/soil.png` (bare in two kinds, tilled, watered) and redraws on `farm_changed`. It blocks
  nothing and nothing is picked up from it. As the area loads it takes the Decor tiles off its cells
  (`clear_ground()`): no map is re-baked for it. It sits just after the Decor layer in the scene.
- **Tools** are items of type `tool` whose stats name the `tool` (`hoe`, or `water` for the can). They go on
  the item button (`Inventory.EQUIPPABLE_TYPES`). The can names what it holds as its `ammo` (the item
  `water`, ten at most), so the item menu and the HUD say "Watering Can (Water x7)" with the code the bow
  uses. `Inventory.held_in_tools()` keeps the water out of the "Carrying" line.
- **`ToolUse`** (`core/farming/`, pure) decides what a use does: `decide(kind, soil, at_water, pours, holds)`
  returns what it does (`TILL`, `WATER`, `FILL` or nothing) and the words for when it does nothing.
  `AreaController._use_tool()` asks it about the cell the hero faces, then does it: the motor's attack state
  for the tool's `cooldown` (he stands still, in his swing pose), the farm changed, the energy spent, a sound,
  a puff, and a `ToolFlash` (the tool's picture dipping over the cell). A use that does nothing costs nothing.
  - `is_water_source(cell)`: a water tile on the Height layer, or one of the well's four Decor tiles.
- **Where the tools are:** two `ItemPickup`s in the hero's home, by the door, and beside them the first pouch
  of five turnip seeds.
- **Crops are data** (P3b; `data/crops/<id>.json`, schema `docs/data/crop.schema.json`): `days`, `seed`,
  `gives`, `seed_price`, `sells_for`. `Crops` (`core/farming/`, pure) reads them and checks them
  (`problems()`: the seed must be a seed that names this crop, the item it gives must exist). A seed is an
  item of type `seed` whose stats name its `crop`; the registry checks that the crop exists.
  - What a crop gives is an ordinary `food` item, so it is eaten from the item menu and cooked with like any
    other. There is no item type for crops.
- **Growth** is `Farm`'s: `plant()`, `new_day(days_by_crop)`, `is_ripe()`, `phase_of()`, `harvest()`,
  `clear_withered()`. A morning adds a stage to a crop that was watered the day before; an unwatered one
  counts a dry morning, and `wither_after` of those in a row wither it; watering starts the count again. A
  ripe crop is skipped: it neither grows nor withers. `Farm` is told how many mornings each crop takes, so
  it knows nothing of the data.
  - `phase_of()` is what shows: `SEEDED` (stage 0), `SPROUT` (the first half), `GROWING` (the second),
    `RIPE`, `WITHERED`.
- **Through `GameState`:** `plant_crop()`, `harvest()` (which checks the pack has room, then adds what the
  crop gives), `clear_crop()`, `is_crop_ripe()`, `crop_phase()`. `start_next_day()` hands `new_day()` the
  days of every crop.
- **Planting** is a use of the item button like a tool's: `ToolUse.kind_of()` is `SEED` for a seed, and
  `decide()` takes whether something already grows in the cell. A seed is used up itself
  (`Inventory.ammo_for()`, as a bomb is). Planting costs no energy.
- **Picking** is `interact()`: after pickups, people and doors, `AreaController.crop_in_front()` finds a ripe
  or a withered crop in the cell the hero faces, `crop_prompt()` words the HUD's prompt, and `_tend_crop()`
  picks the one or clears the other. Neither costs energy.
- **Pictures:** `gameplay/art/crops.png` has three frames every crop shares (seeded, sprout, withered) and
  two of its own for each crop (growing, ripe); `FarmPlot.crop_frame()` picks one, falling back to the shared
  ones for a crop with none. All are 16 by 16 and drawn flat by the plot, under everyone: a crop never
  blocks, hides or is hidden.
- **Tools:** `tools/playtest.gd -- farm` starts on the homestead's road above the field's clear corner
  with both tools and seeds of every crop; `tools/capture.gd` has the actions `farm`, `hoe`, `fill`, `tools_menu`, `crops` (a plot in the
  middle of a season), `plant` and `seeds_menu`.

## 21. The shop
- **A shop is data** (P3c; `data/shops/<id>.json`, schema `docs/data/shop.schema.json`): `name`, `sells` (its
  own wares: an item, how many a deal gives, the price), `sells_seeds`, `buys_crops`, and `buys` (the other
  things it pays for: an item and the price of one). Seed prices and what a crop sells for are in
  `data/crops`, so a new crop is on both lists without touching the shop. There was one shop, `tilda`, until the Homestead's phase 4 added a
  second, `oda` (Farmer Oda's stall, §30), whose wares are animals: a ware may be `{ "animal", "price" }`
  in place of an item.
  (Since the Homestead's phase 2 she also sells fibre five at a time, hedges, flower beds and
  saplings: seven more lines of `sells`, §30.)
- **What Tilda buys from the quarry** (mining and crafting, phase 3a) is her `buys` list: copper ore 2,
  iron ore 3, gold ore 7, a crystal 10, a copper bar 8, an iron bar 12, a gold bar 25 (a third less than
  first set: the tuning of phase 3). Stone, wood and
  coal are not on it, so they are not bought. **A new thing to buy is a line of data.**
- **`Shop`** (`core/shop/`, pure) says what is on each list: `wares(shop, crops)` (her own wares in order,
  then a seed of every crop, cheapest first) and `offers(shop, crops, stacks)` (the harvest he carries, in
  the order of the seeds, then what `buys` names and he carries, in that list's order: each with how many
  and the price of one; a thing is offered once, a crop's own price first). `bought_things(shop)` is the
  `buys` list as read. `why_not_buy()` and `why_not_sell()` say why a deal can't be made: not enough coins,
  no room for all a deal gives, a full purse. `problems()` is run by the registry on every shop, and checks
  `buys` as it checks `sells`: a list, each entry an item that exists and a whole price of 1 or more, no
  item twice.
- **`GameState.buy(ware)` and `sell(offer)`** make a deal or return why not (Shop's words), and then nothing
  has changed. Selling is one at a time. Coins and items are already saved: the save format is as it was.
- **`ShopMenu`** (`ui/`, a child of the HUD) is the counter: the two lists as tabs ("[Buy]  Sell"), the purse
  beside them, five lines of the list at a time, a line that says what the last deal was or why it couldn't
  be made, and the help. Up and down move, left and right turn to the other list, either click or Enter makes
  the deal, Tab or Esc leaves. It stays open for as many deals as he likes.
- **A conversation opens it** with the effect `shop` (`shop`, `mode`): `EffectApplier` calls
  `GameState.request_shop()`, which emits `EventBus.shop_requested`; the area keeps it (`_shop_due`) and
  calls `open_shop()` when the conversation closes. The registry checks that the shop exists and that the
  mode is `buy` or `sell`. While the list is open `is_in_menu()` is true: the hero stands still and the clock
  with him.
- **Tilda's conversation** (`data/dialogue/shop_tilda.json`) has the eggs she is owed, "Let me see what you
  sell.", "I have things to sell." (it read "crops" until she bought ore) and "Just looking." Her greeting
  says she buys what he grows and what he digs out of the quarry.
- **Tools:** `tools/playtest.gd -- market` starts at her counter with coins and a harvest; `tools/capture.gd`
  has the actions `shop_buy`, `shop_sell`, `shop_ore` (her list with a pack from the quarry) and `meals`.

## 22. The story over days
P4a (`docs/progress/P4-plan.md`). The story is still data; what is new is three small things data may say, a
kind of door, and four flags.
- **The flags** (`StoryGates`, `core/story/`, pure, has their names):
  - `planted_first_crop`: set by `GameState.plant_crop()` the first time a seed goes in.
  - `keep_gate_open`: set by Elder Bram's promise ("I'll keep watch."), with `promised_elder_keep`.
  - `keep_warden_beaten`: as before, set when the Iron Warden falls.
  - `crypt_open`: set by the main quest at the first dawn after the Warden falls.
- **The main quest** (`data/quests/a_place_of_your_own.json`) starts by itself (`auto_start`) and has six
  stages: take what lies in the cottage, plant a seed, hear Elder Bram out, quiet the keep, sleep, end the
  Shade. Each stage's journal says where to go and how. Its conditions are such that a hero further along
  catches up: an old save starts the quest and runs straight to where he is.
- **Elder Bram** (`data/dialogue/elder_bram.json`) has an opening for a hero with no first crop and no Warden
  beaten: a welcome, and what to do first. Otherwise he speaks as before, and his promise unchains the gate.
- **The keep's gate** is `KeepChain` in the Old Wood: a `chained` `DungeonDoor` over the same two cells as the
  exit `KeepGate`, open on `keep_gate_open`. Shut, its cells are solid. `AreaController` says its words when
  the hero steps into the cell before it facing it (`chained_words_in_front()`), as it does for a shop that is
  shut.
- **The crypt's bars** (`CryptBars` in Hearthvale) open on `crypt_open`, not on the Warden's fall. The quest's
  `rest` stage moves on by `{"type": "days_since", "flag": "keep_warden_beaten", "days": 1}`, and its `crypt`
  stage sets the flag. `Quests` hears `EventBus.day_started`, so this happens as he wakes, before the morning's
  save.
- **`days_since`** (`ConditionEvaluator.days_since()`): how many dawns since a flag came true, from the
  snapshot's `day` and `flag_days`. Not true on the day itself.
- **Old saves** are past the gates (section 9, version 4).
- **One chime.** A quest that runs through several stages in one update (an old save catching up) is
  announced at each, but `Quests` chimes once.
- **Words that changed** with the timing: Bram's promise and his tale, Guard Rolf's two answers about the
  chapel door (now on `crypt_open`), the keep's closing words, and the title's line.
- **Tools:** `tools/playtest.gd` has `bram` (in his house, the first crop in), `gate` (below the chained gate)
  and `rest` (by the chapel on the day the Warden fell). A scenario's `flags` are set as of long ago and its
  `today` flags as of that day. The older scenarios start past the gates. `tools/capture.gd` starts the main
  quest before each shot, so its notice is not in every picture (but for `begin`, a game's first moment), and
  has the actions `lights`, `story_log` and `try`.

## 23. Skills
P4b (`docs/progress/P4-plan.md` section 11). Three skills that rise with use and change only energy.
- **The rules are data** (`data/rules/skills.json`, in `docs/data/rules.schema.json`): `levels` (the points
  each level begins at: 0, 10, 25, 50, 90), `step` (0.1: the share a level above the first takes off a cost or
  adds to a dish), and `skills`, each with a `name`, its `gains` (points by deed), the costs it `eases`
  (EnergyRules' names) and whether it `enriches_dishes`.
- **`Skills`** (`core/skills/`, pure) reads them: `level_at()`, `next_at()`, `gain()`, `cost_factor()`,
  `dish_factor()`, `line()` for the pause menu, `risen_words()`, and `problems()` for the load check. It keeps
  no points.
- **`GameState`** holds `skill_points` (saved since version 4). `practise(skill, deed)` adds the deed's points
  and emits `EventBus.skill_rose(skill, level)` when the level rises. `skill_level()`, `energy_cost()` and
  `food_energy()` are what the rest of the game asks.
- **Where points come from:**
  - combat: `AreaController._on_enemy_died()` (a `monster`, or a `boss` for an `ArenaBoss`)
  - farming: `GameState.till_soil()` (`till`) and `harvest()` (`harvest`), and since the Homestead's
    phase 4 `pet_animal()` when it takes a product (`tend`, §30)
  - cooking: the effect `practise`, which `Cooking.dialogue()` gives each dish's answer after its `give_item`
- **What a level does:**
  - combat eases `swing` and `shot`; farming eases `hoe` and `water`. The hoe is paid before the cell is
    tilled, so the stroke that raises farming costs the old price.
  - cooking enriches dishes. A dish is anything a recipe makes (`Cooking.is_dish()`), and the level counts
    when it is eaten (`GameState.eat()` adds `food_energy()`). Hearts are the dish's own.
- **Shown:** `AreaController.pause_status()` has the line `Skills.line()` gives; a rise is a notice at the top
  of the screen and the sound `skill`. `ItemMenu.describe()` and the words on eating say what a dish gives him
  now (`Food.gives_text(item, energy)`).
- **Tools:** `tools/playtest.gd` takes `skills=<level>`; `tools/capture.gd` has the actions `skill_up`,
  `skills_pause` and `cook_menu`.

## 24. Friendship
P4c (`docs/progress/P4-plan.md` section 12). Talking and gifts make friends of the seven villagers.
- **The rules are data** (`data/rules/friendship.json`, in `docs/data/rules.schema.json`): `marks` (5),
  `points_per_mark` (4), `talk` (1), `liked_gift` (3), `other_gift` (1), and `gift_types` (the item types that
  can be given: `food` and `ingredient`).
- **The villagers are data** (`data/villagers/<id>.json`, `docs/data/villager.schema.json`): `name`, `dialogue`
  (the conversation that is theirs), `likes` (item ids) and `thanks` (what they say to a gift they `liked` and
  to any `other`). A villager is known by their conversation, so no scene names one:
  `AreaController.villager_of(talkable)` looks a `Villager` up by its `dialogue_id`. DataRegistry checks that
  no two villagers share a conversation and that everything liked can be given.
- **`Friendship`** (`core/friendship/`, pure) reads the rules: `marks_at()`, `after()`, `gift_points()`,
  `is_giftable()`, `giftable_held()`, and the statics `likes()`, `villager_of()`, `thanks()`,
  `with_gift_answer()`; `problems()` and `villager_problems()` for the load check. It keeps no points.
- **`GameState`** holds `friends` (saved since version 4): villager id to `points`, `talked` and `gift` (the
  days of the last talk and the last gift). `greet()` gives the day's first talk its point; `can_give()` and
  `give_gift()` keep it to one gift a villager a day; `add_friendship()` stops at a full friendship and emits
  `EventBus.friend_mark_gained(villager, marks)` when a mark is reached.
- **Giving:**
  - `AreaController.talk_to()` greets a villager, and if a gift can be given today and he carries one, opens
    a copy of the conversation with the answer "I brought you something." added to the node it begins at
    (`DialogueRunner.opening()`), before its last answer. The data in DataRegistry is never changed.
  - The answer's effect is `gift` (a villager id): `GameState.request_gift()` emits
    `EventBus.gift_requested`, and the area opens the list when the conversation closes, as it does a shop's.
  - `GiftMenu` (`ui/gift_menu.gd`, on the HUD as `gift_menu`) lists `GameState.gifts_held()`; choosing one
    gives it, emits `given`, and closes. The area shows the villager's words as a message. The clock and the
    hero wait while it is open (`is_in_menu()`).
- **Shown:** a mark gained is a notice at the top of the screen and the sound `friend`. The pause menu has
  **Friends** (`FriendsPage`, `ui/friends_page.gd`): every villager by name with `FriendMarks`, a row of five
  blossoms drawn in code like the hearts.
- **Tools:** `tools/playtest.gd -- gifts` starts beside Pip with a pack of food; `tools/capture.gd` has the
  actions `gift_talk`, `gift_list`, `gift_given` and `friends_page`.

- **A gift to a full friendship** (the fix round of 2026-11-16) is still taken and adds nothing.
  `GameState.give_gift()` says so (`"full"` in what it returns: the friendship was full already), and the
  villager answers with `thanks.full` from their file in place of the other two lines. A villager's file
  without that line is refused when the data is checked.

## 25. What friendship opens
P4d (`docs/progress/P4-plan.md` section 13). All of it is data; the code is one condition, one effect and a
field on recipes.
- **The condition `friendship`** (a villager and so many marks) is met when the hero has that many marks with
  them. Points are in the snapshot, but how many make a mark is a rule, so a `ConditionEvaluator` is given the
  rules of friendship: `ConditionEvaluator.for_state(state)` builds one from a state's snapshot and its
  `friendship()`. `DialogueRunner` and `QuestRunner` use it. Without the rules (a stand-in state) no such
  condition is met.
- **Recipes that are taught:** a recipe may say `"taught": true`. `Cooking.known(recipes, flags)` is those
  known from the start and those whose flag `recipe/<id>` is set; the hearth lists
  `GameState.known_recipes()`. The effect `teach_recipe` calls `GameState.learn_recipe()`, which sets the flag
  and emits `EventBus.recipe_learned`; the area shows "New recipe: Berry Jam." as a notice.
- **A villager's conversation holds what their friendship opens,** as `openings` (section 22) on the
  condition, in this order after anything of their own (Elder Bram's welcome):
  - four marks, and the flag `present/<villager>` not set: a node whose `on_enter` gives the present and sets
    the flag
  - two marks, and the favour's quest not started: a node that asks it ("Not just now." goes to their usual
    start); or two marks and the recipe's flag not set: a node whose `on_enter` teaches it
  - three marks, and the favour's quest not started, for the two who teach at two marks (Wenna, Shepherd
    Edda): a node that asks it. It stands after the lesson in `openings`, so a hero who comes to three
    marks untaught is taught first and asked at the next talk.
- **The favours** are quests of one shape: a first stage with two objectives (have the thing; bring it)
  that moves on by a flag, and a `done` stage whose `on_enter` gives the reward. The villager's start node has
  the answer that hands the thing over (it takes it and sets the flag) and one that reminds him what was
  asked. There are seven: Pip's, Guard Rolf's, Farmer Oda's and Elder Bram's (P4d), Old Henrik's
  (Willowmere), and two that want what the quarry gives (mining and crafting, phase 3a): Wenna's "Black
  for the Loom" (five coal; 30 coins and two Cherry Blossom Tea) and Shepherd Edda's "New Shears" (two
  iron bars; 50 coins and a Shepherd's Pie). Rewards are `give_item`, so a full pack loses none of them.
- **Nothing is saved that wasn't before:** a recipe known and a present given are flags, quests are quests.
- **Tools:** `tools/playtest.gd -- late` is the sixth morning with every villager a gift short of two marks;
  a scenario may give a `day` and `friends`. `tools/capture.gd` has `friend:<villager>:<points>` (talk to the
  villager faced with that friendship), `favour:<villager>:<points>` (the same, with the recipes that are
  taught at two marks known already), `long_log` and `new_dishes`.
- **The whole story in one test** (`tests/world/whole_story_test.gd`): a new game through every gate to the
  ending's lines in six days, with a friend made, a favour done and a recipe learned. The two boss fights are
  stood in for by their flags.


## 26. Willowmere
The marsh east of Hearthvale (the user's request, 2026-11-17; `docs/progress/willowmere-plan.md`). Step 1,
the marsh by day, step 2, the Bogwisp, and step 3, Old Henrik, are all built.
- **The map** is baked like the others (`build_maps.gd`, `"willowmere"`): its base is water, and blocks lay
  reeds, land, boardwalks, the hut and the woods over it. Three things are new in the baker, all small:
  - a map may name its `"prop_ground"`, the solid ground its props stand on (the marsh's is `marsh_solid`);
  - block kinds that pick one of several tiles: `boardwalk` lays its planks across the way it runs, `reeds`
    mixes two pictures, `ruin` is fallen roof with the front wall along its bottom row;
  - the scatter of decorations covers the marsh's ground as well as grass.
- **The tiles** are two rows at the end of the atlas (`GreyboxTiles.ROW_MARSH`, `ROW_MARSH_DECOR`), painted by
  `make_tile_texture.gd`: no older tile changed place. `MARSH_KINDS` go on the Height layer (with
  `MARSH_SOLID` and `MARSH_HEIGHTS` for the tileset), `MARSH_DECOR_KINDS` on the Decor layer.
- **The willow** is a tall picture (`SceneryAtlas`, two of them, painted by `make_scenery.gd`): `"willow"`
  blocks in a map become `prop_willow` tiles, which `Scenery` stands up like the cherry trees.
- **The way from Hearthvale:** `MarshWalk` (an `AreaExit`, two cells) in the village's east tree line, and
  `WestWalk` in the marsh; the planks on the east meadow are the Decor layer's `planks`, laid over the
  meadow's own ground, so they need no height of their own.
- **Forage and food** are data: six `ForageSpot` nodes (three new pictures in `forage.png`), three food
  items, one recipe. The heart piece is a `HeartPiece` like the other four.
- **Mist and fireflies:** `Ambience.MISTY` has the marsh; `Ambience.DUSK_FIREFLIES` names the areas whose
  fireflies keep out of sight until the lamps are lit (`Critter.from_dusk`, `is_out()`).
- **The tune** is `marsh` in `make_audio.gd`; `Audio.MUSIC` lists it.
- **Nothing is saved that wasn't before:** the heart piece and the forage are flags.
- **The Bogwisp (step 2)** is an `Enemy` like the others, with three things an enemy's data may now say:
  - `"behaviour": "wisp"` gives it a `WispBrain` (`core/enemies/`, pure): idle, chase, then `flare`
    (still, for the data's half second, with its `aim` fixed as the flare begins), `dart` (along the aim),
    `rest`, and `gone` once `fade()` is called. `take_hit()` refuses unless the brain is `lit`. Its
    `GridBody` is `drifting`: it enters any cell inside the map.
  - `"energy_drain"`: the enemy's `HitBox` carries it (`HitBox.energy`, `Hit.energy`) and the hero spends
    it when a hit lands (`PlayerController._on_hit_taken`), after the hearts.
  - `"appears": "night"`: the area lets it `lie_low()` as it loads by day, calls `rise()` when
    `is_night_outdoors()` turns true while the hero is there (`_on_night_turned`), and `fade()` when it
    turns false. `NightRules.strengthen()` leaves such an enemy alone.
- **Whether light reaches it** is the area's to say: `Enemy.is_lit_at` is `AreaController.holds_at`, which
  asks `LightRules.is_lit()` about `holding_lights()`: the Lantern the hero carries (only if he carries
  one), at `Inventory.light_radius()`. The enemy sets `WispBrain.lit` each frame before the brain thinks.
- **Its light** is drawn like a torch's: `Enemy.glow_now()` is an `Ambience.glow`, stronger and wider
  while it flares, and `glows_now()` adds it. Its picture is three frames in `wisp.png`; with no body it
  is drawn see-through and without a shadow.
- **Its drop** lands where it can be reached: `Enemy.drop_cell()` treats a solid cell (water, reeds) like
  a pit and looks for open floor beside it, else takes the hero's cell.
- **The mist** has a thickness (`Mist.thickness`, eased by `thicken_toward()`); `Ambience.NIGHT_MIST` says
  where the night's is thicker.
- **Old Henrik (step 3)** is data: `data/villagers/old_henrik.json`, `data/dialogue/old_henrik.json`,
  `data/quests/lights_on_the_marsh.json`, `data/recipes/ember_tea.json`, an item, and a `Villager` node in
  the marsh. No code names him.
- **The lanterns:** an area's `lanterns_flag` (an export) names the flag that lights its posts.
  - `lanterns_are_lit()` is that flag; `lanterns_burn()` adds the hours the lamps are lit.
  - Lit, every `prop_marsh_lantern` tile on the Decor layer becomes `prop_marsh_lantern_lit`
    (`Ambience.light_lanterns()`): as the area loads, or at once if the flag comes true while the hero is
    there (`_on_flag_set`).
  - The burning tile is one of `Ambience.TILE_LIGHTS`, lit at dusk like `prop_lamp`, so it glows through
    the same code as the village's lamps.
  - `holding_lights()` adds a `LightRules` light of `Ambience.LANTERN_HOLD` at each `lantern_points()`
    while they burn: a Bogwisp there has a body.
- **Played from the keys:** a scratch script (not in the repository) drove the favour and the fight in a
  real window; `docs/progress/LOG.md` has what it pressed and what happened.

## 27. The Old Quarry
Mining (the user's request, 2026-11-17; `docs/progress/mining-crafting-plan.md`, phase 1). Crafting
(phase 2) is §28; the balance pass (phase 3) is §29.
- **Eleven places.** The mouth is six cells of the North Fields' east tree line (`quarry_rock` and
  `mine_mouth` tiles; `QuarryMouth`, an `AreaExit`). The entrance hall is the area `quarry`; the nine floors
  are the areas `quarry_1` to `quarry_9`, each one screen (20 by 11 cells).
- **Maps from sketches.** A map in `build_maps.gd` may be a `"sketch"`: rows of characters, a cell each,
  laid before its blocks (`#` the base, `~` water, `^` a ledge at height 1, `S` stairs, `T` a timber prop,
  `o` floor with a rock marker, `=` floor with rails, anything else floor). A cave wall with floor to its
  south gets its face tile (`_cave_faces`). The scenes' own nodes (ways in and out, monsters, the lift)
  are in the `.tscn` files, where the letters of the sketch say they stand.
- **The tiles** are two rows at the end of the atlas (`GreyboxTiles.ROW_QUARRY`, `ROW_QUARRY_DECOR`) and a
  sixth spawn marker, `rock`. No older tile changed place.
- **Underground.** `AreaController.underground` makes an area a dungeon for looks and light
  (`Ambience.kind_of`), but the day's clock runs (`clock_runs()`), and an enemy that `waits_for_night()`
  is always out. There is no daylight, so the night's rules never strengthen anything there.
- **Rules, rolls and what is remembered** are three pure classes in `core/mining/`:
  - `MineRules` reads `data/rules/mine.json`: the hall, the floors in order (an area and how many of its
    rocks hold each ore), the lift's stops, and for each kind of rock its blows and what it gives.
  - `MineRolls.roll()` shuffles a floor's rock cells from three numbers (the save's own, the day, the
    floor) and hands out the day's ore, then the ladder to one of the plain rocks left.
  - `MineState` keeps that number and the cells of the rocks broken today, by area; it empties the list
    when asked about another day. `GameState.mine()` holds it (always as of today) and saves it.
- **A rock** is a `Rock` node made from a `rock` marker. `AreaController.roll_rocks()` runs as the area
  loads, before anything is marked occupied: it tells each rock its kind and blows, takes away the ones
  `GameState.is_rock_broken()`, and shows the ladder if its rock is among them. A rock has no hurt box:
  the sword and bombs pass it by.
- **The Pickaxe** is an item of type `tool` whose stats say `"tool": "pick"`. `ToolUse.decide_pick()` says
  whether there is a rock to strike; `AreaController._swing_pick()` spends `EnergyRules.MINE`, strikes,
  and on the last blow calls `_on_rock_broken()`: the rock is marked broken, Mining is practised, and
  what it held is left as an `ItemDrop` in its cell (or the ladder is shown). With the pickaxe in hand a
  left click is the sword's unless he faces a rock (`faces_work()`).
- **The ladder down** is a `LadderHole` (an `AreaExit` that draws itself) added where the day's rock stood.
  The hall has one of its own. Every ladder up is a plain `AreaExit` on a `ladder_up` tile in a wall, and
  leads to the hall: a way up to the floor above would have nowhere certain to arrive.
- **The lift** is a `MineLift` (a `Talkable`) in the hall. Its conversation is built by
  `MineRules.lift_dialogue()` from the stops whose flags are set (`quarry/lift/<floor>`, set by
  `_open_the_lift()` on arriving). Its answers use a new effect, `travel` (`area`, `entry`): GameState
  emits `EventBus.travel_requested`, and the area goes when the conversation closes (`go_to_area()`).
- **A fall** on a floor ends in the hall: an area may name a `fall_area` and `fall_entry`, and `respawn()`
  then travels there with full hearts and the usual words. `save_here()` saves a fallen hero as on his way.
- **A drop he can't carry** stays where it lies: `ItemDrop.collect()` refuses without room, and the area
  tells him once (`ItemDrop.told`). This holds for what monsters drop as well as for ore.
- **The Mining skill** is the fourth in `data/rules/skills.json`: it gains by `ore` (1 point; a plain rock, the deed `rock`, is not in its `gains` since the tuning), eases
  `mine`, and has an `extra_chance` (0.05): `Skills.extra_chance()` is that for each level above the
  first, and `_on_rock_broken()` rolls it for a rock of ore (`AreaController.roll_extra_ore`, which tests
  replace). The pause menu shows two skills to a line (`Skills.lines()`), and is a line taller.
- **Save version 5** adds `mine`: `{ "number", "day", "broken": { area: ["x,y"] } }`. The step from 4 gives
  an old save a number made from the save itself and nothing broken.
- **Pictures and sound:** `rocks.png` (a rock, five ores, the ladder, the lift) and seven item icons from
  `make_sprites.gd`; the tune `mine` and the sounds `pick`, `rock_break` and `lift` from `make_audio.gd`.

## 28. Crafting
Crafting (the user's request, 2026-11-17; `docs/progress/mining-crafting-plan.md`, phase 2). The balance
pass (phase 3: Tilda buys ore and bars, two favours, eight days played) is §29.
- **Recipes are data.** A crafting recipe is a file in `data/crafting/` (cooking keeps `data/recipes/`):
  its `station` (`workbench` or `furnace`), its `tab` at the workbench (`make`, or `place` for what is
  set down on the homestead, §30; `make` if it names none), its `order` on that list, what it `needs`, what it
  `makes` (an item and a count, or a `furnishing` of the hero's home) and an optional `unlock` (an item
  `found`, or a `skill` at a `level`). `Crafting` (`core/crafting/`, pure) says which are known, what is
  missing, why a thing can't be made, and how a need reads beside what he has ("Stone 12 of 20");
  `Crafting.problems()` checks each file as it loads. **A new recipe is data only.**
- **What he has found** is `GameState.found`, a set of item ids, saved as a list. `add_item()` adds to it
  whenever a count goes up, so a recipe that waits on an item stays known when the last of it is sold or
  used. `has_found()` also counts what he carries; a loaded save marks what it carries as found.
- **Making a thing** is `GameState.craft(recipe_id)`: only a workbench recipe he knows, and only if
  `why_not_craft()` is empty. What it needs goes, and what it makes is added to the pack, or (a
  furnishing) the flag `home/<id>` is set. A thing it uses up makes room for one of the same kind. A tool
  made from the one in his hand takes its place there. `EventBus.crafted` says what was made.
- **Furnishings.** `Furnishing` (a `Talkable`) is anything that stands in the cottage: the workbench
  (`always`, there from the start) at cell (9, 3), the furnace (6, 2), the chest (2, 2), the lamp (4, 2)
  and the rug (2..3, 4), each a node with a fixed place in `home.tscn`. Until its flag is set it is not
  drawn, not in the way and not faced. The area marks its cell occupied the moment the flag is set
  (`_on_flag_set`); the rug lies flat and is walked over. The names a recipe may give are listed in
  `data/rules/crafting.json` (`furnishings`). No map was re-baked, and nothing that stood there moved.
- **The workbench's list** is `CraftMenu` (`ui/craft_menu.gd`) on the HUD, opened by
  `AreaController.open_craft()` when the workbench is faced (`talk_to()` asks `Furnishing.opens()`). It
  shows six recipes at a time (`MenuCursor.window_top()`), on two labels in the same place: what can be
  made now on the bright one, what can't on the dim one, so a line is on one and blank on the other
  (`bright_lines()` and `greyed_lines()` say which).
  Under it are the needs of the recipe under the cursor, a need to a line. It stays open for as many
  things as he likes, and a line says what was made or why not. The mouse points, the wheel steps, Tab
  and Esc leave. The hero stands still and the clock stops while it is open (`is_in_menu()`).
- **The furnace** is a `Furnace` (pure) held by `GameState.furnace()`: one load of one thing, lit on a
  day, ready from the next morning, waiting until it is taken out. Its recipes are the crafting recipes
  whose station is `furnace`: three ore and a coal for a bar. `Furnace.dialogue()` builds its
  conversation as `Cooking.dialogue()` builds the hearth's: burning, it says so; burned down, it offers
  what it holds; cold, it lists what he knows to smelt, each answer loading as many as he has the makings
  for (`load_size()`, `furnace_most` at the most: five). The ore and coal go by `take_item` effects, and
  two new effects do the rest: `light_furnace` (`item`, `count`) and `empty_furnace`. The bars are
  *given* (`GameState.give_item()`), so what a full pack can't take is laid at his feet. A burning
  furnace shows its lit picture and is a light (`Furnishing.glow_now()`); the standing lamp is one always.
- **The storage chest** is a `Store` (pure) held by `GameState.store()`: `chest_slots` stacks (24), each
  up to its item's own `max_stack`, and several stacks of one thing if need be. It keeps what stacks, and
  leaves coins, keys and quest things with the hero (`Store.can_hold()`); what a tool holds (the can's
  water, `Inventory.held_in_tools()`) is not in the pack to be put away. `StoreMenu` (`ui/store_menu.gd`)
  shows two lists, the pack and the chest; left and right turn from one to the other, and a line chosen
  moves that stack across, as much of it as there is room for (`GameState.store_put()`, `store_take()`).
  A list a move empties hands the cursor to the other.
- **Wood.** A fallen branch and an old stump are breakables (`data/breakables/branch.json`,
  `stump.json`) on two new spawn markers. A breakable's data may now say `hits` (the blows it takes: a
  stump three) and `"returns": "daily"`: broken, it stays broken until the next morning. The day is kept
  in the flag `cut/<area>/<x>,<y>`, so nothing new is saved. Ten branches and five stumps lie at chosen
  cells of the North Fields, the Old Wood and the South Field (`build_maps.gd`; those three maps were
  re-baked for their markers). The sword cuts them, as it cuts grass.
- **Tool tiers** are items of their own (`copper_hoe`, `iron_hoe`, and so on), made from the tool before
  them. A hoe's or a can's stats may say `reach`: `ToolUse.reach()` and `ToolUse.line()` give the cells
  one use works, from the cell he faces onward. The cell he faces decides whether the stroke is made
  (`ToolUse.decide()`, as before); `AreaController._cells_worked()` adds the cells beyond it that the
  same thing can be done to. Energy and the pour are paid once. A pickaxe's stats may say `fewer_blows`:
  `Rock.strike(fewer)` counts them at each blow, so it is the pickaxe that strikes that matters, not the
  one in hand when he came in.
- **The sprinkler** is an item of type `sprinkler`, on the item bar. `ToolUse.decide()` says whether it
  can be set (tilled soil of the plot with no crop and no sprinkler); `GameState.place_sprinkler()` and
  `take_sprinkler()` change the `Farm` and tell whoever draws it. It lies flat and blocks nothing, a seed
  can't be planted where it stands, and facing it, interact takes it up again (if he has room). In
  `Farm.new_day()`, after the crops have grown or dried and the soil is dry again, each sprinkler waters
  the tilled cells among the four beside it (`Farm.watered_by()`): the morning's water, for tomorrow's
  growth.
- **The Miner's Lantern** is a second item of type `lantern`, with radius 80. Making it uses up the
  Lantern; `Inventory.light_radius()` takes the widest lantern he carries.
- **The save is still version 5.** New in it: `home` (`{ "furnace": { "item", "count", "day" } or {},
  "chest": [{ "id", "count" }] }`), `found` (a sorted list of item ids), and `"sprinkler": true` in a
  cell of `farm`. Furnishings and cut wood are flags. `SaveSystem._v4_to_v5()` gives an older save a cold
  furnace, an empty chest and an empty `found`. A version 5 save from phase 1 has none of the three and
  loads the same way: each is read with a default.
- **Pictures and sound:** `crafted.png` (the workbench, the furnace cold and lit, the chest, the lamp, the
  rug's two halves, the sprinkler), a branch and a stump in `breakables.png` and twelve item icons, all
  from `make_sprites.gd`; the sounds `craft` and `furnace` from `make_audio.gd`. The plan's "ladder" sound
  was not made: the ladder uses the `secret` chime.

## 29. The balance pass
Phase 3 of mining and crafting (`docs/progress/mining-crafting-plan.md`). It added little code: one list
in a shop's data, two favours as data, and a tool that plays the game.
- **Tilda buys ore, bars and crystals:** a shop's `buys` list (§21).
- **Two favours at three marks:** Wenna's and Shepherd Edda's (§25).
- **`tools/play_days.gd` plays eight days in a real window** with real input, from the title screen's
  "New game", on save slot 956 (emptied before and after):
  `godot --path . -s res://tools/play_days.gd -- <output dir> [days=8] [speed=1] [deep] [verbose]`.
  - **It presses, it doesn't call:** keys and mouse buttons go through `Input.parse_input_event` (flushed
    at once, so a key is down in the very step it is pressed). Moving is on the keys, a left click uses
    what is in hand, a right click interacts, the number keys and the wheel choose on the item bar,
    Enter answers, Tab opens the food menu and leaves a list.
  - **It looks at what a player can see:** which cells can be walked (`TerrainQuery.check_move`, a
    breadth-first search over them), where rocks stand and what shows in them, where monsters are and
    what a Bogwisp is doing, what a conversation or a list offers. It never reads where the day's ladder
    is hidden: it breaks plain rocks, the nearest first, until the ladder shows.
  - **What it does in a day:** the plot (till, sow, water at the well, harvest, set sprinklers), Tilda's
    counter (sell, buy bread and seed), the quarry (every rock of ore on a floor, then plain rocks until
    the ladder; the lift; eating when it tires; home when it is spent, late, or has fallen twice), the
    furnace (one load a night) and the workbench (the furnace, the better pickaxes, sprinklers, a copper
    can and hoe).
  - **Monsters:** it swings at what comes into the sword's reach, hunts what it can get to on arriving at
    a floor, steps out of a Bogwisp's line, and with a light runs at a wisp that flares and strikes it
    before it darts.
  - **Where it changes the game's state it logs SETUP** (the Lantern on day 7, which the story gives in
    the crypt), and both lists are in its output.
  - **What it writes:** `days.json` (for each day: energy spent and by what, energy eaten, every item
    and coin that came or went and in what work, rocks broken, each floor visited with what it took and
    gave, skills, touches and falls), `play_log.txt`, and pictures.
  - **`speed=4` is for trying the script out:** more steps a second, each as long as ever. The area sets
    `Engine.time_scale` back to 1 after a hit's freeze, so the tool says its speed again each step.
    `deep` is a trial of the dark floors alone, with a kit handed over.
- **The report** is `docs/progress/mining-balance-report.md`: the eight days, the floors, what the script
  set up or left out, a day in the quarry beside a day on the plot against the plan's first guesses, and
  the numbers it proposes to change.
- **The tuning** (the user's word, 2026-11-17: all three proposals) was data and the tests that carry
  it: Tilda's seven prices in `data/shops/tilda.json`, Mining's `gains` in `data/rules/skills.json`, and
  the coal on floors 4 to 6 in `data/rules/mine.json`. No code changed.

## 30. The Homestead
The user's request of 2026-11-17 (`docs/progress/homestead-plan.md`, approved as written), in five phases.
**Phase 1 is built** (2026-11-18 and 19): the farm and the home's move. **Phase 2 is built**
(2026-11-19): placing things, under "Placing things" below. **Phase 3 is built** (2026-11-19):
buildings, under "Buildings" below. **Phase 4 is built** (2026-11-19): animals, under "Animals" below.
**Phase 5, steps 5a and 5b** (2026-11-19): two favours, under "Balance" below, and ten days played by
`tools/play_days.gd` (`docs/progress/homestead-balance-report.md`).
- **The area `homestead`** (`world/areas/homestead/homestead.tscn`, "Your farm") is a map of 40 by 30
  cells, baked by `tools/greybox/build_maps.gd` from a sketch with a legend of its own (below). Woods two
  deep stand all round it; the ground is level (height 0 everywhere).
  - **The way in** is the lane's west end. In Hearthvale the exit `WestRoad` covers cells (0, 16..17) and
    leads to `homestead` / `east_road`; on the farm `EastRoad` covers (39, 14..15) and leads to `village`
    / `west_road`. He arrives at (38, 14) on the farm and at (1, 16) in the village. For it the village
    was re-baked once: cells (0..1, 16..17) of the west tree line became lane, and the lane was laid over
    (2, 16..17). Nothing else in the village moved.
  - **The road** is rows 14 and 15 from column 20 to the edge, and a path up column 28 to the doorstep at
    (28, 12): twelve cells from where he arrives to his doorstep.
  - **The farmhouse** is (26..31, 8..11), laid with the village's own house tiles (thatch, a
    half-timbered upper floor, a ground floor), with its door at (28, 11): the exit `FarmhouseDoor`, to
    `home` / `door`. `WallRelief`, `Scenery`'s ridge, `WindowGlow` and the chimney's smoke treat it as
    they treat the village's cottages.
  - **The pond** is (4..9, 21..24), water tiles on the Height layer, so `is_water_source()` is true there
    and the can fills. There is no well.
  - **Eleven old trees** stand inside the woods, tall pictures from `Scenery`, each blocking its own cell.
  - **Nothing lives there:** no villagers, monsters, critters or forage spots.
- **The home's move is where two doors lead.** The area `home` is the same scene and the same room, named
  "Your farmhouse"; its `Doormat` leads to `homestead` / `farmhouse_door` (the cell (28, 12), facing
  south). `WorldPaths.HOME_AREA` and `HOME_BED` are as they were, so sleeping, 02:00 and a collapse wake
  him there with no change to any rule of energy or sleep.
  - **The old cottage** in Hearthvale keeps its door (`HomeDoor`, at (8, 14)) and its entry (`home_door`,
    which nothing leads to now). The door names the place `old_cottage`, whose hours in
    `data/rules/hours.json` begin and end together, so `Hours.is_open()` is never true: the cell is solid
    and walking into it or trying it says the place's words.
- **The field** is the `FarmPlot` node at (22, 17): the plot of the farm's rules, 12 by 6 (§20). The
  village's `FarmPlot` node is gone. The plot's own cells (0..5, 0..2) are the old plot, so a saved farm
  needs nothing moved.
- **`Homestead`** (`core/homestead/`, pure) is what the hero has done to his land that is for good: the
  cells he has cleared. `GameState.homestead()` keeps the one (thrown away by `clear()`), and it is the
  save's section `homestead` (§9, version 6).
- **The overgrowth** (step 1b): 145 things stand on the land in a new game, 54 of them on the field.
  The field's clear corner, the road, the path and the row before the farmhouse carry none, and none
  stands behind a tree's crown (`Scenery.hiding()`): twenty of the plan's drawing did, and were moved a
  cell or two when the map was baked.

  | What | A | Cleared by | Blows | Leaves | On the land |
  |---|---|---|---|---|---|
  | Weeds | `Breakable` `weeds` | the sword, a bomb | 1 | 1 fibre | 70 |
  | A bush | `Breakable` `bush` | the sword, a bomb | 2 | 2 fibre | 16 |
  | A fallen log | `Breakable` `log` | the sword, a bomb | 3 | 3 wood | 10 |
  | An old stump | `Breakable` `farm_stump` | the sword, a bomb | 3 | 2 wood | 14 |
  | A rock | `Rock` `rock` | any pickaxe | 2 (plain), 1 | 1 stone | 24 |
  | A boulder | `Rock` `boulder` | the Copper Pickaxe or better | 3 (copper), 2 (iron) | 4 stone | 8 |
  | A great boulder | `Rock` `great_boulder` | the Iron Pickaxe | 3 | 8 stone | 3 |

  - **All of it is data.** The four the sword clears are files in `data/breakables/` whose `returns` is
    `"never"`. The three rocks are kinds in `data/rules/homestead.json`, read by `HomesteadRules`
    (`core/homestead/`, pure): `blows` (counted for the plain pickaxe; a better one takes its
    `fewer_blows` off, as in the quarry), `wants` (the least pickaxe, an item id), `gives` and `count`.
    The same file names the map that is his land (`area`).
  - **Where each stands** is a spawn marker baked from the sketch's letters (the map's `"marks"`). The
    first row of markers was full, so six new ones are a row of their own at the end of the atlas
    (`GreyboxTiles.LAND_MARKER_KINDS`, row 27); a plain rock grows from the quarry's rock marker.
    `AreaController._spawned()` makes a `Rock` of every `ROCK_MARKERS` kind, and a boulder's kind is its
    marker's name.
  - **Cleared for good:** `GameState.clear_debris(area, cell)` records the cell in `Homestead` and emits
    `EventBus.homestead_changed`; `is_debris_cleared(area, cell)` asks. Both answer "no" for any map but
    the land. A `Breakable` that never returns calls the first as it is smashed and asks the second as
    it is made (`is_for_good()`); on the land `roll_rocks()` stands each rock as its kind
    (`_stand_land_rocks()`) and takes away those cleared, and `_on_rock_broken()` clears the cell
    (`_on_land_rock_broken()`) where the quarry marks it broken for the day. No flag and nothing of the
    mine's record is used.
  - **What one leaves** is an `ItemDrop` in its cell, as in the quarry: walked onto, and left lying by
    a full pack.
  - **A boulder and a lesser pickaxe:** `ToolUse.decide_pick(at_rock, too_hard)` says
    `ToolUse.PICK_WEAK` ("It wants a better pickaxe.") and nothing is swung or spent.
    `HomesteadRules.is_too_hard()` compares the `fewer_blows` of the pickaxe in hand with those of the
    one the kind wants.
  - **Nothing is tilled under it:** `ToolUse.decide()` takes `blocked`, and the hoe, the can, a seed and
    a sprinkler at a cell of the plot with something standing on it are all told `ToolUse.CLEAR_FIRST`
    ("Clear this first."). A better hoe's stroke passes over such a cell (`_cells_worked()`).
  - **`AreaController.debris()` and `debris_at(cell)`** are what still stands. Each fills its cell
    (`TerrainQuery.set_occupied`, as every breakable and rock does) until it is cleared.
  - **Pictures:** weeds, a bush and a log in `breakables.png` (the land's stumps wear the countryside's
    stump); a field stone, a boulder and a great boulder in `rocks.png`; fibre in `items.png`. All from
    `tools/art/make_sprites.gd`, added after the frames that were there.
  - **Fibre** is a material (stacks to 50). Nothing uses it until phase 3.
- **A sketch with a legend** (`build_maps.gd`): a map's `"legend"` names the characters that lay a tile
  (`[kind, height]`, a cell each) and every other character leaves the base showing; its `"marks"` name
  the characters that are spawn markers. A sketch without one is read as the Old Quarry's are.
- **Two tunes** (step 1c), made in code by `tools/audio/make_audio.gd` like the rest: `homestead`
  (D major, 92 beats a minute: a plain tune over a walking bass and a broken chord) and
  `homestead_night` (the same tune in long notes at 66, every voice quieter than the game's own night
  tune).
  - **An area may name its own night tune:** `AreaController.night_music`. `tune_now()` gives it out of
    doors after nightfall where the area names one, and the game's `night` everywhere else. Only the
    homestead names one.
  - **The farmhouse plays `homestead`** at every hour (indoors keeps no night, as in the village's
    houses), so the tune doesn't change at his own door by day.
- **Tools** (step 1c):
  - `tools/playtest.gd -- homestead` arrives on the farm by the lane with a sword, all three pickaxes,
    the hoe, the can and seeds; `-- farm` starts on the farm's road above the clear corner.
  - `tools/capture.gd`: the ten shots that stood at the village's plot (110 to 112, 114, 116 to 119,
    129, 153) stand at the field's clear corner under their old numbers. 96 (the cottage's door, with
    the lane's west end) and 115 (the well) are still in the village. Nine new shots, 159 to 167: the
    farm as he arrives, the farmhouse, the locked cottage's words, the pond, a boulder refusing the
    plain pickaxe, the overgrown land, the farm at night, weeds cut on the field, and the field with
    its clear corner. The action `boulder` swings the plain Pickaxe at a boulder (the hero stands
    beside it: from below, he is two cells tall and hides it).
  - `tools/play_days.gd` knows that home is the farmhouse (`TOWARD_VILLAGE`: home, then the homestead,
    then the village) and that the plot is on the homestead (`PLOT_AREA`). It works the cells with
    nothing standing on them, the clear corner, and fills the can at the pond. It does not clear land.
    Two days at `days=2 speed=4` played through with nothing left out.
- **Placing things** (phase 2; the plan's D12 to D19):
  - **A placeable is an item of type `placeable`** (data/items; `docs/data/items.schema.json`). Its
    stats say what it is on the ground: `layer` (`lying` or `standing`); for a lying thing `fills`
    (a path or a floor: it covers its cell and is drawn with a rim); for a standing thing `blocks`
    (true unless said: a gate says false), `joins` (a fence, a gate), `light` (a lamp post: where,
    how far, how strong) and `grows` (a sapling: `mornings` and the `tree` it becomes). Its `icon`
    names a frame of `gameplay/art/placed.png` (`PlacedArt.FRAMES`), which is its picture on the
    ground and on the build bar. `Placement.problems()` checks each as the data loads. **A new
    placeable is data and a picture.** It is no `Inventory.EQUIPPABLE_TYPES`, so it is never on the
    item bar. There are fifteen: three paths, two floors, three flower beds; the fence, the gate, the
    hedge, the lamp post, the bench, and the oak and cherry saplings.
  - **`Placement`** (`core/homestead/`, pure) says whether a thing fits a cell. The area describes the
    cell as a `site` (`Placement.site()`: on his land, ground to stand on, road, doorstep, field,
    debris, what lies and stands there, someone in it, something lying to be picked up) and
    `Placement.why_not(item, site)` gives the first refusal that holds, in the plan's table's order
    and words, or "".
  - **`Homestead` keeps what is set down** on two layers, a cell to one thing of each: `lying_at()`,
    `standing_at()`, `age_at()`, `set_down()`, `take_up()`, `move()`, `placed(layer)`, and `grow()`
    for a morning. It knows nothing of what an item is. **Go through `GameState.set_down(area, cell,
    item_id)`, `take_up(area, cell, layer)` and `move_placed(area, from, to, layer)`**
    (`why_not_take_up()` says why not: nothing there, or no room). The first two move the item
    between the pack and the land; a move goes through no pack and keeps a sapling's mornings. All
    three refuse anywhere but his land and emit `EventBus.homestead_changed`. None asks whether the
    ground fits: that is `Placement`'s, and build mode asks it first.
  - **A lamp post** (`PlacedThing.is_lit()`, `glow_now()`) is lit while the day's lamps are
    (`DayClock.lamps_lit`: 18:30 to 06:30): it draws `<frame>_lit`, and the area adds its glow to
    `glows_now()` with the village lamps' numbers, never flickering. Each is two engine lights (a
    pool and a glow) of the area's fourteen.
  - **A sapling** grows by `GameState.start_next_day()`: `Homestead.grow()` adds a morning to
    everything standing whose item grows (`Placement.growing()`), up to the mornings it takes, and
    `homestead_changed` is emitted if anything grew. `Placement.stage_of()` picks its picture
    (`<icon>`, `<icon>_1`, `<icon>_2`); `Placement.is_grown()` says when it is a tree. Then its
    `PlacedThing` draws nothing and `PlacedThings` stands a tree in its cell with `Scenery.stand()`
    (the code that stands the map's trees, so it sorts and fades as they do), and fells it
    (`Scenery.fell()`) when the sapling's item is taken up or moved away. The item that stands there
    is still the sapling's, so taking it up gives a sapling back.
  - **`PlacedThings`** (`world/areas/placed_things.gd`), a node of the homestead's area, keeps the
    area in step with that on every `homestead_changed`: it draws the lying things flat, just over
    the ground's shading and under everyone; makes a `PlacedThing` (`gameplay/interactables/`) in
    `Interactables` for each standing thing, sorted by depth with the hero; and fills the cell of each
    that blocks (`TerrainQuery.set_occupied`), freeing it when the thing is gone. Nothing else in the
    area changes.
  - **`PlacedArt`** draws a thing: its frame, and for one that joins, a rail toward each neighbour
    that joins too (`<frame>_n`, `<frame>_e`, mirrored for the west, `<frame>_s`); a `<frame>_v` is
    how it stands in a run going north and south (the gate). It mirrors in place itself (it did so
    while `SpriteSheet.draw()` put a mirrored frame a frame's width to the right; that is fixed).
  - **Build mode** is `BuildMode` (`world/areas/build_mode.gd`), a node of the area that only the
    homestead has. `AreaController.open_build()` opens it on the action `build` (B; a pad's left
    stick), when he is free to act; any other area says `Placement.NOT_LAND_WORDS`. Open, it counts
    as a menu (`is_in_menu()`): the hero stands still, the clock stops, the item bar is out of sight.
    - It reads its own input before the area does. The mouse's motion and clicks are turned into a
      cell through the canvas's own transform (`make_input_local`), so the camera's scroll is
      accounted for; the movement keys move the ghost a cell (a held key repeats).
    - `view_cells()` is the cells whose middle the camera shows; `point_at()` clamps to it.
    - `site_at(cell)` builds the site from the area: the grid, the Height layer's path tiles and the
      exits (road), a door tile under an exit (doorstep), the plot, `debris_at()`, the hero's cell.
    - `set_down()` (a left click; the sword's key) and `take_up()` (a right click; the item's key)
      do the work; `step()` and `choose_slot()` choose on the bar (the wheel; 1 to 9); B, Tab and
      Esc `close()`.
    - **The hand** (`BuildBar.HAND`, the bar's first entry): `set_down()` with it lifts what is
      under the ghost (`lifted`: its cell, layer and item; nothing changes yet) and, with a thing
      lifted, moves it to where the ghost is if it fits there (`GameState.move_placed()`), or puts
      it back on its own cell. `take_up()`, another choice, or `close()` lets it go.
    - `words()` is the line the HUD shows: the refusal, or "Fence x12", or what the hand would do;
      `ghost_colour()` is green, red or pale.
    - The ghost is drawn on a canvas layer of its own that follows the camera, under the HUD.
  - **The build bar** is `BuildBar` (`core/homestead/`, pure: the hand and then every placeable
    he carries; the choice as the mode opens and after a thing runs out; stepping) and
    `BuildBarView` (`ui/`, the item bar's own drawing with the hand's picture and a count in every
    other slot). The HUD shows it with a line of words (`AreaHud.show_build()`, `build_words()`,
    `build_refused()`). Longer than nine slots, it moves along with the choice as the item bar does.
  - **The workbench's tabs** (§28): a crafting recipe's `tab` is `make` (or none) or `place`
    (`Crafting.TABS`, `tab_of()`, `of_tab()`); `CraftMenu` shows one tab's recipes at a time, opens
    on "Make", and turns with left and right or a click on a tab's name (`switch_tab()`,
    `show_tab()`, `tab_under()`), as `ShopMenu` turns its lists. The nine recipes of "Place" are
    files in `data/crafting/` named for what they make. `GameState.known_crafts()` and `craft()` are
    as they were: every workbench recipe he knows, of either tab.
  - **Tilda's wares for the land** (§21) are seven more lines of her `sells`: fibre five at a time,
    the hedge, the three flower beds and the two saplings. No code changed for them.
  - **The save is still version 6.** The section `homestead` gains `"lying": { "x,y": item id }` and
    `"standing": { "x,y": { "item": id, "age": mornings } }`, each written only when it has something
    in it and read as empty when it is missing. A thing the game doesn't know, or on the wrong layer,
    is left out as it loads.
  - **Sounds and tools:** `set_down` and `take_up` (`make_audio.gd`); `tools/playtest.gd -- build`;
    capture shots 168 to 176 (`build:<x>,<y>:<slot>` opens the mode with the ghost on a cell and a
    slot chosen; `yard`, `yard_night` and `yard_hand` show a yard hedged, fenced, gated, floored and
    lit; `saplings`; `place_tab`; `shop_land`). The sprite tool's `"made"` frames may be a `"swap"`
    of another frame's colours.
- **Buildings** (phase 3; the plan's D20 to D24, and D29's hay):
  - **A building is a file in `data/buildings/`** (`docs/data/building.schema.json`): its `size`, its
    `door` (a cell of its bottom row) and `room` (the area that is its inside), what it does
    (`fills_can`, `holds`, `keeps`), the `animals` it has room for (phase 4's to read), its upgrade
    (`big`: a name, animals and a look) and its `look`, blocks of the atlas's tiles laid by the map
    baker's own rules (`Buildings.detail()`: roofs with ridge, eaves and gable ends, walls with a
    window every third cell, `well` and `silo` as 2 by 2 pictures, a `chimney` over what is under
    it). **`Buildings`** (`core/homestead/`, pure) reads it: cells, door, doorstep, the cell the ghost
    holds it by (`anchor_of`: its door, or the middle of its bottom row), the cells it fills (a site
    all, a building all but its door), whether it fits (`why_not_at`: each cell and then the doorstep
    asked `Placement.why_not` as a standing thing, the first refusal found), its tiles, and what pulling
    it down gives back (`refund`). `DataRegistry` checks each as it loads (`Buildings.problems()`), and
    that every building has one kit and every kit a building. **A new building is data and pictures.**
  - **A kit** is an item of type `kit` whose stats name its building. It doesn't stack, never goes in a
    chest (`Store.KEPT_OUT`) and is never on the item bar; the build bar shows it among the placeables.
  - **The workbench's third tab, "Build"** (`Crafting.TAB_BUILD`): a recipe there makes a kit (a
    plan) or `{"upgrade": building}`; coins are the need `coin`. `GameState.why_not_craft()` asks
    `Crafting.why_not(..., is_had)`, which refuses what he has as a whole already ("You have one
    already.": a kit in the pack, a site or a building, or an upgrade), and on this tab a plan short of
    something says so by name (`Crafting.short_words()`: "You are short of 40 Stone, 10 Wood and 80
    Coins."). A recipe's `unlock` may be `{"built": id}`: known while that building stands
    (`Crafting.is_known(..., has_built)`; `GameState.is_built()`).
  - **`Homestead` keeps the buildings** (`put_building`, `building_at`, `building_day`, `is_site`,
    `is_standing`, `upgrade`, `is_big`, `move_building`, `remove_building`, `finished_on`) and the silo's
    `hay` (`add_hay`). **Go through `GameState.set_down_kit(area, origin, kit_id)`** (a site with its
    top-left corner at `origin`, today), `GameState.building_covering(area, cell)` and
    `doorstep_of(area, cell)`. `GameState.start_next_day()` finishes what was set down or bought the day
    before: `EventBus.building_finished(id, big)`, `GameState.morning_news` ("The Well stands on your
    farm."), which the area says with the sound `built` where he is or where he next arrives.
  - **In build mode** a kit's ghost (`BuildMode.building_in_hand()`, `building_origin()`) covers every
    cell and the doorstep, washed green or red, with the building's picture and outlines; the words are
    the first refusal. `BuildMode.site_at(cell, except)` says a building's cells are no ground and its
    doorstep a doorstep (all but `except`'s), and that a whole tuft of tall grass is to be cleared first
    (`grass_at`).
  - **`PlacedBuildings`** (`world/areas/placed_buildings.gd`), a node of the homestead's area, keeps the
    area in step on every `homestead_changed`: it draws each building flat on the ground over what lies
    there, with a house's shadow east and south (`BuildingArt`, `gameplay/art/`; HeightShading's
    numbers), raises each roof's ridge as a strip of the area's scenery sorted as the farmhouse's is,
    makes a `BuildingSpot` (`gameplay/interactables/`) in `Interactables` for what the hero faces, and
    fills each building's cells. `fills_can_at(cell)` makes a standing Well water to the can
    (`AreaController.is_water_source`).
  - **The Silo** (`holds`: 60 hay): a right click facing it (`BuildingSpot.use()`) puts in the hay he
    carries (`GameState.put_hay()`), as much as there is room for.
  - **The meadow's tall grass** is the breakable `meadow_grass` (`"returns": "daily"`, one hay lying) on
    a seventh land marker (`GreyboxTiles.LAND_MARKER_KINDS`); the homestead was re-baked for it. A tuft
    whose cell has something set down or a building on it is taken away as the land loads
    (`AreaController._clear_grass_under_things()`).
  - **Rooms** (step 3b): the Coop (4 by 3), the Barn (6 by 4) and the Shed (4 by 3) have a `door` and a
    `room`, the areas `coop`, `barn` and `shed` (11 by 9, baked by `build_maps.gd` like every house's
    inside). Standing, each has an `AreaExit` on its door's cell into its room's entry `door`
    (`PlacedBuildings.door(id)`), and its room's doormat leads to the homestead's entry `<id>_door`, a
    marker `PlacedBuildings.mark_doors()` puts on the doorstep before the hero is placed, and moves with
    the building. A site has neither.
  - **The shed's furnishings** are `Furnishing` nodes of `shed.tscn` with a `room` (`shed`), a `piece`
    (its own name: `chest_a`, `chest_b`) and `keeps` (the key of its furnace or chest): their flags are
    `shed/furnace`, `shed/chest_a`, `shed/chest_b`, made by recipes whose `makes` names a `room`
    (`data/rules/crafting.json` lists each room's furnishings under `rooms`) and which wait on
    `{"built": "shed"}`. `GameState.furnace(key)`, `store(key)`, `light_furnace(item, count, key)`,
    `empty_furnace(key)`, `furnace_dialogue(key)`, `store_put(item, key)`, `store_take(index, key)` take
    an optional key; none is the farmhouse's. `StoreMenu.open(key)`. The furnace's conversation puts
    its key in its effects. Saved in `homestead` as `"furnaces"` and `"chests"`, by key.
  - **Upgrades:** a "Build" recipe making `{"upgrade": id}` (the Big Coop, the Big Barn) calls
    `Homestead.upgrade(id, day)`; the next morning `is_big()` is true, its look is `big`'s, and its
    `animals` are `big`'s (8).
  - **Moving and pulling down** (step 3c; D24): in build mode the hand lifts a building from any of its
    cells (`BuildMode.lifted` has `"building"`), and a left click where it fits moves it
    (`GameState.move_building(area, id, origin)`): at once, for nothing, as it is.
    `BuildMode.site_at(cell, except)` doesn't count the building being moved. A right click on a site
    gives its kit back (`GameState.take_up_site()`); on a building it asks (`BuildMode.asked`) and a
    second pulls it down if `GameState.why_not_demolish(id)` is empty: `GameState.demolish(area, id)`
    gives back `demolish_refund(id)`, half of `building_costs(id)` (the plan's needs, and the
    upgrade's), through `give_item()`.
  - **Tools:** `tools/playtest.gd -- buildings` (the coins, materials and skill for every plan, the
    ground cleared, the farmhouse's chest full of wood and stone) and `-- built` (every building standing
    the morning after); capture shots 177 to 191 (`b:<what>`: the Build tab, a kit's ghost green and
    red, a site, the farm with every building, the coop's doorstep, the well, the silo, the three rooms,
    the shed furnished, the big forms, the shed moved, a demolition and its refund). A shot that points
    in build mode warps the window's own mouse there (`_point`).
  - **Pictures and sound:** atlas rows 28 and 29 (`GreyboxTiles.BUILDING_KINDS`, `SILO_KINDS`: a site, a
    site's timber, the barn's plank wall, loft door and door, the silo's quarters), painted by
    `make_tile_texture.gd` and never laid on a Height layer; the icons `hay` and `kit`; the sound `built`.
  - **The save is still version 6:** `homestead` gains `"buildings"` and `"hay"`, each written only when
    there is something in it. The fixture `tests/fixtures/saves/v6_a_yard_on_the_farm.json` was written
    by the game as it stood at the end of phase 2.
- **Animals** (phase 4; the plan's D25 to D28, D30):
  - **A kind of animal is a file in `data/animals/`** (`docs/data/animal.schema.json`): `lives_in` (a
    building with room for animals), `gives` (an item), `every` (mornings between products, fed and
    petted), `grazes` (cells of pasture grass a morning), `sound`. `DataRegistry.get_animal()`;
    `Herd.problems()` checks each as it loads. **A new animal is data and pictures.**
  - **`Herd`** (`core/homestead/`, pure): an animal on the land is `Herd.new_animal(kind)`, `{ "kind",
    "petted", "progress", "ready", "hungry" }`. `Herd.feed(animals, kinds, pastures, hay)` feeds the
    herd in the order bought, each from its building's pasture while the grass holds, else a hay, else
    nothing (D25); `Herd.morning(animal, kind, fed)` brings a fed one two halves of a morning nearer its
    product if it was petted the day before, one if not, none unfed (and `hungry`), and nothing while a
    product waits (D27). `Herd.why_not_buy()` says why one can't be bought.
  - **`Pasture`** (`core/homestead/`, pure): `Pasture.reach(doorstep, size, kind_of)` is the ground
    reached from a building's doorstep, cell to cell, through `GRASS` and `BARE` cells, stopped by
    `WALL`s; reaching an `OPEN` cell (the road, the path, a way out, off the map) means it isn't
    fenced. `is_pasture()` is fenced with grass in it.
  - **`LandMap`** (pure) is the land as it was: its solid cells, its road, its field and where the
    overgrowth stood. **`LandSurvey.survey()`** (`world/areas/`) reads it from the homestead's scene,
    made and freed out of the tree, once a run (`GameState.land_map()`). `GameState.pasture_kind(cell)`
    lays what he has cleared, set down and built over it: the road is open; what is solid, anything
    standing (a gate too), a building or site, and debris not cleared are walls; the field and what
    lies on the grass are bare; the rest, the meadow's tall grass with it, is grass.
  - **`Homestead` keeps the herd** in the order bought (`add_animal()`, `animals()`, `animal(index)`,
    `animal_count()`); none is ever taken away, so an animal's place in the herd is its name. An animal
    lives in its kind's building, so it goes wherever that building goes.
  - **`GameState`:** `pasture_of(id)`, `has_pasture(id)`, `pastures()` (each pasture with the buildings
    whose doors open on it, so two share one), `animals_in(id)`, `why_not_buy_animal()`,
    `buy_animal()` (and `buy()` of a ware that is an animal), `pet_animal(index)` (petted today, its
    sound, `EventBus.animal_petted`, the product taken if there is room, and the deed `tend` of Farming).
    `start_next_day()` runs the herd's morning (`_herd_morning()`) after the saplings grow, and the
    silo's hay is what is left. `why_not_demolish()` refuses a building with animals.
  - **Oda's stall** is `data/shops/oda.json`, a shop whose wares are `{ "animal", "price" }`
    (`Shop.wares()` gives them with `"animal"`, `Shop.is_animal()`), opened by her conversation's `shop`
    effect; `ShopMenu` names them by the kind and says where one went. The village was re-baked once
    more for it: the market stall's six tiles at (16..18, 30..31), solid, beside her.
  - **In the world:** `PlacedAnimals` (`world/areas/placed_animals.gd`), a node of the homestead and of
    a room whose building has room for animals (the coop, the barn; `AreaController.animals`, null
    elsewhere). On the land, while `Hours.villagers_out()` (06:00 to 20:00), it shows the animals of
    each building with a pasture, among its cells; in a room, the animals living there that are not out
    (all of them by night), among the room's floor (not the doormat or the cell before it). It follows
    `homestead_changed` and `time_changed`, and moves them each frame but while build mode is open.
  - **`Animal`** (`gameplay/interactables/`): its place in the herd, an `AnimalMotion` (`core/homestead/`,
    pure: rest or graze, then walk straight toward a cell within three, never leaving its cells), its
    pictures (the hen is the village's chicken in `critters.png`; the sheep and the cow are
    `animals.png`, 24 by 20, mirrored in place facing right), what it has ready on a round badge over
    its head, three dots in a bubble when it is hungry. It fills no cell. `reached_from(cell)`: it
    stands in the cell, or within 12 px of its middle.
  - **A right click** (`AreaController.interact()`) on the animal the hero faces (`animal_in_front()`,
    after a person and before a door, a chest or a crop) pets it: `GameState.pet_animal()`. The prompt
    is "Pet the Chicken", or "Take the Egg" when one waits.
  - **Build mode** counts an animal's cell as someone's (`Placement.SOMEONE_WORDS`).
  - **Into the rest** (step 4c): the egg and the milk are food (6 and 18 energy), the wool and cloth
    materials; three cooking recipes, known from the start (`fried_egg`, `omelette`, `custard`); Tilda
    buys the egg, the milk, the wool and cloth (8, 30, 40, 100: four lines of her `buys`); two crafting
    recipes on the "Make" tab, `cloth` (2 wool; known once wool is found) and `wool_blanket` (2 cloth;
    known once cloth is found), which makes the furnishing `blanket`, a `Furnishing` that lies over the
    bed (1, 3) in the farmhouse, for show, not solid; and Farming's deed `tend` (1 point a product taken).
  - **Pictures and sound:** seven icons in `items.png` (the egg, wool, milk, cloth and the three
    dishes), `animals.png`, the blanket in `crafted.png`, from `tools/art/make_sprites.gd`; the sounds
    `cluck`, `bleat`, `low` (`make_audio.gd`).
  - **Tools:** `tools/playtest.gd -- animals` (a scenario may name `pens`, `animals`, `ready` and `hay`);
    capture shots 192 to 203 (`a:<what>`, on the farm of `ANIMALS`).
  - **The save is still version 6:** `homestead` gains `"animals"` (a list, in the order bought), written
    only when there is one; a kind the game doesn't know is left out. The fixture
    `tests/fixtures/saves/v6_buildings_before_animals.json` was written by the game at the end of phase 3.
- **Balance (phase 5).**
  - **Two favours at three marks, data only:** Tilda's "Market Day" (`data/quests/market_day.json`: six
    eggs; 50 coins and 2 Carrot Cakes) after her carrot cake at two marks, and Farmer Oda's "A Roof for
    the Flock" (`a_roof_for_the_flock.json`: a coop standing; 60 coins and 5 hay) after his seed wheat at
    two. Each is an opening on `friendship` 3 and four nodes in the villager's conversation, of the shape
    of Wenna's and Edda's. The rewards are `give_item`. There are thirteen quests.
  - **The flag `built/<id>`** (`GameState.built_flag(id)`) is true while building `id` stands
    (`is_built`): set at the morning a site stands (`start_next_day()`), erased when it is pulled down
    (`demolish()`), and put right by `from_dict()` (an older save's buildings get theirs; a flag with no
    building behind it goes). A site never has one, and moving changes nothing. Oda's quest and his
    answer "My coop is built." ask `built/coop`; no new condition type was needed.
- **Tests:** phase 5's `tests/world/homestead_favours_test.gd`; phase 4's `tests/core/homestead/herd_test.gd`, `pasture_test.gd` and
  `animal_motion_test.gd`, `tests/autoload/animals_state_test.gd`, `tests/world/oda_stall_test.gd`,
  `animals_test.gd` and `animal_products_test.gd`; phase 3's `tests/core/homestead/building_rules_test.gd` (`Buildings`),
  `homestead_buildings_test.gd` (what `Homestead` keeps of them), `tests/core/crafting/crafting_build_test.gd`
  (the "Build" tab's rules), `tests/world/plans_test.gd` (step 3a), `rooms_test.gd` (3b) and
  `building_moves_test.gd` (3c); `tests/world/build_mode_test.gd` (build mode in the world), `tests/world/placeables_test.gd`
  (the lamp post, saplings and trees, the hand, the tabs, Tilda's wares, a whole yard), `tests/core/homestead/`
  (`Placement`, `BuildBar`, what `Homestead` keeps), `tests/world/homestead_test.gd` (the map and the walk), `tests/world/home_move_test.gd` (the
  doors, waking, the locked cottage, the version 5 save in the world), `tests/world/debris_test.gd` (the
  overgrowth), `tests/world/homestead_tune_test.gd` (the tunes), `tests/autoload/homestead_save_test.gd`,
  and `tests/core/homestead/` (`Homestead`, `HomesteadRules`). The suites that worked the village's plot work the
  field's clear corner (`PLOT = Vector2i(22, 17)`).
