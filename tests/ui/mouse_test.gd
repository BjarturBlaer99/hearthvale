extends GdUnitTestSuite
## The mouse (the user's requests, 2026-11-13), as in farming games: the hero is moved with the
## keys; the left button uses what he has in hand (his sword, or the tool or item on the item
## button), and the right button interacts with people and things. The buttons are buttons,
## not a pointer: nothing on any screen takes a click for itself, so a click anywhere reaches
## the game; and every screen names the clicks where it used to name E.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const VILLAGE: String = "res://world/areas/village/village.tscn"
const FARM: String = "res://world/areas/homestead/homestead.tscn"
const FIELD: String = "res://world/areas/south_field/south_field.tscn"
const TITLE: String = "res://ui/title_screen.tscn"
const ENDING: String = "res://ui/ending_screen.tscn"
const TEST_SLOT: int = 981
const FRAME: float = 1.0 / 60.0
## The field's north-west corner on the homestead, the pond's west bank there, and open grass
## on the farm well away from the field and from water; and open grass in Hearthvale.
const PLOT: Vector2i = Vector2i(22, 17)
const POND_BANK: Vector2i = Vector2i(3, 22)
const FARM_GRASS: Vector2i = Vector2i(34, 12)
const GRASS: Vector2i = Vector2i(23, 20)

var _area: Node
var _heard: Array[StringName] = []


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	GameState.set_time(float(GameState.day_clock().in_day("12:00")))
	SaveSystem.current_slot = TEST_SLOT
	# The main quest begins with the game, with a chime: before these tests listen.
	Quests.refresh()
	_heard.clear()
	EventBus.sound.connect(_on_sound)


func after_test() -> void:
	EventBus.sound.disconnect(_on_sound)
	if is_instance_valid(_area):
		_area.free()
	_area = null
	SaveSystem.erase_slot(TEST_SLOT)
	SaveSystem.current_slot = SaveSystem.GAME_SLOT
	Audio.play_music(&"")
	GameState.clear()


func test_the_prompt_names_the_right_click() -> void:
	assert_str(MenuInput.INTERACT_KEY).is_equal("Right click")
	assert_str(MenuInput.prompt("Open the door")).is_equal("[Right click] Open the door")
	var village: AreaController = _load(VILLAGE)
	var oda: Talkable = Steps.stand_before(village, "FarmerOda")
	village._update_hud()
	assert_str(village.hud.prompt_text()).is_equal("[Right click] %s" % oda.prompt())
	village.player.motor.place(GRASS)
	village._update_hud()
	assert_str(village.hud.prompt_text()).override_failure_message("nothing to do here, nothing said").is_equal("")


func test_either_click_is_a_menus_yes_and_the_left_one_answers() -> void:
	assert_bool(MenuInput.is_confirm(_click(MOUSE_BUTTON_LEFT))).is_true()
	assert_bool(MenuInput.is_confirm(_click(MOUSE_BUTTON_RIGHT))).is_true()
	assert_bool(MenuInput.is_confirm(_click(MOUSE_BUTTON_MIDDLE))).override_failure_message("the middle button is nothing").is_false()
	# In a conversation the left click answers; the right click, which starts one, doesn't.
	assert_str(MenuInput.ANSWER_KEY).is_equal("Left click")
	assert_bool(MenuInput.is_answer(_click(MOUSE_BUTTON_LEFT))).is_true()
	assert_bool(MenuInput.is_answer(_click(MOUSE_BUTTON_RIGHT))).override_failure_message("a right click doesn't answer").is_false()
	# A pad's A and Enter answer as they did; Space, which only swings the sword, doesn't.
	var pad: InputEventJoypadButton = InputEventJoypadButton.new()
	pad.button_index = JOY_BUTTON_A
	pad.pressed = true
	assert_bool(MenuInput.is_answer(pad)).override_failure_message("A on a pad").is_true()
	assert_bool(MenuInput.is_answer(_key(KEY_ENTER))).override_failure_message("Enter").is_true()
	assert_bool(MenuInput.is_answer(_key(KEY_SPACE))).override_failure_message("Space swings; it doesn't answer").is_false()
	for button: MouseButton in [MOUSE_BUTTON_LEFT, MOUSE_BUTTON_RIGHT]:
		assert_bool(MenuInput.is_back(_click(button)) or MenuInput.is_up(_click(button)) or MenuInput.is_down(_click(button))).is_false()
		var released: InputEventMouseButton = _click(button)
		released.pressed = false
		assert_bool(MenuInput.is_confirm(released)).override_failure_message("letting go isn't a second yes").is_false()


