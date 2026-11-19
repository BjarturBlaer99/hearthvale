extends GdUnitTestSuite
## PlayerAnimator: which way the sprite faces, the six-frame walk and run cycles, the blink and
## the breath while standing, the poses (a three-frame swing, an item held up, fallen) and the
## sheet region. Also that its columns are the ones tools/art/make_player_sprite.gd paints, and
## that the tool puts every frame together from the same parts (P1e).

const DIAGONAL: float = 0.70710678
const TOOL: String = "res://tools/art/make_player_sprite.gd"
const SHEET: String = "res://gameplay/player/player_sheet.png"
const W: int = 16
const H: int = 32

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
	assert_int(_anim.frame()).is_equal(PlayerAnimator.WALK_1)
	_anim.update(Vector2.LEFT, 0.0)
	assert_int(_anim.frame()).is_equal(PlayerAnimator.IDLE)
	assert_that(_anim.facing).is_equal(PlayerAnimator.Facing.SIDE)


func test_the_walk_cycle_has_six_frames_and_advances_with_distance_travelled() -> void:
	_anim.update(Vector2.DOWN, 0.5)
	assert_int(_anim.frame()).override_failure_message("setting off: legs passing, not a jump to a full step").is_equal(PlayerAnimator.WALK_6)
	_anim = PlayerAnimator.new()
	var frames: Array = []
	var bobs: Array = []
	for i: int in 7:
		_anim.update(Vector2.DOWN, PlayerAnimator.STRIDE)
		frames.append(_anim.frame())
		bobs.append(_anim.bob())
	assert_array(frames).is_equal([
		PlayerAnimator.WALK_1, PlayerAnimator.WALK_2, PlayerAnimator.WALK_3,
		PlayerAnimator.WALK_4, PlayerAnimator.WALK_5, PlayerAnimator.WALK_6, PlayerAnimator.WALK_1,
	])
	assert_array(bobs).override_failure_message("a dip as the weight comes onto each foot").is_equal([0, 1, 0, 0, 1, 0, 0])
	assert_int(PlayerAnimator.CYCLE.size()).is_equal(6)
	assert_float(PlayerAnimator.STRIDE * PlayerAnimator.CYCLE.size()).override_failure_message("a cycle covers the ground it did with four frames").is_equal_approx(28.0, 0.01)
	var slow: PlayerAnimator = PlayerAnimator.new()
	slow.update(Vector2.DOWN, PlayerAnimator.STRIDE * 0.5)
	assert_int(slow.frame()).is_equal(PlayerAnimator.WALK_6)
	slow.update(Vector2.DOWN, PlayerAnimator.STRIDE * 0.5)
	assert_int(slow.frame()).is_equal(PlayerAnimator.WALK_1)


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


func test_standing_the_hero_breathes() -> void:
	var out: float = 0.0
	var step: float = 1.0 / 60.0
	var changes: int = 0
	var last: int = PlayerAnimator.IDLE
	for i: int in roundi(PlayerAnimator.BREATH_EVERY * 2.0 / step):
		_anim.tick(step)
		var now: int = _anim.frame()
		assert_bool(now in [PlayerAnimator.IDLE, PlayerAnimator.BREATHE, PlayerAnimator.BLINK]).is_true()
		if now == PlayerAnimator.BREATHE:
			out += step
		if now != last and now != PlayerAnimator.BLINK and last != PlayerAnimator.BLINK:
			changes += 1
		last = now
	assert_float(out).override_failure_message("out for part of each breath").is_between(PlayerAnimator.BREATH_OUT, PlayerAnimator.BREATH_OUT * 2.0 + 0.1)
	assert_int(changes).override_failure_message("slow, not a twitch").is_less_equal(4)
	assert_float(PlayerAnimator.BREATH_OUT).is_less(PlayerAnimator.BREATH_EVERY / 2.0)


func test_sprinting_uses_the_run_cycle_with_a_longer_stride() -> void:
	_anim.sprinting = true
	_anim.update(Vector2.LEFT, 0.5)
	var seen: Array[int] = [_anim.frame()]
	for i: int in 6:
		_anim.update(Vector2.LEFT, PlayerAnimator.RUN_STRIDE)
		seen.append(_anim.frame())
	assert_array(seen).is_equal([
		PlayerAnimator.RUN_6, PlayerAnimator.RUN_1, PlayerAnimator.RUN_2, PlayerAnimator.RUN_3,
		PlayerAnimator.RUN_4, PlayerAnimator.RUN_5, PlayerAnimator.RUN_6,
	])
	assert_int(PlayerAnimator.RUN_CYCLE.size()).is_equal(PlayerAnimator.CYCLE.size())
	assert_float(PlayerAnimator.RUN_STRIDE).override_failure_message("a running step covers more ground").is_greater(PlayerAnimator.STRIDE)
	_anim.update(Vector2.LEFT, PlayerAnimator.RUN_STRIDE)
	assert_int(_anim.bob()).override_failure_message("no dip on the step itself").is_equal(0)
	_anim.update(Vector2.LEFT, PlayerAnimator.RUN_STRIDE)
	assert_int(_anim.bob()).override_failure_message("the run dips as the weight comes down too").is_equal(1)
	_anim.sprinting = false
	assert_int(_anim.frame()).override_failure_message("slowing to a walk keeps the same step").is_equal(PlayerAnimator.WALK_2)


