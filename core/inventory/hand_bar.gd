class_name HandBar
extends RefCounted
## What can be in the hero's hand, in the order of the bar at the bottom of the screen (the
## user's request, 2026-11-15), pure: his best sword first, then what he holds for the item
## button (the bow, bombs, the hoe, the watering can, seeds) in the order it was picked up. One
## of them is in hand: the sword when nothing is on the item button, else what is on it. The
## mouse wheel steps through them, round and round, and the keys 1 to 9 choose a slot. Works on
## item entries from data and on stacks in GameState.inventory's shape; GameState applies it
## and ItemBar draws it.
##
## **Columns** (step B1 of docs/progress/icons-axe-bar-plan.md, the user's Q13): the bar is a
## list of columns, each naming one thing (an item id, or SWORD for whichever sword is best) or
## nothing (EMPTY). A thing keeps its column: used up (the last bomb, the last seed of a kind),
## its column stays, empty, and remembers it, so it comes back there; a better tool takes the
## column of the tool of its kind he no longer carries; anything else new takes the first column
## that remembers nothing, else a new one at the end. The first sword takes the first column.
## Without arranging, that is the pack's order, as the bar always was. The wheel steps over
## empty columns, a number key on one does nothing, and empty columns at the end aren't drawn.

## How many slots show at once, each with a number key. With more things than that the bar
## moves along with the choice.
const SLOTS: int = 9
## The item type of a sword.
const SWORD_TYPE: String = "weapon_melee"
## No entry.
const NONE: int = -1
## A column's name for the sword (whichever is best), and for a column that remembers nothing.
const SWORD: String = "@sword"
const EMPTY: String = ""


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


## The name of the column `item` (an item entry) goes in: SWORD for any sword, else its id.
static func column_of(item: Dictionary) -> String:
	return SWORD if is_sword(item) else str(item.get("id", ""))


## The bar as it always was, for a pack with no bar saved (an old save): a column for each of
## entries(), in their order.
static func default_bar(stacks: Array, items: Array) -> Array[String]:
	var out: Array[String] = []
	for item: Dictionary in entries(stacks, items):
		out.append(column_of(item))
	return out


## `bar` (as saved, or as kept) made sound: a column naming SWORD, or a thing of `items` that
## goes in the hand (no sword by its id, no food, placeable or kit), once each; any other is
## EMPTY. The empty columns at the end are left off. Not a list at all: no columns.
static func cleaned(bar: Variant, items: Array) -> Array[String]:
	var out: Array[String] = []
	if typeof(bar) != TYPE_ARRAY:
		return out
	var by_id: Dictionary = _by_id(items)
	for column: Variant in (bar as Array):
		var name: String = str(column) if typeof(column) == TYPE_STRING or typeof(column) == TYPE_STRING_NAME else EMPTY
		var sound: bool = name == SWORD or Inventory.is_equippable(by_id.get(name, {}))
		out.append(name if sound and not out.has(name) else EMPTY)
	return _trimmed(out)


## `bar` with a column for everything for the hand he carries (`stacks`), by the rules above:
## the sword's at the front if there is none, a better tool in the column of a tool of its kind
## he no longer has, anything else in the first column that remembers nothing, else at the end.
## What has a column keeps it. `items` are the game's item entries.
static func settled(bar: Array, stacks: Array, items: Array) -> Array[String]:
	var out: Array[String] = cleaned(bar, items)
	var held: Array[Dictionary] = entries(stacks, items)
	var carried: Dictionary = {}
	for item: Dictionary in held:
		carried[column_of(item)] = true
	var by_id: Dictionary = _by_id(items)
	for item: Dictionary in held:
		var name: String = column_of(item)
		if out.has(name):
			continue
		if name == SWORD:
			out.insert(0, SWORD)
			continue
		var at: int = _column_for(out, item, carried, by_id)
		if at == NONE:
			out.append(name)
		else:
			out[at] = name
	return out


