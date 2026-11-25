class_name Sword
extends HitBox
## The hero's sword: an arc-shaped HitBox in front of the hero, switched on for one swing.
## Its damage and knockback come from the weapon's data. Draws the swing in code: a blade
## sweeping across the arc, with a faint trail. The blade takes the colour of the weapon's
## picture (ItemIcons): wood for the Wooden Sword, steel for the Iron Sword.

## Blade colours by the weapon's picture; anything else swings WOOD.
const BLADES: Dictionary = {&"sword": Color(0.84, 0.66, 0.42), &"iron_sword": Color(0.86, 0.88, 0.92)}
const WOOD: Color = Color(0.84, 0.66, 0.42)
const EDGE: Color = Color(0.10, 0.08, 0.12)
const HILT: Color = Color(0.55, 0.36, 0.18)
const TRAIL: Color = Color(1.0, 1.0, 1.0, 0.35)
## Where the hand is, relative to the hero's feet: at his belt. Only the drawing uses it; the
## arc that hits is measured from his feet, as it always was.
const HAND: Vector2 = Vector2(0.0, -11.0)
## The drawn blade grows with the reach (13 px at the old 20, 18 at 28), so a longer reach shows.
const BLADE_LENGTH: float = CombatRules.SWORD_REACH * 0.65
## How faint the sweep at the reach is: the ground the swing covers, drawn round his feet.
const SWEEP: Color = Color(1.0, 1.0, 1.0, 0.22)

## How far through the swing, 0 to 1 (the hero's controller sets it every frame).
var progress: float = 0.0
## The colour of the blade being swung.
var blade: Color = WOOD
## The area's ground (the hero's controller sets it): a blow stops at a wall or a closed door,
## as an arrow does. Without it (a bare test) nothing stands in the way.
var terrain: TerrainQuery


func _init() -> void:
	team = &"hero"
	kind = &"sword"
	radius = CombatRules.SWORD_REACH
	arc_degrees = CombatRules.SWORD_ARC_DEGREES
	once_per_activation = true
	active = false


## Starts a swing toward `direction` with the weapon's stats; `picture` is the weapon's
## picture (ItemIcons), which decides the blade's colour.
func swing(direction: Vector2, stats: Dictionary, picture: StringName = &"sword") -> void:
	blade = BLADES.get(picture, WOOD)
	damage = int(stats.get("damage", 1))
	knockback = float(stats.get("knockback", 0.0))
	progress = 0.0
	activate(direction)
	queue_redraw()


## In the arc, and nothing between his feet and the target that stops a blow: a wall, a closed
## door, or higher ground (TerrainQuery.stops_blow; 2026-11-25).
func touches(hurt_box: HurtBox) -> bool:
	if not super(hurt_box):
		return false
	if terrain == null:
		return true
	# Measured in the area's own cells: from his feet to the target, whatever the area's offset.
	var feet: Vector2 = (get_parent() as Node2D).position if get_parent() is Node2D else global_position
	var target: Vector2 = feet + (hurt_box.global_position - global_position)
	var level: int = terrain.standing_level(GridBody.cell_of(feet))
	return CombatRules.clear_between(feet, target, func(cell: Vector2i) -> bool: return terrain.stops_blow(cell, level))


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
		# The ground the blow covers: a faint sweep at the reach, round his feet.
		draw_arc(Vector2.ZERO, radius - 1.0, start, angle, 16, SWEEP, 2.0)
	var along: Vector2 = Vector2.RIGHT.rotated(angle)
	var tip: Vector2 = HAND + along * BLADE_LENGTH
	var guard: Vector2 = HAND + along * 3.0
	draw_line(guard, tip, EDGE, 3.0)
	draw_line(guard, tip, blade, 1.0)
	var across: Vector2 = along.orthogonal() * 2.5
	draw_line(guard - across, guard + across, HILT, 2.0)
