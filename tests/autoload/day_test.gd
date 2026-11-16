extends GdUnitTestSuite
## The day in GameState and in saves (P2a): the day, the time of day and the hero's energy are
## kept and saved (save version 2), and a version 1 save loads as the first morning, rested,
## with everything else as it was.

const DataRegistryScript: GDScript = preload("res://autoload/data_registry.gd")

const TEST_SLOT: int = 989
const OLD_SAVES: String = "res://tests/fixtures/saves"
const FIXTURES: String = "res://tests/fixtures"

var _times: Array = []
var _days: Array = []


func before_test() -> void:
	_times.clear()
	_days.clear()
	GameState.clear()
	EventBus.time_changed.connect(_on_time)
	EventBus.day_started.connect(_on_day)


func after_test() -> void:
	EventBus.time_changed.disconnect(_on_time)
	EventBus.day_started.disconnect(_on_day)
	GameState.clear()
	SaveSystem.current_slot = SaveSystem.GAME_SLOT
	SaveSystem.erase_slot(TEST_SLOT)


func test_a_new_game_starts_on_the_first_morning_rested() -> void:
	GameState.new_game()
	assert_int(GameState.day).is_equal(1)
	assert_float(GameState.minute).is_equal(360.0)
	assert_str(GameState.time_text()).is_equal("Day 1  06:00")
	assert_float(GameState.energy).override_failure_message("a full bar").is_equal(GameState.max_energy())
	assert_bool(GameState.is_day_over()).is_false()
	GameState.clear()
	assert_float(GameState.energy).override_failure_message("nothing until a game starts").is_equal(0.0)
	assert_float(GameState.minute).override_failure_message("but always a real time of day").is_equal(360.0)


func test_time_passes_a_minute_at_a_time_and_stops_when_the_day_is_over() -> void:
	GameState.new_game()
	var clock: DayClock = GameState.day_clock()
	var a_minute: float = clock.seconds_per_hour / 60.0
	GameState.advance_time(a_minute * 0.4)
	assert_array(_times).override_failure_message("less than a minute: nothing to say").is_empty()
	GameState.advance_time(a_minute * 0.7)
	assert_array(_times).override_failure_message("a new minute is announced once").is_equal([[1, 361]])
	for i: int in 60:
		GameState.advance_time(a_minute / 3.0)
	assert_int(_times.size()).override_failure_message("twenty more minutes, each announced once").is_equal(21)
	assert_str(GameState.time_text()).is_equal("Day 1  06:20")
	GameState.advance_time(clock.length_seconds())
	assert_bool(GameState.is_day_over()).is_true()
	assert_float(GameState.minute).is_equal(float(clock.ends))
	assert_str(GameState.time_text()).is_equal("Day 1  02:00")
	assert_that(GameState.daylight()).is_equal(clock.light_at(float(clock.ends)))
	GameState.start_next_day()
	assert_int(GameState.day).is_equal(2)
	assert_float(GameState.minute).is_equal(float(clock.starts))
	assert_array(_days).is_equal([2])
	assert_that(_times[-1]).override_failure_message("and the new day's first minute").is_equal([2, 360])
	GameState.set_time(99999.0)
	assert_float(GameState.minute).override_failure_message("the clock is kept within the day").is_equal(float(clock.ends))
	GameState.set_time(-5.0)
	assert_float(GameState.minute).is_equal(float(clock.starts))


func test_energy_is_spent_never_goes_under_nothing_and_is_announced() -> void:
	var heard: Array = []
	var note: Callable = func(current: float, maximum: float) -> void: heard.append([current, maximum])
	EventBus.energy_changed.connect(note)
	GameState.new_game()
	var full: float = GameState.max_energy()
	assert_float(full).override_failure_message("a full bar is the rules'").is_equal(GameState.energy_rules().maximum)
	GameState.spend_energy(0.5)
	GameState.spend_energy(-3.0)
	GameState.spend_energy(0.0)
	assert_array(heard).override_failure_message("said once for each change").is_equal([[full - 0.5, full]])
	assert_bool(GameState.is_exhausted()).is_false()
	GameState.spend_energy(500.0)
	assert_float(GameState.energy).is_equal(0.0)
	assert_bool(GameState.is_exhausted()).is_true()
	GameState.set_energy(full * 3.0)
	assert_float(GameState.energy).override_failure_message("never over a full bar").is_equal(full)
	EventBus.energy_changed.disconnect(note)
	GameState.clear()
	assert_bool(GameState.is_exhausted()).override_failure_message("no game, nobody to collapse").is_false()


