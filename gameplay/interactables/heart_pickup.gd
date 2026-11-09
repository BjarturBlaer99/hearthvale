class_name HeartPickup
extends Node2D
## A recovery heart on the ground: touch it to get `halves` half hearts back. It's gone for the
## rest of the visit and back on the next one (not saved), like the hearts grass and enemies
## will drop. Position = the cell's top-left corner.

const RADIUS: float = 5.0
const CENTER: Vector2 = Vector2(8.0, 8.0)
const OUTLINE: Color = Color(0.10, 0.08, 0.12)
const RED: Color = Color(0.86, 0.16, 0.20)

@export var halves: int = 2

var taken: bool = false


func cell() -> Vector2i:
	return PlayerMotor.cell_of(position + Vector2(0.5, 0.5))


## Whether a circle at `point` (area pixels) with `radius` touches the heart, while it's there.
func touches(point: Vector2, radius: float) -> bool:
	return not taken and CombatRules.circles_touch(global_position + CENTER, RADIUS, point, radius)


## Heals the hero and disappears. Returns false if it was already taken.
func collect() -> bool:
	if taken:
		return false
	taken = true
	GameState.heal(halves)
	EventBus.sound.emit(&"heart")
	Burst.spawn(get_parent(), position + CENTER, &"sparkle")
	queue_redraw()
	return true


func _draw() -> void:
	if taken:
		return
	draw_circle(CENTER + Vector2(0, 5), 3.0, Color(0, 0, 0, 0.25))
	ItemIcons.draw(self, &"heart")
