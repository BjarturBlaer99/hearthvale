class_name ForageSpot
extends ItemPickup
## Something to gather that grows back (P2d, GDD §6): wild berries, mushrooms, fallen cherry
## blossom. Stand on it and press interact, as for any item lying in the world; it is gone for
## the day and back the next morning. `taken_flag` remembers the day it was last gathered.
## It lies on the ground and blocks nothing. Position = the cell's top-left corner.

const SHEET: Texture2D = preload("res://gameplay/art/forage.png")
## Frames in the order the tool paints them (a test checks).
const FRAMES: Dictionary = {
	&"berries": 0, &"berries_picked": 1, &"mushrooms": 2, &"mushrooms_picked": 3,
	&"blossoms": 4, &"blossoms_picked": 5,
}
const SIZE: Vector2i = Vector2i(16, 16)

## Which picture it shows: &"berries", &"mushrooms" or &"blossoms".
@export var kind: StringName = &"berries"


func _ready() -> void:
	EventBus.day_started.connect(_on_day_started)


## Gathered today: there is nothing here until tomorrow.
func taken() -> bool:
	return int(GameState.get_flag(taken_flag, 0)) >= GameState.day


## Gathers it. Returns false if it was already gathered today, or there is no room for it (it
## stays on the bush).
func take() -> bool:
	if taken() or not has_room():
		return false
	GameState.add_item(item_id, count)
	GameState.set_flag(taken_flag, GameState.day)
	EventBus.sound.emit(&"item_get")
	Burst.spawn(get_parent(), position + Vector2(8, 8), &"leaves")
	queue_redraw()
	return true


## The frame it shows now.
func frame() -> StringName:
	return StringName(String(kind) + "_picked") if taken() else kind


func _draw() -> void:
	SpriteSheet.draw(self, SHEET, FRAMES[frame()], SIZE, Vector2.ZERO)


func _on_day_started(_day: int) -> void:
	queue_redraw()
