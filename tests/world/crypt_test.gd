extends GdUnitTestSuite
## The Chapel Crypt (H14): ten dark rooms under Hearthvale's chapel, barred until the keep is
## quiet. Pits cost half a heart and put the hero back at the edge, and a block pushed in
## bridges one for good. Torches need the Lantern and open their doors; some burn only briefly.
## A walkthrough finishes the crypt start to end, then the Crypt Shade: blows pass through it
## until all four braziers burn, it takes more than one binding, and beaten it leaves a heart
## container. The Iron Sword, found on the way, hits harder than the wooden one.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const CRYPT: String = "res://world/areas/crypt/crypt.tscn"
const VILLAGE: String = "res://world/areas/village/village.tscn"
const FRAME: float = 1.0 / 60.0
const SIDES: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
## Cells inside each room, by name (on the side the hero comes in by).
const NARTHEX: Vector2i = Vector2i(22, 40)
const TRENCH: Vector2i = Vector2i(33, 38)
const OSSUARY: Vector2i = Vector2i(10, 38)
const HALL: Vector2i = Vector2i(22, 27)
const TOMB: Vector2i = Vector2i(36, 27)
const BROKEN_FLOOR: Vector2i = Vector2i(10, 28)
const DARK_PATH: Vector2i = Vector2i(37, 19)
const RELIQUARY: Vector2i = Vector2i(7, 18)
const KNIGHTS_TOMB: Vector2i = Vector2i(37, 8)
const SHADES_HALL: Vector2i = Vector2i(22, 19)
## Where to stand, and which way to face, to light each of the Shade's braziers.
const BRAZIER_SPOTS: Array = [
	[Vector2i(25, 14), Vector2.RIGHT], [Vector2i(19, 14), Vector2.LEFT],
	[Vector2i(25, 18), Vector2.RIGHT], [Vector2i(19, 18), Vector2.LEFT],
]

var _area: Node


func before_test() -> void:
	GameState.clear()
	GameState.new_game()


func after_test() -> void:
	if is_instance_valid(_area):
		_area.free()
	_area = null
	GameState.clear()


func test_the_crypt_is_under_the_chapel_and_barred_until_the_keep_is_quiet() -> void:
	GameState.go_to(&"village", &"crypt_door")
	var village: AreaController = _load(VILLAGE)
	var door: Vector2i = village.player.motor.cell
	assert_that(door).is_equal(Vector2i(23, 6))
	var bars: DungeonDoor = village.interactables.get_node(^"CryptBars")
	assert_bool(bars.is_open()).is_false()
	assert_str(Steps.walk_until_travel(village, Vector2.UP, 90)).override_failure_message("the bars hold").is_equal("")
	village.player.face(Vector2.UP)
	assert_bool(village.interact()).override_failure_message("E says why").is_true()
	# The Warden falls, with the story behind it: the bars hold until the next dawn (P4a).
	for flag: StringName in [StoryGates.FIRST_CROP, StoryGates.KEEP_GATE, StoryGates.WARDEN_BEATEN]:
		GameState.set_flag(flag, true)
	assert_bool(bars.is_open()).override_failure_message("not on the day the Warden falls").is_false()
	GameState.start_next_day()
	assert_bool(bars.is_open()).override_failure_message("at dawn the day after").is_true()
	var crypt: AreaController = _load(Steps.walk_until_travel(village, Vector2.UP, 90))
	assert_str(crypt.area_name).is_equal("The Chapel Crypt")
	assert_that(crypt.current_room).is_equal(Vector2i(1, 3))
	village = _load(Steps.walk_until_travel(crypt, Vector2.DOWN))
	assert_that(village.player.motor.cell).is_equal(door)


func test_guard_rolf_says_why_the_door_is_barred_and_when_it_opens() -> void:
	var before: DialogueRunner = DialogueRunner.new(DataRegistry.get_dialogue(&"guard_rolf"), GameState)
	before.start()
	assert_bool(Array(before.option_texts()).has("Why is the chapel door barred?")).is_true()
	assert_bool(Array(before.option_texts()).has("The chapel door stands open.")).is_false()
	GameState.set_flag(StoryGates.CRYPT_OPEN, true)
	var after: DialogueRunner = DialogueRunner.new(DataRegistry.get_dialogue(&"guard_rolf"), GameState)
	after.start()
	assert_bool(Array(after.option_texts()).has("The chapel door stands open.")).is_true()
	assert_bool(Array(after.option_texts()).has("Why is the chapel door barred?")).is_false()


