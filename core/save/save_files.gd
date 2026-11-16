class_name SaveFiles
extends RefCounted
## The files of a save slot, and what can be read from one (pure). A save is written beside
## its place first and put there only when it is whole, and the save that was there is kept as a
## backup, so a write that is cut short (the power, a full disk, the game closed) never costs
## the game:
##   slot_1.json          the save
##   slot_1.json.tmp      the save being written; never read
##   slot_1.backup.json   the save before the last
## SaveSystem does the writing and the reading; this says where, and whether what was read is a
## save this game can use.


## The file a save is written to before it is put in the place of `path`.
static func temp_path(path: String) -> String:
	return path + ".tmp"


## The file the save that was at `path` is kept in when a new one is written.
static func backup_path(path: String) -> String:
	return "%s.backup.%s" % [path.get_basename(), path.get_extension()]


## What is wrong with `text` as a save: OK if it is one this game can load, ERR_PARSE_ERROR if
## it isn't a save at all (cut short, empty, not JSON), ERR_INVALID_DATA if its version is one
## this game doesn't know (`newest` is the newest it does).
static func problem(text: String, newest: int) -> Error:
	if text.strip_edges().is_empty():
		return ERR_PARSE_ERROR
	var json: JSON = JSON.new()
	if json.parse(text) != OK or typeof(json.data) != TYPE_DICTIONARY:
		return ERR_PARSE_ERROR
	var version: int = int((json.data as Dictionary).get("version", 0))
	return OK if version >= 1 and version <= newest else ERR_INVALID_DATA


## The save in `text` as it was written, or {} if it can't be used (problem()).
static func read(text: String, newest: int) -> Dictionary:
	if problem(text, newest) != OK:
		return {}
	return JSON.parse_string(text)
