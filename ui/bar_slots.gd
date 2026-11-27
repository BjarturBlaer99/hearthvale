class_name BarSlots
extends Control
## The slots of the screen that arranges the item bar (step B2): the bar's columns in rows of
## nine, the first row numbered 1 to 9 as the keys choose them in play, drawn as the bar's slots
## are (ItemBar's colours: an empty one is its rim alone). The slot under the cursor is lit;
## a lifted thing rises over the slot under the cursor, and the slot it came from stays marked
## with its picture faint. BarMenu tells it what to show and asks it which slot a point is on.
## For show only: BarMenu reads the input.

## A slot's side and the gap between slots (px), as on the bar in play but wider apart.
const SLOT: int = ItemBar.SLOT
const GAP: int = 4
## The band over the first row where its numbers stand (px).
const NUMBERS: int = 12
## How far a lifted thing rises over its slot (px).
const RISE: float = 5.0
const NUMBER: Color = Color(0.7, 0.7, 0.65)
## The slot a lifted thing came from: its rim, and how faint its picture stays.
const FROM_EDGE: Color = PanelFrame.GOLD
## How much of a faint picture shows through.
const FAINT: Color = Color(1.0, 1.0, 1.0, 0.35)
const FONT_SIZE: int = 8

## Each slot's entry (HandBar's columns, {} for an empty one; as many as the screen shows), the
## slot under the cursor, the one lifted (BarCursor.NONE: none), and each slot's number.
var entries: Array[Dictionary] = []
var cursor: int = 0
var lifted: int = BarCursor.NONE
var counts: PackedStringArray = []


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Shows `shown` (an entry a slot), the cursor on `at` and slot `from` lifted; `numbers` are
## what each slot's number says.
func show_slots(shown: Array[Dictionary], at: int, from: int, numbers: PackedStringArray) -> void:
	entries = shown
	cursor = at
	lifted = from
	counts = numbers
	var rows: int = maxi(1, ceili(float(entries.size()) / float(BarCursor.COLUMNS)))
	custom_minimum_size = Vector2(width(), NUMBERS + rows * SLOT + (rows - 1) * GAP)
	size = custom_minimum_size
	queue_redraw()


## How wide a row of slots is (px).
static func width() -> float:
	return float(BarCursor.COLUMNS * SLOT + (BarCursor.COLUMNS - 1) * GAP)


## Where slot `index` is drawn, from the top-left corner.
func slot_rect(index: int) -> Rect2:
	var column: int = index % BarCursor.COLUMNS
	@warning_ignore("integer_division")
	var row: int = index / BarCursor.COLUMNS
	return Rect2(Vector2(column * (SLOT + GAP), NUMBERS + row * (SLOT + GAP)), Vector2(SLOT, SLOT))


## Which slot the point `local` (from the top-left corner) is on, or BarCursor.NONE.
func slot_at(local: Vector2) -> int:
	return MenuPointer.cell_at(local - Vector2(0, NUMBERS), Vector2(SLOT, SLOT), float(GAP), BarCursor.COLUMNS, entries.size())


func _draw() -> void:
	var font: Font = get_theme_default_font()
	for column: int in BarCursor.COLUMNS:
		var under: Rect2 = slot_rect(column)
		draw_string(font, Vector2(under.position.x, NUMBERS - 3.0), str(column + 1), HORIZONTAL_ALIGNMENT_CENTER, SLOT, FONT_SIZE, NUMBER)
	for index: int in entries.size():
		var rect: Rect2 = slot_rect(index)
		var lit: bool = index == cursor
		draw_rect(rect, ItemBar.LIT_BACK if lit else ItemBar.BACK)
		_draw_edge(rect, FROM_EDGE if index == lifted else (ItemBar.LIT_EDGE if lit else ItemBar.EDGE))
		if entries[index].is_empty():
			continue
		var icon: StringName = ItemIcons.name_for(StringName(str(entries[index].get("id", ""))))
		if index == lifted:
			# Where it came from: its picture faint until it is set down.
			_draw_icon_faint(icon, rect.position + Vector2(2, 2))
			continue
		ItemIcons.draw(self, icon, rect.position + Vector2(2, 2))
		if index < counts.size() and not counts[index].is_empty():
			var at: Vector2 = Vector2(rect.position.x, rect.end.y - 2.0 - font.get_descent(FONT_SIZE))
			draw_string(font, at + Vector2(0, 1), counts[index], HORIZONTAL_ALIGNMENT_RIGHT, SLOT - 1.0, FONT_SIZE, ItemBar.COUNT_SHADE)
			draw_string(font, at + Vector2(-1, 0), counts[index], HORIZONTAL_ALIGNMENT_RIGHT, SLOT - 1.0, FONT_SIZE, ItemBar.COUNT)
	# The lifted thing, risen over the slot under the cursor: where it would be set down.
	if lifted >= 0 and lifted < entries.size() and cursor >= 0 and cursor < entries.size():
		var over: Rect2 = slot_rect(cursor)
		var lifted_icon: StringName = ItemIcons.name_for(StringName(str(entries[lifted].get("id", ""))))
		ItemIcons.draw(self, lifted_icon, over.position + Vector2(2.0, 2.0 - RISE))


## A picture drawn faint: the icon, then the slot's own colour over it, most of the way.
func _draw_icon_faint(icon: StringName, origin: Vector2) -> void:
	ItemIcons.draw(self, icon, origin)
	draw_rect(Rect2(origin, Vector2(ItemIcons.SIZE)), Color(ItemBar.BACK, 1.0 - FAINT.a))


## A one-pixel rim just inside `rect`.
func _draw_edge(rect: Rect2, colour: Color) -> void:
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 1.0)), colour)
	draw_rect(Rect2(Vector2(rect.position.x, rect.end.y - 1.0), Vector2(rect.size.x, 1.0)), colour)
	draw_rect(Rect2(rect.position + Vector2(0.0, 1.0), Vector2(1.0, rect.size.y - 2.0)), colour)
	draw_rect(Rect2(Vector2(rect.end.x - 1.0, rect.position.y + 1.0), Vector2(1.0, rect.size.y - 2.0)), colour)
