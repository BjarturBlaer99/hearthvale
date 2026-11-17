extends GdUnitTestSuite
## Crafting at home (phase 2a): the workbench stands in the cottage from the start and opens a
## list of what he knows how to make, with what each needs beside what he has, and what he
## can't make greyed out. The furnace is made there; it smelts ore into bars overnight. What
## he has ever held is remembered, and all of it goes through a save.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const HOME: String = "res://world/areas/home/home.tscn"
const TEST_SLOT: int = 960
const WORKBENCH_CELL: Vector2i = Vector2i(9, 3)
const FURNACE_CELL: Vector2i = Vector2i(6, 2)

var _area: Node
var _heard: Array[StringName] = []
var _made: Array[StringName] = []


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	Quests.refresh()
	_heard.clear()
	_made.clear()
	EventBus.sound.connect(_on_sound)
	EventBus.crafted.connect(_on_crafted)


func after_test() -> void:
	EventBus.sound.disconnect(_on_sound)
	EventBus.crafted.disconnect(_on_crafted)
	if is_instance_valid(_area):
		_area.free()
	_area = null
	GameState.clear()
	SaveSystem.current_slot = SaveSystem.GAME_SLOT
	SaveSystem.erase_slot(TEST_SLOT)


func test_the_workbench_stands_in_the_cottage_from_the_first_day() -> void:
	var home: AreaController = _load(HOME)
	var bench: Furnishing = home.interactables.get_node(^"Workbench")
	assert_that(bench.cell()).is_equal(WORKBENCH_CELL)
	assert_bool(bench.is_there()).is_true()
	assert_bool(home.terrain.is_occupied(WORKBENCH_CELL)).override_failure_message("it fills its cell").is_true()
	assert_bool(home.grid.is_solid(WORKBENCH_CELL)).override_failure_message("the room's own map is as it was").is_false()
	assert_str(bench.prompt()).is_equal("Use the workbench")
	# Nothing is known yet but the things that wait on nothing; the furnace's place is empty.
	var furnace: Furnishing = home.interactables.get_node(^"Furnace")
	assert_bool(furnace.is_there()).is_false()
	assert_bool(home.terrain.is_occupied(FURNACE_CELL)).is_false()
	assert_bool(furnace.covers(FURNACE_CELL)).override_failure_message("not there to be faced").is_false()
	# Interacting opens the list; he stands still while it is open, and the clock with him.
	Steps.stand_before(home, "Workbench")
	assert_bool(home.interact()).is_true()
	var menu: CraftMenu = home.hud.craft_menu
	assert_bool(menu.is_open()).is_true()
	assert_bool(home.is_in_menu()).is_true()
	assert_bool(home.player.controls_enabled).is_false()
	assert_bool(home.clock_runs()).is_false()
	assert_str((menu.get_node(^"Panel/Title") as Label).text).is_equal("Workbench")
	assert_bool(_ids(menu.entries()).has("furnace")).override_failure_message("no copper ore found yet: no furnace on the list").is_false()
	menu.close()
	assert_bool(home.player.controls_enabled).is_true()
	assert_bool(home.is_in_menu()).is_false()


func test_a_recipe_is_listed_once_its_item_has_been_found_and_stays() -> void:
	assert_bool(GameState.has_found(&"copper_ore")).is_false()
	assert_bool(_ids(GameState.known_crafts(Crafting.WORKBENCH)).has("furnace")).is_false()
	GameState.add_item(&"copper_ore", 2)
	assert_bool(GameState.has_found(&"copper_ore")).is_true()
	assert_bool(_ids(GameState.known_crafts(Crafting.WORKBENCH)).has("furnace")).is_true()
	# The last of it gone (sold, used), the recipe is still known.
	GameState.add_item(&"copper_ore", -2)
	assert_int(GameState.item_count(&"copper_ore")).is_equal(0)
	assert_bool(GameState.has_found(&"copper_ore")).is_true()
	assert_bool(_ids(GameState.known_crafts(Crafting.WORKBENCH)).has("furnace")).is_true()
	# Bombs wait on coal; taking some away finds nothing.
	assert_bool(_ids(GameState.known_crafts(Crafting.WORKBENCH)).has("bombs")).is_false()
	GameState.add_item(&"coal", -1)
	assert_bool(GameState.has_found(&"coal")).is_false()
	GameState.add_item(&"coal", 1)
	assert_bool(_ids(GameState.known_crafts(Crafting.WORKBENCH)).has("bombs")).is_true()


