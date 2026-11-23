extends GdUnitTestSuite
## Hours and night in the world (P2e): the shop's door is shut outside its hours; villagers who
## stand outdoors go home at eight and are back at six; monsters met outdoors at night are
## tougher; house windows are lit with the lamps; the night has its own tune out of doors; and
## eating, collapsing and the morning each have a sound.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")
const DataRegistryScript: GDScript = preload("res://autoload/data_registry.gd")

const VILLAGE: String = "res://world/areas/village/village.tscn"
const SHOP: String = "res://world/areas/shop/shop.tscn"
const HOME: String = "res://world/areas/home/home.tscn"
const ELDER_HOUSE: String = "res://world/areas/elder_house/elder_house.tscn"
const FIELD: String = "res://world/areas/south_field/south_field.tscn"
const NORTH_FIELDS: String = "res://world/areas/north_fields/north_fields.tscn"
const CELLAR: String = "res://world/areas/ruin_cellar/ruin_cellar.tscn"
const TEST_SLOT: int = 985
const FRAME: float = 1.0 / 60.0
const SHOP_DOOR: Vector2i = Vector2i(8, 24)
const SHUT: String = "Tilda's shop is shut. She opens at 08:00 and closes at 18:00."
const OUTDOOR_VILLAGERS: Array[String] = ["FarmerOda", "Pip", "GuardRolf"]

var _area: Node
var _heard: Array[StringName] = []


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	SaveSystem.current_slot = TEST_SLOT
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


func test_hours_and_the_night_are_data_and_bad_ones_are_reported() -> void:
	for id: StringName in [DataRegistry.RULES_HOURS, DataRegistry.RULES_NIGHT]:
		assert_bool(DataRegistry.has_entry(&"rules", id)).override_failure_message("data/rules/%s.json is loaded" % id).is_true()
	assert_array(Array(Hours.problems(DataRegistry.get_rules(DataRegistry.RULES_HOURS)))).is_empty()
	assert_array(Array(NightRules.problems(DataRegistry.get_rules(DataRegistry.RULES_NIGHT)))).is_empty()
	var registry: Node = auto_free(DataRegistryScript.new())
	var errors: String = "\n".join(registry.load_all("res://tests/fixtures/bad_rules"))
	assert_str(errors).contains("rules 'hours': 'outdoors' must have a 'from' and a 'to', each a time of day.")
	assert_str(errors).contains("rules 'hours': place 'shop' must have a 'from' and a 'to', each a time of day.")
	assert_str(errors).contains("rules 'hours': place 'inn': 'shut' must be the words said at its door.")
	assert_str(errors).contains("rules 'night': 'health' must be a number above 0")
	assert_str(errors).contains("rules 'night': 'coin_drops' must be a number above 0")


func test_the_shops_door_is_shut_outside_its_hours() -> void:
	_at("19:00")
	var village: AreaController = _load(VILLAGE)
	var door: AreaExit = village.interactables.get_node(^"ShopDoor")
	assert_that(door.hours).is_equal(&"shop")
	assert_that(door.cell()).is_equal(SHOP_DOOR)
	# (The old cottage's door keeps the hours of a place that is never open: tests/world/home_move_test.gd.)
	var cottage: AreaExit = village.interactables.get_node(^"HomeDoor")
	assert_array(village.doors_with_hours()).override_failure_message("only the shop keeps hours, and the cottage is locked").contains_exactly_in_any_order([door, cottage])
	assert_bool(village.is_shut(door)).is_true()
	assert_bool(village.terrain.is_occupied(SHOP_DOOR)).override_failure_message("a shut door is solid").is_true()
	# He walks up to it: he is told, and stands before it.
	village.player.motor.place(SHOP_DOOR + Vector2i(0, 2))
	village.player.face(Vector2.UP)
	assert_str(Steps.walk_until_travel(village, Vector2.UP, 90)).override_failure_message("he doesn't get in").is_equal("")
	assert_that(village.player.motor.cell).override_failure_message("before the door, not in it").is_equal(SHOP_DOOR + Vector2i.DOWN)
	assert_str(village.hud.message_text()).is_equal(SHUT)
	assert_array(_heard).contains([&"nope"])
	assert_bool(village.player.controls_enabled).is_true()
	# Trying it says so again; walking past it says nothing.
	village.hud.show_message("-")
	assert_bool(village.interact()).is_true()
	assert_str(village.hud.message_text()).is_equal(SHUT)
	village.hud.show_message("-")
	village.player.motor.place(SHOP_DOOR + Vector2i(-1, 1))
	village.player.face(Vector2.RIGHT)
	for i: int in 30:
		village.player.motor.step(Vector2.RIGHT, FRAME)
	assert_bool(village.player.motor.cell.x >= SHOP_DOOR.x).override_failure_message("he has passed the door").is_true()
	assert_str(village.hud.message_text()).is_equal("-")
	# Nothing takes him through a shut door.
	var travelled: Array[String] = []
	village.travel = func(path: String) -> void: travelled.append(path)
	village.take_exit(door)
	assert_array(travelled).is_empty()
	assert_bool(village.player.controls_enabled).is_true()


