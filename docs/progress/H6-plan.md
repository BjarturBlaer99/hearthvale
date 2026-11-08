# H6 — Puzzles (plan)

Goal (ROADMAP H6): push blocks, pressure plates, switches (sword or arrow) and cracked walls (bombs). One room per
mechanic, and one room that combines two mechanics with more than one solution.

## Design
- **Rules** (`core/puzzles/PuzzleRules`, pure):
  - when a block can be pushed: the next cell is open floor at the same level, nobody's in it, and it isn't the
    room's border, so a block can never jam a doorway
  - when a plate is pressed: the hero or a block on it
  - when a shutter waiting on several flags opens: any of them, or all
- **Hit kinds:** a `Hit` says what dealt it (`sword`, `arrow`, `bomb`, `contact`). Switches react to the sword,
  arrows and bombs; cracked walls only to bombs.
- **Pieces** (`gameplay/puzzles/`):
  - **Push block:** stands in its cell. Hold a direction against it for a moment and it slides one cell, if
    PuzzleRules allows.
  - **Pressure plate:** sets its flag while pressed. A latching plate stays pressed once stepped on.
  - **Crystal switch:** a hit sets its flag (or toggles it), and the crystal turns from red to blue.
  - **Cracked wall:** a new DungeonDoor kind, a bombable wall; a blast opens it for good.
- **Shutters** can wait on several flags (`open_flags`, any of them by default), so one room can have two
  solutions.
- Blocks go back to where they started on the next visit; plates, switches and walls are flags, so they stay
  solved.
- **The Cistern:** a five-room puzzle dungeon down a stairway in the Ruin Cellar's inner room.
  1. **Push block:** a row of pillars, with a block in the only gap.
  2. **Pressure plate:** a latching plate lifts the east shutter.
  3. **Switch:** a crystal in a pillar nook, hit with the sword or an arrow, lifts the north shutter.
  4. **Cracked wall:** bomb the west wall.
  5. **Combined:** the treasure shutter opens if a block is pushed onto the plate, or if the crystal on a raised
     platform (out of sword reach, no stairs) is shot with an arrow.

## Acceptance criteria (from ROADMAP)
- [x] one room per mechanic works
- [x] one room combines two mechanics with more than one solution

## Deliberately not in H6
The keep and its boss (H7), pits and blocks falling into them, ice, torches, timed switches, puzzle hints.
