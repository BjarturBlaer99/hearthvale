extends GdUnitTestSuite
## Build mode (the Homestead, phase 2, step 2a): B opens it on the hero's land and nowhere
## else. In it he stands still and the clock with him; the mouse points at a cell and the
## movement keys move the ghost a cell at a time, no further than the screen shows; the ghost
## is green where the thing fits and red where it doesn't, with the reason in words; a left
## click sets a thing down and a right click takes one up; the wheel and the keys 1 to 9
## choose on the build bar; Tab, Esc or B leave. A fence blocks the moment it is set and frees
## its cell the moment it is taken up; a path never blocks; the hero walks through a gate.
## Nothing is set down outside the mode.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const FARM: String = "res://world/areas/homestead/homestead.tscn"
const VILLAGE: String = "res://world/areas/village/village.tscn"
const HOME: String = "res://world/areas/home/home.tscn"
const TEST_SLOT: int = 951
const FRAME: float = 1.0 / 60.0
## Open grass east of the path to the farmhouse's door: rows 12 and 13, columns 29 to 37.
const START: Vector2i = Vector2i(30, 13)
const YARD: Vector2i = Vector2i(33, 12)
## One cell of each thing the plan says is never built on.
const WOODS: Vector2i = Vector2i(1, 13)
const OLD_TREE: Vector2i = Vector2i(34, 8)
const HOUSE: Vector2i = Vector2i(27, 10)
const ROAD: Vector2i = Vector2i(31, 14)
const DOOR_PATH: Vector2i = Vector2i(28, 13)
const DOORSTEP: Vector2i = Vector2i(28, 12)
const DOOR: Vector2i = Vector2i(28, 11)
const WAY_OUT: Vector2i = Vector2i(39, 14)
const FIELD: Vector2i = Vector2i(24, 18)
const WEEDS: Vector2i = Vector2i(36, 7)
## Weeds that stand alone, with grass below them to swing from.
const LONE_WEEDS: Vector2i = Vector2i(36, 5)

var _area: Node
var _heard: Array[StringName] = []
var _changes: int = 0


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	Quests.refresh()
	GameState.set_time(float(GameState.day_clock().in_day("12:00")))
	SaveSystem.erase_slot(TEST_SLOT)
	SaveSystem.current_slot = TEST_SLOT
	_heard.clear()
	_changes = 0
	EventBus.sound.connect(_on_sound)
	EventBus.homestead_changed.connect(_on_homestead_changed)


func after_test() -> void:
	EventBus.sound.disconnect(_on_sound)
	EventBus.homestead_changed.disconnect(_on_homestead_changed)
	if is_instance_valid(_area):
		_area.free()
	_area = null
	SaveSystem.erase_slot(TEST_SLOT)
	SaveSystem.current_slot = SaveSystem.GAME_SLOT
	GameState.clear()


func test_b_opens_build_mode_on_his_land_and_only_there() -> void:
	_stock()
	var farm: AreaController = _farm()
	assert_bool(InputMap.has_action(&"build")).is_true()
	assert_bool(farm.is_building()).is_false()
	assert_bool(farm.hud.is_building()).is_false()
	farm._unhandled_input(_key(&"build"))
	assert_bool(farm.is_building()).override_failure_message("B opens it on the homestead").is_true()
	assert_bool(farm.is_in_menu()).override_failure_message("it is a screen, like a menu").is_true()
	assert_bool(farm.player.controls_enabled).override_failure_message("the hero stands still").is_false()
	assert_bool(farm.hud.is_building()).is_true()
	assert_str(farm.hud.hint_text()).contains("Build mode")
	# In the village B says why not, and nothing opens. Nor in his own house.
	var village: AreaController = _load(VILLAGE)
	assert_object(village.build).is_null()
	assert_object(village.placed).is_null()
	_heard.clear()
	village._unhandled_input(_key(&"build"))
	assert_str(village.hud.message_text()).is_equal("You can only build on your own land.")
	assert_bool(village.is_building()).is_false()
	assert_bool(village.is_in_menu()).is_false()
	assert_bool(village.player.controls_enabled).is_true()
	assert_array(_heard).contains_exactly([&"nope"])
	var home: AreaController = _load(HOME)
	home._unhandled_input(_key(&"build"))
	assert_str(home.hud.message_text()).is_equal(Placement.NOT_LAND_WORDS)
	assert_bool(home.is_building()).is_false()


func test_it_opens_only_when_he_is_free_to_act() -> void:
	_stock()
	var farm: AreaController = _farm()
	# Behind the pause menu, in a list, or with his hands tied: B does nothing.
	farm.open_pause_menu()
	assert_bool(farm.open_build()).is_false()
	farm.hud.pause_menu.resume()
	GameState.add_item(&"bread", 1)
	GameState.set_energy(40.0)
	assert_bool(farm.open_item_menu()).is_true()
	assert_bool(farm.open_build()).override_failure_message("not over the food menu").is_false()
	farm.hud.item_menu.close()
	farm.player.controls_enabled = false
	assert_bool(farm.open_build()).override_failure_message("not while he can't act").is_false()
	farm.player.controls_enabled = true
	assert_bool(farm.open_build()).is_true()
	# And while it is open nothing else opens over it, and a second B is not a second mode.
	assert_bool(farm.open_item_menu()).is_false()
	assert_bool(farm.open_pause_menu()).is_false()
	assert_bool(farm.interact()).is_false()
	assert_bool(farm.use_hand()).is_false()
	assert_bool(farm.open_build()).is_false()


