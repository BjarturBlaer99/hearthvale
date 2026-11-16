extends GdUnitTestSuite
## The item bar (the user's request, 2026-11-15): a bar at the bottom of the screen with a slot
## for each thing that can be in hand. The mouse wheel steps through it and the keys 1 to 9
## choose a slot; the lit slot is what the left click uses. The Tab menu lists only food. The
## last bomb or seed leaves the sword in hand, in a new game and in an old save.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const VILLAGE: String = "res://world/areas/village/village.tscn"
const FIELD: String = "res://world/areas/south_field/south_field.tscn"
const TEST_SLOT: int = 969
const FRAME: float = 1.0 / 60.0
## Open grass in Hearthvale, away from the plot and from water.
const GRASS: Vector2i = Vector2i(23, 20)

var _area: Node
var _heard: Array[StringName] = []


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	GameState.set_time(float(GameState.day_clock().in_day("12:00")))
	SaveSystem.current_slot = TEST_SLOT
	GameState.set_flag(StoryGates.FIRST_CROP, true)
	Quests.refresh()
	_heard.clear()
	EventBus.sound.connect(_on_sound)


func after_test() -> void:
	EventBus.sound.disconnect(_on_sound)
	if is_instance_valid(_area):
		_area.free()
	_area = null
	get_tree().paused = false
	SaveSystem.erase_slot(TEST_SLOT)
	SaveSystem.current_slot = SaveSystem.GAME_SLOT
	GameState.clear()


func test_the_bar_shows_what_can_be_in_hand_with_the_one_in_hand_lit() -> void:
	for item: Array in [[&"hoe", 1], [&"wooden_sword", 1], [&"bow", 1], [&"arrow", 7], [&"bomb", 3], [&"bread", 2], [&"turnip_seeds", 5], [&"watering_can", 1]]:
		GameState.add_item(item[0], item[1])
	assert_that(GameState.equipped).override_failure_message("his first thing for the item button went on it").is_equal(&"hoe")
	var village: AreaController = _load(VILLAGE)
	village.player.motor.place(GRASS)
	village._update_hud()
	var bar: ItemBar = village.hud.item_bar
	assert_bool(bar.visible).is_true()
	assert_array(bar.shown_ids()).override_failure_message("the sword, then the rest as picked up; no food, no arrows").is_equal([&"wooden_sword", &"hoe", &"bow", &"bomb", &"turnip_seeds", &"watering_can"])
	assert_int(bar.lit_slot()).override_failure_message("the hoe is in hand").is_equal(1)
	assert_array(Array(bar.shown_counts())).override_failure_message("arrows for the bow, bombs, seeds, pours in the can").is_equal(["", "", "7", "3", "5", "0"])
	# It sits in the middle of the bottom of the screen, a slot a thing.
	var screen: Vector2 = village.get_viewport_rect().size
	assert_float(bar.size.x).is_equal(6.0 * ItemBar.SLOT + 5.0 * ItemBar.GAP)
	assert_float(bar.position.x + bar.size.x / 2.0).is_equal_approx(screen.x / 2.0, 1.0)
	assert_float(bar.position.y + bar.size.y).is_equal(screen.y - ItemBar.MARGIN)
	for slot: int in 6:
		assert_that(bar.slot_rect(slot).size).is_equal(Vector2(ItemBar.SLOT, ItemBar.SLOT))
	assert_float(bar.slot_rect(1).position.x).is_equal(float(ItemBar.SLOT + ItemBar.GAP))
	# The prompt and the message line are clear of it, one above the other.
	var prompt: Label = village.hud.get_node(^"Prompt")
	var message: Label = village.hud.get_node(^"Message")
	assert_float(prompt.position.y + prompt.size.y).override_failure_message("the prompt ends above the bar").is_less_equal(bar.position.y)
	assert_float(message.position.y + message.size.y).override_failure_message("the message ends above the prompt").is_less_equal(prompt.position.y)
	assert_int(bar.mouse_filter).override_failure_message("it takes no clicks").is_equal(Control.MOUSE_FILTER_IGNORE)
	# The keys in the corner say how.
	assert_str((village.hud.get_node(^"Hint") as Label).text).contains("Wheel or 1-9: choose what is in hand")
	assert_str((village.hud.get_node(^"Hint") as Label).text).contains("Tab: food")


