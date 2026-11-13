extends GdUnitTestSuite
## NightRules (P2e): what the night does to a monster met out of doors. The numbers are the
## game's own (data/rules/night.json), tried on the game's own monsters.

const NIGHT_RULES: String = "res://data/rules/night.json"

var _data: Dictionary
var _rules: NightRules


func before_test() -> void:
	_data = JSON.parse_string(FileAccess.get_file_as_string(NIGHT_RULES))
	_rules = NightRules.new(_data)


func test_a_monster_at_night_has_more_health_speed_and_sight() -> void:
	var slime: Dictionary = DataRegistry.get_enemy(&"slime")
	var by_night: Dictionary = _rules.strengthen(slime)
	assert_int(int(slime["health"])).is_equal(2)
	assert_int(by_night["health"]).override_failure_message("half as much again").is_equal(3)
	assert_float(by_night["speed"]).override_failure_message("15% faster").is_equal_approx(float(slime["speed"]) * 1.15, 0.001)
	assert_float(by_night["sight"]).override_failure_message("it sees further").is_equal_approx(float(slime["sight"]) * 1.3, 0.001)
	assert_that(by_night["contact_damage"]).override_failure_message("it hits no harder").is_equal(slime["contact_damage"])
	assert_that(by_night["behaviour"]).is_equal(slime["behaviour"])
	# Health is whole, and rounded up: a bat with one becomes one with two.
	var bat: Dictionary = DataRegistry.get_enemy(&"bat")
	assert_int(_rules.strengthen(bat)["health"]).is_equal(ceili(float(bat["health"]) * 1.5))
	assert_int(NightRules.new({"health": 1.2}).strengthen({"health": 1})["health"]).override_failure_message("rounded up").is_equal(2)


func test_coins_drop_more_often_at_night() -> void:
	var slime: Dictionary = DataRegistry.get_enemy(&"slime")
	var by_night: Dictionary = _rules.strengthen(slime)
	assert_float(_coin_share(slime["drops"])).override_failure_message("by day, two times in five").is_equal_approx(0.4, 0.01)
	assert_float(_coin_share(by_night["drops"])).override_failure_message("by night, four times in seven").is_equal_approx(4.0 / 7.0, 0.01)
	for i: int in (slime["drops"] as Array).size():
		var before: Dictionary = slime["drops"][i]
		var after: Dictionary = by_night["drops"][i]
		if str(before.get("item", "")) != "coin":
			assert_dict(after).override_failure_message("only coins are likelier: %s" % before).is_equal(before)


func test_the_monsters_own_data_is_left_alone() -> void:
	var slime: Dictionary = DataRegistry.get_enemy(&"slime")
	var before: Dictionary = slime.duplicate(true)
	var by_night: Dictionary = _rules.strengthen(slime)
	by_night["drops"][0]["weight"] = 99
	assert_dict(slime).is_equal(before)
	assert_dict(DataRegistry.get_enemy(&"slime")).is_equal(before)


func test_bosses_are_left_as_they_are() -> void:
	for id: StringName in [&"iron_warden", &"crypt_shade"]:
		var boss: Dictionary = DataRegistry.get_enemy(id)
		assert_dict(_rules.strengthen(boss)).override_failure_message(String(id)).is_equal(boss)


func test_the_nights_rules_are_sound_and_bad_ones_are_named() -> void:
	assert_array(Array(NightRules.problems(_data))).is_empty()
	for key: String in NightRules.DEFAULTS:
		assert_float(float(NightRules.DEFAULTS[key])).override_failure_message("what a missing '%s' falls back to is the game's own" % key).is_equal(float(_data[key]))
	assert_float(_rules.health).is_equal(1.5)
	assert_float(_rules.speed).is_equal(1.15)
	assert_bool(_rules.sight > 1.0 and _rules.coin_drops > 1.0).is_true()
	var same: Dictionary = NightRules.new({"health": 1, "speed": 1, "sight": 1, "coin_drops": 1}).strengthen(DataRegistry.get_enemy(&"slime"))
	assert_int(same["health"]).override_failure_message("rules of 1 leave a monster as by day").is_equal(2)
	assert_array(Array(NightRules.problems({"health": 0, "speed": "fast", "sight": 1.3}))).contains_exactly([
		"'health' must be a number above 0 (1 leaves things as by day).",
		"'speed' must be a number above 0 (1 leaves things as by day).",
		"'coin_drops' must be a number above 0 (1 leaves things as by day).",
	])


## How often `drops` gives a coin, over an even spread of rolls.
func _coin_share(drops: Array) -> float:
	var coins: int = 0
	for i: int in 700:
		if str(DropTable.roll(drops, (i + 0.5) / 700.0).get("item", "")) == "coin":
			coins += 1
	return coins / 700.0
