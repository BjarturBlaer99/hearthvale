class_name ToolFlash
extends Node2D
## A tool at work (P3): its picture over the cell it works for a moment, dipping to the ground
## and lifting again, then gone. For show only: the work is done the moment the tool is used.
## Position = the cell's top-left corner.

## How far above the cell the tool starts and ends (px).
const LIFT: float = 6.0

var icon: StringName = &"gem"
var time: float = 0.3
var _left: float = 0.3


## Shows `tool_icon` (an ItemIcons frame) over the cell at `at` (area px) for `seconds`.
static func spawn(parent: Node, at: Vector2, tool_icon: StringName, seconds: float) -> ToolFlash:
	var flash: ToolFlash = ToolFlash.new()
	flash.position = at
	flash.icon = tool_icon
	flash.time = maxf(seconds, 0.05)
	flash._left = flash.time
	# Drawn with whatever stands on the row below it, so it shows over the soil and the hero's feet.
	flash.z_index = 1
	parent.add_child(flash)
	return flash


## How high the tool is now (px above the cell): down to the ground by the middle, up again.
func height() -> float:
	var through: float = 1.0 - clampf(_left / time, 0.0, 1.0)
	return LIFT * absf(1.0 - through * 2.0)


func _process(delta: float) -> void:
	_left -= delta
	if _left <= 0.0:
		queue_free()
		return
	queue_redraw()


func _draw() -> void:
	ItemIcons.draw(self, icon, Vector2(0.0, -roundf(height())))
