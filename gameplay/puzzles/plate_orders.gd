class_name PlateOrders
extends RefCounted
## The area's plates that are pressed in an order (dungeon-difficulty-plan.md, decision 14):
## every set of plates sharing a `flag`, each with its `order`. Each physics frame the area
## says what stands where; a plate stepped onto is counted by its set's PlateSequence. In turn
## it stays down with the plate's clunk; out of turn the set's plates rise with "nope"; the last
## in turn sets the flag for good (the shutter waiting on it says "solved"). A set already
## solved (its flag set, in this visit or a saved game) shows every plate down. Leaving the room
## starts an unsolved set over (`reset()`). Nothing about the progress is saved.

var _sets: Dictionary = {}
var _standing: Dictionary = {}


## Updates every plate with an `order` among `plates` for the hero in `hero` and blocks in
## `blocks` (cells); `nobody` (the hero dying) presses nothing.
func update(plates: Array, hero: Vector2i, blocks: Array, nobody: bool = false) -> void:
	for plate: PressurePlate in _ordered(plates):
		var sequence: PlateSequence = _sequence_of(plate, plates)
		var down: bool = not nobody and PuzzleRules.plate_pressed(plate.cell(), hero, blocks)
		var was: bool = bool(_standing.get(plate, false))
		_standing[plate] = down
		if down and not was:
			_press(plate, sequence, plates)
		plate.show_counted(sequence.is_done() or sequence.is_counted(plate.order))


## Every unsolved set back to the start, its plates up.
func reset(plates: Array) -> void:
	for flag: StringName in _sets:
		(_sets[flag] as PlateSequence).reset()
	for plate: PressurePlate in _ordered(plates):
		var sequence: PlateSequence = _sets.get(plate.flag)
		if sequence != null:
			plate.show_counted(sequence.is_done() or sequence.is_counted(plate.order))


## The set `flag` names (null before any of its plates has been looked at).
func set_of(flag: StringName) -> PlateSequence:
	return _sets.get(flag)


func _press(plate: PressurePlate, sequence: PlateSequence, plates: Array) -> void:
	var result: StringName = sequence.press(plate.order)
	if result == PlateSequence.RIGHT:
		EventBus.sound.emit(&"plate")
	elif result == PlateSequence.DONE:
		EventBus.sound.emit(&"plate")
		GameState.set_flag(plate.flag, true)
	elif result == PlateSequence.WRONG:
		EventBus.sound.emit(&"nope")
		# Out of turn: every plate of the set rises (but the first, stepped onto afresh).
		for other: PressurePlate in _ordered(plates):
			if other.flag == plate.flag:
				other.show_counted(sequence.is_counted(other.order))


func _sequence_of(plate: PressurePlate, plates: Array) -> PlateSequence:
	if not _sets.has(plate.flag):
		var count: int = 0
		for other: PressurePlate in _ordered(plates):
			if other.flag == plate.flag:
				count += 1
		_sets[plate.flag] = PlateSequence.new(count)
	var sequence: PlateSequence = _sets[plate.flag]
	if GameState.get_flag(plate.flag) == true and not sequence.is_done():
		sequence.progress = sequence.length
	return sequence


static func _ordered(plates: Array) -> Array[PressurePlate]:
	var out: Array[PressurePlate] = []
	for plate: Variant in plates:
		if plate is PressurePlate and (plate as PressurePlate).order > 0:
			out.append(plate as PressurePlate)
	return out