func test_the_shop_opens_at_eight_and_shuts_at_six() -> void:
	_at("07:59")
	var village: AreaController = _load(VILLAGE)
	assert_bool(village.terrain.is_occupied(SHOP_DOOR)).override_failure_message("07:59").is_true()
	_at("08:00")
	assert_bool(village.terrain.is_occupied(SHOP_DOOR)).override_failure_message("08:00").is_false()
	_at("17:59")
	assert_bool(village.terrain.is_occupied(SHOP_DOOR)).override_failure_message("17:59").is_false()
	_at("18:00")
	assert_bool(village.terrain.is_occupied(SHOP_DOOR)).override_failure_message("18:00").is_true()
	GameState.start_next_day()
	assert_bool(village.terrain.is_occupied(SHOP_DOOR)).override_failure_message("06:00 the next day").is_true()
	_at("10:00")
	village.player.motor.place(SHOP_DOOR + Vector2i(0, 2))
	village.player.face(Vector2.UP)
	assert_str(Steps.walk_until_travel(village, Vector2.UP, 90)).override_failure_message("open, the door takes him in").is_equal(SHOP)
	assert_array(_heard).not_contains([&"nope"])
	# From inside, the shop can always be left; Tilda keeps no hours of her own.
	_at("19:00")
	var shop: AreaController = _load(SHOP)
	assert_array(shop.doors_with_hours()).is_empty()
	assert_bool((shop.interactables.get_node(^"Tilda") as Villager).present).is_true()
	var travelled: Array[String] = []
	shop.travel = func(path: String) -> void: travelled.append(path)
	shop.take_exit(shop.interactables.get_node(^"Doormat"))
	assert_array(travelled).is_equal([VILLAGE])


func test_villagers_who_stand_outdoors_go_home_at_eight_and_are_back_at_six() -> void:
	_at("19:59")
	var village: AreaController = _load(VILLAGE)
	assert_int(_villagers(village).size()).is_equal(OUTDOOR_VILLAGERS.size())
	for villager: Villager in _villagers(village):
		assert_bool(villager.present and villager.visible).override_failure_message("%s is out at 19:59" % villager.name).is_true()
		assert_bool(village.terrain.is_occupied(villager.cell())).is_true()
	var pip: Villager = Steps.stand_before(village, "Pip") as Villager
	assert_object(village.talkable_in_front()).is_same(pip)
	_at("20:00")
	for villager: Villager in _villagers(village):
		assert_bool(villager.present or villager.visible).override_failure_message("%s has gone home" % villager.name).is_false()
		assert_bool(village.terrain.is_occupied(villager.cell())).override_failure_message("%s's cell is free" % villager.name).is_false()
	assert_object(village.talkable_in_front()).override_failure_message("nobody to talk to").is_null()
	assert_bool(village.interact()).is_false()
	# In the morning they are back, but nobody comes back onto the hero.
	village.player.motor.place(pip.cell())
	GameState.start_next_day()
	for villager: Villager in _villagers(village):
		assert_bool(villager.present).override_failure_message("%s at 06:00, the hero in Pip's place" % villager.name).is_equal(villager != pip)
	village.player.motor.place(pip.cell() + Vector2i.DOWN)
	village.player.face(Vector2.UP)
	_at("06:01")
	assert_bool(pip.present and pip.visible).is_true()
	assert_bool(village.terrain.is_occupied(pip.cell())).is_true()
	assert_object(village.talkable_in_front()).is_same(pip)


