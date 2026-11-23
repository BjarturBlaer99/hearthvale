extends GdUnitTestSuite
## The Old Quarry (mining, phase 1): its mouth in the North Fields, its entrance hall, nine
## floors in three bands, the Pickaxe, rocks that stay broken until morning, the day's roll of
## ore and ladder, the lift, a fall that ends in the hall, the clock underground, the dark
## floors and their Bogwisps, and the heart piece on the last.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const FIELDS: String = "res://world/areas/north_fields/north_fields.tscn"
const HALL: String = "res://world/areas/quarry/quarry.tscn"
const FRAME: float = 1.0 / 60.0
const SIDES: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
## The six cells of the fields' east tree line that changed: rock, the mouth, rock.
const OUTCROP: Rect2i = Rect2i(38, 5, 2, 3)
const MOUTH_ROW: int = 6
## Each floor: how many rocks, and its monsters (enemy id -> how many).
const FLOORS: Dictionary = {
	# One more monster on each floor below the first (harder dungeons, 2026-11-23).
	1: [16, {&"slime": 2}], 2: [16, {&"slime": 3, &"goblin_archer": 1}], 3: [16, {&"slime": 4, &"goblin_archer": 1}],
	4: [16, {&"bat": 3, &"slime": 1}], 5: [16, {&"bat": 2, &"goblin_archer": 1, &"slime": 1}], 6: [16, {&"bat": 2, &"goblin_archer": 2, &"slime": 1}],
	7: [14, {&"bogwisp": 3}], 8: [14, {&"bogwisp": 4}], 9: [17, {&"bogwisp": 5}],
}
## The cells the HUD's corner covers at a dungeon's size: nothing he must see is under it.
const UNDER_THE_HUD: Rect2i = Rect2i(0, 0, 5, 3)
## A number for the mine's rolls, so a test knows today's and tomorrow's.
const NUMBER: int = 20261117

var _area: Node
var _heard: Array[StringName] = []
var _went: Array[String] = []


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	Quests.refresh()
	GameState.mine().number = NUMBER
	GameState.add_item(&"wooden_sword")
	GameState.add_item(&"pickaxe")
	GameState.equip(&"pickaxe")
	GameState.set_time(GameState.day_clock().in_day("12:00"))
	_heard.clear()
	_went.clear()
	EventBus.sound.connect(_on_sound)


func after_test() -> void:
	EventBus.sound.disconnect(_on_sound)
	if is_instance_valid(_area):
		_area.free()
	_area = null
	GameState.clear()


func test_the_quarry_is_reached_from_the_north_fields_and_back() -> void:
	var fields: AreaController = _load(FIELDS)
	var mouth: AreaExit = fields.interactables.get_node(^"QuarryMouth")
	assert_that(mouth.cell()).is_equal(Vector2i(38, MOUTH_ROW))
	fields.player.motor.place(Vector2i(36, MOUTH_ROW))
	assert_str(Steps.walk_until_travel(fields, Vector2.RIGHT)).is_equal(HALL)
	assert_dict(GameState.player).is_equal({"area": "quarry", "entry": "mouth"})
	var hall: AreaController = _load(HALL)
	assert_that(hall.player.motor.cell).override_failure_message("just inside").is_equal(Vector2i(1, 3))
	assert_str(hall.area_name).is_equal("The Old Quarry")
	assert_str(Steps.walk_until_travel(hall, Vector2.LEFT)).is_equal(FIELDS)
	assert_dict(GameState.player).is_equal({"area": "north_fields", "entry": "quarry"})
	fields = _load(FIELDS)
	assert_that(fields.player.motor.cell).override_failure_message("outside the mouth, clear of it").is_equal(Vector2i(37, MOUTH_ROW))
	assert_bool(mouth_covers(fields, fields.player.motor.cell)).is_false()


func mouth_covers(fields: AreaController, cell: Vector2i) -> bool:
	return (fields.interactables.get_node(^"QuarryMouth") as AreaExit).covers(cell)


