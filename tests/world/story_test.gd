extends GdUnitTestSuite
## The story (H15), all of it data: Elder Bram tells the old tale once the keep is quiet and
## gives thanks at the end; Guard Rolf has his say; five inscriptions stand where the hero will
## pass them, each on open floor, each with its words; and the keep's closing words send the
## hero to Elder Bram.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const VILLAGE: String = "res://world/areas/village/village.tscn"
const KEEP: String = "res://world/areas/keep/keep.tscn"
const CRYPT: String = "res://world/areas/crypt/crypt.tscn"
## [area scene, the inscription's node, its conversation, words it must hold]
const INSCRIPTIONS: Array = [
	[VILLAGE, "ChapelPlaque", &"sign_chapel", ["ALDRIC", "SHADE", "Warden"]],
	[KEEP, "WardenPlaque", &"sign_keep_warden", ["WARDEN", "CHAPEL", "barred"]],
	[CRYPT, "NarthexInscription", &"sign_crypt_narthex", ["Four flames", "No blade"]],
	[CRYPT, "TrenchInscription", &"sign_crypt_trench", ["FALLEN IN", "stone"]],
	[CRYPT, "Epitaph", &"sign_crypt_epitaph", ["ALDRIC", "sword", "all three"]],
]

var _area: Node


func before_test() -> void:
	GameState.clear()
	GameState.new_game()


func after_test() -> void:
	if is_instance_valid(_area):
		_area.free()
	_area = null
	GameState.clear()


func test_elder_bram_speaks_to_each_point_in_the_game() -> void:
	var before: PackedStringArray = _options(&"elder_bram")
	assert_bool(Array(before).has("What lights?")).is_true()
	assert_bool(Array(before).has("The keep is quiet. The Warden fell.")).is_false()
	assert_bool(Array(before).has("The Shade is gone.")).is_false()
	GameState.set_flag(&"keep_warden_beaten", true)
	var after_keep: PackedStringArray = _options(&"elder_bram")
	assert_array(Array(after_keep)).override_failure_message("after the keep: the tale, and nothing stale").is_equal(["The keep is quiet. The Warden fell.", "Goodbye."])
	GameState.set_flag(&"crypt_shade_beaten", true)
	assert_array(Array(_options(&"elder_bram"))).override_failure_message("at the end: thanks").is_equal(["The Shade is gone.", "Goodbye."])


func test_brams_tale_ties_the_keep_to_the_crypt_and_says_what_to_do() -> void:
	GameState.set_flag(&"keep_warden_beaten", true)
	var runner: DialogueRunner = DialogueRunner.new(DataRegistry.get_dialogue(&"elder_bram"), GameState)
	runner.start()
	assert_bool(runner.choose(0)).is_true()
	assert_str(runner.text()).contains("Aldric").contains("Shade").contains("chapel").contains("Warden")
	assert_bool(runner.choose(0)).is_true()
	assert_str(runner.text()).contains("light").contains("sword")
	GameState.set_flag(&"crypt_shade_beaten", true)
	var thanks: DialogueRunner = DialogueRunner.new(DataRegistry.get_dialogue(&"elder_bram"), GameState)
	thanks.start()
	thanks.choose(0)
	assert_str(thanks.text()).contains("Hearthvale can sleep")


func test_guard_rolf_has_a_quiet_watch_at_the_end() -> void:
	GameState.set_flag(&"keep_warden_beaten", true)
	assert_bool(Array(_options(&"guard_rolf")).has("The chapel door stands open.")).is_true()
	assert_bool(Array(_options(&"guard_rolf")).has("The crypt is quiet.")).is_false()
	GameState.set_flag(&"crypt_shade_beaten", true)
	assert_bool(Array(_options(&"guard_rolf")).has("The crypt is quiet.")).is_true()
	assert_bool(Array(_options(&"guard_rolf")).has("The chapel door stands open.")).override_failure_message("old news").is_false()


func test_the_keeps_closing_words_send_the_hero_to_elder_bram() -> void:
	var nodes: Dictionary = DataRegistry.get_dialogue(&"ending_keep")["nodes"]
	assert_str(str(nodes["thanks"]["text"])).contains("chapel").contains("Elder Bram")


func test_five_inscriptions_stand_on_open_floor_and_can_be_read() -> void:
	for case: Array in INSCRIPTIONS:
		var area: AreaController = _load(case[0])
		var sign: Signpost = area.interactables.get_node(NodePath(str(case[1])))
		var where: String = "%s in %s" % [case[1], area.area_id]
		assert_that(sign.dialogue_id).is_equal(case[2])
		assert_bool(area.grid.is_solid(sign.cell())).override_failure_message(where + " stands on open floor").is_false()
		assert_bool(area.terrain.is_pit(sign.cell())).is_false()
		var others: int = 0
		for child: Node in area.interactables.get_children():
			if child != sign and child.has_method(&"covers") and child.call(&"covers", sign.cell()):
				others += 1
		assert_int(others).override_failure_message(where + " has its cell to itself").is_equal(0)
		# It can be read from at least one side.
		var read: bool = false
		for side: Vector2i in [Vector2i.DOWN, Vector2i.UP, Vector2i.LEFT, Vector2i.RIGHT]:
			var from: Vector2i = sign.cell() + side
			if area.grid.is_solid(from) or area.terrain.is_occupied(from) or area.terrain.is_pit(from):
				continue
			area.player.motor.place(from)
			area.player.face(Vector2(-side))
			if area.interact():
				read = true
				break
		assert_bool(read).override_failure_message(where + " can be read").is_true()
		for word: String in case[3]:
			assert_str(area.hud.dialogue.shown_text()).override_failure_message("%s says '%s'" % [where, word]).contains(word)
		area.hud.dialogue.confirm()
		assert_bool(area.is_talking()).is_false()


func _options(dialogue_id: StringName) -> PackedStringArray:
	var runner: DialogueRunner = DialogueRunner.new(DataRegistry.get_dialogue(dialogue_id), GameState)
	runner.start()
	return runner.option_texts()


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area