func test_collapsing_starts_the_next_day_with_half_his_energy_and_fewer_coins() -> void:
	GameState.new_game()
	GameState.add_item(GameState.COIN, 120)
	GameState.damage(3)
	var hearts: int = GameState.health
	GameState.set_energy(0.0)
	assert_int(GameState.collapse()).override_failure_message("it says what he lost").is_equal(12)
	assert_int(GameState.day).is_equal(2)
	assert_float(GameState.minute).is_equal(float(GameState.day_clock().starts))
	assert_float(GameState.energy).is_equal(GameState.energy_rules().wake_energy())
	assert_int(GameState.item_count(GameState.COIN)).is_equal(108)
	assert_int(GameState.health).override_failure_message("hearts are untouched").is_equal(hearts)
	GameState.add_item(GameState.COIN, -108)
	assert_int(GameState.collapse()).override_failure_message("with no coins there is nothing to lose").is_equal(0)
	assert_int(GameState.day).is_equal(3)


func test_sleeping_starts_the_next_day_with_full_hearts_and_energy() -> void:
	var slept: Array = []
	var note: Callable = func(day: int) -> void: slept.append([day, GameState.day, GameState.health])
	EventBus.slept.connect(note)
	GameState.new_game()
	GameState.add_heart_container()
	GameState.damage(5)
	GameState.energy = 12.0
	GameState.set_time(float(GameState.day_clock().in_day("23:40")))
	GameState.sleep()
	EventBus.slept.disconnect(note)
	assert_int(GameState.day).is_equal(2)
	assert_float(GameState.minute).is_equal(float(GameState.day_clock().starts))
	assert_int(GameState.health).is_equal(GameState.max_health())
	assert_float(GameState.energy).is_equal(GameState.max_energy())
	assert_array(_days).override_failure_message("a new day is announced").is_equal([2])
	assert_array(slept).override_failure_message("and then that he slept, once he is rested").is_equal([[2, 2, GameState.max_health()]])


func test_a_conversation_can_put_the_hero_to_bed() -> void:
	assert_bool(DataRegistry.EFFECT_FIELDS.has("sleep")).override_failure_message("'sleep' is an effect data may use").is_true()
	assert_bool(DataRegistry.has_entry(&"dialogues", &"bed")).override_failure_message("the bed's words are data").is_true()
	GameState.new_game()
	GameState.damage(2)
	var effects: EffectApplier = EffectApplier.new(GameState)
	assert_bool(effects.apply({"type": "sleep"})).is_true()
	assert_int(GameState.day).is_equal(2)
	assert_int(GameState.health).is_equal(GameState.max_health())
	assert_bool(effects.apply({"type": "nap"})).override_failure_message("an effect nobody knows does nothing").is_false()
	assert_int(GameState.day).is_equal(2)
	# The bed's conversation: the first answer sleeps, the second doesn't.
	var runner: DialogueRunner = DialogueRunner.new(DataRegistry.get_dialogue(&"bed"), GameState)
	runner.start()
	assert_int(runner.options().size()).is_equal(2)
	runner.choose(1)
	assert_int(GameState.day).override_failure_message("\"Not yet.\"").is_equal(2)
	runner = DialogueRunner.new(DataRegistry.get_dialogue(&"bed"), GameState)
	runner.start()
	runner.choose(0)
	assert_int(GameState.day).override_failure_message("\"Sleep until morning.\"").is_equal(3)


func test_the_day_the_hour_and_the_energy_are_saved() -> void:
	GameState.new_game()
	GameState.start_next_day()
	GameState.start_next_day()
	GameState.set_time(float(GameState.day_clock().in_day("21:15")))
	GameState.energy = 41.5
	GameState.update_player(&"village", Vector2i(20, 18))
	assert_int(GameState.SAVE_VERSION).override_failure_message("version 2 brought the day; the farm made it 3 (P3a)").is_greater_equal(2)
	var before: String = JSON.stringify(GameState.to_dict(), "", true)
	assert_int(SaveSystem.save_to_slot(TEST_SLOT)).is_equal(OK)
	GameState.new_game()
	assert_int(SaveSystem.load_from_slot(TEST_SLOT)).is_equal(OK)
	assert_str(JSON.stringify(GameState.to_dict(), "", true)).is_equal(before)
	assert_int(GameState.day).is_equal(3)
	assert_str(GameState.time_text()).is_equal("Day 3  21:10")
	assert_float(GameState.energy).is_equal(41.5)
	# Whatever a file says, the state stays sound.
	var odd: Dictionary = GameState.to_dict()
	odd["day"] = -4
	odd["minute"] = 5.0
	odd["energy"] = 900.0
	GameState.from_dict(odd)
	assert_int(GameState.day).is_equal(1)
	assert_float(GameState.minute).is_equal(float(GameState.day_clock().starts))
	assert_float(GameState.energy).is_equal(GameState.max_energy())


