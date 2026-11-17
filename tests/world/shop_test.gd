extends GdUnitTestSuite
## Tilda's shop (P3c): her conversation opens a buy-and-sell list; seeds and her old wares are
## bought from it for the prices in the GDD, and the harvest is sold on it; a deal that can't
## be made says why and changes nothing; the hero stands still and the clock with him while the
## list is open.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const SHOP: String = "res://world/areas/shop/shop.tscn"
const VILLAGE: String = "res://world/areas/village/village.tscn"
const FRAME: float = 1.0 / 60.0
## GDD §7 and §9: what each ware costs, and what each crop sells for.
const BUY_LINES: Array[String] = [
	"Arrows x10: 5 coins", "Bombs x3: 8 coins", "Bread: 6 coins", "Pickaxe: 25 coins", "Turnip Seeds: 5 coins",
	"Wheat Seeds: 6 coins", "Carrot Seeds: 8 coins", "Seed Potatoes: 10 coins", "Pumpkin Seeds: 20 coins",
]
const SELLS_FOR: Dictionary = {&"turnip": 12, &"wheat": 10, &"carrot": 18, &"potato": 24, &"pumpkin": 60}

var _area: Node
var _heard: Array[StringName] = []


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	GameState.set_time(float(GameState.day_clock().in_day("12:00")))
	_heard.clear()
	EventBus.sound.connect(_on_sound)


func after_test() -> void:
	EventBus.sound.disconnect(_on_sound)
	if is_instance_valid(_area):
		_area.free()
	_area = null
	Audio.play_music(&"")
	GameState.clear()


func test_tildas_conversation_opens_her_list() -> void:
	var shop: AreaController = _load(SHOP)
	var counter: ShopMenu = shop.hud.shop_menu
	Steps.stand_before(shop, "Tilda")
	assert_bool(shop.interact()).is_true()
	var box: DialogueBox = shop.hud.dialogue
	assert_array(Array(box.shown_options())).is_equal(["Let me see what you sell.", "I have things to sell.", "Just looking."])
	assert_str(box.shown_text()).override_failure_message("she says what she has, and that she buys").contains("Seeds").contains("buy what you grow").contains("dig out of the quarry")
	assert_bool(counter.is_open()).override_failure_message("not while she is still talking").is_false()
	box.confirm()
	assert_bool(shop.is_talking()).is_false()
	assert_bool(counter.is_open()).is_true()
	assert_that(counter.mode).is_equal(Shop.BUY)
	assert_str(counter.tabs_text()).is_equal("[Buy]   Sell ")
	assert_bool(shop.is_in_menu()).is_true()
	assert_bool(shop.player.controls_enabled).override_failure_message("he stands at the counter").is_false()
	assert_bool(shop.clock_runs()).override_failure_message("and the clock with him").is_false()
	var minute: float = GameState.minute
	shop._process(2.0)
	assert_float(GameState.minute).is_equal(minute)
	assert_bool(shop.interact() or shop.use_hand() or shop.open_item_menu()).override_failure_message("nothing else while the list is open").is_false()
	counter.close()
	assert_bool(shop.is_in_menu()).is_false()
	assert_bool(shop.player.controls_enabled).is_true()
	assert_bool(shop.clock_runs()).is_true()
	# "I have things to sell" opens it on the other list; "Just looking" opens nothing.
	assert_bool(shop.interact()).is_true()
	box.move_cursor(1)
	box.confirm()
	assert_bool(counter.is_open()).is_true()
	assert_that(counter.mode).is_equal(Shop.SELL)
	assert_str(counter.tabs_text()).is_equal(" Buy   [Sell]")
	counter.close()
	assert_bool(shop.interact()).is_true()
	box.move_cursor(2)
	box.confirm()
	assert_bool(counter.is_open() or shop.is_talking()).is_false()
	assert_bool(shop.player.controls_enabled).is_true()
	# The eggs she is owed are still asked for in her conversation.
	GameState.set_quest_stage(&"eggs_for_tilda", &"deliver")
	GameState.add_item(&"egg_basket")
	assert_bool(shop.interact()).is_true()
	assert_str(box.shown_options()[0]).is_equal("Eggs from Farmer Oda.")


