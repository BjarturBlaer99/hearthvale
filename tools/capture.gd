extends SceneTree
## Saves screenshots of an area with the hero at a few spots, for reviewing a build without
## playing it. Needs a window (not --headless):
##   godot --path . -s res://tools/capture.gd -- <output_dir>
## A -s script compiles before the autoloads exist, so GameState is looked up at runtime.

## [file name, area id, hero cell, facing, damage in half hearts, talk to what's in front]
const SHOTS: Array = [
	["1_village_square", &"village", Vector2i(23, 20), Vector2.DOWN, 0, false],
	["2_village_north_rise", &"village", Vector2i(24, 9), Vector2.UP, 0, false],
	["3_village_doors_hurt", &"village", Vector2i(23, 16), Vector2.UP, 3, false],
	["4_village_east_meadow", &"village", Vector2i(41, 24), Vector2.RIGHT, 0, false],
	["5_village_field_and_pond", &"village", Vector2i(20, 29), Vector2.DOWN, 0, false],
	["6_reading_the_sign", &"village", Vector2i(26, 19), Vector2.UP, 0, true],
	["7_elder_house", &"elder_house", Vector2i(5, 6), Vector2.UP, 0, false],
	["8_talking_to_bram", &"elder_house", Vector2i(5, 4), Vector2.UP, 0, true],
	["9_weaver_house", &"weaver_house", Vector2i(7, 4), Vector2.UP, 0, false],
]


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else "user://captures"
	DirAccess.make_dir_recursive_absolute(out_dir)
	var game_state: Node = root.get_node("GameState")
	for shot: Array in SHOTS:
		game_state.call(&"clear")
		game_state.call(&"new_game")
		game_state.call(&"damage", shot[4])
		var scene: Node = (load(WorldPaths.scene_for(shot[1])) as PackedScene).instantiate()
		root.add_child(scene)
		var player: Node = scene.get(&"player")
		var motor: PlayerMotor = player.get(&"motor")
		motor.place(shot[2])
		player.call(&"face", shot[3])
		if shot[5]:
			scene.call(&"interact")
		await _frames(30)
		var path: String = out_dir.path_join("%s.png" % shot[0])
		var error: Error = root.get_texture().get_image().save_png(path)
		print("tools/capture: %s (%s)" % [path, error_string(error)])
		scene.queue_free()
		await _frames(2)
	quit()


func _frames(count: int) -> void:
	for i: int in count:
		await process_frame