func test_tab_esc_and_b_each_leave_it() -> void:
	_stock()
	var farm: AreaController = _farm()
	for leave: StringName in [&"item_menu", &"pause", &"build"]:
		assert_bool(farm.open_build()).is_true()
		farm.build._unhandled_input(_key(leave))
		assert_bool(farm.is_building()).override_failure_message("%s leaves" % leave).is_false()
		assert_bool(farm.is_in_menu()).is_false()
		assert_bool(farm.player.controls_enabled).override_failure_message("and he can walk again").is_true()
		assert_bool(farm.hud.is_building()).is_false()
		assert_str(farm.hud.build_words()).is_equal("")
		assert_str(farm.hud.hint_text()).override_failure_message("the hint says what it said").contains("WASD: move")
		assert_bool(is_paused_or_menu(farm)).override_failure_message("leaving with Esc doesn't open the pause menu").is_false()
	# Closed, its keys are nobody's: a click sets nothing down.
	farm.build._unhandled_input(_click(farm, YARD))
	assert_int(GameState.homestead().placed_count()).is_equal(0)


func is_paused_or_menu(area: AreaController) -> bool:
	return area.is_paused() or area.hud.item_menu.is_open()


func test_the_clock_stands_and_the_hero_with_it() -> void:
	_stock()
	var farm: AreaController = _farm()
	assert_bool(farm.clock_runs()).is_true()
	farm.open_build()
	assert_bool(farm.clock_runs()).override_failure_message("the clock stops in build mode").is_false()
	var minute: float = GameState.minute
	var energy: float = GameState.energy
	var at: Vector2 = farm.player.motor.position
	Input.action_press(&"move_right")
	for frame: int in 120:
		farm._process(0.5)
		farm.player._physics_process(FRAME)
	Input.action_release(&"move_right")
	assert_float(GameState.minute).override_failure_message("a minute of real time, and the same minute of the day").is_equal(minute)
	assert_that(farm.player.motor.position).override_failure_message("he has not moved").is_equal(at)
	# Setting things down costs no energy and no time.
	farm.build.point_at(YARD)
	assert_bool(farm.build.set_down()).is_true()
	assert_float(GameState.energy).is_equal(energy)
	assert_float(GameState.minute).is_equal(minute)
	farm.build.close()
	farm._process(0.5)
	assert_float(GameState.minute).override_failure_message("and it runs again once he leaves").is_greater(minute)


func test_the_build_bar_takes_the_item_bars_place() -> void:
	GameState.add_item(&"wooden_sword")
	GameState.add_item(&"hoe")
	_stock()
	var farm: AreaController = _farm()
	farm._process(FRAME)
	assert_bool(farm.hud.item_bar.visible).is_true()
	assert_bool(farm.hud.build_bar.visible).is_false()
	assert_array(farm.hud.item_bar.shown_ids()).override_failure_message("nothing to set down is ever on the item bar").is_equal([&"wooden_sword", &"hoe"])
	farm.open_build()
	farm._process(FRAME)
	assert_bool(farm.hud.item_bar.visible).override_failure_message("the item bar is out of sight").is_false()
	assert_bool(farm.hud.build_bar.visible).is_true()
	assert_array(farm.hud.build_bar.shown_ids()).is_equal([&"fence", &"gate", &"dirt_path", &"stone_path", &"wood_path"])
	assert_array(Array(farm.hud.build_bar.shown_counts())).is_equal(["12", "2", "8", "8", "8"])
	assert_int(farm.hud.build_bar.lit_slot()).override_failure_message("the first thing is chosen").is_equal(0)
	assert_that(farm.build.chosen).is_equal(&"fence")
	assert_str(farm.hud.build_words()).is_equal("Fence x12")
	# The bar sits where the item bar sits.
	assert_float(farm.hud.build_bar.position.y).is_equal(farm.hud.item_bar.position.y)
	farm.build.close()
	farm._process(FRAME)
	assert_bool(farm.hud.item_bar.visible).is_true()
	assert_bool(farm.hud.build_bar.visible).is_false()


func test_the_wheel_and_the_number_keys_choose() -> void:
	_stock()
	var farm: AreaController = _farm()
	farm.open_build()
	_heard.clear()
	farm.build._unhandled_input(_wheel(MOUSE_BUTTON_WHEEL_DOWN))
	assert_that(farm.build.chosen).is_equal(&"gate")
	assert_int(farm.hud.build_bar.lit_slot()).is_equal(1)
	assert_str(farm.hud.build_words()).is_equal("Gate x2")
	farm.build._unhandled_input(_wheel(MOUSE_BUTTON_WHEEL_UP))
	farm.build._unhandled_input(_wheel(MOUSE_BUTTON_WHEEL_UP))
	assert_that(farm.build.chosen).override_failure_message("round to the last").is_equal(&"wood_path")
	assert_array(_heard).override_failure_message("each change of choice is heard").is_equal([&"menu_move", &"menu_move", &"menu_move"])
	farm.build._unhandled_input(_key(&"slot_3"))
	assert_that(farm.build.chosen).is_equal(&"dirt_path")
	assert_int(farm.hud.build_bar.lit_slot()).is_equal(2)
	# The slot it is on already, and a slot with nothing in it, change nothing.
	_heard.clear()
	farm.build._unhandled_input(_key(&"slot_3"))
	farm.build._unhandled_input(_key(&"slot_8"))
	assert_that(farm.build.chosen).is_equal(&"dirt_path")
	assert_array(_heard).is_empty()
	# What is in the hero's hand is as it was: the wheel was the build bar's.
	assert_that(GameState.equipped).is_equal(&"")


