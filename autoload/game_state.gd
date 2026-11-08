extends Node
## Owns every piece of state that must survive a save (docs/TECH_DESIGN.md §2, §9).
##
## Scene nodes never hide game state: they read it here and change it through these
## methods, which emit the matching EventBus signal. `to_dict()` / `from_dict()` use the
## save format from TECH_DESIGN §9; SaveSystem handles files and version migration.

const SAVE_VERSION: int = 1
const HALVES_PER_HEART: int = 2
const START_HEARTS: int = 3
const MAX_HEARTS: int = 20

## Heart containers the hero has (0 until a game starts).
var hearts_max: int = 0
## Health in half hearts, 0..max_health().
var health: int = 0
## flag -> value. A missing flag reads as false.
var flags: Dictionary[StringName, Variant] = {}
## quest id -> current stage id
var quests: Dictionary[StringName, StringName] = {}
## Stacks of { "id": StringName, "count": int }, in pickup order. Capped by Inventory rules.
var inventory: Array[Dictionary] = []
## The item on the item button (bow, bombs), or empty.
var equipped: StringName = &""
## Where the hero is: { "area", "cell": [x, y] }, or { "area", "entry" } on the way into an
## area through one of its entry points (go_to), until the area places them.
var player: Dictionary = {}


## Starts a fresh game: full health with the starting hearts, nothing else.
func new_game() -> void:
	clear()
	hearts_max = START_HEARTS
	health = max_health()


func is_started() -> bool:
	return hearts_max > 0


# --- Health ----------------------------------------------------------------

func max_health() -> int:
	return hearts_max * HALVES_PER_HEART


func damage(halves: int) -> void:
	set_health(health - maxi(halves, 0))


func heal(halves: int) -> void:
	set_health(health + maxi(halves, 0))


## A heart container: one more heart, and health refills (as in classic Zeldas).
func add_heart_container() -> void:
	hearts_max = mini(hearts_max + 1, MAX_HEARTS)
	health = max_health()
	EventBus.health_changed.emit(health, max_health())


func set_health(value: int) -> void:
	var clamped: int = clampi(value, 0, max_health())
	if clamped == health:
		return
	health = clamped
	EventBus.health_changed.emit(health, max_health())


func is_dead() -> bool:
	return is_started() and health <= 0


# --- Flags -----------------------------------------------------------------

func set_flag(flag: StringName, value: Variant) -> void:
	if flags.has(flag) and flags[flag] == value:
		return
	flags[flag] = value
	EventBus.flag_set.emit(flag, value)


func get_flag(flag: StringName, default: Variant = false) -> Variant:
	return flags.get(flag, default)


# --- Player ----------------------------------------------------------------

## Records which area the hero is in and where. The area calls this every frame.
func update_player(area_id: StringName, cell: Vector2i) -> void:
	player = {"area": String(area_id), "cell": [cell.x, cell.y]}


## Sends the hero to the entry point `entry` of `area_id` (a door, a doormat); the area
## places them there when it loads. The caller changes the scene.
func go_to(area_id: StringName, entry: StringName) -> void:
	player = {"area": String(area_id), "entry": String(entry)}


# --- Quests ----------------------------------------------------------------

func set_quest_stage(quest_id: StringName, stage_id: StringName) -> void:
	if quests.get(quest_id, &"") == stage_id:
		return
	quests[quest_id] = stage_id
	EventBus.quest_updated.emit(quest_id)


func get_quest_stage(quest_id: StringName) -> StringName:
	return quests.get(quest_id, &"")


# --- Inventory -------------------------------------------------------------

## Adds `count` of an item, as many as fit (Inventory.capacity, from the item's data); a
## negative count removes, never going below zero. The first item for the item button that
## comes in is equipped. Returns how many were actually added (negative when removing).
func add_item(item_id: StringName, count: int = 1) -> int:
	var item: Dictionary = DataRegistry.get_item(item_id)
	if count > 0:
		count = mini(count, Inventory.room_for(item_count(item_id), item))
	if count == 0:
		return 0
	if count > 0 and equipped == &"" and Inventory.is_equippable(item):
		equip(item_id)
	var index: int = _find_stack(item_id)
	if index == -1:
		if count < 0:
			return 0
		inventory.append({"id": item_id, "count": count})
		EventBus.item_added.emit(item_id, count)
		return count
	var held: int = inventory[index]["count"]
	var applied: int = maxi(count, -held)
	if held + applied == 0:
		inventory.remove_at(index)
	else:
		inventory[index]["count"] = held + applied
	EventBus.item_added.emit(item_id, applied)
	return applied


