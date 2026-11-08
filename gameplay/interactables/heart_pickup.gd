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
	queue_redraw()
	return true


func _draw() -> void:
	if taken:
		return
	draw_circle(CENTER + Vector2(0, 5), 3.0, Color(0, 0, 0, 0.25))
	var outline: PackedVector2Array = [Vector2(8, 13), Vector2(2, 7), Vector2(2, 4), Vector2(4, 2), Vector2(6, 2), Vector2(8, 4), Vector2(10, 2), Vector2(12, 2), Vector2(14, 4), Vector2(14, 7)]
	draw_colored_polygon(outline, OUTLINE)
	var heart: PackedVector2Array = [Vector2(8, 11.5), Vector2(3, 6.5), Vector2(3, 4.5), Vector2(4.5, 3), Vector2(5.5, 3), Vector2(8, 5.5), Vector2(10.5, 3), Vector2(11.5, 3), Vector2(13, 4.5), Vector2(13, 6.5)]
	draw_colored_polygon(heart, RED)
	draw_rect(Rect2(4, 4, 1, 1), Color(1, 0.8, 0.8))
