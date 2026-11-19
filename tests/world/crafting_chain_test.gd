extends GdUnitTestSuite
## Crafting from end to end (phase 2's "done when"): everything on the workbench's list is made,
## in the cottage, from what the mine and the fields give, the ore going through the furnace a
## night at a time; and the furnace, the chest and a sprinkler go on with their work through a
## save and the mornings after it.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const HOME: String = "res://world/areas/home/home.tscn"
const TEST_SLOT: int = 958
## The furnace's answers, in their order.
const COPPER: int = 0
const IRON: int = 1
const GOLD: int = 2

var _area: Node
var _made: Array[String] = []


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	Quests.refresh()
	_made.clear()
	EventBus.crafted.connect(_on_crafted)


func after_test() -> void:
	EventBus.crafted.disconnect(_on_crafted)
	if is_instance_valid(_area):
		_area.free()
	_area = null
	GameState.clear()
	SaveSystem.current_slot = SaveSystem.GAME_SLOT
	SaveSystem.erase_slot(TEST_SLOT)


func test_everything_on_the_list_is_made_from_what_the_mine_and_the_fields_give() -> void:
	# A few days' work, and nothing more than it takes. From the mine: stone and copper ore (the
	# top floors), iron ore and coal (the middle floors), three gold ore and a crystal (the
	# deep). From the fields: wood, wheat off the plot, blossom from under the cherry trees. The
	# hoe and the can lie at home, the Pickaxe is Tilda's, the Lantern is the crypt's.
	for item: Array in [[&"hoe", 1], [&"watering_can", 1], [&"pickaxe", 1], [&"lantern", 1], [&"stone", 23], [&"copper_ore", 30],
			[&"coal", 21], [&"iron_ore", 24], [&"gold_ore", 3], [&"crystal", 1], [&"wood", 12], [&"wheat", 8], [&"cherry_blossom", 3]]:
		assert_int(GameState.add_item(item[0], item[1])).override_failure_message("%s fits in the pack" % item[0]).is_equal(item[1])
	# The skills come from the work itself: twenty-five rocks of ore, ten cells tilled.
	for rock: int in 25:
		GameState.practise(Skills.MINING, &"ore")
	for cell: int in 10:
		GameState.practise(Skills.FARMING, &"till")
	assert_int(GameState.skill_level(Skills.MINING)).is_equal(3)
	assert_int(GameState.skill_level(Skills.FARMING)).is_equal(2)
	var home: AreaController = _load(HOME)
	var all: Array = _ids(Crafting.of_tab(Crafting.of_station(DataRegistry.entries(&"crafting"), Crafting.WORKBENCH), Crafting.TAB_MAKE))
	assert_int(all.size()).is_equal(13)

	# Day 1. Stone and ore make the furnace; nothing of metal can be made before it has burned.
	_make(home, "furnace")
	_make(home, "bombs")
	_make(home, "rug")
	assert_bool(_listed(home, "chest")).override_failure_message("wood is found: the chest is on the list").is_true()
	assert_bool(_can_make(home, "chest")).override_failure_message("but it wants a bar").is_false()
	for metal: String in ["copper_hoe", "copper_watering_can", "lamp", "iron_hoe", "iron_watering_can"]:
		assert_bool(_listed(home, metal)).override_failure_message("%s waits on a first bar" % metal).is_false()
	_smelt(home, COPPER, 5)
	assert_int(GameState.item_count(&"copper_bar")).override_failure_message("not until morning").is_equal(0)

	# Day 2. Five copper bars: the chest, the lamp, the copper hoe. Five more ore, and five more bars.
	_take_out(home, &"copper_bar", 5)
	_make(home, "chest")
	_make(home, "lamp")
	_make(home, "copper_hoe")
	assert_int(GameState.item_count(&"hoe")).is_equal(0)
	GameState.add_item(&"copper_ore", 5)
	_smelt(home, COPPER, 5)

	# Day 3. The copper can and the copper pickaxe; the furnace turns to iron.
	_take_out(home, &"copper_bar", 5)
	_make(home, "copper_watering_can")
	_make(home, "copper_pickaxe")
	assert_int(GameState.item_count(&"copper_bar")).override_failure_message("one kept for the sprinkler").is_equal(1)
	assert_bool(_listed(home, "iron_hoe")).override_failure_message("no iron bar yet").is_false()
	_smelt(home, IRON, 5)

	# Day 4. The sprinkler, the iron hoe and the iron can. What ore is left makes three bars.
	_take_out(home, &"iron_bar", 5)
	_make(home, "sprinkler")
	_make(home, "iron_hoe")
	_make(home, "iron_watering_can")
	assert_bool(_can_make(home, "iron_pickaxe")).override_failure_message("three bars short").is_false()
	_smelt(home, IRON, 3)

	# Day 5. The iron pickaxe; and the gold goes in.
	_take_out(home, &"iron_bar", 3)
	_make(home, "iron_pickaxe")
	_smelt(home, GOLD, 1)

	# Day 6. The Miner's Lantern is the last thing on the list.
	_take_out(home, &"gold_bar", 1)
	_make(home, "miners_lantern")
	assert_int(GameState.day).is_equal(6)

	# Everything on the workbench's list has been made, each once.
	var made: Array = _made.duplicate()
	made.sort()
	all.sort()
	assert_array(made).is_equal(all)
	for furnishing: String in GameState.crafting_rules()["furnishings"]:
		assert_bool(GameState.is_furnished(StringName(furnishing))).override_failure_message(furnishing).is_true()
		assert_bool((home.interactables.get_node(NodePath(furnishing.capitalize())) as Furnishing).is_there()).override_failure_message("%s stands in the cottage" % furnishing).is_true()
	# What he holds at the end: the best of each tool, and the things made to be used.
	for held: Array in [[&"iron_hoe", 1], [&"iron_watering_can", 1], [&"iron_pickaxe", 1], [&"sprinkler", 1], [&"miners_lantern", 1], [&"bomb", 3]]:
		assert_int(GameState.item_count(held[0])).override_failure_message(String(held[0])).is_equal(held[1])
	# And nothing is left over: every stone, ore, coal, bar and plank went into something, and
	# every tool before the last was used up in the next.
	for spent: StringName in [&"stone", &"copper_ore", &"coal", &"iron_ore", &"gold_ore", &"crystal", &"wood", &"wheat", &"cherry_blossom",
			&"copper_bar", &"iron_bar", &"gold_bar", &"hoe", &"watering_can", &"pickaxe", &"lantern", &"copper_hoe",
			&"copper_watering_can", &"copper_pickaxe"]:
		assert_int(GameState.item_count(spent)).override_failure_message("no %s left" % spent).is_equal(0)
	# The whole list is still known, and there is nothing left to make any of it with.
	var menu: CraftMenu = home.hud.craft_menu
	home.open_craft()
	assert_int(menu.entries().size()).is_equal(13)
	for index: int in 13:
		assert_bool(menu.can_make(index)).override_failure_message(str(menu.entries()[index]["id"])).is_false()
	assert_bool(GameState.furnace().is_empty()).is_true()


