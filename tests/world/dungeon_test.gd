extends GdUnitTestSuite
## The dungeon framework (H5) in the Ruin Cellar, the three-room test dungeon under the South
## Field ruin: the camera shows one room at a time; a small key from the entry hall's chest is
## needed to get further; opened doors and chests are remembered after leaving (and through a
## save); beating the hall's slimes lifts the shutter; and the boss door needs the big key.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const CELLAR: String = "res://world/areas/ruin_cellar/ruin_cellar.tscn"
const FIELD: String = "res://world/areas/south_field/south_field.tscn"
const FRAME: float = 1.0 / 60.0
## Rooms (RoomGrid coordinates): the inner room, the hall, the entry hall.
const INNER: Vector2i = Vector2i(0, 0)
const HALL: Vector2i = Vector2i(0, 1)
const ENTRY: Vector2i = Vector2i(0, 2)
## Just south of the locked door, and of the boss door.
const BELOW_HALL_DOOR: Vector2i = Vector2i(7, 23)
const BELOW_BOSS_DOOR: Vector2i = Vector2i(7, 12)

var _area: Node


func before_test() -> void:
	GameState.clear()
	GameState.new_game()


func after_test() -> void:
	if is_instance_valid(_area):
		_area.free()
	_area = null
	GameState.clear()


func test_the_cellar_is_down_the_stairs_in_the_ruin_and_back() -> void:
	GameState.go_to(&"south_field", &"cellar_stairs")
	var field: AreaController = _load(FIELD)
	var outside: Vector2i = field.player.motor.cell
	var path: String = Steps.walk_until_travel(field, Vector2.UP)
	assert_str(path).is_equal(CELLAR)
	var cellar: AreaController = _load(path)
	assert_that(cellar.current_room).is_equal(ENTRY)
	assert_str(cellar.area_text()).is_equal("Ruin Cellar   Keys: 0")
	path = Steps.walk_until_travel(cellar, Vector2.DOWN)
	assert_str(path).is_equal(FIELD)
	field = _load(path)
	assert_that(field.player.motor.cell).is_equal(outside)


func test_the_camera_shows_one_room_at_a_time() -> void:
	GameState.set_flag(DungeonState.door_flag(&"ruin_cellar", &"hall_door"), true)
	var cellar: AreaController = _load(CELLAR)
	assert_that(cellar.player.camera_limits().get_center()).override_failure_message("the entry hall in the middle").is_equal(Vector2i(120, 440))
	assert_that(cellar.room_mask.room_rect).override_failure_message("everything else shaded").is_equal(Rect2(0, 352, 240, 176))
	cellar.player.motor.place(BELOW_HALL_DOOR)
	_walk_until_room(cellar, Vector2.UP, HALL)
	assert_that(cellar.current_room).is_equal(HALL)
	assert_that(cellar.player.camera_limits().get_center()).override_failure_message("now the hall").is_equal(Vector2i(120, 264))
	assert_that(cellar.room_mask.room_rect).is_equal(Rect2(0, 176, 240, 176))


func test_a_small_key_is_needed_to_get_further() -> void:
	var cellar: AreaController = _load(CELLAR)
	var door: DungeonDoor = cellar.interactables.get_node(^"HallDoor")
	_face(cellar, BELOW_HALL_DOOR, Vector2.UP)
	assert_object(cellar.usable_in_front()).is_same(door)
	assert_str(door.prompt()).is_equal("Locked door")
	assert_bool(cellar.interact()).override_failure_message("it says why").is_true()
	assert_bool(door.is_open()).is_false()
	_walk_until_room(cellar, Vector2.UP, HALL, 1.0)
	assert_that(cellar.current_room).override_failure_message("the locked door holds").is_equal(ENTRY)

	_face(cellar, Vector2i(11, 28), Vector2.UP)
	assert_str(str(cellar.usable_in_front().call(&"prompt"))).is_equal("Open the chest")
	assert_bool(cellar.interact()).is_true()
	assert_str(cellar.area_text()).is_equal("Ruin Cellar   Keys: 1")

	_face(cellar, BELOW_HALL_DOOR, Vector2.UP)
	assert_str(door.prompt()).is_equal("Unlock the door")
	assert_bool(cellar.interact()).is_true()
	assert_bool(door.is_open()).is_true()
	assert_str(cellar.area_text()).override_failure_message("the key is spent").is_equal("Ruin Cellar   Keys: 0")
	_walk_until_room(cellar, Vector2.UP, HALL)
	assert_that(cellar.current_room).override_failure_message("through to the hall").is_equal(HALL)


