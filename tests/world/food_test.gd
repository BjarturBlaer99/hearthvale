extends GdUnitTestSuite
## Food in the world (P2d): eating from the item menu; berries, mushrooms and blossom to gather,
## back each morning; bread at Tilda's; and cooking at the hearth at home.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")
const DataRegistryScript: GDScript = preload("res://autoload/data_registry.gd")

const VILLAGE: String = "res://world/areas/village/village.tscn"
const HOME: String = "res://world/areas/home/home.tscn"
const SHOP: String = "res://world/areas/shop/shop.tscn"
const ELDER_HOUSE: String = "res://world/areas/elder_house/elder_house.tscn"
## Where there is something to gather: area -> how many spots.
const SPOTS: Dictionary = {&"village": 3, &"north_fields": 2, &"south_field": 1, &"old_wood": 4}

var _area: Node


func before_test() -> void:
	GameState.clear()
	GameState.new_game()


func after_test() -> void:
	if is_instance_valid(_area):
		_area.free()
	_area = null
	GameState.clear()


func test_food_and_recipes_are_data() -> void:
	for id: StringName in [&"wild_berries", &"mushroom", &"bread", &"blossom_tea"]:
		var item: Dictionary = DataRegistry.get_item(id)
		assert_bool(Food.is_food(item)).override_failure_message("%s is food" % id).is_true()
		assert_array(Array(Food.problems(item))).is_empty()
		assert_bool(ItemIcons.FRAMES.has(ItemIcons.name_for(id)) and ItemIcons.name_for(id) != &"gem").override_failure_message("%s has a picture of its own" % id).is_true()
	assert_float(Food.energy_of(DataRegistry.get_item(&"wild_berries"))).is_equal(8.0)
	assert_float(Food.energy_of(DataRegistry.get_item(&"mushroom"))).is_equal(6.0)
	assert_float(Food.energy_of(DataRegistry.get_item(&"bread"))).is_equal(30.0)
	assert_float(Food.energy_of(DataRegistry.get_item(&"blossom_tea"))).is_equal(15.0)
	assert_str(str(DataRegistry.get_item(&"cherry_blossom")["type"])).override_failure_message("blossom is only cooked with").is_equal("ingredient")
	var tea: Dictionary = DataRegistry.get_recipe(&"blossom_tea")
	assert_str(str(tea["makes"]["item"])).is_equal("blossom_tea")
	assert_that(tea["needs"]).is_equal([{"item": "cherry_blossom", "count": 3.0}])
	var registry: Node = auto_free(DataRegistryScript.new())
	var errors: String = "\n".join(registry.load_all("res://tests/fixtures/bad_food"))
	assert_str(errors).contains("item 'stone_soup': food must give some 'energy' or some 'hearts'.")
	assert_str(errors).contains("recipe 'nectar': 'makes' names an unknown item id 'nectar'.")
	assert_str(errors).contains("recipe 'nectar': 'needs' names an unknown item id 'dew'.")


func test_eating_from_the_item_menu_gives_energy_and_uses_the_food() -> void:
	GameState.add_item(&"bow")
	GameState.add_item(&"arrow", 5)
	GameState.add_item(&"bread", 2)
	GameState.add_item(&"cherry_blossom", 3)
	GameState.add_item(&"wild_berries", 3)
	GameState.set_energy(40.0)
	var village: AreaController = _load(VILLAGE)
	assert_bool(village.open_item_menu()).is_true()
	var menu: ItemMenu = village.hud.item_menu
	assert_array(Array(menu.shown_lines())).override_failure_message("the bow, then the food; an ingredient isn't listed").is_equal(["> Bow (Arrows x5)", "  Bread x2 (+30 energy)", "  Wild Berries x3 (+8 energy)"])
	menu.move_cursor(1)
	menu.confirm()
	assert_float(GameState.energy).is_equal(70.0)
	assert_int(GameState.item_count(&"bread")).is_equal(1)
	assert_that(GameState.equipped).override_failure_message("eating doesn't change what is on the item button").is_equal(&"bow")
	assert_str(village.hud.message_text()).is_equal("Bread: +30 energy.")
	assert_float(village.hud.energy.fraction()).override_failure_message("the bar goes up").is_equal_approx(0.7, 0.001)
	assert_bool(menu.is_open()).is_false()
	assert_bool(village.player.controls_enabled).is_true()
	# A second loaf takes him to full and no further.
	assert_bool(GameState.eat(&"bread")).is_true()
	assert_float(GameState.energy).is_equal(GameState.max_energy())
	assert_int(GameState.item_count(&"bread")).is_equal(0)
	# Full, he isn't hungry: nothing is used.
	assert_bool(village.open_item_menu()).is_true()
	menu.move_cursor(1)
	menu.confirm()
	assert_int(GameState.item_count(&"wild_berries")).override_failure_message("not wasted").is_equal(3)
	assert_str(village.hud.message_text()).is_equal(AreaController.NOT_HUNGRY_WORDS)
	assert_bool(GameState.eat(&"cherry_blossom")).override_failure_message("an ingredient can't be eaten").is_false()
	assert_bool(GameState.eat(&"bread")).override_failure_message("nor can what he hasn't got").is_false()
	assert_int(GameState.health).override_failure_message("these mend no hearts").is_equal(GameState.max_health())


