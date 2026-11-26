extends SceneTree
## Saves screenshots of an area with the hero at a few spots, for reviewing a build without
## playing it. Needs a window (not --headless):
##   godot --path . -s res://tools/capture.gd -- <output_dir>
## A -s script compiles before the autoloads exist, so GameState is looked up at runtime.

## [file name, area id, hero cell, facing, damage in half hearts, action]. Actions: "" (none),
## "talk" (to what is in front), "swing" (the sword, caught mid-swing), and with the bow, arrows
## and bombs in hand: "bar" (the item bar, the bow's slot lit), "shoot" (an arrow in flight), "bomb" (lit);
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
## lying where he fell, and never gets home: nothing is saved). "food_menu" opens the food menu (Tab)
## with food in the pack and the energy bar half spent; "cook" faces the hearth with the makings of tea.
## "lights" talks to Elder Bram once a first crop is in; "story_log" opens the quest log of a
## game just begun; "try" tries what the hero faces (the keep's chained gate). The main quest
## has begun before every shot, so its notice is not in each of them, except "begin": a game's
## first moment, with the notice. "skill_up" tills the cell that raises the hero's farming;
## "skills_pause" opens the pause menu with skills at different levels; "cook_menu" opens the
## item menu of a hero at the top level of cooking, with dishes and plain food. With food in
## his pack before Pip: "gift_talk" shows the answer that gives, "gift_list" the list it
## opens, and "gift_given" a gift Pip likes, which makes a first mark. "friends_page" opens the
## pause menu's Friends page with friendships at different marks. "friend:<villager>:<points>"
## talks to whoever the hero faces with that much friendship behind him (a favour asked, a
## recipe taught, a present); "long_log" opens the quest log with eight quests, scrolled;
## "new_dishes" opens the item menu with the three dishes that are taught. Crafting: "workbench"
## opens the workbench's list with some things within reach and some not; "furnished" shows the
## farmhouse with every furnishing made and the furnace burning; "chest" opens the chest's two
## lists; "furnace_talk" asks the cold furnace what to smelt; "boulder" swings the plain Pickaxe at
## a boulder of the homestead, which wants a better one; "sprinkler" shows the plot the
## morning after two sprinklers were set. "shop_ore" opens Tilda's list of what she buys with
## a turnip and a pack from the quarry; "favour:<villager>:<points>" talks to a villager who
## has taught her recipe already, so that at three marks she asks her favour. The Homestead's
## build mode: "build:<x>,<y>" opens it with a stock of placeables and the ghost on that cell
## ("build:<x>,<y>:<slot>" with that slot of the build bar chosen); "yard" shows a yard hedged,
## fenced, gated, floored and furnished east of the farmhouse ("yard_night": after dark, its
## lamp post lit; "yard_hand": in build mode, the hand moving its bench); "saplings" shows an
## oak and a cherry sapling at each age and the hero behind a grown oak; "place_tab" opens the
## workbench's "Place" tab; "shop_land" opens Tilda's list on what she sells for the land.
## "yard_detail" (the warm-ground plan, step 3): the yard, a stone lying on grass with ground
## details round it, and build mode's ghost on another detail.
## The Homestead's buildings (phase 3), "b:<what>": "b:tab" opens the workbench's "Build" tab;
## "b:ghost:<x>,<y>" opens build mode with the Coop's kit and its ghost held at that cell; "b:site"
## shows the Coop's site set down; "b:farm" the farm with every building standing (BUILT) ("b:night":
## the same at 22:00, the windows lit), as do
## "b:fill" (the can filled at the Well), "b:hay" (hay put in the Silo), "b:demolish" (the Coop
## pulled down with a full stack of wood: half its materials back, what doesn't fit at his feet),
## "b:moved" (the Shed moved west, the hero just out of its door) and "b:big" (the Big Coop and
## the Big Barn); "b:room" shows a room bare and "b:shed" the shed furnished, its furnace burning.
## The Homestead's animals (phase 4), "a:<what>", each on the farm of ANIMALS (a coop and a barn
## west of the farmhouse with fenced pastures, the silo east of it, four hens, two sheep and two
## cows, one of each with its product ready): "a:farm" the animals out by day; "a:night" the same
## after dark (in their rooms); "a:oda" Oda's list, a hen just bought; "a:sheep" the hero facing a
## sheep with wool to give; "a:silo" hay put in the silo; "a:hearth" the hearth's list with the
## makings of the three dishes; "a:dishes" the item menu with the three; "a:tilda" Tilda's list of
## what she buys, with the products and cloth; "a:blanket" the wool blanket on the bed;
## "a:weave" the workbench's "Make" tab with wool to weave.
## The Homestead's favours (phase 5), "f:ask:<villager>" and "f:done:<villager>", for Tilda and
## Farmer Oda at three marks, what each teaches or asks at two already done: "ask" talks to them
## as they ask their favour; "done" hands over the six eggs (Tilda), or tells of the coop that
## stands since this morning (Oda), and is caught as they give the reward.
## Film shots (tool polish, 2026-11-19): `-- <output_dir> film [names]` films strokes of work on
## the homestead instead, each a grid of FILM_PICTURES pictures FILM_EVERY seconds apart, cropped
## round the hero and enlarged (a stroke of several blows takes a row of pictures a blow). A film
## is [name, hero cell, facing, what he carries ("hoe", "can", "can_empty", "seed", "sprinkler",
## "pick", "copper_pick", "sword", "ripe"; or the farm of the "a:" shots: "a:sheep" with a sheep
## that has wool before him, "a:hen" with a hen that has nothing, "a:silo" with hay in his pack),
## what he does ("use", "swing" or "interact"), blows].
const FILMS: Array = [
	["hoe_side", Vector2i(24, 18), Vector2.RIGHT, "hoe", "use", 1],
	["hoe_left", Vector2i(26, 18), Vector2.LEFT, "hoe", "use", 1],
	["hoe_down", Vector2i(24, 16), Vector2.DOWN, "hoe", "use", 1],
	["hoe_up", Vector2i(24, 19), Vector2.UP, "hoe", "use", 1],
	["can_pour_side", Vector2i(24, 18), Vector2.RIGHT, "can", "use", 1],
	["can_pour_down", Vector2i(24, 16), Vector2.DOWN, "can", "use", 1],
	["can_pour_up", Vector2i(26, 19), Vector2.UP, "can", "use", 1],
	["can_fill_pond", Vector2i(3, 22), Vector2.RIGHT, "can_empty", "use", 1],
	["seed_plant", Vector2i(24, 18), Vector2.RIGHT, "seed", "use", 1],
	["sprinkler_set", Vector2i(24, 18), Vector2.RIGHT, "sprinkler", "use", 1],
	["sprinkler_down", Vector2i(24, 16), Vector2.DOWN, "sprinkler", "use", 1],
	["pick_rock", Vector2i(34, 9), Vector2.RIGHT, "pick", "use", 2],
	["pick_boulder_copper", Vector2i(13, 7), Vector2.RIGHT, "copper_pick", "use", 3],
	["sword_log", Vector2i(6, 4), Vector2.RIGHT, "sword", "swing", 3],
	["sword_stump", Vector2i(25, 2), Vector2.LEFT, "sword", "swing", 3],
	# The sword's reach (2026-11-25): one swing down into the weeds of the field's column 28,
	# one to the side along row 18, one up and one to the left on open ground.
	["sword_reach_down", Vector2i(28, 16), Vector2.DOWN, "sword", "swing", 1],
	["sword_reach_side", Vector2i(26, 18), Vector2.RIGHT, "sword", "swing", 1],
	["sword_reach_up", Vector2i(34, 13), Vector2.UP, "sword", "swing", 1],
	["sword_reach_left", Vector2i(36, 12), Vector2.LEFT, "sword", "swing", 1],
	["harvest", Vector2i(24, 18), Vector2.RIGHT, "ripe", "interact", 1],
	["take_wool", Vector2i(6, 13), Vector2.RIGHT, "a:sheep", "interact", 1],
	["pet_hen", Vector2i(6, 13), Vector2.RIGHT, "a:hen", "interact", 1],
	["silo_hay", Vector2i(35, 11), Vector2.RIGHT, "a:silo", "interact", 1],
]
const FILM_PICTURES: int = 12
const FILM_EVERY: float = 0.04
## How much of the area round the hero a film's picture shows (px), and how much bigger.
const FILM_CROP: int = 72
const FILM_ZOOM: int = 4
const FILM_COLUMNS: int = 6
const SHOTS: Array = [
	["1_village_square", &"village", Vector2i(23, 20), Vector2.DOWN, 0, ""],
	["2_village_north_rise", &"village", Vector2i(24, 9), Vector2.UP, 0, ""],
	["3_village_doors_hurt", &"village", Vector2i(23, 16), Vector2.UP, 3, ""],
	["4_village_east_meadow", &"village", Vector2i(41, 24), Vector2.RIGHT, 0, ""],
	["5_village_field_and_pond", &"village", Vector2i(20, 29), Vector2.DOWN, 0, ""],
	["6_reading_the_sign", &"village", Vector2i(26, 19), Vector2.UP, 0, "talk"],
	["7_elder_house", &"elder_house", Vector2i(5, 6), Vector2.UP, 0, ""],
	["8_talking_to_bram", &"elder_house", Vector2i(5, 4), Vector2.UP, 0, "lights"],
	["9_weaver_house", &"weaver_house", Vector2i(7, 4), Vector2.UP, 0, ""],
	["10_training_yard", &"village", Vector2i(8, 30), Vector2.RIGHT, 2, ""],
	["11_swinging_at_the_dummy", &"village", Vector2i(9, 29), Vector2.RIGHT, 0, "swing"],
	["12_south_field_slimes", &"south_field", Vector2i(12, 12), Vector2.LEFT, 0, ""],
	["13_goblin_on_the_plateau", &"south_field", Vector2i(31, 13), Vector2.UP, 0, ""],
	["14_bats_by_the_ruin", &"south_field", Vector2i(24, 22), Vector2.RIGHT, 0, ""],
	["15_tildas_shop", &"shop", Vector2i(5, 4), Vector2.UP, 0, "talk"],
	["16_the_item_bar", &"village", Vector2i(23, 20), Vector2.DOWN, 0, "bar"],
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
	["66_chapel_door_open", &"village", Vector2i(23, 7), Vector2.UP, 0, "flag:crypt_open"],
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
	["110_the_plot", &"homestead", Vector2i(25, 16), Vector2.DOWN, 0, ""],
	["111_soil_tilled_and_watered", &"homestead", Vector2i(24, 19), Vector2.RIGHT, 0, "farm"],
	["112_the_hoe_at_work", &"homestead", Vector2i(24, 18), Vector2.RIGHT, 0, "hoe"],
	["113_the_tools_at_home", &"home", Vector2i(6, 6), Vector2.DOWN, 0, ""],
	["114_tools_on_the_item_bar", &"homestead", Vector2i(25, 16), Vector2.DOWN, 0, "tools_bar"],
	["115_filling_the_can_at_the_well", &"village", Vector2i(17, 19), Vector2.RIGHT, 0, "fill"],
	["116_crops_growing_and_ripe", &"homestead", Vector2i(25, 16), Vector2.DOWN, 0, "crops"],
	["117_a_ripe_turnip_to_pick", &"homestead", Vector2i(22, 19), Vector2.UP, 0, "crops"],
	["118_planting_a_seed", &"homestead", Vector2i(27, 19), Vector2.UP, 0, "plant"],
	["119_seeds_on_the_item_bar", &"homestead", Vector2i(25, 16), Vector2.DOWN, 0, "seeds_bar"],
	["120_tildas_list_to_buy_from", &"shop", Vector2i(5, 4), Vector2.UP, 0, "shop_buy"],
	["121_selling_the_harvest", &"shop", Vector2i(5, 4), Vector2.UP, 0, "shop_sell"],
	["122_meals_at_the_hearth", &"home", Vector2i(5, 2), Vector2.UP, 0, "meals"],
	["123_the_story_in_the_quest_log", &"village", Vector2i(23, 20), Vector2.DOWN, 0, "story_log"],
	["124_bram_welcomes_a_newcomer", &"elder_house", Vector2i(5, 4), Vector2.UP, 0, "talk"],
	["125_the_keeps_gate_is_chained", &"old_wood", Vector2i(19, 4), Vector2.UP, 0, "try"],
	["126_the_gate_unchained", &"old_wood", Vector2i(19, 5), Vector2.UP, 0, "flag:keep_gate_open"],
	["127_the_day_the_warden_fell", &"village", Vector2i(23, 7), Vector2.UP, 0, "flag:keep_warden_beaten"],
	["128_a_game_begins", &"village", Vector2i(23, 20), Vector2.DOWN, 0, "begin"],
	["129_a_skill_rises", &"homestead", Vector2i(24, 18), Vector2.RIGHT, 0, "skill_up"],
	["130_skills_in_the_pause_menu", &"village", Vector2i(23, 20), Vector2.DOWN, 0, "skills_pause"],
	["131_a_good_cooks_dishes", &"village", Vector2i(23, 20), Vector2.DOWN, 0, "cook_menu"],
	["132_something_to_give", &"village", Vector2i(27, 25), Vector2.UP, 0, "gift_talk"],
	["133_the_gift_list", &"village", Vector2i(27, 25), Vector2.UP, 0, "gift_list"],
	["134_a_gift_pip_likes", &"village", Vector2i(27, 25), Vector2.UP, 0, "gift_given"],
	["135_the_friends_page", &"village", Vector2i(23, 20), Vector2.DOWN, 0, "friends_page"],
	["136_pip_asks_a_favour", &"village", Vector2i(27, 25), Vector2.UP, 0, "friend:pip:8"],
	["137_wenna_teaches_a_recipe", &"weaver_house", Vector2i(7, 4), Vector2.UP, 0, "friend:wenna:8"],
	["138_a_present_from_tilda", &"shop", Vector2i(5, 4), Vector2.UP, 0, "friend:tilda:16"],
	["139_eight_quests_in_the_log", &"village", Vector2i(23, 20), Vector2.DOWN, 0, "long_log"],
	["140_the_dishes_that_are_taught", &"village", Vector2i(23, 20), Vector2.DOWN, 0, "new_dishes"],
	# Willowmere (2026-11-17): the marsh by day, and after dark with the Bogwisps over its pools.
	["141_willowmere_by_day", &"willowmere", Vector2i(21, 14), Vector2.DOWN, 0, "time:12:00"],
	["142_willowmere_by_night", &"willowmere", Vector2i(21, 14), Vector2.DOWN, 0, "time:22:00"],
	# The Old Quarry (2026-11-17): its mouth in the North Fields, its hall, a floor of each band,
	# and the dark floors with no light and with the Lantern.
	["143_quarry_mouth", &"north_fields", Vector2i(35, 6), Vector2.RIGHT, 0, ""],
	["144_quarry_hall", &"quarry", Vector2i(4, 4), Vector2.DOWN, 0, ""],
	["145_quarry_floor_1", &"quarry_1", Vector2i(9, 2), Vector2.DOWN, 0, ""],
	["146_quarry_floor_5", &"quarry_5", Vector2i(2, 5), Vector2.RIGHT, 0, ""],
	["147_quarry_floor_8_dark", &"quarry_8", Vector2i(11, 2), Vector2.DOWN, 0, ""],
	["148_quarry_floor_8_lantern", &"quarry_8", Vector2i(11, 2), Vector2.DOWN, 0, "lantern"],
	["149_quarry_floor_9_heart", &"quarry_9", Vector2i(16, 2), Vector2.DOWN, 0, "lantern"],
	# Crafting (2026-11-17): the workbench's list in the bare home; the home with all four
	# furnishings and the furnace burning; the chest's two lists; the plot the morning after two
	# sprinklers were set; the cold furnace's list; and fallen wood in the Old Wood. (The home
	# is the farmhouse since the Homestead: shot 151 keeps the name it had.)
	["150_the_workbench_list", &"home", Vector2i(8, 3), Vector2.RIGHT, 0, "workbench"],
	["151_the_cottage_furnished", &"home", Vector2i(5, 5), Vector2.UP, 0, "furnished"],
	["152_the_chest_two_lists", &"home", Vector2i(2, 3), Vector2.UP, 0, "chest"],
	["153_sprinklers_on_the_plot", &"homestead", Vector2i(25, 16), Vector2.DOWN, 0, "sprinkler"],
	["154_the_furnace_asks", &"home", Vector2i(6, 3), Vector2.UP, 0, "furnace_talk"],
	["155_fallen_wood", &"old_wood", Vector2i(24, 8), Vector2.DOWN, 0, ""],
	# The balance pass (mining and crafting, phase 3): what Tilda buys, and the two favours
	# asked at three marks.
	["156_tilda_buys_ore_and_bars", &"shop", Vector2i(5, 4), Vector2.UP, 0, "shop_ore"],
	["157_wenna_asks_for_coal", &"weaver_house", Vector2i(7, 4), Vector2.UP, 0, "favour:wenna:12"],
	["158_edda_asks_for_iron", &"north_fields", Vector2i(25, 22), Vector2.UP, 0, "favour:shepherd_edda:12"],
	# The Homestead (2026-11-18), phase 1: the farm as he comes in by the road; the farmhouse from
	# its yard; the old cottage's door tried; the can filled at the pond; the plain pickaxe at a
	# boulder; the overgrown land west of the house; the farm at night; weeds cut on the field;
	# and the field with its clear corner. (Shots 110 to 119, 129 and 153, which stood at the
	# village's plot, stand at the field's clear corner; 96 and 115 are still in the village:
	# the locked cottage with the lane's west end, and the well.)
	["159_arriving_on_the_farm", &"homestead", Vector2i(37, 14), Vector2.LEFT, 0, ""],
	["160_the_farmhouse_and_its_yard", &"homestead", Vector2i(28, 13), Vector2.UP, 0, ""],
	["161_the_old_cottage_is_locked", &"village", Vector2i(8, 15), Vector2.UP, 0, "try"],
	["162_filling_the_can_at_the_pond", &"homestead", Vector2i(3, 22), Vector2.RIGHT, 0, "fill"],
	["163_a_boulder_wants_a_better_pickaxe", &"homestead", Vector2i(13, 7), Vector2.RIGHT, 0, "boulder"],
	["164_the_overgrown_land", &"homestead", Vector2i(12, 15), Vector2.UP, 0, ""],
	["165_the_farm_at_night", &"homestead", Vector2i(28, 13), Vector2.DOWN, 0, "time:22:00"],
	["166_cutting_weeds_on_the_field", &"homestead", Vector2i(27, 18), Vector2.RIGHT, 0, "swing"],
	["167_the_field_and_its_clear_corner", &"homestead", Vector2i(28, 16), Vector2.DOWN, 0, ""],
	# The Homestead, phase 2 (2026-11-19): build mode with a green ghost and the build bar; a
	# red ghost on the road, with its words; a yard fenced, gated and paved, the hero before
	# its fence; the hero walking through its gate; the yard after dark, its lamp post lit;
	# saplings at each age, and the hero behind a grown oak; the hand moving the yard's bench;
	# the workbench's "Place" tab; and what Tilda sells for the land.
	["168_build_mode_a_green_ghost", &"homestead", Vector2i(30, 13), Vector2.RIGHT, 0, "build:33,12:1"],
	["169_a_red_ghost_on_the_road", &"homestead", Vector2i(30, 13), Vector2.RIGHT, 0, "build:32,14:1"],
	["170_a_fenced_yard_with_paths", &"homestead", Vector2i(33, 14), Vector2.UP, 0, "yard"],
	["171_through_the_gate", &"homestead", Vector2i(34, 13), Vector2.DOWN, 0, "yard"],
	["172_a_lamp_post_at_night", &"homestead", Vector2i(37, 13), Vector2.LEFT, 0, "yard_night"],
	["173_saplings_and_a_grown_tree", &"homestead", Vector2i(34, 12), Vector2.DOWN, 0, "saplings"],
	["174_the_hand_moves_a_bench", &"homestead", Vector2i(37, 13), Vector2.LEFT, 0, "yard_hand"],
	["175_the_workbench_place_tab", &"home", Vector2i(8, 3), Vector2.RIGHT, 0, "place_tab"],
	["176_tilda_sells_for_the_land", &"shop", Vector2i(5, 4), Vector2.UP, 0, "shop_land"],
	# The Homestead, phase 3: buildings.
	["177_the_workbench_build_tab", &"home", Vector2i(8, 3), Vector2.RIGHT, 0, "b:tab"],
	["178_a_kits_ghost_green", &"homestead", Vector2i(30, 13), Vector2.RIGHT, 0, "b:ghost:35,12"],
	["179_a_kits_ghost_red_on_the_road", &"homestead", Vector2i(30, 13), Vector2.RIGHT, 0, "b:ghost:34,15"],
	["180_a_building_site", &"homestead", Vector2i(30, 13), Vector2.RIGHT, 0, "b:site"],
	["181_the_farm_with_every_building", &"homestead", Vector2i(28, 13), Vector2.DOWN, 0, "b:farm"],
	["182_before_the_coops_door", &"homestead", Vector2i(5, 15), Vector2.DOWN, 0, "b:farm"],
	["183_the_well_fills_the_can", &"homestead", Vector2i(21, 13), Vector2.UP, 0, "b:fill"],
	["184_the_silo_takes_hay", &"homestead", Vector2i(34, 12), Vector2.UP, 0, "b:hay"],
	["185_inside_the_coop", &"coop", Vector2i(5, 6), Vector2.UP, 0, "b:room"],
	["186_inside_the_barn", &"barn", Vector2i(5, 6), Vector2.UP, 0, "b:room"],
	["187_inside_the_shed", &"shed", Vector2i(5, 6), Vector2.UP, 0, "b:room"],
	["188_the_shed_furnished", &"shed", Vector2i(5, 5), Vector2.UP, 0, "b:shed"],
	["189_the_big_coop_and_the_big_barn", &"homestead", Vector2i(28, 13), Vector2.DOWN, 0, "b:big"],
	["190_the_shed_moved_and_its_door", &"homestead", Vector2i(15, 18), Vector2.DOWN, 0, "b:moved"],
	["191_a_demolition_and_its_refund", &"homestead", Vector2i(30, 13), Vector2.RIGHT, 0, "b:demolish"],
	# The Homestead's animals (phase 4).
	["192_odas_list", &"village", Vector2i(15, 32), Vector2.UP, 0, "a:oda"],
	["193_hens_in_their_pasture", &"homestead", Vector2i(16, 15), Vector2.UP, 0, "a:farm"],
	["194_sheep_and_cows_in_theirs", &"homestead", Vector2i(12, 16), Vector2.LEFT, 0, "a:farm"],
	["195_inside_the_coop_at_night", &"coop", Vector2i(5, 6), Vector2.UP, 0, "a:night"],
	["196_inside_the_barn_at_night", &"barn", Vector2i(5, 6), Vector2.UP, 0, "a:night"],
	["197_a_sheep_with_wool_to_give", &"homestead", Vector2i(6, 13), Vector2.RIGHT, 0, "a:sheep"],
	["198_the_silo_takes_hay_for_the_herd", &"homestead", Vector2i(35, 11), Vector2.RIGHT, 0, "a:silo"],
	["199_the_hearth_and_the_three_dishes", &"home", Vector2i(5, 2), Vector2.UP, 0, "a:hearth"],
	["200_the_three_dishes", &"home", Vector2i(5, 5), Vector2.UP, 0, "a:dishes"],
	["201_tildas_list_of_what_she_buys", &"shop", Vector2i(5, 4), Vector2.UP, 0, "a:tilda"],
	["202_the_wool_blanket_on_the_bed", &"home", Vector2i(2, 3), Vector2.LEFT, 0, "a:blanket"],
	["203_cloth_at_the_workbench", &"home", Vector2i(8, 3), Vector2.RIGHT, 0, "a:weave"],
	# The Homestead's two favours (phase 5).
	["204_tilda_asks_for_six_eggs", &"shop", Vector2i(5, 4), Vector2.UP, 0, "f:ask:tilda"],
	["205_tilda_has_her_eggs", &"shop", Vector2i(5, 4), Vector2.UP, 0, "f:done:tilda"],
	["206_oda_asks_for_a_coop", &"village", Vector2i(15, 32), Vector2.UP, 0, "f:ask:farmer_oda"],
	["207_oda_hears_the_coop_stands", &"village", Vector2i(15, 32), Vector2.UP, 0, "f:done:farmer_oda"],
	# The tool polish, step 4: the buildings' windows lit at night, and a site's string.
	["208_the_farm_at_night_its_windows_lit", &"homestead", Vector2i(16, 13), Vector2.DOWN, 0, "b:night"],
	# Warmer colours and busier ground, step 3: a stone lying among the ground's details, and the ghost.
	["209_a_stone_and_the_ghost_on_detailed_grass", &"homestead", Vector2i(30, 15), Vector2.DOWN, 0, "yard_detail"],
	# Icons, an axe and the item bar, step I2: the Tab menu's two lists, Food and Pack.
	["210_the_tab_menu_with_a_few_things", &"village", Vector2i(23, 20), Vector2.DOWN, 0, "pack:few:food:0"],
	["211_the_pack_with_a_few_things", &"village", Vector2i(23, 20), Vector2.DOWN, 0, "pack:few:pack:0"],
	["212_the_pack_full_scrolled", &"village", Vector2i(23, 20), Vector2.DOWN, 0, "pack:full:pack:9"],
	["213_tab_with_no_food", &"village", Vector2i(23, 20), Vector2.DOWN, 0, "pack:no_food:pack:0"],
]
## What the Tab menu's shots carry (210 to 213): a few things, a full pack, and no food.
const PACK_STOCK: Dictionary = {
	"few": [[&"wooden_sword", 1], [&"coin", 35], [&"bread", 2], [&"wild_berries", 3], [&"stone", 6]],
	"full": [[&"wooden_sword", 1], [&"coin", 412], [&"bow", 1], [&"arrow", 20], [&"bomb", 5], [&"small_key", 1],
		[&"hoe", 1], [&"watering_can", 1], [&"water", 10], [&"pickaxe", 1], [&"turnip_seeds", 8], [&"bread", 3],
		[&"egg", 4], [&"stone", 40], [&"wood", 25], [&"copper_ore", 7], [&"copper_bar", 2], [&"coal", 5],
		[&"fibre", 12], [&"hay", 8], [&"weavers_shuttle", 1]],
	"no_food": [[&"wooden_sword", 1], [&"coin", 35], [&"hoe", 1], [&"watering_can", 1], [&"water", 10], [&"stone", 6]],
}
## What a build shot carries: enough of each thing for a yard, in the order of the build bar.
const BUILD_STOCK: Array = [[&"fence", 30], [&"gate", 3], [&"dirt_path", 12], [&"stone_path", 20], [&"wood_path", 12],
	[&"wooden_flooring", 12], [&"stone_flooring", 12], [&"hedge", 8], [&"lamp_post", 2], [&"bench", 2],
	[&"flower_bed_red", 2], [&"flower_bed_yellow", 2], [&"flower_bed_blue", 2], [&"oak_sapling", 2], [&"cherry_sapling", 2]]
