extends GdUnitTestSuite
## SettingsData: the defaults, how each setting steps on, their labels, and a ConfigFile round
## trip that keeps defaults for missing keys and snaps odd window sizes to one on offer.


func test_defaults_match_the_project_window() -> void:
	var data: SettingsData = SettingsData.new()
	assert_bool(data.fullscreen).is_false()
	assert_int(data.window_scale * 480).override_failure_message("3x is the 1440-wide window in project.godot").is_equal(int(ProjectSettings.get_setting("display/window/size/window_width_override")))
	assert_bool(data.show_controls).is_true()


func test_settings_step_on_and_wrap() -> void:
	var data: SettingsData = SettingsData.new()
	data.cycle(SettingsData.FULLSCREEN)
	assert_bool(data.fullscreen).is_true()
	data.cycle(SettingsData.SHOW_CONTROLS)
	assert_bool(data.show_controls).is_false()
	data.cycle(SettingsData.WINDOW_SCALE)
	assert_int(data.window_scale).is_equal(4)
	data.cycle(SettingsData.WINDOW_SCALE)
	assert_int(data.window_scale).override_failure_message("wraps round").is_equal(2)
	data.cycle(SettingsData.WINDOW_SCALE, -1)
	assert_int(data.window_scale).is_equal(4)


func test_labels_say_the_value() -> void:
	var data: SettingsData = SettingsData.new()
	assert_str(data.describe(SettingsData.FULLSCREEN)).is_equal("Fullscreen: Off")
	assert_str(data.describe(SettingsData.WINDOW_SCALE)).is_equal("Window size: 3x")
	assert_str(data.describe(SettingsData.SHOW_CONTROLS)).is_equal("Controls hint: On")
	assert_str(data.describe(SettingsData.MUSIC_VOLUME)).is_equal("Music volume: 70%")
	assert_str(data.describe(SettingsData.SFX_VOLUME)).is_equal("Sound volume: 70%")


func test_volumes_step_a_notch_and_wrap_round_through_silence() -> void:
	var data: SettingsData = SettingsData.new()
	for i: int in 3:
		data.cycle(SettingsData.MUSIC_VOLUME)
	assert_int(data.music_volume).is_equal(SettingsData.VOLUME_MAX)
	data.cycle(SettingsData.MUSIC_VOLUME)
	assert_int(data.music_volume).override_failure_message("past full: silent").is_equal(0)
	data.cycle(SettingsData.SFX_VOLUME, -1)
	assert_int(data.sfx_volume).is_equal(6)
	var config: ConfigFile = ConfigFile.new()
	data.to_config(config)
	var back: SettingsData = SettingsData.new()
	back.from_config(config)
	assert_int(back.music_volume).is_equal(0)
	assert_int(back.sfx_volume).is_equal(6)
	var loud: ConfigFile = ConfigFile.new()
	loud.set_value("audio", "music_volume", 99)
	back.from_config(loud)
	assert_int(back.music_volume).override_failure_message("kept within range").is_equal(SettingsData.VOLUME_MAX)


func test_a_config_round_trip_keeps_them_and_fixes_odd_values() -> void:
	var data: SettingsData = SettingsData.new()
	data.cycle(SettingsData.FULLSCREEN)
	data.cycle(SettingsData.WINDOW_SCALE, -1)
	data.cycle(SettingsData.SHOW_CONTROLS)
	var config: ConfigFile = ConfigFile.new()
	data.to_config(config)
	var back: SettingsData = SettingsData.new()
	back.from_config(config)
	assert_bool(back.fullscreen).is_true()
	assert_int(back.window_scale).is_equal(2)
	assert_bool(back.show_controls).is_false()
	var odd: ConfigFile = ConfigFile.new()
	odd.set_value("display", "window_scale", 9)
	back = SettingsData.new()
	back.from_config(odd)
	assert_int(back.window_scale).override_failure_message("the nearest size on offer").is_equal(4)
	assert_bool(back.show_controls).override_failure_message("missing: the default").is_true()
