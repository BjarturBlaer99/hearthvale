extends GdUnitTestSuite
## PlayerAnimator: which way the sprite faces, the four-frame walk cycle, the blink while
## standing, the poses (attack, an item held up, fallen) and the sheet region. Also that its
## columns are the ones tools/art/make_player_sprite.gd paints.

const DIAGONAL: float = 0.70710678
const TOOL: String = "res://tools/art/make_player_sprite.gd"
const SHEET: String = "res://gameplay/player/player_sheet.png"

var _anim: PlayerAnimator


func before_test() -> void:
	_anim = PlayerAnimator.new()


func test_faces_the_way_the_hero_moves() -> void:
	_anim.update(Vector2.UP, 1.0)
	assert_that(_anim.facing).is_equal(PlayerAnimator.Facing.UP)
	_anim.update(Vector2.LEFT, 1.0)
	assert_that(_anim.facing).is_equal(PlayerAnimator.Facing.SIDE)
	assert_bool(_anim.shows_flipped()).is_false()
	_anim.update(Vector2.RIGHT, 1.0)
	assert_that(_anim.facing).is_equal(PlayerAnimator.Facing.SIDE)
	assert_bool(_anim.shows_flipped()).is_true()
	_anim.update(Vector2.DOWN, 1.0)
	assert_that(_anim.facing).is_equal(PlayerAnimator.Facing.DOWN)
	assert_bool(_anim.shows_flipped()).is_false()


func test_a_diagonal_keeps_a_facing_that_matches_it() -> void:
	_anim.update(Vector2.RIGHT, 1.0)
	_anim.update(Vector2(DIAGONAL, DIAGONAL), 1.0)
	assert_that(_anim.facing).is_equal(PlayerAnimator.Facing.SIDE)
	assert_bool(_anim.flip_h).is_true()
	_anim.update(Vector2.UP, 1.0)
	_anim.update(Vector2(DIAGONAL, -DIAGONAL), 1.0)
	assert_that(_anim.facing).is_equal(PlayerAnimator.Facing.UP)


func test_a_diagonal_that_matches_nothing_faces_up_or_down() -> void:
	_anim.update(Vector2.LEFT, 1.0)
	_anim.update(Vector2(DIAGONAL, DIAGONAL), 1.0)
	assert_that(_anim.facing).is_equal(PlayerAnimator.Facing.DOWN)
	_anim.update(Vector2(-DIAGONAL, -DIAGONAL), 1.0)
	assert_that(_anim.facing).is_equal(PlayerAnimator.Facing.UP)


func test_standing_still_shows_the_idle_frame_and_keeps_facing() -> void:
	_anim.update(Vector2.LEFT, PlayerAnimator.STRIDE)
	assert_int(_anim.frame()).is_equal(PlayerAnimator.WALK_A)
	_anim.update(Vector2.LEFT, 0.0)
	assert_int(_anim.frame()).is_equal(PlayerAnimator.IDLE)
	assert_that(_anim.facing).is_equal(PlayerAnimator.Facing.SIDE)


func test_the_walk_cycle_has_four_frames_and_advances_with_distance_travelled() -> void:
	_anim.update(Vector2.DOWN, 0.5)
	assert_int(_anim.frame()).override_failure_message("setting off: legs passing, not a jump to a full step").is_equal(PlayerAnimator.PASS_B)
	_anim = PlayerAnimator.new()
	var frames: Array = []
	var bobs: Array = []
	for i: int in 5:
		_anim.update(Vector2.DOWN, PlayerAnimator.STRIDE)
		frames.append(_anim.frame())
		bobs.append(_anim.bob())
	assert_array(frames).is_equal([PlayerAnimator.WALK_A, PlayerAnimator.PASS_A, PlayerAnimator.WALK_B, PlayerAnimator.PASS_B, PlayerAnimator.WALK_A])
	assert_array(bobs).override_failure_message("a dip on each step").is_equal([1, 0, 1, 0, 1])
	var slow: PlayerAnimator = PlayerAnimator.new()
	slow.update(Vector2.DOWN, PlayerAnimator.STRIDE * 0.5)
	assert_int(slow.frame()).is_equal(PlayerAnimator.PASS_B)
	slow.update(Vector2.DOWN, PlayerAnimator.STRIDE * 0.5)
	assert_int(slow.frame()).is_equal(PlayerAnimator.WALK_A)


