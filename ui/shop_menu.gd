class_name ShopMenu
extends Control
## A shop's counter (P3c, GDD §9): two lists, what the shop sells and what it buys of what the
## hero carries, with his coins beside them. Up and down move the cursor; left and right turn
## from one list to the other; a click or Enter makes the deal under the cursor; Tab or Esc
## leaves. The mouse points: at a line to put the cursor there, and a click on "Buy" or "Sell"
## turns to that list. It stays open for as many deals as he likes, and a line says what the last one was,
## or why it couldn't be made. Shop (pure) says what is on the lists and what a deal needs;
## GameState makes it. The area opens it (a conversation's `shop` effect) and keeps the hero
## still while it is open. Each line has its picture beside it (ItemIconColumn): the item's, or
## an animal's own (Herd.icon_of).

signal closed

const CURSOR: String = "> "
## How many lines the box has room for.
const ROWS: int = 5
const NOTHING_TO_BUY: String = "She has nothing to sell today."
const NOTHING_TO_SELL: String = "You carry nothing she buys."
const BOUGHT_WORDS: String = "Bought: %s."
## An animal bought (Farmer Oda's stall): its name, and the building it is in now.
const ANIMAL_BOUGHT_WORDS: String = "Bought: a %s. It is in your %s."
const SOLD_WORDS: String = "Sold: %s, for %s."
## The two lists as their tabs name them.
const TAB_NAMES: Dictionary = {Shop.BUY: "Buy", Shop.SELL: "Sell"}
## What stands between the two names.
const TAB_GAP: String = "  "

var shop: Dictionary = {}
var mode: StringName = Shop.BUY
var selected: int = 0
## The first entry shown.
var top: int = 0

@onready var _title: Label = $Panel/Title
@onready var _tabs: Label = $Panel/Tabs
@onready var _coins: Label = $Panel/Coins
@onready var _list: Label = $Panel/List
@onready var _icons: ItemIconColumn = $Panel/Icons
@onready var _note: Label = $Panel/Note
@onready var _count: Label = $Panel/Count


func _ready() -> void:
	hide()


## Shows `shop_data` (a data entry) on its `start` list (Shop.BUY or Shop.SELL).
func open(shop_data: Dictionary, start: StringName = Shop.BUY) -> void:
	shop = shop_data
	mode = start if Shop.MODES.has(start) else Shop.BUY
	selected = 0
	top = 0
	_note.text = ""
	show()
	_refresh()


func is_open() -> bool:
	return visible


## What is on the list he is looking at: wares to buy, or his harvest to sell (Shop's entries).
func entries() -> Array[Dictionary]:
	var crops: Array = DataRegistry.entries(&"crops")
	if mode == Shop.SELL:
		return Shop.offers(shop, crops, GameState.inventory)
	return Shop.wares(shop, crops)


func move_cursor(step: int) -> void:
	var count: int = entries().size()
	if count == 0:
		return
	selected = wrapi(selected + step, 0, count)
	EventBus.sound.emit(&"menu_move")
	_refresh()


## Turns to the other list.
func switch_mode() -> void:
	mode = Shop.SELL if mode == Shop.BUY else Shop.BUY
	selected = 0
	top = 0
	_note.text = ""
	EventBus.sound.emit(&"menu_move")
	_refresh()


## Makes the deal under the cursor: buys the ware, or sells one of the harvest. Returns whether
## it was made; the note says what was bought or sold, or why not.
func confirm() -> bool:
	var list: Array[Dictionary] = entries()
	if list.is_empty():
		return false
	var entry: Dictionary = list[clampi(selected, 0, list.size() - 1)]
	var item_name: String = _name_of(entry)
	var why_not: String = GameState.sell(entry) if mode == Shop.SELL else GameState.buy(entry)
	if not why_not.is_empty():
		EventBus.sound.emit(&"nope")
		_note.text = why_not
	elif mode == Shop.SELL:
		EventBus.sound.emit(&"coin")
		_note.text = SOLD_WORDS % [item_name, Shop.coins_text(int(entry["price"]))]
	elif Shop.is_animal(entry):
		EventBus.sound.emit(&"coin")
		var home: StringName = Herd.lives_in(DataRegistry.get_animal(StringName(str(entry["animal"]))))
		_note.text = ANIMAL_BOUGHT_WORDS % [item_name.to_lower(), Buildings.name_of(DataRegistry.get_building(home), GameState.is_big(home))]
	else:
		EventBus.sound.emit(&"coin")
		_note.text = BOUGHT_WORDS % (item_name if int(entry["count"]) == 1 else "%s x%d" % [item_name, int(entry["count"])])
	_refresh()
	return why_not.is_empty()


func close() -> void:
	if not visible:
		return
	hide()
	closed.emit()


