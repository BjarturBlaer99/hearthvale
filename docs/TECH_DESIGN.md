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
| `data/breakables/` | one breakable (grass, pot) per file |
| `data/recipes/` | one recipe per file: what a dish needs and what it makes |
| `data/crops/` | one crop per file: how long it takes, its seed, what it gives, its prices |
| `data/shops/` | one shop per file: its wares and prices, whether it sells seeds and buys crops |
| `data/rules/` | one set of rules per file: the numbers a system runs on (`time.json`: the day's clock; `energy.json`: the hero's energy; `hours.json`: who is where when; `night.json`: what the night does to monsters; `farm.json`: the hero's plot) |

DataRegistry validates required fields and resolves every cross-reference at load. A set of rules must be one
the game knows (`RULE_SETS`), and is checked by the class that reads it (`DayClock.problems()`,
`EnergyRules.problems()`, `Hours.problems()`, `NightRules.problems()`, `Farm.problems()`). A tool item is
checked by `ToolUse.problems()`.

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
  unchanged; E no longer does anything. The buttons are buttons, not a pointer: where a click lands doesn't
  matter, and the hero acts on what he faces.
  - **What is in hand** is `AreaController.use_hand()`'s to say. With nothing on the item button: the sword.
    A weapon there (the bow, bombs): that weapon, until it has nothing left to shoot or set down
    (`GameState.is_out_of_ammo()`); then the click is the sword's again, so running out is no dead end (Q
    still says "Out of arrows."). A farm tool or a seed: the tool when he faces what it is for
    (`faces_farm_work()`: a cell of his plot, or water), where it works or says why not; anywhere else the
    sword, so a hoe in hand doesn't leave him unarmed. With no sword at all the tool says what it is for.
  - **The sword can be taken in hand again** from the item menu: when he holds something for the item button,
    or something used up is still on it (the last bomb gone), the menu lists his best sword first, and
    choosing it empties the item button (`GameState.equip(&"")`). Tab or Esc leaves the menu, as any list.
  - Every menu takes either click as its yes (`MenuInput.is_confirm()`: interact, use_hand or Enter).
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
- **Volume:** `SettingsData` adds music and sound volume (0–10, default 7). `Audio` sets each bus (0 mutes).

## 14. Sprites
- **Every actor is pixel art painted in code**, like the hero. The art lives as ASCII in `tools/art/`:
  - `make_player_sprite.gd`: the hero, brown-haired with his blue hood down, a blue tunic with a gold hem and a
    red scarf. Three rows (down, up, side; right is the side row mirrored) of twenty-one 16x32 frames.
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
  - A negative width mirrors it (side views face left).
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
- **Home and sleep (P2b):** `home` is an area like the other houses (the thatched cottage's inside; its door is
  an `AreaExit` in the village). The bed is a `Bed` (`gameplay/interactables/`), a `Talkable` on the bed's
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
- **The tune:** `AreaController.tune_now()` is the area's `music`, or `NIGHT_TUNE` when `is_night_outdoors()`.
  `_play_tune()` asks for it at load and on `time_changed`, but only when it is another than the one it last
  asked for, so a boss's tune is left alone.
- **Sounds:** `eat` (eating), `collapse` (as he falls), `morning` (a cock-crow: after sleeping, and when he
  wakes at home after a day that ran out).
- **Tools:** `tools/capture.gd` has the action `shut` (the hero tries the shop's door at 19:00).

## 20. Farming
- **The farm's rules are data** (`data/rules/farm.json`): the plot's size in cells (6 by 3) and how many dry
  mornings wither a crop (3b). What hoeing and watering cost is in the energy rules (`hoe`, `water`).
- **`Farm`** (`core/farming/`, pure) is the plot: which cells are tilled and which watered. Cells are the
  plot's own ((0, 0) is its north-west corner), so the plot can lie anywhere. `till()` and `water()` return
  whether they did anything; `new_day()` dries the soil and leaves it tilled; `to_dict()` and `load_saved()`
  are its save.
- **`GameState.farm()`** keeps the one farm (made from the rules when first asked for, thrown away by
  `clear()`). `till_soil()` and `water_soil()` change it and emit `EventBus.farm_changed`;
  `start_next_day()` calls `new_day()`, so sleeping, collapsing and staying up all dry the soil.
- **`FarmPlot`** (`world/areas/`) is the plot as it lies in an area: a node at the plot's north-west corner
  (Hearthvale's is at cell (12, 18), between the shop and the well). It draws each cell from
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
- **Tools:** `tools/playtest.gd -- farm` starts on the road by the plot with both tools and seeds of every
  crop; `tools/capture.gd` has the actions `farm`, `hoe`, `fill`, `tools_menu`, `crops` (a plot in the
  middle of a season), `plant` and `seeds_menu`.

## 21. The shop
- **A shop is data** (P3c; `data/shops/<id>.json`, schema `docs/data/shop.schema.json`): `name`, `sells` (its
  own wares: an item, how many a deal gives, the price), `sells_seeds` and `buys_crops`. Seed prices and what
  a crop sells for are in `data/crops`, so a new crop is on both lists without touching the shop. There is
  one shop, `tilda`.
- **`Shop`** (`core/shop/`, pure) says what is on each list: `wares(shop, crops)` (her own wares in order,
  then a seed of every crop, cheapest first) and `offers(shop, crops, stacks)` (the harvest he carries, with
  how many and the price of one). `why_not_buy()` and `why_not_sell()` say why a deal can't be made: not
  enough coins, no room for all a deal gives, a full purse. `problems()` is run by the registry on every shop.
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
  sell.", "I have crops to sell." and "Just looking."
- **Tools:** `tools/playtest.gd -- market` starts at her counter with coins and a harvest; `tools/capture.gd`
  has the actions `shop_buy`, `shop_sell` and `meals`.

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
  - farming: `GameState.till_soil()` (`till`) and `harvest()` (`harvest`)
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
- **The four favours** are quests of one shape: a first stage with two objectives (have the thing; bring it)
  that moves on by a flag, and a `done` stage whose `on_enter` gives the reward. The villager's start node has
  the answer that hands the thing over (it takes it and sets the flag) and one that reminds him what was
  asked.
- **Nothing is saved that wasn't before:** a recipe known and a present given are flags, quests are quests.
- **Tools:** `tools/playtest.gd -- late` is the sixth morning with every villager a gift short of two marks;
  a scenario may give a `day` and `friends`. `tools/capture.gd` has `friend:<villager>:<points>` (talk to the
  villager faced with that friendship), `long_log` and `new_dishes`.
- **The whole story in one test** (`tests/world/whole_story_test.gd`): a new game through every gate to the
  ending's lines in six days, with a friend made, a favour done and a recipe learned. The two boss fights are
  stood in for by their flags.

