class_name MoveResult
extends RefCounted
## The outcome of stepping from one cell onto a neighbour (docs/TECH_DESIGN.md §3).
## Produced by TerrainQuery.check_move(); the player and enemies act on it.

enum Kind { BLOCKED, WALK, DROP }

var kind: Kind = Kind.BLOCKED
## The level the mover stands at after the move.
var to_level: int = 0
## Levels hopped down off a ledge. Ledge hops never hurt.
var drop: int = 0
## Why the move is BLOCKED, for debugging.
var reason: String = ""


func is_allowed() -> bool:
	return kind != Kind.BLOCKED
