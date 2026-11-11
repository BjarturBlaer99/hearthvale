extends GdUnitTestSuite
## Menus and the end (H9): the title screen offers New game (and Continue once there's a
## save, saying where and how long), the pause menu stops the game, saves, opens the settings
## and quits to the title. Settings apply and are kept at once. The play clock stops behind the
## pause menu. Taking the Warden's heart ends the slice with a closing conversation. Closed
## doors stop arrows. Uses its own save slot and settings file, and restores both.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const TITLE: String = "res://ui/title_screen.tscn"
const VILLAGE: String = "res://world/areas/village/village.tscn"
const WOOD: String = "res://world/areas/old_wood/old_wood.tscn"
const KEEP: String = "res://world/areas/keep/keep.tscn"
const TEST_SLOT: int = 992
const TEST_SETTINGS: String = "user://test_settings.cfg"
const FRAME: float = 1.0 / 60.0

var _area: Node


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	SaveSystem.current_slot = TEST_SLOT
	Settings.path = TEST_SETTINGS
	Settings.load_settings()


func after_test() -> void:
	if is_instance_valid(_area):
		_area.free()
	_area = null
	get_tree().paused = false
	if SaveSystem.has_slot(TEST_SLOT):
		DirAccess.remove_absolute(SaveSystem.slot_path(TEST_SLOT))
	SaveSystem.current_slot = SaveSystem.GAME_SLOT
	if FileAccess.file_exists(TEST_SETTINGS):
		DirAccess.remove_absolute(TEST_SETTINGS)
	Settings.path = Settings.PATH
	Settings.load_settings()
	GameState.clear()


func test_the_title_offers_a_new_game_until_there_is_a_save() -> void:
	var title: TitleScreen = _title()
	assert_array(Array(title.shown_lines())).is_equal(["  (Continue)", "> New game", "  Settings", "  Quit"])
	var travelled: Array[String] = []
	title.travel = func(path: String) -> void: travelled.append(path)
	GameState.add_item(&"coin", 9)
	title.choose()
	assert_array(travelled).is_equal([VILLAGE])
	assert_int(GameState.item_count(&"coin")).override_failure_message("a fresh game").is_equal(0)
	assert_int(GameState.hearts_max).is_equal(3)
	var quit: Array[bool] = []
	title.quit = func() -> void: quit.append(true)
	title.choose(TitleScreen.QUIT)
	assert_array(quit).is_equal([true])


func test_the_keeps_window_goes_dark_on_the_title_once_the_game_is_finished() -> void:
	var title: TitleScreen = _title()
	assert_bool(title.backdrop.keep_lit).override_failure_message("no save: the window is lit").is_true()
	GameState.update_player(&"village", Vector2i(20, 18))
	assert_int(SaveSystem.save_game()).is_equal(OK)
	title.refresh()
	assert_bool(title.backdrop.keep_lit).override_failure_message("an unfinished save: still lit").is_true()
	GameState.set_flag(AreaController.ENDING_FLAG, true)
	title.refresh()
	assert_bool(title.backdrop.keep_lit).override_failure_message("finished but not saved: still lit").is_true()
	assert_int(SaveSystem.save_game()).is_equal(OK)
	assert_bool(_title().backdrop.keep_lit).override_failure_message("a finished save: dark").is_false()


func test_continue_puts_you_back_where_you_saved() -> void:
	GameState.add_item(&"wooden_sword")
	GameState.add_play_time(125.0)
	GameState.update_player(&"old_wood", Vector2i(18, 10))
	assert_int(SaveSystem.save_game()).is_equal(OK)
	GameState.clear()
	var title: TitleScreen = _title()
	assert_str(title.shown_lines()[0]).is_equal("> Continue   The Old Wood, 2:05")
	var travelled: Array[String] = []
	title.travel = func(path: String) -> void: travelled.append(path)
	title.choose()
	assert_array(travelled).is_equal([WOOD])
	assert_int(GameState.item_count(&"wooden_sword")).is_equal(1)
	var wood: AreaController = _load(WOOD)
	assert_that(wood.player.motor.cell).override_failure_message("right where you saved").is_equal(Vector2i(18, 10))


func test_the_pause_menu_stops_the_game_and_saves() -> void:
	var village: AreaController = _load(VILLAGE)
	assert_bool(village.open_pause_menu()).is_true()
	assert_bool(get_tree().paused).is_true()
	assert_bool(village.can_process()).override_failure_message("the area stops").is_false()
	assert_bool(village.hud.pause_menu.can_process()).override_failure_message("the menu doesn't").is_true()
	var menu: PauseMenu = village.hud.pause_menu
	assert_array(Array(menu.shown_lines())).is_equal(["> Resume", "  Save", "  Quests", "  Settings", "  Quit to title"])
	var status: String = (menu.get_node(^"Panel/Status") as Label).text
	assert_str(status).contains("Hearts 3").contains("Heart pieces 0 of 4").contains("Time played")
	menu.choose(PauseMenu.SAVE)
	assert_str(menu.note()).is_equal("Saved.")
	assert_str(str(SaveSystem.summary()["area"])).is_equal("village")
	menu.choose(PauseMenu.RESUME)
	assert_bool(get_tree().paused).is_false()
	assert_bool(village.is_paused()).is_false()
	village.talk_to(village.talkables()[0])
	assert_bool(village.open_pause_menu()).override_failure_message("not mid-conversation").is_false()


func test_quitting_to_the_title_warns_about_unsaved_progress() -> void:
	var village: AreaController = _load(VILLAGE)
	var travelled: Array[String] = []
	village.travel = func(path: String) -> void: travelled.append(path)
	village.open_pause_menu()
	assert_str(village.hud.pause_menu.note()).contains("haven't saved")
	village.hud.pause_menu.choose(PauseMenu.QUIT)
	assert_array(travelled).is_equal([TITLE])
	assert_bool(get_tree().paused).is_false()