func test_ten_rooms_all_joined_once_every_door_is_open_and_every_pit_bridged() -> void:
	var crypt: AreaController = _load(CRYPT)
	var rooms: Array[Vector2i] = []
	for ry: int in 4:
		for rx: int in 3:
			var origin: Vector2i = Vector2i(rx, ry) * crypt.room_size
			if not crypt.grid.is_solid(origin + Vector2i(7, 5)) or not crypt.grid.is_solid(origin + Vector2i(1, 1)):
				rooms.append(Vector2i(rx, ry))
	assert_int(rooms.size()).override_failure_message("10 to 14 rooms").is_equal(10)
	for door: DungeonDoor in crypt.doors():
		GameState.set_flag(DungeonState.door_flag(&"crypt", door.door_id), true)
		if door.open_flag != &"":
			GameState.set_flag(door.open_flag, true)
		for flag: StringName in door.open_flags:
			GameState.set_flag(flag, true)
	# The Tomb's crystal opens one gap or the other: red is the way north.
	GameState.set_flag(&"crypt_tomb_blue", false)
	var pits: Array[Vector2i] = HeightGridBuilder.pit_cells(crypt.height_layer)
	assert_int(pits.size()).override_failure_message("the crypt has pits").is_greater(40)
	for pit: Vector2i in pits:
		assert_bool(crypt.terrain.is_pit(pit)).is_true()
		crypt.terrain.set_pit(pit, false)
	var reachable: Dictionary = _reachable(crypt, NARTHEX)
	for cell: Vector2i in [TRENCH, OSSUARY, HALL, TOMB, BROKEN_FLOOR, DARK_PATH, RELIQUARY, KNIGHTS_TOMB, SHADES_HALL]:
		assert_bool(reachable.has(cell)).override_failure_message("%s is joined to the rest" % cell).is_true()


func test_falling_into_a_pit_costs_half_a_heart_and_puts_the_hero_back_at_the_edge() -> void:
	var crypt: AreaController = _load(CRYPT)
	var edge: Vector2i = Vector2i(36, 38)
	_face(crypt, edge + Vector2i.LEFT, Vector2.RIGHT)
	_walk_into_the_pit(crypt, Vector2.RIGHT)
	assert_int(GameState.health).override_failure_message("half a heart").is_equal(GameState.max_health() - 1)
	assert_that(crypt.player.motor.cell).is_equal(Vector2i(37, 38))
	assert_bool(crypt.player.is_falling()).is_true()
	assert_bool(crypt.player.controls_enabled).is_false()
	assert_bool(crypt.player.hurt_box.enabled).override_failure_message("out of reach while falling").is_false()
	assert_bool(crypt.interact()).override_failure_message("nothing to do while falling").is_false()
	_wait(crypt, AreaController.PIT_TIME + 0.05)
	assert_bool(crypt.is_in_pit()).is_false()
	assert_that(crypt.player.motor.cell).override_failure_message("back at the edge").is_equal(edge)
	assert_bool(crypt.player.is_falling()).is_false()
	assert_bool(crypt.player.controls_enabled).is_true()
	assert_bool(crypt.player.hurt_box.enabled).is_true()
	assert_bool(crypt.player.motor.is_invincible()).override_failure_message("a moment's grace").is_true()
	assert_int(GameState.health).override_failure_message("and only the once").is_equal(GameState.max_health() - 1)


func test_a_fall_on_the_last_half_heart_sends_the_hero_back_to_the_entrance() -> void:
	var crypt: AreaController = _load(CRYPT)
	var entrance: Vector2i = crypt.player.motor.cell
	GameState.set_health(1)
	_face(crypt, Vector2i(35, 38), Vector2.RIGHT)
	_walk_into_the_pit(crypt, Vector2.RIGHT)
	assert_bool(crypt.is_dying()).is_true()
	_wait(crypt, AreaController.RESPAWN_DELAY + 0.1)
	assert_bool(crypt.is_dying()).is_false()
	assert_that(crypt.player.motor.cell).is_equal(entrance)
	assert_int(GameState.health).is_equal(GameState.max_health())
	assert_bool(crypt.player.is_falling()).is_false()
	assert_bool(crypt.player.hurt_box.enabled).is_true()
	assert_bool(crypt.player.controls_enabled).is_true()


func test_enemies_keep_out_of_pits_but_bats_fly_over_and_drops_land_beside() -> void:
	var crypt: AreaController = _load(CRYPT)
	var walker: GridBody = GridBody.new(crypt.terrain)
	walker.allow_drops = false
	walker.place(Vector2i(36, 38))
	assert_bool(walker.can_enter(Vector2i(37, 38))).override_failure_message("a slime at the edge").is_false()
	var flier: GridBody = GridBody.new(crypt.terrain)
	flier.flying = true
	flier.place(Vector2i(36, 38))
	assert_bool(flier.can_enter(Vector2i(37, 38))).override_failure_message("a bat").is_true()
	var bat: Enemy = crypt.interactables.get_node(^"PathBatA")
	bat.body.place(Vector2i(36, 17))
	assert_bool(crypt.terrain.is_pit(bat.body.cell)).is_true()
	var drop: Vector2i = bat.drop_cell()
	assert_bool(crypt.terrain.is_pit(drop)).override_failure_message("its drop lands on floor").is_false()
	assert_int(absi(drop.x - 36) + absi(drop.y - 17)).override_failure_message("right beside the pit").is_equal(1)


