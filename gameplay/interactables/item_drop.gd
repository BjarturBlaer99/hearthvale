class_name ItemDrop
extends Node2D
## Something an enemy dropped (coins for now): touch it to pick it up. It's gone for the
## rest of the visit and never saved. Position = the cell's top-left corner.

const RADIUS: float = 5.0
const CENTER: Vector2 = Vector2(8.0, 9.0)
const OUTLINE: Color = Color(0.10, 0.08, 0.12)
const GOLD: Color = Color(0.95, 0.76, 0.24)

@export var item_id: StringName = &"coin"
@export var count: int = 1

var taken: bool = false


## Whether a circle at `point` (area pixels) with `radius` touches it, while it's there.
func touches(point: Vector2, radius: float) -> bool:
	return not taken and CombatRules.circles_touch(global_position + CENTER, RADIUS, point, radius)


## Puts it in the inventory and disappears. Returns false if it was already taken.
func collect() -> bool:
	if taken:
		return false
	taken = true
	GameState.add_item(item_id, count)
	queue_redraw()
	return true


func _draw() -> void:
	if taken:
		return
	draw_circle(CENTER + Vector2(0, 4), 3.0, Color(0, 0, 0, 0.25))
	var coins: int = clampi(count, 1, 3)
	for i: int in coins:
		var at: Vector2 = CENTER + Vector2((i - (coins - 1) / 2.0) * 3.0, -i)
		draw_circle(at, 3.5, OUTLINE)
		draw_circle(at, 2.5, GOLD)
		draw_rect(Rect2(at + Vector2(-1, -1), Vector2(1, 1)), Color(1, 0.95, 0.7))
