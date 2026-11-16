extends GdUnitTestSuite
## The Old Keep (H7): ten rooms at the top of the Old Wood. A walkthrough finishes it start to
## end, checking every gate on the way (small keys, two-plate shutter, the Bow, crystals,
## archers on a walkway, the big key, the boss door), then the Iron Warden: blows clink until an
## arrow finds its eye, it takes several stuns, and beaten it leaves a heart container that
## adds a heart. Also: the Warden starts over when the hero leaves, lets arrows fall for an
## empty quiver, and stays beaten.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const KEEP: String = "res://world/areas/keep/keep.tscn"
const WOOD: String = "res://world/areas/old_wood/old_wood.tscn"
const FRAME: float = 1.0 / 60.0
const SIDES: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
## Cells inside each room, by name.
const ENTRANCE: Vector2i = Vector2i(22, 40)
const GUARD_ROOM: Vector2i = Vector2i(7, 38)
const STORE: Vector2i = Vector2i(37, 38)
const HALL: Vector2i = Vector2i(22, 27)
const PLATE_ROOM: Vector2i = Vector2i(7, 27)
const ARMOURY: Vector2i = Vector2i(7, 16)
const GALLERY: Vector2i = Vector2i(7, 7)
const TWIN_ROOM: Vector2i = Vector2i(36, 28)
const BIG_KEY_ROOM: Vector2i = Vector2i(37, 18)
const WARDENS_HALL: Vector2i = Vector2i(22, 18)

var _area: Node


func before_test() -> void:
	GameState.clear()
	GameState.new_game()


func after_test() -> void:
	if is_instance_valid(_area):
		_area.free()
	_area = null
	GameState.clear()


func test_the_keeps_gate_is_at_the_top_of_the_old_wood() -> void:
	# With Elder Bram's word: the gate is unchained (P4a; tests/world/story_days_test.gd).
	GameState.set_flag(StoryGates.KEEP_GATE, true)
	GameState.go_to(&"old_wood", &"keep_gate")
	var wood: AreaController = _load(WOOD)
	var gate: Vector2i = wood.player.motor.cell
	var keep: AreaController = _load(Steps.walk_until_travel(wood, Vector2.UP))
	assert_str(keep.area_name).is_equal("The Old Keep")
	assert_that(keep.current_room).is_equal(Vector2i(1, 3))
	wood = _load(Steps.walk_until_travel(keep, Vector2.DOWN))
	assert_that(wood.player.motor.cell).is_equal(gate)


func test_a_key_held_through_the_way_out_does_not_walk_him_back_in() -> void:
	# The way out behind the Warden's hall is taken going north, and sets him down a step south
	# of the keep's gate: the key still held would take him straight back in (the playtest of
	# 2026-11-16). It is not obeyed until it is let go.
	GameState.set_flag(StoryGates.KEEP_GATE, true)
	GameState.go_to(&"old_wood", &"keep_gate")
	var wood: AreaController = _load(WOOD)
	var travelled: Array[String] = []
	wood.travel = func(path: String) -> void: travelled.append(path)
	var gate: Vector2i = wood.player.motor.cell
	Input.action_press(&"move_up")
	for i: int in 60:
		wood.player._physics_process(FRAME)
	assert_array(travelled).is_empty()
	assert_that(wood.player.motor.cell).is_equal(gate)
	# Let go and pressed again, it is a new press: he goes in.
	Input.action_release(&"move_up")
	wood.player._physics_process(FRAME)
	Input.action_press(&"move_up")
	for i: int in 60:
		wood.player._physics_process(FRAME)
	Input.action_release(&"move_up")
	assert_array(travelled).has_size(1)


func test_a_key_held_the_way_he_comes_out_keeps_him_walking() -> void:
	GameState.set_flag(StoryGates.KEEP_GATE, true)
	GameState.go_to(&"old_wood", &"keep_gate")
	var wood: AreaController = _load(WOOD)
	var gate: Vector2i = wood.player.motor.cell
	Input.action_press(&"move_down")
	for i: int in 30:
		wood.player._physics_process(FRAME)
	Input.action_release(&"move_down")
	assert_int(wood.player.motor.cell.y).is_greater(gate.y)


func test_a_loaded_game_holds_no_key_back() -> void:
	GameState.set_flag(StoryGates.KEEP_GATE, true)
	GameState.update_player(&"old_wood", Vector2i(18, 6))
	var wood: AreaController = _load(WOOD)
	assert_that(wood.player.held_back).is_equal(Vector2.ZERO)


