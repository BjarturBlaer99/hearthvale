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

## H9 — Save, menus & playtest ✅
- Title screen, save/load from a menu, pause, settings; fixes from playtesting.
**Done when**: a new player finishes the slice in 30–60 minutes with no developer help.

---

# Phase 2 — From slice to small game (approved 2026-11-08)

Goal: grow the slice into a small, complete game of about **2 hours**:
- it feels and sounds good
- it looks good: a blue-suited hero and pixel art everywhere
- the world we have is richer and more detailed, rather than bigger
- villagers give small quests
- a second dungeon is built around a new item
- a light story leads to an ending

Same rules as the slice:
- Work milestone by milestone, H10 onwards; stop after each and report.
- No external assets. Sound, music and art are made in code, the way the hero's sprite and the tiles already are.
- Change the GDD before adding a mechanic it doesn't describe.

## H10 — Feel & sound ✅
- **Sound effects**, made in code (a small synth in `tools/`, baked to WAV files the way the tiles are baked to a
  PNG):
  - swings and hits; enemies hurt and beaten
  - pickups; doors, chests and keys
  - arrows, bombs, crystals and blocks
  - the Warden's stomp, clink, gaze and fall
- **Music:** a short looping tune each for the village, the countryside, dungeons and the boss, from a code
  sequencer.
- **Juice:**
  - a brief freeze when a hit lands
  - screen shake for bombs and the Warden
  - dust and sparkle particles
- **Settings:** music and effects volume, kept with the other settings.

**Done when**: every action above makes its sound, each area plays its tune and the boss fight its own, volume
settings work and persist, and a playtest says the game feels better, not noisier.

## H11 — Hero & graphics ✅
- **A new hero sprite** with a **blue suit** (hood and tunic, gold trim, belt and buckle), more detail and shading,
  and arms that swing on the walk. Still painted in code from ASCII art. The leftover "Network Key" from the old
  design goes.
- **Pixel art for every actor**, painted in code like the hero, replacing the placeholder shapes: villagers,
  slimes, goblin archers, bats, the Iron Warden, items and pickups, chests, doors and puzzle pieces.
- **Better tiles:** a raised-floor dungeon tile (no more dirt-path ledges), richer walls and floors, and gently
  animated water.

**Done when**: no placeholder shapes are left, screenshots of every area read clearly, the hero wears blue, and
tests stay green.

## H12 — A more detailed world ✅
More to see and do in the areas we have, instead of new ones:
- **Denser, livelier places:**
  - Hearthvale gets a market stall, crates and barrels, a washing line, a well bucket, more fences and paths.
  - Interiors get furnished.
  - The fields and the wood get more props and decoration.
- **Ambient life:** butterflies over flowers, chickens in the village, fireflies in the wood, drawn in code.
- **Grass and pots** to cut and break, with data-driven drop tables (hearts, coins, arrows, bombs), as GDD §5 and
  §8 promise.
- **More villagers** with something to say, and three more heart pieces hidden in the existing areas (four make a
  heart), with a HUD counter.

**Done when**: every outdoor area and interior has new detail in its screenshots; grass and pots drop what their
data says; all four heart pieces can be found; and the map is no bigger than before.

## H13 — Quests ✅
- `QuestRunner` (TECH_DESIGN §7): quests as JSON stages with objectives, using the existing conditions and
  effects. Adding a quest needs no new code.
- Two or three small villager quests with rewards, for example a lost item found in the countryside, or a
  delivery. A bigger quiver or a heart piece are possible rewards.
- A quest log in the pause menu. Quest progress is saved.

**Done when**: each quest starts, advances and finishes from data alone; the log shows where each stands; progress
survives a save; and a new quest can be added by writing only a JSON file.

## Art pass 2 ✅ (user's request, between H13 and H14)
Better graphics, a better-looking hero with better animation, and houses that look more medieval. No new
mechanics, areas or content. Plan and checklist: `docs/progress/art-pass-2-plan.md`.

## H14 — The second dungeon & boss ✅
Built as the **Chapel Crypt**, with the **Lantern** as its item and the **Crypt Shade** as its boss (choices and
reasons in `docs/progress/H14-plan.md` and DECISIONS).

- A second dungeon of 10–14 rooms, entered from somewhere in the existing world (no new region), built around a
  **new item** chosen in this milestone's plan: a boomerang that stuns and fetches, or a lantern for dark rooms
  and torches.
- **Pits** (deferred since H6): falling costs half a heart and puts the hero back at the edge. Blocks can fill
  them.
- A second boss whose weak point needs the new item. The **Iron Sword** (GDD §5) is a reward.

**Done when**: the dungeon can be finished start to end, its puzzles need the new item, the boss can only be
beaten with it, pits work, and the Iron Sword does more than the wooden one.

## H15 — Story, ending & playtest (built; the playtest is still to run)
The story and the ending are in. The "done when" below needs new players: `docs/progress/H15-playtest.md` is the
guide for running it, and what it finds gets fixed afterwards.

- A light story that ties the two dungeons together (still short: GDD §9), told through villagers and signs, and
  a real ending after the second boss.
- Fixes from a full playtest with new players.

**Done when**: a new player finishes the game in about 2 hours with no developer help.

---

## Later (not in phase 2)
A new region and a bigger world (moved out of phase 2 on 2026-11-08: detail first), more dungeons and items, key
rebinding, several save slots.
