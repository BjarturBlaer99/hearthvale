extends SceneTree
## Starts the game partway through, for trying one part by hand without playing up to it.
## Needs a window:
##   godot --path . -s res://tools/playtest.gd -- <scenario>
## Scenarios are below. A -s script compiles before the autoloads exist, so GameState is
## looked up at runtime.

## Each scenario: the area and cell to start in, items to hold, and flags to set.
const SCENARIOS: Dictionary = {
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


func _initialize() -> void:
	_start.call_deferred()


func _start() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var scenario_name: String = args[0] if args.size() > 0 else ""
	if not SCENARIOS.has(scenario_name):
		push_error("tools/playtest: no scenario '%s'. Scenarios: %s" % [scenario_name, ", ".join(SCENARIOS.keys())])
		quit(1)
		return
	var scenario: Dictionary = SCENARIOS[scenario_name]
	var game_state: Node = root.get_node("GameState")
	game_state.call(&"new_game")
	for item: Array in scenario["items"]:
		game_state.call(&"add_item", item[0], item[1])
	for flag: StringName in scenario["flags"]:
		game_state.call(&"set_flag", flag, true)
	game_state.call(&"update_player", scenario["area"], scenario["cell"])
	change_scene_to_file("res://world/areas/%s/%s.tscn" % [scenario["area"], scenario["area"]])