func test_ten_rooms_all_joined_once_every_door_is_open() -> void:
	var keep: AreaController = _load(KEEP)
	var rooms: Array[Vector2i] = []
	for ry: int in 4:
		for rx: int in 3:
			var room: Vector2i = Vector2i(rx, ry)
			var origin: Vector2i = room * keep.room_size
			if not keep.grid.is_solid(origin + Vector2i(7, 5)) or not keep.grid.is_solid(origin + Vector2i(1, 1)):
				rooms.append(room)
	assert_int(rooms.size()).override_failure_message("8 to 12 rooms").is_equal(10)
	for door: DungeonDoor in keep.doors():
		GameState.set_flag(DungeonState.door_flag(&"keep", door.door_id), true)
		if door.open_flag != &"":
			GameState.set_flag(door.open_flag, true)
		for flag: StringName in door.open_flags:
			GameState.set_flag(flag, true)
	var reachable: Dictionary = _reachable(keep, ENTRANCE)
	for cell: Vector2i in [GUARD_ROOM, STORE, HALL, PLATE_ROOM, ARMOURY, GALLERY, TWIN_ROOM, BIG_KEY_ROOM, WARDENS_HALL]:
		assert_bool(reachable.has(cell)).override_failure_message("%s is joined to the rest" % cell).is_true()


