class_name ItemMenu
extends Control
## The item menu (Tab): the hero's sword (to take it in hand again), the items for the item
## button that he holds, with their ammo, then the food he carries, with what each gives (P2d). Up/down (or left/right) moves the
## cursor; a click picks the highlighted item and closes; Tab closes without changing anything. The
## area equips or eats the chosen item (`chosen`) and keeps the hero still while the menu is
## open. The box shows ROWS lines: a longer list (tools, seeds and a harvest, P3b) scrolls to
## keep the cursor in view, and a corner says where in the list he is.

signal chosen(item_id: StringName)
signal closed

const CURSOR: String = "> "
## How many lines the box has room for.
const ROWS: int = 5

var items: Array[Dictionary] = []
var selected: int = 0
## The first item shown.
var top: int = 0

@onready var _list: Label = $Panel/List
@onready var _count: Label = $Panel/Count


## "Bow (Arrows x10)", "Bombs x3": an item and what it has left to use.
static func describe(item: Dictionary) -> String:
	var name_text: String = str(item.get("name", item.get("id", "?")))
	if Food.is_food(item):
		var id: StringName = StringName(str(item.get("id", "")))
		return "%s x%d (%s)" % [name_text, GameState.item_count(id), Food.gives_text(item, GameState.food_energy(id))]
	var ammo: String = Inventory.ammo_for(item)
	if ammo.is_empty():
		return name_text
	var count: int = GameState.item_count(StringName(ammo))
	if ammo == str(item.get("id", "")):
		return "%s x%d" % [name_text, count]
	var ammo_name: String = str(DataRegistry.get_item(StringName(ammo)).get("name", ammo))
	return "%s (%s x%d)" % [name_text, ammo_name, count]


func _ready() -> void:
	hide()


## Shows `held` (item entries), with the cursor on `equipped` if it's among them.
func open(held: Array[Dictionary], equipped: StringName) -> void:
	items = held
	selected = 0
	top = 0
	for i: int in items.size():
		if str(items[i].get("id", "")) == String(equipped):
			selected = i
	show()
	_refresh()


func is_open() -> bool:
	return visible


func selected_id() -> StringName:
	if items.is_empty():
		return &""
	return StringName(str(items[selected].get("id", "")))


func move_cursor(step: int) -> void:
	if items.is_empty():
		return
	selected = wrapi(selected + step, 0, items.size())
	EventBus.sound.emit(&"menu_move")
	_refresh()


## Picks the highlighted item and closes. Returns its id.
func confirm() -> StringName:
	var id: StringName = selected_id()
	if id != &"":
		EventBus.sound.emit(&"menu_select")
		chosen.emit(id)
	close()
	return id


func close() -> void:
	if not visible:
		return
	hide()
	closed.emit()


func shown_lines() -> PackedStringArray:
	return _list.text.split("\n") if visible else PackedStringArray()


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if event.is_action_pressed(&"interact") or event.is_action_pressed(&"use_item") or event.is_action_pressed(&"use_hand"):
		confirm()
	elif event.is_action_pressed(&"item_menu"):
		close()
	elif event.is_action_pressed(&"move_up") or event.is_action_pressed(&"move_left"):
		move_cursor(-1)
	elif event.is_action_pressed(&"move_down") or event.is_action_pressed(&"move_right"):
		move_cursor(1)
	else:
		return
	get_viewport().set_input_as_handled()


func _refresh() -> void:
	top = MenuCursor.window_top(top, selected, items.size(), ROWS)
	var lines: PackedStringArray = []
	for i: int in range(top, mini(top + ROWS, items.size())):
		lines.append((CURSOR if i == selected else "  ") + describe(items[i]))
	_list.text = "\n".join(lines)
	_count.text = MenuCursor.count_text(top, selected, items.size(), ROWS)
