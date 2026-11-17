extends GdUnitTestSuite
## The marsh by night (Willowmere, step 2): Bogwisps. By day there are none; as night falls they
## rise over the pools. A wisp's touch takes half a heart and a chunk of energy. Without the
## Lantern a blow passes through it; inside the Lantern's light it has a body, and two blows
## beat it and leave a Wisp Ember where the hero can reach it. When the night ends, any left
## fade and leave nothing. The mist is thicker at night.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const MARSH: String = "res://world/areas/willowmere/willowmere.tscn"
const FRAME: float = 1.0 / 60.0
const WISPS: Array[String] = ["BogwispA", "BogwispB", "BogwispC", "BogwispD", "BogwispE"]
## On the west boardwalk, and the pool cell beside it.
const ON_THE_BOARDS: Vector2i = Vector2i(11, 14)
const OVER_THE_POOL: Vector2i = Vector2i(11, 13)

var _area: Node
var _heard: Array[StringName] = []


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	Quests.refresh()
	GameState.add_item(&"wooden_sword")
	_heard.clear()
	EventBus.sound.connect(_on_sound)


func after_test() -> void:
	EventBus.sound.disconnect(_on_sound)
	if is_instance_valid(_area):
		_area.free()
	_area = null
	GameState.clear()


func test_the_bogwisp_is_data_and_always_leaves_an_ember() -> void:
	var data: Dictionary = DataRegistry.get_enemy(&"bogwisp")
	assert_str(str(data["name"])).is_equal("Bogwisp")
	assert_str(str(data["behaviour"])).is_equal("wisp")
	assert_str(str(data["appears"])).is_equal("night")
	assert_int(int(data["health"])).override_failure_message("two blows of either sword: 2 + 2, or 3 + 3").is_equal(4)
	assert_int(int(data["contact_damage"])).override_failure_message("half a heart").is_equal(1)
	assert_float(float(data["energy_drain"])).is_equal(15.0)
	assert_float(float(data["wisp"]["flare"])).override_failure_message("half a second of warning").is_equal(0.5)
	for roll: float in [0.0, 0.25, 0.5, 0.75, 0.999]:
		var drop: Dictionary = DropTable.roll(data["drops"], roll)
		assert_str(str(drop.get("item", ""))).override_failure_message("roll %s" % roll).is_equal("wisp_ember")
	var ember: Dictionary = DataRegistry.get_item(&"wisp_ember")
	assert_str(str(ember["type"])).override_failure_message("for the hearth and for Henrik: it can't be eaten").is_equal("ingredient")
	GameState.add_item(&"wisp_ember")
	assert_bool(GameState.eat(&"wisp_ember")).is_false()
	assert_int(GameState.item_count(&"wisp_ember")).is_equal(1)
	assert_that(ItemIcons.name_for(&"wisp_ember")).is_equal(&"wisp_ember")
	assert_array(Array(DataRegistry.errors)).override_failure_message("the data loads clean").is_empty()


func test_the_night_does_not_make_a_thing_of_the_night_tougher() -> void:
	var data: Dictionary = DataRegistry.get_enemy(&"bogwisp")
	var rules: NightRules = NightRules.new(DataRegistry.get_rules(DataRegistry.RULES_NIGHT))
	assert_bool(NightRules.is_of_the_night(data)).is_true()
	assert_bool(NightRules.is_of_the_night(DataRegistry.get_enemy(&"slime"))).is_false()
	assert_dict(rules.strengthen(data)).override_failure_message("its numbers are its night's already").is_equal(data)
	assert_int(int(rules.strengthen(DataRegistry.get_enemy(&"slime"))["health"])).override_failure_message("a slime still is").is_equal(3)
	var marsh: AreaController = _marsh("22:00")
	var wisp: Enemy = _wisp(marsh, "BogwispA")
	assert_int(wisp.brain.max_health).is_equal(4)
	assert_float(wisp.brain.speed).is_equal(22.0)
	assert_that(wisp.modulate).override_failure_message("no night's tint on a light").is_equal(Color.WHITE)


