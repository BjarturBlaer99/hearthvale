extends Node
## Owns every piece of state that must survive a save (docs/TECH_DESIGN.md §2, §9).
##
## Scene nodes never hide game state: they read it here and change it through these
## methods, which emit the matching EventBus signal. `to_dict()` / `from_dict()` use the
## save format from TECH_DESIGN §9; SaveSystem handles files and version migration.

const SAVE_VERSION: int = 1
const REPUTATION_MIN: int = -100
const REPUTATION_MAX: int = 100

## district id -> current level id
var water: Dictionary[StringName, StringName] = {}
## district id -> water units received toward its next level (see WaterNetwork)
var water_pending: Dictionary[StringName, int] = {}
## basin id -> stored water units
var basins: Dictionary[StringName, int] = {}
## flood network node id -> &"broken" or &"repaired"
var network_nodes: Dictionary[StringName, StringName] = {}
## flag -> value. A missing flag reads as false.
var flags: Dictionary[StringName, Variant] = {}
## quest id -> current stage id
var quests: Dictionary[StringName, StringName] = {}
## faction id -> reputation, clamped to REPUTATION_MIN..REPUTATION_MAX
var reputation: Dictionary[StringName, int] = {}
## Stacks of { "id": StringName, "count": int }, in pickup order.
var inventory: Array[Dictionary] = []
## Where the player is: { "district", "cell": [x, y], "height" }.
var player: Dictionary = {}
## Boat upgrades and position (filled in from M3).
var boat: Dictionary = {}


# --- New game --------------------------------------------------------------

## Starts a fresh game from the start values in res://data. Each system adds its seeding
## here as it arrives; so far that is the flood network.
func new_game() -> void:
	clear()
	set_water_state(_water_topology().get_state())


# --- Flags -----------------------------------------------------------------

func set_flag(flag: StringName, value: Variant) -> void:
	if flags.has(flag) and flags[flag] == value:
		return
	flags[flag] = value
	EventBus.flag_set.emit(flag, value)


func get_flag(flag: StringName, default: Variant = false) -> Variant:
	return flags.get(flag, default)


# --- Water -----------------------------------------------------------------

func set_water_level(district_id: StringName, level_id: StringName) -> void:
	if water.get(district_id, &"") == level_id:
		return
	water[district_id] = level_id
	EventBus.water_level_changed.emit(district_id, level_id)


func get_water_level(district_id: StringName) -> StringName:
	return water.get(district_id, &"")


## The flood network in its current state, built fresh from data plus this state so it
## can never drift from what gets saved. Preview on it with WaterSolver, then record the
## result with apply_water_change().
func water_network() -> WaterNetwork:
	var network: WaterNetwork = _water_topology()
	network.set_state(water_state())
	return network


## Records a change previewed on water_network(). Emits water_level_changed for each
## district whose level changed, in flow order; water that only builds up toward a level
## changes no map, so emits nothing. Returns false, changing nothing, if the change was
## rejected or the state moved on since the preview.
func apply_water_change(change: WaterChangeResult) -> bool:
	var network: WaterNetwork = water_network()
	if not WaterSolver.new().apply(network, change):
		return false
	set_water_state(network.get_state())
	var changed: Dictionary[StringName, StringName] = change.level_changes()
	for district_id: StringName in changed:
		EventBus.water_level_changed.emit(district_id, changed[district_id])
	return true


## Water levels, pending water, basins and node states, in WaterNetwork's state shape.
func water_state() -> Dictionary:
	return {
		"water": water.duplicate(),
		"water_pending": water_pending.duplicate(),
		"basins": basins.duplicate(),
		"network_nodes": network_nodes.duplicate(),
	}


## Replaces all water state (new game, load). Does not emit signals.
func set_water_state(state: Dictionary) -> void:
	water.clear()
	water_pending.clear()
	basins.clear()
	network_nodes.clear()
	var src_water: Dictionary = state.get("water", {})
	for key: Variant in src_water:
		water[StringName(str(key))] = StringName(str(src_water[key]))
	var src_pending: Dictionary = state.get("water_pending", {})
	for key: Variant in src_pending:
		water_pending[StringName(str(key))] = int(src_pending[key])
	var src_basins: Dictionary = state.get("basins", {})
	for key: Variant in src_basins:
		basins[StringName(str(key))] = int(src_basins[key])
	var src_nodes: Dictionary = state.get("network_nodes", {})
	for key: Variant in src_nodes:
		network_nodes[StringName(str(key))] = StringName(str(src_nodes[key]))


