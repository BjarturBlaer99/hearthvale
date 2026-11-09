class_name PlayerAnimator
extends RefCounted
## Chooses the frame of the hero's sheet to show (gameplay/player/player_sheet.png, painted
## by tools/art/make_player_sprite.gd). Pure, so it is unit-tested: tell it how the hero
## moved each frame (update), let time pass (tick) and set a pose, then read region(),
## shows_flipped() and bob().
##
## Facing follows movement, four ways. A diagonal keeps the current facing when it matches
## one of its two directions (as in classic top-down Zeldas), otherwise faces up or down.
## - Walking: a four-frame cycle (pass, step A, pass, step B) that advances by distance
##   travelled, so it keeps pace with walking and sprinting alike.
## - Standing: idle, with a blink every BLINK_EVERY seconds.
## - A pose overrides both: ATTACK (lunging behind the sword), HOLD (an item held overhead,
##   always seen from the front) or FALLEN (out of hearts).

## Rows of the sheet.
enum Facing { DOWN, UP, SIDE }
enum Pose { NONE, ATTACK, HOLD, FALLEN }

const FRAME_SIZE: Vector2i = Vector2i(16, 24)
## Pixels travelled per animation step; four steps make one walk cycle.
const STRIDE: float = 7.0
## Sheet columns, in the order the tool paints them (a test checks).
const IDLE: int = 0
const BLINK: int = 1
const WALK_A: int = 2
const PASS_A: int = 3
const WALK_B: int = 4
const PASS_B: int = 5
const ATTACK: int = 6
const HOLD: int = 7
const FALLEN: int = 8
const COLUMNS: int = 9
## Walk order from standing: legs passing first, then a step, so setting off doesn't jump.
const CYCLE: Array[int] = [PASS_B, WALK_A, PASS_A, WALK_B]
## Standing, the eyes close for BLINK_TIME every BLINK_EVERY seconds.
const BLINK_EVERY: float = 3.4
const BLINK_TIME: float = 0.14

var facing: Facing = Facing.DOWN
## True when facing right; the sheet's side row faces left.
var flip_h: bool = false
var pose: Pose = Pose.NONE

var _step: int = 0
var _travel: float = 0.0
var _moving: bool = false
var _clock: float = 0.0


## `direction` is where the hero is trying to go (or last went) and `distance` the pixels
## actually moved this frame. Standing still ends the walk cycle.
func update(direction: Vector2, distance: float) -> void:
	_face(direction)
	if distance <= 0.0:
		_step = 0
		_travel = 0.0
		_moving = false
		return
	_moving = true
	_travel += distance
	while _travel >= STRIDE:
		_travel -= STRIDE
		_step = (_step + 1) % CYCLE.size()


## Lets `delta` seconds pass (the blink's clock).
func tick(delta: float) -> void:
	_clock += delta


## Sheet column of the current frame.
func frame() -> int:
	match pose:
		Pose.ATTACK:
			return ATTACK
		Pose.HOLD:
			return HOLD
		Pose.FALLEN:
			return FALLEN
	if _moving:
		return CYCLE[_step]
	return BLINK if fmod(_clock, BLINK_EVERY) >= BLINK_EVERY - BLINK_TIME else IDLE


## Sheet row of the current frame: the facing, but an item is always held up facing front.
func row() -> int:
	return int(Facing.DOWN) if pose == Pose.HOLD else int(facing)


## Texture region of the current frame.
func region() -> Rect2:
	return Rect2(frame() * FRAME_SIZE.x, row() * FRAME_SIZE.y, FRAME_SIZE.x, FRAME_SIZE.y)


## Whether to mirror the frame: facing right, on the side row.
func shows_flipped() -> bool:
	return flip_h and row() == int(Facing.SIDE)


## The classic walking bob: 1 px down on the step frames.
func bob() -> int:
	return 1 if pose == Pose.NONE and _moving and (frame() == WALK_A or frame() == WALK_B) else 0


func _face(direction: Vector2) -> void:
	var horizontal: bool = absf(direction.x) > 0.01
	var vertical: bool = absf(direction.y) > 0.01
	if horizontal and vertical:
		var keeps_side: bool = facing == Facing.SIDE and flip_h == (direction.x > 0.0)
		var keeps_down: bool = facing == Facing.DOWN and direction.y > 0.0
		var keeps_up: bool = facing == Facing.UP and direction.y < 0.0
		if keeps_side or keeps_down or keeps_up:
			return
		facing = Facing.DOWN if direction.y > 0.0 else Facing.UP
		flip_h = false
	elif horizontal:
		facing = Facing.SIDE
		flip_h = direction.x > 0.0
	elif vertical:
		facing = Facing.DOWN if direction.y > 0.0 else Facing.UP
		flip_h = false