func test_only_six_cells_of_the_north_fields_changed() -> void:
	var fields: AreaController = _load(FIELDS)
	var height: TileMapLayer = fields.get_node(^"Height")
	# The east tree line is solid from top to bottom but for the mouth.
	var open: Array[Vector2i] = []
	for y: int in range(0, 30):
		for x: int in [38, 39]:
			if not fields.grid.is_solid(Vector2i(x, y)):
				open.append(Vector2i(x, y))
	assert_array(open).is_equal([Vector2i(38, MOUTH_ROW), Vector2i(39, MOUTH_ROW)])
	for y: int in range(OUTCROP.position.y, OUTCROP.end.y):
		for x: int in range(OUTCROP.position.x, OUTCROP.end.x):
			var kind: String = "mine_mouth" if y == MOUTH_ROW else "quarry_rock"
			assert_that(height.get_cell_atlas_coords(Vector2i(x, y))).override_failure_message("(%d, %d) is %s" % [x, y, kind]).is_equal(GreyboxTiles.coords(kind))
	# The trees above and below it stand where they stood, and the ground before it is open.
	for cell: Vector2i in [Vector2i(38, 4), Vector2i(39, 4), Vector2i(38, 8), Vector2i(39, 8)]:
		assert_int(height.get_cell_atlas_coords(cell).y).override_failure_message("%s is still a tree's ground" % cell).is_equal(GreyboxTiles.ROW_SOLID_GROUND)
	for y: int in [5, 6, 7]:
		assert_bool(fields.grid.is_solid(Vector2i(37, y))).override_failure_message("(37, %d) is open" % y).is_false()


func test_the_hall_has_the_way_out_the_lift_the_ladder_and_two_rocks() -> void:
	var hall: AreaController = _load(HALL)
	assert_bool(hall.underground).is_true()
	assert_that(hall.music).is_equal(&"mine")
	assert_that(hall.ambience).override_failure_message("shown and lit as a dungeon is").is_equal(Ambience.DUNGEON)
	assert_bool(hall.dark).is_false()
	assert_bool(hall.enemies().is_empty()).override_failure_message("no monsters in the hall").is_true()
	assert_object(hall.interactables.get_node_or_null(^"Lift") as MineLift).is_not_null()
	var down: LadderHole = hall.interactables.get_node(^"LadderDown")
	assert_that(down.target_area).is_equal(&"quarry_1")
	assert_that(down.target_entry).is_equal(MineRules.ARRIVAL)
	# Two rocks to try a pickaxe on: plain stone every day, with no ladder under either.
	assert_int(hall.rocks().size()).is_equal(2)
	for day: int in 5:
		for rock: Rock in hall.rocks():
			assert_that(rock.kind).is_equal(MineRules.STONE)
		assert_that(hall.ladder_cell()).is_equal(MineRolls.NO_CELL)
		GameState.start_next_day()
		hall = _load(HALL)
	# The ladder takes him to the first floor.
	down = hall.interactables.get_node(^"LadderDown")
	hall.player.motor.place(down.cell() + Vector2i.LEFT)
	assert_str(Steps.walk_until_travel(hall, Vector2.RIGHT)).is_equal(WorldPaths.scene_for(&"quarry_1"))
	assert_dict(GameState.player).is_equal({"area": "quarry_1", "entry": "ladder"})


