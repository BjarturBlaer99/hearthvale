class_name Boss
extends Enemy
## A dungeon boss (docs/TECH_DESIGN.md §5): an Enemy whose brain is a WardenBrain (the Iron
## Warden), drawn big. It keeps to `arena`, its room's floor in cells, and starts the fight over
## (full health, back home) whenever the hero leaves it. If the hero has no arrows when its eye
## opens, ARROW_HELP arrows fall into a far corner of the room, so the fight never strands
## anyone. Blows it shrugs off throw a spark. Give it a `clear_flag` and `stays_beaten`: the
## flag records it beaten (a heart container and the way out wait on it), and it never returns.

const ARROW_HELP: int = 5
## Kept clear of the arena's edges (px), for its bulk.
const ARENA_MARGIN: float = 14.0
const SPARK_TIME: float = 0.15
const IRON: Color = Color(0.46, 0.50, 0.58)
const IRON_DARK: Color = Color(0.28, 0.30, 0.36)
const EYE: Color = Color(1.0, 0.78, 0.25)
const RAGE: Color = Color(0.95, 0.30, 0.20)

## Its room's floor, in cells: where it may go and where the hero must be for it to fight.
@export var arena: Rect2i

var warden: WardenBrain
## The arrows it last let fall (null if none).
var arrow_help: ItemDrop

var _spark_left: float = 0.0


func setup(terrain_query: TerrainQuery, hero: Node2D, rng: RandomNumberGenerator) -> bool:
	if not super(terrain_query, hero, rng):
		return false
	warden = brain as WardenBrain
	if warden == null:
		push_warning("%s: a Boss needs a warden behaviour, not '%s'." % [name, data.get("behaviour", "")])
		brain = null
		return false
	warden.arena = arena_pixels()
	warden.clinked.connect(_on_clinked)
	warden.state_changed.connect(_on_state_changed)
	return true


## The arena in area pixels, less its bulk.
func arena_pixels() -> Rect2:
	return Rect2(Vector2(arena.position) * GridBody.TILE, Vector2(arena.size) * GridBody.TILE).grow(-ARENA_MARGIN)


func hero_in_arena() -> bool:
	return target != null and arena.has_point(GridBody.cell_of(target.position))


func _physics_process(delta: float) -> void:
	_spark_left = maxf(0.0, _spark_left - delta)
	super(delta)


## Fights while the hero is in its room; the moment they leave, it starts over.
func step(delta: float) -> void:
	if brain == null or brain.is_dead():
		return
	if hero_in_arena():
		super(delta)
		return
	if brain.state != EnemyBrain.IDLE or brain.health < brain.max_health or body.position != brain.home:
		warden.reset()
		position = body.position
		queue_redraw()


func _on_clinked() -> void:
	_spark_left = SPARK_TIME
	queue_redraw()


func _on_state_changed(state: StringName) -> void:
	if state == WardenBrain.GAZE and GameState.item_count(&"arrow") <= 0 \
			and (not is_instance_valid(arrow_help) or arrow_help.taken):
		_let_arrows_fall()


## ARROW_HELP arrows land in the arena's corner farthest from it.
func _let_arrows_fall() -> void:
	var corners: Array[Vector2i] = [arena.position, Vector2i(arena.end.x - 1, arena.position.y),
		Vector2i(arena.position.x, arena.end.y - 1), arena.end - Vector2i.ONE]
	var best: Vector2i = corners[0]
	for corner: Vector2i in corners:
		if GridBody.cell_center(corner).distance_to(position) > GridBody.cell_center(best).distance_to(position):
			best = corner
	arrow_help = ItemDrop.new()
	arrow_help.item_id = &"arrow"
	arrow_help.count = ARROW_HELP
	arrow_help.position = Vector2(best) * GridBody.TILE
	get_parent().add_child(arrow_help)


## Its bolts come from the eye and glow.
func _on_shot(direction: Vector2) -> void:
	var shot: Dictionary = data.get("shot", {})
	var bolt: Arrow = Arrow.new()
	bolt.setup(terrain, direction, int(shot.get("damage", 2)), float(shot.get("speed", 110.0)))
	bolt.bolt = true
	bolt.position = body.position + direction * 10.0
	get_parent().add_child(bolt)
	last_arrow = bolt


# --- Drawing (placeholder art) ----------------------------------------------

