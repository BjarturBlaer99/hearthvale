extends SceneTree
## Saves screenshots of an area with the hero at a few spots, for reviewing a build without
## playing it. Needs a window (not --headless):
##   godot --path . -s res://tools/capture.gd -- <output_dir>
## A -s script compiles before the autoloads exist, so GameState is looked up at runtime.

## [file name, area id, hero cell, facing, damage in half hearts, action]. Actions: "" (none),
## "talk" (to what is in front), "swing" (the sword, caught mid-swing), and with the bow, arrows
## and bombs in hand: "menu" (the item menu open), "shoot" (an arrow in flight), "bomb" (lit);
## "flag:<name>" sets that flag first (a door already opened); "gaze" waits for a boss's eye to
## open; "pause" opens the pause menu and "settings" the settings from it; "accept" talks and
## takes the first answer twice (accepting a quest); "questlog" starts the quests, moves them on
## a little and opens the quest log; "take" picks up what lies underfoot (the hero holds it up);
## "walk" catches the hero mid-stride; "fall" takes every heart; in the crypt, "lantern" gives
## the Lantern, "sunk" shows the Trench with its block already in, "pit" walks the hero into a
## pit, "haunt" lets the Shade come, and "braziers" lights its hall. The area id "title"
## shows the title screen instead of an area ("finished": with a finished game saved, in a
## slot of its own), and "ending" the ending screen (after two quests and an hour and a bit of
## play). Every shot is taken at noon (NOON), unless its action is "time:<HH:MM>".
## "energy:<n>" leaves the hero with that much energy; "collapse" takes it all (he is caught
## lying where he fell, and never gets home: nothing is saved). "food_menu" opens the item menu
## with food in hand and a bar half spent; "cook" faces the hearth with the makings of tea.
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
	["48_title_screen", &"title", Vector2i.ZERO, Vector2.DOWN, 0, ""],
	["49_pause_menu", &"keep", Vector2i(22, 30), Vector2.UP, 1, "pause"],
	["50_settings", &"village", Vector2i(23, 20), Vector2.DOWN, 0, "settings"],
	["51_the_end", &"keep", Vector2i(22, 14), Vector2.UP, 0, "flag:keep_warden_beaten"],
	["52_village_market", &"village", Vector2i(28, 23), Vector2.UP, 0, ""],
	["53_village_field_and_chickens", &"village", Vector2i(16, 30), Vector2.LEFT, 0, ""],
	["54_village_washing_line_and_nook", &"village", Vector2i(3, 25), Vector2.UP, 0, ""],
	["55_fields_shepherd_and_plateau", &"north_fields", Vector2i(25, 23), Vector2.UP, 0, ""],
	["56_cistern_secret_room", &"cistern", Vector2i(22, 29), Vector2.UP, 0, "flag:dungeon/cistern/door/secret_wall"],
	["57_old_wood_fireflies", &"old_wood", Vector2i(6, 18), Vector2.UP, 0, ""],
	["58_wenna_has_a_problem", &"weaver_house", Vector2i(7, 4), Vector2.UP, 0, "talk"],
	["59_a_new_quest", &"weaver_house", Vector2i(7, 4), Vector2.UP, 0, "accept"],
	["60_the_shuttle_by_the_stream", &"north_fields", Vector2i(32, 8), Vector2.RIGHT, 0, ""],
	["61_quest_log", &"village", Vector2i(23, 20), Vector2.DOWN, 0, "questlog"],
	["62_holding_up_the_sword", &"village", Vector2i(6, 29), Vector2.RIGHT, 0, "take"],
	["63_walking", &"village", Vector2i(23, 17), Vector2.LEFT, 0, "walk"],
	["64_fallen", &"south_field", Vector2i(12, 12), Vector2.LEFT, 0, "fall"],
	["65_chapel_door_barred", &"village", Vector2i(23, 7), Vector2.UP, 0, ""],
	["66_chapel_door_open", &"village", Vector2i(23, 7), Vector2.UP, 0, "flag:keep_warden_beaten"],
	["67_crypt_narthex", &"crypt", Vector2i(22, 41), Vector2.UP, 0, ""],
	["68_crypt_trench", &"crypt", Vector2i(33, 38), Vector2.RIGHT, 0, ""],
	["69_crypt_trench_bridged", &"crypt", Vector2i(36, 37), Vector2.RIGHT, 0, "sunk"],
	["70_crypt_falling", &"crypt", Vector2i(35, 38), Vector2.RIGHT, 0, "pit"],
	["71_crypt_hall", &"crypt", Vector2i(22, 30), Vector2.UP, 0, ""],
	["72_crypt_lanterns_tomb", &"crypt", Vector2i(38, 27), Vector2.RIGHT, 0, ""],
	["73_crypt_dark_path_no_lantern", &"crypt", Vector2i(37, 19), Vector2.UP, 0, ""],
	["74_crypt_dark_path", &"crypt", Vector2i(37, 19), Vector2.UP, 0, "lantern"],
	["75_crypt_knights_tomb", &"crypt", Vector2i(37, 7), Vector2.UP, 0, "lantern"],
	["76_crypt_ossuary", &"crypt", Vector2i(11, 38), Vector2.LEFT, 0, "lantern"],
	["77_crypt_broken_floor", &"crypt", Vector2i(10, 28), Vector2.LEFT, 0, "lantern"],
	["78_crypt_reliquary", &"crypt", Vector2i(7, 16), Vector2.UP, 0, "lantern"],
	["79_the_shade_haunts", &"crypt", Vector2i(22, 19), Vector2.UP, 0, "haunt"],
	["80_the_shade_bound", &"crypt", Vector2i(22, 19), Vector2.UP, 0, "braziers"],
	["81_bram_tells_the_tale", &"elder_house", Vector2i(5, 4), Vector2.UP, 0, "tale"],
	["82_the_chapel_plaque", &"village", Vector2i(21, 7), Vector2.UP, 0, "talk"],
	["83_the_wardens_plaque", &"keep", Vector2i(20, 42), Vector2.UP, 0, "talk"],
	["84_the_narthex_inscription", &"crypt", Vector2i(24, 41), Vector2.DOWN, 0, "talk"],
	["85_aldrics_epitaph", &"crypt", Vector2i(36, 6), Vector2.UP, 0, "lantern_talk"],
	["86_the_ending", &"ending", Vector2i.ZERO, Vector2.DOWN, 0, ""],
	["87_title_after_the_ending", &"title", Vector2i.ZERO, Vector2.DOWN, 0, "finished"],
	["88_the_reliquarys_stone", &"crypt", Vector2i(8, 24), Vector2.UP, 0, "lantern_talk"],
	["89_village_at_dawn", &"village", Vector2i(23, 20), Vector2.DOWN, 0, "time:06:00"],
	["90_village_at_dusk", &"village", Vector2i(23, 20), Vector2.DOWN, 0, "time:18:45"],
	["91_village_at_nightfall", &"village", Vector2i(23, 20), Vector2.DOWN, 0, "time:20:00"],
	["92_village_at_night", &"village", Vector2i(23, 20), Vector2.DOWN, 0, "time:23:30"],
	["93_north_rise_at_night", &"village", Vector2i(24, 9), Vector2.UP, 0, "time:22:00"],
	["94_fields_at_night", &"north_fields", Vector2i(20, 20), Vector2.DOWN, 0, "time:01:00"],
	["95_a_house_at_night", &"elder_house", Vector2i(5, 6), Vector2.UP, 0, "time:22:00"],
	["96_the_cottage_door", &"village", Vector2i(8, 16), Vector2.UP, 0, ""],
	["97_home", &"home", Vector2i(5, 6), Vector2.UP, 0, ""],
	["98_the_bed_asks", &"home", Vector2i(2, 3), Vector2.LEFT, 0, "talk"],
	["99_a_new_morning", &"home", Vector2i(2, 3), Vector2.LEFT, 3, "sleep"],
	["100_tired", &"village", Vector2i(23, 20), Vector2.DOWN, 0, "energy:18"],
	["101_out_of_energy", &"village", Vector2i(23, 20), Vector2.DOWN, 0, "collapse"],
	["102_wild_berries", &"north_fields", Vector2i(7, 15), Vector2.LEFT, 0, ""],
	["103_mushrooms_in_the_wood", &"old_wood", Vector2i(5, 19), Vector2.LEFT, 0, ""],
	["104_fallen_blossom", &"village", Vector2i(20, 28), Vector2.RIGHT, 0, ""],
	["105_food_in_the_item_menu", &"village", Vector2i(23, 20), Vector2.DOWN, 0, "food_menu"],
	["106_the_hearth_lists_what_to_cook", &"home", Vector2i(5, 2), Vector2.UP, 0, "cook"],
	["107_the_shop_is_shut", &"village", Vector2i(8, 25), Vector2.UP, 0, "shut"],
	["108_monsters_at_night", &"south_field", Vector2i(12, 12), Vector2.LEFT, 0, "time:22:00"],
	["109_lit_windows", &"village", Vector2i(12, 16), Vector2.UP, 0, "time:21:30"],
	["110_the_plot", &"village", Vector2i(15, 17), Vector2.DOWN, 0, ""],
	["111_soil_tilled_and_watered", &"village", Vector2i(14, 20), Vector2.RIGHT, 0, "farm"],
	["112_the_hoe_at_work", &"village", Vector2i(14, 19), Vector2.RIGHT, 0, "hoe"],
	["113_the_tools_at_home", &"home", Vector2i(6, 6), Vector2.DOWN, 0, ""],
	["114_tools_in_the_item_menu", &"village", Vector2i(15, 17), Vector2.DOWN, 0, "tools_menu"],
	["115_filling_the_can_at_the_well", &"village", Vector2i(17, 19), Vector2.RIGHT, 0, "fill"],
]
## The hour every shot is taken at unless it says another: noon, in minutes since midnight.
const NOON: float = 720.0
## The save slot the "finished" title uses, so the player's own save is left alone.
const CAPTURE_SLOT: int = 994