func test_standing_the_hero_blinks_now_and_then() -> void:
	var blinks: int = 0
	var blinking: bool = false
	var longest: float = 0.0
	var run: float = 0.0
	var step: float = 1.0 / 60.0
	for i: int in roundi(PlayerAnimator.BLINK_EVERY * 3.0 / step):
		_anim.tick(step)
		var now: bool = _anim.frame() == PlayerAnimator.BLINK
		if now and not blinking:
			blinks += 1
		run = run + step if now else 0.0
		longest = maxf(longest, run)
		blinking = now
	assert_int(blinks).is_equal(3)
	assert_float(longest).override_failure_message("a blink is brief").is_less(0.25)
	_anim.update(Vector2.DOWN, 1.0)
	for i: int in roundi(PlayerAnimator.BLINK_EVERY / step):
		_anim.tick(step)
		assert_bool(_anim.frame() == PlayerAnimator.BLINK).override_failure_message("no blinking mid-stride").is_false()


func test_poses_override_walking_and_standing() -> void:
	_anim.update(Vector2.LEFT, PlayerAnimator.STRIDE)
	_anim.pose = PlayerAnimator.Pose.ATTACK
	assert_int(_anim.frame()).is_equal(PlayerAnimator.ATTACK)
	assert_int(_anim.bob()).override_failure_message("no bob in a pose").is_equal(0)
	assert_that(_anim.region()).override_failure_message("attacking shows the facing's own row").is_equal(Rect2(PlayerAnimator.ATTACK * 16, 48, 16, 24))
	_anim.pose = PlayerAnimator.Pose.FALLEN
	assert_int(_anim.frame()).is_equal(PlayerAnimator.FALLEN)
	_anim.pose = PlayerAnimator.Pose.NONE
	assert_int(_anim.frame()).is_equal(PlayerAnimator.WALK_A)


func test_an_item_is_always_held_up_facing_front() -> void:
	_anim.update(Vector2.RIGHT, 0.0)
	assert_bool(_anim.shows_flipped()).is_true()
	_anim.pose = PlayerAnimator.Pose.HOLD
	assert_that(_anim.region()).is_equal(Rect2(PlayerAnimator.HOLD * 16, 0, 16, 24))
	assert_bool(_anim.shows_flipped()).override_failure_message("the front view isn't mirrored").is_false()
	_anim.pose = PlayerAnimator.Pose.NONE
	assert_that(_anim.facing).override_failure_message("and the hero faces as before afterwards").is_equal(PlayerAnimator.Facing.SIDE)
	assert_bool(_anim.shows_flipped()).is_true()


func test_region_picks_the_frame_and_row() -> void:
	_anim.update(Vector2.UP, PlayerAnimator.STRIDE)
	assert_that(_anim.region()).is_equal(Rect2(PlayerAnimator.WALK_A * 16, 24, 16, 24))
	_anim.update(Vector2.LEFT, 0.0)
	assert_that(_anim.region()).is_equal(Rect2(0, 48, 16, 24))


func test_the_columns_are_the_ones_the_tool_paints() -> void:
	var tool: Dictionary = (load(TOOL) as GDScript).get_script_constant_map()
	var columns: Array = tool["COLUMNS"]
	var named: Dictionary = {
		"idle": PlayerAnimator.IDLE, "blink": PlayerAnimator.BLINK, "walk_a": PlayerAnimator.WALK_A,
		"pass_a": PlayerAnimator.PASS_A, "walk_b": PlayerAnimator.WALK_B, "pass_b": PlayerAnimator.PASS_B,
		"attack": PlayerAnimator.ATTACK, "hold": PlayerAnimator.HOLD, "fallen": PlayerAnimator.FALLEN,
	}
	assert_int(columns.size()).is_equal(PlayerAnimator.COLUMNS)
	for column: String in named:
		assert_int(columns.find(column)).override_failure_message(column).is_equal(int(named[column]))
	assert_array(tool["ROWS"]).override_failure_message("rows in Facing order").is_equal(["down", "up", "side"])
	var sheet: Texture2D = load(SHEET)
	assert_that(Vector2i(sheet.get_size())).is_equal(Vector2i(PlayerAnimator.COLUMNS * 16, 3 * 24))
	var image: Image = sheet.get_image()
	for row: int in 3:
		for column: int in PlayerAnimator.COLUMNS:
			var painted: int = 0
			for y: int in 24:
				for x: int in 16:
					if image.get_pixel(column * 16 + x, row * 24 + y).a > 0.0:
						painted += 1
			assert_int(painted).override_failure_message("row %d column %d is painted" % [row, column]).is_greater(40)
