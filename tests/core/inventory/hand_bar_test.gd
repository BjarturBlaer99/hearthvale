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
const COPPER_HOE: Dictionary = {"id": "copper_hoe", "type": "tool", "stats": {"tool": "hoe", "reach": 2}}
const PICK: Dictionary = {"id": "pickaxe", "type": "tool", "stats": {"tool": "pick"}}
const CARROTS: Dictionary = {"id": "carrot_seeds", "type": "seed", "stackable": true, "stats": {"crop": "carrot"}}
const FENCE: Dictionary = {"id": "fence", "type": "placeable", "stackable": true}
const ITEMS: Array = [SWORD, IRON, BOW, ARROW, BOMB, HOE, CAN, SEEDS, BREAD, COPPER_HOE, PICK, CARROTS, FENCE]


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


# --- Columns (step B1: each thing keeps its slot) ---------------------------

func test_with_no_bar_kept_the_columns_are_the_bar_as_it_always_was() -> void:
	var stacks: Array = [_stack("bread", 2), _stack("hoe"), _stack("wooden_sword"), _stack("bomb", 2), _stack("arrow", 5), _stack("bow")]
	assert_array(HandBar.default_bar(stacks, ITEMS)).is_equal([HandBar.SWORD, "hoe", "bomb", "bow"])
	assert_array(HandBar.settled([], stacks, ITEMS)).override_failure_message("settling an empty bar gives the same").is_equal([HandBar.SWORD, "hoe", "bomb", "bow"])
	assert_array(HandBar.default_bar([_stack("bread")], ITEMS)).is_empty()
	# Its columns are the entries, in the same order.
	var held: Array[Dictionary] = HandBar.entries(stacks, ITEMS)
	assert_array(_ids(HandBar.columns(HandBar.default_bar(stacks, ITEMS), held))).is_equal(_ids(held))


func test_a_thing_used_up_leaves_its_column_empty_and_comes_back_to_it() -> void:
	var bar: Array[String] = HandBar.settled([], [_stack("wooden_sword"), _stack("turnip_seeds", 1), _stack("hoe")], ITEMS)
	assert_array(bar).is_equal([HandBar.SWORD, "turnip_seeds", "hoe"])
	# The last seed sown: the bar keeps its column, and shows it empty.
	var after: Array = [_stack("wooden_sword"), _stack("hoe")]
	bar = HandBar.settled(bar, after, ITEMS)
	assert_array(bar).override_failure_message("the column remembers the seeds").is_equal([HandBar.SWORD, "turnip_seeds", "hoe"])
	var shown: Array[Dictionary] = HandBar.columns(bar, HandBar.entries(after, ITEMS))
	assert_int(shown.size()).is_equal(3)
	assert_bool(shown[1].is_empty()).override_failure_message("an empty slot").is_true()
	assert_str(str(shown[2]["id"])).override_failure_message("the hoe doesn't move left").is_equal("hoe")
	assert_bool(HandBar.is_empty_column(shown, 1)).is_true()
	assert_bool(HandBar.is_empty_column(shown, 2)).is_false()
	assert_bool(HandBar.is_empty_column(shown, 3)).override_failure_message("past the end").is_true()
	# A new thing (another kind of seed, a bomb) doesn't take a remembered column.
	var more: Array = [_stack("wooden_sword"), _stack("hoe"), _stack("carrot_seeds", 4), _stack("bomb", 2)]
	bar = HandBar.settled(bar, more, ITEMS)
	assert_array(bar).is_equal([HandBar.SWORD, "turnip_seeds", "hoe", "carrot_seeds", "bomb"])
	# Turnip seeds again: back in their own column.
	more.append(_stack("turnip_seeds", 5))
	bar = HandBar.settled(bar, more, ITEMS)
	assert_array(bar).is_equal([HandBar.SWORD, "turnip_seeds", "hoe", "carrot_seeds", "bomb"])
	assert_array(_ids(HandBar.columns(bar, HandBar.entries(more, ITEMS)))).is_equal(["wooden_sword", "turnip_seeds", "hoe", "carrot_seeds", "bomb"])


func test_empty_columns_at_the_end_are_not_shown() -> void:
	var bar: Array[String] = [HandBar.SWORD, "hoe", "bomb", "turnip_seeds"]
	var held: Array[Dictionary] = HandBar.entries([_stack("wooden_sword"), _stack("hoe")], ITEMS)
	assert_array(_ids(HandBar.columns(bar, held))).is_equal(["wooden_sword", "hoe"])
	assert_array(HandBar.columns(["bomb"], [])).is_empty()
	assert_array(HandBar.columns([], held)).is_empty()


