extends GdUnitTestSuite
## PuzzleRules: when a block can be pushed, when a plate is pressed, and when a shutter waiting
## on several flags opens.


func test_a_block_slides_only_onto_open_floor_at_its_level() -> void:
	assert_bool(_push("0 0 0", Vector2i.RIGHT)).override_failure_message("open floor").is_true()
	assert_bool(_push("0 0s", Vector2i.RIGHT)).override_failure_message("a solid tile").is_false()
	assert_bool(_push("0 1", Vector2i.RIGHT)).override_failure_message("up a level").is_false()
	assert_bool(_push("1 0", Vector2i.RIGHT)).override_failure_message("off a ledge").is_false()
	assert_bool(_push("0 0r", Vector2i.RIGHT)).override_failure_message("onto stairs").is_false()
	assert_bool(_push("0 0", Vector2i(1, 1))).override_failure_message("never diagonally").is_false()
	var terrain: TerrainQuery = _terrain(["0 0 0"])
	terrain.set_occupied(Vector2i(1, 0))
	assert_bool(PuzzleRules.can_push(terrain, Vector2i(0, 0), Vector2i.RIGHT)).override_failure_message("something in the way").is_false()


func test_a_block_never_reaches_a_rooms_border() -> void:
	var rows: Array = []
	for y: int in 5:
		rows.append("0 0 0 0 0")
	var terrain: TerrainQuery = _terrain(rows)
	var room: Vector2i = Vector2i(5, 5)
	assert_bool(PuzzleRules.can_push(terrain, Vector2i(2, 2), Vector2i.UP, room)).is_true()
	assert_bool(PuzzleRules.can_push(terrain, Vector2i(2, 1), Vector2i.UP, room)).override_failure_message("the wall ring, where doorways are").is_false()
	assert_bool(PuzzleRules.on_room_border(Vector2i(14, 5), Vector2i(15, 11))).is_true()
	assert_bool(PuzzleRules.on_room_border(Vector2i(15, 5), Vector2i(15, 11))).override_failure_message("the next room's west wall").is_true()
	assert_bool(PuzzleRules.on_room_border(Vector2i(7, 5), Vector2i(15, 11))).is_false()
	assert_bool(PuzzleRules.on_room_border(Vector2i(0, 0), Vector2i.ZERO)).override_failure_message("no rooms, no borders").is_false()


func test_plates_are_pressed_by_the_hero_or_a_block() -> void:
	var plate: Vector2i = Vector2i(3, 3)
	assert_bool(PuzzleRules.plate_pressed(plate, plate, [])).is_true()
	assert_bool(PuzzleRules.plate_pressed(plate, Vector2i(0, 0), [Vector2i(3, 3)])).is_true()
	assert_bool(PuzzleRules.plate_pressed(plate, Vector2i(0, 0), [Vector2i(2, 3)])).is_false()


func test_shutters_open_on_any_flag_or_all_of_them() -> void:
	assert_bool(PuzzleRules.shutter_open([false, true], false)).is_true()
	assert_bool(PuzzleRules.shutter_open([false, false], false)).is_false()
	assert_bool(PuzzleRules.shutter_open([true, true], true)).is_true()
	assert_bool(PuzzleRules.shutter_open([true, false], true)).is_false()
	assert_bool(PuzzleRules.shutter_open([], false)).override_failure_message("no flags, no opening").is_false()


func _push(row: String, direction: Vector2i) -> bool:
	return PuzzleRules.can_push(_terrain([row]), Vector2i(0, 0), direction)


func _terrain(rows: Array) -> TerrainQuery:
	return TerrainQuery.new(HeightGrid.from_rows(PackedStringArray(rows)))


func test_a_block_sinks_into_a_pit_beside_it_but_never_slides_over_one() -> void:
	var terrain: TerrainQuery = _terrain(["0 0 0 0"])
	terrain.set_pit(Vector2i(1, 0))
	assert_bool(PuzzleRules.can_sink(terrain, Vector2i(0, 0), Vector2i.RIGHT)).is_true()
	assert_bool(PuzzleRules.can_push(terrain, Vector2i(0, 0), Vector2i.RIGHT)).override_failure_message("a pit isn't floor to slide onto").is_false()
	assert_bool(PuzzleRules.can_sink(terrain, Vector2i(3, 0), Vector2i.LEFT)).override_failure_message("plain floor: nothing to sink into").is_false()
	assert_bool(PuzzleRules.can_sink(terrain, Vector2i(0, 0), Vector2i(1, 1))).override_failure_message("straight pushes only").is_false()
	terrain.set_pit(Vector2i(1, 0), false)
	assert_bool(PuzzleRules.can_sink(terrain, Vector2i(0, 0), Vector2i.RIGHT)).override_failure_message("a filled pit takes no second block").is_false()
	assert_bool(PuzzleRules.can_push(terrain, Vector2i(0, 0), Vector2i.RIGHT)).override_failure_message("it's floor now").is_true()


func test_a_block_never_sinks_on_a_rooms_border_or_off_its_level() -> void:
	var terrain: TerrainQuery = _terrain(["0 0 0 0 0"])
	terrain.set_pit(Vector2i(4, 0))
	assert_bool(PuzzleRules.can_sink(terrain, Vector2i(3, 0), Vector2i.RIGHT, Vector2i(5, 1))).override_failure_message("the pit is in the room's wall ring").is_false()
	var stepped: TerrainQuery = _terrain(["1 0"])
	stepped.set_pit(Vector2i(1, 0))
	assert_bool(PuzzleRules.can_sink(stepped, Vector2i(0, 0), Vector2i.RIGHT)).override_failure_message("a pit below a ledge").is_false()


func test_a_torch_burns_for_its_burn_time_or_for_good() -> void:
	assert_bool(PuzzleRules.torch_burning(1000.0, 0.0)).override_failure_message("no burn time: for good").is_true()
	assert_bool(PuzzleRules.torch_burning(4.9, 5.0)).is_true()
	assert_bool(PuzzleRules.torch_burning(5.0, 5.0)).is_false()
