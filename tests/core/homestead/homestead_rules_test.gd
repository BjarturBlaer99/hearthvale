extends GdUnitTestSuite
## HomesteadRules (2026-11-18, phase 1, step 1b), pure: which map is the hero's land, the
## kinds of rock that stand on it, how many blows each takes with each pickaxe, what it leaves,
## and which pickaxe it wants. The numbers are the game's own (data/rules/homestead.json).

const DataRegistryScript: GDScript = preload("res://autoload/data_registry.gd")

var _data: Dictionary
var _rules: HomesteadRules
var _picks: Dictionary = {}


func before_test() -> void:
	_data = DataRegistry.get_rules(DataRegistry.RULES_HOMESTEAD)
	_rules = HomesteadRules.new(_data)
	for id: StringName in [&"pickaxe", &"copper_pickaxe", &"iron_pickaxe"]:
		_picks[id] = DataRegistry.get_item(id)


func test_the_land_is_the_homestead_and_no_other_map() -> void:
	assert_that(_rules.area).is_equal(&"homestead")
	assert_bool(_rules.is_land(&"homestead")).is_true()
	for other: StringName in [&"village", &"home", &"quarry_1", &"north_fields", &""]:
		assert_bool(_rules.is_land(other)).override_failure_message("%s is not his land" % other).is_false()
	assert_bool(HomesteadRules.new().is_land(&"")).override_failure_message("rules that name no land have none").is_false()


func test_a_rock_a_boulder_and_a_great_boulder_as_the_plan_has_them() -> void:
	assert_array(_rules.rock_kinds()).is_equal([&"rock", &"boulder", &"great_boulder"])
	# [kind, what it leaves, the least pickaxe, blows with the plain / copper / iron pickaxe]
	var table: Array = [
		[&"rock", 1, &"", 2, 1, 1],
		[&"boulder", 4, &"copper_pickaxe", 4, 3, 2],
		[&"great_boulder", 8, &"iron_pickaxe", 5, 4, 3],
	]
	for row: Array in table:
		var kind: StringName = row[0]
		assert_bool(_rules.has_rock(kind)).is_true()
		assert_that(_rules.gives(kind)).override_failure_message("%s leaves stone" % kind).is_equal(&"stone")
		assert_int(_rules.count(kind)).override_failure_message("%s leaves %d" % [kind, row[1]]).is_equal(row[1])
		assert_that(_rules.wants(kind)).override_failure_message("%s wants" % kind).is_equal(row[2])
		assert_int(_rules.blows(kind)).is_equal(row[3])
		for tier: int in 3:
			assert_int(_rules.blows_with(kind, tier)).override_failure_message("%s, a pickaxe that needs %d fewer" % [kind, tier]).is_equal(row[3 + tier])
	# The plan's own sums: a boulder is three blows of the Copper Pickaxe or two of the Iron,
	# and a great boulder three of the Iron.
	assert_int(_rules.blows_with(&"boulder", ToolUse.fewer_blows(_picks[&"copper_pickaxe"]))).is_equal(3)
	assert_int(_rules.blows_with(&"boulder", ToolUse.fewer_blows(_picks[&"iron_pickaxe"]))).is_equal(2)
	assert_int(_rules.blows_with(&"great_boulder", ToolUse.fewer_blows(_picks[&"iron_pickaxe"]))).is_equal(3)
	assert_int(_rules.blows_with(&"rock", ToolUse.fewer_blows(_picks[&"pickaxe"]))).is_equal(2)
	# A kind the rules don't know is a plain rock, and leaves nothing of its own.
	assert_that(_rules.rock_kind(&"stone")).is_equal(HomesteadRules.ROCK)
	assert_that(_rules.rock_kind(&"boulder")).is_equal(&"boulder")
	assert_bool(_rules.has_rock(&"copper_ore")).is_false()
	assert_that(_rules.gives(&"copper_ore")).is_equal(&"")
	assert_int(_rules.blows(&"copper_ore")).is_equal(1)
	assert_int(_rules.count(&"copper_ore")).is_equal(1)


func test_a_lesser_pickaxe_is_too_weak_and_a_better_one_never_is() -> void:
	# [kind, too hard for the plain / copper / iron pickaxe]
	var table: Array = [
		[&"rock", false, false, false],
		[&"boulder", true, false, false],
		[&"great_boulder", true, true, false],
	]
	var order: Array[StringName] = [&"pickaxe", &"copper_pickaxe", &"iron_pickaxe"]
	for row: Array in table:
		var kind: StringName = row[0]
		var wanted: Dictionary = DataRegistry.get_item(_rules.wants(kind))
		for index: int in order.size():
			assert_bool(_rules.is_too_hard(kind, _picks[order[index]], wanted)).override_failure_message("%s with the %s" % [kind, order[index]]).is_equal(row[1 + index])
	# What is no pickaxe at all is as weak as the plain one.
	assert_bool(_rules.is_too_hard(&"boulder", DataRegistry.get_item(&"hoe"), _picks[&"copper_pickaxe"])).is_true()
	assert_bool(_rules.is_too_hard(&"rock", {}, {})).is_false()


func test_the_rules_are_sound_and_bad_ones_are_named() -> void:
	var item_of: Callable = func(id: String) -> Dictionary: return DataRegistry.get_item(StringName(id))
	assert_array(Array(HomesteadRules.problems(_data, item_of))).is_empty()
	assert_array(Array(HomesteadRules.problems({}, item_of))).contains_exactly([
		"'area' must name the map that is the hero's land.",
		"'rocks' must be an object: a kind of rock, then its blows and what it gives.",
	])
	var bad: Dictionary = {"area": "homestead", "rocks": {
		"boulder": {"blows": 0, "gives": "stone"},
		"pebble": {"blows": 2, "gives": "gravel", "count": 0},
		"slab": {"blows": 2, "gives": "stone", "wants": "hoe"},
		"crag": {"blows": 2, "gives": "stone", "wants": "iron_pickaxe"},
		"lump": 3,
	}}
	assert_array(Array(HomesteadRules.problems(bad, item_of))).contains_exactly([
		"'rocks' needs 'rock', the plain rock of the land.",
		"rock 'boulder' needs 'blows', a whole number of 1 or more.",
		"rock 'pebble': 'count' must be a whole number of 1 or more.",
		"rock 'pebble' gives 'gravel', which is no item.",
		"rock 'slab' wants 'hoe', which is no pickaxe.",
		"rock 'crag' needs more 'blows' than the pickaxe it wants takes off.",
		"rock 'lump' must be an object.",
	])
	# A fresh registry reads the game's own data with nothing to say about it.
	var registry: Node = auto_free(DataRegistryScript.new())
	var errors: PackedStringArray = registry.load_all("res://data")
	assert_array(Array(errors)).is_empty()
	assert_bool((registry.get_rules(DataRegistry.RULES_HOMESTEAD) as Dictionary).is_empty()).is_false()
