extends GdUnitTestSuite
## Feel & sound (H10): every sound the game asks for is baked by the tool; each area plays the
## tune for its kind of place; every action asks for its sound (tests listen to
## EventBus.sound); the Warden brings its own tune and gives the area's back; landed blows
## freeze the game a moment and blasts shake the camera; volumes set the buses and are kept.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const FIELD: String = "res://world/areas/south_field/south_field.tscn"
const KEEP: String = "res://world/areas/keep/keep.tscn"
const VILLAGE: String = "res://world/areas/village/village.tscn"
const TITLE: String = "res://ui/title_screen.tscn"
const TEST_SETTINGS: String = "user://test_sound_settings.cfg"
const FRAME: float = 1.0 / 60.0
## Each area and the tune it should play.
const TUNES: Dictionary = {
	&"village": &"village", &"elder_house": &"village", &"weaver_house": &"village", &"shop": &"village",
	&"south_field": &"countryside", &"north_fields": &"countryside", &"old_wood": &"countryside",
	&"ruin_cellar": &"dungeon", &"cistern": &"dungeon", &"keep": &"dungeon",
}

var _area: Node
var _heard: Array[StringName] = []


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	_heard.clear()
	EventBus.sound.connect(_on_sound)
	Audio.play_music(&"")
	Settings.path = TEST_SETTINGS
	Settings.load_settings()


func after_test() -> void:
	EventBus.sound.disconnect(_on_sound)
	if is_instance_valid(_area):
		_area.free()
	_area = null
	Engine.time_scale = 1.0
	if FileAccess.file_exists(TEST_SETTINGS):
		DirAccess.remove_absolute(TEST_SETTINGS)
	Settings.path = Settings.PATH
	Settings.load_settings()
	Audio.apply_volumes()
	Audio.play_music(&"")
	GameState.clear()


func test_every_sound_and_tune_the_game_uses_is_baked_by_the_tool() -> void:
	var tool: Dictionary = (load("res://tools/audio/make_audio.gd") as GDScript).get_script_constant_map()
	assert_array(Array(tool["SFX"])).is_equal(Array(Audio.SFX).map(func(id: StringName) -> String: return String(id)))
	for id: StringName in Audio.SFX:
		var stream: AudioStreamWAV = load("%s/%s.wav" % [Audio.SFX_DIR, id]) as AudioStreamWAV
		assert_object(stream).override_failure_message("audio/sfx/%s.wav" % id).is_not_null()
		assert_float(stream.get_length()).override_failure_message("%s is a short sound" % id).is_between(0.02, 2.0)
	var songs: Array = (tool["SONGS"] as Dictionary).keys()
	songs.sort()
	var tunes: Array = Array(Audio.MUSIC).map(func(id: StringName) -> String: return String(id))
	tunes.sort()
	assert_array(songs).is_equal(tunes)
	for id: StringName in Audio.MUSIC:
		var tune: AudioStreamWAV = load("%s/%s.wav" % [Audio.MUSIC_DIR, id]) as AudioStreamWAV
		assert_object(tune).override_failure_message("audio/music/%s.wav" % id).is_not_null()
		assert_float(tune.get_length()).override_failure_message("%s is a loop of some length" % id).is_greater(10.0)


func test_each_area_plays_the_tune_for_its_kind_of_place() -> void:
	for area_id: StringName in TUNES:
		_load(WorldPaths.scene_for(area_id))
		assert_that(Audio.current_music).override_failure_message(String(area_id)).is_equal(TUNES[area_id])
	_area.free()
	var title: Node = (load(TITLE) as PackedScene).instantiate()
	get_tree().root.add_child(title)
	_area = title
	assert_that(Audio.current_music).override_failure_message("the title").is_equal(&"village")


func test_fighting_sounds_and_feels_weighty() -> void:
	GameState.add_item(&"wooden_sword")
	var field: AreaController = _load(FIELD)
	var slime: Enemy = field.interactables.get_node(^"SlimeA")
	assert_bool(field.player.swing()).is_true()
	assert_array(_heard).contains([&"sword"])
	slime.hurt_box.receive(Hit.new(1, Vector2.ZERO, Vector2.ZERO, &"sword"))
	assert_array(_heard).contains([&"hit"])
	assert_bool(field.is_hit_stopped()).override_failure_message("a landed blow freezes the game a moment").is_true()
	assert_float(Engine.time_scale).is_equal(AreaController.HIT_STOP_SCALE)
	assert_bool(_bursts(field) > 0).override_failure_message("sparks fly").is_true()
	for i: int in roundi(0.5 / FRAME):
		slime.step(FRAME)
	slime.hurt_box.receive(Hit.new(5, Vector2.ZERO, Vector2.ZERO, &"sword"))
	assert_bool(slime.is_dead()).is_true()
	assert_array(_heard).contains([&"enemy_die"])
	field.player.hurt_box.receive(Hit.new(1, Vector2(16, 0), Vector2.ZERO))
	assert_array(_heard).contains([&"hurt"])
	assert_bool(field.player.is_shaking()).override_failure_message("getting hurt shakes the view").is_true()
	field = _load(FIELD)
	assert_float(Engine.time_scale).override_failure_message("leaving an area ends any freeze").is_equal(1.0)