func test_all_that_the_list_is_made_of_comes_from_the_mine_the_fields_or_the_bench() -> void:
	# What the world gives, read from its data: what a rock leaves, what cut wood and grass
	# leave, what a crop gives, what Tilda sells...
	var given: Dictionary = {}
	for rock: Dictionary in (DataRegistry.get_rules(DataRegistry.RULES_MINE)["rocks"] as Dictionary).values():
		given[str(rock["gives"])] = "a rock of the quarry"
	for breakable: Dictionary in DataRegistry.entries(&"breakables"):
		for drop: Dictionary in breakable.get("drops", []):
			if str(drop.get("type", "")) == "item":
				given[str(drop["item"])] = "cut or broken: %s" % breakable["id"]
	for crop: Dictionary in DataRegistry.entries(&"crops"):
		given[str(crop["gives"]["item"])] = "the plot"
	for ware: Dictionary in DataRegistry.get_shop(&"tilda")["sells"]:
		given[str(ware["item"])] = "Tilda's shop"
	# ...and what lies in the world for the taking: the hoe and the can at home (looked for
	# here), blossom under the cherry trees, and the Lantern in the crypt's chest.
	var home: AreaController = _load(HOME)
	for child: Node in home.interactables.get_children():
		if child is ItemPickup:
			given[String((child as ItemPickup).item_id)] = "lying at home"
	for lying: String in ["cherry_blossom", "lantern"]:
		given[lying] = "lying in the world"
	for raw: String in ["stone", "copper_ore", "coal", "iron_ore", "gold_ore", "crystal", "wood", "wheat", "hoe", "watering_can", "pickaxe"]:
		assert_bool(given.has(raw)).override_failure_message("%s is given by the world" % raw).is_true()
	# What the bench and the furnace make.
	var made: Dictionary = {}
	for recipe: Dictionary in DataRegistry.entries(&"crafting"):
		if not Crafting.item_made(recipe).is_empty():
			made[Crafting.item_made(recipe)] = str(recipe["id"])
	# Every need of every recipe is one or the other, and no recipe needs the thing it makes.
	for recipe: Dictionary in DataRegistry.entries(&"crafting"):
		for need: Dictionary in Crafting.needs_of(recipe):
			var item: String = str(need["item"])
			assert_bool(given.has(item) or made.has(item)).override_failure_message("%s needs %s, which nothing gives or makes" % [recipe["id"], item]).is_true()
			assert_str(item).override_failure_message("%s needs what it makes" % recipe["id"]).is_not_equal(Crafting.item_made(recipe))
			assert_int(int(need["count"])).override_failure_message("%s: %d of %s fit in the pack" % [recipe["id"], need["count"], item]).is_less_equal(Inventory.capacity(DataRegistry.get_item(StringName(item))))
	# Every ore lies on some floor of the quarry, and every bar's ore and coal with it.
	var on_floors: Dictionary = {}
	for floor: Dictionary in DataRegistry.get_rules(DataRegistry.RULES_MINE)["floors"]:
		for ore: String in floor.get("ores", {}):
			on_floors[ore] = true
	for ore: String in ["copper_ore", "coal", "iron_ore", "gold_ore", "crystal"]:
		assert_bool(on_floors.has(ore)).override_failure_message("%s lies on some floor" % ore).is_true()


