# H2 — Sword & hearts (plan)

Goal (ROADMAP H2): the Wooden Sword with an arc swing, hitboxes and hurtboxes; taking damage (knockback,
invincibility, hearts going down), heart pickups, death and respawn; a training dummy.

## Design
- **Hit rules (pure, `core/combat/CombatRules`):**
  - `in_arc`: a target circle within reach, inside a slice pointing the way the hero faces.
  - `circles_touch`: contact between two circles.
  - `push`: the knockback vector, away from the source.
  - `best_melee_weapon`: the strongest sword the hero holds, by its data stats.
  - A `Hit` is damage, a push and a source position.
- **HitBox / HurtBox** (`gameplay/combat/`): circles around a node, each on a team (`hero` or `enemy`).
  - A HitBox can be an arc instead of a full circle (the sword). It hits HurtBoxes of the other team that it
    touches while active; the sword hits each target once per swing.
  - The area resolves contacts every physics frame in code (`resolve_combat`), not with physics Area2Ds. That
    matches the grid-checked movement, and stays deterministic in headless tests.
- **Hero states** (`PlayerMotor`, one script each):
  - `attack`: stands still for the weapon's cooldown, with the sword's arc active.
  - `hurt`: pushed along the hit's knockback at a fixed speed through the terrain rules; can be knocked off a
    ledge, never through a wall.
  - `dead`: lies still.
  - Invincibility: 1 s after a hit, the sprite blinks and further hits are ignored.
- **The sword:** `attack` action (Space / J / gamepad X). It works once the Wooden Sword is in the inventory;
  damage, knockback and cooldown come from `data/items/items.json`. The swing is drawn in code: a blade sweeping
  a 120° arc in front of the hero, with 20 px reach.
- **Damage and death:**
  - Hits cost half hearts (`GameState.damage`).
  - At zero, the hero lies still for a moment, then respawns at the **area entrance** with full hearts and the
    screen flashes. The entrance is where they arrived: the entry point they came through, or the spawn or
    saved cell.
- **Village training yard** (the fenced field):
  - the Wooden Sword lying on the ground (pick it up with E)
  - a training dummy (hit it: it wobbles and flashes; it blocks its cell)
  - brambles (hazard: half a heart and knockback on touch)
  - a recovery heart (touch: +1 heart; back on every visit)

## Acceptance criteria (from ROADMAP)
- [x] the sword hits the dummy only in front of the hero
- [x] touching a hazard costs half a heart with knockback and invincibility frames
- [x] at zero hearts the hero respawns at the area entrance with full hearts

## Deliberately not in H2
Enemies (H3), the bow, bombs and the item button (H4), heart containers and heart pieces, drops from grass and
pots, a death or game-over screen, sword attack frames on the sprite sheet, sound.
