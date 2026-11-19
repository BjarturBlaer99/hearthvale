class_name TitlePicture
extends RefCounted
## Layout of the title screen's painted picture (P1f): an evening over Hearthvale, with the old
## keep on its hill (ui/title/backdrop.png), shown by TitleBackdrop, which draws
## what moves over it (stars, the keep's window, petals) at the places named here.

const TEXTURE_PATH: String = "res://ui/title/backdrop.png"
## The picture is the size of the screen.
const SIZE: Vector2i = Vector2i(640, 360)
## The sky at the very top, as painted (the tool warms it; so does whoever draws more of it).
const SKY_TOP: Color = Color(0.08, 0.09, 0.22)
## Where the land meets the sky, down from the top (px): stars are above it.
const HORIZON: int = 214
## The keep's window: dark in the picture, lit by the screen until the game is finished.
const WINDOW: Rect2i = Rect2i(488, 158, 4, 6)
## The stars that twinkle: painted dim, brightened in turn by the screen.
const STARS: Array[Vector2i] = [
	Vector2i(38, 22), Vector2i(86, 96), Vector2i(171, 14), Vector2i(214, 61), Vector2i(262, 30),
	Vector2i(333, 9), Vector2i(371, 78), Vector2i(418, 37), Vector2i(467, 17), Vector2i(521, 66),
	Vector2i(566, 24), Vector2i(611, 47), Vector2i(300, 108), Vector2i(596, 104),
]
## Where the village's cherry trees stand (their feet), back row first.
const CHERRY_FEET: Array[Vector2i] = [
	Vector2i(104, 307), Vector2i(452, 306), Vector2i(626, 309),
	Vector2i(22, 345), Vector2i(166, 347), Vector2i(498, 347), Vector2i(612, 350),
]
## How far above its foot a cherry tree's crown is: where its petals leave from (px).
const CROWN_RISE: int = 26


## The middle of each cherry tree's crown.
static func crowns() -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for foot: Vector2i in CHERRY_FEET:
		out.append(foot - Vector2i(0, CROWN_RISE))
	return out
