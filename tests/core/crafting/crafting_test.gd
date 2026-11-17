extends GdUnitTestSuite
## Crafting's rules (Crafting, pure): which recipes a station has and in what order, when one
## is known, what is missing, why a thing can't be made, how its needs read, and recipes and
## rules that can't be used.

const FURNACE: Dictionary = {
	"id": "furnace", "name": "Furnace", "station": "workbench", "order": 1,
	"needs": [{"item": "stone", "count": 20}, {"item": "copper_ore", "count": 5}],
	"makes": {"furnishing": "furnace"}, "unlock": {"found": "copper_ore"},
}
const BOMBS: Dictionary = {
	"id": "bombs", "station": "workbench", "order": 3,
	"needs": [{"item": "coal", "count": 1}, {"item": "stone", "count": 3}],
	"makes": {"item": "bomb", "count": 3}, "unlock": {"found": "coal"},
}
const SPRINKLER: Dictionary = {
	"id": "sprinkler", "station": "workbench", "order": 4,
	"needs": [{"item": "copper_bar", "count": 1}, {"item": "iron_bar", "count": 1}],
	"makes": {"item": "sprinkler", "count": 1}, "unlock": {"skill": "farming", "level": 2},
}
const COPPER_HOE: Dictionary = {
	"id": "copper_hoe", "station": "workbench", "order": 5,
	"needs": [{"item": "hoe", "count": 1}, {"item": "copper_bar", "count": 2}],
	"makes": {"item": "copper_hoe", "count": 1},
}
const RUG: Dictionary = {
	"id": "rug", "name": "Woven Rug", "order": 12,
	"needs": [{"item": "wheat", "count": 8}], "makes": {"furnishing": "rug"},
}
const BAR: Dictionary = {
	"id": "copper_bar", "station": "furnace", "order": 1,
	"needs": [{"item": "copper_ore", "count": 3}, {"item": "coal", "count": 1}],
	"makes": {"item": "copper_bar", "count": 1},
}
const NAMES: Dictionary = {"stone": "Stone", "copper_ore": "Copper Ore", "coal": "Coal", "bomb": "Bombs", "copper_bar": "Copper Bar", "iron_bar": "Iron Bar", "sprinkler": "Sprinkler", "hoe": "Hoe", "copper_hoe": "Copper Hoe"}

var _held: Dictionary = {}
var _found: Array = []
var _levels: Dictionary = {}
var _furnished: Array = []
## Item id -> how many of it he can carry in all.
var _most: Dictionary = {}


func before_test() -> void:
	_held = {}
	_found = []
	_levels = {}
	_furnished = []
	_most = {}


func test_a_station_has_its_own_recipes_in_their_order() -> void:
	var all: Array = [RUG, BAR, SPRINKLER, FURNACE, BOMBS, COPPER_HOE]
	assert_array(_ids(Crafting.of_station(all, Crafting.WORKBENCH))).is_equal(["furnace", "bombs", "sprinkler", "copper_hoe", "rug"])
	assert_array(_ids(Crafting.of_station(all, Crafting.FURNACE))).is_equal(["copper_bar"])
	assert_str(Crafting.station_of(RUG)).override_failure_message("a recipe that names no station is the workbench's").is_equal(Crafting.WORKBENCH)
	# Recipes with the same place in the order go by id.
	var twins: Array = [{"id": "b", "order": 2, "needs": [], "makes": {}}, {"id": "a", "order": 2, "needs": [], "makes": {}}, {"id": "c", "order": 1, "needs": [], "makes": {}}]
	assert_array(_ids(Crafting.of_station(twins, Crafting.WORKBENCH))).is_equal(["c", "a", "b"])
	assert_array(Crafting.of_station([], Crafting.WORKBENCH)).is_empty()


