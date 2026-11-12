# P1a — The frame (plan)

The first step of the pivot's visual overhaul (`docs/ROADMAP.md` P1, `docs/progress/pivot-plan.md`). It changes
how much of the world the screen shows and where everything on screen sits. It repaints nothing: the art is the
same until steps 1b to 1f.

## What changes
- **The picture is 640x360** (it was 480x270), on the same 16-pixel grid. Outdoors that shows 40 by 22 cells in
  place of 30 by 17. The window is 1920x1080 at the default 3x; the settings offer 2x, 3x and 4x.
- **Indoors and in dungeons the camera shows the room at twice the size** (decision 2), because rooms are small:
  a dungeon room is 15 by 11 cells and a house 11 by 9. `Ambience` already knows what kind of place an area is,
  so no scene has to say.
- **Every screen is laid out again** with anchors, so boxes sit in the middle or along an edge whatever the
  size: the HUD, the dialogue box, the item, pause, quest and settings menus, the title and the ending.
- **The HUD's corner** holds the hearts, then an **energy bar** (`EnergyBar`, new), then the three lines of
  text. The bar is hidden until P2; the corner's box fits whatever it holds.
- **Small things that assumed the old size:** the specks in the air cover the wider view; the title's houses
  and stars spread across the wider screen.

## What does not change
- No tile, sprite, map, collision, speed or timing. Positions in scenes are still in the same pixels.
- The save format.

## Done when
- [x] every area and screen fits the new frame, with nothing cut off or left at the old position
- [x] rooms and house interiors sit in the middle of the screen at twice the size, on whole pixels
- [x] the HUD's box grows when the energy bar is shown and shrinks when it is hidden
- [x] all earlier tests pass; new tests cover the camera's size indoors and out, the bar and the box
- [x] all 88 review shots retaken and compared with the old ones
- [ ] (yours) it looks right in play
