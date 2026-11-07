class_name BoatController
extends CharacterBody2D
## The player's boat (docs/TECH_DESIGN.md §4): a grid-checked BoatMotor, steered with the
## move actions while the player is aboard and drifting to a stop otherwise. The map it's on
## (district or sea) decides where it is and whether it's here at all.

signal edge_reached(direction: Vector2)
signal cell_changed(cell: Vector2i)

## Below this speed (px/s) there's no wake.
const WAKE_SPEED: float = 25.0

var motor: BoatMotor
## The player aboard, or null.
var rider: PlayerController = null
## Whether the boat is on this map. An absent boat is hidden and doesn't move.
var present: bool = true

@onready var _hull: Node2D = $Hull
@onready var _wake: Polygon2D = $Wake


func setup(terrain: TerrainQuery, water_height: int) -> void:
	motor = BoatMotor.new(terrain, water_height)
	motor.edge_reached.connect(edge_reached.emit)
	motor.cell_changed.connect(cell_changed.emit)


func set_present(on: bool) -> void:
	present = on
	visible = on
	set_physics_process(on)


func set_water_height(height: int) -> void:
	motor.water_height = height


## Puts the boat at rest in `cell`; a rider comes along.
func place(cell: Vector2i, heading: float) -> void:
	motor.place(cell, heading)
	sync_from_motor()


func take_aboard(player: PlayerController) -> void:
	rider = player
	player.board(self)


## The rider has stepped off; the boat stops where it is.
func put_ashore() -> void:
	rider = null
	motor.velocity = Vector2.ZERO


func sync_from_motor() -> void:
	position = motor.position
	_hull.rotation = motor.heading
	_wake.rotation = motor.heading
	_wake.visible = motor.speed() > WAKE_SPEED
	if rider != null:
		rider.ride(self)


func _physics_process(delta: float) -> void:
	if motor == null:
		return
	var input: Vector2 = Vector2.ZERO
	if rider != null:
		input = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	motor.step(input, delta)
	sync_from_motor()
