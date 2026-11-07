extends GdUnitTestSuite
## M4 acceptance: draining St. Aud from the pump visibly floods Greenterrace, and the preview
## warned about it first. Played through the real St. Aud scene, the real Network Key panel
## and the real Greenterrace scene.

const PUMP_CELL: Vector2i = Vector2i(10, 7)


func before_test() -> void:
	get_tree().paused = false
	GameState.clear()


func after_test() -> void:
	get_tree().paused = false
	GameState.clear()


func test_draining_st_aud_through_the_pump_floods_greenterrace_after_a_warning() -> void:
	var district: DistrictController = await _district(&"st_aud")
	var greenterrace_before: int = _deep_cells(_load_district(&"greenterrace"))
	district.player.motor.place(PUMP_CELL)

	# 1. The pump is broken and there's no valve: nothing happens.
	assert_bool(district.interact()).is_false()
	assert_bool(GameState.is_network_node_repaired(&"st_aud_pump")).is_false()

	# 2. With the valve, the pump is repaired and the valve is used up.
	GameState.add_item(&"pump_valve", 1)
	assert_bool(district.interact()).is_true()
	assert_bool(GameState.is_network_node_repaired(&"st_aud_pump")).is_true()
	assert_int(GameState.item_count(&"pump_valve")).is_equal(0)

	# 3. First drain: the preview shows both consequences, then it's applied.
	assert_bool(district.interact()).is_true()
	var panel: NetworkPanel = district.network_panel
	assert_bool(panel.is_open()).is_true()
	assert_bool(get_tree().paused).override_failure_message("the game waits while you decide").is_true()
	assert_array(Array(panel.change.describe())).is_equal([
		"St. Aud Hospital: flooded -> waist",
		"Greenterrace: water rising, 50 of 100 toward the next level",
	])
	assert_bool(panel.confirm()).is_true()
	assert_bool(get_tree().paused).is_false()
	assert_that(GameState.get_water_level(&"st_aud")).is_equal(&"waist")
	assert_that(GameState.get_water_level(&"greenterrace")).is_equal(&"dry")

	# 4. Second drain: the preview warns that Greenterrace floods before anything changes.
	assert_bool(district.interact()).is_true()
	assert_array(Array(panel.change.describe())).contains("Greenterrace: dry -> flooded")
	assert_that(panel.map.outline_for(&"greenterrace")).is_equal(RegionMap.FLOODS)
	assert_that(GameState.get_water_level(&"greenterrace")).override_failure_message("nothing happens until you confirm").is_equal(&"dry")
	assert_bool(panel.confirm()).is_true()
	assert_that(GameState.get_water_level(&"st_aud")).is_equal(&"drained")
	assert_that(GameState.get_water_level(&"greenterrace")).is_equal(&"flooded")
	assert_int(district.water_layer.get_used_cells_by_id(GreyboxTiles.SOURCE_ID, GreyboxTiles.WATER_DEEP).size()).is_equal(0)

	# 5. And it shows: Greenterrace's streets are now deep water.
	var greenterrace_after: int = _deep_cells(_load_district(&"greenterrace"))
	print("  Greenterrace deep cells: %d before the drain, %d after" % [greenterrace_before, greenterrace_after])
	assert_int(greenterrace_before).is_equal(0)
	assert_int(greenterrace_after).is_greater(500)


func test_impossible_changes_are_refused_and_the_preview_can_be_cancelled() -> void:
	var district: DistrictController = await _district(&"st_aud")
	GameState.add_item(&"pump_valve", 1)
	GameState.repair_network_node(&"st_aud_pump")
	district.player.motor.place(PUMP_CELL)
	assert_bool(district.interact()).is_true()
	var panel: NetworkPanel = district.network_panel
	panel.choose(WaterSolver.RAISE)
	assert_str(panel.change.rejected_reason).contains("already at its highest level")
	assert_bool(panel.confirm()).is_false()
	assert_bool(panel.is_open()).is_true()
	panel.choose(WaterSolver.LOWER)
	panel.cancel()
	assert_bool(panel.is_open()).is_false()
	assert_bool(get_tree().paused).is_false()
	assert_that(GameState.get_water_level(&"st_aud")).is_equal(&"flooded")
	assert_int(GameState.water_pending.get(&"greenterrace", 0)).is_equal(0)


func test_the_pump_valve_is_waiting_on_spire_nine() -> void:
	var district: DistrictController = await _district(&"spire_nine")
	district.player.motor.place(Vector2i(10, 15))
	assert_object(district.interactable_under_player()).is_instanceof(ItemPickup)
	assert_bool(district.interact()).is_true()
	assert_int(GameState.item_count(&"pump_valve")).is_equal(1)
	assert_bool(GameState.get_flag(&"spire_nine_pump_valve_taken")).is_true()
	assert_object(district.interactable_under_player()).override_failure_message("nothing left to pick up").is_null()
	assert_bool(district.interact()).is_false()
	assert_int(GameState.item_count(&"pump_valve")).is_equal(1)


func _district(district_id: StringName) -> DistrictController:
	var runner: GdUnitSceneRunner = scene_runner(WorldPaths.scene_for(district_id))
	await runner.simulate_frames(1)
	var district: DistrictController = runner.scene()
	district.travel = func(_path: String) -> void: pass
	return district


## Loads a district into the tree as it would look right now, for a look at its water.
func _load_district(district_id: StringName) -> DistrictController:
	var district: DistrictController = auto_free((load(WorldPaths.scene_for(district_id)) as PackedScene).instantiate())
	add_child(district)
	return district


func _deep_cells(district: DistrictController) -> int:
	var count: int = district.water_layer.get_used_cells_by_id(GreyboxTiles.SOURCE_ID, GreyboxTiles.WATER_DEEP).size()
	remove_child(district)
	return count
