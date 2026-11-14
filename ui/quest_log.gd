class_name QuestLog
extends Control
## The quest log (pause menu, "Quests"; docs/TECH_DESIGN.md §7): every started quest, active
## ones first, then finished ones. Up and down pick one; its journal line and objectives show
## below, each objective ticked when done. Esc (or Back) returns to the pause menu. It reads
## the quests as they stand when opened, and works while the game is paused. Five lines show
## at a time: a longer list scrolls to keep the cursor in view, and the corner says where in it
## he is (P4d).

signal closed

const BACK: StringName = &"back"
## How many lines of the list the box has room for.
const ROWS: int = 5
const NO_QUESTS: String = "No quests yet. The folk of Hearthvale may have work for you."

var cursor: MenuCursor = MenuCursor.new()
## The first line shown.
var top: int = 0

## Quest id -> its entry from QuestRunner.started_quests().
var _entries: Dictionary = {}

@onready var _list: Label = $Panel/List
@onready var _detail: Label = $Panel/Detail
@onready var _count: Label = $Panel/Count


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	hide()


func open() -> void:
	_entries.clear()
	var options: Array[Dictionary] = []
	for entry: Dictionary in Quests.runner.started_quests():
		_entries[entry["id"]] = entry
		options.append(MenuCursor.option(entry["id"], title_line(entry)))
	options.append(MenuCursor.option(BACK, "Back"))
	cursor.set_options(options)
	top = 0
	_refresh()
	show()


func is_open() -> bool:
	return visible


func close() -> void:
	if not visible:
		return
	hide()
	closed.emit()


func move_cursor(step: int) -> void:
	EventBus.sound.emit(&"menu_move")
	cursor.move(step)
	_refresh()


## The lines on screen now: at most ROWS of the list.
func shown_lines() -> PackedStringArray:
	return _list.text.split("\n") if visible else PackedStringArray()


## Every line of the list, shown or not.
func all_lines() -> PackedStringArray:
	return cursor.lines() if visible else PackedStringArray()


## What the corner says: where he is in a list longer than its box, or nothing.
func corner_text() -> String:
	return _count.text if visible else ""


func shown_detail() -> String:
	return _detail.text if visible else ""


## "The Lost Shuttle", or "The Lost Shuttle (done)" once finished.
static func title_line(entry: Dictionary) -> String:
	var done: bool = entry.get("status", &"") == QuestState.COMPLETE
	return "%s (done)" % entry.get("title", "") if done else str(entry.get("title", ""))


## A quest's journal line, then its objectives: "[x]" when done, "[ ]" when not.
static func detail_text(entry: Dictionary) -> String:
	var lines: PackedStringArray = [str(entry.get("journal", ""))]
	for objective: Dictionary in entry.get("objectives", []):
		var line: String = "[%s] %s" % ["x" if objective.get("done", false) else " ", objective.get("text", "")]
		lines.append(line + " (optional)" if objective.get("optional", false) else line)
	return "\n".join(lines)


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	var viewport: Viewport = get_viewport()
	if MenuInput.is_up(event):
		move_cursor(-1)
	elif MenuInput.is_down(event):
		move_cursor(1)
	elif MenuInput.is_back(event) or (MenuInput.is_confirm(event) and cursor.selected_id() == BACK):
		close()
	else:
		return
	viewport.set_input_as_handled()


func _refresh() -> void:
	var lines: PackedStringArray = cursor.lines()
	top = MenuCursor.window_top(top, cursor.selected, lines.size(), ROWS)
	_list.text = "\n".join(lines.slice(top, top + ROWS))
	_count.text = MenuCursor.count_text(top, cursor.selected, lines.size(), ROWS)
	var id: StringName = cursor.selected_id()
	if _entries.has(id):
		_detail.text = detail_text(_entries[id])
	else:
		_detail.text = NO_QUESTS if _entries.is_empty() else ""
