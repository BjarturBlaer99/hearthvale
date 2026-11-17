extends Node
## Writes GameState to JSON save slots and reads it back (docs/TECH_DESIGN.md §2, §9).
##
## Every file carries a `version`. Bump GameState.SAVE_VERSION on a breaking change to
## the save shape and add a step to `migrate()` so older saves still load.
##
## A save is never written over the one before it (SaveFiles): it is written beside it, read
## back to see that it is whole, and only then put in its place, and the save that was there is
## kept as a backup. A write that fails leaves the old save as it was.
##
## Leaving saves first: the window closing is not taken as a yes (auto_accept_quit is off). The
## game's scene is asked to save and say so (`save_and_leave(then)`: an area, the ending screen),
## and the game quits a moment later. A scene with nothing to save (the title) quits at once.

const SAVE_DIR: String = "user://saves"
## The slot the title screen and the pause menu use (the slice has one).
const GAME_SLOT: int = 1
## How often a file is tried again when the system won't let go of it (a file just written
## can be held for a moment by whatever watches the disk), and how long between tries.
const TRIES: int = 5
const TRY_AGAIN_MSEC: int = 20
## What the screen says while the game is saved on its way out, what it says when that save
## can't be written (the game stays, the first time), and how long the first stays up.
const SAVING_WORDS: String = "Saving..."
const NOT_SAVED_WORDS: String = "Couldn't save (%s). Quit again to leave without saving."
const LEAVE_DELAY: float = 0.5

## The slot save_game() and load_game() use. Tests point it elsewhere.
var current_slot: int = GAME_SLOT
## Writes `text` to the file at `path` and returns what went wrong, if anything. Tests replace
## it to cut a save short.
var write_file: Callable = _write_text
## How long "Saving..." is up before the game leaves. Tests set it to nothing.
var leave_delay: float = LEAVE_DELAY
## Quits the game. Tests replace it.
var quit: Callable = func() -> void: get_tree().quit()


func _ready() -> void:
	# The game decides when a closing window may close: a game in play is saved first.
	get_tree().auto_accept_quit = false


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST:
		close_requested()


## The window was asked to close. The game's scene saves first and says so, if it has a game to
## save (it has `save_and_leave(then)`), and the game quits when it is done; any other scene
## (the title) quits at once. Only the scene the game is showing is asked: an area a test or a
## tool has put in the tree beside it is not.
func close_requested() -> void:
	var scene: Node = get_tree().current_scene
	if scene != null and scene.has_method(&"save_and_leave"):
		scene.call(&"save_and_leave", quit)
	else:
		quit.call()


## Calls `then` when "Saving..." has been up for `leave_delay` (at once, with none). It counts
## real time, behind the pause menu too.
func after_notice(then: Callable) -> void:
	if leave_delay <= 0.0:
		then.call()
	else:
		get_tree().create_timer(leave_delay, true, false, true).timeout.connect(then)


func slot_path(slot: int) -> String:
	return SAVE_DIR.path_join("slot_%d.json" % slot)


func backup_path(slot: int) -> String:
	return SaveFiles.backup_path(slot_path(slot))


func has_slot(slot: int) -> bool:
	return FileAccess.file_exists(slot_path(slot))


func has_save() -> bool:
	return has_slot(current_slot)


## Whether the save before the last is kept for the current slot.
func has_backup() -> bool:
	return FileAccess.file_exists(backup_path(current_slot))


## Removes everything kept for `slot`: its save, its backup and a save left half written.
func erase_slot(slot: int) -> void:
	for path: String in [slot_path(slot), backup_path(slot), SaveFiles.temp_path(slot_path(slot))]:
		_remove(path)


func save_game() -> Error:
	return save_to_slot(current_slot)


func load_game() -> Error:
	return load_from_slot(current_slot)


## Loads the save before the last into GameState (the title offers it when the save can't be
## read).
func load_backup() -> Error:
	return _load(backup_path(current_slot))


## A save's key facts without loading it: { "area", "play_time", "hearts_max", "finished" }, or
## empty if there's no readable save in `from_slot` (default: the current slot).
func summary(from_slot: int = -1) -> Dictionary:
	return _summary(slot_path(current_slot if from_slot < 0 else from_slot))


## The same for the current slot's backup.
func backup_summary() -> Dictionary:
	return _summary(backup_path(current_slot))


## Writes GameState to `slot`, safely: to a file beside the save first, which is read back, and
## only a whole one is put in the save's place. The save that was there becomes the backup.
## Anything that goes wrong before the new save is in place leaves the old one as it was.
func save_to_slot(slot: int) -> Error:
	var dir_error: Error = DirAccess.make_dir_recursive_absolute(SAVE_DIR)
	if dir_error != OK:
		push_error("SaveSystem: cannot create %s (%s)" % [SAVE_DIR, error_string(dir_error)])
		return dir_error
	var path: String = slot_path(slot)
	var temp: String = SaveFiles.temp_path(path)
	var text: String = JSON.stringify(GameState.to_dict(), "\t")
	var error: Error = write_file.call(temp, text)
	# Read back: a disk that filled up, or a write cut short, must not pass for a save.
	if error == OK and FileAccess.get_file_as_string(temp) != text:
		error = ERR_FILE_CORRUPT
	if error != OK:
		push_error("SaveSystem: cannot write %s (%s); the save before it is untouched" % [temp, error_string(error)])
		_remove(temp)
		return error
	var kept: bool = not FileAccess.file_exists(path)
	if not kept:
		kept = _try(func() -> Error: return DirAccess.copy_absolute(path, backup_path(slot))) == OK
		if not kept:
			push_warning("SaveSystem: cannot keep %s as a backup" % path)
	error = _put_in_place(temp, path, kept)
	if error != OK:
		push_error("SaveSystem: cannot put %s in place (%s)" % [path, error_string(error)])
		_remove(temp)
	return error


