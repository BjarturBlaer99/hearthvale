# Hearthvale

A 2D top-down action-adventure in the style of *A Link to the Past*: start in a small medieval village, explore
the countryside, and delve into dungeons full of enemies and puzzles. Find new weapons, and grow from three hearts
into a hero.

## Getting started with Claude Code
1. Install Godot 4.x (latest stable) and make sure `godot` is on your PATH.
2. Run `claude` here and say: **"Read CLAUDE.md and the docs, then start the next milestone."**
3. After each milestone, review `docs/progress/LOG.md`, play the build, commit, then ask for the next one.

## Playing the current build
Run `godot --path .` to start in Hearthvale.

| Action | Keyboard | Gamepad |
|---|---|---|
| Move (8 directions) | WASD / arrow keys | Left stick / d-pad |
| Sprint (hold) | Shift | B |
| Talk / read / pick up | E | A |
| Choose an answer | W / S or arrows, then E | d-pad, then A |
| Swing the sword (once you have it) | Space / J | X |
| Use the equipped item (bow, bombs) | Q / K | Y |
| Item menu (choose what's equipped) | Tab / I | Back |

Read the sign in the square, then walk into a door: Elder Bram lives in the blue-roofed house, Wenna the weaver
in the house west of the road. The Wooden Sword lies in the fenced training yard south-west of the square, next
to a straw dummy to practise on. Mind the brambles (half a heart each touch); the red heart heals. At zero hearts
you wake up back where you entered the area. Take the stairs up to the chapel on the north rise, or to the meadow
in the east; hop down a ledge to come back.

Follow the road south out of the village to the **South Field**:
- slimes hop about the meadow
- a goblin archer guards the plateau (take its stairs, and watch for it drawing its bow)
- bats roost in the old ruin

Beaten enemies sometimes drop hearts or coins.
- **Bow:** for now it lies in the South Field's ruin, with ten arrows. It moves into the first dungeon later.
- **Tilda's shop:** the red house beside the training yard. She sells ten arrows for 5 coins and three bombs for 8.
- **Bombs:** set one down, step back, and it blows up enemies nearby.
- **The Ruin Cellar:** a three-room test dungeon down the stairway in the ruin.
  - A chest in the entry hall holds the small key for the locked door.
  - Beat the hall's slimes to lift the bars on the big key's alcove.
  - The big key opens the boss door. Doors and chests you open stay open.
- **The Cistern:** five puzzle rooms down a stairway in the cellar's inner room.
  - Push the sandstone block (walk into it and keep pushing), stand on the plate, and hit the crystal.
  - Bomb the cracked wall.
  - The treasure room has two ways in: a block on the plate, or an arrow into the crystal up on the platform.
- **The road north:** from the top of the north rise, through the woods.
  - **The North Fields:** a stream with a bridge, a farm plot, slimes, and a goblin archer on a plateau. Keep an eye
    on the tree line beside the road.
  - **The Old Wood:** a road winding between clearings, up to the keep's gate. There's an old walled shrine with
    something inside, and one stretch of its wall looks cracked.
- **The Old Keep:** the first real dungeon, at the top of the Old Wood.
  - Ten rooms: small keys, a room with two plates (stand on one, push the block onto the other), and crystals.
  - **The Bow** is in its armoury; goblin archers on a walkway have to be shot down.
  - The big key opens the Iron Warden's hall. Blows clink off its iron: wait for its eye to open, put an arrow in
    it, then use your sword while it's stunned.
  - Beat it for a heart container, and the way out opens behind it.

Next: a title screen, saving from a menu, and playtesting (`docs/ROADMAP.md`).

## Docs
- `CLAUDE.md` — rules for Claude Code
- `docs/GDD.md` — game design
- `docs/TECH_DESIGN.md` — architecture
- `docs/ROADMAP.md` — milestones H0–H9 (vertical slice)
- `docs/data/` — example content files and the condition/effect vocabulary
- `docs/DECISIONS.md`, `docs/progress/` — running records

The project started as a water-level game called *Low Tide*; that version is kept on the `water-version` branch.