func test_the_ghost_starts_before_him_and_the_keys_move_it_a_cell_at_a_time() -> void:
	_stock()
	var farm: AreaController = _farm()
	farm.open_build()
	assert_that(farm.build.cell).override_failure_message("on the cell he faces").is_equal(START + Vector2i.RIGHT)
	for step: Array in [[&"move_right", Vector2i(32, 13)], [&"move_up", Vector2i(32, 12)], [&"move_left", Vector2i(31, 12)], [&"move_down", Vector2i(31, 13)]]:
		farm.build._unhandled_input(_key(step[0]))
		assert_that(farm.build.cell).override_failure_message(String(step[0])).is_equal(step[1])
	# A key held repeats, as it does in a menu.
	var held: InputEventAction = _key(&"move_right")
	farm.build._unhandled_input(held)
	farm.build._unhandled_input(held)
	assert_that(farm.build.cell).is_equal(Vector2i(33, 13))
	assert_that(farm.player.motor.cell).override_failure_message("the hero is where he was").is_equal(START)


func test_only_what_is_on_screen_can_be_built_on() -> void:
	_stock()
	var farm: AreaController = _farm()
	await await_idle_frame()
	farm.open_build()
	var view: Rect2i = farm.build.view_cells()
	assert_that(view).override_failure_message("the map is a screen wide; the camera shows rows 2 to 24 from the yard").is_equal(Rect2i(0, 2, 40, 23))
	# The ghost stops at the edge of the view, by the keys and by the mouse alike.
	farm.build.point_at(Vector2i(31, 24))
	farm.build._unhandled_input(_key(&"move_down"))
	assert_that(farm.build.cell).override_failure_message("no further down than the screen shows").is_equal(Vector2i(31, 24))
	assert_bool(farm.build.point_at(Vector2i(31, 27))).is_false()
	assert_that(farm.build.cell).is_equal(Vector2i(31, 24))
	farm.build.point_at(Vector2i(60, -4))
	assert_that(farm.build.cell).override_failure_message("nor off the map").is_equal(Vector2i(39, 2))
	farm.build._unhandled_input(_key(&"move_right"))
	farm.build._unhandled_input(_key(&"move_up"))
	assert_that(farm.build.cell).is_equal(Vector2i(39, 2))
	# To build further off he leaves, walks, and opens it again.
	farm.build.close()
	farm.player.motor.place(Vector2i(30, 26))
	farm.player.sync_from_motor()
	await await_idle_frame()
	await await_idle_frame()
	farm.open_build()
	assert_bool(farm.build.view_cells().has_point(Vector2i(31, 27))).override_failure_message("the south of the land is on screen now").is_true()
	assert_bool(farm.build.view_cells().has_point(Vector2i(31, 4))).is_false()
	farm.build.point_at(Vector2i(31, 27))
	assert_that(farm.build.cell).is_equal(Vector2i(31, 27))


func test_the_mouse_points_at_a_cell_and_its_clicks_set_down_and_take_up() -> void:
	_stock()
	var farm: AreaController = _farm()
	await await_idle_frame()
	farm.open_build()
	farm.build._unhandled_input(_point(farm, YARD))
	assert_that(farm.build.cell).override_failure_message("the ghost is under the mouse").is_equal(YARD)
	# Anywhere in the cell is that cell, and the next cell begins at its edge.
	farm.build._unhandled_input(_point_px(farm, Vector2(YARD) * 16.0 + Vector2(15.5, 0.5)))
	assert_that(farm.build.cell).is_equal(YARD)
	farm.build._unhandled_input(_point_px(farm, Vector2(YARD) * 16.0 + Vector2(16.5, 0.5)))
	assert_that(farm.build.cell).is_equal(YARD + Vector2i.RIGHT)
	# A left click sets the chosen thing down where the mouse is, wherever the ghost was.
	_heard.clear()
	farm.build._unhandled_input(_click(farm, YARD))
	assert_that(GameState.homestead().standing_at(YARD)).is_equal(&"fence")
	assert_int(GameState.item_count(&"fence")).override_failure_message("one from the pack").is_equal(11)
	assert_str(farm.hud.build_words()).override_failure_message("and the cell is taken now").is_equal(Placement.TAKEN_WORDS)
	assert_array(_heard).contains_exactly([&"set_down"])
	assert_int(_changes).is_equal(1)
	# A right click takes up what is under the mouse.
	_heard.clear()
	farm.build._unhandled_input(_click(farm, Vector2i(35, 13)))
	assert_that(GameState.homestead().standing_at(Vector2i(35, 13))).is_equal(&"fence")
	farm.build._unhandled_input(_click(farm, YARD, MOUSE_BUTTON_RIGHT))
	assert_that(GameState.homestead().standing_at(YARD)).is_equal(&"")
	assert_that(GameState.homestead().standing_at(Vector2i(35, 13))).override_failure_message("the other fence stands").is_equal(&"fence")
	assert_int(GameState.item_count(&"fence")).is_equal(11)
	assert_array(_heard).is_equal([&"set_down", &"take_up"])
	assert_str(farm.hud.message_text()).is_equal("Taken up: Fence.")
	# The keys do the same where the ghost is: the sword's key sets down, the item's takes up.
	farm.build.point_at(Vector2i(34, 12))
	farm.build._unhandled_input(_key(&"attack"))
	assert_that(GameState.homestead().standing_at(Vector2i(34, 12))).is_equal(&"fence")
	farm.build._unhandled_input(_key(&"use_item"))
	assert_that(GameState.homestead().standing_at(Vector2i(34, 12))).is_equal(&"")


