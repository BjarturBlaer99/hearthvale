extends Node
## Owns every piece of state that must survive a save (docs/TECH_DESIGN.md §2, §9).
##
## Scene nodes never hide game state: they read it here and change it through these
## methods, which emit the matching EventBus signal. `to_dict()` / `from_dict()` use the
## save format from TECH_DESIGN §9; SaveSystem handles files and version migration.

const SAVE_VERSION: int = 6
const HALVES_PER_HEART: int = 2
const START_HEARTS: int = 3
const MAX_HEARTS: int = 20
## Pieces of heart that make one heart container.
const PIECES_PER_HEART: int = 4
## The item that is money.
const COIN: StringName = &"coin"
## What the tally counts: every crop picked from the plot.
const CROPS_PICKED: StringName = &"crops_picked"

## Heart containers the hero has (0 until a game starts).
var hearts_max: int = 0
## Health in half hearts, 0..max_health().
var health: int = 0
## Pieces of heart found toward the next heart container, 0..PIECES_PER_HEART - 1.
var heart_pieces: int = 0
## flag -> value. A missing flag reads as false.
var flags: Dictionary[StringName, Variant] = {}
## flag -> the day it came true (P4a), for what waits a day on it (the `days_since` condition).
## A flag that came true before days were kept (an older save) has none, and counts as long ago.
var flag_days: Dictionary[StringName, int] = {}
## skill id -> points earned. Saved since version 4; nothing earns them until P4b.
var skill_points: Dictionary[StringName, int] = {}
## villager id -> { "points", "talked", "gift" }: friendship, and the days he last talked to
## them and gave them something. Saved since version 4; nothing changes them until P4c.
var friends: Dictionary[StringName, Dictionary] = {}
## What the game has counted over all its days: what -> how many (CROPS_PICKED).
var tally: Dictionary[StringName, int] = {}
## quest id -> current stage id
var quests: Dictionary[StringName, StringName] = {}
## Stacks of { "id": StringName, "count": int }, in pickup order. Capped by Inventory rules.
var inventory: Array[Dictionary] = []
## The item on the item button (bow, bombs), or empty.
var equipped: StringName = &""
## Seconds played, counted while an area runs unpaused (add_play_time).
var play_time: float = 0.0
## The day of the game: 1 is the first.
var day: int = 1
## The time of day, in minutes since the midnight the day began on (DayClock): 360 is 06:00,
## and 1560 is 02:00 at the day's end.
var minute: float = 360.0
## The hero's energy, 0..max_energy() (0 until a game starts). Apart from hearts: energy never
## costs a heart (GDD §5).
var energy: float = 0.0

## Words for the area the hero arrives in to say once (he woke at home after staying up too
## late). Not part of a save: it is gone once said.
var arrival_notice: String = ""

var _day_clock: DayClock
var _energy_rules: EnergyRules
var _skills: Skills
var _friendship: Friendship
## The hero's plot (P3): made from the farm's rules when first asked for. Saved.
var _farm: Farm
## What the mine remembers (2026-11-17): the number its rolls come from and today's broken
## rocks. Saved.
var _mine: MineState
var _mine_rules: MineRules
## Every item he has ever held (crafting, 2026-11-17): a recipe that waits on a thing being
## found stays known when the last of it is gone. Saved.
var found: Dictionary[StringName, bool] = {}
## The furnace in his home: what it holds and the day it was lit. Saved.
var _furnace: Furnace
## The furnaces and chests of buildings' rooms (the Homestead's shed), by their keys ("shed",
## "shed_a", "shed_b"). The farmhouse's are `_furnace` and `_store`.
var _room_furnaces: Dictionary[StringName, Furnace] = {}
var _room_stores: Dictionary[StringName, Store] = {}
## The storage chest in his home: its stacks. Saved.
var _store: Store
## His homestead (2026-11-17): what he has cleared from the land for good. Saved.
var _homestead: Homestead
var _homestead_rules: HomesteadRules
## The land as it is before he does anything to it (LandSurvey), read once a run.
var _land_map: LandMap
## What the morning has to say (the Homestead: a building finished), until an area says it.
## Not saved: it is said as the next area loads, or at once in the area he is in.
var morning_news: PackedStringArray = []
## Where the hero is: { "area", "cell": [x, y] }, or { "area", "entry" } on the way into an
## area through one of its entry points (go_to), until the area places them.
var player: Dictionary = {}


## Starts a fresh game: full health with the starting hearts, nothing else.
func new_game() -> void:
	clear()
	hearts_max = START_HEARTS
	health = max_health()
	energy = max_energy()
	# Every game's mine rolls its own way.
	_mine = MineState.new(randi())


func is_started() -> bool:
	return hearts_max > 0


# --- Health ----------------------------------------------------------------

func max_health() -> int:
	return hearts_max * HALVES_PER_HEART


func damage(halves: int) -> void:
	set_health(health - maxi(halves, 0))


func heal(halves: int) -> void:
	set_health(health + maxi(halves, 0))


## A heart container: one more heart, and health refills (as in classic Zeldas).
func add_heart_container() -> void:
	hearts_max = mini(hearts_max + 1, MAX_HEARTS)
	health = max_health()
	EventBus.health_changed.emit(health, max_health())


## A piece of heart: every PIECES_PER_HEART of them make a heart container. Returns the
## pieces now held toward the next one (0 when they just made a heart).
func add_heart_piece() -> int:
	heart_pieces += 1
	if heart_pieces >= PIECES_PER_HEART:
		heart_pieces = 0
		add_heart_container()
	EventBus.heart_piece_found.emit(heart_pieces)
	return heart_pieces


## Counts `seconds` of play. It changes every frame, so it announces nothing.
func add_play_time(seconds: float) -> void:
	play_time += maxf(seconds, 0.0)


## "4:07" or "1:02:09".
static func format_play_time(seconds: float) -> String:
	var total: int = floori(maxf(seconds, 0.0))
	@warning_ignore("integer_division")
	var hours: int = total / 3600
	@warning_ignore("integer_division")
	var minutes: int = (total / 60) % 60
	if hours > 0:
		return "%d:%02d:%02d" % [hours, minutes, total % 60]
	return "%d:%02d" % [minutes, total % 60]


# --- Energy ----------------------------------------------------------------

## The rules of the hero's energy, from data (data/rules/energy.json).
func energy_rules() -> EnergyRules:
	if _energy_rules == null:
		_energy_rules = EnergyRules.new(DataRegistry.get_rules(DataRegistry.RULES_ENERGY))
	return _energy_rules


## A full bar.
func max_energy() -> float:
	return energy_rules().maximum


func set_energy(value: float) -> void:
	var clamped: float = clampf(value, 0.0, max_energy())
	if clamped == energy:
		return
	energy = clamped
	EventBus.energy_changed.emit(energy, max_energy())


## What `action` (one of EnergyRules' costs) costs the hero now: the rules' cost, less what
## his skill at that work takes off it (P4b).
func energy_cost(action: String) -> float:
	return energy_rules().cost(action) * skills().cost_factor(action, skill_points)


## Spends `amount` of energy (what a swing costs, or a moment's running). It never goes under
## nothing.
func spend_energy(amount: float) -> void:
	set_energy(energy_rules().after(energy, maxf(amount, 0.0)))


## Eats one `item_id` (GDD §6): its energy, and the hearts a meal mends. Returns false, and
## uses nothing, if he has none, it isn't food, or it would do him no good (a full bar and
## nothing to mend).
func eat(item_id: StringName) -> bool:
	var item: Dictionary = DataRegistry.get_item(item_id)
	if item_count(item_id) <= 0 or not Food.would_help(item, energy, max_energy(), health, max_health()):
		return false
	var gives: float = food_energy(item_id)
	add_item(item_id, -1)
	set_energy(energy + gives)
	heal(Food.halves_of(item))
	return true


## The energy eating one `item_id` gives the hero now. A dish (anything a recipe makes) gives
## more to a better cook (P4b); other food gives what its data says.
func food_energy(item_id: StringName) -> float:
	var gives: float = Food.energy_of(DataRegistry.get_item(item_id))
	if Cooking.is_dish(DataRegistry.entries(&"recipes"), String(item_id)):
		gives *= skills().dish_factor(skill_points)
	return gives


## Whether the hero has no energy left: he collapses (the area sees to it).
func is_exhausted() -> bool:
	return is_started() and energy_rules().is_spent(energy)


