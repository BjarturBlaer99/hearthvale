class_name HeldTool
extends Sprite2D
## The tool in the hero's hands while he works (tool polish, 2026-11-19): a frame of
## HeldTools.SHEET laid over his work pose from his feet, mirrored with him (in place: a frame's
## feet are in its middle). For show only: it hits nothing and blocks nothing. PlayerController
## shows it, and puts it behind him when he faces up.

## The frame shown, or -1 while nothing is in his hands.
var frame_index: int = -1


func _init() -> void:
	name = "HeldTool"
	texture = HeldTools.SHEET
	centered = false
	region_enabled = true
	position = -Vector2(HeldTools.FEET)
	visible = false


## Shows `frame` (HeldTools), mirrored when `flipped`; -1 hides it.
func show_frame(frame: int, flipped: bool) -> void:
	frame_index = frame
	visible = frame >= 0
	if frame < 0:
		return
	region_rect = HeldTools.region_of(frame)
	flip_h = flipped