func test_a_recipe_is_known_once_its_item_is_found_or_its_skill_has_risen() -> void:
	assert_bool(_known(RUG)).override_failure_message("no unlock: known from the start").is_true()
	assert_bool(_known(FURNACE)).is_false()
	_found = ["coal"]
	assert_bool(_known(FURNACE)).override_failure_message("coal is not copper ore").is_false()
	assert_bool(_known(BOMBS)).is_true()
	_found = ["copper_ore"]
	assert_bool(_known(FURNACE)).is_true()
	assert_bool(_known(SPRINKLER)).is_false()
	_levels = {"farming": 1}
	assert_bool(_known(SPRINKLER)).is_false()
	_levels = {"mining": 5, "farming": 1}
	assert_bool(_known(SPRINKLER)).override_failure_message("it is farming that opens it").is_false()
	_levels = {"farming": 2}
	assert_bool(_known(SPRINKLER)).is_true()
	_levels = {"farming": 4}
	assert_bool(_known(SPRINKLER)).is_true()
	# The list a station shows is its known recipes, in order.
	var all: Array = [RUG, BAR, SPRINKLER, FURNACE, BOMBS]
	_levels = {}
	_found = ["coal"]
	assert_array(_ids(Crafting.known(all, Crafting.WORKBENCH, _has_found, _level_of))).is_equal(["bombs", "rug"])


func test_what_a_recipe_makes_and_what_it_is_called() -> void:
	assert_str(Crafting.furnishing_made(FURNACE)).is_equal("furnace")
	assert_str(Crafting.item_made(FURNACE)).is_equal("")
	assert_str(Crafting.item_made(BOMBS)).is_equal("bomb")
	assert_str(Crafting.furnishing_made(BOMBS)).is_equal("")
	assert_int(Crafting.count_made(BOMBS)).is_equal(3)
	assert_int(Crafting.count_made(FURNACE)).is_equal(1)
	assert_str(Crafting.name_of(FURNACE, NAMES)).override_failure_message("its own name").is_equal("Furnace")
	assert_str(Crafting.name_of(BOMBS, NAMES)).override_failure_message("its item's name, and how many").is_equal("Bombs x3")
	assert_str(Crafting.name_of(SPRINKLER, NAMES)).is_equal("Sprinkler")
	assert_str(Crafting.name_of(SPRINKLER, {})).override_failure_message("an item with no name goes by its id").is_equal("sprinkler")
	assert_that(Crafting.furnished_flag(&"furnace")).is_equal(&"home/furnace")


func test_what_is_missing_is_what_he_is_short_of() -> void:
	assert_array(Crafting.missing(FURNACE, _count)).is_equal([{"item": "stone", "count": 20}, {"item": "copper_ore", "count": 5}])
	_held = {"stone": 12, "copper_ore": 5}
	assert_array(Crafting.missing(FURNACE, _count)).is_equal([{"item": "stone", "count": 8}])
	_held = {"stone": 20, "copper_ore": 9}
	assert_array(Crafting.missing(FURNACE, _count)).is_empty()
	assert_array(Array(Crafting.need_lines(FURNACE, _count, NAMES))).override_failure_message("more than is needed shows as what is needed").is_equal(["Stone 20 of 20", "Copper Ore 5 of 5"])
	_held = {"stone": 12}
	assert_array(Array(Crafting.need_lines(FURNACE, _count, NAMES))).is_equal(["Stone 12 of 20", "Copper Ore 0 of 5"])
	assert_array(Array(Crafting.need_lines(FURNACE, _count, {}))).override_failure_message("with no names, the ids").is_equal(["stone 12 of 20", "copper_ore 0 of 5"])


