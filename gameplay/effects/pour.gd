class_name Pour
extends Node2D
## Water falling from the can's spout to the soil (tool polish, 2026-11-19, D5): a few drops,
## one after another, from `from` down to the cell, then gone within LIFE. For show only.
## Position = where the drops land; `from` is the spout, from there.

const LIFE: float = 0.25
const DROPS: int = 5
## How long one drop takes to fall.
const FALL: float = 0.12
const COLOR: Color = Color(0.62, 0.84, 1.0)
const LIGHT: Color = Color(0.86, 0.95, 1.0)

var from: Vector2 = Vector2(0, -12)
var _age: float = 0.0


## Drops from `spout` falling to `at` (both in `parent`'s space).
static func spawn(parent: Node, spout: Vector2, at: Vector2) -> Pour:
	var pour: Pour = Pour.new()
	pour.position = at
	pour.from = spout - at
	pour.z_index = 1
	parent.add_child(pour)
	return pour


## Where each drop is now (from where they land), those still falling.
func drops() -> Array[Vector2]:
	var out: Array[Vector2] = []
	for i: int in DROPS:
		var start: float = (LIFE - FALL) * i / float(DROPS - 1)
		var t: float = (_age - start) / FALL
		if t < 0.0 or t > 1.0:
			continue
		# Falling faster as it goes, as water does.
		out.append(from.lerp(Vector2.ZERO, t * t))
	return out


func _process(delta: float) -> void:
	_age += delta
	if _age >= LIFE:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	for i: int in drops().size():
		var drop: Vector2 = drops()[i].round()
		draw_rect(Rect2(drop - Vector2(1, 1), Vector2(2, 2)), COLOR)
		draw_rect(Rect2(drop - Vector2(1, 1), Vector2(1, 1)), LIGHT)
