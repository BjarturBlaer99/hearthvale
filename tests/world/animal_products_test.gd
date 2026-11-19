extends GdUnitTestSuite
## What the animals give, into the rest of the game (the Homestead, phase 4, step 4c): the egg and
## the milk eaten raw and given as gifts; the three dishes, known from the start, cooked at the
## hearth; Tilda buys the egg, the milk, the wool and the cloth, and cloth is worth more than its
## wool; cloth and the wool blanket woven at the workbench, the blanket lying on the bed; Farming
## rises by tending (D30, R16). And the plan's "done when": a hen bought, fed either way, petted,
## and its eggs cooked, sold and given; the same for a sheep and a cow.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const HOME: String = "res://world/areas/home/home.tscn"
const SHOP: String = "res://world/areas/shop/shop.tscn"
const LAND: StringName = &"homestead"
## The plan's table: each dish's makings, its energy and the hearts it mends (in half hearts).
const DISHES: Dictionary = {
	&"fried_egg": {"name": "Fried Egg", "needs": {"egg": 1}, "energy": 20.0, "halves": 0},
	&"omelette": {"name": "Omelette", "needs": {"egg": 2, "mushroom": 1}, "energy": 50.0, "halves": 1},
	&"custard": {"name": "Custard", "needs": {"egg": 1, "milk": 1}, "energy": 65.0, "halves": 2},
}
## What Tilda pays (the plan's table, and cloth).
const PRICES: Dictionary = {&"egg": 8, &"milk": 30, &"wool": 40, &"cloth": 100}
const COOP_AT: Vector2i = Vector2i(14, 10)
const BARN_AT: Vector2i = Vector2i(4, 7)
const SILO_AT: Vector2i = Vector2i(36, 10)

var _area: Node


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	Quests.refresh()
	GameState.set_time(float(GameState.day_clock().in_day("12:00")))


func after_test() -> void:
	if is_instance_valid(_area):
		_area.free()
	_area = null
	Audio.play_music(&"")
	GameState.clear()


func test_an_egg_and_milk_are_food_and_the_wool_and_cloth_materials() -> void:
	assert_float(Food.energy_of(DataRegistry.get_item(&"egg"))).is_equal(6.0)
	assert_float(Food.energy_of(DataRegistry.get_item(&"milk"))).is_equal(18.0)
	for id: StringName in [&"wool", &"cloth"]:
		assert_str(str(DataRegistry.get_item(id)["type"])).is_equal("material")
	GameState.set_energy(40.0)
	GameState.add_item(&"egg", 1)
	GameState.add_item(&"milk", 1)
	assert_bool(GameState.eat(&"egg")).is_true()
	assert_bool(GameState.eat(&"milk")).is_true()
	assert_float(GameState.energy).is_equal(64.0)
	# Given as a gift like any food.
	GameState.add_item(&"egg", 1)
	assert_dict(GameState.give_gift(&"pip", &"egg")).is_not_empty()
	assert_int(GameState.item_count(&"egg")).is_equal(0)


func test_the_three_dishes_are_known_from_the_start_and_cook_at_the_hearth() -> void:
	var known: Callable = func(id: String) -> bool: return not DataRegistry.get_item(StringName(id)).is_empty()
	var ids: Array = GameState.known_recipes().map(func(recipe: Dictionary) -> String: return str(recipe["id"]))
	for id: StringName in DISHES:
		var dish: Dictionary = DISHES[id]
		var recipe: Dictionary = DataRegistry.get_recipe(id)
		assert_array(Array(Cooking.problems(recipe, known))).is_empty()
		assert_bool(bool(recipe.get("taught", false))).override_failure_message("%s is known from the start" % id).is_false()
		assert_bool(ids.has(String(id))).is_true()
		var needs: Dictionary = {}
		for need: Dictionary in recipe["needs"]:
			needs[str(need["item"])] = int(need["count"])
		assert_dict(needs).is_equal(dish["needs"])
		var item: Dictionary = DataRegistry.get_item(id)
		assert_str(str(item["name"])).is_equal(dish["name"])
		assert_float(Food.energy_of(item)).is_equal(float(dish["energy"]))
		assert_int(Food.halves_of(item)).is_equal(int(dish["halves"]))
	# At the hearth, from their makings.
	var home: AreaController = _load(HOME)
	var hearth: Hearth = home.interactables.get_node(^"Hearth")
	home.player.motor.place(hearth.cell() + Vector2i.DOWN)
	home.player.face(Vector2.UP)
	for id: StringName in DISHES:
		var dish: Dictionary = DISHES[id]
		for need: String in dish["needs"]:
			GameState.add_item(StringName(need), int(dish["needs"][need]))
		assert_bool(home.interact()).is_true()
		assert_bool(_choose_starting(home, str(dish["name"]) + " (")).override_failure_message("the hearth lists %s" % dish["name"]).is_true()
		assert_str(home.hud.dialogue.shown_text()).is_equal(Cooking.COOKED_WORDS % str(dish["name"]).to_lower())
		assert_int(GameState.item_count(id)).is_equal(1)
		for need: String in dish["needs"]:
			assert_int(GameState.item_count(StringName(need))).override_failure_message("the %s is used" % need).is_equal(0)
		_choose_starting(home, Cooking.DONE_WORDS)
		assert_bool(home.is_talking()).is_false()


