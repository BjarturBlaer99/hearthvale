# Hearthvale — Game Design Document

**The pivot (2026-11-12).** Hearthvale began as a short top-down action-adventure. It is becoming a story-driven
RPG with survival and farming, in a modern pixel-art look of its own. Parts marked *(P1)* to *(P4)* are planned
for that phase of the pivot (`docs/ROADMAP.md`) and are not in the game yet; everything unmarked is built.
Numbers for energy, time, food and crops are starting values, kept in data so they can be tuned.

## 1. Pitch
A **cosy 2D story RPG with farming and survival**, seen from above. You settle in **Hearthvale**, a small
medieval village: you keep a plot, cook, sleep, and make friends. The days pass, and the old trouble under the
village does not go away: something has stirred in the keep to the north, and the hero is the one who can go.

It is Hearthvale's own game. It takes the mechanics of its genre, not any one game's art, interface or
characters.

## 2. Design pillars
1. **A day is a budget.** Energy and daylight are what you spend: on the plot, on the road, in a fight. Food and
   sleep give them back. *(P2)*
2. **The village is home.** A bed, a hearth, a plot, neighbours with hours and likes of their own. *(P2–P4)*
3. **Curiosity pays.** Side paths, secrets and hidden heart pieces reward looking off the road.
4. **Every dungeon is a puzzle box built around its item.** You find the item inside, learn it on its puzzles,
   then need it to beat the boss.
5. **Readable fights.** Few enemy types, each with a clear tell; damage is measured in hearts, not numbers.
6. **Visible growth.** New tools, weapons, recipes and heart containers change how you play, not just your
   stats.

## 3. Core loop
Morning at home (water the plot, eat) → the day's errand (the village, the countryside, a dungeon) → back before
dark (cook, sleep). Dungeons keep their own loop: keys, puzzles, the dungeon item, the boss, a heart container.

## 4. World
- **View:** from above, on a 16×16 grid, drawn at **640×360** *(P1)*. Outdoors the camera follows the hero;
  indoors and in dungeons it shows the room at twice the size *(P1)*. Tall things (trees, roofs) stand up from
  the ground, and the hero walks behind them *(P1)*.
- The world is split into **areas**: the village, house interiors, the countryside, and dungeons (room by room).
- **Terrain:** ground heights make cliffs and plateaus. **Stairs** connect levels; **ledges** can be hopped
  down (one way, never hurts); trees, rocks, walls, fences and water block the way. No swimming or climbing.
- **Hearthvale:** houses you can enter, a well, a chapel on the rise, a shop, a fenced field, a pond, and
  **cherry blossom trees** by the chapel, round the pond and along the main path *(P1)*.
- **The hero's home:** the thatched cottage west of the square, with a bed and a hearth *(P2)*, and a plot of
  soil across the road *(P3)*.
- **The countryside:** the South Field, the North Fields and the Old Wood.
- **The dungeons:** the Old Keep, north of the village, and the Chapel Crypt under the chapel. The crypt is
  barred until the keep is quiet. It's dark, and its floor has fallen in. A ruin in the South Field leads down
  to a small cellar and cistern.

## 5. The hero
- Moves in 8 directions and faces 4. **E / A** interacts. Hold **Shift / B** to sprint. **Esc / Start** pauses:
  save, quests, settings, quit to the title.
- **Life: hearts**, for combat only. Start with **3**. Most hits cost **half a heart**. A **heart container**
  (from a boss) adds a heart and refills you; four **heart pieces** make a container. Hearts drop from enemies,
  grass and pots. At zero hearts you return to the area's entrance with full hearts.
- **Energy** *(P2)*: a bar of 100, apart from hearts. It never costs hearts.

| Action | Energy |
|---|---|
| Sprinting | 0.25 a second |
| A sword swing or a bow shot | 0.5 |
| Hoeing a cell *(P3)* | 2 |
| Watering a cell *(P3)* | 1 |
| Walking, talking, harvesting | nothing |

  - **Low** (under 25): movement at 85%, the sword 30% slower. Under 10, no sprinting.
  - **At zero** the hero collapses, wakes at home the next morning with half energy and loses a tenth of his
    coins (30 at most). Dungeon progress is kept.
  - Until P2, sprinting is free, as it has been.
- **Weapons and items:**

| Item | Where | Use |
|---|---|---|
| **Wooden Sword** | Hearthvale's training yard | Swing in an arc in front of you |
| **Bow & arrows** | The Old Keep (its item) | Hit enemies and switches at range; arrows are ammo |
| **Bombs** | Hearthvale shop | Blow open cracked walls; hurt enemies |
| **Lantern** | The crypt (its item) | Carried: lights the dark around you, and lets you light torches with E |
| **Iron Sword** | The crypt's Knight's Tomb | Stronger sword: half as hard again as the wooden one |
| **Hoe**, **watering can**, **seeds** *(P3)* | Home, Tilda's shop | Used from the item button, like the bow |

- The sword is always on the attack button; one item is equipped on the item button. The Lantern needs no
  button: it works while it's carried. Food is eaten from the item menu *(P2)*.
- **Growth** *(P4, to be proposed)*: three skills (combat, farming, cooking) that rise with use.

## 6. Time, food and sleep *(P2)*
*(Built so far: the clock, the day and the light, in step 2a. The rest of this section is still to come.)*
- **A day** runs from 06:00 to 02:00 in 14 real minutes. At 02:00 the hero passes out, as at zero energy
  *(until 2b and 2c: a new day simply begins where he stands)*. The clock stops in conversations, in menus and
  in dungeons.
- **Light follows the hour:** peach at dawn, clear by day, orange then violet at dusk, blue at night. Lamps
  light at dusk *(windows too, in 2e)*.