func test_by_day_there_are_none() -> void:
	var marsh: AreaController = _marsh("12:00")
	for name: String in WISPS:
		var wisp: Enemy = _wisp(marsh, name)
		assert_bool(wisp.lying_low).override_failure_message("%s lies low" % name).is_true()
		assert_bool(wisp.visible).is_false()
		assert_object(wisp.brain).override_failure_message("not set up at all").is_null()
		assert_bool(wisp.hit_box.active).is_false()
		assert_bool(wisp.hurt_box.enabled).is_false()
		assert_dict(wisp.glow_now()).is_empty()
	# Standing right where one lies costs nothing, and a swing finds nothing.
	var hearts: int = GameState.health
	var energy: float = GameState.energy
	marsh.player.motor.place(ON_THE_BOARDS)
	(_wisp(marsh, "BogwispA")).position = marsh.player.position
	_play(marsh, 1.0)
	assert_int(GameState.health).is_equal(hearts)
	assert_float(GameState.energy).is_equal(energy)
	# Only Willowmere has them.
	for area_id: StringName in [&"village", &"north_fields", &"old_wood", &"south_field"]:
		assert_bool(FileAccess.get_file_as_string(WorldPaths.scene_for(area_id)).contains("bogwisp")).override_failure_message(String(area_id)).is_false()


func test_as_night_falls_they_rise_where_he_stands_watching() -> void:
	var marsh: AreaController = _marsh("19:59")
	assert_bool(_wisp(marsh, "BogwispA").lying_low).is_true()
	GameState.set_time(float(GameState.day_clock().in_day("20:00")))
	marsh._process(FRAME)
	for name: String in WISPS:
		var wisp: Enemy = _wisp(marsh, name)
		assert_bool(wisp.lying_low).override_failure_message("%s has risen" % name).is_false()
		assert_bool(wisp.visible).is_true()
		assert_object(wisp.brain).is_not_null()
		assert_bool(wisp.brain is WispBrain).is_true()
		assert_bool(wisp.hit_box.active).is_true()
		assert_bool(wisp.hurt_box.enabled).is_true()
		assert_dict(wisp.glow_now()).override_failure_message("it is a light").is_not_empty()
		assert_bool(marsh.grid.is_solid(wisp.body.cell)).override_failure_message("%s hangs over the water" % name).is_true()
	# And one that comes in after dark finds them there already.
	marsh = _marsh("23:00")
	assert_bool(_wisp(marsh, "BogwispC").lying_low).is_false()
	assert_object(_wisp(marsh, "BogwispC").brain).is_not_null()
	assert_int(marsh.glows_now().filter(func(glow: Dictionary) -> bool: return glow["color"] == Enemy.WISP_COLOR).size()).override_failure_message("five lights over the pools").is_equal(5)


func test_its_touch_takes_half_a_heart_and_a_chunk_of_energy() -> void:
	var marsh: AreaController = _marsh("22:00")
	var wisp: Enemy = _wisp(marsh, "BogwispA")
	marsh.player.motor.place(ON_THE_BOARDS)
	marsh.player.sync_from_motor()
	GameState.set_energy(80.0)
	var hearts: int = GameState.health
	_put(wisp, marsh.player.position)
	assert_int(marsh.resolve_combat()).override_failure_message("it touches him, body or no body").is_greater_equal(1)
	assert_int(GameState.health).override_failure_message("half a heart").is_equal(hearts - 1)
	assert_float(GameState.energy).override_failure_message("and fifteen of his energy").is_equal(65.0)
	# He can't be hurt again at once: one touch, one drain.
	marsh.resolve_combat()
	assert_int(GameState.health).is_equal(hearts - 1)
	assert_float(GameState.energy).is_equal(65.0)
	# Other enemies take no energy: a hit carries none unless its data says so.
	assert_float(Hit.new(1).energy).is_equal(0.0)
	assert_float(wisp.hit_box.energy).is_equal(15.0)


