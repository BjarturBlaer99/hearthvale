# H14 — The second dungeon & boss (plan)

Roadmap: a second dungeon of 10–14 rooms built around a new item, pits, a second boss whose weak point needs
the item, and the Iron Sword. No new region.

## Choices made here
- **The item is the Lantern**, not the boomerang. The bow already hits things at range, so a boomerang's puzzles
  would mostly repeat the keep's. Darkness and torches are new, and they need no change to how enemies work
  (a boomerang's stun would touch every enemy brain).
- **The dungeon is the Chapel Crypt**, entered through the chapel's door on Hearthvale's north rise. Bars hold
  the door shut until the Iron Warden is beaten. Guard Rolf says so, before and after.
- **The boss is the Crypt Shade.** Blows pass through it in the dark. Light all four braziers in its hall and
  the light binds it for a few seconds: only then can the sword hurt it. Then it snuffs the braziers and comes
  again; at half health it's faster and throws bolts.
- **The Iron Sword** lies in the crypt's Knight's Tomb, an optional room before the boss, so it's there for the
  fight.

## New mechanics
- **Pits** (`TerrainQuery`): a pit cell is a drop for walkers, so the hero can fall in and enemies keep out, and
  bats and arrows cross. Falling costs half a heart and puts the hero back on the last safe cell.
- **Blocks fill pits:** a push block pushed into a pit sinks and becomes floor. With a `block_id` it stays sunk
  for good (a flag), so a bridge built once is always there.
- **Darkness:** the crypt is dark. The screen shows only what lights reach: lit torches, and the hero (a dim
  glow, or the Lantern's wide one). `LightRules` (pure) works out the light; a `Darkness` overlay draws it.
- **Torches** (`Torch`): lit with E while the Lantern is carried. A torch sets a flag while it burns; some burn
  for good, some only for a few seconds, and braziers marked `always_lit` light the first rooms. Shutters wait on
  torch flags as they do on plates and crystals.
- **The Lantern** is a new item type, `lantern`. It's carried, not put on the item button (changed while
  building: see DECISIONS).

## The crypt: ten 15x11 rooms on a 3x4 grid
| Room | What it teaches or asks |
|---|---|
| Narthex (entrance) | Lit by braziers. Two unlit torches flank a barred door: come back with the Lantern |
| The Trench | Pits and blocks: push the block into the trench, cross, take the small key |
| Hall of the Dead | The hub: a locked door east, a torch door west, the boss door north |
| The Lantern's Tomb | The Lantern. A torch opens the way north |
| The Dark Path | The first truly dark room: a winding path between pits |
| The Knight's Tomb | Three torches that burn only briefly: light all three to open the Iron Sword's alcove |
| The Ossuary | A fight in the dark for the second small key |
| The Broken Floor | Dark, a trench and a block to find, and a locked door |
| The Reliquary | Archers across a pit, a crystal to shoot in the dark, the big key |
| The Shade's Hall | The boss, then a heart container |

Keys can't strand anyone: before the Lantern there's one small key and one locked door in reach.

## Done when (from the roadmap)
- [x] the dungeon can be finished start to end (a scene test plays it through)
- [x] its puzzles need the new item: torch doors stay shut without the Lantern
- [x] the boss can only be beaten with it: blows pass through until the braziers burn
- [x] pits work: half a heart, back at the edge; blocks fill them; enemies keep out
- [x] the Iron Sword does more than the wooden one

## Not in this milestone
Lantern fuel, fire arrows, burning things, a map or compass, new enemies besides the boss, the story (H15).
