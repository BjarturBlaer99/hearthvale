class_name MoveResult
extends RefCounted
## The outcome of stepping from one cell onto a neighbour (docs/TECH_DESIGN.md §3.4).
## Produced by TerrainQuery.check_move(); the player and NPC state machines act on it.

enum Kind { BLOCKED, WALK, CLIMB, DROP, SWIM }

var kind: Kind = Kind.BLOCKED
## The level the actor stands, or swims, at after the move.
var to_level: int = 0
## Levels fallen. A drop into deep water never hurts.
var drop: int = 0
## True when the drop is high enough to hurt (TerrainQuery.DAMAGING_DROP or more, onto ground).
var damaging: bool = false
## Movement speed multiplier: TerrainQuery.SHALLOW_SPEED while wading.
var speed_scale: float = 1.0
## Why the move is BLOCKED, for debugging.
var reason: String = ""


func is_allowed() -> bool:
	return kind != Kind.BLOCKED
