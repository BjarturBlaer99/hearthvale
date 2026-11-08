extends SceneTree
## Saves screenshots of an area with the hero at a few spots, for reviewing a build without
## playing it. Needs a window (not --headless):
##   godot --path . -s res://tools/capture.gd -- <output_dir>
## A -s script compiles before the autoloads exist, so GameState is looked up at runtime.

## [file name, area id, hero cell, facing, damage in half hearts, action]. Actions: "" (none),
## "talk" (to what is in front), "swing" (the sword, caught mid-swing), and with the bow, arrows
## and bombs in hand: "menu" (the item menu open), "shoot" (an arrow in flight), "bomb" (lit);
## "flag:<name>" sets that flag first (a door already opened); "gaze" waits for a boss's eye to
## open.
const SHOTS: Array = [
	["1_village_square", &"village", Vector2i(23, 20), Vector2.DOWN, 0, ""],
	["2_village_north_rise", &"village", Vector2i(24, 9), Vector2.UP, 0, ""],
	["3_village_doors_hurt", &"village", Vector2i(23, 16), Vector2.UP, 3, ""],
	["4_village_east_meadow", &"village", Vector2i(41, 24), Vector2.RIGHT, 0, ""],
	["5_village_field_and_pond", &"village", Vector2i(20, 29), Vector2.DOWN, 0, ""],
	["6_reading_the_sign", &"village", Vector2i(26, 19), Vector2.UP, 0, "talk"],
	["7_elder_house", &"elder_house", Vector2i(5, 6), Vector2.UP, 0, ""],
	["8_talking_to_bram", &"elder_house", Vector2i(5, 4), Vector2.UP, 0, "talk"],
	["9_weaver_house", &"weaver_house", Vector2i(7, 4), Vector2.UP, 0, ""],
	["10_training_yard", &"village", Vector2i(8, 30), Vector2.RIGHT, 2, ""],
	["11_swinging_at_the_dummy", &"village", Vector2i(9, 29), Vector2.RIGHT, 0, "swing"],
	["12_south_field_slimes", &"south_field", Vector2i(12, 12), Vector2.LEFT, 0, ""],
	["13_goblin_on_the_plateau", &"south_field", Vector2i(31, 13), Vector2.UP, 0, ""],
	["14_bats_by_the_ruin", &"south_field", Vector2i(24, 22), Vector2.RIGHT, 0, ""],
	["15_tildas_shop", &"shop", Vector2i(5, 4), Vector2.UP, 0, "talk"],
	["16_item_menu", &"village", Vector2i(23, 20), Vector2.DOWN, 0, "menu"],
	["17_shooting_the_bow", &"south_field", Vector2i(20, 12), Vector2.RIGHT, 0, "shoot"],
	["18_a_lit_bomb", &"south_field", Vector2i(20, 12), Vector2.DOWN, 0, "bomb"],
	["19_stairway_in_the_ruin", &"south_field", Vector2i(31, 21), Vector2.UP, 0, ""],
	["20_cellar_entry_hall", &"ruin_cellar", Vector2i(7, 27), Vector2.UP, 0, ""],
	["21_cellar_hall", &"ruin_cellar", Vector2i(7, 18), Vector2.UP, 0, "flag:dungeon/ruin_cellar/door/hall_door"],
	["22_cistern_push_room", &"cistern", Vector2i(4, 28), Vector2.UP, 0, ""],
	["23_cistern_plate_room", &"cistern", Vector2i(5, 15), Vector2.LEFT, 0, ""],
	["24_cistern_switch_room", &"cistern", Vector2i(22, 17), Vector2.UP, 0, ""],
	["25_cistern_cracked_wall", &"cistern", Vector2i(17, 5), Vector2.LEFT, 0, ""],
	["26_cistern_combined_room", &"cistern", Vector2i(7, 8), Vector2.LEFT, 0, ""],
	["27_village_keep_road", &"village", Vector2i(36, 4), Vector2.UP, 0, ""],
	["28_keep_entrance", &"keep", Vector2i(22, 41), Vector2.UP, 0, ""],
	["29_keep_guard_room", &"keep", Vector2i(12, 38), Vector2.LEFT, 0, ""],
	["30_keep_great_hall", &"keep", Vector2i(22, 30), Vector2.UP, 0, ""],
	["31_keep_plate_room", &"keep", Vector2i(12, 27), Vector2.LEFT, 0, ""],
	["32_keep_armoury", &"keep", Vector2i(7, 19), Vector2.UP, 0, ""],
	["33_keep_gallery", &"keep", Vector2i(7, 8), Vector2.UP, 0, ""],
	["34_keep_twin_crystals", &"keep", Vector2i(32, 27), Vector2.RIGHT, 0, ""],
	["35_keep_big_key_room", &"keep", Vector2i(37, 20), Vector2.UP, 0, ""],
	["36_keep_old_store", &"keep", Vector2i(32, 38), Vector2.RIGHT, 0, ""],
	["37_the_warden_wakes", &"keep", Vector2i(22, 20), Vector2.UP, 0, ""],
	["38_the_wardens_eye_opens", &"keep", Vector2i(22, 20), Vector2.UP, 0, "gaze"],
	["39_the_warden_beaten", &"keep", Vector2i(22, 18), Vector2.UP, 0, "flag:keep_warden_beaten"],
	["40_fields_road_in", &"north_fields", Vector2i(20, 25), Vector2.UP, 0, ""],
	["41_fields_bridge", &"north_fields", Vector2i(15, 12), Vector2.UP, 0, ""],
	["42_fields_plateau", &"north_fields", Vector2i(24, 18), Vector2.RIGHT, 0, ""],
	["43_fields_hidden_meadow", &"north_fields", Vector2i(6, 5), Vector2.LEFT, 0, ""],
	["44_wood_road", &"old_wood", Vector2i(11, 19), Vector2.UP, 0, ""],
	["45_wood_keep_gate", &"old_wood", Vector2i(19, 8), Vector2.UP, 0, ""],
	["46_wood_shrine", &"old_wood", Vector2i(27, 13), Vector2.RIGHT, 0, ""],
	["47_wood_shrine_opened", &"old_wood", Vector2i(31, 13), Vector2.RIGHT, 0, "flag:dungeon/old_wood/door/shrine_wall"],
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
		if str(shot[5]).begins_with("flag:"):
			game_state.call(&"set_flag", StringName(str(shot[5]).trim_prefix("flag:")), true)
		var scene: Node = (load(WorldPaths.scene_for(shot[1])) as PackedScene).instantiate()
		root.add_child(scene)
		var player: Node = scene.get(&"player")
		var motor: PlayerMotor = player.get(&"motor")
		motor.place(shot[2])
		player.call(&"face", shot[3])
		if scene.has_method(&"update_room"):
			scene.call(&"update_room")
		if shot[5] == "swing":
			game_state.call(&"add_item", &"wooden_sword", 1)
			game_state.call(&"set_flag", &"took_wooden_sword", true)
		if shot[5] in ["menu", "shoot", "bomb"]:
			for item: Array in [[&"bow", 1], [&"arrow", 10], [&"bomb", 3]]:
				game_state.call(&"add_item", item[0], item[1])
			game_state.call(&"equip", &"bomb" if shot[5] == "bomb" else &"bow")
		if shot[5] == "talk":
			scene.call(&"interact")
		await _frames(30)
		if shot[5] == "swing":
			player.call(&"swing")
			await _frames(9)
		elif shot[5] == "menu":
			scene.call(&"open_item_menu")
			await _frames(2)
		elif shot[5] == "shoot":
			scene.call(&"use_item")
			await _frames(18)
		elif shot[5] == "gaze":
			await _frames(170)
		elif shot[5] == "bomb":
			scene.call(&"use_item")
			player.get(&"motor").call(&"place", shot[2] + Vector2i(0, 2))
			player.call(&"sync_from_motor")
			await _frames(40)
		var path: String = out_dir.path_join("%s.png" % shot[0])
		var error: Error = root.get_texture().get_image().save_png(path)
		print("tools/capture: %s (%s)" % [path, error_string(error)])
		scene.queue_free()
		await _frames(2)
	quit()


func _frames(count: int) -> void:
	for i: int in count:
		await process_frame