func test_drained_to_nothing_he_collapses_where_he_stands() -> void:
	var marsh: AreaController = _marsh("22:00")
	var wisp: Enemy = _wisp(marsh, "BogwispA")
	marsh.travel = func(_path: String) -> void: pass
	marsh.player.motor.place(ON_THE_BOARDS)
	marsh.player.sync_from_motor()
	GameState.set_energy(12.0)
	_put(wisp, marsh.player.position)
	marsh.resolve_combat()
	assert_float(GameState.energy).is_equal(0.0)
	assert_bool(GameState.is_exhausted()).is_true()
	marsh._process(FRAME)
	assert_bool(marsh.is_collapsing()).override_failure_message("the marsh at night is a risk to his strength, not only his hearts").is_true()


func test_without_the_lantern_the_sword_passes_through_it() -> void:
	var marsh: AreaController = _marsh("22:00")
	var wisp: Enemy = _wisp(marsh, "BogwispA")
	assert_array(marsh.holding_lights()).override_failure_message("his own dim glow is no light to speak of").is_empty()
	_face_over_the_pool(marsh, wisp)
	wisp.step(0.0)
	assert_bool((wisp.brain as WispBrain).lit).is_false()
	for i: int in 3:
		assert_bool(marsh.player.swing()).is_true()
		_play(marsh, 0.5)
		_put(wisp, GridBody.cell_center(OVER_THE_POOL))
	assert_int(wisp.brain.health).override_failure_message("untouched").is_equal(4)
	assert_bool(wisp.is_dead()).is_false()
	assert_array(_heard).override_failure_message("thin air").contains([&"whiff"])
	assert_array(_heard).not_contains([&"hit", &"enemy_die"])


func test_in_the_lanterns_light_two_blows_beat_it_and_it_leaves_an_ember() -> void:
	GameState.add_item(&"lantern")
	var marsh: AreaController = _marsh("22:00")
	var wisp: Enemy = _wisp(marsh, "BogwispA")
	assert_int(marsh.holding_lights().size()).is_equal(1)
	assert_float(float(marsh.holding_lights()[0]["radius"])).override_failure_message("the Lantern's own reach, as in the crypt").is_equal(marsh.hero_light_radius())
	_face_over_the_pool(marsh, wisp)
	wisp.step(0.0)
	assert_bool((wisp.brain as WispBrain).lit).override_failure_message("the light gives it a body").is_true()
	assert_bool(marsh.player.swing()).is_true()
	_play(marsh, 0.5)
	assert_int(wisp.brain.health).override_failure_message("the first blow lands").is_equal(2)
	assert_bool(wisp.is_dead()).is_false()
	_put(wisp, GridBody.cell_center(OVER_THE_POOL))
	wisp.step(0.0)
	assert_bool(marsh.player.swing()).is_true()
	_play(marsh, 0.5)
	assert_bool(wisp.is_dead()).override_failure_message("the second beats it").is_true()
	assert_array(_heard).contains([&"hit", &"enemy_die"])
	# The ember: it was beaten over the water, so it lies on the boards beside, in reach.
	var ember: ItemDrop = wisp.dropped as ItemDrop
	assert_object(ember).is_not_null()
	assert_that(ember.item_id).is_equal(&"wisp_ember")
	var lies: Vector2i = GridBody.cell_of(ember.position + Vector2(8, 8))
	assert_bool(marsh.grid.is_solid(lies)).override_failure_message("the ember lies at %s, where he can walk" % lies).is_false()
	marsh.player.motor.place(lies)
	marsh.player.sync_from_motor()
	marsh.collect_pickups()
	assert_int(GameState.item_count(&"wisp_ember")).is_equal(1)
	assert_int(GameState.skill_points.get(Skills.COMBAT, 0)).override_failure_message("a monster beaten is practice").is_greater(0)


