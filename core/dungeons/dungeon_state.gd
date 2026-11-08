class_name DungeonState
extends RefCounted
## A dungeon's progress, kept as flags in GameState (docs/TECH_DESIGN.md §6) so leaving, coming
## back and saving never reset it. Pure: the flag names for one dungeon, and the door rules.
## Keys belong to their dungeon: small keys are a count, the big key a yes/no.
##
## Flags: dungeon/<id>/keys (int), dungeon/<id>/big_key (bool),
##        dungeon/<id>/door/<door> (bool, opened), dungeon/<id>/chest/<chest> (bool, opened).

## Door kinds (DungeonDoor.kind).
const OPEN: StringName = &"open"
const LOCKED: StringName = &"locked"
const BOSS: StringName = &"boss"
const SHUTTER: StringName = &"shutter"
## A cracked wall: a bomb's blast opens it for good.
const CRACKED: StringName = &"cracked"
const KINDS: Array[StringName] = [OPEN, LOCKED, BOSS, SHUTTER, CRACKED]


static func keys_flag(dungeon: StringName) -> StringName:
	return StringName("dungeon/%s/keys" % dungeon)


static func big_key_flag(dungeon: StringName) -> StringName:
	return StringName("dungeon/%s/big_key" % dungeon)


static func door_flag(dungeon: StringName, door: StringName) -> StringName:
	return StringName("dungeon/%s/door/%s" % [dungeon, door])


static func chest_flag(dungeon: StringName, chest: StringName) -> StringName:
	return StringName("dungeon/%s/chest/%s" % [dungeon, chest])


## Whether a closed door of `kind` can be opened now, holding `keys` small keys and the big key
## or not. Shutters never open by hand: their flag opens them.
static func can_unlock(kind: StringName, keys: int, has_big_key: bool) -> bool:
	match kind:
		LOCKED:
			return keys > 0
		BOSS:
			return has_big_key
	return false


## How many small keys opening a door of `kind` uses up.
static func key_cost(kind: StringName) -> int:
	return 1 if kind == LOCKED else 0
