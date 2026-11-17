class_name Store
extends RefCounted
## The storage chest in the hero's home (crafting, 2026-11-17, docs/TECH_DESIGN.md §28), pure:
## so many slots, each a stack of one thing up to that thing's own limit. Unlike the pack it may
## hold several stacks of the same thing: its use is keeping more ore, bars and crops than one
## stack. It takes what stacks (food, ingredients, materials, seeds, bombs, arrows) and leaves
## coins, keys and quest things with the hero. GameState holds one, moves stacks between it
## and the pack, and saves it.

## Item types that stay with the hero.
const KEPT_OUT: Array[String] = ["currency", "key", "quest"]
## Why a stack can't be moved.
const FULL_WORDS: String = "The chest is full."
const NOT_KEPT_WORDS: String = "That stays with you."
const NO_ROOM_WORDS: String = "You have no room to carry more of that."
const NOTHING_WORDS: String = "There is nothing there."

## How many stacks it holds at most.
var slots: int = 24

## [{ "id": String, "count": int }], in the order they were put in.
var _stacks: Array[Dictionary] = []


func _init(slot_count: int = 24) -> void:
	slots = maxi(slot_count, 1)


## Whether `item` (a data entry) is something the chest keeps: it stacks, and isn't coins, a
## key or a quest's thing.
static func can_hold(item: Dictionary) -> bool:
	return bool(item.get("stackable", false)) and not KEPT_OUT.has(str(item.get("type", "")))


## Its stacks, in order: [{ "id", "count" }] (copies).
func stacks() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for stack: Dictionary in _stacks:
		out.append(stack.duplicate())
	return out


func used_slots() -> int:
	return _stacks.size()


func free_slots() -> int:
	return maxi(slots - _stacks.size(), 0)


## How many of `item_id` it holds in all.
func count_of(item_id: String) -> int:
	var total: int = 0
	for stack: Dictionary in _stacks:
		if str(stack["id"]) == item_id:
			total += int(stack["count"])
	return total


## How many more of `item_id` would go in, a stack of it holding `capacity`: what its own
## stacks have room for, and a full stack for every free slot.
func room_for(item_id: String, capacity: int) -> int:
	var limit: int = maxi(capacity, 1)
	var room: int = free_slots() * limit
	for stack: Dictionary in _stacks:
		if str(stack["id"]) == item_id:
			room += maxi(limit - int(stack["count"]), 0)
	return room


## Puts in `count` of `item_id` (a stack of it holds `capacity`): its own stacks are topped up
## first, then new ones begun. Returns how many went in: fewer than asked if it filled up.
func put(item_id: String, count: int, capacity: int) -> int:
	var limit: int = maxi(capacity, 1)
	var left: int = maxi(count, 0)
	for stack: Dictionary in _stacks:
		if left <= 0:
			break
		if str(stack["id"]) == item_id:
			var added: int = mini(left, maxi(limit - int(stack["count"]), 0))
			stack["count"] = int(stack["count"]) + added
			left -= added
	while left > 0 and _stacks.size() < slots:
		var added: int = mini(left, limit)
		_stacks.append({"id": item_id, "count": added})
		left -= added
	return maxi(count, 0) - left


## Takes up to `count` out of stack `index`. Returns how many came out; a stack emptied is
## gone, and the ones after it move up.
func take(index: int, count: int) -> int:
	if index < 0 or index >= _stacks.size() or count <= 0:
		return 0
	var taken: int = mini(count, int(_stacks[index]["count"]))
	_stacks[index]["count"] = int(_stacks[index]["count"]) - taken
	if int(_stacks[index]["count"]) <= 0:
		_stacks.remove_at(index)
	return taken


## JSON-safe: [{ "id", "count" }].
func to_list() -> Array:
	var out: Array = []
	for stack: Dictionary in _stacks:
		out.append({"id": str(stack["id"]), "count": int(stack["count"])})
	return out


## Takes what a save holds: stacks in order, as many as there are slots. Anything that isn't a
## stack is left out. `capacity_of` (optional) gives the most a stack of an item id may hold:
## one bigger than that is cut down to it.
func load_saved(saved: Variant, capacity_of: Callable = Callable()) -> void:
	_stacks.clear()
	if typeof(saved) != TYPE_ARRAY:
		return
	for entry: Variant in saved:
		if _stacks.size() >= slots:
			break
		if typeof(entry) != TYPE_DICTIONARY or typeof((entry as Dictionary).get("id")) != TYPE_STRING or str(entry["id"]).is_empty():
			continue
		var count: Variant = (entry as Dictionary).get("count")
		if (typeof(count) != TYPE_INT and typeof(count) != TYPE_FLOAT) or int(count) < 1:
			continue
		var most: int = int(capacity_of.call(str(entry["id"]))) if capacity_of.is_valid() else int(count)
		_stacks.append({"id": str(entry["id"]), "count": mini(int(count), maxi(most, 1))})
