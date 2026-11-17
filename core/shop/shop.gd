class_name Shop
extends RefCounted
## A shop's buy-and-sell list (P3c, GDD §9), pure. A shop is data (data/shops/<id>.json):
##   { "id": "tilda", "name": "Tilda's Shop",
##     "sells": [ { "item": "arrow", "count": 10, "price": 5 } ],
##     "sells_seeds": true, "buys_crops": true,
##     "buys": [ { "item": "copper_ore", "price": 2 } ] }
## `sells` are its own wares. With `sells_seeds` it also sells a seed of every crop at the
## crop's seed price, and with `buys_crops` it buys what every crop gives at the crop's sale
## price (data/crops), so a new crop is on both lists without touching the shop. `buys` are the
## other things it pays for (ore, bars, crystals), each at its own price, so a new thing to buy
## is a line of data. This says what is on each list, what a deal costs and gives, and why one
## can't be made; GameState makes it.

## The two lists.
const BUY: StringName = &"buy"
const SELL: StringName = &"sell"
const MODES: Array[StringName] = [BUY, SELL]
## Why a deal can't be made.
const NO_COINS: String = "You haven't the coins for that."
const NO_ROOM: String = "You have no room to carry more of that."
const FULL_PURSE: String = "Your purse can hold no more coins."
const NONE_LEFT: String = "You have none of that left."


