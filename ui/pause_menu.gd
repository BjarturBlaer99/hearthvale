class_name PauseMenu
extends Control
## The pause menu (Esc or Start, docs/TECH_DESIGN.md §12): the game stops behind it. It shows
## the hero's hearts, heart pieces, keys and play time, and offers Resume, Save, Quests (the
## quest log), Friends (the villagers and their marks), Settings and Quit to title. Save writes the save slot (SaveSystem); quitting to the title loses anything
## not saved, and the menu says so. Esc resumes. The mouse points: the line under it is
## highlighted, and a click chooses it.

signal resumed
signal quit_to_title

const RESUME: StringName = &"resume"
const SAVE: StringName = &"save"
const QUESTS: StringName = &"quests"
const FRIENDS: StringName = &"friends"
const SETTINGS: StringName = &"settings"
const QUIT: StringName = &"quit"

var cursor: MenuCursor = MenuCursor.new()

@onready var settings_menu: SettingsMenu = $SettingsMenu
@onready var quest_log: QuestLog = $QuestLog
@onready var friends_page: FriendsPage = $FriendsPage
@onready var _status: Label = $Panel/Status
@onready var _list: Label = $Panel/List
@onready var _note: Label = $Panel/Note


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()
	settings_menu.closed.connect(_show_panel.bind(true))
	quest_log.closed.connect(_show_panel.bind(true))
	friends_page.closed.connect(_show_panel.bind(true))


## Pauses the game and shows the menu with `status` (hearts, keys, time) at the top.
func open(status: String) -> void:
	_status.text = status
	_note.text = "Quitting to the title loses anything you haven't saved."
	_show_panel(true)
	cursor.set_options([
		MenuCursor.option(RESUME, "Resume"),
		MenuCursor.option(SAVE, "Save"),
		MenuCursor.option(QUESTS, "Quests"),
		MenuCursor.option(FRIENDS, "Friends"),
		MenuCursor.option(SETTINGS, "Settings"),
		MenuCursor.option(QUIT, "Quit to title"),
	])
	_refresh()
	show()
	EventBus.sound.emit(&"pause")
	get_tree().paused = true


func is_open() -> bool:
	return visible


func note() -> String:
	return _note.text


func shown_lines() -> PackedStringArray:
	return cursor.lines() if visible else PackedStringArray()


func move_cursor(step: int) -> void:
	EventBus.sound.emit(&"menu_move")
	cursor.move(step)
	_refresh()


## Does what option `id` says (the highlighted one by default).
func choose(id: StringName = &"") -> void:
	if id == &"":
		id = cursor.selected_id()
	EventBus.sound.emit(&"menu_select")
	match id:
		RESUME:
			resume()
		SAVE:
			var error: Error = SaveSystem.save_game()
			_note.text = "Saved." if error == OK else "Couldn't save (%s)." % error_string(error)
		QUESTS:
			_show_panel(false)
			quest_log.open()
		FRIENDS:
			_show_panel(false)
			friends_page.open()
		SETTINGS:
			_show_panel(false)
			settings_menu.open()
		QUIT:
			hide()
			get_tree().paused = false
			quit_to_title.emit()


func resume() -> void:
	if not visible:
		return
	settings_menu.close()
	quest_log.close()
	friends_page.close()
	hide()
	get_tree().paused = false
	resumed.emit()


func _unhandled_input(event: InputEvent) -> void:
	# Take the viewport now: a choice can change the scene, which takes this menu out of the tree.
	var viewport: Viewport = get_viewport()
	if not visible or settings_menu.is_open() or quest_log.is_open() or friends_page.is_open():
		return
	if MenuInput.is_pointing(event):
		point_at(event)
		return
	if MenuInput.is_up(event):
		move_cursor(-1)
	elif MenuInput.is_down(event):
		move_cursor(1)
	elif MenuInput.is_confirm(event):
		# A click on a line chooses that line; on no line, the highlighted one.
		if cursor.take_click(MenuInput.line_under(_list, event, cursor.options.size())):
			_refresh()
			choose()
	elif MenuInput.is_back(event):
		resume()
	else:
		return
	viewport.set_input_as_handled()


## Puts the cursor on the line the mouse is on in `event`, if it is on one.
func point_at(event: InputEvent) -> void:
	if cursor.select(MenuInput.line_under(_list, event, cursor.options.size())):
		EventBus.sound.emit(&"menu_move")
		_refresh()


## The pause panel steps aside while the settings menu, the quest log or the Friends page is
## open in its place.
func _show_panel(shown: bool) -> void:
	$Border.visible = shown
	$Panel.visible = shown


func _refresh() -> void:
	_list.text = "\n".join(cursor.lines())
