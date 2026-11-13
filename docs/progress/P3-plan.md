# P3 — Farming (plan)

The third phase of the pivot (`docs/ROADMAP.md` P3; the numbers are section 7 of
`docs/progress/pivot-plan.md`, approved as written, and GDD §7). It is built in three steps, each with its own
tests, commit and review stop. The phase is done when growth is unit-tested and a crop can be planted, raised,
harvested, eaten, cooked and sold.

## The three steps
- **3a — The plot and the tools.** Eighteen cells of soil across the road from the hero's cottage; a hoe and a
  watering can on the item button; soil that is tilled, watered, and dry again each morning; save version 3
  with a migration from version 2.
- **3b — Seeds and crops.** Five crops as data; seeds planted from the item button; a crop grows a stage each
  morning if it was watered the day before and withers after two dry mornings; harvesting; raw crops can be
  eaten.
- **3c — The shop's list and meals.** A buy-and-sell list at Tilda's (seeds and her other wares to buy, crops
  to sell); the five meals made from crops, as recipes; the round from seed to coin played through.

Nothing is built ahead of its step. Each later step gets its own "done when" list here before it starts.

## Decisions taken here (none of them in the docs; all in `docs/DECISIONS.md`)
- **Where the plot is:** six cells wide and three deep on the far side of the road from the cottages, cells
  (12..17, 18..20) of Hearthvale: between Tilda's shop and the well. It is open grass today. Straight across
  from the hero's own door (cells 6..11) the shop's roof hides half of the third row, so the plot is one
  house to the east, and has the well at its edge.
- **The plot is a thing in the village, not a change to its map.** The soil is drawn over the grass and the
  three flowers that grow there are taken off as the area loads. The hero walks over it, crops and all, exactly
  as over the grass there today. No map is re-baked.
- **Where the tools come from:** they lie in the hero's home, by the door (GDD §4 says "Home"). An old save
  finds them there too.
- **The can's water is carried like arrows** (an item, `water`, ten at most): the item menu and the HUD say
  "Watering Can (Water x7)" with what is already built, and nothing new is saved for it.
- **A tool works on the cell the hero faces,** like the sword and the bow.
- **The save is version 3 for the whole of P3.** A cell's crop joins it in 3b as a field with a default, so
  the format changes once.
- **(For 3b, said now so it can be refused):** a pouch of five turnip seeds lies with the tools at home, so the
  first crop needs no coins. Every other seed is bought.

---

## 3a — The plot and the tools

### What changes
- **The plot:** a `FarmPlot` in Hearthvale (18 cells, as above). It draws each cell as bare soil, tilled soil
  or watered soil. Walking is unchanged.
- **The farm's rules are data** (`data/rules/farm.json`): the plot's size, and how many dry mornings wither a
  crop (2; used in 3b). What hoeing (2) and watering (1) cost joins the energy rules. How many pours the can
  holds (10) is how much of the item `water` can be carried.
- **`Farm`** (`core/farming/`, pure, tested): the state of the cells; tilling one; watering one; a new morning
  (watered soil is dry again; tilled soil stays tilled).
- **`GameState.farm`**, saved. **Save version 3**, with a migration from version 2 (an untouched plot),
  tested on a real version 2 save. A version 1 save still loads, through both steps.
- **Two tools** (a new item type, `tool`), lying in the hero's home: the **hoe** and the **watering can**. Each
  goes on the item button from the item menu, like the bow.
  - **The hoe** tills the soil cell he faces: 2 energy.
  - **The watering can** waters the tilled cell he faces: 1 energy and one pour. Facing the well or the pond
    it fills (ten pours), for nothing.
  - Used anywhere else, or on a cell already done, a tool says so and costs nothing. Out of water, the can
    says where to fill it.
  - A tool takes a moment (he stands still, as for the bow) and its picture shows on the cell it works.
- **Art:** the soil (bare, tilled, watered) and two item pictures, painted in the sprite tool. The hero's own
  frames are not touched: he uses his swing pose.
- **Sound:** the hoe, water poured, the can filled.
- **Tools:** a playtest scenario at the plot with both tools (`-- farm`); new screenshots.

### What does not change
- Where the hero can walk, anywhere. No map is re-baked.
- Energy, apart from the two new costs. Hearts: farming never costs one.
- Nothing grows yet, and there are no seeds (3b). The shop is as it was (3c).

### Done when
- [x] the farm's rules are data, checked on load, and `Farm` is unit-tested: tilling, watering, the morning
- [x] the plot shows in Hearthvale, and walking there is exactly as before
- [x] the hoe and the can are found at home and go on the item button
- [x] the hoe tills the cell he faces for 2 energy; the can waters a tilled cell for 1 energy and a pour
- [x] the can holds ten pours and fills at the well and at the pond
- [x] watered soil is dry the next morning, and tilled soil is still tilled
- [x] a version 2 save loads with an untouched plot; a version 1 save still loads; the farm survives a save
- [x] all earlier tests pass
- [x] (yours) hoeing and watering eighteen cells feels like work, not a chore (tried on 2026-11-13: "feels
  right")

### Not in this step
- Seeds, crops, growth, withering, harvest (3b). Buying and selling, meals (3c).
- A scarecrow, fences round the plot, fertiliser, sprinklers, bigger plots, weather, seasons: not in the
  pivot at all.
