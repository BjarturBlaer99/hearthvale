extends GdUnitTestSuite
## Dungeon rules: rooms on a grid for the camera, and the flags and door rules of DungeonState.

const ROOM: Vector2i = Vector2i(15, 11)


func test_cells_belong_to_rooms_on_a_grid() -> void:
	assert_that(RoomGrid.room_of(Vector2i(0, 0), ROOM)).is_equal(Vector2i(0, 0))
	assert_that(RoomGrid.room_of(Vector2i(14, 10), ROOM)).is_equal(Vector2i(0, 0))
	assert_that(RoomGrid.room_of(Vector2i(7, 11), ROOM)).is_equal(Vector2i(0, 1))
	assert_that(RoomGrid.room_of(Vector2i(15, 32), ROOM)).is_equal(Vector2i(1, 2))
	assert_that(RoomGrid.room_of(Vector2i(40, 40), Vector2i.ZERO)).override_failure_message("no rooms: one room").is_equal(Vector2i.ZERO)


func test_the_camera_shows_the_room_around_a_cell() -> void:
	assert_that(RoomGrid.camera_rect(Vector2i(7, 25), ROOM, Vector2i(15, 33), 16)).is_equal(Rect2i(0, 352, 240, 176))
	assert_that(RoomGrid.camera_rect(Vector2i(7, 25), Vector2i.ZERO, Vector2i(48, 36), 16)).override_failure_message("no rooms: the whole area").is_equal(Rect2i(0, 0, 768, 576))


func test_dungeon_flags_are_named_per_dungeon() -> void:
	assert_str(String(DungeonState.keys_flag(&"keep"))).is_equal("dungeon/keep/keys")
	assert_str(String(DungeonState.big_key_flag(&"keep"))).is_equal("dungeon/keep/big_key")
	assert_str(String(DungeonState.door_flag(&"keep", &"hall"))).is_equal("dungeon/keep/door/hall")
	assert_str(String(DungeonState.chest_flag(&"keep", &"c1"))).is_equal("dungeon/keep/chest/c1")
	assert_str(String(DungeonState.keys_flag(&"cellar"))).override_failure_message("keys belong to their dungeon").is_not_equal(String(DungeonState.keys_flag(&"keep")))


func test_locked_doors_need_a_small_key_and_boss_doors_the_big_key() -> void:
	assert_bool(DungeonState.can_unlock(DungeonState.LOCKED, 0, true)).is_false()
	assert_bool(DungeonState.can_unlock(DungeonState.LOCKED, 1, false)).is_true()
	assert_bool(DungeonState.can_unlock(DungeonState.BOSS, 3, false)).override_failure_message("small keys don't open it").is_false()
	assert_bool(DungeonState.can_unlock(DungeonState.BOSS, 0, true)).is_true()
	assert_bool(DungeonState.can_unlock(DungeonState.SHUTTER, 9, true)).override_failure_message("shutters only open on their flag").is_false()
	assert_int(DungeonState.key_cost(DungeonState.LOCKED)).is_equal(1)
	assert_int(DungeonState.key_cost(DungeonState.BOSS)).override_failure_message("the big key isn't spent").is_equal(0)
