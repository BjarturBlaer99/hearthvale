class_name Sword
extends HitBox
## The hero's sword: an arc-shaped HitBox in front of the hero, switched on for one swing.
## Its damage and knockback come from the weapon's data. Draws the swing in code: a blade
## sweeping across the arc, with a faint trail.

const BLADE: Color = Color(0.86, 0.88, 0.92)
const EDGE: Color = Color(0.10, 0.08, 0.12)
const HILT: Color = Color(0.55, 0.36, 0.18)
const TRAIL: Color = Color(1.0, 1.0, 1.0, 0.35)
## Where the hand is, relative to the hero's feet.
const HAND: Vector2 = Vector2(0.0, -6.0)
const BLADE_LENGTH: float = 13.0

## How far through the swing, 0 to 1 (the hero's controller sets it every frame).
var progress: float = 0.0


func _init() -> void:
	team = &"hero"
	radius = CombatRules.SWORD_REACH
	arc_degrees = CombatRules.SWORD_ARC_DEGREES
	once_per_activation = true
	active = false


## Starts a swing toward `direction` with the weapon's stats.
func swing(direction: Vector2, stats: Dictionary) -> void:
	damage = int(stats.get("damage", 1))
	knockback = float(stats.get("knockback", 0.0))
	progress = 0.0
	activate(direction)
	queue_redraw()


func end_swing() -> void:
	deactivate()
	queue_redraw()


func _draw() -> void:
	if not active:
		return
	var half: float = deg_to_rad(arc_degrees) / 2.0
	var start: float = facing.angle() - half
	var angle: float = start + 2.0 * half * progress
	if angle - start > 0.05:
		draw_arc(HAND, BLADE_LENGTH - 2.0, start, angle, 12, TRAIL, 3.0)
	var along: Vector2 = Vector2.RIGHT.rotated(angle)
	var tip: Vector2 = HAND + along * BLADE_LENGTH
	var guard: Vector2 = HAND + along * 3.0
	draw_line(guard, tip, EDGE, 3.0)
	draw_line(guard, tip, BLADE, 1.0)
	var across: Vector2 = along.orthogonal() * 2.5
	draw_line(guard - across, guard + across, HILT, 2.0)
