class_name Brambles
extends Node2D
## A thorny bush: touching it costs half a heart and knocks the hero back (its HitBox child,
## on the enemy team). It doesn't fill its cell, so an invincible hero can push into it.
## Position = the cell's top-left corner.

const OUTLINE: Color = Color(0.10, 0.08, 0.12)
const LEAF: Color = Color(0.24, 0.36, 0.16)
const THORN: Color = Color(0.82, 0.78, 0.62)
const BERRY: Color = Color(0.55, 0.12, 0.25)

const CLUMPS: Array[Vector3] = [Vector3(5, 9, 4.0), Vector3(11, 9, 4.0), Vector3(8, 6, 4.5), Vector3(8, 11, 3.5)]
const THORNS: Array[Vector2] = [Vector2(2, 7), Vector2(14, 8), Vector2(7, 2), Vector2(11, 3), Vector2(4, 13), Vector2(12, 13)]


func cell() -> Vector2i:
	return PlayerMotor.cell_of(position + Vector2(0.5, 0.5))


func covers(at: Vector2i) -> bool:
	return at == cell()


func _draw() -> void:
	for clump: Vector3 in CLUMPS:
		draw_circle(Vector2(clump.x, clump.y), clump.z + 1.0, OUTLINE)
	for clump: Vector3 in CLUMPS:
		draw_circle(Vector2(clump.x, clump.y), clump.z, LEAF)
		draw_circle(Vector2(clump.x - 1.0, clump.y - 1.0), clump.z * 0.45, LEAF.lightened(0.2))
	for thorn: Vector2 in THORNS:
		var inward: Vector2 = (Vector2(8, 8) - thorn).normalized() * 3.0
		draw_line(thorn, thorn + inward, THORN, 1.0)
	for berry: Vector2 in [Vector2(6, 7), Vector2(10, 11), Vector2(11, 6)]:
		draw_rect(Rect2(berry, Vector2(1, 1)), BERRY)
