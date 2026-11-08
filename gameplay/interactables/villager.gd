class_name Villager
extends Talkable
## A villager who stands in one spot and talks. Their name comes from their conversation (the
## start node's speaker, through the dialogue's "speakers" map). Placeholder art: a robed
## figure drawn in code, feet in the middle of the cell like the hero's, head above the cell.

const OUTLINE: Color = Color(0.10, 0.08, 0.12)
const SKIN: Color = Color(0.93, 0.76, 0.60)
## How far the figure is drawn up from the bottom of its cell, so its feet are mid-cell.
const LIFT: float = 5.0

@export var robe_color: Color = Color(0.45, 0.35, 0.60)
@export var hair_color: Color = Color(0.35, 0.22, 0.12)
@export var beard: bool = false


func display_name() -> String:
	var data: Dictionary = dialogue()
	var nodes: Variant = data.get("nodes", {})
	var start: Variant = (nodes as Dictionary).get(str(data.get("start", "")), {}) if typeof(nodes) == TYPE_DICTIONARY else {}
	var speaker: String = str((start as Dictionary).get("speaker", "")) if typeof(start) == TYPE_DICTIONARY else ""
	var shown: String = DialogueRunner.speaker_name_of(data, speaker)
	return shown if not shown.is_empty() else String(name)


func prompt() -> String:
	return "Talk to %s" % display_name()


func _draw() -> void:
	draw_set_transform(Vector2(0.0, -LIFT))
	_ellipse(Vector2(8, 13), Vector2(6, 2.5), Color(0, 0, 0, 0.35))
	# Robe, belt and sleeves.
	var robe: PackedVector2Array = [Vector2(2, 14), Vector2(14, 14), Vector2(12, 1), Vector2(4, 1)]
	draw_colored_polygon(robe, OUTLINE)
	draw_colored_polygon(PackedVector2Array([Vector2(3, 13), Vector2(13, 13), Vector2(11, 2), Vector2(5, 2)]), robe_color)
	draw_rect(Rect2(4, 7, 8, 1), robe_color.darkened(0.35))
	draw_rect(Rect2(2, 4, 2, 5), robe_color.darkened(0.15))
	draw_rect(Rect2(12, 4, 2, 5), robe_color.darkened(0.15))
	# Head: outline, hair, face, eyes.
	draw_circle(Vector2(8, -3), 5.0, OUTLINE)
	draw_circle(Vector2(8, -3), 4.0, hair_color)
	draw_rect(Rect2(5, -3, 6, 4), SKIN)
	draw_rect(Rect2(6, -2, 1, 1), OUTLINE)
	draw_rect(Rect2(9, -2, 1, 1), OUTLINE)
	if beard:
		draw_colored_polygon(PackedVector2Array([Vector2(5, 0), Vector2(11, 0), Vector2(8, 5)]), hair_color)


func _ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points: PackedVector2Array = []
	for i: int in 16:
		var angle: float = TAU * i / 16.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)
