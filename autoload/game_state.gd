extends Node
## Owns every piece of state that must survive a save (docs/TECH_DESIGN.md §2, §9).
##
## Scene nodes never hide game state: they read it here and change it through these
## methods, which emit the matching EventBus signal. `to_dict()` / `from_dict()` use the
## save format from TECH_DESIGN §9; SaveSystem handles files and version migration.

const SAVE_VERSION: int = 3
const HALVES_PER_HEART: int = 2
const START_HEARTS: int = 3
const MAX_HEARTS: int = 20
## Pieces of heart that make one heart container.
const PIECES_PER_HEART: int = 4
## The item that is money.
const COIN: StringName = &"coin"

## Heart containers the hero has (0 until a game starts).
var hearts_max: int = 0
## Health in half hearts, 0..max_health().
var health: int = 0
## Pieces of heart found toward the next heart container, 0..PIECES_PER_HEART - 1.
var heart_pieces: int = 0
## flag -> value. A missing flag reads as false.
var flags: Dictionary[StringName, Variant] = {}
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
## The hero's plot (P3): made from the farm's rules when first asked for. Saved.
var _farm: Farm
## Where the hero is: { "area", "cell": [x, y] }, or { "area", "entry" } on the way into an
## area through one of its entry points (go_to), until the area places them.
var player: Dictionary = {}


## Starts a fresh game: full health with the starting hearts, nothing else.
func new_game() -> void:
	clear()
	hearts_max = START_HEARTS
	health = max_health()
	energy = max_energy()


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
	add_item(item_id, -1)
	set_energy(energy + Food.energy_of(item))
	heal(Food.halves_of(item))
	return true


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


## Tills a cell of the plot (the plot's own cell). Returns whether it did.
func till_soil(cell: Vector2i) -> bool:
	if not farm().till(cell):
		return false
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
	if Inventory.room_for(item_count(item_id), DataRegistry.get_item(item_id)) < int(given["count"]):
		return {}
	farm().harvest(cell, Crops.days_of(crop))
	add_item(item_id, int(given["count"]))
	EventBus.farm_changed.emit()
	return given


## Clears a withered crop out of a cell of the plot. Returns whether one was there.
func clear_crop(cell: Vector2i) -> bool:
	if not farm().clear_withered(cell):
		return false
	EventBus.farm_changed.emit()
	return true


## The next day begins, at the hour days start. The plot wakes to its morning: what was
## watered grows, what wasn't goes a day drier.
func start_next_day() -> void:
	day += 1
	minute = float(day_clock().starts)
	farm().new_day(Crops.days_by_id(DataRegistry.entries(&"crops")))
	EventBus.farm_changed.emit()
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
	EventBus.flag_set.emit(flag, value)


func get_flag(flag: StringName, default: Variant = false) -> Variant:
	return flags.get(flag, default)


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
	if count > 0 and equipped == &"" and Inventory.is_equippable(item):
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
	else:
		inventory[index]["count"] = held + applied
	EventBus.item_added.emit(item_id, applied)
	return applied


## Puts `item_id` on the item button (empty to clear it).
func equip(item_id: StringName) -> void:
	if equipped == item_id:
		return
	equipped = item_id
	EventBus.equipped_changed.emit(item_id)


func item_count(item_id: StringName) -> int:
	var index: int = _find_stack(item_id)
	return 0 if index == -1 else int(inventory[index]["count"])


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
	flags.clear()
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
		"quests": _json_safe(quests),
		"inventory": stacks,
		"equipped": String(equipped),
		"player": _json_safe(player),
		"farm": farm().to_dict(),
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
	var src_quests: Dictionary = data.get("quests", {})
	for key: Variant in src_quests:
		quests[StringName(str(key))] = StringName(str(src_quests[key]))
	var src_inventory: Array = data.get("inventory", [])
	for stack: Variant in src_inventory:
		var entry: Dictionary = stack
		inventory.append({"id": StringName(str(entry["id"])), "count": int(entry["count"])})
	equipped = StringName(str(data.get("equipped", "")))
	player = _whole_numbers_as_int(data.get("player", {}))
	farm().load_saved(data.get("farm", {}), DataRegistry.ids(&"crops"))


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
