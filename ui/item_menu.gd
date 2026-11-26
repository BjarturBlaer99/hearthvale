class_name ItemMenu
extends Control
## The Tab menu: two lists, turned as the shop's are (left and right, or a click on a name).
## "Food" (P2d) is the food he carries, with what each gives: a click or Enter eats the line
## under the cursor and closes (the area eats it: `chosen`). "Pack" (icons, an axe and the item
## bar, step I2) is everything he carries, in the pack's order, with its count (PackList), to
## look at only: a click there only points, and nothing on it is eaten, dropped or put in hand
## (what is in hand is chosen on the bar). It opens on Food, or on Pack when he has no food, so
## Tab always opens. Up/down and the wheel move the cursor; Tab or Esc closes without changing
## anything. The area keeps the hero still while it is open. The box shows ROWS lines: a longer
## list scrolls to keep the cursor in view, and a corner says where in the list he is. Each
## line has its item's picture beside it (ItemIconColumn).

signal chosen(item_id: StringName)
signal closed

const CURSOR: String = "> "
## How many lines the box has room for.
const ROWS: int = 5
## The two lists.
const FOOD: StringName = &"food"
const PACK: StringName = &"pack"
const LISTS: Array[StringName] = [FOOD, PACK]
## The two lists as their tabs (and the heading) name them.
const TAB_NAMES: Dictionary = {FOOD: "Food", PACK: "Pack"}
## What stands between the two names.
const TAB_GAP: String = "  "
const NOTHING_TO_EAT: String = "You carry nothing to eat."
const NOTHING_CARRIED: String = "You carry nothing."
## Each list's help line: on Pack a click does nothing, so it isn't offered.
const HELP: Dictionary = {FOOD: "Click: eat   A / D: turn   Tab: close", PACK: "A / D: turn   Tab: close"}

## The list shown (FOOD or PACK).
var list: StringName = FOOD
## The entries of the list shown (item data, in order).
var items: Array[Dictionary] = []
var selected: int = 0
## The first item shown.
var top: int = 0

@onready var _title: Label = $Panel/Title
@onready var _tabs: Label = $Panel/Tabs
@onready var _help: Label = $Panel/Help
@onready var _list: Label = $Panel/List
@onready var _icons: ItemIconColumn = $Panel/Icons
@onready var _count: Label = $Panel/Count


## "Bow (Arrows x10)", "Bombs x3", "Bread x2 (+30 energy)": an item and what it has left to
## use, or what it gives if it is food.
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


## The list Tab opens on: Food if he carries any, else Pack.
static func first_list() -> StringName:
	return FOOD if not food_held().is_empty() else PACK


## The food he carries, in the order it was picked up (item data).
static func food_held() -> Array[Dictionary]:
	return Food.edible_held(GameState.inventory, DataRegistry.entries(&"items"))


## Everything he carries, in the pack's order (item data; PackList).
static func pack_held() -> Array[Dictionary]:
	return PackList.entries(GameState.inventory, DataRegistry.entries(&"items"))


## A stack of the pack as its line reads: "Stone x9", "Watering Can (Water x10)", "120 coins".
static func pack_line(item: Dictionary) -> String:
	var count: int = GameState.item_count(StringName(str(item.get("id", ""))))
	var holds: String = PackList.holds(item)
	if holds.is_empty():
		return PackList.line(item, count)
	var holds_name: String = str(DataRegistry.get_item(StringName(holds)).get("name", holds))
	return PackList.line(item, count, holds_name, GameState.item_count(StringName(holds)))


func _ready() -> void:
	hide()


## Opens on `start` (FOOD or PACK), the cursor on its first line.
func open(start: StringName = FOOD) -> void:
	list = start if LISTS.has(start) else FOOD
	selected = 0
	top = 0
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


## Turns to the other list.
func switch_list() -> void:
	list = PACK if list == FOOD else FOOD
	selected = 0
	top = 0
	EventBus.sound.emit(&"menu_move")
	_refresh()


