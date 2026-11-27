extends GdUnitTestSuite
## The overgrowth (the Homestead, phase 1, step 1b): weeds, bushes, fallen logs, old stumps,
## rocks, boulders and great boulders stand on the hero's land. The sword clears weeds and
## bushes, the axe logs and stumps (icons-axe-bar plan, step A2: the sword did until then),
## and the pickaxe the rocks; a boulder wants the Copper Pickaxe and a great boulder the Iron. What one leaves lies in its cell. Cleared is cleared: no visit, morning or save
## brings it back. A cell with something on it can't be tilled.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const FARM: String = "res://world/areas/homestead/homestead.tscn"
const VILLAGE: String = "res://world/areas/village/village.tscn"
const TEST_SLOT: int = 950
const FRAME: float = 1.0 / 60.0
const SIDES: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]
## The whole field and its clear corner, the farmhouse, the pond, and where he comes in.
const FIELD: Rect2i = Rect2i(22, 17, 12, 6)
const CLEAR: Rect2i = Rect2i(22, 17, 6, 3)
const HOUSE: Rect2i = Rect2i(26, 8, 6, 4)
## The yard: the row of ground before the farmhouse's front.
const YARD: Rect2i = Rect2i(26, 12, 6, 1)
const POND: Rect2i = Rect2i(4, 21, 6, 4)
const WAY_IN: Vector2i = Vector2i(38, 14)
const DOORSTEP: Vector2i = Vector2i(28, 12)
## How many of each stand on the land in a new game, and on the field (the plan's table).
const ON_THE_LAND: Dictionary = {
	&"weeds": 70, &"bush": 16, &"log": 10, &"farm_stump": 14, &"rock": 24, &"boulder": 8, &"great_boulder": 3,
}
const ON_THE_FIELD: Dictionary = {&"weeds": 40, &"bush": 5, &"log": 2, &"farm_stump": 2, &"rock": 5}
## What the sword and the axe clear: [kind, blows, what it leaves, how many, what cuts it].
const SWORD_KINDS: Array = [
	[&"weeds", 1, &"fibre", 1, "sword"], [&"bush", 2, &"fibre", 2, "sword"], [&"log", 3, &"wood", 3, "axe"], [&"farm_stump", 3, &"wood", 2, "axe"],
]
## One of each with nothing else near it (a swing catches only it) and grass below it.
const ALONE: Dictionary = {
	&"weeds": Vector2i(36, 5), &"bush": Vector2i(7, 17), &"log": Vector2i(7, 4), &"farm_stump": Vector2i(24, 2),
	&"rock": Vector2i(3, 4),
}
const BOULDERS: Array[Vector2i] = [Vector2i(14, 7), Vector2i(5, 9), Vector2i(7, 14)]
const GREAT_BOULDERS: Array[Vector2i] = [Vector2i(11, 21), Vector2i(13, 21)]

var _area: Node
var _heard: Array[StringName] = []
var _changes: int = 0


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	Quests.refresh()
	GameState.add_item(&"wooden_sword")
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


func test_the_seven_kinds_are_data_and_fibre_is_a_material() -> void:
	for row: Array in SWORD_KINDS:
		var kind: Dictionary = DataRegistry.get_breakable(row[0])
		assert_bool(kind.is_empty()).override_failure_message("%s is data" % row[0]).is_false()
		assert_array(kind["breaks_on"]).override_failure_message("%s: the %s and a bomb, and nothing else" % [row[0], row[4]]).contains_exactly_in_any_order([row[4], "bomb"])
		assert_str(str(kind["returns"])).override_failure_message("%s never comes back" % row[0]).is_equal("never")
		assert_int(int(kind.get("hits", 1))).override_failure_message("%s: blows" % row[0]).is_equal(row[1])
		assert_bool(Breakable.FRAMES.has(StringName(str(kind["frames"]["whole"])))).is_true()
		assert_str(str(kind["frames"].get("broken", ""))).override_failure_message("nothing is left standing").is_equal("")
		for roll: float in [0.0, 0.5, 0.999]:
			var drop: Dictionary = DropTable.roll(kind["drops"], roll)
			assert_str(str(drop.get("item", ""))).override_failure_message("%s always leaves %s" % [row[0], row[2]]).is_equal(String(row[2]))
			assert_int(int(drop.get("count", 1))).is_equal(row[3])
	var rules: HomesteadRules = GameState.homestead_rules()
	assert_array(rules.rock_kinds()).is_equal([&"rock", &"boulder", &"great_boulder"])
	for kind: StringName in rules.rock_kinds():
		assert_bool(Rock.FRAMES.has(kind)).override_failure_message("%s has its picture" % kind).is_true()
	# Fibre is a new material: it stacks, has its picture, and is not to be eaten.
	var fibre: Dictionary = DataRegistry.get_item(&"fibre")
	assert_str(str(fibre["name"])).is_equal("Fibre")
	assert_str(str(fibre["type"])).is_equal("material")
	assert_int(Inventory.capacity(fibre)).is_equal(50)
	assert_that(ItemIcons.name_for(&"fibre")).is_equal(&"fibre")
	GameState.add_item(&"fibre")
	assert_bool(GameState.eat(&"fibre")).is_false()
	# The stump and the branch of the countryside are as they were: back each morning.
	for old: StringName in [&"branch", &"stump"]:
		assert_str(str(DataRegistry.get_breakable(old)["returns"])).override_failure_message(String(old)).is_equal("daily")
	assert_array(Array(DataRegistry.errors)).is_empty()


