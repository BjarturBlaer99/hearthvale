extends GdUnitTestSuite
## Shop (P3c): what is on a shop's two lists, what a deal needs and why one can't be made. Tried
## on the game's own shop (data/shops/tilda.json) and crops, and on made-up ones.

const DataRegistryScript: GDScript = preload("res://autoload/data_registry.gd")

var _tilda: Dictionary
var _crops: Array


func before_test() -> void:
	_tilda = DataRegistry.get_shop(&"tilda")
	_crops = DataRegistry.entries(&"crops")


func test_tilda_sells_her_wares_then_a_seed_of_every_crop_cheapest_first() -> void:
	assert_str(str(_tilda["name"])).is_equal("Tilda's Shop")
	assert_array(Shop.wares(_tilda, _crops)).is_equal([
		{"item": "arrow", "count": 10, "price": 5},
		{"item": "bomb", "count": 3, "price": 8},
		{"item": "bread", "count": 1, "price": 6},
		{"item": "pickaxe", "count": 1, "price": 25},
		{"item": "turnip_seeds", "count": 1, "price": 5},
		{"item": "wheat_seeds", "count": 1, "price": 6},
		{"item": "carrot_seeds", "count": 1, "price": 8},
		{"item": "potato_seeds", "count": 1, "price": 10},
		{"item": "pumpkin_seeds", "count": 1, "price": 20},
	])
	# A shop that sells no seeds has only its own wares; one with no wares, only seeds.
	assert_int(Shop.wares({"sells": _tilda["sells"]}, _crops).size()).is_equal(4)
	assert_int(Shop.wares({"sells": [], "sells_seeds": true}, _crops).size()).is_equal(5)
	assert_array(Shop.wares({}, _crops)).is_empty()
	# A new crop is on the list without touching the shop.
	var with_beans: Array = _crops.duplicate()
	with_beans.append({"id": "bean", "seed": "bean_seeds", "gives": {"item": "bean"}, "seed_price": 7, "sells_for": 15})
	var seeds: Array = Shop.wares(_tilda, with_beans).map(func(ware: Dictionary) -> String: return str(ware["item"]))
	assert_array(seeds.slice(4)).override_failure_message("between wheat (6) and carrots (8)").is_equal(["turnip_seeds", "wheat_seeds", "bean_seeds", "carrot_seeds", "potato_seeds", "pumpkin_seeds"])


func test_tilda_buys_what_the_crops_give_and_nothing_else() -> void:
	var pack: Array = [{"id": &"coin", "count": 10}, {"id": &"wheat", "count": 5}, {"id": &"mushroom", "count": 3},
		{"id": &"turnip", "count": 4}, {"id": &"bread", "count": 2}, {"id": &"pumpkin", "count": 1}, {"id": &"turnip_seeds", "count": 9}]
	assert_array(Shop.offers(_tilda, _crops, pack)).override_failure_message("his harvest, in the order of the seeds, at each crop's price").is_equal([
		{"item": "turnip", "count": 4, "price": 12},
		{"item": "wheat", "count": 5, "price": 10},
		{"item": "pumpkin", "count": 1, "price": 60},
	])
	assert_array(Shop.offers(_tilda, _crops, [])).is_empty()
	assert_array(Shop.offers(_tilda, _crops, [{"id": &"bread", "count": 3}, {"id": &"carrot", "count": 0}])).override_failure_message("no bread, and no carrots he hasn't got").is_empty()
	assert_array(Shop.offers({"sells": [], "sells_seeds": true}, _crops, pack)).override_failure_message("a shop that doesn't buy").is_empty()
	# Every crop sells for more than its seed costs (GDD §7).
	for crop: Dictionary in _crops:
		assert_int(int(crop["sells_for"])).override_failure_message(str(crop["id"])).is_greater(int(crop["seed_price"]))