func test_with_nothing_to_hold_there_is_no_bar() -> void:
	GameState.add_item(&"bread", 2)
	GameState.add_item(&"coin", 9)
	var village: AreaController = _load(VILLAGE)
	village._update_hud()
	var bar: ItemBar = village.hud.item_bar
	assert_int(bar.shown_count()).is_equal(0)
	assert_float(bar.size.x).is_equal(0.0)
	assert_int(bar.lit_slot()).is_equal(HandBar.NONE)
	assert_bool(village.step_hand(1)).override_failure_message("nothing to step to").is_false()
	assert_bool(village.choose_slot(0)).is_false()


func test_the_wheel_steps_through_the_bar_and_the_number_keys_choose_a_slot() -> void:
	for item: Array in [[&"wooden_sword", 1], [&"bow", 1], [&"arrow", 3], [&"bomb", 2]]:
		GameState.add_item(item[0], item[1])
	var village: AreaController = _load(VILLAGE)
	village.player.motor.place(GRASS)
	village._update_hud()
	var bar: ItemBar = village.hud.item_bar
	assert_array(bar.shown_ids()).is_equal([&"wooden_sword", &"bow", &"bomb"])
	assert_int(bar.lit_slot()).is_equal(1)
	_heard.clear()
	# The wheel rolled down: the next slot. Past the last, the first.
	village._unhandled_input(_wheel(MOUSE_BUTTON_WHEEL_DOWN))
	assert_that(GameState.equipped).is_equal(&"bomb")
	assert_int(bar.lit_slot()).override_failure_message("the bar shows it at once").is_equal(2)
	assert_array(_heard).contains_exactly([&"menu_move"])
	village._unhandled_input(_wheel(MOUSE_BUTTON_WHEEL_DOWN))
	assert_that(GameState.equipped).override_failure_message("the sword: nothing on the item button").is_equal(&"")
	assert_int(bar.lit_slot()).is_equal(0)
	# Rolled up: the one before. Back from the first, the last.
	village._unhandled_input(_wheel(MOUSE_BUTTON_WHEEL_UP))
	assert_that(GameState.equipped).is_equal(&"bomb")
	# A number key chooses its slot.
	_heard.clear()
	village._unhandled_input(_key(KEY_2))
	assert_that(GameState.equipped).is_equal(&"bow")
	assert_int(bar.lit_slot()).is_equal(1)
	village._unhandled_input(_key(KEY_2))
	assert_array(_heard).override_failure_message("the slot in hand already: nothing changes, nothing is heard").contains_exactly([&"menu_move"])
	village._unhandled_input(_key(KEY_9))
	assert_that(GameState.equipped).override_failure_message("no ninth slot").is_equal(&"bow")
	# The lit slot is what the left click uses.
	village._unhandled_input(_key(KEY_1))
	assert_that(GameState.equipped).is_equal(&"")
	assert_bool(village.use_hand()).is_true()
	assert_bool(village.player.motor.is_attacking()).override_failure_message("the sword in hand swings").is_true()
	_rest(village)
	village._unhandled_input(_key(KEY_3))
	assert_bool(village.use_hand()).is_true()
	assert_int(GameState.item_count(&"bomb")).override_failure_message("the bombs in hand are set down").is_equal(1)
	village._unhandled_input(_key(KEY_2))
	assert_bool(village.use_hand()).is_true()
	assert_int(GameState.item_count(&"arrow")).override_failure_message("the bow in hand shoots").is_equal(2)


func test_the_hand_stays_as_it_is_while_he_talks_and_the_bar_is_out_of_sight() -> void:
	for item: Array in [[&"wooden_sword", 1], [&"hoe", 1], [&"watering_can", 1]]:
		GameState.add_item(item[0], item[1])
	var village: AreaController = _load(VILLAGE)
	Steps.stand_before(village, "FarmerOda")
	village._update_hud()
	var bar: ItemBar = village.hud.item_bar
	assert_bool(bar.visible).is_true()
	assert_bool(village.interact()).is_true()
	village._update_hud()
	assert_bool(bar.visible).override_failure_message("out of sight under the conversation").is_false()
	village._unhandled_input(_wheel(MOUSE_BUTTON_WHEEL_DOWN))
	village._unhandled_input(_key(KEY_3))
	assert_that(GameState.equipped).override_failure_message("the hoe is still in hand").is_equal(&"hoe")
	village.hud.dialogue.open_for = 1.0
	while village.is_talking():
		village.hud.dialogue.move_cursor(village.hud.dialogue.shown_options().size() - 1 - village.hud.dialogue.selected)
		village.hud.dialogue.confirm()
	village._update_hud()
	assert_bool(bar.visible).is_true()
	# Behind the pause menu too, nothing changes hands.
	village.open_pause_menu()
	assert_bool(village.step_hand(1)).is_false()
	assert_that(GameState.equipped).is_equal(&"hoe")