func test_the_land_carries_what_the_plan_counted() -> void:
	var farm: AreaController = _load(FARM)
	var layer: TileMapLayer = farm.get_node(^"Height")
	var counts: Dictionary = {}
	var on_field: Dictionary = {}
	var gives: Dictionary = {}
	for thing: Node2D in farm.debris():
		var kind: StringName = _kind_of(thing)
		var cell: Vector2i = thing.call(&"cell")
		counts[kind] = int(counts.get(kind, 0)) + 1
		if FIELD.has_point(cell):
			on_field[kind] = int(on_field.get(kind, 0)) + 1
		# Each stands in its own cell, on open ground, and nowhere it has no business.
		assert_bool(farm.terrain.is_occupied(cell)).override_failure_message("%s stands in %s" % [kind, cell]).is_true()
		assert_bool(farm.grid.is_solid(cell)).override_failure_message("%s at %s is on open ground" % [kind, cell]).is_false()
		assert_object(farm.debris_at(cell)).is_same(thing)
		assert_bool(CLEAR.has_point(cell)).override_failure_message("%s: the clear corner is clear" % cell).is_false()
		assert_that(layer.get_cell_atlas_coords(cell)).override_failure_message("%s: on grass, never on the road or the path" % cell).is_equal(GreyboxTiles.coords("ground"))
		assert_bool(YARD.has_point(cell)).override_failure_message("%s: the yard before the house is clear" % cell).is_false()
		assert_bool(HOUSE.has_point(cell) or POND.has_point(cell)).is_false()
		# None is behind a tree's crown: what blocks his way is in plain sight. (Twenty of the
		# plan's drawing stood under the woods' edge or an old tree, and were moved a cell or two.)
		assert_array(farm.scenery.hiding(GridBody.cell_center(cell))).override_failure_message("%s at %s is clear of the trees" % [kind, cell]).is_empty()
		assert_object(farm.exit_at(cell)).is_null()
		var leaves: Array = _leaves(kind)
		gives[leaves[0]] = int(gives.get(leaves[0], 0)) + int(leaves[1])
	assert_dict(counts).is_equal(ON_THE_LAND)
	assert_dict(on_field).override_failure_message("on the field: nothing there wants a better tool").is_equal(ON_THE_FIELD)
	assert_int(farm.debris().size()).is_equal(145)
	assert_dict(gives).override_failure_message("what the whole land gives").is_equal({&"fibre": 102, &"wood": 58, &"stone": 80})
	assert_int(GameState.homestead().cleared_count()).is_equal(0)
	# With nothing cleared he can walk from the road to his door, to every cell of the clear
	# corner, and to the pond's bank.
	var reach: Dictionary = _reach(farm, WAY_IN, [])
	assert_bool(reach.has(DOORSTEP)).is_true()
	for x: int in CLEAR.size.x:
		for y: int in CLEAR.size.y:
			assert_bool(reach.has(CLEAR.position + Vector2i(x, y))).override_failure_message("the clear corner at %s" % (CLEAR.position + Vector2i(x, y))).is_true()
	var banks: int = 0
	for cell: Vector2i in reach:
		for side: Vector2i in SIDES:
			if POND.has_point(cell + side):
				banks += 1
				break
	assert_int(banks).override_failure_message("a bank of the pond can be walked to").is_greater(0)
	# And with the sword, the axe and the plain pickaxe he can open up every cell of the land but the
	# boulders' own: nothing is walled in behind a tool he has to wait for.
	var all_open: Dictionary = _reach(farm, WAY_IN, [&"weeds", &"bush", &"log", &"farm_stump", &"rock"])
	for y: int in farm.grid.size.y:
		for x: int in farm.grid.size.x:
			var cell: Vector2i = Vector2i(x, y)
			if farm.grid.is_solid(cell) or farm.exit_at(cell) != null:
				continue
			var thing: Node2D = farm.debris_at(cell)
			if thing != null and (_kind_of(thing) == &"boulder" or _kind_of(thing) == &"great_boulder"):
				var beside: bool = false
				for side: Vector2i in SIDES:
					beside = beside or all_open.has(cell + side)
				assert_bool(beside).override_failure_message("the boulder at %s can be got at" % cell).is_true()
				continue
			assert_bool(all_open.has(cell)).override_failure_message("%s can be reached with the plain tools" % cell).is_true()


