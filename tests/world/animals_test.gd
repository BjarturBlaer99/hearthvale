extends GdUnitTestSuite
## The animals in the world (the Homestead, phase 4, step 4b): by day the hens of a coop with a
## pasture are out in it, and the rest are in their room; at 20:00 all are in, and at 06:00 out
## again (D28); each wanders within its ground and blocks nobody; one right click pets an animal,
## with its sound, and takes what it has ready (D26), and a full pack leaves the egg waiting;
## nothing is set down on an animal's cell; build mode holds them still.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const FARM: String = "res://world/areas/homestead/homestead.tscn"
const COOP_ROOM: String = "res://world/areas/coop/coop.tscn"
const BARN_ROOM: String = "res://world/areas/barn/barn.tscn"
const LAND: StringName = &"homestead"
const FRAME: float = 1.0 / 60.0
## The coop on the open land west of the farmhouse, its doorstep (16, 13) in a pen of
## (13..18, 13..15), fenced on (12..19, 12..16), with a gate at (15, 16).
const COOP_AT: Vector2i = Vector2i(14, 10)
const DOORSTEP: Vector2i = Vector2i(16, 13)
const PEN: Rect2i = Rect2i(13, 13, 6, 3)
const GATE: Vector2i = Vector2i(15, 16)
const BARN_AT: Vector2i = Vector2i(32, 9)

var _area: Node
var _heard: Array[StringName] = []


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	Quests.refresh()
	_noon()
	_heard.clear()
	EventBus.sound.connect(_on_sound)


func after_test() -> void:
	EventBus.sound.disconnect(_on_sound)
	if is_instance_valid(_area):
		_area.free()
	_area = null
	GameState.clear()


func test_by_day_hens_with_a_pasture_are_out_in_it_and_the_rest_are_in() -> void:
	_coop_with_hens(3)
	# No pasture yet: by day they are in their room.
	var farm: AreaController = _farm()
	assert_object(farm.animals).is_not_null()
	assert_array(farm.animals.shown()).is_empty()
	var coop: AreaController = _load(COOP_ROOM)
	assert_object(coop.animals).override_failure_message("the coop's room keeps its animals").is_not_null()
	assert_int(coop.animals.shown().size()).is_equal(3)
	# Fenced, by day they are out, each in the pasture.
	_fence_pen()
	farm = _farm()
	assert_int(farm.animals.shown().size()).is_equal(3)
	var pasture: Array = GameState.pasture_of(&"coop")["cells"]
	for hen: Animal in farm.animals.shown():
		assert_bool(pasture.has(hen.cell())).override_failure_message("hen %d stands in the pasture" % hen.index).is_true()
		assert_that(hen.kind_id).is_equal(&"chicken")
	coop = _load(COOP_ROOM)
	assert_array(coop.animals.shown()).override_failure_message("out of doors, not at home").is_empty()
	# Places with no animals keep none: the farmhouse, the village.
	assert_object(_load("res://world/areas/home/home.tscn").animals).is_null()
	assert_object(_load("res://world/areas/shed/shed.tscn").animals).is_null()


func test_in_at_20_and_out_at_06() -> void:
	_coop_with_hens(2)
	_fence_pen()
	var farm: AreaController = _farm()
	assert_int(farm.animals.shown().size()).is_equal(2)
	GameState.set_time(float(GameState.day_clock().in_day("19:50")))
	EventBus.time_changed.emit(GameState.day, floori(GameState.minute))
	assert_int(farm.animals.shown().size()).override_failure_message("still out at 19:50").is_equal(2)
	GameState.set_time(float(GameState.day_clock().in_day("20:00")))
	EventBus.time_changed.emit(GameState.day, floori(GameState.minute))
	assert_array(farm.animals.shown()).override_failure_message("in at 20:00").is_empty()
	var coop: AreaController = _load(COOP_ROOM)
	assert_int(coop.animals.shown().size()).is_equal(2)
	var floor_cells: Array[Vector2i] = coop.animals.room_floor()
	assert_bool(floor_cells.has(Vector2i(5, 8)) or floor_cells.has(Vector2i(5, 7))).override_failure_message("not on the doormat or the cell before it").is_false()
	assert_bool(floor_cells.has(Vector2i(4, 7))).is_true()
	for hen: Animal in coop.animals.shown():
		assert_bool(floor_cells.has(hen.cell())).is_true()
		assert_bool(coop.terrain.is_occupied(hen.cell())).override_failure_message("in the room, as out of doors, it blocks nobody").is_false()
	# The morning: out at 06:00, from the room too.
	GameState.start_next_day()
	assert_float(GameState.minute).is_equal(float(GameState.day_clock().in_day("06:00")))
	EventBus.time_changed.emit(GameState.day, floori(GameState.minute))
	assert_array(coop.animals.shown()).override_failure_message("out at 06:00").is_empty()
	farm = _farm()
	assert_int(farm.animals.shown().size()).is_equal(2)