## The hero collapsed, or stayed up until the day ran out (GDD §5, §6): the next day begins, he
## has half his energy, and some of his coins are gone. His hearts are as they were. Returns how
## many coins he lost.
func collapse() -> int:
	start_next_day()
	set_energy(energy_rules().wake_energy())
	var lost: int = energy_rules().coins_lost(item_count(COIN))
	if lost > 0:
		add_item(COIN, -lost)
	return lost


# --- Recipes ---------------------------------------------------------------

## Whether the hero knows the recipe `recipe_id`: one known from the start, or one he was taught.
func knows_recipe(recipe_id: StringName) -> bool:
	var recipe: Dictionary = DataRegistry.get_recipe(recipe_id)
	return not recipe.is_empty() and (not Cooking.is_taught(recipe) or get_flag(Cooking.known_flag(recipe_id)) == true)


## The recipes the hero knows (data entries), in the data's order: what the hearth lists.
func known_recipes() -> Array[Dictionary]:
	return Cooking.known(DataRegistry.entries(&"recipes"), flags)


## The hero is taught the recipe `recipe_id` (the `teach_recipe` effect). Returns whether he
## learned it: false for no such recipe, or one he knows already. Learning is said
## (EventBus.recipe_learned).
func learn_recipe(recipe_id: StringName) -> bool:
	if DataRegistry.get_recipe(recipe_id).is_empty() or knows_recipe(recipe_id):
		return false
	set_flag(Cooking.known_flag(recipe_id), true)
	EventBus.recipe_learned.emit(recipe_id)
	return true


# --- Skills ----------------------------------------------------------------

## The rules of the hero's skills, from data (data/rules/skills.json).
func skills() -> Skills:
	if _skills == null:
		_skills = Skills.new(DataRegistry.get_rules(DataRegistry.RULES_SKILLS))
	return _skills


## The hero's level at `skill`: 1 until its points reach the second level.
func skill_level(skill: StringName) -> int:
	return skills().level_of(skill, skill_points)


## The chance that a rock of ore gives one more (0 to 1): what his Mining adds.
func extra_ore_chance() -> float:
	return skills().extra_chance(Skills.MINING, skill_points)


## The hero does a `deed` that `skill` grows by (Skills' deeds: a monster beaten, a cell
## tilled, a dish cooked). Its points are added, and if that raises its level, it is said
## (EventBus.skill_rose). Returns the points gained: 0 if the skill doesn't grow by that.
func practise(skill: StringName, deed: StringName) -> int:
	var points: int = skills().gain(skill, deed)
	if points <= 0:
		return 0
	var before: int = skill_level(skill)
	skill_points[skill] = int(skill_points.get(skill, 0)) + points
	var after: int = skill_level(skill)
	if after > before:
		EventBus.skill_rose.emit(skill, after)
	return points


# --- Friends ---------------------------------------------------------------

## The rules of friendship, from data (data/rules/friendship.json).
func friendship() -> Friendship:
	if _friendship == null:
		_friendship = Friendship.new(DataRegistry.get_rules(DataRegistry.RULES_FRIENDSHIP))
	return _friendship


## The hero's friendship with `villager` (a villager id), in points and in marks.
func friend_points(villager: StringName) -> int:
	return int((friends.get(villager, {}) as Dictionary).get("points", 0))


func friend_marks(villager: StringName) -> int:
	return friendship().marks_at(friend_points(villager))


## The hero talks to `villager`: the first time in a day is worth a little friendship. Returns
## the points gained (0 for a second talk that day, or someone who is no villager).
func greet(villager: StringName) -> int:
	if DataRegistry.get_villager(villager).is_empty() or Friendship.talked_on(friends.get(villager, {}), day):
		return 0
	_friend(villager)["talked"] = day
	return add_friendship(villager, friendship().talk)


## Whether `villager` can be given something today: one gift a villager a day.
func can_give(villager: StringName) -> bool:
	return not DataRegistry.get_villager(villager).is_empty() and not Friendship.given_on(friends.get(villager, {}), day)


## What the hero carries that can be given (item data entries), in the order it was picked up.
func gifts_held() -> Array[Dictionary]:
	return friendship().giftable_held(inventory, DataRegistry.entries(&"items"))


## Gives `villager` one `item_id`: it leaves the pack, and the friendship grows, more if they
## like it. A full friendship still takes a gift, which adds nothing to it. Returns { "liked",
## "points", "full" } (`full`: it was full already), or {} if nothing was given: no such
## villager, a gift already given today, none of that item, or a thing that can't be given.
func give_gift(villager: StringName, item_id: StringName) -> Dictionary:
	var who: Dictionary = DataRegistry.get_villager(villager)
	if not can_give(villager) or item_count(item_id) <= 0 or not friendship().is_giftable(DataRegistry.get_item(item_id)):
		return {}
	var full: bool = friendship().is_full(int(_friend(villager)["points"]))
	add_item(item_id, -1)
	_friend(villager)["gift"] = day
	var liked: bool = Friendship.likes(who, String(item_id))
	return {"liked": liked, "points": add_friendship(villager, friendship().gift_points(liked)), "full": full}


## Adds `points` to the friendship with `villager`, up to a full one. A mark gained is said
## (EventBus.friend_mark_gained). Returns the points added.
func add_friendship(villager: StringName, points: int) -> int:
	if DataRegistry.get_villager(villager).is_empty():
		return 0
	var friend: Dictionary = _friend(villager)
	var before: int = int(friend["points"])
	var after: int = friendship().after(before, points)
	friend["points"] = after
	if friendship().marks_at(after) > friendship().marks_at(before):
		EventBus.friend_mark_gained.emit(villager, friendship().marks_at(after))
	return after - before


## A conversation asks for the list of what can be given `villager` (the `gift` effect):
## whoever runs the area opens it.
func request_gift(villager: StringName) -> void:
	EventBus.gift_requested.emit(villager)


## The record of the friendship with `villager`, made if there is none yet.
func _friend(villager: StringName) -> Dictionary:
	if not friends.has(villager):
		friends[villager] = {"points": 0, "talked": 0, "gift": 0}
	return friends[villager]


# --- Time ------------------------------------------------------------------

## The rules of the day, from data (data/rules/time.json).
func day_clock() -> DayClock:
	if _day_clock == null:
		_day_clock = DayClock.new(DataRegistry.get_rules(DataRegistry.RULES_TIME))
	return _day_clock


## Lets `seconds` of real time pass on the day's clock, which stops at the day's end. Says so
## once for each minute of the day that goes by.
func advance_time(seconds: float) -> void:
	set_time(day_clock().advance(minute, seconds))


## Puts the clock at `to_minute` of this day (kept within the day).
func set_time(to_minute: float) -> void:
	var before: int = floori(minute)
	minute = clampf(to_minute, float(day_clock().starts), float(day_clock().ends))
	if floori(minute) != before:
		EventBus.time_changed.emit(day, floori(minute))


## Whether the day has run out (02:00).
func is_day_over() -> bool:
	return day_clock().is_over(minute)


## The hero's plot: which of its cells are tilled and which watered (GDD §7).
func farm() -> Farm:
	if _farm == null:
		_farm = Farm.new(DataRegistry.get_rules(DataRegistry.RULES_FARM))
	return _farm


## Sets a sprinkler in a cell of the plot (tilled, with nothing in it). Returns whether it did.
func place_sprinkler(cell: Vector2i) -> bool:
	if not farm().place_sprinkler(cell):
		return false
	EventBus.farm_changed.emit()
	return true


## Takes up the sprinkler in a cell of the plot. Returns whether there was one.
func take_sprinkler(cell: Vector2i) -> bool:
	if not farm().take_sprinkler(cell):
		return false
	EventBus.farm_changed.emit()
	return true


## Tills a cell of the plot (the plot's own cell). Returns whether it did.
func till_soil(cell: Vector2i) -> bool:
	if not farm().till(cell):
		return false
	practise(Skills.FARMING, Skills.TILL)
	EventBus.farm_changed.emit()
	return true


## Waters a tilled cell of the plot. Returns whether it did.
func water_soil(cell: Vector2i) -> bool:
	if not farm().water(cell):
		return false
	EventBus.farm_changed.emit()
	return true


## Plants a crop (a crop id) in a tilled, empty cell of the plot. Returns whether it did.
func plant_crop(cell: Vector2i, crop_id: StringName) -> bool:
	if DataRegistry.get_crop(crop_id).is_empty() or not farm().plant(cell, String(crop_id)):
		return false
	# The first seed in the ground: he has settled in, and the story may begin (P4a).
	set_flag(StoryGates.FIRST_CROP, true)
	EventBus.farm_changed.emit()
	return true