func test_a_swing_has_a_wind_up_a_slash_and_a_follow_through() -> void:
	_anim.pose = PlayerAnimator.Pose.ATTACK
	var by_progress: Dictionary = {
		0.0: PlayerAnimator.WINDUP, 0.1: PlayerAnimator.WINDUP,
		0.2: PlayerAnimator.ATTACK, 0.5: PlayerAnimator.ATTACK,
		0.6: PlayerAnimator.FOLLOW, 0.9: PlayerAnimator.FOLLOW, 1.0: PlayerAnimator.FOLLOW,
	}
	for progress: float in by_progress:
		_anim.attack_progress = progress
		assert_int(_anim.frame()).override_failure_message("at %.1f" % progress).is_equal(int(by_progress[progress]))
	assert_float(PlayerAnimator.WINDUP_UNTIL).override_failure_message("the wind-up is short").is_less(0.25)
	assert_float(PlayerAnimator.FOLLOW_FROM - PlayerAnimator.WINDUP_UNTIL).override_failure_message("the slash is the longest of the three").is_greater(1.0 - PlayerAnimator.FOLLOW_FROM)


func test_hurt_and_landing_have_poses_of_their_own() -> void:
	_anim.update(Vector2.UP, PlayerAnimator.STRIDE)
	_anim.pose = PlayerAnimator.Pose.HURT
	assert_that(_anim.region()).override_failure_message("flinching, in the facing's own row").is_equal(Rect2(PlayerAnimator.HURT * W, H, W, H))
	_anim.pose = PlayerAnimator.Pose.LAND
	assert_int(_anim.frame()).override_failure_message("knees bent").is_equal(PlayerAnimator.BREATHE)
	assert_int(_anim.bob()).is_equal(0)


func test_the_made_frames_come_from_the_drawn_ones() -> void:
	var tool: GDScript = load(TOOL)
	var constants: Dictionary = tool.get_script_constant_map()
	var columns: Array = constants["COLUMNS"]
	var named: Dictionary = {
		"breathe": PlayerAnimator.BREATHE, "hurt": PlayerAnimator.HURT,
		"run_1": PlayerAnimator.RUN_1, "run_2": PlayerAnimator.RUN_2, "run_3": PlayerAnimator.RUN_3,
		"run_4": PlayerAnimator.RUN_4, "run_5": PlayerAnimator.RUN_5, "run_6": PlayerAnimator.RUN_6,
	}
	for column: String in named:
		assert_int(columns.find(column)).override_failure_message(column).is_equal(int(named[column]))
	for facing: String in constants["ROWS"]:
		var drawn: Array = tool.call(&"drawn", facing)
		var made: Array = tool.call(&"derived", facing)
		assert_int(drawn.size() + made.size() + (tool.call(&"worked", facing) as Array).size()).is_equal(columns.size())
		var idle: Array = drawn[PlayerAnimator.IDLE]
		var breathe: Array = made[PlayerAnimator.BREATHE - drawn.size()]
		assert_int(breathe.size()).is_equal(H)
		assert_that(breathe[H - 1]).override_failure_message("%s: the feet stay on the ground" % facing).is_equal(idle[H - 1])
		assert_that(breathe[3]).override_failure_message("%s: the head is a pixel lower" % facing).is_equal(idle[2])
		for step: int in 6:
			var walk: Array = drawn[PlayerAnimator.WALK_1 + step]
			var run: Array = made[PlayerAnimator.RUN_1 + step - drawn.size()]
			assert_that(run[H - 2]).override_failure_message("%s: the feet land where a walking step does" % facing).is_equal(walk[H - 2])
			if facing == "side":
				assert_that(run[8]).override_failure_message("the head leans a pixel forward").is_equal(str(walk[8]).substr(1) + ".")
				assert_that(run[20]).override_failure_message("below the belt nothing leans").is_equal(walk[20])
			else:
				assert_array(run).override_failure_message("%s: running is the walk, seen from the front or back" % facing).is_equal(walk)
		# The sword is on his back until he swings it.
		var hilt: bool = false
		for line: String in idle:
			hilt = hilt or "G" in line
		assert_bool(hilt).override_failure_message("%s: the hilt shows when standing" % facing).is_equal(facing != "side")
		for column: int in [PlayerAnimator.WINDUP, PlayerAnimator.ATTACK, PlayerAnimator.FOLLOW]:
			for line: String in drawn[column]:
				assert_bool("G" in line).override_failure_message("%s: no hilt on his back mid-swing" % facing).is_false()


