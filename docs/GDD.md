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
- **The first dungeon:** an old keep north of the village (working name).

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
| **Iron Sword** | Reward (TBD) | Stronger sword |

- The sword is always on the attack button; one item is equipped on the item button.

## 6. Enemies (slice)
| Enemy | Where | Behaviour |
|---|---|---|
| **Slime** | Countryside, dungeon | Hops toward you; weak |
| **Goblin archer** | Countryside | Keeps its distance and shoots arrows |
| **Bat** | Dungeon | Erratic flight |
| **Iron Warden** (keep boss) | The keep | Stomps after you; blows clink off its iron. It opens its eye (the tell): an arrow there stuns it, then the sword hurts it. Rages at half health |

Enemies sometimes drop hearts or coins.

## 7. Dungeons & puzzles
- Rooms on a grid; the camera shows one room at a time; doors between rooms.
- **Small keys** open locked doors in their dungeon. The **big key** opens the boss door.
- **Puzzle pieces:** push blocks, pressure plates, switches (hit with the sword or an arrow), cracked walls
  (bombs), and shutter doors that open when every enemy in the room is beaten.
- Each mechanic is introduced on its own, then combined.

## 8. Village & economy
- **Coins** drop from enemies, grass and pots. The Hearthvale shop sells bombs and arrows.
- Villagers give hints and small quests (data-driven).

## 9. Story (deliberately light for now)
Something has stirred in the old keep north of Hearthvale. The story stays thin until the slice plays well.

## 10. Tone & look
Warm, cosy medieval: green meadows, timber houses, red and blue roofs; darker, colder dungeons. 16×16 pixel art,
limited palette. The hero is an original adventurer in a blue hooded tunic with gold trim (Zelda-style, not Link).

## 11. Out of scope (for now)
Multiplayer, procedural generation, 3D, voice acting, swimming and water levels, an open world. Phase 2 (ROADMAP)
adds one region and a second dungeon, not an open world.
