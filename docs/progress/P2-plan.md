# P2 — Energy, food and time (plan)

The second phase of the pivot (`docs/ROADMAP.md` P2; the numbers are section 6 of
`docs/progress/pivot-plan.md`, approved as written). It is built in five steps, each with its own tests, commit
and review stop, as P1 was built in six. The phase is done when a day can be played from waking to sleeping.

## The five steps
- **2a — The clock and the day.** A day of 14 real minutes from 06:00 to 02:00; light that follows the hour;
  lamps lit from dusk; the day and the hour on the HUD; save version 2 with a migration from version 1.
- **2b — Home and sleep.** The thatched cottage gets a door and a one-room interior (a new area, decision 4);
  sleeping in the bed ends the day, refills hearts and saves; at 02:00 the hero wakes there.
- **2c — Energy.** The bar on the HUD; sprinting and swinging cost it; low energy slows; at zero the hero
  collapses and wakes at home, poorer.
- **2d — Food and cooking.** Food items, eaten from the item menu; foraged berries and mushrooms; bread at
  Tilda's; recipes as data, cooked at the hearth at home.
- **2e — Hours and night.** Tilda's shop hours; villagers go home at 20:00; lit windows; tougher monsters
  outdoors at night; a night tune and the new sounds.

Nothing is built ahead of its step. Each later step gets its own "done when" list here before it starts.

---

## 2a — The clock and the day

### What changes
- **The rules of the clock are data** (`data/rules/time.json`, a new kind of data, with a schema): when the
  day starts and ends, how many real seconds an hour takes, when lamps are lit, when night falls, and the
  colour of the light at each hour.
- **`DayClock`** (`core/time/`, pure, tested) reads those rules: moves the time on, says when the day is over,
  what colour the light is, whether lamps are lit, whether it is night.
- **`GameState`** keeps the day (1, 2, 3...) and the minute, and the hero's energy (full, and unused until 2c:
  it is in the save now so the format changes once). **Save version 2**, with a migration from version 1: day
  1, 06:00, full energy, everything else as it was. A finished version 1 save loads, finished.
- **The clock runs** while an area runs: not behind the pause menu, in a conversation or in the item menu, and
  (decision 7) not in a dungeon. It runs in houses.
- **Light follows the hour outdoors:** peach at dawn, clear by day, orange then violet at dusk, blue at night.
  Houses and dungeons keep their own light.
- **Lamps are lit from dusk to dawn,** and dark by day. At night each lamp has its pool of light. The hero has
  no pool of his own outdoors: the night is dim, not dark.
- **The HUD's corner** shows the day and the hour under the hearts ("Day 1  06:00", moving in steps of ten
  minutes).
- **At 02:00 the day ends.** Until the hero has a home (2b) he nods off where he stands and a new day begins
  there, at 06:00. No penalty yet: that comes with energy (2c).
- **Tools:** the playtest scenarios take an hour (`-- warden 19:30`), and there is one that starts in the
  village; the screenshot tool takes the village at dawn, dusk and night.

### What does not change
- Enemies, the shop and the villagers are the same at every hour (2e).
- Sprint stays free (2c). Nothing costs energy yet.
- Dungeons: no clock, no change of light.

### Done when
- [x] the clock's rules are data, checked on load, with a schema
- [x] `DayClock` is unit-tested: the day's length, the hours, the light, the lamps, the night
- [x] the clock runs outdoors and in houses, and stands still in dungeons, conversations, menus and pause
- [x] the light outdoors follows the hour, and lamps are lit only from dusk to dawn
- [x] the HUD shows the day and the hour
- [x] at 02:00 a new day begins
- [x] a version 1 save loads as day 1 at 06:00 with full energy, and a finished one is still finished
- [x] all earlier tests pass; the village is compared at dawn, noon, dusk and night
- [ ] (yours) a day feels the right length in play

### Not in this step
- The bed, the home, sleeping (2b). Energy costs and the bar (2c). Food (2d).
- Hours for the shop and villagers, night monsters, lit windows, a night tune (2e).
- Weather, seasons, a calendar: not in the pivot at all.

---

## 2b — Home and sleep

