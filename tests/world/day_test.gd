extends GdUnitTestSuite
## The day in the world (P2a): the clock runs outdoors and in houses and stands still in
## dungeons, conversations and menus; the light outdoors follows the hour; lamps are lit from
## dusk to dawn; the HUD shows the day and the hour; and at 02:00 a new day begins.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const VILLAGE: String = "res://world/areas/village/village.tscn"
const ELDER_HOUSE: String = "res://world/areas/elder_house/elder_house.tscn"
const KEEP: String = "res://world/areas/keep/keep.tscn"
const CRYPT: String = "res://world/areas/crypt/crypt.tscn"
const FRAME: float = 1.0 / 60.0
const TEST_SLOT: int = 987

var _area: Node


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	SaveSystem.current_slot = TEST_SLOT


func after_test() -> void:
	if is_instance_valid(_area):
		_area.free()
	_area = null
	if SaveSystem.has_slot(TEST_SLOT):
		DirAccess.remove_absolute(SaveSystem.slot_path(TEST_SLOT))
	SaveSystem.current_slot = SaveSystem.GAME_SLOT
	GameState.clear()


func test_the_clock_runs_outdoors_and_in_a_house_and_stands_still_in_a_dungeon() -> void:
	var village: AreaController = _load(VILLAGE)
	assert_bool(village.clock_runs()).is_true()
	var before: float = GameState.minute
	village._process(GameState.day_clock().seconds_per_hour)
	assert_float(GameState.minute - before).override_failure_message("an hour of the day in seconds_per_hour of play").is_equal_approx(60.0, 0.01)
	var house: AreaController = _load(ELDER_HOUSE)
	assert_bool(house.clock_runs()).override_failure_message("it runs indoors too").is_true()
	before = GameState.minute
	house._process(1.0)
	assert_float(GameState.minute).is_greater(before)
	for path: String in [KEEP, CRYPT]:
		var dungeon: AreaController = _load(path)
		assert_bool(dungeon.clock_runs()).override_failure_message("%s: no day underground (decision 7)" % path).is_false()
		before = GameState.minute
		var played: float = GameState.play_time
		dungeon._process(5.0)
		assert_float(GameState.minute).override_failure_message("%s: the clock stands still" % path).is_equal(before)
		assert_float(GameState.play_time).override_failure_message("though play time still counts").is_greater(played)


func test_the_clock_stops_in_a_conversation_and_in_the_item_menu() -> void:
	var village: AreaController = _load(VILLAGE)
	Steps.stand_before(village, "FarmerOda")
	assert_bool(village.interact()).is_true()
	assert_bool(village.is_talking()).is_true()
	assert_bool(village.clock_runs()).override_failure_message("not while someone is talking").is_false()
	var before: float = GameState.minute
	village._process(3.0)
	assert_float(GameState.minute).is_equal(before)
	# The last answer is always the way out ("Goodbye.").
	for i: int in 12:
		if not village.is_talking():
			break
		village.hud.dialogue.move_cursor(village.hud.dialogue.shown_options().size() - 1)
		village.hud.dialogue.confirm()
	assert_bool(village.is_talking()).is_false()
	assert_bool(village.clock_runs()).is_true()
	GameState.add_item(&"bread")
	assert_bool(village.open_item_menu()).is_true()
	assert_bool(village.clock_runs()).override_failure_message("nor with the food menu open").is_false()
	village.hud.item_menu.close()
	assert_bool(village.clock_runs()).is_true()
	GameState.damage(99)
	assert_bool(village.is_dying()).is_true()
	assert_bool(village.clock_runs()).override_failure_message("nor while the hero is down").is_false()


func test_the_light_outdoors_follows_the_hour_and_a_house_keeps_its_own() -> void:
	var village: AreaController = _load(VILLAGE)
	assert_bool(village.has_daylight()).is_true()
	var clock: DayClock = GameState.day_clock()
	for time: String in ["06:00", "12:00", "18:30", "19:45", "23:00", "02:00"]:
		GameState.set_time(float(clock.in_day(time)))
		village._update_light()
		assert_that(village.lighting.ambient).override_failure_message("the village at %s" % time).is_equal(clock.light_at(float(clock.in_day(time))))
		assert_that((village.lighting.get_child(0) as CanvasModulate).color).override_failure_message("and it is what tints the picture").is_equal(village.lighting.ambient)
	GameState.set_time(float(clock.in_day("12:00")))
	village._update_light()
	assert_bool(village.lighting.is_dim()).override_failure_message("clear at noon").is_false()
	GameState.set_time(float(clock.in_day("23:00")))
	village._update_light()
	assert_bool(village.lighting.is_dim()).override_failure_message("dim at night").is_true()
	var house: AreaController = _load(ELDER_HOUSE)
	assert_bool(house.has_daylight()).is_false()
	house._update_light()
	assert_that(house.lighting.ambient).override_failure_message("a house's light doesn't change with the hour").is_equal(AreaLighting.ambient_for(Ambience.INTERIOR, false))
	var crypt: AreaController = _load(CRYPT)
	crypt._update_light()
	assert_that(crypt.lighting.ambient).override_failure_message("nor the crypt's dark").is_equal(AreaLighting.DARK)