func test_the_list_shows_what_each_thing_needs_and_greys_out_what_he_cant_make() -> void:
	GameState.add_item(&"copper_ore", 5)
	GameState.add_item(&"stone", 12)
	GameState.add_item(&"coal", 1)
	var home: AreaController = _load(HOME)
	assert_bool(home.open_craft()).is_true()
	var menu: CraftMenu = home.hud.craft_menu
	assert_array(_ids(menu.entries())).override_failure_message("the rug waits on nothing: it is always on the list").is_equal(["furnace", "bombs", "rug"])
	assert_array(Array(menu.shown_lines())).is_equal(["> Furnace", "  Bombs x3", "  Woven Rug"])
	assert_array(menu.greyed_lines()).override_failure_message("twelve stone of twenty: the furnace is greyed; bombs can be made; he has no wheat for the rug").is_equal([true, false, true])
	assert_array(Array(menu.bright_lines())).override_failure_message("a greyed line is on the dim list only: the bright one is blank there").is_equal(["", "  Bombs x3", ""])
	assert_bool(menu.can_make(0)).is_false()
	assert_bool(menu.can_make(1)).is_true()
	assert_array(Array(menu.need_lines())).is_equal(["Stone 12 of 20", "Copper Ore 5 of 5"])
	assert_str(menu.needs_text()).is_equal("Needs:\nStone 12 of 20\nCopper Ore 5 of 5")
	# What he can't make, he is told why, and nothing changes.
	var before: Dictionary = GameState.to_dict()
	assert_bool(menu.confirm()).is_false()
	assert_str(menu.note_text()).is_equal(Crafting.LACKING_WORDS)
	assert_array(_heard).contains([&"nope"])
	assert_dict(GameState.to_dict()).is_equal(before)
	assert_bool(_made.is_empty()).is_true()
	# The cursor moves to the bombs, and the needs follow it.
	menu.move_cursor(1)
	assert_array(Array(menu.shown_lines())).is_equal(["  Furnace", "> Bombs x3", "  Woven Rug"])
	assert_array(Array(menu.need_lines())).is_equal(["Coal 1 of 1", "Stone 3 of 3"])
	assert_str(menu.note_text()).override_failure_message("the note was about the furnace").is_equal("")


func test_making_a_thing_takes_what_it_needs_and_gives_what_it_makes() -> void:
	GameState.add_item(&"coal", 3)
	GameState.add_item(&"stone", 13)
	var home: AreaController = _load(HOME)
	home.open_craft()
	var menu: CraftMenu = home.hud.craft_menu
	assert_array(_ids(menu.entries())).is_equal(["bombs", "rug"])
	_heard.clear()
	assert_bool(menu.confirm()).is_true()
	assert_int(GameState.item_count(&"bomb")).is_equal(3)
	assert_int(GameState.item_count(&"coal")).is_equal(2)
	assert_int(GameState.item_count(&"stone")).is_equal(10)
	assert_str(menu.note_text()).is_equal("Made: Bombs x3.")
	assert_array(_heard).contains([&"craft"])
	assert_array(_made).is_equal([&"bombs"])
	assert_bool(menu.is_open()).override_failure_message("the list stays for more").is_true()
	# Three times is nine bombs; a fourth would be twelve in a bag of ten.
	assert_bool(menu.confirm()).is_true()
	assert_bool(menu.confirm()).is_true()
	assert_int(GameState.item_count(&"bomb")).is_equal(9)
	GameState.add_item(&"coal", 1)
	assert_str(GameState.why_not_craft(menu.entries()[0])).override_failure_message("he has the makings: it is room he lacks").is_equal(Crafting.NO_ROOM_WORDS)
	assert_bool(menu.confirm()).is_false()
	assert_array(menu.greyed_lines()).override_failure_message("what he has no room for is greyed too").is_equal([true, true])
	assert_str(menu.note_text()).is_equal(Crafting.NO_ROOM_WORDS)
	assert_int(GameState.item_count(&"bomb")).is_equal(9)
	assert_int(GameState.item_count(&"coal")).override_failure_message("nothing was used").is_equal(1)
	# Only what he knows can be made, and only at the workbench.
	assert_str(GameState.craft(&"furnace")).override_failure_message("copper ore never found").is_equal(Crafting.UNKNOWN_WORDS)
	assert_str(GameState.craft(&"copper_bar")).override_failure_message("the furnace's, not the workbench's").is_equal(Crafting.UNKNOWN_WORDS)
	assert_str(GameState.craft(&"no_such_thing")).is_equal(Crafting.UNKNOWN_WORDS)


