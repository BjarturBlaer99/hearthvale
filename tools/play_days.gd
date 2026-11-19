extends SceneTree
## Plays ten days of Hearthvale in a real window, by pressing real keys and mouse buttons
## while the game runs as it does for a player (mining and crafting, phase 3b:
## docs/progress/mining-crafting-plan.md; taught the farm by the Homestead's phase 5b:
## docs/progress/homestead-plan.md). It starts at the title screen, takes "New game",
## and lives ten days: the plot, Tilda's counter, the Old Quarry, the furnace and the
## workbench, and on the homestead the field cleared, the workbench's "Place" and "Build"
## tabs, buildings set down in build mode, a pen fenced, hens bought from Oda and tended. It looks at the game only to decide what to press (where the rocks, the
## monsters and the walls are, what a list shows: as a player's eyes would), and changes the
## game's state only where its log says SETUP. What it left out is logged as SKIP.
## What it did each day is written to <output dir>/days.json, its log to play_log.txt, and
## pictures beside them. Its save is slot 956, emptied before and after: never the player's
## own game.
##   godot --path . -s res://tools/play_days.gd -- <output dir> [days=10] [speed=1] [deep] [farm] [verbose]
## Needs a window. `speed` runs the game faster than life, for trying the script out; the
## report's run is at 1. `deep` is a trial of the dark floors alone: a hero handed an Iron
## Pickaxe, a sword, the Lantern, bread and the lift's stops goes straight down to floor 7.
## `farm` is a trial of the farm alone: a hero handed the makings of the Well, the Coop and a
## pen clears the field, makes and sets them down, buys hens and tends them for four days.
## A -s script compiles before the autoloads exist, so they are looked up at runtime, and the
## game's nodes are told apart by what they have, never by their classes.

const SLOT: int = 956
const TITLE_SCENE: String = "res://ui/title_screen.tscn"
const TILE: int = 16
const KEYS: Dictionary = {Vector2i.LEFT: KEY_A, Vector2i.RIGHT: KEY_D, Vector2i.UP: KEY_W, Vector2i.DOWN: KEY_S}
const SIDES: Array[Vector2i] = [Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]
## Each area and the one it is left for on the way to the village. (His home is the farmhouse
## on the homestead since 2026-11-18: out of its door is the farm, and the lane leads on to the
## village.)
const TOWARD_VILLAGE: Dictionary = {
	&"home": &"homestead", &"homestead": &"village", &"shop": &"village", &"weaver_house": &"village", &"north_fields": &"village",
	&"quarry": &"north_fields", &"coop": &"homestead", &"barn": &"homestead", &"shed": &"homestead",
}
## Where his plot lies: the field on the homestead. The script works its clear corner and
## leaves the overgrown cells alone (clearing land is not taught to it yet).
const PLOT_AREA: StringName = &"homestead"
## What he eats when he tires, in this order.
const FOODS: Array[StringName] = [&"bread", &"shepherds_pie", &"blossom_tea"]
## His pickaxes, the best first.
const PICKAXES: Array[StringName] = [&"iron_pickaxe", &"copper_pickaxe", &"pickaxe"]
const HOES: Array[StringName] = [&"iron_hoe", &"copper_hoe", &"hoe"]
const CANS: Array[StringName] = [&"iron_watering_can", &"copper_watering_can", &"watering_can"]
## What a rock may hold besides stone.
const ORES: Array[StringName] = [&"copper_ore", &"coal", &"iron_ore", &"gold_ore", &"crystal"]
## What Tilda buys of what the quarry gives, the cheapest first.
const SELLABLE: Array[StringName] = [&"copper_ore", &"iron_ore", &"gold_ore", &"copper_bar", &"crystal", &"iron_bar", &"gold_bar"]
const CROPS: Array[StringName] = [&"turnip", &"wheat", &"carrot", &"potato", &"pumpkin"]
## The energy a blow of the pickaxe never costs more than.
const BLOW: float = 2.0
## How near (px) a monster must be for the sword to reach it, and the frames between swings.
const SWORD_REACH: float = 21.0
const SWING_EVERY: int = 24
## The minute of the day (from the midnight it began on) after which he heads home: 22:00.
const HOME_BY: float = 22.0 * 60.0

var _out: String = ""
var _gs: Node
var _bus: Node
var _saves: Node
var _data: Node
var _lines: PackedStringArray = []
## Everything the script set up by hand or left out, for the report.
var _by_hand: Array[String] = []
var _held: Dictionary = {}
var _started: int = 0
var _frame: int = 0
var _last_swing: int = -1000
var _today: int = 1
var _ctx: String = "walk"
var _days: Array[Dictionary] = []
var _cur: Dictionary = {}
var _energy_was: float = 0.0
var _health_was: int = 0
## Rocks he gave up on (no way to them), by area and cell, for today.
var _given_up: Dictionary = {}
## Whether he ran out of hearts since he came to the floor he is on.
var _fell: bool = false
## Says more of what it does (the word "verbose" on the command line), for chasing its faults.
var _verbose: bool = false
## How many times faster than life the game runs (1 for the report's run).
var _speed: float = 1.0


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	var args: PackedStringArray = OS.get_cmdline_user_args()
	if args.is_empty():
		push_error("tools/play_days: give an output folder.")
		quit(1)
		return
	_out = args[0]
	var days: int = 10
	var speed: float = 1.0
	var farm_alone: bool = false
	for arg: String in args.slice(1):
		if arg.begins_with("days="):
			days = clampi(int(arg.trim_prefix("days=")), 1, 10)
		elif arg.begins_with("speed="):
			speed = clampf(float(arg.trim_prefix("speed=")), 1.0, 8.0)
		elif arg == "verbose":
			_verbose = true
		elif arg == "deep":
			days = 0
		elif arg == "farm":
			days = 0
			farm_alone = true
	DirAccess.make_dir_recursive_absolute(_out)
	_gs = root.get_node("GameState")
	_bus = root.get_node("EventBus")
	_saves = root.get_node("SaveSystem")
	_data = root.get_node("DataRegistry")
	_saves.set(&"current_slot", SLOT)
	_saves.call(&"erase_slot", SLOT)
	_gs.call(&"clear")
	# Faster than life, the game takes more steps a second, each as long as ever: what happens
	# in a step is what happens at life's own speed.
	_speed = speed
	Engine.time_scale = speed
	Engine.physics_ticks_per_second = roundi(60.0 * speed)
	Engine.max_physics_steps_per_frame = maxi(8, ceili(speed) * 4)
	_started = Time.get_ticks_msec()
	physics_frame.connect(_on_physics_frame)
	_bus.connect(&"item_added", _on_item_added)
	_bus.connect(&"energy_changed", _on_energy_changed)
	_bus.connect(&"health_changed", _on_health_changed)
	_bus.connect(&"sound", _on_sound)
	_bus.connect(&"crafted", _on_crafted)
	_bus.connect(&"skill_rose", _on_skill_rose)
	_bus.connect(&"quest_announced", _on_quest_announced)
	_note("START: slot %d, %d days, speed %s" % [SLOT, days, speed])
	if speed != 1.0:
		_by_hand.append("SETUP: the game ran %s times faster than life (a trial run of the script)." % speed)
	await _new_game_from_the_title()
	for day: int in range(1, days + 1):
		if int(_gs.get(&"day")) != day:
			_note("!! it is day %s, not day %d: this day's plan is left out" % [_gs.get(&"day"), day])
			continue
		_begin_day(day)
		match day:
			1: await _day_1()
			2: await _day_2()
			3: await _day_3()
			4: await _day_4()
			5: await _day_5()
			6: await _day_6()
			7: await _day_7()
			8: await _day_8()
			9: await _day_9()
			10: await _day_10()
		await _go_to_bed()
		_end_day()
	if days == 0 and farm_alone:
		await _the_farm_alone()
	elif days == 0:
		await _the_deep_floors_alone()
	_write_out()
	_saves.call(&"erase_slot", SLOT)
	Engine.time_scale = 1.0
	Engine.physics_ticks_per_second = 60
	quit()


## A trial of the dark floors alone, for trying the script out: not one of the eight days.
func _the_deep_floors_alone() -> void:
	_begin_day(1)
	_set_up("a trial of the deep floors: an Iron Pickaxe, a sword, the Lantern, four loaves, Mining at its top level and the lift's two stops were handed to him")
	for item: Array in [[&"iron_pickaxe", 1], [&"wooden_sword", 1], [&"lantern", 1], [&"bread", 4]]:
		_gs.call(&"add_item", item[0], item[1])
	(_gs.get(&"skill_points") as Dictionary)[&"mining"] = 90
	for stop: int in [4, 7]:
		_gs.call(&"set_flag", StringName("quarry/lift/%d" % stop), true)
	await _mine(7, 9, false)
	await _go_to_bed()
	_end_day()


# --- The eight days -----------------------------------------------------------------------

## A first day: the tools by the door, five turnips in the ground, the sword, a lost shuttle
## for the weaver (30 coins), the Pickaxe (25), and the first rocks.
func _day_1() -> void:
	_plan("the plot and a first look at the quarry")
	await _travel_to(&"home")
	for thing: String in ["TurnipSeeds", "Hoe", "WateringCan"]:
		await _pick_up(thing)
	_shot("d1_01_tools_taken")
	await _travel_to(PLOT_AREA)
	await _tend_plot()
	_shot("d1_02_five_turnips")
	await _travel_to(&"village")
	await _pick_up("WoodenSword")
	# The weaver's shuttle: the game's first coins.
	_ctx = "quest"
	await _travel_to(&"weaver_house")
	if await _talk_to("Wenna"):
		await _say("You look troubled.")
		await _say("I'll look for it.")
		await _end_talk()
	await _travel_to(&"north_fields")
	await _pick_up("Shuttle")
	await _travel_to(&"weaver_house")
	if await _talk_to("Wenna"):
		await _say("I found your shuttle.")
		await _end_talk()
	_note("the shuttle is back with Wenna: coins %d" % _count(&"coin"))
	await _shop([[&"pickaxe", 1]], 0, {})
	await _mine(1, 9, true)


## The top floors with the plain pickaxe: copper, stone, and the lift's first stop if he gets
## that far. In the evening the furnace, if he has its makings.
func _day_2() -> void:
	_plan("the quarry: the top floors")
	await _tend_plot()
	await _shop([], 3, _keep())
	await _mine(1, 9, false)
	await _evening_at_home()


## The middle floors: iron and coal, and a first look at the dark below them. A copper
## pickaxe first, if the furnace gave the bars.
func _day_3() -> void:
	_plan("the quarry: the middle floors, and a look at the dark below")
	await _morning_at_home()
	await _tend_plot()
	await _shop([], 3, _keep())
	await _mine(4, 9, false)
	await _evening_at_home()


## A day on the farm: the first turnips are ripe. They are sold, the field is cleared as far
## as his energy goes, the whole of what is clear is tilled and sown, and the Well is made and
## set down if he has its makings.
func _day_4() -> void:
	_plan("the farm: harvest, clear the field, sell, sow, the Well")
	await _farm_day()


## The quarry again with whatever pickaxe he has made by now: from the top down to the last
## floor that has daylight's worth of seeing (he has no Lantern).
func _day_5() -> void:
	_plan("the quarry: floors 1 to 6 with a better pickaxe")
	await _morning_at_home()
	await _tend_animals()
	await _tend_plot()
	await _shop([], 4, _keep())
	await _mine(1, 6, false)
	await _evening_at_home()


## A day on the farm: wood and fibre gathered for the Coop, which is made and set down with a
## pen before its door, if the purse reaches; a better can and hoe, if there are bars to spare.
func _day_6() -> void:
	_plan("the farm: wood and fibre, the Coop and its pen, the plot")
	await _farm_day(false, [&"copper_watering_can", &"copper_hoe"])


## Hens for the coop, if it stands, then the quarry's safe floors.
func _day_7() -> void:
	_plan("hens from Oda, then the quarry: floors 1 to 6")
	await _morning_at_home()
	await _tend_animals()
	await _tend_plot()
	await _shop([], 4, _keep())
	await _buy_hens()
	await _mine(1, 6, false)
	await _evening_at_home()


## A day on the farm: the eggs, the field, whatever building comes next.
func _day_8() -> void:
	_plan("the farm: animals, harvest, clear, sell, build, sow")
	await _farm_day()


## The whole quarry late in the game: the best pickaxe he has made, a high skill, and the
## Lantern (which the story gives him in the crypt).
func _day_9() -> void:
	_plan("the quarry, late: all nine floors with the Lantern")
	await _morning_at_home()
	if _count(&"lantern") == 0 and _count(&"miners_lantern") == 0:
		_set_up("the Lantern is put in his pack on day 9 (in the story it comes from the crypt, the last dungeon)")
		_gs.call(&"add_item", &"lantern", 1)
	if _count(&"iron_pickaxe") == 0:
		_set_up("the Iron Pickaxe is put in his pack on day 9 (he had not made one: %s)" % _carrying())
		for old: StringName in [&"copper_pickaxe", &"pickaxe"]:
			if _count(old) > 0:
				_gs.call(&"add_item", old, -1)
		_gs.call(&"add_item", &"iron_pickaxe", 1)
	await _tend_animals()
	await _tend_plot()
	await _shop([], 4, _keep())
	await _mine(1, 9, false)
	await _evening_at_home()


