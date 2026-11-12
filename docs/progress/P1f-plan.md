# P1f — UI polish (plan)

The sixth and last step of the pivot's visual overhaul (`docs/ROADMAP.md` P1): frames, a second larger letter
face for headings, and the title screen. Nothing about play changes: the same menus, the same choices, the same
keys.

## What changes
- **A heading face** (`tools/art/make_font.gd`): a second pixel font, twice the size of the first (16 pixels,
  capitals twelve tall), with thick stems, thin bars and small serifs. It has capitals, digits and a few marks;
  a small letter shows as its capital, so any heading can be set in it. Baked to `ui/font/hearth_heading.tres`
  and offered by the theme as the `Heading` kind of label.
  - Used for the game's name on the title screen and "The End" (at twice its size, where the small face was
    stretched four times), and for the heading of each box: Paused, Settings, Items, Quests.
- **Frames** (`PanelFrame`): every box keeps its look and gains a corner bracket in each corner in place of the
  square stud, an edge that is lighter along the top and left and darker along the bottom and right, and, under
  a heading, a rule with a small diamond in the middle.
- **The title screen**: a painted evening in place of the flat hills. A new tool, `tools/art/make_title.gd`,
  paints the picture (a dithered dusk sky, a moon, far hills, the old keep, the wood, and Hearthvale's roofs
  among cherry trees) and bakes it to `ui/title/backdrop.png`. The screen adds what moves: stars that twinkle,
  the keep's lit window (dark once the game is finished, as now), and petals on the wind. The ending screen
  shares the picture, as it shares the backdrop now.
- **A slimmer HUD corner** (carried over from 1a, where it covered the top corners of dungeon rooms): the box is
  as wide as its words, not a fixed 202 pixels, and the "Carrying" and "Item" lines show only when there is
  something to say.

## What does not change
- What the menus do, their options and their keys; the words on screen (but for the headings' face).
- The small face: it stays the face of everything that is read.
- Label sizes stay whole multiples of 8, so every letter stays in whole pixels.
- No external assets: both faces and the title's picture are painted in code.

## Done when
- [x] the heading face is baked by the tool, and every heading in the game can be set in it
- [x] the title, "The End" and the four box headings use it
- [x] every box wears the new frame, with a rule under its heading where it has one
- [x] the title screen shows the painted evening, and the keep's window still follows the save
- [x] the HUD's corner is as wide as its words and hides its empty lines
- [x] all earlier tests pass; new tests cover the face, the frame, the picture and the HUD's fit
- [x] every screen is compared before and after
- [ ] (yours) it looks right in play

## Not in this step
- New menus, new options, a clock or an energy bar on show (P2).
- Icons in the menus, mouse support, or a new layout for any box.
- Small letters for the heading face.
