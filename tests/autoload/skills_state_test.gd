extends GdUnitTestSuite
## Skills in the game's state (P4b): a deed adds its points and a level rising is said once;
## what work costs and what a dish gives follow the levels; tilling and picking are practice
## at farming; points go through a save, and a game saved before skills starts at level 1.

const TEST_SLOT: int = 977
const OLD_SAVE: String = "res://tests/fixtures/saves/v3_in_the_keep.json"

var _risen: Array = []


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	_risen.clear()
	EventBus.skill_rose.connect(_on_skill_rose)


func after_test() -> void:
	EventBus.skill_rose.disconnect(_on_skill_rose)
	GameState.clear()
	SaveSystem.current_slot = SaveSystem.GAME_SLOT
	SaveSystem.erase_slot(TEST_SLOT)


func test_a_new_game_has_every_skill_at_level_one() -> void:
	for skill: StringName in GameState.skills().ids():
		assert_int(GameState.skill_level(skill)).override_failure_message(String(skill)).is_equal(1)
	assert_bool(GameState.skill_points.is_empty()).is_true()
	assert_int(GameState.skill_level(&"fishing")).override_failure_message("a skill there isn't").is_equal(1)


func test_a_deed_adds_its_points_and_a_level_rising_is_said_once() -> void:
	for i: int in 9:
		assert_int(GameState.practise(Skills.COMBAT, Skills.MONSTER)).is_equal(1)
	assert_int(GameState.skill_points[Skills.COMBAT]).is_equal(9)
	assert_int(GameState.skill_level(Skills.COMBAT)).is_equal(1)
	assert_array(_risen).override_failure_message("nothing to say yet").is_empty()
	GameState.practise(Skills.COMBAT, Skills.MONSTER)
	assert_int(GameState.skill_level(Skills.COMBAT)).is_equal(2)
	assert_array(_risen).is_equal([[Skills.COMBAT, 2]])
	GameState.practise(Skills.COMBAT, Skills.MONSTER)
	assert_array(_risen).override_failure_message("said once, not at every point after").has_size(1)
	# A boss is worth ten: from 11 to 21, then to 31, past the third level's 25.
	assert_int(GameState.practise(Skills.COMBAT, Skills.BOSS)).is_equal(10)
	assert_array(_risen).has_size(1)
	GameState.practise(Skills.COMBAT, Skills.BOSS)
	assert_array(_risen).is_equal([[Skills.COMBAT, 2], [Skills.COMBAT, 3]])
	assert_int(GameState.skill_points[Skills.COMBAT]).is_equal(31)
	assert_bool(GameState.skill_points.has(Skills.FARMING)).override_failure_message("the other skills are as they were").is_false()


func test_a_deed_a_skill_doesnt_grow_by_changes_nothing() -> void:
	assert_int(GameState.practise(Skills.COMBAT, Skills.TILL)).is_equal(0)
	assert_int(GameState.practise(&"fishing", Skills.MONSTER)).is_equal(0)
	assert_bool(GameState.skill_points.is_empty()).is_true()
	assert_array(_risen).is_empty()


func test_points_past_the_top_level_say_nothing_more() -> void:
	GameState.skill_points[Skills.COOKING] = 89
	GameState.practise(Skills.COOKING, Skills.DISH)
	assert_array(_risen).is_equal([[Skills.COOKING, 5]])
	for i: int in 20:
		GameState.practise(Skills.COOKING, Skills.DISH)
	assert_int(GameState.skill_level(Skills.COOKING)).is_equal(5)
	assert_array(_risen).has_size(1)


