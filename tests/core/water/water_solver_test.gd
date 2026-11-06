extends GdUnitTestSuite
## WaterSolver on the real Spillway data and on small hand-built networks.
## Every operation goes through _operate(), which also checks that preview never changes
## the network, that apply lands on exactly the previewed state, and that water is conserved.

var _solver: WaterSolver


func before_test() -> void:
	_solver = WaterSolver.new()


# --- The Spillway (res://data/water/spillway.json) -------------------------

func test_draining_st_aud_through_the_pump_floods_greenterrace() -> void:
	var network: WaterNetwork = _spillway([&"st_aud_pump"])

	var first: WaterChangeResult = _operate(network, &"st_aud_pump", WaterSolver.LOWER)
	assert_str(first.rejected_reason).is_empty()
	assert_dict(_levels(first)).is_equal({&"st_aud": &"waist"})
	assert_int(first.districts[&"greenterrace"]["to_pending"]).is_equal(50)
	assert_that(network.level_id(&"greenterrace")).is_equal(&"dry")

	var second: WaterChangeResult = _operate(network, &"st_aud_pump", WaterSolver.LOWER)
	assert_dict(_levels(second)).is_equal({&"st_aud": &"drained", &"greenterrace": &"flooded"})
	assert_that(network.level_id(&"greenterrace")).is_equal(&"flooded")
	assert_int(network.get_district(&"greenterrace").pending).is_equal(0)

	var third: WaterChangeResult = _operate(network, &"st_aud_pump", WaterSolver.LOWER)
	assert_str(third.rejected_reason).contains("already at its lowest level")


func test_third_outlet_fills_the_reservoir_exactly_and_spares_greenterrace() -> void:
	var network: WaterNetwork = _spillway([&"third_outlet"])
	_operate(network, &"third_outlet", WaterSolver.LOWER)
	var second: WaterChangeResult = _operate(network, &"third_outlet", WaterSolver.LOWER)
	assert_str(second.rejected_reason).is_empty()
	assert_int(network.get_basin(&"old_reservoir").stored).is_equal(100)
	assert_that(network.level_id(&"st_aud")).is_equal(&"drained")
	assert_that(network.level_id(&"greenterrace")).is_equal(&"dry")
	assert_bool(second.districts.has(&"greenterrace")).is_false()


func test_broken_node_is_rejected_with_reason() -> void:
	var network: WaterNetwork = _spillway([])
	var change: WaterChangeResult = _operate(network, &"st_aud_pump", WaterSolver.LOWER)
	assert_bool(change.is_rejected()).is_true()
	assert_str(change.rejected_reason).contains("broken")
	assert_bool(change.districts.is_empty() and change.basins.is_empty()).is_true()


func test_unknown_node_and_bad_direction_are_rejected_with_reason() -> void:
	var network: WaterNetwork = _spillway([&"st_aud_pump"])
	assert_str(_solver.preview(network, &"no_such_node", WaterSolver.LOWER).rejected_reason).contains("no network node")
	assert_str(_solver.preview(network, &"st_aud_pump", 2).rejected_reason).contains("Direction")


func test_raising_pulls_water_back_from_a_basin() -> void:
	var network: WaterNetwork = _spillway([&"third_outlet"])
	_operate(network, &"third_outlet", WaterSolver.LOWER)
	_operate(network, &"third_outlet", WaterSolver.LOWER)

	var up: WaterChangeResult = _operate(network, &"third_outlet", WaterSolver.RAISE)
	assert_dict(_levels(up)).is_equal({&"st_aud": &"waist"})
	assert_int(network.get_basin(&"old_reservoir").stored).is_equal(50)
	_operate(network, &"third_outlet", WaterSolver.RAISE)
	assert_that(network.level_id(&"st_aud")).is_equal(&"flooded")
	assert_int(network.get_basin(&"old_reservoir").stored).is_equal(0)

	var top: WaterChangeResult = _operate(network, &"third_outlet", WaterSolver.RAISE)
	assert_str(top.rejected_reason).contains("already at its highest level")


func test_raising_through_the_pump_drains_greenterrace_again() -> void:
	var network: WaterNetwork = _spillway([&"st_aud_pump"])
	_operate(network, &"st_aud_pump", WaterSolver.LOWER)
	_operate(network, &"st_aud_pump", WaterSolver.LOWER)
	var up: WaterChangeResult = _operate(network, &"st_aud_pump", WaterSolver.RAISE)
	assert_dict(_levels(up)).is_equal({&"st_aud": &"waist", &"greenterrace": &"dry"})
	assert_int(network.get_district(&"greenterrace").pending).is_equal(50)


