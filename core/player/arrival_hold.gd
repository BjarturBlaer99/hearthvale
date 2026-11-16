class_name ArrivalHold
extends RefCounted
## A key held as the hero comes through a door (pure). He comes out facing the way the entry
## point says; a key still held **against** that way was pressed on the other side of the door,
## for the room he has left. Obeyed, it walks him straight back through the door he came out of:
## the keep's way out behind the Warden's hall is taken going north, and sets him down under the
## keep's gate, which is one step north of him. So that way is held back until the key is let
## go; every other way moves him at once, and so does a new press of the same key.


## Whether `input` (the movement keys, as a vector) pushes the way that is `held_back` (a unit
## vector, or zero for nothing held back).
static func is_against(input: Vector2, held_back: Vector2) -> bool:
	return held_back != Vector2.ZERO and input.dot(held_back) > 0.0


## `input` without its push the way that is `held_back`: the rest of it still moves him.
static func allowed(input: Vector2, held_back: Vector2) -> Vector2:
	if not is_against(input, held_back):
		return input
	return input - held_back * input.dot(held_back)


## What is held back after a frame with `input`: the same way while a key still pushes it,
## nothing once it is let go.
static func after(input: Vector2, held_back: Vector2) -> Vector2:
	return held_back if is_against(input, held_back) else Vector2.ZERO
