extends GdUnitTestSuite
## Characters (P1e): villagers stand as tall as the hero on the same spot they always stood on,
## still fill exactly their own cell, and breathe and blink in their own time.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const VILLAGE: String = "res://world/areas/village/village.tscn"
const STEP: float = 1.0 / 30.0

var _area: Node


func before_test() -> void:
	GameState.clear()
	GameState.new_game()


func after_test() -> void:
	if is_instance_valid(_area):
		_area.free()
	_area = null
	GameState.clear()


func test_villagers_are_as_tall_as_the_hero_and_stand_where_they_stood() -> void:
	assert_that(Villager.SIZE).is_equal(PlayerAnimator.FRAME_SIZE)
	assert_that(Vector2i(Villager.SHEET.get_size())).is_equal(Vector2i(Villager.SIZE.x * Villager.FRAMES.size(), Villager.SIZE.y * 2))
	assert_float(Villager.FEET_Y).override_failure_message("their feet are where they were, mid-cell").is_equal(9.0)
	# The lowest painted row of every frame is the frame's last: nobody floats.
	var image: Image = Villager.SHEET.get_image()
	for frame: StringName in Villager.FRAMES:
		var soles: int = 0
		var crown: int = -1
		for y: int in Villager.SIZE.y:
			for x: int in Villager.SIZE.x:
				if image.get_pixel(int(Villager.FRAMES[frame]) * Villager.SIZE.x + x, y).a > 0.0:
					soles += 1 if y == Villager.SIZE.y - 1 else 0
					crown = y if crown < 0 else crown
		assert_int(soles).override_failure_message("%s stands on the last row" % frame).is_greater(0)
		assert_int(crown).override_failure_message("%s: the head tops out where the hero's does" % frame).is_between(2, 3)
	var village: AreaController = _load(VILLAGE)
	var oda: Villager = village.interactables.get_node(^"FarmerOda")
	assert_bool(oda.covers(oda.cell())).is_true()
	assert_bool(oda.covers(oda.cell() + Vector2i.UP)).override_failure_message("taller, but only their own cell is theirs").is_false()
	assert_bool(village.terrain.is_occupied(oda.cell())).is_true()
	for side: Vector2i in [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
		assert_bool(village.terrain.is_occupied(oda.cell() + side)).override_failure_message("nothing around them is taken up: %s" % side).is_false()


func test_villagers_breathe_and_blink_in_their_own_time() -> void:
	var village: AreaController = _load(VILLAGE)
	var oda: Villager = village.interactables.get_node(^"FarmerOda")
	var pip: Villager = village.interactables.get_node(^"Pip")
	var seen: Dictionary = {}
	var apart: int = 0
	for i: int in roundi(Idling.BREATH_EVERY * Idling.BLINK_EVERY / STEP):
		oda._process(STEP)
		pip._process(STEP)
		assert_bool(Villager.FRAMES.has(oda.frame())).override_failure_message(String(oda.frame())).is_true()
		seen[String(oda.frame()).trim_prefix("bearded").trim_prefix("plain")] = true
		apart += 1 if String(oda.frame()).get_slice("_", 1) != String(pip.frame()).get_slice("_", 1) else 0
	assert_array(seen.keys()).override_failure_message("standing, breathing out, blinking").contains_exactly_in_any_order(["", "_breathe", "_blink"])
	assert_int(apart).override_failure_message("two villagers don't breathe as one").is_greater(20)
	assert_bool(String(oda.frame()).begins_with("bearded" if oda.beard else "plain")).override_failure_message("and they keep their own face").is_true()


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area