## The last day: the animals, the harvest, and everything he has left sold at Tilda's.
func _day_10() -> void:
	_plan("the farm, late: animals, harvest, build, sell everything, sow again")
	await _farm_day(true)


## A day on the farm: the furnace and the workbench at dawn, the animals, the harvest, the
## field cleared as far as energy allows, the makings of the next building gathered, Tilda's
## counter (and Oda's stall for hens), the next building made and set down, and the plot sown
## and watered. On the last day (`all`) the ore and bars are sold as well.
func _farm_day(all: bool = false, tools: Array[StringName] = []) -> void:
	await _morning_at_home()
	if not tools.is_empty():
		await _make_things(tools)
	await _tend_animals()
	await _travel_to(PLOT_AREA)
	await _harvest()
	await _clear_land(true, {}, 45.0)
	await _gather_makings()
	# The harvest and the clearing raise his farming: back to the workbench (a sprinkler).
	await _travel_to(&"home")
	await _make_things()
	# On the last day everything is sold: what a building wants is made first.
	if all:
		await _build_what_he_can()
	await _shop_for_seeds(all, _next_goal_coins())
	await _buy_hens()
	await _build_what_he_can()
	await _tend_plot()
	_shot("d%d_the_farm" % _today)
	await _evening_at_home()


## A trial of the farm alone, for trying the script out: not one of the ten days. Five days:
## the makings handed over, a little of the field cleared, the Well, the Coop and a pen made
## and set down; then hens bought and tended.
func _the_farm_alone() -> void:
	_begin_day(1)
	_set_up("a trial of the farm: a sword, the Copper Pickaxe, a hoe and a can, 700 coins, 30 wood, 50 stone, 20 fibre and 2 copper bars were handed to him")
	for item: Array in [[&"wooden_sword", 1], [&"copper_pickaxe", 1], [&"hoe", 1], [&"watering_can", 1], [&"coin", 700], [&"wood", 30],
			[&"stone", 50], [&"fibre", 20], [&"copper_bar", 2], [&"turnip_seeds", 5]]:
		_gs.call(&"add_item", item[0], item[1])
	await _travel_to(PLOT_AREA)
	await _clear_land(true, {}, 60.0)
	await _build_what_he_can()
	await _gather_makings()
	await _build_what_he_can()
	await _tend_plot()
	await _go_to_bed()
	_end_day()
	for day: int in [2, 3, 4, 5]:
		if int(_gs.get(&"day")) != day:
			break
		_begin_day(day)
		await _tend_animals()
		await _buy_hens()
		await _tend_animals()
		await _go_to_bed()
		_end_day()


# --- The farm (the Homestead, phase 5b) ---------------------------------------------------

## The buildings the script makes, in the order it wants them, and where each is set down (its
## top-left corner): the Well beside the field, where it fills the can; the Coop against the
## north woods, where the overgrowth on either side closes most of a pen before its door; the
## Silo east of the farmhouse.
const BUILD_ORDER: Array[StringName] = [&"well", &"coop", &"silo"]
const SITES: Dictionary = {&"well": Vector2i(20, 17), &"coop": Vector2i(17, 2), &"silo": Vector2i(34, 11)}
## Where he stands to set each down: near enough that the ghost can reach it.
const STAND_FOR: Dictionary = {&"well": Vector2i(20, 16), &"coop": Vector2i(22, 8), &"silo": Vector2i(33, 13)}
## The pen before the Coop's door: the cells fenced (the overgrowth closes the rest), and the
## gate he goes in by. Inside are sixteen cells of grass: four hens' worth (a hen grazes four).
const PEN_FENCES: Array[Vector2i] = [Vector2i(24, 3), Vector2i(24, 5), Vector2i(20, 6), Vector2i(21, 6), Vector2i(22, 6), Vector2i(23, 6)]
const PEN_GATE: Vector2i = Vector2i(24, 4)
## The overgrowth that closes the pen: never cleared for its wood or fibre.
const PEN_WALLS: Array[Vector2i] = [Vector2i(16, 5), Vector2i(17, 6), Vector2i(18, 6), Vector2i(19, 6), Vector2i(24, 2)]
## The field (cells of the map), and its clear corner's count of cells.
const FIELD: Rect2i = Rect2i(22, 17, 12, 6)
## What clearing gives, by the kind of debris: the item, so that he goes after what he needs.
const DEBRIS_GIVES: Dictionary = {&"weeds": &"fibre", &"bush": &"fibre", &"log": &"wood", &"farm_stump": &"wood", &"rock": &"stone"}
## The hens he keeps (the Coop holds four).
const HENS: int = 4


## Clears the debris of his land: on the field (`on_field`) everything he has a tool for, the
## nearest first; off it, only what gives something `wanted` still wants ({item: count}), and
## never the overgrowth that closes the pen. He stops when he is down to `reserve` energy and
## has nothing to eat (the plot still wants tilling and watering), or when it is late.
func _clear_land(on_field: bool, wanted: Dictionary = {}, reserve: float = 40.0) -> void:
	if not await _travel_to(&"homestead"):
		return
	_ctx = "clear"
	var gave_up: Dictionary = {}
	var cleared: int = 0
	for turn: int in 200:
		if not _day_is_on() or _area_id() != &"homestead" or float(_gs.get(&"minute")) > HOME_BY - 180.0:
			break
		if not on_field and _short_of(wanted).is_empty():
			break
		var target: Node2D = _next_debris(on_field, _short_of(wanted), gave_up)
		if target == null:
			break
		if float(_gs.get(&"energy")) < reserve + BLOW * 2.0 and not await _keep_fit(reserve + BLOW * 2.0):
			_note("clearing stops: energy %.0f, kept for the plot" % float(_gs.get(&"energy")))
			break
		var cell: Vector2i = _cell_of(target)
		if await _clear_one(target, reserve):
			cleared += 1
			await _gather(true)
		else:
			gave_up[cell] = true
	_ctx = "walk"
	_note("cleared %d on the %s: %d of the field's cells clear, %d cleared on the land in all; %s" % [
		cleared, "field" if on_field else "land", _field_clear(), int(_gs.call(&"homestead").call(&"cleared_count")), _materials_text()])


## The debris to clear next: the nearest he can get to and has a tool for.
func _next_debris(on_field: Variant, wanted: Dictionary, gave_up: Dictionary) -> Node2D:
	var steps: Dictionary = _steps_from(_cell())
	var best: Node2D = null
	var fewest: int = 1 << 30
	for thing: Node2D in _area().call(&"debris"):
		var cell: Vector2i = _cell_of(thing)
		if gave_up.has(cell) or PEN_WALLS.has(cell) or FIELD.has_point(cell) != bool(on_field):
			continue
		var kind: StringName = _debris_kind(thing)
		if not bool(on_field) and not wanted.has(DEBRIS_GIVES.get(kind, &"")):
			continue
		if _tool_for(thing) == &"":
			continue
		var near: int = _steps_to_side(steps, cell)
		if near >= 0 and near < fewest:
			fewest = near
			best = thing
	return best


func _debris_kind(thing: Node2D) -> StringName:
	return StringName(thing.get(&"breakable_id")) if &"breakable_id" in thing else StringName(thing.get(&"kind"))


## What clears `thing`: the sword for what grows and lies, a pickaxe good enough for a rock
## (a boulder wants the copper one, a great boulder the iron one). "" for nothing he has.
func _tool_for(thing: Node2D) -> StringName:
	if &"breakable_id" in thing:
		return &"sword" if _armed() else &""
	match _debris_kind(thing):
		&"boulder":
			return _best([&"iron_pickaxe", &"copper_pickaxe"])
		&"great_boulder":
			return _best([&"iron_pickaxe"])
	return _best(PICKAXES)


## Clears one thing: blows of the sword (Space) or the pickaxe (a left click) until it is gone.
func _clear_one(thing: Node2D, reserve: float) -> bool:
	var here: StringName = _area_id()
	var cell: Vector2i = _cell_of(thing)
	var tool: StringName = _tool_for(thing)
	for blow: int in 10:
		if _area_id() != here or not is_instance_valid(thing) or bool(thing.get(&"broken")):
			break
		if tool != &"sword" and not await _keep_fit(minf(reserve, 20.0) + BLOW):
			return false
		if _front() != cell and not await _stand_by(cell):
			return false
		if tool == &"sword":
			_release_all()
			_key(KEY_SPACE, true)
			await physics_frame
			_key(KEY_SPACE, false)
		else:
			if not await _take_in_hand(tool):
				return false
			await _click(MOUSE_BUTTON_LEFT)
		for frame: int in 40:
			await physics_frame
			if frame > 4 and not bool(_motor().call(&"is_attacking")):
				break
		await _wait(4)
	var gone: bool = _area_id() == here and (not is_instance_valid(thing) or bool(thing.get(&"broken")))
	if gone:
		var kind: String = String(_debris_kind(thing)) if is_instance_valid(thing) else "?"
		(_cur["cleared"] as Dictionary)[kind] = int((_cur["cleared"] as Dictionary).get(kind, 0)) + 1
	return gone


## What of `wanted` ({item: count}) he is still short of: {item: how many more}.
func _short_of(wanted: Dictionary) -> Dictionary:
	var out: Dictionary = {}
	for item: StringName in wanted:
		if _count(item) < int(wanted[item]):
			out[item] = int(wanted[item]) - _count(item)
	return out


## The field's cells that are clear: its clear corner and what has been cleared of the rest.
func _field_clear() -> int:
	var home: RefCounted = _gs.call(&"homestead")
	var clear: int = 18
	for cell: Vector2i in home.call(&"cleared_cells"):
		if FIELD.has_point(cell):
			clear += 1
	return clear


## The materials of the next building he wants (and the pen's wood with the Coop), gathered
## from the land off the field: wood from logs and stumps, fibre from weeds and bushes, stone
## from rocks.
func _gather_makings() -> void:
	var wanted: Dictionary = {}
	var next: StringName = _next_building()
	if next == &"":
		return
	# The next building's makings, and the one after's as far as a stack holds them.
	for id: StringName in _next_buildings(2):
		for need: Dictionary in _recipe(id).get("needs", []):
			var item: StringName = StringName(str(need["item"]))
			if item in [&"wood", &"fibre", &"stone"]:
				var most: int = int(_data.call(&"get_item", item).get("max_stack", 99))
				wanted[item] = mini(int(wanted.get(item, 0)) + int(need["count"]), most)
	if _short_of(wanted).is_empty():
		return
	_note("gathering for the %s: short of %s" % [next, _short_of(wanted)])
	await _clear_land(false, wanted, 30.0)


## The next building he wants: the first of BUILD_ORDER that is neither standing, nor a site,
## nor a kit in his pack, whose plan he knows. "" when there is none.
func _next_building() -> StringName:
	var home: RefCounted = _gs.call(&"homestead")
	for id: StringName in BUILD_ORDER:
		if bool(home.call(&"has_building", id)) or _count(_kit_of(id)) > 0:
			continue
		if _recipe(id).is_empty():
			continue
		return id
	return &""


## The next `many` buildings he wants, in order.
func _next_buildings(many: int) -> Array[StringName]:
	var out: Array[StringName] = []
	var home: RefCounted = _gs.call(&"homestead")
	for id: StringName in BUILD_ORDER:
		if out.size() >= many:
			break
		if bool(home.call(&"has_building", id)) or _count(_kit_of(id)) > 0 or _recipe(id).is_empty():
			continue
		out.append(id)
	return out


## The coins he wants at Tilda's for the next building, once the coins are all it still wants
## (its bars and materials are in his pack), and for hens once the Coop stands: ore and bars
## beyond what he keeps are sold toward them, after the seed is paid for.
func _next_goal_coins() -> int:
	var goal: int = 0
	var next: StringName = _next_building()
	if next != &"":
		var coins: int = 0
		var ready: bool = true
		for need: Dictionary in _recipe(next).get("needs", []):
			if str(need["item"]) == "coin":
				coins += int(need["count"])
			elif _count(StringName(str(need["item"]))) < int(need["count"]):
				ready = false
		goal += coins if ready else 0
	if bool(_gs.call(&"is_built", &"coop")):
		goal += maxi(HENS - _hens(), 0) * _animal_price(&"chicken")
	return goal


## The workbench recipe that makes building `id` (its kit), if he knows it; else {}.
func _recipe(id: StringName) -> Dictionary:
	for recipe: Dictionary in _gs.call(&"known_crafts", "workbench"):
		if str(recipe.get("makes", {}).get("item", "")) == String(_kit_of(id)):
			return recipe
	return {}


func _kit_of(id: StringName) -> StringName:
	return StringName("%s_kit" % id)