## The yard of the "yard" shots, east of the farmhouse: [item, the cells it is set down in].
## A hedge along the north of (32..36, 10..13) and a fence round the rest, with a gate in its
## west side and one in its south side; a wooden floor inside with a lamp post and a bench on
## it; a stone path through the south gate and a dirt path from the west gate to the door's
## path; and three flower beds below that.
const YARD: Array = [
	[&"hedge", [Vector2i(32, 10), Vector2i(33, 10), Vector2i(34, 10), Vector2i(35, 10), Vector2i(36, 10)]],
	[&"fence", [Vector2i(32, 11), Vector2i(36, 11), Vector2i(36, 12),
		Vector2i(32, 13), Vector2i(33, 13), Vector2i(35, 13), Vector2i(36, 13)]],
	[&"gate", [Vector2i(32, 12), Vector2i(34, 13)]],
	[&"wooden_flooring", [Vector2i(33, 11), Vector2i(34, 11), Vector2i(35, 11), Vector2i(33, 12), Vector2i(34, 12), Vector2i(35, 12)]],
	[&"stone_path", [Vector2i(34, 13)]],
	[&"dirt_path", [Vector2i(29, 12), Vector2i(30, 12), Vector2i(31, 12), Vector2i(32, 12)]],
	[&"lamp_post", [Vector2i(33, 11)]],
	[&"bench", [Vector2i(35, 11)]],
	[&"flower_bed_red", [Vector2i(29, 13)]],
	[&"flower_bed_yellow", [Vector2i(30, 13)]],
	[&"flower_bed_blue", [Vector2i(31, 13)]],
]
## The "saplings" shot: [item, cell, the mornings it has seen]. An oak at each of its three
## pictures and grown, and a cherry the same, with room to stand behind the grown oak.
const SAPLINGS: Array = [
	[&"oak_sapling", Vector2i(30, 13), 0], [&"oak_sapling", Vector2i(31, 13), 2], [&"oak_sapling", Vector2i(32, 13), 3],
	[&"oak_sapling", Vector2i(34, 13), 4],
	[&"cherry_sapling", Vector2i(30, 16), 0], [&"cherry_sapling", Vector2i(31, 16), 2], [&"cherry_sapling", Vector2i(32, 16), 4],
	[&"cherry_sapling", Vector2i(36, 13), 6],
]
## Where every building stands in the "b:" shots (its top-left corner), on ground cleared for
## them (BUILT_CLEARED): the Silo east of the farmhouse, the Coop, the Barn, the Shed and the
## Well on the land west of it.
const BUILT: Dictionary = {&"coop": Vector2i(3, 12), &"silo": Vector2i(34, 10), &"barn": Vector2i(8, 7),
	&"shed": Vector2i(16, 7), &"well": Vector2i(21, 11)}