func test_the_keep_can_be_finished_start_to_end() -> void:
	GameState.add_item(&"wooden_sword")
	GameState.go_to(&"keep", &"entrance")
	var keep: AreaController = _load(KEEP)
	assert_that(keep.player.motor.cell).is_equal(Vector2i(22, 42))

	# 1. The way north is locked; the guard room's alcove opens once its guards are beaten.
	assert_bool(_reachable(keep, ENTRANCE).has(HALL)).override_failure_message("the hall door is locked").is_false()
	assert_bool(_reachable(keep, ENTRANCE).has(GUARD_ROOM)).is_true()
	assert_bool(_reachable(keep, GUARD_ROOM).has(Vector2i(2, 36))).override_failure_message("the key's alcove is shut").is_false()
	_beat_all(keep, &"keep_guard_clear")
	_open(keep, Vector2i(2, 36), Vector2.UP)
	assert_int(_keys()).override_failure_message("small key 1").is_equal(1)
	_open(keep, Vector2i(22, 34), Vector2.UP)
	assert_int(_keys()).is_equal(0)
	assert_bool(_reachable(keep, ENTRANCE).has(HALL)).override_failure_message("into the great hall").is_true()

	# 2. In the hall the east door is locked and the boss door shut.
	_face(keep, Vector2i(28, 27), Vector2.RIGHT)
	keep.interact()
	_face(keep, Vector2i(22, 23), Vector2.UP)
	keep.interact()
	assert_bool(_reachable(keep, HALL).has(TWIN_ROOM)).is_false()
	assert_bool(_reachable(keep, HALL).has(WARDENS_HALL)).is_false()

	# 3. Plate room: one plate isn't enough; the hero on one and the block on the other is.
	var shutter: DungeonDoor = keep.interactables.get_node(^"PlateShutter")
	var block: PushBlock = keep.interactables.get_node(^"PlateBlock")
	_face(keep, Vector2i(3, 24), Vector2.UP)
	keep.update_plates()
	assert_bool(shutter.is_open()).override_failure_message("one plate").is_false()
	_push(keep, block, Vector2i(6, 28), Vector2.RIGHT, Vector2i(11, 28))
	_push(keep, block, Vector2i(11, 29), Vector2.UP, Vector2i(11, 24))
	_face(keep, Vector2i(3, 24), Vector2.UP)
	keep.update_plates()
	assert_bool(shutter.is_open()).override_failure_message("both plates at once").is_true()
	_face(keep, Vector2i(7, 26), Vector2.UP)
	keep.update_plates()
	assert_bool(shutter.is_open()).override_failure_message("solved, it stays open").is_true()

	# 4. Armoury: the Bow and arrows, tried on a crystal the sword can't reach. Leaving the
	# plate room put its block back; the shutter stays open.
	_face(keep, Vector2i(7, 19), Vector2.UP)
	assert_that(block.cell()).override_failure_message("the block went back").is_equal(Vector2i(7, 28))
	keep.update_plates()
	assert_bool(shutter.is_open()).is_true()
	_open(keep, Vector2i(3, 15), Vector2.UP)
	_open(keep, Vector2i(5, 15), Vector2.UP)
	assert_that(GameState.equipped).override_failure_message("the dungeon's item").is_equal(&"bow")
	assert_int(GameState.item_count(&"arrow")).is_equal(15)
	var crystal: CrystalSwitch = keep.interactables.get_node(^"ArmouryCrystal")
	_face(keep, Vector2i(11, 15), Vector2.UP)
	keep.player.swing()
	_play(keep, 0.4)
	assert_bool(crystal.is_on()).override_failure_message("out of sword reach").is_false()
	_shoot(keep, Vector2i(11, 15), Vector2.UP)
	assert_bool(crystal.is_on()).is_true()
	assert_bool(_reachable(keep, ARMOURY).has(GALLERY)).override_failure_message("into the gallery").is_true()

	# 5. Gallery: archers on a walkway nobody can climb; shot down, they open the key's alcove,
	# and what they drop falls to the floor.
	assert_bool(keep.terrain.check_move(Vector2i(4, 4), Vector2i(4, 3)).is_allowed()).override_failure_message("no way up").is_false()
	for archer_name: String in ["GalleryArcherA", "GalleryArcherB"]:
		var archer: Enemy = keep.interactables.get_node(NodePath(archer_name))
		archer.roll_drop = func() -> float: return 0.0
		_shoot_down(keep, archer)
		assert_bool(archer.is_dead()).override_failure_message("%s shot down" % archer_name).is_true()
		assert_int(GridBody.cell_of(archer.dropped.position).y).override_failure_message("its drop fell off the walkway").is_equal(4)
	_open(keep, Vector2i(11, 8), Vector2.RIGHT)
	assert_int(_keys()).override_failure_message("small key 2").is_equal(1)
	assert_bool(_reachable(keep, GALLERY).has(HALL)).override_failure_message("back down to the hall").is_true()

	# 6. Twin crystals: the sword for the low one, an arrow for the high one; both needed.
	_open(keep, Vector2i(28, 27), Vector2.RIGHT)
	assert_bool(_reachable(keep, HALL).has(TWIN_ROOM)).is_true()
	var twin: DungeonDoor = keep.interactables.get_node(^"TwinShutter")
	_face(keep, Vector2i(33, 25), Vector2.UP)
	keep.player.swing()
	_play(keep, 0.4)
	assert_bool((keep.interactables.get_node(^"TwinLow") as CrystalSwitch).is_on()).is_true()
	assert_bool(twin.is_open()).override_failure_message("one crystal").is_false()
	_shoot(keep, Vector2i(42, 26), Vector2.UP)
	assert_bool(twin.is_open()).override_failure_message("both crystals").is_true()

	# 7. Big key room: beat its guards, take the big key, open the boss door.
	_beat_all(keep, &"keep_bigkey_clear")
	_open(keep, Vector2i(37, 14), Vector2.UP)
	assert_bool(GameState.get_flag(DungeonState.big_key_flag(&"keep")) == true).is_true()
	_open(keep, Vector2i(22, 23), Vector2.UP)
	assert_bool(_reachable(keep, HALL).has(WARDENS_HALL)).override_failure_message("the boss door opens").is_true()

	# 8. The Iron Warden (its touch switched off: this is about the way through, not dodging).
	var warden: Boss = keep.interactables.get_node(^"Warden")
	var heart: HeartContainer = keep.interactables.get_node(^"HeartContainer")
	warden.hit_box.deactivate()
	assert_bool(heart.is_there()).is_false()
	_face(keep, Vector2i(22, 20), Vector2.UP)
	var stuns: int = 0
	for cycle: int in 8:
		_step_until(keep, warden, WardenBrain.GAZE, 8.0)
		warden.body.place(Vector2i(22, 16))
		warden.position = warden.body.position
		if cycle == 0:
			var before: int = warden.brain.health
			_face(keep, Vector2i(22, 17), Vector2.UP)
			keep.player.swing()
			_fight(keep, warden, 0.35)
			assert_int(warden.brain.health).override_failure_message("the sword clinks off").is_equal(before)
		_shoot(keep, Vector2i(22, 19), Vector2.UP)
		assert_bool(warden.warden.is_stunned()).override_failure_message("an arrow in its eye stuns it").is_true()
		stuns += 1
		_face(keep, Vector2i(22, 17), Vector2.UP)
		while warden.warden.is_stunned():
			keep.player.swing()
			_fight(keep, warden, 0.35)
		if warden.is_dead():
			break
	assert_bool(warden.is_dead()).override_failure_message("beaten").is_true()
	print("  keep: the Warden fell after %d stuns" % stuns)
	assert_int(stuns).override_failure_message("it takes more than one stun").is_greater_equal(2)
	assert_bool(GameState.get_flag(&"keep_warden_beaten") == true).is_true()

	# 9. A heart container appears; it adds a heart. Then the way out.
	assert_bool(heart.is_there()).is_true()
	assert_int(GameState.hearts_max).is_equal(3)
	GameState.damage(3)
	keep.player.motor.place(heart.cell())
	keep.player.sync_from_motor()
	assert_int(keep.collect_pickups()).is_equal(1)
	assert_int(GameState.hearts_max).override_failure_message("beating the boss adds a heart").is_equal(4)
	assert_int(GameState.health).override_failure_message("and fills them all").is_equal(8)
	assert_bool(keep.is_talking()).override_failure_message("the closing conversation opens").is_true()
	assert_str(keep.hud.dialogue.shown_text()).contains("Heart Container")
	keep.hud.dialogue.confirm()
	keep.hud.dialogue.confirm()
	_face(keep, Vector2i(22, 12), Vector2.UP)
	assert_str(Steps.walk_until_travel(keep, Vector2.UP)).override_failure_message("out to the Old Wood").is_equal(WOOD)


