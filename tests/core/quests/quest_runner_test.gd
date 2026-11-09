extends GdUnitTestSuite
## QuestRunner on a game state of its own: a quest starts, applies each stage's on_enter effects
## exactly once, moves on by the first transition whose condition is met, and finishes with
## complete_quest. Nothing is kept outside the state, so a save and a load change nothing and
## never repeat a reward. The log lists started quests, active ones first.

const GameStateScript: GDScript = preload("res://autoload/game_state.gd")

## The docs' example: find the key, bring it back, get paid.
const LOST_KEY: Dictionary = {
	"id": "lost_key", "title": "The Lost Key", "start_stage": "find_key",
	"stages": {
		"find_key": {
			"journal": "The elder dropped the chapel key somewhere in the field.",
			"objectives": [{"id": "get_key", "text": "Find the chapel key", "complete_when": {"type": "has_item", "item": "small_key", "count": 1}}],
			"transitions": [{"when": {"type": "has_item", "item": "small_key", "count": 1}, "to": "return_key"}],
		},
		"return_key": {
			"journal": "Bring the key back to the elder.",
			"objectives": [{"id": "talk_elder", "text": "Return the key", "complete_when": {"type": "flag", "flag": "returned_chapel_key", "value": true}}],
			"transitions": [{"when": {"type": "flag", "flag": "returned_chapel_key", "value": true}, "to": "done"}],
		},
		"done": {
			"journal": "The elder has the chapel key again.",
			"on_enter": [
				{"type": "take_item", "item": "small_key", "count": 1},
				{"type": "give_item", "item": "coin", "count": 20},
				{"type": "complete_quest"},
			],
		},
	},
}
## Hands over a parcel on starting, and has two ways on: the better outcome is listed first.
const ERRAND: Dictionary = {
	"id": "errand", "title": "An Errand", "start_stage": "carry",
	"stages": {
		"carry": {
			"journal": "Carry the parcel.",
			"on_enter": [{"type": "give_item", "item": "bomb", "count": 1}],
			"transitions": [
				{"when": {"type": "flag", "flag": "parcel_whole", "value": true}, "to": "thanked"},
				{"when": {"type": "flag", "flag": "parcel_given", "value": true}, "to": "grumbled"},
			],
		},
		"thanked": {"journal": "Delivered whole.", "on_enter": [{"type": "give_item", "item": "coin", "count": 10}, {"type": "complete_quest"}]},
		"grumbled": {"journal": "Delivered, more or less.", "on_enter": [{"type": "complete_quest"}]},
	},
}
## Bad data: two stages that send each other back and forth.
const LOOP: Dictionary = {
	"id": "loop", "title": "Round and Round", "start_stage": "a",
	"stages": {
		"a": {"journal": "A", "transitions": [{"when": {"type": "flag", "flag": "never", "value": false}, "to": "b"}]},
		"b": {"journal": "B", "transitions": [{"when": {"type": "flag", "flag": "never", "value": false}, "to": "a"}]},
	},
}

var _state: Node
var _runner: QuestRunner
var _news: Array = []


func before_test() -> void:
	_state = auto_free(GameStateScript.new())
	_state.new_game()
	_runner = _runner_for(_state)
	_news.clear()
	_runner.stage_entered.connect(func(quest_id: StringName, stage_id: StringName, first: bool, completed: bool) -> void:
		_news.append([quest_id, stage_id, first, completed]))


func test_a_quest_starts_at_its_first_stage_once() -> void:
	assert_that(_runner.status(&"lost_key")).is_equal(QuestState.NOT_STARTED)
	assert_str(_runner.journal(&"lost_key")).is_empty()
	assert_bool(_runner.start(&"lost_key")).is_true()
	assert_that(_runner.status(&"lost_key")).is_equal(QuestState.ACTIVE)
	assert_that(_runner.stage(&"lost_key")).is_equal(&"find_key")
	assert_str(_runner.journal(&"lost_key")).contains("chapel key")
	assert_array(_runner.objectives(&"lost_key")).is_equal([{"text": "Find the chapel key", "done": false, "optional": false}])
	assert_array(_news).is_equal([[&"lost_key", &"find_key", true, false]])
	assert_bool(_runner.start(&"lost_key")).override_failure_message("already started").is_false()
	assert_bool(_runner.start(&"no_such_quest")).is_false()


