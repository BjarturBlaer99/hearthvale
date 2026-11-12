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
