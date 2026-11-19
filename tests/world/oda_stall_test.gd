extends GdUnitTestSuite
## Farmer Oda's stall (the Homestead, phase 4, step 4a): it stands beside her by her field, the
## village's one more small re-bake; her conversation's "Have you any animals to sell?" opens
## her list, like Tilda's; an animal is refused without a building for it, and bought, it is in
## its building, and the list says so.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const VILLAGE: String = "res://world/areas/village/village.tscn"
const ASK: String = "Have you any animals to sell?"
## The stall's six cells: an awning over a counter, beside Oda at (15, 31).
const STALL: Rect2i = Rect2i(16, 30, 3, 2)

var _area: Node


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	Quests.refresh()
	GameState.set_time(float(GameState.day_clock().in_day("12:00")))


func after_test() -> void:
	if is_instance_valid(_area):
		_area.free()
	_area = null
	GameState.clear()


func test_the_stall_stands_beside_her() -> void:
	var village: AreaController = _load()
	# The stall is a prop: its picture on the Decor layer, a solid cell under it.
	var layer: TileMapLayer = village.get_node(^"Decor")
	var oda: Villager = village.interactables.get_node(^"FarmerOda")
	assert_that(oda.cell()).is_equal(Vector2i(15, 31))
	var parts: Array[String] = ["stall_nw", "stall_n", "stall_ne", "stall_sw", "stall_s", "stall_se"]
	for y: int in range(STALL.position.y, STALL.end.y):
		for x: int in range(STALL.position.x, STALL.end.x):
			var cell: Vector2i = Vector2i(x, y)
			var part: String = parts[(y - STALL.position.y) * 3 + x - STALL.position.x]
			assert_that(layer.get_cell_atlas_coords(cell)).override_failure_message("%s is %s" % [cell, part]).is_equal(GreyboxTiles.coords(part))
			assert_bool(village.grid.is_solid(cell)).override_failure_message("%s is solid" % cell).is_true()
	# She can still be talked to from the path above her.
	assert_bool(village.grid.is_solid(Vector2i(15, 30))).is_false()


func test_her_conversation_opens_her_list_and_an_animal_needs_its_building() -> void:
	GameState.add_item(GameState.COIN, 200)
	var village: AreaController = _load()
	var counter: ShopMenu = village.hud.shop_menu
	_ask(village)
	assert_bool(counter.is_open()).is_true()
	assert_str(counter.shown_lines()[0]).is_equal("> Chicken: 60 coins")
	assert_array(Array(counter.shown_lines())).is_equal(["> Chicken: 60 coins", "  Sheep: 180 coins", "  Cow: 240 coins"])
	assert_bool(village.is_in_menu()).is_true()
	assert_bool(counter.confirm()).is_false()
	assert_str(counter.note_text()).is_equal("A chicken needs a Coop on your farm.")
	assert_int(GameState.item_count(GameState.COIN)).is_equal(200)
	counter.close()
	# With a coop standing on the farm, the hen is bought and is in it.
	var coop: Dictionary = DataRegistry.get_building(&"coop")
	for cell: Vector2i in Buildings.cells_and_doorstep(coop, Vector2i(32, 10)):
		GameState.clear_debris(&"homestead", cell)
	GameState.add_item(&"coop_kit")
	GameState.set_down_kit(&"homestead", Vector2i(32, 10), &"coop_kit")
	GameState.start_next_day()
	GameState.set_time(float(GameState.day_clock().in_day("12:00")))
	village = _load()
	counter = village.hud.shop_menu
	_ask(village)
	assert_bool(counter.confirm()).is_true()
	assert_str(counter.note_text()).is_equal("Bought: a chicken. It is in your Coop.")
	assert_int(GameState.item_count(GameState.COIN)).is_equal(140)
	assert_array(GameState.animals_in(&"coop")).is_equal([0])
	# A cow wants a barn.
	counter.move_cursor(2)
	assert_bool(counter.confirm()).is_false()
	assert_str(counter.note_text()).is_equal("A cow needs a Barn on your farm.")


func _ask(village: AreaController) -> void:
	Steps.stand_before(village, "FarmerOda")
	assert_bool(village.interact()).is_true()
	var box: DialogueBox = village.hud.dialogue
	var answers: Array = Array(box.shown_options())
	assert_bool(answers.has(ASK)).override_failure_message("her answers: %s" % [answers]).is_true()
	box.move_cursor(answers.find(ASK))
	box.confirm()
	assert_bool(village.is_talking()).is_false()


func _load() -> AreaController:
	_area = Steps.load_area(VILLAGE, _area)
	return _area
