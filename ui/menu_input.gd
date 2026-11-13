class_name MenuInput
extends RefCounted
## Which menu key an input event is (docs/TECH_DESIGN.md §12), shared by every menu: the
## movement keys go up and down, a click / Enter / A picks, Esc / Start / Tab backs out.
## Interact is the left mouse button (since 2026-11-13). It is a button, not a pointer: no
## part of the screen is clicked on, so nothing on screen may take the click for itself
## (let_clicks_through).

## What the interact button is called on screen: "[Click] Pick up the Hoe".
const INTERACT_KEY: String = "Click"


## "[Click] Open the door": the HUD's prompt for what interact would do here.
static func prompt(what: String) -> String:
	return "[%s] %s" % [INTERACT_KEY, what]


## Makes everything on a screen ignore the mouse, so a click anywhere reaches the game as the
## interact action. Called by each screen as it starts (the HUD, the title, the ending); a
## Control would otherwise swallow a click that lands on it.
static func let_clicks_through(root: Node) -> void:
	if root is Control:
		(root as Control).mouse_filter = Control.MOUSE_FILTER_IGNORE
	for child: Node in root.get_children():
		let_clicks_through(child)


static func is_up(event: InputEvent) -> bool:
	return event.is_action_pressed(&"move_up")


static func is_down(event: InputEvent) -> bool:
	return event.is_action_pressed(&"move_down")


static func is_confirm(event: InputEvent) -> bool:
	return event.is_action_pressed(&"interact") or event.is_action_pressed(&"ui_accept")


## Answering a conversation: as is_confirm, but not with the attack key (Space is both), so
## swinging as the words open doesn't skip them.
static func is_answer(event: InputEvent) -> bool:
	if event.is_action_pressed(&"interact"):
		return true
	return event.is_action_pressed(&"ui_accept") and not event.is_action(&"attack")


static func is_back(event: InputEvent) -> bool:
	return event.is_action_pressed(&"pause") or event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"item_menu")
