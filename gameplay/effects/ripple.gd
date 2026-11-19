class_name Ripple
extends Node2D
## A ring on the water where the can is dipped (tool polish, 2026-11-19, D5): it widens from
## FROM to TO pixels across and fades within LIFE, then is gone. Flat on the water, as the water's
## own surface is seen. For show only. Position = the middle of the ring.

const LIFE: float = 0.4
const FROM: float = 2.0
const TO: float = 7.0
const COLOR: Color = Color(0.86, 0.95, 1.0, 0.9)
const POINTS: int = 18

var _age: float = 0.0


static func spawn(parent: Node, at: Vector2) -> Ripple:
	var ripple: Ripple = Ripple.new()
	ripple.position = at
	ripple.z_index = 1
	parent.add_child(ripple)
	return ripple


## How wide it is now (px from the middle, across).
func radius() -> float:
	return lerpf(FROM, TO, clampf(_age / LIFE, 0.0, 1.0))


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFE:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	var color: Color = COLOR
	color.a *= 1.0 - _age / LIFE
	var ring: PackedVector2Array = []
	for i: int in POINTS + 1:
		var angle: float = TAU * i / POINTS
		ring.append(Vector2(cos(angle) * radius(), sin(angle) * radius() * 0.5).round())
	draw_polyline(ring, color, 1.0)