func test_out_of_the_lanterns_reach_it_is_a_light_again() -> void:
	GameState.add_item(&"lantern")
	var marsh: AreaController = _marsh("22:00")
	var wisp: Enemy = _wisp(marsh, "BogwispA")
	marsh.player.motor.place(ON_THE_BOARDS)
	marsh.player.sync_from_motor()
	var reach: float = marsh.hero_light_radius()
	for case: Array in [[reach - 6.0, true], [reach + 6.0, false], [reach * 3.0, false]]:
		_put(wisp, marsh.player.position + Vector2(0, -8) - Enemy.WISP_AT + Vector2(float(case[0]), 0))
		wisp.step(0.0)
		assert_bool((wisp.brain as WispBrain).lit).override_failure_message("%s px from the Lantern" % case[0]).is_equal(case[1])
	assert_bool(marsh.holds_at(marsh.player.position)).is_true()
	assert_bool(marsh.holds_at(marsh.player.position + Vector2(200, 0))).is_false()


func test_it_flares_and_darts_at_him_and_both_are_heard() -> void:
	var marsh: AreaController = _marsh("22:00")
	var wisp: Enemy = _wisp(marsh, "BogwispA")
	marsh.player.motor.place(ON_THE_BOARDS)
	marsh.player.sync_from_motor()
	_put(wisp, marsh.player.position + Vector2(0, -44))
	var states: Array[StringName] = []
	wisp.brain.state_changed.connect(func(state: StringName) -> void: states.append(state))
	# It was put there resting: a rest, then the flare, then the dart.
	for i: int in 130:
		wisp.step(FRAME)
	assert_array(states.slice(0, 3)).is_equal([EnemyBrain.CHASE, WispBrain.FLARE, WispBrain.DART])
	assert_array(_heard).contains([&"wisp_flare", &"wisp_dart"])
	assert_int(_heard.find(&"wisp_flare")).is_less(_heard.find(&"wisp_dart"))
	for id: StringName in [&"wisp_flare", &"wisp_dart"]:
		assert_bool(Audio.SFX.has(id)).is_true()
		assert_bool(ResourceLoader.exists("res://audio/sfx/%s.wav" % id)).is_true()
	# Flaring, its light is wider and stronger.
	var calm: Dictionary = _wisp(marsh, "BogwispB").glow_now()
	_put(wisp, marsh.player.position + Vector2(0, -44))
	wisp.brain.change_state(WispBrain.FLARE)
	var flaring: Dictionary = wisp.glow_now()
	assert_float(float(flaring["radius"])).is_greater(float(calm["radius"]))
	assert_float(float(flaring["strength"])).is_greater(float(calm["strength"]))


func test_when_the_night_ends_any_left_fade_and_leave_nothing() -> void:
	var marsh: AreaController = _marsh("23:00")
	var practised: int = int(GameState.skill_points.get(Skills.COMBAT, 0))
	var died: Array[Enemy] = []
	for name: String in WISPS:
		_wisp(marsh, name).died.connect(func(enemy: Enemy) -> void: died.append(enemy))
	# The hero is never here at dawn (a day ends at 02:00), so the rule is told the night is over.
	marsh._on_night_turned(false)
	var fading: Array[Enemy] = []
	for name: String in WISPS:
		var wisp: Enemy = _wisp(marsh, name)
		fading.append(wisp)
		assert_bool(wisp.is_fading()).override_failure_message("%s fades" % name).is_true()
		assert_bool(wisp.is_dead()).override_failure_message("faded, not beaten").is_false()
		assert_bool(wisp.hit_box.active).override_failure_message("its touch is gone at once").is_false()
		assert_bool(wisp.hurt_box.enabled).is_false()
		assert_dict(wisp.glow_now()).is_empty()
		assert_object(wisp.dropped).override_failure_message("nothing is left behind").is_null()
	for i: int in roundi((Enemy.RISE_TIME + 0.1) / FRAME):
		for wisp: Enemy in fading:
			if is_instance_valid(wisp) and not wisp.is_queued_for_deletion():
				wisp._physics_process(FRAME)
	for wisp: Enemy in fading:
		assert_bool(wisp.is_queued_for_deletion()).override_failure_message("gone").is_true()
	assert_array(died).override_failure_message("none was beaten").is_empty()
	assert_int(int(GameState.skill_points.get(Skills.COMBAT, 0))).is_equal(practised)
	assert_int(GameState.item_count(&"wisp_ember")).is_equal(0)
	# A slime in the fields is not a thing of the night: telling it so changes nothing.
	var slime: Enemy = auto_free((load("res://gameplay/enemies/enemy.tscn") as PackedScene).instantiate())
	slime.enemy_id = &"slime"
	assert_bool(slime.waits_for_night()).is_false()


