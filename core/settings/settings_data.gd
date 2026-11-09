class_name SettingsData
extends RefCounted
## The player's settings (docs/TECH_DESIGN.md §12), apart from any save: music and effects
## volume (0 to VOLUME_MAX), fullscreen, the window size (a whole multiple of the 480x270
## picture) and whether the HUD shows the controls hint.
## Pure: values, how each one steps to the next, its label, and a ConfigFile round trip. The
## Settings autoload applies and stores them.

const FULLSCREEN: StringName = &"fullscreen"
const WINDOW_SCALE: StringName = &"window_scale"
const SHOW_CONTROLS: StringName = &"show_controls"
const MUSIC_VOLUME: StringName = &"music_volume"
const SFX_VOLUME: StringName = &"sfx_volume"
## In the order a settings menu lists them.
const KEYS: Array[StringName] = [MUSIC_VOLUME, SFX_VOLUME, FULLSCREEN, WINDOW_SCALE, SHOW_CONTROLS]
## Volumes run from 0 (silent) to this.
const VOLUME_MAX: int = 10
## Window sizes on offer, as multiples of the base picture.
const SCALES: Array[int] = [2, 3, 4]

var fullscreen: bool = false
var window_scale: int = 3
var show_controls: bool = true
var music_volume: int = 7
var sfx_volume: int = 7


## Moves setting `key` on by `step`: a yes/no flips, the window size steps through SCALES and a
## volume goes up or down a notch, each wrapping round.
func cycle(key: StringName, step: int = 1) -> void:
	match key:
		FULLSCREEN:
			fullscreen = not fullscreen
		SHOW_CONTROLS:
			show_controls = not show_controls
		WINDOW_SCALE:
			var at: int = maxi(SCALES.find(window_scale), 0)
			window_scale = SCALES[wrapi(at + signi(step if step != 0 else 1), 0, SCALES.size())]
		MUSIC_VOLUME:
			music_volume = wrapi(music_volume + signi(step if step != 0 else 1), 0, VOLUME_MAX + 1)
		SFX_VOLUME:
			sfx_volume = wrapi(sfx_volume + signi(step if step != 0 else 1), 0, VOLUME_MAX + 1)


## "Fullscreen: Off", "Window size: 3x", "Controls hint: On".
func describe(key: StringName) -> String:
	match key:
		FULLSCREEN:
			return "Fullscreen: %s" % _on_off(fullscreen)
		WINDOW_SCALE:
			return "Window size: %dx" % window_scale
		SHOW_CONTROLS:
			return "Controls hint: %s" % _on_off(show_controls)
		MUSIC_VOLUME:
			return "Music volume: %d%%" % (music_volume * 100 / VOLUME_MAX)
		SFX_VOLUME:
			return "Sound volume: %d%%" % (sfx_volume * 100 / VOLUME_MAX)
	return str(key)


func to_config(config: ConfigFile) -> void:
	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("display", "window_scale", window_scale)
	config.set_value("hud", "show_controls", show_controls)
	config.set_value("audio", "music_volume", music_volume)
	config.set_value("audio", "sfx_volume", sfx_volume)


## Reads what `config` has, keeping defaults for anything missing and the nearest offered size.
func from_config(config: ConfigFile) -> void:
	fullscreen = bool(config.get_value("display", "fullscreen", fullscreen))
	show_controls = bool(config.get_value("hud", "show_controls", show_controls))
	music_volume = clampi(int(config.get_value("audio", "music_volume", music_volume)), 0, VOLUME_MAX)
	sfx_volume = clampi(int(config.get_value("audio", "sfx_volume", sfx_volume)), 0, VOLUME_MAX)
	var wanted: int = int(config.get_value("display", "window_scale", window_scale))
	var best: int = SCALES[0]
	for scale: int in SCALES:
		if absi(scale - wanted) < absi(best - wanted):
			best = scale
	window_scale = best


static func _on_off(value: bool) -> String:
	return "On" if value else "Off"
