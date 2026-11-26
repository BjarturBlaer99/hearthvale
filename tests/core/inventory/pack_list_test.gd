extends GdUnitTestSuite
## The Tab menu's "Pack" (icons, an axe and the item bar, step I2), pure: everything carried,
## in the pack's order, without what a tool holds, and each stack's line.

const SWORD: Dictionary = {"id": "wooden_sword", "name": "Wooden Sword", "type": "weapon_melee"}
const COIN: Dictionary = {"id": "coin", "name": "Coin", "type": "currency", "stackable": true}
const KEY: Dictionary = {"id": "small_key", "name": "Small Key", "type": "key", "stackable": true}
const SHUTTLE: Dictionary = {"id": "weavers_shuttle", "name": "Weaver's Shuttle", "type": "quest"}
const STONE: Dictionary = {"id": "stone", "name": "Stone", "type": "material", "stackable": true}
const BOW: Dictionary = {"id": "bow", "name": "Bow", "type": "weapon_ranged", "stats": {"ammo": "arrow"}}
const ARROW: Dictionary = {"id": "arrow", "name": "Arrows", "type": "ammo", "stackable": true}
const CAN: Dictionary = {"id": "watering_can", "name": "Watering Can", "type": "tool", "stats": {"tool": "water", "ammo": "water"}}
const WATER: Dictionary = {"id": "water", "name": "Water", "type": "ammo", "stackable": true}
const HOE: Dictionary = {"id": "hoe", "name": "Hoe", "type": "tool", "stats": {"tool": "hoe"}}
const BREAD: Dictionary = {"id": "bread", "name": "Bread", "type": "food", "stackable": true}
const ITEMS: Array = [SWORD, COIN, KEY, SHUTTLE, STONE, BOW, ARROW, CAN, WATER, HOE, BREAD]


func test_everything_carried_is_listed_in_the_packs_order() -> void:
	var stacks: Array = [_stack("stone", 9), _stack("coin", 40), _stack("bread", 2), _stack("hoe"), _stack("small_key"),
		_stack("weavers_shuttle"), _stack("wooden_sword"), _stack("bow"), _stack("arrow", 12)]
	assert_array(_ids(PackList.entries(stacks, ITEMS))).is_equal(
		["stone", "coin", "bread", "hoe", "small_key", "weavers_shuttle", "wooden_sword", "bow", "arrow"])
	assert_array(PackList.entries([], ITEMS)).is_empty()


func test_what_a_tool_holds_and_a_stack_of_none_are_not_lines_of_their_own() -> void:
	var stacks: Array = [_stack("watering_can"), _stack("water", 10), _stack("bread", 0), _stack("stone", 3)]
	assert_array(_ids(PackList.entries(stacks, ITEMS))).is_equal(["watering_can", "stone"])
	# A bow's arrows are a stack of their own, not held in the bow.
	assert_array(_ids(PackList.entries([_stack("bow"), _stack("arrow", 5)], ITEMS))).is_equal(["bow", "arrow"])


func test_a_stack_with_no_data_is_still_listed_by_its_id() -> void:
	var listed: Array[Dictionary] = PackList.entries([_stack("mystery", 2)], ITEMS)
	assert_int(listed.size()).is_equal(1)
	assert_str(str(listed[0]["id"])).is_equal("mystery")
	assert_str(PackList.line(listed[0], 2)).is_equal("mystery x2")


func test_each_line_says_the_count() -> void:
	assert_str(PackList.line(STONE, 9)).is_equal("Stone x9")
	assert_str(PackList.line(STONE, 1)).override_failure_message("a stack says its count even of one").is_equal("Stone x1")
	assert_str(PackList.line(SWORD, 1)).override_failure_message("one of what never stacks: the name").is_equal("Wooden Sword")
	assert_str(PackList.line(SHUTTLE, 1)).is_equal("Weaver's Shuttle")
	assert_str(PackList.line(COIN, 120)).is_equal("120 coins")
	assert_str(PackList.line(COIN, 1)).is_equal("1 coin")
	assert_str(PackList.line(CAN, 1, "Water", 10)).override_failure_message("what a tool holds is said on its line").is_equal("Watering Can (Water x10)")
	assert_str(PackList.line(CAN, 1, "Water", 0)).is_equal("Watering Can (Water x0)")


func test_only_a_tool_holds_something_in_itself() -> void:
	assert_str(PackList.holds(CAN)).is_equal("water")
	assert_str(PackList.holds(HOE)).is_equal("")
	assert_str(PackList.holds(BOW)).override_failure_message("arrows are carried, not held in the bow").is_equal("")
	assert_str(PackList.holds(STONE)).is_equal("")


func _stack(id: String, count: int = 1) -> Dictionary:
	return {"id": id, "count": count}


func _ids(entries: Array[Dictionary]) -> Array:
	var out: Array = []
	for entry: Dictionary in entries:
		out.append(str(entry["id"]))
	return out
