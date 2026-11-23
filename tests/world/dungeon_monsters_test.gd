extends GdUnitTestSuite
## Monsters met in a dungeon are tougher (dungeon-difficulty-plan.md, decision 1): the area
## tells each where it is, and it is set up by that place's numbers (data/rules/dungeon.json).
## Out of doors they are as they were. The bosses have their own, tougher numbers (decisions 4
## and 5), and the Shade's braziers burn out.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const KEEP: String = "res://world/areas/keep/keep.tscn"
const CRYPT: String = "res://world/areas/crypt/crypt.tscn"
const WOOD: String = "res://world/areas/old_wood/old_wood.tscn"

var _area: Node


func before_test() -> void:
	GameState.clear()
	GameState.new_game()


func after_test() -> void:
	if is_instance_valid(_area):
		_area.free()
	_area = null
	GameState.clear()


func test_a_slime_in_the_keep_takes_two_blows_and_one_in_the_wood_one() -> void:
	GameState.go_to(&"keep", &"entrance")
	var keep: AreaController = _load(KEEP)
	var slime: Enemy = keep.interactables.get_node(^"EntranceSlimeA")
	assert_that(slime.place).is_equal(&"keep")
	assert_int(slime.brain.health).is_equal(3)
	assert_int(slime.hit_box.damage).override_failure_message("half a heart, as in the fields").is_equal(1)
	var archer: Enemy = keep.interactables.get_node(^"HallArcher")
	assert_int(archer.brain.health).is_equal(6)
	GameState.minute = 12 * 60
	GameState.go_to(&"old_wood", &"keep_gate")
	var wood: AreaController = _load(WOOD)
	for enemy: Enemy in wood.enemies():
		if enemy.enemy_id == &"slime":
			assert_int(enemy.brain.health).override_failure_message("by day in the wood").is_equal(2)
			return
	fail("the Old Wood has a slime")


func test_in_the_crypt_a_touch_costs_a_whole_heart() -> void:
	GameState.go_to(&"crypt", &"entrance")
	var crypt: AreaController = _load(CRYPT)
	var slime: Enemy = crypt.interactables.get_node(^"HallSlimeA")
	assert_int(slime.brain.health).is_equal(4)
	assert_int(slime.hit_box.damage).is_equal(2)


func test_the_bosses_are_tougher_and_hit_for_a_whole_heart() -> void:
	var warden: Dictionary = DataRegistry.get_enemy(&"iron_warden")
	assert_int(int(warden["health"])).override_failure_message("nine wooden-sword blows").is_equal(18)
	assert_int(int(warden["contact_damage"])).is_equal(2)
	assert_int(int(warden["boss"]["rage_at"])).override_failure_message("at half, as before").is_equal(9)
	assert_float(float(warden["boss"]["gaze_time"])).is_equal_approx(1.6, 0.001)
	assert_float(float(warden["boss"]["stun_time"])).is_equal_approx(2.4, 0.001)
	var shade: Dictionary = DataRegistry.get_enemy(&"crypt_shade")
	assert_int(int(shade["health"])).override_failure_message("eight iron-sword blows").is_equal(22)
	assert_int(int(shade["contact_damage"])).is_equal(2)
	assert_int(int(shade["boss"]["rage_at"])).is_equal(11)
	assert_float(float(shade["boss"]["bound_time"])).is_equal_approx(2.4, 0.001)
	assert_float(float(shade["boss"]["bolt_every"])).is_equal_approx(2.0, 0.001)


func test_the_shades_braziers_burn_ten_seconds() -> void:
	GameState.go_to(&"crypt", &"entrance")
	var crypt: AreaController = _load(CRYPT)
	var shade: ShadeBoss = crypt.interactables.get_node(^"Shade")
	var braziers: Array[Torch] = shade.braziers()
	assert_array(braziers).has_size(4)
	for torch: Torch in braziers:
		assert_float(torch.burn_time).is_equal_approx(10.0, 0.001)
	# Lit, one goes out by itself once its ten seconds are up, and the Shade is no longer held.
	GameState.add_item(&"lantern")
	for torch: Torch in braziers:
		torch.light()
	assert_bool(shade.all_lit()).is_true()
	braziers[0]._process(9.9)
	assert_bool(braziers[0].is_lit()).is_true()
	braziers[0]._process(0.2)
	assert_bool(braziers[0].is_lit()).is_false()
	assert_bool(shade.all_lit()).is_false()


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area
