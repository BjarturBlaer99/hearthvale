class_name Bomb
extends Node2D
## A lit bomb (docs/TECH_DESIGN.md §4): set down by the hero, its fuse burns for `fuse`
## seconds (the spark blinks faster as it runs down), then it blows up. A blast HitBox of
## `radius` px on the hero's team hurts every enemy in range once, and the bomb is gone. The
## hero's own bombs don't hurt them. Stats come from the bomb item's data. Position = where it
## sits, at ground level.

const BLAST_TIME: float = 0.3
const OUTLINE: Color = Color(0.10, 0.08, 0.12)
const BODY: Color = Color(0.20, 0.24, 0.40)

var fuse: float = 2.0
var fuse_left: float = 2.0
var exploded: bool = false
var blast: HitBox

var _blast_left: float = 0.0


func setup(stats: Dictionary) -> void:
	fuse = maxf(float(stats.get("fuse", 2.0)), 0.05)
	fuse_left = fuse
	blast = HitBox.new()
	blast.team = &"hero"
	blast.kind = &"bomb"
	blast.radius = float(stats.get("radius", 24.0))
	blast.damage = int(stats.get("damage", 4))
	blast.knockback = float(stats.get("knockback", 32.0))
	blast.once_per_activation = true
	blast.active = false
	add_child(blast)


func _physics_process(delta: float) -> void:
	tick(delta)


## Burns the fuse, or the blast, for `delta` seconds. Returns false once the bomb is gone.
func tick(delta: float) -> bool:
	queue_redraw()
	if not exploded:
		fuse_left -= delta
		if fuse_left <= 0.0:
			explode()
		return true
	_blast_left -= delta
	if _blast_left <= 0.0:
		blast.deactivate()
		queue_free()
		return false
	return true


func explode() -> void:
	exploded = true
	_blast_left = BLAST_TIME
	blast.activate(Vector2.DOWN)
	queue_redraw()


func _draw() -> void:
	if exploded:
		var spread: float = 1.0 - _blast_left / BLAST_TIME
		var size: float = blast.radius * (0.55 + 0.45 * spread)
		draw_circle(Vector2(0, -2), size, Color(1.0, 0.55, 0.15, 0.55 * (1.0 - spread)))
		draw_circle(Vector2(0, -2), size * 0.6, Color(1.0, 0.85, 0.35, 0.8 * (1.0 - spread)))
		return
	draw_circle(Vector2(0, 1), 4.0, Color(0, 0, 0, 0.3))
	draw_circle(Vector2(0, -4), 5.5, OUTLINE)
	draw_circle(Vector2(0, -4), 4.5, BODY)
	draw_rect(Rect2(-2, -7, 1, 1), BODY.lightened(0.5))
	draw_line(Vector2(2, -8), Vector2(4, -11), Color(0.85, 0.75, 0.55), 1.0)
	# The spark blinks faster as the fuse runs down: the tell for "move away".
	var period: float = lerpf(0.3, 0.06, 1.0 - fuse_left / fuse)
	if fmod(fuse_left, period) < period / 2.0:
		draw_circle(Vector2(4, -12), 1.5, Color(1.0, 0.85, 0.3))
