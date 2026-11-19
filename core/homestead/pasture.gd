class_name Pasture
extends RefCounted
## A pasture on the hero's land (the Homestead, phase 4; docs/TECH_DESIGN.md §30; the plan's
## D25), pure: the ground an animal can reach from its building's door without crossing a
## fence, a gate, a hedge or anything that stands, and how much of it is grass. Ground that runs
## on to the road or off the edge of the map is not fenced, and is no pasture.
##
## What a cell is, is asked of `kind_of` (a cell -> one of the kinds below), so this knows
## nothing of maps or of what is set down: GameState says what each cell of the land is.

## A cell of grass: walked on and grazed.
const GRASS: StringName = &"grass"
## A cell walked on and not grazed: a path or a floor lies there, or it is the field.
const BARE: StringName = &"bare"
## A cell nothing crosses: a fence, a gate, a hedge, anything standing, a building, debris, a
## tree, water, a wall.
const WALL: StringName = &"wall"
## The road, the path to a door, or a way out: ground that reaches it is not fenced.
const OPEN: StringName = &"open"


## The ground reached from `start` (a building's doorstep) through what can be crossed, in
## `size` cells (anything outside them is the edge of the map, and open):
## { "fenced": whether it is closed all round, "cells": Array[Vector2i] of what is reached, row
##   by row, "grass": how many of them are grass }.
## A start that can't be stood on (a wall, the road) reaches nothing, and is not fenced.
static func reach(start: Vector2i, size: Vector2i, kind_of: Callable) -> Dictionary:
	var bounds: Rect2i = Rect2i(Vector2i.ZERO, size)
	var start_kind: StringName = _kind(start, bounds, kind_of)
	if start_kind != GRASS and start_kind != BARE:
		return {"fenced": false, "cells": [] as Array[Vector2i], "grass": 0}
	var seen: Dictionary = {start: true}
	var queue: Array[Vector2i] = [start]
	var cells: Array[Vector2i] = []
	var grass: int = 0
	var fenced: bool = true
	while not queue.is_empty():
		var cell: Vector2i = queue.pop_front()
		cells.append(cell)
		if _kind(cell, bounds, kind_of) == GRASS:
			grass += 1
		for step: Vector2i in [Vector2i.UP, Vector2i.RIGHT, Vector2i.DOWN, Vector2i.LEFT]:
			var next: Vector2i = cell + step
			if seen.has(next):
				continue
			seen[next] = true
			var kind: StringName = _kind(next, bounds, kind_of)
			if kind == OPEN:
				fenced = false
			elif kind == GRASS or kind == BARE:
				queue.append(next)
	cells.sort_custom(func(a: Vector2i, b: Vector2i) -> bool: return a.y < b.y or (a.y == b.y and a.x < b.x))
	return {"fenced": fenced, "cells": cells, "grass": grass}


## Whether what reach() found is a pasture: fenced all round, with grass in it.
static func is_pasture(reached: Dictionary) -> bool:
	return bool(reached.get("fenced", false)) and int(reached.get("grass", 0)) > 0


## How many animals that eat `grazes` cells each a pasture of `grass` cells feeds.
static func feeds(grass: int, grazes: int) -> int:
	@warning_ignore("integer_division")
	return maxi(grass, 0) / maxi(grazes, 1)


static func _kind(cell: Vector2i, bounds: Rect2i, kind_of: Callable) -> StringName:
	if not bounds.has_point(cell):
		return OPEN
	return StringName(str(kind_of.call(cell)))