func test_the_sword_clears_weeds_and_bushes_the_axe_logs_and_stumps_and_each_leaves_its_drop() -> void:
	GameState.add_item(&"axe")
	var farm: AreaController = _load(FARM)
	var swings: int = 0
	for row: Array in SWORD_KINDS:
		var kind: StringName = row[0]
		var thing: Breakable = farm.debris_at(ALONE[kind]) as Breakable
		assert_object(thing).override_failure_message("%s at %s" % [kind, ALONE[kind]]).is_not_null()
		assert_that(thing.breakable_id).is_equal(kind)
		assert_int(thing.hits_left).is_equal(row[1])
		for blow: int in int(row[1]) - 1:
			_cut(farm, thing, row[4])
			swings += 1
			assert_bool(thing.broken).override_failure_message("%s: blow %d doesn't clear it" % [kind, blow + 1]).is_false()
			assert_bool(farm.terrain.is_occupied(thing.cell())).is_true()
			assert_object(thing.dropped).is_null()
			assert_bool(GameState.homestead().is_cleared(thing.cell())).is_false()
		var changes: int = _changes
		_cut(farm, thing, row[4])
		swings += 1
		assert_bool(thing.broken).override_failure_message("%s is cleared by blow %d" % [kind, row[1]]).is_true()
		assert_bool(farm.terrain.is_occupied(thing.cell())).override_failure_message("its cell is free").is_false()
		assert_object(farm.debris_at(thing.cell())).is_null()
		assert_bool(GameState.homestead().is_cleared(thing.cell())).override_failure_message("%s is cleared for good" % kind).is_true()
		assert_int(_changes).override_failure_message("and it is said once").is_equal(changes + 1)
		# What it leaves lies in its cell, and is his when he walks onto it.
		var drop: ItemDrop = thing.dropped as ItemDrop
		assert_object(drop).override_failure_message("%s leaves something" % kind).is_not_null()
		assert_that(drop.item_id).is_equal(row[2])
		assert_int(drop.count).is_equal(row[3])
		assert_that(GridBody.cell_of(drop.position + Vector2(8, 8))).is_equal(thing.cell())
		assert_int(GameState.item_count(row[2])).override_failure_message("not in the pack until he walks onto it").is_equal(_carried_before(kind))
		_put(farm, thing.cell())
		assert_int(farm.collect_pickups()).is_equal(1)
	assert_int(GameState.item_count(&"fibre")).is_equal(3)
	assert_int(GameState.item_count(&"wood")).is_equal(5)
	assert_bool(GameState.has_found(&"fibre")).is_true()
	assert_int(swings).is_equal(9)
	assert_float(GameState.energy).override_failure_message("nine blows of the sword and the axe, no more").is_equal(100.0 - 9 * 0.5)
	assert_int(GameState.homestead().cleared_count()).is_equal(4)
	# A swing at a rock does nothing to it: only the pickaxe breaks a rock.
	var rock: Rock = farm.debris_at(ALONE[&"rock"]) as Rock
	for swing: int in 3:
		_swing_at(farm, rock)
	assert_bool(rock.broken).is_false()
	assert_int(rock.blows_left).is_equal(2)
	assert_bool(farm.terrain.is_occupied(rock.cell())).is_true()


