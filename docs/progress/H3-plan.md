# H3 — Enemies (plan)

Goal (ROADMAP H3): slime, goblin archer and bat from `data/enemies/*.json`; an AI state machine (idle, wander,
chase, attack, hurt) with the hero's grid-checked movement; drops of hearts and coins.

## Design
- **Data** (`data/enemies/<id>.json`, one enemy per file; `docs/data/enemy.schema.json`):
  - health (sword damage 2 per hit), speed, contact damage and knockback, sight
  - a behaviour id (`hopper`, `archer`, `flier`), an optional `shot` (arrow damage, speed, cooldown)
  - a weighted drop table of `heart`, `item` (coins) and `nothing`
  - DataRegistry validates the fields, the behaviour id, drop types and item references.
- **Movement:** the hero's grid movement moves into a shared `GridBody` (PlayerMotor extends it).
  - Enemies walk by the same rules but never hop down ledges, so they keep to their level.
  - Bats fly: heights and ledges don't stop them; solid tiles and the map edge do.
- **Brains** (`core/enemies/`, pure, seeded RNG): an `EnemyBrain` state machine (idle, wander, chase, attack,
  hurt, dead) with one subclass per behaviour.
  - **Hopper (slime):** hops a tile at a time near home; once it notices the hero (sight) it hops after them,
    lunging when close; gives up when they get far away.
  - **Archer (goblin):** walks near home; once it notices the hero it keeps its distance, lines up along a row or
    column, draws (a visible tell), then shoots an arrow; waits out a cooldown.
  - **Flier (bat):** rests, flits about its roost; once it notices the hero it flies at them in a zigzag and
    swoops when close.
  - Hits cost health and knock the enemy back (briefly unhittable); at zero it dies.
  - `DropTable` rolls the drop.
- **Nodes:**
  - `Enemy`: draws itself; a HurtBox and a contact HitBox on the enemy team, so touching it hurts the hero.
  - `Arrow`: a HitBox that flies straight and stops at solid tiles or on hitting.
  - `ItemDrop`: coins, collected by touch.
  - The area sets enemies up, and collects touch pickups (hearts and coins).
  - Enemies come back on the next visit; nothing about them is saved.
- **South Field** (new greybox area, through the gap at the end of the village's south road):
  - a meadow with slimes and a pond
  - a plateau with stairs, where a goblin archer patrols (tests that enemies keep to their level)
  - an old stone ruin where bats roost

  `AreaExit` gains a size, so the four-cell road gap is one exit.

## Acceptance criteria (from ROADMAP)
- [x] each enemy patrols, notices, attacks and can be beaten
- [x] drops follow data
- [x] enemies respect cliffs, ledges and solid tiles

## Deliberately not in H3
The bow, bombs, the shop and spending coins (H4), the rest of the countryside (H8), dungeon rooms (H5), the
boss, sword-deflecting arrows, enemy sounds and sprites.
