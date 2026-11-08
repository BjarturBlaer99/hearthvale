class_name HurtBox
extends Node2D
## Where something can be hit (docs/TECH_DESIGN.md §4): a circle of `radius` around this node,
## on a team. HitBoxes of the other team that touch it deliver Hits through `hit_taken`; the
## owner decides what a hit does (hearts and knockback for the hero, a wobble for the dummy).

signal hit_taken(hit: Hit)

const GROUP: StringName = &"hurt_boxes"

@export var radius: float = 5.0
## &"hero" or &"enemy". Hits only come from the other team.
@export var team: StringName = &"enemy"
@export var enabled: bool = true


func _enter_tree() -> void:
	add_to_group(GROUP)


func receive(hit: Hit) -> void:
	hit_taken.emit(hit)