const BUILT_CLEARED: Array = [Rect2i(29, 8, 9, 6), Rect2i(3, 6, 23, 8), Rect2i(3, 14, 17, 6)]
## The farm of the "a:" shots: where each building stands, the ground cleared for them, each
## pasture (its ground, and the gate in its fence), the herd in the order bought, and which of
## them has its product ready (the same farm as tools/playtest.gd -- animals).
const ANIMALS: Dictionary = {
	"standing": {&"coop": Vector2i(14, 7), &"barn": Vector2i(4, 7), &"silo": Vector2i(36, 10)},
	"cleared": [Rect2i(29, 8, 9, 6), Rect2i(2, 6, 18, 11), Rect2i(20, 16, 18, 1)],
	"pens": [[Rect2i(13, 10, 6, 4), Vector2i(16, 14)], [Rect2i(3, 11, 8, 5), Vector2i(7, 16)]],
	"herd": [&"chicken", &"chicken", &"chicken", &"chicken", &"sheep", &"sheep", &"cow", &"cow"],
	"ready": [0, 2, 4, 6],
}
## Where "b:moved" moves the Shed.
const SHED_MOVED: Vector2i = Vector2i(13, 15)
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
	if args.size() > 1 and args[1] == "film":
		await _film(out_dir, args.slice(2))
		quit()
		return
	for shot: Array in SHOTS:
		# Shot numbers after the folder take only those shots: -- <output_dir> 1 30 71
		if args.size() > 1 and not args.slice(1).has(str(shot[0]).get_slice("_", 0)):
			continue
		game_state.call(&"clear")
		game_state.call(&"new_game")
		# Every capture's mine rolls the same way, so the same shot shows the same rocks.
		(game_state.call(&"mine") as RefCounted).set(&"number", 1)
		game_state.call(&"damage", shot[4])
		var clock: RefCounted = game_state.call(&"day_clock")
		game_state.call(&"set_time", float(clock.call(&"in_day", str(shot[5]).trim_prefix("time:"))) if str(shot[5]).begins_with("time:") else NOON)
		if str(shot[5]).begins_with("flag:"):
			game_state.call(&"set_flag", StringName(str(shot[5]).trim_prefix("flag:")), true)
		if shot[5] == "lights":
			game_state.call(&"set_flag", &"planted_first_crop", true)
		# The main quest begins by itself: here, where there is no HUD yet to announce it.
		if shot[5] != "begin":
			root.get_node("Quests").call(&"refresh")
		if shot[5] == "sunk":
			game_state.call(&"set_flag", &"dungeon/crypt/block/trench", "37,36")
		if shot[5] in ["lantern", "haunt", "braziers", "lantern_talk"]:
			game_state.call(&"add_item", &"lantern", 1)
		if shot[5] == "tale":
			game_state.call(&"set_flag", &"keep_warden_beaten", true)
		if shot[5] in ["furnished", "chest", "furnace_talk"]:
			# Everything the workbench makes for the home, each in its own place.
			for furnishing: String in ["furnace", "chest", "rug", "lamp"]:
				game_state.call(&"set_flag", StringName("home/%s" % furnishing), true)
		if shot[5] == "furnished":
			game_state.call(&"light_furnace", &"copper_bar", 3)
		if shot[1] == &"ending":
			# A game of seven days: thirty-one crops picked, three friends made.
			for day: int in 6:
				game_state.call(&"start_next_day")
			game_state.call(&"add_tally", &"crops_picked", 31)
			for friend: Array in [[&"pip", 14], [&"wenna", 20], [&"elder_bram", 12], [&"tilda", 7]]:
				game_state.call(&"add_friendship", friend[0], friend[1])
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
				saves.call(&"erase_slot", CAPTURE_SLOT)
				saves.set(&"current_slot", own_slot)
			continue
		if str(shot[5]).begins_with("b:"):
			_set_up_buildings(game_state, str(shot[5]))
		if str(shot[5]).begins_with("a:"):
			_set_up_animals(game_state, str(shot[5]))
		if str(shot[5]).begins_with("f:"):
			_set_up_favour(game_state, str(shot[5]))
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
		if shot[5] in ["bar", "shoot", "bomb"]:
			for item: Array in [[&"bow", 1], [&"arrow", 10], [&"bomb", 3]]:
				game_state.call(&"add_item", item[0], item[1])
			if shot[5] == "bar":
				game_state.call(&"add_item", &"wooden_sword", 1)
				game_state.call(&"set_flag", &"took_wooden_sword", true)
			game_state.call(&"equip", &"bomb" if shot[5] == "bomb" else &"bow")
		if shot[5] == "cook":
			game_state.call(&"add_item", &"cherry_blossom", 4)
		if shot[5] in ["shop_buy", "shop_sell", "meals"]:
			# A purse and a harvest: enough to buy seeds, to sell, and to cook every dish.
			for item: Array in [[&"coin", 34], [&"turnip", 4], [&"carrot", 2], [&"wheat", 6], [&"potato", 2], [&"pumpkin", 1], [&"mushroom", 3]]:
				game_state.call(&"add_item", item[0], item[1])
		if shot[5] in ["crops", "plant", "seeds_bar"]:
			# The plot in the middle of a season: the top row growing, the middle row ripe (a column
			# a crop: turnip, carrot, wheat, potato, pumpkin), and along the bottom a seed just
			# planted, a sprout and a withered crop. The last column is tilled and empty.
			var cells: Dictionary = {}
			var raised: Array = [["turnip", 2, 3], ["carrot", 2, 4], ["wheat", 3, 5], ["potato", 3, 5], ["pumpkin", 4, 8]]
			for x: int in raised.size():
				cells["%d,0" % x] = {"watered": true, "crop": raised[x][0], "stage": raised[x][1]}
				cells["%d,1" % x] = {"watered": false, "crop": raised[x][0], "stage": raised[x][2]}
			cells["0,2"] = {"watered": true, "crop": "carrot", "stage": 0}
			cells["1,2"] = {"watered": true, "crop": "pumpkin", "stage": 1}
			cells["2,2"] = {"watered": false, "crop": "wheat", "stage": 2, "dry": 2, "withered": true}
			for y: int in 3:
				cells["5,%d" % y] = {"watered": y == 0}
			(game_state.call(&"farm") as Farm).load_saved({"cells": cells})
			root.get_node("EventBus").emit_signal(&"farm_changed")
			for item: Array in [[&"hoe", 1], [&"watering_can", 1], [&"water", 6], [&"turnip_seeds", 5], [&"carrot_seeds", 3], [&"pumpkin_seeds", 2], [&"turnip", 4], [&"pumpkin", 1]]:
				game_state.call(&"add_item", item[0], item[1])
			game_state.call(&"equip", &"turnip_seeds")
		if shot[5] == "skill_up":
			# One point short of the second level of farming, with the hoe in hand.
			(game_state.get(&"skill_points") as Dictionary)[&"farming"] = 9
			game_state.call(&"add_item", &"hoe", 1)
			game_state.call(&"equip", &"hoe")
		if shot[5] == "skills_pause":
			for skill: Array in [[&"combat", 30], [&"farming", 55], [&"cooking", 12]]:
				(game_state.get(&"skill_points") as Dictionary)[skill[0]] = skill[1]
		if shot[5] == "cook_menu":
			(game_state.get(&"skill_points") as Dictionary)[&"cooking"] = 90
			for item: Array in [[&"vegetable_stew", 1], [&"roast_turnip", 2], [&"bread", 2], [&"turnip", 3], [&"wild_berries", 4]]:
				game_state.call(&"add_item", item[0], item[1])
			game_state.call(&"set_energy", 30.0)
		if shot[5] in ["gift_talk", "gift_list", "gift_given"]:
			for item: Array in [[&"wild_berries", 4], [&"bread", 2], [&"cherry_blossom", 3], [&"turnip", 2], [&"pumpkin_pie", 1], [&"carrot", 2]]:
				game_state.call(&"add_item", item[0], item[1])
		if str(shot[5]).begins_with("friend:") or str(shot[5]).begins_with("favour:"):
			var parts: PackedStringArray = str(shot[5]).split(":")
			game_state.call(&"add_friendship", StringName(parts[1]), int(parts[2]))
		if str(shot[5]).begins_with("favour:"):
			# The two who teach at two marks and ask at three have taught already (the flags, so
			# that no news of a recipe stands over the picture).
			for recipe: StringName in [&"recipe/berry_jam", &"recipe/shepherds_pie"]:
				game_state.call(&"set_flag", recipe, true)
		if shot[5] == "shop_ore":
			# A turnip, and what a few days in the quarry leave in the pack: she buys the ore, the
			# bars and the crystal, and not the stone, the coal or the wood.
			for item: Array in [[&"coin", 34], [&"turnip", 2], [&"stone", 30], [&"copper_ore", 12], [&"coal", 6], [&"iron_ore", 5],
					[&"gold_ore", 2], [&"crystal", 1], [&"copper_bar", 4], [&"iron_bar", 2], [&"gold_bar", 1], [&"wood", 4]]:
				game_state.call(&"add_item", item[0], item[1])
		if shot[5] == "new_dishes":
			for item: Array in [[&"berry_jam", 2], [&"carrot_cake", 1], [&"shepherds_pie", 1], [&"bread", 1]]:
				game_state.call(&"add_item", item[0], item[1])
			game_state.call(&"set_energy", 30.0)
		if shot[5] == "friends_page":
			# Friendships at every stage: none, a first point, and so on up to a full one.
			var points: Dictionary = {&"elder_bram": 9, &"farmer_oda": 4, &"guard_rolf": 1, &"pip": 20, &"tilda": 13, &"wenna": 17}
			for villager: StringName in points:
				game_state.call(&"add_friendship", villager, points[villager])
		if shot[5] in ["farm", "hoe", "tools_bar", "fill"]:
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
		if str(shot[5]).begins_with("build:") or str(shot[5]).begins_with("yard"):
			for item: Array in BUILD_STOCK:
				game_state.call(&"add_item", item[0], item[1])
		if str(shot[5]).begins_with("yard"):
			for row: Array in YARD:
				for cell: Vector2i in row[1]:
					game_state.call(&"set_down", &"homestead", cell, row[0])
		if shot[5] == "yard_night":
			game_state.call(&"set_time", float(clock.call(&"in_day", "22:00")))
		if shot[5] == "saplings":
			# Each as old as the list says, as if set down that many mornings ago.
			var land: RefCounted = game_state.call(&"homestead")
			for sapling: Array in SAPLINGS:
				land.call(&"set_down", sapling[1], &"standing", sapling[0], sapling[2])
			root.get_node("EventBus").emit_signal(&"homestead_changed")
		if shot[5] == "place_tab":
			# Wood and stone for most of the list, and none of the lamp post's iron or coal.
			for item: Array in [[&"wood", 9], [&"stone", 2]]:
				game_state.call(&"add_item", item[0], item[1])
		if shot[5] == "shop_land":
			game_state.call(&"add_item", &"coin", 34)
		if shot[5] == "boulder":
			# The plain Pickaxe in hand, at a boulder that wants the Copper one.
			game_state.call(&"add_item", &"pickaxe", 1)
			game_state.call(&"equip", &"pickaxe")
		if shot[5] == "workbench":
			# Nine recipes known (Farming and Mining at their second level), six of them within
			# reach: the list scrolls, and the rest are greyed.
			for skill: StringName in [&"farming", &"mining"]:
				(game_state.get(&"skill_points") as Dictionary)[skill] = 10
			for item: Array in [[&"hoe", 1], [&"watering_can", 1], [&"pickaxe", 1], [&"stone", 30], [&"copper_ore", 5], [&"coal", 2],
					[&"wood", 4], [&"copper_bar", 2], [&"wheat", 8], [&"cherry_blossom", 3]]:
				game_state.call(&"add_item", item[0], item[1])
		if shot[5] == "chest":
			# A pack after a day in the mine and on the plot, and a chest with a few days in it.
			for item: Array in [[&"copper_ore", 30], [&"coal", 12], [&"stone", 40], [&"wood", 9], [&"turnip", 6], [&"wheat", 5], [&"bread", 2]]:
				game_state.call(&"add_item", item[0], item[1])
			var chest: RefCounted = game_state.call(&"store")
			for stack: Array in [["copper_ore", 30, 30], ["copper_ore", 12, 30], ["iron_ore", 18, 30], ["copper_bar", 7, 20], ["pumpkin", 3, 20], ["potato", 8, 20]]:
				chest.call(&"put", stack[0], stack[1], stack[2])
		if shot[5] == "furnace_talk":
			for item: Array in [[&"copper_ore", 11], [&"coal", 8], [&"iron_ore", 3]]:
				game_state.call(&"add_item", item[0], item[1])
		if shot[5] == "sprinkler":
			# The whole plot tilled, two sprinklers set, crops beside them and in the corners; then a
			# night goes by. The four cells beside each sprinkler are wet in the morning, and the
			# corners are dry.
			var cells: Dictionary = {}
			for x: int in 6:
				for y: int in 3:
					cells["%d,%d" % [x, y]] = {"watered": false}
			for at: String in ["1,1", "4,1"]:
				cells[at] = {"watered": false, "sprinkler": true}
			for grown: Array in [["0,1", "turnip", 2], ["1,0", "carrot", 2], ["2,1", "turnip", 1], ["1,2", "wheat", 3], ["3,1", "potato", 3],
					["4,0", "pumpkin", 4], ["5,1", "carrot", 1], ["4,2", "turnip", 2], ["0,0", "turnip", 1], ["5,2", "wheat", 2]]:
				cells[grown[0]] = {"watered": true, "crop": grown[1], "stage": grown[2]}
			(game_state.call(&"farm") as Farm).load_saved({"cells": cells})
			game_state.call(&"start_next_day")
			game_state.call(&"set_time", NOON)
			root.get_node("EventBus").emit_signal(&"farm_changed")
			for item: Array in [[&"hoe", 1], [&"watering_can", 1], [&"water", 4], [&"sprinkler", 2]]:
				game_state.call(&"add_item", item[0], item[1])
			game_state.call(&"equip", &"sprinkler")
		if shot[5] == "shut":
			# An hour after closing: the hero tries the shop's door.
			game_state.call(&"set_time", float(clock.call(&"in_day", "19:00")))
			scene.call(&"interact")
		if shot[5] in ["talk", "accept", "tale", "lantern_talk", "cook", "lights", "try", "gift_talk", "gift_list", "gift_given", "furnace_talk"] or str(shot[5]).begins_with("friend:") or str(shot[5]).begins_with("favour:"):
			scene.call(&"interact")
		if str(shot[5]).begins_with("f:"):
			scene.call(&"interact")
			if str(shot[5]).begins_with("f:done:"):
				# Handing over, or telling, is the first answer.
				scene.get(&"hud").get(&"dialogue").call(&"confirm")
		if shot[5] in ["gift_talk", "gift_list", "gift_given"]:
			# The answer that gives is the second of Pip's three.
			scene.get(&"hud").get(&"dialogue").call(&"move_cursor", 1)
			if shot[5] != "gift_talk":
				scene.get(&"hud").get(&"dialogue").call(&"confirm")
			if shot[5] == "gift_given":
				# Berries, which he likes: with the day's first talk that is a first mark.
				scene.get(&"hud").get(&"gift_menu").call(&"confirm")
		if shot[5] == "sleep":
			# A night in bed, on a slot of its own, caught as the morning's words show.
			var saves: Node = root.get_node("SaveSystem")
			var own_slot: int = saves.get(&"current_slot")
			saves.set(&"current_slot", CAPTURE_SLOT)
			game_state.call(&"sleep")
			saves.call(&"erase_slot", CAPTURE_SLOT)
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
		elif shot[5] in ["bar", "tools_bar", "seeds_bar"]:
			# What can be in hand is on the bar at the bottom: nothing to open.
			await _frames(2)
		elif shot[5] in ["shop_buy", "shop_sell"]:
			scene.call(&"open_shop", &"tilda", &"sell" if shot[5] == "shop_sell" else &"buy")
			var counter: Node = scene.get(&"hud").get(&"shop_menu")
			# One deal made, so the line that says so shows; and the cursor moved down the list.
			counter.call(&"move_cursor", 3 if shot[5] == "shop_buy" else 1)
			counter.call(&"confirm")
			await _frames(2)
		elif shot[5] == "shop_ore":
			scene.call(&"open_shop", &"tilda", &"sell")
			var ore_counter: Node = scene.get(&"hud").get(&"shop_menu")
			# A bar of copper sold, so the line that says so shows; the cursor on the bars.
			ore_counter.call(&"move_cursor", 5)
			ore_counter.call(&"confirm")
			await _frames(2)
		elif shot[5] == "meals":
			scene.call(&"interact")
			scene.get(&"hud").get(&"dialogue").call(&"move_cursor", 4)
			await _frames(2)
		elif shot[5] in ["cook_menu", "new_dishes"]:
			scene.call(&"open_item_menu")
			await _frames(2)
		elif str(shot[5]).begins_with("build:"):
			# Build mode open, the ghost on the cell named (and the slot named chosen).
			var build_parts: PackedStringArray = str(shot[5]).split(":")
			var at: PackedStringArray = build_parts[1].split(",")
			scene.call(&"open_build")
			if build_parts.size() > 2:
				scene.get(&"build").call(&"choose_slot", int(build_parts[2]))
			scene.get(&"build").call(&"point_at", Vector2i(int(at[0]), int(at[1])))
			await _frames(3)
		elif shot[5] == "yard_detail":
			await _show_ground_detail(scene)
		elif shot[5] == "yard_hand":
			# Build mode with the hand chosen: the bench lifted, and the ghost where it would go.
			scene.call(&"open_build")
			var hand_mode: Node = scene.get(&"build")
			while hand_mode.get(&"chosen") != &"hand":
				hand_mode.call(&"step", -1)
			hand_mode.call(&"point_at", Vector2i(35, 11))
			hand_mode.call(&"set_down")
			hand_mode.call(&"point_at", Vector2i(34, 12))
			await _frames(3)
		elif str(shot[5]).begins_with("b:"):
			await _act_on_buildings(scene, str(shot[5]))
		elif str(shot[5]).begins_with("a:"):
			await _act_on_animals(scene, str(shot[5]))
		elif shot[5] == "place_tab":
			# The "Place" tab, the cursor on the fence and one made, so the line that says so shows.
			scene.call(&"open_craft")
			var bench_list: Node = scene.get(&"hud").get(&"craft_menu")
			bench_list.call(&"switch_tab", 1)
			bench_list.call(&"move_cursor", 5)
			bench_list.call(&"confirm")
			await _frames(2)
		elif shot[5] == "shop_land":
			# The cursor on the oak sapling and one bought, so the line that says so shows.
			scene.call(&"open_shop", &"tilda", &"buy")
			var land_counter: Node = scene.get(&"hud").get(&"shop_menu")
			land_counter.call(&"move_cursor", 9)
			land_counter.call(&"confirm")
			await _frames(2)
		elif shot[5] == "workbench":
			# The cursor on the chest, which he hasn't the wood for: its needs show what is short.
			scene.call(&"open_craft")
			scene.get(&"hud").get(&"craft_menu").call(&"move_cursor", 1)
			await _frames(2)
		elif shot[5] == "chest":
			# One stack put away, so the line that says so shows.
			scene.call(&"open_store")
			scene.get(&"hud").get(&"store_menu").call(&"move_cursor", 3)
			scene.get(&"hud").get(&"store_menu").call(&"confirm")
			await _frames(2)
		elif shot[5] in ["hoe", "fill", "plant", "boulder"]:
			scene.call(&"use_item")
			await _frames(7)
		elif shot[5] == "skill_up":
			scene.call(&"use_item")
			await _frames(20)
		elif shot[5] == "food_menu":
			for item: Array in [[&"bow", 1], [&"arrow", 10], [&"bread", 2], [&"wild_berries", 3], [&"blossom_tea", 1]]:
				game_state.call(&"add_item", item[0], item[1])
			game_state.call(&"set_energy", 48.0)
			scene.call(&"open_item_menu")
			await _frames(2)
		elif str(shot[5]).begins_with("pack:"):
			# pack:<stock>:<list>:<steps down>: the Tab menu opened over that stock, turned to
			# the list named (if it has two: a capture of the game before step I2 shows Food only).
			var pack_parts: PackedStringArray = str(shot[5]).split(":")
			for item: Array in PACK_STOCK[pack_parts[1]]:
				game_state.call(&"add_item", item[0], item[1])
			game_state.call(&"set_energy", 48.0)
			scene.call(&"open_item_menu")
			var tab_menu: Node = scene.get(&"hud").get(&"item_menu")
			if tab_menu.has_method(&"switch_list") and str(tab_menu.get(&"list")) != pack_parts[2]:
				tab_menu.call(&"switch_list")
			if bool(tab_menu.call(&"is_open")):
				tab_menu.call(&"move_cursor", int(pack_parts[3]))
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
		elif shot[5] == "long_log":
			# Every quest begun, two of them done: eight lines and "Back", the cursor well down.
			var runner: RefCounted = root.get_node("Quests").get(&"runner")
			for quest_id: StringName in [&"lost_shuttle", &"slime_bounty", &"eggs_for_tilda", &"pie_for_pip", &"rations_for_the_watch", &"seed_stock", &"elders_supper"]:
				runner.call(&"start", quest_id)
			for flag: StringName in [&"eggs_delivered", &"told_oda_eggs", &"seed_wheat_given"]:
				game_state.call(&"set_flag", flag, true)
			scene.call(&"open_pause_menu")
			scene.get(&"hud").get(&"pause_menu").call(&"choose", &"quests")
			scene.get(&"hud").get(&"pause_menu").get(&"quest_log").call(&"move_cursor", 5)
			await _frames(2)
		elif shot[5] == "friends_page":
			scene.call(&"open_pause_menu")
			scene.get(&"hud").get(&"pause_menu").call(&"choose", &"friends")
			await _frames(2)
		elif shot[5] == "story_log":
			scene.call(&"open_pause_menu")
			scene.get(&"hud").get(&"pause_menu").call(&"choose", &"quests")
			await _frames(2)
		elif shot[5] in ["pause", "settings", "skills_pause"]:
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


