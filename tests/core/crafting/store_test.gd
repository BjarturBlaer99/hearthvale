extends GdUnitTestSuite
## The storage chest's stacks (Store, pure): so many slots, each a stack up to its item's own
## limit, with several stacks of one thing allowed; what it keeps and what stays with the hero;
## putting in, taking out, and through a save.


func test_it_keeps_what_stacks_and_leaves_coins_keys_and_quest_things() -> void:
	assert_bool(Store.can_hold({"id": "copper_ore", "type": "material", "stackable": true, "max_stack": 30})).is_true()
	assert_bool(Store.can_hold({"id": "turnip", "type": "food", "stackable": true, "max_stack": 30})).is_true()
	assert_bool(Store.can_hold({"id": "bomb", "type": "bomb", "stackable": true, "max_stack": 10})).is_true()
	assert_bool(Store.can_hold({"id": "coin", "type": "currency", "stackable": true, "max_stack": 999})).is_false()
	assert_bool(Store.can_hold({"id": "small_key", "type": "key", "stackable": true, "max_stack": 9})).is_false()
	assert_bool(Store.can_hold({"id": "egg_basket", "type": "quest"})).is_false()
	assert_bool(Store.can_hold({"id": "hoe", "type": "tool"})).override_failure_message("a thing there is one of stays in the pack").is_false()
	assert_bool(Store.can_hold({})).is_false()
	# The game's own: every material and every food is kept; the sword, the Lantern and coins are not.
	for item: Dictionary in DataRegistry.entries(&"items"):
		if str(item["type"]) in ["material", "food", "ingredient", "seed"]:
			assert_bool(Store.can_hold(item)).override_failure_message(str(item["id"])).is_true()
	for id: StringName in [&"wooden_sword", &"lantern", &"coin", &"pickaxe", &"big_key"]:
		assert_bool(Store.can_hold(DataRegistry.get_item(id))).override_failure_message(String(id)).is_false()


func test_a_stack_goes_in_whole_and_tops_up_its_own_kind_first() -> void:
	var chest: Store = Store.new(24)
	assert_int(chest.slots).is_equal(24)
	assert_int(chest.free_slots()).is_equal(24)
	assert_int(chest.put("copper_ore", 12, 30)).is_equal(12)
	assert_array(chest.stacks()).is_equal([{"id": "copper_ore", "count": 12}])
	assert_int(chest.put("stone", 50, 50)).is_equal(50)
	# More copper tops up the copper stack, then begins another: the chest may hold several.
	assert_int(chest.put("copper_ore", 30, 30)).is_equal(30)
	assert_array(chest.stacks()).is_equal([{"id": "copper_ore", "count": 30}, {"id": "stone", "count": 50}, {"id": "copper_ore", "count": 12}])
	assert_int(chest.count_of("copper_ore")).is_equal(42)
	assert_int(chest.count_of("iron_ore")).is_equal(0)
	assert_int(chest.used_slots()).is_equal(3)
	assert_int(chest.free_slots()).is_equal(21)
	# What is handed back is a copy: changing it changes nothing in the chest.
	chest.stacks()[0]["count"] = 1
	assert_int(chest.count_of("copper_ore")).is_equal(42)
	assert_int(chest.put("coal", 0, 30)).is_equal(0)
	assert_int(chest.put("coal", -4, 30)).is_equal(0)
	assert_int(chest.used_slots()).is_equal(3)