## The network as data builds it, in its start state.
func _water_topology() -> WaterNetwork:
	return WaterNetwork.from_entries(
		DataRegistry.entries(&"districts"), DataRegistry.entries(&"basins"), DataRegistry.entries(&"nodes"))


# --- Quests ----------------------------------------------------------------

func set_quest_stage(quest_id: StringName, stage_id: StringName) -> void:
	if quests.get(quest_id, &"") == stage_id:
		return
	quests[quest_id] = stage_id
	EventBus.quest_updated.emit(quest_id)


func get_quest_stage(quest_id: StringName) -> StringName:
	return quests.get(quest_id, &"")


# --- Reputation ------------------------------------------------------------

func set_reputation(faction_id: StringName, value: int) -> void:
	var clamped: int = clampi(value, REPUTATION_MIN, REPUTATION_MAX)
	if reputation.has(faction_id) and reputation[faction_id] == clamped:
		return
	reputation[faction_id] = clamped
	EventBus.reputation_changed.emit(faction_id, clamped)


func change_reputation(faction_id: StringName, delta: int) -> void:
	set_reputation(faction_id, get_reputation(faction_id) + delta)


func get_reputation(faction_id: StringName) -> int:
	return reputation.get(faction_id, 0)


# --- Inventory -------------------------------------------------------------
# Stack limits and item rules arrive with core/inventory; this only keeps counts.

## Adds `count` of an item; a negative count removes, never going below zero.
func add_item(item_id: StringName, count: int = 1) -> void:
	if count == 0:
		return
	var index: int = _find_stack(item_id)
	if index == -1:
		if count < 0:
			return
		inventory.append({"id": item_id, "count": count})
		EventBus.item_added.emit(item_id, count)
		return
	var held: int = inventory[index]["count"]
	var applied: int = maxi(count, -held)
	if held + applied == 0:
		inventory.remove_at(index)
	else:
		inventory[index]["count"] = held + applied
	EventBus.item_added.emit(item_id, applied)


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
	water.clear()
	water_pending.clear()
	basins.clear()
	network_nodes.clear()
	flags.clear()
	quests.clear()
	reputation.clear()
	inventory.clear()
	player.clear()
	boat.clear()


## The whole state as JSON-safe data (String keys, no StringNames).
func to_dict() -> Dictionary:
	var stacks: Array = []
	for stack: Dictionary in inventory:
		stacks.append({"id": String(stack["id"]), "count": int(stack["count"])})
	return {
		"version": SAVE_VERSION,
		"water": _json_safe(water),
		"water_pending": _json_safe(water_pending),
		"basins": _json_safe(basins),
		"network_nodes": _json_safe(network_nodes),
		"flags": _json_safe(flags),
		"quests": _json_safe(quests),
		"reputation": _json_safe(reputation),
		"inventory": stacks,
		"player": _json_safe(player),
		"boat": _json_safe(boat),
	}


## Replaces all state with `data`, which must already be at SAVE_VERSION.
## Does not emit signals: the caller reloads the world after loading.
func from_dict(data: Dictionary) -> void:
	clear()
	set_water_state(data)
	var src_flags: Dictionary = data.get("flags", {})
	for key: Variant in src_flags:
		flags[StringName(str(key))] = src_flags[key]
	var src_quests: Dictionary = data.get("quests", {})
	for key: Variant in src_quests:
		quests[StringName(str(key))] = StringName(str(src_quests[key]))
	var src_reputation: Dictionary = data.get("reputation", {})
	for key: Variant in src_reputation:
		reputation[StringName(str(key))] = clampi(int(src_reputation[key]), REPUTATION_MIN, REPUTATION_MAX)
	var src_inventory: Array = data.get("inventory", [])
	for stack: Variant in src_inventory:
		var entry: Dictionary = stack
		inventory.append({"id": StringName(str(entry["id"])), "count": int(entry["count"])})
	player = _whole_numbers_as_int(data.get("player", {}))
	boat = _whole_numbers_as_int(data.get("boat", {}))


## JSON may return 12 as 12.0. Cells, heights and counts are ints, so turn whole floats
## back into ints, recursively, leaving real fractions alone.
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