func test_raising_needs_enough_water_in_the_target() -> void:
	var network: WaterNetwork = _spillway([&"st_aud_pump", &"third_outlet"])
	_operate(network, &"st_aud_pump", WaterSolver.LOWER)
	var change: WaterChangeResult = _operate(network, &"third_outlet", WaterSolver.RAISE)
	assert_str(change.rejected_reason).contains("Old Reservoir holds 0 units")


func test_describe_lists_every_consequence() -> void:
	var network: WaterNetwork = _spillway([&"st_aud_pump"])
	var change: WaterChangeResult = _solver.preview(network, &"st_aud_pump", WaterSolver.LOWER)
	assert_array(Array(change.describe())).is_equal([
		"St. Aud Hospital: flooded -> waist",
		"Greenterrace: water rising, 50 of 100 toward the next level",
	])


# --- Hand-built networks ---------------------------------------------------

func test_overflow_cascades_along_outflows_in_order() -> void:
	var districts: Array = [
		_district("upper", [6, 4, 2, 0], 30, 0, []),
		_district("middle", [3, 1], 40, 1, ["spill", "lower"]),
		_district("lower", [2, 0], 30, 1, ["upper"]),
	]
	var network: WaterNetwork = WaterNetwork.from_entries(districts, [_basin("spill", 20, 0)], [_node("pump", "upper", "middle")])

	var first: WaterChangeResult = _operate(network, &"pump", WaterSolver.LOWER)
	assert_dict(_levels(first)).is_equal({&"upper": &"l1"})
	assert_int(network.get_district(&"middle").pending).is_equal(30)

	# Middle needs 10 more to rise; the other 20 overflow into its first outflow, the basin.
	var second: WaterChangeResult = _operate(network, &"pump", WaterSolver.LOWER)
	assert_array(second.districts.keys()).is_equal([&"upper", &"middle"])
	assert_array(second.basins.keys()).is_equal([&"spill"])
	assert_that(network.level_id(&"middle")).is_equal(&"l0")
	assert_int(network.get_basin(&"spill").stored).is_equal(20)

	# Middle and the basin are full, so the water goes on to the second outflow.
	var third: WaterChangeResult = _operate(network, &"pump", WaterSolver.LOWER)
	assert_dict(_levels(third)).is_equal({&"upper": &"l3", &"lower": &"l0"})
	assert_bool(third.basins.has(&"spill")).is_false()

	var fourth: WaterChangeResult = _operate(network, &"pump", WaterSolver.LOWER)
	assert_str(fourth.rejected_reason).contains("already at its lowest level")


func test_water_never_flows_back_into_the_district_being_drained() -> void:
	var districts: Array = [
		_district("source", [2, 0], 50, 0, []),
		_district("pond", [3, 1], 50, 0, ["source"]),
	]
	var network: WaterNetwork = WaterNetwork.from_entries(districts, [], [_node("pump", "source", "pond")])
	var change: WaterChangeResult = _operate(network, &"pump", WaterSolver.LOWER)
	assert_str(change.rejected_reason).contains("Nowhere for the water to go")
	assert_that(network.level_id(&"source")).is_equal(&"l0")


func test_a_basin_never_takes_more_than_its_capacity() -> void:
	var network: WaterNetwork = WaterNetwork.from_entries([_district("source", [4, 2, 0], 50, 0, [])], [_basin("tank", 80, 0)], [_node("drain", "source", "tank")])
	_operate(network, &"drain", WaterSolver.LOWER)
	var over: WaterChangeResult = _operate(network, &"drain", WaterSolver.LOWER)
	assert_str(over.rejected_reason).contains("Tank and everything downstream of it is full (20 units left over)")
	assert_int(network.get_basin(&"tank").stored).is_equal(50)
	assert_that(network.level_id(&"source")).is_equal(&"l1")


func test_stale_previews_are_not_applied() -> void:
	var network: WaterNetwork = _spillway([&"third_outlet"])
	var change: WaterChangeResult = _solver.preview(network, &"third_outlet", WaterSolver.LOWER)
	assert_bool(_solver.apply(network, change)).is_true()
	assert_bool(_solver.apply(network, change)).is_false()

	var next: WaterChangeResult = _solver.preview(network, &"third_outlet", WaterSolver.LOWER)
	network.set_node_state(&"third_outlet", WaterNetwork.STATE_BROKEN)
	assert_bool(_solver.apply(network, next)).is_false()
	assert_int(network.get_basin(&"old_reservoir").stored).is_equal(50)