## Whether the crop in a cell of the plot is ready to pick.
func is_crop_ripe(cell: Vector2i) -> bool:
	return farm().is_ripe(cell, Crops.days_of(DataRegistry.get_crop(StringName(farm().crop_at(cell)))))


## How far along the crop in a cell of the plot is (a Farm phase), or "" if nothing grows there.
func crop_phase(cell: Vector2i) -> StringName:
	return farm().phase_of(cell, Crops.days_of(DataRegistry.get_crop(StringName(farm().crop_at(cell)))))


## Picks the ripe crop in a cell of the plot into the pack. Returns what it gave
## ({ "item", "count" }), or {} if nothing was picked: nothing ripe there, or no room for it.
func harvest(cell: Vector2i) -> Dictionary:
	if not is_crop_ripe(cell):
		return {}
	var crop: Dictionary = DataRegistry.get_crop(StringName(farm().crop_at(cell)))
	var given: Dictionary = Crops.gives(crop)
	var item_id: StringName = StringName(str(given["item"]))
	if not has_room_for(item_id, int(given["count"])):
		return {}
	farm().harvest(cell, Crops.days_of(crop))
	add_item(item_id, int(given["count"]))
	add_tally(CROPS_PICKED, int(given["count"]))
	practise(Skills.FARMING, Skills.HARVEST)
	EventBus.farm_changed.emit()
	return given


## Clears a withered crop out of a cell of the plot. Returns whether one was there.
func clear_crop(cell: Vector2i) -> bool:
	if not farm().clear_withered(cell):
		return false
	EventBus.farm_changed.emit()
	return true


# --- Crafting (2026-11-17) ---------------------------------------------------

## Whether he has ever held `item_id` (he may have none now).
func has_found(item_id: StringName) -> bool:
	return found.has(item_id) or item_count(item_id) > 0


## The numbers crafting runs on (data/rules/crafting.json).
func crafting_rules() -> Dictionary:
	return DataRegistry.get_rules(DataRegistry.RULES_CRAFTING)


## Whether his home has the furnishing `furnishing` (made at the workbench).
func is_furnished(furnishing: StringName) -> bool:
	return get_flag(Crafting.furnished_flag(furnishing)) == true


## The recipes of `station` (Crafting.WORKBENCH or FURNACE) that he knows, in their order.
func known_crafts(station: String) -> Array[Dictionary]:
	return Crafting.known(DataRegistry.entries(&"crafting"), station,
		func(item_id: String) -> bool: return has_found(StringName(item_id)),
		func(skill: String) -> int: return skill_level(StringName(skill)),
		func(building: String) -> bool: return is_built(StringName(building)))


## Why `recipe` (a crafting data entry) can't be made now, in Crafting's words; "" if it can.
## A building's plan (the workbench's "Build" tab) says what he is short of, by name.
func why_not_craft(recipe: Dictionary) -> String:
	var why: String = Crafting.why_not(recipe,
		func(item_id: String) -> int: return item_count(StringName(item_id)),
		func(item_id: String, count: int) -> bool: return count <= 0 or has_room_for(StringName(item_id), count),
		func(furnishing: String) -> bool: return is_furnished(StringName(furnishing)),
		func(wanted: Dictionary) -> bool: return _has_whole(wanted))
	if why == Crafting.LACKING_WORDS and Crafting.tab_of(recipe) == Crafting.TAB_BUILD:
		return Crafting.short_words(recipe, func(item_id: String) -> int: return item_count(StringName(item_id)), need_names())
	return why


## The names a need goes by on the workbench: each item's, and "Coins" for coins.
func need_names() -> Dictionary:
	var names: Dictionary = {}
	for item: Dictionary in DataRegistry.entries(&"items"):
		names[str(item["id"])] = str(item.get("name", item["id"]))
	names[String(COIN)] = "Coins"
	return names


## Whether he has what `recipe` makes as a whole thing, of which there is one of each: a
## building's kit (in the pack, or set down as a site or a building), or its upgrade.
func _has_whole(recipe: Dictionary) -> bool:
	var upgrade: StringName = StringName(Crafting.upgrade_made(recipe))
	if upgrade != &"":
		return homestead().has_upgrade(upgrade)
	var kit: Dictionary = DataRegistry.get_item(StringName(Crafting.item_made(recipe)))
	if not Buildings.is_kit(kit):
		return false
	return item_count(StringName(str(kit["id"]))) > 0 or homestead().has_building(Buildings.building_of_kit(kit))


## Makes `recipe_id` at the workbench: what it needs goes, and what it makes comes, into the
## pack or (a furnishing) into his home. A tool made from the one in his hand takes its place
## there. Returns "" if it was made, or why not in Crafting's words; then nothing changed.
func craft(recipe_id: StringName) -> String:
	var recipe: Dictionary = DataRegistry.get_crafting(recipe_id)
	if recipe.is_empty() or Crafting.station_of(recipe) != Crafting.WORKBENCH or not known_crafts(Crafting.WORKBENCH).has(recipe):
		return Crafting.UNKNOWN_WORDS
	var why_not: String = why_not_craft(recipe)
	if not why_not.is_empty():
		return why_not
	var in_hand: bool = false
	for need: Dictionary in Crafting.needs_of(recipe):
		in_hand = in_hand or equipped == StringName(str(need["item"]))
		add_item(StringName(str(need["item"])), -int(need["count"]))
	var made: StringName = StringName(Crafting.item_made(recipe))
	if made != &"":
		add_item(made, Crafting.count_made(recipe))
		if in_hand and equipped == &"" and Inventory.is_equippable(DataRegistry.get_item(made)):
			equip(made)
	elif not Crafting.upgrade_made(recipe).is_empty():
		# A building's upgrade (the Homestead): bought today, finished the next morning.
		homestead().upgrade(StringName(Crafting.upgrade_made(recipe)), day)
		EventBus.homestead_changed.emit()
	else:
		set_flag(Crafting.furnished_flag(StringName(Crafting.furnishing_made(recipe))), true)
	EventBus.crafted.emit(recipe_id)
	return ""


## The furnace in his home: what it holds, and the day it was lit. With `key`, the furnace of a
## building's room of that key (the shed's: &"shed"), each with its own load.
func furnace(key: StringName = &"") -> Furnace:
	if key != &"":
		if not _room_furnaces.has(key):
			_room_furnaces[key] = Furnace.new()
		return _room_furnaces[key]
	if _furnace == null:
		_furnace = Furnace.new()
	return _furnace


## Lights the furnace (`key`'s, or the farmhouse's) with what makes `count` of `item_id` (the
## `light_furnace` effect: the ore and the coal are taken by the conversation's own effects).
## Returns whether it was lit.
func light_furnace(item_id: StringName, count: int, key: StringName = &"") -> bool:
	var lit: bool = furnace(key).light(item_id, count, day)
	if lit:
		EventBus.sound.emit(&"furnace")
		EventBus.furnace_changed.emit()
	return lit


## Takes out what the furnace made (the `empty_furnace` effect). It is given, not just added:
## what a full pack can't take is laid at his feet. Returns what came out ({} if nothing).
func empty_furnace(key: StringName = &"") -> Dictionary:
	var out: Dictionary = furnace(key).take()
	if not out.is_empty():
		give_item(out["item"], int(out["count"]))
		EventBus.sound.emit(&"item_get")
		EventBus.furnace_changed.emit()
	return out


## The furnace's conversation as of now (Furnace.dialogue): what it holds, or what he can smelt.
func furnace_dialogue(key: StringName = &"") -> Dictionary:
	var names: Dictionary = {}
	for item: Dictionary in DataRegistry.entries(&"items"):
		names[str(item["id"])] = str(item.get("name", item["id"]))
	return furnace(key).dialogue(day, known_crafts(Crafting.FURNACE),
		func(item_id: String) -> int: return item_count(StringName(item_id)),
		int(crafting_rules().get("furnace_most", 1)), names, String(key))


## The storage chest in his home: its stacks (it is there to open once it has been made). With
## `key`, the chest of a building's room of that key (the shed's: &"shed_a", &"shed_b").
func store(key: StringName = &"") -> Store:
	if key != &"":
		if not _room_stores.has(key):
			_room_stores[key] = Store.new(int(crafting_rules().get("chest_slots", 24)))
		return _room_stores[key]
	if _store == null:
		_store = Store.new(int(crafting_rules().get("chest_slots", 24)))
	return _store