func test_the_pickaxe_breaks_a_rock_in_two_blows_for_a_stone() -> void:
	GameState.add_item(&"pickaxe")
	GameState.equip(&"pickaxe")
	var farm: AreaController = _load(FARM)
	var rock: Rock = farm.debris_at(ALONE[&"rock"]) as Rock
	assert_that(rock.kind).is_equal(&"rock")
	assert_int(rock.blows_left).is_equal(2)
	_face(farm, rock)
	assert_object(farm.rock_in_front()).is_same(rock)
	assert_bool(farm.use_item()).is_true()
	assert_bool(rock.broken).override_failure_message("one blow doesn't break it").is_false()
	# The sound comes when the tool lands (tool polish).
	Steps.to_the_blow(farm)
	assert_array(_heard).contains([&"pick"])
	assert_float(GameState.energy).is_equal(98.0)
	_finish(farm)
	# The left click is the pickaxe's when he faces a rock.
	assert_bool(farm.use_hand()).is_true()
	assert_bool(rock.broken).is_true()
	Steps.to_the_blow(farm)
	assert_array(_heard).contains([&"rock_break"])
	assert_float(GameState.energy).override_failure_message("two energy a blow, as in the quarry").is_equal(96.0)
	assert_bool(farm.terrain.is_occupied(rock.cell())).is_false()
	assert_bool(GameState.homestead().is_cleared(rock.cell())).is_true()
	assert_int(_changes).is_equal(1)
	var drop: ItemDrop = _drop_at(farm, rock.cell())
	assert_that(drop.item_id).is_equal(&"stone")
	assert_int(drop.count).is_equal(1)
	_put(farm, rock.cell())
	assert_int(farm.collect_pickups()).is_equal(1)
	assert_int(GameState.item_count(&"stone")).is_equal(1)
	# A plain rock is no practice at mining (as in the quarry), and nothing is kept in the
	# mine's record of today's broken rocks: this one is gone for good.
	assert_int(int(GameState.skill_points.get(Skills.MINING, 0))).is_equal(0)
	assert_bool(GameState.is_rock_broken(&"homestead", rock.cell())).is_false()
	# A better pickaxe breaks a rock in one.
	_finish(farm)
	GameState.add_item(&"copper_pickaxe")
	GameState.equip(&"copper_pickaxe")
	var other: Rock = farm.debris_at(Vector2i(36, 19)) as Rock
	_face(farm, other)
	assert_bool(farm.use_item()).is_true()
	assert_bool(other.broken).is_true()


func test_a_boulder_wants_the_copper_pickaxe_and_a_great_boulder_the_iron() -> void:
	for pick: StringName in [&"pickaxe", &"copper_pickaxe", &"iron_pickaxe"]:
		GameState.add_item(pick)
	var farm: AreaController = _load(FARM)
	var boulder: Rock = farm.debris_at(BOULDERS[0]) as Rock
	var great: Rock = farm.debris_at(GREAT_BOULDERS[0]) as Rock
	assert_that(boulder.kind).is_equal(&"boulder")
	assert_that(great.kind).is_equal(&"great_boulder")
	# The plain pickaxe at a boulder: told so, and nothing is spent or struck.
	GameState.equip(&"pickaxe")
	for hard: Rock in [boulder, great]:
		_face(farm, hard)
		var blows: int = hard.blows_left
		_heard.clear()
		farm.hud.show_message("-")
		assert_bool(farm.use_item()).override_failure_message("the plain pickaxe at a %s" % hard.kind).is_false()
		assert_str(farm.hud.message_text()).is_equal("It wants a better pickaxe.")
		assert_str(ToolUse.PICK_WEAK).is_equal("It wants a better pickaxe.")
		assert_array(_heard).contains_exactly([&"nope"])
		assert_float(GameState.energy).override_failure_message("no energy is spent").is_equal(100.0)
		assert_int(hard.blows_left).override_failure_message("and no blow fell").is_equal(blows)
		assert_bool(farm.player.motor.state_name == PlayerMotor.GROUND).override_failure_message("he doesn't swing").is_true()
		# The left click says the same: he faces a rock, so it is the pickaxe's.
		farm.hud.show_message("-")
		assert_bool(farm.use_hand()).is_false()
		assert_str(farm.hud.message_text()).is_equal(ToolUse.PICK_WEAK)
	assert_float(GameState.energy).is_equal(100.0)
	# The Copper Pickaxe: a boulder in three blows, four stone; a great boulder refuses it.
	GameState.equip(&"copper_pickaxe")
	_face(farm, great)
	assert_bool(farm.use_item()).override_failure_message("the Copper Pickaxe at a great boulder").is_false()
	assert_str(farm.hud.message_text()).is_equal(ToolUse.PICK_WEAK)
	assert_float(GameState.energy).is_equal(100.0)
	_face(farm, boulder)
	for blow: int in 3:
		assert_bool(boulder.broken).override_failure_message("blow %d" % blow).is_false()
		assert_bool(farm.use_item()).is_true()
		_finish(farm)
	assert_bool(boulder.broken).override_failure_message("three blows of the Copper Pickaxe").is_true()
	assert_float(GameState.energy).is_equal(94.0)
	assert_int(_drop_at(farm, boulder.cell()).count).is_equal(4)
	assert_that(_drop_at(farm, boulder.cell()).item_id).is_equal(&"stone")
	assert_bool(GameState.homestead().is_cleared(boulder.cell())).is_true()
	# The Iron Pickaxe: a boulder in two, a great boulder in three for eight stone.
	GameState.equip(&"iron_pickaxe")
	var second: Rock = farm.debris_at(BOULDERS[1]) as Rock
	_face(farm, second)
	for blow: int in 2:
		assert_bool(second.broken).is_false()
		assert_bool(farm.use_item()).is_true()
		_finish(farm)
	assert_bool(second.broken).override_failure_message("two blows of the Iron Pickaxe").is_true()
	_face(farm, great)
	for blow: int in 3:
		assert_bool(great.broken).override_failure_message("blow %d" % blow).is_false()
		assert_bool(farm.use_item()).is_true()
		_finish(farm)
	assert_bool(great.broken).override_failure_message("three blows of the Iron Pickaxe").is_true()
	assert_int(_drop_at(farm, great.cell()).count).is_equal(8)
	assert_bool(farm.terrain.is_occupied(great.cell())).is_false()
	assert_float(GameState.energy).override_failure_message("eight blows in all").is_equal(84.0)
	assert_int(GameState.homestead().cleared_count()).is_equal(3)
	assert_int(int(GameState.skill_points.get(Skills.MINING, 0))).override_failure_message("stone is no practice").is_equal(0)


