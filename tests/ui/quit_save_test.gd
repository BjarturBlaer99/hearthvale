extends GdUnitTestSuite
## Leaving saves first (the fix round of 2026-11-16): "Quit to title" and a closing window save
## the game, say "Saving..." for a moment, and then leave. A save that can't be written keeps
## the game open the first time. Only the scene the game is showing is saved on a closing
## window: never an area a test has put beside it. Uses a slot of its own.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const VILLAGE: String = "res://world/areas/village/village.tscn"
const KEEP: String = "res://world/areas/keep/keep.tscn"
const TITLE: String = "res://ui/title_screen.tscn"
const ENDING: String = "res://ui/ending_screen.tscn"
const TEST_SLOT: int = 967

var _area: Node
var _screen: Node
var _own_scene: Node


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	Quests.refresh()
	SaveSystem.erase_slot(TEST_SLOT)
	SaveSystem.current_slot = TEST_SLOT
	SaveSystem.leave_delay = 0.0
	_own_scene = get_tree().current_scene


func after_test() -> void:
	get_tree().current_scene = _own_scene
	if is_instance_valid(_area):
		_area.free()
	_area = null
	if is_instance_valid(_screen):
		_screen.free()
	_screen = null
	get_tree().paused = false
	SaveSystem.write_file = SaveSystem._write_text
	SaveSystem.quit = func() -> void: get_tree().quit()
	SaveSystem.leave_delay = SaveSystem.LEAVE_DELAY
	SaveSystem.erase_slot(TEST_SLOT)
	SaveSystem.current_slot = SaveSystem.GAME_SLOT
	GameState.clear()


func test_the_game_decides_when_a_closing_window_may_close() -> void:
	assert_bool(get_tree().auto_accept_quit).is_false()


func test_quitting_to_the_title_saves_where_he_stands_and_says_so() -> void:
	var village: AreaController = _load(VILLAGE)
	var travelled: Array[String] = []
	village.travel = func(path: String) -> void: travelled.append(path)
	GameState.add_item(&"coin", 12)
	village.player.motor.place(Vector2i(20, 22))
	village.open_pause_menu()
	assert_str(village.hud.pause_menu.note()).is_equal(PauseMenu.QUIT_NOTE)
	village.hud.pause_menu.choose(PauseMenu.QUIT)
	assert_array(travelled).is_equal([TITLE])
	assert_array(Array(village.hud.notice_lines())).contains([SaveSystem.SAVING_WORDS])
	assert_bool(village.is_leaving()).is_true()
	var saved: Dictionary = _saved()
	assert_str(str(saved["player"]["area"])).is_equal("village")
	assert_array(saved["player"]["cell"]).override_failure_message("where he stood, not where the last frame left him").is_equal([20.0, 22.0])
	GameState.new_game()
	assert_int(SaveSystem.load_game()).is_equal(OK)
	assert_int(GameState.item_count(&"coin")).is_equal(12)


func test_saving_is_up_for_a_moment_before_the_game_leaves() -> void:
	SaveSystem.leave_delay = 0.05
	var village: AreaController = _load(VILLAGE)
	var travelled: Array[String] = []
	village.travel = func(path: String) -> void: travelled.append(path)
	village.open_pause_menu()
	village.hud.pause_menu.choose(PauseMenu.QUIT)
	assert_bool(SaveSystem.has_save()).override_failure_message("saved at once").is_true()
	assert_array(travelled).override_failure_message("not gone yet").is_empty()
	assert_bool(village.player.controls_enabled).override_failure_message("he stands still meanwhile").is_false()
	# Asked again while it waits: nothing more happens.
	village.save_and_leave(func() -> void: travelled.append("twice"))
	await get_tree().create_timer(0.3).timeout
	assert_array(travelled).is_equal([TITLE])


func test_a_save_that_fails_keeps_him_in_the_game_once_and_lets_him_go_the_second_time() -> void:
	var village: AreaController = _load(VILLAGE)
	var travelled: Array[String] = []
	village.travel = func(path: String) -> void: travelled.append(path)
	SaveSystem.write_file = func(_path: String, _text: String) -> Error: return ERR_FILE_CANT_WRITE
	village.open_pause_menu()
	village.hud.pause_menu.choose(PauseMenu.QUIT)
	assert_array(travelled).override_failure_message("unsaved, he is not thrown out").is_empty()
	assert_bool(village.is_leaving()).is_false()
	assert_bool(village.player.controls_enabled).override_failure_message("the game goes on").is_true()
	var told: String = village.hud.notice_text()
	assert_str(told).contains("Couldn't save").contains("Quit again")
	# The second time he has been told: it leaves, unsaved.
	village.open_pause_menu()
	village.hud.pause_menu.choose(PauseMenu.QUIT)
	assert_array(travelled).is_equal([TITLE])
	assert_bool(SaveSystem.has_save()).is_false()
	assert_array(Array(village.hud.notice_lines())).override_failure_message("and it doesn't say it saved").not_contains([SaveSystem.SAVING_WORDS])