func test_every_floor_has_its_rocks_its_monsters_and_a_way_out() -> void:
	var rules: MineRules = GameState.mine_rules()
	for floor: int in FLOORS:
		var area_id: StringName = rules.area_of(floor)
		GameState.go_to(area_id, MineRules.ARRIVAL)
		var area: AreaController = _load(WorldPaths.scene_for(area_id))
		var where: String = "floor %d" % floor
		assert_that(area.area_id).is_equal(area_id)
		assert_str(area.area_name).override_failure_message(where + " says which floor it is").ends_with("Floor %d" % floor)
		assert_bool(area.underground).override_failure_message(where + " is underground").is_true()
		assert_that(area.music).is_equal(&"mine")
		assert_bool(area.dark).override_failure_message(where + ": the dark begins at floor 7").is_equal(floor >= 7)
		assert_that(area.fall_area).override_failure_message(where + ": a fall ends in the hall").is_equal(rules.hall)
		assert_that(area.fall_entry).is_equal(MineRules.ARRIVAL)
		assert_that(area.grid.size).override_failure_message(where + " is one screen").is_equal(Vector2i(20, 11))
		assert_int(area.rocks().size()).override_failure_message(where + ": rocks").is_equal(FLOORS[floor][0])
		var monsters: Dictionary = {}
		for enemy: Enemy in area.enemies():
			monsters[enemy.enemy_id] = int(monsters.get(enemy.enemy_id, 0)) + 1
		assert_dict(monsters).override_failure_message(where + ": monsters").is_equal(FLOORS[floor][1])
		# He arrives clear of the HUD's corner, with the ladder up in the wall behind him.
		var arrival: Vector2i = area.player.motor.cell
		assert_bool(UNDER_THE_HUD.has_point(arrival)).override_failure_message(where + ": he arrives in plain sight, not at %s" % arrival).is_false()
		var up: AreaExit = area.interactables.get_node(^"LadderUp")
		assert_that(up.cell()).is_equal(arrival + Vector2i.UP)
		assert_that(up.target_area).is_equal(rules.hall)
		assert_that((area.get_node(^"Height") as TileMapLayer).get_cell_atlas_coords(up.cell())).is_equal(GreyboxTiles.coords("ladder_up"))
		# Every rock and every monster can be got to, breaking rocks on the way.
		var reach: Dictionary = _reach(area, arrival, true)
		for rock: Rock in area.rocks():
			assert_bool(reach.has(rock.cell())).override_failure_message(where + ": the rock at %s can be reached" % rock.cell()).is_true()
			assert_bool(UNDER_THE_HUD.has_point(rock.cell())).override_failure_message(where + ": the rock at %s is in plain sight" % rock.cell()).is_false()
			assert_bool(area.terrain.is_occupied(rock.cell())).override_failure_message(where + ": a rock stands in its cell").is_true()
		for enemy: Enemy in area.enemies():
			assert_bool(reach.has(GridBody.cell_of(enemy.position))).override_failure_message(where + ": %s can be reached" % enemy.name).is_true()
		# And the day's roll matches the rules: this floor's ore, and a ladder unless it is the last.
		var held: Dictionary = {}
		for rock: Rock in area.rocks():
			if rock.kind != MineRules.STONE:
				held[rock.kind] = int(held.get(rock.kind, 0)) + 1
		assert_dict(held).override_failure_message(where + ": today's ore").is_equal(rules.ores_of(floor))
		assert_bool(area.ladder_cell() == MineRolls.NO_CELL).override_failure_message(where + ": a ladder down, but for the last").is_equal(floor == 9)
		assert_object(area.ladder()).override_failure_message(where + ": the ladder is hidden").is_null()


func test_the_pickaxe_breaks_a_plain_rock_in_two_blows_for_two_energy_each() -> void:
	var floor: AreaController = _floor(1)
	var rock: Rock = _rock_of(floor, MineRules.STONE)
	var hearts: int = GameState.health
	_face(floor, rock)
	assert_bool(floor.use_item()).is_true()
	assert_bool(rock.broken).override_failure_message("one blow doesn't break it").is_false()
	assert_int(rock.blows_left).is_equal(1)
	assert_float(GameState.energy).is_equal(98.0)
	# The sound comes when the tool lands (tool polish).
	Steps.to_the_blow(floor)
	assert_array(_heard).contains([&"pick"])
	assert_bool(floor.player.motor.is_attacking()).override_failure_message("he stands still for the blow").is_true()
	assert_bool(floor.use_item()).override_failure_message("not again until the blow is done").is_false()
	assert_float(GameState.energy).is_equal(98.0)
	_finish(floor)
	assert_bool(floor.use_item()).is_true()
	assert_bool(rock.broken).is_true()
	assert_float(GameState.energy).is_equal(96.0)
	assert_int(GameState.health).override_failure_message("mining never costs a heart").is_equal(hearts)
	Steps.to_the_blow(floor)
	assert_array(_heard).contains([&"rock_break"])
	assert_bool(floor.terrain.is_occupied(rock.cell())).override_failure_message("its cell is free").is_false()
	assert_bool(GameState.is_rock_broken(floor.area_id, rock.cell())).is_true()
	assert_object(floor.rock_in_front()).override_failure_message("nothing left to face").is_null()


