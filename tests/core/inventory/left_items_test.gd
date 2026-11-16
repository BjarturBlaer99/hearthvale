extends GdUnitTestSuite
## LeftItems: the names of the flags that keep what a full pack couldn't take, and reading them
## back: what is owed, what lies in an area, and how he is told.


func test_the_flags_are_named_for_the_item_and_the_place() -> void:
	assert_that(LeftItems.owed_flag(&"arrow")).is_equal(&"owed/arrow")
	assert_that(LeftItems.lying_flag(&"village", Vector2i(18, 23), &"arrow")).is_equal(&"left/village/18,23/arrow")
	assert_that(LeftItems.lying_flag(&"old_wood", Vector2i(0, 4), &"wild_berries")).is_equal(&"left/old_wood/0,4/wild_berries")


func test_a_count_is_a_whole_number_above_nothing() -> void:
	assert_int(LeftItems.count_of(6)).is_equal(6)
	assert_int(LeftItems.count_of(6.0)).override_failure_message("a save gives floats back").is_equal(6)
	assert_int(LeftItems.count_of(0)).is_equal(0)
	assert_int(LeftItems.count_of(-3)).is_equal(0)
	assert_int(LeftItems.count_of(false)).override_failure_message("a flag that isn't there").is_equal(0)
	assert_int(LeftItems.count_of(true)).is_equal(0)
	assert_int(LeftItems.count_of("6")).is_equal(0)


func test_what_is_owed_is_read_from_the_flags() -> void:
	var flags: Dictionary = {&"owed/coin": 12, "owed/arrow": 6.0, &"owed/bomb": 0, &"owed/": 3, &"took_hoe": true,
		&"left/village/18,23/arrow": 2}
	var owed: Array[Dictionary] = LeftItems.owed(flags)
	assert_int(owed.size()).is_equal(2)
	assert_that(owed[0]["item"]).is_equal(&"arrow")
	assert_int(int(owed[0]["count"])).is_equal(6)
	assert_that(owed[0]["flag"]).is_equal(&"owed/arrow")
	assert_that(owed[1]["item"]).is_equal(&"coin")
	assert_array(LeftItems.owed({})).is_empty()


func test_what_lies_in_an_area_is_read_from_the_flags() -> void:
	var flags: Dictionary = {
		&"left/village/18,23/arrow": 6,
		"left/village/18,23/coin": 40.0,
		&"left/village/3,4/bomb": 0,
		&"left/village_green/1,1/arrow": 9,
		&"left/old_wood/5,5/arrow": 1,
		&"left/village/nowhere/arrow": 2,
		&"left/village/7,8": 2,
		&"owed/arrow": 3,
	}
	var lying: Array[Dictionary] = LeftItems.lying_in(flags, &"village")
	assert_int(lying.size()).override_failure_message("two in the village: not the empty one, another area's or a broken name").is_equal(2)
	assert_that(lying[0]["cell"]).is_equal(Vector2i(18, 23))
	assert_that(lying[0]["item"]).is_equal(&"arrow")
	assert_int(int(lying[0]["count"])).is_equal(6)
	assert_that(lying[0]["flag"]).is_equal(&"left/village/18,23/arrow")
	assert_that(lying[1]["item"]).is_equal(&"coin")
	assert_int(int(lying[1]["count"])).is_equal(40)
	assert_int(LeftItems.lying_in(flags, &"old_wood").size()).is_equal(1)
	assert_array(LeftItems.lying_in(flags, &"keep")).is_empty()


func test_a_flag_made_for_a_place_is_read_back_as_that_place() -> void:
	var flag: StringName = LeftItems.lying_flag(&"north_fields", Vector2i(31, 7), &"wild_berries")
	var lying: Array[Dictionary] = LeftItems.lying_in({flag: 4}, &"north_fields")
	assert_that(lying[0]["cell"]).is_equal(Vector2i(31, 7))
	assert_that(lying[0]["item"]).is_equal(&"wild_berries")


func test_he_is_told_what_lies_at_his_feet() -> void:
	assert_str(LeftItems.words("Arrows", 6)).is_equal("No room in your pack. At your feet: Arrows x6.")
	assert_str(LeftItems.words("Bow", 1)).is_equal("No room in your pack. At your feet: Bow.")