func _draw() -> void:
	if warden == null:
		return
	if _poof_left > 0.0:
		var spread: float = 1.0 - _poof_left / POOF_TIME
		for offset: Vector2 in [Vector2(0, -16), Vector2(-10, -8), Vector2(10, -8), Vector2(0, -28)]:
			draw_arc(offset, 4.0 + spread * 14.0, 0.0, TAU, 20, Color(1, 1, 1, 1.0 - spread), 2.0)
		return
	var stunned: bool = warden.is_stunned()
	var sink: float = 6.0 if stunned else 0.0
	var stomp: float = absf(sin(_clock * 6.0)) * 1.5 if warden.state == WardenBrain.GUARD else 0.0
	var iron: Color = _tint(IRON)
	var dark: Color = _tint(IRON_DARK)
	_ellipse(Vector2(0, 0), Vector2(14, 4), SHADOW)
	# Legs, then the body: a broad breastplate between round pauldrons.
	for side: float in [-1.0, 1.0]:
		var leg: Rect2 = Rect2(Vector2(side * 7.0 - 4.0, -9.0 + sink * 0.5 - (stomp if side < 0.0 else 0.0)), Vector2(8, 9 - sink * 0.5))
		draw_rect(leg.grow(1.0), OUTLINE)
		draw_rect(leg, dark)
	var top: float = -30.0 + sink
	var chest: PackedVector2Array = [Vector2(-13, top + 4), Vector2(13, top + 4), Vector2(10, -7 + sink * 0.5), Vector2(-10, -7 + sink * 0.5)]
	draw_colored_polygon(_grown(chest, 1.5), OUTLINE)
	draw_colored_polygon(chest, iron)
	draw_line(Vector2(0, top + 6), Vector2(0, -9 + sink * 0.5), dark, 1.0)
	draw_rect(Rect2(-10, top + 14, 20, 2), RAGE if warden.is_raging() else dark)
	for side: float in [-1.0, 1.0]:
		draw_circle(Vector2(side * 13.0, top + 6), 6.0, OUTLINE)
		draw_circle(Vector2(side * 13.0, top + 6), 5.0, iron)
		draw_circle(Vector2(side * 12.0, top + 4), 2.0, iron.lightened(0.3))
	# The helm, tipped forward when stunned, with the eye in its visor.
	var helm: Vector2 = Vector2(warden.facing.x * 2.0 + (sin(_clock * 3.0) * 2.0 if stunned else 0.0), top - 6.0 + (3.0 if stunned else 0.0))
	draw_rect(Rect2(helm + Vector2(-9, -9), Vector2(18, 16)), OUTLINE)
	draw_rect(Rect2(helm + Vector2(-8, -8), Vector2(16, 14)), iron)
	draw_rect(Rect2(helm + Vector2(-8, -8), Vector2(16, 3)), iron.lightened(0.25))
	draw_rect(Rect2(helm + Vector2(-6, -2), Vector2(12, 4)), Color(0.05, 0.04, 0.06))
	var open: float = warden.eye_open()
	if open > 0.0:
		draw_circle(helm, 4.0 + open * 3.0, Color(EYE, 0.25 * open))
		draw_rect(Rect2(helm + Vector2(-3.0 * open - 1.0, -1.5), Vector2(6.0 * open + 2.0, 3)), EYE)
		draw_rect(Rect2(helm + Vector2(-1, -1), Vector2(2, 2)), Color(0.6, 0.1, 0.05))
	elif stunned:
		draw_line(helm + Vector2(-4, 0), helm + Vector2(4, 0), EYE.darkened(0.6), 1.0)
		for i: int in 3:
			var angle: float = _clock * 4.0 + TAU * i / 3.0
			var star: Vector2 = helm + Vector2(cos(angle) * 11.0, -12.0 + sin(angle) * 3.0)
			draw_rect(Rect2(star - Vector2(1, 1), Vector2(2, 2)), Color(1.0, 0.95, 0.5))
	else:
		draw_line(helm + Vector2(-4, 0), helm + Vector2(4, 0), RAGE if warden.is_raging() else EYE.darkened(0.4), 1.0)
	if _spark_left > 0.0:
		var spark: Vector2 = Vector2(warden.facing.x * 10.0, top + 10.0 + maxf(warden.facing.y, 0.0) * 6.0)
		var size: float = 3.0 + (1.0 - _spark_left / SPARK_TIME) * 4.0
		draw_line(spark - Vector2(size, 0), spark + Vector2(size, 0), Color.WHITE, 1.0)
		draw_line(spark - Vector2(0, size), spark + Vector2(0, size), Color.WHITE, 1.0)
		draw_line(spark - Vector2(size, size) * 0.6, spark + Vector2(size, size) * 0.6, Color(1, 0.95, 0.6), 1.0)
		draw_line(spark - Vector2(size, -size) * 0.6, spark + Vector2(size, -size) * 0.6, Color(1, 0.95, 0.6), 1.0)


## `points` pushed out from their middle by `by` px (a rough outline for a convex shape).
func _grown(points: PackedVector2Array, by: float) -> PackedVector2Array:
	var middle: Vector2 = Vector2.ZERO
	for point: Vector2 in points:
		middle += point
	middle /= points.size()
	var out: PackedVector2Array = []
	for point: Vector2 in points:
		out.append(point + (point - middle).normalized() * by)
	return out
