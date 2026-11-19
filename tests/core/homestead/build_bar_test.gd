extends GdUnitTestSuite
## BuildBar (the Homestead, phase 2), pure: what is on the build bar (the hand, then what he
## carries to set down), which of it is chosen, and how the wheel and the number keys move the
## choice.

const ITEMS: Array = [
	{"id": "wooden_sword", "name": "Wooden Sword", "type": "weapon_melee"},
	{"id": "hoe", "name": "Hoe", "type": "tool", "stats": {"tool": "hoe"}},
	{"id": "stone", "name": "Stone", "type": "material", "stackable": true, "max_stack": 50},
	{"id": "fence", "name": "Fence", "type": "placeable", "stackable": true, "max_stack": 99, "stats": {"layer": "standing"}},
	{"id": "gate", "name": "Gate", "type": "placeable", "stackable": true, "max_stack": 20, "stats": {"layer": "standing"}},
	{"id": "dirt_path", "name": "Dirt Path", "type": "placeable", "stackable": true, "max_stack": 99, "stats": {"layer": "lying"}},
]


func _pack(ids: Array) -> Array:
	var out: Array = []
	for id: String in ids:
		out.append({"id": StringName(id), "count": 3})
	return out


func _ids(held: Array) -> Array:
	return held.map(func(entry: Dictionary) -> String: return str(entry["id"]))


func test_the_bar_is_the_hand_and_then_the_placeables_he_carries_in_the_packs_order() -> void:
	assert_array(_ids(BuildBar.entries([], ITEMS))).override_failure_message("the hand is always there").is_equal(["hand"])
	assert_array(_ids(BuildBar.entries(_pack(["wooden_sword", "hoe", "stone"]), ITEMS))).override_failure_message("a sword, a tool and stone are no placeables").is_equal(["hand"])
	var held: Array[Dictionary] = BuildBar.entries(_pack(["gate", "wooden_sword", "dirt_path", "stone", "fence"]), ITEMS)
	assert_array(_ids(held)).is_equal(["hand", "gate", "dirt_path", "fence"])
	assert_bool(BuildBar.is_hand(held[0])).is_true()
	assert_bool(BuildBar.is_hand(held[1])).is_false()
	assert_that(BuildBar.HAND).is_equal(&"hand")
	assert_str(str(BuildBar.HAND_ENTRY["name"])).is_equal("Hand")
	assert_str(str(BuildBar.HAND_ENTRY["icon"])).is_equal("hand")
	# A stack that has run out is not on it.
	var pack: Array = _pack(["fence", "gate"])
	pack[0]["count"] = 0
	assert_array(_ids(BuildBar.entries(pack, ITEMS))).is_equal(["hand", "gate"])
	# And nothing on the build bar is ever on the item bar.
	for entry: Dictionary in held:
		assert_bool(Inventory.is_equippable(entry)).override_failure_message(str(entry["id"])).is_false()
	assert_array(_ids(HandBar.entries(_pack(["gate", "wooden_sword", "hoe", "fence"]), ITEMS))).is_equal(["wooden_sword", "hoe"])


func test_which_is_chosen() -> void:
	var held: Array[Dictionary] = BuildBar.entries(_pack(["gate", "dirt_path", "fence"]), ITEMS)
	assert_int(BuildBar.index_of(held, BuildBar.HAND)).is_equal(0)
	assert_int(BuildBar.index_of(held, &"gate")).is_equal(1)
	assert_int(BuildBar.index_of(held, &"fence")).is_equal(3)
	assert_int(BuildBar.index_of(held, &"stone")).is_equal(BuildBar.NONE)
	assert_int(BuildBar.index_of(held, &"")).is_equal(BuildBar.NONE)
	assert_int(BuildBar.index_of([], &"gate")).is_equal(BuildBar.NONE)
	assert_that(BuildBar.id_at(held, 2)).is_equal(&"dirt_path")
	assert_that(BuildBar.id_at(held, 4)).is_equal(&"")
	assert_that(BuildBar.id_at(held, -1)).is_equal(&"")
	# As the mode opens: what was chosen last time if it is still there, else the first thing
	# he carries to set down, else the hand.
	assert_that(BuildBar.opening(held, &"dirt_path")).is_equal(&"dirt_path")
	assert_that(BuildBar.opening(held, BuildBar.HAND)).override_failure_message("the hand is remembered too").is_equal(BuildBar.HAND)
	assert_that(BuildBar.opening(held, &"")).override_failure_message("never opened: the first thing he carries").is_equal(&"gate")
	assert_that(BuildBar.opening(held, &"hedge")).override_failure_message("he has no hedges left").is_equal(&"gate")
	var bare: Array[Dictionary] = BuildBar.entries([], ITEMS)
	assert_that(BuildBar.opening(bare, &"")).override_failure_message("nothing to set down: the hand").is_equal(BuildBar.HAND)
	assert_that(BuildBar.opening(bare, &"fence")).is_equal(BuildBar.HAND)
	# While it is open: what is chosen stays chosen while it is on the bar; the last of a thing
	# set down leaves the hand chosen.
	assert_that(BuildBar.kept(held, &"dirt_path")).is_equal(&"dirt_path")
	assert_that(BuildBar.kept(held, BuildBar.HAND)).is_equal(BuildBar.HAND)
	assert_that(BuildBar.kept(held, &"hedge")).override_failure_message("not the next thing: the hand").is_equal(BuildBar.HAND)
	assert_that(BuildBar.kept(bare, &"gate")).is_equal(BuildBar.HAND)