func test_settings_apply_at_once_are_kept_and_can_hide_the_controls_hint() -> void:
	var village: AreaController = _load(VILLAGE)
	assert_bool(village.hud.hint_shown()).is_true()
	village.open_pause_menu()
	var menu: PauseMenu = village.hud.pause_menu
	menu.choose(PauseMenu.SETTINGS)
	var settings: SettingsMenu = menu.settings_menu
	assert_bool(settings.is_open()).is_true()
	assert_array(Array(settings.shown_lines())).is_equal(["> Music volume: 70%", "  Sound volume: 70%", "  Fullscreen: Off", "  Window size: 3x", "  Controls hint: On", "  Back"])
	settings.move_cursor(4)
	settings.change(1)
	assert_str(settings.shown_lines()[4]).is_equal("> Controls hint: Off")
	assert_bool(village.hud.hint_shown()).override_failure_message("hidden at once").is_false()
	var config: ConfigFile = ConfigFile.new()
	assert_int(config.load(TEST_SETTINGS)).override_failure_message("kept on disk").is_equal(OK)
	assert_bool(config.get_value("hud", "show_controls")).is_false()
	Settings.load_settings()
	assert_bool(Settings.data.show_controls).is_false()
	settings.move_cursor(1)
	settings.change(1)
	assert_bool(settings.is_open()).override_failure_message("Back closes it").is_false()


func test_the_play_clock_runs_only_while_the_game_does() -> void:
	var village: AreaController = _load(VILLAGE)
	var before: float = GameState.play_time
	village._process(0.5)
	assert_float(GameState.play_time).is_equal_approx(before + 0.5, 0.0001)
	village.open_pause_menu()
	assert_bool(village.can_process()).override_failure_message("paused: no _process, no clock").is_false()


func test_taking_the_wardens_heart_points_on_to_the_crypt() -> void:
	GameState.set_flag(&"keep_warden_beaten", true)
	var keep: AreaController = _load(KEEP)
	var heart: HeartContainer = keep.interactables.get_node(^"HeartContainer")
	keep.player.motor.place(heart.cell())
	keep.player.sync_from_motor()
	assert_int(keep.collect_pickups()).is_equal(1)
	assert_int(GameState.hearts_max).is_equal(4)
	assert_bool(keep.is_talking()).override_failure_message("a closing conversation").is_true()
	assert_str(keep.hud.dialogue.shown_text()).contains("Heart Container")
	keep.hud.dialogue.confirm()
	assert_str(keep.hud.dialogue.shown_text()).contains("chapel").contains("Elder Bram")
	keep.hud.dialogue.confirm()
	assert_bool(keep.is_talking()).is_false()


func test_closed_doors_stop_arrows() -> void:
	GameState.add_item(&"bow")
	GameState.add_item(&"arrow", 5)
	var keep: AreaController = _load(KEEP)
	keep.player.motor.place(Vector2i(22, 36))
	keep.player.face(Vector2.UP)
	assert_bool(keep.use_item()).is_true()
	var arrow: Arrow = keep.last_projectile
	for i: int in roundi(1.0 / FRAME):
		if not arrow.fly(FRAME):
			break
	assert_bool(arrow.stopped).is_true()
	assert_int(GridBody.cell_of(arrow.position).y).override_failure_message("stopped at the locked door").is_equal(33)
	GameState.set_flag(DungeonState.door_flag(&"keep", &"hall_door"), true)
	keep.player.motor.place(Vector2i(22, 36))
	for i: int in roundi(0.6 / FRAME):
		keep.player.motor.step(Vector2.ZERO, FRAME)
	assert_bool(keep.use_item()).is_true()
	var through: Arrow = keep.last_projectile
	for i: int in roundi(0.4 / FRAME):
		through.fly(FRAME)
	assert_int(GridBody.cell_of(through.position).y).override_failure_message("an open door lets it by").is_less(32)


func test_a_choice_that_changes_the_scene_doesnt_trip_over_the_menu_leaving() -> void:
	# Changing the scene takes the old one out of the tree at once, before the key press that
	# chose it has been marked handled (found in the first playtest).
	var title: TitleScreen = _title()
	title.travel = func(_path: String) -> void: title.get_parent().remove_child(title)
	title._unhandled_input(_pressed(&"interact"))
	assert_bool(title.is_inside_tree()).override_failure_message("New game left the title").is_false()
	var village: AreaController = _load(VILLAGE)
	village.travel = func(_path: String) -> void: village.get_parent().remove_child(village)
	village.open_pause_menu()
	var menu: PauseMenu = village.hud.pause_menu
	menu.move_cursor(4)
	menu._unhandled_input(_pressed(&"interact"))
	assert_bool(village.is_inside_tree()).override_failure_message("Quit to title left the area").is_false()
	assert_bool(get_tree().paused).is_false()


func test_elder_bram_points_new_players_to_the_sword_and_the_road_north() -> void:
	var nodes: Dictionary = DataRegistry.get_dialogue(&"elder_bram")["nodes"]
	assert_str(str(nodes["promise"]["text"])).contains("training yard").contains("north")
	assert_dict(DataRegistry.get_dialogue(&"ending_keep")).is_not_empty()


func _pressed(action: StringName) -> InputEventAction:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = true
	return event


func _title() -> TitleScreen:
	if is_instance_valid(_area):
		_area.free()
	var title: TitleScreen = (load(TITLE) as PackedScene).instantiate()
	get_tree().root.add_child(title)
	_area = title
	return title


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area