func test_her_list_shows_nine_wares_five_at_a_time() -> void:
	GameState.add_item(&"coin", 47)
	var shop: AreaController = _load(SHOP)
	assert_bool(shop.open_shop(&"tilda", Shop.BUY)).is_true()
	var counter: ShopMenu = shop.hud.shop_menu
	assert_str((counter.get_node(^"Panel/Title") as Label).text).is_equal("Tilda's Shop")
	assert_str((counter.get_node(^"Panel/Coins") as Label).text).is_equal("47 coins")
	assert_int(counter.entries().size()).is_equal(BUY_LINES.size())
	assert_array(Array(counter.shown_lines())).is_equal(["> " + BUY_LINES[0], "  " + BUY_LINES[1], "  " + BUY_LINES[2], "  " + BUY_LINES[3], "  " + BUY_LINES[4]])
	assert_str((counter.get_node(^"Panel/Count") as Label).text).is_equal("  1/9 v")
	for i: int in range(1, BUY_LINES.size()):
		counter.move_cursor(1)
		assert_bool(Array(counter.shown_lines()).has("> " + BUY_LINES[i])).override_failure_message("the cursor on '%s' is in view" % BUY_LINES[i]).is_true()
		assert_int(counter.shown_lines().size()).is_equal(ShopMenu.ROWS)
	assert_str((counter.get_node(^"Panel/Count") as Label).text).is_equal("^ 9/9  ")
	counter.move_cursor(1)
	assert_str(counter.shown_lines()[0]).override_failure_message("past the end it wraps to the top").is_equal("> " + BUY_LINES[0])
	assert_bool(shop.open_shop(&"nowhere", Shop.BUY)).override_failure_message("no such shop").is_false()


func test_seeds_and_wares_are_bought_for_their_prices() -> void:
	GameState.add_item(&"coin", 93)
	var shop: AreaController = _load(SHOP)
	shop.open_shop(&"tilda", Shop.BUY)
	var counter: ShopMenu = shop.hud.shop_menu
	var wares: Array[Dictionary] = counter.entries()
	var spent: int = 0
	for i: int in wares.size():
		_heard.clear()
		assert_bool(counter.confirm()).override_failure_message("buying %s" % wares[i]["item"]).is_true()
		spent += int(wares[i]["price"])
		assert_int(GameState.item_count(StringName(str(wares[i]["item"])))).is_equal(int(wares[i]["count"]))
		assert_int(GameState.item_count(&"coin")).is_equal(93 - spent)
		assert_array(_heard).contains([&"coin"])
		counter.move_cursor(1)
	assert_int(spent).override_failure_message("one of everything: 5+8+6+25 and 5+6+8+10+20").is_equal(93)
	assert_str(counter.note_text()).is_equal("Bought: Pumpkin Seeds.")
	assert_str((counter.get_node(^"Panel/Coins") as Label).text).is_equal("0 coins")
	# With an empty purse nothing more is sold, and nothing changes.
	_heard.clear()
	var before: Dictionary = GameState.to_dict()
	assert_bool(counter.confirm()).is_false()
	assert_str(counter.note_text()).is_equal(Shop.NO_COINS)
	assert_array(_heard).contains_exactly([&"nope"])
	assert_dict(GameState.to_dict()).is_equal(before)
	# What comes in tens says so.
	GameState.add_item(&"coin", 5)
	assert_bool(counter.confirm()).is_true()
	assert_str(counter.note_text()).is_equal("Bought: Arrows x10.")
	assert_int(GameState.item_count(&"arrow")).is_equal(20)


