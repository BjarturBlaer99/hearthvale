class_name Brambles
extends Node2D
## A thorny bush: touching it costs half a heart and knocks the hero back (its HitBox child,
## on the enemy team). It doesn't fill its cell, so an invincible hero can push into it.
## Position = the cell's top-left corner.

const SHEET: Texture2D = preload("res://gameplay/art/brambles.png")



func cell() -> Vector2i:
	return PlayerMotor.cell_of(position + Vector2(0.5, 0.5))


func covers(at: Vector2i) -> bool:
	return at == cell()


func _draw() -> void:
	SpriteSheet.draw(self, SHEET, 0, Vector2i(16, 16), Vector2.ZERO)
