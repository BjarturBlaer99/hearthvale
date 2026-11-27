# Icons, an axe, and arranging the item bar: the plan

The user's request (2026-11-26, their words): "add icons for every item in the store and in the tab
inventory also add an axe and an option to customize the item bar which item is in what column".

**Approved on 2026-11-26** ("Approve as recommended"). It has three parts, built in the order below,
each step committed and stopped with a summary and pictures, as with every plan since the pivot. The
questions are at the end (Q1 to Q14), each with its recommendation; the user's answers are just below.
Where a step depends on an answer, it says which one.

## What the user has decided

**2026-11-26, shown a summary of the plan and its fourteen questions: "Approve as recommended".**
Every question is answered with its recommendation:

- **Q1, "the store":** the shops (Tilda's and Oda's stall), the Tab menu **and the chest**, all in
  step I1. The gift list and the workbench not now.
- **Q2, the Tab menu:** **yes, a second list "Pack"** of everything he carries, to look at only
  (step I2 is built).
- **Q3, size:** 16 px pictures in 16 px lines, five lines as now; **the boxes grow** to hold them.
- **Q4, the sheep:** its icon is **cut from today's sheep** and listed as a gap.
- **Q5, what the axe cuts:** branches, stumps and logs. Not grass, weeds, bushes or pots.
- **Q6, the sword and wood:** **the sword no longer cuts wood;** wood wants the axe, and a bomb
  still breaks it. **This changes the Homestead's D5** ("The sword and the pickaxe clear it"): it
  becomes "the sword, the axe and the pickaxe" (recorded in `homestead-plan.md` and
  `docs/DECISIONS.md`).
- **Q7, blows and energy:** as the sword's today (branch 1, stump and log 3, the same wood; 0.5
  energy a blow).
- **Q8, a skill:** none.
- **Q9, better axes:** a Copper Axe and an Iron Axe, made at the workbench as the hoe's are.
- **Q10, how it's had:** it lies in the farmhouse, for new games and old saves alike; Tilda doesn't
  sell it.
- **Q11, trees:** not cut.
- **Q12, where the bar is arranged:** a new line "Item bar" in the pause menu, opening its own
  screen.
- **Q13, empty slots:** fixed columns. Each thing keeps its column; used up, its slot stays empty
  and it comes back there; an upgrade takes its tool's column; anything new takes the first free one.
- **Q14, the save:** a field read with a default; the version stays 6.

So every step is built, in order: I1 (with the chest), I2, A1, A2, B1, B2. **All six are built
(2026-11-27); B2 waits for the user's review.** (The plan's "seven steps
at most" below counts one too many: there are six.)

Pictures of the menus and the bar as they are today (taken with `tools/capture.gd`, shots 105, 114,
119, 120, 121, 152, 156, 176, 192, 201) are in the session notes folder, `icons-axe-bar-today/`.

---

## What is there today

**No list in the game draws a picture.** Only the item bar at the bottom of the screen does
(`ItemBar`, through `ItemIcons.draw()`). The shop's two lists (`ShopMenu`), the Tab menu (`ItemMenu`),
the chest (`StoreMenu`), the gift list and the workbench are words only.

- **The shop** (`ui/shop_menu.tscn`): one `Label` for the list, five lines of 11 px (the 8 px face), a
  cursor mark `> ` before the line it is on. Lines look like "Pickaxe: 25 coins" (buying) and
  "Copper Ore x2: 3 coins each" (selling). Both shops use it: Tilda's (her sixteen wares to buy, and
  her harvest, ore, bars and animal goods to sell to) and Farmer Oda's stall (three animals). The
  shop has no greyed lines (only the workbench has those).
- **The Tab menu** (`ui/item_menu.tscn`, title "Food"): **food only**, since the user's request of
  2026-11-15 moved what is in hand to the bar. Lines look like "Bread x2 (+30 energy)". With no food,
  Tab doesn't open it and the hero is told he has nothing to eat.