func test_a_ware_there_is_no_room_for_is_not_sold() -> void:
	GameState.add_item(&"coin", 100)
	GameState.add_item(&"bomb", 8)
	GameState.add_item(&"turnip_seeds", 30)
	var shop: AreaController = _load(SHOP)
	shop.open_shop(&"tilda", Shop.BUY)
	var counter: ShopMenu = shop.hud.shop_menu
	counter.move_cursor(1)
	assert_bool(counter.confirm()).override_failure_message("eight bombs and three more don't fit a bag of ten").is_false()
	assert_str(counter.note_text()).is_equal(Shop.NO_ROOM)
	counter.move_cursor(3)
	assert_bool(counter.confirm()).override_failure_message("thirty seeds is a full pouch").is_false()
	assert_str(counter.note_text()).is_equal(Shop.NO_ROOM)
	assert_int(GameState.item_count(&"coin")).is_equal(100)
	assert_int(GameState.item_count(&"bomb")).is_equal(8)


func test_the_harvest_is_sold_one_at_a_time_for_each_crops_price() -> void:
	for item: Array in [[&"turnip", 2], [&"wheat", 1], [&"carrot", 1], [&"potato", 1], [&"pumpkin", 1], [&"mushroom", 3], [&"bread", 1], [&"coin", 3]]:
		GameState.add_item(item[0], item[1])
	var shop: AreaController = _load(SHOP)
	shop.open_shop(&"tilda", Shop.SELL)
	var counter: ShopMenu = shop.hud.shop_menu
	assert_array(Array(counter.shown_lines())).override_failure_message("his harvest only: no mushrooms, no bread").is_equal([
		"> Turnip x2: 12 coins each", "  Wheat x1: 10 coins each", "  Carrot x1: 18 coins each", "  Potato x1: 24 coins each", "  Pumpkin x1: 60 coins each"])
	# A turnip: twelve coins, and one fewer on its line.
	_heard.clear()
	assert_bool(counter.confirm()).is_true()
	assert_int(GameState.item_count(&"turnip")).is_equal(1)
	assert_int(GameState.item_count(&"coin")).is_equal(15)
	assert_str(counter.note_text()).is_equal("Sold: Turnip, for 12 coins.")
	assert_str(counter.shown_lines()[0]).is_equal("> Turnip x1: 12 coins each")
	assert_array(_heard).contains([&"coin"])
	# The last one: its line goes, and the cursor is on what follows.
	assert_bool(counter.confirm()).is_true()
	assert_str(counter.shown_lines()[0]).is_equal("> Wheat x1: 10 coins each")
	var coins: int = 27
	for crop: StringName in [&"wheat", &"carrot", &"potato", &"pumpkin"]:
		assert_bool(counter.confirm()).override_failure_message("selling the %s" % crop).is_true()
		coins += int(SELLS_FOR[crop])
		assert_int(GameState.item_count(crop)).is_equal(0)
		assert_int(GameState.item_count(&"coin")).is_equal(coins)
	assert_int(coins).is_equal(3 + 12 + 12 + 10 + 18 + 24 + 60)
	assert_array(Array(counter.shown_lines())).is_equal([ShopMenu.NOTHING_TO_SELL])
	assert_bool(counter.confirm()).override_failure_message("nothing left to sell").is_false()
	assert_int(GameState.item_count(&"mushroom")).override_failure_message("she bought no mushrooms").is_equal(3)
	assert_int(GameState.item_count(&"bread")).is_equal(1)
	for crop: StringName in SELLS_FOR:
		assert_int(int(DataRegistry.get_crop(crop)["sells_for"])).override_failure_message("%s's price is its data's" % crop).is_equal(int(SELLS_FOR[crop]))


