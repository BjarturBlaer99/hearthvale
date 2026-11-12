extends Node
## The player's settings (docs/TECH_DESIGN.md §12): loaded at start from `path`, applied to
## the window, and saved whenever they change. They belong to this machine, not to a save, so
## they live apart from GameState. The values and their rules are a SettingsData.

const PATH: String = "user://settings.cfg"
## The picture the game draws, before the window scales it up.
const BASE_SIZE: Vector2i = Vector2i(640, 360)

var data: SettingsData = SettingsData.new()
## Where they're kept. Tests point it elsewhere.
var path: String = PATH


func _ready() -> void:
	load_settings()
	apply()


## Reads `path` (defaults for anything missing, or if there's no file yet).
func load_settings() -> void:
	data = SettingsData.new()
	var config: ConfigFile = ConfigFile.new()
	if config.load(path) == OK:
		data.from_config(config)


func save_settings() -> Error:
	var config: ConfigFile = ConfigFile.new()
	data.to_config(config)
	return config.save(path)


## Moves setting `key` on (SettingsData.cycle), applies it, saves, and announces it.
func change(key: StringName, step: int = 1) -> void:
	data.cycle(key, step)
	apply()
	save_settings()
	EventBus.settings_changed.emit()


## Puts the window in fullscreen or at the chosen size (nothing to do without a window).
func apply() -> void:
	if DisplayServer.get_name() == "headless":
		return
	var window: Window = get_window()
	if data.fullscreen:
		window.mode = Window.MODE_FULLSCREEN
		return
	window.mode = Window.MODE_WINDOWED
	var size: Vector2i = BASE_SIZE * data.window_scale
	var screen: Rect2i = DisplayServer.screen_get_usable_rect(window.current_screen)
	window.size = size
	window.position = screen.position + (screen.size - size) / 2