func test_why_a_thing_cant_be_made() -> void:
	_most = {"bomb": 10, "copper_hoe": 1}
	assert_str(_why_not(BOMBS)).is_equal(Crafting.LACKING_WORDS)
	_held = {"coal": 1, "stone": 2}
	assert_str(_why_not(BOMBS)).override_failure_message("one stone short").is_equal(Crafting.LACKING_WORDS)
	_held = {"coal": 1, "stone": 3}
	assert_str(_why_not(BOMBS)).is_equal("")
	# No room for all it makes: three bombs on top of eight don't fit a bag of ten.
	_held = {"coal": 1, "stone": 3, "bomb": 8}
	assert_str(_why_not(BOMBS)).is_equal(Crafting.NO_ROOM_WORDS)
	_held["bomb"] = 7
	assert_str(_why_not(BOMBS)).is_equal("")
	# A furnishing is made once.
	_held = {"stone": 20, "copper_ore": 5}
	assert_str(_why_not(FURNACE)).is_equal("")
	_furnished = ["furnace"]
	assert_str(_why_not(FURNACE)).is_equal(Crafting.HAVE_ONE_WORDS)
	_held = {}
	assert_str(_why_not(FURNACE)).override_failure_message("having one comes before lacking the stone").is_equal(Crafting.HAVE_ONE_WORDS)
	# A tool made from a tool: the new one has room whatever he carries.
	_held = {"hoe": 1, "copper_bar": 2}
	assert_str(_why_not(COPPER_HOE)).is_equal("")
	_held["copper_hoe"] = 1
	assert_str(_why_not(COPPER_HOE)).override_failure_message("he has a copper hoe already").is_equal(Crafting.NO_ROOM_WORDS)


func test_a_thing_it_uses_up_makes_room_for_one_of_its_kind() -> void:
	# Two of a thing go in and three come out: one more to carry, not three.
	var recipe: Dictionary = {"id": "more", "needs": [{"item": "bomb", "count": 2}], "makes": {"item": "bomb", "count": 3}}
	_most = {"bomb": 10}
	_held = {"bomb": 9}
	assert_str(_why_not(recipe)).is_equal("")
	_held = {"bomb": 10}
	assert_str(_why_not(recipe)).is_equal(Crafting.NO_ROOM_WORDS)


func test_the_games_recipes_load_clean() -> void:
	assert_array(Array(DataRegistry.errors)).is_empty()
	var workbench: Array = _ids(Crafting.of_station(DataRegistry.entries(&"crafting"), Crafting.WORKBENCH))
	assert_array(workbench.slice(0, 2)).override_failure_message("the furnace first, then bombs among the first").contains(["furnace"])
	assert_array(_ids(Crafting.of_station(DataRegistry.entries(&"crafting"), Crafting.FURNACE))).is_equal(["copper_bar", "iron_bar", "gold_bar"])
	for metal: String in ["copper", "iron", "gold"]:
		var bar: Dictionary = DataRegistry.get_crafting(StringName(metal + "_bar"))
		assert_array(Crafting.needs_of(bar)).override_failure_message("a %s bar: three ore and one coal" % metal).is_equal([{"item": metal + "_ore", "count": 3}, {"item": "coal", "count": 1}])
		assert_str(Crafting.item_made(bar)).is_equal(metal + "_bar")
		assert_int(Crafting.count_made(bar)).is_equal(1)
		assert_str(str(DataRegistry.get_item(StringName(metal + "_bar"))["type"])).is_equal("material")
	var rules: Dictionary = DataRegistry.get_rules(DataRegistry.RULES_CRAFTING)
	assert_int(int(rules["furnace_most"])).is_equal(5)
	assert_int(int(rules["chest_slots"])).is_equal(24)
	assert_array(rules["furnishings"]).is_equal(["furnace", "chest", "rug", "lamp"])