func test_every_frame_of_a_facing_is_put_together_from_the_same_parts() -> void:
	var tool: GDScript = load(TOOL)
	var constants: Dictionary = tool.get_script_constant_map()
	var head_rows: int = constants["HEAD_ROWS"]
	var body_rows: int = constants["BODY_ROWS"]
	assert_int(head_rows + body_rows + int(constants["LEG_ROWS"])).override_failure_message("head, body and legs fill the frame").is_equal(H)
	var built: Array[int] = [
		PlayerAnimator.BLINK, PlayerAnimator.WALK_1, PlayerAnimator.WALK_2, PlayerAnimator.WALK_3,
		PlayerAnimator.WALK_4, PlayerAnimator.WALK_5, PlayerAnimator.WALK_6,
		PlayerAnimator.WINDUP, PlayerAnimator.ATTACK, PlayerAnimator.FOLLOW,
	]
	for facing: String in constants["ROWS"]:
		var drawn: Array = tool.call(&"drawn", facing)
		var idle: Array = drawn[PlayerAnimator.IDLE]
		for column: int in built:
			# Rows 8 to 11 are where the eyes close, the hilt shows and a raised hand reaches.
			assert_array((drawn[column] as Array).slice(0, 8)).override_failure_message("%s, column %d: the same head" % [facing, column]).is_equal(idle.slice(0, 8))
			assert_that(drawn[column][head_rows + body_rows - 1]).override_failure_message("%s, column %d: the same hem" % [facing, column]).is_equal(idle[head_rows + body_rows - 1])
		# The hood is down: hair on his head, the hood's blue only below it.
		var hair: bool = false
		for y: int in 10:
			var line: String = idle[y]
			hair = hair or "h" in line
			assert_bool("m" in line or "D" in line).override_failure_message("%s: no hood on his head (row %d)" % [facing, y]).is_false()
		assert_bool(hair).override_failure_message("%s: his hair shows" % facing).is_true()
		# The second half of the walk is the first on the other foot.
		for step: int in 3:
			var first: Array = (drawn[PlayerAnimator.WALK_1 + step] as Array).slice(head_rows + body_rows)
			var second: Array = (drawn[PlayerAnimator.WALK_4 + step] as Array).slice(head_rows + body_rows)
			for y: int in first.size():
				var line: String = first[y]
				var other: String = line.replace("p", "#").replace("P", "p").replace("#", "P") if facing == "side" else line.reverse()
				assert_that(second[y]).override_failure_message("%s: step %d on the other foot (row %d)" % [facing, step + 1, y]).is_equal(other)
			assert_array(second).override_failure_message("%s: and it isn't the same picture twice" % facing).is_not_equal(first)
	var back: Array = tool.call(&"frame", "up", "idle")
	assert_bool("mmmm" in str(back[head_rows + 1])).override_failure_message("from behind, the hood hangs between his shoulders").is_true()


func test_poses_override_walking_and_standing() -> void:
	_anim.update(Vector2.LEFT, PlayerAnimator.STRIDE)
	_anim.pose = PlayerAnimator.Pose.ATTACK
	assert_int(_anim.frame()).is_equal(PlayerAnimator.ATTACK)
	assert_int(_anim.bob()).override_failure_message("no bob in a pose").is_equal(0)
	assert_that(_anim.region()).override_failure_message("attacking shows the facing's own row").is_equal(Rect2(PlayerAnimator.ATTACK * W, 2 * H, W, H))
	_anim.pose = PlayerAnimator.Pose.FALLEN
	assert_int(_anim.frame()).is_equal(PlayerAnimator.FALLEN)
	_anim.pose = PlayerAnimator.Pose.NONE
	assert_int(_anim.frame()).is_equal(PlayerAnimator.WALK_1)


func test_an_item_is_always_held_up_facing_front() -> void:
	_anim.update(Vector2.RIGHT, 0.0)
	assert_bool(_anim.shows_flipped()).is_true()
	_anim.pose = PlayerAnimator.Pose.HOLD
	assert_that(_anim.region()).is_equal(Rect2(PlayerAnimator.HOLD * W, 0, W, H))
	assert_bool(_anim.shows_flipped()).override_failure_message("the front view isn't mirrored").is_false()
	_anim.pose = PlayerAnimator.Pose.NONE
	assert_that(_anim.facing).override_failure_message("and the hero faces as before afterwards").is_equal(PlayerAnimator.Facing.SIDE)
	assert_bool(_anim.shows_flipped()).is_true()