func test_the_ghost_is_green_where_it_fits_and_red_with_the_reason_where_not() -> void:
	_stock()
	var farm: AreaController = _farm()
	await await_idle_frame()
	farm.open_build()
	farm.build.point_at(YARD)
	assert_bool(farm.build.fits()).is_true()
	assert_bool(farm.hud.build_refused()).is_false()
	assert_str(farm.hud.build_words()).is_equal("Fence x12")
	# Every refusal of the plan's table that the land can show, with its words.
	var rows: Array = [
		[WOODS, Placement.NO_GROUND_WORDS, "the woods at the edge"], [OLD_TREE, Placement.NO_GROUND_WORDS, "an old tree"],
		[HOUSE, Placement.NO_GROUND_WORDS, "the house"], [Vector2i(0, 12), Placement.NO_GROUND_WORDS, "the edge of the map"],
		[ROAD, Placement.ROAD_WORDS, "the road"], [DOOR_PATH, Placement.ROAD_WORDS, "the path to the door"],
		[WAY_OUT, Placement.ROAD_WORDS, "the way out"], [DOOR, Placement.ROAD_WORDS, "the door itself is a way out"],
		[FIELD, Placement.FIELD_WORDS, "the field"], [Vector2i(33, 22), Placement.FIELD_WORDS, "the field's far corner"],
		[WEEDS, Placement.CLEAR_FIRST_WORDS, "weeds"], [START, Placement.SOMEONE_WORDS, "the cell he stands in"],
	]
	assert_bool(farm.grid.is_solid(OLD_TREE) and farm.debris_at(WEEDS) != null).override_failure_message("the map is as the test takes it to be").is_true()
	for row: Array in rows:
		farm.build.point_at(row[0])
		assert_that(farm.build.cell).override_failure_message("%s is on screen" % row[2]).is_equal(row[0])
		assert_str(farm.build.why_not()).override_failure_message(str(row[2])).is_equal(row[1])
		assert_bool(farm.build.fits()).is_false()
		assert_bool(farm.hud.build_refused()).override_failure_message("%s: the words are a refusal's" % row[2]).is_true()
		assert_str(farm.hud.build_words()).is_equal(row[1])
		_heard.clear()
		assert_bool(farm.build.set_down()).override_failure_message("%s: nothing is set down" % row[2]).is_false()
		assert_array(_heard).contains_exactly([&"nope"])
	assert_int(GameState.homestead().placed_count()).is_equal(0)
	assert_int(GameState.item_count(&"fence")).is_equal(12)
	assert_int(_changes).is_equal(0)
	# The pond: water is nowhere to stand. (He walks there to see it.)
	farm.build.close()
	farm.player.motor.place(Vector2i(12, 20))
	farm.player.sync_from_motor()
	await await_idle_frame()
	await await_idle_frame()
	farm.open_build()
	farm.build.point_at(Vector2i(6, 22))
	assert_str(farm.build.why_not()).override_failure_message("water").is_equal(Placement.NO_GROUND_WORDS)
	# The doorstep is the cell before the door. The farmhouse's is the path's end, so it is
	# refused as road; the rule itself is Placement's (tests/core/homestead/placement_test.gd).
	assert_bool(farm.build.is_doorstep(DOORSTEP)).is_true()
	assert_bool(farm.build.is_doorstep(DOOR_PATH) or farm.build.is_doorstep(YARD) or farm.build.is_doorstep(Vector2i(38, 14))).is_false()
	assert_bool(farm.build.is_road(DOORSTEP)).is_true()
	assert_str(Placement.why_not(DataRegistry.get_item(&"fence"), farm.build.site_at(DOORSTEP))).is_equal(Placement.ROAD_WORDS)
	# A lying thing may go under his feet; nothing may go on the road, whatever it is.
	farm.build.choose_slot(2)
	assert_that(farm.build.chosen).is_equal(&"dirt_path")
	farm.build.point_at(farm.player.motor.cell)
	assert_bool(farm.build.fits()).override_failure_message("a path under the hero").is_true()
	assert_str(Placement.why_not(DataRegistry.get_item(&"dirt_path"), farm.build.site_at(ROAD))).is_equal(Placement.ROAD_WORDS)
	assert_str(Placement.why_not(DataRegistry.get_item(&"dirt_path"), farm.build.site_at(FIELD))).is_equal(Placement.FIELD_WORDS)
	assert_str(Placement.why_not(DataRegistry.get_item(&"dirt_path"), farm.build.site_at(WEEDS))).is_equal(Placement.CLEAR_FIRST_WORDS)


