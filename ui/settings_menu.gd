class_name SettingsMenu
extends Control
## The settings menu (docs/TECH_DESIGN.md §12): fullscreen, window size, the controls hint,
## and Back. Up and down pick a line; E, Enter or right moves the setting on, left moves it
## back; Esc (or Start, or Tab) closes. The mouse points at a line, and a click moves that
## setting on. Changes apply and are kept at once (Settings). It works while the game is paused.

signal closed

const BACK: StringName = &"back"

var cursor: MenuCursor = MenuCursor.new()

@onready var _list: Label = $Panel/List


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()


func open() -> void:
	_rebuild(SettingsData.KEYS[0])
	show()


func is_open() -> bool:
	return visible


func close() -> void:
	if not visible:
		return
	hide()
	closed.emit()


## Moves the highlighted setting on by `step`, or closes on Back.
func change(step: int = 1) -> void:
	var id: StringName = cursor.selected_id()
	if id == BACK:
		close()
		return
	Settings.change(id, step)
	EventBus.sound.emit(&"menu_select")
	_rebuild(id)


func move_cursor(step: int) -> void:
	EventBus.sound.emit(&"menu_move")
	cursor.move(step)
	_list.text = "\n".join(cursor.lines())


func shown_lines() -> PackedStringArray:
	return cursor.lines() if visible else PackedStringArray()


func _unhandled_input(event: InputEvent) -> void:
	# Take the viewport now: a choice can change the scene, which takes this menu out of the tree.
	var viewport: Viewport = get_viewport()
	if not visible:
		return
	if MenuInput.is_pointing(event):
		point_at(event)
		return
	if MenuInput.is_up(event):
		move_cursor(-1)
	elif MenuInput.is_down(event):
		move_cursor(1)
	elif MenuInput.is_confirm(event):
		if cursor.take_click(MenuInput.line_under(_list, event, cursor.options.size())):
			change(1)
	elif event.is_action_pressed(&"move_right"):
		change(1)
	elif event.is_action_pressed(&"move_left"):
		change(-1)
	elif MenuInput.is_back(event):
		close()
	else:
		return
	viewport.set_input_as_handled()


## Puts the cursor on the line the mouse is on in `event`, if it is on one.
func point_at(event: InputEvent) -> void:
	if cursor.select(MenuInput.line_under(_list, event, cursor.options.size())):
		EventBus.sound.emit(&"menu_move")
		_list.text = "\n".join(cursor.lines())


func _rebuild(keep: StringName) -> void:
	var options: Array[Dictionary] = []
	for key: StringName in SettingsData.KEYS:
		options.append(MenuCursor.option(key, Settings.data.describe(key)))
	options.append(MenuCursor.option(BACK, "Back"))
	cursor.set_options(options, keep)
	_list.text = "\n".join(cursor.lines())
