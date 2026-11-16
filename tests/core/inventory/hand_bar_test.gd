extends GdUnitTestSuite
## The bar of what can be in hand: its order (the best sword, then the things for the item
## button as they were picked up), which of it is in hand, stepping round it, which slots
## show when there are more than nine, and the number a slot has.

const SWORD: Dictionary = {"id": "wooden_sword", "type": "weapon_melee", "stats": {"damage": 2}}
const IRON: Dictionary = {"id": "iron_sword", "type": "weapon_melee", "stats": {"damage": 3}}
const BOW: Dictionary = {"id": "bow", "type": "weapon_ranged", "stats": {"ammo": "arrow"}}
const ARROW: Dictionary = {"id": "arrow", "type": "ammo", "stackable": true, "max_stack": 30}
const BOMB: Dictionary = {"id": "bomb", "type": "bomb", "stackable": true, "max_stack": 10}
const HOE: Dictionary = {"id": "hoe", "type": "tool", "stats": {"tool": "hoe"}}
const CAN: Dictionary = {"id": "watering_can", "type": "tool", "stats": {"tool": "water", "ammo": "water"}}
const SEEDS: Dictionary = {"id": "turnip_seeds", "type": "seed", "stackable": true, "stats": {"crop": "turnip"}}
const BREAD: Dictionary = {"id": "bread", "type": "food", "stackable": true, "stats": {"energy": 30}}
const ITEMS: Array = [SWORD, IRON, BOW, ARROW, BOMB, HOE, CAN, SEEDS, BREAD]


func test_the_sword_comes_first_then_what_goes_on_the_item_button_as_it_was_picked_up() -> void:
	var stacks: Array = [_stack("bread", 2), _stack("hoe"), _stack("wooden_sword"), _stack("bomb", 2), _stack("arrow", 5), _stack("bow")]
	assert_array(_ids(HandBar.entries(stacks, ITEMS))).is_equal(["wooden_sword", "hoe", "bomb", "bow"])
	# Food and arrows are carried, not held in the hand.
	assert_array(_ids(HandBar.entries([_stack("bread"), _stack("arrow", 9)], ITEMS))).is_empty()
	# With two swords it is the better one, once.
	stacks.append(_stack("iron_sword"))
	assert_array(_ids(HandBar.entries(stacks, ITEMS))).is_equal(["iron_sword", "hoe", "bomb", "bow"])
	# With no sword the bar begins with the first thing for the button; a stack of none isn't there.
	assert_array(_ids(HandBar.entries([_stack("bow"), _stack("bomb", 0), _stack("turnip_seeds", 3)], ITEMS))).is_equal(["bow", "turnip_seeds"])
	assert_array(HandBar.entries([], ITEMS)).is_empty()


func test_the_sword_is_in_hand_when_nothing_is_on_the_item_button() -> void:
	var held: Array[Dictionary] = HandBar.entries([_stack("wooden_sword"), _stack("hoe"), _stack("bomb", 2)], ITEMS)
	assert_int(HandBar.index_of(held, &"")).is_equal(0)
	assert_int(HandBar.index_of(held, &"hoe")).is_equal(1)
	assert_int(HandBar.index_of(held, &"bomb")).is_equal(2)
	assert_int(HandBar.index_of(held, &"bow")).override_failure_message("something he doesn't have").is_equal(HandBar.NONE)
	var unarmed: Array[Dictionary] = HandBar.entries([_stack("hoe")], ITEMS)
	assert_int(HandBar.index_of(unarmed, &"")).override_failure_message("no sword: nothing in hand").is_equal(HandBar.NONE)
	# Taking a slot in hand: the sword empties the item button, anything else goes on it.
	assert_that(HandBar.equipped_for(held, 0)).is_equal(&"")
	assert_that(HandBar.equipped_for(held, 2)).is_equal(&"bomb")
	assert_that(HandBar.equipped_for(held, 3)).override_failure_message("no such slot").is_equal(&"")
	assert_that(HandBar.equipped_for(held, -1)).is_equal(&"")
	assert_bool(HandBar.is_sword(SWORD)).is_true()
	assert_bool(HandBar.is_sword(BOW)).is_false()


func test_stepping_goes_round_and_round() -> void:
	var held: Array[Dictionary] = HandBar.entries([_stack("wooden_sword"), _stack("hoe"), _stack("bomb", 2)], ITEMS)
	assert_int(HandBar.stepped(held, &"", 1)).is_equal(1)
	assert_int(HandBar.stepped(held, &"hoe", 1)).is_equal(2)
	assert_int(HandBar.stepped(held, &"bomb", 1)).override_failure_message("past the last, the first").is_equal(0)
	assert_int(HandBar.stepped(held, &"", -1)).override_failure_message("back from the first, the last").is_equal(2)
	assert_int(HandBar.stepped(held, &"hoe", 2)).is_equal(0)
	# With nothing in hand (no sword, nothing on the button) a step takes an end of the bar.
	var unarmed: Array[Dictionary] = HandBar.entries([_stack("hoe"), _stack("bomb", 1)], ITEMS)
	assert_int(HandBar.stepped(unarmed, &"", 1)).is_equal(0)
	assert_int(HandBar.stepped(unarmed, &"", -1)).is_equal(1)
	assert_int(HandBar.stepped([], &"", 1)).override_failure_message("nothing to hold").is_equal(HandBar.NONE)


func test_with_more_than_nine_things_the_bar_keeps_the_one_in_hand_in_view() -> void:
	assert_int(HandBar.SLOTS).is_equal(9)
	assert_int(HandBar.first_shown(0, 0, 12)).is_equal(0)
	assert_int(HandBar.first_shown(0, 8, 12)).is_equal(0)
	assert_int(HandBar.first_shown(0, 9, 12)).override_failure_message("the tenth: the bar moves on by one").is_equal(1)
	assert_int(HandBar.first_shown(1, 11, 12)).is_equal(3)
	assert_int(HandBar.first_shown(3, 5, 12)).override_failure_message("still in view: the bar stays").is_equal(3)
	assert_int(HandBar.first_shown(3, 2, 12)).is_equal(2)
	assert_int(HandBar.first_shown(3, 4, 9)).override_failure_message("nine fit: nothing to move").is_equal(0)
	assert_int(HandBar.first_shown(2, HandBar.NONE, 12)).override_failure_message("nothing in hand: as for the first").is_equal(0)


func test_a_slot_says_how_many_it_has_left_to_use() -> void:
	var held: Dictionary = {&"arrow": 7, &"bomb": 2, &"turnip_seeds": 5}
	var count_of: Callable = func(id: StringName) -> int: return int(held.get(id, 0))
	assert_str(HandBar.count_text(BOW, count_of)).override_failure_message("the bow's arrows").is_equal("7")
	assert_str(HandBar.count_text(BOMB, count_of)).is_equal("2")
	assert_str(HandBar.count_text(SEEDS, count_of)).is_equal("5")
	assert_str(HandBar.count_text(CAN, count_of)).override_failure_message("an empty can").is_equal("0")
	assert_str(HandBar.count_text(SWORD, count_of)).override_failure_message("a sword uses nothing up").is_equal("")
	assert_str(HandBar.count_text(HOE, count_of)).is_equal("")


func _stack(id: String, count: int = 1) -> Dictionary:
	return {"id": id, "count": count}


func _ids(held: Array) -> Array:
	return held.map(func(item: Dictionary) -> String: return str(item["id"]))
