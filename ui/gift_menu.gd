class_name GiftMenu
extends Control
## What the hero carries that can be given (P4c, GDD §10), in the shape of Tilda's list: a
## villager's conversation opens it (the answer "I brought you something."). Up and down move
## the cursor; a click or Enter gives the thing under it, and the list closes: one gift a
## villager a day. Tab or Esc keeps everything. Friendship (pure) says what can be given;
## GameState gives it. The area opens it and keeps the hero still while it is open.

## Something was given: the area has the villager say their words.
signal given(villager: StringName, item_id: StringName, liked: bool)
signal closed

const CURSOR: String = "> "
## How many lines the box has room for.
const ROWS: int = 5
const TITLE: String = "A gift for %s"
const NOTHING: String = "You carry nothing to give."

## The villager the gift is for (a data entry).
var villager: Dictionary = {}
var selected: int = 0
## The first entry shown.
var top: int = 0

@onready var _title: Label = $Panel/Title
@onready var _list: Label = $Panel/List
@onready var _count: Label = $Panel/Count


func _ready() -> void:
	hide()


## Shows what can be given to `villager_data` (a data entry).
func open(villager_data: Dictionary) -> void:
	villager = villager_data
	selected = 0
	top = 0
	show()
	_refresh()


func is_open() -> bool:
	return visible


## What he carries that can be given (item data entries), in the order it was picked up.
func entries() -> Array[Dictionary]:
	return GameState.gifts_held()


func move_cursor(step: int) -> void:
	var count: int = entries().size()
	if count == 0:
		return
	selected = wrapi(selected + step, 0, count)
	EventBus.sound.emit(&"menu_move")
	_refresh()


## Gives the thing under the cursor, and closes. Returns whether it was given.
func confirm() -> bool:
	var list: Array[Dictionary] = entries()
	if list.is_empty():
		return false
	var who: StringName = StringName(str(villager.get("id", "")))
	var item_id: StringName = StringName(str(list[clampi(selected, 0, list.size() - 1)].get("id", "")))
	var result: Dictionary = GameState.give_gift(who, item_id)
	if result.is_empty():
		EventBus.sound.emit(&"nope")
		return false
	given.emit(who, item_id, bool(result["liked"]))
	close()
	return true


func close() -> void:
	if not visible:
		return
	hide()
	closed.emit()


func shown_lines() -> PackedStringArray:
	return _list.text.split("\n") if visible else PackedStringArray()


func title_text() -> String:
	return _title.text


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if MenuInput.is_confirm(event):
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


func _refresh() -> void:
	var list: Array[Dictionary] = entries()
	selected = clampi(selected, 0, maxi(list.size() - 1, 0))
	top = MenuCursor.window_top(top, selected, list.size(), ROWS)
	var lines: PackedStringArray = []
	for i: int in range(top, mini(top + ROWS, list.size())):
		var id: StringName = StringName(str(list[i].get("id", "")))
		lines.append("%s%s x%d" % [CURSOR if i == selected else "  ", str(list[i].get("name", id)), GameState.item_count(id)])
	if list.is_empty():
		lines.append(NOTHING)
	_title.text = TITLE % str(villager.get("name", "them"))
	_list.text = "\n".join(lines)
	_count.text = MenuCursor.count_text(top, selected, list.size(), ROWS)
