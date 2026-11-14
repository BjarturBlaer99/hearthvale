class_name Hearth
extends Talkable
## The hearth at the hero's home (P2d, GDD §6): face it and press interact, and it lists what
## can be cooked. Its words aren't a file in data/dialogue: the list is built from the recipes
## in data/recipes that he knows (Cooking.dialogue), and cooking is the shared give and take effects. Draws
## nothing: the hearth is a tile of the room. Position = its cell's top-left corner.


func prompt() -> String:
	return "Cook"


## The hearth's list: an answer for every recipe he knows.
func dialogue() -> Dictionary:
	var items: Dictionary = {}
	for item: Dictionary in DataRegistry.entries(&"items"):
		items[str(item["id"])] = item
	return Cooking.dialogue(GameState.known_recipes(), items)