func test_a_swing_at_nothing_costs_nothing_and_says_so() -> void:
	var floor: AreaController = _floor(1)
	var arrival: Vector2i = floor.player.motor.cell
	floor.player.face(Vector2.DOWN)
	assert_object(floor.rock_in_front()).is_null()
	assert_bool(floor.use_item()).is_false()
	assert_str(floor.hud.message_text()).is_equal(MineRules.NOTHING_WORDS)
	assert_array(_heard).contains([&"nope"])
	assert_float(GameState.energy).is_equal(100.0)
	assert_that(floor.player.motor.cell).is_equal(arrival)
	# With the pickaxe in hand the left click is the sword's unless he faces a rock.
	_heard.clear()
	assert_bool(floor.use_hand()).override_failure_message("a swing of the sword").is_true()
	assert_bool(_heard.has(&"nope")).is_false()
	_finish(floor)
	var rock: Rock = _rock_of(floor, MineRules.STONE)
	_face(floor, rock)
	assert_bool(floor.use_hand()).override_failure_message("facing a rock, the click is the pickaxe's").is_true()
	assert_int(rock.blows_left).is_equal(1)


func test_only_the_pickaxe_breaks_a_rock() -> void:
	var floor: AreaController = _floor(1)
	var rock: Rock = _rock_of(floor, MineRules.STONE)
	_face(floor, rock)
	# The sword passes it by, and a rock has nothing a bomb's blast could catch.
	GameState.equip(&"")
	for swing: int in 3:
		assert_bool(floor.player.swing()).is_true()
		for i: int in 40:
			floor.player.motor.step(Vector2.ZERO, FRAME)
			floor.resolve_combat()
	assert_bool(rock.broken).is_false()
	assert_int(rock.blows_left).is_equal(2)
	assert_object(rock.get(&"hurt_box")).override_failure_message("no blast or blade reaches it").is_null()
	assert_float(GameState.energy).override_failure_message("three swings of the sword").is_equal(98.5)


func test_ore_shows_in_the_rock_takes_its_blows_and_lies_where_the_rock_stood() -> void:
	var floor: AreaController = _floor(4)
	var iron: Rock = _rock_of(floor, &"iron_ore")
	var coal: Rock = _rock_of(floor, &"coal")
	assert_int(iron.blows_left).override_failure_message("iron takes three").is_equal(3)
	assert_int(coal.blows_left).is_equal(2)
	_face(floor, iron)
	for blow: int in 3:
		assert_bool(iron.broken).is_false()
		assert_bool(floor.use_item()).is_true()
		_finish(floor)
	assert_bool(iron.broken).is_true()
	assert_float(GameState.energy).is_equal(94.0)
	var drop: ItemDrop = _drop_at(floor, iron.cell())
	assert_object(drop).override_failure_message("the ore lies where the rock stood").is_not_null()
	assert_that(drop.item_id).is_equal(&"iron_ore")
	assert_int(drop.count).is_equal(1)
	assert_int(GameState.item_count(&"iron_ore")).override_failure_message("not his until he picks it up").is_equal(0)
	_put(floor, iron.cell())
	assert_int(floor.collect_pickups()).is_equal(1)
	assert_int(GameState.item_count(&"iron_ore")).is_equal(1)
	assert_array(_heard).contains([&"coin"])
	assert_that(ItemIcons.name_for(&"iron_ore")).is_equal(&"iron_ore")


func test_the_ladder_is_under_a_plain_rock_and_leads_to_the_floor_below() -> void:
	var floor: AreaController = _floor(2)
	var hidden: Vector2i = floor.ladder_cell()
	var rock: Rock = _rock_at(floor, hidden)
	assert_that(rock.kind).override_failure_message("never under ore").is_equal(MineRules.STONE)
	_face(floor, rock)
	for blow: int in 2:
		assert_bool(floor.use_item()).is_true()
		_finish(floor)
	var ladder: LadderHole = floor.ladder()
	assert_object(ladder).is_not_null()
	assert_that(ladder.cell()).is_equal(hidden)
	assert_that(ladder.target_area).is_equal(&"quarry_3")
	assert_that(ladder.target_entry).is_equal(MineRules.ARRIVAL)
	assert_str(floor.hud.message_text()).is_equal(AreaController.LADDER_WORDS)
	assert_array(_heard).contains([&"secret"])
	assert_object(_drop_at(floor, hidden)).override_failure_message("the ladder is what that rock gave").is_null()
	assert_int(GameState.item_count(&"stone")).is_equal(0)
	# Stepping onto it goes down.
	var before: Vector2i = floor.player.motor.cell
	assert_str(Steps.walk_until_travel(floor, Vector2(hidden - before))).is_equal(WorldPaths.scene_for(&"quarry_3"))
	assert_dict(GameState.player).is_equal({"area": "quarry_3", "entry": "ladder"})


