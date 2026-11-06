class_name WaterNetwork
extends RefCounted
## Topology and current state of the flood network (docs/TECH_DESIGN.md §3.1). Pure data:
## no scene nodes, no autoloads, so it is fully unit-testable.
##
## Water is counted in whole units. A district holds
## `levels above its lowest × water_volume_per_step + pending` units, where `pending` is
## water that has arrived but does not yet make a full step. A basin holds `stored` units,
## up to `capacity`. WaterSolver moves water around; total_water() never changes.

const STATE_BROKEN: StringName = &"broken"
const STATE_REPAIRED: StringName = &"repaired"


class District:
	var id: StringName
	var name: String
	## Level ids from most water to least. Shared between copies; never mutated.
	var level_ids: Array[StringName] = []
	## Water height of each level, same order, strictly decreasing.
	var water_heights: Array[int] = []
	var volume_per_step: int = 1
	## Where overflow goes once this district is at its highest level, in order.
	var outflows: Array[StringName] = []
	## Index into level_ids. 0 is the most water.
	var level_index: int = 0
	## Units received toward the next level up. 0 <= pending < volume_per_step,
	## and 0 at the highest level.
	var pending: int = 0

	func level_id() -> StringName:
		return level_ids[level_index]

	func water_height() -> int:
		return water_heights[level_index]

	func is_highest() -> bool:
		return level_index == 0

	func is_lowest() -> bool:
		return level_index == level_ids.size() - 1

	## Units held above the lowest level.
	func volume() -> int:
		return (level_ids.size() - 1 - level_index) * volume_per_step + pending

	## Units it can still take before reaching its highest level.
	func room() -> int:
		return level_index * volume_per_step - pending

	func copy() -> District:
		var other: District = District.new()
		other.id = id
		other.name = name
		other.level_ids = level_ids
		other.water_heights = water_heights
		other.volume_per_step = volume_per_step
		other.outflows = outflows
		other.level_index = level_index
		other.pending = pending
		return other


class Basin:
	var id: StringName
	var name: String
	var capacity: int = 0
	var stored: int = 0

	func room() -> int:
		return capacity - stored

	func copy() -> Basin:
		var other: Basin = Basin.new()
		other.id = id
		other.name = name
		other.capacity = capacity
		other.stored = stored
		return other


class NetworkNode:
	var id: StringName
	## pump, sluice or outlet. All behave the same in the solver for now.
	var type: StringName
	## The district this node raises and lowers.
	var district: StringName
	## The district or basin that receives (or gives back) the water.
	var target: StringName
	var state: StringName = STATE_BROKEN

	func is_repaired() -> bool:
		return state == STATE_REPAIRED

	func copy() -> NetworkNode:
		var other: NetworkNode = NetworkNode.new()
		other.id = id
		other.type = type
		other.district = district
		other.target = target
		other.state = state
		return other


var districts: Dictionary[StringName, District] = {}
var basins: Dictionary[StringName, Basin] = {}
var nodes: Dictionary[StringName, NetworkNode] = {}


## Builds a network in its start state from DataRegistry-shaped entries
## (docs/data/water_network.schema.json). Entries are assumed valid: DataRegistry checked them.
static func from_entries(district_entries: Array, basin_entries: Array, node_entries: Array) -> WaterNetwork:
	var network: WaterNetwork = WaterNetwork.new()
	for entry: Dictionary in district_entries:
		var district: District = District.new()
		district.id = StringName(str(entry["id"]))
		district.name = str(entry.get("name", district.id))
		for level: Dictionary in entry["levels"]:
			district.level_ids.append(StringName(str(level["id"])))
			district.water_heights.append(int(level["water_height"]))
		district.volume_per_step = maxi(1, int(entry["water_volume_per_step"]))
		for target: Variant in entry["outflows"]:
			district.outflows.append(StringName(str(target)))
		district.level_index = maxi(0, district.level_ids.find(StringName(str(entry["start_level"]))))
		network.districts[district.id] = district
	for entry: Dictionary in basin_entries:
		var basin: Basin = Basin.new()
		basin.id = StringName(str(entry["id"]))
		basin.name = str(entry.get("name", basin.id))
		basin.capacity = maxi(0, int(entry["capacity"]))
		basin.stored = clampi(int(entry["start_stored"]), 0, basin.capacity)
		network.basins[basin.id] = basin
	for entry: Dictionary in node_entries:
		var node: NetworkNode = NetworkNode.new()
		node.id = StringName(str(entry["id"]))
		node.type = StringName(str(entry["type"]))
		node.district = StringName(str(entry["district"]))
		node.target = StringName(str(entry["target"]))
		node.state = StringName(str(entry["start_state"]))
		network.nodes[node.id] = node
	return network


