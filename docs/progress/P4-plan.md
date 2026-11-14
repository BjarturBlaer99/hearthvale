# P4 — RPG and story

The fourth and last phase of the pivot (`docs/ROADMAP.md` P4). It was written as a proposal, as you asked
("Propose before building anything new in this phase; keep it small"), and **you approved it as written on
2026-11-13:** all ten decisions in section 3 stand as recommended. Each of the four steps has its own list
further down (section 10 on), written before the step is built.

## 1. What you asked for (2026-11-12)
- Keep Sir Aldric, the Iron Warden and the Crypt Shade at the core, but spread the story over days: Elder
  Bram's quest opens after the hero has settled in and planted a first crop.
- Light RPG progression: a simple level or skill system (combat, farming and cooking that improve with use)
  that changes how you play.
- Friendships with villagers through talking and gifts, unlocking small side quests and recipes.
- More dialogue and side quests in the existing quest data format.
- The ending screen with days survived, crops grown and friendships.

The roadmap's test for the phase: **a new player finishes the main story in six to eight in-game days with no
developer help.**

## 2. Where the game stands for this
- **The story has no gate.** Elder Bram's lines change with flags, but the keep can be entered without ever
  meeting him, and the crypt's bars lift the moment the Warden falls. A player can finish the story on the
  first day without planting anything.
- **Nothing tells a new player he has a cottage, tools and a plot.** He finds them by walking in. This was
  noted at steps 3a and 3b.
- **Seven villagers:** Elder Bram, Wenna and Tilda (indoors); Farmer Oda, Pip and Guard Rolf (in Hearthvale);
  the shepherd Edda (North Fields). **Three side quests.** The main story is not in the quest log at all.
- **The ending screen** says the time played, the hearts won and the quests finished.
- **Never yet done:** a whole-game playtest that reaches the ending, and a playtest by a new player.

## 3. Decisions I need from you
Each has my recommendation. The rest of this plan follows from them.

| # | Decision | Options | I recommend |
|---|---|---|---|
| 1 | The shape of progression | Three skills that rise with use; or one hero level; or none | **Three skills** (combat, farming, cooking), five levels each |
| 2 | What a level does | Only makes that skill's work cheaper or its meals better; or that plus a named perk per skill | **Cheaper and better only.** It is the smaller choice and still changes how much you can do in a day |
| 3 | What holds the story back | The keep's gate is chained until Bram gives the quest; or Guard Rolf bars the north road; or only Bram's words change | **The keep's gate.** The fields and the wood stay open for foraging |
| 4 | When Bram's quest opens | As soon as the first seed is in the soil; or the morning after | **As soon as it is planted** |
| 5 | The crypt after the keep | Its bars lift at dawn the day after the Warden falls; or at once, as now | **At dawn the next day.** It sends him home to sleep between the two dungeons |
| 6 | The friendship scale | Five marks a villager, four points a mark: talking once a day +1, a liked gift +3, another gift +1, one gift a day | **As described** |
| 7 | How a gift is given | A "give" answer in every villager's conversation opens a list of what he carries; or he gives what is on the item button | **The list**, like Tilda's |
| 8 | What friendship opens | At two marks a small side quest or a recipe; at four marks a present in return | **Yes: four new side quests and three new recipes in all** |
| 9 | Old saves | Any save made before this phase counts as past the story's gate | **Yes**, or a hero already inside the keep would be locked out |
| 10 | Steps | Four steps, each with tests, a commit and a review stop | **Four** |

## 4. The four steps
- **4a — The story over days.** A main quest in the quest log from the first morning; Bram's quest opens with
  the first crop; the keep's gate is chained until then; the crypt opens the morning after the keep. Save
  version 4, with a migration.
- **4b — Skills.** Combat, farming and cooking rise with use and are shown in the pause menu.
- **4c — Friendship and gifts.** Villagers as data, a mark for each four points, talking and giving.
- **4d — Side quests, recipes and the ending.** What friendship opens; the ending screen's new lines; a
  whole game played through.

