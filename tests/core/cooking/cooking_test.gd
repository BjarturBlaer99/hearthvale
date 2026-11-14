extends GdUnitTestSuite
## Food and Cooking (P2d), pure: what food gives and when it is worth eating; what a recipe
## needs; and the hearth's list, a conversation built from the recipes.

const Fake: GDScript = preload("res://tests/support/fake_state.gd")

const BREAD: Dictionary = {"id": "bread", "name": "Bread", "type": "food", "stackable": true, "max_stack": 10, "stats": {"energy": 30}}
const SOUP: Dictionary = {"id": "soup", "name": "Mushroom Soup", "type": "food", "stackable": true, "max_stack": 5, "stats": {"energy": 35, "hearts": 0.5}}
const PIE: Dictionary = {"id": "pie", "name": "Pumpkin Pie", "type": "food", "stats": {"energy": 80, "hearts": 2}}
const TONIC: Dictionary = {"id": "tonic", "name": "Tonic", "type": "food", "stats": {"hearts": 1.5}}
const BLOSSOM: Dictionary = {"id": "blossom", "name": "Cherry Blossoms", "type": "ingredient", "stackable": true, "max_stack": 30}
const MUSHROOM: Dictionary = {"id": "mushroom", "name": "Mushrooms", "type": "food", "stackable": true, "max_stack": 20, "stats": {"energy": 6}}
const TEA: Dictionary = {"id": "tea", "name": "Cherry Blossom Tea", "type": "food", "stackable": true, "max_stack": 2, "stats": {"energy": 15}}
const TEA_RECIPE: Dictionary = {"id": "tea", "makes": {"item": "tea", "count": 1}, "needs": [{"item": "blossom", "count": 3}]}
const SOUP_RECIPE: Dictionary = {"id": "soup", "makes": {"item": "soup"}, "needs": [{"item": "mushroom", "count": 2}, {"item": "blossom", "count": 1}]}
const ITEMS: Dictionary = {"bread": BREAD, "soup": SOUP, "blossom": BLOSSOM, "mushroom": MUSHROOM, "tea": TEA}


func test_food_gives_energy_and_some_meals_mend_hearts() -> void:
	assert_bool(Food.is_food(BREAD)).is_true()
	assert_bool(Food.is_food(BLOSSOM)).override_failure_message("an ingredient is only cooked with").is_false()
	assert_bool(Food.is_food({})).is_false()
	assert_float(Food.energy_of(BREAD)).is_equal(30.0)
	assert_int(Food.halves_of(BREAD)).is_equal(0)
	assert_int(Food.halves_of(SOUP)).override_failure_message("half a heart is one half").is_equal(1)
	assert_int(Food.halves_of(PIE)).is_equal(4)
	assert_str(Food.gives_text(BREAD)).is_equal("+30 energy")
	assert_str(Food.gives_text(SOUP)).is_equal("+35 energy, +half a heart")
	assert_str(Food.gives_text(PIE)).is_equal("+80 energy, +2 hearts")
	assert_str(Food.gives_text(TONIC)).is_equal("+1 and a half hearts")
	assert_str(Food.gives_text({"type": "food", "stats": {"hearts": 1}})).is_equal("+1 heart")


func test_eating_is_worth_it_only_when_it_would_help() -> void:
	assert_bool(Food.would_help(BREAD, 60.0, 100.0, 6, 6)).is_true()
	assert_bool(Food.would_help(BREAD, 100.0, 100.0, 2, 6)).override_failure_message("bread mends no hearts: a full bar isn't hungry").is_false()
	assert_bool(Food.would_help(SOUP, 100.0, 100.0, 2, 6)).override_failure_message("soup mends a heart, so it helps the hurt").is_true()
	assert_bool(Food.would_help(SOUP, 100.0, 100.0, 6, 6)).is_false()
	assert_bool(Food.would_help(TONIC, 10.0, 100.0, 6, 6)).override_failure_message("a tonic gives no energy").is_false()
	assert_bool(Food.would_help(BLOSSOM, 0.0, 100.0, 1, 6)).override_failure_message("not food at all").is_false()
	var stacks: Array = [{"id": "blossom", "count": 4}, {"id": "soup", "count": 1}, {"id": "bread", "count": 0}, {"id": "mushroom", "count": 2}]
	var held: Array[Dictionary] = Food.edible_held(stacks, ITEMS.values())
	assert_array(held.map(func(item: Dictionary) -> String: return str(item["id"]))).override_failure_message("the food he holds, in the order he got it").is_equal(["soup", "mushroom"])


