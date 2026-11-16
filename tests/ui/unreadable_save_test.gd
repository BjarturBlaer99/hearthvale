extends GdUnitTestSuite
## A save that can't be read (the fix round of 2026-11-16): Continue says so and offers the
## save before it, which is kept as a backup. If that can't be read either, or there is none,
## it says that and the title stays. A good save loads with nothing said. Uses a slot and a
## settings file of its own.

const TITLE: String = "res://ui/title_screen.tscn"
const VILLAGE: String = "res://world/areas/village/village.tscn"
const WOOD: String = "res://world/areas/old_wood/old_wood.tscn"
const TEST_SLOT: int = 966
const TEST_SETTINGS: String = "user://test_settings_unreadable.cfg"
const HALF: String = "{ \"version\": 4, \"inv"

var _title_screen: TitleScreen
var _travelled: Array[String] = []


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	SaveSystem.erase_slot(TEST_SLOT)
	SaveSystem.current_slot = TEST_SLOT
	Settings.path = TEST_SETTINGS
	Settings.load_settings()
	_travelled = []


func after_test() -> void:
	if is_instance_valid(_title_screen):
		_title_screen.free()
	_title_screen = null
	SaveSystem.erase_slot(TEST_SLOT)
	SaveSystem.current_slot = SaveSystem.GAME_SLOT
	if FileAccess.file_exists(TEST_SETTINGS):
		DirAccess.remove_absolute(TEST_SETTINGS)
	Settings.path = Settings.PATH
	Settings.load_settings()
	GameState.clear()


func test_a_good_save_loads_with_nothing_said() -> void:
	_two_saves()
	var title: TitleScreen = _title()
	assert_str(title.shown_lines()[0]).is_equal("> Continue   Hearthvale, 2:00")
	assert_str(title.notice()).is_empty()
	title.choose()
	assert_array(_travelled).is_equal([VILLAGE])
	assert_int(GameState.item_count(&"coin")).is_equal(12)
	assert_str(title.notice()).is_empty()


func test_a_broken_save_says_so_and_offers_the_one_before_it() -> void:
	_two_saves()
	_break(SaveSystem.slot_path(TEST_SLOT))
	var title: TitleScreen = _title()
	# Nothing can be said of a save that can't be read, but Continue can be chosen.
	assert_array(Array(title.shown_lines())).is_equal(["> Continue", "  New game", "  Settings", "  Quit"])
	title.choose()
	assert_array(_travelled).override_failure_message("nowhere yet").is_empty()
	assert_str(title.notice()).is_equal(TitleScreen.OFFER_WORDS % "The Old Wood, 1:00")
	assert_array(Array(title.shown_lines())).is_equal(["> Load the earlier save", "  Back"])
	assert_bool(title.is_offering_backup()).is_true()
	assert_int(GameState.item_count(&"coin")).override_failure_message("nothing is loaded until he says").is_equal(0)
	title.choose()
	assert_array(_travelled).is_equal([WOOD])
	assert_int(GameState.item_count(&"coin")).override_failure_message("the save before the last").is_equal(7)


func test_back_and_escape_return_to_the_menu_with_nothing_loaded() -> void:
	_two_saves()
	_break(SaveSystem.slot_path(TEST_SLOT))
	var title: TitleScreen = _title()
	title.choose()
	title.choose(TitleScreen.BACK)
	assert_array(Array(title.shown_lines())).is_equal(["> Continue", "  New game", "  Settings", "  Quit"])
	assert_str(title.notice()).is_empty()
	title.choose()
	assert_bool(title.is_offering_backup()).is_true()
	var escape: InputEventAction = InputEventAction.new()
	escape.action = &"pause"
	escape.pressed = true
	title._unhandled_input(escape)
	assert_bool(title.is_offering_backup()).is_false()
	assert_array(_travelled).is_empty()
	assert_int(GameState.item_count(&"coin")).is_equal(0)


func test_the_pointer_chooses_between_the_earlier_save_and_back() -> void:
	_two_saves()
	_break(SaveSystem.slot_path(TEST_SLOT))
	var title: TitleScreen = _title()
	title.choose()
	var list: Label = title.get_node(^"Menu/List")
	title._unhandled_input(_motion(_point(list, 1)))
	assert_that(title.cursor.selected_id()).is_equal(TitleScreen.BACK)
	title._unhandled_input(_click_at(_point(list, 0)))
	assert_array(_travelled).is_equal([WOOD])