## At home, the kit of each building he wants and has the makings for is made (the "Build"
## tab), with the pen's fences and gate for the Coop (the "Place" tab); then, on the farm, each
## kit he carries is set down at its site in build mode, and the pen laid.
func _build_what_he_can() -> void:
	var making: Array[StringName] = []
	for id: StringName in BUILD_ORDER:
		var recipe: Dictionary = _recipe(id)
		if recipe.is_empty() or bool(_gs.call(&"homestead").call(&"has_building", id)) or _count(_kit_of(id)) > 0:
			continue
		if _can_make(StringName(str(recipe["id"]))):
			making.append(StringName(str(recipe["id"])))
	if not making.is_empty() and await _travel_to(&"home"):
		await _make_things(making)
	for id: StringName in BUILD_ORDER:
		if _count(_kit_of(id)) > 0:
			await _set_down_kit(id)
	if not bool(_gs.call(&"homestead").call(&"has_building", &"coop")):
		return
	# The pen: its fences (two to a wood) and its gate (three wood), the wood gathered first
	# (the pack holds thirty, and the Coop took a full stack).
	var fences: int = maxi(PEN_FENCES.size() - _pen_laid(&"fence") - _count(&"fence"), 0)
	var gate: int = 1 if _pen_laid(&"gate") == 0 and _count(&"gate") == 0 else 0
	var list: Array[StringName] = []
	for pair: int in ceili(fences / 2.0):
		list.append(&"fence")
	for one: int in gate:
		list.append(&"gate")
	if not list.is_empty():
		var wood: int = ceili(fences / 2.0) + 3 * gate
		if _count(&"wood") < wood:
			_note("gathering for the pen: %d wood wanted" % wood)
			await _clear_land(false, {&"wood": wood}, 20.0)
		if await _travel_to(&"home"):
			await _make_things(list)
	if _count(&"fence") > 0 or _count(&"gate") > 0:
		await _lay_pen()


## How many of the pen's cells have `item` (a fence or the gate) standing on them.
func _pen_laid(item: StringName) -> int:
	var home: RefCounted = _gs.call(&"homestead")
	var cells: Array[Vector2i] = [PEN_GATE]
	if item == &"fence":
		cells = PEN_FENCES
	var laid: int = 0
	for cell: Vector2i in cells:
		if StringName(home.call(&"standing_at", cell)) == item:
			laid += 1
	return laid


## Sets the kit of building `id` down at its site: build mode (B), the kit chosen on the build
## bar (the wheel), the ghost moved a cell at a time (the movement keys) to where the kit holds
## the building (its door, or the middle of its bottom row), and the sword's key to set it down.
func _set_down_kit(id: StringName) -> bool:
	var building: Dictionary = _data.call(&"get_building", id)
	var at: Vector2i = SITES[id] + Buildings.anchor_of(building)
	if not await _open_build(STAND_FOR[id]):
		return false
	var done: bool = await _set_down_in_build(_kit_of(id), at)
	_shot("d%d_build_%s" % [_today, id])
	await _close_build()
	if done:
		(_cur["set_down"] as Array).append(String(id))
	_note("the %s's kit set down at %s: %s ('%s')" % [id, SITES[id], done, _build_words()])
	return done


## Lays the pen before the Coop's door: a fence on each of its fence cells, the gate on its own.
func _lay_pen() -> void:
	if not await _open_build(STAND_FOR[&"coop"]):
		return
	var home: RefCounted = _gs.call(&"homestead")
	for cell: Vector2i in PEN_FENCES:
		if _count(&"fence") == 0:
			break
		if StringName(home.call(&"standing_at", cell)) == &"":
			await _set_down_in_build(&"fence", cell)
	if _count(&"gate") > 0 and StringName(home.call(&"standing_at", PEN_GATE)) == &"":
		await _set_down_in_build(&"gate", PEN_GATE)
	_shot("d%d_build_pen" % _today)
	await _close_build()
	_note("the pen: %d of %d fences and %d gate laid" % [_pen_laid(&"fence"), PEN_FENCES.size(), _pen_laid(&"gate")])


## Walks to `stand` on the farm and opens build mode there (B).
func _open_build(stand: Vector2i) -> bool:
	if not await _travel_to(&"homestead"):
		return false
	_ctx = "build"
	await _walk_to(stand)
	await _face(Vector2i.UP)
	await _wait(10)
	await _tap(KEY_B)
	var build: Node = _area().get(&"build")
	if build == null or not await _until(func() -> bool: return bool(build.call(&"is_open")), 60):
		_note("!! build mode did not open")
		_ctx = "walk"
		return false
	return true


## In build mode: chooses `item` on the build bar, moves the ghost to `at` and sets it down.
func _set_down_in_build(item: StringName, at: Vector2i) -> bool:
	var build: Node = _area().get(&"build")
	for turn: int in 20:
		if StringName(build.get(&"chosen")) == item:
			break
		await _wheel()
		await _wait(2)
	if StringName(build.get(&"chosen")) != item:
		_note("!! %s is not on the build bar" % item)
		return false
	for step: int in 60:
		var cell: Vector2i = build.get(&"cell")
		if cell == at:
			break
		var way: Vector2i = Vector2i(signi(at.x - cell.x), 0) if cell.x != at.x else Vector2i(0, signi(at.y - cell.y))
		await _tap(KEY_D if way == Vector2i.RIGHT else (KEY_A if way == Vector2i.LEFT else (KEY_S if way == Vector2i.DOWN else KEY_W)))
		if Vector2i(build.get(&"cell")) == cell:
			_note("!! the ghost will go no nearer %s than %s" % [at, cell])
			return false
	if not bool(build.call(&"fits")):
		_note("!! the %s does not fit at %s: '%s'" % [item, at, build.call(&"why_not")])
		return false
	var before: int = _count(item)
	await _tap(KEY_SPACE)
	await _wait(6)
	return _count(item) < before


func _close_build() -> void:
	var build: Node = _area().get(&"build") if _in_area() else null
	if build != null and bool(build.call(&"is_open")):
		await _tap(KEY_B)
		await _wait(10)
	_ctx = "walk"


func _build_words() -> String:
	return str(_hud().call(&"build_words")) if _in_area() and _hud().has_method(&"build_words") else ""


## The hens he has.
func _hens() -> int:
	var count: int = 0
	for animal: Dictionary in _gs.call(&"homestead").call(&"animals"):
		if str(animal.get("kind", "")) == "chicken":
			count += 1
	return count


func _animal_price(kind: StringName) -> int:
	for ware: Dictionary in _data.call(&"get_shop", &"oda").get("sells", []):
		if str(ware.get("animal", "")) == String(kind):
			return int(ware["price"])
	return 0


## Buys hens at Oda's stall, up to the Coop's four, with what the purse holds beyond a little
## for seed, if the Coop stands.
func _buy_hens() -> void:
	if not bool(_gs.call(&"is_built", &"coop")) or _hens() >= HENS:
		return
	var price: int = _animal_price(&"chicken")
	var wanted: int = mini(HENS - _hens(), (_count(&"coin") - 20) / price)
	if wanted <= 0:
		_note("no hens today: %d coins" % _count(&"coin"))
		return
	if not await _travel_to(&"village"):
		return
	_ctx = "buy"
	if not await _talk_to("FarmerOda"):
		_ctx = "walk"
		return
	if not await _say("Have you any animals to sell?"):
		_note("Oda: '%s'" % _words())
		await _end_talk()
		_ctx = "walk"
		return
	var stall: Node = _hud().get(&"shop_menu")
	if not await _until(func() -> bool: return bool(stall.call(&"is_open")), 60):
		_ctx = "walk"
		return
	var index: int = -1
	var entries: Array = stall.call(&"entries")
	for i: int in entries.size():
		if str((entries[i] as Dictionary).get("animal", "")) == "chicken":
			index = i
	for step: int in 10:
		if int(stall.get(&"selected")) == index or index == -1:
			break
		await _tap(KEY_S if index > int(stall.get(&"selected")) else KEY_W)
	for hen: int in wanted:
		var had: int = _hens()
		await _tap(KEY_ENTER)
		await _wait(4)
		if _hens() == had:
			_note("Oda's stall: '%s'" % stall.call(&"note_text"))
			break
	_shot("d%d_odas_stall" % _today)
	await _tap(KEY_TAB)
	await _wait(10)
	_ctx = "walk"
	_note("hens: %d; coins %d" % [_hens(), _count(&"coin")])


## Pets every animal he has and takes what each has ready: out in their pasture by day, at home
## in their building's room when they have none.
func _tend_animals() -> void:
	var home: RefCounted = _gs.call(&"homestead")
	if int(home.call(&"animal_count")) == 0:
		return
	var where: StringName = &"homestead" if bool(_gs.call(&"has_pasture", &"coop")) else &"coop"
	if not await _travel_to(where):
		return
	_ctx = "tend"
	await _wait(20)
	var placed: Node = _area().get(&"animals")
	if placed == null:
		_ctx = "walk"
		return
	for turn: int in 30:
		var next: Node2D = null
		for animal: Node2D in placed.call(&"shown"):
			if not bool((home.call(&"animal", int(animal.get(&"index"))) as Dictionary).get("petted", false)):
				next = animal
				break
		if next == null or not _day_is_on():
			break
		var index: int = int(next.get(&"index"))
		if not await _stand_by(Vector2i(next.call(&"cell"))):
			await _wait(30)
			continue
		await _click(MOUSE_BUTTON_RIGHT)
		await _wait(20)
		if bool((home.call(&"animal", index) as Dictionary).get("petted", false)):
			_note("tended: '%s'" % _hud().call(&"message_text"))
	_ctx = "walk"
	var petted: int = 0
	for animal: Dictionary in home.call(&"animals"):
		petted += 1 if bool(animal.get("petted", false)) else 0
	_note("animals tended in the %s: %d of %d petted; eggs %d" % [where, petted, int(home.call(&"animal_count")), _count(&"egg")])


## "wood 12, stone 30, fibre 4": the materials of the Homestead he carries.
func _materials_text() -> String:
	var parts: PackedStringArray = []
	for item: StringName in [&"wood", &"stone", &"fibre", &"hay", &"copper_bar", &"iron_bar"]:
		parts.append("%s %d" % [item, _count(item)])
	return ", ".join(parts)


## The farm as it stands, for the day's record.
func _farm_record() -> Dictionary:
	var home: RefCounted = _gs.call(&"homestead")
	var buildings: Dictionary = {}
	for id: StringName in home.call(&"building_ids"):
		buildings[String(id)] = "standing" if bool(_gs.call(&"is_built", id)) else "site"
	var animals: Dictionary = {}
	for animal: Dictionary in home.call(&"animals"):
		animals[str(animal["kind"])] = int(animals.get(str(animal["kind"]), 0)) + 1
	var materials: Dictionary = {}
	for item: StringName in [&"wood", &"stone", &"fibre", &"hay", &"copper_bar", &"iron_bar", &"egg"]:
		materials[String(item)] = _count(item)
	return {"buildings": buildings, "animals": animals, "materials": materials, "cleared_on_land": int(home.call(&"cleared_count")),
		"field_clear": _field_clear(), "pen": {"fences": _pen_laid(&"fence"), "gate": _pen_laid(&"gate")},
		"coop_pasture": bool(_gs.call(&"has_pasture", &"coop")), "hay_in_silo": int(home.get(&"hay")), "placed": int(home.call(&"placed_count"))}


# --- Mornings and evenings at home ------------------------------------------------------

## Takes what the furnace made overnight, and makes what he can at the workbench.
func _morning_at_home() -> void:
	await _travel_to(&"home")
	await _empty_the_furnace()
	await _make_things()


## Home again: the furnace is built if it can be, loaded for the night, and the workbench
## is given another look.
func _evening_at_home() -> void:
	await _travel_to(&"home")
	await _make_things()
	await _load_the_furnace()
	await _make_things()


## Makes, in this order, whatever of `wanted` he knows and has the makings for: by default
## the furnace, the better pickaxes and a sprinkler.
func _make_things(wanted: Array[StringName] = [&"furnace", &"copper_pickaxe", &"iron_pickaxe", &"sprinkler"]) -> void:
	if _area_id() != &"home":
		return
	var makeable: Array[StringName] = []
	for recipe: StringName in wanted:
		if _can_make(recipe) and not (recipe == &"sprinkler" and _no_sprinkler()) and not _takes_the_wells_bar(recipe):
			makeable.append(recipe)
	if makeable.is_empty():
		return
	_ctx = "craft"
	if not await _open_workbench():
		_note("!! the workbench did not open")
		return
	for recipe: StringName in wanted:
		var menu: Node = _hud().get(&"craft_menu")
		# Its tab first: "Make", "Place" or "Build" (D turns to the next).
		var tab: String = _tab_of(recipe)
		for turn: int in 4:
			if str(menu.get(&"tab")) == tab:
				break
			await _tap(KEY_D)
			await _wait(4)
		var entries: Array = menu.call(&"entries")
		var index: int = -1
		for i: int in entries.size():
			if StringName(str((entries[i] as Dictionary).get("id", ""))) == recipe:
				index = i
		if index == -1 or not bool(menu.call(&"can_make", index)) or (recipe == &"sprinkler" and _no_sprinkler()) or _takes_the_wells_bar(recipe):
			continue
		for step: int in 20:
			var selected: int = menu.get(&"selected")
			if selected == index:
				break
			await _tap(KEY_S if index > selected else KEY_W)
		await _wait(4)
		_shot("d%d_workbench_%s" % [_today, recipe])
		await _tap(KEY_ENTER)
		await _wait(12)
		_note("workbench: %s" % menu.call(&"note_text"))
	await _tap(KEY_TAB)
	await _wait(10)
	_ctx = "walk"


