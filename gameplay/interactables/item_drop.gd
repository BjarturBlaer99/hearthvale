class_name ItemDrop
extends Node2D
## Something an enemy dropped (coins, or a bundle of arrows): touch it to pick it up. It's gone
## for the rest of the visit and never saved. Position = the cell's top-left corner.

const RADIUS: float = 5.0
const CENTER: Vector2 = Vector2(8.0, 9.0)
const OUTLINE: Color = PixelGrade.INK
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
	EventBus.sound.emit(&"coin")
	Burst.spawn(get_parent(), position + CENTER, &"sparkle")
	queue_redraw()
	return true


func _draw() -> void:
	if taken:
		return
	SoftShadow.draw(self, CENTER + Vector2(0, 4), Vector2(3, 1.4))
	if ItemIcons.name_for(item_id) != &"coin":
		ItemIcons.draw(self, ItemIcons.name_for(item_id), Vector2(0, -1))
		return
	# A little pile: up to three coins.
	var coins: int = clampi(count, 1, 3)
	for i: int in coins:
		ItemIcons.draw(self, &"coin", Vector2(roundf((i - (coins - 1) / 2.0) * 3.0), -i))
