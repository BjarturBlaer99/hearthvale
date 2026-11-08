extends GdUnitTestSuite
## Enemies (H3) in the South Field: the village's south road leads there and back; every enemy
## is set up from its data; each kind can be beaten with the sword and drops what its data's
## table says; touching an enemy hurts; the goblin archer shoots arrows that hurt and stop at
## solid tiles; and over a long stretch of play no enemy climbs a cliff, hops down a ledge or
## enters a solid tile.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const FIELD: String = "res://world/areas/south_field/south_field.tscn"
const VILLAGE: String = "res://world/areas/village/village.tscn"
const FRAME: float = 1.0 / 60.0
const BRAINS: Dictionary = {"hopper": "HopperBrain", "archer": "ArcherBrain", "flier": "FlierBrain"}

var _area: Node


func before_test() -> void:
	GameState.clear()
	GameState.new_game()


func after_test() -> void:
	if is_instance_valid(_area):
		_area.free()
	_area = null
	GameState.clear()


func test_the_south_road_leads_to_the_field_and_back() -> void:
	GameState.go_to(&"village", &"south_road")
	_area = Steps.load_area(VILLAGE)
	var village: AreaController = _area
	var outside: Vector2i = village.player.motor.cell
	var path: String = Steps.walk_until_travel(village, Vector2.DOWN)
	assert_str(path).is_equal(FIELD)
	_area = Steps.load_area(path, _area)
	var field: AreaController = _area
	assert_str(field.area_name).is_equal("South Field")
	assert_that(field.player.facing_direction()).is_equal(Vector2i.DOWN)
	path = Steps.walk_until_travel(field, Vector2.UP)
	assert_str(path).is_equal(VILLAGE)
	_area = Steps.load_area(path, _area)
	assert_that((_area as AreaController).player.motor.cell).override_failure_message("back on the south road").is_equal(outside)


func test_every_enemy_is_set_up_from_its_data() -> void:
	var field: AreaController = _field()
	var kinds: Dictionary = {}
	for enemy: Enemy in field.enemies():
		var data: Dictionary = DataRegistry.get_enemy(enemy.enemy_id)
		assert_dict(data).override_failure_message("%s names enemy '%s'" % [enemy.name, enemy.enemy_id]).is_not_empty()
		assert_object(enemy.brain).is_not_null()
		assert_int(enemy.brain.health).is_equal(int(data["health"]))
		assert_float(enemy.brain.speed).is_equal(float(data["speed"]))
		assert_int(enemy.hit_box.damage).is_equal(int(data["contact_damage"]))
		assert_str(enemy.brain.get_script().get_global_name()).is_equal(BRAINS[str(data["behaviour"])])
		kinds[String(enemy.enemy_id)] = true
	assert_array(kinds.keys()).contains_exactly_in_any_order(["slime", "goblin_archer", "bat"])


func test_each_kind_of_enemy_can_be_beaten_and_drops_what_its_data_says() -> void:
	GameState.add_item(&"wooden_sword")
	var field: AreaController = _field()
	# [enemy node, the drop roll, sword hits it takes]
	var cases: Array = [["SlimeA", 0.3, 1], ["GoblinArcher", 0.0, 2], ["BatA", 0.99, 1]]
	for case: Array in cases:
		var enemy: Enemy = field.interactables.get_node(NodePath(case[0]))
		var roll: float = case[1]
		enemy.roll_drop = func() -> float: return roll
		var swings: int = _beat(field, enemy)
		assert_bool(enemy.is_dead()).override_failure_message("%s beaten" % case[0]).is_true()
		assert_int(swings).override_failure_message("%s: sword hits needed" % case[0]).is_equal(case[2])
		var expected: Dictionary = DropTable.roll(enemy.data["drops"], roll)
		match str(expected.get("type", "")):
			"heart":
				assert_object(enemy.dropped).override_failure_message("%s drops a heart" % case[0]).is_instanceof(HeartPickup)
			"item":
				assert_object(enemy.dropped).is_instanceof(ItemDrop)
				assert_str(String((enemy.dropped as ItemDrop).item_id)).is_equal(str(expected["item"]))
				assert_int((enemy.dropped as ItemDrop).count).is_equal(int(expected.get("count", 1)))
			_:
				assert_object(enemy.dropped).override_failure_message("%s drops nothing" % case[0]).is_null()
	# The slime's coin and the goblin's three fell on the same spot: walking over it picks up all.
	var slime_coin: ItemDrop = (field.interactables.get_node(^"SlimeA") as Enemy).dropped
	var goblin_coins: ItemDrop = (field.interactables.get_node(^"GoblinArcher") as Enemy).dropped
	field.player.motor.place(GridBody.cell_of(slime_coin.position) + Vector2i.RIGHT)
	_play(field, Vector2.LEFT, 0.4)
	assert_int(GameState.item_count(&"coin")).is_equal(slime_coin.count + goblin_coins.count)


