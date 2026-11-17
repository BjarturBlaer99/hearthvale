extends GdUnitTestSuite
## The Old Quarry's rules (MineRules, pure): nine floors in three bands, what each rock takes
## and gives, the lift's two stops, the lift's conversation, and rules that can't be used.

const RULES: Dictionary = {
	"hall": "quarry",
	"floors": [
		{"area": "pit_1", "ores": {"copper_ore": 2}},
		{"area": "pit_2", "ores": {"iron_ore": 1, "coal": 3}},
		{"area": "pit_3", "ores": {}},
	],
	"lift": [2],
	"rocks": {
		"stone": {"blows": 2, "gives": "stone"},
		"copper_ore": {"blows": 2, "gives": "copper_ore"},
		"coal": {"blows": 2, "gives": "coal"},
		"iron_ore": {"blows": 3, "gives": "iron_ore"},
	},
}

var _game: MineRules


func before_test() -> void:
	_game = MineRules.new(DataRegistry.get_rules(DataRegistry.RULES_MINE))


func test_the_game_has_nine_floors_in_three_bands() -> void:
	assert_array(Array(DataRegistry.errors)).override_failure_message("the data loads clean").is_empty()
	assert_that(_game.hall).is_equal(&"quarry")
	assert_int(_game.floor_count()).is_equal(9)
	for floor: int in range(1, 10):
		assert_that(_game.area_of(floor)).is_equal(StringName("quarry_%d" % floor))
		assert_int(_game.floor_of(StringName("quarry_%d" % floor))).is_equal(floor)
	# Floors 1 to 3: copper. 4 to 6: iron and coal. 7 to 9: gold, and crystal from 8 down.
	for floor: int in [1, 2, 3]:
		assert_dict(_game.ores_of(floor)).is_equal({&"copper_ore": 5})
	for floor: int in [4, 5, 6]:
		assert_dict(_game.ores_of(floor)).is_equal({&"iron_ore": 3, &"coal": 2})
	assert_dict(_game.ores_of(7)).is_equal({&"gold_ore": 2, &"coal": 2})
	assert_dict(_game.ores_of(8)).is_equal({&"gold_ore": 2, &"crystal": 1, &"coal": 2})
	assert_dict(_game.ores_of(9)).is_equal({&"gold_ore": 2, &"crystal": 2})
	assert_array(_game.lift_floors()).is_equal([4, 7])
	assert_float(EnergyRules.new(DataRegistry.get_rules(DataRegistry.RULES_ENERGY)).cost(EnergyRules.MINE)).override_failure_message("a blow costs what the hoe does").is_equal(2.0)


func test_the_game_s_rocks_take_two_or_three_blows_and_give_one_of_what_they_hold() -> void:
	var blows: Dictionary = {&"stone": 2, &"copper_ore": 2, &"coal": 2, &"iron_ore": 3, &"gold_ore": 3, &"crystal": 3}
	assert_int(_game.kinds().size()).is_equal(blows.size())
	for kind: StringName in blows:
		assert_int(_game.blows(kind)).override_failure_message(String(kind)).is_equal(blows[kind])
		assert_that(_game.gives(kind)).override_failure_message("%s gives itself" % kind).is_equal(kind)
		assert_bool(DataRegistry.get_item(_game.gives(kind)).is_empty()).override_failure_message("%s is an item" % kind).is_false()
		assert_str(str(DataRegistry.get_item(kind)["type"])).override_failure_message("%s can't be eaten or given" % kind).is_equal("material")
		assert_bool(_game.is_ore(kind)).is_equal(kind != &"stone")


func test_a_floor_is_known_by_its_area_and_the_last_has_no_ladder_down() -> void:
	var rules: MineRules = MineRules.new(RULES)
	assert_int(rules.floor_count()).is_equal(3)
	assert_int(rules.floor_of(&"pit_2")).is_equal(2)
	assert_int(rules.floor_of(&"quarry")).override_failure_message("the hall is no floor").is_equal(MineRules.NO_FLOOR)
	assert_int(rules.floor_of(&"village")).is_equal(MineRules.NO_FLOOR)
	assert_that(rules.area_of(0)).is_equal(&"")
	assert_that(rules.area_of(4)).is_equal(&"")
	assert_that(rules.below(1)).is_equal(&"pit_2")
	assert_that(rules.below(2)).is_equal(&"pit_3")
	assert_that(rules.below(3)).override_failure_message("nothing under the last floor").is_equal(&"")
	assert_that(rules.below(MineRules.NO_FLOOR)).override_failure_message("the hall's ladder is its own").is_equal(&"")
	assert_bool(rules.is_last(3)).is_true()
	assert_bool(rules.is_last(2)).is_false()
	assert_dict(rules.ores_of(2)).is_equal({&"iron_ore": 1, &"coal": 3})
	assert_array(rules.ores_of(2).keys()).override_failure_message("in the order the data lists them").is_equal([&"iron_ore", &"coal"])
	assert_dict(rules.ores_of(3)).is_empty()
	assert_dict(rules.ores_of(9)).is_empty()


func test_a_better_pickaxe_needs_fewer_blows_but_never_none() -> void:
	var rules: MineRules = MineRules.new(RULES)
	assert_int(rules.blows(&"iron_ore")).is_equal(3)
	assert_int(rules.blows(&"iron_ore", 1)).is_equal(2)
	assert_int(rules.blows(&"iron_ore", 2)).is_equal(1)
	assert_int(rules.blows(&"iron_ore", 5)).override_failure_message("never less than one").is_equal(1)
	assert_int(rules.blows(&"stone", 1)).is_equal(1)
	assert_int(rules.blows(&"stone", 2)).is_equal(1)
	assert_int(rules.blows(&"stone", -3)).override_failure_message("a worse pickaxe is no pickaxe the rules know").is_equal(2)
	assert_int(rules.blows(&"marble")).override_failure_message("a kind the rules don't name is plain stone").is_equal(2)
	assert_that(rules.gives(&"marble")).is_equal(&"")
	assert_bool(rules.is_ore(&"marble")).is_false()