## What a "b:" shot needs before its area loads: ground cleared, materials, the buildings set
## down (and a morning, so they stand), and what is in them.
func _set_up_buildings(game_state: Node, action: String) -> void:
	for patch: Rect2i in BUILT_CLEARED:
		for x: int in range(patch.position.x, patch.end.x):
			for y: int in range(patch.position.y, patch.end.y):
				game_state.call(&"clear_debris", &"homestead", Vector2i(x, y))
	if action == "b:tab":
		# Farming 3 and a copper bar found: every plan is known; enough for the Well and the Silo.
		(game_state.get(&"skill_points") as Dictionary)[&"farming"] = 25
		for item: Array in [[&"stone", 50], [&"wood", 30], [&"fibre", 20], [&"copper_bar", 3], [&"coin", 300]]:
			game_state.call(&"add_item", item[0], item[1])
		return
	if action.begins_with("b:ghost"):
		game_state.call(&"add_item", &"coop_kit", 1)
		return
	if action == "b:site":
		game_state.call(&"add_item", &"coop_kit", 1)
		game_state.call(&"set_down_kit", &"homestead", Vector2i(33, 10), &"coop_kit")
		return
	if action == "b:room":
		return
	if action == "b:shed":
		for flag: StringName in [&"shed/furnace", &"shed/chest_a", &"shed/chest_b"]:
			game_state.call(&"set_flag", flag, true)
		game_state.call(&"light_furnace", &"iron_bar", 3, &"shed")
		return
	for id: StringName in BUILT:
		var kit: StringName = StringName("%s_kit" % id)
		game_state.call(&"add_item", kit, 1)
		game_state.call(&"set_down_kit", &"homestead", BUILT[id], kit)
	game_state.call(&"start_next_day")
	game_state.call(&"set_time", float((game_state.call(&"day_clock") as RefCounted).call(&"in_day", "22:00")) if action == "b:night" else NOON)
	if action == "b:big":
		var land: RefCounted = game_state.call(&"homestead")
		for id: StringName in [&"coop", &"barn"]:
			land.call(&"upgrade", id, game_state.get(&"day"))
		game_state.call(&"start_next_day")
		game_state.call(&"set_time", NOON)
	if action == "b:moved":
		game_state.call(&"move_building", &"homestead", &"shed", SHED_MOVED)
	if action == "b:fill":
		for item: Array in [[&"watering_can", 1], [&"water", 2]]:
			game_state.call(&"add_item", item[0], item[1])
		game_state.call(&"equip", &"watering_can")
	if action == "b:hay":
		game_state.call(&"add_item", &"hay", 12)
	if action == "b:demolish":
		game_state.call(&"add_item", &"wood", 30)
	# The morning's news is not what these shots show.
	game_state.set(&"morning_news", PackedStringArray())


