class_name SoftShadowNode
extends Node2D
## A SoftShadow as a node, for things built in a scene (the hero): put it under the sprite, at
## the feet.

@export var radii: Vector2 = Vector2(6, 2.6)
@export var strength: float = 1.0


func _draw() -> void:
	SoftShadow.draw(self, Vector2.ZERO, radii, strength)
