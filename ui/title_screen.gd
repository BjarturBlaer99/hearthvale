class_name TitleScreen
extends Control
## The title screen, the game's first scene (docs/TECH_DESIGN.md §12): Continue (when there's
## a save, saying where and how long), New game, Settings and Quit. Up and down (or the wheel)
## pick, and so does pointing with the mouse; a click or Enter chooses: the line the click is
## on, or the highlighted one if it is on none. Its picture follows the save: the keep's window
## is dark once the game is finished.
##
## A save that can't be read is never passed over in silence (the fix round of 2026-11-16):
## Continue says so under the menu and offers the save before it, which SaveSystem keeps as a
## backup ("Load the earlier save", "Back"). If that can't be read either, or there is none, it
## says that, and the title stays.

const CONTINUE: StringName = &"continue"
const NEW_GAME: StringName = &"new_game"
const SETTINGS: StringName = &"settings"
const QUIT: StringName = &"quit"
## The two lines offered in the menu's place when the save can't be read and its backup can.
const BACKUP: StringName = &"backup"
const BACK: StringName = &"back"
## What is said under the menu: the save can't be read and the backup is offered (with where and
## how long it was), there is no backup, or the backup can't be read either.
const OFFER_WORDS: String = "Your save can't be read. An earlier save was kept: %s."
const NO_BACKUP_WORDS: String = "Your save can't be read, and no earlier save was kept."
const BOTH_WORDS: String = "Your save can't be read, and neither can the earlier save that was kept."

var cursor: MenuCursor = MenuCursor.new()
## Changes the scene (gets its path). Tests replace it.
var travel: Callable
## Quits the game. Tests replace it.
var quit: Callable

@onready var backdrop: TitleBackdrop = $Backdrop
@onready var settings_menu: SettingsMenu = $SettingsMenu
@onready var _list: Label = $Menu/List
@onready var _notice: Control = $Notice
@onready var _words: Label = $Notice/Words


func _init() -> void:
	travel = func(path: String) -> void: get_tree().change_scene_to_file(path)
	quit = func() -> void: get_tree().quit()


func _ready() -> void:
	get_tree().paused = false
	MenuInput.let_clicks_through(self)
	EventBus.music_requested.emit(&"village")
	refresh()


## Rebuilds the menu: Continue can be chosen when there's a save, or the backup of one (a save
## that can't be read is found out when it is chosen). The keep's window is lit until the save
## says the game was finished.
func refresh() -> void:
	var summary: Dictionary = SaveSystem.summary()
	backdrop.keep_lit = not bool(summary.get("finished", false))
	cursor.set_options([
		MenuCursor.option(CONTINUE, continue_text(summary), SaveSystem.has_save() or SaveSystem.has_backup()),
		MenuCursor.option(NEW_GAME, "New game"),
		MenuCursor.option(SETTINGS, "Settings"),
		MenuCursor.option(QUIT, "Quit"),
	])
	_list.text = "\n".join(cursor.lines())


## "Continue   The Old Wood, 12:04" for a save; plain "Continue" without one that can be read.
static func continue_text(summary: Dictionary) -> String:
	if summary.is_empty():
		return "Continue"
	return "Continue   %s" % where_and_when(summary)


## "The Old Wood, 12:04": where a save (its summary) was made and how long had been played.
static func where_and_when(summary: Dictionary) -> String:
	return "%s, %s" % [WorldPaths.area_name(StringName(str(summary.get("area", "")))),
		GameState.format_play_time(float(summary.get("play_time", 0.0)))]


## Says `words` under the menu; nothing takes the box away.
func say(words: String) -> void:
	_words.text = words
	_notice.visible = not words.is_empty()


## What is said under the menu now ("" when nothing is).
func notice() -> String:
	return _words.text if _notice.visible else ""


## Whether the menu is offering the backup in place of its four lines.
func is_offering_backup() -> bool:
	return cursor.selected_id() == BACKUP or cursor.selected_id() == BACK


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
				_enter_the_game()
			else:
				_offer_the_backup()
		BACKUP:
			if SaveSystem.load_backup() == OK:
				_enter_the_game()
			else:
				EventBus.sound.emit(&"nope")
				refresh()
				say(BOTH_WORDS)
		BACK:
			refresh()
			say("")
		NEW_GAME:
			GameState.new_game()
			travel.call(WorldPaths.scene_for(WorldPaths.START_AREA))
		SETTINGS:
			settings_menu.open()
		QUIT:
			quit.call()


## Goes to the area the game just loaded says the hero is in.
func _enter_the_game() -> void:
	var area: StringName = StringName(str(GameState.player.get("area", WorldPaths.START_AREA)))
	travel.call(WorldPaths.scene_for(area if ResourceLoader.exists(WorldPaths.scene_for(area)) else WorldPaths.START_AREA))


## The save couldn't be loaded: he is told, and the save before it is offered if it can be
## read. Without one the title stays as it is.
func _offer_the_backup() -> void:
	var earlier: Dictionary = SaveSystem.backup_summary()
	if earlier.is_empty():
		EventBus.sound.emit(&"nope")
		say(BOTH_WORDS if SaveSystem.has_backup() else NO_BACKUP_WORDS)
		return
	cursor.set_options([
		MenuCursor.option(BACKUP, "Load the earlier save"),
		MenuCursor.option(BACK, "Back"),
	])
	_list.text = "\n".join(cursor.lines())
	say(OFFER_WORDS % where_and_when(earlier))


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
	elif MenuInput.is_back(event) and is_offering_backup():
		choose(BACK)
	else:
		return
	viewport.set_input_as_handled()
