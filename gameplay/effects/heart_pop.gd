class_name HeartPop
extends Node2D
## A small heart over an animal he pets (tool polish, 2026-11-19, D8): it rises RISE pixels and
## fades within LIFE, then is gone. The one effect of a stroke or a touch that rises, allowed by
## the user as a bend of "A still world". For show only. Position = where it starts (its bottom).

const LIFE: float = 0.5
const RISE: float = 6.0
const COLOR: Color = Color(0.94, 0.38, 0.46)
const LIGHT: Color = Color(1.0, 0.72, 0.76)
## The heart, a row a string: "x" filled, "l" its light, "." clear. Five wide, from its bottom.
const SHAPE: Array[String] = [".x.x.", "xlxxx", "xxxxx", ".xxx.", "..x.."]

var _age: float = 0.0


## A heart at `at` in `parent`'s space.
static func spawn(parent: Node, at: Vector2) -> HeartPop:
	var heart: HeartPop = HeartPop.new()
	heart.position = at
	heart.z_index = 1
	parent.add_child(heart)
	return heart


## How far it has risen (px).
func height() -> float:
	return roundf(RISE * clampf(_age / LIFE, 0.0, 1.0))


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFE:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var fade: float = 1.0 - clampf(_age / LIFE, 0.0, 1.0)
	var top: Vector2 = Vector2(-2, -SHAPE.size() - height())
	var ink: Color = PixelGrade.INK
	ink.a = fade
	# Its outline first: each filled pixel's neighbours, in ink.
	for y: int in SHAPE.size():
		for x: int in SHAPE[y].length():
			if SHAPE[y][x] != ".":
				draw_rect(Rect2(top + Vector2(x - 1, y - 1), Vector2(3, 3)), ink)
	for y: int in SHAPE.size():
		for x: int in SHAPE[y].length():
			if SHAPE[y][x] == ".":
				continue
			var color: Color = LIGHT if SHAPE[y][x] == "l" else COLOR
			color.a = fade
			draw_rect(Rect2(top + Vector2(x, y), Vector2(1, 1)), color)