func test_a_broken_save_with_a_broken_backup_says_so_and_stays() -> void:
	_two_saves()
	_break(SaveSystem.slot_path(TEST_SLOT))
	_break(SaveSystem.backup_path(TEST_SLOT))
	var title: TitleScreen = _title()
	title.choose()
	assert_str(title.notice()).is_equal(TitleScreen.BOTH_WORDS)
	assert_array(Array(title.shown_lines())).override_failure_message("the title stays").is_equal(["> Continue", "  New game", "  Settings", "  Quit"])
	assert_array(_travelled).is_empty()
	assert_int(GameState.item_count(&"coin")).is_equal(0)


func test_a_broken_save_with_no_backup_says_so_and_stays() -> void:
	GameState.add_item(&"coin", 7)
	assert_int(SaveSystem.save_game()).is_equal(OK)
	GameState.new_game()
	_break(SaveSystem.slot_path(TEST_SLOT))
	var title: TitleScreen = _title()
	title.choose()
	assert_str(title.notice()).is_equal(TitleScreen.NO_BACKUP_WORDS)
	assert_array(_travelled).is_empty()
	assert_bool(title.is_offering_backup()).is_false()


func test_a_backup_that_breaks_after_it_was_offered_says_so_and_stays() -> void:
	_two_saves()
	_break(SaveSystem.slot_path(TEST_SLOT))
	var title: TitleScreen = _title()
	title.choose()
	_break(SaveSystem.backup_path(TEST_SLOT))
	title.choose()
	assert_str(title.notice()).is_equal(TitleScreen.BOTH_WORDS)
	assert_bool(title.is_offering_backup()).is_false()
	assert_array(_travelled).is_empty()


func test_a_save_that_is_gone_offers_the_one_before_it() -> void:
	# The game closed between the old save going and the new one coming.
	_two_saves()
	DirAccess.remove_absolute(SaveSystem.slot_path(TEST_SLOT))
	var title: TitleScreen = _title()
	assert_str(title.shown_lines()[0]).override_failure_message("Continue can be chosen").is_equal("> Continue")
	title.choose()
	assert_bool(title.is_offering_backup()).is_true()
	title.choose()
	assert_array(_travelled).is_equal([WOOD])


func test_a_save_from_a_newer_game_is_not_loaded_and_the_earlier_one_is_offered() -> void:
	_two_saves()
	SaveSystem._write_text(SaveSystem.slot_path(TEST_SLOT), "{ \"version\": 99 }")
	var title: TitleScreen = _title()
	title.choose()
	assert_bool(title.is_offering_backup()).is_true()
	assert_str(title.notice()).contains("can't be read")


func test_the_game_saved_after_the_earlier_save_was_loaded_is_whole_again() -> void:
	_two_saves()
	_break(SaveSystem.slot_path(TEST_SLOT))
	var title: TitleScreen = _title()
	title.choose()
	title.choose()
	GameState.add_item(&"coin", 1)
	assert_int(SaveSystem.save_game()).is_equal(OK)
	assert_dict(SaveSystem.summary()).is_not_empty()
	GameState.new_game()
	assert_int(SaveSystem.load_game()).is_equal(OK)
	assert_int(GameState.item_count(&"coin")).is_equal(8)


func test_no_save_and_no_backup_leaves_continue_out_of_reach() -> void:
	var title: TitleScreen = _title()
	assert_array(Array(title.shown_lines())).is_equal(["  (Continue)", "> New game", "  Settings", "  Quit"])
	assert_str(title.notice()).is_empty()


## Two saves: seven coins in the Old Wood after a minute, then twelve in Hearthvale after two.
## The first is the backup. GameState is a new game again when this returns.
func _two_saves() -> void:
	GameState.add_item(&"coin", 7)
	GameState.add_play_time(60.0)
	GameState.update_player(&"old_wood", Vector2i(18, 10))
	assert_int(SaveSystem.save_game()).is_equal(OK)
	GameState.add_item(&"coin", 5)
	GameState.add_play_time(60.0)
	GameState.update_player(&"village", Vector2i(18, 23))
	assert_int(SaveSystem.save_game()).is_equal(OK)
	GameState.new_game()


## Cuts the file at `path` short, as a write that never finished would leave it.
func _break(path: String) -> void:
	SaveSystem._write_text(path, HALF)


func _title() -> TitleScreen:
	_title_screen = (load(TITLE) as PackedScene).instantiate()
	get_tree().root.add_child(_title_screen)
	_title_screen.travel = func(path: String) -> void: _travelled.append(path)
	return _title_screen


func _point(label: Label, line: int) -> Vector2:
	return label.get_global_transform_with_canvas() * Vector2(4.0, MenuInput.line_height(label) * (float(line) + 0.5))


func _motion(at: Vector2) -> InputEventMouseMotion:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.position = at
	event.global_position = at
	return event


func _click_at(at: Vector2) -> InputEventMouseButton:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = MOUSE_BUTTON_LEFT
	event.pressed = true
	event.position = at
	event.global_position = at
	return event