func test_work_costs_less_at_each_level_and_sprinting_costs_the_same() -> void:
	var rules: EnergyRules = GameState.energy_rules()
	for action: String in EnergyRules.COSTS:
		assert_float(GameState.energy_cost(action)).override_failure_message("%s at level 1 is the rules' cost" % action).is_equal(rules.cost(action))
	GameState.skill_points[Skills.COMBAT] = 10
	GameState.skill_points[Skills.FARMING] = 90
	assert_float(GameState.energy_cost(EnergyRules.SWING)).is_equal_approx(0.45, 0.0001)
	assert_float(GameState.energy_cost(EnergyRules.SHOT)).is_equal_approx(0.45, 0.0001)
	assert_float(GameState.energy_cost(EnergyRules.HOE)).is_equal_approx(1.2, 0.0001)
	assert_float(GameState.energy_cost(EnergyRules.WATER)).is_equal_approx(0.6, 0.0001)
	assert_float(GameState.energy_cost(EnergyRules.SPRINT)).override_failure_message("no skill eases sprinting").is_equal(rules.cost(EnergyRules.SPRINT))


func test_a_dish_gives_a_better_cook_more_energy_and_the_same_hearts() -> void:
	assert_float(GameState.food_energy(&"vegetable_stew")).is_equal(60.0)
	GameState.skill_points[Skills.COOKING] = 90
	assert_float(GameState.food_energy(&"vegetable_stew")).override_failure_message("a stew at level 5").is_equal_approx(84.0, 0.0001)
	assert_float(GameState.food_energy(&"roast_turnip")).is_equal_approx(22.0 * 1.4, 0.0001)
	assert_float(GameState.food_energy(&"bread")).override_failure_message("bread is a dish, baked or bought").is_equal_approx(30.0 * 1.4, 0.0001)
	# What isn't cooked gives what it always did.
	assert_float(GameState.food_energy(&"turnip")).is_equal(Food.energy_of(DataRegistry.get_item(&"turnip")))
	assert_float(GameState.food_energy(&"wild_berries")).is_equal(Food.energy_of(DataRegistry.get_item(&"wild_berries")))
	assert_float(GameState.food_energy(&"wooden_sword")).is_equal(0.0)
	# Eaten: the energy is the cook's, the hearts are the dish's.
	GameState.add_item(&"vegetable_stew")
	GameState.set_energy(10.0)
	GameState.damage(4)
	var health: int = GameState.health
	assert_bool(GameState.eat(&"vegetable_stew")).is_true()
	assert_float(GameState.energy).is_equal_approx(94.0, 0.0001)
	assert_int(GameState.health).override_failure_message("one heart, as its data says").is_equal(health + 2)


func test_every_dish_is_something_a_recipe_makes() -> void:
	var recipes: Array = DataRegistry.entries(&"recipes")
	for dish: String in ["blossom_tea", "bread", "roast_turnip", "mushroom_soup", "vegetable_stew", "pumpkin_pie"]:
		assert_bool(Cooking.is_dish(recipes, dish)).override_failure_message(dish).is_true()
	for plain: String in ["turnip", "wild_berries", "mushroom", "wheat", "coin", ""]:
		assert_bool(Cooking.is_dish(recipes, plain)).override_failure_message(plain).is_false()
	assert_bool(Cooking.is_dish([], "bread")).is_false()
	assert_bool(Cooking.is_dish(["bread", {"makes": "bread"}], "bread")).override_failure_message("garbled recipes are passed over").is_false()


func test_tilling_and_picking_are_practice_at_farming() -> void:
	assert_bool(GameState.till_soil(Vector2i(0, 0))).is_true()
	assert_int(GameState.skill_points[Skills.FARMING]).is_equal(1)
	assert_bool(GameState.till_soil(Vector2i(0, 0))).override_failure_message("already tilled").is_false()
	assert_bool(GameState.till_soil(Vector2i(40, 40))).override_failure_message("not a cell of the plot").is_false()
	assert_int(GameState.skill_points[Skills.FARMING]).override_failure_message("a stroke that tills nothing teaches nothing").is_equal(1)
	GameState.plant_crop(Vector2i(0, 0), &"turnip")
	GameState.water_soil(Vector2i(0, 0))
	assert_int(GameState.skill_points[Skills.FARMING]).override_failure_message("planting and watering give no points").is_equal(1)
	assert_dict(GameState.harvest(Vector2i(0, 0))).override_failure_message("not ripe").is_empty()
	assert_int(GameState.skill_points[Skills.FARMING]).is_equal(1)
	for day: int in 3:
		GameState.water_soil(Vector2i(0, 0))
		GameState.start_next_day()
	assert_dict(GameState.harvest(Vector2i(0, 0))).is_not_empty()
	assert_int(GameState.skill_points[Skills.FARMING]).override_failure_message("one for the till, two for the crop").is_equal(3)


