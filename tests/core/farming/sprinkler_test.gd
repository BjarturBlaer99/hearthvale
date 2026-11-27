extends GdUnitTestSuite
## Sprinklers and tool tiers in the pure rules (crafting, phase 2c): where a sprinkler can
## stand on the plot (Farm), the four cells it waters each morning, and through a save; what
## having one in hand does (ToolUse); how far a better hoe or can reaches, and how many blows
## a better pickaxe saves.

const RULES: Dictionary = {"plot": {"columns": 6, "rows": 3}, "wither_after": 2}
const DAYS: Dictionary = {"turnip": 3}


func _farm() -> Farm:
	return Farm.new(RULES)


func test_a_sprinkler_stands_on_tilled_soil_with_nothing_in_it() -> void:
	var farm: Farm = _farm()
	assert_bool(farm.place_sprinkler(Vector2i(1, 1))).override_failure_message("bare soil: till it first").is_false()
	farm.till(Vector2i(1, 1))
	assert_bool(farm.has_sprinkler(Vector2i(1, 1))).is_false()
	assert_bool(farm.place_sprinkler(Vector2i(1, 1))).is_true()
	assert_bool(farm.has_sprinkler(Vector2i(1, 1))).is_true()
	assert_int(farm.sprinkler_count()).is_equal(1)
	assert_bool(farm.place_sprinkler(Vector2i(1, 1))).override_failure_message("one to a cell").is_false()
	assert_bool(farm.place_sprinkler(Vector2i(9, 9))).override_failure_message("not outside the plot").is_false()
	# Not where something grows, and nothing is planted where one stands.
	farm.till(Vector2i(2, 1))
	farm.plant(Vector2i(2, 1), "turnip")
	assert_bool(farm.place_sprinkler(Vector2i(2, 1))).is_false()
	assert_bool(farm.plant(Vector2i(1, 1), "turnip")).override_failure_message("its own cell can't be planted").is_false()
	assert_bool(farm.has_crop(Vector2i(1, 1))).is_false()
	assert_that(farm.state_of(Vector2i(1, 1))).override_failure_message("the soil under it is tilled soil still").is_equal(Farm.TILLED)
	# Taken up, the cell is tilled soil again, and can be planted.
	assert_bool(farm.take_sprinkler(Vector2i(1, 1))).is_true()
	assert_bool(farm.take_sprinkler(Vector2i(1, 1))).override_failure_message("taken once").is_false()
	assert_bool(farm.has_sprinkler(Vector2i(1, 1))).is_false()
	assert_int(farm.sprinkler_count()).is_equal(0)
	assert_bool(farm.plant(Vector2i(1, 1), "turnip")).is_true()


func test_it_waters_the_four_cells_beside_it_each_morning() -> void:
	var farm: Farm = _farm()
	for cell: Vector2i in [Vector2i(1, 1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(2, 1), Vector2i(1, 2), Vector2i(0, 0), Vector2i(2, 2), Vector2i(3, 1)]:
		farm.till(cell)
	farm.place_sprinkler(Vector2i(1, 1))
	assert_array(farm.watered_by(Vector2i(1, 1))).is_equal([Vector2i(1, 0), Vector2i(0, 1), Vector2i(2, 1), Vector2i(1, 2)])
	# Set down today, it runs from tomorrow.
	for cell: Vector2i in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(2, 1), Vector2i(1, 2)]:
		assert_bool(farm.is_watered(cell)).override_failure_message("%s is dry until morning" % cell).is_false()
	farm.new_day(DAYS)
	for cell: Vector2i in [Vector2i(1, 0), Vector2i(0, 1), Vector2i(2, 1), Vector2i(1, 2)]:
		assert_bool(farm.is_watered(cell)).override_failure_message("%s is watered" % cell).is_true()
	# Not the corners, not two cells away, and not its own.
	for cell: Vector2i in [Vector2i(0, 0), Vector2i(2, 2), Vector2i(3, 1), Vector2i(1, 1)]:
		assert_bool(farm.is_watered(cell)).override_failure_message("%s is not its to water" % cell).is_false()
	# Only soil that is tilled: bare ground beside it stays bare.
	var edge: Farm = _farm()
	edge.till(Vector2i(0, 0))
	edge.till(Vector2i(1, 0))
	edge.place_sprinkler(Vector2i(0, 0))
	assert_array(edge.watered_by(Vector2i(0, 0))).override_failure_message("in a corner, with one neighbour tilled").is_equal([Vector2i(1, 0)])
	edge.new_day(DAYS)
	assert_that(edge.state_of(Vector2i(0, 1))).is_equal(Farm.BARE)
	assert_bool(edge.is_watered(Vector2i(1, 0))).is_true()


