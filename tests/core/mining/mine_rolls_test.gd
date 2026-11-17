extends GdUnitTestSuite
## The day's roll for a floor of the mine (MineRolls, pure): which rocks hold ore and which
## plain rock hides the ladder. The same all day and after a load; another one tomorrow, on
## another floor, and in another game; never two things in one rock.

const ORES: Dictionary = {&"copper_ore": 5}
const DEEP: Dictionary = {&"gold_ore": 2, &"crystal": 1, &"coal": 2}


## Sixteen rocks in a block, like a floor's.
func _cells(count: int = 16) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	for index: int in count:
		@warning_ignore("integer_division")
		out.append(Vector2i(2 + index % 6, 3 + index / 6))
	return out


func _count(kinds: Dictionary, kind: StringName) -> int:
	var found: int = 0
	for cell: Vector2i in kinds:
		if kinds[cell] == kind:
			found += 1
	return found


func test_a_roll_gives_every_rock_a_kind_and_exactly_the_ore_asked_for() -> void:
	var roll: Dictionary = MineRolls.roll(77, 3, 2, _cells(), ORES, true)
	var kinds: Dictionary = roll["kinds"]
	assert_int(kinds.size()).override_failure_message("every rock holds something").is_equal(16)
	for cell: Vector2i in _cells():
		assert_bool(kinds.has(cell)).override_failure_message("%s" % cell).is_true()
	assert_int(_count(kinds, &"copper_ore")).is_equal(5)
	assert_int(_count(kinds, MineRules.STONE)).is_equal(11)
	var deep: Dictionary = MineRolls.roll(77, 3, 8, _cells(14), DEEP, true)["kinds"]
	assert_int(_count(deep, &"gold_ore")).is_equal(2)
	assert_int(_count(deep, &"crystal")).is_equal(1)
	assert_int(_count(deep, &"coal")).is_equal(2)
	assert_int(_count(deep, MineRules.STONE)).is_equal(9)


func test_the_ladder_is_under_a_plain_rock_and_only_where_there_is_one() -> void:
	for day: int in range(1, 60):
		var roll: Dictionary = MineRolls.roll(5, day, 1, _cells(), ORES, true)
		var ladder: Vector2i = roll["ladder"]
		assert_bool(_cells().has(ladder)).override_failure_message("day %d: under one of the rocks" % day).is_true()
		assert_that(roll["kinds"][ladder]).override_failure_message("day %d: never under ore" % day).is_equal(MineRules.STONE)
	# The last floor has none.
	assert_that(MineRolls.roll(5, 1, 9, _cells(), ORES, false)["ladder"]).is_equal(MineRolls.NO_CELL)
	# With no rocks there is nowhere to hide it, and nothing to hold.
	var bare: Dictionary = MineRolls.roll(5, 1, 1, [], ORES, true)
	assert_that(bare["ladder"]).is_equal(MineRolls.NO_CELL)
	assert_dict(bare["kinds"]).is_empty()


func test_the_roll_is_the_same_all_day_whatever_order_the_rocks_are_given_in() -> void:
	var cells: Array[Vector2i] = _cells()
	var first: Dictionary = MineRolls.roll(1234, 6, 4, cells, DEEP, true)
	assert_dict(MineRolls.roll(1234, 6, 4, cells, DEEP, true)).override_failure_message("asked twice").is_equal(first)
	var turned: Array[Vector2i] = cells.duplicate()
	turned.reverse()
	assert_dict(MineRolls.roll(1234, 6, 4, turned, DEEP, true)).override_failure_message("the rocks named backwards").is_equal(first)
	assert_array(cells).override_failure_message("the list handed in is left as it was").is_equal(_cells())


func test_another_day_another_floor_and_another_game_roll_differently() -> void:
	var cells: Array[Vector2i] = _cells()
	var today: Dictionary = MineRolls.roll(1234, 6, 4, cells, ORES, true)
	var changed: Dictionary = {"day": 0, "floor": 0, "game": 0}
	for step: int in range(1, 9):
		if MineRolls.roll(1234, 6 + step, 4, cells, ORES, true) != today:
			changed["day"] += 1
		if MineRolls.roll(1234, 6, 4 + step, cells, ORES, true) != today:
			changed["floor"] += 1
		if MineRolls.roll(1234 + step, 6, 4, cells, ORES, true) != today:
			changed["game"] += 1
	for what: String in changed:
		assert_int(changed[what]).override_failure_message("another %s is another roll (of eight tried)" % what).is_greater(6)


func test_over_many_days_every_rock_hides_the_ladder_and_holds_ore_some_time() -> void:
	var cells: Array[Vector2i] = _cells()
	var hid: Dictionary = {}
	var held: Dictionary = {}
	for day: int in range(1, 401):
		var roll: Dictionary = MineRolls.roll(99, day, 3, cells, ORES, true)
		hid[roll["ladder"]] = true
		for cell: Vector2i in roll["kinds"]:
			if roll["kinds"][cell] != MineRules.STONE:
				held[cell] = true
	assert_int(hid.size()).override_failure_message("no rock is never the ladder's").is_equal(16)
	assert_int(held.size()).override_failure_message("no rock never holds ore").is_equal(16)


func test_with_more_ore_than_rocks_the_first_kinds_get_theirs_and_no_ladder_fits() -> void:
	var roll: Dictionary = MineRolls.roll(8, 2, 1, _cells(4), {&"gold_ore": 3, &"coal": 5}, true)
	var kinds: Dictionary = roll["kinds"]
	assert_int(kinds.size()).is_equal(4)
	assert_int(_count(kinds, &"gold_ore")).is_equal(3)
	assert_int(_count(kinds, &"coal")).is_equal(1)
	assert_that(roll["ladder"]).override_failure_message("no plain rock is left to hide it").is_equal(MineRolls.NO_CELL)
	# Exactly as much ore as rocks: the same.
	assert_that(MineRolls.roll(8, 2, 1, _cells(5), ORES, true)["ladder"]).is_equal(MineRolls.NO_CELL)
	# One rock over: it is the ladder's.
	var one_over: Dictionary = MineRolls.roll(8, 2, 1, _cells(6), ORES, true)
	assert_that(one_over["kinds"][one_over["ladder"]]).is_equal(MineRules.STONE)
	assert_int(_count(one_over["kinds"], MineRules.STONE)).is_equal(1)
