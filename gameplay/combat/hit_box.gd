class_name HitBox
extends Node2D
## Something that hurts what it touches (docs/TECH_DESIGN.md §4): a circle of `radius` around
## this node or, with `arc_degrees` under 360, a slice of it pointing along `facing` (the
## sword's swing). While `active` it hits HurtBoxes of the other team; the area checks contacts
## every physics frame (AreaController.resolve_combat). With `once_per_activation`, each target
## is hit at most once between activate() calls; otherwise the target's invincibility decides.

## A hit was just delivered to `hurt_box` (arrows stop on this).
signal landed(hurt_box: HurtBox)

const GROUP: StringName = &"hit_boxes"

@export var radius: float = 6.0
## &"hero" or &"enemy".
@export var team: StringName = &"enemy"
## Half hearts against the hero; health points against anything else.
@export var damage: int = 1
## How far a hit pushes the target (px).
@export var knockback: float = 32.0
@export var arc_degrees: float = 360.0
@export var active: bool = true
@export var once_per_activation: bool = false
## What its hits are: &"sword", &"arrow", &"bomb" or &"contact".
@export var kind: StringName = &"contact"
## Energy a hit takes from the hero, as well as its damage (a Bogwisp's touch).
@export var energy: float = 0.0

## The way an arc points.
var facing: Vector2 = Vector2.DOWN

var _already_hit: Dictionary[int, bool] = {}


func _enter_tree() -> void:
	add_to_group(GROUP)


## Switches on (pointing along `direction`), forgetting who was hit before.
func activate(direction: Vector2 = facing) -> void:
	facing = direction
	active = true
	_already_hit.clear()


func deactivate() -> void:
	active = false


func touches(hurt_box: HurtBox) -> bool:
	if arc_degrees >= 360.0:
		return CombatRules.circles_touch(global_position, radius, hurt_box.global_position, hurt_box.radius)
	return CombatRules.in_arc(global_position, facing, deg_to_rad(arc_degrees), radius, hurt_box.global_position, hurt_box.radius)


## Hits `hurt_box` if it can: both on, different teams, touching, and not already hit this
## activation (when that matters). Returns whether a hit was delivered.
func try_hit(hurt_box: HurtBox) -> bool:
	if not active or not hurt_box.enabled or hurt_box.team == team or not touches(hurt_box):
		return false
	if once_per_activation:
		var id: int = hurt_box.get_instance_id()
		if _already_hit.has(id):
			return false
		_already_hit[id] = true
	var push: Vector2 = CombatRules.push(global_position, hurt_box.global_position, knockback, facing)
	var hit: Hit = Hit.new(damage, push, global_position, kind)
	hit.energy = energy
	hurt_box.receive(hit)
	landed.emit(hurt_box)
	return true