## What the shop sells: its own wares in their order, then a seed of every crop, cheapest
## first. Each is { "item": id, "count": how many a deal gives, "price": coins }.
static func wares(shop: Dictionary, crops: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for ware: Variant in shop.get("sells", []):
		if typeof(ware) == TYPE_DICTIONARY:
			out.append({"item": str(ware.get("item", "")), "count": maxi(int(ware.get("count", 1)), 1), "price": maxi(int(ware.get("price", 0)), 0)})
	if bool(shop.get("sells_seeds", false)):
		for crop: Dictionary in _by_seed_price(crops):
			out.append({"item": str(crop.get("seed", "")), "count": 1, "price": maxi(int(crop.get("seed_price", 0)), 0)})
	return out


## What the shop would buy of what `stacks` hold (GameState.inventory's shape): the harvest of
## every crop he carries some of, in the order of the seeds, then what its `buys` list names
## and he carries, in that list's order. Each is { "item": id, "count": how many he has,
## "price": coins for one }. A thing is on the list once: a crop's own price comes first.
static func offers(shop: Dictionary, crops: Array, stacks: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var held: Dictionary = {}
	for stack: Variant in stacks:
		if typeof(stack) == TYPE_DICTIONARY:
			held[str((stack as Dictionary).get("id", ""))] = int((stack as Dictionary).get("count", 0))
	var listed: Dictionary = {}
	if bool(shop.get("buys_crops", false)):
		for crop: Dictionary in _by_seed_price(crops):
			var given: String = str(Crops.gives(crop)["item"])
			if int(held.get(given, 0)) > 0 and not listed.has(given):
				listed[given] = true
				out.append({"item": given, "count": int(held[given]), "price": maxi(int(crop.get("sells_for", 0)), 0)})
	for bought: Dictionary in bought_things(shop):
		var item: String = str(bought["item"])
		if int(held.get(item, 0)) > 0 and not listed.has(item):
			listed[item] = true
			out.append({"item": item, "count": int(held[item]), "price": int(bought["price"])})
	return out


## The shop's own `buys` list, in its order: each { "item": id, "price": coins for one }.
## Empty for a shop that buys nothing but crops.
static func bought_things(shop: Dictionary) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	var buys: Variant = shop.get("buys", [])
	if typeof(buys) != TYPE_ARRAY:
		return out
	for bought: Variant in buys:
		if typeof(bought) == TYPE_DICTIONARY and (bought as Dictionary).has("item"):
			out.append({"item": str(bought["item"]), "price": maxi(int((bought as Dictionary).get("price", 0)), 0)})
	return out


## Why `ware` can't be bought with `coins` in the purse and `held` of it carried already (of
## an item whose data entry is `item`): NO_COINS, NO_ROOM, or "" if it can.
static func why_not_buy(ware: Dictionary, coins: int, held: int, item: Dictionary) -> String:
	if coins < int(ware.get("price", 0)):
		return NO_COINS
	if Inventory.room_for(held, item) < int(ware.get("count", 1)):
		return NO_ROOM
	return ""


## Why one of `offer` can't be sold with `coins` in a purse that holds `purse` at most:
## NONE_LEFT, FULL_PURSE, or "" if it can.
static func why_not_sell(offer: Dictionary, coins: int, purse: int) -> String:
	if int(offer.get("count", 0)) <= 0:
		return NONE_LEFT
	return FULL_PURSE if coins + int(offer.get("price", 0)) > purse else ""


## "5 coins", "1 coin".
static func coins_text(coins: int) -> String:
	return "%d coin%s" % [coins, "" if coins == 1 else "s"]


## A ware as the list shows it: "Arrows x10: 5 coins", "Bread: 6 coins".
static func ware_line(ware: Dictionary, item_name: String) -> String:
	var many: String = " x%d" % int(ware["count"]) if int(ware["count"]) > 1 else ""
	return "%s%s: %s" % [item_name, many, coins_text(int(ware["price"]))]


## An offer as the list shows it: "Turnip x4: 12 coins each".
static func offer_line(offer: Dictionary, item_name: String) -> String:
	return "%s x%d: %s each" % [item_name, int(offer["count"]), coins_text(int(offer["price"]))]


## What is wrong with `shop`, in words: nothing, if it can be used. `item_of` gives the item
## entry for an id (empty if there is none).
static func problems(shop: Dictionary, item_of: Callable) -> PackedStringArray:
	var out: PackedStringArray = []
	if typeof(shop.get("name")) != TYPE_STRING or str(shop.get("name", "")).is_empty():
		out.append("'name' must be what the shop is called.")
	var sells: Variant = shop.get("sells")
	if typeof(sells) != TYPE_ARRAY:
		out.append("'sells' must list the shop's wares (it may be empty).")
		return out
	for ware: Variant in sells:
		if typeof(ware) != TYPE_DICTIONARY or not (ware as Dictionary).has("item") or not (ware as Dictionary).has("price"):
			out.append("every entry in 'sells' has an 'item' and a 'price'.")
			continue
		if (item_of.call(str(ware["item"])) as Dictionary).is_empty():
			out.append("'sells' names an unknown item id '%s'." % ware["item"])
		if not _is_whole(ware["price"], 0):
			out.append("the price of '%s' must be a whole number of coins, 0 or more." % ware["item"])
		if not _is_whole((ware as Dictionary).get("count", 1), 1):
			out.append("the 'count' of '%s' must be a whole number of 1 or more." % ware["item"])
	if not shop.has("buys"):
		return out
	var buys: Variant = shop["buys"]
	if typeof(buys) != TYPE_ARRAY:
		out.append("'buys' must list what the shop pays for (it may be left out).")
		return out
	var named: Dictionary = {}
	for bought: Variant in buys:
		if typeof(bought) != TYPE_DICTIONARY or not (bought as Dictionary).has("item") or not (bought as Dictionary).has("price"):
			out.append("every entry in 'buys' has an 'item' and a 'price'.")
			continue
		var id: String = str(bought["item"])
		if (item_of.call(id) as Dictionary).is_empty():
			out.append("'buys' names an unknown item id '%s'." % id)
		if named.has(id):
			out.append("'buys' names '%s' twice." % id)
		named[id] = true
		if not _is_whole(bought["price"], 1):
			out.append("what is paid for '%s' must be a whole number of coins, 1 or more." % id)
	return out


## `crops` (data entries) with the cheapest seed first, and by name where the price is the same.
static func _by_seed_price(crops: Array) -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for crop: Variant in crops:
		if typeof(crop) == TYPE_DICTIONARY:
			out.append(crop)
	out.sort_custom(func(a: Dictionary, b: Dictionary) -> bool:
		if int(a.get("seed_price", 0)) != int(b.get("seed_price", 0)):
			return int(a.get("seed_price", 0)) < int(b.get("seed_price", 0))
		return str(a.get("id", "")) < str(b.get("id", "")))
	return out


static func _is_whole(value: Variant, least: int) -> bool:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return false
	return float(value) >= float(least) and float(value) == roundf(float(value))