func test_a_right_click_talks_a_left_click_answers_and_either_click_chooses() -> void:
	GameState.add_item(&"bow")
	GameState.add_item(&"arrow", 5)
	GameState.add_item(&"bread", 2)
	GameState.set_energy(40.0)
	var village: AreaController = _load(VILLAGE)
	Steps.stand_before(village, "FarmerOda")
	village._unhandled_input(_click(MOUSE_BUTTON_RIGHT))
	assert_bool(village.is_talking()).override_failure_message("a right click starts the conversation").is_true()
	var box: DialogueBox = village.hud.dialogue
	var first: String = box.shown_text()
	var answers: PackedStringArray = box.shown_options()
	box._process(DialogueBox.SWING_GRACE + 0.05)
	box._unhandled_input(_click(MOUSE_BUTTON_RIGHT))
	assert_bool(village.is_talking() and box.shown_text() == first and box.shown_options() == answers).override_failure_message("a right click doesn't answer").is_true()
	for i: int in 30:
		if not village.is_talking():
			break
		box._unhandled_input(_click(MOUSE_BUTTON_LEFT))
	assert_bool(village.is_talking()).override_failure_message("left clicks carry it to its end").is_false()
	assert_int(GameState.item_count(&"arrow")).override_failure_message("no arrow was loosed meanwhile").is_equal(5)
	# The item menu: either click chooses the line under the cursor.
	village.player.motor.place(GRASS)
	assert_bool(village.open_item_menu()).is_true()
	village.hud.item_menu.move_cursor(1)
	village.hud.item_menu._unhandled_input(_click(MOUSE_BUTTON_LEFT))
	assert_bool(village.hud.item_menu.is_open()).is_false()
	assert_int(GameState.item_count(&"bread")).override_failure_message("he ate the bread he clicked on").is_equal(1)
	assert_bool(village.open_item_menu()).is_true()
	village.hud.item_menu.move_cursor(1)
	village.hud.item_menu._unhandled_input(_click(MOUSE_BUTTON_RIGHT))
	assert_int(GameState.item_count(&"bread")).is_equal(0)
	# With nobody before him a right click does nothing.
	village._unhandled_input(_click(MOUSE_BUTTON_RIGHT))
	assert_bool(village.is_talking() or village.is_in_menu()).is_false()


func test_a_swing_as_the_words_appear_doesnt_skip_them() -> void:
	var village: AreaController = _load(VILLAGE)
	Steps.stand_before(village, "FarmerOda")
	assert_bool(village.interact()).is_true()
	var box: DialogueBox = village.hud.dialogue
	var first: String = box.shown_text()
	assert_float(box.open_for).override_failure_message("just opened").is_equal(0.0)
	# The left click is the sword's button too: in the first moment it answers nothing.
	box._unhandled_input(_click(MOUSE_BUTTON_LEFT))
	box._process(DialogueBox.SWING_GRACE * 0.5)
	box._unhandled_input(_click(MOUSE_BUTTON_LEFT))
	assert_bool(village.is_talking() and box.shown_text() == first).override_failure_message("the first words are still there").is_true()
	# Enter is nobody's sword: it answers at once.
	box._unhandled_input(_key(KEY_ENTER))
	assert_bool(village.is_talking() and box.shown_text() == first).override_failure_message("Enter answered").is_false()
	# A moment later the left click answers; and the wait starts again with each conversation.
	for i: int in 30:
		if not village.is_talking():
			break
		box._process(DialogueBox.SWING_GRACE)
		box._unhandled_input(_click(MOUSE_BUTTON_LEFT))
	assert_bool(village.is_talking()).is_false()
	assert_bool(village.interact()).is_true()
	assert_float(box.open_for).override_failure_message("a new conversation, a new wait").is_equal(0.0)
	assert_float(DialogueBox.SWING_GRACE).override_failure_message("short enough not to be felt").is_between(0.15, 0.5)


