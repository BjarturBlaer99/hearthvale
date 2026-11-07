extends SceneTree
## Saves screenshots of the boat and travel situations across maps (the sea, arriving at
## districts at different water levels), for reviewing a build without playing it.
## Needs a window (not --headless):
##   godot --path . -s res://tools/capture_world.gd -- <output_dir>
## A -s script compiles before the autoloads exist, so GameState is looked up at runtime.

## [file name, map id, setup]. Setups: "sea_at" (boat at a sea cell), or "arrive" (sail in
## from the sea at a water level).
const SHOTS: Array = [
	["1_sea_off_st_aud", &"sea", {"sea_at": Vector2i(24, 14), "heading": PI}],
	["2_sea_west_islands", &"sea", {"sea_at": Vector2i(17, 15), "heading": PI / 2.0}],
	["3_st_aud_flooded_aboard", &"st_aud", {"arrive": &"flooded"}],
	["4_greenterrace_dry_ashore", &"greenterrace", {"arrive": &"dry"}],
	["5_greenterrace_flooded_aboard", &"greenterrace", {"arrive": &"flooded"}],
	["6_spire_nine_aboard", &"spire_nine", {"arrive": &"sea"}],
]


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else "user://captures"
	DirAccess.make_dir_recursive_absolute(out_dir)
	var game_state: Node = root.get_node("GameState")
	for shot: Array in SHOTS:
		var map_id: StringName = shot[1]
		var setup: Dictionary = shot[2]
		game_state.call(&"clear")
		game_state.call(&"new_game")
		if setup.has("sea_at"):
			game_state.call(&"set_boat", WorldPaths.SEA_ID, setup["sea_at"], setup["heading"])
			game_state.call(&"begin_voyage", WorldPaths.SEA_ID, &"")
		else:
			game_state.call(&"set_water_level", map_id, setup["arrive"])
			game_state.call(&"set_boat", WorldPaths.SEA_ID, Vector2i(21, 22), 0.0, map_id)
			game_state.call(&"begin_voyage", map_id, WorldPaths.SEA_ID)
		var scene: Node = (load(WorldPaths.scene_for(map_id)) as PackedScene).instantiate()
		root.add_child(scene)
		await _frames(45)
		var path: String = out_dir.path_join("%s.png" % shot[0])
		var error: Error = root.get_texture().get_image().save_png(path)
		print("tools/capture_world: %s (%s)" % [path, error_string(error)])
		scene.queue_free()
		await _frames(2)
	quit()


func _frames(count: int) -> void:
	for i: int in count:
		await process_frame
