extends GdUnitTestSuite
## The homestead's two tunes (phase 1, step 1c): its own by day, and a quieter one of its own
## after dark in place of the game's night tune. The farmhouse plays the farm's tune. Every
## other place is as it was: the village's own tune, and the game's night tune out of doors.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")
const AudioTool: GDScript = preload("res://tools/audio/make_audio.gd")

const FARM: String = "res://world/areas/homestead/homestead.tscn"
const HOME: String = "res://world/areas/home/home.tscn"
const VILLAGE: String = "res://world/areas/village/village.tscn"

var _area: Node


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	Quests.refresh()
	_at("12:00")


func after_test() -> void:
	if is_instance_valid(_area):
		_area.free()
	_area = null
	GameState.clear()


func test_the_farm_has_a_tune_by_day_and_a_quieter_one_at_night() -> void:
	var farm: AreaController = _load(FARM)
	assert_that(farm.music).is_equal(&"homestead")
	assert_that(farm.night_music).is_equal(&"homestead_night")
	for tune: StringName in [&"homestead", &"homestead_night"]:
		assert_bool(Audio.MUSIC.has(tune)).override_failure_message("%s is a tune the game has" % tune).is_true()
		assert_bool(ResourceLoader.exists("res://audio/music/%s.wav" % tune)).override_failure_message("%s is baked" % tune).is_true()
	assert_that(farm.tune_now()).is_equal(&"homestead")
	assert_that(Audio.current_music).is_equal(&"homestead")
	# Night falls at eight: its own night tune, not the game's.
	_at("19:59")
	assert_that(Audio.current_music).is_equal(&"homestead")
	_at("20:00")
	assert_that(farm.tune_now()).is_equal(&"homestead_night")
	assert_that(Audio.current_music).override_failure_message("the farm's own night tune").is_equal(&"homestead_night")
	assert_that(Audio.current_music).is_not_equal(AreaController.NIGHT_TUNE)
	_at("01:30")
	assert_that(Audio.current_music).is_equal(&"homestead_night")
	# The morning brings the day's tune back.
	GameState.start_next_day()
	assert_that(Audio.current_music).is_equal(&"homestead")
	# Arriving at night, it is the night tune from the first.
	_at("23:00")
	farm = _load(FARM)
	assert_that(Audio.current_music).is_equal(&"homestead_night")


func test_the_farmhouse_plays_the_farms_tune_and_the_village_is_as_it_was() -> void:
	# Indoors keeps no night: the farmhouse plays the farm's day tune at any hour.
	var home: AreaController = _load(HOME)
	assert_that(home.music).is_equal(&"homestead")
	assert_that(home.night_music).is_equal(&"")
	assert_that(Audio.current_music).is_equal(&"homestead")
	_at("23:00")
	home = _load(HOME)
	assert_that(Audio.current_music).override_failure_message("indoors at 23:00").is_equal(&"homestead")
	# Hearthvale: its own tune by day, and the game's night tune after dark, as before.
	_at("12:00")
	var village: AreaController = _load(VILLAGE)
	assert_that(village.night_music).is_equal(&"")
	assert_that(Audio.current_music).is_equal(&"village")
	_at("21:00")
	assert_that(village.tune_now()).is_equal(AreaController.NIGHT_TUNE)
	assert_that(Audio.current_music).is_equal(&"night")
	# No other area names a night tune of its own.
	for area_id: StringName in [&"north_fields", &"south_field", &"old_wood", &"willowmere"]:
		var scene: AreaController = _load(WorldPaths.scene_for(area_id))
		assert_that(scene.night_music).override_failure_message(String(area_id)).is_equal(&"")


func test_the_night_tune_is_the_quieter_of_the_two_and_quieter_than_the_games_own() -> void:
	var songs: Dictionary = AudioTool.get_script_constant_map()["SONGS"]
	var day: Dictionary = songs["homestead"]
	var night: Dictionary = songs["homestead_night"]
	var games_night: Dictionary = songs["night"]
	assert_float(_loudness(night)).override_failure_message("quieter than the farm's day tune").is_less(_loudness(day))
	assert_float(_loudness(night)).override_failure_message("quieter than the game's own night tune").is_less(_loudness(games_night))
	assert_float(float(night["bpm"])).override_failure_message("and slower than the day's").is_less(float(day["bpm"]))
	for track: Dictionary in night["tracks"]:
		assert_str(str(track["wave"])).override_failure_message("no drums at night").is_not_equal("drums")
	# Every track is as long as its song (the tool refuses to bake one that isn't).
	for song: Dictionary in [day, night]:
		for track: Dictionary in song["tracks"]:
			assert_int(Synth.eighths(str(track["notes"]))).is_equal(int(song["bars"]) * 8)
	# The two are tunes of their own, not another place's under a new name.
	for other: String in songs:
		if other != "homestead" and other != "homestead_night":
			assert_str(str(songs[other]["tracks"][0]["notes"])).is_not_equal(str(day["tracks"][0]["notes"]))
			assert_str(str(songs[other]["tracks"][0]["notes"])).is_not_equal(str(night["tracks"][0]["notes"]))


## The sum of a song's track volumes: how loud it is at its fullest.
func _loudness(song: Dictionary) -> float:
	var total: float = 0.0
	for track: Dictionary in song["tracks"]:
		total += float(track["volume"])
	return total


func _at(hour: String) -> void:
	GameState.set_time(float(GameState.day_clock().in_day(hour)))


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area
