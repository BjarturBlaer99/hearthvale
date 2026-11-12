class_name TrainingDummy
extends Node2D
## A straw dummy on a post, to practise the sword on. It stands in its cell (nothing walks
## through it), and every hit makes it wobble and flash. Position = the cell's top-left corner;
## the HurtBox child sits at the middle of the dummy.

const WOBBLE_TIME: float = 0.35
const FLASH_TIME: float = 0.1
const SHEET: Texture2D = preload("res://gameplay/art/dummy.png")
## The post's foot, mid-cell like the hero's feet.
const BASE: Vector2 = Vector2(8.0, 9.0)

## Hits taken this visit, and the last one.
var hits: int = 0
var last_hit: Hit

var _wobble_left: float = 0.0

@onready var hurt_box: HurtBox = $HurtBox


func _ready() -> void:
	hurt_box.hit_taken.connect(_on_hit_taken)
	set_process(false)


func cell() -> Vector2i:
	return PlayerMotor.cell_of(position + Vector2(0.5, 0.5))


func covers(at: Vector2i) -> bool:
	return at == cell()


## It stands in its cell: the area marks the cell occupied.
func occupies() -> bool:
	return true


func _on_hit_taken(hit: Hit) -> void:
	hits += 1
	last_hit = hit
	_wobble_left = WOBBLE_TIME
	set_process(true)
	queue_redraw()


func _process(delta: float) -> void:
	_wobble_left = maxf(0.0, _wobble_left - delta)
	queue_redraw()
	if _wobble_left <= 0.0:
		set_process(false)


func _draw() -> void:
	SoftShadow.draw(self, BASE + Vector2(0.0, 0.5), Vector2(5.5, 2))
	var shown: float = WOBBLE_TIME - _wobble_left
	var lean: float = sin(shown * 30.0) * 0.35 * (_wobble_left / WOBBLE_TIME)
	draw_set_transform(BASE, lean)
	var flash: bool = _wobble_left > 0.0 and shown < FLASH_TIME
	SpriteSheet.draw(self, SHEET, 0, Vector2i(16, 24), Vector2(-8, -23), false, flash)
	draw_set_transform(Vector2.ZERO)
