# H7 — The first dungeon & boss (plan)

Goal (ROADMAP H7): the keep, 8–12 rooms using H5/H6, the bow as its item, a boss whose weak point needs the bow,
and a heart container. Pillar 2: find the item inside, learn it on its puzzles, then need it for the boss.

## Design
- **The Old Keep** (`world/areas/keep/`, dungeon id `keep`): ten 15x11 rooms on a 3x4 grid; the top-middle and
  top-right slots are solid rock. Until H8 builds the countryside, a path through a gap in the woods at the top
  of the village's north rise leads to the keep's door.

  | Room | What it holds | Way on |
  |---|---|---|
  | (1,3) Entrance | two slimes | north door locked (small key 1); east wall cracked (bombs, optional) |
  | (0,3) Guard room | slimes and a bat | beating them lifts the shutter on small key 1's alcove |
  | (2,3) Old store | 50 coins, behind the cracked wall | optional |
  | (1,2) Great hall | slimes, a goblin archer, pillars | west open; east locked (small key 2); north the boss door |
  | (0,2) Plate room | two plates and a push block | both plates at once (hero on one, block on the other) lift the north shutter |
  | (0,1) Armoury | **the Bow** and 15 arrows in chests | a crystal on a ledge, out of sword reach, lifts the north shutter: shoot it |
  | (0,0) Gallery | two goblin archers on a raised walkway | shoot them down; that lifts the shutter on small key 2's alcove |
  | (2,2) Twin crystals | bats; one crystal on the floor, one on a ledge | both crystals lift the north shutter |
  | (2,1) Big key room | archer and slimes | beating them lifts the shutter on the big key's alcove |
  | (1,1) Warden's hall | **the boss** | beaten: a heart container appears and the way out opens |

- **The boss, the Iron Warden** (`data/enemies/iron_warden.json`, behaviour `warden`): a hulking suit of iron
  with one eye in its visor. `WardenBrain` (pure) is a state machine:
  1. **Guard:** stomps toward the hero. The sword, arrows and bombs clink off its iron.
  2. **Gaze:** stops and opens its eye (the tell). An arrow in the eye stuns it. If nothing hits the eye in time,
     it fires a bolt at the hero.
  3. **Stunned:** slumped; now the sword, arrows and bombs hurt it.
  4. At half health it rages: it stomps faster and fires three bolts at once.

  It stays in its room (an arena rect), and starts over (full health, home) whenever the hero leaves the room. If
  the hero has no arrows when its eye opens, five arrows fall into the room, so the fight can't strand anyone.
- **Bosses stay beaten:** an Enemy with `stays_beaten` doesn't come back once its `clear_flag` is set (saved).
- **Heart container** (`HeartContainer`): appears when its flag is set (the boss beaten), is taken by touch, adds
  a heart and refills them all, and is gone for good.
- **Shutters can stay open** (`stays_open`): once their flags are met they open for good, so a solved puzzle
  stays solved.
- **Blocks reset when the hero leaves their room** (H6's known issue): a block jammed in a corner is back in place
  on the way back in.
- **Drops from a raised enemy fall to the ledge's foot**, so archers shot off the gallery drop where the hero can
  reach. Goblin archers can now drop arrows.
- The Bow and its arrows leave the South Field ruin (H4's stand-in); the shop still sells arrows.

## Acceptance criteria (from ROADMAP)
- [x] the dungeon can be finished start to end (a test walks every gate in order)
- [x] beating the boss adds a heart

## Deliberately not in H7
The countryside (H8), pits, boss music or a health bar, more boss phases, a map or compass, keys carried out of the
dungeon.