func test_ore_bars_and_crystals_are_sold_beside_the_crops() -> void:
	for item: Array in [[&"gold_bar", 1], [&"coal", 2], [&"copper_ore", 2], [&"stone", 3], [&"wood", 2], [&"turnip", 1], [&"crystal", 1],
			[&"iron_bar", 1], [&"iron_ore", 1], [&"gold_ore", 1], [&"copper_bar", 1]]:
		GameState.add_item(item[0], item[1])
	var shop: AreaController = _load(SHOP)
	shop.open_shop(&"tilda", Shop.SELL)
	var counter: ShopMenu = shop.hud.shop_menu
	var lines: Array[String] = [
		"Turnip x1: 12 coins each", "Copper Ore x2: 2 coins each", "Iron Ore x1: 3 coins each", "Gold Ore x1: 7 coins each",
		"Crystal x1: 10 coins each", "Copper Bar x1: 8 coins each", "Iron Bar x1: 12 coins each", "Gold Bar x1: 25 coins each"]
	assert_int(counter.entries().size()).override_failure_message("the turnip and seven things from the quarry: no stone, coal or wood").is_equal(lines.size())
	assert_array(Array(counter.shown_lines())).is_equal(["> " + lines[0], "  " + lines[1], "  " + lines[2], "  " + lines[3], "  " + lines[4]])
	assert_str((counter.get_node(^"Panel/Count") as Label).text).is_equal("  1/8 v")
	# The rest is a scroll away.
	for i: int in range(1, lines.size()):
		counter.move_cursor(1)
		assert_bool(Array(counter.shown_lines()).has("> " + lines[i])).override_failure_message("the cursor on '%s' is in view" % lines[i]).is_true()
	counter.move_cursor(2)
	assert_bool(Array(counter.shown_lines()).has("> Copper Ore x2: 2 coins each")).override_failure_message("past the end and round to the second line").is_true()
	# One ore: two coins, and one fewer on its line.
	assert_bool(counter.confirm()).is_true()
	assert_int(GameState.item_count(&"copper_ore")).is_equal(1)
	assert_int(GameState.item_count(&"coin")).is_equal(2)
	assert_str(counter.note_text()).is_equal("Sold: Copper Ore, for 2 coins.")
	assert_bool(Array(counter.shown_lines()).has("> Copper Ore x1: 2 coins each")).is_true()
	# Everything she buys, sold: the plan's prices.
	counter.move_cursor(-1)
	var sold: int = 1
	while not counter.entries().is_empty() and sold < 20:
		assert_bool(counter.confirm()).is_true()
		sold += 1
	assert_int(sold).override_failure_message("nine things, one at a time").is_equal(9)
	assert_int(GameState.item_count(&"coin")).override_failure_message("12 + 2 + 2 + 3 + 7 + 10 + 8 + 12 + 25").is_equal(81)
	assert_array(Array(counter.shown_lines())).is_equal([ShopMenu.NOTHING_TO_SELL])
	for kept: Array in [[&"stone", 3], [&"coal", 2], [&"wood", 2]]:
		assert_int(GameState.item_count(kept[0])).override_failure_message("she bought no %s" % kept[0]).is_equal(kept[1])
	for gone: StringName in [&"turnip", &"copper_ore", &"iron_ore", &"gold_ore", &"crystal", &"copper_bar", &"iron_bar", &"gold_bar"]:
		assert_int(GameState.item_count(gone)).is_equal(0)
	# What has been sold is still found: a recipe that waited on it stays known.
	assert_bool(GameState.has_found(&"copper_bar")).is_true()


func test_a_full_purse_keeps_the_ore_too() -> void:
	GameState.add_item(&"coin", 990)
	GameState.add_item(&"gold_bar", 1)
	GameState.add_item(&"copper_ore", 4)
	var shop: AreaController = _load(SHOP)
	shop.open_shop(&"tilda", Shop.SELL)
	var counter: ShopMenu = shop.hud.shop_menu
	assert_array(Array(counter.shown_lines())).is_equal(["> Copper Ore x4: 2 coins each", "  Gold Bar x1: 25 coins each"])
	counter.move_cursor(1)
	assert_bool(counter.confirm()).override_failure_message("990 and 25 are more than a purse holds").is_false()
	assert_str(counter.note_text()).is_equal(Shop.FULL_PURSE)
	assert_int(GameState.item_count(&"gold_bar")).is_equal(1)
	counter.move_cursor(-1)
	assert_bool(counter.confirm()).override_failure_message("two coins still fit").is_true()
	assert_int(GameState.item_count(&"coin")).is_equal(992)


func test_a_full_purse_keeps_the_crop() -> void:
	GameState.add_item(&"coin", 990)
	GameState.add_item(&"turnip", 2)
	var shop: AreaController = _load(SHOP)
	shop.open_shop(&"tilda", Shop.SELL)
	var counter: ShopMenu = shop.hud.shop_menu
	assert_bool(counter.confirm()).override_failure_message("990 and 12 are more than a purse holds").is_false()
	assert_str(counter.note_text()).is_equal(Shop.FULL_PURSE)
	assert_int(GameState.item_count(&"turnip")).is_equal(2)
	assert_int(GameState.item_count(&"coin")).is_equal(990)