func test_a_left_click_swings_the_sword_when_nothing_else_is_in_hand() -> void:
	var village: AreaController = _load(VILLAGE)
	village.player.motor.place(GRASS)
	assert_bool(village.use_hand()).override_failure_message("no sword yet, nothing in hand").is_false()
	GameState.add_item(&"wooden_sword")
	village._unhandled_input(_click(MOUSE_BUTTON_LEFT))
	assert_bool(village.player.motor.is_attacking()).override_failure_message("a left click swings").is_true()
	assert_array(_heard).contains([&"sword"])
	assert_float(GameState.energy).override_failure_message("a swing's energy").is_equal(99.5)
	# A right click swings nothing.
	_rest(village)
	village._unhandled_input(_click(MOUSE_BUTTON_RIGHT))
	assert_bool(village.player.motor.is_attacking()).is_false()
	assert_float(GameState.energy).is_equal(99.5)


func test_a_left_click_uses_the_bow_or_the_bombs_in_hand() -> void:
	GameState.add_item(&"wooden_sword")
	GameState.add_item(&"bow")
	GameState.add_item(&"arrow", 3)
	var village: AreaController = _load(VILLAGE)
	village.player.motor.place(GRASS)
	assert_bool(village.use_hand()).is_true()
	assert_int(GameState.item_count(&"arrow")).override_failure_message("the bow in hand shoots").is_equal(2)
	assert_array(_heard).contains([&"arrow"])
	assert_array(_heard).override_failure_message("it is the bow he uses, not the sword").not_contains([&"sword"])
	_rest(village)
	GameState.add_item(&"bomb", 2)
	GameState.equip(&"bomb")
	assert_bool(village.use_hand()).is_true()
	assert_int(GameState.item_count(&"bomb")).is_equal(1)
	# The keys are as they were: Space swings whatever is in hand, Q uses the item.
	_rest(village)
	assert_bool(village.player.swing()).is_true()
	_rest(village)
	assert_bool(village.use_item()).is_true()
	assert_int(GameState.item_count(&"bomb")).is_equal(0)


func test_a_bow_with_no_arrows_gives_the_left_click_to_the_sword() -> void:
	# (The last bomb leaves the bar altogether: tests/ui/item_bar_test.gd.)
	GameState.add_item(&"wooden_sword")
	GameState.add_item(&"bow")
	assert_that(GameState.equipped).is_equal(&"bow")
	var field: AreaController = _load(FIELD)
	field.player.motor.place(Vector2i(12, 12))
	field.player.face(Vector2.LEFT)
	_heard.clear()
	# With nothing to shoot the click is the sword's: running out is no dead end.
	assert_bool(field.use_hand()).is_true()
	assert_bool(field.player.motor.is_attacking()).is_true()
	assert_array(_heard).contains([&"sword"])
	assert_array(_heard).not_contains([&"nope"])
	assert_object(field.last_projectile).override_failure_message("no arrow flew").is_null()
	assert_that(GameState.equipped).override_failure_message("the bow is still his, and still in hand").is_equal(&"bow")
	# The item button's own key still says there are none.
	_rest(field)
	assert_bool(field.use_item()).is_false()
	assert_str(field.hud.message_text()).is_equal("Out of arrows.")
	# With arrows it shoots again.
	GameState.add_item(&"arrow", 1)
	_heard.clear()
	assert_bool(field.use_hand()).is_true()
	assert_object(field.last_projectile).is_instanceof(Arrow)
	assert_int(GameState.item_count(&"arrow")).is_equal(0)
	assert_array(_heard).not_contains([&"sword"])
	# With no sword to fall back on, the empty bow says so.
	_rest(field)
	GameState.add_item(&"wooden_sword", -1)
	_heard.clear()
	assert_bool(field.use_hand()).is_false()
	assert_str(field.hud.message_text()).is_equal("Out of arrows.")
	assert_array(_heard).contains_exactly([&"nope"])


