class_name TitleScreen
extends Control
## The title screen, the game's first scene (docs/TECH_DESIGN.md §12): Continue (when there's
## a save, saying where and how long), New game, Settings and Quit. Up and down pick, E or
## Enter chooses.

const CONTINUE: StringName = &"continue"
const NEW_GAME: StringName = &"new_game"
const SETTINGS: StringName = &"settings"
const QUIT: StringName = &"quit"

var cursor: MenuCursor = MenuCursor.new()
## Changes the scene (gets its path). Tests replace it.
var travel: Callable
## Quits the game. Tests replace it.
var quit: Callable

@onready var settings_menu: SettingsMenu = $SettingsMenu
@onready var _list: Label = $Menu/List


func _init() -> void:
	travel = func(path: String) -> void: get_tree().change_scene_to_file(path)
	quit = func() -> void: get_tree().quit()


func _ready() -> void:
	get_tree().paused = false
	refresh()


## Rebuilds the menu: Continue can be chosen only when there's a save.
func refresh() -> void:
	var summary: Dictionary = SaveSystem.summary()
	cursor.set_options([
		MenuCursor.option(CONTINUE, continue_text(summary), not summary.is_empty()),
		MenuCursor.option(NEW_GAME, "New game"),
		MenuCursor.option(SETTINGS, "Settings"),
		MenuCursor.option(QUIT, "Quit"),
	])
	_list.text = "\n".join(cursor.lines())


## "Continue   The Old Wood, 12:04" for a save; plain "Continue" without one.
static func continue_text(summary: Dictionary) -> String:
	if summary.is_empty():
		return "Continue"
	return "Continue   %s, %s" % [WorldPaths.area_name(StringName(str(summary.get("area", "")))),
		GameState.format_play_time(float(summary.get("play_time", 0.0)))]


func shown_lines() -> PackedStringArray:
	return cursor.lines()


func move_cursor(step: int) -> void:
	cursor.move(step)
	_list.text = "\n".join(cursor.lines())


## Does what option `id` says (the highlighted one by default).
func choose(id: StringName = &"") -> void:
	if id == &"":
		id = cursor.selected_id()
	match id:
		CONTINUE:
			if SaveSystem.load_game() == OK:
				var area: StringName = StringName(str(GameState.player.get("area", WorldPaths.START_AREA)))
				travel.call(WorldPaths.scene_for(area if ResourceLoader.exists(WorldPaths.scene_for(area)) else WorldPaths.START_AREA))
		NEW_GAME:
			GameState.new_game()
			travel.call(WorldPaths.scene_for(WorldPaths.START_AREA))
		SETTINGS:
			settings_menu.open()
		QUIT:
			quit.call()


func _unhandled_input(event: InputEvent) -> void:
	# Take the viewport now: a choice can change the scene, which takes this menu out of the tree.
	var viewport: Viewport = get_viewport()
	if settings_menu.is_open():
		return
	if MenuInput.is_up(event):
		move_cursor(-1)
	elif MenuInput.is_down(event):
		move_cursor(1)
	elif MenuInput.is_confirm(event):
		choose()
	else:
		return
	viewport.set_input_as_handled()