func test_cleared_stays_cleared_through_a_visit_a_morning_and_a_save() -> void:
	GameState.add_item(&"pickaxe")
	var farm: AreaController = _load(FARM)
	var weeds: Vector2i = ALONE[&"weeds"]
	var rock_cell: Vector2i = ALONE[&"rock"]
	_swing_at(farm, farm.debris_at(weeds))
	GameState.equip(&"pickaxe")
	var rock: Rock = farm.debris_at(rock_cell) as Rock
	_face(farm, rock)
	for blow: int in 2:
		assert_bool(farm.use_item()).is_true()
		_finish(farm)
	assert_int(GameState.homestead().cleared_count()).is_equal(2)
	# Leaving and coming back.
	farm = _load(FARM)
	_is_gone(farm, weeds, "on the next visit")
	_is_gone(farm, rock_cell, "on the next visit")
	assert_int(farm.debris().size()).override_failure_message("the others stand").is_equal(143)
	# The next morning, and the one after: a branch in the countryside would be back, and a
	# rock in the quarry.
	GameState.start_next_day()
	GameState.start_next_day()
	farm = _load(FARM)
	_is_gone(farm, weeds, "two mornings on")
	_is_gone(farm, rock_cell, "two mornings on")
	# Through a save.
	GameState.update_player(&"homestead", WAY_IN)
	assert_int(SaveSystem.save_to_slot(TEST_SLOT)).is_equal(OK)
	GameState.clear()
	GameState.new_game()
	farm = _load(FARM)
	assert_int(farm.debris().size()).override_failure_message("a new game's land is overgrown").is_equal(145)
	assert_int(SaveSystem.load_from_slot(TEST_SLOT)).is_equal(OK)
	farm = _load(FARM)
	_is_gone(farm, weeds, "after loading")
	_is_gone(farm, rock_cell, "after loading")
	assert_int(farm.debris().size()).is_equal(143)
	assert_array(GameState.homestead().cleared_cells()).contains_exactly_in_any_order([weeds, rock_cell])
	# No flag keeps it, and the mine's record doesn't: only the homestead's own.
	for flag: StringName in GameState.flags:
		assert_bool(String(flag).begins_with("cut/homestead")).override_failure_message(String(flag)).is_false()
	# The same cell of another map is no cell of his land.
	assert_bool(GameState.is_debris_cleared(&"village", weeds)).is_false()
	assert_bool(GameState.clear_debris(&"village", Vector2i(5, 5))).override_failure_message("nothing is cleared for good off his land").is_false()
	assert_bool(GameState.homestead().is_cleared(Vector2i(5, 5))).is_false()
	assert_bool(GameState.clear_debris(&"homestead", weeds)).override_failure_message("cleared already: no news").is_false()