- **Which items have a picture:** all 90 items in `data/items/items.json` but one have a picture of
  their own (`ItemIcons.FRAMES` or `PlacedArt.FRAMES`), or one by their type (a sword, the bow,
  arrows, bombs, keys, the coin). The five building kits share one picture, `kit`.
  - **No picture:** the **Basket of Eggs** (`egg_basket`, a quest thing) falls back to the gem. It is
    never sold or eaten, so it would show only in a list of everything he carries (Q2). The pack has
    no basket: a gap.
  - **Animals have no icon at all.** Oda's three lines (hen, sheep, cow) are animals, not items. The
    pack has a 16 x 16 front-facing hen (`Actor/Animal/Chicken`) and cow (`Actor/Animal/Cow`,
    `SpriteSheetWhite.png`). **It has no sheep:** the sheep in the world is today's art (a known gap).
  - Still today's art, as CLAUDE.md lists: the shuttle, the cattail root, the wisp ember and the
    sprinkler. They show today's pictures in a list, as on the bar.
- **The bar** (`HandBar`, pure; `GameState.hand_entries()`, `take_in_hand()`, `step_hand()`;
  `ItemBar` draws it): the best sword first, then what goes on the item button in the order it came
  into the pack. Nine slots show at once; with more, it moves along with the one in hand. Keys 1 to 9
  choose among the nine showing, the wheel steps round. When the last bomb or seed is gone its slot
  goes, and everything after it moves one to the left. Nothing is saved about the order: it is the
  pack's order.
- **Wood today:** the sword (and a bomb) cuts fallen branches (1 blow, 1 wood) and old stumps (3
  blows, 2 wood) in the countryside, back each morning, and on the homestead the fallen logs (10 of
  them, 3 blows, 3 wood) and old stumps (14, 3 blows, 2 wood), gone for good. The Homestead's
  decision **D5** says "The sword and the pickaxe clear it." A swing costs 0.5 energy and is eased by
  Combat. Trees are scenery and are never cut.
- **The pack has an axe:** an icon (`Items/Tool/Axe.png`, 16 x 16) and the animated character's axe
  layer (`Actor/CharacterAnimated/Weapon/Axe.png`), the same kind of layer the pickaxe and the hoe
  in his hands were cut from in phase E.

---

## Part 1: icons in the shop and the Tab menu

### How a line shows its icon

- **A 16 x 16 picture at the left of each line**, before the cursor mark: `[icon] > Pickaxe: 25 coins`.
  The words stay exactly as they are, so `shown_lines()` and every test that reads it hold.
- **Lines become 16 px tall** (a multiple of 8; the face stays 8): the list's `Label` gets a
  `line_spacing` of 5 (11 + 5). `MenuInput.line_height()` already adds `line_spacing`, so the pointer
  finds the line under it as before, and a click chooses that line.
- **Five rows, as now; the boxes grow** to hold them (Q3): the shop's box about 24 px taller and 18 px
  wider, the Tab menu's the same. The screen is 640 x 360; both still fit with room.
- **The pictures scroll with the words:** a small part, `ItemIconColumn` (a `Control` beside the list
  `Label`), is told the icons of the lines shown (from `top` to `top + ROWS`) and draws them at the
  label's own line height. It takes no clicks (`MOUSE_FILTER_IGNORE`). The empty-list line ("She has
  nothing to sell today.") has none.
- **A ware's picture is its item's** (`ItemIcons.name_for()`); an animal's is a new icon of its own:
  `hen` and `cow` cut from the pack's front frames, `sheep` cut from today's sheep (Q4). They go at
  the end of `items.png` (an older frame never moves), each with its white flash row, listed in
  `art/sheets.json` and `docs/ASSETS.md`. `Herd` names the icon from the animal's data (`"icon"`),
  so a new animal is still data and pictures.
- No greyed lines in either list today, so nothing to say about them; if the chest or the workbench
  join (Q1), a greyed line's picture is drawn at half strength, as its words are dimmer.

### Steps

**Step I1. The icon column, the shop and the Tab menu.**
- `ItemIconColumn` (`ui/item_icon_column.gd`), used by `ShopMenu` (both lists, both shops) and
  `ItemMenu`; three animal icons; `Herd.icon_of()`; the boxes resized in their scenes.