func test_nobody_leaves_in_the_middle_of_a_conversation() -> void:
	_at("19:59")
	var village: AreaController = _load(VILLAGE)
	var pip: Villager = Steps.stand_before(village, "Pip") as Villager
	assert_bool(village.interact()).is_true()
	assert_bool(village.is_talking()).is_true()
	_at("20:00")
	assert_bool(pip.present).override_failure_message("he stays to finish what he was saying").is_true()
	for i: int in 40:
		if not village.is_talking():
			break
		village.hud.dialogue.confirm()
	assert_bool(village.is_talking()).is_false()
	_at("20:01")
	assert_bool(pip.present).is_false()


func test_villagers_are_away_when_he_arrives_at_night_but_indoors_keeps_no_hours() -> void:
	_at("23:00")
	for path: String in [VILLAGE, NORTH_FIELDS]:
		var outdoors: AreaController = _load(path)
		assert_int(_villagers(outdoors).size()).override_failure_message(path).is_greater(0)
		for villager: Villager in _villagers(outdoors):
			assert_bool(villager.present or villager.visible).override_failure_message("%s at 23:00" % villager.name).is_false()
			assert_bool(outdoors.terrain.is_occupied(villager.cell())).is_false()
	for path: String in [ELDER_HOUSE, SHOP]:
		var indoors: AreaController = _load(path)
		assert_int(_villagers(indoors).size()).override_failure_message(path).is_greater(0)
		for villager: Villager in _villagers(indoors):
			assert_bool(villager.present and villager.visible).override_failure_message("%s is at home at 23:00" % villager.name).is_true()
			assert_bool(indoors.terrain.is_occupied(villager.cell())).is_true()


func test_monsters_met_outdoors_at_night_are_tougher() -> void:
	# By day they are as their data says, and stay so if night falls while he is there.
	var field: AreaController = _load(FIELD)
	assert_int(field.enemies().size()).is_greater(3)
	_at("22:00")
	for enemy: Enemy in field.enemies():
		var by_day: Dictionary = DataRegistry.get_enemy(enemy.enemy_id)
		assert_bool(enemy.night).override_failure_message("%s was met by day" % enemy.name).is_false()
		assert_int(enemy.brain.max_health).is_equal(int(by_day["health"]))
		assert_float(enemy.brain.speed).is_equal(float(by_day["speed"]))
		assert_object(enemy.material).is_null()
		assert_that(enemy.modulate).is_equal(Color.WHITE)
	# Met at night: more health, faster, further sight, coins likelier; and they show in the dark.
	field = _load(FIELD)
	assert_bool(field.is_night_outdoors()).is_true()
	for enemy: Enemy in field.enemies():
		var by_day: Dictionary = DataRegistry.get_enemy(enemy.enemy_id)
		assert_bool(enemy.night).override_failure_message("%s is met at night" % enemy.name).is_true()
		assert_int(enemy.brain.max_health).override_failure_message("%s's health" % enemy.name).is_equal(ceili(float(by_day["health"]) * 1.5))
		assert_int(enemy.brain.health).is_equal(enemy.brain.max_health)
		assert_float(enemy.brain.speed).is_equal_approx(float(by_day["speed"]) * 1.15, 0.001)
		assert_float(enemy.brain.sight).is_equal_approx(float(by_day["sight"]) * 1.3, 0.001)
		assert_int(enemy.hit_box.damage).override_failure_message("it hits no harder").is_equal(int(by_day["contact_damage"]))
		assert_that(enemy.modulate).is_equal(Enemy.NIGHT_TINT)
		assert_int((enemy.material as CanvasItemMaterial).light_mode).override_failure_message("drawn whatever the hour's light").is_equal(CanvasItemMaterial.LIGHT_MODE_UNSHADED)
	var slime: Enemy = field.enemies()[0]
	assert_that(slime.enemy_id).is_equal(&"slime")
	assert_float(float(slime.data["drops"][1]["weight"])).override_failure_message("coins twice as likely").is_equal(4.0)
	assert_float(float(DataRegistry.get_enemy(&"slime")["drops"][1]["weight"])).override_failure_message("the data is left alone").is_equal(2.0)
	# They stay as they were met until he leaves.
	GameState.start_next_day()
	assert_bool(field.is_night_outdoors()).is_false()
	assert_bool(slime.night).is_true()
	assert_int(slime.brain.max_health).is_equal(3)


