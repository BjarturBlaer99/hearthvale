extends GdUnitTestSuite
## The furnace (Furnace, pure): one load at a time, lit today and ready from the next morning;
## how big a load can be; what it says cold, burning and burned down; and through a save.

const COPPER: Dictionary = {
	"id": "copper_bar", "station": "furnace", "order": 1,
	"needs": [{"item": "copper_ore", "count": 3}, {"item": "coal", "count": 1}],
	"makes": {"item": "copper_bar", "count": 1},
}
const IRON: Dictionary = {
	"id": "iron_bar", "station": "furnace", "order": 2,
	"needs": [{"item": "iron_ore", "count": 3}, {"item": "coal", "count": 1}],
	"makes": {"item": "iron_bar", "count": 1},
}
const NAMES: Dictionary = {"copper_ore": "Copper Ore", "iron_ore": "Iron Ore", "coal": "Coal", "copper_bar": "Copper Bar", "iron_bar": "Iron Bar"}

var _held: Dictionary = {}


func before_test() -> void:
	_held = {}


func test_it_is_lit_today_and_ready_from_the_next_morning() -> void:
	var furnace: Furnace = Furnace.new()
	assert_bool(furnace.is_empty()).is_true()
	assert_bool(furnace.is_burning(3) or furnace.is_ready(3)).override_failure_message("cold: neither").is_false()
	assert_bool(furnace.light(&"copper_bar", 4, 3)).is_true()
	assert_bool(furnace.is_empty()).is_false()
	assert_bool(furnace.is_burning(3)).is_true()
	assert_bool(furnace.is_ready(3)).override_failure_message("not the same day").is_false()
	assert_bool(furnace.is_burning(4)).is_false()
	assert_bool(furnace.is_ready(4)).override_failure_message("the next morning").is_true()
	assert_bool(furnace.is_ready(9)).override_failure_message("and it waits").is_true()
	assert_dict(furnace.take()).is_equal({"item": &"copper_bar", "count": 4})
	assert_bool(furnace.is_empty()).is_true()
	assert_dict(furnace.take()).override_failure_message("taken once").is_empty()


func test_it_takes_one_load_at_a_time() -> void:
	var furnace: Furnace = Furnace.new()
	assert_bool(furnace.light(&"copper_bar", 0, 1)).override_failure_message("nothing to make").is_false()
	assert_bool(furnace.light(&"", 2, 1)).is_false()
	assert_bool(furnace.is_empty()).is_true()
	assert_bool(furnace.light(&"copper_bar", 2, 1)).is_true()
	assert_bool(furnace.light(&"iron_bar", 5, 1)).override_failure_message("burning: no second load").is_false()
	assert_bool(furnace.light(&"iron_bar", 5, 2)).override_failure_message("burned down but not emptied: no second load").is_false()
	assert_that(furnace.item).is_equal(&"copper_bar")
	assert_int(furnace.count).is_equal(2)
	furnace.take()
	assert_bool(furnace.light(&"iron_bar", 5, 2)).is_true()


func test_a_load_is_as_many_as_he_has_the_makings_for_up_to_the_most() -> void:
	assert_int(Furnace.load_size(COPPER, _count, 5)).is_equal(0)
	_held = {"copper_ore": 9, "coal": 0}
	assert_int(Furnace.load_size(COPPER, _count, 5)).override_failure_message("no coal, no fire").is_equal(0)
	_held = {"copper_ore": 2, "coal": 4}
	assert_int(Furnace.load_size(COPPER, _count, 5)).override_failure_message("not three ore").is_equal(0)
	_held = {"copper_ore": 9, "coal": 2}
	assert_int(Furnace.load_size(COPPER, _count, 5)).override_failure_message("coal for two").is_equal(2)
	_held = {"copper_ore": 11, "coal": 8}
	assert_int(Furnace.load_size(COPPER, _count, 5)).override_failure_message("ore for three, and two left over").is_equal(3)
	_held = {"copper_ore": 30, "coal": 30}
	assert_int(Furnace.load_size(COPPER, _count, 5)).override_failure_message("five at the most").is_equal(5)
	assert_int(Furnace.load_size(COPPER, _count, 1)).is_equal(1)
	assert_int(Furnace.load_size(COPPER, _count, 0)).is_equal(0)