func test_the_things_crafting_added_are_what_the_plan_says() -> void:
	# [item, its type, how many a stack holds]: the plan's table of items.
	var plan: Array = [
		[&"copper_bar", "material", 20], [&"iron_bar", "material", 20], [&"gold_bar", "material", 20], [&"wood", "material", 30],
		[&"copper_hoe", "tool", 1], [&"iron_hoe", "tool", 1], [&"copper_watering_can", "tool", 1], [&"iron_watering_can", "tool", 1],
		[&"copper_pickaxe", "tool", 1], [&"iron_pickaxe", "tool", 1], [&"sprinkler", "sprinkler", 10], [&"miners_lantern", "lantern", 1],
	]
	var gift_types: Array = DataRegistry.get_rules(DataRegistry.RULES_FRIENDSHIP)["gift_types"]
	for row: Array in plan:
		var item: Dictionary = DataRegistry.get_item(row[0])
		assert_bool(item.is_empty()).override_failure_message("%s is an item" % row[0]).is_false()
		assert_str(str(item["type"])).override_failure_message("%s: its type" % row[0]).is_equal(row[1])
		assert_int(Inventory.capacity(item)).override_failure_message("%s: a stack of it" % row[0]).is_equal(row[2])
		assert_that(ItemIcons.name_for(row[0])).override_failure_message("%s has a picture of its own" % row[0]).is_equal(row[0])
		# None of them is food, and none can be given as a gift.
		assert_bool(gift_types.has(str(item["type"]))).override_failure_message("%s is no gift" % row[0]).is_false()
		GameState.add_item(row[0], 1)
		assert_bool(GameState.eat(row[0])).override_failure_message("%s is not to be eaten" % row[0]).is_false()
		assert_int(GameState.item_count(row[0])).is_equal(1)


func test_a_save_keeps_the_furnace_the_chest_and_the_sprinkler_at_their_work() -> void:
	GameState.set_flag(Crafting.furnished_flag(&"furnace"), true)
	GameState.set_flag(Crafting.furnished_flag(&"chest"), true)
	# The furnace is lit. The chest holds two stacks of ore and one of turnips.
	assert_bool(GameState.light_furnace(&"iron_bar", 4)).is_true()
	for load: Array in [[&"copper_ore", 30], [&"copper_ore", 12], [&"turnip", 6]]:
		GameState.add_item(load[0], load[1])
		assert_str(GameState.store_put(load[0])).is_equal("")
	# A sprinkler stands between a turnip and bare tilled soil; another turnip is in the corner.
	for cell: Vector2i in [Vector2i(1, 1), Vector2i(1, 0), Vector2i(0, 1), Vector2i(2, 1), Vector2i(1, 2), Vector2i(0, 0)]:
		GameState.till_soil(cell)
	assert_bool(GameState.place_sprinkler(Vector2i(1, 1))).is_true()
	GameState.plant_crop(Vector2i(2, 1), &"turnip")
	GameState.plant_crop(Vector2i(0, 0), &"turnip")
	GameState.update_player(&"home", Vector2i(5, 5))
	assert_int(SaveSystem.save_to_slot(TEST_SLOT)).is_equal(OK)
	var before: String = JSON.stringify(GameState.to_dict(), "", true)
	GameState.clear()
	assert_int(SaveSystem.load_from_slot(TEST_SLOT)).is_equal(OK)
	assert_str(JSON.stringify(GameState.to_dict(), "", true)).is_equal(before)

	# The chest has its stacks, in their order, and gives them back.
	assert_array(GameState.store().to_list()).is_equal([{"id": "copper_ore", "count": 30}, {"id": "copper_ore", "count": 12}, {"id": "turnip", "count": 6}])
	assert_str(GameState.store_take(1)).is_equal("")
	assert_int(GameState.item_count(&"copper_ore")).is_equal(12)
	assert_array(GameState.store().to_list()).is_equal([{"id": "copper_ore", "count": 30}, {"id": "turnip", "count": 6}])

	# The furnace is still burning, and has its bars the next morning.
	assert_bool(GameState.furnace().is_burning(GameState.day)).is_true()
	GameState.start_next_day()
	assert_bool(GameState.furnace().is_ready(GameState.day)).is_true()
	assert_dict(GameState.empty_furnace()).is_equal({"item": &"iron_bar", "count": 4})
	assert_int(GameState.item_count(&"iron_bar")).is_equal(4)

	# The sprinkler waters its four cells that morning, and every morning after: the turnip
	# beside it ripens without the can, and the one in the corner withers.
	var sides: Array[Vector2i] = [Vector2i(1, 0), Vector2i(0, 1), Vector2i(2, 1), Vector2i(1, 2)]
	for morning: int in 4:
		if morning > 0:
			GameState.start_next_day()
		assert_bool(GameState.farm().has_sprinkler(Vector2i(1, 1))).is_true()
		for cell: Vector2i in sides:
			assert_bool(GameState.farm().is_watered(cell)).override_failure_message("day %d: %s is watered" % [GameState.day, cell]).is_true()
		assert_bool(GameState.farm().is_watered(Vector2i(0, 0))).override_failure_message("day %d: the corner is dry" % GameState.day).is_false()
		assert_bool(GameState.farm().is_watered(Vector2i(1, 1))).override_failure_message("its own cell is dry").is_false()
	assert_int(GameState.day).is_equal(5)
	assert_that(GameState.crop_phase(Vector2i(2, 1))).is_equal(Farm.RIPE)
	assert_that(GameState.crop_phase(Vector2i(0, 0))).is_equal(Farm.WITHERED)


