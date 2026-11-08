extends GdUnitTestSuite
## Hearthvale, the starting village: a new game starts in the square with three hearts, the
## hearts on the HUD follow the hero's health, the layout keeps its promises (stairs, a
## one-way ledge, solid buildings, a way out), standing on an item picks it up, and the
## welcome sign reads from data.

const SCENE: String = "res://world/areas/village/village.tscn"
const SPAWN: Vector2i = Vector2i(23, 20)
const SIDES: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]


func before_test() -> void:
	GameState.clear()


func after_test() -> void:
	GameState.clear()


func test_a_new_game_starts_in_the_village_square_with_three_hearts() -> void:
	var area: AreaController = await _village()
	assert_that(area.player.motor.cell).is_equal(SPAWN)
	assert_int(GameState.health).is_equal(6)
	assert_that(area.hud.hearts.describe()).is_equal(Vector3i(3, 0, 0))
	assert_that(str(GameState.player["area"])).is_equal("village")


func test_the_hearts_follow_the_heros_health() -> void:
	var area: AreaController = await _village()
	GameState.damage(1)
	assert_that(area.hud.hearts.describe()).is_equal(Vector3i(2, 1, 0))
	GameState.damage(2)
	assert_that(area.hud.hearts.describe()).is_equal(Vector3i(1, 1, 1))
	GameState.add_heart_container()
	assert_that(area.hud.hearts.describe()).is_equal(Vector3i(4, 0, 0))


func test_the_layout_has_stairs_a_one_way_ledge_solid_buildings_and_a_way_out() -> void:
	var scene: Node = auto_free((load(SCENE) as PackedScene).instantiate())
	var query: TerrainQuery = TerrainQuery.new(HeightGridBuilder.from_layer(scene.get_node("Height")))
	var reachable: Dictionary = _reachable(query, SPAWN)
	print("  village: %d cells reachable on foot from the square" % reachable.size())
	assert_bool(reachable.has(Vector2i(10, 4))).override_failure_message("north rise, by its stairs").is_true()
	assert_int(query.grid.height_at(Vector2i(10, 4))).is_equal(2)
	assert_bool(reachable.has(Vector2i(42, 20))).override_failure_message("east meadow, by its stairs").is_true()
	assert_bool(reachable.has(Vector2i(23, 35))).override_failure_message("the south road out").is_true()
	assert_that(query.check_move(Vector2i(38, 16), Vector2i(37, 16)).kind).is_equal(MoveResult.Kind.DROP)
	assert_that(query.check_move(Vector2i(37, 16), Vector2i(38, 16)).kind).override_failure_message("the ledge is one way").is_equal(MoveResult.Kind.BLOCKED)
	for solid: Vector2i in [Vector2i(8, 12), Vector2i(17, 14), Vector2i(24, 3), Vector2i(18, 19), Vector2i(30, 27), Vector2i(0, 20)]:
		assert_bool(query.grid.is_solid(solid)).override_failure_message("%s is solid" % solid).is_true()
		assert_bool(reachable.has(solid)).override_failure_message("%s can't be entered" % solid).is_false()


func test_standing_on_an_item_and_using_it_picks_it_up() -> void:
	var area: AreaController = await _village()
	var pickup: ItemPickup = ItemPickup.new()
	pickup.item_id = &"small_key"
	pickup.taken_flag = &"test_village_key_taken"
	pickup.position = Vector2(area.player.motor.cell) * PlayerMotor.TILE
	area.interactables.add_child(pickup)
	assert_object(area.pickup_under_player()).is_same(pickup)
	assert_bool(area.interact()).is_true()
	assert_int(GameState.item_count(&"small_key")).is_equal(1)
	assert_bool(GameState.get_flag(&"test_village_key_taken")).is_true()
	assert_object(area.pickup_under_player()).override_failure_message("nothing left to pick up").is_null()
	assert_bool(area.interact()).is_false()


func test_the_welcome_sign_reads_from_data_and_stands_in_its_cell() -> void:
	var area: AreaController = await _village()
	var sign: Signpost = area.interactables.get_node(^"WelcomeSign")
	area.player.motor.place(sign.cell() + Vector2i.DOWN)
	area.player.face(Vector2.UP)
	assert_object(area.talkable_in_front()).is_same(sign)
	assert_str(sign.prompt()).is_equal("Read the sign")
	assert_bool(area.interact()).is_true()
	var box: DialogueBox = area.hud.dialogue
	assert_bool(box.is_open()).is_true()
	assert_str(box.shown_name()).override_failure_message("a sign has no speaker").is_empty()
	assert_str(box.shown_text()).is_equal(str(DataRegistry.get_dialogue(&"sign_welcome")["nodes"]["read"]["text"]))
	assert_array(Array(box.shown_options())).is_empty()
	box.confirm()
	assert_bool(box.is_open()).override_failure_message("interact closes a sign").is_false()
	assert_str(area.terrain.check_move(sign.cell() + Vector2i.DOWN, sign.cell()).reason).is_equal("occupied")


func _village() -> AreaController:
	var runner: GdUnitSceneRunner = scene_runner(SCENE)
	await runner.simulate_frames(1)
	return runner.scene()


func _reachable(query: TerrainQuery, start: Vector2i) -> Dictionary:
	var seen: Dictionary = {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_back()
		for side: Vector2i in SIDES:
			var next: Vector2i = cell + side
			if not seen.has(next) and query.check_move(cell, next).is_allowed():
				seen[next] = true
				queue.append(next)
	return seen