func test_the_last_floor_has_no_ladder_down() -> void:
	var floor: AreaController = _floor(9)
	assert_that(floor.ladder_cell()).is_equal(MineRolls.NO_CELL)
	for rock: Rock in floor.rocks():
		rock.strike()
		rock.strike()
		rock.strike()
		assert_bool(rock.broken).is_true()
	assert_object(floor.ladder()).is_null()


func test_broken_rocks_stay_broken_today_and_are_whole_tomorrow_rolled_anew() -> void:
	var floor: AreaController = _floor(1)
	var today: Dictionary = _kinds(floor)
	var hidden: Vector2i = floor.ladder_cell()
	var ore_cell: Vector2i = _rock_of(floor, &"copper_ore").cell()
	for rock: Rock in [_rock_at(floor, ore_cell), _rock_at(floor, hidden)]:
		_face(floor, rock)
		for blow: int in 2:
			assert_bool(floor.use_item()).is_true()
			_finish(floor)
	assert_float(GameState.energy).is_equal(92.0)
	# He leaves and comes back the same day: both are gone, and the ladder stands open.
	floor = _floor(1)
	assert_dict(_kinds(floor)).override_failure_message("the same roll all day").is_equal(today)
	assert_int(_whole(floor)).is_equal(14)
	assert_bool(_rock_at(floor, ore_cell).broken).is_true()
	assert_bool(floor.terrain.is_occupied(ore_cell)).is_false()
	assert_object(floor.rock_in_front()).is_null()
	assert_object(floor.ladder()).override_failure_message("found once, open all day").is_not_null()
	assert_that(floor.ladder().cell()).is_equal(hidden)
	assert_object(_drop_at(floor, ore_cell)).override_failure_message("what he left lying is gone").is_null()
	# The next morning every rock is back, and the roll is another.
	GameState.start_next_day()
	floor = _floor(1)
	assert_int(_whole(floor)).is_equal(16)
	assert_object(floor.ladder()).is_null()
	assert_bool(_kinds(floor) != today or floor.ladder_cell() != hidden).override_failure_message("tomorrow's roll is its own").is_true()
	var cells: Array = today.keys()
	cells.sort()
	var again: Array = _kinds(floor).keys()
	again.sort()
	assert_array(again).override_failure_message("the rocks stand where they stood").is_equal(cells)


func test_the_lift_opens_at_floors_four_and_seven_and_takes_him_there() -> void:
	# Before he has been down, it goes nowhere.
	var hall: AreaController = _load(HALL)
	var lift: MineLift = Steps.stand_before(hall, "Lift")
	assert_str(lift.prompt()).is_equal("Ride the lift")
	assert_bool(hall.talk_to(lift)).is_true()
	assert_str(hall.hud.dialogue.shown_text()).is_equal(MineRules.LIFT_NOWHERE_WORDS)
	assert_array(Array(hall.hud.dialogue.shown_options())).is_equal([MineRules.LIFT_STAY_WORDS])
	hall.hud.dialogue.confirm()
	assert_bool(_went.is_empty()).is_true()
	# Floor 3 is no stop; coming to floor 4 opens the lift to it, and says so once.
	var three: AreaController = _floor(3)
	assert_bool(Array(three.hud.notice_lines()).has(AreaController.LIFT_OPEN_WORDS)).override_failure_message("floor 3 is no stop: nothing is said").is_false()
	assert_bool(GameState.get_flag(MineRules.lift_flag(3)) == true).override_failure_message("and nothing is kept").is_false()
	assert_bool(GameState.get_flag(MineRules.lift_flag(4)) == true).is_false()
	var four: AreaController = _floor(4)
	assert_bool(GameState.get_flag(MineRules.lift_flag(4)) == true).is_true()
	assert_array(Array(four.hud.notice_lines())).contains([AreaController.LIFT_OPEN_WORDS])
	four = _floor(4)
	assert_bool(Array(four.hud.notice_lines()).has(AreaController.LIFT_OPEN_WORDS)).override_failure_message("said the once").is_false()
	_floor(7)
	# Now it offers both, and takes him to the one he chooses.
	hall = _load(HALL)
	lift = Steps.stand_before(hall, "Lift")
	assert_bool(hall.talk_to(lift)).is_true()
	assert_str(hall.hud.dialogue.shown_text()).is_equal(MineRules.LIFT_WORDS)
	assert_array(Array(hall.hud.dialogue.shown_options())).is_equal(["Floor 4", "Floor 7", MineRules.LIFT_STAY_WORDS])
	hall.hud.dialogue.move_cursor(1)
	hall.hud.dialogue.confirm()
	assert_array(_went).is_equal([WorldPaths.scene_for(&"quarry_7")])
	assert_dict(GameState.player).is_equal({"area": "quarry_7", "entry": "ladder"})
	assert_array(_heard).contains([&"lift"])
	# Staying stays.
	hall = _load(HALL)
	_went.clear()
	hall.talk_to(Steps.stand_before(hall, "Lift"))
	hall.hud.dialogue.move_cursor(2)
	hall.hud.dialogue.confirm()
	assert_bool(_went.is_empty()).is_true()
	assert_bool(hall.player.controls_enabled).is_true()