func test_a_left_click_works_the_plot_with_a_tool_and_swings_the_sword_elsewhere() -> void:
	for item: Array in [[&"wooden_sword", 1], [&"hoe", 1], [&"watering_can", 1], [&"turnip_seeds", 2]]:
		GameState.add_item(item[0], item[1])
	GameState.equip(&"hoe")
	var farm: AreaController = _load(FARM)
	# Facing the plot: the hoe.
	_face_plot(farm, Vector2i(2, 0))
	assert_bool(farm.faces_farm_work()).is_true()
	farm._unhandled_input(_click(MOUSE_BUTTON_LEFT))
	assert_bool(GameState.farm().is_tilled(Vector2i(2, 0))).override_failure_message("a left click hoes").is_true()
	assert_array(_heard).contains([&"hoe"])
	assert_array(_heard).not_contains([&"sword"])
	# The same cell again: the hoe says why not, and he doesn't hack at his plot.
	_rest(farm)
	_heard.clear()
	assert_bool(farm.use_hand()).is_false()
	assert_str(farm.hud.message_text()).is_equal(ToolUse.HOE_DONE)
	assert_array(_heard).contains_exactly([&"nope"])
	# Seeds, then the can at the pond and on the seed.
	GameState.equip(&"turnip_seeds")
	assert_bool(farm.use_hand()).is_true()
	assert_str(GameState.farm().crop_at(Vector2i(2, 0))).is_equal("turnip")
	_rest(farm)
	GameState.equip(&"watering_can")
	farm.player.motor.place(POND_BANK)
	farm.player.face(Vector2.RIGHT)
	assert_bool(farm.faces_farm_work()).override_failure_message("the pond is work for the can").is_true()
	assert_bool(farm.use_hand()).is_true()
	assert_int(GameState.item_count(&"water")).is_equal(10)
	_rest(farm)
	_face_plot(farm, Vector2i(2, 0))
	assert_bool(farm.use_hand()).is_true()
	assert_bool(GameState.farm().is_watered(Vector2i(2, 0))).is_true()
	# Away from the plot and the water a tool in hand is no use: he swings his sword.
	for tool: StringName in [&"hoe", &"watering_can", &"turnip_seeds"]:
		_rest(farm)
		GameState.equip(tool)
		farm.player.motor.place(FARM_GRASS)
		farm.player.face(Vector2.UP)
		assert_bool(farm.faces_farm_work()).is_false()
		_heard.clear()
		var energy: float = GameState.energy
		farm.hud.show_message("-")
		assert_bool(farm.use_hand()).override_failure_message("with the %s in hand" % tool).is_true()
		assert_array(_heard).contains_exactly([&"sword"])
		assert_float(GameState.energy).is_equal(energy - 0.5)
		assert_str(farm.hud.message_text()).override_failure_message("and the tool says nothing").is_equal("-")
	assert_int(GameState.item_count(&"turnip_seeds")).is_equal(1)
	assert_int(GameState.farm().crop_count()).is_equal(1)
	# The item's own key still asks the tool, wherever he is.
	_rest(farm)
	GameState.equip(&"hoe")
	assert_bool(farm.use_item()).is_false()
	assert_str(farm.hud.message_text()).is_equal(ToolUse.HOE_NOT_HERE)


