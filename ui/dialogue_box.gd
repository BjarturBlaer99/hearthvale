class_name DialogueBox
extends Control
## The text box at the bottom of the screen (docs/TECH_DESIGN.md §7): who is speaking, what
## they say, and the answers to pick from (up/down to move, interact to choose). It shows a
## DialogueRunner, which holds the conversation; the area keeps the hero still while it's
## open. On a node with no answers (a sign), interact closes it.

## The conversation is over and the box has hidden.
signal closed

const CURSOR: String = "> "

var runner: DialogueRunner
## Index of the highlighted answer among the visible ones.
var selected: int = 0

@onready var _name: Label = $Panel/Lines/Name
@onready var _text: Label = $Panel/Lines/Text
@onready var _options: Label = $Panel/Lines/Options
@onready var _more: Label = $Panel/More


func _ready() -> void:
	hide()


## Shows `dialogue_runner`, starting it if it hasn't started.
func open(dialogue_runner: DialogueRunner) -> void:
	runner = dialogue_runner
	runner.ended.connect(_on_ended, CONNECT_ONE_SHOT)
	selected = 0
	show()
	if not runner.is_running():
		runner.start()
	if runner != null:
		_refresh()


func is_open() -> bool:
	return visible and runner != null


func move_cursor(step: int) -> void:
	if not is_open():
		return
	var count: int = runner.options().size()
	if count == 0:
		return
	selected = wrapi(selected + step, 0, count)
	EventBus.sound.emit(&"menu_move")
	_refresh()


## Picks the highlighted answer, or closes a box with nothing to answer.
func confirm() -> void:
	if not is_open():
		return
	if runner.options().is_empty():
		runner.advance()
	else:
		runner.choose(selected)
	if is_open():
		selected = 0
		_refresh()


func shown_name() -> String:
	return _name.text if _name.visible else ""


func shown_text() -> String:
	return _text.text


## The answers as shown, without the cursor.
func shown_options() -> PackedStringArray:
	return runner.option_texts() if is_open() else PackedStringArray()


func _unhandled_input(event: InputEvent) -> void:
	if not is_open():
		return
	if event.is_action_pressed(&"interact"):
		confirm()
	elif event.is_action_pressed(&"move_up"):
		move_cursor(-1)
	elif event.is_action_pressed(&"move_down"):
		move_cursor(1)
	else:
		return
	get_viewport().set_input_as_handled()


func _on_ended() -> void:
	runner = null
	hide()
	closed.emit()


func _refresh() -> void:
	_name.text = runner.speaker_name()
	_name.visible = not _name.text.is_empty()
	_text.text = runner.text()
	var texts: PackedStringArray = runner.option_texts()
	var lines: PackedStringArray = []
	for i: int in texts.size():
		lines.append((CURSOR if i == selected else "  ") + texts[i])
	_options.text = "\n".join(lines)
	_options.visible = not texts.is_empty()
	_more.visible = texts.is_empty()
