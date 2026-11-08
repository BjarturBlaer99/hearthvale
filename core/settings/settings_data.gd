class_name SettingsData
extends RefCounted
## The player's settings (docs/TECH_DESIGN.md §12), apart from any save: fullscreen, the window
## size (a whole multiple of the 480x270 picture) and whether the HUD shows the controls hint.
## Pure: values, how each one steps to the next, its label, and a ConfigFile round trip. The
## Settings autoload applies and stores them.

const FULLSCREEN: StringName = &"fullscreen"
const WINDOW_SCALE: StringName = &"window_scale"
const SHOW_CONTROLS: StringName = &"show_controls"
## In the order a settings menu lists them.
const KEYS: Array[StringName] = [FULLSCREEN, WINDOW_SCALE, SHOW_CONTROLS]
## Window sizes on offer, as multiples of the base picture.
const SCALES: Array[int] = [2, 3, 4]

var fullscreen: bool = false
var window_scale: int = 3
var show_controls: bool = true


## Moves setting `key` on by `step`: a yes/no flips, the window size steps through SCALES,
## wrapping round.
func cycle(key: StringName, step: int = 1) -> void:
	match key:
		FULLSCREEN:
			fullscreen = not fullscreen
		SHOW_CONTROLS:
			show_controls = not show_controls
		WINDOW_SCALE:
			var at: int = maxi(SCALES.find(window_scale), 0)
			window_scale = SCALES[wrapi(at + signi(step if step != 0 else 1), 0, SCALES.size())]


## "Fullscreen: Off", "Window size: 3x", "Controls hint: On".
func describe(key: StringName) -> String:
	match key:
		FULLSCREEN:
			return "Fullscreen: %s" % _on_off(fullscreen)
		WINDOW_SCALE:
			return "Window size: %dx" % window_scale
		SHOW_CONTROLS:
			return "Controls hint: %s" % _on_off(show_controls)
	return str(key)


func to_config(config: ConfigFile) -> void:
	config.set_value("display", "fullscreen", fullscreen)
	config.set_value("display", "window_scale", window_scale)
	config.set_value("hud", "show_controls", show_controls)


## Reads what `config` has, keeping defaults for anything missing and the nearest offered size.
func from_config(config: ConfigFile) -> void:
	fullscreen = bool(config.get_value("display", "fullscreen", fullscreen))
	show_controls = bool(config.get_value("hud", "show_controls", show_controls))
	var wanted: int = int(config.get_value("display", "window_scale", window_scale))
	var best: int = SCALES[0]
	for scale: int in SCALES:
		if absi(scale - wanted) < absi(best - wanted):
			best = scale
	window_scale = best


static func _on_off(value: bool) -> String:
	return "On" if value else "Off"
