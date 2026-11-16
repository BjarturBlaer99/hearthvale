class_name TitleScreen
extends Control
## The title screen, the game's first scene (docs/TECH_DESIGN.md §12): Continue (when there's
## a save, saying where and how long), New game, Settings and Quit. Up and down (or the wheel)
## pick, and so does pointing with the mouse; a click or Enter chooses: the line the click is
## on, or the highlighted one if it is on none. Its picture follows the save: the keep's window is dark once the game is
## finished.

const CONTINUE: StringName = &"continue"
const NEW_GAME: StringName = &"new_game"
const SETTINGS: StringName = &"settings"
const QUIT: StringName = &"quit"

var cursor: MenuCursor = MenuCursor.new()
## Changes the scene (gets its path). Tests replace it.
var travel: Callable
## Quits the game. Tests replace it.
var quit: Callable

@onready var backdrop: TitleBackdrop = $Backdrop
@onready var settings_menu: SettingsMenu = $SettingsMenu
@onready var _list: Label = $Menu/List


func _init() -> void:
	travel = func(path: String) -> void: get_tree().change_scene_to_file(path)
	quit = func() -> void: get_tree().quit()


func _ready() -> void:
	get_tree().paused = false
	MenuInput.let_clicks_through(self)
	EventBus.music_requested.emit(&"village")
	refresh()


## Rebuilds the menu: Continue can be chosen only when there's a save. The keep's window is
## lit until that save says the game was finished.
func refresh() -> void:
	var summary: Dictionary = SaveSystem.summary()
	backdrop.keep_lit = not bool(summary.get("finished", false))
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
	EventBus.sound.emit(&"menu_move")
	cursor.move(step)
	_list.text = "\n".join(cursor.lines())


## Does what option `id` says (the highlighted one by default).
func choose(id: StringName = &"") -> void:
	if id == &"":
		id = cursor.selected_id()
	EventBus.sound.emit(&"menu_select")
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


## Puts the cursor on the line the mouse is on in `event`, if that line can be chosen.
func point_at(event: InputEvent) -> void:
	if cursor.select(MenuInput.line_under(_list, event, cursor.options.size())):
		EventBus.sound.emit(&"menu_move")
		_list.text = "\n".join(cursor.lines())


func _unhandled_input(event: InputEvent) -> void:
	# Take the viewport now: a choice can change the scene, which takes this menu out of the tree.
	var viewport: Viewport = get_viewport()
	if settings_menu.is_open():
		return
	if MenuInput.is_pointing(event):
		point_at(event)
		return
	if MenuInput.is_up(event):
		move_cursor(-1)
	elif MenuInput.is_down(event):
		move_cursor(1)
	elif MenuInput.is_confirm(event):
		# A click on a line chooses that line; on one that can't be chosen, nothing.
		if cursor.take_click(MenuInput.line_under(_list, event, cursor.options.size())):
			_list.text = "\n".join(cursor.lines())
			choose()
	else:
		return
	viewport.set_input_as_handled()
