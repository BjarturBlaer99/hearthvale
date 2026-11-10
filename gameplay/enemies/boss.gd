class_name Boss
extends ArenaBoss
## The Iron Warden, the keep's boss (docs/TECH_DESIGN.md §5): an ArenaBoss whose brain is a
## WardenBrain, drawn big from its pixel art. If the hero has no arrows when its eye opens,
## ARROW_HELP arrows fall into a far corner of the room, so the fight never strands anyone.
## Blows it shrugs off throw a spark.

const ARROW_HELP: int = 5
const SPARK_TIME: float = 0.15
## While guarding it stomps (a thud and a small shake) this often.
const STOMP_EVERY: float = 0.5
const IRON: Color = Color(0.46, 0.50, 0.58)
const IRON_DARK: Color = Color(0.28, 0.30, 0.36)
const EYE: Color = Color(1.0, 0.78, 0.25)
const RAGE: Color = Color(0.95, 0.30, 0.20)

var warden: WardenBrain
## The arrows it last let fall (null if none).
var arrow_help: ItemDrop

var _spark_left: float = 0.0
var _stomp_left: float = 0.0


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


func _physics_process(delta: float) -> void:
	_spark_left = maxf(0.0, _spark_left - delta)
	super(delta)


func _fight(delta: float) -> void:
	_stomp(delta)


func _start_over() -> void:
	warden.reset()


## A thud and a little shake every STOMP_EVERY seconds while it guards.
func _stomp(delta: float) -> void:
	if brain.state != WardenBrain.GUARD:
		_stomp_left = 0.0
		return
	_stomp_left -= delta
	if _stomp_left <= 0.0:
		_stomp_left = STOMP_EVERY
		EventBus.sound.emit(&"stomp")
		EventBus.shake.emit(1.0, 0.08)


func _on_clinked() -> void:
	_spark_left = SPARK_TIME
	EventBus.sound.emit(&"clink")
	Burst.spawn(get_parent(), position + Vector2(warden.facing.x * 10.0, -18.0), &"spark")
	queue_redraw()


func _on_state_changed(state: StringName) -> void:
	match state:
		WardenBrain.GUARD:
			wake()
		WardenBrain.GAZE:
			EventBus.sound.emit(&"gaze")
		WardenBrain.STUNNED:
			EventBus.sound.emit(&"stun")
			EventBus.hit_stop.emit(0.12)
			EventBus.shake.emit(2.0, 0.2)
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


# --- Drawing (pixel art painted by tools/art/make_sprites.gd) ------------------

const SHEET: Texture2D = preload("res://gameplay/art/warden.png")
## Frames in the order the tool paints them (a test checks).
const FRAMES: Dictionary = {&"stand": 0, &"step": 1, &"gaze": 2, &"stunned": 3}
const SIZE: Vector2i = Vector2i(32, 40)
## Raging, its iron glows a little red.
const RAGE_TINT: Color = Color(1.0, 0.76, 0.72)
## Where its eye sits, from its feet.
const EYE_AT: Vector2 = Vector2(0, -31.5)


func _draw() -> void:
	if warden == null:
		return
	if _poof_left > 0.0:
		var spread: float = 1.0 - _poof_left / POOF_TIME
		for offset: Vector2 in [Vector2(0, -16), Vector2(-10, -8), Vector2(10, -8), Vector2(0, -28)]:
			draw_arc(offset, 4.0 + spread * 14.0, 0.0, TAU, 20, Color(1, 1, 1, 1.0 - spread), 2.0)
		return
	_ellipse(Vector2(0, 0), Vector2(14, 4), SHADOW)
	var frame: StringName = &"stand"
	var flip: bool = false
	if warden.is_stunned():
		frame = &"stunned"
	elif warden.state == WardenBrain.GAZE:
		frame = &"gaze"
	elif warden.state == WardenBrain.GUARD:
		# Stomping: stand, left foot up, stand, right foot up (the step frame mirrored).
		var beat: int = int(_clock * 4.0) % 4
		frame = &"step" if beat % 2 == 1 else &"stand"
		flip = beat == 3
	var tint: Color = RAGE_TINT if warden.is_raging() else Color.WHITE
	SpriteSheet.draw(self, SHEET, FRAMES[frame], SIZE, Vector2(-16, -39), flip, _flash_left > 0.0, tint)
	var open: float = warden.eye_open()
	if open > 0.0:
		draw_circle(EYE_AT, 4.0 + open * 3.0, Color(EYE, 0.25 * open))
	if warden.is_stunned():
		for i: int in 3:
			var angle: float = _clock * 4.0 + TAU * i / 3.0
			var star: Vector2 = Vector2(cos(angle) * 12.0, -42.0 + sin(angle) * 3.0).round()
			draw_rect(Rect2(star - Vector2(1, 1), Vector2(2, 2)), Color(1.0, 0.95, 0.5))
	if _spark_left > 0.0:
		var spark: Vector2 = Vector2(warden.facing.x * 10.0, -24.0 + maxf(warden.facing.y, 0.0) * 6.0)
		var size: float = 3.0 + (1.0 - _spark_left / SPARK_TIME) * 4.0
		draw_line(spark - Vector2(size, 0), spark + Vector2(size, 0), Color.WHITE, 1.0)
		draw_line(spark - Vector2(0, size), spark + Vector2(0, size), Color.WHITE, 1.0)
		draw_line(spark - Vector2(size, size) * 0.6, spark + Vector2(size, size) * 0.6, Color(1, 0.95, 0.6), 1.0)
		draw_line(spark - Vector2(size, -size) * 0.6, spark + Vector2(size, -size) * 0.6, Color(1, 0.95, 0.6), 1.0)