func shown_lines() -> PackedStringArray:
	return _list.text.split("\n") if visible else PackedStringArray()


## The icons of the lines shown, in order (none when it is closed or the list is empty).
func shown_icons() -> Array[StringName]:
	return _icons.icons.duplicate() if visible else ([] as Array[StringName])


## The picture of `entry`, a ware or an offer: its item's, or its animal's.
static func icon_of(entry: Dictionary) -> StringName:
	if Shop.is_animal(entry):
		var icon: StringName = Herd.icon_of(DataRegistry.get_animal(StringName(str(entry["animal"]))))
		return icon if ItemIcons.has(icon) else &"gem"
	return ItemIcons.name_for(StringName(str(entry["item"])))


func note_text() -> String:
	return _note.text


## "[Buy]   Sell": the two lists, the one shown in brackets.
func tabs_text() -> String:
	return TAB_GAP.join(tab_parts())


## The two lists' names as they are written, the one shown in brackets.
func tab_parts() -> PackedStringArray:
	var parts: PackedStringArray = []
	for tab: StringName in Shop.MODES:
		parts.append("[%s]" % TAB_NAMES[tab] if tab == mode else " %s " % TAB_NAMES[tab])
	return parts


func _unhandled_input(event: InputEvent) -> void:
	if not visible:
		return
	if MenuInput.is_pointing(event):
		point_at(event)
		return
	if MenuInput.is_confirm(event):
		# A click on "Buy" or "Sell" turns to that list; a click on a line makes that deal; on
		# neither, the deal under the cursor.
		# (A click beside the two names does nothing: it was aimed at them.)
		if MenuInput.line_under(_tabs, event, 1) != MenuPointer.NONE:
			var tab: StringName = tab_under(event)
			if tab != &"" and tab != mode:
				switch_mode()
		else:
			point_at(event)
			confirm()
	elif MenuInput.is_back(event):
		close()
	elif MenuInput.is_up(event):
		move_cursor(-1)
	elif MenuInput.is_down(event):
		move_cursor(1)
	elif event.is_action_pressed(&"move_left") or event.is_action_pressed(&"move_right"):
		switch_mode()
	else:
		return
	get_viewport().set_input_as_handled()


## Puts the cursor on the line the mouse is on in `event`, if it is on one.
func point_at(event: InputEvent) -> void:
	var line: int = MenuInput.line_under(_list, event, mini(ROWS, entries().size() - top), ItemIconColumn.WIDTH)
	if line == MenuPointer.NONE or top + line == selected:
		return
	selected = top + line
	EventBus.sound.emit(&"menu_move")
	_refresh()


## The list whose name the mouse is on in `event` (Shop.BUY or Shop.SELL), or "" if it is on
## neither.
func tab_under(event: InputEvent) -> StringName:
	if MenuInput.line_under(_tabs, event, 1) == MenuPointer.NONE:
		return &""
	var widths: PackedFloat32Array = []
	for part_words: String in tab_parts():
		widths.append(MenuInput.width_of(_tabs, part_words))
	var x: float = (_tabs.make_input_local(event) as InputEventMouse).position.x
	var part: int = MenuPointer.part_at(x, widths, MenuInput.width_of(_tabs, TAB_GAP))
	return Shop.MODES[part] if part != MenuPointer.NONE else &""


func _name_of(entry: Dictionary) -> String:
	if Shop.is_animal(entry):
		return Herd.name_of(DataRegistry.get_animal(StringName(str(entry["animal"]))))
	return str(DataRegistry.get_item(StringName(str(entry["item"]))).get("name", entry["item"]))


func _refresh() -> void:
	var list: Array[Dictionary] = entries()
	# A sale can empty a line: the cursor stays on the list.
	selected = clampi(selected, 0, maxi(list.size() - 1, 0))
	top = MenuCursor.window_top(top, selected, list.size(), ROWS)
	var lines: PackedStringArray = []
	var icons: Array[StringName] = []
	for i: int in range(top, mini(top + ROWS, list.size())):
		icons.append(icon_of(list[i]))
		var words: String = Shop.offer_line(list[i], _name_of(list[i])) if mode == Shop.SELL else Shop.ware_line(list[i], _name_of(list[i]))
		lines.append((CURSOR if i == selected else "  ") + words)
	if list.is_empty():
		lines.append(NOTHING_TO_SELL if mode == Shop.SELL else NOTHING_TO_BUY)
	_title.text = str(shop.get("name", "Shop"))
	_tabs.text = tabs_text()
	_coins.text = Shop.coins_text(GameState.item_count(GameState.COIN))
	_list.text = "\n".join(lines)
	_icons.show_icons(icons, MenuInput.line_height(_list))
	_count.text = MenuCursor.count_text(top, selected, list.size(), ROWS)