func test_each_wanders_within_its_ground_and_blocks_nobody() -> void:
	_coop_with_hens(4)
	_fence_pen()
	var farm: AreaController = _farm()
	var pasture: Array = GameState.pasture_of(&"coop")["cells"]
	var moved: bool = false
	var starts: Array[Vector2] = []
	for hen: Animal in farm.animals.shown():
		starts.append(hen.position)
	for i: int in 1200:
		farm.animals._process(FRAME)
		for hen: Animal in farm.animals.shown():
			assert_bool(pasture.has(hen.cell())).override_failure_message("hen %d left the pasture at %s" % [hen.index, hen.cell()]).is_true()
			if i % 100 == 0:
				assert_bool(farm.terrain.is_occupied(hen.cell())).override_failure_message("a hen blocks nobody").is_false()
	for j: int in starts.size():
		moved = moved or farm.animals.shown()[j].position.distance_to(starts[j]) > 2.0
	assert_bool(moved).override_failure_message("in twenty seconds somebody wandered").is_true()
	# Through the gate the hero walks; a hen never does.
	assert_bool(farm.terrain.is_occupied(GATE)).is_false()
	assert_bool(pasture.has(GATE)).is_false()
	# Build mode holds them still.
	GameState.add_item(&"fence", 1)
	assert_bool(farm.open_build()).is_true()
	var where: Array[Vector2] = []
	for hen: Animal in farm.animals.shown():
		where.append(hen.position)
	for i: int in 120:
		farm.animals._process(FRAME)
	for j: int in where.size():
		assert_that(farm.animals.shown()[j].position).is_equal(where[j])
	farm.build.close()


func test_nothing_is_set_down_on_an_animals_cell() -> void:
	_coop_with_hens(1)
	_fence_pen()
	var farm: AreaController = _farm()
	var hen: Animal = farm.animals.shown()[0]
	_put(hen, Vector2i(17, 14))
	GameState.add_item(&"fence", 2)
	GameState.add_item(&"stone_path", 2)
	farm.player.motor.place(Vector2i(17, 15))
	assert_bool(farm.open_build()).is_true()
	_choose(farm, &"fence")
	farm.build.point_at(Vector2i(17, 14))
	assert_str(farm.build.why_not()).is_equal(Placement.SOMEONE_WORDS)
	farm.build.point_at(Vector2i(14, 14))
	assert_str(farm.build.why_not()).is_empty()
	# A path lies under her feet.
	_choose(farm, &"stone_path")
	farm.build.point_at(Vector2i(17, 14))
	assert_str(farm.build.why_not()).is_empty()
	farm.build.close()


func test_one_right_click_pets_and_takes_and_a_full_pack_leaves_the_egg_waiting() -> void:
	_coop_with_hens(1)
	_fence_pen()
	var farm: AreaController = _farm()
	var hen: Animal = farm.animals.shown()[0]
	# Two cells off, she can't be reached; in the cell he faces, she can.
	_put(hen, Vector2i(16, 13))
	farm.player.motor.place(Vector2i(16, 15))
	farm.player.face(Vector2.RIGHT)
	assert_object(farm.animal_in_front()).override_failure_message("two cells off").is_null()
	farm.player.face(Vector2.UP)
	assert_object(farm.animal_in_front()).override_failure_message("a cell beyond the one he faces").is_null()
	_face(farm, hen, Vector2i(16, 14))
	assert_object(farm.animal_in_front()).is_same(hen)
	farm._update_hud()
	assert_str(farm.hud.prompt_text()).contains("Pet the Chicken")
	# A right click is interact: it pets her, with her cluck.
	farm._unhandled_input(_right_click())
	assert_bool(_heard.has(&"cluck")).is_true()
	assert_bool(GameState.homestead().animal(0)["petted"]).is_true()
	assert_str(farm.hud.message_text()).is_equal("You pet the chicken.")
	# The next morning she has an egg, shown over her head and named in the prompt.
	GameState.start_next_day()
	_noon()
	farm = _farm()
	hen = farm.animals.shown()[0]
	assert_bool(hen.has_ready()).is_true()
	_face(farm, hen, Vector2i(16, 14))
	farm._update_hud()
	assert_str(farm.hud.prompt_text()).contains("Take the Egg")
	assert_bool(farm.interact()).is_true()
	assert_int(GameState.item_count(&"egg")).is_equal(1)
	assert_str(farm.hud.message_text()).is_equal("You pet the chicken. Taken: Egg.")
	assert_bool(hen.has_ready()).is_false()
	# Fed and petted again: another egg; the pack full of eggs leaves it waiting.
	GameState.start_next_day()
	_noon()
	GameState.add_item(&"egg", 29)
	farm = _farm()
	hen = farm.animals.shown()[0]
	_face(farm, hen, Vector2i(16, 14))
	assert_bool(farm.interact()).is_true()
	assert_int(GameState.item_count(&"egg")).is_equal(30)
	assert_str(farm.hud.message_text()).is_equal("You pet the chicken. Your pack has no room for the Egg: it waits.")
	assert_bool(hen.has_ready()).override_failure_message("the egg waits").is_true()