func test_a_full_chest_takes_only_what_its_stacks_have_room_for() -> void:
	var chest: Store = Store.new(2)
	assert_int(chest.room_for("stone", 50)).override_failure_message("two empty slots: two full stacks").is_equal(100)
	assert_int(chest.put("stone", 50, 50)).is_equal(50)
	assert_int(chest.put("coal", 20, 30)).is_equal(20)
	assert_int(chest.free_slots()).is_equal(0)
	assert_int(chest.room_for("coal", 30)).is_equal(10)
	assert_int(chest.room_for("stone", 50)).is_equal(0)
	assert_int(chest.room_for("wood", 30)).override_failure_message("no slot for a new kind").is_equal(0)
	assert_int(chest.put("coal", 25, 30)).override_failure_message("ten go in; fifteen stay with him").is_equal(10)
	assert_int(chest.put("wood", 5, 30)).is_equal(0)
	assert_int(chest.put("stone", 1, 50)).is_equal(0)
	assert_array(chest.stacks()).is_equal([{"id": "stone", "count": 50}, {"id": "coal", "count": 30}])
	# One thing that fills several slots: thirty to a stack, two slots, sixty at the most.
	var other: Store = Store.new(2)
	assert_int(other.put("iron_ore", 75, 30)).is_equal(60)
	assert_array(other.stacks()).is_equal([{"id": "iron_ore", "count": 30}, {"id": "iron_ore", "count": 30}])
	assert_int(Store.new(0).slots).override_failure_message("a chest has a slot at the least").is_equal(1)


func test_taking_out_takes_from_one_stack_and_an_emptied_stack_is_gone() -> void:
	var chest: Store = Store.new(24)
	chest.put("copper_ore", 30, 30)
	chest.put("stone", 12, 50)
	chest.put("coal", 9, 30)
	assert_int(chest.take(1, 5)).is_equal(5)
	assert_array(chest.stacks()).is_equal([{"id": "copper_ore", "count": 30}, {"id": "stone", "count": 7}, {"id": "coal", "count": 9}])
	assert_int(chest.take(1, 99)).override_failure_message("no more than is there").is_equal(7)
	assert_array(chest.stacks()).override_failure_message("the coal moves up").is_equal([{"id": "copper_ore", "count": 30}, {"id": "coal", "count": 9}])
	assert_int(chest.take(5, 1)).override_failure_message("no such stack").is_equal(0)
	assert_int(chest.take(-1, 1)).is_equal(0)
	assert_int(chest.take(0, 0)).is_equal(0)
	assert_int(chest.take(0, 30)).is_equal(30)
	assert_int(chest.take(0, 9)).is_equal(9)
	assert_int(chest.used_slots()).is_equal(0)
	assert_int(chest.take(0, 1)).is_equal(0)


func test_it_goes_through_a_save_as_it_is() -> void:
	var chest: Store = Store.new(24)
	chest.put("copper_ore", 42, 30)
	chest.put("turnip", 6, 30)
	var saved: Array = chest.to_list()
	assert_array(saved).is_equal([{"id": "copper_ore", "count": 30}, {"id": "copper_ore", "count": 12}, {"id": "turnip", "count": 6}])
	var again: Store = Store.new(24)
	again.load_saved(JSON.parse_string(JSON.stringify(saved)))
	assert_array(again.to_list()).is_equal(saved)
	assert_int(again.count_of("copper_ore")).is_equal(42)
	# Loading replaces what was there.
	again.load_saved([{"id": "coal", "count": 3}])
	assert_array(again.to_list()).is_equal([{"id": "coal", "count": 3}])


func test_odd_values_in_a_save_are_made_safe() -> void:
	var chest: Store = Store.new(3)
	chest.put("stone", 4, 50)
	for odd: Variant in [null, "full", 7, {}]:
		chest.load_saved(odd)
		assert_int(chest.used_slots()).override_failure_message("%s" % [odd]).is_equal(0)
	chest.load_saved([{"id": "stone", "count": 4}, "a stack", {"id": "", "count": 2}, {"id": "coal", "count": 0}, {"id": "coal"}, {"count": 5}, {"id": 9, "count": 1}, {"id": "wood", "count": 2.0}])
	assert_array(chest.to_list()).override_failure_message("only what is a stack is kept").is_equal([{"id": "stone", "count": 4}, {"id": "wood", "count": 2}])
	# No more stacks than slots, and none bigger than its item allows.
	var most: Callable = func(item_id: String) -> int: return 30 if item_id == "coal" else 50
	chest.load_saved([{"id": "coal", "count": 99}, {"id": "stone", "count": 50}, {"id": "coal", "count": 5}, {"id": "wood", "count": 1}], most)
	assert_array(chest.to_list()).is_equal([{"id": "coal", "count": 30}, {"id": "stone", "count": 50}, {"id": "coal", "count": 5}])
