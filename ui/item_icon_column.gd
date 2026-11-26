class_name ItemIconColumn
extends Control
## The pictures beside a list's lines (icons, an axe and the item bar, step I1): a column at the
## left of a list Label, a 16x16 icon (ItemIcons) at the top of each line the list shows, one
## line_height apart, so the pictures scroll with the words. The menu tells it the icons of the
## lines it shows, from its first shown line to its last (`show_icons`); a line with no picture
## (the empty list's words) is &"". It only draws: it takes no clicks, and the list Label beside it
## is still what the pointer measures.

## The side of a picture, and the room it takes beside the words (the picture and two pixels).
const SIZE: int = 16
const WIDTH: int = SIZE + 2

## The icons of the lines shown, in order (&"" for a line without one).
var icons: Array[StringName] = []
## How far apart the lines are (MenuInput.line_height of the list).
var line_height: float = float(SIZE)


## The icon name of each item in `item_ids`, in order (ItemIcons.name_for).
static func icons_of(item_ids: Array) -> Array[StringName]:
	var named: Array[StringName] = []
	for item_id: Variant in item_ids:
		named.append(ItemIcons.name_for(StringName(str(item_id))))
	return named


func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE


## Shows `shown` (one icon per line shown, from the top) with the lines `height` apart.
func show_icons(shown: Array[StringName], height: float) -> void:
	icons = shown.duplicate()
	line_height = height
	queue_redraw()


func _draw() -> void:
	for i: int in icons.size():
		if icons[i] != &"":
			ItemIcons.draw(self, icons[i], Vector2(0.0, roundf(float(i) * line_height)))