func test_a_cell_takes_one_lying_thing_and_one_standing() -> void:
	_stock()
	var farm: AreaController = _farm()
	farm.open_build()
	farm.build.point_at(YARD)
	farm.build.choose_slot(3)
	assert_bool(farm.build.set_down()).override_failure_message("a stone path").is_true()
	assert_str(farm.build.why_not()).override_failure_message("a second path on it").is_equal(Placement.TAKEN_WORDS)
	farm.build.choose_slot(2)
	assert_str(farm.build.why_not()).override_failure_message("nor a path of another kind").is_equal(Placement.TAKEN_WORDS)
	farm.build.choose_slot(0)
	assert_bool(farm.build.fits()).override_failure_message("a fence on the paved cell").is_true()
	assert_bool(farm.build.set_down()).is_true()
	assert_that(GameState.homestead().lying_at(YARD)).is_equal(&"stone_path")
	assert_that(GameState.homestead().standing_at(YARD)).is_equal(&"fence")
	assert_str(farm.build.why_not()).is_equal(Placement.TAKEN_WORDS)
	farm.build.choose_slot(1)
	assert_str(farm.build.why_not()).override_failure_message("a gate where a fence stands").is_equal(Placement.TAKEN_WORDS)
	assert_bool(farm.build.set_down()).is_false()
	assert_int(GameState.homestead().placed_count()).is_equal(2)
	# A right click takes up what stands there first, then what lies there, then finds nothing.
	_heard.clear()
	assert_bool(farm.build.take_up()).is_true()
	assert_that(GameState.homestead().standing_at(YARD)).is_equal(&"")
	assert_that(GameState.homestead().lying_at(YARD)).override_failure_message("the path stays").is_equal(&"stone_path")
	assert_bool(farm.build.take_up()).is_true()
	assert_that(GameState.homestead().lying_at(YARD)).is_equal(&"")
	assert_int(GameState.item_count(&"fence")).is_equal(12)
	assert_int(GameState.item_count(&"stone_path")).is_equal(8)
	assert_bool(farm.build.take_up()).override_failure_message("nothing is left there").is_false()
	assert_str(farm.hud.message_text()).is_equal("There is nothing here to take up.")
	assert_array(_heard).is_equal([&"take_up", &"take_up", &"nope"])


func test_a_fence_blocks_the_moment_it_is_set_and_frees_its_cell_when_taken_up() -> void:
	_stock()
	var farm: AreaController = _farm()
	var beside: Vector2i = START + Vector2i.RIGHT
	assert_bool(farm.terrain.is_occupied(beside)).is_false()
	assert_that(farm.terrain.check_move(START, beside).kind).is_equal(MoveResult.Kind.WALK)
	farm.open_build()
	assert_that(farm.build.cell).is_equal(beside)
	assert_bool(farm.build.set_down()).is_true()
	# At once: no frame has gone by.
	assert_bool(farm.terrain.is_occupied(beside)).override_failure_message("the fence fills its cell").is_true()
	assert_that(farm.terrain.check_move(START, beside).kind).is_equal(MoveResult.Kind.BLOCKED)
	assert_object(farm.placed.standing_node(beside)).is_not_null()
	farm.build.close()
	_walk(farm, Vector2.RIGHT, 60)
	assert_that(farm.player.motor.cell).override_failure_message("he walks into the fence and stops").is_equal(START)
	# Taken up, the cell is free the same moment, and he walks on.
	farm.open_build()
	farm.build.point_at(beside)
	assert_bool(farm.build.take_up()).is_true()
	assert_bool(farm.terrain.is_occupied(beside)).override_failure_message("the cell is free again").is_false()
	assert_object(farm.placed.standing_node(beside)).is_null()
	farm.build.close()
	_walk(farm, Vector2.RIGHT, 60)
	assert_that(farm.player.motor.cell.x).override_failure_message("he walks where the fence stood").is_greater(beside.x)
	# Nothing else on the land changed for it: the weeds still stand, the tree still blocks.
	assert_bool(farm.terrain.is_occupied(WEEDS)).is_true()
	assert_bool(farm.grid.is_solid(OLD_TREE)).is_true()


func test_a_path_never_blocks_and_the_hero_walks_through_a_gate() -> void:
	_stock()
	var farm: AreaController = _farm()
	farm.open_build()
	# A fence line across row 13 east of him, with a gate in it, and a path leading through.
	farm.build.choose_slot(2)
	for x: int in range(31, 35):
		farm.build.point_at(Vector2i(x, 13))
		assert_bool(farm.build.set_down()).is_true()
		assert_bool(farm.terrain.is_occupied(Vector2i(x, 13))).override_failure_message("a path is walked on").is_false()
	farm.build.choose_slot(1)
	farm.build.point_at(Vector2i(32, 13))
	assert_bool(farm.build.set_down()).override_failure_message("a gate on the path").is_true()
	assert_bool(farm.terrain.is_occupied(Vector2i(32, 13))).override_failure_message("a gate lets the hero through").is_false()
	assert_bool(farm.placed.standing_node(Vector2i(32, 13)).blocks()).is_false()
	farm.build.choose_slot(0)
	farm.build.point_at(Vector2i(32, 12))
	assert_bool(farm.build.set_down()).is_true()
	farm.build.close()
	_walk(farm, Vector2.RIGHT, 60)
	assert_int(farm.player.motor.cell.x).override_failure_message("along the path and through the gate").is_greater(33)
	assert_int(farm.player.motor.cell.y).is_equal(13)
	# The gate stands in a fence that runs north from it: it shows as the gap's two ends.
	assert_int(farm.placed.standing_node(Vector2i(32, 13)).joined()).is_equal(PlacedArt.NORTH)
	assert_array(PlacedArt.pieces(DataRegistry.get_item(&"gate"), 0, PlacedArt.NORTH)).is_equal([[&"gate_v", false]])
	assert_array(PlacedArt.pieces(DataRegistry.get_item(&"gate"), 0, PlacedArt.EAST | PlacedArt.WEST)).is_equal([[&"gate", false]])
	assert_array(PlacedArt.pieces(DataRegistry.get_item(&"gate"), 0, 0)).is_equal([[&"gate", false]])
	# The fence north of it runs down to it: its post, and a rail to the south.
	assert_int(farm.placed.standing_node(Vector2i(32, 12)).joined()).is_equal(PlacedArt.SOUTH)
	assert_array(PlacedArt.pieces(DataRegistry.get_item(&"fence"), 0, PlacedArt.SOUTH)).is_equal([[&"fence", false], [&"fence_s", false]])
	assert_array(PlacedArt.pieces(DataRegistry.get_item(&"fence"), 0, PlacedArt.NORTH | PlacedArt.EAST | PlacedArt.SOUTH | PlacedArt.WEST)).is_equal(
		[[&"fence_n", false], [&"fence_e", true], [&"fence_e", false], [&"fence", false], [&"fence_s", false]])
	assert_array(PlacedArt.pieces(DataRegistry.get_item(&"dirt_path"), 0, PlacedArt.EAST)).override_failure_message("a path is one picture").is_equal([[&"dirt_path", false]])


