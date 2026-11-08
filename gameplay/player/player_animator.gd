class_name PlayerAnimator
extends RefCounted
## Chooses the frame of the hero's sheet to show (gameplay/player/player_sheet.png, painted
## by tools/art/make_player_sprite.gd). Pure, so it is unit-tested: tell it how the hero
## moved each frame, then read region(), flip_h and bob().
##
## Facing follows movement, four ways. A diagonal keeps the current facing when it matches
## one of its two directions (as in classic top-down Zeldas), otherwise faces up or down.
## The walk cycle (idle, step A, idle, step B) advances by distance travelled.

## Rows of the sheet.
enum Facing { DOWN, UP, SIDE }

const FRAME_SIZE: Vector2i = Vector2i(16, 24)
## Pixels travelled per animation step; four steps make one walk cycle.
const STRIDE: float = 7.0
## Sheet columns in walk order: idle, step A, idle, step B.
const CYCLE: Array[int] = [0, 1, 0, 2]

var facing: Facing = Facing.DOWN
## True when facing right; the sheet's side row faces left.
var flip_h: bool = false

var _step: int = 0
var _travel: float = 0.0


## `direction` is where the hero is trying to go (or last went) and `distance` the pixels
## actually moved this frame. Standing still shows the idle frame.
func update(direction: Vector2, distance: float) -> void:
	_face(direction)
	if distance <= 0.0:
		_step = 0
		_travel = 0.0
		return
	_travel += distance
	while _travel >= STRIDE:
		_travel -= STRIDE
		_step = (_step + 1) % CYCLE.size()


## Sheet column of the current frame.
func frame() -> int:
	return CYCLE[_step]


## Texture region of the current frame.
func region() -> Rect2:
	return Rect2(frame() * FRAME_SIZE.x, int(facing) * FRAME_SIZE.y, FRAME_SIZE.x, FRAME_SIZE.y)


## The classic walking bob: 1 px down on step frames.
func bob() -> int:
	return 0 if frame() == 0 else 1


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
