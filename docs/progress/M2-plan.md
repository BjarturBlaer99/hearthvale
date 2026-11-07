# M2 — Player & district greybox (plan)

Goal (ROADMAP M2): walk, sprint, climb, drop, wade and swim around a greybox St. Aud, cycle its
water level with a debug key, and see the map change.

## Design
- **Movement is grid-checked, not physics.** A pure `PlayerMotor` (`core/player/`) owns position,
  level, stamina and a small state machine, with one script per state: `ground`, `swim`, `climb`.
  Each step asks `TerrainQuery.check_move()` before the player's leading edge enters a new cell.
  BLOCKED stops 4 px short of the edge (and the player slides along walls); CLIMB starts climbing on a
  firm push; WALK/DROP/SWIM let the player through. Ground vs swim follows the cell under the feet,
  so rising or falling water switches state automatically. `PlayerController` (CharacterBody2D) only
  reads input, steps the motor and draws. Physics collision waits for enemies (M7).
- **8-direction movement:** input snaps to 8 directions with equal speed. Keyboard (WASD/arrows,
  physical keys, so any layout works) and gamepad (left stick, d-pad).
- **Stamina:** sprint drains it and climbing drains it, even while hanging; it regenerates otherwise.
  Running dry mid-climb drops you back down (damaging from 3 levels). Health arrives in M7, so for
  now a damaging fall is reported, not applied.
- **District = one scene.** `world/districts/st_aud/st_aud.tscn` has a `Height` TileMapLayer whose
  tiles carry `height` / `climbable` / `ramp` / `dive_point` custom data (TECH_DESIGN §3.2), a
  `HeightShading` overlay for cliff edges, and a `Water` TileMapLayer redrawn from the current water
  height (shallow light teal, deep dark teal, both translucent so the terrain shows through). It also
  holds the points of interest, the player and the HUD.
- **Greybox tiles** are generated: a script paints a 128×64 PNG (heights 0–7 plain / climbable /
  ramp, plus 2 water tiles) and builds the TileSet. No external art.
- **Layout** is authored as rectangles in `tools/greybox/build_st_aud.gd`, which fills the Height
  layer of the hand-written scene. After that the TileMapLayer is the source of truth and can be
  painted in the editor; re-running the tool overwrites that painting.
- **Debug key** (F2 / gamepad Back, debug builds only) cycles flooded → waist → drained, bypassing
  the solver. It redraws instantly behind a short fade.

## Level-gated places (the acceptance test)
| Place | Where | Reachable on foot only at |
|---|---|---|
| Rooftop door | east wing roof, height 4 | **flooded**: swim to the roof's edge |
| Clinic balcony hatch | clinic roof, height 2 | **waist**: swim to it |
| Subway entrance | plaza, street level | **drained**: walk there |

A test searches the real scene's Height layer from the player spawn, using `check_move()`, at each
St. Aud level, and checks each place is reachable at its level and no other.

## Steps
1. Input actions (`move_*`, `sprint`, `interact`, `debug_cycle_water`) written to project.godot by
   `tools/setup_input_map.gd`; pixel snapping on.
2. Tile texture + TileSet tools; `HeightGridBuilder` reads a Height layer into a `HeightGrid`.
3. `PlayerMotor` + `PlayerGroundState` / `PlayerSwimState` / `PlayerClimbState`, unit-tested.
4. `PlayerController` + scene; `PointOfInterest`; `DistrictHud`; `HeightShading`; `DistrictController`.
5. St. Aud scene + layout bake. It becomes the main scene; the dev smoke scene stays runnable.
6. GameState: `update_player()` (district, cell, height, stamina); `set_water_level()` clears pending
   water so debug cycling keeps the network valid.
7. Tests, then visual check (recorded frames at each level), docs.

## Acceptance criteria (from ROADMAP)
- [x] each water level changes where you can walk
- [x] something is reachable only at specific levels (rooftop door: flooded only; subway: drained only)
- [x] state survives level changes

## Deliberately not in M2
Physics collision and pathfinding (M7), health and fall damage (M7), boats (M3), network nodes in the
world (M4), diving (M5), WaterVisibility entities, Y-sorted tall props, real art.