# --- Helpers -------------------------------------------------------------------------------

func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area


func _ids(recipes: Array) -> Array:
	return recipes.map(func(recipe: Dictionary) -> String: return str(recipe["id"]))


## Whether `recipe_id` is on the workbench's list now.
func _listed(home: AreaController, recipe_id: String) -> bool:
	return _ids(home.hud.craft_menu.entries()).has(recipe_id)


## Whether `recipe_id` is on the list and not greyed out.
func _can_make(home: AreaController, recipe_id: String) -> bool:
	var menu: CraftMenu = home.hud.craft_menu
	return menu.can_make(_ids(menu.entries()).find(recipe_id))


## Makes `recipe_id` at the workbench as a player does: the list open, the cursor on its line,
## the line bright, and Enter.
func _make(home: AreaController, recipe_id: String) -> void:
	var menu: CraftMenu = home.hud.craft_menu
	if not menu.is_open():
		Steps.stand_before(home, "Workbench")
		assert_bool(home.interact()).is_true()
	assert_bool(menu.is_open()).is_true()
	var index: int = _ids(menu.entries()).find(recipe_id)
	assert_int(index).override_failure_message("%s is on the workbench's list" % recipe_id).is_greater_equal(0)
	menu.move_cursor(index - menu.selected)
	assert_int(menu.selected).is_equal(index)
	assert_bool(menu.can_make(index)).override_failure_message("%s can be made (%s)" % [recipe_id, ", ".join(menu.need_lines())]).is_true()
	assert_bool(menu.confirm()).override_failure_message("%s: %s" % [recipe_id, menu.note_text()]).is_true()


## Loads the furnace with the metal on answer `line` and lights it: `bars` is the load he has
## the ore and the coal for.
func _smelt(home: AreaController, line: int, bars: int) -> void:
	home.hud.craft_menu.close()
	Steps.stand_before(home, "Furnace")
	assert_bool(home.interact()).is_true()
	assert_str(home.hud.dialogue.shown_text()).is_equal(Furnace.COLD_WORDS)
	home.hud.dialogue.move_cursor(line)
	home.hud.dialogue.confirm()
	home.hud.dialogue.confirm()
	assert_bool(home.is_talking()).is_false()
	assert_int(GameState.furnace().count).override_failure_message("a load of %d" % bars).is_equal(bars)
	assert_bool(GameState.furnace().is_burning(GameState.day)).is_true()


## Sleeps on it, and takes out what the furnace made.
func _take_out(home: AreaController, item: StringName, bars: int) -> void:
	home.hud.craft_menu.close()
	var before: int = GameState.item_count(item)
	GameState.start_next_day()
	Steps.stand_before(home, "Furnace")
	assert_bool(home.interact()).is_true()
	assert_array(Array(home.hud.dialogue.shown_options())).is_equal([Furnace.TAKE_WORDS, Furnace.LEAVE_WORDS])
	home.hud.dialogue.confirm()
	assert_bool(home.is_talking()).is_false()
	assert_int(GameState.item_count(item) - before).override_failure_message("%d of %s came out" % [bars, item]).is_equal(bars)
	assert_bool(GameState.furnace().is_empty()).is_true()


func _on_crafted(recipe_id: StringName) -> void:
	_made.append(String(recipe_id))