func test_items_sound_when_used_and_say_no_when_they_cant_be() -> void:
	GameState.add_item(&"bow")
	GameState.add_item(&"arrow", 1)
	GameState.add_item(&"bomb", 1)
	var field: AreaController = _load(FIELD)
	field.player.motor.place(Vector2i(20, 8))
	field.player.face(Vector2.DOWN)
	GameState.equip(&"bow")
	assert_bool(field.use_item()).is_true()
	assert_array(_heard).contains([&"arrow"])
	_play(field, 0.6)
	assert_bool(field.use_item()).override_failure_message("out of arrows").is_false()
	assert_array(_heard).contains([&"nope"])
	GameState.equip(&"bomb")
	assert_bool(field.use_item()).is_true()
	assert_array(_heard).contains([&"bomb_set"])
	var bomb: Bomb = field.last_projectile
	for i: int in roundi(2.2 / FRAME):
		if not bomb.tick(FRAME):
			break
	assert_array(_heard).contains([&"bomb"])
	assert_bool(field.player.is_shaking()).override_failure_message("a blast shakes the view").is_true()


func test_pickups_and_treasure_sound() -> void:
	var village: AreaController = _load(VILLAGE)
	var sword: ItemPickup = village.interactables.get_node(^"WoodenSword")
	village.player.motor.place(sword.cell())
	assert_bool(village.interact()).is_true()
	assert_array(_heard).contains([&"item_get"])
	var heart: HeartPickup = HeartPickup.new()
	var coin: ItemDrop = ItemDrop.new()
	heart.position = Vector2(30, 20) * GridBody.TILE
	coin.position = Vector2(31, 20) * GridBody.TILE
	village.interactables.add_child(heart)
	village.interactables.add_child(coin)
	assert_bool(heart.collect() and coin.collect()).is_true()
	assert_array(_heard).contains([&"heart", &"coin"])
	GameState.set_flag(&"keep_warden_beaten", true)
	var keep: AreaController = _load(KEEP)
	_heard.clear()
	_face(keep, Vector2i(2, 36), Vector2.UP)
	assert_bool(keep.interact()).override_failure_message("the guard room's chest").is_true()
	assert_array(_heard).contains([&"item_get"])
	var container: HeartContainer = keep.interactables.get_node(^"HeartContainer")
	keep.player.motor.place(container.cell())
	keep.player.sync_from_motor()
	keep.collect_pickups()
	assert_array(_heard).contains([&"heart_get"])


func test_doors_and_puzzles_sound() -> void:
	var keep: AreaController = _load(KEEP)
	_face(keep, Vector2i(22, 34), Vector2.UP)
	keep.interact()
	assert_array(_heard).override_failure_message("locked, no key").contains([&"nope"])
	GameState.set_flag(DungeonState.keys_flag(&"keep"), 1)
	keep.interact()
	assert_array(_heard).contains([&"door"])
	_face(keep, Vector2i(3, 24), Vector2.UP)
	keep.update_plates()
	keep.update_plates()
	assert_int(_heard.count(&"plate")).override_failure_message("one click, not one a frame").is_equal(1)
	var block: PushBlock = keep.interactables.get_node(^"PlateBlock")
	assert_bool(block.try_push(Vector2i.RIGHT, keep.terrain, keep.room_size)).is_true()
	assert_array(_heard).contains([&"push"])
	var crystal: CrystalSwitch = keep.interactables.get_node(^"ArmouryCrystal")
	_face(keep, Vector2i(11, 15), Vector2.UP)
	crystal.hurt_box.receive(Hit.new(2, Vector2.ZERO, Vector2.ZERO, &"arrow"))
	assert_array(_heard).contains([&"crystal", &"solved"])
	var wall: DungeonDoor = keep.interactables.get_node(^"StoreWall")
	wall._blast_box.receive(Hit.new(4, Vector2.ZERO, Vector2.ZERO, &"bomb"))
	assert_array(_heard).override_failure_message("a cracked wall gives way to a secret").contains([&"secret"])