func test_any_sequence_of_operations_conserves_water() -> void:
	var districts: Array = [
		_district("upper", [6, 4, 2, 0], 30, 0, ["middle"]),
		_district("middle", [3, 1], 40, 0, ["spill", "lower"]),
		_district("lower", [2, 1, 0], 25, 1, ["upper"]),
	]
	var nodes: Array = [_node("pump", "upper", "middle"), _node("sluice", "middle", "lower"), _node("drain", "lower", "spill")]
	var network: WaterNetwork = WaterNetwork.from_entries(districts, [_basin("spill", 70, 35)], nodes)
	var total: int = network.total_water()
	var node_ids: Array[StringName] = [&"pump", &"sluice", &"drain"]
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = 20261106
	var applied: int = 0
	for i: int in 300:
		var direction: int = WaterSolver.LOWER if rng.randf() < 0.5 else WaterSolver.RAISE
		var change: WaterChangeResult = _solver.preview(network, node_ids[rng.randi_range(0, 2)], direction)
		if _solver.apply(network, change):
			applied += 1
		assert_int(network.total_water()).is_equal(total)
		_assert_invariants(network)
	assert_int(applied).is_greater(50)


# --- Helpers ---------------------------------------------------------------

## Previews, checks the preview left the network alone, applies, and checks the network
## now matches the preview exactly and holds the same total water.
func _operate(network: WaterNetwork, node_id: StringName, direction: int) -> WaterChangeResult:
	var before: Dictionary = network.get_state()
	var total: int = network.total_water()
	var change: WaterChangeResult = _solver.preview(network, node_id, direction)
	assert_str(_snapshot(network.get_state())).is_equal(_snapshot(before))
	if change.is_rejected():
		assert_bool(_solver.apply(network, change)).is_false()
		return change
	assert_bool(_solver.apply(network, change)).is_true()
	assert_str(_snapshot(network.get_state())).is_equal(_snapshot(_expected_after(before, change)))
	assert_int(network.total_water()).is_equal(total)
	return change


func _expected_after(before: Dictionary, change: WaterChangeResult) -> Dictionary:
	var expected: Dictionary = before.duplicate(true)
	for id: StringName in change.districts:
		expected["water"][id] = change.districts[id]["to_level"]
		expected["water_pending"][id] = change.districts[id]["to_pending"]
	for id: StringName in change.basins:
		expected["basins"][id] = change.basins[id]["to_stored"]
	return expected


func _assert_invariants(network: WaterNetwork) -> void:
	for district: WaterNetwork.District in network.districts.values():
		var message: String = "%s pending %d (step %d, level %s)" % [district.id, district.pending, district.volume_per_step, district.level_id()]
		var ok: bool = district.pending >= 0 and district.pending < district.volume_per_step
		assert_bool(ok and (district.pending == 0 or not district.is_highest())).override_failure_message(message).is_true()
	for basin: WaterNetwork.Basin in network.basins.values():
		assert_bool(basin.stored >= 0 and basin.stored <= basin.capacity).is_true()


## Level changes as a plain Dictionary, so it compares cleanly with a literal.
func _levels(change: WaterChangeResult) -> Dictionary:
	var out: Dictionary = {}
	var changes: Dictionary = change.level_changes()
	for id: Variant in changes:
		out[id] = changes[id]
	return out


func _snapshot(state: Dictionary) -> String:
	return JSON.stringify(state, "", true)


func _spillway(repaired: Array) -> WaterNetwork:
	var network: WaterNetwork = WaterNetwork.from_entries(DataRegistry.entries(&"districts"), DataRegistry.entries(&"basins"), DataRegistry.entries(&"nodes"))
	for id: Variant in repaired:
		network.set_node_state(StringName(str(id)), WaterNetwork.STATE_REPAIRED)
	return network


func _district(id: String, heights: Array, step_volume: int, start_index: int, outflows: Array) -> Dictionary:
	var levels: Array = []
	for i: int in heights.size():
		levels.append({"id": "l%d" % i, "water_height": heights[i]})
	return {"id": id, "name": id.capitalize(), "levels": levels, "start_level": "l%d" % start_index, "water_volume_per_step": step_volume, "outflows": outflows}


func _basin(id: String, capacity: int, stored: int) -> Dictionary:
	return {"id": id, "name": id.capitalize(), "capacity": capacity, "start_stored": stored}


func _node(id: String, district: String, target: String) -> Dictionary:
	return {"id": id, "type": "pump", "district": district, "target": target, "start_state": "repaired"}