## What a "b:" shot does once its area has loaded.
## A stone lying on a cell of grass that has a detail, and build mode's ghost on another, near
## the hero (the warm-ground plan, step 3): neither shows the detail under it.
func _show_ground_detail(scene: Node) -> void:
	var detail: Node = scene.get(&"ground_detail")
	var height: TileMapLayer = scene.get(&"height_layer")
	var hero: Vector2i = Vector2i(30, 15)
	# Grass with details, below the road and west of the field, nearest the hero first.
	var shown: Array[Vector2i] = []
	for y: int in range(hero.y + 2, hero.y + 8):
		for x: int in range(hero.x - 12, hero.x - 8):
			if height.get_cell_atlas_coords(Vector2i(x, y)) == Vector2i.ZERO and detail.call(&"shown_at", Vector2i(x, y)) != &"":
				shown.append(Vector2i(x, y))
	if shown.size() < 2:
		push_warning("capture: too few ground details near the hero")
		return
	var ghost: Vector2i = shown[1]
	for cell: Vector2i in shown:
		if absi(cell.x - shown[0].x) + absi(cell.y - shown[0].y) >= 2:
			ghost = cell
			break
	var drop: Node2D = load("res://gameplay/interactables/item_drop.gd").new()
	drop.set(&"item_id", &"stone")
	drop.position = Vector2(shown[0] * 16)
	scene.get(&"interactables").add_child(drop)
	scene.call(&"open_build")
	scene.get(&"build").call(&"point_at", ghost)
	await _frames(3)