func test_with_more_than_nine_things_the_bar_moves_with_the_choice() -> void:
	for item: Array in [[&"wooden_sword", 1], [&"bow", 1], [&"bomb", 2], [&"hoe", 1], [&"watering_can", 1], [&"turnip_seeds", 1],
			[&"carrot_seeds", 1], [&"wheat_seeds", 1], [&"potato_seeds", 1], [&"pumpkin_seeds", 1]]:
		GameState.add_item(item[0], item[1])
	GameState.equip(&"")
	var village: AreaController = _load(VILLAGE)
	village.player.motor.place(GRASS)
	village._update_hud()
	var bar: ItemBar = village.hud.item_bar
	assert_int(bar.entries.size()).is_equal(10)
	assert_int(bar.shown_count()).override_failure_message("nine slots show").is_equal(HandBar.SLOTS)
	assert_bool(bar.more_after()).override_failure_message("a mark where there is more").is_true()
	assert_bool(bar.more_before()).is_false()
	assert_array(bar.shown_ids()).not_contains([&"pumpkin_seeds"])
	# Back from the sword is the tenth thing: the bar moves on so it shows.
	village._unhandled_input(_wheel(MOUSE_BUTTON_WHEEL_UP))
	assert_that(GameState.equipped).is_equal(&"pumpkin_seeds")
	assert_int(bar.top).is_equal(1)
	assert_int(bar.lit_slot()).is_equal(8)
	assert_that(bar.shown_ids()[8]).is_equal(&"pumpkin_seeds")
	assert_bool(bar.more_before()).is_true()
	assert_bool(bar.more_after()).is_false()
	# The number keys are for the slots that show: 1 is now the bow.
	village._unhandled_input(_key(KEY_1))
	assert_that(GameState.equipped).is_equal(&"bow")
	assert_int(bar.top).override_failure_message("still in view: the bar stays").is_equal(1)
	# On from the last is the sword again, and the bar goes back to its start.
	village._unhandled_input(_key(KEY_9))
	village._unhandled_input(_wheel(MOUSE_BUTTON_WHEEL_DOWN))
	assert_that(GameState.equipped).is_equal(&"")
	assert_int(bar.top).is_equal(0)
	assert_int(bar.lit_slot()).is_equal(0)


func test_the_tab_menu_lists_only_food() -> void:
	for item: Array in [[&"wooden_sword", 1], [&"bow", 1], [&"arrow", 5], [&"bread", 2], [&"cherry_blossom", 3], [&"wild_berries", 3]]:
		GameState.add_item(item[0], item[1])
	GameState.set_energy(40.0)
	var village: AreaController = _load(VILLAGE)
	village.player.motor.place(GRASS)
	assert_bool(village.open_item_menu()).is_true()
	var menu: ItemMenu = village.hud.item_menu
	assert_str((menu.get_node(^"Panel/Title") as Label).text).is_equal("Food")
	assert_array(Array(menu.shown_lines())).override_failure_message("food only: the sword and the bow are on the bar").is_equal(["> Bread x2 (+30 energy)", "  Wild Berries x3 (+8 energy)"])
	assert_bool(village.hud.item_bar.visible).override_failure_message("the bar is out of sight behind the list").is_false()
	menu.confirm()
	assert_float(GameState.energy).is_equal(70.0)
	assert_that(GameState.equipped).override_failure_message("eating doesn't change what is in hand").is_equal(&"bow")
	# With nothing to eat there is no list, and he is told.
	GameState.add_item(&"bread", -1)
	GameState.add_item(&"wild_berries", -3)
	assert_bool(village.open_item_menu()).is_false()
	assert_str(village.hud.message_text()).is_equal("You carry nothing to eat.")
	assert_bool(village.player.controls_enabled).is_true()


