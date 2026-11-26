class_name StoreMenu
extends Control
## The storage chest's two lists (crafting, 2026-11-17, docs/TECH_DESIGN.md §28): what he
## carries that a chest keeps, and what the chest holds. Up and down (or the wheel) move the
## cursor; left and right turn from one list to the other; a click or Enter moves the stack
## under the cursor across, as much of it as there is room for; Tab or Esc leaves. The mouse
## points: at a line of either list to put the cursor there. A line says what was moved, or why
## not. Store (pure) keeps the stacks; GameState moves them. The area opens it and keeps the
## hero still while it is open. Each line has its item's picture beside it (ItemIconColumn).

signal closed

const CURSOR: String = "> "
## How many lines each list has room for.
const ROWS: int = 7
const PACK: StringName = &"pack"
const CHEST: StringName = &"chest"
const SIDES: Array[StringName] = [PACK, CHEST]
const PACK_TITLE: String = "Your pack"
const CHEST_TITLE: String = "Chest  %d of %d"
const EMPTY_PACK: String = "Nothing to put away."
const EMPTY_CHEST: String = "The chest is empty."
const PUT_WORDS: String = "Put away: %s."
const TOOK_WORDS: String = "Took out: %s."
const STACK_LINE: String = "%s x%d"

var side: StringName = PACK
## Which chest it shows: &"" the farmhouse's, else the key of a building room's (&"shed_a").
var key: StringName = &""
var selected: int = 0
## The first entry shown of each list.
var tops: Dictionary = {PACK: 0, CHEST: 0}

@onready var _pack_title: Label = $Panel/PackTitle
@onready var _chest_title: Label = $Panel/ChestTitle
@onready var _pack: Label = $Panel/PackList
@onready var _chest: Label = $Panel/ChestList
@onready var _pack_icons: ItemIconColumn = $Panel/PackIcons
@onready var _chest_icons: ItemIconColumn = $Panel/ChestIcons
@onready var _note: Label = $Panel/Note
@onready var _count: Label = $Panel/Count


func _ready() -> void:
	hide()


func open(chest: StringName = &"") -> void:
	# It opens on the pack; with nothing there to put away, _refresh turns to the chest.
	key = chest
	side = PACK
	selected = 0
	tops = {PACK: 0, CHEST: 0}
	_note.text = ""
	show()
	_refresh()


func is_open() -> bool:
	return visible


## The stacks of list `which` (PACK or CHEST): [{ "id", "count" }].
func entries(which: StringName = side) -> Array[Dictionary]:
	return GameState.store(key).stacks() if which == CHEST else GameState.storable_stacks()


func move_cursor(step: int) -> void:
	var count: int = entries().size()
	if count == 0:
		return
	selected = wrapi(selected + step, 0, count)
	EventBus.sound.emit(&"menu_move")
	_refresh()


## Turns to the other list.
func switch_side() -> void:
	side = CHEST if side == PACK else PACK
	selected = 0
	EventBus.sound.emit(&"menu_move")
	_refresh()


## Moves the stack under the cursor across. Returns whether any of it moved; the note says
## what moved, or why not.
func confirm() -> bool:
	var list: Array[Dictionary] = entries()
	if list.is_empty():
		return false
	var index: int = clampi(selected, 0, list.size() - 1)
	var stack: Dictionary = list[index]
	var item_id: StringName = StringName(str(stack["id"]))
	var before: int = GameState.item_count(item_id)
	var why_not: String = GameState.store_take(index, key) if side == CHEST else GameState.store_put(item_id, key)
	if not why_not.is_empty():
		EventBus.sound.emit(&"nope")
		_note.text = why_not
		_refresh()
		return false
	var moved: int = absi(GameState.item_count(item_id) - before)
	EventBus.sound.emit(&"menu_select")
	_note.text = (TOOK_WORDS if side == CHEST else PUT_WORDS) % _stack_words(str(stack["id"]), moved)
	_refresh()
	return true


