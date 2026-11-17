# Plan: Willowmere and the Bogwisp

The user's request, 2026-11-17: one new area (Willowmere, a misty marsh east of the village) and one new
enemy (the Bogwisp), with an eighth villager, a favour, forage, two recipes and a tune. No new mechanics.

**Status: approved as written on 2026-11-17. All three steps are built (2026-11-17). Not yet played by the user.**

## Ten things to decide

Each has a choice already made, the simplest that fits the game as it is. Approving the plan approves these.

| # | The question | What the plan does |
|---|---|---|
| 1 | **The mist and the fireflies.** The request says "low drifting mist" and "fireflies"; the rule of 2026-11-13 says the scenery stands still and only the water moves. | The mist lies still, as in the Old Wood, and is thicker at night. The fireflies are the game's own firefly creature (creatures were left moving by that rule), out from dusk. Say so if the marsh should be the exception and its mist should drift. |
| 2 | **Dawn can't be seen.** A day ends at 02:00 and the hero wakes at home at 06:00, so he is never in the marsh when the night ends. | The rule is built and tested (a Bogwisp told the night is over fades and leaves nothing), and no Bogwisp is there by day. What he does see is the other end: they rise at 20:00 if he is standing there. |
| 3 | **The Lantern is in the crypt.** So a Bogwisp can't be hit, and the favour can't be finished, until the crypt is open (the dawn after the Warden). Before that the marsh at night is only a risk. | As asked. Henrik says a blade needs a light, so nobody wonders why the sword does nothing. |
| 4 | **A fifth heart piece.** Four make a heart and four exist; a fifth is always left over ("1 of 4"). | As asked: any four of the five make the heart, so one of the harder ones can be skipped. |
| 5 | **Do the lit marsh lanterns count as light for a Bogwisp?** | Yes: one that drifts into their light turns solid, as in the Lantern's. The favour then makes the boardwalk safer, not only prettier. |
| 6 | **The hut has no inside.** One new area was asked for, and a room is an area. | Henrik stands by his ruined hut from 06:00 to 20:00 and is away at night, like every villager out of doors. |
| 7 | **Hearthvale changes.** The way east needs a gap. | Two cells of the east tree line open, half-way down the east meadow, with six cells of plank path leading to them. The village is re-baked; nothing else in it moves. |
| 8 | **Which recipe Henrik teaches.** | Marsh Stew is known from the start, so the forage is worth picking on day 1. Henrik teaches Ember Tea, the Wisp Ember's dish, as the favour's reward. |
| 9 | **A present at four marks.** Every villager gives one; the request names none for Henrik. | Three bog mushrooms, so he is like the other seven. Data only. |
| 10 | **Where to stop.** | Three steps, a commit each. One stop after step 1 with screenshots, since the look is the thing most worth steering early; then steps 2 and 3 to the end. |

**Worth knowing:** a night is short. From 20:00 to 02:00 is about four minutes of play, and at 02:00 the hero
wakes at home at the usual cost, so a hunt for three embers is one or two evenings and a run for bed.

## The map

40 by 30 cells, the size of the North Fields. The sketch is as step 1 built it: the hut stands two cells
west of where it was first drawn (it stood where the north walk lands), and the heart piece a cell north.
The way out of Hearthvale is at rows 17 and 18 of its east edge, clear of the meadow's own trees.