## What he carries that the chest keeps, in the pack's order: [{ "id", "count" }]. What a
## tool holds (the can's water) is in the tool, not the pack.
func storable_stacks() -> Array[Dictionary]:
	var in_tools: Array[String] = Inventory.held_in_tools(DataRegistry.entries(&"items"))
	var out: Array[Dictionary] = []
	for stack: Dictionary in inventory:
		if Store.can_hold(DataRegistry.get_item(stack["id"])) and not in_tools.has(String(stack["id"])):
			out.append({"id": String(stack["id"]), "count": int(stack["count"])})
	return out


## Puts his stack of `item_id` in the chest: as much of it as goes in. Returns "" if any of it
## moved, or why not in Store's words; then nothing changed.
func store_put(item_id: StringName, key: StringName = &"") -> String:
	var item: Dictionary = DataRegistry.get_item(item_id)
	var held: int = item_count(item_id)
	if held <= 0:
		return Store.NOTHING_WORDS
	if not Store.can_hold(item) or Inventory.held_in_tools(DataRegistry.entries(&"items")).has(String(item_id)):
		return Store.NOT_KEPT_WORDS
	var moved: int = store(key).put(String(item_id), held, Inventory.capacity(item))
	if moved <= 0:
		return Store.FULL_WORDS
	add_item(item_id, -moved)
	return ""


## Takes stack `index` out of the chest: as much of it as he has room for. Returns "" if any of
## it moved, or why not in Store's words; then nothing changed.
func store_take(index: int, key: StringName = &"") -> String:
	var stacks: Array[Dictionary] = store(key).stacks()
	if index < 0 or index >= stacks.size():
		return Store.NOTHING_WORDS
	var item_id: StringName = StringName(str(stacks[index]["id"]))
	var room: int = Inventory.room_for(item_count(item_id), DataRegistry.get_item(item_id))
	if room <= 0:
		return Store.NO_ROOM_WORDS
	add_item(item_id, store(key).take(index, mini(room, int(stacks[index]["count"]))))
	return ""


# --- The Homestead (2026-11-17) ----------------------------------------------

## The hero's homestead: what he has done to his land (what he has cleared for good, and what
## he has set down).
func homestead() -> Homestead:
	if _homestead == null:
		_homestead = Homestead.new()
	return _homestead


## The homestead's rules (data/rules/homestead.json): which map is his land, and its rocks.
func homestead_rules() -> HomesteadRules:
	if _homestead_rules == null:
		_homestead_rules = HomesteadRules.new(DataRegistry.get_rules(DataRegistry.RULES_HOMESTEAD))
	return _homestead_rules


## Whether what stood at `cell` of `area` has been cleared for good. Only his land keeps such
## a thing: anywhere else nothing is ever cleared for good.
func is_debris_cleared(area: StringName, cell: Vector2i) -> bool:
	return homestead_rules().is_land(area) and homestead().is_cleared(cell)


## What stood at `cell` of `area` (weeds, a bush, a log, a stump, a rock, a boulder) is
## cleared, for good: no morning brings it back. Returns whether that is news; it never is
## off his land, or for a cell cleared already.
func clear_debris(area: StringName, cell: Vector2i) -> bool:
	if not homestead_rules().is_land(area) or not homestead().clear(cell):
		return false
	EventBus.homestead_changed.emit()
	return true


## Sets one `item_id` (a placeable he carries) down in `cell` of `area`: it leaves the pack
## and lies or stands there, as its data says (Placement). Whether it fits the ground is the
## area's to ask first (Placement.why_not: build mode does); here it is refused only off his
## land, for what he hasn't got or can't be set down, and where a thing of its layer is
## already. Returns whether it was set down.
func set_down(area: StringName, cell: Vector2i, item_id: StringName) -> bool:
	var layer: StringName = Placement.layer_of(DataRegistry.get_item(item_id))
	if not homestead_rules().is_land(area) or layer == &"" or item_count(item_id) <= 0:
		return false
	if not homestead().set_down(cell, layer, item_id):
		return false
	add_item(item_id, -1)
	EventBus.homestead_changed.emit()
	return true


## Why what is on `layer` (Placement.LYING or STANDING) in `cell` of `area` can't be taken up,
## in Placement's words: nothing is there, or the pack has no room for it. "" if it can.
func why_not_take_up(area: StringName, cell: Vector2i, layer: StringName) -> String:
	var item_id: StringName = homestead().thing_at(cell, layer) if homestead_rules().is_land(area) else &""
	if item_id == &"":
		return Placement.NOTHING_WORDS
	if not has_room_for(item_id):
		return Placement.NO_ROOM_WORDS % str(DataRegistry.get_item(item_id).get("name", item_id))
	return ""


## Takes up what is on `layer` in `cell` of `area` and puts its item back in the pack (a grown
## tree gives back its sapling: it is the sapling's item that stands there). A full pack
## refuses, and the thing stays where it is. Returns the item taken up, or &"" if none was.
func take_up(area: StringName, cell: Vector2i, layer: StringName) -> StringName:
	if not why_not_take_up(area, cell, layer).is_empty():
		return &""
	var item_id: StringName = homestead().take_up(cell, layer)
	add_item(item_id, 1)
	EventBus.homestead_changed.emit()
	return item_id


## Moves what is on `layer` in cell `from` of `area` to cell `to`, as it is (the hand of build
## mode: a sapling keeps its mornings, and a grown tree stays a tree). Nothing goes through
## the pack, so a full one is no hindrance. Whether it fits the ground at `to` is the area's to
## ask first (Placement.why_not). Returns whether it moved: never off his land, with nothing
## to move, or onto a thing of its layer.
func move_placed(area: StringName, from: Vector2i, to: Vector2i, layer: StringName) -> bool:
	if not homestead_rules().is_land(area) or not homestead().move(from, to, layer):
		return false
	EventBus.homestead_changed.emit()
	return true


## What grows on his land, for a morning (Homestead.grow): item id -> the mornings it takes.
func growing_things() -> Dictionary:
	return Placement.growing(DataRegistry.entries(&"items"))


# --- The Homestead's buildings (phase 3) -------------------------------------

## The silo's words: what was put in, or why nothing was.
const HAY_IN_WORDS: String = "You put %d hay in the silo. It holds %d of %d."
const SILO_FULL_WORDS: String = "The silo is full: it holds %d hay."
const NO_HAY_WORDS: String = "You carry no hay. The silo holds %d of %d."


## Whether building `id` (data/buildings) stands on his land today: its site was set down on
## an earlier day. A site is not built yet.
func is_built(id: StringName) -> bool:
	return homestead().is_standing(id, day)


## Whether building `id` stands today as its bigger self (its upgrade was bought on an earlier
## day).
func is_big(id: StringName) -> bool:
	return homestead().is_big(id, day)


## The building or site that covers `cell` of `area`, or &"" (none, or not his land).
func building_covering(area: StringName, cell: Vector2i) -> StringName:
	if not homestead_rules().is_land(area):
		return &""
	for id: StringName in homestead().building_ids():
		if Buildings.covers(DataRegistry.get_building(id), homestead().building_at(id), cell):
			return id
	return &""


## The building whose doorstep is `cell` of `area`, or &"" (none, or not his land). A site's
## doorstep is kept free too: it is where its door will be.
func doorstep_of(area: StringName, cell: Vector2i) -> StringName:
	if not homestead_rules().is_land(area):
		return &""
	for id: StringName in homestead().building_ids():
		if Buildings.doorstep_of(DataRegistry.get_building(id), homestead().building_at(id)) == cell:
			return id
	return &""


## Sets the kit `kit_id` he carries down on `area` with its building's top-left corner at
## `origin`: it leaves the pack and is a building site today, and the building stands the
## next morning (the plan's D21). Whether the ground fits is the area's to ask first
## (Buildings.why_not_at: build mode does). Refused off his land, for what is no kit or isn't
## carried, and for a building that is there already. Returns whether it was set down.
func set_down_kit(area: StringName, origin: Vector2i, kit_id: StringName) -> bool:
	var building: StringName = Buildings.building_of_kit(DataRegistry.get_item(kit_id))
	if not homestead_rules().is_land(area) or building == &"" or item_count(kit_id) <= 0:
		return false
	if not homestead().put_building(building, origin, day):
		return false
	add_item(kit_id, -1)
	EventBus.homestead_changed.emit()
	return true