func test_the_wheel_steps_round_and_round() -> void:
	var held: Array[Dictionary] = BuildBar.entries(_pack(["gate", "dirt_path", "fence"]), ITEMS)
	assert_that(BuildBar.stepped(held, BuildBar.HAND, 1)).is_equal(&"gate")
	assert_that(BuildBar.stepped(held, &"gate", 1)).is_equal(&"dirt_path")
	assert_that(BuildBar.stepped(held, &"dirt_path", 1)).is_equal(&"fence")
	assert_that(BuildBar.stepped(held, &"fence", 1)).override_failure_message("round to the hand").is_equal(BuildBar.HAND)
	assert_that(BuildBar.stepped(held, BuildBar.HAND, -1)).override_failure_message("and back to the last").is_equal(&"fence")
	assert_that(BuildBar.stepped(held, &"fence", -1)).is_equal(&"dirt_path")
	# With nothing chosen, a step on takes the first and a step back the last.
	assert_that(BuildBar.stepped(held, &"", 1)).is_equal(BuildBar.HAND)
	assert_that(BuildBar.stepped(held, &"", -1)).is_equal(&"fence")
	assert_that(BuildBar.stepped([], &"gate", 1)).is_equal(&"")
	# The hand alone on the bar: a step leaves it chosen.
	var bare: Array[Dictionary] = BuildBar.entries([], ITEMS)
	assert_that(BuildBar.stepped(bare, BuildBar.HAND, 1)).is_equal(BuildBar.HAND)
	assert_that(BuildBar.stepped(bare, BuildBar.HAND, -1)).is_equal(BuildBar.HAND)


func test_a_long_bar_moves_along_with_the_choice() -> void:
	assert_int(BuildBar.SLOTS).is_equal(9)
	assert_int(BuildBar.first_shown(0, 0, 16)).is_equal(0)
	assert_int(BuildBar.first_shown(0, 8, 16)).is_equal(0)
	assert_int(BuildBar.first_shown(0, 9, 16)).override_failure_message("the tenth thing is brought into view").is_equal(1)
	assert_int(BuildBar.first_shown(0, 15, 16)).override_failure_message("the hand and all fifteen").is_equal(7)
	assert_int(BuildBar.first_shown(7, 5, 16)).override_failure_message("and back").is_equal(5)
	assert_int(BuildBar.first_shown(3, BuildBar.NONE, 4)).override_failure_message("a short bar starts at its start").is_equal(0)


func test_a_slot_says_how_many_he_carries_and_the_hand_says_nothing() -> void:
	var counts: Dictionary = {&"fence": 12, &"gate": 1}
	var count_of: Callable = func(item_id: StringName) -> int: return int(counts.get(item_id, 0))
	assert_str(BuildBar.count_text({"id": "fence"}, count_of)).is_equal("12")
	assert_str(BuildBar.count_text({"id": "gate"}, count_of)).is_equal("1")
	assert_str(BuildBar.count_text({"id": "dirt_path"}, count_of)).is_equal("0")
	assert_str(BuildBar.count_text(BuildBar.HAND_ENTRY, count_of)).is_equal("")
