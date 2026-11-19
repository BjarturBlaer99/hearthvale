class_name Villager
extends Talkable
## A villager who stands in one spot and talks. Their name comes from their conversation (the
## start node's speaker, through the dialogue's "speakers" map). Pixel art
## (gameplay/art/villager.png) in marker colours, swapped for this villager's robe and hair; feet
## in the middle of the cell like the hero's, and as tall as he is, two cells (P1e). They
## breathe and blink in their own time (Idling), for show only.

const SHEET: Texture2D = preload("res://gameplay/art/villager.png")
## Frames in the order the tool paints them (a test checks).
const FRAMES: Dictionary = {
	&"plain": 0, &"bearded": 1, &"plain_breathe": 2, &"bearded_breathe": 3, &"plain_blink": 4, &"bearded_blink": 5,
}
const SIZE: Vector2i = Vector2i(16, 32)
## What each look of Idling adds to the frame's name.
const LOOKS: Dictionary = {Idling.Look.REST: "", Idling.Look.BREATHE: "_breathe", Idling.Look.BLINK: "_blink"}
## The marker colours the sheet is painted in, swapped for each villager's own.
const ROBE_MARK: Color = Color(1.0, 0.0, 1.0)
const ROBE_SHADE_MARK: Color = Color(0.5, 0.0, 0.5)
const HAIR_MARK: Color = Color(0.0, 1.0, 1.0)
const HAIR_SHADE_MARK: Color = Color(0.0, 0.5, 0.5)
## How far the figure is drawn up from the bottom of its cell, so its feet are mid-cell (signs
## stand the same way).
const LIFT: float = 5.0
## Where the feet are, down from the top of the cell.
const FEET_Y: float = 14.0 - LIFT

@export var robe_color: Color = Color(0.45, 0.35, 0.60)
@export var hair_color: Color = Color(0.35, 0.22, 0.12)
@export var beard: bool = false

## Whether they are here. A villager who stands outdoors goes home for the night (P2e): the area
## keeps their hours, and frees their cell while they are away.
var present: bool = true

var _idling: Idling
var _look: Idling.Look = Idling.Look.REST


func _ready() -> void:
	_idling = Idling.new(Idling.phase_of(cell()))
	_look = _idling.look()


func _process(delta: float) -> void:
	_idling.tick(delta)
	if _idling.look() != _look:
		_look = _idling.look()
		queue_redraw()


## The frame of the sheet showing now: this villager's picture, breathing out or blinking.
func frame() -> StringName:
	return StringName(("bearded" if beard else "plain") + str(LOOKS[_look]))


## Sends them home, or brings them back.
func set_present(here: bool) -> void:
	present = here
	visible = here


## Gone home, they are nowhere to be talked to.
func covers(at: Vector2i) -> bool:
	return present and super(at)


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
	SoftShadow.draw(self, Vector2(8, FEET_Y - 1.0), Vector2(6, 2.5), 1.1)
	SpriteSheet.draw(self, _sheet(), FRAMES[frame()], SIZE, Vector2(0, FEET_Y - SIZE.y + 1))


## The villager sheet in this villager's robe and hair (made once per look).
func _sheet() -> Texture2D:
	return SpriteSheet.recoloured(SHEET, {
		ROBE_MARK: robe_color, ROBE_SHADE_MARK: robe_color.darkened(0.3),
		HAIR_MARK: hair_color, HAIR_SHADE_MARK: hair_color.darkened(0.3),
	}, "villager:%s:%s" % [robe_color.to_html(), hair_color.to_html()])


func _ellipse(center: Vector2, radius: Vector2, color: Color) -> void:
	var points: PackedVector2Array = []
	for i: int in 16:
		var angle: float = TAU * i / 16.0
		points.append(center + Vector2(cos(angle) * radius.x, sin(angle) * radius.y))
	draw_colored_polygon(points, color)
