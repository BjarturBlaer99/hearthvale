extends Node
## Global signal hub: signals only, never state (docs/TECH_DESIGN.md §2).
##
## Systems talk through these signals instead of holding references across scenes.
## Anything that must survive a save belongs in GameState, which is the only emitter
## of the state signals below.

## A district's water level changed. Emitted after the change is applied.
signal water_level_changed(district_id: StringName, level: StringName)

## A quest moved to a new stage.
signal quest_updated(quest_id: StringName)

## A faction's reputation changed; `value` is the new, clamped total.
signal reputation_changed(faction_id: StringName, value: int)

## Items entered the inventory. A negative `count` means items were removed.
signal item_added(item_id: StringName, count: int)

## A world flag was written.
signal flag_set(flag: StringName, value: Variant)