## Moves building `id` (or its site) on `area` so that its top-left corner is at `origin`, as it
## is, at once and for nothing (D24): what is in it goes with it (the silo's hay, the shed's
## chests and furnace), and its door with it. Whether the ground fits is the area's to ask first
## (Buildings.why_not_at: build mode does, not counting the building itself). Returns whether it
## moved: never off his land, for none, or to where it stands already.
func move_building(area: StringName, id: StringName, origin: Vector2i) -> bool:
	if not homestead_rules().is_land(area) or not homestead().move_building(id, origin):
		return false
	EventBus.homestead_changed.emit()
	return true


## Why building `id`'s site can't be taken up on `area` (it is undone, and its kit comes back):
## it isn't a site, or the pack has no room for the kit. "" if it can.
func why_not_take_up_site(area: StringName, id: StringName) -> String:
	if not homestead_rules().is_land(area) or not homestead().is_site(id, day):
		return Placement.NOTHING_WORDS
	var kit: StringName = Buildings.kit_for(id, DataRegistry.entries(&"items"))
	if not has_room_for(kit):
		return Placement.NO_ROOM_WORDS % str(DataRegistry.get_item(kit).get("name", kit))
	return ""


## Takes up building `id`'s site on `area`: nothing was built, so its kit comes back whole.
## Returns the kit, or &"" if it was refused (why_not_take_up_site).
func take_up_site(area: StringName, id: StringName) -> StringName:
	if not why_not_take_up_site(area, id).is_empty():
		return &""
	var kit: StringName = Buildings.kit_for(id, DataRegistry.entries(&"items"))
	homestead().remove_building(id)
	add_item(kit, 1)
	EventBus.homestead_changed.emit()
	return kit


## Why a building can't be pulled down.
const NOT_STANDING_WORDS: String = "There is no building here to pull down."
const HOLDS_WORDS: String = "The %s still holds %s. Only an empty building can be pulled down."
const CHEST_FULL_WORDS: String = "There are things in the %s's chests. Only an empty building can be pulled down."
const FURNACE_FULL_WORDS: String = "The %s's furnace holds a load. Only an empty building can be pulled down."
const ANIMALS_IN_WORDS: String = "The %s still has animals in it. Only an empty building can be pulled down."


## Why building `id` can't be pulled down, in words; "" if it can. Only an empty building can go
## (D24): no animals living in it (phase 4), nothing in what it holds (the silo's hay), nothing
## in its room's chests or furnace.
func why_not_demolish(id: StringName) -> String:
	if not is_built(id):
		return NOT_STANDING_WORDS
	var building: Dictionary = DataRegistry.get_building(id)
	var called: String = Buildings.name_of(building, is_big(id))
	if not animals_in(id).is_empty():
		return ANIMALS_IN_WORDS % called
	var held: Dictionary = Buildings.holds(building)
	if not held.is_empty() and homestead().hay > 0:
		return HOLDS_WORDS % [called, str(DataRegistry.get_item(held["item"]).get("name", held["item"])).to_lower()]
	for key: StringName in Buildings.kept_in(building, true):
		if store(key).used_slots() > 0:
			return CHEST_FULL_WORDS % called
	for key: StringName in Buildings.kept_in(building, false):
		if not furnace(key).is_empty():
			return FURNACE_FULL_WORDS % called
	return ""


## What went into building `id`: the needs of its plan and, if it has its upgrade, of that.
func building_costs(id: StringName) -> Array[Dictionary]:
	var plan: Array[Dictionary] = []
	var upgrade: Array[Dictionary] = []
	var kit: String = String(Buildings.kit_for(id, DataRegistry.entries(&"items")))
	for recipe: Dictionary in DataRegistry.entries(&"crafting"):
		if Crafting.item_made(recipe) == kit and not kit.is_empty():
			plan.append_array(Crafting.needs_of(recipe))
		elif Crafting.upgrade_made(recipe) == String(id) and homestead().has_upgrade(id):
			upgrade.append_array(Crafting.needs_of(recipe))
	return plan + upgrade


## What pulling building `id` down gives back: half of each material that went into it, rounded
## down, and no coins (D24). [{ "item", "count" }]
func demolish_refund(id: StringName) -> Array[Dictionary]:
	return Buildings.refund(building_costs(id), String(COIN))


## Pulls building `id` down on `area`, if it can go (why_not_demolish): it is gone, and half of
## each material comes back, given: what the pack can't take is laid at his feet. Its room's
## furnishings stay with the room (a shed built again has them). Returns what came back, or []
## if it was refused.
func demolish(area: StringName, id: StringName) -> Array[Dictionary]:
	if not homestead_rules().is_land(area) or not why_not_demolish(id).is_empty():
		return []
	var back: Array[Dictionary] = demolish_refund(id)
	homestead().remove_building(id)
	EventBus.homestead_changed.emit()
	for thing: Dictionary in back:
		give_item(StringName(str(thing["item"])), int(thing["count"]))
	return back


## Puts the hay he carries in the building `id` that holds it (the Silo, by its data's
## "holds"), as much as it has room for: what doesn't fit stays in the pack. Returns the words
## to say ("" if `id` holds nothing, or doesn't stand yet).
func put_hay(id: StringName) -> String:
	var held: Dictionary = Buildings.holds(DataRegistry.get_building(id))
	if held.is_empty() or not is_built(id):
		return ""
	var most: int = int(held["count"])
	var carried: int = item_count(held["item"])
	if carried <= 0:
		return NO_HAY_WORDS % [homestead().hay, most]
	var added: int = homestead().add_hay(carried, most)
	if added <= 0:
		return SILO_FULL_WORDS % most
	add_item(held["item"], -added)
	EventBus.sound.emit(&"item_get")
	EventBus.homestead_changed.emit()
	return HAY_IN_WORDS % [added, homestead().hay, most]


# --- The Homestead's animals (phase 4) ----------------------------------------

## What is said when an animal is petted (its kind's name, lower case), and what it gave (the
## product's name), or that the pack had no room and the product waits.
const PETTED_WORDS: String = "You pet the %s."
const TOOK_WORDS: String = "You pet the %s. Taken: %s."
const NO_ROOM_PRODUCT_WORDS: String = "You pet the %s. Your pack has no room for the %s: it waits."


## The land as it was before he did anything to it (the woods, the trees, the pond, the house,
## the road, the field, where the overgrowth stood), read from its scene once a run.
func land_map() -> LandMap:
	if _land_map == null:
		_land_map = LandSurvey.survey(homestead_rules().area, farm().size)
	return _land_map


## What `cell` of his land is now to a grazing animal (Pasture's kinds): the land as it was,
## with what he has cleared, set down and built laid over it.
func pasture_kind(cell: Vector2i) -> StringName:
	var land: LandMap = land_map()
	if not land.in_bounds(cell) or land.is_road(cell):
		return Pasture.OPEN
	var home: Homestead = homestead()
	if land.is_solid(cell) or home.standing_at(cell) != &"" or building_covering(homestead_rules().area, cell) != &"":
		return Pasture.WALL
	if land.had_debris(cell) and not home.is_cleared(cell):
		return Pasture.WALL
	if land.is_field(cell) or home.lying_at(cell) != &"":
		return Pasture.BARE
	return Pasture.GRASS


## The ground building `id`'s animals reach from its door (Pasture.reach: "fenced", "cells",
## "grass"), or {} for a building that doesn't stand or has no door.
func pasture_of(id: StringName) -> Dictionary:
	var building: Dictionary = DataRegistry.get_building(id)
	if not is_built(id) or not Buildings.has_door(building):
		return {}
	return Pasture.reach(Buildings.doorstep_of(building, homestead().building_at(id)), land_map().size, pasture_kind)


## Whether building `id` has a pasture: fenced all round from its door, with grass in it.
func has_pasture(id: StringName) -> bool:
	return Pasture.is_pasture(pasture_of(id))


## Today's pastures, for a morning (Herd.feed): [{ "buildings": the ids of the buildings with
## animals whose door opens on it, "grass": its cells of grass }]. Two doors on one pasture
## share it.
func pastures() -> Array[Dictionary]:
	var out: Array[Dictionary] = []
	for id: StringName in homestead().building_ids():
		if animals_in(id).is_empty():
			continue
		var reached: Dictionary = pasture_of(id)
		if not Pasture.is_pasture(reached):
			continue
		var doorstep: Vector2i = Buildings.doorstep_of(DataRegistry.get_building(id), homestead().building_at(id))
		var shared: bool = false
		for pasture: Dictionary in out:
			if (pasture["cells"] as Array).has(doorstep):
				(pasture["buildings"] as Array).append(String(id))
				shared = true
				break
		if not shared:
			out.append({"buildings": [String(id)], "grass": int(reached["grass"]), "cells": reached["cells"]})
	return out


