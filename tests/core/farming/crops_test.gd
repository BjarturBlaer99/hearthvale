extends GdUnitTestSuite
## Crops (P3b): the game's five crops as data (data/crops), their seeds and what they give;
## what ToolUse says about a seed on the item button; and bad crops named.

const DataRegistryScript: GDScript = preload("res://autoload/data_registry.gd")

## GDD §7: each crop's days, seed price and sale price.
const TABLE: Dictionary = {
	&"turnip": [3, 5, 12], &"carrot": [4, 8, 18], &"wheat": [5, 6, 10], &"potato": [5, 10, 24], &"pumpkin": [8, 20, 60],
}
## What each crop gives raw: about a third of what it is worth cooked (docs/DECISIONS.md).
const RAW: Dictionary = {&"turnip": 7.0, &"carrot": 7.0, &"wheat": 5.0, &"potato": 8.0, &"pumpkin": 22.0}


func test_the_five_crops_are_data() -> void:
	assert_array(DataRegistry.ids(&"crops").map(func(id: StringName) -> String: return String(id))).is_equal(["carrot", "potato", "pumpkin", "turnip", "wheat"])
	var item_of: Callable = func(id: String) -> Dictionary: return DataRegistry.get_item(StringName(id))
	for id: StringName in TABLE:
		var crop: Dictionary = DataRegistry.get_crop(id)
		assert_array(Array(Crops.problems(crop, item_of))).override_failure_message(String(id)).is_empty()
		assert_int(Crops.days_of(crop)).override_failure_message("%s's days" % id).is_equal(TABLE[id][0])
		assert_int(int(crop["seed_price"])).override_failure_message("%s's seed price" % id).is_equal(TABLE[id][1])
		assert_int(int(crop["sells_for"])).override_failure_message("%s's sale price" % id).is_equal(TABLE[id][2])
		assert_bool(int(crop["sells_for"]) > int(crop["seed_price"])).override_failure_message("%s is worth growing" % id).is_true()
		assert_dict(Crops.gives(crop)).is_equal({"item": String(id), "count": 1})
	assert_dict(Crops.days_by_id(DataRegistry.entries(&"crops"))).is_equal({"carrot": 4, "potato": 5, "pumpkin": 8, "turnip": 3, "wheat": 5})
	assert_dict(DataRegistry.get_crop(&"moonflower")).is_empty()
	assert_int(Crops.days_of({})).override_failure_message("a crop that says nothing takes a morning").is_equal(1)


func test_every_crop_has_a_seed_that_plants_it_and_a_harvest_that_can_be_eaten() -> void:
	for id: StringName in TABLE:
		var crop: Dictionary = DataRegistry.get_crop(id)
		var seed: Dictionary = DataRegistry.get_item(StringName(str(crop["seed"])))
		assert_bool(Crops.is_seed(seed)).override_failure_message("%s is a seed" % crop["seed"]).is_true()
		assert_str(Crops.crop_of_seed(seed)).is_equal(String(id))
		assert_str(ToolUse.kind_of(seed)).is_equal(ToolUse.SEED)
		assert_bool(ToolUse.is_farm_tool(seed)).override_failure_message("a seed is no tool").is_false()
		assert_bool(Inventory.is_equippable(seed)).override_failure_message("%s goes on the item button" % crop["seed"]).is_true()
		assert_str(Inventory.ammo_for(seed)).override_failure_message("and is used up itself").is_equal(str(crop["seed"]))
		assert_int(Inventory.capacity(seed)).is_greater_equal(18)
		var harvest: Dictionary = DataRegistry.get_item(id)
		assert_bool(Food.is_food(harvest)).override_failure_message("%s can be eaten raw" % id).is_true()
		assert_float(Food.energy_of(harvest)).is_equal(RAW[id])
		assert_int(Food.halves_of(harvest)).override_failure_message("raw, it mends no hearts").is_equal(0)
		assert_int(Inventory.capacity(harvest)).override_failure_message("a whole plot of it fits the pack").is_greater_equal(18)
		assert_bool(Inventory.is_equippable(harvest)).is_false()
		for item_id: StringName in [id, StringName(str(crop["seed"]))]:
			assert_bool(ItemIcons.FRAMES.has(ItemIcons.name_for(item_id)) and ItemIcons.name_for(item_id) == item_id).override_failure_message("%s has a picture of its own" % item_id).is_true()
		for phase: StringName in [Farm.GROWING, Farm.RIPE]:
			assert_that(FarmPlot.crop_frame(String(id), phase)).override_failure_message("%s %s" % [id, phase]).is_equal(StringName("%s_%s" % [id, phase]))
	assert_str(Crops.crop_of_seed(DataRegistry.get_item(&"hoe"))).is_equal("")
	assert_str(Crops.crop_of_seed({"type": "seed"})).is_equal("")
	assert_array(Inventory.held_in_tools(DataRegistry.entries(&"items"))).override_failure_message("seeds are in the pack, not in a tool").is_equal(["water"])


