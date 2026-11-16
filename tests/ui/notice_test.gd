extends GdUnitTestSuite
## News at the top of the screen doesn't replace news: a skill that rises as a quest moves on,
## or a mark gained as a recipe is taught, are both there to read, a line each. (Before this
## the later one took the earlier one's place, and the Warden's fall lost a line.)

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const VILLAGE: String = "res://world/areas/village/village.tscn"
const WEAVER: String = "res://world/areas/weaver_house/weaver_house.tscn"
const TEST_SLOT: int = 971

var _area: Node


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	GameState.set_time(float(GameState.day_clock().in_day("12:00")))
	SaveSystem.current_slot = TEST_SLOT
	GameState.set_flag(StoryGates.FIRST_CROP, true)
	GameState.set_flag(StoryGates.KEEP_GATE, true)
	Quests.refresh()


func after_test() -> void:
	if is_instance_valid(_area):
		_area.free()
	_area = null
	SaveSystem.erase_slot(TEST_SLOT)
	SaveSystem.current_slot = SaveSystem.GAME_SLOT
	GameState.clear()


func test_news_joins_news_and_all_of_it_goes_when_its_time_is_up() -> void:
	var village: AreaController = _load(VILLAGE)
	var hud: AreaHud = village.hud
	assert_str(hud.notice_text()).override_failure_message("a game already under way: nothing to tell").is_equal("")
	assert_array(Array(hud.notice_lines())).is_empty()
	hud.show_notice("New quest: The Lost Shuttle")
	assert_str(hud.notice_text()).is_equal("New quest: The Lost Shuttle")
	hud.show_notice("Farming rose to level 2.")
	assert_array(Array(hud.notice_lines())).is_equal(["New quest: The Lost Shuttle", "Farming rose to level 2."])
	assert_str(hud.notice_text()).override_failure_message("both on the screen, a line each").is_equal("New quest: The Lost Shuttle\nFarming rose to level 2.")
	# The same news again is one line still.
	hud.show_notice("Farming rose to level 2.")
	assert_int(hud.notice_lines().size()).is_equal(2)
	# Each new line gives the news its full time again.
	hud._process(AreaHud.NOTICE_TIME - 0.5)
	assert_int(hud.notice_lines().size()).is_equal(2)
	hud.show_notice("Pip: friendship 2 of 5.")
	hud._process(AreaHud.NOTICE_TIME - 0.5)
	assert_array(Array(hud.notice_lines())).is_equal(["New quest: The Lost Shuttle", "Farming rose to level 2.", "Pip: friendship 2 of 5."])
	# Past three lines the oldest gives way.
	hud.show_notice("New recipe: Berry Jam.")
	assert_array(Array(hud.notice_lines())).is_equal(["Farming rose to level 2.", "Pip: friendship 2 of 5.", "New recipe: Berry Jam."])
	# Its time up, all of it is gone, and the next news stands alone.
	hud._process(AreaHud.NOTICE_TIME + 0.1)
	assert_str(hud.notice_text()).is_equal("")
	assert_array(Array(hud.notice_lines())).is_empty()
	hud.show_notice("Quest complete: The Lost Shuttle")
	assert_array(Array(hud.notice_lines())).is_equal(["Quest complete: The Lost Shuttle"])


func test_the_wardens_fall_tells_of_the_skill_and_of_the_quest() -> void:
	assert_that(Quests.runner.stage(&"a_place_of_your_own")).is_equal(&"keep")
	GameState.skill_points[Skills.COMBAT] = 5
	var village: AreaController = _load(VILLAGE)
	# As the area does when a boss falls: the practice, then the flag his fall sets.
	GameState.practise(Skills.COMBAT, Skills.BOSS)
	GameState.set_flag(StoryGates.WARDEN_BEATEN, true)
	assert_int(GameState.skill_level(Skills.COMBAT)).is_equal(2)
	assert_that(Quests.runner.stage(&"a_place_of_your_own")).is_equal(&"rest")
	assert_array(Array(village.hud.notice_lines())).override_failure_message("neither line took the other's place").is_equal(["Combat rose to level 2.", "Quest updated: A Place of Your Own"])


func test_a_talk_that_gains_a_mark_and_a_lesson_tells_of_both() -> void:
	# One point short of two marks: the talk itself is the point, and at two marks Wenna teaches.
	GameState.add_friendship(&"wenna", GameState.friendship().points_per_mark * 2 - 1)
	var weaver: AreaController = _load(WEAVER)
	Steps.stand_before(weaver, "Wenna")
	assert_bool(weaver.interact()).is_true()
	assert_int(GameState.friend_marks(&"wenna")).is_equal(2)
	assert_bool(GameState.knows_recipe(&"berry_jam")).is_true()
	assert_array(Array(weaver.hud.notice_lines())).is_equal(["Wenna: friendship 2 of 5.", "New recipe: Berry Jam."])


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area
