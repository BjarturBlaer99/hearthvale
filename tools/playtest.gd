extends SceneTree
## Starts the game partway through, for trying one part by hand without playing up to it.
## Needs a window:
##   godot --path . -s res://tools/playtest.gd -- <scenario>
## Scenarios are below. Saving in a scenario goes to a slot of its own, emptied at each
## start, so it never overwrites the player's own game. A -s script compiles before the
## autoloads exist, so GameState and SaveSystem are looked up at runtime.

##
## "full" is the whole game for a playtest (docs/progress/H15-playtest.md):
##   godot --path . -s res://tools/playtest.gd -- full [fresh]
## It opens the title screen on a save slot of its own, so there's no Continue until this
## playtest has saved, and the slot is kept between runs so a session can stop and go on
## ("fresh" empties it first). It writes down when things happen (areas entered, items first
## held, flags, quests, falls) with the time since the run began and the game's own clock, to
## the console and to user://playtests/playtest_<date and time>.log.

## The save slot scenarios use (the game's own is SaveSystem.GAME_SLOT; tests use 990 and up).
const PLAYTEST_SLOT: int = 900
## The whole-game playtest: its name on the command line, its save slot and where its logs go.
const FULL: String = "full"
const FULL_SLOT: int = 901
const TITLE_SCENE: String = "res://ui/title_screen.tscn"
const LOG_DIR: String = "user://playtests"
## Add this word to print every key pressed and what the words on screen were (to chase input bugs).
const KEYS: String = "keys"

## Each scenario: the area and cell to start in, items to hold, and flags to set. An hour
## after the scenario's name starts it at that time of day: -- village 19:30
const SCENARIOS: Dictionary = {
	# In the village square at the start of the game, with nothing: for watching a day go by.
	"village": {
		"area": &"village",
		"cell": Vector2i(23, 20),
		"items": [],
		"flags": [],
	},
	# Outside the Iron Warden's hall: sword, bow, 20 arrows, the boss door already open.
	"warden": {
		"area": &"keep",
		"cell": Vector2i(22, 24),
		"items": [[&"wooden_sword", 1], [&"bow", 1], [&"arrow", 20]],
		"flags": [&"took_wooden_sword", &"dungeon/keep/big_key", &"dungeon/keep/door/boss_door"],
	},
	# At the top of the crypt's stairs, as after the keep: sword, bow, arrows and bombs.
	"crypt": {
		"area": &"crypt",
		"cell": Vector2i(22, 42),
		"items": [[&"wooden_sword", 1], [&"bow", 1], [&"arrow", 20], [&"bomb", 5]],
		"flags": [&"took_wooden_sword", &"keep_warden_beaten"],
	},
	# In the Shade's hall with the Shade beaten: step up to the heart container for the ending.
	"ending": {
		"area": &"crypt",
		"cell": Vector2i(22, 16),
		"items": [[&"wooden_sword", 1], [&"iron_sword", 1], [&"bow", 1], [&"arrow", 20], [&"lantern", 1]],
		"flags": [&"took_wooden_sword", &"keep_warden_beaten", &"crypt_shade_beaten", &"dungeon/crypt/big_key", &"dungeon/crypt/door/boss_door"],
	},
	# Outside the Crypt Shade's hall: the Lantern and the Iron Sword, the boss door already open.
	"shade": {
		"area": &"crypt",
		"cell": Vector2i(22, 24),
		"items": [[&"wooden_sword", 1], [&"iron_sword", 1], [&"bow", 1], [&"arrow", 20], [&"lantern", 1]],
		"flags": [&"took_wooden_sword", &"keep_warden_beaten", &"dungeon/crypt/big_key", &"dungeon/crypt/door/boss_door"],
	},
}


## The whole-game playtest's log, while one runs (null in a scenario).
var _log: FileAccess
var _game_state: Node
var _started_msec: int = 0
var _game_clock: float = 0.0
var _area: String = ""
var _fallen: bool = false
var _held: Dictionary = {}


func _initialize() -> void:
	_start.call_deferred()


func _start() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var scenario_name: String = args[0] if args.size() > 0 else ""
	if args.has(KEYS):
		root.add_child(KeyWatch.new())
	if scenario_name == FULL:
		_start_full(args.has("fresh"))
		return
	if not SCENARIOS.has(scenario_name):
		push_error("tools/playtest: no scenario '%s'. Scenarios: %s, %s" % [scenario_name, ", ".join(SCENARIOS.keys()), FULL])
		quit(1)
		return
	var scenario: Dictionary = SCENARIOS[scenario_name]
	var saves: Node = root.get_node("SaveSystem")
	saves.set(&"current_slot", PLAYTEST_SLOT)
	var old_save: String = str(saves.call(&"slot_path", PLAYTEST_SLOT))
	if FileAccess.file_exists(old_save):
		DirAccess.remove_absolute(old_save)
	print("tools/playtest: '%s'. Saving here goes to slot %d, not your own game." % [scenario_name, PLAYTEST_SLOT])
	var game_state: Node = root.get_node("GameState")
	game_state.call(&"new_game")
	for item: Array in scenario["items"]:
		game_state.call(&"add_item", item[0], item[1])
	for flag: StringName in scenario["flags"]:
		game_state.call(&"set_flag", flag, true)
	for arg: String in args.slice(1):
		if DayClock.parse(arg) >= 0:
			game_state.call(&"set_time", float((game_state.call(&"day_clock") as DayClock).in_day(arg)))
			print("tools/playtest: starting at %s." % arg)
	game_state.call(&"update_player", scenario["area"], scenario["cell"])
	change_scene_to_file("res://world/areas/%s/%s.tscn" % [scenario["area"], scenario["area"]])