func test_the_lift_stops_where_the_flags_say_it_has_been() -> void:
	var rules: MineRules = MineRules.new(RULES)
	assert_bool(rules.is_lift_stop(2)).is_true()
	assert_bool(rules.is_lift_stop(1)).is_false()
	assert_that(MineRules.lift_flag(4)).is_equal(&"quarry/lift/4")
	assert_array(rules.reached({})).is_empty()
	assert_array(rules.reached({&"quarry/lift/2": false})).is_empty()
	assert_array(rules.reached({&"quarry/lift/2": true, &"quarry/lift/3": true})).override_failure_message("only its own stops").is_equal([2])
	assert_array(_game.reached({&"quarry/lift/7": true, &"quarry/lift/4": true})).override_failure_message("shallowest first").is_equal([4, 7])


func test_the_lift_s_conversation_offers_each_stop_and_staying() -> void:
	var talk: Dictionary = _game.lift_dialogue([4, 7], &"ladder")
	var node: Dictionary = talk["nodes"][talk["start"]]
	assert_str(str(node["text"])).is_equal(MineRules.LIFT_WORDS)
	var answers: Array = node["options"]
	assert_int(answers.size()).is_equal(3)
	assert_str(str(answers[0]["text"])).is_equal("Floor 4")
	assert_array(answers[0]["effects"]).is_equal([{"type": "travel", "area": "quarry_4", "entry": "ladder"}])
	assert_str(str(answers[1]["text"])).is_equal("Floor 7")
	assert_array(answers[1]["effects"]).is_equal([{"type": "travel", "area": "quarry_7", "entry": "ladder"}])
	assert_str(str(answers[2]["text"])).is_equal(MineRules.LIFT_STAY_WORDS)
	assert_bool((answers[2] as Dictionary).has("effects")).override_failure_message("staying does nothing").is_false()
	for answer: Dictionary in answers:
		assert_that(answer["next"]).override_failure_message("every answer ends the conversation").is_null()
	# With nowhere reached it says so, and offers only to stay.
	var nowhere: Dictionary = _game.lift_dialogue([], &"ladder")
	var only: Dictionary = nowhere["nodes"][nowhere["start"]]
	assert_str(str(only["text"])).is_equal(MineRules.LIFT_NOWHERE_WORDS)
	assert_int((only["options"] as Array).size()).is_equal(1)


func test_the_travel_effect_asks_to_be_taken_there() -> void:
	var asked: Array = []
	var listen: Callable = func(area: StringName, entry: StringName) -> void: asked.append([area, entry])
	EventBus.travel_requested.connect(listen)
	assert_bool(EffectApplier.new(GameState).apply({"type": "travel", "area": "quarry_4", "entry": "ladder"})).is_true()
	EventBus.travel_requested.disconnect(listen)
	assert_array(asked).is_equal([[&"quarry_4", &"ladder"]])


func test_rules_that_cant_be_used_say_why() -> void:
	var item_of: Callable = func(id: String) -> Dictionary: return {"id": id} if ["stone", "copper_ore", "coal", "iron_ore"].has(id) else {}
	assert_array(Array(MineRules.problems(RULES, item_of))).is_empty()
	var cases: Array = [
		[{"hall": ""}, "'hall' must name the area the mine is entered through."],
		[{"rocks": {"copper_ore": {"blows": 2, "gives": "copper_ore"}}}, "'rocks' must be an object of kinds of rock, 'stone' among them."],
		[{"rocks": {"stone": {"blows": 0, "gives": "stone"}}}, "rock 'stone' needs 'blows', a whole number of 1 or more."],
		[{"rocks": {"stone": {"blows": 1.5, "gives": "stone"}}}, "rock 'stone' needs 'blows', a whole number of 1 or more."],
		[{"rocks": {"stone": {"blows": 2, "gives": "gravel"}}}, "rock 'stone' gives an unknown item id 'gravel'."],
		[{"floors": []}, "'floors' must list one floor or more."],
		[{"floors": [{"ores": {}}]}, "floor 1 must name its 'area'."],
		[{"floors": [{"area": "pit_1"}, {"area": "pit_1"}]}, "floor 2: area 'pit_1' is a floor already."],
		[{"floors": [{"area": "pit_1", "ores": {"marble": 1}}]}, "floor 1: 'marble' is not a kind of ore in 'rocks'."],
		[{"floors": [{"area": "pit_1", "ores": {"stone": 3}}]}, "floor 1: 'stone' is not a kind of ore in 'rocks'."],
		[{"floors": [{"area": "pit_1", "ores": {"coal": -1}}]}, "floor 1: 'coal' needs a whole number of rocks, 0 or more."],
		[{"lift": [4]}, "'lift' names floor '4', which there isn't."],
		[{"lift": "all"}, "'lift' must be a list of floor numbers."],
	]
	for case: Array in cases:
		var rules: Dictionary = RULES.duplicate(true)
		rules.merge(case[0], true)
		assert_array(Array(MineRules.problems(rules, item_of))).override_failure_message("%s" % [case[0]]).contains([case[1]])
	# Rules with nothing in them are no mine at all, and say so without falling over.
	var empty: MineRules = MineRules.new()
	assert_int(empty.floor_count()).is_equal(0)
	assert_int(empty.blows(&"stone")).is_equal(1)
	assert_bool(MineRules.problems({}, item_of).is_empty()).is_false()
