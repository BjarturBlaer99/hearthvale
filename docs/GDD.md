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
- **The hero's home:** the thatched cottage west of the weaver's, with a bed and a hearth, and a plot of soil
  across the road, between the shop and the well.
- **The countryside:** the South Field, the North Fields and the Old Wood.
- **The dungeons:** the Old Keep, north of the village, and the Chapel Crypt under the chapel. The crypt is
  barred until the keep is quiet. It's dark, and its floor has fallen in. A ruin in the South Field leads down
  to a small cellar and cistern.

## 5. The hero
- Moves in 8 directions and faces 4, on the keys. The mouse is as in farming games: **the left button uses
  what is in hand** (the sword, or the tool or item on the item button) and **the right button / A
  interacts** with people and things. In a conversation the left button answers and reads on. They are buttons:
  where a click lands doesn't matter, and he acts on what he faces. Hold **Shift / B** to sprint. **Esc / Start** pauses:
  save, quests, settings, quit to the title.
- **Life: hearts**, for combat only. Start with **3**. Most hits cost **half a heart**. A **heart container**
  (from a boss) adds a heart and refills you; four **heart pieces** make a container. Hearts drop from enemies,
  grass and pots. At zero hearts you return to the area's entrance with full hearts.
- **Energy**: a bar of 100, apart from hearts. It never costs hearts. Sleep refills it; so will food *(2d)*.

| Action | Energy |
|---|---|
| Sprinting | 0.25 a second |
| A sword swing or a bow shot | 0.5 |
| Hoeing a cell | 2 |
| Watering a cell | 1 |
| Walking, talking, harvesting | nothing |

  - **Low** (under 25): movement at 85%, the sword 30% slower. Under 10, no sprinting.
  - **At zero** the hero collapses, wakes at home the next morning with half energy and loses a tenth of his
    coins (30 at most). Dungeon progress is kept.
  - Staying up until the day runs out (02:00) costs the same as collapsing.
- **Weapons and items:**

| Item | Where | Use |
|---|---|---|
| **Wooden Sword** | Hearthvale's training yard | Swing in an arc in front of you |
| **Bow & arrows** | The Old Keep (its item) | Hit enemies and switches at range; arrows are ammo |
| **Bombs** | Hearthvale shop | Blow open cracked walls; hurt enemies |
| **Lantern** | The crypt (its item) | Carried: lights the dark around you, and lets you light torches with a right click |
| **Iron Sword** | The crypt's Knight's Tomb | Stronger sword: half as hard again as the wooden one |
| **Hoe**, **watering can** | Home, by the door | Used from the item button, like the bow, on the cell you face |
| **Seeds** *(3b)* | Home (a first pouch), Tilda's shop *(3c)* | Planted from the item button |

- The sword is always on the attack button (Space); one item is equipped on the item button (Q). The Lantern
  needs no button: it works while it's carried. Food is eaten from the item menu *(P2)*.
- **In hand** (the left mouse button): with nothing on the item button, the sword. The bow or bombs on it:
  those, until the arrows or the bombs run out; then the sword again. A farm tool or seeds on it: the tool
  where there is work for it (facing the plot, or water for the can), and the sword everywhere else. Choosing
  the sword in the item menu empties the item button.
- **A full pack loses nothing:** what lies in the world, what grows to be gathered, what a chest holds and a
  ripe crop stay where they are until he can carry all of it, and he is told why.
- **Growth** *(P4b)*: three skills that rise with use, five levels each, at 0, 10, 25, 50 and 90 points.

| Skill | Raised by | Each level above the first |
|---|---|---|
| Combat | 1 for a monster beaten, 10 for a boss | A swing and a shot cost a tenth less energy |
| Farming | 1 for a cell tilled, 2 for a crop picked | The hoe and the can cost a tenth less energy |
| Cooking | 2 for a dish cooked | A dish gives a tenth more energy |

  At level 5 a swing costs 0.3, a cell hoed 1.2 and watered 0.6, and a stew gives 84. A level rising is said
  once, and the pause menu shows the three. A dish is anything a recipe makes, so bread bought from Tilda is
  richer for a good cook too. Skills change energy and nothing else: never hearts, damage, speed or timing.