func test_a_full_pack_leaves_the_drop_lying_and_the_land_is_cleared_all_the_same() -> void:
	GameState.add_item(&"fibre", 50)
	var farm: AreaController = _load(FARM)
	var weeds: Breakable = farm.debris_at(ALONE[&"weeds"]) as Breakable
	_swing_at(farm, weeds)
	assert_bool(weeds.broken).override_failure_message("a full pack doesn't stop the sword").is_true()
	var drop: ItemDrop = weeds.dropped as ItemDrop
	_put(farm, weeds.cell())
	assert_int(farm.collect_pickups()).is_equal(0)
	assert_bool(drop.taken).override_failure_message("it stays where it lies").is_false()
	assert_int(GameState.item_count(&"fibre")).is_equal(50)
	assert_str(farm.hud.message_text()).is_equal(AreaController.NO_ROOM_WORDS % "fibre")
	farm.hud.show_message("Something else.")
	farm.collect_pickups()
	assert_str(farm.hud.message_text()).override_failure_message("told the once").is_equal("Something else.")
	assert_bool(GameState.homestead().is_cleared(weeds.cell())).is_true()
	# With room for it, it is his.
	GameState.add_item(&"fibre", -1)
	assert_int(farm.collect_pickups()).is_equal(1)
	assert_int(GameState.item_count(&"fibre")).is_equal(50)
	# The same with a boulder's four stone when there is room for three.
	GameState.add_item(&"stone", 47)
	GameState.add_item(&"iron_pickaxe")
	GameState.equip(&"iron_pickaxe")
	var boulder: Rock = farm.debris_at(BOULDERS[2]) as Rock
	_face(farm, boulder)
	for blow: int in 2:
		assert_bool(farm.use_item()).is_true()
		_finish(farm)
	assert_bool(boulder.broken).is_true()
	_put(farm, boulder.cell())
	assert_int(farm.collect_pickups()).is_equal(0)
	assert_int(GameState.item_count(&"stone")).override_failure_message("all four or none: nothing is lost").is_equal(47)
	assert_bool(_drop_at(farm, boulder.cell()).taken).is_false()


func test_the_hoe_refuses_a_cell_under_debris_until_it_is_cleared() -> void:
	for item: StringName in [&"hoe", &"copper_hoe", &"pickaxe", &"watering_can", &"turnip_seeds"]:
		GameState.add_item(item)
	GameState.add_item(&"water", 5)
	var farm: AreaController = _load(FARM)
	# Weeds on the field's first row, east of the clear corner; a rock in its fourth row.
	var weeds_cell: Vector2i = Vector2i(28, 17)
	var rock_cell: Vector2i = Vector2i(23, 20)
	assert_that((farm.debris_at(weeds_cell) as Breakable).breakable_id).is_equal(&"weeds")
	assert_that((farm.debris_at(rock_cell) as Rock).kind).is_equal(&"rock")
	for case: Array in [[weeds_cell, Vector2i(27, 17), Vector2.RIGHT], [rock_cell, Vector2i(23, 19), Vector2.DOWN]]:
		GameState.equip(&"hoe")
		farm.player.motor.place(case[1])
		farm.player.face(case[2])
		assert_that(farm.player.front_cell()).is_equal(case[0])
		_heard.clear()
		assert_bool(farm.use_item()).override_failure_message("the hoe at %s" % case[0]).is_false()
		assert_str(farm.hud.message_text()).is_equal("Clear this first.")
		assert_str(ToolUse.CLEAR_FIRST).is_equal("Clear this first.")
		assert_array(_heard).contains_exactly([&"nope"])
		assert_float(GameState.energy).override_failure_message("nothing is spent").is_equal(100.0)
		assert_that(farm.plot.soil_at(case[0])).is_equal(Farm.BARE)
		# Seeds and the can are told the same, and nothing of them is used.
		for other: StringName in [&"turnip_seeds", &"watering_can"]:
			GameState.equip(other)
			farm.hud.show_message("-")
			assert_bool(farm.use_item()).override_failure_message("the %s at %s" % [other, case[0]]).is_false()
			assert_str(farm.hud.message_text()).is_equal(ToolUse.CLEAR_FIRST)
	assert_int(GameState.item_count(&"water")).is_equal(5)
	assert_int(GameState.farm().count_of(Farm.TILLED)).is_equal(0)
	assert_int(GameState.item_count(&"turnip_seeds")).is_equal(1)
	# A left click with the hoe in hand says the same on the field (the field is the hoe's
	# work); off the field the click is the sword's, as it always was, and cuts the weeds.
	GameState.equip(&"hoe")
	farm.player.motor.place(Vector2i(27, 17))
	farm.player.face(Vector2.RIGHT)
	farm.hud.show_message("-")
	assert_bool(farm.use_hand()).is_false()
	assert_str(farm.hud.message_text()).is_equal(ToolUse.CLEAR_FIRST)
	assert_object(farm.debris_at(weeds_cell)).is_not_null()
	var off_field: Breakable = farm.debris_at(ALONE[&"weeds"]) as Breakable
	farm.player.motor.place(off_field.cell() + Vector2i.DOWN)
	farm.player.face(Vector2.UP)
	farm.player.sync_from_motor()
	farm.hud.show_message("-")
	assert_bool(farm.use_hand()).override_failure_message("off the field the click swings the sword").is_true()
	for i: int in 40:
		farm.player.motor.step(Vector2.ZERO, FRAME)
		farm.player.sync_from_motor()
		farm.resolve_combat()
	assert_bool(off_field.broken).is_true()
	assert_str(farm.hud.message_text()).is_equal("-")
	assert_float(GameState.energy).override_failure_message("one swing of the sword").is_equal(99.5)
	GameState.set_energy(100.0)
	# A better hoe's stroke passes over what stands in its way: it tills two clear cells in a
	# line, and from the corner's last cell but one that cell's neighbour and not the weeds
	# beyond it.
	GameState.equip(&"copper_hoe")
	farm.player.motor.place(Vector2i(25, 17))
	farm.player.face(Vector2.RIGHT)
	assert_bool(farm.use_item()).is_true()
	_finish(farm)
	assert_that(farm.plot.soil_at(Vector2i(26, 17))).is_equal(Farm.TILLED)
	assert_that(farm.plot.soil_at(Vector2i(27, 17))).is_equal(Farm.TILLED)
	farm.player.motor.place(Vector2i(26, 18))
	farm.player.face(Vector2.RIGHT)
	assert_bool(farm.use_item()).is_true()
	_finish(farm)
	assert_that(farm.plot.soil_at(Vector2i(27, 18))).is_equal(Farm.TILLED)
	assert_that(farm.plot.soil_at(Vector2i(28, 18))).override_failure_message("the weeds beyond are in the way").is_equal(Farm.BARE)
	assert_int(GameState.farm().count_of(Farm.TILLED)).is_equal(3)
	assert_float(GameState.energy).is_equal(96.0)
	# Cleared, the soil is his to till: the weeds by the sword, the rock by the pickaxe.
	_swing_at_from(farm, farm.debris_at(weeds_cell), Vector2i(27, 17), Vector2.RIGHT)
	assert_object(farm.debris_at(weeds_cell)).is_null()
	GameState.equip(&"hoe")
	farm.player.motor.place(Vector2i(27, 17))
	farm.player.face(Vector2.RIGHT)
	assert_bool(farm.use_item()).override_failure_message("the hoe where the weeds stood").is_true()
	_finish(farm)
	assert_that(farm.plot.soil_at(weeds_cell)).is_equal(Farm.TILLED)
	GameState.equip(&"pickaxe")
	farm.player.motor.place(Vector2i(23, 19))
	farm.player.face(Vector2.DOWN)
	for blow: int in 2:
		assert_bool(farm.use_item()).is_true()
		_finish(farm)
	assert_object(farm.debris_at(rock_cell)).is_null()
	_put(farm, rock_cell)
	farm.collect_pickups()
	GameState.equip(&"hoe")
	farm.player.motor.place(Vector2i(23, 19))
	farm.player.face(Vector2.DOWN)
	assert_bool(farm.use_item()).override_failure_message("the hoe where the rock stood").is_true()
	assert_that(farm.plot.soil_at(rock_cell)).is_equal(Farm.TILLED)