func test_taking_up_gives_the_item_back_and_a_full_pack_refuses() -> void:
	_stock()
	var farm: AreaController = _farm()
	farm.open_build()
	farm.build.point_at(YARD)
	assert_bool(farm.build.set_down()).is_true()
	assert_int(GameState.item_count(&"fence")).is_equal(11)
	# A full stack of fences: the one that stands can't be carried, and stays where it is.
	GameState.add_item(&"fence", 200)
	assert_int(GameState.item_count(&"fence")).is_equal(99)
	_heard.clear()
	_changes = 0
	assert_bool(farm.build.take_up()).is_false()
	assert_str(farm.hud.message_text()).is_equal("You have no room for the Fence.")
	assert_that(GameState.homestead().standing_at(YARD)).override_failure_message("a full pack loses nothing: it stands").is_equal(&"fence")
	assert_bool(farm.terrain.is_occupied(YARD)).is_true()
	assert_int(GameState.item_count(&"fence")).is_equal(99)
	assert_array(_heard).contains_exactly([&"nope"])
	assert_int(_changes).is_equal(0)
	# With room for it, it comes back.
	GameState.add_item(&"fence", -1)
	assert_bool(farm.build.take_up()).is_true()
	assert_int(GameState.item_count(&"fence")).is_equal(99)
	assert_that(GameState.homestead().standing_at(YARD)).is_equal(&"")


func test_the_last_of_a_thing_leaves_the_bar_and_the_next_is_chosen() -> void:
	GameState.add_item(&"gate", 1)
	GameState.add_item(&"dirt_path", 2)
	var farm: AreaController = _farm()
	farm.open_build()
	assert_that(farm.build.chosen).is_equal(&"gate")
	farm.build.point_at(YARD)
	assert_bool(farm.build.set_down()).is_true()
	assert_array(farm.hud.build_bar.shown_ids()).is_equal([&"dirt_path"])
	assert_that(farm.build.chosen).override_failure_message("the next thing on the bar").is_equal(&"dirt_path")
	for x: int in [34, 35]:
		farm.build.point_at(Vector2i(x, 12))
		assert_bool(farm.build.set_down()).is_true()
	# Nothing left to set down: the bar is empty, the ghost a pointer, and a click sets nothing.
	assert_that(farm.build.chosen).is_equal(&"")
	assert_array(farm.hud.build_bar.shown_ids()).is_empty()
	assert_str(farm.hud.build_words()).is_equal("You carry nothing to set down.")
	assert_bool(farm.hud.build_refused()).is_false()
	farm.build.point_at(Vector2i(36, 12))
	_heard.clear()
	assert_bool(farm.build.set_down()).is_false()
	assert_array(_heard).contains_exactly([&"nope"])
	assert_that(GameState.homestead().thing_at(Vector2i(36, 12), Placement.LYING)).is_equal(&"")
	# He can still take things up, and what he takes up is on the bar again, chosen.
	farm.build.point_at(YARD)
	assert_bool(farm.build.take_up()).is_true()
	assert_that(farm.build.chosen).is_equal(&"gate")
	assert_array(farm.hud.build_bar.shown_ids()).is_equal([&"gate"])
	# What was chosen is remembered when he comes back to it.
	farm.build.close()
	GameState.add_item(&"fence", 3)
	farm.open_build()
	assert_that(farm.build.chosen).is_equal(&"gate")


