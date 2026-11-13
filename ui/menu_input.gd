class_name MenuInput
extends RefCounted
## Which menu key an input event is (docs/TECH_DESIGN.md §12), shared by every menu: the
## movement keys go up and down, a click / Enter / A picks, Esc / Start / Tab backs out.
## The mouse (since 2026-11-13): the right button is interact, the left uses what is in hand.
## They are buttons, not a pointer: no part of the screen is clicked on, so nothing on screen
## may take a click for itself (let_clicks_through).

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


static func is_up(event: InputEvent) -> bool:
	return event.is_action_pressed(&"move_up")


static func is_down(event: InputEvent) -> bool:
	return event.is_action_pressed(&"move_down")


## A menu's yes: either mouse button, Enter, or A on a pad.
static func is_confirm(event: InputEvent) -> bool:
	return event.is_action_pressed(&"interact") or event.is_action_pressed(&"use_hand") or event.is_action_pressed(&"ui_accept")


## Answering a conversation: interact (the right mouse button) or Enter, but nothing that
## swings the sword (Space is both; so is the left mouse button), so swinging as the words
## open doesn't skip them.
static func is_answer(event: InputEvent) -> bool:
	if event.is_action_pressed(&"interact"):
		return true
	return event.is_action_pressed(&"ui_accept") and not event.is_action(&"attack")


static func is_back(event: InputEvent) -> bool:
	return event.is_action_pressed(&"pause") or event.is_action_pressed(&"ui_cancel") or event.is_action_pressed(&"item_menu")
