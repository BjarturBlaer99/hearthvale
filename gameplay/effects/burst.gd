class_name Burst
extends Node2D
## A puff of little drawn particles (docs/TECH_DESIGN.md §13) that fly out, fade and free
## themselves: sparks where a blow lands, dust from blasts, pushes and running feet, sparkle
## from pickups, leaves from cut grass and shards from broken pots. Drawn in code.

## Each kind: how many bits, how fast they fly (px/s), how long they last, their colour and
## size, and how they drift (px/s², negative rises).
const KINDS: Dictionary = {
	&"spark": {"count": 6, "speed": 75.0, "life": 0.2, "color": Color(1.0, 0.95, 0.7), "size": 1.0, "drift": 0.0},
	&"dust": {"count": 7, "speed": 26.0, "life": 0.42, "color": Color(0.80, 0.72, 0.58, 0.85), "size": 2.0, "drift": -14.0},
	&"sparkle": {"count": 7, "speed": 38.0, "life": 0.5, "color": Color(1.0, 0.88, 0.40), "size": 1.0, "drift": -24.0},
	&"leaves": {"count": 8, "speed": 34.0, "life": 0.5, "color": Color(0.46, 0.74, 0.30), "size": 2.0, "drift": 40.0},
	&"shards": {"count": 8, "speed": 46.0, "life": 0.4, "color": Color(0.76, 0.46, 0.26), "size": 2.0, "drift": 90.0},
}

var kind: StringName = &"spark"
var life: float = 0.2

var _bits: Array[Vector2] = []
var _speeds: Array[Vector2] = []
var _age: float = 0.0
var _style: Dictionary = {}
var _scale: float = 1.0


## A burst of `burst_kind` at `at` (in `parent`'s space), `scale_by` bigger or smaller.
static func spawn(parent: Node, at: Vector2, burst_kind: StringName, scale_by: float = 1.0) -> Burst:
	var burst: Burst = Burst.new()
	burst.position = at
	burst.setup(burst_kind, scale_by)
	parent.add_child(burst)
	return burst


func setup(burst_kind: StringName, scale_by: float = 1.0) -> void:
	kind = burst_kind if KINDS.has(burst_kind) else &"spark"
	_style = KINDS[kind]
	_scale = scale_by
	life = float(_style["life"])
	var count: int = int(_style["count"] * maxf(scale_by, 0.5))
	for i: int in count:
		var angle: float = TAU * (i + 0.37 * (i % 3)) / count
		var speed: float = float(_style["speed"]) * scale_by * (0.6 + 0.4 * ((i * 7) % 5) / 4.0)
		_bits.append(Vector2.ZERO)
		_speeds.append(Vector2(cos(angle), sin(angle) * 0.6) * speed)
	z_index = 1


func _process(delta: float) -> void:
	_age += delta
	if _age >= life:
		queue_free()
		return
	for i: int in _bits.size():
		_speeds[i].y += float(_style["drift"]) * delta
		_bits[i] += _speeds[i] * delta
	queue_redraw()


func _draw() -> void:
	var fade: float = 1.0 - _age / maxf(life, 0.001)
	var color: Color = _style.get("color", Color.WHITE)
	color.a *= fade
	var size: float = float(_style.get("size", 1.0)) * (_scale if kind == &"dust" else 1.0)
	if kind == &"leaves" or kind == &"shards":
		size = maxf(1.0, size * fade + 0.5)
	for bit: Vector2 in _bits:
		draw_rect(Rect2(bit - Vector2(size, size) * 0.5, Vector2(size, size)), color)