func test_recipes_that_cant_be_used_say_why() -> void:
	var item_of: Callable = func(id: String) -> Dictionary: return {"id": id} if NAMES.has(id) else {}
	var furnishings: Array = ["furnace", "chest"]
	var skills: Array = ["farming", "mining"]
	for good: Dictionary in [FURNACE, BOMBS, SPRINKLER, COPPER_HOE, BAR]:
		assert_array(Array(Crafting.problems(good, item_of, furnishings, skills))).override_failure_message(str(good["id"])).is_empty()
	var cases: Array = [
		[{"station": "anvil"}, "'station' must be one of: workbench, furnace."],
		[{"makes": {}}, "'makes' must name an 'item' or a 'furnishing', one of the two."],
		[{"makes": {"item": "bomb", "furnishing": "furnace"}}, "'makes' must name an 'item' or a 'furnishing', one of the two."],
		[{"makes": {"item": "gunpowder"}}, "'makes' names an unknown item id 'gunpowder'."],
		[{"makes": {"item": "bomb", "count": 0}}, "'makes' 'count' must be 1 or more."],
		[{"makes": {"furnishing": "throne"}}, "'makes' names an unknown furnishing 'throne'."],
		[{"station": "furnace", "makes": {"furnishing": "chest"}}, "the furnace makes items, not furnishings."],
		[{"needs": []}, "'needs' must list one thing or more that the recipe uses."],
		[{"needs": [{"item": "coal"}]}, "every entry in 'needs' has an 'item' and a 'count'."],
		[{"needs": [{"item": "peat", "count": 1}]}, "'needs' names an unknown item id 'peat'."],
		[{"needs": [{"item": "coal", "count": 0}]}, "'needs' wants 1 or more of 'coal'."],
		[{"unlock": "later"}, "'unlock' must name an item 'found' or a 'skill' and its 'level', one of the two."],
		[{"unlock": {"found": "coal", "skill": "mining", "level": 2}}, "'unlock' must name an item 'found' or a 'skill' and its 'level', one of the two."],
		[{"unlock": {"found": "peat"}}, "'unlock' names an unknown item id 'peat'."],
		[{"unlock": {"skill": "smithing", "level": 2}}, "'unlock' names an unknown skill 'smithing'."],
		[{"unlock": {"skill": "mining", "level": 1}}, "'unlock' needs a 'level' of 2 or more: every skill begins at 1."],
	]
	for case: Array in cases:
		var recipe: Dictionary = BOMBS.duplicate(true)
		recipe.merge(case[0], true)
		assert_array(Array(Crafting.problems(recipe, item_of, furnishings, skills))).override_failure_message("%s" % [case[0]]).contains([case[1]])


func test_rules_that_cant_be_used_say_why() -> void:
	var good: Dictionary = {"furnace_most": 5, "chest_slots": 24, "furnishings": ["furnace"]}
	assert_array(Array(Crafting.rules_problems(good))).is_empty()
	var cases: Array = [
		[{"furnace_most": 0}, "'furnace_most' must be a whole number of 1 or more."],
		[{"furnace_most": 2.5}, "'furnace_most' must be a whole number of 1 or more."],
		[{"chest_slots": "many"}, "'chest_slots' must be a whole number of 1 or more."],
		[{"furnishings": "all"}, "'furnishings' must list what the hero's home can be furnished with."],
		[{"furnishings": ["furnace", 3]}, "every entry in 'furnishings' is a name."],
	]
	for case: Array in cases:
		var rules: Dictionary = good.duplicate(true)
		rules.merge(case[0], true)
		assert_array(Array(Crafting.rules_problems(rules))).override_failure_message("%s" % [case[0]]).contains([case[1]])


# --- Helpers -------------------------------------------------------------------------------

func _ids(recipes: Array) -> Array:
	return recipes.map(func(recipe: Dictionary) -> String: return str(recipe["id"]))


func _count(item_id: String) -> int:
	return int(_held.get(item_id, 0))


func _has_found(item_id: String) -> bool:
	return _found.has(item_id)


func _level_of(skill: String) -> int:
	return int(_levels.get(skill, 1))


func _known(recipe: Dictionary) -> bool:
	return Crafting.is_known(recipe, _has_found, _level_of)


func _why_not(recipe: Dictionary) -> String:
	return Crafting.why_not(recipe, _count,
		func(item_id: String, count: int) -> bool: return _count(item_id) + count <= int(_most.get(item_id, 99)),
		func(furnishing: String) -> bool: return _furnished.has(furnishing))
