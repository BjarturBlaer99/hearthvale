class_name Arrow
extends Node2D
## An enemy's arrow: flies straight, hurts the hero on touching them (a HitBox on the enemy
## team), and stops at a solid tile, the map edge, or after LIFETIME. It flies over heights and
## ledges. Position = its point, at ground level.

const LIFETIME: float = 3.0
const SHAFT: Color = Color(0.85, 0.78, 0.62)
const TIP: Color = Color(0.75, 0.78, 0.82)
const FLETCH: Color = Color(0.85, 0.30, 0.25)

var direction: Vector2 = Vector2.RIGHT
var speed: float = 120.0
var terrain: TerrainQuery
var hit_box: HitBox
## Set once it has hit something or stopped; it frees itself.
var stopped: bool = false

var _age: float = 0.0


func setup(terrain_query: TerrainQuery, flight: Vector2, damage: int, flight_speed: float) -> void:
	terrain = terrain_query
	direction = flight.normalized()
	speed = flight_speed
	hit_box = HitBox.new()
	hit_box.team = &"enemy"
	hit_box.radius = 3.0
	hit_box.damage = damage
	hit_box.knockback = 20.0
	hit_box.facing = direction
	add_child(hit_box)
	hit_box.landed.connect(_on_landed)


func _physics_process(delta: float) -> void:
	fly(delta)


## Moves on for `delta` seconds. Returns false once it has stopped.
func fly(delta: float) -> bool:
	if stopped:
		return false
	position += direction * speed * delta
	_age += delta
	var cell: Vector2i = GridBody.cell_of(position)
	if _age > LIFETIME or not terrain.grid.in_bounds(cell) or terrain.grid.is_solid(cell):
		_stop()
		return false
	return true


func _on_landed(_hurt_box: HurtBox) -> void:
	_stop()


func _stop() -> void:
	stopped = true
	hit_box.deactivate()
	queue_free()


func _draw() -> void:
	var lift: Vector2 = Vector2(0, -4)
	var tail: Vector2 = lift - direction * 9.0
	draw_line(tail, lift, SHAFT, 1.0)
	draw_line(lift - direction * 2.0, lift, TIP, 2.0)
	var across: Vector2 = direction.orthogonal() * 2.0
	draw_line(tail, tail - direction * 2.0 + across, FLETCH, 1.0)
	draw_line(tail, tail - direction * 2.0 - across, FLETCH, 1.0)