func test_a_crop_beside_a_sprinkler_grows_every_day_without_the_can() -> void:
	var farm: Farm = _farm()
	farm.till(Vector2i(2, 1))
	farm.till(Vector2i(3, 1))
	farm.till(Vector2i(5, 2))
	farm.place_sprinkler(Vector2i(2, 1))
	farm.plant(Vector2i(3, 1), "turnip")
	farm.plant(Vector2i(5, 2), "turnip")
	# The first morning nothing has been watered yet: both go a day dry, and the sprinkler runs.
	farm.new_day(DAYS)
	assert_int(farm.stage_of(Vector2i(3, 1))).is_equal(0)
	for morning: int in 3:
		farm.new_day(DAYS)
	assert_bool(farm.is_ripe(Vector2i(3, 1), 3)).override_failure_message("three watered mornings: ripe").is_true()
	assert_bool(farm.is_withered(Vector2i(3, 1))).is_false()
	assert_bool(farm.is_withered(Vector2i(5, 2))).override_failure_message("the one out of its reach has withered").is_true()
	# A ripe crop waits; the sprinkler keeps its soil wet and does it no harm.
	farm.new_day(DAYS)
	assert_bool(farm.is_ripe(Vector2i(3, 1), 3)).is_true()


func test_sprinklers_go_through_a_save() -> void:
	var farm: Farm = _farm()
	farm.till(Vector2i(1, 1))
	farm.till(Vector2i(2, 1))
	farm.place_sprinkler(Vector2i(1, 1))
	farm.plant(Vector2i(2, 1), "turnip")
	var saved: Dictionary = farm.to_dict()
	assert_dict(saved["cells"]["1,1"]).is_equal({"watered": false, "sprinkler": true})
	assert_bool((saved["cells"]["2,1"] as Dictionary).has("sprinkler")).override_failure_message("only where one stands").is_false()
	var again: Farm = _farm()
	again.load_saved(JSON.parse_string(JSON.stringify(saved)))
	assert_bool(again.has_sprinkler(Vector2i(1, 1))).is_true()
	assert_bool(again.has_sprinkler(Vector2i(2, 1))).is_false()
	assert_dict(again.to_dict()).is_equal(saved)
	# A save can't put a sprinkler where something grows, or outside the plot; a save from
	# before sprinklers has none.
	again.load_saved({"cells": {"0,0": {"watered": false, "crop": "turnip", "stage": 1, "dry": 0, "withered": false, "sprinkler": true}, "9,9": {"watered": false, "sprinkler": true}, "3,2": {"watered": true}, "4,2": {"watered": false, "sprinkler": "yes"}}})
	assert_int(again.sprinkler_count()).is_equal(0)
	assert_bool(again.has_crop(Vector2i(0, 0))).is_true()


func test_a_sprinkler_in_hand_is_set_on_tilled_empty_soil() -> void:
	var item: Dictionary = DataRegistry.get_item(&"sprinkler")
	assert_str(ToolUse.kind_of(item)).is_equal(ToolUse.SPRINKLER)
	assert_bool(Inventory.is_equippable(item)).override_failure_message("it goes on the bar").is_true()
	assert_str(Inventory.ammo_for(item)).override_failure_message("setting one down uses one up").is_equal("sprinkler")
	assert_int(Inventory.capacity(item)).is_equal(10)
	assert_dict(ToolUse.decide(ToolUse.SPRINKLER, Farm.TILLED, false, 2, 10)).is_equal({"does": ToolUse.PLACE, "says": ""})
	assert_dict(ToolUse.decide(ToolUse.SPRINKLER, Farm.WATERED, false, 1, 10)).override_failure_message("wet soil is tilled soil").is_equal({"does": ToolUse.PLACE, "says": ""})
	var cases: Array = [
		[&"", false, false, 1, ToolUse.SPRINKLER_NOT_HERE],
		[Farm.BARE, false, false, 1, ToolUse.SPRINKLER_BARE],
		[Farm.TILLED, true, false, 1, ToolUse.SPRINKLER_GROWING],
		[Farm.TILLED, false, true, 1, ToolUse.SPRINKLER_TAKEN],
		[Farm.TILLED, false, false, 0, ToolUse.SPRINKLER_NONE],
	]
	for case: Array in cases:
		assert_dict(ToolUse.decide(ToolUse.SPRINKLER, case[0], false, case[3], 10, case[1], case[2])).override_failure_message("%s" % [case]).is_equal({"does": ToolUse.NOTHING, "says": case[4]})
	# A seed is not planted where a sprinkler stands.
	assert_dict(ToolUse.decide(ToolUse.SEED, Farm.TILLED, false, 3, 30, false, true)).is_equal({"does": ToolUse.NOTHING, "says": ToolUse.SEED_SPRINKLER})
	assert_dict(ToolUse.decide(ToolUse.SEED, Farm.TILLED, false, 3, 30, false, false)).is_equal({"does": ToolUse.PLANT, "says": ""})


