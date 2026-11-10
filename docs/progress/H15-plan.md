# H15 — Story, ending & playtest (plan)

Roadmap: a light story that ties the two dungeons together, told through villagers and signs; a real ending
after the second boss; and fixes from a full playtest with new players.

## The story (short, and all in data)
Long ago a knight, **Sir Aldric**, drove a Shade into the crypt under Hearthvale's chapel and bound it there with
light. He set the **Iron Warden** in the keep to keep watch: if the dark below ever stirred, the Warden would wake
and drop the bars on the crypt.

Now the Shade has stirred. The Warden woke (the lights over the keep) and the bars dropped. But the Warden is old
and blind with rust, and strikes at anyone. Elder Bram knows only that something has stirred in the keep, and
sends the hero to quiet it. Beating the Warden lifts the bars: the hero has broken the lock, and has to finish
what Aldric began, with a light and with Aldric's own sword.

**Where it's told**
| Where | What it says |
|---|---|
| Elder Bram, before the keep | (as now) lights over the keep; take the sword; the road north |
| A plaque in the keep's entrance | The Warden wakes when the dark under the chapel stirs, and bars the crypt |
| The keep's closing words | Bars grind upward under the chapel. Tell Elder Bram |
| Elder Bram, after the keep | The old tale: Aldric, the Shade, the Warden as its lock. Carry a light |
| A plaque by the chapel door | Here Aldric bound the Shade with light |
| An inscription in the crypt's Narthex | Four flames hold it; no blade bites it in the dark (the boss's hint) |
| An inscription in the Trench | The floor fell in; a good stone will mend it (the block's hint) |
| Aldric's epitaph in the Knight's Tomb | His sword for the hand that finishes it; light the three before the first dies |
| The crypt's closing words | What Aldric bound, you have ended |
| Elder Bram and Guard Rolf, after | Thanks, and a quiet watch |

## The ending
- The crypt's closing conversation ends by setting the flag `game_finished` (an ordinary `set_flag` effect).
- When that conversation closes, the area goes to a new **ending screen**: "The End", the time played, hearts,
  and quests finished, then two choices: keep exploring (back where the hero stood) or save and go to the title.
- `EndingSummary` (pure, tested) builds the lines. No new effect type, and the flag is saved, so the ending
  plays once.

## The playtest
I can't run it: it needs people who haven't seen the game. This milestone gets everything ready for it:
- `docs/progress/H15-playtest.md`: how to run it, what to watch for, where I expect people to get stuck, and
  what to write down.
- A playtest scenario, `ending`, to try the ending without playing up to it.
- What the playtest turns up gets fixed afterwards, and noted in the LOG.

## Done when
- [x] the story is told in the places above, each from data, each shown only at its point in the game
- [x] the ending screen follows the crypt's closing words, once, with the right time, hearts and quests
- [x] keep exploring returns the hero to where they stood; save and quit saves
- [x] all tests pass, and the new screens and signs are checked in screenshots
- [ ] (yours) a new player finishes the game without help, in about two hours

## Not in this milestone
Cutscenes, credits music, new quests, more villagers, new areas. No fixes for problems nobody has hit yet.