func _act_on_buildings(scene: Node, action: String) -> void:
	if action == "b:tab":
		# The "Build" tab, the cursor on the Coop, whose needs show what is short.
		scene.call(&"open_craft")
		var bench: Node = scene.get(&"hud").get(&"craft_menu")
		bench.call(&"show_tab", "build")
		bench.call(&"move_cursor", 2)
		await _frames(2)
	elif action.begins_with("b:ghost"):
		var at: PackedStringArray = action.trim_prefix("b:ghost:").split(",")
		scene.call(&"open_build")
		var mode: Node = scene.get(&"build")
		while mode.get(&"chosen") != &"coop_kit":
			mode.call(&"step", 1)
		_point(mode, Vector2i(int(at[0]), int(at[1])))
		await _frames(3)
		_point(mode, Vector2i(int(at[0]), int(at[1])))
		await _frames(1)
	elif action == "b:fill":
		scene.call(&"use_item")
		await _frames(7)
	elif action == "b:hay":
		scene.call(&"interact")
		await _frames(3)
	elif action == "b:demolish":
		scene.call(&"open_build")
		var hand: Node = scene.get(&"build")
		while hand.get(&"chosen") != &"hand":
			hand.call(&"step", 1)
		_point(hand, BUILT[&"coop"] + Vector2i(1, 1))
		await _frames(2)
		_point(hand, BUILT[&"coop"] + Vector2i(1, 1))
		hand.call(&"take_up")
		hand.call(&"take_up")
		await _frames(3)
	else:
		await _frames(2)


