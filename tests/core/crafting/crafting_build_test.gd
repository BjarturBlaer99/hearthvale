extends GdUnitTestSuite
## Crafting's "Build" tab (the Homestead, phase 3), pure: a plan makes a building's kit and
## costs coins like any other need; it says what he is short of by name; one of each (a plan
## he has already, as a kit or a building, is refused); a recipe may wait on a building that
## stands; an upgrade names its building; a furnishing may belong to a building's room.

const WELL_PLAN: Dictionary = {
	"id": "well", "name": "Well", "station": "workbench", "tab": "build", "order": 1,
	"needs": [{"item": "stone", "count": 40}, {"item": "wood", "count": 10}, {"item": "copper_bar", "count": 1}, {"item": "coin", "count": 80}],
	"makes": {"item": "well_kit"}, "unlock": {"found": "copper_bar"},
}
const BIG_COOP: Dictionary = {
	"id": "big_coop", "name": "Big Coop", "tab": "build", "order": 4,
	"needs": [{"item": "wood", "count": 20}, {"item": "coin", "count": 350}],
	"makes": {"upgrade": "coop"}, "unlock": {"built": "coop"},
}
const SHED_FURNACE: Dictionary = {
	"id": "shed_furnace", "name": "Shed Furnace", "order": 14,
	"needs": [{"item": "stone", "count": 20}], "makes": {"furnishing": "furnace", "room": "shed"}, "unlock": {"built": "shed"},
}
const NAMES: Dictionary = {"stone": "Stone", "wood": "Wood", "copper_bar": "Copper Bar", "coin": "Coins", "well_kit": "Well Kit"}

var _held: Dictionary = {}
var _built: Array = []
var _had: Array = []


func before_test() -> void:
	_held = {}
	_built = []
	_had = []


func test_the_workbench_has_a_build_tab() -> void:
	assert_array(Crafting.TABS).is_equal(["make", "place", "build"])
	assert_str(Crafting.tab_of(WELL_PLAN)).is_equal(Crafting.TAB_BUILD)
	assert_array(Crafting.of_tab([WELL_PLAN, SHED_FURNACE, BIG_COOP], Crafting.TAB_BUILD)).is_equal([WELL_PLAN, BIG_COOP])


func test_a_recipe_may_wait_on_a_building_that_stands() -> void:
	var nothing: Callable = func(_id: String) -> bool: return false
	var level_one: Callable = func(_skill: String) -> int: return 1
	assert_bool(Crafting.is_known(SHED_FURNACE, nothing, level_one, _has_built)).is_false()
	assert_bool(Crafting.is_known(SHED_FURNACE, nothing, level_one)).override_failure_message("none stands where none is asked").is_false()
	_built = ["shed"]
	assert_bool(Crafting.is_known(SHED_FURNACE, nothing, level_one, _has_built)).is_true()
	assert_bool(Crafting.is_known(BIG_COOP, nothing, level_one, _has_built)).is_false()
	_built.append("coop")
	assert_array(Crafting.known([SHED_FURNACE, BIG_COOP, WELL_PLAN], Crafting.WORKBENCH, nothing, level_one, _has_built).map(
		func(recipe: Dictionary) -> String: return str(recipe["id"]))).is_equal(["big_coop", "shed_furnace"])


func test_what_a_plan_an_upgrade_and_a_rooms_furnishing_make() -> void:
	assert_str(Crafting.item_made(WELL_PLAN)).is_equal("well_kit")
	assert_str(Crafting.upgrade_made(BIG_COOP)).is_equal("coop")
	assert_str(Crafting.upgrade_made(WELL_PLAN)).is_empty()
	assert_str(Crafting.item_made(BIG_COOP)).is_empty()
	assert_str(Crafting.furnishing_made(BIG_COOP)).is_empty()
	assert_str(Crafting.furnishing_made(SHED_FURNACE)).is_equal("shed/furnace")
	assert_that(Crafting.furnished_flag(&"shed/furnace")).override_failure_message("a room's key is its own flag").is_equal(&"shed/furnace")
	assert_that(Crafting.furnished_flag(&"furnace")).is_equal(&"home/furnace")
	assert_str(Crafting.name_of(BIG_COOP, NAMES)).is_equal("Big Coop")
	assert_str(Crafting.name_of(WELL_PLAN, NAMES)).is_equal("Well")