func test_a_better_tool_reaches_further_or_strikes_harder() -> void:
	# [item, its kind, cells in a line, blows fewer]
	var cases: Array = [
		[&"hoe", ToolUse.HOE, 1, 0], [&"copper_hoe", ToolUse.HOE, 2, 0], [&"iron_hoe", ToolUse.HOE, 3, 0],
		[&"watering_can", ToolUse.CAN, 1, 0], [&"copper_watering_can", ToolUse.CAN, 2, 0], [&"iron_watering_can", ToolUse.CAN, 3, 0],
		[&"pickaxe", ToolUse.PICK, 1, 0], [&"copper_pickaxe", ToolUse.PICK, 1, 1], [&"iron_pickaxe", ToolUse.PICK, 1, 2],
	]
	for case: Array in cases:
		var item: Dictionary = DataRegistry.get_item(case[0])
		assert_str(ToolUse.kind_of(item)).override_failure_message(String(case[0])).is_equal(case[1])
		assert_int(ToolUse.reach(item)).override_failure_message("%s: cells in a line" % case[0]).is_equal(case[2])
		assert_int(ToolUse.fewer_blows(item)).override_failure_message("%s: blows fewer" % case[0]).is_equal(case[3])
		assert_array(Array(ToolUse.problems(item))).override_failure_message(String(case[0])).is_empty()
		assert_float(ToolUse.time_of(item)).override_failure_message("%s is no quicker: the same stroke" % case[0]).is_equal(0.4)
		assert_bool(Inventory.is_equippable(item)).is_true()
		assert_that(ItemIcons.name_for(case[0])).override_failure_message("%s has a picture of its own" % case[0]).is_equal(case[0])
	# Every can holds the same water.
	for can: StringName in [&"watering_can", &"copper_watering_can", &"iron_watering_can"]:
		assert_str(Inventory.ammo_for(DataRegistry.get_item(can))).is_equal("water")
	# What isn't a tool reaches one cell and saves no blows; a bad number is one cell.
	assert_int(ToolUse.reach({"id": "turnip", "type": "food"})).is_equal(1)
	assert_int(ToolUse.reach({"id": "odd", "type": "tool", "stats": {"tool": "hoe", "reach": 0}})).is_equal(1)
	# Any tool's stat is read (the axes, step A2), and the hoes' and cans' say nothing.
	assert_int(ToolUse.fewer_blows({"id": "odd_hoe", "type": "tool", "stats": {"tool": "hoe", "fewer_blows": 2}})).override_failure_message("any tool's stat is read").is_equal(2)
	for id: StringName in [&"copper_hoe", &"iron_hoe", &"copper_watering_can", &"iron_watering_can"]:
		assert_int(ToolUse.fewer_blows(DataRegistry.get_item(id))).override_failure_message("%s saves no blows" % id).is_equal(0)


func test_the_cells_a_stroke_works_run_in_a_line_the_way_he_faces() -> void:
	assert_array(ToolUse.line(Vector2i(4, 4), Vector2i.RIGHT, 1)).is_equal([Vector2i(4, 4)])
	assert_array(ToolUse.line(Vector2i(4, 4), Vector2i.RIGHT, 3)).is_equal([Vector2i(4, 4), Vector2i(5, 4), Vector2i(6, 4)])
	assert_array(ToolUse.line(Vector2i(4, 4), Vector2i.UP, 2)).is_equal([Vector2i(4, 4), Vector2i(4, 3)])
	assert_array(ToolUse.line(Vector2i(4, 4), Vector2i.LEFT, 0)).override_failure_message("the cell he faces at the least").is_equal([Vector2i(4, 4)])
	# The mine's rules count a better pickaxe's blows; never less than one.
	var rules: MineRules = MineRules.new(DataRegistry.get_rules(DataRegistry.RULES_MINE))
	var blows: Dictionary = {&"stone": [2, 1, 1], &"copper_ore": [2, 1, 1], &"coal": [2, 1, 1], &"iron_ore": [3, 2, 1], &"gold_ore": [3, 2, 1], &"crystal": [3, 2, 1]}
	for kind: StringName in blows:
		for tier: int in 3:
			assert_int(rules.blows(kind, tier)).override_failure_message("%s with %d fewer" % [kind, tier]).is_equal(blows[kind][tier])
