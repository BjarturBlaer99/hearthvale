extends Node
## Writes GameState to JSON save slots and reads it back (docs/TECH_DESIGN.md §2, §9).
##
## Every file carries a `version`. Bump GameState.SAVE_VERSION on a breaking change to
## the save shape and add a step to `migrate()` so older saves still load.

const SAVE_DIR: String = "user://saves"
## The slot the title screen and the pause menu use (the slice has one).
const GAME_SLOT: int = 1

## The slot save_game() and load_game() use. Tests point it elsewhere.
var current_slot: int = GAME_SLOT


func slot_path(slot: int) -> String:
	return SAVE_DIR.path_join("slot_%d.json" % slot)


func has_slot(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))


func has_save() -> bool:
	return has_slot(current_slot)


func save_game() -> Error:
	return save_to_slot(current_slot)


func load_game() -> Error:
	return load_from_slot(current_slot)


## A save's key facts without loading it: { "area", "play_time", "hearts_max", "finished" }, or
## empty if there's no readable save in `from_slot` (default: the current slot).
func summary(from_slot: int = -1) -> Dictionary:
	var path: String = slot_path(current_slot if from_slot < 0 else from_slot)
	if not FileAccess.file_exists(path):
		return {}
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		return {}
	var data: Dictionary = parsed
	var where: Dictionary = data.get("player", {}) if typeof(data.get("player")) == TYPE_DICTIONARY else {}
	var saved_flags: Dictionary = data.get("flags", {}) if typeof(data.get("flags")) == TYPE_DICTIONARY else {}
	return {
		"area": str(where.get("area", "")),
		"play_time": float(data.get("play_time", 0.0)),
		"hearts_max": int(data.get("hearts_max", 0)),
		"finished": EndingSummary.is_finished(saved_flags),
	}


func save_to_slot(slot: int) -> Error:
	var dir_error: Error = DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	if dir_error != OK:
		push_error("SaveSystem: cannot create %s (%s)" % [SAVE_DIR, error_string(dir_error)])
		return dir_error
	var file: FileAccess = FileAccess.open(slot_path(slot), FileAccess.WRITE)
	if file == null:
		var open_error: Error = FileAccess.get_open_error()
		push_error("SaveSystem: cannot write %s (%s)" % [slot_path(slot), error_string(open_error)])
		return open_error
	file.store_string(JSON.stringify(GameState.to_dict(), "\t"))
	file.close()
	return OK


func load_from_slot(slot: int) -> Error:
	var path: String = slot_path(slot)
	if not FileAccess.file_exists(path):
		return ERR_FILE_NOT_FOUND
	var parsed: Variant = JSON.parse_string(FileAccess.get_file_as_string(path))
	if typeof(parsed) != TYPE_DICTIONARY:
		push_error("SaveSystem: %s is not a valid save file" % path)
		return ERR_PARSE_ERROR
	var data: Dictionary = parsed
	var version: int = int(data.get("version", 0))
	if version < 1 or version > GameState.SAVE_VERSION:
		push_error("SaveSystem: %s has unsupported version %d" % [path, version])
		return ERR_INVALID_DATA
	GameState.from_dict(migrate(data, version))
	return OK


## Brings save data from `from_version` up to GameState.SAVE_VERSION, one step at a time.
func migrate(data: Dictionary, from_version: int) -> Dictionary:
	var migrated: Dictionary = data.duplicate(true)
	if from_version < 2:
		migrated = _v1_to_v2(migrated)
	if from_version < 3:
		migrated = _v2_to_v3(migrated)
	migrated["version"] = GameState.SAVE_VERSION
	return migrated


## Version 2 (P2a) added the day, the time of day and the hero's energy. A game saved before
## them wakes on the first day at the hour days start, rested.
func _v1_to_v2(data: Dictionary) -> Dictionary:
	data["day"] = 1
	data["minute"] = float(GameState.day_clock().starts)
	data["energy"] = GameState.max_energy()
	return data


## Version 3 (P3a) added the farm. A game saved before it has an untouched plot.
func _v2_to_v3(data: Dictionary) -> Dictionary:
	data["farm"] = {"cells": {}}
	return data
