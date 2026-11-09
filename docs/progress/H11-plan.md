# H11 — Hero & graphics (plan)

Goal (ROADMAP H11, re-planned 2026-11-08 at the user's request): a new hero sprite in a **blue suit**, pixel art
for every actor in place of the placeholder shapes, and better tiles. Still no external assets: everything is
painted in code.

## Design
- **The hero first** (`tools/art/make_player_sprite.gd`, ASCII art, same 3x3 sheet of 16x24 frames so nothing else
  changes):
  - a blue hood and tunic with a gold-trimmed hem
  - more shading
  - a face with two eyes, a hair fringe, a brown belt with a gold buckle, cream trousers, brown boots
  - in side view, an arm that swings with the walk

  The old "Network Key" glow on the belt goes.
- **Then every other actor**, the same way: villagers, slimes, goblin archers, bats, the Iron Warden, pickups and
  items, chests, doors, push blocks, plates and crystals.
  - Each gets a small sprite sheet painted from ASCII art by a tool in `tools/art/`, so the art is edited in one
    place and the nodes just draw frames.
- **Tiles:** a raised-floor dungeon tile instead of the dirt-path ledges, richer floors and walls, and animated
  water (two frames).
- Checked by screenshots before and after, area by area.

## Acceptance criteria (from ROADMAP)
- [x] the hero wears blue
- [x] no placeholder shapes are left
- [x] screenshots of every area read clearly
- [x] tests stay green

## Deliberately not in H11
New animations beyond walking and the existing swing (no idle breathing, no attack poses yet), lighting, new
areas or content.
