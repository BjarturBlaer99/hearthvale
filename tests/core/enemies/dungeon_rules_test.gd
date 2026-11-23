extends GdUnitTestSuite
## DungeonRules (dungeon-difficulty-plan.md, decision 1): what each dungeon does to the
## monsters in it. The numbers are the game's own (data/rules/dungeon.json), tried on the
## game's own monsters.

const DUNGEON_RULES: String = "res://data/rules/dungeon.json"

var _data: Dictionary
var _rules: DungeonRules


func before_test() -> void:
	_data = JSON.parse_string(FileAccess.get_file_as_string(DUNGEON_RULES))
	_rules = DungeonRules.new(_data)


func test_in_the_keep_a_monster_takes_more_blows_and_hits_as_hard() -> void:
	var slime: Dictionary = DataRegistry.get_enemy(&"slime")
	var in_keep: Dictionary = _rules.strengthen(slime, &"keep")
	assert_int(in_keep["health"]).override_failure_message("two blows of the wooden sword, not one").is_equal(3)
	assert_int(in_keep["contact_damage"]).override_failure_message("still half a heart").is_equal(1)
	assert_float(in_keep["speed"]).is_equal_approx(float(slime["speed"]) * 1.1, 0.001)
	assert_float(in_keep["sight"]).is_equal_approx(float(slime["sight"]) * 1.2, 0.001)
	var archer: Dictionary = _rules.strengthen(DataRegistry.get_enemy(&"goblin_archer"), &"keep")
	assert_int(archer["health"]).override_failure_message("three blows, not two").is_equal(6)
	assert_float(archer["shot"]["cooldown"]).override_failure_message("it shoots more often").is_equal_approx(1.6 * 0.8, 0.001)
	assert_int(archer["shot"]["damage"]).is_equal(1)
	assert_int(_rules.strengthen(DataRegistry.get_enemy(&"bat"), &"keep")["health"]).override_failure_message("rounded up").is_equal(2)


func test_in_the_crypt_every_touch_and_arrow_costs_a_whole_heart() -> void:
	var slime: Dictionary = _rules.strengthen(DataRegistry.get_enemy(&"slime"), &"crypt")
	assert_int(slime["health"]).override_failure_message("two blows of the iron sword").is_equal(4)
	assert_int(slime["contact_damage"]).is_equal(2)
	var archer: Dictionary = _rules.strengthen(DataRegistry.get_enemy(&"goblin_archer"), &"crypt")
	assert_int(archer["health"]).is_equal(8)
	assert_int(archer["contact_damage"]).is_equal(2)
	assert_int(archer["shot"]["damage"]).override_failure_message("its arrows too").is_equal(2)


func test_hearts_drop_half_as_often() -> void:
	var slime: Dictionary = DataRegistry.get_enemy(&"slime")
	var in_keep: Dictionary = _rules.strengthen(slime, &"keep")
	assert_float(_heart_share(slime["drops"])).override_failure_message("in the fields, one time in five").is_equal_approx(0.2, 0.01)
	assert_float(_heart_share(in_keep["drops"])).override_failure_message("in the keep, one time in nine").is_equal_approx(1.0 / 9.0, 0.01)
	for i: int in (slime["drops"] as Array).size():
		var before: Dictionary = slime["drops"][i]
		if str(before.get("type", "")) != "heart":
			assert_dict(in_keep["drops"][i]).override_failure_message("only hearts are rarer: %s" % before).is_equal(before)


func test_a_place_it_doesnt_name_is_left_as_in_the_fields() -> void:
	for place: StringName in [&"old_wood", &"village", &"quarry_1", &""]:
		var slime: Dictionary = DataRegistry.get_enemy(&"slime")
		assert_dict(_rules.strengthen(slime, place)).override_failure_message(String(place)).is_equal(slime)
	for place: StringName in [&"keep", &"crypt", &"ruin_cellar", &"cistern", &"quarry_4", &"quarry_9"]:
		assert_bool(_rules.names(place)).override_failure_message(String(place)).is_true()


func test_bosses_and_the_bogwisp_are_left_as_they_are() -> void:
	for id: StringName in [&"iron_warden", &"crypt_shade", &"bogwisp"]:
		var enemy: Dictionary = DataRegistry.get_enemy(id)
		for place: StringName in [&"keep", &"crypt", &"quarry_8"]:
			assert_dict(_rules.strengthen(enemy, place)).override_failure_message("%s in %s" % [id, place]).is_equal(enemy)


func test_the_monsters_own_data_is_left_alone() -> void:
	var archer: Dictionary = DataRegistry.get_enemy(&"goblin_archer")
	var before: Dictionary = archer.duplicate(true)
	var in_crypt: Dictionary = _rules.strengthen(archer, &"crypt")
	in_crypt["shot"]["damage"] = 99
	in_crypt["drops"][0]["weight"] = 99
	assert_dict(archer).is_equal(before)
	assert_dict(DataRegistry.get_enemy(&"goblin_archer")).is_equal(before)


func test_a_number_left_out_is_one() -> void:
	var rules: DungeonRules = DungeonRules.new({"places": {"somewhere": {"health": 2}}})
	var slime: Dictionary = DataRegistry.get_enemy(&"slime")
	var there: Dictionary = rules.strengthen(slime, &"somewhere")
	assert_int(there["health"]).is_equal(4)
	assert_int(there["contact_damage"]).is_equal(1)
	assert_float(there["speed"]).is_equal_approx(float(slime["speed"]), 0.001)


func test_the_dungeons_rules_are_sound_and_bad_ones_are_named() -> void:
	assert_array(Array(DungeonRules.problems(_data))).is_empty()
	assert_array(Array(DungeonRules.problems(DataRegistry.get_rules(DataRegistry.RULES_DUNGEON)))).override_failure_message("the registry has them").is_empty()
	assert_array(Array(DungeonRules.problems({}))).has_size(1)
	assert_array(Array(DungeonRules.problems({"places": {}}))).has_size(1)
	assert_array(Array(DungeonRules.problems({"places": {"keep": 2}}))).has_size(1)
	assert_array(Array(DungeonRules.problems({"places": {"keep": {"health": 0}}}))).has_size(1)
	assert_array(Array(DungeonRules.problems({"places": {"keep": {"health": "lots"}}}))).has_size(1)
	assert_array(Array(DungeonRules.problems({"places": {"keep": {"armour": 2}}}))).has_size(1)


func _heart_share(drops: Array) -> float:
	var hearts: float = 0.0
	var total: float = 0.0
	for drop: Dictionary in drops:
		total += float(drop["weight"])
		if str(drop["type"]) == "heart":
			hearts += float(drop["weight"])
	return hearts / total
