extends GdUnitTestSuite
## Energy in the world (P2c): the bar on the HUD; sprinting, swinging and shooting cost energy;
## tired, the hero is slower; out of energy he collapses and wakes at home, poorer. None of it
## ever touches a heart.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const VILLAGE: String = "res://world/areas/village/village.tscn"
const KEEP: String = "res://world/areas/keep/keep.tscn"
const HOME: String = "res://world/areas/home/home.tscn"
const TEST_SLOT: int = 986
const STEP: float = 1.0 / 60.0
## A spot on Hearthvale's east-west road with a long clear run to the east.
const ON_THE_ROAD: Vector2i = Vector2i(5, 16)

var _area: Node
var _rules: EnergyRules


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	SaveSystem.current_slot = TEST_SLOT
	_rules = GameState.energy_rules()


func after_test() -> void:
	for action: StringName in [&"sprint", &"move_right", &"attack"]:
		Input.action_release(action)
	if is_instance_valid(_area):
		_area.free()
	_area = null
	if SaveSystem.has_slot(TEST_SLOT):
		DirAccess.remove_absolute(SaveSystem.slot_path(TEST_SLOT))
	SaveSystem.current_slot = SaveSystem.GAME_SLOT
	GameState.clear()


func test_the_hud_shows_the_bar_and_it_follows_his_energy() -> void:
	var village: AreaController = _load(VILLAGE)
	var hud: AreaHud = village.hud
	assert_bool(hud.energy.visible).override_failure_message("the bar shows, under the hearts").is_true()
	assert_float(hud.energy.fraction()).is_equal(1.0)
	GameState.spend_energy(40.0)
	assert_float(hud.energy.fraction()).is_equal_approx(0.6, 0.001)
	assert_bool(hud.energy.is_low()).is_false()
	GameState.set_energy(20.0)
	assert_bool(hud.energy.is_low()).override_failure_message("the bar turns where he tires").is_true()
	assert_float(EnergyBar.LOW * GameState.max_energy()).override_failure_message("the bar's low mark is the rules'").is_equal(_rules.low_below)
	# A game loaded with less shows less from the start.
	GameState.set_energy(33.0)
	var home: AreaController = _load(HOME)
	assert_float(home.hud.energy.fraction()).is_equal_approx(0.33, 0.001)


func test_sprinting_costs_energy_only_while_he_runs() -> void:
	var village: AreaController = _load(VILLAGE)
	village.player.motor.place(ON_THE_ROAD)
	Input.action_press(&"move_right")
	_run(village, 1.0)
	assert_float(GameState.energy).override_failure_message("walking is free").is_equal(GameState.max_energy())
	Input.action_press(&"sprint")
	_run(village, 2.0)
	assert_bool(village.player.motor.sprinting).is_true()
	assert_float(GameState.max_energy() - GameState.energy).override_failure_message("two seconds of running").is_equal_approx(2.0 * _rules.cost(EnergyRules.SPRINT), 0.02)
	Input.action_release(&"move_right")
	var standing: float = GameState.energy
	_run(village, 1.0)
	assert_float(GameState.energy).override_failure_message("holding sprint while standing costs nothing").is_equal(standing)
	assert_int(GameState.health).override_failure_message("hearts are untouched").is_equal(GameState.max_health())


func test_tired_he_is_slower_and_worn_out_he_cannot_run() -> void:
	var village: AreaController = _load(VILLAGE)
	Input.action_press(&"move_right")
	GameState.set_energy(60.0)
	var rested: float = _distance_in_a_second(village)
	assert_float(rested).override_failure_message("a second's walk").is_equal_approx(PlayerMotor.WALK_SPEED, 1.5)
	GameState.set_energy(_rules.low_below)
	assert_float(_distance_in_a_second(village)).override_failure_message("at 25 he isn't tired yet").is_equal_approx(rested, 0.01)
	GameState.spend_energy(0.1)
	assert_str(village.hud.message_text()).override_failure_message("a line says so as he tires").is_equal(AreaController.TIRED_WORDS)
	assert_float(_distance_in_a_second(village) / rested).override_failure_message("tired: 85% of his speed").is_equal_approx(_rules.low_move, 0.02)
	# Tired, he can still run, at the same share of his speed, and it still costs.
	Input.action_press(&"sprint")
	var before: float = GameState.energy
	assert_float(_distance_in_a_second(village) / PlayerMotor.SPRINT_SPEED).is_equal_approx(_rules.low_move, 0.02)
	assert_float(GameState.energy).is_less(before)
	# Under 10 he can't.
	GameState.set_energy(_rules.no_sprint_below - 0.5)
	assert_str(village.hud.message_text()).is_equal(AreaController.WORN_OUT_WORDS)
	before = GameState.energy
	assert_float(_distance_in_a_second(village) / rested).override_failure_message("sprint held, but he walks").is_equal_approx(_rules.low_move, 0.02)
	assert_bool(village.player.motor.sprinting).is_false()
	assert_float(GameState.energy).override_failure_message("and walking costs nothing").is_equal(before)
	assert_int(GameState.health).is_equal(GameState.max_health())


