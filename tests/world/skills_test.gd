extends GdUnitTestSuite
## Skills in the world (P4b): a monster beaten and a boss are practice at combat, a cell tilled
## at farming, a dish cooked at cooking; a swing, a shot, the hoe and the can cost less at each
## level; a level rising is said once at the top of the screen, with a chime; the pause menu
## shows the three levels; a good cook's dish says what it gives him. Hearts are never touched.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const VILLAGE: String = "res://world/areas/village/village.tscn"
const FARM: String = "res://world/areas/homestead/homestead.tscn"
const HOME: String = "res://world/areas/home/home.tscn"
const FIELD: String = "res://world/areas/south_field/south_field.tscn"
const KEEP: String = "res://world/areas/keep/keep.tscn"
const FRAME: float = 1.0 / 60.0
const TEST_SLOT: int = 976
## The field's north-west corner on the homestead (its first row is worked from the grass above
## it), and open grass in Hearthvale.
const PLOT: Vector2i = Vector2i(22, 17)
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
	get_tree().paused = false
	SaveSystem.erase_slot(TEST_SLOT)
	SaveSystem.current_slot = SaveSystem.GAME_SLOT
	GameState.clear()


func test_a_monster_beaten_is_a_point_of_combat() -> void:
	var field: AreaController = _load(FIELD)
	var slimes: Array[Enemy] = field.enemies().filter(func(enemy: Enemy) -> bool: return enemy.enemy_id == &"slime")
	assert_int(slimes.size()).is_greater_equal(2)
	var hearts: int = GameState.health
	slimes[0].hurt_box.receive(Hit.new(99, Vector2.ZERO, Vector2.ZERO, &"sword"))
	assert_int(int(GameState.skill_points.get(Skills.COMBAT, 0))).is_equal(1)
	slimes[0].hurt_box.receive(Hit.new(99, Vector2.ZERO, Vector2.ZERO, &"sword"))
	assert_int(int(GameState.skill_points[Skills.COMBAT])).override_failure_message("a dead monster is not beaten twice").is_equal(1)
	# A hit that doesn't finish one teaches nothing.
	slimes[1].hurt_box.receive(Hit.new(1, Vector2.ZERO, Vector2.ZERO, &"sword"))
	assert_bool(slimes[1].is_dead()).override_failure_message("a slime takes more than one point of damage").is_false()
	assert_int(int(GameState.skill_points[Skills.COMBAT])).override_failure_message("only a monster beaten").is_equal(1)
	assert_bool(GameState.skill_points.has(Skills.FARMING) or GameState.skill_points.has(Skills.COOKING)).is_false()
	assert_int(GameState.health).override_failure_message("skills never touch hearts").is_equal(hearts)


func test_a_boss_is_worth_ten() -> void:
	GameState.set_flag(StoryGates.KEEP_GATE, true)
	GameState.go_to(&"keep", &"entrance")
	var keep: AreaController = _load(KEEP)
	var bosses: Array[Enemy] = keep.enemies().filter(func(enemy: Enemy) -> bool: return enemy is ArenaBoss)
	assert_int(bosses.size()).override_failure_message("the keep has its Warden").is_equal(1)
	# The Warden falls (the fight itself is tests/world/keep_test.gd's): the area hears it.
	bosses[0].died.emit(bosses[0])
	assert_int(int(GameState.skill_points[Skills.COMBAT])).is_equal(10)
	assert_int(GameState.skill_level(Skills.COMBAT)).is_equal(2)
	assert_str(keep.hud.notice_text()).is_equal("Combat rose to level 2.")
	assert_array(_heard.filter(func(id: StringName) -> bool: return id == &"skill")).has_size(1)


func test_a_swing_and_a_shot_cost_less_as_combat_rises() -> void:
	for item: Array in [[&"wooden_sword", 1], [&"bow", 1], [&"arrow", 20]]:
		GameState.add_item(item[0], item[1])
	var village: AreaController = _load(VILLAGE)
	village.player.motor.place(GRASS)
	village.player.face(Vector2.DOWN)
	# [combat points, what a swing and a shot each cost]
	for case: Array in [[0, 0.5], [10, 0.45], [25, 0.4], [50, 0.35], [90, 0.3]]:
		GameState.skill_points[Skills.COMBAT] = case[0]
		GameState.set_energy(50.0)
		GameState.equip(&"")
		assert_bool(village.use_hand()).override_failure_message("a swing at %d points" % case[0]).is_true()
		assert_float(GameState.energy).override_failure_message("a swing at %d points" % case[0]).is_equal_approx(50.0 - float(case[1]), 0.0001)
		_rest(village)
		GameState.equip(&"bow")
		assert_bool(village.use_item()).override_failure_message("a shot at %d points" % case[0]).is_true()
		assert_float(GameState.energy).override_failure_message("a shot at %d points" % case[0]).is_equal_approx(50.0 - 2.0 * float(case[1]), 0.0001)
		_rest(village)
	# The sword is the sword it was: only its cost in energy changed.
	var stats: Dictionary = CombatRules.weapon_stats(village.player.best_sword())
	assert_dict(stats).is_equal(CombatRules.weapon_stats(DataRegistry.get_item(&"wooden_sword")))


