class_name Burst
extends Node2D
## A puff of little drawn particles (docs/TECH_DESIGN.md §13) that fly out, fade and free
## themselves: sparks where a blow lands, dust from blasts, pushes and running feet, sparkle
## from pickups, leaves from cut grass and shards from broken pots. Drawn in code.
## The bursts of a stroke (tool polish, 2026-11-19, D5): clods from the hoe, a splash of water,
## seeds from the hand, chips and rubble of a rock in its own colours, splinters of wood, chaff
## from hay put in the silo. They
## are thrown up and fall back to rest on the ground (`floor`), half a second at the most:
## none of them rises or hangs in the air ("A still world", bent for strokes by the user).

## Each kind: how many bits, how fast they fly (px/s), how long they last, their colour and
## size, and how they drift (px/s², negative rises). A kind may also throw its bits `up` (px/s),
## let them come to rest `floor` px below where they began, and give each bit one of `colors`.
const KINDS: Dictionary = {
	&"spark": {"count": 6, "speed": 75.0, "life": 0.2, "color": Color(1.0, 0.95, 0.7), "size": 1.0, "drift": 0.0},
	&"dust": {"count": 7, "speed": 26.0, "life": 0.42, "color": Color(0.80, 0.72, 0.58, 0.85), "size": 2.0, "drift": -14.0},
	&"sparkle": {"count": 7, "speed": 38.0, "life": 0.5, "color": Color(1.0, 0.88, 0.40), "size": 1.0, "drift": -24.0},
	&"leaves": {"count": 8, "speed": 34.0, "life": 0.5, "color": Color(0.46, 0.74, 0.30), "size": 2.0, "drift": 40.0},
	&"drops": {"count": 7, "speed": 30.0, "life": 0.4, "color": Color(0.58, 0.80, 0.96, 0.9), "size": 1.0, "drift": 70.0},
	&"shards": {"count": 8, "speed": 46.0, "life": 0.4, "color": Color(0.76, 0.46, 0.26), "size": 2.0, "drift": 90.0},
	# The strokes' (tool polish).
	&"clods": {"count": 6, "speed": 26.0, "life": 0.35, "size": 2.0, "drift": 420.0, "up": 44.0, "floor": 3.0,
		"color": Color(0.70, 0.54, 0.34), "colors": [Color(0.70, 0.54, 0.34), Color(0.26, 0.16, 0.09), Color(0.82, 0.66, 0.44)]},
	&"splash": {"count": 6, "speed": 24.0, "life": 0.3, "size": 2.0, "drift": 420.0, "up": 36.0, "floor": 2.0,
		"color": Color(0.62, 0.84, 1.0), "colors": [Color(0.62, 0.84, 1.0), Color(0.86, 0.95, 1.0)]},
	&"seeds": {"count": 3, "speed": 10.0, "life": 0.3, "size": 2.0, "drift": 420.0, "up": 0.0, "floor": 10.0,
		"color": Color(0.90, 0.80, 0.52)},
	&"chips": {"count": 5, "speed": 40.0, "life": 0.4, "size": 2.0, "drift": 420.0, "up": 40.0, "floor": 4.0,
		"color": Color(0.62, 0.60, 0.58)},
	&"rubble": {"count": 10, "speed": 50.0, "life": 0.45, "size": 2.0, "drift": 420.0, "up": 46.0, "floor": 5.0,
		"color": Color(0.62, 0.60, 0.58)},
	&"chaff": {"count": 7, "speed": 28.0, "life": 0.35, "size": 2.0, "drift": 420.0, "up": 30.0, "floor": 3.0,
		"color": Color(0.92, 0.80, 0.46), "colors": [Color(0.92, 0.80, 0.46), Color(0.78, 0.62, 0.30)]},
	&"splinters": {"count": 5, "speed": 38.0, "life": 0.4, "size": 2.0, "drift": 420.0, "up": 38.0, "floor": 4.0,
		"color": Color(0.84, 0.66, 0.42), "colors": [Color(0.84, 0.66, 0.42), Color(0.62, 0.45, 0.25), Color(0.92, 0.80, 0.58)]},
}
## The kinds that shrink as they fade.
const SHRINKING: Array[StringName] = [&"leaves", &"shards", &"chips", &"rubble", &"splinters"]

var kind: StringName = &"spark"
var life: float = 0.2

var _bits: Array[Vector2] = []
var _speeds: Array[Vector2] = []
var _colors: Array[Color] = []
var _age: float = 0.0
var _style: Dictionary = {}
var _scale: float = 1.0


## A burst of `burst_kind` at `at` (in `parent`'s space), `scale_by` bigger or smaller, its bits
## in `colors` if any are given (a rock's own).
static func spawn(parent: Node, at: Vector2, burst_kind: StringName, scale_by: float = 1.0, colors: Array = []) -> Burst:
	var burst: Burst = Burst.new()
	burst.position = at
	burst.setup(burst_kind, scale_by, colors)
	parent.add_child(burst)
	return burst


func setup(burst_kind: StringName, scale_by: float = 1.0, colors: Array = []) -> void:
	kind = burst_kind if KINDS.has(burst_kind) else &"spark"
	_style = KINDS[kind]
	_scale = scale_by
	life = float(_style["life"])
	var palette: Array = colors if not colors.is_empty() else _style.get("colors", [_style.get("color", Color.WHITE)])
	var count: int = int(_style["count"] * maxf(scale_by, 0.5))
	var up: float = float(_style.get("up", 0.0))
	for i: int in count:
		var angle: float = TAU * (i + 0.37 * (i % 3)) / count
		var speed: float = float(_style["speed"]) * scale_by * (0.6 + 0.4 * ((i * 7) % 5) / 4.0)
		_bits.append(Vector2.ZERO)
		_speeds.append(Vector2(cos(angle), sin(angle) * 0.6) * speed + Vector2(0.0, -up * (0.7 + 0.3 * (i % 2))))
		_colors.append(palette[i % palette.size()])
	z_index = 1


## Where each bit is now, from where the burst began (for tests).
func bits() -> Array[Vector2]:
	return _bits


func _process(delta: float) -> void:
	_age += delta
	if _age >= life:
		queue_free()
		return
	var floor_y: float = float(_style.get("floor", -1.0))
	for i: int in _bits.size():
		_speeds[i].y += float(_style["drift"]) * delta
		_bits[i] += _speeds[i] * delta
		# Come down, it lies where it fell.
		if floor_y >= 0.0 and _speeds[i].y > 0.0 and _bits[i].y >= floor_y:
			_bits[i].y = floor_y
			_speeds[i] = Vector2.ZERO
	queue_redraw()


func _draw() -> void:
	var fade: float = 1.0 - _age / maxf(life, 0.001)
	var size: float = float(_style.get("size", 1.0)) * (_scale if kind == &"dust" else 1.0)
	if SHRINKING.has(kind):
		size = maxf(1.0, size * fade + 0.5)
	# The strokes' bits keep to the pixel grid; the older kinds are drawn as they always were.
	var snap: bool = _style.has("floor")
	for i: int in _bits.size():
		var color: Color = _colors[i]
		color.a *= fade
		var corner: Vector2 = _bits[i] - Vector2(size, size) * 0.5
		draw_rect(Rect2(corner.round() if snap else corner, Vector2(size, size)), color)
