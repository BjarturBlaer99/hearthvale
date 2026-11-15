extends GdUnitTestSuite
## A full pack loses nothing: what lies in the world, what grows to be gathered and what a
## chest holds stay where they are until there is room to carry all of it, and the hero is
## told why. (Before this, each was used up and gave nothing.)

const Steps: GDScript = preload("res://tests/support/area_steps.gd")

const FIELDS: String = "res://world/areas/north_fields/north_fields.tscn"
const HOME: String = "res://world/areas/home/home.tscn"
const KEEP: String = "res://world/areas/keep/keep.tscn"

var _area: Node
var _heard: Array[StringName] = []


func before_test() -> void:
	GameState.clear()
	GameState.new_game()
	GameState.set_time(float(GameState.day_clock().in_day("12:00")))
	Quests.refresh()
	_heard.clear()
	EventBus.sound.connect(_on_sound)


func after_test() -> void:
	EventBus.sound.disconnect(_on_sound)
	if is_instance_valid(_area):
		_area.free()
	_area = null
	GameState.clear()


func test_berries_are_left_to_grow_when_the_pack_holds_no_more() -> void:
	var most: int = Inventory.capacity(DataRegistry.get_item(&"wild_berries"))
	GameState.add_item(&"wild_berries", most)
	var fields: AreaController = _load(FIELDS)
	var berries: ForageSpot = fields.interactables.get_node(^"BerriesA")
	fields.player.motor.place(berries.cell())
	assert_bool(berries.has_room()).is_false()
	assert_bool(berries.take()).override_failure_message("asked itself, the bush gives nothing either").is_false()
	_heard.clear()
	assert_bool(fields.interact()).override_failure_message("he is told, so the click did something").is_true()
	assert_int(GameState.item_count(&"wild_berries")).is_equal(most)
	assert_bool(berries.taken()).override_failure_message("the berries are still on the bush").is_false()
	assert_that(berries.frame()).is_equal(&"berries")
	assert_str(fields.hud.message_text()).is_equal("You have no room for the Wild Berries.")
	assert_array(_heard).override_failure_message("a refusal, not the sound of taking").contains_exactly([&"nope"])
	assert_bool(fields.player.is_holding_up()).override_failure_message("nothing is held up").is_false()

	# Room for one of the two is not room: he takes all of it or none.
	GameState.add_item(&"wild_berries", -1)
	assert_bool(fields.interact()).is_true()
	assert_int(GameState.item_count(&"wild_berries")).is_equal(most - 1)
	assert_bool(berries.taken()).is_false()

	# With room for both, they are his, and the bush is bare until morning.
	GameState.add_item(&"wild_berries", -1)
	assert_bool(fields.interact()).is_true()
	assert_int(GameState.item_count(&"wild_berries")).is_equal(most)
	assert_bool(berries.taken()).is_true()
	assert_str(fields.hud.message_text()).is_equal("You pick up the Wild Berries.")


func test_seeds_on_the_floor_are_left_when_they_dont_all_fit() -> void:
	var most: int = Inventory.capacity(DataRegistry.get_item(&"turnip_seeds"))
	GameState.add_item(&"turnip_seeds", most - 2)
	var home: AreaController = _load(HOME)
	var seeds: ItemPickup = home.interactables.get_node(^"TurnipSeeds")
	assert_int(seeds.count).override_failure_message("the pouch holds more than the two that fit").is_greater(2)
	home.player.motor.place(seeds.cell())
	assert_bool(seeds.take()).override_failure_message("asked itself, the pouch stays too").is_false()
	assert_bool(home.interact()).is_true()
	assert_int(GameState.item_count(&"turnip_seeds")).is_equal(most - 2)
	assert_bool(seeds.taken()).override_failure_message("the pouch is still on the floor").is_false()
	assert_bool(GameState.get_flag(seeds.taken_flag) == true).is_false()
	assert_str(home.hud.message_text()).is_equal("You have no room for the Turnip Seeds.")
	assert_object(home.pickup_under_player()).override_failure_message("and can still be picked up").is_same(seeds)

	GameState.add_item(&"turnip_seeds", -seeds.count)
	assert_bool(home.interact()).is_true()
	assert_int(GameState.item_count(&"turnip_seeds")).is_equal(most - 2)
	assert_bool(seeds.taken()).is_true()


func test_a_chest_stays_shut_when_what_it_holds_doesnt_fit() -> void:
	GameState.set_flag(StoryGates.KEEP_GATE, true)
	var most: int = Inventory.capacity(DataRegistry.get_item(&"arrow"))
	GameState.add_item(&"arrow", most - 5)
	var keep: AreaController = _load(KEEP)
	var chest: Chest = keep.interactables.get_node(^"QuiverChest")
	assert_int(chest.count).is_greater(5)
	keep.player.motor.place(chest.cell() + Vector2i.DOWN)
	keep.player.face(Vector2.UP)
	_heard.clear()
	assert_bool(keep.interact()).is_true()
	assert_bool(chest.opened()).override_failure_message("the chest is still shut").is_false()
	assert_int(GameState.item_count(&"arrow")).is_equal(most - 5)
	assert_str(keep.hud.message_text()).is_equal("You have no room for the Arrows in this chest.")
	assert_array(_heard).contains_exactly([&"nope"])
	assert_bool(keep.player.is_holding_up()).override_failure_message("nothing is held up").is_false()
	assert_str(chest.prompt()).override_failure_message("and can still be opened").is_equal("Open the chest")

	GameState.add_item(&"arrow", -(chest.count - 5))
	assert_bool(keep.interact()).is_true()
	assert_bool(chest.opened()).is_true()
	assert_int(GameState.item_count(&"arrow")).is_equal(most)
	assert_bool(keep.player.is_holding_up()).is_true()


func test_keys_always_fit_for_they_are_not_carried_in_the_pack() -> void:
	GameState.set_flag(StoryGates.KEEP_GATE, true)
	var keep: AreaController = _load(KEEP)
	for child: Node in keep.interactables.get_children():
		var chest: Chest = child as Chest
		if chest != null and (chest.item_id == &"small_key" or chest.item_id == &"big_key"):
			assert_bool(chest.has_room()).override_failure_message("%s" % chest.name).is_true()


func _load(path: String) -> AreaController:
	_area = Steps.load_area(path, _area)
	return _area


func _on_sound(sound: StringName) -> void:
	_heard.append(sound)