func test_the_mist_is_thicker_at_night_and_only_over_the_marsh() -> void:
	assert_float(Ambience.mist_thickness(&"willowmere", false)).is_equal(Mist.THICKEST)
	assert_float(Ambience.mist_thickness(&"willowmere", true)).is_greater(Mist.THICKEST)
	assert_float(Ambience.mist_thickness(&"old_wood", true)).override_failure_message("the Old Wood's is as it was").is_equal(Mist.THICKEST)
	var marsh: AreaController = _marsh("12:00")
	assert_float(marsh.mist.thickness).is_equal(Mist.THICKEST)
	marsh = _marsh("22:00")
	assert_float(marsh.mist.thickness).override_failure_message("thick as he arrives at night").is_equal(Ambience.mist_thickness(&"willowmere", true))
	# Standing there as night falls, it thickens slowly, and never moves.
	marsh = _marsh("19:59")
	var lies_at: Vector2 = marsh.mist.position
	GameState.set_time(float(GameState.day_clock().in_day("20:00")))
	marsh._process(0.5)
	assert_float(marsh.mist.thickness).is_greater(Mist.THICKEST)
	assert_float(marsh.mist.thickness).override_failure_message("not all at once").is_less(Ambience.mist_thickness(&"willowmere", true))
	assert_that(marsh.mist.position).override_failure_message("it thickens where it lies").is_equal(lies_at)


## Willowmere at `hour`, the hero on the west bank.
func _marsh(hour: String) -> AreaController:
	GameState.set_time(float(GameState.day_clock().in_day(hour)))
	GameState.update_player(&"willowmere", Vector2i(4, 14))
	_area = Steps.load_area(MARSH, _area)
	return _area as AreaController


func _wisp(area: AreaController, node_name: String) -> Enemy:
	return area.interactables.get_node(NodePath(node_name)) as Enemy


## Puts `wisp` at `point` (area px), as its body and its node.
func _put(wisp: Enemy, point: Vector2) -> void:
	wisp.body.position = point
	wisp.body.cell = GridBody.cell_of(point)
	wisp.position = point
	wisp.brain.change_state(WispBrain.REST)


## The hero on the boards facing north, `wisp` hanging over the pool cell before him.
func _face_over_the_pool(area: AreaController, wisp: Enemy) -> void:
	area.player.motor.place(ON_THE_BOARDS)
	area.player.face(Vector2.UP)
	area.player.sync_from_motor()
	_put(wisp, GridBody.cell_center(OVER_THE_POOL))


## Plays `seconds`: the hero stands, hits land. Wisps stay where they were put.
func _play(area: AreaController, seconds: float) -> void:
	for i: int in roundi(seconds / FRAME):
		area.player.motor.step(Vector2.ZERO, FRAME)
		area.player.sync_from_motor()
		area.resolve_combat()


func _on_sound(id: StringName) -> void:
	_heard.append(id)