```
     0         1         2         3         
     0123456789012345678901234567890123456789
  0  TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
  1  TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
  2  TT~~~~~~~~~~~~~"""""""""""~~~~~...V...TT
  3  TT"""""~~~~~~~~"".c.....""~~~~~.......TT
  4  TT"""""~~~~~~~~"".....c.""~*~~~.......TT
  5  TT"""""~~~~~~~~"".......""~~~~wwwwwww.TT
  6  TT~~~~~~~~*~~~~"""""==""""~~~~wwwwwww.TT
  7  TT~~~~~~~~~~~~~~~~~~==~~~~~~~""wwwwww.TT
  8  TT~~~~~~~~~~~~~~~~~~==~~~~~~~""wwwwww.TT
  9  TT""""""~~~~~~""""""=="""""~~"".......TT
 10  TT....."~~~~~~""HHHH..i..""~~""...b...TT
 11  TT.w..."~~~~~~""HHHH.....""~~"".......TT
 12  TT....."~~~~~~""HHHH.....""~~"".....w.TT
 13  TT....i"~~~~~~""i.....@.i""~~""i......TT
 14  >>.....=========.........======.......TT
 15  >>.....=========.........======.......TT
 16  TT....."~~~~~~"".......w.""~~""..b....TT
 17  TT....."~~~~~~""...i.....""~~"".......TT
 18  TT..w.."~~~~~~""""""=="""""~~"".......TT
 19  TT....."~~~~~~""""""=="""""~~""..w....TT
 20  TT""""""~~*~~~~~~~~~==~~~~~~~"".......TT
 21  TT~~~~~~~~~~~~~~~~~~==~~~~~*~"""""""""TT
 22  TT~~~~~~~~~~~"""""""==""""""~~~~~~~~~~TT
 23  TT~~~~~~""""~""...........""~~""""""~~TT
 24  TT~~~~~~""""~"".......m.w.""~~""""""~~TT
 25  TT~~~~~~""""~"".w.m.......""~~""""""~~TT
 26  TT~~~~~~~~~~~""...........""~~~~~*~~~~TT
 27  TT~~~~~~~~~~~"""""""""""""""~~~~~~~~~~TT
 28  TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
 29  TTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTTT
```

| Letter | What |
|---|---|
| `T` | the woods round the edge (solid) |
| `~` | water (solid, and it moves, as all water does) |
| `"` | deep reeds (solid) |
| `=` | boardwalk: the only way across |
| `.` | mossy ground |
| `>` | the way in from Hearthvale's east meadow |
| `H`, `@` | the ruined fisher's hut (solid, roofless), and Old Henrik beside it by day |
| `i` | a marsh lantern post, dark until the favour is done |
| `w` | a weeping willow (a tall picture the hero walks behind, like the cherry trees) |
| `c`, `b`, `m` | forage, back each morning: cattail root, marsh berries, bog mushrooms |
| `V` | the heart piece, in a nook reached by one cell of ground between the willows and the east woods |
| `*` | where a Bogwisp rises at night |

Cattails, lily pads and mossy stones are decoration on top of this.

## New data

