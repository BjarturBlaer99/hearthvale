class_name HeartsBar
extends Control
## The hero's life as a row of hearts (GDD §5). Each heart is two halves: full,
## half or empty. Ten to a row; more wrap onto a second row. Pieces of heart found toward the
## next heart show after the row as a gold heart filling a quarter at a time.

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
## The colours of PixelLab's UI sheet (new art, step 4): a red heart lit at its top left, an
## empty one in dark wood.
const FULL: Color = Color("e14a3d")
const SHINE: Color = Color("f88783")
const EMPTY: Color = Color("593a2a")
const OUTLINE: Color = Color("392015")
const PIECE: Color = Color("e7c072")
const PIECE_EMPTY: Color = Color("5b5035")
## The pixel of a heart that catches the light (its left lobe), when that half is full.
const SHINE_AT: Vector2i = Vector2i(1, 1)

var _halves: int = 0
var _max_halves: int = 0
var _pieces: int = 0


## Both values in half hearts.
func set_health(halves: int, max_halves: int) -> void:
	if halves == _halves and max_halves == _max_halves:
		return
	_halves = halves
	_max_halves = max_halves
	_fit()
	queue_redraw()


## Pieces of heart toward the next heart (0 hides the piece heart).
func set_pieces(pieces: int) -> void:
	if pieces == _pieces:
		return
	_pieces = pieces
	_fit()
	queue_redraw()


## How many rows the hearts (and the piece heart after them) take.
func rows() -> int:
	var shown: int = ceili(_max_halves / 2.0) + (1 if _pieces > 0 else 0)
	@warning_ignore("integer_division")
	return maxi(1, (shown + PER_ROW - 1) / PER_ROW)


## Asks for the room its rows need, so the box around it fits.
func _fit() -> void:
	custom_minimum_size = Vector2(PER_ROW * SPACING.x, rows() * SPACING.y)


func pieces_shown() -> int:
	return _pieces


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
					if lit and Vector2i(x, y) == SHINE_AT:
						color = SHINE
				draw_rect(Rect2(origin + Vector2(x, y), Vector2.ONE), color)
	if _pieces > 0:
		_draw_pieces(Vector2(hearts % PER_ROW, hearts / PER_ROW) * SPACING)


## The piece heart: quarters fill in order (top left, top right, bottom left, bottom right).
func _draw_pieces(origin: Vector2) -> void:
	for y: int in HEART.size():
		for x: int in HEART[y].length():
			var pixel: String = HEART[y][x]
			if pixel == ".":
				continue
			var color: Color = OUTLINE
			if pixel == "r":
				var quarter: int = (0 if x <= 3 else 1) + (0 if y <= 2 else 2)
				color = PIECE if quarter < _pieces else PIECE_EMPTY
			draw_rect(Rect2(origin + Vector2(x, y), Vector2.ONE), color)