func test_a_better_tool_takes_the_column_of_the_tool_it_was_made_from() -> void:
	var bar: Array[String] = [HandBar.SWORD, "hoe", "watering_can", "turnip_seeds"]
	# The hoe went into the copper hoe: it takes the hoe's column, not the end.
	var stacks: Array = [_stack("wooden_sword"), _stack("watering_can"), _stack("turnip_seeds", 3), _stack("copper_hoe")]
	bar = HandBar.settled(bar, stacks, ITEMS)
	assert_array(bar).is_equal([HandBar.SWORD, "copper_hoe", "watering_can", "turnip_seeds"])
	# A tool of another kind doesn't take a hoe's column.
	bar = HandBar.settled([HandBar.SWORD, "hoe", "watering_can"], [_stack("wooden_sword"), _stack("watering_can"), _stack("pickaxe")], ITEMS)
	assert_array(bar).is_equal([HandBar.SWORD, "hoe", "watering_can", "pickaxe"])
	# With the old hoe still carried, its column is its own: the new one goes on.
	bar = HandBar.settled([HandBar.SWORD, "hoe"], [_stack("wooden_sword"), _stack("hoe"), _stack("copper_hoe")], ITEMS)
	assert_array(bar).is_equal([HandBar.SWORD, "hoe", "copper_hoe"])


func test_a_new_thing_takes_the_first_column_that_remembers_nothing() -> void:
	var bar: Array[String] = [HandBar.SWORD, "", "turnip_seeds", "", "hoe"]
	var stacks: Array = [_stack("wooden_sword"), _stack("hoe"), _stack("bomb", 1)]
	bar = HandBar.settled(bar, stacks, ITEMS)
	assert_array(bar).override_failure_message("past the remembered seeds, into the first free one").is_equal([HandBar.SWORD, "bomb", "turnip_seeds", "", "hoe"])
	stacks.append(_stack("bow"))
	stacks.append(_stack("pickaxe"))
	bar = HandBar.settled(bar, stacks, ITEMS)
	assert_array(bar).override_failure_message("the next free one, then the end").is_equal([HandBar.SWORD, "bomb", "turnip_seeds", "bow", "hoe", "pickaxe"])
	# What has a column keeps it, wherever it is.
	assert_array(HandBar.settled(["hoe", HandBar.SWORD], [_stack("wooden_sword"), _stack("hoe")], ITEMS)).is_equal(["hoe", HandBar.SWORD])


func test_the_first_sword_takes_the_first_column_and_a_better_one_keeps_it() -> void:
	var bar: Array[String] = HandBar.settled([], [_stack("hoe"), _stack("bomb", 2)], ITEMS)
	assert_array(bar).is_equal(["hoe", "bomb"])
	bar = HandBar.settled(bar, [_stack("hoe"), _stack("bomb", 2), _stack("wooden_sword")], ITEMS)
	assert_array(bar).override_failure_message("the sword first, as the bar always had it").is_equal([HandBar.SWORD, "hoe", "bomb"])
	var better: Array = [_stack("hoe"), _stack("bomb", 2), _stack("wooden_sword"), _stack("iron_sword")]
	bar = HandBar.settled(bar, better, ITEMS)
	assert_array(bar).is_equal([HandBar.SWORD, "hoe", "bomb"])
	assert_str(str(HandBar.columns(bar, HandBar.entries(better, ITEMS))[0]["id"])).override_failure_message("whichever sword is best").is_equal("iron_sword")


func test_a_bar_from_a_save_is_made_sound() -> void:
	assert_array(HandBar.cleaned([HandBar.SWORD, "hoe", "", "turnip_seeds"], ITEMS)).is_equal([HandBar.SWORD, "hoe", "", "turnip_seeds"])
	# Food, a placeable, a sword by its id, a thing the game hasn't, a second of one, not a word: nothing.
	assert_array(HandBar.cleaned(["bread", "hoe", "fence", "wooden_sword", "moon_hoe", "hoe", 7, HandBar.SWORD, "bow"], ITEMS)) \
			.is_equal(["", "hoe", "", "", "", "", "", HandBar.SWORD, "bow"])
	assert_array(HandBar.cleaned(["hoe", "", "bread"], ITEMS)).override_failure_message("no empty columns at the end").is_equal(["hoe"])
	assert_array(HandBar.cleaned("hoe", ITEMS)).override_failure_message("not a list").is_empty()
	assert_array(HandBar.cleaned(null, ITEMS)).is_empty()


