extends GdUnitTestSuite
## Meals from crops (P3c, GDD §6): five recipes as data, which the hearth at home lists and
## cooks, each dish giving what the GDD says; and a conversation with many answers (the hearth's
## six dishes) scrolls to keep the cursor in view.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const HOME: String = "res://world/areas/home/home.tscn"
const SHOP: String = "res://world/areas/shop/shop.tscn"
const VILLAGE: String = "res://world/areas/village/village.tscn"
## GDD §6: each meal's makings, the energy it gives and the hearts it mends (in half hearts).
const MEALS: Dictionary = {
	&"roast_turnip": {"dish": &"roast_turnip", "needs": {"turnip": 1}, "energy": 22.0, "halves": 0},
	&"mushroom_soup": {"dish": &"mushroom_soup", "needs": {"mushroom": 2, "potato": 1}, "energy": 35.0, "halves": 1},
	&"vegetable_stew": {"dish": &"vegetable_stew", "needs": {"potato": 1, "carrot": 1, "turnip": 1}, "energy": 60.0, "halves": 2},
	&"pumpkin_pie": {"dish": &"pumpkin_pie", "needs": {"pumpkin": 1, "wheat": 1}, "energy": 80.0, "halves": 4},
	&"bread": {"dish": &"bread", "needs": {"wheat": 2}, "energy": 30.0, "halves": 0},
}

var _area: Node


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	GameState.set_time(float(GameState.day_clock().in_day("12:00")))


func after_test() -> void:
	if is_instance_valid(_area):
		_area.free()
	_area = null
	Audio.play_music(&"")
	GameState.clear()


func test_the_five_meals_are_recipes_that_give_what_the_gdd_says() -> void:
	var known: Callable = func(id: String) -> bool: return not DataRegistry.get_item(StringName(id)).is_empty()
	for id: StringName in MEALS:
		var meal: Dictionary = MEALS[id]
		var recipe: Dictionary = DataRegistry.get_recipe(id)
		assert_array(Array(Cooking.problems(recipe, known))).override_failure_message(String(id)).is_empty()
		assert_str(str(recipe["makes"]["item"])).is_equal(String(meal["dish"]))
		assert_int(int(recipe["makes"].get("count", 1))).is_equal(1)
		var needs: Dictionary = {}
		var raw: float = 0.0
		for need: Dictionary in recipe["needs"]:
			needs[str(need["item"])] = int(need["count"])
			raw += Food.energy_of(DataRegistry.get_item(StringName(str(need["item"])))) * int(need["count"])
		assert_dict(needs).override_failure_message("%s's makings" % id).is_equal(meal["needs"])
		var dish: Dictionary = DataRegistry.get_item(meal["dish"])
		assert_bool(Food.is_food(dish)).is_true()
		assert_array(Array(Food.problems(dish))).is_empty()
		assert_float(Food.energy_of(dish)).override_failure_message("%s's energy" % id).is_equal(float(meal["energy"]))
		assert_int(Food.halves_of(dish)).override_failure_message("%s's hearts" % id).is_equal(int(meal["halves"]))
		assert_float(Food.energy_of(dish)).override_failure_message("%s is worth more cooked than its makings raw (%s)" % [id, raw]).is_greater(raw)
		assert_bool(ItemIcons.FRAMES.has(ItemIcons.name_for(meal["dish"])) and ItemIcons.name_for(meal["dish"]) != &"gem").override_failure_message("%s has a picture of its own" % meal["dish"]).is_true()
	assert_array(DataRegistry.ids(&"recipes").map(func(id: StringName) -> String: return String(id))).is_equal(["blossom_tea", "bread", "mushroom_soup", "pumpkin_pie", "roast_turnip", "vegetable_stew"])
	assert_str(Food.gives_text(DataRegistry.get_item(&"vegetable_stew"))).is_equal("+60 energy, +1 heart")
	assert_str(Food.gives_text(DataRegistry.get_item(&"mushroom_soup"))).is_equal("+35 energy, +half a heart")
	assert_str(Food.gives_text(DataRegistry.get_item(&"pumpkin_pie"))).is_equal("+80 energy, +2 hearts")


func test_the_hearth_cooks_every_meal_from_its_makings() -> void:
	var home: AreaController = _load(HOME)
	var hearth: Hearth = home.interactables.get_node(^"Hearth")
	home.player.motor.place(hearth.cell() + Vector2i.DOWN)
	home.player.face(Vector2.UP)
	for id: StringName in MEALS:
		var meal: Dictionary = MEALS[id]
		var had: int = GameState.item_count(meal["dish"])
		for need: String in meal["needs"]:
			GameState.add_item(StringName(need), int(meal["needs"][need]))
		assert_bool(home.interact()).is_true()
		var dish_name: String = str(DataRegistry.get_item(meal["dish"])["name"])
		assert_bool(_say_starting(home, dish_name + " (")).override_failure_message("the hearth lists %s" % dish_name).is_true()
		assert_str(home.hud.dialogue.shown_text()).is_equal(Cooking.COOKED_WORDS % dish_name.to_lower())
		assert_int(GameState.item_count(meal["dish"])).override_failure_message("one %s" % dish_name).is_equal(had + 1)
		for need: String in meal["needs"]:
			assert_int(GameState.item_count(StringName(need))).override_failure_message("%s's %s is used up" % [dish_name, need]).is_equal(0)
		_say_starting(home, Cooking.DONE_WORDS)
		assert_bool(home.is_talking()).is_false()
	# Without the makings the hearth says so, and nothing is made.
	GameState.add_item(&"potato", 1)
	GameState.add_item(&"carrot", 1)
	assert_bool(home.interact()).is_true()
	_say_starting(home, "Vegetable Stew (")
	assert_str(home.hud.dialogue.shown_text()).override_failure_message("a stew wants a turnip too").is_equal(Cooking.LACKING_WORDS)
	assert_int(GameState.item_count(&"vegetable_stew")).is_equal(1)
	assert_int(GameState.item_count(&"potato")).is_equal(1)


