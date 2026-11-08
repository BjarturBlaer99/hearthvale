class_name DropTable
extends RefCounted
## Picks what a beaten enemy drops (docs/data/enemy.schema.json): one entry of its weighted
## `drops` table, e.g. { "type": "heart" }, { "type": "item", "item": "coin", "count": 1 } or
## { "type": "nothing" }. Pure: the caller supplies the random number.


## The entry `roll` (0 <= roll < 1) lands on, walking the table in order with each entry
## taking its share of the total weight. An empty table gives an empty dictionary.
static func roll(drops: Array, roll_value: float) -> Dictionary:
	var total: float = 0.0
	for entry: Variant in drops:
		total += _weight(entry)
	if total <= 0.0:
		return {}
	var point: float = clampf(roll_value, 0.0, 0.999999) * total
	for entry: Variant in drops:
		var weight: float = _weight(entry)
		if point < weight:
			return entry
		point -= weight
	return drops.back() if typeof(drops.back()) == TYPE_DICTIONARY else {}


static func _weight(entry: Variant) -> float:
	if typeof(entry) != TYPE_DICTIONARY:
		return 0.0
	return maxf(float((entry as Dictionary).get("weight", 0.0)), 0.0)