func test_a_deal_needs_the_coins_and_the_room() -> void:
	var arrows: Dictionary = {"item": "arrow", "count": 10, "price": 5}
	var quiver: Dictionary = DataRegistry.get_item(&"arrow")
	assert_str(Shop.why_not_buy(arrows, 5, 0, quiver)).is_equal("")
	assert_str(Shop.why_not_buy(arrows, 4, 0, quiver)).is_equal(Shop.NO_COINS)
	assert_str(Shop.why_not_buy(arrows, 99, 20, quiver)).override_failure_message("twenty and ten make a full quiver").is_equal("")
	assert_str(Shop.why_not_buy(arrows, 99, 21, quiver)).override_failure_message("all ten must fit").is_equal(Shop.NO_ROOM)
	assert_str(Shop.why_not_buy(arrows, 0, 30, quiver)).override_failure_message("the coins are said first").is_equal(Shop.NO_COINS)
	assert_str(Shop.why_not_buy({"item": "gift", "count": 1, "price": 0}, 0, 0, {})).override_failure_message("a free ware").is_equal("")
	# Selling: the purse must hold the coins, and he must have one to sell.
	var turnips: Dictionary = {"item": "turnip", "count": 3, "price": 12}
	assert_str(Shop.why_not_sell(turnips, 0, 999)).is_equal("")
	assert_str(Shop.why_not_sell(turnips, 987, 999)).is_equal("")
	assert_str(Shop.why_not_sell(turnips, 988, 999)).is_equal(Shop.FULL_PURSE)
	assert_str(Shop.why_not_sell({"item": "turnip", "count": 0, "price": 12}, 0, 999)).is_equal(Shop.NONE_LEFT)


func test_the_lists_say_what_a_deal_is() -> void:
	assert_str(Shop.coins_text(1)).is_equal("1 coin")
	assert_str(Shop.coins_text(5)).is_equal("5 coins")
	assert_str(Shop.coins_text(0)).is_equal("0 coins")
	assert_str(Shop.ware_line({"item": "arrow", "count": 10, "price": 5}, "Arrows")).is_equal("Arrows x10: 5 coins")
	assert_str(Shop.ware_line({"item": "bread", "count": 1, "price": 6}, "Bread")).is_equal("Bread: 6 coins")
	assert_str(Shop.ware_line({"item": "nail", "count": 1, "price": 1}, "Nail")).is_equal("Nail: 1 coin")
	assert_str(Shop.offer_line({"item": "turnip", "count": 4, "price": 12}, "Turnip")).is_equal("Turnip x4: 12 coins each")
	assert_array(Shop.MODES).is_equal([Shop.BUY, Shop.SELL])


func test_the_games_shop_is_sound_and_bad_ones_are_named() -> void:
	var item_of: Callable = func(id: String) -> Dictionary: return DataRegistry.get_item(StringName(id))
	assert_array(Array(Shop.problems(_tilda, item_of))).is_empty()
	assert_array(DataRegistry.ids(&"shops")).is_equal([&"tilda"])
	assert_array(Array(Shop.problems({"id": "kiosk", "name": "", "sells": [
		{"item": "gem", "price": 3}, {"item": "bread", "price": -2, "count": 0}, {"item": "arrow"}, "bombs",
	]}, item_of))).contains_exactly([
		"'name' must be what the shop is called.",
		"'sells' names an unknown item id 'gem'.",
		"the price of 'bread' must be a whole number of coins, 0 or more.",
		"the 'count' of 'bread' must be a whole number of 1 or more.",
		"every entry in 'sells' has an 'item' and a 'price'.",
		"every entry in 'sells' has an 'item' and a 'price'.",
	])
	assert_array(Array(Shop.problems({"id": "stall", "name": "Stall", "sells": "apples"}, item_of))).contains_exactly(["'sells' must list the shop's wares (it may be empty)."])
	assert_array(Array(Shop.problems({"id": "stall", "name": "Stall", "sells": []}, item_of))).override_failure_message("a shop may sell only seeds").is_empty()
	# The registry runs them on every shop, and checks every conversation that opens one.
	var registry: Node = auto_free(DataRegistryScript.new())
	var errors: String = "\n".join(registry.load_all("res://tests/fixtures/bad_shops"))
	assert_str(errors).contains("shop 'kiosk': 'sells' names an unknown item id 'gem'.")
	assert_str(errors).contains("shop 'kiosk': the price of 'bread' must be a whole number of coins, 0 or more.")
	assert_str(errors).contains("shop 'cart' is missing required field 'sells'.")
	assert_str(errors).contains("a shop's 'mode' must be 'buy' or 'sell', not 'barter'.")
	assert_str(errors).contains("unknown shop id 'nowhere'")
