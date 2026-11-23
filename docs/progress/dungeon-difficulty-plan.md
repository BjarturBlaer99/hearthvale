# Harder dungeons and puzzles — plan

The user's request (2026-11-23): "make the dungens more difficult and make the puzzles more difficult".
Nothing in `docs/ROADMAP.md` lists this, so this plan waits for the user's word before anything is built.
Each step stops for review, as the pivot's steps did: tests pass, new logic has tests, the step is
committed, and there is a summary with pictures. Push only when asked.

Marks used below: **[mechanic]** needs new code (a new rule or puzzle piece), **[art]** needs a new
picture, **[save]** changes the save format. **None of the proposals needs [art] or [save].** The
puzzle pieces drawn today (plates, crystals, torches, blocks, shutters) are drawn as they are; new
flags are plain dungeon flags, which every save already holds.

## 1. What the dungeons ask today (the audit)

Damage is counted in half hearts; the hero starts with 3 hearts (6). The wooden sword does 2, the iron
sword 3, an arrow 2, a bomb 4.

**Monsters** (`data/enemies/`): slime 2 health (one blow), bat 1 (one blow), goblin archer 4 (two
blows), every touch and arrow half a heart. Dungeons don't use the night's rules, so a dungeon's
monster is the same as one met in the fields by day.

**The Old Keep** (10 rooms, 15 monsters, all slimes, bats and archers, one to three a room):
- Entrance: 2 slimes. Guard room: 2 slimes and a bat, beaten for a small key. Store: a cracked wall
  (bomb) and 2 bats over a little coin. Great hall: 2 slimes and an archer, the boss door.
- Plate room: **two plates and one block** (the hero on one, the block on the other).
- Armoury: the Bow, and **one crystal on a ledge** (one arrow).
- Gallery: 2 archers on a walkway, beaten for the second key.
- Twin crystals: **a low and a high crystal, both needed**, hit in any order, any time apart; 2 bats.
- Big key room: an archer and 2 slimes, beaten for the big key.
- **The Iron Warden:** 12 health (six wooden-sword blows), eye open 2.2 s, stunned 3 s, rage at 6.

**The Chapel Crypt** (dark, 10 rooms, 18 monsters):
- Narthex: **two torches side by side** (permanent). Trench: a one-cell pit, **one block** to fill it,
  a bat. Great hall: **two torches side by side**, 2 slimes and a bat.
- Tomb: the Lantern, 2 slimes, one torch. Dark Path: two walls of pit, **two torches**, 2 bats.
- Knight's Tomb: **three torches that burn 6.5 s**, lit in one go, for the Iron Sword; 2 bats.
- Ossuary: 3 slimes and a bat beaten for a key. Broken Floor: a pit row, **one block**, 2 bats.
- Reliquary: **one crystal across a pit** (one arrow), 2 archers, the big key.
- **The Crypt Shade:** 16 health (six iron-sword blows), bound 3 s, rage at 8, a bolt every 2.8 s; its
  four braziers burn until it snuffs them.

