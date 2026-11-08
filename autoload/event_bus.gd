extends Node
## Global signal hub: signals only, never state (docs/TECH_DESIGN.md §2).
##
## Systems talk through these signals instead of holding references across scenes.
## Anything that must survive a save belongs in GameState, which is the only emitter
## of the state signals below.

## A quest moved to a new stage.
signal quest_updated(quest_id: StringName)

## Items entered the inventory. A negative `count` means items were removed.
signal item_added(item_id: StringName, count: int)

## A world flag was written.
signal flag_set(flag: StringName, value: Variant)

## The hero's health changed. Both values are in half hearts.
signal health_changed(current: int, maximum: int)