func test_meals_mend_hearts_as_well_as_giving_energy() -> void:
	for dish: StringName in [&"mushroom_soup", &"vegetable_stew", &"pumpkin_pie", &"roast_turnip"]:
		GameState.add_item(dish, 1)
	GameState.damage(5)
	assert_int(GameState.health).override_failure_message("half a heart left of three").is_equal(1)
	GameState.set_energy(0.0)
	assert_bool(GameState.eat(&"mushroom_soup")).is_true()
	assert_int(GameState.health).override_failure_message("soup: half a heart").is_equal(2)
	assert_float(GameState.energy).is_equal(35.0)
	assert_bool(GameState.eat(&"vegetable_stew")).is_true()
	assert_int(GameState.health).override_failure_message("stew: one heart").is_equal(4)
	assert_float(GameState.energy).is_equal(95.0)
	assert_bool(GameState.eat(&"pumpkin_pie")).is_true()
	assert_int(GameState.health).override_failure_message("pie: two hearts, and never more than he has room for").is_equal(6)
	assert_float(GameState.energy).override_failure_message("nor more than a full bar").is_equal(100.0)
	assert_bool(GameState.eat(&"roast_turnip")).override_failure_message("full and whole, he isn't hungry").is_false()
	assert_int(GameState.item_count(&"roast_turnip")).is_equal(1)


func test_a_long_list_of_answers_scrolls_to_keep_the_cursor_in_view() -> void:
	var home: AreaController = _load(HOME)
	var hearth: Hearth = home.interactables.get_node(^"Hearth")
	home.player.motor.place(hearth.cell() + Vector2i.DOWN)
	home.player.face(Vector2.UP)
	assert_bool(home.interact()).is_true()
	var box: DialogueBox = home.hud.dialogue
	var all: PackedStringArray = box.shown_options()
	assert_int(all.size()).override_failure_message("six dishes and the way out").is_equal(7)
	assert_int(DialogueBox.OPTION_ROWS).is_equal(4)
	assert_array(Array(box.shown_option_lines())).is_equal(["> " + all[0], "  " + all[1], "  " + all[2], "  " + all[3]])
	assert_str(box.corner_text()).is_equal("  1/7 v")
	for i: int in range(1, all.size()):
		box.move_cursor(1)
		assert_int(box.shown_option_lines().size()).override_failure_message("four lines, never more").is_equal(DialogueBox.OPTION_ROWS)
		assert_bool(Array(box.shown_option_lines()).has("> " + all[i])).override_failure_message("the cursor on '%s' is in view" % all[i]).is_true()
	assert_str(box.corner_text()).is_equal("^ 7/7  ")
	assert_str(box.shown_option_lines()[3]).is_equal("> " + Cooking.LEAVE_WORDS)
	box.move_cursor(1)
	assert_str(box.shown_option_lines()[0]).override_failure_message("past the end it wraps to the top").is_equal("> " + all[0])
	box.move_cursor(-3)
	assert_str(box.corner_text()).is_equal("^ 5/7 v")
	# The next words start from the top again.
	box.confirm()
	assert_int(box.top).is_equal(0)
	assert_int(box.selected).is_equal(0)
	_say_starting(home, Cooking.DONE_WORDS)
	# A short list shows whole, with nothing in the corner; words with no answers say how to read on.
	var shop: AreaController = _load(SHOP)
	Steps.stand_before(shop, "Tilda")
	assert_bool(shop.interact()).is_true()
	assert_int(shop.hud.dialogue.shown_option_lines().size()).is_equal(3)
	assert_str(shop.hud.dialogue.corner_text()).is_equal("")
	var village: AreaController = _load(VILLAGE)
	village.player.motor.place(Vector2i(26, 19))
	village.player.face(Vector2.UP)
	assert_bool(village.interact()).override_failure_message("the sign in the square").is_true()
	assert_array(Array(village.hud.dialogue.shown_option_lines())).is_empty()
	assert_str(village.hud.dialogue.corner_text()).is_equal("[Left click]")


## Picks the answer that starts with `words`. Returns whether there was one.
func _say_starting(area: AreaController, words: String) -> bool:
	var box: DialogueBox = area.hud.dialogue
	var options: PackedStringArray = box.shown_options()
	for i: int in options.size():
		if options[i].begins_with(words):
			box.move_cursor(i - box.selected)
			box.confirm()
			return true
	return false


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area