func test_a_bomb_cuts_what_the_sword_and_the_axe_cut_and_never_a_rock() -> void:
	GameState.add_item(&"bomb", 2)
	var farm: AreaController = _load(FARM)
	# Beside the log at (27, 6): the blast catches it.
	var log: Breakable = farm.debris_at(Vector2i(27, 6)) as Breakable
	assert_that(log.breakable_id).is_equal(&"log")
	_bomb(farm, Vector2i(27, 7))
	assert_int(log.hits_left).override_failure_message("a blast is a blow, as on a stump in the countryside").is_equal(2)
	assert_bool(log.broken).is_false()
	# Beside the weeds that stand alone: one blast clears them, for good.
	var weeds: Vector2i = ALONE[&"weeds"]
	_bomb(farm, weeds + Vector2i.DOWN)
	assert_object(farm.debris_at(weeds)).is_null()
	assert_bool(GameState.homestead().is_cleared(weeds)).is_true()
	# Beside a rock: it stands.
	GameState.add_item(&"bomb", 1)
	_bomb(farm, ALONE[&"rock"] + Vector2i.DOWN)
	var rock: Rock = farm.debris_at(ALONE[&"rock"]) as Rock
	assert_bool(rock.broken).is_false()
	assert_int(rock.blows_left).is_equal(2)


# --- Helpers -------------------------------------------------------------------------------

func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area


## What kind of debris `thing` is: a breakable's id, or a rock's kind.
func _kind_of(thing: Node2D) -> StringName:
	return (thing as Breakable).breakable_id if thing is Breakable else (thing as Rock).kind


## [item, count] that one of `kind` leaves.
func _leaves(kind: StringName) -> Array:
	var rules: HomesteadRules = GameState.homestead_rules()
	if rules.has_rock(kind):
		return [rules.gives(kind), rules.count(kind)]
	var drop: Dictionary = DropTable.roll(DataRegistry.get_breakable(kind)["drops"], 0.5)
	return [StringName(str(drop["item"])), int(drop.get("count", 1))]