func _initialize() -> void:
	_capture.call_deferred()


func _capture() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	var out_dir: String = args[0] if args.size() > 0 else "user://captures"
	DirAccess.make_dir_recursive_absolute(out_dir)
	var game_state: Node = root.get_node("GameState")
	for shot: Array in SHOTS:
		# Shot numbers after the folder take only those shots: -- <output_dir> 1 30 71
		if args.size() > 1 and not args.slice(1).has(str(shot[0]).get_slice("_", 0)):
			continue
		game_state.call(&"clear")
		game_state.call(&"new_game")
		game_state.call(&"damage", shot[4])
		var clock: RefCounted = game_state.call(&"day_clock")
		game_state.call(&"set_time", float(clock.call(&"in_day", str(shot[5]).trim_prefix("time:"))) if str(shot[5]).begins_with("time:") else NOON)
		if str(shot[5]).begins_with("flag:"):
			game_state.call(&"set_flag", StringName(str(shot[5]).trim_prefix("flag:")), true)
		if shot[5] == "sunk":
			game_state.call(&"set_flag", &"dungeon/crypt/block/trench", "37,36")
		if shot[5] in ["lantern", "haunt", "braziers", "lantern_talk"]:
			game_state.call(&"add_item", &"lantern", 1)
		if shot[5] == "tale":
			game_state.call(&"set_flag", &"keep_warden_beaten", true)
		if shot[1] == &"ending":
			game_state.call(&"add_play_time", 4031.0)
			game_state.call(&"add_heart_container")
			game_state.call(&"add_heart_container")
			for quest: StringName in [&"lost_shuttle", &"slime_bounty"]:
				game_state.call(&"set_flag", StringName("quest/%s/complete" % quest), true)
			var ending: Node = (load("res://ui/ending_screen.tscn") as PackedScene).instantiate()
			root.add_child(ending)
			await _frames(30)
			_save(out_dir, shot[0])
			ending.queue_free()
			await _frames(2)
			continue
		if shot[1] == &"title":
			var saves: Node = root.get_node("SaveSystem")
			var own_slot: int = saves.get(&"current_slot")
			if shot[5] == "finished":
				saves.set(&"current_slot", CAPTURE_SLOT)
				game_state.call(&"add_play_time", 4031.0)
				game_state.call(&"update_player", &"village", Vector2i(23, 20))
				game_state.call(&"set_flag", &"game_finished", true)
				saves.call(&"save_game")
			var title: Node = (load("res://ui/title_screen.tscn") as PackedScene).instantiate()
			root.add_child(title)
			await _frames(30)
			_save(out_dir, shot[0])
			title.queue_free()
			await _frames(2)
			if shot[5] == "finished":
				DirAccess.remove_absolute(str(saves.call(&"slot_path", CAPTURE_SLOT)))
				saves.set(&"current_slot", own_slot)
			continue
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
		if shot[5] == "cook":
			game_state.call(&"add_item", &"cherry_blossom", 4)
		if shot[5] in ["farm", "hoe", "tools_menu", "fill"]:
			# The farm's tools in hand, the can half full; and for "farm" a morning's work done:
			# two rows tilled, the first of them watered.
			for item: Array in [[&"hoe", 1], [&"watering_can", 1], [&"water", 5]]:
				game_state.call(&"add_item", item[0], item[1])
			game_state.call(&"equip", &"watering_can" if shot[5] == "fill" else &"hoe")
			if shot[5] == "farm":
				for x: int in 6:
					for y: int in 2:
						game_state.call(&"till_soil", Vector2i(x, y))
					game_state.call(&"water_soil", Vector2i(x, 0))
		if shot[5] == "shut":
			# An hour after closing: the hero tries the shop's door.
			game_state.call(&"set_time", float(clock.call(&"in_day", "19:00")))
			scene.call(&"interact")
		if shot[5] in ["talk", "accept", "tale", "lantern_talk", "cook"]:
			scene.call(&"interact")
		if shot[5] == "sleep":
			# A night in bed, on a slot of its own, caught as the morning's words show.
			var saves: Node = root.get_node("SaveSystem")
			var own_slot: int = saves.get(&"current_slot")
			saves.set(&"current_slot", CAPTURE_SLOT)
			game_state.call(&"sleep")
			DirAccess.remove_absolute(str(saves.call(&"slot_path", CAPTURE_SLOT)))
			saves.set(&"current_slot", own_slot)
			await _frames(110)
		if shot[5] == "tale":
			scene.get(&"hud").get(&"dialogue").call(&"confirm")
		if shot[5] == "accept":
			for i: int in 2:
				scene.get(&"hud").get(&"dialogue").call(&"confirm")
		if str(shot[5]).begins_with("energy:"):
			game_state.call(&"set_energy", float(str(shot[5]).trim_prefix("energy:")))
		await _frames(30)
		if shot[5] == "collapse":
			# Caught as he lies: the way home is stopped before he can take it.
			scene.set(&"travel", func(_path: String) -> void: pass)
			game_state.call(&"set_energy", 0.0)
			await _frames(24)
			_save(out_dir, shot[0])
			scene.free()
			await _frames(2)
			continue
		if shot[5] == "swing":
			player.call(&"swing")
			await _frames(9)
		elif shot[5] == "take":
			scene.call(&"interact")
			await _frames(4)
		elif shot[5] == "walk":
			# By the clock, like "gaze": a third of a second of walking, whatever the frame rate.
			Input.action_press(&"move_left")
			await create_timer(0.34).timeout
			_save(out_dir, shot[0])
			Input.action_release(&"move_left")
		elif shot[5] == "fall":
			game_state.call(&"damage", 99)
			await _frames(6)
		elif shot[5] == "pit":
			Input.action_press(&"move_right")
			await create_timer(0.5).timeout
			Input.action_release(&"move_right")
		elif shot[5] == "haunt":
			await create_timer(1.6).timeout
		elif shot[5] == "braziers":
			for child: Node in scene.get(&"interactables").get_children():
				if String(child.name).begins_with("ShadeBrazier"):
					child.call(&"light")
			await create_timer(0.5).timeout
		elif shot[5] == "menu":
			scene.call(&"open_item_menu")
			await _frames(2)
		elif shot[5] == "tools_menu":
			scene.call(&"open_item_menu")
			await _frames(2)
		elif shot[5] in ["hoe", "fill"]:
			scene.call(&"use_item")
			await _frames(7)
		elif shot[5] == "food_menu":
			for item: Array in [[&"bow", 1], [&"arrow", 10], [&"bread", 2], [&"wild_berries", 3], [&"blossom_tea", 1]]:
				game_state.call(&"add_item", item[0], item[1])
			game_state.call(&"set_energy", 48.0)
			scene.call(&"open_item_menu")
			await _frames(2)
		elif shot[5] == "shoot":
			scene.call(&"use_item")
			await _frames(18)
		elif shot[5] == "gaze":
			# By the clock, not frames: a fast screen draws many more frames a second.
			await create_timer(3.2).timeout
		elif shot[5] == "questlog":
			var runner: RefCounted = root.get_node("Quests").get(&"runner")
			for quest_id: StringName in [&"lost_shuttle", &"slime_bounty", &"eggs_for_tilda"]:
				runner.call(&"start", quest_id)
			for flag: StringName in [&"eggs_delivered", &"told_oda_eggs"]:
				game_state.call(&"set_flag", flag, true)
			game_state.call(&"add_item", &"weavers_shuttle", 1)
			scene.call(&"open_pause_menu")
			scene.get(&"hud").get(&"pause_menu").call(&"choose", &"quests")
			scene.get(&"hud").get(&"pause_menu").get(&"quest_log").call(&"move_cursor", 1)
			await _frames(2)
		elif shot[5] in ["pause", "settings"]:
			scene.call(&"open_pause_menu")
			if shot[5] == "settings":
				scene.get(&"hud").get(&"pause_menu").call(&"choose", &"settings")
			await _frames(2)
		elif shot[5] == "bomb":
			scene.call(&"use_item")
			player.get(&"motor").call(&"place", shot[2] + Vector2i(0, 2))
			player.call(&"sync_from_motor")
			await _frames(40)
		if shot[5] != "walk":
			_save(out_dir, shot[0])
		paused = false
		scene.queue_free()
		await _frames(2)
	quit()


func _save(out_dir: String, shot_name: String) -> void:
	var path: String = out_dir.path_join("%s.png" % shot_name)
	var error: Error = root.get_texture().get_image().save_png(path)
	print("tools/capture: %s (%s)" % [path, error_string(error)])


func _frames(count: int) -> void:
	for i: int in count:
		await process_frame
