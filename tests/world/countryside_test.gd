extends GdUnitTestSuite
## The countryside (H8): the road runs from the village through the North Fields and the Old
## Wood to the keep's gate, and back. Two optional secrets: a gap in the fields' tree line leads
## to a hidden meadow with a chest of bombs, and a bombable crack in the wood's walled shrine
## opens the way to a heart piece. Both areas have enemies.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const VILLAGE: String = "res://world/areas/village/village.tscn"
const FIELDS: String = "res://world/areas/north_fields/north_fields.tscn"
const WOOD: String = "res://world/areas/old_wood/old_wood.tscn"
const KEEP: String = "res://world/areas/keep/keep.tscn"
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


func test_the_road_runs_from_the_village_to_the_keep_and_back() -> void:
	# [area scene, exit to take, where it leads]
	var north: Array = [[VILLAGE, "NorthRoad", FIELDS], [FIELDS, "NorthRoad", WOOD], [WOOD, "KeepGate", KEEP]]
	var south: Array = [[KEEP, "Gate", WOOD], [WOOD, "SouthRoad", FIELDS], [FIELDS, "SouthRoad", VILLAGE]]
	var area: AreaController = _load(VILLAGE)
	for leg: Array in north + south:
		assert_str(area.scene_file_path).is_equal(leg[0])
		var next: String = _take(area, leg[1])
		assert_str(next).override_failure_message("%s's %s" % [area.area_name, leg[1]]).is_equal(leg[2])
		area = _load(next)
	assert_str(area.area_name).is_equal("Hearthvale")
	assert_that(area.player.motor.cell).override_failure_message("back where the north road comes in").is_equal(Vector2i(36, 1))


func test_secret_one_a_gap_in_the_tree_line_hides_a_meadow_with_bombs() -> void:
	GameState.go_to(&"north_fields", &"south_road")
	var fields: AreaController = _load(FIELDS)
	var reachable: Dictionary = _reachable(fields, fields.player.motor.cell)
	assert_bool(reachable.has(Vector2i(5, 5))).override_failure_message("the meadow can be reached").is_true()
	# Off the road: a narrow path through the thicket, its mouth beside the road.
	for side: Vector2i in [Vector2i.UP, Vector2i.DOWN]:
		assert_bool(fields.grid.is_solid(Vector2i(10, 5) + side)).override_failure_message("a path one tree wide").is_true()
	assert_bool(fields.grid.is_solid(Vector2i(13, 5))).is_false()
	assert_int(fields.grid.height_at(Vector2i(14, 5))).is_equal(0)
	fields.player.motor.place(Vector2i(5, 5))
	fields.player.face(Vector2.UP)
	assert_bool(fields.interact()).is_true()
	assert_int(GameState.item_count(&"bomb")).is_equal(5)
	assert_bool(GameState.get_flag(&"dungeon/north_fields/chest/meadow_bombs") == true).override_failure_message("outdoors, a chest's flag is named by its area").is_true()
	assert_that(GameState.equipped).is_equal(&"bomb")
	fields = _load(FIELDS)
	fields.player.motor.place(Vector2i(5, 5))
	fields.player.face(Vector2.UP)
	assert_bool(fields.interact()).override_failure_message("opened for good").is_false()


func test_secret_two_a_bomb_opens_the_shrine_and_its_heart_piece_counts_toward_a_heart() -> void:
	GameState.add_item(&"wooden_sword")
	GameState.add_item(&"bomb", 1)
	GameState.go_to(&"old_wood", &"south_road")
	var wood: AreaController = _load(WOOD)
	var piece: HeartPiece = wood.interactables.get_node(^"HeartPiece")
	var wall: DungeonDoor = wood.interactables.get_node(^"ShrineWall")
	var start: Vector2i = wood.player.motor.cell
	assert_bool(_reachable(wood, start).has(piece.cell())).override_failure_message("walled in").is_false()
	assert_bool(_reachable(wood, start).has(Vector2i(29, 13))).override_failure_message("the crack can be reached").is_true()
	_face(wood, Vector2i(29, 13), Vector2.RIGHT)
	wood.player.swing()
	_play(wood, 0.4)
	assert_bool(wall.is_open()).override_failure_message("a sword doesn't break it").is_false()
	assert_bool(wood.use_item()).is_true()
	_play(wood, 2.5)
	assert_bool(wall.is_open()).override_failure_message("a bomb does").is_true()
	assert_bool(_reachable(wood, start).has(piece.cell())).is_true()
	assert_int(GameState.health).override_failure_message("the hero's own bomb spares them").is_equal(GameState.max_health())
	wood.player.motor.place(piece.cell())
	wood.player.sync_from_motor()
	assert_int(wood.collect_pickups()).is_equal(1)
	assert_int(GameState.heart_pieces).is_equal(1)
	assert_int(GameState.hearts_max).override_failure_message("one piece isn't a heart yet").is_equal(3)
	assert_str((wood.hud.get_node(^"Message") as Label).text).contains("1 of 4")
	wood = _load(WOOD)
	assert_bool((wood.interactables.get_node(^"ShrineWall") as DungeonDoor).is_open()).override_failure_message("still open").is_true()
	assert_bool((wood.interactables.get_node(^"HeartPiece") as HeartPiece).is_there()).override_failure_message("taken for good").is_false()


func test_the_countryside_has_enemies_on_open_ground() -> void:
	for path: String in [FIELDS, WOOD]:
		var area: AreaController = _load(path)
		var kinds: Dictionary = {}
		for enemy: Enemy in area.enemies():
			assert_object(enemy.brain).override_failure_message("%s set up" % enemy.name).is_not_null()
			assert_bool(area.grid.is_solid(enemy.body.cell)).override_failure_message("%s on open ground" % enemy.name).is_false()
			kinds[String(enemy.enemy_id)] = true
		assert_int(area.enemies().size()).override_failure_message(area.area_name).is_greater_equal(5)
		assert_bool(kinds.has("goblin_archer") and kinds.size() >= 2).override_failure_message("%s: more than one kind" % area.area_name).is_true()


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area


func _face(area: AreaController, cell: Vector2i, direction: Vector2) -> void:
	area.player.motor.place(cell)
	area.player.face(direction)


## Walks the hero from where they stand to the exit named `exit_name` (checking it can be
## reached), then onto it. Returns the scene it leads to ("" if the hero never left).
func _take(area: AreaController, exit_name: String) -> String:
	var exit: AreaExit = area.interactables.get_node(NodePath(exit_name))
	var reachable: Dictionary = _reachable(area, area.player.motor.cell)
	for side: Vector2i in SIDES:
		var from: Vector2i = exit.cell() - side
		if reachable.has(from) and not exit.covers(from) and area.terrain.check_move(from, exit.cell()).is_allowed():
			area.player.motor.place(from)
			return Steps.walk_until_travel(area, Vector2(side))
	assert_bool(false).override_failure_message("%s: %s can't be reached" % [area.area_name, exit_name]).is_true()
	return ""


## Plays `seconds`: the hero stands, arrows fly, bombs burn, hits land.
func _play(area: AreaController, seconds: float) -> void:
	for i: int in roundi(seconds / FRAME):
		area.player.motor.step(Vector2.ZERO, FRAME)
		area.player.sync_from_motor()
		for child: Node in area.interactables.get_children():
			if child is Arrow:
				(child as Arrow).fly(FRAME)
			elif child is Bomb:
				(child as Bomb).tick(FRAME)
		area.resolve_combat()


## Every cell the hero could walk to from `start` right now.
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
