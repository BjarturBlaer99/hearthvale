class_name HandBar
extends RefCounted
## What can be in the hero's hand, in the order of the bar at the bottom of the screen (the
## user's request, 2026-11-15), pure: his best sword first, then what he holds for the item
## button (the bow, bombs, the hoe, the watering can, seeds) in the order it was picked up. One
## of them is in hand: the sword when nothing is on the item button, else what is on it. The
## mouse wheel steps through them, round and round, and the keys 1 to 9 choose a slot. Works on
## item entries from data and on stacks in GameState.inventory's shape; GameState applies it
## and ItemBar draws it.

## How many slots show at once, each with a number key. With more things than that the bar
## moves along with the choice.
const SLOTS: int = 9
## The item type of a sword.
const SWORD_TYPE: String = "weapon_melee"
## No entry.
const NONE: int = -1


## The bar's entries (item data entries): the best sword among `stacks`, then the things for
## the item button in the order they were picked up. `items` are the game's item entries.
static func entries(stacks: Array, items: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var sword: Dictionary = CombatRules.best_melee_weapon(stacks, items)
	if not sword.is_empty():
		out.append(sword)
	out.append_array(Inventory.equippable_held(stacks, items))
	return out


static func is_sword(item: Dictionary) -> bool:
	return str(item.get("type", "")) == SWORD_TYPE


## What is on the item button when entry `index` of `held` is in hand: its id, or "" for the
## sword (the item button is empty when the sword is in hand) and for no such entry.
static func equipped_for(held: Array, index: int) -> StringName:
	if index < 0 or index >= held.size() or is_sword(held[index]):
		return &""
	return StringName(str((held[index] as Dictionary).get("id", "")))


## Which entry of `held` is in hand with `equipped` on the item button: that item's; with
## nothing on the button, the sword's. NONE if it isn't among them (no sword, or something
## he no longer has).
static func index_of(held: Array, equipped: StringName) -> int:
	for i: int in held.size():
		var item: Dictionary = held[i]
		if (equipped == &"" and is_sword(item)) or (equipped != &"" and str(item.get("id", "")) == String(equipped)):
			return i
	return NONE


## The entry `step` slots on from the one in hand, round and round. With nothing in hand a
## step on takes the first and a step back the last. NONE if there is nothing to hold.
static func stepped(held: Array, equipped: StringName, step: int) -> int:
	if held.is_empty():
		return NONE
	var at: int = index_of(held, equipped)
	if at == NONE:
		return 0 if step >= 0 else held.size() - 1
	return wrapi(at + step, 0, held.size())


## The first entry the bar shows of `count`, so that the one in hand (`in_hand`) is in view:
## `first` (where the bar stood) moved only as far as it must be.
static func first_shown(first: int, in_hand: int, count: int) -> int:
	return MenuCursor.window_top(first, maxi(in_hand, 0), count, SLOTS)


## What a slot's number says: how many `item` has left to use (arrows for the bow, the bombs
## or seeds themselves, pours in the can), or "" for what uses nothing up. `count_of` gives
## how many of an item id the hero carries.
static func count_text(item: Dictionary, count_of: Callable) -> String:
	var ammo: String = Inventory.ammo_for(item)
	return "" if ammo.is_empty() else str(int(count_of.call(StringName(ammo))))
