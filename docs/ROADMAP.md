# Hearthvale — Roadmap

Goal: a **vertical slice**: Hearthvale, the countryside beyond it, and the first dungeon with its boss. It
should prove that exploring, fighting and solving puzzles is fun. Everything uses placeholder art.

Milestones are **H0–H9** (the earlier M1–M4 in `docs/progress/LOG.md` belong to the abandoned water-level
design, kept on the `water-version` branch). Work in order; stop after each and report against its acceptance
criteria.

---

## H0 — Land reset ✅
Water, boat, sea and Network Key removed; land-only terrain (stairs, one-way ledges, solid tiles); hearts in
GameState and on the HUD; the Hearthvale village greybox as the start.
**Done when**: tests green; the game starts in the village with 3 hearts; stairs and ledges work; buildings are solid.

## H1 — Village life ✅
- Doors into house interiors and back (area transitions with entry points; GameState remembers the area).
- Villagers with data-driven dialogue (DialogueRunner + text box), signs to read.
**Done when**: you can enter two houses and come out the same door; a villager's dialogue (with a choice that sets
a flag) plays from data; the flag survives leaving the area.

## H2 — Sword & hearts ✅
- The Wooden Sword (picked up in the village), an arc swing, hitboxes and hurtboxes.
- Taking damage: knockback, brief invincibility, hearts going down; heart pickups; death and respawn.
- A training dummy to hit.
**Done when**: the sword hits the dummy only in front of the hero; touching a hazard costs half a heart with
knockback and invincibility frames; at zero hearts the hero respawns at the area entrance with full hearts.

## H3 — Enemies ✅
- Slime, goblin archer and bat from `data/enemies/*.json` (health, speed, damage, behaviour, drops).
- An AI state machine (idle, wander, chase, attack, hurt); grid-checked movement like the hero's.
- Drops: hearts and coins.
**Done when**: each enemy patrols, notices, attacks and can be beaten; drops follow data; enemies respect cliffs,
ledges and solid tiles.

## H4 — Items & weapons ✅
- Inventory and equipment: one item on the item button, an item menu.
- Bow and arrows (ammo), bombs (fuse, blast); coins and the village shop.
**Done when**: arrows and bombs hurt enemies and run out; the shop sells them for coins; the equipped item survives
a save.

## H5 — Dungeon framework ✅
- Rooms with a camera per room and doors between them; small keys and locked doors; the big key and boss door;
  shutter doors.
- Dungeon state (opened doors, keys held, chests opened) in GameState.
**Done when**: a three-room test dungeon needs a small key to progress, remembers opened doors after leaving, and
the boss door needs the big key.

## H6 — Puzzles ✅
- Push blocks, pressure plates, switches (sword or arrow), cracked walls (bombs).
**Done when**: one room per mechanic works, and one room combines two mechanics with more than one solution.

## H7 — The first dungeon & boss ✅
- The keep: 8–12 rooms using H5/H6, the bow as its item, a boss whose weak point needs the bow, a heart container.
**Done when**: the dungeon can be finished start to end; beating the boss adds a heart.

## H8 — The countryside ✅
- Fields and forest between Hearthvale and the keep, enemies, a secret or two, a heart piece.
**Done when**: you can walk from the village to the keep and back, with at least one optional secret.

## H9 — Save, menus & playtest
- Title screen, save/load from a menu, pause, settings; fixes from playtesting.
**Done when**: a new player finishes the slice in 30–60 minutes with no developer help.

---

## After the slice (not now)
More dungeons and items, heart pieces everywhere, a bigger world, real pixel art and audio, a story.