func test_a_block_pushed_into_the_trench_bridges_it_for_good() -> void:
	var crypt: AreaController = _load(CRYPT)
	var block: PushBlock = crypt.interactables.get_node(^"TrenchBlock")
	assert_bool(_reachable(crypt, TRENCH).has(Vector2i(40, 38))).override_failure_message("the trench cuts the room in two").is_false()
	_push(crypt, block, Vector2i(33, 36), Vector2.RIGHT, Vector2i(37, 36))
	assert_bool(block.sunk).is_true()
	assert_bool(crypt.terrain.is_pit(Vector2i(37, 36))).override_failure_message("the pit is floor now").is_false()
	assert_bool(crypt.terrain.is_occupied(Vector2i(37, 36))).override_failure_message("and nothing stands on it").is_false()
	assert_bool(crypt.terrain.is_pit(Vector2i(37, 38))).override_failure_message("the rest of the trench is still there").is_true()
	assert_bool(_reachable(crypt, TRENCH).has(Vector2i(40, 38))).is_true()
	assert_bool(block.try_push(Vector2i.RIGHT, crypt.terrain, crypt.room_size)).override_failure_message("it moves no more").is_false()
	crypt = _load(CRYPT)
	block = crypt.interactables.get_node(^"TrenchBlock")
	assert_bool(block.sunk).override_failure_message("still sunk on the next visit").is_true()
	assert_that(block.cell()).is_equal(Vector2i(37, 36))
	assert_bool(crypt.terrain.is_pit(Vector2i(37, 36))).is_false()
	assert_bool(_reachable(crypt, TRENCH).has(Vector2i(40, 38))).is_true()
	crypt.reset_blocks()
	assert_that(block.cell()).override_failure_message("and leaving the room doesn't lift it out").is_equal(Vector2i(37, 36))


func test_a_game_past_the_reliquarys_door_finds_the_new_pit_filled() -> void:
	# The pit before the Reliquary's door and its block came after games were saved (harder
	# dungeons, 2026-11-23): one that opened the door before then is never stuck beyond it.
	var crypt: AreaController = _load(CRYPT)
	assert_bool(crypt.terrain.is_pit(Vector2i(7, 23))).override_failure_message("a new game: the pit is open").is_true()
	assert_bool((crypt.interactables.get_node(^"FloorBlockB") as PushBlock).sunk).is_false()
	GameState.set_flag(DungeonState.door_flag(&"crypt", &"reliquary_door"), true)
	crypt = _load(CRYPT)
	var block: PushBlock = crypt.interactables.get_node(^"FloorBlockB")
	assert_bool(block.sunk).is_true()
	assert_that(block.cell()).is_equal(Vector2i(7, 23))
	assert_bool(crypt.terrain.is_pit(Vector2i(7, 23))).override_failure_message("filled").is_false()
	assert_bool(_reachable(crypt, RELIQUARY).has(Vector2i(7, 25))).override_failure_message("the way back from the Reliquary").is_true()


func test_the_second_block_can_never_reach_the_trench() -> void:
	# It starts against the north wall, west of the pit: nobody can stand above it, so it only
	# slides along the wall, and the one pit it can fall into is the one before the door. (Pushed
	# south into the trench it would sink there for good, and the door's pit could never be filled.)
	var crypt: AreaController = _load(CRYPT)
	var second: PushBlock = crypt.interactables.get_node(^"FloorBlockB")
	assert_int(second.cell().y).is_equal(23)
	assert_int(second.cell().x).is_less(7)
	for x: int in range(1, 8):
		assert_bool(crypt.grid.is_solid(Vector2i(x, 22)) or x == 7).override_failure_message("(%d, 22) is wall" % x).is_true()
	assert_bool(crypt.interactables.get_node(^"ReliquaryInscription") is Node2D).is_true()
	assert_that(GridBody.cell_of((crypt.interactables.get_node(^"ReliquaryInscription") as Node2D).position + Vector2(8, 8))).override_failure_message("the inscription closes the row east of the pit").is_equal(Vector2i(8, 23))


func test_a_game_that_took_the_ossuarys_key_keeps_its_bars_open() -> void:
	GameState.set_flag(DungeonState.chest_flag(&"crypt", &"ossuary_key"), true)
	var crypt: AreaController = _load(CRYPT)
	assert_bool((crypt.interactables.get_node(^"OssuaryKeyBars") as DungeonDoor).is_open()).is_true()


func test_the_ossuarys_plates_are_one_to_three() -> void:
	var crypt: AreaController = _load(CRYPT)
	var places: Array = []
	for child: Node in crypt.interactables.get_children():
		if child is PressurePlate and (child as PressurePlate).order > 0:
			places.append((child as PressurePlate).order)
	assert_array(Array(PlateSequence.problems(places))).is_empty()
	assert_int(places.size()).is_equal(3)


