extends GdUnitTestSuite
## WaterNetwork: built from data in its start state; state survives get/set and copies.


func test_start_state_comes_from_data() -> void:
	var network: WaterNetwork = _spillway()
	assert_that(network.level_id(&"st_aud")).is_equal(&"flooded")
	assert_int(network.water_height(&"st_aud")).is_equal(4)
	assert_that(network.level_id(&"greenterrace")).is_equal(&"dry")
	assert_int(network.water_height(&"greenterrace")).is_equal(1)
	assert_int(network.get_basin(&"old_reservoir").capacity).is_equal(100)
	assert_int(network.get_basin(&"old_reservoir").stored).is_equal(0)
	assert_bool(network.get_network_node(&"st_aud_pump").is_repaired()).is_false()
	assert_that(network.get_network_node(&"third_outlet").target).is_equal(&"old_reservoir")


func test_total_water_counts_levels_pending_and_basins() -> void:
	var network: WaterNetwork = _spillway()
	# St. Aud starts flooded: 2 levels above drained, 50 units each.
	assert_int(network.total_water()).is_equal(100)
	network.get_district(&"greenterrace").pending = 30
	network.get_basin(&"old_reservoir").stored = 20
	assert_int(network.total_water()).is_equal(150)


func test_state_round_trips_through_get_and_set() -> void:
	var network: WaterNetwork = _spillway()
	network.get_district(&"st_aud").level_index = 1
	network.get_district(&"greenterrace").pending = 50
	network.get_basin(&"old_reservoir").stored = 30
	network.set_node_state(&"third_outlet", WaterNetwork.STATE_REPAIRED)
	var restored: WaterNetwork = _spillway()
	restored.set_state(network.get_state())
	assert_str(_snapshot(restored)).is_equal(_snapshot(network))


func test_copies_do_not_share_state() -> void:
	var network: WaterNetwork = _spillway()
	var copy: WaterNetwork = network.copy()
	copy.get_district(&"st_aud").level_index = 2
	copy.get_basin(&"old_reservoir").stored = 99
	copy.set_node_state(&"st_aud_pump", WaterNetwork.STATE_REPAIRED)
	assert_that(network.level_id(&"st_aud")).is_equal(&"flooded")
	assert_int(network.get_basin(&"old_reservoir").stored).is_equal(0)
	assert_bool(network.get_network_node(&"st_aud_pump").is_repaired()).is_false()


func test_set_state_skips_unknown_ids_and_clamps_numbers() -> void:
	var network: WaterNetwork = _spillway()
	network.set_state({
		"water": {"st_aud": "not_a_level", "atlantis": "dry"},
		"water_pending": {"greenterrace": 999},
		"basins": {"old_reservoir": 500},
		"network_nodes": {"st_aud_pump": "exploded"},
	})
	assert_that(network.level_id(&"st_aud")).is_equal(&"flooded")
	assert_int(network.get_district(&"greenterrace").pending).is_equal(99)
	assert_int(network.get_basin(&"old_reservoir").stored).is_equal(100)
	assert_bool(network.get_network_node(&"st_aud_pump").is_repaired()).is_false()


func _spillway() -> WaterNetwork:
	return WaterNetwork.from_entries(DataRegistry.entries(&"districts"), DataRegistry.entries(&"basins"), DataRegistry.entries(&"nodes"))


func _snapshot(network: WaterNetwork) -> String:
	return JSON.stringify(network.get_state(), "", true)