func test_the_keys_and_the_clicks_work_her_list() -> void:
	GameState.add_item(&"coin", 30)
	GameState.add_item(&"turnip", 1)
	var shop: AreaController = _load(SHOP)
	shop.open_shop(&"tilda", Shop.BUY)
	var counter: ShopMenu = shop.hud.shop_menu
	counter._unhandled_input(_action(&"move_down"))
	counter._unhandled_input(_action(&"move_down"))
	assert_int(counter.selected).is_equal(2)
	counter._unhandled_input(_click(MOUSE_BUTTON_LEFT))
	assert_int(GameState.item_count(&"bread")).override_failure_message("a left click makes the deal").is_equal(1)
	counter._unhandled_input(_click(MOUSE_BUTTON_RIGHT))
	assert_int(GameState.item_count(&"bread")).override_failure_message("so does a right click").is_equal(2)
	counter._unhandled_input(_action(&"move_up"))
	assert_int(counter.selected).is_equal(1)
	# Left and right turn to the other list, and back.
	counter._unhandled_input(_action(&"move_right"))
	assert_that(counter.mode).is_equal(Shop.SELL)
	assert_int(counter.selected).override_failure_message("from the top").is_equal(0)
	assert_str(counter.note_text()).override_failure_message("the last deal's words go").is_equal("")
	counter._unhandled_input(_click(MOUSE_BUTTON_LEFT))
	assert_int(GameState.item_count(&"turnip")).is_equal(0)
	counter._unhandled_input(_action(&"move_left"))
	assert_that(counter.mode).is_equal(Shop.BUY)
	counter.switch_mode()
	assert_that(counter.mode).is_equal(Shop.SELL)
	# Tab or Esc leaves.
	counter._unhandled_input(_action(&"item_menu"))
	assert_bool(counter.is_open()).is_false()
	assert_bool(shop.player.controls_enabled).is_true()
	shop.open_shop(&"tilda", Shop.BUY)
	counter._unhandled_input(_action(&"pause"))
	assert_bool(counter.is_open()).is_false()
	assert_bool(shop.is_paused()).override_failure_message("Esc left the list; it didn't open the pause menu too").is_false()
	# Closed, it hears nothing.
	counter._unhandled_input(_click(MOUSE_BUTTON_LEFT))
	assert_int(GameState.item_count(&"bread")).is_equal(2)
	assert_int((counter.get_node(^"Panel") as PanelFrame).get_child_count()).override_failure_message("a title, the tabs, the coins, the list, a note, a count, the help").is_equal(7)


func test_the_shop_effect_asks_for_a_shop_and_only_tilda_has_one() -> void:
	var asked: Array = []
	var listen: Callable = func(shop_id: StringName, mode: StringName) -> void: asked.append([shop_id, mode])
	EventBus.shop_requested.connect(listen)
	assert_bool(EffectApplier.new(GameState).apply({"type": "shop", "shop": "tilda", "mode": "sell"})).is_true()
	EventBus.shop_requested.disconnect(listen)
	assert_array(asked).is_equal([[&"tilda", &"sell"]])
	# A conversation elsewhere opens no shop, and a request with no conversation is kept for
	# the next one that closes.
	var village: AreaController = _load(VILLAGE)
	Steps.stand_before(village, "FarmerOda")
	assert_bool(village.interact()).is_true()
	for i: int in 30:
		if not village.is_talking():
			break
		village.hud.dialogue.confirm()
	assert_bool(village.hud.shop_menu.is_open()).is_false()
	assert_bool(village.player.controls_enabled).is_true()


func _action(action: StringName) -> InputEventAction:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = true
	return event


func _click(button: MouseButton) -> InputEventMouseButton:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = button
	event.pressed = true
	return event


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area


func _on_sound(id: StringName) -> void:
	_heard.append(id)
