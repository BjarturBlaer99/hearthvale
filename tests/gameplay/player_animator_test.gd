extends GdUnitTestSuite
## PlayerAnimator: which way the sprite faces, the walk cycle, climbing, and the sheet region.

const DIAGONAL: float = 0.70710678

var _anim: PlayerAnimator


func before_test() -> void:
	_anim = PlayerAnimator.new()


func test_faces_the_way_the_player_moves() -> void:
	_anim.update(Vector2.UP, 1.0, false)
	assert_that(_anim.facing).is_equal(PlayerAnimator.Facing.UP)
	_anim.update(Vector2.LEFT, 1.0, false)
	assert_that(_anim.facing).is_equal(PlayerAnimator.Facing.SIDE)
	assert_bool(_anim.flip_h).is_false()
	_anim.update(Vector2.RIGHT, 1.0, false)
	assert_that(_anim.facing).is_equal(PlayerAnimator.Facing.SIDE)
	assert_bool(_anim.flip_h).is_true()
	_anim.update(Vector2.DOWN, 1.0, false)
	assert_that(_anim.facing).is_equal(PlayerAnimator.Facing.DOWN)
	assert_bool(_anim.flip_h).is_false()


func test_a_diagonal_keeps_a_facing_that_matches_it() -> void:
	_anim.update(Vector2.RIGHT, 1.0, false)
	_anim.update(Vector2(DIAGONAL, DIAGONAL), 1.0, false)
	assert_that(_anim.facing).is_equal(PlayerAnimator.Facing.SIDE)
	assert_bool(_anim.flip_h).is_true()
	_anim.update(Vector2.UP, 1.0, false)
	_anim.update(Vector2(DIAGONAL, -DIAGONAL), 1.0, false)
	assert_that(_anim.facing).is_equal(PlayerAnimator.Facing.UP)


func test_a_diagonal_that_matches_nothing_faces_up_or_down() -> void:
	_anim.update(Vector2.LEFT, 1.0, false)
	_anim.update(Vector2(DIAGONAL, DIAGONAL), 1.0, false)
	assert_that(_anim.facing).is_equal(PlayerAnimator.Facing.DOWN)
	_anim.update(Vector2(-DIAGONAL, -DIAGONAL), 1.0, false)
	assert_that(_anim.facing).is_equal(PlayerAnimator.Facing.UP)


func test_standing_still_shows_the_idle_frame_and_keeps_facing() -> void:
	_anim.update(Vector2.LEFT, PlayerAnimator.STRIDE, false)
	assert_int(_anim.frame()).is_equal(1)
	_anim.update(Vector2.ZERO, 0.0, false)
	assert_int(_anim.frame()).is_equal(0)
	assert_that(_anim.facing).is_equal(PlayerAnimator.Facing.SIDE)


func test_the_walk_cycle_advances_with_distance_travelled() -> void:
	var frames: Array = []
	var bobs: Array = []
	for i: int in 5:
		_anim.update(Vector2.DOWN, PlayerAnimator.STRIDE, false)
		frames.append(_anim.frame())
		bobs.append(_anim.bob())
	assert_array(frames).is_equal([1, 0, 2, 0, 1])
	assert_array(bobs).is_equal([1, 0, 1, 0, 1])
	# Short steps add up: half a stride twice is one step.
	var slow: PlayerAnimator = PlayerAnimator.new()
	slow.update(Vector2.DOWN, PlayerAnimator.STRIDE * 0.5, false)
	assert_int(slow.frame()).is_equal(0)
	slow.update(Vector2.DOWN, PlayerAnimator.STRIDE * 0.5, false)
	assert_int(slow.frame()).is_equal(1)


func test_climbing_shows_the_back_and_holds_its_pose() -> void:
	_anim.update(Vector2.RIGHT, 1.0, false)
	_anim.update(Vector2.RIGHT, PlayerAnimator.STRIDE, true)
	assert_that(_anim.facing).is_equal(PlayerAnimator.Facing.UP)
	assert_bool(_anim.flip_h).is_false()
	assert_int(_anim.frame()).is_equal(1)
	_anim.update(Vector2.ZERO, 0.0, true)
	assert_int(_anim.frame()).is_equal(1)


func test_region_picks_the_frame_and_crops_for_swimming() -> void:
	_anim.update(Vector2.UP, PlayerAnimator.STRIDE, false)
	assert_that(_anim.region()).is_equal(Rect2(16, 24, 16, 24))
	assert_that(_anim.region(PlayerAnimator.SWIM_ROWS)).is_equal(Rect2(16, 24, 16, PlayerAnimator.SWIM_ROWS))
	_anim.update(Vector2.LEFT, 0.0, false)
	assert_that(_anim.region()).is_equal(Rect2(0, 48, 16, 24))