func test_a_block_without_a_name_is_lifted_out_again_when_the_room_resets() -> void:
	var crypt: AreaController = _load(CRYPT)
	var loose: PushBlock = PushBlock.new()
	loose.position = Vector2(35, 40) * 16.0
	crypt.interactables.add_child(loose)
	crypt.terrain.set_occupied(loose.cell())
	assert_bool(loose.try_push(Vector2i.RIGHT, crypt.terrain, crypt.room_size)).is_true()
	assert_bool(loose.sunk).is_false()
	assert_bool(loose.try_push(Vector2i.RIGHT, crypt.terrain, crypt.room_size)).is_true()
	assert_bool(loose.sunk).is_true()
	assert_bool(crypt.terrain.is_pit(Vector2i(37, 40))).is_false()
	assert_bool(loose.reset(crypt.terrain)).is_true()
	assert_bool(loose.sunk).is_false()
	assert_that(loose.cell()).is_equal(Vector2i(35, 40))
	assert_bool(crypt.terrain.is_pit(Vector2i(37, 40))).override_failure_message("the pit is open again").is_true()
	assert_bool(crypt.terrain.is_occupied(Vector2i(35, 40))).is_true()


func test_torches_need_the_lantern_and_open_their_doors_for_good() -> void:
	var crypt: AreaController = _load(CRYPT)
	var torch: Torch = crypt.interactables.get_node(^"NarthexTorchA")
	var bars: DungeonDoor = crypt.interactables.get_node(^"OssuaryBars")
	_face(crypt, Vector2i(17, 35), Vector2.UP)
	assert_str(torch.prompt()).is_equal("An unlit torch")
	assert_bool(crypt.interact()).override_failure_message("E says it needs a flame").is_true()
	assert_bool(torch.is_lit()).override_failure_message("no lantern, no light").is_false()
	GameState.add_item(&"lantern")
	assert_str(torch.prompt()).is_equal("Light the torch")
	assert_bool(crypt.interact()).is_true()
	assert_bool(torch.is_lit()).is_true()
	assert_bool(GameState.get_flag(&"crypt_narthex_a") == true).is_true()
	assert_str(torch.prompt()).override_failure_message("nothing more to do with it").is_equal("")
	assert_bool(bars.is_open()).override_failure_message("one torch of two").is_false()
	# They stand apart and burn 6 s (harder dungeons, 2026-11-23): both lit in one run.
	_burn(crypt, 6.1)
	assert_bool(torch.is_lit()).override_failure_message("too slow: it went out").is_false()
	_open(crypt, Vector2i(27, 41), Vector2.DOWN)
	assert_bool(bars.is_open()).is_false()
	_open(crypt, Vector2i(17, 35), Vector2.UP)
	assert_bool(bars.is_open()).is_true()
	assert_bool(crypt.terrain.is_occupied(Vector2i(14, 38))).is_false()
	crypt = _load(CRYPT)
	assert_bool((crypt.interactables.get_node(^"OssuaryBars") as DungeonDoor).is_open()).override_failure_message("still open on the next visit").is_true()
	assert_bool((crypt.interactables.get_node(^"NarthexTorchA") as Torch).is_lit()).override_failure_message("though the torch is out").is_false()


func test_brief_torches_go_out_unless_all_four_burn_together() -> void:
	GameState.add_item(&"lantern")
	var crypt: AreaController = _load(CRYPT)
	var first: Torch = crypt.interactables.get_node(^"KnightTorchA")
	var bars: DungeonDoor = crypt.interactables.get_node(^"SwordBars")
	_open(crypt, Vector2i(42, 9), Vector2.RIGHT)
	assert_bool(first.is_lit()).is_true()
	_burn(crypt, first.burn_time - 0.5)
	assert_bool(first.is_lit()).override_failure_message("burns for its burn time").is_true()
	_burn(crypt, 1.0)
	assert_bool(first.is_lit()).override_failure_message("then goes out").is_false()
	assert_bool(GameState.get_flag(&"crypt_knight_a") == true).is_false()
	assert_bool(bars.is_open()).is_false()
	assert_float(first.burn_time).is_equal_approx(5.5, 0.001)
	_light_the_knights_torches(crypt, 2.0)
	assert_bool(bars.is_open()).override_failure_message("too slow: the first went out before the fourth").is_false()
	_burn(crypt, 6.0)
	_light_the_knights_torches(crypt, 1.5, true)
	assert_bool(bars.is_open()).override_failure_message("three of four").is_false()
	_open(crypt, Vector2i(42, 5), Vector2.RIGHT)
	assert_bool(bars.is_open()).override_failure_message("all four at once").is_true()
	_burn(crypt, 8.0)
	assert_bool(first.is_lit()).is_false()
	assert_bool(bars.is_open()).override_failure_message("open for good, though the torches have gone out").is_true()


func test_a_brief_torch_starts_every_visit_unlit() -> void:
	GameState.set_flag(&"crypt_knight_a", true)
	var crypt: AreaController = _load(CRYPT)
	assert_bool((crypt.interactables.get_node(^"KnightTorchA") as Torch).is_lit()).is_false()
	assert_bool(GameState.get_flag(&"crypt_knight_a") == true).override_failure_message("a flag left over from a save mid-burn is cleared").is_false()