func test_lamps_are_lit_from_dusk_to_dawn() -> void:
	var village: AreaController = _load(VILLAGE)
	var clock: DayClock = GameState.day_clock()
	var lamps: int = 0
	for glow: Dictionary in village.tile_glows:
		lamps += 1 if glow["at_dusk"] else 0
	assert_int(lamps).override_failure_message("the village has street lamps").is_greater(2)
	GameState.set_time(float(clock.in_day("12:00")))
	village._update_light()
	assert_int(_dusk_glows(village.glows_now())).override_failure_message("dark by day").is_equal(0)
	assert_int(_kind(village.scene_lights(), AreaLighting.POOL)).override_failure_message("and no pools of light at noon").is_equal(0)
	GameState.set_time(float(clock.in_day("18:30")))
	village._update_light()
	assert_int(_dusk_glows(village.glows_now())).override_failure_message("lit at dusk").is_equal(lamps)
	GameState.set_time(float(clock.in_day("23:00")))
	village._update_light()
	assert_int(_dusk_glows(village.glows_now())).is_equal(lamps)
	var pools: int = _kind(village.scene_lights(), AreaLighting.POOL)
	assert_int(pools).override_failure_message("at night each lamp has its pool, and the hero has none of his own").is_equal(lamps)
	for light: Dictionary in village.scene_lights():
		if light["kind"] == AreaLighting.POOL:
			assert_float(float(light["strength"])).override_failure_message("a lamp doesn't bring back the day").is_less(1.0)
			assert_float((light["at"] as Vector2).distance_to(village.player.position + Vector2(0, -8))).override_failure_message("no pool follows the hero").is_greater(1.0)
	GameState.set_time(float(clock.in_day("06:40")))
	village._update_light()
	assert_int(_dusk_glows(village.glows_now())).override_failure_message("out again after dawn").is_equal(0)
	# A fire burns at any hour, and indoors the hero keeps his own pool.
	GameState.set_time(float(clock.in_day("12:00")))
	var house: AreaController = _load(ELDER_HOUSE)
	assert_int(house.glows_now().size()).override_failure_message("the hearth is lit at noon").is_greater(0)
	assert_int(_dusk_glows(house.tile_glows)).is_equal(0)
	assert_int(_kind(house.scene_lights(), AreaLighting.POOL)).is_greater(house.glows_now().size() - 1)
	assert_array(Ambience.shining([Ambience.glow(Vector2.ZERO, 1.0, Color.WHITE, 1.0, false, true), Ambience.glow(Vector2.ONE, 1.0, Color.WHITE, 1.0, false)], false)).override_failure_message("by day, only what doesn't wait for dusk").has_size(1)


func test_the_hud_shows_the_day_and_the_hour() -> void:
	var village: AreaController = _load(VILLAGE)
	village._update_hud()
	assert_str(village.hud.shown_lines()[0]).is_equal("Day 1  06:00")
	GameState.set_time(float(GameState.day_clock().in_day("14:27")))
	village._update_hud()
	assert_str(village.hud.shown_lines()[0]).override_failure_message("in steps of ten minutes").is_equal("Day 1  14:20")
	var keep: AreaController = _load(KEEP)
	keep._update_hud()
	assert_str(keep.hud.shown_lines()[0]).override_failure_message("still shown where the clock stands still").is_equal("Day 1  14:20")
	assert_float(keep.hud.panel_size().x).override_failure_message("the corner stays small").is_less(130.0)


func test_a_day_ends_at_two_where_the_clock_runs_and_never_underground() -> void:
	var village: AreaController = _load(VILLAGE)
	var travelled: Array[String] = []
	village.travel = func(path: String) -> void: travelled.append(path)
	var clock: DayClock = GameState.day_clock()
	GameState.set_time(float(clock.ends) - 1.0)
	village._process(clock.seconds_per_hour / 60.0 * 0.5)
	assert_int(GameState.day).override_failure_message("not yet").is_equal(1)
	village._process(clock.seconds_per_hour / 60.0)
	assert_int(GameState.day).override_failure_message("02:00: the next day").is_equal(2)
	assert_float(GameState.minute).is_equal_approx(float(clock.starts), 0.5)
	assert_int(travelled.size()).override_failure_message("and the hero is taken home (tests/world/home_test.gd)").is_equal(1)
	# In a dungeon the clock stands still, so the day can't end there.
	GameState.set_time(float(clock.ends))
	var keep: AreaController = _load(KEEP)
	keep.travel = func(path: String) -> void: travelled.append(path)
	keep._process(1.0)
	assert_int(GameState.day).override_failure_message("no day ends underground").is_equal(2)
	assert_int(travelled.size()).is_equal(1)


func _dusk_glows(glows: Array) -> int:
	var count: int = 0
	for glow: Dictionary in glows:
		count += 1 if glow.get("at_dusk", false) else 0
	return count


func _kind(lights: Array, kind: StringName) -> int:
	var count: int = 0
	for light: Dictionary in lights:
		count += 1 if light["kind"] == kind else 0
	return count


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area
