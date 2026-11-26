class_name MenuInput
extends RefCounted
## Which menu key an input event is (docs/TECH_DESIGN.md §12), shared by every menu: the
## movement keys and the mouse wheel go up and down, a click / Enter / A picks, Esc / Start /
## Tab backs out.
## The mouse in play (since 2026-11-13): the right button is interact, the left uses what is in
## hand. There they are buttons, not a pointer: the hero works what he faces.
## The mouse in menus (since 2026-11-15): it points. The line under it is highlighted
## (line_under, MenuPointer) and a click on a line chooses that line; a click on no line does
## what it always did, choosing the highlighted one. Menus read input in _unhandled_input, so
## nothing on screen may take a click for itself (let_clicks_through).

## What the interact button is called on screen: "[Right click] Pick up the Hoe".
const INTERACT_KEY: String = "Right click"


## "[Right click] Open the door": the HUD's prompt for what interact would do here.
static func prompt(what: String) -> String:
	return "[%s] %s" % [INTERACT_KEY, what]


## Makes everything on a screen ignore the mouse, so a click anywhere reaches the game as its
## action. Called by each screen as it starts (the HUD, the title, the ending); a
## Control would otherwise swallow a click that lands on it.
static func let_clicks_through(root: Node) -> void:
	if root is Control:
		(root as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child: Node in root.get_children():
		let_clicks_through(child)


## Up a line: the movement keys, or the mouse wheel rolled up.
static func is_up(event: InputEvent) -> bool:
	return event.is_action_pressed(&"move_up") or event.is_action_pressed(&"slot_previous")


## Down a line: the movement keys, or the mouse wheel rolled down.
static func is_down(event: InputEvent) -> bool:
	return event.is_action_pressed(&"move_down") or event.is_action_pressed(&"slot_next")


## Whether `event` is the mouse moving: it may point at another line now.
static func is_pointing(event: InputEvent) -> bool:
	return event is InputEventMouseMotion


## The height of one line of `label`'s words (px).
static func line_height(label: Label) -> float:
	return float(label.get_line_height() + label.get_theme_constant(&"line_spacing"))


## Which line of `label` the mouse is on in `event` (the mouse moving, or one of its buttons):
## 0 for the first of the `lines` it shows, or MenuPointer.NONE if it is on none of them, the
## list isn't showing, or `event` isn't the mouse's. `lead` widens each line that far to the
## left of the label: a list with its pictures beside it (ItemIconColumn.WIDTH) is pointed at on
## a picture too.
static func line_under(label: Label, event: InputEvent, lines: int, lead: float = 0.0) -> int:
	if not event is InputEventMouse or label == null or not label.is_visible_in_tree():
		return MenuPointer.NONE
	var local: Vector2 = (label.make_input_local(event) as InputEventMouse).position + Vector2(lead, 0.0)
	return MenuPointer.line_at(local, label.size.x + lead, line_height(label), lines)


## How wide `words` are in `label`'s own face (px).
static func width_of(label: Label, words: String) -> float:
	return label.get_theme_font(&"font").get_string_size(words, HORIZONTAL_ALIGNMENT_LEFT, -1.0, label.get_theme_font_size(&"font_size")).x


## A menu's yes: either mouse button, Enter, or A on a pad.
static func is_confirm(event: InputEvent) -> bool:
	return event.is_action_pressed(&"interact") or event.is_action_pressed(&"use_hand") or event.is_action_pressed(&"ui_accept")


## What the button that answers a conversation is called on screen.
const ANSWER_KEY: String = "Left click"


## Answering a conversation: the left mouse button (the user's request, 2026-11-13), Enter, or
## A on a pad. Not the right mouse button, which starts conversations, and not Space, which
## only swings the sword. The left button swings it too, so the box that asks waits a moment
## after its words appear (DialogueBox.SWING_GRACE).
static func is_answer(event: InputEvent) -> bool:
	if event.is_action_pressed(&"use_hand"):
		return true
	if event.is_action_pressed(&"interact"):
		return not event is InputEventMouseButton
	return event.is_action_pressed(&"ui_accept") and not event.is_action(&"attack")


static func is_back(event: InputEvent) -> bool:
	return event.is_action_pressed(&"pause") or event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"item_menu")