**The ruin's cellar and the cistern** (side dungeons, no boss): the cellar is 2 slimes; the cistern is
one block in a gap, one latching plate, one crystal, a cracked wall, and a treasure shutter that opens
on **either** its plate **or** its crystal (it doesn't need both).

**The Old Quarry** (nine floors): 2, 3, 4 slimes on floors 1–3; 3 bats, then bats and 1–2 archers on
4–6; 2, 3, 4 Bogwisps on 7–9.

**In short:** every puzzle is one step, every timed one is generous, nothing asks for an order, and
a monster dies in one or two blows and costs half a heart.

## 2. The decisions (numbered; each wants the user's yes)

### A. Tougher monsters

1. **[mechanic] Dungeon rules, as the night's are** — a new `data/rules/dungeon.json`, read by a pure
   `DungeonRules` (`core/enemies/`, with tests), the same shape as `NightRules`. Each dungeon names its
   own numbers, so the first dungeon can stay gentler than the last. Bosses are left out (they have
   their own numbers, decision 4). Monsters in the fields are untouched. Proposed:

   | Where | Health | Touch and arrows | Speed | Sight | Hearts dropped |
   |---|---|---|---|---|---|
   | The ruin's cellar and cistern | ×1.5 | ×1 (half a heart) | ×1.1 | ×1.2 | ×0.5 |
   | The Old Keep | ×1.5 | ×1 (half a heart) | ×1.1 | ×1.2 | ×0.5 |
   | The Chapel Crypt | ×2 | ×2 (a whole heart) | ×1.15 | ×1.3 | ×0.5 |
   | The quarry, floors 4–9 | ×1.5 | ×2 from floor 7 | ×1.1 | ×1.2 | ×0.5 |

   So in the keep a slime takes two blows of the wooden sword, an archer three; in the crypt a slime
   takes two blows of the iron sword and every touch costs a whole heart. Archers shoot a little more
   often in dungeons (cooldown ×0.8). Bogwisps keep their numbers, as they do at night.
   *Without this decision,* steps 2–4 only add monsters and puzzles; editing `data/enemies/` instead
   would make the fields harder too, which the user didn't ask for.
2. **More monsters in each room** (placements only, no code): about one more a room, so most rooms hold
   three or four; the rooms that are beaten for a key get an archer among them. Room by room in
   section 3.
3. **The quarry gets one more monster on each floor** (an archer on floors 2–3, a slime on 4–6, a
   Bogwisp on 7–9). *Optional:* the user may want the quarry left as it is, since it is the farm's
   mine as much as a dungeon.

### B. Tougher bosses (data only)

4. **The Iron Warden:** health 12 → 18; its eye open 2.2 s → 1.6 s (a quicker shot); stunned 3 s →
   2.4 s; rage at 9 of 18 (half, as now); its touch a whole heart. Nine wooden-sword blows over about
   four stuns instead of two.
5. **The Crypt Shade:** health 16 → 22; bound 3 s → 2.4 s; rage at 11; a bolt every 2.8 s → 2.0 s; its
   touch a whole heart. **And its four braziers burn only 10 s once lit** (the torch's `burn_time`,
   which exists): all four must be lit inside ten seconds while it drifts after him. Eight iron-sword
   blows over about four bindings instead of two.

### C. Harder puzzles from the pieces there are now (no new code)

6. **The keep's plate room: three plates, two blocks.** All three must be held at once (plates that
   don't latch, as now): the hero on one, a block on each of the others. Two more pillars are baked
   into the room so each block has one right road and a wrong push pins it against a wall; leaving the
   room puts the blocks back (as now), which is the way to start over. Two slimes wander the room.
7. **The keep's twin crystals become three**, one on the floor and two on ledges at either end, all
   needed. (Decision 13 makes them timed.)
8. **The crypt's Knight's Tomb: four torches at 5.5 s** (from three at 6.5), the fourth across the
   room, so the order he lights them in matters.
9. **The crypt's Narthex and great hall: torches apart, burning 6 s.** Each room's two torches move to
   opposite sides and burn only 6 s, so they must be lit in one run, around the room's monsters. The
   shutters still stay open for good once lifted.
10. **The crypt's Dark Path: its two torches burn 8 s,** one at each end of the pit maze: light one,
    run the maze, light the other.
11. **The crypt's Broken Floor: a second pit row and a second block**, the new block placed so it must
    be pushed in after the first one has made a way to it. *Save safety:* the old pit row and its block
    (`block_id` `floor`) are left as they are, so a save that has filled it is never stuck; only the new
    row and its new block are added.
12. **The cistern's treasure needs both** its plate and its crystal (today either opens it), and its
    plate room's plate stops latching, so it must be held by the block.

### D. New puzzle pieces (each one **[mechanic]**, small, pure logic with tests, no art)

13. **[mechanic] Crystals that turn back.** A crystal switch may have a `hold_time`: hit, it is blue
    for that long, then red again (it flashes white the last second, from its own frame, as a torch
    gutters). Shutters that need several crystals then need them blue **at the same time**. Used for:
    the keep's three twin crystals (5 s: an arrow up, run, an arrow up, a blow), the armoury's crystal
    paired with a second one across the room (4 s), and the crypt's Reliquary (two crystals across the
    pit, 4 s). *This gives the keep timed puzzles; today only torches are timed, and the keep has no
    Lantern.*