func test_the_warden_sounds_and_brings_its_own_tune() -> void:
	var keep: AreaController = _load(KEEP)
	var warden: Boss = keep.interactables.get_node(^"Warden")
	warden.hit_box.deactivate()
	assert_that(Audio.current_music).is_equal(&"dungeon")
	_face(keep, Vector2i(22, 20), Vector2.UP)
	_step_until(warden, WardenBrain.GUARD, 2.0)
	assert_that(Audio.current_music).override_failure_message("the fight's own tune").is_equal(&"boss")
	for i: int in roundi(0.6 / FRAME):
		warden.step(FRAME)
	assert_array(_heard).contains([&"stomp"])
	_step_until(warden, WardenBrain.GAZE, 6.0)
	assert_array(_heard).contains([&"gaze"])
	warden.hurt_box.receive(Hit.new(2, Vector2.ZERO, Vector2.ZERO, &"sword"))
	assert_array(_heard).contains([&"clink"])
	warden.hurt_box.receive(Hit.new(2, Vector2.ZERO, Vector2.ZERO, &"arrow"))
	assert_array(_heard).contains([&"stun"])
	_face(keep, Vector2i(22, 25), Vector2.UP)
	warden.step(FRAME)
	assert_that(Audio.current_music).override_failure_message("calm again when the hero leaves").is_equal(&"dungeon")
	_face(keep, Vector2i(22, 20), Vector2.UP)
	_step_until(warden, WardenBrain.GAZE, 8.0)
	warden.hurt_box.receive(Hit.new(2, Vector2.ZERO, Vector2.ZERO, &"arrow"))
	warden.hurt_box.receive(Hit.new(99, Vector2.ZERO, Vector2.ZERO, &"sword"))
	assert_bool(warden.is_dead()).is_true()
	assert_array(_heard).contains([&"boss_die"])
	assert_that(Audio.current_music).is_equal(&"dungeon")


func test_menus_sound() -> void:
	var village: AreaController = _load(VILLAGE)
	village.open_pause_menu()
	assert_array(_heard).contains([&"pause"])
	village.hud.pause_menu.move_cursor(1)
	assert_array(_heard).contains([&"menu_move"])
	village.hud.pause_menu.choose(PauseMenu.RESUME)
	assert_array(_heard).contains([&"menu_select"])
	assert_bool(get_tree().paused).is_false()


func test_volumes_set_the_buses_mute_at_zero_and_are_kept() -> void:
	var music: int = AudioServer.get_bus_index(Audio.MUSIC_BUS)
	var effects: int = AudioServer.get_bus_index(Audio.SFX_BUS)
	assert_int(music).is_not_equal(-1)
	assert_int(effects).is_not_equal(-1)
	Settings.change(SettingsData.MUSIC_VOLUME, -1)
	assert_float(AudioServer.get_bus_volume_db(music)).is_equal_approx(Audio.volume_db(6), 0.01)
	for i: int in 6:
		Settings.change(SettingsData.MUSIC_VOLUME, -1)
	assert_int(Settings.data.music_volume).is_equal(0)
	assert_bool(AudioServer.is_bus_mute(music)).override_failure_message("silent means silent").is_true()
	Settings.change(SettingsData.SFX_VOLUME, 1)
	assert_float(AudioServer.get_bus_volume_db(effects)).is_equal_approx(Audio.volume_db(8), 0.01)
	Settings.load_settings()
	assert_int(Settings.data.music_volume).override_failure_message("kept on disk").is_equal(0)
	assert_int(Settings.data.sfx_volume).is_equal(8)


func _on_sound(id: StringName) -> void:
	_heard.append(id)


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area


func _face(area: AreaController, cell: Vector2i, direction: Vector2) -> void:
	area.player.motor.place(cell)
	area.player.face(direction)
	area.player.sync_from_motor()
	area.update_room()


func _bursts(area: AreaController) -> int:
	var count: int = 0
	for child: Node in area.interactables.get_children():
		if child is Burst:
			count += 1
	return count


func _play(area: AreaController, seconds: float) -> void:
	for i: int in roundi(seconds / FRAME):
		area.player.motor.step(Vector2.ZERO, FRAME)
		area.player.sync_from_motor()
		for child: Node in area.interactables.get_children():
			if child is Arrow:
				(child as Arrow).fly(FRAME)


func _step_until(boss: Boss, state: StringName, seconds: float) -> void:
	for i: int in roundi(seconds / FRAME):
		boss.step(FRAME)
		if boss.brain.state == state:
			return
	assert_that(boss.brain.state).override_failure_message("waited for %s" % state).is_equal(state)
