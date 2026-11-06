class_name WaterSolver
extends RefCounted
## Decides what a network operation does (docs/TECH_DESIGN.md §3.1). Stateless and pure.
##
## LOWER moves one step of the source district's water (its water_volume_per_step) into
## the node's target. RAISE pulls the same amount back from the node's target. A district
## that receives water keeps it as `pending` and rises one level each time a full step of
## its own has arrived; at its highest level it passes the rest along its outflows, in
## order. Each district is visited at most once per operation, and water never flows back
## into the district being changed. Anything left with nowhere to go rejects the whole
## operation. Total water is conserved exactly.

const LOWER: int = -1
const RAISE: int = 1


## What operating `node_id` in `direction` would do. Never modifies `network`.
func preview(network: WaterNetwork, node_id: StringName, direction: int) -> WaterChangeResult:
	var result: WaterChangeResult = WaterChangeResult.new()
	result.node_id = node_id
	result.direction = direction
	if direction != LOWER and direction != RAISE:
		return _reject(result, "Direction must be LOWER (-1) or RAISE (+1), not %d." % direction)
	var node: WaterNetwork.NetworkNode = network.get_network_node(node_id)
	if node == null:
		return _reject(result, "There is no network node '%s'." % node_id)
	result.source_district = node.district
	if not node.is_repaired():
		return _reject(result, "The %s '%s' is broken and must be repaired first." % [node.type, node_id])

	var sim: WaterNetwork = network.copy()
	var source: WaterNetwork.District = sim.get_district(node.district)
	var order: Array[StringName] = [source.id]
	result.volume = source.volume_per_step
	if direction == LOWER:
		if source.is_lowest():
			return _reject(result, "%s is already at its lowest level (%s)." % [source.name, source.level_id()])
		source.level_index += 1
		var leftover: int = _deliver(sim, node.target, source.volume_per_step, {source.id: true}, order)
		if leftover > 0:
			return _reject(result, _no_room(sim, node.target, leftover))
	else:
		if source.is_highest():
			return _reject(result, "%s is already at its highest level (%s)." % [source.name, source.level_id()])
		var shortage: String = _withdraw(sim, node.target, source.volume_per_step, order)
		if not shortage.is_empty():
			return _reject(result, shortage)
		var leftover: int = _deliver(sim, source.id, source.volume_per_step, {node.target: true}, order)
		if leftover > 0:
			return _reject(result, _no_room(sim, source.id, leftover))
	_record(result, network, sim, order)
	return result


## Makes a previewed change real. Returns false and changes nothing if the change was
## rejected, or if `network` is no longer in the state the change was previewed from.
func apply(network: WaterNetwork, change: WaterChangeResult) -> bool:
	if change.is_rejected() or not matches_start(network, change):
		return false
	for id: StringName in change.districts:
		var district: WaterNetwork.District = network.get_district(id)
		district.level_index = district.level_ids.find(change.districts[id]["to_level"])
		district.pending = change.districts[id]["to_pending"]
	for id: StringName in change.basins:
		network.get_basin(id).stored = change.basins[id]["to_stored"]
	return true


## True if `network` is still in the state `change` was previewed from: same values for
## everything it affects, and the node still repaired.
func matches_start(network: WaterNetwork, change: WaterChangeResult) -> bool:
	var node: WaterNetwork.NetworkNode = network.get_network_node(change.node_id)
	if node == null or not node.is_repaired():
		return false
	for id: StringName in change.districts:
		var district: WaterNetwork.District = network.get_district(id)
		var entry: Dictionary = change.districts[id]
		if district == null or district.level_id() != entry["from_level"] or district.pending != entry["from_pending"]:
			return false
	for id: StringName in change.basins:
		var basin: WaterNetwork.Basin = network.get_basin(id)
		if basin == null or basin.stored != change.basins[id]["from_stored"]:
			return false
	return true


## Puts `amount` units into `target_id`, cascading along outflows. Returns what did not
## fit anywhere. `visited` holds districts that must not receive water in this operation.
func _deliver(sim: WaterNetwork, target_id: StringName, amount: int, visited: Dictionary,
		order: Array[StringName]) -> int:
	if amount <= 0:
		return 0
	var basin: WaterNetwork.Basin = sim.get_basin(target_id)
	if basin != null:
		_touch(order, target_id)
		var into_basin: int = mini(amount, basin.room())
		basin.stored += into_basin
		return amount - into_basin
	var district: WaterNetwork.District = sim.get_district(target_id)
	if district == null or visited.has(target_id):
		return amount
	visited[target_id] = true
	_touch(order, target_id)
	var absorbed: int = mini(amount, district.room())
	district.pending += absorbed
	while district.pending >= district.volume_per_step and district.level_index > 0:
		district.pending -= district.volume_per_step
		district.level_index -= 1
	var leftover: int = amount - absorbed
	for outflow: StringName in district.outflows:
		if leftover == 0:
			break
		leftover = _deliver(sim, outflow, leftover, visited, order)
	return leftover


## Takes `amount` units out of `target_id` (not its neighbours). Returns why it could
## not, or an empty string on success.
func _withdraw(sim: WaterNetwork, target_id: StringName, amount: int, order: Array[StringName]) -> String:
	var basin: WaterNetwork.Basin = sim.get_basin(target_id)
	if basin != null:
		if basin.stored < amount:
			return "%s holds %d units; raising needs %d." % [basin.name, basin.stored, amount]
		basin.stored -= amount
		_touch(order, target_id)
		return ""
	var district: WaterNetwork.District = sim.get_district(target_id)
	if district == null:
		return "There is no district or basin '%s' to draw water from." % target_id
	if district.volume() < amount:
		return "%s holds %d units above its lowest level; raising needs %d." % [district.name, district.volume(), amount]
	if district.pending >= amount:
		district.pending -= amount
	else:
		var deficit: int = amount - district.pending
		var steps: int = ceili(float(deficit) / float(district.volume_per_step))
		district.level_index += steps
		district.pending = steps * district.volume_per_step - deficit
	_touch(order, target_id)
	return ""


func _record(result: WaterChangeResult, before: WaterNetwork, after: WaterNetwork,
		order: Array[StringName]) -> void:
	for id: StringName in order:
		var now: WaterNetwork.District = after.get_district(id)
		if now != null:
			var was: WaterNetwork.District = before.get_district(id)
			if now.level_index != was.level_index or now.pending != was.pending:
				result.districts[id] = {
					"name": now.name,
					"from_level": was.level_id(),
					"to_level": now.level_id(),
					"from_pending": was.pending,
					"to_pending": now.pending,
					"step_volume": now.volume_per_step,
				}
			continue
		var basin_now: WaterNetwork.Basin = after.get_basin(id)
		var basin_was: WaterNetwork.Basin = before.get_basin(id)
		if basin_now != null and basin_now.stored != basin_was.stored:
			result.basins[id] = {
				"name": basin_now.name,
				"from_stored": basin_was.stored,
				"to_stored": basin_now.stored,
				"capacity": basin_now.capacity,
			}


func _no_room(sim: WaterNetwork, first_target: StringName, leftover: int) -> String:
	return "Nowhere for the water to go: %s and everything downstream of it is full (%d units left over)." % [sim.display_name(first_target), leftover]


func _touch(order: Array[StringName], id: StringName) -> void:
	if not order.has(id):
		order.append(id)


func _reject(result: WaterChangeResult, reason: String) -> WaterChangeResult:
	result.rejected_reason = reason
	result.districts.clear()
	result.basins.clear()
	return result