## Each column of `bar` as the bar shows it: the entry of `held` (entries()) it names, or {} for
## an empty column (one that remembers nothing, or a thing he no longer carries). The empty
## columns at the end are left off: they aren't drawn.
static func columns(bar: Array, held: Array) -> Array[Dictionary]:
	var by_name: Dictionary = {}
	for item: Variant in held:
		if typeof(item) == TYPE_DICTIONARY:
			by_name[column_of(item)] = item
	var out: Array[Dictionary] = []
	for column: Variant in bar:
		out.append(by_name.get(str(column), {}))
	while not out.is_empty() and (out.back() as Dictionary).is_empty():
		out.pop_back()
	return out


## `bar` with the thing in column `from` lifted and set down in column `to` (for the screen that
## arranges it, step B2): the two swap, or it moves into an empty column, past the end too.
## The empty columns at the end are left off. Out of range, or the same column: as it was.
static func moved(bar: Array, from: int, to: int) -> Array[String]:
	var out: Array[String] = []
	for column: Variant in bar:
		out.append(str(column))
	if from < 0 or to < 0 or from == to or from >= out.size():
		return _trimmed(out)
	while out.size() <= to:
		out.append(EMPTY)
	var lifted: String = out[from]
	out[from] = out[to]
	out[to] = lifted
	return _trimmed(out)


## Whether column `index` of `held` (columns()) holds nothing to take in hand.
static func is_empty_column(held: Array, index: int) -> bool:
	return index < 0 or index >= held.size() or (held[index] as Dictionary).is_empty()


## What is on the item button when entry `index` of `held` is in hand: its id, or "" for the
## sword (the item button is empty when the sword is in hand) and for no such entry (an empty
## column too: is_empty_column() tells them apart).
static func equipped_for(held: Array, index: int) -> StringName:
	if index < 0 or index >= held.size() or is_sword(held[index]):
		return &""
	return StringName(str((held[index] as Dictionary).get("id", "")))


## Which entry of `held` is in hand with `equipped` on the item button: that item's; with
## nothing on the button, the sword's. NONE if it isn't among them (no sword, or something
## he no longer has). An empty column is never in hand.
static func index_of(held: Array, equipped: StringName) -> int:
	for i: int in held.size():
		var item: Dictionary = held[i]
		if item.is_empty():
			continue
		if (equipped == &"" and is_sword(item)) or (equipped != &"" and str(item.get("id", "")) == String(equipped)):
			return i
	return NONE


## The entry `step` slots on from the one in hand, round and round, over the empty columns
## (each step is to the next column with something in it). With nothing in hand a step on takes
## the first and a step back the last. NONE if there is nothing to hold.
static func stepped(held: Array, equipped: StringName, step: int) -> int:
	var filled: Array[int] = []
	for i: int in held.size():
		if not is_empty_column(held, i):
			filled.append(i)
	if filled.is_empty():
		return NONE
	var at: int = filled.find(index_of(held, equipped))
	if at == -1:
		return filled[0] if step >= 0 else filled[filled.size() - 1]
	return filled[wrapi(at + step, 0, filled.size())]


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


## The column a new thing (`item`, not yet on `bar`) takes, or NONE for a new one at the end:
## a tool takes the first column naming a tool of its kind that isn't `carried`; else the first
## column that remembers nothing.
static func _column_for(bar: Array[String], item: Dictionary, carried: Dictionary, by_id: Dictionary) -> int:
	var kind: String = _tool_kind(item)
	if not kind.is_empty():
		for i: int in bar.size():
			if bar[i] != EMPTY and not carried.has(bar[i]) and _tool_kind(by_id.get(bar[i], {})) == kind:
				return i
	return bar.find(EMPTY)


## A tool's kind (its stats' "tool": hoe, water, pick, chop), or "" for what isn't a tool.
static func _tool_kind(item: Dictionary) -> String:
	if str(item.get("type", "")) != "tool":
		return ""
	var stats: Variant = item.get("stats", {})
	return str((stats as Dictionary).get("tool", "")) if typeof(stats) == TYPE_DICTIONARY else ""


static func _by_id(items: Array) -> Dictionary:
	var by_id: Dictionary = {}
	for item: Variant in items:
		if typeof(item) == TYPE_DICTIONARY:
			by_id[str((item as Dictionary).get("id", ""))] = item
	return by_id


static func _trimmed(bar: Array[String]) -> Array[String]:
	while not bar.is_empty() and bar.back() == EMPTY:
		bar.pop_back()
	return bar