func test_cold_it_lists_what_he_can_smelt_and_how_much_goes_in() -> void:
	var furnace: Furnace = Furnace.new()
	_held = {"copper_ore": 11, "coal": 8, "iron_ore": 2}
	var talk: Dictionary = furnace.dialogue(2, [COPPER, IRON], _count, 5, NAMES)
	var node: Dictionary = talk["nodes"][talk["start"]]
	assert_str(str(node["text"])).is_equal(Furnace.COLD_WORDS)
	var answers: Array = node["options"]
	assert_int(answers.size()).is_equal(3)
	# Copper: three bars' worth goes in, with one effect for each thing taken and one to light it.
	assert_str(str(answers[0]["text"])).is_equal("Copper Bar x3 (9 Copper Ore, 3 Coal)")
	assert_array(answers[0]["effects"]).is_equal([
		{"type": "take_item", "item": "copper_ore", "count": 9},
		{"type": "take_item", "item": "coal", "count": 3},
		{"type": "light_furnace", "item": "copper_bar", "count": 3},
	])
	var lit: Dictionary = talk["nodes"][answers[0]["next"]]
	assert_str(str(lit["text"])).is_equal("You load the furnace and light it. The copper bar x3 will be ready in the morning.")
	# Iron: he hasn't three ore, so it says what one takes and that he hasn't it.
	assert_str(str(answers[1]["text"])).is_equal("Iron Bar (3 Iron Ore, 1 Coal)")
	assert_bool((answers[1] as Dictionary).has("effects")).is_false()
	assert_str(str(talk["nodes"][answers[1]["next"]]["text"])).is_equal(Furnace.LACKING_WORDS)
	assert_str(str(answers[2]["text"])).is_equal(Furnace.NOT_NOW_WORDS)
	assert_that(answers[2]["next"]).is_null()
	# A single bar reads without a number.
	_held = {"copper_ore": 3, "coal": 1}
	var one: Dictionary = furnace.dialogue(2, [COPPER], _count, 5, NAMES)
	assert_str(str(one["nodes"][one["start"]]["options"][0]["text"])).is_equal("Copper Bar (3 Copper Ore, 1 Coal)")
	assert_array(one["nodes"][one["start"]]["options"][0]["effects"]).contains([{"type": "light_furnace", "item": "copper_bar", "count": 1}])
	# With nothing to smelt known, it says so.
	var none: Dictionary = furnace.dialogue(2, [], _count, 5, NAMES)
	assert_str(str(none["nodes"][none["start"]]["text"])).is_equal(Furnace.NOTHING_WORDS)
	assert_int((none["nodes"][none["start"]]["options"] as Array).size()).is_equal(1)


func test_burning_it_says_so_and_burned_down_it_offers_what_it_made() -> void:
	var furnace: Furnace = Furnace.new()
	furnace.light(&"iron_bar", 2, 4)
	var burning: Dictionary = furnace.dialogue(4, [COPPER, IRON], _count, 5, NAMES)
	var node: Dictionary = burning["nodes"][burning["start"]]
	assert_str(str(node["text"])).is_equal("The furnace is burning. The iron bar x2 will be ready in the morning.")
	assert_int((node["options"] as Array).size()).override_failure_message("nothing to do but leave it").is_equal(1)
	assert_bool((node["options"][0] as Dictionary).has("effects")).is_false()
	var ready: Dictionary = furnace.dialogue(5, [COPPER, IRON], _count, 5, NAMES)
	node = ready["nodes"][ready["start"]]
	assert_str(str(node["text"])).is_equal("The furnace has burned down. In it: iron bar x2.")
	assert_str(str(node["options"][0]["text"])).is_equal(Furnace.TAKE_WORDS)
	assert_array(node["options"][0]["effects"]).is_equal([{"type": "empty_furnace"}])
	assert_str(str(node["options"][1]["text"])).is_equal(Furnace.LEAVE_WORDS)
	assert_bool((node["options"][1] as Dictionary).has("effects")).is_false()


func test_it_goes_through_a_save_as_it_is() -> void:
	var furnace: Furnace = Furnace.new()
	assert_dict(furnace.to_dict()).override_failure_message("cold: nothing to save").is_empty()
	furnace.light(&"gold_bar", 1, 7)
	assert_dict(furnace.to_dict()).is_equal({"item": "gold_bar", "count": 1, "day": 7})
	var again: Furnace = Furnace.new()
	again.load_saved(JSON.parse_string(JSON.stringify(furnace.to_dict())))
	assert_that(again.item).is_equal(&"gold_bar")
	assert_int(again.count).is_equal(1)
	assert_int(again.day).is_equal(7)
	assert_bool(again.is_burning(7)).is_true()
	assert_bool(again.is_ready(8)).is_true()
	# Loading replaces what was there, and anything that isn't a load leaves it cold.
	for odd: Variant in [null, "hot", [], {}, {"item": "", "count": 3}, {"item": "gold_bar", "count": 0}, {"item": 5, "count": 2}, {"item": "gold_bar", "count": "two"}]:
		again.light(&"copper_bar", 2, 1)
		again.take()
		again.light(&"copper_bar", 2, 1)
		again.load_saved(odd)
		assert_bool(again.is_empty()).override_failure_message("%s" % [odd]).is_true()


func _count(item_id: String) -> int:
	return int(_held.get(item_id, 0))