func test_with_no_sword_a_tool_says_what_it_is_for() -> void:
	GameState.add_item(&"hoe")
	var village: AreaController = _load(VILLAGE)
	village.player.motor.place(GRASS)
	village.player.face(Vector2.UP)
	assert_bool(village.use_hand()).is_false()
	assert_str(village.hud.message_text()).is_equal(ToolUse.HOE_NOT_HERE)
	assert_array(_heard).contains_exactly([&"nope"])


func test_a_tool_in_hand_doesnt_leave_him_unarmed_among_monsters() -> void:
	GameState.add_item(&"wooden_sword")
	GameState.add_item(&"hoe")
	var field: AreaController = _load(FIELD)
	assert_object(field.plot).is_null()
	field.player.motor.place(Vector2i(12, 12))
	field.player.face(Vector2.LEFT)
	assert_bool(field.faces_farm_work()).is_false()
	assert_bool(field.use_hand()).is_true()
	assert_bool(field.player.motor.is_attacking()).is_true()
	assert_array(_heard).contains([&"sword"])


func test_the_sword_can_be_taken_in_hand_again_on_the_bar() -> void:
	GameState.add_item(&"wooden_sword")
	GameState.add_item(&"bread")
	GameState.set_energy(50.0)
	var village: AreaController = _load(VILLAGE)
	village.player.motor.place(GRASS)
	village._update_hud()
	var bar: ItemBar = village.hud.item_bar
	# With only a sword, it is the bar's one slot, and in hand.
	assert_array(bar.shown_ids()).is_equal([&"wooden_sword"])
	assert_int(bar.lit_slot()).is_equal(0)
	GameState.add_item(&"bow")
	GameState.add_item(&"arrow", 4)
	assert_that(GameState.equipped).is_equal(&"bow")
	village._update_hud()
	assert_array(bar.shown_ids()).is_equal([&"wooden_sword", &"bow"])
	assert_int(bar.lit_slot()).is_equal(1)
	# The sword's slot: nothing on the item button.
	assert_bool(village.choose_slot(0)).is_true()
	assert_that(GameState.equipped).override_failure_message("the sword in hand: nothing on the item button").is_equal(&"")
	assert_int(GameState.item_count(&"wooden_sword")).is_equal(1)
	village._update_hud()
	assert_bool(village.hud.shown_lines().has(AreaController.equipped_text())).override_failure_message("no item line on the HUD").is_false()
	assert_bool(village.use_hand()).is_true()
	assert_array(_heard).contains([&"sword"])
	assert_int(GameState.item_count(&"arrow")).override_failure_message("the bow stays in the pack").is_equal(4)
	# The bow can be taken up again.
	_rest(village)
	assert_bool(village.choose_slot(1)).is_true()
	assert_that(GameState.equipped).is_equal(&"bow")
	# It is his best sword that has the slot.
	GameState.add_item(&"iron_sword")
	village._update_hud()
	assert_array(bar.shown_ids()).is_equal([&"iron_sword", &"bow"])
	# With no sword at all the bar begins with the bow, and the Tab menu is the food's alone.
	GameState.add_item(&"wooden_sword", -1)
	GameState.add_item(&"iron_sword", -1)
	village._update_hud()
	assert_array(bar.shown_ids()).is_equal([&"bow"])
	assert_bool(village.open_item_menu()).is_true()
	assert_array(Array(village.hud.item_menu.shown_lines())).is_equal(["> Bread x1 (+30 energy)"])