func test_a_closing_window_saves_the_area_the_game_is_showing_and_then_quits() -> void:
	var village: AreaController = _load(VILLAGE)
	get_tree().current_scene = village
	var quits: Array[bool] = []
	SaveSystem.quit = func() -> void: quits.append(true)
	GameState.add_item(&"coin", 5)
	village.player.motor.place(Vector2i(20, 22))
	SaveSystem.notification(Node.NOTIFICATION_WM_CLOSE_REQUEST)
	assert_array(quits).is_equal([true])
	assert_array(Array(village.hud.notice_lines())).contains([SaveSystem.SAVING_WORDS])
	assert_array(_saved()["player"]["cell"]).is_equal([20.0, 22.0])
	GameState.new_game()
	assert_int(SaveSystem.load_game()).is_equal(OK)
	assert_int(GameState.item_count(&"coin")).is_equal(5)


func test_a_closing_window_behind_the_pause_menu_says_so_in_the_menu() -> void:
	var village: AreaController = _load(VILLAGE)
	get_tree().current_scene = village
	var quits: Array[bool] = []
	SaveSystem.quit = func() -> void: quits.append(true)
	village.open_pause_menu()
	SaveSystem.close_requested()
	assert_str(village.hud.pause_menu.note()).is_equal(SaveSystem.SAVING_WORDS)
	assert_bool(SaveSystem.has_save()).is_true()
	assert_array(quits).is_equal([true])


func test_a_closing_window_that_cant_save_stays_open_once() -> void:
	var village: AreaController = _load(VILLAGE)
	get_tree().current_scene = village
	var quits: Array[bool] = []
	SaveSystem.quit = func() -> void: quits.append(true)
	SaveSystem.write_file = func(_path: String, _text: String) -> Error: return ERR_FILE_CANT_WRITE
	SaveSystem.close_requested()
	assert_array(quits).override_failure_message("it stays, and says why").is_empty()
	assert_str(village.hud.notice_text()).contains("Couldn't save")
	SaveSystem.close_requested()
	assert_array(quits).is_equal([true])


func test_an_area_a_test_put_in_the_tree_is_not_saved_by_a_closing_window() -> void:
	# This suite's own scene is the one the game is showing: the village beside it is not.
	var village: AreaController = _load(VILLAGE)
	var quits: Array[bool] = []
	SaveSystem.quit = func() -> void: quits.append(true)
	SaveSystem.close_requested()
	assert_array(quits).is_equal([true])
	assert_bool(SaveSystem.has_save()).override_failure_message("nothing was saved").is_false()
	assert_bool(village.is_leaving()).is_false()


func test_the_title_has_nothing_to_save_and_closes_at_once() -> void:
	GameState.add_item(&"coin", 3)
	assert_int(SaveSystem.save_game()).is_equal(OK)
	var before: String = FileAccess.get_file_as_string(SaveSystem.slot_path(TEST_SLOT))
	_screen = (load(TITLE) as PackedScene).instantiate()
	get_tree().root.add_child(_screen)
	get_tree().current_scene = _screen
	var quits: Array[bool] = []
	SaveSystem.quit = func() -> void: quits.append(true)
	assert_bool(_screen.has_method(&"save_and_leave")).is_false()
	GameState.clear()
	SaveSystem.close_requested()
	assert_array(quits).is_equal([true])
	assert_str(FileAccess.get_file_as_string(SaveSystem.slot_path(TEST_SLOT))).override_failure_message("the save is as it was").is_equal(before)


func test_a_hero_lying_fallen_is_saved_awake_at_the_entrance() -> void:
	GameState.set_flag(StoryGates.KEEP_GATE, true)
	GameState.go_to(&"keep", &"entrance")
	var keep: AreaController = _load(KEEP)
	var entrance: Vector2i = keep.player.motor.cell
	keep.travel = func(_path: String) -> void: pass
	keep.player.motor.place(entrance + Vector2i(0, -3))
	GameState.damage(GameState.max_health())
	assert_bool(keep.is_dying()).is_true()
	keep.save_and_leave(func() -> void: pass)
	var saved: Dictionary = _saved()
	assert_int(int(saved["health"])).override_failure_message("whole again").is_equal(GameState.max_health())
	assert_array(saved["player"]["cell"]).is_equal([float(entrance.x), float(entrance.y)])


func test_the_ending_screen_saves_the_finished_game_on_a_closing_window() -> void:
	GameState.set_flag(EndingSummary.FINISHED_FLAG, true)
	GameState.update_player(&"crypt", Vector2i(10, 10))
	_screen = (load(ENDING) as PackedScene).instantiate()
	get_tree().root.add_child(_screen)
	get_tree().current_scene = _screen
	var quits: Array[bool] = []
	SaveSystem.quit = func() -> void: quits.append(true)
	SaveSystem.close_requested()
	assert_array(quits).is_equal([true])
	assert_str((_screen as EndingScreen).note()).is_equal(SaveSystem.SAVING_WORDS)
	assert_bool(bool(SaveSystem.summary()["finished"])).override_failure_message("the last fight is not lost").is_true()


func test_the_ending_screen_that_cant_save_stays_open_once() -> void:
	_screen = (load(ENDING) as PackedScene).instantiate()
	get_tree().root.add_child(_screen)
	get_tree().current_scene = _screen
	var quits: Array[bool] = []
	SaveSystem.quit = func() -> void: quits.append(true)
	SaveSystem.write_file = func(_path: String, _text: String) -> Error: return ERR_FILE_CANT_WRITE
	SaveSystem.close_requested()
	assert_array(quits).is_empty()
	assert_str((_screen as EndingScreen).note()).contains("Couldn't save")
	SaveSystem.close_requested()
	assert_array(quits).is_equal([true])


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area


func _saved() -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(SaveSystem.slot_path(TEST_SLOT)))