func test_in_the_barn_at_night_a_sheep_and_a_cow_are_petted_with_their_sounds() -> void:
	GameState.add_item(GameState.COIN, 999)
	_build(&"barn", BARN_AT)
	assert_str(GameState.buy_animal(&"sheep", 180)).is_empty()
	assert_str(GameState.buy_animal(&"cow", 240)).is_empty()
	GameState.set_time(float(GameState.day_clock().in_day("21:00")))
	GameState.go_to(&"barn", &"door")
	var barn: AreaController = _load(BARN_ROOM)
	assert_int(barn.animals.shown().size()).is_equal(2)
	for animal: Animal in barn.animals.shown():
		var below: Vector2i = animal.cell() + Vector2i.DOWN
		barn.player.motor.place(below)
		barn.player.face(Vector2.UP)
		assert_object(barn.animal_in_front()).is_same(animal)
		assert_bool(barn.interact()).is_true()
	assert_bool(_heard.has(&"bleat")).is_true()
	assert_bool(_heard.has(&"low")).is_true()
	assert_str(barn.hud.message_text()).is_equal("You pet the cow.")
	# A hungry animal shows it: nobody fed them this morning.
	GameState.start_next_day()
	assert_bool(GameState.homestead().animal(0)["hungry"]).is_true()
	GameState.set_time(float(GameState.day_clock().in_day("21:00")))
	barn = _load(BARN_ROOM)
	assert_bool(barn.animals.shown()[0].is_hungry()).is_true()


func test_the_sounds_are_made_in_code() -> void:
	var tool: Dictionary = (load("res://tools/audio/make_audio.gd") as GDScript).get_script_constant_map()
	for kind: Dictionary in DataRegistry.entries(&"animals"):
		var sound: StringName = Herd.sound_of(kind)
		assert_bool(Audio.SFX.has(sound)).override_failure_message("%s's sound" % kind["id"]).is_true()
		assert_bool((tool["SFX"] as Array).has(String(sound))).is_true()
	assert_array(Animal.FRAMES.keys()).contains([&"sheep", &"sheep_walk", &"sheep_graze", &"cow", &"cow_walk", &"cow_graze"])


# --- Helpers -------------------------------------------------------------------------------

func _noon() -> void:
	GameState.set_time(float(GameState.day_clock().in_day("12:00")))


func _build(id: StringName, at: Vector2i) -> void:
	for cell: Vector2i in Buildings.cells_and_doorstep(DataRegistry.get_building(id), at):
		GameState.clear_debris(LAND, cell)
	var kit: StringName = Buildings.kit_for(id, DataRegistry.entries(&"items"))
	GameState.add_item(kit)
	assert_bool(GameState.set_down_kit(LAND, at, kit)).is_true()
	GameState.start_next_day()
	_noon()


func _coop_with_hens(count: int) -> void:
	GameState.add_item(GameState.COIN, 60 * count)
	_build(&"coop", COOP_AT)
	for i: int in count:
		assert_str(GameState.buy_animal(&"chicken", 60)).is_empty()


## Clears the pen round the coop's door and fences it, with a gate in its south side.
func _fence_pen() -> void:
	var ring: Rect2i = PEN.grow(1)
	for y: int in range(ring.position.y - 1, ring.end.y):
		for x: int in range(ring.position.x, ring.end.x):
			GameState.clear_debris(LAND, Vector2i(x, y))
	for x: int in range(ring.position.x, ring.end.x):
		for y: int in range(ring.position.y, ring.end.y):
			var cell: Vector2i = Vector2i(x, y)
			if PEN.has_point(cell) or GameState.building_covering(LAND, cell) != &"":
				continue
			GameState.homestead().set_down(cell, Placement.STANDING, &"gate" if cell == GATE else &"fence")


## Loads the farm with the hero in the pen, below the coop's door.
func _farm() -> AreaController:
	GameState.update_player(LAND, Vector2i(16, 15))
	return _load(FARM)


## Stands `animal` in `cell` and the hero below it, facing up.
func _face(area: AreaController, animal: Animal, cell: Vector2i) -> void:
	_put(animal, cell)
	area.player.motor.place(cell + Vector2i.DOWN)
	area.player.face(Vector2.UP)


func _put(animal: Animal, cell: Vector2i) -> void:
	animal.motion.position = GridBody.cell_center(cell)
	animal.position = animal.motion.position


func _choose(farm: AreaController, id: StringName) -> void:
	for step: int in farm.build.entries().size():
		if farm.build.chosen == id:
			return
		farm.build.step(1)


func _right_click() -> InputEventMouseButton:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_RIGHT
	event.pressed = true
	return event


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area


func _on_sound(id: StringName) -> void:
	_heard.append(id)
