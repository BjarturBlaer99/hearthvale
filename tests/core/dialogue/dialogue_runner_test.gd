extends GdUnitTestSuite
## DialogueRunner: plays a conversation from data. Options are hidden by unmet conditions,
## choosing one applies its effects and moves on, null ends it, and nodes without options
## end on advance. EffectApplier applies each effect type to the game state.

const FakeState: GDScript = preload("res://tests/support/fake_state.gd")

const TALK: Dictionary = {
	"id": "talk",
	"start": "greet",
	"speakers": {"bram": "Elder Bram"},
	"nodes": {
		"greet": {
			"speaker": "bram",
			"text": "Hello.",
			"options": [
				{"text": "Promise.", "conditions": [{"type": "flag", "flag": "promised", "value": false}],
					"effects": [{"type": "set_flag", "flag": "promised", "value": true}], "next": "thanks"},
				{"text": "Kept it.", "conditions": [{"type": "flag", "flag": "promised", "value": true}], "next": null},
				{"text": "Bye.", "next": null},
			],
		},
		"thanks": {
			"speaker": "wenna",
			"text": "Thank you.",
			"on_enter": [{"type": "give_item", "item": "coin", "count": 5}],
			"options": [],
		},
	},
}

var _state: RefCounted


func before_test() -> void:
	_state = FakeState.new()


func test_starts_at_the_start_node() -> void:
	var runner: DialogueRunner = _start()
	assert_bool(runner.is_running()).is_true()
	assert_str(runner.node_id).is_equal("greet")
	assert_str(runner.speaker_name()).is_equal("Elder Bram")
	assert_str(runner.text()).is_equal("Hello.")


func test_options_with_unmet_conditions_are_hidden() -> void:
	var runner: DialogueRunner = _start()
	assert_array(Array(runner.option_texts())).is_equal(["Promise.", "Bye."])
	_state.set_flag(&"promised", true)
	assert_array(Array(runner.option_texts())).is_equal(["Kept it.", "Bye."])


func test_choosing_applies_effects_then_moves_on() -> void:
	var runner: DialogueRunner = _start()
	assert_bool(runner.choose(0)).is_true()
	assert_bool(_state.flags.get("promised", false)).is_true()
	assert_str(runner.node_id).is_equal("thanks")
	assert_str(runner.speaker_name()).override_failure_message("no name in the map: the id, capitalised").is_equal("Wenna")


func test_reaching_a_node_applies_its_on_enter_effects() -> void:
	var runner: DialogueRunner = _start()
	runner.choose(0)
	assert_int(int(_state.items.get("coin", 0))).is_equal(5)


func test_a_null_next_ends_the_conversation() -> void:
	var runner: DialogueRunner = _start()
	var ended: Array[int] = [0]
	runner.ended.connect(func() -> void: ended[0] += 1)
	assert_bool(runner.choose(1)).is_true()
	assert_bool(runner.is_running()).is_false()
	assert_int(ended[0]).is_equal(1)
	assert_array(runner.options()).is_empty()


func test_a_node_without_options_ends_on_advance() -> void:
	var runner: DialogueRunner = _start()
	assert_bool(runner.advance()).override_failure_message("greet has options to choose").is_false()
	runner.choose(0)
	assert_bool(runner.advance()).is_true()
	assert_bool(runner.is_running()).is_false()


func test_choosing_a_missing_option_changes_nothing() -> void:
	var runner: DialogueRunner = _start()
	assert_bool(runner.choose(2)).is_false()
	assert_bool(runner.choose(-1)).is_false()
	assert_str(runner.node_id).is_equal("greet")
	assert_dict(_state.flags).is_empty()


func test_a_bad_start_node_ends_at_once() -> void:
	var broken: Dictionary = TALK.duplicate(true)
	broken["start"] = "nowhere"
	var runner: DialogueRunner = DialogueRunner.new(broken, _state)
	var ended: Array[int] = [0]
	runner.ended.connect(func() -> void: ended[0] += 1)
	runner.start()
	assert_bool(runner.is_running()).is_false()
	assert_int(ended[0]).is_equal(1)


func test_speaker_names() -> void:
	assert_str(DialogueRunner.speaker_name_of(TALK, "bram")).is_equal("Elder Bram")
	assert_str(DialogueRunner.speaker_name_of(TALK, "old_tom")).is_equal("Old Tom")
	assert_str(DialogueRunner.speaker_name_of(TALK, "")).override_failure_message("a sign").is_empty()


func test_effects_change_the_state() -> void:
	var effects: EffectApplier = EffectApplier.new(_state)
	assert_bool(effects.apply({"type": "set_flag", "flag": "gate_open", "value": true})).is_true()
	assert_bool(effects.apply({"type": "give_item", "item": "coin", "count": 3})).is_true()
	assert_bool(effects.apply({"type": "take_item", "item": "coin", "count": 1})).is_true()
	assert_bool(effects.apply({"type": "set_quest_stage", "quest": "lost_key", "stage": "find_key"})).is_true()
	assert_bool(_state.flags["gate_open"]).is_true()
	assert_int(int(_state.items["coin"])).is_equal(2)
	assert_str(_state.quests["lost_key"]).is_equal("find_key")


func test_effects_that_need_a_quest_or_are_unknown_are_skipped() -> void:
	var effects: EffectApplier = EffectApplier.new(_state)
	var applied: int = effects.apply_all([
		{"type": "complete_quest"},
		{"type": "summon_dragon"},
		{"type": "set_flag", "flag": "a", "value": 1},
	])
	assert_int(applied).is_equal(1)
	assert_dict(_state.flags).is_equal({"a": 1})


func _start() -> DialogueRunner:
	var runner: DialogueRunner = DialogueRunner.new(TALK, _state)
	runner.start()
	return runner
