extends GdUnitTestSuite
## The story's gates, the pure parts (P4a): what the flags of a game saved before the gates
## become, a door that opens on somebody's word, and the checks on the new things data may say
## (`days_since`, `auto_start`, `openings`).

const DataRegistryScript: GDScript = preload("res://autoload/data_registry.gd")


func test_an_old_games_flags_are_put_past_the_gates() -> void:
	var old: Dictionary = {"took_hoe": true, "dungeon/keep/keys": 1}
	var past: Dictionary = StoryGates.past_the_gates(old)
	assert_dict(past).is_equal({"took_hoe": true, "dungeon/keep/keys": 1, "planted_first_crop": true, "keep_gate_open": true})
	assert_dict(old).override_failure_message("the flags it was given are left alone").is_equal({"took_hoe": true, "dungeon/keep/keys": 1})
	assert_dict(StoryGates.past_the_gates({})).is_equal({"planted_first_crop": true, "keep_gate_open": true})


func test_the_crypts_bars_are_up_only_if_the_warden_had_fallen() -> void:
	assert_bool(StoryGates.past_the_gates({"keep_warden_beaten": true}).get("crypt_open", false)).is_true()
	assert_bool(StoryGates.past_the_gates({"keep_warden_beaten": false}).has("crypt_open")).is_false()
	assert_bool(StoryGates.past_the_gates({"keep_warden_beaten": "yes"}).has("crypt_open")).override_failure_message("only a plain yes").is_false()
	assert_bool(StoryGates.past_the_gates({"crypt_shade_beaten": true}).has("crypt_open")).is_false()


func test_the_flags_have_the_names_the_data_uses() -> void:
	# Elder Bram's conversation, the main quest and two doors name these in their files.
	assert_that(StoryGates.FIRST_CROP).is_equal(&"planted_first_crop")
	assert_that(StoryGates.KEEP_GATE).is_equal(&"keep_gate_open")
	assert_that(StoryGates.WARDEN_BEATEN).is_equal(&"keep_warden_beaten")
	assert_that(StoryGates.CRYPT_OPEN).is_equal(&"crypt_open")
	var bram: String = JSON.stringify(DataRegistry.get_dialogue(&"elder_bram"))
	var quest: String = JSON.stringify(DataRegistry.get_quest(&"a_place_of_your_own"))
	for flag: StringName in [StoryGates.FIRST_CROP, StoryGates.KEEP_GATE]:
		assert_str(bram).override_failure_message("Bram's conversation names %s" % flag).contains(String(flag))
	for flag: StringName in [StoryGates.FIRST_CROP, StoryGates.KEEP_GATE, StoryGates.WARDEN_BEATEN, StoryGates.CRYPT_OPEN]:
		assert_str(quest).override_failure_message("the main quest names %s" % flag).contains(String(flag))


func test_a_chained_gate_opens_on_its_flag_and_never_by_a_key() -> void:
	assert_bool(DungeonState.KINDS.has(DungeonState.CHAINED)).is_true()
	assert_bool(DungeonState.opens_on_flags(DungeonState.CHAINED)).is_true()
	assert_bool(DungeonState.opens_on_flags(DungeonState.SHUTTER)).is_true()
	for kind: StringName in [DungeonState.OPEN, DungeonState.LOCKED, DungeonState.BOSS, DungeonState.CRACKED]:
		assert_bool(DungeonState.opens_on_flags(kind)).override_failure_message(String(kind)).is_false()
	assert_bool(DungeonState.can_unlock(DungeonState.CHAINED, 9, true)).override_failure_message("no key opens it").is_false()
	assert_int(DungeonState.key_cost(DungeonState.CHAINED)).is_equal(0)


func test_bad_story_data_is_refused_on_load() -> void:
	var registry: Node = auto_free(DataRegistryScript.new())
	var errors: String = "\n".join(registry.load_all("res://tests/fixtures/bad_story"))
	assert_str(errors).contains("quest 'odd' 'auto_start' must be true or false.")
	assert_str(errors).contains("transition 0: 'days' must be a whole number, 1 or more")
	assert_str(errors).contains("transition 1: 'days' must be a whole number, 1 or more, not 'soon'.")
	assert_str(errors).contains("transition 2: condition 'days_since' is missing 'days'.")
	assert_str(errors).contains("dialogue 'greeter' opening 0 needs 'node', one of the dialogue's nodes (got 'nowhere').")
	assert_str(errors).contains("dialogue 'greeter' opening 1 needs 'conditions'")
	assert_str(errors).contains("dialogue 'greeter' opening 2 conditions[0]: unknown condition type 'mood'.")
	assert_str(errors).contains("dialogue 'mumbler' 'openings' must be an array.")
	# The game's own data says all three new things, and loads clean.
	assert_bool(DataRegistry.get_quest(&"a_place_of_your_own").get("auto_start", false)).is_true()
	assert_str(str(DataRegistry.get_dialogue(&"elder_bram")["openings"][0]["node"])).override_failure_message("his welcome is the first of his openings").is_equal("welcome")
	assert_array(Array(DataRegistry.errors)).is_empty()