func test_the_hoe_and_the_can_cost_less_as_farming_rises() -> void:
	for item: Array in [[&"hoe", 1], [&"watering_can", 1], [&"water", 10]]:
		GameState.add_item(item[0], item[1])
	var farm: AreaController = _load(FARM)
	# [farming points before the stroke, the plot's column, what the hoe and the can cost]
	var cases: Array = [[0, 0, 2.0, 1.0], [10, 1, 1.8, 0.9], [25, 2, 1.6, 0.8], [50, 3, 1.4, 0.7], [90, 4, 1.2, 0.6]]
	for case: Array in cases:
		GameState.skill_points[Skills.FARMING] = case[0]
		GameState.set_energy(50.0)
		_stand(farm, PLOT + Vector2i(case[1], -1), Vector2.DOWN)
		GameState.equip(&"hoe")
		assert_bool(farm.use_item()).override_failure_message("tilling at %d points" % case[0]).is_true()
		assert_float(GameState.energy).override_failure_message("the hoe at %d points" % case[0]).is_equal_approx(50.0 - float(case[2]), 0.0001)
		_rest(farm)
		GameState.equip(&"watering_can")
		assert_bool(farm.use_item()).override_failure_message("watering at %d points" % case[0]).is_true()
		assert_float(GameState.energy).override_failure_message("the can at %d points" % case[0]).is_equal_approx(50.0 - float(case[2]) - float(case[3]), 0.0001)
		_rest(farm)
	assert_int(GameState.farm().count_of(Farm.WATERED)).is_equal(5)


func test_the_stroke_that_raises_farming_costs_the_old_price_and_is_said_once() -> void:
	GameState.add_item(&"hoe")
	GameState.equip(&"hoe")
	GameState.skill_points[Skills.FARMING] = 9
	var farm: AreaController = _load(FARM)
	var hearts: int = GameState.health
	_stand(farm, PLOT + Vector2i(0, -1), Vector2.DOWN)
	assert_str(farm.hud.notice_text()).is_not_equal("Farming rose to level 2.")
	assert_bool(farm.use_item()).is_true()
	assert_int(GameState.skill_level(Skills.FARMING)).is_equal(2)
	assert_float(GameState.energy).override_failure_message("level 1's price for the stroke that made level 2").is_equal(98.0)
	assert_str(farm.hud.notice_text()).is_equal("Farming rose to level 2.")
	assert_array(_heard.filter(func(id: StringName) -> bool: return id == &"skill")).override_failure_message("one chime").has_size(1)
	_rest(farm)
	_stand(farm, PLOT + Vector2i(1, -1), Vector2.DOWN)
	assert_bool(farm.use_item()).is_true()
	assert_float(GameState.energy).override_failure_message("and the next is cheaper").is_equal_approx(98.0 - 1.8, 0.0001)
	assert_array(_heard.filter(func(id: StringName) -> bool: return id == &"skill")).override_failure_message("not said again").has_size(1)
	assert_int(GameState.health).is_equal(hearts)