func test_a_swing_and_a_shot_cost_energy_and_a_bomb_does_not() -> void:
	GameState.add_item(&"wooden_sword")
	GameState.add_item(&"bow")
	GameState.add_item(&"arrow", 5)
	GameState.add_item(&"bomb", 2)
	var village: AreaController = _load(VILLAGE)
	var cooldown: float = float(CombatRules.weapon_stats(PlayerController.best_sword())["cooldown"])
	assert_bool(village.player.swing()).is_true()
	assert_float(GameState.max_energy() - GameState.energy).override_failure_message("a swing").is_equal(_rules.cost(EnergyRules.SWING))
	assert_float((village.player.motor.state as PlayerAttackState).duration).override_failure_message("rested, the sword is as quick as it was").is_equal_approx(cooldown, 0.0001)
	_finish_swing(village)
	GameState.set_energy(20.0)
	assert_bool(village.player.swing()).is_true()
	assert_float((village.player.motor.state as PlayerAttackState).duration).override_failure_message("tired, it is 30% slower to be ready").is_equal_approx(cooldown * _rules.low_cooldown, 0.0001)
	assert_float(GameState.energy).is_equal(20.0 - _rules.cost(EnergyRules.SWING))
	_finish_swing(village)
	GameState.equip(&"bow")
	var before: float = GameState.energy
	assert_bool(village.use_item()).is_true()
	assert_float(before - GameState.energy).override_failure_message("a shot").is_equal(_rules.cost(EnergyRules.SHOT))
	assert_int(GameState.item_count(&"arrow")).is_equal(4)
	_finish_swing(village)
	GameState.equip(&"bomb")
	before = GameState.energy
	assert_bool(village.use_item()).is_true()
	assert_float(GameState.energy).override_failure_message("a bomb is free").is_equal(before)
	assert_int(GameState.health).override_failure_message("hearts are untouched").is_equal(GameState.max_health())


func test_out_of_energy_he_collapses_and_wakes_at_home_poorer() -> void:
	GameState.add_item(&"wooden_sword")
	GameState.add_item(&"coin", 55)
	GameState.damage(2)
	var hearts: int = GameState.health
	var village: AreaController = _load(VILLAGE)
	var travelled: Array[String] = []
	village.travel = func(path: String) -> void: travelled.append(path)
	GameState.set_energy(0.4)
	assert_bool(village.player.swing()).override_failure_message("his last swing").is_true()
	assert_bool(GameState.is_exhausted()).is_true()
	village._process(STEP)
	assert_bool(village.is_collapsing()).is_true()
	assert_bool(village.player.is_lying()).is_true()
	village.player.sync_from_motor()
	assert_int(int(village.player.shown_region().position.x) / PlayerAnimator.FRAME_SIZE.x).override_failure_message("he lies where he fell").is_equal(PlayerAnimator.FALLEN)
	assert_bool(village.player.controls_enabled).is_false()
	assert_bool(village.player.hurt_box.enabled).override_failure_message("nothing can hurt him as he lies").is_false()
	assert_str(village.hud.message_text()).is_equal(AreaController.SPENT_WORDS)
	assert_bool(village.clock_runs()).is_false()
	assert_bool(village.interact()).override_failure_message("he can do nothing").is_false()
	assert_array(travelled).override_failure_message("not yet").is_empty()
	village._process(AreaController.COLLAPSE_TIME + 0.1)
	assert_array(travelled).is_equal([WorldPaths.scene_for(WorldPaths.HOME_AREA)])
	assert_dict(GameState.player).is_equal({"area": "home", "entry": "bed"})
	assert_int(GameState.day).override_failure_message("the next morning").is_equal(2)
	assert_float(GameState.minute).is_equal(float(GameState.day_clock().starts))
	assert_float(GameState.energy).override_failure_message("half his energy").is_equal(_rules.wake_energy())
	assert_int(GameState.item_count(&"coin")).override_failure_message("a tenth of his coins gone").is_equal(50)
	assert_int(GameState.health).override_failure_message("hearts are untouched").is_equal(hearts)
	assert_str(GameState.arrival_notice).is_equal(AreaController.COLLAPSED_WORDS + AreaController.COINS_LOST_WORDS % 5)
	assert_bool(SaveSystem.has_slot(TEST_SLOT)).override_failure_message("saved").is_true()
	village._process(1.0)
	assert_int(travelled.size()).override_failure_message("once").is_equal(1)
	# At home he is told, and the bar shows half.
	var home: AreaController = _load(HOME)
	assert_str(home.hud.message_text()).contains("collapsed")
	assert_float(home.hud.energy.fraction()).is_equal_approx(0.5, 0.001)
	home._process(STEP)
	assert_bool(home.is_collapsing()).is_false()


