# H9 — Save, menus & playtest (plan)

Goal (ROADMAP H9): a title screen, save/load from a menu, pause and settings, and fixes from playtesting, so that
a new player can finish the slice in 30–60 minutes with no developer help.

## Design
- **Title screen** (`ui/title_screen.tscn`, the new main scene):
  - The name over a painted backdrop: hills and the keep on the skyline.
  - The menu: **Continue** (shown when there's a save, with where and how long), **New game**, **Settings**,
    **Quit**.
- **Menus** share one pure cursor (`MenuCursor`): up and down move, skipping options that can't be chosen, and
  E / Enter / A picks. Esc (or Start) backs out.
- **Pause** (new action `pause`: Esc / P, gamepad Start):
  - The area pauses the game tree and opens the pause menu: **Resume**, **Save**, **Settings**, **Quit to
    title**.
  - It also shows your hearts, heart pieces (n of 4), small keys in a dungeon, and the play time.
- **Saving:**
  - One save slot for the slice (`SaveSystem.slot`; tests use their own). It saves where you stand, and Continue
    puts you back there.
  - Quitting to the title loses progress since the last save, and the menu says so.
- **Play time:** `GameState.play_time` (saved) counts while the game runs unpaused. Playtesters can read it in the
  pause menu, which is how we'll check the 30–60 minutes.
- **Settings** (`Settings` autoload over a pure `SettingsData`, saved to `user://settings.cfg`, not the save
  slot):
  - fullscreen
  - window size (2x, 3x, 4x)
  - showing the controls hint

  There's no volume setting, because there's no audio yet.
- **The end:** taking the Warden's heart container opens a short closing conversation from data (the end of the
  slice, thanks for playing, keep exploring).
- **Fixes from playtesting and the logs:**
  - Arrows and bats stop at closed doors (H7's known issue). Closed doors seal their cells for everything.
  - Elder Bram points new players to the sword and the road north.
  - The controls hint mentions the pause menu.

## Acceptance criteria (from ROADMAP)
- [x] a new player finishes the slice in 30–60 minutes with no developer help: the new-player playtest went well
  (2026-11-08). Everything it relies on is built and tested:
  - the title screen
  - new game, save and continue
  - pause
  - settings that persist
  - the end
  - timing

## Deliberately not in H9
Several save slots, key rebinding, audio and volume, a map, real art.