func test_lifting_a_thing_to_another_column_swaps_or_moves_it() -> void:
	var bar: Array[String] = [HandBar.SWORD, "hoe", "", "bomb"]
	assert_array(HandBar.moved(bar, 1, 3)).override_failure_message("a swap").is_equal([HandBar.SWORD, "bomb", "", "hoe"])
	assert_array(HandBar.moved(bar, 1, 2)).override_failure_message("into an empty column").is_equal([HandBar.SWORD, "", "hoe", "bomb"])
	assert_array(HandBar.moved(bar, 0, 5)).override_failure_message("past the end").is_equal(["", "hoe", "", "bomb", "", HandBar.SWORD])
	assert_array(HandBar.moved(bar, 3, 2)).override_failure_message("no empty columns at the end").is_equal([HandBar.SWORD, "hoe", "bomb"])
	assert_array(HandBar.moved(bar, 1, 1)).is_equal(bar)
	assert_array(HandBar.moved(bar, 9, 1)).override_failure_message("no such column").is_equal(bar)
	assert_array(HandBar.moved(bar, -1, 1)).is_equal(bar)
	assert_array(bar).override_failure_message("the bar given is left as it was").is_equal([HandBar.SWORD, "hoe", "", "bomb"])


func test_the_wheel_steps_over_empty_columns_both_ways() -> void:
	var stacks: Array = [_stack("wooden_sword"), _stack("hoe"), _stack("bomb", 2)]
	var held: Array[Dictionary] = HandBar.columns([HandBar.SWORD, "turnip_seeds", "hoe", "", "bow", "bomb"], HandBar.entries(stacks, ITEMS))
	assert_int(held.size()).is_equal(6)
	assert_int(HandBar.stepped(held, &"", 1)).override_failure_message("over the seeds' empty slot to the hoe").is_equal(2)
	assert_int(HandBar.stepped(held, &"hoe", 1)).override_failure_message("over two empty slots").is_equal(5)
	assert_int(HandBar.stepped(held, &"bomb", 1)).override_failure_message("round to the sword").is_equal(0)
	assert_int(HandBar.stepped(held, &"", -1)).is_equal(5)
	assert_int(HandBar.stepped(held, &"bomb", -1)).is_equal(2)
	assert_int(HandBar.stepped(held, &"hoe", -1)).is_equal(0)
	assert_int(HandBar.stepped(held, &"hoe", 2)).override_failure_message("two things on, not two slots").is_equal(0)
	# An empty column is never in hand, and taking it puts nothing on the button.
	assert_int(HandBar.index_of(held, &"turnip_seeds")).is_equal(HandBar.NONE)
	assert_int(HandBar.index_of(held, &"bow")).is_equal(HandBar.NONE)
	# Only the sword: every step is the sword.
	var alone: Array[Dictionary] = HandBar.columns([HandBar.SWORD, "turnip_seeds", "bomb"], HandBar.entries([_stack("wooden_sword")], ITEMS))
	assert_int(alone.size()).is_equal(1)
	assert_int(HandBar.stepped(alone, &"", 1)).is_equal(0)
	assert_int(HandBar.stepped(alone, &"", -1)).is_equal(0)
	# Nothing in hand (no sword): a step on takes the first thing, a step back the last.
	var unarmed: Array[Dictionary] = HandBar.columns(["", "hoe", "turnip_seeds", "bomb"], HandBar.entries([_stack("hoe"), _stack("bomb", 1)], ITEMS))
	assert_int(HandBar.stepped(unarmed, &"", 1)).is_equal(1)
	assert_int(HandBar.stepped(unarmed, &"", -1)).is_equal(3)
	assert_int(HandBar.stepped(HandBar.columns(["bomb"], []), &"", 1)).override_failure_message("nothing to hold").is_equal(HandBar.NONE)


func _stack(id: String, count: int = 1) -> Dictionary:
	return {"id": id, "count": count}


func _ids(held: Array) -> Array:
	return held.map(func(item: Dictionary) -> String: return str(item["id"]))