func test_a_fall_in_the_mine_ends_in_the_hall_whole_with_what_he_carries() -> void:
	GameState.add_item(&"copper_ore", 7)
	var floor: AreaController = _floor(5)
	GameState.spend_energy(40.0)
	GameState.damage(GameState.health)
	assert_bool(floor.is_dying()).is_true()
	assert_bool(_went.is_empty()).override_failure_message("he lies a moment first").is_true()
	for i: int in 70:
		floor._process(FRAME)
	assert_array(_went).is_equal([HALL])
	assert_dict(GameState.player).is_equal({"area": "quarry", "entry": "ladder"})
	assert_int(GameState.health).override_failure_message("whole again").is_equal(GameState.max_health())
	assert_int(GameState.item_count(&"copper_ore")).override_failure_message("he keeps what he carries").is_equal(7)
	assert_float(GameState.energy).override_failure_message("a fall gives no energy back").is_equal(60.0)
	assert_str(GameState.arrival_notice).is_equal(AreaController.FELL_WORDS)
	var hall: AreaController = _load(HALL)
	assert_that(hall.player.motor.cell).override_failure_message("by the ladder").is_equal(Vector2i(11, 6))
	assert_str(hall.hud.message_text()).is_equal(AreaController.FELL_WORDS)
	# Out of doors a fall is as it was: back at this area's own entrance.
	var fields: AreaController = _load(FIELDS)
	_went.clear()
	GameState.damage(GameState.health)
	for i: int in 70:
		fields._process(FRAME)
	assert_bool(_went.is_empty()).is_true()
	assert_int(GameState.health).is_equal(GameState.max_health())


func test_the_clock_runs_underground_and_a_day_spent_there_is_gone() -> void:
	var floor: AreaController = _floor(2)
	var noon: float = GameState.minute
	assert_bool(floor.clock_runs()).is_true()
	assert_bool(floor.has_daylight()).override_failure_message("no day's light down here").is_false()
	for i: int in 120:
		floor._process(FRAME)
	assert_float(GameState.minute).override_failure_message("two seconds of the day went by").is_greater(noon + 2.0)
	# No monster is tougher for the hour, here: the night's rules are for out of doors.
	GameState.set_time(GameState.day_clock().in_day("23:00"))
	floor = _floor(2)
	assert_bool(floor.is_night_outdoors()).is_false()
	for enemy: Enemy in floor.enemies():
		assert_bool(enemy.night).is_false()
	# When the day runs out he wakes at home, as from anywhere.
	GameState.set_time(float(GameState.day_clock().ends) - 0.01)
	SaveSystem.current_slot = 961
	floor._process(0.5)
	SaveSystem.current_slot = SaveSystem.GAME_SLOT
	SaveSystem.erase_slot(961)
	assert_array(_went).is_equal([WorldPaths.scene_for(WorldPaths.HOME_AREA)])
	assert_int(GameState.day).is_equal(2)


