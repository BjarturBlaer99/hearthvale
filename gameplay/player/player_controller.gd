class_name PlayerController
extends CharacterBody2D
## The player in a district: reads input, steps the grid-checked PlayerMotor, and draws the
## result with the sprite sheet (docs/TECH_DESIGN.md §4). Position comes from the motor,
## not from physics; the collision shape is here for enemies and hitboxes later (M7).

const HOP_TIME: float = 0.22
const HOP_HEIGHT: float = 4.0
## Pixels the sprite rises over a full climb.
const CLIMB_LIFT: float = 10.0
## Animation pace while climbing: pixels of "walk" per full climb.
const CLIMB_STRIDE_PX: float = 24.0
## How far the swimmer sits below the surface line, and how fast they bob.
const SWIM_SINK: int = 4
const SWIM_BOB_SPEED: float = 5.0
const EXHAUSTED_TINT: Color = Color(1.0, 0.62, 0.58)

var motor: PlayerMotor

var _animator: PlayerAnimator = PlayerAnimator.new()
var _last_position: Vector2 = Vector2.ZERO
var _last_climb: float = 0.0
var _hop_left: float = 0.0
var _swim_time: float = 0.0

@onready var _sprite: Sprite2D = $Sprite
@onready var _shadow: Polygon2D = $Shadow
@onready var _ripple: Polygon2D = $Ripple
@onready var _camera: Camera2D = $Camera2D


## Called by the district once its terrain is known.
func setup(terrain: TerrainQuery, water_height: int, start_cell: Vector2i, stamina: float, bounds: Rect2i) -> void:
	motor = PlayerMotor.new(terrain, water_height)
	motor.stamina = clampf(stamina, 0.0, PlayerMotor.STAMINA_MAX)
	motor.place(start_cell)
	motor.fell.connect(_on_fell)
	_camera.limit_left = bounds.position.x
	_camera.limit_top = bounds.position.y
	_camera.limit_right = bounds.end.x
	_camera.limit_bottom = bounds.end.y
	_last_position = motor.position
	sync_from_motor()


## Moves the node to the motor's position and redraws (after anything outside the
## physics step changes the motor, such as a water change).
func sync_from_motor() -> void:
	position = motor.position
	_update_visuals(0.0)


func _physics_process(delta: float) -> void:
	if motor == null:
		return
	var input: Vector2 = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	motor.step(input, Input.is_action_pressed(&"sprint"), delta)
	_hop_left = maxf(0.0, _hop_left - delta)
	position = motor.position
	_update_visuals(delta)


func _update_visuals(delta: float) -> void:
	var swimming: bool = motor.state_name == PlayerMotor.SWIM
	var climbing: bool = motor.state_name == PlayerMotor.CLIMB
	var moved: float = motor.position.distance_to(_last_position)
	if climbing:
		moved = absf(motor.climb_progress() - _last_climb) * CLIMB_STRIDE_PX
	_last_position = motor.position
	_last_climb = motor.climb_progress()
	_animator.update(motor.facing, moved, climbing)

	var lift: float = motor.climb_progress() * CLIMB_LIFT
	if _hop_left > 0.0:
		lift += sin(_hop_left / HOP_TIME * PI) * HOP_HEIGHT
	var top: int
	if swimming:
		_swim_time += delta
		_sprite.region_rect = _animator.region(PlayerAnimator.SWIM_ROWS)
		top = -PlayerAnimator.SWIM_ROWS + SWIM_SINK + roundi(sin(_swim_time * SWIM_BOB_SPEED))
	else:
		_sprite.region_rect = _animator.region()
		top = -PlayerAnimator.FRAME_SIZE.y + _animator.bob()
	_sprite.position = Vector2(-PlayerAnimator.FRAME_SIZE.x / 2.0, top - roundi(lift))
	_sprite.flip_h = _animator.flip_h
	_sprite.modulate = EXHAUSTED_TINT if motor.exhausted else Color.WHITE
	_shadow.visible = not swimming
	_ripple.visible = swimming


func _on_fell(_levels: int, _damaging: bool) -> void:
	_hop_left = HOP_TIME
