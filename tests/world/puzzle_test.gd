extends GdUnitTestSuite
## Puzzles (H6) in the Cistern, down the stairs in the Ruin Cellar: one room per mechanic (push
## block, pressure plate, crystal switch, cracked wall), and a combined room whose treasure
## shutter opens two ways: a block pushed onto a plate, or an arrow into a crystal the sword
## can't reach.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const CISTERN: String = "res://world/areas/cistern/cistern.tscn"
const CELLAR: String = "res://world/areas/ruin_cellar/ruin_cellar.tscn"
const FRAME: float = 1.0 / 60.0
const SIDES: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

var _area: Node


func before_test() -> void:
	GameState.clear()
	GameState.new_game()


func after_test() -> void:
	if is_instance_valid(_area):
		_area.free()
	_area = null
	GameState.clear()


func test_the_cistern_is_down_the_stairs_in_the_cellar() -> void:
	GameState.go_to(&"ruin_cellar", &"cistern_stairs")
	var cellar: AreaController = _load(CELLAR)
	var below: Vector2i = cellar.player.motor.cell
	var cistern: AreaController = _load(Steps.walk_until_travel(cellar, Vector2.UP))
	assert_str(cistern.area_name).is_equal("The Cistern")
	assert_that(cistern.current_room).is_equal(Vector2i(0, 2))
	cellar = _load(Steps.walk_until_travel(cistern, Vector2.DOWN))
	assert_that(cellar.player.motor.cell).is_equal(below)


func test_push_room_a_block_slides_out_of_the_way() -> void:
	var cistern: AreaController = _load(CISTERN)
	var block: PushBlock = cistern.interactables.get_node(^"PushRoomBlock")
	var start: Vector2i = Vector2i(4, 27)
	var plate_room: Vector2i = Vector2i(7, 20)
	_face(cistern, start, Vector2.UP)
	assert_bool(_reachable(cistern, start).has(plate_room)).override_failure_message("the block bars the way").is_false()
	_hold(cistern, Vector2.UP, 0.25)
	assert_that(block.cell()).override_failure_message("a tap doesn't push").is_equal(Vector2i(4, 26))
	_hold(cistern, Vector2.UP, 2.5)
	assert_that(block.cell()).override_failure_message("pushed north until the room's edge stops it").is_equal(Vector2i(4, 23))
	assert_bool(cistern.terrain.is_occupied(Vector2i(4, 26))).is_false()
	assert_bool(cistern.terrain.is_occupied(Vector2i(4, 23))).is_true()
	assert_bool(_reachable(cistern, cistern.player.motor.cell).has(plate_room)).override_failure_message("the way north is open").is_true()


func test_plate_room_a_latching_plate_lifts_the_shutter() -> void:
	var cistern: AreaController = _load(CISTERN)
	var shutter: DungeonDoor = cistern.interactables.get_node(^"PlateRoomShutter")
	assert_bool(shutter.is_open()).is_false()
	assert_bool(cistern.terrain.is_occupied(Vector2i(14, 16))).is_true()
	cistern.player.motor.place(Vector2i(2, 13))
	cistern.update_plates()
	assert_bool(shutter.is_open()).is_true()
	assert_bool(cistern.terrain.is_occupied(Vector2i(14, 16))).is_false()
	cistern.player.motor.place(Vector2i(6, 15))
	cistern.update_plates()
	assert_bool(shutter.is_open()).override_failure_message("the plate latches").is_true()


func test_switch_room_the_crystal_answers_the_sword_or_an_arrow() -> void:
	GameState.add_item(&"wooden_sword")
	GameState.add_item(&"bow")
	GameState.add_item(&"arrow", 5)
	var cistern: AreaController = _load(CISTERN)
	var crystal: CrystalSwitch = cistern.interactables.get_node(^"SwitchRoomSwitch")
	var shutter: DungeonDoor = cistern.interactables.get_node(^"SwitchRoomShutter")
	_face(cistern, Vector2i(22, 16), Vector2.UP)
	cistern.player.swing()
	_play(cistern, Vector2.ZERO, 0.4)
	assert_bool(crystal.is_on()).override_failure_message("the sword").is_true()
	assert_bool(shutter.is_open()).is_true()

	GameState.set_flag(&"cistern_c_switch", false)
	# After a hit the crystal ignores hits for a moment (one swing, one change); let it pass.
	crystal._process(CrystalSwitch.LOCKOUT + 0.01)
	assert_bool(shutter.is_open()).is_false()
	assert_bool(cistern.terrain.is_occupied(Vector2i(22, 11))).override_failure_message("the shutter drops again").is_true()
	_face(cistern, Vector2i(22, 19), Vector2.UP)
	assert_bool(cistern.use_item()).is_true()
	_play(cistern, Vector2.ZERO, 0.6)
	assert_bool(crystal.is_on()).override_failure_message("an arrow").is_true()
	assert_bool(shutter.is_open()).is_true()


