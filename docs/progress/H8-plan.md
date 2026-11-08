# H8 — The countryside (plan)

Goal (ROADMAP H8): fields and forest between Hearthvale and the keep, enemies, a secret or two, and a heart piece.

## Design
- **Two new areas** on the road north, replacing H7's stand-in road straight from the village into the keep:
  - The village's north road leads to the **North Fields**, which lead to the **Old Wood**, which ends at the keep's
    gate.
  - The keep's gate and its way out behind the boss both lead back to the Old Wood.
- **North Fields** (`north_fields`, 40x30): a winding road, a stream crossed by a bridge, a fenced farm plot, a
  plateau with a goblin archer (stairs up, ledges down), slimes, and a signpost.
  - **Secret 1:** a gap in the tree line beside the road leads down a narrow path to a hidden meadow, with a chest
    of bombs.
- **Old Wood** (`old_wood`, 40x30): dense trees, the road winding between clearings with slimes, bats and an
  archer, and the keep's stone front with its gate at the top.
  - **Secret 2:** an old shrine, walled in stone, beside the keep's forecourt. The heart piece is plain to see
    inside it, and one stretch of its wall is cracked: bomb it.
- **Heart pieces:**
  - `GameState.heart_pieces` (saved, 0–3) and `add_heart_piece()`: every fourth piece becomes a heart container.
  - `HeartPiece`: a quarter heart lying in the world. Touch it and it's gone for good (`taken_flag`).
  - The slice has one piece, so it shows "1 of 4".
- **Doors and chests outside dungeons** keep their flags under the area's id, so a cracked wall or a chest works
  outdoors. A cracked wall can take a lighter stone colour to match a ruin.

## Acceptance criteria (from ROADMAP)
- [x] you can walk from the village to the keep and back (tests walk every road both ways)
- [x] at least one optional secret (the hidden meadow and the shrine; neither is needed to reach the keep)

## Deliberately not in H8
Grass to cut, pots, more heart pieces, a world map, day and night, new enemy types, quests.