func test_the_night_changes_nothing_under_the_ground() -> void:
	_at("23:00")
	var cellar: AreaController = _load(CELLAR)
	assert_bool(cellar.is_night_outdoors()).is_false()
	assert_int(cellar.enemies().size()).is_greater(0)
	for enemy: Enemy in cellar.enemies():
		assert_bool(enemy.night).override_failure_message(String(enemy.name)).is_false()
		# The cellar's own numbers (data/rules/dungeon.json), and nothing of the night's on top.
		var underground: Dictionary = DungeonRules.new(DataRegistry.get_rules(DataRegistry.RULES_DUNGEON)).strengthen(DataRegistry.get_enemy(enemy.enemy_id), &"ruin_cellar")
		assert_int(enemy.brain.max_health).is_equal(int(underground["health"]))
		assert_object(enemy.material).is_null()


func test_house_windows_are_lit_with_the_lamps() -> void:
	_at("12:00")
	var village: AreaController = _load(VILLAGE)
	var glow: WindowGlow = village.windows
	assert_object(glow).is_not_null()
	var tiles: int = 0
	for kind: String in WindowGlow.GLASS:
		tiles += village.height_layer.get_used_cells_by_id(GreyboxTiles.SOURCE_ID, GreyboxTiles.coords(kind)).size()
	assert_int(tiles).override_failure_message("the village's houses have windows").is_greater(10)
	assert_int(glow.windows.size()).override_failure_message("a pane of light a window").is_equal(tiles)
	var kinds: Array = WindowGlow.GLASS.keys().map(func(kind: String) -> Vector2i: return GreyboxTiles.coords(kind))
	for glass: Rect2 in glow.windows:
		var cell: Vector2i = Vector2i(glass.position) / GreyboxTiles.TILE_SIZE
		assert_bool(kinds.has(village.height_layer.get_cell_atlas_coords(cell))).override_failure_message("glass at %s is in a window" % cell).is_true()
		assert_bool(Rect2(Vector2(cell * GreyboxTiles.TILE_SIZE), Vector2(GreyboxTiles.TILE_SIZE, GreyboxTiles.TILE_SIZE)).encloses(glass)).is_true()
	# Over the walls and what is painted on them; under what stands in front of a wall.
	for under: Node in [village.height_layer, village.water, village.reflections, village.relief]:
		if under != null:
			assert_int(glow.get_index()).override_failure_message("over %s" % under.name).is_greater(under.get_index())
	for over: Node in [village.get_node(^"Decor"), village.interactables, village.player, village.scenery]:
		assert_int(glow.get_index()).override_failure_message("under %s" % over.name).is_less(over.get_index())
	assert_int((glow.material as CanvasItemMaterial).light_mode).override_failure_message("the night doesn't dim them").is_equal(CanvasItemMaterial.LIGHT_MODE_UNSHADED)
	var lit: Dictionary = {"12:00": false, "18:29": false, "18:30": true, "23:00": true, "01:30": true}
	for time: String in lit:
		_at(time)
		village._process(FRAME)
		assert_bool(glow.lit).override_failure_message("windows at %s" % time).is_equal(lit[time])
		assert_bool(glow.lit).override_failure_message("with the lamps at %s" % time).is_equal(GameState.day_clock().lamps_lit(GameState.minute))
	GameState.start_next_day()
	village._process(FRAME)
	assert_bool(glow.lit).override_failure_message("still lit at 06:00").is_true()
	_at("06:30")
	village._process(FRAME)
	assert_bool(glow.lit).override_failure_message("out by 06:30").is_false()
	# Where there are no houses there is nothing to light.
	assert_object(_load(FIELD).windows).is_null()