func test_the_furnace_is_made_once_and_stands_in_its_place() -> void:
	GameState.add_item(&"stone", 45)
	GameState.add_item(&"copper_ore", 12)
	var home: AreaController = _load(HOME)
	var furnace: Furnishing = home.interactables.get_node(^"Furnace")
	home.open_craft()
	var menu: CraftMenu = home.hud.craft_menu
	assert_array(Array(menu.shown_lines())).is_equal(["> Furnace", "  Woven Rug"])
	assert_bool(menu.confirm()).is_true()
	assert_str(menu.note_text()).is_equal("Made: Furnace.")
	assert_int(GameState.item_count(&"stone")).is_equal(25)
	assert_int(GameState.item_count(&"copper_ore")).is_equal(7)
	assert_bool(GameState.is_furnished(&"furnace")).is_true()
	assert_bool(GameState.get_flag(&"home/furnace") == true).is_true()
	# It is there at once: seen, in the way, and to be faced.
	assert_bool(furnace.is_there()).is_true()
	assert_bool(home.terrain.is_occupied(FURNACE_CELL)).is_true()
	assert_bool(furnace.covers(FURNACE_CELL)).is_true()
	assert_str(furnace.prompt()).is_equal("Use the furnace")
	# A second can't be made, though he has the stone for it.
	assert_array(menu.greyed_lines()).is_equal([true, true])
	assert_bool(menu.confirm()).is_false()
	assert_str(menu.note_text()).is_equal(Crafting.HAVE_ONE_WORDS)
	assert_int(GameState.item_count(&"stone")).is_equal(25)
	# And it is there when he comes home again.
	menu.close()
	home = _load(HOME)
	assert_bool((home.interactables.get_node(^"Furnace") as Furnishing).is_there()).is_true()
	assert_bool(home.terrain.is_occupied(FURNACE_CELL)).is_true()