func test_bogwisps_are_out_at_any_hour_on_the_dark_floors() -> void:
	for hour: String in ["09:00", "12:00", "21:00"]:
		GameState.set_time(GameState.day_clock().in_day(hour))
		var floor: AreaController = _floor(7)
		assert_bool(floor.dark).is_true()
		assert_int(floor.enemies().size()).is_equal(3)
		for wisp: Enemy in floor.enemies():
			assert_bool(wisp.waits_for_night()).override_failure_message("the same Bogwisp as the marsh's").is_true()
			assert_bool(wisp.lying_low).override_failure_message("%s: out, at %s" % [wisp.name, hour]).is_false()
			assert_bool(wisp.night).override_failure_message("and no tougher for the hour").is_false()
	# Without a lantern he sees a cell or so, and a wisp has no body.
	var dark: AreaController = _floor(7)
	assert_float(dark.hero_light_radius()).is_equal(AreaController.DIM_RADIUS)
	var wisp: Enemy = dark.enemies()[0]
	assert_bool(dark.holds_at(wisp.position)).is_false()
	GameState.add_item(&"lantern")
	_put(dark, GridBody.cell_of(wisp.position) + Vector2i.LEFT)
	assert_bool(dark.holds_at(wisp.position)).override_failure_message("the Lantern's light gives it a body").is_true()


func test_the_heart_piece_on_the_last_floor_is_walled_in_by_rocks() -> void:
	var floor: AreaController = _floor(9)
	var piece: HeartPiece = floor.interactables.get_node(^"QuarryHeartPiece")
	assert_that(piece.taken_flag).is_equal(&"took_quarry_heart_piece")
	var arrival: Vector2i = floor.player.motor.cell
	assert_bool(_reach(floor, arrival, false).has(piece.cell())).override_failure_message("not without breaking a rock").is_false()
	assert_bool(_reach(floor, arrival, true).has(piece.cell())).override_failure_message("through the rocks, yes").is_true()
	# Break one of the three that wall it in, and the way is open.
	var wall: Rock = _rock_at(floor, Vector2i(16, 3))
	for blow: int in 3:
		wall.strike()
	assert_bool(_reach(floor, arrival, false).has(piece.cell())).is_true()
	_put(floor, piece.cell())
	floor.collect_pickups()
	assert_bool(GameState.get_flag(&"took_quarry_heart_piece") == true).is_true()
	assert_int(GameState.heart_pieces).is_equal(1)
	# Taken once: it isn't there tomorrow, though the rocks are.
	GameState.start_next_day()
	floor = _floor(9)
	assert_bool((floor.interactables.get_node(^"QuarryHeartPiece") as HeartPiece).is_there()).is_false()
	assert_int(_whole(floor)).is_equal(17)


func test_what_a_full_pack_cant_take_stays_lying_and_he_is_told_once() -> void:
	GameState.add_item(&"stone", 50)
	var floor: AreaController = _floor(1)
	var rock: Rock = _rock_of(floor, MineRules.STONE)
	_face(floor, rock)
	for blow: int in 2:
		assert_bool(floor.use_item()).override_failure_message("a full pack doesn't stop the pickaxe").is_true()
		_finish(floor)
	var drop: ItemDrop = _drop_at(floor, rock.cell())
	assert_object(drop).is_not_null()
	_put(floor, rock.cell())
	assert_int(floor.collect_pickups()).is_equal(0)
	assert_bool(drop.taken).override_failure_message("it stays where it lies").is_false()
	assert_int(GameState.item_count(&"stone")).is_equal(50)
	assert_str(floor.hud.message_text()).is_equal(AreaController.NO_ROOM_WORDS % "stone")
	floor.hud.show_message("Something else.")
	floor.collect_pickups()
	assert_str(floor.hud.message_text()).override_failure_message("told the once").is_equal("Something else.")
	# With room for it, it is his.
	GameState.add_item(&"stone", -1)
	assert_int(floor.collect_pickups()).is_equal(1)
	assert_int(GameState.item_count(&"stone")).is_equal(50)


func test_tilda_sells_the_pickaxe_once() -> void:
	GameState.add_item(&"pickaxe", -1)
	GameState.add_item(&"coin", 60)
	var ware: Dictionary = {}
	for entry: Dictionary in Shop.wares(DataRegistry.get_shop(&"tilda"), DataRegistry.entries(&"crops")):
		if str(entry["item"]) == "pickaxe":
			ware = entry
	assert_dict(ware).is_equal({"item": "pickaxe", "count": 1, "price": 25})
	assert_str(GameState.buy(ware)).is_equal("")
	assert_int(GameState.item_count(&"pickaxe")).is_equal(1)
	assert_int(GameState.item_count(&"coin")).is_equal(35)
	assert_str(GameState.buy(ware)).override_failure_message("he needs only one").is_equal(Shop.NO_ROOM)
	assert_int(GameState.item_count(&"coin")).is_equal(35)
	# It goes on the bar with the other tools, and is a tool of the kind "pick".
	var pick: Dictionary = DataRegistry.get_item(&"pickaxe")
	assert_str(ToolUse.kind_of(pick)).is_equal(ToolUse.PICK)
	assert_int(ToolUse.fewer_blows(pick)).is_equal(0)
	assert_bool(Inventory.is_equippable(pick)).is_true()
	assert_that(ItemIcons.name_for(&"pickaxe")).is_equal(&"pickaxe")
	assert_dict(ToolUse.decide_pick(true)).is_equal({"does": ToolUse.MINE, "says": ""})
	assert_dict(ToolUse.decide_pick(false)).is_equal({"does": ToolUse.NOTHING, "says": MineRules.NOTHING_WORDS})


