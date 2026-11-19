class_name PlacedThing
extends Node2D
## Something the hero has set down that stands on his land (the Homestead, phase 2;
## docs/TECH_DESIGN.md §30): a fence, a gate, a hedge, a lamp post, a bench, a sapling. What
## it is, is its item's data (Placement); where it is and how old, GameState.homestead() says.
## PlacedThings makes one for every standing thing and takes it away again; this only draws
## it, joined to its neighbours, with a shadow at its foot. It is sorted with the hero and
## everyone else by where it stands, so he walks before it and behind it.
## Position = the top-left corner of its cell.

## Which item it is, that item's data, and the mornings it has stood (a sapling's).
var item_id: StringName = &""
var item: Dictionary = {}
var age: int = 0


## Shows it as `id` after `mornings`.
func show_as(id: StringName, mornings: int = 0) -> void:
	item_id = id
	item = DataRegistry.get_item(id)
	age = mornings
	queue_redraw()


func cell() -> Vector2i:
	return PlayerMotor.cell_of(position + Vector2(0.5, 0.5))


## Whether it fills its cell (a gate doesn't).
func blocks() -> bool:
	return Placement.blocks(item)


## The neighbours it runs on to (PlacedArt's bits).
func joined() -> int:
	return joined_at(cell(), item)


## The neighbours a `thing` (a placeable's data) standing in `at` runs on to (PlacedArt's
## bits): those that stand beside it and join, as it does. None, for a thing that doesn't join.
static func joined_at(at: Vector2i, thing: Dictionary) -> int:
	if not Placement.joins(thing):
		return 0
	var out: int = 0
	for way: Array in PlacedArt.WAYS:
		var beside: StringName = GameState.homestead().standing_at(at + (way[0] as Vector2i))
		if beside != &"" and Placement.joins(DataRegistry.get_item(beside)):
			out |= int(way[1])
	return out


func _draw() -> void:
	if item.is_empty():
		return
	SoftShadow.draw(self, Vector2(8, 14), Vector2(6, 1.6), 0.8)
	PlacedArt.draw_thing(self, item, age, Vector2.ZERO, joined())