## The workbench tab recipe `recipe_id` is on ("make" if it names none).
func _tab_of(recipe_id: StringName) -> String:
	for recipe: Dictionary in _gs.call(&"known_crafts", "workbench"):
		if StringName(str(recipe.get("id", ""))) == recipe_id:
			return str(recipe.get("tab", "make"))
	return "make"


## Whether making `recipe` would take the copper bar the Well still wants (a tool or a
## sprinkler, while he has only the one).
func _takes_the_wells_bar(recipe_id: StringName) -> bool:
	if recipe_id == &"well" or not _wants_well() or _count(&"copper_bar") > 1:
		return false
	for recipe: Dictionary in _gs.call(&"known_crafts", "workbench"):
		if StringName(str(recipe.get("id", ""))) == recipe_id:
			for need: Dictionary in recipe.get("needs", []):
				if str(need["item"]) == "copper_bar":
					return true
	return false


## Whether a sprinkler is not to be made: he has two, or its copper bar is the one the Well
## still wants.
func _no_sprinkler() -> bool:
	var well_wants: bool = not bool(_gs.call(&"homestead").call(&"has_building", &"well")) and _count(&"well_kit") == 0
	return _sprinklers() >= 2 or (well_wants and _count(&"copper_bar") <= 1)


## The sprinklers he has, carried or set on the plot: two are all the plot's middle row takes.
func _sprinklers() -> int:
	return _count(&"sprinkler") + int(_gs.call(&"farm").call(&"sprinkler_count"))


## Whether workbench recipe `recipe_id` is known and can be made now (what its line would show).
func _can_make(recipe_id: StringName) -> bool:
	for recipe: Dictionary in _gs.call(&"known_crafts", "workbench"):
		if StringName(str(recipe.get("id", ""))) == recipe_id:
			return str(_gs.call(&"why_not_craft", recipe)).is_empty()
	return false


func _open_workbench() -> bool:
	var bench: Node2D = _thing("Workbench")
	if bench == null or not await _stand_by(_cell_of(bench)):
		return false
	await _click(MOUSE_BUTTON_RIGHT)
	return await _until(func() -> bool: return bool(_hud().get(&"craft_menu").call(&"is_open")), 60)


## Takes the bars out of a furnace that has burned down.
func _empty_the_furnace() -> void:
	if _area_id() != &"home" or not _has_furnace():
		return
	var furnace: RefCounted = _gs.call(&"furnace")
	if not bool(furnace.call(&"is_ready", int(_gs.get(&"day")))):
		return
	_ctx = "furnace"
	if await _talk_to("Furnace"):
		_note("the furnace: '%s'" % _words())
		await _say("Take it out.")
		await _end_talk()
	_ctx = "walk"


## Loads the furnace for the night with the metal he has the most bars' worth of.
func _load_the_furnace() -> void:
	if _area_id() != &"home" or not _has_furnace():
		return
	var furnace: RefCounted = _gs.call(&"furnace")
	var day: int = _gs.get(&"day")
	if bool(furnace.call(&"is_burning", day)) or bool(furnace.call(&"is_ready", day)):
		return
	var best: String = ""
	var most: int = 0
	for metal: String in ["iron", "gold", "copper"]:
		var bars: int = mini(_count(StringName(metal + "_ore")) / 3, _count(&"coal"))
		# Iron first when it makes a tool's worth; else whatever makes the most bars.
		if bars > most:
			most = bars
			best = metal
	if best == "":
		_note("the furnace stays cold: %s" % _carrying())
		return
	_ctx = "furnace"
	if await _talk_to("Furnace"):
		_shot("d%d_furnace" % _today)
		var bar: String = str(_data.call(&"get_item", StringName(best + "_bar")).get("name", best))
		if await _say(bar, false):
			_note("the furnace is lit: '%s'" % _words())
			_cur["smelting"] = "%s x%d" % [bar, mini(most, 5)]
		await _end_talk()
	_ctx = "walk"


func _has_furnace() -> bool:
	return _gs.call(&"get_flag", &"home/furnace") == true


# --- The plot -----------------------------------------------------------------------------

## Picks every ripe crop, and clears what has withered.
func _harvest() -> void:
	if _area_id() != PLOT_AREA:
		return
	_ctx = "harvest"
	for cell: Vector2i in _plot_cells():
		var phase: StringName = _phase(cell)
		if phase != &"ripe" and phase != &"withered":
			continue
		if not await _stand_by(cell):
			continue
		await _click(MOUSE_BUTTON_RIGHT)
		await _wait(14)
	_ctx = "walk"
	_note("harvested: %s" % _carrying())


## Tills as many cells as he has seeds for, sows them, and waters every crop that is dry.
func _tend_plot() -> void:
	if not await _travel_to(PLOT_AREA):
		return
	_ctx = "farm"
	var hoe: StringName = _best(HOES)
	var can: StringName = _best(CANS)
	await _set_sprinklers(hoe)
	# Sowing: a seed for every empty cell he can till.
	var seeds: Array[StringName] = _seeds_held()
	if hoe != &"" and not seeds.is_empty():
		for cell: Vector2i in _plot_cells():
			if _seeds_held().is_empty():
				break
			if _has_crop(cell) or _has_sprinkler(cell):
				continue
			if _soil(cell) == &"bare":
				if not _fit_for(BLOW):
					break
				if not await _stand_by(cell) or not await _take_in_hand(hoe):
					continue
				await _click(MOUSE_BUTTON_LEFT)
				await _wait(30)
				if _verbose:
					_note("  hoe at %s from %s facing %s: soil %s; '%s'" % [cell, _cell(), _front(), _soil(cell), _hud().call(&"message_text")])
			if _soil(cell) != &"bare" and not _has_crop(cell):
				if not await _stand_by(cell) or not await _take_in_hand(_seeds_held()[0]):
					continue
				await _click(MOUSE_BUTTON_LEFT)
				await _wait(30)
				if _verbose:
					_note("  seed at %s from %s facing %s: crop %s, in hand %s; '%s'" % [cell, _cell(), _front(), _has_crop(cell), _gs.get(&"equipped"), _hud().call(&"message_text")])
	# Watering: every crop on dry soil.
	if can != &"":
		for cell: Vector2i in _plot_cells():
			if not _has_crop(cell) or _soil(cell) == &"watered" or _phase(cell) == &"ripe" or _phase(cell) == &"withered":
				continue
			if not _fit_for(1.0):
				break
			if _count(&"water") == 0 and not await _fill_the_can(can):
				_note("!! the can could not be filled")
				break
			if not await _stand_by(cell) or not await _take_in_hand(can):
				continue
			await _click(MOUSE_BUTTON_LEFT)
			await _wait(30)
	_ctx = "walk"
	var farm: RefCounted = _gs.call(&"farm")
	_note("the plot: %d crops, %d cells watered, farming level %s" % [int(farm.call(&"crop_count")), int(farm.call(&"count_of", &"watered")), _level(&"farming")])


## Sets the sprinklers he carries on the plot's middle row, where all four cells beside one
## are soil: the second cell from each end.
func _set_sprinklers(hoe: StringName) -> void:
	for cell: Vector2i in _plot_cells():
		if _count(&"sprinkler") == 0:
			return
		var at: Vector2i = _plot_cell(cell)
		if at.y != 1 or at.x % 3 != 1 or _has_crop(cell) or _has_sprinkler(cell):
			continue
		if _soil(cell) == &"bare" and hoe != &"" and _fit_for(BLOW):
			if await _stand_by(cell) and await _take_in_hand(hoe):
				await _click(MOUSE_BUTTON_LEFT)
				await _wait(30)
		if _soil(cell) == &"bare":
			continue
		if await _stand_by(cell) and await _take_in_hand(&"sprinkler"):
			await _click(MOUSE_BUTTON_LEFT)
			await _wait(30)
			_note("a sprinkler is set at the plot's cell %s: %s" % [at, _has_sprinkler(cell)])
			_shot("d%d_sprinkler" % _today)


## Fills the can at the nearest water (the pond in the corner of the farm).
func _fill_the_can(can: StringName) -> bool:
	var spots: Array[Vector2i] = []
	var size: Vector2i = _area().get(&"grid").get(&"size")
	for x: int in size.x:
		for y: int in size.y:
			if bool(_area().call(&"is_water_source", Vector2i(x, y))):
				for side: Vector2i in SIDES:
					spots.append(Vector2i(x, y) + side)
	if not await _walk_to_any(spots):
		return false
	for side: Vector2i in SIDES:
		if bool(_area().call(&"is_water_source", _cell() + side)):
			await _face(side)
			if not await _take_in_hand(can):
				return false
			await _click(MOUSE_BUTTON_LEFT)
			await _wait(30)
			return _count(&"water") > 0
	return false


## The cells of the plot he can work: those with nothing standing on them (the field's clear
## corner, until the land is cleared).
func _plot_cells() -> Array[Vector2i]:
	var plot: Node = _area().get(&"plot")
	var out: Array[Vector2i] = []
	if plot != null:
		for cell: Vector2i in plot.call(&"cells"):
			if _area().call(&"debris_at", cell) == null:
				out.append(cell)
	return out


func _plot_cell(cell: Vector2i) -> Vector2i:
	return _area().get(&"plot").call(&"plot_cell", cell)


func _soil(cell: Vector2i) -> StringName:
	return _gs.call(&"farm").call(&"state_of", _plot_cell(cell))


func _has_crop(cell: Vector2i) -> bool:
	return _gs.call(&"farm").call(&"has_crop", _plot_cell(cell))


func _has_sprinkler(cell: Vector2i) -> bool:
	return _gs.call(&"farm").call(&"has_sprinkler", _plot_cell(cell))


## What the crop in `cell` looks like: "seeded", "sprout", "growing", "ripe", "withered", or "".
func _phase(cell: Vector2i) -> StringName:
	if not _has_crop(cell):
		return &""
	var farm: RefCounted = _gs.call(&"farm")
	var crop: String = farm.call(&"crop_at", _plot_cell(cell))
	var days: int = int(_data.call(&"get_crop", StringName(crop)).get("days", 1))
	return farm.call(&"phase_of", _plot_cell(cell), days)


func _seeds_held() -> Array[StringName]:
	var out: Array[StringName] = []
	for stack: Dictionary in _gs.get(&"inventory"):
		if str(_data.call(&"get_item", stack["id"]).get("type", "")) == "seed" and int(stack["count"]) > 0:
			out.append(stack["id"])
	return out


# --- Tilda's counter -----------------------------------------------------------------------

## A plot day's trade: every crop he carries is sold, and turnip seed is bought for every
## empty cell the coins reach (ore and bars he has no use for are sold for it, if the crops
## don't pay for it all). On the last day (`all`) the ore, bars and crystals all go.
func _shop_for_seeds(all: bool = false, save: int = 0) -> void:
	# The plot is on the homestead: he looks at it there.
	if not await _travel_to(PLOT_AREA):
		return
	var empty: int = 0
	for cell: Vector2i in _plot_cells():
		if not _has_crop(cell) and not _has_sprinkler(cell):
			empty += 1
	# A sprinkler he carries will take a cell.
	empty = maxi(empty - _seed_count() - mini(_count(&"sprinkler"), 2), 0)
	var selling: Array[StringName] = []
	selling.assign(CROPS)
	selling.append(&"egg")
	if all:
		selling.append_array(SELLABLE)
	var keep: Dictionary = _keep()
	# Seed first: the crops are what pay. The coins saved for the farm are made up by selling
	# ore and bars beyond what he keeps, after the seed.
	var worth: int = _count(&"coin")
	for item: StringName in CROPS + [&"egg"]:
		worth += _count(item) * _price_of(item)
	for item: StringName in SELLABLE:
		worth += maxi(_count(item) - (0 if all else int(keep.get(item, 0))), 0) * _price_of(item)
	var seeds: int = clampi(worth / 5, 0, empty)
	if save > 0:
		_note("seed for %d of %d empty cells, then ore sold toward the farm's %d coins" % [seeds, empty, save])
	await _shop([[&"turnip_seeds", seeds]] if seeds > 0 else [], 0, keep, selling, save)


func _seed_count() -> int:
	var total: int = 0
	for seed: StringName in _seeds_held():
		total += _count(seed)
	return total


## What he keeps back when he sells ore and bars for bread: the furnace's copper ore until it
## is built, the bars a better pickaxe and a first sprinkler still want, and the iron ore
## that will be those bars.
func _keep() -> Dictionary:
	var iron_pick: bool = _count(&"iron_pickaxe") > 0
	var copper_pick: bool = iron_pick or _count(&"copper_pickaxe") > 0
	var sprinkler: int = maxi(2 - _sprinklers(), 0)
	return {
		&"copper_ore": 0 if _has_furnace() else 5,
		&"copper_bar": (0 if copper_pick else 3) + sprinkler + (1 if _wants_well() else 0),
		&"iron_bar": (0 if iron_pick else 3) + sprinkler,
		&"iron_ore": 0 if iron_pick else 9,
	}


func _wants_well() -> bool:
	return not bool(_gs.call(&"homestead").call(&"has_building", &"well")) and _count(&"well_kit") == 0


## What Tilda pays for one `item` (her list shows it).
func _price_of(item: StringName) -> int:
	var shop: Dictionary = _data.call(&"get_shop", &"tilda")
	for offer: Dictionary in Shop.offers(shop, _data.call(&"entries", &"crops"), [{"id": item, "count": 1}]):
		return int(offer["price"])
	return 0