## 6. Time, food and sleep *(P2)*
*(Built so far: the clock, the day and the light in step 2a; the home, the bed and sleeping in 2b; energy in
2c; food, foraging and cooking in 2d; hours and the night in 2e; the meals made from crops in step 3c.)*
- **A day** runs from 06:00 to 02:00 in 14 real minutes. At 02:00 the hero passes out, as at zero energy, and
  wakes by his bed the next morning with half his energy and a tenth of his coins gone. The clock stops in
  conversations, in menus and in dungeons.
- **Light follows the hour:** peach at dawn, clear by day, orange then violet at dusk, blue at night. Lamps
  and house windows light at dusk and go out at dawn.
- **Hours:** Tilda's shop is open 08:00 to 18:00: outside those hours its door is shut and says when it
  opens (once inside, he can always leave). Villagers who stand outdoors go home at 20:00 and are back at
  06:00; those indoors stay where they are.
- **Night monsters** (outdoors, 20:00 to 06:00): half as much health again, 15% faster, and they see 30%
  further. They drop coins twice as often. They hit no harder. A monster is a night monster if he comes upon
  it at night: it is decided as he enters the area. Dungeons have no night, and bosses are never changed.
  Night monsters show pale in the dark.
- **The night has its own tune** out of doors.
- **Sleeping** in the bed at home ends the day, refills energy and hearts, and saves. He can sleep at any hour.
  Saving from the pause menu stays.
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
| Berry jam *(taught by Wenna)* | 3 wild berries | 30 | |
| Carrot cake *(taught by Tilda)* | 2 carrots, 1 wheat | 50 | half |
| Shepherd's pie *(taught by Shepherd Edda)* | potato, turnip, mushroom | 70 | one |

The last three are not known from the start: a villager teaches each as a friend (§10).

## 7. Farming *(P3)*
*(Built: the plot, the hoe and the watering can in step 3a; seeds and crops in 3b; buying, selling and the
meals in 3c.)*
- **The plot:** 18 cells of soil (6 by 3) across the road from the cottages, between Tilda's shop and the
  well. It is ground: the hero walks over it.
- Hoe a cell, plant a seed, water it. A crop grows one stage each morning if it was watered the day before. Two
  dry mornings in a row and it withers. The watering can holds ten pours and refills at the well or the pond.
- A tool works on the cell the hero faces, and takes a moment. A tool with nothing to do says so and costs
  nothing. Watered soil is dry again each morning; tilled soil stays tilled.
- **Seeds** go on the item button like the tools: one is planted in the tilled, empty cell he faces. Planting
  costs no energy. The first pouch (five turnip seeds) lies at home with the tools; the rest are bought.
- **Watering starts the dry count again.** A ripe crop waits to be picked: it needs no more water and never
  withers.
- **Picking:** facing a ripe crop, a right click puts it in the pack and leaves tilled soil. Facing a withered
  one, a right click clears it away. Neither costs energy.
- **Crops never block.** The hero walks through his plot whatever grows there and tramples nothing.
- **Raw**, a crop gives about a third of what it is worth cooked: turnip 7 energy, carrot 7, wheat 5, potato 8,
  pumpkin 22.
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
- **The dark and torches:** in a dark dungeon you see only what light reaches. With the Lantern, a right click lights a
  torch; lit torches open doors. Some burn only for a few seconds, so several must be lit in one go.
- Each mechanic is introduced on its own, then combined.

## 10. Village & economy
- **Coins** drop from enemies, grass and pots, and come from selling crops.
- **Tilda's shop** has a list to buy from and a list to sell on, opened from her conversation. She sells ten
  arrows (5 coins), three bombs (8), a loaf of bread (6), and a seed of each crop at its price (§7). She buys
  what the crops give, one at a time, at each crop's price, and nothing else. The list stays open for as many
  deals as he likes and says why one can't be made: not enough coins, no room to carry it, a full purse. She
  is open from 08:00 to 18:00 (§6).
- Villagers give hints and small quests (data-driven).
- **Friendship** *(P4c)* is twenty points a villager, a mark for every four: five marks.
  - The first talk of a day is worth 1 point.
  - A gift is worth 3 if they like it and 1 if not. One gift a villager a day.
  - Food and what is cooked with can be given, and nothing else. With something to give, a villager's
    conversation offers "I brought you something.", which opens a list of what he carries.
  - A mark gained is said once; the pause menu's Friends page shows every villager's marks.
  - **At two marks** a villager asks a favour or teaches a recipe *(P4d)*:

