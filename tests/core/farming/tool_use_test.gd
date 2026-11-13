extends GdUnitTestSuite
## ToolUse (P3a): what the hoe and the watering can do to what the hero faces, and what they
## say when they do nothing. Tried on the game's own tools (data/items).


func test_the_hoe_tills_bare_soil_and_nothing_else() -> void:
	assert_dict(ToolUse.decide(ToolUse.HOE, Farm.BARE, false, 0, 10)).is_equal({"does": ToolUse.TILL, "says": ""})
	assert_dict(ToolUse.decide(ToolUse.HOE, Farm.TILLED, false, 0, 10)).is_equal({"does": ToolUse.NOTHING, "says": ToolUse.HOE_DONE})
	assert_dict(ToolUse.decide(ToolUse.HOE, Farm.WATERED, false, 0, 10)).is_equal({"does": ToolUse.NOTHING, "says": ToolUse.HOE_DONE})
	assert_dict(ToolUse.decide(ToolUse.HOE, &"", false, 0, 10)).override_failure_message("off the plot").is_equal({"does": ToolUse.NOTHING, "says": ToolUse.HOE_NOT_HERE})
	assert_dict(ToolUse.decide(ToolUse.HOE, &"", true, 0, 10)).override_failure_message("the hoe does nothing at the well").is_equal({"does": ToolUse.NOTHING, "says": ToolUse.HOE_NOT_HERE})


func test_the_can_waters_tilled_soil_while_it_holds_water() -> void:
	assert_dict(ToolUse.decide(ToolUse.CAN, Farm.TILLED, false, 3, 10)).is_equal({"does": ToolUse.WATER, "says": ""})
	assert_dict(ToolUse.decide(ToolUse.CAN, Farm.TILLED, false, 1, 10)).override_failure_message("the last pour").is_equal({"does": ToolUse.WATER, "says": ""})
	assert_dict(ToolUse.decide(ToolUse.CAN, Farm.TILLED, false, 0, 10)).is_equal({"does": ToolUse.NOTHING, "says": ToolUse.CAN_EMPTY})
	assert_dict(ToolUse.decide(ToolUse.CAN, Farm.BARE, false, 3, 10)).is_equal({"does": ToolUse.NOTHING, "says": ToolUse.CAN_BARE})
	assert_dict(ToolUse.decide(ToolUse.CAN, Farm.WATERED, false, 3, 10)).is_equal({"does": ToolUse.NOTHING, "says": ToolUse.CAN_DONE})
	assert_dict(ToolUse.decide(ToolUse.CAN, &"", false, 3, 10)).is_equal({"does": ToolUse.NOTHING, "says": ToolUse.CAN_NOT_HERE})
	# What is wrong with the soil is said before what is wrong with the can.
	assert_str(str(ToolUse.decide(ToolUse.CAN, Farm.BARE, false, 0, 10)["says"])).is_equal(ToolUse.CAN_BARE)
	assert_str(str(ToolUse.decide(ToolUse.CAN, Farm.WATERED, false, 0, 10)["says"])).is_equal(ToolUse.CAN_DONE)
	assert_str(ToolUse.CAN_EMPTY).override_failure_message("an empty can says where to fill it").contains("the well or the pond")


func test_the_can_fills_at_water_until_it_is_full() -> void:
	assert_dict(ToolUse.decide(ToolUse.CAN, &"", true, 0, 10)).is_equal({"does": ToolUse.FILL, "says": ""})
	assert_dict(ToolUse.decide(ToolUse.CAN, &"", true, 9, 10)).is_equal({"does": ToolUse.FILL, "says": ""})
	assert_dict(ToolUse.decide(ToolUse.CAN, &"", true, 10, 10)).is_equal({"does": ToolUse.NOTHING, "says": ToolUse.CAN_FULL})
	assert_dict(ToolUse.decide(ToolUse.CAN, Farm.TILLED, true, 2, 10)).override_failure_message("at the water, he fills").is_equal({"does": ToolUse.FILL, "says": ""})


func test_what_is_no_tool_does_nothing() -> void:
	assert_dict(ToolUse.decide("spade", Farm.BARE, true, 5, 10)).is_equal({"does": ToolUse.NOTHING, "says": ""})
	assert_dict(ToolUse.decide("", Farm.BARE, false, 5, 10)).is_equal({"does": ToolUse.NOTHING, "says": ""})


func test_the_games_tools_are_items() -> void:
	var hoe: Dictionary = DataRegistry.get_item(&"hoe")
	var can: Dictionary = DataRegistry.get_item(&"watering_can")
	var water: Dictionary = DataRegistry.get_item(&"water")
	assert_bool(ToolUse.is_farm_tool(hoe) and ToolUse.is_farm_tool(can)).is_true()
	assert_str(ToolUse.kind_of(hoe)).is_equal(ToolUse.HOE)
	assert_str(ToolUse.kind_of(can)).is_equal(ToolUse.CAN)
	assert_array(Array(ToolUse.problems(hoe))).is_empty()
	assert_array(Array(ToolUse.problems(can))).is_empty()
	assert_float(ToolUse.time_of(hoe)).override_failure_message("a moment's work").is_between(0.2, 0.6)
	assert_float(ToolUse.time_of(can)).is_between(0.2, 0.6)
	assert_float(ToolUse.time_of({})).is_equal(0.4)
	# They go on the item button; the can holds ten pours of water, which is not a tool.
	assert_bool(Inventory.is_equippable(hoe) and Inventory.is_equippable(can)).is_true()
	assert_str(Inventory.ammo_for(hoe)).is_equal("")
	assert_str(Inventory.ammo_for(can)).is_equal("water")
	assert_int(Inventory.capacity(water)).override_failure_message("ten pours").is_equal(10)
	assert_bool(ToolUse.is_farm_tool(water) or Inventory.is_equippable(water)).is_false()
	assert_array(Inventory.held_in_tools(DataRegistry.entries(&"items"))).is_equal(["water"])
	for other: StringName in [&"bow", &"bomb", &"bread", &"wooden_sword"]:
		assert_bool(ToolUse.is_farm_tool(DataRegistry.get_item(other))).override_failure_message("%s is no farm tool" % other).is_false()
		assert_str(ToolUse.kind_of(DataRegistry.get_item(other))).is_equal("")
	for id: StringName in [&"hoe", &"watering_can", &"water"]:
		assert_bool(ItemIcons.FRAMES.has(ItemIcons.name_for(id)) and ItemIcons.name_for(id) == StringName(str(DataRegistry.get_item(id)["icon"]))).override_failure_message("%s has a picture of its own" % id).is_true()


func test_a_bad_tool_is_named() -> void:
	assert_array(Array(ToolUse.problems({"id": "spade", "type": "tool", "stats": {"tool": "dig"}}))).contains_exactly(["a tool's stats must name its 'tool': hoe or water."])
	assert_array(Array(ToolUse.problems({"id": "rake", "type": "tool"}))).contains_exactly(["a tool's stats must name its 'tool': hoe or water."])
	assert_array(Array(ToolUse.problems({"id": "jug", "type": "tool", "stats": {"tool": "water"}}))).contains_exactly(["the watering can's stats must name what it holds ('ammo')."])
