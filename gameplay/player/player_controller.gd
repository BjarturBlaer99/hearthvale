class_name PlayerController
extends CharacterBody2D
## The hero in an area: reads input, steps the grid-checked PlayerMotor, swings the sword and
## takes hits, and draws the sprite (docs/TECH_DESIGN.md §4). Position comes from the motor,
## not from physics. The HurtBox child is where the hero can be hit; the Sword child is the
## swing's HitBox. PlayerAnimator picks the sprite's frame: walking, blinking, swinging the
## sword, holding up an item just taken (hold_up), or fallen.

const HOP_TIME: float = 0.22
const HOP_HEIGHT: float = 4.0
## How long the knees stay bent after landing from a hop.
const LAND_TIME: float = 0.12
## Invincibility blinks: visible for half of each period.
const BLINK_PERIOD: float = 0.12
const HURT_TINT: Color = Color(1.0, 0.55, 0.55)
## Seconds between puffs of dust while sprinting.
const DUST_EVERY: float = 0.16
## How long an item just taken is held overhead (moving or swinging ends it sooner).
const HOLD_TIME: float = 1.1
## Where a held item's picture is drawn, from the hero's feet: just above the raised hands.
const HOLD_OFFSET: Vector2 = Vector2(-8.0, -47.0)

var motor: PlayerMotor
## Whether input moves the hero (off while talking, going through a door, or down).
var controls_enabled: bool = true
## The way a held key is not obeyed, until it is let go (`ArrivalHold`): the area sets it as he
## comes through a door, to the way back through it. Zero: every key is obeyed.
var held_back: Vector2 = Vector2.ZERO

var _animator: PlayerAnimator = PlayerAnimator.new()
var _last_position: Vector2 = Vector2.ZERO
var _hop_left: float = 0.0
var _land_left: float = 0.0
var _attack_was_held: bool = false
var _shake_left: float = 0.0
var _shake_time: float = 0.0
var _shake_strength: float = 0.0
var _dust_left: float = 0.0
var _hold_left: float = 0.0
var _hold_icon: StringName = &""
var _falling: bool = false
var _fall_left: float = 0.0
var _fall_time: float = 1.0
var _lying: bool = false

@onready var hurt_box: HurtBox = $HurtBox
@onready var sword: Sword = $Sword
@onready var _sprite: Sprite2D = $Sprite
@onready var _shadow: Node2D = $Shadow
@onready var _camera: Camera2D = $Camera2D


func _ready() -> void:
	hurt_box.hit_taken.connect(_on_hit_taken)
	EventBus.shake.connect(shake)


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
	# Tired, he is slower to be ready again; and every swing costs a little energy.
	var energy: EnergyRules = GameState.energy_rules()
	if not motor.attack(direction, float(stats["cooldown"]) * energy.cooldown_factor(GameState.energy)):
		return false
	GameState.spend_energy(GameState.energy_cost(EnergyRules.SWING))
	sword.swing(Vector2(direction), stats, ItemIcons.name_for(StringName(str(weapon.get("id", "")))))
	EventBus.sound.emit(&"sword")
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
	var keys: Vector2 = Input.get_vector(&"move_left", &"move_right", &"move_up", &"move_down")
	var input: Vector2 = ArrivalHold.allowed(keys, held_back) if controls_enabled else Vector2.ZERO
	held_back = ArrivalHold.after(keys, held_back)
	# The energy rules (GDD §5): sprint needs energy and spends it while he runs; tired, he is
	# slower.
	var energy: EnergyRules = GameState.energy_rules()
	motor.sprinting = controls_enabled and Input.is_action_pressed(&"sprint") and energy.can_sprint(GameState.energy)
	motor.speed_scale = energy.move_factor(GameState.energy)
	var before: Vector2 = motor.position
	motor.step(input, delta)
	if motor.sprinting and motor.position != before and motor.state_name == PlayerMotor.GROUND:
		GameState.spend_energy(energy.cost(EnergyRules.SPRINT) * delta)
	_kick_up_dust(motor.position != before, delta)
	var was_in_the_air: bool = _hop_left > 0.0
	_hop_left = maxf(0.0, _hop_left - delta)
	# Coming down from a ledge hop, the knees bend for a moment.
	_land_left = LAND_TIME if was_in_the_air and _hop_left <= 0.0 else maxf(0.0, _land_left - delta)
	_animator.tick(delta)
	_fall_left = maxf(0.0, _fall_left - delta)
	if _hold_left > 0.0:
		_hold_left -= delta
		if _hold_left <= 0.0:
			_end_hold()
	sync_from_motor()


## Shows the hero holding picture `icon` (ItemIcons) overhead for a moment: an item just taken.
## For show only: moving or swinging ends it.
func hold_up(icon: StringName) -> void:
	_hold_icon = icon
	_hold_left = HOLD_TIME
	queue_redraw()
	if motor != null:
		sync_from_motor()


## The hero drops out of sight (into a pit) over `seconds`, and stays gone until end_fall().
## For show only: the area takes the heart and puts the hero back.
func fall_in(seconds: float) -> void:
	_falling = true
	_fall_time = maxf(seconds, 0.01)
	_fall_left = _fall_time
	_end_hold()


func end_fall() -> void:
	_falling = false
	if motor != null:
		sync_from_motor()


func is_falling() -> bool:
	return _falling


func is_holding_up() -> bool:
	return _hold_left > 0.0