func test_it_can_happen_in_a_dungeon_and_what_was_done_there_stays_done() -> void:
	GameState.set_flag(&"dungeon/keep/door/hall_door", true)
	GameState.add_item(&"coin", 9)
	var keep: AreaController = _load(KEEP)
	var travelled: Array[String] = []
	keep.travel = func(path: String) -> void: travelled.append(path)
	GameState.set_energy(0.0)
	keep._process(STEP)
	assert_bool(keep.is_collapsing()).is_true()
	keep._process(AreaController.COLLAPSE_TIME + 0.1)
	assert_array(travelled).is_equal([WorldPaths.scene_for(WorldPaths.HOME_AREA)])
	assert_int(GameState.day).override_failure_message("the next morning, though no clock runs underground").is_equal(2)
	assert_bool(GameState.get_flag(&"dungeon/keep/door/hall_door") == true).override_failure_message("the door he opened stays open").is_true()
	assert_int(GameState.item_count(&"coin")).override_failure_message("a tenth of nine coins is none").is_equal(9)
	assert_str(GameState.arrival_notice).override_failure_message("so nothing is said of coins").is_equal(AreaController.COLLAPSED_WORDS)


func test_staying_up_until_two_costs_what_collapsing_costs() -> void:
	GameState.add_item(&"coin", 400)
	var village: AreaController = _load(VILLAGE)
	var travelled: Array[String] = []
	village.travel = func(path: String) -> void: travelled.append(path)
	GameState.set_energy(80.0)
	var clock: DayClock = GameState.day_clock()
	GameState.set_time(float(clock.ends) - 0.5)
	village._process(clock.seconds_per_hour / 60.0)
	assert_int(travelled.size()).is_equal(1)
	assert_float(GameState.energy).override_failure_message("half a bar, whatever he had").is_equal(_rules.wake_energy())
	assert_int(GameState.item_count(&"coin")).override_failure_message("thirty coins at most").is_equal(370)
	assert_str(GameState.arrival_notice).is_equal(AreaController.WOKE_LATE_WORDS + AreaController.COINS_LOST_WORDS % 30)


func test_dying_costs_no_energy_and_no_coins() -> void:
	GameState.add_item(&"coin", 40)
	var village: AreaController = _load(VILLAGE)
	GameState.set_energy(70.0)
	GameState.damage(99)
	assert_bool(village.is_dying()).is_true()
	village._process(AreaController.RESPAWN_DELAY + 0.1)
	assert_bool(village.is_dying()).is_false()
	assert_float(GameState.energy).is_equal(70.0)
	assert_int(GameState.item_count(&"coin")).is_equal(40)
	assert_int(GameState.day).is_equal(1)


## Lets `seconds` of physics frames pass for the hero.
func _run(area: AreaController, seconds: float) -> void:
	for i: int in roundi(seconds / STEP):
		area.player._physics_process(STEP)


## How far east the hero gets in a second from the same spot on the road, with the keys held
## as they are.
func _distance_in_a_second(area: AreaController) -> float:
	area.player.motor.place(ON_THE_ROAD)
	var from: float = area.player.motor.position.x
	_run(area, 1.0)
	return area.player.motor.position.x - from


func _finish_swing(area: AreaController) -> void:
	for i: int in 240:
		if not area.player.motor.is_attacking():
			return
		area.player.motor.step(Vector2.ZERO, STEP)
	area.player.sync_from_motor()


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area