## Goes to Tilda's (waiting at her door if she is not open yet). Sells every `sell_all`
## item; then, to carry `loaves` loaves of bread, sells ore and bars, the cheapest first and
## never below what `keep` says of each, until the coins are enough; then buys `buy`
## ([item, times]) and the bread.
func _shop(buy: Array, loaves: int, keep: Dictionary, sell_all: Array[StringName] = [], save: int = 0) -> void:
	var bread: int = maxi(loaves - _count(&"bread"), 0)
	var selling: bool = false
	for item: StringName in sell_all:
		selling = selling or _count(item) > 0
	if buy.is_empty() and bread == 0 and not selling and _count(&"coin") >= save:
		return
	if not await _travel_to(&"village"):
		return
	await _wait_for_the_shop()
	if not await _travel_to(&"shop"):
		_note("!! Tilda's door did not open: nothing bought or sold")
		return
	_ctx = "sell"
	# She may have something of her own to say first (a recipe, a present): then he asks again.
	for attempt: int in 3:
		if not await _talk_to("Tilda"):
			_note("!! Tilda did not answer")
			_ctx = "walk"
			return
		if await _say("I have things to sell."):
			break
		_note("Tilda: '%s'" % _words())
		await _end_talk()
	var counter: Node = _hud().get(&"shop_menu")
	if not await _until(func() -> bool: return bool(counter.call(&"is_open")), 60):
		_note("!! her list did not open")
		_ctx = "walk"
		return
	_shot("d%d_tilda_buys" % _today)
	for item: StringName in sell_all:
		await _sell(item, 0)
	# Ore and bars for bread (and the coins saved for the farm), as far as it is needed.
	var cost: int = bread * 6 + save
	for ware: Array in buy:
		cost += _ware_price(ware[0]) * int(ware[1])
	for item: StringName in SELLABLE:
		while _count(&"coin") < cost and _count(item) > int(keep.get(item, 0)):
			if not await _sell_one(item):
				break
	# The other list.
	_ctx = "buy"
	await _tap(KEY_D)
	await _wait(8)
	for ware: Array in buy:
		for times: int in int(ware[1]):
			if not await _buy_one(ware[0]):
				break
	for loaf: int in bread:
		if not await _buy_one(&"bread"):
			break
	_shot("d%d_tilda_sells" % _today)
	await _tap(KEY_TAB)
	await _wait(10)
	_ctx = "walk"
	_note("at Tilda's: coins %d; carrying %s" % [_count(&"coin"), _carrying()])


func _ware_price(item: StringName) -> int:
	var shop: Dictionary = _data.call(&"get_shop", &"tilda")
	for ware: Dictionary in Shop.wares(shop, _data.call(&"entries", &"crops")):
		if StringName(str(ware["item"])) == item:
			return int(ware["price"])
	return 0


## Sells `item` down to `keep` of it.
func _sell(item: StringName, keep: int) -> void:
	while _count(item) > keep:
		if not await _sell_one(item):
			break


func _sell_one(item: StringName) -> bool:
	var before: int = _count(item)
	if not await _point_at_entry(item):
		return false
	await _tap(KEY_ENTER)
	await _wait(3)
	return _count(item) < before


func _buy_one(item: StringName) -> bool:
	var before: int = _count(item)
	if not await _point_at_entry(item):
		return false
	await _tap(KEY_ENTER)
	await _wait(3)
	if _count(item) <= before:
		_note("could not buy %s: '%s'" % [item, _hud().get(&"shop_menu").call(&"note_text")])
		return false
	return true


## Moves the shop list's cursor to the line of `item`. False if it is not on the list.
func _point_at_entry(item: StringName) -> bool:
	var counter: Node = _hud().get(&"shop_menu")
	for step: int in 30:
		var entries: Array = counter.call(&"entries")
		var index: int = -1
		for i: int in entries.size():
			if StringName(str((entries[i] as Dictionary)["item"])) == item:
				index = i
		if index == -1:
			return false
		var selected: int = counter.get(&"selected")
		if selected == index:
			return true
		await _tap(KEY_S if index > selected else KEY_W)
	return false


## Stands at Tilda's door until she opens (08:00), if it is before that.
func _wait_for_the_shop() -> void:
	var door: Node2D = _thing("ShopDoor")
	if door == null or not bool(_area().call(&"is_shut", door)):
		return
	_note("Tilda's is shut: waiting at her door")
	var spots: Array[Vector2i] = []
	for side: Vector2i in SIDES:
		spots.append(_cell_of(door) + side)
	await _walk_to_any(spots)
	await _until(func() -> bool: return _area_id() != &"village" or not bool(_area().call(&"is_shut", door)), 60 * 200)
	_note("she has opened")


# --- The quarry ------------------------------------------------------------------------------

## A day's mining: to the quarry, down from `first` (by the lift if it reaches that floor, else
## by the ladders from the top) as far as `last`, floor by floor: every rock of ore, then
## plain rocks until the ladder shows. He turns back when he is spent and has nothing to eat,
## when it is late, or when he has fallen twice.
func _mine(first: int, last: int, hall_rocks: bool) -> void:
	if _best(PICKAXES) == &"":
		_note("!! no pickaxe: no mining today")
		return
	if not await _travel_to(&"quarry"):
		_note("!! he did not get to the quarry (%s)" % _area_id())
		return
	_shot("d%d_quarry_hall" % _today)
	var falls: int = 0
	var slips: int = 0
	while falls < 2 and slips < 3 and _day_is_on():
		if _area_id() != &"quarry":
			break
		_ctx = "mine"
		if hall_rocks:
			await _work_floor(&"quarry", true, 8.0)
			hall_rocks = false
		if not await _keep_fit(BLOW * 6.0 + 4.0) or float(_gs.get(&"minute")) > HOME_BY:
			break
		# Down: the lift if it reaches the floor he wants, else the ladder.
		var stop: int = _lift_stop_for(first)
		if stop > 1:
			if not await _ride_the_lift(stop):
				_note("!! the lift did not take him to floor %d" % stop)
				break
		else:
			var hole: Node2D = _thing("LadderDown")
			if hole == null or not await _leave_by(hole):
				_note("!! no way down from the hall")
				break
		# Floor by floor.
		var outcome: String = "down"
		while outcome == "down" and _day_is_on():
			var level: int = _floor()
			if level == 0:
				break
			outcome = await _floor_visit(level, level < last)
		if outcome == "fell":
			falls += 1
			_cur["falls"] = int(_cur.get("falls", 0)) + 1
			_note("he fell, and woke in the hall: fall %d today" % falls)
			await _wait(90)
			# Fallen in the dark without a light, he doesn't go back down there today.
			if not _has_light():
				last = mini(last, 6)
			if _deepest_today() >= last:
				break
			# Down again by the lift, as far as it goes toward where he fell.
			first = maxi(first, _lift_stop_for(_deepest_today()))
			continue
		if outcome == "left":
			# Up the ladder by mistake (a step aside from a monster): he goes down again.
			slips += 1
			_note("he was back in the hall without a fall: down again")
			first = maxi(first, _lift_stop_for(_deepest_today()))
			continue
		break
	_ctx = "walk"
	# Up and out, if he is still on a floor.
	if _floor() > 0:
		var up: Node2D = _thing("LadderUp")
		if up != null:
			await _leave_by(up)
	_note("out of the quarry: %s" % _carrying())


## One floor: the monsters in reach are fought, the rocks are worked, and he goes down the
## ladder if he wants to and has found it. Returns "down" (he is on the next floor), "fell",
## or why he stopped ("spent", "late", "done", "lost").
func _floor_visit(level: int, wants_down: bool) -> String:
	var here: StringName = _area_id()
	var seen: Dictionary = {"floor": level, "area": String(here), "energy": float(_cur["energy_spent"]), "blows": int(_cur["blows"]),
		"touches": int(_cur["touches"]), "at": _clock(), "frames": _frame, "pickaxe": String(_best(PICKAXES)), "mining": _level(&"mining"), "rocks": {}, "got": {}}
	var flows_from: int = (_cur["flows"] as Array).size()
	var rocks_before: Dictionary = _standing_by_kind()
	await _wait(30)
	if level == 1 or level == 4 or level >= 7:
		_shot("d%d_floor_%d" % [_today, level])
	# In the dark a Bogwisp's touch takes fifteen energy: he keeps more in hand down there.
	var reserve: float = 8.0 if level < 7 else (24.0 if _has_light() else 34.0)
	_fell = false
	await _step_clear()
	# Down in the dark he wants a full belly: a Bogwisp's touch takes fifteen energy.
	if level >= 7:
		await _keep_fit(70.0)
	await _hunt(60.0 if level >= 7 else 20.0)
	await _gather()
	var outcome: String = await _work_floor(here, wants_down, reserve)
	await _gather()
	# What this floor took and gave.
	if _area_id() == here:
		var rocks_after: Dictionary = _standing_by_kind()
		for kind: StringName in rocks_before:
			var broken: int = int(rocks_before[kind]) - int(rocks_after.get(kind, 0))
			if broken > 0:
				(seen["rocks"] as Dictionary)[String(kind)] = broken
	for flow: Dictionary in (_cur["flows"] as Array).slice(flows_from):
		if int(flow["count"]) > 0 and str(flow["area"]) == String(here):
			(seen["got"] as Dictionary)[flow["item"]] = int((seen["got"] as Dictionary).get(flow["item"], 0)) + int(flow["count"])
	seen["energy"] = snappedf(float(_cur["energy_spent"]) - float(seen["energy"]), 0.1)
	seen["blows"] = int(_cur["blows"]) - int(seen["blows"])
	seen["touches"] = int(_cur["touches"]) - int(seen["touches"])
	seen["seconds"] = snappedf((_frame - int(seen["frames"])) / 60.0, 0.1)
	seen.erase("frames")
	seen["outcome"] = outcome
	(_cur["floors"] as Array).append(seen)
	_note("floor %d (%s): %s; got %s; rocks broken %s; energy %.1f, %d blows, %d touches, %.0f s" % [
		level, here, outcome, seen["got"], seen["rocks"], float(seen["energy"]), int(seen["blows"]), int(seen["touches"]), float(seen["seconds"])])
	if outcome == "ladder":
		var hole: Node2D = _area().call(&"ladder")
		if hole != null and await _leave_by(hole):
			return "down"
		await _until(func() -> bool: return _in_area(), 300)
		return ("fell" if _fell else "left") if _area_id() == &"quarry" else "lost"
	return outcome


## Works the rocks of the floor (or the hall) he stands on: ore first, the nearest first;
## then, if he `wants_down`, plain rocks until the ladder shows. Returns "ladder" (it is
## found and he wants it), "done", "spent", "late", "fell" or "lost".
func _work_floor(here: StringName, wants_down: bool, reserve: float) -> String:
	for turn: int in 80:
		if not _day_is_on():
			return "lost"
		if _area_id() != here:
			await _until(func() -> bool: return _in_area(), 300)
			# In the hall again: he fell, or he stepped onto the ladder up without meaning to.
			return ("fell" if _fell else "left") if _area_id() == &"quarry" else "lost"
		if float(_gs.get(&"minute")) > HOME_BY:
			return "late"
		var ladder_found: bool = _area().call(&"ladder") != null
		var rock: Node2D = _next_rock(wants_down and not ladder_found)
		if rock == null:
			return "ladder" if wants_down and ladder_found else "done"
		if not await _keep_fit(reserve + BLOW):
			return "spent"
		var broke: bool = await _break(rock, reserve)
		if _verbose and is_instance_valid(rock):
			_note("  rock %s at %s: %s (he is at %s)" % [rock.get(&"kind"), _cell_of(rock), "broken" if broke else "not broken", _cell() if _in_area() else Vector2i.ZERO])
		if not broke:
			if _area_id() != here:
				continue
			if float(_gs.get(&"energy")) < reserve + BLOW and not _has_food():
				return "spent"
			_given_up["%s/%s" % [here, _cell_of(rock)]] = true
	return "done"


## The rock to break next: the nearest he can get to that holds ore; with none, and if
## `plain_too`, the nearest plain one; else a plain one that stands between him and ore he
## can't reach. Null when there is nothing to do.
func _next_rock(plain_too: bool) -> Node2D:
	var steps: Dictionary = _steps_from(_cell())
	var ore: Node2D = null
	var plain: Node2D = null
	var ore_steps: int = 1 << 30
	var plain_steps: int = 1 << 30
	var ore_out_of_reach: bool = false
	for rock: Node2D in _rocks():
		if _given_up.has("%s/%s" % [_area_id(), _cell_of(rock)]):
			continue
		var near: int = _steps_to_side(steps, _cell_of(rock))
		var is_ore: bool = StringName(rock.get(&"kind")) != &"stone"
		if near < 0:
			ore_out_of_reach = ore_out_of_reach or is_ore
			continue
		if is_ore and near < ore_steps:
			ore_steps = near
			ore = rock
		elif not is_ore and near < plain_steps:
			plain_steps = near
			plain = rock
	if ore != null:
		return ore
	return plain if plain_too or ore_out_of_reach else null


