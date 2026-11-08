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


## Puts the item in the inventory. Returns false if it was already taken.
func take() -> bool:
	if taken():
		return false
	GameState.add_item(item_id, count)
	GameState.set_flag(taken_flag, true)
	queue_redraw()
	return true


func _draw() -> void:
	if taken():
		return
	# A faint glow so it can be spotted, then the item by type.
	draw_circle(Vector2(8, 9), 6.5, Color(1.0, 0.85, 0.4, 0.18))
	match str(DataRegistry.get_item(item_id).get("type", "")):
		"weapon_melee":
			_draw_sword()
		"weapon_ranged":
			_draw_bow()
		"ammo":
			_draw_arrows()
		"bomb":
			_draw_bomb()
		_:
			_draw_token()


func _draw_bow() -> void:
	draw_arc(Vector2(6, 9), 6.0, -PI / 2.0, PI / 2.0, 10, Color(0.10, 0.08, 0.12), 3.0)
	draw_arc(Vector2(6, 9), 6.0, -PI / 2.0, PI / 2.0, 10, Color(0.62, 0.40, 0.20), 1.0)
	draw_line(Vector2(6, 3), Vector2(6, 15), Color(0.92, 0.90, 0.84), 1.0)


func _draw_arrows() -> void:
	for i: int in 3:
		var x: float = 5.0 + i * 3.0
		draw_line(Vector2(x, 14), Vector2(x, 4), Color(0.85, 0.78, 0.62), 1.0)
		draw_line(Vector2(x, 4), Vector2(x, 3), Color(0.75, 0.78, 0.82), 2.0)
		draw_line(Vector2(x - 1, 14), Vector2(x + 1, 14), Color(0.85, 0.30, 0.25), 1.0)


func _draw_bomb() -> void:
	draw_circle(Vector2(8, 10), 5.0, Color(0.10, 0.08, 0.12))
	draw_circle(Vector2(8, 10), 4.0, Color(0.20, 0.24, 0.40))
	draw_line(Vector2(10, 6), Vector2(12, 3), Color(0.85, 0.75, 0.55), 1.0)


## A short sword lying on the ground, point up and to the right.
func _draw_sword() -> void:
	var outline: Color = Color(0.10, 0.08, 0.12)
	draw_line(Vector2(4, 13), Vector2(13, 4), outline, 3.0)
	draw_line(Vector2(6, 11), Vector2(13, 4), Color(0.86, 0.88, 0.92), 1.0)
	draw_line(Vector2(3, 9), Vector2(8, 14), outline, 3.0)
	draw_line(Vector2(4, 10), Vector2(7, 13), Color(0.55, 0.36, 0.18), 1.0)
	draw_line(Vector2(3, 14), Vector2(5, 12), Color(0.55, 0.36, 0.18), 2.0)


## A brass token with a glint, for anything without its own picture yet.
func _draw_token() -> void:
	draw_circle(Vector2(8, 9), 4.5, Color(0.10, 0.08, 0.12))
	draw_circle(Vector2(8, 9), 3.5, Color(0.86, 0.66, 0.26))
	draw_line(Vector2(6, 7), Vector2(7, 6), Color(1, 0.95, 0.75), 1.0)