### What changes
- **The hero has a home** (decision 4): the thatched cottage west of the weaver's, which had no door, gets one
  in the middle of its front wall, and a one-room inside: a new area, `home`, the size of the other houses,
  with a bed, a hearth (for cooking, in 2d), a table, shelves and a candle.
  - This is one new cell the hero can walk to in Hearthvale: the doorway.
- **Sleeping:** face the bed and press E. The bed asks; "Sleep until morning" ends the day. He wakes at 06:00
  the next day with full hearts and full energy, and the game is saved. "Not yet" changes nothing. He can sleep
  at any hour.
  - The bed's words are a conversation in data, and sleeping is a new effect a conversation can have
    (`sleep`), like giving an item.
- **At 02:00 he wakes at home** in place of where he stood (2a's stopgap): the next day begins by his bed, the
  game is saved, and a line says he stayed up too late. Hearts are as they were; nothing is lost (that is 2c).
- **Tools:** a playtest scenario that starts at home; screenshots of the cottage's door, its inside, the bed's
  question and a morning.

### What does not change
- A new game still starts in the village square.
- The other houses, the shop, and every other cell of Hearthvale.
- Saving from the pause menu.

### Done when
- [x] the cottage has a door that leads to its inside, and the doormat leads back out
- [x] the hero can reach exactly one more cell of Hearthvale than before: the doorway
- [x] sleeping in the bed starts the next day at 06:00 with full hearts and energy, and saves
- [x] "Not yet" changes nothing
- [x] at 02:00 the hero wakes by his bed on the next day, saved, with his hearts as they were
- [x] all earlier tests pass; new tests cover the door, the room, the bed and the waking
- [x] the cottage is compared before and after, outside and in
- [ ] (yours) sleeping feels right in play

### Not in this step
- Starting a new game at home, in bed.
- Cooking at the hearth (2d). What collapsing costs (2c). Furniture to buy or move.

---

## 2c — Energy

### What changes
- **The energy rules are data** (`data/rules/energy.json`, read by a pure `EnergyRules` in `core/energy/`): a
  bar of 100; sprinting costs 0.25 a second, a sword swing or a bow shot 0.5; walking, talking and bombs cost
  nothing.
- **The bar shows on the HUD,** under the hearts (it has been there, hidden, since 1a).
- **Sprint is no longer free** (the user's rule of 2026-11-12, in place of "no stamina"): it drains energy
  while the hero is running, and under 10 energy he can't sprint at all.
- **Low energy slows him:** under 25 he moves at 85% speed and the sword's cooldown is 30% longer. A line of
  words says so when it happens.
- **At zero he collapses:** he falls, the screen goes dark, and he wakes by his bed the next morning with half
  his energy and a tenth of his coins gone (30 at most). Hearts are untouched, and whatever he had done in a
  dungeon stays done.
- **Staying up until 02:00 costs the same** as collapsing ("as at zero energy").
- **Sleeping refills the bar** (since 2b). Nothing else does until there is food (2d).
- **Tools:** the playtest tool takes a starting energy (`-- village energy=12`); screenshots of the bar when
  low and of a collapse.

### What does not change
- Hearts are life in combat only: energy never costs a heart, and losing hearts never costs energy.
- Walk and sprint speeds at 25 energy or more; the swing's length, its hit and when it lands.
- Dying (no hearts) works as before, and costs no coins.

### Done when
- [x] the energy rules are data, checked on load, with a schema, and `EnergyRules` is unit-tested
- [x] the HUD shows the bar, and it follows the hero's energy
- [x] sprinting drains energy only while he runs; a swing and a shot each cost their price; a bomb is free
- [x] under 25 he is slower and the sword's cooldown longer; under 10 he can't sprint
- [x] at zero he collapses and wakes at home the next day with half energy and a tenth of his coins gone
- [x] staying up until 02:00 costs the same
- [x] hearts are never touched by any of it
- [x] all earlier tests pass
- [ ] (yours) sprinting still feels free enough, and a long fight doesn't drain him unfairly

### Not in this step
- Food, and anything else that gives energy back (2d). Hoeing and watering costs (P3).
- A sound for tiring or collapsing (2e). Night monsters (2e).
