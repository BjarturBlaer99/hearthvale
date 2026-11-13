class_name FriendMarks
extends Control
## A villager's friendship as a row of small blossoms (P4c, GDD §10): one for each mark there
## can be, in bloom for each mark earned. Drawn in code from a small picture, like the hearts.

## p: petal, s: a petal in shade, y: the blossom's heart, o: its edge.
const BLOSSOM: Array[String] = [
	"..o.o..",
	".opopo.",
	"oppyppo",
	".pyyys.",
	"oppysso",
	".ososo.",
	"..o.o..",
]
const SPACING: float = 10.0
const SIZE: Vector2 = Vector2(7, 7)
## A blossom in bloom, and one still to come.
const BLOOM: Dictionary = {
	"p": Color(0.98, 0.70, 0.80), "s": Color(0.86, 0.50, 0.64), "y": Color(1.0, 0.86, 0.45), "o": Color(0.45, 0.22, 0.32),
}
const BUD: Dictionary = {
	"p": Color(0.24, 0.21, 0.27), "s": Color(0.20, 0.17, 0.23), "y": Color(0.24, 0.21, 0.27), "o": Color(0.15, 0.13, 0.18),
}

## The marks earned, and the most there are.
var earned: int = 0
var out_of: int = 0


## Shows `marks` blossoms in bloom out of `most`.
func show_marks(marks: int, most: int) -> void:
	out_of = maxi(most, 0)
	earned = clampi(marks, 0, out_of)
	custom_minimum_size = Vector2(SPACING * float(out_of), SIZE.y)
	size = custom_minimum_size
	queue_redraw()


func _draw() -> void:
	for mark: int in out_of:
		var colours: Dictionary = BLOOM if mark < earned else BUD
		for y: int in BLOSSOM.size():
			for x: int in BLOSSOM[y].length():
				var key: String = BLOSSOM[y][x]
				if colours.has(key):
					draw_rect(Rect2(float(mark) * SPACING + float(x), float(y), 1.0, 1.0), colours[key])