func test_tilda_buys_the_products_and_cloth_is_worth_more_than_its_wool() -> void:
	var tilda: Dictionary = DataRegistry.get_shop(&"tilda")
	var bought: Dictionary = {}
	for thing: Dictionary in Shop.bought_things(tilda):
		bought[StringName(str(thing["item"]))] = int(thing["price"])
	for id: StringName in PRICES:
		assert_int(int(bought.get(id, 0))).override_failure_message("Tilda pays for %s" % id).is_equal(PRICES[id])
	var cloth: Dictionary = DataRegistry.get_crafting(&"cloth")
	var wool_in_cloth: int = 0
	for need: Dictionary in cloth["needs"]:
		if str(need["item"]) == "wool":
			wool_in_cloth = int(need["count"])
	assert_int(wool_in_cloth).is_equal(2)
	assert_int(PRICES[&"cloth"]).override_failure_message("cloth is worth more than its wool").is_greater(wool_in_cloth * PRICES[&"wool"])
	# At her counter: the four on her list of what she buys, after the crops and the ore.
	for id: StringName in PRICES:
		GameState.add_item(id, 2)
	var shop: AreaController = _load(SHOP)
	assert_bool(shop.open_shop(&"tilda", Shop.SELL)).is_true()
	var counter: ShopMenu = shop.hud.shop_menu
	assert_array(Array(counter.shown_lines())).is_equal(["> Egg x2: 8 coins each", "  Milk x2: 30 coins each", "  Wool x2: 40 coins each", "  Cloth x2: 100 coins each"])
	counter.move_cursor(3)
	assert_bool(counter.confirm()).is_true()
	assert_int(GameState.item_count(GameState.COIN)).is_equal(100)


func test_cloth_and_the_wool_blanket_are_woven_at_the_workbench() -> void:
	var make: Callable = func() -> Array: return Crafting.of_tab(GameState.known_crafts(Crafting.WORKBENCH), Crafting.TAB_MAKE).map(func(recipe: Dictionary) -> String: return str(recipe["id"]))
	assert_bool((make.call() as Array).has("cloth")).override_failure_message("no wool yet").is_false()
	GameState.add_item(&"wool", 4)
	assert_bool((make.call() as Array).has("cloth")).is_true()
	assert_bool((make.call() as Array).has("wool_blanket")).override_failure_message("no cloth yet").is_false()
	assert_str(GameState.craft(&"cloth")).is_empty()
	assert_str(GameState.craft(&"cloth")).is_empty()
	assert_int(GameState.item_count(&"cloth")).is_equal(2)
	assert_int(GameState.item_count(&"wool")).is_equal(0)
	assert_array((make.call() as Array).slice(-2)).is_equal(["cloth", "wool_blanket"])
	assert_str(GameState.craft(&"wool_blanket")).is_empty()
	assert_int(GameState.item_count(&"cloth")).is_equal(0)
	assert_bool(GameState.is_furnished(&"blanket")).is_true()
	assert_str(GameState.craft(&"wool_blanket")).override_failure_message("one blanket").is_not_empty()
	# It lies over the bed, for show: the bed is still the bed.
	var home: AreaController = _load(HOME)
	var blanket: Furnishing = home.interactables.get_node(^"Blanket")
	var bed: Talkable = home.interactables.get_node(^"Bed")
	assert_that(blanket.cell()).is_equal(bed.cell())
	assert_bool(blanket.is_there()).is_true()
	assert_bool(blanket.is_solid()).is_false()
	assert_str(blanket.prompt()).is_empty()
	home.player.motor.place(bed.cell() + Vector2i.RIGHT)
	home.player.face(Vector2.LEFT)
	assert_object(home.talkable_in_front()).override_failure_message("he still goes to bed").is_same(bed)


