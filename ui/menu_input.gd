class_name MenuInput
extends RefCounted
## Which menu key an input event is (docs/TECH_DESIGN.md §12), shared by every menu: the
## movement keys go up and down, E / Enter / A picks, Esc / Start / Tab backs out.


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