func test_five_dishes_at_the_hearth_make_a_better_cook() -> void:
	GameState.add_item(&"turnip", 6)
	var home: AreaController = _load(HOME)
	var hearth: Hearth = home.interactables.get_node(^"Hearth")
	home.player.motor.place(hearth.cell() + Vector2i.DOWN)
	home.player.face(Vector2.UP)
	assert_bool(home.interact()).is_true()
	for dish: int in 5:
		_say(home, "Roast Turnip (1 Turnip)")
		assert_int(int(GameState.skill_points[Skills.COOKING])).override_failure_message("two points a dish").is_equal(2 * (dish + 1))
		_say(home, Cooking.MORE_WORDS if dish < 4 else Cooking.DONE_WORDS)
	assert_bool(home.is_talking()).is_false()
	assert_int(GameState.item_count(&"roast_turnip")).is_equal(5)
	assert_int(GameState.skill_level(Skills.COOKING)).is_equal(2)
	assert_str(home.hud.notice_text()).is_equal("Cooking rose to level 2.")
	assert_array(_heard.filter(func(id: StringName) -> bool: return id == &"skill")).has_size(1)
	# Wanting a dish he hasn't the makings of teaches nothing.
	home.interact()
	_say(home, "Vegetable Stew (1 Potato, 1 Carrot, 1 Turnip)")
	assert_int(int(GameState.skill_points[Skills.COOKING])).is_equal(10)
	_say(home, Cooking.DONE_WORDS)

	# His dishes give a tenth more, and say so; a raw turnip gives what it did.
	assert_str(ItemMenu.describe(DataRegistry.get_item(&"roast_turnip"))).is_equal("Roast Turnip x5 (+24 energy)")
	assert_str(ItemMenu.describe(DataRegistry.get_item(&"turnip"))).is_equal("Turnip x1 (+7 energy)")
	GameState.set_energy(20.0)
	home.hud.item_menu.chosen.emit(&"roast_turnip")
	assert_float(GameState.energy).is_equal_approx(20.0 + 22.0 * 1.1, 0.0001)
	assert_str(home.hud.message_text()).is_equal("Roast Turnip: +24 energy.")
	home.hud.item_menu.chosen.emit(&"turnip")
	assert_float(GameState.energy).is_equal_approx(20.0 + 22.0 * 1.1 + 7.0, 0.0001)


func test_the_pause_menu_shows_every_skills_level() -> void:
	var village: AreaController = _load(VILLAGE)
	assert_array(Array(village.pause_status().split("\n"))).is_equal([
		"Hearts 3   Heart pieces 0 of 4", "Combat 1   Farming 1", "Cooking 1   Mining 1", "Hearthvale", "Time played 0:00",
	])
	GameState.skill_points[Skills.COMBAT] = 30
	GameState.skill_points[Skills.FARMING] = 55
	GameState.skill_points[Skills.COOKING] = 12
	assert_bool(village.open_pause_menu()).is_true()
	var status: Label = village.hud.pause_menu.get_node(^"Panel/Status")
	assert_str(status.text).contains("Combat 3   Farming 4\nCooking 2   Mining 1")
	assert_int(status.text.split("\n").size()).override_failure_message("five lines: all its box holds").is_equal(5)
	assert_float(status.size.y).override_failure_message("and the box is tall enough for five").is_greater_equal(5.0 * status.get_line_height())
	village.hud.pause_menu.resume()
	# In a dungeon the keys' line is there too, and it is still four.
	GameState.set_flag(StoryGates.KEEP_GATE, true)
	GameState.go_to(&"keep", &"entrance")
	var keep: AreaController = _load(KEEP)
	var lines: PackedStringArray = keep.pause_status().split("\n")
	assert_int(lines.size()).is_equal(5)
	assert_str(lines[1]).is_equal("Combat 3   Farming 4")
	assert_str(lines[2]).is_equal("Cooking 2   Mining 1")
	assert_str(lines[3]).contains("Small keys")


func test_the_chime_is_a_sound_the_game_has() -> void:
	assert_bool(Audio.SFX.has(&"skill")).is_true()
	assert_bool(ResourceLoader.exists("res://audio/sfx/skill.wav")).is_true()
	var tool: Dictionary = (load("res://tools/audio/make_audio.gd") as GDScript).get_script_constant_map()
	assert_bool((tool["SFX"] as Array).has("skill")).override_failure_message("made by the audio tool").is_true()


func _stand(area: AreaController, cell: Vector2i, way: Vector2) -> void:
	area.player.motor.place(cell)
	area.player.face(way)


## Lets a swing, a shot or a tool's stroke finish.
func _rest(area: AreaController) -> void:
	for i: int in 60:
		area.player.motor.step(Vector2.ZERO, FRAME)


## Picks the answer that reads `text` in the open conversation.
func _say(area: AreaController, text: String) -> void:
	var box: DialogueBox = area.hud.dialogue
	var index: int = box.shown_options().find(text)
	assert_int(index).override_failure_message("no answer '%s' among %s" % [text, box.shown_options()]).is_greater_equal(0)
	box.move_cursor(index - box.selected)
	box.confirm()


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area


func _on_sound(id: StringName) -> void:
	_heard.append(id)
