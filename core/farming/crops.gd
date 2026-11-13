class_name Crops
extends RefCounted
## Crops (P3b, GDD §7), pure: what the data says about one (data/crops/<id>.json):
##   { "id": "turnip", "name": "Turnip", "days": 3, "seed": "turnip_seeds",
##     "gives": { "item": "turnip", "count": 1 }, "seed_price": 5, "sells_for": 12 }
## `days` is how many watered mornings it takes to ripen; `seed` the item that plants it (an
## item of type "seed" whose stats name this crop); `gives` what a harvest puts in the pack;
## the prices are Tilda's (3c). Farm does the growing; this reads the entries and checks them.

## The item type that plants a crop.
const SEED_TYPE: String = "seed"


## How many watered mornings `crop` takes to ripen.
static func days_of(crop: Dictionary) -> int:
	return maxi(int(crop.get("days", 1)), 1)


## How many mornings each of `crops` (data entries) takes: crop id -> days, for Farm.new_day().
static func days_by_id(crops: Array) -> Dictionary:
	var out: Dictionary = {}
	for crop: Variant in crops:
		if typeof(crop) == TYPE_DICTIONARY:
			out[str((crop as Dictionary).get("id", ""))] = days_of(crop)
	return out


## What a harvest of `crop` gives: { "item": id, "count": n }.
static func gives(crop: Dictionary) -> Dictionary:
	var given: Variant = crop.get("gives", {})
	if typeof(given) != TYPE_DICTIONARY:
		return {"item": "", "count": 0}
	return {"item": str((given as Dictionary).get("item", "")), "count": maxi(int((given as Dictionary).get("count", 1)), 1)}


static func is_seed(item: Dictionary) -> bool:
	return str(item.get("type", "")) == SEED_TYPE


## The crop a seed item plants (a crop id), or "" if `item` is no seed.
static func crop_of_seed(item: Dictionary) -> String:
	var stats: Variant = item.get("stats", {})
	if not is_seed(item) or typeof(stats) != TYPE_DICTIONARY:
		return ""
	return str((stats as Dictionary).get("crop", ""))


## What is wrong with `crop`, in words: nothing, if it can be grown. `item_of` gives the item
## entry for an id (empty if there is none).
static func problems(crop: Dictionary, item_of: Callable) -> PackedStringArray:
	var out: PackedStringArray = []
	if not _is_whole(crop.get("days"), 1):
		out.append("'days' must be a whole number of 1 or more: the watered mornings it takes to ripen.")
	var seed: Dictionary = item_of.call(str(crop.get("seed", "")))
	if seed.is_empty():
		out.append("'seed' names an unknown item id '%s'." % crop.get("seed", ""))
	elif crop_of_seed(seed) != str(crop.get("id", "")):
		out.append("'seed' must be an item of type 'seed' whose stats name this crop ('%s' doesn't)." % crop.get("seed", ""))
	var given: Variant = crop.get("gives")
	if typeof(given) != TYPE_DICTIONARY or not (given as Dictionary).has("item"):
		out.append("'gives' must name the 'item' a harvest gives.")
	else:
		if (item_of.call(str(given["item"])) as Dictionary).is_empty():
			out.append("'gives' names an unknown item id '%s'." % given["item"])
		if not _is_whole((given as Dictionary).get("count", 1), 1):
			out.append("'gives' 'count' must be a whole number of 1 or more.")
	for price: String in ["seed_price", "sells_for"]:
		if not _is_whole(crop.get(price), 0):
			out.append("'%s' must be a whole number of coins, 0 or more." % price)
	return out


## What is wrong with the seed `item`, in words. `is_crop` says whether a crop id is known.
static func seed_problems(item: Dictionary, is_crop: Callable) -> PackedStringArray:
	var out: PackedStringArray = []
	if crop_of_seed(item).is_empty():
		out.append("a seed's stats must name the 'crop' it plants.")
	elif not is_crop.call(crop_of_seed(item)):
		out.append("a seed's 'crop' names an unknown crop id '%s'." % crop_of_seed(item))
	return out


static func _is_whole(value: Variant, least: int) -> bool:
	if typeof(value) != TYPE_INT and typeof(value) != TYPE_FLOAT:
		return false
	return float(value) >= float(least) and float(value) == roundf(float(value))