# --- Helpers -------------------------------------------------------------------------------

func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	(_area as AreaController).travel = func(to: String) -> void: _went.append(to)
	return _area


## Arrives on floor `number` by its ladder.
func _floor(number: int) -> AreaController:
	var area_id: StringName = GameState.mine_rules().area_of(number)
	GameState.go_to(area_id, MineRules.ARRIVAL)
	return _load(WorldPaths.scene_for(area_id))


## The cells that can be walked to from `from`: open ground, by way of the rocks' cells too if
## `through_rocks` (they can be broken), else only round them.
func _reach(area: AreaController, from: Vector2i, through_rocks: bool) -> Dictionary:
	var rocks: Dictionary = {}
	for rock: Rock in area.rocks():
		if not rock.broken:
			rocks[rock.cell()] = true
	var seen: Dictionary = {from: true}
	var queue: Array[Vector2i] = [from]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_back()
		for side: Vector2i in SIDES:
			var next: Vector2i = cell + side
			if seen.has(next) or not area.grid.in_bounds(next) or area.grid.is_solid(next):
				continue
			if rocks.has(next) and not through_rocks:
				continue
			seen[next] = true
			queue.append(next)
	return seen


## Stands the hero beside `rock`, facing it, on open ground with nothing in it.
func _face(area: AreaController, rock: Rock) -> void:
	for side: Vector2i in SIDES:
		var at: Vector2i = rock.cell() + side
		if area.grid.in_bounds(at) and not area.grid.is_solid(at) and not area.terrain.is_occupied(at) \
				and area.grid.height_at(at) == area.grid.height_at(rock.cell()):
			area.player.motor.place(at)
			area.player.face(Vector2(-side))
			return
	fail("no open ground beside the rock at %s" % rock.cell())


## Puts the hero in `cell`, and his body with him (what touches a pickup is his body).
func _put(area: AreaController, cell: Vector2i) -> void:
	area.player.motor.place(cell)
	area.player.sync_from_motor()


## Lets a blow finish.
func _finish(area: AreaController) -> void:
	for i: int in 40:
		area.player.motor.step(Vector2.ZERO, FRAME)


## A whole rock of `kind` with open ground beside it.
func _rock_of(area: AreaController, kind: StringName) -> Rock:
	for rock: Rock in area.rocks():
		if rock.kind != kind or rock.broken or rock.cell() == area.ladder_cell():
			continue
		for side: Vector2i in SIDES:
			var at: Vector2i = rock.cell() + side
			if area.grid.in_bounds(at) and not area.grid.is_solid(at) and not area.terrain.is_occupied(at) \
					and area.grid.height_at(at) == area.grid.height_at(rock.cell()):
				return rock
	fail("no %s rock to get at" % kind)
	return null


func _rock_at(area: AreaController, cell: Vector2i) -> Rock:
	for rock: Rock in area.rocks():
		if rock.cell() == cell:
			return rock
	fail("no rock at %s" % cell)
	return null


func _drop_at(area: AreaController, cell: Vector2i) -> ItemDrop:
	for child: Node in area.interactables.get_children():
		if child is ItemDrop and not (child as ItemDrop).taken and GridBody.cell_of(child.position + Vector2(8, 8)) == cell:
			return child
	return null


func _kinds(area: AreaController) -> Dictionary:
	var out: Dictionary = {}
	for rock: Rock in area.rocks():
		out[rock.cell()] = rock.kind
	return out


func _whole(area: AreaController) -> int:
	var whole: int = 0
	for rock: Rock in area.rocks():
		if not rock.broken:
			whole += 1
	return whole


func _on_sound(id: StringName) -> void:
	_heard.append(id)