func test_the_practise_effect_is_the_deed() -> void:
	var effects: EffectApplier = EffectApplier.new(GameState)
	assert_bool(effects.apply({"type": "practise", "skill": "cooking", "deed": "dish"})).is_true()
	assert_int(GameState.skill_points[Skills.COOKING]).is_equal(2)
	# The hearth's conversation gives it to every dish, after the dish itself.
	var items: Dictionary = {}
	for item: Dictionary in DataRegistry.entries(&"items"):
		items[str(item["id"])] = item
	var hearth: Dictionary = Cooking.dialogue(DataRegistry.entries(&"recipes"), items)
	var cooking: int = 0
	for answer: Dictionary in hearth["nodes"][Cooking.ASK]["options"]:
		var gives: Array = (answer.get("effects", []) as Array).filter(func(effect: Dictionary) -> bool: return effect["type"] == "give_item")
		if gives.is_empty():
			continue
		cooking += 1
		assert_dict((answer["effects"] as Array).back()).override_failure_message(str(answer["text"])).is_equal({"type": "practise", "skill": "cooking", "deed": "dish"})
	assert_int(cooking).override_failure_message("every recipe").is_equal(DataRegistry.entries(&"recipes").size())


func test_skill_points_go_through_a_save() -> void:
	GameState.skill_points[Skills.COMBAT] = 31
	GameState.skill_points[Skills.FARMING] = 12
	GameState.update_player(&"village", Vector2i(23, 20))
	assert_int(SaveSystem.save_to_slot(TEST_SLOT)).is_equal(OK)
	var on_disk: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SaveSystem.slot_path(TEST_SLOT)))
	assert_dict(on_disk["skills"]).is_equal({"combat": 31.0, "farming": 12.0})
	assert_int(int(on_disk["version"])).override_failure_message("no new version: skills have had their place since 4").is_equal(4)
	GameState.clear()
	assert_int(GameState.skill_level(Skills.COMBAT)).override_failure_message("cleared").is_equal(1)
	assert_int(SaveSystem.load_from_slot(TEST_SLOT)).is_equal(OK)
	assert_int(GameState.skill_level(Skills.COMBAT)).is_equal(3)
	assert_int(GameState.skill_level(Skills.FARMING)).is_equal(2)
	assert_int(GameState.skill_level(Skills.COOKING)).is_equal(1)
	assert_array(_risen).override_failure_message("loading says nothing").is_empty()


func test_a_game_saved_before_skills_starts_at_level_one() -> void:
	DirAccess.make_dir_recursive_absolute(SaveSystem.SAVE_DIR)
	var file: FileAccess = FileAccess.open(SaveSystem.slot_path(TEST_SLOT), FileAccess.WRITE)
	file.store_string(FileAccess.get_file_as_string(OLD_SAVE))
	file.close()
	assert_int(SaveSystem.load_from_slot(TEST_SLOT)).is_equal(OK)
	assert_bool(GameState.skill_points.is_empty()).is_true()
	for skill: StringName in GameState.skills().ids():
		assert_int(GameState.skill_level(skill)).is_equal(1)
	assert_float(GameState.energy_cost(EnergyRules.SWING)).is_equal(GameState.energy_rules().cost(EnergyRules.SWING))
	assert_str(GameState.skills().line(GameState.skill_points)).is_equal("Combat 1   Farming 1   Cooking 1")


func _on_skill_rose(skill: StringName, level: int) -> void:
	_risen.append([skill, level])
