class_name BarMenu
extends Control
## The screen that arranges the item bar (step B2 of docs/progress/icons-axe-bar-plan.md; the
## pause menu's "Item bar", the user's Q12): the bar's slots in rows of nine (BarSlots), with
## the name of the thing under the cursor below. A click on a slot lifts what is in it; a click
## on another slot sets it down there, swapping with what was there or into an empty one; a
## click on its own slot, a right click, Esc or Tab puts it back. A click on no slot does
## nothing. The movement keys step a slot (left, right) or a row (up, down), the wheel a slot,
## and Enter lifts and sets down. Esc or Tab with nothing lifted goes back to the pause menu.
## Each move is made at once (GameState.move_on_bar), so leaving keeps the arrangement and
## the bar in play shows it; the save keeps it in "bar". Works while the game is paused.
## BarCursor (pure) keeps the cursor and the lifted slot.

signal closed

## The box's sides and what stands in it (px).
const WIDTH: float = 240.0
const SLOTS_TOP: float = 32.0
const LINE: float = 11.0
const SPACE: float = 6.0
## What the name line says over an empty slot.
const EMPTY_WORDS: String = "An empty slot"

var cursor: BarCursor = BarCursor.new()

## Each slot's entry as shown (HandBar's columns, {} for an empty one, as many as the screen
## has slots).
var _entries: Array[Dictionary] = []

@onready var _border: ColorRect = $Border
@onready var _panel: PanelFrame = $Panel
@onready var _slots: BarSlots = $Panel/Slots
@onready var _name: Label = $Panel/Name
@onready var _help: Label = $Panel/Help


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	MenuInput.let_clicks_through(self)
	hide()


## Shows the bar as it stands, the cursor on the thing in hand.
func open() -> void:
	cursor = BarCursor.new()
	_read_bar()
	cursor.at = clampi(GameState.hand_index(), 0, cursor.cells - 1)
	show()
	_refresh()


func is_open() -> bool:
	return visible


## Leaves (putting back anything lifted).
func close() -> void:
	if not visible:
		return
	cursor.put_back()
	hide()
	closed.emit()


## What each slot holds, by item id ("" for an empty one), as many as the screen shows.
func shown_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for entry: Dictionary in _entries:
		out.append(StringName(str(entry.get("id", ""))))
	return out


## The item lifted, or "" for none.
func lifted_id() -> StringName:
	return StringName(str(_entries[cursor.lifted].get("id", ""))) if cursor.is_lifting() else &""


func shown_name() -> String:
	return _name.text


func shown_help() -> String:
	return _help.text


## Where the middle of slot `index` is on the screen (for a pointer).
func slot_point(index: int) -> Vector2:
	return _slots.get_global_transform_with_canvas() * _slots.slot_rect(index).get_center()


## A choice on slot `index` (a click on it, or Enter on the cursor's): lifts, sets down or puts
## back.
func choose(index: int) -> void:
	if index < 0 or index >= _entries.size():
		return
	var was_lifting: bool = cursor.is_lifting()
	var move: Vector2i = cursor.choose(index, not _entries[index].is_empty())
	if move != BarCursor.NO_MOVE:
		GameState.move_on_bar(move.x, move.y)
		_read_bar()
		EventBus.sound.emit(&"set_down")
	elif cursor.is_lifting():
		EventBus.sound.emit(&"take_up")
	elif was_lifting:
		EventBus.sound.emit(&"menu_move")
	else:
		# An empty slot, with nothing to set down in it.
		EventBus.sound.emit(&"nope")
	_refresh()


## Puts back what is lifted, or with nothing lifted goes back to the pause menu.
func back() -> void:
	if cursor.put_back():
		EventBus.sound.emit(&"menu_move")
		_refresh()
	else:
		close()


func move_cursor(step: int) -> void:
	cursor.step(step)
	EventBus.sound.emit(&"menu_move")
	_refresh()