- **Hours:** Tilda's shop is open 08:00 to 18:00; villagers who stand outdoors go home at 20:00.
- **Night monsters** (outdoors, 20:00 to 06:00): half as much health again, a little faster, and they see
  further. They drop coins more often.
- **Sleeping** in the bed at home ends the day, refills energy and hearts, and saves. Saving from the pause menu
  stays.
- **Food** restores energy; some meals heal a little. Raw crops can be eaten for about a third of their cooked
  worth. Cooking is done at the hearth at home, from recipes.

| Food | From | Energy | Hearts |
|---|---|---|---|
| Wild berries | foraged | 8 | |
| Mushroom | foraged in the Old Wood | 6 | |
| Bread | Tilda's shop, or 2 wheat | 30 | |
| Cherry blossom tea | 3 blossoms | 15 | |
| Roast turnip | 1 turnip | 22 | |
| Mushroom soup | 2 mushrooms, 1 potato | 35 | half |
| Vegetable stew | potato, carrot, turnip | 60 | one |
| Pumpkin pie | 1 pumpkin, 1 wheat | 80 | two |

## 7. Farming *(P3)*
- **The plot:** 18 cells of soil across the road from the hero's cottage.
- Hoe a cell, plant a seed, water it. A crop grows one stage each morning if it was watered the day before. Two
  dry mornings in a row and it withers. The watering can holds ten pours and refills at the well or the pond.
- No seasons and no weather.
- Harvested crops can be eaten, cooked, sold, or given to villagers *(P4)*.

| Crop | Days | Seed price | Sells for |
|---|---|---|---|
| Turnip | 3 | 5 | 12 |
| Carrot | 4 | 8 | 18 |
| Wheat | 5 | 6 | 10 |
| Potato | 5 | 10 | 24 |
| Pumpkin | 8 | 20 | 60 |

## 8. Enemies
| Enemy | Where | Behaviour |
|---|---|---|
| **Slime** | Countryside, dungeons | Hops toward you; weak |
| **Goblin archer** | Countryside, dungeons | Keeps its distance and shoots arrows |
| **Bat** | The ruin, dungeons | Erratic flight |
| **Iron Warden** (keep boss) | The keep | Stomps after you; blows clink off its iron. It opens its eye (the tell): an arrow there stuns it, then the sword hurts it. Rages at half health |
| **Crypt Shade** (crypt boss) | The crypt | Drifts after you; blows pass through it. Light all four braziers in its hall and the light binds it for a few seconds: now the sword hurts it. Then it snuffs them. Rages at half health: faster, with bolts |

Enemies sometimes drop hearts or coins.

## 9. Dungeons & puzzles
- Rooms on a grid; the camera shows one room at a time; doors between rooms.
- **Small keys** open locked doors in their dungeon. The **big key** opens the boss door.
- **Puzzle pieces:** push blocks, pressure plates, switches (hit with the sword or an arrow), cracked walls
  (bombs), and shutter doors that open when every enemy in the room is beaten.
- **Pits:** stepping into one costs half a heart and puts you back at its edge. A push block pushed in fills
  it. Enemies on foot keep out; bats and arrows cross.
- **The dark and torches:** in a dark dungeon you see only what light reaches. With the Lantern, E lights a
  torch; lit torches open doors. Some burn only for a few seconds, so several must be lit in one go.
- Each mechanic is introduced on its own, then combined.

## 10. Village & economy
- **Coins** drop from enemies, grass and pots, and come from selling crops *(P3)*.
- **Tilda's shop** sells bombs and arrows, and bread *(P2)* and seeds *(P3)*; it buys crops *(P3)*.
- Villagers give hints and small quests (data-driven). **Friendship** grows from talking and from gifts they
  like, and opens small quests and recipes *(P4, to be proposed)*.

## 11. Story
Something has stirred in the old keep north of Hearthvale, and Elder Bram asks the hero to quiet it.

Long ago a knight, Sir Aldric, drove a Shade into the crypt under the village chapel and bound it with light. He
set the Iron Warden in the keep to watch: when the dark below stirs, the Warden wakes and bars the crypt. That is
what has happened. But the Warden is old and strikes at anyone, and beating it lifts the bars. The hero has
broken the lock, and has to finish what Aldric began: down into the dark with a light and Aldric's own sword.

It's told in a few lines: Elder Bram before and after the keep, inscriptions in the keep, by the chapel door and
in the crypt, and the closing words of each dungeon. The main story ends when the Shade does.

*(P4)* The story spreads over days: Elder Bram's quest opens once the hero has settled in and planted a first
crop. The aim is the main story in six to eight in-game days.

## 12. Tone & look
Warm and cosy: a storybook countryside in modern pixel art. Green meadows, cherry blossom, half-timbered houses
under thatch, red clay tiles or blue slate, with smoking chimneys, and a stone chapel; darker, colder dungeons.
- Many shades per material and soft saturation; shadows lean violet and lights lean warm.
- Outlines only where a shape needs one, in a dark shade of the thing itself *(P1; today everything is outlined)*.
- Real light: lamps, hearths, torches and windows light what is near them, and the hour colours the air *(P1, P2)*.
- The world moves: grass, leaves and cloth in the wind, water with reflections and foam, petals, mist in the
  Old Wood *(P1)*.
- The hero is an original young adventurer: a blue tunic with gold trim, a red scarf, a leather vest, his sword
  on his back, and his hood worn down so his hair shows *(P1; today the hood is up)*.

## 13. Out of scope (unless asked)
Multiplayer, procedural generation, 3D, voice acting, swimming, climbing, seasons, weather, livestock of your
own, crafting beyond cooking, fishing, an inventory limit, an open world, new areas beyond the hero's home and
plot.