func test_the_dark_shows_only_what_light_reaches() -> void:
	var crypt: AreaController = _load(CRYPT)
	assert_bool(crypt.dark).is_true()
	assert_that(crypt.lighting.ambient).override_failure_message("the crypt's own dark").is_equal(AreaLighting.DARK)
	assert_float(crypt.brightness_at(Vector2i(22, 38))).override_failure_message("the Narthex is lit by its braziers").is_greater(0.5)
	assert_float(crypt.hero_light_radius()).is_equal(AreaController.DIM_RADIUS)
	_face(crypt, DARK_PATH, Vector2.UP)
	assert_int(crypt.lights().size()).override_failure_message("only the hero's glow: the braziers next door don't shine through the wall").is_equal(1)
	assert_float(crypt.brightness_at(DARK_PATH)).is_equal(1.0)
	assert_float(crypt.brightness_at(DARK_PATH + Vector2i(0, -2))).override_failure_message("the pit two cells ahead can't be seen").is_equal(0.0)
	GameState.add_item(&"lantern")
	assert_float(crypt.hero_light_radius()).override_failure_message("the Lantern's reach, from its data").is_equal(56.0)
	assert_float(crypt.brightness_at(DARK_PATH + Vector2i(0, -2))).override_failure_message("with the Lantern it can").is_greater(0.5)
	assert_float(crypt.brightness_at(DARK_PATH + Vector2i(0, -5))).override_failure_message("but not the far end of the room").is_equal(0.0)
	crypt._process(FRAME)
	assert_int(_pools(crypt).size()).override_failure_message("one pool of light: the hero's").is_equal(1)
	_open(crypt, Vector2i(39, 13), Vector2.UP)
	crypt._process(FRAME)
	assert_int(_pools(crypt).size()).override_failure_message("a lit torch is a light").is_equal(2)
	assert_float(crypt.brightness_at(Vector2i(39, 13))).is_greater(0.5)
	GameState.set_time(float(GameState.day_clock().in_day("12:00")))
	var village: AreaController = _load(VILLAGE)
	assert_that(village.lighting.ambient).override_failure_message("the village isn't dark (at noon it is clear)").is_equal(Color.WHITE)
	assert_float(village.brightness_at(Vector2i(2, 30))).is_equal(1.0)