## The whole game, from the title screen, on its own save slot, with a log of what happens.
func _start_full(fresh: bool) -> void:
	var saves: Node = root.get_node("SaveSystem")
	saves.set(&"current_slot", FULL_SLOT)
	var save_path: String = str(saves.call(&"slot_path", FULL_SLOT))
	if fresh and FileAccess.file_exists(save_path):
		DirAccess.remove_absolute(save_path)
	_game_state = root.get_node("GameState")
	_game_state.call(&"clear")
	_started_msec = Time.get_ticks_msec()
	DirAccess.make_dir_recursive_absolute(LOG_DIR)
	var log_path: String = LOG_DIR.path_join("playtest_%s.log" % Time.get_datetime_string_from_system().replace(":", "-"))
	_log = FileAccess.open(log_path, FileAccess.WRITE)
	var bus: Node = root.get_node("EventBus")
	bus.connect(&"flag_set", _on_flag_set)
	bus.connect(&"item_added", _on_item_added)
	bus.connect(&"health_changed", _on_health_changed)
	bus.connect(&"quest_announced", _on_quest_announced)
	# Keys pressed while words are on screen go in the log too (run 3's closing words got stuck).
	var watch: KeyWatch = KeyWatch.new()
	watch.words_only = true
	watch.report = _note
	root.add_child(watch)
	print("tools/playtest: the whole game. Saves go to slot %d, not your own game. Log: %s" % [FULL_SLOT, ProjectSettings.globalize_path(log_path)])
	_note("run started (%s)" % ("carrying on from this playtest's save" if FileAccess.file_exists(save_path) else "no save yet"))
	change_scene_to_file(TITLE_SCENE)


## Watches for the hero changing area (nothing announces it) while a whole-game playtest runs.
func _process(_delta: float) -> bool:
	if _log == null or not is_instance_valid(_game_state):
		return false
	_game_clock = float(_game_state.get(&"play_time"))
	var where: Variant = _game_state.get(&"player")
	var area: String = str((where as Dictionary).get("area", "")) if typeof(where) == TYPE_DICTIONARY else ""
	if area != _area:
		_area = area
		if area != "":
			_note("entered %s" % area)
	return false


func _finalize() -> void:
	if _log != null:
		_note("run ended")
		_log.close()
		_log = null


func _on_flag_set(flag: StringName, value: Variant) -> void:
	_note("flag %s = %s" % [flag, value])


## The first time each kind of item is held (coins and arrows come by the dozen).
func _on_item_added(item_id: StringName, _count: int) -> void:
	if not _held.has(item_id):
		_held[item_id] = true
		_note("first %s" % item_id)


func _on_health_changed(current: int, _maximum: int) -> void:
	if current <= 0 and not _fallen:
		_note("fell (out of hearts)")
	_fallen = current <= 0


func _on_quest_announced(quest_id: StringName, what: StringName) -> void:
	_note("quest %s: %s" % [quest_id, what])


## One line of the log: the time since the run began, the game's own clock, and what happened.
func _note(what: String) -> void:
	# As the game closes the autoloads may already be gone: the last clock read is used then.
	if is_instance_valid(_game_state):
		_game_clock = float(_game_state.get(&"play_time"))
	var line: String = "%s  game %s  %s" % [_clock((Time.get_ticks_msec() - _started_msec) / 1000.0), _clock(_game_clock), what]
	print("[playtest] " + line)
	if _log != null:
		_log.store_line(line)
		_log.flush()


## Seconds as h:mm:ss.
static func _clock(seconds: float) -> String:
	var whole: int = int(seconds)
	@warning_ignore("integer_division")
	return "%d:%02d:%02d" % [whole / 3600, (whole / 60) % 60, whole % 60]


## Prints each key or button pressed, with the conversation showing (if any) and its answers.
class KeyWatch:
	extends Node

	## Only presses made while a conversation shows.
	var words_only: bool = false
	## Where each line goes (default: printed).
	var report: Callable = func(line: String) -> void: print("[keys] " + line)

	func _init() -> void:
		process_mode = Node.PROCESS_MODE_ALWAYS

	func _input(event: InputEvent) -> void:
		if not event.is_pressed() or event.is_echo() or not (event is InputEventKey or event is InputEventJoypadButton):
			return
		var scene: Node = get_tree().current_scene
		var hud: Variant = scene.get(&"hud") if scene != null else null
		var box: Variant = (hud as Node).get(&"dialogue") if hud is Node else null
		var words: String = ""
		if box is Node and (box as Node).call(&"is_open"):
			words = "words: '%s...' answers: %s" % [str((box as Node).call(&"shown_text")).left(24), (box as Node).call(&"shown_options")]
		if words == "" and words_only:
			return
		report.call("key %s  paused: %s  %s" % [event.as_text(), get_tree().paused, words if words != "" else "no words showing"])