func close() -> void:
	if not visible:
		return
	hide()
	closed.emit()


## The lines of list `which` as they read.
func shown_lines(which: StringName = side) -> PackedStringArray:
	if not visible:
		return PackedStringArray()
	return (_chest if which == CHEST else _pack).text.split("\n")


## The icons of the lines list `which` shows, in order (none when it is closed or the list is
## empty).
func shown_icons(which: StringName = side) -> Array[StringName]:
	if not visible:
		return [] as Array[StringName]
	return (_chest_icons if which == CHEST else _pack_icons).icons.duplicate()


func note_text() -> String:
	return _note.text


func chest_title() -> String:
	return _chest_title.text


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
	elif event.is_action_pressed(&"move_left") or event.is_action_pressed(&"move_right"):
		switch_side()
	else:
		return
	get_viewport().set_input_as_handled()


## Puts the cursor on the line the mouse is on in `event`, on whichever list it is.
func point_at(event: InputEvent) -> void:
	for which: StringName in SIDES:
		var label: Label = _chest if which == CHEST else _pack
		var line: int = MenuInput.line_under(label, event, mini(ROWS, entries(which).size() - int(tops[which])), ItemIconColumn.WIDTH)
		if line == MenuPointer.NONE:
			continue
		if which == side and int(tops[which]) + line == selected:
			return
		side = which
		selected = int(tops[which]) + line
		EventBus.sound.emit(&"menu_move")
		_refresh()
		return


func _stack_words(item_id: String, count: int) -> String:
	var words: String = str(DataRegistry.get_item(StringName(item_id)).get("name", item_id))
	return STACK_LINE % [words, count] if count != 1 else words


## The item ids of the lines list `which` shows, from its first shown line.
func _shown_ids(which: StringName) -> Array:
	var list: Array[Dictionary] = entries(which)
	var ids: Array = []
	for i: int in range(int(tops[which]), mini(int(tops[which]) + ROWS, list.size())):
		ids.append(str(list[i]["id"]))
	return ids


func _lines(which: StringName) -> PackedStringArray:
	var list: Array[Dictionary] = entries(which)
	var top: int = int(tops[which])
	if which == side:
		selected = clampi(selected, 0, maxi(list.size() - 1, 0))
		top = MenuCursor.window_top(top, selected, list.size(), ROWS)
	else:
		top = clampi(top, 0, maxi(list.size() - ROWS, 0))
	tops[which] = top
	var lines: PackedStringArray = []
	for i: int in range(top, mini(top + ROWS, list.size())):
		var words: String = STACK_LINE % [str(DataRegistry.get_item(StringName(str(list[i]["id"]))).get("name", list[i]["id"])), int(list[i]["count"])]
		lines.append((CURSOR if which == side and i == selected else "  ") + words)
	if list.is_empty():
		lines.append(EMPTY_CHEST if which == CHEST else EMPTY_PACK)
	return lines


func _refresh() -> void:
	# A list that a move emptied hands the cursor to the other, if that one has anything.
	if entries().is_empty() and not entries(CHEST if side == PACK else PACK).is_empty():
		side = CHEST if side == PACK else PACK
		selected = 0
	_pack.text = "\n".join(_lines(PACK))
	_chest.text = "\n".join(_lines(CHEST))
	_pack_icons.show_icons(ItemIconColumn.icons_of(_shown_ids(PACK)), MenuInput.line_height(_pack))
	_chest_icons.show_icons(ItemIconColumn.icons_of(_shown_ids(CHEST)), MenuInput.line_height(_chest))
	_pack_title.text = PACK_TITLE
	_chest_title.text = CHEST_TITLE % [GameState.store(key).used_slots(), GameState.store(key).slots]
	_count.text = MenuCursor.count_text(int(tops[side]), selected, entries().size(), ROWS)