## What an "f:" shot needs before its area loads: three marks with Tilda or Oda, what each
## teaches or asks at two done with, and for "done" the favour taken and its want met (six eggs;
## a coop set down yesterday, standing this morning), at noon.
func _set_up_favour(game_state: Node, action: String) -> void:
	var parts: PackedStringArray = action.split(":")
	var who: StringName = StringName(parts[2])
	game_state.call(&"add_friendship", who, 12)
	game_state.call(&"set_flag", &"recipe/carrot_cake", true)
	# Oda's wheat was brought long ago: finished, and nothing said of it now.
	(game_state.get(&"quests") as Dictionary)[&"seed_stock"] = &"done"
	(game_state.get(&"flags") as Dictionary)[&"quest/seed_stock/complete"] = true
	if parts[1] == "done" and who == &"tilda":
		(game_state.get(&"quests") as Dictionary)[&"market_day"] = &"bring"
		game_state.call(&"add_item", &"egg", 6)
	if parts[1] == "done" and who == &"farmer_oda":
		(game_state.get(&"quests") as Dictionary)[&"a_roof_for_the_flock"] = &"build"
		game_state.call(&"add_item", &"coop_kit", 1)
		game_state.call(&"set_down_kit", &"homestead", Vector2i(32, 10), &"coop_kit")
		game_state.call(&"start_next_day")
	var clock: Object = game_state.call(&"day_clock")
	game_state.call(&"set_time", float(clock.call(&"in_day", "12:00")))


## What an "a:" shot needs before its area loads: the farm of ANIMALS, its herd and what each
## has ready, the hour, and what he carries.
func _set_up_animals(game_state: Node, action: String) -> void:
	for patch: Rect2i in ANIMALS["cleared"]:
		for x: int in range(patch.position.x, patch.end.x):
			for y: int in range(patch.position.y, patch.end.y):
				game_state.call(&"clear_debris", &"homestead", Vector2i(x, y))
	var standing: Dictionary = ANIMALS["standing"]
	for building: StringName in standing:
		var kit: StringName = StringName("%s_kit" % building)
		game_state.call(&"add_item", kit, 1)
		game_state.call(&"set_down_kit", &"homestead", standing[building], kit)
	game_state.call(&"start_next_day")
	game_state.set(&"morning_news", PackedStringArray())
	var homestead: RefCounted = game_state.call(&"homestead")
	for pen: Array in ANIMALS["pens"]:
		var ground: Rect2i = pen[0]
		var ring: Rect2i = ground.grow(1)
		for x: int in range(ring.position.x, ring.end.x):
			for y: int in range(ring.position.y, ring.end.y):
				var at: Vector2i = Vector2i(x, y)
				if not ground.has_point(at) and game_state.call(&"building_covering", &"homestead", at) == &"":
					homestead.call(&"set_down", at, &"standing", &"gate" if at == pen[1] else &"fence")
	# Oda's list buys a hen: the coop has room for one more.
	for kind: StringName in (ANIMALS["herd"] as Array).slice(1 if action == "a:oda" else 0):
		homestead.call(&"add_animal", kind)
	for index: int in ANIMALS["ready"]:
		(homestead.call(&"animal", index) as Dictionary)["ready"] = true
	homestead.set(&"hay", 24)
	var clock: RefCounted = game_state.call(&"day_clock")
	game_state.call(&"set_time", float(clock.call(&"in_day", "21:00" if action == "a:night" else "12:00")))
	match action:
		"a:oda":
			game_state.call(&"add_item", &"coin", 300)
		"a:silo":
			game_state.call(&"add_item", &"hay", 12)
		"a:hearth":
			for item: Array in [[&"egg", 4], [&"milk", 1], [&"mushroom", 1]]:
				game_state.call(&"add_item", item[0], item[1])
		"a:dishes":
			for item: Array in [[&"fried_egg", 2], [&"omelette", 1], [&"custard", 1], [&"egg", 3], [&"milk", 1]]:
				game_state.call(&"add_item", item[0], item[1])
			game_state.call(&"set_energy", 40.0)
		"a:tilda":
			for item: Array in [[&"coin", 20], [&"egg", 6], [&"milk", 2], [&"wool", 3], [&"cloth", 2], [&"turnip", 2]]:
				game_state.call(&"add_item", item[0], item[1])
		"a:blanket":
			game_state.call(&"set_flag", &"home/blanket", true)
			game_state.call(&"set_flag", &"home/rug", true)
		"a:weave":
			game_state.call(&"add_item", &"wool", 5)