## On Food, eats the highlighted item and closes; returns its id. On Pack, nothing: it is for
## looking only (returns "").
func confirm() -> StringName:
	if list == PACK:
		return &""
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


## The icons of the lines shown, in order (none when it is closed).
func shown_icons() -> Array[StringName]:
	return _icons.icons.duplicate() if visible else ([] as Array[StringName])


## The heading as it reads now: the list's name.
func title_text() -> String:
	return _title.text


## The help line as it reads now.
func help_text() -> String:
	return _help.text


## "[Food]  Pack": the two lists, the one shown in brackets.
func tabs_text() -> String:
	return TAB_GAP.join(tab_parts())


## The two lists' names as they are written, the one shown in brackets.
func tab_parts() -> PackedStringArray:
	var parts: PackedStringArray = []
	for tab: StringName in LISTS:
		parts.append("[%s]" % TAB_NAMES[tab] if tab == list else " %s " % TAB_NAMES[tab])
	return parts


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if MenuInput.is_pointing(event):
		point_at(event)
		return
	if event.is_action_pressed(&"interact") or event.is_action_pressed(&"use_item") or event.is_action_pressed(&"use_hand"):
		# A click on "Food" or "Pack" turns to that list (beside the two names, nothing: it was
		# aimed at them). A click on a line picks that line; on no line, the highlighted one.
		# On Pack a click only points.
		if MenuInput.line_under(_tabs, event, 1) != MenuPointer.NONE:
			var tab: StringName = tab_under(event)
			if tab != &"" and tab != list:
				switch_list()
		else:
			point_at(event)
			confirm()
	elif MenuInput.is_back(event):
		# Tab or Esc, as in every other list: out, and nothing changed.
		close()
	elif MenuInput.is_up(event):
		move_cursor(-1)
	elif MenuInput.is_down(event):
		move_cursor(1)
	elif event.is_action_pressed(&"move_left") or event.is_action_pressed(&"move_right"):
		switch_list()
	else:
		return
	get_viewport().set_input_as_handled()


## Puts the cursor on the line the mouse is on in `event`, if it is on one.
func point_at(event: InputEvent) -> void:
	var line: int = MenuInput.line_under(_list, event, mini(ROWS, items.size() - top), ItemIconColumn.WIDTH)
	if line == MenuPointer.NONE or top + line == selected:
		return
	selected = top + line
	EventBus.sound.emit(&"menu_move")
	_refresh()


## The list whose name the mouse is on in `event` (FOOD or PACK), or "" if it is on neither.
func tab_under(event: InputEvent) -> StringName:
	if MenuInput.line_under(_tabs, event, 1) == MenuPointer.NONE:
		return &""
	var widths: PackedFloat32Array = []
	for part_words: String in tab_parts():
		widths.append(MenuInput.width_of(_tabs, part_words))
	var x: float = (_tabs.make_input_local(event) as InputEventMouse).position.x
	var part: int = MenuPointer.part_at(x, widths, MenuInput.width_of(_tabs, TAB_GAP))
	return LISTS[part] if part != MenuPointer.NONE else &""


func _refresh() -> void:
	items = food_held() if list == FOOD else pack_held()
	selected = clampi(selected, 0, maxi(items.size() - 1, 0))
	top = MenuCursor.window_top(top, selected, items.size(), ROWS)
	var lines: PackedStringArray = []
	var ids: Array = []
	for i: int in range(top, mini(top + ROWS, items.size())):
		var words: String = describe(items[i]) if list == FOOD else pack_line(items[i])
		lines.append((CURSOR if i == selected else "  ") + words)
		ids.append(str(items[i].get("id", "")))
	if items.is_empty():
		lines.append(NOTHING_TO_EAT if list == FOOD else NOTHING_CARRIED)
	_title.text = TAB_NAMES[list]
	_tabs.text = tabs_text()
	_help.text = HELP[list]
	_list.text = "\n".join(lines)
	_icons.show_icons(ItemIconColumn.icons_of(ids), MenuInput.line_height(_list))
	_count.text = MenuCursor.count_text(top, selected, items.size(), ROWS)
