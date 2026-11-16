# Plan: a fix round (no new content)

The user's request, 2026-11-16, after the whole game was played: five fixes, in order, each with tests.
Four were found in the bug hunt of 2026-11-15 and left for the user to decide; "quitting does not save" was
seen in the playthrough's log.

> Old saves must still load. Touch nothing else. When done, all tests pass, commit, and list each fix with
> how you verified it.

The save format does not change: no new version.

## 1. Safe saving

- A save is written to a temporary file, read back to see that it is whole, and only then put in the save's
  place. The save that was there is kept beside it as a backup (`slot_1.backup.json`).
- A save that can't be written leaves the old save as it was, and says why.
- `SaveSystem.erase_slot()` removes a slot's three files; the tests and the playtest tool use it.

**Done when**
- [x] A save that fails partway leaves the save before it readable
- [x] After two saves the backup holds the first
- [x] A save written by the game as it was (no backup beside it) loads as before

## 2. Save on quit

- "Quit to title" in the pause menu saves first; so does closing the window, in an area or on the ending
  screen. "Saving..." shows for half a second before the game leaves.
- If the save can't be written he is told and the game stays; asked again, it leaves without saving.
- A window closed in the moment he lies fallen saves him awake at the entrance, as he would have been.
- The title screen, the tests and the screenshot tool never save the player's own game this way: the title
  has nothing to save, a test's area is not the game's scene, and the screenshot tool uses a slot of its own.

**Done when**
- [x] Quitting to the title writes the save, shows the notice, then leaves
- [x] A close request in an area and on the ending screen does the same, then quits
- [x] A save that fails keeps him in the game the first time and lets him go the second

## 3. A save that can't be read

- Continue can be chosen when there is a save or a backup. If the save can't be read (or is gone) the title
  says so and offers the backup, with where and how long it was. If the backup can't be read either, or
  there is none, it says so and the title stays.

**Done when**
- [x] A broken save with a good backup: the message, the offer, and the backup loads
- [x] A broken save with a broken backup, and one with none: the message, and the title stays
- [x] A good save loads as before, with nothing said

## 4. A reward too big for the pack

- What is given by a quest or in a conversation (the `give_item` effect) goes in the pack as far as it fits.
  The rest is laid at the hero's feet and a line at the top of the screen says so ("Pack full. At your feet:
  Arrows x6."). It lies there until it is
  picked up, through leaving the area and through a save (kept in the flags, so the save format is as it was).
- It is picked up like any item on the ground: whole, when there is room.

**Done when**
- [x] A reward that doesn't fit: the pack is full, the rest is at his feet, and he is told
- [x] What lies there is still there after the area is left and after a save and a load
- [x] With room made, it can be picked up, and then it is gone for good

## 5. A gift to a full friendship

- At five marks a gift is still taken, and the villager says a line of their own for it: `thanks.full` in
  their file in `data/villagers/`. Seven short lines are the only new words.

**Done when**
- [x] At five marks the gift is taken and their own line is said; below five, the lines are as they were
- [x] A villager's file without the line is refused when the data is checked

## Not in this

- Any new item, area, quest or system. More than one save slot. Choosing where a save is kept.
- Taking part of what lies on the ground. Dropping things from the pack by choice.
