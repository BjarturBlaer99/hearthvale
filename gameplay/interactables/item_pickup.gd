class_name ItemPickup
extends Node2D
## An item lying in the world. Stand on it and press interact to take it; `taken_flag` in
## GameState remembers it's gone, on every visit. Position = the cell's top-left corner.

@export var item_id: StringName
@export var count: int = 1
@export var taken_flag: StringName


func cell() -> Vector2i:
	return PlayerMotor.cell_of(position + Vector2(0.5, 0.5))


## Taken items cover nothing: there's nothing left to stand on.
func covers(at: Vector2i) -> bool:
	return not taken() and at == cell()


func taken() -> bool:
	return GameState.get_flag(taken_flag) == true


func item_name() -> String:
	return str(DataRegistry.get_item(item_id).get("name", item_id))


## Whether the pack has room for all of it. If not it is left lying: nothing is lost to a full
## pack.
func has_room() -> bool:
	return GameState.has_room_for(item_id, count)


## Puts the item in the inventory. Returns false if it was already taken, or there is no room
## for it.
func take() -> bool:
	if taken() or not has_room():
		return false
	GameState.add_item(item_id, count)
	GameState.set_flag(taken_flag, true)
	EventBus.sound.emit(&"item_get")
	Burst.spawn(get_parent(), position + Vector2(8, 8), &"sparkle")
	queue_redraw()
	return true


func _draw() -> void:
	if taken():
		return
	# A faint glow so it can be spotted, then the item's picture.
	draw_circle(Vector2(8, 9), 6.5, Color(1.0, 0.85, 0.4, 0.18))
	ItemIcons.draw(self, ItemIcons.name_for(item_id))
