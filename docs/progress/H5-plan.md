# H5 — Dungeon framework (plan)

Goal (ROADMAP H5): rooms with a camera per room and doors between them; small keys and locked doors; the big key
and boss door; shutter doors; dungeon state (opened doors, keys held, chests opened) in GameState.

## Design
- **Rooms on a grid:** a dungeon is one area whose map is cut into equal rooms (`room_size` on the
  AreaController). `RoomGrid` (pure) gives the room of a cell and its rectangle. The camera shows only the
  hero's room, centred when it's smaller than the screen, and flashes briefly when the hero crosses into another.
- **Dungeon state** (`DungeonState`, pure) is all flags in GameState, named per dungeon:
  - `dungeon/<id>/keys` (small keys held for that dungeon) and `dungeon/<id>/big_key`
  - `dungeon/<id>/door/<door>` (opened) and `dungeon/<id>/chest/<chest>` (opened)

  Leaving and coming back, or saving and loading, keeps it all. Keys belong to their dungeon, not the
  inventory.
- **Doors** (`DungeonDoor`, set into the wall between rooms, 1–2 cells; closed doors fill their cells):
  - **open**: just a doorway
  - **locked**: E with a small key spends it and opens it for good
  - **boss**: E with the big key (not spent) opens it for good
  - **shutter**: bars that lift once a flag is set
- **Chests** (`Chest`): face one and press E. A small key or the big key goes to the dungeon's count; anything
  else goes to the inventory. Opened chests stay open.
- **Clearing a room:** enemies can name a `clear_flag`. When every enemy with that flag is beaten, the flag is
  set, and a shutter waiting on it opens. Enemies still come back on the next visit; the opened shutter stays
  open.
- **Interact:** after pickups and people, E uses the door or chest in front. The HUD prompt says what E will do,
  and in a dungeon the HUD shows the keys held.
- **Tiles:** dungeon floor, stairs down (walkable), dungeon wall, pillar (solid).
- **The test dungeon: the Ruin Cellar**, down stairs in the South Field's ruin, with three rooms stacked
  north to south:
  1. **Entry hall:** a chest with a small key, and a locked door north.
  2. **Hall:** two slimes; beating them lifts a shutter into a side alcove with the big key chest. The boss door
     is north.
  3. **Inner room:** a chest of coins (the boss room's place, until H7).

## Acceptance criteria (from ROADMAP)
- [x] a three-room test dungeon needs a small key to progress
- [x] it remembers opened doors after leaving
- [x] the boss door needs the big key

## Deliberately not in H5
Puzzle pieces (H6), the real keep, its boss and the heart container (H7), room-scrolling animation, doors that
lock behind you, maps and compasses.
