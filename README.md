# Low Tide

2D top-down open-world RPG: Fallout-style factions and choices + Zelda-style exploration and tools, set a century
after a catastrophic flood. Changing the water level changes the world.

## Getting started with Claude Code
1. Install Godot 4.x (latest stable) and make sure `godot` is on your PATH.
2. `git init` in this folder and commit these docs.
3. Run `claude` here and say: **"Read CLAUDE.md and the docs, then start milestone M0."**
4. After each milestone, review `docs/progress/LOG.md`, play the build, commit, then ask for the next one.

## Playing the current build
Run `godot --path .` to start in the greybox St. Aud district.

| Action | Keyboard | Gamepad |
|---|---|---|
| Move (8 directions) | WASD / arrow keys | Left stick / d-pad |
| Sprint (uses stamina) | Shift | LB or L3 |
| Use what you're standing on · board the boat · go ashore | E | A |
| Cycle the water level (debug builds) | F2 | Back / Select |

Walk into a climbable (ivy) wall to climb it; walking off a ledge drops you.

**The boat:** stand next to it (or swim beside it) and press E to board. It steers toward the direction you
press. Press E again to go ashore. Sail off the edge of a district to reach the open sea, then sail into a
marked approach to visit St. Aud, Spire Nine or Greenterrace. If the water's too low for the boat, it waits at
sea off the district's harbour (the anchor): walk there and press E to board it.

## Docs
- `CLAUDE.md` — rules for Claude Code
- `docs/GDD.md` — game design
- `docs/TECH_DESIGN.md` — architecture
- `docs/ROADMAP.md` — milestones M0–M11 (vertical slice)
- `docs/data/` — example content files and the condition/effect vocabulary
- `docs/DECISIONS.md`, `docs/progress/` — running records
