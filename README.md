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
| Talk / read / pick up | E | A |
| Choose an answer | W / S or arrows, then E | d-pad, then A |

Read the sign in the square, then walk into a door: Elder Bram lives in the blue-roofed house, Wenna the weaver
in the house west of the road. Take the stairs up to the chapel on the north rise, or to the meadow in the east;
hop down a ledge to come back. Combat, enemies, items and dungeons arrive milestone by milestone
(`docs/ROADMAP.md`).

## Docs
- `CLAUDE.md` — rules for Claude Code
- `docs/GDD.md` — game design
- `docs/TECH_DESIGN.md` — architecture
- `docs/ROADMAP.md` — milestones H0–H9 (vertical slice)
- `docs/data/` — example content files and the condition/effect vocabulary
- `docs/DECISIONS.md`, `docs/progress/` — running records

The project started as a water-level game called *Low Tide*; that version is kept on the `water-version` branch.
