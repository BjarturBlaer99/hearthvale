class_name Talkable
extends Node2D
## Someone (or something) the hero talks to or reads: face it and press interact
## (docs/TECH_DESIGN.md §7). It names a conversation in data/dialogue and stands in its cell,
## which nothing else can enter. Position = the cell's top-left corner. Villager and Signpost
## draw themselves.

@export var dialogue_id: StringName


func cell() -> Vector2i:
	return PlayerMotor.cell_of(position + Vector2(0.5, 0.5))


func covers(at: Vector2i) -> bool:
	return at == cell()


## It stands in its cell: the area marks the cell occupied.
func occupies() -> bool:
	return true


## The conversation's data from DataRegistry (empty if the id is unknown).
func dialogue() -> Dictionary:
	return DataRegistry.get_dialogue(dialogue_id)


## The HUD prompt for using it, after the interact button's name.
func prompt() -> String:
	return "Talk"
