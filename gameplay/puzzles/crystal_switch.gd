class_name CrystalSwitch
extends Node2D
## A crystal on a pedestal (docs/TECH_DESIGN.md §6): hit it with the sword, an arrow or a bomb
## and it sets `flag` (or flips it, with `toggles`); the crystal shows red when the flag is off
## and blue when on. It stands in its cell. Its HurtBox (on the enemy team, so the hero's hits
## reach it) is made in code. Position = its cell's top-left corner.

## After a hit, more hits are ignored this long (one swing, one change).
const LOCKOUT: float = 0.4
const OUTLINE: Color = Color(0.10, 0.08, 0.12)
const RED: Color = Color(0.92, 0.28, 0.30)
const BLUE: Color = Color(0.35, 0.62, 0.98)
const STONE: Color = Color(0.50, 0.50, 0.56)
const KINDS: Array[StringName] = [&"sword", &"arrow", &"bomb"]

@export var flag: StringName
@export var toggles: bool = false

var hurt_box: HurtBox

var _lockout: float = 0.0
var _flash: float = 0.0


func _ready() -> void:
	hurt_box = HurtBox.new()
	hurt_box.team = &"enemy"
	hurt_box.radius = 6.0
	hurt_box.position = Vector2(8, 6)
	add_child(hurt_box)
	hurt_box.hit_taken.connect(_on_hit)
	set_process(false)


func cell() -> Vector2i:
	return PlayerMotor.cell_of(position + Vector2(0.5, 0.5))


func covers(at: Vector2i) -> bool:
	return at == cell()


## It stands in its cell: the area marks the cell occupied.
func occupies() -> bool:
	return true


func is_on() -> bool:
	return GameState.get_flag(flag) == true


func _on_hit(hit: Hit) -> void:
	if _lockout > 0.0 or not KINDS.has(hit.kind):
		return
	GameState.set_flag(flag, not is_on() if toggles else true)
	_lockout = LOCKOUT
	_flash = 0.15
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_lockout = maxf(0.0, _lockout - delta)
	_flash = maxf(0.0, _flash - delta)
	queue_redraw()
	if _lockout <= 0.0 and _flash <= 0.0:
		set_process(false)


func _draw() -> void:
	draw_rect(Rect2(2, 12, 12, 3), Color(0, 0, 0, 0.3))
	draw_rect(Rect2(3, 9, 10, 6), OUTLINE)
	draw_rect(Rect2(4, 10, 8, 4), STONE)
	draw_rect(Rect2(4, 10, 8, 1), STONE.lightened(0.2))
	var gem: Color = Color.WHITE if _flash > 0.0 else (BLUE if is_on() else RED)
	var crystal: PackedVector2Array = [Vector2(8, 0), Vector2(13, 5), Vector2(8, 11), Vector2(3, 5)]
	draw_colored_polygon(PackedVector2Array([Vector2(8, -1), Vector2(14, 5), Vector2(8, 12), Vector2(2, 5)]), OUTLINE)
	draw_colored_polygon(crystal, gem)
	draw_colored_polygon(PackedVector2Array([Vector2(8, 1), Vector2(11, 5), Vector2(8, 5), Vector2(5, 4)]), gem.lightened(0.35))
