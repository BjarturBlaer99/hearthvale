class_name Petals
extends Node2D
## Cherry blossom petals (P1c): a scatter of fallen ones on the grass and the water round each
## cherry tree, drawn once, at ground level. None are in the air: they drifted on the wind
## until 2026-11-13. For show only.

## Settled petals to a tree, and how far from its foot they lie (px, wider than deep).
const SETTLED: int = 18
const SPREAD: Vector2 = Vector2(34.0, 22.0)
const PINKS: Array[Color] = [Color(0.99, 0.80, 0.86), Color(0.95, 0.62, 0.74), Color(1.0, 0.92, 0.94)]
## On water they are paler, as if afloat.
const AFLOAT: Color = Color(1.0, 0.90, 0.93, 0.9)

## Where each settled petal lies (area px), its colour, and whether it is two pixels wide.
var settled: Array = []


## Where the settled petals of a tree with its foot at `foot` lie: the same for the same tree,
## every time, all within SPREAD of it.
static func scatter(foot: Vector2, count: int = SETTLED) -> Array[Vector2]:
	var rng: RandomNumberGenerator = RandomNumberGenerator.new()
	rng.seed = hash(Vector2i(foot))
	var out: Array[Vector2] = []
	for i: int in count:
		var angle: float = rng.randf() * TAU
		var far: float = sqrt(rng.randf())
		out.append((foot + Vector2(cos(angle) * SPREAD.x, sin(angle) * SPREAD.y) * far).floor())
	return out


## Lays petals round each of `feet` (the cherry trees). `ground_at` says what a cell is: "open"
## (they lie there), "water" (they float) or anything else (none).
func setup(feet: Array[Vector2], ground_at: Callable) -> void:
	settled.clear()
	for foot: Vector2 in feet:
		var spots: Array[Vector2] = scatter(foot)
		for i: int in spots.size():
			var cell: Vector2i = Vector2i((spots[i] / float(GreyboxTiles.TILE_SIZE)).floor())
			var ground: String = str(ground_at.call(cell))
			if ground == "water":
				settled.append([spots[i], AFLOAT, false])
			elif ground == "open":
				settled.append([spots[i], PINKS[i % PINKS.size()], i % 4 == 0])
	queue_redraw()


func _draw() -> void:
	for petal: Array in settled:
		draw_rect(Rect2(petal[0], Vector2(2.0 if petal[2] else 1.0, 1.0)), petal[1])