## What an "a:" shot does once its area has loaded.
func _act_on_animals(scene: Node, action: String) -> void:
	if action == "a:oda":
		scene.call(&"open_shop", &"oda", &"buy")
		scene.get(&"hud").get(&"shop_menu").call(&"confirm")
		await _frames(2)
	elif action in ["a:farm", "a:night"]:
		# Long enough for some of them to wander off where they were put.
		await create_timer(2.5).timeout
	elif action == "a:sheep":
		var herd: Node = scene.get(&"animals")
		var sheep: Node2D = herd.call(&"animal", 4)
		var motion: RefCounted = sheep.get(&"motion")
		motion.set(&"position", Vector2(7 * 16 + 8, 13 * 16 + 8))
		sheep.position = motion.get(&"position")
		herd.set_process(false)
		await _frames(3)
	elif action == "a:silo":
		scene.call(&"interact")
		await _frames(3)
	elif action == "a:hearth":
		scene.call(&"interact")
		# The cursor on the Custard, so the Fried Egg shows beneath it.
		scene.get(&"hud").get(&"dialogue").call(&"move_cursor", 2)
		await _frames(2)
	elif action == "a:dishes":
		scene.call(&"open_item_menu")
		await _frames(2)
	elif action == "a:tilda":
		scene.call(&"open_shop", &"tilda", &"sell")
		var counter: Node = scene.get(&"hud").get(&"shop_menu")
		# A bolt of cloth sold, so the line that says so shows.
		counter.call(&"move_cursor", 4)
		counter.call(&"confirm")
		await _frames(2)
	elif action == "a:weave":
		scene.call(&"open_craft")
		var bench: Node = scene.get(&"hud").get(&"craft_menu")
		bench.call(&"move_cursor", 13)
		bench.call(&"confirm")
		await _frames(2)
	else:
		await _frames(3)


## Puts build mode's ghost on `cell`, and the window's own mouse pointer there too: in a window
## the pointer is real, and wherever it is over the game the ghost goes.
func _point(mode: Node, cell: Vector2i) -> void:
	mode.call(&"point_at", cell)
	var screen: Vector2 = (mode as Node2D).get_global_transform_with_canvas() * (Vector2(cell * 16) + Vector2(8, 8))
	root.warp_mouse(screen)
	mode.call(&"point_at", cell)


## The film shots (FILMS), or only those named.
func _film(out_dir: String, names: PackedStringArray) -> void:
	var game_state: Node = root.get_node("GameState")
	for film: Array in FILMS:
		if not names.is_empty() and not names.has(film[0]):
			continue
		game_state.call(&"clear")
		game_state.call(&"new_game")
		(game_state.call(&"mine") as RefCounted).set(&"number", 1)
		game_state.call(&"set_time", NOON)
		root.get_node("Quests").call(&"refresh")
		_set_up_film(game_state, str(film[3]))
		var scene: Node = (load(WorldPaths.scene_for(&"homestead")) as PackedScene).instantiate()
		root.add_child(scene)
		var player: Node2D = scene.get(&"player")
		(player.get(&"motor") as PlayerMotor).place(film[1])
		player.call(&"face", film[2])
		# The new hero's camera is the one that shows, whatever was there before.
		player.get_node("Camera2D").call(&"make_current")
		# An animal of the herd put before him (a sheep with wool, a hen with nothing), held still.
		if str(film[3]) in ["a:sheep", "a:hen"]:
			var herd: Node = scene.get(&"animals")
			var animal: Node2D = herd.call(&"animal", 4 if film[3] == "a:sheep" else 1)
			var motion: RefCounted = animal.get(&"motion")
			motion.set(&"position", Vector2((film[1] + Vector2i(1, 0)) * 16) + Vector2(8, 8))
			animal.position = motion.get(&"position")
			herd.set_process(false)
		await _frames(30)
		var pictures: Array[Image] = []
		for blow: int in int(film[5]):
			match str(film[4]):
				"use":
					scene.call(&"use_item")
				"swing":
					player.call(&"swing")
				"interact":
					scene.call(&"interact")
			for i: int in FILM_PICTURES:
				await create_timer(FILM_EVERY).timeout
				pictures.append(_film_picture(player))
			await create_timer(0.15).timeout
		_save_film(pictures, out_dir.path_join("film_%s.png" % film[0]))
		scene.queue_free()
		await _frames(3)


## What a film's hero carries and the plot he works: the plot's clear corner tilled where he
## faces it, a ripe turnip for "ripe".
func _set_up_film(game_state: Node, what: String) -> void:
	if what.begins_with("a:"):
		_set_up_animals(game_state, "a:silo" if what == "a:silo" else "a:farm")
		return
	match what:
		"hoe":
			game_state.call(&"add_item", &"hoe", 1)
			game_state.call(&"equip", &"hoe")
		"pick", "copper_pick":
			var pick: StringName = &"pickaxe" if what == "pick" else &"copper_pickaxe"
			game_state.call(&"add_item", pick, 1)
			game_state.call(&"equip", pick)
		"sword":
			game_state.call(&"add_item", &"wooden_sword", 1)
			game_state.call(&"set_flag", &"took_wooden_sword", true)
		_:
			for item: Array in [[&"hoe", 1], [&"watering_can", 1], [&"turnip_seeds", 3], [&"sprinkler", 1]]:
				game_state.call(&"add_item", item[0], item[1])
			if what == "can":
				game_state.call(&"add_item", &"water", 5)
			for cell: Vector2i in [Vector2i(3, 1), Vector2i(2, 0), Vector2i(2, 1), Vector2i(4, 1), Vector2i(4, 2)]:
				game_state.call(&"till_soil", cell)
			if what == "ripe":
				(game_state.call(&"farm") as Farm).load_saved({"cells": {"3,1": {"watered": true, "crop": "turnip", "stage": 3}}})
				root.get_node("EventBus").emit_signal(&"farm_changed")
			var equip: Dictionary = {"can": &"watering_can", "can_empty": &"watering_can", "seed": &"turnip_seeds", "sprinkler": &"sprinkler", "ripe": &"hoe"}
			game_state.call(&"equip", equip[what])


## The picture on screen round the hero, enlarged FILM_ZOOM times.
func _film_picture(player: Node2D) -> Image:
	var image: Image = root.get_texture().get_image()
	var scale: int = maxi(1, image.get_width() / 640)
	var size: int = FILM_CROP * scale
	var corner: Vector2i = Vector2i(player.get_global_transform_with_canvas().origin * scale) - Vector2i(size / 2, size * 5 / 8)
	corner.x = clampi(corner.x, 0, image.get_width() - size)
	corner.y = clampi(corner.y, 0, image.get_height() - size)
	var part: Image = image.get_region(Rect2i(corner, Vector2i(size, size)))
	part.resize(FILM_CROP * FILM_ZOOM, FILM_CROP * FILM_ZOOM, Image.INTERPOLATE_NEAREST)
	part.convert(Image.FORMAT_RGBA8)
	return part


func _save_film(pictures: Array[Image], path: String) -> void:
	var side: int = FILM_CROP * FILM_ZOOM
	var grid: Image = Image.create(FILM_COLUMNS * (side + 4), ceili(pictures.size() / float(FILM_COLUMNS)) * (side + 4), false, Image.FORMAT_RGBA8)
	grid.fill(Color(0.1, 0.1, 0.1))
	for i: int in pictures.size():
		grid.blit_rect(pictures[i], Rect2i(Vector2i.ZERO, Vector2i(side, side)), Vector2i((i % FILM_COLUMNS) * (side + 4), (i / FILM_COLUMNS) * (side + 4)))
	print("tools/capture: %s (%s)" % [path, error_string(grid.save_png(path))])


func _save(out_dir: String, shot_name: String) -> void:
	var path: String = out_dir.path_join("%s.png" % shot_name)
	var error: Error = root.get_texture().get_image().save_png(path)
	print("tools/capture: %s (%s)" % [path, error_string(error)])


func _frames(count: int) -> void:
	for i: int in count:
		await process_frame