func test_nothing_on_any_screen_takes_a_click_for_itself() -> void:
	var village: AreaController = _load(VILLAGE)
	var counted: int = _assert_ignores_mouse(village.hud, "the HUD")
	assert_int(counted).override_failure_message("the HUD, its menus and its boxes").is_greater(30)
	village.free()
	_area = null
	for path: String in [TITLE, ENDING]:
		var screen: Control = (load(path) as PackedScene).instantiate()
		get_tree().root.add_child(screen)
		_area = screen
		assert_int(_assert_ignores_mouse(screen, path)).is_greater(3)
		screen.free()
		_area = null
	# The helper itself: everything under a node, and the node.
	var box: Control = auto_free(Control.new())
	var inner: ColorRect = ColorRect.new()
	var label: Label = Label.new()
	box.add_child(inner)
	inner.add_child(label)
	assert_int(inner.mouse_filter).override_failure_message("a box takes clicks unless told not to").is_equal(Control.MOUSE_FILTER_STOP)
	MenuInput.let_clicks_through(box)
	for control: Control in [box, inner, label]:
		assert_int(control.mouse_filter).is_equal(Control.MOUSE_FILTER_IGNORE)


func test_every_screen_names_the_clicks_and_none_names_e() -> void:
	var village: AreaController = _load(VILLAGE)
	var said: PackedStringArray = _words(village.hud)
	village.free()
	_area = null
	for path: String in [TITLE, ENDING]:
		var screen: Control = (load(path) as PackedScene).instantiate()
		get_tree().root.add_child(screen)
		said.append_array(_words(screen))
		screen.free()
	var named: int = 0
	for words: String in said:
		for old: String in ["[E]", "E: ", "E or Enter", " E "]:
			assert_bool(words.contains(old)).override_failure_message("'%s' still names E" % words).is_false()
		if words.to_lower().contains("click"):
			named += 1
	assert_int(named).override_failure_message("the HUD's keys, the answer mark, the item menu, the pause menu, the title, the ending").is_greater_equal(6)
	var all: String = "\n".join(said)
	assert_bool(all.contains("WASD: move")).override_failure_message("moving is as it was").is_true()
	assert_bool(all.contains("Left click: sword / item")).is_true()
	assert_bool(all.contains("Right click: talk / take")).is_true()
	assert_bool(all.contains("[Left click]")).override_failure_message("the answer mark in a conversation").is_true()
	assert_bool(all.contains("[Right click]")).override_failure_message("no conversation is answered with the right click").is_false()


## Checks that no Control under `root` (or `root` itself) takes mouse input. Returns how many
## there were.
func _assert_ignores_mouse(root: Node, where: String) -> int:
	var count: int = 0
	if root is Control:
		count += 1
		assert_int((root as Control).mouse_filter).override_failure_message("%s: %s lets clicks through" % [where, root.name]).is_equal(Control.MOUSE_FILTER_IGNORE)
	for child: Node in root.get_children():
		count += _assert_ignores_mouse(child, where)
	return count


## The text of every label under `root`.
func _words(root: Node) -> PackedStringArray:
	var out: PackedStringArray = []
	if root is Label and not (root as Label).text.is_empty():
		out.append((root as Label).text)
	for child: Node in root.get_children():
		out.append_array(_words(child))
	return out


## Puts the hero in the cell below the plot's own cell `cell`, facing up at it.
func _face_plot(area: AreaController, cell: Vector2i) -> void:
	area.player.motor.place(PLOT + cell + Vector2i.DOWN)
	area.player.face(Vector2.UP)


## Lets a stroke or a swing finish.
func _rest(area: AreaController) -> void:
	for i: int in 40:
		area.player.motor.step(Vector2.ZERO, FRAME)


func _key(code: Key) -> InputEventKey:
	var event: InputEventKey = InputEventKey.new()
	event.keycode = code
	event.physical_keycode = code
	event.pressed = true
	return event


func _click(button: MouseButton) -> InputEventMouseButton:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = button
	event.pressed = true
	return event


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area


func _on_sound(id: StringName) -> void:
	_heard.append(id)
