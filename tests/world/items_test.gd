extends GdUnitTestSuite
## Items & weapons (H4): the Bow lies in the South Field ruin and goes on the item button when
## picked up; arrows and bombs hurt enemies and run out; Tilda's shop sells them for coins
## (only what you can afford and carry); the item menu equips, and the choice survives a save.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const FIELD: String = "res://world/areas/south_field/south_field.tscn"
const SHOP: String = "res://world/areas/shop/shop.tscn"
const VILLAGE: String = "res://world/areas/village/village.tscn"
const FRAME: float = 1.0 / 60.0
const TEST_SLOT: int = 991

var _area: Node


func before_test() -> void:
	GameState.clear()
	GameState.new_game()


func after_test() -> void:
	if is_instance_valid(_area):
		_area.free()
	_area = null
	GameState.clear()
	if SaveSystem.has_slot(TEST_SLOT):
		DirAccess.remove_absolute(SaveSystem.slot_path(TEST_SLOT))


func test_the_bow_lies_in_the_ruin_and_goes_on_the_item_button() -> void:
	var field: AreaController = _load(FIELD)
	for pickup_name: String in ["Bow", "RuinArrows"]:
		var pickup: ItemPickup = field.interactables.get_node(NodePath(pickup_name))
		field.player.motor.place(pickup.cell())
		assert_bool(field.interact()).override_failure_message("pick up %s" % pickup_name).is_true()
	assert_that(GameState.equipped).override_failure_message("the first item for the button is equipped").is_equal(&"bow")
	assert_str(AreaController.equipped_text()).is_equal("Item: Bow (Arrows x10)")


func test_arrows_hurt_enemies_and_run_out() -> void:
	GameState.add_item(&"bow")
	GameState.add_item(&"arrow", 2)
	var field: AreaController = _load(FIELD)
	var slime: Enemy = _put(field, "SlimeA", Vector2i(20, 6))
	field.player.motor.place(Vector2i(20, 9))
	field.player.face(Vector2.UP)
	assert_bool(field.use_item()).is_true()
	assert_int(GameState.item_count(&"arrow")).is_equal(1)
	var arrow: Arrow = field.last_projectile
	assert_that(arrow.hit_box.team).is_equal(&"hero")
	_play(field, Vector2.ZERO, 0.6)
	assert_bool(slime.is_dead()).override_failure_message("an arrow beats a slime").is_true()
	assert_bool(arrow.stopped).is_true()
	assert_bool(field.use_item()).override_failure_message("the last arrow").is_true()
	_play(field, Vector2.ZERO, 0.6)
	assert_int(GameState.item_count(&"arrow")).is_equal(0)
	assert_bool(field.use_item()).override_failure_message("out of arrows").is_false()


func test_bombs_hurt_enemies_and_run_out() -> void:
	GameState.add_item(&"bomb", 1)
	assert_that(GameState.equipped).is_equal(&"bomb")
	var field: AreaController = _load(FIELD)
	var goblin: Enemy = _put(field, "GoblinArcher", Vector2i(20, 6))
	field.player.motor.place(Vector2i(20, 7))
	assert_bool(field.use_item()).is_true()
	assert_int(GameState.item_count(&"bomb")).is_equal(0)
	var bomb: Bomb = field.last_projectile
	_play(field, Vector2.ZERO, 1.5)
	assert_bool(goblin.is_dead()).override_failure_message("not before the fuse burns down").is_false()
	_play(field, Vector2.ZERO, 1.0)
	assert_bool(bomb.exploded).is_true()
	assert_bool(goblin.is_dead()).override_failure_message("one blast beats a goblin").is_true()
	assert_int(GameState.health).override_failure_message("the hero's own bomb spares them").is_equal(GameState.max_health())
	assert_bool(field.use_item()).override_failure_message("out of bombs").is_false()


