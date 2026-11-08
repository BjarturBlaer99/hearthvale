class_name Hit
extends RefCounted
## One blow landing (docs/TECH_DESIGN.md §4): how much it hurts, which way and how far it
## pushes, and where it came from. A HitBox makes one for each HurtBox it touches.

## Half hearts against the hero; health points against anything else.
var damage: int = 0
## Knockback: direction times distance in px.
var push: Vector2 = Vector2.ZERO
## Where the blow came from, in area pixels.
var source: Vector2 = Vector2.ZERO


func _init(hit_damage: int = 0, hit_push: Vector2 = Vector2.ZERO, hit_source: Vector2 = Vector2.ZERO) -> void:
	damage = hit_damage
	push = hit_push
	source = hit_source