func test_the_warden_starts_over_when_the_hero_leaves_and_never_strands_an_empty_quiver() -> void:
	GameState.add_item(&"wooden_sword")
	GameState.add_item(&"bow")
	var keep: AreaController = _load(KEEP)
	var warden: Boss = keep.interactables.get_node(^"Warden")
	warden.hit_box.deactivate()
	_face(keep, Vector2i(22, 20), Vector2.UP)
	_step_until(keep, warden, WardenBrain.GAZE, 8.0)
	var help: ItemDrop = warden.arrow_help
	assert_object(help).override_failure_message("arrows fall for an empty quiver").is_not_null()
	assert_that(help.item_id).is_equal(&"arrow")
	assert_bool(Rect2i(warden.arena).has_point(GridBody.cell_of(help.position))).is_true()
	keep.player.motor.place(GridBody.cell_of(help.position))
	keep.player.sync_from_motor()
	keep.collect_pickups()
	assert_int(GameState.item_count(&"arrow")).is_equal(Boss.ARROW_HELP)

	# An unanswered gaze ends in a glowing bolt at the hero.
	_face(keep, Vector2i(22, 20), Vector2.UP)
	_step_until(keep, warden, WardenBrain.GUARD, 3.0)
	assert_object(warden.last_arrow).is_not_null()
	assert_bool(warden.last_arrow.bolt).is_true()
	assert_that(warden.last_arrow.hit_box.team).is_equal(&"enemy")

	# Stunned and hurt, then the hero walks out: it starts over.
	_step_until(keep, warden, WardenBrain.GAZE, 8.0)
	warden.body.place(Vector2i(22, 16))
	warden.position = warden.body.position
	_shoot(keep, Vector2i(22, 19), Vector2.UP)
	_face(keep, Vector2i(22, 17), Vector2.UP)
	keep.player.swing()
	_fight(keep, warden, 0.35)
	assert_int(warden.brain.health).is_less(warden.brain.max_health)
	_face(keep, Vector2i(22, 25), Vector2.UP)
	warden.step(FRAME)
	assert_int(warden.brain.health).override_failure_message("full health again").is_equal(warden.brain.max_health)
	assert_that(warden.brain.state).is_equal(EnemyBrain.IDLE)
	assert_that(warden.body.position).override_failure_message("back home").is_equal(warden.brain.home)


