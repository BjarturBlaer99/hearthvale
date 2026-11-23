class_name ShadeBoss
extends ArenaBoss
## The Crypt Shade, the crypt's boss (docs/TECH_DESIGN.md §5): an ArenaBoss with a ShadeBrain,
## drawn big and half there. The braziers are the Torch nodes standing in its arena. Every
## frame it tells its brain whether all of them burn: that is what binds it, and only bound can
## it be hurt. When the binding ends it snuffs them, and so does starting over. Bound, its
## touch does no harm, so the hero can close in.

## How solid it looks while it haunts (bound, it is all there).
const HAUNT_ALPHA: float = 0.62
const SHEET: Texture2D = preload("res://gameplay/art/shade.png")
## Frames in the order they stand in the sheet (art/sheets.json; a test checks).
const FRAMES: Dictionary = {&"drift_a": 0, &"drift_b": 1, &"bound": 2}
const SIZE: Vector2i = Vector2i(32, 40)
## Raging, it burns a little red.
const RAGE_TINT: Color = Color(1.0, 0.72, 0.78)

var shade: ShadeBrain

var _whiff_left: float = 0.0


func setup(terrain_query: TerrainQuery, hero: Node2D, rng: RandomNumberGenerator) -> bool:
	if not super(terrain_query, hero, rng):
		return false
	shade = brain as ShadeBrain
	if shade == null:
		push_warning("%s: a ShadeBoss needs a shade behaviour, not '%s'." % [name, data.get("behaviour", "")])
		brain = null
		return false
	shade.arena = arena_pixels()
	shade.passed.connect(_on_passed)
	shade.bound.connect(_on_bound)
	shade.snuffed.connect(_on_snuffed)
	# (Its state_changed is already connected by Enemy.setup(), to this script's own method.)
	return true


## The torches standing in its arena that can go out.
func braziers() -> Array[Torch]:
	var out: Array[Torch] = []
	for sibling: Node in get_parent().get_children():
		if sibling is Torch and not (sibling as Torch).always_lit and arena.has_point((sibling as Torch).cell()):
			out.append(sibling as Torch)
	return out


## Whether every brazier burns (false with none at all).
func all_lit() -> bool:
	var torches: Array[Torch] = braziers()
	for torch: Torch in torches:
		if not torch.is_lit():
			return false
	return not torches.is_empty()


## Puts every brazier out. Returns how many were burning.
func snuff_all() -> int:
	var snuffed: int = 0
	for torch: Torch in braziers():
		if torch.snuff():
			snuffed += 1
	return snuffed


func _physics_process(delta: float) -> void:
	_whiff_left = maxf(0.0, _whiff_left - delta)
	super(delta)


func _fight(_delta: float) -> void:
	shade.set_lit(all_lit())


func _start_over() -> void:
	shade.reset()
	snuff_all()
	hit_box.activate()


func _on_passed() -> void:
	_whiff_left = 0.15
	EventBus.sound.emit(&"whiff")
	queue_redraw()


func _on_bound() -> void:
	hit_box.deactivate()
	EventBus.sound.emit(&"stun")
	EventBus.hit_stop.emit(0.12)
	EventBus.shake.emit(2.0, 0.2)


func _on_snuffed() -> void:
	snuff_all()
	EventBus.sound.emit(&"snuff")
	EventBus.shake.emit(1.5, 0.15)


func _on_state_changed(state: StringName) -> void:
	if state == ShadeBrain.HAUNT:
		wake()
		hit_box.activate()


func _draw() -> void:
	if shade == null:
		return
	if _poof_left > 0.0:
		var spread: float = 1.0 - _poof_left / POOF_TIME
		for offset: Vector2 in [Vector2(0, -16), Vector2(-10, -8), Vector2(10, -8), Vector2(0, -28)]:
			draw_arc(offset, 4.0 + spread * 14.0, 0.0, TAU, 20, Color(1, 1, 1, 1.0 - spread), 2.0)
		return
	SoftShadow.draw(self, Vector2.ZERO, Vector2(11, 3), 0.7)
	var frame: StringName = &"bound"
	var alpha: float = 1.0
	var hover: float = 0.0
	if not shade.is_bound():
		frame = &"drift_a" if int(_clock * 3.0) % 2 == 0 else &"drift_b"
		alpha = HAUNT_ALPHA * (0.6 if _whiff_left > 0.0 else 1.0)
		hover = roundf(sin(_clock * 2.5) * 2.0)
	var tint: Color = RAGE_TINT if shade.is_raging() else Color.WHITE
	SpriteSheet.draw(self, SHEET, FRAMES[frame], SIZE, Vector2(-16, -42 + hover), shade.facing.x > 0.3, _flash_left > 0.0, Color(tint, alpha))
