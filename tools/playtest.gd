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
## after the scenario's name starts it at that time of day, energy=<n> with that much energy,
## and skills=<level> with every skill at that level: -- village 19:30 energy=12 skills=3
## A scenario's "flags" came true long ago (no day is kept for them); its "today" flags came
## true this very day, for what waits a day on them (the crypt's bars). "day" is the day it is
## (the plot wakes that many mornings), "friends" the points of friendship with villagers, and
## "skills" the level of each skill it names (the rest begin at 1). "cleared" are rectangles of
## its area's cells whose overgrowth is gone already (the homestead's).
const SCENARIOS: Dictionary = {
	# A late day: the sixth morning at home, the keep quiet and the crypt open, every villager
	# one liked gift short of two marks (when four ask a favour and three teach a recipe), and a
	# pack to give, cook and fight with. Add skills=3 for skills to match.
	"late": {
		"area": &"home",
		"cell": Vector2i(5, 5),
		"day": 6,
		"items": [[&"wooden_sword", 1], [&"bow", 1], [&"arrow", 20], [&"bomb", 5], [&"lantern", 1], [&"hoe", 1], [&"watering_can", 1],
			[&"coin", 60], [&"wild_berries", 6], [&"bread", 4], [&"pumpkin_pie", 2], [&"vegetable_stew", 2], [&"blossom_tea", 2],
			[&"cherry_blossom", 4], [&"mushroom_soup", 2], [&"carrot", 4], [&"wheat", 6], [&"pumpkin", 2], [&"potato", 2],
			[&"turnip", 3], [&"mushroom", 2]],
		"flags": [&"took_wooden_sword", &"took_hoe", &"took_watering_can", &"took_first_seeds", &"planted_first_crop",
			&"promised_elder_keep", &"keep_gate_open", &"keep_warden_beaten"],
		"friends": {&"elder_bram": 5, &"wenna": 5, &"tilda": 5, &"farmer_oda": 5, &"pip": 5, &"guard_rolf": 5, &"shepherd_edda": 5},
	},
	# In Hearthvale beside Pip, with a pack of things to give: something each villager likes and
	# plenty they don't. Elder Bram, Wenna and Tilda are indoors; Oda and Rolf stand in the
	# village; Edda is in the North Fields. One gift a villager a day: the bed at home ends one.
	"gifts": {
		"area": &"village",
		"cell": Vector2i(27, 26),
		"items": [[&"wooden_sword", 1], [&"wild_berries", 5], [&"bread", 3], [&"pumpkin_pie", 2], [&"vegetable_stew", 1],
			[&"blossom_tea", 2], [&"cherry_blossom", 4], [&"mushroom_soup", 2], [&"carrot", 3], [&"wheat", 3], [&"pumpkin", 1],
			[&"turnip", 4]],
		"flags": [&"took_wooden_sword", &"took_hoe", &"took_watering_can", &"took_first_seeds", &"planted_first_crop"],
	},
	# In Elder Bram's house with the tools taken and a first seed counted as planted: his quest
	# opens. The promise takes the chain off the keep's gate.
	"bram": {
		"area": &"elder_house",
		"cell": Vector2i(5, 6),
		"items": [[&"hoe", 1], [&"watering_can", 1], [&"turnip_seeds", 4]],
		"flags": [&"took_hoe", &"took_watering_can", &"took_first_seeds", &"planted_first_crop"],
	},
	# In the Old Wood below the keep's gate, with a sword but without Elder Bram's word: the
	# gate is chained.
	"gate": {
		"area": &"old_wood",
		"cell": Vector2i(19, 7),
		"items": [[&"wooden_sword", 1]],
		"flags": [&"took_wooden_sword", &"took_hoe", &"took_watering_can", &"took_first_seeds", &"planted_first_crop"],
	},
	# By the chapel's door on the day the Warden fell: the bars are down until he has slept (his
	# farmhouse is out the lane's west end, on his own land).
	"rest": {
		"area": &"village",
		"cell": Vector2i(23, 8),
		"items": [[&"wooden_sword", 1], [&"bow", 1], [&"arrow", 20], [&"bomb", 5]],
		"flags": [&"took_wooden_sword", &"took_hoe", &"took_watering_can", &"took_first_seeds", &"planted_first_crop",
			&"promised_elder_keep", &"keep_gate_open"],
		"today": [&"keep_warden_beaten"],
	},
	# At home by the hearth, a little tired, with bread, berries and the makings of tea: for
	# trying food and cooking.
	"kitchen": {
		"area": &"home",
		"cell": Vector2i(5, 3),
		"items": [[&"cherry_blossom", 4], [&"bread", 2], [&"wild_berries", 4], [&"coin", 20], [&"turnip", 3], [&"carrot", 1],
			[&"wheat", 3], [&"potato", 2], [&"pumpkin", 1], [&"mushroom", 2]],
		"flags": [],
	},
	# On the homestead's road above the field's clear corner, with the hoe, the watering can
	# (empty: the pond is in the south-west corner of the land), seeds of every crop and a sword:
	# for trying the farm. The bed in the farmhouse, up the path, ends a day.
	"farm": {
		"area": &"homestead",
		"cell": Vector2i(25, 15),
		"items": [[&"wooden_sword", 1], [&"hoe", 1], [&"watering_can", 1], [&"turnip_seeds", 5], [&"carrot_seeds", 3],
			[&"wheat_seeds", 3], [&"potato_seeds", 3], [&"pumpkin_seeds", 2], [&"coin", 30]],
		"flags": [&"took_wooden_sword", &"took_hoe", &"took_watering_can", &"took_first_seeds"],
	},
	# Arriving on the homestead by the lane from Hearthvale, with a sword and all three pickaxes
	# (the plain one for rocks, the Copper for boulders, the Iron for great boulders), the hoe,
	# the can and a few seeds: for trying the land, clearing it, and the farm's two tunes (add an
	# hour for the night's: -- homestead 20:30).
	"homestead": {
		"area": &"homestead",
		"cell": Vector2i(37, 14),
		"items": [[&"wooden_sword", 1], [&"pickaxe", 1], [&"copper_pickaxe", 1], [&"iron_pickaxe", 1], [&"hoe", 1],
			[&"watering_can", 1], [&"turnip_seeds", 5], [&"bread", 3], [&"coin", 30]],
		"flags": [&"took_wooden_sword", &"took_hoe", &"took_watering_can", &"took_first_seeds"],
	},
	# On the homestead east of the farmhouse's door, where the ground is cleared (columns 29 to
	# 37, rows 8 to 13, and the strip below the road), with a stock of everything that can be set
	# down: for trying build mode. B opens it; the mouse points at a cell and the movement keys
	# move the ghost; a left click sets down and a right click takes up; the wheel and 1 to 9
	# choose (the hand, the bar's first slot, lifts a thing to move it); B, Tab or Esc leave.
	# A sword too, to clear more ground; wood, stone and coins for the workbench's "Place" tab
	# (in the farmhouse) and Tilda's hedges, flower beds and saplings. A lamp post lights at
	# 18:30 (-- build 18:20), and a sapling grows a stage with the bed's mornings.
	"build": {
		"area": &"homestead",
		"cell": Vector2i(30, 13),
		"items": [[&"wooden_sword", 1], [&"fence", 40], [&"gate", 4], [&"dirt_path", 20], [&"stone_path", 20], [&"wood_path", 20],
			[&"wooden_flooring", 20], [&"stone_flooring", 20], [&"hedge", 12], [&"lamp_post", 4], [&"bench", 2],
			[&"flower_bed_red", 4], [&"flower_bed_yellow", 4], [&"flower_bed_blue", 4], [&"oak_sapling", 3], [&"cherry_sapling", 2],
			[&"wood", 20], [&"stone", 20], [&"coin", 60]],
		"flags": [&"took_wooden_sword", &"took_hoe", &"took_watering_can", &"took_first_seeds"],
		"cleared": [Rect2i(29, 8, 9, 6), Rect2i(20, 16, 18, 1)],
	},
	# On the homestead with the coins, materials and skill to buy every building's plan at the
	# workbench (in the farmhouse, up the path), and the yard east of the house and the land west
	# of it cleared for them (the Homestead, phase 3). A pack's stack holds only so much (wood 30,
	# stone and fibre 50): the farmhouse's chest holds the rest. Bought, a plan is a kit: B opens
	# build mode, where it is set down; the bed brings the morning that finishes it. The hand
	# lifts a building to move it; a right click on one asks, and a second pulls it down. A sword,
	# and the hay the Silo takes, from the meadow's tall grass in the north-west.
	"buildings": {
		"area": &"homestead",
		"cell": Vector2i(30, 13),
		"items": [[&"wooden_sword", 1], [&"wood", 30], [&"stone", 50], [&"fibre", 50], [&"copper_bar", 10], [&"iron_bar", 10],
			[&"gold_bar", 4], [&"copper_ore", 10], [&"coin", 999]],
		"flags": [&"took_wooden_sword", &"took_hoe", &"took_watering_can", &"took_first_seeds", &"home/chest"],
		"chest": [[&"wood", 30], [&"wood", 30], [&"wood", 30], [&"wood", 30], [&"stone", 50], [&"stone", 50], [&"stone", 50], [&"fibre", 20]],
		"skills": {&"farming": 3},
		"cleared": [Rect2i(29, 8, 9, 6), Rect2i(3, 6, 23, 8), Rect2i(3, 14, 17, 6), Rect2i(20, 16, 18, 1)],
	},
	# The same farm the morning after every building was set down: the Coop and the Silo east of
	# the farmhouse, the Barn, the Shed and the Well west of it (the Homestead, phase 3). Their
	# doors lead into their rooms; the shed's chests and furnace are on the workbench's "Build"
	# tab; the can fills at the Well and the Silo takes hay. Materials and coins for the two
	# upgrades and the shed's furnishings.
	"built": {
		"area": &"homestead",
		"cell": Vector2i(28, 13),
		"items": [[&"wooden_sword", 1], [&"watering_can", 1], [&"hay", 12], [&"wood", 30], [&"stone", 50], [&"fibre", 20],
			[&"copper_bar", 4], [&"iron_bar", 4], [&"gold_bar", 2], [&"copper_ore", 10], [&"coin", 999]],
		"flags": [&"took_wooden_sword", &"took_hoe", &"took_watering_can", &"took_first_seeds"],
		"cleared": [Rect2i(29, 8, 9, 6), Rect2i(3, 6, 23, 8), Rect2i(3, 14, 17, 6), Rect2i(20, 16, 18, 1)],
		"standing": {&"coop": Vector2i(32, 9), &"silo": Vector2i(36, 10), &"barn": Vector2i(8, 7), &"shed": Vector2i(16, 7), &"well": Vector2i(21, 11)},
	},
	# On a farm with animals (the Homestead, phase 4): the Coop and the Barn west of the farmhouse,
	# each with a fenced pasture before its door and a gate in it, the Silo east of the house with
	# hay in it. Four hens, two sheep and two cows, out in their pastures by day and in their
	# rooms from 20:00 (-- animals 21:00); one of each kind has its egg, wool or milk ready. A
	# right click pets an animal and takes what it has. Farmer Oda's stall (in the village, by
	# her field) sells more; the hearth cooks the eggs and milk, and Tilda buys them.
	"animals": {
		"area": &"homestead",
		"cell": Vector2i(16, 15),
		"items": [[&"wooden_sword", 1], [&"hay", 12], [&"mushroom", 4], [&"fence", 10], [&"gate", 2], [&"coin", 600]],
		"flags": [&"took_wooden_sword", &"took_hoe", &"took_watering_can", &"took_first_seeds"],
		"cleared": [Rect2i(29, 8, 9, 6), Rect2i(2, 6, 18, 11), Rect2i(20, 16, 18, 1)],
		"standing": {&"coop": Vector2i(14, 7), &"barn": Vector2i(4, 7), &"silo": Vector2i(36, 10)},
		"pens": [[Rect2i(13, 10, 6, 4), Vector2i(16, 14)], [Rect2i(3, 11, 8, 5), Vector2i(7, 16)]],
		"animals": [&"chicken", &"chicken", &"chicken", &"chicken", &"sheep", &"sheep", &"cow", &"cow"],
		"ready": [0, 4, 6],
		"hay": 30,
	},
	# In Tilda's shop at her counter, with coins and a harvest: for trying her list. (Start it by
	# day: the shop is shut from 18:00 to 08:00, and he could not get back in.)
	"market": {
		"area": &"shop",
		"cell": Vector2i(5, 4),
		"items": [[&"wooden_sword", 1], [&"hoe", 1], [&"watering_can", 1], [&"coin", 40], [&"turnip", 6], [&"carrot", 3],
			[&"wheat", 4], [&"potato", 2], [&"pumpkin", 1]],
		"flags": [&"took_wooden_sword", &"took_hoe", &"took_watering_can", &"took_first_seeds"],
	},
	# At home, by the door: for trying the bed.
	"home": {
		"area": &"home",
		"cell": Vector2i(5, 6),
		"items": [],
		"flags": [],
	},
	# In the village square at the start of the game, with nothing: for watching a day go by.
	"village": {
		"area": &"village",
		"cell": Vector2i(23, 20),
		"items": [],
		"flags": [],
	},
	# In Willowmere, just off the walk from Hearthvale, with a sword and the Lantern, a bowl of
	# stew, and room for what grows there. Old Henrik is one liked gift short of two marks, when
	# he asks his favour. Add an hour for the marsh after dark: -- marsh 19:30
	"marsh": {
		"area": &"willowmere",
		"cell": Vector2i(3, 14),
		"items": [[&"wooden_sword", 1], [&"lantern", 1], [&"marsh_stew", 1], [&"bread", 2]],
		"flags": [&"took_wooden_sword", &"took_hoe", &"took_watering_can", &"took_first_seeds", &"planted_first_crop"],
		"friends": {&"old_henrik": 5},
	},
	# In the Old Quarry's entrance hall with a Pickaxe, a sword and bread: for trying the mine
	# from the top. (The lift has been nowhere yet.)
	"quarry": {
		"area": &"quarry",
		"cell": Vector2i(2, 3),
		"items": [[&"wooden_sword", 1], [&"pickaxe", 1], [&"bread", 5], [&"coin", 20]],
		"flags": [&"took_wooden_sword", &"took_hoe", &"took_watering_can", &"took_first_seeds", &"planted_first_crop"],
	},
	# On floor 7 of the quarry by its ladder, where the dark begins, with the Lantern, food, and
	# the lift open to floors 4 and 7: for trying the deep floors and their Bogwisps.
	"deep": {
		"area": &"quarry_7",
		"cell": Vector2i(8, 1),
		"items": [[&"wooden_sword", 1], [&"pickaxe", 1], [&"lantern", 1], [&"bread", 5], [&"vegetable_stew", 2]],
		"flags": [&"took_wooden_sword", &"took_hoe", &"took_watering_can", &"took_first_seeds", &"planted_first_crop",
			&"quarry/lift/4", &"quarry/lift/7"],
	},
	# At home by the workbench, with what the mine and the fields give: stone and copper ore for the
	# furnace, ore and coal to smelt, bars for the chest, the lamp, a sprinkler and the first tool
	# upgrades, wheat and blossoms for the rug, and the Lantern, a gold bar and a crystal for the
	# Miner's Lantern. Farming 2 and Mining 3, so every recipe is on the list. The furnace takes a
	# night: the bed is by the west wall. The field is out of the door and across the road.
	"craft": {
		"area": &"home",
		"cell": Vector2i(8, 3),
		"items": [[&"wooden_sword", 1], [&"hoe", 1], [&"watering_can", 1], [&"pickaxe", 1], [&"lantern", 1],
			[&"stone", 30], [&"copper_ore", 14], [&"coal", 10], [&"iron_ore", 9], [&"wood", 14],
			[&"copper_bar", 6], [&"iron_bar", 3], [&"gold_bar", 1], [&"crystal", 1],
			[&"wheat", 8], [&"cherry_blossom", 3], [&"turnip_seeds", 4], [&"bread", 3], [&"coin", 20]],
		"flags": [&"took_wooden_sword", &"took_hoe", &"took_watering_can", &"took_first_seeds", &"planted_first_crop"],
		"skills": {&"farming": 2, &"mining": 3},
	},
	# At the keep's entrance, with Elder Bram's word given: the wooden sword and nothing else, as a
	# hero first walks in (harder dungeons, 2026-11-23: for trying its rooms from the start).
	"keep": {
		"area": &"keep",
		"cell": Vector2i(22, 42),
		"items": [[&"wooden_sword", 1], [&"bread", 3]],
		"flags": [&"took_wooden_sword", &"planted_first_crop", &"promised_elder_keep", &"keep_gate_open"],
	},
	# Outside the Iron Warden's hall: sword, bow, 20 arrows, the boss door already open.
	"warden": {
		"area": &"keep",
		"cell": Vector2i(22, 24),
		"items": [[&"wooden_sword", 1], [&"bow", 1], [&"arrow", 20]],
		"flags": [&"took_wooden_sword", &"planted_first_crop", &"promised_elder_keep", &"keep_gate_open",
			&"dungeon/keep/big_key", &"dungeon/keep/door/boss_door"],
	},
	# At the top of the crypt's stairs, as after the keep: sword, bow, arrows and bombs.
	"crypt": {
		"area": &"crypt",
		"cell": Vector2i(22, 42),
		"items": [[&"wooden_sword", 1], [&"bow", 1], [&"arrow", 20], [&"bomb", 5]],
		"flags": [&"took_wooden_sword", &"planted_first_crop", &"promised_elder_keep", &"keep_gate_open", &"keep_warden_beaten"],
	},
	# In the Shade's hall with the Shade beaten: step up to the heart container for the ending.
	"ending": {
		"area": &"crypt",
		"cell": Vector2i(22, 16),
		"items": [[&"wooden_sword", 1], [&"iron_sword", 1], [&"bow", 1], [&"arrow", 20], [&"lantern", 1]],
		"flags": [&"took_wooden_sword", &"planted_first_crop", &"promised_elder_keep", &"keep_gate_open", &"keep_warden_beaten",
			&"crypt_shade_beaten", &"dungeon/crypt/big_key", &"dungeon/crypt/door/boss_door"],
	},
	# Outside the Crypt Shade's hall: the Lantern and the Iron Sword, the boss door already open.
	"shade": {
		"area": &"crypt",
		"cell": Vector2i(22, 24),
		"items": [[&"wooden_sword", 1], [&"iron_sword", 1], [&"bow", 1], [&"arrow", 20], [&"lantern", 1]],
		"flags": [&"took_wooden_sword", &"planted_first_crop", &"promised_elder_keep", &"keep_gate_open", &"keep_warden_beaten",
			&"dungeon/crypt/big_key", &"dungeon/crypt/door/boss_door"],
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
	# The save, its backup and anything half written: a scenario starts with none of them.
	saves.call(&"erase_slot", PLAYTEST_SLOT)
	print("tools/playtest: '%s'. Saving here goes to slot %d, not your own game." % [scenario_name, PLAYTEST_SLOT])
	var game_state: Node = root.get_node("GameState")
	game_state.call(&"new_game")
	for item: Array in scenario["items"]:
		game_state.call(&"add_item", item[0], item[1])
	for day: int in int(scenario.get("day", 1)) - 1:
		game_state.call(&"start_next_day")
	var friends: Dictionary = scenario.get("friends", {})
	for villager: StringName in friends:
		game_state.call(&"add_friendship", villager, friends[villager])
	for flag: StringName in scenario["flags"]:
		game_state.call(&"set_flag", flag, true)
	# Ground cleared before he came: its weeds, logs and rocks are gone for good.
	for patch: Rect2i in scenario.get("cleared", []):
		for x: int in range(patch.position.x, patch.end.x):
			for y: int in range(patch.position.y, patch.end.y):
				game_state.call(&"clear_debris", scenario["area"], Vector2i(x, y))
	# What the farmhouse's chest holds, and buildings that stood before he came (the Homestead):
	# each set down, and a morning come.
	for stack: Array in scenario.get("chest", []):
		(game_state.call(&"store") as RefCounted).call(&"put", String(stack[0]), int(stack[1]), int(stack[1]))
	var standing: Dictionary = scenario.get("standing", {})
	for building: StringName in standing:
		var kit: StringName = StringName("%s_kit" % building)
		game_state.call(&"add_item", kit, 1)
		game_state.call(&"set_down_kit", scenario["area"], standing[building], kit)
	if not standing.is_empty():
		game_state.call(&"start_next_day")
		game_state.set(&"morning_news", PackedStringArray())
	# Pastures fenced before he came, each a ring of fences round its ground (but where a
	# building stands) with a gate; the animals, the silo's hay, and what each has ready (the
	# Homestead, phase 4).
	var homestead: RefCounted = game_state.call(&"homestead")
	for pen: Array in scenario.get("pens", []):
		var ground: Rect2i = pen[0]
		var ring: Rect2i = ground.grow(1)
		for x: int in range(ring.position.x, ring.end.x):
			for y: int in range(ring.position.y, ring.end.y):
				var at: Vector2i = Vector2i(x, y)
				if ground.has_point(at) or game_state.call(&"building_covering", scenario["area"], at) != &"":
					continue
				homestead.call(&"set_down", at, &"standing", &"gate" if at == pen[1] else &"fence")
	for kind: StringName in scenario.get("animals", []):
		homestead.call(&"add_animal", kind)
	for index: int in scenario.get("ready", []):
		(homestead.call(&"animal", index) as Dictionary)["ready"] = true
	if scenario.has("hay"):
		homestead.set(&"hay", int(scenario["hay"]))
	# Those came true long ago: no day is kept for them, so nothing waits a day on them.
	(game_state.get(&"flag_days") as Dictionary).clear()
	for flag: StringName in scenario.get("today", []):
		game_state.call(&"set_flag", flag, true)
	# A scenario's own skills: each at the level named, with just the points that level begins at.
	var levels: Dictionary = scenario.get("skills", {})
	for skill: StringName in levels:
		var rules: Skills = game_state.call(&"skills")
		(game_state.get(&"skill_points") as Dictionary)[skill] = rules.thresholds[clampi(int(levels[skill]), 1, rules.top_level()) - 1]
	for arg: String in args.slice(1):
		if DayClock.parse(arg) >= 0:
			game_state.call(&"set_time", float((game_state.call(&"day_clock") as DayClock).in_day(arg)))
			print("tools/playtest: starting at %s." % arg)
		elif arg.begins_with("energy=") and arg.trim_prefix("energy=").is_valid_float():
			game_state.call(&"set_energy", float(arg.trim_prefix("energy=")))
			print("tools/playtest: starting with %s energy." % arg.trim_prefix("energy="))
		elif arg.begins_with("skills=") and arg.trim_prefix("skills=").is_valid_int():
			# Every skill at that level: each has just the points the level begins at.
			var skills: Skills = game_state.call(&"skills")
			var level: int = clampi(int(arg.trim_prefix("skills=")), 1, skills.top_level())
			for skill: StringName in skills.ids():
				(game_state.get(&"skill_points") as Dictionary)[skill] = skills.thresholds[level - 1]
			print("tools/playtest: starting with every skill at level %d." % level)
	game_state.call(&"update_player", scenario["area"], scenario["cell"])
	change_scene_to_file("res://world/areas/%s/%s.tscn" % [scenario["area"], scenario["area"]])


## The whole game, from the title screen, on its own save slot, with a log of what happens.
func _start_full(fresh: bool) -> void:
	var saves: Node = root.get_node("SaveSystem")
	saves.set(&"current_slot", FULL_SLOT)
	var save_path: String = str(saves.call(&"slot_path", FULL_SLOT))
	if fresh:
		saves.call(&"erase_slot", FULL_SLOT)
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
