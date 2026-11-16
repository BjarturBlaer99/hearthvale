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

- A light story that ties the two dungeons together (still short: GDD §11), told through villagers and signs, and
  a real ending after the second boss.
- Fixes from a full playtest with new players.

**Done when**: a new player finishes the game in about 2 hours with no developer help.

---

## Art pass 3 (user's request, after H15): step 1 ✅
A warmer, softer look, everywhere at once: colour and outlines. No new mechanics, areas or content. Later steps
(bigger trees, richer ground, the menus' look, the villagers) only if wanted. Plan and checklist:
`docs/progress/art-pass-3-plan.md`.

---

# The pivot (P1–P4)
On 2026-11-12 the user changed the game's direction: a story-driven RPG with survival and farming, in a modern
pixel-art look, with cherry blossom trees in the village. The audit, the options and the nine decisions the user
approved are in `docs/progress/pivot-plan.md`. H15's "done when" (a new player finishes in about two hours) is
replaced by P4's.

Rules for every step: the architecture stays (pure logic with tests, thin scenes, state in `GameState`, signals
on `EventBus`, content as JSON); no external assets; a save format change needs a version and a migration; each
step ends with tests green, a commit, screenshots and a stop.

## P1 — Visual overhaul
A modern, cosy pixel-art look of the game's own. **No collision or hitbox changes**, except the cells of the new
cherry trees, which are listed and approved before they are baked. Every area is photographed before and after.

- **1a — The frame.** 640x360 on the same 16-pixel grid; indoors and in dungeons the camera shows the room at
  twice the size; every screen laid out again; a HUD with room for hearts and an energy bar (hidden until P2);
  window sizes of 2x, 3x and 4x.
  **Done when**: every area and screen fits the new frame, rooms sit in the middle at twice the size, and all
  earlier tests pass.
- **1b — Light.** One ambient colour per area and a real light at each lamp, hearth, candle, torch, crystal and
  the lantern, in place of the glow sprites and the show-only gloom; soft shadows. The crypt's dark stays a rule
  (`LightRules`), drawn with the same lights.
  **Done when**: what the crypt's rule says is lit is what is drawn lit, and the frame cost is measured.
- **1c — Ground and nature.** A new palette and selective outlines; terrain; tall trees the hero walks behind;
  cherry blossom trees with drifting and settled petals; wind in grass, leaves and cloth; water with ripples,
  foam and reflections; mist in the Old Wood.
  **Done when**: the hero is never hidden behind a tree, and reachability is unchanged but for the listed cells.
- **1d — Buildings, interiors and dungeons** in a taller three-quarter view.
- **1e — Characters.** The hero taller, hood down, with six-frame walk and run and a drawn three-frame attack;
  idle animations for villagers and animals (villagers breathe and blink; a chicken standing still blinks);
  enemies in the new palette (theirs since 1c; not redrawn).
  **Done when**: swing timing, hits, speed and collisions are untouched.
- **1f — UI polish.** Frames, a second larger letter face for headings, the title screen; and the HUD's corner
  slimmed (carried over from 1a, where it covered the corners of dungeon rooms).

## P2 — Energy, food and time
Energy apart from hearts (GDD §5); food and cooking at the hearth; a day of 14 real minutes with light that
follows the hour; sleeping ends the day, refills and saves; shop and villager hours; tougher monsters at night;
the hero's home (the thatched cottage, a door and a one-room interior). The HUD shows hearts, energy, the clock
and the day. Save version 2, with a migration from version 1.
**Done when**: the energy rules, food effects, recipes and the clock are unit-tested, an old save loads, and a
day can be played from waking to sleeping.

## P3 — Farming
A plot of 18 cells by the hero's home; a hoe, a watering can and seeds on the item button; crops that grow by
the day and wither unwatered; five crops as data; a buy-and-sell list at Tilda's shop.
**Done when**: growth is unit-tested, and a crop can be planted, raised, harvested, eaten, cooked and sold.
Built in three steps (`docs/progress/P3-plan.md`): **3a** the plot and the tools (save version 3), **3b** seeds
and crops, **3c** the shop's list and the meals. **Done on 2026-11-13**: growth is unit-tested, and one test
plants, raises, harvests, eats, cooks and sells a crop (`tests/world/farm_round_test.gd`).

## P4 — RPG and story
Proposed in full before it is built, and kept small: the story spread over days (Elder Bram's quest opens after
the first crop), three skills that rise with use, friendship through talk and gifts, more side quests in the
quest data format, and an ending screen with days, crops and friendships.
**Done when**: a new player finishes the main story in six to eight in-game days with no developer help.

The proposal (`docs/progress/P4-plan.md`) was approved as written on 2026-11-13. Four steps:
- **4a — The story over days.** *Built 2026-11-13.* A main quest from the first morning, Bram's quest after the
  first crop, the keep's gate chained until then, the crypt open the morning after the keep. Save version 4.
- **4b — Skills.** *Built 2026-11-13.* Combat, farming and cooking rise with use and make their work cheaper
  (cooking: dishes richer). Shown in the pause menu.
- **4c — Friendship and gifts.** *Built 2026-11-13.* Villagers as data, a point for the day's first talk,
  one gift a villager a day, five marks, and a Friends page in the pause menu.
- **4d — Side quests, recipes and the ending.** *Built 2026-11-14.* Four favours and three recipes at two
  marks, a present at four, a quest log that scrolls, and the ending's three new lines.

All four steps are built, and **P4's "done when" was met on 2026-11-16:** the user played a whole game from
the title to the ending (on day 5, a day sooner than the six to eight aimed at; the user knows the game, so
a player new to it is still untried). The roadmap is finished.

## After the roadmap: Willowmere
One new area and one new enemy, at the user's request of 2026-11-17 (`docs/progress/willowmere-plan.md`,
approved as written). Three steps:
- **W1 — The marsh by day.** *Built 2026-11-17.* The map and its tiles, the way from Hearthvale, forage,
  Marsh Stew, a heart piece, mist, fireflies and a tune.
- **W2 — The marsh by night.** The Bogwisp: it drains energy, and only light makes it solid.
- **W3 — Old Henrik.** An eighth villager, his favour, the marsh lanterns and Ember Tea.

---

## Later (not in phase 2)
A new region and a bigger world (moved out of phase 2 on 2026-11-08: detail first), more dungeons and items, key
rebinding, several save slots.