func test_the_last_bomb_or_seed_leaves_the_sword_in_hand() -> void:
	GameState.add_item(&"wooden_sword")
	GameState.add_item(&"bomb", 1)
	assert_that(GameState.equipped).is_equal(&"bomb")
	var field: AreaController = _load(FIELD)
	field.player.motor.place(Vector2i(12, 12))
	field.player.face(Vector2.LEFT)
	field._update_hud()
	var bar: ItemBar = field.hud.item_bar
	assert_array(bar.shown_ids()).is_equal([&"wooden_sword", &"bomb"])
	assert_bool(field.use_hand()).is_true()
	assert_int(GameState.item_count(&"bomb")).is_equal(0)
	assert_that(GameState.equipped).override_failure_message("nothing is on the item button that he doesn't have").is_equal(&"")
	field._update_hud()
	assert_array(bar.shown_ids()).override_failure_message("the bombs' slot is gone").is_equal([&"wooden_sword"])
	assert_int(bar.lit_slot()).is_equal(0)
	_heard.clear()
	assert_bool(field.use_hand()).is_true()
	assert_bool(field.player.motor.is_attacking()).override_failure_message("the next click swings the sword").is_true()
	assert_array(_heard).not_contains([&"nope"])
	# Bombs again, with nothing else for the button: they are in hand, as his first were.
	GameState.add_item(&"bomb", 3)
	assert_that(GameState.equipped).is_equal(&"bomb")
	# But with the sword in hand by choice, a thing picked up waits in the bar.
	GameState.equip(&"")
	GameState.add_item(&"hoe")
	assert_that(GameState.equipped).override_failure_message("the hoe doesn't take the sword's place").is_equal(&"")
	# The last seed is the same.
	GameState.add_item(&"turnip_seeds", 1)
	GameState.equip(&"turnip_seeds")
	GameState.add_item(&"turnip_seeds", -1)
	assert_that(GameState.equipped).is_equal(&"")
	# A bow with no arrows is still his: it stays in hand, and in the bar with a nought.
	GameState.add_item(&"bow")
	GameState.equip(&"bow")
	GameState.add_item(&"arrow", 1)
	GameState.add_item(&"arrow", -1)
	assert_that(GameState.equipped).is_equal(&"bow")
	field._update_hud()
	assert_str(bar.shown_counts()[bar.lit_slot()]).is_equal("0")


func test_an_old_save_with_nothing_left_on_the_item_button_loads_with_the_sword_in_hand() -> void:
	# As the player's own save was: bombs on the item button, and the last of them used.
	GameState.add_item(&"wooden_sword")
	GameState.add_item(&"coin", 18)
	GameState.update_player(&"village", GRASS)
	var saved: Dictionary = GameState.to_dict()
	saved["equipped"] = "bomb"
	DirAccess.make_dir_recursive_absolute(SaveSystem.SAVE_DIR)
	var file: FileAccess = FileAccess.open(SaveSystem.slot_path(TEST_SLOT), FileAccess.WRITE)
	file.store_string(JSON.stringify(saved))
	file.close()
	GameState.clear()
	assert_int(SaveSystem.load_game()).is_equal(OK)
	assert_that(GameState.equipped).is_equal(&"")
	assert_int(GameState.hand_index()).override_failure_message("the sword is in hand").is_equal(0)
	var village: AreaController = _load(VILLAGE)
	village._update_hud()
	assert_bool(village.hud.shown_lines().has(AreaController.equipped_text())).override_failure_message("no \"Item: Bombs x0\" in the corner").is_false()
	assert_bool(village.use_hand()).override_failure_message("and the left click swings it").is_true()
	# What is still his stays on the button through a save.
	GameState.add_item(&"bomb", 2)
	assert_that(GameState.equipped).is_equal(&"bomb")
	assert_int(SaveSystem.save_game()).is_equal(OK)
	GameState.clear()
	assert_int(SaveSystem.load_game()).is_equal(OK)
	assert_that(GameState.equipped).is_equal(&"bomb")


func _rest(area: AreaController) -> void:
	for i: int in 40:
		area.player.motor.step(Vector2.ZERO, FRAME)


func _wheel(button: MouseButton) -> InputEventMouseButton:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = button
	event.pressed = true
	event.position = Vector2(3.0, 3.0)
	return event


func _key(code: Key) -> InputEventKey:
	var event: InputEventKey = InputEventKey.new()
	event.physical_keycode = code
	event.keycode = code
	event.pressed = true
	return event


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area


func _on_sound(id: StringName) -> void:
	_heard.append(id)