func test_a_plan_says_what_he_is_short_of_by_name() -> void:
	_held = {"stone": 12, "wood": 10, "coin": 50}
	assert_str(_why_not(WELL_PLAN)).is_equal(Crafting.LACKING_WORDS)
	assert_str(Crafting.short_words(WELL_PLAN, _count, NAMES)).is_equal("You are short of 28 Stone, 1 Copper Bar and 30 Coins.")
	_held = {"stone": 40, "wood": 10, "copper_bar": 1, "coin": 79}
	assert_str(Crafting.short_words(WELL_PLAN, _count, NAMES)).is_equal("You are short of 1 Coin.")
	_held["coin"] = 80
	assert_str(Crafting.short_words(WELL_PLAN, _count, NAMES)).is_empty()
	assert_str(_why_not(WELL_PLAN)).is_empty()
	assert_array(Array(Crafting.need_lines(WELL_PLAN, _count, NAMES))).is_equal(["Stone 40 of 40", "Wood 10 of 10", "Copper Bar 1 of 1", "Coins 80 of 80"])


func test_one_of_each_what_he_has_already_is_refused() -> void:
	_held = {"stone": 40, "wood": 10, "copper_bar": 1, "coin": 80}
	_had = ["well"]
	assert_str(_why_not(WELL_PLAN)).is_equal(Crafting.HAVE_ONE_WORDS)
	_had = []
	assert_str(_why_not(WELL_PLAN)).is_empty()
	# Without the question, nothing is had (the farmhouse's recipes ask none).
	assert_str(Crafting.why_not(WELL_PLAN, _count, func(_i: String, _c: int) -> bool: return true, func(_f: String) -> bool: return false)).is_empty()


func test_plans_and_upgrades_that_cant_be_used_say_why() -> void:
	var item_of: Callable = func(id: String) -> Dictionary: return {"id": id} if NAMES.has(id) else {}
	var rooms: Dictionary = {"shed": ["furnace", "chest_a", "chest_b"]}
	var buildings: Array = ["well", "coop", "shed"]
	for good: Dictionary in [WELL_PLAN, BIG_COOP, SHED_FURNACE]:
		assert_array(Array(Crafting.problems(good, item_of, ["furnace"], [], rooms, buildings))).override_failure_message(str(good["id"])).is_empty()
	var cases: Array = [
		[BIG_COOP, {"makes": {"upgrade": "kennel"}}, "'makes' names an unknown building 'kennel' to upgrade."],
		[BIG_COOP, {"makes": {"upgrade": "coop", "item": "wood"}}, "'makes' names an 'upgrade' alone: nothing else."],
		[BIG_COOP, {"tab": "make"}, "an upgrade is on the workbench's 'build' tab."],
		[BIG_COOP, {"unlock": {"built": "kennel"}}, "'unlock' names an unknown building 'kennel'."],
		[BIG_COOP, {"unlock": {"built": "coop", "found": "wood"}}, "'unlock' names a building 'built' alone: nothing else."],
		[SHED_FURNACE, {"makes": {"furnishing": "furnace", "room": "attic"}}, "'makes' names an unknown room 'attic'."],
		[SHED_FURNACE, {"makes": {"furnishing": "lamp", "room": "shed"}}, "'makes' names an unknown furnishing 'lamp'."],
		[WELL_PLAN, {"tab": "barn"}, "'tab' must be one of: make, place, build."],
	]
	for case: Array in cases:
		var recipe: Dictionary = (case[0] as Dictionary).duplicate(true)
		recipe.merge(case[1], true)
		assert_array(Array(Crafting.problems(recipe, item_of, ["furnace"], [], rooms, buildings))).override_failure_message("%s" % [case[1]]).contains([case[2]])
	assert_array(Array(Crafting.rules_problems({"furnace_most": 5, "chest_slots": 24, "furnishings": [], "rooms": rooms}))).is_empty()
	assert_array(Array(Crafting.rules_problems({"furnace_most": 5, "chest_slots": 24, "furnishings": [], "rooms": "shed"}))).contains(["'rooms' must name each room and the furnishings it can have."])
	assert_array(Array(Crafting.rules_problems({"furnace_most": 5, "chest_slots": 24, "furnishings": [], "rooms": {"home": []}}))).contains(["room 'home' must list its furnishings' names (and not be the home's)."])


func _count(item_id: String) -> int:
	return int(_held.get(item_id, 0))


func _has_built(building: String) -> bool:
	return _built.has(building)


func _why_not(recipe: Dictionary) -> String:
	return Crafting.why_not(recipe, _count, func(_item: String, _count_: int) -> bool: return true,
		func(_furnishing: String) -> bool: return false,
		func(wanted: Dictionary) -> bool: return _had.has(Crafting.item_made(wanted).trim_suffix("_kit")))
