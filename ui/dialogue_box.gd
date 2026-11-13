class_name DialogueBox
extends Control
## The text box at the bottom of the screen (docs/TECH_DESIGN.md §7): who is speaking, what
## they say, and the answers to pick from (up/down to move, a left click or Enter to choose).
## It shows a DialogueRunner, which holds the conversation; the area keeps the hero still
## while it's open. On a node with no answers (a sign), the same keys close it.

## The conversation is over and the box has hidden.
signal closed

const CURSOR: String = "> "
## How long after the words appear a left click is not yet an answer (s). The left click is
## also the sword's button: a swing made as a conversation opens by itself (a boss's last
## words) would otherwise skip its first line.
const SWING_GRACE: float = 0.3
## How many answers show at a time. A longer list (the hearth's dishes) scrolls to keep the
## cursor in view, and the corner says where in it he is.
const OPTION_ROWS: int = 4

var runner: DialogueRunner
## Index of the highlighted answer among the visible ones.
var selected: int = 0
## The first answer shown.
var top: int = 0
## How long the box has been open (s).
var open_for: float = 0.0

@onready var _name: Label = $Panel/Lines/Name
@onready var _text: Label = $Panel/Lines/Text
@onready var _options: Label = $Panel/Lines/Options
@onready var _more: Label = $Panel/More


func _ready() -> void:
	hide()


func _process(delta: float) -> void:
	if is_open():
		open_for += delta


## Shows `dialogue_runner`, starting it if it hasn't started.
func open(dialogue_runner: DialogueRunner) -> void:
	runner = dialogue_runner
	runner.ended.connect(_on_ended, CONNECT_ONE_SHOT)
	selected = 0
	top = 0
	open_for = 0.0
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
		top = 0
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
	# Held from before: the last answer can end the game's scene, and the box leaves the tree.
	var viewport: Viewport = get_viewport()
	if MenuInput.is_answer(event):
		# A left click in the first moment is taken for a swing of the sword, and goes nowhere.
		if not (event.is_action_pressed(&"use_hand") and open_for < SWING_GRACE):
			confirm()
	elif event.is_action_pressed(&"move_up"):
		move_cursor(-1)
	elif event.is_action_pressed(&"move_down"):
		move_cursor(1)
	else:
		return
	viewport.set_input_as_handled()


func _on_ended() -> void:
	runner = null
	hide()
	closed.emit()


func _refresh() -> void:
	_name.text = runner.speaker_name()
	_name.visible = not _name.text.is_empty()
	_text.text = runner.text()
	var texts: PackedStringArray = runner.option_texts()
	top = MenuCursor.window_top(top, selected, texts.size(), OPTION_ROWS)
	var lines: PackedStringArray = []
	for i: int in range(top, mini(top + OPTION_ROWS, texts.size())):
		lines.append((CURSOR if i == selected else "  ") + texts[i])
	_options.text = "\n".join(lines)
	_options.visible = not texts.is_empty()
	# The corner: how to read on when there is nothing to choose, or where he is in a long list.
	_more.text = "[%s]" % MenuInput.ANSWER_KEY if texts.is_empty() else MenuCursor.count_text(top, selected, texts.size(), OPTION_ROWS)
	_more.visible = not _more.text.is_empty()


## The answers on screen now, with the cursor's mark (at most OPTION_ROWS of them).
func shown_option_lines() -> PackedStringArray:
	return _options.text.split("\n") if is_open() and _options.visible else PackedStringArray()


## What the corner says: how to read on, where he is in a long list of answers, or nothing.
func corner_text() -> String:
	return _more.text if is_open() and _more.visible else ""