func test_the_crypt_can_be_finished_start_to_end() -> void:
	GameState.add_item(&"wooden_sword")
	GameState.add_item(&"bow")
	GameState.add_item(&"arrow", 20)
	var crypt: AreaController = _load(CRYPT)
	var hearts: int = GameState.hearts_max
	var items: Array = DataRegistry.entries(&"items")
	assert_str(str(CombatRules.best_melee_weapon(GameState.inventory, items)["id"])).is_equal("wooden_sword")

	# 1. The Trench: the block bridges it, and the chest beyond holds a small key.
	_push(crypt, crypt.interactables.get_node(^"TrenchBlock"), Vector2i(33, 36), Vector2.RIGHT, Vector2i(37, 36))
	_open(crypt, Vector2i(40, 38), Vector2.RIGHT)
	assert_int(_keys()).is_equal(1)

	# 2. The Hall of the Dead: the key opens the east door. The west door wants two torches lit.
	assert_bool(_reachable(crypt, HALL).has(TOMB)).is_false()
	_open(crypt, Vector2i(28, 27), Vector2.RIGHT)
	assert_int(_keys()).is_equal(0)
	assert_bool(_reachable(crypt, HALL).has(TOMB)).is_true()
	assert_bool(_reachable(crypt, HALL).has(BROKEN_FLOOR)).is_false()

	# 3. The Lantern's Tomb: a wall across it, its two gaps barred, one open while the crystal is
	# red and one while it is blue. The Lantern is behind the blue one, the torch that opens the
	# way north behind the red one.
	var crystal: CrystalSwitch = crypt.interactables.get_node(^"TombCrystal")
	assert_bool(_reachable(crypt, TOMB).has(Vector2i(35, 24))).override_failure_message("red: the torch's side").is_true()
	assert_bool(_reachable(crypt, TOMB).has(Vector2i(42, 24))).override_failure_message("red: not the Lantern's").is_false()
	_swing(crypt, Vector2i(37, 28), Vector2.DOWN)
	assert_bool(crystal.is_on()).is_true()
	assert_bool(_reachable(crypt, TOMB).has(Vector2i(35, 24))).override_failure_message("blue: the torch's side is shut").is_false()
	_open(crypt, Vector2i(42, 24), Vector2.UP)
	assert_int(GameState.item_count(&"lantern")).is_equal(1)
	assert_bool(crypt.player.is_holding_up()).is_true()
	var path_bars: DungeonDoor = crypt.interactables.get_node(^"PathBars")
	assert_bool(path_bars.is_open()).is_false()
	crystal._process(CrystalSwitch.LOCKOUT + 0.01)
	_swing(crypt, Vector2i(37, 28), Vector2.DOWN)
	assert_bool(crystal.is_on()).override_failure_message("red again").is_false()
	_open(crypt, Vector2i(35, 24), Vector2.UP)
	assert_bool(path_bars.is_open()).is_true()

	# 4. The Dark Path: a way winds between the pits; a torch at each end, burning 8 s.
	var path: Dictionary = _reachable(crypt, DARK_PATH)
	assert_bool(path.has(Vector2i(39, 13)) and path.has(Vector2i(32, 20))).override_failure_message("the path reaches both torches").is_true()
	assert_bool(path.has(KNIGHTS_TOMB)).is_false()
	_open(crypt, Vector2i(32, 20), Vector2.LEFT)
	_burn(crypt, 8.1)
	_open(crypt, Vector2i(39, 13), Vector2.UP)
	assert_bool(_reachable(crypt, DARK_PATH).has(KNIGHTS_TOMB)).override_failure_message("too slow: the first went out").is_false()
	_burn(crypt, 3.0)
	_open(crypt, Vector2i(32, 20), Vector2.LEFT)
	assert_bool(_reachable(crypt, DARK_PATH).has(KNIGHTS_TOMB)).is_true()

	# 5. The Knight's Tomb: four brief torches, and the Iron Sword.
	var sword_bars: DungeonDoor = crypt.interactables.get_node(^"SwordBars")
	_light_the_knights_torches(crypt, 1.5)
	assert_bool(sword_bars.is_open()).is_true()
	_open(crypt, Vector2i(37, 3), Vector2.UP)
	var best: Dictionary = CombatRules.best_melee_weapon(GameState.inventory, items)
	assert_str(str(best["id"])).override_failure_message("the hero swings the Iron Sword now").is_equal("iron_sword")
	assert_float(float(CombatRules.weapon_stats(best)["damage"])).override_failure_message("and it hits harder than the wooden one").is_greater(float(CombatRules.weapon_stats(DataRegistry.get_item(&"wooden_sword"))["damage"]))
	crypt.player.face(Vector2.DOWN)
	assert_bool(crypt.player.swing()).is_true()
	assert_int(crypt.player.sword.damage).override_failure_message("a swing does the Iron Sword's damage").is_equal(3)
	assert_that(crypt.player.sword.blade).override_failure_message("with a steel blade").is_equal(Sword.BLADES[&"iron_sword"])
	crypt.player.motor.place(crypt.player.motor.cell)

	# 6. The Narthex's two torches, far apart, open the Ossuary: beat everything in it and visit
	# the watchmen in the order its inscription gives, for the second key.
	_open(crypt, Vector2i(17, 35), Vector2.UP)
	_burn(crypt, 2.0)
	_open(crypt, Vector2i(27, 41), Vector2.DOWN)
	assert_bool(_reachable(crypt, NARTHEX).has(OSSUARY)).is_true()
	var key_bars: DungeonDoor = crypt.interactables.get_node(^"OssuaryKeyBars")
	assert_bool(key_bars.is_open()).is_false()
	_beat_all(crypt, &"crypt_ossuary_clear")
	assert_bool(key_bars.is_open()).override_failure_message("the watchmen not visited").is_false()
	_walk_onto(crypt, Vector2i(11, 35), Vector2i(9, 39))
	assert_bool((crypt.interactables.get_node(^"OssuaryPlateNorth") as PressurePlate).pressed).override_failure_message("out of turn").is_false()
	for plate_cell: Vector2i in [Vector2i(11, 41), Vector2i(11, 35)]:
		_walk_onto(crypt, plate_cell, Vector2i(9, 39))
	assert_bool(key_bars.is_open()).is_false()
	_walk_onto(crypt, Vector2i(7, 38), Vector2i(9, 39))
	assert_bool(key_bars.is_open()).is_true()
	_open(crypt, Vector2i(2, 36), Vector2.UP)
	assert_int(_keys()).is_equal(1)

	# 7. The Hall's two torches, in its far corners, open the Broken Floor.
	_open(crypt, Vector2i(17, 24), Vector2.UP)
	_burn(crypt, 2.0)
	_open(crypt, Vector2i(27, 30), Vector2.DOWN)
	assert_bool(_reachable(crypt, HALL).has(BROKEN_FLOOR)).is_true()

	# 8. The Broken Floor: a block in the far corner bridges the trench; beyond it a second block
	# fills the pit before the door; the key opens the door.
	assert_bool(_reachable(crypt, BROKEN_FLOOR).has(Vector2i(7, 24))).is_false()
	_push(crypt, crypt.interactables.get_node(^"FloorBlock"), Vector2i(3, 31), Vector2.UP, Vector2i(3, 26))
	assert_bool(_reachable(crypt, BROKEN_FLOOR).has(Vector2i(7, 24))).is_true()
	assert_bool(_reachable(crypt, BROKEN_FLOOR).has(Vector2i(7, 23))).override_failure_message("a pit before the door").is_false()
	var second: PushBlock = crypt.interactables.get_node(^"FloorBlockB")
	_push(crypt, second, Vector2i(2, 23), Vector2.RIGHT, Vector2i(7, 23))
	assert_bool(second.sunk).is_true()
	assert_bool(_reachable(crypt, BROKEN_FLOOR).has(Vector2i(7, 23))).is_true()
	_open(crypt, Vector2i(7, 23), Vector2.UP)
	assert_int(_keys()).is_equal(0)

	# 9. The Reliquary: an arrow across the pit into the crystal, and the big key.
	var bigkey_bars: DungeonDoor = crypt.interactables.get_node(^"BigKeyBars")
	assert_bool(bigkey_bars.is_open()).is_false()
	assert_float(crypt.brightness_at(Vector2i(2, 13))).override_failure_message("from the room before, the crystal is in the dark").is_equal(0.0)
	var west_crystal: CrystalSwitch = crypt.interactables.get_node(^"ReliquaryCrystal")
	_shoot(crypt, Vector2i(2, 16), Vector2.UP)
	assert_float(crypt.brightness_at(Vector2i(2, 13))).override_failure_message("from the pit's edge it shows in the Lantern's light").is_greater(0.0)
	assert_bool(west_crystal.is_on()).is_true()
	assert_bool(bigkey_bars.is_open()).override_failure_message("one crystal of two").is_false()
	west_crystal._process(4.1)
	_shoot(crypt, Vector2i(12, 16), Vector2.UP)
	assert_bool(bigkey_bars.is_open()).override_failure_message("too slow: the first turned back").is_false()
	_shoot(crypt, Vector2i(2, 16), Vector2.UP)
	assert_bool(bigkey_bars.is_open()).is_true()
	_open(crypt, Vector2i(3, 19), Vector2.LEFT)
	assert_bool(GameState.get_flag(DungeonState.big_key_flag(&"crypt")) == true).is_true()

	# 10. The boss door.
	_open(crypt, Vector2i(22, 23), Vector2.UP)
	assert_bool(_reachable(crypt, HALL).has(SHADES_HALL)).is_true()

	# 11. The Crypt Shade: blows pass through it until all four braziers burn.
	var shade: ShadeBoss = crypt.interactables.get_node(^"Shade")
	_face(crypt, SHADES_HALL, Vector2.UP)
	_fight(crypt, shade, 0.5)
	assert_that(shade.brain.state).is_equal(ShadeBrain.HAUNT)
	assert_bool(shade.hit_box.active).override_failure_message("its touch hurts").is_true()
	shade.hurt_box.receive(Hit.new(3, Vector2.ZERO, Vector2.ZERO, &"sword"))
	shade.hurt_box.receive(Hit.new(2, Vector2.ZERO, Vector2.ZERO, &"arrow"))
	assert_int(shade.brain.health).override_failure_message("blows pass through").is_equal(shade.brain.max_health)
	var rounds: int = 0
	while not shade.is_dead() and rounds < 8:
		rounds += 1
		for i: int in BRAZIER_SPOTS.size():
			assert_bool(shade.shade.is_bound()).override_failure_message("not bound with %d of 4 burning" % i).is_false()
			_open(crypt, BRAZIER_SPOTS[i][0], BRAZIER_SPOTS[i][1])
			_fight(crypt, shade, FRAME * 2.0)
		assert_bool(shade.shade.is_bound()).override_failure_message("all four burning bind it").is_true()
		assert_bool(shade.hit_box.active).override_failure_message("bound, its touch does no harm").is_false()
		for blow: int in 12:
			shade.hurt_box.receive(Hit.new(3, Vector2.ZERO, Vector2.ZERO, &"sword"))
			if shade.is_dead():
				break
			_fight(crypt, shade, ShadeBrain.FLINCH_TIME + FRAME)
			if not shade.shade.is_bound():
				break
		if not shade.is_dead():
			assert_bool(shade.all_lit()).override_failure_message("it snuffed the braziers").is_false()
			assert_that(shade.brain.state).is_equal(ShadeBrain.HAUNT)
	assert_bool(shade.is_dead()).is_true()
	assert_int(rounds).override_failure_message("it takes more than one binding").is_greater(1)
	assert_bool(GameState.get_flag(&"crypt_shade_beaten") == true).is_true()

	# 12. The heart container.
	var heart: HeartContainer = crypt.interactables.get_node(^"HeartContainer")
	assert_bool(heart.is_there()).is_true()
	crypt.player.motor.place(heart.cell())
	crypt.player.sync_from_motor()
	assert_int(crypt.collect_pickups()).is_equal(1)
	assert_int(GameState.hearts_max).is_equal(hearts + 1)
	assert_bool(crypt.is_talking()).override_failure_message("and the closing words").is_true()
	assert_str(crypt.hud.dialogue.runner.text()).contains("Shade is gone")


