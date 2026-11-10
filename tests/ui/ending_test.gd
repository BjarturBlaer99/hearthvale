extends GdUnitTestSuite
## The ending (H15): taking the Shade's heart opens the crypt's closing words, and when they
## are done the area leaves for the ending screen, once. The screen shows the time played, the
## hearts and the quests finished; "Keep exploring" goes back to where the hero stood, and
## "Save and go to the title" saves first. Uses its own save slot, and removes it.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const CRYPT: String = "res://world/areas/crypt/crypt.tscn"
const ENDING: String = "res://ui/ending_screen.tscn"
const TITLE: String = "res://ui/title_screen.tscn"
const TEST_SLOT: int = 993

var _area: Node


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	SaveSystem.current_slot = TEST_SLOT


func after_test() -> void:
	if is_instance_valid(_area):
		_area.free()
	_area = null
	get_tree().paused = false
	if SaveSystem.has_slot(TEST_SLOT):
		DirAccess.remove_absolute(SaveSystem.slot_path(TEST_SLOT))
	SaveSystem.current_slot = SaveSystem.GAME_SLOT
	GameState.clear()


func test_the_crypts_closing_words_lead_to_the_ending_screen_once() -> void:
	GameState.set_flag(&"crypt_shade_beaten", true)
	var crypt: AreaController = _load(CRYPT)
	var travelled: Array[String] = []
	crypt.travel = func(path: String) -> void: travelled.append(path)
	var heart: HeartContainer = crypt.interactables.get_node(^"HeartContainer")
	crypt.player.motor.place(heart.cell())
	crypt.player.sync_from_motor()
	assert_int(crypt.collect_pickups()).is_equal(1)
	assert_bool(crypt.is_talking()).is_true()
	assert_str(crypt.hud.dialogue.shown_text()).contains("Shade is gone")
	crypt.hud.dialogue.confirm()
	assert_str(crypt.hud.dialogue.shown_text()).contains("Aldric").contains("Hearthvale sleeps")
	assert_array(travelled).override_failure_message("not before the last words are read").is_empty()
	crypt.hud.dialogue.confirm()
	assert_bool(crypt.is_talking()).is_false()
	assert_bool(GameState.get_flag(AreaController.ENDING_FLAG) == true).is_true()
	assert_array(travelled).is_equal([ENDING])
	assert_str(str(GameState.player.get("area", ""))).override_failure_message("the hero's place is kept").is_equal("crypt")
	assert_array(GameState.player.get("cell", [])).is_equal([heart.cell().x, heart.cell().y])
	assert_bool(crypt.interact()).override_failure_message("nothing more happens on the way out").is_false()
	# Back in the crypt afterwards, conversations end as they always did.
	crypt = _load(CRYPT)
	var later: Array[String] = []
	crypt.travel = func(path: String) -> void: later.append(path)
	crypt.player.motor.place(Vector2i(24, 41))
	crypt.player.face(Vector2.DOWN)
	assert_bool(crypt.interact()).override_failure_message("reading the inscription").is_true()
	crypt.hud.dialogue.confirm()
	assert_bool(crypt.is_talking()).is_false()
	assert_array(later).override_failure_message("the ending doesn't play twice").is_empty()


func test_the_ending_screen_sums_up_the_game() -> void:
	GameState.add_play_time(4031.0)
	GameState.add_heart_container()
	GameState.add_heart_container()
	GameState.set_quest_stage(&"lost_shuttle", &"find")
	GameState.set_flag(QuestState.complete_flag(&"slime_bounty"), true)
	var screen: EndingScreen = _screen()
	assert_str(screen.shown_stats()).contains("Time played   1:07:11")
	assert_str(screen.shown_stats()).contains("Hearts   5")
	assert_str(screen.shown_stats()).override_failure_message("one quest finished, one only begun").contains("Quests finished   1 of %d" % DataRegistry.ids(&"quests").size())
	assert_array(Array(screen.shown_lines())).is_equal(["> Keep exploring", "  Save and go to the title"])
	assert_bool((screen.get_node(^"Backdrop") as TitleBackdrop).keep_lit).override_failure_message("the keep's window is dark").is_false()


func test_keep_exploring_goes_back_to_where_the_hero_stood() -> void:
	GameState.update_player(&"crypt", Vector2i(22, 13))
	var screen: EndingScreen = _screen()
	var travelled: Array[String] = []
	screen.travel = func(path: String) -> void: travelled.append(path)
	screen._unhandled_input(_pressed(&"interact"))
	assert_array(travelled).is_equal([CRYPT])
	assert_bool(SaveSystem.has_save()).override_failure_message("nothing is saved unasked").is_false()
	screen.queue_free()
	var crypt: AreaController = _load(CRYPT)
	assert_that(crypt.player.motor.cell).is_equal(Vector2i(22, 13))


func test_save_and_go_to_the_title_saves_first() -> void:
	GameState.update_player(&"crypt", Vector2i(22, 13))
	GameState.set_flag(AreaController.ENDING_FLAG, true)
	var screen: EndingScreen = _screen()
	var travelled: Array[String] = []
	screen.travel = func(path: String) -> void: travelled.append(path)
	screen.move_cursor(1)
	screen.choose()
	assert_array(travelled).is_equal([TITLE])
	assert_bool(SaveSystem.has_save()).is_true()
	GameState.clear()
	assert_int(SaveSystem.load_game()).is_equal(OK)
	assert_bool(GameState.get_flag(AreaController.ENDING_FLAG) == true).override_failure_message("the save remembers the game was finished").is_true()
	assert_str(str(GameState.player.get("area", ""))).is_equal("crypt")


func _screen() -> EndingScreen:
	var screen: EndingScreen = auto_free((load(ENDING) as PackedScene).instantiate())
	add_child(screen)
	return screen


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area


func _pressed(action: StringName) -> InputEventAction:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = true
	return event
