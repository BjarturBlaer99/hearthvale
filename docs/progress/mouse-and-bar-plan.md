# Plan: the mouse in menus, and an item bar

The user's request, 2026-11-15, after playing the game:

> the mouse should be the select on the pause menu and main menu and bombs and lets add a items menu at the
> bottom of the screen where the player scrolls or uses 123456789 buttons to select the item they want to use

Three things were asked back, and answered:

| Asked | Answered |
|---|---|
| What should the mouse do for bombs? | Nothing new: bombs are picked in the bar like any item, and set down at his feet as before |
| Which menus should the mouse point at? | Every menu and list; the keys keep working |
| What does the bar hold? | What goes in hand: the sword, bow, bombs, hoe, watering can, seeds. Food stays in the Tab menu, which lists only food |

This changes a rule the user set on 2026-11-13 ("the mouse is two buttons, not a pointer"). It is now: **a
pointer in menus, two buttons in play.**

## Step A: the mouse points in menus

**What changes**
- In every menu and list the line under the pointer is highlighted as the mouse moves, and a click on a line
  chooses that line: the title, the pause menu and its pages (quests, settings), the food menu, Tilda's
  lists, the gifts, the answers in a conversation, the ending.
- A click that is on no line does what it did: it chooses the highlighted line, or reads on in a
  conversation. So the keys and a click anywhere still work together.
- The mouse wheel moves the highlight up and down, which is how a list longer than its box is scrolled with
  the mouse.
- At Tilda's, a click on "Buy" or "Sell" turns to that list.
- The rule is pure (`MenuPointer`: which line a point is on); each menu asks it about its own list.

**What does not change**
- The keys in every menu. What the two buttons do in play. No part of the world is pointed at: the hero
  still works the cell he faces.

**Done when**
- [x] Each menu has a test in which moving the pointer onto a line highlights it and a click chooses it
- [x] A click off the list still chooses the highlighted line, and a left click still reads a conversation on
- [x] The wheel moves the highlight in a long list
- [ ] *(yours)* choosing with the mouse feels natural in the pause menu and the title

## Step B: the item bar

**What changes**
- A bar at the bottom of the screen with a slot for each thing that can be in hand: his best sword first,
  then the bow, bombs, hoe, watering can and seeds in the order they were picked up. The slot in hand is lit,
  and it is what the left click uses. A slot shows how many it has left: arrows for the bow, bombs, seeds,
  pours in the can.
- **The mouse wheel steps through the slots** (round and round), and **the keys 1 to 9 choose a slot**. On a
  gamepad, the shoulder buttons step.
- With more than nine things the bar shows nine and moves with the choice.
- **The Tab menu lists only food.** The sword and the tools are no longer chosen there.
- When the last bomb or seed is used, its slot goes and the sword is in hand again: the item button never
  holds something he no longer has.
- The prompt and the message line move up to clear the bar; the keys in the top right name the wheel and the
  numbers; the first quest's journal says how to choose the hoe.
- The bar is hidden during a conversation and behind the lists.
- The order and the choice are pure (`HandBar`); the bar only draws them.

**What does not change**
- What a left click does with what is in hand (the sword away from the plot with a tool in hand, and so on),
  Space and Q, the save format, hearts, energy, timing.

**Done when**
- [x] The bar shows what he holds in the right order, with the slot in hand lit and the right counts
- [x] The wheel and each number key put the right thing in hand, and the left click then uses it
- [x] With ten things, the tenth can be reached and seen
- [x] The Tab menu lists food only, and eating from it works as before
- [x] The last bomb leaves the sword in hand, in a new game and in an old save
- [ ] *(yours)* choosing with the wheel and the numbers feels right in a fight and on the plot

## Not in this

- Clicking a slot of the bar with the pointer, or dragging things about in it.
- Food in the bar. Throwing or aiming bombs. Number keys in menus.
- Any new item, area or content.
