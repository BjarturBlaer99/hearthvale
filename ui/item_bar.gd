class_name ItemBar
extends Control
## The bar at the bottom of the screen (the user's request, 2026-11-15): a slot for each thing
## that can be in the hero's hand, his sword first, then the bow, bombs, tools and seeds in the
## order he picked them up. The slot in hand is lit: it is what the left click uses. A slot
## shows how many it has left to use (arrows, bombs, seeds, pours in the can). The mouse wheel
## steps through the slots and the keys 1 to 9 choose one; the area does that (GameState's
## hand), and tells this what to show. HandBar (pure) says what is in the bar and in what
## order; this only draws it. With more than HandBar.SLOTS things it shows that many and moves
## along with the one in hand, with a mark at the end where there is more. For show only: it
## takes no clicks. (BuildBarView is this bar with other things in it: build mode's.)

## A slot's side (px): a 16 px picture with a two-pixel rim.
const SLOT: int = 20
const GAP: int = 2
## How far the bar sits from the bottom of the screen (px).
const MARGIN: int = 4
## The Ninja Adventure pack's inventory cell (the farm look's phase C): grey-green in a dark rim,
## the one in hand lighter and rimmed in the orange of its focus mark.
const BACK: Color = Color(Color("8d977f"), 0.9)
const EDGE: Color = Color("46402e")
const LIT_BACK: Color = Color(Color("abc2bc"), 0.95)
const LIT_EDGE: Color = Color("ffad55")
const COUNT: Color = Color(1.0, 1.0, 1.0)
const COUNT_SHADE: Color = Color(0.05, 0.03, 0.09, 0.95)
const MORE: Color = Color("ffad55")
const FONT_SIZE: int = 8

## What can be in hand (item data entries, HandBar's order), which of them is (HandBar.NONE:
## none), and the first one showing.
var entries: Array[Dictionary] = []
var selected: int = HandBar.NONE
var top: int = 0

## What was last drawn, in words: it is drawn again only when that changes.
var _drawn: String = ""


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Shows `held` (HandBar.entries) with entry `in_hand` lit, in the middle of the bottom of the
## screen. The bar keeps the one in hand in view.
func show_hand(held: Array[Dictionary], in_hand: int) -> void:
	entries = held
	selected = in_hand
	top = HandBar.first_shown(top, selected, entries.size())
	var shown: int = shown_count()
	size = Vector2(shown * SLOT + maxi(shown - 1, 0) * GAP, SLOT)
	var view: Vector2 = get_viewport_rect().size
	position = Vector2(roundf((view.x - size.x) / 2.0), view.y - float(SLOT + MARGIN))
	var state: String = "%d|%d|%d|%s|%s" % [selected, top, entries.size(), ",".join(PackedStringArray(shown_ids())), ",".join(shown_counts())]
	if state != _drawn:
		_drawn = state
		queue_redraw()


## How many slots show now.
func shown_count() -> int:
	return clampi(entries.size() - top, 0, HandBar.SLOTS)


## The item in each slot showing, left to right.
func shown_ids() -> Array[StringName]:
	var out: Array[StringName] = []
	for slot: int in shown_count():
		out.append(StringName(str(entries[top + slot].get("id", ""))))
	return out


## The number each slot showing has ("" for what uses nothing up), left to right.
func shown_counts() -> PackedStringArray:
	var out: PackedStringArray = []
	for slot: int in shown_count():
		out.append(count_of(entries[top + slot]))
	return out


## The picture of `entry` (one of `entries`).
func icon_of(entry: Dictionary) -> StringName:
	return ItemIcons.name_for(StringName(str(entry.get("id", ""))))


## The number `entry`'s slot shows ("" for none): how many it has left to use.
func count_of(entry: Dictionary) -> String:
	return HandBar.count_text(entry, GameState.item_count)


## Which of the slots showing is lit (0 is the leftmost), or HandBar.NONE.
func lit_slot() -> int:
	return selected - top if selected >= top and selected < top + shown_count() else HandBar.NONE


## Where slot `slot` is drawn, from the bar's top-left corner.
func slot_rect(slot: int) -> Rect2:
	return Rect2(Vector2(slot * (SLOT + GAP), 0), Vector2(SLOT, SLOT))


## Whether there are entries before the first slot showing, and after the last.
func more_before() -> bool:
	return top > 0


func more_after() -> bool:
	return top + shown_count() < entries.size()


func _draw() -> void:
	var font: Font = get_theme_default_font()
	var counts: PackedStringArray = shown_counts()
	for slot: int in shown_count():
		var rect: Rect2 = slot_rect(slot)
		var lit: bool = slot == lit_slot()
		draw_rect(rect, LIT_BACK if lit else BACK)
		_draw_edge(rect, LIT_EDGE if lit else EDGE)
		ItemIcons.draw(self, icon_of(entries[top + slot]), rect.position + Vector2(2, 2))
		if not counts[slot].is_empty():
			var at: Vector2 = Vector2(rect.position.x, rect.end.y - 2.0 - font.get_descent(FONT_SIZE))
			draw_string(font, at + Vector2(0, 1), counts[slot], HORIZONTAL_ALIGNMENT_RIGHT, SLOT - 1.0, FONT_SIZE, COUNT_SHADE)
			draw_string(font, at + Vector2(-1, 0), counts[slot], HORIZONTAL_ALIGNMENT_RIGHT, SLOT - 1.0, FONT_SIZE, COUNT)
	# A small arrow at an end where the bar goes on.
	if more_before():
		_draw_arrow(Vector2(-6.0, SLOT / 2.0), -1.0)
	if more_after():
		_draw_arrow(Vector2(size.x + 5.0, SLOT / 2.0), 1.0)


## A one-pixel rim just inside `rect`.
func _draw_edge(rect: Rect2, colour: Color) -> void:
	draw_rect(Rect2(rect.position, Vector2(rect.size.x, 1.0)), colour)
	draw_rect(Rect2(Vector2(rect.position.x, rect.end.y - 1.0), Vector2(rect.size.x, 1.0)), colour)
	draw_rect(Rect2(rect.position + Vector2(0.0, 1.0), Vector2(1.0, rect.size.y - 2.0)), colour)
	draw_rect(Rect2(Vector2(rect.end.x - 1.0, rect.position.y + 1.0), Vector2(1.0, rect.size.y - 2.0)), colour)


## A little arrowhead at `tip`, pointing left (`way` -1) or right (1): three columns of pixels.
func _draw_arrow(tip: Vector2, way: float) -> void:
	for column: int in 3:
		var half: float = float(column)
		draw_rect(Rect2(Vector2(tip.x - way * float(column), tip.y - half - 0.5).floor(), Vector2(1.0, half * 2.0 + 1.0)), MORE)