14. **[mechanic] Plates in an order.** A set of plates (or crystals) that must be pressed in a set
    order; a wrong one resets the set with the clunk the plates make now. The order is told by an
    inscription in the room (a `Signpost`, words only, so no art). Used for: the keep's big key room (four
    plates, its alcove opening on the order *and* on its monsters beaten) and the crypt's Ossuary (three
    plates under the ossuary's skulls, read from its inscription).
15. **[mechanic] Shutters that open when a crystal is red.** A shutter may wait on a flag being *off*
    (`opens_when_off`). With a toggling crystal (which exists), one hit opens one way and shuts another:
    the "red and blue doors" kind of route puzzle. Used once, in the crypt's Tomb room, between the
    Lantern and the Dark Path. *Optional:* the user may want only 13 and 14.

### E. What stays as it is

16. **No change to** the hero (hearts, sword, bow, bombs, energy), the falls (half a heart at a pit, the
    entrance on the last half heart), what a dungeon remembers, the keys' and doors' places, the dark's
    rules, or the story's gates. No new rooms, monsters, items or pictures. **No save change:** new
    flags are dungeon flags like any other.
17. **Old saves:** a puzzle already solved in a save stays solved (shutters that `stay_open` are latched
    in the save), so the user's own game (finished, slot 1) shows the changes only in a new game or in
    the playtest scenarios (`warden`, `crypt`, `shade`, `gate`). Nothing is changed in slot 1.

## 3. Room by room (what decisions 2 and 6–15 mean in each)

**The Old Keep:** entrance 2 slimes + a bat; guard room + an archer; store + a slime; great hall 3
slimes + 2 archers; plate room (6) + 2 slimes; armoury two crystals that turn back (13) + a bat; gallery
3 archers + a bat; twin crystals (7, 13) + a bat; big key room plates in order (14) + an archer.

**The Chapel Crypt:** Narthex torches apart (9) + a bat; Trench + a slime; great hall torches apart (9)
+ an archer; Tomb red-and-blue shutters (15) + a bat; Dark Path torches at 8 s (10) + a bat; Knight's
Tomb four torches (8); Ossuary plates in order (14) + an archer; Broken Floor two rows (11) + a slime;
Reliquary two crystals that turn back (13) + a bat.

**The cellar and the cistern:** the cellar + a bat; the cistern (12) + 2 slimes and a bat.

Exact cells are settled while building each room, and **every changed room gets a test that solves
it** the way a player would (as `tests/world/keep_test.gd` and `crypt_test.gd` already walk the
dungeons through), so nothing is left unsolvable.

## 4. Steps (stop after each for the user's review)

1. **Monsters and bosses:** `DungeonRules` (1) and its data, the bosses' numbers (4, 5), with tests.
   Pictures: the Warden and the Shade fights, a keep room's monsters.
2. **New puzzle pieces** (13, 14, 15, only those approved), pure logic with tests, not yet in a room.
3. **The Old Keep:** its monsters (2) and puzzles (6, 7, 13, 14), the keep's tests walking it through,
   `tools/playtest.gd -- gate` / `warden` for a hand try.
4. **The Chapel Crypt:** its monsters (2) and puzzles (8–11, 13–15), the crypt's tests,
   `-- crypt` / `-- shade`.
5. **The cellar, the cistern and the quarry** (2, 3, 12).

Each step: the whole suite green (`--continue`), docs updated (`GDD.md` §8–9, `TECH_DESIGN.md` §5–6,
`DECISIONS.md`, `LOG.md`), committed, a short summary with capture shots. CLAUDE.md's changes are
reported to the coordinator session, not made here.

## 5. Risks

- **Too hard.** A whole heart a touch in the crypt, with fewer hearts dropped, may be steep for a hero
  with four or five hearts. Every number is data (`dungeon.json`, the bosses' files, a torch's
  `burn_time`, a crystal's `hold_time`), so it can be eased after a playtest without code.
- **Tests that walk the dungeons** (`keep_test`, `crypt_test`, `puzzle_test`, `whole_story_test`,
  `story_test`) will change with the rooms; each step updates them.
- **The scripted playthrough** (`tools/playtest.gd -- full`) and `play_days.gd` don't enter the
  dungeons, so they are not affected.
