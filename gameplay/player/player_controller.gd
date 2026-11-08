class_name PlayerController
extends CharacterBody2D
## The hero in an area: reads input, steps the grid-checked PlayerMotor, and draws the
## sprite (docs/TECH_DESIGN.md §4). Position comes from the motor, not from physics; the
## collision shape is for hitboxes once combat arrives.

const HOP_TIME: float = 0.22
const HOP_HEIGHT: float = 4.0

var motor: PlayerMotor
## Whether input moves the hero (off while talking, or going through a door).
var controls_enabled: bool = true

var _animator: PlayerAnimator = PlayerAnimator.new()
var _last_position: Vector2 = Vector2.ZERO
var _hop_left: float = 0.0

@onready var _sprite: Sprite2D = $Sprite
@onready var _camera: Camera2D = $Camera2D


## Called by the area once its terrain is known.
func setup(terrain: TerrainQuery, start_cell: Vector2i, bounds: Rect2i) -> void:
	motor = PlayerMotor.new(terrain)
	motor.place(start_cell)
	motor.dropped.connect(_on_dropped)
	_set_camera_limits(bounds)
	_last_position = motor.position
	sync_from_motor()


## Turns the hero to face `direction` without moving (arriving through a door).
func face(direction: Vector2) -> void:
	motor.facing = direction
	sync_from_motor()


## Which way the hero faces, as the sprite shows it: one of the four neighbour offsets.
func facing_direction() -> Vector2i:
	match _animator.facing:
		PlayerAnimator.Facing.UP:
			return Vector2i.UP
		PlayerAnimator.Facing.SIDE:
			return Vector2i.RIGHT if _animator.flip_h else Vector2i.LEFT
	return Vector2i.DOWN


## The cell in front of the hero: who they talk to.
func front_cell() -> Vector2i:
	return motor.cell + facing_direction()


## Moves the node to the motor's position and redraws (after anything outside the
## physics step moves the hero).
func sync_from_motor() -> void:
	position = motor.position
	_update_visuals()


func _physics_process(delta: float) -> void:
	if motor == null:
		return
	var input: Vector2 = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down") if controls_enabled else Vector2.ZERO
	motor.step(input, delta)
	_hop_left = maxf(0.0, _hop_left - delta)
	sync_from_motor()


func _update_visuals() -> void:
	var moved: float = motor.position.distance_to(_last_position)
	_last_position = motor.position
	_animator.update(motor.facing, moved)
	_sprite.region_rect = _animator.region()
	var lift: float = sin(_hop_left / HOP_TIME * PI) * HOP_HEIGHT if _hop_left > 0.0 else 0.0
	_sprite.position = Vector2(-PlayerAnimator.FRAME_SIZE.x / 2.0, -PlayerAnimator.FRAME_SIZE.y + _animator.bob() - roundi(lift))
	_sprite.flip_h = _animator.flip_h


## Keeps the camera inside the area. An area smaller than the screen (a house) sits in the
## middle of it, on the clear colour.
func _set_camera_limits(bounds: Rect2i) -> void:
	var view: Vector2i = Vector2i(get_viewport_rect().size)
	var limits: Rect2i = bounds
	for axis: int in 2:
		if bounds.size[axis] < view[axis]:
			@warning_ignore("integer_division")
			limits.position[axis] = bounds.position[axis] - (view[axis] - bounds.size[axis]) / 2
			limits.size[axis] = view[axis]
	_camera.limit_left = limits.position.x
	_camera.limit_top = limits.position.y
	_camera.limit_right = limits.end.x
	_camera.limit_bottom = limits.end.y


func _on_dropped(_levels: int) -> void:
	_hop_left = HOP_TIME