## The kinds of animal, by id (String), as Herd wants them.
func animal_kinds() -> Dictionary:
	var out: Dictionary = {}
	for kind: Dictionary in DataRegistry.entries(&"animals"):
		out[str(kind["id"])] = kind
	return out


## The places in the herd of the animals that live in building `id`, in the order they came.
func animals_in(id: StringName) -> Array[int]:
	var out: Array[int] = []
	var herd: Array[Dictionary] = homestead().animals()
	for i: int in herd.size():
		if Herd.lives_in(DataRegistry.get_animal(StringName(str(herd[i]["kind"])))) == id:
			out.append(i)
	return out


## Why an animal of kind `kind_id` can't be bought for `price` coins, in words; "" if it can:
## its building must stand with room for one more, and the purse must hold the price.
func why_not_buy_animal(kind_id: StringName, price: int) -> String:
	var kind: Dictionary = DataRegistry.get_animal(kind_id)
	if kind.is_empty():
		return Shop.NO_COINS if item_count(COIN) < price else ""
	var home: StringName = Herd.lives_in(kind)
	return Herd.why_not_buy(kind, DataRegistry.get_building(home), is_built(home), is_big(home), animals_in(home).size(), item_count(COIN), price)


## Buys an animal of kind `kind_id` for `price` coins: the coins go, and it is in its building at
## once (Farmer Oda's stall; D29). Returns "" if it was bought, or why not.
func buy_animal(kind_id: StringName, price: int) -> String:
	var why: String = why_not_buy_animal(kind_id, price)
	if not why.is_empty() or DataRegistry.get_animal(kind_id).is_empty():
		return why if not why.is_empty() else Shop.NO_COINS
	add_item(COIN, -price)
	homestead().add_animal(kind_id)
	EventBus.homestead_changed.emit()
	return ""


## Pets the animal at `index` in the herd (D26): it is petted today, it says so, and what it has
## ready is taken, if the pack has room (else it waits). A product taken is a deed of Farming
## (`tend`). Returns the words to say ("" for no animal).
func pet_animal(index: int) -> String:
	var animal: Dictionary = homestead().animal(index)
	if animal.is_empty():
		return ""
	var kind: Dictionary = DataRegistry.get_animal(StringName(str(animal["kind"])))
	var called: String = Herd.name_of(kind).to_lower()
	animal["petted"] = true
	EventBus.sound.emit(Herd.sound_of(kind))
	EventBus.animal_petted.emit(index)
	if not bool(animal["ready"]):
		return PETTED_WORDS % called
	var product: StringName = Herd.gives(kind)
	var product_name: String = str(DataRegistry.get_item(product).get("name", product))
	if not has_room_for(product):
		return NO_ROOM_PRODUCT_WORDS % [called, product_name]
	add_item(product, 1)
	animal["ready"] = false
	practise(Skills.FARMING, &"tend")
	return TOOK_WORDS % [called, product_name]


## A morning comes to the herd (D25, D27): each animal in turn is fed from its building's pasture
## while the grass holds out, then by a hay from the silo, else goes hungry; each fed one comes
## nearer its next product. Nothing happens with no animals.
func _herd_morning() -> void:
	var herd: Array[Dictionary] = homestead().animals()
	if herd.is_empty():
		return
	var kinds: Dictionary = animal_kinds()
	var fed: Dictionary = Herd.feed(herd, kinds, pastures(), homestead().hay)
	homestead().hay = int(fed["hay"])
	for i: int in herd.size():
		Herd.morning(herd[i], kinds.get(str(herd[i]["kind"]), {}), bool(fed["fed"][i]))


# --- The mine (2026-11-17) ---------------------------------------------------

## The Old Quarry's rules (data/rules/mine.json).
func mine_rules() -> MineRules:
	if _mine_rules == null:
		_mine_rules = MineRules.new(DataRegistry.get_rules(DataRegistry.RULES_MINE))
	return _mine_rules


## What the mine remembers, as of today: a rock broken on another day is whole again.
func mine() -> MineState:
	if _mine == null:
		_mine = MineState.new()
	_mine.start_day(day)
	return _mine


## Whether the rock at `cell` of `area` has been broken today.
func is_rock_broken(area: StringName, cell: Vector2i) -> bool:
	return mine().is_broken(area, cell, day)


## The rock at `cell` of `area` is broken: it stays so until tomorrow.
func break_rock(area: StringName, cell: Vector2i) -> void:
	mine().mark_broken(area, cell, day)


## Today's rocks for `area`, whose rocks stand at `cells`: which hold ore, and which hides the
## ladder down (MineRolls.roll's answer). Anywhere that isn't a floor of the mine (its hall)
## has plain rocks and no ladder.
func mine_roll(area: StringName, cells: Array[Vector2i]) -> Dictionary:
	var rules: MineRules = mine_rules()
	var floor: int = rules.floor_of(area)
	var has_ladder: bool = floor != MineRules.NO_FLOOR and not rules.is_last(floor)
	return MineRolls.roll(mine().number, day, floor, cells, rules.ores_of(floor), has_ladder)


## The next day begins, at the hour days start. The plot wakes to its morning: what was
## watered grows, what wasn't goes a day drier.
func start_next_day() -> void:
	day += 1
	minute = float(day_clock().starts)
	farm().new_day(Crops.days_by_id(DataRegistry.entries(&"crops")))
	EventBus.farm_changed.emit()
	# A sapling on his land is a morning older (the Homestead): no water needed. A site set
	# down yesterday stands this morning, and an upgrade bought yesterday is finished.
	var grew: bool = homestead().grow(growing_things())
	# The herd is fed (pasture, then hay) and comes nearer its eggs, fleeces and pails.
	_herd_morning()
	var finished: Array[Dictionary] = homestead().finished_on(day)
	for done: Dictionary in finished:
		var building: Dictionary = DataRegistry.get_building(done["id"])
		morning_news.append((Buildings.BIGGER_WORDS if done["big"] else Buildings.STANDS_WORDS) % Buildings.name_of(building, done["big"]))
		EventBus.building_finished.emit(done["id"], done["big"])
	if grew or not finished.is_empty() or homestead().animal_count() > 0:
		EventBus.homestead_changed.emit()
	EventBus.day_started.emit(day)
	EventBus.time_changed.emit(day, floori(minute))


## The hero sleeps in his bed (GDD §6): the next day begins, and he wakes with full hearts and
## full energy. Whoever runs the area saves the game.
func sleep() -> void:
	start_next_day()
	set_energy(max_energy())
	set_health(max_health())
	EventBus.slept.emit(day)


## "Day 3  14:20" for the HUD: the clock moves in steps of ten minutes.
func time_text() -> String:
	return "Day %d  %s" % [day, DayClock.shown(minute)]


## The colour of the light outdoors now.
func daylight() -> Color:
	return day_clock().light_at(minute)


func set_health(value: int) -> void:
	var clamped: int = clampi(value, 0, max_health())
	if clamped == health:
		return
	health = clamped
	EventBus.health_changed.emit(health, max_health())


func is_dead() -> bool:
	return is_started() and health <= 0


# --- Flags -----------------------------------------------------------------

func set_flag(flag: StringName, value: Variant) -> void:
	if flags.has(flag) and flags[flag] == value:
		return
	flags[flag] = value
	# The day a flag came true is kept: the crypt's bars wait for the dawn after the Warden falls.
	if typeof(value) == TYPE_BOOL and value:
		flag_days[flag] = day
	else:
		flag_days.erase(flag)
	EventBus.flag_set.emit(flag, value)


func get_flag(flag: StringName, default: Variant = false) -> Variant:
	return flags.get(flag, default)


## Forgets `flag` altogether (what lay on the ground under it was picked up): it reads as its
## default again, and a save no longer carries it.
func erase_flag(flag: StringName) -> void:
	if not flags.has(flag):
		return
	flags.erase(flag)
	flag_days.erase(flag)
	EventBus.flag_set.emit(flag, false)


# --- Tally -----------------------------------------------------------------

## How many of `what` the game has counted (CROPS_PICKED).
func tally_of(what: StringName) -> int:
	return int(tally.get(what, 0))


