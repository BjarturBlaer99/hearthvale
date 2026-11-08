class_name PlayerController
extends CharacterBody2D
## The hero in an area: reads input, steps the grid-checked PlayerMotor, swings the sword and
## takes hits, and draws the sprite (docs/TECH_DESIGN.md §4). Position comes from the motor,
## not from physics. The HurtBox child is where the hero can be hit; the Sword child is the
## swing's HitBox.

const HOP_TIME: float = 0.22
const HOP_HEIGHT: float = 4.0
## Invincibility blinks: visible for half of each period.
const BLINK_PERIOD: float = 0.12
const HURT_TINT: Color = Color(1.0, 0.55, 0.55)
const DEAD_TINT: Color = Color(1.0, 0.35, 0.35, 0.8)

var motor: PlayerMotor
## Whether input moves the hero (off while talking, going through a door, or down).
var controls_enabled: bool = true

var _animator: PlayerAnimator = PlayerAnimator.new()
var _last_position: Vector2 = Vector2.ZERO
var _hop_left: float = 0.0
var _attack_was_held: bool = false

@onready var hurt_box: HurtBox = $HurtBox
@onready var sword: Sword = $Sword
@onready var _sprite: Sprite2D = $Sprite
@onready var _camera: Camera2D = $Camera2D


func _ready() -> void:
	hurt_box.hit_taken.connect(_on_hit_taken)


## Called by the area once its terrain is known.
func setup(terrain: TerrainQuery, start_cell: Vector2i, bounds: Rect2i) -> void:
	motor = PlayerMotor.new(terrain)
	motor.place(start_cell)
	motor.dropped.connect(_on_dropped)
	set_camera_bounds(bounds)
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


## The way the hero is pushing: the held direction when it's straight (not diagonal), they're
## on foot and facing it; zero otherwise.
func pushing_toward() -> Vector2i:
	if motor == null or motor.state_name != PlayerMotor.GROUND:
		return Vector2i.ZERO
	var held: Vector2i = Vector2i(roundi(motor.held.x), roundi(motor.held.y))
	if absi(held.x) + absi(held.y) != 1 or held != facing_direction():
		return Vector2i.ZERO
	return held


## The strongest sword the hero holds (an item entry from data), or empty.
static func best_sword() -> Dictionary:
	return CombatRules.best_melee_weapon(GameState.inventory, DataRegistry.entries(&"items"))


## Swings the best sword the hero has, the way they face. Needs a sword, free hands and the
## hero on foot. Returns whether a swing started.
func swing() -> bool:
	if not controls_enabled:
		return false
	var weapon: Dictionary = best_sword()
	if weapon.is_empty():
		return false
	var stats: Dictionary = CombatRules.weapon_stats(weapon)
	var direction: Vector2i = facing_direction()
	if not motor.attack(direction, stats["cooldown"]):
		return false
	sword.swing(Vector2(direction), stats)
	sync_from_motor()
	return true


## Moves the node to the motor's position and redraws (after anything outside the
## physics step moves the hero).
func sync_from_motor() -> void:
	position = motor.position
	_update_sword()
	_update_visuals()


func _physics_process(delta: float) -> void:
	if motor == null:
		return
	# Swing on the press, not while held (tracked here so Input.action_press drives it in tests).
	var attack_held: bool = Input.is_action_pressed(&"attack")
	if attack_held and not _attack_was_held and controls_enabled:
		swing()
	_attack_was_held = attack_held
	var input: Vector2 = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down") if controls_enabled else Vector2.ZERO
	motor.sprinting = controls_enabled and Input.is_action_pressed(&"sprint")
	motor.step(input, delta)
	_hop_left = maxf(0.0, _hop_left - delta)
	sync_from_motor()


## A HitBox of the other team touched the hero: knockback and invincibility from the motor,
## and the damage off the hearts, unless the hero can't be hurt right now.
func _on_hit_taken(hit: Hit) -> void:
	if motor != null and motor.take_hit(hit.push):
		GameState.damage(hit.damage)
		sync_from_motor()


## The sword's arc is live only while the motor is swinging; it draws behind the hero when
## they face up.
func _update_sword() -> void:
	if not motor.is_attacking():
		if sword.active:
			sword.end_swing()
		return
	sword.progress = (motor.state as PlayerAttackState).progress()
	var behind: bool = sword.facing.y < 0.0
	if behind != (sword.get_index() < _sprite.get_index()):
		move_child(sword, _sprite.get_index() if behind else -1)
	sword.queue_redraw()


func _update_visuals() -> void:
	var moved: float = motor.position.distance_to(_last_position)
	_last_position = motor.position
	_animator.update(motor.facing, moved)
	_sprite.region_rect = _animator.region()
	var lift: float = sin(_hop_left / HOP_TIME * PI) * HOP_HEIGHT if _hop_left > 0.0 else 0.0
	_sprite.position = Vector2(-PlayerAnimator.FRAME_SIZE.x / 2.0, -PlayerAnimator.FRAME_SIZE.y + _animator.bob() - roundi(lift))
	_sprite.flip_h = _animator.flip_h
	match motor.state_name:
		PlayerMotor.DEAD:
			_sprite.modulate = DEAD_TINT
		PlayerMotor.HURT:
			_sprite.modulate = HURT_TINT
		_:
			_sprite.modulate = Color.WHITE
	var blinking: bool = motor.is_invincible() and motor.state_name != PlayerMotor.DEAD
	_sprite.visible = not blinking or fmod(motor.invincible_left, BLINK_PERIOD) < BLINK_PERIOD / 2.0


## Keeps the camera inside `bounds` (area pixels: the whole area, or a dungeon room). Bounds
## smaller than the screen (a house, a room) sit in the middle of it, on the clear colour.
func set_camera_bounds(bounds: Rect2i) -> void:
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


## Where the camera may look (for tests): its limits as a rectangle.
func camera_limits() -> Rect2i:
	return Rect2i(_camera.limit_left, _camera.limit_top, _camera.limit_right - _camera.limit_left, _camera.limit_bottom - _camera.limit_top)


func _on_dropped(_levels: int) -> void:
	_hop_left = HOP_TIME