func test_a_seed_is_planted_in_tilled_soil_with_nothing_in_it() -> void:
	assert_dict(ToolUse.decide(ToolUse.SEED, Farm.TILLED, false, 5, 30)).is_equal({"does": ToolUse.PLANT, "says": ""})
	assert_dict(ToolUse.decide(ToolUse.SEED, Farm.WATERED, false, 1, 30)).override_failure_message("wet soil takes a seed").is_equal({"does": ToolUse.PLANT, "says": ""})
	assert_dict(ToolUse.decide(ToolUse.SEED, Farm.BARE, false, 5, 30)).is_equal({"does": ToolUse.NOTHING, "says": ToolUse.SEED_BARE})
	assert_dict(ToolUse.decide(ToolUse.SEED, &"", false, 5, 30)).is_equal({"does": ToolUse.NOTHING, "says": ToolUse.SEED_NOT_HERE})
	assert_dict(ToolUse.decide(ToolUse.SEED, &"", true, 5, 30)).override_failure_message("not at the well either").is_equal({"does": ToolUse.NOTHING, "says": ToolUse.SEED_NOT_HERE})
	assert_dict(ToolUse.decide(ToolUse.SEED, Farm.TILLED, false, 5, 30, true)).is_equal({"does": ToolUse.NOTHING, "says": ToolUse.SEED_TAKEN})
	assert_dict(ToolUse.decide(ToolUse.SEED, Farm.TILLED, false, 0, 30)).is_equal({"does": ToolUse.NOTHING, "says": ToolUse.SEED_NONE})
	# The tools on a planted cell: the hoe leaves it alone, the can waters it as any other.
	assert_dict(ToolUse.decide(ToolUse.HOE, Farm.TILLED, false, 0, 0, true)).is_equal({"does": ToolUse.NOTHING, "says": ToolUse.HOE_GROWING})
	assert_dict(ToolUse.decide(ToolUse.HOE, Farm.WATERED, false, 0, 0, true)).is_equal({"does": ToolUse.NOTHING, "says": ToolUse.HOE_GROWING})
	assert_dict(ToolUse.decide(ToolUse.CAN, Farm.TILLED, false, 3, 10, true)).is_equal({"does": ToolUse.WATER, "says": ""})
	assert_dict(ToolUse.decide(ToolUse.CAN, Farm.WATERED, false, 3, 10, true)).is_equal({"does": ToolUse.NOTHING, "says": ToolUse.CAN_DONE})


func test_bad_crops_and_bad_seeds_are_named() -> void:
	var items: Dictionary = {
		"bean_seeds": {"id": "bean_seeds", "type": "seed", "stats": {"crop": "bean"}},
		"bean": {"id": "bean", "type": "food"},
		"pea_seeds": {"id": "pea_seeds", "type": "seed", "stats": {"crop": "pea"}},
		"pebble": {"id": "pebble", "type": "quest"},
	}
	var item_of: Callable = func(id: String) -> Dictionary: return items.get(id, {})
	var good: Dictionary = {"id": "bean", "name": "Bean", "days": 2, "seed": "bean_seeds", "gives": {"item": "bean", "count": 2}, "seed_price": 3, "sells_for": 0}
	assert_array(Array(Crops.problems(good, item_of))).is_empty()
	assert_dict(Crops.gives(good)).is_equal({"item": "bean", "count": 2})
	var bad: Dictionary = {"id": "bean", "name": "Bean", "days": 0, "seed": "pea_seeds", "gives": {"item": "husk", "count": 0}, "seed_price": -1, "sells_for": 2.5}
	assert_array(Array(Crops.problems(bad, item_of))).contains_exactly([
		"'days' must be a whole number of 1 or more: the watered mornings it takes to ripen.",
		"'seed' must be an item of type 'seed' whose stats name this crop ('pea_seeds' doesn't).",
		"'gives' names an unknown item id 'husk'.",
		"'gives' 'count' must be a whole number of 1 or more.",
		"'seed_price' must be a whole number of coins, 0 or more.",
		"'sells_for' must be a whole number of coins, 0 or more.",
	])
	assert_array(Array(Crops.problems({"id": "bean", "days": 2, "seed": "gravel", "gives": "beans", "seed_price": 1, "sells_for": 1}, item_of))).contains_exactly([
		"'seed' names an unknown item id 'gravel'.",
		"'gives' must name the 'item' a harvest gives.",
	])
	assert_array(Array(Crops.problems({"id": "bean", "days": 2, "seed": "pebble", "gives": {"item": "bean"}, "seed_price": 1, "sells_for": 1}, item_of))).override_failure_message("a seed must be a seed").contains_exactly([
		"'seed' must be an item of type 'seed' whose stats name this crop ('pebble' doesn't).",
	])
	var is_crop: Callable = func(id: String) -> bool: return id == "bean"
	assert_array(Array(Crops.seed_problems(items["bean_seeds"], is_crop))).is_empty()
	assert_array(Array(Crops.seed_problems(items["pea_seeds"], is_crop))).contains_exactly(["a seed's 'crop' names an unknown crop id 'pea'."])
	assert_array(Array(Crops.seed_problems({"id": "dust", "type": "seed"}, is_crop))).contains_exactly(["a seed's stats must name the 'crop' it plants."])
	# The registry runs them on every crop and every seed.
	var registry: Node = auto_free(DataRegistryScript.new())
	var errors: String = "\n".join(registry.load_all("res://tests/fixtures/bad_crops"))
	assert_str(errors).contains("crop 'bean': 'days' must be a whole number of 1 or more")
	assert_str(errors).contains("crop 'bean': 'gives' names an unknown item id 'husk'.")
	assert_str(errors).contains("crop 'pea': 'seed' names an unknown item id 'pea_seeds'.")
	assert_str(errors).contains("item 'fern_spores': a seed's 'crop' names an unknown crop id 'fern'.")
	assert_str(errors).contains("crop 'oat' is missing required field 'sells_for'.")