## How much of what `kind` leaves he carried before clearing it, in the order the sword's
## test clears them (weeds, bush, log, stump).
func _carried_before(kind: StringName) -> int:
	return {&"weeds": 0, &"bush": 1, &"log": 0, &"farm_stump": 3}[kind]


func _is_gone(farm: AreaController, cell: Vector2i, when: String) -> void:
	assert_object(farm.debris_at(cell)).override_failure_message("%s is clear %s" % [cell, when]).is_null()
	assert_bool(farm.terrain.is_occupied(cell)).override_failure_message("%s is free %s" % [cell, when]).is_false()
	assert_bool(GameState.is_debris_cleared(&"homestead", cell)).is_true()
	for child: Node in farm.interactables.get_children():
		if (child is Breakable or child is Rock) and child.call(&"cell") == cell:
			assert_bool(child.get(&"broken")).override_failure_message("what stood at %s is gone %s" % [cell, when]).is_true()
			if child is Breakable:
				assert_bool((child as Breakable).hurt_box.enabled).is_false()


## The cells he can walk to from `start`, clearing as he goes whatever is of the `kinds` named.
func _reach(farm: AreaController, start: Vector2i, kinds: Array) -> Dictionary:
	var ground: TerrainQuery = TerrainQuery.new(farm.grid)
	var seen: Dictionary = {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		for side: Vector2i in SIDES:
			var next: Vector2i = cell + side
			if seen.has(next) or not ground.check_move(cell, next).is_allowed():
				continue
			var thing: Node2D = farm.debris_at(next)
			if thing != null and not kinds.has(_kind_of(thing)):
				continue
			seen[next] = true
			queue.append(next)
	return seen


## One blow at `what` of the sword ("sword") or the axe ("axe", from the item button).
func _cut(farm: AreaController, what: Node2D, with: String) -> void:
	if with == "sword":
		_swing_at(farm, what)
		return
	GameState.equip(&"axe")
	_face(farm, what)
	assert_bool(farm.use_item()).override_failure_message("a stroke of the axe").is_true()
	_finish(farm)
	GameState.equip(&"")


## Stands the hero below `what`, facing it, swings the sword once and lets the blow land.
func _swing_at(farm: AreaController, what: Node2D) -> void:
	_swing_at_from(farm, what, what.call(&"cell") + Vector2i.DOWN, Vector2.UP)


func _swing_at_from(farm: AreaController, what: Node2D, from: Vector2i, facing: Vector2) -> void:
	assert_object(what).is_not_null()
	farm.player.motor.place(from)
	farm.player.face(facing)
	farm.player.sync_from_motor()
	assert_bool(farm.player.swing()).is_true()
	for i: int in 40:
		farm.player.motor.step(Vector2.ZERO, FRAME)
		farm.player.sync_from_motor()
		farm.resolve_combat()


## Stands the hero below `rock` (or anything that stands in a cell), facing it.
func _face(farm: AreaController, rock: Node2D) -> void:
	farm.player.motor.place(rock.call(&"cell") + Vector2i.DOWN)
	farm.player.face(Vector2.UP)


func _put(farm: AreaController, cell: Vector2i) -> void:
	farm.player.motor.place(cell)
	farm.player.sync_from_motor()


## Lets a blow finish.
func _finish(farm: AreaController) -> void:
	for i: int in 40:
		farm.player.motor.step(Vector2.ZERO, FRAME)


func _drop_at(farm: AreaController, cell: Vector2i) -> ItemDrop:
	for child: Node in farm.interactables.get_children():
		if child is ItemDrop and not (child as ItemDrop).taken and GridBody.cell_of(child.position + Vector2(8, 8)) == cell:
			return child
	return null


## Sets a bomb down at `cell` and lets it burn out.
func _bomb(farm: AreaController, cell: Vector2i) -> void:
	GameState.equip(&"bomb")
	farm.player.motor.place(cell)
	farm.player.sync_from_motor()
	assert_bool(farm.use_item()).is_true()
	var bomb: Bomb = farm.last_projectile
	# He steps well away, as a player does, so the blast is not his.
	farm.player.motor.place(WAY_IN)
	farm.player.sync_from_motor()
	for i: int in roundi(2.6 / FRAME):
		bomb.tick(FRAME)
		farm.resolve_combat()
		if not is_instance_valid(bomb) or bomb.is_queued_for_deletion():
			break


func _on_sound(id: StringName) -> void:
	_heard.append(id)


func _on_homestead_changed() -> void:
	_changes += 1
