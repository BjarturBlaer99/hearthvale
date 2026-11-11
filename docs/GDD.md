# Hearthvale — Game Design Document

## 1. Pitch
A **2D top-down action-adventure** in the style of *A Link to the Past*. You start in **Hearthvale**, a small
medieval village. From there you explore the countryside, delve into dungeons full of enemies and puzzles, find
new weapons, and grow from three hearts into a hero.

## 2. Design pillars
1. **Curiosity pays.** Side paths, secrets and hidden heart pieces reward looking off the road.
2. **Every dungeon is a puzzle box built around its item.** You find the item inside, learn it on its puzzles,
   then need it to beat the boss.
3. **Readable fights.** Few enemy types, each with a clear tell; damage is measured in hearts, not numbers.
4. **Visible growth.** New weapons and heart containers change how you play, not just your stats.

## 3. Core loop
Village (talk, shop, rest) → countryside (explore, fight, find the way) → dungeon (keys, puzzles, the dungeon
item, the boss) → heart container and a new item that opens new paths → back to the village.

## 4. World
- **View:** top-down, 16×16 tiles, camera follows the hero. The world is split into **areas**: the village,
  house interiors, the countryside, and dungeons (room by room).
- **Terrain:** ground heights make cliffs and plateaus. **Stairs** connect levels; **ledges** can be hopped
  down (one way, never hurts); trees, rocks, walls, fences and water block the way. No swimming in the slice.
- **Hearthvale** (start): houses you can enter, a well, a chapel on the rise, a shop, a fenced field, a pond.
- **The countryside:** fields and a forest between the village and the first dungeon.
- **The first dungeon:** the Old Keep, north of the village.
- **The second dungeon:** the Chapel Crypt, under Hearthvale's chapel. Its door is barred until the keep is
  quiet. It's dark, and its floor has fallen in.

## 5. The hero
- Moves in 8 directions and faces 4. **E / A** interacts. Hold **Shift / B** to sprint (no stamina: it never
  runs out). No climbing or stamina. **Esc / Start** pauses: save, settings, quit to the title.
- **Life: hearts.** Start with **3**. Most hits cost **half a heart**. A **heart container** (from a boss) adds a
  heart and refills you; four **heart pieces** make a container (one is hidden in the slice; more after it). Hearts drop from enemies,
  grass and pots. At zero hearts you return to the area's entrance with full hearts.
- **Weapons and items (slice):**

| Item | Where | Use |
|---|---|---|
| **Wooden Sword** | Hearthvale (start of the adventure) | Swing in an arc in front of you |
| **Bow & arrows** | The first dungeon (its item) | Hit enemies and switches at range; arrows are ammo |
| **Bombs** | Hearthvale shop | Blow open cracked walls; hurt enemies |
| **Lantern** | The crypt (its item) | Carried: lights the dark around you, and lets you light torches with E |
| **Iron Sword** | The crypt's Knight's Tomb | Stronger sword: half as hard again as the wooden one |

- The sword is always on the attack button; one item is equipped on the item button. The Lantern needs no
  button: it works while it's carried.

## 6. Enemies (slice)
| Enemy | Where | Behaviour |
|---|---|---|
| **Slime** | Countryside, dungeon | Hops toward you; weak |
| **Goblin archer** | Countryside | Keeps its distance and shoots arrows |
| **Bat** | Dungeon | Erratic flight |
| **Iron Warden** (keep boss) | The keep | Stomps after you; blows clink off its iron. It opens its eye (the tell): an arrow there stuns it, then the sword hurts it. Rages at half health |

| **Crypt Shade** (crypt boss) | The crypt | Drifts after you; blows pass through it. Light all four braziers in its hall and the light binds it for a few seconds: now the sword hurts it. Then it snuffs them. Rages at half health: faster, with bolts |

Enemies sometimes drop hearts or coins.

## 7. Dungeons & puzzles
- Rooms on a grid; the camera shows one room at a time; doors between rooms.
- **Small keys** open locked doors in their dungeon. The **big key** opens the boss door.
- **Puzzle pieces:** push blocks, pressure plates, switches (hit with the sword or an arrow), cracked walls
  (bombs), and shutter doors that open when every enemy in the room is beaten.
- **Pits:** stepping into one costs half a heart and puts you back at its edge. A push block pushed in fills
  it. Enemies on foot keep out; bats and arrows cross.
- **The dark and torches:** in a dark dungeon you see only what light reaches. With the Lantern, E lights a
  torch; lit torches open doors. Some burn only for a few seconds, so several must be lit in one go.
- Each mechanic is introduced on its own, then combined.

## 8. Village & economy
- **Coins** drop from enemies, grass and pots. The Hearthvale shop sells bombs and arrows.
- Villagers give hints and small quests (data-driven).

## 9. Story (light)
Something has stirred in the old keep north of Hearthvale, and Elder Bram asks the hero to quiet it.

Long ago a knight, Sir Aldric, drove a Shade into the crypt under the village chapel and bound it with light. He
set the Iron Warden in the keep to watch: when the dark below stirs, the Warden wakes and bars the crypt. That is
what has happened. But the Warden is old and strikes at anyone, and beating it lifts the bars. The hero has
broken the lock, and has to finish what Aldric began: down into the dark with a light and Aldric's own sword.

It's told in a few lines: Elder Bram before and after the keep, inscriptions in the keep, by the chapel door and
in the crypt, and the closing words of each dungeon. The game ends when the Shade does.

## 10. Tone & look
Warm, cosy medieval: green meadows, half-timbered houses under thatch, red clay tiles or blue slate, with
smoking chimneys, and a stone chapel; darker, colder dungeons. 16×16 pixel art, limited palette: sunlit and
saturated, with shadows that lean violet, lights that lean yellow, and outlines in a dark shade of the thing
itself, not black. The look is Hearthvale's own, in the manner of cosy village pixel art. The hero is an
original adventurer in a blue hooded tunic with gold trim and a red scarf (Zelda-style, not Link).

## 11. Out of scope (for now)
Multiplayer, procedural generation, 3D, voice acting, swimming and water levels, an open world. Phase 2 (ROADMAP)
adds one region and a second dungeon, not an open world.
