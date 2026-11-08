class_name HeartsBar
extends Control
## The hero's life as a row of hearts (GDD: Zelda-style). Each heart is two halves: full,
## half or empty. Ten to a row; more wrap onto a second row.

const HEART: Array[String] = [
	".oo.oo.",
	"orrorro",
	"orrrrro",
	"orrrrro",
	".orrro.",
	"..oro..",
	"...o...",
]
const SPACING: Vector2 = Vector2(9, 9)
const PER_ROW: int = 10
const FULL: Color = Color(0.89, 0.18, 0.20)
const EMPTY: Color = Color(0.22, 0.12, 0.14)
const OUTLINE: Color = Color(0.08, 0.05, 0.07)

var _halves: int = 0
var _max_halves: int = 0


## Both values in half hearts.
func set_health(halves: int, max_halves: int) -> void:
	if halves == _halves and max_halves == _max_halves:
		return
	_halves = halves
	_max_halves = max_halves
	queue_redraw()


## Full hearts, whether the next one is half full, and empty hearts: what the bar shows.
func describe() -> Vector3i:
	var hearts: int = ceili(_max_halves / 2.0)
	@warning_ignore("integer_division")
	var full: int = _halves / 2
	var half: int = _halves % 2
	return Vector3i(full, half, hearts - full - half)


func _draw() -> void:
	var hearts: int = ceili(_max_halves / 2.0)
	for i: int in hearts:
		var origin: Vector2 = Vector2(i % PER_ROW, i / PER_ROW) * SPACING
		var filled: int = clampi(_halves - i * 2, 0, 2)
		for y: int in HEART.size():
			for x: int in HEART[y].length():
				var pixel: String = HEART[y][x]
				if pixel == ".":
					continue
				var color: Color = OUTLINE
				if pixel == "r":
					var lit: bool = filled == 2 or (filled == 1 and x <= 3)
					color = FULL if lit else EMPTY
				draw_rect(Rect2(origin + Vector2(x, y), Vector2.ONE), color)
