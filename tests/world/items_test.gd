extends GdUnitTestSuite
## Items & weapons (H4): the Bow (in a chest in the keep's armoury, H7) goes on the item button
## when picked up; arrows and bombs hurt enemies and run out; Tilda's shop sells them for coins
## (only what you can afford and carry); the item menu equips, and the choice survives a save.

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const FIELD: String = "res://world/areas/south_field/south_field.tscn"
const KEEP: String = "res://world/areas/keep/keep.tscn"
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


func test_the_bow_waits_in_the_keep_and_goes_on_the_item_button() -> void:
	var keep: AreaController = _load(KEEP)
	for chest_name: String in ["BowChest", "QuiverChest"]:
		var chest: Chest = keep.interactables.get_node(NodePath(chest_name))
		keep.player.motor.place(chest.cell() + Vector2i.DOWN)
		keep.player.face(Vector2.UP)
		assert_bool(keep.interact()).override_failure_message("open %s" % chest_name).is_true()
	assert_that(GameState.equipped).override_failure_message("the first item for the button is equipped").is_equal(&"bow")
	assert_str(AreaController.equipped_text()).is_equal("Item: Bow (Arrows x15)")


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
	assert_array(Array(box.shown_options())).override_failure_message("her wares are a list since P3c (tests/world/shop_test.gd)").is_equal(["Let me see what you sell.", "I have crops to sell.", "Just looking."])
	box.confirm()
	assert_bool(box.is_open()).is_false()
	var counter: ShopMenu = shop.hud.shop_menu
	assert_bool(counter.is_open()).override_failure_message("her list opens when the words are done").is_true()
	assert_bool(counter.confirm()).is_true()
	assert_int(GameState.item_count(&"arrow")).is_equal(10)
	assert_int(GameState.item_count(&"coin")).is_equal(15)
	counter.move_cursor(1)
	assert_bool(counter.confirm()).is_true()
	assert_int(GameState.item_count(&"bomb")).is_equal(3)
	assert_int(GameState.item_count(&"coin")).is_equal(7)

	# Seven coins don't buy bombs: the list says why, and nothing changes.
	assert_bool(counter.confirm()).is_false()
	assert_str(counter.note_text()).is_equal(Shop.NO_COINS)
	assert_int(GameState.item_count(&"bomb")).is_equal(3)
	assert_int(GameState.item_count(&"coin")).is_equal(7)

	# A full quiver: no more arrows sold, and no coins taken.
	GameState.add_item(&"arrow", 50)
	assert_int(GameState.item_count(&"arrow")).override_failure_message("a quiver holds 30").is_equal(30)
	counter.move_cursor(-1)
	assert_bool(counter.confirm()).is_false()
	assert_str(counter.note_text()).is_equal(Shop.NO_ROOM)
	assert_int(GameState.item_count(&"coin")).is_equal(7)
	counter.close()
	assert_bool(shop.player.controls_enabled).is_true()


func test_what_is_in_hand_is_chosen_on_the_bar_and_survives_a_save() -> void:
	GameState.add_item(&"bow")
	GameState.add_item(&"arrow", 5)
	GameState.add_item(&"bomb", 2)
	var village: AreaController = _load(VILLAGE)
	village._update_hud()
	var bar: ItemBar = village.hud.item_bar
	assert_array(bar.shown_ids()).is_equal([&"bow", &"bomb"])
	assert_array(Array(bar.shown_counts())).is_equal(["5", "2"])
	assert_int(bar.lit_slot()).override_failure_message("his first thing for the button is in hand").is_equal(0)
	assert_bool(village.choose_slot(1)).is_true()
	assert_that(GameState.equipped).is_equal(&"bomb")
	assert_int(bar.lit_slot()).is_equal(1)
	assert_bool(village.player.controls_enabled).override_failure_message("choosing doesn't stop him").is_true()

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


func test_tab_or_esc_leaves_the_food_menu_and_changes_nothing() -> void:
	GameState.add_item(&"bow")
	GameState.add_item(&"bread", 2)
	GameState.add_item(&"wild_berries", 3)
	GameState.set_energy(40.0)
	var village: AreaController = _load(VILLAGE)
	var menu: ItemMenu = village.hud.item_menu
	# Esc backs out of it, as it does out of the shop's list and the gifts: it is every menu's
	# way back, and it doesn't open the pause menu on its way.
	for back: StringName in [&"item_menu", &"pause"]:
		assert_bool(village.open_item_menu()).is_true()
		menu.move_cursor(1)
		menu._unhandled_input(_action(back))
		assert_bool(menu.is_open()).override_failure_message("'%s' leaves the food menu" % back).is_false()
		assert_float(GameState.energy).override_failure_message("and nothing was eaten").is_equal(40.0)
		assert_that(GameState.equipped).is_equal(&"bow")
		assert_bool(village.player.controls_enabled).is_true()
		assert_bool(village.is_paused()).is_false()
	# Closed, it hears nothing.
	menu._unhandled_input(_action(&"pause"))
	assert_bool(menu.is_open()).is_false()


func _action(action: StringName) -> InputEventAction:
	var event: InputEventAction = InputEventAction.new()
	event.action = action
	event.pressed = true
	return event


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
