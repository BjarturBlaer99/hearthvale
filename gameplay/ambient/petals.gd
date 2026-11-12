class_name Petals
extends Node2D
## Cherry blossom petals (P1c): a few drifting on the wind from each cherry tree, and a scatter
## of settled ones on the grass and the water round it. The settled ones are drawn once, at
## ground level; the drifting ones are particles above everything. For show only.

## Settled petals to a tree, and how far from its foot they lie (px, wider than deep).
const SETTLED: int = 18
const SPREAD: Vector2 = Vector2(34.0, 22.0)
const PINKS: Array[Color] = [Color(0.99, 0.80, 0.86), Color(0.95, 0.62, 0.74), Color(1.0, 0.92, 0.94)]
## On water they are paler, as if afloat.
const AFLOAT: Color = Color(1.0, 0.90, 0.93, 0.9)
## Drifting petals to a tree, and how long each lives (seconds).
const DRIFTING: int = 5
const LIFETIME: float = 5.0

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


## Lays petals round each of `feet` (the cherry trees), and starts them drifting. `ground_at`
## says what a cell is: "open" (they lie there), "water" (they float) or anything else (none).
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
		add_child(_drift(foot))
	queue_redraw()


func _draw() -> void:
	for petal: Array in settled:
		draw_rect(Rect2(petal[0], Vector2(2.0 if petal[2] else 1.0, 1.0)), petal[1])


## Petals leaving the crown of the tree at `foot`, carried down and along by the wind.
func _drift(foot: Vector2) -> CPUParticles2D:
	var drift: CPUParticles2D = CPUParticles2D.new()
	drift.position = foot + Vector2(0.0, -24.0)
	drift.z_index = 36
	drift.amount = DRIFTING
	drift.lifetime = LIFETIME
	drift.preprocess = LIFETIME
	drift.randomness = 1.0
	drift.local_coords = false
	drift.emission_shape = CPUParticles2D.EMISSION_SHAPE_RECTANGLE
	drift.emission_rect_extents = Vector2(13.0, 8.0)
	drift.direction = Vector2(1.0, 0.6)
	drift.spread = 35.0
	drift.gravity = Vector2(3.0, 6.0)
	drift.initial_velocity_min = 5.0
	drift.initial_velocity_max = 12.0
	drift.scale_amount_min = 1.0
	drift.scale_amount_max = 1.0
	var pinks: Gradient = Gradient.new()
	pinks.offsets = PackedFloat32Array([0.0, 0.5, 1.0])
	pinks.colors = PackedColorArray([PINKS[0], PINKS[1], PINKS[2]])
	drift.color_initial_ramp = pinks
	var fade: Gradient = Gradient.new()
	fade.offsets = PackedFloat32Array([0.0, 0.8, 1.0])
	fade.colors = PackedColorArray([Color(1, 1, 1, 1), Color(1, 1, 1, 1), Color(1, 1, 1, 0)])
	drift.color_ramp = fade
	return drift