func test_the_shade_starts_over_when_the_hero_leaves_and_stays_beaten() -> void:
	GameState.add_item(&"lantern")
	var crypt: AreaController = _load(CRYPT)
	var shade: ShadeBoss = crypt.interactables.get_node(^"Shade")
	assert_int(shade.braziers().size()).is_equal(4)
	_face(crypt, SHADES_HALL, Vector2.UP)
	_fight(crypt, shade, 0.5)
	for spot: Array in BRAZIER_SPOTS:
		_open(crypt, spot[0], spot[1])
	_fight(crypt, shade, FRAME * 2.0)
	shade.hurt_box.receive(Hit.new(3, Vector2.ZERO, Vector2.ZERO, &"sword"))
	assert_int(shade.brain.health).is_equal(shade.brain.max_health - 3)
	_face(crypt, HALL, Vector2.UP)
	_fight(crypt, shade, FRAME * 2.0)
	assert_that(shade.brain.state).is_equal(EnemyBrain.IDLE)
	assert_int(shade.brain.health).override_failure_message("full health again").is_equal(shade.brain.max_health)
	assert_that(shade.body.cell).is_equal(Vector2i(22, 15))
	for torch: Torch in shade.braziers():
		assert_bool(torch.is_lit()).override_failure_message("the braziers are out again").is_false()
	assert_bool(shade.hit_box.active).is_true()
	GameState.set_flag(&"crypt_shade_beaten", true)
	crypt = _load(CRYPT)
	assert_bool(crypt.interactables.get_node(^"Shade").is_queued_for_deletion()).override_failure_message("beaten, it doesn't come back").is_true()


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area