func test_farming_rises_by_tending() -> void:
	assert_int(GameState.skills().gain(Skills.FARMING, &"tend")).is_equal(1)
	GameState.add_item(GameState.COIN, 999)
	_build(&"coop", COOP_AT)
	_build(&"silo", SILO_AT)
	GameState.homestead().hay = 60
	GameState.buy_animal(&"chicken", 60)
	assert_int(GameState.skill_level(Skills.FARMING)).is_equal(1)
	# Ten eggs taken: a level of Farming.
	for i: int in 10:
		GameState.pet_animal(0)
		GameState.start_next_day()
		assert_bool(GameState.homestead().animal(0)["ready"]).is_true()
		GameState.pet_animal(0)
	assert_int(GameState.item_count(&"egg")).is_equal(10)
	assert_int(GameState.skill_points[Skills.FARMING]).is_equal(10)
	assert_int(GameState.skill_level(Skills.FARMING)).is_equal(2)
	# Petting with nothing to take is no deed.
	GameState.pet_animal(0)
	assert_int(GameState.skill_points[Skills.FARMING]).is_equal(10)


func test_a_hen_a_sheep_and_a_cow_from_the_stall_to_the_kitchen_the_counter_and_a_friend() -> void:
	GameState.add_item(GameState.COIN, 999)
	_build(&"coop", COOP_AT)
	_build(&"barn", BARN_AT)
	_build(&"silo", SILO_AT)
	var wares: Array[Dictionary] = Shop.wares(DataRegistry.get_shop(&"oda"), DataRegistry.entries(&"crops"))
	for ware: Dictionary in wares:
		assert_str(GameState.buy(ware)).is_empty()
	# Fed by hay: the silo gives three, and every one of them is ready on its morning.
	GameState.homestead().hay = 20
	var mornings: Dictionary = {}
	for day: int in range(1, 7):
		for i: int in 3:
			GameState.pet_animal(i)
		GameState.start_next_day()
		for i: int in 3:
			if GameState.homestead().animal(i)["ready"] and not mornings.has(i):
				mornings[i] = day
	# A hen the first morning, a sheep the third, a cow the second.
	assert_array([mornings.get(0, 0), mornings.get(1, 0), mornings.get(2, 0)]).is_equal([1, 3, 2])
	assert_int(GameState.homestead().hay).is_less(20)
	# Fed by pasture too: the coop's pen (the barn's animals still eat hay).
	_fence_coop()
	var hay_before: int = GameState.homestead().hay
	GameState.start_next_day()
	assert_int(GameState.homestead().hay).override_failure_message("the hen grazes, the sheep and the cow eat hay").is_equal(hay_before - 2)
	# Taken, the products go to the kitchen, the counter and a friend.
	for i: int in 3:
		GameState.pet_animal(i)
	for id: StringName in [&"egg", &"wool", &"milk"]:
		assert_int(GameState.item_count(id)).override_failure_message(id).is_greater_equal(1)
	GameState.add_item(&"egg", 3)
	GameState.add_item(&"milk", 1)
	GameState.add_item(&"wool", 1)
	assert_str(GameState.craft(&"cloth")).is_empty()
	var coins: int = GameState.item_count(GameState.COIN)
	for offer: Dictionary in Shop.offers(DataRegistry.get_shop(&"tilda"), DataRegistry.entries(&"crops"), GameState.inventory):
		if offer["item"] in ["egg", "milk", "cloth"]:
			assert_str(GameState.sell(offer)).is_empty()
	assert_int(GameState.item_count(GameState.COIN)).is_equal(coins + 8 + 30 + 100)
	assert_dict(GameState.give_gift(&"wenna", &"egg")).is_not_empty()
	# (The eggs and the milk cooked at the hearth: test_the_three_dishes_are_known_from_the_start_and_cook_at_the_hearth.)


# --- Helpers -------------------------------------------------------------------------------

func _build(id: StringName, at: Vector2i) -> void:
	for cell: Vector2i in Buildings.cells_and_doorstep(DataRegistry.get_building(id), at):
		GameState.clear_debris(LAND, cell)
	var kit: StringName = Buildings.kit_for(id, DataRegistry.entries(&"items"))
	GameState.add_item(kit)
	assert_bool(GameState.set_down_kit(LAND, at, kit)).is_true()
	GameState.start_next_day()


## Fences the ground before the coop's door: (13..18, 13..15).
func _fence_coop() -> void:
	var pen: Rect2i = Rect2i(13, 13, 6, 3)
	var ring: Rect2i = pen.grow(1)
	for y: int in range(ring.position.y - 1, ring.end.y):
		for x: int in range(ring.position.x, ring.end.x):
			GameState.clear_debris(LAND, Vector2i(x, y))
	for x: int in range(ring.position.x, ring.end.x):
		for y: int in range(ring.position.y, ring.end.y):
			var cell: Vector2i = Vector2i(x, y)
			if not pen.has_point(cell) and GameState.building_covering(LAND, cell) == &"":
				GameState.homestead().set_down(cell, Placement.STANDING, &"fence")


func _choose_starting(area: AreaController, words: String) -> bool:
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
