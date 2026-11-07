class_name PlayerController
extends CharacterBody2D
## The player in a district: reads input, steps the grid-checked PlayerMotor, and draws the
## result (docs/TECH_DESIGN.md §4). Position comes from the motor, not from physics; the
## collision shape is here for enemies and hitboxes later (M7).

const HOP_TIME: float = 0.22
const HOP_HEIGHT: float = 4.0
## Pixels the body rises over a full climb.
const CLIMB_LIFT: float = 10.0
const COLOR_GROUND: Color = Color(0.93, 0.55, 0.25)
const COLOR_SWIM: Color = Color(0.98, 0.74, 0.48)
const COLOR_CLIMB: Color = Color(0.96, 0.66, 0.32)
const COLOR_EXHAUSTED: Color = Color(0.72, 0.36, 0.30)

var motor: PlayerMotor

var _hop_left: float = 0.0

@onready var _body: Polygon2D = $Body
@onready var _facing: Polygon2D = $Body/Facing
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
	sync_from_motor()


## Moves the node to the motor's position and redraws (after anything outside the
## physics step changes the motor, such as a water change).
func sync_from_motor() -> void:
	position = motor.position
	_update_visuals()


func _physics_process(delta: float) -> void:
	if motor == null:
		return
	var input: Vector2 = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	motor.step(input, Input.is_action_pressed(&"sprint"), delta)
	_hop_left = maxf(0.0, _hop_left - delta)
	sync_from_motor()


func _update_visuals() -> void:
	var swimming: bool = motor.state_name == PlayerMotor.SWIM
	var lift: float = motor.climb_progress() * CLIMB_LIFT
	if _hop_left > 0.0:
		lift += sin(_hop_left / HOP_TIME * PI) * HOP_HEIGHT
	_body.position = Vector2(0.0, (3.0 if swimming else 0.0) - lift)
	_body.scale = Vector2(1.0, 0.6 if swimming else 1.0)
	if motor.exhausted:
		_body.color = COLOR_EXHAUSTED
	elif swimming:
		_body.color = COLOR_SWIM
	elif motor.state_name == PlayerMotor.CLIMB:
		_body.color = COLOR_CLIMB
	else:
		_body.color = COLOR_GROUND
	_shadow.visible = not swimming
	_ripple.visible = swimming
	_facing.rotation = motor.facing.angle() + PI / 2.0


func _on_fell(_levels: int, _damaging: bool) -> void:
	_hop_left = HOP_TIME
