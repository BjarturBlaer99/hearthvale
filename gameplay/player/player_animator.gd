class_name PlayerAnimator
extends RefCounted
## Chooses the frame of the hero's sheet to show (gameplay/player/player_sheet.png, painted
## by tools/art/make_player_sprite.gd). Pure, so it is unit-tested: tell it how the hero
## moved each frame (update), let time pass (tick) and set a pose, then read region(),
## shows_flipped() and bob().
##
## Facing follows movement, four ways. A diagonal keeps the current facing when it matches
## one of its two directions (as in classic top-down Zeldas), otherwise faces up or down.
## - Walking: a six-frame cycle (legs passing, a step, the weight coming down, then the same on
##   the other foot) that advances by distance travelled, so it keeps pace with walking and
##   sprinting alike. Sprinting uses the leaning run frames and a longer stride.
## - Standing: idle, breathing out every BREATH_EVERY seconds, with a blink every BLINK_EVERY.
## - A pose overrides both: ATTACK (a wind-up, the slash, then the follow-through, by
##   `attack_progress`), HURT (flinching), HOLD (an item held overhead, always seen from the
##   front), LAND (knees bent after a hop), FALLEN (out of hearts) or WORK (a tool at work: its
##   `work_pose`, one of raise, strike, pour or reach, which ToolStroke chooses).
## It only picks pictures: how fast the hero moves, when a swing hits and how long anything
## lasts are the motor's business.

## Rows of the sheet.
enum Facing { DOWN, UP, SIDE }
enum Pose { NONE, ATTACK, HOLD, FALLEN, HURT, LAND, WORK }

const FRAME_SIZE: Vector2i = Vector2i(16, 32)
## Pixels travelled per animation step; six steps make one walk cycle (28 px, as it was when
## the cycle had four).
const STRIDE: float = 28.0 / 6.0
## Sprinting, each step covers more ground, so the feet don't slide.
const RUN_STRIDE: float = 6.0
## Sheet columns, in the order the tool paints them (a test checks).
const IDLE: int = 0
const BLINK: int = 1
## The walk: a step, the weight coming down, the legs passing; then the same on the other foot.
const WALK_1: int = 2
const WALK_2: int = 3
const WALK_3: int = 4
const WALK_4: int = 5
const WALK_5: int = 6
const WALK_6: int = 7
## The swing: gathering, the slash (ATTACK), following through.
const WINDUP: int = 8
const ATTACK: int = 9
const FOLLOW: int = 10
const HOLD: int = 11
const FALLEN: int = 12
const BREATHE: int = 13
const HURT: int = 14
const RUN_1: int = 15
const RUN_2: int = 16
const RUN_3: int = 17
const RUN_4: int = 18
const RUN_5: int = 19
const RUN_6: int = 20
## The work poses (tool polish): a tool raised, the blow, the can held out, a reach down.
const RAISE: int = 21
const STRIKE: int = 22
const POUR: int = 23
const REACH: int = 24
const COLUMNS: int = 25
## The work poses by name (ToolStroke.hero_pose()).
const WORK_COLUMNS: Dictionary = {&"raise": RAISE, &"strike": STRIKE, &"pour": POUR, &"reach": REACH}
## Walk order from standing: legs passing first, then a step, so setting off doesn't jump.
const CYCLE: Array[int] = [WALK_6, WALK_1, WALK_2, WALK_3, WALK_4, WALK_5]
const RUN_CYCLE: Array[int] = [RUN_6, RUN_1, RUN_2, RUN_3, RUN_4, RUN_5]
## The frames in which the weight comes down: the body dips a pixel (bob()).
const LOW: Array[int] = [WALK_2, WALK_5, RUN_2, RUN_5]
## Standing, the shoulders drop for BREATH_OUT at the end of every BREATH_EVERY seconds.
const BREATH_EVERY: float = 2.6
const BREATH_OUT: float = 0.9
## A swing's pictures by how far through it is (0-1): the wind-up, the slash, then the
## follow-through.
const WINDUP_UNTIL: float = 0.18
const FOLLOW_FROM: float = 0.6
## Standing, the eyes close for BLINK_TIME every BLINK_EVERY seconds.
const BLINK_EVERY: float = 3.4
const BLINK_TIME: float = 0.14

var facing: Facing = Facing.DOWN
## True when facing right; the sheet's side row faces left.
var flip_h: bool = false
var pose: Pose = Pose.NONE
## Whether the hero is sprinting (the run frames) and how far through a swing they are (0-1).
var sprinting: bool = false
var attack_progress: float = 0.5
## Which work pose WORK shows (a key of WORK_COLUMNS).
var work_pose: StringName = &"raise"

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
	var stride: float = RUN_STRIDE if sprinting else STRIDE
	while _travel >= stride:
		_travel -= stride
		_step = (_step + 1) % CYCLE.size()


## Lets `delta` seconds pass (the blink's clock).
func tick(delta: float) -> void:
	_clock += delta


## Sheet column of the current frame.
func frame() -> int:
	match pose:
		Pose.ATTACK:
			if attack_progress < WINDUP_UNTIL:
				return WINDUP
			return FOLLOW if attack_progress >= FOLLOW_FROM else ATTACK
		Pose.HURT:
			return HURT
		Pose.LAND:
			return BREATHE
		Pose.HOLD:
			return HOLD
		Pose.FALLEN:
			return FALLEN
		Pose.WORK:
			return int(WORK_COLUMNS.get(work_pose, RAISE))
	if _moving:
		return RUN_CYCLE[_step] if sprinting else CYCLE[_step]
	if fmod(_clock, BLINK_EVERY) >= BLINK_EVERY - BLINK_TIME:
		return BLINK
	return BREATHE if fmod(_clock, BREATH_EVERY) >= BREATH_EVERY - BREATH_OUT else IDLE


## Sheet row of the current frame: the facing, but an item is always held up facing front.
func row() -> int:
	return int(Facing.DOWN) if pose == Pose.HOLD else int(facing)


## Texture region of the current frame.
func region() -> Rect2:
	return Rect2(frame() * FRAME_SIZE.x, row() * FRAME_SIZE.y, FRAME_SIZE.x, FRAME_SIZE.y)


## Whether to mirror the frame: facing right, on the side row.
func shows_flipped() -> bool:
	return flip_h and row() == int(Facing.SIDE)


## The walking bob: 1 px down as the weight comes onto each foot.
func bob() -> int:
	return 1 if pose == Pose.NONE and _moving and frame() in LOW else 0


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
