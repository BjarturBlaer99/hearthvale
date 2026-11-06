extends Node
## Writes GameState to JSON save slots and reads it back (docs/TECH_DESIGN.md §2, §9).
##
## Every file carries a `version`. Bump GameState.SAVE_VERSION on a breaking change to
## the save shape and add a step to `migrate()` so older saves still load.

const SAVE_DIR: String = "user://saves"


func slot_path(slot: int) -> String:
	return SAVE_DIR.path_join("slot_%d.json" % slot)


func has_slot(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))


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
	# Version 1 is the first format, so there is nothing to migrate yet. Add steps here:
	# if from_version < 2: migrated = _v1_to_v2(migrated)
	migrated["version"] = GameState.SAVE_VERSION
	return migrated
