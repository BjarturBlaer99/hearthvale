# H15 — New-player playtest guide

The roadmap's last test: **a new player finishes the game in about two hours with no developer help.** This page
is how to run that test and what to bring back from it.

## Before
- Find one to three people who have never seen the game. One at a time is best.
- Run the playtest version of the game. It opens the title screen on a save slot of its own, so your own game is
  untouched and the title offers only **New game** until this playtest has saved:

```bash
godot --path . -s res://tools/playtest.gd -- full
```

- The slot is kept between runs, so a session can stop and carry on with **Continue**. For the next person, add
  `fresh` to start with no save:

```bash
godot --path . -s res://tools/playtest.gd -- full fresh
```

- It keeps a log of what happens, each line with the time since the run began and the game's own clock: areas
  entered, items first held, flags (bosses, keys, doors, chests), quests and falls. The logs are in
  `%APPDATA%\Godot\app_userdata\Hearthvale\playtests`. Most of the checkpoint times below can be read from it.

- Have a clock and something to write on.

## During
- Say only: "Play it as you would any game. Think out loud if you can." Then say nothing.
- **Don't help.** If they're stuck for five minutes, write down where and why, and only then give the smallest
  hint that gets them moving. Every hint is a finding.
- The log has the time of most checkpoints below. Write down the ones it can't see (talking to someone, standing
  stuck), and anything they say out loud that sounds like
  confusion ("where do I...", "what does this...", "why can't I...").

## Checkpoints
| # | Checkpoint | Time | Hints given | Notes |
|---|---|---|---|---|
| 1 | Talks to Elder Bram | | | |
| 2 | Has the Wooden Sword | | | |
| 3 | Leaves the village by the north road | | | |
| 4 | Reaches the Old Keep's gate | | | |
| 5 | Has the Bow | | | |
| 6 | Beats the Iron Warden | | | |
| 7 | Hears the old tale from Elder Bram | | | |
| 8 | Enters the crypt | | | |
| 9 | Bridges the Trench | | | |
| 10 | Has the Lantern | | | |
| 11 | Has the Iron Sword (optional) | | | |
| 12 | Has the crypt's big key | | | |
| 13 | Beats the Crypt Shade | | | |
| 14 | Sees the ending screen (its time is the total) | | | |

## Where I expect trouble
These are guesses from building it, not findings. Watch them closely.
1. **Finding the sword.** It lies in the training yard, off the first road they'll walk. Bram says where; a
   player who skips Bram may leave without it.
2. **The Warden's eye.** Blows clink until an arrow finds the open eye. The tell is there, but nobody says it.
3. **Going to the chapel after the keep.** The keep's closing words point to Elder Bram, and he to the chapel.
4. **The Trench.** Pushing a block into a pit is new. An inscription hints at it.
5. **The Broken Floor.** The block is in a far corner, in the dark.
6. **The Reliquary.** The crystal shows only from the pit's edge, by lantern light, while archers shoot.
   Its door is locked, and the key is back in the Ossuary, west of the first hall. Run 1 (2026-11-11) got stuck
   here, so a stone by the door now says where the key is. Watch whether a new player reads it.
7. **The three brief torches** (the Iron Sword). 6.5 seconds may be too tight, or too easy.
8. **The Crypt Shade.** Do they read the Narthex inscription? Do they see that lit braziers bind it? Is relighting
   four braziers each round fun or a chore?
9. **Pits in the dark.** Fair, or cheap?
10. **Length.** My guess is that a first run takes 45 to 75 minutes, well under the roadmap's two hours. The
    ending screen gives the real number.

## After
Ask, and write down the answers:
1. What were you trying to do most of the time? Was it ever unclear?
2. Where did you feel stuck, and what got you out?
3. What did you enjoy most? What felt like a chore?
4. Was any fight unfair? Any puzzle unfair?
5. Did you follow the story? Who was Aldric, and what was the Warden for?
6. Would you have kept playing?

## Bringing it back
Tell me what happened in whatever form you have it: the table, notes, or just what you remember. I'll turn it
into fixes and record both in `docs/progress/LOG.md`.

## Trying parts by hand
To look at one part without playing up to it:

```bash
godot --path . -s res://tools/playtest.gd -- warden
```

```bash
godot --path . -s res://tools/playtest.gd -- crypt
```

```bash
godot --path . -s res://tools/playtest.gd -- shade
```

```bash
godot --path . -s res://tools/playtest.gd -- ending
```