## Breaks `rock` with the best pickaxe he has, and walks onto what it leaves. False if he
## could not get to it, ran short of energy, or was taken elsewhere.
func _break(rock: Node2D, reserve: float) -> bool:
	var here: StringName = _area_id()
	var cell: Vector2i = _cell_of(rock)
	for blow: int in 12:
		if _area_id() != here or not is_instance_valid(rock):
			return false
		if bool(rock.get(&"broken")):
			break
		if not await _keep_fit(reserve + BLOW):
			return false
		if _front() != cell:
			if not await _stand_by(cell):
				return false
		if not await _take_in_hand(_best(PICKAXES)):
			return false
		await _click(MOUSE_BUTTON_LEFT)
		for frame: int in 40:
			await physics_frame
			if frame > 4 and not bool(_motor().call(&"is_attacking")):
				break
		await _mind_monsters()
	if _area_id() != here or not is_instance_valid(rock) or not bool(rock.get(&"broken")):
		return false
	var kind: String = str(rock.get(&"kind"))
	(_cur["rocks"] as Dictionary)[kind] = int((_cur["rocks"] as Dictionary).get(kind, 0)) + 1
	# What it held lies in its cell: he walks onto it.
	if _drop_at(cell) != null:
		await _walk_to(cell)
		await _wait(6)
	return true


## Walks a few steps from the ladder he came down by: a knock from a monster there would
## send him back up it.
func _step_clear() -> void:
	if not _in_area():
		return
	var ways_out: Dictionary = _ways_out()
	var steps: Dictionary = _steps_from(_cell())
	var best: Vector2i = _cell()
	var fewest: int = 1 << 30
	for cell: Vector2i in steps:
		var clear: bool = true
		for way: Vector2i in ways_out:
			if absi(way.x - cell.x) + absi(way.y - cell.y) < 3:
				clear = false
				break
		if clear and int(steps[cell]) < fewest:
			fewest = int(steps[cell])
			best = cell
	if best != _cell():
		await _walk_to(best)


## The deepest floor he has stood on today.
func _deepest_today() -> int:
	var deepest: int = 0
	for seen: Dictionary in _cur["floors"]:
		deepest = maxi(deepest, int(seen["floor"]))
	return deepest


## Walks onto everything that lies on this floor to be picked up and that he can get to: what
## monsters dropped, and ore he was knocked away from.
func _gather(anywhere: bool = false) -> void:
	if not _in_area() or (_floor() == 0 and not anywhere):
		return
	var here: StringName = _area_id()
	for turn: int in 12:
		if _area_id() != here or _busy() or not _day_is_on():
			return
		var steps: Dictionary = _steps_from(_cell())
		var nearest: Vector2i = Vector2i(-1, -1)
		var fewest: int = 1 << 30
		for thing: Node in _things():
			if thing.has_method(&"collect") and &"told" in thing and not bool(thing.get(&"taken")) and not bool(thing.get(&"told")):
				var cell: Vector2i = _cell_of(thing as Node2D)
				if steps.has(cell) and int(steps[cell]) < fewest:
					fewest = int(steps[cell])
					nearest = cell
		if nearest == Vector2i(-1, -1):
			return
		if not await _walk_to(nearest):
			return
		await _wait(6)
		# No room for it: it stays, and he is told once (then it is left alone).
		var still: Node2D = _drop_at(nearest)
		if still != null and not bool(still.get(&"told")):
			return


## The lift's stop to ride to when he wants to begin at floor `first`: the deepest stop it
## has been to that is no deeper than `first`. 1 if there is none (the ladder from the hall).
func _lift_stop_for(first: int) -> int:
	var best: int = 1
	for stop: int in [4, 7]:
		if stop <= first and _gs.call(&"get_flag", StringName("quarry/lift/%d" % stop)) == true:
			best = stop
	return best


func _ride_the_lift(stop: int) -> bool:
	_ctx = "walk"
	if not await _talk_to("Lift"):
		return false
	_shot("d%d_lift" % _today)
	if not await _say("Floor %d" % stop):
		await _end_talk()
		return false
	var there: StringName = StringName("quarry_%d" % stop)
	var arrived: bool = await _until(func() -> bool: return _area_id() == there, 300)
	_release_all()
	await _wait(24)
	_ctx = "mine"
	return arrived


## The floor he is on (1 to 9), or 0 in the hall and anywhere else.
func _floor() -> int:
	var id: String = String(_area_id())
	return int(id.trim_prefix("quarry_")) if id.begins_with("quarry_") else 0


func _rocks() -> Array[Node2D]:
	var out: Array[Node2D] = []
	for thing: Node in _things():
		if &"blows_left" in thing and not bool(thing.get(&"broken")):
			out.append(thing as Node2D)
	return out


func _standing_by_kind() -> Dictionary:
	var out: Dictionary = {}
	for rock: Node2D in _rocks():
		var kind: StringName = rock.get(&"kind")
		out[kind] = int(out.get(kind, 0)) + 1
	return out


## What lies in `cell` to be picked up by walking onto it, or null.
func _drop_at(cell: Vector2i) -> Node2D:
	for thing: Node in _things():
		if thing.has_method(&"collect") and &"told" in thing and not bool(thing.get(&"taken")) and _cell_of(thing as Node2D) == cell:
			return thing as Node2D
	return null


# --- Monsters ----------------------------------------------------------------------------------

## The monsters that are up: not beaten, not lying low.
func _monsters() -> Array[Node2D]:
	var out: Array[Node2D] = []
	if not _in_area():
		return out
	for thing: Node in _things():
		if &"enemy_id" in thing and not thing.is_queued_for_deletion() and thing.get(&"brain") != null \
				and not bool(thing.get(&"lying_low")) and not bool(thing.call(&"is_dead")) and not bool(thing.call(&"is_fading")):
			out.append(thing as Node2D)
	return out


func _is_wisp(monster: Node2D) -> bool:
	return StringName(monster.get(&"enemy_id")) == &"bogwisp"


## Whether the sword would bite: a Bogwisp has a body only in the light.
func _can_be_hit(monster: Node2D) -> bool:
	return not _is_wisp(monster) or bool(monster.get(&"brain").get(&"lit"))


func _nearest(monsters: Array) -> Node2D:
	var best: Node2D = null
	for monster: Node2D in monsters:
		if best == null or monster.position.distance_to(_hero().position) < best.position.distance_to(_hero().position):
			best = monster
	return best


## What he does about monsters between one step and the next: out of the way of a Bogwisp
## that flares or darts, and a swing at anything in reach that the sword can bite.
func _mind_monsters() -> void:
	if not _in_area() or _busy():
		return
	var monsters: Array[Node2D] = _monsters()
	if monsters.is_empty():
		return
	for monster: Node2D in monsters:
		if not _is_wisp(monster):
			continue
		var brain: RefCounted = monster.get(&"brain")
		var state: StringName = brain.get(&"state")
		if (state == &"flare" or state == &"dart") and monster.position.distance_to(_hero().position) <= 100.0:
			await _meet(monster)
			return
	if not _armed() or _frame - _last_swing < SWING_EVERY:
		return
	var foe: Node2D = _nearest(monsters.filter(func(monster: Node2D) -> bool: return _can_be_hit(monster)))
	if foe != null and foe.position.distance_to(_hero().position) <= SWORD_REACH:
		await _swing_at(foe.position - _hero().position)


## A Bogwisp flares or darts. Flaring, it stands still, and his own light reaches it: with a
## lantern and a sword he runs at it and strikes before it can dart. Without, or too late, he
## steps out of its line.
func _meet(wisp: Node2D) -> void:
	var state: StringName = wisp.get(&"brain").get(&"state")
	if state == &"flare" and _has_light() and _armed() and wisp.position.distance_to(_hero().position) <= 60.0:
		await _run_at(wisp)
	else:
		await _dodge(wisp)


## Runs straight at a flaring Bogwisp and swings as soon as the sword reaches it, and again
## while it reels or rests. He gives it up when it drifts off again or darts past him.
func _run_at(wisp: Node2D) -> void:
	var here: StringName = _area_id()
	for frame: int in 150:
		if _area_id() != here or _busy() or not is_instance_valid(wisp) or wisp.is_queued_for_deletion() or bool(wisp.call(&"is_dead")):
			break
		var state: StringName = wisp.get(&"brain").get(&"state")
		var offset: Vector2 = wisp.position - _hero().position
		if state != &"flare" and state != &"rest" and state != &"hurt" and state != &"dart":
			break
		if offset.length() <= SWORD_REACH:
			if bool(wisp.get(&"brain").get(&"lit")) and state != &"hurt" and _frame - _last_swing >= 20:
				await _swing_at(offset)
				if not _cur.has("wisp_shot"):
					_cur["wisp_shot"] = true
					_shot("d%d_a_wisp_struck" % _today)
			else:
				_release_all()
				await physics_frame
			continue
		if state == &"dart":
			# It is on its way: out of its line, then at it again while it rests.
			await _dodge(wisp)
			continue
		# Both keys at once: the straight way is the short way.
		for way: Vector2i in KEYS:
			var along: float = offset.dot(Vector2(way))
			_hold(way, along > 3.0 and _free(_cell() + way))
		await physics_frame
	_release_all()


## Steps across the line a Bogwisp is aimed along.
func _dodge(wisp: Node2D) -> void:
	var here: StringName = _area_id()
	var aim: Vector2 = wisp.get(&"brain").get(&"aim")
	var across: Vector2 = Vector2(-aim.y, aim.x)
	if (_hero().position - wisp.position).dot(across) < 0.0:
		across = -across
	var way: Vector2i = _cardinal(across)
	# Not into a wall, a hole or a way out: the other side, if this one is shut.
	if not _free(_cell() + way):
		way = -way
	if not _free(_cell() + way):
		await physics_frame
		return
	_release_all()
	_hold(way, true)
	# Until he is well clear of its line, or it has gone by.
	for frame: int in 40:
		await physics_frame
		if _area_id() != here or not is_instance_valid(wisp):
			break
		var from_line: float = absf((_hero().position - wisp.position).dot(Vector2(-aim.y, aim.x)))
		var state: StringName = wisp.get(&"brain").get(&"state")
		if from_line >= 22.0 or (state != &"flare" and state != &"dart"):
			break
		# The next cell that way is shut: he stops at its edge, as far over as he can get.
		if not _free(_cell() + way) and (_pos() - _centre(_cell())).dot(Vector2(way)) >= 3.0:
			break
	_release_all()


## Faces the way `offset` points and swings the sword (Space).
func _swing_at(offset: Vector2) -> void:
	_release_all()
	var way: Vector2i = _cardinal(offset)
	if Vector2i(_hero().call(&"facing_direction")) != way:
		_hold(way, true)
		await physics_frame
		await physics_frame
		_hold(way, false)
	_key(KEY_SPACE, true)
	await physics_frame
	_key(KEY_SPACE, false)
	_last_swing = _frame
	await _wait(6)


## Goes after the monsters the sword can bite, the nearest first, for up to `seconds`. Those
## that fly come to him; those he has no way to are left. A Bogwisp is gone after only if he
## carries a light: it has a body once his light reaches it, and he strikes when it does.
func _hunt(seconds: float) -> void:
	if not _armed():
		return
	var here: StringName = _area_id()
	var was: String = _ctx
	_ctx = "fight"
	var until: int = _frame + int(seconds * 60.0)
	var idle: int = 0
	var lit: bool = _has_light()
	while _frame < until and _area_id() == here and not _busy() and _day_is_on() and idle < 240:
		# A wisp's touch takes fifteen energy: he eats before he is too low to take one.
		if not await _keep_fit(36.0 if lit else 12.0):
			break
		var foes: Array = _monsters().filter(func(monster: Node2D) -> bool: return _can_be_hit(monster) or (lit and _is_wisp(monster)))
		var foe: Node2D = _nearest(foes)
		if foe == null:
			break
		var offset: Vector2 = foe.position - _hero().position
		if _is_wisp(foe):
			# A wisp is let come: it stops to flare, he steps out of its line, and he goes at it
			# while it rests after its dart. Far off, he walks nearer until it notices him.
			var state: StringName = foe.get(&"brain").get(&"state")
			if state == &"flare" or state == &"dart":
				idle = 0
				await _meet(foe)
				continue
			if state != &"rest" and state != &"hurt" and offset.length() > SWORD_REACH:
				if offset.length() <= 84.0:
					idle += 1
					if _verbose and idle % 40 == 0:
						_note("  waiting for a wisp: %s, %.0f px off, lit %s, he is at %s, it at %s" % [state, offset.length(), foe.get(&"brain").get(&"lit"), _hero().position, foe.position])
					_release_all()
					await physics_frame
					continue
		if offset.length() <= SWORD_REACH:
			idle = 0
			if _can_be_hit(foe) and _frame - _last_swing >= SWING_EVERY:
				await _swing_at(offset)
			else:
				await physics_frame
				await _mind_monsters()
			continue
		# A step nearer: to the cell beside it that he can get to (never onto a way out).
		var ways_out: Dictionary = _ways_out()
		var goals: Array[Vector2i] = []
		for side: Vector2i in [Vector2i.ZERO, Vector2i.UP, Vector2i.DOWN, Vector2i.LEFT, Vector2i.RIGHT]:
			if not ways_out.has(_cell_at(foe.position) + side):
				goals.append(_cell_at(foe.position) + side)
		var path: Array[Vector2i] = _path(_cell(), goals)
		if path.is_empty():
			idle += 1
			_release_all()
			await physics_frame
			await _mind_monsters()
			continue
		idle = 0
		if not await _step_to(path[0], here):
			await physics_frame
	_release_all()
	if _verbose:
		_note("  the hunt ends in %s: %d monsters still up, idle %d, %d frames left" % [_area_id(), _monsters().size(), idle, until - _frame])
	_ctx = was