func test_touching_an_enemy_costs_half_a_heart() -> void:
	var field: AreaController = _field()
	var slime: Enemy = field.interactables.get_node(^"SlimeA")
	field.player.motor.place(slime.body.cell + Vector2i(2, 0))
	_play(field, Vector2.LEFT, 0.5)
	assert_int(GameState.health).is_equal(5)
	assert_bool(field.player.motor.is_invincible()).is_true()


func test_the_goblin_shoots_arrows_that_hurt_and_stop_at_solid_tiles() -> void:
	var field: AreaController = _field()
	var goblin: Enemy = field.interactables.get_node(^"GoblinArcher")
	# Lined up below it on the plateau, in range: it draws and shoots by itself.
	field.player.motor.place(goblin.body.cell + Vector2i(0, 3))
	field.player.sync_from_motor()
	for i: int in roundi(3.0 / FRAME):
		goblin.step(FRAME)
		if goblin.last_arrow != null:
			break
	assert_object(goblin.last_arrow).override_failure_message("it shot").is_not_null()
	var arrow: Arrow = goblin.last_arrow
	for i: int in roundi(1.5 / FRAME):
		if not arrow.fly(FRAME):
			break
		field.resolve_combat()
	assert_int(GameState.health).override_failure_message("the arrow hurts").is_equal(5)
	assert_bool(arrow.stopped).is_true()

	# Shot at the tree beside it, an arrow stops there.
	goblin.body.place(Vector2i(32, 4))
	goblin.position = goblin.body.position
	goblin.brain.shot.emit(Vector2.RIGHT)
	arrow = goblin.last_arrow
	var flew: int = 0
	while arrow.fly(FRAME):
		flew += 1
		assert_int(flew).override_failure_message("still flying").is_less(120)
	assert_int(GridBody.cell_of(arrow.position).x).override_failure_message("stopped in the tree").is_equal(33)


func test_no_enemy_climbs_a_cliff_hops_down_a_ledge_or_enters_a_solid_tile() -> void:
	var field: AreaController = _field()
	field.rng.seed = 11
	# The hero waits below the plateau's south ledge, in the goblin's sight.
	field.player.motor.place(Vector2i(31, 13))
	field.player.sync_from_motor()
	var levels: Dictionary = {}
	for enemy: Enemy in field.enemies():
		levels[enemy] = enemy.body.level
	var grid: HeightGrid = field.grid
	for i: int in roundi(12.0 / FRAME):
		for enemy: Enemy in field.enemies():
			enemy.step(FRAME)
			var cell: Vector2i = enemy.body.cell
			assert_bool(grid.in_bounds(cell) and not grid.is_solid(cell)).override_failure_message("%s at %s" % [enemy.name, cell]).is_true()
			if not enemy.body.flying:
				assert_int(enemy.body.level).override_failure_message("%s keeps to its level" % enemy.name).is_equal(levels[enemy])
	var goblin: Enemy = field.interactables.get_node(^"GoblinArcher")
	assert_int(goblin.body.level).override_failure_message("the goblin is still on the plateau").is_equal(2)


func _field() -> AreaController:
	_area = Steps.load_area(FIELD, _area)
	return _area


## Swings at `enemy` (moved to an open cell, with the hero below it facing up) until it falls.
## Between swings the enemy recovers from the blow. Returns the swings it took.
func _beat(area: AreaController, enemy: Enemy) -> int:
	var spot: Vector2i = Vector2i(20, 9)
	for swing: int in range(1, 8):
		enemy.body.place(spot)
		enemy.position = enemy.body.position
		area.player.motor.place(spot + Vector2i.DOWN)
		area.player.face(Vector2.UP)
		area.player.swing()
		_play(area, Vector2.ZERO, 0.35)
		if enemy.is_dead():
			return swing
		for i: int in roundi(0.5 / FRAME):
			enemy.step(FRAME)
	return -1


## Plays `seconds` of the area frame by frame without the engine loop: the hero steps, the
## area resolves hits and pickups. Enemies stay where they are.
func _play(area: AreaController, input: Vector2, seconds: float) -> void:
	for i: int in roundi(seconds / FRAME):
		area.player.motor.step(input, FRAME)
		area.player.sync_from_motor()
		area.resolve_combat()
		area.collect_pickups()