func _keys() -> int:
	return int(GameState.get_flag(DungeonState.keys_flag(&"crypt"), 0))


func _face(area: AreaController, cell: Vector2i, direction: Vector2) -> void:
	area.player.motor.place(cell)
	area.player.face(direction)
	area.update_room()


## Stands at `cell` facing `direction` and presses E (a chest, a door, a torch).
func _open(area: AreaController, cell: Vector2i, direction: Vector2) -> void:
	_face(area, cell, direction)
	assert_bool(area.interact()).override_failure_message("E at %s" % cell).is_true()


## Walks `direction` until the hero drops into a pit.
func _walk_into_the_pit(area: AreaController, direction: Vector2) -> void:
	for i: int in 60:
		area.player.motor.step(direction, FRAME)
		if area.is_in_pit():
			return
	assert_bool(area.is_in_pit()).override_failure_message("walked into the pit").is_true()


## Lets `seconds` pass for the area (falls, respawns, the dark).
func _wait(area: AreaController, seconds: float) -> void:
	for i: int in roundi(seconds / FRAME):
		area._process(FRAME)


## Lets `seconds` pass for every torch.
func _burn(area: AreaController, seconds: float) -> void:
	for i: int in roundi(seconds / FRAME):
		for child: Node in area.interactables.get_children():
			if child is Torch:
				(child as Torch)._process(FRAME)


## Swings the sword from `cell` toward `direction` and lets the blow land.
func _swing(area: AreaController, cell: Vector2i, direction: Vector2) -> void:
	_face(area, cell, direction)
	assert_bool(area.player.swing()).is_true()
	for i: int in roundi(0.4 / FRAME):
		area.player.motor.step(Vector2.ZERO, FRAME)
		area.player.sync_from_motor()
		area.resolve_combat()


## Steps from `off` onto `cell`, and the plates are checked.
func _walk_onto(area: AreaController, cell: Vector2i, off: Vector2i) -> void:
	_face(area, off, Vector2.UP)
	area.update_plates()
	_face(area, cell, Vector2.UP)
	area.update_plates()


## Lights the Knight's Tomb's torches, `gap` seconds apart: all four, or the first three.
func _light_the_knights_torches(area: AreaController, gap: float, only_three: bool = false) -> void:
	var spots: Array = [[Vector2i(42, 9), Vector2.RIGHT], [Vector2i(32, 9), Vector2.LEFT], [Vector2i(32, 1), Vector2.LEFT], [Vector2i(42, 5), Vector2.RIGHT]]
	for i: int in (3 if only_three else 4):
		if i > 0:
			_burn(area, gap)
		_open(area, spots[i][0], spots[i][1])


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
	for i: int in roundi(0.6 / FRAME):
		area.player.motor.step(Vector2.ZERO, FRAME)
		area.player.sync_from_motor()
		for child: Node in area.interactables.get_children():
			if child is Arrow:
				(child as Arrow).fly(FRAME)
		area.resolve_combat()


## Holds `direction` from `from` until `block` reaches `target`.
func _push(area: AreaController, block: PushBlock, from: Vector2i, direction: Vector2, target: Vector2i) -> void:
	_face(area, from, direction)
	for i: int in roundi(6.0 / FRAME):
		area.player.motor.step(direction, FRAME)
		area.player.sync_from_motor()
		area.update_pushing(FRAME)
		if block.cell() == target:
			return
	assert_that(block.cell()).override_failure_message("pushed to %s" % target).is_equal(target)


## Plays `seconds` with the Shade thinking (its touch left out: this is about the way through).
func _fight(area: AreaController, boss: ShadeBoss, seconds: float) -> void:
	for i: int in roundi(seconds / FRAME):
		area.player.motor.step(Vector2.ZERO, FRAME)
		area.player.sync_from_motor()
		boss.step(FRAME)


## Every cell the hero could walk to from `start` right now without falling (doors, blocks and
## pits in the way).
func _reachable(area: AreaController, start: Vector2i) -> Dictionary:
	var seen: Dictionary = {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_back()
		for side: Vector2i in SIDES:
			var next: Vector2i = cell + side
			if not seen.has(next) and not area.terrain.is_pit(next) and area.terrain.check_move(cell, next).is_allowed():
				seen[next] = true
				queue.append(next)
	return seen


## The pools of light the crypt's lighting last showed (the rule's lights, drawn).
func _pools(area: AreaController) -> Array:
	return area.lighting.shown.filter(func(one: Dictionary) -> bool: return one["kind"] == AreaLighting.POOL)
