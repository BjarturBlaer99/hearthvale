extends GdUnitTestSuite
## The St. Aud scene running: every water level redraws the map to match the terrain,
## nothing else resets when the water changes, the water moves the player between walking
## and swimming, points of interest respect the water, and the move actions drive the player.

const SCENE: String = "res://world/districts/st_aud/st_aud.tscn"
const NO_TILE: Vector2i = Vector2i(-1, -1)


func before_test() -> void:
	GameState.clear()


func after_test() -> void:
	Input.action_release(&"move_right")
	GameState.clear()


func test_cycling_water_redraws_the_map_and_keeps_everything_else() -> void:
	var runner: GdUnitSceneRunner = scene_runner(SCENE)
	var district: DistrictController = runner.scene()
	var player: PlayerController = district.player
	assert_that(GameState.get_water_level(&"st_aud")).is_equal(&"flooded")
	_assert_water_matches_terrain(district)

	GameState.set_flag(&"st_aud_rooftop_door_opened", true)
	player.motor.stamina = 60.0
	var start: Vector2 = player.motor.position
	var levels: Array = []
	var deep_counts: Array = []
	for i: int in 3:
		district.cycle_water_level()
		await runner.simulate_frames(2)
		levels.append(GameState.get_water_level(&"st_aud"))
		deep_counts.append(district.water_layer.get_used_cells_by_id(GreyboxTiles.SOURCE_ID, GreyboxTiles.WATER_DEEP).size())
		_assert_water_matches_terrain(district)
		assert_that(player.motor.position).is_equal(start)
		assert_that(player.position).is_equal(start)
		assert_bool(GameState.get_flag(&"st_aud_rooftop_door_opened")).is_true()
		assert_int(district.last_redraw_usec).is_less(200000)
		print("  water %s: %d deep cells, redraw %.1f ms" % [levels[-1], deep_counts[-1], district.last_redraw_usec / 1000.0])
	assert_array(levels).is_equal([&"waist", &"drained", &"flooded"])
	assert_int(deep_counts[1]).is_equal(0)
	assert_int(deep_counts[2]).is_greater(deep_counts[0])
	assert_float(player.motor.stamina).is_greater(59.0)


func test_water_lifts_and_strands_the_player() -> void:
	var runner: GdUnitSceneRunner = scene_runner(SCENE)
	var district: DistrictController = runner.scene()
	var motor: PlayerMotor = district.player.motor
	motor.place(Vector2i(43, 46))
	assert_that(motor.state_name).is_equal(PlayerMotor.SWIM)
	assert_int(motor.level).is_equal(4)
	district.cycle_water_level()
	assert_that(motor.state_name).is_equal(PlayerMotor.SWIM)
	assert_int(motor.level).is_equal(2)
	district.cycle_water_level()
	assert_that(motor.state_name).is_equal(PlayerMotor.GROUND)
	assert_int(motor.level).is_equal(0)


func test_points_of_interest_follow_the_water() -> void:
	var runner: GdUnitSceneRunner = scene_runner(SCENE)
	var district: DistrictController = runner.scene()
	var motor: PlayerMotor = district.player.motor
	motor.place(Vector2i(44, 48))
	assert_bool(district.interact()).override_failure_message("subway while flooded").is_false()
	district.cycle_water_level()
	district.cycle_water_level()
	assert_that(GameState.get_water_level(&"st_aud")).is_equal(&"drained")
	assert_bool(district.interact()).is_true()
	assert_bool(GameState.get_flag(&"st_aud_subway_entered")).is_true()
	district.cycle_water_level()
	assert_bool(district.interact()).is_false()
	assert_bool(GameState.get_flag(&"st_aud_subway_entered")).is_true()


func test_the_move_actions_drive_the_player() -> void:
	var runner: GdUnitSceneRunner = scene_runner(SCENE)
	var district: DistrictController = runner.scene()
	var player: PlayerController = district.player
	var start: Vector2 = player.motor.position
	Input.action_press(&"move_right")
	await runner.simulate_frames(20, 20)
	Input.action_release(&"move_right")
	assert_float(player.motor.position.x - start.x).is_greater(8.0)
	assert_float(player.motor.position.y).is_equal(start.y)
	assert_that(player.position).is_equal(player.motor.position)
	assert_array(GameState.player["cell"]).is_equal([player.motor.cell.x, player.motor.cell.y])


func _assert_water_matches_terrain(district: DistrictController) -> void:
	var height: int = district.water_height()
	var mismatches: Array = []
	for y: int in district.grid.size.y:
		for x: int in district.grid.size.x:
			var cell: Vector2i = Vector2i(x, y)
			var expected: Vector2i = NO_TILE
			match district.terrain.cell_kind(cell, height):
				TerrainQuery.CellKind.SHALLOW:
					expected = GreyboxTiles.WATER_SHALLOW
				TerrainQuery.CellKind.DEEP:
					expected = GreyboxTiles.WATER_DEEP
			if district.water_layer.get_cell_atlas_coords(cell) != expected:
				mismatches.append(cell)
	assert_array(mismatches).override_failure_message("water tiles wrong at %d cells, e.g. %s" % [mismatches.size(), mismatches.slice(0, 5)]).is_empty()
