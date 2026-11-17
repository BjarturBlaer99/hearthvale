class_name CraftMenu
extends Control
## The workbench's list (crafting, 2026-11-17, docs/TECH_DESIGN.md §28): the recipes he knows,
## what the one under the cursor needs beside what he has ("Stone 12 of 20"), and the ones he
## can't make now greyed out. Up and down (or the wheel) move the cursor; a click or Enter makes
## the thing under it; Tab or Esc leaves. The mouse points: at a line to put the cursor there.
## It stays open for as many things as he likes, and a line says what was made, or why not.
## Crafting (pure) says what is known and what is missing; GameState makes it. The area opens it
## and keeps the hero still while it is open.

signal closed

const CURSOR: String = "> "
## How many recipes the box has room for.
const ROWS: int = 6
const TITLE: String = "Workbench"
const NOTHING_WORDS: String = "You know nothing to make yet."
## The heading over what the thing under the cursor needs: each need has a line of its own.
const NEEDS_WORDS: String = "Needs:"

var selected: int = 0
## The first entry shown.
var top: int = 0

@onready var _title: Label = $Panel/Title
## Two lists in the same place: what he can make now, and (greyed) what he can't. A line is on
## one of them and blank on the other.
@onready var _list: Label = $Panel/List
@onready var _dim: Label = $Panel/ListDim
@onready var _needs: Label = $Panel/Needs
@onready var _note: Label = $Panel/Note
@onready var _count: Label = $Panel/Count


func _ready() -> void:
	hide()


func open() -> void:
	selected = 0
	top = 0
	_note.text = ""
	show()
	_refresh()


func is_open() -> bool:
	return visible


## The recipes on the list: what the workbench makes that he knows, in their order.
func entries() -> Array[Dictionary]:
	return GameState.known_crafts(Crafting.WORKBENCH)


## Whether entry `index` can be made now.
func can_make(index: int) -> bool:
	var list: Array[Dictionary] = entries()
	return index >= 0 and index < list.size() and GameState.why_not_craft(list[index]).is_empty()


func move_cursor(step: int) -> void:
	var count: int = entries().size()
	if count == 0:
		return
	selected = wrapi(selected + step, 0, count)
	_note.text = ""
	EventBus.sound.emit(&"menu_move")
	_refresh()


## Makes the thing under the cursor. Returns whether it was made; the note says what was made,
## or why not.
func confirm() -> bool:
	var list: Array[Dictionary] = entries()
	if list.is_empty():
		return false
	var recipe: Dictionary = list[clampi(selected, 0, list.size() - 1)]
	var words: String = Crafting.name_of(recipe, _names())
	var why_not: String = GameState.craft(StringName(str(recipe["id"])))
	if why_not.is_empty():
		EventBus.sound.emit(&"craft")
		_note.text = Crafting.MADE_WORDS % words
	else:
		EventBus.sound.emit(&"nope")
		_note.text = why_not
	_refresh()
	return why_not.is_empty()


func close() -> void:
	if not visible:
		return
	hide()
	closed.emit()


## The lines of the list as they read, whichever of the two lists each is on.
func shown_lines() -> PackedStringArray:
	if not visible:
		return PackedStringArray()
	var bright: PackedStringArray = _list.text.split("\n")
	var grey: PackedStringArray = _dim.text.split("\n")
	var out: PackedStringArray = []
	for index: int in bright.size():
		out.append(bright[index] if not bright[index].is_empty() else (grey[index] if index < grey.size() else ""))
	return out


## The lines of the bright list alone: a line he can't make now is blank here, since it is on
## the dim list (the two are drawn in the same place).
func bright_lines() -> PackedStringArray:
	return _list.text.split("\n") if visible else PackedStringArray()


## Which of the shown lines are greyed out (true: it can't be made now).
func greyed_lines() -> Array[bool]:
	var out: Array[bool] = []
	if not visible:
		return out
	for line: String in _dim.text.split("\n"):
		out.append(not line.is_empty())
	return out


## What the thing under the cursor needs, beside what he has: "Stone 12 of 20".
func need_lines() -> PackedStringArray:
	var list: Array[Dictionary] = entries()
	if list.is_empty():
		return PackedStringArray()
	return Crafting.need_lines(list[clampi(selected, 0, list.size() - 1)], func(item_id: String) -> int: return GameState.item_count(StringName(item_id)), _names())


func needs_text() -> String:
	return _needs.text


func note_text() -> String:
	return _note.text


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if MenuInput.is_pointing(event):
		point_at(event)
		return
	if MenuInput.is_confirm(event):
		point_at(event)
		confirm()
	elif MenuInput.is_back(event):
		close()
	elif MenuInput.is_up(event):
		move_cursor(-1)
	elif MenuInput.is_down(event):
		move_cursor(1)
	else:
		return
	get_viewport().set_input_as_handled()


## Puts the cursor on the line the mouse is on in `event`, if it is on one.
func point_at(event: InputEvent) -> void:
	var line: int = MenuInput.line_under(_list, event, mini(ROWS, entries().size() - top))
	if line == MenuPointer.NONE or top + line == selected:
		return
	selected = top + line
	_note.text = ""
	EventBus.sound.emit(&"menu_move")
	_refresh()


func _names() -> Dictionary:
	var names: Dictionary = {}
	for item: Dictionary in DataRegistry.entries(&"items"):
		names[str(item["id"])] = str(item.get("name", item["id"]))
	return names


func _refresh() -> void:
	var list: Array[Dictionary] = entries()
	var names: Dictionary = _names()
	selected = clampi(selected, 0, maxi(list.size() - 1, 0))
	top = MenuCursor.window_top(top, selected, list.size(), ROWS)
	var bright: PackedStringArray = []
	var grey: PackedStringArray = []
	for i: int in range(top, mini(top + ROWS, list.size())):
		var words: String = (CURSOR if i == selected else "  ") + Crafting.name_of(list[i], names)
		var able: bool = GameState.why_not_craft(list[i]).is_empty()
		bright.append(words if able else "")
		grey.append("" if able else words)
	if list.is_empty():
		bright.append(NOTHING_WORDS)
		grey.append("")
	_title.text = TITLE
	_list.text = "\n".join(bright)
	_dim.text = "\n".join(grey)
	_needs.text = NEEDS_WORDS + "\n" + "\n".join(need_lines()) if not list.is_empty() else ""
	_count.text = MenuCursor.count_text(top, selected, list.size(), ROWS)
