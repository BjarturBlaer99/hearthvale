extends GdUnitTestSuite
## The Mining skill (mining, phase 1): it grows by breaking rocks, a point for plain stone and
## two for ore; each level takes a tenth off the energy of a blow and adds a twentieth to the
## chance that a rock of ore leaves one more. It changes nothing else.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const FRAME: float = 1.0 / 60.0
const SIDES: Array[Vector2i] = [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]

var _area: Node
var _risen: Array = []


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	Quests.refresh()
	GameState.mine().number = 20261117
	GameState.add_item(&"wooden_sword")
	GameState.add_item(&"pickaxe")
	GameState.equip(&"pickaxe")
	_risen.clear()
	EventBus.skill_rose.connect(_on_skill_rose)


func after_test() -> void:
	EventBus.skill_rose.disconnect(_on_skill_rose)
	if is_instance_valid(_area):
		_area.free()
	_area = null
	GameState.clear()


func test_mining_is_a_fourth_skill_with_the_others_levels() -> void:
	var skills: Skills = GameState.skills()
	assert_array(skills.ids()).is_equal([Skills.COMBAT, Skills.FARMING, Skills.COOKING, Skills.MINING])
	assert_str(skills.name_of(Skills.MINING)).is_equal("Mining")
	assert_int(skills.gain(Skills.MINING, Skills.ROCK)).override_failure_message("a plain rock").is_equal(1)
	assert_int(skills.gain(Skills.MINING, Skills.ORE)).override_failure_message("a rock of ore").is_equal(2)
	assert_bool(skills.eases(Skills.MINING, EnergyRules.MINE)).is_true()
	for other: String in [EnergyRules.SWING, EnergyRules.HOE, EnergyRules.WATER, EnergyRules.SPRINT]:
		assert_bool(skills.eases(Skills.MINING, other)).override_failure_message("it eases the pickaxe, not %s" % other).is_false()
	assert_bool(skills.enriches_dishes(Skills.MINING)).is_false()
	assert_int(GameState.skill_level(Skills.MINING)).is_equal(1)
	assert_array(Array(skills.lines(GameState.skill_points))).is_equal(["Combat 1   Farming 1", "Cooking 1   Mining 1"])
	assert_array(Array(DataRegistry.errors)).is_empty()


func test_each_level_takes_a_tenth_off_a_blow_and_adds_a_twentieth_to_the_chance_of_more() -> void:
	# [points, level, what a blow costs, the chance of one more ore]
	var cases: Array = [[0, 1, 2.0, 0.0], [9, 1, 2.0, 0.0], [10, 2, 1.8, 0.05], [25, 3, 1.6, 0.10], [50, 4, 1.4, 0.15], [90, 5, 1.2, 0.20], [500, 5, 1.2, 0.20]]
	for case: Array in cases:
		GameState.skill_points[Skills.MINING] = case[0]
		assert_int(GameState.skill_level(Skills.MINING)).override_failure_message("%d points" % case[0]).is_equal(case[1])
		assert_float(GameState.energy_cost(EnergyRules.MINE)).override_failure_message("a blow at level %d" % case[1]).is_equal_approx(case[2], 0.0001)
		assert_float(GameState.extra_ore_chance()).override_failure_message("the chance at level %d" % case[1]).is_equal_approx(case[3], 0.0001)
	# Mining makes nothing else cheaper, and no other skill gives more ore.
	assert_float(GameState.energy_cost(EnergyRules.HOE)).is_equal(2.0)
	assert_float(GameState.energy_cost(EnergyRules.SWING)).is_equal(0.5)
	GameState.skill_points.clear()
	GameState.skill_points[Skills.FARMING] = 500
	GameState.skill_points[Skills.COMBAT] = 500
	assert_float(GameState.extra_ore_chance()).is_equal(0.0)
	assert_float(GameState.energy_cost(EnergyRules.MINE)).is_equal(2.0)
	assert_float(Skills.new({"levels": [0, 10], "step": 0.1, "skills": {"mining": {"name": "Mining", "gains": {"rock": 1}}}}).extra_chance(Skills.MINING, {Skills.MINING: 99})) \
		.override_failure_message("a skill with no chance of its own gives none").is_equal(0.0)


func test_a_chance_that_cant_be_used_says_why() -> void:
	var good: Dictionary = DataRegistry.get_rules(DataRegistry.RULES_SKILLS).duplicate(true)
	assert_array(Array(Skills.problems(good, EnergyRules.COSTS))).is_empty()
	var words: String = "skill 'mining' 'extra_chance' must be a number from 0 up, and no more than 1 at the top level."
	for bad: Variant in [-0.1, "some", 0.3]:
		var rules: Dictionary = good.duplicate(true)
		rules["skills"]["mining"]["extra_chance"] = bad
		assert_array(Array(Skills.problems(rules, EnergyRules.COSTS))).override_failure_message("%s" % [bad]).contains([words])