func test_the_furnace_turns_ore_into_bars_overnight() -> void:
	GameState.set_flag(Crafting.furnished_flag(&"furnace"), true)
	GameState.add_item(&"copper_ore", 11)
	GameState.add_item(&"coal", 8)
	var home: AreaController = _load(HOME)
	var furnace: Furnishing = Steps.stand_before(home, "Furnace")
	assert_bool(furnace.is_burning()).is_false()
	assert_that(furnace.frames()).is_equal([&"furnace"] as Array[StringName])
	assert_bool(furnace.glow_now().is_empty()).is_true()
	# Cold, it lists what he can smelt: copper for three bars, and iron and gold he has no ore for.
	assert_bool(home.interact()).is_true()
	assert_str(home.hud.dialogue.shown_text()).is_equal(Furnace.COLD_WORDS)
	assert_array(Array(home.hud.dialogue.shown_options())).is_equal([
		"Copper Bar x3 (9 Copper Ore, 3 Coal)", "Iron Bar (3 Iron Ore, 1 Coal)", "Gold Bar (3 Gold Ore, 1 Coal)", Furnace.NOT_NOW_WORDS,
	])
	_heard.clear()
	home.hud.dialogue.confirm()
	assert_str(home.hud.dialogue.shown_text()).is_equal("You load the furnace and light it. The copper bar x3 will be ready in the morning.")
	home.hud.dialogue.confirm()
	assert_bool(home.is_talking()).is_false()
	assert_int(GameState.item_count(&"copper_ore")).is_equal(2)
	assert_int(GameState.item_count(&"coal")).is_equal(5)
	assert_int(GameState.item_count(&"copper_bar")).override_failure_message("not yet").is_equal(0)
	assert_array(_heard).contains([&"furnace"])
	assert_bool(furnace.is_burning()).is_true()
	assert_that(furnace.frames()).is_equal([&"furnace_lit"] as Array[StringName])
	assert_bool(furnace.glow_now().is_empty()).override_failure_message("a burning furnace gives light").is_false()
	assert_array(home.glows_now()).contains([furnace.glow_now()])
	# The same day it is burning, and says so.
	home.interact()
	assert_str(home.hud.dialogue.shown_text()).is_equal("The furnace is burning. The copper bar x3 will be ready in the morning.")
	assert_array(Array(home.hud.dialogue.shown_options())).is_equal([Furnace.LEAVE_WORDS])
	home.hud.dialogue.confirm()
	assert_int(GameState.item_count(&"copper_bar")).is_equal(0)
	# The next morning the bars are there, and are his when he takes them.
	GameState.start_next_day()
	assert_bool(furnace.is_burning()).is_false()
	assert_that(furnace.frames()).is_equal([&"furnace"] as Array[StringName])
	home.interact()
	assert_str(home.hud.dialogue.shown_text()).is_equal("The furnace has burned down. In it: copper bar x3.")
	assert_array(Array(home.hud.dialogue.shown_options())).is_equal([Furnace.TAKE_WORDS, Furnace.LEAVE_WORDS])
	home.hud.dialogue.confirm()
	assert_int(GameState.item_count(&"copper_bar")).is_equal(3)
	assert_bool(GameState.furnace().is_empty()).is_true()
	assert_bool(GameState.has_found(&"copper_bar")).is_true()
	# Cold again, with ore for nothing: every line says what one bar takes.
	home.interact()
	assert_str(home.hud.dialogue.shown_text()).is_equal(Furnace.COLD_WORDS)
	assert_str(home.hud.dialogue.shown_options()[0]).is_equal("Copper Bar (3 Copper Ore, 1 Coal)")
	home.hud.dialogue.confirm()
	assert_str(home.hud.dialogue.shown_text()).is_equal(Furnace.LACKING_WORDS)


func test_a_load_is_five_bars_at_the_most_and_what_doesnt_fit_is_laid_at_his_feet() -> void:
	GameState.set_flag(Crafting.furnished_flag(&"furnace"), true)
	GameState.add_item(&"iron_ore", 30)
	GameState.add_item(&"coal", 30)
	GameState.add_item(&"iron_bar", 17)
	var home: AreaController = _load(HOME)
	Steps.stand_before(home, "Furnace")
	home.interact()
	assert_str(home.hud.dialogue.shown_options()[1]).override_failure_message("ore and coal for ten, room in the fire for five").is_equal("Iron Bar x5 (15 Iron Ore, 5 Coal)")
	home.hud.dialogue.move_cursor(1)
	home.hud.dialogue.confirm()
	home.hud.dialogue.confirm()
	assert_int(GameState.item_count(&"iron_ore")).is_equal(15)
	assert_int(GameState.item_count(&"coal")).is_equal(25)
	assert_dict(GameState.furnace().to_dict()).is_equal({"item": "iron_bar", "count": 5, "day": 1})
	# A burning furnace takes no second load.
	assert_bool(GameState.light_furnace(&"copper_bar", 1)).is_false()
	GameState.start_next_day()
	# Twenty bars is a full stack: three go in the pack, two are laid at his feet, none is lost.
	home.interact()
	home.hud.dialogue.confirm()
	assert_int(GameState.item_count(&"iron_bar")).is_equal(20)
	assert_bool(GameState.furnace().is_empty()).is_true()
	var left: Array = []
	for child: Node in home.interactables.get_children():
		if child is LeftItem:
			left.append([(child as LeftItem).item_id, (child as LeftItem).count])
	assert_array(left).override_failure_message("two bars lie where he stands").is_equal([[&"iron_bar", 2]])