func test_the_shop_sells_arrows_and_bombs_for_coins() -> void:
	GameState.add_item(&"coin", 20)
	var shop: AreaController = _load(SHOP)
	Steps.stand_before(shop, "Tilda")
	assert_bool(shop.interact()).is_true()
	var box: DialogueBox = shop.hud.dialogue
	assert_array(Array(box.shown_options())).is_equal(["Ten arrows (5 coins)", "Three bombs (8 coins)", "Just looking."])
	box.confirm()
	assert_int(GameState.item_count(&"arrow")).is_equal(10)
	assert_int(GameState.item_count(&"coin")).is_equal(15)
	box.confirm()
	box.move_cursor(1)
	box.confirm()
	assert_int(GameState.item_count(&"bomb")).is_equal(3)
	assert_int(GameState.item_count(&"coin")).is_equal(7)

	# Seven coins don't buy bombs: choosing them only gets an explanation.
	box.confirm()
	box.move_cursor(1)
	box.confirm()
	assert_str(box.shown_text()).contains("Come back when")
	assert_int(GameState.item_count(&"bomb")).is_equal(3)
	assert_int(GameState.item_count(&"coin")).is_equal(7)
	box.move_cursor(1)
	box.confirm()
	assert_bool(box.is_open()).is_false()

	# A full quiver: no more arrows sold, and no coins taken.
	GameState.add_item(&"arrow", 50)
	assert_int(GameState.item_count(&"arrow")).override_failure_message("a quiver holds 30").is_equal(30)
	shop.interact()
	box.confirm()
	assert_str(box.shown_text()).contains("Come back when")
	assert_int(GameState.item_count(&"coin")).is_equal(7)


func test_the_item_menu_equips_and_the_choice_survives_a_save() -> void:
	GameState.add_item(&"bow")
	GameState.add_item(&"arrow", 5)
	GameState.add_item(&"bomb", 2)
	var village: AreaController = _load(VILLAGE)
	assert_bool(village.open_item_menu()).is_true()
	var menu: ItemMenu = village.hud.item_menu
	assert_array(Array(menu.shown_lines())).is_equal(["> Bow (Arrows x5)", "  Bombs x2"])
	assert_bool(village.player.controls_enabled).override_failure_message("the hero stands still in the menu").is_false()
	menu.move_cursor(1)
	menu.confirm()
	assert_that(GameState.equipped).is_equal(&"bomb")
	assert_bool(menu.is_open()).is_false()
	assert_bool(village.player.controls_enabled).is_true()

	assert_int(SaveSystem.save_to_slot(TEST_SLOT)).is_equal(OK)
	GameState.new_game()
	assert_that(GameState.equipped).is_equal(&"")
	assert_int(SaveSystem.load_from_slot(TEST_SLOT)).is_equal(OK)
	assert_that(GameState.equipped).override_failure_message("survives a save").is_equal(&"bomb")
	_load(VILLAGE)
	assert_str(AreaController.equipped_text()).is_equal("Item: Bombs x2")


func test_the_item_menu_needs_something_to_equip() -> void:
	GameState.add_item(&"wooden_sword")
	var village: AreaController = _load(VILLAGE)
	assert_bool(village.open_item_menu()).is_false()
	assert_bool(village.hud.item_menu.is_open()).is_false()
	assert_bool(village.player.controls_enabled).is_true()
	assert_bool(village.use_item()).override_failure_message("nothing on the button").is_false()


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area


## Moves an enemy to `cell`; it stays there (enemies only think when stepped).
func _put(area: AreaController, node_name: String, cell: Vector2i) -> Enemy:
	var enemy: Enemy = area.interactables.get_node(NodePath(node_name))
	enemy.body.place(cell)
	enemy.position = enemy.body.position
	return enemy


## Plays `seconds` of the area frame by frame without the engine loop: the hero steps, arrows
## fly, bombs burn, and the area resolves hits and pickups. Enemies stay where they are.
func _play(area: AreaController, input: Vector2, seconds: float) -> void:
	for i: int in roundi(seconds / FRAME):
		area.player.motor.step(input, FRAME)
		area.player.sync_from_motor()
		for child: Node in area.interactables.get_children():
			if child is Arrow:
				(child as Arrow).fly(FRAME)
			elif child is Bomb:
				(child as Bomb).tick(FRAME)
		area.resolve_combat()
		area.collect_pickups()