func test_food_data_must_say_what_it_gives() -> void:
	assert_array(Array(Food.problems(BREAD))).is_empty()
	assert_array(Array(Food.problems(TONIC))).is_empty()
	assert_str("\n".join(Food.problems({"id": "air", "type": "food"}))).contains("needs 'stats'")
	assert_str("\n".join(Food.problems({"id": "air", "type": "food", "stats": {}}))).contains("some 'energy' or some 'hearts'")
	assert_str("\n".join(Food.problems({"id": "bad", "type": "food", "stats": {"energy": -4}}))).contains("'energy'")
	assert_str("\n".join(Food.problems({"id": "bad", "type": "food", "stats": {"energy": 5, "hearts": "two"}}))).contains("'hearts'")


func test_a_recipe_needs_its_makings() -> void:
	assert_bool(Cooking.can_cook(TEA_RECIPE, {"blossom": 3})).is_true()
	assert_bool(Cooking.can_cook(TEA_RECIPE, {"blossom": 2})).is_false()
	assert_bool(Cooking.can_cook(SOUP_RECIPE, {"mushroom": 2})).override_failure_message("every one of its makings").is_false()
	assert_bool(Cooking.can_cook(SOUP_RECIPE, {"mushroom": 5, "blossom": 1})).is_true()
	assert_bool(Cooking.can_cook({"id": "air", "makes": {"item": "tea"}, "needs": []}, {})).override_failure_message("nothing comes of nothing").is_false()
	var names: Dictionary = {"blossom": "Cherry Blossoms", "mushroom": "Mushrooms"}
	assert_str(Cooking.needs_text(TEA_RECIPE, names)).is_equal("3 Cherry Blossoms")
	assert_str(Cooking.needs_text(SOUP_RECIPE, names)).is_equal("2 Mushrooms, 1 Cherry Blossoms")


func test_the_hearths_list_cooks_what_he_has_the_makings_of() -> void:
	var state: RefCounted = Fake.new()
	state.add_item(&"blossom", 7)
	state.add_item(&"mushroom", 1)
	var runner: DialogueRunner = DialogueRunner.new(Cooking.dialogue([TEA_RECIPE, SOUP_RECIPE], ITEMS), state)
	runner.start()
	assert_str(runner.text()).is_equal(Cooking.ASK_WORDS)
	assert_array(Array(runner.option_texts())).override_failure_message("every recipe, then the way out").is_equal(["Cherry Blossom Tea (3 Cherry Blossoms)", "Mushroom Soup (2 Mushrooms, 1 Cherry Blossoms)", Cooking.LEAVE_WORDS])
	runner.choose(0)
	assert_int(int(state.items["blossom"])).override_failure_message("three blossoms into the pot").is_equal(4)
	assert_int(int(state.items["tea"])).is_equal(1)
	assert_str(runner.text()).is_equal("You make cherry blossom tea.")
	runner.choose(0)
	assert_str(runner.text()).override_failure_message("\"Cook something else.\" goes back to the list").is_equal(Cooking.ASK_WORDS)
	runner.choose(1)
	assert_str(runner.text()).override_failure_message("one mushroom isn't two").is_equal(Cooking.LACKING_WORDS)
	assert_int(int(state.items["mushroom"])).is_equal(1)
	assert_bool(state.items.has("soup")).is_false()
	runner.choose(0)
	runner.choose(0)
	assert_int(int(state.items["tea"])).is_equal(2)
	assert_int(int(state.items["blossom"])).is_equal(1)
	# No room for a third cup (he can carry two): nothing is used, nothing is lost.
	state.add_item(&"blossom", 5)
	runner.choose(0)
	runner.choose(0)
	assert_str(runner.text()).is_equal(Cooking.LACKING_WORDS)
	assert_int(int(state.items["blossom"])).is_equal(6)
	runner.choose(1)
	assert_bool(runner.is_running()).override_failure_message("\"That will do.\" ends it").is_false()
	# With nothing to cook the hearth says so.
	var bare: DialogueRunner = DialogueRunner.new(Cooking.dialogue([], ITEMS), state)
	bare.start()
	assert_str(bare.text()).is_equal(Cooking.NOTHING_WORDS)
	assert_array(Array(bare.option_texts())).is_equal([Cooking.LEAVE_WORDS])


