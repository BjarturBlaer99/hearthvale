extends GdUnitTestSuite
## Sailing between maps through the real scenes and controllers. Scene changes are stubbed:
## each test replaces `travel` and checks where it was asked to go and what GameState says.

const FRAME: float = 1.0 / 60.0

var _travelled: Array = []


func before_test() -> void:
	GameState.clear()
	_travelled.clear()


func after_test() -> void:
	GameState.clear()


# --- Inside a district -----------------------------------------------------

func test_a_new_game_starts_with_the_boat_at_st_auds_mooring() -> void:
	var district: DistrictController = await _district(&"st_aud")
	assert_bool(district.boat.present).is_true()
	assert_object(district.boat.rider).is_null()
	assert_that(district.boat.motor.cell).is_equal(Vector2i(1, 10))
	assert_that(GameState.boat_cell()).is_equal(Vector2i(1, 10))
	assert_that(str(GameState.boat["where"])).is_equal("st_aud")


func test_board_from_the_pier_and_go_ashore_again() -> void:
	var district: DistrictController = await _district(&"st_aud")
	district.player.motor.place(Vector2i(1, 9))
	assert_bool(district.can_board()).is_true()
	assert_bool(district.interact()).is_true()
	assert_object(district.boat.rider).is_same(district.player)
	assert_that(district.player.motor.state_name).is_equal(PlayerMotor.ON_BOAT)
	assert_bool(district.interact()).is_true()
	assert_that(district.player.motor.state_name).is_equal(PlayerMotor.GROUND)
	assert_that(district.player.motor.cell).is_equal(Vector2i(1, 9))
	assert_object(district.boat.rider).is_null()


func test_sailing_off_the_edge_heads_out_to_sea() -> void:
	var district: DistrictController = await _district(&"st_aud")
	district.player.motor.place(Vector2i(1, 9))
	district.board()
	_sail(district.boat, Vector2.LEFT, 3.0)
	assert_array(_travelled).is_equal([WorldPaths.SEA_SCENE])
	assert_that(str(GameState.player["district"])).is_equal("sea")
	assert_that(str(GameState.player["came_from"])).is_equal("st_aud")
	assert_bool(GameState.player["arriving"]).is_true()
	assert_that(str(GameState.boat["where"])).is_equal("sea")
	assert_that(GameState.boat_cell()).is_equal(GameState.NO_CELL)


func test_falling_water_moves_the_boat_to_the_nearest_deep_cell() -> void:
	var district: DistrictController = await _district(&"st_aud")
	district.player.motor.place(Vector2i(1, 9))
	district.board()
	district.boat.place(Vector2i(13, 17), 0.0)
	district.cycle_water_level()
	assert_that(GameState.get_water_level(&"st_aud")).is_equal(&"waist")
	assert_that(district.boat.motor.cell).is_equal(Vector2i(12, 17))
	assert_that(district.player.motor.cell).is_equal(Vector2i(12, 17))
	assert_that(district.player.motor.state_name).is_equal(PlayerMotor.ON_BOAT)


func test_with_no_deep_water_left_the_boat_waits_at_sea() -> void:
	var district: DistrictController = await _district(&"st_aud")
	district.player.motor.place(Vector2i(1, 9))
	district.board()
	district.cycle_water_level()
	assert_bool(district.boat.present).override_failure_message("still afloat at waist").is_true()
	district.cycle_water_level()
	assert_bool(district.boat.present).is_false()
	assert_that(district.player.motor.state_name).is_equal(PlayerMotor.GROUND)
	assert_that(district.player.motor.cell).is_equal(Vector2i(1, 10))
	assert_bool(district.boat_waiting_offshore()).is_true()
	# Walk out from the harbour to board it.
	assert_bool(district.can_walk_out_to_boat()).is_false()
	district.player.motor.place(district.harbour.cell())
	assert_bool(district.interact()).is_true()
	assert_array(_travelled).is_equal([WorldPaths.SEA_SCENE])
	assert_that(str(GameState.player["came_from"])).is_equal("st_aud")


# --- At sea ----------------------------------------------------------------