func test_the_mouse_points_and_the_wheel_steps_in_the_workbenchs_list() -> void:
	GameState.add_item(&"copper_ore", 5)
	GameState.add_item(&"stone", 23)
	GameState.add_item(&"coal", 1)
	var home: AreaController = _load(HOME)
	home.open_craft()
	var menu: CraftMenu = home.hud.craft_menu
	var list: Label = menu.get_node(^"Panel/List")
	await await_idle_frame()
	assert_int(menu.selected).is_equal(0)
	menu._unhandled_input(_move(list, 1))
	assert_int(menu.selected).override_failure_message("the line under the mouse is the one chosen").is_equal(1)
	menu._unhandled_input(_wheel(MOUSE_BUTTON_WHEEL_UP))
	assert_int(menu.selected).is_equal(0)
	menu._unhandled_input(_wheel(MOUSE_BUTTON_WHEEL_DOWN))
	assert_int(menu.selected).is_equal(1)
	# A click on a line makes that thing.
	menu._unhandled_input(_click_at(_point(list, 0)))
	assert_bool(GameState.is_furnished(&"furnace")).override_failure_message("a click on the furnace's line makes it").is_true()
	assert_int(menu.selected).is_equal(0)
	assert_int(GameState.item_count(&"bomb")).is_equal(0)
	# A click on no line makes the one under the cursor.
	menu.move_cursor(1)
	menu._unhandled_input(_click_at(Vector2(3.0, 3.0)))
	assert_int(GameState.item_count(&"bomb")).is_equal(3)
	# Tab leaves.
	var back: InputEventAction = InputEventAction.new()
	back.action = &"item_menu"
	back.pressed = true
	menu._unhandled_input(back)
	assert_bool(menu.is_open()).is_false()
	assert_bool(home.player.controls_enabled).is_true()


func test_a_long_list_scrolls_and_opens_at_the_top_each_time() -> void:
	# Everything found and both skills risen: all thirteen recipes are known.
	for item: StringName in [&"copper_ore", &"wood", &"coal", &"copper_bar", &"iron_bar", &"crystal"]:
		GameState.add_item(item, 1)
	GameState.skill_points[Skills.FARMING] = 10
	GameState.skill_points[Skills.MINING] = 25
	var home: AreaController = _load(HOME)
	home.open_craft()
	var menu: CraftMenu = home.hud.craft_menu
	var list: Label = menu.get_node(^"Panel/List")
	await await_idle_frame()
	assert_int(menu.entries().size()).is_equal(13)
	assert_int(CraftMenu.ROWS).override_failure_message("the box has room for six").is_equal(6)
	assert_int(menu.shown_lines().size()).override_failure_message("six lines, however many he knows").is_equal(6)
	assert_str(menu.shown_lines()[0]).is_equal("> Furnace")
	assert_str((menu.get_node(^"Panel/Count") as Label).text).override_failure_message("it says there is more below").is_not_equal("")
	# The list moves along with the cursor.
	for step: int in 8:
		menu.move_cursor(1)
	assert_int(menu.selected).is_equal(8)
	assert_int(menu.top).is_equal(3)
	assert_int(menu.shown_lines().size()).is_equal(6)
	assert_str(menu.shown_lines()[5]).override_failure_message("the cursor's line is in view").is_equal("> Iron Watering Can")
	assert_array(Array(menu.need_lines())).is_equal(["Copper Watering Can 0 of 1", "Iron Bar 1 of 2"])
	# Pointing at the second line shown puts the cursor on the fifth recipe, not the second.
	menu._unhandled_input(_move(list, 1))
	assert_int(menu.selected).is_equal(4)
	assert_str(menu.shown_lines()[1]).is_equal("> Copper Hoe")
	# He hasn't the hoe: it says why. Closed and opened again, the list begins at the top
	# with nothing said.
	assert_bool(menu.confirm()).is_false()
	assert_str(menu.note_text()).is_equal(Crafting.LACKING_WORDS)
	menu.close()
	assert_bool(home.open_craft()).is_true()
	assert_int(menu.selected).override_failure_message("the cursor is on the first line again").is_equal(0)
	assert_int(menu.top).is_equal(0)
	assert_str(menu.note_text()).override_failure_message("what was said last time is gone").is_equal("")
	assert_str(menu.shown_lines()[0]).is_equal("> Furnace")


