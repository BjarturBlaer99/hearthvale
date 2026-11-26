class_name Villager
extends Talkable
## A villager who stands in one spot and talks. Their name comes from their conversation (the
## start node's speaker, through the dialogue's "speakers" map). Pixel art
## (gameplay/art/villager.png): each villager is a figure of their own from the art pack (the
## farm-look plan, phase D: F5, "Eight faces"), named by `figure`. They are the pack's short
## people (F3), standing at the foot of a frame as tall as the hero's, feet in the middle of the
## cell as before. They breathe and blink in their own time (Idling), for show only.

const SHEET: Texture2D = preload("res://gameplay/art/villager.png")
## The figures, in the sheet's order: each has three frames, resting, breathing out and blinking.
const FIGURES: Array[StringName] = [&"bram", &"tilda", &"wenna", &"pip", &"rolf", &"oda", &"edda", &"henrik"]
## Frames in the order the tool paints them (a test checks).
const FRAMES: Dictionary = {
	&"bram": 0, &"bram_breathe": 1, &"bram_blink": 2,
	&"tilda": 3, &"tilda_breathe": 4, &"tilda_blink": 5,
	&"wenna": 6, &"wenna_breathe": 7, &"wenna_blink": 8,
	&"pip": 9, &"pip_breathe": 10, &"pip_blink": 11,
	&"rolf": 12, &"rolf_breathe": 13, &"rolf_blink": 14,
	&"oda": 15, &"oda_breathe": 16, &"oda_blink": 17,
	&"edda": 18, &"edda_breathe": 19, &"edda_blink": 20,
	&"henrik": 21, &"henrik_breathe": 22, &"henrik_blink": 23,
}
const SIZE: Vector2i = Vector2i(16, 32)
## What each look of Idling adds to the frame's name.
const LOOKS: Dictionary = {Idling.Look.REST: "", Idling.Look.BREATHE: "_breathe", Idling.Look.BLINK: "_blink"}
## How far the figure is drawn up from the bottom of its cell, so its feet are mid-cell (signs
## stand the same way).
const LIFT: float = 5.0
## Where the feet are, down from the top of the cell.
const FEET_Y: float = 14.0 - LIFT

## Which figure of the sheet is theirs (one of FIGURES; any other name shows the first).
@export var figure: StringName = &"pip"

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


## The frame of the sheet showing now: this villager's figure, resting, breathing out or blinking.
func frame() -> StringName:
	var own: StringName = figure if FIGURES.has(figure) else FIGURES[0]
	return StringName(String(own) + str(LOOKS[_look]))


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
	SpriteSheet.draw(self, SHEET, FRAMES[frame()], SIZE, Vector2(0, FEET_Y - SIZE.y + 1))
