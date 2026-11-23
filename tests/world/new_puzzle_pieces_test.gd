extends GdUnitTestSuite
## The three new puzzle pieces (dungeon-difficulty-plan.md, decisions 13 to 15), set into the
## cistern's secret room for the test, since no dungeon uses them yet: crystals that turn back,
## plates pressed in an order, and a shutter that opens when its flag is off.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const CISTERN: String = "res://world/areas/cistern/cistern.tscn"
## Open floor in the cistern's secret room (16..28, 23..31; pillars at its four inner corners).
const FLOOR: Array[Vector2i] = [Vector2i(20, 27), Vector2i(22, 27), Vector2i(24, 27), Vector2i(22, 30)]
const ORDER_FLAG: StringName = &"test_order"
const TOGGLE_FLAG: StringName = &"test_toggle"

var _area: AreaController


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	_area = Steps.load_area(CISTERN, null)


func after_test() -> void:
	if is_instance_valid(_area):
		_area.free()
	_area = null
	GameState.clear()


func test_a_crystal_that_turns_back_is_blue_for_its_time_and_blinks_before() -> void:
	var crystal: CrystalSwitch = _crystal(&"test_a", FLOOR[0], 4.0)
	_hit(crystal)
	assert_bool(crystal.is_on()).is_true()
	crystal._process(2.9)
	assert_bool(crystal.is_warning()).is_false()
	crystal._process(0.2)
	assert_bool(crystal.is_warning()).override_failure_message("its last second").is_true()
	assert_bool(crystal.is_on()).is_true()
	crystal._process(1.0)
	assert_bool(crystal.is_on()).override_failure_message("red again").is_false()
	# Hit again, it is blue for its whole time anew.
	_hit(crystal)
	crystal._process(3.5)
	_hit(crystal)
	crystal._process(3.5)
	assert_bool(crystal.is_on()).is_true()


func test_a_crystal_that_turns_back_starts_every_visit_red() -> void:
	GameState.set_flag(&"test_a", true)
	var crystal: CrystalSwitch = _crystal(&"test_a", FLOOR[0], 4.0)
	assert_bool(crystal.is_on()).is_false()
	# One that doesn't turn back keeps what the save says.
	GameState.set_flag(&"test_b", true)
	assert_bool(_crystal(&"test_b", FLOOR[1], 0.0).is_on()).is_true()


func test_two_crystals_that_turn_back_must_be_blue_at_once() -> void:
	var a: CrystalSwitch = _crystal(&"test_a", FLOOR[0], 4.0)
	var b: CrystalSwitch = _crystal(&"test_b", FLOOR[2], 4.0)
	var shutter: DungeonDoor = _shutter([&"test_a", &"test_b"], false, FLOOR[3])
	_hit(a)
	a._process(4.1)
	_hit(b)
	assert_bool(shutter.is_open()).override_failure_message("too slow: the first has turned back").is_false()
	b._process(CrystalSwitch.LOCKOUT + 0.01)
	_hit(a)
	assert_bool(shutter.is_open()).override_failure_message("both blue at once").is_true()
	# It stays open for good once lifted, after both have turned back.
	a._process(4.1)
	b._process(4.1)
	assert_bool(a.is_on() or b.is_on()).is_false()
	assert_bool(shutter.is_open()).is_true()


func test_plates_in_an_order_open_only_when_pressed_in_turn() -> void:
	# Plate 1 at FLOOR[2], 2 at FLOOR[0], 3 at FLOOR[1]: the order is not where they lie.
	var plates: Array[PressurePlate] = [_plate(FLOOR[2], 1), _plate(FLOOR[0], 2), _plate(FLOOR[1], 3)]
	var shutter: DungeonDoor = _shutter([ORDER_FLAG], false, FLOOR[3])
	var sounds: Array[StringName] = []
	var hear: Callable = func(id: StringName) -> void: sounds.append(id)
	EventBus.sound.connect(hear)
	_stand(FLOOR[2])
	_stand(FLOOR[1])
	assert_bool(plates[0].pressed).override_failure_message("out of turn: the first rises again").is_false()
	assert_bool(plates[2].pressed).is_false()
	assert_bool(sounds.has(&"nope")).is_true()
	_stand(FLOOR[2])
	_stand(FLOOR[0])
	assert_bool(plates[0].pressed and plates[1].pressed).override_failure_message("two counted, both down").is_true()
	assert_bool(plates[2].pressed).is_false()
	assert_bool(shutter.is_open()).is_false()
	_stand(FLOOR[1])
	EventBus.sound.disconnect(hear)
	assert_bool(GameState.get_flag(ORDER_FLAG) == true).is_true()
	assert_bool(shutter.is_open()).is_true()
	# Solved, every plate stays down, whoever walks over them.
	_stand(FLOOR[3])
	for plate: PressurePlate in plates:
		assert_bool(plate.pressed).is_true()