func test_cracked_wall_room_only_a_bomb_breaks_it() -> void:
	GameState.add_item(&"wooden_sword")
	GameState.add_item(&"bomb", 1)
	var cistern: AreaController = _load(CISTERN)
	var wall: DungeonDoor = cistern.interactables.get_node(^"CrackedWall")
	assert_bool(cistern.terrain.is_occupied(Vector2i(15, 5))).is_true()
	_face(cistern, Vector2i(16, 5), Vector2.LEFT)
	cistern.player.swing()
	_play(cistern, Vector2.ZERO, 0.4)
	assert_bool(wall.is_open()).override_failure_message("a sword doesn't break it").is_false()
	assert_bool(cistern.use_item()).is_true()
	_play(cistern, Vector2.ZERO, 2.5)
	assert_bool(wall.is_open()).override_failure_message("a bomb does").is_true()
	assert_bool(cistern.terrain.is_occupied(Vector2i(15, 5))).is_false()
	assert_bool(cistern.terrain.is_occupied(Vector2i(14, 5))).is_false()
	assert_int(GameState.health).override_failure_message("the hero's own bomb spares them").is_equal(GameState.max_health())
	cistern = _load(CISTERN)
	assert_bool((cistern.interactables.get_node(^"CrackedWall") as DungeonDoor).is_open()).override_failure_message("it stays broken").is_true()


func test_combined_room_a_block_on_the_plate_opens_the_treasure() -> void:
	var cistern: AreaController = _load(CISTERN)
	var block: PushBlock = cistern.interactables.get_node(^"CombinedBlock")
	var plate: PressurePlate = cistern.interactables.get_node(^"CombinedPlate")
	var shutter: DungeonDoor = cistern.interactables.get_node(^"TreasureShutter")
	_face(cistern, Vector2i(7, 8), Vector2.LEFT)
	for i: int in roundi(3.0 / FRAME):
		_hold(cistern, Vector2.LEFT, FRAME)
		if block.cell() == plate.cell():
			break
	cistern.update_plates()
	assert_that(block.cell()).is_equal(plate.cell())
	assert_bool(shutter.is_open()).override_failure_message("solution one: a block on the plate").is_true()
	assert_bool(cistern.terrain.is_occupied(Vector2i(2, 4))).is_false()
	# The plate doesn't latch: push the block off (the hero, following it, now stands on the
	# plate and keeps it down), step away, and the shutter drops.
	_hold(cistern, Vector2.LEFT, 0.8)
	assert_that(block.cell()).is_not_equal(plate.cell())
	cistern.player.motor.place(Vector2i(8, 8))
	cistern.update_plates()
	assert_bool(shutter.is_open()).override_failure_message("it needs holding down").is_false()


func test_combined_room_an_arrow_into_the_high_crystal_opens_the_treasure() -> void:
	GameState.add_item(&"wooden_sword")
	GameState.add_item(&"bow")
	GameState.add_item(&"arrow", 5)
	var cistern: AreaController = _load(CISTERN)
	var crystal: CrystalSwitch = cistern.interactables.get_node(^"CombinedSwitch")
	var shutter: DungeonDoor = cistern.interactables.get_node(^"TreasureShutter")
	_face(cistern, Vector2i(11, 5), Vector2.UP)
	assert_bool(cistern.terrain.check_move(Vector2i(11, 5), Vector2i(11, 4)).is_allowed()).override_failure_message("no way up the platform").is_false()
	cistern.player.swing()
	_play(cistern, Vector2.ZERO, 0.4)
	assert_bool(crystal.is_on()).override_failure_message("out of the sword's reach").is_false()
	assert_bool(cistern.use_item()).is_true()
	_play(cistern, Vector2.ZERO, 0.6)
	assert_bool(crystal.is_on()).is_true()
	assert_bool(shutter.is_open()).override_failure_message("solution two: an arrow").is_true()
	_face(cistern, Vector2i(2, 3), Vector2.UP)
	assert_bool(cistern.interact()).is_true()
	assert_int(GameState.item_count(&"coin")).override_failure_message("the treasure").is_equal(30)


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area


func _face(area: AreaController, cell: Vector2i, direction: Vector2) -> void:
	area.player.motor.place(cell)
	area.player.face(direction)
	area.update_room()


## Holds a direction for `seconds`: the hero walks (and pushes), plates update.
func _hold(area: AreaController, direction: Vector2, seconds: float) -> void:
	for i: int in maxi(roundi(seconds / FRAME), 1):
		area.player.motor.step(direction, FRAME)
		area.player.sync_from_motor()
		area.update_pushing(FRAME)
		area.update_plates()


## Plays `seconds` frame by frame: the hero steps, arrows fly, bombs burn, hits land.
func _play(area: AreaController, input: Vector2, seconds: float) -> void:
	for i: int in roundi(seconds / FRAME):
		area.player.motor.step(input, FRAME)
		area.player.sync_from_motor()
		for child: Node in area.interactables.get_children():
			if child is Arrow:
				(child as Arrow).fly(FRAME)
			elif child is Bomb:
				(child as Bomb).tick(FRAME)
		area.resolve_combat()


## Every cell the hero could walk to from `start` right now (doors and blocks in the way).
func _reachable(area: AreaController, start: Vector2i) -> Dictionary:
	var seen: Dictionary = {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_back()
		for side: Vector2i in SIDES:
			var next: Vector2i = cell + side
			if not seen.has(next) and area.terrain.check_move(cell, next).is_allowed():
				seen[next] = true
				queue.append(next)
	return seen