## 5. Each part, with its numbers

### The story (4a)
- **A main quest, "A Place of Your Own",** in the existing quest format, started on the first morning. Its
  journal says where to go at each stage, which is the help a new player has lacked:
  1. Find your cottage (the thatched one west of the weaver's) and take what lies by the door.
  2. Till a cell of the plot and plant a seed.
  3. See Elder Bram, in the blue-roofed house.
  4. Quiet the Old Keep.
  5. Rest. The chapel's bars lift at dawn.
  6. Go down into the crypt.
- **Elder Bram before the first crop** welcomes the hero and sends him to settle in. Once a seed is planted he
  speaks of the lights over the keep, asks for the promise as he does today, and gives the word for the gate.
- **The keep's gate** in the Old Wood is chained until then. Facing it says so and names Bram.
- **The crypt's bars** lift at dawn on the day after the Warden falls. Today they lift at once.
- **The title's line** changes from "Something has stirred in the old keep north of the village." to "A
  cottage, a plot of soil, and lights over the old keep."
- **How a run of seven days might go** (to be checked in play, not promised):

| Day | What happens |
|---|---|
| 1 | The cottage, the tools, the first seeds planted. Bram's quest opens. The sword in the training yard |
| 2 | The fields and the wood: foraging, the first monsters. Tilda's shop |
| 3 to 4 | The Old Keep, the bow, the Warden. The first harvest |
| 5 | A day at home: selling, cooking, friends. The crypt's bars lift |
| 6 to 7 | The crypt, the lantern, the iron sword, the Shade |

### Skills (4b)
- **Three skills, five levels each,** with the numbers in data (`data/rules/skills.json`).
- **What raises them:**

| Skill | Raised by |
|---|---|
| Combat | 1 for each monster beaten, 10 for a boss |
| Farming | 1 for each cell tilled, 2 for each crop picked |
| Cooking | 2 for each dish cooked |

- **Levels** at 0, 10, 25, 50 and 90 points.
- **What each level above the first does:**

| Skill | Each level | At level 5 |
|---|---|---|
| Combat | A swing and a shot cost 10% less energy | 40% less: 0.3 a swing |
| Farming | Hoeing and watering cost 10% less energy | 40% less: 1.2 a cell hoed, 0.6 watered |
| Cooking | A dish he cooks gives 10% more energy | 40% more: a stew gives 84 |

- **Shown** as a line in the pause menu ("Combat 2   Farming 3   Cooking 1"), with a line of words and a
  chime when one rises.
- **My guess for a seven-day run:** combat near 4, farming near 4, cooking 2 or 3. Only a playtest says.
- Hearts are untouched: skills never change damage, speed or timing.

### Friendship and gifts (4c)
- **Villagers are data** (`data/villagers/<id>.json`): a name, the gifts they like, and what their friendship
  opens.
- **Twenty points a villager, a mark for every four** (five marks).
  - Talking to one for the first time each day: +1.
  - One gift a day: +3 for a gift they like, +1 for any other food or crop.
- **Giving:** every villager's conversation gains the answer "I brought you something.", which opens a list
  of the food and crops he carries. The answer is added by the game, so no conversation file changes for it.
- **Shown** on a "Friends" page beside the quest log in the pause menu: each villager and their marks.
- **Villagers who stand outdoors have gone home after 20:00,** as now: no talk and no gifts until morning.
- **What they like** (proposed):

| Villager | Likes |
|---|---|
| Elder Bram | Vegetable stew, cherry blossom tea |
| Wenna | Cherry blossoms, cherry blossom tea |
| Tilda | Pumpkin pie, wheat |
| Farmer Oda | Bread, pumpkin |
| Pip | Wild berries, pumpkin pie |
| Guard Rolf | Bread, mushroom soup |
| Shepherd Edda | Mushroom soup, carrots |

### Side quests, recipes and the ending (4d)
- **Four side quests,** each offered at two marks, each "bring this" in the existing format:

| Quest | From | Wants | Gives |
|---|---|---|---|
| A Pie for Pip | Pip | 1 pumpkin pie | 15 coins and a secret about the Old Wood's shrine |
| Rations for the Watch | Guard Rolf | 3 bread | 10 arrows and 20 coins |
| Seed Stock | Farmer Oda | 5 wheat | 3 pumpkin seeds |
| The Elder's Supper | Elder Bram | 1 vegetable stew | 30 coins and more of Sir Aldric's tale |

- **Three recipes,** each taught at two marks. The hearth lists what he knows; the six he has today are known
  from the start.

| Recipe | From | Makings | Energy | Hearts |
|---|---|---|---|---|
| Berry jam | Wenna | 3 wild berries | 20 | |
| Carrot cake | Tilda | 2 carrots, 1 wheat | 50 | half |
| Shepherd's pie | Shepherd Edda | potato, turnip, mushroom | 70 | one |

- **At four marks** each villager gives something once: seeds or coins. No hearts or heart pieces: the four
  pieces in the game make exactly one heart.
- **The ending screen** adds three lines to its three: "Days 7", "Crops grown 31", "Friends 3 of 7" (a
  friend is a villager at three marks or more).

## 6. What changes in the code

| System | What changes | Step |
|---|---|---|
| `GameState` | Skill points, friendship points and the day each villager was last talked to and given to, crops picked, the day the Warden fell. Save version 4 | 4a to 4c |
| `SaveSystem` | A version 3 to 4 migration, tested on a real version 3 save: no skill, no friends, and past the story's gate | 4a |
| Quests | The main quest and four side quests, as data | 4a, 4d |
| Conditions and effects | New conditions: a day has passed since a flag was set; friendship at least so many marks. New effects: add friendship, teach a recipe | 4a, 4c, 4d |
| Dialogue | New lines for Bram; a few for each villager; the "give" answer added by the game | 4a, 4c |
| `EnergyRules`, `Cooking` | Costs and a dish's energy pass through the skill's level | 4b |
| A new pure `Skills` and `Friendship` | The rules, with unit tests | 4b, 4c |
| `DataRegistry` and schemas | New kinds: villagers; new rule sets: skills, friendship | 4b, 4c |
| UI | A skills line in the pause menu; a Friends page; a gift list (Tilda's list, reused); three lines on the ending | 4b to 4d |
| The keep's gate, the crypt's bars | A chained gate that says why; bars that wait for dawn | 4a |
| Art and sound | A chain on the gate, a mark for friendship, three dish pictures; chimes for a level and a mark | 4a to 4d |
| Tools | Playtest scenarios for a late day; new screenshots | each |

## 7. Save version 4
One change of format for the whole phase, made in 4a. A version 3 save loads with no skill points, no
friendship and no crops counted, and counts as past the story's gate (decision 9). Versions 1 and 2 still load,
through every step.

## 8. Risks
- **Pacing can only be judged in play.** Six to eight days is a guess built from the numbers. The gates are few
  on purpose, and each is one line of data to move.
- **Three new systems in one phase.** Each is small, but together they are the most new rules since energy.
  The four stops keep them apart.
- **Friendship may be too slow or too fast.** With a liked gift every day a mark takes a little over a day; by
  talking alone it takes four. Both numbers are data.
- **Skills may be invisible.** Ten percent a level is felt over a day, not in a swing. If it reads as nothing,
  a named perk per skill is the next thing to try (decision 2).
- **The chained gate changes an old route.** Anyone who knew the way to the keep finds it shut on a new game
  until Bram speaks.
- **No whole-game playtest has ever reached the ending.** I propose one at the end of 4a, before the rest is
  built on it.

## 9. Not included unless you ask
A hero level or stat points, skill trees, perks, new weapons or monsters, new dungeons or areas, villagers who
walk about or keep a daily round, birthdays, festivals, romance, visiting villagers at home at night, gifts of
anything but food and crops, more than one gift a day, a calendar or seasons, crafting.

## 10. Step 4a — The story over days

### What changes
- **A main quest, "A Place of Your Own"** (`data/quests/a_place_of_your_own.json`), in the quest log from the
  first morning. It begins by itself: a quest may now say `"auto_start": true`. Its stages are the six in
  section 5, and each stage's words say where to go.
- **The first seed planted is remembered** (the flag `planted_first_crop`), which is what the quest and Elder
  Bram wait for.
- **Elder Bram greets a newcomer differently.** A conversation may now have `openings`: other places to begin,
  each with conditions, tried in order before its usual `start`. Before the first crop he welcomes the hero,
  says which cottage and plot are his and sends him to settle in. After it he speaks of the lights as he does
  today, and his promise also has the chain taken off the keep's gate (the flag `keep_gate_open`).
- **The keep's gate is chained** until then: a new kind of door, `chained`, in the Old Wood in front of the
  way in. It is drawn in code like the other doors. Walking up to it, or interacting with it, says that it is
  chained and that Elder Bram has the say over it.
- **The crypt's bars lift at dawn on the day after the Warden falls** (the flag `crypt_open`, set by the main
  quest). For that a flag's day is remembered (`GameState.flag_days`), with a new condition, `days_since`.
- **Words that spoke of the bars lifting at once** now speak of dawn: Bram's tale, Guard Rolf's two answers,
  the keep's closing words.
- **The title's line** becomes "A cottage, a plot of soil, and lights over the old keep."
- **Save version 4,** the one change of format for the whole phase. New in a save: the day each flag was set,
  skill points, friendship, and a tally (crops picked). Only the flags' days and the tally are used in this
  step: the skills' and the friends' places are kept empty until 4b and 4c. A version 3 save loads with all
  of them empty and counts as past the story's gates: the first crop counts as planted, the keep's gate is
  open, and the crypt's bars are up if the Warden has fallen.
- **Crops picked are counted** from now on, for the ending in 4d.
- **Tools:** playtest scenarios in Elder Bram's house with a first crop in (`-- bram`), below the chained
  gate (`-- gate`) and by the chapel on the day the Warden fell (`-- rest`); the first morning is `-- village`
  or the whole game (`-- full`); the old scenarios start past the gates; new screenshots.

### What does not change
- The maps: none is re-baked. The gate and the bars are nodes in their areas.
- The dungeons, the bosses, combat, energy, the farm's rules, the shop, the hours, the three side quests.
- Where a new game begins (the square in Hearthvale).

### Done when
- [x] a new game has "A Place of Your Own" in the quest log, and it moves on as the hero takes the tools,
      plants a seed, speaks to Bram, quiets the keep, sleeps, and ends the Shade
- [x] before the first crop Elder Bram welcomes the hero and does not speak of the keep; after it he does
- [x] the keep's gate can't be passed on a new game, and says why, naming Elder Bram; after the promise it can
- [x] the crypt's bars stay down on the day the Warden falls and are up the next morning
- [x] `days_since`, `auto_start` and `openings` are checked on load, in the schemas, and unit-tested
- [x] a version 3 save loads as version 4, past the gates, with nothing lost; versions 1 and 2 still load
- [x] the title shows the new line
- [x] all earlier tests pass
- [ ] (yours) the first day reads clearly to someone who has never played: where to go, and why the keep waits

### Not in this step
- Skills (4b), friendship and gifts (4c), the new side quests, recipes and the ending's lines (4d).
- A tutorial, pop-up hints or markers on a map: the quest log's words are the help.
- A new place to start the game, or a scene of arriving.

## 11. Step 4b — Skills

### What changes
- **Three skills, five levels each,** as section 5 has them: combat, farming and cooking, with levels at 0,
  10, 25, 50 and 90 points. The numbers are data (`data/rules/skills.json`), read by a new pure `Skills`
  (`core/skills/`).
- **What raises them:** a monster beaten 1 point of combat and a boss 10; a cell tilled 1 point of farming
  and a crop picked 2; a dish cooked 2 points of cooking.
- **What a level does:** each level above the first takes a tenth off the energy a skill's work costs: a
  swing and a shot for combat, the hoe and the can for farming. Each level of cooking adds a tenth to the
  energy a dish gives. Which costs a skill eases is in the data too.
- **A dish is anything a recipe makes,** and the cook's level counts when it is eaten. So Tilda's bread, which
  is the same bread the hearth bakes, is richer for a good cook too. (A dish does not remember who made it.)
- **Cooking is counted through a new effect, `practise`,** which the hearth's conversation gives each dish.
  Any conversation or quest may use it.
- **A level rising is said once,** at the top of the screen ("Farming rose to level 2."), with a chime of its
  own (a new sound, made by the audio tool).
- **The pause menu shows the three levels** on a line of its own: "Combat 2   Farming 3   Cooking 1".
- **The item menu and the words on eating** show what a dish gives him now, not what its data says.
- **Tools:** `skills=<level>` after a playtest scenario's name starts with every skill at that level; new
  screenshots.

### What does not change
- Hearts, damage, speed, cooldowns and every timing: a skill only changes energy.
- Sprinting costs what it did, at every level.
- What food gives in hearts, and what food that is not cooked gives (berries, raw crops).
- The save format: skill points have had their place since version 4 (step 4a). A game saved before this
  step starts every skill at level 1.

### Done when
- [x] the skills' numbers are data, checked on load, with a schema; `Skills` is unit-tested: levels, points,
      what a level takes off and adds
- [x] a monster, a boss, a tilled cell, a picked crop and a cooked dish each give their points, once
- [x] at each level a swing, a shot, the hoe and the can cost what section 5's table says, and a dish gives
      what it says; sprinting and hearts are as they were
- [x] a level rising is said once, with a chime; the pause menu shows the three levels
- [x] skill points go through a save, and a version 3 save starts at level 1
- [x] all earlier tests pass
- [ ] (yours) a level is felt over a day's work, not only read in the menu

### Not in this step
- Perks, a hero level, a skills screen, a bar toward the next level: not in P4 (section 9).
- Skills changing damage, speed or anything but energy.
- Friendship (4c); side quests, recipes and the ending's lines (4d).

## 12. Step 4c — Friendship and gifts

### What changes
- **The seven villagers are data** (`data/villagers/<id>.json`, a new kind with a schema): a name, the
  conversation that is theirs, the gifts they like (section 5's table), and what they say to a gift they like
  and to any other. Nothing in a scene changes: the game knows who is spoken to by the conversation.
- **Friendship is twenty points a villager, a mark for every four** (five marks). The numbers are data
  (`data/rules/friendship.json`), read by a new pure `Friendship` (`core/friendship/`).
  - Talking to a villager for the first time in a day: 1 point.
  - A gift: 3 points if they like it, 1 for any other. One gift a villager a day.
- **What can be given:** food and what is cooked with (so cherry blossoms can be). Not tools, seeds, coins or
  anything else.
- **Giving:** a villager's conversation gains the answer "I brought you something." where it begins, when he
  has not given them anything that day and carries something that can be given. It is added by the game: no
  conversation file changes. Choosing it opens a list of what he carries, in the shape of Tilda's list; he
  picks one thing, the villager says their words, and the list closes.
- **A mark gained is said once,** at the top of the screen, with a chime of its own (a new sound).
- **A "Friends" page in the pause menu,** beside "Quests": every villager and their marks, drawn as five small
  blossoms, and a line that says how friendship grows.
- **A new effect, `gift`** (a villager), which opens the list when the conversation is over, as `shop` does.
- **Tools:** a playtest scenario by Pip with a pack of food (`-- gifts`); new screenshots.

### What does not change
- The villagers' conversations as files, where they stand, and their hours: those who stand outdoors are
  away from 20:00 to 06:00, so there is no talk and no gift then.
- The save format: friendship has had its place since version 4 (step 4a). A game saved before this step
  has no friends yet.
- What a gift is worth to the hero if he eats it instead: food is food.

### Done when
- [x] the villagers and the numbers are data, checked on load, with schemas; `Friendship` is unit-tested:
      marks, what a talk and a gift give, what can be given
- [x] the first talk of a day gives a point, and a second that day gives none
- [x] a liked gift gives three points and another gives one; a second gift that day can't be given
- [x] the answer shows only when there is something to give and nothing was given that day; no conversation
      file is changed for it
- [x] a mark gained is said once, with a chime; the Friends page shows every villager's marks
- [x] friendship goes through a save, and a version 3 save has none
- [x] all earlier tests pass
- [ ] (yours) giving feels worth the food, and the marks come at a pace that feels right

### Not in this step
- What friendship opens: the side quests, the recipes and the presents are step 4d. So are the condition
  that asks for so many marks and the effect that adds friendship, which only they would use.
- Birthdays, villagers who walk about, gifts of anything but food, more than one gift a day (section 9).
- Showing on the Friends page what each villager likes: it is found by giving.

## 13. Step 4d — Side quests, recipes and the ending

### What changes
- **What friendship opens is in each villager's conversation,** as data: an opening (step 4a's `openings`)
  on a new condition, `friendship` (a villager and so many marks).
  - **At two marks** four villagers ask a favour and three teach a recipe (the tables in section 5).
  - **At four marks** each gives a present, once: Elder Bram 40 coins, Wenna 25 coins, Tilda 3 potato seeds,
    Farmer Oda 3 carrot seeds, Pip 10 coins, Guard Rolf 30 coins, Shepherd Edda 4 wheat seeds.
- **Four side quests** in the quest format, each "bring this": A Pie for Pip, Rations for the Watch, Seed
  Stock, The Elder's Supper. A favour can be put off ("Not just now.") and is asked again at the next talk.
- **Three recipes that are taught:** berry jam (Wenna), carrot cake (Tilda), shepherd's pie (Shepherd Edda). A
  recipe may now say `"taught": true`; the hearth lists the recipes he knows, and a new effect,
  `teach_recipe`, teaches one. The six from before are known from the start. Three new dishes, with pictures.
- **Berry jam gives 30 energy, not the table's 20.** Three wild berries eaten raw give 24, and step 3c's rule
  (and its test) is that a dish is worth more than its makings.
- **The quest log scrolls:** five quests show at a time, and with these there can be eight.
- **The ending screen has three more lines:** the days it took, the crops grown, and friends out of seven (a
  friend is a villager at three marks or more: a number in the friendship rules).
- **The whole story in one test,** from the first morning to the ending's lines, through every gate and with
  a friend made, a favour done and a recipe learned on the way.
- **Tools:** a playtest scenario on a late day (`-- late`: the sixth morning, the crypt open, every villager
  one gift short of two marks); new screenshots.

### What does not change
- The save format: a recipe known and a present given are flags, and quests are saved as quests.
- The main quest, the three older side quests, and what each villager already says.
- The rules of friendship from 4c: what a talk and a gift are worth, and one gift a day.

### Done when
- [x] `friendship`, `teach_recipe` and a recipe's `taught` are checked on load, in the schemas, and unit-tested
- [x] at two marks each of the four asks their favour, and the quest can be taken, put off, and finished for
      the reward in section 5's table
- [x] at two marks each of the three teaches their recipe once, and the hearth then lists it and cooks it
- [x] at four marks each of the seven gives their present, once
- [x] the quest log shows more quests than its box holds, five at a time
- [x] the ending shows the days, the crops grown and the friends made
- [x] one test carries a new game through the story's gates to the ending's lines
- [x] all earlier tests pass
- [ ] (yours) a whole game, played from the title to the ending, in six to eight days with no help

### Not in this step
- The effect that adds friendship: the plan lists it, but nothing in the plan's content would use it.
- Friendship written into the villagers' data files as "what it opens": it is in their conversations, where
  quests have always been offered.
- More quests, recipes or villagers than section 5's tables; anything in section 9.