func test_plates_in_an_order_start_over_when_he_leaves_the_room() -> void:
	var plates: Array[PressurePlate] = [_plate(FLOOR[0], 1), _plate(FLOOR[1], 2)]
	_area.player.motor.place(Vector2i(22, 25))
	_area.update_room()
	assert_that(_area.current_room).is_equal(Vector2i(1, 2))
	_stand(FLOOR[0])
	assert_bool(plates[0].pressed).is_true()
	_area.player.motor.place(Vector2i(7, 29))
	_area.update_room()
	assert_bool(plates[0].pressed).override_failure_message("another room: it starts over").is_false()
	assert_int(_area.plate_orders.set_of(ORDER_FLAG).progress).is_equal(0)


func test_plates_in_an_order_already_solved_show_down() -> void:
	GameState.set_flag(ORDER_FLAG, true)
	var plates: Array[PressurePlate] = [_plate(FLOOR[0], 1), _plate(FLOOR[1], 2)]
	_stand(FLOOR[3])
	for plate: PressurePlate in plates:
		assert_bool(plate.pressed).is_true()


func test_a_shutter_that_opens_when_off_answers_a_toggling_crystal() -> void:
	var crystal: CrystalSwitch = _crystal(TOGGLE_FLAG, FLOOR[0], 0.0)
	crystal.toggles = true
	var red_way: DungeonDoor = _shutter([TOGGLE_FLAG], true, FLOOR[1])
	red_way.stays_open = true
	var blue_way: DungeonDoor = _shutter([TOGGLE_FLAG], false, FLOOR[2])
	blue_way.stays_open = false
	assert_bool(red_way.is_open()).override_failure_message("red: the red way is open").is_true()
	assert_bool(blue_way.is_open()).is_false()
	_hit(crystal)
	assert_bool(red_way.is_open()).override_failure_message("blue: it shuts, though it was told to stay open").is_false()
	assert_bool(blue_way.is_open()).is_true()
	assert_bool(_area.terrain.is_occupied(FLOOR[1])).override_failure_message("its cell is barred").is_true()
	crystal._process(CrystalSwitch.LOCKOUT + 0.01)
	_hit(crystal)
	assert_bool(red_way.is_open()).is_true()
	assert_bool(blue_way.is_open()).is_false()


func _crystal(flag: StringName, cell: Vector2i, hold_time: float) -> CrystalSwitch:
	var crystal: CrystalSwitch = CrystalSwitch.new()
	crystal.flag = flag
	crystal.hold_time = hold_time
	crystal.position = Vector2(cell * GridBody.TILE)
	_area.interactables.add_child(crystal)
	return crystal


func _plate(cell: Vector2i, order: int) -> PressurePlate:
	var plate: PressurePlate = PressurePlate.new()
	plate.flag = ORDER_FLAG
	plate.order = order
	plate.position = Vector2(cell * GridBody.TILE)
	_area.interactables.add_child(plate)
	return plate


func _shutter(flags: Array[StringName], when_off: bool, cell: Vector2i) -> DungeonDoor:
	var door: DungeonDoor = DungeonDoor.new()
	door.kind = DungeonState.SHUTTER
	door.door_id = StringName("test_%d_%d" % [cell.x, cell.y])
	door.size = Vector2i(1, 1)
	door.open_flags = flags
	door.needs_all = true
	door.stays_open = true
	door.opens_when_off = when_off
	door.position = Vector2(cell * GridBody.TILE)
	_area.interactables.add_child(door)
	door.set_dungeon(&"cistern")
	return door


func _hit(crystal: CrystalSwitch) -> void:
	crystal._on_hit(Hit.new(1, Vector2.ZERO, Vector2.ZERO, &"sword"))


## The hero steps onto `cell` (off whatever he stood on), and the plates are checked.
func _stand(cell: Vector2i) -> void:
	_area.player.motor.place(Vector2i(22, 25))
	_area.update_plates()
	_area.player.motor.place(cell)
	_area.update_plates()