## The frame the sprite shows (for tests, and for the hero's reflection): its region of the
## sheet, the sheet itself, and whether it is drawn the other way round.
func shown_region() -> Rect2:
	return _sprite.region_rect


func sheet() -> Texture2D:
	return _sprite.texture


func shown_flipped() -> bool:
	return _sprite.flip_h


## The hero drops where he stands, out of energy (the fallen picture; for show). He doesn't
## get up here: the area takes him home.
func lie_down() -> void:
	_lying = true
	if motor != null:
		sync_from_motor()


func is_lying() -> bool:
	return _lying


func _end_hold() -> void:
	_hold_left = 0.0
	queue_redraw()


func _draw() -> void:
	if _hold_left > 0.0:
		ItemIcons.draw(self, _hold_icon, HOLD_OFFSET)


## A HitBox of the other team touched the hero: knockback and invincibility from the motor,
## and the damage off the hearts, unless the hero can't be hurt right now.
func _on_hit_taken(hit: Hit) -> void:
	if motor != null and motor.take_hit(hit.push):
		GameState.damage(hit.damage)
		EventBus.sound.emit(&"hurt")
		EventBus.hit_stop.emit(0.08)
		EventBus.shake.emit(2.0, 0.18)
		sync_from_motor()


## Shakes the camera up to `strength` px for `seconds` (the strongest shake wins).
func shake(strength: float, seconds: float) -> void:
	if seconds <= 0.0:
		return
	_shake_strength = maxf(strength, _shake_strength if _shake_left > 0.0 else 0.0)
	_shake_left = maxf(seconds, _shake_left)
	_shake_time = _shake_left


func is_shaking() -> bool:
	return _shake_left > 0.0


func _process(delta: float) -> void:
	if _shake_left <= 0.0:
		return
	_shake_left = maxf(0.0, _shake_left - delta)
	var amount: float = _shake_strength * (_shake_left / maxf(_shake_time, 0.001))
	_camera.offset = Vector2(randf_range(-1.0, 1.0), randf_range(-1.0, 1.0)) * amount if _shake_left > 0.0 else Vector2.ZERO


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
	if _hold_left > 0.0 and (moved > 0.0 or motor.is_attacking()):
		_end_hold()
	_animator.sprinting = motor.sprinting and moved > 0.0
	_animator.update(motor.facing, moved)
	if motor.state_name == PlayerMotor.DEAD or _lying:
		_animator.pose = PlayerAnimator.Pose.FALLEN
	elif motor.is_attacking():
		_animator.pose = PlayerAnimator.Pose.ATTACK
		_animator.attack_progress = (motor.state as PlayerAttackState).progress()
	elif motor.state_name == PlayerMotor.HURT:
		_animator.pose = PlayerAnimator.Pose.HURT
	elif _hold_left > 0.0:
		_animator.pose = PlayerAnimator.Pose.HOLD
	elif _land_left > 0.0:
		_animator.pose = PlayerAnimator.Pose.LAND
	else:
		_animator.pose = PlayerAnimator.Pose.NONE
	_sprite.region_rect = _animator.region()
	var lift: float = sin(_hop_left / HOP_TIME * PI) * HOP_HEIGHT if _hop_left > 0.0 else 0.0
	# Falling into a pit, the hero shrinks toward their feet and is gone.
	var shrink: float = _fall_left / _fall_time if _falling else 1.0
	_sprite.scale = Vector2(shrink, shrink)
	_sprite.position = Vector2(-PlayerAnimator.FRAME_SIZE.x / 2.0, -PlayerAnimator.FRAME_SIZE.y + _animator.bob() - roundi(lift)) * shrink
	_shadow.visible = not _falling
	_sprite.flip_h = _animator.shows_flipped()
	_sprite.modulate = HURT_TINT if motor.state_name == PlayerMotor.HURT else Color.WHITE
	var blinking: bool = motor.is_invincible() and motor.state_name != PlayerMotor.DEAD
	_sprite.visible = not blinking or fmod(motor.invincible_left, BLINK_PERIOD) < BLINK_PERIOD / 2.0


## Shows everything `times` bigger than life: 1 outdoors, 2 in houses and dungeons, whose rooms
## are small. Whole numbers only, so every pixel stays square. Set it before the bounds.
func set_camera_zoom(times: int) -> void:
	_camera.zoom = Vector2(maxi(times, 1), maxi(times, 1))


func camera_zoom() -> int:
	return roundi(_camera.zoom.x)


## How much of the area the camera shows at once (area pixels).
func camera_view() -> Vector2i:
	return Vector2i(get_viewport_rect().size / _camera.zoom)


## Keeps the camera inside `bounds` (area pixels: the whole area, or a dungeon room). Bounds
## smaller than what the camera shows (a house, a room) sit in the middle of it, on the clear
## colour.
func set_camera_bounds(bounds: Rect2i) -> void:
	var view: Vector2i = camera_view()
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


## Running feet kick up a little dust every DUST_EVERY seconds.
func _kick_up_dust(moved: bool, delta: float) -> void:
	if not (moved and motor.sprinting and motor.state_name == PlayerMotor.GROUND):
		_dust_left = 0.0
		return
	_dust_left -= delta
	if _dust_left <= 0.0 and get_parent() != null:
		_dust_left = DUST_EVERY
		Burst.spawn(get_parent(), position, &"dust", 0.6)
