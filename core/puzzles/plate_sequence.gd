class_name PlateSequence
extends RefCounted
## Plates to be pressed in an order (dungeon-difficulty-plan.md, decision 14). Pure: it is told
## each time a plate of the set is stepped onto, by its place in the order (1 to `length`), and
## says what came of it. The right plate next moves it on; the last one solves it. A wrong one
## starts it over, and counts as the first step if it is the first plate. Stepping again onto a
## plate already counted changes nothing.

const RIGHT: StringName = &"right"
const WRONG: StringName = &"wrong"
const DONE: StringName = &"done"
## Nothing changed: a plate already counted, or the set solved already.
const SAME: StringName = &"same"

var length: int
## How many plates have been pressed in the right order so far.
var progress: int = 0


func _init(plates: int) -> void:
	length = maxi(plates, 1)


func is_done() -> bool:
	return progress >= length


## Whether the plate at `place` (1-based) is counted: pressed in order, and not undone since.
func is_counted(place: int) -> bool:
	return place >= 1 and place <= progress


## The plate at `place` (1-based) has just been stepped onto. Returns RIGHT, WRONG, DONE or SAME.
func press(place: int) -> StringName:
	if is_done() or is_counted(place):
		return SAME
	if place == progress + 1:
		progress += 1
		return DONE if is_done() else RIGHT
	progress = 1 if place == 1 else 0
	return WRONG


## Back to the start (the hero left the room).
func reset() -> void:
	if not is_done():
		progress = 0


## What is wrong with a set of plates whose places in the order are `places`: nothing, if they
## are 1 to n with none missing or twice.
static func problems(places: Array) -> PackedStringArray:
	var out: PackedStringArray = []
	var sorted: Array = places.duplicate()
	sorted.sort()
	for i: int in sorted.size():
		if int(sorted[i]) != i + 1:
			out.append("its plates' places must be 1 to %d, each once; they are %s." % [sorted.size(), places])
			break
	return out