# --- Lookups ---------------------------------------------------------------

func get_district(id: StringName) -> District:
	return districts.get(id)


func get_basin(id: StringName) -> Basin:
	return basins.get(id)


func get_network_node(id: StringName) -> NetworkNode:
	return nodes.get(id)


func level_id(district_id: StringName) -> StringName:
	return districts[district_id].level_id()


func water_height(district_id: StringName) -> int:
	return districts[district_id].water_height()


## Display name of a district or basin, or the id itself if unknown.
func display_name(id: StringName) -> String:
	if districts.has(id):
		return districts[id].name
	if basins.has(id):
		return basins[id].name
	return String(id)


func set_node_state(node_id: StringName, state: StringName) -> void:
	if nodes.has(node_id) and (state == STATE_BROKEN or state == STATE_REPAIRED):
		nodes[node_id].state = state


## Every unit of water in the network. WaterSolver keeps this constant.
func total_water() -> int:
	var total: int = 0
	for district: District in districts.values():
		total += district.volume()
	for basin: Basin in basins.values():
		total += basin.stored
	return total


# --- State -----------------------------------------------------------------

## Mutable state, in GameState's shape:
## { water: {district: level}, water_pending: {district: int},
##   basins: {basin: int}, network_nodes: {node: state} }
func get_state() -> Dictionary:
	var water: Dictionary[StringName, StringName] = {}
	var pending: Dictionary[StringName, int] = {}
	for id: StringName in districts:
		water[id] = districts[id].level_id()
		pending[id] = districts[id].pending
	var stored: Dictionary[StringName, int] = {}
	for id: StringName in basins:
		stored[id] = basins[id].stored
	var node_states: Dictionary[StringName, StringName] = {}
	for id: StringName in nodes:
		node_states[id] = nodes[id].state
	return {"water": water, "water_pending": pending, "basins": stored, "network_nodes": node_states}


## Applies saved state on top of the start state. Unknown ids and level ids are skipped
## with a warning (content changed since the save); out-of-range numbers are clamped.
func set_state(state: Dictionary) -> void:
	var water: Dictionary = state.get("water", {})
	for key: Variant in water:
		var district: District = districts.get(StringName(str(key)))
		var index: int = -1 if district == null else district.level_ids.find(StringName(str(water[key])))
		if index == -1:
			push_warning("WaterNetwork: ignoring saved level '%s' for '%s'." % [water[key], key])
			continue
		district.level_index = index
		district.pending = 0
	var pending: Dictionary = state.get("water_pending", {})
	for key: Variant in pending:
		var district: District = districts.get(StringName(str(key)))
		if district == null:
			push_warning("WaterNetwork: ignoring pending water for unknown district '%s'." % key)
			continue
		var limit: int = 0 if district.is_highest() else district.volume_per_step - 1
		district.pending = clampi(int(pending[key]), 0, limit)
	var stored: Dictionary = state.get("basins", {})
	for key: Variant in stored:
		var basin: Basin = basins.get(StringName(str(key)))
		if basin == null:
			push_warning("WaterNetwork: ignoring unknown basin '%s'." % key)
			continue
		basin.stored = clampi(int(stored[key]), 0, basin.capacity)
	var node_states: Dictionary = state.get("network_nodes", {})
	for key: Variant in node_states:
		set_node_state(StringName(str(key)), StringName(str(node_states[key])))


## A deep copy of the mutable state. Topology arrays are shared because they never change.
func copy() -> WaterNetwork:
	var other: WaterNetwork = WaterNetwork.new()
	for id: StringName in districts:
		other.districts[id] = districts[id].copy()
	for id: StringName in basins:
		other.basins[id] = basins[id].copy()
	for id: StringName in nodes:
		other.nodes[id] = nodes[id].copy()
	return other