func test_it_moves_on_when_a_transition_is_met_and_finishes_with_its_rewards() -> void:
	_runner.start(&"lost_key")
	assert_int(_runner.update()).override_failure_message("nothing due yet").is_equal(0)
	_state.add_item(&"small_key", 1)
	assert_int(_runner.update()).override_failure_message("moved on, and entered the next stage").is_equal(2)
	assert_that(_runner.stage(&"lost_key")).is_equal(&"return_key")
	assert_int(_state.item_count(&"small_key")).override_failure_message("not taken until it's returned").is_equal(1)
	_state.set_flag(&"returned_chapel_key", true)
	_runner.update()
	assert_that(_runner.status(&"lost_key")).is_equal(QuestState.COMPLETE)
	assert_int(_state.item_count(&"small_key")).is_equal(0)
	assert_int(_state.item_count(&"coin")).is_equal(20)
	assert_array(_news).is_equal([
		[&"lost_key", &"find_key", true, false], [&"lost_key", &"return_key", false, false], [&"lost_key", &"done", false, true],
	])


func test_rewards_are_given_exactly_once() -> void:
	_runner.start(&"lost_key")
	_state.add_item(&"small_key", 1)
	_state.set_flag(&"returned_chapel_key", true)
	_runner.update()
	assert_int(_state.item_count(&"coin")).is_equal(20)
	for i: int in 3:
		assert_int(_runner.update()).override_failure_message("finished: nothing more to do").is_equal(0)
	assert_int(_state.item_count(&"coin")).is_equal(20)


func test_an_item_found_before_asking_still_counts() -> void:
	_state.add_item(&"small_key", 1)
	_runner.start(&"lost_key")
	assert_that(_runner.stage(&"lost_key")).override_failure_message("straight on to bringing it back").is_equal(&"return_key")


func test_a_stage_set_from_outside_gets_its_on_enter_effects() -> void:
	# A dialogue's set_quest_stage effect sets the stage on the state; the runner does the rest.
	_state.set_quest_stage(&"errand", &"carry")
	assert_int(_state.item_count(&"bomb")).is_equal(0)
	_runner.update()
	assert_int(_state.item_count(&"bomb")).override_failure_message("handed the parcel on starting").is_equal(1)
	assert_array(_news).is_equal([[&"errand", &"carry", true, false]])


func test_the_first_transition_that_is_met_wins() -> void:
	_runner.start(&"errand")
	_state.set_flag(&"parcel_given", true)
	_state.set_flag(&"parcel_whole", true)
	_runner.update()
	assert_that(_runner.stage(&"errand")).is_equal(&"thanked")
	assert_int(_state.item_count(&"coin")).is_equal(10)


func test_a_save_and_a_load_change_nothing_and_never_repeat_a_reward() -> void:
	_runner.start(&"errand")
	_runner.start(&"lost_key")
	_state.add_item(&"small_key", 1)
	_runner.update()
	var saved: Variant = JSON.parse_string(JSON.stringify(_state.to_dict()))
	var loaded: Node = auto_free(GameStateScript.new())
	loaded.from_dict(saved)
	var runner: QuestRunner = _runner_for(loaded)
	assert_int(runner.update()).override_failure_message("nothing is re-applied after a load").is_equal(0)
	assert_int(loaded.item_count(&"bomb")).override_failure_message("the parcel isn't handed over twice").is_equal(1)
	assert_that(runner.stage(&"lost_key")).is_equal(&"return_key")
	assert_array(runner.started_quests()).is_equal(_runner.started_quests())
	loaded.set_flag(&"returned_chapel_key", true)
	runner.update()
	assert_that(runner.status(&"lost_key")).is_equal(QuestState.COMPLETE)
	assert_int(loaded.item_count(&"coin")).is_equal(20)


func test_the_log_lists_started_quests_active_first() -> void:
	assert_array(_runner.started_quests()).is_empty()
	_runner.start(&"lost_key")
	_runner.start(&"errand")
	_state.set_flag(&"parcel_given", true)
	_runner.update()
	var listed: Array[Dictionary] = _runner.started_quests()
	assert_array(listed.map(func(entry: Dictionary) -> String: return "%s:%s" % [entry["title"], entry["status"]])) \
		.is_equal(["The Lost Key:active", "An Errand:complete"])
	assert_str(str(listed[1]["journal"])).is_equal("Delivered, more or less.")
	assert_int(_runner.active_count()).is_equal(1)
	_state.add_item(&"small_key", 1)
	assert_array(_runner.objectives(&"lost_key")).override_failure_message("objectives tick as they're met").is_equal([{"text": "Find the chapel key", "done": true, "optional": false}])


func test_quest_data_that_goes_round_in_a_loop_is_stopped() -> void:
	_state.set_quest_stage(&"loop", &"a")
	assert_int(_runner.update()).is_equal(QuestRunner.MAX_PASSES)


func _runner_for(state: Node) -> QuestRunner:
	return QuestRunner.new({&"lost_key": LOST_KEY, &"errand": ERRAND, &"loop": LOOP}, state)