func _armed() -> bool:
	return _count(&"wooden_sword") > 0 or _count(&"iron_sword") > 0


## Whether he carries a lantern: its light gives a Bogwisp a body.
func _has_light() -> bool:
	return _count(&"lantern") > 0 or _count(&"miners_lantern") > 0


# --- Energy and food ---------------------------------------------------------------------------

## Whether he has `needed` energy to spend and still keep a little for the walk home.
func _fit_for(needed: float) -> bool:
	return float(_gs.get(&"energy")) >= needed + 4.0


func _has_food() -> bool:
	for food: StringName in FOODS:
		if _count(food) > 0:
			return true
	return false


## Eats (from the food menu, Tab) until he has `needed` energy, if he carries food. False if
## he is still short.
func _keep_fit(needed: float) -> bool:
	for bite: int in 6:
		if float(_gs.get(&"energy")) >= needed:
			return true
		if not _has_food() or not await _eat():
			return false
	return float(_gs.get(&"energy")) >= needed


func _eat() -> bool:
	var food: StringName = &""
	for item: StringName in FOODS:
		if _count(item) > 0:
			food = item
			break
	if food == &"" or _busy():
		return false
	var was: String = _ctx
	_ctx = "eat"
	_release_all()
	await _wait(4)
	await _tap(KEY_TAB)
	var menu: Node = _hud().get(&"item_menu")
	if not await _until(func() -> bool: return bool(menu.call(&"is_open")), 40):
		_ctx = was
		return false
	for step: int in 20:
		if StringName(menu.call(&"selected_id")) == food:
			break
		await _tap(KEY_S)
	var ate: bool = false
	if StringName(menu.call(&"selected_id")) == food:
		var before: int = _count(food)
		await _tap(KEY_Q)
		await _wait(6)
		ate = _count(food) < before
	if bool(menu.call(&"is_open")):
		await _tap(KEY_TAB)
	await _wait(6)
	_ctx = was
	return ate


# --- Going to bed ------------------------------------------------------------------------------

func _go_to_bed() -> void:
	if not _day_is_on():
		_note("the day ended by itself: he woke on day %s" % _gs.get(&"day"))
		await _until(func() -> bool: return _in_area(), 600)
		await _wait(120)
		return
	_ctx = "walk"
	if not await _travel_to(&"home"):
		_note("!! he did not get home (%s): the script waits for the day to end" % _area_id())
		await _until(func() -> bool: return not _day_is_on(), 60 * 900)
		await _wait(120)
		return
	_cur["bed_time"] = _clock()
	_cur["energy_left"] = snappedf(float(_gs.get(&"energy")), 0.1)
	_ctx = "sleep"
	if await _talk_to("Bed"):
		await _say("Sleep until morning.")
	await _until(func() -> bool: return not _day_is_on(), 600)
	await _wait(150)


# --- Getting about -----------------------------------------------------------------------------

## Walks from area to area until he is in `target`.
func _travel_to(target: StringName) -> bool:
	for hop: int in 14:
		if not _day_is_on():
			return false
		await _until(func() -> bool: return _in_area(), 300)
		var here: StringName = _area_id()
		if here == target:
			return true
		var next: StringName = _next_hop(here, target)
		if next == &"" or not await _leave_to(next):
			return _area_id() == target
	return _area_id() == target


## The area to walk into next on the way from `here` to `target`.
func _next_hop(here: StringName, target: StringName) -> StringName:
	if String(here).begins_with("quarry_"):
		return &"quarry"
	var down: Array[StringName] = [target]
	while TOWARD_VILLAGE.has(down[-1]):
		down.append(TOWARD_VILLAGE[down[-1]])
	var index: int = down.find(here)
	if index > 0:
		return down[index - 1]
	return TOWARD_VILLAGE.get(here, &"")


## Leaves for the area `next` by the nearest way that leads there.
func _leave_to(next: StringName) -> bool:
	var way: Node2D = null
	var steps: Dictionary = _steps_from(_cell())
	var best: int = 1 << 30
	for thing: Node in _things():
		if &"target_area" in thing and StringName(thing.get(&"target_area")) == next:
			for cell: Vector2i in _cells_of_way(thing as Node2D):
				var near: int = _steps_to_side(steps, cell)
				if near >= 0 and near < best:
					best = near
					way = thing as Node2D
	if way == null:
		_note("!! no way from %s to %s" % [_area_id(), next])
		return false
	return await _leave_by(way)


## Walks onto the way out `way` (a door, a road's end, a ladder) and waits to arrive.
func _leave_by(way: Node2D) -> bool:
	var here: StringName = _area_id()
	var next: StringName = way.get(&"target_area")
	var cells: Array[Vector2i] = _cells_of_way(way)
	for attempt: int in 4:
		if _area_id() != here:
			break
		var path: Array[Vector2i] = _path(_cell(), cells)
		if _verbose:
			_note("  leaving %s for %s: at %s, way out %s, %d steps" % [here, next, _cell(), cells, path.size()])
		if path.is_empty():
			await _wait(20)
			continue
		var walked: bool = await _follow(path)
		if _verbose:
			_note("  walked: %s; now at %s %s in %s" % [walked, _cell() if _in_area() else Vector2i.ZERO, _pos() if _in_area() else Vector2.ZERO, _area_id()])
		if await _until(func() -> bool: return _area_id() != here, 40):
			break
	_release_all()
	var arrived: bool = await _until(func() -> bool: return _area_id() == next, 300)
	_release_all()
	# A key held through a door is not obeyed on the other side until it is let go.
	await _wait(24)
	return arrived


func _cells_of_way(way: Node2D) -> Array[Vector2i]:
	var out: Array[Vector2i] = []
	var size: Vector2i = way.get(&"size")
	for x: int in size.x:
		for y: int in size.y:
			out.append(_cell_of(way) + Vector2i(x, y))
	return out


## Walks to a cell beside `cell` and faces it.
func _stand_by(cell: Vector2i) -> bool:
	var spots: Array[Vector2i] = []
	for side: Vector2i in SIDES:
		spots.append(cell + side)
	if not await _walk_to_any(spots):
		return false
	await _face(cell - _cell())
	return _front() == cell


func _walk_to(goal: Vector2i) -> bool:
	return await _walk_to_any([goal])


## Walks to the nearest of `goals` he can get to. True once he stands in the middle of one.
func _walk_to_any(goals: Array[Vector2i]) -> bool:
	var here: StringName = _area_id()
	for attempt: int in 5:
		if _area_id() != here or not _day_is_on():
			return false
		if _busy():
			await _wait(20)
			continue
		if goals.has(_cell()):
			if await _step_to(_cell(), here):
				_release_all()
				return true
			continue
		var path: Array[Vector2i] = _path(_cell(), goals)
		if path.is_empty():
			_release_all()
			return false
		if await _follow(path):
			return true
		await _wait(8)
	_release_all()
	return false


## Walks along `path`, a cell at a time. False if he was stopped or taken elsewhere.
func _follow(path: Array[Vector2i]) -> bool:
	var here: StringName = _area_id()
	if not await _step_to(_cell(), here):
		_release_all()
		return false
	for cell: Vector2i in path:
		if not await _step_to(cell, here):
			_release_all()
			return false
	_release_all()
	await _wait(2)
	return true


## Walks to the middle of `cell`, his own or the next one, minding monsters as he goes.
func _step_to(cell: Vector2i, here: StringName) -> bool:
	var target: Vector2 = _centre(cell)
	for frame: int in 300:
		if _area_id() != here or _busy() or not _day_is_on():
			return false
		var offset: Vector2 = target - _pos()
		if absf(offset.x) <= 1.6 and absf(offset.y) <= 1.6:
			return true
		# Knocked more than a cell away: the path no longer holds.
		if maxi(absi(_cell().x - cell.x), absi(_cell().y - cell.y)) > 1:
			return false
		_release_all()
		if absf(offset.x) > 1.6 and (absf(offset.x) >= absf(offset.y) or absf(offset.y) <= 1.6):
			_hold(Vector2i.RIGHT if offset.x > 0.0 else Vector2i.LEFT, true)
		else:
			_hold(Vector2i.DOWN if offset.y > 0.0 else Vector2i.UP, true)
		await physics_frame
		await _mind_monsters()
	return false


## The cells to step through from `from` to the nearest of `goals`, the last one a goal.
## Empty if there is no way (or he is on one already). He walks on the level and up and down
## stairs; he never hops off a ledge, steps in a hole, or crosses a way out that is not his
## goal.
func _path(from: Vector2i, goals: Array[Vector2i]) -> Array[Vector2i]:
	var wanted: Dictionary = {}
	for goal: Vector2i in goals:
		wanted[goal] = true
	var empty: Array[Vector2i] = []
	if wanted.has(from):
		return empty
	var ways_out: Dictionary = _ways_out()
	var came: Dictionary = {from: from}
	var queue: Array[Vector2i] = [from]
	var head: int = 0
	while head < queue.size():
		var at: Vector2i = queue[head]
		head += 1
		for side: Vector2i in SIDES:
			var next: Vector2i = at + side
			if came.has(next) or not _can_step(at, next) or (ways_out.has(next) and not wanted.has(next)):
				continue
			came[next] = at
			if wanted.has(next):
				var path: Array[Vector2i] = []
				var back: Vector2i = next
				while back != from:
					path.push_front(back)
					back = came[back]
				return path
			queue.append(next)
	return empty


## How many steps it is from `from` to every cell he can walk to.
func _steps_from(from: Vector2i) -> Dictionary:
	var ways_out: Dictionary = _ways_out()
	var steps: Dictionary = {from: 0}
	var queue: Array[Vector2i] = [from]
	var head: int = 0
	while head < queue.size():
		var at: Vector2i = queue[head]
		head += 1
		for side: Vector2i in SIDES:
			var next: Vector2i = at + side
			if steps.has(next) or not _can_step(at, next) or ways_out.has(next):
				continue
			steps[next] = int(steps[at]) + 1
			queue.append(next)
	return steps


## The fewest steps to a cell beside `cell`, by `steps` (_steps_from); -1 if he can't get there.
func _steps_to_side(steps: Dictionary, cell: Vector2i) -> int:
	var best: int = -1
	for side: Vector2i in SIDES:
		if steps.has(cell + side) and (best == -1 or int(steps[cell + side]) < best):
			best = int(steps[cell + side])
	return best


func _can_step(from: Vector2i, to: Vector2i) -> bool:
	var terrain: RefCounted = _area().get(&"terrain")
	var move: MoveResult = terrain.call(&"check_move", from, to)
	return move.kind == MoveResult.Kind.WALK and not bool(terrain.call(&"is_pit", to))


## Whether he could step from his cell into the neighbouring `cell` without leaving the area.
func _free(cell: Vector2i) -> bool:
	return _can_step(_cell(), cell) and not _ways_out().has(cell)


## The cells of every way out of this area.
func _ways_out() -> Dictionary:
	var out: Dictionary = {}
	for thing: Node in _things():
		if &"target_area" in thing:
			for cell: Vector2i in _cells_of_way(thing as Node2D):
				out[cell] = true
	return out


# --- People and things -------------------------------------------------------------------------

## Walks onto the thing called `thing_name` and picks it up (right click).
func _pick_up(thing_name: String) -> bool:
	var thing: Node2D = _thing(thing_name)
	if thing == null or bool(thing.call(&"taken")):
		_note("nothing to pick up: %s" % thing_name)
		return false
	if not await _walk_to(_cell_of(thing)):
		_note("!! no way to %s" % thing_name)
		return false
	await _click(MOUSE_BUTTON_RIGHT)
	await _wait(75)
	_note("picked up %s: '%s'" % [thing_name, _hud().call(&"message_text")])
	return true


## Stands before the person or thing called `who` and starts talking (right click).
func _talk_to(who: String) -> bool:
	var thing: Node2D = _thing(who)
	if thing == null or not await _stand_by(_cell_of(thing)):
		_note("!! could not stand before %s" % who)
		return false
	await _click(MOUSE_BUTTON_RIGHT)
	return await _until(func() -> bool: return _talking(), 60)


## Chooses the answer that reads `text` (or, if not `exact`, begins with it): the cursor is
## moved to it with the keys and Enter takes it.
func _say(text: String, exact: bool = true) -> bool:
	await _wait(26)
	if not _talking():
		return false
	var box: Node = _hud().get(&"dialogue")
	var options: PackedStringArray = box.call(&"shown_options")
	var index: int = -1
	for i: int in options.size():
		if options[i] == text or (not exact and options[i].begins_with(text)):
			index = i
			break
	if index == -1:
		_note("no answer '%s' among %s" % [text, options])
		return false
	for step: int in 16:
		var selected: int = box.get(&"selected")
		if selected == index:
			break
		await _tap(KEY_S if index > selected else KEY_W)
	await _tap(KEY_ENTER)
	await _wait(10)
	return true