## Puts `item_id` on the item button (empty to clear it).
func equip(item_id: StringName) -> void:
	if equipped == item_id:
		return
	equipped = item_id
	EventBus.equipped_changed.emit(item_id)


func item_count(item_id: StringName) -> int:
	var index: int = _find_stack(item_id)
	return 0 if index == -1 else int(inventory[index]["count"])


func _find_stack(item_id: StringName) -> int:
	for i: int in inventory.size():
		if inventory[i]["id"] == item_id:
			return i
	return -1


# --- Serialization ---------------------------------------------------------

## Empties all state. Does not emit signals: callers reload whatever reads it.
func clear() -> void:
	hearts_max = 0
	health = 0
	flags.clear()
	quests.clear()
	inventory.clear()
	equipped = &""
	player.clear()


## The whole state as JSON-safe data (String keys, no StringNames).
func to_dict() -> Dictionary:
	var stacks: Array = []
	for stack: Dictionary in inventory:
		stacks.append({"id": String(stack["id"]), "count": int(stack["count"])})
	return {
		"version": SAVE_VERSION,
		"hearts_max": hearts_max,
		"health": health,
		"flags": _json_safe(flags),
		"quests": _json_safe(quests),
		"inventory": stacks,
		"equipped": String(equipped),
		"player": _json_safe(player),
	}


## Replaces all state with `data`, which must already be at SAVE_VERSION.
## Does not emit signals: the caller reloads the world after loading.
func from_dict(data: Dictionary) -> void:
	clear()
	hearts_max = clampi(int(data.get("hearts_max", 0)), 0, MAX_HEARTS)
	health = clampi(int(data.get("health", 0)), 0, max_health())
	var src_flags: Dictionary = data.get("flags", {})
	for key: Variant in src_flags:
		flags[StringName(str(key))] = src_flags[key]
	var src_quests: Dictionary = data.get("quests", {})
	for key: Variant in src_quests:
		quests[StringName(str(key))] = StringName(str(src_quests[key]))
	var src_inventory: Array = data.get("inventory", [])
	for stack: Variant in src_inventory:
		var entry: Dictionary = stack
		inventory.append({"id": StringName(str(entry["id"])), "count": int(entry["count"])})
	equipped = StringName(str(data.get("equipped", "")))
	player = _whole_numbers_as_int(data.get("player", {}))


## JSON may return 12 as 12.0. Cells and counts are ints, so turn whole floats back into
## ints, recursively, leaving real fractions alone.
func _whole_numbers_as_int(value: Variant) -> Variant:
	match typeof(value):
		TYPE_FLOAT:
			var number: float = value
			return int(number) if number == roundf(number) else number
		TYPE_DICTIONARY:
			var source: Dictionary = value
			var out: Dictionary = {}
			for key: Variant in source:
				out[key] = _whole_numbers_as_int(source[key])
			return out
		TYPE_ARRAY:
			var out_array: Array = []
			for element: Variant in (value as Array):
				out_array.append(_whole_numbers_as_int(element))
			return out_array
	return value


## Recursively turns StringName keys and values into String so JSON keeps them stable.
func _json_safe(value: Variant) -> Variant:
	match typeof(value):
		TYPE_STRING_NAME:
			return String(value)
		TYPE_DICTIONARY:
			var source: Dictionary = value
			var out: Dictionary = {}
			for key: Variant in source:
				var safe_key: Variant = String(key) if typeof(key) == TYPE_STRING_NAME else key
				out[safe_key] = _json_safe(source[key])
			return out
		TYPE_ARRAY:
			var out_array: Array = []
			for element: Variant in (value as Array):
				out_array.append(_json_safe(element))
			return out_array
	return value