func move_row(step: int) -> void:
	cursor.step_row(step)
	EventBus.sound.emit(&"menu_move")
	_refresh()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var viewport: Viewport = get_viewport()
	if MenuInput.is_pointing(event):
		if cursor.point(slot_under(event)):
			EventBus.sound.emit(&"menu_move")
			_refresh()
		return
	if event.is_action_pressed(&"slot_previous"):
		move_cursor(-1)
	elif event.is_action_pressed(&"slot_next"):
		move_cursor(1)
	elif event.is_action_pressed(&"move_left"):
		move_cursor(-1)
	elif event.is_action_pressed(&"move_right"):
		move_cursor(1)
	elif event.is_action_pressed(&"move_up"):
		move_row(-1)
	elif event.is_action_pressed(&"move_down"):
		move_row(1)
	elif event.is_action_pressed(&"use_hand"):
		# A click chooses the slot it is on; on no slot it does nothing.
		var index: int = slot_under(event) if event is InputEventMouse else cursor.at
		if index != BarCursor.NONE:
			choose(index)
	elif MenuInput.is_back(event):
		back()
	elif event.is_action_pressed(&"interact"):
		# A right click puts back what is lifted.
		if cursor.put_back():
			EventBus.sound.emit(&"menu_move")
			_refresh()
	elif event.is_action_pressed(&"ui_accept"):
		choose(cursor.at)
	else:
		return
	viewport.set_input_as_handled()


## Which slot the mouse is on in `event`, or BarCursor.NONE.
func slot_under(event: InputEvent) -> int:
	if not event is InputEventMouse or not _slots.is_visible_in_tree():
		return BarCursor.NONE
	return _slots.slot_at((_slots.make_input_local(event) as InputEventMouse).position)


## Reads the bar from GameState: a slot for each column, empty ones to fill the rows.
func _read_bar() -> void:
	var columns: Array[Dictionary] = GameState.hand_entries()
	cursor.set_columns(columns.size())
	_entries = columns
	while _entries.size() < cursor.cells:
		_entries.append({})


func _refresh() -> void:
	var counts: PackedStringArray = []
	for entry: Dictionary in _entries:
		counts.append("" if entry.is_empty() else HandBar.count_text(entry, GameState.item_count))
	_slots.show_slots(_entries, cursor.at, cursor.lifted, counts)
	_name.text = _name_words()
	_help.text = ("Click: set down   %s" % MenuInput.prompt("Put back")) if cursor.is_lifting() else "Click: lift   Esc: back"
	_lay_out()


## The name line: what is under the cursor, or, with something lifted, where it would go.
func _name_words() -> String:
	var under: Dictionary = _entries[cursor.at] if cursor.at < _entries.size() else {}
	if not cursor.is_lifting():
		return EMPTY_WORDS if under.is_empty() else _name_of(under)
	var lifted: String = _name_of(_entries[cursor.lifted])
	if cursor.at == cursor.lifted:
		return "%s: put it back" % lifted
	if under.is_empty():
		return "%s: set it down here" % lifted
	return "%s: swap with the %s" % [lifted, _name_of(under)]


static func _name_of(entry: Dictionary) -> String:
	return str(entry.get("name", entry.get("id", "")))


## Fits the box round its rows: the slots, then the name line and the help line under them.
func _lay_out() -> void:
	var slots_bottom: float = SLOTS_TOP + _slots.size.y
	_slots.position = Vector2(roundf((WIDTH - BarSlots.width()) / 2.0), SLOTS_TOP)
	_name.position = Vector2(10.0, slots_bottom + SPACE)
	_help.position = Vector2(10.0, slots_bottom + SPACE + LINE + 4.0)
	var height: float = _help.position.y + LINE + SPACE
	var top: float = -roundf(height / 2.0)
	_panel.offset_left = -WIDTH / 2.0
	_panel.offset_right = WIDTH / 2.0
	_panel.offset_top = top
	_panel.offset_bottom = top + height
	_border.offset_left = _panel.offset_left - 1.0
	_border.offset_right = _panel.offset_right + 1.0
	_border.offset_top = _panel.offset_top - 1.0
	_border.offset_bottom = _panel.offset_bottom + 1.0