## Counts `count` more of `what`.
func add_tally(what: StringName, count: int = 1) -> void:
	if count > 0:
		tally[what] = tally_of(what) + count


# --- Player ----------------------------------------------------------------

## Records which area the hero is in and where. The area calls this every frame.
func update_player(area_id: StringName, cell: Vector2i) -> void:
	player = {"area": String(area_id), "cell": [cell.x, cell.y]}


## Sends the hero to the entry point `entry` of `area_id` (a door, a doormat); the area
## places them there when it loads. The caller changes the scene.
func go_to(area_id: StringName, entry: StringName) -> void:
	player = {"area": String(area_id), "entry": String(entry)}


# --- Quests ----------------------------------------------------------------

func set_quest_stage(quest_id: StringName, stage_id: StringName) -> void:
	if quests.get(quest_id, &"") == stage_id:
		return
	quests[quest_id] = stage_id
	EventBus.quest_updated.emit(quest_id)


func get_quest_stage(quest_id: StringName) -> StringName:
	return quests.get(quest_id, &"")


# --- Inventory -------------------------------------------------------------

## Adds `count` of an item, as many as fit (Inventory.capacity, from the item's data); a
## negative count removes, never going below zero. The first item for the item button that
## comes in is equipped. Returns how many were actually added (negative when removing).
func add_item(item_id: StringName, count: int = 1) -> int:
	var item: Dictionary = DataRegistry.get_item(item_id)
	if count > 0:
		count = mini(count, Inventory.room_for(item_count(item_id), item))
	if count == 0:
		return 0
	if count > 0:
		found[item_id] = true
	# His first thing for the item button goes on it. Later ones wait in the bar: with the sword
	# in hand by choice, a thing picked up doesn't take its place.
	if count > 0 and equipped == &"" and Inventory.is_equippable(item) \
			and Inventory.equippable_held(inventory, DataRegistry.entries(&"items")).is_empty():
		equip(item_id)
	var index: int = _find_stack(item_id)
	if index == -1:
		if count < 0:
			return 0
		inventory.append({"id": item_id, "count": count})
		EventBus.item_added.emit(item_id, count)
		return count
	var held: int = inventory[index]["count"]
	var applied: int = maxi(count, -held)
	if held + applied == 0:
		inventory.remove_at(index)
		# The last of what was on the item button (a bomb, a seed): the button is empty, and the
		# sword is in hand again. It never holds what he no longer has.
		if equipped == item_id:
			equip(&"")
	else:
		inventory[index]["count"] = held + applied
	EventBus.item_added.emit(item_id, applied)
	return applied


## Buys one of a shop's wares (Shop.wares: { "item", "count", "price" }): the coins go and the
## ware comes. Returns "" if it was bought, or why not in Shop's words; then nothing changed.
func buy(ware: Dictionary) -> String:
	if Shop.is_animal(ware):
		return buy_animal(StringName(str(ware["animal"])), int(ware.get("price", 0)))
	var item_id: StringName = StringName(str(ware.get("item", "")))
	var why_not: String = Shop.why_not_buy(ware, item_count(COIN), item_count(item_id), DataRegistry.get_item(item_id))
	if why_not.is_empty():
		add_item(COIN, -int(ware.get("price", 0)))
		add_item(item_id, int(ware.get("count", 1)))
	return why_not


## Sells one of what a shop buys (Shop.offers: { "item", "price" }): it goes and the coins
## come. Returns "" if it was sold, or why not in Shop's words; then nothing changed.
func sell(offer: Dictionary) -> String:
	var item_id: StringName = StringName(str(offer.get("item", "")))
	var why_not: String = Shop.why_not_sell({"count": item_count(item_id), "price": offer.get("price", 0)},
		item_count(COIN), Inventory.capacity(DataRegistry.get_item(COIN)))
	if why_not.is_empty():
		add_item(item_id, -1)
		add_item(COIN, int(offer.get("price", 0)))
	return why_not


## A conversation asks to be taken somewhere (the `travel` effect: the mine's lift): whoever
## runs the area goes there.
func request_travel(area_id: StringName, entry: StringName) -> void:
	EventBus.travel_requested.emit(area_id, entry)


## A conversation asks for a shop's list (the `shop` effect): whoever runs the area opens it.
func request_shop(shop_id: StringName, mode: StringName) -> void:
	EventBus.shop_requested.emit(shop_id, mode)


## Puts `item_id` on the item button (empty to clear it).
func equip(item_id: StringName) -> void:
	if equipped == item_id:
		return
	equipped = item_id
	EventBus.equipped_changed.emit(item_id)


# --- In hand ---------------------------------------------------------------

## What can be in the hero's hand, in the order of the bar at the bottom of the screen
## (HandBar): his best sword, then what he holds for the item button.
func hand_entries() -> Array[Dictionary]:
	return HandBar.entries(inventory, DataRegistry.entries(&"items"))


## Which of hand_entries() is in hand: the sword with nothing on the item button, else what
## is on it. HandBar.NONE if he has neither.
func hand_index() -> int:
	return HandBar.index_of(hand_entries(), equipped)


## Puts entry `index` of hand_entries() in hand (a number key of the bar). Returns whether
## that changed what is in hand: false for no such entry, or the one in hand already.
func take_in_hand(index: int) -> bool:
	var held: Array[Dictionary] = hand_entries()
	if index < 0 or index >= held.size() or index == HandBar.index_of(held, equipped):
		return false
	equip(HandBar.equipped_for(held, index))
	return true


## Puts the thing `step` slots on in hand, round and round (the mouse wheel). Returns whether
## that changed what is in hand.
func step_hand(step: int) -> bool:
	return take_in_hand(HandBar.stepped(hand_entries(), equipped, step))


## Whether `item_id` uses something up and there is none left: a bow with no arrows, the last
## bomb or seed gone, an empty watering can. False for what uses nothing up.
func is_out_of_ammo(item_id: StringName) -> bool:
	var ammo: String = Inventory.ammo_for(DataRegistry.get_item(item_id))
	return not ammo.is_empty() and item_count(StringName(ammo)) <= 0


func item_count(item_id: StringName) -> int:
	var index: int = _find_stack(item_id)
	return 0 if index == -1 else int(inventory[index]["count"])


## Whether the pack has room for `count` more of `item_id`: all of them. What doesn't fit whole
## is left where it lies (a pickup, a chest, a crop) so nothing is lost to a full pack.
func has_room_for(item_id: StringName, count: int = 1) -> bool:
	return Inventory.fits(item_count(item_id), DataRegistry.get_item(item_id), count)


## Hands the hero `count` of an item (the `give_item` effect: a quest's reward, a present, a
## thing given in a conversation). What fits goes in the pack. The rest is not lost: it is owed
## (LeftItems, in the flags), and whoever runs the area lays it at his feet when told
## (EventBus.items_owed), or as the next area loads. Returns how many went in the pack.
func give_item(item_id: StringName, count: int = 1) -> int:
	var taken: int = add_item(item_id, count)
	if count > taken and count > 0:
		var flag: StringName = LeftItems.owed_flag(item_id)
		set_flag(flag, LeftItems.count_of(get_flag(flag, 0)) + count - taken)
		EventBus.items_owed.emit()
	return taken


## Lays everything owed in `cell` of `area` (where the hero stands): it lies there until it is
## picked up (LeftItems; a LeftItem in the area). Returns what was laid down: [{ "item",
## "count" }].
func lay_down_owed(area: StringName, cell: Vector2i) -> Array[Dictionary]:
	var laid: Array[Dictionary] = []
	for due: Dictionary in LeftItems.owed(flags):
		var lying: StringName = LeftItems.lying_flag(area, cell, due["item"])
		set_flag(lying, LeftItems.count_of(get_flag(lying, 0)) + int(due["count"]))
		erase_flag(due["flag"])
		laid.append({"item": due["item"], "count": int(due["count"])})
	return laid


func _find_stack(item_id: StringName) -> int:
	for i: int in inventory.size():
		if inventory[i]["id"] == item_id:
			return i
	return -1


# --- Serialization ---------------------------------------------------------