## Ends the conversation by its last answer, as often as it takes.
func _end_talk() -> void:
	for turn: int in 6:
		await _wait(20)
		if not _talking():
			return
		var box: Node = _hud().get(&"dialogue")
		var count: int = (box.call(&"shown_options") as PackedStringArray).size()
		for step: int in 16:
			if count == 0 or int(box.get(&"selected")) == count - 1:
				break
			await _tap(KEY_S)
		await _tap(KEY_ENTER)
	await _wait(10)


func _words() -> String:
	return str(_hud().get(&"dialogue").call(&"shown_text"))


## Puts `item` in his hand: its number on the bar, or the wheel if it is past the ninth slot.
func _take_in_hand(item: StringName) -> bool:
	if item == &"":
		return false
	for attempt: int in 14:
		if StringName(_gs.get(&"equipped")) == item:
			return true
		var entries: Array = _gs.call(&"hand_entries")
		var index: int = -1
		for i: int in entries.size():
			if StringName(str((entries[i] as Dictionary).get("id", ""))) == item:
				index = i
		if index == -1:
			return false
		var bar: Node = _hud().get(&"item_bar")
		var slot: int = index - int(bar.get(&"top"))
		if slot >= 0 and slot < mini(int(bar.call(&"shown_count")), 9):
			await _tap((KEY_1 + slot) as Key)
		else:
			await _wheel()
	return StringName(_gs.get(&"equipped")) == item


## The first of `items` that he carries, or "".
func _best(items: Array[StringName]) -> StringName:
	for item: StringName in items:
		if _count(item) > 0:
			return item
	return &""


# --- The title ---------------------------------------------------------------------------------

func _new_game_from_the_title() -> void:
	change_scene_to_file(TITLE_SCENE)
	await _until(func() -> bool: return current_scene != null and current_scene.has_method(&"choose"), 300)
	await _wait(60)
	var title: Node = current_scene
	for step: int in 6:
		if StringName(title.get(&"cursor").call(&"selected_id")) == &"new_game":
			break
		await _tap(KEY_S)
	_shot("d1_00_title")
	_note("the title: Enter on '%s'" % title.get(&"cursor").call(&"selected_id"))
	await _tap(KEY_ENTER)
	await _until(func() -> bool: return _area_id() == &"village", 300)
	await _wait(60)
	_note("a new game: %s, coins %d, hearts %s, energy %s" % [_clock(), _count(&"coin"), _gs.get(&"health"), _gs.get(&"energy")])


# --- Pressing things ---------------------------------------------------------------------------

func _key(code: Key, pressed: bool) -> void:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = pressed
	Input.parse_input_event(event)
	# Handed on at once, not at the next picture: a key is down in the very step it is pressed.
	Input.flush_buffered_events()


func _tap(code: Key) -> void:
	_key(code, true)
	await physics_frame
	await physics_frame
	_key(code, false)
	await physics_frame
	await physics_frame


func _hold(way: Vector2i, on: bool) -> void:
	if bool(_held.get(way, false)) == on:
		return
	_held[way] = on
	_key(KEYS[way], on)


func _release_all() -> void:
	for way: Vector2i in KEYS:
		_hold(way, false)


## Turns him to face `way` (a tap of its key), if he doesn't already.
func _face(way: Vector2i) -> void:
	if not KEYS.has(way):
		return
	_release_all()
	for attempt: int in 3:
		if Vector2i(_hero().call(&"facing_direction")) == way:
			break
		_hold(way, true)
		await physics_frame
		await physics_frame
		_hold(way, false)
		await _wait(3)


## A click of a mouse button. In play where it lands doesn't matter; it lands clear of the
## lists, so that in one it chooses the highlighted line.
func _click(button: MouseButton) -> void:
	var at: Vector2 = root.get_final_transform() * Vector2(320, 12)
	for pressed: bool in [true, false]:
		var event: InputEventMouseButton = InputEventMouseButton.new()
		event.button_index = button
		event.pressed = pressed
		event.position = at
		event.global_position = at
		Input.parse_input_event(event)
		Input.flush_buffered_events()
		await physics_frame
		await physics_frame


## The mouse wheel, a notch down.
func _wheel() -> void:
	await _click(MOUSE_BUTTON_WHEEL_DOWN)


# --- Looking at the game -----------------------------------------------------------------------

func _in_area() -> bool:
	return current_scene != null and &"area_id" in current_scene and current_scene.get(&"player") != null


func _area() -> Node:
	return current_scene


func _area_id() -> StringName:
	return StringName(current_scene.get(&"area_id")) if _in_area() else &""


func _hero() -> Node2D:
	return _area().get(&"player")


func _motor() -> RefCounted:
	return _hero().get(&"motor")


func _cell() -> Vector2i:
	return _motor().get(&"cell")


func _pos() -> Vector2:
	return _motor().get(&"position")


func _front() -> Vector2i:
	return _hero().call(&"front_cell")


func _hud() -> Node:
	return _area().get(&"hud")


func _things() -> Array[Node]:
	return (_area().get(&"interactables") as Node).get_children()


func _thing(thing_name: String) -> Node2D:
	return (_area().get(&"interactables") as Node).get_node_or_null(NodePath(thing_name)) as Node2D


func _cell_at(point: Vector2) -> Vector2i:
	return Vector2i((point / float(TILE)).floor())


func _cell_of(node: Node2D) -> Vector2i:
	return _cell_at(node.position + Vector2(0.5, 0.5))


func _centre(cell: Vector2i) -> Vector2:
	return Vector2(cell) * float(TILE) + Vector2(8.0, 8.0)


func _talking() -> bool:
	return _in_area() and bool(_area().call(&"is_talking"))


## Whether he can't act just now: between areas, talking, at a list, fallen or collapsing.
func _busy() -> bool:
	if not _in_area():
		return true
	var area: Node = _area()
	return bool(area.call(&"is_talking")) or bool(area.call(&"is_in_menu")) or bool(area.call(&"is_dying")) or bool(area.call(&"is_collapsing"))


## Whether it is still the day the script is playing.
func _day_is_on() -> bool:
	return int(_gs.get(&"day")) == _today


func _count(item: StringName) -> int:
	return int(_gs.call(&"item_count", item))


func _clock() -> String:
	return str(_gs.call(&"time_text"))


func _level(skill: StringName) -> int:
	return int(_gs.call(&"skill_level", skill))


func _cardinal(offset: Vector2) -> Vector2i:
	if absf(offset.x) >= absf(offset.y):
		return Vector2i.RIGHT if offset.x > 0.0 else Vector2i.LEFT
	return Vector2i.DOWN if offset.y > 0.0 else Vector2i.UP


## "Copper Ore x7, Stone x12": what is in the pack, coins aside.
func _carrying() -> String:
	var parts: PackedStringArray = []
	for stack: Dictionary in _gs.get(&"inventory"):
		if StringName(stack["id"]) != &"coin":
			parts.append("%s x%d" % [stack["id"], int(stack["count"])])
	return ", ".join(parts) if not parts.is_empty() else "nothing"


# --- Waiting -----------------------------------------------------------------------------------

func _wait(frames: int) -> void:
	for i: int in frames:
		await physics_frame


## Waits until `test` is true, for `frames` at the most. Returns whether it came true.
func _until(test: Callable, frames: int) -> bool:
	for i: int in frames:
		if bool(test.call()):
			return true
		await physics_frame
	return bool(test.call())


func _on_physics_frame() -> void:
	_frame += 1
	# The game sets the engine's pace back to life's after every moment's freeze (a hit's
	# weight): a trial run that is to go faster says so again.
	if _speed != 1.0 and is_equal_approx(Engine.time_scale, 1.0):
		Engine.time_scale = _speed


# --- Writing it down ---------------------------------------------------------------------------

func _begin_day(day: int) -> void:
	_today = day
	_given_up.clear()
	_energy_was = float(_gs.get(&"energy"))
	_health_was = int(_gs.get(&"health"))
	_ctx = "walk"
	_cur = {
		"day": day, "plan": "", "woke": _clock(), "coins_at_dawn": _count(&"coin"), "energy_at_dawn": snappedf(_energy_was, 0.1),
		"energy_spent": 0.0, "energy_by": {}, "energy_eaten": 0.0, "flows": [], "crafted": [], "rocks": {}, "floors": [],
		"blows": 0, "touches": 0, "beaten": 0, "falls": 0, "hearts_lost": 0, "news": [], "frames": _frame, "cleared": {}, "set_down": [],
		"farm_at_dawn": _farm_record(),
		"skills_at_dawn": _skills(),
	}
	_note("=== DAY %d begins: coins %d, energy %.0f, %s" % [day, _count(&"coin"), _energy_was, _carrying()])


func _plan(words: String) -> void:
	_cur["plan"] = words
	_note("the day's plan: %s" % words)


func _end_day() -> void:
	_cur["seconds"] = snappedf((_frame - int(_cur["frames"])) / 60.0, 0.1)
	_cur.erase("frames")
	_cur.erase("wisp_shot")
	_cur["coins_at_dusk"] = _count(&"coin")
	_cur["skills_at_dusk"] = _skills()
	_cur["pack_at_dusk"] = _carrying()
	_cur["farm_at_dusk"] = _farm_record()
	_cur["energy_spent"] = snappedf(float(_cur["energy_spent"]), 0.1)
	_cur["energy_eaten"] = snappedf(float(_cur["energy_eaten"]), 0.1)
	for key: String in (_cur["energy_by"] as Dictionary).keys():
		(_cur["energy_by"] as Dictionary)[key] = snappedf(float((_cur["energy_by"] as Dictionary)[key]), 0.1)
	_days.append(_cur)
	_note("=== DAY %d ends (%s in bed): energy spent %.1f, eaten %.1f; coins %d -> %d; %.0f s played" % [
		int(_cur["day"]), _cur.get("bed_time", "no bed"), float(_cur["energy_spent"]), float(_cur["energy_eaten"]),
		int(_cur["coins_at_dawn"]), int(_cur["coins_at_dusk"]), float(_cur["seconds"])])


func _skills() -> Dictionary:
	var out: Dictionary = {}
	for skill: String in ["combat", "farming", "cooking", "mining"]:
		out[skill] = _level(StringName(skill))
	return out


func _set_up(words: String) -> void:
	_by_hand.append("SETUP (day %d): %s." % [_today, words])
	_note("SETUP: %s" % words)


func _note(text: String) -> void:
	var line: String = "[%6.1f s  %s  hearts %s  energy %3.0f  coins %3d] %s" % [
		(Time.get_ticks_msec() - _started) / 1000.0, _clock(), _gs.get(&"health"), float(_gs.get(&"energy")), _count(&"coin"), text]
	_lines.append(line)
	print(line)


func _shot(shot_name: String) -> void:
	root.get_texture().get_image().save_png(_out.path_join(shot_name + ".png"))


func _write_out() -> void:
	_note("END after %.0f seconds" % ((Time.get_ticks_msec() - _started) / 1000.0))
	var log_file: FileAccess = FileAccess.open(_out.path_join("play_log.txt"), FileAccess.WRITE)
	log_file.store_string("\n".join(_lines) + "\n")
	log_file.close()
	var data_file: FileAccess = FileAccess.open(_out.path_join("days.json"), FileAccess.WRITE)
	data_file.store_string(JSON.stringify({"days": _days, "by_hand": _by_hand}, "\t") + "\n")
	data_file.close()


func _on_item_added(item_id: StringName, count: int) -> void:
	if _cur.is_empty():
		return
	(_cur["flows"] as Array).append({"ctx": _ctx, "item": String(item_id), "count": count, "area": String(_area_id())})


func _on_energy_changed(current: float, _maximum: float) -> void:
	var change: float = current - _energy_was
	_energy_was = current
	if _cur.is_empty() or _ctx == "sleep" or not _day_is_on():
		return
	if change < 0.0:
		_cur["energy_spent"] = float(_cur["energy_spent"]) - change
		var by: Dictionary = _cur["energy_by"]
		by[_ctx] = float(by.get(_ctx, 0.0)) - change
	else:
		_cur["energy_eaten"] = float(_cur["energy_eaten"]) + change


func _on_health_changed(current: int, _maximum: int) -> void:
	if not _cur.is_empty() and current < _health_was:
		_cur["hearts_lost"] = int(_cur["hearts_lost"]) + _health_was - current
	if current <= 0:
		_fell = true
	_health_was = current


func _on_sound(id: StringName) -> void:
	if _cur.is_empty():
		return
	match id:
		&"pick", &"rock_break":
			_cur["blows"] = int(_cur["blows"]) + 1
		&"hurt":
			_cur["touches"] = int(_cur["touches"]) + 1
		&"enemy_die":
			_cur["beaten"] = int(_cur["beaten"]) + 1


func _on_crafted(recipe_id: StringName) -> void:
	if not _cur.is_empty():
		(_cur["crafted"] as Array).append(String(recipe_id))


func _on_skill_rose(skill: StringName, level: int) -> void:
	if not _cur.is_empty():
		(_cur["news"] as Array).append("%s rose to level %d at %s" % [skill, level, _clock()])
	_note("%s rose to level %d" % [skill, level])


func _on_quest_announced(quest_id: StringName, what: StringName) -> void:
	_note("quest %s: %s" % [quest_id, what])