func test_food_alone_opens_the_item_menu() -> void:
	var village: AreaController = _load(VILLAGE)
	assert_bool(village.open_item_menu()).override_failure_message("nothing to show").is_false()
	GameState.add_item(&"cherry_blossom", 2)
	assert_bool(village.open_item_menu()).override_failure_message("an ingredient alone is nothing to show").is_false()
	GameState.add_item(&"mushroom", 1)
	assert_bool(village.open_item_menu()).is_true()
	assert_array(Array(village.hud.item_menu.shown_lines())).is_equal(["> Mushrooms x1 (+6 energy)"])


func test_there_are_things_to_gather_and_each_is_back_the_next_morning() -> void:
	var total: int = 0
	for area_id: StringName in SPOTS:
		var area: AreaController = _load(WorldPaths.scene_for(area_id))
		var spots: Array[ForageSpot] = []
		for child: Node in area.interactables.get_children():
			if child is ForageSpot:
				spots.append(child as ForageSpot)
		assert_int(spots.size()).override_failure_message("%s: places to gather" % area_id).is_equal(int(SPOTS[area_id]))
		var reachable: Dictionary = _reachable(area)
		var flags: Dictionary = {}
		for spot: ForageSpot in spots:
			var where: String = "%s/%s" % [area_id, spot.name]
			total += 1
			assert_bool(area.grid.is_solid(spot.cell())).override_failure_message(where + " lies on open ground").is_false()
			assert_bool(area.terrain.is_occupied(spot.cell())).override_failure_message(where + " blocks nothing").is_false()
			assert_bool(reachable.has(spot.cell())).override_failure_message(where + " can be walked to").is_true()
			assert_bool(DataRegistry.has_entry(&"items", spot.item_id)).override_failure_message(where + " gives a real item").is_true()
			assert_bool(ForageSpot.FRAMES.has(spot.kind) and ForageSpot.FRAMES.has(StringName(String(spot.kind) + "_picked"))).override_failure_message(where + " has its pictures").is_true()
			assert_str(String(spot.taken_flag)).override_failure_message(where + " remembers by its own flag").is_equal("forage/%s/%s" % [area_id, spot.name])
			assert_array(area.scenery.hiding(GridBody.cell_center(spot.cell()))).override_failure_message(where + " isn't under a tree's crown, which would stay faded for it").is_empty()
			flags[spot.taken_flag] = true
			for other: Node in area.interactables.get_children():
				if other != spot and other.has_method(&"covers") and not other is Enemy:
					assert_bool(other.call(&"covers", spot.cell())).override_failure_message("%s shares its cell with %s" % [where, other.name]).is_false()
		assert_int(flags.size()).override_failure_message("%s: each spot its own flag" % area_id).is_equal(spots.size())
	assert_int(total).is_equal(10)
	# Gathering one: stand on it and press interact, as for any item.
	var wood: AreaController = _load(WorldPaths.scene_for(&"old_wood"))
	var mushrooms: ForageSpot = wood.interactables.get_node(^"MushroomsA")
	assert_that(mushrooms.frame()).is_equal(&"mushrooms")
	wood.player.motor.place(mushrooms.cell())
	wood._update_hud()
	assert_str(wood.hud.get_node(^"Prompt").text).is_equal("[Right click] Pick up the Mushrooms")
	assert_bool(wood.interact()).is_true()
	assert_int(GameState.item_count(&"mushroom")).is_equal(mushrooms.count)
	assert_bool(mushrooms.taken()).is_true()
	assert_that(mushrooms.frame()).override_failure_message("it shows as gathered").is_equal(&"mushrooms_picked")
	assert_bool(wood.interact()).override_failure_message("nothing more today").is_false()
	assert_int(GameState.item_count(&"mushroom")).is_equal(mushrooms.count)
	# It is remembered across a save, and back the next morning.
	var saved: Dictionary = JSON.parse_string(JSON.stringify(GameState.to_dict()))
	GameState.from_dict(saved)
	wood = _load(WorldPaths.scene_for(&"old_wood"))
	mushrooms = wood.interactables.get_node(^"MushroomsA")
	assert_bool(mushrooms.taken()).override_failure_message("still gathered after loading").is_true()
	GameState.start_next_day()
	assert_bool(mushrooms.taken()).override_failure_message("grown back").is_false()
	assert_that(mushrooms.frame()).is_equal(&"mushrooms")
	wood.player.motor.place(mushrooms.cell())
	assert_bool(wood.interact()).is_true()
	assert_int(GameState.item_count(&"mushroom")).is_equal(mushrooms.count * 2)