func test_crafting_goes_through_a_save_and_an_old_save_starts_with_none_of_it() -> void:
	GameState.add_item(&"copper_ore", 3)
	GameState.add_item(&"copper_ore", -3)
	GameState.add_item(&"coal", 2)
	GameState.set_flag(Crafting.furnished_flag(&"furnace"), true)
	GameState.light_furnace(&"copper_bar", 4)
	GameState.update_player(&"home", Vector2i(5, 5))
	assert_int(SaveSystem.save_to_slot(TEST_SLOT)).is_equal(OK)
	var on_disk: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(SaveSystem.slot_path(TEST_SLOT)))
	assert_int(int(on_disk["version"])).is_equal(5)
	assert_dict(on_disk["home"]["furnace"]).is_equal({"item": "copper_bar", "count": 4.0, "day": 1.0})
	assert_array(on_disk["found"]).is_equal(["coal", "copper_ore"])
	var before: String = JSON.stringify(GameState.to_dict(), "", true)
	GameState.clear()
	assert_bool(GameState.has_found(&"copper_ore") or not GameState.furnace().is_empty()).override_failure_message("cleared").is_false()
	assert_int(SaveSystem.load_from_slot(TEST_SLOT)).is_equal(OK)
	assert_str(JSON.stringify(GameState.to_dict(), "", true)).is_equal(before)
	assert_bool(GameState.has_found(&"copper_ore")).override_failure_message("found, though he carries none").is_true()
	assert_bool(GameState.furnace().is_burning(1)).is_true()
	assert_bool(GameState.is_furnished(&"furnace")).is_true()
	# A save from before crafting: a cold furnace, nothing furnished, and what it carries is found.
	var old: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://tests/fixtures/saves/v4_before_the_mine.json"))
	var migrated: Dictionary = SaveSystem.migrate(old, 4)
	assert_dict(migrated["home"]).is_equal({"furnace": {}, "chest": []})
	assert_array(migrated["found"]).is_empty()
	GameState.from_dict(migrated)
	assert_bool(GameState.furnace().is_empty()).is_true()
	for furnishing: String in GameState.crafting_rules()["furnishings"]:
		assert_bool(GameState.is_furnished(StringName(furnishing))).override_failure_message(furnishing).is_false()
	assert_bool(GameState.has_found(&"bread")).override_failure_message("what he carries, he has found").is_true()
	assert_bool(GameState.has_found(&"copper_ore")).is_false()
	GameState.add_item(&"bread", -GameState.item_count(&"bread"))
	assert_int(GameState.item_count(&"bread")).is_equal(0)
	assert_bool(GameState.has_found(&"bread")).override_failure_message("and it stays found when the last of it is eaten").is_true()
	# A save with no home in it at all still loads.
	migrated.erase("home")
	migrated.erase("found")
	GameState.from_dict(migrated)
	assert_bool(GameState.furnace().is_empty()).is_true()
	assert_bool(GameState.has_found(&"bread")).is_true()


# --- Helpers -------------------------------------------------------------------------------

func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area


func _ids(recipes: Array) -> Array:
	return recipes.map(func(recipe: Dictionary) -> String: return str(recipe["id"]))


func _point(label: Label, line: int) -> Vector2:
	return label.get_global_transform_with_canvas() * Vector2(4.0, MenuInput.line_height(label) * (float(line) + 0.5))


func _move(label: Label, line: int) -> InputEventMouseMotion:
	var event: InputEventMouseMotion = InputEventMouseMotion.new()
	event.position = _point(label, line)
	event.global_position = event.position
	return event


func _click_at(at: Vector2, button: MouseButton = MOUSE_BUTTON_LEFT) -> InputEventMouseButton:
	var event: InputEventMouseButton = InputEventMouseButton.new()
	event.button_index = button
	event.pressed = true
	event.position = at
	event.global_position = at
	return event


func _wheel(button: MouseButton) -> InputEventMouseButton:
	return _click_at(Vector2(3.0, 3.0), button)


func _on_sound(id: StringName) -> void:
	_heard.append(id)


func _on_crafted(recipe_id: StringName) -> void:
	_made.append(recipe_id)