func test_nothing_is_set_down_outside_the_mode() -> void:
	GameState.add_item(&"wooden_sword")
	_stock()
	var farm: AreaController = _farm()
	farm._process(FRAME)
	# In play the mouse is two buttons: a left click swings the sword, a right click finds
	# nothing to do, and the wheel and the number keys are the item bar's. Nothing is set down.
	assert_array(GameState.hand_entries().map(func(entry: Dictionary) -> String: return str(entry["id"]))).is_equal(["wooden_sword"])
	farm._unhandled_input(_click(farm, YARD))
	farm._unhandled_input(_click(farm, YARD, MOUSE_BUTTON_RIGHT))
	farm._unhandled_input(_wheel(MOUSE_BUTTON_WHEEL_DOWN))
	farm._unhandled_input(_key(&"slot_2"))
	farm._unhandled_input(_key(&"use_item"))
	farm.build._unhandled_input(_click(farm, YARD))
	farm.build._unhandled_input(_point(farm, YARD))
	assert_bool(farm.build.set_down()).override_failure_message("the mode is shut").is_false()
	assert_bool(farm.build.take_up()).is_false()
	assert_int(GameState.homestead().placed_count()).is_equal(0)
	assert_int(GameState.item_count(&"fence")).is_equal(12)
	assert_that(GameState.equipped).override_failure_message("and nothing of it is in his hand").is_equal(&"")
	assert_int(_changes).is_equal(0)
	# Off his land GameState sets nothing down either, whatever asks.
	assert_bool(GameState.set_down(&"village", Vector2i(20, 20), &"fence")).is_false()
	assert_bool(GameState.set_down(&"home", Vector2i(5, 5), &"dirt_path")).is_false()
	assert_that(GameState.take_up(&"village", Vector2i(20, 20), Placement.STANDING)).is_equal(&"")
	assert_str(GameState.why_not_take_up(&"village", Vector2i(20, 20), Placement.STANDING)).is_equal(Placement.NOTHING_WORDS)
	# Nor what he hasn't got, or what is no placeable.
	assert_bool(GameState.set_down(&"homestead", YARD, &"hedge_of_dreams")).is_false()
	assert_bool(GameState.set_down(&"homestead", YARD, &"wooden_sword")).is_false()
	GameState.add_item(&"fence", -12)
	assert_bool(GameState.set_down(&"homestead", YARD, &"fence")).override_failure_message("he carries none").is_false()
	assert_int(GameState.homestead().placed_count()).is_equal(0)
	assert_int(_changes).is_equal(0)


func test_standing_things_are_sorted_with_the_hero_and_lying_things_lie_under_everyone() -> void:
	_stock()
	var farm: AreaController = _farm()
	farm.open_build()
	farm.build.point_at(YARD)
	farm.build.set_down()
	farm.build.choose_slot(2)
	farm.build.point_at(YARD + Vector2i.RIGHT)
	farm.build.set_down()
	farm.build.close()
	var fence: PlacedThing = farm.placed.standing_node(YARD)
	assert_object(fence.get_parent()).override_failure_message("a standing thing is among the area's interactables").is_same(farm.interactables)
	assert_bool(farm.interactables.y_sort_enabled and farm.y_sort_enabled).is_true()
	assert_that(fence.position).is_equal(Vector2(YARD) * 16.0)
	assert_that(fence.cell()).is_equal(YARD)
	# In front of it (south) he is drawn after it; behind it (north), before.
	farm.player.motor.place(YARD + Vector2i.DOWN)
	farm.player.sync_from_motor()
	assert_float(farm.player.position.y).override_failure_message("in front of the fence he is drawn over it").is_greater(fence.position.y)
	farm.player.motor.place(YARD + Vector2i.UP)
	farm.player.sync_from_motor()
	assert_float(farm.player.position.y).override_failure_message("behind it, under it").is_less(fence.position.y)
	# Lying things are one flat picture just over the ground's shading, under everyone.
	assert_float(farm.placed.position.y).is_equal(0.0)
	assert_int(farm.placed.get_index()).is_less(farm.interactables.get_index())
	assert_int(farm.placed.get_index()).is_greater(farm.get_node(^"HeightShading").get_index())
	assert_int(farm.placed.get_index()).is_less(farm.player.get_index())
	assert_object(farm.placed.standing_node(YARD + Vector2i.RIGHT)).override_failure_message("a path is no node of its own").is_null()
	# The ghost is drawn over the world and under the HUD.
	assert_int(farm.build.get_index()).is_less(farm.hud.get_index())


func test_what_is_set_down_is_there_after_a_save() -> void:
	_stock()
	var farm: AreaController = _farm()
	farm.open_build()
	var fences: Array[Vector2i] = [Vector2i(32, 12), Vector2i(33, 12), Vector2i(34, 12)]
	for cell: Vector2i in fences:
		farm.build.point_at(cell)
		assert_bool(farm.build.set_down()).is_true()
	farm.build.choose_slot(1)
	farm.build.point_at(Vector2i(35, 12))
	farm.build.set_down()
	farm.build.choose_slot(3)
	for cell: Vector2i in [Vector2i(33, 12), Vector2i(33, 13)]:
		farm.build.point_at(cell)
		assert_bool(farm.build.set_down()).is_true()
	farm.build.close()
	assert_int(farm.save_here()).is_equal(OK)
	var on_disk: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SaveSystem.slot_path(TEST_SLOT)))
	assert_int(int(on_disk["version"])).override_failure_message("still version 6").is_equal(6)
	assert_dict(on_disk["homestead"]).is_equal({
		"cleared": [],
		"lying": {"33,12": "stone_path", "33,13": "stone_path"},
		"standing": {"32,12": {"item": "fence"}, "33,12": {"item": "fence"}, "34,12": {"item": "fence"}, "35,12": {"item": "gate"}},
	})
	var before: String = JSON.stringify(GameState.to_dict(), "", true)
	GameState.clear()
	assert_int(SaveSystem.load_from_slot(TEST_SLOT)).is_equal(OK)
	assert_str(JSON.stringify(GameState.to_dict(), "", true)).is_equal(before)
	# The land as it loads: every fence stands and blocks, the gate lets him through, the
	# paths lie, and what he carried he carries.
	farm = _load(FARM)
	for cell: Vector2i in fences:
		assert_object(farm.placed.standing_node(cell)).override_failure_message("%s stands" % cell).is_not_null()
		assert_that(farm.placed.standing_node(cell).item_id).is_equal(&"fence")
		assert_bool(farm.terrain.is_occupied(cell)).override_failure_message("%s blocks" % cell).is_true()
	assert_that(farm.placed.standing_node(Vector2i(35, 12)).item_id).is_equal(&"gate")
	assert_bool(farm.terrain.is_occupied(Vector2i(35, 12))).is_false()
	assert_bool(farm.terrain.is_occupied(Vector2i(33, 13))).is_false()
	assert_int(farm.placed.standing_nodes().size()).is_equal(4)
	assert_that(GameState.homestead().lying_at(Vector2i(33, 13))).is_equal(&"stone_path")
	assert_int(GameState.item_count(&"fence")).is_equal(9)
	assert_int(GameState.item_count(&"stone_path")).is_equal(6)
	# A morning changes none of it, and it can all be taken up again.
	GameState.start_next_day()
	assert_int(GameState.homestead().placed_count()).is_equal(6)
	farm.open_build()
	for cell: Vector2i in [Vector2i(32, 12), Vector2i(33, 12), Vector2i(33, 12), Vector2i(34, 12), Vector2i(35, 12), Vector2i(33, 13)]:
		farm.build.point_at(cell)
		assert_bool(farm.build.take_up()).override_failure_message("%s" % cell).is_true()
	assert_int(GameState.homestead().placed_count()).is_equal(0)
	assert_int(farm.placed.standing_nodes().size()).is_equal(0)
	assert_dict(GameState.to_dict()["homestead"]).override_failure_message("a yard taken up is no yard").is_equal({"cleared": []})
	for item: Array in [[&"fence", 12], [&"gate", 2], [&"stone_path", 8]]:
		assert_int(GameState.item_count(item[0])).override_failure_message(String(item[0])).is_equal(item[1])


