class_name Idling
extends RefCounted
## How someone standing still passes the time (P1e): they breathe out for BREATH_OUT at the end
## of every BREATH_EVERY seconds, and their eyes close for BLINK_TIME every BLINK_EVERY. Each
## starts at a moment of their own (`phase`), so a row of villagers doesn't blink as one.
## Pure: tick() it and read look(). For show only.

enum Look { REST, BREATHE, BLINK }

const BREATH_EVERY: float = 3.2
const BREATH_OUT: float = 1.1
const BLINK_EVERY: float = 4.3
const BLINK_TIME: float = 0.14

var _clock: float = 0.0


func _init(phase: float = 0.0) -> void:
	_clock = phase


## Lets `delta` seconds pass.
func tick(delta: float) -> void:
	_clock += delta


## What they are doing now. The eyes don't close mid-breath: the blink is drawn with the
## shoulders up, and they would jump.
func look() -> Look:
	if fmod(_clock, BREATH_EVERY) >= BREATH_EVERY - BREATH_OUT:
		return Look.BREATHE
	return Look.BLINK if fmod(_clock, BLINK_EVERY) >= BLINK_EVERY - BLINK_TIME else Look.REST


## A moment of their own for whoever stands in `cell`: the same every time the area loads, and
## different from their neighbours'.
static func phase_of(cell: Vector2i) -> float:
	return float(posmod(cell.x * 37 + cell.y * 101, 97)) / 97.0 * BREATH_EVERY * BLINK_EVERY
