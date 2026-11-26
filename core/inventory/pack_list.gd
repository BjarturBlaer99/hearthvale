class_name PackList
extends RefCounted
## The Tab menu's "Pack" (icons, an axe and the item bar, step I2), pure: everything the hero
## carries, to look at only, in the pack's order, and each stack as its line reads. What a tool
## holds (the can's water) is in the tool, not the pack: it is said on the tool's line
## ("Watering Can (Water x10)"), not on a line of its own. Works on stacks in
## GameState.inventory's shape ({ "id", "count" }) and item entries from data.


## The items that `stacks` hold, looked up in `items` (data entries), in the pack's order. A
## stack of none isn't there, nor what a tool holds; an id with no data is still listed, by its id.
static func entries(stacks: Array, items: Array) -> Array[Dictionary]:
	var by_id: Dictionary = {}
	for item: Variant in items:
		if typeof(item) == TYPE_DICTIONARY:
			by_id[str((item as Dictionary).get("id", ""))] = item
	var in_tools: Array[String] = Inventory.held_in_tools(items)
	var out: Array[Dictionary] = []
	for stack: Variant in stacks:
		if typeof(stack) != TYPE_DICTIONARY:
			continue
		var id: String = str((stack as Dictionary).get("id", ""))
		if int((stack as Dictionary).get("count", 0)) <= 0 or in_tools.has(id):
			continue
		out.append(by_id.get(id, {"id": id, "name": id}))
	return out


## What `item` holds in itself, if anything (the can's water): the id of that, else "". Only a
## tool's ammo is held in the tool; a bow's arrows and a bomb are stacks of their own.
static func holds(item: Dictionary) -> String:
	return Inventory.ammo_for(item) if str(item.get("type", "")) == "tool" else ""


## A stack as the Pack's line reads it: "120 coins", "Stone x9", "Pickaxe", and for a tool that
## holds something, what it holds ("Watering Can (Water x10)"). `holds_name` and `holds_count`
## are what it holds ("" if nothing).
static func line(item: Dictionary, count: int, holds_name: String = "", holds_count: int = 0) -> String:
	var name_text: String = str(item.get("name", item.get("id", "?")))
	if str(item.get("type", "")) == "currency":
		return Shop.coins_text(count)
	var words: String = "%s x%d" % [name_text, count] if bool(item.get("stackable", false)) or count > 1 else name_text
	if not holds_name.is_empty():
		words += " (%s x%d)" % [holds_name, holds_count]
	return words