func load_from_slot(slot: int) -> Error:
	return _load(slot_path(slot))


## Brings save data from `from_version` up to GameState.SAVE_VERSION, one step at a time.
func migrate(data: Dictionary, from_version: int) -> Dictionary:
	var migrated: Dictionary = data.duplicate(true)
	if from_version < 2:
		migrated = _v1_to_v2(migrated)
	if from_version < 3:
		migrated = _v2_to_v3(migrated)
	if from_version < 4:
		migrated = _v3_to_v4(migrated)
	if from_version < 5:
		migrated = _v4_to_v5(migrated)
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


## Version 4 (P4a) added the day each flag came true, skill points, friendship and a tally, and
## it is the version the story's gates came with: the keep's gate waits for Elder Bram's word,
## his word for a first crop, and the crypt's bars for the dawn after the Warden falls. A game
## saved before them has none of the new things and is past the gates: its hero may be standing
## inside the keep.
func _v3_to_v4(data: Dictionary) -> Dictionary:
	data["flag_days"] = {}
	data["skills"] = {}
	data["friends"] = {}
	data["tally"] = {}
	var saved_flags: Variant = data.get("flags", {})
	data["flags"] = StoryGates.past_the_gates(saved_flags if typeof(saved_flags) == TYPE_DICTIONARY else {})
	return data


## Version 5 (2026-11-17) came with mining and crafting: the mine keeps the number its daily
## rolls come from and the rocks broken today; the hero's home keeps what its furnace and its
## chest hold; and what he has ever held is remembered, for the recipes that wait on it. A game
## saved before it gets a number of its own, made from the save itself so the same save always
## rolls the same way, a whole mine, a cold furnace and an empty chest. (What it carries counts
## as found when it loads.)
func _v4_to_v5(data: Dictionary) -> Dictionary:
	data["mine"] = {"number": hash([data.get("play_time", 0.0), data.get("day", 1), data.get("hearts_max", 0)]), "day": 0, "broken": {}}
	data["home"] = {"furnace": {}, "chest": []}
	data["found"] = []
	return data


func _load(path: String) -> Error:
	if not FileAccess.file_exists(path):
		return ERR_FILE_NOT_FOUND
	var text: String = FileAccess.get_file_as_string(path)
	var problem: Error = SaveFiles.problem(text, GameState.SAVE_VERSION)
	if problem != OK:
		push_error("SaveSystem: %s %s" % [path, "is not a valid save file" if problem == ERR_PARSE_ERROR else "has a version this game doesn't know"])
		return problem
	var data: Dictionary = SaveFiles.read(text, GameState.SAVE_VERSION)
	GameState.from_dict(migrate(data, int(data.get("version", 0))))
	return OK


func _summary(path: String) -> Dictionary:
	if not FileAccess.file_exists(path):
		return {}
	var data: Dictionary = SaveFiles.read(FileAccess.get_file_as_string(path), GameState.SAVE_VERSION)
	if data.is_empty():
		return {}
	var where: Dictionary = data.get("player", {}) if typeof(data.get("player")) == TYPE_DICTIONARY else {}
	var saved_flags: Dictionary = data.get("flags", {}) if typeof(data.get("flags")) == TYPE_DICTIONARY else {}
	return {
		"area": str(where.get("area", "")),
		"play_time": float(data.get("play_time", 0.0)),
		"hearts_max": int(data.get("hearts_max", 0)),
		"finished": EndingSummary.is_finished(saved_flags),
	}


func _write_text(path: String, text: String) -> Error:
	var file: FileAccess = FileAccess.open(path, FileAccess.WRITE)
	if file == null:
		return FileAccess.get_open_error()
	file.store_string(text)
	var error: Error = file.get_error()
	file.close()
	return error


## Moves the whole new save at `temp` to `path`. Where a move won't take the place of a file,
## the old one goes first, but only if it is `kept` in the backup.
func _put_in_place(temp: String, path: String, kept: bool) -> Error:
	var error: Error = _try(func() -> Error: return DirAccess.rename_absolute(temp, path))
	if error != OK and kept and FileAccess.file_exists(path):
		_remove(path)
		error = _try(func() -> Error: return DirAccess.rename_absolute(temp, path))
	return error


## Does `action` (it returns an Error) until it works, a few times over.
func _try(action: Callable) -> Error:
	var error: Error = FAILED
	for i: int in TRIES:
		error = action.call()
		if error == OK:
			break
		OS.delay_msec(TRY_AGAIN_MSEC)
	return error


func _remove(path: String) -> void:
	if FileAccess.file_exists(path):
		DirAccess.remove_absolute(path)