func test_tilda_sells_bread() -> void:
	# Her wares are a list since P3c (tests/world/shop_test.gd): bread is its third line.
	GameState.add_item(&"coin", 13)
	var shop: AreaController = _load(SHOP)
	assert_bool(shop.open_shop(&"tilda", Shop.BUY)).is_true()
	var counter: ShopMenu = shop.hud.shop_menu
	assert_str(counter.shown_lines()[2]).is_equal("  Bread: 6 coins")
	counter.move_cursor(2)
	assert_bool(counter.confirm()).is_true()
	assert_int(GameState.item_count(&"bread")).is_equal(1)
	assert_int(GameState.item_count(&"coin")).is_equal(7)
	assert_bool(counter.confirm()).is_true()
	assert_int(GameState.item_count(&"bread")).is_equal(2)
	assert_bool(counter.confirm()).override_failure_message("one coin buys no bread").is_false()
	assert_str(counter.note_text()).is_equal(Shop.NO_COINS)
	assert_int(GameState.item_count(&"bread")).is_equal(2)
	assert_int(GameState.item_count(&"coin")).is_equal(1)


func test_the_hearth_at_home_cooks_from_the_recipes() -> void:
	var home: AreaController = _load(HOME)
	var hearth: Hearth = home.interactables.get_node(^"Hearth")
	assert_that((home.get_node(^"Height") as TileMapLayer).get_cell_atlas_coords(hearth.cell())).override_failure_message("the hearth's node is on the hearth").is_equal(GreyboxTiles.coords("hearth"))
	assert_str(hearth.prompt()).is_equal("Cook")
	home.player.motor.place(hearth.cell() + Vector2i.DOWN)
	home.player.face(Vector2.UP)
	assert_object(home.talkable_in_front()).is_same(hearth)
	GameState.add_item(&"cherry_blossom", 4)
	var minute: float = GameState.minute
	assert_bool(home.interact()).is_true()
	assert_bool(home.is_talking()).is_true()
	assert_str(home.hud.dialogue.shown_text()).is_equal(Cooking.ASK_WORDS)
	assert_array(Array(home.hud.dialogue.shown_options())).override_failure_message("every recipe in data, then the way out").is_equal([
		"Cherry Blossom Tea (3 Cherry Blossoms)", "Bread (2 Wheat)", "Mushroom Soup (2 Mushrooms, 1 Potato)",
		"Pumpkin Pie (1 Pumpkin, 1 Wheat)", "Roast Turnip (1 Turnip)", "Vegetable Stew (1 Potato, 1 Carrot, 1 Turnip)", Cooking.LEAVE_WORDS])
	assert_int(GameState.known_recipes().size()).override_failure_message("tea, and the five meals of P3c (tests/world/meals_test.gd): what he knows from the start").is_equal(6)
	home._process(2.0)
	assert_float(GameState.minute).override_failure_message("the clock stands still while he cooks").is_equal(minute)
	_say(home, "Cherry Blossom Tea (3 Cherry Blossoms)")
	assert_int(GameState.item_count(&"blossom_tea")).is_equal(1)
	assert_int(GameState.item_count(&"cherry_blossom")).is_equal(1)
	assert_str(home.hud.dialogue.shown_text()).is_equal("You make cherry blossom tea.")
	_say(home, Cooking.MORE_WORDS)
	_say(home, "Cherry Blossom Tea (3 Cherry Blossoms)")
	assert_str(home.hud.dialogue.shown_text()).override_failure_message("one blossom isn't three").is_equal(Cooking.LACKING_WORDS)
	assert_int(GameState.item_count(&"blossom_tea")).is_equal(1)
	_say(home, Cooking.DONE_WORDS)
	assert_bool(home.is_talking()).is_false()
	# The tea can then be drunk.
	GameState.set_energy(50.0)
	assert_bool(GameState.eat(&"blossom_tea")).is_true()
	assert_float(GameState.energy).is_equal(65.0)
	# Only the hero's own hearth is for cooking.
	var elder: AreaController = _load(ELDER_HOUSE)
	for child: Node in elder.interactables.get_children():
		assert_bool(child is Hearth).override_failure_message("Elder Bram's hearth is his own").is_false()


func _talk(area: AreaController, who: String) -> void:
	Steps.stand_before(area, who)
	assert_bool(area.interact()).override_failure_message("talking to %s" % who).is_true()


## Picks the answer that reads `words`.
func _say(area: AreaController, words: String) -> void:
	var box: DialogueBox = area.hud.dialogue
	var options: PackedStringArray = box.shown_options()
	var index: int = options.find(words)
	assert_int(index).override_failure_message("'%s' isn't among %s" % [words, options]).is_greater_equal(0)
	if index < 0:
		return
	box.move_cursor(index - box.selected)
	box.confirm()


func _reachable(area: AreaController) -> Dictionary:
	var query: TerrainQuery = TerrainQuery.new(area.grid)
	var start: Vector2i = area.player.motor.cell
	var seen: Dictionary = {start: true}
	var queue: Array[Vector2i] = [start]
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		for step: Vector2i in [Vector2i.LEFT, Vector2i.RIGHT, Vector2i.UP, Vector2i.DOWN]:
			var next: Vector2i = cell + step
			if not seen.has(next) and query.check_move(cell, next).is_allowed():
				seen[next] = true
				queue.append(next)
	return seen


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area
