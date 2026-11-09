extends GdUnitTestSuite
## Village life (H1): Elder Bram's conversation plays from data/dialogue/elder_bram.json, the
## answer "I'll keep watch." sets a flag, and the flag survives leaving the house (and a save)
## and changes what Bram and Wenna say. The hero stands still while talking.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const ELDER_HOUSE: String = "res://world/areas/elder_house/elder_house.tscn"
const VILLAGE: String = "res://world/areas/village/village.tscn"
const FLAG: StringName = &"promised_elder_keep"

var _area: Node


func before_test() -> void:
	GameState.clear()
	GameState.new_game()


func after_test() -> void:
	if is_instance_valid(_area):
		_area.free()
	GameState.clear()


func test_bram_talks_from_data_and_a_choice_sets_a_flag() -> void:
	_area = Steps.load_area(ELDER_HOUSE)
	var house: AreaController = _area
	var bram: Talkable = Steps.stand_before(house, "Bram")
	assert_object(house.talkable_in_front()).is_same(bram)
	assert_str(bram.prompt()).is_equal("Talk to Elder Bram")
	var nodes: Dictionary = DataRegistry.get_dialogue(&"elder_bram")["nodes"]

	assert_bool(house.interact()).is_true()
	var box: DialogueBox = house.hud.dialogue
	assert_bool(box.is_open()).is_true()
	assert_str(box.shown_name()).is_equal("Elder Bram")
	assert_str(box.shown_text()).is_equal(str(nodes["greet"]["text"]))
	assert_array(Array(box.shown_options())).is_equal(["What lights?", "Goodbye."])

	box.confirm()
	assert_str(box.shown_text()).is_equal(str(nodes["lights"]["text"]))
	assert_array(Array(box.shown_options())).is_equal(["I'll keep watch.", "Not me."])
	assert_bool(GameState.get_flag(FLAG)).is_false()
	box.confirm()
	assert_bool(GameState.get_flag(FLAG)).override_failure_message("the choice sets the flag").is_true()
	assert_str(box.shown_text()).is_equal(str(nodes["promise"]["text"]))
	box.confirm()
	assert_bool(box.is_open()).is_false()

	# Talk again: the answers have changed.
	house.interact()
	assert_array(Array(box.shown_options())).is_equal(["I'm keeping watch, as I promised.", "Goodbye."])
	box.move_cursor(1)
	box.move_cursor(1)
	assert_int(box.selected).override_failure_message("the cursor wraps").is_equal(0)
	box.move_cursor(-1)
	box.confirm()
	assert_bool(box.is_open()).override_failure_message("Goodbye. ends it").is_false()


func test_the_hero_stands_still_while_talking() -> void:
	_area = Steps.load_area(ELDER_HOUSE)
	var house: AreaController = _area
	Steps.stand_before(house, "Bram")
	house.interact()
	assert_bool(house.player.controls_enabled).is_false()
	assert_bool(house.interact()).override_failure_message("no second conversation over the first").is_false()
	assert_str(house.hud.get_node(^"Prompt").text).is_empty()
	house.hud.dialogue.move_cursor(-1)
	house.hud.dialogue.confirm()
	assert_bool(house.player.controls_enabled).is_true()


func test_the_flag_survives_leaving_the_area() -> void:
	_area = Steps.load_area(ELDER_HOUSE)
	var house: AreaController = _area
	Steps.stand_before(house, "Bram")
	house.interact()
	for i: int in 3:
		house.hud.dialogue.confirm()
	assert_bool(GameState.get_flag(FLAG)).is_true()

	# Out over the doormat, into the village.
	house.player.motor.place(Vector2i(5, 7))
	var path: String = Steps.walk_until_travel(house, Vector2.DOWN)
	assert_str(path).is_equal(VILLAGE)
	_area = Steps.load_area(path, _area)
	var village: AreaController = _area
	await get_tree().process_frame
	assert_bool(GameState.get_flag(FLAG)).override_failure_message("after leaving the house").is_true()

	# Through a save and a load.
	var saved: Variant = JSON.parse_string(JSON.stringify(GameState.to_dict()))
	GameState.clear()
	GameState.from_dict(saved)
	assert_bool(GameState.get_flag(FLAG)).override_failure_message("after a save").is_true()

	# Wenna has heard about it.
	village.player.motor.place(Vector2i(16, 15))
	path = Steps.walk_until_travel(village, Vector2.UP)
	_area = Steps.load_area(path, _area)
	var weaver: AreaController = _area
	Steps.stand_before(weaver, "Wenna")
	weaver.interact()
	assert_array(Array(weaver.hud.dialogue.shown_options())).is_equal(["Bram asked me to keep watch.", "You look troubled.", "Goodbye."])
	weaver.hud.dialogue.confirm()
	weaver.hud.dialogue.confirm()

	# And Bram remembers, back in his house.
	weaver.player.motor.place(Vector2i(5, 7))
	path = Steps.walk_until_travel(weaver, Vector2.DOWN)
	_area = Steps.load_area(path, _area)
	village = _area
	village.player.motor.place(Vector2i(30, 15))
	path = Steps.walk_until_travel(village, Vector2.UP)
	_area = Steps.load_area(path, _area)
	house = _area
	Steps.stand_before(house, "Bram")
	house.interact()
	assert_array(Array(house.hud.dialogue.shown_options())).is_equal(["I'm keeping watch, as I promised.", "Goodbye."])
