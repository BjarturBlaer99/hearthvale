extends SceneTree
## Saves screenshots of St. Aud at each water level, with the player at the level-gated
## places, for reviewing a build without playing it. Needs a window (not --headless):
##   godot --path . -s res://tools/capture_st_aud.gd -- <output_dir>
## Without an output dir it writes to user://captures.
##
## A -s script compiles before the autoloads exist, so it must not name classes that use
## them (DistrictController, GameState...). Everything here is looked up at runtime.

const SCENE: String = "res://world/districts/st_aud/st_aud.tscn"
## [file name, water level, player cell, facing]
const SHOTS: Array = [
	["1_flooded_spawn", &"flooded", Vector2i(8, 9), Vector2.DOWN],
	["2_flooded_rooftop_door", &"flooded", Vector2i(45, 23), Vector2.UP],
	["3_waist_clinic_hatch", &"waist", Vector2i(14, 38), Vector2.LEFT],
	["4_waist_spawn", &"waist", Vector2i(9, 14), Vector2.RIGHT],
	["5_drained_subway", &"drained", Vector2i(43, 47), Vector2.DOWN],
	["6_drained_spawn", &"drained", Vector2i(9, 16), Vector2.DOWN],
	["7_flooded_swimming", &"flooded", Vector2i(40, 23), Vector2.RIGHT],
]


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else "user://captures"
	DirAccess.make_dir_recursive_absolute(out_dir)
	var game_state: Node = root.get_node("GameState")
	game_state.call(&"clear")
	var district: Node = (load(SCENE) as PackedScene).instantiate()
	root.add_child(district)
	await _frames(10)
	var player: Node = district.get(&"player")
	for shot: Array in SHOTS:
		game_state.call(&"set_water_level", &"st_aud", shot[1])
		var motor: PlayerMotor = player.get(&"motor")
		motor.place(shot[2])
		motor.facing = shot[3]
		player.call(&"sync_from_motor")
		await _frames(40)
		var path: String = out_dir.path_join("%s.png" % shot[0])
		var error: Error = root.get_texture().get_image().save_png(path)
		print("tools/capture_st_aud: %s (%s)" % [path, error_string(error)])
	quit()


func _frames(count: int) -> void:
	for i: int in count:
		await process_frame