## Empties all state. Does not emit signals: callers reload whatever reads it.
func clear() -> void:
	hearts_max = 0
	health = 0
	heart_pieces = 0
	play_time = 0.0
	day = 1
	minute = float(day_clock().starts)
	energy = 0.0
	arrival_notice = ""
	_farm = null
	_mine = null
	_furnace = null
	_store = null
	_room_furnaces.clear()
	_room_stores.clear()
	_homestead = null
	morning_news.clear()
	found.clear()
	flags.clear()
	flag_days.clear()
	skill_points.clear()
	friends.clear()
	tally.clear()
	quests.clear()
	inventory.clear()
	equipped = &""
	player.clear()


## The whole state as JSON-safe data (String keys, no StringNames).
func to_dict() -> Dictionary:
	var stacks: Array = []
	for stack: Dictionary in inventory:
		stacks.append({"id": String(stack["id"]), "count": int(stack["count"])})
	return {
		"version": SAVE_VERSION,
		"hearts_max": hearts_max,
		"health": health,
		"heart_pieces": heart_pieces,
		"play_time": snappedf(play_time, 0.01),
		"day": day,
		"minute": snappedf(minute, 0.01),
		"energy": snappedf(energy, 0.01),
		"flags": _json_safe(flags),
		"flag_days": _json_safe(flag_days),
		"quests": _json_safe(quests),
		"inventory": stacks,
		"equipped": String(equipped),
		"player": _json_safe(player),
		"farm": farm().to_dict(),
		"mine": mine().to_dict(),
		"home": {"furnace": furnace().to_dict(), "chest": store().to_list()},
		"homestead": _homestead_saved(),
		"found": _found_list(),
		"skills": _json_safe(skill_points),
		"friends": _json_safe(friends),
		"tally": _json_safe(tally),
	}


## Replaces all state with `data`, which must already be at SAVE_VERSION.
## Does not emit signals: the caller reloads the world after loading.
func from_dict(data: Dictionary) -> void:
	clear()
	hearts_max = clampi(int(data.get("hearts_max", 0)), 0, MAX_HEARTS)
	health = clampi(int(data.get("health", 0)), 0, max_health())
	heart_pieces = clampi(int(data.get("heart_pieces", 0)), 0, PIECES_PER_HEART - 1)
	play_time = maxf(float(data.get("play_time", 0.0)), 0.0)
	day = maxi(int(data.get("day", 1)), 1)
	minute = clampf(float(data.get("minute", day_clock().starts)), float(day_clock().starts), float(day_clock().ends))
	energy = clampf(float(data.get("energy", max_energy())), 0.0, max_energy())
	var src_flags: Dictionary = data.get("flags", {})
	for key: Variant in src_flags:
		flags[StringName(str(key))] = src_flags[key]
	var src_days: Dictionary = _dictionary(data.get("flag_days"))
	for key: Variant in src_days:
		flag_days[StringName(str(key))] = maxi(int(src_days[key]), 1)
	var src_skills: Dictionary = _dictionary(data.get("skills"))
	for key: Variant in src_skills:
		skill_points[StringName(str(key))] = maxi(int(src_skills[key]), 0)
	var src_friends: Dictionary = _dictionary(data.get("friends"))
	for key: Variant in src_friends:
		var friend: Dictionary = _dictionary(src_friends[key])
		friends[StringName(str(key))] = {
			"points": maxi(int(friend.get("points", 0)), 0),
			"talked": maxi(int(friend.get("talked", 0)), 0),
			"gift": maxi(int(friend.get("gift", 0)), 0),
		}
	var src_tally: Dictionary = _dictionary(data.get("tally"))
	for key: Variant in src_tally:
		tally[StringName(str(key))] = maxi(int(src_tally[key]), 0)
	var src_quests: Dictionary = data.get("quests", {})
	for key: Variant in src_quests:
		quests[StringName(str(key))] = StringName(str(src_quests[key]))
	var src_inventory: Array = data.get("inventory", [])
	for stack: Variant in src_inventory:
		var entry: Dictionary = stack
		inventory.append({"id": StringName(str(entry["id"])), "count": int(entry["count"])})
	equipped = StringName(str(data.get("equipped", "")))
	# A save from before the bar could keep bombs on the button with none left.
	if equipped != &"" and item_count(equipped) <= 0:
		equipped = &""
	player = _whole_numbers_as_int(data.get("player", {}))
	farm().load_saved(data.get("farm", {}), DataRegistry.ids(&"crops"))
	_mine = MineState.new()
	_mine.load_saved(data.get("mine"))
	var home: Dictionary = _dictionary(data.get("home"))
	_furnace = Furnace.new()
	_furnace.load_saved(home.get("furnace"))
	_store = null
	store().load_saved(home.get("chest"), func(item_id: String) -> int: return Inventory.capacity(DataRegistry.get_item(StringName(item_id))))
	homestead().load_saved(data.get("homestead"), func(item_id: String) -> StringName: return Placement.layer_of(DataRegistry.get_item(StringName(item_id))),
		func(building: String) -> bool: return DataRegistry.has_entry(&"buildings", StringName(building)),
		func(kind: String) -> bool: return DataRegistry.has_entry(&"animals", StringName(kind)))
	_load_rooms(_dictionary(data.get("homestead")))
	var src_found: Variant = data.get("found")
	if typeof(src_found) == TYPE_ARRAY:
		for id: Variant in src_found:
			if typeof(id) == TYPE_STRING and not str(id).is_empty():
				found[StringName(str(id))] = true
	# What he carries, he has found: a save from before this was kept says nothing of it.
	for stack: Dictionary in inventory:
		found[stack["id"]] = true


## The save's section `homestead`: what Homestead keeps, and (the Homestead, phase 3) the
## furnaces and chests of buildings' rooms, by key: "furnaces": { "shed": {...} }, "chests": {
## "shed_a": [...] }, each written only when one holds something.
func _homestead_saved() -> Dictionary:
	var out: Dictionary = homestead().to_dict()
	var furnaces: Dictionary = {}
	for key: StringName in _room_furnaces:
		if not _room_furnaces[key].is_empty():
			furnaces[String(key)] = _room_furnaces[key].to_dict()
	if not furnaces.is_empty():
		out["furnaces"] = furnaces
	var chests: Dictionary = {}
	for key: StringName in _room_stores:
		if _room_stores[key].used_slots() > 0:
			chests[String(key)] = _room_stores[key].to_list()
	if not chests.is_empty():
		out["chests"] = chests
	return out


## Takes up the rooms' furnaces and chests from a saved `homestead` section (none in a save
## from before them).
func _load_rooms(saved: Dictionary) -> void:
	var furnaces: Dictionary = _dictionary(saved.get("furnaces"))
	for key: Variant in furnaces:
		furnace(StringName(str(key))).load_saved(furnaces[key])
	var chests: Dictionary = _dictionary(saved.get("chests"))
	for key: Variant in chests:
		store(StringName(str(key))).load_saved(chests[key], func(item_id: String) -> int: return Inventory.capacity(DataRegistry.get_item(StringName(item_id))))


## The ids of what he has found, in order, for a save.
func _found_list() -> Array:
	var out: Array = []
	for id: StringName in found:
		out.append(String(id))
	out.sort()
	return out


## `value` if it is a Dictionary, else an empty one (a section missing from a save).
static func _dictionary(value: Variant) -> Dictionary:
	return value if typeof(value) == TYPE_DICTIONARY else {}


## JSON may return 12 as 12.0. Cells and counts are ints, so turn whole floats back into
## ints, recursively, leaving real fractions alone.
func _whole_numbers_as_int(value: Variant) -> Variant:
	match typeof(value):
		TYPE_FLOAT:
			var number: float = value
			return int(number) if number == roundf(number) else number
		TYPE_DICTIONARY:
			var source: Dictionary = value
			var out: Dictionary = {}
			for key: Variant in source:
				out[key] = _whole_numbers_as_int(source[key])
			return out
		TYPE_ARRAY:
			var out_array: Array = []
			for element: Variant in (value as Array):
				out_array.append(_whole_numbers_as_int(element))
			return out_array
	return value


## Recursively turns StringName keys and values into String so JSON keeps them stable.
func _json_safe(value: Variant) -> Variant:
	match typeof(value):
		TYPE_STRING_NAME:
			return String(value)
		TYPE_DICTIONARY:
			var source: Dictionary = value
			var out: Dictionary = {}
			for key: Variant in source:
				var safe_key: Variant = String(key) if typeof(key) == TYPE_STRING_NAME else key
				out[safe_key] = _json_safe(source[key])
			return out
		TYPE_ARRAY:
			var out_array: Array = []
			for element: Variant in (value as Array):
				out_array.append(_json_safe(element))
			return out_array
	return value