func test_a_version_1_save_loads_as_the_first_morning_with_all_else_as_it_was() -> void:
	# A real save from the whole-game playtest, written by version 1 of the format.
	var old: Dictionary = _old_save("v1_playtest.json")
	assert_int(int(old["version"])).is_equal(1)
	assert_bool(old.has("day") or old.has("minute") or old.has("energy")).override_failure_message("version 1 knew no day").is_false()
	assert_int(_load_old("v1_playtest.json")).is_equal(OK)
	assert_int(GameState.day).is_equal(1)
	assert_float(GameState.minute).is_equal(float(GameState.day_clock().starts))
	assert_float(GameState.energy).override_failure_message("rested").is_equal(GameState.max_energy())
	assert_int(GameState.hearts_max).is_equal(int(old["hearts_max"]))
	assert_int(GameState.health).is_equal(int(old["health"]))
	assert_float(GameState.play_time).is_equal_approx(float(old["play_time"]), 0.01)
	assert_that(GameState.equipped).is_equal(StringName(str(old["equipped"])))
	# Every flag it had, and those that put an old game past the story's gates (version 4).
	assert_int(GameState.flags.size()).override_failure_message("every flag").is_equal(StoryGates.past_the_gates(old["flags"]).size())
	for flag: String in old["flags"]:
		assert_that(GameState.get_flag(StringName(flag), null)).override_failure_message(flag).is_equal(old["flags"][flag])
	assert_int(GameState.inventory.size()).is_equal((old["inventory"] as Array).size())
	for stack: Dictionary in old["inventory"]:
		assert_int(GameState.item_count(StringName(str(stack["id"])))).override_failure_message(str(stack["id"])).is_equal(int(stack["count"]))
	assert_int(GameState.quests.size()).is_equal((old["quests"] as Dictionary).size())
	assert_str(str(GameState.player["area"])).is_equal(str(old["player"]["area"]))
	assert_int(int(GameState.to_dict()["version"])).override_failure_message("saved again, it is in today's format").is_equal(GameState.SAVE_VERSION)
	assert_bool(EndingSummary.is_finished(GameState.to_dict()["flags"])).override_failure_message("this one wasn't finished").is_false()


func test_a_finished_version_1_save_is_still_finished() -> void:
	assert_int(_load_old("v1_finished.json")).is_equal(OK)
	assert_bool(GameState.get_flag(EndingSummary.FINISHED_FLAG) == true).is_true()
	assert_int(GameState.day).is_equal(1)
	assert_int(SaveSystem.save_to_slot(TEST_SLOT)).is_equal(OK)
	assert_bool(bool(SaveSystem.summary(TEST_SLOT)["finished"])).override_failure_message("and the title's window stays dark").is_true()


func test_a_save_from_a_later_version_is_refused() -> void:
	GameState.new_game()
	var newer: Dictionary = GameState.to_dict()
	newer["version"] = GameState.SAVE_VERSION + 1
	_write(TEST_SLOT, newer)
	GameState.clear()
	assert_int(SaveSystem.load_from_slot(TEST_SLOT)).is_equal(ERR_INVALID_DATA)
	assert_bool(GameState.is_started()).override_failure_message("and nothing of it is taken in").is_false()


func test_the_clocks_rules_are_data_and_bad_ones_are_reported() -> void:
	assert_bool(DataRegistry.has_entry(&"rules", DataRegistry.RULES_TIME)).override_failure_message("data/rules/time.json is loaded").is_true()
	assert_array(Array(DayClock.problems(DataRegistry.get_rules(DataRegistry.RULES_TIME)))).is_empty()
	assert_int(GameState.day_clock().starts).is_equal(DayClock.parse(str(DataRegistry.get_rules(DataRegistry.RULES_TIME)["day_starts"])))
	var registry: Node = auto_free(DataRegistryScript.new())
	var errors: String = "\n".join(registry.load_all(FIXTURES.path_join("bad_rules")))
	assert_str(errors).contains("unknown rules 'weather'")
	assert_str(errors).contains("rules 'time': 'seconds_per_hour' must be a number above 0.")
	assert_str(errors).contains("rules 'time': 'night' must have a 'from' and a 'to'")
	assert_bool(DataRegistry.has_entry(&"rules", DataRegistry.RULES_ENERGY)).override_failure_message("data/rules/energy.json is loaded").is_true()
	assert_array(Array(EnergyRules.problems(DataRegistry.get_rules(DataRegistry.RULES_ENERGY)))).is_empty()
	assert_str(errors).contains("rules 'energy': 'maximum' must be a number above 0.")
	assert_str(errors).contains("rules 'energy': 'collapse' needs 'coins_lost_most'")


func _on_time(day: int, minute: int) -> void:
	_times.append([day, minute])


func _on_day(day: int) -> void:
	_days.append(day)


func _old_save(file: String) -> Dictionary:
	return JSON.parse_string(FileAccess.get_file_as_string(OLD_SAVES.path_join(file)))


## Puts an old save in the test slot, as it would lie on disk, and loads it.
func _load_old(file: String) -> Error:
	_write(TEST_SLOT, _old_save(file))
	return SaveSystem.load_from_slot(TEST_SLOT)


func _write(slot: int, data: Dictionary) -> void:
	DirAccess.make_dir_recursive_absolute(SaveSystem.SAVE_DIR)
	var file: FileAccess = FileAccess.open(SaveSystem.slot_path(slot), FileAccess.WRITE)
	file.store_string(JSON.stringify(data, "\t"))
	file.close()