func test_out_at_sea_the_boat_appears_off_the_district_just_left() -> void:
	GameState.new_game()
	GameState.set_boat(WorldPaths.SEA_ID, GameState.NO_CELL, PI)
	GameState.begin_voyage(WorldPaths.SEA_ID, &"st_aud")
	var sea: SeaController = await _sea()
	assert_that(sea.boat.motor.cell).is_equal(sea.port_for(&"st_aud").exit_cell)
	assert_object(sea.boat.rider).is_same(sea.player)
	assert_bool(GameState.player["arriving"]).is_false()


func test_sailing_into_a_port_sets_course_for_that_district() -> void:
	GameState.new_game()
	GameState.set_boat(WorldPaths.SEA_ID, Vector2i(20, 22), PI)
	var sea: SeaController = await _sea()
	_sail(sea.boat, Vector2.LEFT, 3.0)
	assert_array(_travelled).is_equal([WorldPaths.scene_for(&"greenterrace")])
	assert_that(str(GameState.player["district"])).is_equal("greenterrace")
	assert_bool(GameState.player["arriving"]).is_true()
	assert_that(str(GameState.boat["moored_at"])).is_equal("greenterrace")
	assert_that(GameState.boat_cell()).is_equal(sea.port_for(&"greenterrace").exit_cell)


# --- Arriving --------------------------------------------------------------

func test_arriving_at_dry_greenterrace_you_come_ashore_and_the_boat_waits() -> void:
	_arrive_from_sea(&"greenterrace", &"dry")
	var district: DistrictController = await _district(&"greenterrace")
	assert_bool(district.boat.present).is_false()
	assert_that(district.player.motor.cell).is_equal(district.harbour.cell())
	assert_that(district.player.motor.state_name).is_equal(PlayerMotor.GROUND)
	assert_bool(district.boat_waiting_offshore()).is_true()
	assert_bool(district.walk_out_to_boat()).is_true()
	assert_array(_travelled).is_equal([WorldPaths.SEA_SCENE])
	assert_that(GameState.boat_cell()).is_equal(Vector2i(21, 22))


func test_arriving_at_flooded_greenterrace_you_sail_in() -> void:
	_arrive_from_sea(&"greenterrace", &"flooded")
	var district: DistrictController = await _district(&"greenterrace")
	assert_bool(district.boat.present).is_true()
	assert_that(district.boat.motor.cell).is_equal(Vector2i(1, 17))
	assert_that(district.player.motor.state_name).is_equal(PlayerMotor.ON_BOAT)
	assert_that(str(GameState.boat["where"])).is_equal("greenterrace")


func test_arriving_at_spire_nine_you_sail_in() -> void:
	_arrive_from_sea(&"spire_nine", &"sea")
	var district: DistrictController = await _district(&"spire_nine")
	assert_that(district.player.motor.state_name).is_equal(PlayerMotor.ON_BOAT)
	assert_bool(district.interact()).override_failure_message("go ashore on the dock").is_true()
	assert_that(district.player.motor.state_name).is_equal(PlayerMotor.GROUND)


# --- Helpers ---------------------------------------------------------------

func _district(district_id: StringName) -> DistrictController:
	var runner: GdUnitSceneRunner = scene_runner(WorldPaths.scene_for(district_id))
	await runner.simulate_frames(1)
	var district: DistrictController = runner.scene()
	district.travel = func(path: String) -> void: _travelled.append(path)
	return district


func _sea() -> SeaController:
	var runner: GdUnitSceneRunner = scene_runner(WorldPaths.SEA_SCENE)
	await runner.simulate_frames(1)
	var sea: SeaController = runner.scene()
	sea.travel = func(path: String) -> void: _travelled.append(path)
	return sea


## The state the sea leaves behind when it sends the boat to `district_id`.
func _arrive_from_sea(district_id: StringName, level: StringName) -> void:
	GameState.new_game()
	GameState.set_water_level(district_id, level)
	GameState.set_boat(WorldPaths.SEA_ID, Vector2i(21, 22), 0.0, district_id)
	GameState.begin_voyage(district_id, WorldPaths.SEA_ID)


## Steers the boat directly (no frames), stopping once a scene change has been asked for.
func _sail(boat: BoatController, input: Vector2, seconds: float) -> void:
	for i: int in roundi(seconds / FRAME):
		if not _travelled.is_empty():
			return
		boat.motor.step(input, FRAME)
		boat.sync_from_motor()
