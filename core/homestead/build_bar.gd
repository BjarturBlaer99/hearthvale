class_name BuildBar
extends RefCounted
## What can be set down, in the order of the build bar (the Homestead, phase 2; docs/TECH_DESIGN.md
## §30), pure: every placeable the hero carries, in the order he came by them, each with how many
## he has. In build mode this bar takes the item bar's place: the wheel steps along it, round
## and round, and the keys 1 to 9 choose a slot. One entry is chosen (or none, with nothing to
## set down): it is what a left click sets down. Works on item entries from data and on stacks
## in GameState.inventory's shape; BuildMode keeps the choice and BuildBarView draws it.
## Nothing here is ever on the item bar: placeables are no Inventory.EQUIPPABLE_TYPES.

## How many slots show at once, each with a number key.
const SLOTS: int = HandBar.SLOTS
## No entry.
const NONE: int = -1


## The bar's entries (item data entries): the placeables among `stacks`, in the stacks' order.
## `items` are the game's item entries.
static func entries(stacks: Array, items: Array) -> Array[Dictionary]:
	return Inventory.held_of_type(stacks, items, Placement.TYPE)


## Which entry of `held` is `chosen` (an item id), or NONE if it isn't among them.
static func index_of(held: Array, chosen: StringName) -> int:
	for i: int in held.size():
		if str((held[i] as Dictionary).get("id", "")) == String(chosen):
			return i
	return NONE


## The id of entry `index` of `held`, or &"" if there is none.
static func id_at(held: Array, index: int) -> StringName:
	return StringName(str((held[index] as Dictionary).get("id", ""))) if index >= 0 and index < held.size() else &""


## What is chosen once `held` is what he carries: `chosen` while he still has some, else the
## first thing on the bar (&"" with nothing on it). The last of a thing set down doesn't leave
## the bar pointing at nothing.
static func kept(held: Array, chosen: StringName) -> StringName:
	return chosen if index_of(held, chosen) != NONE else id_at(held, 0)


## The id of the entry `step` slots on from `chosen`, round and round. With nothing chosen a
## step on takes the first and a step back the last. &"" if there is nothing on the bar.
static func stepped(held: Array, chosen: StringName, step: int) -> StringName:
	if held.is_empty():
		return &""
	var at: int = index_of(held, chosen)
	if at == NONE:
		return id_at(held, 0 if step >= 0 else held.size() - 1)
	return id_at(held, wrapi(at + step, 0, held.size()))


## The first entry the bar shows of `count`, so that the chosen one (`chosen_index`) is in
## view: `first` (where the bar stood) moved only as far as it must be.
static func first_shown(first: int, chosen_index: int, count: int) -> int:
	return MenuCursor.window_top(first, maxi(chosen_index, 0), count, SLOTS)


## What a slot's number says: how many of `entry` he carries. `count_of` gives how many of an
## item id the hero carries.
static func count_text(entry: Dictionary, count_of: Callable) -> String:
	return str(int(count_of.call(StringName(str(entry.get("id", ""))))))
