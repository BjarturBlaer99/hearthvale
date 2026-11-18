extends GdUnitTestSuite
## The whole round (P3's "done when", docs/ROADMAP.md): a crop is planted, raised, harvested,
## eaten, cooked and sold, as a player does it: the tools and the first seeds from the farmhouse,
## the plot worked with the left click, the turnips picked with the right, one eaten raw, one
## roasted at the hearth, two sold to Tilda, and her coins spent on seeds for the next round.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const HOME: String = "res://world/areas/home/home.tscn"
const FARM: String = "res://world/areas/homestead/homestead.tscn"
const SHOP: String = "res://world/areas/shop/shop.tscn"
const FRAME: float = 1.0 / 60.0
## The field's north-west corner on the homestead (its clear corner is worked here), and the
## pond's west bank.
const PLOT: Vector2i = Vector2i(22, 17)
const POND_BANK: Vector2i = Vector2i(3, 22)
const TEST_SLOT: int = 980

var _area: Node


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	GameState.set_time(float(GameState.day_clock().in_day("08:00")))
	SaveSystem.current_slot = TEST_SLOT


func after_test() -> void:
	if is_instance_valid(_area):
		_area.free()
	_area = null
	SaveSystem.erase_slot(TEST_SLOT)
	SaveSystem.current_slot = SaveSystem.GAME_SLOT
	Audio.play_music(&"")
	GameState.clear()


func test_a_crop_is_planted_raised_harvested_eaten_cooked_and_sold() -> void:
	# The cottage: the hoe, the can and the first pouch of seeds, by the door.
	var home: AreaController = _load(HOME)
	for found: String in ["Hoe", "WateringCan", "TurnipSeeds"]:
		home.player.motor.place((home.interactables.get_node(NodePath(found)) as ItemPickup).cell())
		assert_bool(home.interact()).override_failure_message("picking up the %s" % found).is_true()
	assert_int(GameState.item_count(&"turnip_seeds")).is_equal(5)
	assert_int(GameState.item_count(&"coin")).override_failure_message("he starts with nothing in his purse").is_equal(0)

	# The plot: five cells tilled and planted with the left click.
	var farm: AreaController = _load(FARM)
	for x: int in 5:
		_face(farm, Vector2i(x, 0))
		GameState.equip(&"hoe")
		assert_bool(farm.use_hand()).override_failure_message("tilling").is_true()
		_rest(farm)
		GameState.equip(&"turnip_seeds")
		assert_bool(farm.use_hand()).override_failure_message("planting").is_true()
		_rest(farm)
	assert_int(GameState.item_count(&"turnip_seeds")).is_equal(0)
	assert_int(GameState.farm().crop_count()).is_equal(5)

	# Three days: the can filled at the pond, every seed watered, and a night's sleep.
	GameState.equip(&"watering_can")
	for day: int in 3:
		assert_bool(GameState.is_crop_ripe(Vector2i(0, 0))).override_failure_message("not ripe before its third morning").is_false()
		if GameState.item_count(&"water") < 5:
			farm.player.motor.place(POND_BANK)
			farm.player.face(Vector2.RIGHT)
			assert_bool(farm.use_hand()).override_failure_message("filling the can at the pond").is_true()
			_rest(farm)
		for x: int in 5:
			_face(farm, Vector2i(x, 0))
			assert_bool(farm.use_hand()).override_failure_message("watering on day %d" % (day + 1)).is_true()
			_rest(farm)
		GameState.start_next_day()
	assert_int(GameState.day).is_equal(4)

	# The harvest: five turnips picked with the right click.
	for x: int in 5:
		_face(farm, Vector2i(x, 0))
		assert_bool(farm.interact()).override_failure_message("picking turnip %d" % x).is_true()
	assert_int(GameState.item_count(&"turnip")).is_equal(5)
	assert_int(GameState.farm().crop_count()).is_equal(0)
	assert_float(GameState.energy).override_failure_message("ten for the hoe and fifteen for the can, and nothing for planting or picking").is_equal(75.0)

	# Eaten: one raw.
	assert_bool(GameState.eat(&"turnip")).is_true()
	assert_float(GameState.energy).is_equal(82.0)

	# Cooked: one roasted at the hearth, and eaten.
	home = _load(HOME)
	var hearth: Hearth = home.interactables.get_node(^"Hearth")
	home.player.motor.place(hearth.cell() + Vector2i.DOWN)
	home.player.face(Vector2.UP)
	assert_bool(home.interact()).is_true()
	var box: DialogueBox = home.hud.dialogue
	var dishes: PackedStringArray = box.shown_options()
	box.move_cursor(dishes.find("Roast Turnip (1 Turnip)") - box.selected)
	box.confirm()
	assert_int(GameState.item_count(&"roast_turnip")).is_equal(1)
	assert_int(GameState.item_count(&"turnip")).is_equal(3)
	while home.is_talking():
		box.move_cursor(box.shown_options().size() - 1 - box.selected)
		box.confirm()
	assert_bool(GameState.eat(&"roast_turnip")).is_true()
	assert_float(GameState.energy).override_failure_message("roasted, it is worth three raw ones").is_equal(100.0)

	# Sold: two to Tilda, through her conversation, and the coins spent on seeds.
	GameState.set_time(float(GameState.day_clock().in_day("10:00")))
	var shop: AreaController = _load(SHOP)
	Steps.stand_before(shop, "Tilda")
	assert_bool(shop.interact()).is_true()
	shop.hud.dialogue.move_cursor(1)
	shop.hud.dialogue.confirm()
	var counter: ShopMenu = shop.hud.shop_menu
	assert_bool(counter.is_open()).is_true()
	assert_str(counter.shown_lines()[0]).is_equal("> Turnip x3: 12 coins each")
	assert_bool(counter.confirm()).is_true()
	assert_bool(counter.confirm()).is_true()
	assert_int(GameState.item_count(&"coin")).override_failure_message("two turnips at twelve").is_equal(24)
	assert_int(GameState.item_count(&"turnip")).is_equal(1)
	counter.switch_mode()
	counter.move_cursor(4)
	assert_str(counter.shown_lines()[4]).is_equal("> Turnip Seeds: 5 coins")
	for i: int in 4:
		assert_bool(counter.confirm()).override_failure_message("buying seed %d" % (i + 1)).is_true()
	assert_bool(counter.confirm()).override_failure_message("four coins buy no fifth seed").is_false()
	counter.close()
	assert_int(GameState.item_count(&"turnip_seeds")).is_equal(4)
	assert_int(GameState.item_count(&"coin")).is_equal(4)

	# The round left him better off than it found him, and never touched a heart.
	assert_int(GameState.health).is_equal(GameState.max_health())
	assert_int(GameState.farm().count_of(Farm.TILLED)).override_failure_message("five cells ready for the next seeds").is_equal(5)
	assert_bool(shop.player.controls_enabled).is_true()


## Puts the hero in the cell below the plot's own cell `cell`, facing up at it.
func _face(area: AreaController, cell: Vector2i) -> void:
	area.player.motor.place(PLOT + cell + Vector2i.DOWN)
	area.player.face(Vector2.UP)


## Lets a stroke finish.
func _rest(area: AreaController) -> void:
	for i: int in 40:
		area.player.motor.step(Vector2.ZERO, FRAME)


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area
