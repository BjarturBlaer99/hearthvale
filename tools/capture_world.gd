extends SceneTree
## Saves screenshots of the boat and travel situations across maps (the sea, arriving at
## districts at different water levels), for reviewing a build without playing it.
## Needs a window (not --headless):
##   godot --path . -s res://tools/capture_world.gd -- <output_dir>
## A -s script compiles before the autoloads exist, so GameState is looked up at runtime.

## [file name, map id, setup]. Setups: "sea_at" (boat at a sea cell), "arrive" (sail in
## from the sea at a water level), or "pump" (pump repaired, drained n times, preview open).
const SHOTS: Array = [
	["1_sea_off_st_aud", &"sea", {"sea_at": Vector2i(24, 14), "heading": PI}],
	["2_sea_west_islands", &"sea", {"sea_at": Vector2i(17, 15), "heading": PI / 2.0}],
	["3_st_aud_flooded_aboard", &"st_aud", {"arrive": &"flooded"}],
	["4_greenterrace_dry_ashore", &"greenterrace", {"arrive": &"dry"}],
	["5_greenterrace_flooded_aboard", &"greenterrace", {"arrive": &"flooded"}],
	["6_spire_nine_aboard", &"spire_nine", {"arrive": &"sea"}],
	["7_pump_preview_first_drain", &"st_aud", {"pump": 0}],
	["8_pump_preview_greenterrace_floods", &"st_aud", {"pump": 1}],
]
const PUMP: StringName = &"st_aud_pump"
const PUMP_CELL: Vector2i = Vector2i(10, 7)


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
		elif setup.has("pump"):
			game_state.call(&"add_item", &"pump_valve", 1)
			game_state.call(&"repair_network_node", PUMP)
			for i: int in int(setup["pump"]):
				var network: WaterNetwork = game_state.call(&"water_network")
				game_state.call(&"apply_water_change", WaterSolver.new().preview(network, PUMP, WaterSolver.LOWER))
		else:
			game_state.call(&"set_water_level", map_id, setup["arrive"])
			game_state.call(&"set_boat", WorldPaths.SEA_ID, Vector2i(21, 22), 0.0, map_id)
			game_state.call(&"begin_voyage", map_id, WorldPaths.SEA_ID)
		var scene: Node = (load(WorldPaths.scene_for(map_id)) as PackedScene).instantiate()
		root.add_child(scene)
		if setup.has("pump"):
			var player: Node = scene.get(&"player")
			(player.get(&"motor") as PlayerMotor).place(PUMP_CELL)
			player.call(&"sync_from_motor")
			await _frames(5)
			scene.call(&"open_network_panel", PUMP)
		await _frames(45)
		var path: String = out_dir.path_join("%s.png" % shot[0])
		var error: Error = root.get_texture().get_image().save_png(path)
		print("tools/capture_world: %s (%s)" % [path, error_string(error)])
		paused = false
		scene.queue_free()
		await _frames(2)
	quit()


func _frames(count: int) -> void:
	for i: int in count:
		await process_frame