- If Q1 says so, the chest (`StoreMenu`'s two lists) in the same step.
- **Done when:** every line of Tilda's two lists, Oda's list and the Tab menu shows its picture; the
  lines are 16 px; pointing and clicking choose the line under the pointer as before; the help line
  and the count still fit; all tests pass; before-and-after pictures of shots 105, 120, 121, 156, 176,
  192 and 201 (and 152 for the chest).
- **Tests:** the column is given the shown lines' icons in order, and moves with `top` when the list
  scrolls (`tests/ui/`); an animal's line has its animal's icon; the line under a point 16 px lines
  apart is the right one (the existing pointer tests, with the new height); `tests/art/` checks the
  three new frames and their flash row.
- **Built (2026-11-26), waiting for the user's review.** As written, with the chest (Q1). What
  building it decided: the picture stands left of the cursor mark, and **a point on a picture
  finds its line** (`MenuInput.line_under()` takes a `lead` of `ItemIconColumn.WIDTH`), so a click
  on an icon never chooses another line; the text sits three pixels lower than the picture's top,
  so its middle meets the picture's. Boxes: the shop 258 x 164, the Tab menu 242 x 134, the chest
  336 x 196 (seven lines a side, as before). The sheep is today's first frame with seven columns
  of its fleece taken out, its legs three columns each a column apart. See `LOG.md`.
- **Approved (2026-11-26).** Shown the summary and four before-and-after pairs (Tilda's list, the
  Tab menu, the chest, Oda's list), the user said "Approve, go on". It stands as built
  (`637a466`); step I2 begins on that word.

**Step I2 (only if Q2 is "yes"). A list of everything he carries in the Tab menu.**
- The Tab menu gets two lists, turned as the shop's are (left and right, or a click on a name):
  **"Food"** (as today: a click eats) and **"Pack"** (everything he carries, with its picture and
  count, to look at only: a click does nothing but point). It opens on Food, or on Pack when he has
  no food, so Tab always opens. Nothing on the Pack list goes into his hand: that stays the bar's.
- **Done when:** Pack lists every stack in the pack's order with its icon; Food is unchanged; Tab
  opens with no food; tests pass; pictures.
- **Tests:** Pack lists coins, keys, quest things, materials and tools; a click on Pack changes
  nothing in hand or in the pack; Tab with no food opens on Pack.
- **Built (2026-11-26), waiting for the user's review.** As written. What building it decided:
  the two names stand on a line of their own under the rule ("[Food]   Pack", gold, as the
  shop's "Buy" and "Sell"), and the heading reads the list shown ("Food" or "Pack"). The box is
  the shop's width, 258 x 150 (was 242 x 134), so each list's help line fits beside the count:
  Food's "Click: eat   A / D: turn   Tab: close", Pack's "A / D: turn   Tab: close" (a click
  is not offered there). Left and right turn the lists (they moved the cursor before; up, down
  and the wheel still do). What a tool holds is said on its line, not on a line of its own
  ("Watering Can (Water x10)"), as the chest leaves it out; coins read "412 coins"; a stack
  says its count even of one ("Small Key x1"), what never stacks only its name ("Hoe"). Food
  with nothing to eat says "You carry nothing to eat." (the words the area said before), and
  Pack with nothing at all "You carry nothing.". On Pack, Enter, Q and a click only point. The
  pure part is `PackList` (`core/inventory/`). Capture shots 210 to 213. See `LOG.md`.
- **Approved (2026-11-26).** Shown the summary and four shots of the Tab menu (Food, Pack, a
  full pack scrolled, Tab with no food), the user said "Approve, go on". It stands as built
  (`e3bb229`); step A1 begins on that word.

### Risks
- A taller line could push the shop's note line or help line past the box: the box grows with it, and
  the capture shots are checked by eye.
- The cursor mark now sits after the picture; if that reads badly in the pictures, the alternative is
  to draw the cursor before the picture, which changes `shown_lines()` and many tests. Kept as is
  unless the user asks.

---

## Part 2: an axe

### What it does (the recommendations, each a question below)

- **It cuts wood:** fallen branches, old stumps (both come back each morning), and on the homestead the
  fallen logs and old stumps (gone for good). It is a tool on the item bar, used from the item button
  or a left click, **at the cell he faces**, as the pickaxe is at a rock. Grass, weeds, bushes and pots
  stay the sword's; trees are not cut (Q5, Q11).
- **Wood wants the axe** (Q6): the sword no longer cuts branches, stumps or logs. A sword blow on wood
  makes a dull knock and he is told "It wants an axe." (once a visit, not at every swing). A bomb still
  breaks wood. This bends **D5** ("The sword and the pickaxe clear it"): it becomes "the sword, the
  axe and the pickaxe".
- **Blows, wood and energy as today** (Q7): the plain axe cuts a branch in 1 blow, a stump or a log in
  3, and each gives the wood it gives now. A blow costs 0.5 energy (`"chop": 0.5` in
  `data/rules/energy.json`, today's swing), so clearing costs what it costs now.
- **No skill** (Q8): chopping gives no points and nothing eases it.
- **Two better axes** (Q9), made at the workbench as the hoe's are: the **Copper Axe** (the axe and 2
  copper bars, once a copper bar has been found) and the **Iron Axe** (the copper axe and 2 iron
  bars, once an iron bar has been found). Their stats say `fewer_blows` 1 and 2, as the pickaxes'
  do: a stump or a log in 2 blows, then 1. The recipes go on the "Make" tab, which grows from
  thirteen to fifteen.
- **How it's had** (Q10): **it lies in the farmhouse**, a pickup by the hoe's place, so a new game
  and an old save both find it the first time he is home. It is not sold, so Tilda's list stays at
  sixteen. (Since the sword no longer cuts wood, nobody should pay to do what they did for free.)
- **Art, all the pack's:** the icon from `Items/Tool/Axe.png`; the copper and iron axes recoloured in
  the bars' colours, as phase C did the pickaxes; in his hands, the axe layer cut as the pickaxe's
  was, raised and struck in his existing work poses (`raise`, `strike`): 18 new frames at the end of
  `held_tools.png` (three axes, three facings, two poses), 40 x 56 with his feet at (20, 40). The
  stroke's sound and burst are the breakable's own (`cut`, splinters or leaves). No new sound.
- **The overgrowth:** the same 145 things, the same counts, blows (for the plain axe) and drops. Only
  what cuts the 10 logs and 14 stumps changes, and the two better axes cut them in fewer blows.

### How it is built
- `ToolUse.CHOP` (`"chop"`), a kind of tool like `PICK`; `ToolUse.decide_chop(at_wood)` says what a
  stroke does, `fewer_blows()` reads any tool's stat (not only the pickaxe's).
- A breakable's data says `"axe"` in `breaks_on` (the schema's enum gains it); with Q6 "yes", the four
  wood breakables lose `"sword"`. A blow of the axe counts as `1 + fewer_blows` of the breakable's
  `hits`.
- `AreaController._swing_axe()` beside `_swing_pick()`: the breakable in the cell faced, the stroke
  shown, energy paid once, the blow struck with `Hit.kind` `axe`. On the homestead what it clears
  goes through `GameState.clear_debris()` as now.
- `tools/play_days.gd` takes the axe to the field's two logs and two stumps; `tools/playtest.gd`'s
  `homestead`, `build` and `farm` scenarios carry an axe.

### Steps

**Step A1. The axe's pictures.** The three icons at the end of `items.png`, the 18 frames at the end
of `held_tools.png`, `art/sheets.json`, `HeldTools` and `ItemIcons` names, `docs/ASSETS.md`.
- **Done when:** `tests/art/` passes with the new frames; a sheet of the frames beside the pickaxe's
  is shown to the user.
- **Built (2026-11-26), waiting for the user's review.** As written: icons 77 to 79 of
  `items.png` (`axe`, `copper_axe`, `iron_axe`) and frames 57 to 74 of `held_tools.png` (the plain
  axe's six, then copper's, then iron's: down, up, side, each raised and struck), named by
  `ItemIcons.FRAMES` and `HeldTools` (`ADDED`, after every older frame; `ITEMS` knows the three
  ids, which A2 adds to the items' data). What building it decided: **the axe is cut from the
  pack's axe layer in the very windows the pickaxe was** (found by matching each pickaxe frame to
  its layer pixel for pixel), so his hands hold it where they hold the pickaxe; **in two poses
  (up raised, side struck) it is moved one pixel along its handle,** which lies flat there,
  because its blade is a column longer than the pickaxe's head and its tip's outline would have
  been cut by the 40-px frame. **The metals are phase C's** (read off the pickaxe and the hoe):
  copper's head in the copper bar's oranges and its handle darker wood, iron's head in the pale
  greys and blues; **the axe's bright edge, which no pickaxe has, is `ffcb8d` in copper and
  `ffffff` in iron** (both the palette's). No sound, no stroke, no item yet: nothing in play
  changes until A2. See `LOG.md`.
- **Approved (2026-11-27).** Shown the summary and two 8x close-ups (the axes on the hero's work
  poses beside the pickaxe's, and the frames alone), the user said "okay continue". It stands as
  built (`0b6c8c1`); step A2 begins on that word.

**Step A2. The axe in play.** The three items, `ToolUse.CHOP`, the stroke in the area, the breakables'
data, the energy rule, the two recipes, the pickup in the farmhouse, the tools' scripts.
- **Done when:** the axe cuts a branch, a stump and a log in the countryside and on the land; the
  sword doesn't (Q6); the copper and iron axes take fewer blows; energy is paid once a stroke; a new
  game and an old save find the axe at home; all tests pass; pictures of the hero chopping in three
  facings, the Make tab with the two recipes, and the bar with the axe.
- **Tests:** `ToolUse.decide_chop()` and `fewer_blows()` (pure); a stroke at a stump takes 3 blows
  (and 2 and 1 with the better axes) and leaves 2 wood; the sword's blow leaves a stump standing and
  says why; a bomb still breaks it; on the land a cleared log never comes back; the energy cost of a
  stroke; the recipes' unlocks; an old save (the v6 fixtures) loads and finds the axe in the
  farmhouse; the debris tests' wood cases move from the sword to the axe.
- **Built (2026-11-27), waiting for the user's review.** As written: the three axes are items
  (`"tool": "chop"`, `fewer_blows` 1 and 2 on the better two); `ToolUse.CHOP`, `decide_chop()`,
  `hits_of_blow()`, and `fewer_blows()` reading any tool's stat; `AreaController._swing_axe()` beside
  `_swing_pick()`, paying `"chop": 0.5` once a stroke and striking with `Hit.kind` `axe`; the four wood
  breakables say `"axe"` and not `"sword"`; a sword's blow on wood knocks and says "It wants an axe."
  once a visit; a bomb still breaks wood; the Copper Axe and the Iron Axe on the "Make" tab (fifteen
  lines with everything found, cloth and the blanket aside); the axe lying in the farmhouse at (4, 7);
  `play_days.gd` takes the axe (picked up on day 1, handed over in the farm trial) to logs and stumps;
  `playtest.gd`'s `homestead`, `build` and `farm` carry one; capture shots 214 to 218, and the films
  `axe_stump_side`, `axe_log_up`, `axe_log_down` and `sword_knocks_on_a_stump` in place of the sword's two wood films. The save
  is still version 6. What building decided (in `docs/DECISIONS.md`, 2026-11-27): **the axe lies on
  the open floor west of the doorway,** in the row of the seeds, the hoe and the can, and nothing in
  the room moved; **a blow is struck at once and shown at the blow,** as the pickaxe's is (the wood is
  down and its drop lying, hidden, until the axe comes down); **the knock is the sound `plate`** with no
  shudder or splinters, so it never looks like a blow that counted; **the axe facing no wood** says
  "There is no wood here to cut." and costs nothing; **the two recipes stand at the end of the tab**
  (no earlier line moved). See `LOG.md`.
- **Approved (2026-11-27).** Shown the summary and four pictures (chopping a stump, a film of
  three blows, the "Make" tab with both axes, the bar with the axe in hand), the user said
  "Approve, go on". It stands as built (`0ccd68c`); step B1 begins on that word.

### Risks
- **Taking the sword's wood away is a change to the game the user has played**, and to the
  Homestead's D5. It is the main question (Q6). If the answer is "keep the sword", the axe only cuts
  quicker, and the plain axe has nothing to give unless it also takes fewer blows than the sword.
- Every test that cuts a branch, stump or log with the sword changes (`debris_test.gd`, the wood
  tests of crafting); `play_days.gd`'s farm days change their route.
- A pickup in the farmhouse: the room is the old cottage's, cell for cell. The axe lies on an open
  floor cell, nothing moves.

---

## Part 3: arranging the item bar

### How it works (the recommendations)

- **Columns, fixed** (Q13): each thing on the bar keeps the column it is given. The bar is a list of
  columns, each holding one thing or nothing.
  - **The sword** has a column of its own (`HandBar.SWORD`), whichever sword is best.
  - **A thing used up** (the last bomb, the last seed of a kind) leaves its column **empty**, and it
    is remembered there: bought or found again, it comes back to the same column.
  - **A better tool takes the place of the one it was made from:** the Copper Hoe goes in the hoe's
    column (a new thing takes the column of a remembered thing of its own kind, by its tool kind,
    that he no longer carries).
  - **Anything new** takes the first empty column that remembers nothing, else a new column at the
    end.
  - **Without arranging, the bar is as today:** the sword, then the pack's order.
- **In play:** an empty column shows as an empty slot (its rim, no picture). The wheel steps over
  empty slots. A number key on an empty slot does nothing. Empty columns at the end are not drawn.
  With more than nine columns the bar still shows nine and moves along with the one in hand, as now.
  `GameState.equipped` is still always something he carries.
- **Where it is arranged** (Q12): **a seventh line in the pause menu, "Item bar"**, opening a screen
  of its own (`BarMenu`). It is done rarely, the pause menu already holds the settings, and its own
  screen leaves the movement keys free to move along the slots.
- **The screen:** the columns as the bar's slots, in rows of nine (two rows; a third when more are
  in use), the first row marked 1 to 9 as on the bar, with the name of the thing under the cursor
  below.
  - **Mouse:** the slot under the pointer is lit; **a click lifts** what is in it (it rises, the slot
    stays marked); **a click on another slot sets it down there**, swapping with what was there, or
    into an empty slot; a right click, Esc or Tab while something is lifted puts it back where it
    was. A click on no slot does nothing.
  - **Keys:** left and right (A/D, the arrows) and the wheel step a slot, up and down a row; Enter
    lifts and sets down; Tab or Esc leave (`MenuInput.is_back()`).
  - **Following the menu rules:** `MenuInput.let_clicks_through()`, a new pure `MenuPointer.cell_at()`
    (the slot under a point in a grid, beside `line_at()` and `part_at()`), the wheel as up and down
    through `MenuInput.is_up()` / `is_down()`, and the prompt line written with `MenuInput.prompt()`.
- **What is on the bar doesn't change:** only what can be in the hand (the sword, the bow, bombs,
  tools, seeds, the sprinkler). Nothing can be taken off the bar, and no food or placeable goes on it.

### The save (Q14)
**A field read with a default, and the version stays 6.** The save gains `"bar"`: the columns as
item ids, `"@sword"` for the sword, `""` for an empty column (`["@sword", "hoe", "", "watering_can"]`).
An older save has none, and is read as today's order, built from its pack. This is how the project
has added crafting's fields and the Homestead's phases 2 to 4 without a new version. **Said plainly:
CLAUDE.md's rule asks for a new version and a migration for any change to the save; those plans bent
it by decision, and this asks the user to bend it the same way.** The other way is version 7, with a
migration that writes today's order into `"bar"`, and a test from the v6 fixture. Either way there is
a test that every v6 fixture loads with the bar it had.

### How it is built
- **`HandBar` stays pure and tested**, and gains: `columns(bar, held)` (each column's entry, `{}` for
  empty), `settled(bar, held)` (the bar with every carried thing given a column, by the rules above),
  `moved(bar, from, to)` (a lift and set-down: a swap), `default_bar(stacks, items)` (today's order).
  `index_of()`, `stepped()` and `equipped_for()` work over columns and step over empty ones.
- `GameState.bar` (an `Array[String]`), settled whenever the pack changes (where `found` is marked),
  saved and read; `hand_entries()` returns the columns; `take_in_hand()` refuses an empty column;
  `move_on_bar(from, to)`.
- `ItemBar` draws an empty slot; `BarMenu` (`ui/bar_menu.gd`, `.tscn`) on the HUD; a line in
  `PauseMenu`.

### Steps

**Step B1. Columns.** `HandBar`'s columns and their rules, `GameState.bar`, the save's field, the bar
drawing empty slots, the wheel and the keys stepping over them. No screen yet: in play nothing looks
different until something is used up (its slot now stays empty) or upgraded (it keeps its column).
- **Done when:** the bar keeps an empty slot for the last seed and gives it back to the same seeds;
  a copper hoe takes the hoe's column; a new thing takes the first free column; the wheel skips
  empty slots and a key on one does nothing; the v6 fixtures load with today's order; all tests
  pass; pictures of the bar with an empty slot.
- **Tests (pure, `tests/core/`):** every rule above on its own; `stepped()` over empty columns, both
  ways, and with only the sword; `moved()` swaps and moves into an empty column; a remembered column
  is not given to something new; a save round-trips `bar`; an old save has none and gets today's
  order. The existing bar tests pass unchanged (the default is today's order).
- **Built (2026-11-27).** As written: `HandBar.SWORD` and `EMPTY`,
  `column_of()`, `default_bar()`, `cleaned()`, `settled()`, `columns()`, `moved()` and
  `is_empty_column()`, with `stepped()` and `index_of()` over empty columns; `GameState.bar`, settled by
  `add_item()` when something for the hand comes in and by `from_dict()`; `"bar"` in the save, version
  6, read with today's order when missing; `ItemBar` drawing an empty slot (its rim, no picture) and
  `is_empty_slot()`; `take_in_hand()` refusing one. What building it decided (in `docs/DECISIONS.md`,
  2026-11-27): **the first sword takes the front column**, so the sword is first as always; **a tool's
  kind is its `"tool"` stat**; **empty columns at the end are not drawn** (kept all the same); the wheel
  steps from thing to thing; **more than nine:** the columns count, empty ones too, and the bar moves
  along as before. Capture shots 219 to 221. Nothing looks different in play until something is used
  up or upgraded. See `LOG.md`.
- **Approved (2026-11-27).** Shown the summary and a before-and-after sheet of the bar (after the
  last seed, with the seeds back, with a copper hoe), the user said "Approve, go on". It stands as
  built (`12f89a5`); step B2 begins on that word.

**Step B2. The screen.** `BarMenu`, the pause menu's line, `MenuPointer.cell_at()`.
- **Done when:** the pause menu's "Item bar" opens it; mouse and keys lift and set down, swap and
  move into an empty slot; Esc puts a lifted thing back; leaving keeps the arrangement, which the bar
  shows at once and the save keeps; all tests pass; pictures of the screen and the bar after.
- **Tests:** `MenuPointer.cell_at()` (pure); keys and clicks on the screen (`_unhandled_input()` with
  mouse events at a slot's point, windowed where a test needs input); a lifted thing put back on Esc;
  the arrangement saved and loaded; the pause menu has seven lines (tests that count six change).
- **Built (2026-11-27), waiting for the user's review.** As written: the pause menu's fifth line
  "Item bar" (seven lines: Resume, Save, Quests, Friends, Item bar, Settings, Quit to title) opens
  `BarMenu` (`ui/bar_menu.gd`, `.tscn`) in the pause panel's place, with its slots drawn by
  `BarSlots` (`ui/bar_slots.gd`) in rows of nine, the first numbered 1 to 9, and the name of the thing
  under the cursor below; the cursor and the lift are `BarCursor` (`core/menus/`, pure);
  `MenuPointer.cell_at()` finds the slot under a point; `GameState.move_on_bar()` makes each move at
  once through `HandBar.moved()`. A click lifts, a click on another slot sets down (a swap, or into
  an empty slot), a click on its own slot, a right click, Esc or Tab puts back; a click on no slot
  does nothing; the movement keys step a slot or a row, the wheel a slot, Enter lifts and sets down.
  The save's `"bar"` keeps it, still version 6. What building it decided is in `docs/DECISIONS.md`
  (2026-11-27): the line's place, the screen as a page of the pause menu, each move made at once, the
  wheel a slot, the look of a lifted thing, remembered columns shown empty. Capture shots 222 to 224.
  See `LOG.md`.

### Risks
- **Every test that assumes the bar closes up** after the last seed or bomb (`HandBar`, `ItemBar`, the
  seeds' tests) changes: they now see an empty slot. CLAUDE.md's line "After the last bomb or seed
  `GameState.equipped` is empty" still holds.
- `hand_entries()` now has holes (`{}`): every caller that reads an entry's `id` must skip them. A
  search of the callers is part of B1.
- The pause menu's sixth line ("Quit") moves to seventh: tests and capture shots that choose it by
  number change.

---

## The order, and what stays as it is

**The order:** I1 (and I2 if Q2 says so), then A1, A2, then B1, B2: seven steps at most, each
committed and stopped for the user. The axe comes before the bar's columns so that the columns are
tested with it in the pack.

**Not planned (ask first):** icons in the gift list or the workbench; a coin picture beside the
shop's coins; felling trees; a skill for wood; selling the axe; taking things off the bar; a second
bar; arranging the build bar. Capture shots for this plan's steps start at 210.

---

## Questions for the user

**Icons**
- **Q1. "The store":** I read it as the shops (Tilda's and Oda's stall). The game's code also calls
  the chest "the store". **Recommendation: the shops, the Tab menu and the chest** (the same part, one
  more list). The gift list and the workbench not now.
- **Q2. The Tab menu lists food only** (your decision of 2026-11-15, when choosing what's in hand
  moved to the bar). Should it also show everything he carries? **Recommendation: yes, a second
  list "Pack"** beside "Food", to look at only, with icons and counts (step I2). Choosing what's in
  hand stays on the bar.
- **Q3. Size:** 16 px pictures in 16 px lines, five lines as now, the boxes about 24 px taller.
  **Recommendation: yes.** The other way keeps the boxes and shows four lines.
- **Q4. The sheep in Oda's list:** the pack has a hen and a cow but no sheep. **Recommendation: cut
  its picture from today's sheep** (as the world shows it), and list it as a gap. The other way leaves
  the sheep's line without one.

**The axe**
- **Q5. What it cuts:** **Recommendation: branches, stumps and logs** (wood). Not grass, weeds, bushes
  or pots.
- **Q6. Does the sword still cut wood?** **Recommendation: no, wood wants the axe** (a bomb still
  breaks it); this bends the Homestead's D5. The other way: the sword cuts as now and the axe only
  cuts quicker.
- **Q7. Blows and energy:** **Recommendation: as the sword's today** (branch 1, stump and log 3, the
  same wood; 0.5 energy a blow), so nothing costs more than now.
- **Q8. A skill:** **Recommendation: none.** The other way: Farming eases it (one word of data).
- **Q9. Better axes:** **Recommendation: a Copper Axe and an Iron Axe at the workbench**, made as the
  hoe's are (2 copper bars, then 2 iron bars), cutting a stump or a log in 2 blows, then 1.
- **Q10. How it's had:** **Recommendation: it lies in the farmhouse**, found by a new game and an old
  save alike; not sold. The other way: Tilda sells it for 25 coins, as the pickaxe.
- **Q11. Trees:** **Recommendation: not cut.** Felling trees needs trees that grow back and new rules,
  a plan of its own.

**The bar**
- **Q12. Where it's arranged:** **Recommendation: a line "Item bar" in the pause menu**, opening its
  own screen. The other ways: a third list in the Tab menu (where the movement keys turn the lists),
  or a key in play that moves the thing in hand one slot left or right.
- **Q13. Empty slots:** **Recommendation: fixed columns.** A thing keeps its column; used up, its slot
  stays empty and it comes back there; an upgrade takes its tool's column; anything new takes the
  first free one. The other way: no gaps, the bar closes up as now, and only the order is kept.
- **Q14. The save:** **Recommendation: a field read with a default, version 6 kept**, as crafting and
  the Homestead did. The other way: version 7 and a migration. Either way, a test that the old saves
  load with the bar they had.
