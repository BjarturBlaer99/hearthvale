extends Node
## Plays the game's sound effects and music (docs/TECH_DESIGN.md §13).
## - EventBus.sound(id) plays audio/sfx/<id>.wav on one of a few players on the SFX bus.
## - EventBus.music_requested(id) loops audio/music/<id>.wav on the Music bus. The same tune
##   again doesn't restart; empty stops the music.
## Volumes follow Settings. The buses are made at start. It keeps playing while the game is
## paused, so menus still sound. The files are baked by tools/audio/make_audio.gd. Headless
## (tests, tools) it keeps track of what would play but plays nothing: nobody can hear it, and a
## sound still playing at quit races the dummy mixer and leaks.

const SFX_DIR: String = "res://audio/sfx"
const MUSIC_DIR: String = "res://audio/music"
## Every sound effect (tools/audio/make_audio.gd bakes the same list; a test checks).
const SFX: Array[StringName] = [
	&"sword", &"hit", &"enemy_die", &"hurt", &"heart", &"coin", &"item_get", &"heart_get", &"door",
	&"solved", &"secret", &"arrow", &"bomb_set", &"bomb", &"crystal", &"push", &"plate", &"clink",
	&"stomp", &"gaze", &"stun", &"boss_die", &"menu_move", &"menu_select", &"pause", &"nope", &"cut",
	&"pot",
]
const MUSIC: Array[StringName] = [&"village", &"countryside", &"dungeon", &"boss"]
const MUSIC_BUS: StringName = &"Music"
const SFX_BUS: StringName = &"SFX"
## Sound effects that can overlap.
const VOICES: int = 8

## The tune playing (empty: none).
var current_music: StringName = &""
## The last sound effect played (for tests).
var last_sound: StringName = &""

var _voices: Array[AudioStreamPlayer] = []
var _next_voice: int = 0
var _music: AudioStreamPlayer
var _streams: Dictionary = {}
var _silent: bool = false


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	_silent = DisplayServer.get_name() == "headless"
	_make_bus(MUSIC_BUS)
	_make_bus(SFX_BUS)
	for i: int in VOICES:
		var voice: AudioStreamPlayer = AudioStreamPlayer.new()
		voice.bus = SFX_BUS
		add_child(voice)
		_voices.append(voice)
	_music = AudioStreamPlayer.new()
	_music.bus = MUSIC_BUS
	add_child(_music)
	EventBus.sound.connect(play_sfx)
	EventBus.music_requested.connect(play_music)
	EventBus.settings_changed.connect(apply_volumes)
	apply_volumes()


## Plays sound effect `id`. Returns false (with a warning) if there's no such sound.
func play_sfx(id: StringName) -> bool:
	var stream: AudioStream = _stream(SFX_DIR, id)
	if stream == null:
		push_warning("Audio: no sound '%s' in %s." % [id, SFX_DIR])
		return false
	last_sound = id
	if _silent:
		return true
	var voice: AudioStreamPlayer = _voices[_next_voice]
	_next_voice = (_next_voice + 1) % _voices.size()
	voice.stream = stream
	voice.play()
	return true


## Loops tune `id` (empty: stops the music). The tune already playing carries on. Returns false
## (with a warning) if there's no such tune.
func play_music(id: StringName) -> bool:
	if id == current_music:
		return true
	if id == &"":
		current_music = id
		_music.stop()
		return true
	var stream: AudioStreamWAV = _stream(MUSIC_DIR, id) as AudioStreamWAV
	if stream == null:
		push_warning("Audio: no tune '%s' in %s." % [id, MUSIC_DIR])
		return false
	current_music = id
	stream.loop_mode = AudioStreamWAV.LOOP_FORWARD
	stream.loop_begin = 0
	@warning_ignore("integer_division")
	stream.loop_end = stream.data.size() / 2
	if _silent:
		return true
	_music.stream = stream
	_music.play()
	return true


## Everything stops when the game quits, so no sound is left playing on the audio thread.
func _exit_tree() -> void:
	_music.stop()
	_music.stream = null
	for voice: AudioStreamPlayer in _voices:
		voice.stop()
		voice.stream = null
	_streams.clear()


func is_music_playing() -> bool:
	return _music.playing


## Sets both buses from Settings: a volume of 0 mutes.
func apply_volumes() -> void:
	_set_level(MUSIC_BUS, Settings.data.music_volume)
	_set_level(SFX_BUS, Settings.data.sfx_volume)


## Decibels for a volume `level` of 0..SettingsData.VOLUME_MAX (silence: -80).
static func volume_db(level: int) -> float:
	if level <= 0:
		return -80.0
	return linear_to_db(float(level) / SettingsData.VOLUME_MAX)


func _set_level(bus: StringName, level: int) -> void:
	var index: int = AudioServer.get_bus_index(bus)
	AudioServer.set_bus_mute(index, level <= 0)
	AudioServer.set_bus_volume_db(index, volume_db(level))


func _make_bus(bus: StringName) -> void:
	if AudioServer.get_bus_index(bus) != -1:
		return
	AudioServer.add_bus()
	var index: int = AudioServer.bus_count - 1
	AudioServer.set_bus_name(index, bus)
	AudioServer.set_bus_send(index, &"Master")


func _stream(directory: String, id: StringName) -> AudioStream:
	var path: String = directory.path_join("%s.wav" % id)
	if not _streams.has(path):
		_streams[path] = load(path) if ResourceLoader.exists(path) else null
	return _streams[path]