func test_the_night_has_its_own_tune_out_of_doors() -> void:
	assert_bool(Audio.MUSIC.has(AreaController.NIGHT_TUNE)).is_true()
	_at("19:59")
	var village: AreaController = _load(VILLAGE)
	assert_that(village.tune_now()).is_equal(&"village")
	assert_that(Audio.current_music).is_equal(&"village")
	_at("20:00")
	assert_that(Audio.current_music).override_failure_message("night falls at eight").is_equal(&"night")
	GameState.start_next_day()
	assert_that(Audio.current_music).override_failure_message("the morning brings the village's tune back").is_equal(&"village")
	# A tune something else asked for is left to play until the area's own changes.
	Audio.play_music(&"boss")
	_at("12:00")
	assert_that(Audio.current_music).is_equal(&"boss")
	_at("23:00")
	assert_that(Audio.current_music).is_equal(&"night")
	# Arriving at night: the night's tune in the fields, the house's own indoors, the dungeon's below.
	_load(FIELD)
	assert_that(Audio.current_music).override_failure_message("the fields at 23:00").is_equal(&"night")
	_load(SHOP)
	assert_that(Audio.current_music).override_failure_message("indoors at 23:00").is_equal(&"village")
	_load(CELLAR)
	assert_that(Audio.current_music).override_failure_message("a dungeon at 23:00").is_equal(&"dungeon")


func test_eating_and_collapsing_have_sounds_of_their_own() -> void:
	GameState.add_item(&"wooden_sword")
	GameState.add_item(&"bread")
	GameState.set_energy(40.0)
	var village: AreaController = _load(VILLAGE)
	village.travel = func(_path: String) -> void: pass
	assert_bool(village.open_item_menu()).is_true()
	_heard.clear()
	village.hud.item_menu.confirm()
	assert_float(GameState.energy).override_failure_message("he ate the bread").is_equal(70.0)
	assert_array(_heard).contains([&"eat"])
	assert_array(_heard).override_failure_message("not the sound of a heart picked up").not_contains([&"heart"])
	_heard.clear()
	GameState.set_energy(0.4)
	assert_bool(village.player.swing()).is_true()
	village._process(FRAME)
	assert_bool(village.is_collapsing()).is_true()
	assert_array(_heard).contains([&"collapse"])
	assert_int(_heard.count(&"collapse")).override_failure_message("once").is_equal(1)


func test_the_cock_crows_when_a_new_day_begins() -> void:
	var home: AreaController = _load(HOME)
	var bed: Bed = home.interactables.get_node(^"Bed")
	home.player.motor.place(bed.cell() + Vector2i.RIGHT)
	home.player.face(Vector2.LEFT)
	_at("21:00")
	_heard.clear()
	assert_bool(home.interact()).is_true()
	home.hud.dialogue.confirm()
	assert_int(GameState.day).is_equal(2)
	assert_array(_heard).contains([&"morning"])
	# And when he wakes at home after a day that ran out on him.
	_heard.clear()
	GameState.arrival_notice = AreaController.WOKE_LATE_WORDS
	home = _load(HOME)
	assert_array(_heard).contains([&"morning"])
	assert_str(home.hud.message_text()).is_equal(AreaController.WOKE_LATE_WORDS)
	for id: StringName in [&"eat", &"morning", &"collapse"]:
		assert_bool(Audio.SFX.has(id)).override_failure_message("%s is a sound the game has" % id).is_true()


func _at(time: String) -> void:
	GameState.set_time(float(GameState.day_clock().in_day(time)))


func _villagers(area: AreaController) -> Array[Villager]:
	var out: Array[Villager] = []
	for child: Node in area.interactables.get_children():
		if child is Villager:
			out.append(child as Villager)
	return out


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area


func _on_sound(id: StringName) -> void:
	_heard.append(id)