func test_region_picks_the_frame_and_row() -> void:
	assert_that(PlayerAnimator.FRAME_SIZE).override_failure_message("a cell wide, two cells tall").is_equal(Vector2i(W, H))
	_anim.update(Vector2.UP, PlayerAnimator.STRIDE)
	assert_that(_anim.region()).is_equal(Rect2(PlayerAnimator.WALK_1 * W, H, W, H))
	_anim.update(Vector2.LEFT, 0.0)
	assert_that(_anim.region()).is_equal(Rect2(0, 2 * H, W, H))


func test_the_columns_are_the_ones_the_tool_paints() -> void:
	var tool: Dictionary = (load(TOOL) as GDScript).get_script_constant_map()
	var columns: Array = tool["COLUMNS"]
	var named: Dictionary = {
		"idle": PlayerAnimator.IDLE, "blink": PlayerAnimator.BLINK,
		"walk_1": PlayerAnimator.WALK_1, "walk_2": PlayerAnimator.WALK_2, "walk_3": PlayerAnimator.WALK_3,
		"walk_4": PlayerAnimator.WALK_4, "walk_5": PlayerAnimator.WALK_5, "walk_6": PlayerAnimator.WALK_6,
		"windup": PlayerAnimator.WINDUP, "slash": PlayerAnimator.ATTACK, "follow": PlayerAnimator.FOLLOW,
		"hold": PlayerAnimator.HOLD, "fallen": PlayerAnimator.FALLEN,
	}
	assert_int(columns.size()).is_equal(PlayerAnimator.COLUMNS)
	for column: String in named:
		assert_int(columns.find(column)).override_failure_message(column).is_equal(int(named[column]))
	assert_array(tool["ROWS"]).override_failure_message("rows in Facing order").is_equal(["down", "up", "side"])
	var sheet: Texture2D = load(SHEET)
	assert_that(Vector2i(sheet.get_size())).is_equal(Vector2i(PlayerAnimator.COLUMNS * W, 3 * H))
	var image: Image = sheet.get_image()
	for row: int in 3:
		for column: int in PlayerAnimator.COLUMNS:
			var painted: int = 0
			var soles: int = 0
			for y: int in H:
				for x: int in W:
					if image.get_pixel(column * W + x, row * H + y).a > 0.0:
						painted += 1
						soles += 1 if y == H - 1 else 0
			assert_int(painted).override_failure_message("row %d column %d is painted" % [row, column]).is_greater(40)
			assert_int(soles).override_failure_message("row %d column %d stands on the frame's last row" % [row, column]).is_greater(0)


func test_the_work_poses_are_the_last_four_columns_and_keep_the_sword_on_his_back() -> void:
	var tool: GDScript = load(TOOL)
	var constants: Dictionary = tool.get_script_constant_map()
	var columns: Array = constants["COLUMNS"]
	for pose: StringName in PlayerAnimator.WORK_COLUMNS:
		assert_int(columns.find(String(pose))).override_failure_message(String(pose)).is_equal(int(PlayerAnimator.WORK_COLUMNS[pose]))
	assert_int(PlayerAnimator.REACH).override_failure_message("the last column").is_equal(PlayerAnimator.COLUMNS - 1)
	for facing: String in constants["ROWS"]:
		var worked: Array = tool.call(&"worked", facing)
		assert_int(worked.size()).is_equal(4)
		var idle: Array = tool.call(&"frame", facing, "idle")
		var reach: Array = worked[3]
		assert_that(reach[3]).override_failure_message("%s: a reach is a pixel lower" % facing).is_equal(tool.call(&"frame", facing, "follow")[2])
		for frame: Array in worked:
			assert_int(frame.size()).is_equal(H)
		# The hilt over his shoulder (from the side the hood hides it): as idle, not as a swing.
		for mark: Array in (constants["HILTS"] as Dictionary)[facing]:
			if int(mark[0]) < 8:
				continue
			assert_str(str(worked[1][mark[0]])[mark[1]]).override_failure_message("%s strike: the sword stays on his back" % facing).is_equal(str(idle[mark[0]])[mark[1]])
	_anim.update(Vector2.LEFT, 0.0)
	_anim.pose = PlayerAnimator.Pose.WORK
	_anim.work_pose = &"strike"
	assert_that(_anim.region()).is_equal(Rect2(PlayerAnimator.STRIKE * W, 2 * H, W, H))
	_anim.work_pose = &"reach"
	assert_int(_anim.frame()).is_equal(PlayerAnimator.REACH)
	assert_int(_anim.bob()).is_equal(0)