| Villager | At two marks | Gives |
|---|---|---|
| Pip | A Pie for Pip: 1 pumpkin pie | 15 coins, and a secret about the Old Wood's shrine |
| Guard Rolf | Rations for the Watch: 3 bread | 10 arrows and 20 coins |
| Farmer Oda | Seed Stock: 5 wheat | 3 pumpkin seeds |
| Elder Bram | The Elder's Supper: 1 vegetable stew | 30 coins, and more of Sir Aldric's tale |
| Wenna | teaches berry jam | |
| Tilda | teaches carrot cake | |
| Shepherd Edda | teaches shepherd's pie | |

  - **At four marks** each gives a present, once: Elder Bram 40 coins, Wenna 25 coins, Tilda 3 potato seeds,
    Farmer Oda 3 carrot seeds, Pip 10 coins, Guard Rolf 30 coins, Shepherd Edda 4 wheat seeds. No hearts.
  - A favour can be put off and is asked again at the next talk.

| Villager | Likes |
|---|---|
| Elder Bram | Vegetable stew, cherry blossom tea |
| Wenna | Cherry blossoms, cherry blossom tea |
| Tilda | Pumpkin pie, wheat |
| Farmer Oda | Bread, pumpkin |
| Pip | Wild berries, pumpkin pie |
| Guard Rolf | Bread, mushroom soup |
| Shepherd Edda | Mushroom soup, carrots |

## 11. Story
Something has stirred in the old keep north of Hearthvale, and Elder Bram asks the hero to quiet it.

Long ago a knight, Sir Aldric, drove a Shade into the crypt under the village chapel and bound it with light. He
set the Iron Warden in the keep to watch: when the dark below stirs, the Warden wakes and bars the crypt. That is
what has happened. But the Warden is old and strikes at anyone, and beating it lifts the bars. The hero has
broken the lock, and has to finish what Aldric began: down into the dark with a light and Aldric's own sword.

It's told in a few lines: Elder Bram before and after the keep, inscriptions in the keep, by the chapel door and
in the crypt, and the closing words of each dungeon. The main story ends when the Shade does.

**Over days (P4a).** The story is spread over the days of the game, and a main quest, "A Place of Your Own",
is in the quest log from the first morning. Its words say where to go at each stage:
1. Find the cottage and take what lies inside its door: the hoe, the watering can, a pouch of seeds.
2. Till a patch of the plot and plant a seed.
3. See Elder Bram. Before the first crop he only welcomes the hero and sends him to settle in. After it he
   speaks of the lights over the keep and asks for the promise.
4. Quiet the Old Keep. Its gate in the Old Wood is chained until Bram gives his word.
5. Rest. The chapel's bars lift at dawn on the day after the Warden falls.
6. Go down into the crypt.

The aim is the main story in six to eight in-game days. Whether it runs to that is for a playtest.

**The ending** *(P4d)* says how long the game took, the hearts won and the quests finished, and then the days
it took, the crops grown, and how many of the seven villagers are friends (three marks or more).

**More of Sir Aldric** *(P4d)*: for his supper Elder Bram tells that Aldric was a farmer of the valley before
he took up the sword, and that the hero's cottage was his.

## 12. Tone & look
Warm and cosy: a storybook countryside in modern pixel art. Green meadows, cherry blossom, half-timbered houses
under thatch, red clay tiles or blue slate, with smoking chimneys, and a stone chapel; darker, colder dungeons.
- Many shades per material and soft saturation; shadows lean violet and lights lean warm.
- Outlines only where a shape needs one, in a dark shade of the thing itself *(P1; today everything is outlined)*.
- Real light: lamps, hearths, torches and windows light what is near them, and the hour colours the air *(P1, P2)*.
- The scenery is still, but for the water: it ripples, foams at the bank and mirrors what stands by it. Petals
  lie under the cherry trees and mist lies in the Old Wood. *(Until 2026-11-13 the grass, the trees and the
  washing moved in the wind, petals and specks drifted and the mist with them; the user asked for a still
  world.)*
- The hero is an original young adventurer: a blue tunic with gold trim, a red scarf, a leather vest, his sword
  on his back, and his hood worn down so his hair shows *(P1; today the hood is up)*.

## 13. Out of scope (unless asked)
Multiplayer, procedural generation, 3D, voice acting, swimming, climbing, seasons, weather, livestock of your
own, crafting beyond cooking, fishing, an inventory limit, an open world, new areas beyond the hero's home and
plot.