func test_beaten_the_warden_stays_beaten_and_its_heart_is_taken_once() -> void:
	GameState.set_flag(&"keep_warden_beaten", true)
	var keep: AreaController = _load(KEEP)
	var warden: Boss = keep.interactables.get_node(^"Warden")
	assert_bool(warden.is_queued_for_deletion()).override_failure_message("it doesn't come back").is_true()
	assert_bool((keep.interactables.get_node(^"ExitShutter") as DungeonDoor).is_open()).is_true()
	var heart: HeartContainer = keep.interactables.get_node(^"HeartContainer")
	keep.player.motor.place(heart.cell())
	keep.player.sync_from_motor()
	assert_int(keep.collect_pickups()).is_equal(1)
	assert_bool(keep.player.is_holding_up()).override_failure_message("the heart is held up").is_true()
	assert_int(keep.collect_pickups()).is_equal(0)
	keep = _load(KEEP)
	assert_bool((keep.interactables.get_node(^"HeartContainer") as HeartContainer).is_there()).override_failure_message("taken for good").is_false()
	assert_int(GameState.hearts_max).is_equal(4)


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area


func _keys() -> int:
	return int(GameState.get_flag(DungeonState.keys_flag(&"keep"), 0))


func _face(area: AreaController, cell: Vector2i, direction: Vector2) -> void:
	area.player.motor.place(cell)
	area.player.face(direction)
	area.update_room()


## Stands at `cell` facing `direction` and presses E (a chest, a door).
func _open(area: AreaController, cell: Vector2i, direction: Vector2) -> void:
	_face(area, cell, direction)
	assert_bool(area.interact()).override_failure_message("E at %s" % cell).is_true()


## Every enemy sharing `clear_flag` takes a blow it can't survive.
func _beat_all(area: AreaController, clear_flag: StringName) -> void:
	for enemy: Enemy in area.enemies():
		if enemy.clear_flag == clear_flag:
			enemy.hurt_box.receive(Hit.new(99, Vector2.ZERO, Vector2.ZERO, &"sword"))
	assert_bool(GameState.get_flag(clear_flag) == true).override_failure_message("%s set" % clear_flag).is_true()


## Shoots the bow from `cell` toward `direction` and lets the arrow fly.
func _shoot(area: AreaController, cell: Vector2i, direction: Vector2) -> void:
	_face(area, cell, direction)
	assert_bool(area.use_item()).override_failure_message("shoot from %s" % cell).is_true()
	_play(area, 0.6)


## Shoots an archer on the walkway from the floor below until it falls.
func _shoot_down(area: AreaController, archer: Enemy) -> void:
	var spot: Vector2i = archer.body.cell
	for i: int in 6:
		archer.body.place(spot)
		archer.position = archer.body.position
		_shoot(area, Vector2i(spot.x, 5), Vector2.UP)
		if archer.is_dead():
			return
		for frame: int in roundi(0.4 / FRAME):
			archer.step(FRAME)


## Holds `direction` from `from` until `block` reaches `target`.
func _push(area: AreaController, block: PushBlock, from: Vector2i, direction: Vector2, target: Vector2i) -> void:
	_face(area, from, direction)
	for i: int in roundi(6.0 / FRAME):
		area.player.motor.step(direction, FRAME)
		area.player.sync_from_motor()
		area.update_pushing(FRAME)
		area.update_plates()
		if block.cell() == target:
			return
	assert_that(block.cell()).override_failure_message("pushed to %s" % target).is_equal(target)


## Plays `seconds`: arrows fly, hits land (enemies stand still).
func _play(area: AreaController, seconds: float) -> void:
	for i: int in roundi(seconds / FRAME):
		area.player.motor.step(Vector2.ZERO, FRAME)
		area.player.sync_from_motor()
		for child: Node in area.interactables.get_children():
			if child is Arrow:
				(child as Arrow).fly(FRAME)
		area.resolve_combat()


## Plays `seconds` with the boss thinking too.
func _fight(area: AreaController, boss: Boss, seconds: float) -> void:
	for i: int in roundi(seconds / FRAME):
		area.player.motor.step(Vector2.ZERO, FRAME)
		area.player.sync_from_motor()
		boss.step(FRAME)
		for child: Node in area.interactables.get_children():
			if child is Arrow:
				(child as Arrow).fly(FRAME)
		area.resolve_combat()


## Lets the boss think until it enters `state`.
func _step_until(_area_controller: AreaController, boss: Boss, state: StringName, seconds: float) -> void:
	for i: int in roundi(seconds / FRAME):
		boss.step(FRAME)
		if boss.brain.state == state:
			return
	assert_that(boss.brain.state).override_failure_message("waited for %s" % state).is_equal(state)


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