| Kind | Entries |
|---|---|
| Area | `willowmere` ("Willowmere"), baked by `build_maps.gd` like the others; an exit each way |
| Items (6) | `cattail_root`, `marsh_berries`, `bog_mushroom` (food, eaten raw for a little energy); `marsh_stew` and `ember_tea` (food); `wisp_ember` (an ingredient: it can't be eaten) |
| Recipes (2) | `marsh_stew`: 2 bog mushrooms and 1 cattail root, known from the start. `ember_tea`: 1 wisp ember and 2 marsh berries, a great deal of energy and no hearts, taught by Henrik |
| Enemy (1) | `bogwisp`: behaviour `wisp`, health 4 (two blows from either sword), touch half a heart and 15 energy, always drops one wisp ember. Two new fields any enemy may have: `energy_drain`, and `appears: "night"` |
| Villager (1) | `old_henrik`: name, conversation, likes (Marsh Stew, Bread), three lines of thanks |
| Dialogue (1) | `old_henrik`: a greeting that warns of the lights, the favour at two marks, the present at four |
| Quest (1) | `lights_on_the_marsh`: have 3 wisp embers, bring them to Henrik. Reward: the flag `marsh_lanterns_lit` and the Ember Tea recipe |
| Forage | six `ForageSpot` nodes, two of each kind |
| Sound | the tune `marsh` (slow, misty), and two effects: a Bogwisp's flare and its dart |

Numbers (energy from each food, the Bogwisp's speed and reach) are first guesses in data, to be tuned in play.

## What is reused, and the little that is new

| For | Reused as it is | New code |
|---|---|---|
| The map | the baker, the tileset, `Scenery`'s tall trees, `Mist`, the firefly creature | one row of tiles (boardwalk, reeds, mossy ground, cattails, a mossy stone, a lantern post, the hut's broken walls) and a willow, painted in the art tools |
| The Bogwisp | `Enemy`, `EnemyBrain`'s states, `HitBox` and `HurtBox`, `DropTable` | `WispBrain` (pure, with unit tests): drift, flare for half a second, dart in a straight line, rest. Its body floats over water and reeds |
| Solid in light | `LightRules.brightness()` and the Lantern's own radius, the numbers the crypt uses | the area tells a Bogwisp whether light reaches it; unlit, a blow passes through it, as the Warden's armour turns one |
| The drain | `GameState.spend_energy()`, and the collapse at nothing | a hit can carry energy as well as hearts |
| Only at night | the clock's own night (20:00 to 06:00) | an enemy marked `appears: "night"` is set up only then, rises as night falls, and isn't made tougher by the night's rules |
| Forage and food | `ForageSpot`, items, `Cooking`, the hearth's list | none |
| Henrik | `Villager`, `Friendship`, the gift list, `openings`, `teach_recipe`, the quest runner | none |
| The lanterns | lamp posts that light at dusk (`Ambience`) | a light that waits for a flag as well as for dusk |
| The tune | the synth in `make_audio.gd` | none |

## Steps

**Step 1: the marsh by day.** The tiles and the willow, the map, the way in from Hearthvale, the mist and
fireflies, the six forage spots, the three raw foods and Marsh Stew, the heart piece, the tune. *Stop here with
screenshots.*
- [x] The hero walks from the east meadow into Willowmere and back; water and reeds stop him, boards don't
- [x] Each forage spot gives its food and is back the next morning; Marsh Stew cooks at the hearth
- [x] The heart piece is reached only by the way behind the willows, and is taken once

**Step 2: the marsh by night.** The Bogwisp's brain, picture and sounds, the drain, the light rule, the thicker
mist.
- [x] `WispBrain` is unit-tested: drift, the half-second flare, the straight dart, a blow passing through
      unlit, two blows lit, fading when the night ends
- [x] By day there are none; at 20:00 they rise; one that touches him takes half a heart and 15 energy
- [x] Without the Lantern the sword passes through; with it, two blows and a Wisp Ember

**Step 3: Old Henrik.** The villager, his conversation and present, the favour, the lanterns, Ember Tea.
- [x] Henrik can be befriended and given gifts like the other seven; his data is unit-tested
- [x] The favour is asked at two marks, finished with three embers, and lights the lanterns from the next dusk
- [x] Ember Tea is not at the hearth before the favour and is after it

**Done when** all tests pass, a save from before Willowmere loads with the marsh untouched and Henrik a
stranger, it is committed, and the user has screenshots of the marsh by day and by night and an account of
the Bogwisp fight and the favour as played.

All of that is done but the last word, which is the user's:
- [ ] *(yours)* the marsh feels worth the walk by day, and worth the risk by night

## Saves

No new version. Everything new is kept where such things already are: flags (the heart piece, the forage,
the lanterns, the recipe), the quest's stage, and Henrik's entry among the friends, which is made when he is
first met. A test loads saves from every older version.

## Tests that will change

Those that count seven villagers, eight quests, nine recipes or the hearth's lines (about ten places), and
the village's layout test for its east edge.

## Not in this

- Fishing, swimming, boats, new tools, anything to do with the water but walk beside it.
- An inside for the hut. A second new area. Any change to another area but the village's two cells.
- A second enemy, a boss, or Bogwisps anywhere but Willowmere.
- A sign, a chest, a shop, or more words than Henrik's conversation and one quest.