func test_cleared_ground_can_be_built_on_and_what_lies_there_is_not_shut_in() -> void:
	GameState.add_item(&"wooden_sword")
	_stock()
	GameState.update_player(&"homestead", LONE_WEEDS + Vector2i.DOWN)
	var farm: AreaController = _load(FARM)
	farm.player.face(Vector2.UP)
	assert_object(farm.debris_at(LONE_WEEDS)).is_not_null()
	farm.player.swing()
	for frame: int in 40:
		farm.player.motor.step(Vector2.ZERO, FRAME)
		farm.player.sync_from_motor()
		farm.resolve_combat()
	assert_object(farm.debris_at(LONE_WEEDS)).override_failure_message("the weeds are cut").is_null()
	farm.open_build()
	farm.build.point_at(LONE_WEEDS)
	# The fibre they left lies there: a fence would shut it in, a path may go under it.
	assert_bool(farm.build.lies_at(LONE_WEEDS)).is_true()
	assert_str(farm.build.why_not()).is_equal(Placement.TAKEN_WORDS)
	farm.build.choose_slot(2)
	assert_bool(farm.build.fits()).is_true()
	farm.build.close()
	farm.player.motor.place(LONE_WEEDS)
	farm.player.sync_from_motor()
	farm.collect_pickups()
	assert_int(GameState.item_count(&"fibre")).is_equal(1)
	farm.player.motor.place(LONE_WEEDS + Vector2i.DOWN)
	farm.player.sync_from_motor()
	farm.open_build()
	farm.build.choose_slot(0)
	farm.build.point_at(LONE_WEEDS)
	assert_bool(farm.build.lies_at(LONE_WEEDS)).is_false()
	assert_bool(farm.build.set_down()).override_failure_message("cleared and picked up: a fence stands where the weeds stood").is_true()
	assert_bool(farm.terrain.is_occupied(LONE_WEEDS)).is_true()


# --- helpers ---------------------------------------------------------------

## A stock of the five things of step 2a, in this order on the bar.
func _stock() -> void:
	for item: Array in [[&"fence", 12], [&"gate", 2], [&"dirt_path", 8], [&"stone_path", 8], [&"wood_path", 8]]:
		GameState.add_item(item[0], item[1])


## The homestead with the hero in the yard, facing east.
func _farm() -> AreaController:
	GameState.update_player(&"homestead", START)
	var farm: AreaController = _load(FARM)
	farm.player.face(Vector2.RIGHT)
	return farm


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area


## Walks the hero `direction` for `frames` frames.
func _walk(area: AreaController, direction: Vector2, frames: int) -> void:
	for frame: int in frames:
		area.player.motor.step(direction, FRAME)
	area.player.sync_from_motor()


## A key (or pad button) of `action`, pressed.
func _key(action: StringName) -> InputEventAction:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = true
	return event


## The mouse moved to the area's pixel `at`, as the screen shows it.
func _point_px(area: AreaController, at: Vector2) -> InputEventMouseMotion:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.position = area.build.get_global_transform_with_canvas() * at
	event.global_position = event.position
	return event


## The mouse moved to the middle of `cell`.
func _point(area: AreaController, cell: Vector2i) -> InputEventMouseMotion:
	return _point_px(area, GridBody.cell_center(cell))


## A click in the middle of `cell`.
func _click(area: AreaController, cell: Vector2i, button: MouseButton = MOUSE_BUTTON_LEFT) -> InputEventMouseButton:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = button
	event.pressed = true
	event.position = area.get_global_transform_with_canvas() * GridBody.cell_center(cell)
	event.global_position = event.position
	return event


## The wheel rolled a notch.
func _wheel(button: MouseButton) -> InputEventMouseButton:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = button
	event.pressed = true
	return event


func _on_sound(id: StringName) -> void:
	_heard.append(id)


func _on_homestead_changed() -> void:
	_changes += 1