func test_a_recipes_problems_are_named() -> void:
	var known: Callable = func(id: String) -> bool: return ITEMS.has(id)
	assert_array(Array(Cooking.problems(TEA_RECIPE, known))).is_empty()
	assert_array(Array(Cooking.problems(SOUP_RECIPE, known))).is_empty()
	assert_str("\n".join(Cooking.problems({"id": "x", "needs": [{"item": "blossom", "count": 1}]}, known))).contains("'makes'")
	assert_str("\n".join(Cooking.problems({"id": "x", "makes": {"item": "nectar"}, "needs": [{"item": "blossom", "count": 1}]}, known))).contains("unknown item id 'nectar'")
	assert_str("\n".join(Cooking.problems({"id": "x", "makes": {"item": "tea", "count": 0}, "needs": [{"item": "blossom", "count": 1}]}, known))).contains("1 or more")
	assert_str("\n".join(Cooking.problems({"id": "x", "makes": {"item": "tea"}, "needs": []}, known))).contains("'needs'")
	assert_str("\n".join(Cooking.problems({"id": "x", "makes": {"item": "tea"}, "needs": [{"item": "dew", "count": 2}]}, known))).contains("unknown item id 'dew'")
	assert_str("\n".join(Cooking.problems({"id": "x", "makes": {"item": "tea"}, "needs": [{"item": "blossom", "count": 0}]}, known))).contains("1 or more of 'blossom'")
	assert_str("\n".join(Cooking.problems({"id": "x", "makes": {"item": "tea"}, "needs": [{"item": "blossom"}]}, known))).contains("an 'item' and a 'count'")


func test_a_recipe_that_is_taught_is_known_only_once_its_flag_is_set() -> void:
	var tea: Dictionary = {"id": "tea", "makes": {"item": "blossom_tea"}, "needs": [{"item": "cherry_blossom", "count": 3}]}
	var jam: Dictionary = {"id": "jam", "taught": true, "makes": {"item": "berry_jam"}, "needs": [{"item": "wild_berries", "count": 3}]}
	var cake: Dictionary = {"id": "cake", "taught": true, "makes": {"item": "carrot_cake"}, "needs": [{"item": "carrot", "count": 2}]}
	assert_bool(Cooking.is_taught(tea)).is_false()
	assert_bool(Cooking.is_taught(jam)).is_true()
	assert_bool(Cooking.is_taught({"id": "odd", "taught": "yes"})).override_failure_message("only a plain yes").is_false()
	assert_that(Cooking.known_flag(&"jam")).is_equal(&"recipe/jam")
	var recipes: Array = [tea, jam, cake, "not a recipe"]
	assert_array(Cooking.known(recipes, {})).override_failure_message("from the start: only what needs no teaching").is_equal([tea])
	assert_array(Cooking.known(recipes, {&"recipe/cake": true})).override_failure_message("in the data's order").is_equal([tea, cake])
	assert_array(Cooking.known(recipes, {"recipe/jam": true, "recipe/cake": true})).override_failure_message("a save's flags, keyed by text").is_equal([tea, jam, cake])
	assert_array(Cooking.known(recipes, {&"recipe/jam": false, &"recipe/cake": "soon"})).is_equal([tea])
	# The hearth's list is built from what he knows.
	var names: Dictionary = {"blossom_tea": {"name": "Tea"}, "berry_jam": {"name": "Jam"}, "cherry_blossom": {"name": "Blossoms"}, "wild_berries": {"name": "Berries"}}
	var answers: Array = Cooking.dialogue(Cooking.known(recipes, {&"recipe/jam": true}), names)["nodes"][Cooking.ASK]["options"]
	assert_bool(answers.any(func(answer: Dictionary) -> bool: return str(answer["text"]).begins_with("Jam"))).is_true()
	assert_bool(answers.any(func(answer: Dictionary) -> bool: return str(answer["text"]).begins_with("carrot_cake"))).is_false()
	# 'taught' must be a yes or a no.
	var known: Callable = func(_id: String) -> bool: return true
	assert_array(Array(Cooking.problems(jam, known))).is_empty()
	var odd: Dictionary = jam.duplicate(true)
	odd["taught"] = "yes"
	assert_array(Array(Cooking.problems(odd, known))).contains(["'taught' must be true or false."])