func test_breaking_rocks_is_practice_a_point_for_stone_and_two_for_ore() -> void:
	var floor: AreaController = _floor(1)
	floor.roll_extra_ore = func() -> float: return 0.99
	_break(floor, _rock_of(floor, MineRules.STONE))
	assert_int(int(GameState.skill_points.get(Skills.MINING, 0))).is_equal(1)
	_break(floor, _rock_of(floor, &"copper_ore"))
	assert_int(int(GameState.skill_points.get(Skills.MINING, 0))).is_equal(3)
	# The rock over the ladder is a plain rock like any other.
	_break(floor, _rock_at(floor, floor.ladder_cell()))
	assert_int(int(GameState.skill_points.get(Skills.MINING, 0))).is_equal(4)
	assert_float(GameState.energy).override_failure_message("six blows at the first level's price").is_equal(88.0)
	assert_bool(_risen.is_empty()).is_true()
	# A blow that doesn't break a rock is no practice.
	var half: Rock = _rock_of(floor, MineRules.STONE)
	_face(floor, half)
	assert_bool(floor.use_item()).is_true()
	assert_int(int(GameState.skill_points.get(Skills.MINING, 0))).is_equal(4)


func test_the_blow_that_raises_his_mining_pays_the_old_price_and_the_next_the_new() -> void:
	GameState.skill_points[Skills.MINING] = 9
	var floor: AreaController = _floor(1)
	floor.roll_extra_ore = func() -> float: return 0.99
	_break(floor, _rock_of(floor, MineRules.STONE))
	assert_float(GameState.energy).override_failure_message("two blows at 2").is_equal(96.0)
	assert_array(_risen).is_equal([[Skills.MINING, 2]])
	assert_array(Array(floor.hud.notice_lines())).contains([GameState.skills().risen_words(Skills.MINING, 2)])
	_break(floor, _rock_of(floor, MineRules.STONE))
	assert_float(GameState.energy).override_failure_message("then two at 1.8").is_equal_approx(92.4, 0.0001)
	# His hearts, his sword and his speed are as they were.
	assert_int(GameState.health).is_equal(GameState.max_health())
	assert_float(GameState.energy_cost(EnergyRules.SWING)).is_equal(0.5)


func test_a_rock_of_ore_leaves_one_more_when_the_roll_is_under_his_chance() -> void:
	GameState.skill_points[Skills.MINING] = 90
	assert_float(GameState.extra_ore_chance()).is_equal_approx(0.20, 0.0001)
	var floor: AreaController = _floor(4)
	# Under the chance: two. Stone never: there is no such thing as extra stone.
	floor.roll_extra_ore = func() -> float: return 0.19
	var iron: Rock = _rock_of(floor, &"iron_ore")
	_break(floor, iron)
	assert_int(_drop_at(floor, iron.cell()).count).override_failure_message("a roll of 0.19 against 0.20").is_equal(2)
	var stone: Rock = _rock_of(floor, MineRules.STONE)
	_break(floor, stone)
	assert_int(_drop_at(floor, stone.cell()).count).is_equal(1)
	# At the chance or over it: one.
	floor.roll_extra_ore = func() -> float: return 0.20
	var coal: Rock = _rock_of(floor, &"coal")
	_break(floor, coal)
	assert_int(_drop_at(floor, coal.cell()).count).override_failure_message("a roll of 0.20 against 0.20").is_equal(1)
	# At the first level there is no chance at all, whatever the roll.
	GameState.skill_points[Skills.MINING] = 0
	floor.roll_extra_ore = func() -> float: return 0.0
	var more: Rock = _rock_of(floor, &"iron_ore")
	_break(floor, more)
	assert_int(_drop_at(floor, more.cell()).count).is_equal(1)
	# Picked up, both are his.
	_put(floor, iron.cell())
	floor.collect_pickups()
	assert_int(GameState.item_count(&"iron_ore")).is_equal(2)


func test_the_areas_own_roll_is_a_number_from_nought_to_one() -> void:
	var floor: AreaController = _floor(1)
	for i: int in 50:
		var roll: float = floor.roll_extra_ore.call()
		assert_bool(roll >= 0.0 and roll < 1.0).is_true()


# --- Helpers -------------------------------------------------------------------------------

func _floor(number: int) -> AreaController:
	var area_id: StringName = GameState.mine_rules().area_of(number)
	GameState.go_to(area_id, MineRules.ARRIVAL)
	_area = Steps.load_area(WorldPaths.scene_for(area_id), _area)
	return _area


func _open_beside(area: AreaController, cell: Vector2i) -> Array:
	for side: Vector2i in SIDES:
		var at: Vector2i = cell + side
		if area.grid.in_bounds(at) and not area.grid.is_solid(at) and not area.terrain.is_occupied(at) \
				and area.grid.height_at(at) == area.grid.height_at(cell):
			return [at, Vector2(-side)]
	return []


func _face(area: AreaController, rock: Rock) -> void:
	var where: Array = _open_beside(area, rock.cell())
	if where.is_empty():
		fail("no open ground beside the rock at %s" % rock.cell())
		return
	area.player.motor.place(where[0])
	area.player.face(where[1])


## Breaks `rock` with as many blows as it takes.
func _break(area: AreaController, rock: Rock) -> void:
	_face(area, rock)
	for blow: int in 4:
		if rock.broken:
			return
		assert_bool(area.use_item()).is_true()
		for i: int in 40:
			area.player.motor.step(Vector2.ZERO, FRAME)


func _put(area: AreaController, cell: Vector2i) -> void:
	area.player.motor.place(cell)
	area.player.sync_from_motor()


func _rock_of(area: AreaController, kind: StringName) -> Rock:
	for rock: Rock in area.rocks():
		if rock.kind == kind and not rock.broken and rock.cell() != area.ladder_cell() and not _open_beside(area, rock.cell()).is_empty():
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


func _on_skill_rose(skill: StringName, level: int) -> void:
	_risen.append([skill, level])