func test_opened_doors_and_chests_are_remembered_after_leaving() -> void:
	var cellar: AreaController = _load(CELLAR)
	_face(cellar, Vector2i(11, 28), Vector2.UP)
	cellar.interact()
	_face(cellar, BELOW_HALL_DOOR, Vector2.UP)
	cellar.interact()

	# Up the stairs, through a save and a load, and back down.
	cellar.player.motor.place(Vector2i(7, 31))
	var field: AreaController = _load(Steps.walk_until_travel(cellar, Vector2.DOWN))
	var saved: Variant = JSON.parse_string(JSON.stringify(GameState.to_dict()))
	GameState.clear()
	GameState.from_dict(saved)
	field = _area
	cellar = _load(Steps.walk_until_travel(field, Vector2.UP))

	var door: DungeonDoor = cellar.interactables.get_node(^"HallDoor")
	var chest: Chest = cellar.interactables.get_node(^"EntryChest")
	assert_bool(door.is_open()).override_failure_message("the door stays open").is_true()
	assert_bool(cellar.terrain.is_occupied(Vector2i(7, 22))).is_false()
	assert_bool(chest.opened()).override_failure_message("the chest stays open").is_true()
	assert_str(chest.prompt()).is_empty()
	assert_str(cellar.area_text()).override_failure_message("no second key from it").is_equal("Ruin Cellar   Keys: 0")


func test_beating_the_hall_slimes_lifts_the_shutter() -> void:
	var cellar: AreaController = _load(CELLAR)
	var shutter: DungeonDoor = cellar.interactables.get_node(^"AlcoveShutter")
	assert_bool(shutter.is_open()).is_false()
	assert_bool(cellar.terrain.is_occupied(Vector2i(4, 16))).is_true()
	_beat(cellar, "SlimeA")
	assert_bool(shutter.is_open()).override_failure_message("one slime still stands").is_false()
	_beat(cellar, "SlimeB")
	assert_bool(shutter.is_open()).is_true()
	assert_bool(cellar.terrain.is_occupied(Vector2i(4, 16))).override_failure_message("the way into the alcove is free").is_false()


func test_the_boss_door_needs_the_big_key() -> void:
	GameState.set_flag(DungeonState.keys_flag(&"ruin_cellar"), 3)
	var cellar: AreaController = _load(CELLAR)
	var boss_door: DungeonDoor = cellar.interactables.get_node(^"BossDoor")
	_face(cellar, BELOW_BOSS_DOOR, Vector2.UP)
	assert_str(boss_door.prompt()).is_equal("Boss door")
	cellar.interact()
	assert_bool(boss_door.is_open()).override_failure_message("small keys don't open it").is_false()

	_face(cellar, Vector2i(3, 16), Vector2.LEFT)
	assert_bool(cellar.interact()).is_true()
	assert_str(cellar.area_text()).is_equal("Ruin Cellar   Keys: 3   Big key")

	_face(cellar, BELOW_BOSS_DOOR, Vector2.UP)
	assert_str(boss_door.prompt()).is_equal("Open the boss door")
	cellar.interact()
	assert_bool(boss_door.is_open()).is_true()
	assert_str(cellar.area_text()).override_failure_message("the big key isn't spent, nor small keys").is_equal("Ruin Cellar   Keys: 3   Big key")
	_walk_until_room(cellar, Vector2.UP, INNER)
	assert_that(cellar.current_room).is_equal(INNER)
	_face(cellar, Vector2i(7, 5), Vector2.UP)
	cellar.interact()
	assert_int(GameState.item_count(&"coin")).override_failure_message("the inner room's chest").is_equal(20)


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area


func _face(area: AreaController, cell: Vector2i, direction: Vector2) -> void:
	area.player.motor.place(cell)
	area.player.face(direction)
	area.update_room()


## Walks one way until the hero is in `room` (or `seconds` run out).
func _walk_until_room(area: AreaController, direction: Vector2, room: Vector2i, seconds: float = 2.0) -> void:
	for i: int in roundi(seconds / FRAME):
		area.player.motor.step(direction, FRAME)
		area.player.sync_from_motor()
		if area.current_room == room:
			return


func _beat(area: AreaController, enemy_name: String) -> void:
	var enemy: Enemy = area.interactables.get_node(NodePath(enemy_name))
	enemy.hurt_box.receive(Hit.new(99, Vector2.ZERO, enemy.position))
